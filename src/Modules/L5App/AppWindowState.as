package Modules.L5App
{
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;
    import flash.events.Event;
    import Modules.AppStateManager;
    import Modules.MouseState;
    import Modules.ClipboardManager;
    import Modules.AboutBoxController;
    import flash.utils.getTimer;
    import Modules.BackgroundWorkerCoordinator;
    import Modules.NativeSave;
    import Modules.ReplayEngine.ReplayState;
    import Modules.CaptureEngine.CaptureController;
    import Modules.ReplayEngine.ReplayFileCache;
    import flash.geom.Rectangle;
    import flash.display.Screen;
    import flash.display.NativeWindowDisplayState;
    import Modules.L3Feature.ActivityWorkTimer;
    import Modules.L2Engine.DrawEngine.CanvasResizer;
    import Modules.L5App.InputManager.CaptureModeInput;
    import Modules.L4UI.ColorPickerController;
    import Modules.L5App.InputManager.DrawModeInput;
    import Modules.L3Feature.Tools.FillPenTool;
    import Modules.L4UI.ImageViewWindow;
    import Modules.L3Feature.ImeController;
    import Modules.L5App.InputManager.InputManager;
    import Modules.L3Feature.Tools.LassoTool;
    import Modules.L4UI.LoadBoxController;
    import Modules.L5App.ReplayEngine.ReplayController;
    import Modules.L5App.InputManager.ReplayModeInput;
    import Modules.L4UI.SidebarController;
    import Modules.L3Feature.Tools.ToolController;
    import Modules.L4UI.Tools.ToolPanel;
    import Modules.L3Feature.UndoController;

    // 층: L5 앱 흐름 - 창 크기, 활성화, 닫기 처리와 창 제목 갱신
    public class AppWindowState
    {
                public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        // 윈도우 비활성화된 시간 저장, 알탭 반복 시 save all data 과다 호출 방지
        public static var lastWindowDeactivateTime:int = 0;
                // 앱종료할때 올려줌 창 최대화 되어있는 상태를 원래대로 하고 window resize이벤트에서 마지막에 종료 호출
        public static var isAppClosing:Boolean = false;
        public static var lastAppWindowSize:Rectangle = new Rectangle();// 창크기 조절 얼마나 됐을지 비교할때 마지막 크기 창크기 저장
        public static var lastAppWindowState:int = 0;
        public static var lastNormalWindowBounds:Rectangle = null; // 최소화되지 않은 상태에서 마지막으로 저장한 창 사각형 (최소화 중 저장할 때 대신 씀)

        private static const TITLE_CHECK_HEIGHT:Number = 30; // 창 위쪽 이 높이만큼을 제목 표시줄로 보고 화면에 보이는지 검사함
        private static const MIN_VISIBLE_TITLE_WIDTH:Number = 100; // 제목 표시줄이 이 너비 이상 보여야 마우스로 잡아 옮길 수 있다고 봄
        private static const MIN_VISIBLE_TITLE_HEIGHT:Number = 10;

        // 종료 저장/close가 이미 시작됐는지 (종료 직전 applyLayout이 여러 경로로 중복 호출되는 것 방지)
        public static var isCloseRequested:Boolean = false;
        
        // 저장된 창 사각형이 지금 연결된 모니터 어디에도 제대로 보이지 않으면(주 모니터 변경, 모니터 분리, 최소화 좌표 등)
        // 주 모니터 작업 영역 가운데로 옮긴 사각형을 돌려줌. 보이면 그대로 돌려줌
        // 크기가 주 모니터 작업 영역보다 크면 줄임. 크기가 없거나 NaN이면 defaultWidth/defaultHeight를 씀
        public static function getVisibleWindowBounds(saved:Rectangle, defaultWidth:Number, defaultHeight:Number):Rectangle
        {
            const width:Number = (isNaN(saved.width) || saved.width <= 0) ? defaultWidth : saved.width;
            const height:Number = (isNaN(saved.height) || saved.height <= 0) ? defaultHeight : saved.height;

            if (!isNaN(saved.x) && !isNaN(saved.y))
            {
                const title:Rectangle = new Rectangle(saved.x, saved.y, width, TITLE_CHECK_HEIGHT);

                for each (var screen:Screen in Screen.screens)
                {
                    const visible:Rectangle = title.intersection(screen.visibleBounds);

                    if (visible.width >= MIN_VISIBLE_TITLE_WIDTH && visible.height >= MIN_VISIBLE_TITLE_HEIGHT)
                    {
                        return new Rectangle(saved.x, saved.y, width, height);
                    }
                }
            }

            const vb:Rectangle = Screen.mainScreen.visibleBounds;
            const w:Number = Math.min(width, vb.width);
            const h:Number = Math.min(height, vb.height);
            return new Rectangle(Math.round(vb.x + (vb.width - w) / 2), Math.round(vb.y + (vb.height - h) / 2), w, h);
        }

        public static function onWindowResize(e:Event):void
        {
            if (AppStateManager.isLoadingAppData)
            {
                return;
            }

            FOFOTimer.addByName("windowResizeDelayTimer", 0.2, false, UIController.applyLayout);
        }

        public static function onWindowActive(e:Event):void
        {
            ImeController.onWindowActivate();
            ClipboardManager.checkCanUseClipBoardButton();

            if (AboutBoxController.isAboutBoxOpened)
            {
                MouseState.isClickBlocked = true;
            }
            else
            {
                InputManager.unblockMouseClickAfterDelay();
            }
        }

        public static function onWindowDeactivate(e:Event):void
        {
            MouseState.isClickBlocked = true;
            ImeController.onWindowDeactivate();
            FillPenTool.hideFillPenMenuBox();
            MouseState.finishAllDrags(); // 그리는 도중 포커스를 잃으면 mouseUp이 안오므로 획 등을 정상 종료함
            MouseState.resetAll();
            DrawModeInput.isKeyReleasedBeforeMouseUp = false;
            CanvasResizer.exit();
            InputManager.clearKeyBuffer();
            InputManager.removeKeyRepeatEvents(null);
            FOFOTimer.remove("pressholdtimer");
            if (ToolPanel.isToolBox2Showing)
            {
                ToolPanel.closeToolBox2();
            }
            if (!SidebarController.isSidebarVisible)
            {
                SidebarController.startHidingSidebarTemporary();
            }
            if (getTimer() - lastWindowDeactivateTime >= 3000
                    && !BackgroundWorkerCoordinator.isSaveInProgress
                    && !FileManager.isFileBrowserOpened
                    && !LoadBoxController.isLoadPendingAfterSaving
                    && !LoadBoxController.loadMenuBox.visible
                    && !ReplayState.isGeneratingCacheImages())
            {
                AppStateManager.saveAllAppData();
            }

            if (SidebarController.isQuickSidebarActive && !UndoController.isDeepUndoEnabled)
            {
                SidebarController.deactivateQuickSidebar();
            }
            if (ColorPickerController.numPadBox.visible)
            {
                ColorPickerController.closeNumpad();
            }
            if (ColorPickerController.numPadBox.isLCHSliderActive())
            {
                ColorPickerController.numPadBox.removeOKLCHMouseEvent();
            }
            if (ColorPickerController.colorPickerBox.scratchPad.isScratchStarted)
            {
                ColorPickerController.colorPickerBox.scratchPad.removeCheckMouseDistEvent();
            }
            HintController.hideBottomHint();
            ToolController.selectLastUsedTool();
            lastWindowDeactivateTime = getTimer();
        }

        private static const NATIVE_SAVE_EXIT_WAIT:int = 120;

        public static function onWindowClosingEvent(e:Event):void
        {
            isAppClosing = true;
            e.preventDefault();
            main.stage.nativeWindow.removeEventListener(Event.DEACTIVATE, AppWindowState.onWindowDeactivate);
            CaptureModeInput.removeEvents();
            DrawModeInput.removeEvents();
            ReplayModeInput.removeEvents();
            ActivityWorkTimer.stop();

            if (ImageViewWindow.canvasWindow !== null)
            {
                ImageViewWindow.canvasWindow.visible = false;
            }

            if (CaptureController.isCaptureModeON === true)
            {
                CaptureController.handleExitCaptureMode();
            }

            if (ReplayState.isReplayStarted === true)
            {
                ReplayController.stopReplay();
            }

            if (LassoTool.isStarted)
            {
                LassoTool.cancelLassoTool();
            }

            // 캐시 이미지 만드는 중이면 멈춰야 앱이 종료됨 (다음 실행때 이어서 만듬)
            // 이어 만들때 다시 깔아주도록 지금 로드박스 배경 이미지도 저장
            if (ReplayState.isGeneratingCacheImages())
            {
                ReplayController.stopGeneratingReplayCacheImage();
                ReplayFileCache.saveCachePreview(LoadBoxController.loadMenuBox.getPreviewImage());
            }

            // worker와 네이티브 저장이 끝날때까지 기다린 뒤 종료 (네이티브 저장은 최대 NATIVE_SAVE_EXIT_WAIT초, 넘으면 로그를 남기고 종료)
            if (BackgroundWorkerCoordinator.isWorkerBusy() || NativeSave.isBusy)
            {
                const waitStart:int = getTimer();

                if (!FOFOTimer.hasTimer("pollTimerWaitWorkerStop"))
                {
                    main.stage.nativeWindow.title = "Waiting for remaining tasks...";
                    LoadBoxController.openLoadMenuBoxOnClosing();
                    FOFOTimer.addByName("pollTimerWaitWorkerStop", BackgroundWorkerCoordinator.getWaitPollingInterval(), true, function ():Boolean
                        {
                            const nativeTimedOut:Boolean = NativeSave.isBusy && getTimer() - waitStart > NATIVE_SAVE_EXIT_WAIT * 1000;

                            if (nativeTimedOut)
                            {
                                AppStateManager.writeCrashLog("Exit while native save still running");
                            }

                            if (BackgroundWorkerCoordinator.isWorkerStopped() && (!NativeSave.isBusy || nativeTimedOut))
                            {
                                FOFOTimer.remove("pollTimerWaitWorkerStop");
                                AppStateManager.checkWindowMaximizedAndSaveAllData();
                                return false;
                            }
                            return true;
                        });
                }
            }
            else
            {
                AppStateManager.checkWindowMaximizedAndSaveAllData();
            }
        }

        public static function updateWindowTitle():void
        {
            main.stage.nativeWindow.title = FileManager.stripExtension(FileManager.lastSaveFileName) + main.STRING_TITLE_FOFOPAINT;
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.copyMainWindowTitleToCanvasWindow();
            }
        }

        public static function markWindowTitleAsDirty():void
        {
            const titleEndStr:int = main.stage.nativeWindow.title.lastIndexOf(main.STRING_TITLE_FOFOPAINT);

            if (titleEndStr > 0 && main.stage.nativeWindow.title.charAt(titleEndStr - 1) !== "*")
            {
                const starFileName:String = main.stage.nativeWindow.title.slice(0, titleEndStr) + "*";
                main.stage.nativeWindow.title = starFileName + main.STRING_TITLE_FOFOPAINT;

                if (ImageViewWindow.isCanvasWindowON)
                {
                    ImageViewWindow.copyMainWindowTitleToCanvasWindow();
                }
            }
        }

        // 종료 대기 중이면 저장하고 창을 닫는다(마지막 종료 트리거).
        public static function closeAppIfPending():void
        {
            if (!isAppClosing || isCloseRequested)
            {
                return;
            }

            if (FOFOTimer.hasTimer("pollTimerWaitWorkerStop"))
            {
                return;
            }

            isCloseRequested = true;
            AppStateManager.deleteTempDirectory();
            AppStateManager.saveAllAppData();
            main.stage.nativeWindow.close();
        }
    }
}
