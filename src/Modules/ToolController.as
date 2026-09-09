package Modules
{
    import Symbols.ToolMenuSet;
    import Symbols.ToolMenuSet2;
    import Symbols.FillPenMenuSet;
    import Symbols.ToolOptionsSet;
    import Symbols.EyedropperLensSet;
    import flash.geom.Rectangle;
    import flash.display.Bitmap;
    import flash.display.SimpleButton;
    import flash.events.MouseEvent;
    import flash.display.DisplayObject;
    import Modules.Tools.PenTool;
    import flash.display.Sprite;
    import Modules.Tools.LassoTool;
    import flash.events.KeyboardEvent;
    import flash.geom.Point;

    public class ToolController
    {
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

        public static const toolBox:ToolMenuSet = new ToolMenuSet();
        public static const toolBox2:ToolMenuSet2 = new ToolMenuSet2();
        public static const toolOptionsBox:ToolOptionsSet = new ToolOptionsSet();

        public static var isToolBox2Showing:Boolean = false; // 툴박스가 오른쪽 클릭으로 켜졌을때 올려줌
        public static var nowTool:int = 1; // 현재 툴 번호
        public static var lastTool:int = TOOL_NONE; // 툴백업
        public static var selectedToolViewBitmap:Bitmap = new Bitmap();

        public static var isSharpLineON:Boolean = false; // 0.5픽셀어긋나게 안하고 완전히 정확하게 할때씀
        public static var isPenAirBrushON:Boolean = false;

        public static function updateSelectedToolViewBoxPos():void
        {
            const viewportRect:Rectangle = MainUIController.getViewportRect();
            selectedToolViewBitmap.x = viewportRect.x + viewportRect.width / 2 - selectedToolViewBitmap.width / 2;
            selectedToolViewBitmap.y = viewportRect.y + 20 * Global.getUIScale();
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
            main.startAlphaFadeOut(selectedToolViewBitmap, 1.0, 1.0);
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
                main.updatePenSizeCursor();
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
            MainUI.showMouseHintTemp(tooltype + size + "px, " + alpha * 100 + "%");
        }

        // opabox의 커서 위치와 색깔을 바꿈
        public static function updateOpacityCursorPos(index:int):void
        {
            if (index <= 0)
                return;
            const curButton:Sprite = toolOptionsBox.opaBox.getChildByName("alphaButton" + index) as Sprite;
            if (!curButton)
                return;
            toolOptionsBox.opaCursor.x = curButton.x;
            toolOptionsBox.opaCursor.y = curButton.y;
        }

        public static function updateDrawToolAlpha(alpha:Number = 0.0):void
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
                updateDrawToolAlpha(PenTool.penAlphaList[index]);
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
                main.updatePenSizeCursor();
                showDrawToolHintSizeOpacity();
                main.penCursorManager.checkCursorVisibility();
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
            const numberOnly:String = targetName.substr(11, targetName.length);
            const index:uint = parseInt(numberOnly);
            setDrawToolSize(index);
            main.updatePenSizeCursor();
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
            CanvasController.isMouseDragging = true;
            function onMouseUpPenSmoothing(e:MouseEvent):void
            {
                CanvasController.isMouseDragging = false;
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpPenSmoothing);
                main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMovePenSmoothing);
            }
            function adjustPenSmoothingValue():void
            {
                var mx:Number = toolOptionsBox.penSmoothSliderWapper.mouseX + toolOptionsBox.penSmoothSlider.x;
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
                    MainUI.showBottomHint(HintStrings.getHintFromTargetName("penSmoothSliderWapper"));
                }
            }
            function onMouseMovePenSmoothing(e:MouseEvent):void
            {
                adjustPenSmoothingValue();
            }
            adjustPenSmoothingValue();
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpPenSmoothing);
            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMovePenSmoothing);
        }

        public static function setDrawToolSize(index:uint):void
        {
            const size:uint = PenTool.penSizeList[index];
            if (isSelectedToolPenOrLine() || isSelectedTool(TOOL_FILLPEN))
            {
                PenTool.penSize = size;
                PenTool.penSizeIndex = index;
                main.penCursorManager.updateCursorSize(PenTool.penSize);
            }
            else if (isSelectedTool(TOOL_ERASER))
            {
                PenTool.eraserSize = size;
                PenTool.eraserSizeIndex = index;
                main.penCursorManager.updateCursorSize(PenTool.eraserSize);
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
            main.updatePenSizeCursor();
        }

        // 단축키를  after tool mouse up에서 이전툴을 복구해줌
        public static function selectLastUsedTool():void
        {
            const lastToolSave:int = lastTool;
            if (lastToolSave === TOOL_NONE)
            {
                selectPenTool();
                main.updatePenSizeCursor();
                return;
            }
            switch (lastToolSave)
            {
                case TOOL_PEN:
                    selectPenTool();
                    main.updatePenSizeCursor();
                    break;
                case TOOL_FILLPEN:
                    selectFillPenTool();
                    break;
                case TOOL_ERASER:
                    selectEraseTool();
                    main.updatePenSizeCursor();
                    break;
                case TOOL_LINE:
                    selectLineTool();
                    main.updatePenSizeCursor();
                    break;
                case TOOL_EYEDROPPER:
                    main.eyeDropperTool();
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

        public static function handleToolBoxClick(targetName:String):void
        {
            function onMouseUpToolBox(e:MouseEvent):void
            {
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpToolBox);
                if (main.isGeneratingCacheImages())
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
                                main.updatePenSizeCursor();
                            }
                        }
                        break;
                    case "toolFillPen":
                        {
                            if (!isSelectedTool(TOOL_FILLPEN))
                            {
                                selectFillPenTool();
                                main.updatePenSizeCursor();
                            }
                        }
                        break;
                    case "toolEraser":
                        {
                            if (!isSelectedTool(TOOL_ERASER))
                            {
                                selectEraseTool();
                                main.updatePenSizeCursor();
                            }
                        }
                        break;
                    case "toolLine":
                        {
                            if (!isSelectedTool(TOOL_LINE))
                            {
                                selectLineTool();
                                main.updatePenSizeCursor();
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
                                main.eyeDropperTool();
                            }
                        }
                        break;
                    case "toolUndo":
                        {
                            if (!FOFOTimer.hasTimer("keyHoldRepeatTimer"))
                            {
                                main.undo();
                            }
                        }
                        break;
                    case "toolRedo":
                        {
                            if (!FOFOTimer.hasTimer("keyHoldRepeatTimer"))
                            {
                                main.redo();
                            }
                        }
                        break;
                    case "toolMirror":
                        {
                            CanvasController.mirrorCanvas();
                        }
                        break;
                    case "toolMove":
                        {
                            selectMoveTool();
                        }
                        break;
                    case "toolZoomIn":
                        {
                            CanvasController.zoomInCanvas(true, false);
                        }
                        break;
                    case "toolZoomOut":
                        {
                            CanvasController.zoomInCanvas(false, false);
                        }
                        break;
                    case "toolRefLayer":
                        {
                            if (SidebarController.isQuickSidebarActive)
                                SidebarController.deactivateQuickSidebar();
                            if (ReferenceLayerController.isRefLayerMenuON === false)
                            {
                                ReferenceLayerController.openRefLayerMenu();
                                // mouseY에서 main.stage.mouseY로 바꾸었는데 동작 이상하면 체크해야함
                                ReferenceLayerController.refLayerMenuBox.y = main.stage.mouseY - 60;
                            }
                        }
                        break;
                }
            }
            // main.undo키 반복이 있어서 우선순위 1로 약간 높여줌
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpToolBox, false, 1);
        }

        public static function selectPenTool(lineFlag:Boolean = false):void
        {
            setSelectedTool((lineFlag) ? TOOL_LINE : TOOL_PEN);
            toggleAirBrushCheckBox(isPenAirBrushON, true);
            setDrawToolSize(PenTool.penSizeIndex);
            updateDrawToolAlpha(PenTool.penAlpha);
            updateOpacityCursorPos(PenTool.penAlphaIndex);
            moveEraserButtonToOtherTool((lineFlag) ? "toolLine" : "toolPen");
            toolBox.moveToolCursor((lineFlag) ? "toolLine" : "toolPen");
            updateToolOptionsTextBySelectedTool();
            toolOptionsBox.updatePenShapeSet(PenTool.penIsSquare);
            main.penCursorManager.check();
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
        public static function selectEraseTool():void
        {
            setSelectedTool(TOOL_ERASER);
            toggleAirBrushCheckBox(PenTool.isEraserAirBrushON, false);
            setDrawToolSize(PenTool.eraserSizeIndex);
            updateDrawToolAlpha(PenTool.eraserAlpha);
            updateOpacityCursorPos(PenTool.eraserAlphaIndex);
            if (main.lastEraserPosButton)
            {
                main.lastEraserPosButton.visible = true;
            }
            main.lastEraserPosButton = null;
            toolBox2.toolEraser.visible = false;
            toolBox.moveToolCursor("toolEraser");
            updateToolOptionsTextBySelectedTool();
            toolOptionsBox.updatePenShapeSet(PenTool.eraserIsSquare);
            main.penCursorManager.check();
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
            CanvasController.penSizePreviewCursor.visible = false;
            updateOpacityCursorPos(PenTool.penAlphaIndex);
            toggleAirBrushCheckBox(isPenAirBrushON, true);
            toolOptionsBox.movePenSizeCursor(1);
            toolOptionsBox.setButtonsAlphaFillPenSelected(Global.OFFALPHA);
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
            toolBox.moveToolCursor("toolZoomIn", CanvasController.canvasInfoBox);
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
            toolBox.moveToolCursor("toolRotate", CanvasController.canvasInfoBox);
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
            if (main.lastEraserPosButton)
            {
                if (main.lastEraserPosButton.x !== nowButton2.x
                        || main.lastEraserPosButton.y !== nowButton2.y) // 위치가 다를 때에만 보여줌
                {
                    main.lastEraserPosButton.visible = true;
                }
            }
            main.lastEraserPosButton = nowButton2;
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
                if (keyCode === main.KEY.esc || keyCode === main.KEY.backspace)
                {
                    ReferenceLayerController.closeRefLayerMenu();
                    return;
                }
            }
            switch (keyCode)
            {
                case main.KEY.q:
                case main.KEY.o:
                    {
                        setLastTool(TOOL_PEN);
                        selectFillPenTool();
                        showNowToolIconToCursorTemp(TOOL_FILLPEN);
                    }
                    break;
                case main.KEY.t:
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
                case main.KEY.a:
                case main.KEY.l:
                    {
                        CanvasController.mirrorCanvas();
                        showNowToolIconToCursorTemp(TOOL_MIRROR);
                    }
                    break;
                case main.KEY.c:
                case main.KEY.m:
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
                            main.eyeDropperTool();
                            showNowToolIconToCursorTemp(TOOL_EYEDROPPER);
                        }
                    }
                    break;
                case main.KEY.r:
                case main.KEY.y:
                    {
                        if (!isSelectedTool(TOOL_LASSO))
                        {
                            updateLastTool();
                            selectLassoTool();
                            showNowToolIconToCursorTemp(TOOL_LASSO);
                        }
                    }
                    break;
                case main.KEY.space:
                    {
                        if (!isSelectedTool(TOOL_HAND))
                        {
                            updateLastTool();
                            setSelectedTool(TOOL_HAND);
                            showNowToolIconToCursorTemp(TOOL_HAND);
                        }
                    }
                    break;
                case main.KEY.d:
                case main.KEY.j:
                    {
                        if (!isSelectedTool(TOOL_ERASER))
                        {
                            updateLastTool();
                            selectEraseTool();
                            main.updatePenSizeCursor();
                            showNowToolIconToCursorTemp(TOOL_ERASER);
                        }
                    }
                    break;
                case main.KEY.s:
                case main.KEY.k:
                    {
                        if (!isSelectedTool(TOOL_ROTATE))
                        {
                            updateLastTool();
                            selectRotateTool();
                            showNowToolIconToCursorTemp(TOOL_ROTATE);
                        }
                    }
                    break;
                case main.KEY.e:
                case main.KEY.u:
                    {
                        if (!isSelectedTool(TOOL_MOVE))
                        {
                            updateLastTool();
                            selectMoveTool();
                            showNowToolIconToCursorTemp(TOOL_MOVE);
                        }
                    }
                    break;
                case main.KEY.w:
                case main.KEY.i:
                    {
                        if (!isSelectedTool(TOOL_ZOOM))
                        {
                            updateLastTool();
                            selectZoomTool();
                            showNowToolIconToCursorTemp(TOOL_ZOOM);
                        }
                    }
                    break;
                case main.KEY.shift:
                    {
                        if (!isSelectedTool(TOOL_LINE))
                        {
                            updateLastTool();
                            selectLineTool();
                            main.updatePenSizeCursor();
                        }
                    }
                    break;
                case main.KEY.esc:
                case main.KEY.del:
                case main.KEY.backspace:
                    {
                        if (MainUI.topBar.newFileButton.alpha === 1.0 && !BackgroundWorkerCoordinator.isSaveInProgress)
                        {
                            FileManager.createNewFile(true);
                        }
                    }
                    break;
            }
            main.penCursorManager.check();
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
            main.removeInputEventsToolBox2();
            isToolBox2Showing = false;
            toolBox2.visible = false;
            if (!ignoreResizeButtonVisible)
            {
                MainUIController.showCanvasResizeButtonVisibleDelay(false);
            }
        }
        public static function onMouseDownToolBox2(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if (!target)
            {
                return;
            }
            const targetName:String = target.name;
            switch (targetName)
            {
                case "toolZoom":
                    {
                        updateToolBoxMousePos(target as SimpleButton);
                        closeToolBox2();
                        main.zoomTool();
                    }
                    break;
                case "toolMove":
                    {
                        updateToolBoxMousePos(target as SimpleButton);
                        closeToolBox2();
                        main.moveTool();
                    }
                    break;
                case "toolRotate2":
                    {
                        updateToolBoxMousePos(target as SimpleButton);
                        closeToolBox2();
                        main.rotateTool(false);
                    }
                    break;
                case "resizeButtonR":
                case "resizeButtonD":
                case "resizeButtonL":
                case "resizeButtonU":
                    {
                        CanvasController.startCanvasResizing(targetName);
                    }
                    break;
                default:
                    {
                        if (toolBox2.visible && toolBox2.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                        {
                            updateToolBoxMousePos(toolBox2.toolPen);
                            updateLastTool();
                            main.handTool(false, false);
                        }
                        closeToolBox2();
                    }
                    break;
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
                        main.updatePenSizeCursor();
                        showNowToolIconToCursorTemp(TOOL_PEN);
                    }
                    break;
                case "toolFillPen":
                    {
                        selectFillPenTool();
                        main.updatePenSizeCursor();
                        showNowToolIconToCursorTemp(TOOL_FILLPEN);
                    }
                    break;
                case "toolEraser":
                    {
                        selectEraseTool();
                        main.updatePenSizeCursor();
                        showNowToolIconToCursorTemp(TOOL_ERASER);
                    }
                    break;
                case "toolLine":
                    {
                        selectLineTool();
                        main.updatePenSizeCursor();
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
                            main.eyeDropperTool();
                            showNowToolIconToCursorTemp(TOOL_EYEDROPPER);
                        }
                    }
                    break;
                case "toolUndo":
                    {
                        main.undo();
                        showNowToolIconToCursorTemp(TOOL_UNDO);
                    }
                    break;
                case "toolRedo":
                    {
                        main.redo();
                        showNowToolIconToCursorTemp(TOOL_REDO);
                    }
                    break;
                case "toolMirror":
                    {
                        CanvasController.mirrorCanvas();
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
        public static function onKeyUpToolBox2(e:KeyboardEvent):void
        {
            main.resetLastKey();
            handleToolBox2Closing(toolBox2.getMouseOverTarget());
        }
        public static function onRightMouseUpToolBox2(e:MouseEvent):void
        {
            CanvasController.isPenSizeCursorInvisible = false;
            if (LassoTool.isLassoToolStarted === true)
            {
                closeToolBox2();
                return;
            }
            const target:SimpleButton = e.target as SimpleButton;
            if (!target || target.alpha < 1.0 || !main.isCursorInDrawArea())
            {
                closeToolBox2();
                return;
            }
            handleToolBox2Closing(target);
        }

        public static function handleToolBoxMouseDown(target:DisplayObject):Boolean
        {
            if (main.isKeyPressed() && !SidebarController.isQuickSidebarActive || !target)
                return true;
            const targetName:String = target.name;
            switch (targetName)
            {
                case "toolRotate":
                    {
                        main.rotateTool(false);
                    }
                    return true;
                case "toolUndo":
                    {
                        main.startKeyRepeat(false, main.undo);
                        main.startKeyRepeatStopTimerOnMouseLeave(target);
                        handleToolBoxClick(targetName);
                    }
                    return true;
                case "toolRedo":
                    {
                        main.startKeyRepeat(false, main.redo);
                        main.startKeyRepeatStopTimerOnMouseLeave(target);
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

        public static function openToolBox2(fromShortcut:Boolean):void
        {
            CanvasController.isPenSizeCursorInvisible = true;
            CanvasController.penSizePreviewCursor.visible = false;
            var pos:Point = toolBox2.getLastUsedToolPos();
            const scale:Number = Global.getUIScale();
            toolBox2.x = Math.floor(main.stage.mouseX - pos.x * scale);
            toolBox2.y = Math.floor(main.stage.mouseY - pos.y * scale);
            toolBox2.alpha = 1.0;
            toolBox2.visible = true;
            isToolBox2Showing = true;
            MainUIController.showCanvasResizeButtonVisibleDelay(true);
            Utils.setAsTopChild(toolBox2);
            main.addInputEventsToolBox2(fromShortcut);
            FOFOTimer.addByName("toolBox2HideCheckTimer", 0.1, true, function ():Boolean
                {
                    if (!isToolBox2Showing)
                    {
                        return false;
                    }
                    if (MainUIController.resizeButtonR.visible)
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

        public static function handlePenOptionsBoxMouseDown(target:DisplayObject):Boolean
        {
            if (isToolBox2Showing)
            {
                return true;
            }
            const targetName:String = target.name;
            if (target.alpha === Global.OFFALPHA)
            {
                return true;
            }
            switch (targetName)
            {
                case "penSmoothSliderWapper":
                    {
                        if (nowTool !== TOOL_PEN)
                        {
                            return true;
                        }
                        selectPenToolIfNotDrawingTool(true);
                        startPenSmootingAdjustment();
                    }
                    return true;
                case "alphaButton1":
                case "alphaButton2":
                case "alphaButton3":
                case "alphaButton4":
                case "alphaButton5":
                case "alphaButton6":
                case "alphaButton7":
                case "alphaButton8":
                case "alphaButton9":
                case "alphaButton10":
                    {
                        main.selectOpacityButton(targetName);
                        selectPenToolIfNotDrawingTool(true);
                    }
                    return true;
                case "nSizeButton1":
                case "nSizeButton2":
                case "nSizeButton3":
                case "nSizeButton4":
                case "nSizeButton5":
                case "nSizeButton6":
                case "nSizeButton7":
                case "nSizeButton8":
                case "nSizeButton9":
                case "nSizeButton10":
                case "nSizeButton11":
                case "nSizeButton12":
                    {
                        if (!isSelectedTool(TOOL_FILLPEN))
                        {
                            selectPenToolIfNotDrawingTool(true);
                            selectPenSizeButton(targetName);
                        }
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
                        CanvasController.selectLayer1(false);
                        CanvasController.toggleLayer1Check();
                    }
                    return true;
                case "layer2CheckedButton":
                case "layer2UncheckedButton":
                    {
                        CanvasController.selectLayer2(false);
                        CanvasController.toggleLayer2Check();
                    }
                    return true;
                case "layer1SelectButton":
                    {
                        if (CanvasController.isLayer2Selected)
                        {
                            CanvasController.selectLayer1(false);
                        }
                        else
                        {
                            CanvasController.selectLayer1(CanvasController.canvasLayer2Bitmap.visible);
                            MainUI.showMouseHintLayerVisible();
                        }
                        if (toolOptionsBox.layer2CheckedButton.visible)
                        {
                            CanvasController.toggleLayer2Check();
                        }
                    }
                    return true;
                case "layer2SelectButton":
                    {
                        if (!CanvasController.isLayer2Selected)
                        {
                            CanvasController.selectLayer2(false);
                        }
                        else
                        {
                            CanvasController.selectLayer2(CanvasController.canvasLayer1Bitmap.visible);
                            MainUI.showMouseHintLayerVisible();
                        }
                        if (toolOptionsBox.layer1CheckedButton.visible)
                        {
                            CanvasController.toggleLayer1Check();
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
                        main.handleMouseClick(targetName);
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
            main.updatePenSizeCursor();
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
                MainUI.showMouseHintTemp("Sharp line ON");
            }
            else
            {
                MainUI.showMouseHintTemp("Sharp line OFF");
            }
        }

        public static function togglePenAirBrushButtonShortCut():void
        {
            isPenAirBrushON = !isPenAirBrushON;
            toggleAirBrushCheckBox(isPenAirBrushON, true);
            if (isPenAirBrushON)
                MainUI.showMouseHintTemp("Pen Air brush ON");
            else
                MainUI.showMouseHintTemp("Pen Air brush OFF");
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
                CanvasController.canvasDrawLayerChild.filters = [];
                toolOptionsBox.blurShapeSetOFF();
            }
        }
        public static function toggleEraseAirBrushButtonShortCut():void
        {
            PenTool.isEraserAirBrushON = !PenTool.isEraserAirBrushON;
            toggleAirBrushCheckBox(PenTool.isEraserAirBrushON, false);
            if (PenTool.isEraserAirBrushON)
                MainUI.showMouseHintTemp("Eraser Air brush ON");
            else
                MainUI.showMouseHintTemp("Eraser Air brush OFF");
        }
        public static function toggleEraseAirBrushButton(flag:Boolean):void
        {
            PenTool.isEraserAirBrushON = flag;
            toggleAirBrushCheckBox(flag, false);
        }

    }
}
