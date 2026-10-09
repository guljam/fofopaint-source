// 네이티브 저장 파이프라인 (.png + .fofo) 과 캡처 PNG 저장
// saveStart 한 번의 동기 호출에서 BitmapData 내부 버퍼, repdata 앞부분, 바이트들을 복사하고 바로 돌아옴
// repdata를 스레드에서 읽지 않는 이유: AIR FileStream의 UPDATE/WRITE는 공유 없이 열어서(실측 #3013) 딥 언두 자르기(applyDeepUndo, 저장 잠금 밖)와 겹치면
// AIR 쪽이 예외를 내고, 먼저 잘리면 호출 시점 내용이 아니게 됨
// 스레드에서 PNG 인코드, 이미지 5개 straight 변환 + zlib, FRC2 인코드(검증)를 동시에 하고
// .fofo를 ReplayFileCache.writeReplayFile과 같은 구조로 씀. 결과는 StatusEvent("save", 작업 번호) -> takeJobResult
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

    // [name, image..., meta...] 배열을 pieces 끝에 붙임 (이미지 조각은 옮겨 넣어서 복사하지 않음)
    bool appendImageArray(Pieces& out, const char* name, std::vector<Pieces*> images, const std::vector<Simple>& meta)
    {
        Bytes head;
        head.push_back(0x09);
        putU29(head, (uint32_t)((1 + images.size() + meta.size()) << 1) | 1);
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

        out.parts.push_back(std::move(head));
        return true;
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

    volatile LONG gActiveSaves = 0;

    class SaveJob : public Task
    {
    public:
        int32_t id = 0;
        std::wstring pngPath;
        std::wstring fofoPath;
        Bytes replay; // repdata 앞부분 + 메모리 뭉치
        PixelImage composite;
        PixelImage images[5]; // 첫 이미지 1, 2, 현재 1, 2, 참고
        bool hasReference = false;
        Bytes mirrorBytes;
        Bytes timingBytes;
        std::vector<Simple> firstMeta;
        std::vector<Simple> finalMeta;
        std::vector<Simple> referenceMeta;
        int pngLevel = 6;
        int imageLevel = 6;
        bool forceZlibReplay = false;
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
            volatile LONG failed = 0;
            const char* volatile failMessage = "";
            const int partCount = hasReference ? 7 : 6;

            auto part = [&](int index)
            {
                try
                {
                    if (index == 0)
                    {
                        if (!encodePng(composite, pngLevel, PRIORITY_SAVE, png))
                            throw "png encode failed";

                        releaseImage(composite);
                    }
                    else if (index == 1)
                    {
                        Bytes encoded;
                        std::string error;

                        // 리플레이 명령은 FRC2(LZMA)로, 지원하지 않는 형식이거나 검증이 다르면 기존 zlib (V1 헤더)
                        if (!forceZlibReplay && frc2EncodeVerified(replay.data(), replay.size(), encoded, error) == FRC2_OK)
                        {
                            replayBlock.parts.push_back(std::move(encoded));
                            isFrc2 = true;
                        }
                        else if (!zlibCompressParallel(replay.data(), replay.size(), imageLevel, PRIORITY_SAVE, replayBlock))
                        {
                            throw "replay zlib failed";
                        }

                        Bytes().swap(replay);
                    }
                    else
                    {
                        PixelImage& image = images[index - 2];
                        Bytes straight(image.byteSize());
                        imageToStraight(image, straight.data(), PRIORITY_SAVE);
                        releaseImage(image);

                        if (!zlibCompressParallel(straight.data(), straight.size(), imageLevel, PRIORITY_SAVE, compressed[index - 2]))
                            throw "image zlib failed";
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
                // 네이티브 내부 오류: 쓰기 실패가 아님, AS3가 이 저장을 기존 worker 경로로 처리함
                jobs::finish(id, "save", makeResult("internal", pngPath, fofoPath, 0, "encode", 0, "", encoded - start, 0, failMessage));
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

                if (!appendImageArray(fofo, "rFirstImage", { &compressed[0], &compressed[1] }, firstMeta)
                    || !appendImageArray(fofo, "rFinalImage", { &compressed[2], &compressed[3] }, finalMeta)
                    || (hasReference && !appendImageArray(fofo, "refimage", { &compressed[4] }, referenceMeta)))
                    throw "image too large";

                if (!timingBytes.empty())
                    fofo.parts.push_back(std::move(timingBytes));
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
            const char* codec = isFrc2 ? "frc2" : "zlib";

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
                jobs::finish(id, "save", makeResult("ok", pngPath, fofoPath, fofoSize, "", 0, codec, encoded - start, nowMs() - encoded, ""));
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
                char message[96];
                sprintf_s(message, "%s error %lu", replaceStage, (unsigned long)replaceError);
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

    uint64_t estimate(const PixelImage& image)
    {
        // 스냅샷 + straight 변환 버퍼 + 압축 결과(대략 절반)
        return (uint64_t)image.byteSize() * 5 / 2;
    }
}

// saveStart(id, pngPath, fofoPath, composite, first1, first2, current1, current2, reference|null,
//           repdataPath, repdataLength, memoryGroups, mirrorBytes, timingBytes, firstMeta, finalMeta, referenceMeta|null, options):int
// options: 1 = repdata를 FRC2 대신 zlib으로 (테스트용)
static FREObject SaveStart(FREContext ctx, void* functionData, uint32_t argc, FREObject argv[])
{
    if (argc < 18)
        return newInt(RESULT_BAD_ARGUMENT);

    if (!gHasSaveTable || !gHasPngTable)
        return newInt(RESULT_NO_TABLE);

    SaveJob* job = new SaveJob();
    InterlockedIncrement(&gActiveSaves);
    std::string png, fofo, repdata;
    double repdataLength = 0;
    int32_t options = 0;

    if (!getInt(argv[0], &job->id) || !getUtf8(argv[1], png) || !getUtf8(argv[2], fofo) || !getUtf8(argv[9], repdata)
        || !getDouble(argv[10], &repdataLength) || repdataLength < 0 || !getInt(argv[17], &options)
        || !readSimpleArray(argv[14], job->firstMeta) || !readSimpleArray(argv[15], job->finalMeta) || !readSimpleArray(argv[16], job->referenceMeta)
        || !copyByteArray(argv[12], job->mirrorBytes) || !copyByteArray(argv[13], job->timingBytes))
    {
        delete job;
        return newInt(RESULT_BAD_ARGUMENT);
    }

    job->pngPath = widePath(png);
    job->fofoPath = widePath(fofo);
    job->forceZlibReplay = (options & 1) != 0;

    // repdata 앞부분 + 메모리 뭉치 (호출 시점 내용)
    if (repdataLength > 0)
    {
        const IoResult read = readFilePrefix(widePath(repdata), (uint64_t)repdataLength, job->replay);

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
    job->budgetBytes = estimate(job->composite) + (uint64_t)job->replay.size() * 2;

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
};

const NamedFunction* saveFunctions(uint32_t* count)
{
    *count = sizeof(gSaveFunctions) / sizeof(gSaveFunctions[0]);
    return gSaveFunctions;
}
