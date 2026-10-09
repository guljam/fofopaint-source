package Modules.ReplayEngine
{
    // 펜 점의 시각 보정. 24fps 앱에서는 한 프레임 동안 들어온 점들이 전부 같은 getTimer 값으로 기록됨 (실측: 점의 약 84%가 직전 점과 같은 ms)
    // 그대로 재생하면 프레임마다 점 여러 개가 한꺼번에 그려져서 실제 입력 리듬(약 8ms 간격)이 사라지므로,
    // 같은 시각으로 기록된 연속 lineTo 묶음을 직전 시각부터 그 시각까지 구간에 균등하게 나눠서 시각을 새로 매김
    //   예) 이전 시각 100, 묶음 시각 142, 점 6개 -> 107, 114, 121, 128, 135, 142 (마지막 점은 원래 시각 그대로)
    // 이 클래스는 ReplayState.takeTimingSheetBufferTimes가 부르는 한 곳 외에는 아무것도 모름
    // 쓰지 않으려면 ENABLED를 false로 하거나 그 호출 한 줄을 지우면 되고, 파일 형식과 다른 코드는 바뀌지 않음
    // 층: L1 데이터 - 펜 점의 시각 보정
    public final class TimingSmoother
    {
        public static const ENABLED:Boolean = true;
        public static const MAX_GAP_MS:int = 100; // 직전 시각과 묶음 시각의 차이가 이보다 크면 쉬었다 시작한 것으로 보고 나누지 않음

        // times: 명령별 getTimer 값(int, 줄어들지 않음). commands: 같은 순서의 명령 배열. times를 제자리에서 고침
        public static function spread(times:Array, commands:Array):void
        {
            if (!ENABLED)
            {
                return;
            }

            const count:int = times.length;
            var i:int = 1;

            while (i < count)
            {
                if (!isLineTo(commands[i]))
                {
                    i++;
                    continue;
                }

                // i에서 시작하는, 같은 시각을 가진 연속 lineTo 묶음의 끝 찾기
                const batchTime:int = times[i];
                var end:int = i;

                while (end + 1 < count && isLineTo(commands[end + 1]) && times[end + 1] === batchTime)
                {
                    end++;
                }

                // 묶음 바로 앞 명령의 시각이 더 이르고 간격이 정상 범위일때만 나눔
                const previousTime:int = times[i - 1];
                const gap:int = (batchTime - previousTime) | 0;
                const size:int = end - i + 1;

                if (size > 1 && gap > 0 && gap <= MAX_GAP_MS)
                {
                    for (var j:int = 0; j < size; j++)
                    {
                        times[i + j] = previousTime + Math.round(gap * (j + 1) / size);
                    }
                }

                i = end + 1;
            }
        }

        private static function isLineTo(command:*):Boolean
        {
            return command is Array && command[0] === "lineTo";
        }
    }
}
