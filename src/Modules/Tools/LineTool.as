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
    import Modules.InputController;

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
        private static var isPointInsideCanvas:Boolean = false;
        private static var lastClickedPos:Point = new Point(0, 0);

        public static function removeEventsAndResetVar():void
        {
            FOFOTimer.remove("updateLineToolTimer");
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, updateLinePreview);
            main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownLineTool);

            if (startFromShortCut)
            {
                startFromShortCut = false;
                main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpLineTool);
            }
            else
            {
                main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, updateLinePreview);
            }

            isPointInsideCanvas = false;
            _isStarted = false;
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

        private static function checkPointInsideCanvas(mx:Number, my:Number):void
        {
            if (mx >= 0 && mx <= canvasWidth && my >= 0 && my <= canvasHeight)
            {
                isPointInsideCanvas = true;
            }
        }

        public static function inputLineToData(posX:Number, posY:Number):void
        {
            lastClickedPos.setTo(posX, posY);
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
            CanvasController.isMouseDragging = false;
            PenSizePreviewCursor.setCursorInVisibleFlag(false);

            if (!ReferenceLayerController.isRefLayerEmpty() && ReferenceLayerController.isRefLayerMemoryTrainingON && ReferenceLayerController.refLayerLastAlpha > 0.0)
            {
                ReferenceLayerController.setCanvasRefLayerVisibleDelay();
            }

            if (isPointInsideCanvas)
            {
                removeLastLineToData();
                drawLine();
                isPointInsideCanvas = false;
                UndoManager.canAddUndoData = true;
                ReplayController.rDataBuffer.push(["line4", xShape, xSize, xColor, xAlpha, command, data, xBlendMode, subLayerFlag, PenTool.airBrushSizeDrawMode]);
            }
            else
            {
                trace('아예 안해줌');
            }

            CanvasController.resetCanvasDrawLayerCliprect();
            DrawingFinish.run();
            removeEventsAndResetVar();
        }

        private static function onKeyDownLineTool(e:KeyboardEvent):void
        {
            if (InputController.isPressedKey(InputController.KEY.esc))
            {
                cancel();
            }
            else if (InputController.isPressedKey(InputController.KEY.enter))
            {
                apply();
            }
        }

        private static function onKeyUpLineTool(e:KeyboardEvent):void
        {
            apply();
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
                inputLineToData(mx, my);
            }

            if (isPointInsideCanvas === false)
            {
                checkPointInsideCanvas(mx, my);
            }
        }

        // private static function onMouseUpLineTool(e:MouseEvent):void
        // {

            // if (isLineInsideCanvas() === true)
            // {
            // const mx:Number = CanvasController.canvasDrawLayerChild.mouseX;
            // const my:Number = CanvasController.canvasDrawLayerChild.mouseY;
            // UndoManager.canAddUndoData = true;
            // if (mouseMovedFlag === false && oldX === mx && oldY === my)
            // {
            // ReplayController.rDataBuffer = [];
            // ReplayController.rDataBuffer.push(["dot4", xShape, xSize, xColor, xAlpha, mx, my, xBlendMode, subLayerFlag, xAirBrushON, CanvasController.canvasAnchorPoint.rotation]);
            // DotTool.start(xShape, xSize, xColor, mx, my, CanvasController.canvasAnchorPoint.rotation);
            // }
            // else
            // {
            // if (xShape === true)
            // {
            // const extPoints:Array = extendLineSegment(oldX, oldY, mx, my, xSize / 8);
            // startPoint.setTo(extPoints[0], extPoints[1]);
            // endPoint.setTo(extPoints[2], extPoints[3]);
            // }
            // else
            // {
            // startPoint.setTo(oldX, oldY);
            // endPoint.setTo(mx, my);
            // }
            // }
            // }
        // }

        public static function start():void
        {
            if (_isStarted === false)
            {
                trace('start linetool');
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

                if (isPointInsideCanvas === false)
                {
                    checkPointInsideCanvas(mx, my);
                }

                subLayerFlag = CanvasController.isLayer2Selected;

                if (!ReferenceLayerController.isRefLayerEmpty() && ReferenceLayerController.isRefLayerMemoryTrainingON)
                {
                    ReferenceLayerController.setCanvasRefLayerInvisible();
                }

                // 선 관련 이벤트 함수 붙여줌
                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownLineTool);
                main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownLineTool);

                FOFOTimer.addByName("updateLineToolTimer", 0.1, true, function ():Boolean
                    {
                        updateLinePreview();
                        return true;
                    });

                if (InputController.isPressingShift())
                {
                    trace('단축키로 시작');
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
