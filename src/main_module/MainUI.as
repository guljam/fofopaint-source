package main_module
{
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.geom.Rectangle;
    import flash.display.DisplayObject;
    import flash.events.MouseEvent;

    public final class MainUI
    {
        private static const main:Main = Main._instance;
        public static const stageBG:Sprite = new Sprite(); // 드래그 불러오기가 stage공백에서는 안되서 수동으로 전체바탕으로 만들어줌
        public static const topBar:TopMenuSet = new TopMenuSet();
        public static const mouseHint:HintBoxSet = new HintBoxSet(main.stage, true);
        public static const bottomHint:HintBoxSet = new HintBoxSet(main.stage, false);
        public static const bottomHintScrolling:HintScrolling = new HintScrolling(bottomHint, main.stage);
        public static const bottomBar:Sprite = new Sprite();
        public static const hintHighlightBox:Shape = new Shape(); // 요소에 마우스 클릭하면 사각형으로 하이라이트 표시해줌
        public static const lastBottomHintTargetRect:Rectangle = new Rectangle(); // bottomhint mosue move에서 자꾸 호출해주니까 저장해서 호출 덜하게 해줌
        public static const canvasRotateCursor:RotateCursorSet = new RotateCursorSet(); // 회전이 얼마나 됐는지 표시,

        public static function isSameWithLastBottomHintTargetRect(target:DisplayObject):Boolean
        {
            return lastBottomHintTargetRect.equals(target.getBounds(main.stage));
        }

        public static function updateLastBottomHintTargetRect(target:DisplayObject):void
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

        public static function getImageScaleHint(width:Number, height:Number, scale:Number, scaleXFlag:Boolean):String
        {
            const scaleStr:String = Math.round(scale * 100) + "%";
            if (scaleXFlag)
            {
                return Math.round(width * scale) + " x " + Math.round(height * scale) + " (" + scaleStr + ")";
            }
            return Math.round(width) + " x " + Math.round(height) + " (" + scaleStr + ")";
        }

        public static function isHintUnavailable():Boolean
        {
            return main.isMouseClicked || main.isRightMouseClicked || main.isMouseDragging || main.isToolBox2Showing
                || main.numPadBox.visible || main.isAboutBoxOpened || main.isGeneratingCacheImages();
            // || isFillPenStarted
            // || isLassoToolStarted
        }

        public static function showMouseHintLayerVisible():void
        {
            showMouseHintTemp(HintStrings.getLayerVisibleHint(main.canvasLayer1Bitmap.visible, main.canvasLayer2Bitmap.visible));
        }

        public static function showBottomHintForTargetCaptureMode(target:DisplayObject):void
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
                const xCanvasPanel:Sprite = (main.isReplayModeON) ? main.rCanvasPanel : main.canvasPanel;
                if (main.captureAreaManager.isFullImageCapture() && xCanvasPanel.hitTestPoint(main.stage.mouseX, main.stage.mouseY, true))
                {
                    showHintHighlightBox((main.isReplayModeON) ? main.rCanvasLayer1Bitmap : main.canvasLayer1Bitmap);
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

        public static function onMouseMoveBottomHint(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if (!target)
            {
                return;
            }

            if (isSameWithLastBottomHintTargetRect(target) || main.isToolBox2Showing)
            {
                return;
            }

            FOFOTimer.remove("bottomHintOnDelay");
            updateLastBottomHintTargetRect(target);

            if (main.isCaptureModeON)
            {
                showBottomHintForTargetCaptureMode(target);
            }
            else if (main.isLassoToolStarted)
            {
                if (main.isHintAvailableWithLassoToolStarted(target))
                {
                    showBottomHintForTarget(target);
                }
            }
            else if (main.isHintAvailableWithFillPen(target))
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

                if (main.isCanvasNaviatorChild(target))
                {
                    showHintHighlightBox(main.canvasNavigatorBox.navStageBG);
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
            const scale:Number = Global.getUIScale();
            hintHighlightBox.graphics.clear();
            hintHighlightBox.graphics.lineStyle(2 * scale, Global.getHintHightlightColor(), 1.0);

            if (target.parent === main.canvasNavigatorBox)
            {
                target = main.canvasNavigatorBox;
            }

            const rect:Rectangle = target.getBounds(main.stage);

            if (target === main.colorPickerBox.rgbInfoText)
            {
                // rect.y -= 2*scale;
                rect.height -= 2 * scale;
            }
            else if (target === main.sideBarScrollBar)
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

        public static function updateHightLightBoxZOrderByTarget(target:DisplayObject):void
        {
            const topIndex:int = main.stage.numChildren - 1;
            const tbIndex:int = main.stage.getChildIndex(topBar);
            const hIndex:int = main.stage.getChildIndex(hintHighlightBox);

            if (topBar.contains(target) || main.seekBarBox.contains(target))
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

        public static function hideHintHighlightBox():void
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

            bottomHint.setHintText(str);
            bottomHint.show();
            main.updateBottomBarLayoutAndColor();
            bottomBar.visible = true;
            Utils.setAsTopChild(bottomBar);

            if (bottomHint.width > main.stage.stageWidth)
            {
                bottomHintScrolling.start();
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
            var hintY:Number = Math.floor(main.mouseY - 45 * Global.getUIScale());
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

        public static function updateTopbarIconsDrawMode():void
        {
            topBar.updateIconsByMode(0);
        }

        public static function updateTopbarIconsReplayMode():void
        {
            topBar.updateIconsByMode(1);
        }

        public static function updateTopbarIconsCaptureMode():void
        {
            topBar.updateIconsByMode(2);
        }

        public static function initializeAppMenus():void
        {
            const main:Main = Main._instance;
            main.aboutBox.name = "aboutPanel";
            main.aboutBox.setVersionInfo(main.APP_VERSION.toFixed(2));
            topBar.name = "topBar";
            main.sideBarScrollBar.name = "sideBarScrollBar";
            topBar.makeTopbarBG(Global.UI_COLOR_MID_DARK);
            updateTopbarIconsDrawMode();

            main.fillPenBox.x = -main.fillPenBox.width - 3;
            main.fillPenBox.y = -main.fillPenBox.height - 3;

            main.canvasNavigatorBox.scrollRect = new Rectangle(0, 0, main.canvasNavigatorBox.width, main.canvasNavigatorBox.height);

            main.sideBarScrollPanel.addChild(main.canvasNavigatorBox);
            main.sideBarScrollPanel.addChild(main.canvasInfoBox);
            main.toolBox.moveCanvasControlButtonsTo(main.canvasInfoBox);
            main.sideBarScrollPanel.addChild(main.toolBox);
            main.sideBarScrollPanel.addChild(main.toolOptionsBox);
            main.sideBarScrollPanel.addChild(main.colorPickerBox);

            main.sideBar.addChild(main.sideBarScrollBar);
            main.sideBar.addChild(main.sideBarScrollPanel);
            main.sideBar.updateSideBGSize(main.getSideBarBGHeight());
            main.sideBarScrollBar.alpha = 0.75;
            main.STAGE_TOP_OFFSET = topBar.BARSIZE;

            main.captureStampFontListBox.y = 100;

            topBar.updateTimerPos(main.stage.stageWidth);
            topBar.replayFitToWindowButton.alpha = Global.OFFALPHA;

            bottomBar.name = "bottomBar";
            bottomBar.addChild(bottomHint);
            bottomHint.x = 2;
            bottomHint.y = 3;

            main.selectedToolViewBitmap.name = "selectedToolViewBitmap";
            main.selectedToolViewBitmap.visible = false;

            main.stage.addChild(main.loadMenuBox);
            main.stage.addChild(main.refLayerMenuBox);
            main.stage.addChild(main.aboutBox);
            main.stage.addChild(main.sideBar);
            main.stage.addChild(main.fillPenBox);
            main.stage.addChild(main.toolBox2);
            main.stage.addChild(canvasRotateCursor);
            main.stage.addChild(main.numPadBox);
            main.stage.addChild(main.captureStampFontListBox);
            main.stage.addChild(topBar);
            main.stage.addChild(hintHighlightBox);
            main.stage.addChild(bottomBar);
            main.stage.addChild(mouseHint);
            main.stage.addChild(main.selectedToolViewBitmap);
        }

        public static function hideCanvasRotateCursor():void
        {
            canvasRotateCursor.visible = false;
        }

        public static function showCanvasRotateCursorMouseDrag(target:DisplayObject):Function
        {
            const main:Main = Main._instance;
            const snapThreshold:Number = 82;
            canvasRotateCursor.x = main.stage.mouseX;
            canvasRotateCursor.y = main.stage.mouseY + (65 * Global.getUIScale());
            canvasRotateCursor.rotateArrow.rotation = target.rotation;
            Utils.setAsTopChild(canvasRotateCursor);
            canvasRotateCursor.visible = true;

            const toDeg:Number = 180.0 / Math.PI;
            // 움직인 각도합 로테이트 캔버스 마지막각도를 넣어줌 rad로 변환

            var sumAng:Number = target.rotation;
            // 각도 차이 구하기 위해서 넣어줌, 초기 값은 마우스 클릭한 위치의 각도값
            var lastAng:Number = Math.atan2(main.stage.mouseX - canvasRotateCursor.x, main.stage.mouseY - canvasRotateCursor.y) * toDeg;
            var activateSnapFlag:Boolean = false;
            var ignoreSnapFlag:Boolean = true;
            var snappedAng:Number = 0;

            return function():Number
            {
                const nowAng:Number = Math.atan2(main.stage.mouseX - canvasRotateCursor.x, main.stage.mouseY - canvasRotateCursor.y) * toDeg;
                const subAng:Number = lastAng - nowAng;

                lastAng = nowAng;
                sumAng += subAng;
                var deg:Number = sumAng;
                const snap90:Number = Math.abs(deg % 90.0); // 90도 스냅 변수
                const snap90N:Number = 90.0 - snap90;
                const snapAng:Number = (snap90 > snap90N) ? snap90 : snap90N;

                if (snapAng > snapThreshold && ignoreSnapFlag === false)
                {
                    activateSnapFlag = true;
                    deg = Math.round(deg / 90) * 90;
                    if (snappedAng !== deg)
                    {
                        snappedAng = deg;
                    }
                }
                else if (activateSnapFlag === true)
                {
                    sumAng = snappedAng;
                    deg = snappedAng;
                    activateSnapFlag = false;
                    ignoreSnapFlag = true;
                }
                else if (ignoreSnapFlag === true)
                {
                    if (snapAng <= snapThreshold)
                    {
                        ignoreSnapFlag = false;
                    }
                }

                canvasRotateCursor.rotateArrow.rotation = deg;
                return Math.round(deg);
            };

        }
    }
}
