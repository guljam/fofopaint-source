package
{
    import Modules.DrawEngine.CanvasView;
    import Modules.DrawEngine.DrawCanvas;
    import Modules.UIEngine.CanvasNavigator;
    import Modules.DrawEngine.CanvasResizer;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;
    import Modules.InputPriority;
    import Modules.MouseState;
    import Modules.ImeController;
    import Modules.AboutBoxController;
    import Modules.AppStateManager;
    import Modules.AppStateVars;
    import Modules.AppUpdater;
    import Modules.BackgroundWorkerCoordinator;
    import Modules.CanvasGridOverlay;
    import Modules.CaptureEngine.CaptureController;
    import Modules.ClipboardManager;
    import Modules.ColorPickerController;
    import Modules.DragInteraction;
    import Modules.FileManager;
    import Modules.Tools.FillPenTool;
    import Modules.ImageViewWindow;
    import Modules.InputManager.InputManager;
    import Modules.InputManager.DrawModeInput;
    import Modules.InputManager.CaptureModeInput;
    import Modules.InputManager.ReplayModeInput;
    import Modules.PaletteController;
    import Modules.ReferenceLayerController;
    import Modules.SidebarController;
    import Modules.ToolController;
    import Modules.Tools.EyeDropperTool;
    import Modules.Tools.HandTool;
    import Modules.Tools.LassoTool;
    import Modules.Tools.LineTool;
    import Modules.Tools.MoveTool;
    import Modules.Tools.PenTool;
    import Modules.Tools.RotateTool;
    import Modules.Tools.ZoomTool;
    import Modules.Utils;

    // todo 힌트박스 컨트롤러 만들기, 지금 각툴에 힌트 관련 마우스 이벤트가 있음 이것을 전부 옮기기 mainui도아마 개편해야할듯싶음 힌트관련 메뉴가 많음
    // todo if(켜졌으면) 꺼주기 형식 각 클래스마다 비슷한거 있는데 gpt한테 물어봐서 정리한다음 메서드 하나로 한줄로 호출되도록 바꾸기
    // todo 함수 중복 처리되는거 잘 관찰한후 내부 값만 변경 - 최종 갱신순으로 해야겠음, 너무 툴마다 따로따로 생각했던것같음
    import Symbols.HintBoxSet;

    import flash.desktop.NativeApplication;
    import flash.display.SimpleButton;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageQuality;
    import flash.display.StageScaleMode;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.InvokeEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.NativeDragEvent;
    import flash.events.UncaughtErrorEvent;
    import flash.net.registerClassAlias;
    import flash.system.Capabilities;
    import Modules.ActivityWorkTimer;
    import Modules.PenSizePreviewCursor;
    import Modules.CaptureEngine.CaptureStamp;
    import Modules.CaptureEngine.CaptureArea;
    import Modules.CacheImageMetaData;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayFileCache;

    // import
    public class Main extends Sprite
    {
        // todo: (중요) module 클래스는 정적 변수가 아니라 main에서 호출되어서 연결되어지는 클래스 인스턴스로 가는게맞는것같음
        // todo 현재 일단 컴파일만되게 분리하는작업임
        // todo layer (trace layer 포함) 좀더 쉽게 볼수있도록 ui 개편해야함

        public static var _instance:Main;
        public const APP_VERSION:String = "28.01";
        public const APP_STATE_VERSION:String = "2801";
        public static const ADOBE_AIR_SDK_VERSION:String = "51.3.4.2";

        public const STRING_TITLE_FOFOPAINT:String = " - FOFO PAINT";

        // 기타


        public function Main():void
        {
            _instance = this;
            if (this.stage)
            {
                initializeStage();
            }
            else
            {
                this.addEventListener(Event.ADDED_TO_STAGE, onStageAdded);
            }
        }
        public function onStageAdded(e:Event):void
        {
            this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdded);
            initializeStage();
        }
        public function initializeModule():void
        {
            // 나중에 file load 클래스 초기화로 옮겨야함
            registerClassAlias("AppStateVars", AppStateVars);
            registerClassAlias("CacheImageMetaData", CacheImageMetaData);
            // main ui가 호출되기전에 이것부터 stage 연결시켜주어야함 그냥 상단에 고정
            HintBoxSet.setMainStage(this.stage);

            AboutBoxController.setMainInstance(this);
            AppUpdater.setMainInstance(this);
            AppStateManager.setMainInstance(this);
            AppWindowState.setMainInstance(this);
            ImeController.setMainInstance(this);
            ActivityWorkTimer.setMainInstance(this);
            BackgroundWorkerCoordinator.setMainInstance(this);
            CanvasGridOverlay.setMainInstance(this);
            CaptureController.setMainInstance(this);
            CaptureStamp.setMainInstance(this);
            CaptureArea.setMainInstance(this);

            CanvasView.setMainInstance(this);
            CanvasResizer.setMainInstance(this);
            CanvasNavigator.setMainInstance(this);
            ClipboardManager.setMainInstance(this);
            ColorPickerController.setMainInstance(this);
            DragInteraction.setMainInstance(this);
            FileManager.setMainInstance(this);
            ImageViewWindow.setMainInstance(this);
            HintController.setMainInstance(this);
            UIController.setMainInstance(this);
            PaletteController.setMainInstance(this);
            PenSizePreviewCursor.setMainInstance(this);
            ReferenceLayerController.setMainInstance(this);
            SidebarController.setMainInstance(this);
            ToolController.setMainInstance(this);
            Utils.setMainInstance(this);
            ReplayController.setMainInstance(this);
            InputManager.setMainInstance(this);
            DrawModeInput.setMainInstance(this);
            CaptureModeInput.setMainInstance(this);
            ReplayModeInput.setMainInstance(this);
        }

        public function initializeTools():void
        {
            PenTool.setMainInstance(this);
            LassoTool.setMainInstance(this);
            LineTool.setMainInstance(this);
            HandTool.setMainInstance(this);
            ZoomTool.setMainInstance(this);
            MoveTool.setMainInstance(this);
            RotateTool.setMainInstance(this);
            FillPenTool.setMainInstance(this);
            EyeDropperTool.setMainInstance(this);
        }

        public function initializeStage():void
        {
            initializeModule();
            initializeTools();
            AppWindowState.updateWindowTitle();
            AppWindowState.markWindowTitleAsDirty();
            initializeStageSettings();
            CanvasView.init();
            ReplayController.initializeReplayCanvas();
            UIController.initializeAppMenus();
            CanvasResizer.init();
            CaptureController.initializeCaptureModeTransparentBG();
            BackgroundWorkerCoordinator.initializeWorker();
            AppStateManager.loadAppState();
            // 입력 이벤트는 loadappdstate보다느려야함
            addGlobalEvents();
            DrawModeInput.addEvents();
            const isNewReplayFile:Boolean = !FileManager.replayDataFilePath.exists;
            ReplayFileCache.initializeReplayDataFile();
            if (isNewReplayFile)
            {
                ReplayFileCache.createFirstImageCache(DrawCanvas.canvasLayer1BitmapData, DrawCanvas.canvasLayer2BitmapData, DrawCanvas.CANVAS_BG_COLOR);
            }
            CanvasNavigator.box.updateImage();
            ActivityWorkTimer.start();
            AppUpdater.checkUpdate();
            ImeController.init();
            ColorPickerController.colorPickerBox.setActiveColorPreset(0);
            HintController.mouseHint.updateBGColor();
            SidebarController.moveSideBar("left"); // 컨트롤 박스 크기가 set pentool 이후에 제대로 바뀜 원인 모름
            stage.addChild(SidebarController.fofo);
            stage.setChildIndex(SidebarController.fofo, stage.getChildIndex(SidebarController.sideBar) + (stage.getChildIndex(SidebarController.fofo) < stage.getChildIndex(SidebarController.sideBar) ? 0 : 1));
            HintStrings.setMainInstance(this);
            HintController.bottomHint.visible = true;
            ToolController.selectPenTool();
            ToolController.addHintEventToolBox2();
            ClipboardManager.checkCanUseClipBoardButton();
        }
        // function

        public function initializeStageSettings():void
        {
            stage.vsyncEnabled = true;
            stage.scaleMode = StageScaleMode.NO_SCALE; // 창크기 상관없이 스테이지 크기 고정
            stage.align = StageAlign.TOP_LEFT;
            stage.quality = StageQuality.BEST;
            stage.tabChildren = false;
            NativeApplication.nativeApplication.autoExit = true;
        }

        public function addGlobalEvents():void
        {
            // 전역스테이지 이벤트 cMouseMoveStage <- 스테이지 마우스 무브는 클로저로 하고있음
            // todo gpt가 동일한 우선순위라도 capture 플래그가 true인것이 먼저 실행된다고함 capture - target  -bubble 순이라고함
            // 그래서 마우스랑 키보드 입력 mouseleave이벤트를 캡쳐플래그를 true로해놓았음 나중에 기능 이상생기면 확인
            stage.addEventListener(MouseEvent.MOUSE_DOWN, InputManager.onMouseDownStage, true, InputPriority.STAGE_ROOT);
            stage.addEventListener(MouseEvent.MOUSE_UP, InputManager.onMouseUpStage, false, InputPriority.STAGE_ROOT);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, InputManager.onRightMouseUpStage, false, InputPriority.STAGE_ROOT);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, InputManager.onRightMouseDownStage, true, InputPriority.STAGE_ROOT);
            stage.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, InputManager.onMiddleMouseDownStage, false, InputPriority.STAGE_ROOT);
            stage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP, MouseState.onMiddleUp, false, InputPriority.STAGE_ROOT);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, MouseState.onMouseMoveHeal, true, InputPriority.STAGE_ROOT);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, InputManager.onKeyDownStage, true, InputPriority.STAGE_ROOT);
            stage.addEventListener(KeyboardEvent.KEY_UP, InputManager.onKeyUpStage, false, InputPriority.STAGE_ROOT);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, InputManager.onMouseMoveUpdatePenPreviewCursor);
            stage.addEventListener(MouseEvent.MOUSE_UP, InputManager.onMouseMoveUpdatePenPreviewCursor, false, InputPriority.MODE);
            stage.addEventListener(Event.MOUSE_LEAVE, InputManager.onMouseLeaveStage, true);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, HintController.onMouseMoveBottomHint);
            stage.nativeWindow.x = Capabilities.screenResolutionX / 2 - 680 / 2;
            stage.nativeWindow.y = Capabilities.screenResolutionY / 2 - 768 / 2 - 50;
            stage.nativeWindow.addEventListener(Event.RESIZE, AppWindowState.onWindowResize);
            stage.nativeWindow.addEventListener(Event.DEACTIVATE, AppWindowState.onWindowDeactivate);
            stage.nativeWindow.addEventListener(Event.ACTIVATE, AppWindowState.onWindowActive);
            stage.nativeWindow.addEventListener(Event.CLOSING, AppWindowState.onWindowClosingEvent);
            stage.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, ReplayController.onDragEnterStage);
            stage.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, FileManager.onDragDropStage);
            stage.addEventListener(MouseEvent.MOUSE_WHEEL, InputManager.onMouseWheelStage);
            NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, FileManager.onInvokeEvent);
            loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onGlobalError);
            function onGlobalError(e:UncaughtErrorEvent):void
            {
                e.preventDefault();
                const errorObject:* = e.error;
                FileManager.writeCrashLog(errorObject);

                try
                {
                    var msg:String = "An unknown error occurred.";
                    if (errorObject is Error)
                    {
                        msg = (errorObject as Error).message;
                    }
                    else if (errorObject is ErrorEvent)
                    {
                        msg = (errorObject as ErrorEvent).text;
                    }
                    else if (errorObject != null) // Error, ErrorEvent가 아닌 객체 처리
                    {
                        msg = String(errorObject);
                    }
                    HintController.showMouseHintTemp(msg, 10.0);
                }
                catch (hintError:Error)
                {
                    trace("Global error hint failed: " + hintError);
                }
            }
        }
    }
}
