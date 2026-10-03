package Modules.ReplayEngine
{
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import Modules.FileManager;
    import Modules.AppStateManager;

    // 프레임(명령 순번) 위치를 실시간 재생 시간(틱)과 그리기 명령 수(wait 제외)로 바꿔줌
    // 틱은 남은 시간, 최대 속도 계산에 쓰고 명령 수는 캐시 이미지 간격 계산에 씀
    // 그리기 명령의 지연: 바로 앞에 붙은 wait 값의 합, wait가 없으면 1틱, 데이터 맨 처음 그리기 명령은 0 (재생 시작때 기다리지 않음)
    // wait 자체는 시간이 없고 뒤의 그리기 명령에 붙음, wait는 같은 뭉치 안에서 명령 바로 앞에만 오기 때문에 뭉치마다 따로 계산할수 있음
    // 리플레이 파일 구간은 뭉치마다 [시작 프레임, 시작 틱, 시작 명령 수, 바이트 위치]를 저장하고 메모리 undo 구간은 그때그때 계산함
    public class ReplayTimeline
    {
        private static var groupFrames:Vector.<Number> = new Vector.<Number>();
        private static var groupTicks:Vector.<Number> = new Vector.<Number>();
        private static var groupBytes:Vector.<Number> = new Vector.<Number>();
        private static var groupCommands:Vector.<Number> = new Vector.<Number>();
        // 리플레이 파일 구간의 fillanim 셀 프레임과 높이, 재생 속도에 따라 시간에 넣을지 달라져서 틱 합과 따로 보관함
        private static var fillFrames:Vector.<Number> = new Vector.<Number>();
        private static var fillMsSums:Vector.<Number> = new Vector.<Number>(); // 각 fillanim까지의 애니메이션 시간(ms) 누적합, 재생 속도와 상관없는 시간이라 미리 더해둘 수 있음
        private static var groupFills:Vector.<int> = new Vector.<int>(); // 뭉치가 시작할때의 fillFrames 길이
        private static var fileFrames:Number = 0; // 표가 만들어진 리플레이 파일의 프레임 수
        private static var fileTicks:Number = 0;
        private static var fileCommands:Number = 0;
        private static var measuredTicks:Number = 0; // measureGroup 결과
        private static var measuredCommands:Number = 0;
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

        // UndoHistory.addNew에서 가장 오래된 undo 뭉치가 파일 끝에 붙을때
        public static function appendFileGroup(group:Array, startFrame:Number, startByte:Number, endByte:Number):void
        {
            // 파일은 이미 바뀐 뒤라 isValid 대신 표가 기억하는 끝 위치와 비교함
            if (!valid || startFrame !== fileFrames || startByte !== fileBytes)
            {
                valid = false;
                return;
            }

            addGroup(group, fileBytes);
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
                fileCommands = groupCommands[end];
                fillFrames.length = groupFills[end];
                fillMsSums.length = groupFills[end];
                groupFrames.length = end;
                groupTicks.length = end;
                groupBytes.length = end;
                groupCommands.length = end;
                groupFills.length = end;
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

        // frame 위치까지(그 앞 명령까지) 그린 그리기 명령 수, wait는 세지 않음
        // 구버전 데이터는 wait가 없어서 frame과 같음
        public static function getCommandCountAtFrame(frame:Number):Number
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

                // 캐시 이미지 위치는 뭉치 경계라서 보통 파일을 읽지 않음
                if (frame === groupFrames[g])
                {
                    return groupCommands[g];
                }

                const group:Array = getFileGroup(g);
                measureGroup(group, frame - groupFrames[g], false);
                return groupCommands[g] + measuredCommands;
            }

            var count:Number = fileCommands;
            var start:Number = fileFrames;

            for each (var data:Array in ReplayState.rMemoryData)
            {
                if (!data)
                {
                    continue;
                }

                if (frame < start + data.length)
                {
                    measureGroup(data, frame - start, false);
                    return count + measuredCommands;
                }

                measureGroup(data, data.length, false);
                count += measuredCommands;
                start += data.length;
            }

            return count;
        }

        // [from, to) 프레임 칸에 있는 fillanim, lassoanim, moveanim 애니메이션 시간(ms)의 합
        // 재생 속도와 상관없는 실제 시간이라 틱 합(getTickAtFrame)과 따로 셈, 틱 합과 같은 프레임 범위로 맞춰서 총 시간을 구함
        // 파일 구간은 표를 이분탐색하고 메모리 undo 구간은 to까지만 훑음 (to 뒤의 뭉치 애니메이션은 세지 않음)
        public static function getAnimMsBetween(from:Number, to:Number):Number
        {
            if (!(to > from))
            {
                return 0;
            }

            if (!isValid())
            {
                rebuild();
            }

            var sum:Number = 0;
            const low:int = lowerBoundFill(from);
            const high:int = lowerBoundFill(to);

            if (high > low)
            {
                sum = fillMsSums[high - 1] - (low > 0 ? fillMsSums[low - 1] : 0);
            }

            // 메모리 undo 구간
            var start:Number = fileFrames;

            for each (var data:Array in ReplayState.rMemoryData)
            {
                if (!data)
                {
                    continue;
                }

                if (start >= to)
                {
                    break;
                }

                if (start + data.length > from)
                {
                    for (var j:int = Math.max(0, from - start);j < data.length && start + j < to;j++)
                    {
                        sum += ReplayState.getAnimMsAt(data, j);
                    }
                }

                start += data.length;
            }

            return sum;
        }

        // frame 위치 뒤(그 칸 포함)부터 전체 프레임(ReplayState.TOTAL_FRAME) 앞까지의 애니메이션 시간(ms)의 합
        public static function getAnimMsFrom(frame:Number):Number
        {
            return getAnimMsBetween(frame, ReplayState.TOTAL_FRAME);
        }

        // fillFrames는 프레임 순서대로라서 frame 이상인 첫 위치를 이분탐색
        private static function lowerBoundFill(frame:Number):int
        {
            var low:int = 0;
            var high:int = fillFrames.length;

            while (low < high)
            {
                const mid:int = (low + high) >> 1;

                if (fillFrames[mid] < frame)
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
                const group:Array = getFileGroup(g);
                return group ? group[frame - groupFrames[g]] : null;
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
                if (!ReplayState.isNonDrawCommand(first[i]))
                {
                    return false;
                }
            }

            return true;
        }

        // 뭉치 안 end 앞까지 그리기 명령들의 지연 합
        public static function getGroupTicks(group:Array, end:int, firstOfData:Boolean):Number
        {
            measureGroup(group, end, firstOfData);
            return measuredTicks;
        }

        // 뭉치 안 end 앞까지 그리기 명령들의 지연 합과 그리기 명령 수를 한번에 셈 (measuredTicks, measuredCommands)
        private static function measureGroup(group:Array, end:int, firstOfData:Boolean):void
        {
            var sum:Number = 0;
            var commands:Number = 0;
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

                // fillanim, lassoanim, moveanim은 그리지 않고 지연에도 영향이 없음 (애니메이션 시간은 getAnimMsFrom에서 따로 셈)
                if (ReplayState.isNonDrawCommand(c))
                {
                    continue;
                }

                commands++;

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

            measuredTicks = sum;
            measuredCommands = commands;
        }

        // 파일 끝에 뭉치 하나를 표에 추가, 틱과 명령 수는 한번 훑어서 같이 셈
        private static function addGroup(group:Array, startByte:Number):void
        {
            groupFrames.push(fileFrames);
            groupTicks.push(fileTicks);
            groupCommands.push(fileCommands);
            groupBytes.push(startByte);
            groupFills.push(fillFrames.length);

            for (var i:int = 0;i < group.length;i++)
            {
                const animMs:Number = ReplayState.getAnimMsAt(group, i);

                if (animMs > 0)
                {
                    fillFrames.push(fileFrames + i);
                    fillMsSums.push((fillMsSums.length > 0 ? fillMsSums[fillMsSums.length - 1] : 0) + animMs);
                }
            }

            measureGroup(group, group.length, groupFrames.length === 1);
            fileTicks += measuredTicks;
            fileCommands += measuredCommands;
            fileFrames += group.length;
        }

        // 파일 구간 g번째 뭉치, 연속으로 같은 뭉치를 볼때 다시 읽지 않게 마지막 뭉치를 기억함
        private static function getFileGroup(g:int):Array
        {
            if (cachedGroup === null || cachedGroupStart !== groupFrames[g])
            {
                cachedGroup = readFileGroup(groupBytes[g]);
                cachedGroupStart = groupFrames[g];
            }

            return cachedGroup;
        }

        // 리플레이 파일을 바꾸는 곳은 append, truncate, invalidate로 표에 알려주므로 파일 크기나 프레임 수를 매번 비교하지 않음
        // 재생 중에 파일을 다시 읽어도 캔버스, 캐시와 어긋나서 의미가 없고, 프레임 수가 안 맞는 상태가 이어지면 매번 rebuild가 돌게 됨
        private static function isValid():Boolean
        {
            return valid;
        }

        // 리플레이 파일 전체를 읽어서 표를 새로 만듬. 파일 프레임 수가 ReplayState와 다르면(저장 없이 앱이 죽은 경우 등) 알리기만 하고 표는 파일 기준으로 둠
        private static function rebuild():void
        {
            groupFrames.length = 0;
            cachedGroup = null;
            groupTicks.length = 0;
            groupBytes.length = 0;
            groupCommands.length = 0;
            groupFills.length = 0;
            fillFrames.length = 0;
            fillMsSums.length = 0;
            fileFrames = 0;
            fileTicks = 0;
            fileCommands = 0;
            fileBytes = 0;
            const f:File = AppStateManager.replayDataFilePath;

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

                    addGroup(group, start);
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
            fs.open(AppStateManager.replayDataFilePath, FileMode.READ);
            fs.position = byte;
            const group:Array = fs.bytesAvailable > 0 ? fs.readObject() as Array : null;
            fs.close();
            return group;
        }
    }
}
