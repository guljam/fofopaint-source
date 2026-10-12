package Modules.L4UI.CaptureEngine
{
    import Modules.L1Data.AppContext;

    import flash.display.CapsStyle;
    import flash.display.LineScaleMode;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L2Engine.ReplayEngine.ReplayState;
    import Modules.L1Data.MouseState;
    import Modules.L4UI.CaptureEngine.CaptureController;
    import Modules.L1Data.FOFOTimer;
    import Modules.L1Data.InputPriority;

    // 층: L4 UI - 캡처 영역 지정과 표시
    public class CaptureArea
    {
        public static var captureDragAreaOverlay:Shape = new Shape(); // 스크린샷 박스 미리보기 그려줌
        private static var captureCanvasPanel:Sprite;
        private static var hasMouseMovedInDrag:Boolean = false;
        private static var canvasWidth:Number = 0;
        private static var canvasHeight:Number = 0;
        private static var dragStartMousePos:Point = new Point(0, 0);
        private static const canvasFullRect:Rectangle = new Rectangle();
        private static const dragRawRect:Rectangle = new Rectangle(); // 새 영역 그리기 드래그 전용
        private static const rectClamped:Rectangle = new Rectangle();
        private static const moveStartRect:Rectangle = new Rectangle(); // 영역 이동 드래그 시작 시점의 영역
        private static var minCaptureAreaSize:Number = 10.0;
        private static const dragStartThresholdPx:Number = 5.0;

        // 영역 변(테두리) 개별 크기 조정. 마우스 좌표는 captureCanvasPanel 지역 좌표(캔버스 좌표)라 회전/대칭과 무관
        private static const EDGE_NONE:int = -1;
        private static const EDGE_TOP:int = 0;
        private static const EDGE_BOTTOM:int = 1;
        private static const EDGE_LEFT:int = 2;
        private static const EDGE_RIGHT:int = 3;
        private static const edgeHitPx:Number = 10.0; // 테두리 기준 +-10px(화면 px)에서 클릭 반응
        private static const edgeHighlightPx:Number = 2.0; // 호버/드래그 중인 변 강조선 굵기(화면 px)
        private static var highlightedEdge:int = EDGE_NONE;
        private static var resizingEdge:int = EDGE_NONE;
        private static var dragEdgeStartPosition:Number = 0;
        private static var isDragging:Boolean = false;

        private static function validateCaptureArea():void
        {
            var intersection:Rectangle = canvasFullRect.intersection(rectClamped);
            if (intersection.width >= minCaptureAreaSize && intersection.height >= minCaptureAreaSize)
            {
                rectClamped.x = Math.round(intersection.x);
                rectClamped.y = Math.round(intersection.y);
                rectClamped.width = Math.round(intersection.width);
                rectClamped.height = Math.round(intersection.height);
            }
            else
            {
                FOFOTimer.add(0.0, false, function ():void
                    {
                        resetCaptureArea();
                    });
            }
        }

        private static function normalizeRectClamped():void
        {
            if (rectClamped.width < 0)
            {
                rectClamped.width = Math.abs(rectClamped.width);
                rectClamped.x = rectClamped.x - rectClamped.width;
            }
            if (rectClamped.height < 0)
            {
                rectClamped.height = Math.abs(rectClamped.height);
                rectClamped.y = rectClamped.y - rectClamped.height;
            }
        }

        // ---- 변(테두리) 조정: 4변을 edge 번호 하나로 통합 ----
        private static function getCaptureAreaEdgePosition(edge:int):Number
        {
            switch (edge)
            {
                case EDGE_TOP:
                    return rectClamped.y;
                case EDGE_BOTTOM:
                    return rectClamped.y + rectClamped.height;
                case EDGE_LEFT:
                    return rectClamped.x;
                default:
                    return rectClamped.x + rectClamped.width;
            }
        }

        // 위/왼쪽 변은 시작점, 아래/오른쪽 변은 끝점을 움직임. 반대 변과 minCaptureAreaSize 이상 유지, 캔버스 안으로 제한
        private static function setCaptureAreaEdgePosition(edge:int, position:Number):void
        {
            const isVerticalEdge:Boolean = (edge === EDGE_TOP || edge === EDGE_BOTTOM);
            const isStartEdge:Boolean = (edge === EDGE_TOP || edge === EDGE_LEFT);
            const start:Number = (isVerticalEdge) ? rectClamped.y : rectClamped.x;
            const end:Number = start + ((isVerticalEdge) ? rectClamped.height : rectClamped.width);
            const limit:Number = (isVerticalEdge) ? canvasHeight : canvasWidth;
            var newStart:Number = start;
            var newEnd:Number = end;

            if (isStartEdge)
            {
                newStart = Math.max(0, Math.min(end - minCaptureAreaSize, Math.round(position)));
            }
            else
            {
                newEnd = Math.max(start + minCaptureAreaSize, Math.min(limit, Math.round(position)));
            }

            if (isVerticalEdge)
            {
                rectClamped.y = newStart;
                rectClamped.height = newEnd - newStart;
            }
            else
            {
                rectClamped.x = newStart;
                rectClamped.width = newEnd - newStart;
            }
        }

        // 테두리 중심 +-edgeHitPx(화면 px) 안에 들어온 변. 겹치면 위, 아래, 왼쪽, 오른쪽 순으로 먼저 탐지된 변
        private static function hitTestCaptureAreaEdge(canvasMouseX:Number, canvasMouseY:Number):int
        {
            const edgeHitBandPx:Number = edgeHitPx / getCanvasScale();
            const left:Number = rectClamped.x;
            const right:Number = rectClamped.x + rectClamped.width;
            const top:Number = rectClamped.y;
            const bottom:Number = rectClamped.y + rectClamped.height;
            const inX:Boolean = (canvasMouseX >= left - edgeHitBandPx && canvasMouseX <= right + edgeHitBandPx);
            const inY:Boolean = (canvasMouseY >= top - edgeHitBandPx && canvasMouseY <= bottom + edgeHitBandPx);

            if (inX && Math.abs(canvasMouseY - top) <= edgeHitBandPx)
                return EDGE_TOP;
            if (inX && Math.abs(canvasMouseY - bottom) <= edgeHitBandPx)
                return EDGE_BOTTOM;
            if (inY && Math.abs(canvasMouseX - left) <= edgeHitBandPx)
                return EDGE_LEFT;
            if (inY && Math.abs(canvasMouseX - right) <= edgeHitBandPx)
                return EDGE_RIGHT;

            return EDGE_NONE;
        }

        private static function getHoveredEdge():int
        {
            if (!captureCanvasPanel || isFullImageCapture())
            {
                return EDGE_NONE;
            }

            // 값싼 변 판정을 먼저 하고, 변에 걸렸을 때만 비싼 hitTestPoint를 확인함
            const edge:int = hitTestCaptureAreaEdge(captureCanvasPanel.mouseX, captureCanvasPanel.mouseY);
            if (edge === EDGE_NONE)
            {
                return EDGE_NONE;
            }

            if (UIController.topBar.hitTestPoint(AppContext.stage.mouseX, AppContext.stage.mouseY) || CaptureStamp.captureStampFontListBox.visible)
            {
                return EDGE_NONE;
            }

            return edge;
        }

        private static function setHighlightedEdge(edge:int):void
        {
            if (highlightedEdge === edge)
            {
                return;
            }

            highlightedEdge = edge;
            drawCaptureAreaOverlay();
        }

        // 드래그 중이 아닐 때 마우스 위치의 변을 강조함
        private static function onMouseMoveEdgeHover(e:MouseEvent):void
        {
            if (!CaptureController.isCaptureModeON || isDragging)
            {
                return;
            }

            setHighlightedEdge(getHoveredEdge());
        }

        // 캡처 모드 중 마우스가 영역의 변 위에 오면 그 변을 강조하기 위한 마우스 이동 추적을 시작함
        public static function startEdgeHoverTracking():void
        {
            AppContext.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveEdgeHover);
        }

        // 변 강조 추적을 멈추고 강조를 지움
        public static function stopEdgeHoverTracking():void
        {
            AppContext.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveEdgeHover);
            highlightedEdge = EDGE_NONE;
        }

        // 변 크기 조절: 드래그 시작 시점의 변 위치 + 마우스 이동량으로 변을 옮김
        private static function onMouseMoveResizeEdge(e:MouseEvent):void
        {
            if (!CaptureController.isCaptureModeON)
            {
                removeCaptureAreaEvents();
                return;
            }

            const isVerticalEdge:Boolean = (resizingEdge === EDGE_TOP || resizingEdge === EDGE_BOTTOM);
            const dragDeltaAlongEdge:Number = (isVerticalEdge) ? captureCanvasPanel.mouseY - dragStartMousePos.y : captureCanvasPanel.mouseX - dragStartMousePos.x;
            const edgePositionBefore:Number = getCaptureAreaEdgePosition(resizingEdge);

            setCaptureAreaEdgePosition(resizingEdge, dragEdgeStartPosition + Math.round(dragDeltaAlongEdge));

            if (getCaptureAreaEdgePosition(resizingEdge) === edgePositionBefore)
            {
                return;
            }

            if (!hasMouseMovedInDrag)
            {
                hasMouseMovedInDrag = true;
                CaptureController.onCaptureAreaDragStarted();
            }

            HintController.showBottomHint(getRotatedRectSizeString());
            drawCaptureAreaOverlay();
        }

        // 영역 이동: 드래그 시작 시점 위치 + 마우스 이동량으로 매번 새로 계산(누적 안 함)
        private static function onMouseMoveMoveCaptureArea(e:MouseEvent):void
        {
            if (!CaptureController.isCaptureModeON)
            {
                removeCaptureAreaEvents();
                return;
            }

            const dragDeltaX:Number = Math.round(captureCanvasPanel.mouseX - dragStartMousePos.x);
            const dragDeltaY:Number = Math.round(captureCanvasPanel.mouseY - dragStartMousePos.y);

            if (!hasMouseMovedInDrag)
            {
                if (Math.abs(dragDeltaX) < dragStartThresholdPx && Math.abs(dragDeltaY) < dragStartThresholdPx)
                {
                    return;
                }

                hasMouseMovedInDrag = true;
                CaptureController.onCaptureAreaDragStarted();
            }

            const newX:Number = Math.round(Math.max(0, Math.min(canvasWidth - rectClamped.width, moveStartRect.x + dragDeltaX)));
            const newY:Number = Math.round(Math.max(0, Math.min(canvasHeight - rectClamped.height, moveStartRect.y + dragDeltaY)));
            if (newX === rectClamped.x && newY === rectClamped.y)
            {
                return;
            }

            rectClamped.x = newX;
            rectClamped.y = newY;
            drawCaptureAreaOverlay();
        }

        // 새 영역 그리기: 시작점에서 마우스까지를 영역으로 삼음 (일정 거리 이상 움직여야 시작)
        private static function onMouseMoveDrawCaptureArea(e:MouseEvent):void
        {
            if (!CaptureController.isCaptureModeON)
            {
                removeCaptureAreaEvents();
                return;
            }

            var canvasMouseX:Number = captureCanvasPanel.mouseX;
            var canvasMouseY:Number = captureCanvasPanel.mouseY;
            var dragDeltaX:Number = Math.round(canvasMouseX - dragStartMousePos.x);
            var dragDeltaY:Number = Math.round(canvasMouseY - dragStartMousePos.y);

            if (hasMouseMovedInDrag)
            {
                if (dragRawRect.width === dragDeltaX && dragRawRect.height === dragDeltaY)
                {
                    return;
                }

                dragRawRect.width = dragDeltaX;
                dragRawRect.height = dragDeltaY;
                rectClamped.x = dragRawRect.x;
                rectClamped.y = dragRawRect.y;
                rectClamped.width = dragRawRect.width;
                rectClamped.height = dragRawRect.height;
                normalizeRectClamped();
                HintController.showBottomHint(getRotatedRectSizeString());
                drawCaptureAreaOverlay();
            }
            else if (Math.abs(dragDeltaX) >= dragStartThresholdPx || Math.abs(dragDeltaY) >= dragStartThresholdPx)
            {
                dragRawRect.x = dragStartMousePos.x;
                dragRawRect.y = dragStartMousePos.y;
                dragRawRect.width = dragDeltaX;
                dragRawRect.height = dragDeltaY;
                rectClamped.x = dragRawRect.x;
                rectClamped.y = dragRawRect.y;
                rectClamped.width = dragRawRect.width;
                rectClamped.height = dragRawRect.height;
                HintController.showBottomHint(getRotatedRectSizeString());
                hasMouseMovedInDrag = true;
                CaptureController.onCaptureAreaDragStarted();
            }
        }

        private static const DRAG_OWNER:String = "captureArea";

        private static function onMouseUpCaptureArea(e:MouseEvent):void
        {
            finishCaptureAreaDrag();
        }

        // 이벤트 객체를 쓰지 않음. mouseUp을 못받는 경우(alt+tab 등)에도 MouseState.finishAllDrags가 직접 호출함
        private static function finishCaptureAreaDrag():void
        {
            MouseState.endDrag(DRAG_OWNER);
            removeCaptureAreaEvents();

            if (hasMouseMovedInDrag === true)
            {
                // rect길이가 음수인경우 cx cy를 양수로 다시 맞추어줌
                normalizeRectClamped();
                validateCaptureArea();
                UIController.topBar.capClipBoard.alpha = 1.0;
                drawCaptureAreaOverlay();
                CaptureController.onCaptureAreaChanged();
            }

            hasMouseMovedInDrag = false;
            isDragging = false;
            resizingEdge = EDGE_NONE;
            setHighlightedEdge(getHoveredEdge());
        }

        private static function removeCaptureAreaEvents():void
        {
            AppContext.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveDrawCaptureArea);
            AppContext.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveMoveCaptureArea);
            AppContext.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveResizeEdge);
            AppContext.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpCaptureArea);
        }

        public static function updateDrawArea(forceFlag:Boolean = false):void
        {
            if ((rectClamped.width >= minCaptureAreaSize && rectClamped.height >= minCaptureAreaSize) || forceFlag)
            {
                if (!isDragging)
                {
                    highlightedEdge = getHoveredEdge();
                }
                drawCaptureAreaOverlay();
            }
            CaptureController.onCaptureAreaChanged();
        }

        // 지금 캔버스 배율 (화면 px을 캔버스 px로 바꿀 때 씀)
        private static function getCanvasScale():Number
        {
            return (ReplayState.isReplayModeON) ? Math.abs(ReplayDrawer.rCanvasAnchorPoint.scaleX) : Math.abs(CanvasView.canvasAnchorPoint.scaleX);
        }

        // 영역 밖을 어둡게, 영역 테두리를 흰 선으로, 강조 중인 변을 주황 선으로 오버레이에 그림
        private static function drawCaptureAreaOverlay():void
        {
            const canvasScale:Number = getCanvasScale();
            const lineSize:Number = Math.ceil(1 / canvasScale);

            captureDragAreaOverlay.graphics.clear();
            // 배경색 약간 어둡게 해줌
            captureDragAreaOverlay.graphics.lineStyle(0, 0, 0);
            captureDragAreaOverlay.graphics.beginFill(0, 0.3);
            captureDragAreaOverlay.graphics.drawRect(0, 0, canvasWidth, rectClamped.y); // 위
            captureDragAreaOverlay.graphics.drawRect(0, rectClamped.y, rectClamped.x, rectClamped.height); // 왼쪽
            captureDragAreaOverlay.graphics.drawRect(rectClamped.x + rectClamped.width, rectClamped.y, canvasWidth - (rectClamped.x + rectClamped.width), rectClamped.height); // 오른쪽
            captureDragAreaOverlay.graphics.drawRect(0, rectClamped.y + rectClamped.height, canvasWidth, canvasHeight - (rectClamped.y + rectClamped.height)); // 아래
            captureDragAreaOverlay.graphics.endFill();

            captureDragAreaOverlay.graphics.lineStyle(lineSize, 0xFFFFFF, 1.0, true);
            captureDragAreaOverlay.graphics.beginFill(0xFFFFFF, 0.0);
            captureDragAreaOverlay.graphics.drawRect(rectClamped.x, rectClamped.y, rectClamped.width, rectClamped.height);
            captureDragAreaOverlay.graphics.endFill();

            if (highlightedEdge !== EDGE_NONE && !isFullImageCapture())
            {
                const left:Number = rectClamped.x;
                const right:Number = rectClamped.x + rectClamped.width;
                const top:Number = rectClamped.y;
                const bottom:Number = rectClamped.y + rectClamped.height;

                captureDragAreaOverlay.graphics.lineStyle(edgeHighlightPx / canvasScale, 0xFF6600, 1.0, true, LineScaleMode.NORMAL, CapsStyle.NONE);

                switch (highlightedEdge)
                {
                    case EDGE_TOP:
                        captureDragAreaOverlay.graphics.moveTo(left, top);
                        captureDragAreaOverlay.graphics.lineTo(right, top);
                        break;
                    case EDGE_BOTTOM:
                        captureDragAreaOverlay.graphics.moveTo(left, bottom);
                        captureDragAreaOverlay.graphics.lineTo(right, bottom);
                        break;
                    case EDGE_LEFT:
                        captureDragAreaOverlay.graphics.moveTo(left, top);
                        captureDragAreaOverlay.graphics.lineTo(left, bottom);
                        break;
                    default:
                        captureDragAreaOverlay.graphics.moveTo(right, top);
                        captureDragAreaOverlay.graphics.lineTo(right, bottom);
                        break;
                }
            }
        }

        public static function getRotatedRectSizeString():String
        {
            const w:Number = Math.abs(rectClamped.width);
            const h:Number = Math.abs(rectClamped.height);

            if (rectClamped.x === 0.0 && rectClamped.y === 0.0 && rectClamped.width === 0.0 && rectClamped.height === 0.0)
            {
                if (ReplayState.isReplayModeON)
                {
                    return !CaptureController.isCaptureAxisSwapped() ? ReplayState.RCANVAS_WIDTH + " x " + ReplayState.RCANVAS_HEIGHT : ReplayState.RCANVAS_HEIGHT + " x " + ReplayState.RCANVAS_WIDTH;
                }
                else
                {
                    return !CaptureController.isCaptureAxisSwapped() ? canvasWidth + " x " + canvasHeight : canvasHeight + " x " + canvasWidth;
                }
            }

            if (w < minCaptureAreaSize || h < minCaptureAreaSize)
            {
                return "";
            }

            return !CaptureController.isCaptureAxisSwapped() ? w + " x " + h : h + " x " + w;
        }

        // 영역, 드래그 시작점, 변 강조/조절 상태를 비움 (캔버스 정보는 유지)
        private static function clearCaptureAreaState():void
        {
            dragStartMousePos.setTo(0, 0);
            rectClamped.setTo(0, 0, 0, 0);
            dragRawRect.setTo(0, 0, 0, 0);
            highlightedEdge = EDGE_NONE;
            resizingEdge = EDGE_NONE;
        }

        public static function resetCaptureArea():void
        {
            clearCaptureAreaState();
            captureDragAreaOverlay.graphics.clear();
            UIController.topBar.capClipBoard.alpha = 1.0;
            CaptureController.onCaptureAreaChanged();
        }

        public static function resetCaptureAreaAndCanvasInfo():void
        {
            clearCaptureAreaState();
            canvasWidth = 0;
            canvasHeight = 0;
            canvasFullRect.setTo(0, 0, 0, 0);
            captureCanvasPanel = null;
            hasMouseMovedInDrag = false;
            // 드래그 도중 캡처 모드가 끝나면 리스너와 등록이 남지 않게 정리함
            if (isDragging)
            {
                removeCaptureAreaEvents();
                MouseState.endDrag(DRAG_OWNER);
            }
            isDragging = false;
            UIController.topBar.capClipBoard.alpha = 1.0;
        }

        // 영역을 지정하지 않아서 이미지 전체를 캡처하는 상태인지
        public static function isFullImageCapture():Boolean
        {
            return rectClamped.width === 0.0 || rectClamped.height === 0.0;
        }

        // 지금 캡처 영역(캔버스 좌표). 영역이 없으면 너비 또는 높이가 0 (isFullImageCapture)
        public static function getCaptureArea():Rectangle
        {
            return rectClamped;
        }

        // 마우스가 지금 캡처 영역 안에 있는지
        public static function isCursorInCaptureArea():Boolean
        {
            if (!captureCanvasPanel)
            {
                return false;
            }
            return rectClamped.contains(captureCanvasPanel.mouseX, captureCanvasPanel.mouseY);
        }

        // 드래그를 시작함. 이전 드래그가 열려 있으면 먼저 마무리하고 마우스 이동/업 리스너를 등록함
        private static function beginCaptureAreaDrag(canvasMouseX:Number, canvasMouseY:Number, onMouseMoveListener:Function):void
        {
            // mouseUp을 놓쳐서 이전 드래그가 열려있으면 먼저 마무리함
            if (isDragging)
            {
                finishCaptureAreaDrag();
            }

            isDragging = true;
            hasMouseMovedInDrag = false;
            dragStartMousePos.setTo(canvasMouseX, canvasMouseY);
            AppContext.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveListener);
            AppContext.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpCaptureArea, false, InputPriority.DEFAULT);
            MouseState.beginDrag(DRAG_OWNER, finishCaptureAreaDrag);
        }

        // 캡처 모드 진입 시 한 번 호출함. 캡처 모드 중에는 캔버스 크기와 패널이 바뀌지 않음
        public static function initCaptureCanvasInfo():void
        {
            if (ReplayState.isReplayModeON)
            {
                canvasWidth = ReplayState.RCANVAS_WIDTH;
                canvasHeight = ReplayState.RCANVAS_HEIGHT;
                captureCanvasPanel = ReplayDrawer.rCanvasPanel;
            }
            else
            {
                canvasWidth = DrawCanvas.CANVAS_WIDTH;
                canvasHeight = DrawCanvas.CANVAS_HEIGHT;
                captureCanvasPanel = CanvasView.canvasPanel;
            }
            canvasFullRect.setTo(0, 0, canvasWidth, canvasHeight);
        }

        // 마우스를 눌렀을 때 부름. 영역이 없으면 새로 그리기, 변 근처면 크기 조절, 영역 안이면 이동 드래그를 시작함 (상단바 위는 무시)
        public static function startCaptureAreaDrag():void
        {
            if (UIController.topBar.hitTestPoint(AppContext.stage.mouseX, AppContext.stage.mouseY) === false)
            {
                const canvasMouseX:Number = captureCanvasPanel.mouseX;
                const canvasMouseY:Number = captureCanvasPanel.mouseY;
                const hasCaptureArea:Boolean = !isFullImageCapture();
                const edge:int = (hasCaptureArea) ? hitTestCaptureAreaEdge(canvasMouseX, canvasMouseY) : EDGE_NONE;

                if (edge !== EDGE_NONE) // 크기 조절
                {
                    resizingEdge = edge;
                    highlightedEdge = edge;
                    dragEdgeStartPosition = getCaptureAreaEdgePosition(edge);
                    beginCaptureAreaDrag(canvasMouseX, canvasMouseY, onMouseMoveResizeEdge);
                }
                else if (hasCaptureArea && isCursorInCaptureArea()) // 영역 이동
                {
                    moveStartRect.copyFrom(rectClamped);
                    setHighlightedEdge(EDGE_NONE);
                    beginCaptureAreaDrag(canvasMouseX, canvasMouseY, onMouseMoveMoveCaptureArea);
                }
                else if (!hasCaptureArea) // 새로 그리기
                {
                    setHighlightedEdge(EDGE_NONE);
                    beginCaptureAreaDrag(canvasMouseX, canvasMouseY, onMouseMoveDrawCaptureArea);
                }
            }
        }
    }
}
