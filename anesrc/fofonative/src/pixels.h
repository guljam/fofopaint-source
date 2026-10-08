// 픽셀 변환표, BitmapData 스냅샷, 행 단위 변환
#pragma once
#include <stdint.h>
#include <vector>
#include "pool.h"

#define PIXEL_TABLE_LENGTH 65536

// [알파 << 8 | copyPixelsToByteArray 출력값] -> 내부 premultiplied 값 (불러오기)
extern uint8_t gRestoreTable[PIXEL_TABLE_LENGTH];
extern bool gHasRestoreTable;
// [알파 << 8 | 내부 premultiplied 값] -> copyPixelsToByteArray 출력값 (저장)
extern uint8_t gSaveTable[PIXEL_TABLE_LENGTH];
extern bool gHasSaveTable;
// [알파 << 8 | 내부 premultiplied 값] -> AIR encode(PNGEncoderOptions)가 PNG에 쓰는 값 (copyPixelsToByteArray와 반올림이 다름, 실측)
extern uint8_t gPngTable[PIXEL_TABLE_LENGTH];
extern bool gHasPngTable;

// straight ARGB(바이트 순서 A,R,G,B) 한 행을 내부 premultiplied 값(호스트 엔디언 32비트 ARGB)으로
void restoreStraightRow(const uint8_t* source, uint32_t* target, uint32_t width);
// 내부값 한 행을 표(gSaveTable이면 copyPixelsToByteArray와 같은 바이트)로 A,R,G,B 바이트로
void saveStraightRow(const uint32_t* source, uint8_t* target, uint32_t width, const uint8_t* table);

// BitmapData 내부 버퍼 복사본 (FRE 호출 밖, 다른 스레드에서 쓰려고)
// pixels는 메모리 순서 그대로: invertedY면 아래 행부터, 각 픽셀은 호스트 엔디언 32비트 premultiplied ARGB(메모리 B,G,R,A)
struct PixelImage
{
    uint32_t width = 0;
    uint32_t height = 0;
    bool invertedY = false;
    bool transparent = true;
    std::vector<uint32_t> pixels;

    size_t byteSize() const { return (size_t)width * height * 4; }
    // 위에서 y번째 행
    const uint32_t* row(uint32_t y) const
    {
        const uint32_t memoryRow = invertedY ? (height - 1 - y) : y;
        return pixels.data() + (size_t)memoryRow * width;
    }
};

// FRE 호출 안에서만 부를 것. 실패하면 결과 코드(RESULT_*) 음수, 성공하면 RESULT_OK
int snapshotBitmap(FREObject object, PixelImage& image, TaskPriority priority);
// image 전체를 straight ARGB 바이트(위 행부터, copyPixelsToByteArray 형식)로, 병렬
void imageToStraight(const PixelImage& image, uint8_t* target, TaskPriority priority, const uint8_t* table = gSaveTable);

const NamedFunction* pixelFunctions(uint32_t* count);
