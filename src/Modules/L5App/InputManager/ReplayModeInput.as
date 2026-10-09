package Modules.L5App.InputManager
{
    import Modules.MouseState;
    import Modules.ClipboardManager;
    import Modules.InputPriority;
    import Modules.CaptureEngine.CaptureController;

    import flash.display.DisplayObject;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import Modules.L3Feature.ActivityWorkTimer;
    import Modules.L5App.FileManager;
    import Modules.L3Feature.Tools.HandTool;
    import Modules.L4UI.LoadBoxController;
    import Modules.L5App.ReplayEngine.ReplayController;
    import Modules.L3Feature.Tools.RotateTool;
    import Modules.L1Data.KeyState;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L2Engine.ReplayEngine.ReplayState;

    // 리플레이 모드의 키보드/마우스 입력
    // 층: L5 앱 흐름 - 리플레이 모드의 키보드/마우스 입력
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
            if (input === KeyState.KEY.c || input === KeyState.KEY.comma)
            {
                CaptureController.enterCaptureMode();
            }
            else if (input === KeyState.KEY.v || input === KeyState.KEY.m)
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
                case KeyState.KEY.left:
                case KeyState.KEY.z:
                case KeyState.KEY.dot:
                    {
                        if (ReplayState.canStartReplay())
                        {
                            KeyState.startKeyRepeat(true, ReplayController.moveToPreviousFrame);
                        }
                    }
                    break;
                case KeyState.KEY.right:
                case KeyState.KEY.x:
                case KeyState.KEY.comma:
                    {
                        if (ReplayState.canStartReplay())
                        {
                            KeyState.startKeyRepeat(true, ReplayController.moveToNextFrame);
                        }
                    }
                    break;
            }
        }

        private static function onKeyUpReplayMode(e:KeyboardEvent):void
        {
            KeyState.checkGeneralKeyUp();
        }

        private static function onKeyDownReplayMode(e:KeyboardEvent):void // keydown2
        {
            const firstKey:uint = KeyState.getFirstPressedKey();
            if (MouseState.isLeftDown || MouseState.isRightDown || KeyState.isLastKey(firstKey) || LoadBoxController.loadMenuBox.visible)
            {
                return;
            }

            if (ReplayState.isReplayStarted)
            {
                switch (firstKey)
                {
                    case KeyState.KEY.backspace:
                    case KeyState.KEY.esc:
                    case KeyState.KEY.space:
                        {
                            KeyState.updateLastKey();
                            FOFOTimer.remove("prograssBarUpdateTimer");
                            ReplayController.handleReplayStopButton();
                        }
                        break;
                    // 재생 중 배속/줌 조절 (shift/ctrl 조합은 제외). 줌 키는 반복 없이 키를 떼기 전에는 다시 들어오지 않음
                    case KeyState.KEY.up:
                    case KeyState.KEY.f:
                    case KeyState.KEY.h:
                        {
                            if (!KeyState.isPressingShift() && !KeyState.isPressingControl())
                            {
                                KeyState.updateLastKey();
                                ReplayController.startAdjustPlayBackSpeedByShortcut(true);
                            }
                        }
                        break;
                    case KeyState.KEY.down:
                    case KeyState.KEY.v:
                    case KeyState.KEY.n:
                        {
                            if (!KeyState.isPressingShift() && !KeyState.isPressingControl())
                            {
                                KeyState.updateLastKey();
                                ReplayController.startAdjustPlayBackSpeedByShortcut(false);
                            }
                        }
                        break;
                    case KeyState.KEY.w:
                    case KeyState.KEY.i:
                        {
                            if (!KeyState.isPressingShift() && !KeyState.isPressingControl())
                            {
                                KeyState.updateLastKey();
                                ReplayDrawer.viewport.zoomStep(true);
                            }
                        }
                        break;
                    case KeyState.KEY.s:
                    case KeyState.KEY.k:
                        {
                            if (!KeyState.isPressingShift() && !KeyState.isPressingControl())
                            {
                                KeyState.updateLastKey();
                                ReplayDrawer.viewport.zoomStep(false);
                            }
                        }
                        break;
                }
                return;
            }

            if (ReplayController.isReplayRestartTimerON())
            {
                switch (firstKey)
                {
                    case KeyState.KEY.backspace:
                    case KeyState.KEY.esc:
                    case KeyState.KEY.enter:
                    case KeyState.KEY.space:
                        {
                            KeyState.updateLastKey();
                            ReplayController.cancelReplayRestartTimer();
                        }
                        break;
                }
                return;
            }

            if (KeyState.isPressingShift())
            {
                KeyState.checkSubKey(2, false, handleShiftSubKeyReplayMode);
                return;
            }
            else if (KeyState.isPressingControl())
            {
                KeyState.checkSubKey(2, true, handleControlSubKeyReplayMode);
                return;
            }

            KeyState.updateLastKey();

            switch (firstKey)
            {
                case KeyState.KEY.left:
                case KeyState.KEY.z:
                case KeyState.KEY.dot:
                    {
                        if (ReplayState.canStartReplay())
                        {
                            KeyState.startKeyRepeat(true, ReplayController.moveToPreviousStep);
                        }
                    }
                    break;
                case KeyState.KEY.right:
                case KeyState.KEY.x:
                case KeyState.KEY.comma:
                    {
                        if (ReplayState.canStartReplay())
                        {
                            KeyState.startKeyRepeat(true, ReplayController.moveToNextStep);
                        }
                    }
                    break;
                case KeyState.KEY.up:
                case KeyState.KEY.f:
                case KeyState.KEY.h:
                    {
                        if (ReplayState.canStartReplay())
                        {
                            ReplayController.startAdjustPlayBackSpeedByShortcut(true);
                        }
                    }
                    break;
                case KeyState.KEY.down:
                case KeyState.KEY.v:
                case KeyState.KEY.n:
                    {
                        if (ReplayState.canStartReplay())
                        {
                            ReplayController.startAdjustPlayBackSpeedByShortcut(false);
                        }
                    }
                    break;
                case KeyState.KEY.w:
                case KeyState.KEY.i:
                    {
                        ReplayDrawer.viewport.zoomStep(true); // 반복 없음: 위에서 updateLastKey를 불러 키를 떼기 전에는 다시 들어오지 않음
                    }
                    break;
                case KeyState.KEY.s:
                case KeyState.KEY.k:
                    {
                        ReplayDrawer.viewport.zoomStep(false);
                    }
                    break;
                case KeyState.KEY.backspace:
                case KeyState.KEY.esc:
                case KeyState.KEY.f1:
                case KeyState.KEY.f7:
                    {
                        ReplayController.exitReplayMode();
                    }
                    break;
                case KeyState.KEY.space:
                    {
                        if (ReplayState.canStartReplay())
                        {
                            ReplayController.handleReplayStartButton();
                        }
                    }
                    break;
            }
        }

        private static function onRightMouseDownReplayMode(e:MouseEvent):void
        {
            if (MouseState.isLeftDown || KeyState.isKeyPressed() || !e.target || LoadBoxController.loadMenuBox.visible
                    || ReplayState.isZeroReplayFrame())
            {
                return;
            }

            const targetName:String = e.target.name;

            switch (targetName)
            {
                case "replayPrev":
                    {
                        KeyState.startKeyRepeat(true, ReplayController.moveToPreviousFrame);
                        KeyState.startKeyRepeatStopTimerOnMouseLeave(e.target as DisplayObject);
                    }
                    break;
                case "replayNext":
                    {
                        KeyState.startKeyRepeat(true, ReplayController.moveToNextFrame);
                        KeyState.startKeyRepeatStopTimerOnMouseLeave(e.target as DisplayObject);
                    }
                    break;
                case "replayRotateButton":
                    {
                        ReplayController.resetRotationReplayMode();
                        ReplayDrawer.cursorFollow.updateBounds();
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


            if (targetName)
            {
                if (KeyState.isKeyPressed())
                {
                    return;
                }

                if(!ReplayController.isReplayRestartTimerON())
                {   
                    if (targetName === "rCanvasPanel" || targetName === "rCanvasDrawLayer" || targetName === "stageBG")
                    {
                        HandTool.startInReplayMode();
                        return;
                    }
                    else if(targetName === "replayFitToWindowButton")
                    {
                        InputManager.handleMouseClickStage(targetName, onClickReplayButton);
                    }
                }

                if (targetName === "replayRepeatButton")
                {
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
                        if (KeyState.isPressingShift())
                        {
                            KeyState.startKeyRepeat(true, ReplayController.moveToPreviousFrame);
                            KeyState.startKeyRepeatStopTimerOnMouseLeave(target);
                        }
                        else
                        {
                            KeyState.startKeyRepeat(true, ReplayController.moveToPreviousStep);
                            KeyState.startKeyRepeatStopTimerOnMouseLeave(target);
                        }
                    }
                    break;
                case "replayNext":
                    {
                        FOFOTimer.remove("prograssBarUpdateTimer");
                        if (KeyState.isPressingShift())
                        {
                            KeyState.startKeyRepeat(true, ReplayController.moveToNextFrame);
                            KeyState.startKeyRepeatStopTimerOnMouseLeave(target);
                        }
                        else
                        {
                            KeyState.startKeyRepeat(true, ReplayController.moveToNextStep);
                            KeyState.startKeyRepeatStopTimerOnMouseLeave(target);
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
                        if (KeyState.isKeyPressed())
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
                        if (KeyState.isKeyPressed())
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
                        if (KeyState.isKeyPressed())
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
