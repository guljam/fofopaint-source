package Modules.Tools
{
    import flash.geom.Point;
    import flash.display.Sprite;
    import flash.display.Bitmap;
    import flash.events.MouseEvent;
    import Modules.CanvasController;
    import Modules.ReferenceLayerController;
    import Modules.InputController;
    import Modules.ToolController;
    import Modules.MainUIController;
    import Modules.ReplayController;

    public class HandTool
    {
        public static var main:Main;

        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static const old:Point = new Point(0, 0);

        private static var isReplayMode:Boolean;
        private static var isDrawMode:Boolean;

        private static var xAnc:Sprite;
        private static var xBitmap:Bitmap;

        private static function onMouseUpHandTool(e:MouseEvent):void
        {
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHandTool);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpHandTool);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpHandTool);
            main.stage.removeEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMouseUpHandTool);

            CanvasController.isMouseDragging = false;
            CanvasController.isPenSizeCursorInvisible = false;
            CanvasController.keepCanvasPanelInStage(isReplayMode);

            if (isDrawMode)
            {
                ReferenceLayerController.setRefLayerAndGridVisible(true);

                if (LassoTool._isLassoToolStarted)
                {
                    if (LassoTool._isLassoMenuHiddenTemp === true)
                    {
                        LassoTool.hideLassoMenuBoxTemp();
                    }
                } // tool box에서 클릭해서 핸드툴 들어갈때 필요함
                else if (!InputController.isLastKey(InputController.KEY.space))
                {
                    ToolController.selectLastUsedTool();
                }

                ToolController.toolBox.setCursorVisible(true);
                MainUIController.updateCanvasNaigatorCursor();
            }
            else
            {
                ReplayController.rFollowMouse.updateBounds();
            }
        }

        private static function onMouseMoveHandTool(e:MouseEvent):void
        {
            if (isReplayMode && ReplayController.isReplayRestartTimerON())
            {
                onMouseUpHandTool(null);
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
            CanvasController.isMouseDragging = true;

            isReplayMode = fromReplayMode;
            isDrawMode = !fromReplayMode;

            xAnc = (isDrawMode) ? CanvasController.canvasAnchorPoint : ReplayController.rCanvasAnchorPoint;
            xBitmap = (isDrawMode) ? CanvasController.canvasLayer1Bitmap : ReplayController.rCanvasLayer1Bitmap;

            old.setTo(main.stage.mouseX, main.stage.mouseY);
            CanvasController.isPenSizeCursorInvisible = true;

            if (isDrawMode)
            {
                ToolController.toolBox.setCursorVisible(false);
                ReferenceLayerController.setRefLayerAndGridVisible(false);
            }

            if (fromWheelClick)
            {
                main.stage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMouseUpHandTool);
            }

            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHandTool);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpHandTool);
            // 윈도우 바깥에서 up을 하면 hand가 안꺼져서 오른쪽 마우스 뗄떼도 꺼주게함
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpHandTool);
        };
    }
}
