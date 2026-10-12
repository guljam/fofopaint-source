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

    // 캔버스 하나(드로우 또는 리플레이)의 화면 배치: 앵커 이동, 배율, 가운데 정렬, 화면 안으로 끌어오기
    // 드로우는 DrawViewport(CanvasView.viewport), 리플레이는 ReplayViewport(ReplayDrawer.viewport)가 모드별 값과 동작을 재정의함
    // 하위 클래스는 생성자에서 아무것도 읽지 않고 getter로 그때그때 읽음 (static 초기화 중에 만들어도 순환 참조가 생기지 않게)
    // 층: L4 UI - 캔버스 하나의 화면 배치 공통 동작 (앵커 이동, 배율, 가운데 정렬)
    public class CanvasViewport
    {
        // 리플레이 모드 여부로 리플레이/드로우 캔버스의 뷰포트를 고름 (모드를 저장해 두고 쓰는 도구용)
        public static function getViewportByReplayMode(isReplayMode:Boolean):CanvasViewport
        {
            return (isReplayMode) ? ReplayDrawer.viewport : CanvasView.viewport;
        }

        // 지금 보이는 캔버스 (리플레이 모드면 리플레이 캔버스, 아니면 드로우 캔버스)
        public static function getCurrentVisibleViewport():CanvasViewport
        {
            return getViewportByReplayMode(ReplayState.isReplayModeON);
        }

        // 줌 단계 목록(드로우/리플레이 공용)에서 한 단계 이동한 인덱스
        public static function getNextZoomIndex(currentZoomIndex:int, zoomIn:Boolean):int
        {
            const maxZoomIndex:int = CanvasView.canvasZoomMultiplierList.length - 1;
            var newZoomIndex:int = currentZoomIndex;
            if (zoomIn)
            {
                newZoomIndex++;
                if (newZoomIndex > maxZoomIndex)
                {
                    newZoomIndex = maxZoomIndex;
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

        public function get canvasAnchorPoint():Sprite // 회전/배율이 걸리는 부모
        {
            throw new Error("CanvasViewport.canvasAnchorPoint must be overridden");
        }

        public function get canvasPanel():Sprite // 레이어들이 들어있는 캔버스 패널
        {
            throw new Error("CanvasViewport.canvasPanel must be overridden");
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

        public function get zoomMultiplier():Number
        {
            throw new Error("CanvasViewport.zoomMultiplier must be overridden");
        }

        // 줌 단계 한칸 확대/축소
        public function zoomByOneStep(zoomIn:Boolean):void
        {
            throw new Error("CanvasViewport.zoomByOneStep must be overridden");
        }

        // 배율 값을 저장하고 모드별 후속 처리 (앵커에 배율이 적용되기 전에 호출됨)
        protected function storeZoomMultiplier(newZoomMultiplier:Number):void
        {
            throw new Error("CanvasViewport.storeZoomMultiplier must be overridden");
        }

        // ---- 공용 동작 ----

        // 앵커를 (targetX, targetY)로 옮기고, 캔버스 패널은 회전과 배율을 반영해 반대로 움직여 캔버스 내용이 화면에서 제자리에 있게 함
        public function moveAnchorPoint(targetX:Number, targetY:Number):void
        {
            targetX = Math.round(targetX);
            targetY = Math.round(targetY);
            const anchorSprite:Sprite = canvasAnchorPoint;
            if (anchorSprite.x === targetX && anchorSprite.y === targetY)
            {
                return;
            }
            // round하면 정확도가 약간 줄어드는데, 안하면 그릴때 픽셀 어긋남
            // 캔버스 회전됐을때 점 위치를 구해줌
            // zoom된값을 나눠줘야 제대로된 이동거리가 나옴
            const zoomMultiplierNow:Number = zoomMultiplier;
            const rotatedMoveOffset:Point = Utils.rotatePoint((anchorSprite.x - targetX) / zoomMultiplierNow,
                    (anchorSprite.y - targetY) / zoomMultiplierNow,
                    anchorSprite.rotation);
            anchorSprite.x = targetX;
            anchorSprite.y = targetY;
            const panelSprite:Sprite = canvasPanel;
            panelSprite.x += Math.round(rotatedMoveOffset.x); // 이동한 만큼 거꾸로 움직여줌
            panelSprite.y += Math.round(rotatedMoveOffset.y); // rotate값 포함해서 움직여야함
        }

        // 캔버스 배율을 정함 (0이면 1배, 음수면 절댓값). 모드별 저장(storeZoomMultiplier)과 캡처 반전, 배율 표시, 리플레이 커서 크기까지 갱신함
        public function setCanvasScale(newZoomMultiplier:Number):void
        {
            if (!newZoomMultiplier)
                newZoomMultiplier = 1.0;
            if (newZoomMultiplier < 0.0)
                newZoomMultiplier = Math.abs(newZoomMultiplier);
            storeZoomMultiplier(newZoomMultiplier);
            const anchorSprite:Sprite = canvasAnchorPoint;
            anchorSprite.scaleX = newZoomMultiplier;
            anchorSprite.scaleY = newZoomMultiplier;
            if (CaptureController.isCaptureModeON && CaptureController.isCaptureCanvasFlipped)
            {
                anchorSprite.scaleX = -anchorSprite.scaleX;
            }
            if (!CaptureController.isCaptureModeON)
            {
                UIController.canvasInfoBox.setZoom(newZoomMultiplier);
            }
            ReplayDrawer.updateReplayCursorScale(newZoomMultiplier);
        }

        // 캔버스가 화면 밖으로 완전히 나가지 않게 앵커를 끌어옴 (최소 minVisiblePx 만큼은 보이게). 요소 전체가 창에서 넘어가지만 않게 하는 용도
        public function keepCanvasInStage():void
        {
            const anchorSprite:Sprite = canvasAnchorPoint;
            const minVisiblePx:int = 100; // 최소 100픽셀 은 보여야함
            const bounds:Object = Utils.getBoundRect(layer1Bitmap);
            const leftLimit:Number = UIController.STAGE_LEFT_OFFSET + minVisiblePx;
            const rightLimit:Number = AppContext.stage.stageWidth - (UIController.STAGE_RIGHT_OFFSET + minVisiblePx);
            const topLimit:Number = UIController.STAGE_TOP_OFFSET + minVisiblePx;
            const bottomLimit:Number = AppContext.stage.stageHeight - (UIController.STAGE_BOTTOM_OFFSET + minVisiblePx);
            // getbound는 보이는 그대로 사각형 끝점 좌표를 반환함
            const left:Number = bounds.left;
            const top:Number = bounds.top;
            const right:Number = bounds.right;
            const bottom:Number = bounds.bottom;
            // 꼭지점이 화면 경계에서 minVisiblePx 안쪽 한계를 넘어가면 넘어간 거리만큼 regpoint를 반대로 움직여줌
            if (left > rightLimit)
                anchorSprite.x -= left - rightLimit;
            else if (right < leftLimit)
                anchorSprite.x += leftLimit - right;
            if (bottom < topLimit)
                anchorSprite.y += topLimit - bottom;
            else if (top > bottomLimit)
                anchorSprite.y -= top - bottomLimit;
        }

        // 리플레이/캡처 모드에서 캔버스를 맞춤 영역(UIController.getCanvasFitAreaRect) 안에 맞추고 그 중심에 둠 (allowScaleAboveOne이면 1배보다 크게도 맞춤). 현재 보이는 캔버스의 viewport에 호출
        public function fitToViewportMargin(allowScaleAboveOne:Boolean = false):void
        {
            if (!ReplayState.isReplayModeON && !CaptureController.isCaptureModeON)
            {
                return;
            }
            const fitArea:Rectangle = UIController.getCanvasFitAreaRect();
            const availableStageWidth:int = fitArea.width;
            const availableStageHeight:int = fitArea.height;
            var fitWidth:Number = canvasWidth;
            var fitHeight:Number = canvasHeight;
            if (ReplayState.isReplayModeON && allowScaleAboveOne)
            {
                canvasAnchorPoint.scaleX = 1.0;
                canvasAnchorPoint.scaleY = 1.0; // 크기를 원래대로 해놓고 해야 길이 측정이 됨
                const layer1StageBounds:Rectangle = layer1Bitmap.getBounds(AppContext.stage);
                fitWidth = layer1StageBounds.right - layer1StageBounds.left;
                fitHeight = layer1StageBounds.bottom - layer1StageBounds.top;
            }
            if (CaptureController.isCaptureModeON)
            {
                if (CaptureController.captureCanvasRotationStep === 1 || CaptureController.captureCanvasRotationStep === 3)
                {
                    const savedFitWidth:Number = fitWidth;
                    fitWidth = fitHeight;
                    fitHeight = savedFitWidth;
                }
            }
            const scaleW:Number = availableStageWidth / fitWidth;
            const scaleH:Number = availableStageHeight / fitHeight;
            var fitScale:Number = Math.min(scaleW, scaleH);
            if (!allowScaleAboveOne && fitScale > 1.0)
            {
                fitScale = 1.0;
            }
            if (CaptureController.isCaptureModeON)
            {
                canvasAnchorPoint.rotation = 90 * CaptureController.captureCanvasRotationStep;
            }
            if (ReplayState.isReplayModeON && !ReplayState.isReplayCanvasFitToWindow)
            {
                ReplayState.isReplayFinishedWithFiwWindow = true;
            }
            if (CaptureController.isCaptureModeON)
            {
                setCanvasScale(fitScale);
                centerCanvasInStage("capture");
            }
            else if (ReplayState.isReplayModeON)
            {
                setCanvasScale(fitScale);
                centerCanvasInStage("replay");
            }
            if (!allowScaleAboveOne || ReplayState.isReplayFinished)
            {
                layer1Bitmap.smoothing = true;
                layer2Bitmap.smoothing = true;
            }
        }

        // 캔버스 정 가운데로. centerMode("draw"/"replay"/"capture")는 화면 중심 좌표를 구하는 기준
        public function centerCanvasInStage(centerMode:String):void
        {
            const stageCenterPos:Point = UIController.getStageCenterPos(centerMode);
            canvasAnchorPoint.x = Math.floor(stageCenterPos.x);
            canvasAnchorPoint.y = Math.floor(stageCenterPos.y);
            canvasPanel.x = Math.floor(-canvasWidth / 2);
            canvasPanel.y = Math.floor(-canvasHeight / 2);
        }
    }
}
