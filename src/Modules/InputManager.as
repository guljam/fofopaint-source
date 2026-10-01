package Modules
{
    import Modules.UIEngine.UITheme;
    import Modules.CaptureEngine.CaptureStamp;
    import Modules.CaptureEngine.CaptureController;
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
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayState;
    import flash.text.TextInteractionMode;

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

        // todo 이거 쓰나?
        public static var isLayerCheckKeyPressed:Boolean = false;
        public static var isDrawModeInputEventsAdded:Boolean = false;
        public static var isCaptureModeInputEventsAdded:Boolean = false; // 이벤트 세트가 켜지거나 꺼지는거 보관 중복 이벤트 추가 피하려고
        public static var isReplayModeInputEventsAdded:Boolean = false; // 리플레이 이벤트 추가되면 올려줌

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

        // todo: 분야별로 분리해야
        public static function handleMouseClickStage(targetName:String):void
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
                                CaptureController.toggleLayerCaptureMode(1);
                            }
                            break;
                        case "capLayer2VisibleButton":
                            {
                                CaptureController.toggleLayerCaptureMode(2);
                            }
                            break;
                        case "dpiButton":
                            {
                                UITheme.setNextScaleIndex();
                                MainUIController.applyUIScale();
                                MainUI.showMouseHintTemp(UITheme.getUIScaleString());
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
                                CaptureController.rotateCaptureImage(CaptureController.captureCanvasRotationStep + 1, false);
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
                                CaptureStamp.toggleCaptureStampButton();
                            }
                            break;
                        case "capStampFont":
                            {
                                if (CaptureStamp.captureStampFontListBox.visible)
                                {
                                    CaptureStamp.hideStampFontList();
                                }
                                else
                                {
                                    CaptureStamp.showStampFontList();
                                }
                            }
                            break;
                        case "capFontListPrev":
                            {
                                CaptureStamp.captureStampFontListBox.updateNextFontList(false);
                            }
                            break;
                        case "capFontListNext":
                            {
                                CaptureStamp.captureStampFontListBox.updateNextFontList(true);
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
                                LassoTool.cancelIfActive();
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
                                MainUI.showMouseHintTemp(HintStrings.getCanvasLayerSwappedHintString());
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
            MainUI.hideBottomHint();
        }

        public static function onMouseUpStage(e:MouseEvent):void
        {
            InputManager.checkInvalidKey();
            const mx:Number = main.stage.mouseX;
            const my:Number = main.stage.mouseY;
            MouseState.onLeftUp();
        }

        public static function onRightMouseDownStage(e:MouseEvent):void
        {
            checkInvalidKey();
            MouseState.onRightDown();
        }

        public static function onRightMouseUpStage(e:MouseEvent):void
        {
            InputManager.checkInvalidKey();
            const mx:Number = main.stage.mouseX;
            const my:Number = main.stage.mouseY;
            MouseState.onRightUp();
        }

        public static function onMouseWheelStage(e:MouseEvent):void
        {
            if (CanvasController.isMouseLeftClicked || CanvasController.isRightMouseClicked || CanvasController.isMouseDragging
                    || MainUIController.isPopUpWindowOpened()
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
                MainUI.hideMouseHint();
            }

            if (LassoTool.isStarted)
            {
                LassoTool._lassoMenuBox.visible = false;
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

        public static function checkGeneralKeyUp(keyCode:uint):void
        {
            if (keyBuffer.length === 0)
            {
                resetLastKey();
            }
            else if (!CaptureController.isCaptureModeON && !ReplayState.isReplayModeON && isLastKey(keyCode))
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
            //     MainUIController.applyLayout();
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

                if (targetName.indexOf(UITheme.ALPHA_BUTTON_PREFIX) == 0)
                {
                    ToolController.onOpacityButtonDown(targetName);
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
            else if (Utils.isCursorInDrawArea() && SidebarController.isQuickSidebarActive === false)
            {
                main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);
                MouseState.beginDrag(FILLPEN_DRAG_OWNER, finishFillPenDrag);

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
            // 드래그 도중 FillPen이 종료되면(파일 로드로 취소 등) onMouseUpFillPen이 안 불리므로 여기서 등록을 해제함
            MouseState.endDrag(FILLPEN_DRAG_OWNER);
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
            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownFillPen, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpFillPen, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownFillPen, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpFillPen, false, InputPriority.DEFAULT);
            main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpFillPen, false, InputPriority.DEFAULT);
            main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeydownFillPen, false, InputPriority.DEFAULT);
        }

        public static function onRightMouseDownFillPen(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;

            if (CanvasController.isMouseLeftClicked
                    || SidebarController.isQuickSidebarActive
                    || !target
                    || ColorPickerController.numPadBox.visible)
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

            FillPenTool.showFillPenMenuBox()
        }

        private static const FILLPEN_DRAG_OWNER:String = "fillPenDrag";

        // 첫 획은 onMouseDownFillPen이 아니라 FillPenTool.start()가 시작하므로 거기서 호출해 등록함
        public static function beginFillPenDrag():void
        {
            MouseState.beginDrag(FILLPEN_DRAG_OWNER, finishFillPenDrag);
        }

        // 이벤트 객체를 쓰지 않음. mouseUp을 못받는 경우(alt+tab 등)에 MouseState.finishAllDrags가 직접 호출함
        // onMouseUpFillPen에서 버튼 클릭 판정(e.target)이 필요 없는 마무리 부분만 수행함
        private static function finishFillPenDrag():void
        {
            MouseState.endDrag(FILLPEN_DRAG_OWNER);
            FOFOTimer.remove("previewFilledColorUpdateTimer");
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);

            // 드래그 도중 FillPen이 이미 종료됐다면(등록이 남은 경우) 미리보기를 다시 그리지 않음
            if (FillPenTool.isStarted && !FillPenTool.fillPenBox.visible)
            {
                FillPenTool.handleOnMouseUp();
            }

            FillPenTool.afterKeyUpOK = false;
        }

        public static function onMouseUpFillPen(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;

            if (!target)
            {
                return;
            }

            const targetName:String = e.target.name;

            MouseState.endDrag(FILLPEN_DRAG_OWNER);
            FOFOTimer.remove("previewFilledColorUpdateTimer");
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
            if (CanvasController.isMouseLeftClicked
                    || CanvasController.isRightMouseClicked
                    || CanvasController.isKeyReleasedBeforeMouseUp
                    || FillPenTool.isStarted
                    || LineTool.isStarted
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
            if (Utils.isCursorInDrawArea() && LassoTool._lassoMenuBox.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
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
                        InputManager.handleMouseClickStage(targetName);
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
            if (!LassoTool.isStarted)
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
            if (!LassoTool.isStarted || CanvasController.isMouseLeftClicked)
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
            main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpLassoTool, false, InputPriority.DEFAULT);
            main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownLassoTool, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownLassoTool, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpLassoTool, false, InputPriority.MODE);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownLassoTool, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpLassoTool, false, InputPriority.DEFAULT);
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
                        if (!ReplayState.isReplayStarted)
                        {
                            startKeyRepeat(true, ReplayController.moveToPreviousFrame);
                        }
                    }
                    break;
                case KEY.right:
                case KEY.x:
                case KEY.comma:
                    {
                        if (!ReplayState.isReplayStarted)
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
                        startPressHoldKey(MainUI.topBar.timer, HintStrings.getResetTimerHintString(), null, ActivityWorkTimer.reset, null);
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
                        if (UITheme.getUIScaleIndex() !== 0)
                        {
                            UITheme.resetScaleIndex();
                            MainUIController.applyUIScale();
                            MainUI.showMouseHintTemp(UITheme.getUIScaleString());
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

        private static function onKeyDownCaptureMode(e:KeyboardEvent):void
        {
            const firstKey:uint = getFirstPressedKey();
            if (CaptureStamp.captureStampFontListBox.visible)
            {
                if (firstKey === KEY.esc)
                {
                    CaptureStamp.hideStampFontList();
                }
                return;
            }

            if (main.stage.focus === MainUI.topBar.captureInput)
            {
                if (firstKey === KEY.esc || firstKey === KEY.enter || isPressingControl())
                {
                    main.stage.focus = null;
                }
                return;
            }

            if (CanvasController.isMouseLeftClicked || CanvasController.isRightMouseClicked)
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
                main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpCaptureMode, false, InputPriority.MODE);
                main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownCaptureMode, false, InputPriority.MODE);
                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownCaptureMode, false, InputPriority.MODE);
                main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownCaptureMode, false, InputPriority.MODE);
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
                InputManager.handleMouseClickStage(targetName);
                return;
            }

            if (targetName === "capClipBoard")
            {
                CaptureController.executeCaptureFlashEffect();
                if (target.alpha < 1.0 && MainUI.topBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                {
                    return;
                }
                InputManager.handleMouseClickStage(targetName);
            }

            if (target.alpha < 1.0 && MainUI.topBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
            {
                return;
            }

            if (CaptureStamp.captureStampFontListBox.visible)
            {
                if (targetName === "capFontListNext" || targetName === "capFontListPrev")
                {
                    InputManager.handleMouseClickStage(targetName);
                }
                else if (targetName && targetName.indexOf(CaptureStamp.captureStampFontListBox.getStampFontButtonName()) !== -1)
                {
                    CaptureStamp.changeFont(CaptureStamp.captureStampFontListBox.getFontName(targetName), true);
                }
                else if (target.parent)
                {
                    if (target.parent.name && target.parent.name.indexOf(CaptureStamp.captureStampFontListBox.getStampFontButtonName()) !== -1)
                    {
                        CaptureStamp.changeFont(CaptureStamp.captureStampFontListBox.getFontName(target.parent.name), true);
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
                    InputManager.handleMouseClickStage(targetName);
                    break;
                case "timer":
                    startPressHoldKey(MainUI.topBar.timer, HintStrings.getResetTimerHintString(), null, ActivityWorkTimer.reset, null);
                    break;
                default:
                    if (!CanvasController.isMouseClickBlocked)
                    {
                        CaptureController.startCaptureAreaSelection();
                    }
                    break;
            }
        }

        private static function onRightMouseDownCaptureMode(e:MouseEvent):void
        {
            if (MainUI.topBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
            {
                if (!CaptureController.isFullImageCapture())
                {
                    CaptureController.resetCaptureAreaSelection();
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
            if (ReplayState.isReplayStarted)
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
                        if (!ReplayState.isReplayStarted)
                        {
                            startKeyRepeat(true, ReplayController.moveToPreviousStep);
                        }
                    }
                    break;
                case KEY.right:
                case KEY.x:
                case KEY.comma:
                    {
                        if (!ReplayState.isReplayStarted)
                        {
                            startKeyRepeat(true, ReplayController.moveToNextStep);
                        }
                    }
                    break;
                case KEY.up:
                case KEY.f:
                case KEY.h:
                    {
                        if (!ReplayState.isReplayStarted)
                        {
                            ReplayController.startAdjustPlayBackSpeedByShortcut(true);
                        }
                    }
                    break;
                case KEY.down:
                case KEY.v:
                case KEY.n:
                    {
                        if (!ReplayState.isReplayStarted)
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
                main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownReplayMode, false, InputPriority.MODE);
                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownReplayMode, false, InputPriority.MODE);
                main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownReplayMode, false, InputPriority.MODE);
                main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpReplayMode, false, InputPriority.MODE);
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
                        else if (!ReplayState.isReplayStarted)
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
                if (ReplayController.seekBarBox.trackBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
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
                    InputManager.handleMouseClickStage(targetName);
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
                                    ReplayController.seekBarBox.setDeleteRangeBarVisible(false);
                                },
                                FileManager.isReplayDataLocked);
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
                                        ReplayController.seekBarBox.setDeleteRangeBarVisible(false);
                                    },
                                    FileManager.isReplayDataLocked);
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
                                        ReplayController.seekBarBox.setDeleteRangeBarVisible(false);
                                    },
                                    FileManager.isReplayDataLocked);
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
                        InputManager.handleMouseClickStage(targetName);
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
