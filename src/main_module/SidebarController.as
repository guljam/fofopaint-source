package main_module
{
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import symbols.SidePanelSet;
    import symbols.FOFO;
    import flash.filesystem.File;
    import flash.display.BitmapData;

    public final class SidebarController
    {
        public static const SCROLL_BAR_WIDTH:Number = 21;
        public static const sideBar:SidePanelSet = new SidePanelSet();
        public static const fofo:FOFO = new FOFO();
        public static const sideBarScrollBar:Sprite = new Sprite();
        public static const sideBarScrollPanel:Sprite = new Sprite();

        public static var scrollSetMovedY:Number = 0;
        public static var scrollBarHeight:Number = 0;
        public static var sideBarConstHeight:Number = 780;

        public static var isSidebarVisible:Boolean = true; // 사이드바 표시 여부
        public static var isSidebarTempShowDeactivated:Boolean = false; // 사이드바 임시로 보여주는 기능이 잠시 꺼졌을때 올려줌
        public static var isReactivateSidebarTempShowEventsAdded:Boolean = false; // 사이드바 임시로 보여주는 기능을 끄는 이벤트들이 등록되면 올려줌
        public static var isSidebarHideEventAdded:Boolean = false; // 사이드바가 임시로 보여졌을때 마우스 클릭하면 꺼주는 이벤트가 추가되면 올려줌
        public static var isRightSidebar:Boolean = false; // 사이드바 위치 (false: 왼쪽, true: 오른쪽)
        public static var lassoAndRefLayerBoxLastPos:Array = [0, 0, 0, 0, 0, 0, 0, 0]; // 사이즈바 켜줄때 임시로 사이드바 안쪽으로 밀려나게 하고 위치가 변경되지 않았으면 원래대로 복귀해줌

        public static var isQuickSidebarActive:Boolean = false; // 퀵 사이드바 활성화 여부
        public static var isLoadPendingAfterSaving:Boolean = false; // 저장 후 로드 대기 플래그
        public static var isLayerCheckKeyPressed:Boolean = false; // 키 입력 반복 시 함수 중복 호출 방지 플래그
        public static var isDrawModeInputEventsAdded:Boolean = false; // 드로우 모드 이벤트 중복 추가 방지
        public static var isReplayModeInputEventsAdded:Boolean = false; // 리플레이 모드 이벤트 중복 추가 방지
        public static var isFileBrowserOpened:Boolean = false; // 캡처 저장 시 중복 실행 방지 플래그
        public static var lastLoadedFile:File; // invoke나 파일 드래그 드롭했을때 저장해줘서 같은 파일 로드하지 않게
        public static var loadMenuBoxBitmapData:BitmapData; // 메뉴 박스 미리보기 이미지 데이터
        public static var loadMenuBoxFileType:String; // 메뉴 박스에 로드할 파일 종류
        public static var loadMenuBoxFile:File; // 메뉴 박스에 로드할 파일

        public static function isMouseCursorInSideBar():Boolean
        {
            const main:Main = Main._instance;

            if (sideBar.visible === true)
            {
                const scale:Number = Global.getUIScale();

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

        public static function getSidebarConstHeight():Number
        {
            return (sideBarConstHeight + ((PaletteController.isMyPaletteExpended && PaletteController.myPalettePresetType === 0) ? PaletteController.myPaletteColorHeight * 7 : 0));
        }

        public static function checkCollisionFOFOAndSideBarScrollSet():int
        {
            const main:Main = Main._instance;

            const sideBarWidth:Number = sideBar.getWidth();
            const scale:Number = Global.getUIScale();
            const fofoHeight:Number = fofo.height - 10 * scale;

            const fofoTopRect:Rectangle = new Rectangle(sideBar.x, MainUIController.STAGE_TOP_OFFSET, sideBarWidth, fofoHeight);
            const fofoBottomRect:Rectangle = new Rectangle(sideBar.x, main.stage.stageHeight - MainUIController.STAGE_BOTTOM_OFFSET - fofoHeight, sideBarWidth, fofoHeight);

            const gp:Point = sideBarScrollPanel.localToGlobal(new Point(0, 0));
            const sideBarRect:Rectangle = new Rectangle(gp.x - sideBarScrollPanel.x * scale, gp.y, sideBar.getWidth(), getSidebarConstHeight() * scale);

            const collisionTop:Boolean = sideBarRect.intersects(fofoTopRect);
            const collisionBottom:Boolean = sideBarRect.intersects(fofoBottomRect);

            return (collisionTop && collisionBottom) ? 0 : (collisionBottom) ? 1 : (collisionTop) ? 2 : 3;
        }

        public static function alignFOFOToSidebar():void
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
            const main:Main = Main._instance;

            if (!sideBar.visible)
            {
                fofo.visible = false;
                return;
            }

            const checkYPos:int = checkCollisionFOFOAndSideBarScrollSet();
            fofo.visible = sideBar.visible;

            switch (checkYPos)
            {
                case 3:
                    // 충돌 없음 그대로 둠
                    return;

                case 0:
                    // 위/아래 모두 충돌 숨김
                    fofo.visible = false;
                    break;

                case 1:
                    // 아래쪽 충돌
                    fofo.setTop(MainUIController.STAGE_TOP_OFFSET);
                    alignFOFOToSidebar();
                    fofo.visible = true;
                    break;

                case 2:
                    // 위쪽 충돌
                    alignFOFOToSidebar();
                    fofo.setBottom(main.stage.stageHeight - MainUIController.STAGE_BOTTOM_OFFSET);
                    fofo.visible = true;
                    break;
            }
        }

        public static function onMouseUpQuickSidebar(e:MouseEvent):void
        {
            deactivateQuickSidebar();
        }

        public static function deactivateQuickSidebar():void
        {
            const main:Main = Main._instance;

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

            if (main.toolBox.getLastTool() === "toolEyedropper")
            {
                main.eyeDropperTool();
            }

            if (ReferenceLayerController.isRefLayerMenuON)
            {
                ReferenceLayerController.refLayerMenuBox.visible = true;
            }

            MainUI.hideBottomHint();
            main.closeNumpad();
        }

        public static function startDeactivteQuickSidebar():void
        {
            const main:Main = Main._instance;

            if (main.isMouseClicked && sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
            {
                main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpQuickSidebar);
                return;
            }

            deactivateQuickSidebar();
        }

        public static function onRightMouseDownQuickSidebar(e:MouseEvent):void
        {
            const main:Main = Main._instance;

            if (!e.target || main.numPadBox.visible || MainUIController.isPopUpWindowOpened())
            {
                return;
            }

            switch (e.target.name)
            {
                case "toolZoomIn":
                case "toolZoomOut":
                    if (main.canvasZoomMultipler !== 1.0)
                    {
                        main.resetZoomDrawMode();
                    }
                    break;

                case "toolRotate":
                    if (main.canvasAnchorPoint.rotation !== 0.0)
                    {
                        main.resetRotationDrawMode();
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

        public static function onMouseDownQuickSidebar(e:MouseEvent):void
        {
            const main:Main = Main._instance;

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

        public static function onKeyUpQuickSidebar(e:KeyboardEvent):void
        {
            const main:Main = Main._instance;
            const keyCode:uint = e.keyCode;

            if (keyCode === main.KEY.s || keyCode === main.KEY.d
                    || keyCode === main.KEY.j || keyCode === main.KEY.k
                    || keyCode === main.KEY.n6)
            {
                startDeactivteQuickSidebar();
            }
        }

        public static function setSidebarDefaultPos():void
        {
            const main:Main = Main._instance;

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
            const main:Main = Main._instance;
            isQuickSidebarActive = true;

            if (shortcut)
            {
                if (!main.isFillPenStarted)
                {
                    main.selectLastUsedTool();
                }

                main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpQuickSidebar);
            }
            else
            {
                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownQuickSidebar, false, -2);
            }

            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownQuickSidebar, false, -2);

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

            if (MainUI.mouseHint.isShowing())
            {
                MainUI.hideMouseHint();
            }

            if (MainUI.isBottomBarVisible())
            {
                MainUI.hideBottomHint();
            }

            if (main.selectedToolViewBitmap.visible)
            {
                main.selectedToolViewBitmap.visible = false;
            }

            sideBar.setTransparentBG();
            sideBar.visible = true;

            checkFOFOPosition();
        }

        public static function isPressingQuickSidebarShortcut(key1:int, key2:int):Boolean
        {
            const main:Main = Main._instance;

            if ((key1 === main.KEY.s && key2 === main.KEY.d)
                    || (key1 === main.KEY.d && key2 === main.KEY.s)
                    || (key1 === main.KEY.j && key2 === main.KEY.k)
                    || (key1 === main.KEY.k && key2 === main.KEY.j))
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

        public static function addSidebarTempShowActivateEvents():void
        {
            const main:Main = Main._instance;
            isReactivateSidebarTempShowEventsAdded = true;

            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownReactivateSidebarTempShow);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onMouseDownReactivateSidebarTempShow);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpReactivateSidebarTempShow);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpReactivateSidebarTempShow);
        }

        public static function setSideBarClickEvents():void
        {
            const main:Main = Main._instance;
            isSidebarHideEventAdded = true;

            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownHideSidebar, false, -1);
        }

        public static function removeSidebarTempShowActivateEvents():void
        {
            const main:Main = Main._instance;

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

        public static function onMouseDownReactivateSidebarTempShow(e:MouseEvent):void
        {
            const main:Main = Main._instance;

            if (sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
            {
                removeSidebarTempShowActivateEvents();
            }
        }

        public static function startTimerActivateSidebarShowTemp():void
        {
            isSidebarTempShowDeactivated = true;

            FOFOTimer.addByName("sidebarTempShowActivateTimer", 0.7, false, function():void
                {
                    isReactivateSidebarTempShowEventsAdded = false;
                    isSidebarTempShowDeactivated = false;
                    removeSidebarTempShowActivateEvents();
                });
        }

        public static function onMouseUpReactivateSidebarTempShow(e:MouseEvent):void
        {
            const main:Main = Main._instance;

            if (!(main.isRightMouseClicked && main.isMouseClicked))
            {
                startTimerActivateSidebarShowTemp();
            }
        }

        public static function sidebarOFFRightMouseDownEvent(e:MouseEvent):void
        {
            const main:Main = Main._instance;

            main.isMouseClickBlocked = true;
            main.unblockMouseClickAfterDelay();

            startHidingSidebarTemporary();
        }

        public static function onMouseDownHideSidebar(e:MouseEvent):void
        {
            const main:Main = Main._instance;

            if (e.target && (e.target.name === "sideBarONButton" || e.target.name === "sideBarONButton2" || e.target.name === "fofo"))
            {
                // do nothing
            }
            else if (sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
            {
                startHidingSidebarTemporary();
            }
        }

        public static function startShowSideBarTemporary():void
        {
            const main:Main = Main._instance;

            if (!(main.isMouseClicked || main.isRightMouseClicked || main.isMouseDragging))
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

        public static function canShowSidebarTemporarily():Boolean
        {
            const main:Main = Main._instance;

            return !sideBar.visible
                && !main.isReplayModeON
                && !main.isCaptureModeON
                && !main.isToolBox2Showing
                && !main.isMouseClickBlocked
                && !MainUIController.resizeButtonR.visible;
        }

        public static function onMouseLeaveSideBar(e:Event):void
        {
            const main:Main = Main._instance;

            if (canShowSidebarTemporarily())
            {
                const sideBarWidth:Number = sideBar.getWidth();

                if (((isRightSidebar && main.stage.mouseX > main.stage.stageWidth - sideBarWidth)
                            || (!isRightSidebar && main.stage.mouseX < sideBarWidth))
                        && main.mouseY > MainUIController.STAGE_TOP_OFFSET)
                {
                    startShowSideBarTemporary();
                }
            }
        }

        public static function onMouseMoveSideBar(e:MouseEvent):void
        {
            const main:Main = Main._instance;

            if (canShowSidebarTemporarily())
            {
                const mx:Number = main.stage.mouseX;
                const my:Number = main.stage.mouseY;

                if ((!isRightSidebar && mx <= 15 || isRightSidebar && mx >= main.stage.stageWidth - 15) && my > MainUIController.STAGE_TOP_OFFSET)
                {
                    startShowSideBarTemporary();
                }
            }

            if (!isSidebarVisible && sideBar.visible)
            {
                if (main.isCursorInDrawArea())
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

        public static function onMouseUpSideBar(e:MouseEvent):void
        {
            const main:Main = Main._instance;

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

        public static function updateSidebarLayout():void
        {
            const main:Main = Main._instance;

            MainUIController.updateStageOffset();
            MainUIController.updateCanvasNaigatorCursor();

            checkFOFOPosition();

            if (main.selectedToolViewBitmap.visible)
            {
                main.updateSelectedToolViewBoxPos();
            }
        }

        public static function showSidebarPermanent():void
        {
            const main:Main = Main._instance;

            isSidebarVisible = true;
            sideBar.visible = true;

            MainUI.topBar.checkSideBarONOFFButton(true, isRightSidebar);

            updateSidebarLayout();

            MainUI.hideBottomHint();

            main.recordLassoAndRefLayerBoxLastPos();

            sideBar.resetBG();

            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpSideBar);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpSideBar);
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveSideBar);
            main.stage.removeEventListener(Event.MOUSE_LEAVE, onMouseLeaveSideBar);
        }

        public static function hideSidebarPermanent():void
        {
            const main:Main = Main._instance;

            isSidebarVisible = false;
            sideBar.visible = false;

            MainUI.topBar.checkSideBarONOFFButton(false, isRightSidebar);

            updateSidebarLayout();

            MainUI.hideBottomHint();

            main.restoreLassoAndRefLayerBoxLastPos();

            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpSideBar);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpSideBar);
            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveSideBar);
            main.stage.addEventListener(Event.MOUSE_LEAVE, onMouseLeaveSideBar);
        }

        public static function showSidebarTemporary():void
        {
            const main:Main = Main._instance;

            sideBar.visible = true;

            updateSidebarLayout();

            main.recordLassoAndRefLayerBoxLastPos();

            sideBar.setTransparentBG();
        }

        public static function hideSidebarTemporary():void
        {
            const main:Main = Main._instance;

            sideBar.visible = false;

            updateSidebarLayout();

            main.restoreLassoAndRefLayerBoxLastPos();
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
            const main:Main = Main._instance;

            // direction: "left" or "right"
            const isRight:Boolean = (direction === "right");

            setSidebarDefaultPos();

            MainUIController.updateStageOffset();

            sideBarScrollPanel.x = isRight ? 9 : 5;
            sideBarScrollPanel.y = scrollSetMovedY;

            main.canvasNavigatorBox.x = isRight ? -4 : 0;
            main.canvasNavigatorBox.y = 0;

            main.canvasInfoBox.setWidth(main.canvasNavigatorBox.BOX_WIDTH);
            main.canvasInfoBox.x = main.canvasNavigatorBox.x - 2;
            main.canvasInfoBox.y = Math.floor(main.canvasNavigatorBox.y + main.canvasNavigatorBox.BOX_HEIGHT + 6);

            main.toolOptionsBox.x = isRight ? 39 : 0;
            main.toolOptionsBox.y = Math.floor(main.canvasInfoBox.y + main.canvasInfoBox.height + 7);

            main.colorPickerBox.x = main.toolOptionsBox.x;
            main.colorPickerBox.y = Math.floor(main.toolOptionsBox.y + main.toolOptionsBox.height + 10);

            main.toolBox.x = isRight ? -2 : 177;
            main.toolBox.y = Math.floor(main.toolOptionsBox.y + 1);

            if (!isRight && main.toolBox.getDeafultY() === 0)
            {
                main.toolBox.setDeafultY(main.toolBox.y);
            }

            resetScrollBarX();

            sideBar.y = MainUI.topBar.BARSIZE * MainUI.topBar.scaleX;

            if (!ignoreCheckStageOffset)
            {
                if (isRight)
                {
                    main.canvasAnchorPoint.x -= MainUIController.STAGE_RIGHT_OFFSET;
                }
                else
                {
                    main.canvasAnchorPoint.x += MainUIController.STAGE_LEFT_OFFSET;
                }
            }

            if (sideBar.visible)
            {
                MainUI.topBar.sideBarOFFButton.visible = isRight;
                MainUI.topBar.sideBarOFFButton2.visible = !isRight;
            }
            else
            {
                MainUI.topBar.sideBarONButton.visible = isRight;
                MainUI.topBar.sideBarONButton2.visible = !isRight;
            }

            MainUI.topBar.sideBarPositionButton.visible = !isRight;
            MainUI.topBar.sideBarPositionButton2.visible = isRight;

            checkFOFOPosition();

            if (main.isLassoToolStarted)
            {
                MainUIController.keepBoxInsideViewPort(main.lassoMenuBox);
            }

            if (ReferenceLayerController.isRefLayerMenuON)
            {
                MainUIController.keepBoxInsideViewPort(ReferenceLayerController.refLayerMenuBox);
            }

            MainUI.hideBottomHint();
        }

        public static function updateScrollBarColorAndHeight():void
        {
            const main:Main = Main._instance;

            const scale:Number = Global.getUIScale();
            const topBarHeight:Number = Math.round(MainUI.topBar.BARSIZE * scale);
            const height:Number = Math.round((main.stage.stageHeight - topBarHeight - MainUIController.STAGE_BOTTOM_OFFSET) / scale);

            const color1:uint = Global.getUIFGColor();
            const color2:uint = Global.getUIBGColor();

            sideBarScrollBar.graphics.clear();
            sideBarScrollBar.graphics.lineStyle(2, color1, 1.0, true);
            sideBarScrollBar.graphics.beginFill(color2);
            sideBarScrollBar.graphics.drawRect(0, 1, SCROLL_BAR_WIDTH, height - 2);
            sideBarScrollBar.graphics.endFill();

            scrollBarHeight = height;
        }

        public static function resetScrollBarX():void
        {
            const main:Main = Main._instance;

            if (sideBarScrollBar.visible === false)
            {
                sideBarScrollBar.x = 0;
            }
            else if (isRightSidebar)
            {
                sideBarScrollBar.x = main.canvasNavigatorBox.x - sideBarScrollBar.width + 4;
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
            const main:Main = Main._instance;

            return (main.stage.stageHeight - MainUI.topBar.BARSIZE * Global.getUIScale()) / Global.getUIScale();
        }

        public static function keepScrollSetInStage():void
        {
            const main:Main = Main._instance;

            const scale:Number = Global.getUIScale();
            const limitTop:Number = Math.floor(-sideBarConstHeight + 20.0);
            const limitBottom:Number = Math.floor(main.stage.stageHeight - MainUIController.STAGE_TOP_OFFSET - MainUIController.STAGE_BOTTOM_OFFSET - 20.0 * scale);

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
            const main:Main = Main._instance;

            const scale:Number = Global.getUIScale();
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
            deltaY = Math.floor(deltaY * Global.getUIScale());

            sideBarScrollPanel.y += deltaY * 1.5;
            scrollSetMovedY = sideBarScrollPanel.y;

            checkFOFOPosition();

            if (MainUI.bottomBar.visible)
            {
                MainUI.hideBottomHint();
            }
        }

        public static function handleSidebarMouseDown(target:DisplayObject):Boolean
        {
            const main:Main = Main._instance;
            const targetName:String = target.name;

            if (sideBarScrollPanel.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
            {
                if (targetName === "navStageBG"
                        || targetName === "navBitmapBG"
                        || targetName === "navLayer1Bitmap"
                        || targetName === "navLayer2Bitmap")
                {
                    main.startCanvasMoveByCanvasNavigator(false);
                    return true;
                }
                else if (targetName === "navCursor")
                {
                    main.startCanvasMoveByCanvasNavigator(true);
                    return true;
                }
                else if (main.handleColorPickerBoxMouseDown(target) && !main.isKeyPressed())
                {
                    return true;
                }
                else if (main.handlePenOptionsBoxMouseDown(target) && (main.isSelectedToolPenOrLine() || main.isSelectedTool(main.TOOL_ERASER)))
                {
                    return true;
                }
                else if (main.toolBox.alpha === 1.0 && target.alpha === 1.0 && main.handleToolBoxMouseDown(target))
                {
                    return true;
                }
            }
            else if (isSidebarVisible === false)
            {
                if (sideBar.visible && !sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY) && main.isCursorInDrawArea())
                {
                    startHidingSidebarTemporary();
                    return true;
                }
            }

            return false;
        }
    }
}
