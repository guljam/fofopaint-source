package Modules.Tools
{
    import Modules.CanvasController;
    import Modules.ColorPickerController;
    import Modules.DrawingFinish;
    import Modules.MainUI;
    import Modules.PaletteController;
    import Modules.ReferenceLayerController;
    import Modules.ReplayController;
    import Modules.ToolController;
    import Modules.UndoManager;

    import flash.display.BitmapData;
    import flash.display.CapsStyle;
    import flash.display.JointStyle;
    import flash.display.LineScaleMode;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import Modules.PenSizePreviewCursor;
    import flash.system.ApplicationDomain;
    import flash.events.KeyboardEvent;
    import Modules.InputManager;
    import flash.events.BrowserInvokeEvent;

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
        private static var xAirBrushON:Boolean;
        private static var subLayerFlag:Boolean;
        private static var command:Vector.<int>;
        private static var data:Vector.<Number>;
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

            if (startFromShortCut)
            {
                startFromShortCut = false;
                main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpLineTool);
            }
            else
            {
                main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownLineTool);
            }

            command.length = 0;
            data.length = 0;
            hasLineTouchedCanvas = false;
            _isStarted = false;

            CanvasController.isMouseDragging = false;
            PenSizePreviewCursor.setCursorInVisibleFlag(false);

            if (!ReferenceLayerController.isRefLayerEmpty() && ReferenceLayerController.isRefLayerMemoryTrainingON && ReferenceLayerController.refLayerLastAlpha > 0.0)
            {
                ReferenceLayerController.setCanvasRefLayerVisibleDelay();
            }
        }

        public static function cancel():void
        {
            removeEventsAndResetVar();
            CanvasController.canvasDrawLayerChild.graphics.clear();
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

            CanvasController.canvasDrawLayerChild.graphics.drawPath(command, data);
        }

        private static function updateLinePreview():void
        {
            const mx:Number = CanvasController.canvasDrawLayerChild.mouseX;
            const my:Number = CanvasController.canvasDrawLayerChild.mouseY;

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
                UndoManager.canAddUndoData = true;
                ReplayController.rDataBuffer.push(["line4", xShape, xSize, xColor, xAlpha, command.concat(), data.concat(), xBlendMode, subLayerFlag, PenTool.airBrushSizeDrawMode]);
            }

            CanvasController.resetCanvasDrawLayerCliprect();
            DrawingFinish.run();
            removeEventsAndResetVar();
        }

        private static function onKeyDownLineTool(e:KeyboardEvent):void
        {
            if (InputManager.isPressedKey(InputManager.KEY.esc))
            {
                cancel();
            }
            else if (InputManager.isPressedKey(InputManager.KEY.enter))
            {
                apply();
            }
        }

        private static function onKeyUpLineTool(e:KeyboardEvent):void
        {
            if (e.keyCode === InputManager.KEY.shift)
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
            const mx:Number = CanvasController.canvasDrawLayerChild.mouseX;
            const my:Number = CanvasController.canvasDrawLayerChild.mouseY;

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

                canvasWidth = CanvasController.CANVAS_WIDTH;
                canvasHeight = CanvasController.CANVAS_HEIGHT;
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

                command = new Vector.<int>();
                data = new Vector.<Number>();

                const mx:Number = CanvasController.canvasDrawLayerChild.mouseX;
                const my:Number = CanvasController.canvasDrawLayerChild.mouseY;

                inputMoveToData(mx, my);
                inputLineToData(mx, my);

                subLayerFlag = CanvasController.isLayer2Selected;

                if (!ReferenceLayerController.isRefLayerEmpty() && ReferenceLayerController.isRefLayerMemoryTrainingON)
                {
                    ReferenceLayerController.setCanvasRefLayerInvisible();
                }

                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownLineTool);
                main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownLineTool);

                if (hasLineTouchedCanvas === false)
                {
                    checkPointInsideCanvas(mx, my);
                }

                FOFOTimer.addByName("updateLineToolTimer", 0.1, true, function ():Boolean
                    {
                        updateLinePreview();
                        return true;
                    });

                if (InputManager.isPressingShift())
                {
                    startFromShortCut = true;
                    main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpLineTool);
                }
                else
                {
                    main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownLineTool);
                }
            }
        }
    }
}
