package Modules.ReplayEngine
{
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import Modules.FileManager;

    // 프레임(명령 순번) 위치를 실시간 재생 시간(틱)으로 바꿔줌. 남은 시간, 최대 속도 계산에만 씀
    // 그리기 명령의 지연: 바로 앞에 붙은 wait 값의 합, wait가 없으면 1틱, 데이터 맨 처음 그리기 명령은 0 (재생 시작때 기다리지 않음)
    // wait 자체는 시간이 없고 뒤의 그리기 명령에 붙음, wait는 같은 뭉치 안에서 명령 바로 앞에만 오기 때문에 뭉치마다 따로 계산할수 있음
    // 리플레이 파일 구간은 뭉치마다 [시작 프레임, 시작 틱, 바이트 위치]를 저장하고 메모리 undo 구간은 그때그때 계산함
    public class ReplayTimeline
    {
        private static var groupFrames:Vector.<Number> = new Vector.<Number>();
        private static var groupTicks:Vector.<Number> = new Vector.<Number>();
        private static var groupBytes:Vector.<Number> = new Vector.<Number>();
        private static var fileFrames:Number = 0; // 표가 만들어진 리플레이 파일의 프레임 수
        private static var fileTicks:Number = 0;
        private static var fileBytes:Number = 0; // 표가 만들어진 리플레이 파일 크기
        private static var valid:Boolean = false;
        private static var cachedGroup:Array = null; // getCommandAt에서 마지막으로 읽은 파일 뭉치
        private static var cachedGroupStart:Number = -1;

        // 리플레이 파일 내용이 바뀌었는데 아래 append, truncate로 따라가지 않는 곳에서 호출. 다음에 쓸때 파일을 다시 읽음
        public static function invalidate():void
        {
            valid = false;
            cachedGroup = null;
        }

        // UndoController.addNew에서 가장 오래된 undo 뭉치가 파일 끝에 붙을때
        public static function appendFileGroup(group:Array, startFrame:Number, startByte:Number, endByte:Number):void
        {
            // 파일은 이미 바뀐 뒤라 isValid 대신 표가 기억하는 끝 위치와 비교함
            if (!valid || startFrame !== fileFrames || startByte !== fileBytes)
            {
                valid = false;
                return;
            }

            groupFrames.push(fileFrames);
            groupTicks.push(fileTicks);
            groupBytes.push(fileBytes);
            fileTicks += getGroupTicks(group, group.length, groupFrames.length === 1);
            fileFrames += group.length;
            fileBytes = endByte;
        }

        // 딥 언두 적용, 뒤 자르기에서 파일을 byte 위치에서 잘랐을때
        public static function truncateFile(byte:Number, frame:Number):void
        {
            if (!valid)
            {
                return;
            }

            var count:int = groupBytes.length;

            while (count > 0 && groupBytes[count - 1] >= byte)
            {
                count--;
            }

            const end:int = count;

            if ((end < groupBytes.length ? groupFrames[end] : fileFrames) !== frame || (end < groupBytes.length ? groupBytes[end] : fileBytes) !== byte)
            {
                // 뭉치 경계가 아니면 다시 읽음
                valid = false;
                return;
            }

            if (end < groupBytes.length)
            {
                fileTicks = groupTicks[end];
                groupFrames.length = end;
                groupTicks.length = end;
                groupBytes.length = end;
                cachedGroup = null;
            }

            fileFrames = frame;
            fileBytes = byte;
        }

        // frame 위치까지(그 앞 명령까지) 흐른 재생 틱
        public static function getTickAtFrame(frame:Number):Number
        {
            if (frame <= 0)
            {
                return 0;
            }

            if (!isValid())
            {
                rebuild();
            }

            if (frame < fileFrames)
            {
                const g:int = findFileGroup(frame);
                const group:Array = readFileGroup(groupBytes[g]);
                return groupTicks[g] + (group ? getGroupTicks(group, frame - groupFrames[g], g === 0) : 0);
            }

            // 메모리 undo 구간
            var tick:Number = fileTicks;
            var start:Number = fileFrames;
            const memory:Array = ReplayState.rMemoryData;

            for (var i:int = 0;i < memory.length;i++)
            {
                const data:Array = memory[i];

                if (!data)
                {
                    continue;
                }

                const first:Boolean = fileFrames === 0 && i === 0;

                if (frame < start + data.length)
                {
                    return tick + getGroupTicks(data, frame - start, first);
                }

                tick += getGroupTicks(data, data.length, first);
                start += data.length;
            }

            return tick;
        }

        // frame 위치의 명령 (그리지 않고 보기만 함), 범위 밖이면 null
        public static function getCommandAt(frame:Number):Array
        {
            if (frame < 0)
            {
                return null;
            }

            if (!isValid())
            {
                rebuild();
            }

            if (frame < fileFrames)
            {
                const g:int = findFileGroup(frame);

                if (cachedGroup === null || cachedGroupStart !== groupFrames[g])
                {
                    cachedGroup = readFileGroup(groupBytes[g]);
                    cachedGroupStart = groupFrames[g];
                }

                return cachedGroup ? cachedGroup[frame - cachedGroupStart] : null;
            }

            var start:Number = fileFrames;

            for each (var data:Array in ReplayState.rMemoryData)
            {
                if (!data)
                {
                    continue;
                }

                if (frame < start + data.length)
                {
                    return data[frame - start];
                }

                start += data.length;
            }

            return null;
        }

        // frame이 데이터 첫 그리기 명령보다 앞인지 (앞에 붙은 wait만 지났거나 맨 처음)
        public static function isBeforeFirstCommand(frame:Number):Boolean
        {
            if (frame <= 0)
            {
                return true;
            }

            var first:Array = null;

            if (ReplayState.getRFileDataTotalFrame() > 0)
            {
                if (!isValid())
                {
                    rebuild();
                }

                first = groupBytes.length > 0 ? readFileGroup(groupBytes[0]) : null;
            }
            else if (ReplayState.rMemoryData.length > 0)
            {
                first = ReplayState.rMemoryData[0];
            }

            if (!first)
            {
                return true;
            }

            for (var i:int = 0;i < first.length && i < frame;i++)
            {
                if (!ReplayState.isWaitCommand(first[i]))
                {
                    return false;
                }
            }

            return true;
        }

        // 뭉치 안 end 앞까지 그리기 명령들의 지연 합
        public static function getGroupTicks(group:Array, end:int, firstOfData:Boolean):Number
        {
            var sum:Number = 0;
            var waitSum:Number = 0;
            var hasWait:Boolean = false;
            var skipFirst:Boolean = firstOfData;

            for (var i:int = 0;i < end;i++)
            {
                const c:Array = group[i];

                if (ReplayState.isWaitCommand(c))
                {
                    waitSum += c[1];
                    hasWait = true;
                    continue;
                }

                if (skipFirst)
                {
                    skipFirst = false;
                }
                else
                {
                    sum += hasWait ? waitSum : 1;
                }

                waitSum = 0;
                hasWait = false;
            }

            return sum;
        }

        private static function isValid():Boolean
        {
            return valid && fileFrames === ReplayState.getRFileDataTotalFrame() && fileBytes === getFileSize();
        }

        private static function getFileSize():Number
        {
            const f:File = FileManager.replayDataFilePath;
            return f.exists ? f.size : 0;
        }

        private static function rebuild():void
        {
            groupFrames.length = 0;
            cachedGroup = null;
            groupTicks.length = 0;
            groupBytes.length = 0;
            fileFrames = 0;
            fileTicks = 0;
            fileBytes = 0;
            const f:File = FileManager.replayDataFilePath;

            if (f.exists)
            {
                const fs:FileStream = new FileStream();
                fs.open(f, FileMode.READ);

                while (fs.bytesAvailable > 0)
                {
                    const start:Number = fs.position;
                    const group:Array = fs.readObject() as Array;

                    if (!group)
                    {
                        continue;
                    }

                    groupFrames.push(fileFrames);
                    groupTicks.push(fileTicks);
                    groupBytes.push(start);
                    fileTicks += getGroupTicks(group, group.length, groupFrames.length === 1);
                    fileFrames += group.length;
                }

                fileBytes = fs.position;
                fs.close();
            }

            valid = true;

            if (fileFrames !== ReplayState.getRFileDataTotalFrame())
            {
                trace("[ReplayTimeline] file frame mismatch", fileFrames, ReplayState.getRFileDataTotalFrame());
            }
        }

        private static function findFileGroup(frame:Number):int
        {
            var low:int = 0;
            var high:int = groupFrames.length - 1;

            while (low < high)
            {
                const mid:int = (low + high + 1) >> 1;

                if (groupFrames[mid] <= frame)
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

        private static function readFileGroup(byte:Number):Array
        {
            const fs:FileStream = new FileStream();
            fs.open(FileManager.replayDataFilePath, FileMode.READ);
            fs.position = byte;
            const group:Array = fs.bytesAvailable > 0 ? fs.readObject() as Array : null;
            fs.close();
            return group;
        }
    }
}
