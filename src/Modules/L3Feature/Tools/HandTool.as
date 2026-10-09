package Modules.L3Feature.Tools
{
    import Modules.CanvasViewport;
    import Modules.UIEngine.CanvasNavigator;
    import Modules.InputPriority;
    import Modules.MouseState;
    import flash.geom.Point;
    import flash.display.Sprite;
    import flash.display.Bitmap;
    import flash.events.MouseEvent;
    import Modules.ReferenceLayerController;
    import Modules.L5App.ReplayEngine.ReplayController;
    import Modules.L4UI.Tools.ToolPanel;
    import Modules.L1Data.KeyState;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L4UI.PenSizePreviewCursor;

    // 층: L3 기능 - 손 툴(캔버스 끌어 이동)
    public class HandTool
    {
        public static var main:Main;

        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

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
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHandTool);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpHandTool);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpHandTool);
            main.stage.removeEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMouseUpHandTool);

            PenSizePreviewCursor.setCursorInVisibleFlag(false);
            CanvasViewport.forMode(isReplayMode).keepInStage();

            if (!isReplayMode)
            {
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
            else
            {
                ReplayDrawer.cursorFollow.updateBounds();
            }
        }

        private static function onMouseMoveHandTool(e:MouseEvent):void
        {
            if (isReplayMode && ReplayController.isReplayRestartTimerON())
            {
                finishHandTool();
                return;
            }

            xAnc.x += (main.stage.mouseX - old.x);
            xAnc.y += (main.stage.mouseY - old.y);

            old.setTo(main.stage.mouseX, main.stage.mouseY);
        }

        public static function startInDrawMode():void
        {
            _start(false, false);
        }

        public static function startInDrawModeWithWheelClick():void
        {
            _start(false, true);
        }

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

            xAnc = CanvasViewport.forMode(isReplayMode).anchor;

            old.setTo(main.stage.mouseX, main.stage.mouseY);
            PenSizePreviewCursor.setCursorInVisibleFlag(true);
            
            if (!fromReplayMode)
            {
                ToolPanel.toolBox.setCursorVisible(false);
                ReferenceLayerController.setRefLayerAndGridVisible(false);
            }

            if (fromWheelClick)
            {
                main.stage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMouseUpHandTool);
            }

            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHandTool);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpHandTool, false, InputPriority.DEFAULT);
            // 윈도우 바깥에서 up을 하면 hand가 안꺼져서 오른쪽 마우스 뗄떼도 꺼주게함
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpHandTool, false, InputPriority.DEFAULT);
            MouseState.beginDrag(DRAG_OWNER, finishHandTool);
        };
    }
}
