package Modules.Tools
{
    import Modules.DrawEngine.CanvasView;
    import Modules.DrawEngine.DrawCanvas;
    import Modules.UIEngine.CanvasNavigator;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;
    import Modules.UIEngine.UITheme;
    import flash.geom.Point;
    import Modules.ReferenceLayerController;
    import Modules.CanvasGridOverlay;
    import Modules.DragInteraction;
    import Modules.PenSizePreviewCursor;
    import flash.display.Sprite;
    import Modules.Utils;

    public class ZoomTool
    {
        public static var main:Main;

        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static const zoomMaxIndex:uint = CanvasView.canvasZoomMultiplierList.length - 1;
        private static const clickPos:Point = new Point(0, 0);
        private static const lastMousePos:Point = new Point(0, 0);
        private static const mouseMoveStep:int = 26; // 이 픽셀이상움직일때만 zoomcanvas를 실행

        private static var lastZoom:Number = 0.0;
        private static var startZoomIndex:int = 0;
        private static var dragDirection:int = 0; // 1이면 x축

        private static function fixMouseHintPos():void
        {
            HintController.mouseHint.x = clickPos.x - HintController.mouseHint.width / 2;
            HintController.mouseHint.y = clickPos.y - 35 * UITheme.getUIScale();
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

            const zoomValue:Number = CanvasView.canvasZoomMultiplierList[startZoomIndex];
            CanvasView.canvasZoomIndex = startZoomIndex;
            CanvasView.viewport.setScale(zoomValue);

            HintController.showMouseHint(Math.floor(zoomValue * 100) + "%");
            fixMouseHintPos();
        }

        private static function onMouseMove():void
        {
            var mx:Number = main.stage.mouseX;
            var my:Number = main.stage.mouseY;

            if (dragDirection === 0)
            {
                if (Math.abs(mx - lastMousePos.x) > 20)
                {
                    dragDirection = 1;
                    lastMousePos.x = main.stage.mouseX;
                }
                else if (Math.abs(my - lastMousePos.y) > 20)
                {
                    dragDirection = 2;
                    lastMousePos.y = main.stage.mouseY;
                }
            }
            else if (dragDirection === 1)
            {
                const subX:Number = lastMousePos.x - mx;

                if (Math.abs(subX) > mouseMoveStep)
                {
                    lastMousePos.x = main.stage.mouseX;
                    zoomToolMouseMoveEvent2(subX);
                }
            }
            else if (dragDirection === 2)
            {
                const subY:Number = my - lastMousePos.y;

                if (Math.abs(subY) > mouseMoveStep)
                {
                    lastMousePos.y = main.stage.mouseY;
                    zoomToolMouseMoveEvent2(subY);
                }
            }
        }

        private static function onMouseUp():void
        {
            PenSizePreviewCursor.setCursorInVisibleFlag(false);
            PenSizePreviewCursor.updateSizeAndShape();
            HintController.hideMouseHint();
            
            ReferenceLayerController.setRefLayerAndGridVisible(true);

            if (LassoTool.isLassoMenuHiddenTemp === true)
            {
                LassoTool.showLassoMenuBox();
            }

            CanvasNavigator.updateCursor();

            if (CanvasGridOverlay.gridGapMultiplier > 0 && lastZoom !== CanvasView.canvasZoomMultiplier)
            {
                CanvasGridOverlay.drawGrid();
            }
        }
        
        //캔버스 바깥에 줌 클릭시작해도 캔버스 경계면까지 점을 반환함
        public static function getCanvasBoundLimitPoint(canvas:Sprite, px:Number, py:Number, width:Number, height:Number, zoom:Number, rotation:Number):Point
        {
            // 매개변수 rotation은 음수값으로 넣어야 됨
            var zoomClickX:Number = px * zoom;
            var zoomClickY:Number = py * zoom;

            if (zoomClickX < 0)
            {
                zoomClickX = 0;
            }
            else if (zoomClickX > width * zoom)
            {
                zoomClickX = width * zoom;
            }

            if (zoomClickY < 0)
            {
                zoomClickY = 0;
            }
            else if (zoomClickY > height * zoom)
            {
                zoomClickY = height * zoom;
            }

            return Utils.rotatePoint(zoomClickX, zoomClickY, rotation);
        }

        public static function start():void
        {
            function onDragStart():void
            {
                lastZoom = CanvasView.canvasZoomMultiplier;
                dragDirection = 0;

                // 클릭한 위치가 캔버스밖을 벗어날경우 줌 기준점을 캔버스 경계선에 닿도록 함
                var gp:Point;

                if (LassoTool.isLassoMenuHiddenTemp === true)
                {
                    gp = LassoTool.lassoLayer1.localToGlobal(new Point(0, 0));
                    CanvasView.viewport.moveAnchorPoint(gp.x, gp.y);
                }
                else
                {
                    gp = CanvasView.canvasPanel.localToGlobal(new Point(0, 0));
                    const panelLimitedPos:Point = getCanvasBoundLimitPoint(CanvasView.canvasPanel, CanvasView.canvasPanel.mouseX, CanvasView.canvasPanel.mouseY, DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, CanvasView.canvasZoomMultiplier, -CanvasView.canvasAnchorPoint.rotation);
                    // 캔버스 0,0점이 글로벌좌표 기준으로 어느 위치에 있는지 더해줘야함
                    CanvasView.viewport.moveAnchorPoint(panelLimitedPos.x + gp.x, panelLimitedPos.y + gp.y);
                }

                lastMousePos.setTo(main.stage.mouseX, main.stage.mouseY);
                startZoomIndex = CanvasView.canvasZoomIndex;

                PenSizePreviewCursor.setCursorInVisibleFlag(true);
                ReferenceLayerController.setRefLayerAndGridVisible(false);

                clickPos.setTo(main.stage.mouseX, main.stage.mouseY);
                HintController.showMouseHint(Math.floor(CanvasView.canvasZoomMultiplier * 100) + "%");
                fixMouseHintPos();
            }

            DragInteraction.start(onDragStart, onMouseMove, onMouseUp);
        };
    }
}
