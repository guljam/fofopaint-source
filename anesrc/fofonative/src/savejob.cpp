// 네이티브 저장 파이프라인 (.png + .fofo) 과 캡처 PNG 저장
// saveStart 한 번의 동기 호출에서 BitmapData 내부 버퍼, repdata 앞부분, 바이트들을 복사하고 바로 돌아옴
// repdata를 스레드에서 읽지 않는 이유: AIR FileStream의 UPDATE/WRITE는 공유 없이 열어서(실측 #3013) 딥 언두 자르기(applyDeepUndo, 저장 잠금 밖)와 겹치면
// AIR 쪽이 예외를 내고, 먼저 잘리면 호출 시점 내용이 아니게 됨
// 스레드에서 PNG 인코드, 이미지 5개 straight 변환 + zlib, FRC2 세그먼트 인코드(검증)를 동시에 하고
// 이전 .fofo(reuseFofoPath)에 원본이 같은 리플레이 조각, 첫 이미지, 참고 이미지가 있으면 그 압축 바이트를 다시 씀 (frc2.h 세그먼트 형식 설명)
// repdata 조각 캐시(AS3 ReplaySegmentCache)의 앞부분 조각을 넘겨받으면 그 파일을 읽어(길이, 압축 crc 확인) 그대로 쓰고 repdata는 캐시 끝부터만 읽음
// .fofo를 ReplayFileCache.writeReplayFile과 같은 구조로 씀. 결과는 StatusEvent("save", 작업 번호) -> takeJobResult
// 조각 캐시 채우기(replaySegmentCacheFillStart)도 여기 있음: repdata 구간을 호출 안에서 읽고, 스레드에서 닫힌 조각만 인코드해 조각 파일로 씀 -> StatusEvent("segcache")
//
// 쓰기 실패 처리 (지시서 D5, D6)
// - 임시 파일을 대상 폴더에 만들지 못하거나 쓰는 중 실패(폴더 없음, 권한 없음, 디스크 부족, 잘못된 이름) -> 최종 실패, 재시도 없음
// - 임시 파일은 썼는데 대상 교체가 안 됨(다른 프로그램이 잡고 있음, 읽기 전용 등) -> 이미 쓴 임시 파일을 이름_new(.png/.fofo 한 쌍)로 옮김
//   이름은 _new, _new2, _new3 ... 중 png와 fofo 둘 다 없는 첫 번호, 덮어쓰지 않음
#include "common.h"
#include "pool.h"
#include "pixels.h"
#include "zstream.h"
#include "png.h"
#include "frc2.h"
#include "fileio.h"
#include "amf3.h"
#include <string>
#include <math.h>

namespace
{
    // repdata 메타 배열 원소 (AS3에서 넘어온 숫자/불리언/null)
    struct Simple
    {
        int type; // 0 숫자, 1 불리언, 2 null
        double number;
        bool flag;
    };

    double nowMs()
    {
        static LARGE_INTEGER freq = { 0 };

        if (freq.QuadPart == 0)
            QueryPerformanceFrequency(&freq);

        LARGE_INTEGER now;
        QueryPerformanceCounter(&now);
        return (double)now.QuadPart * 1000.0 / (double)freq.QuadPart;
    }

    bool readSimpleArray(FREObject array, std::vector<Simple>& out)
    {
        FREObjectType type;

        if (FREGetObjectType(array, &type) != FRE_OK)
            return false;

        if (type == FRE_TYPE_NULL)
            return true;

        uint32_t length = 0;

        if (FREGetArrayLength(array, &length) != FRE_OK)
            return false;

        for (uint32_t i = 0; i < length; i++)
        {
            FREObject element;

            if (FREGetArrayElementAt(array, i, &element) != FRE_OK || FREGetObjectType(element, &type) != FRE_OK)
                return false;

            Simple value = { 2, 0, false };

            if (type == FRE_TYPE_NUMBER)
            {
                value.type = 0;

                if (!getDouble(element, &value.number))
                    return false;
            }
            else if (type == FRE_TYPE_BOOLEAN)
            {
                value.type = 1;

                if (!getBool(element, &value.flag))
                    return false;
            }
            else if (type != FRE_TYPE_NULL)
            {
                return false;
            }

            out.push_back(value);
        }

        return true;
    }

    bool copyByteArray(FREObject object, Bytes& out)
    {
        FREObjectType type;

        if (FREGetObjectType(object, &type) != FRE_OK)
            return false;

        if (type == FRE_TYPE_NULL)
            return true;

        FREByteArray bytes;

        if (FREAcquireByteArray(object, &bytes) != FRE_OK)
            return false;

        bool ok = true;

        try
        {
            out.assign(bytes.bytes, bytes.bytes + bytes.length);
        }
        catch (...)
        {
            ok = false;
        }

        FREReleaseByteArray(object);
        return ok;
    }

    bool getUtf8(FREObject object, std::string& out)
    {
        uint32_t length = 0;
        const uint8_t* text = NULL;

        if (FREGetObjectAsUTF8(object, &length, &text) != FRE_OK)
            return false;

        out.assign((const char*)text, length);
        return true;
    }

    // ---- AS3 writeObject와 같은 AMF3 바이트 (배열 하나: 문자열 + ByteArray + 숫자/불리언) ----
    void putU29(Bytes& out, uint32_t value)
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

    void putSimple(Bytes& out, const Simple& value)
    {
        if (value.type == 1)
        {
            out.push_back(value.flag ? 0x03 : 0x02);
        }
        else if (value.type == 2)
        {
            out.push_back(0x01);
        }
        else
        {
            const double n = value.number;

            if (n >= -268435456.0 && n <= 268435455.0 && n == floor(n) && !(n == 0 && signbit(n)))
            {
                out.push_back(0x04);
                putU29(out, (uint32_t)(int32_t)n);
            }
            else
            {
                out.push_back(0x05);
                uint64_t bits;
                memcpy(&bits, &n, 8);

                for (int i = 7; i >= 0; i--)
                    out.push_back((uint8_t)(bits >> (i * 8)));
            }
        }
    }

    // [name, image..., meta..., (reuseTag)] 배열을 pieces 끝에 붙임 (이미지 조각은 옮겨 넣어서 복사하지 않음)
    // reuseTag가 비어있지 않으면 배열 끝에 문자열로 붙임 (읽는 쪽은 번호로 앞 원소만 읽으므로 끝에 붙은 원소는 무시함)
    bool appendImageArray(Pieces& out, const char* name, std::vector<Pieces*> images, const std::vector<Simple>& meta, const std::string& reuseTag)
    {
        Bytes head;
        head.push_back(0x09);
        putU29(head, (uint32_t)((1 + images.size() + meta.size() + (reuseTag.empty() ? 0 : 1)) << 1) | 1);
        head.push_back(0x01); // 연관 부분 없음
        head.push_back(0x06);
        const uint32_t nameLength = (uint32_t)strlen(name);
        putU29(head, (nameLength << 1) | 1);
        head.insert(head.end(), name, name + nameLength);

        for (size_t i = 0; i < images.size(); i++)
        {
            const uint64_t size = images[i]->size();

            if (size >= (1u << 28))
                return false; // AMF3 ByteArray 길이 한계

            head.push_back(0x0C);
            putU29(head, ((uint32_t)size << 1) | 1);
            out.parts.push_back(std::move(head));
            head = Bytes();

            for (size_t k = 0; k < images[i]->parts.size(); k++)
                out.parts.push_back(std::move(images[i]->parts[k]));

            images[i]->parts.clear();
        }

        for (size_t i = 0; i < meta.size(); i++)
            putSimple(head, meta[i]);

        if (!reuseTag.empty())
        {
            head.push_back(0x06);
            putU29(head, ((uint32_t)reuseTag.size() << 1) | 1);
            head.insert(head.end(), reuseTag.begin(), reuseTag.end());
        }

        out.parts.push_back(std::move(head));
        return true;
    }

    // ---- 다시 저장할때 이전 .fofo의 압축 결과 재사용 ----
    // 첫 이미지(1, 2)와 참고 이미지 배열 끝에 "reuse1:원본길이:원본crc:압축crc[:원본길이:원본crc:압축crc]" 문자열을 붙여 둠 (이미지마다 3개)
    // 다음 저장때 straight 바이트의 길이와 crc가 같고 이전 압축 바이트의 crc가 맞으면 다시 압축하지 않고 그 바이트를 씀
    const char* const IMAGE_REUSE_TAG_PREFIX = "reuse1:";

    // 이미지 하나의 재사용 판단 값
    struct ImageReuseKey
    {
        uint32_t rawLength = 0;
        uint32_t rawCrc = 0;
        uint32_t compressedCrc = 0;
    };

    // 이전 .fofo에서 다시 쓸 수 있는 압축 이미지 하나 (OldFofoForReuse::tail 안을 가리킴)
    struct ReusableOldImage
    {
        bool valid = false;
        const uint8_t* compressed = NULL;
        uint32_t compressedLength = 0;
        ImageReuseKey key;
    };

    // 재사용 판단에 쓰는 이전 .fofo 정보: 리플레이 조각 표, 첫 이미지/참고 이미지의 압축 바이트
    struct OldFofoForReuse
    {
        Frc2ReuseSource replay;
        Bytes tail; // 리플레이 블록 뒤 전부 (미러, 이미지 배열들, 타이밍 시트)
        ReusableOldImage images[5]; // SaveJob::images와 같은 번호, 0/1 첫 이미지와 4 참고 이미지만 채움
        double readMs = 0;
    };

    std::string makeImageReuseTag(const std::vector<const ImageReuseKey*>& keys)
    {
        std::string tag = IMAGE_REUSE_TAG_PREFIX;

        for (size_t i = 0; i < keys.size(); i++)
        {
            char numbers[48];
            sprintf_s(numbers, "%s%lu:%lu:%lu", (i == 0) ? "" : ":", (unsigned long)keys[i]->rawLength, (unsigned long)keys[i]->rawCrc, (unsigned long)keys[i]->compressedCrc);
            tag += numbers;
        }

        return tag;
    }

    // "reuse1:..." 문자열을 숫자 목록으로, 형식이 아니면 빈 목록
    std::vector<uint32_t> parseImageReuseTag(const uint8_t* text, uint32_t length)
    {
        std::vector<uint32_t> values;
        const size_t prefixLength = strlen(IMAGE_REUSE_TAG_PREFIX);

        if (length <= prefixLength || memcmp(text, IMAGE_REUSE_TAG_PREFIX, prefixLength) != 0)
            return values;

        uint64_t value = 0;
        bool hasDigit = false;

        for (uint32_t i = (uint32_t)prefixLength; i <= length; i++)
        {
            if (i == length || text[i] == ':')
            {
                if (!hasDigit || value > 0xFFFFFFFFu)
                    return std::vector<uint32_t>();

                values.push_back((uint32_t)value);
                value = 0;
                hasDigit = false;
            }
            else if (text[i] >= '0' && text[i] <= '9' && value <= 0xFFFFFFFFu)
            {
                value = value * 10 + (text[i] - '0');
                hasDigit = true;
            }
            else
            {
                return std::vector<uint32_t>();
            }
        }

        return values;
    }

    // 이전 .fofo 뒷부분(old.tail)에서 rFirstImage, refimage 배열을 찾아 재사용 문자열이 있는 이미지를 old.images에 채움
    // 읽지 못하는 객체(지원하지 않는 AMF3 형식)를 만나면 거기서 멈춤 (이미지 배열은 타이밍 시트보다 앞에 있음)
    void findReusableImagesInOldTail(OldFofoForReuse& old)
    {
        AmfReader reader(old.tail.data(), old.tail.size());
        AmfArena arena;

        while (reader.remaining() > 0)
        {
            arena.clear();
            uint32_t arrayNode;

            if (!reader.readValue(arena, &arrayNode))
                return;

            const AmfNode array = arena.nodes[arrayNode];

            if (array.type != AMF_ARRAY || array.count < 2)
                continue;

            auto child = [&](uint32_t index) -> const AmfNode& { return arena.nodes[arena.children[array.first + index]]; };
            const AmfNode& name = child(0);
            int firstSlot;

            if (name.type == AMF_STRING && name.count == 11 && memcmp(name.bytes, "rFirstImage", 11) == 0)
                firstSlot = 0;
            else if (name.type == AMF_STRING && name.count == 8 && memcmp(name.bytes, "refimage", 8) == 0)
                firstSlot = 4;
            else
                continue;

            const AmfNode& last = child(array.count - 1);

            if (last.type != AMF_STRING)
                continue;

            const std::vector<uint32_t> values = parseImageReuseTag(last.bytes, last.count);
            int imageNumber = 0;

            for (uint32_t i = 1; i < array.count; i++)
            {
                const AmfNode& element = child(i);

                if (element.type != AMF_BYTEARRAY)
                    continue;

                const size_t valueIndex = (size_t)imageNumber * 3;
                const int slot = firstSlot + imageNumber;
                imageNumber++;

                if (valueIndex + 3 > values.size() || slot > 4 || (firstSlot == 4 && imageNumber > 1))
                    break;

                ReusableOldImage& image = old.images[slot];
                image.valid = true;
                image.compressed = element.bytes;
                image.compressedLength = element.count;
                image.key.rawLength = values[valueIndex];
                image.key.rawCrc = values[valueIndex + 1];
                image.key.compressedCrc = values[valueIndex + 2];
            }
        }
    }

    // 이전 .fofo(V2FOFOPAINT/FOFOPAINT 헤더)에서 리플레이 조각 표를 읽어 replay에 넣고, 리플레이 블록 뒤 위치(tailStart)를 돌려줌
    // 파일이 없거나 형식이 아니면 false, 세그먼트 형식이 아니면 조각 표는 비워둠
    bool readOldFofoReplaySegmentTable(const std::wstring& path, Frc2ReuseSource& replay, uint64_t* tailStart, uint64_t* fileSizeOut)
    {
        uint64_t fileSize = 0;

        if (path.empty() || !fileSizeOf(path, &fileSize))
            return false;

        Bytes head;
        const uint64_t headLength = 11 + 4 + FRC2_SEGMENT_HEAD_BYTES;

        if (!readFileRange(path, 0, (fileSize < headLength) ? fileSize : headLength, head).ok)
            return false;

        size_t headerLength = 0;

        if (head.size() >= 11 && memcmp(head.data(), "V2FOFOPAINT", 11) == 0)
            headerLength = 11;
        else if (head.size() >= 9 && memcmp(head.data(), "FOFOPAINT", 9) == 0)
            headerLength = 9;
        else
            return false;

        if (head.size() < headerLength + 4)
            return false;

        const uint8_t* lengthBytes = head.data() + headerLength;
        const uint64_t blockLength = ((uint32_t)lengthBytes[0] << 24) | ((uint32_t)lengthBytes[1] << 16) | ((uint32_t)lengthBytes[2] << 8) | lengthBytes[3];
        const uint64_t blockStart = headerLength + 4;

        if (blockStart + blockLength > fileSize)
            return false;

        const int64_t segmentCount = (head.size() > blockStart) ? frc2SegmentCountFromHead(head.data() + blockStart, (size_t)(head.size() - blockStart)) : -1;

        if (segmentCount >= 0 && FRC2_SEGMENT_HEAD_BYTES + (uint64_t)segmentCount * FRC2_SEGMENT_ENTRY_BYTES <= blockLength)
        {
            Bytes table;

            if (readFileRange(path, blockStart + FRC2_SEGMENT_HEAD_BYTES, (uint64_t)segmentCount * FRC2_SEGMENT_ENTRY_BYTES, table).ok
                && frc2ReadSegmentTable(table.data(), (uint32_t)segmentCount, blockStart, blockLength, replay.segments))
                replay.path = path;
            else
                replay.segments.clear();
        }

        *tailStart = blockStart + blockLength;
        *fileSizeOut = fileSize;
        return true;
    }

    // 이전 .fofo에서 리플레이 조각 표와 뒷부분(첫 이미지/참고 이미지 재사용)을 읽음. 파일이 없거나 형식이 아니면 비워둠 (그러면 모두 새로 압축)
    // 리플레이 조각의 압축 바이트는 여기서 읽지 않고, 원본이 같은 조각만 인코드 중에 그 위치에서 읽음
    void readOldFofoForReuse(const std::wstring& path, OldFofoForReuse& old)
    {
        const double start = nowMs();
        uint64_t tailStart = 0;
        uint64_t fileSize = 0;

        if (!readOldFofoReplaySegmentTable(path, old.replay, &tailStart, &fileSize))
            return;

        if (tailStart < fileSize && readFileRange(path, tailStart, fileSize - tailStart, old.tail).ok)
            findReusableImagesInOldTail(old);

        old.readMs = nowMs() - start;
    }

    // repdata 조각 캐시 파일들을 순서대로 읽어 압축 길이, 압축 crc, FRC2 버전 1 머리가 맞는 앞부분만 out에 넣음 (처음 틀린 조각에서 멈춤)
    // pathArray: 캐시 파일 경로들, numberArray: 조각마다 [원본 길이, 원본 crc, 압축 길이, 압축 crc, 누적 프레임], offeredCount: 넘겨받은 조각 수
    void readValidReplaySegmentCacheFiles(FREObject pathArray, FREObject numberArray, std::vector<Frc2EncodedSegment>& out, uint32_t* offeredCount)
    {
        const uint32_t NUMBERS_PER_SEGMENT = 5;
        FREObjectType type;
        uint32_t pathCount = 0;
        uint32_t numberCount = 0;
        *offeredCount = 0;

        if (FREGetObjectType(pathArray, &type) != FRE_OK || type != FRE_TYPE_ARRAY || FREGetArrayLength(pathArray, &pathCount) != FRE_OK
            || FREGetObjectType(numberArray, &type) != FRE_OK || type != FRE_TYPE_ARRAY || FREGetArrayLength(numberArray, &numberCount) != FRE_OK
            || numberCount != pathCount * NUMBERS_PER_SEGMENT)
            return;

        *offeredCount = pathCount;

        for (uint32_t i = 0; i < pathCount; i++)
        {
            FREObject element;
            std::string path;
            double numbers[NUMBERS_PER_SEGMENT];

            if (FREGetArrayElementAt(pathArray, i, &element) != FRE_OK || !getUtf8(element, path))
                return;

            for (uint32_t k = 0; k < NUMBERS_PER_SEGMENT; k++)
            {
                if (FREGetArrayElementAt(numberArray, i * NUMBERS_PER_SEGMENT + k, &element) != FRE_OK || !getDouble(element, &numbers[k]) || numbers[k] < 0)
                    return;
            }

            Frc2EncodedSegment segment;
            segment.rawLength = (uint32_t)numbers[0];
            segment.rawCrc = (uint32_t)numbers[1];
            segment.endFrames = (uint64_t)numbers[4];
            const uint64_t compressedLength = (uint64_t)numbers[2];
            const std::wstring segmentFilePath = widePath(path);
            uint64_t fileSize = 0;

            if (!fileSizeOf(segmentFilePath, &fileSize) || fileSize != compressedLength || compressedLength < 5
                || !readFilePrefix(segmentFilePath, compressedLength, segment.compressed).ok
                || memcmp(segment.compressed.data(), "FRC2", 4) != 0 || segment.compressed[4] != 1
                || crc32OfBytes(segment.compressed.data(), segment.compressed.size()) != (uint32_t)numbers[3])
                return;

            out.push_back(std::move(segment));
        }
    }

    // 결과 문자열: 줄마다 한 필드
    // status, pngPath, fofoPath, fofoSize, stage, win32Error, codec, encodeMs, writeMs, message
    std::string makeResult(const char* status, const std::wstring& png, const std::wstring& fofo, uint64_t fofoSize,
        const char* stage, DWORD error, const char* codec, double encodeMs, double writeMs, const std::string& message)
    {
        char numbers[160];
        sprintf_s(numbers, "%llu\n%s\n%lu\n%s\n%.1f\n%.1f\n", (unsigned long long)fofoSize, stage, (unsigned long)error, codec, encodeMs, writeMs);
        return std::string(status) + "\n" + utf8Path(png) + "\n" + utf8Path(fofo) + "\n" + numbers + message;
    }

    // 교체 실패 중 이름을 바꾸면 되는 것 (대상 파일 문제)
    bool isRetryableReplaceError(DWORD error)
    {
        return error == ERROR_SHARING_VIOLATION || error == ERROR_LOCK_VIOLATION || error == ERROR_ACCESS_DENIED
            || error == ERROR_USER_MAPPED_FILE || error == ERROR_WRITE_PROTECT;
    }

    std::wstring withSuffix(const std::wstring& path, const std::wstring& extension, const std::wstring& suffix)
    {
        // path는 extension으로 끝남 (".png" / ".fofo")
        if (path.size() >= extension.size() && _wcsicmp(path.c_str() + path.size() - extension.size(), extension.c_str()) == 0)
            return path.substr(0, path.size() - extension.size()) + suffix + extension;

        return path + suffix + extension;
    }

    // ---- 타이밍 시트 객체 (TimingSheetFile.makeSheetFileObject와 같은 내용) ----
    const uint32_t TIMING_SHEET_SEGMENT_FRAMES = 10000; // TimingSheet.SEGMENT_FRAMES
    const uint32_t TIMING_RECORD_BYTES = 8; // 프레임 하나 = [간격, 연출 길이] uint 둘 (빅 엔디언)

    // saveStart 때 읽어 둔 타이밍 시트 재료
    struct TimingSheetSource
    {
        double fileFrameCount = 0; // 파일 부분 프레임 수 (시트 파일에 모자라면 그 프레임은 0)
        Bytes sheetFileRecords; // 시트 파일 앞 min(파일 프레임 수, fileFrameCount)개 레코드
        Bytes pointsFile; // 점 시각 파일 (저장 시작 때 길이까지)
        Bytes memoryRecords; // 메모리 부분 [간격, 연출 길이] 쌍 (끝의 덧붙인 0 프레임 포함)
        Bytes memoryPointRecords; // 메모리 부분 점 시각 레코드 (프레임 번호는 fileFrameCount부터)
        double legacyFrameCount = 0; // 객체 끝의 옛 프레임 수
    };

    uint32_t readBigEndianU32At(const uint8_t* p)
    {
        return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) | ((uint32_t)p[2] << 8) | (uint32_t)p[3];
    }

    // 가변 길이 정수 (7비트씩, 이어지는 바이트는 최상위 비트 1), TimingSheet.writeVarLengthIntsToByteArray와 같음
    void putVarLengthUint(Bytes& out, uint32_t value)
    {
        while (value >= 128)
        {
            out.push_back((uint8_t)((value & 127) | 128));
            value >>= 7;
        }

        out.push_back((uint8_t)value);
    }

    // 프레임 하나의 [간격, 연출 길이]: 파일 부분은 시트 파일 레코드(없으면 0), 그 뒤는 메모리 부분
    void readTimingFrameRecord(const TimingSheetSource& source, uint64_t frame, uint32_t& delta, uint32_t& anim)
    {
        const uint64_t fileFrames = (uint64_t)source.fileFrameCount;
        const uint8_t* record = NULL;

        if (frame < fileFrames)
        {
            if ((frame + 1) * TIMING_RECORD_BYTES <= source.sheetFileRecords.size())
                record = source.sheetFileRecords.data() + frame * TIMING_RECORD_BYTES;
        }
        else
        {
            record = source.memoryRecords.data() + (frame - fileFrames) * TIMING_RECORD_BYTES;
        }

        delta = record ? readBigEndianU32At(record) : 0;
        anim = record ? readBigEndianU32At(record + 4) : 0;
    }

    // 점 시각 파일에서 프레임 번호 < fileFrameCount인 레코드만 옮기고 메모리 부분을 이어 붙임 (TimingSheetFile.makePointTimesBlob과 같은 규칙, 잘린 레코드에서 멈춤)
    void collectTimingPointRecords(const TimingSheetSource& source, Bytes& out)
    {
        const uint8_t* data = source.pointsFile.data();
        const uint64_t length = source.pointsFile.size();
        uint64_t position = 0;

        while (length - position >= 8)
        {
            const uint32_t frame = readBigEndianU32At(data + position);
            const uint64_t valueBytes = (uint64_t)readBigEndianU32At(data + position + 4) * 4;

            if (length - position - 8 < valueBytes)
                break;

            if ((double)frame < source.fileFrameCount)
                out.insert(out.end(), data + position, data + position + 8 + valueBytes);

            position += 8 + valueBytes;
        }

        out.insert(out.end(), source.memoryPointRecords.begin(), source.memoryPointRecords.end());
    }

    void putByteArrayHead(Bytes& out, uint64_t length)
    {
        if (length >= (1u << 28))
            throw "timing sheet too large"; // AMF3 ByteArray 길이 한계

        out.push_back(0x0C);
        putU29(out, ((uint32_t)length << 1) | 1);
    }

    // ["rTimingSheet", 2, 전체 프레임 수, 10000, [구간별 zlib blob], 점 시각 zlib blob|null, 옛 프레임 수] AMF3 바이트를 out 끝에 붙임
    // 구간 blob은 구간마다 간격들 다음 연출 길이들을 가변 길이 정수로 쓰고 zlib 압축 (구간은 풀에서 동시에)
    void appendTimingSheetObject(const TimingSheetSource& source, int level, Pieces& out)
    {
        const uint64_t totalFrames = (uint64_t)source.fileFrameCount + source.memoryRecords.size() / TIMING_RECORD_BYTES;
        const int segmentCount = (int)((totalFrames + TIMING_SHEET_SEGMENT_FRAMES - 1) / TIMING_SHEET_SEGMENT_FRAMES);
        std::vector<Pieces> blobs(segmentCount);
        Pieces pointsBlob;
        volatile LONG failed = 0;

        auto encodeSegment = [&](int index)
        {
            try
            {
                if (index == segmentCount)
                {
                    Bytes points;
                    collectTimingPointRecords(source, points);

                    if (!points.empty() && !zlibCompressParallel(points.data(), points.size(), level, PRIORITY_SAVE, pointsBlob))
                        InterlockedExchange(&failed, 1);

                    return;
                }

                const uint64_t first = (uint64_t)index * TIMING_SHEET_SEGMENT_FRAMES;
                const uint32_t count = (uint32_t)((totalFrames - first < TIMING_SHEET_SEGMENT_FRAMES) ? totalFrames - first : TIMING_SHEET_SEGMENT_FRAMES);
                std::vector<uint32_t> anims(count);
                Bytes raw;
                raw.reserve((size_t)count * 2 + 64);

                for (uint32_t i = 0; i < count; i++)
                {
                    uint32_t delta;
                    readTimingFrameRecord(source, first + i, delta, anims[i]);
                    putVarLengthUint(raw, delta);
                }

                for (uint32_t i = 0; i < count; i++)
                    putVarLengthUint(raw, anims[i]);

                if (!zlibCompressParallel(raw.data(), raw.size(), level, PRIORITY_SAVE, blobs[index]))
                    InterlockedExchange(&failed, 1);
            }
            catch (...)
            {
                InterlockedExchange(&failed, 1);
            }
        };

        pool::parallelFor(segmentCount + 1, PRIORITY_SAVE, encodeSegment);

        if (failed)
            throw "timing sheet encode failed";

        static const char NAME[] = "rTimingSheet";
        Bytes head;
        head.push_back(0x09);
        putU29(head, (7 << 1) | 1);
        head.push_back(0x01);
        head.push_back(0x06);
        putU29(head, ((uint32_t)(sizeof(NAME) - 1) << 1) | 1);
        head.insert(head.end(), NAME, NAME + sizeof(NAME) - 1);
        putSimple(head, Simple{ 0, 2, false });
        putSimple(head, Simple{ 0, (double)totalFrames, false });
        putSimple(head, Simple{ 0, (double)TIMING_SHEET_SEGMENT_FRAMES, false });
        head.push_back(0x09);
        putU29(head, ((uint32_t)segmentCount << 1) | 1);
        head.push_back(0x01);

        for (int i = 0; i < segmentCount; i++)
        {
            putByteArrayHead(head, blobs[i].size());
            out.parts.push_back(std::move(head));
            head = Bytes();

            for (size_t k = 0; k < blobs[i].parts.size(); k++)
                out.parts.push_back(std::move(blobs[i].parts[k]));
        }

        if (pointsBlob.parts.empty())
        {
            head.push_back(0x01);
        }
        else
        {
            putByteArrayHead(head, pointsBlob.size());
            out.parts.push_back(std::move(head));
            head = Bytes();

            for (size_t k = 0; k < pointsBlob.parts.size(); k++)
                out.parts.push_back(std::move(pointsBlob.parts[k]));
        }

        putSimple(head, Simple{ 0, source.legacyFrameCount, false });
        out.parts.push_back(std::move(head));
    }

    volatile LONG gActiveSaves = 0;

    class SaveJob : public Task
    {
    public:
        int32_t id = 0;
        std::wstring pngPath;
        std::wstring fofoPath;
        Bytes replay; // repdata 앞부분(조각 캐시가 있으면 캐시 뒤부터) + 메모리 뭉치
        std::vector<Frc2EncodedSegment> cachedReplaySegments; // repdata 조각 캐시에서 읽은 앞부분 조각들 (repdata 처음부터 이어짐)
        uint64_t replayStartFrames = 0; // replay 앞까지의 누적 프레임 (= 캐시 조각 마지막 endFrames)
        uint32_t offeredCacheSegmentCount = 0; // AS3가 넘긴 캐시 조각 수 (cachedReplaySegments보다 많으면 뒤는 읽기/검증 실패)
        double cacheReadMs = 0;
        PixelImage composite;
        PixelImage images[5]; // 첫 이미지 1, 2, 현재 1, 2, 참고
        bool hasReference = false;
        Bytes mirrorBytes;
        TimingSheetSource timingSheet;
        std::vector<Simple> firstMeta;
        std::vector<Simple> finalMeta;
        std::vector<Simple> referenceMeta;
        int pngLevel = 6;
        int imageLevel = 6;
        bool forceZlibReplay = false;
        bool isLegacyWholeSave = false; // 세그먼트 이전 방식 (리플레이 한 덩어리 FRC2, 이미지 재사용 없음), 비교 테스트용
        std::wstring reuseFofoPath; // 압축 결과를 다시 쓸 이전 .fofo (없으면 빈 문자열)
        uint64_t budgetBytes = 0;

        ~SaveJob() override
        {
            budget::release(budgetBytes);
            InterlockedDecrement(&gActiveSaves);
        }

        void run() override
        {
            const double start = nowMs();
            Pieces png;
            Pieces compressed[5];
            Pieces replayBlock;
            bool isFrc2 = false;
            const char* codecName = "zlib";
            Frc2SegmentStats segmentStats;
            double replayMs = 0;
            double timingSheetMs = 0;
            Pieces timingSheetObject;
            ImageReuseKey imageReuseKeys[5];
            volatile LONG reusedImageCount = 0;
            volatile LONG failed = 0;
            const char* volatile failMessage = "";
            const char* volatile failStage = "encode";
            const int partCount = (hasReference ? 7 : 6) + 1;
            const int timingSheetPartIndex = partCount - 1; // 마지막 작업 = 타이밍 시트 객체
            const size_t cachedSegmentCount = cachedReplaySegments.size();
            const uint64_t tailByteCount = replay.size();
            OldFofoForReuse old;

            if (!isLegacyWholeSave)
                readOldFofoForReuse(reuseFofoPath, old);

            auto part = [&](int index)
            {
                try
                {
                    if (index == timingSheetPartIndex)
                    {
                        const double timingStart = nowMs();
                        appendTimingSheetObject(timingSheet, imageLevel, timingSheetObject);
                        timingSheet = TimingSheetSource();
                        timingSheetMs = nowMs() - timingStart;
                    }
                    else if (index == 0)
                    {
                        if (!encodePng(composite, pngLevel, PRIORITY_SAVE, png))
                            throw "png encode failed";

                        releaseImage(composite);
                    }
                    else if (index == 1)
                    {
                        const double replayStart = nowMs();
                        std::string error;

                        // 리플레이 명령은 FRC2 세그먼트 형식으로: 앞부분은 repdata 조각 캐시의 압축 바이트를 그대로 쓰고
                        // 나머지(replay)만 조각으로 나눠 인코드 (이전 .fofo에 같은 조각이 있으면 그대로 씀)
                        // 지원하지 않는 형식이거나 검증이 다르면 기존 zlib (V1 헤더)
                        if (!forceZlibReplay && !isLegacyWholeSave)
                        {
                            std::vector<Frc2EncodedSegment> tailSegments;

                            if (frc2EncodeReplaySegments(replay.data(), replay.size(), replayStartFrames, FRC2_SEGMENT_FRAMES, false, old.replay.segments.empty() ? NULL : &old.replay,
                                PRIORITY_SAVE, tailSegments, segmentStats, error) == FRC2_OK)
                            {
                                std::vector<Frc2EncodedSegment> allSegments;
                                allSegments.reserve(cachedReplaySegments.size() + tailSegments.size());

                                for (size_t i = 0; i < cachedReplaySegments.size(); i++)
                                    allSegments.push_back(std::move(cachedReplaySegments[i]));

                                for (size_t i = 0; i < tailSegments.size(); i++)
                                    allSegments.push_back(std::move(tailSegments[i]));

                                cachedReplaySegments.clear();
                                frc2AssembleSegmentedBlock(allSegments, replayBlock);
                                isFrc2 = true;
                                codecName = "frc2seg";
                            }
                            else if (!cachedReplaySegments.empty())
                            {
                                // 앞부분을 캐시로 받아서 replay가 리플레이 전체가 아님 -> zlib로 대신 쓸 수 없음, AS3가 캐시 없이 다시 저장
                                failStage = "segment-cache";
                                throw "replay tail segment encode failed";
                            }
                        }
                        else if (!forceZlibReplay)
                        {
                            Bytes encoded;

                            if (frc2EncodeVerified(replay.data(), replay.size(), encoded, error) == FRC2_OK)
                            {
                                replayBlock.parts.push_back(std::move(encoded));
                                isFrc2 = true;
                                codecName = "frc2";
                            }
                        }

                        if (!isFrc2 && !zlibCompressParallel(replay.data(), replay.size(), imageLevel, PRIORITY_SAVE, replayBlock))
                            throw "replay zlib failed";

                        Bytes().swap(replay);
                        replayMs = nowMs() - replayStart;
                    }
                    else
                    {
                        const int slot = index - 2;
                        PixelImage& image = images[slot];
                        Bytes straight(image.byteSize());
                        imageToStraight(image, straight.data(), PRIORITY_SAVE);
                        releaseImage(image);
                        // 첫 이미지와 참고 이미지만 재사용 (현재 이미지는 거의 매번 바뀜)
                        const bool isReuseTracked = !isLegacyWholeSave && (slot == 0 || slot == 1 || slot == 4);

                        if (isReuseTracked)
                        {
                            ImageReuseKey& key = imageReuseKeys[slot];
                            key.rawLength = (uint32_t)straight.size();
                            key.rawCrc = crc32OfBytesParallel(straight.data(), straight.size(), PRIORITY_SAVE);
                            const ReusableOldImage& oldImage = old.images[slot];

                            if (oldImage.valid && oldImage.key.rawLength == key.rawLength && oldImage.key.rawCrc == key.rawCrc
                                && crc32OfBytes(oldImage.compressed, oldImage.compressedLength) == oldImage.key.compressedCrc)
                            {
                                compressed[slot].parts.push_back(Bytes(oldImage.compressed, oldImage.compressed + oldImage.compressedLength));
                                key.compressedCrc = oldImage.key.compressedCrc;
                                InterlockedIncrement(&reusedImageCount);
                                return;
                            }
                        }

                        if (!zlibCompressParallel(straight.data(), straight.size(), imageLevel, PRIORITY_SAVE, compressed[slot]))
                            throw "image zlib failed";

                        if (isReuseTracked)
                            imageReuseKeys[slot].compressedCrc = crc32OfPieces(compressed[slot]);
                    }
                }
                catch (const char* message)
                {
                    if (InterlockedExchange(&failed, 1) == 0)
                        failMessage = message;
                }
                catch (...)
                {
                    if (InterlockedExchange(&failed, 1) == 0)
                        failMessage = "out of memory";
                }
            };

            pool::parallelFor(partCount, PRIORITY_SAVE, part);
            const double encoded = nowMs();

            if (failed)
            {
                // 네이티브 내부 오류: 쓰기 실패가 아님, AS3가 이 저장을 기존 worker 경로로 처리함 ("segment-cache"면 조각 캐시 없이 다시 저장)
                jobs::finish(id, "save", makeResult("internal", pngPath, fofoPath, 0, failStage, 0, "", encoded - start, 0, failMessage));
                return;
            }

            // .fofo 조립 (ReplayFileCache.writeReplayFile과 같은 구조)
            Pieces fofo;

            try
            {
                Bytes head;
                const char* header = isFrc2 ? "V2FOFOPAINT" : "FOFOPAINT";
                head.insert(head.end(), header, header + strlen(header));
                const uint64_t blockSize = replayBlock.size();

                if (blockSize > 0xFFFFFFFFu)
                    throw "replay block too large";

                head.push_back((uint8_t)(blockSize >> 24));
                head.push_back((uint8_t)(blockSize >> 16));
                head.push_back((uint8_t)(blockSize >> 8));
                head.push_back((uint8_t)blockSize);
                fofo.parts.push_back(std::move(head));

                for (size_t i = 0; i < replayBlock.parts.size(); i++)
                    fofo.parts.push_back(std::move(replayBlock.parts[i]));

                if (!mirrorBytes.empty())
                    fofo.parts.push_back(std::move(mirrorBytes));

                const std::string firstImageReuseTag = isLegacyWholeSave ? std::string() : makeImageReuseTag({ &imageReuseKeys[0], &imageReuseKeys[1] });
                const std::string referenceImageReuseTag = isLegacyWholeSave ? std::string() : makeImageReuseTag({ &imageReuseKeys[4] });

                if (!appendImageArray(fofo, "rFirstImage", { &compressed[0], &compressed[1] }, firstMeta, firstImageReuseTag)
                    || !appendImageArray(fofo, "rFinalImage", { &compressed[2], &compressed[3] }, finalMeta, std::string())
                    || (hasReference && !appendImageArray(fofo, "refimage", { &compressed[4] }, referenceMeta, referenceImageReuseTag)))
                    throw "image too large";

                for (size_t i = 0; i < timingSheetObject.parts.size(); i++)
                    fofo.parts.push_back(std::move(timingSheetObject.parts[i]));
            }
            catch (const char* message)
            {
                jobs::finish(id, "save", makeResult("internal", pngPath, fofoPath, 0, "assemble", 0, "", encoded - start, 0, message));
                return;
            }
            catch (...)
            {
                jobs::finish(id, "save", makeResult("internal", pngPath, fofoPath, 0, "assemble", 0, "", encoded - start, 0, "out of memory"));
                return;
            }

            const uint64_t fofoSize = fofo.size();
            const char* codec = codecName;
            // 저장 결과 message 끝에 붙이는 재사용 집계 (key=value, 테스트와 로그용)
            // cachedSegments: repdata 조각 캐시에서 그대로 쓴 조각 수, offeredCacheSegments: AS3가 넘긴 수 (적으면 그 뒤 캐시 파일은 깨진 것)
            // segments/reusedSegments는 캐시 뒤에서 새로 나눈 조각만 셈
            char reuseStats[384];
            sprintf_s(reuseStats, "replayMs=%.1f segments=%lu reusedSegments=%lu rejectedSegments=%lu reusedRawBytes=%llu reusedImages=%ld oldReadMs=%.1f timingSheetMs=%.1f"
                " cachedSegments=%lu offeredCacheSegments=%lu cacheReadMs=%.1f tailBytes=%llu",
                replayMs, (unsigned long)segmentStats.segmentCount, (unsigned long)segmentStats.reusedCount, (unsigned long)segmentStats.rejectedCount,
                (unsigned long long)segmentStats.reusedRawBytes, (long)reusedImageCount, old.readMs, timingSheetMs,
                (unsigned long)cachedSegmentCount, (unsigned long)offeredCacheSegmentCount, cacheReadMs, (unsigned long long)tailByteCount);

            // 임시 파일 쓰기: 여기서 실패하면 이름을 바꿔도 소용없음 -> 최종 실패
            std::wstring pngTemp;
            std::wstring fofoTemp;
            IoResult result = writeTempFile(pngPath, { &png }, pngTemp);
            png.clear();

            if (!result.ok)
            {
                jobs::finish(id, "save", makeResult("failed", pngPath, fofoPath, 0, "write-png", result.error, codec, encoded - start, nowMs() - encoded, "temp png write failed"));
                return;
            }

            result = writeTempFile(fofoPath, { &fofo }, fofoTemp);
            fofo.clear();

            if (!result.ok)
            {
                deleteQuietly(pngTemp);
                jobs::finish(id, "save", makeResult("failed", pngPath, fofoPath, 0, "write-fofo", result.error, codec, encoded - start, nowMs() - encoded, "temp fofo write failed"));
                return;
            }

            // 교체: 둘 다 덮어쓸 수 있는지 먼저 보고, 안되면 바로 _new 쌍으로 (한쪽만 바뀐 쌍을 줄이려고)
            const IoResult pngCheck = canReplace(pngPath);
            const IoResult fofoCheck = canReplace(fofoPath);
            DWORD replaceError = 0;
            const char* replaceStage = "";
            bool needRename = false;

            if (!pngCheck.ok || !fofoCheck.ok)
            {
                needRename = true;
                replaceError = !fofoCheck.ok ? fofoCheck.error : pngCheck.error;
                replaceStage = !fofoCheck.ok ? "check-fofo" : "check-png";

                if (!isRetryableReplaceError(replaceError))
                {
                    deleteQuietly(pngTemp);
                    deleteQuietly(fofoTemp);
                    jobs::finish(id, "save", makeResult("failed", pngPath, fofoPath, 0, replaceStage, replaceError, codec, encoded - start, nowMs() - encoded, "target not writable"));
                    return;
                }
            }

            bool fofoReplaced = false;
            bool pngReplaced = false;

            if (!needRename)
            {
                result = replaceFile(fofoTemp, fofoPath);

                if (result.ok)
                {
                    fofoReplaced = true;
                    result = replaceFile(pngTemp, pngPath);

                    if (result.ok)
                    {
                        pngReplaced = true;
                    }
                    else
                    {
                        replaceStage = "move-png";
                    }
                }
                else
                {
                    replaceStage = "move-fofo";
                }

                if (!result.ok)
                {
                    replaceError = result.error;

                    if (!isRetryableReplaceError(replaceError))
                    {
                        deleteQuietly(pngTemp);
                        deleteQuietly(fofoTemp);
                        jobs::finish(id, "save", makeResult("failed", pngPath, fofoPath, 0, replaceStage, replaceError, codec, encoded - start, nowMs() - encoded, "replace failed"));
                        return;
                    }

                    needRename = true;
                }
            }

            if (!needRename)
            {
                jobs::finish(id, "save", makeResult("ok", pngPath, fofoPath, fofoSize, "", 0, codec, encoded - start, nowMs() - encoded, reuseStats));
                return;
            }

            // _new 쌍으로 저장: 이미 쓴 임시 파일을 옮기기만 함 (다시 압축하지 않음)
            // 교체에 성공한 쪽(fofo가 먼저 바뀐 경우)은 바뀐 파일을 _new로 복사해서 쌍을 맞춤
            for (int number = 1; number <= 999; number++)
            {
                wchar_t suffix[16];

                if (number == 1)
                    wcscpy_s(suffix, L"_new");
                else
                    swprintf(suffix, 16, L"_new%d", number);

                const std::wstring newPng = withSuffix(pngPath, L".png", suffix);
                const std::wstring newFofo = withSuffix(fofoPath, L".fofo", suffix);

                if (fileExists(newPng) || fileExists(newFofo))
                    continue;

                IoResult moved = fofoReplaced ? IoResult{ CopyFileW(fofoPath.c_str(), newFofo.c_str(), TRUE) != 0, GetLastError() } : moveNoReplace(fofoTemp, newFofo);

                if (!moved.ok)
                {
                    if (moved.error == ERROR_FILE_EXISTS || moved.error == ERROR_ALREADY_EXISTS)
                        continue; // 그 사이에 생김, 다음 번호

                    deleteQuietly(pngTemp);
                    deleteQuietly(fofoTemp);
                    jobs::finish(id, "save", makeResult("failed", pngPath, fofoPath, 0, "rename-fofo", moved.error, codec, encoded - start, nowMs() - encoded, "rename failed"));
                    return;
                }

                moved = pngReplaced ? IoResult{ CopyFileW(pngPath.c_str(), newPng.c_str(), TRUE) != 0, GetLastError() } : moveNoReplace(pngTemp, newPng);

                if (!moved.ok)
                {
                    // fofo는 옮겼는데 png가 실패: fofo를 되돌릴 수 없으니 실패로 알리고 둘 다 지움
                    deleteQuietly(newFofo);
                    deleteQuietly(pngTemp);
                    deleteQuietly(fofoTemp);
                    jobs::finish(id, "save", makeResult("failed", pngPath, fofoPath, 0, "rename-png", moved.error, codec, encoded - start, nowMs() - encoded, "rename failed"));
                    return;
                }

                deleteQuietly(pngTemp);
                deleteQuietly(fofoTemp);
                char message[384];
                sprintf_s(message, "%s error %lu %s", replaceStage, (unsigned long)replaceError, reuseStats);
                jobs::finish(id, "save", makeResult("renamed", newPng, newFofo, fofoSize, replaceStage, replaceError, codec, encoded - start, nowMs() - encoded, message));
                return;
            }

            deleteQuietly(pngTemp);
            deleteQuietly(fofoTemp);
            jobs::finish(id, "save", makeResult("failed", pngPath, fofoPath, 0, "rename", replaceError, codec, encoded - start, nowMs() - encoded, "no free _new name"));
        }

    private:
        static void releaseImage(PixelImage& image)
        {
            std::vector<uint32_t>().swap(image.pixels);
        }
    };

    class PngJob : public Task
    {
    public:
        int32_t id = 0;
        std::wstring path;
        PixelImage image;
        int level = 6;
        uint64_t budgetBytes = 0;

        ~PngJob() override
        {
            budget::release(budgetBytes);
            InterlockedDecrement(&gActiveSaves);
        }

        void run() override
        {
            const double start = nowMs();
            Pieces png;

            if (!encodePng(image, level, PRIORITY_SAVE, png))
            {
                jobs::finish(id, "png", makeResult("internal", path, L"", 0, "encode", 0, "", nowMs() - start, 0, "png encode failed"));
                return;
            }

            std::vector<uint32_t>().swap(image.pixels);
            const double encoded = nowMs();
            const uint64_t size = png.size();
            std::wstring temp;
            IoResult result = writeTempFile(path, { &png }, temp);

            if (result.ok)
            {
                result = replaceFile(temp, path);

                if (!result.ok)
                    deleteQuietly(temp);
            }

            jobs::finish(id, "png", makeResult(result.ok ? "ok" : "failed", path, L"", size, result.ok ? "" : "write", result.error, "", encoded - start, nowMs() - encoded, ""));
        }
    };

    // repdata 한 구간을 조각 규칙으로 나눠 닫힌 조각(경계에서 끝나는 조각)만 인코드하고 조각마다 캐시 파일로 씀 (ReplaySegmentCache 채우기)
    // 결과: StatusEvent("segcache", 작업 번호) -> takeJobResult
    //   "ok\n인코드ms\n쓰기ms\n재사용 조각 수\n조각 수\n" + 조각마다 "파일 이름 원본길이 원본crc 압축길이 압축crc 누적프레임\n"
    //   실패면 "error\n메세지"
    class ReplaySegmentCacheFillJob : public Task
    {
    public:
        int32_t id = 0;
        Bytes replay; // repdata 구간 (호출 시점 내용)
        uint64_t replayStartFrames = 0; // 구간 앞까지의 누적 프레임
        std::wstring cacheFolderPath;
        std::string segmentFileNamePrefix; // 조각 파일 이름 = 접두어 + 조각 번호
        uint32_t firstSegmentNumber = 0;
        std::wstring reuseFofoPath; // 같은 조각의 압축 결과를 가져올 .fofo (불러온 파일), 없으면 빈 문자열
        uint64_t budgetBytes = 0;

        ~ReplaySegmentCacheFillJob() override
        {
            budget::release(budgetBytes);
        }

        void run() override
        {
            const double start = nowMs();
            Frc2ReuseSource reuse;
            uint64_t tailStart = 0;
            uint64_t fileSize = 0;

            if (!reuseFofoPath.empty())
                readOldFofoReplaySegmentTable(reuseFofoPath, reuse, &tailStart, &fileSize);

            std::vector<Frc2EncodedSegment> segments;
            Frc2SegmentStats stats;
            std::string error;
            const int result = frc2EncodeReplaySegments(replay.data(), replay.size(), replayStartFrames, FRC2_SEGMENT_FRAMES, true,
                reuse.segments.empty() ? NULL : &reuse, PRIORITY_CACHE, segments, stats, error);
            Bytes().swap(replay);

            if (result != FRC2_OK)
            {
                jobs::finish(id, "segcache", "error\n" + error);
                return;
            }

            const double encoded = nowMs();
            std::string lines;

            for (size_t i = 0; i < segments.size(); i++)
            {
                char number[16];
                sprintf_s(number, "%lu", (unsigned long)(firstSegmentNumber + i));
                const std::string fileName = segmentFileNamePrefix + number;
                const std::wstring filePath = cacheFolderPath + L"\\" + widePath(fileName);
                const uint64_t compressedLength = segments[i].compressed.size();
                const uint32_t compressedCrc = crc32OfBytes(segments[i].compressed.data(), segments[i].compressed.size());
                Pieces file;
                file.parts.push_back(std::move(segments[i].compressed));
                std::wstring tempPath;
                IoResult written = writeTempFile(filePath, { &file }, tempPath);

                if (written.ok)
                {
                    written = replaceFile(tempPath, filePath);

                    if (!written.ok)
                        deleteQuietly(tempPath);
                }

                if (!written.ok)
                {
                    char message[96];
                    sprintf_s(message, "error\nsegment write failed %lu", (unsigned long)written.error);
                    jobs::finish(id, "segcache", message);
                    return;
                }

                char line[160];
                sprintf_s(line, "%s %lu %lu %llu %lu %llu\n", fileName.c_str(), (unsigned long)segments[i].rawLength, (unsigned long)segments[i].rawCrc,
                    (unsigned long long)compressedLength, (unsigned long)compressedCrc, (unsigned long long)segments[i].endFrames);
                lines += line;
            }

            char head[128];
            sprintf_s(head, "ok\n%.1f\n%.1f\n%lu\n%lu\n", encoded - start, nowMs() - encoded, (unsigned long)stats.reusedCount, (unsigned long)segments.size());
            jobs::finish(id, "segcache", head + lines);
        }
    };

    uint64_t estimate(const PixelImage& image)
    {
        // 스냅샷 + straight 변환 버퍼 + 압축 결과(대략 절반)
        return (uint64_t)image.byteSize() * 5 / 2;
    }
}

// saveStart(id, pngPath, fofoPath, composite, first1, first2, current1, current2, reference|null,
//           repdataPath, repdataLength, memoryGroups, mirrorBytes, firstMeta, finalMeta, referenceMeta|null, options, reuseFofoPath,
//           timingSheetPath, timingSheetLength, timingPointsPath, timingPointsLength, timingFileFrameCount, timingMemoryRecords, timingMemoryPointRecords, timingLegacyFrameCount,
//           [cacheSegmentPaths, cacheSegmentNumbers]):int
// cacheSegment*: repdata 조각 캐시 (ReplaySegmentCache), 처음부터 이어진 조각 파일 경로와 조각마다 [원본 길이, 원본 crc, 압축 길이, 압축 crc, 누적 프레임]
// options: 1 = repdata를 FRC2 대신 zlib으로 (테스트용), 2 = 세그먼트 이전 방식(리플레이 한 덩어리 FRC2, 이미지 재사용 없음, 비교 테스트용)
// reuseFofoPath: 압축 결과를 다시 쓸 이전 .fofo 경로, 없으면 빈 문자열
// timing*: 타이밍 시트 재료. 시트/점 시각 파일은 repdata처럼 여기서 호출 시점 길이까지 읽어 둠 (AIR가 공유 없이 열어 쓰는 파일이라 스레드에서 읽지 않음)
static FREObject SaveStart(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    if (argc < 26)
        return newInt(RESULT_BAD_ARGUMENT);

    if (!gHasSaveTable || !gHasPngTable)
        return newInt(RESULT_NO_TABLE);

    SaveJob* job = new SaveJob();
    InterlockedIncrement(&gActiveSaves);
    std::string png, fofo, repdata, reuseFofo, timingSheetPath, timingPointsPath;
    double repdataLength = 0, timingSheetLength = 0, timingPointsLength = 0;
    int32_t options = 0;
    TimingSheetSource& timing = job->timingSheet;

    if (!getInt(argv[0], &job->id) || !getUtf8(argv[1], png) || !getUtf8(argv[2], fofo) || !getUtf8(argv[9], repdata)
        || !getDouble(argv[10], &repdataLength) || repdataLength < 0 || !getInt(argv[16], &options) || !getUtf8(argv[17], reuseFofo)
        || !readSimpleArray(argv[13], job->firstMeta) || !readSimpleArray(argv[14], job->finalMeta) || !readSimpleArray(argv[15], job->referenceMeta)
        || !copyByteArray(argv[12], job->mirrorBytes)
        || !getUtf8(argv[18], timingSheetPath) || !getDouble(argv[19], &timingSheetLength) || timingSheetLength < 0
        || !getUtf8(argv[20], timingPointsPath) || !getDouble(argv[21], &timingPointsLength) || timingPointsLength < 0
        || !getDouble(argv[22], &timing.fileFrameCount) || timing.fileFrameCount < 0
        || !copyByteArray(argv[23], timing.memoryRecords) || timing.memoryRecords.size() % TIMING_RECORD_BYTES != 0
        || !copyByteArray(argv[24], timing.memoryPointRecords) || !getDouble(argv[25], &timing.legacyFrameCount))
    {
        delete job;
        return newInt(RESULT_BAD_ARGUMENT);
    }

    // 타이밍 시트 파일 앞 min(파일 프레임 수, 시트 레코드 수)개, 점 시각 파일 전체 (호출 시점 길이)
    timing.fileFrameCount = floor(timing.fileFrameCount);
    const double sheetFrames = floor(timingSheetLength / TIMING_RECORD_BYTES);
    const uint64_t sheetReadBytes = (uint64_t)((sheetFrames < timing.fileFrameCount) ? sheetFrames : timing.fileFrameCount) * TIMING_RECORD_BYTES;

    if ((sheetReadBytes > 0 && !readFilePrefix(widePath(timingSheetPath), sheetReadBytes, timing.sheetFileRecords).ok)
        || (timingPointsLength > 0 && !readFilePrefix(widePath(timingPointsPath), (uint64_t)timingPointsLength, timing.pointsFile).ok))
    {
        delete job;
        return newInt(RESULT_IO_ERROR);
    }

    job->pngPath = widePath(png);
    job->fofoPath = widePath(fofo);
    job->forceZlibReplay = (options & 1) != 0;
    job->isLegacyWholeSave = (options & 2) != 0;
    job->reuseFofoPath = reuseFofo.empty() ? std::wstring() : widePath(reuseFofo);

    // repdata 조각 캐시: 맞는 앞부분 조각만 쓰고 repdata는 그 뒤부터만 읽음 (이전 방식/zlib 시험 옵션이면 캐시를 쓰지 않음)
    const double cacheReadStart = nowMs();
    uint64_t cachedRawByteLength = 0;

    if (argc >= 28 && !job->forceZlibReplay && !job->isLegacyWholeSave)
    {
        readValidReplaySegmentCacheFiles(argv[26], argv[27], job->cachedReplaySegments, &job->offeredCacheSegmentCount);

        for (size_t i = 0; i < job->cachedReplaySegments.size(); i++)
            cachedRawByteLength += job->cachedReplaySegments[i].rawLength;

        // AS3는 저장 길이 안의 조각만 넘김, 넘으면 캐시를 쓰지 않음
        if (cachedRawByteLength > (uint64_t)repdataLength)
        {
            job->cachedReplaySegments.clear();
            cachedRawByteLength = 0;
        }

        if (!job->cachedReplaySegments.empty())
            job->replayStartFrames = job->cachedReplaySegments.back().endFrames;
    }

    job->cacheReadMs = nowMs() - cacheReadStart;

    // repdata 나머지 + 메모리 뭉치 (호출 시점 내용)
    if ((uint64_t)repdataLength > cachedRawByteLength)
    {
        const IoResult read = readFileRange(widePath(repdata), cachedRawByteLength, (uint64_t)repdataLength - cachedRawByteLength, job->replay);

        if (!read.ok)
        {
            delete job;
            return newInt(RESULT_IO_ERROR);
        }
    }

    Bytes memoryGroups;

    if (!copyByteArray(argv[11], memoryGroups))
    {
        delete job;
        return newInt(RESULT_BAD_ARGUMENT);
    }

    try
    {
        job->replay.insert(job->replay.end(), memoryGroups.begin(), memoryGroups.end());
    }
    catch (...)
    {
        delete job;
        return newInt(RESULT_OUT_OF_MEMORY);
    }

    FREObjectType referenceType;
    job->hasReference = FREGetObjectType(argv[8], &referenceType) == FRE_OK && referenceType == FRE_TYPE_BITMAPDATA;

    int snap = snapshotBitmap(argv[3], job->composite, PRIORITY_SAVE);

    for (int i = 0; i < 5 && snap == RESULT_OK; i++)
    {
        if (i == 4 && !job->hasReference)
            break;

        snap = snapshotBitmap(argv[4 + i], job->images[i], PRIORITY_SAVE);
    }

    if (snap != RESULT_OK)
    {
        delete job;
        return newInt(snap);
    }

    // 저장은 사용자가 기다리는 작업이라 상한을 넘어도 받음 (대신 캐시 작업이 기다림)
    job->budgetBytes = estimate(job->composite) + (uint64_t)job->replay.size() * 2 + timing.sheetFileRecords.size() + timing.pointsFile.size() * 2;

    for (int i = 0; i < 5; i++)
        job->budgetBytes += estimate(job->images[i]);

    budget::forceAcquire(job->budgetBytes);
    pool::submit(job, PRIORITY_SAVE);
    return newInt(RESULT_OK);
}

// pngStart(id, path, bitmap, level):int  캡처 이미지 저장
static FREObject PngStart(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    if (argc < 4)
        return newInt(RESULT_BAD_ARGUMENT);

    if (!gHasPngTable)
        return newInt(RESULT_NO_TABLE);

    PngJob* job = new PngJob();
    InterlockedIncrement(&gActiveSaves);
    std::string path;

    if (!getInt(argv[0], &job->id) || !getUtf8(argv[1], path) || !getInt(argv[3], &job->level))
    {
        delete job;
        return newInt(RESULT_BAD_ARGUMENT);
    }

    job->path = widePath(path);
    const int snap = snapshotBitmap(argv[2], job->image, PRIORITY_SAVE);

    if (snap != RESULT_OK)
    {
        delete job;
        return newInt(snap);
    }

    job->budgetBytes = estimate(job->image);
    budget::forceAcquire(job->budgetBytes);
    pool::submit(job, PRIORITY_SAVE);
    return newInt(RESULT_OK);
}

// replaySegmentCacheFillStart(id, repdataPath, startByte, endByte, startFrames, cacheFolderPath, segmentFileNamePrefix, firstSegmentNumber, reuseFofoPath):int
// repdata의 [startByte, endByte)를 호출 안에서 읽고(saveStart와 같은 이유로 스레드에서 읽지 않음) 닫힌 조각을 캐시 파일로 씀 (ReplaySegmentCacheFillJob)
static FREObject ReplaySegmentCacheFillStart(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    if (argc < 9)
        return newInt(RESULT_BAD_ARGUMENT);

    ReplaySegmentCacheFillJob* job = new ReplaySegmentCacheFillJob();
    std::string repdataPath, cacheFolderPath, reuseFofoPath;
    double startByte = 0, endByte = 0, startFrames = 0;
    int32_t firstSegmentNumber = 0;

    if (!getInt(argv[0], &job->id) || !getUtf8(argv[1], repdataPath) || !getDouble(argv[2], &startByte) || !getDouble(argv[3], &endByte)
        || !getDouble(argv[4], &startFrames) || !getUtf8(argv[5], cacheFolderPath) || !getUtf8(argv[6], job->segmentFileNamePrefix)
        || !getInt(argv[7], &firstSegmentNumber) || !getUtf8(argv[8], reuseFofoPath)
        || startByte < 0 || endByte < startByte || startFrames < 0 || firstSegmentNumber < 0)
    {
        delete job;
        return newInt(RESULT_BAD_ARGUMENT);
    }

    if (endByte > startByte && !readFileRange(widePath(repdataPath), (uint64_t)startByte, (uint64_t)(endByte - startByte), job->replay).ok)
    {
        delete job;
        return newInt(RESULT_IO_ERROR);
    }

    job->replayStartFrames = (uint64_t)startFrames;
    job->cacheFolderPath = widePath(cacheFolderPath);
    job->firstSegmentNumber = (uint32_t)firstSegmentNumber;
    job->reuseFofoPath = reuseFofoPath.empty() ? std::wstring() : widePath(reuseFofoPath);
    // 원본 + 인코드 중 버퍼 (조각 압축 결과는 원본보다 작음)
    job->budgetBytes = (uint64_t)job->replay.size() * 2;
    budget::forceAcquire(job->budgetBytes);
    pool::submit(job, PRIORITY_CACHE);
    return newInt(RESULT_OK);
}

// activeSaves():int  진행 중인 저장 작업 수
static FREObject ActiveSaves(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    return newInt((int32_t)gActiveSaves);
}

int activeSaveCount()
{
    return (int)gActiveSaves;
}

static const NamedFunction gSaveFunctions[] = {
    { "saveStart", &SaveStart },
    { "pngStart", &PngStart },
    { "activeSaves", &ActiveSaves },
    { "replaySegmentCacheFillStart", &ReplaySegmentCacheFillStart },
};

const NamedFunction* saveFunctions(uint32_t* count)
{
    *count = sizeof(gSaveFunctions) / sizeof(gSaveFunctions[0]);
    return gSaveFunctions;
}
