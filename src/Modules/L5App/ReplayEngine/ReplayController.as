package Modules.L5App.ReplayEngine
{
    import Modules.L1Data.AppContext;
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
    import flash.filesystem.File;
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
    import Modules.L5App.AppWindowState;
    import Modules.L4UI.CanvasGridOverlay;
    import Modules.L4UI.ColorPickerController;
    import Modules.L5App.InputManager.DrawModeInput;
    import Modules.L5App.FileManager;
    import Modules.L4UI.ImageViewWindow;
    import Modules.L5App.InputManager.ReplayModeInput;
    import Modules.L4UI.SidebarController;
    import Modules.L3Feature.UndoController;
    import Modules.L1Data.KeyState;
    import Modules.L2Engine.BackgroundWorkerCoordinator;
    import Modules.L2Engine.ReplayEngine.ReplayClock;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.L2Engine.ReplayEngine.ReplayFileCache;
    import Modules.L2Engine.ReplayEngine.TimingSheetFile;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L1Data.AppDataPaths;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L4UI.UIEngine.MessageBoxController;
    import Modules.L4UI.PenSizePreviewCursor;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L2Engine.ReplayEngine.ReplayDrawCommands;
    import Modules.L2Engine.UndoHistory;
    import Modules.L4UI.CanvasViewport;
    import Modules.L2Engine.ReplayEngine.ReplayState;
    import Modules.L1Data.ReplayEngine.ReplaySaveMetaData;
    import Modules.L4UI.HintStrings;
    import Modules.L3Feature.DrawEngine.CanvasLayers;
    import Modules.L2Engine.CacheImageMetaData;
    import Modules.L1Data.DragInteraction;
    import Modules.L1Data.MouseState;
    import Modules.L1Data.Utils;
    import Modules.L4UI.CaptureEngine.CaptureController;
    import Modules.L1Data.Tools.PenSettings;
    import Modules.L4UI.ReferenceLayerController;
    import Modules.L5App.LoadBoxController;
    import Modules.L4UI.ReplayEngine.ReplayMouseAutoHide;
    import Modules.L4UI.UIEngine.CanvasNavigator;
    import Modules.L1Data.FOFOTimer;
    import Modules.L1Data.InputPriority;
    import Modules.L1Data.NativeImageCaching;
    import Modules.L1Data.NativeCore;
    import Modules.L1Data.UIEngine.UITheme;
    import Modules.L4UI.Tools.ToolPanel;

    // 층: L5 앱 흐름 - 리플레이 모드 진입·종료와 재생 제어
    public class ReplayController
    {

        private static const REPLAY_MAX_SPEED_PLAY_MS:Number = 30000; // 배속을 끝까지 올렸을때 전체를 보는데 걸리는 시간(ms)
        private static const REPLAY_DRAW_CHUNK_FRAMES:Number = 200; // 시계를 따라가려고 한번에 그리는 프레임 수 단위
        private static const REPLAY_DRAW_TIME_BUDGET:int = 14; // 한 틱에 그리기에 쓰는 최대 시간(ms)
        private static const REPLAY_AUTO_SKIP_PLAY_MIN_MS:Number = 1000; // 자동 건너뛰기 재생 구간 길이 범위
        private static const REPLAY_AUTO_SKIP_PLAY_MAX_MS:Number = 3000;
        private static const REPLAY_AUTO_SKIP_PLAY_RANGE_COUNT:int = 3; // 범위를 이만큼 나눠서 한 바퀴씩 골고루 뽑음
        private static var autoSkipPlayRangeBag:Vector.<int> = new Vector.<int>();
        private static var autoSkipLastPlayRange:int = -1;
        private static const REPLAY_AUTO_SKIP_FADE_MS:Number = 250; // 건너뛴 직후 이전 화면이 사라지는 시간
        private static const REPLAY_AUTO_SKIP_FADE_HIDE_ALPHA:Number = 0.02; // 이 투명도 이하면 크로스페이드를 끝내고 숨김
        private static var autoSkipFadeBitmap:Bitmap = new Bitmap(); // 건너뛰기 직전 화면. 캔버스 크기가 같으면 비트맵데이터를 재사용함 (리플레이 모드를 나갈때 해제)
        private static var rCanvasCompleteAnchorPoint:Sprite = new Sprite(); // 리플레이에어 이미지가 재생되었을때 보여주는 객체 stage와 가로세로 중앙정렬
        private static var rCanvasCompleteBitmap:Bitmap = new Bitmap(new BitmapData(1, 1, false, 0), "auto", true);
        private static var updatePrograssBarStartTime:int = 0; // 리플레이 시작 시간저장 update prograss bar에서 프레임 오차 수정할때 참고하는 변수
        private static var rReplayRestartTimerCount:uint = 0; // 리스타트 타이머
        private static var isReplaySpeedDragging:Boolean = false; // 속도 슬라이더 드래그 중에는 s eekbar 텍스트에 속도 힌트를 보여줌
        private static var stopGeneratingCacheImageFunc:Function = null; // 캐시 이미지 만드는 중이면 멈추는 함수
        private static var frameOnEnterReplayMode:Number = -1; // 리플레이 켜줄때 rNowFrame이 변하니까 그전에 백업해주고 꺼줄때 이 프레임으로 되돌림
        public static var lastReplayTimeBoxYPos:Number = 0; // 리플레이 재생해줄때 WorkspaceView.topbar 사라지게 할때 원래 위치 저장해서 끝나면 이 위치로 복원해줌
        private static var isReplayWaitingBoxShown:Boolean = false;
        private static var isRestartPending:Boolean = false; // 자연 종료로 멈췄고 재시작 대기 타이머가 곧 시작될 차례

        public static function initializeReplayController():void
        {
            ReplayDrawer.rReplayFOFOCursor.initWaitingTextBox(UIController.seekBarBox.prograssInfo.defaultTextFormat, UIController.seekBarBox.prograssInfo.embedFonts);
        }

        public static function createNewFileFromReplayCanvas():void
        {
            UIController.seekBarBox.setDeleteRangeBarVisible(false);
            // 길게 누르는 동안 worker가 시작되었을 수 있음
            if (FileManager.isReplayDataLocked())
            {
                FileManager.showReplayDataLockedHint();
                return;
            }
            copyReplayCanvasDataToDrawCanvas();
            clearReplayDataAndResetVars();
            syncDrawCanvasWithReplayCanvas();
            exitReplayMode();
            UndoController.exitDeepUndo();
            resetReplayTime();
            ReferenceLayerController.resetRefLayerImageTransform();
        }

        //리플레이 배속을 끝까지 올렸을때 총 프레임수을 고려해서 30초가 걸리도록 갱신해줌
        public static function updateTotalFrameAndReplayMaxSpeed(totalframe:Number):void
        {
            ReplayState.TOTAL_FRAME = totalframe;
            // 파일 부분 색인은 바꾼 곳에서 증분으로 갱신하고(ReplayClock.extendFileIndexByAppendedFrames, truncateFileIndex, rebuildFileIndex) 여기서는 맞는지 확인만 함. 메모리 부분은 매번 새로 만듬
            ReplayClock.buildOrFixFileIndex();
            ReplayClock.rebuildMemoryIndex();
            var maxSpeed:Number = Math.floor(ReplayClock.getSeekbarAxisMsAtSpeed(1) / REPLAY_MAX_SPEED_PLAY_MS); // 1배속 기준으로 쉬는 구간을 줄인 길이 (배속에 따라 길이가 바뀌는 순환을 피함)

            if (maxSpeed < 1.0)
            {
                maxSpeed = 1.0;
            }

            ReplayState.REPLAY_MAX_SPEED = maxSpeed;

            if (UIController.topBar)
            {
                UIController.topBar.updateReplaySpeedSnapMarker(maxSpeed, ReplayState.REPLAY_AUTO_SKIP_PLAY_SPEED);
            }

            if (ReplayState.rReplaySpeedMultipler > maxSpeed)
            {
                ReplayState.rReplaySpeedMultipler = maxSpeed;
            }

            // 배속이 바뀌지 않았어도 축(쉬는 구간) 표시는 갱신해야 함
            // onReplaySpeedChanged가 refresh replay waiting ranges를 포함하므로 여기서 한 번만 부름 (예전에는 클램프 때 두 번 그림)
            onReplaySpeedChanged();
        }

        // 배속이 바뀌면 시크바 축(쉬는 구간의 유지 길이)이 달라지므로 표시와 위치를 다시 맞춤. 멈춰 있을때만 위치를 직접 갱신함 (재생 중에는 매 프레임 갱신됨)
        private static function onReplaySpeedChanged():void
        {
            refreshReplayWaitingRanges();

            if (UIController.seekBarBox && !ReplayState.isReplayStarted)
            {
                UIController.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayClock.getSeekbarRatioOfFrame(ReplayState.rNowFrame));
            }
        }

        // 시크바의 쉬는 구간 표시를 다시 그림. 프레임 수나 배속이 바뀔때 부름
        public static function refreshReplayWaitingRanges():void
        {
            if (!UIController.seekBarBox)
            {
                return;
            }

            UIController.seekBarBox.setReplayWaitingRanges(ReplayClock.getSeekbarIdleMarks());
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
                    NativeDragManager.acceptDragDrop(AppContext.stage);
                }
            }
        }

        public static function deleteReplayDataBeforeCurrentFrame():void
        {
            if (FileManager.isReplayDataLocked())
            {
                UIController.seekBarBox.setDeleteRangeBarVisible(false);
                FileManager.showReplayDataLockedHint();
                return;
            }
            // 미러 되어있을 수도 있기 때문에 원래 프레임으로 점프해준뒤에 실행해줌
            ensureReplayCanvasState();
            UIController.seekBarBox.setDeleteRangeBarVisible(false);
            ReplayFileCache.createFirstImageCache(ReplayDrawer.rCanvasLayer1BitmapData, ReplayDrawer.rCanvasLayer2BitmapData, ReplayState.RCANVAS_BG_COLOR, ReplayState.rMirrorON);
            const fs:FileStream = new FileStream();

            if (ReplayState.rMemoryDataReadON)
            {
                // repfile 초기화
                UndoHistory.updateUndoBaseImageFromReplayMode();
                fs.open(AppDataPaths.replayDataFilePath, FileMode.WRITE); // 파일 생성
                fs.close();
                ReplayDrawer.commandWindow.disposeQueuedCommandGroups();
                FileManager.isFileAlreadySaved = false;
                FileManager.enableNewFileButton();
                ReplayState.setRFileDataTotalFrame(0);
                TimingSheetFile.resetTimingSheet();
                ReplayClock.rebuildFileIndex();
                ReplayState.rMemoryData.splice(0, ReplayState.rMemoryDataIndex + 1);
                ReplayState.rMemoryDataFrames.splice(0, ReplayState.rMemoryDataIndex + 1);
                ReplayState.rMemoryDataTimingSheet.splice(0, ReplayState.rMemoryDataIndex + 1);
                updateTotalFrameAndReplayMaxSpeed(ReplayState.getTotalFrame());
                updateReplayPrograssText(true, ReplayState.TOTAL_FRAME);

                if (ReplayState.isZeroReplayFrame())
                {
                    UIController.seekBarBox.resetReplayPrograssBarWidth();
                }
                else
                {
                    UIController.seekBarBox.setReplayPrograssBarMaxWidth();
                }

                UIController.topBar.repNewFileButton.alpha = UITheme.OFFALPHA;
                ReplayDrawer.rReplayFOFOCursor.visible = false;
                finalize();
            }
            else
            {
                // make jumpimage에서 변경해주기 때문에

                if (ReplayFileCache.repFileTemp.exists) // 이미 있으면 지워주고
                {
                    ReplayFileCache.repFileTemp.deleteFile();
                }

                var ba:ByteArray = new ByteArray();
                var d:Array;
                // 짤라서 ba에 넣어주기
                fs.open(AppDataPaths.replayDataFilePath, FileMode.READ);
                fs.position = ReplayState.rFileLastBytePosition;
                fs.readBytes(ba, 0, fs.bytesAvailable);
                fs.close();
                // 시간 간격도 같은 프레임만큼 앞을 잘라줌
                TimingSheetFile.deleteSheetBeforeFrame(ReplayState.rNowFrame);
                // ba에 넣어준걸 다시 써주기
                fs.open(AppDataPaths.replayDataFilePath, FileMode.WRITE);
                fs.position = 0;
                fs.writeBytes(ba, 0, ba.length);
                fs.close();
                ReplayDrawer.commandWindow.disposeQueuedCommandGroups(); // repdata가 바뀌었으니 미리 읽은 묶음은 버림
                ba.clear();
                ba = null;
                ReplayDrawer.rReplayFOFOCursor.visible = false;
                UIController.seekBarBox.resetReplayPrograssBarWidth();
                FileManager.isFileAlreadySaved = false;
                UIController.loadMenuBox.clearPreviewImage(); // 이 경우 로드박스에 배경 이미지를 깔지 않음
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
                UIController.seekBarBox.setDeleteRangeBarVisible(false);
                FileManager.showReplayDataLockedHint();
                return;
            }
            ensureReplayCanvasState();
            UIController.seekBarBox.setDeleteRangeBarVisible(false);

            if (ReplayState.rMemoryDataReadON === true)
            {
                // 위에서 setJumpOneFrame을 해줘서 rindex가 증가되었기 때문에
                // 실제 undo해줘야할 인덱스는 -1해줘야하는거임
                UndoController.undoToIndex(ReplayState.rMemoryDataIndex);
                ReplayState.rMemoryData.splice(ReplayState.rMemoryDataIndex + 1);
                ReplayState.rMemoryDataFrames.splice(ReplayState.rMemoryDataIndex + 1);
                ReplayState.rMemoryDataTimingSheet.splice(ReplayState.rMemoryDataIndex + 1);
                updateTotalFrameAndReplayMaxSpeed(ReplayState.getTotalFrame());
                resetReplayTime();
            }
            else if (ReplayState.rMemoryDataReadON === false)
            {
                ReplayDrawCommands.setFirstRCursorPosCurrent();
                const fs:FileStream = new FileStream();
                fs.open(AppDataPaths.replayDataFilePath, FileMode.UPDATE);
                fs.position = ReplayState.rFileLastBytePosition;
                fs.truncate(); // 데이터 위에 짤라주고
                fs.close();
                ReplayDrawer.commandWindow.disposeQueuedCommandGroups(); // repdata가 바뀌었으니 미리 읽은 묶음은 버림
                // 썸네일 이미지도 날려줌
                const rNowFrameSave:Number = ReplayState.rNowFrame;
                ReplayFileCache.truncateCacheImagesAfterFrame(rNowFrameSave);
                ReplayState.setRFileDataTotalFrame(rNowFrameSave);
                TimingSheetFile.deleteSheetAfterFrame(rNowFrameSave);
                ReplayClock.truncateFileIndex(rNowFrameSave);
                updateTotalFrameAndReplayMaxSpeed(rNowFrameSave);
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
                if (ReplayDrawCommands.getCommandIndex() < ReplayDrawCommands.getCommandCount())
                {
                    ReplayDrawer.finishRemainingCommandGroup();
                    updateReplayPrograssText();
                    UIController.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayClock.getSeekbarRatioOfFrame(ReplayState.rNowFrame));
                    updateDeleteReplayDataButtonsState();
                }

                if (ReplayState.rNowFrame >= ReplayState.TOTAL_FRAME)
                {
                    UIController.seekBarBox.setDeleteRangeBarVisible(false);
                    return true;
                }
            }

            UIController.seekBarBox.updateDeleteDangeBarPosWidth(mode);
            return false;
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
            clearReplayDataAndResetVars();
            ReplayDrawCommands.resetFirstRCursorPos();
            ReplayFileCache.clearRFrameTempCache();
        }

        public static function stopReplayBeforeFrameJump():void
        {
            ReplayState.isReplayFinished = false;

            if (ReplayState.isReplayStarted)
            {
                stopReplay();
            }
        }

        public static function moveToPreviousStep():void
        {
            stopReplayBeforeFrameJump();

            if (ReplayState.rNowFrame > 0)
            {
                ReplayDrawer.renderReplayFrame(ReplayState.rPrevFrame, ReplayDrawer.JUMP_FRAME_PREV);
                updateDeleteReplayDataButtonsState();
                UIController.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayClock.getSeekbarRatioOfFrame(ReplayState.rNowFrame));
                updateReplayPrograssText();
            }
        }

        public static function moveToNextStep():void
        {
            stopReplayBeforeFrameJump();

            if (ReplayState.rNowFrame < ReplayState.TOTAL_FRAME)
            {
                if (ReplayDrawCommands.getRemainingCommandCount() === 0)
                {
                    // +1해줘서 다음 데이터 갱신해주고 나머지 끝까지 그려줌
                    ReplayDrawer.renderReplayFrame(ReplayState.rNowFrame + 1, ReplayDrawer.JUMP_FRAME_NEXT);
                    ReplayDrawer.renderReplayFrame(ReplayState.rNowFrame + ReplayDrawCommands.getRemainingCommandCount(), ReplayDrawer.JUMP_FRAME_NEXT);
                    // jumpframe함수 이후에 실행
                }
                else
                {
                    ReplayDrawer.renderReplayFrame(ReplayState.rNowFrame + ReplayDrawCommands.getRemainingCommandCount(), ReplayDrawer.JUMP_FRAME_NEXT);
                }

                updateDeleteReplayDataButtonsState();
                UIController.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayClock.getSeekbarRatioOfFrame(ReplayState.rNowFrame));
                updateReplayPrograssText();
            }
        }

        public static function moveToPreviousFrame():void
        {
            stopReplayBeforeFrameJump();

            if (ReplayState.rNowFrame > 0)
            {
                ReplayDrawer.renderReplayFrame(ReplayState.rNowFrame - 1, ReplayDrawer.JUMP_FRAME_MANUAL);
                updateDeleteReplayDataButtonsState();
                UIController.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayClock.getSeekbarRatioOfFrame(ReplayState.rNowFrame));
                updateReplayPrograssText();
            }
        }

        public static function moveToNextFrame():void
        {
            stopReplayBeforeFrameJump();

            if (ReplayState.rNowFrame < ReplayState.TOTAL_FRAME)
            {
                ReplayDrawer.renderReplayFrame(ReplayState.rNowFrame + 1, ReplayDrawer.JUMP_FRAME_MANUAL);
                updateDeleteReplayDataButtonsState();
                UIController.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayClock.getSeekbarRatioOfFrame(ReplayState.rNowFrame));
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
            var wasReplayStarted:Boolean = false;
            var clickX:Number = UIController.seekBarBox.trackBar.mouseX * UIController.seekBarBox.trackBar.scaleX;
            var clickedRatio:Number = clickX / UIController.seekBarBox.trackBar.width; // 마지막으로 가리킨 시크바 위치(0~1), 쉬는 구간 중간을 클릭했을때 그 시각에서 이어 재생하는데 씀
            var finalFrame:Number = ReplayClock.seekbarRatioToFrame(clickedRatio);

            function updateFrameFromSeekbarMouse():void
            {
                var mx:Number = UIController.seekBarBox.trackBar.mouseX * UIController.seekBarBox.trackBar.scaleX;

                if (mx < 0)
                {
                    mx = 0;
                    UIController.seekBarBox.resetReplayPrograssBarWidth();
                }
                else if (mx > UIController.seekBarBox.trackBar.width)
                {
                    mx = UIController.seekBarBox.trackBar.width;
                    UIController.seekBarBox.setReplayPrograssBarMaxWidth();
                }
                else
                {
                    UIController.seekBarBox.setReplayPrograssBarWidth(mx);
                }

                clickedRatio = mx / UIController.seekBarBox.trackBar.width;
                finalFrame = ReplayClock.seekbarRatioToFrame(clickedRatio);
                updateReplayPrograssText(false, finalFrame);
            }

            function onSeekbarDragStart():void
            {
                if (ReplayState.isReplayStarted)
                {
                    wasReplayStarted = true;
                    ReplayState.isReplayStarted = false;
                    ReplayController.clearReplayWaitingState();
                    FOFOTimer.remove("replayDrawTimer");
                    ReplayDrawer.rFileStream.close();
                }

                FOFOTimer.remove("prograssBarUpdateTimer");
                UIController.seekBarBox.setReplayPrograssBarWidth(clickX);
                updateFrameFromSeekbarMouse();
                ReplayState.isReplayFinished = false;
                UIController.seekBarBox.resetPrograssBarColor();
            }

            function onSeekbarMouseMove():void
            {
                updateFrameFromSeekbarMouse();

                if (!FOFOTimer.hasTimer("jumpFrameUpdateTimer"))
                {
                    FOFOTimer.addByName("jumpFrameUpdateTimer", 0.25, false, function ():void
                        {
                            ReplayDrawer.renderReplayFrame(finalFrame, ReplayDrawer.JUMP_FRAME_MANUAL);
                        });
                }
            }

            function onSeekbarMouseUp():void
            {
                FOFOTimer.remove("jumpFrameUpdateTimer");
                ReplayDrawer.renderReplayFrame(finalFrame, ReplayDrawer.JUMP_FRAME_MANUAL);
                updateFrameFromSeekbarMouse();
                // jumpframe함수 이후에 실행
                updateDeleteReplayDataButtonsState();
                // 클릭한 시각을 기억해둠. 클릭한 곳이 쉬는 구간 중간이면 재생을 시작할때 구간 처음이 아니라 그 시각부터 이어감
                ReplayClock.savePausedPosition(ReplayState.rNowFrame, ReplayClock.seekbarRatioToRecordedTime(clickedRatio));
                // 재생중에 스킵하고 있었으면 다시 시작

                //이 조건이 wasReplayStarted보다 먼저야와야함
                //순서를 바꾸면 슬라이드 쇼 모드에서 탐색바 끝까지 올리고 정지되었는데 stopreplay가 호출되지 않아서 버그생김
                if (ReplayState.isReplayFinished)
                {
                    UIController.seekBarBox.setReplayPrograssBarMaxWidth();
                    updateReplayPrograssText(true, ReplayState.TOTAL_FRAME);
                    stopReplay();
                }
                if (wasReplayStarted && !ReplayState.isReplayFinished)
                {
                    startReplay();
                }
            }

            DragInteraction.start(onSeekbarDragStart, onSeekbarMouseMove, onSeekbarMouseUp);
        }

        private static function handleReplayCacheImageGenerateComplete(fs:FileStream, onFrameEnter:Function, _frameSum:Number, _frameSumLast:Number, finalizeFunc:Function):void
        {
            AppContext.stage.removeEventListener(Event.ENTER_FRAME, onFrameEnter);
            fs.close();
            stopGeneratingCacheImageFunc = null;
            ReplayDrawCommands.clearCommandData();
            ReplayState.setRFileDataTotalFrame(_frameSum);
            const sheetFramesBefore:Number = TimingSheetFile.sheetFrameCount;
            TimingSheetFile.resizeSheetToFrameCount(_frameSum); // 시트가 없거나 길이가 다르면 repdata 프레임 수에 맞춤

            if (sheetFramesBefore !== _frameSum)
            {
                if (sheetFramesBefore === 0)
                {
                    TimingSheetFile.setLegacyFrames(_frameSum); // 시트가 아예 없던 옛 파일: 채운 프레임 전부가 옛 구간(앱 fps로 재생)
                }

                ReplayClock.rebuildFileIndex(); // 시트를 채워 맞췄으면(시간 기록이 없는 옛 파일 등) 색인도 다시 읽음. 불러오기·앞 자르기에서 시트를 쓰며 만든 색인은 그대로 씀
            }
            ReplayState.rReplayImageCacheState = ReplayState.REPLAY_IMAGE_CAHCHE_COMPLETE;
            ReplayFileCache.deleteCacheProgress();
            resetReplayTime();
            updateTotalFrameAndReplayMaxSpeed(ReplayState.getTotalFrame());
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
                ReplayDrawer.viewport.centerCanvasInStage("replay");
                ReplayModeInput.addEvents();
                ReplayDrawer.rCanvasAnchorPoint.visible = true;
            }
            else
            {
                ReplayState.rMemoryDataReadON = false;
                DrawCanvas.applyReplayCanvasToDrawModeCanvas();
                CanvasView.canvasAnchorPoint.visible = true;
                CanvasView.canvasAnchorPoint.rotation = 0;
                ReplayDrawer.setReplayCursorRotation(0);
                CanvasView.canvasZoomIndex = 3;
                CanvasView.viewport.setCanvasScale(1.0);
                CanvasView.viewport.centerCanvasInStage("draw");
                UndoController.resetUndoState();
                DrawModeInput.addEvents();
            }

            LoadBoxController.closeLoadMenuBox();
            UIController.loadMenuBox.clearPreviewImage(); // 캐시 이미지 만드는 동안만 쓰던 배경
            KeyState.clearKeyBuffer();

            if (finalizeFunc !== null)
            {
                finalizeFunc();
            }
        }

        private static var loadCacheRunSeq:int = 0; // 불러오기 캐시 임시 파일 이름이 실행마다 겹치지 않게
        private static const PENDING_CACHE_WAIT_LIMIT:int = 120000;

        // resumeIndex가 0 이상이면 그 번호의 캐시 이미지 상태에서 이어서 만듬 (rJumpImageFrameData는 미리 복원되어 있어야함)
        public static function generateReplayCacheImage(finalizeFunc:Function, resumeIndex:int = -1):void
        {
            const fs:FileStream = new FileStream();
            const fs2:FileStream = new FileStream();
            const totalSize:Number = AppDataPaths.replayDataFilePath.size;
            const deepUndoFlag:Boolean = UndoHistory.isDeepUndoEnabled;
            var rect:Rectangle;
            var _frameSum:Number = 0;
            var _LastframeSum:Number = 0;
            var dataWriteCount:uint = 0;
            var hintPrintTimeSave:int = getTimer();
            CanvasView.canvasAnchorPoint.visible = false;
            ReplayDrawer.rCanvasAnchorPoint.visible = false;
            CanvasNavigator.box.visible = false;
            ReplayDrawer.clearCanvasReplayMode(); // 리플레이 캔버스 먼저 깨끗하게
            fs.open(AppDataPaths.replayDataFilePath, FileMode.READ);

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
            UIController.loadMenuBox.visible = false;

            // 네이티브로 쓸 수 있으면 구간마다 스냅샷(두 레이어 내부 버퍼 복사)만 넘기고 바로 다음 구간을 그림, 압축·쓰기는 네이티브 스레드에서 병렬
            // 작업은 작업마다 다른 임시 파일(imagecache_loadtmp)에 쓰고, main이 앞에서부터 이어진 번호만 imagecache/<번호>로 옮겨서
            // rJumpImageFrameData와 진행 기록에 확정 (undo 캐시의 commitCacheImage와 같은 구조, 이어 만들기는 확정된 번호까지만 믿음)
            // 대체 경로로 바꾸거나 멈출때는 cacheEpoch를 올려서 그 전에 시작한 작업의 결과(늦게 온 완료 알림)는 임시 파일만 지우고 버림
            var useNativeCache:Boolean = NativeImageCaching.isAvailable;
            var isStopped:Boolean = false;
            var nextCacheIndex:int = ReplayFileCache.rJumpImageFrameData.length;
            var cacheEpoch:int = 0;
            var pendingCacheJobs:int = 0; // 지금 cacheEpoch의 작업만 셈, 무효화된 작업은 파일 끝에서 기다리지 않음
            var pendingWaitStart:int = 0; // 파일 끝에서 남은 작업을 기다리기 시작한 시각
            var waitingSnapshot:CacheImageMetaData = null; // 메모리 상한 때문에 아직 못 넘긴 스냅샷, 넘길때까지 다음 구간을 그리지 않음
            var snapshotFrames:Object = {}; // 번호 -> nowFrame (확정 전)
            var doneCacheIndexes:Object = {}; // 다 썼지만 앞 번호가 아직이라 확정 못 한 번호 -> 임시 파일
            const cacheGeneration:int = BackgroundWorkerCoordinator.getCacheGeneration();
            const runId:int = ++loadCacheRunSeq;
            ReplayFileCache.clearLoadedCacheTempFolder();

            function confirmFinishedCacheImages():void
            {
                var confirmed:Boolean = false;

                while (doneCacheIndexes[ReplayFileCache.rJumpImageFrameData.length] !== undefined)
                {
                    const jumps:Array = ReplayFileCache.rJumpImageFrameData;
                    const index:int = jumps.length;
                    const tempFile:File = doneCacheIndexes[index];
                    const frame:Number = snapshotFrames[index];
                    delete doneCacheIndexes[index];
                    delete snapshotFrames[index];

                    // 이진 탐색이 깨지지 않게 마지막 캐시보다 뒤 프레임만 받음, 옮기기에 실패하면 그 작업이 실패한 것으로 보고 대체 경로로
                    if (!(jumps.length > 0 && frame > jumps[jumps.length - 1]) || !ReplayFileCache.moveTempCacheImage(tempFile, index))
                    {
                        AppDataPaths.writeCrashLog("Replay cache image " + index + " commit failed (frame " + frame + ")");
                        ReplayFileCache.deleteReplayCacheImages(tempFile);
                        switchToSyncCacheImageCreation();
                        break;
                    }

                    jumps.push(frame);
                    confirmed = true;
                }

                if (confirmed)
                {
                    ReplayFileCache.saveCacheProgress();
                }
            }

            // 진행 중이거나 확정 전인 네이티브 작업의 결과를 버림 (확정 전 임시 파일은 지우고, 진행 중인 작업은 알림이 올때 자기 임시 파일을 지움)
            function discardNativeCacheImageTasks():void
            {
                cacheEpoch++;
                pendingCacheJobs = 0;

                for each (var tempFile:File in doneCacheIndexes)
                {
                    ReplayFileCache.deleteReplayCacheImages(tempFile);
                }

                snapshotFrames = {};
                doneCacheIndexes = {};
                // 네이티브가 블록 사이에서 빨리 멈추게 세대도 바꿈
                BackgroundWorkerCoordinator.cancelPendingCacheImages();
            }

            // 네이티브 작업이 실패하면 그 번호부터는 확정할 수 없으므로 남은 작업을 버리고 확정된 다음 번호부터 AS3로 씀
            function switchToSyncCacheImageCreation():void
            {
                if (!useNativeCache)
                {
                    return;
                }

                useNativeCache = false;
                discardNativeCacheImageTasks();
                nextCacheIndex = ReplayFileCache.rJumpImageFrameData.length;
            }

            // 지금 리플레이 캔버스로 캐시 이미지 하나, 메모리 상한이라 못 넘겼으면 false (다음 프레임에 다시)
            function createCacheImageFromReplayCanvas(metadata:CacheImageMetaData):Boolean
            {
                if (useNativeCache)
                {
                    const index:int = nextCacheIndex;
                    const epoch:int = cacheEpoch;
                    const tempFile:File = AppDataPaths.replayCacheImageLoadTempFolderPath.resolvePath(runId + "_" + epoch + "_" + index);
                    const result:int = NativeImageCaching.startCacheFileWrite(tempFile.nativePath,
                            ReplayDrawer.rCanvasLayer1BitmapData, ReplayDrawer.rCanvasLayer2BitmapData, metadata, cacheGeneration, false, function (r:Object):void
                            {
                                // 무효화된 작업이거나 생성이 멈췄으면 결과를 버림 (pendingCacheJobs는 무효화할때 이미 뺌)
                                if (epoch !== cacheEpoch || isStopped)
                                {
                                    ReplayFileCache.deleteReplayCacheImages(tempFile);
                                    return;
                                }

                                pendingCacheJobs--;

                                if (r.status === "done")
                                {
                                    doneCacheIndexes[index] = tempFile;
                                    confirmFinishedCacheImages();
                                }
                                else
                                {
                                    if (r.status !== "cancelled")
                                    {
                                        AppDataPaths.writeCrashLog("Replay cache image " + index + " failed: " + r.status + " " + r.error);
                                    }
                                    ReplayFileCache.deleteReplayCacheImages(tempFile);
                                    switchToSyncCacheImageCreation();
                                }
                            });

                    if (result === NativeImageCaching.RESULT_BUSY)
                    {
                        return false;
                    }

                    if (result === NativeCore.OK)
                    {
                        snapshotFrames[index] = metadata.nowFrame;
                        nextCacheIndex++;
                        pendingCacheJobs++;
                        return true;
                    }

                    switchToSyncCacheImageCreation();
                }

                // 확정된 다음 번호로 호출 안에서 씀
                ReplayFileCache.createCacheImage(ReplayDrawer.rCanvasLayer1BitmapData, ReplayDrawer.rCanvasLayer2BitmapData, metadata);
                nextCacheIndex = ReplayFileCache.rJumpImageFrameData.length;
                ReplayFileCache.saveCacheProgress();
                return true;
            }

            function printPrograssHint(bytes:Number):void
            {
                const perc:Number = Math.round(((totalSize - bytes) / totalSize) * 100);
                // const str:String = perc.toFixed(1)+"%";
                UIController.loadMenuBox.updatePlaseWaitPrograss(perc + "%");
            }

            UIController.loadMenuBox.showPleaseWaitTextOrCustomText("Reading replay file", "(Press Esc to cancel)");
            LoadBoxController.openLoadMenuBox();

            function onFrameEnter(e:Event):void
            {
                if (waitingSnapshot !== null)
                {
                    if (!createCacheImageFromReplayCanvas(waitingSnapshot))
                    {
                        printPrograssHint(fs.bytesAvailable);
                        return;
                    }

                    waitingSnapshot = null;
                }

                while (true)
                {
                    const namojiBytes:Number = fs.bytesAvailable;

                    if (namojiBytes === 0)
                    {
                        // 네이티브 작업이 다 확정된 뒤에 끝냄, 알림이 오지 않으면(정상이면 없는 일) 2분 뒤 남은 작업을 버리고 끝냄
                        if (pendingCacheJobs > 0)
                        {
                            if (pendingWaitStart === 0)
                            {
                                pendingWaitStart = getTimer();
                            }
                            else if (getTimer() - pendingWaitStart > PENDING_CACHE_WAIT_LIMIT)
                            {
                                AppDataPaths.writeCrashLog("Replay cache image jobs timed out: " + pendingCacheJobs);
                                switchToSyncCacheImageCreation();
                            }
                            return;
                        }

                        isStopped = true;
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
                    ReplayDrawCommands.setCommandData(data);
                    _LastframeSum = _frameSum;
                    _frameSum += data.length; // _rJumpImageCount 변수보다 먼저 와야함
                    dataWriteCount += data.length;
                    ReplayDrawCommands.drawAllCommands();

                    if (dataWriteCount > ReplayFileCache.REPLAY_DISK_CACHE_FRAME_INTERVAL)
                    {
                        dataWriteCount = 0;
                        // 메타데이터는 지금(커서 위치 포함) 만들어 둠, 메모리 상한이면 다음 프레임에 같은 상태로 다시 시도
                        const snapshot:CacheImageMetaData = new CacheImageMetaData
                            (
                                ReplayDrawer.rCanvasLayer1BitmapData.width,
                                ReplayDrawer.rCanvasLayer1BitmapData.height,
                                ReplayState.RCANVAS_BG_COLOR,
                                fs.position,
                                _LastframeSum,
                                _frameSum,
                                ReplayState.rMirrorON
                            );

                        if (UIController.seekBarBox.prograssBar.width > 0)
                        {
                            UIController.seekBarBox.resetReplayPrograssBarWidth();
                        }

                        if (!createCacheImageFromReplayCanvas(snapshot))
                        {
                            waitingSnapshot = snapshot;
                            printPrograssHint(fs.bytesAvailable);
                            return;
                        }
                    }
                }
            }

            AppContext.stage.addEventListener(Event.ENTER_FRAME, onFrameEnter);
            stopGeneratingCacheImageFunc = function ():void
            {
                AppContext.stage.removeEventListener(Event.ENTER_FRAME, onFrameEnter);
                fs.close();
                isStopped = true;

                // 아직 쓰는 중이거나 확정 전인 네이티브 캐시는 버림 (진행 기록에는 확정된 번호만 있어서 다음 실행때 그 뒤부터 다시 만듦)
                discardNativeCacheImageTasks();
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
            UIController.loadMenuBox.clearPreviewImage();
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

            KeyState.clearKeyBuffer();
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
            onReplaySpeedChanged();
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
            ReplayDrawCommands.clearCommandData();
        }

        public static function updateReplayPrograssText(finishFlag:Boolean = false, customFrame:Number = NaN):void
        {
            if (isReplaySpeedDragging)
            {
                UIController.seekBarBox.prograssInfo.text = getReplaySpeedHintText();
                return;
            }

            if (isNaN(customFrame))
            {
                customFrame = ReplayState.rNowFrame;
            }

            const remainingTime:String = (UndoHistory.isDeepUndoEnabled || finishFlag) ? "" : getReplayRemainingTimeString(ReplayState.rReplaySpeedMultipler, ReplayState.TOTAL_FRAME - customFrame);

            UIController.seekBarBox.prograssInfo.text = customFrame + " / " + ReplayState.TOTAL_FRAME + remainingTime;
        }

        public static function startUpdatingPrograssBarTimer():void
        {
            if (FOFOTimer.hasTimer("prograssBarUpdateTimer"))
            {
                return;
            }

            var lastCursorUpdateTime:int = getTimer();
            var lastTextUpdateTime:int = getTimer();
            const cursorUpdateTime:int = ReplayState.REPLAY_VISUAL_UPDATE_MS;
            const textUpdateTime:int = 1000;
            updateReplayPrograssText();
            UIController.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayClock.getSeekbarRatioOfFrame(ReplayState.rNowFrame));
            FOFOTimer.addByName("prograssBarUpdateTimer", 0.0, true, function ():Boolean
                {
                    if (!ReplayState.isReplayModeON)
                    {
                        return false;
                    }

                    // 마지막 명령의 연출(채우기, 올가미, 이동, 선)이 아직 진행 중이면 끝날때까지 완료 처리를 미룸
                    if (ReplayState.rNowFrame >= ReplayState.TOTAL_FRAME && !ReplayDrawer.anim.isAnimActive)
                    {
                        UIController.seekBarBox.setReplayPrograssBarMaxWidth();
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
                    }

                    // 재생 중 시크바는 시계가 흐르는 대로 매 프레임 움직임 (쉬는 구간에도 멈추지 않음)
                    if (ReplayState.isReplayStarted)
                    {
                        UIController.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayClock.getSeekbarRatioWhilePlaying(ReplayState.getReplayClockSpeed()));
                    }

                    if (nowTime - lastTextUpdateTime >= textUpdateTime)
                    {
                        lastTextUpdateTime = nowTime;
                        updateReplayPrograssText();

                        // 재생 중에는 위에서 매 프레임 시계 기준으로 갱신하니 그리지 않은 프레임 기준 값으로 덮어써서 바가 앞뒤로 튀지 않게 함
                        if (!ReplayState.isReplayStarted)
                        {
                            UIController.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayClock.getSeekbarRatioOfFrame(ReplayState.rNowFrame));
                        }
                    }

                    updatePrograssBarStartTime = getTimer();
                    return true;
                });
        }

        public static function startCheckAutoHideTopbarOnPlaybackTimer():void
        {
            FOFOTimer.addByName("checkAutoHideTopbarOnPlaybackTimer", 0.0, true, function ():Boolean
            {
                if(!ReplayState.isReplayModeON || (!ReplayState.isReplayStarted && !ReplayState.isReplayRestartTimerON && !isRestartPending))
                {
                    showTopbarOnPlayback();
                    return false;
                }

                checkAutoHideTopbarOnPlayback();
                return true;
            });
        }

        public static function startReplayDrawTimer():void
        {
            var autoSkipPlayStartAt:int = getTimer(); // 자동 건너뛰기 재생 구간을 시작한 시각 (배속이 자동 건너뛰기 재생 배속 이하면 매 틱 갱신)
            var autoSkipPlayMs:Number = getNextAutoSkipPlayMs();
            FOFOTimer.addByName("replayDrawTimer", 0.0, true, function ():Boolean
                {
                    if (ReplayState.rReplaySpeedMultipler > ReplayState.REPLAY_AUTO_SKIP_PLAY_SPEED)
                    {
                        const autoSkipPlayElapsed:int = getTimer() - autoSkipPlayStartAt;

                        if (autoSkipPlayElapsed >= autoSkipPlayMs)
                        {
                            if (skipReplayAfterAutoSkipPlay(autoSkipPlayElapsed))
                            {
                                return true;
                            }

                            autoSkipPlayStartAt = getTimer();
                            autoSkipPlayMs = getNextAutoSkipPlayMs();
                        }
                    }
                    else
                    {
                        autoSkipPlayStartAt = getTimer();
                    }

                    if (drawReplayRemainingFrames())
                    {
                        isRestartPending = ReplayState.isReplayRepeatON; // 곧 재시작 대기가 시작됨 (그 사이 상단바가 잠깐 보였다 숨지 않게)
                        stopReplay(isRestartPending && ReplayMouseAutoHide.isMouseHidden);
                    }

                    ReplayDrawer.commandWindow.loadMoreCommandGroups(ReplayState.rNowFrame, ReplayState.getReplayClockSpeed());
                    if(!ReplayState.isReplayCanvasFitToWindow)
                    {
                        ReplayDrawer.cursorFollow.updateCameraAfterDraw();
                    }
                    return true;
                });
        }

        // 자동 건너뛰기 재생 구간 길이(ms). 범위를 같은 폭으로 나눈 구간을 한 바퀴씩 섞어서 하나씩 뽑고 (1초 근처만 연달아 나오는 일이 없게) 구간 안에서는 균등 랜덤
        private static function getNextAutoSkipPlayMs():Number
        {
            if (autoSkipPlayRangeBag.length === 0)
            {
                do
                {
                    autoSkipPlayRangeBag.length = 0;

                    for (var i:int = 0; i < REPLAY_AUTO_SKIP_PLAY_RANGE_COUNT; i++)
                    {
                        autoSkipPlayRangeBag.push(i);
                    }

                    for (var j:int = REPLAY_AUTO_SKIP_PLAY_RANGE_COUNT - 1; j > 0; j--)
                    {
                        const k:int = int(Math.random() * (j + 1));
                        const swap:int = autoSkipPlayRangeBag[j];
                        autoSkipPlayRangeBag[j] = autoSkipPlayRangeBag[k];
                        autoSkipPlayRangeBag[k] = swap;
                    }
                }
                while (autoSkipPlayRangeBag[autoSkipPlayRangeBag.length - 1] === autoSkipLastPlayRange); // 바퀴가 바뀌는 곳에서 같은 구간이 연달아 나오지 않게
            }

            autoSkipLastPlayRange = autoSkipPlayRangeBag.pop();
            return REPLAY_AUTO_SKIP_PLAY_MIN_MS + (autoSkipLastPlayRange + Math.random()) * (REPLAY_AUTO_SKIP_PLAY_MAX_MS - REPLAY_AUTO_SKIP_PLAY_MIN_MS) / REPLAY_AUTO_SKIP_PLAY_RANGE_COUNT;
        }

        // 자동 건너뛰기 재생 배속으로 autoSkipPlayedMs 동안 재생한 뒤, 선택한 배속에 맞게 그만큼 더 앞으로 건너뜀 (건너뛴 구간의 그림은 한 번에 그림)
        // 건너뛰는 녹화 시간 = 재생 구간 실제 시간 * (선택 배속 - 자동 건너뛰기 재생 배속). 반환값: 끝까지 가서 재생을 멈췄으면 true
        private static function skipReplayAfterAutoSkipPlay(autoSkipPlayedMs:Number):Boolean
        {
            const target:Number = ReplayClock.readRecordedTimeNow() + autoSkipPlayedMs * (ReplayState.rReplaySpeedMultipler - ReplayState.REPLAY_AUTO_SKIP_PLAY_SPEED);
            const targetFrame:Number = ReplayClock.getFrameCountAtRecorded(target);

            if (targetFrame <= ReplayState.rNowFrame)
            {
                ReplayClock.moveClockToRecorded(target);
                return false;
            }

            // 시크바를 누르는 것과 같은 순서: 가까운 캐시 이미지를 불러오고 남은 프레임만 그린 뒤 그 시각부터 이어서 재생
            // JUMP_FRAME_AUTO_SKIP은 재생 상태를 유지한 채 캐시 이미지를 불러오고 시크바 탐색용 메모리 캐시는 만들지 않음 (재생 중에는 임시 캐시가 없음)
            captureReplayCanvasForAutoSkipFade();
            clearReplayWaitingState();
            ReplayDrawer.rFileStream.close();
            ReplayDrawer.renderReplayFrame(targetFrame, ReplayDrawer.JUMP_FRAME_AUTO_SKIP);

            if (ReplayState.rNowFrame >= ReplayState.TOTAL_FRAME)
            {
                ReplayState.isReplayFinished = true;
                stopReplay();
                startReplayAutoSkipFade();
                return true;
            }

            if (!ReplayState.rMemoryDataReadON)
            {
                ReplayDrawer.rFileStream.open(AppDataPaths.replayDataFilePath, FileMode.READ);
                ReplayDrawer.rFileStream.position = ReplayState.rFileLastBytePosition;
            }

            ReplayClock.savePausedPosition(ReplayState.rNowFrame, target);
            ReplayClock.startClockAtFrame(ReplayState.rNowFrame, ReplayState.getReplayClockSpeed());
            startReplayAutoSkipFade();
            return false;
        }

        // 건너뛰기 직전 화면을 찍어 둠 (건너뛴 뒤 startReplayAutoSkipFade가 그 위에 얹어서 사라지게 함)
        // 합쳐진 레이어 비트맵을 표시 순서대로 copyPixels로 복사함 (패널 전체를 draw로 렌더하는 것보다 빠름). 비트맵은 크기가 같으면 재사용
        private static function captureReplayCanvasForAutoSkipFade():void
        {
            endReplayAutoSkipFade();
            const width:int = ReplayState.RCANVAS_WIDTH;
            const height:int = ReplayState.RCANVAS_HEIGHT;

            if (!autoSkipFadeBitmap.bitmapData || autoSkipFadeBitmap.bitmapData.width !== width || autoSkipFadeBitmap.bitmapData.height !== height)
            {
                disposeReplayAutoSkipFadeBitmapData();
                autoSkipFadeBitmap.bitmapData = new BitmapData(width, height, false, ReplayState.RCANVAS_BG_COLOR);
            }

            const snapshot:BitmapData = autoSkipFadeBitmap.bitmapData;
            const panel:Sprite = ReplayDrawer.rCanvasPanel;
            const area:Rectangle = new Rectangle(0, 0, width, height);
            snapshot.fillRect(area, 0xFF000000 | ReplayState.RCANVAS_BG_COLOR);

            for (var i:int = 0; i < panel.numChildren; i++)
            {
                const child:DisplayObject = panel.getChildAt(i);

                if (!child.visible)
                {
                    continue;
                }

                if (child === ReplayDrawer.rCanvasLayer1Bitmap || child === ReplayDrawer.rCanvasLayer2Bitmap)
                {
                    snapshot.copyPixels(Bitmap(child).bitmapData, area, new Point(0, 0), null, null, true);
                }
                else if (child === ReplayDrawer.rCanvasDrawLayer)
                {
                    snapshot.draw(child, null, new ColorTransform(1, 1, 1, child.alpha));
                }
            }
        }

        // 찍어 둔 화면을 캔버스 위에 얹고 SKIP_FADE_MS 동안 투명해지게 함. 캔버스와 같은 앵커에 넣어서 확대, 이동을 따라감
        // 한 번 붙인 자식은 리플레이 모드를 나갈때(removeReplayAutoSkipFadeBitmap)까지 두고, 거의 투명해지면 visible만 끔
        private static function startReplayAutoSkipFade():void
        {
            autoSkipFadeBitmap.alpha = 1;
            autoSkipFadeBitmap.visible = true;
            autoSkipFadeBitmap.x = ReplayDrawer.rCanvasPanel.x;
            autoSkipFadeBitmap.y = ReplayDrawer.rCanvasPanel.y;

            if (!autoSkipFadeBitmap.parent)
            {
                ReplayDrawer.rCanvasAnchorPoint.addChild(autoSkipFadeBitmap);
            }

            const fadeStart:int = getTimer();
            FOFOTimer.addByName("replayAutoSkipFadeTimer", 0.0, true, function ():Boolean
                {
                    autoSkipFadeBitmap.alpha = 1 - (getTimer() - fadeStart) / REPLAY_AUTO_SKIP_FADE_MS;

                    if (autoSkipFadeBitmap.alpha <= REPLAY_AUTO_SKIP_FADE_HIDE_ALPHA || !ReplayState.isReplayModeON)
                    {
                        endReplayAutoSkipFade();
                        return false;
                    }

                    return true;
                });
        }

        // 크로스페이드를 멈추고 화면에서 안 보이게만 함 (자식에서는 제거하지 않음)
        private static function endReplayAutoSkipFade():void
        {
            FOFOTimer.remove("replayAutoSkipFadeTimer");
            autoSkipFadeBitmap.visible = false;
        }

        // 리플레이 모드를 나갈때 자식에서 빼고 비트맵데이터를 해제함
        private static function removeReplayAutoSkipFadeBitmap():void
        {
            endReplayAutoSkipFade();

            if (autoSkipFadeBitmap.parent)
            {
                autoSkipFadeBitmap.parent.removeChild(autoSkipFadeBitmap);
            }

            disposeReplayAutoSkipFadeBitmapData();
        }

        private static function disposeReplayAutoSkipFadeBitmapData():void
        {
            if (autoSkipFadeBitmap.bitmapData)
            {
                autoSkipFadeBitmap.bitmapData.dispose();
                autoSkipFadeBitmap.bitmapData = null;
            }
        }

        public static function clearReplayWaitingState():void
        {
            if (isReplayWaitingBoxShown)
            {
                isReplayWaitingBoxShown = false;
                ReplayDrawer.rReplayFOFOCursor.hideReplaWaitingBox();
            }
        }

        // 매 틱 부르지만 상태가 바뀔때만 갱신함
        private static function updateReplayAfkState():void
        {
            if (!ReplayClock.isWaitingNextReplayCommand)
            {
                clearReplayWaitingState();
                return;
            }

            if (!isReplayWaitingBoxShown)
            {
                isReplayWaitingBoxShown = true;
                ReplayDrawer.rReplayFOFOCursor.showReplayWaitingBox();
            }
        }

        // 시계 기준으로 지금까지 그려야 하는 만큼 그림. 한 틱에 쓰는 시간에 상한을 둬서 못 따라가면 다음 틱에 이어서 그림
        // 반환값: 리플레이를 정지해야 하면 true
        private static function drawReplayRemainingFrames():Boolean
        {
            var remaining:Number = ReplayClock.getFrameCountToDrawNow(ReplayState.rNowFrame, ReplayState.getReplayClockSpeed()) - ReplayState.rNowFrame;
            const startTime:int = getTimer();
            updateReplayAfkState();
            ReplayDrawer.anim.updateAnimToRecorded(ReplayClock.readRecordedTimeNow()); // 진행 중인 연출(채우기, 올가미, 이동)을 시계에 맞춰 진행

            while (remaining > 0)
            {
                const chunk:Number = Math.min(remaining, REPLAY_DRAW_CHUNK_FRAMES);
                ReplayDrawer.isRealtimePlay = true;
                const shouldStop:Boolean = ReplayDrawer.drawReplayCommands(chunk, ReplayDrawer.JUMP_FRAME_PLAY);
                ReplayDrawer.isRealtimePlay = false;

                if (shouldStop)
                {
                    return true;
                }

                remaining -= chunk;

                if (getTimer() - startTime >= REPLAY_DRAW_TIME_BUDGET)
                {
                    break;
                }
            }

            // 마지막 프레임까지 그렸으면 한번 더 읽어서 끝났다는 것을 확인 (정지 판단은 읽는 쪽에서 함)
            // 마지막 명령의 연출(채우기, 올가미, 이동)이 아직 진행 중이면 끝날때까지 기다림
            if (ReplayState.rNowFrame >= ReplayState.TOTAL_FRAME && !ReplayDrawer.anim.isAnimActive)
            {
                return ReplayDrawer.drawReplayCommands(1, ReplayDrawer.JUMP_FRAME_PLAY);
            }

            return false;
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
            const clacMax:Number = Math.floor(ReplayClock.getSeekbarAxisMsAtSpeed(1) / 3000);

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
            onReplaySpeedChanged();
            UIController.topBar.setSpeedButtonPosByValue(_rSpeed, maxSpeed);
            showReplaySpeedMouseHint();
        }

        public static function startAdjustPlayBackSpeedByShortcut(increase:Boolean):void
        {
            KeyState.startKeyRepeat(true, adjustReplaySpeedByShortcut, increase);
        }

        public static function adjustReplaySpeedByMouse():void
        {
            if (ReplayClock.getSeekbarAxisMsAtSpeed(1) <= 3000) // 3초 이내면 안함
            {
                return;
            }

            // setSpeedButtonPosByValue도 오프셋 수정해주어야함
            const minDist:Number = UIController.topBar.replaySpeedSlider.x + 1.5;
            const maxDist:Number = minDist + UIController.topBar.replaySpeedSlider.width - 2.5;
            const maxSpeed:Number = ReplayState.REPLAY_MAX_SPEED;
            var oldSpeed:Number;
            var wasReplayRunning:Boolean = false; // 누르기 전에 재생 중이었는지 (놓으면 이어서 재생)
            var released:Boolean = false; // 놓기와 창 비활성화가 겹쳐도 놓기 처리는 한 번만
            PenSizePreviewCursor.setCursorInVisibleFlag(true);

            // 재생 중이면 시크바 드래그와 같은 임시 중단 (stopReplay를 부르지 않아 상단바 복귀와 카메라 snap이 일어나지 않고, 시크바 텍스트의 배속 힌트가 진행 갱신에 덮이지 않음)
            if (ReplayState.isReplayStarted)
            {
                wasReplayRunning = true;
                ReplayClock.savePausedPosition(ReplayState.rNowFrame, ReplayClock.readRecordedTimeNow()); // 쉬는 구간 중간에서 눌러도 그 시각부터 이어 재생
                ReplayState.isReplayStarted = false;
                ReplayController.clearReplayWaitingState();
                FOFOTimer.remove("replayDrawTimer");
                FOFOTimer.remove("prograssBarUpdateTimer");
                ReplayDrawer.rFileStream.close();
            }

            function setReplaySpeedBySliderX(mx:Number):void
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
                    onReplaySpeedChanged();
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

            function snapReplaySpeedSliderX(mx:Number):Number
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

            function moveReplaySpeedSliderButton(mx:Number):void
            {
                mx = snapReplaySpeedSliderX(mx);

                if (mx < minDist)
                {
                    mx = minDist;
                }
                else if (mx > maxDist)
                {
                    mx = maxDist;
                }

                UIController.topBar.replaySpeedSliderCursor.x = mx;
                setReplaySpeedBySliderX(mx);

                if (isSnapped)
                {
                    // floor 오차로 59가 되지 않도록 스냅 속도를 직접 지정
                    oldSpeed = ReplayState.REPLAY_AUTO_SKIP_PLAY_SPEED;
                    ReplayState.rReplaySpeedMultipler = ReplayState.REPLAY_AUTO_SKIP_PLAY_SPEED;
                    onReplaySpeedChanged();
                }
                updateReplayPrograssText(); // 드래그 중에는 속도 힌트가 seekbar 텍스트에 표시됨
            }

            function replaySpeedButtomUpEvent(e:MouseEvent):void
            {
                if (released)
                {
                    return;
                }

                released = true;
                MouseState.endDrag("replaySpeed");

                if (isReplaySpeedDragging)
                {
                    isReplaySpeedDragging = false;
                    Mouse.show();
                    HintController.hideMouseHint();
                    updateReplayPrograssText(ReplayState.isReplayFinished, ReplayState.isReplayFinished ? ReplayState.TOTAL_FRAME : NaN);
                }

                AppContext.stage.removeEventListener(MouseEvent.MOUSE_MOVE, replaySpeedButtomMoveEvent);
                AppContext.stage.removeEventListener(MouseEvent.MOUSE_UP, replaySpeedButtomUpEvent);

                // 창 비활성화로 불린 경우도 여기서 재개 (시크바 드래그의 onSeekbarMouseUp과 같은 조건)
                if (wasReplayRunning && !ReplayState.isReplayFinished)
                {
                    startReplay();
                }
            }

            function replaySpeedButtomMoveEvent(e:MouseEvent):void
            {
                moveReplaySpeedSliderButton(UIController.topBar.replaySpeedSliderWrapper.mouseX);
            }

            isReplaySpeedDragging = true;
            Mouse.hide();
            moveReplaySpeedSliderButton(UIController.topBar.replaySpeedSliderWrapper.mouseX);
            setReplaySpeedBySliderX(UIController.topBar.replaySpeedSliderWrapper.mouseX);
            updateReplayPrograssText();
            AppContext.stage.addEventListener(MouseEvent.MOUSE_MOVE, replaySpeedButtomMoveEvent);
            AppContext.stage.addEventListener(MouseEvent.MOUSE_UP, replaySpeedButtomUpEvent, false, InputPriority.DEFAULT);
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
            const trackBarWidth:Number = UIController.seekBarBox.trackBar.width;
            if (!isReplaySpeedDragging)
            {
                UIController.seekBarBox.prograssInfo.text = nowFrame + " / " + totalFrame;
            }
            UIController.seekBarBox.prograssBar.width = (totalFrame === 0) ? 0 : trackBarWidth * ReplayClock.getSeekbarRatioOfFrame(nowFrame);
        }

        public static function updateReplayTimeBarFromDrawMode():void
        {
            updateReplayPrograssText(true, ReplayState.rNowFrame);

            if (ReplayState.isZeroReplayFrame())
            {
                UIController.seekBarBox.resetReplayPrograssBarWidth();
            }
            else
            {
                UIController.seekBarBox.updateReplayPrograssBarWidthByNowFame(ReplayClock.getSeekbarRatioOfFrame(ReplayState.rNowFrame));
            }
        }

        public static function cancelReplayRestartTimer():void
        {
            UIController.seekBarBox.setPlayButtonVisible(true);
            hideCompleteImageToBGReplayMode();
            FOFOTimer.remove("replayRestartTimer");
            updateReplayPrograssText(true, ReplayState.TOTAL_FRAME);
            Utils.setColorTransform(UIController.seekBarBox.prograssBar, UITheme.getUIReplayEndBarColor());
        }

        public static function startReplayRestartTimer():void
        {
            isRestartPending = false;

            if (ReplayState.isReplayRepeatON)
            {
                Utils.setColorTransform(UIController.seekBarBox.prograssBar, UITheme.getUIReplayRestartBarColor());
                rReplayRestartTimerCount = 20;
                // 끝나는 틱에서 자동 숨김 타이머가 재시작 타이머보다 먼저 돌면 "멈췄고 재시작도 없음"으로 보고 스스로 끝나므로, 재시작 대기 동안 다시 살림
                if (!FOFOTimer.hasTimer("checkAutoHideTopbarOnPlaybackTimer"))
                {
                    startCheckAutoHideTopbarOnPlaybackTimer();
                }

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
                            UIController.seekBarBox.prograssInfo.text = HintStrings.getReplayRestartHintString(rReplayRestartTimerCount);
                        }
                        --rReplayRestartTimerCount;
                        return true;
                    });
            }
            else
            {
                Utils.setColorTransform(UIController.seekBarBox.prograssBar, UITheme.getUIReplayEndBarColor());
                rReplayRestartTimerCount = 0;
                //todo updateReplayPrograssText로 replay finished 표시해주고 잘 모르겠음 ai한테 물어봐야겠음
                updateReplayPrograssText(true, ReplayState.TOTAL_FRAME);
            }
        }

        public static function toggleReplayRepeat():void
        {
            ReplayState.isReplayRepeatON = !ReplayState.isReplayRepeatON;

            if (ReplayState.isReplayRepeatON)
            {
                if(ReplayState.isReplayFinished && !ReplayState.isReplayRestartTimerON)
                {
                    ReplayController.startReplayRestartTimer();
                }
                UIController.topBar.replayRepeatButton.alpha = 1.0;
            }
            else
            {
                if(ReplayState.isReplayFinished && ReplayState.isReplayRestartTimerON)
                {
                    ReplayController.cancelReplayRestartTimer();
                }
                UIController.topBar.replayRepeatButton.alpha = UITheme.OFFALPHA;
            }
        }

        // 재생 중 마우스가 숨겨지면 상단바를 숨기고, 숨겨진 상태에서 커서가 상단바+시크바 높이 안으로 오면 다시 보여줌
        // STAGE_TOP_OFFSET은 상단바를 숨기면 줄어들므로 꺼내는 영역은 따로 계산함. 메시지 상자 위에서는 꺼내지 않음 (꺼내면 메시지가 아래로 밀려 커서 밑에서 빠져나감)
        public static function checkAutoHideTopbarOnPlayback():void
        {
            if(ReplayMouseAutoHide.isMouseHidden)
            {
                hideTopbarOnPlayback();
            }
            else if(UIController.topBar.visible === false)
            {
                const mx:Number = AppContext.stage.mouseX;
                const my:Number = AppContext.stage.mouseY;
                const topbarRevealAreaBottom:Number = (UIController.topBar.BARSIZE + UIController.seekBarBox.BARSIZE) * UITheme.getUIScale();
                if(my <= topbarRevealAreaBottom && !MessageBoxController.isMessageBoxClickAreaAt(mx, my))
                {
                    showTopbarOnPlayback();
                }
            }
        }

        // 상단바를 숨기고 시크바를 맨 위로 올림. 위쪽 여백(STAGE_TOP_OFFSET)과 메시지 위치도 다시 맞추고, 창 맞춤 중이면 캔버스도 다시 맞춤
        public static function hideTopbarOnPlayback():void
        {
            if (UIController.topBar.visible === true)
            {
                UIController.seekBarBox.y = 0;
                UIController.seekBarBox.hideReplayControlButton();
                UIController.topBar.visible = false;
                UIController.updateStageOffset();
                refitReplayCanvasAfterTopbarToggle();
                HintController.hideBottomHint();
                HintController.hideMouseHint();
            }
        }

        // 상단바를 다시 보이고 시크바를 원래 y로 내림. 위쪽 여백(STAGE_TOP_OFFSET)과 메시지 위치도 다시 맞추고, 창 맞춤 중이면 캔버스도 다시 맞춤
        public static function showTopbarOnPlayback():void
        {
            if (UIController.topBar.visible === false)
            {
                UIController.topBar.visible = true;
                UIController.seekBarBox.y = lastReplayTimeBoxYPos;
                UIController.seekBarBox.showReplayControlButton();
                UIController.updateStageOffset();
                refitReplayCanvasAfterTopbarToggle();
                HintController.hideBottomHint();
                HintController.hideMouseHint();
            }
        }

        // 상단바가 숨거나 나타나 위쪽 여백이 바뀌었을 때, 리플레이 캔버스가 창 맞춤 중이면 바뀐 여백에 다시 맞춤
        // 리플레이 모드를 나갔거나 캡처 모드로 들어가며 상단바를 꺼낸 경우는 제외 (캡처는 자기 맞춤을 따로 함)
        private static function refitReplayCanvasAfterTopbarToggle():void
        {
            if (ReplayState.isReplayModeON && !CaptureController.isCaptureModeON && ReplayState.isReplayCanvasFitToWindow)
            {
                fitReplayCanvasToViewport();
            }
        }

        public static function handleReplayStopButton():void
        {
            stopReplay();
        }

        public static function stopReplay(keepTopbarHidden:Boolean = false):void
        {
            // 재생 중이었다면 멈춘 시각을 기억해서 다시 재생할때 같은 곳에서 이어감 (쉬는 구간 처음부터 다시 세지 않게)
            if (ReplayState.isReplayStarted && ReplayState.rNowFrame < ReplayState.TOTAL_FRAME)
            {
                ReplayClock.savePausedPosition(ReplayState.rNowFrame, ReplayClock.readRecordedTimeNow());
            }

            FOFOTimer.remove("replayDrawTimer");
            ReplayDrawer.anim.clearAnimOverlay();
            ReplayController.clearReplayWaitingState();

            if (!keepTopbarHidden)
            {
                ReplayController.showTopbarOnPlayback();
            }

            if (!ReplayState.isReplayFinished)
            {
                UIController.seekBarBox.setPlayButtonVisible(true);
            }

            ReplayDrawer.rFileStream.close();
            ReplayState.isReplayStarted = false;
            updateDeleteReplayDataButtonsState();
            ReplayDrawer.cursorFollow.moveCameraToCursorNow(); // 남은 이동을 애니메이션하지 않고 최종 위치와 배율로 바로 마무리
        }

        public static function handleReplayStartButton():void
        {
            if (!ReplayState.canStartReplay())
            {
                return;
            }

            // hideTopbarOnReplayStart();
            startReplay();
        }

        public static function startReplay():void
        {
            if (!ReplayState.canStartReplay())
            {
                return;
            }

            isRestartPending = false;
            ReplayState.isReplayStarted = true;
            UIController.seekBarBox.resetPrograssBarColor();
            UIController.seekBarBox.playButton.visible = false;
            UIController.seekBarBox.pauseButton.visible = true;
            ReplayDrawer.rReplayFOFOCursor.visible = true;
            updateDeleteReplayDataButtonsState();

            if (ReplayState.isReplayFinished === true) // 리플레이 시간 등등 초기화 시키고 시작
            {
                UIController.seekBarBox.resetReplayPrograssBarWidth();
                resetReplayTime();
                ReplayDrawer.clearCanvasReplayMode();
                ReplayDrawer.drawFirstJumpImage();
                ReplayState.rMemoryDataReadON = false;
                ReplayState.isReplayFinished = false; // resetReplayTime함수 에서 이걸 true로 해주기 때문에 아래쪽에서 변경
                ReplayDrawer.cursorFollow.resyncCameraWithAnchor();
                ReplayDrawer.selectReplaySubLayer(false);
            }

            if (!ReplayState.rMemoryDataReadON)
            {
                ReplayDrawer.rFileStream.open(AppDataPaths.replayDataFilePath, FileMode.READ);
                ReplayDrawer.rFileStream.position = ReplayState.rFileLastBytePosition;
            }

            if (ReplayState.isReplayCanvasFitToWindow)
            {
                fitReplayCanvasToViewport();
            }

            if (ReplayState.rNowFrame === 0)
            {
                ReplayDrawer.cursorFollow.holdOverviewAfterReplayStart(); // 처음부터 재생하면 잠시 전체를 보여준 뒤 집중 영역으로 들어감
            }

            ReplayFileCache.clearRFrameTempCache();
            ReplayClock.startClockAtFrame(ReplayState.rNowFrame, ReplayState.getReplayClockSpeed());
            ReplayMouseAutoHide.startMouseHideTimer();
            startReplayDrawTimer();
            startCheckAutoHideTopbarOnPlaybackTimer();
            startUpdatingPrograssBarTimer();
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
            ReplayDrawer.commandWindow.disposeQueuedCommandGroups();
            removeReplayAutoSkipFadeBitmap();
            ReplayState.isReplayModeON = false;
            ReplayDrawer.rCanvasAnchorPoint.visible = false;
            ReplayDrawer.rReplayFOFOCursor.visible = false;
            UIController.seekBarBox.visible = false;
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
            ReplayDrawer.setReplayCursorRotation(CanvasView.canvasAnchorPoint.rotation);

            if (HintController.mouseHint.isShowing())
            {
                HintController.hideMouseHint();
            }

            if (HintController.isHighlightBoxVisible())
            {
                HintController.hideBottomHint();
            }

            UIController.seekBarBox.pauseButton.visible = false;
            Utils.setAsTopChild(UIController.seekBarBox);
            UIController.seekBarBox.setDeleteRangeBarVisible(false);
            UIController.updateStageOffset();
            CanvasNavigator.updateCursor();

            if (PenSettings.isTransparentPenColor)
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
            ReplayDrawer.commandWindow.disposeQueuedCommandGroups(); // 앞에서 읽어 둔 것이 있어도 이번 모드에서는 새로 읽음
            ReplayState.isReplayModeON = true;
            CanvasView.canvasAnchorPoint.visible = false;
            ReplayDrawer.rCanvasAnchorPoint.visible = true;
            UIController.seekBarBox.visible = true;
            PenSizePreviewCursor.setCursorInVisibleFlag(true);
            PenSizePreviewCursor.setVisible(false);
            ToolPanel.selectedToolViewSprite.visible = false;
            UIController.seekBarBox.pauseButton.visible = false;
            UIController.seekBarBox.y = Math.floor(UIController.topBar.BARSIZE * UITheme.getUIScale() - 4);
            lastReplayTimeBoxYPos = UIController.seekBarBox.y;
            Utils.setAsTopChild(UIController.seekBarBox);
            UIController.seekBarBox.setDeleteRangeBarVisible(false);
            UITheme.applyToolBoxButtonOverBGColor(UIController.seekBarBox.prograssBar);

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
            ReplayDrawer.setReplayCursorRotation(ReplayDrawer.rCanvasAnchorPoint.rotation);
            UIController.updateStageOffset();
            FOFOTimer.remove("rCursorOffAlphaAnimTimer");
            HintController.hideBottomHint();
            UndoController.suspendDeepUndo();
            frameOnEnterReplayMode = ReplayState.rNowFrame;
            updateTotalFrameAndReplayMaxSpeed(ReplayState.getTotalFrame()); // 최대 속도 계산
            updateReplayPrograssBarAndText();
            updateReplaySpeedSliderAlpha();
            UIController.seekBarBox.updatePos(AppContext.stage.stageWidth);
            ReplayDrawer.cursorFollow.resyncCameraWithAnchor();
            ReplayDrawer.updateReplayCursorScale(ReplayState.rCanvasZoomMultiplier);

            if (ReferenceLayerController.isRefLayerMenuON === true)
            {
                ReferenceLayerController.refLayerMenuBox.visible = false;
            }

            if (ReplayState.rReplayImageCacheState === ReplayState.REPLAY_IMAGE_CAHCHE_COMPLETE)
            {
                ReplayState.rMemoryDataReadON = false;
                updateReplayTimeBarFromDrawMode();
                ReplayDrawer.viewport.centerCanvasInStage("replay");

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
                ReplayDrawer.viewport.keepCanvasInStage();
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
            ReplayState.rCanvasZoomIndex = CanvasView.canvasZoomMultiplierList.indexOf(1.0);
            ReplayDrawer.viewport.moveAnchorPoint(center.x, center.y);
            ReplayDrawer.viewport.setCanvasScale(1.0);
            setFitReplayCanvasToViewportOFF();
            ReplayDrawer.cursorFollow.resyncCameraWithAnchor();
        }

        private static function copyReplayCanvasDataToDrawCanvas():void
        {
            const lineStyleSave:Array = ReplayDrawCommands.getRLineStyleSave();
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
            CanvasView.canvasZoomIndex = CanvasView.getNearZoomIndex(ReplayState.rCanvasZoomMultiplier); // 리플레이 자동 줌 배율은 단계 값이 아니라서 가까운 단계로 맞춤
            CanvasView.canvasAnchorPoint.x = Math.floor(ReplayDrawer.rCanvasAnchorPoint.x); // 뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
            CanvasView.canvasAnchorPoint.y = Math.floor(ReplayDrawer.rCanvasAnchorPoint.y);
            CanvasView.canvasAnchorPoint.scaleX = ReplayDrawer.rCanvasAnchorPoint.scaleX;
            CanvasView.canvasAnchorPoint.scaleY = ReplayDrawer.rCanvasAnchorPoint.scaleY;
            CanvasView.canvasAnchorPoint.rotation = ReplayDrawer.rCanvasAnchorPoint.rotation;
            CanvasView.canvasPanel.x = Math.floor(ReplayDrawer.rCanvasPanel.x);
            CanvasView.canvasPanel.y = Math.floor(ReplayDrawer.rCanvasPanel.y);
            ReplayDrawer.setReplayCursorRotation(ReplayDrawer.rCanvasAnchorPoint.rotation);
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
            rCanvasCompleteAnchorPoint.width = AppContext.stage.stageWidth + 200;
            rCanvasCompleteAnchorPoint.height = AppContext.stage.stageHeight + 200;
            rCanvasCompleteAnchorPoint.x = AppContext.stage.stageWidth / 2;
            rCanvasCompleteAnchorPoint.y = AppContext.stage.stageHeight / 2;
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

        // 창 맞춤을 켜고 끔. 끌 때는 지금 화면(맞춤 배율)에서 리플레이 카메라가 이어받음
        public static function toggleFitToCanvasReplayMode():void
        {
            if (ReplayState.isReplayCanvasFitToWindow)
            {
                setFitReplayCanvasToViewportOFF();
                ReplayDrawer.cursorFollow.moveCameraToCursorNow();
            }
            else
            {
                setFitReplayCanvasToViewportON();
            }
        }

        public static function resetRotationReplayMode():void
        {
            const center:Point = UIController.getStageCenterPos("replay");
            ReplayDrawer.viewport.moveAnchorPoint(center.x, center.y);
            ReplayDrawer.rCanvasAnchorPoint.rotation = 0;
            ReplayDrawer.setReplayCursorRotation(0);
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
            UIController.seekBarBox.name = "seekBarBox";
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
            AppContext.stage.addChild(ReplayDrawer.rCanvasAnchorPoint);
            AppContext.stage.addChild(UIController.seekBarBox);
            UIController.seekBarBox.x = 0;
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
            ReplayDrawer.setReplayCursorRotation(CanvasView.canvasAnchorPoint.rotation);
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
            ReplayDrawer.setReplayCursorRotation(ReplayDrawer.rCanvasAnchorPoint.rotation);
        }

        public static function setFitReplayCanvasToViewportOFF():void
        {
            ReplayState.isReplayCanvasFitToWindow = false;
            UIController.topBar.replayFitToWindowButton.alpha = UITheme.OFFALPHA;
        }

        public static function setFitReplayCanvasToViewportON():void
        {
            ReplayState.isReplayCanvasFitToWindow = true;
            UIController.topBar.replayFitToWindowButton.alpha = 1.0;
            fitReplayCanvasToViewport();
        }

        // 리플레이 캔버스를 창에 맞춤. 배율은 연속값 그대로 둠 (단계 값으로 바꾸면 화면 배율과 rCanvasZoomMultiplier가 어긋나 맞춤을 끈 뒤 카메라 계산이 틀어짐)
        public static function fitReplayCanvasToViewport():void
        {
            FOFOTimer.addByName("rFitZoomedDelayTimer", 0.15, false, function ():void
                {
                    CanvasViewport.getCurrentVisibleViewport().fitToViewportMargin(true);
                    ReplayState.rCanvasZoomIndex = CanvasView.getNearZoomIndex(ReplayState.rCanvasZoomMultiplier);
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

        public static function clearReplayDataAndResetVars():void
        {
            FileManager.isContinueSaveON = false;
            ReplayState.rMirrorON = false;
            DrawCanvas.mirrorON = false;
            ReplayState.rMemoryDataReadON = false;
            ReplayState.mirrorCommandReady = false;
            ReplayState.setRFileDataTotalFrame(0);
            ReplayClock.rebuildFileIndex();
            updateTotalFrameAndReplayMaxSpeed(0);
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
            KeyState.removeKeyRepeatEvents(null);
        }

        private static function replayCompleteEffect():void
        {
            CanvasViewport.getCurrentVisibleViewport().fitToViewportMargin(true); // 창 맞춤을 꺼도 카메라의 최소 배율이 맞춤 배율이라 끝날 때도 100%를 넘겨 맞춤
            CanvasView.applyCanvasFlashEffect(ReplayDrawer.rCanvasPanel, 0, 0, ReplayState.RCANVAS_WIDTH, ReplayState.RCANVAS_HEIGHT, function ():Boolean
                {
                    return !ReplayState.isReplayModeON;
                });
        }

        public static function getReplayRemainingTimeString(speed:Number, totalFrame:Number):String
        {
            // totalFrame은 남은 프레임 수, 시계에서 그 지점부터 끝까지의 녹화 시간을 배속으로 나눠 실제 남은 시간을 구함
            // 지금 위치의 남은 시간은 마지막으로 그린 프레임이 아니라 시계 시각 기준 (쉬는 구간을 기다리는 동안에도 줄어들도록)
            const fromFrame:Number = ReplayState.TOTAL_FRAME - totalFrame;
            const fromRecorded:Number = (fromFrame === ReplayState.rNowFrame) ? ReplayClock.getRecordedTimeForDisplay(fromFrame, ReplayState.isReplayStarted) : ReplayClock.getRecordedTimeOfFrame(fromFrame - 1);
            const totalSec:Number = ReplayClock.getRemainingRealMsAtRecorded(fromRecorded, speed) / 1000;

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
