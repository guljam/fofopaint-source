package Modules
{
    import avm2.intrinsics.memory.li8;
    import avm2.intrinsics.memory.si8;
    import flash.display.BitmapData;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Rectangle;
    import flash.system.ApplicationDomain;
    import flash.utils.ByteArray;
    import flash.utils.CompressionAlgorithm;
    import flash.utils.Endian;
    import Modules.L2Engine.CacheImageMetaData;

    // 캐시 이미지 파일 읽기/쓰기 (형식: CacheImageFormat)
    // 네이티브를 쓸 수 있으면 내부 버퍼 원본 덤프(손실 없음)로 쓰고 읽음, 못 쓰면 straight + PixelRestore (AS3)
    // 옛 형식([zlib 레이어1, zlib 레이어2, CacheImageMetaData] writeObject)도 읽음:
    // 앱을 업데이트한 뒤 첫 실행에서 캐시를 다시 만들려면 불러오기 경로를 타야 하는데 그 경로는 메모리 undo 뭉치를 지우므로 옛 캐시를 그대로 읽어서 씀
    // 층: L2 엔진 - 캐시 이미지 파일 읽기·쓰기
    public final class CacheImageFile
    {
        public static function isNewFormatFile(file:File):Boolean
        {
            const fs:FileStream = new FileStream();
            const head:ByteArray = new ByteArray();

            try
            {
                fs.open(file, FileMode.READ);

                if (fs.bytesAvailable >= 4)
                {
                    fs.readBytes(head, 0, 4);
                }
            }
            catch (error:Error)
            {
                return false;
            }
            finally
            {
                fs.close();
            }

            return CacheImageFormat.isNewFormat(head);
        }

        // 헤더만 읽어서 메타데이터를 돌려줌, 새 형식이 아니거나 깨졌으면 null (이어 만들기 확인용)
        public static function readNewFormatMetadata(file:File):CacheImageMetaData
        {
            const fs:FileStream = new FileStream();

            try
            {
                fs.open(file, FileMode.READ);
                fs.endian = Endian.LITTLE_ENDIAN;

                if (fs.bytesAvailable < 20 || fs.readUTFBytes(4) !== "FCI2" || fs.readUnsignedByte() !== CacheImageFormat.VERSION)
                {
                    return null;
                }

                fs.position = 16;
                const metadataLength:uint = fs.readUnsignedInt();

                if (metadataLength > fs.bytesAvailable)
                {
                    return null;
                }

                const bytes:ByteArray = new ByteArray();
                fs.readBytes(bytes, 0, metadataLength);
                return bytes.readObject() as CacheImageMetaData;
            }
            catch (error:Error)
            {
                trace("Cache image header read failed: " + error);
            }
            finally
            {
                fs.close();
            }

            return null;
        }

        // {bmpd1, bmpd2, metadata}
        public static function read(file:File):Object
        {
            const all:ByteArray = new ByteArray();
            const fs:FileStream = new FileStream();
            fs.open(file, FileMode.READ);

            if (fs.bytesAvailable >= 4)
            {
                fs.readBytes(all, 0, 4);
            }

            if (!CacheImageFormat.isNewFormat(all))
            {
                fs.position = 0;
                const data:Array = fs.readObject() as Array;
                fs.close();
                return readOldFormat(data);
            }

            fs.readBytes(all, 4, fs.bytesAvailable);
            fs.close();
            all.endian = Endian.LITTLE_ENDIAN;
            all.position = 4;
            all.readUnsignedByte(); // 형식 버전 (cacheRead와 AS3 읽기가 확인)
            const compression:int = all.readUnsignedByte();
            const pixelFormat:int = all.readUnsignedByte();
            all.readUnsignedByte(); // 레이어 수
            const width:uint = all.readUnsignedInt();
            const height:uint = all.readUnsignedInt();
            const metadataLength:uint = all.readUnsignedInt();
            const metadataBytes:ByteArray = new ByteArray();
            all.readBytes(metadataBytes, 0, metadataLength);
            const metadata:CacheImageMetaData = metadataBytes.readObject() as CacheImageMetaData;
            const layer1:BitmapData = new BitmapData(width, height, true, 0);
            const layer2:BitmapData = new BitmapData(width, height, true, 0);

            // 네이티브: 블록을 병렬로 풀어 내부 버퍼에 바로 씀
            if (NativeCore.isAvailable && PixelRestore.isNativeEnabled && NativeCore.callResult("cacheRead", file.nativePath, layer1, layer2) === NativeCore.OK)
            {
                all.clear();
                return { bmpd1: layer1, bmpd2: layer2, metadata: metadata };
            }

            // AS3 대체 경로
            const layers:Array = [layer1, layer2];

            for (var l:int = 0;l < 2;l++)
            {
                const blockCount:uint = all.readUnsignedInt();
                const sizes:Array = [];
                var i:uint;

                for (i = 0;i < blockCount;i++)
                {
                    all.readUnsignedInt(); // 행 수
                    all.readUnsignedInt(); // 원본 크기
                    sizes.push(all.readUnsignedInt());
                }

                const pixels:ByteArray = new ByteArray();

                for (i = 0;i < blockCount;i++)
                {
                    const block:ByteArray = new ByteArray();
                    all.readBytes(block, 0, sizes[i]);
                    block.uncompress(compression === CacheImageFormat.COMPRESS_LZMA ? CompressionAlgorithm.LZMA : CompressionAlgorithm.ZLIB);
                    pixels.writeBytes(block);
                    block.clear();
                }

                if (pixelFormat !== CacheImageFormat.PIXELS_STRAIGHT_TOP_DOWN)
                {
                    premultipliedToStraight(pixels, width, height, pixelFormat === CacheImageFormat.PIXELS_PREMULTIPLIED_BOTTOM_UP);
                }

                pixels.position = 0;
                PixelRestore.setPixels(layers[l], layers[l].rect, pixels);
                pixels.clear();
            }

            all.clear();
            return { bmpd1: layer1, bmpd2: layer2, metadata: metadata };
        }

        private static function readOldFormat(data:Array):Object
        {
            data[0].uncompress();
            data[1].uncompress();
            const metadata:CacheImageMetaData = data[2] as CacheImageMetaData;
            const rect:Rectangle = new Rectangle(0, 0, metadata.bmpdWidth, metadata.bmpdHeight);
            const layer1:BitmapData = new BitmapData(metadata.bmpdWidth, metadata.bmpdHeight, true, 0);
            const layer2:BitmapData = new BitmapData(metadata.bmpdWidth, metadata.bmpdHeight, true, 0);
            PixelRestore.setPixels(layer1, rect, data[0]);
            PixelRestore.setPixels(layer2, rect, data[1]);
            data[0].clear();
            data[1].clear();
            return { bmpd1: layer1, bmpd2: layer2, metadata: metadata };
        }

        // 내부 버퍼 원본(호스트 32비트 ARGB를 리틀 엔디언으로 = 바이트 B,G,R,A)을 straight A,R,G,B 위 행부터로 바꿈
        // 네이티브를 못 쓸때만 쓰는 경로라 1회 근사 손실(반올림)을 허용함
        private static function premultipliedToStraight(pixels:ByteArray, width:uint, height:uint, bottomUp:Boolean):void
        {
            const rowBytes:uint = width * 4;
            const total:uint = rowBytes * height;
            const work:ByteArray = new ByteArray();
            work.length = Math.max(total * 2, 1024); // 앞쪽 원본, 뒤쪽 결과
            work.writeBytes(pixels, 0, total);
            const previousMemory:ByteArray = ApplicationDomain.currentDomain.domainMemory;

            try
            {
                ApplicationDomain.currentDomain.domainMemory = work;
                var y:uint, x:uint, s:uint, d:uint, a:int, r:int, g:int, b:int;

                for (y = 0;y < height;y++)
                {
                    s = (bottomUp ? (height - 1 - y) : y) * rowBytes;
                    d = total + y * rowBytes;
                    // 디버그 빌드는 소스 줄마다 debugline 명령이 들어가서 반복문 본문을 한 줄로 둠
                    for (x = 0;x < width;x++) { b = li8(s); g = li8(s + 1); r = li8(s + 2); a = li8(s + 3); if (a > 0 && a < 255) { r = Math.min(255, int((r * 255 + (a >> 1)) / a)); g = Math.min(255, int((g * 255 + (a >> 1)) / a)); b = Math.min(255, int((b * 255 + (a >> 1)) / a)); } else if (a === 0) { r = g = b = 0; } si8(a, d); si8(r, d + 1); si8(g, d + 2); si8(b, d + 3); s += 4; d += 4; }
                }
            }
            finally
            {
                ApplicationDomain.currentDomain.domainMemory = previousMemory;
            }

            pixels.clear();
            pixels.writeBytes(work, total, total);
            work.clear();
        }

        // 호출 안에서 다 씀 (첫 이미지 캐시 0번, 네이티브를 못 쓸때의 불러오기 캐시)
        public static function writeSync(file:File, layer1:BitmapData, layer2:BitmapData, metadata:CacheImageMetaData):void
        {
            const metadataBytes:ByteArray = new ByteArray();
            metadataBytes.writeObject(metadata);

            if (NativeCore.isAvailable && NativeCore.callResult("cacheWriteSync", file.nativePath, layer1, layer2, metadataBytes) === NativeCore.OK)
            {
                return;
            }

            const rect:Rectangle = new Rectangle(0, 0, layer1.width, layer1.height);
            const bytes1:ByteArray = new ByteArray();
            const bytes2:ByteArray = new ByteArray();
            layer1.copyPixelsToByteArray(rect, bytes1);
            layer2.copyPixelsToByteArray(rect, bytes2);
            const encoded:ByteArray = CacheImageFormat.encodeStraight(bytes1, bytes2, layer1.width, layer1.height, metadataBytes);
            bytes1.clear();
            bytes2.clear();
            const fs:FileStream = new FileStream();
            fs.open(file, FileMode.WRITE);
            fs.writeBytes(encoded);
            fs.close();
            encoded.clear();
        }
    }
}
