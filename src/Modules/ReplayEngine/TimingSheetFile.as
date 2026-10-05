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
    public final class TimingSheetFile
    {
        // 시간 기록이 없는 프레임(옛 파일, 기록이 어긋난 부분)의 간격. 24fps에서 틱당 명령 1개로 재생하던 옛 1배속과 같은 속도
        public static const LEGACY_FRAME_DELTA:uint = 42;
        public static const RECORD_BYTES:int = 8;
        private static const TWO_POW_32:Number = 4294967296;
        public static const MAX_ANIM_MS:Number = 2097151; // 합친 값이 Number의 정확한 정수 범위(2^53) 안에 들도록 연출 길이는 2^21 - 1 ms(약 35분)까지

        private static var lastStamp:int = 0; // 마지막으로 파일에 쓴 프레임의 getTimer 값
        private static var hasLastStamp:Boolean = false;

        // 연출 길이를 getTimer 값과 합쳐서 메모리 기록 한 칸으로 만듬. animMs가 0이면 getTimer 값만 있는 것과 같음
        public static function packStamp(stamp:int, animMs:Number):Number
        {
            const clamped:Number = Math.max(0, Math.min(MAX_ANIM_MS, Math.floor(animMs)));
            return clamped * TWO_POW_32 + uint(stamp);
        }

        public static function unpackStamp(packed:Number):int
        {
            return int(uint(packed % TWO_POW_32));
        }

        public static function unpackAnimMs(packed:Number):Number
        {
            return Math.floor(packed / TWO_POW_32);
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
            hasLastStamp = false;
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
        public static function alignTo(frame:Number):void
        {
            const file:File = AppStateManager.replayTimingSheetFilePath;
            const now:Number = frameCount;

            if (now === frame)
            {
                return;
            }

            const fs:FileStream = new FileStream();

            if (now > frame)
            {
                fs.open(file, FileMode.UPDATE);
                fs.position = frame * RECORD_BYTES;
                fs.truncate();
                fs.close();
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
        public static function appendGroup(stamps:Array, firstFrame:Number):void
        {
            alignTo(firstFrame);

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

                fs.writeUnsignedInt(uint(delta));
                fs.writeUnsignedInt(uint(unpackAnimMs(stamps[i])));
                lastStamp = stamp;
                hasLastStamp = true;
            }

            fs.close();
        }

        // frame개 이후를 자름 (뒤 자르기)
        public static function truncateAfter(frame:Number):void
        {
            if (frameCount > frame)
            {
                alignTo(frame);
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
            rest.clear();
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

            return ["rTimingSheet", 2, total, TimingSheet.SEGMENT_FRAMES, blobs];
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

                for (var s:int = 0; s < blobs.length; s++)
                {
                    const count:int = int(Math.min(TimingSheet.SEGMENT_FRAMES, remaining));
                    const deltas:Vector.<uint> = new Vector.<uint>(count, true);
                    const anims:Vector.<uint> = new Vector.<uint>(count, true);
                    TimingSheet.decodeSegment(blobs[s] as ByteArray, count, deltas, anims);
                    appendRecords(deltas, anims);
                    remaining -= count;
                }

                if (remaining !== 0)
                {
                    reset();
                    return false;
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
