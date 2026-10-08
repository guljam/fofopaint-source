// 상주 스레드 풀, 병렬 반복, 메모리 상한
// Win32 API만 씀 (CRITICAL_SECTION, CONDITION_VARIABLE, 이벤트: Vista 이상), Windows 7 호환
#pragma once
#include "common.h"

// 작업 우선순위: 저장(사용자가 기다림)은 보통, 캐시는 보통보다 낮게 해서 AIR 메인 스레드가 끊기지 않게 함
enum TaskPriority
{
    PRIORITY_SAVE = 0,
    PRIORITY_CACHE = 1
};

class Task
{
public:
    virtual ~Task() {}
    virtual void run() = 0;
};

namespace pool
{
    // threads <= 0이면 논리 코어 수 - 1 (최소 1, 최대 64)
    void start(int threads);
    void stop();
    int threadCount();
    int logicalCores();
    // 풀이 task를 소유하고 실행 뒤 delete함
    void submit(Task* task, TaskPriority priority);
    // fn(ctx, i)를 i = 0..count-1에 대해 실행하고 모두 끝나면 돌아옴, 부른 스레드도 같이 일함 (풀 스레드에서 불러도 됨)
    void parallelFor(int count, TaskPriority priority, void (*fn)(void* ctx, int index), void* ctx);

    template <class F>
    void parallelFor(int count, TaskPriority priority, F& f)
    {
        struct Call
        {
            static void run(void* ctx, int index) { (*(F*)ctx)(index); }
        };
        parallelFor(count, priority, &Call::run, &f);
    }
}

// 진행 중인 네이티브 작업의 원본+결과 버퍼 합계 상한
namespace budget
{
    void setLimit(uint64_t bytes);
    uint64_t limit();
    uint64_t used();
    uint64_t peak();
    void resetPeak();
    // 비어있을때는 상한보다 커도 하나는 받아줌 (큰 캔버스 한 장이 상한보다 커도 진행되게)
    bool tryAcquire(uint64_t bytes);
    void acquire(uint64_t bytes); // 자리가 날때까지 기다림 (풀 스레드에서만)
    void release(uint64_t bytes);
    uint64_t defaultLimit();
}
