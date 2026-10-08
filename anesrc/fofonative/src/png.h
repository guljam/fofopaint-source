// PNG 인코더: 내부 버퍼 스냅샷 -> 저장표로 straight 변환 -> 행 필터(병렬) -> 병렬 deflate IDAT
#pragma once
#include "pixels.h"
#include "zstream.h"

// 결과는 PNG 파일 전체를 순서대로 이은 조각들 (파일에 바로 흘려 씀)
bool encodePng(const PixelImage& image, int level, TaskPriority priority, Pieces& out);
// 8비트 RGB/RGBA PNG를 RGBA 바이트(위 행부터)로 (표 측정과 검증용, 인터레이스 안 됨)
bool decodePngRgba(const uint8_t* data, size_t length, uint32_t* width, uint32_t* height, Bytes& rgba);
