package Modules.UIEngine
{
    import Modules.Tools.ToolPanel;
    import Modules.CanvasViewport;
    import Modules.DrawEngine.DrawCanvas;
    import Modules.MouseState;
    import Modules.AboutBoxController;
    import Modules.CaptureEngine.CaptureController;
    import Modules.ColorPickerController;
    import Modules.Tools.FillPenTool;
    import Modules.Tools.PenSettings;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayState;
    import Modules.SidebarController;
    import Modules.Tools.ToolController;
    import Modules.Tools.LassoTool;
    import Modules.Tools.LineTool;
    import Modules.Utils;
    import Symbols.HintBoxSet;

    import flash.display.DisplayObject;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;

    // 마우스 힌트, 하단 힌트 바, 힌트 하이라이트 박스 표시. 문구는 HintStrings가 담당
    public final class HintController
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static const BOTTOM_BAR_HEIGHT:Number = 25;
        public static var mouseHint:HintBoxSet = new HintBoxSet(true);
        public static var bottomHint:HintBoxSet = new HintBoxSet(false);
        public static const bottomBar:Sprite = new Sprite();
        private static const hintHighlightBox:Shape = new Shape(); // 요소에 마우스 클릭하면 사각형으로 하이라이트 표시해줌
        private static const lastBottomHintTargetRect:Rectangle = new Rectangle(); // bottomhint mosue move에서 자꾸 호출해주니까 저장해서 호출 덜하게 해줌
        private static const BOTTOM_HINT_SCROLL_TIMER:String = "bottomHintScrollTimer";
        private static var bottomHintScrollWaitFrames:int = 0;
        private static var bottomHintScrollToLeft:Boolean = true;
        private static const BOTTOM_HINT_SCROLL_SPEED:Number = 2;

        // 하단 힌트 바 구성 + 힌트 요소들을 스테이지에 올림 (상단바 위, 선택 툴 표시 아래 순서)
        public static function initialize():void
        {
            bottomBar.name = "bottomBar";
            bottomBar.addChild(bottomHint);
            bottomHint.x = 2;
            bottomHint.y = 3;

            main.stage.addChild(hintHighlightBox);
            main.stage.addChild(bottomBar);
            main.stage.addChild(mouseHint);
        }

        public static function isSameWithLastBottomHintTargetRect(target:DisplayObject):Boolean
        {
            return lastBottomHintTargetRect.equals(target.getBounds(main.stage));
        }

        private static function updateLastBottomHintTargetRect(target:DisplayObject):void
        {
            const rect:Rectangle = target.getBounds(main.stage);

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
                const xCanvasPanel:Sprite = CanvasViewport.current().panel;
                if (CaptureController.isFullImageCapture() && xCanvasPanel.hitTestPoint(main.stage.mouseX, main.stage.mouseY, true))
                {
                    showHintHighlightBox(CanvasViewport.current().layer1Bitmap);
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
            else if (ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
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

        public static function showHintHighlightBox(target:DisplayObject):void
        {
            const scale:Number = UITheme.getUIScale();
            hintHighlightBox.graphics.clear();
            hintHighlightBox.graphics.lineStyle(2 * scale, UITheme.getHintHightlightColor(), 1.0);

            if (target.parent === CanvasNavigator.box)
            {
                target = CanvasNavigator.box;
            }

            const rect:Rectangle = target.getBounds(main.stage);

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
            hintHighlightBox.graphics.drawRect(0, 0, rect.width, rect.height);
            updateHightLightBoxZOrderByTarget(target);
            hintHighlightBox.visible = true;
        }

        private static function updateHightLightBoxZOrderByTarget(target:DisplayObject):void
        {
            const topIndex:int = main.stage.numChildren - 1;
            const tbIndex:int = main.stage.getChildIndex(UIController.topBar);
            const hIndex:int = main.stage.getChildIndex(hintHighlightBox);

            if (UIController.topBar.contains(target) || ReplayController.seekBarBox.contains(target))
            {
                var desiredIndex:int = Math.min(tbIndex + 1, topIndex);
                if (hIndex != desiredIndex)
                {
                    main.stage.setChildIndex(hintHighlightBox, desiredIndex);
                }
            }
            else
            {
                var desiredIndex2:int = Math.max(tbIndex - 1, 0);
                if (hIndex != desiredIndex2)
                {
                    main.stage.setChildIndex(hintHighlightBox, desiredIndex2);
                }
            }
        }

        private static function hideHintHighlightBox():void
        {
            hintHighlightBox.graphics.clear();
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
                if (bottomHint.width > main.stage.stageWidth)
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

        public static function showMouseHintTemp(str:String, duration:Number = 2.0):void
        {
            showMouseHint(str, duration);
        }

        public static function showMouseHint(str:String, duration:Number = 0.0):void
        {
            if (str !== "")
            {
                mouseHint.setHintText(str);
            }

            const stw:uint = main.stage.stageWidth + 1;
            const sth:uint = main.stage.stageHeight + 1;
            const hintWidth:Number = mouseHint.getScaledTextWidth();
            const hintHeight:Number = mouseHint.getScaledTextHeight();
            var hintX:Number = Math.floor(main.mouseX - hintWidth / 2) + 5;
            var hintY:Number = Math.floor(main.mouseY - 45 * UITheme.getUIScale());
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

        // 커서 대신 target 윗부분 가운데에 마우스 힌트를 띄움
        public static function showMouseHintAtTopCenter(str:String, target:DisplayObject):void
        {
            showMouseHint(str);

            const rect:Rectangle = target.getBounds(main.stage);
            mouseHint.x = Math.floor(rect.x + (rect.width - mouseHint.getScaledTextWidth()) / 2);
            mouseHint.y = Math.floor(rect.y + 4 * UITheme.getUIScale());
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

            const rect:Rectangle = bottomHint.getBounds(main.stage);
            const scale:Number = rect.width / bottomHint.width;
            const move:Number = BOTTOM_HINT_SCROLL_SPEED * scale;

            if (bottomHintScrollWaitFrames < main.stage.frameRate)
            {
                bottomHintScrollWaitFrames++;
                return true;
            }

            if (bottomHintScrollToLeft)
            {
                if (rect.right > main.stage.stageWidth)
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

        public static function updateBottomBarLayoutAndColor():void
        {
            bottomBar.x = 0;
            bottomBar.y = main.stage.stageHeight - BOTTOM_BAR_HEIGHT * UITheme.getUIScale();

            bottomBar.graphics.clear();
            // WorkspaceView.bottomBar.graphics.lineStyle(0,0xFF0000,0.0);
            bottomBar.graphics.beginFill(UITheme.getHintBGColor(), 0.75);
            bottomBar.graphics.drawRect(-3, 0, main.stage.stageWidth + 6, BOTTOM_BAR_HEIGHT + 3);
            bottomBar.graphics.endFill();
        }
    }
}
