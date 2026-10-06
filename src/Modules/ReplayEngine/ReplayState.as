package Modules.ReplayEngine
{
    import Modules.UndoHistory;
    import Modules.UndoController;
    import flash.utils.Dictionary;
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
        public static var rMemoryDataTimingSheet:Array = []; // rMemoryData와 같은 모양으로 명령마다 기록한 getTimer 값(int)을 저장, 길이는 항상 rMemoryDataFrame과 같음
        private static var rTimingSheetBufferStamps:Dictionary = new Dictionary(true); // 버퍼의 명령(키)이 기록된 getTimer 값, 펜 명령만 넣고 나머지는 묶음이 확정될때 채움
        public static var mirrorCommandReady:Boolean = false; // 다음 버퍼 앞에 mirror 커맨드를 넣어줄지 말지 결정
        public static var lastMirrorReadyFlag:Boolean = false; // 리플레이 저장해줄때 마지막 mirror플래그는 여기서 가져다 씀 저장중간에 기존 mirror ready플래그가 바뀔수도 있기 때문에

        public static var rNowFrame:Number = 0; // dodraw에서 현재까지 플레이된 프레임수 누적, jump frame이 가동됐을때 프레임 누적갯수를 세서 썸네일 이미지 만들어줌
        public static var rPrevFrame:Number = 0; // jump one frame 에서 이전 프레임 탐색할때 이 프레임으로 탐색해줌 tickdraw에서 data 끝의 프레임을 저장함
        public static var rMemoryDataReadON:Boolean = true; // rData읽을때는 true, rfile 읽을때는 false
        public static var rMemoryDataStartIndex:int = 0; // 리플레이에서 프레임 스캡을 앞부분으로 해줄때 rmemory data를 읽는 부분이면 현재 undoindex부분 부터 읽게 인덱스를 올려줌
        public static var rMemoryDataIndex:int = 0; // rData에서만씀 rData 스크로크 뭉치 인덱스
        public static var rFileLastBytePosition:Number = 0; // fs position 저장
        public static var rFileCutBytePosition:Number = 0; // super undo에서 파일 잘라줄때 필요함

        public static function isZeroReplayFrame():Boolean
        {
            return TOTAL_FRAME === 0;
        }

        public static function canStartReplay():Boolean
        {
            return isReplayStarted === false && !isZeroReplayFrame();
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

        // 펜처럼 입력 시각이 중요한 명령에 지금 시각을 기록해두고 그 명령을 그대로 돌려줌
        // 버퍼에 push하는 식 안에서 감싸서 씀: rMemoryDataBuffer.push(ReplayState.stampTimingSheetCommand(["lineTo", x, y]))
        public static function stampTimingSheetCommand(command:Array):Array
        {
            rTimingSheetBufferStamps[command] = TimingSheetFile.packStamp(getTimer(), 0);
            return command;
        }

        // 채우기, 올가미, 이동처럼 도구를 시작해서 끝낼때까지의 시간을 연출로 보여주는 명령에 씀 (명령을 버퍼에 넣는 끝낼 때 부름)
        // 명령의 시각은 도구를 시작한 startStamp(getTimer 값)이고, 지금까지 걸린 시간이 연출 길이로 기록됨
        // pointStamps는 도구 안에서 점을 찍은 때마다의 getTimer 값 (선 도구처럼 점별 시각이 연출에 필요한 명령에만 넘김, 점 개수는 명령의 꼭짓점 수와 같아야 함)
        public static function stampTimingSheetToolCommand(command:Array, startStamp:int, pointStamps:Array = null):Array
        {
            var points:Array = null;

            if (pointStamps !== null && pointStamps.length > 0)
            {
                points = new Array(pointStamps.length);

                for (var i:int = 0;i < pointStamps.length;i++)
                {
                    points[i] = Math.max(0, (pointStamps[i] - startStamp) | 0); // 도구 시작 기준 ms
                }
            }

            rTimingSheetBufferStamps[command] = TimingSheetFile.makeElement(startStamp, (getTimer() - startStamp) | 0, points);
            return command;
        }

        // 버퍼의 명령마다 기록할 값(TimingSheetFile.packStamp 형식)을 순서대로 돌려주고 기록을 비움 (묶음이 메모리 undo 데이터로 들어갈때 부름)
        // 기록하지 않은 명령은 앞 명령의 시각을 따르고(연출 길이는 0), 맨 앞에 기록 없는 명령(mirror 등)이 있으면 처음 기록된 시각을 따름
        // 마지막으로 기록된 명령 뒤의 명령(drawDone 등)은 묶음이 확정된 지금 시각, 기록이 하나도 없는 묶음도 전부 지금 시각
        // 시각은 순서대로 줄어들지 않도록 이전 값보다 작으면 올려줌
        public static function takeTimingSheetBufferTimes():Array
        {
            const now:int = getTimer();
            const count:int = rMemoryDataBuffer.length;
            const times:Array = new Array(count);
            const anims:Array = new Array(count);
            const pointLists:Array = new Array(count); // 점별 시각이 있는 명령의 점 시각 목록, 없으면 null
            var firstStamped:int = -1;
            var lastStamped:int = -1;

            for (var i:int = 0;i < count;i++)
            {
                const stamp:* = rTimingSheetBufferStamps[rMemoryDataBuffer[i]];
                anims[i] = 0;
                pointLists[i] = null;

                if (stamp !== undefined)
                {
                    times[i] = TimingSheetFile.unpackStamp(stamp);
                    anims[i] = TimingSheetFile.unpackAnimMs(stamp);
                    pointLists[i] = TimingSheetFile.pointsOf(stamp);
                    lastStamped = i;

                    if (firstStamped < 0)
                    {
                        firstStamped = i;
                    }
                }
            }

            if (firstStamped < 0)
            {
                for (i = 0;i < count;i++)
                {
                    times[i] = now;
                }
            }
            else
            {
                for (i = 0;i < firstStamped;i++)
                {
                    times[i] = times[firstStamped];
                }

                for (i = firstStamped + 1;i < count;i++)
                {
                    if (i > lastStamped)
                    {
                        times[i] = now;
                    }
                    else if (times[i] === undefined || ((times[i] - times[i - 1]) | 0) < 0)
                    {
                        times[i] = times[i - 1];
                    }
                }
            }

            TimingSmoother.spread(times, rMemoryDataBuffer); // 같은 프레임에 몰린 펜 점의 시각을 나눠서 (끄려면 이 줄을 지우면 됨)

            for (i = 0;i < count;i++)
            {
                times[i] = TimingSheetFile.makeElement(times[i], anims[i], pointLists[i]);
            }

            rTimingSheetBufferStamps = new Dictionary(true);
            return times;
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

                rMemoryDataBuffer.push(["bgColor", color]);
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
                    rMemoryDataTimingSheet[index][i] = TimingSheetFile.packStamp(getTimer(), 0);
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

            if (rMemoryData[index].length === 1)
            {
                rMemoryData.splice(index);
                rMemoryDataFrame.splice(index);
                rMemoryDataTimingSheet.splice(index);
            }
            else
            {
                for (var i:int = rMemoryData[index].length - 1;i >= 0;i--)
                {
                    if (command === rMemoryData[index][i][0])
                    {
                        rMemoryData[index].splice(i, 1);
                        rMemoryDataTimingSheet[index].splice(i, 1);
                        break;
                    }
                }

                rMemoryData.splice(index + 1);
                rMemoryDataFrame.splice(index + 1);
                rMemoryDataTimingSheet.splice(index + 1);
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
                    rMemoryDataTimingSheet.pop();
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
                    rMemoryDataTimingSheet.pop();
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
