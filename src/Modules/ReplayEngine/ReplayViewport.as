package Modules.ReplayEngine
{
    import Modules.CanvasViewport;
    import Modules.DrawEngine.CanvasView;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;

    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.geom.Point;

    // 리플레이 모드 캔버스의 화면 배치 (ReplayDrawer.viewport)
    public class ReplayViewport extends CanvasViewport
    {
        override public function get anchor():Sprite
        {
            return ReplayDrawer.rCanvasAnchorPoint;
        }

        override public function get panel():Sprite
        {
            return ReplayDrawer.rCanvasPanel;
        }

        override public function get layer1Bitmap():Bitmap
        {
            return ReplayDrawer.rCanvasLayer1Bitmap;
        }

        override public function get layer2Bitmap():Bitmap
        {
            return ReplayDrawer.rCanvasLayer2Bitmap;
        }

        override public function get canvasWidth():Number
        {
            return ReplayState.RCANVAS_WIDTH;
        }

        override public function get canvasHeight():Number
        {
            return ReplayState.RCANVAS_HEIGHT;
        }

        override public function get zoom():Number
        {
            return ReplayState.rCanvasZoomMultiplier;
        }

        override protected function storeZoom(zoomValue:Number):void
        {
            ReplayState.rCanvasZoomMultiplier = zoomValue;
            if (ReplayState.rAirBrushSize > 0)
            {
                ReplayDrawer.blurReplayCanvasByValue(ReplayState.rAirBrushSize);
            }
        }

        override public function zoomStep(zoomIn:Boolean):void
        {
            const newZoomIndex:int = nextZoomIndex(ReplayState.rCanvasZoomIndex, zoomIn);
            const newZoom:Number = CanvasView.canvasZoomMultiplierList[newZoomIndex];
            const center:Point = UIController.getStageCenterPos("replay");
            ReplayState.rLastCanvasZoomMultiplier = newZoom;
            ReplayController.setFitReplayCanvasToViewportOFF();
            ReplayState.rCanvasZoomIndex = newZoomIndex;
            moveAnchorPoint(center.x, center.y);
            setScale(newZoom);
            ReplayController.rFollowMouse.updateBounds();
            HintController.showMouseHintTemp(String(Math.floor(newZoom * 100)) + "%");
        }
    }
}
