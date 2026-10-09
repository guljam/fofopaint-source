// 파일 입출력과 작업 완료 알림
#include "fileio.h"
#include <map>

std::wstring widePath(const std::string& utf8)
{
    if (utf8.empty())
        return std::wstring();

    const int length = MultiByteToWideChar(CP_UTF8, 0, utf8.data(), (int)utf8.size(), NULL, 0);
    std::wstring wide(length, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, utf8.data(), (int)utf8.size(), &wide[0], length);

    // 긴 경로 (Windows 7은 \\?\ 접두사가 있어야 MAX_PATH를 넘을 수 있음)
    if (wide.size() >= MAX_PATH - 20 && wide.size() > 2 && wide[1] == L':' && wide.compare(0, 4, L"\\\\?\\") != 0)
        wide = L"\\\\?\\" + wide;

    return wide;
}

std::string utf8Path(const std::wstring& wide)
{
    std::wstring path = wide;

    if (path.compare(0, 4, L"\\\\?\\") == 0)
        path = path.substr(4);

    if (path.empty())
        return std::string();

    const int length = WideCharToMultiByte(CP_UTF8, 0, path.data(), (int)path.size(), NULL, 0, NULL, NULL);
    std::string utf8(length, '\0');
    WideCharToMultiByte(CP_UTF8, 0, path.data(), (int)path.size(), &utf8[0], length, NULL, NULL);
    return utf8;
}

bool fileExists(const std::wstring& path)
{
    return GetFileAttributesW(path.c_str()) != INVALID_FILE_ATTRIBUTES;
}

IoResult writeTempFile(const std::wstring& finalPath, const std::vector<const Pieces*>& parts, std::wstring& tempPath)
{
    HANDLE file = INVALID_HANDLE_VALUE;
    DWORD error = 0;

    // 같은 이름이 남아있으면 다음 번호 (CREATE_NEW라 덮어쓰지 않음)
    for (int attempt = 0; attempt < 100 && file == INVALID_HANDLE_VALUE; attempt++)
    {
        wchar_t suffix[48];
        swprintf(suffix, 48, L".%08x.tmp", (unsigned)(GetTickCount() ^ (GetCurrentThreadId() << 8) ^ (attempt * 2654435761u)));
        tempPath = finalPath + suffix;
        file = CreateFileW(tempPath.c_str(), GENERIC_WRITE, 0, NULL, CREATE_NEW, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, NULL);

        if (file == INVALID_HANDLE_VALUE)
        {
            error = GetLastError();

            if (error != ERROR_FILE_EXISTS && error != ERROR_ALREADY_EXISTS)
                break;
        }
    }

    if (file == INVALID_HANDLE_VALUE)
    {
        tempPath.clear();
        return { false, error };
    }

    bool ok = true;

    for (size_t p = 0; p < parts.size() && ok; p++)
    {
        const Pieces& pieces = *parts[p];

        for (size_t i = 0; i < pieces.parts.size() && ok; i++)
        {
            const uint8_t* data = pieces.parts[i].data();
            size_t remaining = pieces.parts[i].size();

            while (remaining > 0)
            {
                const DWORD chunk = (DWORD)((remaining > (1u << 30)) ? (1u << 30) : remaining);
                DWORD written = 0;

                if (!WriteFile(file, data, chunk, &written, NULL) || written != chunk)
                {
                    error = GetLastError();

                    if (error == 0)
                        error = ERROR_WRITE_FAULT;

                    ok = false;
                    break;
                }

                data += chunk;
                remaining -= chunk;
            }
        }
    }

    if (!CloseHandle(file) && ok)
    {
        error = GetLastError();
        ok = false;
    }

    if (!ok)
    {
        DeleteFileW(tempPath.c_str());
        tempPath.clear();
        return { false, error };
    }

    return { true, 0 };
}

IoResult replaceFile(const std::wstring& tempPath, const std::wstring& finalPath)
{
    if (MoveFileExW(tempPath.c_str(), finalPath.c_str(), MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH))
        return { true, 0 };

    return { false, GetLastError() };
}

IoResult moveNoReplace(const std::wstring& from, const std::wstring& to)
{
    if (MoveFileExW(from.c_str(), to.c_str(), MOVEFILE_WRITE_THROUGH))
        return { true, 0 };

    return { false, GetLastError() };
}

IoResult canReplace(const std::wstring& finalPath)
{
    const DWORD attributes = GetFileAttributesW(finalPath.c_str());

    if (attributes == INVALID_FILE_ATTRIBUTES)
        return { true, 0 };

    if (attributes & FILE_ATTRIBUTE_READONLY)
        return { false, ERROR_ACCESS_DENIED };

    // MoveFileEx로 교체하려면 대상에 DELETE 권한이 있고, 이미 열린 핸들이 모두 삭제 공유를 허용해야 함 -> 같은 조건으로 열어봄
    HANDLE file = CreateFileW(finalPath.c_str(), DELETE, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);

    if (file == INVALID_HANDLE_VALUE)
        return { false, GetLastError() };

    CloseHandle(file);
    return { true, 0 };
}

IoResult readFilePrefix(const std::wstring& path, uint64_t length, Bytes& out)
{
    HANDLE file = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, NULL);

    if (file == INVALID_HANDLE_VALUE)
        return { false, GetLastError() };

    try
    {
        out.resize((size_t)length);
    }
    catch (...)
    {
        CloseHandle(file);
        return { false, ERROR_NOT_ENOUGH_MEMORY };
    }

    uint64_t done = 0;

    while (done < length)
    {
        const DWORD chunk = (DWORD)((length - done > (1u << 30)) ? (1u << 30) : (length - done));
        DWORD read = 0;

        if (!ReadFile(file, out.data() + done, chunk, &read, NULL))
        {
            const DWORD error = GetLastError();
            CloseHandle(file);
            return { false, error };
        }

        if (read == 0)
        {
            // 파일이 요청한 길이보다 짧음
            CloseHandle(file);
            return { false, ERROR_HANDLE_EOF };
        }

        done += read;
    }

    CloseHandle(file);
    return { true, 0 };
}

void deleteQuietly(const std::wstring& path)
{
    if (!path.empty())
        DeleteFileW(path.c_str());
}

// ---- 작업 완료 알림 ----
namespace
{
    CRITICAL_SECTION gJobLock;
    bool gJobLockReady = false;
    FREContext gContext = NULL;
    std::map<int32_t, std::string> gResults;

    void ensureJobLock()
    {
        if (!gJobLockReady)
        {
            InitializeCriticalSection(&gJobLock);
            gJobLockReady = true;
        }
    }
}

namespace jobs
{
    void setContext(FREContext ctx)
    {
        ensureJobLock();
        EnterCriticalSection(&gJobLock);
        gContext = ctx;
        LeaveCriticalSection(&gJobLock);
    }

    void finish(int32_t id, const char* kind, const std::string& result)
    {
        ensureJobLock();
        char level[32];
        sprintf_s(level, "%d", id);
        EnterCriticalSection(&gJobLock);
        gResults[id] = result;

        // 컨텍스트가 해제된 뒤에는 부르지 않음 (앱 종료 중)
        if (gContext != NULL)
            FREDispatchStatusEventAsync(gContext, (const uint8_t*)kind, (const uint8_t*)level);

        LeaveCriticalSection(&gJobLock);
    }

    std::string take(int32_t id)
    {
        ensureJobLock();
        EnterCriticalSection(&gJobLock);
        std::string result;
        auto found = gResults.find(id);

        if (found != gResults.end())
        {
            result = found->second;
            gResults.erase(found);
        }

        LeaveCriticalSection(&gJobLock);
        return result;
    }
}

// takeJobResult(id:int):String
static FREObject TakeJobResult(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    int32_t id = 0;

    if (argc < 1 || !getInt(argv[0], &id))
        return newString("");

    return newString(jobs::take(id).c_str());
}

static const NamedFunction gJobFunctions[] = {
    { "takeJobResult", &TakeJobResult },
};

const NamedFunction* jobFunctions(uint32_t* count)
{
    *count = sizeof(gJobFunctions) / sizeof(gJobFunctions[0]);
    return gJobFunctions;
}
