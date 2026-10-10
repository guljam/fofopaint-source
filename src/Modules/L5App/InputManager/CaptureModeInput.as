package Modules.L5App.InputManager
{
    import Modules.L1Data.AppContext;

    import flash.display.DisplayObject;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import Modules.L5App.FileManager;
    import Modules.L1Data.KeyState;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L4UI.HintStrings;
    import Modules.L1Data.MouseState;
    import Modules.L4UI.CaptureEngine.CaptureController;
    import Modules.L4UI.CaptureEngine.CaptureStamp;
    import Modules.L4UI.ActivityWorkTimer;
    import Modules.L5App.ClipboardManager;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L1Data.InputPriority;

    // 캡처 모드의 키보드/마우스 입력
    // 층: L5 앱 흐름 - 캡처 모드의 키보드/마우스 입력
    public class CaptureModeInput
    {
        private static var isEventsAdded:Boolean = false; // 이벤트 중복 추가 방지

        public static function addEvents():void
        {
            if (isEventsAdded === false)
            {
                isEventsAdded = true;
                AppContext.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpCaptureMode, false, InputPriority.MODE);
                AppContext.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownCaptureMode, false, InputPriority.MODE);
                AppContext.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownCaptureMode, false, InputPriority.MODE);
                AppContext.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownCaptureMode, false, InputPriority.MODE);
            }
        }

        public static function removeEvents():void
        {
            isEventsAdded = false;
            AppContext.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpCaptureMode);
            AppContext.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownCaptureMode);
            AppContext.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownCaptureMode);
            AppContext.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownCaptureMode);
        }

        // 캡처 버튼은 누른 버튼에서 마우스를 뗐을때 실행됨 (InputManager.handleMouseClickStage가 호출)
        public static function onClickCaptureButton(targetName:String):void
        {
            switch (targetName)
            {
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
            }
        }

        private static function onKeyDownCaptureMode(e:KeyboardEvent):void
        {
            const firstKey:uint = KeyState.getFirstPressedKey();
            if (CaptureStamp.captureStampFontListBox.visible)
            {
                if (firstKey === KeyState.KEY.esc)
                {
                    CaptureStamp.hideStampFontList();
                }
                return;
            }

            if (AppContext.stage.focus === UIController.topBar.captureInput)
            {
                if (firstKey === KeyState.KEY.esc || firstKey === KeyState.KEY.enter || KeyState.isPressingControl())
                {
                    AppContext.stage.focus = null;
                }
                return;
            }

            if (MouseState.isLeftDown || MouseState.isRightDown)
            {
                return;
            }

            if (KeyState.isPressingControl())
            {
                const secondKey:uint = KeyState.getSecondPressedKey();
                if (KeyState.isLastKey(secondKey))
                {
                    return;
                }
                KeyState.updateLastKey();

                if (secondKey === KeyState.KEY.s || secondKey === KeyState.KEY.semicolon)
                {
                    FileManager.saveCaptureImage();
                }
                else if (secondKey === KeyState.KEY.c || secondKey === KeyState.KEY.comma)
                {
                    CaptureController.executeCaptureFlashEffect();
                    if (UIController.topBar.capClipBoard.alpha === 1.0)
                    {
                        CaptureController.copyCaptureImageToCilpBoard();
                    }
                }
                else if (secondKey === KeyState.KEY.v || secondKey === KeyState.KEY.m)
                {
                    if (ClipboardManager.isClipBoardButtonActivated)
                    {
                        ClipboardManager.tryLoadClipboardImage(false);
                    }
                }
                return;
            }

            if (KeyState.isLastKey(firstKey))
            {
                return;
            }

            KeyState.updateLastKey();

            switch (firstKey)
            {
                case KeyState.KEY.esc:
                case KeyState.KEY.backspace:
                case KeyState.KEY.f1:
                case KeyState.KEY.f7:
                    CaptureController.handleExitCaptureMode();
                    break;
                default:
                    break;
            }
        }

        private static function onKeyUpCaptureMode(e:KeyboardEvent):void
        {
            KeyState.updateLastKey();
            KeyState.checkGeneralKeyUp();
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
                InputManager.handleMouseClickStage(targetName, onClickCaptureButton);
                return;
            }

            if (targetName === "capClipBoard")
            {
                CaptureController.executeCaptureFlashEffect();
                if (target.alpha < 1.0 && UIController.topBar.hitTestPoint(AppContext.stage.mouseX, AppContext.stage.mouseY))
                {
                    return;
                }
                InputManager.handleMouseClickStage(targetName, onClickCaptureButton);
            }

            if (target.alpha < 1.0 && UIController.topBar.hitTestPoint(AppContext.stage.mouseX, AppContext.stage.mouseY))
            {
                return;
            }

            if (CaptureStamp.captureStampFontListBox.visible)
            {
                if (targetName === "capFontListNext" || targetName === "capFontListPrev")
                {
                    InputManager.handleMouseClickStage(targetName, onClickCaptureButton);
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
                    InputManager.handleMouseClickStage(targetName, onClickCaptureButton);
                    break;
                case "timer":
                    HintController.startPressHoldKey(UIController.topBar.timer, HintStrings.getResetTimerHintString(), null, ActivityWorkTimer.reset, null);
                    break;
                default:
                    if (!MouseState.isClickBlocked)
                    {
                        CaptureController.startCaptureAreaSelection();
                    }
                    break;
            }
        }

        private static function onRightMouseDownCaptureMode(e:MouseEvent):void
        {
            if (UIController.topBar.hitTestPoint(AppContext.stage.mouseX, AppContext.stage.mouseY) === false)
            {
                if (!CaptureController.isFullImageCapture())
                {
                    CaptureController.resetCaptureAreaSelection();
                }
            }
        }
    }
}
