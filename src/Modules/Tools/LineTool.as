package Modules.Tools
{
    import flash.display.BitmapData;
    import flash.display.CapsStyle;
    import flash.display.JointStyle;
    import flash.display.LineScaleMode;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import Modules.CanvasController;
    import Modules.ColorPickerController;
    import Modules.MainUI;
    import Modules.PaletteController;
    import Modules.ReferenceLayerController;
    import Modules.ReplayController;
    import Modules.ToolController;
    import Modules.UndoManager;

    public class LineTool
    {
        public static var main:Main;

        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static const toDeg:Number = 180 / Math.PI;
        // const oldPoint:Point = new Point(0,0);
        private static var oldX:Number;
        private static var oldY:Number;
        private static var startPoint:Point = new Point();
        private static var endPoint:Point = new Point();
        private static var canvasSizeWidth:Number;
        private static var canvasSizeHeight:Number;
        private static var xSize:uint;
        private static var xColor:uint;
        private static var xAlpha:Number;
        private static var xShape:Boolean;
        private static var xBlendMode:String;
        private static var xAirBrushON:Boolean;
        private static var mouseMovedFlag:Boolean;
        private static var subLayerFlag:Boolean;

        private static function isTwoLineIntersection(x1:Number, y1:Number, x2:Number, y2:Number, x3:Number, y3:Number, x4:Number, y4:Number):Boolean
        {
            var denominator:Number = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1);
            var numerator1:Number = (x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3);
            var numerator2:Number = (x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3);
            if (denominator == 0)
            {
                // 두 선분이 평행하거나 일치함
                return false;
            }
            var t1:Number = numerator1 / denominator;
            var t2:Number = numerator2 / denominator;
            if (t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1)
            {
                // 두 선분이 교차함
                return true;
            }
            else
            {
                // 두 선분이 교차하지 않음
                return false;
            }
        }

        // 중앙선+양옆선 3개의 선이 캔버스 4개의 선과 하나라도 닿으면 true를 반환함
        private static function isLineInsideCanvas():Boolean
        {
            if (CanvasController.canvasPanel.hitTestPoint(main.stage.mouseX, main.stage.mouseY, true))
            {
                return true;
            }
            else
            {
                const sideLine1:Array = getSideLine(startPoint.x, startPoint.y, endPoint.x, endPoint.y, xSize / 2, xShape);
                const sideLine2:Array = getSideLine(startPoint.x, startPoint.y, endPoint.x, endPoint.y, -xSize / 2, xShape);
                if (checkCollision(startPoint.x, startPoint.y, endPoint.x, endPoint.y)
                    || checkCollision(sideLine1[0], sideLine1[1], sideLine1[2], sideLine1[3])
                    || checkCollision(sideLine2[0], sideLine2[1], sideLine2[2], sideLine2[3]))
                {
                    return true;
                }
            }
            return false;
        }

        private static function checkCollision(x1:Number, y1:Number, x2:Number, y2:Number):Boolean
        {
            return isTwoLineIntersection(x1, y1, x2, y2, 0, 0, canvasSizeWidth, 0)
                || isTwoLineIntersection(x1, y1, x2, y2, 0, 0, 0, canvasSizeHeight)
                || isTwoLineIntersection(x1, y1, x2, y2, 0, canvasSizeHeight, canvasSizeWidth, canvasSizeHeight)
                || isTwoLineIntersection(x1, y1, x2, y2, canvasSizeWidth, 0, canvasSizeWidth, canvasSizeHeight);
        }

        private static function getSideLine(x1:Number, y1:Number, x2:Number, y2:Number, distance:Number, squareCapFlag:Boolean):Array
        {
            // 길이를 약간 늘려줌
            if (!squareCapFlag)
            {
                const pointVec:Array = extendLineSegment(x1, y1, x2, y2, Math.abs(distance));
                x1 = pointVec[0];
                y1 = pointVec[1];
                x2 = pointVec[2];
                y2 = pointVec[3];
            }
            // 선분의 방향 벡터
            var directionX:Number = x2 - x1;
            var directionY:Number = y2 - y1;
            // 선분의 방향 벡터를 정규화
            var magnitude:Number = Math.sqrt(directionX * directionX + directionY * directionY);
            var normalizedDirectionX:Number = directionX / magnitude;
            var normalizedDirectionY:Number = directionY / magnitude;
            var newDirectionX:Number = -normalizedDirectionY;
            var newDirectionY:Number = normalizedDirectionX;
            // 새로운 선분의 시작점과 끝점을 계산
            var newLineStartX:Number = x1 + distance * newDirectionX;
            var newLineStartY:Number = y1 + distance * newDirectionY;
            var newLineEndX:Number = x2 + distance * newDirectionX;
            var newLineEndY:Number = y2 + distance * newDirectionY;
            return [newLineStartX, newLineStartY, newLineEndX, newLineEndY];
        }

        // 선분 시작 끝점을 distance로 늘려서 좌표를 반환함
        private static function extendLineSegment(x1:Number, y1:Number, x2:Number, y2:Number, distance:Number):Array
        {
            // 선분의 방향 벡터 계산
            var directionX:Number = x2 - x1;
            var directionY:Number = y2 - y1;
            // 방향 벡터의 길이 계산
            var length:Number = Math.sqrt(directionX * directionX + directionY * directionY);
            // 방향 벡터를 정규화
            directionX /= length;
            directionY /= length;
            // 양 끝점 좌표 이동
            var extendedX1:Number = x1 - directionX * distance;
            var extendedY1:Number = y1 - directionY * distance;
            var extendedX2:Number = x2 + directionX * distance;
            var extendedY2:Number = y2 + directionY * distance;
            return [extendedX1, extendedY1, extendedX2, extendedY2];
        }

        private static function showDgreeHint():void
        {
            const ang:Number = Math.atan2(oldX - CanvasController.canvasDrawLayerChild.mouseX, oldY - CanvasController.canvasDrawLayerChild.mouseY);
            var deg:Number = ang * toDeg + 90;
            if (deg > 180)
            {
                deg = deg - 90;
            }
            var degstr:String = Math.abs(deg % 90).toFixed(1) + "°";
            MainUI.showMouseHint(degstr);
        }

        private static function drawLine():void // 지우개인가 펜인가 구분해서 lineto 실시
        {
            CanvasController.canvasDrawLayerChild.graphics.clear();
            CanvasController.canvasDrawLayer.alpha = xAlpha;
            if (xShape)
            {
                CanvasController.canvasDrawLayerChild.graphics.lineStyle(xSize, xColor, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND);
            }
            else
            {
                CanvasController.canvasDrawLayerChild.graphics.lineStyle(xSize, xColor);
            }
            CanvasController.canvasDrawLayerChild.graphics.moveTo(startPoint.x, startPoint.y);
            CanvasController.canvasDrawLayerChild.graphics.lineTo(endPoint.x, endPoint.y);
        }

        private static function onMouseMoveLineTool(e:MouseEvent):void
        {
            if (!mouseMovedFlag)
            {
                mouseMovedFlag = true;
            }
            const mx:Number = CanvasController.canvasDrawLayerChild.mouseX;
            const my:Number = CanvasController.canvasDrawLayerChild.mouseY;
            if (xShape === true)
            {
                const extPoints:Array = extendLineSegment(oldX, oldY, mx, my, xSize / 8);
                startPoint.setTo(extPoints[0], extPoints[1]);
                endPoint.setTo(extPoints[2], extPoints[3]);
            }
            else
            {
                startPoint.setTo(oldX, oldY);
                endPoint.setTo(mx, my);
            }
            drawLine();
            showDgreeHint();
        }

        private static function onMouseUpLineTool(e:MouseEvent):void
        {
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveLineTool);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpLineTool);
            CanvasController.isPenSizeCursorInvisible = false;
            if (!ReferenceLayerController.isRefLayerEmpty() && ReferenceLayerController.isRefLayerMemoryTrainingON && ReferenceLayerController.refLayerLastAlpha > 0.0)
            {
                ReferenceLayerController.setCanvasRefLayerVisibleDelay();
            }
            CanvasController.isMouseDragging = false;
            MainUI.hideMouseHint();
            if (isLineInsideCanvas() === true)
            {
                const mx:Number = CanvasController.canvasDrawLayerChild.mouseX;
                const my:Number = CanvasController.canvasDrawLayerChild.mouseY;
                UndoManager.canAddUndoData = true;
                if (mouseMovedFlag === false && oldX === mx && oldY === my)
                {
                    ReplayController.rDataBuffer = [];
                    ReplayController.rDataBuffer.push(["dot4", xShape, xSize, xColor, xAlpha, mx, my, xBlendMode, subLayerFlag, xAirBrushON, CanvasController.canvasAnchorPoint.rotation]);
                    DotTool.start(xShape, xSize, xColor, mx, my, CanvasController.canvasAnchorPoint.rotation);
                }
                else
                {
                    if (xShape === true)
                    {
                        const extPoints:Array = extendLineSegment(oldX, oldY, mx, my, xSize / 8);
                        startPoint.setTo(extPoints[0], extPoints[1]);
                        endPoint.setTo(extPoints[2], extPoints[3]);
                    }
                    else
                    {
                        startPoint.setTo(oldX, oldY);
                        endPoint.setTo(mx, my);
                    }
                    ReplayController.rDataBuffer.push(["line3", xShape, xSize, xColor, xAlpha, startPoint.x, startPoint.y, endPoint.x, endPoint.y, xBlendMode, subLayerFlag, PenTool.airBrushSizeDrawMode]);
                    drawLine();
                }
            }
            CanvasController.resetCanvasDrawLayerCliprect();
            DrawingFinish.run();
        }

        public static function start():void
        {
            CanvasController.isPenSizeCursorInvisible = true;
            xSize = PenTool.penSize;
            xAlpha = PenTool.penAlpha;
            xShape = PenTool.penIsSquare;
            xAirBrushON = ToolController.isPenAirBrushON;
            if (PenTool.isTransparentPenColor)
            {
                xColor = CanvasController.CANVAS_BG_COLOR;
                xBlendMode = "erase";
            }
            else
            {
                xColor = PenTool.penColor;
                xBlendMode = null;
                if (!ColorPickerController.isCurrentColorSamePickedColor())
                {
                    ColorPickerController.updatePickerCurrentColor(ColorPickerController.colorPickerBox.getRGBInfoBGColor());
                    PaletteController.addColorMyPaletteHistory(ColorPickerController.colorPickerBox.getRGBInfoBGColor());
                }
            }
            canvasSizeWidth = CanvasController.CANVAS_WIDTH;
            canvasSizeHeight = CanvasController.CANVAS_HEIGHT;
            mouseMovedFlag = false;
            oldX = CanvasController.canvasDrawLayerChild.mouseX;
            oldY = CanvasController.canvasDrawLayerChild.mouseY;
            subLayerFlag = CanvasController.isLayer2Selected;
            if (!ReferenceLayerController.isRefLayerEmpty() && ReferenceLayerController.isRefLayerMemoryTrainingON)
            {
                ReferenceLayerController.setCanvasRefLayerInvisible();
            }
            // 캔버스2번 지워주고, draw판넬 데이터도 지워줌
            CanvasController.canvasDrawLayerBitmapData.dispose();
            CanvasController.canvasDrawLayerBitmap.bitmapData = null;
            CanvasController.canvasDrawLayerBitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
            // 선 관련 이벤트 함수 붙여줌
            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveLineTool);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpLineTool);
        }
    }
}
