// 병렬 zlib 압축 (pigz 방식)과 압축 해제
// 입력을 조각으로 나눠 조각마다 따로 raw deflate (앞 조각 끝 32KB를 사전으로, 마지막 조각만 끝 블록)
// 조각들을 이어 붙이고 zlib 헤더 + adler32_combine 트레일러를 붙이면 하나의 정상 zlib 스트림이 됨 (AS3 uncompress로 읽힘)
#pragma once
#include <stdint.h>
#include <vector>
#include "pool.h"

typedef std::vector<uint8_t> Bytes;

// 순서대로 이으면 결과 스트림. 파일에 바로 흘려 쓸 수 있게 조각으로 둠
struct Pieces
{
    std::vector<Bytes> parts;

    uint64_t size() const
    {
        uint64_t total = 0;
        for (size_t i = 0; i < parts.size(); i++)
            total += parts[i].size();
        return total;
    }

    void clear()
    {
        std::vector<Bytes>().swap(parts);
    }

    Bytes join() const;
};

// level: zlib 압축 수준(1~9), 실패(메모리 부족 등)하면 false
bool zlibCompressParallel(const uint8_t* data, size_t length, int level, TaskPriority priority, Pieces& out);
// raw deflate 조각들만 (헤더·트레일러 없이), PNG IDAT처럼 앞뒤를 직접 붙이는 곳에서 씀. adler는 전체 입력의 adler32
bool deflateRawParallel(const uint8_t* data, size_t length, int level, TaskPriority priority, Pieces& out, uint32_t* adler);
// zlib 헤더 2바이트 (level에 맞는 FLEVEL)
void zlibHeader(int level, uint8_t header[2]);

// 한 번에 전체 해제 (zlib 또는 raw), expected 길이를 알면 넘김(0이면 모름)
bool zlibUncompress(const uint8_t* data, size_t length, Bytes& out, size_t expected);
bool inflateRawInto(const uint8_t* data, size_t length, uint8_t* out, size_t outLength);
// 한 덩어리 압축 (raw deflate, 독립 블록)
bool deflateRawSingle(const uint8_t* data, size_t length, int level, Bytes& out);

// crc32 (zlib과 같은 값), 저장 재사용 판단용
uint32_t crc32OfBytes(const uint8_t* data, size_t length);
// 조각들을 순서대로 이은 내용의 crc32
uint32_t crc32OfPieces(const Pieces& pieces);
// 큰 버퍼를 조각으로 나눠 풀에서 동시에 계산하고 crc32_combine으로 합침 (결과는 crc32OfBytes와 같음)
uint32_t crc32OfBytesParallel(const uint8_t* data, size_t length, TaskPriority priority);
