package Modules
{
    import Modules.Tools.LassoTool;
    import Modules.Tools.PenTool;

    import flash.desktop.Clipboard;
    import flash.desktop.ClipboardFormats;
    import flash.desktop.NativeDragManager;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.CapsStyle;
    import flash.display.DisplayObject;
    import flash.display.IBitmapDrawable;
    import flash.display.JointStyle;
    import flash.display.LineScaleMode;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.NativeDragEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.filters.BlurFilter;
    import flash.filters.GlowFilter;
    import flash.geom.ColorTransform;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.ui.Mouse;
    import flash.utils.ByteArray;
    import flash.utils.getTimer;
    import Symbols.FOFOCursorSet;

    public class ReplayController
    {
        // todo r캔버스는 따로 분리해야함, r캔버스 줌 회전 툴등 조작하는것도 분리해야함
        // 일부 접근자 private로 변경했는데 모듈 완전히 분리하고 나서 해야함 오류나는것들 점검
        // todo 리플레이 저장형식을 바이너리로 다시 대체, 실시간 입력 기반으로 각 프레임마다 그리지 말고 실제 시간 지연을 녹화
        // todo 리플레이 실행중일때 탐색바만 나오는데 리플레이 속도 조절할수있게 같이 나오게 해야함 ui고민
        // todo playback speed 키보드로 조정할때 힌트 박스를 topbar 아래쪽으로 직관적으로 보이게 조정
        // todo 탐색바 힌트를 표시한 채로 f1으로 드로우 모드에 진입하면 테두리랑 힌트가 남음
        // todo 버그 발견, mirror가 된 상태에서 뒷프레임을 잘라주고 나서 재생하면 미러 적용이 안된 상태에서 다시 그려주는 버그가있음
        // todo 그런데 컷 잘라주면 다시 0프레임부터 시작되는데 아까는 왜 중간부터 시작되었는지 모르겠음
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
            drawReplayByCommand = cDrawReplayDataCommands();
            drawCanvasFromReplayData = cDrawReplayData();
            rFollowMouse = cReplayFollowMouse();
            replayHideCursor = cReplayHideCursor();
        }

        public static var drawReplayByCommand:Object;
        private static var drawCanvasFromReplayData:Function;
        public static var rFollowMouse:Object;
        private static var replayHideCursor:Object;

        private static const JUMP_FRAME_PLAY:int = (1 << 0);
        public static const JUMP_FRAME_MANUAL:int = (1 << 1);
        private static const JUMP_FRAME_PREV:int = (1 << 2);
        private static const JUMP_FRAME_NEXT:int = (1 << 3);

        private static const REPLAY_FASTEST_TOTAL_TIME:Number = 10;
        public static const REPLAY_DISK_CACHE_FRAME_INTERVAL:Number = 10000;
        private static const REPLAY_MEMORY_CACHE_FRAME_INTERVAL:Number = 700;
        private static const REPLAY_SLIDESHOW_ACTIVE_SPEED:Number = 60;
        private static const REPLAY_SLIDESHOW_FRAME_RATE:Number = 2; // 1/2초 = 0.5초마다 갱신
        private static const REPLAY_SLIDESHOW_UPDATE_TIME:Number = 1000 / REPLAY_SLIDESHOW_FRAME_RATE;
        private static var REPLAY_MAX_SPEED:Number = 0.0;

        public static const REPLAY_IMAGE_CAHCHE_COMPLETE:int = (1 << 0);
        public static const REPLAY_IMAGE_CAHCHE_READY:int = (1 << 1);
        public static const REPLAY_IMAGE_CAHCHE_PROCESSING:int = (1 << 2);
        public static var RCANVAS_WIDTH:Number = 600;
        public static var RCANVAS_HEIGHT:Number = 390;
        public static var RCANVAS_BG_COLOR:uint = 0xFFFFFF;
        private static var TOTAL_FRAME:Number = 0; // rdata+file 프레임 전부 합친거

        // 리플레이
        public static var repFileTemp:File; // 파일을 저장하거나 불러올때 씀
        public static var rFileStream:FileStream = new FileStream(); // 함수들을 왔다갔다 해야해서 전역으로 하나
        public static var rCanvasAnchorPoint:Sprite = new Sprite(); // 회전 스프라이트 부모
        public static var rCanvasPanel:Sprite = new Sprite();
        public static var rCanvasDrawLayer:Sprite = new Sprite();
        public static var rCanvasDrawShape:Shape = new Shape();
        private static var rCanvasCompleteAnchorPoint:Sprite = new Sprite(); // 리플레이에어 이미지가 재생되었을때 보여주는 객체 stage와 가로세로 중앙정렬
        public static var rCanvasLayer1BitmapData:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
        public static var rCanvasLayer2BitmapData:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
        private static var rCanvasDrawLayerBitmapData:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
        public static var rCanvasLayer1Bitmap:Bitmap = new Bitmap(rCanvasLayer1BitmapData, "auto", true);
        public static var rCanvasLayer2Bitmap:Bitmap = new Bitmap();
        private static var rCanvasCompleteBitmap:Bitmap = new Bitmap(new BitmapData(1, 1, false, 0), "auto", true);
        private static var rCanvasDrawLayerBitmap:Bitmap = new Bitmap(rCanvasDrawLayerBitmapData, "auto", true);
        public static var rReplayFOFOCursor:FOFOCursorSet = new FOFOCursorSet(); // 재생할때 틀어주는 작은 마우스 커서
        public static var rCanvasDrawLayerClipRectLegacy:Rectangle = new Rectangle(); // 갱신된 부분만 그려주는 거 오래된 버전 지원때문에 남겨둠
        public static var rCanvasDrawLayerClipRect:Rectangle = new Rectangle(); // 갱신된 부분만 그려주는 거 이게 새거임
        private static var updatePrograssBarStartTime:int = 0; // 리플레이 시작 시간저장 update prograss bar에서 프레임 오차 수정할때 참고하는 변수
        public static var isReplayStarted:Boolean = false; // 리플레이 시작버튼 여러번 누르는거 방지
        public static var isReplayFinished:Boolean = true; // 리플레이가 자연히 끝났을때 올려주는 플래그 가장 처음에 캔버스 싹쓸이 하기 위해서 넣어줌.
        public static var isReplayFinishedWithFiwWindow:Boolean = false; // 리플레이가 follow cursor옵션으로 캔버스 작게 축소되서 끝났을때
        public static var isReplayModeON:Boolean = false; // 이건 모드 자체 껐다 켰다
        private static var isReplayRepeatON:Boolean = true; // 리플레이 반복 켜기 끄기
        public static var rDataBuffer:Array = []; // draw layer에서 그려준 데이터를 이쪽으로 다모아줌
        public static var rData:Array = []; // rDataBuffer가 이쪽으로 이동되고 undo image data갯수에 똑같이맞추어줌
        public static var rDataFrame:Array = []; // rdata안에 몇프레임이 들어있는지 저장
        public static var rDataReadFlag:Boolean = true; // rData읽을때는 true, rfile 읽을때는 false
        public static var rFileLastBytePosition:Number = 0; // fs position 저장
        private static var rFileCutBytePosition:Number = 0; // super undo에서 파일 잘라줄때 필요함
        public static var rDataIndex:int = 0; // rData에서만씀 rData 스크로크 뭉치 인덱스
        private static var rDataStartIndex:int = 0; // 리플레이에서 프레임 스캡을 앞부분으로 해줄때 rdata를 읽는 부분이면 현재 undoindex부분 부터 읽게 인덱스를 올려줌
        private static var rLastLayer2Selcted:Boolean = false; // 리플레이 실행할때 이걸로 비교해서 캔버스 스왑해줌
        public static var rLastCanvasBGColor:uint = RCANVAS_BG_COLOR; // load replay에서 씀
        private static var rReplaySpeedMultipler:Number = 1; // 리플레이 속도 for루프로 2번씩혹은 3번씩 읽히게 만듬
        public static var rAirBrushSize:int = 0; // 레거시지원 변수
        public static var rAirBrushSize2:int = 0; // 새로운거
        public static var rNowFrame:Number = 0; // dodraw에서 현재까지 플레이된 프레임수 누적, jump frame이 가동됐을때 프레임 누적갯수를 세서 썸네일 이미지 만들어줌
        public static var rPrevFrame:Number = 0; // jump one frame 에서 이전 프레임 탐색할때 이 프레임으로 탐색해줌 tickdraw에서 data 끝의 프레임을 저장함
        public static var rFirstImageLayer1BitmapData:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
        public static var rFirstImageLayer2BitmapData:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
        public static var rFirstImageBGColor:uint = CanvasController.CANVAS_BG_COLOR;
        public static var rMirrorON:Boolean = false; // 대칭 켜지면 올려줌
        public static var rCanvasZoomMultiplier:Number = 1.0; // 리플레이 줌
        public static var rLastCanvasZoomMultiplier:Number = 1.0; // 리플레이에서 수동줌하면 여기다가 저장해줌
        public static var rCanvasZoomIndex:int = 4;
        public static var isReplayCanvasFitToWindow:Boolean = false; // 리플레이에서 오른쪽 클릭해서 창 크기에 맞췄을때 올려줌 startreplay될때 줌 1.0으로 리셋 못시키게함
        private static var rJumpImageIndexLast:int = -2; // 썸네일 인덱스 바뀌면 여기다 저장
        private static var rJumpImageNowFrameLast:Number = -1;
        private static var rCachedImageLastIndex:int = -2; // 마지막에 그려준 캐쉬 이미지 번호를 저장
        private static var rTempCachedLastImageIndex:int = -2; // 더 잘게 쪼개준 이미지 인덱스 바뀌면 여기다 저장
        public static var rJumpImageFrameData:Array = [0]; // 스킵이미지 저장될때 r file frame sum을 저장해줌 처음에 rfirstimage라서 0번 추가해줌
        public static var rReplayImageCacheState:int = REPLAY_IMAGE_CAHCHE_COMPLETE;
        private static var rReplayRestartTimerCount:uint = 0; // 리스타트 타이머
        private static var rSeekbarTextUpdateTime:int = 0; // 프레임 바 딜레이
        private static var isReplaySlideShowMode:Boolean = false; // doDrawSlowEvent가 켜지면 올려줌
        private static var rFrameTempCachedImages:Array = []; // 이전 탐색 프레임 빠르게 하기 위해서 jumpimage구간에서 더 잘게 이미지를 나누어주고 정보를여가다가 저장함
        public static var lastReplayTimeBoxYPos:Number = 0; // 리플레이 재생해줄때 WorkspaceView.topbar 사라지게 할때 원래 위치 저장해서 끝나면 이 위치로 복원해줌

        public static function isGeneratingCacheImages():Boolean
        {
            return rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_PROCESSING;
        }

        public static function addInputEventsDrawModeOrReplayMode():void
        {
            if (isReplayModeON)
            {
                InputController.addInputEventsReplayMode();
            }
            else
            {
                InputController.addInputEventsDrawMode();
            }
        }

        public static function getReplayFileNameFromPath(path:String):String
        {
            return path.substr(0, path.lastIndexOf(".png")) + ".2020";
        }

        // 드로우 모드와 리플레이 모드 캔버스 미러가 다를경우 undo 적용 이후에 mirror커맨드 넣어주도록 함
        public static function checkMirrorCanvasReplayMirror():void
        {
            if (CanvasController.isCanvasMirrored !== rMirrorON)
            {
                UndoManager.mirrorCommandReady = true;
                CanvasController.mirrorDrawModeBitmapData();
                CanvasGridOverlay.updateGridMirror(CanvasController.isCanvasMirrored);
                main.mirrorRCursorPos();
            }
            else if (UndoManager.mirrorCommandReady)
            {
                UndoManager.mirrorCommandReady = false;
            }
        }

        public static function isLayer2SelectedReplayMode():Boolean
        {
            return rCanvasPanel.getChildIndex(rCanvasDrawLayer) < rCanvasPanel.getChildIndex(rCanvasLayer1Bitmap);
        }

        public static function toggleLayerCaptureMode(layer:int):void
        {
            MainUI.topBar.capClipBoard.alpha = 1.0;
            const replayMode:Boolean = isReplayModeON;
            var bitmap:Bitmap = replayMode
                ? (layer == 1 ? rCanvasLayer1Bitmap : rCanvasLayer2Bitmap)
                : (layer == 1 ? CanvasController.canvasLayer1Bitmap : CanvasController.canvasLayer2Bitmap);
            var button:DisplayObject = (layer == 1)
                ? MainUI.topBar.capLayer1VisibleButton
                : MainUI.topBar.capLayer2VisibleButton;
            var otherButton:DisplayObject = (layer == 1)
                ? MainUI.topBar.capLayer2VisibleButton
                : MainUI.topBar.capLayer1VisibleButton;
            if (bitmap.visible)
            {
                bitmap.visible = false;
                button.alpha = Global.OFFALPHA;
                if (replayMode)
                {
                    if ((layer == 1 && !isLayer2SelectedReplayMode())
                            || (layer == 2 && isLayer2SelectedReplayMode()))
                    {
                        rCanvasDrawLayer.visible = false;
                    }
                }
                if (otherButton.alpha < 1.0)
                {
                    toggleLayerCaptureMode((layer == 1) ? 2 : 1);
                }
            }
            else
            {
                bitmap.visible = true;
                button.alpha = 1.0;
                if (replayMode)
                {
                    if ((layer == 1 && !isLayer2SelectedReplayMode())
                            || (layer == 2 && isLayer2SelectedReplayMode()))
                    {
                        rCanvasDrawLayer.visible = true;
                    }
                }
            }
            CaptureController.captureAreaManager.updateDrawArea();
        }

        public static function addUndoBGColorData(color:uint):void
        {
            if (hasLastRDataCommand("bgColor"))
            {
                rDataBuffer.push(["bgColor", color]);
                updateLastRDataCommand("bgColor");
                UndoManager.addUndoData.addContinue();
            }
            else
            {
                if (UndoManager.isDeepUndoEnabled)
                {
                    UndoManager.applyDeepUndo();
                }
                rDataBuffer.push(["bgColor", color]);
                UndoManager.addUndoData.addNew();
            }
        }

        private static function updateLastRDataCommand(command:String):void
        {
            if (rData.length === 0)
                return;
            const arr:Array = rData[rData.length - 1];
            if (arr.length === 1)
            {
                rData[rData.length - 1] = rDataBuffer.concat();
                rDataBuffer = [];
            }
            else
            {
                for (var i:uint = 0;i < arr.length;i++)
                {
                    if (command === arr[i][0])
                    {
                        // rdata버퍼가 배열이기 때문에 concat을 하면 배열안에 배열이 있어서 0번만 반환해줌
                        // buffer.concat -> [["data",11]] //이런식으로 반환이됨
                        arr[i] = rDataBuffer[0].concat();
                        rDataBuffer = [];
                        break;
                    }
                }
            }
            rDataFrame[rDataFrame.length - 1] = rData[rData.length - 1].length;
        }

        public static function deleteLastRDataCommand(command:String):void
        {
            if (rData.length === 0)
            {
                return;
            }
            const index:int = UndoManager.undoDataIndex;
            if (rData[index].length === 1)
            {
                rData.splice(index);
                rDataFrame.splice(index);
            }
            else
            {
                const len:uint = rData[index].length;
                for (var i:uint = 0;i < len;i++)
                {
                    if (command === rData[index][i][0])
                    {
                        rData[index].splice(i, 1);
                        --i;
                    }
                }
                rData.splice(index + 1);
                rDataFrame.splice(index + 1);
            }
            UndoManager.isDeleteUndoDataPending = false;
            UndoManager.addUndoData.updateLastRDataMirror();
            UndoManager.undoDataIndex = rData.length - 1;
        }

        public static function hasLastRDataCommand(command:String):Boolean
        {
            const index:int = UndoManager.undoDataIndex;
            if (rData.length > 0 && index >= 0)
            {
                const len:uint = rData[index].length;
                for (var i:uint = 0;i < len;i++)
                {
                    if (command === rData[index][i][0])
                    {
                        return true;
                    }
                }
            }
            return false;
        }

        private static function cReplayHideCursor():Object
        {
            var isMouseHided:Boolean = false;
            var count:int = 0;
            const pos:Point = new Point(0, 0);
            const frameRate:Number = main.stage.frameRate;
            function isMouseMoved():Boolean
            {
                return pos.x !== main.stage.mouseX || pos.y !== main.stage.mouseY || CanvasController.isMouseLeftClicked || CanvasController.isRightMouseClicked;
            }
            function updateMousePos():void
            {
                pos.setTo(main.stage.mouseX, main.stage.mouseY);
            }
            function show():void
            {
                Mouse.show();
                isMouseHided = false;
                count = 0;
            }
            function check():void
            {
                if (isMouseHided)
                {
                    if (isMouseMoved())
                    {
                        count = 0;
                        show();
                    }
                }
                else
                {
                    if (count > frameRate)
                    {
                        count = frameRate;
                        if (!MainUI.isHighlightBoxVisible())
                        {
                            Mouse.hide();
                            MainUI.hideBottomHint();
                            isMouseHided = true;
                            updateMousePos();
                        }
                    }
                    else
                    {
                        count++;
                    }
                    if (isMouseMoved())
                    {
                        count = 0;
                    }
                    updateMousePos();
                }
            }
            return {
                    check: check,
                    show: show
                };
        }

        private static function restoreZoomReplayMode():void
        {
            rCanvasZoomIndex = CanvasController.getNearZoomIndex(rLastCanvasZoomMultiplier);
            CanvasController.updateCanvasScale(CanvasController.canvasZoomMultiplerList[rCanvasZoomIndex], true);
            rFollowMouse.updateBounds();
        }
        public static function resetZoomReplayMode():void
        {
            const center:Point = MainUIController.getStageCenterPos("replay");
            rLastCanvasZoomMultiplier = 1.0;
            rCanvasZoomIndex = CanvasController.canvasZoomMultiplerList.indexOf(1.0);
            CanvasController.moveCanvasAnchorPoint(center.x, center.y, true);
            CanvasController.updateCanvasScale(1.0, true);
            setFitReplayCanvasToViewportOFF();
            rFollowMouse.updateBounds();
        }

        // drawdone에서 줌된 blur사이즈가 아니 1배율 블러를 적용해야 제대로 되기 때문에 이거해줌
        private static function blurReplayCanvasByDefaultValue():void
        {
            const blurSize:Number = CanvasController.getBlurSize(rAirBrushSize, 1.0);
            const blurf:BlurFilter = new BlurFilter(blurSize, blurSize, 3);
            rCanvasDrawShape.filters = [blurf];
        }
        private static function resetBlurReplayCanvas():void
        {
            rAirBrushSize = 0;
            rCanvasDrawShape.filters = [];
        }

        public static function blurReplayCanvasByValue(size:Number):void
        {
            const blurSize:Number = CanvasController.getBlurSize(size, rCanvasZoomMultiplier);
            const blurf:BlurFilter = new BlurFilter(blurSize, blurSize, 3);
            rAirBrushSize = size;
            rCanvasDrawShape.filters = [blurf];
        }

        public static function clearDataAndResetVars():void
        {
            FileManager.isContinueSaveON = false;
            rLastCanvasBGColor = CanvasController.CANVAS_BG_COLOR;
            rMirrorON = false;
            CanvasController.isCanvasMirrored = false;
            rDataReadFlag = false;
            UndoManager.mirrorCommandReady = false;
            UndoManager.addUndoData.setRFileTotalFrame(0);
            updateTotalFrameAndReplayMaxSpeedFor10Sec(0);
            rReplayImageCacheState = REPLAY_IMAGE_CAHCHE_COMPLETE;
            CanvasController.isLayerSwapped = false;
            ReferenceLayerController.resetRefLayerImageTransform();
            ReferenceLayerController.resetRefLayerMenuOpacity();
            initializeReplayDataFile(true);
            resetReplaySpeedBar();
            resetReplayTime();
            UndoManager.resetUndoState();
            CaptureController.resetCaptureCanvasChangeValue();
            FileManager.updateLastFilePathByRandomFileName();
            CanvasController.canvasInfoBox.setMirror(false);
            MainUIController.updateWindowTitle();
            InputController.removeKeyRepeatEvents(null);
        }
        private static function copyReplayCanvasDataToDrawCanvas():void
        {
            const lineStyleSave:Array = drawReplayByCommand.getrLineStyleSave();
            // if(!lineStyleSave) return;
            var newColorTransform:ColorTransform = new ColorTransform(1, 1, 1, lineStyleSave[0]);
            rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
            rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
            if (isLayer2SelectedReplayMode())
            {
                rCanvasLayer2BitmapData.draw(rCanvasDrawLayerBitmap, null, newColorTransform, lineStyleSave[1]);
            }
            else
            {
                rCanvasLayer1BitmapData.draw(rCanvasDrawLayerBitmap, null, newColorTransform, lineStyleSave[1]);
            }
            // 캔버스 2번 지워줘야함
            rCanvasDrawShape.graphics.clear();
            rCanvasDrawLayerBitmapData.fillRect(new Rectangle(0, 0, rCanvasDrawLayerBitmapData.width, rCanvasDrawLayerBitmapData.height), 0);
            CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, rCanvasLayer1BitmapData, CanvasController.canvasLayer1Bitmap);
            CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, rCanvasLayer2BitmapData, CanvasController.canvasLayer2Bitmap);
            CanvasController.updateCavnvasSizeDrawMode(CanvasController.canvasLayer1Bitmap.width, CanvasController.canvasLayer1Bitmap.height);
            ColorPickerController.updateCanvasBGColorDrawMode(RCANVAS_BG_COLOR);
            CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
                ImageViewWindow.updateCanvasWindowBitmapSize();
            }
        }
        private static function syncDrawCanvasWithReplayCanvas():void
        {
            CanvasController.canvasZoomMultipler = rCanvasZoomMultiplier;
            CanvasController.canvasZoomIndex = rCanvasZoomIndex;
            CanvasController.canvasAnchorPoint.x = Math.floor(rCanvasAnchorPoint.x); // 뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
            CanvasController.canvasAnchorPoint.y = Math.floor(rCanvasAnchorPoint.y);
            CanvasController.canvasAnchorPoint.scaleX = rCanvasAnchorPoint.scaleX;
            CanvasController.canvasAnchorPoint.scaleY = rCanvasAnchorPoint.scaleY;
            CanvasController.canvasAnchorPoint.rotation = rCanvasAnchorPoint.rotation;
            CanvasController.canvasPanel.x = Math.floor(rCanvasPanel.x);
            CanvasController.canvasPanel.y = Math.floor(rCanvasPanel.y);
            ReplayController.setRcursorRotation(rCanvasAnchorPoint.rotation);
        }
        private static function ensureReplayCanvasState():void
        {
            const rNowFrameBackup:Number = rNowFrame;
            renderReplayFrame(0, JUMP_FRAME_MANUAL);
            renderReplayFrame(rNowFrameBackup, JUMP_FRAME_MANUAL);
            CanvasController.isCanvasMirrored = rMirrorON;
            UndoManager.mirrorCommandReady = false;
            CanvasController.canvasInfoBox.setMirror(rMirrorON);
        }
        public static function deleteReplayDataBeforeCurrentFrame():void
        {
            // 미러 되어있을 수도 있기 때문에 워래 프레임 으로 점프해준뒤에 실행해줌
            ensureReplayCanvasState();
            MainUI.seekBarBox.setDeleteRangeBarVisible(false);
            createFirstImageCache(rCanvasLayer1BitmapData, rCanvasLayer2BitmapData, RCANVAS_BG_COLOR);
            const fs:FileStream = new FileStream();
            if (rDataReadFlag)
            {
                // repfile 초기화
                UndoManager.addUndoData.updateUndoBaseImageFromReplayMode();
                fs.open(FileManager.replayDataFilePath, FileMode.WRITE); // 파일 생성
                fs.close();
                FileManager.isFileAlreadySaved = false;
                FileManager.enableNewFileButton();
                UndoManager.addUndoData.setRFileTotalFrame(0);
                rData.splice(0, rDataIndex + 1);
                rDataFrame.splice(0, rDataIndex + 1);
                updateTotalFrameAndReplayMaxSpeedFor10Sec(getTotalFrame());
                updateReplayPrograssText(true, TOTAL_FRAME);
                if (TOTAL_FRAME === 0)
                {
                    MainUI.seekBarBox.resetReplayPrograssBarWidth();
                }
                else
                {
                    MainUI.seekBarBox.setReplayPrograssBarMaxWidth();
                }
                MainUI.topBar.repNewFileButton.alpha = Global.OFFALPHA;
                rReplayFOFOCursor.visible = false;
            }
            else
            {
                // make jumpimage에서 변경해주기 때문에
                if (repFileTemp.exists) // 이미 있으면 지워주고
                {
                    repFileTemp.deleteFile();
                }
                var ba:ByteArray = new ByteArray();
                var d:Array;
                // 짤라서 ba에 넣어주기
                fs.open(FileManager.replayDataFilePath, FileMode.READ);
                fs.position = rFileLastBytePosition;
                fs.readBytes(ba, 0, fs.bytesAvailable);
                fs.close();
                // ba에 넣어준걸 다시 써주기
                fs.open(FileManager.replayDataFilePath, FileMode.WRITE);
                fs.position = 0;
                fs.writeBytes(ba, 0, ba.length);
                fs.close();
                ba.clear();
                ba = null;
                rReplayFOFOCursor.visible = false;
                MainUI.seekBarBox.resetReplayPrograssBarWidth();
                FileManager.isFileAlreadySaved = false;
                startGeneratingReplayCacheImage();
            }
            resetReplaySpeedBar();
            isReplayFinished = true;
            if (UndoManager.undoDataIndex > rData.length - 1)
            {
                UndoManager.undoDataIndex = rData.length - 1;
            }
            UndoManager.undoToIndex(UndoManager.undoDataIndex);
            UndoManager.disableDeepUndo();
            updateReplayPrograssBarAndText();
            updateReplaySpeedSliderAlpha();
            drawReplayByCommand.setFirstRCursorPosCurrent();
            ReferenceLayerController.resetRefLayerImageTransform();
        }
        public static function deleteReplayDataAfterCurrentFrame():void
        {
            ensureReplayCanvasState();
            MainUI.seekBarBox.setDeleteRangeBarVisible(false);
            if (rDataReadFlag === true)
            {
                // 위에서 setJumpOneFrame을 해줘서 rindex가 증가되었기 때문에
                // 실제 undo해줘야할 인덱스는 -1해줘야하는거임
                UndoManager.undoToIndex(rDataIndex);
                rData.splice(rDataIndex + 1);
                rDataFrame.splice(rDataIndex + 1);
                updateTotalFrameAndReplayMaxSpeedFor10Sec(getTotalFrame());
                resetReplayTime();
            }
            else if (rDataReadFlag === false)
            {
                drawReplayByCommand.setFirstRCursorPosCurrent();
                const fs:FileStream = new FileStream();
                fs.open(FileManager.replayDataFilePath, FileMode.UPDATE);
                fs.position = rFileLastBytePosition;
                fs.truncate(); // 데이터 위에 짤라주고
                fs.close();
                // 썸네일 이미지도 날려줌
                const rNowFrameSave:Number = rNowFrame;
                const list:Array = FileManager.replayCacheImageFolderPath.getDirectoryListing();
                const index:Number = getCachedFrameImageIndex(rNowFrameSave);
                // index번 이후 파일 삭제
                for (var i:uint = 0, len:uint = list.length;i < len;i++)
                {
                    if (parseInt(list[i].name) > index)
                    {
                        list[i].deleteFile();
                    }
                }
                // framedata도 인덱스 이후꺼 날려줌
                rJumpImageFrameData.splice(index + 1);
                UndoManager.addUndoData.setRFileTotalFrame(rNowFrameSave);
                updateTotalFrameAndReplayMaxSpeedFor10Sec(rNowFrameSave);
                CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, rCanvasLayer1BitmapData, CanvasController.canvasLayer1Bitmap);
                CanvasController.canvasLayer1Bitmap.bitmapData = CanvasController.canvasLayer1BitmapData;
                CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, rCanvasLayer2BitmapData, CanvasController.canvasLayer2Bitmap);
                CanvasController.canvasLayer2Bitmap.bitmapData = CanvasController.canvasLayer2BitmapData;
                // mirrorON = rMirrorON;
                // UndoManager.mirrorCommandReady = false;
                // appInfoBox.setMirror(rMirrorON);
                CanvasController.updateCavnvasSizeDrawMode(CanvasController.canvasLayer1Bitmap.width, CanvasController.canvasLayer1Bitmap.height, 0, 0, false);
                ColorPickerController.updateCanvasBGColorDrawMode(RCANVAS_BG_COLOR);
                resetReplayTime();
                syncDrawCanvasWithReplayCanvas();
                UndoManager.resetUndoState();
                CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
                if (ImageViewWindow.isCanvasWindowON)
                {
                    ImageViewWindow.updateCanvasWindowImage();
                    ImageViewWindow.updateCanvasWindowBitmapSize();
                }
            }
            updateReplayPrograssBarAndText();
            updateReplaySpeedSliderAlpha();
            updateDeleteReplayDataButtonsState();
            resetReplaySpeedBar();
            UndoManager.disableDeepUndo();
            ReferenceLayerController.resetRefLayerImageTransform();
            if (SidebarController.isQuickSidebarActive)
            {
                SidebarController.deactivateQuickSidebar();
            }
            FileManager.isContinueSaveON = false;
        }
        public static function createNewFileFromReplayCanvas():void
        {
            MainUI.seekBarBox.setDeleteRangeBarVisible(false);
            copyReplayCanvasDataToDrawCanvas();
            clearDataAndResetVars();
            syncDrawCanvasWithReplayCanvas();
            exitReplayMode();
            UndoManager.disableDeepUndo();
            resetReplayTime();
            ReferenceLayerController.resetRefLayerImageTransform();
        }

        public static function prepareDeleteReplayData(mode:String):Boolean
        {
            if (mode !== "total")
            {
                if (drawReplayByCommand.getCurrentPosition() < drawReplayByCommand.getDataLength())
                {
                    finalizeRemainingReplayData();
                    updateReplayPrograssText();
                    MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(rNowFrame / TOTAL_FRAME);
                    updateDeleteReplayDataButtonsState();
                }
                if (rNowFrame >= TOTAL_FRAME)
                {
                    MainUI.seekBarBox.setDeleteRangeBarVisible(false);
                    return true;
                }
            }
            MainUI.seekBarBox.updateDeleteDangeBarPosWidth(mode);
            return false;
        }
        public static function initializeReplayDataFile(overWrite:Boolean = false):void // 기본 리플레이 파일 만들어줌
        {
            FileManager.initializeRepTempFile();
            if (FileManager.replayDataFilePath.exists === false || overWrite === true)
            {
                const fs:FileStream = new FileStream();
                fs.open(FileManager.replayDataFilePath, FileMode.WRITE);
                fs.close();
                createFirstImageCache(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
            }
        }
        private static function drawFirstJumpImage():void
        {
            const fs:FileStream = new FileStream();
            const file:File = FileManager.replayCacheImageFolderPath.resolvePath("0");
            fs.open(file, FileMode.READ);
            const data:Array = fs.readObject() as Array;
            fs.close();
            data[0].uncompress();
            data[1].uncompress();
            var layer1:BitmapData = new BitmapData(data[2], data[3], true, 0);
            var layer2:BitmapData = new BitmapData(data[2], data[3], true, 0);
            const newRectangle:Rectangle = new Rectangle(0, 0, data[2], data[3]);
            layer1.lock();
            layer1.setPixels(newRectangle, data[0]);
            layer1.unlock();
            layer2.lock();
            layer2.setPixels(newRectangle, data[1]);
            layer2.unlock();
            rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, layer1, rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, layer2, rCanvasLayer2Bitmap);
            layer1.dispose();
            layer2.dispose();
            layer1 = null;
            layer2 = null;
            updateCanvasSizeReplayMode(rCanvasLayer1Bitmap.width, rCanvasLayer1Bitmap.height);
            updateCanvasBGColorReplayMode(data[4]);
        }
        private static function createFirstImageCache(bmpd1:BitmapData, bmpd2:BitmapData, bgColor:uint):void
        {
            if (FileManager.replayCacheImageFolderPath.exists)
            {
                FileManager.replayCacheImageFolderPath.deleteDirectory(true);
            }
            FileManager.replayCacheImageFolderPath.createDirectory();
            const fs:FileStream = new FileStream();
            var ba1:ByteArray = new ByteArray();
            var ba2:ByteArray = new ByteArray();
            const w:Number = bmpd1.width;
            const h:Number = bmpd1.height;
            const newRectangle:Rectangle = new Rectangle(0, 0, w, h);
            rJumpImageFrameData.length = 0;
            bmpd1.copyPixelsToByteArray(newRectangle, ba1);
            ba1.compress();
            rFirstImageLayer1BitmapData = CanvasController.updateBitmapData(rFirstImageLayer1BitmapData, bmpd1, null);
            if (bmpd2 === null)
                bmpd2 = new BitmapData(w, h, true, 0);
            bmpd2.copyPixelsToByteArray(newRectangle, ba2);
            ba2.compress();
            rFirstImageLayer2BitmapData = CanvasController.updateBitmapData(rFirstImageLayer2BitmapData, bmpd2, null);
            rFirstImageBGColor = bgColor;
            createCacheImage(ba1, ba2, w, h, bgColor, 0, 0, false);
            ba1.clear();
            ba2.clear();
        }

        public static function setReplayCompleteCanvasCenter():void
        {
            rCanvasCompleteAnchorPoint.width = main.stage.stageWidth + 200;
            rCanvasCompleteAnchorPoint.height = main.stage.stageHeight + 200;
            rCanvasCompleteAnchorPoint.x = main.stage.stageWidth / 2;
            rCanvasCompleteAnchorPoint.y = main.stage.stageHeight / 2;
            rCanvasCompleteBitmap.x = -rCanvasCompleteBitmap.width / 2;
            rCanvasCompleteBitmap.y = -rCanvasCompleteBitmap.height / 2;
        }
        private static function hideCompleteImageToBGReplayMode():void
        {
            if (MainUI.stageBG.getChildByName("rCanvasCompleteAnchorPoint"))
            {
                MainUI.stageBG.removeChild(rCanvasCompleteAnchorPoint);
            }
            if (rCanvasCompleteBitmap.bitmapData)
            {
                rCanvasCompleteBitmap.bitmapData.dispose();
            }
            rCanvasCompleteBitmap.filters = [];
            rCanvasPanel.filters = [];
        }
        private static function showCompleteImageToBGReplayMode():void
        {
            const mergedbmpd:BitmapData = CanvasController.getMergedBitmapdtata(false, true, true, null);
            const tmpbmpd:BitmapData = new BitmapData(mergedbmpd.width / 2, mergedbmpd.height / 2, false, 0);
            const mat:Matrix = new Matrix();
            mat.scale(0.5, 0.5);
            var alpha:ColorTransform = new ColorTransform(1, 1, 1, 0.8);
            tmpbmpd.draw(mergedbmpd, mat, alpha);
            rCanvasCompleteBitmap.bitmapData = tmpbmpd;
            rCanvasCompleteBitmap.filters = [new BlurFilter(15, 15, 3)];
            setReplayCompleteCanvasCenter();
            var glow:GlowFilter = new GlowFilter();
            glow.color = 0xFFFFFF; // 빨간색 테두리
            glow.alpha = 0.5;
            glow.blurX = 20;
            glow.blurY = 20;
            glow.strength = 2;
            glow.quality = 3;
            rCanvasPanel.filters = [glow];
            MainUI.stageBG.addChild(rCanvasCompleteAnchorPoint);
        }
        private static function replayCompleteEffect():void
        {
            CanvasController.fitCanvasToViewportMargin(isReplayCanvasFitToWindow);
            CanvasController.applyCanvasFlashEffect(rCanvasPanel, 0, 0, RCANVAS_WIDTH, RCANVAS_HEIGHT, function ():Boolean
                {
                    return MainUI.topBar.visible;
                });
        }
        public static function cancelReplayRestartTimer():void
        {
            MainUI.seekBarBox.setPlayButtonVisible(true);
            hideCompleteImageToBGReplayMode();
            MainUI.showTopbarOnReplayEnd();
            FOFOTimer.remove("replayRestartTimer");
            updateReplayPrograssText(true, TOTAL_FRAME);
            Global.setColorTransform(MainUI.seekBarBox.prograssBar, Global.getUIReplayEndBarColor());
            CanvasController.updateCanvasScale(rLastCanvasZoomMultiplier, true);
        }
        public static function isReplayRestartTimerON():Boolean
        {
            return FOFOTimer.hasTimer("replayRestartTimer");
        }
        public static function startReplayRestartTimer():void
        {
            Global.setColorTransform(MainUI.seekBarBox.prograssBar, Global.getUIReplayRestartBarColor());
            if (isReplayRepeatON)
            {
                rReplayRestartTimerCount = 20;
                FOFOTimer.addByName("replayRestartTimer", 1.0, true, function ():Boolean
                    {
                        if (rReplayRestartTimerCount === 0)
                        {
                            cancelReplayRestartTimer();
                            handleReplayStartButton();
                            return false;
                        }
                        MainUI.seekBarBox.prograssInfo.text = HintStrings.getReplayRestartHintString(rReplayRestartTimerCount);
                        --rReplayRestartTimerCount;
                        return true;
                    });
            }
            else
            {
                rReplayRestartTimerCount = 0;
                updateReplayPrograssText(true, TOTAL_FRAME);
            }
        }
        public static function resetReplaySpeedBar():void
        {
            rReplaySpeedMultipler = 1.0; // 속도 리셋
            MainUI.topBar.replaySpeedSliderCursor.x = MainUI.topBar.replaySpeedSlider.x + 1.5;
        }
        // total frame file max frame등등은 수동으로 초기화
        // 이건 리플레이 시간을 초기화 시켜주는것 뿐임 데이터는 건드리지 않음
        public static function resetReplayTime():void
        {
            // 어떤 이유가 있어서 rDataReadFlag는 여기 넣으면 안됨 수동으로 조절
            rDataIndex = 0;
            rDataStartIndex = 0;
            rFileLastBytePosition = 0;
            rNowFrame = 0;
            rPrevFrame = 0;
            rJumpImageIndexLast = -2;
            rJumpImageNowFrameLast = -1;
            rTempCachedLastImageIndex = -2;
            isReplayFinished = true;
            isReplaySlideShowMode = false;
            drawReplayByCommand.clearData();
        }

        public static function selectReplaySubLayer(flag:Boolean):void
        {
            rLastLayer2Selcted = flag;
            if (flag)
            {
                if (rCanvasPanel.getChildIndex(rCanvasDrawLayer) > rCanvasPanel.getChildIndex(rCanvasLayer1Bitmap))
                {
                    rCanvasPanel.setChildIndex(rCanvasDrawLayer, rCanvasPanel.getChildIndex(rCanvasLayer1Bitmap));
                }
            }
            else if (rCanvasPanel.getChildIndex(rCanvasDrawLayer) < rCanvasPanel.getChildIndex(rCanvasLayer1Bitmap))
            {
                rCanvasPanel.setChildIndex(rCanvasDrawLayer, rCanvasPanel.getChildIndex(rCanvasLayer1Bitmap));
            }
        }
        public static function moveImageReplayMode(x:Number, y:Number, layer1:Boolean, layer2:Boolean):void
        {
            var tmpbmpd:BitmapData = new BitmapData(RCANVAS_WIDTH, RCANVAS_HEIGHT, true, 0);
            var movedMat:Matrix = new Matrix();
            if (!layer1 && !layer2)
            {
                layer1 = true;
                layer2 = true;
            }
            movedMat.translate(x, y);
            if (layer1)
            {
                tmpbmpd.draw(rCanvasLayer1BitmapData, movedMat);
                rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, tmpbmpd, rCanvasLayer1Bitmap);
            }
            if (layer2)
            {
                tmpbmpd.fillRect(new Rectangle(0, 0, RCANVAS_WIDTH, RCANVAS_HEIGHT), 0);
                tmpbmpd.draw(rCanvasLayer2BitmapData, movedMat);
                rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, tmpbmpd, rCanvasLayer2Bitmap);
            }
            tmpbmpd.dispose();
            tmpbmpd = null;
        }
        public static function replayLineStyleReady(shape:Boolean, size:uint, color:uint, alpha:Number):void
        {
            rCanvasDrawLayer.alpha = alpha;
            if (shape)
            {
                rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.SQUARE, JointStyle.ROUND);
            }
            else
            {
                rCanvasDrawShape.graphics.lineStyle(size, color);
            }
        }

        public static function replayLineStyleReady2(shape:Boolean, size:uint, color:uint, alpha:Number):void
        {
            rCanvasDrawLayer.alpha = alpha;
            if (shape)
            {
                rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.SQUARE, JointStyle.BEVEL);
            }
            else
            {
                rCanvasDrawShape.graphics.lineStyle(size, color);
            }
        }
        public static function replayLineStyleReady3(shape:Boolean, size:uint, color:uint, alpha:Number):void
        {
            rCanvasDrawLayer.alpha = alpha;
            if (shape)
            {
                rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.BEVEL);
            }
            else
            {
                rCanvasDrawShape.graphics.lineStyle(size, color);
            }
        }
        public static function mirrorCanvasReplayMode():void
        {
            var tmpbmpd:BitmapData = new BitmapData(RCANVAS_WIDTH, RCANVAS_HEIGHT, true, 0);
            var flipMat:Matrix = new Matrix(-1, 0, 0, 1, RCANVAS_WIDTH);
            tmpbmpd.draw(rCanvasLayer1BitmapData, flipMat);
            rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, tmpbmpd, rCanvasLayer1Bitmap);
            tmpbmpd.fillRect(new Rectangle(0, 0, RCANVAS_WIDTH, RCANVAS_HEIGHT), 0);
            tmpbmpd.draw(rCanvasLayer2BitmapData, flipMat);
            rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, tmpbmpd, rCanvasLayer2Bitmap);
            tmpbmpd.dispose();
            tmpbmpd = null;
            rMirrorON = !rMirrorON;
            if (isReplayCanvasFitToWindow)
            {
                fitReplayCanvasToViewport();
            }
        }
        public static function cDrawReplayDataCommands():Object
        {
            const rCursorPos:Point = new Point(0, 0);
            // undo인덱스가 처음일때 tickdraw가 아무것도 안해주니까 위치 갱신이 안되서
            // undorefimage갱신 될때 마다 마지막 포인터 위치 저장해주는거
            const rCursorPosFirst:Point = new Point(-1, -1);
            var lineStyleBackup:Array = [1.0, null];
            // tempdone에서 쓰는 플래그임
            var index:uint = 0;
            var data:Array = []; // 데이터 뭉치
            const cmd:Vector.<int> = new Vector.<int>();
            const pos:Vector.<Number> = new Vector.<Number>();
            function updateLineStyleBackup(alpha:Number, blendMode:String):void
            {
                lineStyleBackup[0] = alpha;
                lineStyleBackup[1] = blendMode;
            }
            function getFirstRCursorPos():Point
            {
                return rCursorPosFirst;
            }
            function resetFirstRCursorPos():void
            {
                rCursorPosFirst.setTo(-1, -1);
            }
            function setFirstRCursorPos(x:Number, y:Number):void
            {
                rCursorPosFirst.setTo(x, y);
            }
            function setFirstRCursorPosCurrent():void
            {
                rCursorPosFirst.setTo(rCursorPos.x, rCursorPos.y);
            }
            function hasRCursorFirstPos():Boolean
            {
                return rCursorPosFirst.x > 0 && rCursorPosFirst.y > 0;
            }
            function updateRCursorPosToFirst():void
            {
                rReplayFOFOCursor.x = rCursorPosFirst.x;
                rReplayFOFOCursor.y = rCursorPosFirst.y;
            }
            function updateRCursorPos():void
            {
                rReplayFOFOCursor.x = rCursorPos.x;
                rReplayFOFOCursor.y = rCursorPos.y;
            }

            function setRCursorPosFromMoveTool(x:Number, y:Number):void
            {
                setRCursorPos(rCursorPos.x + x, rCursorPos.y + y);
            }
            function setRCursorPosToCenter():void
            {
                setRCursorPos(RCANVAS_WIDTH / 2, RCANVAS_HEIGHT / 2);
            }
            function setRCursorPos(x:Number, y:Number):void
            {
                if (x < 0)
                    x = 0;
                else if (x > RCANVAS_WIDTH)
                    x = RCANVAS_WIDTH;
                if (y < 0)
                    y = 0;
                else if (y > RCANVAS_HEIGHT)
                    y = RCANVAS_HEIGHT;
                rCursorPos.setTo(x, y);
            }
            function getRCursorPos():Point
            {
                return rCursorPos;
            }
            function clearData():void
            {
                data = [];
                index = 0;
            }
            function setData(refData:Array, startIndex:uint = 0):void
            {
                data = refData;
                index = startIndex;
            }
            function getRemainingData():uint
            {
                if (!data)
                    return 0;
                return data.length - index;
            }
            function isReadFinished():Boolean
            {
                if (!data)
                    return true;
                return index > data.length - 1;
            }
            function getDataLength():uint
            {
                if (!data)
                    return 0;
                return data.length;
            }
            function getCurrentPosition():uint
            {
                return index;
            }
            function setIndex(newIndex:uint):void
            {
                index = newIndex;
            }
            function getLineStyleAlpha():Number
            {
                return lineStyleBackup[0];
            }
            function getrLineStyleSave():Array
            {
                if (lineStyleBackup.length !== 2)
                    return [1.0, null];
                return lineStyleBackup;
            }
            function drawAll():void
            {
                var len:uint = data.length;
                for (var i:uint = 0;i < len;i++)
                {
                    drawNext();
                }
            }
            function checkAirBrush(airBrushFlag:Boolean, size:uint):void
            {
                if (airBrushFlag === true)
                {
                    if (rAirBrushSize !== size)
                        blurReplayCanvasByValue(size);
                }
                else if (rAirBrushSize > 0)
                {
                    resetBlurReplayCanvas();
                }
            }
            function checkSubLayer(subLayerFlag:Boolean):void
            {
                if (subLayerFlag)
                {
                    // if((replayStartON && subLayerFlag) !== false && rSubLayerSave !== subLayerFlag)
                    if (rLastLayer2Selcted !== subLayerFlag)
                    {
                        selectReplaySubLayer(subLayerFlag);
                    }
                }
                else if (rLastLayer2Selcted)
                {
                    selectReplaySubLayer(false);
                }
            }
            function lineStyle5(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const blendMode:String = data[7];
                const fillpen:Boolean = data[8];
                const subLayer:Boolean = data[9];
                const airBrushSize:Number = data[10];
                updateLineStyleBackup(alpha, blendMode);
                checkSubLayer(subLayer);
                rAirBrushSize2 = airBrushSize;
                if (fillpen)
                {
                    rCanvasDrawShape.graphics.clear();
                    replayLineStyleReady2(false, 1, color, 1.0);
                    rCanvasDrawShape.graphics.beginFill(color);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                    rCanvasDrawLayer.alpha = alpha;
                }
                else
                {
                    replayLineStyleReady3(shape, size, color, alpha);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                }
                if (index === 0)
                {
                    CanvasController.resetRCanvasDrawLayerCliprect2();
                }
                else
                {
                    updateRCanvasDrawLayerCliprect2();
                }
            }
            function lineStyle4(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const blendMode:String = data[7];
                const fillpen:Boolean = data[8];
                const subLayer:Boolean = data[9];
                const airBrush:Boolean = data[10];
                updateLineStyleBackup(alpha, blendMode);
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                if (fillpen)
                {
                    rCanvasDrawShape.graphics.clear();
                    replayLineStyleReady2(false, 1, color, 1.0);
                    rCanvasDrawShape.graphics.beginFill(color);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                    rCanvasDrawLayer.alpha = alpha;
                }
                else
                {
                    replayLineStyleReady3(shape, size, color, alpha);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                }
                if (index === 0)
                {
                    CanvasController.resetRCanvasDrawLayerCliprect();
                }
                else
                {
                    CanvasController.updateRCanvasDrawLayerCliprect();
                }
            }
            function lineStyle3(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const blendMode:String = data[7];
                const fillpen:Boolean = data[8];
                const subLayer:Boolean = data[9];
                const airBrush:Boolean = data[10];
                updateLineStyleBackup(alpha, blendMode);
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                if (!fillpen)
                {
                    replayLineStyleReady3(shape, size, color, alpha);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                }
                else
                {
                    rCanvasDrawShape.graphics.clear();
                    replayLineStyleReady2(false, 1, color, 1.0);
                    rCanvasDrawShape.graphics.beginFill(color);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                    rCanvasDrawLayer.alpha = alpha;
                }
            }
            function lineStyle2(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const blendMode:String = data[7];
                const fillpen:Boolean = data[8];
                const subLayer:Boolean = data[9];
                const airBrush:Boolean = data[10];
                updateLineStyleBackup(alpha, blendMode);
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                if (!fillpen)
                {
                    replayLineStyleReady2(shape, size, color, alpha);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                }
                else
                {
                    rCanvasDrawShape.graphics.clear();
                    replayLineStyleReady2(false, 1, color, 1.0);
                    rCanvasDrawShape.graphics.beginFill(color);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                    rCanvasDrawLayer.alpha = alpha;
                }
            }
            function lineStyle(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const blendMode:String = data[7];
                const fillpen:Boolean = data[8];
                const subLayer:Boolean = data[9];
                const airBrush:Boolean = data[10];
                updateLineStyleBackup(alpha, blendMode);
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                if (!fillpen)
                {
                    replayLineStyleReady(shape, size, color, alpha);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                }
                else
                {
                    rCanvasDrawShape.graphics.clear();
                    replayLineStyleReady(false, 1, color, 1.0);
                    rCanvasDrawShape.graphics.beginFill(color);
                    rCanvasDrawShape.graphics.moveTo(startX, startY);
                    rCanvasDrawLayer.alpha = alpha;
                }
            }
            function lineTo(data:Array):void
            {
                const x:Number = data[1];
                const y:Number = data[2];
                rCanvasDrawShape.graphics.lineTo(x, y);
                setRCursorPos(x, y);
            }
            function sqline(data:Array):void
            {
                const size:Number = data[1];
                const color:Number = data[2];
                const alpha:Number = data[3];
                const blendMode:String = data[4];
                const command:Vector.<int> = data[5];
                const xyData:Vector.<Number> = data[6];
                rCanvasDrawLayerBitmap.bitmapData = null;
                rCanvasDrawLayerBitmapData.dispose();
                rCanvasDrawLayerBitmapData = new BitmapData(RCANVAS_WIDTH, RCANVAS_HEIGHT, true, 0);
                rCanvasDrawShape.graphics.clear();
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.SQUARE, JointStyle.ROUND);
                rCanvasDrawShape.graphics.drawPath(command, xyData);
                setRCursorPos(xyData[xyData.length - 2], xyData[xyData.length - 1]);
            }
            function fill5(data:Array):void
            {
                const color:Number = data[1];
                const alpha:Number = data[2];
                const blendMode:String = data[3];
                const command:Vector.<int> = data[4];
                const xyData:Vector.<Number> = data[5];
                const airBrushFlag:Boolean = data[6];
                const airBrushSize:uint = data[7];
                rAirBrushSize2 = airBrushSize;
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.clear();
                rCanvasDrawShape.graphics.lineStyle(1, color);
                rCanvasDrawShape.graphics.beginFill(color);
                rCanvasDrawShape.graphics.drawPath(command, xyData);
                setRCursorPos(xyData[xyData.length - 2], xyData[xyData.length - 1]);
                CanvasController.resetRCanvasDrawLayerCliprect2();
            }
            function fill4(data:Array):void
            {
                const color:Number = data[1];
                const alpha:Number = data[2];
                const blendMode:String = data[3];
                const command:Vector.<int> = data[4];
                const xyData:Vector.<Number> = data[5];
                const airBrushFlag:Boolean = data[6];
                const airBrushSize:uint = data[7];
                checkAirBrush(airBrushFlag, airBrushSize);
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.clear();
                rCanvasDrawShape.graphics.lineStyle(1, color);
                rCanvasDrawShape.graphics.beginFill(color);
                rCanvasDrawShape.graphics.drawPath(command, xyData);
                setRCursorPos(xyData[xyData.length - 2], xyData[xyData.length - 1]);
                CanvasController.resetRCanvasDrawLayerCliprect();
            }
            function fill3(data:Array):void
            {
                const color:Number = data[1];
                const alpha:Number = data[2];
                const blendMode:String = data[3];
                const command:Vector.<int> = data[4];
                const xyData:Vector.<Number> = data[5];
                const airBrushFlag:Boolean = data[6];
                const airBrushSize:uint = data[7];
                checkAirBrush(airBrushFlag, airBrushSize);
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.clear();
                rCanvasDrawShape.graphics.lineStyle(1, color);
                rCanvasDrawShape.graphics.beginFill(color);
                rCanvasDrawShape.graphics.drawPath(command, xyData);
                setRCursorPos(xyData[xyData.length - 2], xyData[xyData.length - 1]);
            }
            function fill2(data:Array):void
            {
                const color:Number = data[1];
                const alpha:Number = data[2];
                const blendMode:String = data[3];
                const arr:Vector.<Number> = data[4];
                const len:uint = arr.length;
                resetBlurReplayCanvas();
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.clear();
                rCanvasDrawShape.graphics.lineStyle(1, color);
                rCanvasDrawShape.graphics.beginFill(color);
                rCanvasDrawShape.graphics.moveTo(arr[0], arr[1]);
                for (var i:uint = 2;i < len;i += 2)
                {
                    rCanvasDrawShape.graphics.lineTo(arr[i], arr[i + 1]);
                }
                rCanvasDrawShape.graphics.endFill();
                setRCursorPos(arr[len - 2], arr[len - 1]);
            }
            function fill(data:Array):void
            {
                const color:Number = data[1];
                const alpha:Number = data[2];
                const blendMode:String = data[3];
                const command:Vector.<int> = data[4];
                const xyData:Vector.<Number> = data[5];
                resetBlurReplayCanvas();
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.clear();
                rCanvasDrawShape.graphics.lineStyle(1, color);
                rCanvasDrawShape.graphics.beginFill(color);
                rCanvasDrawShape.graphics.drawPath(command, xyData);
                setRCursorPos(xyData[xyData.length - 2], xyData[xyData.length - 1]);
            }
            function dot4(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const blendMode:String = data[7];
                const subLayer:Boolean = data[8];
                const airBrushSize:Number = data[9];
                const rotation:Number = data[10];
                checkSubLayer(subLayer);
                rAirBrushSize2 = airBrushSize;
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.lineStyle(0, 0, 0);
                rCanvasDrawShape.graphics.beginFill(color);
                if (shape)
                {
                    cmd.length = 0;
                    pos.length = 0;
                    const halfSize:Number = size / 2;
                    var point:Point = Utils.rotatePoint(-halfSize, -halfSize, rotation);
                    cmd.push(1);
                    pos.push(startX + point.x);
                    pos.push(startY + point.y);
                    point = Utils.rotatePoint(halfSize, -halfSize, rotation);
                    cmd.push(2);
                    pos.push(startX + point.x);
                    pos.push(startY + point.y);
                    point = Utils.rotatePoint(halfSize, halfSize, rotation);
                    cmd.push(2);
                    pos.push(startX + point.x);
                    pos.push(startY + point.y);
                    point = Utils.rotatePoint(-halfSize, halfSize, rotation);
                    cmd.push(2);
                    pos.push(startX + point.x);
                    pos.push(startY + point.y);
                    rCanvasDrawShape.graphics.drawPath(cmd, pos);
                    point = null;
                }
                else
                {
                    rCanvasDrawShape.graphics.drawCircle(startX, startY, size / 2);
                }
                rCanvasDrawShape.graphics.endFill();
                CanvasController.resetRCanvasDrawLayerCliprect2();
                setRCursorPos(startX, startY);
            }
            function dot3(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const blendMode:String = data[7];
                const subLayer:Boolean = data[8];
                const airBrush:Boolean = data[9];
                const rotation:Number = data[10];
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.lineStyle(0, 0, 0);
                rCanvasDrawShape.graphics.beginFill(color);
                if (shape)
                {
                    cmd.length = 0;
                    pos.length = 0;
                    const p0:Point = Utils.rotatePoint(-size / 2, -size / 2, rotation);
                    cmd.push(1);
                    pos.push(startX + p0.x);
                    pos.push(startY + p0.y);
                    const p1:Point = Utils.rotatePoint(+size / 2, -size / 2, rotation);
                    cmd.push(2);
                    pos.push(startX + p1.x);
                    pos.push(startY + p1.y);
                    const p2:Point = Utils.rotatePoint(+size / 2, +size / 2, rotation);
                    cmd.push(2);
                    pos.push(startX + p2.x);
                    pos.push(startY + p2.y);
                    const p3:Point = Utils.rotatePoint(-size / 2, +size / 2, rotation);
                    cmd.push(2);
                    pos.push(startX + p3.x);
                    pos.push(startY + p3.y);
                    rCanvasDrawShape.graphics.drawPath(cmd, pos);
                }
                else
                {
                    rCanvasDrawShape.graphics.drawCircle(startX, startY, size / 2);
                }
                rCanvasDrawShape.graphics.endFill();
                CanvasController.resetRCanvasDrawLayerCliprect();
                setRCursorPos(startX, startY);
            }
            function dot2(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const blendMode:String = data[7];
                const subLayer:Boolean = data[8];
                const airBrush:Boolean = data[9];
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.lineStyle(0, 0, 0);
                rCanvasDrawShape.graphics.beginFill(color);
                if (shape)
                    rCanvasDrawShape.graphics.drawRect(startX - size / 2, startY - size / 2, size, size);
                else
                    rCanvasDrawShape.graphics.drawCircle(startX, startY, size / 2);
                rCanvasDrawShape.graphics.endFill();
                CanvasController.resetRCanvasDrawLayerCliprect();
                setRCursorPos(startX, startY);
            }
            function dot(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const blendMode:String = data[7];
                const subLayer:Boolean = data[8];
                const airBrush:Boolean = data[9];
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                rCanvasDrawShape.graphics.lineStyle(0, 0, 0);
                rCanvasDrawShape.graphics.beginFill(color);
                if (shape)
                    rCanvasDrawShape.graphics.drawRect(startX - size / 2, startY - size / 2, size, size);
                else
                    rCanvasDrawShape.graphics.drawCircle(startX, startY, size / 2);
                rCanvasDrawShape.graphics.endFill();
                setRCursorPos(startX, startY);
            }
            function line3(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const endX:Number = data[7];
                const endY:Number = data[8];
                const blendMode:String = data[9];
                const subLayer:Boolean = data[10];
                const airBrushSize:Number = data[11];
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                checkSubLayer(subLayer);
                rAirBrushSize2 = airBrushSize;
                if (shape)
                    rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND);
                else
                    rCanvasDrawShape.graphics.lineStyle(size, color);
                rCanvasDrawShape.graphics.moveTo(startX, startY);
                rCanvasDrawShape.graphics.lineTo(endX, endY);
                CanvasController.resetRCanvasDrawLayerCliprect2();
                setRCursorPos(endX, endY);
            }
            function line2(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const endX:Number = data[7];
                const endY:Number = data[8];
                const blendMode:String = data[9];
                const subLayer:Boolean = data[10];
                const airBrush:Boolean = data[11];
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                if (shape)
                    rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND);
                else
                    rCanvasDrawShape.graphics.lineStyle(size, color);
                rCanvasDrawShape.graphics.moveTo(startX, startY);
                rCanvasDrawShape.graphics.lineTo(endX, endY);
                CanvasController.resetRCanvasDrawLayerCliprect();
                setRCursorPos(endX, endY);
            }
            function line1(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const endX:Number = data[7];
                const endY:Number = data[8];
                const blendMode:String = data[9];
                const subLayer:Boolean = data[10];
                const airBrush:Boolean = data[11];
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                if (shape)
                    rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND);
                else
                    rCanvasDrawShape.graphics.lineStyle(size, color);
                rCanvasDrawShape.graphics.moveTo(startX, startY);
                rCanvasDrawShape.graphics.lineTo(endX, endY);
                setRCursorPos(endX, endY);
            }
            function line(data:Array):void
            {
                const shape:Boolean = data[1];
                const size:uint = data[2];
                const color:uint = data[3];
                const alpha:Number = data[4];
                const startX:Number = data[5];
                const startY:Number = data[6];
                const endX:Number = data[7];
                const endY:Number = data[8];
                const blendMode:String = data[9];
                const subLayer:Boolean = data[10];
                const airBrush:Boolean = data[11];
                updateLineStyleBackup(alpha, blendMode);
                rCanvasDrawLayer.alpha = alpha;
                checkSubLayer(subLayer);
                checkAirBrush(airBrush, size);
                if (shape)
                    rCanvasDrawShape.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.SQUARE, JointStyle.ROUND);
                else
                    rCanvasDrawShape.graphics.lineStyle(size, color);
                rCanvasDrawShape.graphics.moveTo(startX, startY);
                rCanvasDrawShape.graphics.lineTo(endX, endY);
                setRCursorPos(endX, endY);
            }
            function move1(data:Array):void
            {
                moveImageReplayMode(data[1], data[2], true, false);
                setRCursorPosFromMoveTool(data[1], data[2]);
            }
            function move2(data:Array):void
            {
                moveImageReplayMode(data[1], data[2], false, true);
                setRCursorPosFromMoveTool(data[1], data[2]);
            }
            function move(data:Array):void
            {
                moveImageReplayMode(data[1], data[2], true, true);
                setRCursorPosFromMoveTool(data[1], data[2]);
            }
            function resetLassoVars():void
            {
                LassoTool.lassoLayer1Bitmap.filters = [];
                LassoTool.lassoLayer2Bitmap.filters = [];
                if (LassoTool.lassoLayer1Bitmap.bitmapData)
                    LassoTool.lassoLayer1Bitmap.bitmapData.dispose();
                if (LassoTool.lassoLayer2Bitmap.bitmapData)
                    LassoTool.lassoLayer2Bitmap.bitmapData.dispose();
                LassoTool.lassoLayer1.x = 0;
                LassoTool.lassoLayer1.y = 0;
                LassoTool.lassoLayer1.scaleX = 1.0;
                LassoTool.lassoLayer1.scaleY = 1.0;
                LassoTool.lassoLayer1.rotation = 0;
                LassoTool.lassoLayer1.visible = false;
                LassoTool.lassoLayer2.x = 0;
                LassoTool.lassoLayer2.y = 0;
                LassoTool.lassoLayer2.scaleX = 1.0;
                LassoTool.lassoLayer2.scaleY = 1.0;
                LassoTool.lassoLayer2.rotation = 0;
                LassoTool.lassoLayer2.visible = false;
            }
            // 성능 문제로 샤픈 안해줌
            function lasso2(data:Array, clearOnly:Boolean):void
            {
                if (data[1].length === 0 || data[2].length === 0)
                    return;
                var imageMovedToLasso:Boolean;
                if (data.length <= 5)
                {
                    if (data[3] === null || (data[3] is Array && data[3].length === 0))
                    {
                        // (["lasso",point1,point2,null,lassoInfo]); 초기 버전 데이터 구조 3번이 비어있음
                        // (["lasso",point1,point2,[],lassoInfo]);
                        imageMovedToLasso = LassoTool.moveSelectedAreaToLassoBox(true, data[1], data[2], false, true, true);
                    }
                    else if (data[3].length === 7)
                    {
                        // (["lasso",point1,point2,lassoInfo]); 2019년판 구버전
                        // (["lasso",point1,point2,lassoInfo,lassoCopyON])
                        imageMovedToLasso = LassoTool.moveSelectedAreaToLassoBox(true, data[1], data[2], data[4], true, true);
                    }
                }
                else
                {
                    // (["lasso",point1,point2,lassoInfo,lassoCopyON,canvas1Bitmap.visible,canvas11Bitmap.visible,lassoLayerSwappedFlag]); 신버전 데이터 길이가 6이상임
                    // ["lasso",point1,point2,lassoInfo,lassoCopyON,checklayer1,checklayer2,command] // 신버전 데이터
                    imageMovedToLasso = LassoTool.moveSelectedAreaToLassoBox(true, data[1], data[2], data[4], data[5], data[6]);
                }
                if (imageMovedToLasso && !clearOnly)
                {
                    var lassoInfo:Array = (data[3] is Array && data[3].length === 7) ? data[3] : data[4];
                    const bmpScaleX:Number = lassoInfo[0];
                    const bmpScaleY:Number = lassoInfo[1];
                    const bmpWidth:Number = lassoInfo[2];
                    const bmpHeight:Number = lassoInfo[3];
                    const bmpAngle:Number = lassoInfo[4];
                    const boxX:Number = lassoInfo[5];
                    const boxY:Number = lassoInfo[6];
                    const mat:Matrix = new Matrix();
                    mat.scale(bmpScaleX, bmpScaleY);
                    mat.translate(-bmpWidth / 2, -bmpHeight / 2);
                    mat.rotate(bmpAngle);
                    mat.translate(boxX, boxY);
                    setRCursorPos(boxX, boxY);
                    LassoTool.lassoLayer1Bitmap.smoothing = true;
                    LassoTool.lassoLayer2Bitmap.smoothing = true;
                    if (data[7] as Boolean)
                    {
                        if (data[7] === true)
                        {
                            LassoTool.swapLassoImage();
                        }
                    }
                    else if (data[7] as Array)
                    {
                        const len:uint = data[7].length;
                        for (var i:uint = 0;i < len;i++)
                        {
                            if (data[7][i] === 0)
                            {
                                LassoTool.swapLassoImage();
                            }
                            else if (data[7][i] === 1)
                            {
                                LassoTool.mergeLassoImage();
                            }
                        }
                    }
                    if (data[5] || !data[5] && !data[6])
                    {
                        rCanvasLayer1BitmapData.draw(LassoTool.lassoLayer1Bitmap, mat);
                        rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                    }
                    if (data[6])
                    {
                        rCanvasLayer2BitmapData.draw(LassoTool.lassoLayer2Bitmap, mat);
                        rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
                    }
                }
                resetLassoVars();
            }
            function lasso(data:Array, clearOnly:Boolean):void
            {
                if (data[1].length === 0 || data[2].length === 0)
                    return;
                var imageMovedToLasso:Boolean;
                if (data.length <= 5)
                {
                    if (data[3] === null || (data[3] is Array && data[3].length === 0))
                    {
                        // (["lasso",point1,point2,null,lassoInfo]); 초기 버전 데이터 구조 3번이 비어있음
                        // (["lasso",point1,point2,[],lassoInfo]);
                        imageMovedToLasso = LassoTool.moveSelectedAreaToLassoBox(true, data[1], data[2], false, true, true);
                    }
                    else if (data[3].length === 7)
                    {
                        // (["lasso",point1,point2,lassoInfo]); 2019년판 구버전
                        // (["lasso",point1,point2,lassoInfo,lassoCopyON])
                        imageMovedToLasso = LassoTool.moveSelectedAreaToLassoBox(true, data[1], data[2], data[4], true, true);
                    }
                }
                else
                {
                    // (["lasso",point1,point2,lassoInfo,lassoCopyON,canvas1Bitmap.visible,canvas11Bitmap.visible,lassoLayerSwappedFlag]); 신버전 데이터 길이가 6이상임
                    // ["lasso",point1,point2,lassoInfo,lassoCopyON,checklayer1,checklayer2,command] // 신버전 데이터
                    imageMovedToLasso = LassoTool.moveSelectedAreaToLassoBox(true, data[1], data[2], data[4], data[5], data[6]);
                }
                if (imageMovedToLasso && !clearOnly)
                {
                    var lassoInfo:Array = (data[3] is Array && data[3].length === 7) ? data[3] : data[4];
                    const bmpScaleX:Number = lassoInfo[0];
                    const bmpScaleY:Number = lassoInfo[1];
                    const bmpWidth:Number = lassoInfo[2];
                    const bmpHeight:Number = lassoInfo[3];
                    const bmpAngle:Number = lassoInfo[4];
                    const boxX:Number = lassoInfo[5];
                    const boxY:Number = lassoInfo[6];
                    const mat:Matrix = new Matrix();
                    mat.scale(bmpScaleX, bmpScaleY);
                    mat.translate(-bmpWidth / 2, -bmpHeight / 2);
                    mat.rotate(bmpAngle);
                    mat.translate(boxX, boxY);
                    setRCursorPos(boxX, boxY);
                    LassoTool.lassoLayer1Bitmap.smoothing = true;
                    LassoTool.lassoLayer2Bitmap.smoothing = true;
                    if (data[7] as Boolean)
                    {
                        if (data[7] === true)
                        {
                            LassoTool.swapLassoImage();
                        }
                    }
                    else if (data[7] as Array)
                    {
                        const len:uint = data[7].length;
                        for (var i:uint = 0;i < len;i++)
                        {
                            if (data[7][i] === 0)
                            {
                                LassoTool.swapLassoImage();
                            }
                            else if (data[7][i] === 1)
                            {
                                LassoTool.mergeLassoImage();
                            }
                        }
                    }
                    if (bmpScaleX !== 1 || bmpAngle !== 0)
                    {
                        LassoTool.applyLassoShapen(bmpScaleX);
                    }
                    if (data[5] || !data[5] && !data[6])
                    {
                        rCanvasLayer1BitmapData.draw(LassoTool.lassoLayer1Bitmap, mat);
                        rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                    }
                    if (data[6])
                    {
                        rCanvasLayer2BitmapData.draw(LassoTool.lassoLayer2Bitmap, mat);
                        rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
                    }
                }
                resetLassoVars();
            }
            function mirror():void
            {
                mirrorCanvasReplayMode();
                setRCursorPosToCenter();
            }
            function bgColor(data:Array):void
            {
                const color:uint = data[1];
                rLastCanvasBGColor = color;
                updateCanvasBGColorReplayMode(color);
                setRCursorPosToCenter();
            }
            function canvasSize(data:Array):void
            {
                const width:Number = data[1];
                const height:Number = data[2];
                const moveX:Number = data[3];
                const moveY:Number = data[4];
                const movedFlag:Boolean = data[5];
                updateCanvasSizeReplayMode(width, height, moveX, moveY, movedFlag);
                setRCursorPos(width / 2, height / 2);
            }
            function tempDone4(data:Array):void
            {
                if (rAirBrushSize2 > 0)
                {
                    const blurSize:Number = CanvasController.getBlurSize(rAirBrushSize2, 1.0);
                    rCanvasDrawShape.filters = [new BlurFilter(blurSize, blurSize, 3)];
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    CanvasController.canvasDrawLayerChild.filters = [];
                }
                else
                {
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                }
                rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                updateRCanvasDrawLayerCliprect2();
                rCanvasDrawShape.graphics.clear();
            }
            function tempDone3(data:Array):void
            {
                rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                updateRCanvasDrawLayerCliprect2();
                rCanvasDrawShape.graphics.clear();
            }
            function tempDone2(data:Array):void
            {
                if (rAirBrushSize > 0 && rCanvasZoomMultiplier !== 1.0)
                {
                    blurReplayCanvasByDefaultValue();
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                    CanvasController.updateRCanvasDrawLayerCliprect();
                    rCanvasDrawShape.graphics.clear();
                    blurReplayCanvasByValue(rAirBrushSize);
                }
                else
                {
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                    CanvasController.updateRCanvasDrawLayerCliprect();
                    rCanvasDrawShape.graphics.clear();
                }
            }
            function tempDone(data:Array):void
            {
                if (rAirBrushSize > 0 && rCanvasZoomMultiplier !== 1.0)
                {
                    blurReplayCanvasByDefaultValue();
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                    rCanvasDrawShape.graphics.clear();
                    blurReplayCanvasByValue(rAirBrushSize);
                }
                else
                {
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                    rCanvasDrawShape.graphics.clear();
                }
            }
            function drawDone5(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1, 1, 1, lineStyleData[0]);
                if (rAirBrushSize2 > 0)
                {
                    const blurSize:Number = CanvasController.getBlurSize(rAirBrushSize2, 1.0);
                    rCanvasDrawShape.filters = [new BlurFilter(blurSize, blurSize, 3)];
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawShape.filters = [];
                }
                else
                {
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                }
                rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                updateRCanvasDrawLayerCliprect2();
                CanvasController.extandRCanvasDrawLayerCliprect2();
                if (subLayer)
                {
                    rCanvasLayer2BitmapData.draw(rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1], rCanvasDrawLayerClipRect);
                    rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
                }
                else
                {
                    rCanvasLayer1BitmapData.draw(rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1], rCanvasDrawLayerClipRect);
                    rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                }
                rCanvasDrawLayerBitmapData.fillRect(rCanvasDrawLayerClipRect, 0);
                rCanvasDrawShape.graphics.clear();
            }
            function drawDone4(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1, 1, 1, lineStyleData[0]);
                rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                updateRCanvasDrawLayerCliprect2();
                CanvasController.extandRCanvasDrawLayerCliprect2();
                if (rAirBrushSize2 > 0)
                {
                    const blurSize:Number = CanvasController.getBlurSize(rAirBrushSize2, 1.0);
                    rCanvasDrawLayerBitmapData.applyFilter(rCanvasDrawLayerBitmapData, rCanvasDrawLayerClipRect, new Point(rCanvasDrawLayerClipRect.x, rCanvasDrawLayerClipRect.y), new BlurFilter(blurSize, blurSize, 3));
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                }
                if (subLayer)
                {
                    rCanvasLayer2BitmapData.draw(rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1], rCanvasDrawLayerClipRect);
                    rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
                }
                else
                {
                    rCanvasLayer1BitmapData.draw(rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1], rCanvasDrawLayerClipRect);
                    rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                }
                rCanvasDrawLayerBitmapData.fillRect(rCanvasDrawLayerClipRect, 0);
                rCanvasDrawShape.graphics.clear();
            }
            function drawDone3(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1, 1, 1, lineStyleData[0]);
                if (rAirBrushSize > 0 && rCanvasZoomMultiplier !== 1.0)
                {
                    blurReplayCanvasByDefaultValue();
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                    blurReplayCanvasByValue(rAirBrushSize);
                }
                else
                {
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                }
                CanvasController.updateRCanvasDrawLayerCliprect();
                CanvasController.extandRCanvasDrawLayerCliprect();
                if (subLayer)
                {
                    rCanvasLayer2BitmapData.draw(rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1], rCanvasDrawLayerClipRectLegacy);
                    rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
                }
                else
                {
                    rCanvasLayer1BitmapData.draw(rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1], rCanvasDrawLayerClipRectLegacy);
                    rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                }
                rCanvasDrawLayerBitmapData.fillRect(rCanvasDrawLayerClipRectLegacy, 0);
                rCanvasDrawShape.graphics.clear();
                if (rAirBrushSize > 0)
                {
                    resetBlurReplayCanvas();
                }
            }
            function drawDone2(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1, 1, 1, lineStyleData[0]);
                if (rAirBrushSize > 0 && rCanvasZoomMultiplier !== 1.0)
                {
                    blurReplayCanvasByDefaultValue();
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                    blurReplayCanvasByValue(rAirBrushSize);
                }
                else
                {
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                }
                if (subLayer)
                {
                    rCanvasLayer2BitmapData.draw(rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1]);
                    rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
                }
                else
                {
                    rCanvasLayer1BitmapData.draw(rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1]);
                    rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                }
                rCanvasDrawLayerBitmapData.fillRect(new Rectangle(0, 0, rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height), 0);
                rCanvasDrawShape.graphics.clear();
                if (rAirBrushSize > 0)
                {
                    resetBlurReplayCanvas();
                }
            }
            function drawDone(data:Array):void
            {
                const lineStyleData:Array = getrLineStyleSave();
                // if(!lineStyleData) return;
                const subLayer:Boolean = data[1];
                const canvasAlpha:ColorTransform = new ColorTransform(1, 1, 1, lineStyleData[0]);
                if (rAirBrushSize > 0 && rCanvasZoomMultiplier !== 1.0)
                {
                    blurReplayCanvasByDefaultValue();
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                    blurReplayCanvasByValue(rAirBrushSize);
                }
                else
                {
                    rCanvasDrawLayerBitmapData.draw(rCanvasDrawShape);
                    rCanvasDrawLayerBitmap.bitmapData = rCanvasDrawLayerBitmapData;
                }
                if (subLayer)
                {
                    var tmpbmpd:BitmapData = new BitmapData(RCANVAS_WIDTH, RCANVAS_HEIGHT, true, 0);
                    tmpbmpd.draw(rCanvasDrawLayerBitmap, null, canvasAlpha);
                    tmpbmpd.draw(rCanvasLayer1Bitmap);
                    rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, tmpbmpd, rCanvasLayer1Bitmap);
                    tmpbmpd.dispose();
                    tmpbmpd = null;
                }
                else
                {
                    rCanvasLayer1BitmapData.draw(rCanvasDrawLayerBitmap, null, canvasAlpha, lineStyleData[1]);
                    rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
                }
                rCanvasDrawLayerBitmap.bitmapData = null;
                rCanvasDrawLayerBitmapData.fillRect(new Rectangle(0, 0, rCanvasDrawLayerBitmapData.width, rCanvasDrawLayerBitmapData.height), 0);
                rCanvasDrawShape.graphics.clear();
                if (rAirBrushSize > 0)
                {
                    resetBlurReplayCanvas();
                }
            }
            function clear(layer1:Boolean, layer2:Boolean):void
            {
                if (!layer1 && !layer2)
                {
                    layer1 = true;
                    layer2 = true;
                }
                const rect:Rectangle = new Rectangle(0, 0, rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height);
                if (layer1)
                    rCanvasLayer1BitmapData.fillRect(rect, 0);
                if (layer2)
                    rCanvasLayer2BitmapData.fillRect(rect, 0);
                setRCursorPosToCenter();
            }
            function swapLayer():void
            {
                var tempbmpd1:BitmapData = rCanvasLayer1BitmapData.clone();
                var tempbmpd11:BitmapData = rCanvasLayer2BitmapData.clone();
                const rect:Rectangle = new Rectangle(0, 0, rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height);
                rCanvasLayer1BitmapData.fillRect(rect, 0);
                rCanvasLayer2BitmapData.fillRect(rect, 0);
                rCanvasLayer1BitmapData.draw(tempbmpd11);
                rCanvasLayer2BitmapData.draw(tempbmpd1);
                tempbmpd1.dispose();
                tempbmpd11.dispose();
                tempbmpd1 = null;
                tempbmpd11 = null;
                setRCursorPosToCenter();
            }
            function mergeLayer():void
            {
                rCanvasLayer2BitmapData.draw(rCanvasLayer1BitmapData);
                rCanvasLayer1BitmapData.fillRect(new Rectangle(0, 0, rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height), 0);
                setRCursorPosToCenter();
            }
            function drawNext():void
            {
                if (!data || data.length === 0)
                {
                    return;
                }
                const d:Array = data[index];
                switch (d[0])
                {
                    case "lineStyle":
                        lineStyle(d);
                        break;
                    case "lineStyle2":
                        lineStyle2(d);
                        break;
                    case "lineStyle3":
                        lineStyle3(d);
                        break;
                    case "lineStyle4":
                        lineStyle4(d);
                        break;
                    case "lineStyle5":
                        lineStyle5(d);
                        break;
                    case "lineTo":
                        lineTo(d);
                        break;
                    case "sqline":
                        sqline(d);
                        break;
                    case "fill":
                        fill(d);
                        break;
                    case "fill2":
                        fill2(d);
                        break;
                    case "fill3":
                        fill3(d);
                        break;
                    case "fill4":
                        fill4(d);
                        break;
                    case "fill5":
                        fill5(d);
                        break;
                    case "dot":
                        dot(d);
                        break;
                    case "dot2":
                        dot2(d);
                        break;
                    case "dot3":
                        dot3(d);
                        break;
                    case "dot4":
                        dot4(d);
                        break;
                    case "line":
                        line(d);
                        break;
                    case "line1":
                        line1(d);
                        break;
                    case "line2":
                        line2(d);
                        break;
                    case "line3":
                        line3(d);
                        break;
                    case "move":
                        move(d);
                        break;
                    case "move1":
                        move1(d);
                        break;
                    case "move2":
                        move2(d);
                        break;
                    case "lasso":
                        lasso(d, false);
                        break;
                    case "lasso2":
                        lasso2(d, false);
                        break;
                    case "lassodel":
                        lasso(d, true);
                        break;
                    case "lassodel2":
                        lasso2(d, true);
                        break;
                    case "mirror":
                        mirror();
                        break;
                    case "bgColor":
                        bgColor(d);
                        break;
                    case "canvasSize":
                        canvasSize(d);
                        break;
                    case "tempDone":
                        tempDone(d);
                        break;
                    case "tempDone2":
                        tempDone2(d);
                        break;
                    case "tempDone3":
                        tempDone3(d);
                        break;
                    case "tempDone4":
                        tempDone4(d);
                        break;
                    case "drawDone":
                        drawDone(d);
                        break;
                    case "drawDone2":
                        drawDone2(d);
                        break;
                    case "drawDone3":
                        drawDone3(d);
                        break;
                    case "drawDone4":
                        drawDone4(d);
                        break;
                    case "drawDone5":
                        drawDone5(d);
                        break;
                    case "clear":
                        clear(true, true);
                        break;
                    case "clear1":
                        clear(true, false);
                        break;
                    case "clear2":
                        clear(false, true);
                        break;
                    case "swap":
                        swapLayer();
                        break;
                    case "merge":
                        mergeLayer();
                        break;
                    default:
                        break;
                }
                index++;
            }
            return {
                    drawNext: drawNext,
                    drawAll: drawAll,
                    setData: setData,
                    clearData: clearData,
                    setIndex: setIndex,
                    getCurrentPosition: getCurrentPosition,
                    isReadFinished: isReadFinished,
                    getDataLength: getDataLength,
                    getRemainingData: getRemainingData,
                    getrLineStyleSave: getrLineStyleSave,
                    getLineStyleAlpha: getLineStyleAlpha,
                    getRCursorPos: getRCursorPos,
                    setRCursorPos: setRCursorPos,
                    updateRCursorPos: updateRCursorPos,
                    updateRCursorPosToFirst: updateRCursorPosToFirst,
                    hasRCursorFirstPos: hasRCursorFirstPos,
                    getFirstRCursorPos: getFirstRCursorPos,
                    setFirstRCursorPos: setFirstRCursorPos,
                    resetFirstRCursorPos: resetFirstRCursorPos,
                    setFirstRCursorPosCurrent: setFirstRCursorPosCurrent,
                    updateLineStyleBackup: updateLineStyleBackup
                };
        }

        public static function updateTotalFrameAndReplayMaxSpeedFor10Sec(totalframe:Number):void
        {
            TOTAL_FRAME = totalframe;
            var maxSpeed:Number = Math.floor(totalframe / 10 / main.stage.frameRate);
            if (maxSpeed < 1.0)
            {
                maxSpeed = 1.0;
            }
            REPLAY_MAX_SPEED = maxSpeed;
            if (rReplaySpeedMultipler > maxSpeed)
            {
                rReplaySpeedMultipler = maxSpeed;
            }
        }

        public static function updateReplayPrograssText(finishFlag:Boolean = false, customFrame:Number = NaN):void
        {
            const remainingTime:String = (UndoManager.isDeepUndoEnabled || finishFlag) ? "" : getReplayRemainingTimeString(rReplaySpeedMultipler, TOTAL_FRAME - rNowFrame);
            if (isNaN(customFrame))
            {
                customFrame = rNowFrame;
            }
            MainUI.seekBarBox.prograssInfo.text = customFrame + " / " + TOTAL_FRAME + remainingTime;
        }
        public static function startUpdatingPrograssBarTimer():void
        {
            if (FOFOTimer.hasTimer("prograssBarUpdateTimer"))
            {
                return;
            }
            var lastCursorUpdateTime:int = getTimer();
            var lastTextUpdateTime:int = getTimer();
            const cursorUpdateTime:int = main.stage.frameRate * 2;
            const textUpdateTime:int = 1000;
            updateReplayPrograssText();
            MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(rNowFrame / TOTAL_FRAME);
            FOFOTimer.addByName("prograssBarUpdateTimer", 0.0, true, function ():Boolean
                {
                    if (!isReplayModeON)
                    {
                        return false;
                    }
                    if (rNowFrame >= TOTAL_FRAME)
                    {
                        MainUI.seekBarBox.setReplayPrograssBarMaxWidth();
                        updateReplayPrograssText(true, TOTAL_FRAME);
                        replayCompleteEffect();
                        startReplayRestartTimer();
                        showCompleteImageToBGReplayMode();
                        MainUI.hideBottomHint();
                        return false;
                    }
                    const nowTime:int = getTimer();
                    if (nowTime - lastCursorUpdateTime >= cursorUpdateTime)
                    {
                        lastCursorUpdateTime = nowTime;
                        drawReplayByCommand.updateRCursorPos();
                        if (!isReplayCanvasFitToWindow && !CanvasController.isMouseLeftClicked && !UndoManager.isDeepUndoEnabled)
                        {
                            rFollowMouse.check(isReplaySlideShowMode);
                        }
                    }
                    if (nowTime - lastTextUpdateTime >= textUpdateTime)
                    {
                        lastTextUpdateTime = nowTime;
                        updateReplayPrograssText();
                        MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(rNowFrame / TOTAL_FRAME);
                    }
                    updatePrograssBarStartTime = getTimer();
                    return true;
                });
        }
        public static function drawCanvasFromReplayDataSlideShowMode():void
        {
            const nowTime:int = getTimer();
            if (nowTime - rSeekbarTextUpdateTime >= REPLAY_SLIDESHOW_UPDATE_TIME)
            {
                rSeekbarTextUpdateTime = nowTime;
                const nextFrame:Number = rReplaySpeedMultipler * main.stage.frameRate;
                renderReplayFrame(rNowFrame + Math.floor(nextFrame / REPLAY_SLIDESHOW_FRAME_RATE), JUMP_FRAME_MANUAL);
                if (rNowFrame >= TOTAL_FRAME)
                {
                    isReplayFinished = true;
                    stopReplay();
                }
            }
        }
        public static function startReplayDrawTimer():void
        {
            FOFOTimer.addByName("replayDrawTimer", 0.0, true, function ():Boolean
                {
                    if (isReplaySlideShowMode)
                    {
                        if (!shouldUseReplaySlideShowMode())
                        {
                            isReplaySlideShowMode = false;
                            rFileStream.close();
                            if (!rDataReadFlag)
                            {
                                rFileStream.open(FileManager.replayDataFilePath, FileMode.READ);
                                rFileStream.position = rFileLastBytePosition;
                            }
                        }
                        else
                        {
                            drawCanvasFromReplayDataSlideShowMode();
                        }
                        return true;
                    }
                    if (shouldUseReplaySlideShowMode())
                    {
                        isReplaySlideShowMode = true;
                        rFileStream.close();
                    }
                    else
                    {
                        drawCanvasFromReplayData(rReplaySpeedMultipler, JUMP_FRAME_PLAY);
                    }
                    return true;
                });
        }
        public static function clearRFrameTempCache():void
        {
            if (rFrameTempCachedImages.length > 0)
            {
                for (var i:int = 0;i < rFrameTempCachedImages.length;i++)
                {
                    rFrameTempCachedImages[i][0].dispose();
                    rFrameTempCachedImages[i][1].dispose();
                }
                rFrameTempCachedImages.length = 0;
                rJumpImageIndexLast = -2;
                rCachedImageLastIndex = -2;
            }
        }
        public static function getRFrameTempCacheLastFrame():Number
        {
            return rFrameTempCachedImages[rFrameTempCachedImages.length - 1][6];
        }
        public static function createRFrameTempCache(index:uint, lastReadBytes:Number):void
        {
            rFrameTempCachedImages[index] = [rCanvasLayer1BitmapData.clone()
                    , rCanvasLayer2BitmapData.clone()
                    , rCanvasLayer1BitmapData.width
                    , rCanvasLayer1BitmapData.height
                    , RCANVAS_BG_COLOR
                    , lastReadBytes
                    , rNowFrame
                    , rMirrorON];
        }
        // jumpFlag  0: 기본 재생 1:탐색바를 마우스를 이용하여 스킵, 2:one frame 이전스트로크, 3:one frame 이후 스트로크
        public static function cDrawReplayData():Function
        {
            // jumpFlag 1번은 마우스 커서로 이동, 2,3번은 스트로크 단위혹은 프레임 단위로 앞뒤로 탐색
            var rDataLen:uint;
            var savedTime:int;
            var rFrameCursorDelayTime:int = 0; // 커서 딜레이
            var _rFrameTextDelayTime:int = 0; // 프레임 바 딜레이
            var getTimeStr:String;
            var timeStr:String;
            var readCount:Number = 0;
            var jumpImageGroupIndex:int;
            var nowJumpFlag:Boolean;
            const cursorUpdateTime:int = main.stage.frameRate * 2;
            function makeMemoryCacheImage():void
            {
                createRFrameTempCache(rFrameTempCachedImages.length, rFileCutBytePosition);
            }
            function readyToReadMemoryData(jumpFlag:int):void
            {
                rDataReadFlag = true;
                rDataIndex = rDataStartIndex;
                rDataStartIndex = 0;
                rDataLen = rData.length;
                if (jumpFlag === JUMP_FRAME_PLAY)
                {
                    rFileStream.close();
                    rFileLastBytePosition = 0;
                }
                if (rData.length > 0)
                {
                    rPrevFrame = rNowFrame;
                    drawReplayByCommand.setData(rData[rDataIndex]);
                }
                else
                {
                    drawReplayByCommand.clearData();
                }
            }
            function readNextFileData():Boolean
            {
                if (rFileStream.bytesAvailable > 0)
                {
                    const obj:Array = rFileStream.readObject() as Array;
                    if (!obj)
                        return true;
                    drawReplayByCommand.setData(obj);
                    rFileCutBytePosition = rFileLastBytePosition;
                    rFileLastBytePosition = rFileStream.position;
                    rPrevFrame = rNowFrame;
                    return true;
                }
                return false;
            }
            function checkFinish(jumpFlag:int):Boolean
            {
                if (rDataIndex >= rDataLen || rDataLen === 0) // 자연적으로 끝났을때
                {
                    rReplayFOFOCursor.visible = false;
                    isReplayFinished = true;
                    if (jumpFlag === JUMP_FRAME_PLAY || isReplaySlideShowMode === true) // 1프레임 이상일때만 재시작 타이머 가동
                    {
                        // reset replay time해주지 말고 그냥 end플래그만 올려줌
                        // 왜냐하면 리플레이 자연적으로 끝나고도 스킵프레임이나 oneframe jump을 해줄수가 있기 때문
                        stopReplay();
                        return true;
                    }
                }
                return false;
            }
            function drawFromMemoryData(len:Number, jumpFlag:int):void
            {
                for (var i:Number = 0;i < len;i++)
                {
                    if (drawReplayByCommand.isReadFinished())
                    {
                        rDataIndex++;
                        if (checkFinish(jumpFlag))
                        {
                            return;
                        }
                        rPrevFrame = rNowFrame;
                        drawReplayByCommand.setData(rData[rDataIndex]);
                    }
                    drawReplayByCommand.drawNext();
                    rNowFrame++;
                }
            }
            function drawFromFileData(len:Number, jumpFlag:int):void
            {
                for (var i:Number = 0;i < len;i++)
                {
                    if (drawReplayByCommand.isReadFinished())
                    {
                        if (readNextFileData() === false)
                        {
                            // 더이상 읽을 데이터가 없을때 메모리읽기로 넘겨줌
                            readyToReadMemoryData(jumpFlag);
                            return;
                        }
                        if (isReplayStarted === false && (jumpFlag === JUMP_FRAME_MANUAL || jumpFlag === JUMP_FRAME_PREV))
                        {
                            if (rNowFrame > getRFrameTempCacheLastFrame() + REPLAY_MEMORY_CACHE_FRAME_INTERVAL)
                            {
                                makeMemoryCacheImage();
                            }
                        }
                    }
                    drawReplayByCommand.drawNext();
                    rNowFrame++;
                    readCount--;
                }
            }
            return function (jumpCount:Number, jumpFlag:int):void
            {
                if (jumpCount > 0)
                {
                    readCount = jumpCount;
                    if (!rDataReadFlag)
                    {
                        // readcount 감소
                        drawFromFileData(jumpCount, jumpFlag);
                    }
                    if (readCount > 0)
                    {
                        // readcount를 읽어줌
                        drawFromMemoryData(readCount, jumpFlag);
                    }
                }
            };
        }
        public static function getReplayRemainingTimeString(speed:Number, totalFrame:Number, isSlideShowMode:Boolean = false):String
        {
            const fps:Number = (isSlideShowMode === true) ? 1.0 : main.stage.frameRate;
            const totalSec:Number = totalFrame / (fps * speed);
            if (totalSec === 0)
                return "";
            const hour:int = totalSec / 3600;
            const min:int = totalSec % 3600 / 60;
            const sec:int = totalSec % 60;
            var timeStr:String = "";
            if (hour > 0)
            {
                timeStr += hour + ":";
            }
            if (min > 0)
            {
                timeStr += (min >= 10) ? min + ":" : "0" + min + ":";
            }
            else
            {
                timeStr = "00:";
            }
            if (sec > 0)
            {
                timeStr += (sec >= 10) ? sec : "0" + sec;
            }
            else
            {
                timeStr += "00";
            }
            if (hour === 0 && min === 0 && sec === 0)
            {
                const milisec:Number = totalSec - Math.floor(totalSec);
                const milisecStr:String = milisec.toFixed(1);
                return " (" + milisecStr + ")";
            }
            return " (" + timeStr + ")";
        }
        public static function cReplayFollowMouse():Object
        {
            const padding:Number = 20;
            const cursorPos:Point = new Point(0, 0);
            const windowCenterPos:Point = new Point(0, 0); // 캔버스 중점위치, 창 중점위치 사이 거리
            var stw:Number;
            var sth:Number; // 프레임 탐색막대 길이 빼줌]
            var bounds:Object; // 바운드 저장하는 객체
            var left:Number; // 바운드 상하좌우
            var right:Number;
            var top:Number;
            var bottom:Number;
            var globalChecked:Boolean;
            var cp:Point; // 커서 좌표
            var gp:Point; // 캔버스 글로벌 좌표
            var rg:Point; // 캔버스 회전된 글로벌 좌표
            var zoom:Number = 1.0;
            var scale:Number = 1.0;
            // rcanvas1 글로벌 좌표에 회전된 캔버스에서 커서 위치를 더해줌. 즉 윈도우 기준에서 커서 커서 위치를 구하는거임
            var isCanvasWidthSmallerStage:Boolean; // 캔버스 가로 새로 길이가 스테이지 길이보다 클때 체크
            var isCanvasHeightSmallerStage:Boolean;
            var isNotCenterX:Boolean; // 캔버스 중점위치, 창 중점위치 사이 거리
            var isNotCenterY:Boolean;
            const leftLimit:Number = padding;
            const topLimit:Number = padding + MainUI.topBar.BARSIZE;
            var rightLimit:Number;
            var bottomLimit:Number;
            function updateScale(newScale:Number):void
            {
                scale = newScale;
            }
            function updateBounds():void
            {
                bounds = Utils.getBoundRect(rCanvasLayer1Bitmap);
                left = bounds.left;
                right = bounds.right;
                top = bounds.top;
                bottom = bounds.bottom;
                stw = main.stage.stageWidth;
                sth = main.stage.stageHeight - (MainUI.topBar.BARSIZE) * scale;
                zoom = rCanvasZoomMultiplier;
                isCanvasWidthSmallerStage = right - left < stw;
                isCanvasHeightSmallerStage = bottom - top < sth;
                // 캔버스 중점위치, 창 중점위치 사이 거리
                windowCenterPos.setTo(Math.floor(stw / 2 - (right + left) / 2), Math.floor((MainUI.topBar.BARSIZE) * scale + sth / 2 - (bottom + top) / 2));
                isNotCenterX = Math.abs(windowCenterPos.x) > 0; // 캔버스 중점위치, 창 중점위치 사이 거리
                isNotCenterY = Math.abs(windowCenterPos.y) > 0;
                rightLimit = stw - padding;
                bottomLimit = sth + MainUI.topBar.BARSIZE - padding;
            }
            function check(viewCenterFlag:Boolean):void
            {
                cp = drawReplayByCommand.getRCursorPos();
                globalChecked = false;
                const div:Number = (viewCenterFlag) ? 1 : 3;
                if (isCanvasWidthSmallerStage)
                {
                    if (isNotCenterX)
                    {
                        rCanvasAnchorPoint.x += windowCenterPos.x;
                        updateBounds();
                    }
                }
                else
                {
                    globalChecked = true;
                    gp = rCanvasLayer1Bitmap.localToGlobal(new Point(0, 0));
                    rg = Utils.rotatePoint(cp.x, cp.y, -rCanvasAnchorPoint.rotation);
                    cursorPos.x = gp.x + (rg.x * zoom);
                    if (cursorPos.x < leftLimit)
                    {
                        rCanvasAnchorPoint.x += Math.floor(Math.abs((cursorPos.x - stw / 2) / div));
                        updateBounds();
                    }
                    else if (cursorPos.x > rightLimit)
                    {
                        rCanvasAnchorPoint.x -= Math.floor(Math.abs((cursorPos.x - stw / 2) / div));
                        updateBounds();
                    }
                }
                if (isCanvasHeightSmallerStage)
                {
                    if (isNotCenterY)
                    {
                        rCanvasAnchorPoint.y += windowCenterPos.y;
                        updateBounds();
                    }
                }
                else
                {
                    if (globalChecked === false)
                    {
                        globalChecked = true;
                        gp = rCanvasLayer1Bitmap.localToGlobal(new Point(0, 0));
                        rg = Utils.rotatePoint(cp.x, cp.y, -rCanvasAnchorPoint.rotation);
                    }
                    cursorPos.y = gp.y + (rg.y * zoom);
                    if (cursorPos.y < topLimit)
                    {
                        rCanvasAnchorPoint.y += Math.floor(Math.abs((cursorPos.y - sth / 2) / div));
                        updateBounds();
                    }
                    else if (cursorPos.y > bottomLimit)
                    {
                        rCanvasAnchorPoint.y -= Math.floor(Math.abs((cursorPos.y - sth / 2) / div));
                        updateBounds();
                    }
                }
            }
            return {
                    check: check,
                    updateBounds: updateBounds,
                    updateScale: updateScale
                };
        }
        public static function shouldUseReplaySlideShowMode():Boolean
        {
            return rReplaySpeedMultipler > REPLAY_SLIDESHOW_ACTIVE_SPEED;
        }
        public static function toggleFitToCanvasReplayMode():void
        {
            if (isReplayCanvasFitToWindow)
            {
                resetZoomReplayMode();
                MainUI.topBar.replayFitToWindowButton.alpha = Global.OFFALPHA;
            }
            else
            {
                setFitReplayCanvasToViewportON();
                MainUI.topBar.replayFitToWindowButton.alpha = 1.0;
            }
        }
        public static function toggleReplayRepeat():void
        {
            isReplayRepeatON = !isReplayRepeatON;
            if (isReplayRepeatON)
            {
                MainUI.topBar.replayRepeatButton.alpha = 1.0;
            }
            else
            {
                MainUI.topBar.replayRepeatButton.alpha = Global.OFFALPHA;
            }
        }

        public static function getTotalFrame():Number
        {
            return UndoManager.getNowFrameUntilUndoIndex(rDataFrame.length - 1);
        }

        // targetFrame이 rFrameCacheImages데이터에 몆 번 인덱스에 있나 구해줌
        public static function getCacheImageIndex(targetFrame:Number):int
        {
            return Utils.binarySearchIndex(rFrameTempCachedImages, targetFrame, function (item:*):Number
                {
                    return item[6];
                });
        }
        // targetFrame이 rJumpImageFrameData데이터에 몆 번 인덱스에 있나 구해줌
        public static function getCachedFrameImageIndex(targetFrame:Number):int
        {
            return Utils.binarySearchIndex(rJumpImageFrameData, targetFrame, function (item:*):Number
                {
                    return Number(item);
                });
        }
        public static function updateDeleteReplayDataButtonsState():void
        {
            if (isGeneratingCacheImages() || BackgroundWorkerCoordinator.isSaveInProgress || isReplayStarted)
            {
                MainUI.topBar.superUndoButton.alpha = Global.OFFALPHA;
                MainUI.topBar.cutPrevDataButton.alpha = Global.OFFALPHA;
                MainUI.topBar.repNewFileButton.alpha = Global.OFFALPHA;
            }
            else
            {
                MainUI.topBar.repNewFileButton.alpha = 1.0;
                if (rNowFrame > 0 && rNowFrame < TOTAL_FRAME)
                {
                    MainUI.topBar.superUndoButton.alpha = 1.0;
                    MainUI.topBar.cutPrevDataButton.alpha = 1.0;
                }
                else
                {
                    MainUI.topBar.superUndoButton.alpha = Global.OFFALPHA;
                    MainUI.topBar.cutPrevDataButton.alpha = Global.OFFALPHA;
                }
            }
        }
        public static function readyForFrameJump():void
        {
            isReplayFinished = false;
            if (isReplayStarted)
            {
                stopReplay();
            }
        }
        public static function moveToPreviousStep():void
        {
            readyForFrameJump();
            if (rNowFrame > 0)
            {
                renderReplayFrame(rPrevFrame, JUMP_FRAME_PREV);
                updateDeleteReplayDataButtonsState();
                MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(rNowFrame / TOTAL_FRAME);
                updateReplayPrograssText();
            }
        }
        public static function moveToNextStep():void
        {
            readyForFrameJump();
            if (rNowFrame <= TOTAL_FRAME)
            {
                if (drawReplayByCommand.getRemainingData() === 0)
                {
                    // +1해줘서 다음 데이터 갱신해주고 나머지 끝까지 그려줌
                    renderReplayFrame(rNowFrame + 1, JUMP_FRAME_NEXT);
                    renderReplayFrame(rNowFrame + drawReplayByCommand.getRemainingData(), JUMP_FRAME_NEXT);
                    // jumpframe함수 이후에 실행
                }
                else
                {
                    renderReplayFrame(rNowFrame + drawReplayByCommand.getRemainingData(), JUMP_FRAME_NEXT);
                }
                updateDeleteReplayDataButtonsState();
                MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(rNowFrame / TOTAL_FRAME);
                updateReplayPrograssText();
            }
        }
        public static function moveToPreviousFrame():void
        {
            readyForFrameJump();
            if (rNowFrame > 0)
            {
                renderReplayFrame(rNowFrame - 1, JUMP_FRAME_MANUAL);
                updateDeleteReplayDataButtonsState();
                MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(rNowFrame / TOTAL_FRAME);
                updateReplayPrograssText();
            }
        }
        public static function moveToNextFrame():void
        {
            readyForFrameJump();
            if (rNowFrame < TOTAL_FRAME)
            {
                renderReplayFrame(rNowFrame + 1, JUMP_FRAME_MANUAL);
                updateDeleteReplayDataButtonsState();
                MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(rNowFrame / TOTAL_FRAME);
                updateReplayPrograssText();
            }
        }
        public static function drawCacheImageFirst(tragetFrame:Number):Number
        {
            const index:Number = getCachedFrameImageIndex(tragetFrame);
            var cachedImageIndex:Number = -1; // 자잘 썸네일 인덱스를 넣어줌
            var loadCacheFlag:int = 0;
            var remainingFrameCount:Number = 0.0;
            // isReplayStarted 붙여주는 이유는
            // slide show모드로 재생하게 되면 클리어 케시를 계속 호출해주고
            // 재생 완료시 rJumpImageIndexLast가 갱신되어있을때 다시 해주면 메모리 캐시가 없는데 캐시를 불러주는 버그가 생겨서
            // 아무생각없이 넣어본건데 버그 안나서 그대로 두려고함
            if (index !== rJumpImageIndexLast && isReplayStarted === false)
            {
                clearRFrameTempCache();
                loadCacheFlag = 1;
            }
            else if (rFrameTempCachedImages.length > 0)
            {
                if (tragetFrame >= rFrameTempCachedImages[0][6])
                {
                    cachedImageIndex = getCacheImageIndex(tragetFrame);
                    if (rCachedImageLastIndex !== cachedImageIndex || tragetFrame < rNowFrame)
                    {
                        loadCacheFlag = 2;
                    }
                }
            }
            if (loadCacheFlag > 0 || tragetFrame < rNowFrame)
            {
                var cachedImageData:Array;
                var layer1bmpd:BitmapData;
                var layer2bmpd:BitmapData;
                var newrect:Rectangle;
                if (loadCacheFlag === 2)
                {
                    cachedImageData = rFrameTempCachedImages[cachedImageIndex];
                    layer1bmpd = cachedImageData[0];
                    layer2bmpd = cachedImageData[1];
                    rCachedImageLastIndex = cachedImageIndex;
                }
                else
                {
                    const file:File = FileManager.replayCacheImageFolderPath.resolvePath(String(index));
                    const fs:FileStream = new FileStream();
                    fs.open(file, FileMode.READ);
                    cachedImageData = fs.readObject() as Array;
                    fs.close();
                    cachedImageData[0].uncompress();
                    cachedImageData[1].uncompress();
                    newrect = new Rectangle(0, 0, cachedImageData[2], cachedImageData[3]);
                    layer1bmpd = new BitmapData(cachedImageData[2], cachedImageData[3], true, 0);
                    layer1bmpd.lock();
                    layer1bmpd.setPixels(newrect, cachedImageData[0]);
                    layer1bmpd.unlock();
                    layer2bmpd = new BitmapData(cachedImageData[2], cachedImageData[3], true, 0);
                    layer2bmpd.lock();
                    layer2bmpd.setPixels(newrect, cachedImageData[1]);
                    layer2bmpd.unlock();
                    cachedImageData[0].clear();
                    cachedImageData[0] = null;
                    cachedImageData[1].clear();
                    cachedImageData[1] = null;
                    rJumpImageNowFrameLast = cachedImageData[6];
                }
                rJumpImageIndexLast = index;
                rFileLastBytePosition = cachedImageData[5]; // 마지막 바이트
                rFileStream.position = cachedImageData[5];
                rNowFrame = cachedImageData[6]; // 썸네일 이미지를 저장한 프레임
                // 원하는 프레임에서 썸네일 이미지 프레임을 빼줌 나머지 프레임만 그려주면 되니깐
                remainingFrameCount = tragetFrame - cachedImageData[6];
                rDataIndex = 0; // 이거 먼저 초기화 시켜주어야함
                drawReplayByCommand.clearData();
                clearCanvasReplayMode();
                rMirrorON = cachedImageData[7];
                rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, layer1bmpd, rCanvasLayer1Bitmap);
                rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, layer2bmpd, rCanvasLayer2Bitmap);
                updateCanvasSizeReplayMode(rCanvasLayer1Bitmap.width, rCanvasLayer1Bitmap.height);
                updateCanvasBGColorReplayMode(cachedImageData[4]);
                if (loadCacheFlag === 1 && isReplayStarted === false)
                {
                    createRFrameTempCache(0, rFileLastBytePosition);
                }
                cachedImageData = null;
                rDataReadFlag = false;
                rDataStartIndex = 0;
                if (loadCacheFlag !== 2)
                {
                    layer1bmpd.dispose();
                    layer2bmpd.dispose();
                    layer1bmpd = null;
                    layer2bmpd = null;
                }
            }
            else
            {
                if (!rDataReadFlag)
                {
                    rFileStream.position = rFileLastBytePosition;
                }
                remainingFrameCount = tragetFrame - rNowFrame;
            }
            if (remainingFrameCount === 0.0)
            {
                rPrevFrame = tragetFrame - 1;
            }
            return remainingFrameCount;
        }
        public static function renderReplayFrame(frame:Number, jumpflag:int):void // jumpp
        {
            if (frame < 0)
            {
                frame = 0;
            }
            else if (frame > TOTAL_FRAME)
            {
                frame = TOTAL_FRAME;
            }
            if (isReplayModeON)
            {
                if (frame >= TOTAL_FRAME && isReplayFinished)
                {
                    return;
                }
            }
            rFileStream.open(FileManager.replayDataFilePath, FileMode.READ);
            const remainingFrameCount:Number = drawCacheImageFirst(frame);
            drawCanvasFromReplayData(remainingFrameCount, jumpflag);
            rFileStream.close();
            // dodraw밑이기 때문에 rFrameSum이 갱신되서 위에 nowFrame은 쓸수가 없음
            if (rNowFrame >= TOTAL_FRAME)
            {
                if (isReplayModeON) // deepundo도 있어서
                {
                    if (!isReplayFinished)
                    {
                        isReplayFinished = true;
                        // syncMirrorReplayModeWithDrawMode();
                    }
                    rReplayFOFOCursor.visible = false;
                }
            }
            else
            {
                isReplayFinished = false;
                rReplayFOFOCursor.visible = true;
            }
            drawReplayByCommand.updateRCursorPos();
            if (!isReplaySlideShowMode && !isReplayCanvasFitToWindow && !UndoManager.isDeepUndoEnabled)
            {
                rFollowMouse.check(true);
            }
        }
        // 데이터를 읽다 말았으면 끝까지 한세트 끝나게 프레임 이동시킴
        public static function finalizeRemainingReplayData():void
        {
            renderReplayFrame(rNowFrame + drawReplayByCommand.getRemainingData(), JUMP_FRAME_MANUAL);
        }
        public static function onSeekbarClick():void
        {
            if (TOTAL_FRAME === 0 || rReplayImageCacheState > REPLAY_IMAGE_CAHCHE_COMPLETE)
            {
                return;
            }
            // 리플레이 플레이 중인지 아닌지 플래그 미리 저장해둠
            var wasReplayRunning:Boolean = false;
            var clickX:Number = MainUI.seekBarBox.trackBar.mouseX * MainUI.seekBarBox.trackBar.scaleX;
            var finalFrame:Number = Math.floor(TOTAL_FRAME * clickX / MainUI.seekBarBox.trackBar.width);
            function clampFrame():void
            {
                var mx:Number = MainUI.seekBarBox.trackBar.mouseX * MainUI.seekBarBox.trackBar.scaleX;
                if (mx < 0)
                {
                    mx = 0;
                    MainUI.seekBarBox.resetReplayPrograssBarWidth();
                }
                else if (mx > MainUI.seekBarBox.trackBar.width)
                {
                    mx = MainUI.seekBarBox.trackBar.width;
                    MainUI.seekBarBox.setReplayPrograssBarMaxWidth();
                }
                else
                {
                    MainUI.seekBarBox.setReplayPrograssBarWidth(mx);
                }
                finalFrame = Math.floor(TOTAL_FRAME * mx / MainUI.seekBarBox.trackBar.width);
                updateReplayPrograssText(false, finalFrame);
            }
            function onDragStart():void
            {
                if (isReplayStarted)
                {
                    wasReplayRunning = true;
                    isReplayStarted = false;
                    FOFOTimer.remove("replayDrawTimer");
                    rFileStream.close();
                }
                FOFOTimer.remove("prograssBarUpdateTimer");
                MainUI.seekBarBox.setReplayPrograssBarWidth(clickX);
                clampFrame();
                isReplaySlideShowMode = false;
                isReplayFinished = false;
                MainUI.seekBarBox.resetPrograssBarColor();
            }
            function onMouseMove():void
            {
                clampFrame();
                if (!FOFOTimer.hasTimer("jumpFrameUpdateTimer"))
                {
                    FOFOTimer.addByName("jumpFrameUpdateTimer", 0.25, false, function ():void
                        {
                            renderReplayFrame(finalFrame, JUMP_FRAME_MANUAL);
                        });
                }
            }
            function onMouseUp():void
            {
                FOFOTimer.remove("jumpFrameUpdateTimer");
                renderReplayFrame(finalFrame, JUMP_FRAME_MANUAL);
                clampFrame();
                // jumpframe함수 이후에 실행
                updateDeleteReplayDataButtonsState();
                // 재생중에 스킵하고 있었으면 다시 시작
                if (wasReplayRunning && !isReplayFinished)
                {
                    startReplay();
                }
                else if (isReplayFinished)
                {
                    MainUI.seekBarBox.setReplayPrograssBarMaxWidth();
                    updateReplayPrograssText(true, TOTAL_FRAME);
                    stopReplay();
                }
            }
            DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
        }
        public static function hideTopbarOnReplayStart():void
        {
            if (MainUI.topBar.visible === true)
            {
                MainUI.seekBarBox.y = 0;
                MainUI.seekBarBox.hideReplayControlButton();
                MainUI.topBar.visible = false;
                MainUI.hideBottomHint();
                MainUI.hideMouseHint();
            }
        }
        public static function handleReplayStopButton():void
        {
            MainUI.showTopbarOnReplayEnd();
            stopReplay();
        }
        public static function stopReplay():void
        {
            FOFOTimer.remove("replayDrawTimer");
            if (!isReplayFinished)
            {
                MainUI.seekBarBox.setPlayButtonVisible(true);
            }
            rFileStream.close();
            isReplayStarted = false;
            isReplaySlideShowMode = false;
            updateDeleteReplayDataButtonsState();
        }
        public static function handleReplayStartButton():void
        {
            hideTopbarOnReplayStart();
            startReplay();
        }
        public static function startReplay():void
        {
            if (isReplayStarted || TOTAL_FRAME === 0)
            {
                return;
            }
            isReplayStarted = true;
            MainUI.seekBarBox.resetPrograssBarColor();
            MainUI.seekBarBox.playButton.visible = false;
            MainUI.seekBarBox.pauseButton.visible = true;
            rReplayFOFOCursor.visible = true;
            updateDeleteReplayDataButtonsState();
            if (isReplayFinished === true) // 리플레이 시간 등등 초기화 시키고 시작
            {
                MainUI.seekBarBox.resetReplayPrograssBarWidth();
                rMirrorON = false;
                resetReplayTime();
                clearCanvasReplayMode();
                drawFirstJumpImage();
                rDataReadFlag = false;
                isReplayFinished = false; // resetReplayTime함수 에서 이걸 true로 해주기 때문에 아래쪽에서 변경
                rFollowMouse.updateBounds();
                selectReplaySubLayer(false);
            }
            if (!rDataReadFlag)
            {
                rFileStream.open(FileManager.replayDataFilePath, FileMode.READ);
                rFileStream.position = rFileLastBytePosition;
            }
            if (isReplayCanvasFitToWindow)
            {
                fitReplayCanvasToViewport();
            }
            clearRFrameTempCache();
            startReplayDrawTimer();
            startUpdatingPrograssBarTimer();
            startCheckingHideMouseCursor();
        }

        public static function startCheckingHideMouseCursor():void
        {
            if (FOFOTimer.hasTimer("replayHideCursorCheckTimer"))
            {
                return;
            }
            FOFOTimer.addByName("replayHideCursorCheckTimer", 0.0, true, function ():Boolean
                {
                    if (!isReplayModeON || MainUI.topBar.visible)
                    {
                        replayHideCursor.show();
                        return false;
                    }
                    replayHideCursor.check();
                    return true;
                });
        }
        public static function updateCanvasBGColorReplayMode(color:uint):void
        {
            RCANVAS_BG_COLOR = color;
            CanvasController.updateCanvasBGColorReplayMode(color);
        }

        public static function onDragEnterStage(e:NativeDragEvent):void
        {
            if (FileManager.isFileLoadBlocked())
            {
                return;
            }
            var c:Clipboard = e.clipboard;
            if (c.hasFormat("air:file list") === true)
            {
                if (isReplayStarted)
                    stopReplay();
                var files:Array = c.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
                // 두개이상 선택하고 드래그 할수있기 때문에 하나만 선택되었을때 되도록 해줌
                if (files && files.length == 1)
                {
                    NativeDragManager.acceptDragDrop(main.stage);
                }
            }
        }

        public static function createCacheImage
            (
                layer1ImageData:ByteArray,
                layer2ImageData:ByteArray,
                imageWidth:int,
                imageHeight:int,
                bgColor:uint,
                lastBytePosition:Number,
                frameSum:Number,
                mirrorFlag:Boolean
            ):void
        {
            const fs:FileStream = new FileStream();
            rJumpImageFrameData.push(frameSum);
            fs.open(FileManager.replayCacheImageFolderPath.resolvePath(String(rJumpImageFrameData.length - 1)), FileMode.WRITE);
            fs.writeObject([layer1ImageData // 0
                        , layer2ImageData
                        , imageWidth
                        , imageHeight
                        , bgColor // 4
                        , lastBytePosition
                        , frameSum
                        , mirrorFlag]); // 7
            fs.close();
        }

        public static function generateReplayCacheImage():void // loadrep
        {
            const fs:FileStream = new FileStream();
            const fs2:FileStream = new FileStream();
            const totalSize:Number = FileManager.replayDataFilePath.size;
            const deepUndoFlag:Boolean = UndoManager.isDeepUndoEnabled;
            var rect:Rectangle;
            var _frameSum:Number = 0;
            var _frameSumLast:Number = 0;
            var dataWriteCount:uint = 0;
            var hintPrintTimeSave:int = getTimer();
            CanvasController.canvasAnchorPoint.visible = false;
            rCanvasAnchorPoint.visible = false;
            CanvasController.canvasNavigatorBox.visible = false;
            UndoManager.addUndoData.resetRJumpImageCount();
            clearCanvasReplayMode(); // 리플레이 캔버스 먼저 깨끗하게
            // 첫 이미지 그려줌
            rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, rFirstImageLayer1BitmapData, rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, rFirstImageLayer2BitmapData, rCanvasLayer2Bitmap);
            // 크기도 바꿔주고
            updateCanvasSizeReplayMode(rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height);
            fs.open(FileManager.replayDataFilePath, FileMode.READ);
            fs.position = 0;
            rMirrorON = false;
            FileManager.loadMenuBox.visible = false;
            function printPrograssHint(bytes:Number):void
            {
                const perc:Number = Math.round(((totalSize - bytes) / totalSize) * 100);
                // const str:String = perc.toFixed(1)+"%";
                FileManager.loadMenuBox.updatePlaseWaitPrograss(perc + "%");
            }
            FileManager.loadMenuBox.showPleaseWait("Reading replay file");
            FileManager.openLoadMenuBox();
            function onFrameEnter(e:Event):void
            {
                while (true)
                {
                    const namojiBytes:Number = fs.bytesAvailable;
                    if (namojiBytes === 0)
                    {
                        main.stage.removeEventListener(Event.ENTER_FRAME, onFrameEnter);
                        fs.close();
                        drawReplayByCommand.clearData();
                        UndoManager.addUndoData.setRFileTotalFrame(_frameSum);
                        rReplayImageCacheState = REPLAY_IMAGE_CAHCHE_COMPLETE;
                        resetReplayTime();
                        updateTotalFrameAndReplayMaxSpeedFor10Sec(getTotalFrame());
                        rNowFrame = TOTAL_FRAME;
                        UndoManager.lastReplayFrameOnDeepUndoStart = TOTAL_FRAME;
                        rPrevFrame = _frameSumLast;
                        isReplayFinished = true;
                        if (UndoManager.mirrorCommandReady)
                        {
                            rMirrorON = !rMirrorON;
                            UndoManager.mirrorCommandReady = rMirrorON;
                        }
                        CanvasController.isCanvasMirrored = rMirrorON;
                        rMirrorON = rMirrorON;
                        UndoManager.addUndoData.updateUndoBaseImageMirrorFlag(rMirrorON);
                        CanvasController.canvasInfoBox.setMirror(rMirrorON);
                        CanvasController.canvasNavigatorBox.visible = true;
                        if (!isReplayModeON && UndoManager.isDeepUndoEnabled)
                        {
                            rDataReadFlag = false;
                            InputController.addInputEventsDrawMode();
                            // jumpFrame(undoData.getRFileTotalFrame()-1,JUMP_FRAME_ONCE);
                            renderReplayFrame(rPrevFrame, JUMP_FRAME_MANUAL);
                            main.applyReplayCanvasToDrawModeCanvas();
                            CanvasController.canvasAnchorPoint.visible = true;
                        }
                        else if (isReplayModeON)
                        {
                            updateReplayPrograssBarAndText();
                            updateReplaySpeedSliderAlpha();
                            updateDeleteReplayDataButtonsState();
                            clearRFrameTempCache();
                            rJumpImageIndexLast = -2;
                            rJumpImageNowFrameLast = -1;
                            rTempCachedLastImageIndex = -2;
                            UndoManager.disableDeepUndo();
                            UndoManager.undoToIndex(rData.length - 1);
                            CanvasController.centerCanvas("replay");
                            InputController.removeInputEventsDrawMode();
                            InputController.addInputEventsReplayMode();
                            rCanvasAnchorPoint.visible = true;
                        }
                        FileManager.closeLoadMenuBox();
                        InputController.clearKeyBuffer();
                        return;
                    }
                    if (getTimer() - hintPrintTimeSave > 250)
                    {
                        hintPrintTimeSave = getTimer();
                        printPrograssHint(namojiBytes);
                        return;
                    }
                    const data:Array = fs.readObject() as Array;
                    drawReplayByCommand.setData(data);
                    _frameSumLast = _frameSum;
                    _frameSum += data.length; // _rJumpImageCount 변수보다 먼저 와야함
                    dataWriteCount += data.length;
                    drawReplayByCommand.drawAll();
                    if (dataWriteCount > REPLAY_DISK_CACHE_FRAME_INTERVAL)
                    {
                        var imgData1:ByteArray = new ByteArray();
                        var imgData2:ByteArray = new ByteArray();
                        dataWriteCount = 0;
                        rect = new Rectangle(0, 0, rCanvasLayer1BitmapData.width, rCanvasLayer1BitmapData.height);
                        rCanvasLayer1BitmapData.copyPixelsToByteArray(rect, imgData1);
                        rCanvasLayer2BitmapData.copyPixelsToByteArray(rect, imgData2);
                        imgData1.compress();
                        imgData2.compress();
                        createCacheImage(imgData1,
                                imgData2,
                                rCanvasLayer1BitmapData.width,
                                rCanvasLayer1BitmapData.height,
                                rLastCanvasBGColor,
                                fs.position,
                                _frameSum,
                                rMirrorON);
                        imgData1.clear();
                        imgData2.clear();
                        if (MainUI.seekBarBox.prograssBar.width > 0)
                        {
                            MainUI.seekBarBox.resetReplayPrograssBarWidth();
                        }
                    }
                }
            }
            main.stage.addEventListener(Event.ENTER_FRAME, onFrameEnter);
        }

        public static function writeReplayFile(dataA:ByteArray
                , dataA1:ByteArray
                , dataB:ByteArray
                , dataB1:ByteArray
                , dataC:ByteArray
                , dataD:ByteArray):void
        {
            const fs:FileStream = new FileStream();
            const rImgDataW:int = rFirstImageLayer1BitmapData.width;
            const rImgDataH:int = rFirstImageLayer1BitmapData.height;
            const refImgWidth:Number = ReferenceLayerController.canvasRefLayerBitmapData.width;
            const refImgHeight:Number = ReferenceLayerController.canvasRefLayerBitmapData.height;
            // 실제 저장할 파일을 다시 써줌
            fs.open(repFileTemp, FileMode.WRITE);
            fs.position = 0;
            fs.writeUTFBytes("FOFOPAINT"); // 파일 헤더
            fs.writeUnsignedInt(dataD.length); // 뒤에 압축된 바이트를 얼마나 건너 뛰어야 하는지 저장
            fs.writeBytes(dataD);
            if (UndoManager.mirrorCommandReady) // 임시 미러가 되어있을때 진짜 캔버스로 반전되어있는데 리플레이 데이터에는 아직 써주지 않았으니까 넣어줌
            {
                const tempMirrorData:Array = [["mirror"]];
                fs.writeObject(tempMirrorData);
            }
            fs.writeObject(["rFirstImage", dataA, dataA1, rImgDataW, rImgDataH, rFirstImageBGColor]);
            fs.writeObject(["rFinalImage", dataB, dataB1, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, CanvasController.CANVAS_BG_COLOR]);
            if (ReferenceLayerController.canvasRefLayerBitmapData)
            {
                fs.writeObject(["refimage", dataC, // 1
                            refImgWidth,
                            refImgHeight,
                            ReferenceLayerController.canvasRefLayerBitmap.x,
                            ReferenceLayerController.canvasRefLayerBitmap.y,
                            ReferenceLayerController.canvasRefLayer.rotation,
                            ReferenceLayerController.canvasRefLayer.scaleX,
                            ReferenceLayerController.canvasRefLayer.scaleY,
                            Boolean(ReferenceLayerController.canvasRefLayer.scaleX < 0),
                            ReferenceLayerController.refLayerMenuDragXMoveSum, // 10
                            ReferenceLayerController.refLayerLastAlpha]); // 11
            }
            fs.close();
            dataA.clear();
            dataA1.clear();
            dataB.clear();
            dataB1.clear();
            dataC.clear();
            dataD.clear();
            dataA = null;
            dataA1 = null;
            dataB = null;
            dataB1 = null;
            dataC = null;
            dataD = null;
            try
            {
                const newPath:String = FileManager.lastSaveFilePath.substr(0, FileManager.lastSaveFilePath.lastIndexOf(".png")) + ".2020";
                repFileTemp.moveTo(new File(newPath), true);
            }
            catch (err:Error)
            {
                // 파일 엑세스가 불가하므로 새로운 파일로 저장해줌
                if (BackgroundWorkerCoordinator.isSaveInProgress === 1)
                {
                    BackgroundWorkerCoordinator.isSaveInProgress = 0;
                }
                FileManager.enableFileOperationButtonsTopbar();
                FileManager.openSaveFileBrowser(true, true);
                return;
            }
            if (BackgroundWorkerCoordinator.isSaveInProgress === 1)
            {
                BackgroundWorkerCoordinator.isSaveInProgress = 0;
            }
            FileManager.enableFileOperationButtonsTopbar();
        }

        public static function loadReplayFile(oldFile:File):void // loadrep
        {
            if (FileManager.isTrue2020File(oldFile) === false)
            {
                FileManager.showLoadFaildMouseHint();
                return;
            }
            const fs:FileStream = new FileStream();
            var imgStartByte:uint = 0;
            var finalIMGBMPD:BitmapData = new BitmapData(1, 1, true, 0);
            var finalIMGBMPD1:BitmapData = new BitmapData(1, 1, true, 0);
            var imgW:uint = 0;
            var imgH:uint = 0;
            var bg:uint = 0;
            var errorFlag:Boolean = true;
            var rect:Rectangle;
            initializeReplayDataFile(true); // 일단 썸네일 이미지랑 리플레이 데이터 청소
            oldFile.copyTo(repFileTemp, true); // repdata.c3p를 복사 덮어씌우기
            if (ReferenceLayerController.refLayerRawTransformData)
            {
                ReferenceLayerController.refLayerRawBitmapData.dispose();
                ReferenceLayerController.refLayerRawBitmapData = null;
                ReferenceLayerController.refLayerRawTransformData = null;
            }
            fs.open(repFileTemp, FileMode.READ);
            rJumpImageFrameData = [0];
            var d:Array;
            var ba:ByteArray;
            var replayData:ByteArray = new ByteArray();
            const isNew2020FileFlag:Boolean = FileManager.isNew2020File(oldFile);
            if (isNew2020FileFlag)
            {
                const a:String = fs.readUTFBytes(9); // FOFOPAINT헤더 읽어줌
                const compBytes:uint = fs.readUnsignedInt(); // 압축된 데이터 길이 읽어줌
                if (compBytes > 0)
                {
                    // 압축된 데이터 써주고 압축 풀어줌
                    fs.readBytes(replayData, 0, compBytes);
                    replayData.uncompress();
                }
            }
            while (true)
            {
                if (fs.bytesAvailable === 0)
                    break;
                d = fs.readObject();
                if (d[0] === "rFirstImage")
                {
                    if (d[2] is ByteArray === false)
                    {
                        ba = d[1] as ByteArray;
                        rect = new Rectangle(0, 0, d[2], d[3]);
                        ba.uncompress();
                        rFirstImageLayer1BitmapData = new BitmapData(d[2], d[3], true, 0);
                        rFirstImageLayer1BitmapData.lock();
                        rFirstImageLayer1BitmapData.setPixels(rect, ba);
                        rFirstImageLayer1BitmapData.unlock();
                        ba.clear();
                        ba = null;
                        rLastCanvasBGColor = d[4];
                        createFirstImageCache(rFirstImageLayer1BitmapData, null, d[4]);
                    }
                    else
                    {
                        ba = d[1] as ByteArray;
                        rect = new Rectangle(0, 0, d[3], d[4]);
                        ba.uncompress();
                        rFirstImageLayer1BitmapData = new BitmapData(d[3], d[4], true, 0);
                        rFirstImageLayer1BitmapData.lock();
                        rFirstImageLayer1BitmapData.setPixels(rect, ba);
                        rFirstImageLayer1BitmapData.unlock();
                        ba.clear();
                        ba = d[2] as ByteArray;
                        ba.uncompress();
                        rFirstImageLayer2BitmapData = new BitmapData(d[3], d[4], true, 0);
                        rFirstImageLayer2BitmapData.lock();
                        rFirstImageLayer2BitmapData.setPixels(rect, ba);
                        rFirstImageLayer2BitmapData.unlock();
                        ba.clear();
                        ba = null;
                        rLastCanvasBGColor = d[5];
                        createFirstImageCache(rFirstImageLayer1BitmapData, rFirstImageLayer2BitmapData, d[5]); // 0.cache 파일 갱신
                    }
                }
                else if (d[0] === "rFinalImage") // 최종 이미지
                {
                    // 레이어1일때 구버전
                    if (d[2] is ByteArray === false)
                    {
                        ba = d[1] as ByteArray;
                        rect = new Rectangle(0, 0, d[2], d[3]);
                        ba.uncompress();
                        errorFlag = false;
                        finalIMGBMPD = new BitmapData(d[2], d[3], true, 0);
                        finalIMGBMPD.lock();
                        finalIMGBMPD.setPixels(rect, ba);
                        finalIMGBMPD.unlock();
                        ba.clear();
                        ba = null;
                        imgW = d[2];
                        imgH = d[3];
                        bg = d[4];
                    }
                    else
                    {
                        ba = d[1] as ByteArray;
                        rect = new Rectangle(0, 0, d[3], d[4]);
                        ba.uncompress();
                        errorFlag = false;
                        finalIMGBMPD = new BitmapData(d[3], d[4], true, 0);
                        finalIMGBMPD.lock();
                        finalIMGBMPD.setPixels(rect, ba);
                        finalIMGBMPD.unlock();
                        ba.clear();
                        ba = d[2] as ByteArray;
                        ba.uncompress();
                        finalIMGBMPD1 = new BitmapData(d[3], d[4], true, 0);
                        finalIMGBMPD1.lock();
                        finalIMGBMPD1.setPixels(rect, ba);
                        finalIMGBMPD1.unlock();
                        ba.clear();
                        ba = null;
                        imgW = d[3];
                        imgH = d[4];
                        bg = d[5];
                    }
                }
                else if (d[0] === "refimage" || d[0] === "traceImage")
                {
                    ba = d[1] as ByteArray;
                    rect = new Rectangle(0, 0, d[2], d[3]);
                    ba.uncompress();
                    ReferenceLayerController.refLayerRawBitmapData = new BitmapData(d[2], d[3], true, 0);
                    ReferenceLayerController.refLayerRawBitmapData.lock();
                    ReferenceLayerController.refLayerRawBitmapData.setPixels(rect, ba);
                    ReferenceLayerController.refLayerRawBitmapData.unlock();
                    ba.clear();
                    ba = null;
                    d[0] = null;
                    d[1] = null;
                    ReferenceLayerController.refLayerRawTransformData = d.concat();
                }
                else if (isNew2020FileFlag) // 신포멧인데 rData옛 버전에서rData압축안하고 넣어준거 읽어줌
                {
                    replayData.position = replayData.length;
                    replayData.writeObject(d);
                }
                else
                {
                    imgStartByte = fs.position;
                }
            }
            fs.close();
            if (isNew2020FileFlag)
            {
                fs.open(FileManager.replayDataFilePath, FileMode.WRITE);
                fs.position = 0;
                fs.writeBytes(replayData);
                fs.close();
            }
            else
            {
                // 이미지직전까지 바이트를 기준으로 짤라줌, 즉 뒤에 붙은 첫 이미지 + 마지막 이미지를 지워줌
                fs.open(repFileTemp, FileMode.UPDATE);
                fs.position = imgStartByte;
                fs.truncate();
                fs.close();
                repFileTemp.moveTo(FileManager.replayDataFilePath, true);
            }
            if (repFileTemp.exists)
            {
                repFileTemp.deleteFile();
            }
            replayData.clear();
            replayData = null;
            rReplayImageCacheState = REPLAY_IMAGE_CAHCHE_READY;
            FileManager.finalizeLoadFile(imgW, imgH, finalIMGBMPD, finalIMGBMPD1, false, bg);
        }
        public static function loadImageFile(width:Number, height:Number, layer1Image:IBitmapDrawable, layer2Image:IBitmapDrawable):void
        {
            updateTotalFrameAndReplayMaxSpeedFor10Sec(0);
            UndoManager.addUndoData.setRFileTotalFrame(0);
            rReplayImageCacheState = REPLAY_IMAGE_CAHCHE_COMPLETE;
            ReferenceLayerController.refLayerRawBitmapData = null;
            ReferenceLayerController.refLayerRawTransformData = null;
            FileManager.finalizeLoadFile(width, height, layer1Image, layer2Image, true, 0xFFFFFF);
            initializeReplayDataFile(true); // 일단 썸네일 이미지랑 리플레이 데이터 청소
        }

        public static function saveReplayFrameData():void
        {
            const fs:FileStream = new FileStream();
            fs.open(FileManager.replayCacheImageFrameDataFilePath, FileMode.WRITE);
            fs.writeObject(rJumpImageFrameData);
            fs.close();
        }

        public static function resetRotationReplayMode():void
        {
            const center:Point = MainUIController.getStageCenterPos("replay");
            CanvasController.moveCanvasAnchorPoint(center.x, center.y, true);
            rCanvasAnchorPoint.rotation = 0;
            ReplayController.setRcursorRotation(0);
        }

        public static function syncMirrorReplayModeWithDrawMode():void
        {
            if (UndoManager.mirrorCommandReady)
            {
                mirrorCanvasReplayMode();
            }
        }

        public static function updateCanvasSizeReplayMode(w:Number, h:Number, moveX:Number = 0, moveY:Number = 0, movedFlag:Boolean = false):void
        {
            if (w === RCANVAS_WIDTH && h === RCANVAS_HEIGHT)
            {
                return;
            }
            const bgColor:uint = RCANVAS_BG_COLOR;
            // 캔버스가 회전되어있으면 회전된 방향으로 움직여줘야함
            rCanvasPanel.graphics.clear();
            rCanvasPanel.graphics.beginFill(bgColor);
            rCanvasPanel.graphics.drawRect(0, 0, w, h);
            rCanvasPanel.graphics.endFill();
            rCanvasPanel.scrollRect = new Rectangle(0, 0, w, h); // 마스크 다시 씌워줌
            rCanvasLayer1BitmapData = new BitmapData(w, h, true, 0);
            rCanvasLayer2BitmapData = new BitmapData(w, h, true, 0);
            rCanvasDrawLayerBitmapData = new BitmapData(w, h, true, 0);
            RCANVAS_WIDTH = w;
            RCANVAS_HEIGHT = h;
            if (movedFlag)
            {
                // movex y는 캔버스 사이즈 조절에서 원점이 움직였을경우 그만큼 bitmapdata를 움직여줘야 원래 이미지대로 나옴
                var mat:Matrix = new Matrix();
                mat.translate(moveX, moveY);
                rCanvasLayer1BitmapData.draw(rCanvasLayer1Bitmap, mat);
                rCanvasLayer2BitmapData.draw(rCanvasLayer2Bitmap, mat);
            }
            else
            {
                rCanvasLayer1BitmapData.draw(rCanvasLayer1Bitmap);
                rCanvasLayer2BitmapData.draw(rCanvasLayer2Bitmap);
            }
            if (rCanvasLayer1Bitmap.bitmapData)
                rCanvasLayer1Bitmap.bitmapData.dispose();
            rCanvasLayer1Bitmap.bitmapData = rCanvasLayer1BitmapData;
            if (rCanvasLayer2Bitmap.bitmapData)
                rCanvasLayer2Bitmap.bitmapData.dispose();
            rCanvasLayer2Bitmap.bitmapData = rCanvasLayer2BitmapData;
            rFollowMouse.updateBounds();
            CanvasController.keepCanvasPanelInStage(true);
            if (isReplayCanvasFitToWindow)
            {
                fitReplayCanvasToViewport();
            }
        }

        public static function initializeReplayCanvas():void
        {
            rCanvasPanel.name = "rCanvasPanel";
            rCanvasAnchorPoint.name = "rCanvasAnchorPoint";
            rCanvasLayer1Bitmap.name = "rCanvasLayer1Bitmap";
            rCanvasLayer2Bitmap.name = "rCanvasLayer2Bitmap";
            rCanvasCompleteBitmap.name = "rCanvasCompleteBitmap";
            rCanvasCompleteAnchorPoint.name = "rCanvasCompleteAnchorPoint";
            rCanvasDrawLayer.name = "rCanvasDrawLayer";
            rCanvasDrawShape.name = "rCanvasDrawShape";
            MainUI.seekBarBox.name = "seekBarBox";
            rReplayFOFOCursor.name = "rCursor";
            rReplayFOFOCursor.mouseEnabled = false;
            rCanvasCompleteAnchorPoint.addChild(rCanvasCompleteBitmap);
            rCanvasPanel.graphics.beginFill(CanvasController.CANVAS_BG_COLOR);
            rCanvasPanel.graphics.drawRect(0, 0, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
            rCanvasPanel.graphics.endFill();
            rCanvasDrawLayer.addChild(rCanvasDrawLayerBitmap);
            rCanvasDrawLayer.addChild(rCanvasDrawShape);
            rCanvasDrawLayer.blendMode = "layer"; // 캔버스1이랑 알파 불투명도가 겹치지 않게 layer모드로 해줌
            rCanvasPanel.addChild(rCanvasLayer2Bitmap);
            rCanvasPanel.addChild(rCanvasLayer1Bitmap);
            rCanvasPanel.addChild(rCanvasDrawLayer);
            rCanvasPanel.scrollRect = new Rectangle(0, 0, RCANVAS_WIDTH, RCANVAS_HEIGHT); // 마스크 해줘서 판 밖으로 선나타나지 않도록함
            rCanvasPanel.x = Math.floor(-rCanvasPanel.width / 2);
            rCanvasPanel.y = Math.floor(-rCanvasPanel.height / 2);
            rCanvasAnchorPoint.addChild(rCanvasPanel);
            rCanvasAnchorPoint.visible = false;
            main.stage.addChild(rCanvasAnchorPoint);
            main.stage.addChild(MainUI.seekBarBox);
            MainUI.seekBarBox.x = 0;
        }

        public static function clearCanvasReplayMode():void
        {
            const rect:Rectangle = new Rectangle(0, 0, RCANVAS_WIDTH, RCANVAS_HEIGHT);
            rCanvasDrawShape.graphics.clear();
            rCanvasLayer1BitmapData.fillRect(rect, 0);
            rCanvasLayer2BitmapData.fillRect(rect, 0);
            rCanvasDrawLayerBitmapData.fillRect(rect, 0);
        }

        public static function showReplaySpeedMouseHint():void
        {
            const timeStr:String = getReplayRemainingTimeString(rReplaySpeedMultipler, TOTAL_FRAME);
            const finalStr:String = HintStrings.getReplaySpeedHintString(rReplaySpeedMultipler, timeStr);
            MainUI.showMouseHintTemp(finalStr);
        }
        // keyfunc
        public static function adjustReplaySpeedByShortcut(increaseFlag:Boolean):void
        {
            const clacMax:Number = Math.floor(TOTAL_FRAME / (main.stage.frameRate * 3));
            if (clacMax <= 0)
            {
                return;
            }
            const maxSpeed:Number = REPLAY_MAX_SPEED;
            var _rSpeed:Number = rReplaySpeedMultipler;
            if (increaseFlag)
            {
                _rSpeed += 1;
                if (_rSpeed > maxSpeed)
                {
                    _rSpeed = maxSpeed;
                }
            }
            else
            {
                _rSpeed -= 1;
                if (_rSpeed < 1)
                {
                    _rSpeed = 1;
                }
            }
            rReplaySpeedMultipler = _rSpeed;
            MainUI.topBar.setSpeedButtonPosByValue(_rSpeed, maxSpeed);
            showReplaySpeedMouseHint();
        }
        public static function startAdjustPlayBackSpeedByShortcut(increase:Boolean):void
        {
            InputController.startKeyRepeat(true, adjustReplaySpeedByShortcut, increase);
        }
        public static function adjutReplaySpeedByMouse():void
        {
            const totalF:Number = TOTAL_FRAME;
            if (totalF <= main.stage.frameRate * 3) // 3초 이내면 안함
            {
                return;
            }
            // setSpeedButtonPosByValue도 오프셋 수정해주어야함
            const minDist:Number = MainUI.topBar.replaySpeedSlider.x + 1.5;
            const maxDist:Number = minDist + MainUI.topBar.replaySpeedSlider.width - 2.5;
            const maxSpeed:Number = REPLAY_MAX_SPEED;
            var oldSpeed:Number;
            PenSizePreviewCursor.setCursorInVisibleFlag(true);
            CanvasController.isMouseDragging = true;
            function setSpeed(mx:Number):void
            {
                var exp:Number = mx / maxDist;
                if (exp < 0)
                {
                    exp = 0;
                }
                else if (exp > 1)
                {
                    exp = 1;
                }
                var nowSpeed:Number = Math.floor(Math.pow(maxSpeed, exp));
                if (oldSpeed !== nowSpeed)
                {
                    oldSpeed = nowSpeed;
                    if (nowSpeed > maxSpeed)
                    {
                        nowSpeed = maxSpeed;
                    }
                    rReplaySpeedMultipler = nowSpeed;
                }
            }
            function moveButton(mx:Number):void
            {
                if (mx < minDist)
                {
                    mx = minDist;
                }
                else if (mx > maxDist)
                {
                    mx = maxDist;
                }
                MainUI.topBar.replaySpeedSliderCursor.x = mx;
                setSpeed(mx);
                showReplaySpeedMouseHint();
                if (isReplayFinished === false)
                {
                    updateReplayPrograssText();
                }
            }
            function replaySpeedButtomUpEvent(e:MouseEvent):void
            {
                CanvasController.isMouseDragging = false;
                if (isReplayFinished === false)
                {
                    updateReplayPrograssText();
                }
                main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, replaySpeedButtomMoveEvent);
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, replaySpeedButtomUpEvent);
            }
            function replaySpeedButtomMoveEvent(e:MouseEvent):void
            {
                moveButton(MainUI.topBar.replaySpeedSliderWrapper.mouseX);
            }
            moveButton(MainUI.topBar.replaySpeedSliderWrapper.mouseX);
            setSpeed(MainUI.topBar.replaySpeedSliderWrapper.mouseX);
            showReplaySpeedMouseHint();
            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, replaySpeedButtomMoveEvent);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, replaySpeedButtomUpEvent);
        }

        public static function updateReplaySpeedSliderAlpha():void
        {
            if (REPLAY_MAX_SPEED === 1.0)
            {
                MainUI.topBar.replaySpeedSliderWrapper.alpha = Global.OFFALPHA;
            }
            else
            {
                MainUI.topBar.replaySpeedSliderWrapper.alpha = 1.0;
            }
        }
        public static function updateReplayPrograssBarAndText():void
        {
            const totalFrame:Number = TOTAL_FRAME;
            const nowFrame:Number = rNowFrame;
            const trackBarWidth:Number = MainUI.seekBarBox.trackBar.width;
            MainUI.seekBarBox.prograssInfo.text = nowFrame + " / " + totalFrame;
            MainUI.seekBarBox.prograssBar.width = (totalFrame === 0) ? 0 : trackBarWidth * (nowFrame / totalFrame);
        }
        public static function updateReplayCursorScale(zoom:Number):void
        {
            const z:Number = 1.0 / zoom;
            rReplayFOFOCursor.scaleX = z;
            rReplayFOFOCursor.scaleY = z;
        }

        public static function startGeneratingReplayCacheImage():void
        {
            rReplayImageCacheState = REPLAY_IMAGE_CAHCHE_PROCESSING;
            if (!FOFOTimer.hasTimer("generatereplaycacheimagedelay"))
            {
                FOFOTimer.addByName("generatereplaycacheimagedelay", 0.1, false, function ():void
                    {
                        generateReplayCacheImage();
                    });
            }
        }
        public static function syncDrawCanvasWithReplayMode():void
        {
            CanvasController.canvasZoomMultipler = rCanvasZoomMultiplier; // 줌배율도 공유
            CanvasController.canvasZoomIndex = rCanvasZoomIndex;
            CanvasController.canvasAnchorPoint.scaleX = rCanvasAnchorPoint.scaleX;
            CanvasController.canvasAnchorPoint.scaleY = rCanvasAnchorPoint.scaleY;
            CanvasController.canvasAnchorPoint.rotation = rCanvasAnchorPoint.rotation;
            CanvasController.canvasAnchorPoint.x = rCanvasAnchorPoint.x;
            CanvasController.canvasAnchorPoint.y = rCanvasAnchorPoint.y;
            rCanvasPanel.x = rCanvasPanel.x;
            rCanvasPanel.y = rCanvasPanel.y;
            ReplayController.setRcursorRotation(CanvasController.canvasAnchorPoint.rotation);
        }
        public static function syncReplayCanvasWithDrawMode():void
        {
            rCanvasZoomMultiplier = CanvasController.canvasZoomMultipler; // 줌배율도 공유
            rCanvasZoomIndex = CanvasController.canvasZoomIndex;
            rCanvasAnchorPoint.scaleX = CanvasController.canvasAnchorPoint.scaleX;
            rCanvasAnchorPoint.scaleY = CanvasController.canvasAnchorPoint.scaleY;
            rCanvasAnchorPoint.rotation = CanvasController.canvasAnchorPoint.rotation;
            rCanvasAnchorPoint.x = CanvasController.canvasAnchorPoint.x;
            rCanvasAnchorPoint.y = CanvasController.canvasAnchorPoint.y;
            rCanvasPanel.x = CanvasController.canvasPanel.x;
            rCanvasPanel.y = CanvasController.canvasPanel.y;
            ReplayController.setRcursorRotation(rCanvasAnchorPoint.rotation);
        }
        public static function syncReplayCanvasImageWithDrawMode():void
        {
            rCanvasDrawShape.graphics.clear();
            rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, CanvasController.canvasLayer1BitmapData, rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, CanvasController.canvasLayer2BitmapData, rCanvasLayer2Bitmap);
            updateCanvasSizeReplayMode(CanvasController.canvasLayer1Bitmap.width, CanvasController.canvasLayer1Bitmap.height);
            updateCanvasBGColorReplayMode(CanvasController.CANVAS_BG_COLOR);
        }
        public static function updateReplayTimeBarFromDrawMode():void
        {
            updateReplayPrograssText(true, rNowFrame);
            if (TOTAL_FRAME === 0)
            {
                MainUI.seekBarBox.resetReplayPrograssBarWidth();
            }
            else
            {
                MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(rNowFrame / TOTAL_FRAME);
            }
        }

        public static function exitReplayMode():void
        {
            if (isGeneratingCacheImages())
            {
                return;
            }
            if (isReplayStarted === true)
            {
                stopReplay();
            }
            InputController.removeInputEventsReplayMode();
            cancelReplayRestartTimer();
            isReplayModeON = false;
            rCanvasAnchorPoint.visible = false;
            rReplayFOFOCursor.visible = false;
            MainUI.seekBarBox.visible = false;
            CanvasController.canvasAnchorPoint.visible = true;
            PenSizePreviewCursor.setCursorInVisibleFlag(false);
            PenSizePreviewCursor.setVisible(true);
            if (ReferenceLayerController.isRefLayerMenuON === true)
            {
                ReferenceLayerController.refLayerMenuBox.visible = true;
            }
            if (SidebarController.isSidebarVisible === true)
            {
                SidebarController.showSidebarPermanent();
            }
            CanvasController.canvasPanel.addChild(rReplayFOFOCursor);
            ReplayController.setRcursorRotation(CanvasController.canvasAnchorPoint.rotation);
            if (MainUI.mouseHint.isShowing())
            {
                MainUI.hideMouseHint();
            }
            MainUI.seekBarBox.pauseButton.visible = false;
            Utils.setAsTopChild(MainUI.seekBarBox);
            MainUI.seekBarBox.setDeleteRangeBarVisible(false);
            MainUIController.updateStageOffset();
            MainUIController.updateCanvasNaigatorCursor();
            if (PenTool.isTransparentPenColor)
            {
                ColorPickerController.selectTransparentColor();
            }
            else
            {
                ColorPickerController.switchColorPickerModePen();
            }
            PenSizePreviewCursor.updateSizeAndShape();
            PenSizePreviewCursor.updatePosAndVisibility();
            MainUI.updateTopbarIconsDrawMode();
            CanvasController.canvasInfoBox.setZoom(CanvasController.canvasZoomMultipler);
            updateReplayCursorScale(CanvasController.canvasZoomMultipler);
            UndoManager.isDeepUndoEnabled = UndoManager.lastDeepUndoEnabledFlag;
            if (rNowFrame !== UndoManager.lastReplayFrameOnDeepUndoStart)
            {
                // after로 해주는 이유는 캐쉬 안만들어줄라고
                renderReplayFrame(UndoManager.lastReplayFrameOnDeepUndoStart, JUMP_FRAME_NEXT);
            }
            clearRFrameTempCache();
            rReplayFOFOCursor.visible = false;
            InputController.addInputEventsDrawMode();
        }
        public static function enterReplayMode():void
        {
            if (isGeneratingCacheImages())
            {
                return;
            }
            InputController.removeInputEventsDrawMode();
            isReplayModeON = true;
            CanvasController.canvasAnchorPoint.visible = false;
            rCanvasAnchorPoint.visible = true;
            MainUI.seekBarBox.visible = true;
            PenSizePreviewCursor.setCursorInVisibleFlag(true);
            PenSizePreviewCursor.setVisible(false);
            MainUI.seekBarBox.pauseButton.visible = false;
            MainUI.seekBarBox.y = Math.floor(MainUI.topBar.BARSIZE * Global.getUIScale() - 4);
            lastReplayTimeBoxYPos = MainUI.seekBarBox.y;
            Utils.setAsTopChild(MainUI.seekBarBox);
            MainUI.seekBarBox.setDeleteRangeBarVisible(false);
            if (ColorPickerController.numPadBox.visible)
            {
                ColorPickerController.closeNumpad();
            }
            if (MainUI.mouseHint.isShowing())
            {
                MainUI.hideMouseHint();
            }
            rReplayFOFOCursor.alpha = 1.0;
            rReplayFOFOCursor.visible = false;
            rCanvasPanel.addChild(rReplayFOFOCursor);
            Utils.setAsTopChild(rReplayFOFOCursor);
            ReplayController.setRcursorRotation(rCanvasAnchorPoint.rotation);
            MainUIController.updateStageOffset();
            FOFOTimer.remove("rCursorOffAlphaAnimTimer");
            MainUI.hideBottomHint();
            UndoManager.lastDeepUndoEnabledFlag = UndoManager.isDeepUndoEnabled;
            UndoManager.isDeepUndoEnabled = false;
            UndoManager.lastReplayFrameOnDeepUndoStart = rNowFrame;
            updateTotalFrameAndReplayMaxSpeedFor10Sec(getTotalFrame()); // 최대 속도 계산
            updateReplayPrograssBarAndText();
            updateReplaySpeedSliderAlpha();
            MainUI.seekBarBox.updatePos(main.stage.stageWidth);
            rFollowMouse.updateBounds();
            updateReplayCursorScale(rCanvasZoomMultiplier);
            if (ReferenceLayerController.isRefLayerMenuON === true)
            {
                ReferenceLayerController.refLayerMenuBox.visible = false;
            }
            if (rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_READY)
            {
                InputController.removeKeyRepeatEvents(null);
                InputController.removeInputEventsReplayMode();
                SidebarController.hideSidebarTemporary();
                MainUI.updateTopbarIconsReplayMode();
                startGeneratingReplayCacheImage();
            }
            else if (rReplayImageCacheState === REPLAY_IMAGE_CAHCHE_COMPLETE)
            {
                rDataReadFlag = false;
                updateReplayTimeBarFromDrawMode();
                CanvasController.centerCanvas("replay");
                // fitCanvasToViewportMargin();
                // 이거 안해주고 리플레이틀고 프레임 조작 안하고 재생하면 중간부터 되서 데이터가 꼬임
                isReplayFinished = true;
                if (UndoManager.undoDataIndex >= 0)
                {
                    rDataStartIndex = UndoManager.undoDataIndex + 1;
                    rDataReadFlag = true;
                }
                else
                {
                    rDataStartIndex = 0;
                    rDataReadFlag = false;
                }
                updateDeleteReplayDataButtonsState();
                isReplaySlideShowMode = false;
                CanvasController.keepCanvasPanelInStage(true);
                SidebarController.hideSidebarTemporary();
                MainUI.updateTopbarIconsReplayMode();
                InputController.addInputEventsReplayMode();
            }
        }
        public static function setFitReplayCanvasToViewportOFF():void
        {
            isReplayCanvasFitToWindow = false;
        }
        public static function setFitReplayCanvasToViewportON():void
        {
            isReplayCanvasFitToWindow = true;
            fitReplayCanvasToViewport();
        }
        public static function fitReplayCanvasToViewport():void
        {
            FOFOTimer.addByName("rFitZoomedDelayTimer", 0.15, false, function ():void
                {
                    CanvasController.fitCanvasToViewportMargin(true);
                    rCanvasZoomIndex = CanvasController.getNearZoomIndex(rCanvasZoomMultiplier);
                    rCanvasZoomMultiplier = CanvasController.canvasZoomMultiplerList[rCanvasZoomIndex];
                });
        }

        public static function updateRCanvasDrawLayerCliprect2():void
        {
            rCanvasDrawLayerClipRect = rCanvasDrawLayerClipRect.union(rCanvasDrawShape.getBounds(rCanvasPanel));
        }

        public static function updateReplayCanvasFromUndoRefData(undoRefData:Array, undoIndexSave:int):void
        {
            rDataReadFlag = true;
            rDataIndex = undoIndexSave;
            rPrevFrame = rNowFrame;
            rNowFrame = UndoManager.getNowFrameUntilUndoIndex(undoIndexSave);
            rMirrorON = undoRefData[5];

            if (undoRefData[2] !== RCANVAS_WIDTH || undoRefData[3] !== RCANVAS_HEIGHT)
            {
                updateCanvasSizeReplayMode(undoRefData[2], undoRefData[3], 0, 0, false);
            }

            if (undoRefData[4] !== RCANVAS_BG_COLOR)
            {
                updateCanvasBGColorReplayMode(undoRefData[4]);
            }

            rCanvasDrawShape.graphics.clear();
            rCanvasLayer1BitmapData = CanvasController.updateBitmapData(rCanvasLayer1BitmapData, undoRefData[0], rCanvasLayer1Bitmap);
            rCanvasLayer2BitmapData = CanvasController.updateBitmapData(rCanvasLayer2BitmapData, undoRefData[1], rCanvasLayer2Bitmap);

            if (rData.length > 0)
            {
                for (var i:int = 0;i <= undoIndexSave;i++)
                {
                    if (!rData[i])
                        continue;
                    drawReplayByCommand.setData(rData[i]);
                    drawReplayByCommand.drawAll();
                }
            }

            ColorPickerController.updateCanvasBGColorDrawMode(RCANVAS_BG_COLOR);
            CanvasController.updateCavnvasSizeDrawMode(RCANVAS_WIDTH, RCANVAS_HEIGHT, 0, 0, false);
        }

        public static function setRcursorRotation(newAngle:Number):void
        {
            ReplayController.rReplayFOFOCursor.rotation = -newAngle;
        }
    }
}
