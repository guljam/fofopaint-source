package Modules
{
    import flash.display.DisplayObject;
    import flash.events.MouseEvent;
    import flash.events.KeyboardEvent;
    import flash.utils.Timer;
    import Modules.Tools.LassoTool;
    import flash.utils.getTimer;
    import flash.events.TimerEvent;
    import flash.system.IME;
    import flash.system.Capabilities;
    import flash.events.Event;
    import Modules.Tools.PenTool;

    public class InputController
    {
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

        public static const KEY_REPEAT_START_DELAY:Number = 0.3,
            KEY_REPEAT_INTERVAL:Number = 0.06;
        // 키 누름 관련
        public static  var LAST_KEY:int = -1; // 마지막 누른거 여기다가 저장 반복호출되는 keydown 함수에서 한번만 호출되게 하는변수
        public static const KEY_BUFFER:Array = []; // 정식 키 다운 눌러준 상태에서 다른 키가 눌러져 있으면 여기다가 저장
        public static const COMMAND_CTRL:int = (1 << 0),
            COMMAND_SHIFT:int = (1 << 1),
            COMMAND_CTRL_SHIFT:int = (1 << 2);

        // 키 오래누름 관련 변수
        public static  var pressHoldCountDownTime:Number = 0.0,
            pressHoldFrameCount:int = 0;

        // todo 이거 쓰나?
        public static  var isLayerCheckKeyPressed:Boolean = false;
        public static  var isDrawModeInputEventsAdded:Boolean = false;


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
                var mouseClickONSave:Boolean = CanvasController.isMouseClicked;
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
                        if (CanvasController.isMouseClicked !== mouseClickONSave
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
            LAST_KEY = getLastKey();
        }

        public static function resetLastKey():void
        {
            LAST_KEY = -1;
        }

        public static function isLastKey(key:uint):Boolean
        {
            return LAST_KEY === key;
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
            CanvasController.isMouseClicked = true;
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
            if (LassoTool.isLassoToolStarted)
            {
                LassoTool.lassoMenuBox.visible = false;
                LassoTool.isLassoMenuHiddenTemp = true;
            }
            main.handTool(ReplayController.isReplayModeON, true);
            ToolController.showNowToolIconToCursorTemp(ToolController.TOOL_HAND);
        }

        public static function checkGeneralKeyUp(keyCode:uint):void
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

        public static function checkInvalidKey():void
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

        public static function getPressedKeyCount():int
        {
            return KEY_BUFFER.length;
        }

        public static function isKeyPressed():Boolean
        {
            return KEY_BUFFER.length > 0;
        }

        public static function getLastKey():int
        {
            return KEY_BUFFER[KEY_BUFFER.length - 1];
        }

        public static function isTwoKeyPressed():Boolean
        {
            return KEY_BUFFER.length === 2;
        }

        public static function isPressdKey(key:int):int
        {
            return KEY_BUFFER.lastIndexOf(key);
        }

        public static function getFirstPressedKey():int
        {
            return KEY_BUFFER[0];
        }

        public static function getSecondPressedKey():int
        {
            return KEY_BUFFER[1];
        }

        public static function onKeyUpStage(e:KeyboardEvent):void
        {
            tryDisableIME();
            checkInvalidKey();
            const index:int = isPressdKey(e.keyCode);
            if (index > -1)
            {
                KEY_BUFFER.splice(index, 1);
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
            if (KEY_BUFFER.lastIndexOf(keyCode) === -1)
            {
                KEY_BUFFER.push(keyCode);
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
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, ToolController.onRightMouseUpToolBox2);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, ToolController.onMouseDownToolBox2);
            ToolController.toolBox2.removeEventListener(MouseEvent.MOUSE_OVER, ToolController.onMouseOverToolBox2);
            main.stage.removeEventListener(KeyboardEvent.KEY_UP, ToolController.onKeyUpToolBox2);
            addInputEventsDrawMode();
        }

        public static function addInputEventsToolBox2(fromShortcut:Boolean):void
        {
            removeInputEventsDrawMode();
            if (fromShortcut)
            {
                ToolController.toolBox2.addEventListener(MouseEvent.MOUSE_OVER, ToolController.onMouseOverToolBox2, false, -2);
                main.stage.addEventListener(KeyboardEvent.KEY_UP, ToolController.onKeyUpToolBox2, false, -2);
            }
            else
            {
                main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, ToolController.onRightMouseUpToolBox2, false, -2);
            }
            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, ToolController.onMouseDownToolBox2, false, -2);
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
                    main.penCursorManager.check();
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

        public static function onKeyDownDrawMode(e:KeyboardEvent):void
        {
            if (CanvasController.isMouseClicked || CanvasController.isRightMouseClicked || CanvasController.isKeyReleasedBeforeMouseUp || main.isFillPenStarted
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
                if (main.resizeCanvas.isResizing() === false)
                {
                    MainUIController.updateCanvasResizeButtonVisible(true);
                }
                }
                return;
            }
            if (isPressingShift())
            {
                if (main.handlePenOpacitySizeKeyDown(secondKey))
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
                                                main.resetRotationDrawMode();
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
                if (main.handlePenOpacitySizeKeyDown(secondKey))
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
                if (main.handlePenOpacitySizeKeyDown(secondKey))
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
        if (main.handlePenOpacitySizeKeyDown(firstKey))
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

public static function clearKeyBuffer():void
        {
            KEY_BUFFER.length = 0;
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
                    main.penCursorManager.check();
                }
            }
        }







        public static function onMouseDownDrawMode(e:MouseEvent):void
        {
            if (main.isFillPenStarted || FileManager.loadMenuBox.visible
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
                        startPressHoldKey(MainUI.topBar.timer, HintStrings.getResetTimerHintString(), null, main.realWorkingTimer.reset, null);
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
                            main.fillPenTool.start();
                        break;
                    case ToolController.TOOL_ERASER:
                        if (CanvasController.isToolEnabledByLayerUnChecked())
                            PenTool.startWithEraserMode();
                        break;
                    case ToolController.TOOL_LINE:
                        if (CanvasController.isToolEnabledByLayerUnChecked())
                            main.lineTool(true);
                        break;
                    case ToolController.TOOL_LASSO:
                        LassoTool.lassoToolFunction.start();
                        break;
                    case ToolController.TOOL_MOVE:
                        main.moveTool();
                        break;
                        // 캔버스 조작
                    case ToolController.TOOL_ZOOM:
                        main.zoomTool();
                        break;
                    case ToolController.TOOL_HAND:
                        main.handTool(false, false);
                        break;
                    case ToolController.TOOL_ROTATE:
                        main.rotateTool(false);
                        break;
                }
            }
        }

        //todo numpad켜져있을때 캔버스 바로 클릭하면 바로 다른 툴 적용되게 바꾸어야함
public static function onRightMouseDownDrawMode(e:MouseEvent):void // rdown1
{
    if (CanvasController.isMouseClicked || isKeyPressed() || isPressingControl() || SidebarController.isQuickSidebarActive
            || main.isFillPenStarted || ToolController.isSelectedTool(ToolController.TOOL_EYEDROPPER) || (ReferenceLayerController.isRefLayerMenuON && ReferenceLayerController.refLayerMenuBox.hitTestPoint(main.mouseX, main.mouseY))
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
                    main.resetRotationDrawMode();
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
                        ToolController.openToolBox2(false);
                    }
                }
            }
            break;
    }
}
    }
}
