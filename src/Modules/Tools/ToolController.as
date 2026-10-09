package Modules.Tools
{
    import Modules.PenSizePreviewCursor;
    import Modules.DrawEngine.CanvasLayers;
    import Modules.InputManager.InputManager;
    import Modules.UIEngine.UIController;

    // 층: L3 기능 - 현재 툴 선택과 툴 전환
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

        public static var nowTool:int = 1; // 현재 툴 번호
        public static var lastTool:int = TOOL_NONE; // 툴백업

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
            PenSettings.toggleAirBrushCheckBox(PenSettings.isPenAirBrushON, true);
            PenSettings.setDrawToolSize(PenSettings.penSizeIndex);
            PenSettings.applyDrawingToolAlpha(PenSettings.penAlpha);
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
            PenSettings.toggleAirBrushCheckBox(PenSettings.isEraserAirBrushON, false);
            PenSettings.setDrawToolSize(PenSettings.eraserSizeIndex);
            PenSettings.applyDrawingToolAlpha(PenSettings.eraserAlpha);
            ToolPanel.showEraserToolSelected();
        }

        public static function selectFillPenTool():void
        {
            setSelectedTool(TOOL_FILLPEN);
            PenSizePreviewCursor.setVisible(false);
            PenSettings.toggleAirBrushCheckBox(PenSettings.isPenAirBrushON, true);
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

    }
}
