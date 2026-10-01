package Modules.InputManager
{
    import Modules.AboutBoxController;
    import Modules.CanvasController;
    import Modules.ClipboardManager;
    import Modules.ColorPickerController;
    import Modules.FileManager;
    import Modules.ImeController;
    import Modules.InputPriority;
    import Modules.MouseState;
    import Modules.PenSizePreviewCursor;
    import Modules.SidebarController;
    import Modules.ToolController;
    import Modules.Utils;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;
    import Modules.CaptureEngine.CaptureController;
    import Modules.Tools.HandTool;
    import Modules.Tools.LassoTool;

    import flash.display.DisplayObject;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.system.IME;
    import Modules.ReplayEngine.ReplayState;

    public class InputManager
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


        // handle mouse click 이벤트에서 이벤트 한번만 추가되게 하기
        public static var handMouseClickEventStarted:Boolean = false;

        public static function startScratchPadResetTimer(target:DisplayObject):void
        {
            FOFOTimer.addByName("clearScratchPadTimer", 0.4, false, function ():void
                {
                    startPressHoldKey(target, "Clearing scratch pad..", null, ColorPickerController.colorPickerBox.scratchPad.clearPad, null);
                });
        }

        // abortFunc: 길게 누르는 도중에 true를 반환하면 취소함 (예: worker가 시작되어 리플레이 데이터가 잠겼을때)
        public static function startPressHoldKey(button:DisplayObject, hintStr:String, readyFunc:Function, okFunc:Function, cancelFunc:Function, abortFunc:Function = null):void
        {
            if (!FOFOTimer.hasTimer("pressholdtimer"))
            {
                var keyBufferLenSave:uint = getPressedKeyCount();
                var mouseClickONSave:Boolean = MouseState.isLeftDown;
                var rightMouseClickONSave:Boolean = MouseState.isRightDown;
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
                    HintController.hideMouseHint();
                }
                if (hintStr !== "")
                {
                    HintController.showMouseHint(hintStr + " " + pressHoldCountDownTime);
                }
                FOFOTimer.addByName("pressholdtimer", 0.0, true, function ():Boolean
                    {
                        if (MouseState.isLeftDown !== mouseClickONSave
                                || MouseState.isRightDown !== rightMouseClickONSave
                                || keyBufferLenSave !== getPressedKeyCount()
                                || (button && button.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
                                || (abortFunc !== null && abortFunc() === true))
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
                        HintController.showMouseHint(hintStr + " " + pressHoldCountDownTime);
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

        // 지금 누르고 있는 키 중 마지막 키를 저장함 (반복되는 keydown에서 한 번만 처리하려고)
        public static function updateLastKey():void
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

        // onClick을 주면 같은 버튼에서 마우스를 뗐을때 아래 switch 대신 onClick(targetName)을 호출함
        public static function handleMouseClickStage(targetName:String, onClick:Function = null):void
        {
            if (handMouseClickEventStarted === true)
            {
                return;
            }

            handMouseClickEventStarted = true;
            if (AboutBoxController.isAboutBoxOpened)
            {
                function onMouseUpAboutBox(e:MouseEvent):void
                {
                    main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpAboutBox);
                    const upTargetName:String = e.target.name;
                    if (targetName === upTargetName)
                    {
                        AboutBoxController.handlerMouseUpAboutBox(targetName);
                    }
                    handMouseClickEventStarted = false;
                }
                main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpAboutBox, false, InputPriority.DEFAULT);
                return;
            }

            function onMouseUp(e:MouseEvent):void
            {
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
                handMouseClickEventStarted = false;
                const upTargetName:String = e.target.name;
                if (targetName === upTargetName)
                {
                    if (onClick !== null)
                    {
                        onClick(upTargetName);
                    }
                    else
                    {
                        onClickCommonButton(upTargetName);
                    }
                }
            }
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, InputPriority.DEFAULT);
        }

        // 드로우 모드와 리플레이 모드가 같이 쓰는 상단바 버튼
        private static function onClickCommonButton(targetName:String):void
        {
            switch (targetName)
            {
                case "saveButton":
                    {
                        FileManager.openSaveFileBrowser(false);
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
                case "topBarColorButton":
                    {
                        UIController.cycleUIColor();
                    }
                    break;
            }
        }

        public static function onMouseDownStage(e:MouseEvent):void
        {
            checkInvalidKey();
            MouseState.onLeftDown();
            HintController.hideBottomHint();
        }

        public static function onMouseUpStage(e:MouseEvent):void
        {
            checkInvalidKey();
            MouseState.onLeftUp();
        }

        public static function onRightMouseDownStage(e:MouseEvent):void
        {
            checkInvalidKey();
            MouseState.onRightDown();
        }

        public static function onRightMouseUpStage(e:MouseEvent):void
        {
            checkInvalidKey();
            MouseState.onRightUp();
        }

        public static function onMouseWheelStage(e:MouseEvent):void
        {
            if (MouseState.isLeftDown || MouseState.isRightDown || MouseState.isDragging
                    || UIController.isPopUpWindowOpened()
                    || CaptureController.isCaptureModeON || !SidebarController.isQuickSidebarActive && InputManager.isKeyPressed() || InputManager.getCommandKey() !== 0)
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
                        else if (!ReplayState.isReplayModeON && Utils.isCursorInDrawArea())
                        {
                            if (e.delta > 0)
                            {
                                CanvasController.zoomInCanvas(true, false);
                                HintController.showMouseHintTemp(Math.floor(CanvasController.canvasZoomMultipler * 100) + "%");
                            }
                            else
                            {
                                CanvasController.zoomInCanvas(false, false);
                                HintController.showMouseHintTemp(Math.floor(CanvasController.canvasZoomMultipler * 100) + "%");
                            }
                        }
                    });
            }
        }

        public static function onMouseLeaveStage(e:Event):void
        {
            MouseState.resetAll();
            PenSizePreviewCursor.setVisible(false);
        }

        public static function onMiddleMouseDownStage(e:MouseEvent):void
        {
            MouseState.onMiddleDown();

            if (CaptureController.isCaptureModeON)
                return;

            if (FOFOTimer.hasTimer("toolTipTempONTimer"))
            {
                HintController.hideMouseHint();
            }

            if (LassoTool.isStarted)
            {
                LassoTool.lassoMenuBox.visible = false;
                LassoTool.isLassoMenuHiddenTemp = true;
            }

            if (ReplayState.isReplayModeON)
            {
                HandTool.startInReplayModeWithWheelClick();
            }
            else
            {
                HandTool.startInDrawModeWithWheelClick();
            }

            ToolController.showNowToolIconToCursorTemp(ToolController.TOOL_HAND);
        }

        // 누르고 있는 키가 없으면 마지막 키 기록을 지움
        public static function checkGeneralKeyUp():void
        {
            if (keyBuffer.length === 0)
            {
                resetLastKey();
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

        public static function isPressedKey(key:int):Boolean
        {
            if (keyBuffer.lastIndexOf(key) > -1)
            {
                return true;
            }
            return false;
        }
        public static function getPressedKeyIndex(key:int):int
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
            // 디버그 확인용
            // if(isPressedKey(KEY.f12))
            // {
            //     UIController.applyLayout();
            // }

            checkInvalidKey();
            ImeController.logKeyUp(e);
            const index:int = getPressedKeyIndex(e.keyCode);
            if (index > -1)
            {
                keyBuffer.splice(index, 1);
            }
            ImeController.refresh();
        }

        public static function onKeyDownStage(e:KeyboardEvent):void
        {
            checkInvalidKey();
            // IME가 가져간 키는 단축키로 처리하지 않음 (keyCode가 229 등이라 실제 키를 알 수 없음)
            if (ImeController.interceptKeyDown(e))
            {
                return;
            }
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
            ImeController.refresh();
        }

        public static function addKeyRepeatEvents():void
        {
            main.stage.nativeWindow.addEventListener(Event.DEACTIVATE, removeKeyRepeatEvents);
            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, removeKeyRepeatEvents, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, removeKeyRepeatEvents, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, removeKeyRepeatEvents, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, removeKeyRepeatEvents, false, InputPriority.DEFAULT);
            main.stage.addEventListener(KeyboardEvent.KEY_UP, removeKeyRepeatEvents, false, InputPriority.DEFAULT);
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

        public static function checkSubKey(expectedLength:uint, updateFlag:Boolean, callback:Function):Boolean
        {
            if (getPressedKeyCount() !== expectedLength)
            {
                return false;
            }
            const subKey:uint = getLastPressedKey();
            if (updateFlag)
            {
                updateLastKey();
            }
            if (callback !== null)
            {
                callback(subKey);
            }
            return true;
        }

        public static function unblockMouseClickAfterDelay():void
        {
            FOFOTimer.addByName("clickBlockTimer", 0.15, false, function ():void
                {
                    MouseState.isClickBlocked = false;
                });
        }

        public static function clearKeyBuffer():void
        {
            keyBuffer.length = 0;
            resetLastKey();
        }

        public static function onMouseMoveUpdatePenPreviewCursor(e:MouseEvent):void
        {
            if (ReplayState.isReplayModeON || CaptureController.isCaptureModeON)
            {
                return;
            }

            PenSizePreviewCursor.updatePosAndVisibility();
        }
    }
}
