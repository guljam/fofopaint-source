package Modules.L4UI.UIEngine
{
    import Symbols.CanvasInfoSet;
    import Symbols.RotateCursorSet;
    import Symbols.TopMenuSet;

    import flash.display.DisplayObject;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import Modules.L5App.AppWindowState;
    import Modules.L4UI.ColorPickerController;
    import Modules.L5App.FileManager;
    import Modules.L4UI.ImageViewWindow;
    import Modules.L4UI.LoadBoxController;
    import Modules.L5App.ReplayEngine.ReplayController;
    import Modules.L4UI.SidebarController;
    import Modules.L4UI.Tools.ToolPanel;
    import Modules.L4UI.AboutBoxController;
    import Modules.UIEngine.CanvasNavigator;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.UIEngine.UITheme;
    import Modules.L1Data.AppDataPaths;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L4UI.CanvasGridOverlay;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L4UI.PenSizePreviewCursor;
    import Modules.L2Engine.LassoLayers;
    import Modules.L4UI.CanvasViewport;
    import Modules.L4UI.DrawEngine.CanvasResizer;
    import Modules.L2Engine.ReplayEngine.ReplayState;
    import Modules.L2Engine.DrawEngine.StrokeBuffer;
    import Modules.L1Data.Utils;
    import Modules.L4UI.Tools.FillPenTool;
    import Modules.L4UI.Tools.LassoTool;
    import Modules.L4UI.Tools.ZoomTool;
    import Modules.L4UI.Tools.EyeDropperTool;
    import Modules.L4UI.Tools.ToolController;
    import Modules.L4UI.CaptureEngine.CaptureController;
    import Modules.L4UI.CaptureEngine.CaptureStamp;
    import Modules.L4UI.ClipboardManager;
    import Modules.L4UI.ReferenceLayerController;

    // 스테이지 UI 배치: 표시 순서, 뷰포트 여백, 창 크기 변경 배치, UI 색상/스케일을 각 패널에 반영
    // 층: L4 UI - 스테이지 UI 배치와 UI 색상·스케일을 패널에 반영
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
        public static const canvasInfoBox:CanvasInfoSet = new CanvasInfoSet(); // 사이드바의 캔버스 크기/줌/회전/미러 정보
        public static const canvasRotateCursor:RotateCursorSet = new RotateCursorSet(); // 회전이 얼마나 됐는지 표시
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

            CanvasNavigator.box.scrollRect = new Rectangle(0, 0, CanvasNavigator.box.width, CanvasNavigator.box.height);

            SidebarController.sideBarScrollPanel.addChild(CanvasNavigator.box);
            SidebarController.sideBarScrollPanel.addChild(canvasInfoBox);
            ToolPanel.toolBox.moveCanvasControlButtonsTo(canvasInfoBox);
            SidebarController.sideBarScrollPanel.addChild(ToolPanel.toolBox);
            SidebarController.sideBarScrollPanel.addChild(ToolPanel.toolOptionsBox);
            SidebarController.sideBarScrollPanel.addChild(ColorPickerController.colorPickerBox);

            SidebarController.sideBar.addChild(SidebarController.sideBarScrollBar);
            SidebarController.sideBar.addChild(SidebarController.sideBarScrollPanel);
            SidebarController.sideBar.updateSideBGSize(SidebarController.getSideBarBGHeight());
            SidebarController.sideBarScrollBar.alpha = 0.75;
            STAGE_TOP_OFFSET = topBar.BARSIZE;

            CaptureStamp.captureStampFontListBox.y = 100;

            topBar.updateTimerPos(main.stage.stageWidth);
            topBar.replayFitToWindowButton.alpha = UITheme.OFFALPHA;

            ToolPanel.selectedToolViewBitmap.name = "selectedToolViewBitmap";
            ToolPanel.selectedToolViewBitmap.visible = false;

            main.stage.addChild(LoadBoxController.loadMenuBox);
            main.stage.addChild(ReferenceLayerController.refLayerMenuBox);
            main.stage.addChild(AboutBoxController.aboutBox);
            main.stage.addChild(SidebarController.sideBar);
            main.stage.addChild(FillPenTool.fillPenBox);
            main.stage.addChild(ToolPanel.toolBox2);
            main.stage.addChild(canvasRotateCursor);
            main.stage.addChild(ColorPickerController.numPadBox);
            main.stage.addChild(CaptureStamp.captureStampFontListBox);
            main.stage.addChild(topBar);
            HintController.initialize();
            main.stage.addChild(ToolPanel.selectedToolViewBitmap);
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
            return topBar.gridButtonWrapper.visible || ColorPickerController.numPadBox.visible || LoadBoxController.loadMenuBox.visible || AboutBoxController.aboutBox.visible;
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
            canvasRotateCursor.setScale(scale);
            HintController.mouseHint.setScale(scale);
            HintController.bottomBar.scaleX = scale;
            HintController.bottomBar.scaleY = scale;
            LassoTool._lassoMenuBox.setScale(scale);
            ReferenceLayerController.refLayerMenuBox.setScale(scale);
            FillPenTool.fillPenBox.setScale(scale);
            ToolPanel.toolBox2.setScale(scale);
            AboutBoxController.setAboutBoxScale(scale);
            EyeDropperTool.eyedropperLens.setScale(scale);
            ColorPickerController.numPadBox.setScale(scale);
            updateStageOffset();
            SidebarController.updateScrollBarHeight();
            ReplayDrawer.rReplayFOFOCursor.setScale(scale);
            SidebarController.fofo.setScale(scale);
            SidebarController.checkFOFOPosition();

            // 이거 위에서 뭔가 해주고 난후에 여기서 해줘야함
            SidebarController.sideBar.y = Math.round(STAGE_TOP_OFFSET);
            SidebarController.sideBar.updateSideBGSize(SidebarController.getSideBarBGHeight());

            if (LassoTool.isStarted)
                keepBoxInsideViewPort(LassoTool._lassoMenuBox);
            if (ReferenceLayerController.isRefLayerMenuON)
                keepBoxInsideViewPort(ReferenceLayerController.refLayerMenuBox);

            CanvasNavigator.updateCursor();
            HintController.hideBottomHint();
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
            if (AppDataPaths.isLoadingAppData)
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
                CanvasViewport.current().fitToViewportMargin();

                if (!CaptureController.isFullImageCapture())
                {
                    CaptureController.updateCaptureAreaOverlay(true);
                }
            }
            else
            {
                if (ReplayController.isReplayRestartTimerON())
                {
                    ReplayDrawer.viewport.centerIn("replay");
                }
                else
                {
                    ReplayDrawer.rCanvasAnchorPoint.x = ReplayDrawer.rCanvasAnchorPoint.x + dx;
                    ReplayDrawer.rCanvasAnchorPoint.y = ReplayDrawer.rCanvasAnchorPoint.y + dy;
                }

                CanvasView.canvasAnchorPoint.x = CanvasView.canvasAnchorPoint.x + dx;
                CanvasView.canvasAnchorPoint.y = CanvasView.canvasAnchorPoint.y + dy;
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
                ReplayDrawer.cursorFollow.updateBounds();

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
            CanvasNavigator.updateCursor();

            if (LoadBoxController.loadMenuBox.visible === true)
            {
                LoadBoxController.loadMenuBox.updateClickBlockerSize(main.stage.stageWidth, main.stage.stageHeight);
            }

            if (ToolPanel.selectedToolViewBitmap.visible)
            {
                ToolPanel.updateSelectedToolViewBoxPos();
            }

            updateStageBGSize();
            SidebarController.checkFOFOPosition();
            HintController.updateBottomBarLayoutAndColor();
        }

        // 파일 드래그 드롭등 마우스 이벤트에서도 target이 null이 되는등
        // 방지를 위해서 스테이지 전체 +2사이즈 여백으로 뒷부분 전체를 투명하게 깔아줌
        public static function updateStageBGSize():void
        {
            UIController.stageBG.graphics.clear();
            UIController.stageBG.graphics.beginFill(0, 0.0);
            UIController.stageBG.graphics.drawRect(-2, -2, main.stage.stageWidth + 4, main.stage.stageHeight + 4);
            UIController.stageBG.graphics.endFill();
            if (UIController.stageBG.getChildByName("rCanvasCompleteAnchorPoint"))
            {
                ReplayController.setReplayCompleteCanvasCenter();
            }
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

            CanvasNavigator.box.chanegStageColor(STAGE_BG_COLOR);

            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.canvasWindow.stage.color = STAGE_BG_COLOR;
            }

            SidebarController.sideBar.updateUIColor();
            ToolPanel.toolOptionsBox.updateUIColor();
            ColorPickerController.colorPickerBox.updateUIColor();
            canvasInfoBox.updateUIColor();
            canvasRotateCursor.changeUIColor();
            SidebarController.fofo.updateColor();
            ToolPanel.toolBox.changeUIColor();
            ToolPanel.toolBox2.changeUIColor();
            FillPenTool.fillPenBox.updateUIColor();
            LassoTool._lassoMenuBox.updateUIColor();
            ColorPickerController.numPadBox.updateUIColor();
            ReferenceLayerController.refLayerMenuBox.updateUIColor();
            topBar.updateUIColor();
            ReplayController.seekBarBox.updateUIColor();
            CaptureStamp.captureStampFontListBox.updateUIColor();
            HintController.mouseHint.updateBGColor();
            HintController.bottomHint.updateHintTextColor(0);

            CanvasResizer.setButtonColor();
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
            canvasRotateCursor.visible = false;
        }

        public static function showCanvasRotateCursorMouseDrag(target:DisplayObject):Function
        {
            const snapThreshold:Number = 82;
            canvasRotateCursor.x = main.stage.mouseX;
            canvasRotateCursor.y = main.stage.mouseY + (65 * UITheme.getUIScale());
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

            return function ():Number
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

        // 드로우 모드 캔버스 패널과 화면 객체를 스테이지에 조립함 (표시 순서 포함)
        public static function initializeCanvasView():void
        {
            var g:Graphics;
            CanvasView.canvasPanel.name = "canvasPanel";
            CanvasView.canvasAnchorPoint.name = "canvasAnchorPoint";
            DrawCanvas.canvasLayer1Bitmap.name = "canvasLayer1Bitmap";
            DrawCanvas.canvasLayer2Bitmap.name = "canvasLayer2Bitmap";
            StrokeBuffer.canvasDrawLayer.name = "canvasDrawLayer";
            StrokeBuffer.canvasDrawLayerChild.name = "canvasDrawShape";
            UIController.stageBG.name = "stageBG";
            ReferenceLayerController.canvasRefLayer.name = "canvasRefLayer";
            CanvasGridOverlay.canvasGrid.name = "canvasGrid";
            CanvasView.canvasFlashEffect.name = "canvasFlash";
            LassoLayers.lassoLayer1.name = "lassoBox1";
            LassoLayers.lassoLayer1.addChild(LassoLayers.lassoLayer1Bitmap);
            LassoLayers.lassoLayer1.addChild(LassoLayers.lassoDraw);
            LassoLayers.lassoLayer1.addChild(LassoLayers.lassoDrawCloseLine);
            LassoLayers.lassoLayer1.visible = false;
            LassoLayers.lassoLayer2.name = "lassoBox2";
            LassoLayers.lassoLayer2.addChild(LassoLayers.lassoLayer2Bitmap);
            LassoLayers.lassoLayer2.visible = false;
            // setCanvasBGColorDrawMode는 같은 색이면 바로 리턴하므로, 초기값(흰색)은 스크래치 패드에 전달되지 않아
            // 최초 실행시 패드 배경이 안 그려졌음. 초기 색은 직접 전달함
            ColorPickerController.colorPickerBox.scratchPad.updateBGColor(DrawCanvas.CANVAS_BG_COLOR);
            CanvasView.updateCanvasPanelMask(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT);
            ReferenceLayerController.canvasRefLayer.alpha = ReferenceLayerController.refLayerLastAlpha;
            ReferenceLayerController.canvasRefLayer.addChild(ReferenceLayerController.canvasRefLayerBitmap);
            StrokeBuffer.canvasDrawLayer.addChild(StrokeBuffer.canvasDrawLayerBitmap);
            StrokeBuffer.canvasDrawLayer.addChild(StrokeBuffer.canvasDrawLayerChild);
            StrokeBuffer.canvasDrawLayer.blendMode = "layer"; // 캔버스1이랑 알파 불투명도가 겹치지 않게 layer모드로 해줌
            ReplayDrawer.rReplayFOFOCursor.visible = false;
            ReferenceLayerController.canvasRefHolder.addChild(ReferenceLayerController.canvasRefLayer);
            CanvasView.canvasPanel.addChild(ReferenceLayerController.canvasRefHolder);
            CanvasView.canvasPanel.addChild(DrawCanvas.canvasLayer2Bitmap);
            CanvasView.canvasPanel.addChild(LassoLayers.lassoLayer2);
            CanvasView.canvasPanel.addChild(DrawCanvas.canvasLayer1Bitmap);
            CanvasView.canvasPanel.addChild(LassoLayers.lassoLayer1);
            CanvasView.canvasPanel.addChild(StrokeBuffer.canvasDrawLayer);
            CanvasView.canvasPanel.addChild(CanvasGridOverlay.canvasGrid);
            CanvasView.canvasPanel.addChild(ReplayDrawer.rReplayFOFOCursor);
            // canvasrotate가 중점으로 올수있게 위치를 절반으로세팅
            CanvasView.canvasPanel.x = Math.floor(-CanvasView.canvasPanel.width / 2);
            CanvasView.canvasPanel.y = Math.floor(-CanvasView.canvasPanel.height / 2);
            CanvasView.canvasAnchorPoint.addChild(CanvasView.canvasPanel);
            main.stage.addChild(UIController.stageBG);
            main.stage.addChild(EyeDropperTool.eyedropperLens);
            main.stage.addChild(LassoTool._lassoMenuBox);
            main.stage.addChild(CanvasView.canvasAnchorPoint);
            main.stage.addChild(PenSizePreviewCursor.getCursorShape());
            main.stage.setChildIndex(CanvasView.canvasAnchorPoint, 0);
            main.stage.setChildIndex(UIController.stageBG, 0);
        }

        // 드로우 모드 캔버스를 좌우 반전하고 관련 UI를 갱신함
        public static function mirrorCanvas(canvasOnly:Boolean = false):void
        {
            // canvaspanel로 하면 중점이 안맞아서 canvas1로함
            const p:Point = CanvasView.getCanvasPanelMidPos();
            DrawCanvas.mirrorON = !DrawCanvas.mirrorON;
            ReplayState.mirrorCommandReady = !ReplayState.mirrorCommandReady;
            DrawCanvas.mirrorBmpdDrawmode();
            UIController.canvasInfoBox.setMirror(DrawCanvas.mirrorON);
            // 회전각 부호를 바꿔야 제대로 mirror가됨
            CanvasView.viewport.moveAnchorPoint(p.x, p.y); // regpoint를 회전한 캔버스 중점으로 두고
            if (canvasOnly === false) // 보통 미러할때, canvasonly가 true일때는 appdata에서 바꿔줄때 밖에 없음
            {
                CanvasView.canvasAnchorPoint.rotation = -CanvasView.canvasAnchorPoint.rotation; // 반대각으로 세팅
                ReplayDrawer.setRcursorRotation(CanvasView.canvasAnchorPoint.rotation);
                ReferenceLayerController.mirrorRefLayerImage();
            }
            CanvasGridOverlay.updateGridMirror(DrawCanvas.mirrorON);
            const halfCanvas:Number = (main.stage.stageWidth - SidebarController.sideBar.getWidth()) / 2;
            var stageHalf:Number = (SidebarController.sideBar.visible === false) ? main.stage.stageWidth / 2
                : (SidebarController.isRightSidebar) ? halfCanvas
                : UIController.STAGE_LEFT_OFFSET + halfCanvas;
            // 창 절반을 기준점으로 앵커포인트 x축 이동.
            CanvasView.canvasAnchorPoint.x += Math.round((stageHalf - p.x) * 2);
            CanvasNavigator.updateCursor();
            FileManager.isFileAlreadySaved = false; // 미러도 화면이 바뀌기 때문에 세이브 플래그 꺼줌
            ReplayDrawer.mirrorRCursorPos();

            CanvasNavigator.box.updateImage();
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
            }
        }

        // 캔버스 회전을 0으로 되돌림 (화면 중심 기준)
        public static function resetRotationDrawMode():void
        {
            const center:Point = UIController.getStageCenterPos("draw");
            PenSizePreviewCursor.updateSizeAndShape();
            CanvasView.viewport.moveAnchorPoint(center.x, center.y);
            CanvasView.canvasAnchorPoint.rotation = 0;
            ReplayDrawer.setRcursorRotation(0);
            UIController.canvasInfoBox.setRotate(0);
        }

        // 캔버스 배율을 100%로 되돌림 (화면 중심 기준)
        public static function resetZoomDrawMode():void
        {
            if (CanvasView.canvasZoomMultiplier !== 1.0)
            {
                const center:Point = UIController.getStageCenterPos("draw");
                const gcenter:Point = CanvasView.canvasPanel.globalToLocal(new Point(center.x, center.y));
                const gp:Point = CanvasView.canvasPanel.localToGlobal(new Point(0, 0));
                const panelLimitedPos:Point = ZoomTool.getCanvasBoundLimitPoint(CanvasView.canvasPanel, gcenter.x, gcenter.y, DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, CanvasView.canvasAnchorPoint.scaleY, -CanvasView.canvasAnchorPoint.rotation);
                CanvasView.viewport.moveAnchorPoint(panelLimitedPos.x + gp.x, panelLimitedPos.y + gp.y);
                CanvasView.canvasZoomIndex = CanvasView.canvasZoomMultiplierList.indexOf(1.0);
                CanvasView.viewport.setScale(1.0);
                PenSizePreviewCursor.updateSizeAndShape();
                CanvasGridOverlay.drawGrid();
            }
        }

        // 캔버스 패널이 바뀐 뒤 네비게이터 배경색, 캔버스 정보 크기, 격자를 갱신함
        public static function updateCanvasPanelLinkedUI():void
        {
            CanvasNavigator.box.changeprevBitmapBGColor(DrawCanvas.CANVAS_BG_COLOR);
            UIController.canvasInfoBox.setSize(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT);

            if (CanvasGridOverlay.gridGapMultiplier > 0)
            {
                CanvasGridOverlay.drawGrid();
            }
        }

        // 캔버스 네비게이터와 이미지 보기 창의 미리보기 이미지를 갱신함
        public static function updateCanvasPreviews():void
        {
            CanvasNavigator.box.updateImage();

            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
            }
        }


        //커서가 드로우 영역에 있는지 검사
        public static function isCursorInDrawArea():Boolean
        {
            return !(UIController.topBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY)
                    || (SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                    || (ReplayController.seekBarBox.visible && ReplayController.seekBarBox.hitTestPoint(main.stage.mouseX, main.stage.mouseY)));
        }

    }
}
