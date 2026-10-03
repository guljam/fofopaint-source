package Modules.InputManager
{
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.MouseState;
    import Modules.ActivityWorkTimer;
    import Modules.ClipboardManager;
    import Modules.FileManager;
    import Modules.LoadBoxController;
    import Modules.InputPriority;
    import Modules.CaptureEngine.CaptureController;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayState;
    import Modules.Tools.HandTool;
    import Modules.Tools.RotateTool;
    import Modules.UIEngine.UIController;

    import flash.display.DisplayObject;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;

    // 리플레이 모드의 키보드/마우스 입력
    public class ReplayModeInput
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static var isEventsAdded:Boolean = false; // 이벤트 중복 추가 방지

        // rotate hand zoom에서 쓰임
        public static function addEvents():void
        {
            if (isEventsAdded === false)
            {
                isEventsAdded = true;
                main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownReplayMode, false, InputPriority.MODE);
                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownReplayMode, false, InputPriority.MODE);
                main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownReplayMode, false, InputPriority.MODE);
                main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpReplayMode, false, InputPriority.MODE);
            }
        }

        public static function removeEvents():void
        {
            isEventsAdded = false;
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownReplayMode);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownReplayMode);
            main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownReplayMode);
            main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpReplayMode);
        }

        // 리플레이 버튼은 누른 버튼에서 마우스를 뗐을때 실행됨 (InputManager.handleMouseClickStage가 호출)
        private static function onClickReplayButton(targetName:String):void
        {
            switch (targetName)
            {
                case "drawModeButton":
                    {
                        ReplayController.exitReplayMode();
                    }
                    break;
                case "replayZoomInButton":
                    {
                        ReplayDrawer.viewport.zoomStep(true);
                    }
                    break;
                case "replayZoomOutButton":
                    {
                        ReplayDrawer.viewport.zoomStep(false);
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
            }
        }

        private static function handleControlSubKeyReplayMode(input:int):void
        {
            if (input === InputManager.KEY.c || input === InputManager.KEY.comma)
            {
                CaptureController.enterCaptureMode();
            }
            else if (input === InputManager.KEY.v || input === InputManager.KEY.m)
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
                case InputManager.KEY.left:
                case InputManager.KEY.z:
                case InputManager.KEY.dot:
                    {
                        if (!ReplayState.isReplayStarted)
                        {
                            InputManager.startKeyRepeat(true, ReplayController.moveToPreviousFrame);
                        }
                    }
                    break;
                case InputManager.KEY.right:
                case InputManager.KEY.x:
                case InputManager.KEY.comma:
                    {
                        if (!ReplayState.isReplayStarted)
                        {
                            InputManager.startKeyRepeat(true, ReplayController.moveToNextFrame);
                        }
                    }
                    break;
            }
        }

        private static function onKeyUpReplayMode(e:KeyboardEvent):void
        {
            InputManager.checkGeneralKeyUp();
        }
        private static function onKeyDownReplayMode(e:KeyboardEvent):void // keydown2
        {
            const firstKey:uint = InputManager.getFirstPressedKey();
            if (MouseState.isLeftDown || MouseState.isRightDown || InputManager.isLastKey(firstKey) || LoadBoxController.loadMenuBox.visible)
            {
                return;
            }
            if (ReplayState.isReplayStarted)
            {
                switch (firstKey)
                {
                    case InputManager.KEY.backspace:
                    case InputManager.KEY.esc:
                    case InputManager.KEY.enter:
                    case InputManager.KEY.space:
                        {
                            InputManager.updateLastKey();
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
                    case InputManager.KEY.backspace:
                    case InputManager.KEY.esc:
                    case InputManager.KEY.enter:
                    case InputManager.KEY.space:
                        {
                            InputManager.updateLastKey();
                            ReplayController.cancelReplayRestartTimer();
                        }
                        break;
                }
                return;
            }
            if (InputManager.isPressingShift())
            {
                InputManager.checkSubKey(2, false, handleShiftSubKeyReplayMode);
                return;
            }
            else if (InputManager.isPressingControl())
            {
                InputManager.checkSubKey(2, true, handleControlSubKeyReplayMode);
                return;
            }
            InputManager.updateLastKey();
            switch (firstKey)
            {
                case InputManager.KEY.left:
                case InputManager.KEY.z:
                case InputManager.KEY.dot:
                    {
                        if (!ReplayState.isReplayStarted)
                        {
                            InputManager.startKeyRepeat(true, ReplayController.moveToPreviousStep);
                        }
                    }
                    break;
                case InputManager.KEY.right:
                case InputManager.KEY.x:
                case InputManager.KEY.comma:
                    {
                        if (!ReplayState.isReplayStarted)
                        {
                            InputManager.startKeyRepeat(true, ReplayController.moveToNextStep);
                        }
                    }
                    break;
                case InputManager.KEY.up:
                case InputManager.KEY.f:
                case InputManager.KEY.h:
                    {
                        if (!ReplayState.isReplayStarted)
                        {
                            ReplayController.startAdjustPlayBackSpeedByShortcut(true);
                        }
                    }
                    break;
                case InputManager.KEY.down:
                case InputManager.KEY.v:
                case InputManager.KEY.n:
                    {
                        if (!ReplayState.isReplayStarted)
                        {
                            ReplayController.startAdjustPlayBackSpeedByShortcut(false);
                        }
                    }
                    break;
                case InputManager.KEY.backspace:
                case InputManager.KEY.esc:
                case InputManager.KEY.f1:
                case InputManager.KEY.f7:
                    {
                        ReplayController.exitReplayMode();
                    }
                    break;
                case InputManager.KEY.enter:
                case InputManager.KEY.space:
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

        private static function onRightMouseDownReplayMode(e:MouseEvent):void
        {
            if (MouseState.isLeftDown || InputManager.isKeyPressed() || !e.target || LoadBoxController.loadMenuBox.visible)
            {
                return;
            }

            const targetName:String = e.target.name;

            switch (targetName)
            {
                case "replayPrev":
                    {
                        InputManager.startKeyRepeat(true, ReplayController.moveToPreviousFrame);
                        InputManager.startKeyRepeatStopTimerOnMouseLeave(e.target as DisplayObject);
                    }
                    break;
                case "replayNext":
                    {
                        InputManager.startKeyRepeat(true, ReplayController.moveToNextFrame);
                        InputManager.startKeyRepeatStopTimerOnMouseLeave(e.target as DisplayObject);
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

        private static function onMouseDownReplayMode(e:MouseEvent):void // repdown1
        {
            const target:DisplayObject = e.target as DisplayObject;
            if (!target || LoadBoxController.loadMenuBox.visible)
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
                    if (InputManager.isKeyPressed())
                    {
                        return;
                    }
                    InputManager.handleMouseClickStage(targetName, onClickReplayButton);
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
                        InputManager.startPressHoldKey(UIController.topBar.repNewFileButton, HintStrings.getNewFileHintString(),
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
                        if (UIController.topBar.cutPrevDataButton.alpha === 1.0)
                        {
                            InputManager.startPressHoldKey(UIController.topBar.cutPrevDataButton, HintStrings.getDeleteReplayDataHintString(), function ():Boolean
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
                        if (UIController.topBar.superUndoButton.alpha === 1.0)
                        {
                            InputManager.startPressHoldKey(UIController.topBar.superUndoButton, HintStrings.getDeleteReplayDataHintString(), function ():Boolean
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
                        if (InputManager.isPressingShift())
                        {
                            InputManager.startKeyRepeat(true, ReplayController.moveToPreviousFrame);
                            InputManager.startKeyRepeatStopTimerOnMouseLeave(target);
                        }
                        else
                        {
                            InputManager.startKeyRepeat(true, ReplayController.moveToPreviousStep);
                            InputManager.startKeyRepeatStopTimerOnMouseLeave(target);
                        }
                    }
                    break;
                case "replayNext":
                    {
                        FOFOTimer.remove("prograssBarUpdateTimer");
                        if (InputManager.isPressingShift())
                        {
                            InputManager.startKeyRepeat(true, ReplayController.moveToNextFrame);
                            InputManager.startKeyRepeatStopTimerOnMouseLeave(target);
                        }
                        else
                        {
                            InputManager.startKeyRepeat(true, ReplayController.moveToNextStep);
                            InputManager.startKeyRepeatStopTimerOnMouseLeave(target);
                        }
                    }
                    break;
                case "timer":
                    {
                        InputManager.startPressHoldKey(UIController.topBar.timer, HintStrings.getResetTimerHintString(), null, ActivityWorkTimer.reset, null);
                    }
                    break;
                case "drawModeButton":
                case "playButton":
                case "pauseButton":
                case "replayZoomInButton":
                case "replayZoomOutButton":
                case "replayFitToWindowButton":
                    {
                        if (InputManager.isKeyPressed())
                        {
                            return;
                        }
                        InputManager.handleMouseClickStage(targetName, onClickReplayButton);
                    }
                    break;
                // 캡처 모드로 들어가면 리플레이 입력이 해제되므로 실제로는 여기로 오지 않음
                case "capOff":
                case "capSave":
                case "capClipBoard":
                case "capTrans":
                case "capFlip":
                case "capRotate":
                    {
                        if (InputManager.isKeyPressed())
                        {
                            return;
                        }
                        InputManager.handleMouseClickStage(targetName, CaptureModeInput.onClickCaptureButton);
                    }
                    break;
                // 드로우 모드와 같이 쓰는 상단바 버튼
                case "saveButton":
                case "captureButton":
                case "repCaptureButton":
                case "clipBoardButton":
                case "topBarColorButton":
                    {
                        if (InputManager.isKeyPressed())
                        {
                            return;
                        }
                        InputManager.handleMouseClickStage(targetName);
                    }
                    break;
            }
        }
    }
}
