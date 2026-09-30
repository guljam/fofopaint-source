package Modules
{
    import Modules.CaptureEngine.CaptureStamp;
    import Modules.CaptureEngine.CaptureArea;
    import Modules.CaptureEngine.CaptureController;

    import Modules.SidebarController;
    import Modules.Tools.LassoTool;

    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import Modules.Tools.EyeDropperTool;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.ReplayEngine.ReplayState;

    // todo: 캔버스 리사이즈 버튼은 나중에 따로 분리 해야함

    public final class MainUIController
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }
        public static var STAGE_BG_COLOR:uint = 0xCCCCCC;

        private static const BOTTOM_BAR_HEIGHT:Number = 25;

        public static var STAGE_TOP_OFFSET:Number = 0, // 창 상하좌우 여백
            STAGE_LEFT_OFFSET:Number = 0,
            STAGE_BOTTOM_OFFSET:Number = BOTTOM_BAR_HEIGHT,
            STAGE_RIGHT_OFFSET:Number = 0;

        public static const
            resizeButtonR:Sprite = new Sprite(), // 캔버스 리사이즈 하는 버튼
            resizeButtonD:Sprite = new Sprite(),
            resizeButtonL:Sprite = new Sprite(),
            resizeButtonU:Sprite = new Sprite();

        public static var lastAppWindowSize:Rectangle = new Rectangle(), // 창크기 조절 얼마나 됐을지 비교할때 마지막 크기 창크기 저장
            lastAppWindowState:int = 0;

        // 종료 저장/close가 이미 시작됐는지 (종료 직전 applyLayout이 여러 경로로 중복 호출되는 것 방지)
        private static var isCloseRequested:Boolean = false;

        public static function updateTopbarIconsDrawMode():void
		{
			MainUI.topBar.updateIconsByMode(0);
		}

		public static function updateTopbarIconsReplayMode():void
		{
			MainUI.topBar.updateIconsByMode(1);
		}

		public static function updateTopbarIconsCaptureMode():void
		{
			MainUI.topBar.updateIconsByMode(2);
		}

        public static function activateCaptureUI():void
		{
			const replayMode:Boolean = ReplayState.isReplayModeON;
			CaptureArea.reset();
			MainUIController.updateCanvasResizeButtonVisible(false);
			FOFOTimer.remove("rCursorOffAlphaAnimTimer");

			if (replayMode)
			{
				MainUI.showTopbarOnReplayEnd();
				ReplayController.seekBarBox.setDeleteRangeBarVisible(false);
				ReplayController.seekBarBox.visible = false;
				InputManager.removeInputEventsReplayMode();
			}
			else
			{
				CanvasGridOverlay.canvasGrid.visible = false;
				InputManager.removeInputEventsDrawMode();
			}

			if (SidebarController.isSidebarVisible)
			{
				SidebarController.hideSidebarTemporary();
			}

			PenSizePreviewCursor.setCursorInVisibleFlag(true);
			PenSizePreviewCursor.setVisible(false);
			ReferenceLayerController.canvasRefLayer.visible = false;

			if (ReferenceLayerController.isRefLayerMenuON)
			{
				ReferenceLayerController.refLayerMenuBox.visible = false;
			}

			updateTopbarIconsCaptureMode();
			ReplayDrawer.rReplayFOFOCursor.visible = false;

			if (MainUI.mouseHint.isShowing())
			{
				MainUI.hideMouseHint();
			}

			InputManager.addInputEventsCaptrueMode();
			MainUIController.updateStageOffset();
		}

		public static function deactivateCaptureUI():void
		{
			const replayMode:Boolean = ReplayState.isReplayModeON;
			InputManager.removeInputEventCaptrueMode();
			ReferenceLayerController.canvasRefLayer.visible = true;

			if (replayMode)
			{
				updateTopbarIconsReplayMode();
				InputManager.addInputEventsReplayMode();
				ReplayController.seekBarBox.visible = true;
			}
			else
			{
				if (SidebarController.isSidebarVisible)
				{
					SidebarController.showSidebarPermanent();
				}
				if (ReferenceLayerController.isRefLayerMenuON)
				{
					ReferenceLayerController.refLayerMenuBox.visible = true;
				}
				PenSizePreviewCursor.setCursorInVisibleFlag(false);
				updateTopbarIconsDrawMode();
				InputManager.addInputEventsDrawMode();
			}

			ColorPickerController.switchColorPickerModePen();
			MainUIController.updateStageOffset();
		}

        public static function getViewportRect():Rectangle
        {
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
            return MainUI.topBar.gridButtonWrapper.visible || ColorPickerController.numPadBox.visible || FileManager.loadMenuBox.visible || AboutBoxController.aboutBox.visible;
        }

        public static function updateStageOffset():void
        {
            const scale:Number = Global.getUIScale();

            STAGE_TOP_OFFSET = 0;
            STAGE_BOTTOM_OFFSET = 0;
            STAGE_RIGHT_OFFSET = 0;
            STAGE_LEFT_OFFSET = 0;

            if (MainUI.topBar.visible)
            {
                STAGE_TOP_OFFSET += MainUI.topBar.BARSIZE * scale;
            }

            if (ReplayController.seekBarBox.visible)
            {
                STAGE_TOP_OFFSET += ReplayController.seekBarBox.BARSIZE * scale;
            }

            if (CaptureController.isCaptureModeON || ReplayState.isReplayModeON)
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
            const scale:Number = Global.getUIScale();
            const stw:Number = main.stage.stageWidth;
            const sth:Number = main.stage.stageHeight;

            SidebarController.sideBar.setScale(scale);
            SidebarController.setSidebarDefaultPos();
            MainUI.topBar.setScale(scale);
            MainUI.topBar.updateTopbarBG(stw);
            MainUI.topBar.updateTimerPos(main.stage.stageWidth);
            ReplayController.seekBarBox.setScale(scale);
            CanvasController.canvasRotateCursor.setScale(scale);
            MainUI.mouseHint.setScale(scale);
            MainUI.bottomBar.scaleX = scale;
            MainUI.bottomBar.scaleY = scale;
            LassoTool._lassoMenuBox.setScale(scale);
            ReferenceLayerController.refLayerMenuBox.setScale(scale);
            FillPenTool.fillPenBox.setScale(scale);
            ToolController.toolBox2.setScale(scale);
            AboutBoxController.setAboutBoxScale(scale);
            EyeDropperTool.eyedropperLens.setScale(scale);
            ColorPickerController.numPadBox.setScale(scale);
            updateStageOffset();
            SidebarController.updateScrollBarHeight();
            ReplayDrawer.rReplayFOFOCursor.setScale(scale);
            SidebarController.fofo.setScale(scale);
            SidebarController.checkFOFOPosition();
            ReplayController.rFollowMouse.updateScale(scale);

            // 이거 위에서 뭔가 해주고 난후에 여기서 해줘야함
            SidebarController.sideBar.y = Math.round(STAGE_TOP_OFFSET);
            SidebarController.sideBar.updateSideBGSize(SidebarController.getSideBarBGHeight());

            if (LassoTool._isLassoToolStarted)
                keepBoxInsideViewPort(LassoTool._lassoMenuBox);
            if (ReferenceLayerController.isRefLayerMenuON)
                keepBoxInsideViewPort(ReferenceLayerController.refLayerMenuBox);

            updateCanvasNaigatorCursor();
            MainUI.hideBottomHint();
        }

        private static function setResizeButtonColor():void
        {
            const color:uint = Global.getUIResizeBarColor();

            Utils.setColorTransform(resizeButtonL, color);
            Utils.setColorTransform(resizeButtonR, color);
            Utils.setColorTransform(resizeButtonU, color);
            Utils.setColorTransform(resizeButtonD, color);
        }

        public static function markWindowTitleAsDirty():void
        {
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

            const gp:Point = CanvasController.canvasLayer1Bitmap.globalToLocal(new Point(newLeftOffset, STAGE_TOP_OFFSET));
            const zoom:Number = CanvasController.canvasZoomMultipler;
            CanvasController.canvasNavigatorBox.updateCursor(gp.x * zoom, gp.y * zoom
                    , main.stage.stageWidth - newRightOffset - newLeftOffset
                    , main.stage.stageHeight - STAGE_TOP_OFFSET - STAGE_BOTTOM_OFFSET
                    , CanvasController.CANVAS_WIDTH * zoom, CanvasController.canvasAnchorPoint.rotation);
        }

        public static function updateWindowTitle():void
        {
            main.stage.nativeWindow.title = FileManager.lastSaveFileName + main.STRING_TITLE_FOFOPAINT;
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.copyMainWindowTitleToCanvasWindow();
            }
        }

        private static function hideCanvasResizeButtons():void
        {
            PenSizePreviewCursor.setCursorInVisibleFlag(false);
            resizeButtonR.visible = false;
            resizeButtonL.visible = false;
            resizeButtonD.visible = false;
            resizeButtonU.visible = false;
        }

        private static function showCanvasResizeButtons():void
        {
            PenSizePreviewCursor.setCursorInVisibleFlag(true);
            resizeButtonR.visible = true;
            resizeButtonL.visible = true;
            resizeButtonD.visible = true;
            resizeButtonU.visible = true;
        }

        public static function updateCanvasResizeButtonVisible(flag:Boolean):void
        {
            if (resizeButtonR.visible === flag)
            {
                return;
            }

            if (flag)
            {
                updateResizeButtonPos(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
                showCanvasResizeButtons();
            }
            else
            {
                hideCanvasResizeButtons();
            }
        }

        public static function showCanvasResizeButtonVisibleDelay(flag:Boolean):void
        {
            if (flag)
            {
                updateResizeButtonPos(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
                ToolController.toolBox2.startResizeButtonWaitPrograssBarAnimation();
                FOFOTimer.addByName("resizeButtonVisibleDelayTimer", 0.9, false, function ():void
                    {
                        showCanvasResizeButtons();
                        CanvasController.enableTransparentBGDrawMode();
                    });
            }
            else
            {
                FOFOTimer.remove("resizeButtonVisibleDelayTimer");
                hideCanvasResizeButtons();
                CanvasController.disableTransparentBGDrawMode();
            }
        }

        public static function onAboutWindowMouseDown(e:MouseEvent):void
        {
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
                    InputManager.handleMouseClickStage(targetName);
                    break;

                default:
                    AboutBoxController.closeAboutBox();
                    break;
            }
        }

        public static function initializeResizeButtonFamily():void
        {
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

            CanvasController.canvasAnchorPoint.addChild(resizeButtonU);
            CanvasController.canvasAnchorPoint.addChild(resizeButtonD);
            CanvasController.canvasAnchorPoint.addChild(resizeButtonR);
            CanvasController.canvasAnchorPoint.addChild(resizeButtonL);
        }

        public static function updateResizeButtonPos(width:Number, height:Number):void
        {
            function setpos(target:Sprite, x:Number, y:Number, w:Number, h:Number):void
            {
                target.x = x;
                target.y = y;
                target.width = (w === 0) ? buttonSize : w;
                target.height = (h === 0) ? buttonSize : h;
            }

            const z:Number = 1 / CanvasController.canvasZoomMultipler;
            const buttonSize:Number = 20 * z;
            const buttonSize2:Number = 40 * z;
            const cpPosX:Number = CanvasController.canvasPanel.x;
            const cpPosY:Number = CanvasController.canvasPanel.y;
            const top:Number = cpPosY - buttonSize;
            const bottom:Number = cpPosY + height;
            const left:Number = cpPosX - buttonSize;
            const right:Number = cpPosX + width;

            setpos(resizeButtonU, left, top, width + buttonSize2, 0);
            setpos(resizeButtonD, left, bottom, width + buttonSize2, 0);
            setpos(resizeButtonL, left, top, 0, height + buttonSize);
            setpos(resizeButtonR, right, top, 0, height + buttonSize);
        }

        // 창 크기가 바뀐 뒤의 화면 배치를 "지금 창 크기" 기준으로 다시 계산한다.
        // 이동량은 마지막으로 배치했던 창 크기(lastAppWindowSize)와의 차이로만 구하고, 끝에서 그 기준을 갱신한다.
        // 그래서 같은 크기에서 몇 번을 호출해도 결과가 같고(멱등), 리사이즈 이벤트를 놓쳐도 다음 호출이 전부 보정한다.
        // 호출 지점: 창 리사이즈 이벤트(0.2초 디바운스), 최대화 복원 종료, 캐시 생성 종료 등 "상태가 확정된" 곳.
        // 주의: 앱 데이터 복원 중에는 화면 상태가 아직 확정되지 않았으므로 아무것도 하지 않는다.
        public static function applyLayout():void
        {
            if (AppStateManager.isLoadingAppData)
            {
                return;
            }

            const dx:Number = Math.round((main.stage.nativeWindow.width - lastAppWindowSize.width) / 1.75);
            const dy:Number = Math.round((main.stage.nativeWindow.height - lastAppWindowSize.height) / 1.75);

            if (dx === 0 && dy === 0)
            {
                closeAppIfPending();
                return;
            }

            applyCanvasLayout(dx, dy);
            applyPopupLayout(dx, dy);
            applyChromeLayout();

            rebaseLayout();
            MainUI.hideBottomHint();

            closeAppIfPending();
        }

        // 캔버스(그리기/리플레이/캡처)를 창이 커진 만큼 같이 이동시킨다.
        private static function applyCanvasLayout(dx:Number, dy:Number):void
        {
            if (CaptureController.isCaptureModeON)
            {
                CaptureController.captureWindowMove.setTo(dx, dy);
                CanvasController.fitCanvasToViewportMargin();

                if (!CaptureArea.isFullImageCapture())
                {
                    CaptureArea.updateDrawArea(true);
                }
            }
            else
            {
                if (ReplayController.isReplayRestartTimerON())
                {
                    CanvasController.centerCanvas("replay");
                }
                else
                {
                    ReplayDrawer.rCanvasAnchorPoint.x = ReplayDrawer.rCanvasAnchorPoint.x + dx;
                    ReplayDrawer.rCanvasAnchorPoint.y = ReplayDrawer.rCanvasAnchorPoint.y + dy;
                }

                CanvasController.canvasAnchorPoint.x = CanvasController.canvasAnchorPoint.x + dx;
                CanvasController.canvasAnchorPoint.y = CanvasController.canvasAnchorPoint.y + dy;
            }
        }

        // 떠 있는 팝업들이 창 밖으로 나가지 않게 같이 이동시킨다.
        private static function applyPopupLayout(dx:Number, dy:Number):void
        {
            if (LassoTool._isLassoToolStarted)
            {
                LassoTool._lassoMenuBox.x += dx;
                LassoTool._lassoMenuBox.y += dy;
                keepBoxInsideViewPort(LassoTool._lassoMenuBox);
            }

            if (ReferenceLayerController.isRefLayerMenuON)
            {
                ReferenceLayerController.refLayerMenuBox.x += dx;
                ReferenceLayerController.refLayerMenuBox.y += dy;
                keepBoxInsideViewPort(ReferenceLayerController.refLayerMenuBox);
            }
        }

        // 현재 스테이지 크기만 보고 다시 계산하면 되는 UI들(상단바/사이드바/하단바 등).
        private static function applyChromeLayout():void
        {
            if (AboutBoxController.isAboutBoxOpened)
            {
                AboutBoxController.updateAboutPanelCenterPos();
            }

            if (ReplayState.isReplayModeON)
            {
                ReplayController.seekBarBox.updatePos(main.stage.stageWidth);
                ReplayController.rFollowMouse.updateBounds();

                if (ReplayState.isReplayCanvasFitToWindow)
                {
                    ReplayController.fitReplayCanvasToViewport();
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

            if (FileManager.loadMenuBox.visible === true)
            {
                FileManager.loadMenuBox.updateClickBlockerSize(main.stage.stageWidth, main.stage.stageHeight);
            }

            if (ToolController.selectedToolViewBitmap.visible)
            {
                ToolController.updateSelectedToolViewBoxPos();
            }

            main.updateStageBGSize();
            SidebarController.checkFOFOPosition();
            updateBottomBarLayoutAndColor();
        }

        // 지금 배치가 유효한 창 크기를 기록한다. 다음 리사이즈는 이 크기와 비교한다.
        // 캔버스를 centerCanvas 같은 절대 배치로 새로 잡은 직후에도 호출해서, 남아있던 리사이즈 델타가
        // 뒤늦게 적용되어 위치가 밀리는 것을 막을 수 있다.
        public static function rebaseLayout():void
        {
            lastAppWindowSize.setTo(0, 0, main.stage.nativeWindow.width, main.stage.nativeWindow.height);
        }

        // 종료 대기 중이면 저장하고 창을 닫는다(마지막 종료 트리거).
        private static function closeAppIfPending():void
        {
            if (!FileManager.isAppClosing || isCloseRequested)
            {
                return;
            }

            if (FOFOTimer.hasTimer("pollTimerWaitWorkerStop"))
            {
                return;
            }

            isCloseRequested = true;
            FileManager.deleteTempDirectory();
            FileManager.saveAllAppData();
            main.stage.nativeWindow.close();
        }

        public static function onWindowResize(e:Event):void
        {
            if (AppStateManager.isLoadingAppData)
            {
                return;
            }

            FOFOTimer.addByName("windowResizeDelayTimer", 0.2, false, applyLayout);
        }

        public static function keepBoxInsideViewPort(target:DisplayObject):void
        {
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
            InputManager.tryDisableIME();
            ClipboardManager.checkCanUseClipBoardButton();

            if (AboutBoxController.isAboutBoxOpened)
            {
                CanvasController.isMouseClickBlocked = true;
            }
            else
            {
                InputManager.unblockMouseClickAfterDelay();
            }
        }

        private static function updateStageBGColor():void
        {
            const color:uint = Global.getUIStageColor();

            main.stage.color = color;
            MainUIController.STAGE_BG_COLOR = color;
        }

        public static function cycleUIColor():void
        {
            Global.setNextUIColor();
            applyUIColorSet();
            MainUI.showMouseHintTemp(Global.setUIColorString());
        }

        public static function applyUIColorSet():void
        {
            updateStageBGColor();
            updateBottomBarLayoutAndColor();

            CanvasController.canvasNavigatorBox.chanegStageColor(MainUIController.STAGE_BG_COLOR);

            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.canvasWindow.stage.color = MainUIController.STAGE_BG_COLOR;
            }

            SidebarController.sideBar.updateUIColor();
            ToolController.toolOptionsBox.updateUIColor();
            ColorPickerController.colorPickerBox.updateUIColor();
            CanvasController.canvasInfoBox.updateUIColor();
            CanvasController.canvasRotateCursor.changeUIColor();
            SidebarController.fofo.updateColor();
            ToolController.toolBox.changeUIColor();
            ToolController.toolBox2.changeUIColor();
            FillPenTool.fillPenBox.updateUIColor();
            LassoTool._lassoMenuBox.updateUIColor();
            ColorPickerController.numPadBox.updateUIColor();
            ReferenceLayerController.refLayerMenuBox.updateUIColor();
            MainUI.topBar.updateUIColor();
            ReplayController.seekBarBox.updateUIColor();
            CaptureStamp.captureStampFontListBox.updateUIColor();
            MainUI.mouseHint.updateBGColor();
            MainUI.bottomHint.updateHintTextColor(0);

            MainUIController.setResizeButtonColor();
            SidebarController.updateScrollBarColorAndHeight();

            if (ColorPickerController.isColorPickerModeBG)
            {
                ColorPickerController.switchColorPickerModePen();
            }

            ColorPickerController.colorPickerBox.activePaperColorButton(ColorPickerController.isColorPickerModeBG);
            ClipboardManager.checkCanUseClipBoardButton();
            ColorPickerController.updatePickerBoxTransBGBrightness();

            if (MainUI.isBottomBarVisible())
            {
                MainUI.hideBottomHint();
            }
        }

        public static function updateBottomBarLayoutAndColor():void
        {
            MainUI.bottomBar.x = 0;
            MainUI.bottomBar.y = main.stage.stageHeight - MainUIController.BOTTOM_BAR_HEIGHT * Global.getUIScale();

            MainUI.bottomBar.graphics.clear();
            // WorkspaceView.bottomBar.graphics.lineStyle(0,0xFF0000,0.0);
            MainUI.bottomBar.graphics.beginFill(Global.getHintBGColor(), 0.75);
            MainUI.bottomBar.graphics.drawRect(-3, 0, main.stage.stageWidth + 6, MainUIController.BOTTOM_BAR_HEIGHT + 3);
            MainUI.bottomBar.graphics.endFill();
        }
    }
}
