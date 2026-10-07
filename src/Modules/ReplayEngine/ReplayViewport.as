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

        // 줌 키/버튼의 다음 단계: 지금 화면에 보이는 배율 기준으로 가장 가까운 다음 단계 (자동 줌 뒤에는 배율이 단계 값이 아니라서 저장된 단계 인덱스를 쓰면 크게 튐)
        // 지금 배율이 정확히 단계 값이면 그 다음 단계 (상대 오차 1e-6 미만은 같은 값으로 봄), 목록 끝을 넘으면 끝 값 유지
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

                return list.length - 1;
            }

            for (i = list.length - 1;i >= 0;i--)
            {
                if (list[i] < now * (1 - 1e-6))
                {
                    return i;
                }
            }

            return 0;
        }

        override public function zoomStep(zoomIn:Boolean):void
        {
            const newZoomIndex:int = nextZoomIndexFromVisible(zoomIn);
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
