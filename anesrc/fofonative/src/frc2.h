// ReplayDataCodec(FRC2, VERSION 1, 세그먼트 형식 VERSION 2) 네이티브 구현
// 형식과 결과는 src/Modules/ReplayDataCodec.as와 같아야 함: 네이티브로 인코드한 것을 AS3 decode가, AS3로 인코드한 것을 네이티브 decode가 읽음
// 본문 LZMA는 AIR ByteArray.compress(LZMA)와 같은 LZMA_Alone 형식 (속성 5바이트 + 압축 전 크기 8바이트 LE + 데이터)
#pragma once
#include "zstream.h"
#include <string>
#include <vector>

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

// ---- 세그먼트 형식 (FRC2 버전 2) ----
// 리플레이를 명령 뭉치(writeObject 하나) 경계에서 잘라 조각마다 따로 FRC2 버전 1 블록으로 만들고 이어 붙임
// "FRC2" 2, u32 조각 수, 조각 표 [u32 원본 길이, u32 원본 crc32, u32 압축 길이, u32 압축 crc32] x 조각 수, 조각(FRC2 버전 1 블록)들. 정수는 빅엔디언
// 경계: 누적 프레임(명령 수)이 segmentFrames의 배수를 넘어서는 뭉치 바로 뒤. 내용만으로 정해지므로 같은 앞부분이면 언제나 같은 조각이 나옴
// 다시 저장할때 이전 .fofo에 원본 길이와 crc가 같은 조각이 있으면 그 압축 바이트를 읽어 풀어보고 원본과 같을때만 그대로 씀 (리플레이 데이터를 메모리에 들고 있지 않음)
const uint32_t FRC2_SEGMENT_FRAMES = 10000; // 디스크 캐시 이미지 간격(ReplayFileCache.REPLAY_DISK_CACHE_FRAME_INTERVAL), 타이밍 시트 구간과 같은 단위
const size_t FRC2_SEGMENT_HEAD_BYTES = 9; // "FRC2" + 버전 + 조각 수
const size_t FRC2_SEGMENT_ENTRY_BYTES = 16;

// 이전 .fofo의 조각 하나 (재사용 후보), fileOffset은 그 파일 안의 압축 바이트 위치
struct Frc2OldSegment
{
    uint32_t rawLength;
    uint32_t rawCrc;
    uint32_t compressedLength;
    uint32_t compressedCrc;
    uint64_t fileOffset;
};

// 재사용할 조각을 읽어올 이전 .fofo
struct Frc2ReuseSource
{
    std::wstring path;
    std::vector<Frc2OldSegment> segments;
};

// 세그먼트 인코드 결과 집계 (저장 결과 문자열과 테스트에 씀)
struct Frc2SegmentStats
{
    uint32_t segmentCount = 0;
    uint32_t reusedCount = 0; // 이전 .fofo에서 가져온 조각
    uint32_t rejectedCount = 0; // 원본 길이와 crc는 같았지만 압축 crc나 풀어본 결과가 달라서 새로 만든 조각
    uint64_t reusedRawBytes = 0;
};

// 세그먼트 형식으로 인코드, 새로 만든 조각은 encode -> decode 결과가 원본과 같은지 확인함
// reuse가 NULL이면 모든 조각을 새로 만듦. 조각들은 풀에서 동시에 처리
int frc2EncodeSegmentedVerified(const uint8_t* input, size_t length, uint32_t segmentFrames, const Frc2ReuseSource* reuse, TaskPriority priority,
    Pieces& out, Frc2SegmentStats& stats, std::string& error);
// 블록 앞 FRC2_SEGMENT_HEAD_BYTES 바이트가 세그먼트 형식이면 조각 수를 돌려줌, 아니면 -1
int64_t frc2SegmentCountFromHead(const uint8_t* head, size_t length);
// 조각 표(head 다음 바이트부터 count개)를 읽어 out에 넣음, fileOffset = blockFileOffset + 블록 안 위치. 표가 블록 길이를 넘으면 false
bool frc2ReadSegmentTable(const uint8_t* table, uint32_t count, uint64_t blockFileOffset, uint64_t blockLength, std::vector<Frc2OldSegment>& out);

// LZMA_Alone (AIR CompressionAlgorithm.LZMA와 같은 형식)
bool lzmaCompressAlone(const uint8_t* input, size_t length, Bytes& out, int level, uint32_t dictSize, int threads);
bool lzmaUncompressAlone(const uint8_t* input, size_t length, Bytes& out);

const NamedFunction* codecFunctions(uint32_t* count);
