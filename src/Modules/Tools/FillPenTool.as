package Modules.Tools
{
    import Modules.CanvasController;
    import Modules.ColorPickerController;
    import Modules.DrawingFinish;
    import Modules.InputManager;
    import Modules.InputPriority;
    import Modules.MouseState;
    import Modules.PaletteController;
    import Modules.ReferenceLayerController;
    import Modules.SidebarController;
    import Modules.ToolController;
    import Modules.UndoHistory;
    import Modules.Utils;
    import Modules.UIEngine.UIController;
    import Modules.UIEngine.UITheme;
    import flash.geom.Point;
    import flash.display.SimpleButton;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.display.DisplayObject;
    import Symbols.FillPenMenuSet;
    import flash.geom.Rectangle;
    import Modules.ReplayEngine.ReplayState;

    public class FillPenTool
    {
        // todo 다른 메서드들도 마찬가지지만 클래스 정적 변수 직접 접근하는 부분은 메서드로 호출하게 만들어야함
        // todo 왼쪽 클릭 뭔가 타이밍 잘맞춰서하면 선이 캔버스에 그려지는 버그있음 초반에 버그 구현되다가 갑자기 안됨
        // 새로 추가한 라인툴 이벤트랑 섞였을 가능성도 있음
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
        private static var _afterKeyUpOK:Boolean = false; // 단축키를 떼고 나서 마우스 키를 땠을때 적용해주는 플래그
        private static var _pos05Offset:Number;
        private static var clickedButtonName:String;

        private static const _lastPosOnMouseMove:Point = new Point();
        private static var lastFillPenBoxUsedButton:SimpleButton;
        private static var turnOffFillPenPreviewTimerCount:int = 0; // 프리뷰 일정시간 지나면 사라지게 함
        private static var isStartedFromShortCut:Boolean = false;

        private static function handleOnMouseUp():void
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
            else if (Utils.isCursorInDrawArea())
            {
                showDottedLine();
            }

            resetPreviewOFFTimerCount();
        }

        private static function showFillPenMenuBox():void
        {
            const scale:Number = fillPenBox.getScale();

            fillPenBox.x = Math.floor(main.stage.mouseX - (lastFillPenBoxUsedButton.x + lastFillPenBoxUsedButton.width / 2) * scale);
            fillPenBox.y = Math.floor(main.stage.mouseY - (lastFillPenBoxUsedButton.y + lastFillPenBoxUsedButton.height / 2) * scale);
            fillPenBox.visible = true;

            Utils.setAsTopChild(fillPenBox);
        }

        private static function isInputDataEmpty():Boolean
        {
            return command.length === 0;
        }

        private static function setPreviewOFFTimerCount():void
        {
            turnOffFillPenPreviewTimerCount = main.stage.frameRate;
        }

        private static function resetPreviewOFFTimerCount():void
        {
            turnOffFillPenPreviewTimerCount = 0;
        }

        private static function updateLastMousePos():void
        {
            lastMousePos.setTo(main.stage.mouseX, main.stage.mouseY);
        }

        private static function increasetMoveCount():void
        {
            mouseMoveCount++;

            if (mouseMoveCount >= 6)
            {
                mouseMoveCount = 0;
                commandUndoIndexArr.push(command.length - 1);
            }

        }

        private static function inputLineToData(posX:Number, posY:Number):void
        {
            command.push(2);
            data.push(posX);
            data.push(posY);
        }

        private static function inputMoveToData(posX:Number, posY:Number):void
        {
            command.push(1);
            data.push(posX);
            data.push(posY);
        }

        public static function get isStarted():Boolean
        {
            return _isStarted;
        }

        private static function updateLastFillPenBoxButtonUsed(target:SimpleButton):void
        {
            lastFillPenBoxUsedButton = target;
        }

        private static function startFillColorUpdateTimer():void
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

                        showAlphaChanged();
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
                    else if (!CanvasController.isMouseLeftClicked && !SidebarController.sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
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

        private static function onMouseOverFillPenHint(e:MouseEvent):void
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

        private static function showAlphaChanged():void
        {
            CanvasController.canvasDrawLayer.alpha = xAlpha;
        }

        private static function showFillColor():void
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

            for (var i:uint = 2;i < len;i += 2)
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
            removeEventsFillPen();

            CanvasController.canvasDrawLayer.alpha = 1.0;

            mouseMoveCount = 0;
            _isStarted = false;

            command = new <int>[];
            data = new <Number>[];
            commandUndoIndexArr = [];

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
            ToolController.toolOptionsBox.setButtonsAlphaFillPenSelected(UITheme.OFFALPHA);
            ToolController.toolOptionsBox.restoreDisabledButtons();

            ColorPickerController.colorPickerBox.activePaperColorButton(false);

            if (isStartedFromShortCut)
            {
                ToolController.setLastTool(ToolController.TOOL_PEN);
                ToolController.selectPenTool();
            }
        }

        private static function applyFillPen():void
        {
            if (checkFillPenUndoReady() === true && command.length > 2)
            {
                UndoHistory.canAddUndoData = true;

                command.push(2);
                data.push(data[0]);
                data.push(data[1]); // 마지막으로 원점으로 선을 한번 이어줘야 깔끔하게 닫힘

                CanvasController.canvasDrawLayer.alpha = xAlpha;
                ReplayState.pushCommand(["fill5", xColor, xAlpha, xBlendMode, command.concat(), data.concat(), ToolController.isPenAirBrushON, PenTool.airBrushSizeDrawMode]);

                showFillColor();
            }

            CanvasController.resetCanvasDrawLayerCliprect();
            DrawingFinish.run();

            exitFillPen();
        }

        private static function undoData():void
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

            if (InputManager.getFirstPressedKey() === InputManager.KEY.q || InputManager.getFirstPressedKey() === InputManager.KEY.o)
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
            _pos05Offset = ToolController.getSharpLinePosOffset(1.0);

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
            var mx:Number = filteredPos.x + _pos05Offset;
            var my:Number = filteredPos.y + _pos05Offset;

            _lastPosOnMouseMove.setTo(mx, my);

            command.push(1);
            data.push(mx);
            data.push(my);

            lastMousePos.setTo(mx, my);

            CanvasController.canvasDrawLayer.alpha = xAlpha;

            ToolController.toolBox.setFillPenModeON();
            ToolController.toolOptionsBox.disableButtonFillPenStarted();
            ColorPickerController.colorPickerBox.setFillPenModeON();

            addEventsFillPen();
            beginFillPenDrag();
        }

        // 오른쪽 버튼을 떼서 항목을 고르는 메뉴라서, 포커스를 잃으면(alt+tab 등) up이 안 와서 메뉴가 남음
        public static function hideFillPenMenuBox():void
        {
            fillPenBox.visible = false;
        }

        // ---- 입력 처리 ----

        private static function onMouseMoveFillPen(e:MouseEvent):void
        {
            const filteredPos:Point = CanvasController.getRefinedPoint(CanvasController.canvasDrawLayerChild.mouseX, CanvasController.canvasDrawLayerChild.mouseY);
            const mx:Number = filteredPos.x + _pos05Offset;
            const my:Number = filteredPos.y + _pos05Offset;

            if (_lastPosOnMouseMove.x === mx && _lastPosOnMouseMove.y === my)
            {
                return;
            }

            _lastPosOnMouseMove.setTo(mx, my);

            if (isInputDataEmpty())
            {
                inputMoveToData(mx, my);
            }
            else
            {
                inputLineToData(mx, my);
            }

            increasetMoveCount();

            updateLastMousePos();
            resetPreviewOFFTimerCount();

            if (!FOFOTimer.hasTimer("previewFilledColorUpdateTimer"))
            {
                FOFOTimer.addByName("previewFilledColorUpdateTimer", 0.1, false, showFillColor);
            }
        }

        private static function onMouseDownFillPen(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;

            if (!target)
            {
                return;
            }

            const targetName:String = target.name;
            clickedButtonName = targetName;

            if (fillPenBox.visible)
            {
                return;
            }

            if (SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
            {
                if (targetName === "penColorButton" || targetName === "paperColorButton" || targetName === "rgbInfoText")
                {
                    return;
                }

                if (ColorPickerController.handleColorPickerBoxMouseDown(target) || ColorPickerController.numPadBox.visible)
                {
                    return;
                }

                if (ColorPickerController.numPadBox.visible)
                {
                    return;
                }

                if (targetName.indexOf(UITheme.ALPHA_BUTTON_PREFIX) == 0)
                {
                    ToolController.onOpacityButtonDown(targetName);
                    return;
                }

                switch (targetName)
                {
                    case "toolRotate":
                        {
                            RotateTool.startInDrawMode();
                        }
                        return;

                    case "prevStageBG":
                    case "prevBitmapBG":
                    case "prevBitmap":
                        {
                            CanvasController.startCanvasMoveByCanvasNavigator(false);
                        }
                        return;

                    case "prevCursor":
                        {
                            CanvasController.startCanvasMoveByCanvasNavigator(true);
                        }
                        return;

                    case "toolZoomIn":
                    case "toolZoomOut":
                        {
                            ToolController.handleToolBoxClick(targetName);
                        }
                        return;

                    default:
                        break;
                }
            }

            if (targetName === "sideBarScrollBar")
            {
                SidebarController.startScrollSidebarByDrag();
            }
            else if (Utils.isCursorInDrawArea() && SidebarController.isQuickSidebarActive === false)
            {
                main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);
                MouseState.beginDrag(FILLPEN_DRAG_OWNER, finishFillPenDrag);

                const filteredPos:Point = CanvasController.getRefinedPoint(CanvasController.canvasDrawLayerChild.mouseX, CanvasController.canvasDrawLayerChild.mouseY);
                const mx:Number = filteredPos.x + _pos05Offset;
                const my:Number = filteredPos.y + _pos05Offset;

                if (CanvasController.isLayer2Selected)
                {
                    CanvasController.bringCanvasDrawLayerAboveLayer2();
                }

                if (_lastPosOnMouseMove.x === mx && _lastPosOnMouseMove.y === my)
                {
                    FOFOTimer.remove("previewFilledColorUpdateTimer");
                    showFillColor();

                    return;
                }

                _lastPosOnMouseMove.setTo(mx, my);

                if (isInputDataEmpty())
                {
                    inputMoveToData(mx, my);
                }
                else
                {
                    inputLineToData(mx, my);
                }

                FOFOTimer.remove("previewFilledColorUpdateTimer");
                showFillColor();
            }
        }

        private static function removeEventsFillPen():void
        {
            // 드래그 도중 FillPen이 종료되면(파일 로드로 취소 등) onMouseUpFillPen이 안 불리므로 여기서 등록을 해제함
            MouseState.endDrag(FILLPEN_DRAG_OWNER);
            main.stage.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOverFillPenHint);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownFillPen);
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpFillPen);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownFillPen);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpFillPen);
            main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpFillPen);
            main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeydownFillPen);
        }

        private static function addEventsFillPen():void
        {
            main.stage.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverFillPenHint);
            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownFillPen, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpFillPen, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownFillPen, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpFillPen, false, InputPriority.DEFAULT);
            main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpFillPen, false, InputPriority.DEFAULT);
            main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeydownFillPen, false, InputPriority.DEFAULT);
        }

        private static function onRightMouseDownFillPen(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;

            if (CanvasController.isMouseLeftClicked
                    || SidebarController.isQuickSidebarActive
                    || !target
                    || ColorPickerController.numPadBox.visible)
            {
                return;
            }

            if (target === SidebarController.sideBarScrollBar)
            {
                SidebarController.resetSideBarPosition();
                return;
            }
            else if (target.name === "toolZoomIn" || target.name === "toolZoomOut")
            {
                if (CanvasController.canvasZoomMultipler !== 1.0)
                {
                    CanvasController.resetZoomDrawMode();
                    UIController.updateCanvasNaigatorCursor();
                }
                return;
            }
            else if (target.name === "toolRotate")
            {
                if (CanvasController.canvasAnchorPoint.rotation !== 0.0)
                {
                    CanvasController.resetRotationDrawMode();
                    UIController.updateCanvasNaigatorCursor();
                }
                return;
            }

            if (SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
            {
                return;
            }

            showFillPenMenuBox()
        }

        private static const FILLPEN_DRAG_OWNER:String = "fillPenDrag";

        // 첫 획은 onMouseDownFillPen이 아니라 start()가 시작하므로 거기서 호출해 등록함
        private static function beginFillPenDrag():void
        {
            MouseState.beginDrag(FILLPEN_DRAG_OWNER, finishFillPenDrag);
        }

        // 이벤트 객체를 쓰지 않음. mouseUp을 못받는 경우(alt+tab 등)에 MouseState.finishAllDrags가 직접 호출함
        // onMouseUpFillPen에서 버튼 클릭 판정(e.target)이 필요 없는 마무리 부분만 수행함
        private static function finishFillPenDrag():void
        {
            MouseState.endDrag(FILLPEN_DRAG_OWNER);
            FOFOTimer.remove("previewFilledColorUpdateTimer");
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);

            // 드래그 도중 FillPen이 이미 종료됐다면(등록이 남은 경우) 미리보기를 다시 그리지 않음
            if (isStarted && !fillPenBox.visible)
            {
                handleOnMouseUp();
            }

            _afterKeyUpOK = false;
        }

        private static function onMouseUpFillPen(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;

            if (!target)
            {
                return;
            }

            const targetName:String = e.target.name;

            MouseState.endDrag(FILLPEN_DRAG_OWNER);
            FOFOTimer.remove("previewFilledColorUpdateTimer");
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveFillPen);

            if (clickedButtonName === targetName)
            {
                if (targetName === "toolFillPenOK")
                {
                    applyFillPen();
                    return;
                }
                else if (targetName === "toolFillPenCancel")
                {
                    cancel();
                    return;
                }
                else if (targetName === "toolUndo")
                {
                    undoData();
                    return;
                }
            }

            if (fillPenBox.visible)
            {
                if (clickedButtonName === targetName)
                {
                    if (targetName === "fillPenOK")
                    {
                        applyFillPen();
                    }
                    else if (targetName === "fillPenCancel")
                    {
                        cancel();
                    }
                    else if (targetName === "fillPenUndo")
                    {
                        updateLastFillPenBoxButtonUsed(target as SimpleButton);
                        undoData();
                    }
                }
            }
            else
            {
                handleOnMouseUp();
            }

            _afterKeyUpOK = false;
        }

        private static function onKeydownFillPen(e:KeyboardEvent):void
        {
            const pressedKey:uint = e.keyCode;

            if (CanvasController.isMouseLeftClicked)
            {
                return;
            }

            if (InputManager.isLastKey(pressedKey))
            {
                return;
            }

            const secondKey:int = InputManager.getSecondPressedKey();

            if (SidebarController.isPressingQuickSidebarShortcut(pressedKey, secondKey) || pressedKey === InputManager.KEY.n6)
            {
                InputManager.updateLastKey();

                if (SidebarController.isQuickSidebarActive === false)
                {
                    SidebarController.activeQuickSideBar(true);

                    if (!FOFOTimer.hasTimer("fillColorUpdateTimer"))
                    {
                        startFillColorUpdateTimer();
                    }
                }
            }
            else if (pressedKey === InputManager.KEY.g || pressedKey === InputManager.KEY.b)
            {
                InputManager.updateLastKey();
                InputManager.startKeyRepeat(true, function (increase:Boolean):void
                    {
                        setPreviewOFFTimerCount();
                        ToolController.adjustDrawToolAlphaByShortcut(increase);
                    }, (pressedKey === InputManager.KEY.g) ? true : false);

                if (!FOFOTimer.hasTimer("fillColorUpdateTimer"))
                {
                    startFillColorUpdateTimer();
                }
            }
        }

        private static function onKeyUpFillPen(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;
            InputManager.resetLastKey();

            if (CanvasController.isMouseLeftClicked)
            {
                if (keyCode === InputManager.KEY.q || keyCode === InputManager.KEY.o || keyCode === InputManager.KEY.enter)
                {
                    _afterKeyUpOK = true;
                }

                return;
            }

            if (keyCode === InputManager.KEY.w || keyCode === InputManager.KEY.i || keyCode === InputManager.KEY.z || keyCode === InputManager.KEY.dot)
            {
                undoData();
            }
            else if (keyCode === InputManager.KEY.q || keyCode === InputManager.KEY.o || keyCode === InputManager.KEY.enter)
            {
                applyFillPen();
            }
            else if (keyCode === InputManager.KEY.esc || keyCode === InputManager.KEY.backspace)
            {
                cancel();
            }
        }

        private static function onRightMouseUpFillPen(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;

            if (!target as DisplayObject || target === SidebarController.sideBarScrollBar || SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
            {
                return;
            }

            const targetName:String = target.name;

            if (targetName === "fillPenOK")
            {
                applyFillPen();
            }
            else if (targetName === "fillPenCancel")
            {
                cancel();
            }
            else if (targetName === "fillPenUndo")
            {
                updateLastFillPenBoxButtonUsed(target as SimpleButton);
                undoData();
            }
            else if (targetName === "fillPenSidebar")
            {
                updateLastFillPenBoxButtonUsed(target as SimpleButton);
                SidebarController.activeQuickSideBar(false);

                if (!FOFOTimer.hasTimer("fillColorUpdateTimer"))
                {
                    startFillColorUpdateTimer();
                }
            }

            fillPenBox.visible = false;
        }
    }
}
