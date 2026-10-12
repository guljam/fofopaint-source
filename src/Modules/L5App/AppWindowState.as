package Modules.L5App
{
    import Modules.L1Data.AppContext;
    import flash.events.Event;
    import flash.utils.getTimer;
    import flash.geom.Rectangle;
    import flash.display.NativeWindowDisplayState;
    import Modules.L5App.InputManager.CaptureModeInput;
    import Modules.L4UI.ColorPickerController;
    import Modules.L5App.InputManager.DrawModeInput;
    import Modules.L4UI.ImageViewWindow;
    import Modules.L5App.InputManager.InputManager;
    import Modules.L5App.ReplayEngine.ReplayController;
    import Modules.L5App.InputManager.ReplayModeInput;
    import Modules.L4UI.SidebarController;
    import Modules.L4UI.Tools.ToolPanel;
    import Modules.L1Data.KeyState;
    import Modules.L4UI.AboutBoxController;
    import Modules.L2Engine.BackgroundWorkerCoordinator;
    import Modules.L2Engine.ReplayEngine.ReplayFileCache;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L1Data.AppDataPaths;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L4UI.DrawEngine.CanvasResizer;
    import Modules.L2Engine.ReplayEngine.ReplayState;
    import Modules.L1Data.MouseState;
    import Modules.L2Engine.UndoHistory;
    import Modules.L4UI.Tools.FillPenTool;
    import Modules.L4UI.Tools.LassoTool;
    import Modules.L4UI.Tools.ToolController;
    import Modules.L4UI.CaptureEngine.CaptureController;
    import Modules.L4UI.ActivityWorkTimer;
    import Modules.L4UI.ImeController;
    import Modules.L1Data.Utils;
    import Modules.L1Data.FOFOTimer;
    import Modules.L1Data.NativeSave;

    // 층: L5 앱 흐름 - 창 크기, 활성화, 닫기 처리와 창 제목 갱신
    public class AppWindowState
    {
        // 윈도우 비활성화된 시간 저장, 알탭 반복 시 save all data 과다 호출 방지
        public static var lastWindowDeactivateTime:int = 0;
                // 앱종료할때 올려줌 창 최대화 되어있는 상태를 원래대로 하고 window resize이벤트에서 마지막에 종료 호출
        public static var isAppClosing:Boolean = false;
        public static var lastAppWindowState:int = 0;
        public static var lastNormalWindowBounds:Rectangle = null; // 최소화되지 않은 상태에서 마지막으로 저장한 창 사각형 (최소화 중 저장할 때 대신 씀)

        // 종료 저장/close가 이미 시작됐는지 (종료 직전 applyLayout이 여러 경로로 중복 호출되는 것 방지)
        public static var isCloseRequested:Boolean = false;
        
        public static function onWindowResize(e:Event):void
        {
            if (AppDataPaths.isLoadingAppData)
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
            KeyState.clearKeyBuffer();
            KeyState.removeKeyRepeatEvents(null);
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
                    && !UIController.isFileBrowserOpened
                    && !LoadBoxController.isLoadPendingAfterSaving
                    && !UIController.loadMenuBox.visible
                    && !ReplayState.isGeneratingCacheImages())
            {
                AppStateManager.saveAllAppData();
            }

            if (SidebarController.isQuickSidebarActive && !UndoHistory.isDeepUndoEnabled)
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
            AppContext.stage.nativeWindow.removeEventListener(Event.DEACTIVATE, AppWindowState.onWindowDeactivate);
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
                ReplayFileCache.saveCachePreview(UIController.loadMenuBox.getPreviewImage());
            }

            // worker와 네이티브 저장이 끝날때까지 기다린 뒤 종료 (네이티브 저장은 최대 NATIVE_SAVE_EXIT_WAIT초, 넘으면 로그를 남기고 종료)
            if (BackgroundWorkerCoordinator.isWorkerBusy() || NativeSave.isBusy)
            {
                const waitStart:int = getTimer();

                if (!FOFOTimer.hasTimer("pollTimerWaitWorkerStop"))
                {
                    AppContext.stage.nativeWindow.title = "Waiting for remaining tasks...";
                    LoadBoxController.openLoadMenuBoxOnClosing();
                    FOFOTimer.addByName("pollTimerWaitWorkerStop", BackgroundWorkerCoordinator.getWaitPollingInterval(), true, function ():Boolean
                        {
                            const nativeTimedOut:Boolean = NativeSave.isBusy && getTimer() - waitStart > NATIVE_SAVE_EXIT_WAIT * 1000;

                            if (nativeTimedOut)
                            {
                                AppDataPaths.writeCrashLog("Exit while native save still running");
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
            AppContext.stage.nativeWindow.title = FileManager.stripExtension(FileManager.lastSaveFileName) + AppContext.titleString;
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.copyMainWindowTitleToCanvasWindow();
            }
        }

        public static function markWindowTitleAsDirty():void
        {
            const titleEndStr:int = AppContext.stage.nativeWindow.title.lastIndexOf(AppContext.titleString);

            if (titleEndStr > 0 && AppContext.stage.nativeWindow.title.charAt(titleEndStr - 1) !== "*")
            {
                const starFileName:String = AppContext.stage.nativeWindow.title.slice(0, titleEndStr) + "*";
                AppContext.stage.nativeWindow.title = starFileName + AppContext.titleString;

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
            AppContext.stage.nativeWindow.close();
        }
    }
}
