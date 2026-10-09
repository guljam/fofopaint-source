// 캐시 이미지 (undo 캐시, 불러오기 캐시) 쓰기/읽기
// 로컬 전용이라 BitmapData 내부 버퍼(premultiplied)를 그대로 덤프해서 열화가 없음
//
// 파일 형식 (리틀 엔디언), src/Modules/CacheImageFile.as와 같아야 함
//   0  "FCI2"
//   4  u8 형식 버전 (1)
//   5  u8 압축: 1 = 블록마다 zlib 스트림, 2 = 블록마다 LZMA_Alone (AIR CompressionAlgorithm.LZMA와 같은 형식)
//   6  u8 픽셀 형식: 1 = premultiplied 호스트 32비트 ARGB(메모리 B,G,R,A), 아래 행부터 (Windows BitmapData 내부 순서)
//                    2 = straight A,R,G,B 바이트, 위 행부터 (copyPixelsToByteArray, AS3 대체 경로가 씀)
//                    3 = premultiplied, 위 행부터
//   7  u8 레이어 수 (2)
//   8  u32 너비, u32 높이
//   16 u32 메타데이터 길이, 메타데이터 (AS3 writeObject(CacheImageMetaData))
//   레이어마다: u32 블록 수, 블록마다 (u32 행 수, u32 원본 크기, u32 압축 크기), 그 뒤에 블록 데이터들
//   블록을 따로 압축해서 쓰기와 읽기 모두 블록 단위로 병렬
#include "common.h"
#include "pool.h"
#include "pixels.h"
#include "zstream.h"
#include "frc2.h"
#include "fileio.h"
#include "zlib.h"
#include <string>

namespace
{
    const uint8_t FORMAT_VERSION = 1;
    const uint8_t COMPRESS_ZLIB = 1;
    const uint8_t COMPRESS_LZMA = 2;
    const uint8_t PIXELS_PREMULTIPLIED_BOTTOM_UP = 1;
    const uint8_t PIXELS_STRAIGHT_TOP_DOWN = 2;
    const uint8_t PIXELS_PREMULTIPLIED_TOP_DOWN = 3;
    const size_t BLOCK_BYTES = 1024 * 1024;

    // 캐시 압축 방식 (cacheConfigure로 바꿀 수 있음, 테스트·벤치마크용)
    // zlib 레벨 6 (사용자 결정 2026-10-09): 3000x3000 두 레이어 38.7MB 쓰기 105ms 해제 28ms,
    // LZMA는 30~40% 작지만 해제가 2.6~2.7배(2코어 4.5배)라 탐색 속도를 우선함. 읽기는 LZMA 블록도 지원
    volatile LONG gCompression = COMPRESS_ZLIB;
    volatile LONG gZlibLevel = 6;
    volatile LONG gLzmaLevel = 1;

    // 캐시 세대: AS3 BackgroundWorkerCoordinator.cancelPendingCacheImages와 같은 값, 다르면 작업을 건너뜀
    volatile LONG gGeneration = 0;
    volatile LONG gActiveCacheJobs = 0;

    // ---- 테스트 전용 훅 (cacheTestHooks를 부를 때만 켜짐, 앱은 부르지 않음) ----
    // 훅을 켠 뒤 시작한 캐시 쓰기 작업에 1부터 번호를 매기고, 압축과 마지막 세대 확인을 지난 뒤(파일 쓰기 직전)에서
    // failOrdinal 번 작업은 holdCount개가 붙잡힐 때까지 기다렸다가 "error"로 끝내고,
    // holdFrom..holdFrom+holdCount-1 번 작업은 cacheTestRelease까지 붙잡아 둠 (경쟁 조건을 결정적으로 재현하려고)
    volatile LONG gTestEnabled = 0;
    volatile LONG gTestOrdinal = 0;
    volatile LONG gTestHeld = 0;
    LONG gTestFailOrdinal = 0;
    LONG gTestHoldFrom = 0;
    LONG gTestHoldCount = 0;
    LONG gTestHoldAfterWrite = 0; // 1이면 쓰기·교체를 끝낸 뒤 완료 알림 직전에 붙잡음 (늦게 온 "done"을 AS3가 버리는지 시험)
    HANDLE gTestRelease = NULL;

    double nowMs()
    {
        static LARGE_INTEGER freq = { 0 };

        if (freq.QuadPart == 0)
            QueryPerformanceFrequency(&freq);

        LARGE_INTEGER now;
        QueryPerformanceCounter(&now);
        return (double)now.QuadPart * 1000.0 / (double)freq.QuadPart;
    }

    void putU32(Bytes& out, uint32_t value)
    {
        out.push_back((uint8_t)value);
        out.push_back((uint8_t)(value >> 8));
        out.push_back((uint8_t)(value >> 16));
        out.push_back((uint8_t)(value >> 24));
    }

    uint32_t getU32(const uint8_t* p)
    {
        return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
    }

    struct Block
    {
        uint32_t rows;
        uint32_t rawSize;
        Bytes data;
    };

    uint32_t rowsPerBlock(uint32_t width)
    {
        const size_t rowBytes = (size_t)width * 4;
        size_t rows = BLOCK_BYTES / (rowBytes ? rowBytes : 1);
        return (uint32_t)(rows < 1 ? 1 : rows);
    }

    bool compressBlock(const uint8_t* data, size_t length, int compression, Bytes& out)
    {
        if (compression == COMPRESS_LZMA)
            return lzmaCompressAlone(data, length, out, gLzmaLevel, 1u << 20, 1);

        uLongf size = compressBound((uLong)length);

        try
        {
            out.resize(size);
        }
        catch (...)
        {
            return false;
        }

        if (compress2(out.data(), &size, data, (uLong)length, gZlibLevel) != Z_OK)
            return false;

        out.resize(size);
        return true;
    }

    bool uncompressBlock(const uint8_t* data, size_t length, int compression, uint8_t* out, size_t outLength)
    {
        if (compression == COMPRESS_LZMA)
        {
            Bytes decoded;

            if (!lzmaUncompressAlone(data, length, decoded) || decoded.size() != outLength)
                return false;

            memcpy(out, decoded.data(), outLength);
            return true;
        }

        uLongf size = (uLongf)outLength;
        return uncompress(out, &size, data, (uLong)length) == Z_OK && size == outLength;
    }

    // 레이어 두 장을 블록으로 나눠 병렬 압축 (메모리 순서 그대로)
    bool compressLayers(PixelImage* layers, int compression, std::vector<Block>* blocks, TaskPriority priority, LONG generation)
    {
        struct Item
        {
            int layer;
            uint32_t firstRow;
            uint32_t rows;
        };
        std::vector<Item> items;

        for (int l = 0; l < 2; l++)
        {
            const uint32_t per = rowsPerBlock(layers[l].width);

            for (uint32_t row = 0; row < layers[l].height; row += per)
            {
                Item item = { l, row, (row + per < layers[l].height) ? per : layers[l].height - row };
                items.push_back(item);
            }

            blocks[l].clear();
        }

        std::vector<Block> results(items.size());
        volatile LONG failed = 0;

        auto work = [&](int index)
        {
            if (failed || (generation >= 0 && gGeneration != generation))
            {
                InterlockedExchange(&failed, 1);
                return;
            }

            const Item& item = items[index];
            const PixelImage& image = layers[item.layer];
            const uint8_t* start = (const uint8_t*)(image.pixels.data() + (size_t)item.firstRow * image.width);
            const size_t length = (size_t)item.rows * image.width * 4;
            results[index].rows = item.rows;
            results[index].rawSize = (uint32_t)length;

            try
            {
                if (!compressBlock(start, length, compression, results[index].data))
                    InterlockedExchange(&failed, 1);
            }
            catch (...)
            {
                InterlockedExchange(&failed, 1);
            }
        };

        pool::parallelFor((int)items.size(), priority, work);

        if (failed)
            return false;

        for (size_t i = 0; i < items.size(); i++)
            blocks[items[i].layer].push_back(std::move(results[i]));

        return true;
    }

    // 파일 전체 내용 (헤더 + 블록 표 + 블록) 을 조각으로
    void buildFile(const PixelImage* layers, const Bytes& metadata, int compression, uint8_t pixelFormat, std::vector<Block>* blocks, Pieces& out)
    {
        Bytes head;
        head.insert(head.end(), { 'F', 'C', 'I', '2' });
        head.push_back(FORMAT_VERSION);
        head.push_back((uint8_t)compression);
        head.push_back(pixelFormat);
        head.push_back(2);
        putU32(head, layers[0].width);
        putU32(head, layers[0].height);
        putU32(head, (uint32_t)metadata.size());
        head.insert(head.end(), metadata.begin(), metadata.end());
        out.parts.clear();

        for (int l = 0; l < 2; l++)
        {
            putU32(head, (uint32_t)blocks[l].size());

            for (size_t i = 0; i < blocks[l].size(); i++)
            {
                putU32(head, blocks[l][i].rows);
                putU32(head, blocks[l][i].rawSize);
                putU32(head, (uint32_t)blocks[l][i].data.size());
            }

            out.parts.push_back(std::move(head));
            head = Bytes();

            for (size_t i = 0; i < blocks[l].size(); i++)
                out.parts.push_back(std::move(blocks[l][i].data));
        }
    }

    uint8_t pixelFormatOf(const PixelImage& image)
    {
        return image.invertedY ? PIXELS_PREMULTIPLIED_BOTTOM_UP : PIXELS_PREMULTIPLIED_TOP_DOWN;
    }

    std::string resultText(const char* status, double compressMs, double writeMs, uint64_t size, DWORD error)
    {
        char text[160];
        sprintf_s(text, "%s\n%.1f\n%.1f\n%llu\n%lu", status, compressMs, writeMs, (unsigned long long)size, (unsigned long)error);
        return text;
    }

    class CacheWriteJob : public Task
    {
    public:
        int32_t id = 0;
        LONG generation = 0;
        std::wstring path;
        PixelImage layers[2];
        Bytes metadata;
        int compression = COMPRESS_ZLIB;
        uint64_t budgetBytes = 0;
        LONG testOrdinal = 0; // 테스트 훅이 켜졌을 때만 0이 아님

        ~CacheWriteJob() override
        {
            budget::release(budgetBytes);
            InterlockedDecrement(&gActiveCacheJobs);
        }

        void run() override
        {
            const double start = nowMs();

            if (gGeneration != generation)
            {
                jobs::finish(id, "cache", resultText("cancelled", 0, 0, 0, 0));
                return;
            }

            std::vector<Block> blocks[2];

            if (!compressLayers(layers, compression, blocks, PRIORITY_CACHE, generation))
            {
                jobs::finish(id, "cache", resultText(gGeneration != generation ? "cancelled" : "error", nowMs() - start, 0, 0, 0));
                return;
            }

            const uint8_t format = pixelFormatOf(layers[0]);
            std::vector<uint32_t>().swap(layers[0].pixels);
            std::vector<uint32_t>().swap(layers[1].pixels);
            const double compressed = nowMs();
            Pieces file;
            buildFile(layers, metadata, compression, format, blocks, file);

            if (gGeneration != generation)
            {
                jobs::finish(id, "cache", resultText("cancelled", compressed - start, 0, 0, 0));
                return;
            }

            if (testOrdinal != 0)
            {
                if (testOrdinal == gTestFailOrdinal)
                {
                    for (int waited = 0; waited < 1000 && gTestHeld < gTestHoldCount; waited++)
                        Sleep(10);

                    jobs::finish(id, "cache", resultText("error", compressed - start, 0, 0, 0));
                    // 메인이 실패 알림을 처리할 때까지 메모리 예산을 쥐고 있어서 다음 스냅샷이 네이티브로 먼저 들어가지 않게 함
                    Sleep(2000);
                    return;
                }

                if (!gTestHoldAfterWrite && testOrdinal >= gTestHoldFrom && testOrdinal < gTestHoldFrom + gTestHoldCount)
                {
                    InterlockedIncrement(&gTestHeld);
                    WaitForSingleObject(gTestRelease, 120000);
                }
            }

            std::wstring temp;
            IoResult result = writeTempFile(path, { &file }, temp);

            // 쓰는 사이에 세대가 바뀌었으면 교체하지 않음 (AS3가 이미 결과를 버리기로 함, 쓸데없는 파일을 남기지 않게)
            if (result.ok && gGeneration != generation)
            {
                deleteQuietly(temp);
                jobs::finish(id, "cache", resultText("cancelled", compressed - start, nowMs() - compressed, 0, 0));
                return;
            }

            if (result.ok)
            {
                result = replaceFile(temp, path);

                if (!result.ok)
                    deleteQuietly(temp);
            }

            if (testOrdinal != 0 && gTestHoldAfterWrite && testOrdinal >= gTestHoldFrom && testOrdinal < gTestHoldFrom + gTestHoldCount)
            {
                InterlockedIncrement(&gTestHeld);
                WaitForSingleObject(gTestRelease, 120000);
            }

            jobs::finish(id, "cache", resultText(result.ok ? "done" : "error", compressed - start, nowMs() - compressed, file.size(), result.error));
        }
    };

    bool readWholeFile(const std::wstring& path, Bytes& out)
    {
        HANDLE file = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, NULL);

        if (file == INVALID_HANDLE_VALUE)
            return false;

        LARGE_INTEGER size;

        if (!GetFileSizeEx(file, &size) || size.QuadPart > 0x7FFFFFFF)
        {
            CloseHandle(file);
            return false;
        }

        CloseHandle(file);
        return readFilePrefix(path, (uint64_t)size.QuadPart, out).ok;
    }

    uint64_t estimate(const PixelImage& image)
    {
        return (uint64_t)image.byteSize() * 3 / 2;
    }

    int snapshotLayers(FREObject a, FREObject b, PixelImage* layers, TaskPriority priority)
    {
        int result = snapshotBitmap(a, layers[0], priority);

        if (result == RESULT_OK)
            result = snapshotBitmap(b, layers[1], priority);

        if (result == RESULT_OK && (layers[0].width != layers[1].width || layers[0].height != layers[1].height || layers[0].invertedY != layers[1].invertedY))
            result = RESULT_UNSUPPORTED_FORMAT;

        return result;
    }
}

int activeCacheJobCount()
{
    return (int)gActiveCacheJobs;
}

void cancelAllCacheJobs()
{
    InterlockedIncrement(&gGeneration);
}

// cacheSetGeneration(generation:int):void  AS3 cacheGeneration과 맞춤 (바뀌면 진행 중인 작업은 건너뜀)
static FREObject CacheSetGeneration(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    int32_t generation = 0;

    if (argc >= 1 && getInt(argv[0], &generation))
        InterlockedExchange(&gGeneration, generation);

    return newInt(RESULT_OK);
}

// cacheWrite(id, path, layer1, layer2, metadata:ByteArray, generation, force:Boolean):int
// 비트맵 두 장을 복사하고 바로 돌아옴, 끝나면 StatusEvent("cache", id)
// force가 아니면 메모리 상한을 넘을때 RESULT_BUSY (불러오기 캐시는 다음 프레임에 다시 시도)
static FREObject CacheWrite(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    if (argc < 7)
        return newInt(RESULT_BAD_ARGUMENT);

    int32_t id = 0;
    int32_t generation = 0;
    bool force = false;
    std::string path;
    uint32_t pathLength = 0;
    const uint8_t* pathText = NULL;

    if (!getInt(argv[0], &id) || FREGetObjectAsUTF8(argv[1], &pathLength, &pathText) != FRE_OK || !getInt(argv[5], &generation) || !getBool(argv[6], &force))
        return newInt(RESULT_BAD_ARGUMENT);

    path.assign((const char*)pathText, pathLength);
    FREBitmapData2 probe;
    uint64_t needed = 0;

    // 상한 확인은 복사 전에 (복사 자체가 메모리를 씀)
    if (FREAcquireBitmapData2(argv[2], &probe) == FRE_OK)
    {
        needed = (uint64_t)probe.width * probe.height * 4 * 2 * 3 / 2;
        FREReleaseBitmapData(argv[2]);
    }

    if (force)
        budget::forceAcquire(needed);
    else if (!budget::tryAcquire(needed))
        return newInt(RESULT_BUSY);

    CacheWriteJob* job = new CacheWriteJob();
    InterlockedIncrement(&gActiveCacheJobs);
    job->budgetBytes = needed;
    job->id = id;
    job->generation = generation;
    job->path = widePath(path);
    job->compression = (int)gCompression;

    if (gTestEnabled)
        job->testOrdinal = InterlockedIncrement(&gTestOrdinal);
    FREByteArray metadata;

    if (FREAcquireByteArray(argv[4], &metadata) != FRE_OK)
    {
        delete job;
        return newInt(RESULT_BYTES_ACQUIRE_FAILED);
    }

    job->metadata.assign(metadata.bytes, metadata.bytes + metadata.length);
    FREReleaseByteArray(argv[4]);
    const int snap = snapshotLayers(argv[2], argv[3], job->layers, PRIORITY_CACHE);

    if (snap != RESULT_OK)
    {
        delete job;
        return newInt(snap);
    }

    pool::submit(job, PRIORITY_CACHE);
    return newInt(RESULT_OK);
}

// cacheWriteSync(path, layer1, layer2, metadata:ByteArray):int  호출 안에서 다 씀 (첫 이미지 캐시 0번)
static FREObject CacheWriteSync(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    if (argc < 4)
        return newInt(RESULT_BAD_ARGUMENT);

    uint32_t pathLength = 0;
    const uint8_t* pathText = NULL;

    if (FREGetObjectAsUTF8(argv[0], &pathLength, &pathText) != FRE_OK)
        return newInt(RESULT_BAD_ARGUMENT);

    const std::wstring path = widePath(std::string((const char*)pathText, pathLength));
    PixelImage layers[2];
    const int snap = snapshotLayers(argv[1], argv[2], layers, PRIORITY_SAVE);

    if (snap != RESULT_OK)
        return newInt(snap);

    FREByteArray metadataBytes;

    if (FREAcquireByteArray(argv[3], &metadataBytes) != FRE_OK)
        return newInt(RESULT_BYTES_ACQUIRE_FAILED);

    Bytes metadata(metadataBytes.bytes, metadataBytes.bytes + metadataBytes.length);
    FREReleaseByteArray(argv[3]);
    std::vector<Block> blocks[2];
    const int compression = (int)gCompression;

    if (!compressLayers(layers, compression, blocks, PRIORITY_SAVE, -1))
        return newInt(RESULT_INTERNAL_ERROR);

    Pieces file;
    buildFile(layers, metadata, compression, pixelFormatOf(layers[0]), blocks, file);
    std::wstring temp;
    IoResult result = writeTempFile(path, { &file }, temp);

    if (result.ok)
    {
        result = replaceFile(temp, path);

        if (!result.ok)
            deleteQuietly(temp);
    }

    return newInt(result.ok ? RESULT_OK : RESULT_IO_ERROR);
}

// cacheRead(path, layer1, layer2):int  새 형식 캐시 파일의 두 레이어를 비트맵 내부 버퍼에 바로 풂 (블록 병렬)
// 비트맵은 AS3가 헤더의 크기로 미리 만들어서 넘김
static FREObject CacheRead(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    if (argc < 3)
        return newInt(RESULT_BAD_ARGUMENT);

    uint32_t pathLength = 0;
    const uint8_t* pathText = NULL;

    if (FREGetObjectAsUTF8(argv[0], &pathLength, &pathText) != FRE_OK)
        return newInt(RESULT_BAD_ARGUMENT);

    Bytes file;

    if (!readWholeFile(widePath(std::string((const char*)pathText, pathLength)), file) || file.size() < 20 || memcmp(file.data(), "FCI2", 4) != 0
        || file[4] != FORMAT_VERSION || file[7] != 2)
        return newInt(RESULT_UNSUPPORTED_FORMAT);

    const int compression = file[5];
    const uint8_t pixelFormat = file[6];
    const uint32_t width = getU32(&file[8]);
    const uint32_t height = getU32(&file[12]);
    size_t offset = 20 + (size_t)getU32(&file[16]);

    if ((compression != COMPRESS_ZLIB && compression != COMPRESS_LZMA) || pixelFormat < 1 || pixelFormat > 3 || offset > file.size())
        return newInt(RESULT_UNSUPPORTED_FORMAT);

    if (pixelFormat == PIXELS_STRAIGHT_TOP_DOWN && !gHasRestoreTable)
        return newInt(RESULT_NO_TABLE);

    struct Item
    {
        int layer;
        uint32_t firstRow; // 파일 안 행 순서
        uint32_t rows;
        uint32_t rawSize;
        const uint8_t* data;
        uint32_t size;
    };
    std::vector<Item> items;

    for (int l = 0; l < 2; l++)
    {
        if (offset + 4 > file.size())
            return newInt(RESULT_UNSUPPORTED_FORMAT);

        const uint32_t count = getU32(&file[offset]);
        offset += 4;

        if ((uint64_t)offset + (uint64_t)count * 12 > file.size())
            return newInt(RESULT_UNSUPPORTED_FORMAT);

        const size_t tableStart = offset;
        size_t dataOffset = offset + (size_t)count * 12;
        uint32_t row = 0;

        for (uint32_t i = 0; i < count; i++)
        {
            const uint8_t* entry = &file[tableStart + (size_t)i * 12];
            Item item = { l, row, getU32(entry), getU32(entry + 4), NULL, getU32(entry + 8) };

            if ((uint64_t)dataOffset + item.size > file.size() || (uint64_t)item.rows * width * 4 != item.rawSize)
                return newInt(RESULT_UNSUPPORTED_FORMAT);

            item.data = &file[dataOffset];
            dataOffset += item.size;
            row += item.rows;
            items.push_back(item);
        }

        if (row != height)
            return newInt(RESULT_UNSUPPORTED_FORMAT);

        offset = dataOffset;
    }

    FREBitmapData2 bitmaps[2];

    if (FREAcquireBitmapData2(argv[1], &bitmaps[0]) != FRE_OK)
        return newInt(RESULT_BITMAP_ACQUIRE_FAILED);

    if (FREAcquireBitmapData2(argv[2], &bitmaps[1]) != FRE_OK)
    {
        FREReleaseBitmapData(argv[1]);
        return newInt(RESULT_BITMAP_ACQUIRE_FAILED);
    }

    int result = RESULT_OK;

    for (int l = 0; l < 2; l++)
    {
        if (bitmaps[l].width != width || bitmaps[l].height != height || !bitmaps[l].hasAlpha || !bitmaps[l].isPremultiplied)
            result = RESULT_UNSUPPORTED_FORMAT;
    }

    if (result == RESULT_OK)
    {
        volatile LONG failed = 0;

        auto work = [&](int index)
        {
            const Item& item = items[index];
            FREBitmapData2& bitmap = bitmaps[item.layer];

            try
            {
                Bytes raw(item.rawSize);

                if (!uncompressBlock(item.data, item.size, compression, raw.data(), raw.size()))
                {
                    InterlockedExchange(&failed, 1);
                    return;
                }

                for (uint32_t r = 0; r < item.rows; r++)
                {
                    const uint32_t fileRow = item.firstRow + r;
                    const uint8_t* source = raw.data() + (size_t)r * width * 4;

                    if (pixelFormat == PIXELS_STRAIGHT_TOP_DOWN)
                    {
                        // 위 행부터의 straight 값 -> 복원표로 내부값
                        const uint32_t memoryRow = bitmap.isInvertedY ? height - 1 - fileRow : fileRow;
                        restoreStraightRow(source, bitmap.bits32 + (size_t)memoryRow * bitmap.lineStride32, width);
                    }
                    else
                    {
                        // premultiplied 원본: 파일의 행 순서를 위에서부터로 바꾼 뒤 비트맵 메모리 순서로
                        const uint32_t topRow = (pixelFormat == PIXELS_PREMULTIPLIED_BOTTOM_UP) ? height - 1 - fileRow : fileRow;
                        const uint32_t memoryRow = bitmap.isInvertedY ? height - 1 - topRow : topRow;
                        memcpy(bitmap.bits32 + (size_t)memoryRow * bitmap.lineStride32, source, (size_t)width * 4);
                    }
                }
            }
            catch (...)
            {
                InterlockedExchange(&failed, 1);
            }
        };

        pool::parallelFor((int)items.size(), PRIORITY_SAVE, work);

        if (failed)
            result = RESULT_INTERNAL_ERROR;
    }

    for (int l = 0; l < 2; l++)
    {
        if (result == RESULT_OK)
            FREInvalidateBitmapDataRect(argv[1 + l], 0, 0, width, height);
    }

    FREReleaseBitmapData(argv[2]);
    FREReleaseBitmapData(argv[1]);
    return newInt(result);
}

// cacheConfigure(compression:int, zlibLevel:int, lzmaLevel:int):int  (압축 방식 측정용)
static FREObject CacheConfigure(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    int32_t compression = COMPRESS_ZLIB, zlibLevel = 1, lzmaLevel = 1;

    if (argc < 3 || !getInt(argv[0], &compression) || !getInt(argv[1], &zlibLevel) || !getInt(argv[2], &lzmaLevel))
        return newInt(RESULT_BAD_ARGUMENT);

    InterlockedExchange(&gCompression, compression);
    InterlockedExchange(&gZlibLevel, zlibLevel);
    InterlockedExchange(&gLzmaLevel, lzmaLevel);
    return newInt(RESULT_OK);
}

// cacheActiveJobs():int
static FREObject CacheActiveJobs(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    return newInt((int32_t)gActiveCacheJobs);
}

// budgetInfo():String "사용MB,최고MB,상한MB"
static FREObject BudgetInfo(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    char text[96];
    sprintf_s(text, "%.1f,%.1f,%.1f", budget::used() / 1048576.0, budget::peak() / 1048576.0, budget::limit() / 1048576.0);
    return newString(text);
}

// cacheTestHooks(failOrdinal:int, holdFrom:int, holdCount:int, holdAfterWrite:int):int  테스트 전용, 0,0,0이면 끔
static FREObject CacheTestHooks(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    int32_t fail = 0, from = 0, count = 0, after = 0;

    if (argc < 3 || !getInt(argv[0], &fail) || !getInt(argv[1], &from) || !getInt(argv[2], &count) || (argc >= 4 && !getInt(argv[3], &after)))
        return newInt(RESULT_BAD_ARGUMENT);

    gTestHoldAfterWrite = after;

    if (gTestRelease == NULL)
        gTestRelease = CreateEventW(NULL, TRUE, FALSE, NULL);

    ResetEvent(gTestRelease);
    gTestFailOrdinal = fail;
    gTestHoldFrom = from;
    gTestHoldCount = count;
    InterlockedExchange(&gTestHeld, 0);
    InterlockedExchange(&gTestOrdinal, 0);
    InterlockedExchange(&gTestEnabled, (fail || count) ? 1 : 0);
    return newInt(RESULT_OK);
}

// cacheTestRelease():int  붙잡은 작업을 풀어줌
static FREObject CacheTestRelease(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    if (gTestRelease != NULL)
        SetEvent(gTestRelease);

    return newInt(RESULT_OK);
}

// cacheTestHeld():int  지금까지 붙잡힌 작업 수
static FREObject CacheTestHeld(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    return newInt((int32_t)gTestHeld);
}

static const NamedFunction gCacheFunctions[] = {
    { "cacheTestHooks", &CacheTestHooks },
    { "cacheTestRelease", &CacheTestRelease },
    { "cacheTestHeld", &CacheTestHeld },
    { "cacheSetGeneration", &CacheSetGeneration },
    { "cacheWrite", &CacheWrite },
    { "cacheWriteSync", &CacheWriteSync },
    { "cacheRead", &CacheRead },
    { "cacheConfigure", &CacheConfigure },
    { "cacheActiveJobs", &CacheActiveJobs },
    { "budgetInfo", &BudgetInfo },
};

const NamedFunction* cacheFunctions(uint32_t* count)
{
    *count = sizeof(gCacheFunctions) / sizeof(gCacheFunctions[0]);
    return gCacheFunctions;
}
