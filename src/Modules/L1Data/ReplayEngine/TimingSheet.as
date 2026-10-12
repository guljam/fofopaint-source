package Modules.L1Data.ReplayEngine
{
    import flash.utils.ByteArray;

    // 리플레이 타이밍 시트: 명령(프레임) 하나마다 직전 명령과의 간격(ms)을 기록한 표
    // 프레임 번호 i의 시각 = delta[0] + ... + delta[i], 첫 프레임이나 앱을 새로 켠 직후 명령의 delta는 0
    // 10000프레임씩 구간으로 나눠 구간마다 따로 압축함 (.fofo에는 구간 blob 목록으로 저장)
    // 재생할때는 ReplayClock이 구간을 하나씩만 풀어서 쓰고 구간을 벗어나면 버림
    // 층: L1 데이터 - 프레임마다 직전 명령과의 간격(ms)을 기록한 타이밍 시트
    public final class TimingSheet
    {
        public static const SEGMENT_FRAMES:int = 10000;

        // 한 구간의 간격 목록(deltaMsList)과 연출 길이 목록(animLengthList)을 가변 길이 정수로 차례로 쓰고 zlib으로 압축한 구간 blob을 만듬
        // 간격은 작은 값이 대부분이라 대부분 1바이트, 긴 공백만 2~5바이트이고, 연출 길이는 대부분 0이라 거의 공간을 안 씀
        public static function encodeSegmentDeltasAndAnimsToBlob(deltaMsList:Vector.<uint>, animLengthList:Vector.<uint>, segmentFrameCount:int):ByteArray
        {
            const output:ByteArray = new ByteArray();
            writeVarLengthIntsToByteArray(output, deltaMsList, segmentFrameCount);
            writeVarLengthIntsToByteArray(output, animLengthList, segmentFrameCount);
            output.compress();
            return output;
        }

        // values의 앞 count개를 가변 길이 정수(7비트씩, 이어지는 바이트는 최상위 비트 1)로 output 끝에 이어서 씀
        private static function writeVarLengthIntsToByteArray(output:ByteArray, values:Vector.<uint>, count:int):void
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

        // encodeSegmentDeltasAndAnimsToBlob의 반대. segmentBlob은 건드리지 않고, 결과는 segmentFrameCount 길이의 deltaMsList, animLengthList에 채움
        public static function decodeSegmentBlobToDeltasAndAnims(segmentBlob:ByteArray, segmentFrameCount:int, deltaMsList:Vector.<uint>, animLengthList:Vector.<uint>):void
        {
            const raw:ByteArray = new ByteArray();
            raw.writeBytes(segmentBlob, 0, segmentBlob.length);
            raw.uncompress();
            raw.position = 0;

            try
            {
                readVarLengthIntsFromByteArray(raw, deltaMsList, segmentFrameCount);
                readVarLengthIntsFromByteArray(raw, animLengthList, segmentFrameCount);

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

        // raw의 현재 위치부터 가변 길이 정수 count개를 읽어 values[0..count-1]에 채움 (형식이 깨졌으면 Error)
        private static function readVarLengthIntsFromByteArray(raw:ByteArray, values:Vector.<uint>, count:int):void
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
