package Modules
{
    import Modules.CaptureEngine.CaptureController;
    import Modules.DrawEngine.CanvasView;
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.ReplayEngine.ReplayState;
    import Modules.UIEngine.UIController;

    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.geom.Point;

    // 캔버스 하나(드로우 또는 리플레이)의 화면 배치: 앵커 이동, 배율, 가운데 정렬, 화면 안으로 끌어오기
    // 드로우는 DrawViewport(CanvasView.viewport), 리플레이는 ReplayViewport(ReplayDrawer.viewport)가 모드별 값과 동작을 재정의함
    // 하위 클래스는 생성자에서 아무것도 읽지 않고 getter로 그때그때 읽음 (static 초기화 중에 만들어도 순환 참조가 생기지 않게)
    public class CanvasViewport
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static function forMode(isReplayMode:Boolean):CanvasViewport
        {
            return (isReplayMode) ? ReplayDrawer.viewport : CanvasView.viewport;
        }

        // 지금 보이는 캔버스 (리플레이 모드면 리플레이 캔버스, 아니면 드로우 캔버스)
        public static function current():CanvasViewport
        {
            return forMode(ReplayState.isReplayModeON);
        }

        // 줌 단계 목록(드로우/리플레이 공용)에서 한 단계 이동한 인덱스
        public static function nextZoomIndex(index:int, zoomIn:Boolean):int
        {
            const zoomMax:int = CanvasView.canvasZoomMultiplierList.length - 1;
            var newZoomIndex:int = index;
            if (zoomIn)
            {
                newZoomIndex++;
                if (newZoomIndex > zoomMax)
                {
                    newZoomIndex = zoomMax;
                }
            }
            else
            {
                newZoomIndex--;
                if (newZoomIndex < 0)
                {
                    newZoomIndex = 0;
                }
            }
            return newZoomIndex;
        }

        // ---- 하위 클래스가 재정의 ----

        public function get anchor():Sprite // 회전/배율이 걸리는 부모
        {
            throw new Error("CanvasViewport.anchor must be overridden");
        }

        public function get panel():Sprite // 레이어들이 들어있는 캔버스 패널
        {
            throw new Error("CanvasViewport.panel must be overridden");
        }

        public function get layer1Bitmap():Bitmap
        {
            throw new Error("CanvasViewport.layer1Bitmap must be overridden");
        }

        public function get layer2Bitmap():Bitmap
        {
            throw new Error("CanvasViewport.layer2Bitmap must be overridden");
        }

        public function get canvasWidth():Number
        {
            throw new Error("CanvasViewport.canvasWidth must be overridden");
        }

        public function get canvasHeight():Number
        {
            throw new Error("CanvasViewport.canvasHeight must be overridden");
        }

        public function get zoom():Number
        {
            throw new Error("CanvasViewport.zoom must be overridden");
        }

        // 줌 단계 한칸 확대/축소
        public function zoomStep(zoomIn:Boolean):void
        {
            throw new Error("CanvasViewport.zoomStep must be overridden");
        }

        // 배율 값을 저장하고 모드별 후속 처리 (앵커에 배율이 적용되기 전에 호출됨)
        protected function storeZoom(zoomValue:Number):void
        {
            throw new Error("CanvasViewport.storeZoom must be overridden");
        }

        // ---- 공용 동작 ----

        public function moveAnchorPoint(tx:Number, ty:Number):void
        {
            tx = Math.round(tx);
            ty = Math.round(ty);
            const xAnc:Sprite = anchor;
            if (xAnc.x === tx && xAnc.y === ty)
            {
                return;
            }
            // round하면 정확도가 약간 줄어드는데, 안하면 그릴때 픽셀 어긋남
            // 캔버스 회전됐을때 점 위치를 구해줌
            // zoom된값을 나눠줘야 제대로된 이동거리가 나옴
            const xZoomed:Number = zoom;
            const rotateToolMoveEvent:Point = Utils.rotatePoint((xAnc.x - tx) / xZoomed,
                    (xAnc.y - ty) / xZoomed,
                    xAnc.rotation);
            xAnc.x = tx;
            xAnc.y = ty;
            const xCanvas:Sprite = panel;
            xCanvas.x += Math.round(rotateToolMoveEvent.x); // 이동한 만큼 거꾸로 움직여줌
            xCanvas.y += Math.round(rotateToolMoveEvent.y); // rotate값 포함해서 움직여야함
        }

        public function setScale(zoomValue:Number):void
        {
            if (!zoomValue)
                zoomValue = 1.0;
            if (zoomValue < 0.0)
                zoomValue = Math.abs(zoomValue);
            storeZoom(zoomValue);
            const xAnc:Sprite = anchor;
            xAnc.scaleX = zoomValue;
            xAnc.scaleY = zoomValue;
            if (CaptureController.isCaptureModeON && CaptureController.isCaptureCanvasFlipped)
            {
                xAnc.scaleX = -xAnc.scaleX;
            }
            if (!CaptureController.isCaptureModeON)
            {
                UIController.canvasInfoBox.setZoom(zoomValue);
            }
            ReplayDrawer.updateReplayCursorScale(zoomValue);
        }

        // check box position함수는 요소 전체가 창에서 넘어가만 않게 하는거고
        public function keepInStage():void
        {
            const xAnc:Sprite = anchor;
            const offset:int = 100; // 최소 100픽셀 은 보여야함
            const bounds:Object = Utils.getBoundRect(layer1Bitmap);
            const leftLimit:Number = UIController.STAGE_LEFT_OFFSET + offset;
            const rightLimit:Number = main.stage.stageWidth - (UIController.STAGE_RIGHT_OFFSET + offset);
            const topLimit:Number = UIController.STAGE_TOP_OFFSET + offset;
            const bottomLimit:Number = main.stage.stageHeight - (UIController.STAGE_BOTTOM_OFFSET + offset);
            // getbound는 보이는 그대로 사각형 끝점 좌표를 반환함
            const left:Number = bounds.left;
            const top:Number = bounds.top;
            const right:Number = bounds.right;
            const bottom:Number = bounds.bottom;
            // 꼭지점이 경계offset을 넘어가면 넘어간 거리만큼 regpoint를 반대로 움직여줌
            if (left > rightLimit)
                xAnc.x -= left - rightLimit;
            else if (right < leftLimit)
                xAnc.x += leftLimit - right;
            if (bottom < topLimit)
                xAnc.y += topLimit - bottom;
            else if (top > bottomLimit)
                xAnc.y -= top - bottomLimit;
        }

        // 캔버스 정 가운데로. mode("draw"/"replay"/"capture")는 화면 중심 좌표를 구하는 기준
        public function centerIn(mode:String):void
        {
            const center:Point = UIController.getStageCenterPos(mode);
            anchor.x = Math.floor(center.x);
            anchor.y = Math.floor(center.y);
            panel.x = Math.floor(-canvasWidth / 2);
            panel.y = Math.floor(-canvasHeight / 2);
        }
    }
}
