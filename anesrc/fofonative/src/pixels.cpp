// 픽셀 덤프/복원 (이전 com.fofo.pixeldump를 옮겨옴)
// copyPixelsToByteArray로 저장해둔 픽셀을 BitmapData 내부 버퍼에 원래 값 그대로 써넣음
// AS3 setPixels는 premultiply 변환에서 반투명 픽셀이 1씩 어두워지는데, 이걸 거치지 않고 복원하려고 씀
// AS3쪽 PixelRestore가 런타임을 측정해서 만든 표(출력값 -> 내부 premultiplied 값)를 setRestoreTable로 넘겨줌
#include "common.h"
#include "pixels.h"

// [알파 << 8 | copyPixelsToByteArray 출력값] -> 내부 premultiplied 값
uint8_t gRestoreTable[PIXEL_TABLE_LENGTH];
bool gHasRestoreTable = false;

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

    for (uint32_t y = 0; y < bitmap.height; y++)
    {
        // isInvertedY면 메모리에 아래 행부터 들어있음
        const uint32_t row = bitmap.isInvertedY ? (bitmap.height - 1 - y) : y;
        restoreStraightRow(source, bitmap.bits32 + (size_t)row * bitmap.lineStride32, bitmap.width);
        source += (size_t)bitmap.width * 4;
    }

    FREReleaseByteArray(argv[1]);
    FREInvalidateBitmapDataRect(argv[0], 0, 0, bitmap.width, bitmap.height);
    FREReleaseBitmapData(argv[0]);
    return newInt(RESULT_OK);
}

static const NamedFunction gPixelFunctions[] = {
    { "setRestoreTable", &SetRestoreTable },
    { "restore", &Restore },
};

const NamedFunction* pixelFunctions(uint32_t* count)
{
    *count = sizeof(gPixelFunctions) / sizeof(gPixelFunctions[0]);
    return gPixelFunctions;
}
