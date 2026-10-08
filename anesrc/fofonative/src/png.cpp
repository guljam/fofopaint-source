// PNG 인코더
// 픽셀 값은 copyPixelsToByteArray와 같은 straight 값(저장표)이라 AIR encode(PNGEncoderOptions)를 디코드한 결과와 같아야 함 (테스트 T3)
// 모든 픽셀이 불투명이면 RGB(색 형식 2), 아니면 RGBA(6). 행마다 다섯 필터 중 절대값 합이 가장 작은 것을 고름 (libpng 기본 휴리스틱)
#include "png.h"
#include "zlib.h"
#include <stdlib.h>

namespace
{
    const int ROWS_PER_BAND = 32;

    inline uint8_t paeth(int a, int b, int c)
    {
        const int p = a + b - c;
        const int pa = abs(p - a);
        const int pb = abs(p - b);
        const int pc = abs(p - c);

        if (pa <= pb && pa <= pc)
            return (uint8_t)a;

        return (uint8_t)((pb <= pc) ? b : c);
    }

    // raw: 이 행, prior: 윗 행(첫 행이면 NULL), out: 필터 바이트 + 필터된 행
    void filterRow(const uint8_t* raw, const uint8_t* prior, size_t rowBytes, int bpp, uint8_t* out, uint8_t* scratch)
    {
        // scratch: 4개 후보 (Sub, Up, Average, Paeth) 각각 rowBytes
        uint8_t* candidates[5] = { NULL, scratch, scratch + rowBytes, scratch + rowBytes * 2, scratch + rowBytes * 3 };
        uint64_t sums[5] = { 0, 0, 0, 0, 0 };

        for (size_t i = 0; i < rowBytes; i++)
        {
            const int x = raw[i];
            const int a = (i >= (size_t)bpp) ? raw[i - bpp] : 0;
            const int b = prior ? prior[i] : 0;
            const int c = (prior && i >= (size_t)bpp) ? prior[i - bpp] : 0;
            const uint8_t sub = (uint8_t)(x - a);
            const uint8_t up = (uint8_t)(x - b);
            const uint8_t avg = (uint8_t)(x - ((a + b) >> 1));
            const uint8_t pth = (uint8_t)(x - paeth(a, b, c));
            candidates[1][i] = sub;
            candidates[2][i] = up;
            candidates[3][i] = avg;
            candidates[4][i] = pth;
            // 부호 있는 값의 절대값 합
            sums[0] += (x < 128) ? x : 256 - x;
            sums[1] += (sub < 128) ? sub : 256 - sub;
            sums[2] += (up < 128) ? up : 256 - up;
            sums[3] += (avg < 128) ? avg : 256 - avg;
            sums[4] += (pth < 128) ? pth : 256 - pth;
        }

        int best = 0;

        for (int f = 1; f < 5; f++)
        {
            if (sums[f] < sums[best])
                best = f;
        }

        out[0] = (uint8_t)best;
        memcpy(out + 1, best == 0 ? raw : candidates[best], rowBytes);
    }

    void putUint32(uint8_t* p, uint32_t value)
    {
        p[0] = (uint8_t)(value >> 24);
        p[1] = (uint8_t)(value >> 16);
        p[2] = (uint8_t)(value >> 8);
        p[3] = (uint8_t)value;
    }

    // 길이 + 형식 + 데이터 + CRC
    Bytes makeChunk(const char* type, const uint8_t* data, size_t length)
    {
        Bytes chunk(12 + length);
        putUint32(chunk.data(), (uint32_t)length);
        memcpy(chunk.data() + 4, type, 4);

        if (length > 0)
            memcpy(chunk.data() + 8, data, length);

        const uint32_t crc = (uint32_t)crc32(crc32(0L, Z_NULL, 0), chunk.data() + 4, (uInt)(length + 4));
        putUint32(chunk.data() + 8 + length, crc);
        return chunk;
    }
}

bool encodePng(const PixelImage& image, int level, TaskPriority priority, Pieces& out)
{
    const uint32_t width = image.width;
    const uint32_t height = image.height;

    if (width == 0 || height == 0)
        return false;

    try
    {
        // 1. straight RGBA (위 행부터), 행마다 불투명 여부도 셈
        Bytes straight((size_t)width * height * 4);
        imageToStraight(image, straight.data(), priority, gPngTable);

        bool opaque = true;

        if (image.transparent)
        {
            const int bands = (int)((height + 255) / 256);
            std::vector<uint8_t> bandOpaque(bands, 1);

            auto scan = [&](int band)
            {
                const size_t start = (size_t)band * 256 * width;
                const size_t end = ((size_t)band * 256 + 256 < height) ? start + (size_t)256 * width : (size_t)height * width;
                const uint8_t* p = straight.data();

                for (size_t i = start; i < end; i++)
                {
                    if (p[i * 4] != 255)
                    {
                        bandOpaque[band] = 0;
                        return;
                    }
                }
            };

            pool::parallelFor(bands, priority, scan);

            for (int i = 0; i < bands; i++)
                opaque = opaque && bandOpaque[i] != 0;
        }

        // 2. RGB/RGBA 행으로 바꾸고 필터
        const int bpp = opaque ? 3 : 4;
        const size_t rowBytes = (size_t)width * bpp;
        Bytes filtered((rowBytes + 1) * height);
        Bytes rows;

        if (opaque)
        {
            rows.resize(rowBytes * height);
        }

        const uint8_t* rowBase = opaque ? rows.data() : NULL;
        const int bands = (int)((height + ROWS_PER_BAND - 1) / ROWS_PER_BAND);

        if (opaque)
        {
            auto pack = [&](int band)
            {
                const uint32_t start = (uint32_t)band * ROWS_PER_BAND;
                const uint32_t end = (start + ROWS_PER_BAND < height) ? start + ROWS_PER_BAND : height;

                for (uint32_t y = start; y < end; y++)
                {
                    const uint8_t* src = straight.data() + (size_t)y * width * 4;
                    uint8_t* dst = rows.data() + (size_t)y * rowBytes;

                    for (uint32_t x = 0; x < width; x++)
                    {
                        dst[0] = src[1];
                        dst[1] = src[2];
                        dst[2] = src[3];
                        dst += 3;
                        src += 4;
                    }
                }
            };

            pool::parallelFor(bands, priority, pack);
            Bytes().swap(straight);
        }
        else
        {
            // ARGB -> RGBA (제자리)
            auto swizzle = [&](int band)
            {
                const uint32_t start = (uint32_t)band * ROWS_PER_BAND;
                const uint32_t end = (start + ROWS_PER_BAND < height) ? start + ROWS_PER_BAND : height;
                uint8_t* p = straight.data() + (size_t)start * width * 4;
                uint8_t* pEnd = straight.data() + (size_t)end * width * 4;

                for (; p < pEnd; p += 4)
                {
                    const uint8_t a = p[0];
                    p[0] = p[1];
                    p[1] = p[2];
                    p[2] = p[3];
                    p[3] = a;
                }
            };

            pool::parallelFor(bands, priority, swizzle);
            rowBase = straight.data();
        }

        auto filterBand = [&](int band)
        {
            const uint32_t start = (uint32_t)band * ROWS_PER_BAND;
            const uint32_t end = (start + ROWS_PER_BAND < height) ? start + ROWS_PER_BAND : height;
            Bytes scratch(rowBytes * 4);

            for (uint32_t y = start; y < end; y++)
            {
                const uint8_t* raw = rowBase + (size_t)y * rowBytes;
                const uint8_t* prior = (y > 0) ? raw - rowBytes : NULL;
                filterRow(raw, prior, rowBytes, bpp, filtered.data() + (size_t)y * (rowBytes + 1), scratch.data());
            }
        };

        pool::parallelFor(bands, priority, filterBand);
        Bytes().swap(straight);
        Bytes().swap(rows);

        // 3. IDAT (zlib 스트림을 조각별 IDAT로)
        Pieces body;
        uint32_t adler = 0;

        if (!deflateRawParallel(filtered.data(), filtered.size(), level, priority, body, &adler))
            return false;

        Bytes().swap(filtered);

        uint8_t header[2];
        zlibHeader(level, header);
        uint8_t trailer[4];
        putUint32(trailer, adler);
        Bytes& first = body.parts.front();
        first.insert(first.begin(), header, header + 2);
        Bytes& last = body.parts.back();
        last.insert(last.end(), trailer, trailer + 4);

        const int idatCount = (int)body.parts.size();
        std::vector<Bytes> idats(idatCount);

        auto makeIdat = [&](int index)
        {
            idats[index] = makeChunk("IDAT", body.parts[index].data(), body.parts[index].size());
            Bytes().swap(body.parts[index]);
        };

        pool::parallelFor(idatCount, priority, makeIdat);

        // 4. 시그니처 + IHDR + IDAT들 + IEND
        static const uint8_t signature[8] = { 137, 80, 78, 71, 13, 10, 26, 10 };
        uint8_t ihdr[13];
        putUint32(ihdr, width);
        putUint32(ihdr + 4, height);
        ihdr[8] = 8; // 비트 깊이
        ihdr[9] = opaque ? 2 : 6; // RGB / RGBA
        ihdr[10] = 0;
        ihdr[11] = 0;
        ihdr[12] = 0;

        out.parts.clear();
        out.parts.reserve(idatCount + 3);
        out.parts.push_back(Bytes(signature, signature + 8));
        out.parts.push_back(makeChunk("IHDR", ihdr, 13));

        for (int i = 0; i < idatCount; i++)
            out.parts.push_back(std::move(idats[i]));

        out.parts.push_back(makeChunk("IEND", NULL, 0));
        return true;
    }
    catch (...)
    {
        out.clear();
        return false;
    }
}

bool decodePngRgba(const uint8_t* data, size_t length, uint32_t* outWidth, uint32_t* outHeight, Bytes& rgba)
{
    static const uint8_t signature[8] = { 137, 80, 78, 71, 13, 10, 26, 10 };

    if (length < 8 || memcmp(data, signature, 8) != 0)
        return false;

    uint32_t width = 0;
    uint32_t height = 0;
    int bpp = 0;
    Bytes idat;
    size_t p = 8;

    try
    {
        while (p + 12 <= length)
        {
            const uint32_t n = ((uint32_t)data[p] << 24) | ((uint32_t)data[p + 1] << 16) | ((uint32_t)data[p + 2] << 8) | data[p + 3];
            const uint8_t* type = data + p + 4;
            const uint8_t* body = data + p + 8;

            if (p + 12 + (size_t)n > length)
                return false;

            if (memcmp(type, "IHDR", 4) == 0 && n >= 13)
            {
                width = ((uint32_t)body[0] << 24) | ((uint32_t)body[1] << 16) | ((uint32_t)body[2] << 8) | body[3];
                height = ((uint32_t)body[4] << 24) | ((uint32_t)body[5] << 16) | ((uint32_t)body[6] << 8) | body[7];

                if (body[8] != 8 || body[12] != 0 || (body[9] != 2 && body[9] != 6))
                    return false;

                bpp = body[9] == 6 ? 4 : 3;
            }
            else if (memcmp(type, "IDAT", 4) == 0)
            {
                idat.insert(idat.end(), body, body + n);
            }
            else if (memcmp(type, "IEND", 4) == 0)
            {
                break;
            }

            p += 12 + (size_t)n;
        }

        if (width == 0 || height == 0 || bpp == 0)
            return false;

        const size_t rowBytes = (size_t)width * bpp;
        Bytes raw;

        if (!zlibUncompress(idat.data(), idat.size(), raw, (rowBytes + 1) * height) || raw.size() != (rowBytes + 1) * height)
            return false;

        Bytes prior(rowBytes, 0);
        Bytes line(rowBytes);
        rgba.resize((size_t)width * height * 4);

        for (uint32_t y = 0; y < height; y++)
        {
            const uint8_t filter = raw[(size_t)y * (rowBytes + 1)];
            const uint8_t* src = raw.data() + (size_t)y * (rowBytes + 1) + 1;

            for (size_t i = 0; i < rowBytes; i++)
            {
                const int a = (i >= (size_t)bpp) ? line[i - bpp] : 0;
                const int b = prior[i];
                const int c = (i >= (size_t)bpp) ? prior[i - bpp] : 0;
                int value = src[i];

                switch (filter)
                {
                case 0: break;
                case 1: value += a; break;
                case 2: value += b; break;
                case 3: value += (a + b) >> 1; break;
                case 4: value += paeth(a, b, c); break;
                default: return false;
                }

                line[i] = (uint8_t)value;
            }

            uint8_t* dst = rgba.data() + (size_t)y * width * 4;

            for (uint32_t x = 0; x < width; x++)
            {
                dst[x * 4] = line[x * bpp];
                dst[x * 4 + 1] = line[x * bpp + 1];
                dst[x * 4 + 2] = line[x * bpp + 2];
                dst[x * 4 + 3] = (bpp == 4) ? line[x * bpp + 3] : 255;
            }

            prior.swap(line);
        }
    }
    catch (...)
    {
        return false;
    }

    *outWidth = width;
    *outHeight = height;
    return true;
}
