package Modules.L4UI.Tools
{
    import Modules.L4UI.Tools.ToolPanel;
    import Modules.L1Data.KeyState;
    import Modules.L1Data.ToolState;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L1Data.Tools.PenSettings;
    import Modules.L4UI.PenSizePreviewCursor;
    import Modules.L3Feature.DrawEngine.CanvasLayers;
    import Modules.L4UI.Tools.PenTool;
    import Modules.L4UI.Tools.LineTool;
    import Modules.L4UI.Tools.FillPenTool;
    import Modules.L4UI.Tools.LassoTool;
    import Modules.L4UI.Tools.MoveTool;
    import Modules.L4UI.Tools.HandTool;
    import Modules.L4UI.Tools.ZoomTool;
    import Modules.L4UI.Tools.RotateTool;
    import Modules.L4UI.Tools.EyeDropperTool;

    // 층: L3 기능 - 현재 툴 선택과 툴 전환
    public class ToolController
    {
        public static var main:Main;

        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static function selectPenToolIfNotDrawingTool(checkErase:Boolean):void
        {
            if (!(ToolState.isSelectedToolPenOrLine() || ToolState.isSelectedTool(ToolState.TOOL_FILLPEN)
                        || (checkErase && ToolState.isSelectedTool(ToolState.TOOL_ERASER))))
            {
                ToolState.resetLastTool();
                selectPenTool();
                PenSizePreviewCursor.updateSizeAndShape();
            }
        }

        // 단축키를  after tool mouse up에서 이전툴을 복구해줌
        public static function selectLastUsedTool():void
        {
            const lastToolSave:int = ToolState.lastTool;

            if (lastToolSave === ToolState.TOOL_NONE)
            {
                selectPenTool();
                PenSizePreviewCursor.updateSizeAndShape();
                return;
            }

            switch (lastToolSave)
            {
                case ToolState.TOOL_PEN:
                    selectPenTool();
                    PenSizePreviewCursor.updateSizeAndShape();
                    break;
                case ToolState.TOOL_FILLPEN:
                    selectFillPenTool();
                    break;
                case ToolState.TOOL_ERASER:
                    selectEraserTool();
                    PenSizePreviewCursor.updateSizeAndShape();
                    break;
                case ToolState.TOOL_LINE:
                    selectLineTool();
                    PenSizePreviewCursor.updateSizeAndShape();
                    break;
                case ToolState.TOOL_EYEDROPPER:
                    EyeDropperTool.start();
                    break;
                case ToolState.TOOL_LASSO:
                    selectLassoTool();
                    break;
                case ToolState.TOOL_MOVE:
                    selectMoveTool();
                    break;
                case ToolState.TOOL_ROTATE:
                    selectRotateTool();
                    break;
                case ToolState.TOOL_ZOOM:
                    selectZoomTool();
                    break;
            }

            ToolState.nowTool = lastToolSave;
            ToolState.resetLastTool();
        }

        // 캔버스 영역을 누르면 현재 도구를 시작함 (캔버스 영역 안인지는 입력쪽에서 판단)
        public static function onCanvasMouseDown():void
        {
            switch (ToolState.nowTool)
            {
                case ToolState.TOOL_PEN:
                    if (CanvasLayers.isToolEnabledByLayerUnChecked())
                        PenTool.start();
                    break;
                case ToolState.TOOL_FILLPEN:
                    if (CanvasLayers.isToolEnabledByLayerUnChecked())
                        FillPenTool.start();
                    break;
                case ToolState.TOOL_ERASER:
                    if (CanvasLayers.isToolEnabledByLayerUnChecked())
                        PenTool.startWithEraserMode();
                    break;
                case ToolState.TOOL_LINE:
                    if (CanvasLayers.isToolEnabledByLayerUnChecked())
                        LineTool.start();
                    break;
                case ToolState.TOOL_LASSO:
                    LassoTool.startLassoSelection();
                    break;
                case ToolState.TOOL_MOVE:
                    MoveTool.start();
                    break;
                    // 캔버스 조작
                case ToolState.TOOL_ZOOM:
                    ZoomTool.start();
                    break;
                case ToolState.TOOL_HAND:
                    HandTool.startInDrawMode();
                    break;
                case ToolState.TOOL_ROTATE:
                    RotateTool.startInDrawMode();
                    break;
            }
        }

        public static function selectPenTool(lineFlag:Boolean = false):void
        {
            ToolState.setSelectedTool((lineFlag) ? ToolState.TOOL_LINE : ToolState.TOOL_PEN);
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
            ToolState.setSelectedTool(ToolState.TOOL_ERASER);
            PenSettings.toggleAirBrushCheckBox(PenSettings.isEraserAirBrushON, false);
            PenSettings.setDrawToolSize(PenSettings.eraserSizeIndex);
            PenSettings.applyDrawingToolAlpha(PenSettings.eraserAlpha);
            ToolPanel.showEraserToolSelected();
        }

        public static function selectFillPenTool():void
        {
            ToolState.setSelectedTool(ToolState.TOOL_FILLPEN);
            PenSizePreviewCursor.setVisible(false);
            PenSettings.toggleAirBrushCheckBox(PenSettings.isPenAirBrushON, true);
            ToolPanel.showFillPenToolSelected();
        }

        public static function selectMoveTool():void
        {
            ToolPanel.updateToolOptionsTextBySelectedTool(); // 도구를 바꾸기 전에 갱신함 (기존 동작 유지)
            ToolState.setSelectedTool(ToolState.TOOL_MOVE);
            ToolPanel.showOtherToolSelected("toolMove");
        }

        public static function selectZoomTool():void
        {
            ToolPanel.updateToolOptionsTextBySelectedTool(); // 도구를 바꾸기 전에 갱신함 (기존 동작 유지)
            ToolState.setSelectedTool(ToolState.TOOL_ZOOM);
            ToolPanel.showOtherToolSelected("toolZoomIn", UIController.canvasInfoBox);
        }

        public static function selectRotateTool():void
        {
            ToolPanel.updateToolOptionsTextBySelectedTool(); // 도구를 바꾸기 전에 갱신함 (기존 동작 유지)
            ToolState.setSelectedTool(ToolState.TOOL_ROTATE);
            ToolPanel.showOtherToolSelected("toolRotate", UIController.canvasInfoBox);
        }

        public static function selectLassoTool():void
        {
            ToolPanel.updateToolOptionsTextBySelectedTool(); // 도구를 바꾸기 전에 갱신함 (기존 동작 유지)
            ToolState.setSelectedTool(ToolState.TOOL_LASSO);
            ToolPanel.showOtherToolSelected("toolLasso", null, true);
        }

        // 도구 선택 단축키 (도구와 무관한 단축키는 DrawModeInput.handleNonToolKeyDown이 먼저 처리함)
        public static function handleToolKeyDown(keyCode:int):void
        {
            switch (keyCode)
            {
                case KeyState.KEY.q:
                case KeyState.KEY.o:
                    {
                        ToolState.setLastTool(ToolState.TOOL_PEN);
                        selectFillPenTool();
                        ToolPanel.showNowToolIconToCursorTemp(ToolState.TOOL_FILLPEN);
                    }
                    break;
                case KeyState.KEY.c:
                case KeyState.KEY.m:
                    {
                        if (!ToolState.isSelectedTool(ToolState.TOOL_EYEDROPPER))
                        {
                            EyeDropperTool.start();

                            if (ToolState.isSelectedTool(ToolState.TOOL_EYEDROPPER))
                            {
                                ToolPanel.showNowToolIconToCursorTemp(ToolState.TOOL_EYEDROPPER);
                            }
                        }
                    }
                    break;
                case KeyState.KEY.r:
                case KeyState.KEY.y:
                    {
                        if (!ToolState.isSelectedTool(ToolState.TOOL_LASSO))
                        {
                            ToolState.updateLastTool();
                            selectLassoTool();
                            ToolPanel.showNowToolIconToCursorTemp(ToolState.TOOL_LASSO);
                        }
                    }
                    break;
                case KeyState.KEY.space:
                    {
                        if (!ToolState.isSelectedTool(ToolState.TOOL_HAND))
                        {
                            ToolState.updateLastTool();
                            ToolState.setSelectedTool(ToolState.TOOL_HAND);
                            ToolPanel.showNowToolIconToCursorTemp(ToolState.TOOL_HAND);
                        }
                    }
                    break;
                case KeyState.KEY.d:
                case KeyState.KEY.j:
                    {
                        if (!ToolState.isSelectedTool(ToolState.TOOL_ERASER))
                        {
                            ToolState.updateLastTool();
                            selectEraserTool();
                            PenSizePreviewCursor.updateSizeAndShape();
                            ToolPanel.showNowToolIconToCursorTemp(ToolState.TOOL_ERASER);
                        }
                    }
                    break;
                case KeyState.KEY.s:
                case KeyState.KEY.k:
                    {
                        if (!ToolState.isSelectedTool(ToolState.TOOL_ROTATE))
                        {
                            ToolState.updateLastTool();
                            selectRotateTool();
                            ToolPanel.showNowToolIconToCursorTemp(ToolState.TOOL_ROTATE);
                        }
                    }
                    break;
                case KeyState.KEY.e:
                case KeyState.KEY.u:
                    {
                        if (!ToolState.isSelectedTool(ToolState.TOOL_MOVE))
                        {
                            ToolState.updateLastTool();
                            selectMoveTool();
                            ToolPanel.showNowToolIconToCursorTemp(ToolState.TOOL_MOVE);
                        }
                    }
                    break;
                case KeyState.KEY.w:
                case KeyState.KEY.i:
                    {
                        if (!ToolState.isSelectedTool(ToolState.TOOL_ZOOM))
                        {
                            ToolState.updateLastTool();
                            selectZoomTool();
                            ToolPanel.showNowToolIconToCursorTemp(ToolState.TOOL_ZOOM);
                        }
                    }
                    break;
                case KeyState.KEY.shift:
                    {
                        if (!ToolState.isSelectedTool(ToolState.TOOL_LINE))
                        {
                            ToolState.updateLastTool();
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
