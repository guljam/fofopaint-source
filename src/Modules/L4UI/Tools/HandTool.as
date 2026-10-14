package Modules.L4UI.Tools
{
    import Modules.L1Data.AppContext;
    import flash.geom.Point;
    import flash.display.Sprite;
    import flash.display.Bitmap;
    import flash.events.MouseEvent;
    import Modules.L4UI.Tools.ToolPanel;
    import Modules.L1Data.KeyState;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L4UI.PenSizePreviewCursor;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.L2Engine.ReplayEngine.ReplayState;
    import Modules.L4UI.CanvasViewport;
    import Modules.L1Data.MouseState;
    import Modules.L4UI.Tools.LassoTool;
    import Modules.L4UI.ReferenceLayerController;
    import Modules.L4UI.UIEngine.CanvasNavigator;
    import Modules.L1Data.InputPriority;

    // 층: L4 UI - 손 툴(캔버스 끌어 이동)
    public class HandTool
    {

        private static const old:Point = new Point(0, 0);

        private static var isReplayMode:Boolean;

        private static var xAnc:Sprite;

        private static const DRAG_OWNER:String = "handTool";

        private static function onMouseUpHandTool(e:MouseEvent):void
        {
            finishHandTool();
        }

        // 이벤트 객체를 쓰지 않음. mouseUp을 못받는 경우(alt+tab 등)에도 MouseState.finishAllDrags가 직접 호출함
        private static function finishHandTool():void
        {
            MouseState.endDrag(DRAG_OWNER);
            AppContext.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHandTool);
            AppContext.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpHandTool);
            AppContext.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpHandTool);
            AppContext.stage.removeEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMouseUpHandTool);

            PenSizePreviewCursor.setCursorInVisibleFlag(false);

            if (isReplayMode)
            {
                finishHandToolInReplayMode();
                return;
            }

            CanvasView.viewport.keepCanvasInStage();
            ReferenceLayerController.setRefLayerAndGridVisible(true);

            if (LassoTool.isStarted)
            {
                if (LassoTool.isLassoMenuHiddenTemp === true)
                {
                    LassoTool.showLassoMenuBox();
                }
            } // tool box에서 클릭해서 핸드툴 들어갈때 필요함
            else if (!KeyState.isLastKey(KeyState.KEY.space))
            {
                ToolController.selectLastUsedTool();
            }

            ToolPanel.toolBox.setCursorVisible(true);
            CanvasNavigator.updateCursor();
        }

        // 리플레이 모드에서 손 도구를 놓았을 때: 창 맞춤 상태면 바로 뷰포트 중앙으로 맞추고, 아니면 캔버스를 화면 안에 두고 카메라가 바로 이어받게 함
        private static function finishHandToolInReplayMode():void
        {
            if (ReplayState.isReplayCanvasFitToWindow)
            {
                ReplayDrawer.viewport.fitToViewportMargin(true);
            }
            else
            {
                ReplayDrawer.viewport.keepCanvasInStage();
            }

            ReplayDrawer.cursorFollow.resumeCameraAfterHandToolDrag();
        }

        private static function onMouseMoveHandTool(e:MouseEvent):void
        {
            if (isReplayMode && ReplayState.isReplayRestartTimerON)
            {
                finishHandTool();
                return;
            }

            xAnc.x += (AppContext.stage.mouseX - old.x);
            xAnc.y += (AppContext.stage.mouseY - old.y);

            old.setTo(AppContext.stage.mouseX, AppContext.stage.mouseY);
        }

        public static function startInDrawMode():void
        {
            _start(false, false);
        }

        public static function startInDrawModeWithWheelClick():void
        {
            _start(false, true);
        }

        // 리플레이 모드: 재생 중에도 쓸 수 있고, 끄는 동안 리플레이 카메라는 멈춤
        public static function startInReplayMode():void
        {
            _start(true, false);
        }

        public static function startInReplayModeWithWheelClick():void
        {
            _start(true, true);
        }

        private static function _start(fromReplayMode:Boolean, fromWheelClick:Boolean):void
        {
            isReplayMode = fromReplayMode;

            xAnc = CanvasViewport.getViewportByReplayMode(isReplayMode).canvasAnchorPoint;

            old.setTo(AppContext.stage.mouseX, AppContext.stage.mouseY);
            PenSizePreviewCursor.setCursorInVisibleFlag(true);

            if (isReplayMode)
            {
                ReplayDrawer.cursorFollow.pauseCameraForHandToolDrag();
            }
            else
            {
                ToolPanel.toolBox.setCursorVisible(false);
                ReferenceLayerController.setRefLayerAndGridVisible(false);
            }

            if (fromWheelClick)
            {
                AppContext.stage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMouseUpHandTool);
            }

            AppContext.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHandTool);
            AppContext.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpHandTool, false, InputPriority.DEFAULT);
            // 윈도우 바깥에서 up을 하면 hand가 안꺼져서 오른쪽 마우스 뗄떼도 꺼주게함
            AppContext.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpHandTool, false, InputPriority.DEFAULT);
            MouseState.beginDrag(DRAG_OWNER, finishHandTool);
        };
    }
}
