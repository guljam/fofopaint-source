package Modules.Tools
{
    import flash.display.Sprite;
    import Modules.CanvasController;
    import Modules.ReferenceLayerController;
    import flash.geom.Point;
    import Modules.MainUIController;
    import Modules.MainUI;
    import Modules.ReplayController;
    import Modules.DragInteraction;
    import Modules.InputManager;
    import Modules.PenSizePreviewCursor;

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
            ReplayController.setRcursorRotation(xAnc.rotation);
            CanvasController.canvasInfoBox.setRotate(Math.abs(xAnc.rotation));
        }

        private static function onMouseUp():void
        {
            PenSizePreviewCursor.setCursorInVisibleFlag(false);

            if (!isReplayMode)
            {
                if (LassoTool._isLassoToolStarted)
                {
                    if (LassoTool._isLassoMenuHiddenTemp === true)
                    {
                        LassoTool.hideLassoMenuBoxTemp();
                    }
                }

                PenSizePreviewCursor.updateSizeAndShape();
                ReferenceLayerController.setRefLayerAndGridVisible(true);
                MainUIController.updateCanvasNaigatorCursor();
            }
            else
            {
                if (ReplayController.isReplayCanvasFitToWindow)
                {
                    ReplayController.fitReplayCanvasToViewport();
                }

                InputManager.resetLastKey();
                ReplayController.rFollowMouse.updateBounds();
            }

            MainUI.hideCanvasRotateCursor();
            CanvasController.keepCanvasPanelInStage(isReplayMode);
        }

        private static function onDragStart():void
        {
            PenSizePreviewCursor.setCursorInVisibleFlag(true);

            if (!isReplayMode)
            {
                ReferenceLayerController.setRefLayerAndGridVisible(false);
            }

            const center:Point = MainUIController.getStageCenterPos("replay");

            CanvasController.moveCanvasAnchorPoint(center.x, center.y, isReplayMode);

            // 캔버스 이동이 완료된후 함수를 초기화 시켜줌
            MainUI.hideBottomHint();
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
            xAnc = (isReplayMode) ? ReplayController.rCanvasAnchorPoint : CanvasController.canvasAnchorPoint;
            getAngle = MainUI.showCanvasRotateCursorMouseDrag(xAnc);

            DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
        };

        private function updatePenSizeCursor():void {}
    }
}
