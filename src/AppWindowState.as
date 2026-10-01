package
{
    import flash.events.Event;
    import Modules.AppStateManager;
    import Modules.MainUIController;
    import Modules.InputManager;
    import Modules.ClipboardManager;
    import Modules.AboutBoxController;
    import Modules.CanvasController;
    import Modules.ToolController;
    import Modules.SidebarController;
    import flash.utils.getTimer;
    import Modules.BackgroundWorkerCoordinator;
    import Modules.FileManager;
    import Modules.AppUpdater;
    import Modules.ReplayEngine.ReplayState;
    import Modules.UndoManager;
    import Modules.ColorPickerController;
    import Modules.MainUI;
    import Modules.ActivityWorkTimer;
    import Modules.ImageViewWindow;
    import Modules.CaptureEngine.CaptureController;
    import Modules.ReplayEngine.ReplayController;
    import Modules.Tools.LassoTool;
    import Modules.ReplayEngine.ReplayFileCache;
    import flash.geom.Rectangle;

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

        // 종료 저장/close가 이미 시작됐는지 (종료 직전 applyLayout이 여러 경로로 중복 호출되는 것 방지)
        public static var isCloseRequested:Boolean = false;
        
        public static function onWindowResize(e:Event):void
        {
            if (AppStateManager.isLoadingAppData)
            {
                return;
            }

            FOFOTimer.addByName("windowResizeDelayTimer", 0.2, false, MainUIController.applyLayout);
        }

        public static function onWindowActive(e:Event):void
        {
            InputManager.tryDisableIME();
            ClipboardManager.checkCanUseClipBoardButton();

            if (AboutBoxController.isAboutBoxOpened)
            {
                CanvasController.isMouseClickBlocked = true;
            }
            else
            {
                InputManager.unblockMouseClickAfterDelay();
            }
        }

        public static function onWindowDeactivate(e:Event):void
        {
            CanvasController.isMouseClickBlocked = true;
            main.resizeCanvas.exit(true);
            InputManager.clearKeyBuffer();
            InputManager.removeKeyRepeatEvents(null);
            FOFOTimer.remove("pressholdtimer");
            ToolController.cancelOpacityDrag();
            if (ToolController.isToolBox2Showing)
            {
                CanvasController.isRightMouseClicked = false;
                ToolController.closeToolBox2();
            }
            if (!SidebarController.isSidebarVisible)
            {
                SidebarController.startHidingSidebarTemporary();
            }
            if (getTimer() - lastWindowDeactivateTime >= 3000
                    && !BackgroundWorkerCoordinator.isSaveInProgress
                    && !FileManager.isFileBrowserOpened
                    && !FileManager.isLoadPendingAfterSaving
                    && !AppUpdater.isUpdatePendingAfterSaving
                    && !FileManager.loadMenuBox.visible
                    && !ReplayState.isGeneratingCacheImages())
            {
                FileManager.saveAllAppData();
            }

            if (SidebarController.isQuickSidebarActive && !UndoManager.isDeepUndoEnabled)
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
            MainUI.hideBottomHint();
            ToolController.selectLastUsedTool();
            lastWindowDeactivateTime = getTimer();
        }

        public static function onWindowClosingEvent(e:Event):void
        {
            var loadMenuBox:Object;
            isAppClosing = true;
            e.preventDefault();
            main.stage.nativeWindow.removeEventListener(Event.DEACTIVATE, AppWindowState.onWindowDeactivate);
            InputManager.removeInputEventCaptrueMode();
            InputManager.removeInputEventsDrawMode();
            InputManager.removeInputEventsReplayMode();
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
                ReplayFileCache.saveCachePreview(loadMenuBox.getPreviewImage());
            }

            if (BackgroundWorkerCoordinator.isWorkerBusy())
            {
                if (!FOFOTimer.hasTimer("pollTimerWaitWorkerStop"))
                {
                    main.stage.nativeWindow.title = "Waiting for remaining tasks...";
                    FileManager.openLoadMenuBoxOnClosing();
                    FOFOTimer.addByName("pollTimerWaitWorkerStop", BackgroundWorkerCoordinator.getWaitPollingInterval(), true, function ():Boolean
                        {
                            if (BackgroundWorkerCoordinator.isWorkerStopped())
                            {
                                FOFOTimer.remove("pollTimerWaitWorkerStop");
                                FileManager.checkWindowMaximizedAndSaveAllData();
                                return false;
                            }
                            return true;
                        });
                }
            }
            else
            {
                FileManager.checkWindowMaximizedAndSaveAllData();
            }
        }
    }
}
