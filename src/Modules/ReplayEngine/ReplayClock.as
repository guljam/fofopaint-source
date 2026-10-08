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
        // 쉬는(Replay Waiting) 구간 규칙
        //   실제로 기다리는 시간이 CAP_MS를 넘으면 CAP_MS만 기다리고 다음 프레임으로 건너뜀 (자동 건너뛰기)
        //   건너뛰기 직전에 어색하게 조금만 건너뛰지 않도록, 실제 대기가 ENTRY_MS(캡보다 약간 큼) 이상인 공백부터 캡을 적용함
        //   녹화 길이로는 공백 g가 ENTRY_MS * 배속 이상이면 캡 대상
        public static const CAP_MS:Number = 5000;
        public static const ENTRY_MS:Number = 6000;
        // 시크바 축은 지금 배속(ReplayState.rReplaySpeedMultipler)의 규칙을 그대로 따름
        //   쉬는 구간(g >= ENTRY_MS * 배속)은 실제로 기다리는 앞부분(녹화 CAP_MS * 배속)만 남기고 그 뒤 건너뛰는 부분은 폭 0으로 줄임
        //   그래서 시크바는 언제나 같은 속도로 차오르고, 축 길이 / 배속 = 예상 재생 시간

        private static var fileFrames:Number = 0;
        private static var segmentStart:Vector.<Number> = new Vector.<Number>(); // 파일 구간별 첫 프레임의 녹화 시각
        private static var memoryCumulative:Vector.<Number> = new Vector.<Number>(); // 파일 뒤 메모리 프레임의 녹화 시각 (파일 끝 시각 기준 누적)
        private static var fileEndTime:Number = 0;
        private static var totalTime:Number = 0;
        private static var totalFrames:Number = 0;

        // 쉬는 구간(간격이 ENTRY_MS 이상인 곳)의 [시작 시각, 끝 시각] 쌍을 이어붙인 목록. 시간순
        private static var gapRanges:Vector.<Number> = new Vector.<Number>();
        // 지금 배속에서 건너뛰기 대상인 쉬는 구간만 추린 [시작, 끝] 쌍 목록과 줄어든 시간의 앞쪽 합 (ensureAxis가 배속이 바뀔때 만듬)
        // idlePrefix[i] = 앞쪽 구간 i개가 줄어든 시간 sum(g - 유지 길이), 길이는 구간 수 + 1
        private static var axisSpeed:Number = -1;
        private static var idleRanges:Vector.<Number> = new Vector.<Number>();
        private static var idlePrefix:Vector.<Number> = new Vector.<Number>();
        private static var keepMs:Number = CAP_MS; // 쉬는 구간에서 시크바에 남기는 녹화 길이(CAP_MS * 배속)

        private static var cachedSegment:int = -1; // 풀어둔 파일 구간 번호
        private static var cachedTimes:Vector.<Number> = null; // 그 구간 안 프레임별 녹화 시각 (구간 시작 시각 포함한 절대값)
        private static var cachedAnims:Vector.<uint> = null; // 그 구간 안 프레임별 연출 길이(ms)
        private static var memoryAnims:Vector.<uint> = new Vector.<uint>(); // 파일 뒤 메모리 프레임의 연출 길이
        private static var memoryPoints:Object = {}; // 파일 뒤 메모리 프레임 번호(문자열 키) -> 점별 시각(도구 시작 기준 ms) 배열

        private static var anchorRecorded:Number = 0; // R0
        private static var anchorReal:int = 0; // T0
        private static var anchorSpeed:Number = 1;

        // 일시정지하거나 시크바를 클릭한 위치. 프레임이 같다면 다시 재생할때 그 녹화 시각에서 이어감 (쉬는 구간 중간 등)
        private static var rememberedFrame:Number = -1;
        private static var rememberedRecorded:Number = 0;

        private static var replayWaitingEnd:Number = -1; // Replay Waiting 중이면 공백이 끝나는 녹화 시각, 아니면 -1
        private static var replayWaitingSkipAt:Number = 0; // Replay Waiting 중이면 자동으로 건너뛰는 녹화 시각 (공백 시작 + CAP_MS * 배속)

        // 테스트 하네스(test-output) 전용. 앱 코드에서 호출하지 않음 (지우려면 하네스 호출부도 함께 수정)
        public static function get totalMs():Number
        {
            return totalTime;
        }

        // 테스트 하네스(test-output) 전용. 앱 코드에서 호출하지 않음
        public static function get frameCount():Number
        {
            return totalFrames;
        }

        // 파일 부분 색인. 요약뿐이라 구간 수만큼만 메모리를 씀 (프레임별 시각은 디스크의 타이밍 시트에 두고 구간 하나만 풀어 씀)
        private static var indexedFileFrames:Number = -1; // 색인에 반영된 파일 프레임 수. -1이면 아직 만들지 않음
        private static var fileGaps:Vector.<Number> = new Vector.<Number>(); // 파일 부분의 쉬는 구간 [시작, 끝] 쌍 (gapRanges = 파일 부분 + 메모리 부분)
        private static var fileLastAnim:uint = 0; // 파일 마지막 프레임의 연출 길이
        private static var indexMissCount:int = 0; // 갱신 지점이 빠져서 ensureIndex가 보정한 횟수

        // 테스트 하네스(test-output) 전용. 앱 코드에서 호출하지 않음
        public static function get indexMisses():int
        {
            return indexMissCount;
        }

        // 테스트 하네스(test-output) 전용. 앱 코드에서 호출하지 않음. 지금 색인 요약 (증분 결과와 전체 다시 만든 결과를 비교하는 데 씀)
        public static function indexSnapshot():Object
        {
            return {
                indexed: indexedFileFrames,
                segmentStart: segmentStart.join(","),
                gaps: gapRanges.join(","),
                fileGaps: fileGaps.join(","),
                fileEndTime: fileEndTime,
                fileLastAnim: fileLastAnim,
                totalTime: totalTime,
                totalFrames: totalFrames
            };
        }

        private static function invalidateSegmentCache():void
        {
            cachedSegment = -1;
            cachedTimes = null;
            cachedAnims = null;
            axisSpeed = -1;
        }

        // 파일 전체를 처음부터 읽어 파일 부분 색인을 새로 만듬. 파일 불러오기, 새 파일, 앞 자르기, 처음 만들 때, 확인이 실패했을 때만 부름
        public static function rebuildFileIndex():void
        {
            trace('call');
            fileFrames = ReplayState.getRFileDataTotalFrame();
            TimingSheetFile.resizeToFrameCount(fileFrames);
            invalidateSegmentCache();
            segmentStart = new Vector.<Number>();
            fileGaps = new Vector.<Number>();
            fileEndTime = 0;
            fileLastAnim = 0;
            indexedFileFrames = 0;
            readIntoFileIndex(fileFrames);
            trace('fileEndTime',fileEndTime,"fileLastAnim",fileLastAnim);
        }

        // indexedFileFrames부터 to 프레임 앞까지만 읽어 파일 부분 색인을 이어서 갱신 (구간 경계마다 나눠 읽음)
        private static function readIntoFileIndex(to:Number):void
        {
            const file:File = AppStateManager.replayTimingSheetFilePath;
            var first:Number = indexedFileFrames;

            if (to > first && file.exists)
            {
                const fs:FileStream = new FileStream();
                const chunk:ByteArray = new ByteArray();
                fs.open(file, FileMode.READ);
                fs.position = first * TimingSheetFile.RECORD_BYTES;

                while (first < to)
                {
                    const count:int = int(Math.min(TimingSheet.SEGMENT_FRAMES - first % TimingSheet.SEGMENT_FRAMES, to - first));
                    trace('count',count);
                    chunk.clear();
                    fs.readBytes(chunk, 0, count * TimingSheetFile.RECORD_BYTES);
                    chunk.position = 0;
                    consumeBytes(chunk, count);
                    first += count;
                }

                fs.close();
            }
        }

        // 현재 위치부터 [간격(uint), 연출 길이(uint)] 기록 count개를 읽어 파일 부분 색인 끝에 반영. 파일을 읽는 경로, 덧붙인 값을 바로 받는 경로, 시트를 다시 쓰는 경로가 모두 여기서 계산함
        private static function consumeBytes(bytes:ByteArray, count:int):void
        {
            var sum:Number = fileEndTime;
            var prevAnim:uint = fileLastAnim; // 앞 프레임의 연출 길이
            var frame:Number = indexedFileFrames;

            for (var i:int = 0; i < count; i++)
            {
                if (frame % TimingSheet.SEGMENT_FRAMES === 0)
                {
                    segmentStart.push(sum);
                }

                const delta:uint = bytes.readUnsignedInt();
                const anim:uint = bytes.readUnsignedInt();

                // 쉬는 구간은 앞 프레임의 연출이 끝난 시각부터 이 프레임까지
                if (delta > prevAnim && delta - prevAnim >= ENTRY_MS)
                {
                    fileGaps.push(sum + prevAnim, sum + delta);
                }

                sum += delta;
                prevAnim = anim;
                frame++;
            }

            fileEndTime = sum;
            fileLastAnim = prevAnim;
            indexedFileFrames = frame;
            fileFrames = frame;
        }

        // appendGroupAtFrame이 방금 쓴 [간격, 연출 길이] 기록을 받아 파일을 다시 읽지 않고 반영. firstFrame이 색인 끝과 다르면(시트를 채워 맞춘 경우 등) 파일에서 읽음
        public static function extendFileIndexWith(records:Vector.<uint>, firstFrame:Number):void
        {
            if (indexedFileFrames < 0)
            {
                return;
            }

            if (indexedFileFrames !== firstFrame)
            {
                extendFileIndex();
                return;
            }

            invalidateSegmentCache();
            const bytes:ByteArray = new ByteArray();

            for (var i:int = 0; i < records.length; i++)
            {
                bytes.writeUnsignedInt(records[i]);
            }

            bytes.position = 0;
            consumeBytes(bytes, records.length / 2);
        }

        // 시트를 비웠을 때(새 파일, 불러오기 시작) 색인도 빈 상태로 맞춤. 비운 시트에는 읽을 것이 없으므로 이게 곧 정확한 색인
        public static function resetIndexEmpty():void
        {
            invalidateSegmentCache();
            segmentStart = new Vector.<Number>();
            fileGaps = new Vector.<Number>();
            fileEndTime = 0;
            fileLastAnim = 0;
            indexedFileFrames = 0;
            fileFrames = 0;
        }

        // [간격(uint), 연출 길이(uint)] 8바이트 기록이 이어진 ByteArray(처음부터 끝까지)를 지금 색인 끝에 이어서 반영. 시트를 다시 쓰는 쪽(앞 자르기)이 이미 가진 메모리를 쓰므로 파일을 읽지 않음
        public static function indexBytes(bytes:ByteArray):void
        {
            if (indexedFileFrames < 0)
            {
                return;
            }

            invalidateSegmentCache();
            bytes.position = 0;

            while (bytes.bytesAvailable >= TimingSheetFile.RECORD_BYTES)
            {
                const count:int = int(Math.min(TimingSheet.SEGMENT_FRAMES - indexedFileFrames % TimingSheet.SEGMENT_FRAMES, bytes.bytesAvailable / TimingSheetFile.RECORD_BYTES));
                consumeBytes(bytes, count);
            }
        }

        // ---- 요약 파일 (reptimingindex): 앱을 껐다 켜도 전체 읽기 없이 색인을 되살림 ----
        // 구성: "RTI1", 프레임 수, 시트 파일 크기, 시트 끝 32프레임 해시, 끝 시각, 끝 연출 길이, 구간 수 + 시작 시각들, 쉬는 구간 값 수 + 값들
        // 앱 상태를 저장하는 때(saveAllAppData)에 쓰고 시작할 때 읽음. 저장 없이 죽어서 시트와 안 맞으면 확인에서 걸러져 전체 읽기로 되돌아감

        private static const INDEX_MAGIC:String = "RTI1";

        // 시트 끝 최대 32프레임(256바이트)의 해시. 요약이 이 시트의 것인지 확인용
        private static function sheetTailHash(frames:Number):uint
        {
            const file:File = AppStateManager.replayTimingSheetFilePath;
            var hash:uint = 2166136261;

            if (frames <= 0 || !file.exists)
            {
                return hash;
            }

            const count:int = int(Math.min(32, frames));
            const fs:FileStream = new FileStream();
            fs.open(file, FileMode.READ);
            fs.position = (frames - count) * TimingSheetFile.RECORD_BYTES;

            for (var i:int = 0; i < count * 2; i++)
            {
                hash = ((hash ^ fs.readUnsignedInt()) * 16777619) & 0xFFFFFFFF;
            }

            fs.close();
            return hash;
        }

        public static function saveIndex():void
        {
            const file:File = AppStateManager.replayTimingIndexFilePath;
            const sheet:File = AppStateManager.replayTimingSheetFilePath;

            // 색인이 지금 시트와 맞지 않으면 옛 요약이 남지 않게 지움
            if (indexedFileFrames < 0 || indexedFileFrames !== ReplayState.getRFileDataTotalFrame() || indexedFileFrames !== TimingSheetFile.frameCount)
            {
                if (file.exists)
                {
                    file.deleteFile();
                }

                return;
            }

            const fs:FileStream = new FileStream();
            fs.open(file, FileMode.WRITE);
            fs.writeUTFBytes(INDEX_MAGIC);
            fs.writeDouble(indexedFileFrames);
            fs.writeDouble(sheet.exists ? sheet.size : 0);
            fs.writeUnsignedInt(sheetTailHash(indexedFileFrames));
            fs.writeDouble(fileEndTime);
            fs.writeUnsignedInt(fileLastAnim);
            fs.writeUnsignedInt(segmentStart.length);

            for (var i:int = 0; i < segmentStart.length; i++)
            {
                fs.writeDouble(segmentStart[i]);
            }

            fs.writeUnsignedInt(fileGaps.length);

            for (i = 0; i < fileGaps.length; i++)
            {
                fs.writeDouble(fileGaps[i]);
            }

            fs.close();
        }

        // 요약 파일을 읽어 시트와 맞으면 그대로 씀. 없거나 맞지 않으면 색인을 만들지 않고 둠 (첫 사용 때 ensureIndex가 전체 읽기) + 로그
        public static function loadIndex():void
        {
            indexedFileFrames = -1;
            const file:File = AppStateManager.replayTimingIndexFilePath;
            const frames:Number = ReplayState.getRFileDataTotalFrame();

            if (frames <= 0)
            {
                return; // 비어 있으면 읽을 것이 없음. 첫 사용 때 만들어도 비용 0
            }

            if (!file.exists)
            {
                trace("[ReplayClock] 색인 요약 파일 없음, 첫 사용 때 전체 읽기");
                return;
            }

            try
            {
                const sheet:File = AppStateManager.replayTimingSheetFilePath;
                const fs:FileStream = new FileStream();
                fs.open(file, FileMode.READ);

                if (fs.readUTFBytes(4) !== INDEX_MAGIC)
                {
                    fs.close();
                    trace("[ReplayClock] 색인 요약 파일 형식이 다름, 첫 사용 때 전체 읽기");
                    return;
                }

                const savedFrames:Number = fs.readDouble();
                const savedBytes:Number = fs.readDouble();
                const savedHash:uint = fs.readUnsignedInt();

                if (savedFrames !== frames || !sheet.exists || savedBytes !== sheet.size || sheet.size !== frames * TimingSheetFile.RECORD_BYTES || savedHash !== sheetTailHash(frames))
                {
                    fs.close();
                    trace("[ReplayClock] 색인 요약이 시트와 맞지 않음(저장 없이 종료 등), 첫 사용 때 전체 읽기");
                    return;
                }

                const endTime:Number = fs.readDouble();
                const lastAnim:uint = fs.readUnsignedInt();
                const starts:Vector.<Number> = new Vector.<Number>();
                const segmentCount:uint = fs.readUnsignedInt();

                if (segmentCount !== Math.ceil(frames / TimingSheet.SEGMENT_FRAMES))
                {
                    fs.close();
                    trace("[ReplayClock] 색인 요약의 구간 수가 다름, 첫 사용 때 전체 읽기");
                    return;
                }

                for (var i:uint = 0; i < segmentCount; i++)
                {
                    starts.push(fs.readDouble());
                }

                const gaps:Vector.<Number> = new Vector.<Number>();
                const gapCount:uint = fs.readUnsignedInt();

                for (i = 0; i < gapCount; i++)
                {
                    gaps.push(fs.readDouble());
                }

                fs.close();
                invalidateSegmentCache();
                segmentStart = starts;
                fileGaps = gaps;
                fileEndTime = endTime;
                fileLastAnim = lastAnim;
                indexedFileFrames = frames;
                fileFrames = frames;
            }
            catch (error:Error)
            {
                indexedFileFrames = -1;
                trace("[ReplayClock] 색인 요약 읽기 실패, 첫 사용 때 전체 읽기: " + error);
            }
        }

        // 파일 뒤에 프레임이 덧붙었을 때(undo 묶음이 파일로 넘어감) 덧붙은 만큼만 읽어 이어서 반영. 아직 색인을 만든 적 없으면 첫 사용 때 만들므로 건너뜀
        public static function extendFileIndex():void
        {
            if (indexedFileFrames < 0)
            {
                return;
            }

            invalidateSegmentCache(); // 마지막 구간이 풀려 있으면 길이가 옛 값이라 무효화
            readIntoFileIndex(ReplayState.getRFileDataTotalFrame());
        }

        // 파일이 frame개로 잘렸을 때 frame이 속한 구간 하나만 다시 읽어 색인을 맞춤
        public static function truncateFileIndex(frame:Number):void
        {
            if (indexedFileFrames < 0 || frame >= indexedFileFrames)
            {
                return;
            }

            invalidateSegmentCache();
            fileFrames = frame;
            indexedFileFrames = frame;

            if (frame <= 0)
            {
                segmentStart = new Vector.<Number>();
                fileGaps = new Vector.<Number>();
                fileEndTime = 0;
                fileLastAnim = 0;
                return;
            }

            // 마지막 프레임(frame - 1)이 속한 구간 s의 시작부터 그 프레임까지만 읽어 끝 시각과 끝 연출 길이를 구함
            const s:int = int((frame - 1) / TimingSheet.SEGMENT_FRAMES);
            segmentStart.length = s + 1;
            const first:Number = s * TimingSheet.SEGMENT_FRAMES;
            const count:int = int(frame - first);
            const deltas:Vector.<uint> = new Vector.<uint>(count, true);
            const anims:Vector.<uint> = new Vector.<uint>(count, true);
            TimingSheetFile.readRange(first, count, deltas, anims);
            var sum:Number = segmentStart[s];

            for (var i:int = 0; i < count; i++)
            {
                sum += deltas[i];
            }

            fileEndTime = sum;
            fileLastAnim = anims[count - 1];

            // 쉬는 구간 끝 시각이 새 끝 시각을 넘는 첫 항목부터 잘라냄 (끝 시각은 시간순)
            var low:int = 0;
            var high:int = fileGaps.length / 2;

            while (low < high)
            {
                const mid:int = (low + high) >> 1;

                if (fileGaps[mid * 2 + 1] <= sum)
                {
                    low = mid + 1;
                }
                else
                {
                    high = mid;
                }
            }

            fileGaps.length = low * 2;
        }

        // 파일 부분 색인이 실제 프레임 수와 맞는지 확인. 처음이면 만들고, 어긋나 있으면(갱신 지점이 빠짐) 보정하고 로그
        public static function ensureIndex():void
        {
            const actual:Number = ReplayState.getRFileDataTotalFrame();
            TimingSheetFile.resizeToFrameCount(actual); // 시트 길이를 repdata와 맞춤 (예전에는 rebuild 맨 앞에서 했음)

            if (indexedFileFrames < 0)
            {
                rebuildFileIndex();
            }
            else if (indexedFileFrames < actual)
            {
                indexMissCount++;
                trace("[ReplayClock] 색인 갱신 지점이 빠짐: " + indexedFileFrames + " < " + actual + ", 모자란 만큼 이어서 반영");
                extendFileIndex();
            }
            else if (indexedFileFrames > actual)
            {
                indexMissCount++;
                trace("[ReplayClock] 색인 갱신 지점이 빠짐: " + indexedFileFrames + " > " + actual + ", 전체 다시 만듦");
                rebuildFileIndex();
            }
        }

        // 메모리 undo 묶음 부분을 새로 만들고 전체 길이를 다시 계산. 시계를 쓰기 직전(모드 진입, deep undo 진입 등)에 부름. 크기가 undo 개수만큼이라 매번 다시 해도 됨
        public static function rebuildMemoryIndex():void
        {
            rememberedFrame = -1;
            replayWaitingEnd = -1;
            axisSpeed = -1;
            fileFrames = indexedFileFrames;
            var sum:Number = fileEndTime;
            var prevAnim:uint = fileLastAnim;
            gapRanges = fileGaps.concat();

            // 메모리 묶음: 파일 마지막 프레임 이후의 간격
            const memoryDeltas:Vector.<uint> = new Vector.<uint>();
            memoryAnims = new Vector.<uint>();
            TimingSheetFile.computeMemoryRecords(ReplayState.rMemoryDataTimingSheet, ReplayState.rMemoryData.length, memoryDeltas, memoryAnims);
            memoryCumulative = new Vector.<Number>(memoryDeltas.length, true);

            for (var i:int = 0; i < memoryDeltas.length; i++)
            {
                if (memoryDeltas[i] > prevAnim && memoryDeltas[i] - prevAnim >= ENTRY_MS)
                {
                    gapRanges.push(sum + prevAnim, sum + memoryDeltas[i]);
                }

                sum += memoryDeltas[i];
                prevAnim = memoryAnims[i];
                memoryCumulative[i] = sum;
            }

            // 메모리 프레임의 점별 시각 (점 시각이 필요한 명령만 가짐)
            memoryPoints = {};
            var position:Number = fileFrames;

            for (var g:int = 0; g < ReplayState.rMemoryData.length; g++)
            {
                const stamps:Array = ReplayState.rMemoryDataTimingSheet[g];

                for (var j:int = 0; j < stamps.length; j++)
                {
                    const points:Array = TimingSheetFile.pointsOf(stamps[j]);

                    if (points !== null)
                    {
                        memoryPoints[String(position)] = points;
                    }

                    position++;
                }
            }

            totalTime = sum;
            totalFrames = fileFrames + memoryDeltas.length;
        }

        // 배속이 바뀌었으면 건너뛰기 대상 쉬는 구간 목록과 줄어든 시간의 합을 다시 만듬
        private static function ensureAxis():void
        {
            const speed:Number = ReplayState.rReplaySpeedMultipler;

            if (speed === axisSpeed)
            {
                return;
            }

            axisSpeed = speed;
            keepMs = CAP_MS * speed;
            idleRanges = new Vector.<Number>();
            const prefix:Array = [0];
            var removed:Number = 0;

            for (var i:int = 0; i < gapRanges.length; i += 2)
            {
                const length:Number = gapRanges[i + 1] - gapRanges[i];

                if (length >= ENTRY_MS * speed)
                {
                    idleRanges.push(gapRanges[i], gapRanges[i + 1]);
                    removed += length - keepMs;
                    prefix.push(removed);
                }
            }

            idlePrefix = Vector.<Number>(prefix);
        }

        // 지금 배속에서 시크바 축의 전체 길이(ms) = 전체 녹화 시간 - 건너뛰는 부분. 이 값 / 배속 = 예상 재생 시간
        public static function get axisMs():Number
        {
            ensureAxis();
            return Math.max(0, totalTime - idlePrefix[idlePrefix.length - 1]);
        }

        // 배속 speed에서의 축 길이. 현재 배속과 상관없이 계산할 수 있음 (최대 배속은 1배속 기준으로 정함)
        public static function axisMsAtSpeed(speed:Number):Number
        {
            var removed:Number = 0;

            for (var i:int = 0; i < gapRanges.length; i += 2)
            {
                const length:Number = gapRanges[i + 1] - gapRanges[i];

                if (length >= ENTRY_MS * speed)
                {
                    removed += length - CAP_MS * speed;
                }
            }

            return Math.max(0, totalTime - removed);
        }

        // 녹화 시각 t(ms)를 시크바 축 위치(ms)로 바꿈. 쉬는 구간에서는 앞부분(유지 길이)만 1:1로 움직이고 그 뒤는 폭 0
        private static function toAxis(t:Number):Number
        {
            ensureAxis();
            const count:int = idleRanges.length / 2;
            var low:int = 0;
            var high:int = count - 1;
            var index:int = -1; // 시작 시각이 t 이하인 마지막 쉬는 구간

            while (low <= high)
            {
                const mid:int = (low + high) >> 1;

                if (idleRanges[mid * 2] <= t)
                {
                    index = mid;
                    low = mid + 1;
                }
                else
                {
                    high = mid - 1;
                }
            }

            if (index < 0)
            {
                return t;
            }

            const start:Number = idleRanges[index * 2];
            const end:Number = idleRanges[index * 2 + 1];
            const axisAtStart:Number = start - idlePrefix[index];

            if (t >= end)
            {
                return axisAtStart + keepMs + (t - end);
            }

            return axisAtStart + Math.min(t - start, keepMs);
        }

        // toAxis의 반대. 쉬는 구간의 유지 길이 안이면 그 위치의 녹화 시각, 유지 길이의 끝 위치는 건너뛴 뒤인 공백 끝으로 봄
        private static function fromAxis(u:Number):Number
        {
            ensureAxis();
            const count:int = idleRanges.length / 2;
            var low:int = 0;
            var high:int = count - 1;
            var index:int = -1; // 축 시작 위치가 u 이하인 마지막 쉬는 구간

            while (low <= high)
            {
                const mid:int = (low + high) >> 1;

                if (idleRanges[mid * 2] - idlePrefix[mid] <= u)
                {
                    index = mid;
                    low = mid + 1;
                }
                else
                {
                    high = mid - 1;
                }
            }

            if (index < 0)
            {
                return u;
            }

            const start:Number = idleRanges[index * 2];
            const axisAtStart:Number = start - idlePrefix[index];

            if (u >= axisAtStart + keepMs)
            {
                return u + idlePrefix[index + 1];
            }

            return start + (u - axisAtStart);
        }

        // 시크바의 쉬는 구간 표시용: [시작 비율, 끝 비율] 쌍(0~1)을 이어붙인 목록. 지금 배속에서 건너뛰기 대상인 구간의 유지 길이만 표시됨
        public static function getIdleMarks():Vector.<Number>
        {
            ensureAxis();
            const result:Vector.<Number> = new Vector.<Number>();
            const length:Number = axisMs;

            if (length <= 0)
            {
                return result;
            }

            for (var i:int = 0; i < idleRanges.length; i += 2)
            {
                const axisStart:Number = idleRanges[i] - idlePrefix[i / 2];
                result.push(axisStart / length, (axisStart + keepMs) / length);
            }

            return result;
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

        // 프레임 frame(0부터)의 점별 시각(그 명령의 시각 기준 ms), 기록이 없으면 null (선 도구의 점 순서 연출에 씀)
        public static function pointOffsetsOfFrame(frame:Number):Vector.<uint>
        {
            if (frame < 0 || frame >= totalFrames)
            {
                return null;
            }

            if (frame >= fileFrames)
            {
                const memory:Array = memoryPoints[String(frame)];

                if (memory === null)
                {
                    return null;
                }

                const copy:Vector.<uint> = new Vector.<uint>(memory.length, true);

                for (var i:int = 0; i < memory.length; i++)
                {
                    copy[i] = memory[i];
                }

                return copy;
            }

            return TimingSheetFile.readPoints(frame);
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

            // 기억해둔 위치가 같은 프레임에서 다음 프레임 직전 사이(쉬는 구간이나 대기 중간)면 그 시각에서 이어감
            if (rememberedFrame === frame && rememberedRecorded > anchorRecorded && rememberedRecorded < timeOfFrame(frame))
            {
                anchorRecorded = rememberedRecorded;
            }

            rememberedFrame = -1;
            anchorReal = getTimer();
            anchorSpeed = speed;
            replayWaitingEnd = -1;
        }

        // 일시정지하거나 시크바를 클릭한 때 frame개를 그린 상태와 그 녹화 시각을 기억해둠. 프레임이 바뀌면 anchorAtFrame이 무시함
        public static function rememberPosition(frame:Number, recorded:Number):void
        {
            rememberedFrame = frame;
            rememberedRecorded = recorded;
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

        // 지금 그려야 하는 프레임 수. Replay Waiting 중이면 그리지 않고 현재 프레임 수 그대로
        // drawnFrames: 지금까지 그린 프레임 수
        public static function getRemaingFrameCount(drawnFrames:Number, speed:Number):Number
        {
            const recorded:Number = recordedNow(speed);

            // 다음 프레임이 Replay Waiting 공백 뒤에 있으면 공백이 끝날때까지 기다림
            if (drawnFrames < totalFrames && drawnFrames > 0)
            {
                // 앞 프레임의 연출(도구를 쓰던 시간)은 쉬는 시간이 아니라서 연출이 끝난 시각부터 셈
                const gapStart:Number = timeOfFrame(drawnFrames - 1) + animMsOfFrame(drawnFrames - 1);
                const gapEnd:Number = timeOfFrame(drawnFrames);

                if (recorded >= gapStart && gapEnd - gapStart >= ENTRY_MS * speed && recorded < gapEnd)
                {
                    // 공백 시작부터 유지 길이(CAP_MS * 배속)까지만 기다리고 그 뒤는 건너뜀. 중간에서 이어 재생하면 남은 만큼만 기다림
                    replayWaitingEnd = gapEnd;
                    replayWaitingSkipAt = gapStart + CAP_MS * speed;

                    if (recorded < replayWaitingSkipAt)
                    {
                        return drawnFrames;
                    }

                    // 시한이 지나면 자동으로 공백 끝까지 건너뜀
                    anchorRecorded = gapEnd;
                    anchorReal = getTimer();
                    replayWaitingEnd = -1;
                    return Math.max(drawnFrames, framesDueAt(gapEnd));
                }
            }

            replayWaitingEnd = -1;
            return Math.max(drawnFrames, framesDueAt(recorded));
        }

        public static function get isWaitingNextReplayCommand():Boolean
        {
            return replayWaitingEnd >= 0;
        }

        // 자동으로 건너뛰기까지 남은 실제 시간(ms). 공백 처음에서 시작하면 CAP_MS이고, 중간에서 이어 재생하면 그만큼 줄어든 값
        // 테스트 하네스(test-output) 전용. 앱 코드에서 호출하지 않음 (시크바 Replay Waiting 카운트다운 삭제 후 남음)
        public static function replayWaitingRemainingMs(speed:Number):Number
        {
            if (replayWaitingEnd < 0)
            {
                return 0;
            }

            return Math.max(0, (Math.min(replayWaitingSkipAt, replayWaitingEnd) - recordedPeek()) / speed);
        }

        // 시크바 위치(0~1). 프레임 수가 아니라 녹화 시간을 쉬는 구간이 줄어든 축에 놓은 값. frame개를 그린 상태의 위치
        public static function frameRatio(frame:Number):Number
        {
            const length:Number = axisMs;

            if (length <= 0)
            {
                return totalFrames > 0 ? Math.min(1, frame / totalFrames) : 0;
            }

            return Math.min(1, toAxis(timeOfFrame(frame - 1)) / length);
        }

        // 시크바의 위치 ratio(0~1)에 해당하는 녹화 시각 (쉬는 구간의 줄어든 폭 안이면 그 구간 안의 비례한 시각)
        public static function ratioToTime(ratio:Number):Number
        {
            return fromAxis(axisMs * Math.max(0, Math.min(1, ratio)));
        }

        // 시크바의 위치 ratio(0~1)에 해당하는 프레임 수 (시크바 클릭, 드래그)
        public static function ratioToFrame(ratio:Number):Number
        {
            if (ratio >= 1)
            {
                return totalFrames;
            }

            if (axisMs <= 0)
            {
                return Math.floor(totalFrames * Math.max(0, ratio));
            }

            return Math.min(totalFrames, framesDueAt(ratioToTime(ratio)));
        }

        // 재생 중 시크바 위치. 그린 프레임이 아니라 시계가 흐르는 대로 움직여서 쉬는 구간(Replay Waiting)에도 바가 계속 감
        public static function playRatio(speed:Number):Number
        {
            const length:Number = axisMs;
            return length > 0 ? Math.min(1, toAxis(recordedNow(speed)) / length) : 0;
        }

        // 녹화 시각 recorded에서 끝까지 재생하는데 걸리는 예상 실제 시간(ms). 쉬는 구간은 캡 규칙을 적용함
        // 공백 g가 ENTRY_MS * speed 이상이면 앞부분 CAP_MS 실제 시간만(공백 중간에서 시작하면 그 앞부분의 남은 만큼만), 아니면 g / speed
        public static function remainingRealMsAt(recorded:Number, speed:Number):Number
        {
            var current:Number = recorded;
            var real:Number = 0;

            for (var i:int = 0; i < gapRanges.length; i += 2)
            {
                const start:Number = gapRanges[i];
                const end:Number = gapRanges[i + 1];

                if (end <= current)
                {
                    continue;
                }

                if (start > current)
                {
                    real += (start - current) / speed;
                    current = start;
                }

                if ((end - start) >= ENTRY_MS * speed)
                {
                    // 유지 길이(start + CAP_MS * speed)까지 남은 만큼만 기다리고 나머지는 건너뜀
                    real += Math.max(0, Math.min(end, start + CAP_MS * speed) - current) / speed;
                }
                else
                {
                    real += (end - current) / speed;
                }

                current = end;
            }

            return real + Math.max(0, totalTime - current) / speed;
        }

        // frame개를 그린 상태에서의 예상 남은 실제 시간(ms)
        // 테스트 하네스(test-output) 전용. 앱은 remainingRealMsAt를 직접 씀
        public static function remainingRealMs(frame:Number, speed:Number):Number
        {
            return remainingRealMsAt(timeOfFrame(frame - 1), speed);
        }

        // 남은 시간 표시에 쓸 현재 녹화 시각. 재생 중이면 시계 시각(쉬는 구간을 기다리는 동안에도 줄어듬),
        // 멈춰 있으면 기억해둔 위치(같은 프레임일 때) 또는 frame개를 그린 시각
        public static function displayRecorded(frame:Number, playing:Boolean):Number
        {
            if (playing)
            {
                return Math.min(totalTime, recordedPeek());
            }

            if (rememberedFrame === frame && rememberedRecorded >= timeOfFrame(frame - 1))
            {
                return rememberedRecorded;
            }

            return timeOfFrame(frame - 1);
        }

        // frame개를 그린 상태에서 남은 녹화 시간(ms). 표시용
        // 테스트 하네스(test-output) 전용. 앱 코드에서 호출하지 않음
        public static function remainingMsFrom(frame:Number):Number
        {
            return Math.max(0, totalTime - timeOfFrame(frame - 1));
        }
    }
}
