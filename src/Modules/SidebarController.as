package Modules
{
    import Modules.DrawEngine.CanvasView;
    import Modules.UIEngine.CanvasNavigator;
    import Modules.DrawEngine.CanvasResizer;
    import Modules.InputManager.InputManager;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;
    import Modules.UIEngine.UITheme;
    import Modules.CaptureEngine.CaptureController;
    import Modules.Tools.LassoTool;

    import Symbols.FOFO;
    import Symbols.SidePanelSet;

    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.filesystem.File;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import Modules.Tools.EyeDropperTool;
    import Modules.Tools.LineTool;
    import Modules.Tools.FillPenTool;
    import Modules.ReplayEngine.ReplayState;

    public final class SidebarController
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }
        public static const SCROLL_BAR_WIDTH:Number = 21;
        public static const sideBar:SidePanelSet = new SidePanelSet();
        public static const fofo:FOFO = new FOFO();
        public static const sideBarScrollBar:Sprite = new Sprite();
        public static const sideBarScrollPanel:Sprite = new Sprite();

        public static var scrollSetMovedY:Number = 0;
        private static var scrollBarHeight:Number = 0;
        private static var sideBarConstHeight:Number = 780;

        public static var isSidebarVisible:Boolean = true; // 사이드바 표시 여부
        private static var isSidebarTempShowDeactivated:Boolean = false; // 사이드바 임시로 보여주는 기능이 잠시 꺼졌을때 올려줌
        private static var isReactivateSidebarTempShowEventsAdded:Boolean = false; // 사이드바 임시로 보여주는 기능을 끄는 이벤트들이 등록되면 올려줌
        private static var isSidebarHideEventAdded:Boolean = false; // 사이드바가 임시로 보여졌을때 마우스 클릭하면 꺼주는 이벤트가 추가되면 올려줌
        public static var isRightSidebar:Boolean = false; // 사이드바 위치 (false: 왼쪽, true: 오른쪽)

        public static var isQuickSidebarActive:Boolean = false; // 퀵 사이드바 활성화 여부
        public static var isLoadPendingAfterSaving:Boolean = false; // 저장 후 로드 대기 플래그
        private static var isLayerCheckKeyPressed:Boolean = false; // 키 입력 반복 시 함수 중복 호출 방지 플래그
        private static var isDrawModeInputEventsAdded:Boolean = false; // 드로우 모드 이벤트 중복 추가 방지
        private static var isReplayModeInputEventsAdded:Boolean = false; // 리플레이 모드 이벤트 중복 추가 방지
        private static var isFileBrowserOpened:Boolean = false; // 캡처 저장 시 중복 실행 방지 플래그
        private static var lastLoadedFile:File; // invoke나 파일 드래그 드롭했을때 저장해줘서 같은 파일 로드하지 않게
        private static var loadMenuBoxBitmapData:BitmapData; // 메뉴 박스 미리보기 이미지 데이터
        private static var loadMenuBoxFileType:String; // 메뉴 박스에 로드할 파일 종류
        private static var loadMenuBoxFile:File; // 메뉴 박스에 로드할 파일

        public static function isMouseCursorInSideBar():Boolean
        {
            if (sideBar.visible === true)
            {
                const scale:Number = UITheme.getUIScale();

                if (isRightSidebar
                        && main.stage.mouseX >= sideBar.x - sideBarScrollBar.width * scale
                        && main.stage.mouseX <= sideBar.x + sideBar.WIDTH * scale
                        && main.stage.mouseY >= sideBar.y
                        && main.stage.mouseY <= main.stage.stageHeight)
                {
                    return true;
                }
                else if (main.stage.mouseX >= sideBar.x
                        && main.stage.mouseX <= sideBar.x + sideBar.WIDTH * scale + sideBarScrollBar.width * scale
                        && main.stage.mouseY >= sideBar.y
                        && main.stage.mouseY <= main.stage.stageHeight)
                {
                    return true;
                }
            }

            return false;
        }

        private static function getSidebarConstHeight():Number
        {
            return (sideBarConstHeight + ((PaletteController.isMyPaletteExpended && PaletteController.myPalettePresetType === 0) ? PaletteController.myPaletteColorHeight * 7 : 0));
        }

        private static function checkCollisionFOFOAndSideBarScrollSet():int
        {
            const sideBarWidth:Number = sideBar.getWidth();
            const scale:Number = UITheme.getUIScale();
            const fofoHeight:Number = fofo.height - 10 * scale;

            const fofoTopRect:Rectangle = new Rectangle(sideBar.x, UIController.STAGE_TOP_OFFSET, sideBarWidth, fofoHeight);
            const fofoBottomRect:Rectangle = new Rectangle(sideBar.x, main.stage.stageHeight - UIController.STAGE_BOTTOM_OFFSET - fofoHeight, sideBarWidth, fofoHeight);

            const gp:Point = sideBarScrollPanel.localToGlobal(new Point(0, 0));
            const sideBarRect:Rectangle = new Rectangle(gp.x - sideBarScrollPanel.x * scale, gp.y, sideBar.getWidth(), getSidebarConstHeight() * scale);

            const collisionTop:Boolean = sideBarRect.intersects(fofoTopRect);
            const collisionBottom:Boolean = sideBarRect.intersects(fofoBottomRect);

            return (collisionTop && collisionBottom) ? FOFO.COLLISION_ALL : (collisionBottom) ? FOFO.COLLISION_BOTTOM : (collisionTop) ? FOFO.COLLISION_TOP : FOFO.COLLISION_NONE;
        }

        private static function alignFOFOToSidebar():void
        {
            if (isRightSidebar)
            {
                fofo.setMirror(false);
                fofo.x = sideBar.x + sideBar.getWidth() - fofo.width;
            }
            else
            {
                fofo.setMirror(true);
                fofo.x = sideBar.x;
            }
        }

        public static function checkFOFOPosition():void
        {
            if (!sideBar.visible)
            {
                fofo.visible = false;

                return;
            }

            const checkYPos:int = checkCollisionFOFOAndSideBarScrollSet();
            fofo.visible = sideBar.visible;

            switch (checkYPos)
            {
                case FOFO.COLLISION_NONE:
                    return;

                case FOFO.COLLISION_ALL:
                    fofo.visible = false;
                    break;

                case FOFO.COLLISION_BOTTOM:
                    {
                        fofo.setTop(UIController.STAGE_TOP_OFFSET);
                        alignFOFOToSidebar();
                        fofo.visible = true;
                    }
                    break;

                case FOFO.COLLISION_TOP:
                    {
                        alignFOFOToSidebar();
                        fofo.setBottom(main.stage.stageHeight - UIController.STAGE_BOTTOM_OFFSET);
                        fofo.visible = true;
                    }
                    break;
            }
        }

        private static function onMouseUpQuickSidebar(e:MouseEvent):void
        {
            deactivateQuickSidebar();
        }

        public static function deactivateQuickSidebar():void
        {
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpQuickSidebar);
            main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpQuickSidebar);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownQuickSidebar);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownQuickSidebar);

            if (isSidebarVisible === false)
            {
                sideBar.visible = false;
            }

            setSidebarDefaultPos();

            isQuickSidebarActive = false;
            checkFOFOPosition();

            sideBar.resetBG();

            if (ToolController.toolBox.getLastTool() === "toolEyedropper")
            {
                EyeDropperTool.start();
            }

            if (ReferenceLayerController.isRefLayerMenuON)
            {
                ReferenceLayerController.refLayerMenuBox.visible = true;
            }

            HintController.hideBottomHint();
            ColorPickerController.closeNumpad();
        }

        public static function startDeactivteQuickSidebar():void
        {
            if (MouseState.isLeftDown && sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
            {
                main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpQuickSidebar, false, InputPriority.DEFAULT);
                return;
            }

            deactivateQuickSidebar();
        }

        private static function onRightMouseDownQuickSidebar(e:MouseEvent):void
        {
            if (!e.target || ColorPickerController.numPadBox.visible || UIController.isPopUpWindowOpened())
            {
                return;
            }

            switch (e.target.name)
            {
                case "toolZoomIn":
                case "toolZoomOut":
                    if (CanvasView.canvasZoomMultiplier !== 1.0)
                    {
                        CanvasView.resetZoomDrawMode();
                        CanvasNavigator.updateCursor();
                    }
                    break;

                case "toolRotate":
                    if (CanvasView.canvasAnchorPoint.rotation !== 0.0)
                    {
                        CanvasView.resetRotationDrawMode();
                        CanvasNavigator.updateCursor();
                    }
                    break;

                case "sideBarScrollBar":
                    resetSideBarPosition();
                    break;

                case "myPaletteBox":
                    // 이거 있어야됨
                    break;

                default:
                    break;
            }

            startDeactivteQuickSidebar();
        }

        private static function onMouseDownQuickSidebar(e:MouseEvent):void
        {
            if (e.target && e.target.name === "sideBarScrollBar")
            {
                return;
            }

            if (main.stage.mouseX < sideBar.x || main.stage.mouseX > sideBar.x + sideBar.getWidth()
                    || main.stage.mouseY < sideBar.y)
            {
                startDeactivteQuickSidebar();
            }
        }

        private static function onKeyUpQuickSidebar(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;

            if (keyCode === InputManager.KEY.s || keyCode === InputManager.KEY.d
                    || keyCode === InputManager.KEY.j || keyCode === InputManager.KEY.k
                    || keyCode === InputManager.KEY.n6)
            {
                startDeactivteQuickSidebar();
            }
        }

        public static function setSidebarDefaultPos():void
        {
            if (isRightSidebar)
            {
                sideBar.x = Math.round(main.stage.stageWidth - sideBar.getWidth());
            }
            else
            {
                sideBar.x = 0;
            }
        }

        public static function activeQuickSideBar(shortcut:Boolean):void
        {
            isQuickSidebarActive = true;

            if (shortcut)
            {
                if (!FillPenTool.isStarted && !LineTool.isStarted)
                {
                    ToolController.selectLastUsedTool();
                }

                main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpQuickSidebar, false, InputPriority.DEFAULT);
            }
            else
            {
                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownQuickSidebar, false, InputPriority.LATE);
            }

            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownQuickSidebar, false, InputPriority.LATE);

            const sideBarWidth:Number = sideBar.getWidth();
            const scrollBarWidthLeft:Number = (isRightSidebar) ? sideBarScrollBar.width : 0;
            const scrollBarWidthRight:Number = (!isRightSidebar) ? sideBarScrollBar.width : 0;

            sideBar.x = main.mouseX - (sideBarWidth) / 2 + ((isRightSidebar) ? -18 : 22);

            if (sideBar.x - scrollBarWidthLeft < 0)
            {
                sideBar.x = scrollBarWidthLeft;
            }
            else if (sideBar.x + sideBarWidth + scrollBarWidthRight > main.stage.stageWidth)
            {
                sideBar.x = main.stage.stageWidth - (sideBarWidth + scrollBarWidthRight);
            }

            if (sideBar.visible === true && isSidebarVisible === false)
            {
                removeSidebarTempShowActivateEvents();
            }

            if (ReferenceLayerController.isRefLayerMenuON)
            {
                ReferenceLayerController.refLayerMenuBox.visible = false;
            }

            if (HintController.mouseHint.isShowing())
            {
                HintController.hideMouseHint();
            }

            if (HintController.isBottomBarVisible())
            {
                HintController.hideBottomHint();
            }

            if (ToolController.selectedToolViewBitmap.visible)
            {
                ToolController.selectedToolViewBitmap.visible = false;
            }

            sideBar.setTransparentBG();
            sideBar.visible = true;

            checkFOFOPosition();
        }

        public static function isPressingQuickSidebarShortcut(key1:int, key2:int):Boolean
        {
            if ((key1 === InputManager.KEY.s && key2 === InputManager.KEY.d)
                    || (key1 === InputManager.KEY.d && key2 === InputManager.KEY.s)
                    || (key1 === InputManager.KEY.j && key2 === InputManager.KEY.k)
                    || (key1 === InputManager.KEY.k && key2 === InputManager.KEY.j))
            {
                return true;
            }

            return false;
        }

        public static function startHidingSidebarTemporary():void
        {
            removeSidebarTempShowActivateEvents();

            if (isSidebarVisible === false)
            {
                hideSidebarTemporary();
            }
        }

        private static function addSidebarTempShowActivateEvents():void
        {
            isReactivateSidebarTempShowEventsAdded = true;

            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownReactivateSidebarTempShow, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onMouseDownReactivateSidebarTempShow, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpReactivateSidebarTempShow, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpReactivateSidebarTempShow, false, InputPriority.DEFAULT);
        }

        private static function setSideBarClickEvents():void
        {
            isSidebarHideEventAdded = true;

            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownHideSidebar, false, InputPriority.MODE);
        }

        private static function removeSidebarTempShowActivateEvents():void
        {
            FOFOTimer.remove("sidebarTempShowActivateTimer");

            isSidebarTempShowDeactivated = false;
            isSidebarHideEventAdded = false;
            isReactivateSidebarTempShowEventsAdded = false;

            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownHideSidebar);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpReactivateSidebarTempShow);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpReactivateSidebarTempShow);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownReactivateSidebarTempShow);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onMouseDownReactivateSidebarTempShow);
        }

        private static function onMouseDownReactivateSidebarTempShow(e:MouseEvent):void
        {
            if (sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
            {
                removeSidebarTempShowActivateEvents();
            }
        }

        private static function startTimerActivateSidebarShowTemp():void
        {
            isSidebarTempShowDeactivated = true;

            FOFOTimer.addByName("sidebarTempShowActivateTimer", 0.7, false, function ():void
                {
                    isReactivateSidebarTempShowEventsAdded = false;
                    isSidebarTempShowDeactivated = false;
                    removeSidebarTempShowActivateEvents();
                });
        }

        private static function onMouseUpReactivateSidebarTempShow(e:MouseEvent):void
        {
            if (!(MouseState.isRightDown && MouseState.isLeftDown))
            {
                startTimerActivateSidebarShowTemp();
            }
        }

        private static function onMouseDownHideSidebar(e:MouseEvent):void
        {
            if (e.target && (e.target.name === "sideBarONButton" || e.target.name === "sideBarONButton2" || e.target.name === "fofo"))
            {
                // do nothing
            }
            else if (sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
            {
                startHidingSidebarTemporary();
            }
        }

        private static function startShowSideBarTemporary():void
        {
            if (!(MouseState.isLeftDown || MouseState.isRightDown || MouseState.isDragging))
            {
                if (!isSidebarTempShowDeactivated)
                {
                    if (isSidebarHideEventAdded === false)
                    {
                        setSideBarClickEvents();
                    }

                    if (sideBar.visible === false)
                    {
                        // setSidebarVisible(true,true);
                        showSidebarTemporary();
                    }
                }
            }
            else if (isReactivateSidebarTempShowEventsAdded === false && sideBar.visible === false) // 클릭한 상태에서 들어올경우
            {
                addSidebarTempShowActivateEvents();
            }
        }

        private static function canShowSidebarTemporarily():Boolean
        {
            return !sideBar.visible
                && !ReplayState.isReplayModeON
                && !CaptureController.isCaptureModeON
                && !ToolController.isToolBox2Showing
                && !MouseState.isClickBlocked
                && !CanvasResizer.isButtonVisible();
        }

        private static function onMouseLeaveSideBar(e:Event):void
        {
            if (canShowSidebarTemporarily())
            {
                const sideBarWidth:Number = sideBar.getWidth();

                if (((isRightSidebar && main.stage.mouseX > main.stage.stageWidth - sideBarWidth)
                            || (!isRightSidebar && main.stage.mouseX < sideBarWidth))
                        && main.mouseY > UIController.STAGE_TOP_OFFSET)
                {
                    startShowSideBarTemporary();
                }
            }
        }

        private static function onMouseMoveSideBar(e:MouseEvent):void
        {
            if (canShowSidebarTemporarily())
            {
                const mx:Number = main.stage.mouseX;
                const my:Number = main.stage.mouseY;

                if ((!isRightSidebar && mx <= 15 || isRightSidebar && mx >= main.stage.stageWidth - 15) && my > UIController.STAGE_TOP_OFFSET)
                {
                    startShowSideBarTemporary();
                }
            }

            if (!isSidebarVisible && sideBar.visible)
            {
                // 사이드바 안에서 시작한 드래그(스크롤바, 컬러피커, opabox 등) 도중에는 밖으로 나가도 숨기지 않음
                if (MouseState.isDragging)
                {
                    FOFOTimer.remove("sidebarHideDelayTimer");
                }
                else if (Utils.isCursorInDrawArea())
                {
                    if (!FOFOTimer.hasTimer("sidebarHideDelayTimer"))
                    {
                        FOFOTimer.addByName("sidebarHideDelayTimer", 0.3, false, hideSidebarTemporary);
                    }
                }
                else if (FOFOTimer.hasTimer("sidebarHideDelayTimer"))
                {
                    FOFOTimer.remove("sidebarHideDelayTimer");
                }
            }
        }

        private static function onMouseUpSideBar(e:MouseEvent):void
        {
            const mx:Number = main.stage.mouseX;
            const my:Number = main.stage.mouseY;

            if (mx < 0 || mx > main.stage.stageWidth || my < 0 || my > main.stage.stageHeight)
            {
                if (sideBar.visible === false)
                {
                    addSidebarTempShowActivateEvents();
                }
            }
        }

        private static function updateSidebarLayout():void
        {
            UIController.updateStageOffset();
            CanvasNavigator.updateCursor();

            checkFOFOPosition();

            if (ToolController.selectedToolViewBitmap.visible)
            {
                ToolController.updateSelectedToolViewBoxPos();
            }
        }

        public static function showSidebarPermanent():void
        {
            isSidebarVisible = true;
            sideBar.visible = true;

            UIController.topBar.checkSideBarONOFFButton(true, isRightSidebar);

            updateSidebarLayout();

            HintController.hideBottomHint();

            LassoTool.recordLassoAndRefLayerBoxLastPos();

            sideBar.resetBG();

            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpSideBar);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpSideBar);
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveSideBar);
            main.stage.removeEventListener(Event.MOUSE_LEAVE, onMouseLeaveSideBar);
        }

        public static function hideSidebarPermanent():void
        {
            isSidebarVisible = false;
            sideBar.visible = false;

            UIController.topBar.checkSideBarONOFFButton(false, isRightSidebar);

            updateSidebarLayout();

            HintController.hideBottomHint();

            LassoTool.restoreLassoAndRefLayerBoxLastPos();

            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpSideBar, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpSideBar, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveSideBar);
            main.stage.addEventListener(Event.MOUSE_LEAVE, onMouseLeaveSideBar);
        }

        private static function showSidebarTemporary():void
        {
            sideBar.visible = true;

            updateSidebarLayout();

            LassoTool.recordLassoAndRefLayerBoxLastPos();

            sideBar.setTransparentBG();
        }

        public static function hideSidebarTemporary():void
        {
            sideBar.visible = false;

            updateSidebarLayout();

            LassoTool.restoreLassoAndRefLayerBoxLastPos();
        }

        public static function toggleSideBarPosition():void
        {
            if (isRightSidebar === false)
            {
                isRightSidebar = true;
                moveSideBar("right");
            }
            else if (isRightSidebar === true)
            {
                isRightSidebar = false;
                moveSideBar("left");
            }
        }

        public static function moveSideBar(direction:String, ignoreCheckStageOffset:Boolean = false):void
        {
            // direction: "left" or "right"
            const isRight:Boolean = (direction === "right");

            setSidebarDefaultPos();

            UIController.updateStageOffset();

            sideBarScrollPanel.x = isRight ? 9 : 5;
            sideBarScrollPanel.y = scrollSetMovedY;

            CanvasNavigator.box.x = isRight ? -4 : 0;
            CanvasNavigator.box.y = 0;

            UIController.canvasInfoBox.setWidth(CanvasNavigator.box.BOX_WIDTH);
            UIController.canvasInfoBox.x = CanvasNavigator.box.x - 2;
            UIController.canvasInfoBox.y = Math.floor(CanvasNavigator.box.y + CanvasNavigator.box.BOX_HEIGHT + 6);

            ToolController.toolOptionsBox.x = isRight ? 39 : 0;
            ToolController.toolOptionsBox.y = Math.floor(UIController.canvasInfoBox.y + UIController.canvasInfoBox.height + 7);

            ColorPickerController.colorPickerBox.x = ToolController.toolOptionsBox.x;
            ColorPickerController.colorPickerBox.y = Math.floor(ToolController.toolOptionsBox.y + ToolController.toolOptionsBox.height + 10);

            ToolController.toolBox.x = isRight ? -2 : 177;
            ToolController.toolBox.y = Math.floor(ToolController.toolOptionsBox.y + 1);

            if (!isRight && ToolController.toolBox.getDeafultY() === 0)
            {
                ToolController.toolBox.setDeafultY(ToolController.toolBox.y);
            }

            resetScrollBarX();

            sideBar.y = UIController.topBar.BARSIZE * UIController.topBar.scaleX;

            if (!ignoreCheckStageOffset)
            {
                if (isRight)
                {
                    CanvasView.canvasAnchorPoint.x -= UIController.STAGE_RIGHT_OFFSET;
                }
                else
                {
                    CanvasView.canvasAnchorPoint.x += UIController.STAGE_LEFT_OFFSET;
                }
            }

            if (sideBar.visible)
            {
                UIController.topBar.sideBarOFFButton.visible = isRight;
                UIController.topBar.sideBarOFFButton2.visible = !isRight;
            }
            else
            {
                UIController.topBar.sideBarONButton.visible = isRight;
                UIController.topBar.sideBarONButton2.visible = !isRight;
            }

            UIController.topBar.sideBarPositionButton.visible = !isRight;
            UIController.topBar.sideBarPositionButton2.visible = isRight;

            checkFOFOPosition();

            if (LassoTool.isStarted)
            {
                UIController.keepBoxInsideViewPort(LassoTool._lassoMenuBox);
            }

            if (ReferenceLayerController.isRefLayerMenuON)
            {
                UIController.keepBoxInsideViewPort(ReferenceLayerController.refLayerMenuBox);
            }

            HintController.hideBottomHint();
        }

        public static function updateScrollBarColorAndHeight():void
        {
            const scale:Number = UITheme.getUIScale();
            const topBarHeight:Number = Math.round(UIController.topBar.BARSIZE * scale);
            const height:Number = Math.round((main.stage.stageHeight - topBarHeight - UIController.STAGE_BOTTOM_OFFSET) / scale);

            const color1:uint = UITheme.getUIFGColor();
            const color2:uint = UITheme.getUIBGColor();

            sideBarScrollBar.graphics.clear();
            sideBarScrollBar.graphics.lineStyle(2, color1, 1.0, true);
            sideBarScrollBar.graphics.beginFill(color2);
            sideBarScrollBar.graphics.drawRect(0, 1, SCROLL_BAR_WIDTH, height - 2);
            sideBarScrollBar.graphics.endFill();

            scrollBarHeight = height;
        }

        private static function resetScrollBarX():void
        {
            if (sideBarScrollBar.visible === false)
            {
                sideBarScrollBar.x = 0;
            }
            else if (isRightSidebar)
            {
                sideBarScrollBar.x = CanvasNavigator.box.x - sideBarScrollBar.width + 4;
            }
            else
            {
                sideBarScrollBar.x = sideBar.WIDTH;
            }
        }

        public static function updateScrollBarHeight():void
        {
            updateScrollBarColorAndHeight();
            resetScrollBarX();
            keepScrollSetInStage();
        }

        public static function getSideBarBGHeight():Number
        {
            return (main.stage.stageHeight - UIController.topBar.BARSIZE * UITheme.getUIScale()) / UITheme.getUIScale();
        }

        private static function keepScrollSetInStage():void
        {
            const scale:Number = UITheme.getUIScale();
            const limitTop:Number = Math.floor(-sideBarConstHeight + 20.0);
            const limitBottom:Number = Math.floor(main.stage.stageHeight - UIController.STAGE_TOP_OFFSET - UIController.STAGE_BOTTOM_OFFSET - 20.0 * scale);

            if (sideBarScrollPanel.y < limitTop)
            {
                sideBarScrollPanel.y = limitTop;
            }
            else if (sideBarScrollPanel.y * scale > limitBottom)
            {
                sideBarScrollPanel.y = limitBottom / scale;
            }

            scrollSetMovedY = sideBarScrollPanel.y;
        }

        public static function resetSideBarPosition():void
        {
            sideBarScrollPanel.y = 0;
            scrollSetMovedY = sideBarScrollPanel.y;

            checkFOFOPosition();
        }

        public static function startScrollSidebarByDrag():void
        {
            const scale:Number = UITheme.getUIScale();
            var clickY:Number = main.stage.mouseY;
            const alphaSave:Number = sideBarScrollBar.alpha;

            function onDragStart():void
            {
                sideBarScrollBar.alpha = 0.9;
            }

            function onMouseMove():void
            {
                const subY:Number = (clickY - main.mouseY) / scale;

                sideBarScrollPanel.y += subY * 1.5;
                scrollSetMovedY = sideBarScrollPanel.y;

                clickY = main.mouseY;
            }

            function onMouseUp():void
            {
                sideBarScrollBar.alpha = alphaSave;

                keepScrollSetInStage();
                scrollSetMovedY = sideBarScrollPanel.y;

                main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);

                checkFOFOPosition();
            }

            DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
        }

        public static function startScrollSidebarByMouseWheel(deltaY:Number):void
        {
            deltaY = Math.floor(deltaY * UITheme.getUIScale());

            sideBarScrollPanel.y += deltaY * 1.5;
            scrollSetMovedY = sideBarScrollPanel.y;

            checkFOFOPosition();

            if (HintController.bottomBar.visible || HintController.isHighlightBoxVisible())
            {
                HintController.hideBottomHint();
            }
        }

        public static function handleSidebarMouseDown(target:DisplayObject):Boolean
        {
            const targetName:String = target.name;

            if (sideBarScrollPanel.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
            {
                if (targetName === "navStageBG"
                        || targetName === "navBitmapBG"
                        || targetName === "navLayer1Bitmap"
                        || targetName === "navLayer2Bitmap")
                {
                    CanvasNavigator.startCanvasMove(false);
                    return true;
                }
                else if (targetName === "navCursor")
                {
                    CanvasNavigator.startCanvasMove(true);
                    return true;
                }
                else if (ColorPickerController.handleColorPickerBoxMouseDown(target) && !InputManager.isKeyPressed())
                {
                    return true;
                }
                else if (ToolController.handlePenOptionsBoxMouseDown(target) && (ToolController.isSelectedToolPenOrLine() || ToolController.isSelectedTool(ToolController.TOOL_ERASER)))
                {
                    return true;
                }
                else if (ToolController.toolBox.alpha === 1.0 && target.alpha === 1.0 && ToolController.handleToolBoxMouseDown(target))
                {
                    return true;
                }
            }
            else if (isSidebarVisible === false)
            {
                if (sideBar.visible && !sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY) && Utils.isCursorInDrawArea())
                {
                    startHidingSidebarTemporary();
                    return true;
                }
            }

            return false;
        }
    }
}
