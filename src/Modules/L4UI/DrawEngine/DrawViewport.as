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

    // 드로우 모드 캔버스의 화면 배치 (CanvasView.viewport). 공용 동작은 CanvasViewport, 여기서는 드로우 캔버스의 값과 배율 후처리만 정함
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

        // 배율을 CanvasView에 저장하고, 캡처 모드가 아니면 펜 크기 미리보기를, 올가미 중이면 올가미 윤곽선을 새 배율에 맞춤
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

        // 화면 중심 기준으로 한 단계 확대/축소함. 캔버스가 화면 밖으로 나가지 않게 제한하고 펜 커서, 네비게이터, 격자를 갱신함
        override public function zoomStep(zoomIn:Boolean):void
        {
            const currentAnchor:Sprite = anchor;
            const currentPanel:Sprite = panel;
            const newZoomIndex:int = nextZoomIndex(CanvasView.canvasZoomIndex, zoomIn);
            const newZoom:Number = CanvasView.canvasZoomMultiplierList[newZoomIndex];
            const stageCenterPos:Point = UIController.getStageCenterPos("draw");
            const panelLocalCenterPos:Point = currentPanel.globalToLocal(new Point(stageCenterPos.x, stageCenterPos.y));
            const panelGlobalOriginPos:Point = currentPanel.localToGlobal(new Point(0, 0));
            const panelLimitedCenterPos:Point = ZoomTool.getCanvasBoundLimitPoint(currentPanel, panelLocalCenterPos.x, panelLocalCenterPos.y, DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, currentAnchor.scaleY, -currentAnchor.rotation);
            CanvasView.canvasZoomIndex = newZoomIndex;
            moveAnchorPoint(panelLimitedCenterPos.x + panelGlobalOriginPos.x, panelLimitedCenterPos.y + panelGlobalOriginPos.y);
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
