package Modules.L1Data
{
    import flash.utils.ByteArray;
    import flash.utils.Endian;

    // 캐시 이미지 파일 형식 (anesrc/fofonative/src/cache.cpp와 같아야 함), worker도 쓰므로 다른 앱 클래스에 의존하지 않음
    //   "FCI2", u8 형식 버전, u8 압축(1 zlib, 2 LZMA), u8 픽셀 형식, u8 레이어 수(2), u32 너비, u32 높이,
    //   u32 메타데이터 길이 + 메타데이터(writeObject(CacheImageMetaData)),
    //   레이어마다 u32 블록 수, 블록마다 (u32 행 수, u32 원본 크기, u32 압축 크기), 블록 데이터들 (리틀 엔디언)
    // 픽셀 형식 1: premultiplied 내부 버퍼 원본(호스트 32비트 ARGB, 아래 행부터) - 네이티브가 씀, 손실 없음
    //          2: straight A,R,G,B(copyPixelsToByteArray, 위 행부터) - 네이티브를 못 쓸때 AS3/worker가 씀
    //          3: premultiplied, 위 행부터
    // 층: L1 데이터 - 캐시 이미지 파일 형식 정의
    public final class CacheImageFormat
    {
        public static const VERSION:int = 1;
        public static const COMPRESS_ZLIB:int = 1;
        public static const COMPRESS_LZMA:int = 2;
        public static const PIXELS_PREMULTIPLIED_BOTTOM_UP:int = 1;
        public static const PIXELS_STRAIGHT_TOP_DOWN:int = 2;
        public static const PIXELS_PREMULTIPLIED_TOP_DOWN:int = 3;

        public static function isNewFormat(head:ByteArray):Boolean
        {
            return head.length >= 4 && head[0] === 0x46 && head[1] === 0x43 && head[2] === 0x49 && head[3] === 0x32;
        }

        // straight 레이어 두 장(copyPixelsToByteArray 결과)을 레이어마다 zlib 블록 하나로 (AS3 대체 경로)
        // layer1, layer2는 압축되면서 내용이 바뀜
        public static function encodeStraight(layer1:ByteArray, layer2:ByteArray, width:uint, height:uint, metadata:ByteArray):ByteArray
        {
            const output:ByteArray = new ByteArray();
            output.endian = Endian.LITTLE_ENDIAN;
            output.writeUTFBytes("FCI2");
            output.writeByte(VERSION);
            output.writeByte(COMPRESS_ZLIB);
            output.writeByte(PIXELS_STRAIGHT_TOP_DOWN);
            output.writeByte(2);
            output.writeUnsignedInt(width);
            output.writeUnsignedInt(height);
            output.writeUnsignedInt(metadata.length);
            output.writeBytes(metadata);

            for each (var layer:ByteArray in [layer1, layer2])
            {
                const rawSize:uint = layer.length;
                layer.compress();
                output.writeUnsignedInt(1);
                output.writeUnsignedInt(height);
                output.writeUnsignedInt(rawSize);
                output.writeUnsignedInt(layer.length);
                output.writeBytes(layer);
            }

            output.position = 0;
            return output;
        }
    }
}
