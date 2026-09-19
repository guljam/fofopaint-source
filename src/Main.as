package
{
    import Modules.AboutBoxController;
    import Modules.AppStateManager;
    import Modules.AppStateVars;
    import Modules.AppUpdater;
    import Modules.BackgroundWorkerCoordinator;
    import Modules.CanvasController;
    import Modules.CanvasGridOverlay;
    import Modules.CaptureController;
    import Modules.ClipboardManager;
    import Modules.ColorPickerController;
    import Modules.DragInteraction;
    import Modules.FileManager;
    import Modules.FillPenTool;
    import Modules.ImageViewWindow;
    import Modules.InputController;
    import Modules.MainUI;
    import Modules.MainUIController;
    import Modules.PaletteController;
    import Modules.ReferenceLayerController;
    import Modules.ReplayController;
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
    import Modules.UndoManager;
    import Modules.Utils;

    //todo 힌트박스 컨트롤러 만들기, 지금 각툴에 힌트 관련 마우스 이벤트가 있음 이것을 전부 옮기기 mainui도아마 개편해야할듯싶음 힌트관련 메뉴가 많음
    import Symbols.HintBoxSet;

    import flash.desktop.NativeApplication;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.IBitmapDrawable;
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
    import flash.events.TimerEvent;
    import flash.events.UncaughtErrorEvent;
    import flash.filesystem.File;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.net.URLRequest;
    import flash.net.navigateToURL;
    import flash.net.registerClassAlias;
    import flash.system.Capabilities;
    import flash.utils.Timer;
    import flash.utils.getTimer;
    import Modules.ActivityWorkTimer;

    // import
    public class Main extends Sprite
    {
        // todo: (중요) module 클래스는 정적 변수가 아니라 main에서 호출되어서 연결되어지는 클래스 인스턴스로 가는게맞는것같음
        // todo 현재 일단 컴파일만되게 분리하는작업임
        // todo layer (trace layer 포함) 좀더 쉽게 볼수있도록 ui 개편해야함

        public static var _instance:Main;
        public const APP_VERSION:String = "28.01";
        public const APP_STATE_VERSION:String = "2801";

        public const STRING_TITLE_FOFOPAINT:String = " - FOFO PAINT";

        // 윈도우 크기변수
        // 툴 클로져 자주쓰는거는 클로져로 메모리에 미리 올려둬서 성능향상하려고 한건데 모르겠음
        public var updatePenSizeCursor:Function = cUpdatePenSizeCursor();
        public var penCursorManager:Object = cPenCursorUpdater();
        public var resizeCanvas:Object = CanvasController.cResizeCanvas();

        // 기타
        public var isAppClosing:Boolean = false; // 앱종료할때 올려줌 창 최대화 되어있는 상태를 원래대로 하고 window resize이벤트에서 마지막에 종료 호출
        public var lastWindowDeactivateTime:int = 0; // 윈도우 비활성화된 시간 저장, 알탭 반복 시 save all data 과다 호출 방지
        public var lastEraserPosButton:SimpleButton = null; // 지우개 툴이 이동한 버튼 저장; 복원용

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
            registerClassAlias("AppState", AppStateVars);
            // main ui가 호출되기전에 이것부터 stage 연결시켜주어야함 그냥 상단에 고정
            HintBoxSet.setMainStage(this.stage);

            AboutBoxController.setMainInstance(this);
            AppUpdater.setMainInstance(this);
            AppStateManager.setMainInstance(this);
            ActivityWorkTimer.setMainInstance(this);
            BackgroundWorkerCoordinator.setMainInstance(this);
            CanvasGridOverlay.setMainInstance(this);
            CaptureController.setMainInstance(this);
            CanvasController.setMainInstance(this);
            ClipboardManager.setMainInstance(this);
            ColorPickerController.setMainInstance(this);
            DragInteraction.setMainInstance(this);
            FileManager.setMainInstance(this);
            ImageViewWindow.setMainInstance(this);
            MainUI.setMainInstance(this);
            MainUIController.setMainInstance(this);
            PaletteController.setMainInstance(this);
            ReferenceLayerController.setMainInstance(this);
            SidebarController.setMainInstance(this);
            ToolController.setMainInstance(this);
            Utils.setMainInstance(this);
            UndoManager.setMainInstance(this);
            ReplayController.setMainInstance(this);
            InputController.setMainInstance(this);
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
            MainUIController.updateWindowTitle();
            MainUIController.markWindowTitleAsDirty();
            initializeStageSettings();
            CanvasController.initializeCanvas();
            ReplayController.initializeReplayCanvas();
            MainUI.initializeAppMenus();
            MainUIController.initializeResizeButtonFamily();
            CaptureController.initializeCaptureModeTransparentBG();
            BackgroundWorkerCoordinator.initializeWorker();
            AppStateManager.loadAppState();
            // 입력 이벤트는 loadappdstate보다느려야함
            addGlobalEvents();
            addGlobalEventsChild();
            InputController.addInputEventsDrawMode();
            ReplayController.initializeReplayDataFile();
            CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
            ActivityWorkTimer.start();
            AppUpdater.checkUpdate();
            InputController.tryDisableIME();
            ColorPickerController.colorPickerBox.setActiveColorPreset(0);
            MainUI.mouseHint.updateBGColor();
            SidebarController.moveSideBar("left"); // 컨트롤 박스 크기가 set pentool 이후에 제대로 바뀜 원인 모름
            stage.addChild(SidebarController.fofo);
            stage.setChildIndex(SidebarController.fofo, stage.getChildIndex(SidebarController.sideBar) + (stage.getChildIndex(SidebarController.fofo) < stage.getChildIndex(SidebarController.sideBar) ? 0 : 1));
            HintStrings.setMainInstance(this);
            MainUI.bottomHint.visible = true;
            ToolController.selectPenTool();
            ClipboardManager.checkCanUseClipBoardButton();
        }
        // function


        public function setRcursorRotation(newAngle:Number):void
        {
            ReplayController.rReplayFOFOCursor.rotation = -newAngle;
        }

        public function getClipRectOffsetAirBrush(size:int):Number
        {
            const len:uint = PenTool.penSizeList.length;
            for (var i:uint = 1;i < len;i++)
            {
                if (PenTool.penSizeList[i] === size)
                {
                    return size + PenTool.airBrushClipRectOffsetData[i];
                }
            }
            return 0;
        }

        public function getCanvasLayerSwappedHintString():String
        {
            return "Layers has been swapped " + ((CanvasController.isLayerSwapped) ? "1 / 2" : "2 / 1");
        }

        public function mirrorRCursorPos():void
        {
            const p:Point = ReplayController.drawReplayByCommand.getRCursorPos();
            const half:Number = CanvasController.CANVAS_WIDTH / 2;
            const curcorX:Number = ReplayController.rReplayFOFOCursor.x + (half - p.x) * 2;
            ReplayController.rReplayFOFOCursor.x = curcorX;
            ReplayController.drawReplayByCommand.setRCursorPos(curcorX, p.y);
        }
        public function startAlphaFadeOut(target:DisplayObject, startAlpha:Number = 1.0, waitDuration:Number = 0.0):void
        {
            target.alpha = startAlpha;
            target.visible = true;
            const startTime:int = getTimer() + waitDuration * 1000;
            FOFOTimer.addByName("alphaFadeOutTimer_" + target.name, 0.0, true, function ():Boolean
                {
                    if (getTimer() < startTime)
                    {
                        return true;
                    }
                    if (target.visible === false)
                    {
                        return false;
                    }
                    target.alpha -= 0.1;
                    if (target.alpha < 0.0)
                    {
                        target.visible = false;
                        target.alpha = 1.0;
                        return false;
                    }
                    return true;
                });
        }

        public function isCursorInDrawArea():Boolean
        {
            return !(MainUI.topBar.hitTestPoint(stage.mouseX, stage.mouseY)
                    || (SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(stage.mouseX, stage.mouseY))
                    || (MainUI.seekBarBox.visible && MainUI.seekBarBox.hitTestPoint(stage.mouseX, stage.mouseY)));
        }

        public function initializeStageSettings():void
        {
            stage.vsyncEnabled = true;
            stage.scaleMode = StageScaleMode.NO_SCALE; // 창크기 상관없이 스테이지 크기 고정
            stage.align = StageAlign.TOP_LEFT;
            stage.quality = StageQuality.BEST;
            stage.tabChildren = false;
            NativeApplication.nativeApplication.autoExit = true;
        }

        public function onMouseUpStage(e:MouseEvent):void
        {
            InputController.checkInvalidKey();
            const mx:Number = stage.mouseX;
            const my:Number = stage.mouseY;
            CanvasController.isMouseLeftClicked = false;
            if (!CanvasController.isMouseLeftClicked && CanvasController.isRightMouseClicked)
            {
                CanvasController.isMouseDragging = false;
            }
        }

        public function onRightMouseUpStage(e:MouseEvent):void
        {
            InputController.checkInvalidKey();
            const mx:Number = stage.mouseX;
            const my:Number = stage.mouseY;
            CanvasController.isRightMouseClicked = false;
            if (!CanvasController.isMouseLeftClicked && CanvasController.isRightMouseClicked)
            {
                CanvasController.isMouseDragging = false;
            }
        }

        public function onMouseLeaveStage(e:Event):void
        {
            CanvasController.isMouseLeftClicked = false;
            CanvasController.isRightMouseClicked = false;
            CanvasController.isMouseDragging = false;
            CanvasController.penSizePreviewCursor.visible = false;
        }

        public function onMouseWheelStage(e:MouseEvent):void
        {
            if (CanvasController.isMouseLeftClicked || CanvasController.isRightMouseClicked || CanvasController.isMouseDragging
                    || MainUIController.isPopUpWindowOpened()
                    || CaptureController.isCaptureModeON || !SidebarController.isQuickSidebarActive && InputController.isKeyPressed() || InputController.getCommandKey() !== 0)
            {
                return;

            }

            if (!FOFOTimer.hasTimer("wheelZoomTimer"))
            {
                FOFOTimer.addByName("wheelZoomTimer", 0.07, false, function ():void
                    {
                        if (SidebarController.isMouseCursorInSideBar())
                        {
                            if (SidebarController.sideBarScrollBar.visible === true)
                            {
                                if (e.delta > 0)
                                {
                                    SidebarController.startScrollSidebarByMouseWheel(40);
                                }
                                else
                                {
                                    SidebarController.startScrollSidebarByMouseWheel(-40);
                                }
                            }
                        }
                        else if (!ReplayController.isReplayModeON && isCursorInDrawArea())
                        {
                            if (e.delta > 0)
                            {
                                CanvasController.zoomInCanvas(true, false);
                                MainUI.showMouseHintTemp(Math.floor(CanvasController.canvasZoomMultipler * 100) + "%");
                            }
                            else
                            {
                                CanvasController.zoomInCanvas(false, false);
                                MainUI.showMouseHintTemp(Math.floor(CanvasController.canvasZoomMultipler * 100) + "%");
                            }
                        }
                    });
            }
        }

        public function resetApp():void
        {
            stage.nativeWindow.removeEventListener(Event.CLOSING, FileManager.onWindowClosingEvent);
            stage.nativeWindow.removeEventListener(Event.DEACTIVATE, FileManager.onWindowDeactivate);
            const files:File = File.applicationStorageDirectory;
            files.deleteDirectory(true);
        }

        public function onMouseMoveUpdatePenPreviewCursor(e:MouseEvent):void
        {
            if (ReplayController.isReplayModeON || CaptureController.isCaptureModeON)
            {
                return;
            }

            penCursorManager.check();
        }

        public function cPenCursorUpdater():Object
        {
            var cursorSize:Number = 3.0;
            function getCursorSize():Number
            {
                return cursorSize;
            }
            function updateCursorSize(size:Number):void
            {
                cursorSize = size * CanvasController.canvasZoomMultipler;
            }
            function updateZoom(z:Number):void
            {
                if (ToolController.isSelectedToolPenOrLine())
                {
                    cursorSize = PenTool.penSize * CanvasController.canvasZoomMultipler;
                }
                else if (ToolController.isSelectedTool(ToolController.TOOL_ERASER))
                {
                    cursorSize = PenTool.eraserSize * CanvasController.canvasZoomMultipler;
                }
                else
                {
                    cursorSize = 0;
                }
            }
            function checkCursorVisibility():void
            {
                if (cursorSize <= 4 || ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
                {
                    if (CanvasController.penSizePreviewCursor.visible)
                    {
                        CanvasController.penSizePreviewCursor.visible = false;
                    }
                }
                else if (CanvasController.penSizePreviewCursor.visible === false)
                {
                    CanvasController.penSizePreviewCursor.visible = true;
                }
            }
            function check():void
            {
                const mx:Number = stage.mouseX;
                const my:Number = stage.mouseY;
                // 아마 이거 preview커서 박스 커서가 커져서 sidebar 바운더리가 커졌을때
                // 제대로 확인못해서 썼던걸거임
                // || (!quickSidebarON && !isCursorInDrawArea())
                // (sideBar.visible && (sideBarScrollBar.hitTestPoint(mouseX,mouseY) || sideBar.hitTestPoint(mouseX,mouseY)))
                if (CanvasController.isPenSizeCursorInvisible
                        || (ToolController.nowTool > ToolController.TOOL_LINE && ToolController.nowTool !== ToolController.TOOL_FILLPEN) // 1 2 3 4 펜 지우개 라인툴 라인-지우개툴
                        || !isCursorInDrawArea()
                        || resizeCanvas.isCanvasResizing()
                        || (ReferenceLayerController.refLayerMenuBox.visible && ReferenceLayerController.refLayerMenuBox.hitTestPoint(stage.mouseX, stage.mouseY))
                        || FileManager.loadMenuBox.visible)
                {
                    CanvasController.penSizePreviewCursor.visible = false;
                }
                else
                {
                    // addundo플래그가 커서가 캔버스 안에 들어올때 해주기 때문에 위치를 계속 갱신해줘야함
                    CanvasController.penSizePreviewCursor.x = mx;
                    CanvasController.penSizePreviewCursor.y = my;
                    checkCursorVisibility();
                }
            }
            return {
                    check: check,
                    updateZoom: updateZoom,
                    updateCursorSize: updateCursorSize,
                    checkCursorVisibility: checkCursorVisibility
                };
        }

        public function restoreCanvasBackgroundColor(replayMode:Boolean):void
        {
            var xPanel:Sprite;
            var w:Number = CanvasController.CANVAS_WIDTH;
            var h:Number = CanvasController.CANVAS_HEIGHT;
            var color:uint;
            if (replayMode)
            {
                xPanel = ReplayController.rCanvasPanel;
                w = ReplayController.RCANVAS_WIDTH;
                h = ReplayController.RCANVAS_HEIGHT;
                color = ReplayController.RCANVAS_BG_COLOR;
            }
            else
            {
                xPanel = CanvasController.canvasPanel;
                w = CanvasController.CANVAS_WIDTH;
                h = CanvasController.CANVAS_HEIGHT;
                color = CanvasController.CANVAS_BG_COLOR;
            }
            xPanel.graphics.clear();
            xPanel.graphics.beginFill(color);
            xPanel.graphics.drawRect(0, 0, w, h);
            xPanel.graphics.endFill();
        }

        public function updateStageBGSize():void
        {
            MainUI.stageBG.graphics.clear();
            MainUI.stageBG.graphics.beginFill(0, 0.0);
            MainUI.stageBG.graphics.drawRect(-2, -2, stage.stageWidth + 4, stage.stageHeight + 4);
            MainUI.stageBG.graphics.endFill();
            if (MainUI.stageBG.getChildByName("rCanvasCompleteAnchorPoint"))
            {
                ReplayController.setReplayCompleteCanvasCenter();
            }
        }
        public function addGlobalEvents():void
        {
            // 전역스테이지 이벤트 cMouseMoveStage <- 스테이지 마우스 무브는 클로저로 하고있음
            // todo gpt가 동일한 우선순위라도 capture 플래그가 true인것이 먼저 실행된다고함 capture - target  -bubble 순이라고함
            // 그래서 마우스랑 키보드 입력 mouseleave이벤트를 캡쳐플래그를 true로해놓았음 나중에 기능 이상생기면 확인
            stage.addEventListener(MouseEvent.MOUSE_DOWN, InputController.onMouseDownStage, true, 1);
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpStage, false, 1);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpStage, false, 1);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, InputController.onRightMouseDownStage, true, 1);
            stage.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, InputController.onMiddleMouseDownStage, false, 1);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, InputController.onKeyDownStage, true, 1);
            stage.addEventListener(KeyboardEvent.KEY_UP, InputController.onKeyUpStage, false, 1);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveUpdatePenPreviewCursor);
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseMoveUpdatePenPreviewCursor, false, -1);
            stage.addEventListener(Event.MOUSE_LEAVE, onMouseLeaveStage, true);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, MainUI.onMouseMoveBottomHint);
            stage.nativeWindow.x = Capabilities.screenResolutionX / 2 - 680 / 2;
            stage.nativeWindow.y = Capabilities.screenResolutionY / 2 - 768 / 2 - 50;
            stage.nativeWindow.addEventListener(Event.RESIZE, MainUIController.onWindowResize);
            stage.nativeWindow.addEventListener(Event.DEACTIVATE, FileManager.onWindowDeactivate);
            stage.nativeWindow.addEventListener(Event.ACTIVATE, MainUIController.onWindowActive);
            stage.nativeWindow.addEventListener(Event.CLOSING, FileManager.onWindowClosingEvent);
            stage.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, ReplayController.onDragEnterStage);
            stage.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, FileManager.onDragDropStage);
            stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheelStage);
            NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, FileManager.onInvokeEvent);
            loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onGlobalError);
            function onGlobalError(e:UncaughtErrorEvent):void
            {
                var msg:String = "An unknown error occurred.";
                var errorObject:Object = e.error;
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
                MainUI.showMouseHintTemp(msg, 10.0);
                // 이 핸들러가 에러를 처리했음을 시스템에 알리고 기본 동작을 막습니다. (권장)
                e.preventDefault();
            }
        }
        public function addGlobalEventsChild():void
        {
            ToolController.toolBox2.addEventListener(MouseEvent.MOUSE_OVER, ToolController.onMouseOverToolBox2Hint);
        }

        // composing 키에대한 체크 잘모르겠음 한영 변환이 관련있는거 같음
        // VERSION변수를 문자열로 변환, 변환할때 뒤에 .0이 붙었는지 까지 체크
        public function convertVersionString(version:Number):String
        {
            var verStr:String = version.toString();
            if (verStr && verStr.indexOf(".") === -1)
                verStr = verStr + ".0";
            return verStr;
        }

        public function clearDrawingData():void
        {
            CanvasController.clearCanvas();
            ReplayController.resetZoomReplayMode();
            ReplayController.resetRotationReplayMode();
            CanvasController.centerCanvas("replay");
            ReplayController.clearCanvasReplayMode();
            CanvasController.resetZoomDrawMode();
            resetRotationDrawMode();
            CanvasController.centerCanvas("draw");
            ReplayController.clearDataAndResetVars();
            MainUIController.markWindowTitleAsDirty();
            ReplayController.drawReplayByCommand.resetFirstRCursorPos();
            ReplayController.clearRFrameTempCache();
            // reset vars보다 뒤에 와야함
            // addundo에서 활성화 해주고 있기 때문에
            MainUI.topBar.newFileButton.alpha = Global.OFFALPHA;
        }

        // todo: 분야별로 분리해야
        public function handleMouseClick(targetName:String):void
        {
            if (AboutBoxController.isAboutBoxOpened)
            {
                function onMouseUpAboutBox(e:MouseEvent):void
                {
                    stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpAboutBox);
                    const upTargetName:String = e.target.name;
                    if (targetName === upTargetName)
                    {
                        switch (targetName)
                        {
                            case "resetAppButton":
                                {
                                    resetApp();
                                    stage.nativeWindow.close();
                                }
                                break;
                            case "versionInfo":
                            case "releaseNoteButton":
                                navigateToURL(new URLRequest("https://raw.githubusercontent.com/guljam/2020FlashPaint/master/releasenote.txt"));
                                break;
                            case "aboutButton":
                                AboutBoxController.closeAboutBox();
                                break;
                            case "kor":
                                navigateToURL(new URLRequest("https://github.com/guljam/2020FlashPaint/wiki/FOFO-Paint-%EC%84%A4%EB%AA%85%EC%84%9C"));
                                break;
                            case "jp":
                                navigateToURL(new URLRequest("https://github.com/guljam/2020FlashPaint/wiki/FOFO-Paint-%E3%83%9E%E3%83%8B%E3%83%A5%E3%82%A2%E3%83%AB"));
                                break;
                            case "eng":
                                navigateToURL(new URLRequest("https://github.com/guljam/2020FlashPaint/wiki/FOFO-Paint-manual"));
                                break;
                            case "aboutHomePageLink":
                                navigateToURL(new URLRequest("https://guljam.github.io/2020FlashPaint/"));
                                break;
                            case "aboutManualFolder":
                                FileManager.openLocalManualFolder();
                                break;
                                // case "aboutMeLink":
                                // navigateToURL(new URLRequest("https://twitter.com/ninanoninini"));
                                // break;
                            default:
                                AboutBoxController.closeAboutBox();
                                break;
                        }
                    }
                }
                stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpAboutBox);
                return;
            }
            function onMouseUp(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
                const upTargetName:String = e.target.name;
                if (targetName === upTargetName)
                {
                    switch (upTargetName)
                    {
                        case "drawModeButton":
                            {
                                ReplayController.exitReplayMode();
                            }
                            break;
                        case "replayModeButton":
                            {
                                ReplayController.enterReplayMode();
                                CanvasController.isMouseLeftClicked = false; // 리플레이 버튼 누르고 나서 단축키가 안먹는 현상이 이거임
                            }
                            break;
                        case "capLayer1VisibleButton":
                            {
                                ReplayController.toggleLayerCaptureMode(1);
                            }
                            break;
                        case "capLayer2VisibleButton":
                            {
                                ReplayController.toggleLayerCaptureMode(2);
                            }
                            break;
                        case "dpiButton":
                            {
                                Global.setNextScaleIndex();
                                MainUIController.applyUIScale();
                                MainUI.showMouseHintTemp(Global.getUIScaleString());
                            }
                            break;
                        case "updateButton":
                            {
                                AppUpdater.prepareUpdate();
                            }
                            break;
                        case "sideBarPositionButton":
                        case "sideBarPositionButton2":
                            {
                                SidebarController.toggleSideBarPosition();
                            }
                            break;
                        case "sideBarOFFButton":
                        case "sideBarOFFButton2":
                            {
                                SidebarController.hideSidebarPermanent();
                            }
                            break;
                        case "sideBarONButton":
                        case "sideBarONButton2":
                            {
                                SidebarController.showSidebarPermanent();
                            }
                            break;
                        case "refLoadImageButton":
                            {
                                FileManager.openLoadFileBrowser(true);
                            }
                            break;
                        case "saveButton":
                            {
                                FileManager.openSaveFileBrowser(false);
                            }
                            break;
                        case "loadButton":
                            {
                                FileManager.openLoadFileBrowser();
                            }
                            break;
                        case "clipBoardButton":
                            {
                                ClipboardManager.tryLoadClipboardImage(false);
                            }
                            break;
                        case "repCaptureButton":
                        case "captureButton":
                            {
                                CaptureController.enterCaptureMode();
                            }
                            break;
                        case "capRotate":
                            {
                                CaptureController.rotateCaptureImage(++CaptureController.captureCanvasRotationStep, false);
                            }
                            break;
                        case "capTrans":
                            {
                                CaptureController.applyTransparentCanvasBGCaptureMode(!CaptureController.isCaptureTransparentBGShowing);
                            }
                            break;
                        case "capClipBoard":
                            {
                                CaptureController.copyCaptureImageToCilpBoard();
                            }
                            break;
                        case "capSave":
                            {
                                FileManager.saveCaptureImage();
                            }
                            break;
                        case "capOff":
                            {
                                CaptureController.handleExitCaptureMode();
                            }
                            break;
                        case "capFlip":
                            {
                                CaptureController.flipCaptureImage(!CaptureController.isCaptureCanvasFlipped, false);
                            }
                            break;
                        case "capStamp":
                            {
                                CaptureController.toggleCaptureStampButton();
                            }
                            break;
                        case "capStampFont":
                            {
                                CaptureController.showStampFontList();
                            }
                            break;
                        case "capFontListPrev":
                            {
                                CaptureController.captureStampFontListBox.updateNextFontList(false);
                            }
                            break;
                        case "capFontListNext":
                            {
                                CaptureController.captureStampFontListBox.updateNextFontList(true);
                            }
                            break;
                        case "topBarColorButton":
                            {
                                MainUIController.cycleUIColor();
                            }
                            break;
                        case "gridButton":
                            {
                                CanvasGridOverlay.gridButton.start(false);
                            }
                            break;
                        case "aboutButton":
                            {
                                AboutBoxController.openAboutBox(false);
                            }
                            break;
                        case "newWindowCloseButton":
                            {
                                ImageViewWindow.closeCanvasWindow();
                            }
                            break;
                        case "newWindowButton":
                            {
                                ImageViewWindow.openImageViewWindow();
                            }
                            break;
                        case "replayZoomInButton":
                            {
                                CanvasController.zoomInCanvas(true, true);
                            }
                            break;
                        case "replayZoomOutButton":
                            {
                                CanvasController.zoomInCanvas(false, true);
                            }
                            break;
                        case "replayFitToWindowButton":
                            {
                                ReplayController.toggleFitToCanvasReplayMode();
                            }
                            break;
                        case "replayRepeatButton":
                            {
                                ReplayController.toggleReplayRepeat();
                            }
                            break;
                        case "refMenuCloseButton":
                            {
                                Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                                ReferenceLayerController.closeRefLayerMenu();
                            }
                            break;
                        case "refTransferCanvasImageButton":
                            {
                                ReferenceLayerController.mergeCanvasImageIntoRefLayer();
                            }
                            break;
                        case "refClipBoardButton":
                            {
                                if (ReferenceLayerController.refLayerMenuBox.refClipBoardButton.alpha === 1.0)
                                {
                                    ClipboardManager.tryLoadClipboardImage(true);
                                }
                            }
                            break;
                        case "refMirrorImageButton":
                            {
                                Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                                if (ReferenceLayerController.isRefLayerEmpty())
                                {
                                    ReferenceLayerController.showRefLayerIsEmptyHint();
                                }
                                else
                                {
                                    ReferenceLayerController.startRefLayerImageMirror();
                                }
                            }
                            break;
                        case "refMemoryTrainingOnButton":
                        case "refMemoryTrainingOffButton":
                            {
                                Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                                if (ReferenceLayerController.isRefLayerEmpty())
                                {
                                    ReferenceLayerController.showRefLayerIsEmptyHint();
                                }
                                else
                                {
                                    ReferenceLayerController.toggleRefLayerMemoryTraining();
                                }
                            }
                            break;
                        case "playButton":
                            {
                                if (ReplayController.isReplayRestartTimerON())
                                {
                                    ReplayController.cancelReplayRestartTimer();
                                }
                                else
                                {
                                    ReplayController.handleReplayStartButton();
                                }
                            }
                            break;
                        case "pauseButton":
                            {
                                FOFOTimer.remove("prograssBarUpdateTimer");
                                if (ReplayController.isReplayRestartTimerON())
                                {
                                    ReplayController.cancelReplayRestartTimer();
                                }
                                else
                                {
                                    ReplayController.handleReplayStopButton();
                                }
                            }
                            break;
                        case "lassoRefLayer":
                            {
                                LassoTool.mergeLassoImageIntoToRefLayer();
                            }
                            break;
                        case "lassoOK":
                            {
                                LassoTool.applyLassoImageToCanvas();
                            }
                            break;
                        case "lassoCancel":
                            {
                                if (LassoTool._isLassoToolStarted === true)
                                {
                                    LassoTool.cancelLassoTool();
                                }
                            }
                            break;
                        case "lassoLayerMerge":
                            {
                                if (LassoTool._lassoMenuBox.lassoLayerMerge.alpha === 1.0)
                                {
                                    LassoTool.mergeLayerByLassoTool();
                                }
                            }
                            break;
                        case "lassoLayerSwap":
                            {
                                if (LassoTool._lassoMenuBox.lassoLayerSwap.alpha === 1.0)
                                {
                                    LassoTool.swapLayerByLassoTool();
                                }
                            }
                            break;
                        case "lasso1pxUp":
                            {
                                LassoTool._move1PX(LassoTool.LASSO_1PX_MOVE_UP);
                            }
                            break;
                        case "lasso1pxDown":
                            {
                                LassoTool._move1PX(LassoTool.LASSO_1PX_MOVE_DOWN);
                            }
                            break;
                        case "lasso1pxLeft":
                            {
                                LassoTool._move1PX(LassoTool.LASSO_1PX_MOVE_LEFT);
                            }
                            break;
                        case "lasso1pxRight":
                            {
                                LassoTool._move1PX(LassoTool.LASSO_1PX_MOVE_RIGHT);
                            }
                            break;
                        case "lassoCopy":
                            {
                                LassoTool.copyCanvasImageToLassoTool();
                            }
                            break;
                        case "lassoMirror":
                            {
                                LassoTool.isLassoMirrorON = !LassoTool.isLassoMirrorON;
                                LassoTool.lassoLayer1.scaleX = -LassoTool.lassoLayer1.scaleX;
                                LassoTool.lassoLayer2.scaleX = LassoTool.lassoLayer1.scaleX;
                                // 캔버스가 회전한각도도 있어서 항상 세로축을 중심으로 대칭되게 regpoint각도를 보정값으로 넣어줌
                                LassoTool.lassoLayer1.rotation = -LassoTool.lassoLayer1.rotation - (CanvasController.canvasAnchorPoint.rotation * 2);
                                LassoTool.lassoLayer2.rotation = LassoTool.lassoLayer1.rotation;
                            }
                            break;
                        case "layerMergeButton":
                            {
                                CanvasController.mergeImageIntoLayer2();
                                MainUI.showMouseHintTemp("Layers has been merged to layer 2");
                            }
                            break;
                        case "layerSwapButton":
                            {
                                CanvasController.swapLayer();
                                MainUI.showMouseHintTemp(getCanvasLayerSwappedHintString());
                            }
                            break;
                        default:
                            break;
                    }
                }
            }
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        }

        public function isHintAvailableWithFillPen(target:DisplayObject):Boolean
        {
            const targetName:String = target.name;
            if (FillPenTool.isStarted)
            {
                if (target.alpha > 0.5
                        &&
                        (ToolController.toolBox.contains(target)
                            || CanvasController.canvasInfoBox.contains(target)
                            || ColorPickerController.colorPickerBox.contains(target))
                        || target === SidebarController.sideBarScrollBar
                        || (targetName && targetName.indexOf("alphaButton") !== -1))
                {
                    return true;
                }
                else
                {
                    return false;
                }
            }
            else if (ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
            {
                if ((targetName && targetName.indexOf("nSizeButton") !== -1) || target.alpha < 0.5)
                {
                    return false;
                }
            }
            else if (MainUI.isHintUnavailable())
            {
                return false;
            }
            return true;
        }

        
        // size, size drag, zoom, rotate시 업데이트 해줌
        public function cUpdatePenSizeCursor():Function
        {
            var size:Number;
            var shape:Boolean;
            return function ():void
            {
                const isPenTool:Boolean = ToolController.isSelectedToolPenOrLine();
                if (!isPenTool && !ToolController.isSelectedTool(ToolController.TOOL_ERASER))
                {
                    return;
                }
                if (isPenTool)
                {
                    size = PenTool.penSize;
                    shape = PenTool.penIsSquare;
                }
                else
                {
                    size = PenTool.eraserSize;
                    shape = PenTool.eraserIsSquare;
                }
                const z:Number = CanvasController.canvasZoomMultipler;
                if (size * z === PenTool.penLastSizeAndShape[0] && shape === PenTool.penLastSizeAndShape[1])
                {
                    return;
                }
                PenTool.penLastSizeAndShape[0] = size * z;
                PenTool.penLastSizeAndShape[1] = shape;
                CanvasController.penSizePreviewCursor.graphics.clear();
                if (shape === false)
                {
                    CanvasController.penSizePreviewCursor.graphics.lineStyle(1, 0xFFFFFF);
                    CanvasController.penSizePreviewCursor.graphics.drawCircle(0, 0, (size / 2 - 1 / z) * z);
                    CanvasController.penSizePreviewCursor.graphics.lineStyle(1, 0);
                    CanvasController.penSizePreviewCursor.graphics.drawCircle(0, 0, (size / 2) * z);
                    CanvasController.penSizePreviewCursor.rotation = 0;
                }
                else if (shape === true)
                {
                    CanvasController.penSizePreviewCursor.graphics.lineStyle(1, 0xFFFFFF);
                    CanvasController.penSizePreviewCursor.graphics.drawRect((-size / 2 + 1 / z) * z, (-size / 8 + 1 / z) * z, (size - 2 / z) * z, (size / 4 - 2 / z) * z);
                    CanvasController.penSizePreviewCursor.graphics.lineStyle(1, 0);
                    CanvasController.penSizePreviewCursor.graphics.drawRect(-size / 2 * z, -size / 8 * z, size * z, size * z / 4);
                }
                PenTool.penCursorShape = shape;
                PenTool.penCursorSize = size;
            };
        }

        public function resetRotationDrawMode():void
        {
            const center:Point = MainUIController.getStageCenterPos("draw");
            updatePenSizeCursor();
            CanvasController.moveCanvasAnchorPoint(center.x, center.y, false);
            CanvasController.canvasAnchorPoint.rotation = 0;
            setRcursorRotation(0);
            CanvasController.canvasInfoBox.setRotate(0);
            MainUIController.updateCanvasNaigatorCursor();
        }

        public function getCanvasBoundLimitPoint(canvas:Sprite, px:Number, py:Number, width:Number, height:Number, zoom:Number, rotation:Number):Point
        {
            // 매개변수 rotation은 음수값으로 넣어야 됨
            var zoomClickX:Number = px * zoom;
            var zoomClickY:Number = py * zoom;
            if (zoomClickX < 0)
                zoomClickX = 0;
            else if (zoomClickX > width * zoom)
                zoomClickX = width * zoom;
            if (zoomClickY < 0)
                zoomClickY = 0;
            else if (zoomClickY > height * zoom)
                zoomClickY = height * zoom;
            return Utils.rotatePoint(zoomClickX, zoomClickY, rotation);
        }

        public function applyReplayCanvasToDrawModeCanvas():void
        {
            CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, ReplayController.rCanvasLayer1BitmapData, CanvasController.canvasLayer1Bitmap);
            CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, ReplayController.rCanvasLayer2BitmapData, CanvasController.canvasLayer2Bitmap);
            CanvasController.updateCavnvasSizeDrawMode(ReplayController.rCanvasLayer1BitmapData.width, ReplayController.rCanvasLayer1BitmapData.height, 0, 0, false);
            ColorPickerController.updateCanvasBGColorDrawMode(ReplayController.RCANVAS_BG_COLOR);
            CanvasController.keepCanvasPanelInStage(false);
            FileManager.isFileAlreadySaved = false;
            ReplayController.checkMirrorCanvasReplayMirror();
            CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, ReplayController.RCANVAS_BG_COLOR);
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
                ImageViewWindow.updateCanvasWindowBitmapSize();
            }
        }

        public function handlePenOpacitySizeKeyDown(keyCode:uint):Boolean
        {
            switch (keyCode)
            {
                case InputController.KEY.f:
                case InputController.KEY.h:
                    InputController.startKeyRepeat(true, ToolController.adjustDrawToolSizeByShortcut, true);
                    return true;
                case InputController.KEY.v:
                case InputController.KEY.n:
                    InputController.startKeyRepeat(true, ToolController.adjustDrawToolSizeByShortcut, false);
                    return true;
                case InputController.KEY.g:

                    InputController.startKeyRepeat(true, ToolController.adjustDrawToolAlphaByShortcut, true);
                    return true;
                case InputController.KEY.b:
                    InputController.startKeyRepeat(true, ToolController.adjustDrawToolAlphaByShortcut, false);
                    return true;
            }
            return false;
        }

        public function selectOpacityButton(targetName:String):void
        {
            const number:String = targetName.substr(11, targetName.length);
            const index:int = parseInt(number);
            ToolController.updateDrawToolAlpha(PenTool.penAlphaList[index]);
        }

    }
}
