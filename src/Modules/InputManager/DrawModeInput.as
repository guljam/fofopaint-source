package Modules.InputManager
{
    import Modules.Tools.PenSettings;
    import Modules.Tools.ToolPanel;
    import Modules.DrawEngine.CanvasView;
    import Modules.DrawEngine.DrawCanvas;
    import Modules.DrawEngine.CanvasLayers;
    import Modules.DrawEngine.LayerPreview;
    import Modules.UIEngine.CanvasNavigator;
    import Modules.DrawEngine.CanvasResizer;
    import Modules.MouseState;
    import Modules.ActivityWorkTimer;
    import Modules.AppUpdater;
    import Modules.AboutBoxController;
    import Modules.CanvasGridOverlay;
    import Modules.ClipboardManager;
    import Modules.ColorPickerController;
    import Modules.DragInteraction;
    import Modules.FileManager;
    import Modules.LoadBoxController;
    import Modules.ImageViewWindow;
    import Modules.InputPriority;
    import Modules.PenSizePreviewCursor;
    import Modules.ReferenceLayerController;
    import Modules.SidebarController;
    import Modules.Tools.ToolController;
    import Modules.UndoController;
    import Modules.Utils;
    import Modules.CaptureEngine.CaptureController;
    import Modules.ReplayEngine.ReplayController;
    import Modules.Tools.FillPenTool;
    import Modules.Tools.HandTool;
    import Modules.Tools.LassoTool;
    import Modules.Tools.LineTool;
    import Modules.Tools.MoveTool;
    import Modules.Tools.RotateTool;
    import Modules.Tools.ZoomTool;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;
    import Modules.UIEngine.UITheme;

    import flash.display.DisplayObject;
    import flash.display.SimpleButton;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;

    // 드로우 모드의 키보드/마우스 입력 (툴 단축키, 툴박스2, 드로우 모드 버튼)
    // 층: L5 앱 흐름 - 드로우 모드의 키보드/마우스 입력
    public class DrawModeInput
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static var isEventsAdded:Boolean = false; // 이벤트 중복 추가 방지
        public static var isKeyReleasedBeforeMouseUp:Boolean = false; // 키 떼기 전에 마우스 먼저 떼주었을때 플래그 올려줌

        public static function removeEvents():void
        {
            isEventsAdded = false;
            main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownDrawMode);
            main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpDrawMode);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownDrawMode);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpDrawMode, false);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownDrawMode);
            ColorPickerController.colorPickerBox.rgbInfoText.removeEventListener(MouseEvent.MOUSE_DOWN, ColorPickerController.onMouseDownRGBInfo);
            ColorPickerController.colorPickerBox.rgbInfoBG.removeEventListener(MouseEvent.MOUSE_DOWN, ColorPickerController.onMouseDownRGBInfo);
            ColorPickerController.colorPickerBox.currentColorBox.removeEventListener(MouseEvent.MOUSE_DOWN, ColorPickerController.onMouseDownCurrentColor);
            // main.stage.removeEventListener(MouseEvent.MOUSE_OVER,lassoMenuHintONEvent);
        }

        public static function addEvents():void
        {
            if (isEventsAdded === false)
            {
                isEventsAdded = true;
                // resetKeyBuffer();
                main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpDrawMode, false, InputPriority.MODE);
                main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownDrawMode, false, InputPriority.MODE);
                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownDrawMode, false, InputPriority.MODE);
                main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpDrawMode, false, InputPriority.MODE);
                main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownDrawMode, false, InputPriority.MODE);
                ColorPickerController.colorPickerBox.rgbInfoText.addEventListener(MouseEvent.MOUSE_DOWN, ColorPickerController.onMouseDownRGBInfo);
                ColorPickerController.colorPickerBox.rgbInfoBG.addEventListener(MouseEvent.MOUSE_DOWN, ColorPickerController.onMouseDownRGBInfo);
                ColorPickerController.colorPickerBox.currentColorBox.addEventListener(MouseEvent.MOUSE_DOWN, ColorPickerController.onMouseDownCurrentColor);
            }
        }

        public static function removeToolBox2Events():void
        {
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpToolBox2);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownToolBox2);
            ToolPanel.toolBox2.removeEventListener(MouseEvent.MOUSE_OVER, ToolPanel.onMouseOverToolBox2);
            addEvents();
        }

        public static function addToolBox2Events():void
        {
            removeEvents();
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpToolBox2, false, InputPriority.LATE);
            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownToolBox2, false, InputPriority.LATE);
        }

        private static function onRightMouseUpToolBox2(e:MouseEvent):void
        {
            PenSizePreviewCursor.setCursorInVisibleFlag(false);

            if (LassoTool.isStarted === true)
            {
                ToolPanel.closeToolBox2();
                return;
            }

            const target:SimpleButton = e.target as SimpleButton;

            if (!target || target.alpha < 1.0 || !Utils.isCursorInDrawArea())
            {
                ToolPanel.closeToolBox2();
                return;
            }

            ToolPanel.handleToolBox2Closing(target);
        }

        private static function onMouseDownToolBox2(e:MouseEvent):void
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
                        ToolPanel.updateToolBoxMousePos(target as SimpleButton);
                        ToolPanel.closeToolBox2();
                        ZoomTool.start();
                    }
                    break;
                case "toolMove":
                    {
                        ToolPanel.updateToolBoxMousePos(target as SimpleButton);
                        ToolPanel.closeToolBox2();
                        MoveTool.start();
                    }
                    break;
                case "toolRotate2":
                    {
                        ToolPanel.updateToolBoxMousePos(target as SimpleButton);
                        ToolPanel.closeToolBox2();
                        RotateTool.startInDrawMode();
                    }
                    break;
                case "resizeButtonR":
                case "resizeButtonD":
                case "resizeButtonL":
                case "resizeButtonU":
                    {
                        CanvasResizer.start(targetName);
                    }
                    break;
                default:
                    {
                        if (ToolPanel.toolBox2.visible && ToolPanel.toolBox2.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                        {
                            ToolPanel.updateToolBoxMousePos(ToolPanel.toolBox2.toolPen);
                            ToolController.updateLastTool();
                            HandTool.startInDrawMode();
                        }

                        ToolPanel.closeToolBox2();
                    }
                    break;
            }
        }

        // 드로우 모드 버튼은 누른 버튼에서 마우스를 뗐을때 실행됨 (InputManager.handleMouseClickStage가 호출)
        public static function onClickDrawModeButton(targetName:String):void
        {
            switch (targetName)
            {
                case "replayModeButton":
                    {
                        ReplayController.enterReplayMode();
                        MouseState.isLeftDown = false; // 리플레이 버튼 누르고 나서 단축키가 안먹는 현상이 이거임
                    }
                    break;
                case "dpiButton":
                    {
                        UITheme.setNextScaleIndex();
                        UIController.applyUIScale();
                        HintController.showMouseHintTemp(UITheme.getUIScaleString());
                    }
                    break;
                case "updateButton":
                    {
                        AppUpdater.openReleasePage();
                    }
                    break;
                case "sideBarPositionButton":
                case "sideBarPositionButton2":
                    {
                        SidebarController.toggleSideBarPosition();
                    }
                    break;
                case "sideBarOFFButton":
                case "sideBarOFFButton2":
                    {
                        SidebarController.hideSidebarPermanent();
                    }
                    break;
                case "sideBarONButton":
                case "sideBarONButton2":
                    {
                        SidebarController.showSidebarPermanent();
                    }
                    break;
                case "refLoadImageButton":
                    {
                        FileManager.openLoadFileBrowser(true);
                    }
                    break;
                case "loadButton":
                    {
                        FileManager.openLoadFileBrowser();
                    }
                    break;
                case "gridButton":
                    {
                        CanvasGridOverlay.gridButton.start(false);
                    }
                    break;
                case "aboutButton":
                    {
                        AboutBoxController.openAboutBox(false);
                    }
                    break;
                case "newWindowCloseButton":
                    {
                        ImageViewWindow.closeCanvasWindow();
                    }
                    break;
                case "newWindowButton":
                    {
                        ImageViewWindow.openImageViewWindow();
                    }
                    break;
                case "refMenuCloseButton":
                    {
                        Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                        ReferenceLayerController.closeRefLayerMenu();
                    }
                    break;
                case "refTransferCanvasImageButton":
                    {
                        ReferenceLayerController.mergeCanvasImageIntoRefLayer();
                    }
                    break;
                case "refClipBoardButton":
                    {
                        if (ReferenceLayerController.refLayerMenuBox.refClipBoardButton.alpha === 1.0)
                        {
                            ClipboardManager.tryLoadClipboardImage(true);
                        }
                    }
                    break;
                case "refMirrorImageButton":
                    {
                        Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                        ReferenceLayerController.startRefLayerImageMirror();
                    }
                    break;
                case "refMemoryTrainingOnButton":
                case "refMemoryTrainingOffButton":
                    {
                        Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                        ReferenceLayerController.toggleRefLayerMemoryTraining();
                    }
                    break;
                case "layerMergeButton":
                    {
                        CanvasLayers.mergeImageIntoLayer2();
                        HintController.showMouseHintTemp("Layers has been merged to layer 2");
                    }
                    break;
                case "layerSwapButton":
                    {
                        CanvasLayers.swapLayer();
                        HintController.showMouseHintTemp(HintStrings.getCanvasLayerSwappedHintString());
                    }
                    break;
            }
        }

        private static function onKeyUpDrawMode(e:KeyboardEvent):void // keyup1
        {
            const keyCode:uint = e.keyCode;
            LayerPreview.endKeyPreview(keyCode); // 레이어 단축키를 떼면 프리뷰 즉시 복구
            if (InputManager.isLastKey(keyCode))
            {
                if (MouseState.isLeftDown === true)
                {
                    DrawModeInput.isKeyReleasedBeforeMouseUp = true;
                }
                else if (InputManager.isKeyPressed())
                {
                    onKeyDownDrawMode(null);
                }
                else
                {
                    if (ToolController.lastTool > ToolController.TOOL_NONE)
                    {
                        ToolController.selectLastUsedTool();
                        ToolPanel.showNowToolIconToCursorTemp(ToolController.nowTool);
                    }
                    PenSizePreviewCursor.updatePosAndVisibility();
                }
            }
            if (!InputManager.isKeyPressed())
            {
                InputManager.resetLastKey();
            }
            if (!InputManager.isPressingControl())
            {
                if (CanvasResizer.isResizing())
                {
                    CanvasResizer.exit();
                }
                if (CanvasResizer.isButtonVisible())
                {
                    CanvasResizer.updateButtonVisible(false);
                }
            }
        }

        private static function onKeyDownDrawMode(e:KeyboardEvent):void
        {
            if (MouseState.isLeftDown
                    || MouseState.isRightDown
                    || DrawModeInput.isKeyReleasedBeforeMouseUp
                    || FillPenTool.isStarted
                    || LineTool.isStarted
                    || UIController.isPopUpWindowOpened())
            {
                return;
            }

            const firstKey:uint = InputManager.getFirstPressedKey();
            const secondKey:int = InputManager.getSecondPressedKey();
            // 자툴이 nowkey를 쓰기 때문에 nowkey 리턴 이전에서 체크해야함
            if (InputManager.isPressingControlShift())
            {
                // shift 누르고 ctrl 순서로 누를때 이전툴로 복원
                if (ToolController.isSelectedTool(ToolController.TOOL_LINE))
                {
                    ToolController.selectLastUsedTool();
                }
                InputManager.checkSubKey(3, true, handleControlShiftSubKeyDrawMode);
                return;
            }
            if (InputManager.isPressingControl())
            {
                if (!InputManager.checkSubKey(2, true, handleControlSubKeyDrawMode))
                {
                    if (CanvasResizer.isResizing() === false)
                    {
                        CanvasResizer.updateButtonVisible(true);
                    }
                }
                return;
            }
            if (InputManager.isPressingShift())
            {
                if (handleKeyDownPenOpacitySize(secondKey))
                {
                    return;
                }
                else if (checkPenOptionsKeyDown(secondKey))
                {
                    return;
                }
                else if (InputManager.checkSubKey(2, true, handleShiftSubKeyDrawMode))
                {
                    return;
                }
            }
            if (InputManager.isTwoKeyPressed())
            {
                // 지우개키 조합 따로 체크
                if (firstKey === InputManager.KEY.d || firstKey === InputManager.KEY.j)
                {
                    if (handleKeyDownPenOpacitySize(secondKey))
                    {
                        return;
                    }
                    else if (secondKey === InputManager.KEY.s || secondKey === InputManager.KEY.k)
                    {
                        if (SidebarController.isQuickSidebarActive === false)
                        {
                            SidebarController.activeQuickSideBar(true);
                        }
                        return;
                    }
                    else if (checkPenOptionsKeyDown(secondKey))
                    {
                        return;
                    }
                }
                else if (SidebarController.isPressingQuickSidebarShortcut(firstKey, secondKey))
                {
                    if (SidebarController.isQuickSidebarActive === false)
                    {
                        SidebarController.activeQuickSideBar(true);
                    }
                    return;
                }
                // 필펜 조합 체크
                else if (firstKey === InputManager.KEY.q || firstKey === InputManager.KEY.o)
                {
                    if (handleKeyDownPenOpacitySize(secondKey))
                    {
                        return;
                    }
                    else if (checkPenOptionsKeyDown(secondKey))
                    {
                        return;
                    }
                }
            }
            if (InputManager.isLastKey(firstKey))
            {
                return;
            }
            InputManager.updateLastKey();
            if (handleKeyDownPenOpacitySize(firstKey))
            {
                return;
            }
            if (handleExtraKeyDown(firstKey))
            {
                return;
            }
            if (handleNonToolKeyDown(firstKey))
            {
                return;
            }
            ToolController.handleToolKeyDown(firstKey);
        }

        private static function handleShiftSubKeyDrawMode(input:int):void
        {
            switch (input)
            {
                case InputManager.KEY.s:
                case InputManager.KEY.k:
                    {
                        if (CanvasView.canvasAnchorPoint.rotation !== 0.0)
                        {
                            CanvasView.resetRotationDrawMode();
                            CanvasNavigator.updateCursor();
                        }
                    }
                    return;
                case InputManager.KEY.w:
                case InputManager.KEY.i:
                    {
                        if (CanvasView.canvasZoomMultiplier !== 1.0)
                        {
                            CanvasView.resetZoomDrawMode();
                            CanvasNavigator.updateCursor();
                        }
                    }
                    return;
            }
        }
        private static function handleControlShiftSubKeyDrawMode(input:int):void
        {
            if (input === InputManager.KEY.s)
            {
                FileManager.openSaveFileBrowser(true);
            }
        }
        private static function handleControlSubKeyDrawMode(input:int):void
        {
            if (input === InputManager.KEY.s)
            {
                FileManager.openSaveFileBrowser(false);
            }
            else if (input === InputManager.KEY.o)
            {
                FileManager.openLoadFileBrowser();
            }
            else if (input === InputManager.KEY.c || input === InputManager.KEY.comma)
            {
                CaptureController.enterCaptureMode();
            }
            else if (input === InputManager.KEY.v || input === InputManager.KEY.m)
            {
                if (ClipboardManager.isClipBoardButtonActivated)
                {
                    ClipboardManager.tryLoadClipboardImage(false);
                }
            }
        }

        private static function handleLayerSelectShortcut(layer:int, keyCode:int):void
        {
            const other:int = (layer === 1) ? 2 : 1;
            const isLayer2Selected:Boolean = ((layer === 2) === CanvasLayers.isLayer2Selected);
            const otherVisible:Boolean = (other === 1 ? DrawCanvas.canvasLayer1Bitmap : DrawCanvas.canvasLayer2Bitmap).visible;

            if (!isLayer2Selected)
            {
                HintController.showMouseHintTemp("Layer " + layer + " selected");
                CanvasLayers.selectLayer(layer, false);
            }
            else if (!otherVisible)
            {
                CanvasLayers.selectLayer(layer, false);
                CanvasLayers.toggleLayerCheck(layer);
                HintController.showMouseHintLayerChecked();
            }
            else if (CanvasLayers.checkedLayer === layer)
            {
                CanvasLayers.toggleLayerCheck(layer);
            }
            else
            {
                CanvasLayers.selectLayer(layer, true); // 이 분기에서 otherVisible은 항상 true
                HintController.showMouseHintLayerVisible();
            }

            if (CanvasLayers.checkedLayer === other)
            {
                CanvasLayers.toggleLayerCheck(other);
            }
            LayerPreview.startKeyPreview(keyCode);
        }

        // 도구 선택이 아닌 단축키: 참조 레이어 메뉴, 미러, 스크래치 패드 색 추출, 새 파일
        // 처리했으면 true. C/M을 스크래치 패드 밖에서 누른 경우는 스포이드 도구라 false로 넘김
        private static function handleNonToolKeyDown(keyCode:int):Boolean
        {
            if (ReferenceLayerController.isRefLayerMenuON)
            {
                if (keyCode === InputManager.KEY.esc || keyCode === InputManager.KEY.backspace)
                {
                    ReferenceLayerController.closeRefLayerMenu();
                    return true;
                }
            }

            switch (keyCode)
            {
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
                        ToolPanel.showNowToolIconToCursorTemp(ToolController.TOOL_MIRROR);
                    }
                    break;
                case InputManager.KEY.c:
                case InputManager.KEY.m:
                    {
                        if (!ColorPickerController.colorPickerBox.scratchPad.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                        {
                            return false;
                        }
                        if (ColorPickerController.colorPickerBox.scratchPad.visible)
                        {
                            ColorPickerController.showPickColorScratchPad();
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
                default:
                    return false;
            }

            PenSizePreviewCursor.updatePosAndVisibility();
            return true;
        }

        private static function handleExtraKeyDown(keyCode:int):Boolean
        {
            switch (keyCode)
            {
                case InputManager.KEY.f1:
                case InputManager.KEY.f7:
                    {
                        ReplayController.enterReplayMode();
                    }
                    return true;
                case InputManager.KEY.n1:
                case InputManager.KEY.n9:
                    handleLayerSelectShortcut(1, keyCode);
                    return true;
                case InputManager.KEY.n2:
                case InputManager.KEY.n0:
                    handleLayerSelectShortcut(2, keyCode);
                    return true;
                case InputManager.KEY.n3:
                case InputManager.KEY.n8:
                    {
                        if (ToolPanel.toolOptionsBox.sharpLineButtonWrapper.alpha === 1.0)
                        {
                            PenSettings.toggleSharpLineByShortcut();
                        }
                    }
                    return true;
                case InputManager.KEY.n4:
                case InputManager.KEY.n7:
                    {
                        if (ToolController.isSelectedToolPenOrLine() || ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
                        {
                            PenSettings.togglePenAirBrushButtonShortCut();
                        }
                        else if (ToolController.isSelectedTool(ToolController.TOOL_ERASER))
                        {
                            PenSettings.toggleEraseAirBrushButtonShortCut();
                        }
                    }
                    return true;
                case InputManager.KEY.n6:
                    {
                        SidebarController.activeQuickSideBar(true);
                    }
                    return true;
                case InputManager.KEY.x:
                case InputManager.KEY.comma:
                    {
                        InputManager.startKeyRepeat(true, UndoController.redo);
                        ToolPanel.showNowToolIconToCursorTemp(ToolController.TOOL_REDO);
                    }
                    return true;
                case InputManager.KEY.z:
                case InputManager.KEY.dot:
                    {
                        InputManager.startKeyRepeat(true, UndoController.undo);
                        ToolPanel.showNowToolIconToCursorTemp(ToolController.TOOL_UNDO);
                    }
                    return true;
                case InputManager.KEY.tab:
                case InputManager.KEY.backslash:
                    {
                        if (SidebarController.isSidebarVisible)
                        {
                            SidebarController.hideSidebarPermanent();
                        }
                        else
                        {
                            SidebarController.showSidebarPermanent();
                        }
                    }
                    return true;
            }
            return false;
        }

        // 키를 2개 이상 누르고 있을때 먼저 누른키를 떼면 다음키로 설정함
        private static function onMouseUpDrawMode(e:MouseEvent):void // mouseup1
        {
            if (DrawModeInput.isKeyReleasedBeforeMouseUp) // 단축키 떼고 마우스 땠을때 원래대로 돌림
            {
                DrawModeInput.isKeyReleasedBeforeMouseUp = false;
                if (InputManager.keyBuffer.length > 0)
                {
                    onKeyDownDrawMode(null);
                }
                else
                {
                    InputManager.resetLastKey();
                    if (ToolController.lastTool > ToolController.TOOL_NONE)
                    {
                        ToolController.selectLastUsedTool();
                    }
                    PenSizePreviewCursor.updatePosAndVisibility();
                }
            }
        }

        private static function onMouseDownDrawMode(e:MouseEvent):void
        {
            if (FillPenTool.isStarted || LineTool.isStarted || LoadBoxController.loadMenuBox.visible
                    || UIController.topBar.gridButtonWrapper.visible || ColorPickerController.numPadBox.visible)
            {
                return;
            }
            const target:DisplayObject = e.target as DisplayObject;
            if (!target)
            {
                return;
            }
            const targetName:String = target.name;
            if (SidebarController.sideBar.visible)
            {
                if (SidebarController.sideBarScrollPanel.hitTestPoint(main.stage.mouseX, main.stage.mouseY) && SidebarController.handleSidebarMouseDown(target))
                {
                    return;
                }
            }
            if (SidebarController.isQuickSidebarActive)
            {
                if (targetName === "sideBarScrollBar")
                {
                    SidebarController.startScrollSidebarByDrag();
                }
                return;
            }
            switch (targetName)
            {
                // 리플레이 모드와 같이 쓰는 상단바 버튼
                case "saveButton": // 아래 3개는 WorkspaceView.topbar메뉴에 가면 안됨 mouseuphandler랑 같이 연동되서 여기서 해주어야함
                case "captureButton":
                case "repCaptureButton":
                case "clipBoardButton":
                case "topBarColorButton":
                    {
                        if (ToolPanel.isToolBox2Showing || InputManager.isKeyPressed() || e.target.alpha < 1.0)
                        {
                            return;
                        }
                        InputManager.handleMouseClickStage(targetName);
                    }
                    return;
                case "loadButton":
                case "replayModeButton":
                case "gridButton":
                case "penOptionButton":
                case "aboutButton":
                case "updateButton":
                case "sideBarPositionButton":
                case "sideBarPositionButton2":
                case "sideBarOFFButton":
                case "sideBarOFFButton2":
                case "sideBarONButton":
                case "sideBarONButton2":
                case "refMenuCloseButton":
                case "refTransferCanvasImageButton":
                case "refLoadImageButton":
                case "refMirrorImageButton":
                case "refMemoryTrainingOnButton":
                case "refMemoryTrainingOffButton":
                case "refClipBoardButton":
                case "appResetButton":
                case "dpiButton":
                case "newWindowButton":
                case "newWindowCloseButton":
                    {
                        if (ToolPanel.isToolBox2Showing || InputManager.isKeyPressed() || e.target.alpha < 1.0)
                        {
                            return;
                        }
                        InputManager.handleMouseClickStage(targetName, onClickDrawModeButton);
                    }
                    return;
                case "replaySpeedSliderWrapper":
                    {
                        // grid 에서 불러줬을때 캔버스에 안무것도 못하게
                    }
                    return;
                case "refClearImageButton":
                    {
                        if(!ReferenceLayerController.isRefLayerEmpty())
                        {
                            InputManager.startPressHoldKey(ReferenceLayerController.refLayerMenuBox.refClearImageButton, "Erasing reference image...", null, ReferenceLayerController.startReflayerClear, null);
                        }
                    }
                    return;
                case "timer":
                    {
                        InputManager.startPressHoldKey(UIController.topBar.timer, HintStrings.getResetTimerHintString(), null, ActivityWorkTimer.reset, null);
                    }
                    return;
                case "newFileButton":
                    {
                        if (FileManager.canCreateNewFile())
                        {
                            FileManager.createNewFile(false);
                        }
                    }
                    return;
                case "resizeButtonR":
                case "resizeButtonD":
                case "resizeButtonL":
                case "resizeButtonU":
                    {
                        CanvasResizer.start(targetName);
                    }
                    return;
                case "sideBarScrollBar":
                    {
                        SidebarController.startScrollSidebarByDrag();
                    }
                    return;
                case "refRotateImageButton":
                    {
                        Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                        ReferenceLayerController.startRefLayerRotation();
                    }
                    return;
                case "refMoveImageButton":
                    {
                        Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                        ReferenceLayerController.startRefLayerImageDrag();
                    }
                    return;
                case "refResizeImageButton":
                    {
                        Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                        ReferenceLayerController.startRefLayerImageScale();
                    }
                    return;
                case "refOpacitySliderWrapper":
                    {
                        Utils.setAsTopChild(ReferenceLayerController.refLayerMenuBox);
                        ReferenceLayerController.startRefLayerOpacityDrag();
                    }
                    return;
                case "refLayerMenuMoveButton":
                    {
                        DragInteraction.startDragBox(ReferenceLayerController.refLayerMenuBox);
                    }
                    return;
                case "dragDropFileBG":
                    return;
            }
            // 캔버스 영역 밖에서는 해주지 않음
            if (Utils.isCursorInDrawArea() && !MouseState.isClickBlocked)
            {
                ToolController.onCanvasMouseDown();
            }
        }

        // todo numpad켜져있을때 캔버스 바로 클릭하면 바로 다른 툴 적용되게 바꾸어야함
        private static function onRightMouseDownDrawMode(e:MouseEvent):void // rdown1
        {
            if (MouseState.isLeftDown || InputManager.isKeyPressed() || InputManager.isPressingControl() || SidebarController.isQuickSidebarActive
                    || FillPenTool.isStarted || LineTool.isStarted || ToolController.isSelectedTool(ToolController.TOOL_EYEDROPPER) || (ReferenceLayerController.isRefLayerMenuON && ReferenceLayerController.refLayerMenuBox.hitTestPoint(main.mouseX, main.mouseY))
                    || LoadBoxController.loadMenuBox.visible || UIController.topBar.gridButtonWrapper.visible || ColorPickerController.numPadBox.visible)
            {
                return;
            }

            const targetName:String = e.target.name;
            switch (targetName)
            {
                case "saveButton":
                    {
                        FileManager.openSaveFileBrowser(true);
                    }
                    break;

                case "dpiButton":
                    {
                        if (UITheme.getUIScaleIndex() !== 0)
                        {
                            UITheme.resetScaleIndex();
                            UIController.applyUIScale();
                            HintController.showMouseHintTemp(UITheme.getUIScaleString());
                        }
                    }
                    break;

                case "toolZoomIn":
                case "toolZoomOut":
                    {
                        if (CanvasView.canvasZoomMultiplier !== 1.0)
                        {
                            CanvasView.resetZoomDrawMode();
                            CanvasNavigator.updateCursor();
                        }
                    }
                    break;

                case "gridButton":
                    {
                        if (CanvasGridOverlay.gridGapMultiplier !== 0)
                        {
                            HintController.hideBottomHint();
                            CanvasGridOverlay.resetGrid();
                        }
                    }
                    break;

                case "toolRotate":
                    {
                        if (CanvasView.canvasAnchorPoint.rotation !== 0.0)
                        {
                            CanvasView.resetRotationDrawMode();
                            CanvasNavigator.updateCursor();
                        }
                    }
                    break;

                case "sideBarScrollBar":
                    {
                        SidebarController.resetSideBarPosition();
                    }
                    break;

                default:
                    {
                        if (Utils.isCursorInDrawArea())
                        {
                            if (ToolPanel.isToolBox2Showing && !UndoController.isDeepUndoEnabled)
                            {
                                ToolPanel.closeToolBox2();
                            }
                            else
                            {
                                ToolPanel.openToolBox2();
                            }
                        }
                    }
                    break;
            }
        }

        private static function checkPenOptionsKeyDown(keyCode:uint):Boolean
        {
            const secondKey:int = InputManager.getSecondPressedKey();
            if (secondKey === InputManager.KEY.n3 || secondKey === InputManager.KEY.n8)
            {
                if (ToolPanel.toolOptionsBox.sharpLineButtonWrapper.alpha === 1.0)
                {
                    PenSettings.toggleSharpLineByShortcut();
                }
                return true;
            }
            else if (secondKey === InputManager.KEY.n4 || secondKey === InputManager.KEY.n7)
            {
                if (ToolController.isSelectedToolPenOrLine() || ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
                {
                    PenSettings.togglePenAirBrushButtonShortCut();
                    return true;
                }
                else if (ToolController.isSelectedTool(ToolController.TOOL_ERASER))
                {
                    PenSettings.toggleEraseAirBrushButtonShortCut();
                    return true;
                }
            }
            return false;
        }

        private static function handleKeyDownPenOpacitySize(keyCode:uint):Boolean
        {
            switch (keyCode)
            {
                case InputManager.KEY.f:
                case InputManager.KEY.h:
                    InputManager.startKeyRepeat(true, PenSettings.adjustDrawToolSizeByShortcut, true);
                    return true;
                case InputManager.KEY.v:
                case InputManager.KEY.n:
                    InputManager.startKeyRepeat(true, PenSettings.adjustDrawToolSizeByShortcut, false);
                    return true;
                case InputManager.KEY.g:
                    InputManager.startKeyRepeat(true, PenSettings.adjustDrawToolAlphaByShortcut, true);
                    return true;
                case InputManager.KEY.b:
                    InputManager.startKeyRepeat(true, PenSettings.adjustDrawToolAlphaByShortcut, false);
                    return true;
            }
            return false;
        }
    }
}
