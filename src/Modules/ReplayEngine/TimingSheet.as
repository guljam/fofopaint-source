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
        // ---- 아래 블록은 버전1 "구간 정보 배열(INFO_*)" 검색용. 앱 코드에서는 쓰지 않고 테스트 하네스에서만 씀
        //      (test-output/timing_sheet/TimingSheetTest.as). 재생 중 구간 탐색은 ReplayClock이 담당한다.

        // 구간 정보 배열의 필드 위치 (테스트 하네스가 넘기는 배열 형식)
        public static const INFO_FIRST_FRAME:int = 0; // 구간 첫 프레임 번호
        public static const INFO_FRAME_COUNT:int = 1; // 구간 프레임 수
        public static const INFO_START_TIME:int = 2; // 구간 첫 프레임의 시각(ms, 처음 프레임 기준)
        public static const INFO_DURATION:int = 3; // 구간 첫 프레임부터 마지막 프레임까지의 시간(ms)

        // 구간 정보 배열(INFO_FIRST_FRAME 오름차순)에서 frame이 들어있는 구간 번호, 없으면 -1 (테스트 하네스 전용)
        public static function findSegmentByFrame(infos:Array, frame:Number):int
        {
            return findSegment(infos, frame, INFO_FIRST_FRAME, INFO_FRAME_COUNT);
        }

        // 구간 정보 배열(INFO_START_TIME 오름차순)에서 time(ms)이 들어있는 구간 번호, 없으면 -1 (테스트 하네스 전용)
        // 구간 사이의 공백은 앞 구간에 속함
        public static function findSegmentByTime(infos:Array, time:Number):int
        {
            if (infos.length === 0 || time < infos[0][INFO_START_TIME])
            {
                return -1;
            }

            var low:int = 0;
            var high:int = infos.length - 1;

            while (low < high)
            {
                const mid:int = (low + high + 1) >> 1;

                if (infos[mid][INFO_START_TIME] <= time)
                {
                    low = mid;
                }
                else
                {
                    high = mid - 1;
                }
            }

            return low;
        }

        // findSegmentByFrame/findSegmentByTime이 쓰는 이분 탐색 헬퍼 (테스트 하네스 전용 경로에서만 호출됨)
        private static function findSegment(infos:Array, value:Number, startField:int, countField:int):int
        {
            var low:int = 0;
            var high:int = infos.length - 1;

            while (low <= high)
            {
                const mid:int = (low + high) >> 1;
                const info:Array = infos[mid];

                if (value < info[startField])
                {
                    high = mid - 1;
                }
                else if (value >= info[startField] + info[countField])
                {
                    low = mid + 1;
                }
                else
                {
                    return mid;
                }
            }

            return -1;
        }
    }
}
