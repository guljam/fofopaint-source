package
{
    import Modules.AppStateVars;
    import Modules.AppUpdater;
    import Modules.CacheImageMetaData;
    import Modules.CanvasViewport;
    import Modules.CaptureEngine.CaptureArea;
    import Modules.CaptureEngine.CaptureController;
    import Modules.CaptureEngine.CaptureStamp;
    import Modules.ClipboardManager;
    import Modules.DragInteraction;
    import Modules.InputPriority;
    import Modules.MouseState;
    import Modules.ReferenceLayerController;
    import Modules.Tools.MoveTool;
    import Modules.UIEngine.CanvasNavigator;
    import Modules.Utils;

    import Symbols.HintBoxSet;

    import flash.desktop.NativeApplication;
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
    import Modules.ReplayEngine.ReplayMouseAutoHide;
    import Modules.L3Feature.ActivityWorkTimer;
    import Modules.L5App.AppWindowState;
    import Modules.L4UI.CanvasGridOverlay;
    import Modules.L2Engine.DrawEngine.CanvasResizer;
    import Modules.L5App.InputManager.CaptureModeInput;
    import Modules.L4UI.ColorPickerController;
    import Modules.L5App.InputManager.DrawModeInput;
    import Modules.L3Feature.Tools.EyeDropperTool;
    import Modules.L5App.FileManager;
    import Modules.L3Feature.Tools.FillPenTool;
    import Modules.L3Feature.Tools.HandTool;
    import Modules.L4UI.ImageViewWindow;
    import Modules.L3Feature.ImeController;
    import Modules.L5App.InputManager.InputManager;
    import Modules.L3Feature.Tools.LassoTool;
    import Modules.L3Feature.Tools.LineTool;
    import Modules.L4UI.LoadBoxController;
    import Modules.L5App.ReplayEngine.ReplayController;
    import Modules.L5App.InputManager.ReplayModeInput;
    import Modules.L3Feature.Tools.RotateTool;
    import Modules.L4UI.SidebarController;
    import Modules.L3Feature.Tools.ToolController;
    import Modules.L4UI.Tools.ToolPanel;
    import Modules.L1Data.KeyState;
    import Modules.L4UI.AboutBoxController;
    import Modules.L5App.AppStateManager;
    import Modules.L2Engine.BackgroundWorkerCoordinator;
    import Modules.L4UI.PaletteController;
    import Modules.L2Engine.ReplayEngine.ReplayFileCache;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L1Data.AppDataPaths;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L4UI.PenSizePreviewCursor;
    import Modules.L1Data.Tools.PenSettings;
    import Modules.DrawEngine.StrokeBuffer;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L3Feature.Tools.PenTool;
    import Modules.L3Feature.Tools.ZoomTool;

    // import
    // 층: L5 앱 흐름 - 앱 시작과 모듈 조립, 스테이지 초기화
    public class Main extends Sprite
    {
        // todo: (중요) module 클래스는 정적 변수가 아니라 main에서 호출되어서 연결되어지는 클래스 인스턴스로 가는게맞는것같음
        // todo 앱 30 fps 전환 고려해보기, 예전에 24fps가 cpu도 덜먹고 선찢어지는 현상 덜해서 선택했었는데 지금은 좀 생각이 바뀌네
        public static var _instance:Main;
        public const APP_VERSION:String = "30.0.0";
        public const APP_STATE_VERSION:String = "30.0.0";
        public static const ADOBE_AIR_SDK_VERSION:String = "51.4.1.1";

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
        // 아래층(L1~L3)이 위층에 알릴 때 쓰는 보고용 슬롯을 등록함. loadAppState보다 먼저 등록해야 함 (initializeModule 끝에서 부름. 각 클래스의 static 초기화가 setMainInstance 순서보다 앞서지 않도록 그 뒤에 둠)
        public function registerSlots():void
        {
            PenSettings.onMouseHintTempFunc = HintController.showMouseHintTemp;
            PenSettings.onAlphaAppliedFunc = ToolPanel.updateOpacityCursorPos;
            PenSettings.onSizeIndexAppliedFunc = ToolPanel.movePenSizeCursor;
            PenSettings.onShapeSelectedFunc = ToolPanel.updatePenShapeSet;
            PenSettings.onSharpLineToggledFunc = ToolPanel.updateSharpLineButtons;
            PenSettings.onAirBrushToggledFunc = ToolPanel.updateAirBrushButtons;
            PenSettings.onBlurShapeSetFunc = ToolPanel.setBlurShapeSet;
            PenSettings.onDrawLayerFilterClearedFunc = function ():void
            {
                StrokeBuffer.canvasDrawLayerChild.filters = [];
            };
            PenSettings.onCursorShapeChangedFunc = PenSizePreviewCursor.updateSizeAndShape;
            PenSettings.onCursorPosChangedFunc = PenSizePreviewCursor.updatePosAndVisibility;
            PenSettings.onCursorSizeChangedFunc = PenSizePreviewCursor.updateCursorSize;
            PenSettings.onPenToolNeededFunc = ToolController.selectPenToolIfNotDrawingTool;
            CanvasView.onCanvasPanelResizedFunc = UIController.updateCanvasPanelLinkedUI;
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
            CanvasViewport.setMainInstance(this);
            CanvasResizer.setMainInstance(this);
            CanvasNavigator.setMainInstance(this);
            ClipboardManager.setMainInstance(this);
            ColorPickerController.setMainInstance(this);
            DragInteraction.setMainInstance(this);
            FileManager.setMainInstance(this);
            LoadBoxController.setMainInstance(this);
            ImageViewWindow.setMainInstance(this);
            HintController.setMainInstance(this);
            UIController.setMainInstance(this);
            PaletteController.setMainInstance(this);
            PenSizePreviewCursor.setMainInstance(this);
            ReferenceLayerController.setMainInstance(this);
            SidebarController.setMainInstance(this);
            ToolController.setMainInstance(this);
            ToolPanel.setMainInstance(this);
            Utils.setMainInstance(this);
            ReplayController.setMainInstance(this);
            ReplayMouseAutoHide.setMainInstance(this);
            InputManager.setMainInstance(this);
            KeyState.setMainInstance(this);
            DrawModeInput.setMainInstance(this);
            CaptureModeInput.setMainInstance(this);
            ReplayModeInput.setMainInstance(this);
            registerSlots();
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
            UIController.initializeCanvasView();
            ReplayController.initializeReplayCanvas();
            UIController.initializeAppMenus();
            CanvasResizer.init();
            CaptureController.initializeCaptureModeTransparentBG();
            BackgroundWorkerCoordinator.initializeWorker();
            AppStateManager.loadAppState();
            // 입력 이벤트는 loadappdstate보다느려야함
            addGlobalEvents();
            DrawModeInput.addEvents();
            const isNewReplayFile:Boolean = !AppDataPaths.replayDataFilePath.exists;
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
            ToolPanel.addHintEventToolBox2();
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
            // gpt가 동일한 우선순위라도 capture 플래그가 true인것이 먼저 실행된다고함 capture - target  -bubble 순이라고함
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
                AppDataPaths.writeCrashLog(errorObject);

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
