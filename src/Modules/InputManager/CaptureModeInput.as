package Modules.InputManager
{
    import Modules.MouseState;
    import Modules.ActivityWorkTimer;
    import Modules.ClipboardManager;
    import Modules.FileManager;
    import Modules.InputPriority;
    import Modules.CaptureEngine.CaptureController;
    import Modules.CaptureEngine.CaptureStamp;
    import Modules.UIEngine.UIController;

    import flash.display.DisplayObject;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;

    // 캡처 모드의 키보드/마우스 입력
    // 층: L5 앱 흐름 - 캡처 모드의 키보드/마우스 입력
    public class CaptureModeInput
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static var isEventsAdded:Boolean = false; // 이벤트 중복 추가 방지

        public static function addEvents():void
        {
            if (isEventsAdded === false)
            {
                isEventsAdded = true;
                main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpCaptureMode, false, InputPriority.MODE);
                main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownCaptureMode, false, InputPriority.MODE);
                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownCaptureMode, false, InputPriority.MODE);
                main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownCaptureMode, false, InputPriority.MODE);
            }
        }

        public static function removeEvents():void
        {
            isEventsAdded = false;
            main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpCaptureMode);
            main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownCaptureMode);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownCaptureMode);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownCaptureMode);
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
            const firstKey:uint = InputManager.getFirstPressedKey();
            if (CaptureStamp.captureStampFontListBox.visible)
            {
                if (firstKey === InputManager.KEY.esc)
                {
                    CaptureStamp.hideStampFontList();
                }
                return;
            }

            if (main.stage.focus === UIController.topBar.captureInput)
            {
                if (firstKey === InputManager.KEY.esc || firstKey === InputManager.KEY.enter || InputManager.isPressingControl())
                {
                    main.stage.focus = null;
                }
                return;
            }

            if (MouseState.isLeftDown || MouseState.isRightDown)
            {
                return;
            }

            if (InputManager.isPressingControl())
            {
                const secondKey:uint = InputManager.getSecondPressedKey();
                if (InputManager.isLastKey(secondKey))
                {
                    return;
                }
                InputManager.updateLastKey();

                if (secondKey === InputManager.KEY.s || secondKey === InputManager.KEY.semicolon)
                {
                    FileManager.saveCaptureImage();
                }
                else if (secondKey === InputManager.KEY.c || secondKey === InputManager.KEY.comma)
                {
                    CaptureController.executeCaptureFlashEffect();
                    if (UIController.topBar.capClipBoard.alpha === 1.0)
                    {
                        CaptureController.copyCaptureImageToCilpBoard();
                    }
                }
                else if (secondKey === InputManager.KEY.v || secondKey === InputManager.KEY.m)
                {
                    if (ClipboardManager.isClipBoardButtonActivated)
                    {
                        ClipboardManager.tryLoadClipboardImage(false);
                    }
                }
                return;
            }

            if (InputManager.isLastKey(firstKey))
            {
                return;
            }

            InputManager.updateLastKey();

            switch (firstKey)
            {
                case InputManager.KEY.esc:
                case InputManager.KEY.backspace:
                case InputManager.KEY.f1:
                case InputManager.KEY.f7:
                    CaptureController.handleExitCaptureMode();
                    break;
                default:
                    break;
            }
        }

        private static function onKeyUpCaptureMode(e:KeyboardEvent):void
        {
            InputManager.updateLastKey();
            InputManager.checkGeneralKeyUp();
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
                if (target.alpha < 1.0 && UIController.topBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                {
                    return;
                }
                InputManager.handleMouseClickStage(targetName, onClickCaptureButton);
            }

            if (target.alpha < 1.0 && UIController.topBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
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
                    InputManager.startPressHoldKey(UIController.topBar.timer, HintStrings.getResetTimerHintString(), null, ActivityWorkTimer.reset, null);
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
            if (UIController.topBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
            {
                if (!CaptureController.isFullImageCapture())
                {
                    CaptureController.resetCaptureAreaSelection();
                }
            }
        }
    }
}
