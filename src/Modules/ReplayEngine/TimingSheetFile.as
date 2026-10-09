package Modules.ReplayEngine
{
    import Modules.AppStateManager;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.utils.ByteArray;

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
        // 이 값이 아니라 ReplayClock이 앱 fps(1000 / stage.frameRate)로 계산함. 그 밖에 채워진 프레임(중간에 채워진 부분)은 이 값 그대로 42ms
        public static const LEGACY_FRAME_DELTA:uint = 42;
        public static const RECORD_BYTES:int = 8;
        private static const TWO_POW_32:Number = 4294967296;
        public static const MAX_ANIM_MS:Number = 2097151; // 합친 값이 Number의 정확한 정수 범위(2^53) 안에 들도록 연출 길이는 2^21 - 1 ms(약 35분)까지

        // 파일 맨 앞에서부터 타이밍 기록이 없는 옛 프레임의 수 L. 시트 구조는 그대로 두고(옛 구간에도 42가 채워져 있음) 시계가 이 구간을 앱 fps로 읽음
        // 바뀌는 순간 reptiminglegacy 파일에 바로 써서 저장 없이 종료해도 시트와 같이 살아남음
        private static var legacyCount:Number = 0;

        public static function get legacyFrames():Number
        {
            return legacyCount;
        }

        public static function setLegacyFrames(count:Number):void
        {
            const next:Number = Math.max(0, count);

            if (next === legacyCount)
            {
                return;
            }

            legacyCount = next;
            writeLegacyFile();
        }

        private static function writeLegacyFile():void
        {
            const file:File = AppStateManager.replayTimingLegacyFilePath;

            if (file === null)
            {
                return; // 경로 없이 쓰는 단위 시험
            }

            if (legacyCount === 0)
            {
                if (file.exists)
                {
                    file.deleteFile();
                }

                return;
            }

            const fs:FileStream = new FileStream();
            fs.open(file, FileMode.WRITE);
            fs.writeDouble(legacyCount);
            fs.close();
        }

        // 앱 시작 때 읽음. 파일이 없으면 0, 파일 프레임 수보다 크면(frames > 0일 때만 판단) 줄이고 로그
        public static function loadLegacy(frames:Number):void
        {
            legacyCount = 0;
            const file:File = AppStateManager.replayTimingLegacyFilePath;

            if (file === null || !file.exists)
            {
                return;
            }

            try
            {
                const fs:FileStream = new FileStream();
                fs.open(file, FileMode.READ);
                legacyCount = Math.max(0, fs.readDouble());
                fs.close();
            }
            catch (error:Error)
            {
                legacyCount = 0;
                trace("[TimingSheetFile] 옛 프레임 수 읽기 실패, 0으로 둠: " + error);
                return;
            }

            if (frames > 0 && legacyCount > frames)
            {
                trace("[TimingSheetFile] 옛 프레임 수(" + legacyCount + ")가 파일 프레임 수(" + frames + ")보다 커서 줄임");
                legacyCount = frames;
                writeLegacyFile();
            }
        }

        private static var lastStamp:int = 0; // 마지막으로 파일에 쓴 프레임의 getTimer 값
        private static var hasLastStamp:Boolean = false;

        // 연출 길이를 getTimer 값과 합쳐서 메모리 기록 한 칸으로 만듬. animMs가 0이면 getTimer 값만 있는 것과 같음
        public static function packStamp(stamp:int, animMs:Number):Number
        {
            const clamped:Number = Math.max(0, Math.min(MAX_ANIM_MS, Math.floor(animMs)));
            return clamped * TWO_POW_32 + uint(stamp);
        }

        // 아래 unpack 함수들은 메모리 기록 한 칸(Number, 또는 점별 시각이 붙은 [Number, Array])을 그대로 받음
        private static function packedOf(element:*):Number
        {
            return (element is Array) ? element[0] : element;
        }

        public static function unpackStamp(element:*):int
        {
            return int(uint(packedOf(element) % TWO_POW_32));
        }

        public static function unpackAnimMs(element:*):Number
        {
            return Math.floor(packedOf(element) / TWO_POW_32);
        }

        // 점별 시각(도구 시작 기준 ms)이 붙어 있으면 그 배열, 아니면 null
        public static function pointsOf(element:*):Array
        {
            return (element is Array) ? element[1] : null;
        }

        // 메모리 기록 한 칸을 만듬. points가 없으면 Number 그대로
        public static function makeElement(stamp:int, animMs:Number, points:Array):*
        {
            const packed:Number = packStamp(stamp, animMs);
            return (points !== null && points.length > 0) ? [packed, points] : packed;
        }

        // 기록 한 칸의 getTimer 값을 offset만큼 옮긴 새 칸 (앱을 다시 켜서 getTimer 기준이 바뀔때)
        public static function shiftElement(element:*, offset:int):*
        {
            return makeElement((unpackStamp(element) + offset) | 0, unpackAnimMs(element), pointsOf(element));
        }

        // 파일이 없으면 만들지 않고 비어있는 것으로 봄
        public static function get frameCount():Number
        {
            const file:File = AppStateManager.replayTimingSheetFilePath;
            return file.exists ? Math.floor(file.size / RECORD_BYTES) : 0;
        }

        public static function reset():void
        {
            const fs:FileStream = new FileStream();
            fs.open(AppStateManager.replayTimingSheetFilePath, FileMode.WRITE);
            fs.close();
            fs.open(AppStateManager.replayTimingPointsFilePath, FileMode.WRITE);
            fs.close();
            hasLastStamp = false;
            setLegacyFrames(0);
            ReplayClock.resetIndexEmpty(); // 시트를 비웠으니 시간 색인도 빈 상태가 정확함
        }

        // 마지막 프레임의 시각을 잊게 해서 다음 프레임의 간격을 0으로 만듬 (시계가 끊긴 직후)
        public static function breakClock():void
        {
            hasLastStamp = false;
        }

        public static function getLastStamp():Object
        {
            return {has: hasLastStamp, stamp: lastStamp};
        }

        public static function setLastStamp(has:Boolean, stamp:int):void
        {
            hasLastStamp = has;
            lastStamp = stamp;
        }

        // 파일이 frame개의 프레임만 가지도록 모자라면 LEGACY_FRAME_DELTA로 채우고 남으면 자름
        // repdata와 길이가 어긋난 채로 이어 붙이지 않게 붙이기 직전에 부름
        public static function resizeToFrameCount(frame:Number):void
        {
            const now:Number = frameCount;
            if (now === frame)
            {
                return;
            }

            const file:File = AppStateManager.replayTimingSheetFilePath;
            const fs:FileStream = new FileStream();
            if (now > frame)
            {
                fs.open(file, FileMode.UPDATE);
                fs.position = frame * RECORD_BYTES;
                fs.truncate();
                fs.close();
                rewritePoints(0, frame, 0);
                setLegacyFrames(Math.min(legacyCount, frame));
                return;
            }

            fs.open(file, FileMode.APPEND);

            for (var i:Number = now; i < frame; i++)
            {
                fs.writeUnsignedInt(LEGACY_FRAME_DELTA);
                fs.writeUnsignedInt(0);
            }

            fs.close();
        }

        // 묶음 하나의 명령들의 기록(packStamp 값)을 간격과 연출 길이로 바꿔서 이어 붙임. 앞 프레임까지 길이를 맞춘 다음에 씀
        // 쓴 [간격, 연출 길이] 쌍을 이어붙인 목록을 돌려줌 (시계 색인이 파일을 다시 읽지 않고 반영하도록)
        public static function appendGroupAtFrame(stamps:Array, firstFrame:Number):Vector.<uint>
        {
            resizeToFrameCount(firstFrame);
            const written:Vector.<uint> = new Vector.<uint>(stamps.length * 2, true);

            const fs:FileStream = new FileStream();
            fs.open(AppStateManager.replayTimingSheetFilePath, FileMode.APPEND);

            for (var i:int = 0; i < stamps.length; i++)
            {
                const stamp:int = unpackStamp(stamps[i]);
                var delta:int = 0;

                if (hasLastStamp)
                {
                    delta = (stamp - lastStamp) | 0; // 값이 넘쳐도 차이는 맞게 나옴

                    if (delta < 0)
                    {
                        delta = 0;
                    }
                }

                written[i * 2] = uint(delta);
                written[i * 2 + 1] = uint(unpackAnimMs(stamps[i]));
                fs.writeUnsignedInt(written[i * 2]);
                fs.writeUnsignedInt(written[i * 2 + 1]);
                lastStamp = stamp;
                hasLastStamp = true;
            }

            fs.close();

            for (i = 0; i < stamps.length; i++)
            {
                const points:Array = pointsOf(stamps[i]);

                if (points !== null)
                {
                    appendPointsRecord(firstFrame + i, points);
                }
            }

            return written;
        }

        // frame개 이후를 자름 (뒤 자르기)
        public static function truncateAfter(frame:Number):void
        {
            if (frameCount > frame)
            {
                resizeToFrameCount(frame);
            }

            hasLastStamp = false;
        }

        // 앞의 frame개를 자르고 남은 첫 프레임의 간격을 0으로 함 (앞 자르기)
        public static function cutBefore(frame:Number):void
        {
            const file:File = AppStateManager.replayTimingSheetFilePath;
            hasLastStamp = false;

            if (frame <= 0)
            {
                return;
            }

            if (frameCount <= frame)
            {
                reset();
                return;
            }

            rewritePoints(frame, Number.MAX_VALUE, -frame);

            const fs:FileStream = new FileStream();
            const rest:ByteArray = new ByteArray();
            fs.open(file, FileMode.READ);
            fs.position = frame * RECORD_BYTES;
            fs.readBytes(rest, 0, fs.bytesAvailable);
            fs.close();

            rest.position = 0;
            rest.writeUnsignedInt(0);

            fs.open(file, FileMode.WRITE);
            fs.writeBytes(rest, 0, rest.length);
            fs.close();
            setLegacyFrames(Math.max(0, legacyCount - frame));
            ReplayClock.resetIndexEmpty();
            ReplayClock.indexBytes(rest); // 다시 쓴 내용으로 시간 색인도 같이 만듦 (파일을 다시 읽지 않음)
            rest.clear();
        }

        // 점별 시각 레코드 하나를 파일 끝에 이어 붙임
        private static function appendPointsRecord(frame:Number, points:Array):void
        {
            const fs:FileStream = new FileStream();
            fs.open(AppStateManager.replayTimingPointsFilePath, FileMode.APPEND);
            fs.writeUnsignedInt(uint(frame));
            fs.writeUnsignedInt(uint(points.length));

            for (var i:int = 0; i < points.length; i++)
            {
                fs.writeUnsignedInt(uint(points[i]));
            }

            fs.close();
        }

        // 점별 시각 파일에서 프레임 번호가 [minFrame, maxFrame)인 레코드만 남기고 번호를 shift만큼 옮겨서 다시 씀 (자르기)
        private static function rewritePoints(minFrame:Number, maxFrame:Number, shift:Number):void
        {
            const file:File = AppStateManager.replayTimingPointsFilePath;

            if (!file.exists || file.size === 0)
            {
                return;
            }

            const fs:FileStream = new FileStream();
            const kept:ByteArray = new ByteArray();
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
                    kept.writeUnsignedInt(uint(frame + shift));
                    kept.writeUnsignedInt(count);
                }

                for (var i:uint = 0; i < count; i++)
                {
                    const value:uint = fs.readUnsignedInt();

                    if (keep)
                    {
                        kept.writeUnsignedInt(value);
                    }
                }
            }

            fs.close();
            fs.open(file, FileMode.WRITE);
            fs.writeBytes(kept, 0, kept.length);
            fs.close();
            kept.clear();
        }

        // 프레임 frame의 점별 시각(도구 시작 기준 ms). 없으면 null. 파일을 앞에서부터 읽으며 찾음 (레코드는 프레임 번호 오름차순)
        public static function readPoints(frame:Number):Vector.<uint>
        {
            const file:File = AppStateManager.replayTimingPointsFilePath;

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

                if (recordFrame > frame || fs.bytesAvailable < count * 4)
                {
                    break;
                }

                if (recordFrame === frame)
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
        public static function appendRecords(deltas:Vector.<uint>, anims:Vector.<uint>):void
        {
            const fs:FileStream = new FileStream();
            fs.open(AppStateManager.replayTimingSheetFilePath, FileMode.APPEND);

            for (var i:int = 0; i < deltas.length; i++)
            {
                fs.writeUnsignedInt(deltas[i]);
                fs.writeUnsignedInt(anims[i]);
            }

            fs.close();
        }

        // 메모리 undo 묶음(앞 groupCount개)의 기록을 간격과 연출 길이로 바꿈. 첫 프레임은 파일에 마지막으로 쓴 프레임과 이어서 구함
        // deltas, anims는 비어있는 Vector를 받아서 채움
        public static function computeMemoryRecords(memoryStamps:Array, groupCount:int, deltas:Vector.<uint>, anims:Vector.<uint>):void
        {
            var last:int = lastStamp;
            var has:Boolean = hasLastStamp;

            for (var g:int = 0; g < groupCount; g++)
            {
                const group:Array = memoryStamps[g];

                for (var i:int = 0; i < group.length; i++)
                {
                    const stamp:int = unpackStamp(group[i]);
                    var delta:int = 0;

                    if (has)
                    {
                        delta = (stamp - last) | 0;

                        if (delta < 0)
                        {
                            delta = 0;
                        }
                    }

                    deltas.push(uint(delta));
                    anims.push(uint(unpackAnimMs(group[i])));
                    last = stamp;
                    has = true;
                }
            }
        }

        // .fofo 파일 끝에 쓰는 ["rTimingSheet", 버전, 프레임 수, 구간 프레임 수, [구간별 압축 데이터]] 객체를 만듬
        // 앞쪽 fileFrames개는 파일에서 읽고, 그 뒤는 메모리 undo 묶음(memoryStamps의 앞 memoryGroupCount개)의 기록에서 계산함
        // 메모리 묶음 첫 프레임의 간격은 파일 마지막 프레임과 이어서 구하고, extraFrames는 끝에 간격 0으로 덧붙이는 프레임 수
        // 구간 하나씩만 풀어서 압축하니 전체를 한번에 메모리에 올리지 않음
        public static function buildFileObject(fileFrames:Number, memoryStamps:Array, memoryGroupCount:int, extraFrames:int):Array
        {
            const memoryDeltas:Vector.<uint> = new Vector.<uint>();
            const memoryAnims:Vector.<uint> = new Vector.<uint>();
            computeMemoryRecords(memoryStamps, memoryGroupCount, memoryDeltas, memoryAnims);

            for (var i:int = 0; i < extraFrames; i++)
            {
                memoryDeltas.push(0);
                memoryAnims.push(0);
            }

            const total:Number = fileFrames + memoryDeltas.length;
            const blobs:Array = [];

            for (var first:Number = 0; first < total; first += TimingSheet.SEGMENT_FRAMES)
            {
                const count:int = int(Math.min(TimingSheet.SEGMENT_FRAMES, total - first));
                const deltas:Vector.<uint> = new Vector.<uint>(count, true);
                const anims:Vector.<uint> = new Vector.<uint>(count, true);
                const fromFile:int = int(Math.max(0, Math.min(count, fileFrames - first)));

                if (fromFile > 0)
                {
                    readRange(first, fromFile, deltas, anims);
                }

                for (i = fromFile; i < count; i++)
                {
                    deltas[i] = memoryDeltas[int(first + i - fileFrames)];
                    anims[i] = memoryAnims[int(first + i - fileFrames)];
                }

                blobs.push(TimingSheet.encodeSegment(deltas, anims, count));
            }

            // 뒤에 선택 항목으로 옛 프레임 수 L (버전은 그대로 2라 옛 앱은 무시하고 채워진 42ms로 재생)
            return ["rTimingSheet", 2, total, TimingSheet.SEGMENT_FRAMES, blobs, buildPointsBlob(fileFrames, memoryStamps, memoryGroupCount), Math.min(legacyCount, fileFrames)];
        }

        // 점별 시각 레코드를 압축한 데이터. 파일 부분(프레임 번호 < fileFrames)은 파일에서 그대로 옮기고, 메모리 묶음은 그 뒤 번호로 붙임. 없으면 null
        private static function buildPointsBlob(fileFrames:Number, memoryStamps:Array, memoryGroupCount:int):ByteArray
        {
            const raw:ByteArray = new ByteArray();
            const file:File = AppStateManager.replayTimingPointsFilePath;

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

                    const keep:Boolean = frame < fileFrames;

                    if (keep)
                    {
                        raw.writeUnsignedInt(frame);
                        raw.writeUnsignedInt(count);
                    }

                    for (var i:uint = 0; i < count; i++)
                    {
                        const value:uint = fs.readUnsignedInt();

                        if (keep)
                        {
                            raw.writeUnsignedInt(value);
                        }
                    }
                }

                fs.close();
            }

            var position:Number = fileFrames;

            for (var g:int = 0; g < memoryGroupCount; g++)
            {
                const group:Array = memoryStamps[g];

                for (var j:int = 0; j < group.length; j++)
                {
                    const points:Array = pointsOf(group[j]);

                    if (points !== null)
                    {
                        raw.writeUnsignedInt(uint(position));
                        raw.writeUnsignedInt(uint(points.length));

                        for (var k:int = 0; k < points.length; k++)
                        {
                            raw.writeUnsignedInt(uint(points[k]));
                        }
                    }

                    position++;
                }
            }

            if (raw.length === 0)
            {
                return null;
            }

            raw.compress();
            return raw;
        }

        // buildFileObject로 만든 객체를 읽어서 파일 내용으로 되돌림. 모양이 틀리거나 풀 수 없으면 비워두고 false
        public static function loadFileObject(d:Array):Boolean
        {
            reset();

            try
            {
                if (d[1] !== 2 || !(d[2] is Number) || d[3] !== TimingSheet.SEGMENT_FRAMES || !(d[4] is Array))
                {
                    return false;
                }

                const blobs:Array = d[4];
                var remaining:Number = d[2];

                // 옛 프레임 수 L (선택 항목). 범위 밖이면 0. 색인을 만들기 전에 정해야 옛 구간 간격으로 계산됨
                setLegacyFrames((d.length > 6 && d[6] is Number && d[6] >= 0 && d[6] <= d[2]) ? d[6] : 0);
                ReplayClock.resetIndexEmpty();

                for (var s:int = 0; s < blobs.length; s++)
                {
                    const count:int = int(Math.min(TimingSheet.SEGMENT_FRAMES, remaining));
                    const deltas:Vector.<uint> = new Vector.<uint>(count, true);
                    const anims:Vector.<uint> = new Vector.<uint>(count, true);
                    TimingSheet.decodeSegment(blobs[s] as ByteArray, count, deltas, anims);
                    const firstOfSegment:Number = d[2] - remaining;
                    appendRecords(deltas, anims);
                    remaining -= count;
                    indexSegment(deltas, anims, firstOfSegment);
                }

                if (remaining !== 0)
                {
                    reset();
                    return false;
                }

                // 점별 시각은 없을 수도 있음. 풀 수 없으면 점 시각만 포기하고 나머지는 그대로 씀
                if (d.length > 5 && d[5] is ByteArray)
                {
                    try
                    {
                        const points:ByteArray = new ByteArray();
                        points.writeBytes(d[5] as ByteArray, 0, (d[5] as ByteArray).length);
                        points.uncompress();
                        const pfs:FileStream = new FileStream();
                        pfs.open(AppStateManager.replayTimingPointsFilePath, FileMode.WRITE);
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
                reset();
                return false;
            }

            return true;
        }

        // 불러오며 풀어 쓴 구간을 시계 색인에도 바로 반영 (시트를 다시 읽지 않음)
        private static function indexSegment(deltas:Vector.<uint>, anims:Vector.<uint>, firstFrame:Number):void
        {
            const records:Vector.<uint> = new Vector.<uint>(deltas.length * 2, true);

            for (var i:int = 0; i < deltas.length; i++)
            {
                records[i * 2] = deltas[i];
                records[i * 2 + 1] = anims[i];
            }

            ReplayClock.extendFileIndexWith(records, firstFrame);
        }

        // firstFrame부터 count개의 간격과 연출 길이를 읽어서 deltas, anims(둘다 count 이상)에 채움. 파일에 모자란 부분은 0
        public static function readRange(firstFrame:Number, count:int, deltas:Vector.<uint>, anims:Vector.<uint> = null):void
        {
            const file:File = AppStateManager.replayTimingSheetFilePath;

            if (!file.exists)
            {
                return;
            }

            const available:Number = Math.max(0, Math.min(count, frameCount - firstFrame));

            if (available === 0)
            {
                return;
            }

            const fs:FileStream = new FileStream();
            fs.open(file, FileMode.READ);
            fs.position = firstFrame * RECORD_BYTES;

            for (var i:int = 0; i < available; i++)
            {
                deltas[i] = fs.readUnsignedInt();
                const anim:uint = fs.readUnsignedInt();

                if (anims !== null)
                {
                    anims[i] = anim;
                }
            }

            fs.close();
        }
    }
}
