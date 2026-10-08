// 상주 스레드 풀과 메모리 상한
#include "pool.h"
#include <process.h>
#include <deque>
#include <vector>

namespace
{
    CRITICAL_SECTION gLock;
    CONDITION_VARIABLE gWake;
    bool gLockReady = false;
    bool gStopping = false;
    std::deque<Task*> gQueues[2];
    std::vector<HANDLE> gThreads;

    void ensureLock()
    {
        if (!gLockReady)
        {
            InitializeCriticalSection(&gLock);
            InitializeConditionVariable(&gWake);
            gLockReady = true;
        }
    }

    unsigned __stdcall workerMain(void*)
    {
        int currentPriority = -1;

        for (;;)
        {
            Task* task = NULL;
            int priority = PRIORITY_SAVE;
            EnterCriticalSection(&gLock);

            while (!gStopping && gQueues[0].empty() && gQueues[1].empty())
                SleepConditionVariableCS(&gWake, &gLock, INFINITE);

            if (gStopping && gQueues[0].empty() && gQueues[1].empty())
            {
                LeaveCriticalSection(&gLock);
                break;
            }

            // 저장 작업을 먼저 꺼냄
            for (priority = 0; priority < 2; priority++)
            {
                if (!gQueues[priority].empty())
                {
                    task = gQueues[priority].front();
                    gQueues[priority].pop_front();
                    break;
                }
            }

            LeaveCriticalSection(&gLock);

            if (priority != currentPriority)
            {
                SetThreadPriority(GetCurrentThread(), priority == PRIORITY_SAVE ? THREAD_PRIORITY_NORMAL : THREAD_PRIORITY_BELOW_NORMAL);
                currentPriority = priority;
            }

            try
            {
                task->run();
            }
            catch (...)
            {
                // 작업이 스스로 오류를 처리해야함, 여기까지 오면 스레드만 지킴
            }

            delete task;
        }

        return 0;
    }

    // ---- 병렬 반복 ----
    struct ForGroup
    {
        volatile LONG next;
        volatile LONG remaining;
        volatile LONG refs;
        int count;
        void (*fn)(void*, int);
        void* ctx;
        HANDLE done;
    };

    void releaseGroup(ForGroup* group)
    {
        if (InterlockedDecrement(&group->refs) == 0)
        {
            CloseHandle(group->done);
            delete group;
        }
    }

    void runItems(ForGroup* group)
    {
        for (;;)
        {
            const LONG index = InterlockedIncrement(&group->next) - 1;

            if (index >= group->count)
                break;

            group->fn(group->ctx, (int)index);

            if (InterlockedDecrement(&group->remaining) == 0)
                SetEvent(group->done);
        }
    }

    class ForHelper : public Task
    {
    public:
        explicit ForHelper(ForGroup* group) : group(group) {}
        void run() override
        {
            runItems(group);
            releaseGroup(group);
        }

    private:
        ForGroup* group;
    };

    // ---- 메모리 상한 ----
    CRITICAL_SECTION gBudgetLock;
    CONDITION_VARIABLE gBudgetWake;
    bool gBudgetReady = false;
    uint64_t gBudgetLimit = 0;
    uint64_t gBudgetUsed = 0;
    uint64_t gBudgetPeak = 0;

    void ensureBudget()
    {
        if (!gBudgetReady)
        {
            InitializeCriticalSection(&gBudgetLock);
            InitializeConditionVariable(&gBudgetWake);
            gBudgetLimit = budget::defaultLimit();
            gBudgetReady = true;
        }
    }
}

namespace pool
{
    int logicalCores()
    {
        // 프로세스가 속한 프로세서 그룹의 논리 코어 수 (Windows 7에서도 64개까지), 풀 스레드는 이 그룹에서 돎
        SYSTEM_INFO info;
        GetSystemInfo(&info);
        return (int)info.dwNumberOfProcessors;
    }

    void start(int threads)
    {
        ensureLock();

        if (!gThreads.empty())
            return;

        if (threads <= 0)
            threads = logicalCores() - 1;

        if (threads < 1)
            threads = 1;

        if (threads > 64)
            threads = 64;

        gStopping = false;

        for (int i = 0; i < threads; i++)
        {
            // 스택은 작게 (예약 256KB), 32비트 주소 공간을 아끼려고
            HANDLE thread = (HANDLE)_beginthreadex(NULL, 256 * 1024, &workerMain, NULL, STACK_SIZE_PARAM_IS_A_RESERVATION, NULL);

            if (thread != NULL)
                gThreads.push_back(thread);
        }
    }

    void stop()
    {
        if (!gLockReady || gThreads.empty())
            return;

        EnterCriticalSection(&gLock);
        gStopping = true;
        LeaveCriticalSection(&gLock);
        WakeAllConditionVariable(&gWake);

        for (size_t i = 0; i < gThreads.size(); i++)
        {
            WaitForSingleObject(gThreads[i], INFINITE);
            CloseHandle(gThreads[i]);
        }

        gThreads.clear();
    }

    int threadCount()
    {
        return (int)gThreads.size();
    }

    void submit(Task* task, TaskPriority priority)
    {
        if (gThreads.empty())
            start(0);

        EnterCriticalSection(&gLock);
        gQueues[priority].push_back(task);
        LeaveCriticalSection(&gLock);
        WakeConditionVariable(&gWake);
    }

    void parallelFor(int count, TaskPriority priority, void (*fn)(void* ctx, int index), void* ctx)
    {
        if (count <= 0)
            return;

        if (count == 1)
        {
            fn(ctx, 0);
            return;
        }

        if (gThreads.empty())
            start(0);

        ForGroup* group = new ForGroup();
        group->next = 0;
        group->remaining = count;
        group->count = count;
        group->fn = fn;
        group->ctx = ctx;
        group->done = CreateEventW(NULL, TRUE, FALSE, NULL);
        int helpers = count - 1;

        if (helpers > (int)gThreads.size())
            helpers = (int)gThreads.size();

        group->refs = helpers + 1;

        for (int i = 0; i < helpers; i++)
            submit(new ForHelper(group), priority);

        runItems(group);
        WaitForSingleObject(group->done, INFINITE);
        releaseGroup(group);
    }
}

namespace budget
{
    uint64_t defaultLimit()
    {
#if defined(_WIN64)
        // 실제 메모리의 25%, 최대 2GB
        MEMORYSTATUSEX status;
        status.dwLength = sizeof(status);
        uint64_t limit = (uint64_t)2048 << 20;

        if (GlobalMemoryStatusEx(&status))
        {
            const uint64_t quarter = status.ullTotalPhys / 4;

            if (quarter < limit)
                limit = quarter;
        }

        if (limit < ((uint64_t)256 << 20))
            limit = (uint64_t)256 << 20;

        return limit;
#else
        // 32비트 프로세스는 주소 공간(64비트 Windows 4GB, 32비트 Windows 2GB)을 AIR와 나눠 쓰므로 보수적으로
        return (uint64_t)384 << 20;
#endif
    }

    void setLimit(uint64_t bytes)
    {
        ensureBudget();
        EnterCriticalSection(&gBudgetLock);
        gBudgetLimit = bytes;
        LeaveCriticalSection(&gBudgetLock);
        WakeAllConditionVariable(&gBudgetWake);
    }

    uint64_t limit()
    {
        ensureBudget();
        return gBudgetLimit;
    }

    uint64_t used()
    {
        ensureBudget();
        EnterCriticalSection(&gBudgetLock);
        const uint64_t value = gBudgetUsed;
        LeaveCriticalSection(&gBudgetLock);
        return value;
    }

    uint64_t peak()
    {
        ensureBudget();
        EnterCriticalSection(&gBudgetLock);
        const uint64_t value = gBudgetPeak;
        LeaveCriticalSection(&gBudgetLock);
        return value;
    }

    void resetPeak()
    {
        ensureBudget();
        EnterCriticalSection(&gBudgetLock);
        gBudgetPeak = gBudgetUsed;
        LeaveCriticalSection(&gBudgetLock);
    }

    static bool fits(uint64_t bytes)
    {
        return gBudgetUsed == 0 || gBudgetUsed + bytes <= gBudgetLimit;
    }

    static void take(uint64_t bytes)
    {
        gBudgetUsed += bytes;

        if (gBudgetUsed > gBudgetPeak)
            gBudgetPeak = gBudgetUsed;
    }

    bool tryAcquire(uint64_t bytes)
    {
        ensureBudget();
        EnterCriticalSection(&gBudgetLock);
        const bool ok = fits(bytes);

        if (ok)
            take(bytes);

        LeaveCriticalSection(&gBudgetLock);
        return ok;
    }

    void acquire(uint64_t bytes)
    {
        ensureBudget();
        EnterCriticalSection(&gBudgetLock);

        while (!fits(bytes))
            SleepConditionVariableCS(&gBudgetWake, &gBudgetLock, INFINITE);

        take(bytes);
        LeaveCriticalSection(&gBudgetLock);
    }

    void release(uint64_t bytes)
    {
        ensureBudget();
        EnterCriticalSection(&gBudgetLock);
        gBudgetUsed = (bytes > gBudgetUsed) ? 0 : gBudgetUsed - bytes;
        LeaveCriticalSection(&gBudgetLock);
        WakeAllConditionVariable(&gBudgetWake);
    }
}
