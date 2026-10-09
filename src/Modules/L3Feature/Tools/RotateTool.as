package Modules.L3Feature.Tools
{
    import Modules.CanvasViewport;
    import Modules.UIEngine.CanvasNavigator;
    import Modules.UIEngine.HintController;
    import flash.display.Sprite;
    import Modules.ReferenceLayerController;
    import flash.geom.Point;
    import Modules.DragInteraction;
    import Modules.PenSizePreviewCursor;
    import Modules.ReplayEngine.ReplayState;
    import Modules.L5App.ReplayEngine.ReplayController;
    import Modules.L1Data.KeyState;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.L4UI.UIEngine.UIController;

    // 층: L3 기능 - 회전 툴
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

                KeyState.resetLastKey();
                ReplayDrawer.cursorFollow.updateBounds();
            }

            UIController.hideCanvasRotateCursor();
            CanvasViewport.forMode(isReplayMode).keepInStage();
        }

        private static function onDragStart():void
        {
            PenSizePreviewCursor.setCursorInVisibleFlag(true);

            if (!isReplayMode)
            {
                ReferenceLayerController.setRefLayerAndGridVisible(false);
            }

            const center:Point = UIController.getStageCenterPos("replay");

            CanvasViewport.forMode(isReplayMode).moveAnchorPoint(center.x, center.y);

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
            xAnc = CanvasViewport.forMode(isReplayMode).anchor;
            getAngle = UIController.showCanvasRotateCursorMouseDrag(xAnc);

            DragInteraction.start(onDragStart, onMouseMove, onMouseUp);
        };
    }
}
