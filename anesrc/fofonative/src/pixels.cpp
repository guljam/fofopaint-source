// 픽셀 덤프/복원 (이전 com.fofo.pixeldump를 옮겨옴)과 저장용 변환
// 불러오기: copyPixelsToByteArray로 저장해둔 픽셀을 BitmapData 내부 버퍼에 원래 값 그대로 써넣음
//   AS3 setPixels는 premultiply 변환에서 반투명 픽셀이 1씩 어두워지는데, 이걸 거치지 않고 복원하려고 씀
//   AS3쪽 PixelRestore가 런타임을 측정해서 만든 표(출력값 -> 내부 premultiplied 값)를 setRestoreTable로 넘겨줌
// 저장: 내부 버퍼를 복사해서 copyPixelsToByteArray와 비트 단위로 같은 바이트를 만듬
//   표(내부값 -> 출력값)는 fillSaveProbe로 알려진 내부값을 직접 쓴 비트맵을 AS3가 copyPixelsToByteArray해서 setSaveTable로 넘겨줌
#include "common.h"
#include "pixels.h"
#include "png.h"

uint8_t gRestoreTable[PIXEL_TABLE_LENGTH];
bool gHasRestoreTable = false;
uint8_t gSaveTable[PIXEL_TABLE_LENGTH];
bool gHasSaveTable = false;
uint8_t gPngTable[PIXEL_TABLE_LENGTH];
bool gHasPngTable = false;

// 병렬로 나눌때 한 조각의 행 수
#define ROWS_PER_BAND 64

void restoreStraightRow(const uint8_t* source, uint32_t* target, uint32_t width)
{
    for (uint32_t x = 0; x < width; x++)
    {
        const uint32_t alpha = source[0];
        uint32_t red = source[1];
        uint32_t green = source[2];
        uint32_t blue = source[3];

        if (alpha == 0)
        {
            red = green = blue = 0;
        }
        else if (alpha != 255)
        {
            const uint8_t* table = gRestoreTable + (alpha << 8);
            red = table[red];
            green = table[green];
            blue = table[blue];
        }

        // 호스트 엔디언 32비트 ARGB
        target[x] = (alpha << 24) | (red << 16) | (green << 8) | blue;
        source += 4;
    }
}

void saveStraightRow(const uint32_t* source, uint8_t* target, uint32_t width, const uint8_t* tables)
{
    for (uint32_t x = 0; x < width; x++)
    {
        const uint32_t pixel = source[x];
        const uint32_t alpha = pixel >> 24;
        const uint8_t* table = tables + (alpha << 8);
        target[0] = (uint8_t)alpha;
        target[1] = table[(pixel >> 16) & 0xFF];
        target[2] = table[(pixel >> 8) & 0xFF];
        target[3] = table[pixel & 0xFF];
        target += 4;
    }
}

int snapshotBitmap(FREObject object, PixelImage& image, TaskPriority priority)
{
    FREBitmapData2 bitmap;

    if (FREAcquireBitmapData2(object, &bitmap) != FRE_OK)
        return RESULT_BITMAP_ACQUIRE_FAILED;

    if (!bitmap.isPremultiplied)
    {
        FREReleaseBitmapData(object);
        return RESULT_UNSUPPORTED_FORMAT;
    }

    try
    {
        image.width = bitmap.width;
        image.height = bitmap.height;
        image.invertedY = bitmap.isInvertedY != 0;
        image.transparent = bitmap.hasAlpha != 0;
        image.pixels.resize((size_t)bitmap.width * bitmap.height);
    }
    catch (...)
    {
        FREReleaseBitmapData(object);
        image.pixels.clear();
        image.pixels.shrink_to_fit();
        return RESULT_OUT_OF_MEMORY;
    }

    const uint32_t width = bitmap.width;
    const uint32_t height = bitmap.height;
    const uint32_t stride = bitmap.lineStride32;
    const uint32_t* bits = bitmap.bits32;
    uint32_t* target = image.pixels.data();
    const int bands = (int)((height + ROWS_PER_BAND - 1) / ROWS_PER_BAND);
    const bool opaque = !bitmap.hasAlpha;

    auto copyBand = [&](int band)
    {
        const uint32_t start = (uint32_t)band * ROWS_PER_BAND;
        const uint32_t end = (start + ROWS_PER_BAND < height) ? start + ROWS_PER_BAND : height;

        for (uint32_t y = start; y < end; y++)
        {
            uint32_t* dst = target + (size_t)y * width;
            memcpy(dst, bits + (size_t)y * stride, (size_t)width * 4);

            // 불투명 비트맵은 알파 바이트가 0xFF가 아닐수도 있어서 맞춰줌 (copyPixelsToByteArray는 0xFF로 줌)
            if (opaque)
            {
                for (uint32_t x = 0; x < width; x++)
                    dst[x] |= 0xFF000000u;
            }
        }
    };

    pool::parallelFor(bands, priority, copyBand);
    FREReleaseBitmapData(object);
    return RESULT_OK;
}

void imageToStraight(const PixelImage& image, uint8_t* target, TaskPriority priority, const uint8_t* table)
{
    const uint32_t width = image.width;
    const uint32_t height = image.height;
    const int bands = (int)((height + ROWS_PER_BAND - 1) / ROWS_PER_BAND);

    auto convertBand = [&](int band)
    {
        const uint32_t start = (uint32_t)band * ROWS_PER_BAND;
        const uint32_t end = (start + ROWS_PER_BAND < height) ? start + ROWS_PER_BAND : height;

        for (uint32_t y = start; y < end; y++)
            saveStraightRow(image.row(y), target + (size_t)y * width * 4, width, table);
    };

    pool::parallelFor(bands, priority, convertBand);
}

// setRestoreTable(table:ByteArray):int
static FREObject SetRestoreTable(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    FREByteArray bytes;

    if (argc < 1 || FREAcquireByteArray(argv[0], &bytes) != FRE_OK)
        return newInt(RESULT_BYTES_ACQUIRE_FAILED);

    if (bytes.length < PIXEL_TABLE_LENGTH)
    {
        FREReleaseByteArray(argv[0]);
        return newInt(RESULT_NOT_ENOUGH_BYTES);
    }

    memcpy(gRestoreTable, bytes.bytes, PIXEL_TABLE_LENGTH);
    FREReleaseByteArray(argv[0]);
    gHasRestoreTable = true;
    return newInt(RESULT_OK);
}

// restore(bitmap:BitmapData, pixels:ByteArray, offset:int):int
// pixels는 offset부터 copyPixelsToByteArray 형식(A,R,G,B 순서, 위쪽 행부터), bitmap 전체 크기만큼 있어야함
static FREObject Restore(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    FREBitmapData2 bitmap;
    FREByteArray bytes;
    int32_t offset = 0;

    if (!gHasRestoreTable)
        return newInt(RESULT_NO_TABLE);

    if (argc < 3 || !getInt(argv[2], &offset) || offset < 0)
        return newInt(RESULT_BAD_ARGUMENT);

    if (FREAcquireBitmapData2(argv[0], &bitmap) != FRE_OK)
        return newInt(RESULT_BITMAP_ACQUIRE_FAILED);

    // 투명 + premultiplied 형식만 처리, 나머지는 AS3 setPixels로 처리하게 돌려보냄
    if (!bitmap.hasAlpha || !bitmap.isPremultiplied)
    {
        FREReleaseBitmapData(argv[0]);
        return newInt(RESULT_UNSUPPORTED_FORMAT);
    }

    if (FREAcquireByteArray(argv[1], &bytes) != FRE_OK)
    {
        FREReleaseBitmapData(argv[0]);
        return newInt(RESULT_BYTES_ACQUIRE_FAILED);
    }

    const uint64_t needed = (uint64_t)bitmap.width * bitmap.height * 4;

    if ((uint64_t)bytes.length < (uint64_t)offset + needed)
    {
        FREReleaseByteArray(argv[1]);
        FREReleaseBitmapData(argv[0]);
        return newInt(RESULT_NOT_ENOUGH_BYTES);
    }

    const uint8_t* source = bytes.bytes + offset;
    const uint32_t width = bitmap.width;
    const uint32_t height = bitmap.height;
    const int bands = (int)((height + ROWS_PER_BAND - 1) / ROWS_PER_BAND);

    auto restoreBand = [&](int band)
    {
        const uint32_t start = (uint32_t)band * ROWS_PER_BAND;
        const uint32_t end = (start + ROWS_PER_BAND < height) ? start + ROWS_PER_BAND : height;

        for (uint32_t y = start; y < end; y++)
        {
            // isInvertedY면 메모리에 아래 행부터 들어있음
            const uint32_t row = bitmap.isInvertedY ? (height - 1 - y) : y;
            restoreStraightRow(source + (size_t)y * width * 4, bitmap.bits32 + (size_t)row * bitmap.lineStride32, width);
        }
    };

    pool::parallelFor(bands, PRIORITY_SAVE, restoreBand);
    FREReleaseByteArray(argv[1]);
    FREInvalidateBitmapDataRect(argv[0], 0, 0, bitmap.width, bitmap.height);
    FREReleaseBitmapData(argv[0]);
    return newInt(RESULT_OK);
}

// fillSaveProbe(bitmap:BitmapData):int
// 256x256 투명 비트맵의 (x, y) 픽셀 내부값을 알파 y, R=G=B=x로 직접 씀 (x > y인 값은 premultiplied로는 나오지 않아서 setSaveTable이 무시함)
static FREObject FillSaveProbe(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    FREBitmapData2 bitmap;

    if (argc < 1 || FREAcquireBitmapData2(argv[0], &bitmap) != FRE_OK)
        return newInt(RESULT_BITMAP_ACQUIRE_FAILED);

    if (!bitmap.hasAlpha || !bitmap.isPremultiplied || bitmap.width != 256 || bitmap.height != 256)
    {
        FREReleaseBitmapData(argv[0]);
        return newInt(RESULT_UNSUPPORTED_FORMAT);
    }

    for (uint32_t y = 0; y < 256; y++)
    {
        const uint32_t row = bitmap.isInvertedY ? (255 - y) : y;
        uint32_t* target = bitmap.bits32 + (size_t)row * bitmap.lineStride32;

        for (uint32_t x = 0; x < 256; x++)
            target[x] = (y << 24) | (x << 16) | (x << 8) | x;
    }

    FREInvalidateBitmapDataRect(argv[0], 0, 0, 256, 256);
    FREReleaseBitmapData(argv[0]);
    return newInt(RESULT_OK);
}

// setSaveTable(probeOutput:ByteArray):int
// probeOutput: fillSaveProbe 비트맵을 copyPixelsToByteArray한 결과 (256*256*4)
static FREObject SetSaveTable(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    FREByteArray bytes;

    if (argc < 1 || FREAcquireByteArray(argv[0], &bytes) != FRE_OK)
        return newInt(RESULT_BYTES_ACQUIRE_FAILED);

    if (bytes.length < PIXEL_TABLE_LENGTH * 4)
    {
        FREReleaseByteArray(argv[0]);
        return newInt(RESULT_NOT_ENOUGH_BYTES);
    }

    uint8_t table[PIXEL_TABLE_LENGTH];
    bool valid = true;

    for (uint32_t i = 0; i < PIXEL_TABLE_LENGTH && valid; i++)
    {
        const uint8_t* p = bytes.bytes + (size_t)i * 4;

        // 색 > 알파인 내부값은 premultiplied로는 나올 수 없고, 런타임은 이런 값에서 알파까지 바뀐 엉뚱한 값을 냄 (실측) -> 표에서 빼고 255로 둠
        if ((i & 0xFF) > (i >> 8))
        {
            table[i] = 255;
            continue;
        }

        // 출력의 알파는 그대로여야 하고, 같은 내부값을 쓴 세 채널은 같은 출력이 나와야 함 (채널별 변환인지 확인)
        valid = p[0] == (uint8_t)(i >> 8) && p[1] == p[2] && p[2] == p[3];
        table[i] = p[1];
    }

    FREReleaseByteArray(argv[0]);

    if (!valid)
    {
        gHasSaveTable = false;
        return newInt(RESULT_UNSUPPORTED_FORMAT);
    }

    memcpy(gSaveTable, table, PIXEL_TABLE_LENGTH);
    gHasSaveTable = true;
    return newInt(RESULT_OK);
}

// toStraight(bitmap:BitmapData, output:ByteArray):int
// copyPixelsToByteArray(bitmap.rect, output)와 같은 바이트를 output의 position부터 씀 (자체 검증과 테스트용)
static FREObject ToStraight(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    if (!gHasSaveTable)
        return newInt(RESULT_NO_TABLE);

    if (argc < 2)
        return newInt(RESULT_BAD_ARGUMENT);

    PixelImage image;
    const int snap = snapshotBitmap(argv[0], image, PRIORITY_SAVE);

    if (snap != RESULT_OK)
        return newInt(snap);

    // ByteArray 길이를 늘리려면 position과 length 속성을 AS3 쪽에서 맞춰줘야 해서 여기서는 길이가 충분한지만 봄
    FREByteArray bytes;

    if (FREAcquireByteArray(argv[1], &bytes) != FRE_OK)
        return newInt(RESULT_BYTES_ACQUIRE_FAILED);

    if (bytes.length < image.byteSize())
    {
        FREReleaseByteArray(argv[1]);
        return newInt(RESULT_NOT_ENOUGH_BYTES);
    }

    imageToStraight(image, bytes.bytes, PRIORITY_SAVE);
    FREReleaseByteArray(argv[1]);
    return newInt(RESULT_OK);
}

// setPngTable(png:ByteArray):int
// png: fillSaveProbe 비트맵을 AIR encode(PNGEncoderOptions)한 PNG, 색 <= 알파인 칸만 표로 씀
static FREObject SetPngTable(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    FREByteArray bytes;

    if (argc < 1 || FREAcquireByteArray(argv[0], &bytes) != FRE_OK)
        return newInt(RESULT_BYTES_ACQUIRE_FAILED);

    uint32_t width = 0;
    uint32_t height = 0;
    Bytes rgba;
    const bool decoded = decodePngRgba(bytes.bytes, bytes.length, &width, &height, rgba);
    FREReleaseByteArray(argv[0]);

    if (!decoded || width != 256 || height != 256)
        return newInt(RESULT_UNSUPPORTED_FORMAT);

    uint8_t table[PIXEL_TABLE_LENGTH];
    bool valid = true;

    for (uint32_t i = 0; i < PIXEL_TABLE_LENGTH && valid; i++)
    {
        const uint8_t* p = rgba.data() + (size_t)i * 4; // R,G,B,A

        if ((i & 0xFF) > (i >> 8))
        {
            table[i] = 255;
            continue;
        }

        valid = p[3] == (uint8_t)(i >> 8) && p[0] == p[1] && p[1] == p[2];
        table[i] = p[0];
    }

    if (!valid)
    {
        gHasPngTable = false;
        return newInt(RESULT_UNSUPPORTED_FORMAT);
    }

    memcpy(gPngTable, table, PIXEL_TABLE_LENGTH);
    gHasPngTable = true;
    return newInt(RESULT_OK);
}

// checkPngTable(bitmap:BitmapData, airPng:ByteArray):int
// AIR가 bitmap을 encode한 PNG의 픽셀 값이 네이티브 PNG 표로 바꾼 값과 같은지 (같으면 1, 다르면 0)
static FREObject CheckPngTable(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    if (!gHasPngTable || argc < 2)
        return newInt(RESULT_NO_TABLE);

    PixelImage image;
    const int snap = snapshotBitmap(argv[0], image, PRIORITY_SAVE);

    if (snap != RESULT_OK)
        return newInt(snap);

    FREByteArray bytes;

    if (FREAcquireByteArray(argv[1], &bytes) != FRE_OK)
        return newInt(RESULT_BYTES_ACQUIRE_FAILED);

    uint32_t width = 0;
    uint32_t height = 0;
    Bytes rgba;
    const bool decoded = decodePngRgba(bytes.bytes, bytes.length, &width, &height, rgba);
    FREReleaseByteArray(argv[1]);

    if (!decoded || width != image.width || height != image.height)
        return newInt(RESULT_UNSUPPORTED_FORMAT);

    Bytes straight(image.byteSize());
    imageToStraight(image, straight.data(), PRIORITY_SAVE, gPngTable);

    for (size_t i = 0; i < straight.size(); i += 4)
    {
        // straight는 A,R,G,B, PNG는 R,G,B,A
        if (straight[i] != rgba[i + 3] || straight[i + 1] != rgba[i] || straight[i + 2] != rgba[i + 1] || straight[i + 3] != rgba[i + 2])
            return newInt(0);
    }

    return newInt(RESULT_OK);
}

static const NamedFunction gPixelFunctions[] = {
    { "setPngTable", &SetPngTable },
    { "checkPngTable", &CheckPngTable },
    { "setRestoreTable", &SetRestoreTable },
    { "restore", &Restore },
    { "fillSaveProbe", &FillSaveProbe },
    { "setSaveTable", &SetSaveTable },
    { "toStraight", &ToStraight },
};

const NamedFunction* pixelFunctions(uint32_t* count)
{
    *count = sizeof(gPixelFunctions) / sizeof(gPixelFunctions[0]);
    return gPixelFunctions;
}
