package
{
    import flash.desktop.Clipboard;
    import flash.desktop.ClipboardFormats;
    import flash.desktop.NativeApplication;
    import flash.desktop.NativeDragManager;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.SimpleButton;
    import flash.display.Graphics;
    import flash.display.LineScaleMode;
    import flash.display.CapsStyle;
    import flash.display.JointStyle;
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.IBitmapDrawable;
    import flash.display.StageScaleMode;
    import flash.display.StageAlign;
    import flash.display.StageQuality;
    import flash.display.Loader;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.MouseEvent;
    import flash.events.KeyboardEvent;
    import flash.events.NativeDragEvent;
    import flash.events.InvokeEvent;
    import flash.events.TimerEvent;
    import flash.events.UncaughtErrorEvent;
    import flash.events.ErrorEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileStream;
    import flash.filesystem.FileMode;
    import flash.filters.BlurFilter;
    import flash.filters.GlowFilter;
    import flash.filters.ConvolutionFilter;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.ColorTransform;
    import flash.geom.Rectangle;
    import flash.net.URLRequest;
    import flash.net.FileFilter;
    import flash.net.navigateToURL;
    import flash.system.Capabilities;
    import flash.system.IME;
    import flash.utils.ByteArray;
    import flash.utils.getTimer;
    import flash.utils.Timer;
    import flash.ui.Mouse;
    import flash.net.registerClassAlias;
    import flash.utils.describeType;
    import Modules.Tools.LassoTool;
    import Modules.Tools.PenTool;
    import Modules.Utils;
    import Modules.CanvasGridOverlay;
    import Modules.DragInteraction;
    import Modules.ClipboardManager;
    import Modules.ImageViewWindow;
    import Modules.MainUI;
    import Modules.AppUpdater;
    import Modules.BackgroundWorkerCoordinator;
    import Modules.ReferenceLayerController;
    import Modules.MainUIController;
    import Modules.SidebarController;
    import Modules.PaletteController;
    import Modules.CanvasController;
    import Modules.ToolController;
    import Modules.AppStateManager;
    import Modules.ColorPickerController;
    import Modules.FileManager;
    import Modules.CaptureController;
    import Symbols.FillPenMenuSet;
    import Symbols.EyedropperLensSet;
    import Symbols.AboutWindowSet;
    import Symbols.NumPadSet;
    import Symbols.HintBoxSet;
    import Modules.UndoManager;
    import Modules.ReplayController;
    // import
    public class Main extends Sprite
    {
        //todo: (중요) module 클래스는 정적 변수가 아니라 main에서 호출되어서 연결되어지는 클래스 인스턴스로 가는게맞는것같음
        //현재 일단 컴파일만되게 분리하는작업임
        private const savepos:Array = [0, 0, 0, 0];

        public static var _instance:Main;
        public const APP_VERSION:String = "28.01";
        public const APP_STATE_VERSION:String = "2801";




        public const KEY_REPEAT_START_DELAY:Number = 0.3,
            KEY_REPEAT_INTERVAL:Number = 0.06;

        public const STRING_TITLE_FOFOPAINT:String = " - FOFO PAINT";

       

        // 파일 저장 경로

        // 키 누름 관련
        public var LAST_KEY:int = -1; // 마지막 누른거 여기다가 저장 반복호출되는 keydown 함수에서 한번만 호출되게 하는변수
        public const KEY_BUFFER:Array = []; // 정식 키 다운 눌러준 상태에서 다른 키가 눌러져 있으면 여기다가 저장
        public const COMMAND_CTRL:int = (1 << 0),
            COMMAND_SHIFT:int = (1 << 1),
            COMMAND_CTRL_SHIFT:int = (1 << 2);
        public const KEY:Object = {
                a: 65,
                b: 66,
                c: 67,
                d: 68,
                e: 69,
                f: 70,
                g: 71,
                h: 72,
                i: 73,
                j: 74,
                k: 75,
                l: 76,
                m: 77,
                n: 78,
                o: 79,
                p: 80,
                q: 81,
                r: 82,
                s: 83,
                t: 84,
                u: 85,
                v: 86,
                w: 87,
                x: 88,
                y: 89,
                z: 90,
                dot: 190,
                comma: 188,
                semicolon: 186,
                shift: 16,
                ctrl: 17,
                alt: 18,
                rightAlt: 21, // as에서는 한글모드
                rightCtrl: 25, // 한글 모드에서 오른쪽 컨트롤
                space: 32,
                backslash: 220,
                backspace: 8,
                enter: 13,
                esc: 27,
                del: 46,
                tab: 9,
                n0: 48,
                n1: 49,
                n2: 50,
                n3: 51,
                n4: 52,
                n5: 53,
                n6: 54,
                n7: 55,
                n8: 56,
                n8: 56,
                n9: 57,
                minus: 189,
                pgup: 33,
                pgdn: 34,
                home: 36,
                end: 35,
                left: 37,
                up: 38,
                right: 39,
                down: 40,
                f1: 112,
                f2: 113,
                f3: 114,
                f4: 115,
                f5: 116,
                f6: 117,
                f7: 118,
                f8: 119,
                f9: 120,
                f10: 121,
                f11: 122,
                f12: 123,
                window: 91
            };

        // about
        public const aboutBox:AboutWindowSet = new AboutWindowSet();
        public var isAboutBoxOpened:Boolean = false; // 어바웃 창 떴을때 킴

        // 키 오래누름 관련 변수
        public var pressHoldCountDownTime:Number = 0.0,
            pressHoldFrameCount:int = 0;

public const fillPenBox:FillPenMenuSet = new FillPenMenuSet();
            public var isFillPenON:Boolean = false; // 채우기 펜 플래그
            public var isFillPenStarted:Boolean = false; // 채우기 펜 시작됨
        public const eyedropperLens:EyedropperLensSet = new EyedropperLensSet();
        public var mirrorCommandReady:Boolean = false; // 미러 커맨드를 넣어줄지 말지 결정

        // 윈도우 크기변수
        // 툴 클로져 자주쓰는거는 클로져로 메모리에 미리 올려둬서 성능향상하려고 한건데 모르겠음
        public const realWorkingTimer:Object = cRealWorkingTimer(),
            dottedLine:Object = cDottedLine(), // 순서 먼저 와야함
            dotTool:Function = cDrawDot(),
            lineTool:Function = cLineTool(),
            handTool:Function = cHandTool(),
            rotateTool:Function = cCanvasRotateTool(),
            zoomTool:Function = cZoomTool(),
            moveTool:Function = cMoveTool(),
            eyeDropperTool:Function = cEyeDropperTool(),
            fillPenTool:Object = cFillPenTool(),
            drawDone:Function = cDrawDone(),
            updatePenSizeCursor:Function = cUpdatePenSizeCursor(),
            penCursorManager:Object = cPenCursorUpdater(),
            resizeCanvas:Object = CanvasController.cResizeCanvas();
     
        // 기타
        public var isAppClosing:Boolean = false; // 앱종료할때 올려줌 창 최대화 되어있는 상태를 원래대로 하고 window resize이벤트에서 마지막에 종료 호출
         public var    lastWindowDeactivateTime:int = 0; // 윈도우 비활성화된 시간 저장, 알탭 반복 시 save all data 과다 호출 방지
         public var    lastEraserPosButton:SimpleButton = null; // 지우개 툴이 이동한 버튼 저장; 복원용
         public var    isLayerCheckKeyPressed:Boolean = false;
         public var    isDrawModeInputEventsAdded:Boolean = false;
            
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
            trace('nit modu');
            //나중에 file load 클래스 초기화로 옮겨야함
            registerClassAlias("AppState", AppStateManager);
            //main ui가 호출되기전에 이것부터 stage 연결시켜주어야함 그냥 상단에 고정
            HintBoxSet.setMainStage(this.stage);

            AppUpdater.setMainInstance(this);
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
            
            PenTool.setMainInstance(this);
            LassoTool.setMainInstance(this);
        }

        public function initializeStage():void
        {
            initializeModule();
            MainUIController.updateWindowTitle();
            MainUIController.markWindowTitleAsDirty();
            initializeStageSettings();
            CanvasController.initializeCanvas();
            ReplayController.initializeReplayCanvas();
            MainUI.initializeAppMenus();
            MainUIController.initializeResizeButtonFamily();
            CaptureController.initializeCaptureModeTransparentBG();
            BackgroundWorkerCoordinator.initializeWorker();
            loadAppState();
            // 입력 이벤트는 loadappdstate보다느려야함
            addGlobalEvents();
            addGlobalEventsChild();
            addInputEventsDrawMode();
            ReplayController.initializeReplayDataFile();
            CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
            realWorkingTimer.start();
            AppUpdater.checkUpdate();
            tryDisableIME();
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
        





        public function startScratchPadResetTimer(target:DisplayObject):void
        {
            FOFOTimer.addByName("clearScratchPadTimer", 0.4, false, function ():void
                {
                    startPressHoldKey(target, "Clearing scratch pad..", null, ColorPickerController.colorPickerBox.scratchPad.clearPad, null);
                });
        }

        public function startPressHoldKey(button:DisplayObject, hintStr:String, readyFunc:Function, okFunc:Function, cancelFunc:Function):void
        {
            if (!FOFOTimer.hasTimer("pressholdtimer"))
            {
                var keyBufferLenSave:uint = getPressedKeyCount();
                var mouseClickONSave:Boolean = CanvasController.isMouseClicked;
                var rightMouseClickONSave:Boolean = CanvasController.isRightMouseClicked;
                const countDownTime:Number = 3;
                const countDownTimeNow:Number = Math.ceil((stage.frameRate * 2.5) / countDownTime);
                pressHoldCountDownTime = countDownTime;
                pressHoldFrameCount = 0;
                if (readyFunc !== null)
                {
                    if (readyFunc() === true)
                    {
                        return;
                    }
                }
                function cancelHoldingKey():void
                {
                    pressHoldFrameCount = 0;
                    pressHoldCountDownTime = countDownTime;
                    MainUI.hideMouseHint();
                }
                if (hintStr !== "")
                {
                    MainUI.showMouseHint(hintStr + " " + pressHoldCountDownTime);
                }
                FOFOTimer.addByName("pressholdtimer", 0.0, true, function ():Boolean
                    {
                        if (CanvasController.isMouseClicked !== mouseClickONSave
                                || CanvasController.isRightMouseClicked !== rightMouseClickONSave
                                || keyBufferLenSave !== getPressedKeyCount()
                                || (button && button.hitTestPoint(stage.mouseX, stage.mouseY) === false))
                        {
                            if (cancelFunc !== null)
                            {
                                cancelFunc();
                            }
                            cancelHoldingKey();
                            return false;
                        }
                        pressHoldFrameCount++;
                        if (pressHoldFrameCount >= countDownTimeNow)
                        {
                            pressHoldFrameCount = 0;
                            pressHoldCountDownTime--;
                        }
                        MainUI.showMouseHint(hintStr + " " + pressHoldCountDownTime);
                        if (pressHoldCountDownTime <= 0)
                        {
                            cancelHoldingKey();
                            okFunc();
                            return false;
                        }
                        return true;
                    });
            }
        }









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













        public function cDottedLine():Object
        {
            const lastDotPos:Point = new Point(0, 0);
            var lastLineLength:Number = 0;
            var dotLineLength:Number = 5;
            var subDotLength:Number;
            var startPos:Point = new Point(0, 0);
            var lastInterpPos:Point = new Point(0, 0);
            var lineSize:Number = 1;
            var dotLineColor:uint = 0;
            var graphics:Graphics;
            function setLineScale(zoomed:Number):void
            {
                lineSize = 1 / zoomed;
                dotLineLength = 5 / zoomed;
            }
            function toggleLineColor(from:int):uint
            {
                if (dotLineColor === 0)
                {
                    dotLineColor = 0xFFFFFF;
                }
                else
                {
                    dotLineColor = 0;
                }
                return dotLineColor;
            }
            function moveTo(g:Graphics, x:Number, y:Number):void
            {
                graphics = g;
                dotLineColor = 0;
                subDotLength = dotLineLength;
                startPos.setTo(x, y);
                lastDotPos.setTo(x, y);
                lastInterpPos.setTo(x, y);
                graphics.lineStyle(lineSize, dotLineColor, 1.0, false, "normal", "none");
                graphics.moveTo(x, y);
            }
            function lineTo(x:Number, y:Number, closeLine:Boolean = false):void
            {
                const nowPos:Point = new Point(x, y);
                var dist:Number = Point.distance(lastDotPos, nowPos);
                var interpPoint:Point = new Point(lastDotPos.x, lastDotPos.y);
                var ratio:Number;
                subDotLength -= dist;
                while (subDotLength < 0)
                {
                    ratio = (dist - subDotLength) / dist - 1.0;
                    interpPoint = Point.interpolate(interpPoint, nowPos, ratio);
                    toggleLineColor(1);
                    graphics.lineStyle(lineSize, dotLineColor, 1.0, false, "normal", "none");
                    graphics.moveTo(lastInterpPos.x, lastInterpPos.y);
                    graphics.lineTo(interpPoint.x, interpPoint.y);
                    lastInterpPos.setTo(interpPoint.x, interpPoint.y);
                    dist = Point.distance(nowPos, interpPoint);
                    subDotLength += dotLineLength;
                }
                if (closeLine)
                {
                    graphics.lineTo(startPos.x, startPos.y);
                }
                lastDotPos.setTo(x, y);
            }
            return {
                    lineTo: lineTo,
                    moveTo: moveTo,
                    setLineScale: setLineScale
                };
        }

        public function updateLastKey(key:int):void
        {
            LAST_KEY = getLastKey();
        }
        public function resetLastKey():void
        {
            LAST_KEY = -1;
        }
        public function isLastKey(key:uint):Boolean
        {
            return LAST_KEY === key;
        }

        public function startKeyRepeatStopTimerOnMouseLeave(target:DisplayObject):void
        {
            FOFOTimer.addByName("checkKeyRepeatStop", 0.0, true, function ():Boolean
                {
                    if (!target.hitTestPoint(stage.mouseX, stage.mouseY))
                    {
                        removeKeyRepeatEvents(null);
                        return false;
                    }
                    return true;
                });
        }
        public function startKeyRepeat(firstCall:Boolean, func:Function, ...args):Boolean
        {
            if (FOFOTimer.hasTimer("keyHoldWaitTimer") || FOFOTimer.hasTimer("keyHoldRepeatTimer"))
            {
                return false;
            }
            FOFOTimer.addByName("keyHoldWaitTimer", KEY_REPEAT_START_DELAY, false,
                    function ():void
                    {
                        func.apply(Main, args);
                        FOFOTimer.addByName("keyHoldRepeatTimer", KEY_REPEAT_INTERVAL, true, func, args);
                    });
            addKeyRepeatEvents();
            if (firstCall)
            {
                func.apply(Main, args);
            }
            return true;
        }
        public function checkPenOptionsKeyDown(keyCode:uint):Boolean
        {
            const secondKey:int = getSecondPressedKey();
            if (secondKey === KEY.n3 || secondKey === KEY.n8)
            {
                if (ToolController.toolOptionsBox.sharpLineButtonWrapper.alpha === 1.0)
                {
                    ToolController.toggleSharpLineByShortcut();
                }
                return true;
            }
            else if (secondKey === KEY.n4 || secondKey === KEY.n7)
            {
                if (ToolController.isSelectedToolPenOrLine() || ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
                {
                    ToolController.togglePenAirBrushButtonShortCut();
                    return true;
                }
                else if (ToolController.isSelectedTool(ToolController.TOOL_ERASER))
                {
                    ToolController.toggleEraseAirBrushButtonShortCut();
                    return true;
                }
            }
            return false;
        }
        public function isPressingControl():Boolean
        {
            return getCommandKey() === COMMAND_CTRL;
        }
        public function isPressingShift():Boolean
        {
            return getCommandKey() === COMMAND_SHIFT;
        }
        public function isPressingControlShift():Boolean
        {
            return getCommandKey() === COMMAND_CTRL_SHIFT;
        }
        public function getCommandKey():int
        {
            const first:uint = getFirstPressedKey();
            const second:uint = getSecondPressedKey();
            if ((second === KEY.shift && (first === KEY.ctrl || first === KEY.rightCtrl))
                    || (first === KEY.shift && (second === KEY.ctrl || second === KEY.rightCtrl)))
            {
                return COMMAND_CTRL_SHIFT;
            }
            if (first === KEY.shift)
            {
                return COMMAND_SHIFT;
            }
            if (first === KEY.ctrl || first === KEY.rightCtrl)
            {
                return COMMAND_CTRL;
            }
            return 0;
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


        public function onMouseDownStage(e:MouseEvent):void
        {
            checkInvalidKey();
            CanvasController.isMouseClicked = true;
            MainUI.hideBottomHint();
        }

        public function onMouseUpStage(e:MouseEvent):void
        {
            checkInvalidKey();
            const mx:Number = stage.mouseX;
            const my:Number = stage.mouseY;
            CanvasController.isMouseClicked = false;
            if (!CanvasController.isMouseClicked && CanvasController.isRightMouseClicked)
            {
                CanvasController.isMouseDragging = false;
            }
        }

        public function onRightMouseUpStage(e:MouseEvent):void
        {
            checkInvalidKey();
            const mx:Number = stage.mouseX;
            const my:Number = stage.mouseY;
            CanvasController.isRightMouseClicked = false;
            if (!CanvasController.isMouseClicked && CanvasController.isRightMouseClicked)
            {
                CanvasController.isMouseDragging = false;
            }
        }

        public function onRightMouseDownStage(e:MouseEvent):void
        {
            checkInvalidKey();
            CanvasController.isRightMouseClicked = true;
        }
        public function onMiddleMouseDownStage(e:MouseEvent):void
        {
            if (CaptureController.isCaptureModeON)
                return;
            if (FOFOTimer.hasTimer("toolTipTempONTimer"))
            {
                MainUI.hideMouseHint();
            }
            if (LassoTool.isLassoToolStarted)
            {
                LassoTool.lassoMenuBox.visible = false;
                LassoTool.isLassoMenuHiddenTemp = true;
            }
            handTool(ReplayController.isReplayModeON, true);
            ToolController.showNowToolIconToCursorTemp(ToolController.TOOL_HAND);
        }

        public function onMouseLeaveStage(e:Event):void
        {
            CanvasController.isMouseClicked = false;
            CanvasController.isRightMouseClicked = false;
            CanvasController.isMouseDragging = false;
            CanvasController.penSizePreviewCursor.visible = false;
        }

                public function onMouseWheelStage(e:MouseEvent):void
        {
            if (CanvasController.isMouseClicked || CanvasController.isRightMouseClicked || CanvasController.isMouseDragging
                    || MainUIController.isPopUpWindowOpened()
                    || CaptureController.isCaptureModeON || !SidebarController.isQuickSidebarActive && isKeyPressed() || getCommandKey() !== 0)
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



        public function cFillPenTool():Object
        {
            const lastMousePos:Point = new Point(0, 0);
            var canvasSizeRect:Rectangle = new Rectangle();
            var command:Vector.<int>;
            var data:Vector.<Number>;
            var xColor:uint;
            var xAlpha:Number;
            var commandUndoIndexArr:Array = [];
            var mouseMoveCount:int;
            var afterKeyUpOK:Boolean;
            var pos05Offset:Number;
            var xBlendMode:String;
            var clickedButton:String;
            var canvasDrawZIndexSave:int = 0;
            const lastPosOnMouseMove:Point = new Point();
            var lastFillPenBoxUsedButton:SimpleButton;
            var turnOffFillPenPreviewCount:int = 0;
            var isStartedFromShortCut:Boolean = false;
            function updateLastFillPenBoxButtonUsed(target:SimpleButton):void
            {
                lastFillPenBoxUsedButton = target;
            }
            function startFillColorUpdateTimer():void
            {
                showFillColor();
                FOFOTimer.addByName("fillColorUpdateTimer", 0.1, true, function ():Boolean
                    {
                        const newXcolor:uint = (PenTool.isTransparentPenColor) ? CanvasController.CANVAS_BG_COLOR : ColorPickerController.colorPickerBox.rgbInfoBGColor;
                        const newXAlpha:Number = PenTool.penAlpha;
                        const newXBlendMode:String = (PenTool.isTransparentPenColor) ? "erase" : null;
                        if (newXcolor !== xColor)
                        {
                            xColor = newXcolor;
                            xAlpha = newXAlpha;
                            xBlendMode = newXBlendMode;
                            showFillColor();
                        }
                        if (newXAlpha !== xAlpha)
                        {
                            xAlpha = newXAlpha;
                            showFillColor();
                        }
                        if (newXBlendMode !== xBlendMode)
                        {
                            xBlendMode = newXBlendMode;
                            showFillColor();
                        }
                        if (!SidebarController.sideBar.visible)
                        {
                            showDottedLine();
                            return false;
                        }
                        else if (!CanvasController.isMouseClicked && !SidebarController.sideBar.hitTestPoint(stage.mouseX, stage.mouseY))
                        {
                            turnOffFillPenPreviewCount--;
                            if (turnOffFillPenPreviewCount <= 0)
                            {
                                turnOffFillPenPreviewCount = 0;
                                showDottedLine();
                                return false;
                            }
                        }
                        return true;
                    });
            }
            function onMouseOverFillPenHint(e:MouseEvent):void
            {
                const target:DisplayObject = e.target as DisplayObject;
                if (!target)
                    return;
                const targetName:String = target.name;
                if (!FOFOTimer.hasTimer("fillColorUpdateTimer") && SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(stage.mouseX, stage.mouseY))
                {
                    startFillColorUpdateTimer();
                }
                if (targetName === "fillPenOK")
                    fillPenBox.hint("OK [q, o key up]");
                if (targetName === "fillPenCancel")
                    fillPenBox.hint("Cancel\n[esc, backspace]");
                else if (targetName === "fillPenUndo")
                    fillPenBox.hint("ReplayController.Undo [w, z, i, .]");
                else if (targetName === "fillPenSidebar")
                    fillPenBox.hint("[6, s+d, j+k]");
            }
            function checkFillPenUndoReady():Boolean
            {
                if (canvasSizeRect.intersects(CanvasController.canvasDrawLayerChild.getBounds(CanvasController.canvasPanel)))
                {
                    return true;
                }
                return false;
            }
            function showFillColor():void
            {
                CanvasController.canvasDrawLayerChild.graphics.clear();
                if (data.length === 0)
                {
                    return;
                }
                CanvasController.canvasDrawLayerChild.graphics.lineStyle(1, xColor);
                CanvasController.canvasDrawLayerChild.graphics.beginFill(xColor);
                CanvasController.canvasDrawLayerChild.graphics.drawPath(command, data);
                CanvasController.canvasDrawLayerChild.graphics.endFill();
                CanvasController.canvasDrawLayerChild.graphics.moveTo(data[data.length - 2], data[data.length - 1]);
                CanvasController.canvasDrawLayerChild.graphics.lineTo(data[0], data[1]);
                CanvasController.canvasDrawLayer.alpha = xAlpha;
            }
            function showDottedLine():void
            {
                CanvasController.canvasDrawLayerChild.graphics.clear();
                const len:uint = data.length;
                if (len <= 3)
                {
                    return;
                }
                dottedLine.moveTo(CanvasController.canvasDrawLayerChild.graphics, data[0], data[1]);
                for (var i:uint = 2;i < len;i += 2)
                {
                    dottedLine.lineTo(data[i], data[i + 1]);
                }
                dottedLine.lineTo(data[0], data[1], true);
                if (CanvasController.isLayer2Selected)
                {
                    CanvasController.bringCanvasDrawLayerAboveLayer1();
                }
                CanvasController.canvasDrawLayer.alpha = 1.0;
            }
            function exitFillPen():void
            {
                removeEvents();
                CanvasController.canvasDrawLayer.alpha = 1.0;
                mouseMoveCount = 0;
                isFillPenStarted = false;
                command.length = 0;
                data.length = 0;
                commandUndoIndexArr.length = 0;
                CanvasController.canvasDrawLayerChild.graphics.clear();
                if (ReferenceLayerController.isRefLayerMenuON)
                {
                    ReferenceLayerController.refLayerMenuBox.visible = true;
                }
                fillPenBox.visible = false;
                fillPenBox.x = -fillPenBox.width - 3;
                fillPenBox.y = -fillPenBox.height - 3;
                if (CanvasController.isLayer2Selected)
                {
                    CanvasController.bringCanvasDrawLayerAboveLayer2();
                }
                if (SidebarController.isQuickSidebarActive)
                {
                    SidebarController.startDeactivteQuickSidebar();
                }
                ToolController.toolBox.setFillPenModeOFF();
                ToolController.toolOptionsBox.setButtonsAlphaFillPenSelected(Global.OFFALPHA);
                ToolController.toolOptionsBox.restoreDisabledButtons();
                ColorPickerController.colorPickerBox.activePaperColorButton(false);
                if (isStartedFromShortCut)
                {
                    ToolController.setLastTool(ToolController.TOOL_PEN);
                    ToolController.selectPenTool();
                }
            }
            function applyFillPen():void
            {
                if (checkFillPenUndoReady() === true && command.length > 2)
                {
                    UndoManager.canAddUndoData = true;
                    command.push(2);
                    data.push(data[0]);
                    data.push(data[1]); // 마지막으로 원점으로 선을 한번 이어줘야 깔끔하게 닫힘
                    CanvasController.canvasDrawLayer.alpha = xAlpha;
                    ReplayController.rDataBuffer.push(["fill5", xColor, xAlpha, xBlendMode, command.concat(), data.concat(), ToolController.isPenAirBrushON, PenTool.airBrushSizeDrawMode]);
                    showFillColor();
                }
                CanvasController.resetCanvasDrawLayerCliprect();
                drawDone();
                exitFillPen();
            }
            function undoData():void
            {
                if (command.length === 0)
                    return;
                command.splice(commandUndoIndexArr[commandUndoIndexArr.length - 1], command.length);
                data.splice(commandUndoIndexArr[commandUndoIndexArr.length - 1] * 2, data.length);
                commandUndoIndexArr.pop();
                if (command.length <= 1)
                {
                    command.length = 0;
                    data.length = 0;
                    commandUndoIndexArr[0] = 0;
                    CanvasController.canvasDrawLayerChild.graphics.clear();
                }
                else
                {
                    showDottedLine();
                }
            }
            function onKeydownFillPen(e:KeyboardEvent):void
            {
                const pressedKey:uint = e.keyCode;
                if (CanvasController.isMouseClicked)
                {
                    return;
                }
                if (isLastKey(pressedKey))
                {
                    return;
                }
                const secondKey:int = getSecondPressedKey();
                if (SidebarController.isPressingQuickSidebarShortcut(pressedKey, secondKey)
                        || pressedKey === KEY.n6)
                {
                    updateLastKey(pressedKey);
                    if (SidebarController.isQuickSidebarActive === false)
                    {
                        SidebarController.activeQuickSideBar(true);
                        if (!FOFOTimer.hasTimer("fillColorUpdateTimer"))
                        {
                            startFillColorUpdateTimer();
                        }
                    }
                }
                else if (pressedKey === KEY.g || pressedKey === KEY.b)
                {
                    updateLastKey(pressedKey);
                    startKeyRepeat(true, function (increase:Boolean):void
                        {
                            turnOffFillPenPreviewCount = stage.frameRate;
                            ToolController.adjustDrawToolAlphaByShortcut(increase);
                        }, (pressedKey === KEY.g) ? true : false);
                    if (!FOFOTimer.hasTimer("fillColorUpdateTimer"))
                    {
                        startFillColorUpdateTimer();
                    }
                }
            }
            function onKeyUpFillPen(e:KeyboardEvent):void
            {
                const keyCode:uint = e.keyCode;
                resetLastKey();
                if (CanvasController.isMouseClicked)
                {
                    if (keyCode === KEY.q || keyCode === KEY.o || keyCode === KEY.enter)
                    {
                        afterKeyUpOK = true;
                    }
                    return;
                }
                if (keyCode === KEY.w || keyCode === KEY.i || keyCode === KEY.z || keyCode === KEY.dot)
                {
                    undoData();
                }
                else if (keyCode === KEY.q || keyCode === KEY.o || keyCode === KEY.enter)
                {
                    applyFillPen();
                }
                else if (keyCode === KEY.esc || keyCode === KEY.backspace)
                {
                    exitFillPen();
                }
            }
            function onRightMouseUpFillPen(e:MouseEvent):void
            {
                const target:DisplayObject = e.target as DisplayObject;
                if (!target as DisplayObject || target === SidebarController.sideBarScrollBar
                        || SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(stage.mouseX, stage.mouseY))
                {
                    return;
                }
                const targetName:String = target.name;
                if (targetName === "fillPenOK")
                {
                    applyFillPen();
                }
                else if (targetName === "fillPenCancel")
                {
                    exitFillPen();
                }
                else if (targetName === "fillPenUndo")
                {
                    updateLastFillPenBoxButtonUsed(target as SimpleButton);
                    undoData();
                }
                else if (targetName === "fillPenSidebar")
                {
                    updateLastFillPenBoxButtonUsed(target as SimpleButton);
                    SidebarController.activeQuickSideBar(false);
                    if (!FOFOTimer.hasTimer("fillColorUpdateTimer"))
                    {
                        startFillColorUpdateTimer();
                    }
                }
                fillPenBox.visible = false;
            }
            function onRightMouseDownFillPen(e:MouseEvent):void
            {
                const target:DisplayObject = e.target as DisplayObject;
                if (CanvasController.isMouseClicked || SidebarController.isQuickSidebarActive || !target || ColorPickerController.numPadBox.visible)
                {
                    return;
                }
                if (target === SidebarController.sideBarScrollBar)
                {
                    SidebarController.resetSideBarPosition();
                    return;
                }
                else if (target.name === "toolZoomIn" || target.name === "toolZoomOut")
                {
                    if (CanvasController.canvasZoomMultipler !== 1.0)
                    {
                        CanvasController.resetZoomDrawMode();
                    }
                    return;
                }
                else if (target.name === "toolRotate")
                {
                    if (CanvasController.canvasAnchorPoint.rotation !== 0.0)
                    {
                        resetRotationDrawMode();
                    }
                    return;
                }
                if (SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(stage.mouseX, stage.mouseY))
                {
                    return;
                }
                const scale:Number = fillPenBox.getScale();
                fillPenBox.x = Math.floor(stage.mouseX - (lastFillPenBoxUsedButton.x + lastFillPenBoxUsedButton.width / 2) * scale);
                fillPenBox.y = Math.floor(stage.mouseY - (lastFillPenBoxUsedButton.y + lastFillPenBoxUsedButton.height / 2) * scale);
                fillPenBox.visible = true;
                Utils.setAsTopChild(fillPenBox);
            }
            function onMouseUpFillPen(e:MouseEvent):void
            {
                const target:DisplayObject = e.target as DisplayObject;
                if (!target)
                    return;
                const targetName:String = e.target.name;
                FOFOTimer.remove("previewFilledColorUpdateTimer");
                CanvasController.isMouseDragging = false;
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);
                if (clickedButton === targetName)
                {
                    if (targetName === "toolFillPenOK")
                    {
                        applyFillPen();
                        return;
                    }
                    else if (targetName === "toolFillPenCancel")
                    {
                        exitFillPen();
                        return;
                    }
                    else if (targetName === "toolUndo")
                    {
                        undoData();
                        return;
                    }
                }
                if (fillPenBox.visible)
                {
                    if (clickedButton === targetName)
                    {
                        if (targetName === "fillPenOK")
                        {
                            applyFillPen();
                        }
                        else if (targetName === "fillPenCancel")
                        {
                            exitFillPen();
                        }
                        else if (targetName === "fillPenUndo")
                        {
                            updateLastFillPenBoxButtonUsed(target as SimpleButton);
                            undoData();
                        }
                    }
                }
                else
                {
                    const mousePos:Point = new Point(stage.mouseX, stage.mouseY);
                    const dist:Number = Math.floor(Point.distance(mousePos, lastMousePos));
                    mouseMoveCount += dist;
                    if (mouseMoveCount >= 10)
                    {
                        mouseMoveCount = 0;
                        commandUndoIndexArr.push(command.length - 1);
                    }
                    lastMousePos.setTo(mousePos.x, mousePos.y);
                    if (afterKeyUpOK)
                    {
                        applyFillPen();
                    }
                    else if (isCursorInDrawArea())
                    {
                        showDottedLine();
                    }
                    if (turnOffFillPenPreviewCount > 0)
                    {
                        turnOffFillPenPreviewCount = 0;
                    }
                }
                afterKeyUpOK = false;
            }
            function onMouseMoveFillPen(e:MouseEvent):void
            {
                const filteredPos:Point = CanvasController.getRefinedPoint(CanvasController.canvasDrawLayerChild.mouseX, CanvasController.canvasDrawLayerChild.mouseY);
                const mx:Number = filteredPos.x + pos05Offset;
                const my:Number = filteredPos.y + pos05Offset;
                if (lastPosOnMouseMove.x === mx && lastPosOnMouseMove.y === my)
                {
                    return;
                }
                lastPosOnMouseMove.setTo(mx, my);
                if (command.length === 0)
                {
                    command.push(1);
                    data.push(mx);
                    data.push(my);
                }
                else
                {
                    command.push(2);
                    data.push(mx);
                    data.push(my);
                }
                mouseMoveCount++;
                if (mouseMoveCount >= 6)
                {
                    mouseMoveCount = 0;
                    commandUndoIndexArr.push(command.length - 1);
                }
                lastMousePos.setTo(stage.mouseX, stage.mouseY);
                turnOffFillPenPreviewCount = 0;
                if (!FOFOTimer.hasTimer("previewFilledColorUpdateTimer"))
                {
                    FOFOTimer.addByName("previewFilledColorUpdateTimer", 0.1, false, showFillColor);
                }
            }
            function onMouseDownFillPen(e:MouseEvent):void
            {
                const target:DisplayObject = e.target as DisplayObject;
                if (!target)
                    return;
                const targetName:String = target.name;
                clickedButton = targetName;
                if (fillPenBox.visible)
                {
                    return;
                }
                if (SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(stage.mouseX, stage.mouseY))
                {
                    if (targetName === "penColorButton"
                            || targetName === "paperColorButton"
                            || targetName === "rgbInfoText")
                    {
                        return;
                    }
                    if (ColorPickerController.handleColorPickerBoxMouseDown(target) || ColorPickerController.numPadBox.visible)
                    {
                        return;
                    }
                    if (ColorPickerController.numPadBox.visible)
                    {
                        return;
                    }
                    switch (targetName)
                    {
                        case "toolRotate":
                            {
                                rotateTool(false);
                            }
                            return;
                        case "prevStageBG":
                        case "prevBitmapBG":
                        case "prevBitmap":
                            {
                                CanvasController.startCanvasMoveByCanvasNavigator(false);
                            }
                            return;
                        case "prevCursor":
                            {
                                CanvasController.startCanvasMoveByCanvasNavigator(true);
                            }
                            return;
                        case "toolZoomIn":
                        case "toolZoomOut":
                            {
                                ToolController.handleToolBoxClick(targetName);
                            }
                            return;
                        case "alphaButton1":
                        case "alphaButton2":
                        case "alphaButton3":
                        case "alphaButton4":
                        case "alphaButton5":
                        case "alphaButton6":
                        case "alphaButton7":
                        case "alphaButton8":
                        case "alphaButton9":
                        case "alphaButton10":
                            {
                                selectOpacityButton(targetName);
                            }
                            break;
                        default:
                            break;
                    }
                }
                if (targetName === "sideBarScrollBar")
                {
                    SidebarController.startScrollSidebarByDrag();
                }
                else if (isCursorInDrawArea() && SidebarController.isQuickSidebarActive === false)
                {
                    CanvasController.isMouseDragging = true;
                    stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);
                    const filteredPos:Point = CanvasController.getRefinedPoint(CanvasController.canvasDrawLayerChild.mouseX, CanvasController.canvasDrawLayerChild.mouseY);
                    const mx:Number = filteredPos.x + pos05Offset;
                    const my:Number = filteredPos.y + pos05Offset;
                    if (CanvasController.isLayer2Selected)
                    {
                        CanvasController.bringCanvasDrawLayerAboveLayer2();
                    }
                    if (lastPosOnMouseMove.x === mx && lastPosOnMouseMove.y === my)
                    {
                        FOFOTimer.remove("previewFilledColorUpdateTimer");
                        showFillColor();
                        return;
                    }
                    lastPosOnMouseMove.setTo(mx, my);
                    if (command.length === 0)
                    {
                        command.push(1);
                        data.push(mx);
                        data.push(my);
                    }
                    else
                    {
                        command.push(2);
                        data.push(mx);
                        data.push(my);
                    }
                    FOFOTimer.remove("previewFilledColorUpdateTimer");
                    showFillColor();
                }
            }
            function removeEvents():void
            {
                stage.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOverFillPenHint);
                stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownFillPen);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpFillPen);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownFillPen);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpFillPen);
                stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpFillPen);
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeydownFillPen);
            }
            function addEvents():void
            {
                stage.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverFillPenHint);
                stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownFillPen);
                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);
                stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpFillPen);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownFillPen);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpFillPen);
                stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpFillPen);
                stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeydownFillPen);
            }
            function start():void
            {
                isFillPenStarted = true;
                if (getFirstPressedKey() === KEY.q || getFirstPressedKey() === KEY.o)
                {
                    isStartedFromShortCut = true;
                }
                else
                {
                    isStartedFromShortCut = false;
                }
                canvasSizeRect.width = CanvasController.CANVAS_WIDTH;
                canvasSizeRect.height = CanvasController.CANVAS_HEIGHT;
                command = new Vector.<int>();
                data = new Vector.<Number>();
                if (ColorPickerController.isColorPickerModeBG)
                {
                    ColorPickerController.switchColorPickerModePen();
                }
                mouseMoveCount = 0;
                afterKeyUpOK = false;
                pos05Offset = ToolController.getSharpLinePosOffset(1.0);
                xColor = (PenTool.isTransparentPenColor) ? CanvasController.CANVAS_BG_COLOR : PenTool.penColor;
                xAlpha = PenTool.penAlpha;
                xBlendMode = (PenTool.isTransparentPenColor) ? "erase" : null;
                commandUndoIndexArr[0] = 0;
                clickedButton = null;
                updateLastFillPenBoxButtonUsed(fillPenBox.fillPenOK as SimpleButton);
                if (ToolController.isPenAirBrushON || PenTool.isEraserAirBrushON)
                {
                    CanvasController.canvasDrawLayerChild.filters = [];
                }
                if (!PenTool.isTransparentPenColor)
                {
                    if (!ColorPickerController.isCurrentColorSamePickedColor())
                    {
                        ColorPickerController.updatePickerCurrentColor(ColorPickerController.colorPickerBox.getRGBInfoBGColor());
                        PaletteController.addColorMyPaletteHistory(ColorPickerController.colorPickerBox.getRGBInfoBGColor());
                    }
                }
                if (ReferenceLayerController.isRefLayerMenuON)
                {
                    ReferenceLayerController.refLayerMenuBox.visible = false;
                }
                dottedLine.setLineScale(CanvasController.canvasZoomMultipler);
                const filteredPos:Point = CanvasController.getRefinedPoint(CanvasController.canvasDrawLayerChild.mouseX, CanvasController.canvasDrawLayerChild.mouseY);
                var mx:Number = filteredPos.x + pos05Offset;
                var my:Number = filteredPos.y + pos05Offset;
                lastPosOnMouseMove.setTo(mx, my);
                command.push(1);
                data.push(mx);
                data.push(my);
                lastMousePos.setTo(mx, my);
                CanvasController.canvasDrawLayer.alpha = xAlpha;
                ToolController.toolBox.setFillPenModeON();
                ToolController.toolOptionsBox.disableButtonFillPenStarted();
                ColorPickerController.colorPickerBox.fillPenModeON();
                addEvents();
            }
            return {
                    start: start
                };
        }


        public function onMouseMoveUpdatePenPreviewCursor(e:MouseEvent):void
        {
            if (ReplayController.isReplayModeON || CaptureController.isCaptureModeON)
                return;
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
        public function cRealWorkingTimer():Object
        {
            var workingTimer:Timer = new Timer(1000);
            var workingTime:int = 0;
            var lastTime:int = 0; // 마지막 시간 저장해줌
            // 시간 표시 관련 변수
            var tt:int;
            var hh:int;
            var mm:int;
            var ss:int;
            var lastMousePosX:Number = 0;
            var lastMousePosY:Number = 0;
            function reset():void
            {
                lastTime = getTimer();
                workingTime = 0;
                MainUI.topBar.timer.text = "00:00:00";
                MainUI.topBar.updateTimerPos(stage.stageWidth);
            }
            function setRunningTime(newTime:int):void
            {
                workingTime = newTime;
            }
            function getRunningTime():int
            {
                return workingTime;
            }
            function update():void
            {
                if (workingTime < 0)
                {
                    workingTime = 0;
                }
                tt = workingTime / 1000;
                hh = Math.floor(tt / 3600);
                mm = Math.floor((tt - hh * 3600) / 60);
                ss = Math.floor(tt % 60);
                MainUI.topBar.timer.text = ((hh < 10) ? "0" + hh : "" + hh)
                    + ":" + ((mm < 10) ? "0" + mm : "" + mm)
                    + ":" + ((ss < 10) ? "0" + ss : "" + ss);
                MainUI.topBar.timerAFkDot.visible = false;
                MainUI.topBar.updateTimerPos(stage.stageWidth);
            }
            function onTimer():Boolean
            {
                const nowTime:int = getTimer();
                const subTime:int = nowTime - lastTime;
                if (!stage.nativeWindow.active
                        || (!CanvasController.isMouseClicked && !CanvasController.isRightMouseClicked && !isKeyPressed()
                            && stage.mouseX === lastMousePosX && stage.mouseY === lastMousePosY))
                {
                    MainUI.topBar.timerAFkDot.visible = !MainUI.topBar.timerAFkDot.visible;
                    MainUI.topBar.updateTimerPos(stage.stageWidth);
                }
                else
                {
                    workingTime += subTime;
                    update();
                }
                lastMousePosX = stage.mouseX;
                lastMousePosY = stage.mouseY;
                lastTime = nowTime;
                return true;
            }
            function stop():void
            {
                if (workingTimer !== null)
                {
                    workingTimer.stop();
                    workingTimer.removeEventListener(TimerEvent.TIMER, onTimer);
                    workingTimer = null;
                }
            }
            function start():void
            {
                workingTimer.addEventListener(TimerEvent.TIMER, onTimer);
                workingTimer.start();
            }
            return {
                    start: start,
                    stop: stop,
                    reset: reset,
                    update: update,
                    getRunningTime: getRunningTime,
                    setRunningTime: setRunningTime
                };
        }


        public function checkGeneralKeyUp(keyCode:uint):void
        {
            if (KEY_BUFFER.length === 0)
            {
                resetLastKey();
            }
            else if (!CaptureController.isCaptureModeON && !ReplayController.isReplayModeON && isLastKey(keyCode))
            {
                LassoTool.onKeyDownLassoTool(null);
            }
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
            stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownStage, false, 1);
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpStage, false, 1);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpStage, false, 1);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownStage, false, 1);
            stage.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, onMiddleMouseDownStage, false, 1);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownStage, false, 1);
            stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpStage, false, 1);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveUpdatePenPreviewCursor);
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseMoveUpdatePenPreviewCursor, false, -1);
            stage.addEventListener(Event.MOUSE_LEAVE, onMouseLeaveStage, false);
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
        public function checkInvalidKey():void
        {
            const len:uint = KEY_BUFFER.length;
            for (var i:int = 0;i < len;i++)
            {
                if (KEY_BUFFER[i] === 229
                        || KEY_BUFFER[i] === 241
                        || KEY_BUFFER[i] === 242)
                {
                    clearKeyBuffer();
                    return;
                }
            }
            if (len >= 2)
            {
                if ((KEY_BUFFER[0] === 18 && KEY_BUFFER[1] === 32)
                        || (KEY_BUFFER[0] === 32 && KEY_BUFFER[1] === 18))
                {
                    clearKeyBuffer();
                }
            }
        }
        public function getPressedKeyCount():int
        {
            return KEY_BUFFER.length;
        }
        public function isKeyPressed():Boolean
        {
            return KEY_BUFFER.length > 0;
        }
        public function getLastKey():int
        {
            return KEY_BUFFER[KEY_BUFFER.length - 1];
        }
        public function isTwoKeyPressed():Boolean
        {
            return KEY_BUFFER.length === 2;
        }
        public function isPressdKey(key:int):int
        {
            return KEY_BUFFER.lastIndexOf(key);
        }
        public function getFirstPressedKey():int
        {
            return KEY_BUFFER[0];
        }
        public function getSecondPressedKey():int
        {
            return KEY_BUFFER[1];
        }
        public function onKeyUpStage(e:KeyboardEvent):void
        {
            tryDisableIME();
            checkInvalidKey();
            const index:int = isPressdKey(e.keyCode);
            if (index > -1)
            {
                KEY_BUFFER.splice(index, 1);
            }
        }
        public function onKeyDownStage(e:KeyboardEvent):void
        {
            tryDisableIME();
            checkInvalidKey();
            const keyCode:uint = e.keyCode;
            if (keyCode === KEY.window)
            {
                return;
            }
            if (keyCode === KEY.tab || keyCode === KEY.alt)
            {
                e.preventDefault();
            }
            if (KEY_BUFFER.lastIndexOf(keyCode) === -1)
            {
                KEY_BUFFER.push(keyCode);
            }
        }





        public function removeInputEventsDrawMode():void
        {
            isDrawModeInputEventsAdded = false;
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownDrawMode);
            stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpDrawMode);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownDrawMode);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpDrawMode, false);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownDrawMode);
            ColorPickerController.colorPickerBox.rgbInfoText.removeEventListener(MouseEvent.MOUSE_DOWN, ColorPickerController.onMouseDownRGBInfoText);
            // stage.removeEventListener(MouseEvent.MOUSE_OVER,lassoMenuHintONEvent);
        }
        public function addInputEventsDrawMode():void
        {
            if (isDrawModeInputEventsAdded === false)
            {
                isDrawModeInputEventsAdded = true;
                // resetKeyBuffer();
                stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpDrawMode, false, -1);
                stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownDrawMode, false, -1);
                stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownDrawMode, false, -1);
                stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpDrawMode, false, -1);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownDrawMode, false, -1);
                ColorPickerController.colorPickerBox.rgbInfoText.addEventListener(MouseEvent.MOUSE_DOWN, ColorPickerController.onMouseDownRGBInfoText);
            }
        }

        public function removeInputEventsToolBox2():void
        {
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, ToolController.onRightMouseUpToolBox2);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN, ToolController.onMouseDownToolBox2);
            ToolController.toolBox2.removeEventListener(MouseEvent.MOUSE_OVER, ToolController.onMouseOverToolBox2);
            stage.removeEventListener(KeyboardEvent.KEY_UP, ToolController.onKeyUpToolBox2);
            addInputEventsDrawMode();
        }
        public function addInputEventsToolBox2(fromShortcut:Boolean):void
        {
            removeInputEventsDrawMode();
            if (fromShortcut)
            {
                ToolController.toolBox2.addEventListener(MouseEvent.MOUSE_OVER, ToolController.onMouseOverToolBox2, false, -2);
                stage.addEventListener(KeyboardEvent.KEY_UP, ToolController.onKeyUpToolBox2, false, -2);
            }
            else
            {
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, ToolController.onRightMouseUpToolBox2, false, -2);
            }
            stage.addEventListener(MouseEvent.MOUSE_DOWN, ToolController.onMouseDownToolBox2, false, -2);
        }













        // VERSION변수를 문자열로 변환, 변환할때 뒤에 .0이 붙었는지 까지 체크
        public function convertVersionString(version:Number):String
        {
            var verStr:String = version.toString();
            if (verStr && verStr.indexOf(".") === -1)
                verStr = verStr + ".0";
            return verStr;
        }
        public function enableIME():void
        {
            IME.enabled = true;
        }
        public function tryDisableIME():void
        {
            if (CaptureController.isCaptureStampTextFieldFocused)
            {
                IME.enabled = true;
                return;
            }
            if (Capabilities.hasIME && IME.enabled) // 다른 언어로 하면 자판 안먹어서 그냥 ime자체를안씀
            {
                IME.compositionAbandoned();
                IME.enabled = false;
            }
        }
        // 문자열을 소수 2번째 자리까지만 변환
        public function closeAboutBox():void
        {
            stage.removeEventListener(MouseEvent.MOUSE_DOWN, MainUIController.onAboutWindowMouseDown);
            CaptureController.removeInputEventCaptrueMode();
            ReplayController.removeInputEventsReplayMode();
            addInputEventsDrawMode();
            isAboutBoxOpened = false;
            aboutBox.visible = false;
            FOFOTimer.addByName("clickBlockTimer", 0.15, false, function ():void
                {
                    CanvasController.isMouseClickBlocked = false;
                });
        }
        public function updateAboutPanelCenterPos():void
        {
            aboutBox.x = Math.floor(stage.stageWidth / 2) + Math.floor(-aboutBox.width / 2);
            aboutBox.y = Math.floor((stage.stageHeight - 39) / 2) + Math.floor(-aboutBox.height / 2);
        }
        public function openAboutBox(welcome:Boolean):void
        {
            Utils.setAsTopChild(aboutBox);
            isAboutBoxOpened = true;
            CanvasController.isMouseClickBlocked = true;
            MainUI.hideBottomHint();
            removeInputEventsDrawMode();
            if (welcome === true)
            {
                aboutBox.resetAppButton.visible = false;
                FOFOTimer.addByName("openAboutPanelOFFTimer", 1.0, false, function ():void
                    {
                        stage.addEventListener(MouseEvent.MOUSE_DOWN, MainUIController.onAboutWindowMouseDown);
                    });
            }
            else
            {
                removeInputEventsDrawMode();
                aboutBox.resetAppButton.visible = true;
                AppUpdater.checkUpdate();
                stage.addEventListener(MouseEvent.MOUSE_DOWN, MainUIController.onAboutWindowMouseDown);
            }
            aboutBox.randomLogo();
            aboutBox.updateMemoryInfo(FileManager.getDriveUsageString());
            updateAboutPanelCenterPos();
            aboutBox.visible = true;
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

        //todo: 분야별로 분리해야
        public function handleMouseClick(targetName:String):void
        {
            if (isAboutBoxOpened)
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
                                closeAboutBox();
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
                                closeAboutBox();
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
                                CanvasController.isMouseClicked = false; // 리플레이 버튼 누르고 나서 단축키가 안먹는 현상이 이거임
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
                                openAboutBox(false);
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
                                if (LassoTool.isLassoToolStarted === true)
                                {
                                    LassoTool.cancelLassoTool();
                                }
                            }
                            break;
                        case "lassoLayerMerge":
                            {
                                if (LassoTool.lassoMenuBox.lassoLayerMerge.alpha === 1.0)
                                {
                                    LassoTool.mergeLayerByLassoTool();
                                }
                            }
                            break;
                        case "lassoLayerSwap":
                            {
                                if (LassoTool.lassoMenuBox.lassoLayerSwap.alpha === 1.0)
                                {
                                    LassoTool.swapLayerByLassoTool();
                                }
                            }
                            break;
                        case "lasso1pxUp":
                            {
                                LassoTool.move1PxLassoTool(LassoTool.LASSO_1PX_MOVE_UP);
                            }
                            break;
                        case "lasso1pxDown":
                            {
                                LassoTool.move1PxLassoTool(LassoTool.LASSO_1PX_MOVE_DOWN);
                            }
                            break;
                        case "lasso1pxLeft":
                            {
                                LassoTool.move1PxLassoTool(LassoTool.LASSO_1PX_MOVE_LEFT);
                            }
                            break;
                        case "lasso1pxRight":
                            {
                                LassoTool.move1PxLassoTool(LassoTool.LASSO_1PX_MOVE_RIGHT);
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


















public function addKeyRepeatEvents():void
        {
            stage.nativeWindow.addEventListener(Event.DEACTIVATE, removeKeyRepeatEvents);
            stage.addEventListener(MouseEvent.MOUSE_DOWN, removeKeyRepeatEvents);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, removeKeyRepeatEvents);
            stage.addEventListener(MouseEvent.MOUSE_UP, removeKeyRepeatEvents);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, removeKeyRepeatEvents);
            stage.addEventListener(KeyboardEvent.KEY_UP, removeKeyRepeatEvents);
        }
        public function removeKeyRepeatEvents(e:Object):void
        {
            FOFOTimer.remove("checkKeyRepeatStop");
            FOFOTimer.remove("keyHoldWaitTimer");
            FOFOTimer.remove("keyHoldRepeatTimer");
            stage.nativeWindow.removeEventListener(Event.DEACTIVATE, removeKeyRepeatEvents);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN, removeKeyRepeatEvents);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, removeKeyRepeatEvents);
            stage.removeEventListener(MouseEvent.MOUSE_UP, removeKeyRepeatEvents);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, removeKeyRepeatEvents);
            stage.removeEventListener(KeyboardEvent.KEY_UP, removeKeyRepeatEvents);
        }






public function updateCanvasBGColor(xCanvas:Sprite, w:Number, h:Number, color:uint):void
        {
            xCanvas.graphics.clear();
            xCanvas.graphics.beginFill(color);
            xCanvas.graphics.drawRect(0, 0, w, h);
            xCanvas.graphics.endFill();
        }
public function isHintAvailableWithFillPen(target:DisplayObject):Boolean
        {
            const targetName:String = target.name;
            if (isFillPenStarted)
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

public function finalizeLoadFile(width:uint, height:uint, imageData:IBitmapDrawable, imageData1:IBitmapDrawable, imageOnlyFlag:Boolean, newBG:uint):void
        {
            if (!imageData)
            {
                FileManager.showLoadFaildMouseHint();
                return;
            }
            var maxLength:Number = (width > height) ? width : height;
            var scaleFix:Number = (maxLength > CanvasController.CANVAS_MAX_SIZE) ? CanvasController.CANVAS_MAX_SIZE / maxLength : 1.0;
            const scaledwidth:Number = Math.floor(width * scaleFix);
            const scaledheight:Number = Math.floor(height * scaleFix); // CANVAS_MAX_SIZE 값을 넘으면 리사이즈 해줌
            var scaleMat:Matrix = new Matrix();
            scaleMat.scale(scaleFix, scaleFix);
            var tmpbmpd:BitmapData = new BitmapData(scaledwidth, scaledheight, true, 0);
            if (CaptureController.isCaptureModeON)
            {
                CaptureController.handleExitCaptureMode();
            }
            ReplayController.resetReplaySpeedBar();
            ReplayController.resetReplayTime();
            ReplayController.clearCanvasReplayMode();
            ReplayController.updateReplayPrograssText(true, 0);
            MainUI.seekBarBox.resetReplayPrograssBarWidth();
            ColorPickerController.updateCanvasBGColorDrawMode(newBG);
            ReplayController.updateCanvasBGColorReplayMode(newBG);
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowBGColor(CanvasController.CANVAS_BG_COLOR, ImageViewWindow.canvasWindowLayer1Bitmap.bitmapData);
            }
            // FileManager.updateLastFilePathByRandomFileName();
            FileManager.isContinueSaveON = false; // 연속 세이브 플래그 취소
            ReplayController.rMirrorON = false;
            CanvasController.isCanvasMirrored = false;
            mirrorCommandReady = false;
            CanvasController.canvasInfoBox.setMirror(false);
            CanvasGridOverlay.updateGridMirror(false);
            if (LassoTool.isLassoToolStarted === true)
            {
                LassoTool.cancelLassoTool();
                LassoTool.resetLassoBox();
            }
            if (isFillPenStarted)
            {
                fillPenTool.cancel();
            }
            tmpbmpd.draw(imageData, scaleMat, null, null, null, true);
            CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, tmpbmpd, CanvasController.canvasLayer1Bitmap);
            if (imageOnlyFlag)
            {
                if (ReplayController.rFirstImageLayer1BitmapData && tmpbmpd !== ReplayController.rFirstImageLayer1BitmapData)
                    ReplayController.rFirstImageLayer1BitmapData.dispose();
                ReplayController.rFirstImageLayer1BitmapData = tmpbmpd.clone(); // 이미지만 불러와주면 첫 이미지를 갱신해줌
            }
            if (imageData1 !== null)
            {
                tmpbmpd.fillRect(new Rectangle(0, 0, scaledwidth, scaledheight), 0);
                tmpbmpd.draw(imageData1, scaleMat, null, null, null, true);
                CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, tmpbmpd, CanvasController.canvasLayer2Bitmap);
                if (imageOnlyFlag)
                {
                    ReplayController.rFirstImageLayer2BitmapData = tmpbmpd.clone();
                }
            }
            else
            {
                CanvasController.canvasLayer2BitmapData = new BitmapData(CanvasController.canvasLayer1BitmapData.width, CanvasController.canvasLayer1BitmapData.height, true, 0);
                CanvasController.canvasLayer2Bitmap.bitmapData = CanvasController.canvasLayer2BitmapData;
            }
            tmpbmpd.dispose();
            tmpbmpd = null;
            CanvasController.canvasAnchorPoint.rotation = 0;
            setRcursorRotation(0);
            CanvasController.canvasZoomIndex = 3;
            CanvasController.updateCanvasScale(1.0);
            CanvasController.updateCavnvasSizeDrawMode(scaledwidth, scaledheight, 0, 0, false);
            ReplayController.syncReplayCanvasImageWithDrawMode();
            ReplayController.syncReplayCanvasWithDrawMode();
            CanvasController.centerCanvas("draw");
            updatePenSizeCursor();
            if (CanvasGridOverlay.gridGapMultiplier > 0)
            {
                CanvasGridOverlay.drawGrid();
            }
            // bitmapdata가 갱신된이후에 업데이트 해줘야함
            UndoManager.resetUndoState();
            ReplayController.drawReplayByCommand.resetFirstRCursorPos();
            if (ReferenceLayerController.refLayerRawTransformData === null)
            {
                ReferenceLayerController.clearRefLayerImage();
            }
            else
            {
                ReferenceLayerController.canvasRefLayerBitmapData = ReferenceLayerController.refLayerRawBitmapData.clone();
                ReferenceLayerController.canvasRefLayerBitmap.bitmapData = ReferenceLayerController.canvasRefLayerBitmapData;
                ReferenceLayerController.updateRefLayerImageTransform(ReferenceLayerController.refLayerRawTransformData[4],
                        ReferenceLayerController.refLayerRawTransformData[5],
                        ReferenceLayerController.refLayerRawTransformData[6],
                        ReferenceLayerController.refLayerRawTransformData[7],
                        ReferenceLayerController.refLayerRawTransformData[8]);
                ReferenceLayerController.refLayerMenuDragXMoveSum = ReferenceLayerController.refLayerRawTransformData[10];
                ReferenceLayerController.refLayerLastAlpha = ReferenceLayerController.refLayerRawTransformData[11];
                ReferenceLayerController.canvasRefLayer.visible = true;
                ReferenceLayerController.canvasRefLayer.alpha = Utils.normalizeAlphaValue(ReferenceLayerController.refLayerRawTransformData[11]);
                ReferenceLayerController.updateRefLayerOpacityCursorPosByValue(ReferenceLayerController.refLayerRawTransformData[11]);
                ReferenceLayerController.refLayerRawBitmapData.dispose();
                ReferenceLayerController.refLayerRawBitmapData = null;
                ReferenceLayerController.refLayerRawTransformData = null;
                ReferenceLayerController.canvasRefLayerBitmap.smoothing = true;
            }
            MainUIController.updateWindowTitle();
            CanvasController.selectLayer1(false);
            ReplayController.selectReplaySubLayer(false);
            if (ToolController.toolOptionsBox.layer1CheckedButton.visible)
            {
                CanvasController.toggleLayer1Check();
            }
            if (ToolController.toolOptionsBox.layer2CheckedButton.visible)
            {
                CanvasController.toggleLayer2Check();
            }
            MainUIController.updateResizeButtonPos(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
            removeKeyRepeatEvents(null);
            CanvasController.canvasLayer1Bitmap.visible = true;
            CanvasController.canvasLayer2Bitmap.visible = true;
            MainUI.topBar.captureButton.alpha = 1.0;
            MainUI.topBar.newFileButton.alpha = 1.0;
            ReferenceLayerController.refLayerMenuBox.refTransferCanvasImageButton.alpha = 1.0;
            ColorPickerController.selectCurrentColor(false);
            ToolController.selectPenToolIfNotDrawingTool(false);
            CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
            MainUIController.updateCanvasNaigatorCursor();
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
                ImageViewWindow.canvasWindowIgnoreResizeEventFlag = true;
                ImageViewWindow.updateCanvasWindowBitmapSize();
            }
            CaptureController.resetCaptureCanvasChangeValue();
            FileManager.lastLoadedFile = null;
            FileManager.isLoadPendingAfterSaving = false;
            FileManager.closeLoadMenuBox();
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
        public function cDrawDone():Function
        {
            var drawLayerAlpha:ColorTransform = new ColorTransform();
            return function ():void
            {
                if (UndoManager.canAddUndoData === false)
                {
                    ReplayController.rDataBuffer = [];
                    CanvasController.canvasDrawLayerChild.graphics.clear();
                    return;
                }
                if (UndoManager.isDeepUndoEnabled)
                {
                    var rDataBufferSave:Array = ReplayController.rDataBuffer.concat();
                    UndoManager.applyDeepUndo();
                    ReplayController.rDataBuffer = rDataBufferSave;
                    rDataBufferSave = null;
                }
                UndoManager.canAddUndoData = false;
                if (PenTool.airBrushSizeDrawMode > 0)
                {
                    const blurSize:Number = CanvasController.getBlurSize(PenTool.airBrushSizeDrawMode, 1.0);
                    CanvasController.canvasDrawLayerChild.filters = [new BlurFilter(blurSize, blurSize, 3)];
                    CanvasController.canvasDrawLayerBitmapData.draw(CanvasController.canvasDrawLayerChild);
                    CanvasController.canvasDrawLayerChild.filters = [];
                }
                else
                {
                    CanvasController.canvasDrawLayerBitmapData.draw(CanvasController.canvasDrawLayerChild);
                }
                CanvasController.canvasDrawLayerBitmap.bitmapData = CanvasController.canvasDrawLayerBitmapData;
                CanvasController.updateCanvasDrawLayerCliprect();
                CanvasController.extandCanvasDrawLayerCliprect(); // 그린 영역을 100% 다 포함하지 않아서 약간 늘려줌
                if (ToolController.isSelectedToolPenOrLine() || ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
                {
                    drawLayerAlpha.alphaMultiplier = PenTool.penAlpha;
                    if (CanvasController.isLayer2Selected)
                        CanvasController.canvasLayer2BitmapData.draw(CanvasController.canvasDrawLayerBitmap, null, drawLayerAlpha, (PenTool.isTransparentPenColor) ? "erase" : null, CanvasController.canvasDrawLayerClipRect);
                    else
                        CanvasController.canvasLayer1BitmapData.draw(CanvasController.canvasDrawLayerBitmap, null, drawLayerAlpha, (PenTool.isTransparentPenColor) ? "erase" : null, CanvasController.canvasDrawLayerClipRect);
                }
                else if (ToolController.isSelectedTool(ToolController.TOOL_ERASER))
                {
                    drawLayerAlpha.alphaMultiplier = PenTool.eraserAlpha;
                    if (CanvasController.isLayer2Selected)
                        CanvasController.canvasLayer2BitmapData.draw(CanvasController.canvasDrawLayerBitmap, null, drawLayerAlpha, "erase", CanvasController.canvasDrawLayerClipRect);
                    else
                        CanvasController.canvasLayer1BitmapData.draw(CanvasController.canvasDrawLayerBitmap, null, drawLayerAlpha, "erase", CanvasController.canvasDrawLayerClipRect);
                }
                ReplayController.rDataBuffer.push(["drawDone5", CanvasController.isLayer2Selected]);
                if (CanvasController.isLayer2Selected)
                    CanvasController.canvasLayer2Bitmap.bitmapData = CanvasController.canvasLayer2BitmapData;
                else
                    CanvasController.canvasLayer1Bitmap.bitmapData = CanvasController.canvasLayer1BitmapData;
                CanvasController.canvasDrawLayerBitmapData.fillRect(CanvasController.canvasDrawLayerClipRect, 0); // 그려준 영역만
                CanvasController.canvasDrawLayerChild.graphics.clear();
                UndoManager.addUndoData.addNew();
            };
        }
        public function cLineTool():Function
        {
            const toDeg:Number = 180 / Math.PI;
            // const oldPoint:Point = new Point(0,0);
            var oldX:Number;
            var oldY:Number;
            var startPoint:Point = new Point();
            var endPoint:Point = new Point();
            var canvasSizeWidth:Number;
            var canvasSizeHeight:Number;
            var xSize:uint;
            var xColor:uint;
            var xAlpha:Number;
            var xShape:Boolean;
            var xBlendMode:String;
            var xAirBrushON:Boolean;
            var mouseMovedFlag:Boolean;
            var subLayerFlag:Boolean;
            function isTwoLineIntersection(x1:Number, y1:Number, x2:Number, y2:Number, x3:Number, y3:Number, x4:Number, y4:Number):Boolean
            {
                var denominator:Number = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1);
                var numerator1:Number = (x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3);
                var numerator2:Number = (x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3);
                if (denominator == 0)
                {
                    // 두 선분이 평행하거나 일치함
                    return false;
                }
                var t1:Number = numerator1 / denominator;
                var t2:Number = numerator2 / denominator;
                if (t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1)
                {
                    // 두 선분이 교차함
                    return true;
                }
                else
                {
                    // 두 선분이 교차하지 않음
                    return false;
                }
            }
            // 중앙선+양옆선 3개의 선이 캔버스 4개의 선과 하나라도 닿으면 true를 반환함
            function isLineInsideCanvas():Boolean
            {
                if (CanvasController.canvasPanel.hitTestPoint(stage.mouseX, stage.mouseY, true))
                {
                    return true;
                }
                else
                {
                    const sideLine1:Array = getSideLine(startPoint.x, startPoint.y, endPoint.x, endPoint.y, xSize / 2, xShape);
                    const sideLine2:Array = getSideLine(startPoint.x, startPoint.y, endPoint.x, endPoint.y, -xSize / 2, xShape);
                    if (checkCollision(startPoint.x, startPoint.y, endPoint.x, endPoint.y)
                            || checkCollision(sideLine1[0], sideLine1[1], sideLine1[2], sideLine1[3])
                            || checkCollision(sideLine2[0], sideLine2[1], sideLine2[2], sideLine2[3]))
                    {
                        return true;
                    }
                }
                return false;
            }
            function checkCollision(x1:Number, y1:Number, x2:Number, y2:Number):Boolean
            {
                return isTwoLineIntersection(x1, y1, x2, y2, 0, 0, canvasSizeWidth, 0)
                    || isTwoLineIntersection(x1, y1, x2, y2, 0, 0, 0, canvasSizeHeight)
                    || isTwoLineIntersection(x1, y1, x2, y2, 0, canvasSizeHeight, canvasSizeWidth, canvasSizeHeight)
                    || isTwoLineIntersection(x1, y1, x2, y2, canvasSizeWidth, 0, canvasSizeWidth, canvasSizeHeight);
            }
            function getSideLine(x1:Number, y1:Number, x2:Number, y2:Number, distance:Number, squareCapFlag:Boolean):Array
            {
                // 길이를 약간 늘려줌
                if (!squareCapFlag)
                {
                    const pointVec:Array = extendLineSegment(x1, y1, x2, y2, Math.abs(distance));
                    x1 = pointVec[0];
                    y1 = pointVec[1];
                    x2 = pointVec[2];
                    y2 = pointVec[3];
                }
                // 선분의 방향 벡터
                var directionX:Number = x2 - x1;
                var directionY:Number = y2 - y1;
                // 선분의 방향 벡터를 정규화
                var magnitude:Number = Math.sqrt(directionX * directionX + directionY * directionY);
                var normalizedDirectionX:Number = directionX / magnitude;
                var normalizedDirectionY:Number = directionY / magnitude;
                var newDirectionX:Number = -normalizedDirectionY;
                var newDirectionY:Number = normalizedDirectionX;
                // 새로운 선분의 시작점과 끝점을 계산
                var newLineStartX:Number = x1 + distance * newDirectionX;
                var newLineStartY:Number = y1 + distance * newDirectionY;
                var newLineEndX:Number = x2 + distance * newDirectionX;
                var newLineEndY:Number = y2 + distance * newDirectionY;
                return [newLineStartX, newLineStartY, newLineEndX, newLineEndY];
            }
            // 선분 시작 끝점을 distance로 늘려서 좌표를 반환함
            function extendLineSegment(x1:Number, y1:Number, x2:Number, y2:Number, distance:Number):Array
            {
                // 선분의 방향 벡터 계산
                var directionX:Number = x2 - x1;
                var directionY:Number = y2 - y1;
                // 방향 벡터의 길이 계산
                var length:Number = Math.sqrt(directionX * directionX + directionY * directionY);
                // 방향 벡터를 정규화
                directionX /= length;
                directionY /= length;
                // 양 끝점 좌표 이동
                var extendedX1:Number = x1 - directionX * distance;
                var extendedY1:Number = y1 - directionY * distance;
                var extendedX2:Number = x2 + directionX * distance;
                var extendedY2:Number = y2 + directionY * distance;
                return [extendedX1, extendedY1, extendedX2, extendedY2];
            }
            function showDgreeHint():void
            {
                const ang:Number = Math.atan2(oldX - CanvasController.canvasDrawLayerChild.mouseX, oldY - CanvasController.canvasDrawLayerChild.mouseY);
                var deg:Number = ang * toDeg + 90;
                if (deg > 180)
                {
                    deg = deg - 90;
                }
                var degstr:String = Math.abs(deg % 90).toFixed(1) + "°";
                MainUI.showMouseHint(degstr);
            }
            function drawLine():void // 지우개인가 펜인가 구분해서 lineto 실시
            {
                CanvasController.canvasDrawLayerChild.graphics.clear();
                CanvasController.canvasDrawLayer.alpha = xAlpha;
                if (xShape)
                {
                    CanvasController.canvasDrawLayerChild.graphics.lineStyle(xSize, xColor, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND);
                }
                else
                {
                    CanvasController.canvasDrawLayerChild.graphics.lineStyle(xSize, xColor);
                }
                CanvasController.canvasDrawLayerChild.graphics.moveTo(startPoint.x, startPoint.y);
                CanvasController.canvasDrawLayerChild.graphics.lineTo(endPoint.x, endPoint.y);
            }
            function onMouseMoveLineTool(e:MouseEvent):void
            {
                if (!mouseMovedFlag)
                {
                    mouseMovedFlag = true;
                }
                const mx:Number = CanvasController.canvasDrawLayerChild.mouseX;
                const my:Number = CanvasController.canvasDrawLayerChild.mouseY;
                if (xShape === true)
                {
                    const extPoints:Array = extendLineSegment(oldX, oldY, mx, my, xSize / 8);
                    startPoint.setTo(extPoints[0], extPoints[1]);
                    endPoint.setTo(extPoints[2], extPoints[3]);
                }
                else
                {
                    startPoint.setTo(oldX, oldY);
                    endPoint.setTo(mx, my);
                }
                drawLine();
                showDgreeHint();
            }
            function onMouseUpLineTool(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveLineTool);
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpLineTool);
                CanvasController.isPenSizeCursorInvisible = false;
                if (!ReferenceLayerController.isRefLayerEmpty() && ReferenceLayerController.isRefLayerMemoryTrainingON && ReferenceLayerController.refLayerLastAlpha > 0.0)
                {
                    ReferenceLayerController.setCanvasRefLayerVisibleDelay();
                }
                CanvasController.isMouseDragging = false;
                MainUI.hideMouseHint();
                if (isLineInsideCanvas() === true)
                {
                    const mx:Number = CanvasController.canvasDrawLayerChild.mouseX;
                    const my:Number = CanvasController.canvasDrawLayerChild.mouseY;
                    UndoManager.canAddUndoData = true;
                    if (mouseMovedFlag === false && oldX === mx && oldY === my)
                    {
                        ReplayController.rDataBuffer = [];
                        ReplayController.rDataBuffer.push(["dot4", xShape, xSize, xColor, xAlpha, mx, my, xBlendMode, subLayerFlag, xAirBrushON, CanvasController.canvasAnchorPoint.rotation]);
                        dotTool(xShape, xSize, xColor, mx, my, CanvasController.canvasAnchorPoint.rotation);
                    }
                    else
                    {
                        if (xShape === true)
                        {
                            const extPoints:Array = extendLineSegment(oldX, oldY, mx, my, xSize / 8);
                            startPoint.setTo(extPoints[0], extPoints[1]);
                            endPoint.setTo(extPoints[2], extPoints[3]);
                        }
                        else
                        {
                            startPoint.setTo(oldX, oldY);
                            endPoint.setTo(mx, my);
                        }
                        ReplayController.rDataBuffer.push(["line3", xShape, xSize, xColor, xAlpha, startPoint.x, startPoint.y, endPoint.x, endPoint.y, xBlendMode, subLayerFlag, PenTool.airBrushSizeDrawMode]);
                        drawLine();
                    }
                }
                CanvasController.resetCanvasDrawLayerCliprect();
                drawDone();
            }
            return function (lineToolFlag:Boolean):void
            {
                CanvasController.isPenSizeCursorInvisible = true;
                xSize = PenTool.penSize;
                xAlpha = PenTool.penAlpha;
                xShape = PenTool.penIsSquare;
                xAirBrushON = ToolController.isPenAirBrushON;
                if (PenTool.isTransparentPenColor)
                {
                    xColor = CanvasController.CANVAS_BG_COLOR;
                    xBlendMode = "erase";
                }
                else
                {
                    xColor = PenTool.penColor;
                    xBlendMode = null;
                    if (!ColorPickerController.isCurrentColorSamePickedColor())
                    {
                        ColorPickerController.updatePickerCurrentColor(ColorPickerController.colorPickerBox.getRGBInfoBGColor());
                        PaletteController.addColorMyPaletteHistory(ColorPickerController.colorPickerBox.getRGBInfoBGColor());
                    }
                }
                canvasSizeWidth = CanvasController.CANVAS_WIDTH;
                canvasSizeHeight = CanvasController.CANVAS_HEIGHT;
                mouseMovedFlag = false;
                oldX = CanvasController.canvasDrawLayerChild.mouseX;
                oldY = CanvasController.canvasDrawLayerChild.mouseY;
                subLayerFlag = CanvasController.isLayer2Selected;
                if (!ReferenceLayerController.isRefLayerEmpty() && ReferenceLayerController.isRefLayerMemoryTrainingON)
                {
                    ReferenceLayerController.setCanvasRefLayerInvisible();
                }
                // 캔버스2번 지워주고, draw판넬 데이터도 지워줌
                CanvasController.canvasDrawLayerBitmapData.dispose();
                CanvasController.canvasDrawLayerBitmap.bitmapData = null;
                CanvasController.canvasDrawLayerBitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
                // 선 관련 이벤트 함수 붙여줌
                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveLineTool);
                stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpLineTool);
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
        public function cCanvasRotateTool():Function
        {
            var isReplayMode:Boolean;
            var xAnc:Sprite;
            var getAngle:Function;
            function onMouseMove():void
            {
                const ang:Number = getAngle(true);
                xAnc.rotation = ang;
                setRcursorRotation(xAnc.rotation);
                CanvasController.canvasInfoBox.setRotate(Math.abs(xAnc.rotation));
            }

            function onMouseUp():void
            {
                CanvasController.isPenSizeCursorInvisible = false;
                if (!isReplayMode)
                {
                    if (LassoTool.isLassoToolStarted)
                    {
                        if (LassoTool.isLassoMenuHiddenTemp === true)
                        {
                            LassoTool.hideLassoMenuBoxTemp();
                        }
                    }
                    updatePenSizeCursor();
                    ReferenceLayerController.setRefLayerAndGridVisible(true);
                    MainUIController.updateCanvasNaigatorCursor();
                }
                else
                {
                    if (ReplayController.isReplayCanvasFitToWindow)
                    {
                        ReplayController.fitReplayCanvasToViewport();
                    }
                    resetLastKey();
                    ReplayController.rFollowMouse.updateBounds();
                }
                MainUI.hideCanvasRotateCursor();
                CanvasController.keepCanvasPanelInStage(isReplayMode);
            }
            function onDragStart():void
            {
                CanvasController.isPenSizeCursorInvisible = true;
                if (!isReplayMode)
                {
                    ReferenceLayerController.setRefLayerAndGridVisible(false);
                }
                const center:Point = MainUIController.getStageCenterPos("replay");
                CanvasController.moveCanvasAnchorPoint(center.x, center.y, isReplayMode);
                // 캔버스 이동이 완료된후 함수를 초기화 시켜줌
                MainUI.hideBottomHint();
            }
            return function (fromReplayMode:Boolean):void
            {
                isReplayMode = fromReplayMode;
                xAnc = (isReplayMode) ? ReplayController.rCanvasAnchorPoint : CanvasController.canvasAnchorPoint;
                getAngle = MainUI.showCanvasRotateCursorMouseDrag(xAnc);
                DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
            };
        }
        public function cMoveTool():Function
        {
            var getMovedPos:Function;
            function onMouseUpMoveTool(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveMovetool);
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpMoveTool);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpMoveTool);
                CanvasController.isMouseDragging = false;
                CanvasController.isPenSizeCursorInvisible = false;
                getMovedPos = null;
                var tmpbmpd:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
                const movex:Number = Math.floor(CanvasController.canvasLayer1Bitmap.x);
                const movey:Number = Math.floor(CanvasController.canvasLayer1Bitmap.y);
                const movex1:Number = Math.floor(CanvasController.canvasLayer2Bitmap.x);
                const movey1:Number = Math.floor(CanvasController.canvasLayer2Bitmap.y);
                var movedMat:Matrix = new Matrix();
                if (UndoManager.isDeepUndoEnabled)
                    UndoManager.applyDeepUndo();
                // 최종적으로 움직인 거리를 실제로 비트맵 데이터 조작
                if (CanvasController.checkedLayer === 0)
                {
                    if (CanvasController.canvasLayer1Bitmap.visible)
                    {
                        movedMat.translate(movex, movey);
                        tmpbmpd.draw(CanvasController.canvasLayer1BitmapData, movedMat);
                        CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, tmpbmpd, CanvasController.canvasLayer1Bitmap);
                    }
                    if (CanvasController.canvasLayer2Bitmap.visible)
                    {
                        movedMat = new Matrix();
                        movedMat.translate(movex1, movey1);
                        tmpbmpd.fillRect(new Rectangle(0, 0, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT), 0);
                        tmpbmpd.draw(CanvasController.canvasLayer2BitmapData, movedMat);
                        CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, tmpbmpd, CanvasController.canvasLayer2Bitmap);
                    }
                }
                else if (CanvasController.checkedLayer === 1)
                {
                    movedMat.translate(movex, movey);
                    tmpbmpd.draw(CanvasController.canvasLayer1BitmapData, movedMat);
                    CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, tmpbmpd, CanvasController.canvasLayer1Bitmap);
                }
                else if (CanvasController.checkedLayer === 2)
                {
                    movedMat = new Matrix();
                    movedMat.translate(movex1, movey1);
                    tmpbmpd.fillRect(new Rectangle(0, 0, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT), 0);
                    tmpbmpd.draw(CanvasController.canvasLayer2BitmapData, movedMat);
                    CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, tmpbmpd, CanvasController.canvasLayer2Bitmap);
                }
                tmpbmpd.dispose();
                tmpbmpd = null;
                CanvasController.canvasLayer1Bitmap.x = 0;
                CanvasController.canvasLayer1Bitmap.y = 0;
                CanvasController.canvasLayer2Bitmap.x = 0;
                CanvasController.canvasLayer2Bitmap.y = 0;
                if (LassoTool.isLassoToolStarted === false)
                {
                    var command:String = "move";
                    if (CanvasController.checkedLayer === 1)
                    {
                        command = "move1";
                        ReplayController.rDataBuffer.push([command, movex, movey]);
                    }
                    else if (CanvasController.checkedLayer === 2)
                    {
                        command = "move2";
                        ReplayController.rDataBuffer.push([command, movex1, movey1]);
                    }
                    else
                    {
                        if (!CanvasController.canvasLayer2Bitmap.visible)
                        {
                            command = "move1";
                            ReplayController.rDataBuffer.push([command, movex, movey]);
                        }
                        else if (!CanvasController.canvasLayer1Bitmap.visible)
                        {
                            command = "move2";
                            ReplayController.rDataBuffer.push([command, movex1, movey1]);
                        }
                        else
                        {
                            ReplayController.rDataBuffer.push([command, movex, movey]);
                        }
                    }
                    if (ReplayController.hasLastRDataCommand(command))
                        UndoManager.addUndoData.addContinue();
                    else
                        UndoManager.addUndoData.addNew();
                }
            }
            function onMouseMoveMovetool(e:MouseEvent):void
            {
                const pos:Point = getMovedPos();
                if (CanvasController.checkedLayer === 0)
                {
                    if (CanvasController.canvasLayer1Bitmap.visible)
                    {
                        CanvasController.canvasLayer1Bitmap.x = pos.x;
                        CanvasController.canvasLayer1Bitmap.y = pos.y;
                    }
                    if (CanvasController.canvasLayer2Bitmap.visible)
                    {
                        CanvasController.canvasLayer2Bitmap.x = pos.x;
                        CanvasController.canvasLayer2Bitmap.y = pos.y;
                    }
                }
                else if (CanvasController.checkedLayer === 1)
                {
                    CanvasController.canvasLayer1Bitmap.x = pos.x;
                    CanvasController.canvasLayer1Bitmap.y = pos.y;
                }
                else if (CanvasController.checkedLayer === 2)
                {
                    CanvasController.canvasLayer2Bitmap.x = pos.x;
                    CanvasController.canvasLayer2Bitmap.y = pos.y;
                }
            }
            return function ():void
            {
                if (CanvasController.isAllLayerInvisible())
                    return;
                getMovedPos = Utils.updateImagePosMouseDrag(CanvasController.canvasLayer1Bitmap, CanvasController.canvasAnchorPoint.rotation);
                CanvasController.isPenSizeCursorInvisible = true;
                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveMovetool);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpMoveTool);
                stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpMoveTool);
            };
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
        public function cZoomTool():Function
        {
            const zoomMaxIndex:uint = CanvasController.canvasZoomMultiplerList.length - 1;
            const clickPos:Point = new Point(0, 0);
            const lastMousePos:Point = new Point(0, 0);
            const mouseMoveStep:int = 26; // 이 픽셀이상움직일때만 zoomcanvas를 실행
            var lastZoom:Number = 0.0;
            var startZoomIndex:int = 0;
            var dragDirection:int = 0; // 1이면 x축
            function fixMouseHintPos():void
            {
                MainUI.mouseHint.x = clickPos.x - MainUI.mouseHint.width / 2;
                MainUI.mouseHint.y = clickPos.y - 35 * Global.getUIScale();
            }
            function zoomToolMouseMoveEvent2(dist:Number):void
            {
                if (dist > mouseMoveStep)
                {
                    startZoomIndex--;
                }
                else
                {
                    startZoomIndex++;
                }
                if (startZoomIndex < 0)
                {
                    startZoomIndex = 0;
                }
                else if (startZoomIndex > zoomMaxIndex)
                {
                    startZoomIndex = zoomMaxIndex;
                }
                const zoomValue:Number = CanvasController.canvasZoomMultiplerList[startZoomIndex];
                CanvasController.canvasZoomIndex = startZoomIndex;
                CanvasController.updateCanvasScale(zoomValue, false);
                MainUI.showMouseHint(Math.floor(zoomValue * 100) + "%");
                fixMouseHintPos();
            }
            function onMouseMove():void
            {
                var abs:Function = Math.abs;
                var mx:Number = stage.mouseX;
                var my:Number = stage.mouseY;
                if (dragDirection === 0)
                {
                    if (abs(mx - lastMousePos.x) > 20)
                    {
                        dragDirection = 1;
                        lastMousePos.x = stage.mouseX;
                    }
                    else if (abs(my - lastMousePos.y) > 20)
                    {
                        dragDirection = 2;
                        lastMousePos.y = stage.mouseY;
                    }
                }
                else if (dragDirection === 1)
                {
                    const subX:Number = lastMousePos.x - mx;
                    if (abs(subX) > mouseMoveStep)
                    {
                        lastMousePos.x = stage.mouseX;
                        zoomToolMouseMoveEvent2(subX);
                    }
                }
                else if (dragDirection === 2)
                {
                    const subY:Number = my - lastMousePos.y;
                    if (abs(subY) > mouseMoveStep)
                    {
                        lastMousePos.y = stage.mouseY;
                        zoomToolMouseMoveEvent2(subY);
                    }
                }
            }
            function onMouseUp():void
            {
                CanvasController.isMouseDragging = false;
                CanvasController.isPenSizeCursorInvisible = false;
                MainUI.hideMouseHint();
                updatePenSizeCursor();
                ReferenceLayerController.setRefLayerAndGridVisible(true);
                if (LassoTool.isLassoMenuHiddenTemp === true)
                {
                    LassoTool.hideLassoMenuBoxTemp();
                }
                MainUIController.updateCanvasNaigatorCursor();
                if (CanvasGridOverlay.gridGapMultiplier > 0 && lastZoom !== CanvasController.canvasZoomMultipler)
                {
                    CanvasGridOverlay.drawGrid();
                }
            }
            return function ():void
            {
                function onDragStart():void
                {
                    lastZoom = CanvasController.canvasZoomMultipler;
                    dragDirection = 0;
                    // 클릭한 위치가 캔버스밖을 벗어날경우 줌 기준점을 캔버스 경계선에 닿도록 함
                    var gp:Point;
                    if (LassoTool.isLassoMenuHiddenTemp === true)
                    {
                        gp = LassoTool.lassoLayer1.localToGlobal(new Point(0, 0));
                        CanvasController.moveCanvasAnchorPoint(gp.x, gp.y, false);
                    }
                    else
                    {
                        gp = CanvasController.canvasPanel.localToGlobal(new Point(0, 0));
                        const panelLimitedPos:Point = getCanvasBoundLimitPoint(CanvasController.canvasPanel, CanvasController.canvasPanel.mouseX, CanvasController.canvasPanel.mouseY, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, CanvasController.canvasZoomMultipler, -CanvasController.canvasAnchorPoint.rotation);
                        // 캔버스 0,0점이 글로벌좌표 기준으로 어느 위치에 있는지 더해줘야함
                        CanvasController.moveCanvasAnchorPoint(panelLimitedPos.x + gp.x, panelLimitedPos.y + gp.y, false);
                    }
                    lastMousePos.setTo(stage.mouseX, stage.mouseY);
                    startZoomIndex = CanvasController.canvasZoomIndex;
                    CanvasController.isPenSizeCursorInvisible = true;
                    ReferenceLayerController.setRefLayerAndGridVisible(false);
                    clickPos.setTo(stage.mouseX, stage.mouseY);
                    MainUI.showMouseHint(Math.floor(CanvasController.canvasZoomMultipler * 100) + "%");
                    fixMouseHintPos();
                }
                DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
            };
        }
        // 비트맵 데이터를 대칭으로 돌려줌
        public function mirrorDraw():void
        {
            var tmpbmpd:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
            var flipMat:Matrix = new Matrix(-1, 0, 0, 1, CanvasController.CANVAS_WIDTH);
            tmpbmpd.draw(CanvasController.canvasLayer1BitmapData, flipMat);
            CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, tmpbmpd, CanvasController.canvasLayer1Bitmap);
            tmpbmpd.fillRect(new Rectangle(0, 0, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT), 0);
            tmpbmpd.draw(CanvasController.canvasLayer2BitmapData, flipMat);
            CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, tmpbmpd, CanvasController.canvasLayer2Bitmap);
            tmpbmpd.dispose();
            tmpbmpd = null;
            CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
            }
        }

public function cEyeDropperTool():Function
        {
            // 일단 흰색으로 배경 깔아줌
            const magSize:Number = eyedropperLens.magSize;
            const lensRect:Rectangle = new Rectangle(0, 0, magSize, magSize);
            const lensMat:Matrix = new Matrix();
            var penColorBackup:uint;
            var canvasBGShape:Shape = new Shape();
            function updateEyeDropperLensBitmap():void
            {
                const mid:Number = magSize / (4 * CanvasController.canvasZoomMultipler); // 4는 기본 중앙값 magsize/2에서 zoomed나워주고 기본이 2배줌이니까 2로 나눠준값
                const tx:Number = -CanvasController.canvasLayer1Bitmap.mouseX + mid;
                const ty:Number = -CanvasController.canvasLayer1Bitmap.mouseY + mid;
                lensMat.identity();
                lensMat.translate(tx, ty);
                lensMat.scale(2.0 * CanvasController.canvasZoomMultipler, 2.0 * CanvasController.canvasZoomMultipler);
                eyedropperLens.bitmap.bitmapData.fillRect(lensRect, MainUIController.STAGE_BG_COLOR);
                eyedropperLens.bitmap.bitmapData.draw(canvasBGShape, lensMat, null, null, lensRect);
                if (CanvasController.canvasLayer2Bitmap.visible)
                {
                    eyedropperLens.bitmap.bitmapData.draw(CanvasController.canvasLayer2Bitmap.bitmapData, lensMat, null, null, lensRect);
                }
                if (CanvasController.canvasLayer1Bitmap.visible)
                {
                    eyedropperLens.bitmap.bitmapData.draw(CanvasController.canvasLayer1Bitmap.bitmapData, lensMat, null, null, lensRect);
                }
            }
            function pickColor():uint
            {
                if (CanvasController.canvasLayer1Bitmap.hitTestPoint(stage.mouseX, stage.mouseY))
                {
                    // 배경색
                    const r3:uint = (CanvasController.CANVAS_BG_COLOR & 0xFF0000) >> 16;
                    const g3:uint = (CanvasController.CANVAS_BG_COLOR & 0x00FF00) >> 8;
                    const b3:uint = (CanvasController.CANVAS_BG_COLOR & 0x0000FF);
                    var aa:Number = 0;
                    var rr:uint = 0;
                    var gg:uint = 0;
                    var bb:uint = 0;
                    var a1:Number = 0;
                    var r1:uint = 0;
                    var g1:uint = 0;
                    var b1:uint = 0;
                    var a2:Number = 0;
                    var r2:uint = 0;
                    var g2:uint = 0;
                    var b2:uint = 0;
                    // 위 레이어
                    if (CanvasController.canvasLayer1Bitmap.visible)
                    {
                        const c1:uint = CanvasController.canvasLayer1BitmapData.getPixel32(CanvasController.canvasLayer1Bitmap.mouseX, CanvasController.canvasLayer1Bitmap.mouseY);
                        a1 = ((c1 & 0xFF000000) >>> 24) / 255;
                        r1 = (c1 & 0x00FF0000) >>> 16;
                        g1 = (c1 & 0x0000FF00) >>> 8;
                        b1 = (c1 & 0x000000FF);
                    }
                    // 밑 레이어
                    if (CanvasController.canvasLayer2Bitmap.visible)
                    {
                        const c2:uint = CanvasController.canvasLayer2BitmapData.getPixel32(CanvasController.canvasLayer1Bitmap.mouseX, CanvasController.canvasLayer1Bitmap.mouseY);
                        a2 = ((c2 & 0xFF000000) >>> 24) / 255;
                        r2 = (c2 & 0x00FF0000) >>> 16;
                        g2 = (c2 & 0x0000FF00) >>> 8;
                        b2 = (c2 & 0x000000FF);
                    }
                    // source over S 새로그린거 B는 원래 그려져 있던거
                    // aR : the union alpha (as + ab * (1 - as)) //알파 혼합
                    // r: ((S.r * S.a) + (B.r * B.a) * (1 - S.a)) / aR,
                    // g: ((S.g * S.a) + (B.g * B.a) * (1 - S.a)) / aR,
                    // b: ((S.b * S.a) + (B.b * B.a) * (1 - S.a)) / aR,
                    // 아래 레이어 부터
                    aa = 1.0 - a2;
                    rr = Math.round(r2 * a2) + Math.round(r3 * aa);
                    gg = Math.round(g2 * a2) + Math.round(g3 * aa);
                    bb = Math.round(b2 * a2) + Math.round(b3 * aa);
                    // 그 위에 위 레이어
                    const aa1:Number = 1.0 - a1;
                    const r:uint = Math.round(r1 * a1) + Math.round(rr * aa1);
                    const g:uint = Math.round(g1 * a1) + Math.round(gg * aa1);
                    const b:uint = Math.round(b1 * a1) + Math.round(bb * aa1);
                    return Global.RGBtoHEX(r, g, b);
                }
                else
                {
                    return penColorBackup;
                }
            }
            function onRightMouseDownEyeDropper(e:MouseEvent):void
            {
                exitEyeDropperTool(false);
            }
            function onKeyDownEyeDropper(e:KeyboardEvent):void
            {
                if (isNotEyeDropperTool())
                {
                    exitEyeDropperTool(false);
                    return;
                }
                if (e.keyCode === KEY.c || e.keyCode === KEY.m) {}
                else if (e.keyCode === KEY.space)
                {
                    if (PenTool.isTransparentPenColor)
                    {
                        ColorPickerController.selectCurrentColor(false);
                        MainUI.showMouseHintTemp("Current color selected");
                    }
                    else
                    {
                        ColorPickerController.selectCurrentColor(false);
                        if (PenTool.isTransparentPenColor === false)
                        {
                            ColorPickerController.selectTransparentColor();
                        }
                        MainUI.showMouseHintTemp("Transparent color selected");
                    }
                    exitEyeDropperTool(false);
                }
                else
                {
                    exitEyeDropperTool(false);
                }
            }
            function onKeyUpEyeDropper(e:KeyboardEvent):void
            {
                if (isNotEyeDropperTool())
                {
                    exitEyeDropperTool(false);
                    return;
                }
                if (e.keyCode === KEY.c || e.keyCode === KEY.m)
                {
                    confirmEyeDropperSelection();
                }
            }
            function onMouseDownEyeDropper(e:MouseEvent):void
            {
                if (isNotEyeDropperTool())
                {
                    exitEyeDropperTool(false);
                    return;
                }
                if (eyedropperLens.visible)
                {
                    confirmEyeDropperSelection();
                }
                else
                {
                    exitEyeDropperTool(false);
                }
            }
            function exitEyeDropperTool(okFlag:Boolean):void
            {
                removeEyedropperEvents();
                eyedropperLens.visible = false;
                // canvasRefLayer.visible = true;
                canvasBGShape.graphics.clear();
                ReferenceLayerController.setRefLayerAndGridVisible(true);
                if (okFlag)
                {
                    if (!(ToolController.isLastTool(ToolController.TOOL_FILLPEN)
                                || ToolController.isLastTool(ToolController.TOOL_LINE)
                                || ToolController.isLastTool(ToolController.TOOL_PEN)))
                    {
                        ToolController.setLastTool(ToolController.TOOL_PEN);
                    }
                }
                ToolController.selectLastUsedTool();
            }
            function isNotEyeDropperTool():Boolean
            {
                return !ToolController.isSelectedTool(ToolController.TOOL_EYEDROPPER) || ReplayController.isReplayModeON || CaptureController.isCaptureModeON || FileManager.isFileBrowserOpened || CanvasController.isMouseClickBlocked;
            }
            function confirmEyeDropperSelection():void
            {
                var okFlag:Boolean = false;
                if (eyedropperLens.visible === true)
                {
                    okFlag = true;
                    const pickedColor:uint = pickColor();
                    PenTool.penColor = pickedColor;
                    ColorPickerController.pickerIgnoreHistoryColor = pickedColor;
                    ColorPickerController.updateColorPickerCursorPosAndRGBInfo(pickedColor);
                }
                exitEyeDropperTool(okFlag);
            }
            function onMouseMoveEyeDropper(e:MouseEvent):void
            {
                if (isNotEyeDropperTool())
                {
                    exitEyeDropperTool(false);
                    return;
                }
                eyedropperLens.x = stage.mouseX;
                eyedropperLens.y = stage.mouseY;
                if (canShowEyedropperLens())
                {
                    Global.setColorTransform(eyedropperLens.nowColor, pickColor());
                    if (CanvasController.canvasZoomMultipler < 12.0)
                    {
                        updateEyeDropperLensBitmap();
                    }
                    eyedropperLens.visible = true;
                }
                else
                {
                    eyedropperLens.visible = false;
                }
            }
            function removeEyedropperEvents():void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveEyeDropper);
                stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownEyeDropper);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownEyeDropper);
                stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpEyeDropper);
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownEyeDropper);
            }
            function addEyedropperEvents():void
            {
                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveEyeDropper);
                stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownEyeDropper, false, -2);
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownEyeDropper, false, -2);
                stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpEyeDropper, false, 2);
                stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownEyeDropper, false, 2);
            }
            function canShowEyedropperLens():Boolean
            {
                return isCursorInDrawArea() && CanvasController.canvasLayer1Bitmap.hitTestPoint(stage.mouseX, stage.mouseY, true)
                    && !(ReferenceLayerController.refLayerMenuBox.visible && ReferenceLayerController.refLayerMenuBox.hitTestPoint(stage.mouseX, stage.mouseY));
            }
            return function ():void
            {
                ToolController.toolBox.moveToolCursor("toolEyedropper");
                if (CanvasController.checkedLayer !== 0)
                {
                    return;
                }
                if (CanvasController.isAllLayerInvisible())
                {
                    return;
                }
                ToolController.updateLastTool();
                //todo: 이것도 그냥 setLastToolPen, setSeletedToolPen이런식으로 메서드로 호출
                ToolController.setLastTool(ToolController.nowTool);
                ToolController.setSelectedTool(ToolController.TOOL_EYEDROPPER);
                penColorBackup = PenTool.penColor;
                Global.setColorTransform(eyedropperLens.oldColor, PenTool.penColor);
                ToolController.moveEraserButtonToOtherTool("toolEyedropper");
                eyedropperLens.rotateBitmap(CanvasController.canvasAnchorPoint.rotation);
                ReferenceLayerController.setCanvasRefLayerInvisible();
                canvasBGShape.graphics.clear();
                canvasBGShape.graphics.beginFill(CanvasController.CANVAS_BG_COLOR);
                canvasBGShape.graphics.drawRect(0, 0, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
                if (canShowEyedropperLens())
                {
                    eyedropperLens.x = stage.mouseX;
                    eyedropperLens.y = stage.mouseY;
                    Global.setColorTransform(eyedropperLens.nowColor, pickColor());
                    Utils.setAsTopChild(eyedropperLens);
                    if (CanvasController.canvasZoomMultipler < 12.0)
                    {
                        eyedropperLens.circleBox.visible = true;
                        updateEyeDropperLensBitmap();
                    }
                    else
                    {
                        eyedropperLens.circleBox.visible = false;
                    }
                    eyedropperLens.visible = true;
                }
                addEyedropperEvents();
            };
        }
        public function cHandTool():Function
        {
            const old:Point = new Point(0, 0);
            var isReplayMode:Boolean;
            var isDrawMode:Boolean;
            var xAnc:Sprite;
            var xBitmap:Bitmap;
            function onMouseUpHandTool(e:MouseEvent):void
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHandTool);
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpHandTool);
                stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpHandTool);
                stage.removeEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMouseUpHandTool);
                CanvasController.isMouseDragging = false;
                CanvasController.isPenSizeCursorInvisible = false;
                CanvasController.keepCanvasPanelInStage(isReplayMode);
                if (isDrawMode)
                {
                    ReferenceLayerController.setRefLayerAndGridVisible(true);
                    if (LassoTool.isLassoToolStarted)
                    {
                        if (LassoTool.isLassoMenuHiddenTemp === true)
                        {
                            LassoTool.hideLassoMenuBoxTemp();
                        }
                    } // tool box에서 클릭해서 핸드툴 들어갈때 필요함
                    else if (!isLastKey(KEY.space))
                    {
                        ToolController.selectLastUsedTool();
                    }
                    ToolController.toolBox.setCursorVisible(true);
                    MainUIController.updateCanvasNaigatorCursor();
                }
                else
                {
                    ReplayController.rFollowMouse.updateBounds();
                }
            }
            function onMouseMoveHandTool(e:MouseEvent):void
            {
                if (isReplayMode && ReplayController.isReplayRestartTimerON())
                {
                    onMouseUpHandTool(null);
                    return;
                }
                xAnc.x += (stage.mouseX - old.x);
                xAnc.y += (mouseY - old.y);
                old.setTo(stage.mouseX, stage.mouseY);
            }
            return function (fromReplayMode:Boolean, fromWheelClick:Boolean):void
            {
                CanvasController.isMouseDragging = true;
                isReplayMode = fromReplayMode;
                isDrawMode = !fromReplayMode;
                xAnc = (isDrawMode) ? CanvasController.canvasAnchorPoint : ReplayController.rCanvasAnchorPoint;
                xBitmap = (isDrawMode) ? CanvasController.canvasLayer1Bitmap : ReplayController.rCanvasLayer1Bitmap;
                old.setTo(stage.mouseX, stage.mouseY);
                CanvasController.isPenSizeCursorInvisible = true;
                if (isDrawMode)
                {
                    ToolController.toolBox.setCursorVisible(false);
                    ReferenceLayerController.setRefLayerAndGridVisible(false);
                }
                if (fromWheelClick)
                {
                    stage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMouseUpHandTool);
                }
                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHandTool);
                stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpHandTool);
                // 윈도우 바깥에서 up을 하면 hand가 안꺼져서 오른쪽 마우스 뗄떼도 꺼주게함
                stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpHandTool);
            };
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
                case KEY.f:
                case KEY.h:
                    startKeyRepeat(true, ToolController.adjustDrawToolSizeByShortcut, true);
                    return true;
                case KEY.v:
                case KEY.n:
                    startKeyRepeat(true, ToolController.adjustDrawToolSizeByShortcut, false);
                    return true;
                case KEY.g:
                CanvasController.canvasPanel.x= savepos[0];
                CanvasController.canvasPanel.y= savepos[1];
                CanvasController.canvasAnchorPoint.x= savepos[2];
                CanvasController.canvasAnchorPoint.y= savepos[3];

                    startKeyRepeat(true, ToolController.adjustDrawToolAlphaByShortcut, true);
                    return true;
                case KEY.b:
                    startKeyRepeat(true, ToolController.adjustDrawToolAlphaByShortcut, false);
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

        public function cDrawDot():Function
        {
            const cmd:Vector.<int> = new Vector.<int>();
            const pos:Vector.<Number> = new Vector.<Number>();
            return function (shape:Boolean, size:uint, color:uint, posX:Number, posY:Number, rotation:Number):void
            {
                CanvasController.canvasDrawLayerChild.graphics.clear();
                CanvasController.canvasDrawLayerChild.graphics.lineStyle(0, 0, 0);
                CanvasController.canvasDrawLayerChild.graphics.beginFill(color);
                if (shape === true)
                {
                    cmd.length = 0;
                    pos.length = 0;
                    const p0:Point = Utils.rotatePoint(-size / 2, -size / 2, rotation);
                    cmd.push(1);
                    pos.push(posX + p0.x);
                    pos.push(posY + p0.y);
                    const p1:Point = Utils.rotatePoint(+size / 2, -size / 2, rotation);
                    cmd.push(2);
                    pos.push(posX + p1.x);
                    pos.push(posY + p1.y);
                    const p2:Point = Utils.rotatePoint(+size / 2, +size / 2, rotation);
                    cmd.push(2);
                    pos.push(posX + p2.x);
                    pos.push(posY + p2.y);
                    const p3:Point = Utils.rotatePoint(-size / 2, +size / 2, rotation);
                    cmd.push(2);
                    pos.push(posX + p3.x);
                    pos.push(posY + p3.y);
                    CanvasController.canvasDrawLayerChild.graphics.drawPath(cmd, pos);
                }
                else
                {
                    CanvasController.canvasDrawLayerChild.graphics.drawCircle(posX, posY, size / 2);
                }
                CanvasController.canvasDrawLayerChild.graphics.endFill();
            };
        }
public function loadAppState():void
        {
            const fs:FileStream = new FileStream();
            var arr:Array = [];
            var newRectangle:Rectangle;
            const firstCachedImage:File = FileManager.replayCacheImageFolderPath.resolvePath("0");
            // 앱 경로에 마지막 저장 파일이 있으면 끄기전의 상태로 세팅해줌
            if (firstCachedImage.exists)
            {
                fs.open(firstCachedImage, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();
                if (arr[1] is ByteArray === false)
                {
                    arr[0].uncompress();
                    newRectangle = new Rectangle(0, 0, arr[1], arr[2]);
                    if (ReplayController.rFirstImageLayer1BitmapData)
                        ReplayController.rFirstImageLayer1BitmapData.dispose();
                    ReplayController.rFirstImageLayer1BitmapData = new BitmapData(arr[1], arr[2], true, 0);
                    ReplayController.rFirstImageLayer1BitmapData.lock();
                    ReplayController.rFirstImageLayer1BitmapData.setPixels(newRectangle, arr[0]);
                    ReplayController.rFirstImageLayer1BitmapData.unlock();
                    if (ReplayController.rFirstImageLayer2BitmapData)
                        ReplayController.rFirstImageLayer2BitmapData.dispose();
                    ReplayController.rFirstImageLayer2BitmapData = new BitmapData(arr[1], arr[2], true, 0);
                    ReplayController.rFirstImageBGColor = arr[3];
                }
                else
                {
                    arr[0].uncompress();
                    newRectangle = new Rectangle(0, 0, arr[2], arr[3]);
                    if (ReplayController.rFirstImageLayer1BitmapData)
                        ReplayController.rFirstImageLayer1BitmapData.dispose();
                    ReplayController.rFirstImageLayer1BitmapData = new BitmapData(arr[2], arr[3], true, 0);
                    ReplayController.rFirstImageLayer1BitmapData.lock();
                    ReplayController.rFirstImageLayer1BitmapData.setPixels(newRectangle, arr[0]);
                    ReplayController.rFirstImageLayer1BitmapData.unlock();
                    arr[1].uncompress();
                    if (ReplayController.rFirstImageLayer2BitmapData)
                        ReplayController.rFirstImageLayer2BitmapData.dispose();
                    ReplayController.rFirstImageLayer2BitmapData = new BitmapData(arr[2], arr[3], true, 0);
                    ReplayController.rFirstImageLayer2BitmapData.lock();
                    ReplayController.rFirstImageLayer2BitmapData.setPixels(newRectangle, arr[1]);
                    ReplayController.rFirstImageLayer2BitmapData.unlock();
                    ReplayController.rFirstImageBGColor = arr[4];
                }
            }
            else
            {
                ReplayController.rFirstImageLayer1BitmapData.dispose();
                ReplayController.rFirstImageLayer2BitmapData.dispose();
                ReplayController.rFirstImageLayer1BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
                ReplayController.rFirstImageLayer2BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
            }
            if (ReferenceLayerController.refLayerImageFilePath.exists)
            {
                fs.open(ReferenceLayerController.refLayerImageFilePath, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();
                // arr[0].uncompress();
                newRectangle = new Rectangle(0, 0, arr[1], arr[2]);
                var tmpbmpd:BitmapData = new BitmapData(arr[1], arr[2], true, 0);
                tmpbmpd.lock();
                tmpbmpd.setPixels(newRectangle, arr[0]);
                tmpbmpd.unlock();
                ReferenceLayerController.canvasRefLayerBitmapData = CanvasController.updateBitmapData(ReferenceLayerController.canvasRefLayerBitmapData, tmpbmpd, ReferenceLayerController.canvasRefLayerBitmap);
                ReferenceLayerController.canvasRefLayerBitmap.smoothing = true;
                tmpbmpd.dispose();
                tmpbmpd = null;
            }
            if (FileManager.replayCacheImageFrameDataFilePath.exists)
            {
                fs.open(FileManager.replayCacheImageFrameDataFilePath, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();
                ReplayController.rJumpImageFrameData = arr.concat();
            }
            if (FileManager.myPaletteDataFilePath.exists)
            {
                fs.open(FileManager.myPaletteDataFilePath, FileMode.READ);
                var list:Array = fs.readObject();
                PaletteController.myPalettePreset = list.concat();
                list.length = 0;
                list = null;
            }
            if (FileManager.undoDataFilePath.exists)
            {
                UndoManager.loadUndoData(); // ReplayController.undo data 복구 먼저 해줘야함
            }
            if (FileManager.scratchPadDataFilePath.exists)
            {
                FileManager.loadScratchPadImage();
            }
            if (FileManager.appStateFilePath.exists)
            {
                fs.open(FileManager.appStateFilePath, FileMode.READ);
                const appStateObject:AppStateManager = fs.readObject() as AppStateManager;
                fs.close();
                // loadUndoData함수에서 canvaspanel이 호출되는데 이전에 reflayer 이미지 정보값을 넣어두어야함
                // 그냥 해주면 창크기 적용이 안되서 타이머 걸어줌
                FOFOTimer.addByName("loadAppDataDelayTimer", 0.2, false, function ():void
                {
                    stage.nativeWindow.width = appStateObject.stageNativeWindowWidth;
                    stage.nativeWindow.height = appStateObject.stageNativeWindowHeight;
                    stage.nativeWindow.x = appStateObject.stageNativeWindowX;
                    stage.nativeWindow.y = appStateObject.stageNativeWindowY;
                    MainUIController.lastAppWindowSize.width = appStateObject.stageNativeWindowWidth;
                    MainUIController.lastAppWindowSize.height = appStateObject.stageNativeWindowHeight;

                    // 캔버스 위치까지 전부 다해준 다음에 이전 상태가 풀스크린이었으면 세팅해줌
                    if (appStateObject.lastWindowState === 1)
                        stage.nativeWindow.maximize();

                    Global.setScaleIndex(appStateObject.uiScaleIndex);
                    MainUIController.applyUIScale();
                    Global.setUIColorIndex(appStateObject.uiColorIndex);
                    MainUIController.applyUIColorSet();

                    CanvasController.canvasZoomIndex = appStateObject.canvasZoomIndex;
                    CanvasController.updateCanvasScale(appStateObject.canvasZoomedMultiplier);
                    CanvasController.canvasPanel.x = appStateObject.canvasPanelX;
                    CanvasController.canvasPanel.y = appStateObject.canvasPanelY;
                    CanvasController.canvasAnchorPoint.x = appStateObject.canvasAnchorPointX;
                    CanvasController.canvasAnchorPoint.y = appStateObject.canvasAnchorPointY;
                    savepos[0] =appStateObject.canvasPanelX;
                    savepos[1] =appStateObject.canvasPanelY;
                    savepos[2] =appStateObject.canvasAnchorPointX;
                    savepos[3] =appStateObject.canvasAnchorPointY;
                    CanvasController.canvasAnchorPoint.rotation = appStateObject.canvasAnchorPointRotation;
                    setRcursorRotation(appStateObject.canvasAnchorPointRotation);
                    MainUIController.updateResizeButtonPos(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
                    CanvasController.canvasRotateCursor.rotateArrow.rotation = appStateObject.canvasAnchorPointRotation;

                    PenTool.penSmoothValue = appStateObject.penSmoothValue;
                    PenTool.penSmoothSlideValue = appStateObject.penSmoothSlideValue;
                    ToolController.toolOptionsBox.penSmoothSliderCursor.x = appStateObject.penSmoothButtonX;
                    PenTool.penSize = appStateObject.penSize;
                    PenTool.penColor = appStateObject.penColor;

                    ColorPickerController.hsvColorData[0] = appStateObject.hsvColorData0; // 순서 중요 이게 먼저오고 밑에 rgb info갱신해주어야함
                    ColorPickerController.isHSVInfoTextMode = appStateObject.isHSVInfoTextMode;
                    ColorPickerController.updatePickerCurrentColor(PenTool.penColor);
                    ColorPickerController.updateColorPickerCursorPosAndRGBInfo(PenTool.penColor);
                    ColorPickerController.colorPickerBox.updateHueColor(appStateObject.svBaseColor);
                    ColorPickerController.colorPickerBox.hueCursor.x = appStateObject.hueCursorX;

                    PenTool.penAlpha = appStateObject.penAlpha;
                    PenTool.penAlphaIndex = PenTool.penAlphaList.indexOf(appStateObject.penAlpha);
                    ToolController.updateDrawToolAlpha(appStateObject.penAlpha);
                    PenTool.penIsSquare = appStateObject.penIsSquare;
                    PenTool.penListShapeIsSqare = appStateObject.penIsSquare;
                    ToolController.toolOptionsBox.updatePenShapeSet(appStateObject.penIsSquare);

                    PenTool.eraserSize = appStateObject.eraseSize;
                    PenTool.eraserIsSquare = appStateObject.eraserIsSquare;
                    PenTool.eraserAlpha = appStateObject.eraseAlpha;
                    PenTool.eraserAlphaIndex = PenTool.penAlphaList.indexOf(appStateObject.eraseAlpha);
                    PenTool.eraserSizeIndex = appStateObject.eraseSizeIndex;
                    ToolController.setDrawToolSize(appStateObject.penSizeIndex);

                    FileManager.lastSaveFilePath = appStateObject.saveFilePath;
                    FileManager.lastSaveFileName = appStateObject.saveFileName;
                    if (FileManager.lastSaveFilePath === FileManager.lastSaveFileName)
                    {
                        FileManager.lastSaveFilePath = File.desktopDirectory.nativePath + File.separator + FileManager.lastSaveFileName;
                    }

                    realWorkingTimer.setRunningTime(appStateObject.appRunningTime);
                    realWorkingTimer.update();

                    ReferenceLayerController.refLayerLastAlpha = appStateObject.refLayerLastAlpha;
                    ReferenceLayerController.canvasRefLayer.alpha = appStateObject.refLayerLastAlpha;
                    ReferenceLayerController.refLayerMenuBox.refOpacityCursor.x = appStateObject.refOpacityCursorX;
                    ReferenceLayerController.refLayerMenuBox.x = appStateObject.refLayerMenuBox0;
                    ReferenceLayerController.refLayerMenuBox.y = appStateObject.refLayerMenuBox1;
                    ReferenceLayerController.refLayerMenuDragXMoveSum = appStateObject.refLayerMenuDragXMoveSum;

                    if (appStateObject.isRefLayerMemoryTrainingON)
                    {
                        ReferenceLayerController.isRefLayerMemoryTrainingON = false;
                        ReferenceLayerController.toggleRefLayerMemoryTraining();
                    }

                    SidebarController.isRightSidebar = appStateObject.isRightSidebar;
                    SidebarController.isSidebarVisible = appStateObject.isSidebarVisible;
                    if (appStateObject.isRightSidebar)
                        SidebarController.moveSideBar("right", true);
                    if (!appStateObject.isSidebarVisible)
                        SidebarController.hideSidebarPermanent();

                    ReplayController.rReplayImageCacheState = appStateObject.rReplayImageCacheState;
                    ReplayController.rLastCanvasBGColor = appStateObject.rLastCanvasBGColor;
                    ReplayController.drawReplayByCommand.setFirstRCursorPos(appStateObject.getFirstRCursorPosX, appStateObject.getFirstRCursorPosY);

                    ReferenceLayerController.updateRefLayerImageTransform(
                        appStateObject.canvasRefLayerBitmapX,
                        appStateObject.canvasRefLayerBitmapY,
                        appStateObject.canvasRefLayerRotation,
                        appStateObject.canvasRefLayerScaleX,
                        appStateObject.canvasRefLayerScaleY
                    );

                    if (CanvasController.isCanvasMirrored !== appStateObject.isCanvasMirrored)
                        CanvasController.mirrorCanvas(true);

                    CanvasGridOverlay.gridGapMultiplier = appStateObject.gridValue;
                    CanvasGridOverlay.gridDrawOffsetX = appStateObject.gridDrawOffsetX;
                    CanvasGridOverlay.gridDrawOffsetY = appStateObject.gridDrawOffsetY;
                    if (!CanvasGridOverlay.gridDrawOffsetX)
                        CanvasGridOverlay.gridDrawOffsetX = 0.0;
                    if (!CanvasGridOverlay.gridDrawOffsetY)
                        CanvasGridOverlay.gridDrawOffsetY = 0.0;
                    if (appStateObject.gridValue > 0)
                        CanvasGridOverlay.drawGrid();

                    if (appStateObject.canvasWindowON)
                    {
                        ImageViewWindow.canvasWindowInfo = [
                            appStateObject.newWindowInfo0,
                            appStateObject.newWindowInfo1,
                            appStateObject.newWindowInfo2,
                            appStateObject.newWindowInfo3
                        ];
                        ImageViewWindow.openImageViewWindow();
                        stage.nativeWindow.activate();
                    }

                    FileManager.isContinueSaveON = appStateObject.isContinueSaveON;
                    ReplayController.rDataIndex = UndoManager.undoDataIndex;
                    ReplayController.rNowFrame = UndoManager.getNowFrameUntilUndoIndex(UndoManager.undoDataIndex);
                    ReplayController.rPrevFrame = UndoManager.getNowFrameUntilUndoIndex(UndoManager.undoDataIndex - 1);

                    // 혹시 몰라서 위치 체크 해줌
                    CanvasController.canvasInfoBox.setRotate(CanvasController.canvasAnchorPoint.rotation);
                    CanvasController.centerCanvas("replay");
                    CanvasController.keepCanvasPanelInStage();
                    CanvasController.keepCanvasPanelInStage(true);

                    PaletteController.myPaletteSaveColorBeforeOtherType[0] = PenTool.penColor;
                    if (appStateObject.myPalettePresetType > 0)
                        ColorPickerController.activeColorPreset(appStateObject.myPalettePresetType);

                    PaletteController.updateHistoryList();
                    PaletteController.isMyPaletteExpended = appStateObject.isMyPaletteExpended;
                    if (PaletteController.myPalettePresetType === 0 && appStateObject.isMyPaletteExpended)
                    {
                        PaletteController.switchMyPaletteToExpended();
                    }
                    else
                    {
                        PaletteController.updateMyPaletteList();
                    }

                    ColorPickerController.isColorPickerBoxPositionSwapped = appStateObject.isColorPickerBoxPositionSwapped;
                    if (appStateObject.isColorPickerBoxPositionSwapped)
                    {
                        ColorPickerController.colorPickerBox.swapColorBoxPositions(appStateObject.isColorPickerBoxPositionSwapped);
                    }

                    SidebarController.sideBarScrollPanel.y = appStateObject.scrollSetMovedY;
                    MainUI.topBar.captureInput.text = appStateObject.captureStampText;
                    CaptureController.isCaptureStampEnabled = appStateObject.isCaptureStampON;
                    if (appStateObject.captureStampFont)
                    {
                        CaptureController.captureStampManager.changeFont(appStateObject.captureStampFont, false);
                    }

                    MainUIController.updateCanvasNaigatorCursor();
                    updatePenSizeCursor();
                    MainUIController.updateWindowTitle();
                    CanvasController.selectLayer1(false);
                });
            }
            else // 복원파일이 없을때
            {
                if (FileManager.lastSaveFilePath === FileManager.lastSaveFileName)
                {
                    FileManager.lastSaveFilePath = File.desktopDirectory.nativePath + File.separator + FileManager.lastSaveFileName;
                }
                PaletteController.initializeMyPaletteList();
                MainUIController.lastAppWindowSize.width = 1000;
                MainUIController.lastAppWindowSize.height = 800;
                FOFOTimer.add(0.3, true, function ():Boolean
                    {
                        if (stage.nativeWindow.width === 1000 && stage.nativeWindow.height === 800)
                        {
                            CanvasController.centerCanvas("draw");
                            return false;
                        }
                        stage.nativeWindow.width = MainUIController.lastAppWindowSize.width;
                        stage.nativeWindow.height = MainUIController.lastAppWindowSize.height;
                        return true;
                    });
                CanvasController.updateCavnvasSizeDrawMode(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, 0, 0, false);
                MainUIController.updateResizeButtonPos(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
                ColorPickerController.updatePickerCurrentColor(PenTool.penColor);
                ColorPickerController.updateColorPickerCursorPosAndRGBInfo(PenTool.penColor);
                openAboutBox(true);
                MainUIController.applyUIColorSet();
                MainUIController.updateCanvasNaigatorCursor();
                CanvasController.canvasInfoBox.init(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, Math.floor(CanvasController.canvasZoomMultipler * 100), CanvasController.canvasAnchorPoint.rotation, false);
                CanvasController.selectLayer1(false);
                PaletteController.initMyPaletteHistory();
            }
        }


public function onRightMouseDownDrawMode(e:MouseEvent):void // rdown1
{
    if (CanvasController.isMouseClicked || isKeyPressed() || isPressingControl() || SidebarController.isQuickSidebarActive
            || isFillPenStarted || ToolController.isSelectedTool(ToolController.TOOL_EYEDROPPER) || (ReferenceLayerController.isRefLayerMenuON && ReferenceLayerController.refLayerMenuBox.hitTestPoint(mouseX, mouseY))
            || FileManager.loadMenuBox.visible || MainUI.topBar.gridButtonWrapper.visible || ColorPickerController.numPadBox.visible)
    {
        return;
    }

    const targetName:String = e.target.name;
    switch (targetName)
    {
        case "saveButton":
            {
                FileManager.openSaveFileBrowser(true);
            }
            break;

        case "dpiButton":
            {
                if (Global.getScaleIndex() !== 0)
                {
                    Global.resetScaleIndex();
                    MainUIController.applyUIScale();
                    MainUI.showMouseHintTemp(Global.getUIScaleString());
                }
            }
            break;

        case "toolZoomIn":
        case "toolZoomOut":
            {
                if (CanvasController.canvasZoomMultipler !== 1.0)
                    CanvasController.resetZoomDrawMode();
            }
            break;

        case "gridButton":
            {
                if (CanvasGridOverlay.gridGapMultiplier !== 0)
                {
                    MainUI.hideBottomHint();
                    CanvasGridOverlay.resetGrid();
                }
            }
            break;

        case "toolRotate":
            {
                if (CanvasController.canvasAnchorPoint.rotation !== 0.0)
                {
                    resetRotationDrawMode();
                }
            }
            break;

        case "sideBarScrollBar":
            {
                SidebarController.resetSideBarPosition();
            }
            break;

        default:
            {
                if (isCursorInDrawArea())
                {
                    if (ToolController.isToolBox2Showing && !UndoManager.isDeepUndoEnabled)
                    {
                        ToolController.closeToolBox2();
                    }
                    else
                    {
                        ToolController.openToolBox2(false);
                    }
                }
            }
            break;
    }
}

public function onKeyUpDrawMode(e:KeyboardEvent):void // keyup1
        {
            const keyCode:uint = e.keyCode;
            if (isLastKey(keyCode))
            {
                if (CanvasController.isMouseClicked === true)
                {
                    CanvasController.isKeyReleasedBeforeMouseUp = true;
                }
                else if (isKeyPressed())
                {
                    onKeyDownDrawMode(null);
                }
                else
                {
                    isLayerCheckKeyPressed = false;
                    if (ToolController.lastTool > ToolController.TOOL_NONE)
                    {
                        ToolController.selectLastUsedTool();
                        ToolController.showNowToolIconToCursorTemp(ToolController.nowTool);
                    }
                    penCursorManager.check();
                }
            }
            if (!isKeyPressed())
            {
                resetLastKey();
            }
            if (!isPressingControl())
            {
                if (resizeCanvas.isResizing())
                {
                    resizeCanvas.exit(true);
                }
                if (MainUIController.resizeButtonR.visible)
                {
                    MainUIController.updateCanvasResizeButtonVisible(false);
                }
            }
        }
        public function checkSubKey(expectedLength:uint, updateFlag:Boolean, callback:Function):Boolean
        {
            if (getPressedKeyCount() !== expectedLength)
            {
                return false;
            }
            const subKey:uint = getLastKey();
            if (updateFlag)
            {
                updateLastKey(subKey);
            }
            if (callback !== null)
            {
                callback(subKey);
            }
            return true;
        }
        public function onKeyDownDrawMode(e:KeyboardEvent):void
        {
            if (CanvasController.isMouseClicked || CanvasController.isRightMouseClicked || CanvasController.isKeyReleasedBeforeMouseUp || isFillPenStarted
                    || MainUIController.isPopUpWindowOpened())
            {
                return;
            }
            const firstKey:uint = getFirstPressedKey();
            const secondKey:int = getSecondPressedKey();
            // 자툴이 nowkey를 쓰기 때문에 nowkey 리턴 이전에서 체크해야함
            if (isPressingControlShift())
            {
                // shift 누르고 ctrl 순서로 누를때 이전툴로 복원
                if (ToolController.isSelectedTool(ToolController.TOOL_LINE))
                {
                    ToolController.selectLastUsedTool();
                }
                checkSubKey(3, true, function (input:int):void
                    {
                        if (input === KEY.s)
                        {
                            FileManager.openSaveFileBrowser(true);
                        }
                    });
                return;
            }
            if (isPressingControl())
            {
                if (!checkSubKey(2, true, function (input:int):void
                        {
                            if (input === KEY.s)
                                {
                                    FileManager.openSaveFileBrowser(false);
                        }
                        else if (input === KEY.o)
                            {
                                FileManager.openLoadFileBrowser();
                    }
                    else if (input === KEY.c || input === KEY.comma)
                        {
                            CaptureController.enterCaptureMode();
                }
                else if (input === KEY.v || input === KEY.m)
                    {
                        if (ClipboardManager.isClipBoardButtonActivated)
                            {
                                ClipboardManager.tryLoadClipboardImage(false);
                    }
                }
            }))
            {
                if (resizeCanvas.isResizing() === false)
                {
                    MainUIController.updateCanvasResizeButtonVisible(true);
                }
                }
                return;
            }
            if (isPressingShift())
            {
                if (handlePenOpacitySizeKeyDown(secondKey))
                {
                    return;
                }
                else if (checkPenOptionsKeyDown(secondKey))
                {
                    return;
                }
                else if (checkSubKey(2, true, function (input:int):void
                        {
                            switch (input)
                                {
                                    case KEY.s:
                                    case KEY.k:
                                    {
                                        if (CanvasController.canvasAnchorPoint.rotation !== 0.0)
                                            {
                                                resetRotationDrawMode();
                                    }
                                }
                                return;
                        case KEY.w:
                        case KEY.i:
                        {
                            if (CanvasController.canvasZoomMultipler !== 1.0)
                                {
                                    CanvasController.resetZoomDrawMode();
                        }
                    }
                    return;
        }
        }))
        {
            return;
        }
        }
        if (isTwoKeyPressed())
        {
            // 지우개키 조합 따로 체크
            if (firstKey === KEY.d || firstKey === KEY.j)
            {
                if (handlePenOpacitySizeKeyDown(secondKey))
                {
                    return;
                }
                else if (secondKey === KEY.s || secondKey === KEY.k)
                {
                    if (SidebarController.isQuickSidebarActive === false)
                    {
                        SidebarController.activeQuickSideBar(true);
                    }
                    return;
                }
                else if (checkPenOptionsKeyDown(secondKey))
                {
                    return;
                }
            }
            else if (SidebarController.isPressingQuickSidebarShortcut(firstKey, secondKey))
            {
                if (SidebarController.isQuickSidebarActive === false)
                {
                    SidebarController.activeQuickSideBar(true);
                }
                return;
            }
            // 필펜 조합 체크
            else if (firstKey === KEY.q || firstKey === KEY.o)
            {
                if (handlePenOpacitySizeKeyDown(secondKey))
                {
                    return;
                }
                else if (checkPenOptionsKeyDown(secondKey))
                {
                    return;
                }
            }
        }
        if (isLastKey(firstKey))
        {
            return;
        }
        updateLastKey(firstKey);
        if (handlePenOpacitySizeKeyDown(firstKey))
        {
            return;
        }
        if (handleExtraKeyDown(firstKey))
        {
            return;
        }
        ToolController.handleToolKeyDown(firstKey);
        }
        public function handleExtraKeyDown(keyCode:int):Boolean
        {
            switch (keyCode)
            {
                case KEY.f1:
                case KEY.f7:
                    {
                        ReplayController.enterReplayMode();
                    }
                    return true;
                case KEY.n1:
                case KEY.n9:
                    {
                        if (CanvasController.isLayer2Selected)
                        {
                            MainUI.showMouseHintTemp("Layer 1 selected");
                            CanvasController.selectLayer1(false);
                        }
                        else
                        {
                            CanvasController.selectLayer1(CanvasController.canvasLayer2Bitmap.visible);
                            MainUI.showMouseHintLayerVisible();
                        }
                        if (ToolController.toolOptionsBox.layer2CheckedButton.visible)
                        {
                            CanvasController.toggleLayer2Check();
                        }
                    }
                    return true;
                case KEY.n2:
                case KEY.n0:
                    {
                        if (!CanvasController.isLayer2Selected)
                        {
                            MainUI.showMouseHintTemp("Layer 2 selected");
                            CanvasController.selectLayer2(false);
                        }
                        else
                        {
                            CanvasController.selectLayer2(CanvasController.canvasLayer1Bitmap.visible);
                            MainUI.showMouseHintLayerVisible();
                        }
                        if (ToolController.toolOptionsBox.layer1CheckedButton.visible)
                        {
                            CanvasController.toggleLayer1Check();
                        }
                    }
                    return true;
                case KEY.n3:
                case KEY.n8:
                    {
                        if (ToolController.toolOptionsBox.sharpLineButtonWrapper.alpha === 1.0)
                        {
                            ToolController.toggleSharpLineByShortcut();
                        }
                    }
                    return true;
                case KEY.n4:
                case KEY.n7:
                    {
                        if (ToolController.isSelectedToolPenOrLine() || ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
                        {
                            ToolController.togglePenAirBrushButtonShortCut();
                        }
                        else if (ToolController.isSelectedTool(ToolController.TOOL_ERASER))
                        {
                            ToolController.toggleEraseAirBrushButtonShortCut();
                        }
                    }
                    return true;
                case KEY.n6:
                    {
                        SidebarController.activeQuickSideBar(true);
                    }
                    break;
                    return true;
                case KEY.x:
                case KEY.comma:
                    {
                        startKeyRepeat(true, UndoManager.redo);
                        ToolController.showNowToolIconToCursorTemp(ToolController.TOOL_REDO);
                    }
                    return true;
                case KEY.z:
                case KEY.dot:
                    {
                        startKeyRepeat(true, UndoManager.undo);
                        ToolController.showNowToolIconToCursorTemp(ToolController.TOOL_UNDO);
                    }
                    return true;
                case KEY.tab:
                case KEY.backslash:
                    {
                        if (SidebarController.isSidebarVisible)
                        {
                            SidebarController.hideSidebarPermanent();
                        }
                        else
                        {
                            SidebarController.showSidebarPermanent();
                        }
                    }
                    return true;
            }
            return false;
        }

        public function unblockMouseClickAfterDelay():void
        {
            FOFOTimer.addByName("clickBlockTimer", 0.15, false, function ():void
                {
                    CanvasController.isMouseClickBlocked = false;
                });
        }

public function clearKeyBuffer():void
        {
            KEY_BUFFER.length = 0;
            resetLastKey();
        }

        // 키를 2개 이상 누르고 있을때 먼저 누른키를 떼면 다음키로 설정함
        public function onMouseUpDrawMode(e:MouseEvent):void // mouseup1
        {
            if (CanvasController.isKeyReleasedBeforeMouseUp) // 단축키 떼고 마우스 땠을때 원래대로 돌림
            {
                CanvasController.isKeyReleasedBeforeMouseUp = false;
                if (KEY_BUFFER.length > 0)
                {
                    onKeyDownDrawMode(null);
                }
                else
                {
                    resetLastKey();
                    if (ToolController.lastTool > ToolController.TOOL_NONE)
                    {
                        ToolController.selectLastUsedTool();
                    }
                    penCursorManager.check();
                }
            }
        }







        public function onMouseDownDrawMode(e:MouseEvent):void
        {
            if (isFillPenStarted || FileManager.loadMenuBox.visible
                    || MainUI.topBar.gridButtonWrapper.visible || ColorPickerController.numPadBox.visible)
            {
                return;
            }
            const target:DisplayObject = e.target as DisplayObject;
            if (!target)
            {
                return;
            }
            const targetName:String = target.name;
            if (SidebarController.sideBar.visible)
            {
                if (SidebarController.sideBarScrollPanel.hitTestPoint(stage.mouseX, stage.mouseY) && SidebarController.handleSidebarMouseDown(target))
                {
                    return;
                }
            }
            if (SidebarController.isQuickSidebarActive)
            {
                if (targetName === "sideBarScrollBar")
                {
                    SidebarController.startScrollSidebarByDrag();
                }
                return;
            }
            switch (targetName)
            {
                case "saveButton": // 아래 3개는 WorkspaceView.topbar메뉴에 가면 안됨 mouseuphandler랑 같이 연동되서 여기서 해주어야함
                case "loadButton":
                case "replayModeButton":
                case "captureButton":
                case "repCaptureButton":
                case "clipBoardButton":
                case "topBarColorButton":
                case "gridButton":
                case "penOptionButton":
                case "aboutButton":
                case "updateButton":
                case "sideBarPositionButton":
                case "sideBarPositionButton2":
                case "sideBarOFFButton":
                case "sideBarOFFButton2":
                case "sideBarONButton":
                case "sideBarONButton2":
                case "refMenuCloseButton":
                case "refTransferCanvasImageButton":
                case "refLoadImageButton":
                case "refMirrorImageButton":
                case "refMemoryTrainingOnButton":
                case "refMemoryTrainingOffButton":
                case "refClipBoardButton":
                case "appResetButton":
                case "dpiButton":
                case "newWindowButton":
                case "newWindowCloseButton":
                    {
                        if (ToolController.isToolBox2Showing || isKeyPressed() || e.target.alpha < 1.0)
                        {
                            return;
                        }
                        handleMouseClick(targetName);
                    }
                    return;
                case "replaySpeedSliderWrapper":
                    {
                        // grid 에서 불러줬을때 캔버스에 안무것도 못하게
                    }
                    return;
                case "refClearImageButton":
                    {
                        if (ReferenceLayerController.isRefLayerEmpty())
                        {
                            ReferenceLayerController.showRefLayerIsEmptyHint();
                        }
                        else
                        {
                            startPressHoldKey(ReferenceLayerController.refLayerMenuBox.refClearImageButton, "Erasing reference image...", null, ReferenceLayerController.startReflayerClear, null);
                        }
                    }
                    return;
                case "timer":
                    {
                        startPressHoldKey(MainUI.topBar.timer, HintStrings.getResetTimerHintString(), null, realWorkingTimer.reset, null);
                    }
                    return;
                case "newFileButton":
                    {
                        if (MainUI.topBar.newFileButton.alpha === 1.0 && !BackgroundWorkerCoordinator.isSaveInProgress)
                        {
                            FileManager.createNewFile(false);
                        }
                    }
                    return;
                case "resizeButtonR":
                case "resizeButtonD":
                case "resizeButtonL":
                case "resizeButtonU":
                    {
                        CanvasController.startCanvasResizing(targetName);
                    }
                    return;
                case "sideBarScrollBar":
                    {
                        SidebarController.startScrollSidebarByDrag();
                    }
                    return;
                case "refRotateImageButton":
                    {
                        Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                        if (ReferenceLayerController.isRefLayerEmpty())
                        {
                            ReferenceLayerController.showRefLayerIsEmptyHint();
                        }
                        else
                        {
                            ReferenceLayerController.startRefLayerRotation();
                        }
                    }
                    return;
                case "refMoveImageButton":
                    {
                        Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                        if (ReferenceLayerController.isRefLayerEmpty())
                        {
                            ReferenceLayerController.showRefLayerIsEmptyHint();
                        }
                        else
                        {
                            ReferenceLayerController.startRefLayerImageDrag();
                        }
                    }
                    return;
                case "refResizeImageButton":
                    {
                        Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                        if (ReferenceLayerController.isRefLayerEmpty())
                        {
                            ReferenceLayerController.showRefLayerIsEmptyHint();
                        }
                        else
                        {
                            ReferenceLayerController.startRefLayerImageScale();
                        }
                    }
                    return;
                case "refOpacitySliderWrapper":
                    {
                        Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                        if (ReferenceLayerController.isRefLayerEmpty())
                        {
                            ReferenceLayerController.showRefLayerIsEmptyHint();
                        }
                        else
                        {
                            ReferenceLayerController.startRefLayerOpacityDrag();
                        }
                    }
                    return;
                case "refLayerMenuMoveButton":
                    {
                        DragInteraction.startBoxDrag(ReferenceLayerController.refLayerMenuBox);
                    }
                    return;
                case "dragDropFileBG":
                    return;
            }
            // 캔버스 영역 밖에서는 해주지 않음
            if (isCursorInDrawArea() && !CanvasController.isMouseClickBlocked)
            {
                switch (ToolController.nowTool)
                {
                    case ToolController.TOOL_PEN:
                        if (CanvasController.isToolEnabledByLayerUnChecked())
                            PenTool.start();
                        break;
                    case ToolController.TOOL_FILLPEN:
                        if (CanvasController.isToolEnabledByLayerUnChecked())
                            fillPenTool.start();
                        break;
                    case ToolController.TOOL_ERASER:
                        if (CanvasController.isToolEnabledByLayerUnChecked())
                            PenTool.startWithEraserMode();
                        break;
                    case ToolController.TOOL_LINE:
                        if (CanvasController.isToolEnabledByLayerUnChecked())
                            lineTool(true);
                        break;
                    case ToolController.TOOL_LASSO:
                        LassoTool.lassoToolFunction.start();
                        break;
                    case ToolController.TOOL_MOVE:
                        moveTool();
                        break;
                        // 캔버스 조작
                    case ToolController.TOOL_ZOOM:
                        zoomTool();
                        break;
                    case ToolController.TOOL_HAND:
                        handTool(false, false);
                        break;
                    case ToolController.TOOL_ROTATE:
                        rotateTool(false);
                        break;
                }
            }
        }
    }
}
