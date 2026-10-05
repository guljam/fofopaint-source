package Modules.Tools
{
    import Modules.DrawEngine.StrokeBuffer;
    import Modules.DrawEngine.CanvasView;
    import Modules.DrawEngine.DrawCanvas;
    import Modules.DrawEngine.CanvasLayers;
    import Modules.UIEngine.CanvasNavigator;
    import Modules.ColorHistory;
    import Modules.ColorPickerController;
    import Modules.DrawingFinish;
    import Modules.InputManager.InputManager;
    import Modules.InputPriority;
    import Modules.MouseState;
    import Modules.PaletteController;
    import Modules.ReferenceLayerController;
    import Modules.SidebarController;
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
    import flash.filters.BlurFilter;
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
        private static var canvasSizeRect:Rectangle = new Rectangle();

        private static var command:Vector.<int>;
        private static var data:Vector.<Number>;

        private static var xColor:uint;
        private static var xAlpha:Number;
        private static var xBlendMode:String;
        private static var xAirBrushSize:int; // 미리보기에 적용된 블러 크기와 줌 배율
        private static var xZoom:Number;
        private static var blurFilterSize:Number = 0; // 미리보기에 걸어둔 블러 필터 크기 (0이면 없음)
        private static var isFillPreviewShown:Boolean = false; // 점선이 아니라 채운 미리보기가 보이는 중
        private static const BLUR_PREVIEW_IDLE_TIME:Number = 0.15; // 점을 찍다가 이 시간 멈추면 블러 미리보기를 보여줌
        private static const UNDO_LENGTH:Number = 30; // undo 한 번에 지우는 경로 길이 (화면 px)

        private static var _afterKeyUpOK:Boolean = false; // 단축키를 떼고 나서 마우스 키를 땠을때 적용해주는 플래그
        private static var _pos05Offset:Number;
        private static var clickedButtonName:String;

        private static const _lastPosOnMouseMove:Point = new Point();
        private static var lastFillPenBoxUsedButton:SimpleButton;
        private static var turnOffFillPenPreviewTimerCount:int = 0; // 프리뷰 일정시간 지나면 사라지게 함
        private static var isStartedFromShortCut:Boolean = false;

        private static function handleOnMouseUp():void
        {
            if (_afterKeyUpOK)
            {
                applyFillPen();
            }
            else if (Utils.isCursorInDrawArea())
            {
                showDottedLine();
            }
            else if (isFillPreviewShown && StrokeBuffer.canvasDrawLayerChild.filters.length === 0)
            {
                // 그리던 채운 미리보기가 그대로 남는 경우 (사이드바 위에서 뗌), 멈춘 상태이므로 블러를 걸어줌
                showFillColor(true);
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
                    const newXcolor:uint = (PenTool.isTransparentPenColor) ? DrawCanvas.CANVAS_BG_COLOR : ColorPickerController.colorPickerBox.rgbInfoBGColor;
                    const newXAlpha:Number = PenSettings.penAlpha;
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

                    // 에어브러시 켜기/끄기와 크기 변경은 색상 변경처럼 채운 미리보기를 보여줌
                    // 줌은 블러가 걸린 미리보기가 보이는 중일때만 다시 맞춤
                    if (PenSettings.airBrushSizeDrawMode !== xAirBrushSize
                            || (CanvasView.canvasZoomMultiplier !== xZoom && StrokeBuffer.canvasDrawLayerChild.filters.length > 0))
                    {
                        showFillColor();
                    }

                    if (!SidebarController.sideBar.visible)
                    {
                        showDottedLine();

                        return false;
                    }
                    else if (!MouseState.isLeftDown && !SidebarController.sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
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
            if (canvasSizeRect.intersects(StrokeBuffer.canvasDrawLayerChild.getBounds(CanvasView.canvasPanel)))
            {
                return true;
            }

            return false;
        }

        private static function showAlphaChanged():void
        {
            StrokeBuffer.canvasDrawLayer.alpha = xAlpha;
        }

        // applyBlur: 에어브러시 블러를 미리보기에 걸지 여부, 점을 찍는 중에는 비용 때문에 걸지 않음
        private static function showFillColor(applyBlur:Boolean = true):void
        {
            StrokeBuffer.canvasDrawLayerChild.graphics.clear();

            if (data.length === 0)
            {
                isFillPreviewShown = false;
                return;
            }

            isFillPreviewShown = true;

            StrokeBuffer.canvasDrawLayerChild.graphics.lineStyle(1, xColor);
            StrokeBuffer.canvasDrawLayerChild.graphics.beginFill(xColor);
            StrokeBuffer.canvasDrawLayerChild.graphics.drawPath(command, data);
            StrokeBuffer.canvasDrawLayerChild.graphics.endFill();

            StrokeBuffer.canvasDrawLayerChild.graphics.moveTo(data[data.length - 2], data[data.length - 1]);
            StrokeBuffer.canvasDrawLayerChild.graphics.lineTo(data[0], data[1]);

            StrokeBuffer.canvasDrawLayer.alpha = xAlpha;

            xAirBrushSize = PenSettings.airBrushSizeDrawMode;
            xZoom = CanvasView.canvasZoomMultiplier;

            if (applyBlur && xAirBrushSize > 0)
            {
                setBlurPreviewFilter();
            }
            else
            {
                clearBlurPreviewFilter();
            }
        }

        // 점을 찍는 중에는 블러 없이 채운 모양만 보여주고, 마우스가 잠시 멈추면 블러를 걸어줌
        private static function showFillColorWhileDrawing():void
        {
            showFillColorSharp();
            scheduleBlurPreview();
        }

        private static function showFillColorSharp():void
        {
            showFillColor(false);
        }

        private static function scheduleBlurPreview():void
        {
            if (PenSettings.airBrushSizeDrawMode > 0)
            {
                FOFOTimer.addByName("fillBlurPreviewTimer", BLUR_PREVIEW_IDLE_TIME, false, showBlurPreviewAfterIdle); // 같은 이름이면 시간을 다시 시작함
            }
        }

        private static function cancelBlurPreview():void
        {
            FOFOTimer.remove("fillBlurPreviewTimer");
        }

        private static function showBlurPreviewAfterIdle():void
        {
            if (!_isStarted)
            {
                return;
            }

            // 같은 프레임에 채운 미리보기 타이머가 뒤따라 블러를 지우지 못하게 먼저 없앰
            FOFOTimer.remove("previewFilledColorUpdateTimer");
            showFillColor(true);
        }

        // 에어브러시가 켜져 있으면 채운 미리보기에도 OK할 때와 같은 블러를 보여줌 (점선 미리보기에는 적용하지 않음)
        // 필터는 줌 배율에 따라 커지지 않으므로 화면 기준 크기로 맞춰줌, OK할 때는 DrawingFinish가 1배율로 다시 적용함
        // 같은 크기의 필터가 이미 걸려 있으면 다시 걸지 않음
        private static function setBlurPreviewFilter():void
        {
            const blurSize:Number = PenTool.getBlurSize(xAirBrushSize, xZoom);

            if (blurSize === blurFilterSize && StrokeBuffer.canvasDrawLayerChild.filters.length > 0)
            {
                return;
            }

            blurFilterSize = blurSize;
            StrokeBuffer.canvasDrawLayerChild.filters = [new BlurFilter(blurSize, blurSize, 3)];
        }

        private static function clearBlurPreviewFilter():void
        {
            blurFilterSize = 0;

            if (StrokeBuffer.canvasDrawLayerChild.filters.length > 0)
            {
                StrokeBuffer.canvasDrawLayerChild.filters = [];
            }
        }

        private static function showDottedLine():void
        {
            StrokeBuffer.canvasDrawLayerChild.graphics.clear();
            isFillPreviewShown = false;
            cancelBlurPreview();
            clearBlurPreviewFilter();

            const len:uint = data.length;

            if (len <= 3)
            {
                return;
            }

            DottedLineTool.moveTo(StrokeBuffer.canvasDrawLayerChild.graphics, data[0], data[1]);

            for (var i:uint = 2;i < len;i += 2)
            {
                DottedLineTool.lineTo(data[i], data[i + 1]);
            }

            DottedLineTool.lineTo(data[0], data[1], true);

            if (CanvasLayers.isLayer2Selected)
            {
                CanvasLayers.bringCanvasDrawLayerAboveLayer1();
            }

            StrokeBuffer.canvasDrawLayer.alpha = 1.0;
        }

        private static function exitFillPen():void
        {
            removeEventsFillPen();

            StrokeBuffer.canvasDrawLayer.alpha = 1.0;

            _isStarted = false;

            command = new <int>[];
            data = new <Number>[];

            StrokeBuffer.canvasDrawLayerChild.graphics.clear();
            isFillPreviewShown = false;
            cancelBlurPreview();
            clearBlurPreviewFilter();

            if (ReferenceLayerController.isRefLayerMenuON)
            {
                ReferenceLayerController.refLayerMenuBox.visible = true;
            }

            fillPenBox.visible = false;
            fillPenBox.x = -fillPenBox.width - 3;
            fillPenBox.y = -fillPenBox.height - 3;

            CanvasLayers.syncDrawLayerOrder(); // 종료 시점에 선택된 레이어 기준으로 drawLayer 위치를 확정함 (미리보기 중 레이어를 바꿨어도 맞춰짐)

            if (SidebarController.isQuickSidebarActive)
            {
                SidebarController.startDeactivteQuickSidebar();
            }

            ToolPanel.toolBox.setFillPenModeOFF();
            ToolPanel.updateFillPenOptions();
            ToolPanel.toolOptionsBox.restoreDisabledButtons();

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

                StrokeBuffer.canvasDrawLayer.alpha = xAlpha;
                ReplayState.rMemoryDataBuffer.push(["fill5", xColor, xAlpha, xBlendMode, command.concat(), data.concat(), PenSettings.isPenAirBrushON, PenSettings.airBrushSizeDrawMode]);

                showFillColor(false); // 블러는 DrawingFinish가 적용함
            }

            StrokeBuffer.resetCanvasDrawLayerClipRect();
            DrawingFinish.run();

            exitFillPen();
        }

        private static function undoData():void
        {
            if (command.length === 0)
            {
                return;
            }

            // 끝점부터 경로 길이가 UNDO_LENGTH(화면 px)에 닿을 때까지 점을 통째로 지움
            // 마지막 점이 이전 점에서 그 길이 이상 떨어져 있으면 그 점 하나만 지워짐 (점을 멀리 찍은 경우)
            const maxLength:Number = UNDO_LENGTH / CanvasView.canvasZoomMultiplier; // data는 캔버스 좌표라서 줌으로 나눔
            var count:int = command.length;
            var removedLength:Number = 0;
            var i:int;
            var dx:Number;
            var dy:Number;

            while (count > 1 && removedLength < maxLength)
            {
                i = (count - 1) * 2;
                dx = data[i] - data[i - 2];
                dy = data[i + 1] - data[i - 1];
                removedLength += Math.sqrt(dx * dx + dy * dy);
                count--;
            }

            if (count <= 1)
            {
                command.length = 0;
                data.length = 0;
                _lastPosOnMouseMove.setTo(NaN, NaN); // 같은 자리에 다시 찍어도 점이 들어가게 함
            }
            else
            {
                command.length = count;
                data.length = count * 2;
                _lastPosOnMouseMove.setTo(data[data.length - 2], data[data.length - 1]);
            }

            showDottedLine(); // 점이 없으면 점선 없이 미리보기만 지움
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

            canvasSizeRect.width = DrawCanvas.CANVAS_WIDTH;
            canvasSizeRect.height = DrawCanvas.CANVAS_HEIGHT;

            command = new Vector.<int>();
            data = new Vector.<Number>();

            if (ColorPickerController.isColorPickerModeBG)
            {
                ColorPickerController.switchColorPickerModePen();
            }

            _afterKeyUpOK = false;
            _pos05Offset = PenSettings.getSharpLinePosOffset(1.0);

            xColor = (PenTool.isTransparentPenColor) ? DrawCanvas.CANVAS_BG_COLOR : PenTool.penColor;
            xAlpha = PenSettings.penAlpha;
            xBlendMode = (PenTool.isTransparentPenColor) ? "erase" : null;
            xAirBrushSize = PenSettings.airBrushSizeDrawMode;
            xZoom = CanvasView.canvasZoomMultiplier;
            isFillPreviewShown = false;
            blurFilterSize = 0;

            clickedButtonName = null;

            updateLastFillPenBoxButtonUsed(fillPenBox.fillPenOK as SimpleButton);

            if (PenSettings.isPenAirBrushON || PenSettings.isEraserAirBrushON)
            {
                StrokeBuffer.canvasDrawLayerChild.filters = [];
            }

            if (!PenTool.isTransparentPenColor)
            {
                if (!ColorPickerController.isCurrentColorSamePickedColor())
                {
                    ColorPickerController.updatePickerCurrentColor(ColorPickerController.colorPickerBox.getRGBInfoBGColor());
                    ColorHistory.add(ColorPickerController.colorPickerBox.getRGBInfoBGColor());
                }
            }

            if (ReferenceLayerController.isRefLayerMenuON)
            {
                ReferenceLayerController.refLayerMenuBox.visible = false;
            }

            DottedLineTool.setLineScale(CanvasView.canvasZoomMultiplier);

            const filteredPos:Point = PenTool.getRefinedPoint(StrokeBuffer.canvasDrawLayerChild.mouseX, StrokeBuffer.canvasDrawLayerChild.mouseY);
            var mx:Number = filteredPos.x + _pos05Offset;
            var my:Number = filteredPos.y + _pos05Offset;

            _lastPosOnMouseMove.setTo(mx, my);

            command.push(1);
            data.push(mx);
            data.push(my);

            StrokeBuffer.canvasDrawLayer.alpha = xAlpha;

            ToolPanel.toolBox.setFillPenModeON();
            ToolPanel.toolOptionsBox.disableButtonFillPenStarted();
            ToolPanel.updateFillPenOptions(); // 진행 중에는 크기 버튼도 흐리게 함
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
            const filteredPos:Point = PenTool.getRefinedPoint(StrokeBuffer.canvasDrawLayerChild.mouseX, StrokeBuffer.canvasDrawLayerChild.mouseY);
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

            resetPreviewOFFTimerCount();

            if (!FOFOTimer.hasTimer("previewFilledColorUpdateTimer"))
            {
                FOFOTimer.addByName("previewFilledColorUpdateTimer", 0.1, false, showFillColorSharp);
            }

            scheduleBlurPreview();
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
                if (targetName === "penColorButton" || targetName === "paperColorButton" || targetName === "rgbInfoText" || targetName === "currentColor")
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
                    ToolPanel.onOpacityButtonDown(targetName);
                    return;
                }

                // 에어브러시가 켜져 있을때만 크기(번짐 정도)를 바꿈. 블러는 OK할 때 적용함
                if (targetName.indexOf(UITheme.NSIZE_BUTTON_PREFIX) == 0)
                {
                    if (PenSettings.isFillPenSizeChangeable())
                    {
                        ToolPanel.onPenSizeButtonDown(targetName);
                    }
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
                            CanvasNavigator.startCanvasMove(false);
                        }
                        return;

                    case "prevCursor":
                        {
                            CanvasNavigator.startCanvasMove(true);
                        }
                        return;

                    case "toolZoomIn":
                    case "toolZoomOut":
                        {
                            ToolPanel.handleToolBoxClick(targetName);
                        }
                        return;

                    // 블러는 OK할 때 적용하므로 진행 중에도 켜고 끌 수 있음 (크기 버튼은 진행 중에 바꾸지 않음)
                    case "airBrushButtonWrapper":
                    case "airBrushOFFButton":
                    case "airBrushONButton":
                    case "airBrushText":
                        {
                            PenSettings.togglePenAirBrushButton(!PenSettings.isPenAirBrushON);
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

                const filteredPos:Point = PenTool.getRefinedPoint(StrokeBuffer.canvasDrawLayerChild.mouseX, StrokeBuffer.canvasDrawLayerChild.mouseY);
                const mx:Number = filteredPos.x + _pos05Offset;
                const my:Number = filteredPos.y + _pos05Offset;

                if (CanvasLayers.isLayer2Selected)
                {
                    CanvasLayers.bringCanvasDrawLayerAboveLayer2();
                }

                if (_lastPosOnMouseMove.x === mx && _lastPosOnMouseMove.y === my)
                {
                    FOFOTimer.remove("previewFilledColorUpdateTimer");
                    showFillColorWhileDrawing();

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
                showFillColorWhileDrawing();
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

            if (MouseState.isLeftDown
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
                if (CanvasView.canvasZoomMultiplier !== 1.0)
                {
                    CanvasView.resetZoomDrawMode();
                    CanvasNavigator.updateCursor();
                }
                return;
            }
            else if (target.name === "toolRotate")
            {
                if (CanvasView.canvasAnchorPoint.rotation !== 0.0)
                {
                    CanvasView.resetRotationDrawMode();
                    CanvasNavigator.updateCursor();
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
            cancelBlurPreview();
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
            cancelBlurPreview();
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

            if (MouseState.isLeftDown)
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
            else if (pressedKey === InputManager.KEY.n4 || pressedKey === InputManager.KEY.n7)
            {
                InputManager.updateLastKey();
                setPreviewOFFTimerCount();
                PenSettings.togglePenAirBrushButtonShortCut();

                if (!FOFOTimer.hasTimer("fillColorUpdateTimer"))
                {
                    startFillColorUpdateTimer();
                }
            }
            else if ((pressedKey === InputManager.KEY.f || pressedKey === InputManager.KEY.h
                    || pressedKey === InputManager.KEY.v || pressedKey === InputManager.KEY.n)
                    && PenSettings.isFillPenSizeChangeable())
            {
                InputManager.updateLastKey();
                InputManager.startKeyRepeat(true, function (increase:Boolean):void
                    {
                        setPreviewOFFTimerCount();
                        PenSettings.adjustDrawToolSizeByShortcut(increase);
                    }, (pressedKey === InputManager.KEY.f || pressedKey === InputManager.KEY.h));

                if (!FOFOTimer.hasTimer("fillColorUpdateTimer"))
                {
                    startFillColorUpdateTimer();
                }
            }
            else if (pressedKey === InputManager.KEY.g || pressedKey === InputManager.KEY.b)
            {
                InputManager.updateLastKey();
                InputManager.startKeyRepeat(true, function (increase:Boolean):void
                    {
                        setPreviewOFFTimerCount();
                        PenSettings.adjustDrawToolAlphaByShortcut(increase);
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

            if (MouseState.isLeftDown)
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
