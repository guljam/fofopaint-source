// AMF3 읽기/쓰기
#include "amf3.h"
#include <math.h>

namespace
{
    const int MAX_DEPTH = 64;

    uint32_t hashBytes(const uint8_t* text, uint32_t length)
    {
        uint32_t h = 2166136261u;

        for (uint32_t i = 0; i < length; i++)
            h = (h ^ text[i]) * 16777619u;

        return h;
    }

    double readDoubleBE(const uint8_t* p)
    {
        uint64_t bits = 0;

        for (int i = 0; i < 8; i++)
            bits = (bits << 8) | p[i];

        double value;
        memcpy(&value, &bits, 8);
        return value;
    }
}

bool amfIsIntegerEncodable(double value)
{
    // AS3 writeObject: int 원자(정수, -0 아님)이고 29비트 범위면 정수 표기
    if (!(value >= -268435456.0 && value <= 268435455.0))
        return false;

    if (value != floor(value))
        return false;

    if (value == 0 && signbit(value))
        return false;

    return true;
}

bool isValidUtf8(const uint8_t* text, size_t length)
{
    size_t i = 0;

    while (i < length)
    {
        const uint8_t c = text[i];

        if (c < 0x80)
        {
            i++;
            continue;
        }

        uint32_t code;
        size_t extra;

        if ((c & 0xE0) == 0xC0)
        {
            code = c & 0x1F;
            extra = 1;
        }
        else if ((c & 0xF0) == 0xE0)
        {
            code = c & 0x0F;
            extra = 2;
        }
        else if ((c & 0xF8) == 0xF0)
        {
            code = c & 0x07;
            extra = 3;
        }
        else
        {
            return false;
        }

        // i + extra는 이 글자의 마지막 바이트 위치
        if (i + extra >= length)
            return false;

        for (size_t k = 1; k <= extra; k++)
        {
            if ((text[i + k] & 0xC0) != 0x80)
                return false;

            code = (code << 6) | (text[i + k] & 0x3F);
        }

        // 너무 긴 표기, 서로게이트, 범위 밖
        if ((extra == 1 && code < 0x80) || (extra == 2 && code < 0x800) || (extra == 3 && code < 0x10000))
            return false;

        if ((code >= 0xD800 && code <= 0xDFFF) || code > 0x10FFFF)
            return false;

        i += extra + 1;
    }

    return true;
}

// ---- 읽기 ----

bool AmfReader::readU29(uint32_t* value)
{
    uint32_t result = 0;

    for (int i = 0; i < 4; i++)
    {
        if (position >= length)
            return false;

        const uint8_t b = data[position++];

        if (i < 3)
        {
            result = (result << 7) | (b & 0x7F);

            if ((b & 0x80) == 0)
            {
                *value = result;
                return true;
            }
        }
        else
        {
            result = (result << 8) | b;
        }
    }

    *value = result;
    return true;
}

bool AmfReader::readString(const uint8_t** text, uint32_t* stringLength)
{
    uint32_t header;

    if (!readU29(&header))
        return false;

    if ((header & 1) == 0)
    {
        const uint32_t index = header >> 1;

        if ((size_t)index * 2 + 1 >= stringStarts.size())
            return false;

        *text = data + stringStarts[index * 2];
        *stringLength = stringStarts[index * 2 + 1];
        return true;
    }

    const uint32_t byteLength = header >> 1;

    if (byteLength > length - position)
        return false;

    *text = data + position;
    *stringLength = byteLength;

    if (!isValidUtf8(*text, byteLength))
        return false;

    if (byteLength > 0)
    {
        stringStarts.push_back((uint32_t)position);
        stringStarts.push_back(byteLength);
    }

    position += byteLength;
    return true;
}

bool AmfReader::readValue(AmfArena& arena, uint32_t* node)
{
    stringStarts.clear();
    objects.clear();
    return readNode(arena, node, 0);
}

bool AmfReader::readNode(AmfArena& arena, uint32_t* node, int depth)
{
    if (depth > MAX_DEPTH || position >= length)
        return false;

    const uint8_t marker = data[position++];

    switch (marker)
    {
    case 0x00:
        *node = arena.addSimple(AMF_UNDEFINED);
        return true;
    case 0x01:
        *node = arena.addSimple(AMF_NULL);
        return true;
    case 0x02:
        *node = arena.addSimple(AMF_FALSE);
        return true;
    case 0x03:
        *node = arena.addSimple(AMF_TRUE);
        return true;
    case 0x04:
    {
        uint32_t value;

        if (!readU29(&value))
            return false;

        // 29비트 부호 확장
        const int32_t signedValue = (value & 0x10000000) ? (int32_t)(value | 0xE0000000u) : (int32_t)value;
        *node = arena.addNumber((double)signedValue);
        return true;
    }
    case 0x05:
    {
        if (length - position < 8)
            return false;

        *node = arena.addNumber(readDoubleBE(data + position));
        position += 8;
        return true;
    }
    case 0x06:
    {
        const uint8_t* text;
        uint32_t textLength;

        if (!readString(&text, &textLength))
            return false;

        *node = arena.addString(text, textLength);
        return true;
    }
    case 0x09:
    {
        uint32_t header;

        if (!readU29(&header))
            return false;

        if ((header & 1) == 0)
        {
            const uint32_t index = header >> 1;

            if (index >= objects.size())
                return false;

            *node = objects[index];
            return true;
        }

        const uint32_t count = header >> 1;

        // 연관 부분이 있으면 지원하지 않음 (AS3 쓰기 순서를 알 수 없음)
        if (position >= length || data[position] != 0x01)
            return false;

        position++;

        if (count > length - position)
            return false; // 원소마다 최소 1바이트

        const uint32_t array = arena.addArray(count);
        objects.push_back(array);
        const uint32_t first = arena.nodes[array].first;

        for (uint32_t i = 0; i < count; i++)
        {
            uint32_t child;

            if (!readNode(arena, &child, depth + 1))
                return false;

            arena.children[first + i] = child;
        }

        *node = array;
        return true;
    }
    case 0x0C:
    {
        uint32_t header;

        if (!readU29(&header))
            return false;

        if ((header & 1) == 0)
        {
            const uint32_t index = header >> 1;

            if (index >= objects.size())
                return false;

            *node = objects[index];
            return true;
        }

        const uint32_t byteLength = header >> 1;

        if (byteLength > length - position)
            return false;

        AmfNode bytes;
        bytes.type = AMF_BYTEARRAY;
        bytes.fixed = 0;
        bytes.count = byteLength;
        bytes.bytes = data + position;
        position += byteLength;
        *node = arena.add(bytes);
        objects.push_back(*node);
        return true;
    }
    case 0x0D:
    case 0x0E:
    case 0x0F:
    {
        uint32_t header;

        if (!readU29(&header))
            return false;

        if ((header & 1) == 0)
        {
            const uint32_t index = header >> 1;

            if (index >= objects.size())
                return false;

            *node = objects[index];
            return true;
        }

        const uint32_t count = header >> 1;
        const size_t itemSize = (marker == 0x0F) ? 8 : 4;

        if (position >= length)
            return false;

        const uint8_t fixed = data[position++];

        if ((uint64_t)count * itemSize > (uint64_t)(length - position))
            return false;

        AmfNode vector;
        vector.type = (marker == 0x0D) ? AMF_VECTOR_INT : (marker == 0x0E) ? AMF_VECTOR_UINT : AMF_VECTOR_DOUBLE;
        vector.fixed = fixed ? 1 : 0;
        vector.count = count;
        vector.bytes = data + position;
        position += (size_t)count * itemSize;
        *node = arena.add(vector);
        objects.push_back(*node);
        return true;
    }
    default:
        // 0x07 XMLDoc, 0x08 Date, 0x0A Object, 0x0B XML, 0x10 Vector.<Object>, 0x11 Dictionary
        return false;
    }
}

// ---- 쓰기 ----

void AmfWriter::writeU29(uint32_t value)
{
    value &= 0x1FFFFFFF;

    if (value < 0x80)
    {
        out.push_back((uint8_t)value);
    }
    else if (value < 0x4000)
    {
        out.push_back((uint8_t)((value >> 7) | 0x80));
        out.push_back((uint8_t)(value & 0x7F));
    }
    else if (value < 0x200000)
    {
        out.push_back((uint8_t)((value >> 14) | 0x80));
        out.push_back((uint8_t)(((value >> 7) & 0x7F) | 0x80));
        out.push_back((uint8_t)(value & 0x7F));
    }
    else
    {
        out.push_back((uint8_t)((value >> 22) | 0x80));
        out.push_back((uint8_t)(((value >> 15) & 0x7F) | 0x80));
        out.push_back((uint8_t)(((value >> 8) & 0x7F) | 0x80));
        out.push_back((uint8_t)(value & 0xFF));
    }
}

void AmfWriter::writeString(const uint8_t* text, uint32_t length)
{
    if (length == 0)
    {
        out.push_back(0x01);
        return;
    }

    if (stringSlots.empty())
        stringSlots.assign(1024, -1);

    const uint32_t mask = (uint32_t)stringSlots.size() - 1;
    uint32_t slot = hashBytes(text, length) & mask;

    while (stringSlots[slot] >= 0)
    {
        const StringEntry& entry = strings[stringSlots[slot]];

        if (entry.length == length && memcmp(entry.text, text, length) == 0)
        {
            writeU29((uint32_t)stringSlots[slot] << 1);
            return;
        }

        slot = (slot + 1) & mask;
    }

    stringSlots[slot] = (int32_t)strings.size();
    StringEntry entry = { text, length };
    strings.push_back(entry);

    // 반 넘게 차면 키움
    if (strings.size() * 2 > stringSlots.size())
    {
        std::vector<int32_t> bigger(stringSlots.size() * 2, -1);
        const uint32_t biggerMask = (uint32_t)bigger.size() - 1;

        for (size_t i = 0; i < strings.size(); i++)
        {
            uint32_t s = hashBytes(strings[i].text, strings[i].length) & biggerMask;

            while (bigger[s] >= 0)
                s = (s + 1) & biggerMask;

            bigger[s] = (int32_t)i;
        }

        stringSlots.swap(bigger);
    }

    writeU29((length << 1) | 1);
    out.insert(out.end(), text, text + length);
}

bool AmfWriter::writeValue(const AmfArena& arena, uint32_t node)
{
    strings.clear();
    stringSlots.clear();
    objectIndex.assign(arena.nodes.size(), -1);
    objectCount = 0;
    return writeNode(arena, node, 0);
}

bool AmfWriter::writeNode(const AmfArena& arena, uint32_t index, int depth)
{
    if (depth > MAX_DEPTH)
        return false;

    const AmfNode& node = arena.nodes[index];

    switch (node.type)
    {
    case AMF_UNDEFINED:
        out.push_back(0x00);
        return true;
    case AMF_NULL:
        out.push_back(0x01);
        return true;
    case AMF_FALSE:
        out.push_back(0x02);
        return true;
    case AMF_TRUE:
        out.push_back(0x03);
        return true;
    case AMF_NUMBER:
        if (amfIsIntegerEncodable(node.number))
        {
            out.push_back(0x04);
            writeU29((uint32_t)(int32_t)node.number);
        }
        else
        {
            out.push_back(0x05);
            uint64_t bits;
            memcpy(&bits, &node.number, 8);

            for (int i = 7; i >= 0; i--)
                out.push_back((uint8_t)(bits >> (i * 8)));
        }
        return true;
    case AMF_STRING:
        out.push_back(0x06);
        writeString(node.bytes, node.count);
        return true;
    default:
        break;
    }

    // 객체 표 (Array, ByteArray, Vector)
    const uint8_t marker = (node.type == AMF_ARRAY) ? 0x09 : (node.type == AMF_BYTEARRAY) ? 0x0C
        : (node.type == AMF_VECTOR_INT) ? 0x0D : (node.type == AMF_VECTOR_UINT) ? 0x0E : 0x0F;
    out.push_back(marker);

    if (objectIndex[index] >= 0)
    {
        writeU29((uint32_t)objectIndex[index] << 1);
        return true;
    }

    objectIndex[index] = objectCount++;
    writeU29((node.count << 1) | 1);

    switch (node.type)
    {
    case AMF_ARRAY:
        out.push_back(0x01); // 연관 부분 없음
        for (uint32_t i = 0; i < node.count; i++)
        {
            if (!writeNode(arena, arena.children[node.first + i], depth + 1))
                return false;
        }
        return true;
    case AMF_BYTEARRAY:
        out.insert(out.end(), node.bytes, node.bytes + node.count);
        return true;
    default:
        out.push_back(node.fixed);
        out.insert(out.end(), node.bytes, node.bytes + (size_t)node.count * ((node.type == AMF_VECTOR_DOUBLE) ? 8 : 4));
        return true;
    }
}
