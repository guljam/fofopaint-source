package Modules.UIEngine
{
    import Modules.AboutBoxController;
    import Modules.AppStateManager;
    import Modules.CanvasController;
    import Modules.CaptureEngine.CaptureController;
    import Modules.CaptureEngine.CaptureStamp;
    import Modules.ClipboardManager;
    import Modules.ColorPickerController;
    import Modules.FileManager;
    import Modules.Tools.FillPenTool;
    import Modules.ImageViewWindow;
    import Modules.ReferenceLayerController;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.ReplayEngine.ReplayState;
    import Modules.SidebarController;
    import Modules.ToolController;
    import Modules.Tools.EyeDropperTool;
    import Modules.Tools.LassoTool;
    import Modules.Utils;
    import Symbols.TopMenuSet;

    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    // 스테이지 UI 배치: 표시 순서, 뷰포트 여백, 창 크기 변경 배치, UI 색상/스케일을 각 패널에 반영
    public final class UIController
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        // todo 커스텀 마우스 커서랑 최종적으로 앱 상세 살정할수있는 작은 옵션 버튼들 창 만들어야함, 현재 계속 누르고 있는 확인은 실제 확인창 만들어서 그냥 쉽게 선택하게 하기
        public static const stageBG:Sprite = new Sprite(); // 드래그 불러오기가 stage공백에서는 안되서 수동으로 전체바탕으로 만들어줌
        public static const topBar:TopMenuSet = new TopMenuSet();
        public static var STAGE_BG_COLOR:uint = 0xCCCCCC;

        public static var STAGE_TOP_OFFSET:Number = 0, // 창 상하좌우 여백
            STAGE_LEFT_OFFSET:Number = 0,
            STAGE_BOTTOM_OFFSET:Number = HintController.BOTTOM_BAR_HEIGHT,
            STAGE_RIGHT_OFFSET:Number = 0;

        public static function initializeAppMenus():void
        {
            topBar.name = "topBar";
            SidebarController.sideBarScrollBar.name = "sideBarScrollBar";
            topBar.makeTopbarBG(UITheme.getDefaultUIColor());
            updateTopbarIconsDrawMode();

            FillPenTool.fillPenBox.x = -FillPenTool.fillPenBox.width - 3;
            FillPenTool.fillPenBox.y = -FillPenTool.fillPenBox.height - 3;

            CanvasController.canvasNavigatorBox.scrollRect = new Rectangle(0, 0, CanvasController.canvasNavigatorBox.width, CanvasController.canvasNavigatorBox.height);

            SidebarController.sideBarScrollPanel.addChild(CanvasController.canvasNavigatorBox);
            SidebarController.sideBarScrollPanel.addChild(CanvasController.canvasInfoBox);
            ToolController.toolBox.moveCanvasControlButtonsTo(CanvasController.canvasInfoBox);
            SidebarController.sideBarScrollPanel.addChild(ToolController.toolBox);
            SidebarController.sideBarScrollPanel.addChild(ToolController.toolOptionsBox);
            SidebarController.sideBarScrollPanel.addChild(ColorPickerController.colorPickerBox);

            SidebarController.sideBar.addChild(SidebarController.sideBarScrollBar);
            SidebarController.sideBar.addChild(SidebarController.sideBarScrollPanel);
            SidebarController.sideBar.updateSideBGSize(SidebarController.getSideBarBGHeight());
            SidebarController.sideBarScrollBar.alpha = 0.75;
            STAGE_TOP_OFFSET = topBar.BARSIZE;

            CaptureStamp.captureStampFontListBox.y = 100;

            topBar.updateTimerPos(main.stage.stageWidth);
            topBar.replayFitToWindowButton.alpha = UITheme.OFFALPHA;

            ToolController.selectedToolViewBitmap.name = "selectedToolViewBitmap";
            ToolController.selectedToolViewBitmap.visible = false;

            main.stage.addChild(FileManager.loadMenuBox);
            main.stage.addChild(ReferenceLayerController.refLayerMenuBox);
            main.stage.addChild(AboutBoxController.aboutBox);
            main.stage.addChild(SidebarController.sideBar);
            main.stage.addChild(FillPenTool.fillPenBox);
            main.stage.addChild(ToolController.toolBox2);
            main.stage.addChild(CanvasController.canvasRotateCursor);
            main.stage.addChild(ColorPickerController.numPadBox);
            main.stage.addChild(CaptureStamp.captureStampFontListBox);
            main.stage.addChild(topBar);
            HintController.initialize();
            main.stage.addChild(ToolController.selectedToolViewBitmap);
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
            return topBar.gridButtonWrapper.visible || ColorPickerController.numPadBox.visible || FileManager.loadMenuBox.visible || AboutBoxController.aboutBox.visible;
        }

        public static function updateStageOffset():void
        {
            const scale:Number = UITheme.getUIScale();

            STAGE_TOP_OFFSET = 0;
            STAGE_BOTTOM_OFFSET = 0;
            STAGE_RIGHT_OFFSET = 0;
            STAGE_LEFT_OFFSET = 0;

            if (topBar.visible)
            {
                STAGE_TOP_OFFSET += topBar.BARSIZE * scale;
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
            const scale:Number = UITheme.getUIScale();
            const stw:Number = main.stage.stageWidth;
            const sth:Number = main.stage.stageHeight;

            SidebarController.sideBar.setScale(scale);
            SidebarController.setSidebarDefaultPos();
            topBar.setScale(scale);
            topBar.updateTopbarBG(stw);
            topBar.updateTimerPos(main.stage.stageWidth);
            ReplayController.seekBarBox.setScale(scale);
            CanvasController.canvasRotateCursor.setScale(scale);
            HintController.mouseHint.setScale(scale);
            HintController.bottomBar.scaleX = scale;
            HintController.bottomBar.scaleY = scale;
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
            HintController.hideBottomHint();
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
            HintController.hideBottomHint();

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

            topBar.updateTopbarBG(main.stage.stageWidth);
            topBar.updateTimerPos(main.stage.stageWidth);

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
            HintController.updateBottomBarLayoutAndColor();
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
            const scale:Number = UITheme.getUIScale();
            const center:Point = new Point(0, 0);
            var topBarOffset:Number = topBar.BARSIZE * scale;

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
            const color:uint = UITheme.getUIStageColor();

            main.stage.color = color;
            STAGE_BG_COLOR = color;
        }

        public static function cycleUIColor():void
        {
            UITheme.setNextUIColor();
            applyUIColorSet();
            HintController.showMouseHintTemp(UITheme.getUIColorName());
        }

        public static function applyUIColorSet():void
        {
            updateStageBGColor();
            HintController.updateBottomBarLayoutAndColor();

            CanvasController.canvasNavigatorBox.chanegStageColor(STAGE_BG_COLOR);

            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.canvasWindow.stage.color = STAGE_BG_COLOR;
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
            topBar.updateUIColor();
            ReplayController.seekBarBox.updateUIColor();
            CaptureStamp.captureStampFontListBox.updateUIColor();
            HintController.mouseHint.updateBGColor();
            HintController.bottomHint.updateHintTextColor(0);

            CanvasController.setResizeButtonColor();
            SidebarController.updateScrollBarColorAndHeight();

            if (ColorPickerController.isColorPickerModeBG)
            {
                ColorPickerController.switchColorPickerModePen();
            }

            ColorPickerController.colorPickerBox.activePaperColorButton(ColorPickerController.isColorPickerModeBG);
            ClipboardManager.checkCanUseClipBoardButton();
            ColorPickerController.updatePickerBoxTransBGBrightness();

            if (HintController.isBottomBarVisible())
            {
                HintController.hideBottomHint();
            }
        }

        public static function hideCanvasRotateCursor():void
        {
            CanvasController.canvasRotateCursor.visible = false;
        }

        public static function showCanvasRotateCursorMouseDrag(target:DisplayObject):Function
        {
            const snapThreshold:Number = 82;
            CanvasController.canvasRotateCursor.x = main.stage.mouseX;
            CanvasController.canvasRotateCursor.y = main.stage.mouseY + (65 * UITheme.getUIScale());
            CanvasController.canvasRotateCursor.rotateArrow.rotation = target.rotation;
            Utils.setAsTopChild(CanvasController.canvasRotateCursor);
            CanvasController.canvasRotateCursor.visible = true;

            const toDeg:Number = 180.0 / Math.PI;
            // 움직인 각도합 로테이트 캔버스 마지막각도를 넣어줌 rad로 변환

            var sumAng:Number = target.rotation;
            // 각도 차이 구하기 위해서 넣어줌, 초기 값은 마우스 클릭한 위치의 각도값
            var lastAng:Number = Math.atan2(main.stage.mouseX - CanvasController.canvasRotateCursor.x, main.stage.mouseY - CanvasController.canvasRotateCursor.y) * toDeg;
            var activateSnapFlag:Boolean = false;
            var ignoreSnapFlag:Boolean = true;
            var snappedAng:Number = 0;

            return function ():Number
            {
                const nowAng:Number = Math.atan2(main.stage.mouseX - CanvasController.canvasRotateCursor.x, main.stage.mouseY - CanvasController.canvasRotateCursor.y) * toDeg;
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

                CanvasController.canvasRotateCursor.rotateArrow.rotation = deg;
                return Math.round(deg);
            };
        }
    }
}
