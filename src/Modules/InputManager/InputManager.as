package Modules.InputManager
{
    import Modules.AboutBoxController;
    import Modules.ActivityWorkTimer;
    import Modules.AppUpdater;
    import Modules.CanvasController;
    import Modules.CanvasGridOverlay;
    import Modules.ClipboardManager;
    import Modules.ColorPickerController;
    import Modules.DragInteraction;
    import Modules.FileManager;
    import Modules.ImageViewWindow;
    import Modules.ImeController;
    import Modules.InputPriority;
    import Modules.MouseState;
    import Modules.PenSizePreviewCursor;
    import Modules.ReferenceLayerController;
    import Modules.SidebarController;
    import Modules.ToolController;
    import Modules.UndoController;
    import Modules.Utils;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;
    import Modules.UIEngine.UITheme;
    import Modules.CaptureEngine.CaptureController;
    import Modules.Tools.HandTool;
    import Modules.Tools.LassoTool;
    import Modules.Tools.LineTool;
    import Modules.Tools.FillPenTool;
    import Modules.Tools.MoveTool;
    import Modules.Tools.PenTool;
    import Modules.Tools.RotateTool;
    import Modules.Tools.ZoomTool;

    import flash.display.DisplayObject;
    import flash.display.SimpleButton;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.system.IME;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayState;

    public class InputManager
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

        public static var isDrawModeInputEventsAdded:Boolean = false;

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
                    HintController.hideMouseHint();
                }
                if (hintStr !== "")
                {
                    HintController.showMouseHint(hintStr + " " + pressHoldCountDownTime);
                }
                FOFOTimer.addByName("pressholdtimer", 0.0, true, function ():Boolean
                    {
                        if (CanvasController.isMouseLeftClicked !== mouseClickONSave
                                || CanvasController.isRightMouseClicked !== rightMouseClickONSave
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

        // 인자로 받은 키가 아니라 keyBuffer의 마지막 키를 저장함 (기존 동작 유지)
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

        // todo: 분야별로 분리해야
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
                        return;
                    }

                    switch (upTargetName)
                    {
                        case "replayModeButton":
                            {
                                ReplayController.enterReplayMode();
                                CanvasController.isMouseLeftClicked = false; // 리플레이 버튼 누르고 나서 단축키가 안먹는 현상이 이거임
                            }
                            break;
                        case "dpiButton":
                            {
                                UITheme.setNextScaleIndex();
                                UIController.applyUIScale();
                                HintController.showMouseHintTemp(UITheme.getUIScaleString());
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
                        case "topBarColorButton":
                            {
                                UIController.cycleUIColor();
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
                        case "layerMergeButton":
                            {
                                CanvasController.mergeImageIntoLayer2();
                                HintController.showMouseHintTemp("Layers has been merged to layer 2");
                            }
                            break;
                        case "layerSwapButton":
                            {
                                CanvasController.swapLayer();
                                HintController.showMouseHintTemp(HintStrings.getCanvasLayerSwappedHintString());
                            }
                            break;
                        default:
                            break;
                    }
                }
            }
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, InputPriority.DEFAULT);
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
            if (CanvasController.isMouseLeftClicked || CanvasController.isRightMouseClicked || CanvasController.isMouseDragging
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
                main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpDrawMode, false, InputPriority.MODE);
                main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownDrawMode, false, InputPriority.MODE);
                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownDrawMode, false, InputPriority.MODE);
                main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpDrawMode, false, InputPriority.MODE);
                main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownDrawMode, false, InputPriority.MODE);
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
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpToolBox2, false, InputPriority.LATE);
            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownToolBox2, false, InputPriority.LATE);
        }

        public static function onRightMouseUpToolBox2(e:MouseEvent):void
        {
            PenSizePreviewCursor.setCursorInVisibleFlag(false);

            if (LassoTool.isStarted === true)
            {
                ToolController.closeToolBox2();
                return;
            }

            const target:SimpleButton = e.target as SimpleButton;

            if (!target || target.alpha < 1.0 || !Utils.isCursorInDrawArea())
            {
                ToolController.closeToolBox2();
                return;
            }

            ToolController.handleToolBox2Closing(target);
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
                if (CanvasController.resizeButtonR.visible)
                {
                    CanvasController.updateCanvasResizeButtonVisible(false);
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
                updateLastKey();
            }
            if (callback !== null)
            {
                callback(subKey);
            }
            return true;
        }

        public static function onKeyDownDrawMode(e:KeyboardEvent):void
        {
            if (CanvasController.isMouseLeftClicked
                    || CanvasController.isRightMouseClicked
                    || CanvasController.isKeyReleasedBeforeMouseUp
                    || FillPenTool.isStarted
                    || LineTool.isStarted
                    || UIController.isPopUpWindowOpened())
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
                        CanvasController.updateCanvasResizeButtonVisible(true);
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
            updateLastKey();
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
                            UIController.updateCanvasNaigatorCursor();
                        }
                    }
                    return;
                case KEY.w:
                case KEY.i:
                    {
                        if (CanvasController.canvasZoomMultipler !== 1.0)
                        {
                            CanvasController.resetZoomDrawMode();
                            UIController.updateCanvasNaigatorCursor();
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
                            HintController.showMouseHintTemp("Layer 1 selected");
                            CanvasController.selectLayer1(false);
                        }
                        else
                        {
                            CanvasController.selectLayer1(CanvasController.canvasLayer2Bitmap.visible);
                            HintController.showMouseHintLayerVisible();
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
                            HintController.showMouseHintTemp("Layer 2 selected");
                            CanvasController.selectLayer2(false);
                        }
                        else
                        {
                            CanvasController.selectLayer2(CanvasController.canvasLayer1Bitmap.visible);
                            HintController.showMouseHintLayerVisible();
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
                    return true;
                case KEY.x:
                case KEY.comma:
                    {
                        startKeyRepeat(true, UndoController.redo);
                        ToolController.showNowToolIconToCursorTemp(ToolController.TOOL_REDO);
                    }
                    return true;
                case KEY.z:
                case KEY.dot:
                    {
                        startKeyRepeat(true, UndoController.undo);
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
            if (FillPenTool.isStarted || LineTool.isStarted || FileManager.loadMenuBox.visible
                    || UIController.topBar.gridButtonWrapper.visible || ColorPickerController.numPadBox.visible)
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
                        InputManager.handleMouseClickStage(targetName);
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
                        startPressHoldKey(UIController.topBar.timer, HintStrings.getResetTimerHintString(), null, ActivityWorkTimer.reset, null);
                    }
                    return;
                case "newFileButton":
                    {
                        if (FileManager.canCreateNewFile())
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
            if (Utils.isCursorInDrawArea() && !CanvasController.isMouseClickBlocked)
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
                        LassoTool.startLassoSelection();
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
            trace('right down');
            if (CanvasController.isMouseLeftClicked || isKeyPressed() || isPressingControl() || SidebarController.isQuickSidebarActive
                    || FillPenTool.isStarted || LineTool.isStarted || ToolController.isSelectedTool(ToolController.TOOL_EYEDROPPER) || (ReferenceLayerController.isRefLayerMenuON && ReferenceLayerController.refLayerMenuBox.hitTestPoint(main.mouseX, main.mouseY))
                    || FileManager.loadMenuBox.visible || UIController.topBar.gridButtonWrapper.visible || ColorPickerController.numPadBox.visible)
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
                        if (UITheme.getUIScaleIndex() !== 0)
                        {
                            UITheme.resetScaleIndex();
                            UIController.applyUIScale();
                            HintController.showMouseHintTemp(UITheme.getUIScaleString());
                        }
                    }
                    break;

                case "toolZoomIn":
                case "toolZoomOut":
                    {
                        if (CanvasController.canvasZoomMultipler !== 1.0)
                        {
                            CanvasController.resetZoomDrawMode();
                            UIController.updateCanvasNaigatorCursor();
                        }
                    }
                    break;

                case "gridButton":
                    {
                        if (CanvasGridOverlay.gridGapMultiplier !== 0)
                        {
                            HintController.hideBottomHint();
                            CanvasGridOverlay.resetGrid();
                        }
                    }
                    break;

                case "toolRotate":
                    {
                        if (CanvasController.canvasAnchorPoint.rotation !== 0.0)
                        {
                            CanvasController.resetRotationDrawMode();
                            UIController.updateCanvasNaigatorCursor();
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
                        if (Utils.isCursorInDrawArea())
                        {
                            if (ToolController.isToolBox2Showing && !UndoController.isDeepUndoEnabled)
                            {
                                ToolController.closeToolBox2();
                            }
                            else
                            {
                                ToolController.openToolBox2();
                            }
                        }
                    }
                    break;
            }
        }

        public static function onMouseMoveUpdatePenPreviewCursor(e:MouseEvent):void
        {
            if (ReplayState.isReplayModeON || CaptureController.isCaptureModeON)
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
