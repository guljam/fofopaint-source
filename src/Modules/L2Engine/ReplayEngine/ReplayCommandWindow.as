package Modules.L2Engine.ReplayEngine
{

    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;
    import Modules.ReplayEngine.ReplayDrawCommands;
    import Modules.ReplayEngine.ReplayState;
    import Modules.L1Data.AppDataPaths;

    // 재생 경로에서 repdata를 읽는 유일한 곳. 그리는 쪽(ReplayDrawer.readNextFileData)은 takeNext로 묶음을 하나씩 꺼내 쓰고,
    // 카메라(ReplayCursorFollow)는 앞으로 그려질 커서 위치 요약만 collectCursorPath로 읽음 (명령 배열에는 접근하지 않음)
    // 파일은 읽을 때만 열고 바로 닫음 (다른 곳이 repdata를 자르거나 지울 때 핸들이 남지 않게)
    // 묶음은 읽은 배열 그대로 그리는 쪽에 넘기고, 명령 실행은 이 배열을 고치지 않음 (ReplayDrawCommands 전수 확인, RESULT 참고)
    // 층: L2 엔진 - 재생 경로에서 repdata를 읽는 유일한 곳
    public class ReplayCommandWindow
    {
        public static const LOOKAHEAD_REAL_MS:Number = 500; // 실제 시간으로 이만큼 앞까지 미리 읽음 (녹화 시간으로는 * 배속)
        public static const LOOKAHEAD_MAX_FRAMES:Number = 2000; // 미리 읽는 프레임 수 상한
        public static const MAX_GROUPS:int = 64; // 미리 읽어 둘 묶음 수 상한
        public static const READ_BUDGET_MS:int = 4; // 한 번 채울 때 읽기에 쓰는 시간 (묶음 하나는 끝까지 읽음)
        private static const MAX_SUMMARY_POINTS:int = 256; // 묶음 하나의 요약 점 수 상한 (넘으면 일정 간격으로 줄임)

        private const items:Vector.<Object> = new Vector.<Object>(); // {data, startByte, endByte, firstFrame, summary(Vector.<Number>: 프레임, x, y 반복)}
        private const stream:FileStream = new FileStream();
        private var streamOpen:Boolean = false; // 동기 읽기(takeNext)가 연달아 일어나는 동안 열어 둠. 그리기 틱/탐색이 끝날 때 releaseStream으로 닫음
        private var nextByte:Number = -1; // 큐 맨 뒤 다음에 읽을 위치
        private var nextFrame:Number = 0; // 그 묶음의 첫 프레임 번호
        private var projX:Number = 0; // 요약을 만들 때 이어서 쓰는 커서 위치 (이동 명령은 상대값이라 앞 묶음에서 이어 계산)
        private var projY:Number = 0;
        private var projW:Number = 0;
        private var projH:Number = 0;
        private var lastTakenEnd:Number = -1;
        private var skippedNullEnd:Number = -1;
        private var atEnd:Boolean = false; // 큐 맨 뒤가 파일 끝
        private var currentItem:Object = null; // 마지막으로 꺼낸 묶음 (지금 그리는 중이라 남은 명령의 커서 위치도 카메라가 봐야 함)
        private const memorySummaries:Dictionary = new Dictionary(true); // 메모리 묶음 배열 -> 요약

        // 확인용 통계 (RESULT에 기록)
        public var readCalls:int = 0; // 파일에서 readObject를 부른 횟수
        public var resets:int = 0; // 큐를 비우고 다시 읽은 횟수
        public var maxRefillMs:int = 0; // 한 번 채우는 데 걸린 최대 시간
        public var refills:int = 0; // 실제로 읽은 채우기 횟수
        public var slowRefills:int = 0;
        public var maxGroupParseMs:int = 0; // 묶음 하나를 읽고 요약하는 데 걸린 최대 시간
        private const readBytePositions:Dictionary = new Dictionary(); // 읽은 byte 위치별 횟수 (같은 묶음을 두 번 읽었는지 확인)
        public var duplicateReads:int = 0;

        // collectCursorPath가 마지막으로 본 범위. coveredEndFrame = 요약을 살펴본 마지막 프레임(포함 안 함), coveredToDataEnd = 그 뒤에 더 읽을 데이터가 없음(파일과 메모리 끝)
        // 끝에 못 미쳤다면 데이터가 없어서가 아니라 프레임/묶음 상한이나 아직 안 읽어서임
        public var coveredEndFrame:Number = 0;
        public var coveredToDataEnd:Boolean = false;

        public function get groupCount():int
        {
            return items.length;
        }

        // 스트림을 열거나 위치를 바꾸는 곳에서 부름. 큐를 비우고 byte 위치부터 다시 채우게 함
        public function resetAt(byte:Number, frame:Number):void
        {
            items.length = 0;
            currentItem = null;
            nextByte = byte;
            nextFrame = frame;
            atEnd = false;
            seedProjection();
        }

        // 리플레이 모드 종료, 새 파일 열기, repdata가 바뀌는 곳(자르기 등)에서 부름
        public function dispose():void
        {
            items.length = 0;
            currentItem = null;
            nextByte = -1;
            lastTakenEnd = -1;
            skippedNullEnd = -1;
            atEnd = false;

            for (var key:* in memorySummaries)
            {
                delete memorySummaries[key];
            }

            for (var pos:* in readBytePositions)
            {
                delete readBytePositions[pos];
            }

            releaseStream();
        }

        // 열어 둔 스트림을 닫음. renderReplayFrame이 끝날 때와 refill이 끝날 때 부름 (다른 곳이 repdata를 자르거나 지울 때 핸들이 남지 않게)
        public function releaseStream():void
        {
            if (streamOpen)
            {
                streamOpen = false;

                try
                {
                    stream.close();
                }
                catch (e:Error)
                {
                }
            }
        }

        private function ensureStreamOpen():void
        {
            if (!streamOpen)
            {
                stream.open(AppDataPaths.replayDataFilePath, FileMode.READ);
                streamOpen = true;
            }
        }

        // 맨 앞 묶음을 꺼냄. 반환: {data, endByte} / 파일 끝이면 null
        // expectedByte는 그리는 쪽이 알고 있는 이번 묶음의 시작 byte (rFileLastBytePosition). 큐 맨 앞과 다르면 큐를 비우고 그 위치부터 다시 읽음
        public function takeNext(expectedByte:Number, nowFrame:Number):Object
        {
            if (items.length === 0 || (items[0].startByte !== expectedByte && items[0].startByte !== skippedNullEnd))
            {
                if (items.length > 0)
                {
                    resets++; // 큐에 남은 묶음이 있는데 위치가 달라짐 (탐색 등으로 그리는 쪽이 위치를 옮긴 경우)
                }

                if (items.length > 0 || nextByte !== expectedByte)
                {
                    resetAt(expectedByte, nowFrame);
                }
                else
                {
                    nextFrame = nowFrame; // 직전 묶음에 이어서 읽는 중이면 큐를 비우고 다시 시작하지 않음 (탐색/슬라이드쇼는 묶음 수백 개를 연달아 읽음)
                }

                // 바로 그려 버리는 묶음이라 요약은 만들지 않고, 카메라가 실제로 볼 때 만듦 (summaryOf)
                ensureStreamOpen();
                readGroup(false);
            }

            if (items.length === 0)
            {
                return null;
            }

            const item:Object = items.shift();
            currentItem = item;
            lastTakenEnd = item.endByte;

            if (item.data === null)
            {
                skippedNullEnd = item.endByte;
            }

            return item;
        }

        // 그리기 틱 끝에서 부름. 앞에 남은 녹화 시간이 목표보다 적으면 묶음을 더 읽음
        // speed는 배속, nowFrame은 지금 프레임. 시간 예산을 넘으면 묶음 하나를 끝까지 읽고 멈춤
        public function refill(nowFrame:Number, speed:Number):void
        {
            releaseStream(); // 이 틱에 동기 읽기가 열어 둔 것이 있으면 닫음

            if (atEnd || nextByte < 0 || items.length >= MAX_GROUPS)
            {
                return;
            }

            const start:int = getTimer();
            const wantRecordedMs:Number = LOOKAHEAD_REAL_MS * speed;
            const limitFrame:Number = nowFrame + LOOKAHEAD_MAX_FRAMES;

            if (nextFrame >= limitFrame || ReplayClock.timeOfFrame(nextFrame) - ReplayClock.timeOfFrame(nowFrame) >= wantRecordedMs)
            {
                return; // 이미 충분히 읽어 둠
            }

            ensureStreamOpen(); // 이번 채우기에서 한 번만 열고 끝에 닫음

            try
            {
                while (!atEnd && items.length < MAX_GROUPS && nextFrame < limitFrame && ReplayClock.timeOfFrame(nextFrame) - ReplayClock.timeOfFrame(nowFrame) < wantRecordedMs)
                {
                    readGroup(true);

                    if (getTimer() - start >= READ_BUDGET_MS)
                    {
                        break;
                    }
                }
            }
            finally
            {
                releaseStream();
            }

            const spent:int = getTimer() - start;
            refills++;

            if (spent > maxRefillMs)
            {
                maxRefillMs = spent;
            }

            if (spent > READ_BUDGET_MS + 4)
            {
                slowRefills++; // 예산에 묶음 하나 해석 시간(최대 약 2ms)과 타이머 오차를 더한 값을 넘은 횟수
            }
        }

        // 큐 맨 뒤에서 묶음을 하나 읽음 (스트림은 호출한 쪽이 열어 둠. 파일 끝이면 atEnd)
        private function readGroup(withSummary:Boolean):void
        {
            stream.position = nextByte;

            if (stream.bytesAvailable === 0)
            {
                atEnd = true;
                return;
            }

            const t0:int = getTimer();
            const data:Array = stream.readObject() as Array;
            readCalls++;
            const startByte:Number = nextByte;
            const endByte:Number = stream.position;

            if (startByte in readBytePositions)
            {
                duplicateReads++;
            }

            readBytePositions[startByte] = 1;
            items.push({data: data, startByte: startByte, endByte: endByte, firstFrame: nextFrame, summary: (withSummary && data !== null) ? summarize(data) : null, summaryReady: withSummary});
            nextByte = endByte;
            nextFrame += (data === null) ? 0 : data.length;
            const parseMs:int = getTimer() - t0;

            if (parseMs > maxGroupParseMs)
            {
                maxGroupParseMs = parseMs;
            }
        }

        // 묶음의 요약. 바로 그려 버려서 읽을 때 만들지 않은 묶음은 카메라가 처음 볼 때 지금 커서에서 이어서 만듦 (이동 명령의 상대 좌표는 근사)
        private function summaryOf(item:Object):Vector.<Number>
        {
            if (item.data === null)
            {
                return null;
            }

            if (!item.summaryReady)
            {
                seedProjection();
                item.summary = summarize(item.data);
                item.summaryReady = true;
            }

            return item.summary;
        }

        // 확인용 통계를 0으로 되돌림 (시험에서 구간을 나눠 셀 때)
        public function clearReadStats():void
        {
            readCalls = 0;
            resets = 0;
            duplicateReads = 0;
            maxRefillMs = 0;
            maxGroupParseMs = 0;
            refills = 0;
            slowRefills = 0;

            for (var pos:* in readBytePositions)
            {
                delete readBytePositions[pos];
            }
        }

        // ---- 카메라용 읽기 전용 API ----

        // 지금 그리는 위치(그리는 쪽이 아는 rFileLastBytePosition)와 큐가 이어져 있는지. 탐색 직후처럼 어긋나 있으면 카메라는 미리 본 값을 쓰지 않음
        public function isAlignedWith(byte:Number):Boolean
        {
            if (items.length > 0)
            {
                return items[0].startByte === byte;
            }

            // 큐가 비어 있어도 지금 그리는 묶음의 끝이 기대 위치이고 다음에 읽을 위치와 이어져 있으면 맞는 상태 (저배속에서는 묶음 하나가 길어 큐가 자주 빔)
            return nextByte === byte && (atEnd || (currentItem !== null && currentItem.endByte === byte));
        }

        // 프레임 [fromFrame, toFrame) 구간에서 커서 위치가 정해지는 지점을 (프레임, x, y) 반복으로 out에 이어 붙임
        // 큐에 있는 파일 묶음을 먼저, 그 뒤에 메모리 묶음을 이어서 봄. 반환: 구간 끝까지 데이터가 있었는지
        public function collectCursorPath(fromFrame:Number, toFrame:Number, out:Vector.<Number>):Boolean
        {
            var frame:Number = fromFrame;
            coveredEndFrame = fromFrame;
            coveredToDataEnd = false;

            if (currentItem !== null && summaryOf(currentItem) !== null)
            {
                appendRange(currentItem.summary, currentItem.firstFrame, fromFrame, toFrame, out);
                // 지금 그리는 묶음이 아직 안 끝났으면 그 끝까지는 본 것임 (저배속에서는 묶음 하나가 미리 볼 시간보다 길어 큐가 비어 있는 경우가 많음)
                coveredEndFrame = Math.max(coveredEndFrame, currentItem.firstFrame + currentItem.data.length);
                frame = coveredEndFrame;

                if (frame >= toFrame)
                {
                    return true;
                }
            }

            for each (var item:Object in items)
            {
                if (summaryOf(item) === null)
                {
                    continue;
                }

                appendRange(item.summary, item.firstFrame, fromFrame, toFrame, out);
                frame = item.firstFrame + item.data.length;
                coveredEndFrame = frame;

                if (frame >= toFrame)
                {
                    return true;
                }
            }

            if (!atEnd)
            {
                return false;
            }

            coveredEndFrame = Math.max(coveredEndFrame, ReplayState.getRFileDataTotalFrame());

            // 파일 묶음이 끝났으면 메모리 묶음으로 이어짐 (메모리 묶음은 byte 없이 배열 참조만 씀)
            var first:Number = ReplayState.getRFileDataTotalFrame();
            const groups:Array = ReplayState.rMemoryData;
            const frames:Array = ReplayState.rMemoryDataFrames;

            for (var g:int = 0;g < groups.length;g++)
            {
                const len:Number = frames[g];

                if (first + len > fromFrame && first < toFrame)
                {
                    var summary:Vector.<Number> = memorySummaries[groups[g]] as Vector.<Number>;

                    if (summary === null)
                    {
                        seedProjection();
                        summary = summarize(groups[g]);
                        memorySummaries[groups[g]] = summary;
                    }

                    appendRange(summary, first, fromFrame, toFrame, out);
                }

                first += len;
                coveredEndFrame = Math.max(coveredEndFrame, first);

                if (first >= toFrame)
                {
                    return true;
                }
            }

            coveredToDataEnd = true; // 파일도 메모리도 여기서 끝남
            return false;
        }

        // 확인용: 지금 그리는 묶음의 요약에서 beforeFrame보다 앞선 마지막 커서 위치를 out[0], out[1]에 넣음. 없으면 false
        public function lastCursorBefore(beforeFrame:Number, out:Vector.<Number>):Boolean
        {
            if (currentItem === null || summaryOf(currentItem) === null)
            {
                return false;
            }

            const sm:Vector.<Number> = currentItem.summary;
            var found:Boolean = false;

            for (var i:int = 0;i < sm.length;i += 3)
            {
                if (currentItem.firstFrame + sm[i] < beforeFrame)
                {
                    out[0] = sm[i + 1];
                    out[1] = sm[i + 2];
                    found = true;
                }
            }

            return found;
        }

        private function appendRange(summary:Vector.<Number>, firstFrame:Number, fromFrame:Number, toFrame:Number, out:Vector.<Number>):void
        {
            for (var i:int = 0;i < summary.length;i += 3)
            {
                const f:Number = firstFrame + summary[i];

                if (f >= fromFrame && f < toFrame)
                {
                    out.push(f, summary[i + 1], summary[i + 2]);
                }
            }
        }

        // ---- 요약 ----

        private function seedProjection():void
        {
            projX = ReplayDrawCommands.getRCursorPos().x;
            projY = ReplayDrawCommands.getRCursorPos().y;
            projW = ReplayState.RCANVAS_WIDTH;
            projH = ReplayState.RCANVAS_HEIGHT;
        }

        // 묶음의 명령마다 커서 위치가 정해지는 지점을 뽑음. 규칙은 ReplayDrawCommands의 setRCursorPos 호출과 같음
        // 이동 명령은 앞 묶음에서 이어서 계산하므로 큐가 비었다가 다시 채워지면 그때의 실제 커서에서 다시 시작함
        private function summarize(group:Array):Vector.<Number>
        {
            const raw:Vector.<Number> = new Vector.<Number>();

            for (var i:int = 0;i < group.length;i++)
            {
                if (cursorAfter(group[i] as Array))
                {
                    raw.push(i, projX, projY);
                }
            }

            if (raw.length / 3 <= MAX_SUMMARY_POINTS)
            {
                return raw;
            }

            // 점이 많으면 일정 간격으로 줄이고 마지막 점은 남김
            const total:int = raw.length / 3;
            const step:Number = total / MAX_SUMMARY_POINTS;
            const thinned:Vector.<Number> = new Vector.<Number>();

            for (var k:int = 0;k < MAX_SUMMARY_POINTS;k++)
            {
                const idx:int = int(k * step) * 3;
                thinned.push(raw[idx], raw[idx + 1], raw[idx + 2]);
            }

            thinned.push(raw[raw.length - 3], raw[raw.length - 2], raw[raw.length - 1]);
            return thinned;
        }

        private function setPos(x:Number, y:Number):Boolean
        {
            projX = (x < 0) ? 0 : (x > projW ? projW : x);
            projY = (y < 0) ? 0 : (y > projH ? projH : y);
            return true;
        }

        // 명령 하나가 실행된 뒤의 커서 위치를 projX/projY에 넣음. 커서가 바뀌는 명령이면 true
        private function cursorAfter(cmd:Array):Boolean
        {
            if (cmd === null || cmd.length === 0)
            {
                return false;
            }

            var xy:Vector.<Number>;

            switch (cmd[0])
            {
                case "lineTo":
                    return setPos(cmd[1], cmd[2]);

                case "sqline":
                    xy = cmd[6];
                    return setPos(xy[xy.length - 2], xy[xy.length - 1]);

                case "fill":
                case "fill3":
                case "fill4":
                case "fill5":
                    xy = cmd[5];
                    return setPos(xy[xy.length - 2], xy[xy.length - 1]);

                case "fill2":
                    xy = cmd[4];
                    return setPos(xy[xy.length - 2], xy[xy.length - 1]);

                case "line4":
                    xy = cmd[6];
                    return setPos(xy[xy.length - 2], xy[xy.length - 1]);

                case "dot":
                case "dot2":
                case "dot3":
                case "dot4":
                    return setPos(cmd[5], cmd[6]);

                case "line":
                case "line1":
                case "line2":
                case "line3":
                    return setPos(cmd[7], cmd[8]);

                case "move":
                case "move1":
                case "move2":
                    return setPos(projX + cmd[1], projY + cmd[2]);

                case "lasso":
                case "lasso2":
                    // 올가미 이미지가 실제로 옮겨졌을 때만 커서가 바뀜 (그 판단은 그려봐야 알 수 있어서 상자 위치가 있으면 바뀐다고 봄)
                    if (cmd[1] === null || cmd[2] === null || cmd[1].length === 0 || cmd[2].length === 0)
                    {
                        return false;
                    }

                    const info:Array = (cmd[3] is Array && cmd[3].length === 7) ? cmd[3] : cmd[4];
                    return (info is Array && info.length >= 7) ? setPos(info[5], info[6]) : false;

                case "mirror":
                case "bgColor":
                case "clear":
                case "clear1":
                case "clear2":
                case "swap":
                case "merge":
                    return setPos(projW / 2, projH / 2);

                case "canvasSize":
                    projW = cmd[1];
                    projH = cmd[2];
                    return setPos(projW / 2, projH / 2);
            }

            return false;
        }
    }
}
