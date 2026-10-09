package Modules.L5App.InputManager
{
    import Modules.ClipboardManager;
    import Modules.InputPriority;
    import Modules.L1Data.KeyState;
    import Modules.MouseState;
    import Modules.Utils;
    import Modules.CaptureEngine.CaptureController;

    import flash.display.DisplayObject;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import Modules.DrawEngine.StrokeBuffer;
    import Modules.DrawEngine.HandDrawnLine;
    import Symbols.TopMenuSet;
    import Modules.L4UI.ColorPickerController;
    import Modules.L5App.FileManager;
    import Modules.L3Feature.Tools.HandTool;
    import Modules.L3Feature.ImeController;
    import Modules.L3Feature.Tools.LassoTool;
    import Modules.L5App.ReplayEngine.ReplayController;
    import Modules.L4UI.SidebarController;
    import Modules.L4UI.Tools.ToolPanel;
    import Modules.L4UI.AboutBoxController;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L4UI.PenSizePreviewCursor;
    import Modules.L1Data.ToolState;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L2Engine.ReplayEngine.ReplayState;

    // 층: L5 앱 흐름 - 키보드·마우스 입력을 받아 모드별 입력 처리로 나눠줌
    public class InputManager
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

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
                var keyBufferLenSave:uint = KeyState.getPressedKeyCount();
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
                                || keyBufferLenSave !== KeyState.getPressedKeyCount()
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
            KeyState.checkInvalidKey();
            MouseState.onLeftDown();
            HintController.hideBottomHint();
        }

        public static function onMouseUpStage(e:MouseEvent):void
        {
            KeyState.checkInvalidKey();
            MouseState.onLeftUp();
        }

        public static function onRightMouseDownStage(e:MouseEvent):void
        {
            KeyState.checkInvalidKey();
            MouseState.onRightDown();
        }

        public static function onRightMouseUpStage(e:MouseEvent):void
        {
            KeyState.checkInvalidKey();
            MouseState.onRightUp();
        }

        public static function onMouseWheelStage(e:MouseEvent):void
        {
            if (MouseState.isLeftDown || MouseState.isRightDown || MouseState.isDragging
                    || UIController.isPopUpWindowOpened()
                    || CaptureController.isCaptureModeON || !SidebarController.isQuickSidebarActive && KeyState.isKeyPressed() || KeyState.getCommandKey() !== 0)
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
                        if (Utils.isCursorInDrawArea())
                        {
                            if (ReplayState.isReplayModeON)
                            {
                                // 리플레이 모드: 휠 위 = 줌인, 아래 = 줌아웃 (화면 중심 기준, 힌트는 zoomStep이 띄움)
                                ReplayDrawer.viewport.zoomStep(e.delta > 0);
                            }
                            if (!ReplayState.isReplayModeON)
                            {
                                CanvasView.viewport.zoomStep(e.delta > 0);
                                HintController.showMouseHintTemp(Math.floor(CanvasView.canvasZoomMultiplier * 100) + "%");
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

            ToolPanel.showNowToolIconToCursorTemp(ToolState.TOOL_HAND);
        }

        public static function onKeyUpStage(e:KeyboardEvent):void
        {
            // 디버그 확인용
            if (KeyState.isPressedKey(KeyState.KEY.f12))
            {
                UIController.topBar.showUpdateButton();
            }

            KeyState.checkInvalidKey();
            ImeController.logKeyUp(e);
            const index:int = KeyState.getPressedKeyIndex(e.keyCode);
            if (index > -1)
            {
                KeyState.keyBuffer.splice(index, 1);
            }
            ImeController.refresh();
        }

        public static function onKeyDownStage(e:KeyboardEvent):void
        {
            KeyState.checkInvalidKey();
            // IME가 가져간 키는 단축키로 처리하지 않음 (keyCode가 229 등이라 실제 키를 알 수 없음)
            if (ImeController.interceptKeyDown(e))
            {
                return;
            }
            const keyCode:uint = e.keyCode;
            if (keyCode === KeyState.KEY.window)
            {
                return;
            }
            // ALT 단독 입력이 창 포커스를 시스템 메뉴로 뺏어가는 것을 막음. AIR 51.4.1부터 ALT keyDown의 preventDefault가 Windows 기본 처리를 실제로 막음 (Github-4292)
            if (keyCode === KeyState.KEY.tab || keyCode === KeyState.KEY.alt)
            {
                e.preventDefault();
            }
            if (KeyState.keyBuffer.lastIndexOf(keyCode) === -1)
            {
                KeyState.keyBuffer.push(keyCode);
            }
            ImeController.refresh();
        }

        public static function unblockMouseClickAfterDelay():void
        {
            FOFOTimer.addByName("clickBlockTimer", 0.15, false, function ():void
                {
                    MouseState.isClickBlocked = false;
                });
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
