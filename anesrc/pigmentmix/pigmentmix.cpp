// com.fofo.pigmentmix
// drawLayer(한가지 색으로 그린 획)를 레이어 BitmapData에 mixbox 안료 혼합으로 합성함
// 레이어 BitmapData 내부 버퍼를 직접 고쳐서 복사가 없음, 메인 스레드에서 동기로 부르고 안에서 네이티브 스레드로 나눠 계산함
// mixbox 소스(CC BY-NC 4.0)는 저장소에 넣지 않고 빌드할때 include 경로로 가져옴 (build-ane.ps1의 $mixboxDir)
//
// 픽셀 계산 (획 알파 s = drawLayer 알파 * 펜 알파, 바닥 알파 dA)
//   outA = s + dA * (1 - s)
//   t = s / outA
//   outRGB = mixbox_lerp(바닥RGB, 획색, t)
// 바닥이 투명하면 t = 1이 되어 일반 합성과 같은 결과가 나옴
#include <stdint.h>
#include <string.h>
#include <atomic>
#include <chrono>
#include <thread>
#include <vector>
#include "FlashRuntimeExtensions.h"

// 내부 함수(float_rgb_to_latent, eval_polynomial, mixbox_lut)를 직접 쓰려고 같은 번역 단위로 넣음
#include "mixbox.cpp"

#if defined(_WIN32)
#define FOFO_EXPORT extern "C" __declspec(dllexport)
#else
#define FOFO_EXPORT extern "C" __attribute__((visibility("default")))
#endif

enum
{
    RESULT_BAD_ARGUMENT = -2,
    RESULT_BITMAP_ACQUIRE_FAILED = -3,
    RESULT_UNSUPPORTED_FORMAT = -4,
    RESULT_SIZE_MISMATCH = -5
};

// 스레드 하나가 가져가는 행 수
#define ROWS_PER_CHUNK 16
// 이것보다 작은 영역은 스레드를 나누지 않음
#define SINGLE_THREAD_PIXELS (256 * 256)

// 바닥색 latent 캐시 (RGB24 -> latent), 획이 바뀌어도 그대로 쓸 수 있음
#define LATENT_CACHE_BITS 14
// 결과 캐시 ((바닥 픽셀, drawLayer 알파) -> 결과 픽셀), 획마다 gen으로 무효화함
#define RESULT_CACHE_BITS 16

struct LatentEntry
{
    uint32_t key;
    float latent[7];
};

struct ResultEntry
{
    uint64_t key;
    uint32_t gen;
    uint32_t pixel;
};

struct WorkerCache
{
    LatentEntry latent[1 << LATENT_CACHE_BITS];
    ResultEntry result[1 << RESULT_CACHE_BITS];

    WorkerCache()
    {
        for (int i = 0; i < (1 << LATENT_CACHE_BITS); i++)
            latent[i].key = 0xFFFFFFFFu;
        memset(result, 0, sizeof(result));
    }
};

static std::vector<WorkerCache*> gCaches;
static uint32_t gGeneration = 0;

struct Job
{
    uint32_t* layerBits;
    const uint32_t* drawBits;
    uint32_t layerStride;
    uint32_t drawStride;
    uint32_t height;
    bool invertedY;
    int32_t left;
    int32_t right;
    int32_t top;
    int32_t bottom;
    float alphaScale; // 펜 알파 / 255
    uint32_t colorRGB;
    float colorLatent[7];
    uint32_t gen;
    std::atomic<int32_t> nextRow;
};

static inline uint32_t unpremultiply(uint32_t c, uint32_t a)
{
    const uint32_t v = (c * 255 + (a >> 1)) / a;
    return v > 255 ? 255 : v;
}

static inline uint32_t premultiply(uint32_t c, uint32_t a)
{
    return (c * a + 127) / 255;
}

static inline void latentOf(WorkerCache* cache, uint32_t rgb, float* out)
{
    LatentEntry& e = cache->latent[(rgb * 2654435761u) >> (32 - LATENT_CACHE_BITS)];

    if (e.key != rgb)
    {
        rgb_to_latent((unsigned char)(rgb >> 16), (unsigned char)(rgb >> 8), (unsigned char)rgb, e.latent);
        e.key = rgb;
    }

    memcpy(out, e.latent, sizeof(e.latent));
}

static uint32_t mixPixel(const Job* job, WorkerCache* cache, uint32_t layerPixel, uint32_t coverage)
{
    const float s = (float)coverage * job->alphaScale;
    const uint32_t dA = layerPixel >> 24;
    const float outAlpha = s + (float)dA * (1.0f / 255.0f) * (1.0f - s);
    const uint32_t outA = (uint32_t)(outAlpha * 255.0f + 0.5f);

    if (outA == 0)
        return layerPixel;

    uint32_t rgb = job->colorRGB;

    if (dA != 0 && s < 1.0f)
    {
        const uint32_t dstRGB = (unpremultiply((layerPixel >> 16) & 0xFF, dA) << 16) |
                                (unpremultiply((layerPixel >> 8) & 0xFF, dA) << 8) |
                                unpremultiply(layerPixel & 0xFF, dA);

        if (dstRGB != rgb)
        {
            const float t = s / outAlpha;
            float dstLatent[7];
            float mixLatent[7];
            latentOf(cache, dstRGB, dstLatent);

            for (int i = 0; i < 7; i++)
                mixLatent[i] = (1.0f - t) * dstLatent[i] + t * job->colorLatent[i];

            unsigned char r, g, b;
            latent_to_rgb(mixLatent, &r, &g, &b);
            rgb = ((uint32_t)r << 16) | ((uint32_t)g << 8) | b;
        }
    }

    return (outA << 24) |
           (premultiply((rgb >> 16) & 0xFF, outA) << 16) |
           (premultiply((rgb >> 8) & 0xFF, outA) << 8) |
           premultiply(rgb & 0xFF, outA);
}

static void runWorker(Job* job, WorkerCache* cache)
{
    for (;;)
    {
        const int32_t y0 = job->nextRow.fetch_add(ROWS_PER_CHUNK);

        if (y0 >= job->bottom)
            break;

        const int32_t y1 = (y0 + ROWS_PER_CHUNK < job->bottom) ? y0 + ROWS_PER_CHUNK : job->bottom;

        for (int32_t y = y0; y < y1; y++)
        {
            // isInvertedY면 메모리에 아래 행부터 들어있음
            const uint32_t row = job->invertedY ? (job->height - 1 - (uint32_t)y) : (uint32_t)y;
            uint32_t* layerRow = job->layerBits + (size_t)row * job->layerStride;
            const uint32_t* drawRow = job->drawBits + (size_t)row * job->drawStride;

            for (int32_t x = job->left; x < job->right; x++)
            {
                const uint32_t coverage = drawRow[x] >> 24;

                if (coverage == 0)
                    continue;

                const uint32_t layerPixel = layerRow[x];
                const uint64_t key = ((uint64_t)layerPixel << 8) | coverage;
                ResultEntry& e = cache->result[(key * 0x9E3779B97F4A7C15ull) >> (64 - RESULT_CACHE_BITS)];

                if (e.gen == job->gen && e.key == key)
                {
                    layerRow[x] = e.pixel;
                }
                else
                {
                    const uint32_t pixel = mixPixel(job, cache, layerPixel, coverage);
                    e.key = key;
                    e.gen = job->gen;
                    e.pixel = pixel;
                    layerRow[x] = pixel;
                }
            }
        }
    }
}

static FREObject newNumber(double value)
{
    FREObject object = NULL;
    FRENewObjectFromDouble(value, &object);
    return object;
}

static FREObject newInt(int32_t value)
{
    FREObject object = NULL;
    FRENewObjectFromInt32(value, &object);
    return object;
}

// composite(layer:BitmapData, draw:BitmapData, x:int, y:int, width:int, height:int, color:uint, alpha:Number, threads:int):Number
// 성공하면 네이티브 처리 시간(마이크로초), 실패하면 음수 오류 코드
static FREObject Composite(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    int32_t rx, ry, rw, rh, threads;
    uint32_t color;
    double alpha;

    if (argc < 9 ||
        FREGetObjectAsInt32(argv[2], &rx) != FRE_OK || FREGetObjectAsInt32(argv[3], &ry) != FRE_OK ||
        FREGetObjectAsInt32(argv[4], &rw) != FRE_OK || FREGetObjectAsInt32(argv[5], &rh) != FRE_OK ||
        FREGetObjectAsUint32(argv[6], &color) != FRE_OK || FREGetObjectAsDouble(argv[7], &alpha) != FRE_OK ||
        FREGetObjectAsInt32(argv[8], &threads) != FRE_OK)
        return newNumber(RESULT_BAD_ARGUMENT);

    FREBitmapData2 layer;
    FREBitmapData2 draw;

    if (FREAcquireBitmapData2(argv[0], &layer) != FRE_OK)
        return newNumber(RESULT_BITMAP_ACQUIRE_FAILED);

    if (FREAcquireBitmapData2(argv[1], &draw) != FRE_OK)
    {
        FREReleaseBitmapData(argv[0]);
        return newNumber(RESULT_BITMAP_ACQUIRE_FAILED);
    }

    const auto started = std::chrono::steady_clock::now();
    double result = 0;

    if (!layer.hasAlpha || !layer.isPremultiplied || !draw.hasAlpha || !draw.isPremultiplied)
    {
        result = RESULT_UNSUPPORTED_FORMAT;
    }
    else if (layer.width != draw.width || layer.height != draw.height || layer.isInvertedY != draw.isInvertedY)
    {
        result = RESULT_SIZE_MISMATCH;
    }
    else
    {
        // 영역을 비트맵 안으로 잘라줌 (draw()와 달리 여기서는 밖을 쓰면 메모리를 넘어감)
        const int32_t left = rx < 0 ? 0 : rx;
        const int32_t top = ry < 0 ? 0 : ry;
        const int64_t rightRaw = (int64_t)rx + rw;
        const int64_t bottomRaw = (int64_t)ry + rh;
        const int32_t right = (int32_t)(rightRaw > (int64_t)layer.width ? layer.width : (rightRaw < 0 ? 0 : rightRaw));
        const int32_t bottom = (int32_t)(bottomRaw > (int64_t)layer.height ? layer.height : (bottomRaw < 0 ? 0 : bottomRaw));

        if (right > left && bottom > top && alpha > 0)
        {
            Job job;
            job.layerBits = layer.bits32;
            job.drawBits = draw.bits32;
            job.layerStride = layer.lineStride32;
            job.drawStride = draw.lineStride32;
            job.height = layer.height;
            job.invertedY = layer.isInvertedY != 0;
            job.left = left;
            job.right = right;
            job.top = top;
            job.bottom = bottom;
            job.alphaScale = (float)(alpha > 1.0 ? 1.0 : alpha) * (1.0f / 255.0f);
            job.colorRGB = color & 0xFFFFFF;
            rgb_to_latent((unsigned char)(color >> 16), (unsigned char)(color >> 8), (unsigned char)color, job.colorLatent);
            job.gen = ++gGeneration;
            job.nextRow.store(top);

            int32_t count = threads > 0 ? threads : (int32_t)std::thread::hardware_concurrency();

            if (count < 1)
                count = 1;

            if ((int64_t)(right - left) * (bottom - top) < SINGLE_THREAD_PIXELS)
                count = 1;

            while ((int32_t)gCaches.size() < count)
                gCaches.push_back(new WorkerCache());

            std::vector<std::thread> pool;

            for (int32_t i = 1; i < count; i++)
                pool.emplace_back(runWorker, &job, gCaches[i]);

            runWorker(&job, gCaches[0]);

            for (auto& t : pool)
                t.join();

            // 결과 캐시 gen이 한바퀴 돌면 0과 겹치지 않게 비워줌
            if (gGeneration == 0xFFFFFFFFu)
            {
                for (auto* c : gCaches)
                    memset(c->result, 0, sizeof(c->result));
                gGeneration = 0;
            }

            FREInvalidateBitmapDataRect(argv[0], left, top, right - left, bottom - top);
        }

        result = (double)std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::steady_clock::now() - started).count();
    }

    FREReleaseBitmapData(argv[1]);
    FREReleaseBitmapData(argv[0]);
    return newNumber(result);
}

// lerpRef(color1:uint, color2:uint, t:Number):int
// 검증용, mixbox 원본 mixbox_lerp 결과
static FREObject LerpRef(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    uint32_t c1, c2;
    double t;

    if (argc < 3 || FREGetObjectAsUint32(argv[0], &c1) != FRE_OK || FREGetObjectAsUint32(argv[1], &c2) != FRE_OK ||
        FREGetObjectAsDouble(argv[2], &t) != FRE_OK)
        return newInt(RESULT_BAD_ARGUMENT);

    unsigned char r, g, b;
    mixbox_lerp((unsigned char)(c1 >> 16), (unsigned char)(c1 >> 8), (unsigned char)c1,
                (unsigned char)(c2 >> 16), (unsigned char)(c2 >> 8), (unsigned char)c2,
                (float)t, &r, &g, &b);
    return newInt(((int32_t)r << 16) | ((int32_t)g << 8) | b);
}

// hardwareThreads():int
static FREObject HardwareThreads(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    return newInt((int32_t)std::thread::hardware_concurrency());
}

static void ContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctions, const FRENamedFunction** functions)
{
    static FRENamedFunction list[3];
    list[0].name = (const uint8_t*)"composite";
    list[0].functionData = NULL;
    list[0].function = &Composite;
    list[1].name = (const uint8_t*)"lerpRef";
    list[1].functionData = NULL;
    list[1].function = &LerpRef;
    list[2].name = (const uint8_t*)"hardwareThreads";
    list[2].functionData = NULL;
    list[2].function = &HardwareThreads;
    *numFunctions = 3;
    *functions = list;

    // LUT 압축 풀기를 첫 합성 전에 끝내둠
    mixbox_lut();
}

static void ContextFinalizer(FREContext ctx)
{
}

FOFO_EXPORT void PigmentMixExtInit(void** extData, FREContextInitializer* contextInitializer, FREContextFinalizer* contextFinalizer)
{
    *extData = NULL;
    *contextInitializer = &ContextInitializer;
    *contextFinalizer = &ContextFinalizer;
}

FOFO_EXPORT void PigmentMixExtFin(void* extData)
{
}
