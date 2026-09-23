package Modules
{
    import Modules.Tools.HandTool;
    import Modules.Tools.LassoTool;
    import Modules.Tools.LineTool;
    import Modules.Tools.MoveTool;
    import Modules.Tools.PenTool;
    import Modules.Tools.RotateTool;
    import Modules.Tools.ZoomTool;

    import flash.display.DisplayObject;
    import flash.display.SimpleButton;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.system.Capabilities;
    import flash.system.IME;
    import flash.globalization.LastOperationStatus;
    import worker.BackgroundImageProcessor;

    public class InputController
    {
        // todo 툴이나 기능별로 키보드 마우스 입력 분리하기, 이후에 코드 포맷팅해주기
        // todo 툴 전역 입력 이벤트 빼고 툴관련 이벤트 핸들러도 같이 들어가있는지 확인
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static const KEY:Object = {
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

        public static const KEY_REPEAT_START_DELAY:Number = 0.3;
        public static const KEY_REPEAT_INTERVAL:Number = 0.06;
        // 키 누름 관련
        public static var lastPressedKey:int = -1; // 마지막 누른거 여기다가 저장 반복호출되는 keydown 함수에서 한번만 호출되게 하는변수
        public static const keyBuffer:Array = []; // 정식 키 다운 눌러준 상태에서 다른 키가 눌러져 있으면 여기다가 저장
        public static const COMMAND_CTRL:int = (1 << 0);
        public static const COMMAND_SHIFT:int = (1 << 1);
        public static const COMMAND_CTRL_SHIFT:int = (1 << 2);

        // 키 오래누름 관련 변수
        public static var pressHoldCountDownTime:Number = 0.0;
        public static var pressHoldFrameCount:int = 0;

        // todo 이거 쓰나?
        public static var isLayerCheckKeyPressed:Boolean = false;
        public static var isDrawModeInputEventsAdded:Boolean = false;
        public static var isCaptureModeInputEventsAdded:Boolean = false; // 이벤트 세트가 켜지거나 꺼지는거 보관 중복 이벤트 추가 피하려고
        public static var isReplayModeInputEventsAdded:Boolean = false; // 리플레이 이벤트 추가되면 올려줌

        public static function startScratchPadResetTimer(target:DisplayObject):void
        {
            FOFOTimer.addByName("clearScratchPadTimer", 0.4, false, function ():void
                {
                    startPressHoldKey(target, "Clearing scratch pad..", null, ColorPickerController.colorPickerBox.scratchPad.clearPad, null);
                });
        }

        public static function startPressHoldKey(button:DisplayObject, hintStr:String, readyFunc:Function, okFunc:Function, cancelFunc:Function):void
        {
            if (!FOFOTimer.hasTimer("pressholdtimer"))
            {
                var keyBufferLenSave:uint = getPressedKeyCount();
                var mouseClickONSave:Boolean = CanvasController.isMouseLeftClicked;
                var rightMouseClickONSave:Boolean = CanvasController.isRightMouseClicked;
                const countDownTime:Number = 3;
                const countDownTimeNow:Number = Math.ceil((main.stage.frameRate * 2.5) / countDownTime);
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
                        if (CanvasController.isMouseLeftClicked !== mouseClickONSave
                                || CanvasController.isRightMouseClicked !== rightMouseClickONSave
                                || keyBufferLenSave !== getPressedKeyCount()
                                || (button && button.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false))
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

        public static function updateLastKey(key:int):void
        {
            lastPressedKey = getLastPressedKey();
        }

        public static function resetLastKey():void
        {
            lastPressedKey = -1;
        }

        public static function isLastKey(key:uint):Boolean
        {
            return lastPressedKey === key;
        }

        public static function startKeyRepeatStopTimerOnMouseLeave(target:DisplayObject):void
        {
            FOFOTimer.addByName("checkKeyRepeatStop", 0.0, true, function ():Boolean
                {
                    if (!target.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                    {
                        removeKeyRepeatEvents(null);
                        return false;
                    }
                    return true;
                });
        }

        public static function startKeyRepeat(firstCall:Boolean, func:Function, ...args):Boolean
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

        public static function checkPenOptionsKeyDown(keyCode:uint):Boolean
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

        public static function isPressingControl():Boolean
        {
            return getCommandKey() === COMMAND_CTRL;
        }

        public static function isPressingShift():Boolean
        {
            return getCommandKey() === COMMAND_SHIFT;
        }

        public static function isPressingControlShift():Boolean
        {
            return getCommandKey() === COMMAND_CTRL_SHIFT;
        }

        public static function getCommandKey():int
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

        public static function onMouseDownStage(e:MouseEvent):void
        {
            checkInvalidKey();
            CanvasController.isMouseLeftClicked = true;
            MainUI.hideBottomHint();
        }

        public static function onRightMouseDownStage(e:MouseEvent):void
        {
            checkInvalidKey();
            CanvasController.isRightMouseClicked = true;
        }

        public static function onMiddleMouseDownStage(e:MouseEvent):void
        {
            if (CaptureController.isCaptureModeON)
                return;

            if (FOFOTimer.hasTimer("toolTipTempONTimer"))
            {
                MainUI.hideMouseHint();
            }

            if (LassoTool._isLassoToolStarted)
            {
                LassoTool._lassoMenuBox.visible = false;
                LassoTool._isLassoMenuHiddenTemp = true;
            }

            if (ReplayController.isReplayModeON)
            {
                HandTool.startInReplayModeWithWheelClick();
            }
            else
            {
                HandTool.startInDrawModeWithWheelClick();
            }

            ToolController.showNowToolIconToCursorTemp(ToolController.TOOL_HAND);
        }

        public static function checkGeneralKeyUp(keyCode:uint):void
        {
            if (keyBuffer.length === 0)
            {
                resetLastKey();
            }
            else if (!CaptureController.isCaptureModeON && !ReplayController.isReplayModeON && isLastKey(keyCode))
            {
                onKeyDownLassoTool(null);
            }
        }

        public static function checkInvalidKey():void
        {
            const len:uint = keyBuffer.length;
            for (var i:int = 0;i < len;i++)
            {
                if (keyBuffer[i] === 229
                        || keyBuffer[i] === 241
                        || keyBuffer[i] === 242)
                {
                    clearKeyBuffer();
                    return;
                }
            }
            if (len >= 2)
            {
                if ((keyBuffer[0] === 18 && keyBuffer[1] === 32)
                        || (keyBuffer[0] === 32 && keyBuffer[1] === 18))
                {
                    clearKeyBuffer();
                }
            }
        }

        public static function getPressedKeyCount():int
        {
            return keyBuffer.length;
        }

        public static function isKeyPressed():Boolean
        {
            return keyBuffer.length > 0;
        }

        public static function isTwoKeyPressed():Boolean
        {
            return keyBuffer.length === 2;
        }

        public static function isPressdKey(key:int):int
        {
            return keyBuffer.lastIndexOf(key);
        }

        public static function getFirstPressedKey():int
        {
            return keyBuffer[0];
        }

        public static function getSecondPressedKey():int
        {
            return keyBuffer[1];
        }
        public static function getLastPressedKey():int
        {
            return keyBuffer[keyBuffer.length - 1];
        }

        public static function onKeyUpStage(e:KeyboardEvent):void
        {
            tryDisableIME();
            checkInvalidKey();
            const index:int = isPressdKey(e.keyCode);
            if (index > -1)
            {
                keyBuffer.splice(index, 1);
            }
        }

        public static function onKeyDownStage(e:KeyboardEvent):void
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
            if (keyBuffer.lastIndexOf(keyCode) === -1)
            {
                keyBuffer.push(keyCode);
            }
        }

        public static function removeInputEventsDrawMode():void
        {
            isDrawModeInputEventsAdded = false;
            main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownDrawMode);
            main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpDrawMode);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownDrawMode);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpDrawMode, false);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownDrawMode);
            ColorPickerController.colorPickerBox.rgbInfoText.removeEventListener(MouseEvent.MOUSE_DOWN, ColorPickerController.onMouseDownRGBInfoText);
            // main.stage.removeEventListener(MouseEvent.MOUSE_OVER,lassoMenuHintONEvent);
        }

        public static function addInputEventsDrawMode():void
        {
            if (isDrawModeInputEventsAdded === false)
            {
                isDrawModeInputEventsAdded = true;
                // resetKeyBuffer();
                main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpDrawMode, false, -1);
                main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownDrawMode, false, -1);
                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownDrawMode, false, -1);
                main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpDrawMode, false, -1);
                main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownDrawMode, false, -1);
                ColorPickerController.colorPickerBox.rgbInfoText.addEventListener(MouseEvent.MOUSE_DOWN, ColorPickerController.onMouseDownRGBInfoText);
            }
        }

        public static function removeInputEventsToolBox2():void
        {
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpToolBox2);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownToolBox2);
            ToolController.toolBox2.removeEventListener(MouseEvent.MOUSE_OVER, ToolController.onMouseOverToolBox2);
            addInputEventsDrawMode();
        }

        public static function addInputEventsToolBox2():void
        {
            removeInputEventsDrawMode();
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpToolBox2, false, -2);
            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownToolBox2, false, -2);
        }

        public static function onRightMouseUpToolBox2(e:MouseEvent):void
        {
            PenSizePreviewCursor.setCursorInVisibleFlag(false);

            if (LassoTool._isLassoToolStarted === true)
            {
                ToolController.closeToolBox2();
                return;
            }

            const target:SimpleButton = e.target as SimpleButton;

            if (!target || target.alpha < 1.0 || !main.isCursorInDrawArea())
            {
                ToolController.closeToolBox2();
                return;
            }

            ToolController.handleToolBox2Closing(target);
        }

        public static function onMouseMoveFillPen(e:MouseEvent):void
        {
            const filteredPos:Point = CanvasController.getRefinedPoint(CanvasController.canvasDrawLayerChild.mouseX, CanvasController.canvasDrawLayerChild.mouseY);
            const mx:Number = filteredPos.x + FillPenTool.pos05Offset;
            const my:Number = filteredPos.y + FillPenTool.pos05Offset;

            if (FillPenTool.lastPosOnMouseMove.x === mx && FillPenTool.lastPosOnMouseMove.y === my)
            {
                return;
            }

            FillPenTool.lastPosOnMouseMove.setTo(mx, my);

            if (FillPenTool.isInputDataEmpty())
            {
                FillPenTool.inputMoveToData(mx, my);
            }
            else
            {
                FillPenTool.inputLineToData(mx, my);
            }

            FillPenTool.increasetMoveCount();

            FillPenTool.updateLastMousePos();
            FillPenTool.resetPreviewOFFTimerCount();

            if (!FOFOTimer.hasTimer("previewFilledColorUpdateTimer"))
            {
                FOFOTimer.addByName("previewFilledColorUpdateTimer", 0.1, false, FillPenTool.showFillColor);
            }
        }

        private static function onMouseDownFillPen(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;

            if (!target)
            {
                return;
            }

            const targetName:String = target.name;
            FillPenTool.clickedButton = targetName;

            if (FillPenTool.fillPenBox.visible)
            {
                return;
            }

            if (SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
            {
                if (targetName === "penColorButton" || targetName === "paperColorButton" || targetName === "rgbInfoText")
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

                if (targetName.indexOf(Global.ALPHA_BUTTON_PREFIX) == 0)
                {
                    ToolController.setDrawingToolOpacity(targetName);
                    return;
                }

                switch (targetName)
                {
                    case "toolRotate":
                        {
                            RotateTool.startInDrawMode();
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

                    default:
                        break;
                }
            }

            if (targetName === "sideBarScrollBar")
            {
                SidebarController.startScrollSidebarByDrag();
            }
            else if (main.isCursorInDrawArea() && SidebarController.isQuickSidebarActive === false)
            {
                CanvasController.isMouseDragging = true;
                main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);

                const filteredPos:Point = CanvasController.getRefinedPoint(CanvasController.canvasDrawLayerChild.mouseX, CanvasController.canvasDrawLayerChild.mouseY);
                const mx:Number = filteredPos.x + FillPenTool.pos05Offset;
                const my:Number = filteredPos.y + FillPenTool.pos05Offset;

                if (CanvasController.isLayer2Selected)
                {
                    CanvasController.bringCanvasDrawLayerAboveLayer2();
                }

                if (FillPenTool.lastPosOnMouseMove.x === mx && FillPenTool.lastPosOnMouseMove.y === my)
                {
                    FOFOTimer.remove("previewFilledColorUpdateTimer");
                    FillPenTool.showFillColor();

                    return;
                }

                FillPenTool.lastPosOnMouseMove.setTo(mx, my);

                if (FillPenTool.isInputDataEmpty())
                {
                    FillPenTool.inputMoveToData(mx, my);
                }
                else
                {
                    FillPenTool.inputLineToData(mx, my);
                }

                FOFOTimer.remove("previewFilledColorUpdateTimer");
                FillPenTool.showFillColor();
            }
        }

        public static function removeEventsFillPen():void
        {
            main.stage.removeEventListener(MouseEvent.MOUSE_OVER, FillPenTool.onMouseOverFillPenHint);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownFillPen);
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpFillPen);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownFillPen);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpFillPen);
            main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpFillPen);
            main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeydownFillPen);
        }

        public static function addEventsFillPen():void
        {
            main.stage.addEventListener(MouseEvent.MOUSE_OVER, FillPenTool.onMouseOverFillPenHint);
            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownFillPen);
            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpFillPen);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownFillPen);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpFillPen);
            main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpFillPen);
            main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeydownFillPen);
        }

        public static function onRightMouseDownFillPen(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;

            if (CanvasController.isMouseLeftClicked || SidebarController.isQuickSidebarActive || !target || ColorPickerController.numPadBox.visible)
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
                    MainUIController.updateCanvasNaigatorCursor();
                }
                return;
            }
            else if (target.name === "toolRotate")
            {
                if (CanvasController.canvasAnchorPoint.rotation !== 0.0)
                {
                    CanvasController.resetRotationDrawMode();
                    MainUIController.updateCanvasNaigatorCursor();
                }
                return;
            }

            if (SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
            {
                return;
            }

            ToolController.openFillPenMenuBoxDelay();
        }

        public static function onMouseUpFillPen(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;

            if (!target)
            {
                return;
            }

            const targetName:String = e.target.name;

            FOFOTimer.remove("previewFilledColorUpdateTimer");
            CanvasController.isMouseDragging = false;
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);

            if (FillPenTool.clickedButton === targetName)
            {
                if (targetName === "toolFillPenOK")
                {
                    FillPenTool.applyFillPen();
                    return;
                }
                else if (targetName === "toolFillPenCancel")
                {
                    FillPenTool.cancel();
                    return;
                }
                else if (targetName === "toolUndo")
                {
                    FillPenTool.undoData();
                    return;
                }
            }

            if (FillPenTool.fillPenBox.visible)
            {
                if (FillPenTool.clickedButton === targetName)
                {
                    if (targetName === "fillPenOK")
                    {
                        FillPenTool.applyFillPen();
                    }
                    else if (targetName === "fillPenCancel")
                    {
                        FillPenTool.cancel();
                    }
                    else if (targetName === "fillPenUndo")
                    {
                        FillPenTool.updateLastFillPenBoxButtonUsed(target as SimpleButton);
                        FillPenTool.undoData();
                    }
                }
            }
            else
            {
                FillPenTool.handleOnMouseUp();
            }

            FillPenTool.afterKeyUpOK = false;
        }

        private static function onKeydownFillPen(e:KeyboardEvent):void
        {
            const pressedKey:uint = e.keyCode;

            if (CanvasController.isMouseLeftClicked)
            {
                return;
            }

            if (isLastKey(pressedKey))
            {
                return;
            }

            const secondKey:int = getSecondPressedKey();

            if (SidebarController.isPressingQuickSidebarShortcut(pressedKey, secondKey) || pressedKey === KEY.n6)
            {
                updateLastKey(pressedKey);

                if (SidebarController.isQuickSidebarActive === false)
                {
                    SidebarController.activeQuickSideBar(true);

                    if (!FOFOTimer.hasTimer("fillColorUpdateTimer"))
                    {
                        FillPenTool.startFillColorUpdateTimer();
                    }
                }
            }
            else if (pressedKey === KEY.g || pressedKey === KEY.b)
            {
                updateLastKey(pressedKey);
                startKeyRepeat(true, function (increase:Boolean):void
                    {
                        FillPenTool.setPreviewOFFTimerCount();
                        ToolController.adjustDrawToolAlphaByShortcut(increase);
                    }, (pressedKey === KEY.g) ? true : false);

                if (!FOFOTimer.hasTimer("fillColorUpdateTimer"))
                {
                    FillPenTool.startFillColorUpdateTimer();
                }
            }
        }

        private static function onKeyUpFillPen(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;
            resetLastKey();

            if (CanvasController.isMouseLeftClicked)
            {
                if (keyCode === KEY.q || keyCode === KEY.o || keyCode === KEY.enter)
                {
                    FillPenTool.afterKeyUpOK = true;
                }

                return;
            }

            if (keyCode === KEY.w || keyCode === KEY.i || keyCode === KEY.z || keyCode === KEY.dot)
            {
                FillPenTool.undoData();
            }
            else if (keyCode === KEY.q || keyCode === KEY.o || keyCode === KEY.enter)
            {
                FillPenTool.applyFillPen();
            }
            else if (keyCode === KEY.esc || keyCode === KEY.backspace)
            {
                FillPenTool.cancel();
            }
        }

        private static function onRightMouseUpFillPen(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;

            if (!target as DisplayObject || target === SidebarController.sideBarScrollBar || SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
            {
                return;
            }

            const targetName:String = target.name;

            if (targetName === "fillPenOK")
            {
                FillPenTool.applyFillPen();
            }
            else if (targetName === "fillPenCancel")
            {
                FillPenTool.cancel();
            }
            else if (targetName === "fillPenUndo")
            {
                FillPenTool.updateLastFillPenBoxButtonUsed(target as SimpleButton);
                FillPenTool.undoData();
            }
            else if (targetName === "fillPenSidebar")
            {
                FillPenTool.updateLastFillPenBoxButtonUsed(target as SimpleButton);
                SidebarController.activeQuickSideBar(false);

                if (!FOFOTimer.hasTimer("fillColorUpdateTimer"))
                {
                    FillPenTool.startFillColorUpdateTimer();
                }
            }

            FillPenTool.fillPenBox.visible = false;
        }

        public static function onMouseDownToolBox2(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;

            if (!target)
            {
                return;
            }

            const targetName:String = target.name;

            switch (targetName)
            {
                case "toolZoom":
                    {
                        ToolController.updateToolBoxMousePos(target as SimpleButton);
                        ToolController.closeToolBox2();
                        ZoomTool.start();
                    }
                    break;
                case "toolMove":
                    {
                        ToolController.updateToolBoxMousePos(target as SimpleButton);
                        ToolController.closeToolBox2();
                        MoveTool.start();
                    }
                    break;
                case "toolRotate2":
                    {
                        ToolController.updateToolBoxMousePos(target as SimpleButton);
                        ToolController.closeToolBox2();
                        RotateTool.startInDrawMode();
                    }
                    break;
                case "resizeButtonR":
                case "resizeButtonD":
                case "resizeButtonL":
                case "resizeButtonU":
                    {
                        CanvasController.startCanvasResizing(targetName);
                    }
                    break;
                default:
                    {
                        if (ToolController.toolBox2.visible && ToolController.toolBox2.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                        {
                            ToolController.updateToolBoxMousePos(ToolController.toolBox2.toolPen);
                            ToolController.updateLastTool();
                            HandTool.startInDrawMode();
                        }

                        ToolController.closeToolBox2();
                    }
                    break;
            }
        }

        public static function enableIME():void
        {
            IME.enabled = true;
        }

        public static function tryDisableIME():void
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

        public static function addKeyRepeatEvents():void
        {
            main.stage.nativeWindow.addEventListener(Event.DEACTIVATE, removeKeyRepeatEvents);
            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, removeKeyRepeatEvents);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, removeKeyRepeatEvents);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, removeKeyRepeatEvents);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, removeKeyRepeatEvents);
            main.stage.addEventListener(KeyboardEvent.KEY_UP, removeKeyRepeatEvents);
        }

        public static function removeKeyRepeatEvents(e:Object):void
        {
            FOFOTimer.remove("checkKeyRepeatStop");
            FOFOTimer.remove("keyHoldWaitTimer");
            FOFOTimer.remove("keyHoldRepeatTimer");
            main.stage.nativeWindow.removeEventListener(Event.DEACTIVATE, removeKeyRepeatEvents);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, removeKeyRepeatEvents);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, removeKeyRepeatEvents);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, removeKeyRepeatEvents);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, removeKeyRepeatEvents);
            main.stage.removeEventListener(KeyboardEvent.KEY_UP, removeKeyRepeatEvents);
        }

        public static function onKeyUpDrawMode(e:KeyboardEvent):void // keyup1
        {
            const keyCode:uint = e.keyCode;
            if (isLastKey(keyCode))
            {
                if (CanvasController.isMouseLeftClicked === true)
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
                    PenSizePreviewCursor.updatePosAndVisibility();
                }
            }
            if (!isKeyPressed())
            {
                resetLastKey();
            }
            if (!isPressingControl())
            {
                if (main.resizeCanvas.isResizing())
                {
                    main.resizeCanvas.exit(true);
                }
                if (MainUIController.resizeButtonR.visible)
                {
                    MainUIController.updateCanvasResizeButtonVisible(false);
                }
            }
        }

        public static function checkSubKey(expectedLength:uint, updateFlag:Boolean, callback:Function):Boolean
        {
            if (getPressedKeyCount() !== expectedLength)
            {
                return false;
            }
            const subKey:uint = getLastPressedKey();
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

        public static function onKeyDownDrawMode(e:KeyboardEvent):void
        {
            if (CanvasController.isMouseLeftClicked || CanvasController.isRightMouseClicked || CanvasController.isKeyReleasedBeforeMouseUp || FillPenTool.isStarted
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
                checkSubKey(3, true, handleControlShiftSubKeyDrawMode);
                return;
            }
            if (isPressingControl())
            {
                if (!checkSubKey(2, true, handleControlSubKeyDrawMode))
                {
                    if (main.resizeCanvas.isResizing() === false)
                    {
                        MainUIController.updateCanvasResizeButtonVisible(true);
                    }
                }
                return;
            }
            if (isPressingShift())
            {
                if (handleKeyDownPenOpacitySize(secondKey))
                {
                    return;
                }
                else if (checkPenOptionsKeyDown(secondKey))
                {
                    return;
                }
                else if (checkSubKey(2, true, handleShiftSubKeyDrawMode))
                {
                    return;
                }
            }
            if (isTwoKeyPressed())
            {
                // 지우개키 조합 따로 체크
                if (firstKey === KEY.d || firstKey === KEY.j)
                {
                    if (handleKeyDownPenOpacitySize(secondKey))
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
                    if (handleKeyDownPenOpacitySize(secondKey))
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
            if (handleKeyDownPenOpacitySize(firstKey))
            {
                return;
            }
            if (handleExtraKeyDown(firstKey))
            {
                return;
            }
            ToolController.handleToolKeyDown(firstKey);
        }

        public static function unblockMouseClickAfterDelay():void
        {
            FOFOTimer.addByName("clickBlockTimer", 0.15, false, function ():void
                {
                    CanvasController.isMouseClickBlocked = false;
                });
        }

        public static function onMouseUpLassoTool(e:MouseEvent):void
        {
            if (getPressedKeyCount() === 1 && getFirstPressedKey() === KEY.space)
            {
                updateLastKey(KEY.space);
                LassoTool.isLassoMenuHiddenTemp = true;
                ToolController.setSelectedTool(ToolController.TOOL_HAND);
                ToolController.showNowToolIconToCursorTemp(ToolController.TOOL_HAND);
            }
        }

        public static function onMouseDownLassoTool(e:MouseEvent):void
        {
            if (CanvasController.isRightMouseClicked)
            {
                return;
            }
            const target:DisplayObject = e.target as DisplayObject;
            if (!target)
            {
                return;
            }
            const targetName:String = target.name;
            if (main.isCursorInDrawArea() && LassoTool._lassoMenuBox.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
            {
                if (LassoTool.isLassoMenuHiddenTemp)
                {
                    LassoTool.lassoMenuBox.visible = false;
                    if (ToolController.isSelectedTool(ToolController.TOOL_HAND))
                        HandTool.startInDrawMode();
                    else if (ToolController.isSelectedTool(ToolController.TOOL_ZOOM))
                        ZoomTool.start();
                    else if (ToolController.isSelectedTool(ToolController.TOOL_ROTATE))
                        RotateTool.startInDrawMode();
                }
                else
                {
                    LassoTool.startLassoImageMove();
                }
            }
            else
            {
                switch (targetName)
                {
                    case "lassoMove":
                        {
                            LassoTool.startLassoImageMove();
                        }
                        break;
                    case "lassoResize":
                        {
                            LassoTool.startLassoImageResize();
                        }
                        break;
                    case "lassoRotate":
                        {
                            LassoTool.startLassoImageRotation();
                        }
                        break;
                    case "navStageBG":
                    case "navBitmapBG":
                    case "navLayer1Bitmap":
                    case "navLayer2Bitmap":
                        {
                            CanvasController.startCanvasMoveByCanvasNavigator(false);
                        }
                        break;
                    case "navCursor":
                        {
                            CanvasController.startCanvasMoveByCanvasNavigator(true);
                        }
                        break;
                    case "lassoMenuMoveButton":
                        {
                            Utils.setAsTopChild(LassoTool.lassoMenuBox);
                            DragInteraction.startBoxDrag(LassoTool.lassoMenuBox);
                        }
                        break;
                    case "sideBarScrollBar":
                        {
                            SidebarController.startScrollSidebarByDrag();
                        }
                        break;
                    case "toolZoomIn":
                        {
                            CanvasController.zoomInCanvas(true, false);
                        }
                        break;
                    case "toolZoomOut":
                        {
                            CanvasController.zoomInCanvas(false, false);
                        }
                        break;
                    case "toolRotate":
                        {
                            LassoTool.lassoMenuBox.visible = false;
                            LassoTool.isLassoMenuHiddenTemp = true;
                            RotateTool.startInDrawMode();
                        }
                        break;
                    case "lasso1pxUp":
                    case "lasso1pxDown":
                    case "lasso1pxLeft":
                    case "lasso1pxRight":
                    case "lassoCopy":
                    case "lassoOK":
                    case "lassoCancel":
                    case "lassoRefLayer":
                    case "sideBarPositionButton":
                    case "sideBarPositionButton2":
                    case "sideBarOFFButton":
                    case "sideBarOFFButton2":
                    case "sideBarONButton":
                    case "sideBarONButton2":
                    case "lassoLayerMerge":
                    case "lassoLayerSwap":
                    case "lassoMirror":
                        main.handleMouseClick(targetName);
                        break;
                    default:
                        break;
                }
            }
        }

        public static function onKeyUpLassoTool(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;
            if (LassoTool.isLassoMenuHiddenTemp && !CanvasController.isMouseLeftClicked)
            {
                LassoTool.isLassoMenuHiddenTemp = false;
            }
            checkGeneralKeyUp(keyCode);
        }

        public static function onKeyDownLassoTool(e:KeyboardEvent):void
        {
            if (CanvasController.isMouseLeftClicked || CanvasController.isRightMouseClicked || CanvasController.isMouseDragging)
            {
                return;
            }

            const keyCode:uint = getFirstPressedKey();

            if (keyCode === KEY.space)
            {
                if (checkSubKey(2, true, handleSpaceSubKeyLassoTool))
                {
                    return;
                }

                if (isLastKey(keyCode))
                {
                    return;
                }

                updateLastKey(keyCode);
                LassoTool.isLassoMenuHiddenTemp = true;
                ToolController.setSelectedTool(ToolController.TOOL_HAND);
                ToolController.showNowToolIconToCursorTemp(ToolController.TOOL_HAND);
            }
            else if (isPressingShift())
            {
                if (checkSubKey(2, true, handleShiftSubKeyLassoTool))
                {
                    return;
                }
            }

            if (isLastKey(keyCode))
            {
                return;
            }

            updateLastKey(keyCode);

            switch (keyCode)
            {
                case KEY.tab:
                case KEY.backslash:
                    if (SidebarController.isSidebarVisible)
                    {
                        SidebarController.hideSidebarPermanent();
                    }
                    else
                    {
                        SidebarController.showSidebarPermanent();
                    }
                    break;

                case KEY.w:
                case KEY.i:
                    LassoTool.isLassoMenuHiddenTemp = true;
                    updateLastKey(keyCode);
                    ToolController.setSelectedTool(ToolController.TOOL_ZOOM);
                    ToolController.showNowToolIconToCursorTemp(ToolController.TOOL_ZOOM);
                    break;

                case KEY.s:
                case KEY.k:
                    LassoTool.isLassoMenuHiddenTemp = true;
                    updateLastKey(keyCode);
                    ToolController.setSelectedTool(ToolController.TOOL_ROTATE);
                    ToolController.showNowToolIconToCursorTemp(ToolController.TOOL_ROTATE);
                    break;

                case KEY.enter:
                    LassoTool.applyLassoImageToCanvas();
                    break;

                case KEY.esc:
                case KEY.backspace:
                    LassoTool.cancelIfActive();
                    break;
            }
        }

        public static function onRightMouseDownLassoTool(e:MouseEvent):void
        {
            if (!LassoTool.isLassoToolStarted)
            {
                return;
            }
            const target:DisplayObject = e.target as DisplayObject;
            if (!target)
                return;
            const targetName:String = target.name;
            if (targetName === "toolZoom"
                    || targetName === "toolZoomIn"
                    || targetName === "toolZoomOut")
            {
                if (CanvasController.canvasZoomMultipler !== 1.0)
                {
                    CanvasController.resetZoomDrawMode();
                    MainUIController.updateCanvasNaigatorCursor();
                }
            }
            else if (targetName === "toolRotate")
            {
                if (CanvasController.canvasAnchorPoint.rotation !== 0.0)
                {
                    CanvasController.resetRotationDrawMode();
                    MainUIController.updateCanvasNaigatorCursor();
                }
            }
        }

        public static function onRightMouseUpLassoTool(e:MouseEvent):void
        {
            if (!LassoTool._isLassoToolStarted || CanvasController.isMouseLeftClicked)
            {
                return;
            }
            const target:DisplayObject = e.target as DisplayObject;
            if (!target)
                return;
            const targetName:String = target.name;
            if (targetName === "toolZoom"
                    || targetName === "toolZoomIn"
                    || targetName === "toolZoomOut"
                    || targetName === "toolRotate")
            {
                return;
            }
            if (LassoTool.lassoMenuBox.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false || targetName === "lassoOK")
            {
                LassoTool.applyLassoImageToCanvas();
                return;
            }
            if (targetName === "lassoRotate")
            {
                LassoTool.resetLassoLayerRotation();
            }
            else if (targetName === "lassoResize")
            {
                LassoTool.resetLassoLayerScale();
            }
        }

        public static function removeInputEventsLassoTool():void
        {
            main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpLassoTool);
            main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownLassoTool);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownLassoTool);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpLassoTool);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownLassoTool);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpLassoTool);
            addInputEventsDrawMode();
        }

        public static function addInputEventsLassoTool():void
        {
            main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpLassoTool);
            main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownLassoTool);
            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownLassoTool);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpLassoTool, false, -1);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownLassoTool);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpLassoTool);
            main.stage.addEventListener(MouseEvent.MOUSE_OVER, LassoTool.lassoMenuHintONEvent);
            removeInputEventsDrawMode();
        }

        private static function handleShiftSubKeyLassoTool(input:int):void
        {
            switch (input)
            {
                case KEY.s:
                case KEY.k:
                    if (CanvasController.canvasAnchorPoint.rotation !== 0.0)
                    {
                        CanvasController.resetRotationDrawMode();
                        MainUIController.updateCanvasNaigatorCursor();
                    }
                    return;

                case KEY.w:
                case KEY.i:
                    if (CanvasController.canvasZoomMultipler !== 1.0)
                    {
                        CanvasController.resetZoomDrawMode();
                        MainUIController.updateCanvasNaigatorCursor();
                    }
                    return;
            }
        }
        private static function handleSpaceSubKeyLassoTool(input:int):void
        {
            // 키 2개 조합만 체크함
            if (!isTwoKeyPressed())
            {
                return;
            }

            switch (input)
            {
                case KEY.w:
                case KEY.i:
                    LassoTool.move1PXUp();
                    break;

                case KEY.a:
                case KEY.j:
                    LassoTool.move1PXLeft();
                    break;

                case KEY.s:
                case KEY.k:
                    LassoTool.move1PXDown();
                    break;

                case KEY.d:
                case KEY.l:
                    LassoTool.move1PXRight();
                    break;
            }
        }
        private static function handleControlSubKeyReplayMode(input:int):void
        {
            if (input === KEY.c || input === KEY.m)
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
        }
        private static function handleShiftSubKeyReplayMode(input:int):void
        {
            switch (input)
            {
                case KEY.left:
                case KEY.z:
                case KEY.dot:
                    {
                        if (!ReplayController.isReplayStarted)
                        {
                            startKeyRepeat(true, ReplayController.moveToPreviousFrame);
                        }
                    }
                    break;
                case KEY.right:
                case KEY.x:
                case KEY.comma:
                    {
                        if (!ReplayController.isReplayStarted)
                        {
                            startKeyRepeat(true, ReplayController.moveToNextFrame);
                        }
                    }
                    break;
            }
        }
        private static function handleShiftSubKeyDrawMode(input:int):void
        {
            switch (input)
            {
                case KEY.s:
                case KEY.k:
                    {
                        if (CanvasController.canvasAnchorPoint.rotation !== 0.0)
                        {
                            CanvasController.resetRotationDrawMode();
                            MainUIController.updateCanvasNaigatorCursor();
                        }
                    }
                    return;
                case KEY.w:
                case KEY.i:
                    {
                        if (CanvasController.canvasZoomMultipler !== 1.0)
                        {
                            CanvasController.resetZoomDrawMode();
                            MainUIController.updateCanvasNaigatorCursor();
                        }
                    }
                    return;
            }
        }
        private static function handleControlShiftSubKeyDrawMode(input:int):void
        {
            if (input === KEY.s)
            {
                FileManager.openSaveFileBrowser(true);
            }
        }
        private static function handleControlSubKeyDrawMode(input:int):void
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
        }

        public static function clearKeyBuffer():void
        {
            keyBuffer.length = 0;
            resetLastKey();
        }

        public static function handleExtraKeyDown(keyCode:int):Boolean
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

        // 키를 2개 이상 누르고 있을때 먼저 누른키를 떼면 다음키로 설정함
        public static function onMouseUpDrawMode(e:MouseEvent):void // mouseup1
        {
            if (CanvasController.isKeyReleasedBeforeMouseUp) // 단축키 떼고 마우스 땠을때 원래대로 돌림
            {
                CanvasController.isKeyReleasedBeforeMouseUp = false;
                if (keyBuffer.length > 0)
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
                    PenSizePreviewCursor.updatePosAndVisibility();
                }
            }
        }

        public static function onMouseDownDrawMode(e:MouseEvent):void
        {
            if (FillPenTool.isStarted || FileManager.loadMenuBox.visible
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
                if (SidebarController.sideBarScrollPanel.hitTestPoint(main.stage.mouseX, main.stage.mouseY) && SidebarController.handleSidebarMouseDown(target))
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
                        main.handleMouseClick(targetName);
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
                        startPressHoldKey(MainUI.topBar.timer, HintStrings.getResetTimerHintString(), null, ActivityWorkTimer.reset, null);
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
            if (main.isCursorInDrawArea() && !CanvasController.isMouseClickBlocked)
            {
                switch (ToolController.nowTool)
                {
                    case ToolController.TOOL_PEN:
                        if (CanvasController.isToolEnabledByLayerUnChecked())
                            PenTool.start();
                        break;
                    case ToolController.TOOL_FILLPEN:
                        if (CanvasController.isToolEnabledByLayerUnChecked())
                            FillPenTool.start();
                        break;
                    case ToolController.TOOL_ERASER:
                        if (CanvasController.isToolEnabledByLayerUnChecked())
                            PenTool.startWithEraserMode();
                        break;
                    case ToolController.TOOL_LINE:
                        if (CanvasController.isToolEnabledByLayerUnChecked())
                            LineTool.start();
                        break;
                    case ToolController.TOOL_LASSO:
                        LassoTool.lassoToolFunction.start();
                        break;
                    case ToolController.TOOL_MOVE:
                        MoveTool.start();
                        break;
                        // 캔버스 조작
                    case ToolController.TOOL_ZOOM:
                        ZoomTool.start();
                        break;
                    case ToolController.TOOL_HAND:
                        HandTool.startInDrawMode();
                        break;
                    case ToolController.TOOL_ROTATE:
                        RotateTool.startInDrawMode();
                        break;
                }
            }
        }

        // todo numpad켜져있을때 캔버스 바로 클릭하면 바로 다른 툴 적용되게 바꾸어야함
        public static function onRightMouseDownDrawMode(e:MouseEvent):void // rdown1
        {
            if (CanvasController.isMouseLeftClicked || isKeyPressed() || isPressingControl() || SidebarController.isQuickSidebarActive
                    || FillPenTool.isStarted || ToolController.isSelectedTool(ToolController.TOOL_EYEDROPPER) || (ReferenceLayerController.isRefLayerMenuON && ReferenceLayerController.refLayerMenuBox.hitTestPoint(main.mouseX, main.mouseY))
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
                        {
                            CanvasController.resetZoomDrawMode();
                            MainUIController.updateCanvasNaigatorCursor();
                        }
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
                            CanvasController.resetRotationDrawMode();
                            MainUIController.updateCanvasNaigatorCursor();
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
                        if (main.isCursorInDrawArea())
                        {
                            if (ToolController.isToolBox2Showing && !UndoManager.isDeepUndoEnabled)
                            {
                                ToolController.closeToolBox2();
                            }
                            else
                            {
                                ToolController.openToolBox2Delay();
                            }
                        }
                    }
                    break;
            }
        }

        private static function onKeyDownCaptureMode(e:KeyboardEvent):void
        {
            const firstKey:uint = getFirstPressedKey();
            if (CaptureController.captureStampFontListBox.visible)
            {
                if (firstKey === KEY.esc)
                {
                    CaptureController.hideStampFontList();
                }
                return;
            }

            if (firstKey === KEY.esc)
            {
                if (main.stage.focus === MainUI.topBar.captureInput)
                {
                    main.stage.focus = null;
                    return;
                }
            }

            if (main.stage.focus === MainUI.topBar.captureInput || CanvasController.isMouseLeftClicked || CanvasController.isRightMouseClicked)
            {
                return;
            }

            if (isPressingControl())
            {
                const secondKey:uint = getSecondPressedKey();
                if (isLastKey(secondKey))
                {
                    return;
                }
                updateLastKey(secondKey);

                if (secondKey === KEY.s || secondKey === KEY.semicolon)
                {
                    FileManager.saveCaptureImage();
                }
                else if (secondKey === KEY.c || secondKey === KEY.comma)
                {
                    CaptureController.executeCaptureFlashEffect();
                    if (MainUI.topBar.capClipBoard.alpha === 1.0)
                    {
                        CaptureController.copyCaptureImageToCilpBoard();
                    }
                }
                else if (secondKey === KEY.v || secondKey === KEY.m)
                {
                    if (ClipboardManager.isClipBoardButtonActivated)
                    {
                        ClipboardManager.tryLoadClipboardImage(false);
                    }
                }
                return;
            }

            if (isLastKey(firstKey))
            {
                return;
            }

            updateLastKey(firstKey);

            switch (firstKey)
            {
                case KEY.esc:
                case KEY.backspace:
                case KEY.f1:
                case KEY.f7:
                    CaptureController.handleExitCaptureMode();
                    break;
                default:
                    break;
            }
        }

        public static function removeInputEventCaptrueMode():void
        {
            isCaptureModeInputEventsAdded = false;
            main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpCaptureMode);
            main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownCaptureMode);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownCaptureMode);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownCaptureMode);
        }

        public static function addInputEventsCaptrueMode():void
        {
            if (isCaptureModeInputEventsAdded === false)
            {

                isCaptureModeInputEventsAdded = true;
                // resetKeyBuffer();
                main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpCaptureMode, false, -1);
                main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownCaptureMode, false, -1);
                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownCaptureMode, false, -1);
                main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownCaptureMode, false, -1);
            }
        }

        private static function onKeyUpCaptureMode(e:KeyboardEvent):void
        {
            updateLastKey(getLastPressedKey());
            checkGeneralKeyUp(e.keyCode);
        }

        private static function onMouseDownCaptureMode(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if (!target)
            {
                return;
            }

            const targetName:String = target.name;

            if (targetName === "capLayer1VisibleButton" || targetName === "capLayer2VisibleButton" || targetName === "capStamp" || targetName === "capStampFont")
            {
                main.handleMouseClick(targetName);
                return;
            }

            if (targetName === "capClipBoard")
            {
                CaptureController.executeCaptureFlashEffect();
                if (target.alpha < 1.0 && MainUI.topBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                {
                    return;
                }
                main.handleMouseClick(targetName);
            }

            if (target.alpha < 1.0 && MainUI.topBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
            {
                return;
            }

            if (CaptureController.captureStampFontListBox.visible)
            {
                if (targetName === "capFontListNext" || targetName === "capFontListPrev")
                {
                    main.handleMouseClick(targetName);
                }
                else if (targetName && targetName.indexOf(CaptureController.captureStampFontListBox.getStampFontButtonName()) !== -1)
                {
                    CaptureController.captureStampManager.changeFont(CaptureController.captureStampFontListBox.getFontName(targetName), true);
                }
                else if (target.parent)
                {
                    if (target.parent.name && target.parent.name.indexOf(CaptureController.captureStampFontListBox.getStampFontButtonName()) !== -1)
                    {
                        CaptureController.captureStampManager.changeFont(CaptureController.captureStampFontListBox.getFontName(target.parent.name), true);
                    }
                }
                return;
            }

            switch (targetName)
            {
                case "capRotate":
                case "capFlip":
                case "capSave":
                case "capOff":
                case "capTrans":
                    main.handleMouseClick(targetName);
                    break;
                case "timer":
                    startPressHoldKey(MainUI.topBar.timer, HintStrings.getResetTimerHintString(), null, ActivityWorkTimer.reset, null);
                    break;
                default:
                    if (!CanvasController.isMouseClickBlocked)
                    {
                        CaptureController.captureAreaManager.start();
                    }
                    break;
            }
        }

        private static function onRightMouseDownCaptureMode(e:MouseEvent):void
        {
            if (MainUI.topBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
            {
                if (!CaptureController.captureAreaManager.isFullImageCapture())
                {
                    CaptureController.captureAreaManager.resetCaptureArea();
                }
            }
        }

        public static function onKeyUpReplayMode(e:KeyboardEvent):void
        {
            checkGeneralKeyUp(e.keyCode);
        }
        public static function onKeyDownReplayMode(e:KeyboardEvent):void // keydown2
        {
            const firstKey:uint = getFirstPressedKey();
            if (CanvasController.isMouseLeftClicked || CanvasController.isRightMouseClicked || isLastKey(firstKey) || FileManager.loadMenuBox.visible)
            {
                return;
            }
            if (ReplayController.isReplayStarted)
            {
                switch (firstKey)
                {
                    case KEY.backspace:
                    case KEY.esc:
                    case KEY.enter:
                    case KEY.space:
                        {
                            updateLastKey(firstKey);
                            FOFOTimer.remove("prograssBarUpdateTimer");
                            ReplayController.handleReplayStopButton();
                            ;
                        }
                        break;
                }
                return;
            }
            if (ReplayController.isReplayRestartTimerON())
            {
                switch (firstKey)
                {
                    case KEY.backspace:
                    case KEY.esc:
                    case KEY.enter:
                    case KEY.space:
                        {
                            updateLastKey(firstKey);
                            ReplayController.cancelReplayRestartTimer();
                        }
                        break;
                }
                return;
            }
            if (isPressingShift())
            {
                checkSubKey(2, false, handleShiftSubKeyReplayMode);
                return;
            }
            else if (isPressingControl())
            {
                checkSubKey(2, true, handleControlSubKeyReplayMode);
                return;
            }
            updateLastKey(firstKey);
            switch (firstKey)
            {
                case KEY.left:
                case KEY.z:
                case KEY.dot:
                    {
                        if (!ReplayController.isReplayStarted)
                        {
                            startKeyRepeat(true, ReplayController.moveToPreviousStep);
                        }
                    }
                    break;
                case KEY.right:
                case KEY.x:
                case KEY.comma:
                    {
                        if (!ReplayController.isReplayStarted)
                        {
                            startKeyRepeat(true, ReplayController.moveToNextStep);
                        }
                    }
                    break;
                case KEY.up:
                case KEY.f:
                case KEY.h:
                    {
                        if (!ReplayController.isReplayStarted)
                        {
                            ReplayController.startAdjustPlayBackSpeedByShortcut(true);
                        }
                    }
                    break;
                case KEY.down:
                case KEY.v:
                case KEY.n:
                    {
                        if (!ReplayController.isReplayStarted)
                        {
                            ReplayController.startAdjustPlayBackSpeedByShortcut(false);
                        }
                    }
                    break;
                case KEY.backspace:
                case KEY.esc:
                case KEY.f1:
                case KEY.f7:
                    {
                        ReplayController.exitReplayMode();
                    }
                    break;
                case KEY.enter:
                case KEY.space:
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
            }
        }

        // rotate hand zoom에서 쓰임
        public static function addInputEventsReplayMode():void
        {
            if (isReplayModeInputEventsAdded === false)
            {
                isReplayModeInputEventsAdded = true;
                // resetKeyBuffer();
                main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownReplayMode, false, -1);
                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownReplayMode, false, -1);
                main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownReplayMode, false, -1);
                main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpReplayMode, false, -1);
            }
        }

        public static function removeInputEventsReplayMode():void
        {
            isReplayModeInputEventsAdded = false;
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownReplayMode);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownReplayMode);
            main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownReplayMode);
            main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpReplayMode);
        }

        public static function onRightMouseDownReplayMode(e:MouseEvent):void
        {
            if (CanvasController.isMouseLeftClicked || isKeyPressed() || !e.target || FileManager.loadMenuBox.visible)
            {
                return;
            }

            const targetName:String = e.target.name;

            switch (targetName)
            {
                case "replayPrev":
                    {
                        startKeyRepeat(true, ReplayController.moveToPreviousFrame);
                        startKeyRepeatStopTimerOnMouseLeave(e.target as DisplayObject);
                    }
                    break;
                case "replayNext":
                    {
                        startKeyRepeat(true, ReplayController.moveToNextFrame);
                        startKeyRepeatStopTimerOnMouseLeave(e.target as DisplayObject);
                    }
                    break;
                case "replayRotateButton":
                    {
                        ReplayController.resetRotationReplayMode();
                    }
                    break;
                case "replayZoomInButton":
                case "replayZoomOutButton":
                {
                    ReplayController.resetZoomReplayMode();
                    break;
                }
                case "rCanvasDrawLayer":
                case "stageBG":
                    {
                        if (ReplayController.isReplayRestartTimerON())
                        {
                            ReplayController.cancelReplayRestartTimer();
                        }
                        else if (!ReplayController.isReplayStarted)
                        {
                            ReplayController.handleReplayStartButton();
                        }
                        else
                        {
                            ReplayController.handleReplayStopButton();
                        }
                    }
                    break;
            }
        }

        public static function onMouseDownReplayMode(e:MouseEvent):void // repdown1
        {
            var Handtool:Object;
            const target:DisplayObject = e.target as DisplayObject;
            if (!target || FileManager.loadMenuBox.visible)
            {
                return;
            }
            const targetName:String = target.name;
            if (ReplayController.isReplayRestartTimerON())
            {
                if (MainUI.seekBarBox.trackBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                {
                    ReplayController.cancelReplayRestartTimer();
                    return;
                }
            }
            if (targetName && !ReplayController.isReplayRestartTimerON())
            {
                if (targetName === "rCanvasPanel" || targetName === "rCanvasDrawLayer" || targetName === "stageBG")
                {
                    HandTool.startInReplayMode();
                    return;
                }
                else if (targetName === "replayRepeatButton" || targetName === "replayFitToWindowButton")
                {
                    if (isKeyPressed())
                    {
                        return;
                    }
                    main.handleMouseClick(targetName);
                    return;
                }
            }
            if (target.alpha < 1.0)
            {
                return;
            }
            switch (targetName)
            {
                case "repNewFileButton":
                    {
                        startPressHoldKey(MainUI.topBar.repNewFileButton, HintStrings.getNewFileHintString(),
                                function ():Boolean
                                {
                                    return ReplayController.prepareDeleteReplayData("total");
                                },
                                ReplayController.createNewFileFromReplayCanvas,
                                function ():void
                                {
                                    MainUI.seekBarBox.setDeleteRangeBarVisible(false);
                                });
                    }
                    break;
                case "cutPrevDataButton":
                    {
                        if (MainUI.topBar.cutPrevDataButton.alpha === 1.0)
                        {
                            startPressHoldKey(MainUI.topBar.cutPrevDataButton, HintStrings.getDeleteReplayDataHintString(), function ():Boolean
                                {
                                    return ReplayController.prepareDeleteReplayData("before");
                                },
                                    ReplayController.deleteReplayDataBeforeCurrentFrame,
                                    function ():void
                                    {
                                        MainUI.seekBarBox.setDeleteRangeBarVisible(false);
                                    });
                        }
                    }
                    break;
                case "superUndoButton":
                    {
                        if (MainUI.topBar.superUndoButton.alpha === 1.0)
                        {
                            startPressHoldKey(MainUI.topBar.superUndoButton, HintStrings.getDeleteReplayDataHintString(), function ():Boolean
                                {
                                    return ReplayController.prepareDeleteReplayData("after");
                                },
                                    ReplayController.deleteReplayDataAfterCurrentFrame, function ():void
                                    {
                                        MainUI.seekBarBox.setDeleteRangeBarVisible(false);
                                    });
                        }
                    }
                    break;
                case "replayRotateButton":
                    {
                        RotateTool.startInReplayMode();
                    }
                    break;
                case "replaySpeedSliderWrapper":
                    {
                        ReplayController.adjutReplaySpeedByMouse();
                    }
                    break;
                case "trackBar":
                    {
                        ReplayController.onSeekbarClick();
                    }
                    break;
                case "replayPrev":
                    {
                        FOFOTimer.remove("prograssBarUpdateTimer");
                        if (isPressingShift())
                        {
                            startKeyRepeat(true, ReplayController.moveToPreviousFrame);
                            startKeyRepeatStopTimerOnMouseLeave(target);
                        }
                        else
                        {
                            startKeyRepeat(true, ReplayController.moveToPreviousStep);
                            startKeyRepeatStopTimerOnMouseLeave(target);
                        }
                    }
                    break;
                case "replayNext":
                    {
                        FOFOTimer.remove("prograssBarUpdateTimer");
                        if (isPressingShift())
                        {
                            startKeyRepeat(true, ReplayController.moveToNextFrame);
                            startKeyRepeatStopTimerOnMouseLeave(target);
                        }
                        else
                        {
                            startKeyRepeat(true, ReplayController.moveToNextStep);
                            startKeyRepeatStopTimerOnMouseLeave(target);
                        }
                    }
                    break;
                case "timer":
                    {
                        startPressHoldKey(MainUI.topBar.timer, HintStrings.getResetTimerHintString(), null, ActivityWorkTimer.reset, null);
                    }
                    break;
                case "drawModeButton":
                case "saveButton":
                case "captureButton":
                case "capOff":
                case "capSave":
                case "capClipBoard":
                case "capTrans":
                case "capFlip":
                case "capRotate":
                case "repCaptureButton":
                case "clipBoardButton":
                case "topBarColorButton":
                case "playButton":
                case "pauseButton":
                case "replayZoomInButton":
                case "replayZoomOutButton":
                case "replayFitToWindowButton":
                case "replayPrev":
                case "replayNext":
                    {
                        if (isKeyPressed())
                        {
                            return;
                        }
                        main.handleMouseClick(targetName);
                    }
                    break;
            }
        }

        public static function onMouseMoveUpdatePenPreviewCursor(e:MouseEvent):void
        {
            if (ReplayController.isReplayModeON || CaptureController.isCaptureModeON)
            {
                return;
            }

            PenSizePreviewCursor.updatePosAndVisibility();
        }

        public static function handleKeyDownPenOpacitySize(keyCode:uint):Boolean
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

                    startKeyRepeat(true, ToolController.adjustDrawToolAlphaByShortcut, true);
                    return true;
                case KEY.b:
                    startKeyRepeat(true, ToolController.adjustDrawToolAlphaByShortcut, false);
                    return true;
            }
            return false;
        }
    }
}
