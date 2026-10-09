// 진단·테스트·벤치마크용 함수 (앱 기능은 쓰지 않음)
#include "common.h"
#include "pool.h"
#include "pixels.h"
#include "zstream.h"
#include "png.h"
#include "fileio.h"
#include <stdio.h>

// info():String  "포인터비트,논리코어,풀스레드,메모리상한MB,최고사용MB"
static FREObject Info(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    pool::start(0);
    char text[160];
    sprintf(text, "%d,%d,%d,%llu,%llu", (int)(sizeof(void*) * 8), pool::logicalCores(), pool::threadCount(),
        (unsigned long long)(budget::limit() >> 20), (unsigned long long)(budget::peak() >> 20));
    return newString(text);
}

// configure(threads:int, limitMB:int):int  풀 스레드 수와 메모리 상한을 바꿈 (작업이 없을때만, 테스트용), 0이면 기본값
static FREObject Configure(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    int32_t threads = 0;
    int32_t limitMB = 0;

    if (argc < 2 || !getInt(argv[0], &threads) || !getInt(argv[1], &limitMB))
        return newInt(RESULT_BAD_ARGUMENT);

    pool::stop();
    pool::start(threads);
    budget::setLimit(limitMB > 0 ? ((uint64_t)limitMB << 20) : budget::defaultLimit());
    budget::resetPeak();
    return newInt(RESULT_OK);
}

// zlibCompress(input:ByteArray, level:int, output:ByteArray):int  병렬 zlib (동기)
static FREObject ZlibCompress(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    int32_t level = 6;
    FREByteArray input;

    if (argc < 3 || !getInt(argv[1], &level))
        return newInt(RESULT_BAD_ARGUMENT);

    if (FREAcquireByteArray(argv[0], &input) != FRE_OK)
        return newInt(RESULT_BYTES_ACQUIRE_FAILED);

    Bytes copy(input.bytes, input.bytes + input.length);
    FREReleaseByteArray(argv[0]);
    Pieces pieces;

    if (!zlibCompressParallel(copy.data(), copy.size(), level, PRIORITY_SAVE, pieces))
        return newInt(RESULT_INTERNAL_ERROR);

    const Bytes all = pieces.join();
    return newInt(setByteArray(argv[2], all.data(), all.size()) ? RESULT_OK : RESULT_BYTES_ACQUIRE_FAILED);
}

// zlibUncompress(input:ByteArray, output:ByteArray):int
static FREObject ZlibUncompress(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    FREByteArray input;

    if (argc < 2)
        return newInt(RESULT_BAD_ARGUMENT);

    if (FREAcquireByteArray(argv[0], &input) != FRE_OK)
        return newInt(RESULT_BYTES_ACQUIRE_FAILED);

    Bytes out;
    const bool ok = zlibUncompress(input.bytes, input.length, out, 0);
    FREReleaseByteArray(argv[0]);

    if (!ok)
        return newInt(RESULT_INTERNAL_ERROR);

    return newInt(setByteArray(argv[1], out.data(), out.size()) ? RESULT_OK : RESULT_BYTES_ACQUIRE_FAILED);
}

// encodePng(bitmap:BitmapData, level:int, output:ByteArray):int  (동기)
static FREObject EncodePng(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    int32_t level = 6;

    if (!gHasPngTable)
        return newInt(RESULT_NO_TABLE);

    if (argc < 3 || !getInt(argv[1], &level))
        return newInt(RESULT_BAD_ARGUMENT);

    PixelImage image;
    const int snap = snapshotBitmap(argv[0], image, PRIORITY_SAVE);

    if (snap != RESULT_OK)
        return newInt(snap);

    Pieces pieces;

    if (!encodePng(image, level, PRIORITY_SAVE, pieces))
        return newInt(RESULT_INTERNAL_ERROR);

    const Bytes all = pieces.join();
    return newInt(setByteArray(argv[2], all.data(), all.size()) ? RESULT_OK : RESULT_BYTES_ACQUIRE_FAILED);
}

// timeSnapshot(bitmap:BitmapData):int  스냅샷(내부 버퍼 복사) 시간 측정용, 마이크로초
static FREObject TimeSnapshot(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    LARGE_INTEGER freq, a, b;
    QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&a);
    PixelImage image;
    const int snap = snapshotBitmap(argv[0], image, PRIORITY_SAVE);
    QueryPerformanceCounter(&b);

    if (snap != RESULT_OK)
        return newInt(snap);

    return newInt((int32_t)((b.QuadPart - a.QuadPart) * 1000000 / freq.QuadPart));
}

// fillRandomInternal(bitmap:BitmapData, seed:int):int  유효한 premultiplied 내부값(색 <= 알파)을 채널마다 무작위로 직접 씀 (T2용)
static FREObject FillRandomInternal(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    FREBitmapData2 bitmap;
    int32_t seed = 1;

    if (argc < 2 || !getInt(argv[1], &seed) || FREAcquireBitmapData2(argv[0], &bitmap) != FRE_OK)
        return newInt(RESULT_BAD_ARGUMENT);

    uint32_t state = (uint32_t)seed * 2654435761u + 1;

    for (uint32_t y = 0; y < bitmap.height; y++)
    {
        uint32_t* row = bitmap.bits32 + (size_t)y * bitmap.lineStride32;

        for (uint32_t x = 0; x < bitmap.width; x++)
        {
            state ^= state << 13;
            state ^= state >> 17;
            state ^= state << 5;
            const uint32_t alpha = state & 0xFF;
            const uint32_t r = alpha ? ((state >> 8) & 0xFF) % (alpha + 1) : 0;
            const uint32_t g = alpha ? ((state >> 16) & 0xFF) % (alpha + 1) : 0;
            const uint32_t b = alpha ? ((state >> 24) & 0xFF) % (alpha + 1) : 0;
            row[x] = (alpha << 24) | (r << 16) | (g << 8) | b;
        }
    }

    FREInvalidateBitmapDataRect(argv[0], 0, 0, bitmap.width, bitmap.height);
    FREReleaseBitmapData(argv[0]);
    return newInt(RESULT_OK);
}

// probeRead(path:String):int  지금 이 파일을 저장 파이프라인과 같은 공유 모드로 읽기 열 수 있는지 (0이면 됨, 아니면 Win32 오류)
static FREObject ProbeRead(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    char path[2048];

    if (argc < 1 || !getString(argv[0], path, sizeof(path)))
        return newInt(-1);

    HANDLE file = CreateFileW(widePath(path).c_str(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL, OPEN_EXISTING, 0, NULL);

    if (file == INVALID_HANDLE_VALUE)
        return newInt((int32_t)GetLastError());

    CloseHandle(file);
    return newInt(0);
}

// holdRead(path:String, ms:int):int  다른 스레드에서 같은 공유 모드로 ms 동안 읽기로 열어둠 (AIR 쪽 쓰기와 겹치는지 시험)
static FREObject HoldRead(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    char path[2048];
    int32_t ms = 0;

    if (argc < 2 || !getString(argv[0], path, sizeof(path)) || !getInt(argv[1], &ms))
        return newInt(-1);

    HANDLE file = CreateFileW(widePath(path).c_str(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL, OPEN_EXISTING, 0, NULL);

    if (file == INVALID_HANDLE_VALUE)
        return newInt((int32_t)GetLastError());

    struct Hold : public Task
    {
        HANDLE file;
        int ms;
        void run() override
        {
            Sleep(ms);
            CloseHandle(file);
        }
    };

    Hold* hold = new Hold();
    hold->file = file;
    hold->ms = ms;
    pool::submit(hold, PRIORITY_CACHE);
    return newInt(0);
}

static const NamedFunction gTestFunctions[] = {
    { "probeRead", &ProbeRead },
    { "holdRead", &HoldRead },
    { "fillRandomInternal", &FillRandomInternal },
    { "info", &Info },
    { "configure", &Configure },
    { "zlibCompress", &ZlibCompress },
    { "zlibUncompress", &ZlibUncompress },
    { "encodePng", &EncodePng },
    { "timeSnapshot", &TimeSnapshot },
};

const NamedFunction* testFunctions(uint32_t* count)
{
    *count = sizeof(gTestFunctions) / sizeof(gTestFunctions[0]);
    return gTestFunctions;
}
