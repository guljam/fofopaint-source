package Modules.ReplayEngine
{
    import Modules.UndoController;
    import Modules.UndoManager;

    public class ReplayState
    {
        private static const REPLAY_FASTEST_TOTAL_TIME:Number = 10;
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
        public static var rLastCanvasBGColor:uint = RCANVAS_BG_COLOR; // load replay에서 씀
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
        public static var lastMirrorReadyFlag:Boolean = false; // 리플레이 저장해줄때 마지막 mirror플래그는 여기서 가져다 씀 저장중간에 기존 mirror ready플래그가 바뀔수도 있기 때문에

        public static var rNowFrame:Number = 0; // dodraw에서 현재까지 플레이된 프레임수 누적, jump frame이 가동됐을때 프레임 누적갯수를 세서 썸네일 이미지 만들어줌
        public static var rPrevFrame:Number = 0; // jump one frame 에서 이전 프레임 탐색할때 이 프레임으로 탐색해줌 tickdraw에서 data 끝의 프레임을 저장함
        public static var rMemoryDataReadON:Boolean = true; // rData읽을때는 true, rfile 읽을때는 false
        public static var rMemoryDataStartIndex:int = 0; // 리플레이에서 프레임 스캡을 앞부분으로 해줄때 rmemory data를 읽는 부분이면 현재 undoindex부분 부터 읽게 인덱스를 올려줌
        public static var rMemoryDataIndex:int = 0; // rData에서만씀 rData 스크로크 뭉치 인덱스
        public static var rFileLastBytePosition:Number = 0; // fs position 저장
        public static var rFileCutBytePosition:Number = 0; // super undo에서 파일 잘라줄때 필요함

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
                UndoController.addContinue();
            }
            else
            {
                if (UndoManager.isDeepUndoEnabled)
                {
                    UndoManager.applyDeepUndo();
                }

                rMemoryDataBuffer.push(["bgColor", color]);
                UndoController.addNew();
            }
        }

       private static function updateLastRMemoryDataCommand(command:String):void
        {
            const index:int = UndoManager.undoDataIndex;
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

            const index:int = UndoManager.undoDataIndex;

            if (rMemoryData[index].length === 1)
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
                        rMemoryData[index].splice(i, 1);
                        break;
                    }
                }

                rMemoryData.splice(index + 1);
                rMemoryDataFrame.splice(index + 1);
                // 복수 명령일때만 해당 프레임수로 갱신함
                rMemoryDataFrame[index] = rMemoryData[index].length;
            }

            updateLastRMemoryDataMirror();
            UndoManager.isDeleteUndoDataPending = false;
            UndoManager.undoDataIndex = rMemoryData.length - 1;
        }

        public static function hasLastRMemoryDataCommand(command:String):Boolean
        {
            const index:int = UndoManager.undoDataIndex;

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
            if (UndoManager.mirrorCommandReady)
            {
                // 마지막 데이터에 1개만의 미러 커맨드가 있으먼 미러를 무효로함 mirror mirror니까 원래대로임
                if (rMemoryData.length > 0 && rMemoryData[rMemoryData.length - 1].length === 1 && rMemoryData[rMemoryData.length - 1][0][0] === "mirror")
                {
                    UndoManager.mirrorCommandReady = false;
                    rMemoryData.pop();
                    rMemoryDataFrame.pop();
                }
                // 그게 아니면 가장 앞에 미러커맨드를 넣어줌
                else if (rMemoryDataBuffer.length > 0 && rMemoryDataBuffer[0][0] !== "mirror")
                {
                    UndoManager.mirrorCommandReady = false;
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
                    UndoManager.mirrorCommandReady = true;
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
