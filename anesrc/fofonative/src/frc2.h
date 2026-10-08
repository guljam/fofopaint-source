// ReplayDataCodec(FRC2, VERSION 1) 네이티브 구현
// 형식과 결과는 src/Modules/ReplayDataCodec.as와 같아야 함: 네이티브로 인코드한 것을 AS3 decode가, AS3로 인코드한 것을 네이티브 decode가 읽음
// 본문 LZMA는 AIR ByteArray.compress(LZMA)와 같은 LZMA_Alone 형식 (속성 5바이트 + 압축 전 크기 8바이트 LE + 데이터)
#pragma once
#include "zstream.h"
#include <string>

enum Frc2Result
{
    FRC2_OK = 1,
    FRC2_UNSUPPORTED = -20, // 지원하지 않는 AMF3 형식이나 AS3가 거부하는 데이터 -> AS3 경로
    FRC2_CORRUPT = -21, // 깨진 데이터
    FRC2_VERIFY_FAILED = -22, // 인코드 -> 디코드 결과가 원본과 다름
    FRC2_OUT_OF_MEMORY = -23,
    FRC2_LZMA_FAILED = -24
};

int frc2Encode(const uint8_t* input, size_t length, Bytes& out, std::string& error);
int frc2Decode(const uint8_t* input, size_t length, Bytes& out, std::string& error);
// encode 후 decode 결과가 원본과 바이트 단위로 같을때만 FRC2_OK
int frc2EncodeVerified(const uint8_t* input, size_t length, Bytes& out, std::string& error);

// LZMA_Alone (AIR CompressionAlgorithm.LZMA와 같은 형식)
bool lzmaCompressAlone(const uint8_t* input, size_t length, Bytes& out, int level, uint32_t dictSize, int threads);
bool lzmaUncompressAlone(const uint8_t* input, size_t length, Bytes& out);

const NamedFunction* codecFunctions(uint32_t* count);
