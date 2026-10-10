package Modules.L4UI.DrawEngine
{

    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.geom.Point;
    import Modules.L4UI.CanvasGridOverlay;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L4UI.PenSizePreviewCursor;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L4UI.CanvasViewport;
    import Modules.L4UI.Tools.LassoTool;
    import Modules.L4UI.Tools.ZoomTool;
    import Modules.L4UI.CaptureEngine.CaptureController;
    import Modules.L4UI.UIEngine.CanvasNavigator;

    // 드로우 모드 캔버스의 화면 배치 (CanvasView.viewport)
    // 층: L4 UI - 드로우 모드 캔버스의 화면 배치 (CanvasView.viewport)
    public class DrawViewport extends CanvasViewport
    {
        override public function get anchor():Sprite
        {
            return CanvasView.canvasAnchorPoint;
        }

        override public function get panel():Sprite
        {
            return CanvasView.canvasPanel;
        }

        override public function get layer1Bitmap():Bitmap
        {
            return DrawCanvas.canvasLayer1Bitmap;
        }

        override public function get layer2Bitmap():Bitmap
        {
            return DrawCanvas.canvasLayer2Bitmap;
        }

        override public function get canvasWidth():Number
        {
            return DrawCanvas.CANVAS_WIDTH;
        }

        override public function get canvasHeight():Number
        {
            return DrawCanvas.CANVAS_HEIGHT;
        }

        override public function get zoom():Number
        {
            return CanvasView.canvasZoomMultiplier;
        }

        override protected function storeZoom(zoomValue:Number):void
        {
            CanvasView.canvasZoomMultiplier = zoomValue;
            if (!CaptureController.isCaptureModeON)
            {
                PenSizePreviewCursor.updateZoom(zoomValue);
            }
            if (LassoTool.isStarted)
            {
                LassoTool.redrawLassoOutline();
            }
        }

        override public function zoomStep(zoomIn:Boolean):void
        {
            const xAnc:Sprite = anchor;
            const xPanel:Sprite = panel;
            const newZoomIndex:int = nextZoomIndex(CanvasView.canvasZoomIndex, zoomIn);
            const newZoom:Number = CanvasView.canvasZoomMultiplierList[newZoomIndex];
            const center:Point = UIController.getStageCenterPos("draw");
            const gcenter:Point = xPanel.globalToLocal(new Point(center.x, center.y));
            const gp:Point = xPanel.localToGlobal(new Point(0, 0));
            const panelLimitedPos:Point = ZoomTool.getCanvasBoundLimitPoint(xPanel, gcenter.x, gcenter.y, DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, xAnc.scaleY, -xAnc.rotation);
            CanvasView.canvasZoomIndex = newZoomIndex;
            moveAnchorPoint(panelLimitedPos.x + gp.x, panelLimitedPos.y + gp.y);
            setScale(newZoom);
            PenSizePreviewCursor.updateSizeAndShape();
            CanvasNavigator.updateCursor();
            if (CanvasGridOverlay.gridGapMultiplier > 0)
            {
                CanvasGridOverlay.drawGrid();
            }
        }
    }
}
