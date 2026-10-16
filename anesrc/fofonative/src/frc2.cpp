// ReplayDataCodec(FRC2) 네이티브 구현, AS3 코드(src/Modules/ReplayDataCodec.as)를 한 줄씩 옮김
// AS3 의미를 그대로 따름: int 변수 대입은 ToInt32(32비트 래핑), int끼리 더하기는 Number(double), Math.round는 floor(x + 0.5)
#include "common.h"
#include "frc2.h"
#include "amf3.h"
#include "fileio.h"
#include <math.h>
#include <unordered_map>

extern "C"
{
#include "LzmaEnc.h"
#include "LzmaDec.h"
}

namespace
{
    const uint8_t VERSION = 1;
    const uint8_t SEGMENT_VERSION = 2; // 세그먼트 형식 (조각마다 VERSION 1 블록)
    const uint32_t SEGMENT_MINIMUM_DICT_SIZE = 1u << 16; // 조각 본문은 보통 수십 KB라 64KB에서 시작
    const int STREAM_COUNT = 8;
    const double MAX_SCALED = 268435455; // 2^28 - 1
    const int MAX_NAMES = 250;
    const int MAX_FIELDS = 255;

    const uint8_t OP_RUN_CENTI = 0;
    const uint8_t OP_LINE_TO_RAW = 1;
    const uint8_t OP_NEW_NAME = 2;
    const uint8_t OP_RUN_PIXEL = 3;
    const uint8_t OP_NAME_BASE = 4;

    const uint8_t T_SAME = 0;
    const uint8_t T_NULL = 1;
    const uint8_t T_UNDEFINED = 2;
    const uint8_t T_TRUE = 3;
    const uint8_t T_FALSE = 4;
    const uint8_t T_INT = 5;
    const uint8_t T_CENTI = 6;
    const uint8_t T_DOUBLE = 7;
    const uint8_t T_STRING = 8;
    const uint8_t T_NEW_STRING = 9;
    const uint8_t T_AMF = 10;
    const uint8_t T_PEN = 11;

    enum
    {
        S_OPS,
        S_COUNT,
        S_XY,
        S_TAG,
        S_VALUE,
        S_DOUBLE,
        S_OBJECT,
        S_RUN
    };

    struct Fail
    {
        int code;
        const char* message;
    };

    // ---- AS3 숫자 의미 ----
    double asRound(double x)
    {
        if (isnan(x) || isinf(x) || x == 0)
            return x;

        if (x < 0 && x >= -0.5)
            return -0.0;

        return floor(x + 0.5);
    }

    int32_t toInt32(double x)
    {
        if (isnan(x) || isinf(x))
            return 0;

        double t = trunc(x);
        t = fmod(t, 4294967296.0);

        if (t < 0)
            t += 4294967296.0;

        return (int32_t)(uint32_t)t;
    }

    bool isNumber(const AmfNode& v)
    {
        return v.type == AMF_NUMBER;
    }

    bool isCenti(const AmfNode& v)
    {
        if (v.type != AMF_NUMBER)
            return false;

        const double n = v.number;

        if (n != n || n > MAX_SCALED / 100 || n < -MAX_SCALED / 100 || (n == 0 && signbit(n)))
            return false;

        return asRound(n * 100) / 100 == n;
    }

    bool isWholeInt(double n)
    {
        return n == floor(n) && n <= 1073741823 && n >= -1073741824 && !(n == 0 && signbit(n));
    }

    bool isString(const AmfNode& v, const char* text)
    {
        const size_t length = strlen(text);
        return v.type == AMF_STRING && v.count == length && memcmp(v.bytes, text, length) == 0;
    }

    bool startsWith(const AmfNode& v, const char* text)
    {
        const size_t length = strlen(text);
        return v.type == AMF_STRING && v.count >= length && memcmp(v.bytes, text, length) == 0;
    }

    bool hasPenFields(const AmfNode& name, int fieldCount)
    {
        return fieldCount >= 6 && (startsWith(name, "lineStyle") || startsWith(name, "dot") || startsWith(name, "line"));
    }

    // 다음 뭉치까지 남겨두는 직전 명령 값 (SAME 비교용), 문자열은 입력 버퍼를 가리킴
    struct Stored
    {
        AmfType type; // 객체는 AMF_ARRAY로 표시 (SAME이 될 수 없음)
        double number;
        const uint8_t* text;
        uint32_t length;
    };

    Stored store(const AmfNode& v)
    {
        Stored s;
        s.type = v.type;
        s.number = (v.type == AMF_NUMBER) ? v.number : 0;
        s.text = (v.type == AMF_STRING) ? v.bytes : NULL;
        s.length = (v.type == AMF_STRING) ? v.count : 0;

        if (v.type != AMF_UNDEFINED && v.type != AMF_NULL && v.type != AMF_TRUE && v.type != AMF_FALSE
            && v.type != AMF_NUMBER && v.type != AMF_STRING)
            s.type = AMF_ARRAY;

        return s;
    }

    // AS3 isSameValue(a, b): a !== b면 false, 숫자는 -0과 0 구분, 객체는 false
    bool isSameValue(const AmfNode& a, const Stored& b)
    {
        switch (a.type)
        {
        case AMF_NUMBER:
            if (b.type != AMF_NUMBER || !(a.number == b.number))
                return false;
            return a.number != 0 || signbit(a.number) == signbit(b.number);
        case AMF_STRING:
            return b.type == AMF_STRING && a.count == b.length && memcmp(a.bytes, b.text, a.count) == 0;
        case AMF_NULL:
        case AMF_UNDEFINED:
        case AMF_TRUE:
        case AMF_FALSE:
            return a.type == b.type;
        default:
            return false;
        }
    }

    struct StringKey
    {
        const uint8_t* text;
        uint32_t length;
        bool operator==(const StringKey& other) const
        {
            return length == other.length && memcmp(text, other.text, length) == 0;
        }
    };

    struct StringKeyHash
    {
        size_t operator()(const StringKey& key) const
        {
            uint32_t h = 2166136261u;

            for (uint32_t i = 0; i < key.length; i++)
                h = (h ^ key.text[i]) * 16777619u;

            return h;
        }
    };

    // ---- 바이트 쓰기/읽기 (AS3 ByteArray 기본 빅엔디언) ----
    void writeByte(Bytes& out, uint32_t value)
    {
        out.push_back((uint8_t)value);
    }

    void writeU32(Bytes& out, uint32_t value)
    {
        out.push_back((uint8_t)(value >> 24));
        out.push_back((uint8_t)(value >> 16));
        out.push_back((uint8_t)(value >> 8));
        out.push_back((uint8_t)value);
    }

    void writeDouble(Bytes& out, double value)
    {
        uint64_t bits;
        memcpy(&bits, &value, 8);

        for (int i = 7; i >= 0; i--)
            out.push_back((uint8_t)(bits >> (i * 8)));
    }

    void writeUTF(Bytes& out, const uint8_t* text, uint32_t length)
    {
        if (length > 65535)
            throw Fail{ FRC2_UNSUPPORTED, "string too long for writeUTF" };

        out.push_back((uint8_t)(length >> 8));
        out.push_back((uint8_t)length);
        out.insert(out.end(), text, text + length);
    }

    void writeUnsigned(Bytes& out, uint32_t value)
    {
        while (value >= 128)
        {
            out.push_back((uint8_t)((value & 127) | 128));
            value >>= 7;
        }

        out.push_back((uint8_t)value);
    }

    void writeSigned(Bytes& out, int32_t value)
    {
        writeUnsigned(out, ((uint32_t)value << 1) ^ (uint32_t)(value >> 31));
    }

    struct Reader
    {
        const uint8_t* data;
        size_t length;
        size_t position;

        size_t available() const { return length - position; }

        uint8_t readByte()
        {
            if (position >= length)
                throw Fail{ FRC2_CORRUPT, "end of stream" };

            return data[position++];
        }

        uint32_t readU32()
        {
            if (available() < 4)
                throw Fail{ FRC2_CORRUPT, "end of stream" };

            const uint8_t* p = data + position;
            position += 4;
            return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) | ((uint32_t)p[2] << 8) | p[3];
        }

        double readDouble()
        {
            if (available() < 8)
                throw Fail{ FRC2_CORRUPT, "end of stream" };

            uint64_t bits = 0;

            for (int i = 0; i < 8; i++)
                bits = (bits << 8) | data[position + i];

            position += 8;
            double value;
            memcpy(&value, &bits, 8);
            return value;
        }

        void readUTF(const uint8_t** text, uint32_t* textLength)
        {
            if (available() < 2)
                throw Fail{ FRC2_CORRUPT, "end of stream" };

            const uint32_t n = ((uint32_t)data[position] << 8) | data[position + 1];
            position += 2;

            if (available() < n)
                throw Fail{ FRC2_CORRUPT, "end of stream" };

            *text = data + position;
            *textLength = n;

            if (!isValidUtf8(*text, n))
                throw Fail{ FRC2_UNSUPPORTED, "invalid utf-8" };

            position += n;
        }

        uint32_t readUnsigned()
        {
            uint32_t result = 0;

            for (int shift = 0; shift < 35; shift += 7)
            {
                const uint32_t part = readByte();
                result |= (part & 127) << shift;

                if ((part & 128) == 0)
                    return result;
            }

            throw Fail{ FRC2_CORRUPT, "Replay codec integer is too long" };
        }

        int32_t readSigned()
        {
            const uint32_t bits = readUnsigned();
            return (int32_t)((bits >> 1) ^ (uint32_t)(-(int32_t)(bits & 1)));
        }
    };

    ISzAlloc gAlloc = { [](ISzAllocPtr, size_t size) -> void* { return malloc(size); }, [](ISzAllocPtr, void* address) { free(address); } };

    void encodeBody(const uint8_t* input, size_t length, Bytes& body)
    {
        Bytes streams[STREAM_COUNT];
        Bytes& ops = streams[S_OPS];
        Bytes& counts = streams[S_COUNT];
        Bytes& xy = streams[S_XY];
        Bytes& tags = streams[S_TAG];
        Bytes& values = streams[S_VALUE];
        Bytes& doubles = streams[S_DOUBLE];
        Bytes& objects = streams[S_OBJECT];
        Bytes& runs = streams[S_RUN];

        std::unordered_map<StringKey, int, StringKeyHash> nameIds;
        int nameCount = 0;
        std::vector<std::vector<Stored>> previousById;
        std::unordered_map<StringKey, uint32_t, StringKeyHash> stringIds;
        uint32_t stringCount = 0;

        bool penValid = false;
        int32_t penX = 0;
        int32_t penY = 0;
        int32_t velocityX = 0;
        int32_t velocityY = 0;

        uint32_t groupCount = 0;
        AmfReader reader(input, length);
        AmfArena arena;

        while (reader.remaining() > 0)
        {
            arena.clear();
            uint32_t groupNode;

            if (!reader.readValue(arena, &groupNode))
                throw Fail{ FRC2_UNSUPPORTED, "unsupported or broken AMF3" };

            if (arena.nodes[groupNode].type != AMF_ARRAY)
                throw Fail{ FRC2_UNSUPPORTED, "Replay object is not an Array" };

            const AmfNode group = arena.nodes[groupNode];
            const int commandCount = (int)group.count;
            writeUnsigned(counts, (uint32_t)commandCount);

            auto child = [&](int index) -> const AmfNode& { return arena.nodes[arena.children[group.first + index]]; };
            auto field = [&](const AmfNode& command, int index) -> const AmfNode& { return arena.nodes[arena.children[command.first + index]]; };
            auto isCentiLineTo = [&](const AmfNode& v) -> bool
            {
                return v.type == AMF_ARRAY && v.count == 3 && isString(field(v, 0), "lineTo") && isCenti(field(v, 1)) && isCenti(field(v, 2));
            };

            for (int c = 0; c < commandCount; c++)
            {
                const AmfNode& command = child(c);

                if (command.type != AMF_ARRAY || command.count == 0 || field(command, 0).type != AMF_STRING)
                    throw Fail{ FRC2_UNSUPPORTED, "Invalid replay command" };

                const AmfNode& name = field(command, 0);
                const int fieldCount = (int)command.count - 1;

                if (isCentiLineTo(command))
                {
                    bool pixel = !penValid || (penX % 100 == 0 && penY % 100 == 0 && velocityX % 100 == 0 && velocityY % 100 == 0);
                    int runEnd = c;

                    while (runEnd < commandCount && isCentiLineTo(child(runEnd)))
                    {
                        if (pixel)
                            pixel = fmod(asRound(field(child(runEnd), 1).number * 100), 100) == 0 && fmod(asRound(field(child(runEnd), 2).number * 100), 100) == 0;

                        runEnd++;
                    }

                    writeByte(ops, pixel ? OP_RUN_PIXEL : OP_RUN_CENTI);
                    writeUnsigned(runs, (uint32_t)(runEnd - c));
                    const double unit = pixel ? 100 : 1;

                    for (; c < runEnd; c++)
                    {
                        const int32_t kx = toInt32(asRound(field(child(c), 1).number * 100));
                        const int32_t ky = toInt32(asRound(field(child(c), 2).number * 100));

                        if (penValid)
                        {
                            writeSigned(xy, toInt32(((double)kx - ((double)penX + (double)velocityX)) / unit));
                            writeSigned(xy, toInt32(((double)ky - ((double)penY + (double)velocityY)) / unit));
                            velocityX = toInt32((double)kx - (double)penX);
                            velocityY = toInt32((double)ky - (double)penY);
                        }
                        else
                        {
                            writeSigned(xy, toInt32((double)kx / unit));
                            writeSigned(xy, toInt32((double)ky / unit));
                            velocityX = 0;
                            velocityY = 0;
                        }

                        penX = kx;
                        penY = ky;
                        penValid = true;
                    }

                    c--;
                    continue;
                }

                if (isString(name, "lineTo") && fieldCount == 2)
                {
                    const AmfNode& x = field(command, 1);
                    const AmfNode& y = field(command, 2);

                    if (isNumber(x) && isNumber(y))
                    {
                        writeByte(ops, OP_LINE_TO_RAW);
                        writeDouble(doubles, x.number);
                        writeDouble(doubles, y.number);
                        penValid = false;
                        velocityX = 0;
                        velocityY = 0;
                        continue;
                    }
                }

                // 일반 명령
                const StringKey nameKey = { name.bytes, name.count };
                auto found = nameIds.find(nameKey);
                int id;

                if (found == nameIds.end())
                {
                    if (nameCount >= MAX_NAMES)
                        throw Fail{ FRC2_UNSUPPORTED, "Too many replay command names" };

                    id = nameCount++;
                    nameIds[nameKey] = id;
                    previousById.push_back(std::vector<Stored>());
                    writeByte(ops, OP_NEW_NAME);
                    writeUTF(objects, name.bytes, name.count);
                }
                else
                {
                    id = found->second;
                }

                writeByte(ops, OP_NAME_BASE + id);

                if (fieldCount > MAX_FIELDS)
                    throw Fail{ FRC2_UNSUPPORTED, "Too many replay command fields" };

                writeByte(tags, (uint32_t)fieldCount);
                std::vector<Stored>& previous = previousById[id];
                const bool hasPrevious = !previous.empty();
                const bool hasPen = hasPenFields(name, fieldCount);

                for (int i = 1; i <= fieldCount; i++)
                {
                    const AmfNode& v = field(command, i);

                    if (hasPrevious && i < (int)previous.size() && isSameValue(v, previous[i]))
                    {
                        writeByte(tags, T_SAME);
                    }
                    else if (hasPen && penValid && (i == 5 || i == 6) && isCenti(v)
                        && toInt32(asRound(v.number * 100)) == (i == 5 ? penX : penY))
                    {
                        writeByte(tags, T_PEN);
                    }
                    else if (v.type == AMF_NULL)
                    {
                        writeByte(tags, T_NULL);
                    }
                    else if (v.type == AMF_UNDEFINED)
                    {
                        writeByte(tags, T_UNDEFINED);
                    }
                    else if (v.type == AMF_TRUE)
                    {
                        writeByte(tags, T_TRUE);
                    }
                    else if (v.type == AMF_FALSE)
                    {
                        writeByte(tags, T_FALSE);
                    }
                    else if (v.type == AMF_NUMBER && isWholeInt(v.number))
                    {
                        writeByte(tags, T_INT);
                        writeSigned(values, toInt32(v.number));
                    }
                    else if (v.type == AMF_NUMBER && isCenti(v))
                    {
                        writeByte(tags, T_CENTI);
                        writeSigned(values, toInt32(asRound(v.number * 100)));
                    }
                    else if (v.type == AMF_NUMBER)
                    {
                        writeByte(tags, T_DOUBLE);
                        writeDouble(doubles, v.number);
                    }
                    else if (v.type == AMF_STRING)
                    {
                        const StringKey key = { v.bytes, v.count };
                        auto existing = stringIds.find(key);

                        if (existing == stringIds.end())
                        {
                            stringIds[key] = stringCount++;
                            writeByte(tags, T_NEW_STRING);
                            writeUTF(objects, v.bytes, v.count);
                        }
                        else
                        {
                            writeByte(tags, T_STRING);
                            writeUnsigned(values, existing->second);
                        }
                    }
                    else
                    {
                        writeByte(tags, T_AMF);
                        AmfWriter writer(objects);

                        if (!writer.writeValue(arena, arena.children[command.first + i]))
                            throw Fail{ FRC2_UNSUPPORTED, "AMF3 write failed" };
                    }
                }

                // previousByName[name] = command
                previous.resize(command.count);

                for (uint32_t i = 0; i < command.count; i++)
                    previous[i] = store(field(command, (int)i));

                if (hasPen && startsWith(name, "lineStyle"))
                {
                    velocityX = 0;
                    velocityY = 0;

                    if (isCenti(field(command, 5)) && isCenti(field(command, 6)))
                    {
                        penX = toInt32(asRound(field(command, 5).number * 100));
                        penY = toInt32(asRound(field(command, 6).number * 100));
                        penValid = true;
                    }
                    else
                    {
                        penValid = false;
                    }
                }
            }

            groupCount++;
        }

        size_t total = 4 + STREAM_COUNT * 4;

        for (int s = 0; s < STREAM_COUNT; s++)
            total += streams[s].size();

        body.clear();
        body.reserve(total);
        writeU32(body, groupCount);

        for (int s = 0; s < STREAM_COUNT; s++)
            writeU32(body, (uint32_t)streams[s].size());

        for (int s = 0; s < STREAM_COUNT; s++)
        {
            body.insert(body.end(), streams[s].begin(), streams[s].end());
            Bytes().swap(streams[s]);
        }
    }

    void decodeBody(const Bytes& body, Bytes& output)
    {
        Reader head = { body.data(), body.size(), 0 };
        const uint32_t groupCount = head.readU32();

        if (head.available() < STREAM_COUNT * 4)
            throw Fail{ FRC2_CORRUPT, "Invalid replay codec header" };

        uint32_t lengths[STREAM_COUNT];
        double total = 0;

        for (int s = 0; s < STREAM_COUNT; s++)
        {
            lengths[s] = head.readU32();
            total += lengths[s];
        }

        if (total != (double)head.available())
            throw Fail{ FRC2_CORRUPT, "Invalid replay codec stream length" };

        Reader streams[STREAM_COUNT];
        size_t offset = head.position;

        for (int s = 0; s < STREAM_COUNT; s++)
        {
            streams[s].data = body.data() + offset;
            streams[s].length = lengths[s];
            streams[s].position = 0;
            offset += lengths[s];
        }

        Reader& ops = streams[S_OPS];
        Reader& counts = streams[S_COUNT];
        Reader& xy = streams[S_XY];
        Reader& tags = streams[S_TAG];
        Reader& values = streams[S_VALUE];
        Reader& doubles = streams[S_DOUBLE];
        Reader& objects = streams[S_OBJECT];
        Reader& runs = streams[S_RUN];

        struct Name
        {
            const uint8_t* text;
            uint32_t length;
        };
        std::vector<Name> names;
        std::vector<std::vector<Stored>> previousById;
        std::vector<Name> strings;

        bool penValid = false;
        int32_t penX = 0;
        int32_t penY = 0;
        int32_t velocityX = 0;
        int32_t velocityY = 0;

        AmfArena arena;
        AmfReader objectReader(objects.data, objects.length);
        static const uint8_t LINE_TO[] = { 'l', 'i', 'n', 'e', 'T', 'o' };

        for (uint32_t g = 0; g < groupCount; g++)
        {
            arena.clear();
            const uint32_t commandCount = counts.readUnsigned();

            if (commandCount > ops.available() + xy.available())
                throw Fail{ FRC2_CORRUPT, "Invalid replay command count" };

            const uint32_t groupNode = arena.addArray(commandCount);

            for (uint32_t c = 0; c < commandCount; c++)
            {
                uint32_t op = ops.readByte();

                if (op == OP_RUN_CENTI || op == OP_RUN_PIXEL)
                {
                    const uint32_t runLength = runs.readUnsigned();

                    if (runLength == 0 || runLength > commandCount - c)
                        throw Fail{ FRC2_CORRUPT, "Invalid replay codec run" };

                    const double unit = (op == OP_RUN_PIXEL) ? 100 : 1;

                    for (uint32_t r = 0; r < runLength; r++)
                    {
                        int32_t kx = toInt32((double)xy.readSigned() * unit);
                        int32_t ky = toInt32((double)xy.readSigned() * unit);

                        if (penValid)
                        {
                            kx = toInt32((double)kx + ((double)penX + (double)velocityX));
                            ky = toInt32((double)ky + ((double)penY + (double)velocityY));
                            velocityX = toInt32((double)kx - (double)penX);
                            velocityY = toInt32((double)ky - (double)penY);
                        }
                        else
                        {
                            velocityX = 0;
                            velocityY = 0;
                        }

                        penX = kx;
                        penY = ky;
                        penValid = true;
                        const uint32_t command = arena.addArray(3);
                        const uint32_t first = arena.nodes[command].first;
                        arena.children[first] = arena.addString(LINE_TO, 6);
                        arena.children[first + 1] = arena.addNumber((double)kx / 100);
                        arena.children[first + 2] = arena.addNumber((double)ky / 100);
                        arena.children[arena.nodes[groupNode].first + c] = command;
                        c++;
                    }

                    c--;
                    continue;
                }

                if (op == OP_LINE_TO_RAW)
                {
                    const uint32_t command = arena.addArray(3);
                    const uint32_t first = arena.nodes[command].first;
                    arena.children[first] = arena.addString(LINE_TO, 6);
                    const double x = doubles.readDouble();
                    const double y = doubles.readDouble();
                    arena.children[first + 1] = arena.addNumber(x);
                    arena.children[first + 2] = arena.addNumber(y);
                    arena.children[arena.nodes[groupNode].first + c] = command;
                    penValid = false;
                    velocityX = 0;
                    velocityY = 0;
                    continue;
                }

                if (op == OP_NEW_NAME)
                {
                    Name name;
                    objects.readUTF(&name.text, &name.length);
                    names.push_back(name);
                    previousById.push_back(std::vector<Stored>());
                    op = ops.readByte();
                }

                const int id = (int)op - (int)OP_NAME_BASE;

                if (id < 0 || id >= (int)names.size())
                    throw Fail{ FRC2_CORRUPT, "Unknown replay command id" };

                const Name& name = names[id];
                const int fieldCount = tags.readByte();
                std::vector<Stored>& previous = previousById[id];
                const bool hasPrevious = !previous.empty();
                AmfNode nameNode;
                nameNode.type = AMF_STRING;
                nameNode.count = name.length;
                nameNode.bytes = name.text;
                const bool hasPen = hasPenFields(nameNode, fieldCount);
                const uint32_t command = arena.addArray((uint32_t)fieldCount + 1);
                const uint32_t first = arena.nodes[command].first;
                arena.children[first] = arena.addString(name.text, name.length);

                for (int i = 1; i <= fieldCount; i++)
                {
                    const uint8_t tag = tags.readByte();
                    uint32_t value = 0;

                    switch (tag)
                    {
                    case T_SAME:
                    {
                        if (!hasPrevious || i >= (int)previous.size())
                            throw Fail{ FRC2_CORRUPT, "Invalid replay codec reference" };

                        const Stored& p = previous[i];

                        if (p.type == AMF_NUMBER)
                            value = arena.addNumber(p.number);
                        else if (p.type == AMF_STRING)
                            value = arena.addString(p.text, p.length);
                        else if (p.type == AMF_ARRAY)
                            throw Fail{ FRC2_UNSUPPORTED, "object reference by SAME" };
                        else
                            value = arena.addSimple(p.type);
                        break;
                    }
                    case T_PEN:
                        if (!hasPen || !penValid || (i != 5 && i != 6))
                            throw Fail{ FRC2_CORRUPT, "Invalid replay codec pen reference" };

                        value = arena.addNumber((double)(i == 5 ? penX : penY) / 100);
                        break;
                    case T_NULL:
                        value = arena.addSimple(AMF_NULL);
                        break;
                    case T_UNDEFINED:
                        value = arena.addSimple(AMF_UNDEFINED);
                        break;
                    case T_TRUE:
                        value = arena.addSimple(AMF_TRUE);
                        break;
                    case T_FALSE:
                        value = arena.addSimple(AMF_FALSE);
                        break;
                    case T_INT:
                        value = arena.addNumber((double)values.readSigned());
                        break;
                    case T_CENTI:
                        value = arena.addNumber((double)values.readSigned() / 100);
                        break;
                    case T_DOUBLE:
                        value = arena.addNumber(doubles.readDouble());
                        break;
                    case T_STRING:
                    {
                        const uint32_t stringId = values.readUnsigned();

                        if (stringId >= strings.size())
                            throw Fail{ FRC2_CORRUPT, "Invalid replay codec string" };

                        value = arena.addString(strings[stringId].text, strings[stringId].length);
                        break;
                    }
                    case T_NEW_STRING:
                    {
                        Name text;
                        objects.readUTF(&text.text, &text.length);
                        strings.push_back(text);
                        value = arena.addString(text.text, text.length);
                        break;
                    }
                    case T_AMF:
                        objectReader.seek(objects.position);

                        if (!objectReader.readValue(arena, &value))
                            throw Fail{ FRC2_UNSUPPORTED, "unsupported or broken AMF3 value" };

                        objects.position = objectReader.pos();
                        break;
                    default:
                        throw Fail{ FRC2_CORRUPT, "Unknown replay codec tag" };
                    }

                    arena.children[first + i] = value;
                }

                // previousById[id] = command
                previous.resize((size_t)fieldCount + 1);

                for (int i = 0; i <= fieldCount; i++)
                    previous[i] = store(arena.nodes[arena.children[first + i]]);

                arena.children[arena.nodes[groupNode].first + c] = command;

                if (hasPen && startsWith(nameNode, "lineStyle"))
                {
                    velocityX = 0;
                    velocityY = 0;
                    const AmfNode& x = arena.nodes[arena.children[first + 5]];
                    const AmfNode& y = arena.nodes[arena.children[first + 6]];

                    if (isCenti(x) && isCenti(y))
                    {
                        penX = toInt32(asRound(x.number * 100));
                        penY = toInt32(asRound(y.number * 100));
                        penValid = true;
                    }
                    else
                    {
                        penValid = false;
                    }
                }
            }

            AmfWriter writer(output);

            if (!writer.writeValue(arena, groupNode))
                throw Fail{ FRC2_UNSUPPORTED, "AMF3 write failed" };
        }

        for (int s = 0; s < STREAM_COUNT; s++)
        {
            if (streams[s].available() != 0)
                throw Fail{ FRC2_CORRUPT, "Trailing replay codec bytes" };
        }
    }
}

bool lzmaCompressAlone(const uint8_t* input, size_t length, Bytes& out, int level, uint32_t dictSize, int threads)
{
    CLzmaEncProps props;
    LzmaEncProps_Init(&props);
    props.level = level;
    props.dictSize = dictSize;
    props.lc = 3;
    props.lp = 0;
    props.pb = 2;
    props.numThreads = threads;
    LzmaEncProps_Normalize(&props);

    try
    {
        out.resize(13 + length + length / 3 + 128);
    }
    catch (...)
    {
        return false;
    }

    SizeT destLength = out.size() - 13;
    SizeT propsSize = 5;
    const SRes result = LzmaEncode(out.data() + 13, &destLength, input, length, &props, out.data(), &propsSize, 0, NULL, &gAlloc, &gAlloc);

    if (result != SZ_OK || propsSize != 5)
        return false;

    const uint64_t size = length;

    for (int i = 0; i < 8; i++)
        out[5 + i] = (uint8_t)(size >> (i * 8));

    out.resize(13 + destLength);
    return true;
}

bool lzmaUncompressAlone(const uint8_t* input, size_t length, Bytes& out)
{
    if (length < 13)
        return false;

    uint64_t size = 0;

    for (int i = 7; i >= 0; i--)
        size = (size << 8) | input[5 + i];

    if (size == UINT64_MAX || size > ((uint64_t)1 << 32))
        return false;

    try
    {
        out.resize((size_t)size);
    }
    catch (...)
    {
        return false;
    }

    SizeT destLength = (SizeT)size;
    SizeT sourceLength = length - 13;
    ELzmaStatus status;
    const SRes result = LzmaDecode(out.data(), &destLength, input + 13, &sourceLength, input, 5, LZMA_FINISH_END, &status, &gAlloc);
    return result == SZ_OK && destLength == size;
}

static int encodeFrc2WithLzmaThreads(const uint8_t* input, size_t length, Bytes& out, std::string& error, int lzmaThreads, uint32_t minimumDictSize);
static void decodeSegmentedBlock(const uint8_t* input, size_t length, Bytes& out);
static int encodeFrc2VerifiedWithLzmaThreads(const uint8_t* input, size_t length, Bytes& out, std::string& error, int lzmaThreads, uint32_t minimumDictSize);

int frc2Encode(const uint8_t* input, size_t length, Bytes& out, std::string& error)
{
    return encodeFrc2WithLzmaThreads(input, length, out, error, 2, 1u << 20);
}

// FRC2 버전 1 인코드, lzmaThreads: LZMA 인코더 스레드 수 (조각을 여러 개 동시에 만들때는 1)
// minimumDictSize: 사전 크기 시작값 (본문보다 작으면 2배씩 늘림), 한 덩어리는 1MB, 조각은 작게 해서 동시에 도는 인코더 메모리(사전의 약 11배)를 줄임
static int encodeFrc2WithLzmaThreads(const uint8_t* input, size_t length, Bytes& out, std::string& error, int lzmaThreads, uint32_t minimumDictSize)
{
    try
    {
        Bytes body;
        encodeBody(input, length, body);
        Bytes compressed;
        // 레벨 7 + 사전을 본문 크기에 맞춤 (AIR 자체는 사전 1MB): camera_test 본문 6.9MB에서 AIR 1,055,471B 2.7초 / 네이티브 1,051,120B 2.0초
        // 인코더 메모리가 사전의 약 11배라 32비트는 4MB까지만
#if defined(_WIN64)
        const uint32_t maxDict = 16u << 20;
#else
        const uint32_t maxDict = 4u << 20;
#endif
        uint32_t dict = minimumDictSize;

        while (dict < body.size() && dict < maxDict)
            dict <<= 1;

        if (!lzmaCompressAlone(body.data(), body.size(), compressed, 7, dict, lzmaThreads))
            return FRC2_LZMA_FAILED;

        Bytes().swap(body);
        out.clear();
        out.reserve(5 + compressed.size());
        out.push_back('F');
        out.push_back('R');
        out.push_back('C');
        out.push_back('2');
        out.push_back(VERSION);
        out.insert(out.end(), compressed.begin(), compressed.end());
        return FRC2_OK;
    }
    catch (const Fail& fail)
    {
        error = fail.message;
        return fail.code;
    }
    catch (const std::bad_alloc&)
    {
        error = "out of memory";
        return FRC2_OUT_OF_MEMORY;
    }
}

int frc2Decode(const uint8_t* input, size_t length, Bytes& out, std::string& error)
{
    try
    {
        if (length < 5 || memcmp(input, "FRC2", 4) != 0)
            throw Fail{ FRC2_CORRUPT, "Invalid replay codec header" };

        if (input[4] == SEGMENT_VERSION)
        {
            decodeSegmentedBlock(input, length, out);
            return FRC2_OK;
        }

        if (input[4] != VERSION)
            throw Fail{ FRC2_CORRUPT, "Unknown replay codec version" };

        Bytes body;

        if (!lzmaUncompressAlone(input + 5, length - 5, body))
            throw Fail{ FRC2_LZMA_FAILED, "lzma uncompress failed" };

        out.clear();
        decodeBody(body, out);
        return FRC2_OK;
    }
    catch (const Fail& fail)
    {
        error = fail.message;
        out.clear();
        return fail.code;
    }
    catch (const std::bad_alloc&)
    {
        error = "out of memory";
        out.clear();
        return FRC2_OUT_OF_MEMORY;
    }
}

int frc2EncodeVerified(const uint8_t* input, size_t length, Bytes& out, std::string& error)
{
    return encodeFrc2VerifiedWithLzmaThreads(input, length, out, error, 2, 1u << 20);
}

// FRC2 버전 1로 인코드하고 디코드 결과가 원본과 바이트 단위로 같을때만 FRC2_OK
static int encodeFrc2VerifiedWithLzmaThreads(const uint8_t* input, size_t length, Bytes& out, std::string& error, int lzmaThreads, uint32_t minimumDictSize)
{
    const int encoded = encodeFrc2WithLzmaThreads(input, length, out, error, lzmaThreads, minimumDictSize);

    if (encoded != FRC2_OK)
        return encoded;

    Bytes decoded;
    const int result = frc2Decode(out.data(), out.size(), decoded, error);

    if (result != FRC2_OK)
    {
        out.clear();
        return result;
    }

    if (decoded.size() != length || (length > 0 && memcmp(decoded.data(), input, length) != 0))
    {
        error = "Replay codec verify failed";
        out.clear();
        return FRC2_VERIFY_FAILED;
    }

    return FRC2_OK;
}

// ---- 세그먼트 형식 (VERSION 2) ----

namespace
{
    uint32_t readBigEndianU32(const uint8_t* p)
    {
        return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) | ((uint32_t)p[2] << 8) | p[3];
    }

    // 리플레이를 명령 뭉치 경계에서 조각으로 나눔: segmentEnds[i]는 i번 조각이 끝나는 바이트 위치 (빈 입력이면 조각 없음)
    // segmentEndFrames[i]는 i번 조각 끝까지의 누적 프레임, inputStartFrames는 input 앞까지의 누적 프레임
    // 누적 프레임(뭉치 안 명령 수의 합)이 segmentFrames의 배수를 넘어서는 뭉치 바로 뒤에서 자름
    // isClosedSegmentOnly면 경계에서 끝나지 않은 마지막 부분은 조각으로 넣지 않음
    void splitReplayIntoSegments(const uint8_t* input, size_t length, uint64_t inputStartFrames, uint32_t segmentFrames, bool isClosedSegmentOnly,
        std::vector<size_t>& segmentEnds, std::vector<uint64_t>& segmentEndFrames)
    {
        AmfReader reader(input, length);
        AmfArena arena;
        uint64_t frames = inputStartFrames;

        while (reader.remaining() > 0)
        {
            arena.clear();
            uint32_t groupNode;

            if (!reader.readValue(arena, &groupNode))
                throw Fail{ FRC2_UNSUPPORTED, "unsupported or broken AMF3" };

            if (arena.nodes[groupNode].type != AMF_ARRAY)
                throw Fail{ FRC2_UNSUPPORTED, "Replay object is not an Array" };

            const uint64_t framesBefore = frames;
            frames += arena.nodes[groupNode].count;

            if (frames / segmentFrames != framesBefore / segmentFrames)
            {
                segmentEnds.push_back(reader.pos());
                segmentEndFrames.push_back(frames);
            }
        }

        if (!isClosedSegmentOnly && length > 0 && (segmentEnds.empty() || segmentEnds.back() != length))
        {
            segmentEnds.push_back(length);
            segmentEndFrames.push_back(frames);
        }
    }

    // 이전 .fofo의 조각 후보를 읽어서 압축 crc가 맞고 풀어본 결과가 지금 원본 조각과 같으면 true (압축 바이트를 compressedOut에)
    bool loadReusableSegmentFromOldFofo(const std::wstring& oldFofoPath, const Frc2OldSegment& oldSegment, const uint8_t* raw, size_t rawLength, Bytes& compressedOut)
    {
        Bytes compressed;

        if (!readFileRange(oldFofoPath, oldSegment.fileOffset, oldSegment.compressedLength, compressed).ok)
            return false;

        if (crc32OfBytes(compressed.data(), compressed.size()) != oldSegment.compressedCrc)
            return false;

        if (compressed.size() < 5 || memcmp(compressed.data(), "FRC2", 4) != 0 || compressed[4] != VERSION)
            return false;

        Bytes decoded;
        std::string error;

        if (frc2Decode(compressed.data(), compressed.size(), decoded, error) != FRC2_OK)
            return false;

        if (decoded.size() != rawLength || (rawLength > 0 && memcmp(decoded.data(), raw, rawLength) != 0))
            return false;

        compressedOut.swap(compressed);
        return true;
    }
}

int64_t frc2SegmentCountFromHead(const uint8_t* head, size_t length)
{
    if (length < FRC2_SEGMENT_HEAD_BYTES || memcmp(head, "FRC2", 4) != 0 || head[4] != SEGMENT_VERSION)
        return -1;

    return readBigEndianU32(head + 5);
}

bool frc2ReadSegmentTable(const uint8_t* table, uint32_t count, uint64_t blockFileOffset, uint64_t blockLength, std::vector<Frc2OldSegment>& out)
{
    uint64_t position = FRC2_SEGMENT_HEAD_BYTES + (uint64_t)count * FRC2_SEGMENT_ENTRY_BYTES;

    if (position > blockLength)
        return false;

    out.clear();
    out.reserve(count);

    for (uint32_t i = 0; i < count; i++)
    {
        const uint8_t* entry = table + (size_t)i * FRC2_SEGMENT_ENTRY_BYTES;
        Frc2OldSegment segment;
        segment.rawLength = readBigEndianU32(entry);
        segment.rawCrc = readBigEndianU32(entry + 4);
        segment.compressedLength = readBigEndianU32(entry + 8);
        segment.compressedCrc = readBigEndianU32(entry + 12);
        segment.fileOffset = blockFileOffset + position;
        position += segment.compressedLength;

        if (position > blockLength)
            return false;

        out.push_back(segment);
    }

    return true;
}

// 세그먼트 블록을 풀어서 조각 원본들을 이어 붙임, 조각들은 풀에서 동시에 풂. 깨졌으면 Fail
static void decodeSegmentedBlock(const uint8_t* input, size_t length, Bytes& out)
{
    const int64_t count = frc2SegmentCountFromHead(input, length);
    std::vector<Frc2OldSegment> table;

    if (count < 0 || !frc2ReadSegmentTable(input + FRC2_SEGMENT_HEAD_BYTES, (uint32_t)count, 0, length, table))
        throw Fail{ FRC2_CORRUPT, "Invalid replay segment table" };

    const uint64_t blockEnd = table.empty() ? FRC2_SEGMENT_HEAD_BYTES : table.back().fileOffset + table.back().compressedLength;

    if (blockEnd != length)
        throw Fail{ FRC2_CORRUPT, "Trailing replay segment bytes" };

    std::vector<Bytes> parts(table.size());
    volatile LONG failed = 0;
    int failCode = FRC2_OK;
    const char* failMessage = "";
    auto work = [&](int index)
    {
        try
        {
            const Frc2OldSegment& segment = table[index];
            const uint8_t* blob = input + segment.fileOffset;

            if (crc32OfBytes(blob, segment.compressedLength) != segment.compressedCrc)
                throw Fail{ FRC2_CORRUPT, "Replay segment crc mismatch" };

            if (segment.compressedLength < 5 || blob[4] != VERSION)
                throw Fail{ FRC2_CORRUPT, "Invalid replay segment" };

            std::string error;
            const int result = frc2Decode(blob, segment.compressedLength, parts[index], error);

            if (result != FRC2_OK)
                throw Fail{ result, "Replay segment decode failed" };

            if (parts[index].size() != segment.rawLength || crc32OfBytes(parts[index].data(), parts[index].size()) != segment.rawCrc)
                throw Fail{ FRC2_CORRUPT, "Replay segment content mismatch" };
        }
        catch (const Fail& fail)
        {
            if (InterlockedExchange(&failed, 1) == 0)
            {
                failCode = fail.code;
                failMessage = fail.message;
            }
        }
        catch (...)
        {
            if (InterlockedExchange(&failed, 1) == 0)
            {
                failCode = FRC2_OUT_OF_MEMORY;
                failMessage = "out of memory";
            }
        }
    };

    if (!table.empty())
        pool::parallelFor((int)table.size(), PRIORITY_SAVE, work);

    if (failed)
        throw Fail{ failCode, failMessage };

    size_t total = 0;

    for (size_t i = 0; i < parts.size(); i++)
        total += parts[i].size();

    out.clear();
    out.reserve(total);

    for (size_t i = 0; i < parts.size(); i++)
    {
        out.insert(out.end(), parts[i].begin(), parts[i].end());
        Bytes().swap(parts[i]);
    }
}

int frc2EncodeSegmentedVerified(const uint8_t* input, size_t length, uint32_t segmentFrames, const Frc2ReuseSource* reuse, TaskPriority priority,
    Pieces& out, Frc2SegmentStats& stats, std::string& error)
{
    std::vector<Frc2EncodedSegment> segments;
    const int result = frc2EncodeReplaySegments(input, length, 0, segmentFrames, false, reuse, priority, segments, stats, error);

    if (result != FRC2_OK)
    {
        out.clear();
        return result;
    }

    try
    {
        frc2AssembleSegmentedBlock(segments, out);
        return FRC2_OK;
    }
    catch (const std::bad_alloc&)
    {
        error = "out of memory";
        out.clear();
        return FRC2_OUT_OF_MEMORY;
    }
}

void frc2AssembleSegmentedBlock(std::vector<Frc2EncodedSegment>& segments, Pieces& out)
{
    const size_t count = segments.size();
    Bytes head;
    head.reserve(FRC2_SEGMENT_HEAD_BYTES + count * FRC2_SEGMENT_ENTRY_BYTES);
    head.push_back('F');
    head.push_back('R');
    head.push_back('C');
    head.push_back('2');
    head.push_back(SEGMENT_VERSION);
    writeU32(head, (uint32_t)count);

    for (size_t i = 0; i < count; i++)
    {
        writeU32(head, segments[i].rawLength);
        writeU32(head, segments[i].rawCrc);
        writeU32(head, (uint32_t)segments[i].compressed.size());
        writeU32(head, crc32OfBytes(segments[i].compressed.data(), segments[i].compressed.size()));
    }

    out.clear();
    out.parts.reserve(1 + count);
    out.parts.push_back(std::move(head));

    for (size_t i = 0; i < count; i++)
        out.parts.push_back(std::move(segments[i].compressed));
}

int frc2EncodeReplaySegments(const uint8_t* input, size_t length, uint64_t inputStartFrames, uint32_t segmentFrames, bool isClosedSegmentOnly,
    const Frc2ReuseSource* reuse, TaskPriority priority, std::vector<Frc2EncodedSegment>& out, Frc2SegmentStats& stats, std::string& error)
{
    stats = Frc2SegmentStats();

    try
    {
        if (segmentFrames == 0)
            throw Fail{ FRC2_UNSUPPORTED, "segmentFrames is 0" };

        std::vector<size_t> segmentEnds;
        std::vector<uint64_t> segmentEndFrames;
        splitReplayIntoSegments(input, length, inputStartFrames, segmentFrames, isClosedSegmentOnly, segmentEnds, segmentEndFrames);
        const int count = (int)segmentEnds.size();

        if (count > 0 && segmentEnds.back() - (count > 1 ? segmentEnds[count - 2] : 0) > 0xFFFFFFFFu)
            throw Fail{ FRC2_UNSUPPORTED, "Replay segment too large" };

        // 이전 조각을 (원본 길이, 원본 crc)로 찾음
        std::unordered_multimap<uint64_t, size_t> oldSegmentIndexByKey;

        if (reuse != NULL)
        {
            for (size_t i = 0; i < reuse->segments.size(); i++)
                oldSegmentIndexByKey.emplace(((uint64_t)reuse->segments[i].rawLength << 32) | reuse->segments[i].rawCrc, i);
        }

        std::vector<Frc2EncodedSegment> segments(count);
        volatile LONG failed = 0;
        int failCode = FRC2_OK;
        const char* failMessage = "";
        volatile LONG reusedCount = 0;
        volatile LONG rejectedCount = 0;
        volatile LONG64 reusedRawBytes = 0;
        auto work = [&](int index)
        {
            try
            {
                const size_t start = (index == 0) ? 0 : segmentEnds[index - 1];
                const uint8_t* raw = input + start;
                const size_t rawLength = segmentEnds[index] - start;

                if (rawLength > 0xFFFFFFFFu)
                    throw Fail{ FRC2_UNSUPPORTED, "Replay segment too large" };

                Frc2EncodedSegment& segment = segments[index];
                segment.rawLength = (uint32_t)rawLength;
                segment.rawCrc = crc32OfBytes(raw, rawLength);
                segment.endFrames = segmentEndFrames[index];
                const auto candidates = oldSegmentIndexByKey.equal_range(((uint64_t)rawLength << 32) | segment.rawCrc);

                for (auto it = candidates.first; it != candidates.second; ++it)
                {
                    if (loadReusableSegmentFromOldFofo(reuse->path, reuse->segments[it->second], raw, rawLength, segment.compressed))
                    {
                        InterlockedIncrement(&reusedCount);
                        InterlockedAdd64(&reusedRawBytes, (LONG64)rawLength);
                        return;
                    }

                    InterlockedIncrement(&rejectedCount);
                }

                std::string segmentError;
                const int result = encodeFrc2VerifiedWithLzmaThreads(raw, rawLength, segment.compressed, segmentError, 1, SEGMENT_MINIMUM_DICT_SIZE);

                if (result != FRC2_OK)
                    throw Fail{ result, "Replay segment encode failed" };
            }
            catch (const Fail& fail)
            {
                if (InterlockedExchange(&failed, 1) == 0)
                {
                    failCode = fail.code;
                    failMessage = fail.message;
                }
            }
            catch (...)
            {
                if (InterlockedExchange(&failed, 1) == 0)
                {
                    failCode = FRC2_OUT_OF_MEMORY;
                    failMessage = "out of memory";
                }
            }
        };

        if (count > 0)
            pool::parallelFor(count, priority, work);

        if (failed)
            throw Fail{ failCode, failMessage };

        out.swap(segments);
        stats.segmentCount = (uint32_t)count;
        stats.reusedCount = (uint32_t)reusedCount;
        stats.rejectedCount = (uint32_t)rejectedCount;
        stats.reusedRawBytes = (uint64_t)reusedRawBytes;
        return FRC2_OK;
    }
    catch (const Fail& fail)
    {
        error = fail.message;
        out.clear();
        return fail.code;
    }
    catch (const std::bad_alloc&)
    {
        error = "out of memory";
        out.clear();
        return FRC2_OUT_OF_MEMORY;
    }
}

// ---- FRE 함수 ----

// frc2Encode(input:ByteArray, output:ByteArray, verify:Boolean):int
static FREObject Frc2EncodeFre(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    bool verify = true;

    if (argc < 2 || (argc >= 3 && !getBool(argv[2], &verify)))
        return newInt(RESULT_BAD_ARGUMENT);

    FREByteArray input;

    if (FREAcquireByteArray(argv[0], &input) != FRE_OK)
        return newInt(RESULT_BYTES_ACQUIRE_FAILED);

    Bytes copy;

    try
    {
        copy.assign(input.bytes, input.bytes + input.length);
    }
    catch (...)
    {
        FREReleaseByteArray(argv[0]);
        return newInt(FRC2_OUT_OF_MEMORY);
    }

    FREReleaseByteArray(argv[0]);
    Bytes out;
    std::string error;
    const int result = verify ? frc2EncodeVerified(copy.data(), copy.size(), out, error) : frc2Encode(copy.data(), copy.size(), out, error);

    if (result != FRC2_OK)
        return newInt(result);

    return newInt(setByteArray(argv[1], out.data(), out.size()) ? RESULT_OK : RESULT_BYTES_ACQUIRE_FAILED);
}

// frc2Decode(input:ByteArray, output:ByteArray):int
static FREObject Frc2DecodeFre(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    if (argc < 2)
        return newInt(RESULT_BAD_ARGUMENT);

    FREByteArray input;

    if (FREAcquireByteArray(argv[0], &input) != FRE_OK)
        return newInt(RESULT_BYTES_ACQUIRE_FAILED);

    Bytes out;
    std::string error;
    // 입력은 디코드가 끝날때까지만 씀 (FRE 호출 안)
    const int result = frc2Decode(input.bytes, input.length, out, error);
    FREReleaseByteArray(argv[0]);

    if (result != FRC2_OK)
        return newInt(result);

    return newInt(setByteArray(argv[1], out.data(), out.size()) ? RESULT_OK : RESULT_BYTES_ACQUIRE_FAILED);
}

// lzmaCompress(input:ByteArray, output:ByteArray, level:int, dictMB:int, threads:int):int  (테스트용)
static FREObject LzmaCompressFre(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    int32_t level = 5;
    int32_t dictMB = 1;
    int32_t threads = 2;

    if (argc < 5 || !getInt(argv[2], &level) || !getInt(argv[3], &dictMB) || !getInt(argv[4], &threads))
        return newInt(RESULT_BAD_ARGUMENT);

    FREByteArray input;

    if (FREAcquireByteArray(argv[0], &input) != FRE_OK)
        return newInt(RESULT_BYTES_ACQUIRE_FAILED);

    Bytes copy(input.bytes, input.bytes + input.length);
    FREReleaseByteArray(argv[0]);
    Bytes out;

    if (!lzmaCompressAlone(copy.data(), copy.size(), out, level, (uint32_t)dictMB << 20, threads))
        return newInt(FRC2_LZMA_FAILED);

    return newInt(setByteArray(argv[1], out.data(), out.size()) ? RESULT_OK : RESULT_BYTES_ACQUIRE_FAILED);
}

// frc2EncodeSegmented(input:ByteArray, output:ByteArray, segmentFrames:int):int  (테스트용, 재사용 없이 모든 조각을 새로 만듦)
static FREObject Frc2EncodeSegmentedFre(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    int32_t segmentFrames = 0;

    if (argc < 3 || !getInt(argv[2], &segmentFrames) || segmentFrames <= 0)
        return newInt(RESULT_BAD_ARGUMENT);

    FREByteArray input;

    if (FREAcquireByteArray(argv[0], &input) != FRE_OK)
        return newInt(RESULT_BYTES_ACQUIRE_FAILED);

    Bytes copy(input.bytes, input.bytes + input.length);
    FREReleaseByteArray(argv[0]);
    Pieces out;
    Frc2SegmentStats stats;
    std::string error;
    const int result = frc2EncodeSegmentedVerified(copy.data(), copy.size(), (uint32_t)segmentFrames, NULL, PRIORITY_SAVE, out, stats, error);

    if (result != FRC2_OK)
        return newInt(result);

    const Bytes joined = out.join();
    return newInt(setByteArray(argv[1], joined.data(), joined.size()) ? RESULT_OK : RESULT_BYTES_ACQUIRE_FAILED);
}

static const NamedFunction gCodecFunctions[] = {
    { "frc2Encode", &Frc2EncodeFre },
    { "frc2Decode", &Frc2DecodeFre },
    { "lzmaCompress", &LzmaCompressFre },
    { "frc2EncodeSegmented", &Frc2EncodeSegmentedFre },
};

const NamedFunction* codecFunctions(uint32_t* count)
{
    *count = sizeof(gCodecFunctions) / sizeof(gCodecFunctions[0]);
    return gCodecFunctions;
}
