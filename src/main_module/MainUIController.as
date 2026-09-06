package main_module
{

    import main_module.SidebarController;
    import flash.display.Sprite;
    import flash.display.DisplayObject;
    import flash.display.SimpleButton;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    // todo: 캔버스 리사이즈 버튼은 나중에 따로 분리 해야함

    public final class MainUIController
    {
        public static var STAGE_BG_COLOR:uint = 0xCCCCCC;

        public static const BOTTOM_BAR_HEIGHT:Number = 25;

        public static var STAGE_TOP_OFFSET:Number = 0, // 창 상하좌우 여백
            STAGE_LEFT_OFFSET:Number = 0,
            STAGE_BOTTOM_OFFSET:Number = BOTTOM_BAR_HEIGHT,
            STAGE_RIGHT_OFFSET:Number = 0;

        public static const
            resizeButtonR:Sprite = new Sprite(), // 캔버스 리사이즈 하는 버튼
            resizeButtonD:Sprite = new Sprite(),
            resizeButtonL:Sprite = new Sprite(),
            resizeButtonU:Sprite = new Sprite();

        public static var lastAppWindowSize:Point = new Point(), // 창크기 조절 얼마나 됐을지 비교할때 마지막 크기 창크기 저장
            lastAppWindowSizeInfo:Array = [0, 0, 680, 768],
            lastAppWindowState:int = 0;

        public static function getViewportRect():Rectangle
        {
            const main:Main = Main._instance;

            const stw:int = main.stage.stageWidth;
            const sth:int = main.stage.stageHeight;
            const rect:Rectangle = new Rectangle(0, 0, stw, sth);

            rect.y += STAGE_TOP_OFFSET;

            if (SidebarController.isQuickSidebarActive)
            {
                return rect;
            }

            rect.x += STAGE_LEFT_OFFSET;
            rect.width -= (STAGE_LEFT_OFFSET + STAGE_RIGHT_OFFSET);
            rect.height -= (STAGE_TOP_OFFSET + STAGE_TOP_OFFSET);

            return rect;
        }

        public static function isPopUpWindowOpened():Boolean
        {
            const main:Main = Main._instance;

            return MainUI.topBar.gridButtonWrapper.visible || main.numPadBox.visible || main.loadMenuBox.visible || main.aboutBox.visible;
        }

        public static function updateStageOffset():void
        {
            const main:Main = Main._instance;

            const scale:Number = Global.getUIScale();

            STAGE_TOP_OFFSET = 0;
            STAGE_BOTTOM_OFFSET = 0;
            STAGE_RIGHT_OFFSET = 0;
            STAGE_LEFT_OFFSET = 0;

            if (MainUI.topBar.visible)
            {
                STAGE_TOP_OFFSET += MainUI.topBar.BARSIZE * scale;
            }

            if (main.seekBarBox.visible)
            {
                STAGE_TOP_OFFSET += main.seekBarBox.BARSIZE * scale;
            }

            if (main.isCaptureModeON || main.isReplayModeON)
            {
                return;
            }

            if (SidebarController.sideBar.visible)
            {
                if (SidebarController.isRightSidebar)
                {
                    STAGE_RIGHT_OFFSET = Math.round(SidebarController.sideBar.getWidth() + SidebarController.SCROLL_BAR_WIDTH);
                }
                else
                {
                    STAGE_LEFT_OFFSET = Math.round(SidebarController.sideBar.getWidth()) + SidebarController.SCROLL_BAR_WIDTH;
                }
            }
        }

        public static function applyUIScale():void
        {
            const main:Main = Main._instance;

            const scale:Number = Global.getUIScale();
            const stw:Number = main.stage.stageWidth;
            const sth:Number = main.stage.stageHeight;

            SidebarController.sideBar.setScale(scale);
            SidebarController.setSidebarDefaultPos();
            MainUI.topBar.setScale(scale);
            MainUI.topBar.updateTopbarBG(stw);
            MainUI.topBar.updateTimerPos(main.stage.stageWidth);
            main.seekBarBox.setScale(scale);
            MainUI.canvasRotateCursor.setScale(scale);
            MainUI.mouseHint.setScale(scale);
            MainUI.bottomBar.scaleX = scale;
            MainUI.bottomBar.scaleY = scale;
            main.lassoMenuBox.setScale(scale);
            ReferenceLayerController.refLayerMenuBox.setScale(scale);
            main.fillPenBox.setScale(scale);
            main.toolBox2.setScale(scale);
            main.aboutBox.setScale(scale);
            main.eyedropperLens.setScale(scale);
            main.numPadBox.setScale(scale);
            updateStageOffset();
            SidebarController.updateScrollBarHeight();
            main.rReplayFOFOCursor.setScale(scale);
            main.fofo.setScale(scale);
            SidebarController.checkFOFOPosition();
            main.rFollowMouse.updateScale(scale);

            // 이거 위에서 뭔가 해주고 난후에 여기서 해줘야함
            SidebarController.sideBar.y = Math.round(STAGE_TOP_OFFSET);
            SidebarController.sideBar.updateSideBGSize(SidebarController.getSideBarBGHeight());

            if (main.isLassoToolStarted)
                keepBoxInsideViewPort(main.lassoMenuBox);
            if (ReferenceLayerController.isRefLayerMenuON)
                keepBoxInsideViewPort(ReferenceLayerController.refLayerMenuBox);

            updateCanvasNaigatorCursor();
            MainUI.hideBottomHint();
        }

        public static function setResizeButtonColor():void
        {
            const color:uint = Global.getUIResizeBarColor();

            Global.setColorTransform(resizeButtonL, color);
            Global.setColorTransform(resizeButtonR, color);
            Global.setColorTransform(resizeButtonU, color);
            Global.setColorTransform(resizeButtonD, color);
        }

        public static function markWindowTitleAsDirty():void
        {
            const main:Main = Main._instance;

            const titleEndStr:int = main.stage.nativeWindow.title.lastIndexOf(main.STRING_TITLE_FOFOPAINT);

            if (titleEndStr > 0 && main.stage.nativeWindow.title.charAt(titleEndStr - 1) !== "*")
            {
                const starFileName:String = main.stage.nativeWindow.title.slice(0, titleEndStr) + "*";
                main.stage.nativeWindow.title = starFileName + main.STRING_TITLE_FOFOPAINT;

                if (ImageViewWindow.isCanvasWindowON)
                {
                    ImageViewWindow.copyMainWindowTitleToCanvasWindow();
                }
            }
        }

        public static function updateCanvasNaigatorCursor():void
        {
            const main:Main = Main._instance;

            var newRightOffset:Number = 0;
            var newLeftOffset:Number = 0;

            if (SidebarController.isSidebarVisible === true)
            {
                newRightOffset = STAGE_RIGHT_OFFSET;
                newLeftOffset = STAGE_LEFT_OFFSET;

                if (SidebarController.isRightSidebar)
                {
                    newRightOffset = Math.round(SidebarController.sideBar.getWidth());
                }
                else
                {
                    newLeftOffset = Math.round(SidebarController.sideBar.getWidth());
                }
            }

            const gp:Point = main.canvasLayer1Bitmap.globalToLocal(new Point(newLeftOffset, STAGE_TOP_OFFSET));
            const zoom:Number = main.canvasZoomMultipler;
            main.canvasNavigatorBox.updateCursor(gp.x * zoom, gp.y * zoom
                    , main.stage.stageWidth - newRightOffset - newLeftOffset
                    , main.stage.stageHeight - STAGE_TOP_OFFSET - STAGE_BOTTOM_OFFSET
                    , main.CANVAS_WIDTH * zoom, main.canvasAnchorPoint.rotation);
        }

        public static function updateWindowTitle():void
        {
            const main:Main = Main._instance;

            main.stage.nativeWindow.title = main.lastSaveFileName + main.STRING_TITLE_FOFOPAINT;
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.copyMainWindowTitleToCanvasWindow();
            }
        }

        public static function hideCanvasResizeButtons():void
        {
            const main:Main = Main._instance;

            main.isPenSizeCursorInvisible = false;
            resizeButtonR.visible = false;
            resizeButtonL.visible = false;
            resizeButtonD.visible = false;
            resizeButtonU.visible = false;
        }

        public static function showCanvasResizeButtons():void
        {
            const main:Main = Main._instance;

            main.isPenSizeCursorInvisible = true;
            resizeButtonR.visible = true;
            resizeButtonL.visible = true;
            resizeButtonD.visible = true;
            resizeButtonU.visible = true;
        }

        public static function updateCanvasResizeButtonVisible(flag:Boolean):void
        {
            const main:Main = Main._instance;

            if (resizeButtonR.visible === flag)
            {
                return;
            }

            if (flag)
            {
                updateResizeButtonPos(main.CANVAS_WIDTH, main.CANVAS_HEIGHT);
                showCanvasResizeButtons();
            }
            else
            {
                hideCanvasResizeButtons();
            }
        }

        public static function showCanvasResizeButtonVisibleDelay(flag:Boolean):void
        {
            const main:Main = Main._instance;

            if (flag)
            {
                updateResizeButtonPos(main.CANVAS_WIDTH, main.CANVAS_HEIGHT);
                main.toolBox2.startResizeButtonWaitBarAnimation(0.9);
                FOFOTimer.addByName("resizeButtonVisibleDelayTimer", 0.9, false, function():void
                    {
                        showCanvasResizeButtons();
                        main.enableTransparentBGDrawMode();
                    });
            }
            else
            {
                FOFOTimer.remove("resizeButtonVisibleDelayTimer");
                hideCanvasResizeButtons();
                main.disableTransparentBGDrawMode();
            }
        }

        public static function onAboutWindowMouseDown(e:MouseEvent):void
        {
            const main:Main = Main._instance;

            const targetName:String = e.target.name;

            switch (targetName)
            {
                case "appResetButton":
                case "versionInfo":
                case "releaseNoteButton":
                case "resetAppButton":
                case "aboutButton":
                case "kor":
                case "jp":
                case "eng":
                case "aboutHomePageLink":
                case "aboutManualFolder":
                    // case "aboutMeLink":
                    main.handleMouseClick(targetName);
                    break;

                default:
                    main.closeAboutBox();
                    break;
            }
        }

        public static function initializeResizeButtonFamily():void
        {
            const main:Main = Main._instance;

            function drawRect(target:Sprite):void
            {
                target.visible = false;
                target.graphics.clear();
                target.graphics.beginFill(0xFF0000);
                target.graphics.drawRect(0, 0, 10, 10);
                target.graphics.endFill();
            }
            resizeButtonU.name = "resizeButtonU";
            resizeButtonD.name = "resizeButtonD";
            resizeButtonR.name = "resizeButtonR";
            resizeButtonL.name = "resizeButtonL";

            drawRect(resizeButtonU);
            drawRect(resizeButtonD);
            drawRect(resizeButtonL);
            drawRect(resizeButtonR);

            main.canvasAnchorPoint.addChild(resizeButtonU);
            main.canvasAnchorPoint.addChild(resizeButtonD);
            main.canvasAnchorPoint.addChild(resizeButtonR);
            main.canvasAnchorPoint.addChild(resizeButtonL);
        }

        public static function updateAppWindowSizeInfo():void
        {
            const main:Main = Main._instance;

            const windowSizeInfo:Rectangle = main.stage.nativeWindow.bounds;

            lastAppWindowSizeInfo[0] = windowSizeInfo.x;
            lastAppWindowSizeInfo[1] = windowSizeInfo.y;
            lastAppWindowSizeInfo[2] = windowSizeInfo.width;
            lastAppWindowSizeInfo[3] = windowSizeInfo.height;
        }

        public static function updateResizeButtonPos(width:Number, height:Number):void
        {
            const main:Main = Main._instance;

            function setpos(target:Sprite, x:Number, y:Number, w:Number, h:Number):void
            {
                target.x = x;
                target.y = y;
                target.width = (w === 0) ? buttonSize : w;
                target.height = (h === 0) ? buttonSize : h;
            }

            const z:Number = 1 / main.canvasZoomMultipler;
            const buttonSize:Number = 20 * z;
            const buttonSize2:Number = 40 * z;
            const cpPosX:Number = main.canvasPanel.x;
            const cpPosY:Number = main.canvasPanel.y;
            const top:Number = cpPosY - buttonSize;
            const bottom:Number = cpPosY + height;
            const left:Number = cpPosX - buttonSize;
            const right:Number = cpPosX + width;

            setpos(resizeButtonU, left, top, width + buttonSize2, 0);
            setpos(resizeButtonD, left, bottom, width + buttonSize2, 0);
            setpos(resizeButtonL, left, top, 0, height + buttonSize);
            setpos(resizeButtonR, right, top, 0, height + buttonSize);
        }

        public static function onWindowResize(e:Event):void
        {
            const main:Main = Main._instance;

            FOFOTimer.addByName("windowResizeDelayTimer", 0.2, false, function():void
                {
                    const dx:Number = Math.round((main.stage.nativeWindow.width - lastAppWindowSize.x) / 1.75);
                    const dy:Number = Math.round((main.stage.nativeWindow.height - lastAppWindowSize.y) / 1.75);

                    if (main.isCaptureModeON)
                    {
                        main.captureWindowMove.setTo(dx, dy);
                        main.fitCanvasToViewportMargin();

                        if (!main.captureAreaManager.isFullImageCapture())
                        {
                            main.captureAreaManager.updateDrawArea(true);
                        }
                    }
                    else
                    {
                        if (main.isReplayRestartTimerON())
                        {
                            main.centerCanvas("replay");

                        }
                        else
                        {
                            main.rCanvasAnchorPoint.x = main.rCanvasAnchorPoint.x + dx;
                            main.rCanvasAnchorPoint.y = main.rCanvasAnchorPoint.y + dy;
                        }

                        main.canvasAnchorPoint.x = main.canvasAnchorPoint.x + dx;
                        main.canvasAnchorPoint.y = main.canvasAnchorPoint.y + dy;
                    }

                    if (main.isLassoToolStarted)
                    {
                        main.lassoMenuBox.x += dx;
                        main.lassoMenuBox.y += dy;
                        keepBoxInsideViewPort(main.lassoMenuBox);
                    }

                    if (ReferenceLayerController.isRefLayerMenuON)
                    {
                        ReferenceLayerController.refLayerMenuBox.x += dx;
                        ReferenceLayerController.refLayerMenuBox.y += dy;
                        keepBoxInsideViewPort(ReferenceLayerController.refLayerMenuBox);
                    }

                    if (main.isAboutBoxOpened)
                    {
                        main.updateAboutPanelCenterPos();
                    }

                    if (main.isReplayModeON)
                    {
                        main.seekBarBox.updatePos(main.stage.stageWidth);
                        main.rFollowMouse.updateBounds();

                        if (main.isReplayCanvasFitToWindow)
                        {
                            main.fitReplayCanvasToViewport();
                        }
                    }

                    MainUI.topBar.updateTopbarBG(main.stage.stageWidth);
                    MainUI.topBar.updateTimerPos(main.stage.stageWidth);

                    SidebarController.sideBar.updateSideBGSize(SidebarController.getSideBarBGHeight());

                    if (SidebarController.isQuickSidebarActive)
                    {
                        SidebarController.deactivateQuickSidebar();
                    }
                    else
                    {
                        SidebarController.setSidebarDefaultPos();
                    }

                    SidebarController.updateScrollBarHeight();
                    updateCanvasNaigatorCursor();

                    if (main.loadMenuBox.visible === true)
                    {
                        main.loadMenuBox.updateClickBlockerSize(main.stage.stageWidth, main.stage.stageHeight);
                    }

                    if (main.selectedToolViewBitmap.visible)
                    {
                        main.updateSelectedToolViewBoxPos();
                    }

                    main.updateStageBGSize();
                    SidebarController.checkFOFOPosition();
                    main.updateBottomBarLayoutAndColor();
                    lastAppWindowSize.setTo(main.stage.nativeWindow.width, main.stage.nativeWindow.height);
                    MainUI.hideBottomHint();

                    if (main.isAppClosing)
                    {
                        if (!FOFOTimer.hasTimer("pollTimerWaitWorkerStop"))
                        {
                            main.deleteTempDirectory();
                            main.saveAllAppData();
                            main.stage.nativeWindow.close();
                        }
                    }
                });
        }

        public static function keepBoxInsideViewPort(target:DisplayObject):void
        {
            const main:Main = Main._instance;

            const rect:Rectangle = target.getBounds(main.stage);

            if (rect.x < STAGE_LEFT_OFFSET)
                target.x = STAGE_LEFT_OFFSET;
            else if (rect.x + rect.width > main.stage.stageWidth - STAGE_RIGHT_OFFSET)
                target.x = main.stage.stageWidth - rect.width - STAGE_RIGHT_OFFSET;

            if (rect.y < STAGE_TOP_OFFSET)
                target.y = STAGE_TOP_OFFSET;
            else if (rect.y + rect.height > main.stage.stageHeight - STAGE_BOTTOM_OFFSET)
                target.y = main.stage.stageHeight - rect.height - STAGE_BOTTOM_OFFSET;
        }

        public static function getStageCenterPos(mode:String):Point
        {
            const main:Main = Main._instance;

            const scale:Number = Global.getUIScale();
            const center:Point = new Point(0, 0);
            var topBarOffset:Number = MainUI.topBar.BARSIZE * scale;

            if (mode === "draw")
            {
                center.setTo((!SidebarController.isSidebarVisible) ? Math.floor(main.stage.stageWidth / 2)
                        : (SidebarController.isRightSidebar) ? Math.floor((main.stage.stageWidth - STAGE_RIGHT_OFFSET) / 2)
                        : Math.floor(STAGE_LEFT_OFFSET + (main.stage.stageWidth - STAGE_LEFT_OFFSET) / 2)
                        , Math.floor(topBarOffset + (main.stage.stageHeight - topBarOffset) / 2));
            }
            else if (mode === "replay")
            {
                topBarOffset = topBarOffset;
                center.setTo(main.stage.stageWidth / 2, Math.floor(topBarOffset + (main.stage.stageHeight - topBarOffset) / 2));
            }
            else if (mode === "capture")
            {
                center.setTo(main.stage.stageWidth / 2, Math.floor(topBarOffset + (main.stage.stageHeight - topBarOffset) / 2));
            }
            else
            {
                center.setTo(main.stage.stageWidth / 2, main.stage.stageHeight / 2);
            }

            return center;
        }

        public static function onWindowActive(e:Event):void
        {
            const main:Main = Main._instance;

            main.tryDisableIME();
            ClipboardManager.checkCanUseClipBoardButton();

            if (main.isAboutBoxOpened)
            {
                main.isMouseClickBlocked = true;
            }
            else
            {
                main.unblockMouseClickAfterDelay();
            }
        }
    }
}
