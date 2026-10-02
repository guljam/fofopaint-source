package Modules.Tools
{
    import Modules.PenSizePreviewCursor;
    import Modules.DrawEngine.StrokeBuffer;
    import Modules.DrawEngine.CanvasLayers;
    import Modules.InputManager.InputManager;
    import Modules.InputManager.DrawModeInput;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;
    import Modules.UIEngine.UITheme;

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


        public static var nowTool:int = 1; // 현재 툴 번호
        public static var lastTool:int = TOOL_NONE; // 툴백업


        public static var isSharpLineON:Boolean = false; // 0.5픽셀어긋나게 안하고 완전히 정확하게 할때씀
        public static var isPenAirBrushON:Boolean = false;

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

        public static function applyDrawingToolAlpha(alpha:Number = 0.0):void
        {
            const index:int = PenTool.penAlphaList.indexOf(alpha);
            const eraseFlag:Boolean = isSelectedTool(TOOL_ERASER);

            ToolPanel.updateOpacityCursorPos(index);

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

            ToolPanel.toolOptionsBox.movePenSizeCursor(index);
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

            ToolPanel.toolOptionsBox.updatePenShapeSet(shapeFlag);
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

        public static function selectPenTool(lineFlag:Boolean = false):void
        {
            setSelectedTool((lineFlag) ? TOOL_LINE : TOOL_PEN);
            toggleAirBrushCheckBox(isPenAirBrushON, true);
            setDrawToolSize(PenTool.penSizeIndex);
            applyDrawingToolAlpha(PenTool.penAlpha);
            ToolPanel.showPenToolSelected(lineFlag);
        }

        public static function selectLineTool():void
        {
            selectPenTool(true);
            ToolPanel.setPenSmoothingSliderEnabled(false);
        }

        public static function selectEraserTool():void
        {
            setSelectedTool(TOOL_ERASER);
            toggleAirBrushCheckBox(PenTool.isEraserAirBrushON, false);
            setDrawToolSize(PenTool.eraserSizeIndex);
            applyDrawingToolAlpha(PenTool.eraserAlpha);
            ToolPanel.showEraserToolSelected();
        }

        public static function selectFillPenTool():void
        {
            setSelectedTool(TOOL_FILLPEN);
            PenSizePreviewCursor.setVisible(false);
            toggleAirBrushCheckBox(isPenAirBrushON, true);
            ToolPanel.showFillPenToolSelected();
        }

        public static function selectMoveTool():void
        {
            ToolPanel.updateToolOptionsTextBySelectedTool(); // 도구를 바꾸기 전에 갱신함 (기존 동작 유지)
            setSelectedTool(TOOL_MOVE);
            ToolPanel.showOtherToolSelected("toolMove");
        }

        public static function selectZoomTool():void
        {
            ToolPanel.updateToolOptionsTextBySelectedTool(); // 도구를 바꾸기 전에 갱신함 (기존 동작 유지)
            setSelectedTool(TOOL_ZOOM);
            ToolPanel.showOtherToolSelected("toolZoomIn", UIController.canvasInfoBox);
        }

        public static function selectRotateTool():void
        {
            ToolPanel.updateToolOptionsTextBySelectedTool(); // 도구를 바꾸기 전에 갱신함 (기존 동작 유지)
            setSelectedTool(TOOL_ROTATE);
            ToolPanel.showOtherToolSelected("toolRotate", UIController.canvasInfoBox);
        }

        public static function selectLassoTool():void
        {
            ToolPanel.updateToolOptionsTextBySelectedTool(); // 도구를 바꾸기 전에 갱신함 (기존 동작 유지)
            setSelectedTool(TOOL_LASSO);
            ToolPanel.showOtherToolSelected("toolLasso", null, true);
        }

        // 도구 선택 단축키 (도구와 무관한 단축키는 DrawModeInput.handleNonToolKeyDown이 먼저 처리함)
        public static function handleToolKeyDown(keyCode:int):void
        {
            switch (keyCode)
            {
                case InputManager.KEY.q:
                case InputManager.KEY.o:
                    {
                        setLastTool(TOOL_PEN);
                        selectFillPenTool();
                        ToolPanel.showNowToolIconToCursorTemp(TOOL_FILLPEN);
                    }
                    break;
                case InputManager.KEY.c:
                case InputManager.KEY.m:
                    {
                        if (!isSelectedTool(TOOL_EYEDROPPER))
                        {
                            EyeDropperTool.start();

                            if (isSelectedTool(TOOL_EYEDROPPER))
                            {
                                ToolPanel.showNowToolIconToCursorTemp(TOOL_EYEDROPPER);
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
                            ToolPanel.showNowToolIconToCursorTemp(TOOL_LASSO);
                        }
                    }
                    break;
                case InputManager.KEY.space:
                    {
                        if (!isSelectedTool(TOOL_HAND))
                        {
                            updateLastTool();
                            setSelectedTool(TOOL_HAND);
                            ToolPanel.showNowToolIconToCursorTemp(TOOL_HAND);
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
                            ToolPanel.showNowToolIconToCursorTemp(TOOL_ERASER);
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
                            ToolPanel.showNowToolIconToCursorTemp(TOOL_ROTATE);
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
                            ToolPanel.showNowToolIconToCursorTemp(TOOL_MOVE);
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
                            ToolPanel.showNowToolIconToCursorTemp(TOOL_ZOOM);
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
            }

            PenSizePreviewCursor.updatePosAndVisibility();
        }

        public static function toggleSharpLine(flag:Boolean):void
        {
            isSharpLineON = flag;
            ToolPanel.toolOptionsBox.sharpLineOFFButton.visible = flag;
            ToolPanel.toolOptionsBox.sharpLineONButton.visible = !flag;
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
            ToolPanel.toolOptionsBox.airBrushOFFButton.visible = flag;
            ToolPanel.toolOptionsBox.airBrushONButton.visible = !flag;

            if (flag)
            {
                PenTool.airBrushSizeDrawMode = (penFlag) ? PenTool.penSize : PenTool.eraserSize;
                ToolPanel.toolOptionsBox.blurShapeSetON();
            }
            else if (PenTool.airBrushSizeDrawMode !== 0)
            {
                PenTool.airBrushSizeDrawMode = 0;
                StrokeBuffer.canvasDrawLayerChild.filters = [];
                ToolPanel.toolOptionsBox.blurShapeSetOFF();
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
    }
}
