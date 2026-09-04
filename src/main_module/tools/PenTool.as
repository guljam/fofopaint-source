package main_module.tools
{
    import flash.events.MouseEvent;
    import flash.filters.BlurFilter;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.display.CapsStyle;
    import flash.display.JointStyle;
    import flash.display.LineScaleMode;
    import flash.display.Stage;

    public class PenTool
    {
        private static var _stage:Stage;

        private static const clickPos:Point = new Point(); // 점찍어 줄 때 판단하는 클릭한 자리 저장
        private static const smoothPos:Point = new Point(); // 펜 스무딩에서 커서 뒤에 따라가는 실제 선의 죄표를 저장
        private static const smoothLast:Point = new Point(); // 펜 스무딩에서 현재 마우스 커서 위치를 저장
        private static const moveEventLast:Point = new Point(); // 마우스 move이벤트에서 브러시 크기 필터 해주기 위해 현재 위치 저장
        private static const moveEventDistSave:Point = new Point(); // 마우스 move이벤트에서 브러시 크기 필터 해주기 위해 마지막 위치 저장
        private static const moveEvent2Last:Point = new Point(); // penMove2함수에서 smooth pos를 저장해서 같은 위치면 안그려주기 위해서 마지막 위치를 저장
        private static const sqPenCursorLast:Point = new Point(); // 사각형 커서 각도를 위한 위치저장
        private static const sqLinePosLast:Point = new Point(); // 사각형라인일 때 일정 길이이상 일때만 그려주기 위한 위치
        private static const extendedPos:Point = new Point(); // 사각형라인일 때 양끝점을 약간 확장해주기 위한 위치
        private static const penCommand:Vector.<int> = new Vector.<int>(); // 그냥 펜 명령
        private static const penPoints:Vector.<Number> = new Vector.<Number>(); // 그냥 펜 좌표
        private static const canvasSizeRect:Rectangle = new Rectangle();

        private static var isPenTool:Boolean;

        private static var xSize:uint;

        private static var xColor:uint;

        private static var xAlpha:Number;

        private static var xShape:Boolean;

        private static var xBlendMode:String;

        private static var xAirBrushON:Boolean;

        private static var offsetForSharpline:Number; // 경계선 0.5를 조절해서 번지게 보이느냐 샤프하게 보이느냐
        private static var mouseMovedCount:int; // 마우스 이벤트에서 움직일때 올려주는 카운터 한번에 너무 많이 움직여주면 cpu부하 먹어서 100카운트 마다 bmp에 그려줌
        private static var isMouseMoved:Boolean;

        private static var lastMouseMoveDist:Number; // penmove에서 distlimit이하이면 jump해주는거임, 이동시킬때 이 limit을 dist 만큼 빼줌
        private static var dotflag:Boolean; // 펜스무딩이 강하게 들어갔을때 아주 작은 위치만 그려주면 표현이 제대로 안되기 때문에 너무 작게 선이 그려졌을때 올려주는 플래그
        private static var sq1pxCursor:Boolean = false; // 1픽셀 사각형 커서인경우 올려주고 커서 미리보기 회전적용되게 함

        public static var penAlpha:Number = 1.0;
        public static var penColor:uint = 0x000000;
        public static var penSize:uint = 3;
        public static var penIsSquare:Boolean = false;
        public static var isTransparentPenColor:Boolean = false; // 펜 컬러 투명 켜졌을때 올려줌
        public static var penSizeList:Array = [0, 1, 2, 3, 4, 5, 7, 10, 13, 18, 30, 45, 80];
        public static var penAlphaList:Array = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0];
        public static var penCursorSize:Number = 3;
        public static var penCursorShape:Boolean = false;
        public static var penSizeIndex:uint = 3;
        public static var penAlphaIndex:uint = 9;
        public static var penSmoothValue:Number = 0; // 펜 손떨방 플래그
        public static var penSmoothSlideValue:int = 0; // 펜 손떨방 플래그
        public static var penSmoothSlideTotal:Number = 20; // 손떨방 총 단계
        public static var penListShapeIsSqare:Boolean = false; // 펜 리스트에서 펜 모양 버튼 눌러줄때 툴이랑 상관없이 바꿔줌, 펜 미리보기 할때 필요
        public static var penLastSizeAndShape:Array = [null, null]; // updatePenSizeCursor 중복 사용 방지를 위해서 마지막 크기 저장해놓고 같으면 건너뜀
        public static var eraserSize:uint = 12;
        public static var eraserSizeIndex:uint = 8;
        public static var eraserIsSquare:Boolean = false;
        public static var eraserAlpha:Number = 1.0;
        public static var eraserAlphaIndex:uint = 9;
        public static var isEraserAirBrushON:Boolean = false;

        private static function isCircleRectColliding(cx:Number, cy:Number, r:Number, rx:Number, ry:Number, w:Number, h:Number):Boolean
        {

            const px:Number = Math.max(rx, Math.min(cx, rx + w));

            const py:Number = Math.max(ry, Math.min(cy, ry + h));

            const distance:Number = (Math.sqrt(Math.pow(px - cx, 2) + Math.pow(py - cy, 2)));

            return distance <= r / 2;

        }

        private static function setCanUndoDataFlagON():void
        {

            if (Main._instance.canvasLayer1Bitmap.hitTestPoint(_stage.mouseX, _stage.mouseY, true))
            {

                Main._instance.canAddUndoData = true;

            }

            else if (penCursorShape)
            {

                if (canvasSizeRect.intersects(Main._instance.penSizePreviewCursor.getBounds(Main._instance.canvasPanel)))
                {

                    Main._instance.canAddUndoData = true;

                }

            }

            else if (isCircleRectColliding(Main._instance.canvasPanel.mouseX, Main._instance.canvasPanel.mouseY, penCursorSize, 0, 0, Main._instance.CANVAS_WIDTH, Main._instance.CANVAS_HEIGHT))
            {

                Main._instance.canAddUndoData = true;

            }

        }

        private static function lineStyleReady(shape:Boolean, size:uint, color:uint, alpha:Number):void
        {

            Main._instance.canvasDrawLayer.alpha = alpha;

            if (shape === false)
            {

                Main._instance.canvasDrawLayerChild.graphics.lineStyle(size, color);

            }

            else
            {

                Main._instance.canvasDrawLayerChild.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.BEVEL);

            }

        }

        private static function lineSmoothing():Boolean
        {

            var ox:Number = smoothPos.x;

            var oy:Number = smoothPos.y;

            ox += (smoothLast.x - ox) * penSmoothValue;

            oy += (smoothLast.y - oy) * penSmoothValue;

            handleMouseMove(ox, oy);

            if (Math.abs(smoothLast.x - ox) < 0.02 && Math.abs(smoothLast.y - oy) < 0.02)
            {

                return false;

            }

            else
            {

                smoothPos.setTo(ox, oy);

                FOFOTimer.addByName("lineSmoothingTimer1", 0.02, true, lineSmoothing);

            }

            return true;

        }

        // 끝 부분점을 distance만큼 길게 늘임
        private static function updateExtendEndPoint(x1:Number, y1:Number, x2:Number, y2:Number, distance:Number):void
        {

            // 선분 방향 벡터 계산
            const directionX:Number = x2 - x1;

            const directionY:Number = y2 - y1;

            // 선분 길이 계산
            const length:Number = Math.sqrt(directionX * directionX + directionY * directionY);

            // 선분 방향 벡터 정규화
            const normalizedDirectionX:Number = directionX / length;

            const normalizedDirectionY:Number = directionY / length;

            extendedPos.setTo(x2 + normalizedDirectionX * distance, y2 + normalizedDirectionY * distance);

        }

        private static function handleMouseMove(mx:Number, my:Number):void
        {

            if (Main._instance.canAddUndoData === false)
            {

                setCanUndoDataFlagON();

            }

            const filteredPos:Point = Main._instance.getRefinedPoint(mx, my);

            mx = filteredPos.x + offsetForSharpline;

            my = filteredPos.y + offsetForSharpline;

            if (xShape === true)
            {

                const sx:Number = sqLinePosLast.x - mx;

                const sy:Number = sqLinePosLast.y - my;

                const dist:Number = Math.sqrt(sx * sx + sy * sy);

                if (dist <= 2.5)
                {

                    return;

                }

                else
                {

                    sqLinePosLast.setTo(mx, my);

                }

            }

            if (isMouseMoved === false) // 움직이기 시작할때 linestyle이랑 moveto넣어줌
            {

                isMouseMoved = true;

                Main._instance.canvasDrawLayerChild.graphics.clear();

                lineStyleReady(xShape, xSize, xColor, xAlpha);

                if (xShape)
                {

                    const filteredStartPos:Point = Main._instance.getRefinedPoint(clickPos.x, clickPos.y);

                    filteredStartPos.x = filteredStartPos.x + offsetForSharpline;

                    filteredStartPos.y = filteredStartPos.y + offsetForSharpline;

                    updateExtendEndPoint(mx, my, filteredStartPos.x, filteredStartPos.y, xSize / 8);

                    Main._instance.rDataBuffer.push(["lineStyle5", xShape, xSize, xColor, xAlpha, extendedPos.x, extendedPos.y, xBlendMode, false, Main._instance.isLayer2Selected, Main._instance.airBrushSizeDrawMode]);

                    penPoints.push(extendedPos.x);

                    penPoints.push(extendedPos.y);

                    Main._instance.canvasDrawLayerChild.graphics.moveTo(extendedPos.x, extendedPos.y);

                }

                else
                {

                    Main._instance.rDataBuffer.push(["lineStyle5", xShape, xSize, xColor, xAlpha, smoothPos.x + offsetForSharpline, smoothPos.y + offsetForSharpline, xBlendMode, false, Main._instance.isLayer2Selected, Main._instance.airBrushSizeDrawMode]);

                    penPoints.push(smoothPos.x + offsetForSharpline);

                    penPoints.push(smoothPos.y + offsetForSharpline);

                    Main._instance.canvasDrawLayerChild.graphics.moveTo(smoothPos.x + offsetForSharpline, smoothPos.y + offsetForSharpline);

                }

            }

            if (isMouseMoved)
            {

                if (moveEvent2Last.x === mx && moveEvent2Last.y === my)
                {

                    return;

                }

                Main._instance.rDataBuffer.push(["lineTo", mx, my]);

                penCommand.push(2);

                penPoints.push(mx);

                penPoints.push(my);

                moveEvent2Last.setTo(mx, my);

                Main._instance.canvasDrawLayerChild.graphics.lineTo(mx, my);

                mouseMovedCount++;

                if (mouseMovedCount >= 100)
                {

                    mouseMovedCount = 0;

                    if (Main._instance.airBrushSizeDrawMode > 0)
                    {

                        const blurSize:Number = Main._instance.getBlurSize(Main._instance.airBrushSizeDrawMode, 1.0);

                        Main._instance.canvasDrawLayerChild.filters = [new BlurFilter(blurSize, blurSize, 3)];

                        Main._instance.canvasDrawLayerBitmapData.draw(Main._instance.canvasDrawLayerChild, null, null, "layer");

                        Main._instance.canvasDrawLayerChild.filters = [];

                    }

                    else
                    {

                        Main._instance.canvasDrawLayerBitmapData.draw(Main._instance.canvasDrawLayerChild, null, null, "layer");

                    }

                    Main._instance.canvasDrawLayerBitmap.bitmapData = Main._instance.canvasDrawLayerBitmapData;

                    Main._instance.updateCanvasDrawLayerCliprect();

                    Main._instance.canvasDrawLayerChild.graphics.clear();

                    lineStyleReady(xShape, xSize, xColor, xAlpha);

                    const prevX:Number = penPoints[penPoints.length - 4];

                    const prevY:Number = penPoints[penPoints.length - 3];

                    penCommand.length = 0;

                    penPoints.length = 0;

                    Main._instance.rDataBuffer.push(["tempDone4"]);

                    // TODO: write object를 쓰지 않고 원시 데이터를 써서 리플레이를 빠르고 효율적이게 다시 쓸수있을것같음
                    if (xShape === true)
                    {

                        Main._instance.rDataBuffer.push(["lineStyle5", xShape, xSize, xColor, xAlpha, prevX, prevY, xBlendMode, false, Main._instance.isLayer2Selected, Main._instance.airBrushSizeDrawMode]);

                        penCommand.push(1);

                        penPoints.push(prevX);

                        penPoints.push(prevY);

                        Main._instance.canvasDrawLayerChild.graphics.moveTo(prevX, prevY);

                    }

                    else
                    {

                        Main._instance.rDataBuffer.push(["lineStyle5", xShape, xSize, xColor, xAlpha, mx, my, xBlendMode, false, Main._instance.isLayer2Selected, Main._instance.airBrushSizeDrawMode]);

                        penCommand.push(1);

                        penPoints.push(mx);

                        penPoints.push(my);

                        Main._instance.canvasDrawLayerChild.graphics.moveTo(mx, my);

                    }

                }

                if (xShape === true || sq1pxCursor === true)
                {

                    const rad:Number = Math.atan2(mx - sqPenCursorLast.x, my - sqPenCursorLast.y);

                    const deg:Number = -rad * (180 / Math.PI) + Main._instance.canvasAnchorPoint.rotation;

                    Main._instance.penSizePreviewCursor.rotation = deg;

                    sqPenCursorLast.x = mx;

                    sqPenCursorLast.y = my;

                }

                if (Point.distance(clickPos, moveEvent2Last) >= 0.2)
                {

                    dotflag = false;

                }

            }

        }

        private static function penToolMouseMoveLimit(mx:Number, my:Number):Boolean
        {

            moveEventDistSave.setTo(mx, my);

            const dist:Number = Point.distance(moveEventDistSave, moveEventLast);

            // 브러쉬 크기 제한보다 작게 움직였을때 무시
            // 브러시 크기에 따라서 짧은 선들의 집합으로 그림 사각펜에서 선을 안정화시킴
            if (dist < lastMouseMoveDist)
            {

                lastMouseMoveDist = lastMouseMoveDist - dist;

                if (lastMouseMoveDist <= 0)
                {

                    lastMouseMoveDist = xSize / 5;

                }

                return true;

            }

            lastMouseMoveDist = lastMouseMoveDist - dist;

            if (lastMouseMoveDist <= 0)
            {

                lastMouseMoveDist = xSize / 5;

            }

            moveEventLast.setTo(mx, my);

            return false;

        }

        private static function onMouseMovePenTool(e:MouseEvent):void
        {

            var filteredPos:Point = Main._instance.getRefinedPoint(Main._instance.canvasDrawLayerChild.mouseX, Main._instance.canvasDrawLayerChild.mouseY);

            const mx:Number = filteredPos.x;

            const my:Number = filteredPos.y;

            if (penToolMouseMoveLimit(mx, my))
            {

                return;

            }

            if (isPenTool && penSmoothSlideValue > 1)
            {

                var ox:Number = smoothPos.x;

                var oy:Number = smoothPos.y;

                ox += (smoothLast.x - smoothPos.x) * penSmoothValue;

                oy += (smoothLast.y - smoothPos.y) * penSmoothValue;

                handleMouseMove(ox, oy);

                smoothPos.setTo(ox, oy);

                smoothLast.setTo(mx, my);

                FOFOTimer.addByName("lineSmoothingTimer", 0.03, false, lineSmoothing);

            }

            else
            {

                handleMouseMove(mx, my);

                smoothPos.setTo(mx, my);

            }

        }

        private static function onMouseUpPenTool(e:MouseEvent):void
        {

            _stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpPenTool);

            _stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMovePenTool);

            if (!Main._instance.isRefLayerEmpty() && isPenTool && Main._instance.isRefLayerMemoryTrainingON && Main._instance.refLayerLastAlpha > 0.0)
            {

                Main._instance.setCanvasRefLayerVisibleDelay();

            }

            if (penSmoothSlideValue > 1)
            {

                FOFOTimer.remove("lineSmoothingTimer");

                FOFOTimer.remove("lineSmoothingTimer1");

            }

            if (xShape === true)
            {

                Main._instance.penSizePreviewCursor.rotation = 0;

                if (isMouseMoved === true)
                {

                    const pointLen:uint = penPoints.length;

                    if (pointLen >= 4)
                    {

                        updateExtendEndPoint(penPoints[pointLen - 4], penPoints[pointLen - 3], penPoints[pointLen - 2], penPoints[pointLen - 1], xSize / 8);

                        Main._instance.rDataBuffer.push(["lineTo", extendedPos.x, extendedPos.y]);

                        Main._instance.canvasDrawLayerChild.graphics.lineTo(extendedPos.x, extendedPos.y);

                    }

                }

            }

            if (isMouseMoved === false || (isPenTool && isMouseMoved === true && dotflag))
            {

                Main._instance.rDataBuffer = [];

                Main._instance.rDataBuffer.push(["dot4", xShape, xSize, xColor, xAlpha, clickPos.x, clickPos.y, xBlendMode, Main._instance.isLayer2Selected, Main._instance.airBrushSizeDrawMode, Main._instance.canvasAnchorPoint.rotation]);

                Main._instance.dotTool(xShape, xSize, xColor, clickPos.x, clickPos.y, Main._instance.canvasAnchorPoint.rotation);

                Main._instance.resetCanvasDrawLayerCliprect();

            }

            penCommand.length = 0;

            penPoints.length = 0;

            Main._instance.drawDone();

        }

        public static function init(stage:Stage):void
        {
            _stage = stage;
        }

        public function PenTool():void
        {

        }

        public static function start():void
        {
            execute(true);
        }

        public static function startWithEraserMode():void
        {
            execute(false);
        }

        public static function execute(flag:Boolean):void
        {
            isPenTool = flag;

            if (isPenTool)
            {

                xSize = penSize;

                xAlpha = penAlpha;

                xShape = penIsSquare;

                xAirBrushON = Main._instance.isPenAirBrushON;

                dotflag = true;

                if (isTransparentPenColor)
                {

                    xColor = Main._instance.CANVAS_BG_COLOR;

                    xBlendMode = "erase";

                }

                else
                {

                    xColor = penColor;

                    xBlendMode = null;

                    if (!Main._instance.isCurrentColorSamePickedColor())
                    {

                        Main._instance.updatePickerCurrentColor(Main._instance.colorPickerBox.getRGBInfoBGColor());

                        Main._instance.addColorMyPaletteHistory(Main._instance.colorPickerBox.getRGBInfoBGColor());

                    }

                }

            }

            else
            {

                xSize = eraserSize;

                xColor = Main._instance.CANVAS_BG_COLOR;

                xAlpha = eraserAlpha;

                xShape = eraserIsSquare;

                xBlendMode = "erase";

                xAirBrushON = isEraserAirBrushON;

            }

            if (xSize === 1)
            {

                sq1pxCursor = true;

                xShape = false;

            }

            else
            {

                sq1pxCursor = false;

            }

            if (!Main._instance.isRefLayerEmpty() && flag && Main._instance.isRefLayerMemoryTrainingON)
            {

                Main._instance.setCanvasRefLayerInvisible();

            }

            offsetForSharpline = Main._instance.getSharpLinePosOffset(xSize);

            mouseMovedCount = 0; // 마우스 이벤트에서 움직일때 올려주는 카운터 한번에 너무 많이 움직여주면 cpu부하 먹어서 100카운트 마다 bmp에 그려줌
            isMouseMoved = false;

            canvasSizeRect.width = Main._instance.CANVAS_WIDTH;

            canvasSizeRect.height = Main._instance.CANVAS_HEIGHT;

            Main._instance.resetCanvasDrawLayerCliprect();

            const filteredPos:Point = Main._instance.getRefinedPoint(Main._instance.canvasDrawLayerChild.mouseX, Main._instance.canvasDrawLayerChild.mouseY);

            clickPos.copyFrom(filteredPos); // 점찍어 줄 때 판단하는 클릭한 자리 저장
            smoothPos.copyFrom(filteredPos);

            smoothLast.copyFrom(filteredPos); // penmove할때 마지막x y저장
            moveEventLast.copyFrom(filteredPos);

            if (xShape === true)
            {

                sqPenCursorLast.copyFrom(smoothPos);

                sqLinePosLast.copyFrom(smoothPos);

            }

            lastMouseMoveDist = xSize / 5; // penmove에서 distlimit이하이면 jump해주는거임, 이동시킬때 이 limit을 dist 만큼 빼줌
            if (Main._instance.canAddUndoData === false)
            {

                setCanUndoDataFlagON();

            }

            Main._instance.canvasDrawLayerChild.filters = [];

            _stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMovePenTool);

            _stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpPenTool);
        }
    }
}
