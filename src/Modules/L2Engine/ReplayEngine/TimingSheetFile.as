package Modules.L2Engine.ReplayEngine
{
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.utils.ByteArray;
    import Modules.L1Data.AppContext;
    import Modules.L1Data.AppDataPaths;
    import Modules.L1Data.ReplayEngine.TimingSheet;

    // repdata 파일에 들어있는 프레임(명령)마다의 시간 기록을 이어 쓴 파일
    // 프레임 하나는 uint 둘(8바이트): 직전 프레임과의 간격(ms), 그 명령의 연출 길이(ms, 없으면 0)
    // 프레임 i의 위치는 i * 8 바이트라서 구간만 바로 읽을수 있고, repdata에 묶음을 붙이는 때 같이 붙임
    // .fofo 파일에 저장할때는 TimingSheet로 구간별 압축해서 씀
    // 간격은 첫 프레임이나 시계가 끊긴 직후(앱 재시작, 자르기)의 값이 0
    // 연출 길이는 채우기, 올가미, 이동처럼 도구를 시작해서 끝낼때까지 걸린 시간을 연출로 보여주는 명령에만 있음
    // 그런 명령의 시각(간격의 기준)은 도구를 시작한 시각이고, 연출은 그 시각부터 연출 길이 동안 진행됨
    //
    // 메모리 undo 묶음의 명령별 값(rMemoryDataTimingSheet)은 Number 하나에 합쳐서 가짐
    //   값 = 연출 길이 * 2^32 + getTimer 값(uint로 본 것)
    // 점마다 시각이 필요한 명령(line4)은 [위 Number, [점별 시각 ms]] 배열이 값이 됨 (점 시각은 명령의 시각(도구 시작) 기준)
    // 점별 시각은 프레임 크기가 가변이라 따로 reptimingpoints 파일에 [프레임 번호, 개수, 값...] 레코드로 이어 씀 (프레임 번호 오름차순)
    // 층: L2 엔진 - 프레임마다의 시간 기록을 이어 쓴 파일
    public final class TimingSheetFile
    {
        // 시간 기록이 없는 프레임(옛 파일, 기록이 어긋난 부분)을 시트에 채우는 자리값. 파일 맨 앞 legacyFrames개(옛 구간)의 실제 재생 간격은
        // 이 값이 아니라 ReplayClock이 앱 fps(1000 / stage.frameRate)로 계산함. 그 밖에 채워진 프레임(중간에 채워진 부분)은 채울 때의 앱 fps 간격(ms)이 파일에 그대로 박힘
        public static function get legacyFrameDelta():uint
        {
            return Math.round(1000 / AppContext.stage.frameRate);
        }

        public static const RECORD_BYTES:int = 8;
        private static const TWO_POW_32:Number = 4294967296;
        public static const MAX_ANIM_MS:Number = 2097151; // 합친 값이 Number의 정확한 정수 범위(2^53) 안에 들도록 연출 길이는 2^21 - 1 ms(약 35분)까지

        // 파일 맨 앞에서부터 타이밍 기록이 없는 옛 프레임의 수 L. 시트 구조는 그대로 두고(옛 구간에도 42가 채워져 있음) 시계가 이 구간을 앱 fps로 읽음
        // 바뀌는 순간 reptiminglegacy 파일에 바로 써서 저장 없이 종료해도 시트와 같이 살아남음
        private static var legacyFrameCount:Number = 0;

        // 파일 맨 앞의 타이밍 기록이 없는 옛 프레임 수 (ReplayClock이 이 구간을 앱 fps로 읽음)
        public static function get legacyFrames():Number
        {
            return legacyFrameCount;
        }

        // 옛 프레임 수를 바꾸고 reptiminglegacy 파일에 바로 씀. 값이 같으면 아무것도 안 함
        public static function setLegacyFrames(newLegacyFrameCount:Number):void
        {
            const next:Number = Math.max(0, newLegacyFrameCount);

            if (next === legacyFrameCount)
            {
                return;
            }

            legacyFrameCount = next;
            writeLegacyFrameCountFile();
        }

        private static function writeLegacyFrameCountFile():void
        {
            const file:File = AppDataPaths.replayTimingLegacyFilePath;

            if (file === null)
            {
                return; // 경로 없이 쓰는 단위 시험
            }

            if (legacyFrameCount === 0)
            {
                if (file.exists)
                {
                    file.deleteFile();
                }

                return;
            }

            const fs:FileStream = new FileStream();
            fs.open(file, FileMode.WRITE);
            fs.writeDouble(legacyFrameCount);
            fs.close();
        }

        // 앱 시작 때 읽음. 파일이 없으면 0, 파일 프레임 수보다 크면(fileFrameCount > 0일 때만 판단) 줄이고 로그
        public static function loadLegacyFrameCountFromFile(fileFrameCount:Number):void
        {
            legacyFrameCount = 0;
            const file:File = AppDataPaths.replayTimingLegacyFilePath;

            if (file === null || !file.exists)
            {
                return;
            }

            try
            {
                const fs:FileStream = new FileStream();
                fs.open(file, FileMode.READ);
                legacyFrameCount = Math.max(0, fs.readDouble());
                fs.close();
            }
            catch (error:Error)
            {
                legacyFrameCount = 0;
                trace("[TimingSheetFile] 옛 프레임 수 읽기 실패, 0으로 둠: " + error);
                return;
            }

            if (fileFrameCount > 0 && legacyFrameCount > fileFrameCount)
            {
                trace("[TimingSheetFile] 옛 프레임 수(" + legacyFrameCount + ")가 파일 프레임 수(" + fileFrameCount + ")보다 커서 줄임");
                legacyFrameCount = fileFrameCount;
                writeLegacyFrameCountFile();
            }
        }

        private static var lastWrittenTimerStamp:int = 0; // 마지막으로 파일에 쓴 프레임의 getTimer 값
        private static var hasLastWrittenTimerStamp:Boolean = false;

        // 연출 길이를 getTimer 값과 합쳐서 메모리 기록 한 칸으로 만듬. animLengthMs가 0이면 getTimer 값만 있는 것과 같음
        public static function packTimeAndAnimMs(timerStamp:int, animLengthMs:Number):Number
        {
            const clamped:Number = Math.max(0, Math.min(MAX_ANIM_MS, Math.floor(animLengthMs)));
            return clamped * TWO_POW_32 + uint(timerStamp);
        }

        // 아래 unpack 함수들은 메모리 기록 한 칸(Number, 또는 점별 시각이 붙은 [Number, Array])을 그대로 받음
        // 메모리 기록 한 칸에서 합친 Number를 꺼냄 (점별 시각이 붙은 배열이면 앞 항목)
        private static function getPackedNumber(element:*):Number
        {
            return (element is Array) ? element[0] : element;
        }

        // 메모리 기록 한 칸에서 getTimer 값(int)을 꺼냄
        public static function unpackTimerStamp(element:*):int
        {
            return int(uint(getPackedNumber(element) % TWO_POW_32));
        }

        // 메모리 기록 한 칸에서 연출 길이(ms)를 꺼냄
        public static function unpackAnimLengthMs(element:*):Number
        {
            return Math.floor(getPackedNumber(element) / TWO_POW_32);
        }

        // 점별 시각(도구 시작 기준 ms)이 붙어 있으면 그 배열, 아니면 null
        public static function getPointTimesOf(element:*):Array
        {
            return (element is Array) ? element[1] : null;
        }

        // 메모리 기록 한 칸을 만듬. points가 없으면 Number 그대로
        public static function makeTimingElement(timerStamp:int, animLengthMs:Number, pointTimes:Array):*
        {
            const packed:Number = packTimeAndAnimMs(timerStamp, animLengthMs);
            return (pointTimes !== null && pointTimes.length > 0) ? [packed, pointTimes] : packed;
        }

        // 기록 한 칸의 getTimer 값을 offset만큼 옮긴 새 칸 (앱을 다시 켜서 getTimer 기준이 바뀔때)
        public static function shiftTimingElementTime(element:*, timerStampOffset:int):*
        {
            return makeTimingElement((unpackTimerStamp(element) + timerStampOffset) | 0, unpackAnimLengthMs(element), getPointTimesOf(element));
        }

        // 파일이 없으면 만들지 않고 비어있는 것으로 봄
        // 시트 파일에 기록된 프레임 수 (파일 크기 / RECORD_BYTES)
        public static function get sheetFrameCount():Number
        {
            const file:File = AppDataPaths.replayTimingSheetFilePath;
            return file.exists ? Math.floor(file.size / RECORD_BYTES) : 0;
        }

        public static function resetTimingSheet():void
        {
            const fs:FileStream = new FileStream();
            fs.open(AppDataPaths.replayTimingSheetFilePath, FileMode.WRITE);
            fs.close();
            fs.open(AppDataPaths.replayTimingPointsFilePath, FileMode.WRITE);
            fs.close();
            hasLastWrittenTimerStamp = false;
            setLegacyFrames(0);
            ReplayClock.resetFileIndexToEmpty(); // 시트를 비웠으니 시간 색인도 빈 상태가 정확함
        }

        // 마지막 프레임의 시각을 잊게 해서 다음 프레임의 간격을 0으로 만듬 (시계가 끊긴 직후)
        public static function forgetLastFrameTime():void
        {
            hasLastWrittenTimerStamp = false;
        }

        // 파일에 마지막으로 쓴 프레임의 getTimer 값을 {has, stamp}로 돌려줌 (앱 상태 저장용)
        public static function getLastFrameTime():Object
        {
            return {has: hasLastWrittenTimerStamp, stamp: lastWrittenTimerStamp};
        }

        // getLastFrameTime으로 저장해 둔 값을 되돌림
        public static function setLastFrameTime(hasStamp:Boolean, timerStamp:int):void
        {
            hasLastWrittenTimerStamp = hasStamp;
            lastWrittenTimerStamp = timerStamp;
        }

        // 파일이 targetFrameCount개의 프레임만 가지도록 모자라면 legacyFrameDelta로 채우고 남으면 자름
        // repdata와 길이가 어긋난 채로 이어 붙이지 않게 붙이기 직전에 부름
        public static function resizeSheetToFrameCount(targetFrameCount:Number):void
        {
            const currentFrameCount:Number = sheetFrameCount;
            if (currentFrameCount === targetFrameCount)
            {
                return;
            }

            const file:File = AppDataPaths.replayTimingSheetFilePath;
            const fs:FileStream = new FileStream();
            if (currentFrameCount > targetFrameCount)
            {
                fs.open(file, FileMode.UPDATE);
                fs.position = targetFrameCount * RECORD_BYTES;
                fs.truncate();
                fs.close();
                rewritePointTimesRecords(0, targetFrameCount, 0);
                setLegacyFrames(Math.min(legacyFrameCount, targetFrameCount));
                return;
            }

            fs.open(file, FileMode.APPEND);
            const fillDelta:uint = legacyFrameDelta;

            for (var i:Number = currentFrameCount; i < targetFrameCount; i++)
            {
                fs.writeUnsignedInt(fillDelta);
                fs.writeUnsignedInt(0);
            }

            fs.close();
        }

        // 묶음 하나의 명령들의 기록(packTimeAndAnimMs 값)을 간격과 연출 길이로 바꿔서 이어 붙임. 앞 프레임까지 길이를 맞춘 다음에 씀
        // 쓴 [간격, 연출 길이] 쌍을 이어붙인 목록을 돌려줌 (시계 색인이 파일을 다시 읽지 않고 반영하도록)
        public static function appendGroupTimesAtFrame(timingElements:Array, firstFrame:Number):Vector.<uint>
        {
            resizeSheetToFrameCount(firstFrame);
            const writtenRecords:Vector.<uint> = new Vector.<uint>(timingElements.length * 2, true);

            const fs:FileStream = new FileStream();
            fs.open(AppDataPaths.replayTimingSheetFilePath, FileMode.APPEND);

            for (var i:int = 0; i < timingElements.length; i++)
            {
                const stamp:int = unpackTimerStamp(timingElements[i]);
                var delta:int = 0;

                if (hasLastWrittenTimerStamp)
                {
                    delta = (stamp - lastWrittenTimerStamp) | 0; // 값이 넘쳐도 차이는 맞게 나옴

                    if (delta < 0)
                    {
                        delta = 0;
                    }
                }

                writtenRecords[i * 2] = uint(delta);
                writtenRecords[i * 2 + 1] = uint(unpackAnimLengthMs(timingElements[i]));
                fs.writeUnsignedInt(writtenRecords[i * 2]);
                fs.writeUnsignedInt(writtenRecords[i * 2 + 1]);
                lastWrittenTimerStamp = stamp;
                hasLastWrittenTimerStamp = true;
            }

            fs.close();

            for (i = 0; i < timingElements.length; i++)
            {
                const points:Array = getPointTimesOf(timingElements[i]);

                if (points !== null)
                {
                    appendPointTimesRecord(firstFrame + i, points);
                }
            }

            return writtenRecords;
        }

        // keepFrameCount개 이후를 자름 (뒤 자르기)
        public static function deleteSheetAfterFrame(keepFrameCount:Number):void
        {
            if (sheetFrameCount > keepFrameCount)
            {
                resizeSheetToFrameCount(keepFrameCount);
            }

            hasLastWrittenTimerStamp = false;
        }

        // 앞의 cutFrameCount개를 자르고 남은 첫 프레임의 간격을 0으로 함 (앞 자르기)
        public static function deleteSheetBeforeFrame(cutFrameCount:Number):void
        {
            const file:File = AppDataPaths.replayTimingSheetFilePath;
            hasLastWrittenTimerStamp = false;

            if (cutFrameCount <= 0)
            {
                return;
            }

            if (sheetFrameCount <= cutFrameCount)
            {
                resetTimingSheet();
                return;
            }

            rewritePointTimesRecords(cutFrameCount, Number.MAX_VALUE, -cutFrameCount);

            const fs:FileStream = new FileStream();
            const restBytes:ByteArray = new ByteArray();
            fs.open(file, FileMode.READ);
            fs.position = cutFrameCount * RECORD_BYTES;
            fs.readBytes(restBytes, 0, fs.bytesAvailable);
            fs.close();

            restBytes.position = 0;
            restBytes.writeUnsignedInt(0);

            fs.open(file, FileMode.WRITE);
            fs.writeBytes(restBytes, 0, restBytes.length);
            fs.close();
            setLegacyFrames(Math.max(0, legacyFrameCount - cutFrameCount));
            ReplayClock.resetFileIndexToEmpty();
            ReplayClock.appendSheetBytesToFileIndex(restBytes); // 다시 쓴 내용으로 시간 색인도 같이 만듦 (파일을 다시 읽지 않음)
            restBytes.clear();
        }

        // 점별 시각 레코드 하나를 파일 끝에 이어 붙임
        private static function appendPointTimesRecord(commandFrame:Number, pointTimes:Array):void
        {
            const fs:FileStream = new FileStream();
            fs.open(AppDataPaths.replayTimingPointsFilePath, FileMode.APPEND);
            fs.writeUnsignedInt(uint(commandFrame));
            fs.writeUnsignedInt(uint(pointTimes.length));

            for (var i:int = 0; i < pointTimes.length; i++)
            {
                fs.writeUnsignedInt(uint(pointTimes[i]));
            }

            fs.close();
        }

        // 점별 시각 파일에서 프레임 번호가 [minFrame, maxFrame)인 레코드만 남기고 번호를 shift만큼 옮겨서 다시 씀 (자르기)
        private static function rewritePointTimesRecords(minFrame:Number, maxFrame:Number, frameShift:Number):void
        {
            const file:File = AppDataPaths.replayTimingPointsFilePath;

            if (!file.exists || file.size === 0)
            {
                return;
            }

            const fs:FileStream = new FileStream();
            const keptRecordBytes:ByteArray = new ByteArray();
            fs.open(file, FileMode.READ);

            while (fs.bytesAvailable >= 8)
            {
                const frame:uint = fs.readUnsignedInt();
                const count:uint = fs.readUnsignedInt();

                if (fs.bytesAvailable < count * 4)
                {
                    break; // 끝이 잘린 레코드는 버림
                }

                const keep:Boolean = frame >= minFrame && frame < maxFrame;

                if (keep)
                {
                    keptRecordBytes.writeUnsignedInt(uint(frame + frameShift));
                    keptRecordBytes.writeUnsignedInt(count);
                }

                for (var i:uint = 0; i < count; i++)
                {
                    const value:uint = fs.readUnsignedInt();

                    if (keep)
                    {
                        keptRecordBytes.writeUnsignedInt(value);
                    }
                }
            }

            fs.close();
            fs.open(file, FileMode.WRITE);
            fs.writeBytes(keptRecordBytes, 0, keptRecordBytes.length);
            fs.close();
            keptRecordBytes.clear();
        }

        // 프레임 frame의 점별 시각(도구 시작 기준 ms). 없으면 null. 파일을 앞에서부터 읽으며 찾음 (레코드는 프레임 번호 오름차순)
        public static function readPointTimes(commandFrame:Number):Vector.<uint>
        {
            const file:File = AppDataPaths.replayTimingPointsFilePath;

            if (!file.exists || file.size === 0)
            {
                return null;
            }

            const fs:FileStream = new FileStream();
            fs.open(file, FileMode.READ);
            var result:Vector.<uint> = null;

            while (fs.bytesAvailable >= 8)
            {
                const recordFrame:uint = fs.readUnsignedInt();
                const count:uint = fs.readUnsignedInt();

                if (recordFrame > commandFrame || fs.bytesAvailable < count * 4)
                {
                    break;
                }

                if (recordFrame === commandFrame)
                {
                    result = new Vector.<uint>(count, true);

                    for (var i:uint = 0; i < count; i++)
                    {
                        result[i] = fs.readUnsignedInt();
                    }

                    break;
                }

                fs.position += count * 4;
            }

            fs.close();
            return result;
        }

        // 간격과 연출 길이를 파일 끝에 이어 붙임 (.fofo에서 불러올때 씀)
        public static function appendFrameRecords(deltaMsList:Vector.<uint>, animLengthList:Vector.<uint>):void
        {
            const fs:FileStream = new FileStream();
            fs.open(AppDataPaths.replayTimingSheetFilePath, FileMode.APPEND);

            for (var i:int = 0; i < deltaMsList.length; i++)
            {
                fs.writeUnsignedInt(deltaMsList[i]);
                fs.writeUnsignedInt(animLengthList[i]);
            }

            fs.close();
        }

        // 메모리 undo 묶음(앞 groupCount개)의 기록을 간격과 연출 길이로 바꿈. 첫 프레임은 파일에 마지막으로 쓴 프레임과 이어서 구함
        // deltaMsList, anims는 비어있는 Vector를 받아서 채움
        public static function makeMemoryFrameRecords(memoryTimingElementGroups:Array, memoryGroupCount:int, deltaMsList:Vector.<uint>, animLengthList:Vector.<uint>):void
        {
            var previousTimerStamp:int = lastWrittenTimerStamp;
            var hasPreviousTimerStamp:Boolean = hasLastWrittenTimerStamp;

            for (var g:int = 0; g < memoryGroupCount; g++)
            {
                const group:Array = memoryTimingElementGroups[g];

                for (var i:int = 0; i < group.length; i++)
                {
                    const stamp:int = unpackTimerStamp(group[i]);
                    var delta:int = 0;

                    if (hasPreviousTimerStamp)
                    {
                        delta = (stamp - previousTimerStamp) | 0;

                        if (delta < 0)
                        {
                            delta = 0;
                        }
                    }

                    deltaMsList.push(uint(delta));
                    animLengthList.push(uint(unpackAnimLengthMs(group[i])));
                    previousTimerStamp = stamp;
                    hasPreviousTimerStamp = true;
                }
            }
        }

        // .fofo 파일 끝에 쓰는 ["rTimingSheet", 버전, 프레임 수, 구간 프레임 수, [구간별 압축 데이터]] 객체를 만듬
        // 앞쪽 fileFrames개는 파일에서 읽고, 그 뒤는 메모리 undo 묶음(memoryStamps의 앞 memoryGroupCount개)의 기록에서 계산함
        // 메모리 묶음 첫 프레임의 간격은 파일 마지막 프레임과 이어서 구하고, extraFrames는 끝에 간격 0으로 덧붙이는 프레임 수
        // 구간 하나씩만 풀어서 압축하니 전체를 한번에 메모리에 올리지 않음
        public static function makeSheetFileObject(fileFrameCount:Number, memoryTimingElementGroups:Array, memoryGroupCount:int, extraFrameCount:int):Array
        {
            const memoryDeltas:Vector.<uint> = new Vector.<uint>();
            const memoryAnims:Vector.<uint> = new Vector.<uint>();
            makeMemoryFrameRecords(memoryTimingElementGroups, memoryGroupCount, memoryDeltas, memoryAnims);

            for (var i:int = 0; i < extraFrameCount; i++)
            {
                memoryDeltas.push(0);
                memoryAnims.push(0);
            }

            const totalFrameCount:Number = fileFrameCount + memoryDeltas.length;
            const blobs:Array = [];

            for (var segmentFirstFrame:Number = 0; segmentFirstFrame < totalFrameCount; segmentFirstFrame += TimingSheet.SEGMENT_FRAMES)
            {
                const segmentFrameCount:int = int(Math.min(TimingSheet.SEGMENT_FRAMES, totalFrameCount - segmentFirstFrame));
                const deltaMsList:Vector.<uint> = new Vector.<uint>(segmentFrameCount, true);
                const animLengthList:Vector.<uint> = new Vector.<uint>(segmentFrameCount, true);
                const fileFrameCountInSegment:int = int(Math.max(0, Math.min(segmentFrameCount, fileFrameCount - segmentFirstFrame)));

                if (fileFrameCountInSegment > 0)
                {
                    readFrameRecords(segmentFirstFrame, fileFrameCountInSegment, deltaMsList, animLengthList);
                }

                for (i = fileFrameCountInSegment; i < segmentFrameCount; i++)
                {
                    deltaMsList[i] = memoryDeltas[int(segmentFirstFrame + i - fileFrameCount)];
                    animLengthList[i] = memoryAnims[int(segmentFirstFrame + i - fileFrameCount)];
                }

                blobs.push(TimingSheet.encodeSegmentDeltasAndAnimsToBlob(deltaMsList, animLengthList, segmentFrameCount));
            }

            // 뒤에 선택 항목으로 옛 프레임 수 L (버전은 그대로 2라 옛 앱은 무시하고 채워진 42ms로 재생)
            return ["rTimingSheet", 2, totalFrameCount, TimingSheet.SEGMENT_FRAMES, blobs, makePointTimesBlob(fileFrameCount, memoryTimingElementGroups, memoryGroupCount), Math.min(legacyFrameCount, fileFrameCount)];
        }

        // 점별 시각 레코드를 압축한 데이터. 파일 부분(프레임 번호 < fileFrameCount)은 파일에서 그대로 옮기고, 메모리 묶음은 그 뒤 번호로 붙임. 없으면 null
        private static function makePointTimesBlob(fileFrameCount:Number, memoryTimingElementGroups:Array, memoryGroupCount:int):ByteArray
        {
            const pointTimesBytes:ByteArray = new ByteArray();
            const file:File = AppDataPaths.replayTimingPointsFilePath;

            if (file.exists && file.size > 0)
            {
                const fs:FileStream = new FileStream();
                fs.open(file, FileMode.READ);

                while (fs.bytesAvailable >= 8)
                {
                    const frame:uint = fs.readUnsignedInt();
                    const count:uint = fs.readUnsignedInt();

                    if (fs.bytesAvailable < count * 4)
                    {
                        break;
                    }

                    const keep:Boolean = frame < fileFrameCount;

                    if (keep)
                    {
                        pointTimesBytes.writeUnsignedInt(frame);
                        pointTimesBytes.writeUnsignedInt(count);
                    }

                    for (var i:uint = 0; i < count; i++)
                    {
                        const value:uint = fs.readUnsignedInt();

                        if (keep)
                        {
                            pointTimesBytes.writeUnsignedInt(value);
                        }
                    }
                }

                fs.close();
            }

            var position:Number = fileFrameCount;

            for (var g:int = 0; g < memoryGroupCount; g++)
            {
                const group:Array = memoryTimingElementGroups[g];

                for (var j:int = 0; j < group.length; j++)
                {
                    const points:Array = getPointTimesOf(group[j]);

                    if (points !== null)
                    {
                        pointTimesBytes.writeUnsignedInt(uint(position));
                        pointTimesBytes.writeUnsignedInt(uint(points.length));

                        for (var k:int = 0; k < points.length; k++)
                        {
                            pointTimesBytes.writeUnsignedInt(uint(points[k]));
                        }
                    }

                    position++;
                }
            }

            if (pointTimesBytes.length === 0)
            {
                return null;
            }

            pointTimesBytes.compress();
            return pointTimesBytes;
        }

        // makeSheetFileObject로 만든 객체를 읽어서 파일 내용으로 되돌림. 모양이 틀리거나 풀 수 없으면 비워두고 false
        public static function loadSheetFileObject(sheetFileObject:Array):Boolean
        {
            resetTimingSheet();

            try
            {
                if (sheetFileObject[1] !== 2 || !(sheetFileObject[2] is Number) || sheetFileObject[3] !== TimingSheet.SEGMENT_FRAMES || !(sheetFileObject[4] is Array))
                {
                    return false;
                }

                const blobs:Array = sheetFileObject[4];
                var remainingFrameCount:Number = sheetFileObject[2];

                // 옛 프레임 수 L (선택 항목). 범위 밖이면 0. 색인을 만들기 전에 정해야 옛 구간 간격으로 계산됨
                setLegacyFrames((sheetFileObject.length > 6 && sheetFileObject[6] is Number && sheetFileObject[6] >= 0 && sheetFileObject[6] <= sheetFileObject[2]) ? sheetFileObject[6] : 0);
                ReplayClock.resetFileIndexToEmpty();

                for (var s:int = 0; s < blobs.length; s++)
                {
                    const segmentFrameCount:int = int(Math.min(TimingSheet.SEGMENT_FRAMES, remainingFrameCount));
                    const deltaMsList:Vector.<uint> = new Vector.<uint>(segmentFrameCount, true);
                    const animLengthList:Vector.<uint> = new Vector.<uint>(segmentFrameCount, true);
                    TimingSheet.decodeSegmentBlobToDeltasAndAnims(blobs[s] as ByteArray, segmentFrameCount, deltaMsList, animLengthList);
                    const segmentFirstFrame:Number = sheetFileObject[2] - remainingFrameCount;
                    appendFrameRecords(deltaMsList, animLengthList);
                    remainingFrameCount -= segmentFrameCount;
                    addSegmentToClockIndex(deltaMsList, animLengthList, segmentFirstFrame);
                }

                if (remainingFrameCount !== 0)
                {
                    resetTimingSheet();
                    return false;
                }

                // 점별 시각은 없을 수도 있음. 풀 수 없으면 점 시각만 포기하고 나머지는 그대로 씀
                if (sheetFileObject.length > 5 && sheetFileObject[5] is ByteArray)
                {
                    try
                    {
                        const points:ByteArray = new ByteArray();
                        points.writeBytes(sheetFileObject[5] as ByteArray, 0, (sheetFileObject[5] as ByteArray).length);
                        points.uncompress();
                        const pfs:FileStream = new FileStream();
                        pfs.open(AppDataPaths.replayTimingPointsFilePath, FileMode.WRITE);
                        pfs.writeBytes(points, 0, points.length);
                        pfs.close();
                        points.clear();
                    }
                    catch (pointsError:Error)
                    {
                        trace("Timing points load failed: " + pointsError);
                    }
                }
            }
            catch (error:Error)
            {
                trace("Timing sheet load failed: " + error);
                resetTimingSheet();
                return false;
            }

            return true;
        }

        // 불러오며 풀어 쓴 구간을 시계 색인에도 바로 반영 (시트를 다시 읽지 않음)
        // 풀어 쓴 구간 하나의 간격과 연출 길이를 시계 색인에 이어 붙임
        private static function addSegmentToClockIndex(deltaMsList:Vector.<uint>, animLengthList:Vector.<uint>, firstFrame:Number):void
        {
            const records:Vector.<uint> = new Vector.<uint>(deltaMsList.length * 2, true);

            for (var i:int = 0; i < deltaMsList.length; i++)
            {
                records[i * 2] = deltaMsList[i];
                records[i * 2 + 1] = animLengthList[i];
            }

            ReplayClock.appendRecordsToFileIndex(records, firstFrame);
        }

        // firstFrame부터 count개의 간격과 연출 길이를 읽어서 deltaMsList, animLengthList(둘다 frameCount 이상)에 채움. 파일에 모자란 부분은 0
        public static function readFrameRecords(firstFrame:Number, frameCount:int, deltaMsList:Vector.<uint>, animLengthList:Vector.<uint> = null):void
        {
            const file:File = AppDataPaths.replayTimingSheetFilePath;

            if (!file.exists)
            {
                return;
            }

            const available:Number = Math.max(0, Math.min(frameCount, sheetFrameCount - firstFrame));

            if (available === 0)
            {
                return;
            }

            const fs:FileStream = new FileStream();
            fs.open(file, FileMode.READ);
            fs.position = firstFrame * RECORD_BYTES;

            for (var i:int = 0; i < available; i++)
            {
                deltaMsList[i] = fs.readUnsignedInt();
                const anim:uint = fs.readUnsignedInt();

                if (animLengthList !== null)
                {
                    animLengthList[i] = anim;
                }
            }

            fs.close();
        }
    }
}
