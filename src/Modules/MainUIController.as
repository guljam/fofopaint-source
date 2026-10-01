package Modules
{
    import Modules.CaptureEngine.CaptureStamp;
    import Modules.CaptureEngine.CaptureController;

    import Modules.SidebarController;
    import Modules.Tools.LassoTool;

    import flash.display.DisplayObject;
    import flash.events.Event;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import Modules.Tools.EyeDropperTool;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.ReplayEngine.ReplayState;

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

            if (LassoTool.isStarted)
                keepBoxInsideViewPort(LassoTool._lassoMenuBox);
            if (ReferenceLayerController.isRefLayerMenuON)
                keepBoxInsideViewPort(ReferenceLayerController.refLayerMenuBox);

            updateCanvasNaigatorCursor();
            MainUI.hideBottomHint();
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

        // 창 크기가 바뀐 뒤의 화면 배치를 "지금 창 크기" 기준으로 다시 계산한다.
        // 이동량은 마지막으로 배치했던 창 크기(lastAppWindowSize)와의 차이로만 구하고, 끝에서 그 기준을 갱신한다.
        // 그래서 같은 크기에서 몇 번을 호출해도 결과가 같고(멱등), 리사이즈 이벤트를 놓쳐도 다음 호출이 전부 보정한다.
        // 호출 지점: 창 리사이즈 이벤트(0.2초 디바운스), 최대화 복원 종료, 캐시 생성 종료 등 "상태가 확정된" 곳.
        // 주의: 앱 데이터 복원 중에는 화면 상태가 아직 확정되지 않았으므로 아무것도 하지 않는다.
        // force: 창 크기 변화가 없어도 크롬(상단바/사이드바/하단바 등)을 현재 스테이지 크기로 다시 맞춘다.
        //        복원파일 없이 처음 실행할 때처럼 lastAppWindowSize가 실제 배치와 무관하게 미리 채워진 경우에 쓴다.
        public static function applyLayout(force:Boolean = false):void
        {
            if (AppStateManager.isLoadingAppData)
            {
                return;
            }

            const dx:Number = Math.round((main.stage.nativeWindow.width - AppWindowState.lastAppWindowSize.width) / 1.75);
            const dy:Number = Math.round((main.stage.nativeWindow.height - AppWindowState.lastAppWindowSize.height) / 1.75);

            if (dx === 0 && dy === 0 && !force)
            {
                AppWindowState.closeAppIfPending();
                return;
            }

            applyCanvasLayout(dx, dy);
            applyPopupLayout(dx, dy);
            applyChromeLayout();

            rebaseLayout();
            MainUI.hideBottomHint();

            AppWindowState.closeAppIfPending();
        }

        // 캔버스(그리기/리플레이/캡처)를 창이 커진 만큼 같이 이동시킨다.
        private static function applyCanvasLayout(dx:Number, dy:Number):void
        {
            if (CaptureController.isCaptureModeON)
            {
                CaptureController.addCaptureWindowMove(dx, dy);
                CanvasController.fitCanvasToViewportMargin();

                if (!CaptureController.isFullImageCapture())
                {
                    CaptureController.updateCaptureAreaOverlay(true);
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
            if (LassoTool.isStarted)
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
            AppWindowState.lastAppWindowSize.setTo(0, 0, main.stage.nativeWindow.width, main.stage.nativeWindow.height);
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

            CanvasController.setResizeButtonColor();
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
