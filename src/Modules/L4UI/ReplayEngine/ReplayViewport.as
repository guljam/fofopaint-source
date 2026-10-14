package Modules.L4UI.ReplayEngine
{

    import flash.display.Bitmap;
    import flash.display.Sprite;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.L4UI.CanvasViewport;
    import Modules.L2Engine.ReplayEngine.ReplayState;

    // 리플레이 모드 캔버스의 화면 배치 (ReplayDrawer.viewport)
    // 층: L4 UI - 리플레이 모드 캔버스의 화면 배치 (ReplayDrawer.viewport)
    public class ReplayViewport extends CanvasViewport
    {
        override public function get canvasAnchorPoint():Sprite
        {
            return ReplayDrawer.rCanvasAnchorPoint;
        }

        override public function get canvasPanel():Sprite
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

        override public function get zoomMultiplier():Number
        {
            return ReplayState.rCanvasZoomMultiplier;
        }

        override protected function storeZoomMultiplier(newZoomMultiplier:Number):void
        {
            ReplayState.rCanvasZoomMultiplier = newZoomMultiplier;
            if (ReplayState.rAirBrushSize > 0)
            {
                ReplayDrawer.blurReplayCanvasByValue(ReplayState.rAirBrushSize);
            }
        }
    }
}
