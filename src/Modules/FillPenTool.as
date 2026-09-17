package Modules
{
    import flash.geom.Point;
    import flash.display.SimpleButton;
    import Modules.Tools.PenTool;
    import flash.events.MouseEvent;
    import flash.display.DisplayObject;
    import Symbols.FillPenMenuSet;
    import flash.geom.Rectangle;
    import Modules.Tools.DottedLineTool;
    import flash.events.KeyboardEvent;
    import Modules.Tools.RotateTool;
    import flash.text.engine.BreakOpportunity;

    public class FillPenTool
    {
        //todo 다른 메서드들도 마찬가지지만 클래스 정적 변수 직접 접근하는 부분은 메서드로 호출하게 만들어야함
        public static var main:Main;

        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static const fillPenBox:FillPenMenuSet = new FillPenMenuSet();

        private static var _isStarted:Boolean = false; // 채우기 펜 시작됨
        private static const lastMousePos:Point = new Point(0, 0);
        private static var canvasSizeRect:Rectangle = new Rectangle();

        private static var command:Vector.<int>;
        private static var data:Vector.<Number>;
        private static var commandUndoIndexArr:Array = [];

        private static var xColor:uint;
        private static var xAlpha:Number;
        private static var xBlendMode:String;

        private static var mouseMoveCount:int;
        private static var _afterKeyUpOK:Boolean = false; //단축키를 떼고 나서 마우스 키를 땠을때 적용해주는 플래그
        private static var _pos05Offset:Number;
        private static var clickedButtonName:String;

        private static var canvasDrawZIndexSave:int = 0;
        private static const _lastPosOnMouseMove:Point = new Point();
        private static var lastFillPenBoxUsedButton:SimpleButton;
        private static var turnOffFillPenPreviewTimerCount:int = 0; //프리뷰 일정시간 지나면 사라지게 함
        private static var isStartedFromShortCut:Boolean = false;

        public static function handleOnMouseUp():void
        {
            const mousePos:Point = new Point(main.stage.mouseX, main.stage.mouseY);
            const dist:Number = Math.floor(Point.distance(mousePos, lastMousePos));

            mouseMoveCount += dist;

            if (mouseMoveCount >= 10)
            {
                mouseMoveCount = 0;
                commandUndoIndexArr.push(command.length - 1);
            }

            lastMousePos.setTo(mousePos.x, mousePos.y);

            if (_afterKeyUpOK)
            {
                applyFillPen();
            }
            else if (main.isCursorInDrawArea())
            {
                showDottedLine();
            }

            resetPreviewOFFTimerCount();
        }

        public static function set afterKeyUpOK(flag:Boolean):void
        {
            _afterKeyUpOK = flag;
        }

        public static function showFillPenMenuBox():void
        {
            const scale:Number = fillPenBox.getScale();

            fillPenBox.x = Math.floor(main.stage.mouseX - (lastFillPenBoxUsedButton.x + lastFillPenBoxUsedButton.width / 2) * scale);
            fillPenBox.y = Math.floor(main.stage.mouseY - (lastFillPenBoxUsedButton.y + lastFillPenBoxUsedButton.height / 2) * scale);
            fillPenBox.visible = true;

            Utils.setAsTopChild(fillPenBox);
        }

        public static function isInputDataEmpty():Boolean
        {
            return command.length === 0
        }

        public static function setPreviewOFFTimerCount():void
        {
            turnOffFillPenPreviewTimerCount = main.stage.frameRate;
        }
    
        public static function resetPreviewOFFTimerCount():void
        {
            turnOffFillPenPreviewTimerCount = 0;
        }

        public static function updateLastMousePos():void
        {
            lastMousePos.setTo(main.stage.mouseX, main.stage.mouseY);
        }

        public static function increasetMoveCount():void
        {
            mouseMoveCount++;

            if (mouseMoveCount >= 6)
            {
                mouseMoveCount = 0;
                commandUndoIndexArr.push(command.length - 1);
            }

        }

        public static function inputLineToData(posX:Number,posY:Number):void
        {
            command.push(2);
            data.push(posX);
            data.push(posY);
        }

        public static function inputMoveToData(posX:Number,posY:Number):void
        {
            command.push(1);
            data.push(posX);
            data.push(posY);
        }
        
        public static function set pos05Offset(value:Number):void
        {
            _pos05Offset = value;
        }

        public static function get pos05Offset():Number
        {
            return _pos05Offset;
        }

        public static function get isStarted():Boolean
        {
            return _isStarted;
        }

        public static function get clickedButton():String
        {
            return clickedButtonName;
        }

        public static function set clickedButton(value:String):void
        {
            clickedButtonName = value;
        }

        public static function get lastPosOnMouseMove():Point
        {
            return _lastPosOnMouseMove;
        }

        public static function updateLastFillPenBoxButtonUsed(target:SimpleButton):void
        {
            lastFillPenBoxUsedButton = target;
        }

        public static function startFillColorUpdateTimer():void
        {
            showFillColor();

            FOFOTimer.addByName("fillColorUpdateTimer", 0.1, true, function ():Boolean
                {
                    const newXcolor:uint = (PenTool.isTransparentPenColor) ? CanvasController.CANVAS_BG_COLOR : ColorPickerController.colorPickerBox.rgbInfoBGColor;
                    const newXAlpha:Number = PenTool.penAlpha;
                    const newXBlendMode:String = (PenTool.isTransparentPenColor) ? "erase" : null;

                    if (newXcolor !== xColor)
                    {
                        xColor = newXcolor;
                        xAlpha = newXAlpha;
                        xBlendMode = newXBlendMode;

                        showFillColor();
                    }

                    if (newXAlpha !== xAlpha)
                    {
                        xAlpha = newXAlpha;

                        showFillColor();
                    }

                    if (newXBlendMode !== xBlendMode)
                    {
                        xBlendMode = newXBlendMode;

                        showFillColor();
                    }

                    if (!SidebarController.sideBar.visible)
                    {
                        showDottedLine();

                        return false;
                    }
                    else if (!CanvasController.isMouseClicked && !SidebarController.sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                    {
                        turnOffFillPenPreviewTimerCount--;

                        if (turnOffFillPenPreviewTimerCount <= 0)
                        {
                            turnOffFillPenPreviewTimerCount = 0;

                            showDottedLine();

                            return false;
                        }
                    }

                    return true;
                });
        }

        public static function onMouseOverFillPenHint(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;

            if (!target)
            {
                return;
            }

            const targetName:String = target.name;

            if (!FOFOTimer.hasTimer("fillColorUpdateTimer") && SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
            {
                startFillColorUpdateTimer();
            }

            if (targetName === "fillPenOK")
            {
                fillPenBox.hint("OK [q, o key up]");
            }

            if (targetName === "fillPenCancel")
            {
                fillPenBox.hint("Cancel\n[esc, backspace]");
            }
            else if (targetName === "fillPenUndo")
            {
                fillPenBox.hint("Undo [w, z, i, .]");
            }
            else if (targetName === "fillPenSidebar")
            {
                fillPenBox.hint("[6, s+d, j+k]");
            }
        }

        private static function checkFillPenUndoReady():Boolean
        {
            if (canvasSizeRect.intersects(CanvasController.canvasDrawLayerChild.getBounds(CanvasController.canvasPanel)))
            {
                return true;
            }

            return false;
        }

        public static function showFillColor():void
        {
            CanvasController.canvasDrawLayerChild.graphics.clear();

            if (data.length === 0)
            {
                return;
            }

            CanvasController.canvasDrawLayerChild.graphics.lineStyle(1, xColor);
            CanvasController.canvasDrawLayerChild.graphics.beginFill(xColor);
            CanvasController.canvasDrawLayerChild.graphics.drawPath(command, data);
            CanvasController.canvasDrawLayerChild.graphics.endFill();

            CanvasController.canvasDrawLayerChild.graphics.moveTo(data[data.length - 2], data[data.length - 1]);
            CanvasController.canvasDrawLayerChild.graphics.lineTo(data[0], data[1]);

            CanvasController.canvasDrawLayer.alpha = xAlpha;
        }

        private static function showDottedLine():void
        {
            CanvasController.canvasDrawLayerChild.graphics.clear();

            const len:uint = data.length;

            if (len <= 3)
            {
                return;
            }

            DottedLineTool.moveTo(CanvasController.canvasDrawLayerChild.graphics, data[0], data[1]);

            for (var i:uint = 2; i < len; i += 2)
            {
                DottedLineTool.lineTo(data[i], data[i + 1]);
            }

            DottedLineTool.lineTo(data[0], data[1], true);

            if (CanvasController.isLayer2Selected)
            {
                CanvasController.bringCanvasDrawLayerAboveLayer1();
            }

            CanvasController.canvasDrawLayer.alpha = 1.0;
        }

        private static function exitFillPen():void
        {
            InputController.removeEventsFillPen();

            CanvasController.canvasDrawLayer.alpha = 1.0;

            mouseMoveCount = 0;
            _isStarted = false;

            command.length = 0;
            data.length = 0;
            commandUndoIndexArr.length = 0;

            CanvasController.canvasDrawLayerChild.graphics.clear();

            if (ReferenceLayerController.isRefLayerMenuON)
            {
                ReferenceLayerController.refLayerMenuBox.visible = true;
            }

            fillPenBox.visible = false;
            fillPenBox.x = -fillPenBox.width - 3;
            fillPenBox.y = -fillPenBox.height - 3;

            if (CanvasController.isLayer2Selected)
            {
                CanvasController.bringCanvasDrawLayerAboveLayer2();
            }

            if (SidebarController.isQuickSidebarActive)
            {
                SidebarController.startDeactivteQuickSidebar();
            }

            ToolController.toolBox.setFillPenModeOFF();
            ToolController.toolOptionsBox.setButtonsAlphaFillPenSelected(Global.OFFALPHA);
            ToolController.toolOptionsBox.restoreDisabledButtons();

            ColorPickerController.colorPickerBox.activePaperColorButton(false);

            if (isStartedFromShortCut)
            {
                ToolController.setLastTool(ToolController.TOOL_PEN);
                ToolController.selectPenTool();
            }
        }

        public static function applyFillPen():void
        {
            if (checkFillPenUndoReady() === true && command.length > 2)
            {
                UndoManager.canAddUndoData = true;

                command.push(2);
                data.push(data[0]);
                data.push(data[1]); // 마지막으로 원점으로 선을 한번 이어줘야 깔끔하게 닫힘

                CanvasController.canvasDrawLayer.alpha = xAlpha;
                ReplayController.rDataBuffer.push(["fill5", xColor, xAlpha, xBlendMode, command.concat(), data.concat(), ToolController.isPenAirBrushON, PenTool.airBrushSizeDrawMode]);

                showFillColor();
            }

            CanvasController.resetCanvasDrawLayerCliprect();
            DrawingFinish.run();

            exitFillPen();
        }

        public static function undoData():void
        {
            if (command.length === 0)
            {
                return;
            }

            command.splice(commandUndoIndexArr[commandUndoIndexArr.length - 1], command.length);
            data.splice(commandUndoIndexArr[commandUndoIndexArr.length - 1] * 2, data.length);
            commandUndoIndexArr.pop();

            if (command.length <= 1)
            {
                command.length = 0;
                data.length = 0;
                commandUndoIndexArr[0] = 0;

                CanvasController.canvasDrawLayerChild.graphics.clear();
            }
            else
            {
                showDottedLine();
            }
        }

        public static function cancel():void
        {
            exitFillPen();
        }

        public static function start():void
        {
            _isStarted = true;

            if (InputController.getFirstPressedKey() === InputController.KEY.q || InputController.getFirstPressedKey() === InputController.KEY.o)
            {
                isStartedFromShortCut = true;
            }
            else
            {
                isStartedFromShortCut = false;
            }

            canvasSizeRect.width = CanvasController.CANVAS_WIDTH;
            canvasSizeRect.height = CanvasController.CANVAS_HEIGHT;

            command = new Vector.<int>();
            data = new Vector.<Number>();

            if (ColorPickerController.isColorPickerModeBG)
            {
                ColorPickerController.switchColorPickerModePen();
            }

            mouseMoveCount = 0;
            _afterKeyUpOK = false;
            pos05Offset = ToolController.getSharpLinePosOffset(1.0);

            xColor = (PenTool.isTransparentPenColor) ? CanvasController.CANVAS_BG_COLOR : PenTool.penColor;
            xAlpha = PenTool.penAlpha;
            xBlendMode = (PenTool.isTransparentPenColor) ? "erase" : null;

            commandUndoIndexArr[0] = 0;
            clickedButtonName = null;

            updateLastFillPenBoxButtonUsed(fillPenBox.fillPenOK as SimpleButton);

            if (ToolController.isPenAirBrushON || PenTool.isEraserAirBrushON)
            {
                CanvasController.canvasDrawLayerChild.filters = [];
            }

            if (!PenTool.isTransparentPenColor)
            {
                if (!ColorPickerController.isCurrentColorSamePickedColor())
                {
                    ColorPickerController.updatePickerCurrentColor(ColorPickerController.colorPickerBox.getRGBInfoBGColor());
                    PaletteController.addColorMyPaletteHistory(ColorPickerController.colorPickerBox.getRGBInfoBGColor());
                }
            }

            if (ReferenceLayerController.isRefLayerMenuON)
            {
                ReferenceLayerController.refLayerMenuBox.visible = false;
            }

            DottedLineTool.setLineScale(CanvasController.canvasZoomMultipler);

            const filteredPos:Point = CanvasController.getRefinedPoint(CanvasController.canvasDrawLayerChild.mouseX, CanvasController.canvasDrawLayerChild.mouseY);
            var mx:Number = filteredPos.x + pos05Offset;
            var my:Number = filteredPos.y + pos05Offset;

            lastPosOnMouseMove.setTo(mx, my);

            command.push(1);
            data.push(mx);
            data.push(my);

            lastMousePos.setTo(mx, my);

            CanvasController.canvasDrawLayer.alpha = xAlpha;

            ToolController.toolBox.setFillPenModeON();
            ToolController.toolOptionsBox.disableButtonFillPenStarted();
            ColorPickerController.colorPickerBox.fillPenModeON();

            InputController.addEventsFillPen();
        }
    }
}
