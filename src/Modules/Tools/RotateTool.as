package Modules.Tools
{
    import Modules.DrawEngine.CanvasView;
    import Modules.UIEngine.CanvasNavigator;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;
    import flash.display.Sprite;
    import Modules.ReferenceLayerController;
    import flash.geom.Point;
    import Modules.DragInteraction;
    import Modules.InputManager.InputManager;
    import Modules.PenSizePreviewCursor;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.ReplayEngine.ReplayState;

    public class RotateTool
    {
        public static var main:Main;

        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static var isReplayMode:Boolean;
        private static var xAnc:Sprite;
        private static var getAngle:Function;

        private static function onMouseMove():void
        {
            const ang:Number = getAngle(true);

            xAnc.rotation = ang;
            ReplayDrawer.setRcursorRotation(xAnc.rotation);
            UIController.canvasInfoBox.setRotate(Math.abs(xAnc.rotation));
        }

        private static function onMouseUp():void
        {
            PenSizePreviewCursor.setCursorInVisibleFlag(false);

            if (!isReplayMode)
            {
                if (LassoTool.isStarted)
                {
                    if (LassoTool.isLassoMenuHiddenTemp === true)
                    {
                        LassoTool.showLassoMenuBox();
                    }
                }

                PenSizePreviewCursor.updateSizeAndShape();
                ReferenceLayerController.setRefLayerAndGridVisible(true);
                CanvasNavigator.updateCursor();
            }
            else
            {
                if (ReplayState.isReplayCanvasFitToWindow)
                {
                    ReplayController.fitReplayCanvasToViewport();
                }

                InputManager.resetLastKey();
                ReplayController.rFollowMouse.updateBounds();
            }

            UIController.hideCanvasRotateCursor();
            CanvasView.keepCanvasPanelInStage(isReplayMode);
        }

        private static function onDragStart():void
        {
            PenSizePreviewCursor.setCursorInVisibleFlag(true);

            if (!isReplayMode)
            {
                ReferenceLayerController.setRefLayerAndGridVisible(false);
            }

            const center:Point = UIController.getStageCenterPos("replay");

            CanvasView.moveCanvasAnchorPoint(center.x, center.y, isReplayMode);

            // 캔버스 이동이 완료된후 함수를 초기화 시켜줌
            HintController.hideBottomHint();
        }

        public static function startInDrawMode():void
        {
            _start(false);
        }

        public static function startInReplayMode():void
        {
            _start(true);
        }

        private static function _start(fromReplayMode:Boolean):void
        {
            isReplayMode = fromReplayMode;
            xAnc = (isReplayMode) ? ReplayDrawer.rCanvasAnchorPoint : CanvasView.canvasAnchorPoint;
            getAngle = UIController.showCanvasRotateCursorMouseDrag(xAnc);

            DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
        };
    }
}
