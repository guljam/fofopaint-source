package Modules.Tools
{
    import Modules.CanvasController;
    import flash.geom.Point;
    import Modules.MainUI;
    import Modules.ReferenceLayerController;
    import Modules.MainUIController;
    import Modules.CanvasGridOverlay;
    import Modules.DragInteraction;
    import Modules.PenSizePreviewCursor;

    public class ZoomTool
    {
        public static var main:Main;

        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static const zoomMaxIndex:uint = CanvasController.canvasZoomMultiplerList.length - 1;
        private static const clickPos:Point = new Point(0, 0);
        private static const lastMousePos:Point = new Point(0, 0);
        private static const mouseMoveStep:int = 26; // 이 픽셀이상움직일때만 zoomcanvas를 실행

        private static var lastZoom:Number = 0.0;
        private static var startZoomIndex:int = 0;
        private static var dragDirection:int = 0; // 1이면 x축

        private static function fixMouseHintPos():void
        {
            MainUI.mouseHint.x = clickPos.x - MainUI.mouseHint.width / 2;
            MainUI.mouseHint.y = clickPos.y - 35 * Global.getUIScale();
        }

        private static function zoomToolMouseMoveEvent2(dist:Number):void
        {
            if (dist > mouseMoveStep)
            {
                startZoomIndex--;
            }
            else
            {
                startZoomIndex++;
            }

            if (startZoomIndex < 0)
            {
                startZoomIndex = 0;
            }
            else if (startZoomIndex > zoomMaxIndex)
            {
                startZoomIndex = zoomMaxIndex;
            }

            const zoomValue:Number = CanvasController.canvasZoomMultiplerList[startZoomIndex];
            CanvasController.canvasZoomIndex = startZoomIndex;
            CanvasController.updateCanvasScale(zoomValue, false);

            MainUI.showMouseHint(Math.floor(zoomValue * 100) + "%");
            fixMouseHintPos();
        }

        private static function onMouseMove():void
        {
            var abs:Function = Math.abs;
            var mx:Number = main.stage.mouseX;
            var my:Number = main.stage.mouseY;

            if (dragDirection === 0)
            {
                if (abs(mx - lastMousePos.x) > 20)
                {
                    dragDirection = 1;
                    lastMousePos.x = main.stage.mouseX;
                }
                else if (abs(my - lastMousePos.y) > 20)
                {
                    dragDirection = 2;
                    lastMousePos.y = main.stage.mouseY;
                }
            }
            else if (dragDirection === 1)
            {
                const subX:Number = lastMousePos.x - mx;

                if (abs(subX) > mouseMoveStep)
                {
                    lastMousePos.x = main.stage.mouseX;
                    zoomToolMouseMoveEvent2(subX);
                }
            }
            else if (dragDirection === 2)
            {
                const subY:Number = my - lastMousePos.y;

                if (abs(subY) > mouseMoveStep)
                {
                    lastMousePos.y = main.stage.mouseY;
                    zoomToolMouseMoveEvent2(subY);
                }
            }
        }

        private static function onMouseUp():void
        {
            CanvasController.isMouseDragging = false;
            PenSizePreviewCursor.setCursorInVisibleFlag(false);
            PenSizePreviewCursor.updateSizeAndShape();
            MainUI.hideMouseHint();
            
            ReferenceLayerController.setRefLayerAndGridVisible(true);

            if (LassoTool._isLassoMenuHiddenTemp === true)
            {
                LassoTool.hideLassoMenuBoxTemp();
            }

            MainUIController.updateCanvasNaigatorCursor();

            if (CanvasGridOverlay.gridGapMultiplier > 0 && lastZoom !== CanvasController.canvasZoomMultipler)
            {
                CanvasGridOverlay.drawGrid();
            }
        }

        public static function start():void
        {
            function onDragStart():void
            {
                lastZoom = CanvasController.canvasZoomMultipler;
                dragDirection = 0;

                // 클릭한 위치가 캔버스밖을 벗어날경우 줌 기준점을 캔버스 경계선에 닿도록 함
                var gp:Point;

                if (LassoTool._isLassoMenuHiddenTemp === true)
                {
                    gp = LassoTool.lassoLayer1.localToGlobal(new Point(0, 0));
                    CanvasController.moveCanvasAnchorPoint(gp.x, gp.y, false);
                }
                else
                {
                    gp = CanvasController.canvasPanel.localToGlobal(new Point(0, 0));
                    const panelLimitedPos:Point = main.getCanvasBoundLimitPoint(CanvasController.canvasPanel, CanvasController.canvasPanel.mouseX, CanvasController.canvasPanel.mouseY, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, CanvasController.canvasZoomMultipler, -CanvasController.canvasAnchorPoint.rotation);
                    // 캔버스 0,0점이 글로벌좌표 기준으로 어느 위치에 있는지 더해줘야함
                    CanvasController.moveCanvasAnchorPoint(panelLimitedPos.x + gp.x, panelLimitedPos.y + gp.y, false);
                }

                lastMousePos.setTo(main.stage.mouseX, main.stage.mouseY);
                startZoomIndex = CanvasController.canvasZoomIndex;

                PenSizePreviewCursor.setCursorInVisibleFlag(true);
                ReferenceLayerController.setRefLayerAndGridVisible(false);

                clickPos.setTo(main.stage.mouseX, main.stage.mouseY);
                MainUI.showMouseHint(Math.floor(CanvasController.canvasZoomMultipler * 100) + "%");
                fixMouseHintPos();
            }

            DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
        };
    }
}
