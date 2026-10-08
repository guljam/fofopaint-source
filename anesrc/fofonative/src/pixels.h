// 픽셀 변환표와 행 단위 변환
#pragma once
#include <stdint.h>

#define PIXEL_TABLE_LENGTH 65536

// [알파 << 8 | copyPixelsToByteArray 출력값] -> 내부 premultiplied 값
extern uint8_t gRestoreTable[PIXEL_TABLE_LENGTH];
extern bool gHasRestoreTable;

// straight ARGB(바이트 순서 A,R,G,B) 한 행을 내부 premultiplied 값(호스트 엔디언 32비트 ARGB)으로
void restoreStraightRow(const uint8_t* source, uint32_t* target, uint32_t width);
