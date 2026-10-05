package Modules.ReplayEngine
{
    import Modules.AppStateManager;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.utils.ByteArray;
    import flash.utils.getTimer;

    // 실시간 재생 시계. 타이밍 시트(TimingSheetFile)의 간격으로 프레임(명령)마다 녹화 시각을 알고,
    // 재생 시작 지점의 녹화 시각 R0와 그때의 getTimer T0를 기준으로 지금 녹화 시각 R = R0 + (getTimer() - T0) * 배속 를 구해서
    // 시각이 R 이하인 프레임까지 그리게 함. 매번 기준점과 비교하니 프레임 레이트가 바뀌어도 오차가 쌓이지 않음
    // 시각은 파일 구간(10000프레임)을 하나씩만 풀어서 구하고, 파일 뒤의 메모리 undo 묶음은 기록해둔 시각에서 구함
    public final class ReplayClock
    {
        public static const AFK_WAIT_MS:Number = 10000; // 이 시간(실제 대기) 이상 쉬었으면 AFK로 봄. 녹화 시간으로는 이 값 * 배속

        private static var fileFrames:Number = 0;
        private static var segmentStart:Vector.<Number> = new Vector.<Number>(); // 파일 구간별 첫 프레임의 녹화 시각
        private static var memoryCumulative:Vector.<Number> = new Vector.<Number>(); // 파일 뒤 메모리 프레임의 녹화 시각 (파일 끝 시각 기준 누적)
        private static var fileEndTime:Number = 0;
        private static var totalTime:Number = 0;
        private static var totalFrames:Number = 0;

        // 쉬는 구간(간격이 AFK_WAIT_MS 이상인 곳)의 [시작 시각, 끝 시각] 쌍을 이어붙인 목록. 시크바의 어두운 구간 표시에 씀
        private static var gapRanges:Vector.<Number> = new Vector.<Number>();

        private static var cachedSegment:int = -1; // 풀어둔 파일 구간 번호
        private static var cachedTimes:Vector.<Number> = null; // 그 구간 안 프레임별 녹화 시각 (구간 시작 시각 포함한 절대값)
        private static var cachedAnims:Vector.<uint> = null; // 그 구간 안 프레임별 연출 길이(ms)
        private static var memoryAnims:Vector.<uint> = new Vector.<uint>(); // 파일 뒤 메모리 프레임의 연출 길이

        private static var anchorRecorded:Number = 0; // R0
        private static var anchorReal:int = 0; // T0
        private static var anchorSpeed:Number = 1;

        private static var afkEnd:Number = -1; // AFK 중이면 공백이 끝나는 녹화 시각, 아니면 -1

        public static function get totalMs():Number
        {
            return totalTime;
        }

        public static function get frameCount():Number
        {
            return totalFrames;
        }

        // 프레임 수가 바뀌는 곳(파일 열기, 자르기, 리플레이 모드 진입)에서 부름. 시간 파일을 한번 훑어서 구간 시작 시각을 구함
        public static function rebuild():void
        {
            fileFrames = ReplayState.getRFileDataTotalFrame();
            TimingSheetFile.alignTo(fileFrames);
            cachedSegment = -1;
            cachedTimes = null;
            cachedAnims = null;
            afkEnd = -1;

            segmentStart = new Vector.<Number>();
            gapRanges = new Vector.<Number>();
            var sum:Number = 0;
            var prevAnim:uint = 0; // 앞 프레임의 연출 길이
            const file:File = AppStateManager.replayTimingSheetFilePath;

            if (fileFrames > 0 && file.exists)
            {
                const fs:FileStream = new FileStream();
                const chunk:ByteArray = new ByteArray();
                fs.open(file, FileMode.READ);

                for (var first:Number = 0; first < fileFrames; first += TimingSheet.SEGMENT_FRAMES)
                {
                    segmentStart.push(sum);
                    const count:int = int(Math.min(TimingSheet.SEGMENT_FRAMES, fileFrames - first));
                    chunk.clear();
                    fs.readBytes(chunk, 0, count * TimingSheetFile.RECORD_BYTES);
                    chunk.position = 0;

                    for (var i:int = 0; i < count; i++)
                    {
                        const delta:uint = chunk.readUnsignedInt();
                        const anim:uint = chunk.readUnsignedInt();

                        // 쉬는 구간은 앞 프레임의 연출이 끝난 시각부터 이 프레임까지
                        if (delta > prevAnim && delta - prevAnim >= AFK_WAIT_MS)
                        {
                            gapRanges.push(sum + prevAnim, sum + delta);
                        }

                        sum += delta;
                        prevAnim = anim;
                    }
                }

                fs.close();
            }

            fileEndTime = sum;

            // 메모리 묶음: 파일 마지막 프레임 이후의 간격
            const memoryDeltas:Vector.<uint> = new Vector.<uint>();
            memoryAnims = new Vector.<uint>();
            TimingSheetFile.computeMemoryRecords(ReplayState.rMemoryDataTimingSheet, ReplayState.rMemoryData.length, memoryDeltas, memoryAnims);
            memoryCumulative = new Vector.<Number>(memoryDeltas.length, true);

            for (i = 0; i < memoryDeltas.length; i++)
            {
                if (memoryDeltas[i] > prevAnim && memoryDeltas[i] - prevAnim >= AFK_WAIT_MS)
                {
                    gapRanges.push(sum + prevAnim, sum + memoryDeltas[i]);
                }

                sum += memoryDeltas[i];
                prevAnim = memoryAnims[i];
                memoryCumulative[i] = sum;
            }

            totalTime = sum;
            totalFrames = fileFrames + memoryDeltas.length;
        }

        // 프레임 frame(0부터)이 그려져야 하는 녹화 시각. 범위 밖이면 양끝으로 맞춤
        public static function timeOfFrame(frame:Number):Number
        {
            if (frame < 0 || totalFrames === 0)
            {
                return 0;
            }

            if (frame >= totalFrames)
            {
                return totalTime;
            }

            if (frame >= fileFrames)
            {
                return memoryCumulative[int(frame - fileFrames)];
            }

            const segment:int = int(frame / TimingSheet.SEGMENT_FRAMES);
            loadSegment(segment);
            return cachedTimes[int(frame - segment * TimingSheet.SEGMENT_FRAMES)];
        }

        // 프레임 frame(0부터)의 연출 길이(ms), 연출이 없는 명령은 0
        public static function animMsOfFrame(frame:Number):Number
        {
            if (frame < 0 || frame >= totalFrames)
            {
                return 0;
            }

            if (frame >= fileFrames)
            {
                return memoryAnims[int(frame - fileFrames)];
            }

            const segment:int = int(frame / TimingSheet.SEGMENT_FRAMES);
            loadSegment(segment);
            return cachedAnims[int(frame - segment * TimingSheet.SEGMENT_FRAMES)];
        }

        private static function loadSegment(segment:int):void
        {
            if (segment === cachedSegment)
            {
                return;
            }

            const first:Number = segment * TimingSheet.SEGMENT_FRAMES;
            const count:int = int(Math.min(TimingSheet.SEGMENT_FRAMES, fileFrames - first));
            const deltas:Vector.<uint> = new Vector.<uint>(count, true);
            const anims:Vector.<uint> = new Vector.<uint>(count, true);
            TimingSheetFile.readRange(first, count, deltas, anims);
            const times:Vector.<Number> = new Vector.<Number>(count, true);
            var sum:Number = segmentStart[segment];

            for (var i:int = 0; i < count; i++)
            {
                sum += deltas[i];
                times[i] = sum;
            }

            cachedTimes = times;
            cachedAnims = anims;
            cachedSegment = segment;
        }

        // 녹화 시각 time까지 그려져야 하는 프레임 수 (시각이 time 이하인 프레임의 개수)
        // 구간 시작 시각으로 구간을 먼저 고르고 그 구간 안에서만 찾아서 구간을 여러번 풀지 않음
        public static function framesDueAt(time:Number):Number
        {
            if (totalFrames === 0)
            {
                return 0;
            }

            if (time >= totalTime)
            {
                return totalFrames;
            }

            if (fileFrames > 0 && time >= segmentStart[0])
            {
                var low:int = 0;
                var high:int = segmentStart.length - 1;

                while (low < high)
                {
                    const mid:int = (low + high + 1) >> 1;

                    if (segmentStart[mid] <= time)
                    {
                        low = mid;
                    }
                    else
                    {
                        high = mid - 1;
                    }
                }

                loadSegment(low);
                const found:int = countAtMost(cachedTimes, time);

                if (found < cachedTimes.length || low < segmentStart.length - 1 || memoryCumulative.length === 0)
                {
                    return low * TimingSheet.SEGMENT_FRAMES + found;
                }

                return fileFrames + countAtMost(memoryCumulative, time);
            }

            return fileFrames === 0 ? countAtMost(memoryCumulative, time) : 0;
        }

        // 오름차순 times에서 값이 time 이하인 항목 수
        private static function countAtMost(times:Vector.<Number>, time:Number):int
        {
            var low:int = 0;
            var high:int = times.length;

            while (low < high)
            {
                const mid:int = (low + high) >> 1;

                if (times[mid] <= time)
                {
                    low = mid + 1;
                }
                else
                {
                    high = mid;
                }
            }

            return low;
        }

        // frame개를 그린 상태에서 재생을 시작하거나 이어감 (처음, 건너뛰기, 일시정지 후 재개)
        // 마지막으로 그린 프레임의 시각에서 시작해서 다음 프레임의 간격만큼 기다림
        public static function anchorAtFrame(frame:Number, speed:Number):void
        {
            anchorRecorded = timeOfFrame(frame - 1);
            anchorReal = getTimer();
            anchorSpeed = speed;
            afkEnd = -1;
        }

        // 지금 녹화 시각 R. 배속이 바뀌면 그 순간부터 새 배속으로 이어지게 기준점을 옮김
        public static function recordedNow(speed:Number):Number
        {
            const now:int = getTimer();
            const current:Number = anchorRecorded + (now - anchorReal) * anchorSpeed;

            if (speed !== anchorSpeed)
            {
                anchorRecorded = current;
                anchorReal = now;
                anchorSpeed = speed;
            }

            return current;
        }

        // 지금 녹화 시각을 기준점이나 배속은 건드리지 않고 읽기만 함 (연출 진행률 계산용)
        public static function recordedPeek():Number
        {
            return anchorRecorded + (getTimer() - anchorReal) * anchorSpeed;
        }

        // 지금 그려야 하는 프레임 수. AFK 중이면 그리지 않고 현재 프레임 수 그대로
        // drawnFrames: 지금까지 그린 프레임 수
        public static function frameCountDue(drawnFrames:Number, speed:Number):Number
        {
            const recorded:Number = recordedNow(speed);

            // 다음 프레임이 AFK 공백 뒤에 있으면 공백이 끝날때까지 기다림
            if (drawnFrames < totalFrames && drawnFrames > 0)
            {
                // 앞 프레임의 연출(도구를 쓰던 시간)은 쉬는 시간이 아니라서 연출이 끝난 시각부터 셈
                const gapStart:Number = timeOfFrame(drawnFrames - 1) + animMsOfFrame(drawnFrames - 1);
                const gapEnd:Number = timeOfFrame(drawnFrames);

                if (recorded >= gapStart && gapEnd - gapStart >= AFK_WAIT_MS * speed && recorded < gapEnd)
                {
                    afkEnd = gapEnd;
                    return drawnFrames;
                }
            }

            afkEnd = -1;
            return Math.max(drawnFrames, framesDueAt(recorded));
        }

        public static function get isAfk():Boolean
        {
            return afkEnd >= 0;
        }

        // AFK 공백이 끝날때까지 남은 실제 시간(ms)
        public static function afkRemainingMs(speed:Number):Number
        {
            if (afkEnd < 0)
            {
                return 0;
            }

            return Math.max(0, (afkEnd - recordedNow(speed)) / speed);
        }

        // AFK 공백을 건너뜀
        public static function skipAfk():void
        {
            if (afkEnd < 0)
            {
                return;
            }

            anchorRecorded = afkEnd;
            anchorReal = getTimer();
            afkEnd = -1;
        }

        // 현재 배속에서 AFK가 되는 쉬는 구간(녹화 길이가 AFK_WAIT_MS * 배속 이상)의 [시작 시각, 끝 시각] 쌍 목록
        public static function getAfkRanges(speed:Number):Vector.<Number>
        {
            const result:Vector.<Number> = new Vector.<Number>();
            const minLength:Number = AFK_WAIT_MS * speed;

            for (var i:int = 0; i < gapRanges.length; i += 2)
            {
                if (gapRanges[i + 1] - gapRanges[i] >= minLength)
                {
                    result.push(gapRanges[i], gapRanges[i + 1]);
                }
            }

            return result;
        }

        // 시크바 위치(0~1)는 프레임 수가 아니라 녹화 시간 기준. frame개를 그린 상태의 위치
        public static function frameRatio(frame:Number):Number
        {
            if (totalTime <= 0)
            {
                return totalFrames > 0 ? Math.min(1, frame / totalFrames) : 0;
            }

            return Math.min(1, timeOfFrame(frame - 1) / totalTime);
        }

        // 시크바의 위치 ratio(0~1)에 해당하는 프레임 수 (시크바 클릭, 드래그)
        public static function ratioToFrame(ratio:Number):Number
        {
            if (ratio >= 1)
            {
                return totalFrames;
            }

            if (totalTime <= 0)
            {
                return Math.floor(totalFrames * Math.max(0, ratio));
            }

            return Math.min(totalFrames, framesDueAt(totalTime * Math.max(0, ratio)));
        }

        // 재생 중 시크바 위치. 그린 프레임이 아니라 시계가 흐르는 대로 움직여서 쉬는 구간(AFK)에도 바가 계속 감
        public static function playRatio(speed:Number):Number
        {
            return totalTime > 0 ? Math.min(1, recordedNow(speed) / totalTime) : 0;
        }

        // frame개를 그린 상태에서 남은 녹화 시간(ms). 표시용
        public static function remainingMsFrom(frame:Number):Number
        {
            return Math.max(0, totalTime - timeOfFrame(frame - 1));
        }
    }
}
