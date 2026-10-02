package Modules.Tools
{
    import Modules.InputPriority;
    import Modules.MouseState;
    import Modules.PenSizePreviewCursor;
    import Modules.ReferenceLayerController;
    import Modules.SidebarController;
    import Modules.UndoController;
    import Modules.Utils;
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
    import flash.display.DisplayObjectContainer;
    import flash.display.SimpleButton;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import Modules.ReplayEngine.ReplayState;

    // 사이드바의 툴 패널 UI: 툴박스, 우클릭 툴박스(toolBox2), 펜 옵션 박스와 그 클릭/드래그 처리
    // 도구 선택 상태는 ToolController가 가지고, 여기서는 표시와 입력 해석만 함
    public class ToolPanel
    {
        public static var main:Main;

        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static const TOOL_BOX_ON_DELAY_TIME:Number = 0.12;
        public static const toolBox:ToolMenuSet = new ToolMenuSet();
        public static const toolBox2:ToolMenuSet2 = new ToolMenuSet2();
        public static const toolOptionsBox:ToolOptionsSet = new ToolOptionsSet();
        public static var isToolBox2Showing:Boolean = false; // 툴박스가 오른쪽 클릭으로 켜졌을때 올려줌
        public static var selectedToolViewBitmap:Bitmap = new Bitmap();
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
                case ToolController.TOOL_PEN:
                    return toolBox.toolPen;
                case ToolController.TOOL_FILLPEN:
                    return toolBox.toolFillPen;
                case ToolController.TOOL_ERASER:
                    return toolBox.toolEraser;
                case ToolController.TOOL_EYEDROPPER:
                    return toolBox.toolEyedropper;
                case ToolController.TOOL_LASSO:
                    return toolBox.toolLasso;
                case ToolController.TOOL_MOVE:
                    return toolBox.toolMove;
                case ToolController.TOOL_LINE:
                    return toolBox.toolLine;
                case ToolController.TOOL_ZOOM:
                    return toolBox.toolZoomIn;
                case ToolController.TOOL_ROTATE:
                    return toolBox.toolRotate;
                case ToolController.TOOL_HAND:
                    return toolBox.toolHand;
                case ToolController.TOOL_UNDO:
                    return toolBox.toolUndo;
                case ToolController.TOOL_REDO:
                    return toolBox.toolRedo;
                case ToolController.TOOL_MIRROR:
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
            const nt:uint = ToolController.nowTool;

            if (ToolController.isSelectedTool(ToolController.TOOL_ERASER))
                toolName = "Eraser";
            else if (ToolController.isSelectedTool(ToolController.TOOL_LINE))
                toolName = "Line";
            else if (ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
                toolName = "FillPen";

            toolOptionsBox.hintText(toolName);
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

        public static function startPenSmootingAdjustment():void
        {
            const minDist:Number = toolOptionsBox.penSmoothSlider.x + 1; // 펜 리스트에 흰색 선 시작과 끝 x좌표임
            const maxDist:Number = minDist + toolOptionsBox.penSmoothSlider.width - 1;
            const step:Number = PenSettings.penSmoothSlideTotal;
            const div:Number = (maxDist - minDist) / step;

            const maxValue:Number = 0.85;
            const minValue:Number = 0.02;
            const stepValue:Number = (maxValue - minValue) / step;

            const airBrushFlag:Boolean = ToolController.isSelectedToolPenOrLine() && PenSettings.isPenAirBrushON;
            const eraseAirBrushFlag:Boolean = ToolController.isSelectedTool(ToolController.TOOL_ERASER) && PenSettings.isEraserAirBrushON;

            var oldValue:int = PenSettings.penSmoothSlideValue;

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
                        PenSettings.penSmoothValue = 0;
                    }
                    else
                    {
                        PenSettings.penSmoothValue = maxValue - (value * stepValue);
                    }

                    PenSettings.penSmoothSlideValue = value;
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
                            if (!ToolController.isSelectedTool(ToolController.TOOL_PEN))
                            {
                                ToolController.selectPenTool();
                                PenSizePreviewCursor.updateSizeAndShape();
                            }
                        }
                        break;
                    case "toolFillPen":
                        {
                            if (!ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
                            {
                                ToolController.selectFillPenTool();
                                PenSizePreviewCursor.updateSizeAndShape();
                            }
                        }
                        break;
                    case "toolEraser":
                        {
                            if (!ToolController.isSelectedTool(ToolController.TOOL_ERASER))
                            {
                                ToolController.selectEraserTool();
                                PenSizePreviewCursor.updateSizeAndShape();
                            }
                        }
                        break;
                    case "toolLine":
                        {
                            if (!ToolController.isSelectedTool(ToolController.TOOL_LINE))
                            {
                                ToolController.selectLineTool();
                                PenSizePreviewCursor.updateSizeAndShape();
                            }
                        }
                        break;
                    case "toolLasso":
                        {
                            if (!ToolController.isSelectedTool(ToolController.TOOL_LASSO))
                            {
                                ToolController.selectLassoTool();
                            }
                        }
                        break;
                    case "toolEyedropper":
                        {
                            if (SidebarController.isQuickSidebarActive)
                            {
                                ToolController.resetLastTool();
                                toolBox.moveToolCursor("toolEyedropper");
                            }
                            else if (!ToolController.isSelectedTool(ToolController.TOOL_EYEDROPPER))
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
                            ToolController.selectMoveTool();
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

        // ---- 도구가 선택됐을 때의 표시 (ToolController.select*Tool이 상태를 바꾼 뒤 호출) ----

        public static function showPenToolSelected(lineFlag:Boolean):void
        {
            moveEraserButtonToOtherTool((lineFlag) ? "toolLine" : "toolPen");
            toolBox.moveToolCursor((lineFlag) ? "toolLine" : "toolPen");
            updateToolOptionsTextBySelectedTool();
            toolOptionsBox.updatePenShapeSet(PenSettings.penIsSquare);
            enableSizeButtonsIfDisabled();
            toolOptionsBox.enablePenSmoothingSlider();
        }

        public static function showEraserToolSelected():void
        {
            if (lastEraserPosButton)
            {
                lastEraserPosButton.visible = true;
            }

            lastEraserPosButton = null;
            toolBox2.toolEraser.visible = false;
            toolBox.moveToolCursor("toolEraser");
            updateToolOptionsTextBySelectedTool();
            toolOptionsBox.updatePenShapeSet(PenSettings.eraserIsSquare);
            enableSizeButtonsIfDisabled();
            toolOptionsBox.disablePenSmoothingSlider();
        }

        // 채우기 펜은 크기 버튼을 쓰지 않으므로 크기 커서를 1에 두고 크기/모양 버튼을 흐리게 함
        public static function showFillPenToolSelected():void
        {
            toolBox.moveToolCursor("toolFillPen");
            updateOpacityCursorPos(PenSettings.penAlphaIndex);
            toolOptionsBox.movePenSizeCursor(1);
            toolOptionsBox.setButtonsAlphaFillPenSelected(UITheme.OFFALPHA);
            moveEraserButtonToOtherTool("toolFillPen");
            updateToolOptionsTextBySelectedTool();
        }

        // 펜 옵션을 쓰지 않는 도구(이동, 줌, 회전, 올가미). cursorParent는 커서를 옮길 버튼이 있는 박스 (null이면 툴박스)
        public static function showOtherToolSelected(buttonName:String, cursorParent:DisplayObjectContainer = null, moveEraserButton:Boolean = false):void
        {
            toolBox.moveToolCursor(buttonName, cursorParent);
            if (moveEraserButton)
            {
                moveEraserButtonToOtherTool(buttonName);
            }
            enableSizeButtonsIfDisabled();
            toolOptionsBox.enablePenSmoothingSlider();
        }

        public static function setPenSmoothingSliderEnabled(enabled:Boolean):void
        {
            if (enabled)
            {
                toolOptionsBox.enablePenSmoothingSlider();
            }
            else
            {
                toolOptionsBox.disablePenSmoothingSlider();
            }
        }

        // 채우기 펜에서 흐리게 했던 크기/모양 버튼을 되돌림
        private static function enableSizeButtonsIfDisabled():void
        {
            if (toolOptionsBox.isSizeButtonsDisabled())
            {
                toolOptionsBox.setButtonsAlphaFillPenSelected(1.0);
            }
        }

        // ---- 펜 설정 표시 (PenSettings가 값을 바꾼 뒤 호출) ----

        public static function movePenSizeCursor(index:uint):void
        {
            toolOptionsBox.movePenSizeCursor(index);
        }

        public static function updatePenShapeSet(isSquare:Boolean):void
        {
            toolOptionsBox.updatePenShapeSet(isSquare);
        }

        public static function updateSharpLineButtons(flag:Boolean):void
        {
            toolOptionsBox.sharpLineOFFButton.visible = flag;
            toolOptionsBox.sharpLineONButton.visible = !flag;
        }

        public static function updateAirBrushButtons(flag:Boolean):void
        {
            toolOptionsBox.airBrushOFFButton.visible = flag;
            toolOptionsBox.airBrushONButton.visible = !flag;
        }

        // 에어브러시가 켜지면 크기 버튼 모양을 흐리게 보여줌
        public static function setBlurShapeSet(on:Boolean):void
        {
            if (on)
            {
                toolOptionsBox.blurShapeSetON();
            }
            else
            {
                toolOptionsBox.blurShapeSetOFF();
            }
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
                        ToolController.selectPenTool();
                        PenSizePreviewCursor.updateSizeAndShape();
                        showNowToolIconToCursorTemp(ToolController.TOOL_PEN);
                    }
                    break;
                case "toolFillPen":
                    {
                        ToolController.selectFillPenTool();
                        PenSizePreviewCursor.updateSizeAndShape();
                        showNowToolIconToCursorTemp(ToolController.TOOL_FILLPEN);
                    }
                    break;
                case "toolEraser":
                    {
                        ToolController.selectEraserTool();
                        PenSizePreviewCursor.updateSizeAndShape();
                        showNowToolIconToCursorTemp(ToolController.TOOL_ERASER);
                    }
                    break;
                case "toolLine":
                    {
                        ToolController.selectLineTool();
                        PenSizePreviewCursor.updateSizeAndShape();
                        showNowToolIconToCursorTemp(ToolController.TOOL_LINE);
                    }
                    break;
                case "toolLasso":
                    {
                        ToolController.selectLassoTool();
                        showNowToolIconToCursorTemp(ToolController.TOOL_LASSO);
                    }
                    break;
                case "toolEyedropper":
                    {
                        if (!ToolController.isSelectedTool(ToolController.TOOL_EYEDROPPER))
                        {
                            EyeDropperTool.start();
                            showNowToolIconToCursorTemp(ToolController.TOOL_EYEDROPPER);
                        }
                    }
                    break;
                case "toolUndo":
                    {
                        UndoController.undo();
                        showNowToolIconToCursorTemp(ToolController.TOOL_UNDO);
                    }
                    break;
                case "toolRedo":
                    {
                        UndoController.redo();
                        showNowToolIconToCursorTemp(ToolController.TOOL_REDO);
                    }
                    break;
                case "toolMirror":
                    {
                        CanvasView.mirrorCanvas();
                        showNowToolIconToCursorTemp(ToolController.TOOL_MIRROR);
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
                onOpacityButtonDown(targetName);
                ToolController.selectPenToolIfNotDrawingTool(true);
                return true;
            }

            if (targetName.indexOf(UITheme.NSIZE_BUTTON_PREFIX) == 0)
            {
                if (!ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
                {
                    ToolController.selectPenToolIfNotDrawingTool(true);
                    onPenSizeButtonDown(targetName);
                }
                return true;
            }

            switch (targetName)
            {
                case "penSmoothSliderWrapper":
                    {
                        if (ToolController.nowTool !== ToolController.TOOL_PEN)
                        {
                            return true;
                        }

                        ToolController.selectPenToolIfNotDrawingTool(true);
                        startPenSmootingAdjustment();
                    }
                    return true;

                case "shapeRect":
                    {
                        if (!ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
                        {
                            ToolController.selectPenToolIfNotDrawingTool(true);
                            PenSettings.selectPenShapeButton(true);
                        }
                    }
                    return true;
                case "shapeCircle":
                    {
                        if (!ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
                        {
                            ToolController.selectPenToolIfNotDrawingTool(true);
                            PenSettings.selectPenShapeButton(false);
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
                            ToolController.selectPenToolIfNotDrawingTool(true);
                            PenSettings.toggleSharpLine(!PenSettings.isSharpLineON);
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
                            ToolController.selectPenToolIfNotDrawingTool(true);

                            if (ToolController.isSelectedToolPenOrLine() || ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
                            {
                                PenSettings.togglePenAirBrushButton(!PenSettings.isPenAirBrushON);
                            }
                            else if (ToolController.isSelectedTool(ToolController.TOOL_ERASER))
                            {
                                PenSettings.toggleEraseAirBrushButton(!PenSettings.isEraserAirBrushON);
                            }
                        }
                    }
                    return true;
            }

            return false;
        }

        // opabox 버튼을 눌렀을때 즉시 적용하고, 누른채 다른 버튼 위로 끌면 따라서 선택함
        public static function onOpacityButtonDown(targetName:String):void
        {
            PenSettings.setDrawingToolOpacity(targetName);
            startOptionButtonDrag(toolOptionsBox.opaBox, UITheme.ALPHA_BUTTON_PREFIX, targetName, PenSettings.setDrawingToolOpacity);
        }

        // 펜 크기 버튼을 눌렀을때 즉시 적용하고, 누른채 다른 버튼 위로 끌면 따라서 선택함
        public static function onPenSizeButtonDown(targetName:String):void
        {
            PenSettings.selectPenSizeButton(targetName);
            startOptionButtonDrag(toolOptionsBox.penSizeBox, UITheme.NSIZE_BUTTON_PREFIX, targetName, PenSettings.selectPenSizeButton);
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
