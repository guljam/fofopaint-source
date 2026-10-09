package Modules.L4UI.ReplayEngine
{

    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.geom.Point;
    import Modules.L5App.ReplayEngine.ReplayController;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L4UI.CanvasViewport;
    import Modules.ReplayEngine.ReplayState;

    // 리플레이 모드 캔버스의 화면 배치 (ReplayDrawer.viewport)
    // 층: L2 엔진 - 리플레이 모드 캔버스의 화면 배치 (ReplayDrawer.viewport)
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

        // 줌 키/버튼의 다음 단계: 지금 화면에 보이는 배율 기준으로 가장 가까운 다음 단계 (자동 줌 뒤에는 배율이 단계 값이 아니라서 저장된 단계 인덱스를 쓰면 크게 튐)
        // 지금 배율이 정확히 단계 값이면 그 다음 단계 (상대 오차 1e-6 미만은 같은 값으로 봄). 그 방향에 더 간 단계가 없으면 -1 (배율을 바꾸지 않음)
        private function nextZoomIndexFromVisible(zoomIn:Boolean):int
        {
            const list:Array = CanvasView.canvasZoomMultiplierList;
            const now:Number = ReplayState.rCanvasZoomMultiplier;
            var i:int;

            if (zoomIn)
            {
                for (i = 0;i < list.length;i++)
                {
                    if (list[i] > now * (1 + 1e-6))
                    {
                        return i;
                    }
                }

                return -1;
            }

            for (i = list.length - 1;i >= 0;i--)
            {
                if (list[i] < now * (1 - 1e-6))
                {
                    return i;
                }
            }

            return -1;
        }

        override public function zoomStep(zoomIn:Boolean):void
        {
            const newZoomIndex:int = nextZoomIndexFromVisible(zoomIn);

            if (newZoomIndex < 0)
            {
                HintController.showMouseHintTemp(String(Math.floor(ReplayState.rCanvasZoomMultiplier * 100)) + "%"); // 더 갈 단계가 없으면 지금 배율 그대로 (줌아웃 키로 화면이 커지지 않게)
                return;
            }

            const newZoom:Number = CanvasView.canvasZoomMultiplierList[newZoomIndex];
            const center:Point = UIController.getStageCenterPos("replay");
            ReplayState.rLastCanvasZoomMultiplier = newZoom;
            ReplayController.setFitReplayCanvasToViewportOFF();
            ReplayState.rCanvasZoomIndex = newZoomIndex;
            moveAnchorPoint(center.x, center.y);
            setScale(newZoom);
            ReplayDrawer.cursorFollow.updateBounds();
            HintController.showMouseHintTemp(String(Math.floor(newZoom * 100)) + "%");
        }
    }
}
