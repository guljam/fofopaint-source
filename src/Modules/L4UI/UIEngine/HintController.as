package Modules.L4UI.UIEngine
{
    import Modules.L1Data.AppContext;
    import Symbols.HintBoxSet;

    import flash.display.DisplayObject;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import Modules.L4UI.ColorPickerController;
    import Modules.L4UI.SidebarController;
    import Modules.L4UI.Tools.ToolPanel;
    import Modules.L4UI.AboutBoxController;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L1Data.Tools.PenSettings;
    import Modules.L1Data.ToolState;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L4UI.CanvasViewport;
    import Modules.L2Engine.ReplayEngine.ReplayState;
    import Modules.L4UI.HintStrings;
    import Modules.L1Data.MouseState;
    import Modules.L1Data.Utils;
    import Modules.L4UI.Tools.LineTool;
    import Modules.L4UI.Tools.FillPenTool;
    import Modules.L4UI.Tools.LassoTool;
    import Modules.L4UI.CaptureEngine.CaptureController;
    import Modules.L1Data.KeyState;
    import Modules.L1Data.FOFOTimer;
    import Modules.L1Data.UIEngine.UITheme;
    import Modules.L2Engine.DrawEngine.HandDrawnLine;
    import flash.utils.getTimer;

    // 마우스 힌트, 하단 힌트 바, 힌트 하이라이트 박스 표시. 문구는 HintStrings가 담당
    // 층: L4 UI - 마우스 힌트, 하단 힌트 바, 힌트 하이라이트 박스 표시
    public final class HintController
    {
        public static const BOTTOM_BAR_HEIGHT:Number = 25;
        public static var mouseHint:HintBoxSet = new HintBoxSet(true);
        public static var bottomHint:HintBoxSet = new HintBoxSet(false);
        public static const bottomBar:Sprite = new Sprite();
        private static const bottomHintBorderUI:BottomHintBorderUI = new BottomHintBorderUI(bottomBar); // 하단 힌트 바 가장자리를 해진 모양으로 자르는 마스크
        private static const hintHighlightBox:Sprite = new Sprite(); // 요소에 마우스 클릭하면 사각형으로 하이라이트 표시해줌. 크기별로 그려 둔 Shape 중 하나를 담음
        public static const HIGHLIGHT_BOX_SEED:int = int(Math.random() * 2147483647); // 앱을 켤 때 한 번 정해져서 실행 중에는 같은 크기의 하이라이트가 항상 같은 모양임. MessageBoxController의 메시지 하이라이트도 같이 씀
        private static const HIGHLIGHT_BOX_CACHE_LIMIT:int = 64; // 크기별 저장이 끝없이 늘지 않게 하는 한도
        private static var highlightBoxShapeBySize:Object = {}; // "가로x세로" -> 그 크기로 한 번 그려 둔 Shape
        private static var highlightBoxShapeCount:int = 0;
        private static var highlightBoxCachedColor:uint = 0;
        private static var highlightBoxShowingShape:Shape = null; // hintHighlightBox에 지금 들어 있는 Shape
        private static const variableSizeHighlightShape:Shape = new Shape(); // 창 크기·확대에 따라 크기가 계속 바뀌는 대상(사이드바 스크롤 바, 시크바 트랙, 캡처 모드 캔버스)이 같이 쓰는 하이라이트 Shape. 크기별로 저장하지 않고 크기나 색이 바뀔 때만 다시 그림
        private static var variableSizeHighlightDrawnWidth:Number = NaN;
        private static var variableSizeHighlightDrawnHeight:Number = NaN;
        private static var variableSizeHighlightDrawnColor:uint = 0;
        private static const lastBottomHintTargetRect:Rectangle = new Rectangle(); // bottomhint mosue move에서 자꾸 호출해주니까 저장해서 호출 덜하게 해줌
        private static const BOTTOM_HINT_SCROLL_TIMER:String = "bottomHintScrollTimer";
        private static var bottomHintScrollWaitFrames:int = 0;
        private static var bottomHintScrollToLeft:Boolean = true;
        private static const BOTTOM_HINT_SCROLL_SPEED:Number = 2;

        // 하단 힌트 바 구성 + 힌트 요소들을 스테이지에 올림 (상단바 위, 선택 툴 표시 아래 순서)
        public static function initialize():void
        {
            bottomBar.name = "bottomBar";
            hintHighlightBox.mouseEnabled = false;
            hintHighlightBox.mouseChildren = false;
            bottomBar.addChild(bottomHint);
            bottomHint.x = 2;
            bottomHint.y = 3;

            AppContext.stage.addChild(hintHighlightBox);
            AppContext.stage.addChild(bottomBar);
            AppContext.stage.addChild(mouseHint);
        }

        public static function isSameWithLastBottomHintTargetRect(target:DisplayObject):Boolean
        {
            return lastBottomHintTargetRect.equals(target.getBounds(AppContext.stage));
        }

        private static function updateLastBottomHintTargetRect(target:DisplayObject):void
        {
            const rect:Rectangle = target.getBounds(AppContext.stage);

            lastBottomHintTargetRect.x = rect.x;
            lastBottomHintTargetRect.y = rect.y;
            lastBottomHintTargetRect.width = rect.width;
            lastBottomHintTargetRect.height = rect.height;
        }

        public static function resetLastBottomHintTargetRect():void
        {
            lastBottomHintTargetRect.x = 0;
            lastBottomHintTargetRect.y = 0;
            lastBottomHintTargetRect.width = 0;
            lastBottomHintTargetRect.height = 0;
        }

        public static function isHintUnavailable():Boolean
        {
            return MouseState.isLeftDown || MouseState.isRightDown || MouseState.isDragging || ToolPanel.isToolBox2Showing
                || ColorPickerController.numPadBox.visible || AboutBoxController.isAboutBoxOpened || ReplayState.isGeneratingCacheImages();
            // || isFillPenStarted
            // || isLassoToolStarted
        }

        public static function showMouseHintLayerChecked():void
        {
            showMouseHintTemp(HintStrings.getLayerCheckedHint(DrawCanvas.isLayer2Selected));
        }
        public static function showMouseHintLayerVisible():void
        {
            showMouseHintTemp(HintStrings.getLayerVisibleHint(DrawCanvas.canvasLayer1Bitmap.visible, DrawCanvas.canvasLayer2Bitmap.visible));
        }

        private static function showBottomHintForTargetCaptureMode(target:DisplayObject):void
        {
            if (isHintUnavailable())
            {
                return;
            }

            const hint:String = HintStrings.getHintFromTargetNameCaptureMode(target.name);

            if (hint)
            {
                FOFOTimer.remove("bottomHintOffDelay");

                const targetName:String = target.name;
                const xCanvasPanel:Sprite = CanvasViewport.getCurrentVisibleViewport().canvasPanel;
                if (CaptureController.isFullImageCapture() && xCanvasPanel.hitTestPoint(AppContext.stage.mouseX, AppContext.stage.mouseY, true))
                {
                    showHintHighlightBox(CanvasViewport.getCurrentVisibleViewport().layer1Bitmap);
                    showBottomHint(hint);
                }
                else if (!(targetName === "rCanvasPanel"
                            || targetName === "rCanvasDrawLayer"
                            || targetName === "canvasPanel"
                            || targetName === "canvasDrawLayer"))
                {
                    showHintHighlightBox(target);
                    showBottomHint(hint);
                }
            }
            else
            {
                if (!FOFOTimer.hasTimer("bottomHintOffDelay"))
                {
                    FOFOTimer.addByName("bottomHintOffDelay", 0.3, false, hideBottomHint);
                }
            }
        }

        public static function isHintAvailableWithFillPen(target:DisplayObject):Boolean
        {
            const targetName:String = target.name;
            if (FillPenTool.isStarted || LineTool.isStarted)
            {
                if (target.alpha > 0.5
                        &&
                        (ToolPanel.toolBox.contains(target)
                            || UIController.canvasInfoBox.contains(target)
                            || ColorPickerController.colorPickerBox.contains(target))
                        || target === SidebarController.sideBarScrollBar
                        || (targetName && targetName.indexOf(UITheme.ALPHA_BUTTON_PREFIX) !== -1)
                        || (FillPenTool.isStarted && PenSettings.isFillPenSizeChangeable() && targetName && targetName.indexOf(UITheme.NSIZE_BUTTON_PREFIX) !== -1)
                        || (FillPenTool.isStarted && target === ToolPanel.toolOptionsBox.airBrushButtonWrapper))
                {
                    return true;
                }
                else
                {
                    return false;
                }
            }
            else if (ToolState.isSelectedTool(ToolState.TOOL_FILLPEN))
            {
                if ((targetName && targetName.indexOf(UITheme.NSIZE_BUTTON_PREFIX) !== -1 && !PenSettings.isFillPenSizeChangeable()) || target.alpha < 0.5)
                {
                    return false;
                }
            }
            else if (isHintUnavailable())
            {
                return false;
            }
            return true;
        }

        public static function onMouseMoveBottomHint(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if (!target)
            {
                return;
            }

            if (isSameWithLastBottomHintTargetRect(target) || ToolPanel.isToolBox2Showing)
            {
                return;
            }

            FOFOTimer.remove("bottomHintOnDelay");
            updateLastBottomHintTargetRect(target);

            if (CaptureController.isCaptureModeON)
            {
                showBottomHintForTargetCaptureMode(target);
            }
            else if (LassoTool.isStarted)
            {
                if (LassoTool.isHintAvailableWithLassoToolStarted(target))
                {
                    showBottomHintForTarget(target);
                }
            }
            else if (isHintAvailableWithFillPen(target))
            {
                showBottomHintForTarget(target);
            }
        }

        public static function showBottomHintForTarget(target:DisplayObject):void
        {
            const hint:String = HintStrings.getHintFromTargetName(target.name);

            if (hint)
            {
                FOFOTimer.remove("bottomHintOffDelay");

                if (CanvasNavigator.isNavigatorChild(target))
                {
                    showHintHighlightBox(CanvasNavigator.box.navStageBG);
                }
                else
                {
                    showHintHighlightBox(target);
                }

                if (!isBottomBarVisible())
                {
                    FOFOTimer.addByName("bottomHintOnDelay", 1.0, false, showBottomHint, [hint]);
                }
                else if (bottomHint.visible)
                {
                    showBottomHint(hint);
                }
            }
            else
            {
                if (!FOFOTimer.hasTimer("bottomHintOffDelay"))
                {
                    FOFOTimer.addByName("bottomHintOffDelay", 0.3, false, hideBottomHint);
                }
            }
        }

        // target 위치에 크기별로 저장해 둔 손그림 하이라이트 상자를 보여줌
        public static function showHintHighlightBox(target:DisplayObject):void
        {
            const nt:int = getTimer();
            const scale:Number = UITheme.getUIScale();

            if (target.parent === CanvasNavigator.box)
            {
                target = CanvasNavigator.box;
            }

            const rect:Rectangle = target.getBounds(AppContext.stage);

            if (target === ColorPickerController.colorPickerBox.rgbInfoText)
            {
                // rect.y -= 2*scale;
                rect.height -= 2 * scale;
            }
            else if (target === SidebarController.sideBarScrollBar)
            {
                rect.x += 1 * scale;
                rect.y += 1 * scale;
                rect.width -= 2 * scale;
                rect.height -= 2 * scale;
            }

            hintHighlightBox.x = rect.x;
            hintHighlightBox.y = rect.y;
            if (isHighlightSizeVariableTarget(target))
            {
                showVariableSizeHighlightShape(rect.width, rect.height);
            }
            else
            {
                showHintHighlightShapeOfSize(rect.width, rect.height);
            }
            updateHightLightBoxZOrderByTarget(target);
            hintHighlightBox.visible = true;
        }

        // 창 크기·확대에 따라 크기가 계속 바뀌어서 크기별로 저장해 봐야 다시 쓸 일이 거의 없는 대상인지 (사이드바 스크롤 바, 시크바 트랙, 캡처 모드 캔버스)
        private static function isHighlightSizeVariableTarget(target:DisplayObject):Boolean
        {
            return target === SidebarController.sideBarScrollBar
                || target === UIController.seekBarBox.trackBar
                || target === CanvasViewport.getCurrentVisibleViewport().layer1Bitmap;
        }

        // 크기가 계속 바뀌는 대상들이 같이 쓰는 Shape 하나를 hintHighlightBox에 보여줌. 크기나 하이라이트 색이 지난번과 다를 때만 지우고 다시 그림
        private static function showVariableSizeHighlightShape(boxWidth:Number, boxHeight:Number):void
        {
            const highlightColor:uint = UITheme.getHintHightlightColor();

            if (boxWidth !== variableSizeHighlightDrawnWidth || boxHeight !== variableSizeHighlightDrawnHeight || highlightColor !== variableSizeHighlightDrawnColor)
            {
                variableSizeHighlightShape.graphics.clear();
                HandDrawnLine.drawRect(variableSizeHighlightShape.graphics, 2, highlightColor, 1.0, 0, 0, boxWidth, boxHeight, null, 1.0, 0.01, HIGHLIGHT_BOX_SEED);
                variableSizeHighlightDrawnWidth = boxWidth;
                variableSizeHighlightDrawnHeight = boxHeight;
                variableSizeHighlightDrawnColor = highlightColor;
            }

            setHintHighlightBoxShowingShape(variableSizeHighlightShape);
        }

        // boxWidth x boxHeight 크기로 한 번 그려 둔 하이라이트 Shape를 hintHighlightBox에 보여줌. 처음 보는 크기만 새로 그리고 같은 크기는 저장해 둔 것을 그대로 씀.
        // 하이라이트 색이 바뀌었거나(테마 변경) 저장이 한도를 넘으면 저장을 비우고 다시 쌓음
        private static function showHintHighlightShapeOfSize(boxWidth:Number, boxHeight:Number):void
        {
            const highlightColor:uint = UITheme.getHintHightlightColor();

            if (highlightColor !== highlightBoxCachedColor || highlightBoxShapeCount >= HIGHLIGHT_BOX_CACHE_LIMIT)
            {
                clearHighlightBoxShapeCache();
                highlightBoxCachedColor = highlightColor;
            }

            const sizeKey:String = boxWidth + "x" + boxHeight;
            var sizeShape:Shape = highlightBoxShapeBySize[sizeKey] as Shape;

            if (sizeShape === null)
            {
                sizeShape = new Shape();
                HandDrawnLine.drawRect(sizeShape.graphics, 2, highlightColor, 1.0, 0, 0, boxWidth, boxHeight, null, 1.0, 0.01, HIGHLIGHT_BOX_SEED);
                highlightBoxShapeBySize[sizeKey] = sizeShape;
                highlightBoxShapeCount++;
            }

            setHintHighlightBoxShowingShape(sizeShape);
        }

        // hintHighlightBox에 들어 있는 Shape를 shape로 바꿈. 이미 들어 있으면 아무것도 안 함
        private static function setHintHighlightBoxShowingShape(shape:Shape):void
        {
            if (highlightBoxShowingShape !== shape)
            {
                if (highlightBoxShowingShape !== null)
                {
                    hintHighlightBox.removeChild(highlightBoxShowingShape);
                }

                hintHighlightBox.addChild(shape);
                highlightBoxShowingShape = shape;
            }
        }

        // 크기별로 저장해 둔 하이라이트 Shape를 모두 버림
        private static function clearHighlightBoxShapeCache():void
        {
            if (highlightBoxShowingShape !== null)
            {
                hintHighlightBox.removeChild(highlightBoxShowingShape);
                highlightBoxShowingShape = null;
            }

            highlightBoxShapeBySize = {};
            highlightBoxShapeCount = 0;
        }

        private static function updateHightLightBoxZOrderByTarget(target:DisplayObject):void
        {
            const topIndex:int = AppContext.stage.numChildren - 1;
            const tbIndex:int = AppContext.stage.getChildIndex(UIController.topBar);
            const hIndex:int = AppContext.stage.getChildIndex(hintHighlightBox);

            if (UIController.topBar.contains(target) || UIController.seekBarBox.contains(target))
            {
                var desiredIndex:int = Math.min(tbIndex + 1, topIndex);
                if (hIndex != desiredIndex)
                {
                    AppContext.stage.setChildIndex(hintHighlightBox, desiredIndex);
                }
            }
            else
            {
                var desiredIndex2:int = Math.max(tbIndex - 1, 0);
                if (hIndex != desiredIndex2)
                {
                    AppContext.stage.setChildIndex(hintHighlightBox, desiredIndex2);
                }
            }
        }

        // 하이라이트를 숨김. 그려 둔 Shape는 같은 크기가 다시 올 때 쓰려고 지우지 않음
        private static function hideHintHighlightBox():void
        {
            hintHighlightBox.visible = false;
        }

        public static function isBottomBarVisible():Boolean
        {
            return bottomBar.visible;
        }

        public static function isHighlightBoxVisible():Boolean
        {
            return hintHighlightBox.visible;
        }

        public static function hideBottomHint():void
        {
            FOFOTimer.remove("bottomHintOnDelay");
            hideHintHighlightBox();
            bottomBar.visible = false;
            bottomHint.hide();
        }

        public static function showBottomHint(str:String):void
        {
            if (str === "")
            {
                return;
            }

            const wasVisible:Boolean = bottomBar.visible && bottomHint.visible;
            const textChanged:Boolean = !bottomHint.hasHintText(str);

            if (textChanged)
            {
                bottomHint.setHintText(str);
            }

            bottomHint.show();

            if (!bottomBar.visible)
            {
                updateBottomBarLayoutAndColor();
            }

            bottomBar.visible = true;
            Utils.setAsTopChild(bottomBar);

            if (textChanged || !wasVisible)
            {
                if (bottomHint.width > AppContext.stage.stageWidth)
                {
                    startBottomHintScrolling();
                }
                else
                {
                    stopBottomHintScrolling();
                }
            }
        }

        public static function hideMouseHint():void
        {
            mouseHint.hide();
        }

        public static function showMouseHintTemp(str:String, duration:Number = 3.0):void
        {
            showMouseHint(str, duration);
        }

        public static function showMouseHint(str:String, duration:Number = 0.0):void
        {
            if (str !== "")
            {
                mouseHint.setHintText(str);
            }

            const stw:uint = AppContext.stage.stageWidth + 1;
            const sth:uint = AppContext.stage.stageHeight + 1;
            const hintWidth:Number = mouseHint.getScaledTextWidth();
            const hintHeight:Number = mouseHint.getScaledTextHeight();
            var hintX:Number = Math.floor(AppContext.stage.mouseX - hintWidth / 2) + 5;
            var hintY:Number = Math.floor(AppContext.stage.mouseY - 45 * UITheme.getUIScale());
            const hintRight:int = hintX + hintWidth;
            const hintBottom:int = hintY + hintHeight;

            if (hintX < 0)
            {
                hintX = 0;
            }
            else if (hintRight > stw)
            {
                hintX = stw - hintWidth;
            }

            if (hintY < 0)
            {
                hintY = 0;
            }
            else if (hintBottom >= sth)
            {
                hintY = sth - hintHeight;
            }

            mouseHint.x = Math.floor(hintX);
            mouseHint.y = Math.floor(hintY);
            mouseHint.setHintText(str);
            mouseHint.show(duration);
            Utils.setAsTopChild(mouseHint);
        }

        // 커서 대신 target 정중앙에 마우스 힌트를 띄움
        public static function showMouseHintAtCenter(str:String, target:DisplayObject):void
        {
            showMouseHint(str);

            const rect:Rectangle = target.getBounds(AppContext.stage);
            mouseHint.x = Math.floor(rect.x + (rect.width - mouseHint.getScaledTextWidth()) / 2);
            mouseHint.y = Math.floor(rect.y + (rect.height - mouseHint.getScaledTextHeight()) / 2);
        }

        private static function resetBottomHintScrolling():void
        {
            bottomHint.x = 0;
            bottomHintScrollWaitFrames = 0;
            bottomHintScrollToLeft = true;
        }

        private static function animateBottomHintScrolling():Boolean
        {
            if (!bottomHint.visible)
            {
                resetBottomHintScrolling();
                return false;
            }

            const rect:Rectangle = bottomHint.getBounds(AppContext.stage);
            const scale:Number = rect.width / bottomHint.width;
            const move:Number = BOTTOM_HINT_SCROLL_SPEED * scale;

            if (bottomHintScrollWaitFrames < AppContext.stage.frameRate)
            {
                bottomHintScrollWaitFrames++;
                return true;
            }

            if (bottomHintScrollToLeft)
            {
                if (rect.right > AppContext.stage.stageWidth)
                {
                    bottomHint.x -= move;
                }
                else
                {
                    bottomHintScrollToLeft = false;
                    bottomHintScrollWaitFrames = 0;
                }
            }
            else
            {
                if (rect.left < 0)
                {
                    bottomHint.x += move;
                }
                else
                {
                    bottomHintScrollToLeft = true;
                    bottomHintScrollWaitFrames = 0;
                }
            }

            return true;
        }

        private static function startBottomHintScrolling():void
        {
            resetBottomHintScrolling();

            FOFOTimer.remove(BOTTOM_HINT_SCROLL_TIMER);
            FOFOTimer.addByName(
                    BOTTOM_HINT_SCROLL_TIMER,
                    0.0,
                    true,
                    animateBottomHintScrolling
                );
        }

        private static function stopBottomHintScrolling():void
        {
            FOFOTimer.remove(BOTTOM_HINT_SCROLL_TIMER);
            resetBottomHintScrolling();
        }

        // 하단 힌트 바 위치와 배경을 다시 그리고, 가장자리 마스크도 바 크기에 맞춤
        public static function updateBottomBarLayoutAndColor():void
        {
            bottomBar.x = 0;
            bottomBar.y = AppContext.stage.stageHeight - BOTTOM_BAR_HEIGHT * UITheme.getUIScale();

            bottomBar.graphics.clear();
            // WorkspaceView.bottomBar.graphics.lineStyle(0,0xFF0000,0.0);
            bottomBar.graphics.beginFill(UITheme.getHintBGColor(), 0.75);
            bottomBar.graphics.drawRect(-3, 0, AppContext.stage.stageWidth + 6, BOTTOM_BAR_HEIGHT + 3);
            bottomBar.graphics.endFill();
            bottomHintBorderUI.updateBottomBarBorderSize(AppContext.stage.stageWidth + 6, BOTTOM_BAR_HEIGHT + 3);
        }

        // 키 오래누름 관련 변수
        public static var pressHoldCountDownTime:Number = 0.0;

        public static var pressHoldFrameCount:int = 0;

        // abortFunc: 길게 누르는 도중에 true를 반환하면 취소함 (예: worker가 시작되어 리플레이 데이터가 잠겼을때)
        public static function startPressHoldKey(button:DisplayObject, hintStr:String, readyFunc:Function, okFunc:Function, cancelFunc:Function, abortFunc:Function = null):void
        {
            if (!FOFOTimer.hasTimer("pressholdtimer"))
            {
                var keyBufferLenSave:uint = KeyState.getPressedKeyCount();
                var mouseClickONSave:Boolean = MouseState.isLeftDown;
                var rightMouseClickONSave:Boolean = MouseState.isRightDown;
                const countDownTime:Number = 3;
                const countDownTimeNow:Number = Math.ceil((AppContext.stage.frameRate * 2.5) / countDownTime);
                pressHoldCountDownTime = countDownTime;
                pressHoldFrameCount = 0;
                if (readyFunc !== null)
                {
                    if (readyFunc() === true)
                    {
                        return;
                    }
                }
                function cancelHoldingKey():void
                {
                    pressHoldFrameCount = 0;
                    pressHoldCountDownTime = countDownTime;
                    HintController.hideMouseHint();
                }
                if (hintStr !== "")
                {
                    HintController.showMouseHint(hintStr + " " + pressHoldCountDownTime);
                }
                FOFOTimer.addByName("pressholdtimer", 0.0, true, function ():Boolean
                    {
                        if (MouseState.isLeftDown !== mouseClickONSave
                                || MouseState.isRightDown !== rightMouseClickONSave
                                || keyBufferLenSave !== KeyState.getPressedKeyCount()
                                || (button && button.hitTestPoint(AppContext.stage.mouseX, AppContext.stage.mouseY) === false)
                                || (abortFunc !== null && abortFunc() === true))
                        {
                            if (cancelFunc !== null)
                            {
                                cancelFunc();
                            }
                            cancelHoldingKey();
                            return false;
                        }
                        pressHoldFrameCount++;
                        if (pressHoldFrameCount >= countDownTimeNow)
                        {
                            pressHoldFrameCount = 0;
                            pressHoldCountDownTime--;
                        }
                        HintController.showMouseHint(hintStr + " " + pressHoldCountDownTime);
                        if (pressHoldCountDownTime <= 0)
                        {
                            cancelHoldingKey();
                            okFunc();
                            return false;
                        }
                        return true;
                    });
            }
        }

    }
}
