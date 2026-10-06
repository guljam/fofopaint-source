package Modules.ReplayEngine
{
    import flash.utils.ByteArray;

    // 리플레이 타이밍 시트: 명령(프레임) 하나마다 직전 명령과의 간격(ms)을 기록한 표
    // 프레임 번호 i의 시각 = delta[0] + ... + delta[i], 첫 프레임이나 앱을 새로 켠 직후 명령의 delta는 0
    // 10000프레임씩 구간으로 나눠 구간마다 따로 압축함 (.fofo에는 구간 blob 목록으로 저장)
    // 재생할때는 ReplayClock이 구간을 하나씩만 풀어서 쓰고 구간을 벗어나면 버림
    public final class TimingSheet
    {
        public static const SEGMENT_FRAMES:int = 10000;

        // 간격(deltas)과 연출 길이(anims)를 가변 길이 정수로 차례로 쓰고 zlib으로 압축한 구간 데이터를 만듬
        // 간격은 작은 값이 대부분이라 대부분 1바이트, 긴 공백만 2~5바이트이고, 연출 길이는 대부분 0이라 거의 공간을 안 씀
        public static function encodeSegment(deltas:Vector.<uint>, anims:Vector.<uint>, count:int):ByteArray
        {
            const output:ByteArray = new ByteArray();
            writeVarints(output, deltas, count);
            writeVarints(output, anims, count);
            output.compress();
            return output;
        }

        private static function writeVarints(output:ByteArray, values:Vector.<uint>, count:int):void
        {
            for (var i:int = 0; i < count; i++)
            {
                var value:uint = values[i];

                while (value >= 128)
                {
                    output.writeByte((value & 127) | 128);
                    value >>>= 7;
                }

                output.writeByte(value);
            }
        }

        // encodeSegment의 반대. blob은 건드리지 않고, 결과는 count 길이의 deltas, anims에 채움
        public static function decodeSegment(blob:ByteArray, count:int, deltas:Vector.<uint>, anims:Vector.<uint>):void
        {
            const raw:ByteArray = new ByteArray();
            raw.writeBytes(blob, 0, blob.length);
            raw.uncompress();
            raw.position = 0;

            try
            {
                readVarints(raw, deltas, count);
                readVarints(raw, anims, count);

                if (raw.bytesAvailable > 0)
                {
                    throw new Error("Trailing timing sheet bytes");
                }
            }
            finally
            {
                raw.clear();
            }
        }

        private static function readVarints(raw:ByteArray, values:Vector.<uint>, count:int):void
        {
            for (var i:int = 0; i < count; i++)
            {
                var result:uint = 0;
                var shift:int = 0;

                while (true)
                {
                    if (raw.bytesAvailable === 0 || shift >= 35)
                    {
                        throw new Error("Invalid timing sheet segment");
                    }

                    const part:uint = raw.readUnsignedByte();
                    result |= (part & 127) << shift;
                    shift += 7;

                    if ((part & 128) === 0)
                    {
                        break;
                    }
                }

                values[i] = result;
            }
        }
    }
}
