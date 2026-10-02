package Modules.ReplayEngine
{
    import Modules.UndoHistory;
    import Modules.UndoController;
    import flash.utils.getTimer;

    public class ReplayState
    {
        public static var REPLAY_MAX_SPEED:Number = 0.0;

        public static const REPLAY_IMAGE_CAHCHE_COMPLETE:int = (1 << 0);
        public static const REPLAY_IMAGE_CAHCHE_PROCESSING:int = (1 << 1);
        public static var RCANVAS_WIDTH:Number = 600;
        public static var RCANVAS_HEIGHT:Number = 390;
        public static var RCANVAS_BG_COLOR:uint = 0xFFFFFF;
        public static var TOTAL_FRAME:Number = 0; // rdata+file 프레임 전부 합친거
        public static var isReplayStarted:Boolean = false; // 리플레이 시작버튼 여러번 누르는거 방지
        public static var isReplayFinished:Boolean = true; // 리플레이가 자연히 끝났을때 올려주는 플래그 가장 처음에 캔버스 싹쓸이 하기 위해서 넣어줌.
        public static var isReplayFinishedWithFiwWindow:Boolean = false; // 리플레이가 follow cursor옵션으로 캔버스 작게 축소되서 끝났을때
        public static var isReplayModeON:Boolean = false; // 이건 모드 자체 껐다 켰다
        public static var isReplayRepeatON:Boolean = true; // 리플레이 반복 켜기 끄기

        private static var rFileDataTotalFrame:Number = 0; // file에저장된 프레임수 누적해서 저장

        public static var rLastLayer2Selcted:Boolean = false; // 리플레이 실행할때 이걸로 비교해서 캔버스 스왑해줌
        public static var rReplaySpeedMultipler:Number = 1; // 리플레이 속도 for루프로 2번씩혹은 3번씩 읽히게 만듬
        public static var rAirBrushSize:int = 0; // 레거시지원 변수
        public static var rAirBrushSize2:int = 0; // 새로운거
        public static var rMirrorON:Boolean = false; // 대칭 켜지면 올려줌
        public static var rCanvasZoomMultiplier:Number = 1.0; // 리플레이 줌
        public static var rLastCanvasZoomMultiplier:Number = 1.0; // 리플레이에서 수동줌하면 여기다가 저장해줌
        public static var rCanvasZoomIndex:int = 4;
        public static var isReplayCanvasFitToWindow:Boolean = false; // 리플레이에서 오른쪽 클릭해서 창 크기에 맞췄을때 올려줌 startreplay될때 줌 1.0으로 리셋 못시키게함
        public static var rReplayImageCacheState:int = REPLAY_IMAGE_CAHCHE_COMPLETE;
        public static var isReplaySlideShowMode:Boolean = false; // doDrawSlowEvent가 켜지면 올려줌
        public static var rMemoryDataBuffer:Array = []; // draw layer에서 그려준 데이터를 이쪽으로 다모아줌
        public static var rMemoryData:Array = []; // rDataBuffer가 이쪽으로 이동되고 undo image data갯수에 똑같이맞추어줌
        public static var rMemoryDataFrame:Array = []; // rdata안에 몇프레임이 들어있는지 저장
        public static var mirrorCommandReady:Boolean = false; // 다음 버퍼 앞에 mirror 커맨드를 넣어줄지 말지 결정
        public static var lastMirrorReadyFlag:Boolean = false; // 리플레이 저장해줄때 마지막 mirror플래그는 여기서 가져다 씀 저장중간에 기존 mirror ready플래그가 바뀔수도 있기 때문에

        public static var rNowFrame:Number = 0; // dodraw에서 현재까지 플레이된 프레임수 누적, jump frame이 가동됐을때 프레임 누적갯수를 세서 썸네일 이미지 만들어줌
        public static var rPrevFrame:Number = 0; // jump one frame 에서 이전 프레임 탐색할때 이 프레임으로 탐색해줌 tickdraw에서 data 끝의 프레임을 저장함
        public static var rMemoryDataReadON:Boolean = true; // rData읽을때는 true, rfile 읽을때는 false
        public static var rMemoryDataStartIndex:int = 0; // 리플레이에서 프레임 스캡을 앞부분으로 해줄때 rmemory data를 읽는 부분이면 현재 undoindex부분 부터 읽게 인덱스를 올려줌
        public static var rMemoryDataIndex:int = 0; // rData에서만씀 rData 스크로크 뭉치 인덱스
        public static var rFileLastBytePosition:Number = 0; // fs position 저장
        public static var rFileCutBytePosition:Number = 0; // super undo에서 파일 잘라줄때 필요함

        // 실시간 녹화: 명령 사이 기본 간격은 1틱, 다를때만 ["wait", 틱]을 그 명령 앞에 넣음
        // wait 0이면 앞 명령과 같은 프레임, 구버전 데이터는 wait가 없어서 명령 1개 = 1틱으로 재생됨
        public static const WAIT_COMMAND:String = "wait";
        // 1틱 = 앱의 스테이지 1프레임(24fps, 컴파일러 기본값). 구버전 데이터가 지금처럼 1프레임에 명령 1개로 재생되게 함
        // 저장 형식의 단위라서 나중에 스테이지 프레임레이트를 바꿔도 이 값은 바꾸면 안됨
        public static const WAIT_TICK_MS:Number = 1000 / 24;
        public static const WAIT_MAX_TICK:int = 168; // 7초 이상 쉰 시간은 7초로 기록
        private static var lastCommandTime:int = -1; // 마지막으로 기록한 명령의 getTimer, -1이면 첫 명령 앞에 wait를 넣지 않음
        private static var bufferStartTime:int = -1; // 버퍼 첫 명령의 getTimer, 뭉치 안의 틱은 이 시간 기준으로 반올림
        private static var bufferLastTick:int = 0; // 버퍼 안에서 마지막 명령의 틱 (bufferStartTime 기준)
        private static var bufferPrevCommandTime:int = -1; // 버퍼를 버릴때 lastCommandTime을 되돌릴 값

        // 그리기 명령은 이 함수로 버퍼에 넣어야 실시간 간격이 기록됨
        public static function pushCommand(command:Array):void
        {
            const now:int = getTimer();

            if (rMemoryDataBuffer.length === 0)
            {
                // 뭉치 사이 간격은 직전 명령 시간과의 차이
                bufferPrevCommandTime = lastCommandTime;
                bufferStartTime = now;
                bufferLastTick = 0;

                if (lastCommandTime >= 0)
                {
                    pushWait(Math.round((now - lastCommandTime) / WAIT_TICK_MS));
                }
            }
            else
            {
                // 뭉치 안에서는 첫 명령 기준 시간을 반올림해서 프레임 지터로 0, 2가 번갈아 생기지 않게 함
                const tick:int = Math.round((now - bufferStartTime) / WAIT_TICK_MS);
                pushWait(tick - bufferLastTick);
                bufferLastTick = tick;
            }

            rMemoryDataBuffer.push(command);
            lastCommandTime = now;
        }

        private static function pushWait(delay:int):void
        {
            if (delay < 0)
            {
                delay = 0;
            }
            else if (delay > WAIT_MAX_TICK)
            {
                delay = WAIT_MAX_TICK;
            }

            if (delay !== 1)
            {
                rMemoryDataBuffer.push([WAIT_COMMAND, delay]);
            }
        }

        // undo에 들어가지 않고 버려지는 버퍼, 버려진 명령 시간은 다음 간격 계산에 쓰지 않음
        public static function clearCommandBuffer():void
        {
            if (rMemoryDataBuffer.length > 0)
            {
                lastCommandTime = bufferPrevCommandTime;
            }

            rMemoryDataBuffer = [];
        }

        // 새 파일, 파일 불러오기처럼 작업이 끊기는 곳에서 호출, 다음 첫 명령 앞에는 wait가 들어가지 않음
        public static function resetCommandTime():void
        {
            lastCommandTime = -1;
        }

        public static function isWaitCommand(command:Array):Boolean
        {
            return command !== null && command[0] === WAIT_COMMAND;
        }

        // 채우기 애니메이션: fill5, drawDone5 바로 뒤에 ["fillanim", 영역 높이(px)]를 넣음
        // 실시간 재생에서만 그 영역을 배경색 덮개로 가렸다가 위에서부터 지워서 보여줌, 그 외(탐색, undo, 캐시 생성)에서는 아무것도 안 함
        // 시간은 높이로 정하고 재생 속도와 상관없이 실제 시간(ms)으로 흐름, 틱 시계와 별개라서 타임라인 틱 합에 넣지 않고 따로 셈
        public static const FILL_ANIM_COMMAND:String = "fillanim";
        public static var FILL_ANIM_MIN_MS:Number = 200; // 높이 0일때 애니메이션 시간
        public static var FILL_ANIM_MAX_MS:Number = 2000; // FILL_ANIM_FULL_HEIGHT 이상일때 애니메이션 시간
        public static var FILL_ANIM_FULL_HEIGHT:Number = 600; // 이 높이 이상은 최대 시간, 그 아래는 높이에 비례

        public static function isFillAnimCommand(command:Array):Boolean
        {
            return command !== null && command[0] === FILL_ANIM_COMMAND;
        }

        // 그리는게 없는 명령 (wait, fillanim), 1프레임 이동에서 건너뛰고 캐시 이미지 간격에도 세지 않음
        public static function isNonDrawCommand(command:Array):Boolean
        {
            return command !== null && (command[0] === WAIT_COMMAND || command[0] === FILL_ANIM_COMMAND);
        }

        // 영역 높이로 정한 애니메이션 시간(ms), 재생 속도와 상관없음
        public static function getFillAnimMs(height:Number):Number
        {
            const t:Number = Math.max(0, Math.min(1, height / FILL_ANIM_FULL_HEIGHT));
            return FILL_ANIM_MIN_MS + (FILL_ANIM_MAX_MS - FILL_ANIM_MIN_MS) * t;
        }

        // pushCommand와 달리 wait를 앞에 붙이지 않고 시간도 기록하지 않음 (drawDone5 바로 뒤에 붙어야 하기 때문)
        public static function pushFillAnim(height:Number):void
        {
            rMemoryDataBuffer.push([FILL_ANIM_COMMAND, height]);
        }

        // 그리기 명령 수 (wait, fillanim 제외)
        public static function getDrawCommandCount(commands:Array):int
        {
            var count:int = 0;

            for (var i:int = 0;i < commands.length;i++)
            {
                if (!isNonDrawCommand(commands[i]))
                {
                    count++;
                }
            }

            return count;
        }

        // undo index까지의 프레임 합을 구함
        public static function getRMemoryDataTotalFrame(index:int):Number
        {
            if (index < 0)
            {
                return 0;
            }

            var sum:Number = 0;

            for (var i:int = 0;i <= index;i++)
            {
                sum += rMemoryDataFrame[i];
            }

            return sum;
        }

        public static function increaseRFileDataTotalFrame(count:Number):void
        {
            rFileDataTotalFrame += count;
        }

        public static function getRFileDataTotalFrame():Number
        {
            return rFileDataTotalFrame;
        }

        public static function setRFileDataTotalFrame(frame:Number):void
        {
            rFileDataTotalFrame = frame;
        }

        public static function syncRNowFrameWithTotalFrame():void
        {
            ReplayState.rPrevFrame = ReplayState.rNowFrame;
            ReplayState.rNowFrame = getTotalFrame();
        }

        public static function getNowFrameUntilUndoIndex(index:int):Number
        {
            return getRFileDataTotalFrame() + getRMemoryDataTotalFrame(index);
        }

        public static function getTotalFrame():Number
        {
            return getNowFrameUntilUndoIndex(rMemoryDataFrame.length - 1);
        }

        public static function addUndoBGColorData(color:uint):void
        {
            if (hasLastRMemoryDataCommand("bgColor"))
            {
                rMemoryDataBuffer.push(["bgColor", color]);
                updateLastRMemoryDataCommand("bgColor");
                UndoHistory.addContinue();
            }
            else
            {
                if (UndoController.isDeepUndoEnabled)
                {
                    UndoController.applyDeepUndo();
                }

                pushCommand(["bgColor", color]);
                UndoHistory.addNew();
            }
        }

       private static function updateLastRMemoryDataCommand(command:String):void
        {
            const index:int = UndoHistory.undoDataIndex;
            if (index < 0 || index >= rMemoryData.length)
            {
                return;
            }

            const arr:Array = rMemoryData[index];
            for (var i:int = 0; i < arr.length; i++)
            {
                if (arr[i][0] === command)
                {
                    arr[i] = rMemoryDataBuffer[0].concat();
                    rMemoryDataBuffer = [];
                    rMemoryDataFrame[index] = arr.length;
                    return;
                }
            }
        }

        public static function deleteLastRMemoryDataCommand(command:String):void
        {
            if (rMemoryData.length === 0)
            {
                return;
            }

            const index:int = UndoHistory.undoDataIndex;

            // 앞에 붙은 wait는 세지 않음, 지울 명령만 남은 뭉치는 통째로 지움
            if (getDrawCommandCount(rMemoryData[index]) === 1)
            {
                rMemoryData.splice(index);
                rMemoryDataFrame.splice(index);
            }
            else
            {
                for (var i:int = rMemoryData[index].length - 1;i >= 0;i--)
                {
                    if (command === rMemoryData[index][i][0])
                    {
                        // 이 명령 앞의 wait도 같이 지워야 쓸모없는 대기가 남지 않음
                        const removeStart:int = (i > 0 && isWaitCommand(rMemoryData[index][i - 1])) ? i - 1 : i;
                        rMemoryData[index].splice(removeStart, i - removeStart + 1);
                        break;
                    }
                }

                rMemoryData.splice(index + 1);
                rMemoryDataFrame.splice(index + 1);
                // 복수 명령일때만 해당 프레임수로 갱신함
                rMemoryDataFrame[index] = rMemoryData[index].length;
            }

            updateLastRMemoryDataMirror();
            UndoHistory.setUndoDataIndex(rMemoryData.length - 1);
        }

        public static function hasLastRMemoryDataCommand(command:String):Boolean
        {
            const index:int = UndoHistory.undoDataIndex;

            if (rMemoryData.length > 0 && index >= 0)
            {
                const len:uint = rMemoryData[index].length;

                for (var i:uint = 0;i < len;i++)
                {
                    if (command === rMemoryData[index][i][0])
                    {
                        return true;
                    }
                }
            }

            return false;
        }

        public static function isGeneratingCacheImages():Boolean
        {
            return rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_PROCESSING;
        }

        // 미러가 되어있는지 확인해서 mirror커맨드를 무조건 앞으로 보냄
        // 그게 아니면 미러 커맨드 지워줌
        public static function updateLastRMemoryDataMirror():void
        {
            if (mirrorCommandReady)
            {
                // 마지막 데이터에 1개만의 미러 커맨드가 있으먼 미러를 무효로함 mirror mirror니까 원래대로임
                if (rMemoryData.length > 0 && rMemoryData[rMemoryData.length - 1].length === 1 && rMemoryData[rMemoryData.length - 1][0][0] === "mirror")
                {
                    mirrorCommandReady = false;
                    rMemoryData.pop();
                    rMemoryDataFrame.pop();
                }
                // 그게 아니면 가장 앞에 미러커맨드를 넣어줌
                else if (rMemoryDataBuffer.length > 0 && rMemoryDataBuffer[0][0] !== "mirror")
                {
                    mirrorCommandReady = false;
                    rMemoryDataBuffer.unshift(["mirror"]);
                }
            }
            else
            {
                // 미러 커맨드가 꺼져있는데 독립인 미러커맨드가 있으면 지워주고 미러 커맨드 플래그를 올려줘서 다음번에
                // 미러 커맨드가 가장 앞에 오도록함
                if (rMemoryData.length > 0 && rMemoryData[rMemoryData.length - 1].length === 1 && rMemoryData[rMemoryData.length - 1][0][0] === "mirror")
                {
                    rMemoryData.pop();
                    rMemoryDataFrame.pop();
                    mirrorCommandReady = true;
                }
                // 그게 아니면 그냥 지워줌
                else if (rMemoryDataBuffer.length > 0 && rMemoryDataBuffer[0][0] === "mirror")
                {
                    rMemoryDataBuffer.shift();
                }
            }
        }
    }
}
