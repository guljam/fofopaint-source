package Modules.ReplayEngine
{
    import Modules.CanvasViewport;
    import Modules.DrawEngine.CanvasView;
    import Modules.DrawEngine.DrawCanvas;
    import Modules.DrawEngine.CanvasLayers;
    import Modules.UIEngine.CanvasNavigator;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;
    import Modules.UIEngine.UITheme;
    import Modules.InputPriority;
    import Modules.MouseState;
    import Modules.Tools.PenTool;
    import flash.desktop.Clipboard;
    import flash.desktop.ClipboardFormats;
    import flash.desktop.NativeDragManager;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
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
    import Modules.CacheImageMetaData;
    import Modules.CanvasGridOverlay;
    import Modules.CaptureEngine.CaptureController;
    import Modules.ColorPickerController;
    import Modules.DragInteraction;
    import Modules.FileManager;
    import Modules.AppStateManager;
    import Modules.LoadBoxController;
    import Modules.ImageViewWindow;
    import Modules.InputManager.InputManager;
    import Modules.InputManager.DrawModeInput;
    import Modules.InputManager.ReplayModeInput;
    import Modules.PenSizePreviewCursor;
    import Modules.ReferenceLayerController;
    import Modules.SidebarController;
    import Modules.UndoHistory;
    import Modules.UndoController;
    import Modules.Utils;
    import Symbols.SeekBarSet;

    public class ReplayController
    {
        public static var main:Main;

        private static const REPLAY_SLIDESHOW_ACTIVE_SPEED:Number = 60;
        private static const REPLAY_SLIDESHOW_FRAME_RATE:Number = 2; // 1/2초 = 0.5초마다 갱신
        private static const REPLAY_SLIDESHOW_UPDATE_TIME:Number = 1000 / REPLAY_SLIDESHOW_FRAME_RATE;
        private static var rCanvasCompleteAnchorPoint:Sprite = new Sprite(); // 리플레이에어 이미지가 재생되었을때 보여주는 객체 stage와 가로세로 중앙정렬
        private static var rCanvasCompleteBitmap:Bitmap = new Bitmap(new BitmapData(1, 1, false, 0), "auto", true);
        private static var updatePrograssBarStartTime:int = 0; // 리플레이 시작 시간저장 update prograss bar에서 프레임 오차 수정할때 참고하는 변수
        private static var rReplayRestartTimerCount:uint = 0; // 리스타트 타이머
        private static var isReplaySpeedDragging:Boolean = false; // 속도 슬라이더 드래그 중에는 s eekbar 텍스트에 속도 힌트를 보여줌
        private static var rSeekbarTextUpdateTime:int = 0; // 프레임 바 딜레이
        private static var stopGeneratingCacheImageFunc:Function = null; // 캐시 이미지 만드는 중이면 멈추는 함수
        private static var frameOnEnterReplayMode:Number = -1; // 리플레이 켜줄때 rNowFrame이 변하니까 그전에 백업해주고 꺼줄때 이 프레임으로 되돌림
        public static var lastReplayTimeBoxYPos:Number = 0; // 리플레이 재생해줄때 WorkspaceView.topbar 사라지게 할때 원래 위치 저장해서 끝나면 이 위치로 복원해줌
        public static const seekBarBox:SeekBarSet = new SeekBarSet();

        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static function createNewFileFromReplayCanvas():void
        {
            seekBarBox.setDeleteRangeBarVisible(false);
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
            UndoController.exitDeepUndo();
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

            if (UIController.topBar)
            {
                UIController.topBar.updateReplaySpeedSnapMarker(maxSpeed, REPLAY_SLIDESHOW_ACTIVE_SPEED);
            }

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
                ReplayController.seekBarBox.setDeleteRangeBarVisible(false);
                FileManager.showReplayDataLockedHint();
                return;
            }
            // 미러 되어있을 수도 있기 때문에 원래 프레임으로 점프해준뒤에 실행해줌
            ensureReplayCanvasState();
            ReplayController.seekBarBox.setDeleteRangeBarVisible(false);
            ReplayFileCache.createFirstImageCache(ReplayDrawer.rCanvasLayer1BitmapData, ReplayDrawer.rCanvasLayer2BitmapData, ReplayState.RCANVAS_BG_COLOR, ReplayState.rMirrorON);
            const fs:FileStream = new FileStream();

            if (ReplayState.rMemoryDataReadON)
            {
                // repfile 초기화
                UndoHistory.updateUndoBaseImageFromReplayMode();
                fs.open(AppStateManager.replayDataFilePath, FileMode.WRITE); // 파일 생성
                fs.close();
                FileManager.isFileAlreadySaved = false;
                FileManager.enableNewFileButton();
                ReplayState.setRFileDataTotalFrame(0);
                ReplayState.rMemoryData.splice(0, ReplayState.rMemoryDataIndex + 1);
                ReplayState.rMemoryDataFrame.splice(0, ReplayState.rMemoryDataIndex + 1);
                updateTotalFrameAndReplayMaxSpeedFor10Sec(ReplayState.getTotalFrame());
                updateReplayPrograssText(true, ReplayState.TOTAL_FRAME);

                if (ReplayState.isZeroReplayFrame())
                {
                    ReplayController.seekBarBox.resetReplayPrograssBarWidth();
                }
                else
                {
                    ReplayController.seekBarBox.setReplayPrograssBarMaxWidth();
                }

                UIController.topBar.repNewFileButton.alpha = UITheme.OFFALPHA;
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
                fs.open(AppStateManager.replayDataFilePath, FileMode.READ);
                fs.position = ReplayState.rFileLastBytePosition;
                fs.readBytes(ba, 0, fs.bytesAvailable);
                fs.close();
                // ba에 넣어준걸 다시 써주기
                fs.open(AppStateManager.replayDataFilePath, FileMode.WRITE);
                fs.position = 0;
                fs.writeBytes(ba, 0, ba.length);
                fs.close();
                ba.clear();
                ba = null;
                ReplayDrawer.rReplayFOFOCursor.visible = false;
                ReplayController.seekBarBox.resetReplayPrograssBarWidth();
                FileManager.isFileAlreadySaved = false;
                LoadBoxController.loadMenuBox.clearPreviewImage(); // 이 경우 로드박스에 배경 이미지를 깔지 않음
                startGeneratingReplayCacheImage(false, finalize);
            }

            function finalize():void
            {
                resetReplaySpeedBar();
                ReplayState.isReplayFinished = true;

                UndoController.undoToIndex(Math.min(UndoHistory.undoDataIndex, ReplayState.rMemoryData.length - 1));
                UndoController.exitDeepUndo();
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
                ReplayController.seekBarBox.setDeleteRangeBarVisible(false);
                FileManager.showReplayDataLockedHint();
                return;
            }
            ensureReplayCanvasState();
            ReplayController.seekBarBox.setDeleteRangeBarVisible(false);

            if (ReplayState.rMemoryDataReadON === true)
            {
                // 위에서 setJumpOneFrame을 해줘서 rindex가 증가되었기 때문에
                // 실제 undo해줘야할 인덱스는 -1해줘야하는거임
                UndoController.undoToIndex(ReplayState.rMemoryDataIndex);
                ReplayState.rMemoryData.splice(ReplayState.rMemoryDataIndex + 1);
                ReplayState.rMemoryDataFrame.splice(ReplayState.rMemoryDataIndex + 1);
                updateTotalFrameAndReplayMaxSpeedFor10Sec(ReplayState.getTotalFrame());
                resetReplayTime();
            }
            else if (ReplayState.rMemoryDataReadON === false)
            {
                ReplayDrawCommands.setFirstRCursorPosCurrent();
                const fs:FileStream = new FileStream();
                fs.open(AppStateManager.replayDataFilePath, FileMode.UPDATE);
                fs.position = ReplayState.rFileLastBytePosition;
                fs.truncate(); // 데이터 위에 짤라주고
                fs.close();
                // 썸네일 이미지도 날려줌
                const rNowFrameSave:Number = ReplayState.rNowFrame;
                ReplayFileCache.truncateCacheImagesAfterFrame(rNowFrameSave);
                ReplayState.setRFileDataTotalFrame(rNowFrameSave);
                updateTotalFrameAndReplayMaxSpeedFor10Sec(rNowFrameSave);
                DrawCanvas.canvasLayer1BitmapData = DrawCanvas.updateBitmapData(DrawCanvas.canvasLayer1BitmapData, ReplayDrawer.rCanvasLayer1BitmapData, DrawCanvas.canvasLayer1Bitmap);
                DrawCanvas.canvasLayer1Bitmap.bitmapData = DrawCanvas.canvasLayer1BitmapData;
                DrawCanvas.canvasLayer2BitmapData = DrawCanvas.updateBitmapData(DrawCanvas.canvasLayer2BitmapData, ReplayDrawer.rCanvasLayer2BitmapData, DrawCanvas.canvasLayer2Bitmap);
                DrawCanvas.canvasLayer2Bitmap.bitmapData = DrawCanvas.canvasLayer2BitmapData;
                DrawCanvas.setCanvasSizeDrawMode(DrawCanvas.canvasLayer1Bitmap.width, DrawCanvas.canvasLayer1Bitmap.height, 0, 0, false);
                DrawCanvas.setCanvasBGColorDrawMode(ReplayState.RCANVAS_BG_COLOR);
                CanvasView.updateCanvasPanelColorAndSize();
                resetReplayTime();
                syncDrawCanvasWithReplayCanvas();
                UndoController.resetUndoState();
                CanvasNavigator.box.updateImage();

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
            UndoController.exitDeepUndo();
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
                    ReplayController.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayState.rNowFrame / ReplayState.TOTAL_FRAME);
                    updateDeleteReplayDataButtonsState();
                }

                if (ReplayState.rNowFrame >= ReplayState.TOTAL_FRAME)
                {
                    ReplayController.seekBarBox.setDeleteRangeBarVisible(false);
                    return true;
                }
            }

            ReplayController.seekBarBox.updateDeleteDangeBarPosWidth(mode);
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
                    if (!ReplayState.isReplaySlideShowMode && !ReplayState.isReplayCanvasFitToWindow && !UndoController.isDeepUndoEnabled)
                    {
                        ReplayDrawer.cursorFollow.check(true);
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
                UIController.topBar.superUndoButton.alpha = UITheme.OFFALPHA;
                UIController.topBar.cutPrevDataButton.alpha = UITheme.OFFALPHA;
                UIController.topBar.repNewFileButton.alpha = UITheme.OFFALPHA;
            }
            else
            {
                UIController.topBar.repNewFileButton.alpha = 1.0;

                if (ReplayState.rNowFrame > 0 && ReplayState.rNowFrame < ReplayState.TOTAL_FRAME)
                {
                    UIController.topBar.superUndoButton.alpha = 1.0;
                    UIController.topBar.cutPrevDataButton.alpha = 1.0;
                }
                else
                {
                    UIController.topBar.superUndoButton.alpha = UITheme.OFFALPHA;
                    UIController.topBar.cutPrevDataButton.alpha = UITheme.OFFALPHA;
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
                ReplayController.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayState.rNowFrame / ReplayState.TOTAL_FRAME);
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
                ReplayController.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayState.rNowFrame / ReplayState.TOTAL_FRAME);
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
                ReplayController.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayState.rNowFrame / ReplayState.TOTAL_FRAME);
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
                ReplayController.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayState.rNowFrame / ReplayState.TOTAL_FRAME);
                updateReplayPrograssText();
            }
        }

        public static function onSeekbarClick():void
        {
            if (ReplayState.isZeroReplayFrame() || ReplayState.rReplayImageCacheState > ReplayState.REPLAY_IMAGE_CAHCHE_COMPLETE)
            {
                return;
            }

            // 리플레이 플레이 중인지 아닌지 플래그 미리 저장해둠
            var wasReplayRunning:Boolean = false;
            var clickX:Number = ReplayController.seekBarBox.trackBar.mouseX * ReplayController.seekBarBox.trackBar.scaleX;
            var finalFrame:Number = Math.floor(ReplayState.TOTAL_FRAME * clickX / ReplayController.seekBarBox.trackBar.width);

            function clampFrame():void
            {
                var mx:Number = ReplayController.seekBarBox.trackBar.mouseX * ReplayController.seekBarBox.trackBar.scaleX;

                if (mx < 0)
                {
                    mx = 0;
                    ReplayController.seekBarBox.resetReplayPrograssBarWidth();
                }
                else if (mx > ReplayController.seekBarBox.trackBar.width)
                {
                    mx = ReplayController.seekBarBox.trackBar.width;
                    ReplayController.seekBarBox.setReplayPrograssBarMaxWidth();
                }
                else
                {
                    ReplayController.seekBarBox.setReplayPrograssBarWidth(mx);
                }

                finalFrame = Math.floor(ReplayState.TOTAL_FRAME * mx / ReplayController.seekBarBox.trackBar.width);
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
                ReplayController.seekBarBox.setReplayPrograssBarWidth(clickX);
                clampFrame();
                ReplayState.isReplaySlideShowMode = false;
                ReplayState.isReplayFinished = false;
                ReplayController.seekBarBox.resetPrograssBarColor();
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
                    ReplayController.seekBarBox.setReplayPrograssBarMaxWidth();
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
            frameOnEnterReplayMode = ReplayState.TOTAL_FRAME;
            ReplayState.rPrevFrame = _frameSumLast;
            ReplayState.isReplayFinished = true;

            DrawCanvas.mirrorON = ReplayState.rMirrorON;
            ReplayState.mirrorCommandReady = false;
            UndoHistory.updateUndoBaseImageMirrorFlag(ReplayState.rMirrorON);
            UIController.canvasInfoBox.setMirror(ReplayState.rMirrorON);
            CanvasGridOverlay.updateGridMirror(ReplayState.rMirrorON);

            CanvasNavigator.box.visible = true;

            if (ReplayState.isReplayModeON)
            {
                updateReplayPrograssBarAndText();
                updateReplaySpeedSliderAlpha();
                updateDeleteReplayDataButtonsState();
                ReplayFileCache.clearRFrameTempCache();
                ReplayFileCache.rLastCacheImageIndex = -2;
                ReplayFileCache.rTempCachedLastImageIndex = -2;
                UndoController.undoToIndex(ReplayState.rMemoryData.length - 1);
                ReplayDrawer.viewport.centerIn("replay");
                ReplayModeInput.addEvents();
                ReplayDrawer.rCanvasAnchorPoint.visible = true;
            }
            else
            {
                ReplayState.rMemoryDataReadON = false;
                DrawCanvas.applyReplayCanvasToDrawModeCanvas();
                CanvasView.canvasAnchorPoint.visible = true;
                CanvasView.canvasAnchorPoint.rotation = 0;
                ReplayDrawer.setRcursorRotation(0);
                CanvasView.canvasZoomIndex = 3;
                CanvasView.viewport.setScale(1.0);
                CanvasView.viewport.centerIn("draw");
                UndoController.resetUndoState();
                DrawModeInput.addEvents();
            }

            LoadBoxController.closeLoadMenuBox();
            LoadBoxController.loadMenuBox.clearPreviewImage(); // 캐시 이미지 만드는 동안만 쓰던 배경
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
            const totalSize:Number = AppStateManager.replayDataFilePath.size;
            const deepUndoFlag:Boolean = UndoController.isDeepUndoEnabled;
            var rect:Rectangle;
            var _frameSum:Number = 0;
            var _LastframeSum:Number = 0;
            var dataWriteCount:uint = 0;
            var hintPrintTimeSave:int = getTimer();
            CanvasView.canvasAnchorPoint.visible = false;
            ReplayDrawer.rCanvasAnchorPoint.visible = false;
            CanvasNavigator.box.visible = false;
            ReplayDrawer.clearCanvasReplayMode(); // 리플레이 캔버스 먼저 깨끗하게
            fs.open(AppStateManager.replayDataFilePath, FileMode.READ);

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
                ReplayDrawer.rCanvasLayer1BitmapData = DrawCanvas.updateBitmapData(ReplayDrawer.rCanvasLayer1BitmapData, ReplayFileCache.rFirstImageLayer1BitmapData, ReplayDrawer.rCanvasLayer1Bitmap);
                ReplayDrawer.rCanvasLayer2BitmapData = DrawCanvas.updateBitmapData(ReplayDrawer.rCanvasLayer2BitmapData, ReplayFileCache.rFirstImageLayer2BitmapData, ReplayDrawer.rCanvasLayer2Bitmap);
                // 크기도 바꿔주고
                ReplayDrawer.syncCanvasSizeReplayMode(ReplayDrawer.rCanvasLayer1BitmapData.width, ReplayDrawer.rCanvasLayer1BitmapData.height);
                fs.position = 0;
                ReplayState.rMirrorON = ReplaySaveMetaData.firstImageMirrorFlag;
                ReplayState.RCANVAS_BG_COLOR = ReplaySaveMetaData.firstImageBG;
                ReplayDrawer.updateCanvasBGColorReplayMode(ReplaySaveMetaData.firstImageBG);
            }

            ReplayFileCache.saveCacheProgress();
            LoadBoxController.loadMenuBox.visible = false;

            function printPrograssHint(bytes:Number):void
            {
                const perc:Number = Math.round(((totalSize - bytes) / totalSize) * 100);
                // const str:String = perc.toFixed(1)+"%";
                LoadBoxController.loadMenuBox.updatePlaseWaitPrograss(perc + "%");
            }

            LoadBoxController.loadMenuBox.showPleaseWaitTextOrCustomText("Reading replay file", "(Press Esc to cancel)");
            LoadBoxController.openLoadMenuBox();

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

                        if (ReplayController.seekBarBox.prograssBar.width > 0)
                        {
                            ReplayController.seekBarBox.resetReplayPrograssBarWidth();
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

        // 캐시 이미지를 만드는 도중 취소하면 캐시도 리플레이 데이터도 중간 상태라 그대로 그릴수 없으므로 생성을 멈추고 새 파일로 초기화함
        public static function cancelGeneratingReplayCacheImageAndCreateNewFile():void
        {
            if (!ReplayState.isGeneratingCacheImages())
            {
                return;
            }

            if (FileManager.isReplayDataLocked())
            {
                FileManager.showReplayDataLockedHint();
                return;
            }

            stopGeneratingReplayCacheImage();
            ReplayState.rReplayImageCacheState = ReplayState.REPLAY_IMAGE_CAHCHE_COMPLETE;
            ReplayFileCache.deleteCacheProgress();
            LoadBoxController.closeLoadMenuBox();
            LoadBoxController.loadMenuBox.clearPreviewImage();
            FileManager.resetAllCanvasAndReplayData();
            // 불러오던 파일에서 읽어둔 참조 레이어 원본이 남아있으면 다음 불러오기에 섞이므로 해제하고 참조 레이어도 비움
            if (ReferenceLayerController.refLayerRawBitmapData)
            {
                ReferenceLayerController.refLayerRawBitmapData.dispose();
                ReferenceLayerController.refLayerRawBitmapData = null;
            }
            ReferenceLayerController.refLayerRawTransformData = null;
            ReferenceLayerController.clearRefLayerImage();
            // exitReplayMode가 지워진 데이터 기준으로 프레임을 맞추지 않도록 초기화된 프레임으로 갱신
            frameOnEnterReplayMode = ReplayState.rNowFrame;
            CanvasNavigator.box.visible = true;
            CanvasView.canvasAnchorPoint.visible = true;

            if (ReplayState.isReplayModeON)
            {
                exitReplayMode();
            }
            else
            {
                DrawModeInput.addEvents();
            }

            InputManager.clearKeyBuffer();
        }

        public static function startGeneratingReplayCacheImage(fromLoadFile:Boolean, finalizeFunc:Function, resumeIndex:int = -1):void
        {
            if (fromLoadFile)
            {
                if (ReplayState.isReplayModeON)
                {
                    exitReplayMode();
                }

                DrawModeInput.removeEvents();
                // 이전 문서의 메모리 undo 데이터가 남아있으면 다 만든 뒤 계산하는 전체 프레임에 섞여 들어감
                // undo 기준 이미지는 다 만든 뒤 resetUndoState에서 갱신함
                UndoHistory.clearMemoryUndoData();
            }

            ReplayState.rReplayImageCacheState = ReplayState.REPLAY_IMAGE_CAHCHE_PROCESSING;
            generateReplayCacheImage(finalizeFunc, resumeIndex);
        }

        public static function resetReplaySpeedBar():void
        {
            ReplayState.rReplaySpeedMultipler = 1.0; // 속도 리셋
            UIController.topBar.replaySpeedSliderCursor.x = UIController.topBar.replaySpeedSlider.x + 1.5;
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
            if (isReplaySpeedDragging)
            {
                ReplayController.seekBarBox.prograssInfo.text = getReplaySpeedHintText();
                return;
            }

            if (isNaN(customFrame))
            {
                customFrame = ReplayState.rNowFrame;
            }

            const remainingTime:String = (UndoController.isDeepUndoEnabled || finishFlag) ? "" : getReplayRemainingTimeString(ReplayState.rReplaySpeedMultipler, ReplayState.TOTAL_FRAME - customFrame);

            ReplayController.seekBarBox.prograssInfo.text = customFrame + " / " + ReplayState.TOTAL_FRAME + remainingTime;
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
            ReplayController.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayState.rNowFrame / ReplayState.TOTAL_FRAME);
            FOFOTimer.addByName("prograssBarUpdateTimer", 0.0, true, function ():Boolean
                {
                    if (!ReplayState.isReplayModeON)
                    {
                        return false;
                    }

                    if (ReplayState.rNowFrame >= ReplayState.TOTAL_FRAME)
                    {
                        ReplayController.seekBarBox.setReplayPrograssBarMaxWidth();
                        updateReplayPrograssText(true, ReplayState.TOTAL_FRAME);
                        replayCompleteEffect();
                        startReplayRestartTimer();
                        showCompleteImageToBGReplayMode();
                        HintController.hideBottomHint();
                        return false;
                    }

                    const nowTime:int = getTimer();

                    if (nowTime - lastCursorUpdateTime >= cursorUpdateTime)
                    {
                        lastCursorUpdateTime = nowTime;
                        ReplayDrawCommands.updateRCursorPos();

                        if (!ReplayState.isReplayCanvasFitToWindow && !MouseState.isLeftDown && !UndoController.isDeepUndoEnabled)
                        {
                            ReplayDrawer.cursorFollow.check(ReplayState.isReplaySlideShowMode);
                        }
                    }

                    if (nowTime - lastTextUpdateTime >= textUpdateTime)
                    {
                        lastTextUpdateTime = nowTime;
                        updateReplayPrograssText();
                        ReplayController.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayState.rNowFrame / ReplayState.TOTAL_FRAME);
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
                                ReplayDrawer.rFileStream.open(AppStateManager.replayDataFilePath, FileMode.READ);
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

        private static function getReplaySpeedHintText():String
        {
            const timeStr:String = getReplayRemainingTimeString(ReplayState.rReplaySpeedMultipler, ReplayState.TOTAL_FRAME);
            return HintStrings.getReplaySpeedHintString(ReplayState.rReplaySpeedMultipler, timeStr);
        }

        public static function showReplaySpeedMouseHint():void
        {
            HintController.showMouseHintTemp(getReplaySpeedHintText());
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
            UIController.topBar.setSpeedButtonPosByValue(_rSpeed, maxSpeed);
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
            const minDist:Number = UIController.topBar.replaySpeedSlider.x + 1.5;
            const maxDist:Number = minDist + UIController.topBar.replaySpeedSlider.width - 2.5;
            const maxSpeed:Number = ReplayState.REPLAY_MAX_SPEED;
            var oldSpeed:Number;
            PenSizePreviewCursor.setCursorInVisibleFlag(true);

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

            // 회전 스냅(showCanvasRotateCursorMouseDrag)과 같은 개념: 버튼의 논리 위치(logicX)는 마우스 이동량을 누적해서 구함
            // 논리 위치가 스냅 영역 안이고 스냅이 활성이면 버튼을 선에 고정, 영역을 벗어나면 논리 위치를 선으로 되돌려 거기서부터 이어서 움직임
            // 그래서 스냅에 걸릴 때마다 마우스 위치와 버튼 위치에 차이가 생기고, 그만큼 미세 조정이 가능함
            // 풀린 뒤에는 논리 위치가 영역을 벗어났다가 다시 들어올 때까지 걸리지 않음
            const SNAP_RANGE_PX:Number = 5;
            var logicX:Number = NaN;
            var prevMx:Number = NaN;
            var snapIgnore:Boolean = true;
            var snapActive:Boolean = false;
            var isSnapped:Boolean = false;

            function applySnap(mx:Number):Number
            {
                const snapX:Number = UIController.topBar.replaySpeedSnapX;
                isSnapped = false;

                if (isNaN(logicX)) // 시작할 때는 마우스와 같은 위치
                {
                    logicX = mx;
                    prevMx = mx;
                    snapIgnore = snapX >= 0 && Math.abs(mx - snapX) <= SNAP_RANGE_PX; // 누른 위치가 영역 안이면 영역을 벗어날 때까지 무시
                    return mx;
                }

                const prevLogic:Number = logicX;
                logicX += mx - prevMx;
                prevMx = mx;

                // 끝에서 마우스가 더 나가도 돌아올 때 바로 따라오도록 슬라이더 범위로 제한
                if (logicX < minDist)
                {
                    logicX = minDist;
                }
                else if (logicX > maxDist)
                {
                    logicX = maxDist;
                }

                if (snapX < 0)
                {
                    snapActive = false;
                    return logicX;
                }

                const inZone:Boolean = Math.abs(logicX - snapX) <= SNAP_RANGE_PX;
                // 이벤트 사이에 영역을 건너뛴 경우도 진입으로 취급
                const crossed:Boolean = Math.min(prevLogic, logicX) <= snapX + SNAP_RANGE_PX && Math.max(prevLogic, logicX) >= snapX - SNAP_RANGE_PX;

                if (snapIgnore === false && (inZone || (snapActive === false && crossed)))
                {
                    snapActive = true;
                    isSnapped = true;
                    return snapX;
                }

                if (snapActive === true)
                {
                    logicX = snapX;
                    snapActive = false;
                    snapIgnore = true;
                    return snapX;
                }

                if (snapIgnore === true && inZone === false)
                {
                    snapIgnore = false;
                }
                return logicX;
            }

            function moveButton(mx:Number):void
            {
                mx = applySnap(mx);

                if (mx < minDist)
                {
                    mx = minDist;
                }
                else if (mx > maxDist)
                {
                    mx = maxDist;
                }

                UIController.topBar.replaySpeedSliderCursor.x = mx;
                setSpeed(mx);

                if (isSnapped)
                {
                    // floor 오차로 59가 되지 않도록 스냅 속도를 직접 지정
                    oldSpeed = REPLAY_SLIDESHOW_ACTIVE_SPEED;
                    ReplayState.rReplaySpeedMultipler = REPLAY_SLIDESHOW_ACTIVE_SPEED;
                }
                updateReplayPrograssText(); // 드래그 중에는 속도 힌트가 seekbar 텍스트에 표시됨
            }

            function replaySpeedButtomUpEvent(e:MouseEvent):void
            {
                MouseState.endDrag("replaySpeed");

                if (isReplaySpeedDragging)
                {
                    isReplaySpeedDragging = false;
                    Mouse.show();
                    HintController.hideMouseHint();
                    updateReplayPrograssText(ReplayState.isReplayFinished, ReplayState.isReplayFinished ? ReplayState.TOTAL_FRAME : NaN);
                }

                main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, replaySpeedButtomMoveEvent);
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, replaySpeedButtomUpEvent);
            }

            function replaySpeedButtomMoveEvent(e:MouseEvent):void
            {
                moveButton(UIController.topBar.replaySpeedSliderWrapper.mouseX);
            }

            isReplaySpeedDragging = true;
            Mouse.hide();
            moveButton(UIController.topBar.replaySpeedSliderWrapper.mouseX);
            setSpeed(UIController.topBar.replaySpeedSliderWrapper.mouseX);
            updateReplayPrograssText();
            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, replaySpeedButtomMoveEvent);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, replaySpeedButtomUpEvent, false, InputPriority.DEFAULT);
            MouseState.beginDrag("replaySpeed", function ():void
                {
                    replaySpeedButtomUpEvent(null);
                });
        }

        public static function updateReplaySpeedSliderAlpha():void
        {
            if (ReplayState.REPLAY_MAX_SPEED === 1.0)
            {
                UIController.topBar.replaySpeedSliderWrapper.alpha = UITheme.OFFALPHA;
            }
            else
            {
                UIController.topBar.replaySpeedSliderWrapper.alpha = 1.0;
            }
        }

        public static function updateReplayPrograssBarAndText():void
        {
            const totalFrame:Number = ReplayState.TOTAL_FRAME;
            const nowFrame:Number = ReplayState.rNowFrame;
            const trackBarWidth:Number = ReplayController.seekBarBox.trackBar.width;
            if (!isReplaySpeedDragging)
            {
                ReplayController.seekBarBox.prograssInfo.text = nowFrame + " / " + totalFrame;
            }
            ReplayController.seekBarBox.prograssBar.width = (totalFrame === 0) ? 0 : trackBarWidth * (nowFrame / totalFrame);
        }

        public static function updateReplayTimeBarFromDrawMode():void
        {
            updateReplayPrograssText(true, ReplayState.rNowFrame);

            if (ReplayState.isZeroReplayFrame())
            {
                ReplayController.seekBarBox.resetReplayPrograssBarWidth();
            }
            else
            {
                ReplayController.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayState.rNowFrame / ReplayState.TOTAL_FRAME);
            }
        }

        public static function cancelReplayRestartTimer():void
        {
            ReplayController.seekBarBox.setPlayButtonVisible(true);
            hideCompleteImageToBGReplayMode();
            showTopbarOnReplayEnd();
            FOFOTimer.remove("replayRestartTimer");
            updateReplayPrograssText(true, ReplayState.TOTAL_FRAME);
            Utils.setColorTransform(ReplayController.seekBarBox.prograssBar, UITheme.getUIReplayEndBarColor());
            ReplayDrawer.viewport.setScale(ReplayState.rLastCanvasZoomMultiplier);
        }

        public static function isReplayRestartTimerON():Boolean
        {
            return FOFOTimer.hasTimer("replayRestartTimer");
        }

        public static function startReplayRestartTimer():void
        {
            Utils.setColorTransform(ReplayController.seekBarBox.prograssBar, UITheme.getUIReplayRestartBarColor());

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

                        if (!isReplaySpeedDragging)
                        {
                            ReplayController.seekBarBox.prograssInfo.text = HintStrings.getReplayRestartHintString(rReplayRestartTimerCount);
                        }
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
                UIController.topBar.replayRepeatButton.alpha = 1.0;
            }
            else
            {
                UIController.topBar.replayRepeatButton.alpha = UITheme.OFFALPHA;
            }
        }

        public static function hideTopbarOnReplayStart():void
        {
            if (UIController.topBar.visible === true)
            {
                ReplayController.seekBarBox.y = 0;
                ReplayController.seekBarBox.hideReplayControlButton();
                UIController.topBar.visible = false;
                HintController.hideBottomHint();
                HintController.hideMouseHint();
            }
        }

        public static function showTopbarOnReplayEnd():void
        {
            if (UIController.topBar.visible === false)
            {
                UIController.topBar.visible = true;
                seekBarBox.y = lastReplayTimeBoxYPos;
                seekBarBox.setPlayButtonVisible(true);
                seekBarBox.showReplayControlButton();
                HintController.hideBottomHint();
                HintController.hideMouseHint();
            }
        }

        public static function handleReplayStopButton():void
        {
            showTopbarOnReplayEnd();
            stopReplay();
        }

        public static function stopReplay():void
        {
            FOFOTimer.remove("replayDrawTimer");

            if (!ReplayState.isReplayFinished)
            {
                ReplayController.seekBarBox.setPlayButtonVisible(true);
            }

            ReplayDrawer.rFileStream.close();
            ReplayState.isReplayStarted = false;
            ReplayState.isReplaySlideShowMode = false;
            updateDeleteReplayDataButtonsState();
        }

        public static function handleReplayStartButton():void
        {
            if (!ReplayState.canStartReplay())
            {
                return;
            }

            hideTopbarOnReplayStart();
            startReplay();
        }

        public static function startReplay():void
        {
            if (!ReplayState.canStartReplay())
            {
                return;
            }

            ReplayState.isReplayStarted = true;
            ReplayController.seekBarBox.resetPrograssBarColor();
            ReplayController.seekBarBox.playButton.visible = false;
            ReplayController.seekBarBox.pauseButton.visible = true;
            ReplayDrawer.rReplayFOFOCursor.visible = true;
            updateDeleteReplayDataButtonsState();

            if (ReplayState.isReplayFinished === true) // 리플레이 시간 등등 초기화 시키고 시작
            {
                ReplayController.seekBarBox.resetReplayPrograssBarWidth();
                resetReplayTime();
                ReplayDrawer.clearCanvasReplayMode();
                ReplayDrawer.drawFirstJumpImage();
                ReplayState.rMemoryDataReadON = false;
                ReplayState.isReplayFinished = false; // resetReplayTime함수 에서 이걸 true로 해주기 때문에 아래쪽에서 변경
                ReplayDrawer.cursorFollow.updateBounds();
                ReplayDrawer.selectReplaySubLayer(false);
            }

            if (!ReplayState.rMemoryDataReadON)
            {
                ReplayDrawer.rFileStream.open(AppStateManager.replayDataFilePath, FileMode.READ);
                ReplayDrawer.rFileStream.position = ReplayState.rFileLastBytePosition;
            }

            if (ReplayState.isReplayCanvasFitToWindow)
            {
                fitReplayCanvasToViewport();
            }

            ReplayFileCache.clearRFrameTempCache();
            startReplayDrawTimer();
            startUpdatingPrograssBarTimer();
            ReplayMouseAutoHide.start();
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

            ReplayModeInput.removeEvents();
            cancelReplayRestartTimer();
            ReplayState.isReplayModeON = false;
            ReplayDrawer.rCanvasAnchorPoint.visible = false;
            ReplayDrawer.rReplayFOFOCursor.visible = false;
            ReplayController.seekBarBox.visible = false;
            CanvasView.canvasAnchorPoint.visible = true;
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

            CanvasView.canvasPanel.addChild(ReplayDrawer.rReplayFOFOCursor);
            ReplayDrawer.setRcursorRotation(CanvasView.canvasAnchorPoint.rotation);

            if (HintController.mouseHint.isShowing())
            {
                HintController.hideMouseHint();
            }

            ReplayController.seekBarBox.pauseButton.visible = false;
            Utils.setAsTopChild(ReplayController.seekBarBox);
            ReplayController.seekBarBox.setDeleteRangeBarVisible(false);
            UIController.updateStageOffset();
            CanvasNavigator.updateCursor();

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
            UIController.updateTopbarIconsDrawMode();
            UIController.canvasInfoBox.setZoom(CanvasView.canvasZoomMultiplier);
            ReplayDrawer.updateReplayCursorScale(CanvasView.canvasZoomMultiplier);
            UndoController.resumeDeepUndo();

            if (ReplayState.rNowFrame !== frameOnEnterReplayMode)
            {
                // next로 해주는 이유는 캐쉬 안만들어줄라고 prev로 하면 캐쉬 만들어줌
                ReplayDrawer.renderReplayFrame(frameOnEnterReplayMode, ReplayDrawer.JUMP_FRAME_NEXT);
            }

            ReplayFileCache.clearRFrameTempCache();
            ReplayDrawer.rReplayFOFOCursor.visible = false;
            DrawModeInput.addEvents();
        }

        public static function enterReplayMode():void
        {
            if (ReplayState.isGeneratingCacheImages())
            {
                return;
            }

            DrawModeInput.removeEvents();
            ReplayState.isReplayModeON = true;
            CanvasView.canvasAnchorPoint.visible = false;
            ReplayDrawer.rCanvasAnchorPoint.visible = true;
            ReplayController.seekBarBox.visible = true;
            PenSizePreviewCursor.setCursorInVisibleFlag(true);
            PenSizePreviewCursor.setVisible(false);
            ReplayController.seekBarBox.pauseButton.visible = false;
            ReplayController.seekBarBox.y = Math.floor(UIController.topBar.BARSIZE * UITheme.getUIScale() - 4);
            lastReplayTimeBoxYPos = ReplayController.seekBarBox.y;
            Utils.setAsTopChild(ReplayController.seekBarBox);
            ReplayController.seekBarBox.setDeleteRangeBarVisible(false);
            UITheme.applyToolBoxButtonOverBGColor(ReplayController.seekBarBox.prograssBar);

            if (ColorPickerController.numPadBox.visible)
            {
                ColorPickerController.closeNumpad();
            }

            if (HintController.mouseHint.isShowing())
            {
                HintController.hideMouseHint();
            }

            ReplayDrawer.rReplayFOFOCursor.alpha = 1.0;
            ReplayDrawer.rReplayFOFOCursor.visible = false;
            ReplayDrawer.rCanvasPanel.addChild(ReplayDrawer.rReplayFOFOCursor);
            Utils.setAsTopChild(ReplayDrawer.rReplayFOFOCursor);
            ReplayDrawer.setRcursorRotation(ReplayDrawer.rCanvasAnchorPoint.rotation);
            UIController.updateStageOffset();
            FOFOTimer.remove("rCursorOffAlphaAnimTimer");
            HintController.hideBottomHint();
            UndoController.suspendDeepUndo();
            frameOnEnterReplayMode = ReplayState.rNowFrame;
            updateTotalFrameAndReplayMaxSpeedFor10Sec(ReplayState.getTotalFrame()); // 최대 속도 계산
            updateReplayPrograssBarAndText();
            updateReplaySpeedSliderAlpha();
            ReplayController.seekBarBox.updatePos(main.stage.stageWidth);
            ReplayDrawer.cursorFollow.updateBounds();
            ReplayDrawer.updateReplayCursorScale(ReplayState.rCanvasZoomMultiplier);

            if (ReferenceLayerController.isRefLayerMenuON === true)
            {
                ReferenceLayerController.refLayerMenuBox.visible = false;
            }

            if (ReplayState.rReplayImageCacheState === ReplayState.REPLAY_IMAGE_CAHCHE_COMPLETE)
            {
                ReplayState.rMemoryDataReadON = false;
                updateReplayTimeBarFromDrawMode();
                ReplayDrawer.viewport.centerIn("replay");

                // 이거 안해주고 리플레이틀고 프레임 조작 안하고 재생하면 중간부터 되서 데이터가 꼬임
                ReplayState.isReplayFinished = true;

                if (UndoHistory.undoDataIndex >= 0)
                {
                    ReplayState.rMemoryDataStartIndex = UndoHistory.undoDataIndex + 1;
                    ReplayState.rMemoryDataReadON = true;
                }
                else
                {
                    ReplayState.rMemoryDataStartIndex = 0;
                    ReplayState.rMemoryDataReadON = false;
                }

                updateDeleteReplayDataButtonsState();
                ReplayState.isReplaySlideShowMode = false;
                ReplayDrawer.viewport.keepInStage();
                SidebarController.hideSidebarTemporary();
                UIController.updateTopbarIconsReplayMode();
                ReplayModeInput.addEvents();

                if (ReplayState.isReplayCanvasFitToWindow)
                {
                    fitReplayCanvasToViewport();
                }
            }
        }

        // 드로우 모드와 리플레이 모드 캔버스 미러가 다를경우 undo적용 이후에 mirror되는 것을 방지하고 mirror준비를 넣어주도록 함
        public static function preserveDrawMirrorStateAfterReplayCopy():void
        {
            if (DrawCanvas.mirrorON !== ReplayState.rMirrorON)
            {
                ReplayState.mirrorCommandReady = true;
                DrawCanvas.mirrorBmpdDrawmode();
                CanvasGridOverlay.updateGridMirror(DrawCanvas.mirrorON);
                ReplayDrawer.mirrorRCursorPos();
            }
            else if (ReplayState.mirrorCommandReady)
            {
                ReplayState.mirrorCommandReady = false;
            }
        }

        public static function resetZoomReplayMode():void
        {
            const center:Point = UIController.getStageCenterPos("replay");
            ReplayState.rLastCanvasZoomMultiplier = 1.0;
            ReplayState.rCanvasZoomIndex = CanvasView.canvasZoomMultiplierList.indexOf(1.0);
            ReplayDrawer.viewport.moveAnchorPoint(center.x, center.y);
            ReplayDrawer.viewport.setScale(1.0);
            setFitReplayCanvasToViewportOFF();
            ReplayDrawer.cursorFollow.updateBounds();
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
            DrawCanvas.canvasLayer1BitmapData = DrawCanvas.updateBitmapData(DrawCanvas.canvasLayer1BitmapData, ReplayDrawer.rCanvasLayer1BitmapData, DrawCanvas.canvasLayer1Bitmap);
            DrawCanvas.canvasLayer2BitmapData = DrawCanvas.updateBitmapData(DrawCanvas.canvasLayer2BitmapData, ReplayDrawer.rCanvasLayer2BitmapData, DrawCanvas.canvasLayer2Bitmap);
            DrawCanvas.setCanvasSizeDrawMode(DrawCanvas.canvasLayer1Bitmap.width, DrawCanvas.canvasLayer1Bitmap.height);
            DrawCanvas.setCanvasBGColorDrawMode(ReplayState.RCANVAS_BG_COLOR);
            CanvasView.updateCanvasPanelColorAndSize();
            CanvasNavigator.box.updateImage();

            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
                ImageViewWindow.updateCanvasWindowBitmapSize();
            }
        }

        private static function syncDrawCanvasWithReplayCanvas():void
        {
            CanvasView.canvasZoomMultiplier = ReplayState.rCanvasZoomMultiplier;
            CanvasView.canvasZoomIndex = ReplayState.rCanvasZoomIndex;
            CanvasView.canvasAnchorPoint.x = Math.floor(ReplayDrawer.rCanvasAnchorPoint.x); // 뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
            CanvasView.canvasAnchorPoint.y = Math.floor(ReplayDrawer.rCanvasAnchorPoint.y);
            CanvasView.canvasAnchorPoint.scaleX = ReplayDrawer.rCanvasAnchorPoint.scaleX;
            CanvasView.canvasAnchorPoint.scaleY = ReplayDrawer.rCanvasAnchorPoint.scaleY;
            CanvasView.canvasAnchorPoint.rotation = ReplayDrawer.rCanvasAnchorPoint.rotation;
            CanvasView.canvasPanel.x = Math.floor(ReplayDrawer.rCanvasPanel.x);
            CanvasView.canvasPanel.y = Math.floor(ReplayDrawer.rCanvasPanel.y);
            ReplayDrawer.setRcursorRotation(ReplayDrawer.rCanvasAnchorPoint.rotation);
        }

        private static function ensureReplayCanvasState():void
        {
            const rNowFrameBackup:Number = ReplayState.rNowFrame;
            ReplayDrawer.renderReplayFrame(0, ReplayDrawer.JUMP_FRAME_MANUAL);
            ReplayDrawer.renderReplayFrame(rNowFrameBackup, ReplayDrawer.JUMP_FRAME_MANUAL);
            DrawCanvas.mirrorON = ReplayState.rMirrorON;
            ReplayState.mirrorCommandReady = false;
            UIController.canvasInfoBox.setMirror(ReplayState.rMirrorON);
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
            if (UIController.stageBG.getChildByName("rCanvasCompleteAnchorPoint"))
            {
                UIController.stageBG.removeChild(rCanvasCompleteAnchorPoint);
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
            const mergedbmpd:BitmapData = DrawCanvas.getMergedBitmapData(false, true, true, null);
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
            UIController.stageBG.addChild(rCanvasCompleteAnchorPoint);
        }

        public static function toggleFitToCanvasReplayMode():void
        {
            if (ReplayState.isReplayCanvasFitToWindow)
            {
                resetZoomReplayMode();
                UIController.topBar.replayFitToWindowButton.alpha = UITheme.OFFALPHA;
            }
            else
            {
                setFitReplayCanvasToViewportON();
                UIController.topBar.replayFitToWindowButton.alpha = 1.0;
            }
        }

        public static function resetRotationReplayMode():void
        {
            const center:Point = UIController.getStageCenterPos("replay");
            ReplayDrawer.viewport.moveAnchorPoint(center.x, center.y);
            ReplayDrawer.rCanvasAnchorPoint.rotation = 0;
            ReplayDrawer.setRcursorRotation(0);
        }

        public static function syncMirrorReplayModeWithDrawMode():void
        {
            if (ReplayState.mirrorCommandReady)
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
            ReplayController.seekBarBox.name = "seekBarBox";
            ReplayDrawer.rReplayFOFOCursor.name = "rCursor";
            ReplayDrawer.rReplayFOFOCursor.mouseEnabled = false;
            rCanvasCompleteAnchorPoint.addChild(rCanvasCompleteBitmap);
            ReplayDrawer.rCanvasPanel.graphics.beginFill(DrawCanvas.CANVAS_BG_COLOR);
            ReplayDrawer.rCanvasPanel.graphics.drawRect(0, 0, DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT);
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
            main.stage.addChild(ReplayController.seekBarBox);
            ReplayController.seekBarBox.x = 0;
        }

        public static function syncDrawCanvasWithReplayMode():void
        {
            CanvasView.canvasZoomMultiplier = ReplayState.rCanvasZoomMultiplier; // 줌배율도 공유
            CanvasView.canvasZoomIndex = ReplayState.rCanvasZoomIndex;
            CanvasView.canvasAnchorPoint.scaleX = ReplayDrawer.rCanvasAnchorPoint.scaleX;
            CanvasView.canvasAnchorPoint.scaleY = ReplayDrawer.rCanvasAnchorPoint.scaleY;
            CanvasView.canvasAnchorPoint.rotation = ReplayDrawer.rCanvasAnchorPoint.rotation;
            CanvasView.canvasAnchorPoint.x = ReplayDrawer.rCanvasAnchorPoint.x;
            CanvasView.canvasAnchorPoint.y = ReplayDrawer.rCanvasAnchorPoint.y;
            CanvasView.canvasPanel.x = ReplayDrawer.rCanvasPanel.x;
            CanvasView.canvasPanel.y = ReplayDrawer.rCanvasPanel.y;
            ReplayDrawer.setRcursorRotation(CanvasView.canvasAnchorPoint.rotation);
        }

        public static function setReplayCanvasStateFromDrawMode():void
        {
            ReplayState.rCanvasZoomMultiplier = CanvasView.canvasZoomMultiplier; // 줌배율도 공유
            ReplayState.rCanvasZoomIndex = CanvasView.canvasZoomIndex;
            ReplayDrawer.rCanvasAnchorPoint.scaleX = CanvasView.canvasAnchorPoint.scaleX;
            ReplayDrawer.rCanvasAnchorPoint.scaleY = CanvasView.canvasAnchorPoint.scaleY;
            ReplayDrawer.rCanvasAnchorPoint.rotation = CanvasView.canvasAnchorPoint.rotation;
            ReplayDrawer.rCanvasAnchorPoint.x = CanvasView.canvasAnchorPoint.x;
            ReplayDrawer.rCanvasAnchorPoint.y = CanvasView.canvasAnchorPoint.y;
            ReplayDrawer.rCanvasPanel.x = CanvasView.canvasPanel.x;
            ReplayDrawer.rCanvasPanel.y = CanvasView.canvasPanel.y;
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
                    CanvasViewport.current().fitToViewportMargin(true);
                    ReplayState.rCanvasZoomIndex = CanvasView.getNearZoomIndex(ReplayState.rCanvasZoomMultiplier);
                    ReplayState.rCanvasZoomMultiplier = CanvasView.canvasZoomMultiplierList[ReplayState.rCanvasZoomIndex];
                });
        }

        public static function addInputEventsDrawModeOrReplayMode():void
        {
            if (ReplayState.isReplayModeON)
            {
                ReplayModeInput.addEvents();
            }
            else
            {
                DrawModeInput.addEvents();
            }
        }

        public static function clearDataAndResetVars():void
        {
            FileManager.isContinueSaveON = false;
            ReplayState.rMirrorON = false;
            DrawCanvas.mirrorON = false;
            ReplayState.rMemoryDataReadON = false;
            ReplayState.mirrorCommandReady = false;
            ReplayState.setRFileDataTotalFrame(0);
            updateTotalFrameAndReplayMaxSpeedFor10Sec(0);
            ReplayState.rReplayImageCacheState = ReplayState.REPLAY_IMAGE_CAHCHE_COMPLETE;
            CanvasLayers.isLayerSwapped = false;
            ReferenceLayerController.resetRefLayerImageTransform();
            ReferenceLayerController.resetRefLayerMenuOpacity();
            ReplayFileCache.initializeReplayDataFile(true);
            ReplayFileCache.createFirstImageCache(DrawCanvas.canvasLayer1BitmapData, DrawCanvas.canvasLayer2BitmapData, DrawCanvas.CANVAS_BG_COLOR);
            resetReplaySpeedBar();
            resetReplayTime();
            UndoController.resetUndoState();
            CaptureController.resetCaptureCanvasChangeValue();
            FileManager.updateLastFilePathByRandomFileName();
            UIController.canvasInfoBox.setMirror(false);
            AppWindowState.updateWindowTitle();
            InputManager.removeKeyRepeatEvents(null);
        }

        private static function replayCompleteEffect():void
        {
            CanvasViewport.current().fitToViewportMargin(ReplayState.isReplayCanvasFitToWindow);
            CanvasView.applyCanvasFlashEffect(ReplayDrawer.rCanvasPanel, 0, 0, ReplayState.RCANVAS_WIDTH, ReplayState.RCANVAS_HEIGHT, function ():Boolean
                {
                    return UIController.topBar.visible;
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
