package
{
    import Modules.DrawEngine.CanvasResizer;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;
    import flash.events.Event;
    import Modules.AppStateManager;
    import Modules.InputManager.InputManager;
    import Modules.InputManager.DrawModeInput;
    import Modules.InputManager.ReplayModeInput;
    import Modules.InputManager.CaptureModeInput;
    import Modules.ImeController;
    import Modules.MouseState;
    import Modules.ClipboardManager;
    import Modules.AboutBoxController;
    import Modules.Tools.ToolController;
    import Modules.Tools.FillPenTool;
    import Modules.SidebarController;
    import flash.utils.getTimer;
    import Modules.BackgroundWorkerCoordinator;
    import Modules.FileManager;
    import Modules.AppUpdater;
    import Modules.ReplayEngine.ReplayState;
    import Modules.UndoController;
    import Modules.ColorPickerController;
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
            if (ToolController.isToolBox2Showing)
            {
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
                ReplayFileCache.saveCachePreview(FileManager.loadMenuBox.getPreviewImage());
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

        public static function updateWindowTitle():void
        {
            main.stage.nativeWindow.title = FileManager.lastSaveFileName + main.STRING_TITLE_FOFOPAINT;
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
            FileManager.deleteTempDirectory();
            FileManager.saveAllAppData();
            main.stage.nativeWindow.close();
        }
    }
}
