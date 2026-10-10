package Modules.L4UI
{
    import Modules.L1Data.AppContext;

    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L2Engine.ReplayEngine.ReplayState;
    import Modules.L1Data.Utils;
    import Modules.L4UI.CaptureEngine.CaptureController;
    import Modules.L1Data.UIEngine.UITheme;

    // 캔버스 하나(드로우 또는 리플레이)의 화면 배치: 앵커 이동, 배율, 가운데 정렬, 화면 안으로 끌어오기
    // 드로우는 DrawViewport(CanvasView.viewport), 리플레이는 ReplayViewport(ReplayDrawer.viewport)가 모드별 값과 동작을 재정의함
    // 하위 클래스는 생성자에서 아무것도 읽지 않고 getter로 그때그때 읽음 (static 초기화 중에 만들어도 순환 참조가 생기지 않게)
    // 층: L4 UI - 캔버스 하나의 화면 배치 공통 동작 (앵커 이동, 배율, 가운데 정렬)
    public class CanvasViewport
    {
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
            const rightLimit:Number = AppContext.stage.stageWidth - (UIController.STAGE_RIGHT_OFFSET + offset);
            const topLimit:Number = UIController.STAGE_TOP_OFFSET + offset;
            const bottomLimit:Number = AppContext.stage.stageHeight - (UIController.STAGE_BOTTOM_OFFSET + offset);
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

        // 리플레이/캡처 모드에서 캔버스를 창 여백 안에 맞춤 (fitting이면 1배보다 크게도 맞춤). 현재 보이는 캔버스의 viewport에 호출
        public function fitToViewportMargin(fitting:Boolean = false):void
        {
            if (!ReplayState.isReplayModeON && !CaptureController.isCaptureModeON)
            {
                return;
            }
            const uiscale:Number = UITheme.getUIScale();
            const offsetX:Number = 44 + UIController.STAGE_LEFT_OFFSET + UIController.STAGE_RIGHT_OFFSET;
            const offsetY:Number = (CaptureController.isCaptureModeON) ? (UIController.topBar.BARSIZE) * uiscale + 42 * uiscale : (UIController.topBar.BARSIZE) * uiscale + 42 * uiscale;
            const stw:int = AppContext.stage.stageWidth - offsetX;
            const sth:int = AppContext.stage.stageHeight - offsetY - UIController.STAGE_BOTTOM_OFFSET;
            var fitWidth:Number = canvasWidth;
            var fitHeight:Number = canvasHeight;
            if (ReplayState.isReplayModeON && fitting)
            {
                anchor.scaleX = 1.0;
                anchor.scaleY = 1.0; // 크기를 원래대로 해놓고 해야 길이 측정이 됨
                const b:Rectangle = layer1Bitmap.getBounds(AppContext.stage);
                fitWidth = b.right - b.left;
                fitHeight = b.bottom - b.top;
            }
            if (CaptureController.isCaptureModeON)
            {
                if (CaptureController.captureCanvasRotationStep === 1 || CaptureController.captureCanvasRotationStep === 3)
                {
                    const widthSave:Number = fitWidth;
                    fitWidth = fitHeight;
                    fitHeight = widthSave;
                }
            }
            const scaleW:Number = stw / fitWidth;
            const scaleH:Number = sth / fitHeight;
            var scale:Number = Math.min(scaleW, scaleH);
            if (!fitting && scale > 1.0)
            {
                scale = 1.0;
            }
            if (CaptureController.isCaptureModeON)
            {
                anchor.rotation = 90 * CaptureController.captureCanvasRotationStep;
            }
            if (ReplayState.isReplayModeON && !ReplayState.isReplayCanvasFitToWindow)
            {
                ReplayState.isReplayFinishedWithFiwWindow = true;
            }
            if (CaptureController.isCaptureModeON)
            {
                setScale(scale);
                centerIn("capture");
            }
            else if (ReplayState.isReplayModeON)
            {
                setScale(scale);
                centerIn("replay");
            }
            if (!fitting || ReplayState.isReplayFinished)
            {
                layer1Bitmap.smoothing = true;
                layer2Bitmap.smoothing = true;
            }
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
