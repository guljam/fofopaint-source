// 병렬 zlib 압축 (pigz 방식)
#include "zstream.h"
#include "zlib.h"

namespace
{
    const size_t DICT_SIZE = 32768;
    const size_t MIN_CHUNK = 256 * 1024;
    const size_t MAX_CHUNK = 1024 * 1024;

    size_t chooseChunkSize(size_t length)
    {
        // 스레드마다 2조각 이상 돌아가게, 너무 작으면 사전 반복 비용이 커지니 256KB~1MB
        const size_t threads = (size_t)(pool::threadCount() + 1);
        size_t chunk = length / (threads * 2);

        if (chunk < MIN_CHUNK)
            chunk = MIN_CHUNK;

        if (chunk > MAX_CHUNK)
            chunk = MAX_CHUNK;

        return chunk;
    }

    // 조각 하나를 raw deflate, 마지막이 아니면 Z_SYNC_FLUSH로 바이트 경계에서 끝냄
    bool deflateChunk(const uint8_t* data, size_t length, size_t start, size_t end, bool last, int level, Bytes& out)
    {
        z_stream stream;
        memset(&stream, 0, sizeof(stream));

        if (deflateInit2(&stream, level, Z_DEFLATED, -15, 8, Z_DEFAULT_STRATEGY) != Z_OK)
            return false;

        bool ok = true;

        if (start > 0)
        {
            const size_t dictStart = (start > DICT_SIZE) ? start - DICT_SIZE : 0;
            ok = deflateSetDictionary(&stream, data + dictStart, (uInt)(start - dictStart)) == Z_OK;
        }

        try
        {
            // 끝 표시와 sync flush 여유분까지
            out.resize(deflateBound(&stream, (uLong)(end - start)) + 16);
        }
        catch (...)
        {
            ok = false;
        }

        if (ok)
        {
            stream.next_in = (Bytef*)(data + start);
            stream.avail_in = (uInt)(end - start);
            stream.next_out = out.data();
            stream.avail_out = (uInt)out.size();
            const int result = deflate(&stream, last ? Z_FINISH : Z_SYNC_FLUSH);
            ok = last ? result == Z_STREAM_END : (result == Z_OK && stream.avail_in == 0);

            if (ok)
                out.resize(out.size() - stream.avail_out);
        }

        deflateEnd(&stream);
        return ok;
    }
}

Bytes Pieces::join() const
{
    Bytes all;
    all.reserve((size_t)size());

    for (size_t i = 0; i < parts.size(); i++)
        all.insert(all.end(), parts[i].begin(), parts[i].end());

    return all;
}

void zlibHeader(int level, uint8_t header[2])
{
    // CMF 0x78 (deflate, 32KB 창), FLEVEL은 zlib deflate.c와 같은 규칙
    const int flevel = (level < 2) ? 0 : (level < 6) ? 1 : (level == 6) ? 2 : 3;
    uint32_t value = (0x78 << 8) | (flevel << 6);
    value += 31 - (value % 31);
    header[0] = (uint8_t)(value >> 8);
    header[1] = (uint8_t)value;
}

bool deflateRawParallel(const uint8_t* data, size_t length, int level, TaskPriority priority, Pieces& out, uint32_t* adler)
{
    const size_t chunk = chooseChunkSize(length);
    const int count = (length == 0) ? 1 : (int)((length + chunk - 1) / chunk);
    std::vector<Bytes> parts;
    std::vector<uint32_t> adlers;

    try
    {
        parts.resize(count);
        adlers.resize(count);
    }
    catch (...)
    {
        return false;
    }

    volatile LONG failed = 0;

    auto work = [&](int index)
    {
        if (failed)
            return;

        const size_t start = (size_t)index * chunk;
        const size_t end = (start + chunk < length) ? start + chunk : length;

        if (!deflateChunk(data, length, start, end, index == count - 1, level, parts[index]))
        {
            InterlockedExchange(&failed, 1);
            return;
        }

        adlers[index] = (uint32_t)adler32(adler32(0L, Z_NULL, 0), data + start, (uInt)(end - start));
    };

    pool::parallelFor(count, priority, work);

    if (failed)
        return false;

    uint32_t combined = (uint32_t)adler32(0L, Z_NULL, 0);

    for (int i = 0; i < count; i++)
    {
        const size_t start = (size_t)i * chunk;
        const size_t end = (start + chunk < length) ? start + chunk : length;
        combined = (uint32_t)adler32_combine(combined, adlers[i], (z_off_t)(end - start));
    }

    *adler = combined;
    out.parts.swap(parts);
    return true;
}

bool zlibCompressParallel(const uint8_t* data, size_t length, int level, TaskPriority priority, Pieces& out)
{
    Pieces body;
    uint32_t adler = 0;

    if (!deflateRawParallel(data, length, level, priority, body, &adler))
        return false;

    try
    {
        Bytes header(2);
        zlibHeader(level, header.data());
        Bytes trailer(4);
        trailer[0] = (uint8_t)(adler >> 24);
        trailer[1] = (uint8_t)(adler >> 16);
        trailer[2] = (uint8_t)(adler >> 8);
        trailer[3] = (uint8_t)adler;
        out.parts.clear();
        out.parts.reserve(body.parts.size() + 2);
        out.parts.push_back(std::move(header));

        for (size_t i = 0; i < body.parts.size(); i++)
            out.parts.push_back(std::move(body.parts[i]));

        out.parts.push_back(std::move(trailer));
    }
    catch (...)
    {
        out.clear();
        return false;
    }

    return true;
}

static bool inflateAll(const uint8_t* data, size_t length, int windowBits, Bytes& out, size_t expected)
{
    z_stream stream;
    memset(&stream, 0, sizeof(stream));

    if (inflateInit2(&stream, windowBits) != Z_OK)
        return false;

    bool ok = true;

    try
    {
        out.resize(expected > 0 ? expected : length * 4 + 1024);
        stream.next_in = (Bytef*)data;
        stream.avail_in = (uInt)length;
        size_t produced = 0;

        for (;;)
        {
            stream.next_out = out.data() + produced;
            stream.avail_out = (uInt)(out.size() - produced);
            const int result = inflate(&stream, Z_NO_FLUSH);
            produced = out.size() - stream.avail_out;

            if (result == Z_STREAM_END)
                break;

            if (result != Z_OK && result != Z_BUF_ERROR)
            {
                ok = false;
                break;
            }

            if (stream.avail_out == 0)
                out.resize(out.size() * 2);
            else if (result == Z_BUF_ERROR)
            {
                ok = false; // 입력이 중간에 끝남
                break;
            }
        }

        out.resize(produced);
    }
    catch (...)
    {
        ok = false;
    }

    inflateEnd(&stream);
    return ok;
}

bool zlibUncompress(const uint8_t* data, size_t length, Bytes& out, size_t expected)
{
    return inflateAll(data, length, 15, out, expected);
}

bool inflateRawInto(const uint8_t* data, size_t length, uint8_t* out, size_t outLength)
{
    z_stream stream;
    memset(&stream, 0, sizeof(stream));

    if (inflateInit2(&stream, -15) != Z_OK)
        return false;

    stream.next_in = (Bytef*)data;
    stream.avail_in = (uInt)length;
    stream.next_out = out;
    stream.avail_out = (uInt)outLength;
    const int result = inflate(&stream, Z_FINISH);
    const bool ok = result == Z_STREAM_END && stream.avail_out == 0;
    inflateEnd(&stream);
    return ok;
}

bool deflateRawSingle(const uint8_t* data, size_t length, int level, Bytes& out)
{
    return deflateChunk(data, length, 0, length, true, level, out);
}
