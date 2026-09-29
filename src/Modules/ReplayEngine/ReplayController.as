package Modules.ReplayEngine
{
    import Modules.Tools.PenTool;
    import flash.desktop.Clipboard;
    import flash.desktop.ClipboardFormats;
    import flash.desktop.NativeDragManager;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.NativeDragEvent;
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
    import Modules.BackgroundWorkerCoordinator;
    import Modules.CacheImageMetaData;
    import Modules.CanvasController;
    import Modules.CanvasGridOverlay;
    import Modules.CaptureArea;
    import Modules.CaptureController;
    import Modules.ColorPickerController;
    import Modules.DragInteraction;
    import Modules.FileManager;
    import Modules.ImageViewWindow;
    import Modules.InputManager;
    import Modules.MainUI;
    import Modules.MainUIController;
    import Modules.PenSizePreviewCursor;
    import Modules.ReferenceLayerController;
    import Modules.SidebarController;
    import Modules.UndoController;
    import Modules.UndoManager;
    import Modules.Utils;

    public class ReplayController
    {
        // todo r캔버스는 따로 분리해야함, r캔버스 줌 회전 툴등 조작하는것도 분리해야함
        // 일부 접근자 private로 변경했는데 모듈 완전히 분리하고 나서 해야함 오류나는것들 점검
        // todo 리플레이 저장형식을 바이너리로 다시 대체, 실시간 입력 기반으로 각 프레임마다 그리지 말고 실제 시간 지연을 녹화
        // todo 리플레이 실행중일때 탐색바만 나오는데 리플레이 속도 조절할수있게 같이 나오게 해야함 ui고민
        // todo playback speed 키보드로 조정할때 힌트 박스를 topbar 아래쪽으로 직관적으로 보이게 조정
        // todo 탐색바 힌트를 표시한 채로 f1으로 드로우 모드에 진입하면 테두리랑 힌트가 남음
        // todo 그런데 컷 잘라주면 다시 0프레임부터 시작되는데 아까는 왜 중간부터 시작되었는지 모르겠음
        public static var main:Main;

        public static var rFollowMouse:Object;
        private static var replayHideCursor:Object;
        private static const REPLAY_SLIDESHOW_ACTIVE_SPEED:Number = 60;
        private static const REPLAY_SLIDESHOW_FRAME_RATE:Number = 2; // 1/2초 = 0.5초마다 갱신
        private static const REPLAY_SLIDESHOW_UPDATE_TIME:Number = 1000 / REPLAY_SLIDESHOW_FRAME_RATE;
        private static var rCanvasCompleteAnchorPoint:Sprite = new Sprite(); // 리플레이에어 이미지가 재생되었을때 보여주는 객체 stage와 가로세로 중앙정렬
        private static var rCanvasCompleteBitmap:Bitmap = new Bitmap(new BitmapData(1, 1, false, 0), "auto", true);
        private static var updatePrograssBarStartTime:int = 0; // 리플레이 시작 시간저장 update prograss bar에서 프레임 오차 수정할때 참고하는 변수
        private static var rReplayRestartTimerCount:uint = 0; // 리스타트 타이머
        private static var rSeekbarTextUpdateTime:int = 0; // 프레임 바 딜레이
        private static var stopGeneratingCacheImageFunc:Function = null; // 캐시 이미지 만드는 중이면 멈추는 함수
        public static var lastReplayTimeBoxYPos:Number = 0; // 리플레이 재생해줄때 WorkspaceView.topbar 사라지게 할때 원래 위치 저장해서 끝나면 이 위치로 복원해줌

        public static function setMainInstance(instance:Main):void
        {
            main = instance;
            rFollowMouse = cReplayFollowMouse();
            replayHideCursor = cReplayHideCursor();
        }

        public static function createNewFileFromReplayCanvas():void
        {
            MainUI.seekBarBox.setDeleteRangeBarVisible(false);
            // 길게 누르는 동안 worker가 시작되었을 수 있음
            if (FileManager.isReplayDataLocked())
            {
                FileManager.showReplayDataLockedHint();
                return;
            }
            copyReplayCanvasDataToDrawCanvas();
            clearDataAndResetVars();
            syncDrawCanvasWithReplayCanvas();
            exitReplayMode();
            UndoManager.exitDeepUndo();
            resetReplayTime();
            ReferenceLayerController.resetRefLayerImageTransform();
        }

        public static function updateTotalFrameAndReplayMaxSpeedFor10Sec(totalframe:Number):void
        {
            ReplayState.TOTAL_FRAME = totalframe;
            var maxSpeed:Number = Math.floor(totalframe / 10 / main.stage.frameRate);

            if (maxSpeed < 1.0)
            {
                maxSpeed = 1.0;
            }

            ReplayState.REPLAY_MAX_SPEED = maxSpeed;

            if (ReplayState.rReplaySpeedMultipler > maxSpeed)
            {
                ReplayState.rReplaySpeedMultipler = maxSpeed;
            }
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
                if (ReplayState.isReplayStarted)
                    stopReplay();
                var files:Array = c.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
                // 두개이상 선택하고 드래그 할수있기 때문에 하나만 선택되었을때 되도록 해줌

                if (files && files.length == 1)
                {
                    NativeDragManager.acceptDragDrop(main.stage);
                }
            }
        }

        public static function deleteReplayDataBeforeCurrentFrame():void
        {
            if (FileManager.isReplayDataLocked())
            {
                MainUI.seekBarBox.setDeleteRangeBarVisible(false);
                FileManager.showReplayDataLockedHint();
                return;
            }
            // 미러 되어있을 수도 있기 때문에 원래 프레임으로 점프해준뒤에 실행해줌
            ensureReplayCanvasState();
            MainUI.seekBarBox.setDeleteRangeBarVisible(false);
            ReplayFileCache.createFirstImageCache(ReplayDrawer.rCanvasLayer1BitmapData, ReplayDrawer.rCanvasLayer2BitmapData, ReplayState.RCANVAS_BG_COLOR, ReplayState.rMirrorON);
            const fs:FileStream = new FileStream();

            if (ReplayState.rMemoryDataReadON)
            {
                // repfile 초기화
                UndoController.updateUndoBaseImageFromReplayMode();
                fs.open(FileManager.replayDataFilePath, FileMode.WRITE); // 파일 생성
                fs.close();
                FileManager.isFileAlreadySaved = false;
                FileManager.enableNewFileButton();
                ReplayState.setRFileDataTotalFrame(0);
                ReplayState.rMemoryData.splice(0, ReplayState.rMemoryDataIndex + 1);
                ReplayState.rMemoryDataFrame.splice(0, ReplayState.rMemoryDataIndex + 1);
                updateTotalFrameAndReplayMaxSpeedFor10Sec(ReplayState.getTotalFrame());
                updateReplayPrograssText(true, ReplayState.TOTAL_FRAME);

                if (ReplayState.TOTAL_FRAME === 0)
                {
                    MainUI.seekBarBox.resetReplayPrograssBarWidth();
                }
                else
                {
                    MainUI.seekBarBox.setReplayPrograssBarMaxWidth();
                }

                MainUI.topBar.repNewFileButton.alpha = Global.OFFALPHA;
                ReplayDrawer.rReplayFOFOCursor.visible = false;
                finalize();
            }
            else
            {
                // make jumpimage에서 변경해주기 때문에

                if (FileManager.repFileTemp.exists) // 이미 있으면 지워주고
                {
                    FileManager.repFileTemp.deleteFile();
                }

                var ba:ByteArray = new ByteArray();
                var d:Array;
                // 짤라서 ba에 넣어주기
                fs.open(FileManager.replayDataFilePath, FileMode.READ);
                fs.position = ReplayState.rFileLastBytePosition;
                fs.readBytes(ba, 0, fs.bytesAvailable);
                fs.close();
                // ba에 넣어준걸 다시 써주기
                fs.open(FileManager.replayDataFilePath, FileMode.WRITE);
                fs.position = 0;
                fs.writeBytes(ba, 0, ba.length);
                fs.close();
                ba.clear();
                ba = null;
                ReplayDrawer.rReplayFOFOCursor.visible = false;
                MainUI.seekBarBox.resetReplayPrograssBarWidth();
                FileManager.isFileAlreadySaved = false;
                FileManager.loadMenuBox.clearPreviewImage(); // 이 경우 로드박스에 배경 이미지를 깔지 않음
                startGeneratingReplayCacheImage(false, finalize);
            }

            function finalize():void
            {
                resetReplaySpeedBar();
                ReplayState.isReplayFinished = true;

                if (UndoManager.undoDataIndex > ReplayState.rMemoryData.length - 1)
                {
                    UndoManager.undoDataIndex = ReplayState.rMemoryData.length - 1;
                }

                UndoManager.undoToIndex(UndoManager.undoDataIndex);
                UndoManager.exitDeepUndo();
                updateReplayPrograssBarAndText();
                updateReplaySpeedSliderAlpha();
                ReplayDrawCommands.setFirstRCursorPosCurrent();
                ReferenceLayerController.resetRefLayerImageTransform();
            }
        }

        public static function deleteReplayDataAfterCurrentFrame():void
        {
            if (FileManager.isReplayDataLocked())
            {
                MainUI.seekBarBox.setDeleteRangeBarVisible(false);
                FileManager.showReplayDataLockedHint();
                return;
            }
            ensureReplayCanvasState();
            MainUI.seekBarBox.setDeleteRangeBarVisible(false);

            if (ReplayState.rMemoryDataReadON === true)
            {
                // 위에서 setJumpOneFrame을 해줘서 rindex가 증가되었기 때문에
                // 실제 undo해줘야할 인덱스는 -1해줘야하는거임
                UndoManager.undoToIndex(ReplayState.rMemoryDataIndex);
                ReplayState.rMemoryData.splice(ReplayState.rMemoryDataIndex + 1);
                ReplayState.rMemoryDataFrame.splice(ReplayState.rMemoryDataIndex + 1);
                updateTotalFrameAndReplayMaxSpeedFor10Sec(ReplayState.getTotalFrame());
                resetReplayTime();
            }
            else if (ReplayState.rMemoryDataReadON === false)
            {
                ReplayDrawCommands.setFirstRCursorPosCurrent();
                const fs:FileStream = new FileStream();
                fs.open(FileManager.replayDataFilePath, FileMode.UPDATE);
                fs.position = ReplayState.rFileLastBytePosition;
                fs.truncate(); // 데이터 위에 짤라주고
                fs.close();
                // 썸네일 이미지도 날려줌
                const rNowFrameSave:Number = ReplayState.rNowFrame;
                ReplayFileCache.truncateCacheImagesAfterFrame(rNowFrameSave);
                ReplayState.setRFileDataTotalFrame(rNowFrameSave);
                updateTotalFrameAndReplayMaxSpeedFor10Sec(rNowFrameSave);
                CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, ReplayDrawer.rCanvasLayer1BitmapData, CanvasController.canvasLayer1Bitmap);
                CanvasController.canvasLayer1Bitmap.bitmapData = CanvasController.canvasLayer1BitmapData;
                CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, ReplayDrawer.rCanvasLayer2BitmapData, CanvasController.canvasLayer2Bitmap);
                CanvasController.canvasLayer2Bitmap.bitmapData = CanvasController.canvasLayer2BitmapData;
                CanvasController.setCavnvasSizeDrawMode(CanvasController.canvasLayer1Bitmap.width, CanvasController.canvasLayer1Bitmap.height, 0, 0, false);
                CanvasController.setCanvasBGColorDrawMode(ReplayState.RCANVAS_BG_COLOR);
                CanvasController.updateCanvasPanelColorAndSize();
                resetReplayTime();
                syncDrawCanvasWithReplayCanvas();
                UndoManager.resetUndoState();
                CanvasController.canvasNavigatorBox.updateImage();

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
            UndoManager.exitDeepUndo();
            ReferenceLayerController.resetRefLayerImageTransform();

            if (SidebarController.isQuickSidebarActive)
            {
                SidebarController.deactivateQuickSidebar();
            }

            FileManager.isContinueSaveON = false;
        }

        public static function prepareDeleteReplayData(mode:String):Boolean
        {
            // true를 반환하면 길게 누르기가 시작되지 않음
            if (FileManager.isReplayDataLocked())
            {
                return true;
            }
            if (mode !== "total")
            {
                if (ReplayDrawCommands.getCurrentPosition() < ReplayDrawCommands.getDataLength())
                {
                    ReplayDrawer.finalizeRemainingReplayData();
                    updateReplayPrograssText();
                    MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayState.rNowFrame / ReplayState.TOTAL_FRAME);
                    updateDeleteReplayDataButtonsState();
                }

                if (ReplayState.rNowFrame >= ReplayState.TOTAL_FRAME)
                {
                    MainUI.seekBarBox.setDeleteRangeBarVisible(false);
                    return true;
                }
            }

            MainUI.seekBarBox.updateDeleteDangeBarPosWidth(mode);
            return false;
        }

        public static function drawCanvasFromReplayDataSlideShowMode():void
        {
            const nowTime:int = getTimer();

            if (nowTime - rSeekbarTextUpdateTime >= REPLAY_SLIDESHOW_UPDATE_TIME)
            {
                rSeekbarTextUpdateTime = nowTime;
                const nextFrame:Number = ReplayState.rReplaySpeedMultipler * main.stage.frameRate;
                const shouldStop:Boolean = ReplayDrawer.renderReplayFrame(ReplayState.rNowFrame + Math.floor(nextFrame / REPLAY_SLIDESHOW_FRAME_RATE), ReplayDrawer.JUMP_FRAME_MANUAL);

                if (shouldStop)
                {
                    stopReplay();

                    // 예전에는 renderReplayFrame 안에서 정지된 뒤(슬라이드쇼 플래그 꺼진 상태로) 실행되던 검사라서 순서 유지를 위해 여기서 다시 해줌
                    if (!ReplayState.isReplaySlideShowMode && !ReplayState.isReplayCanvasFitToWindow && !UndoManager.isDeepUndoEnabled)
                    {
                        rFollowMouse.check(true);
                    }
                }

                if (ReplayState.rNowFrame >= ReplayState.TOTAL_FRAME)
                {
                    ReplayState.isReplayFinished = true;
                    stopReplay();
                }
            }
        }

        public static function updateDeleteReplayDataButtonsState():void
        {
            if (ReplayState.isGeneratingCacheImages() || FileManager.isReplayDataLocked() || ReplayState.isReplayStarted)
            {
                MainUI.topBar.superUndoButton.alpha = Global.OFFALPHA;
                MainUI.topBar.cutPrevDataButton.alpha = Global.OFFALPHA;
                MainUI.topBar.repNewFileButton.alpha = Global.OFFALPHA;
            }
            else
            {
                MainUI.topBar.repNewFileButton.alpha = 1.0;

                if (ReplayState.rNowFrame > 0 && ReplayState.rNowFrame < ReplayState.TOTAL_FRAME)
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

        public static function resetCanvasAndReplayData():void
        {
            resetZoomReplayMode();
            resetRotationReplayMode();
            ReplayDrawer.clearCanvasReplayMode();
            clearDataAndResetVars();
            ReplayDrawCommands.resetFirstRCursorPos();
            ReplayFileCache.clearRFrameTempCache();
        }

        public static function readyForFrameJump():void
        {
            ReplayState.isReplayFinished = false;

            if (ReplayState.isReplayStarted)
            {
                stopReplay();
            }
        }

        public static function moveToPreviousStep():void
        {
            readyForFrameJump();

            if (ReplayState.rNowFrame > 0)
            {
                ReplayDrawer.renderReplayFrame(ReplayState.rPrevFrame, ReplayDrawer.JUMP_FRAME_PREV);
                updateDeleteReplayDataButtonsState();
                MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayState.rNowFrame / ReplayState.TOTAL_FRAME);
                updateReplayPrograssText();
            }
        }

        public static function moveToNextStep():void
        {
            readyForFrameJump();

            if (ReplayState.rNowFrame < ReplayState.TOTAL_FRAME)
            {
                if (ReplayDrawCommands.getRemainingData() === 0)
                {
                    // +1해줘서 다음 데이터 갱신해주고 나머지 끝까지 그려줌
                    ReplayDrawer.renderReplayFrame(ReplayState.rNowFrame + 1, ReplayDrawer.JUMP_FRAME_NEXT);
                    ReplayDrawer.renderReplayFrame(ReplayState.rNowFrame + ReplayDrawCommands.getRemainingData(), ReplayDrawer.JUMP_FRAME_NEXT);
                    // jumpframe함수 이후에 실행
                }
                else
                {
                    ReplayDrawer.renderReplayFrame(ReplayState.rNowFrame + ReplayDrawCommands.getRemainingData(), ReplayDrawer.JUMP_FRAME_NEXT);
                }

                updateDeleteReplayDataButtonsState();
                MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayState.rNowFrame / ReplayState.TOTAL_FRAME);
                updateReplayPrograssText();
            }
        }

        public static function moveToPreviousFrame():void
        {
            readyForFrameJump();

            if (ReplayState.rNowFrame > 0)
            {
                ReplayDrawer.renderReplayFrame(ReplayState.rNowFrame - 1, ReplayDrawer.JUMP_FRAME_MANUAL);
                updateDeleteReplayDataButtonsState();
                MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayState.rNowFrame / ReplayState.TOTAL_FRAME);
                updateReplayPrograssText();
            }
        }

        public static function moveToNextFrame():void
        {
            readyForFrameJump();

            if (ReplayState.rNowFrame < ReplayState.TOTAL_FRAME)
            {
                ReplayDrawer.renderReplayFrame(ReplayState.rNowFrame + 1, ReplayDrawer.JUMP_FRAME_MANUAL);
                updateDeleteReplayDataButtonsState();
                MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayState.rNowFrame / ReplayState.TOTAL_FRAME);
                updateReplayPrograssText();
            }
        }

        public static function onSeekbarClick():void
        {
            if (ReplayState.TOTAL_FRAME === 0 || ReplayState.rReplayImageCacheState > ReplayState.REPLAY_IMAGE_CAHCHE_COMPLETE)
            {
                return;
            }

            // 리플레이 플레이 중인지 아닌지 플래그 미리 저장해둠
            var wasReplayRunning:Boolean = false;
            var clickX:Number = MainUI.seekBarBox.trackBar.mouseX * MainUI.seekBarBox.trackBar.scaleX;
            var finalFrame:Number = Math.floor(ReplayState.TOTAL_FRAME * clickX / MainUI.seekBarBox.trackBar.width);

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

                finalFrame = Math.floor(ReplayState.TOTAL_FRAME * mx / MainUI.seekBarBox.trackBar.width);
                updateReplayPrograssText(false, finalFrame);
            }

            function onDragStart():void
            {
                if (ReplayState.isReplayStarted)
                {
                    wasReplayRunning = true;
                    ReplayState.isReplayStarted = false;
                    FOFOTimer.remove("replayDrawTimer");
                    ReplayDrawer.rFileStream.close();
                }

                FOFOTimer.remove("prograssBarUpdateTimer");
                MainUI.seekBarBox.setReplayPrograssBarWidth(clickX);
                clampFrame();
                ReplayState.isReplaySlideShowMode = false;
                ReplayState.isReplayFinished = false;
                MainUI.seekBarBox.resetPrograssBarColor();
            }

            function onMouseMove():void
            {
                clampFrame();

                if (!FOFOTimer.hasTimer("jumpFrameUpdateTimer"))
                {
                    FOFOTimer.addByName("jumpFrameUpdateTimer", 0.25, false, function ():void
                        {
                            ReplayDrawer.renderReplayFrame(finalFrame, ReplayDrawer.JUMP_FRAME_MANUAL);
                        });
                }
            }

            function onMouseUp():void
            {
                FOFOTimer.remove("jumpFrameUpdateTimer");
                ReplayDrawer.renderReplayFrame(finalFrame, ReplayDrawer.JUMP_FRAME_MANUAL);
                clampFrame();
                // jumpframe함수 이후에 실행
                updateDeleteReplayDataButtonsState();
                // 재생중에 스킵하고 있었으면 다시 시작

                if (wasReplayRunning && !ReplayState.isReplayFinished)
                {
                    startReplay();
                }
                else if (ReplayState.isReplayFinished)
                {
                    MainUI.seekBarBox.setReplayPrograssBarMaxWidth();
                    updateReplayPrograssText(true, ReplayState.TOTAL_FRAME);
                    stopReplay();
                }
            }

            DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
        }

        private static function handleReplayCacheImageGenerateComplete(fs:FileStream, onFrameEnter:Function, _frameSum:Number, _frameSumLast:Number, finalizeFunc:Function):void
        {
            main.stage.removeEventListener(Event.ENTER_FRAME, onFrameEnter);
            fs.close();
            stopGeneratingCacheImageFunc = null;
            ReplayDrawCommands.clearData();
            ReplayState.setRFileDataTotalFrame(_frameSum);
            ReplayState.rReplayImageCacheState = ReplayState.REPLAY_IMAGE_CAHCHE_COMPLETE;
            ReplayFileCache.deleteCacheProgress();
            resetReplayTime();
            updateTotalFrameAndReplayMaxSpeedFor10Sec(ReplayState.getTotalFrame());
            ReplayState.rNowFrame = ReplayState.TOTAL_FRAME;
            UndoManager.lastReplayFrameOnDeepUndoStart = ReplayState.TOTAL_FRAME;
            ReplayState.rPrevFrame = _frameSumLast;
            ReplayState.isReplayFinished = true;

            CanvasController.mirrorON = ReplayState.rMirrorON;
            UndoManager.mirrorCommandReady = false;
            UndoController.updateUndoBaseImageMirrorFlag(ReplayState.rMirrorON);
            CanvasController.canvasInfoBox.setMirror(ReplayState.rMirrorON);
            CanvasGridOverlay.updateGridMirror(ReplayState.rMirrorON);

            CanvasController.canvasNavigatorBox.visible = true;

            if (ReplayState.isReplayModeON)
            {
                updateReplayPrograssBarAndText();
                updateReplaySpeedSliderAlpha();
                updateDeleteReplayDataButtonsState();
                ReplayFileCache.clearRFrameTempCache();
                ReplayFileCache.rLastCacheImageIndex = -2;
                ReplayFileCache.rTempCachedLastImageIndex = -2;
                UndoManager.undoToIndex(ReplayState.rMemoryData.length - 1);
                CanvasController.centerCanvas("replay");
                InputManager.addInputEventsReplayMode();
                ReplayDrawer.rCanvasAnchorPoint.visible = true;
            }
            else
            {
                ReplayState.rMemoryDataReadON = false;
                CanvasController.applyReplayCanvasToDrawModeCanvas();
                CanvasController.canvasAnchorPoint.visible = true;
                CanvasController.canvasAnchorPoint.rotation = 0;
                ReplayDrawer.setRcursorRotation(0);
                CanvasController.canvasZoomIndex = 3;
                CanvasController.updateCanvasScale(1.0);
                CanvasController.centerCanvas("draw");
                UndoManager.resetUndoState();
                InputManager.addInputEventsDrawMode();
            }

            FileManager.closeLoadMenuBox();
            FileManager.loadMenuBox.clearPreviewImage(); // 캐시 이미지 만드는 동안만 쓰던 배경
            InputManager.clearKeyBuffer();

            if (finalizeFunc !== null)
            {
                finalizeFunc();
            }
        }

        // resumeIndex가 0 이상이면 그 번호의 캐시 이미지 상태에서 이어서 만듬 (rJumpImageFrameData는 미리 복원되어 있어야함)
        public static function generateReplayCacheImage(finalizeFunc:Function, resumeIndex:int = -1):void
        {
            const fs:FileStream = new FileStream();
            const fs2:FileStream = new FileStream();
            const totalSize:Number = FileManager.replayDataFilePath.size;
            const deepUndoFlag:Boolean = UndoManager.isDeepUndoEnabled;
            var rect:Rectangle;
            var _frameSum:Number = 0;
            var _LastframeSum:Number = 0;
            var dataWriteCount:uint = 0;
            var hintPrintTimeSave:int = getTimer();
            CanvasController.canvasAnchorPoint.visible = false;
            ReplayDrawer.rCanvasAnchorPoint.visible = false;
            CanvasController.canvasNavigatorBox.visible = false;
            ReplayDrawer.clearCanvasReplayMode(); // 리플레이 캔버스 먼저 깨끗하게
            fs.open(FileManager.replayDataFilePath, FileMode.READ);

            if (resumeIndex >= 0)
            {
                // 캐시 이미지를 만들던 그 시점 상태로 되돌려줌 (탐색할때 캐시 이미지에서 이어 그리는것과 같음)
                const cacheImageData:Object = ReplayFileCache.loadReplayCacheImage(resumeIndex);
                const metadata:CacheImageMetaData = cacheImageData.metadata as CacheImageMetaData;
                // 파일 캐시에서 새로 만든 bmpd라 clone 없이 그대로 넘겨줌
                ReplayDrawer.rCanvasLayer1BitmapData = cacheImageData.bmpd1;
                ReplayDrawer.rCanvasLayer2BitmapData = cacheImageData.bmpd2;
                ReplayDrawer.rCanvasLayer1Bitmap.bitmapData = ReplayDrawer.rCanvasLayer1BitmapData;
                ReplayDrawer.rCanvasLayer2Bitmap.bitmapData = ReplayDrawer.rCanvasLayer2BitmapData;
                ReplayState.rLastCanvasBGColor = metadata.bgColor;
                ReplayDrawer.updateCanvasBGColorReplayMode(metadata.bgColor);
                ReplayDrawer.syncCanvasSizeReplayMode(metadata.bmpdWidth, metadata.bmpdHeight);
                ReplayDrawCommands.setRCursorPos(metadata.rCursorPosX, metadata.rCursorPosY);
                ReplayState.rMirrorON = metadata.mirrorFlag;
                fs.position = metadata.lastByte;
                _frameSum = metadata.nowFrame;
                _LastframeSum = metadata.lastFrame;
            }
            else
            {
                // 첫 이미지 그려줌
                ReplayDrawer.rCanvasLayer1BitmapData = CanvasController.updateBitmapData(ReplayDrawer.rCanvasLayer1BitmapData, ReplayFileCache.rFirstImageLayer1BitmapData, ReplayDrawer.rCanvasLayer1Bitmap);
                ReplayDrawer.rCanvasLayer2BitmapData = CanvasController.updateBitmapData(ReplayDrawer.rCanvasLayer2BitmapData, ReplayFileCache.rFirstImageLayer2BitmapData, ReplayDrawer.rCanvasLayer2Bitmap);
                // 크기도 바꿔주고
                ReplayDrawer.syncCanvasSizeReplayMode(ReplayDrawer.rCanvasLayer1BitmapData.width, ReplayDrawer.rCanvasLayer1BitmapData.height);
                fs.position = 0;
                ReplayState.rMirrorON = ReplaySaveMetaData.firstImageMirrorFlag;
                ReplayDrawer.updateCanvasBGColorReplayMode(ReplaySaveMetaData.firstImageBG);
            }

            ReplayFileCache.saveCacheProgress();
            FileManager.loadMenuBox.visible = false;

            function printPrograssHint(bytes:Number):void
            {
                const perc:Number = Math.round(((totalSize - bytes) / totalSize) * 100);
                // const str:String = perc.toFixed(1)+"%";
                FileManager.loadMenuBox.updatePlaseWaitPrograss(perc + "%");
            }

            FileManager.loadMenuBox.showPleaseWaitTextOrCustomText("Reading replay file");
            FileManager.openLoadMenuBox();

            function onFrameEnter(e:Event):void
            {
                while (true)
                {
                    const namojiBytes:Number = fs.bytesAvailable;

                    if (namojiBytes === 0)
                    {
                        handleReplayCacheImageGenerateComplete(fs, onFrameEnter, _frameSum, _LastframeSum, finalizeFunc);
                        return;
                    }

                    if (getTimer() - hintPrintTimeSave > 250)
                    {
                        hintPrintTimeSave = getTimer();
                        printPrograssHint(namojiBytes);
                        return;
                    }

                    const data:Array = fs.readObject() as Array;
                    ReplayDrawCommands.setData(data);
                    _LastframeSum = _frameSum;
                    _frameSum += data.length; // _rJumpImageCount 변수보다 먼저 와야함
                    dataWriteCount += data.length;
                    ReplayDrawCommands.drawAll();

                    if (dataWriteCount > ReplayFileCache.REPLAY_DISK_CACHE_FRAME_INTERVAL)
                    {
                        var imgData1:ByteArray = new ByteArray();
                        var imgData2:ByteArray = new ByteArray();
                        dataWriteCount = 0;
                        rect = new Rectangle(0, 0, ReplayDrawer.rCanvasLayer1BitmapData.width, ReplayDrawer.rCanvasLayer1BitmapData.height);
                        ReplayDrawer.rCanvasLayer1BitmapData.copyPixelsToByteArray(rect, imgData1);
                        ReplayDrawer.rCanvasLayer2BitmapData.copyPixelsToByteArray(rect, imgData2);
                        imgData1.compress();
                        imgData2.compress();
                        ReplayFileCache.createCacheImage(
                                imgData1,
                                imgData2,
                                new CacheImageMetaData
                                (
                                    ReplayDrawer.rCanvasLayer1BitmapData.width,
                                    ReplayDrawer.rCanvasLayer1BitmapData.height,
                                    ReplayState.RCANVAS_BG_COLOR,
                                    fs.position,
                                    _LastframeSum,
                                    _frameSum,
                                    ReplayState.rMirrorON
                                ));
                        imgData1.clear();
                        imgData2.clear();
                        ReplayFileCache.saveCacheProgress();

                        if (MainUI.seekBarBox.prograssBar.width > 0)
                        {
                            MainUI.seekBarBox.resetReplayPrograssBarWidth();
                        }
                    }
                }
            }

            main.stage.addEventListener(Event.ENTER_FRAME, onFrameEnter);
            stopGeneratingCacheImageFunc = function ():void
            {
                main.stage.removeEventListener(Event.ENTER_FRAME, onFrameEnter);
                fs.close();
            };
        }

        // 앱을 닫을때 캐시 이미지 만드는걸 멈춤, 상태는 처리중으로 남겨서 다음 실행때 이어서 만들게 함
        // 멈추지 않으면 창이 닫혀도 ENTER_FRAME이 계속 돌아서 앱이 종료되지 않음
        public static function stopGeneratingReplayCacheImage():void
        {
            if (stopGeneratingCacheImageFunc !== null)
            {
                stopGeneratingCacheImageFunc();
                stopGeneratingCacheImageFunc = null;
            }
        }

        public static function startGeneratingReplayCacheImage(fromLoadFile:Boolean, finalizeFunc:Function, resumeIndex:int = -1):void
        {
            if (fromLoadFile)
            {
                if (ReplayState.isReplayModeON)
                {
                    exitReplayMode();
                }

                InputManager.removeInputEventsDrawMode();
            }

            ReplayState.rReplayImageCacheState = ReplayState.REPLAY_IMAGE_CAHCHE_PROCESSING;
            generateReplayCacheImage(finalizeFunc, resumeIndex);
        }

        public static function resetReplaySpeedBar():void
        {
            ReplayState.rReplaySpeedMultipler = 1.0; // 속도 리셋
            MainUI.topBar.replaySpeedSliderCursor.x = MainUI.topBar.replaySpeedSlider.x + 1.5;
        }

        // total frame file max frame등등은 수동으로 초기화
        // 이건 리플레이 시간을 초기화 시켜주는것 뿐임 데이터는 건드리지 않음
        public static function resetReplayTime():void
        {
            // 어떤 이유가 있어서 rDataReadFlag는 여기 넣으면 안됨 수동으로 조절
            ReplayState.rMemoryDataIndex = 0;
            ReplayState.rMemoryDataStartIndex = 0;
            ReplayState.rFileLastBytePosition = 0;
            ReplayState.rNowFrame = 0;
            ReplayState.rPrevFrame = 0;
            ReplayFileCache.rLastCacheImageIndex = -2;
            ReplayFileCache.rTempCachedLastImageIndex = -2;
            ReplayState.isReplayFinished = true;
            ReplayState.isReplaySlideShowMode = false;
            ReplayDrawCommands.clearData();
        }

        public static function updateReplayPrograssText(finishFlag:Boolean = false, customFrame:Number = NaN):void
        {
            const remainingTime:String = (UndoManager.isDeepUndoEnabled || finishFlag) ? "" : getReplayRemainingTimeString(ReplayState.rReplaySpeedMultipler, ReplayState.TOTAL_FRAME - ReplayState.rNowFrame);

            if (isNaN(customFrame))
            {
                customFrame = ReplayState.rNowFrame;
            }

            MainUI.seekBarBox.prograssInfo.text = customFrame + " / " + ReplayState.TOTAL_FRAME + remainingTime;
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
            MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayState.rNowFrame / ReplayState.TOTAL_FRAME);
            FOFOTimer.addByName("prograssBarUpdateTimer", 0.0, true, function ():Boolean
                {
                    if (!ReplayState.isReplayModeON)
                    {
                        return false;
                    }

                    if (ReplayState.rNowFrame >= ReplayState.TOTAL_FRAME)
                    {
                        MainUI.seekBarBox.setReplayPrograssBarMaxWidth();
                        updateReplayPrograssText(true, ReplayState.TOTAL_FRAME);
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
                        ReplayDrawCommands.updateRCursorPos();

                        if (!ReplayState.isReplayCanvasFitToWindow && !CanvasController.isMouseLeftClicked && !UndoManager.isDeepUndoEnabled)
                        {
                            rFollowMouse.check(ReplayState.isReplaySlideShowMode);
                        }
                    }

                    if (nowTime - lastTextUpdateTime >= textUpdateTime)
                    {
                        lastTextUpdateTime = nowTime;
                        updateReplayPrograssText();
                        MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayState.rNowFrame / ReplayState.TOTAL_FRAME);
                    }

                    updatePrograssBarStartTime = getTimer();
                    return true;
                });
        }

        public static function startReplayDrawTimer():void
        {
            FOFOTimer.addByName("replayDrawTimer", 0.0, true, function ():Boolean
                {
                    if (ReplayState.isReplaySlideShowMode)
                    {
                        if (!shouldUseReplaySlideShowMode())
                        {
                            ReplayState.isReplaySlideShowMode = false;
                            ReplayDrawer.rFileStream.close();

                            if (!ReplayState.rMemoryDataReadON)
                            {
                                ReplayDrawer.rFileStream.open(FileManager.replayDataFilePath, FileMode.READ);
                                ReplayDrawer.rFileStream.position = ReplayState.rFileLastBytePosition;
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
                        ReplayState.isReplaySlideShowMode = true;
                        ReplayDrawer.rFileStream.close();
                    }
                    else
                    {
                        if (ReplayDrawer.startDraw(ReplayState.rReplaySpeedMultipler, ReplayDrawer.JUMP_FRAME_PLAY))
                        {
                            stopReplay();
                        }
                    }

                    return true;
                });
        }

        public static function shouldUseReplaySlideShowMode():Boolean
        {
            return ReplayState.rReplaySpeedMultipler > REPLAY_SLIDESHOW_ACTIVE_SPEED;
        }

        public static function showReplaySpeedMouseHint():void
        {
            const timeStr:String = getReplayRemainingTimeString(ReplayState.rReplaySpeedMultipler, ReplayState.TOTAL_FRAME);
            const finalStr:String = HintStrings.getReplaySpeedHintString(ReplayState.rReplaySpeedMultipler, timeStr);
            MainUI.showMouseHintTemp(finalStr);
        }

        // keyfunc
        public static function adjustReplaySpeedByShortcut(increaseFlag:Boolean):void
        {
            const clacMax:Number = Math.floor(ReplayState.TOTAL_FRAME / (main.stage.frameRate * 3));

            if (clacMax <= 0)
            {
                return;
            }

            const maxSpeed:Number = ReplayState.REPLAY_MAX_SPEED;
            var _rSpeed:Number = ReplayState.rReplaySpeedMultipler;

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

            ReplayState.rReplaySpeedMultipler = _rSpeed;
            MainUI.topBar.setSpeedButtonPosByValue(_rSpeed, maxSpeed);
            showReplaySpeedMouseHint();
        }

        public static function startAdjustPlayBackSpeedByShortcut(increase:Boolean):void
        {
            InputManager.startKeyRepeat(true, adjustReplaySpeedByShortcut, increase);
        }

        public static function adjutReplaySpeedByMouse():void
        {
            const totalF:Number = ReplayState.TOTAL_FRAME;

            if (totalF <= main.stage.frameRate * 3) // 3초 이내면 안함
            {
                return;
            }

            // setSpeedButtonPosByValue도 오프셋 수정해주어야함
            const minDist:Number = MainUI.topBar.replaySpeedSlider.x + 1.5;
            const maxDist:Number = minDist + MainUI.topBar.replaySpeedSlider.width - 2.5;
            const maxSpeed:Number = ReplayState.REPLAY_MAX_SPEED;
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

                    ReplayState.rReplaySpeedMultipler = nowSpeed;
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

                if (ReplayState.isReplayFinished === false)
                {
                    updateReplayPrograssText();
                }
            }

            function replaySpeedButtomUpEvent(e:MouseEvent):void
            {
                CanvasController.isMouseDragging = false;

                if (ReplayState.isReplayFinished === false)
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
            if (ReplayState.REPLAY_MAX_SPEED === 1.0)
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
            const totalFrame:Number = ReplayState.TOTAL_FRAME;
            const nowFrame:Number = ReplayState.rNowFrame;
            const trackBarWidth:Number = MainUI.seekBarBox.trackBar.width;
            MainUI.seekBarBox.prograssInfo.text = nowFrame + " / " + totalFrame;
            MainUI.seekBarBox.prograssBar.width = (totalFrame === 0) ? 0 : trackBarWidth * (nowFrame / totalFrame);
        }

        public static function updateReplayTimeBarFromDrawMode():void
        {
            updateReplayPrograssText(true, ReplayState.rNowFrame);

            if (ReplayState.TOTAL_FRAME === 0)
            {
                MainUI.seekBarBox.resetReplayPrograssBarWidth();
            }
            else
            {
                MainUI.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayState.rNowFrame / ReplayState.TOTAL_FRAME);
            }
        }

        public static function cancelReplayRestartTimer():void
        {
            MainUI.seekBarBox.setPlayButtonVisible(true);
            hideCompleteImageToBGReplayMode();
            MainUI.showTopbarOnReplayEnd();
            FOFOTimer.remove("replayRestartTimer");
            updateReplayPrograssText(true, ReplayState.TOTAL_FRAME);
            Utils.setColorTransform(MainUI.seekBarBox.prograssBar, Global.getUIReplayEndBarColor());
            CanvasController.updateCanvasScale(ReplayState.rLastCanvasZoomMultiplier, true);
        }

        public static function isReplayRestartTimerON():Boolean
        {
            return FOFOTimer.hasTimer("replayRestartTimer");
        }

        public static function startReplayRestartTimer():void
        {
            Utils.setColorTransform(MainUI.seekBarBox.prograssBar, Global.getUIReplayRestartBarColor());

            if (ReplayState.isReplayRepeatON)
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
                updateReplayPrograssText(true, ReplayState.TOTAL_FRAME);
            }
        }

        public static function toggleReplayRepeat():void
        {
            ReplayState.isReplayRepeatON = !ReplayState.isReplayRepeatON;

            if (ReplayState.isReplayRepeatON)
            {
                MainUI.topBar.replayRepeatButton.alpha = 1.0;
            }
            else
            {
                MainUI.topBar.replayRepeatButton.alpha = Global.OFFALPHA;
            }
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

            if (!ReplayState.isReplayFinished)
            {
                MainUI.seekBarBox.setPlayButtonVisible(true);
            }

            ReplayDrawer.rFileStream.close();
            ReplayState.isReplayStarted = false;
            ReplayState.isReplaySlideShowMode = false;
            updateDeleteReplayDataButtonsState();
        }

        public static function handleReplayStartButton():void
        {
            hideTopbarOnReplayStart();
            startReplay();
        }

        public static function startReplay():void
        {
            if (ReplayState.isReplayStarted || ReplayState.TOTAL_FRAME === 0)
            {
                return;
            }

            ReplayState.isReplayStarted = true;
            MainUI.seekBarBox.resetPrograssBarColor();
            MainUI.seekBarBox.playButton.visible = false;
            MainUI.seekBarBox.pauseButton.visible = true;
            ReplayDrawer.rReplayFOFOCursor.visible = true;
            updateDeleteReplayDataButtonsState();

            if (ReplayState.isReplayFinished === true) // 리플레이 시간 등등 초기화 시키고 시작
            {
                MainUI.seekBarBox.resetReplayPrograssBarWidth();
                resetReplayTime();
                ReplayDrawer.clearCanvasReplayMode();
                ReplayDrawer.drawFirstJumpImage();
                ReplayState.rMemoryDataReadON = false;
                ReplayState.isReplayFinished = false; // resetReplayTime함수 에서 이걸 true로 해주기 때문에 아래쪽에서 변경
                rFollowMouse.updateBounds();
                ReplayDrawer.selectReplaySubLayer(false);
            }

            if (!ReplayState.rMemoryDataReadON)
            {
                ReplayDrawer.rFileStream.open(FileManager.replayDataFilePath, FileMode.READ);
                ReplayDrawer.rFileStream.position = ReplayState.rFileLastBytePosition;
            }

            if (ReplayState.isReplayCanvasFitToWindow)
            {
                fitReplayCanvasToViewport();
            }

            ReplayFileCache.clearRFrameTempCache();
            startReplayDrawTimer();
            startUpdatingPrograssBarTimer();
            startCheckingHideMouseCursor();
        }

        public static function exitReplayMode():void
        {
            if (ReplayState.isGeneratingCacheImages())
            {
                return;
            }

            if (ReplayState.isReplayStarted === true)
            {
                stopReplay();
            }

            InputManager.removeInputEventsReplayMode();
            cancelReplayRestartTimer();
            ReplayState.isReplayModeON = false;
            ReplayDrawer.rCanvasAnchorPoint.visible = false;
            ReplayDrawer.rReplayFOFOCursor.visible = false;
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

            CanvasController.canvasPanel.addChild(ReplayDrawer.rReplayFOFOCursor);
            ReplayDrawer.setRcursorRotation(CanvasController.canvasAnchorPoint.rotation);

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
            ReplayDrawer.updateReplayCursorScale(CanvasController.canvasZoomMultipler);
            UndoManager.isDeepUndoEnabled = UndoManager.lastDeepUndoEnabledFlag;

            if (ReplayState.rNowFrame !== UndoManager.lastReplayFrameOnDeepUndoStart)
            {
                // next로 해주는 이유는 캐쉬 안만들어줄라고 prev로 하면 캐쉬 만들어줌
                ReplayDrawer.renderReplayFrame(UndoManager.lastReplayFrameOnDeepUndoStart, ReplayDrawer.JUMP_FRAME_NEXT);
            }

            ReplayFileCache.clearRFrameTempCache();
            ReplayDrawer.rReplayFOFOCursor.visible = false;
            InputManager.addInputEventsDrawMode();
        }

        public static function enterReplayMode():void
        {
            if (ReplayState.isGeneratingCacheImages())
            {
                return;
            }

            InputManager.removeInputEventsDrawMode();
            ReplayState.isReplayModeON = true;
            CanvasController.canvasAnchorPoint.visible = false;
            ReplayDrawer.rCanvasAnchorPoint.visible = true;
            MainUI.seekBarBox.visible = true;
            PenSizePreviewCursor.setCursorInVisibleFlag(true);
            PenSizePreviewCursor.setVisible(false);
            MainUI.seekBarBox.pauseButton.visible = false;
            MainUI.seekBarBox.y = Math.floor(MainUI.topBar.BARSIZE * Global.getUIScale() - 4);
            lastReplayTimeBoxYPos = MainUI.seekBarBox.y;
            Utils.setAsTopChild(MainUI.seekBarBox);
            MainUI.seekBarBox.setDeleteRangeBarVisible(false);
            Global.applyToolBoxButtonOverBGColor(MainUI.seekBarBox.prograssBar);

            if (ColorPickerController.numPadBox.visible)
            {
                ColorPickerController.closeNumpad();
            }

            if (MainUI.mouseHint.isShowing())
            {
                MainUI.hideMouseHint();
            }

            ReplayDrawer.rReplayFOFOCursor.alpha = 1.0;
            ReplayDrawer.rReplayFOFOCursor.visible = false;
            ReplayDrawer.rCanvasPanel.addChild(ReplayDrawer.rReplayFOFOCursor);
            Utils.setAsTopChild(ReplayDrawer.rReplayFOFOCursor);
            ReplayDrawer.setRcursorRotation(ReplayDrawer.rCanvasAnchorPoint.rotation);
            MainUIController.updateStageOffset();
            FOFOTimer.remove("rCursorOffAlphaAnimTimer");
            MainUI.hideBottomHint();
            UndoManager.lastDeepUndoEnabledFlag = UndoManager.isDeepUndoEnabled;
            UndoManager.isDeepUndoEnabled = false;
            UndoManager.lastReplayFrameOnDeepUndoStart = ReplayState.rNowFrame;
            updateTotalFrameAndReplayMaxSpeedFor10Sec(ReplayState.getTotalFrame()); // 최대 속도 계산
            updateReplayPrograssBarAndText();
            updateReplaySpeedSliderAlpha();
            MainUI.seekBarBox.updatePos(main.stage.stageWidth);
            rFollowMouse.updateBounds();
            ReplayDrawer.updateReplayCursorScale(ReplayState.rCanvasZoomMultiplier);

            if (ReferenceLayerController.isRefLayerMenuON === true)
            {
                ReferenceLayerController.refLayerMenuBox.visible = false;
            }

            if (ReplayState.rReplayImageCacheState === ReplayState.REPLAY_IMAGE_CAHCHE_COMPLETE)
            {
                ReplayState.rMemoryDataReadON = false;
                updateReplayTimeBarFromDrawMode();
                CanvasController.centerCanvas("replay");

                // 이거 안해주고 리플레이틀고 프레임 조작 안하고 재생하면 중간부터 되서 데이터가 꼬임
                ReplayState.isReplayFinished = true;

                if (UndoManager.undoDataIndex >= 0)
                {
                    ReplayState.rMemoryDataStartIndex = UndoManager.undoDataIndex + 1;
                    ReplayState.rMemoryDataReadON = true;
                }
                else
                {
                    ReplayState.rMemoryDataStartIndex = 0;
                    ReplayState.rMemoryDataReadON = false;
                }

                updateDeleteReplayDataButtonsState();
                ReplayState.isReplaySlideShowMode = false;
                CanvasController.keepCanvasPanelInStage(true);
                SidebarController.hideSidebarTemporary();
                MainUI.updateTopbarIconsReplayMode();
                InputManager.addInputEventsReplayMode();

                if (ReplayState.isReplayCanvasFitToWindow)
                {
                    fitReplayCanvasToViewport();
                }
            }
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
                bounds = Utils.getBoundRect(ReplayDrawer.rCanvasLayer1Bitmap);
                left = bounds.left;
                right = bounds.right;
                top = bounds.top;
                bottom = bounds.bottom;
                stw = main.stage.stageWidth;
                sth = main.stage.stageHeight - (MainUI.topBar.BARSIZE) * scale;
                zoom = ReplayState.rCanvasZoomMultiplier;
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
                cp = ReplayDrawCommands.getRCursorPos();
                globalChecked = false;
                const div:Number = (viewCenterFlag) ? 1 : 3;

                if (isCanvasWidthSmallerStage)
                {
                    if (isNotCenterX)
                    {
                        ReplayDrawer.rCanvasAnchorPoint.x += windowCenterPos.x;
                        updateBounds();
                    }
                }
                else
                {
                    globalChecked = true;
                    gp = ReplayDrawer.rCanvasLayer1Bitmap.localToGlobal(new Point(0, 0));
                    rg = Utils.rotatePoint(cp.x, cp.y, -ReplayDrawer.rCanvasAnchorPoint.rotation);
                    cursorPos.x = gp.x + (rg.x * zoom);

                    if (cursorPos.x < leftLimit)
                    {
                        ReplayDrawer.rCanvasAnchorPoint.x += Math.floor(Math.abs((cursorPos.x - stw / 2) / div));
                        updateBounds();
                    }
                    else if (cursorPos.x > rightLimit)
                    {
                        ReplayDrawer.rCanvasAnchorPoint.x -= Math.floor(Math.abs((cursorPos.x - stw / 2) / div));
                        updateBounds();
                    }
                }

                if (isCanvasHeightSmallerStage)
                {
                    if (isNotCenterY)
                    {
                        ReplayDrawer.rCanvasAnchorPoint.y += windowCenterPos.y;
                        updateBounds();
                    }
                }
                else
                {
                    if (globalChecked === false)
                    {
                        globalChecked = true;
                        gp = ReplayDrawer.rCanvasLayer1Bitmap.localToGlobal(new Point(0, 0));
                        rg = Utils.rotatePoint(cp.x, cp.y, -ReplayDrawer.rCanvasAnchorPoint.rotation);
                    }

                    cursorPos.y = gp.y + (rg.y * zoom);

                    if (cursorPos.y < topLimit)
                    {
                        ReplayDrawer.rCanvasAnchorPoint.y += Math.floor(Math.abs((cursorPos.y - sth / 2) / div));
                        updateBounds();
                    }
                    else if (cursorPos.y > bottomLimit)
                    {
                        ReplayDrawer.rCanvasAnchorPoint.y -= Math.floor(Math.abs((cursorPos.y - sth / 2) / div));
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

        public static function startCheckingHideMouseCursor():void
        {
            if (FOFOTimer.hasTimer("replayHideCursorCheckTimer"))
            {
                return;
            }

            FOFOTimer.addByName("replayHideCursorCheckTimer", 0.0, true, function ():Boolean
                {
                    if (!ReplayState.isReplayModeON || MainUI.topBar.visible)
                    {
                        replayHideCursor.show();
                        return false;
                    }

                    replayHideCursor.check();
                    return true;
                });
        }

        // 드로우 모드와 리플레이 모드 캔버스 미러가 다를경우 undo적용 이후에 mirror되는 것을 방지하고 mirror준비를 넣어주도록 함
        public static function preserveDrawMirrorStateAfterReplayCopy():void
        {
            if (CanvasController.mirrorON !== ReplayState.rMirrorON)
            {
                UndoManager.mirrorCommandReady = true;
                CanvasController.mirrorBmpdDrawmode();
                CanvasGridOverlay.updateGridMirror(CanvasController.mirrorON);
                ReplayDrawer.mirrorRCursorPos();
            }
            else if (UndoManager.mirrorCommandReady)
            {
                UndoManager.mirrorCommandReady = false;
            }
        }

        public static function toggleLayerCaptureMode(layer:int):void
        {
            MainUI.topBar.capClipBoard.alpha = 1.0;
            const replayMode:Boolean = ReplayState.isReplayModeON;
            var bitmap:Bitmap = replayMode
                ? (layer == 1 ? ReplayDrawer.rCanvasLayer1Bitmap : ReplayDrawer.rCanvasLayer2Bitmap)
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
                    if ((layer == 1 && !ReplayDrawer.isLayer2SelectedReplayMode())
                            || (layer == 2 && ReplayDrawer.isLayer2SelectedReplayMode()))
                    {
                        ReplayDrawer.rCanvasDrawLayer.visible = false;
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
                    if ((layer == 1 && !ReplayDrawer.isLayer2SelectedReplayMode())
                            || (layer == 2 && ReplayDrawer.isLayer2SelectedReplayMode()))
                    {
                        ReplayDrawer.rCanvasDrawLayer.visible = true;
                    }
                }
            }

            CaptureArea.updateDrawArea();
        }

        public static function resetZoomReplayMode():void
        {
            const center:Point = MainUIController.getStageCenterPos("replay");
            ReplayState.rLastCanvasZoomMultiplier = 1.0;
            ReplayState.rCanvasZoomIndex = CanvasController.canvasZoomMultiplerList.indexOf(1.0);
            CanvasController.moveCanvasAnchorPoint(center.x, center.y, true);
            CanvasController.updateCanvasScale(1.0, true);
            setFitReplayCanvasToViewportOFF();
            rFollowMouse.updateBounds();
        }

        private static function copyReplayCanvasDataToDrawCanvas():void
        {
            const lineStyleSave:Array = ReplayDrawCommands.getrLineStyleSave();
            // if(!lineStyleSave) return;
            var newColorTransform:ColorTransform = new ColorTransform(1, 1, 1, lineStyleSave[0]);
            ReplayDrawer.rCanvasDrawLayerBitmapData.draw(ReplayDrawer.rCanvasDrawShape);
            ReplayDrawer.rCanvasDrawLayerBitmap.bitmapData = ReplayDrawer.rCanvasDrawLayerBitmapData;

            if (ReplayDrawer.isLayer2SelectedReplayMode())
            {
                ReplayDrawer.rCanvasLayer2BitmapData.draw(ReplayDrawer.rCanvasDrawLayerBitmap, null, newColorTransform, lineStyleSave[1]);
            }
            else
            {
                ReplayDrawer.rCanvasLayer1BitmapData.draw(ReplayDrawer.rCanvasDrawLayerBitmap, null, newColorTransform, lineStyleSave[1]);
            }

            // 캔버스 2번 지워줘야함
            ReplayDrawer.rCanvasDrawShape.graphics.clear();
            ReplayDrawer.rCanvasDrawLayerBitmapData.fillRect(new Rectangle(0, 0, ReplayDrawer.rCanvasDrawLayerBitmapData.width, ReplayDrawer.rCanvasDrawLayerBitmapData.height), 0);
            CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, ReplayDrawer.rCanvasLayer1BitmapData, CanvasController.canvasLayer1Bitmap);
            CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, ReplayDrawer.rCanvasLayer2BitmapData, CanvasController.canvasLayer2Bitmap);
            CanvasController.setCavnvasSizeDrawMode(CanvasController.canvasLayer1Bitmap.width, CanvasController.canvasLayer1Bitmap.height);
            CanvasController.setCanvasBGColorDrawMode(ReplayState.RCANVAS_BG_COLOR);
            CanvasController.updateCanvasPanelColorAndSize();
            CanvasController.canvasNavigatorBox.updateImage();

            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
                ImageViewWindow.updateCanvasWindowBitmapSize();
            }
        }

        private static function syncDrawCanvasWithReplayCanvas():void
        {
            CanvasController.canvasZoomMultipler = ReplayState.rCanvasZoomMultiplier;
            CanvasController.canvasZoomIndex = ReplayState.rCanvasZoomIndex;
            CanvasController.canvasAnchorPoint.x = Math.floor(ReplayDrawer.rCanvasAnchorPoint.x); // 뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
            CanvasController.canvasAnchorPoint.y = Math.floor(ReplayDrawer.rCanvasAnchorPoint.y);
            CanvasController.canvasAnchorPoint.scaleX = ReplayDrawer.rCanvasAnchorPoint.scaleX;
            CanvasController.canvasAnchorPoint.scaleY = ReplayDrawer.rCanvasAnchorPoint.scaleY;
            CanvasController.canvasAnchorPoint.rotation = ReplayDrawer.rCanvasAnchorPoint.rotation;
            CanvasController.canvasPanel.x = Math.floor(ReplayDrawer.rCanvasPanel.x);
            CanvasController.canvasPanel.y = Math.floor(ReplayDrawer.rCanvasPanel.y);
            ReplayDrawer.setRcursorRotation(ReplayDrawer.rCanvasAnchorPoint.rotation);
        }

        private static function ensureReplayCanvasState():void
        {
            const rNowFrameBackup:Number = ReplayState.rNowFrame;
            ReplayDrawer.renderReplayFrame(0, ReplayDrawer.JUMP_FRAME_MANUAL);
            ReplayDrawer.renderReplayFrame(rNowFrameBackup, ReplayDrawer.JUMP_FRAME_MANUAL);
            CanvasController.mirrorON = ReplayState.rMirrorON;
            UndoManager.mirrorCommandReady = false;
            CanvasController.canvasInfoBox.setMirror(ReplayState.rMirrorON);
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
            ReplayDrawer.rCanvasPanel.filters = [];
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
            ReplayDrawer.rCanvasPanel.filters = [glow];
            MainUI.stageBG.addChild(rCanvasCompleteAnchorPoint);
        }

        public static function toggleFitToCanvasReplayMode():void
        {
            if (ReplayState.isReplayCanvasFitToWindow)
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

        public static function resetRotationReplayMode():void
        {
            const center:Point = MainUIController.getStageCenterPos("replay");
            CanvasController.moveCanvasAnchorPoint(center.x, center.y, true);
            ReplayDrawer.rCanvasAnchorPoint.rotation = 0;
            ReplayDrawer.setRcursorRotation(0);
        }

        public static function syncMirrorReplayModeWithDrawMode():void
        {
            if (UndoManager.mirrorCommandReady)
            {
                ReplayDrawer.mirrorCanvasReplayMode();
            }
        }

        public static function initializeReplayCanvas():void
        {
            ReplayDrawer.rCanvasPanel.name = "rCanvasPanel";
            ReplayDrawer.rCanvasAnchorPoint.name = "rCanvasAnchorPoint";
            ReplayDrawer.rCanvasLayer1Bitmap.name = "rCanvasLayer1Bitmap";
            ReplayDrawer.rCanvasLayer2Bitmap.name = "rCanvasLayer2Bitmap";
            rCanvasCompleteBitmap.name = "rCanvasCompleteBitmap";
            rCanvasCompleteAnchorPoint.name = "rCanvasCompleteAnchorPoint";
            ReplayDrawer.rCanvasDrawLayer.name = "rCanvasDrawLayer";
            ReplayDrawer.rCanvasDrawShape.name = "rCanvasDrawShape";
            MainUI.seekBarBox.name = "seekBarBox";
            ReplayDrawer.rReplayFOFOCursor.name = "rCursor";
            ReplayDrawer.rReplayFOFOCursor.mouseEnabled = false;
            rCanvasCompleteAnchorPoint.addChild(rCanvasCompleteBitmap);
            ReplayDrawer.rCanvasPanel.graphics.beginFill(CanvasController.CANVAS_BG_COLOR);
            ReplayDrawer.rCanvasPanel.graphics.drawRect(0, 0, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
            ReplayDrawer.rCanvasPanel.graphics.endFill();
            ReplayDrawer.rCanvasDrawLayer.addChild(ReplayDrawer.rCanvasDrawLayerBitmap);
            ReplayDrawer.rCanvasDrawLayer.addChild(ReplayDrawer.rCanvasDrawShape);
            ReplayDrawer.rCanvasDrawLayer.blendMode = "layer"; // 캔버스1이랑 알파 불투명도가 겹치지 않게 layer모드로 해줌
            ReplayDrawer.rCanvasPanel.addChild(ReplayDrawer.rCanvasLayer2Bitmap);
            ReplayDrawer.rCanvasPanel.addChild(ReplayDrawer.rCanvasLayer1Bitmap);
            ReplayDrawer.rCanvasPanel.addChild(ReplayDrawer.rCanvasDrawLayer);
            ReplayDrawer.rCanvasPanel.scrollRect = new Rectangle(0, 0, ReplayState.RCANVAS_WIDTH, ReplayState.RCANVAS_HEIGHT); // 마스크 해줘서 판 밖으로 선나타나지 않도록함
            ReplayDrawer.rCanvasPanel.x = Math.floor(-ReplayDrawer.rCanvasPanel.width / 2);
            ReplayDrawer.rCanvasPanel.y = Math.floor(-ReplayDrawer.rCanvasPanel.height / 2);
            ReplayDrawer.rCanvasAnchorPoint.addChild(ReplayDrawer.rCanvasPanel);
            ReplayDrawer.rCanvasAnchorPoint.visible = false;
            main.stage.addChild(ReplayDrawer.rCanvasAnchorPoint);
            main.stage.addChild(MainUI.seekBarBox);
            MainUI.seekBarBox.x = 0;
        }

        public static function syncDrawCanvasWithReplayMode():void
        {
            CanvasController.canvasZoomMultipler = ReplayState.rCanvasZoomMultiplier; // 줌배율도 공유
            CanvasController.canvasZoomIndex = ReplayState.rCanvasZoomIndex;
            CanvasController.canvasAnchorPoint.scaleX = ReplayDrawer.rCanvasAnchorPoint.scaleX;
            CanvasController.canvasAnchorPoint.scaleY = ReplayDrawer.rCanvasAnchorPoint.scaleY;
            CanvasController.canvasAnchorPoint.rotation = ReplayDrawer.rCanvasAnchorPoint.rotation;
            CanvasController.canvasAnchorPoint.x = ReplayDrawer.rCanvasAnchorPoint.x;
            CanvasController.canvasAnchorPoint.y = ReplayDrawer.rCanvasAnchorPoint.y;
            CanvasController.canvasPanel.x = ReplayDrawer.rCanvasPanel.x;
            CanvasController.canvasPanel.y = ReplayDrawer.rCanvasPanel.y;
            ReplayDrawer.setRcursorRotation(CanvasController.canvasAnchorPoint.rotation);
        }

        public static function setReplayCanvasStateFromDrawMode():void
        {
            ReplayState.rCanvasZoomMultiplier = CanvasController.canvasZoomMultipler; // 줌배율도 공유
            ReplayState.rCanvasZoomIndex = CanvasController.canvasZoomIndex;
            ReplayDrawer.rCanvasAnchorPoint.scaleX = CanvasController.canvasAnchorPoint.scaleX;
            ReplayDrawer.rCanvasAnchorPoint.scaleY = CanvasController.canvasAnchorPoint.scaleY;
            ReplayDrawer.rCanvasAnchorPoint.rotation = CanvasController.canvasAnchorPoint.rotation;
            ReplayDrawer.rCanvasAnchorPoint.x = CanvasController.canvasAnchorPoint.x;
            ReplayDrawer.rCanvasAnchorPoint.y = CanvasController.canvasAnchorPoint.y;
            ReplayDrawer.rCanvasPanel.x = CanvasController.canvasPanel.x;
            ReplayDrawer.rCanvasPanel.y = CanvasController.canvasPanel.y;
            ReplayDrawer.setRcursorRotation(ReplayDrawer.rCanvasAnchorPoint.rotation);
        }

        public static function setFitReplayCanvasToViewportOFF():void
        {
            ReplayState.isReplayCanvasFitToWindow = false;
        }

        public static function setFitReplayCanvasToViewportON():void
        {
            ReplayState.isReplayCanvasFitToWindow = true;
            fitReplayCanvasToViewport();
        }

        public static function fitReplayCanvasToViewport():void
        {
            FOFOTimer.addByName("rFitZoomedDelayTimer", 0.15, false, function ():void
                {
                    CanvasController.fitCanvasToViewportMargin(true);
                    ReplayState.rCanvasZoomIndex = CanvasController.getNearZoomIndex(ReplayState.rCanvasZoomMultiplier);
                    ReplayState.rCanvasZoomMultiplier = CanvasController.canvasZoomMultiplerList[ReplayState.rCanvasZoomIndex];
                });
        }

        public static function addInputEventsDrawModeOrReplayMode():void
        {
            if (ReplayState.isReplayModeON)
            {
                InputManager.addInputEventsReplayMode();
            }
            else
            {
                InputManager.addInputEventsDrawMode();
            }
        }

        public static function clearDataAndResetVars():void
        {
            FileManager.isContinueSaveON = false;
            ReplayState.rLastCanvasBGColor = CanvasController.CANVAS_BG_COLOR;
            ReplayState.rMirrorON = false;
            CanvasController.mirrorON = false;
            ReplayState.rMemoryDataReadON = false;
            UndoManager.mirrorCommandReady = false;
            ReplayState.setRFileDataTotalFrame(0);
            updateTotalFrameAndReplayMaxSpeedFor10Sec(0);
            ReplayState.rReplayImageCacheState = ReplayState.REPLAY_IMAGE_CAHCHE_COMPLETE;
            CanvasController.isLayerSwapped = false;
            ReferenceLayerController.resetRefLayerImageTransform();
            ReferenceLayerController.resetRefLayerMenuOpacity();
            ReplayFileCache.initializeReplayDataFile(true);
            ReplayFileCache.createFirstImageCache(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
            resetReplaySpeedBar();
            resetReplayTime();
            UndoManager.resetUndoState();
            CaptureController.resetCaptureCanvasChangeValue();
            FileManager.updateLastFilePathByRandomFileName();
            CanvasController.canvasInfoBox.setMirror(false);
            MainUIController.updateWindowTitle();
            InputManager.removeKeyRepeatEvents(null);
        }

        private static function replayCompleteEffect():void
        {
            CanvasController.fitCanvasToViewportMargin(ReplayState.isReplayCanvasFitToWindow);
            CanvasController.applyCanvasFlashEffect(ReplayDrawer.rCanvasPanel, 0, 0, ReplayState.RCANVAS_WIDTH, ReplayState.RCANVAS_HEIGHT, function ():Boolean
                {
                    return MainUI.topBar.visible;
                });
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
                timeStr += "00:";
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
    }
}
