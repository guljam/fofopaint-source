package Modules.Tools
{
    import Modules.ColorPickerController;
    import Modules.FileManager;
    import Modules.InputPriority;
    import Modules.MouseState;
    import Modules.PenSizePreviewCursor;
    import Modules.ReferenceLayerController;
    import Modules.SidebarController;
    import Modules.UndoController;
    import Modules.Utils;
    import Modules.DrawEngine.StrokeBuffer;
    import Modules.DrawEngine.CanvasView;
    import Modules.DrawEngine.DrawCanvas;
    import Modules.DrawEngine.CanvasLayers;
    import Modules.DrawEngine.CanvasResizer;
    import Modules.InputManager.InputManager;
    import Modules.InputManager.DrawModeInput;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;
    import Modules.UIEngine.UITheme;

    import Symbols.ToolMenuSet;
    import Symbols.ToolMenuSet2;
    import Symbols.ToolOptionsSet;

    import flash.display.Bitmap;
    import flash.display.DisplayObject;
    import flash.display.SimpleButton;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import Modules.ReplayEngine.ReplayState;

    public class ToolController
    {
        // todo: 포멧팅 필요
        public static var main:Main;

        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static const TOOL_NONE:int = 0;
        public static const TOOL_PEN:int = (1 << 0);
        public static const TOOL_ERASER:int = (1 << 1);
        public static const TOOL_LINE:int = (1 << 2);
        public static const TOOL_FILLPEN:int = (1 << 3);
        public static const TOOL_HAND:int = (1 << 4);
        public static const TOOL_LASSO:int = (1 << 5);
        public static const TOOL_EYEDROPPER:int = (1 << 6);
        public static const TOOL_ZOOM:int = (1 << 7);
        public static const TOOL_ROTATE:int = (1 << 8);
        public static const TOOL_MOVE:int = (1 << 9);
        public static const TOOL_UNDO:int = (1 << 10);
        public static const TOOL_REDO:int = (1 << 11);
        public static const TOOL_MIRROR:int = (1 << 12);
        private static const TOOL_BOX_ON_DELAY_TIME:Number = 0.12;

        public static const toolBox:ToolMenuSet = new ToolMenuSet();
        public static const toolBox2:ToolMenuSet2 = new ToolMenuSet2();
        public static const toolOptionsBox:ToolOptionsSet = new ToolOptionsSet();

        public static var isToolBox2Showing:Boolean = false; // 툴박스가 오른쪽 클릭으로 켜졌을때 올려줌
        public static var nowTool:int = 1; // 현재 툴 번호
        public static var lastTool:int = TOOL_NONE; // 툴백업

        public static var selectedToolViewBitmap:Bitmap = new Bitmap();

        public static var isSharpLineON:Boolean = false; // 0.5픽셀어긋나게 안하고 완전히 정확하게 할때씀
        public static var isPenAirBrushON:Boolean = false;
        public static var lastEraserPosButton:SimpleButton = null; // 지우개 툴이 이동한 버튼 저장; 복원용

        public static function addHintEventToolBox2():void
        {
            toolBox2.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverToolBox2Hint);
        }

        public static function get toolBox2ONDelayTime():Number
        {
            return TOOL_BOX_ON_DELAY_TIME;
        }

        public static function updateSelectedToolViewBoxPos():void
        {
            const viewportRect:Rectangle = UIController.getViewportRect();

            selectedToolViewBitmap.x = viewportRect.x + viewportRect.width / 2 - selectedToolViewBitmap.width / 2;
            selectedToolViewBitmap.y = viewportRect.y + 20 * UITheme.getUIScale();
        }

        public static function getToolButtonFromToolIndex(toolIndex:*):SimpleButton
        {
            switch (toolIndex)
            {
                case TOOL_PEN:
                    return toolBox.toolPen;
                case TOOL_FILLPEN:
                    return toolBox.toolFillPen;
                case TOOL_ERASER:
                    return toolBox.toolEraser;
                case TOOL_EYEDROPPER:
                    return toolBox.toolEyedropper;
                case TOOL_LASSO:
                    return toolBox.toolLasso;
                case TOOL_MOVE:
                    return toolBox.toolMove;
                case TOOL_LINE:
                    return toolBox.toolLine;
                case TOOL_ZOOM:
                    return toolBox.toolZoomIn;
                case TOOL_ROTATE:
                    return toolBox.toolRotate;
                case TOOL_HAND:
                    return toolBox.toolHand;
                case TOOL_UNDO:
                    return toolBox.toolUndo;
                case TOOL_REDO:
                    return toolBox.toolRedo;
                case TOOL_MIRROR:
                    return toolBox.toolMirror;
            }

            return null;
        }

        public static function showNowToolIconToCursorTemp(toolIndex:int):void
        {
            if (SidebarController.isQuickSidebarActive)
            {
                return;
            }

            const toolButton:SimpleButton = getToolButtonFromToolIndex(toolIndex);

            if (toolButton === null)
            {
                return;
            }

            selectedToolViewBitmap.bitmapData = toolBox.getToolSelectViewBmpd(toolIndex, toolButton);
            updateSelectedToolViewBoxPos();
            Utils.showDisplayTargetAndFadeOut(selectedToolViewBitmap, 1.0, 1.0);
        }

        public static function isSelectedToolPenOrLine():Boolean
        {
            return nowTool === TOOL_PEN || nowTool === TOOL_LINE;
        }

        public static function isSelectedTool(tool:int):Boolean
        {
            return nowTool === tool;
        }

        public static function setSelectedTool(tool:int):void
        {
            nowTool = tool;
        }

        public static function resetLastTool():void
        {
            lastTool = TOOL_NONE;
        }

        public static function isLastTool(tool:int):Boolean
        {
            return lastTool === tool;
        }

        public static function setLastTool(tool:int):void
        {
            lastTool = tool;
        }

        public static function updateLastTool():void
        {
            if (lastTool === TOOL_NONE)
            {
                lastTool = nowTool;
            }
        }

        public static function selectPenToolIfNotDrawingTool(checkErase:Boolean):void
        {
            if (!(isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILLPEN)
                        || (checkErase && isSelectedTool(TOOL_ERASER))))
            {
                resetLastTool();
                selectPenTool();
                PenSizePreviewCursor.updateSizeAndShape();
            }
        }

        public static function onMouseOverToolBox2Hint(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;

            if (!target || target.alpha < 1.0)
            {
                return;
            }

            const hintStr:String = HintStrings.getHintFromTargetName(target.name);

            toolBox2.hint((hintStr === null) ? "Tools" : hintStr);
        }

        public static function updateToolOptionsTextBySelectedTool():void
        {
            var toolName:String = "Pen";
            const nt:uint = nowTool;

            if (isSelectedTool(TOOL_ERASER))
                toolName = "Eraser";
            else if (isSelectedTool(TOOL_LINE))
                toolName = "Line";
            else if (isSelectedTool(TOOL_FILLPEN))
                toolName = "FillPen";

            toolOptionsBox.hintText(toolName);
        }

        public static function showDrawToolHintSizeOpacity():void
        {
            var tooltype:String = "";
            var size:Number;
            var alpha:Number;

            if (isSelectedTool(TOOL_PEN))
            {
                tooltype = "Pen ";
                size = PenTool.penSizeList[PenTool.penSizeIndex];
                alpha = PenTool.penAlphaList[PenTool.penAlphaIndex];
            }
            else if (isSelectedTool(TOOL_LINE))
            {
                tooltype = "Line ";
                size = PenTool.penSizeList[PenTool.penSizeIndex];
                alpha = PenTool.penAlphaList[PenTool.penAlphaIndex];
            }
            else if (isSelectedTool(TOOL_FILLPEN))
            {
                tooltype = "Fill Pen ";
                size = 1;
                alpha = PenTool.penAlphaList[PenTool.penAlphaIndex];
            }
            else if (isSelectedTool(TOOL_ERASER))
            {
                tooltype = "Eraser ";
                size = PenTool.penSizeList[PenTool.eraserSizeIndex];
                alpha = PenTool.penAlphaList[PenTool.eraserAlphaIndex];
            }

            HintController.showMouseHintTemp(tooltype + size + "px, " + alpha * 100 + "%");
        }

        // opabox의 커서 위치와 색깔을 바꿈
        public static function updateOpacityCursorPos(index:uint):void
        {
            if (index === 0)
            {
                return;
            }

            const curButton:Sprite = toolOptionsBox.opaBox.getChildByName("alphaButton" + index) as Sprite;

            if (!curButton)
            {
                return;
            }

            toolOptionsBox.opaCursor.x = curButton.x;
            toolOptionsBox.opaCursor.y = curButton.y;
        }
        public static function applyDrawingToolAlpha(alpha:Number = 0.0):void
        {
            const index:int = PenTool.penAlphaList.indexOf(alpha);
            const eraseFlag:Boolean = isSelectedTool(TOOL_ERASER);

            updateOpacityCursorPos(index);

            if (eraseFlag === false)
            {
                PenTool.penAlpha = alpha;
                PenTool.penAlphaIndex = index;
            }
            else if (eraseFlag === true)
            {
                PenTool.eraserAlpha = alpha;
                PenTool.eraserAlphaIndex = index;
            }
        }

        public static function adjustDrawToolAlphaByShortcut(increase:Boolean):void
        {
            function setAlpha(alp:Number, size:uint):void
            {
                var index:Number = PenTool.penAlphaList.indexOf(alp);
                const len:uint = PenTool.penAlphaList.length - 1;

                if (increase)
                {
                    index++;

                    if (index > len)
                    {
                        index = len;
                    }
                }
                else
                {
                    index--;

                    if (index < 1)
                    {
                        index = 1;
                    }
                }

                applyDrawingToolAlpha(PenTool.penAlphaList[index]);
                showDrawToolHintSizeOpacity();
            }
            selectPenToolIfNotDrawingTool(true);

            if (isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILLPEN))
            {
                setAlpha(PenTool.penAlpha, PenTool.penSize);
            }
            else if (isSelectedTool(TOOL_ERASER))
            {
                setAlpha(PenTool.eraserAlpha, PenTool.eraserSize);
            }
        }

        public static function adjustDrawToolSizeByShortcut(increase:Boolean):void
        {
            if (isSelectedTool(TOOL_FILLPEN))
            {
                return;
            }

            const len:uint = PenTool.penSizeList.length - 1;

            function setSize(index:uint, alpha:Number):void
            {
                if (increase)
                {
                    index++;

                    if (index > len)
                    {
                        index = len;
                    }
                }
                else
                {
                    index--;

                    if (index < 1)
                    {
                        index = 1;
                    }
                }

                setDrawToolSize(index);
                showDrawToolHintSizeOpacity();

                PenSizePreviewCursor.updateSizeAndShape();
                PenSizePreviewCursor.updatePosAndVisibility();
            }

            selectPenToolIfNotDrawingTool(true);

            if (isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILLPEN))
            {
                setSize(PenTool.penSizeIndex, PenTool.penAlpha);
                // 이거 get set함수로 변환
                if (isPenAirBrushON && PenTool.penSize !== PenTool.airBrushSizeDrawMode)
                {
                    PenTool.airBrushSizeDrawMode = PenTool.penSize;
                }
            }
            else if (isSelectedTool(TOOL_ERASER))
            {
                setSize(PenTool.eraserSizeIndex, PenTool.eraserAlpha);

                if (PenTool.isEraserAirBrushON && PenTool.eraserSize !== PenTool.airBrushSizeDrawMode)
                {
                    PenTool.airBrushSizeDrawMode = PenTool.eraserSize;
                }
            }
        }

        public static function selectPenSizeButton(targetName:String):void
        {
            const numberOnly:String = targetName.substr(UITheme.NSIZE_BUTTON_PREFIX.length);
            const index:uint = parseInt(numberOnly);

            setDrawToolSize(index);
            PenSizePreviewCursor.updateSizeAndShape();

            if (isSelectedTool(TOOL_FILLPEN))
            {
                if (isPenAirBrushON && PenTool.penSize !== PenTool.airBrushSizeDrawMode)
                {
                    PenTool.airBrushSizeDrawMode = PenTool.penSize;
                }
            }
            else if (isSelectedToolPenOrLine())
            {
                if (isPenAirBrushON && PenTool.penSize !== PenTool.airBrushSizeDrawMode)
                {
                    PenTool.airBrushSizeDrawMode = PenTool.penSize;
                }
            }
            else if (isSelectedTool(TOOL_ERASER))
            {
                if (PenTool.isEraserAirBrushON && PenTool.eraserSize !== PenTool.airBrushSizeDrawMode)
                {
                    PenTool.airBrushSizeDrawMode = PenTool.eraserSize;
                }
            }
        }

        public static function startPenSmootingAdjustment():void
        {
            const minDist:Number = toolOptionsBox.penSmoothSlider.x + 1; // 펜 리스트에 흰색 선 시작과 끝 x좌표임
            const maxDist:Number = minDist + toolOptionsBox.penSmoothSlider.width - 1;
            const step:Number = PenTool.penSmoothSlideTotal;
            const div:Number = (maxDist - minDist) / step;

            const maxValue:Number = 0.85;
            const minValue:Number = 0.02;
            const stepValue:Number = (maxValue - minValue) / step;

            const airBrushFlag:Boolean = isSelectedToolPenOrLine() && isPenAirBrushON;
            const eraseAirBrushFlag:Boolean = isSelectedTool(TOOL_ERASER) && PenTool.isEraserAirBrushON;

            var oldValue:int = PenTool.penSmoothSlideValue;

            function onMouseUpPenSmoothing(e:MouseEvent):void
            {
                MouseState.endDrag("penSmoothing");
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpPenSmoothing);
                main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMovePenSmoothing);
            }

            function adjustPenSmoothingValue():void
            {
                var mx:Number = toolOptionsBox.penSmoothSliderWrapper.mouseX + toolOptionsBox.penSmoothSlider.x;

                if (mx < minDist)
                {
                    mx = minDist;
                }
                else if (mx > maxDist)
                {
                    mx = maxDist;
                }

                // 버튼을 기준으로 중간값으로
                const value:Number = Math.floor((mx - minDist) / div);

                if (oldValue !== value)
                {
                    const xpos:Number = value * div + minDist;

                    if (toolOptionsBox.penSmoothSliderCursor.x === xpos)
                        return;
                    toolOptionsBox.penSmoothSliderCursor.x = xpos;

                    if (value === 0)
                    {
                        PenTool.penSmoothValue = 0;
                    }
                    else
                    {
                        PenTool.penSmoothValue = maxValue - (value * stepValue);
                    }

                    PenTool.penSmoothSlideValue = value;
                    oldValue = value;
                    HintController.showBottomHint(HintStrings.getHintFromTargetName("penSmoothSliderWrapper"));
                }
            }

            function onMouseMovePenSmoothing(e:MouseEvent):void
            {
                adjustPenSmoothingValue();
            }
            adjustPenSmoothingValue();
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpPenSmoothing, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMovePenSmoothing);
            MouseState.beginDrag("penSmoothing", function ():void
                {
                    onMouseUpPenSmoothing(null);
                });
        }

        public static function setDrawToolSize(index:uint):void
        {
            const size:uint = PenTool.penSizeList[index];

            if (isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILLPEN))
            {
                PenTool.penSize = size;
                PenTool.penSizeIndex = index;
                PenSizePreviewCursor.updateCursorSize(PenTool.penSize);
            }
            else if (isSelectedTool(TOOL_ERASER))
            {
                PenTool.eraserSize = size;
                PenTool.eraserSizeIndex = index;
                PenSizePreviewCursor.updateCursorSize(PenTool.eraserSize);
            }

            toolOptionsBox.movePenSizeCursor(index);
        }

        public static function selectPenShapeButton(shapeFlag:Boolean):void
        {
            PenTool.penListShapeIsSqare = shapeFlag;

            if (isSelectedToolPenOrLine())
            {
                if (PenTool.penIsSquare !== shapeFlag)
                {
                    PenTool.penIsSquare = shapeFlag;
                }
            }
            else if (isSelectedTool(TOOL_ERASER))
            {
                if (PenTool.eraserIsSquare !== shapeFlag)
                {
                    PenTool.eraserIsSquare = shapeFlag;
                }
            }

            toolOptionsBox.updatePenShapeSet(shapeFlag);
            PenSizePreviewCursor.updateSizeAndShape();
        }

        // 단축키를  after tool mouse up에서 이전툴을 복구해줌
        public static function selectLastUsedTool():void
        {
            const lastToolSave:int = lastTool;

            if (lastToolSave === TOOL_NONE)
            {
                selectPenTool();
                PenSizePreviewCursor.updateSizeAndShape();
                return;
            }

            switch (lastToolSave)
            {
                case TOOL_PEN:
                    selectPenTool();
                    PenSizePreviewCursor.updateSizeAndShape();
                    break;
                case TOOL_FILLPEN:
                    selectFillPenTool();
                    break;
                case TOOL_ERASER:
                    selectEraserTool();
                    PenSizePreviewCursor.updateSizeAndShape();
                    break;
                case TOOL_LINE:
                    selectLineTool();
                    PenSizePreviewCursor.updateSizeAndShape();
                    break;
                case TOOL_EYEDROPPER:
                    EyeDropperTool.start();
                    break;
                case TOOL_LASSO:
                    selectLassoTool();
                    break;
                case TOOL_MOVE:
                    selectMoveTool();
                    break;
                case TOOL_ROTATE:
                    selectRotateTool();
                    break;
                case TOOL_ZOOM:
                    selectZoomTool();
                    break;
            }

            nowTool = lastToolSave;
            resetLastTool();
        }

        // 캔버스 영역을 누르면 현재 도구를 시작함 (캔버스 영역 안인지는 입력쪽에서 판단)
        public static function onCanvasMouseDown():void
        {
            switch (nowTool)
            {
                case TOOL_PEN:
                    if (CanvasLayers.isToolEnabledByLayerUnChecked())
                        PenTool.start();
                    break;
                case TOOL_FILLPEN:
                    if (CanvasLayers.isToolEnabledByLayerUnChecked())
                        FillPenTool.start();
                    break;
                case TOOL_ERASER:
                    if (CanvasLayers.isToolEnabledByLayerUnChecked())
                        PenTool.startWithEraserMode();
                    break;
                case TOOL_LINE:
                    if (CanvasLayers.isToolEnabledByLayerUnChecked())
                        LineTool.start();
                    break;
                case TOOL_LASSO:
                    LassoTool.startLassoSelection();
                    break;
                case TOOL_MOVE:
                    MoveTool.start();
                    break;
                    // 캔버스 조작
                case TOOL_ZOOM:
                    ZoomTool.start();
                    break;
                case TOOL_HAND:
                    HandTool.startInDrawMode();
                    break;
                case TOOL_ROTATE:
                    RotateTool.startInDrawMode();
                    break;
            }
        }

        public static function handleToolBoxClick(targetName:String):void
        {
            function onMouseUpToolBox(e:MouseEvent):void
            {
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpToolBox);

                if (ReplayState.isGeneratingCacheImages())
                {
                    return;
                }

                const upTargetName:String = e.target.name;

                if (upTargetName !== targetName)
                    return;

                switch (upTargetName)
                {
                    case "toolPen":
                        {
                            if (!isSelectedTool(TOOL_PEN))
                            {
                                selectPenTool();
                                PenSizePreviewCursor.updateSizeAndShape();
                            }
                        }
                        break;
                    case "toolFillPen":
                        {
                            if (!isSelectedTool(TOOL_FILLPEN))
                            {
                                selectFillPenTool();
                                PenSizePreviewCursor.updateSizeAndShape();
                            }
                        }
                        break;
                    case "toolEraser":
                        {
                            if (!isSelectedTool(TOOL_ERASER))
                            {
                                selectEraserTool();
                                PenSizePreviewCursor.updateSizeAndShape();
                            }
                        }
                        break;
                    case "toolLine":
                        {
                            if (!isSelectedTool(TOOL_LINE))
                            {
                                selectLineTool();
                                PenSizePreviewCursor.updateSizeAndShape();
                            }
                        }
                        break;
                    case "toolLasso":
                        {
                            if (!isSelectedTool(TOOL_LASSO))
                            {
                                selectLassoTool();
                            }
                        }
                        break;
                    case "toolEyedropper":
                        {
                            if (SidebarController.isQuickSidebarActive)
                            {
                                resetLastTool();
                                toolBox.moveToolCursor("toolEyedropper");
                            }
                            else if (!isSelectedTool(TOOL_EYEDROPPER))
                            {
                                EyeDropperTool.start();
                            }
                        }
                        break;
                    case "toolUndo":
                        {
                            if (!FOFOTimer.hasTimer("keyHoldRepeatTimer"))
                            {
                                UndoController.undo();
                            }
                        }
                        break;
                    case "toolRedo":
                        {
                            if (!FOFOTimer.hasTimer("keyHoldRepeatTimer"))
                            {
                                UndoController.redo();
                            }
                        }
                        break;
                    case "toolMirror":
                        {
                            CanvasView.mirrorCanvas();
                        }
                        break;
                    case "toolMove":
                        {
                            selectMoveTool();
                        }
                        break;
                    case "toolZoomIn":
                        {
                            CanvasView.viewport.zoomStep(true);
                        }
                        break;
                    case "toolZoomOut":
                        {
                            CanvasView.viewport.zoomStep(false);
                        }
                        break;
                    case "toolRefLayer":
                        {
                            if (SidebarController.isQuickSidebarActive)
                            {
                                SidebarController.deactivateQuickSidebar();
                            }

                            if (ReferenceLayerController.isRefLayerMenuON === false)
                            {
                                ReferenceLayerController.openRefLayerMenu();
                                // mouseY에서 main.stage.mouseY로 바꾸었는데 동작 이상하면 체크해야함
                                ReferenceLayerController.refLayerMenuBox.y = main.stage.mouseY - 60;
                            }
                            else
                            {
                                ReferenceLayerController.closeRefLayerMenu();
                            }
                        }
                        break;
                }
                PenSizePreviewCursor.updatePosAndVisibility();
            }
            // main.undo키 반복이 있어서 우선순위 1로 약간 높여줌
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpToolBox, false, InputPriority.STAGE_ROOT);
        }

        public static function selectPenTool(lineFlag:Boolean = false):void
        {
            setSelectedTool((lineFlag) ? TOOL_LINE : TOOL_PEN);
            toggleAirBrushCheckBox(isPenAirBrushON, true);
            setDrawToolSize(PenTool.penSizeIndex);
            applyDrawingToolAlpha(PenTool.penAlpha);
            moveEraserButtonToOtherTool((lineFlag) ? "toolLine" : "toolPen");
            toolBox.moveToolCursor((lineFlag) ? "toolLine" : "toolPen");
            updateToolOptionsTextBySelectedTool();
            toolOptionsBox.updatePenShapeSet(PenTool.penIsSquare);

            if (toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }

            toolOptionsBox.enablePenSmoothingSlider();
        }

        public static function selectLineTool():void
        {
            selectPenTool(true);
            toolOptionsBox.disablePenSmoothingSlider();
        }

        public static function selectEraserTool():void
        {
            setSelectedTool(TOOL_ERASER);
            toggleAirBrushCheckBox(PenTool.isEraserAirBrushON, false);
            setDrawToolSize(PenTool.eraserSizeIndex);
            applyDrawingToolAlpha(PenTool.eraserAlpha);

            if (ToolController.lastEraserPosButton)
            {
                ToolController.lastEraserPosButton.visible = true;
            }

            ToolController.lastEraserPosButton = null;
            toolBox2.toolEraser.visible = false;
            toolBox.moveToolCursor("toolEraser");
            updateToolOptionsTextBySelectedTool();
            toolOptionsBox.updatePenShapeSet(PenTool.eraserIsSquare);

            if (toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }

            toolOptionsBox.disablePenSmoothingSlider();
        }

        public static function selectFillPenTool():void
        {
            setSelectedTool(TOOL_FILLPEN);
            toolBox.moveToolCursor("toolFillPen");
            PenSizePreviewCursor.setVisible(false);
            updateOpacityCursorPos(PenTool.penAlphaIndex);
            toggleAirBrushCheckBox(isPenAirBrushON, true);
            toolOptionsBox.movePenSizeCursor(1);
            toolOptionsBox.setButtonsAlphaFillPenSelected(UITheme.OFFALPHA);
            moveEraserButtonToOtherTool("toolFillPen");
            updateToolOptionsTextBySelectedTool();
        }

        public static function selectMoveTool():void
        {
            updateToolOptionsTextBySelectedTool();
            setSelectedTool(TOOL_MOVE);
            toolBox.moveToolCursor("toolMove");

            if (toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }

            toolOptionsBox.enablePenSmoothingSlider();
        }

        public static function selectZoomTool():void
        {
            updateToolOptionsTextBySelectedTool();
            setSelectedTool(TOOL_ZOOM);
            toolBox.moveToolCursor("toolZoomIn", UIController.canvasInfoBox);

            if (toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }

            toolOptionsBox.enablePenSmoothingSlider();
        }

        public static function selectRotateTool():void
        {
            updateToolOptionsTextBySelectedTool();
            setSelectedTool(TOOL_ROTATE);
            toolBox.moveToolCursor("toolRotate", UIController.canvasInfoBox);

            if (toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }

            toolOptionsBox.enablePenSmoothingSlider();
        }

        public static function selectLassoTool():void
        {
            updateToolOptionsTextBySelectedTool();
            setSelectedTool(TOOL_LASSO);
            toolBox.moveToolCursor("toolLasso");
            moveEraserButtonToOtherTool("toolLasso");

            if (toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }

            toolOptionsBox.enablePenSmoothingSlider();
        }

        public static function moveEraserButtonToOtherTool(toolName:String):void
        {
            const nowButton2:SimpleButton = toolBox2.getChildByName(toolName) as SimpleButton;

            if (!nowButton2)
                return;

            if (lastEraserPosButton)
            {
                if (lastEraserPosButton.x !== nowButton2.x
                        || lastEraserPosButton.y !== nowButton2.y) // 위치가 다를 때에만 보여줌
                {
                    lastEraserPosButton.visible = true;
                }
            }

            lastEraserPosButton = nowButton2;
            nowButton2.visible = false;
            toolBox2.toolEraser.visible = true;
            toolBox2.toolEraser.x = nowButton2.x;
            toolBox2.toolEraser.y = nowButton2.y;
            Utils.setAsTopChild(toolBox2.toolEraser);
        }

        public static function handleToolKeyDown(keyCode:int):void
        {
            if (ReferenceLayerController.isRefLayerMenuON)
            {
                if (keyCode === InputManager.KEY.esc || keyCode === InputManager.KEY.backspace)
                {
                    ReferenceLayerController.closeRefLayerMenu();
                    return;
                }
            }

            switch (keyCode)
            {
                case InputManager.KEY.q:
                case InputManager.KEY.o:
                    {
                        setLastTool(TOOL_PEN);
                        selectFillPenTool();
                        showNowToolIconToCursorTemp(TOOL_FILLPEN);
                    }
                    break;
                case InputManager.KEY.t:
                    {
                        if (ReferenceLayerController.isRefLayerMenuON)
                        {
                            ReferenceLayerController.closeRefLayerMenu();
                        }
                        else
                        {
                            ReferenceLayerController.openRefLayerMenu();
                        }
                    }
                    break;
                case InputManager.KEY.a:
                case InputManager.KEY.l:
                    {
                        CanvasView.mirrorCanvas();
                        showNowToolIconToCursorTemp(TOOL_MIRROR);
                    }
                    break;
                case InputManager.KEY.c:
                case InputManager.KEY.m:
                    {
                        if (ColorPickerController.colorPickerBox.scratchPad.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                        {
                            if (ColorPickerController.colorPickerBox.scratchPad.visible)
                            {
                                ColorPickerController.showPickColorScratchPad();
                            }
                        }
                        else if (!isSelectedTool(TOOL_EYEDROPPER))
                        {
                            EyeDropperTool.start();

                            if (isSelectedTool(TOOL_EYEDROPPER))
                            {
                                showNowToolIconToCursorTemp(TOOL_EYEDROPPER);
                            }
                        }
                    }
                    break;
                case InputManager.KEY.r:
                case InputManager.KEY.y:
                    {
                        if (!isSelectedTool(TOOL_LASSO))
                        {
                            updateLastTool();
                            selectLassoTool();
                            showNowToolIconToCursorTemp(TOOL_LASSO);
                        }
                    }
                    break;
                case InputManager.KEY.space:
                    {
                        if (!isSelectedTool(TOOL_HAND))
                        {
                            updateLastTool();
                            setSelectedTool(TOOL_HAND);
                            showNowToolIconToCursorTemp(TOOL_HAND);
                        }
                    }
                    break;
                case InputManager.KEY.d:
                case InputManager.KEY.j:
                    {
                        if (!isSelectedTool(TOOL_ERASER))
                        {
                            updateLastTool();
                            selectEraserTool();
                            PenSizePreviewCursor.updateSizeAndShape();
                            showNowToolIconToCursorTemp(TOOL_ERASER);
                        }
                    }
                    break;
                case InputManager.KEY.s:
                case InputManager.KEY.k:
                    {
                        if (!isSelectedTool(TOOL_ROTATE))
                        {
                            updateLastTool();
                            selectRotateTool();
                            showNowToolIconToCursorTemp(TOOL_ROTATE);
                        }
                    }
                    break;
                case InputManager.KEY.e:
                case InputManager.KEY.u:
                    {
                        if (!isSelectedTool(TOOL_MOVE))
                        {
                            updateLastTool();
                            selectMoveTool();
                            showNowToolIconToCursorTemp(TOOL_MOVE);
                        }
                    }
                    break;
                case InputManager.KEY.w:
                case InputManager.KEY.i:
                    {
                        if (!isSelectedTool(TOOL_ZOOM))
                        {
                            updateLastTool();
                            selectZoomTool();
                            showNowToolIconToCursorTemp(TOOL_ZOOM);
                        }
                    }
                    break;
                case InputManager.KEY.shift:
                    {
                        if (!isSelectedTool(TOOL_LINE))
                        {
                            updateLastTool();
                            selectLineTool();
                            PenSizePreviewCursor.updateSizeAndShape();
                        }
                    }
                    break;
                case InputManager.KEY.esc:
                case InputManager.KEY.del:
                case InputManager.KEY.backspace:
                    {
                        if (FileManager.canCreateNewFile())
                        {
                            FileManager.createNewFile(true);
                        }
                    }
                    break;
            }

            PenSizePreviewCursor.updatePosAndVisibility();
        }

        public static function updateToolBoxMousePos(target:SimpleButton):void
        {
            // 아이콘 중앙으로 맞추어줌
            if (!target)
            {
                return;
            }

            if (target.parent === toolBox2)
            {
                toolBox2.updateLastUsedToolPos(target.name);
            }
        }

        public static function closeToolBox2(ignoreResizeButtonVisible:Boolean = false):void
        {
            if (!isToolBox2Showing)
            {
                return;
            }

            DrawModeInput.removeToolBox2Events();
            isToolBox2Showing = false;
            toolBox2.visible = false;

            if (!ignoreResizeButtonVisible)
            {
                CanvasResizer.showButtonsWithDelay(false);
            }
        }

        public static function handleToolBox2Closing(target:DisplayObject):void
        {
            const targetName:String = target.name;

            if (targetName !== null && targetName.indexOf("tool") !== -1)
            {
                updateToolBoxMousePos(target as SimpleButton);
            }

            switch (targetName)
            {
                case "toolQuickSidebar":
                    {
                        SidebarController.activeQuickSideBar(false);
                    }
                    break;
                case "toolPen":
                    {
                        selectPenTool();
                        PenSizePreviewCursor.updateSizeAndShape();
                        showNowToolIconToCursorTemp(TOOL_PEN);
                    }
                    break;
                case "toolFillPen":
                    {
                        selectFillPenTool();
                        PenSizePreviewCursor.updateSizeAndShape();
                        showNowToolIconToCursorTemp(TOOL_FILLPEN);
                    }
                    break;
                case "toolEraser":
                    {
                        selectEraserTool();
                        PenSizePreviewCursor.updateSizeAndShape();
                        showNowToolIconToCursorTemp(TOOL_ERASER);
                    }
                    break;
                case "toolLine":
                    {
                        selectLineTool();
                        PenSizePreviewCursor.updateSizeAndShape();
                        showNowToolIconToCursorTemp(TOOL_LINE);
                    }
                    break;
                case "toolLasso":
                    {
                        selectLassoTool();
                        showNowToolIconToCursorTemp(TOOL_LASSO);
                    }
                    break;
                case "toolEyedropper":
                    {
                        if (!isSelectedTool(TOOL_EYEDROPPER))
                        {
                            EyeDropperTool.start();
                            showNowToolIconToCursorTemp(TOOL_EYEDROPPER);
                        }
                    }
                    break;
                case "toolUndo":
                    {
                        UndoController.undo();
                        showNowToolIconToCursorTemp(TOOL_UNDO);
                    }
                    break;
                case "toolRedo":
                    {
                        UndoController.redo();
                        showNowToolIconToCursorTemp(TOOL_REDO);
                    }
                    break;
                case "toolMirror":
                    {
                        CanvasView.mirrorCanvas();
                        showNowToolIconToCursorTemp(TOOL_MIRROR);
                    }
                    break;
                case "toolRefLayer":
                    {
                        ReferenceLayerController.openRefLayerMenu();
                    }
                    break;
            }

            closeToolBox2();
        }

        public static function onMouseOverToolBox2(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;

            if (!target)
            {
                return;
            }

            const targetName:String = target.name;

            if (targetName && targetName.indexOf("tool") !== -1)
            {
                toolBox2.setMouseOverTarget(target);
            }
        }

        public static function handleToolBoxMouseDown(target:DisplayObject):Boolean
        {
            if (InputManager.isKeyPressed() && !SidebarController.isQuickSidebarActive || !target)
                return true;
            const targetName:String = target.name;

            switch (targetName)
            {
                case "toolRotate":
                    {
                        RotateTool.startInDrawMode();
                    }
                    return true;
                case "toolUndo":
                    {
                        InputManager.startKeyRepeat(false, UndoController.undo);
                        InputManager.startKeyRepeatStopTimerOnMouseLeave(target);
                        handleToolBoxClick(targetName);
                    }
                    return true;
                case "toolRedo":
                    {
                        InputManager.startKeyRepeat(false, UndoController.redo);
                        InputManager.startKeyRepeatStopTimerOnMouseLeave(target);
                        handleToolBoxClick(targetName);
                    }
                    return true;
                case "toolZoomIn":
                case "toolZoomOut":
                case "toolPen":
                case "toolFillPen":
                case "toolEraser":
                case "toolLasso":
                case "toolEyedropper":
                case "toolUndo":
                case "toolRedo":
                case "toolMirror":
                case "toolLine":
                case "toolMove":
                case "toolRotate":
                case "toolRefLayer":
                case "toolBoxBG":
                case "toolMask":
                    {
                        // setTopChildIndex(toolBox);
                        handleToolBoxClick(targetName);
                    }
                    return true;
            }

            return false;
        }

        public static function openToolBox2():void
        {
            PenSizePreviewCursor.setCursorInVisibleFlag(true);
            PenSizePreviewCursor.setVisible(false);
            var pos:Point = toolBox2.getLastUsedToolPos();
            const scale:Number = UITheme.getUIScale();

            toolBox2.x = Math.floor(main.stage.mouseX - pos.x * scale);
            toolBox2.y = Math.floor(main.stage.mouseY - pos.y * scale);
            toolBox2.alpha = 1.0;
            toolBox2.visible = true;
            isToolBox2Showing = true;
            CanvasResizer.showButtonsWithDelay(true);
            Utils.setAsTopChild(toolBox2);
            DrawModeInput.addToolBox2Events();
            FOFOTimer.addByName("toolBox2HideCheckTimer", 0.1, true, function ():Boolean
                {
                    if (!isToolBox2Showing)
                    {
                        return false;
                    }

                    if (CanvasResizer.isButtonVisible())
                    {
                        if (!toolBox2.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                        {
                            toolBox2.alpha = 0.6;
                        }
                        else if (toolBox2.alpha < 1.0)
                        {
                            toolBox2.alpha = 1.0;
                        }
                    }

                    return true;
                });
        }

        // 레이어 체크 버튼과 툴 버튼 활성 상태를 CanvasLayers.checkedLayer에 맞춤
        public static function updateLayerCheckButtons():void
        {
            const checked:int = CanvasLayers.checkedLayer;
            toolOptionsBox.layer1CheckedButton.visible = (checked === 1);
            toolOptionsBox.layer1UncheckedButton.visible = (checked !== 1);
            toolOptionsBox.layer2CheckedButton.visible = (checked === 2);
            toolOptionsBox.layer2UncheckedButton.visible = (checked !== 2);
            if (checked !== 0)
            {
                toolBox.setToolButtonsForCheckedLayerON();
                toolBox2.setToolButtonsForCheckedLayerON();
            }
            else
            {
                toolBox.setToolButtonsForCheckedLayerOFF();
                toolBox2.setToolButtonsForCheckedLayerOFF();
            }
        }

        // 선택한 레이어 버튼 강조, onlyViewFlag면 숨겨진 다른 레이어 버튼에 빨간 줄 표시
        public static function updateLayerSelectButtons(layer:int, onlyViewFlag:Boolean):void
        {
            toolOptionsBox.setSelectLayerButtonActiveAlpha(layer);
            if (!onlyViewFlag)
            {
                toolOptionsBox.removeLayerInvisibleLine();
            }
            else if (layer === 1)
            {
                toolOptionsBox.moveLayerInvisibleLineToLayer2();
            }
            else
            {
                toolOptionsBox.moveLayerInvisibleLineToLayer1();
            }
        }

        public static function setLayerMergeButtonEnabled(enabled:Boolean):void
        {
            toolOptionsBox.layerMergeButton.alpha = (enabled) ? 1.0 : UITheme.OFFALPHA;
        }

        // 스왑 버튼이 깜빡이는 동안(playLayerSwapEffect)은 스왑을 막음
        public static function isLayerSwapButtonReady():Boolean
        {
            return toolOptionsBox.layerSwapButton.alpha >= 1.0;
        }

        public static function flickLayerSwapButton():void
        {
            playLayerSwapEffect(toolOptionsBox.layerSwapButton);
        }

        public static function playLayerSwapEffect(target:DisplayObject):void
        {
            target.alpha = UITheme.OFFALPHA;
            FOFOTimer.addByName("layerSwapFlickEffect", 0.5, false, function ():void
                {
                    target.alpha = 1.0;
                });
        }

        public static function handlePenOptionsBoxMouseDown(target:DisplayObject):Boolean
        {
            if (isToolBox2Showing)
            {
                return true;
            }

            const targetName:String = target.name;

            if (target.alpha === UITheme.OFFALPHA)
            {
                return true;
            }

            if (targetName.indexOf(UITheme.ALPHA_BUTTON_PREFIX) == 0)
            {
                ToolController.onOpacityButtonDown(targetName);
                selectPenToolIfNotDrawingTool(true);
                return true;
            }

            if (targetName.indexOf(UITheme.NSIZE_BUTTON_PREFIX) == 0)
            {
                if (!isSelectedTool(TOOL_FILLPEN))
                {
                    selectPenToolIfNotDrawingTool(true);
                    onPenSizeButtonDown(targetName);
                }
                return true;
            }

            switch (targetName)
            {
                case "penSmoothSliderWrapper":
                    {
                        if (nowTool !== TOOL_PEN)
                        {
                            return true;
                        }

                        selectPenToolIfNotDrawingTool(true);
                        startPenSmootingAdjustment();
                    }
                    return true;

                case "shapeRect":
                    {
                        if (!isSelectedTool(TOOL_FILLPEN))
                        {
                            selectPenToolIfNotDrawingTool(true);
                            selectPenShapeButton(true);
                        }
                    }
                    return true;
                case "shapeCircle":
                    {
                        if (!isSelectedTool(TOOL_FILLPEN))
                        {
                            selectPenToolIfNotDrawingTool(true);
                            selectPenShapeButton(false);
                        }
                    }
                    return true;
                case "layer1CheckedButton":
                case "layer1UncheckedButton":
                    {
                        CanvasLayers.selectLayer1(false);
                        CanvasLayers.toggleLayer1Check();
                    }
                    return true;
                case "layer2CheckedButton":
                case "layer2UncheckedButton":
                    {
                        CanvasLayers.selectLayer2(false);
                        CanvasLayers.toggleLayer2Check();
                    }
                    return true;
                case "layer1SelectButton":
                    {
                        if (CanvasLayers.isLayer2Selected)
                        {
                            CanvasLayers.selectLayer1(false);
                        }
                        else
                        {
                            CanvasLayers.selectLayer1(DrawCanvas.canvasLayer2Bitmap.visible);
                            HintController.showMouseHintLayerVisible();
                        }

                        if (CanvasLayers.checkedLayer === 2)
                        {
                            CanvasLayers.toggleLayer2Check();
                        }
                    }
                    return true;
                case "layer2SelectButton":
                    {
                        if (!CanvasLayers.isLayer2Selected)
                        {
                            CanvasLayers.selectLayer2(false);
                        }
                        else
                        {
                            CanvasLayers.selectLayer2(DrawCanvas.canvasLayer1Bitmap.visible);
                            HintController.showMouseHintLayerVisible();
                        }

                        if (CanvasLayers.checkedLayer === 1)
                        {
                            CanvasLayers.toggleLayer1Check();
                        }
                    }
                    return true;
                case "layerMergeButton":
                case "layerSwapButton":
                    {
                        if (isToolBox2Showing || target.alpha < 1.0)
                        {
                            return true;
                        }

                        InputManager.handleMouseClickStage(targetName, DrawModeInput.onClickDrawModeButton);
                    }
                    return true;
                case "sharpLineButtonWrapper":
                case "sharpLineOFFButton":
                case "sharpLineONButton":
                case "sharpLineText":
                    {
                        if (toolOptionsBox.sharpLineButtonWrapper.alpha === 1.0)
                        {
                            selectPenToolIfNotDrawingTool(true);
                            toggleSharpLine(!isSharpLineON);
                        }
                    }
                    return true;
                case "airBrushButtonWrapper":
                case "airBrushOFFButton":
                case "airBrushONButton":
                case "airBrushText":
                    {
                        if (toolOptionsBox.airBrushButtonWrapper.alpha === 1.0)
                        {
                            selectPenToolIfNotDrawingTool(true);

                            if (isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILLPEN))
                            {
                                togglePenAirBrushButton(!isPenAirBrushON);
                            }
                            else if (isSelectedTool(TOOL_ERASER))
                            {
                                toggleEraseAirBrushButton(!PenTool.isEraserAirBrushON);
                            }
                        }
                    }
                    return true;
            }

            return false;
        }

        public static function toggleSharpLine(flag:Boolean):void
        {
            isSharpLineON = flag;
            toolOptionsBox.sharpLineOFFButton.visible = flag;
            toolOptionsBox.sharpLineONButton.visible = !flag;
            PenSizePreviewCursor.updateSizeAndShape();
        }

        public static function getSharpLinePosOffset(size:Number):Number
        {
            return (isSharpLineON) ? (size % 2.0 === 0) ? 0.0 : 0.5
                : (size % 2.0 === 0) ? 0.5 : 0.0;
        }

        public static function toggleSharpLineByShortcut():void
        {
            toggleSharpLine(!isSharpLineON);

            if (isSharpLineON)
            {
                HintController.showMouseHintTemp("Sharp line ON");
            }
            else
            {
                HintController.showMouseHintTemp("Sharp line OFF");
            }
        }

        public static function togglePenAirBrushButtonShortCut():void
        {
            isPenAirBrushON = !isPenAirBrushON;
            toggleAirBrushCheckBox(isPenAirBrushON, true);
            if (isPenAirBrushON)
                HintController.showMouseHintTemp("Pen Air brush ON");
            else
                HintController.showMouseHintTemp("Pen Air brush OFF");
        }

        public static function togglePenAirBrushButton(flag:Boolean):void
        {
            isPenAirBrushON = flag;
            toggleAirBrushCheckBox(flag, true);
        }

        public static function toggleAirBrushCheckBox(flag:Boolean, penFlag:Boolean):void
        {
            toolOptionsBox.airBrushOFFButton.visible = flag;
            toolOptionsBox.airBrushONButton.visible = !flag;

            if (flag)
            {
                PenTool.airBrushSizeDrawMode = (penFlag) ? PenTool.penSize : PenTool.eraserSize;
                toolOptionsBox.blurShapeSetON();
            }
            else if (PenTool.airBrushSizeDrawMode !== 0)
            {
                PenTool.airBrushSizeDrawMode = 0;
                StrokeBuffer.canvasDrawLayerChild.filters = [];
                toolOptionsBox.blurShapeSetOFF();
            }
        }

        public static function toggleEraseAirBrushButtonShortCut():void
        {
            PenTool.isEraserAirBrushON = !PenTool.isEraserAirBrushON;
            toggleAirBrushCheckBox(PenTool.isEraserAirBrushON, false);
            if (PenTool.isEraserAirBrushON)
                HintController.showMouseHintTemp("Eraser Air brush ON");
            else
                HintController.showMouseHintTemp("Eraser Air brush OFF");
        }

        public static function toggleEraseAirBrushButton(flag:Boolean):void
        {
            PenTool.isEraserAirBrushON = flag;
            toggleAirBrushCheckBox(flag, false);
        }

        public static function setDrawingToolOpacity(targetName:String):void
        {
            const number:String = targetName.substr(UITheme.ALPHA_BUTTON_PREFIX.length);
            const index:int = parseInt(number);
            ToolController.applyDrawingToolAlpha(PenTool.penAlphaList[index]);
        }

        // opabox 버튼을 눌렀을때 즉시 적용하고, 누른채 다른 버튼 위로 끌면 따라서 선택함
        public static function onOpacityButtonDown(targetName:String):void
        {
            setDrawingToolOpacity(targetName);
            startOptionButtonDrag(toolOptionsBox.opaBox, UITheme.ALPHA_BUTTON_PREFIX, targetName, setDrawingToolOpacity);
        }

        // 펜 크기 버튼을 눌렀을때 즉시 적용하고, 누른채 다른 버튼 위로 끌면 따라서 선택함
        public static function onPenSizeButtonDown(targetName:String):void
        {
            selectPenSizeButton(targetName);
            startOptionButtonDrag(toolOptionsBox.penSizeBox, UITheme.NSIZE_BUTTON_PREFIX, targetName, selectPenSizeButton);
        }

        private static var isOptionButtonDragging:Boolean = false;
        private static var optionDragBox:Sprite = null;
        private static var optionDragPrefix:String = "";
        private static var optionDragApply:Function = null;
        private static var lastDragOptionButton:String = "";

        private static function startOptionButtonDrag(box:Sprite, prefix:String, startButtonName:String, apply:Function):void
        {
            if (isOptionButtonDragging)
            {
                return;
            }

            isOptionButtonDragging = true;
            optionDragBox = box;
            optionDragPrefix = prefix;
            optionDragApply = apply;
            lastDragOptionButton = startButtonName;

            box.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverOptionButtonDrag);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, endOptionButtonDrag, false, InputPriority.DEFAULT);
            main.stage.addEventListener(Event.MOUSE_LEAVE, endOptionButtonDrag);
            MouseState.beginDrag("optionButton", cancelOptionButtonDrag);
        }

        // 포커스를 잃으면(alt+tab 등) mouseUp이 안 오므로 MouseState.finishAllDrags가 호출함
        private static function cancelOptionButtonDrag():void
        {
            if (isOptionButtonDragging)
            {
                endOptionButtonDrag(null);
            }
        }

        private static function onMouseOverOptionButtonDrag(e:MouseEvent):void
        {
            if (!e.buttonDown)
            {
                endOptionButtonDrag(e);
                return;
            }

            const target:DisplayObject = e.target as DisplayObject;

            if (!target || target.name === lastDragOptionButton || target.name.indexOf(optionDragPrefix) !== 0)
            {
                return;
            }

            lastDragOptionButton = target.name;
            optionDragApply(target.name);
        }

        private static function endOptionButtonDrag(e:Event):void
        {
            MouseState.endDrag("optionButton");
            isOptionButtonDragging = false;

            optionDragBox.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOverOptionButtonDrag);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, endOptionButtonDrag);
            main.stage.removeEventListener(Event.MOUSE_LEAVE, endOptionButtonDrag);
            optionDragBox = null;
            optionDragApply = null;
        }
    }
}
