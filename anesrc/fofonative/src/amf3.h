// AMF3 읽기/쓰기 (repdata 명령 뭉치에 나오는 형식만)
// 지원: undefined, null, false, true, 정수, 실수, 문자열, Array(연관 부분 없는 것), ByteArray, Vector.<int/uint/Number>
// 그 밖의 형식(Object, Date, XML, Dictionary, Vector.<Object>, 연관 부분 있는 Array)은 오류로 돌려주고 호출한 쪽이 AS3 경로로 처리함
// 숫자는 double 하나로 다룸. 쓸때는 AS3 writeObject와 같이 정수이고 -0이 아니고 29비트 범위면 정수 표기, 아니면 실수 표기
#pragma once
#include <stdint.h>
#include <string.h>
#include <vector>

enum AmfType : uint8_t
{
    AMF_UNDEFINED,
    AMF_NULL,
    AMF_FALSE,
    AMF_TRUE,
    AMF_NUMBER,
    AMF_STRING,
    AMF_ARRAY,
    AMF_BYTEARRAY,
    AMF_VECTOR_INT,
    AMF_VECTOR_UINT,
    AMF_VECTOR_DOUBLE
};

// 노드 하나, 참조로 같은 객체를 가리키면 같은 노드 번호를 씀
struct AmfNode
{
    AmfType type;
    uint8_t fixed; // Vector fixed
    uint32_t count; // 문자열/바이트 길이, 배열/Vector 원소 수
    union
    {
        double number;
        const uint8_t* bytes; // 문자열 UTF-8, ByteArray 내용, Vector 원소(빅엔디언 원본)
        uint32_t first; // 배열: children에서 첫 원소 위치
    };
};

// 한 번의 readObject/writeObject 범위의 노드 모음 (뭉치마다 비우고 다시 씀)
struct AmfArena
{
    std::vector<AmfNode> nodes;
    std::vector<uint32_t> children;

    void clear()
    {
        nodes.clear();
        children.clear();
    }

    uint32_t add(const AmfNode& node)
    {
        nodes.push_back(node);
        return (uint32_t)nodes.size() - 1;
    }

    uint32_t addNumber(double value)
    {
        AmfNode node;
        node.type = AMF_NUMBER;
        node.fixed = 0;
        node.count = 0;
        node.number = value;
        return add(node);
    }

    uint32_t addString(const uint8_t* text, uint32_t length)
    {
        AmfNode node;
        node.type = AMF_STRING;
        node.fixed = 0;
        node.count = length;
        node.bytes = text;
        return add(node);
    }

    uint32_t addSimple(AmfType type)
    {
        AmfNode node;
        node.type = type;
        node.fixed = 0;
        node.count = 0;
        node.number = 0;
        return add(node);
    }

    // 원소 count개 자리를 미리 잡은 배열
    uint32_t addArray(uint32_t count)
    {
        AmfNode node;
        node.type = AMF_ARRAY;
        node.fixed = 0;
        node.count = count;
        node.first = (uint32_t)children.size();
        children.resize(children.size() + count, 0);
        return add(node);
    }
};

// 입력에서 AMF3 값 하나를 읽음 (readObject 한 번, 참조 표는 호출마다 새로)
class AmfReader
{
public:
    AmfReader(const uint8_t* data, size_t length) : data(data), length(length), position(0) {}

    // 성공하면 true와 노드 번호, 지원하지 않는 형식이나 깨진 데이터면 false
    bool readValue(AmfArena& arena, uint32_t* node);
    size_t pos() const { return position; }
    void seek(size_t value) { position = value; }
    size_t remaining() const { return length - position; }

private:
    const uint8_t* data;
    size_t length;
    size_t position;
    std::vector<uint32_t> stringStarts; // 문자열 표: (시작 위치, 길이)를 2개씩
    std::vector<uint32_t> objects; // 객체 표: 노드 번호

    bool readU29(uint32_t* value);
    bool readString(const uint8_t** text, uint32_t* length);
    bool readNode(AmfArena& arena, uint32_t* node, int depth);
};

// AMF3 값 쓰기 (writeObject 한 번, 참조 표는 객체마다 새로)
class AmfWriter
{
public:
    explicit AmfWriter(std::vector<uint8_t>& out) : out(out) {}
    // 성공하면 true (깊이 초과 등은 false)
    bool writeValue(const AmfArena& arena, uint32_t node);

private:
    std::vector<uint8_t>& out;
    struct StringEntry
    {
        const uint8_t* text;
        uint32_t length;
    };
    std::vector<StringEntry> strings;
    std::vector<int32_t> stringSlots; // 해시 슬롯 -> strings 번호, -1이면 비어있음
    std::vector<int32_t> objectIndex; // 노드 번호 -> 객체 표 번호, -1이면 아직
    int32_t objectCount = 0;

    void writeU29(uint32_t value);
    void writeString(const uint8_t* text, uint32_t length);
    bool writeNode(const AmfArena& arena, uint32_t node, int depth);
};

// AS3 숫자 규칙
bool amfIsIntegerEncodable(double value);
// 올바른 UTF-8인지 (서로게이트, 너무 긴 표기 없음)
bool isValidUtf8(const uint8_t* text, size_t length);
