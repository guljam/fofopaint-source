package Modules.CaptureEngine
{
    import Modules.InputPriority;
    import Modules.MainUI;
    import Modules.CanvasController;
    import flash.display.CapsStyle;
    import flash.display.LineScaleMode;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.ReplayEngine.ReplayState;

    public class CaptureArea
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static var captureDragAreaOverlay:Shape = new Shape(); // 스크린샷 박스 미리보기 그려줌
        private static var xPanel:Sprite;
        private static var mouseMoved:Boolean = false;
        private static var canvasWidth:Number = 0;
        private static var canvasHeight:Number = 0;
        private static var clickPos:Point = new Point(0, 0);
        private static const rectFull:Rectangle = new Rectangle();
        private static const rectRaw:Rectangle = new Rectangle(); // 새 영역 그리기 드래그 전용
        private static const rectClamped:Rectangle = new Rectangle();
        private static const moveStartRect:Rectangle = new Rectangle(); // 영역 이동 드래그 시작 시점의 영역
        private static var minSize:Number = 10.0;
        private static const mouseMoveThreshold:Number = 5.0;

        // 영역 변(테두리) 개별 크기 조정. 마우스 좌표는 xPanel 지역 좌표(캔버스 좌표)라 회전/대칭과 무관
        private static const EDGE_NONE:int = -1;
        private static const EDGE_TOP:int = 0;
        private static const EDGE_BOTTOM:int = 1;
        private static const EDGE_LEFT:int = 2;
        private static const EDGE_RIGHT:int = 3;
        private static const edgeHitPx:Number = 8.0; // 테두리 기준 +-8px(화면 px)에서 클릭 반응
        private static const edgeHighlightPx:Number = 2.0; // 호버/드래그 중인 변 강조선 굵기(화면 px)
        private static var highlightEdge:int = EDGE_NONE;
        private static var activeEdge:int = EDGE_NONE;
        private static var dragEdgeStartValue:Number = 0;
        private static var isDragging:Boolean = false;

        private static function validateCaptureArea():void
        {
            var intersection:Rectangle = rectFull.intersection(rectClamped);
            if (intersection.width >= minSize && intersection.height >= minSize)
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
        private static function getEdgeValue(edge:int):Number
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

        // 위/왼쪽 변은 시작점, 아래/오른쪽 변은 끝점을 움직임. 반대 변과 minSize 이상 유지, 캔버스 안으로 제한
        private static function setEdge(edge:int, value:Number):void
        {
            const vertical:Boolean = (edge === EDGE_TOP || edge === EDGE_BOTTOM);
            const isStartEdge:Boolean = (edge === EDGE_TOP || edge === EDGE_LEFT);
            const start:Number = (vertical) ? rectClamped.y : rectClamped.x;
            const end:Number = start + ((vertical) ? rectClamped.height : rectClamped.width);
            const limit:Number = (vertical) ? canvasHeight : canvasWidth;
            var newStart:Number = start;
            var newEnd:Number = end;

            if (isStartEdge)
            {
                newStart = Math.max(0, Math.min(end - minSize, Math.round(value)));
            }
            else
            {
                newEnd = Math.max(start + minSize, Math.min(limit, Math.round(value)));
            }

            if (vertical)
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
        private static function hitEdge(mx:Number, my:Number):int
        {
            const band:Number = edgeHitPx / getCanvasScale();
            const left:Number = rectClamped.x;
            const right:Number = rectClamped.x + rectClamped.width;
            const top:Number = rectClamped.y;
            const bottom:Number = rectClamped.y + rectClamped.height;
            const inX:Boolean = (mx >= left - band && mx <= right + band);
            const inY:Boolean = (my >= top - band && my <= bottom + band);

            if (inX && Math.abs(my - top) <= band)
                return EDGE_TOP;
            if (inX && Math.abs(my - bottom) <= band)
                return EDGE_BOTTOM;
            if (inY && Math.abs(mx - left) <= band)
                return EDGE_LEFT;
            if (inY && Math.abs(mx - right) <= band)
                return EDGE_RIGHT;

            return EDGE_NONE;
        }

        private static function getHoverEdge():int
        {
            if (!xPanel || isFullImageCapture())
            {
                return EDGE_NONE;
            }

            if (MainUI.topBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY) || CaptureStamp.captureStampFontListBox.visible)
            {
                return EDGE_NONE;
            }

            return hitEdge(xPanel.mouseX, xPanel.mouseY);
        }

        private static function setHighlightEdge(edge:int):void
        {
            if (highlightEdge === edge)
            {
                return;
            }

            highlightEdge = edge;
            drawArea();
        }

        private static function onMouseMoveHover(e:MouseEvent):void
        {
            if (!CaptureController.isCaptureModeON || isDragging)
            {
                return;
            }

            setHighlightEdge(getHoverEdge());
        }

        public static function startHoverTracking():void
        {
            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHover);
        }

        public static function stopHoverTracking():void
        {
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHover);
            highlightEdge = EDGE_NONE;
        }

        private static function onMouseMoveEdge(e:MouseEvent):void
        {
            if (!CaptureController.isCaptureModeON)
            {
                removeCaptureAreaEvents();
                return;
            }

            const vertical:Boolean = (activeEdge === EDGE_TOP || activeEdge === EDGE_BOTTOM);
            const sub:Number = (vertical) ? xPanel.mouseY - clickPos.y : xPanel.mouseX - clickPos.x;
            const before:Number = getEdgeValue(activeEdge);

            setEdge(activeEdge, dragEdgeStartValue + Math.round(sub));

            if (getEdgeValue(activeEdge) === before)
            {
                return;
            }

            if (!mouseMoved)
            {
                mouseMoved = true;
                CaptureController.onCaptureAreaDragStarted();
            }

            MainUI.showBottomHint(getRotatedRectSizeString());
            drawArea();
        }

        // 영역 이동: 드래그 시작 시점 위치 + 마우스 이동량으로 매번 새로 계산(누적 안 함)
        private static function onMouseMoveAreaMove(e:MouseEvent):void
        {
            if (!CaptureController.isCaptureModeON)
            {
                removeCaptureAreaEvents();
                return;
            }

            const subX:Number = Math.round(xPanel.mouseX - clickPos.x);
            const subY:Number = Math.round(xPanel.mouseY - clickPos.y);

            if (!mouseMoved)
            {
                if (Math.abs(subX) < mouseMoveThreshold && Math.abs(subY) < mouseMoveThreshold)
                {
                    return;
                }

                mouseMoved = true;
                CaptureController.onCaptureAreaDragStarted();
            }

            rectClamped.x = Math.round(Math.max(0, Math.min(canvasWidth - rectClamped.width, moveStartRect.x + subX)));
            rectClamped.y = Math.round(Math.max(0, Math.min(canvasHeight - rectClamped.height, moveStartRect.y + subY)));
            drawArea();
        }

        private static function onMouseMoveDrawCaptureArea(e:MouseEvent):void
        {
            if (!CaptureController.isCaptureModeON)
            {
                removeCaptureAreaEvents();
                return;
            }

            var mx:Number = xPanel.mouseX;
            var my:Number = xPanel.mouseY;
            var subX:Number = Math.round(mx - clickPos.x);
            var subY:Number = Math.round(my - clickPos.y);

            if (mouseMoved)
            {
                rectRaw.width = subX;
                rectRaw.height = subY;
                rectClamped.x = rectRaw.x;
                rectClamped.y = rectRaw.y;
                rectClamped.width = rectRaw.width;
                rectClamped.height = rectRaw.height;
                normalizeRectClamped();
                MainUI.showBottomHint(getRotatedRectSizeString());
                drawArea();
            }
            else if (Math.abs(subX) >= mouseMoveThreshold || Math.abs(subY) >= mouseMoveThreshold)
            {
                rectRaw.x = clickPos.x;
                rectRaw.y = clickPos.y;
                rectRaw.width = subX;
                rectRaw.height = subY;
                rectClamped.x = rectRaw.x;
                rectClamped.y = rectRaw.y;
                rectClamped.width = rectRaw.width;
                rectClamped.height = rectRaw.height;
                MainUI.showBottomHint(getRotatedRectSizeString());
                mouseMoved = true;
                CaptureController.onCaptureAreaDragStarted();
            }
        }

        private static function onMouseUpCaptureArea(e:MouseEvent):void
        {
            CanvasController.isMouseDragging = false;
            removeCaptureAreaEvents();

            if (mouseMoved === true)
            {
                // rect길이가 음수인경우 cx cy를 양수로 다시 맞추어줌
                normalizeRectClamped();
                validateCaptureArea();
                MainUI.topBar.capClipBoard.alpha = 1.0;
                drawArea();
                CaptureController.onCaptureAreaChanged();
            }

            mouseMoved = false;
            isDragging = false;
            activeEdge = EDGE_NONE;
            setHighlightEdge(getHoverEdge());
        }

        private static function removeCaptureAreaEvents():void
        {
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveDrawCaptureArea);
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveAreaMove);
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveEdge);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpCaptureArea);
        }

        public static function updateDrawArea(forceFlag:Boolean = false):void
        {
            if ((rectClamped.width >= minSize && rectClamped.height >= minSize) || forceFlag)
            {
                if (!isDragging)
                {
                    highlightEdge = getHoverEdge();
                }
                drawArea();
            }
            CaptureController.onCaptureAreaChanged();
        }

        private static function getCanvasScale():Number
        {
            return (ReplayState.isReplayModeON) ? Math.abs(ReplayDrawer.rCanvasAnchorPoint.scaleX) : Math.abs(CanvasController.canvasAnchorPoint.scaleX);
        }

        private static function drawArea():void
        {
            const zoomed:Number = getCanvasScale();
            const lineSize:Number = Math.ceil(1 / zoomed);

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

            if (highlightEdge !== EDGE_NONE && !isFullImageCapture())
            {
                const left:Number = rectClamped.x;
                const right:Number = rectClamped.x + rectClamped.width;
                const top:Number = rectClamped.y;
                const bottom:Number = rectClamped.y + rectClamped.height;

                captureDragAreaOverlay.graphics.lineStyle(edgeHighlightPx / zoomed, 0xFF6600, 1.0, true, LineScaleMode.NORMAL, CapsStyle.NONE);

                switch (highlightEdge)
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

            if (w < minSize || h < minSize)
            {
                return "";
            }

            return !CaptureController.isCaptureAxisSwapped() ? w + " x " + h : h + " x " + w;
        }

        private static function clearAreaState():void
        {
            clickPos.setTo(0, 0);
            rectClamped.setTo(0, 0, 0, 0);
            rectRaw.setTo(0, 0, 0, 0);
            rectFull.setTo(0, 0, 0, 0);
            highlightEdge = EDGE_NONE;
            activeEdge = EDGE_NONE;
        }

        public static function resetCaptureArea():void
        {
            clearAreaState();
            captureDragAreaOverlay.graphics.clear();
            MainUI.topBar.capClipBoard.alpha = 1.0;
            CaptureController.onCaptureAreaChanged();
        }

        public static function reset():void
        {
            clearAreaState();
            canvasWidth = 0;
            canvasHeight = 0;
            xPanel = null;
            mouseMoved = false;
            isDragging = false;
            MainUI.topBar.capClipBoard.alpha = 1.0;
        }

        public static function isFullImageCapture():Boolean
        {
            return rectClamped.width === 0.0 || rectClamped.height === 0.0;
        }

        public static function getCaptureArea():Rectangle
        {
            return rectClamped;
        }

        public static function isCursorInCaptureDrea():Boolean
        {
            if (!xPanel)
            {
                return false;
            }
            return rectClamped.contains(xPanel.mouseX, xPanel.mouseY);
        }

        private static function beginDrag(mx:Number, my:Number, moveListener:Function):void
        {
            CanvasController.isMouseDragging = true;
            isDragging = true;
            mouseMoved = false;
            clickPos.setTo(mx, my);
            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, moveListener);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpCaptureArea, false, InputPriority.DEFAULT);
        }

        public static function start():void
        {
            if (MainUI.topBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
            {
                if (ReplayState.isReplayModeON) // 리플레이 변수로 변경
                {
                    canvasWidth = ReplayState.RCANVAS_WIDTH;
                    canvasHeight = ReplayState.RCANVAS_HEIGHT;
                    xPanel = ReplayDrawer.rCanvasPanel;
                }
                else
                {
                    canvasWidth = CanvasController.CANVAS_WIDTH;
                    canvasHeight = CanvasController.CANVAS_HEIGHT;
                    xPanel = CanvasController.canvasPanel;
                }

                const mx:Number = xPanel.mouseX;
                const my:Number = xPanel.mouseY;

                rectFull.setTo(0, 0, canvasWidth, canvasHeight);

                const hasCaptureArea:Boolean = !isFullImageCapture();
                const edge:int = (hasCaptureArea) ? hitEdge(mx, my) : EDGE_NONE;

                if (edge !== EDGE_NONE)
                {
                    activeEdge = edge;
                    highlightEdge = edge;
                    dragEdgeStartValue = getEdgeValue(edge);
                    beginDrag(mx, my, onMouseMoveEdge);
                }
                else if (hasCaptureArea && isCursorInCaptureDrea())
                {
                    moveStartRect.copyFrom(rectClamped);
                    setHighlightEdge(EDGE_NONE);
                    beginDrag(mx, my, onMouseMoveAreaMove);
                }
                else
                {
                    setHighlightEdge(EDGE_NONE);
                    beginDrag(mx, my, onMouseMoveDrawCaptureArea);
                }
            }
        }
    }
}
