package Modules.L3Feature.Tools
{
    import Modules.DrawEngine.StrokeBuffer;
    import Modules.InputPriority;
    import Modules.ReferenceLayerController;
    import Modules.ReplayEngine.ReplayState;

    import flash.display.CapsStyle;
    import flash.display.JointStyle;
    import flash.display.LineScaleMode;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.utils.getTimer;
    import Modules.L4UI.ColorPickerController;
    import Modules.L1Data.KeyState;
    import Modules.L4UI.PaletteController;
    import Modules.L3Feature.DrawingFinish;
    import Modules.L1Data.Tools.PenSettings;
    import Modules.L4UI.PenSizePreviewCursor;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L2Engine.DrawEngine.CanvasLayers;
    import Modules.L1Data.ColorHistory;
    import Modules.L2Engine.UndoHistory;

    // 층: L3 기능 - 직선 그리기
    public class LineTool
    {
        public static var main:Main;

        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static const toDeg:Number = 180 / Math.PI;
        // const oldPoint:Point = new Point(0,0);
        private static var canvasWidth:Number = 0;
        private static var canvasHeight:Number = 0;
        private static var oldX:Number;
        private static var oldY:Number;
        private static var xSize:uint;
        private static var xColor:uint;
        private static var xAlpha:Number;
        private static var xShape:Boolean;
        private static var xBlendMode:String;
        private static var toolStartStamp:int = 0; // 선 도구를 시작한 getTimer 값, 적용할때 타이밍 시트에 연출 시간으로 기록함
        private static var pointStamps:Array = []; // 꼭짓점마다 찍은 getTimer 값 (첫 점은 도구 시작), 재생에서 점 순서대로 선을 그리는 연출에 씀
        private static var subLayerFlag:Boolean;
        private static var command:Vector.<int> = new Vector.<int>();
        private static var data:Vector.<Number> = new Vector.<Number>();
        private static var _isStarted:Boolean = false;
        private static var startFromShortCut:Boolean = false;
        private static var hasLineTouchedCanvas:Boolean = false;
        private static var lastClickedPos:Point = new Point(0, 0);

        private static function thickLineTouchesCanvasBorder(x1:Number, y1:Number, x2:Number, y2:Number, thickness:Number, roundCaps:Boolean):Boolean
        {
            const w:Number = canvasWidth;
            const h:Number = canvasHeight;
            const r:Number = thickness > 0 ? thickness * 0.5 : 0;

            const minX:Number = x1 < x2 ? x1 : x2;
            const maxX:Number = x1 > x2 ? x1 : x2;
            const minY:Number = y1 < y2 ? y1 : y2;
            const maxY:Number = y1 > y2 ? y1 : y2;

            // 굵은 선 전체가 캔버스 밖 또는 안에 있으면 즉시 판정한다.
            if (maxX + r < 0 || minX - r > w ||
                    maxY + r < 0 || minY - r > h)
                return false;

            if (minX - r > 0 && maxX + r < w &&
                    minY - r > 0 && maxY + r < h)
                return false;

            const dx:Number = x2 - x1;
            const dy:Number = y2 - y1;
            const lengthSquared:Number = dx * dx + dy * dy;

            if (lengthSquared == 0)
                return roundCaps &&
                    diskTouchesCanvasBorder(x1, y1, r * r, w, h);

            const length:Number = Math.sqrt(lengthSquared);
            const ux:Number = dx / length;
            const uy:Number = dy / length;
            const ax:Number = Math.abs(ux);
            const ay:Number = Math.abs(uy);

            const midX:Number = (x1 + x2) * 0.5;
            const midY:Number = (y1 + y2) * 0.5;
            const halfLength:Number = length * 0.5;

            // 선분의 직사각형 부분을 캔버스와 SAT로 교차 검사한다.
            const extentX:Number = halfLength * ax + r * ay;
            const extentY:Number = halfLength * ay + r * ax;

            const stripInside:Boolean =
                midX - extentX > 0 && midX + extentX < w &&
                midY - extentY > 0 && midY + extentY < h;

            if (!stripInside)
            {
                const halfW:Number = w * 0.5;
                const halfH:Number = h * 0.5;
                const offsetX:Number = midX - halfW;
                const offsetY:Number = midY - halfH;

                if (Math.abs(offsetX) <= halfW + extentX &&
                        Math.abs(offsetY) <= halfH + extentY &&
                        Math.abs(offsetX * ux + offsetY * uy) <=
                        halfLength + halfW * ax + halfH * ay &&
                        Math.abs(-offsetX * uy + offsetY * ux) <=
                        r + halfW * ay + halfH * ax)
                {
                    return true;
                }
            }

            // 둥근 끝의 원형 부분을 검사한다.
            return roundCaps &&
                (diskTouchesCanvasBorder(x1, y1, r * r, w, h) ||
                    diskTouchesCanvasBorder(x2, y2, r * r, w, h));
        }

        private static function diskTouchesCanvasBorder(x:Number, y:Number, radiusSquared:Number, w:Number, h:Number):Boolean
        {
            const outsideY:Number = y < 0 ? -y : (y > h ? y - h : 0);
            if (x * x + outsideY * outsideY <= radiusSquared ||
                    (x - w) * (x - w) + outsideY * outsideY <= radiusSquared)
                return true;

            const outsideX:Number = x < 0 ? -x : (x > w ? x - w : 0);
            return y * y + outsideX * outsideX <= radiusSquared ||
                (y - h) * (y - h) + outsideX * outsideX <= radiusSquared;
        }

        public static function removeEventsAndResetVar():void
        {
            FOFOTimer.remove("updateLineToolTimer");
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownLineTool);
            main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownLineTool);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownLineTool);

            if (startFromShortCut)
            {
                startFromShortCut = false;
                main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpLineTool);
            }

            command = new Vector.<int>();
            data = new Vector.<Number>();
            hasLineTouchedCanvas = false;
            _isStarted = false;

            PenSizePreviewCursor.setCursorInVisibleFlag(false);

            ReferenceLayerController.hideMemoryTrainingMask();
        }

        public static function cancel():void
        {
            removeEventsAndResetVar();
            StrokeBuffer.canvasDrawLayerChild.graphics.clear();
        }

        public static function get isStarted():Boolean
        {
            return _isStarted;
        }

        public static function removeLastLineToData():void
        {
            command.pop();
            data.pop();
            data.pop();
        }

        public static function updateLastLineToData(posX:Number, posY:Number):void
        {
            if (command.length < 2)
            {
                return;
            }

            command[command.length - 1] = 2;
            data[data.length - 2] = posX;
            data[data.length - 1] = posY;
        }

        public static function isSamePos(posX:Number, posY:Number):Boolean
        {
            if (lastClickedPos.x === posX && lastClickedPos.y === posY)
            {
                return true;
            }
            return false;
        }

        public static function inputLineToData(posX:Number, posY:Number):void
        {
            lastClickedPos.setTo(posX, posY);
            data[data.length - 2] = posX;
            data[data.length - 1] = posY;

            command.push(2);
            data.push(posX);
            data.push(posY);
        }

        public static function inputMoveToData(posX:Number, posY:Number):void
        {
            command.push(1);
            data.push(posX);
            data.push(posY);
        }

        private static function drawLine():void // 지우개인가 펜인가 구분해서 lineto 실시
        {
            if (command.length < 2)
            {
                return;
            }

            StrokeBuffer.canvasDrawLayerChild.graphics.clear();
            StrokeBuffer.canvasDrawLayer.alpha = xAlpha;

            if (xShape)
            {
                StrokeBuffer.canvasDrawLayerChild.graphics.lineStyle(xSize, xColor, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND);
            }
            else
            {
                StrokeBuffer.canvasDrawLayerChild.graphics.lineStyle(xSize, xColor);
            }

            StrokeBuffer.canvasDrawLayerChild.graphics.drawPath(command, data);
        }

        private static function updateLinePreview():void
        {
            const mx:Number = StrokeBuffer.canvasDrawLayerChild.mouseX;
            const my:Number = StrokeBuffer.canvasDrawLayerChild.mouseY;

            updateLastLineToData(mx, my);
            drawLine();
        }

        private static function apply():void
        {
            if (hasLineTouchedCanvas && command.length > 2)
            {
                removeLastLineToData();
                drawLine();
                hasLineTouchedCanvas = false;
                UndoHistory.canAddUndoData = true;
                ReplayState.rMemoryDataBuffer.push(ReplayState.stampTimingSheetToolCommand(["line4", xShape, xSize, xColor, xAlpha, command.concat(), data.concat(), xBlendMode, subLayerFlag, PenSettings.airBrushSizeDrawMode], toolStartStamp, pointStamps));
            }

            StrokeBuffer.resetCanvasDrawLayerClipRect();
            DrawingFinish.run();
            removeEventsAndResetVar();
            PenSizePreviewCursor.updatePosAndVisibility(); // 라인툴 중 숨겼던 커서를 되돌린 뒤
            PenSizePreviewCursor.checkColorNow(); // 확정된 라인이 레이어에 반영된 뒤 커서 색 확인
        }

        private static function onKeyDownLineTool(e:KeyboardEvent):void
        {
            if (KeyState.isPressedKey(KeyState.KEY.enter) || KeyState.isPressedKey(KeyState.KEY.esc))
            {
                apply();
            }
        }

        private static function onKeyUpLineTool(e:KeyboardEvent):void
        {
            if (e.keyCode === KeyState.KEY.shift)
            {
                apply();
            }
        }

        private static function onRightMouseDownLineTool(e:MouseEvent):void
        {
            apply();
        }

        private static function onMouseDownLineTool(e:MouseEvent):void
        {
            const mx:Number = StrokeBuffer.canvasDrawLayerChild.mouseX;
            const my:Number = StrokeBuffer.canvasDrawLayerChild.mouseY;

            if (!isSamePos(mx, my))
            {
                if (hasLineTouchedCanvas === false)
                {
                    if (checkPointInsideCanvas(mx, my) || thickLineTouchesCanvasBorder(mx, my, data[data.length - 4], data[data.length - 3], xSize, !xShape))
                    {
                        hasLineTouchedCanvas = true;
                    }
                }
                inputLineToData(mx, my);
                pointStamps.push(getTimer()); // 점을 찍은 시각 (적용할때 임시로 따라다니던 마지막 점은 지워지므로 찍은 점 수와 맞음)
            }
        }

        private static function checkPointInsideCanvas(mx:Number, my:Number):Boolean
        {
            if (mx >= 0 && mx <= canvasWidth && my >= 0 && my <= canvasHeight)
            {
                return true;
            }
            return false;
        }

        public static function start():void
        {
            if (_isStarted === false)
            {
                _isStarted = true;
                PenSizePreviewCursor.setCursorInVisibleFlag(true);

                canvasWidth = DrawCanvas.CANVAS_WIDTH;
                canvasHeight = DrawCanvas.CANVAS_HEIGHT;
                xSize = PenSettings.penSize;
                xAlpha = PenSettings.penAlpha;
                xShape = PenSettings.penIsSquare;

                if (PenTool.isTransparentPenColor)
                {
                    xColor = DrawCanvas.CANVAS_BG_COLOR;
                    xBlendMode = "erase";
                }
                else
                {
                    xColor = PenTool.penColor;
                    xBlendMode = null;
                    if (!ColorPickerController.isCurrentColorSamePickedColor())
                    {
                        ColorPickerController.updatePickerCurrentColor(ColorPickerController.colorPickerBox.getRGBInfoBGColor());
                        ColorHistory.add(ColorPickerController.colorPickerBox.getRGBInfoBGColor());
                    }
                }

                command = new Vector.<int>();
                data = new Vector.<Number>();

                const mx:Number = StrokeBuffer.canvasDrawLayerChild.mouseX;
                const my:Number = StrokeBuffer.canvasDrawLayerChild.mouseY;

                toolStartStamp = getTimer();
                pointStamps = [toolStartStamp]; // 첫 점은 도구를 시작한 때
                inputMoveToData(mx, my);
                inputLineToData(mx, my);

                subLayerFlag = CanvasLayers.isLayer2Selected;

                if (ReferenceLayerController.isRefLayerMemoryTrainingON)
                {
                    ReferenceLayerController.showMemoryTrainingMask();
                }

                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownLineTool, false, InputPriority.DEFAULT);
                main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownLineTool, false, InputPriority.DEFAULT);
                main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownLineTool, false, InputPriority.LATE);
                hasLineTouchedCanvas = checkPointInsideCanvas(mx, my);

                FOFOTimer.addByName("updateLineToolTimer", 0.1, true, function ():Boolean
                    {
                        updateLinePreview();
                        return true;
                    });

                if (KeyState.isPressingShift())
                {
                    startFromShortCut = true;
                    main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpLineTool, false, InputPriority.DEFAULT);
                }
            }
        }
    }
}
