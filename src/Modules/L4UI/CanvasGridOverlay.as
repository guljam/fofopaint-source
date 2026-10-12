package Modules.L4UI
{
    import Modules.L1Data.AppContext;
    import flash.display.Shape;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import Modules.L1Data.KeyState;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L1Data.MouseState;
    import Modules.L1Data.Utils;
    import Modules.L1Data.InputPriority;
    import Modules.L1Data.UIEngine.UITheme;

    // 층: L4 UI - 캔버스 격자 표시와 격자 간격 조절
    public class CanvasGridOverlay
    {
        // 드로우 모드의 입력 이벤트를 다시 달아야 한다는 보고
        public static var onDrawEventsAddedFunc:Function;
        // 드로우 모드의 입력 이벤트를 빼야 한다는 보고
        public static var onDrawEventsRemovedFunc:Function;

        // 격자 간격 1단계당 캔버스 px
        public static const GRID_GAP:uint = 10;
        private static const GRID_NORMAL_COLOR:uint = 0x808080;
        // 간격 슬라이더가 나누는 단계 수 (0단계 = 격자 끔)
        private static const GRID_SLIDER_STEP_COUNT:Number = 20;

        public static const canvasGrid:Shape = new Shape();
        // drawPath에 넘기는 격자 선 명령/좌표. 간격이나 이동량이 바뀔 때만 다시 만듦
        private static var gridGraphicsCommands:Vector.<int> = new Vector.<int>();
        private static var gridGraphicsData:Vector.<Number> = new Vector.<Number>();

        // 격자 간격 단계 (0이면 격자 꺼짐, 1단계 = GRID_GAP px)
        public static var gridGapMultiplier:uint = 0;
        // 마지막으로 선 경로를 만든 격자 간격 px. 0으로 두면 다음 drawGrid에서 경로를 다시 만듦
        private static var lastDrawnGridGapPixels:Number = 0.0;
        // 격자를 캔버스 안에서 옮긴 거리 (이동 버튼으로 조절)
        public static var gridDrawOffsetX:Number = 0.0;
        public static var gridDrawOffsetY:Number = 0.0;

        // 간격 슬라이더에서 커서가 움직일 수 있는 왼쪽/오른쪽 끝 x (슬라이더 래퍼 좌표)
        private static var gridSliderMinX:Number = 0.0;
        private static var gridSliderMaxX:Number = 0.0;
        // 간격 1단계에 해당하는 슬라이더 가로 px
        private static var gridSliderPixelsPerStep:Number = 0.0;
        // 슬라이더 조작 직전의 간격 단계. 단계가 실제로 바뀌었는지 비교하고 이동량 비율을 맞출 때 씀
        private static var previousGridGapMultiplier:Number;
        // 이동 버튼을 누르고 있는 동안 키 반복마다 더할 이동량
        private static var gridOffsetRepeatMoveX:Number = 0.0;
        private static var gridOffsetRepeatMoveY:Number = 0.0;

        // 상단바가 만들어진 뒤 한 번 호출함. 슬라이더 범위를 상단바 슬라이더 크기에서 계산함
        public static function initialize():void
        {
            gridSliderMinX = UIController.topBar.gridSlider.x + 1.5;
            gridSliderMaxX = gridSliderMinX + UIController.topBar.gridSlider.width - 2.5;
            gridSliderPixelsPerStep = (gridSliderMaxX - gridSliderMinX) / GRID_SLIDER_STEP_COUNT;
        }

        // 격자를 끄고 간격 단계와 슬라이더 커서를 0으로 돌림
        public static function resetGrid():void
        {
            lastDrawnGridGapPixels = 0;
            gridGapMultiplier = 0;
            setGridSliderCursorByGapMultiplier(0);
            clearGrid();
        }

        // 격자 그림을 지우고 숨김. 이동 버튼은 꺼진 모양으로 바꿈
        private static function clearGrid():void
        {
            lastDrawnGridGapPixels = 0;
            UIController.topBar.setGridMoveButtonAlpha(UITheme.OFFALPHA);
            canvasGrid.visible = false;
            canvasGrid.graphics.clear();
        }

        // 현재 간격 단계, 이동량, 캔버스 배율에 맞춰 격자를 다시 그림 (단계가 0이면 지움)
        public static function drawGrid():void
        {
            if (gridGapMultiplier === 0)
            {
                clearGrid();
                return;
            }

            // 축소해서 선이 너무 촘촘해지면 화면 기준 간격이 유지되게 캔버스 간격을 넓힘
            var gridGapPixels:Number = gridGapMultiplier * GRID_GAP;
            if (gridGapPixels * CanvasView.canvasZoomMultiplier < gridGapPixels)
            {
                gridGapPixels = gridGapPixels / CanvasView.canvasZoomMultiplier;
            }

            if (gridGapPixels !== lastDrawnGridGapPixels)
            {
                lastDrawnGridGapPixels = gridGapPixels;
                rebuildGridPath(gridGapPixels);
            }

            canvasGrid.graphics.clear();
            canvasGrid.graphics.lineStyle(1 / CanvasView.canvasZoomMultiplier, GRID_NORMAL_COLOR, 0.5, false);
            canvasGrid.graphics.drawPath(gridGraphicsCommands, gridGraphicsData);

            updateGridMirror(DrawCanvas.mirrorON);
            canvasGrid.cacheAsBitmap = true;
            canvasGrid.visible = true;
        }

        // 가로선 전체, 세로선 전체 순서로 캔버스를 덮는 선 경로(moveTo + lineTo 쌍)를 만듦
        private static function rebuildGridPath(gridGapPixels:Number):void
        {
            const canvasWidth:Number = DrawCanvas.CANVAS_WIDTH;
            const canvasHeight:Number = DrawCanvas.CANVAS_HEIGHT;
            const offsetX:Number = gridDrawOffsetX;
            const offsetY:Number = gridDrawOffsetY;

            // 이동량이 0이면 0번째 선(캔버스 가장자리)은 건너뛰고, 양수면 0번째부터, 음수면 한 줄 더 그림
            var lineIndex:uint = 1;
            var lastLineIndex:Number = Math.floor(canvasHeight / gridGapPixels + 0.5);

            if (offsetY < 0)
                lastLineIndex += 1;
            else if (offsetY > 0)
                lineIndex = 0;

            gridGraphicsCommands = new Vector.<int>();
            gridGraphicsData = new Vector.<Number>();

            for (; lineIndex <= lastLineIndex; lineIndex++)
            {
                gridGraphicsCommands.push(1);
                gridGraphicsCommands.push(2);
                gridGraphicsData.push(0);
                gridGraphicsData.push(gridGapPixels * lineIndex + offsetY);
                gridGraphicsData.push(canvasWidth);
                gridGraphicsData.push(gridGapPixels * lineIndex + offsetY);
            }

            lineIndex = 1;
            lastLineIndex = Math.floor(canvasWidth / gridGapPixels + 0.5);

            if (offsetX < 0)
                lastLineIndex += 1;
            else if (offsetX > 0)
                lineIndex = 0;

            for (; lineIndex <= lastLineIndex; lineIndex++)
            {
                gridGraphicsCommands.push(1);
                gridGraphicsCommands.push(2);
                gridGraphicsData.push(gridGapPixels * lineIndex + offsetX);
                gridGraphicsData.push(0);
                gridGraphicsData.push(gridGapPixels * lineIndex + offsetX);
                gridGraphicsData.push(canvasHeight);
            }
        }

        // 거울(좌우반전) 상태에 맞춰 격자도 뒤집음
        public static function updateGridMirror(mirrorflag:Boolean):void
        {
            if (mirrorflag)
            {
                canvasGrid.scaleX = -1.0;
                canvasGrid.x = DrawCanvas.CANVAS_WIDTH;
            }
            else
            {
                canvasGrid.scaleX = 1;
                canvasGrid.x = 0;
            }
        }

        // ---- 격자 조절 모드: 간격 슬라이더와 이동 버튼 ----

        // 격자 버튼을 눌렀을 때(또는 단축키) 조절 모드를 켜고, 이미 켜져 있으면 끔
        // shortcutKey가 true면 슬라이더를 마우스 위치로 옮겨서 띄움
        public static function toggleGridAdjustMode(shortcutKey:Boolean):void
        {
            if (UIController.topBar.gridButtonWrapper.visible === false)
            {
                if (onDrawEventsRemovedFunc != null) onDrawEventsRemovedFunc();
                UIController.topBar.setGridMoveButtonAlpha(gridGapMultiplier > 0 ? 1.0 : UITheme.OFFALPHA);
                UIController.topBar.setReplaySpeedBarToGridSliderON(shortcutKey);
                setGridSliderCursorByGapMultiplier(gridGapMultiplier);

                if (shortcutKey)
                {
                    const mouseLocalPos:Point = UIController.topBar.globalToLocal(new Point(AppContext.stage.mouseX, AppContext.stage.mouseY));
                    UIController.topBar.gridButtonWrapper.x = mouseLocalPos.x - UIController.topBar.gridSliderWrapper.x - UIController.topBar.gridSliderCursor.x;
                    UIController.topBar.gridButtonWrapper.y = mouseLocalPos.y - UIController.topBar.gridSliderWrapper.y - UIController.topBar.gridSliderCursor.y;
                }

                AppContext.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownGridAdjustMode, false, InputPriority.MODE);
                AppContext.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownGridAdjustMode, false, InputPriority.MODE);
                AppContext.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpGridAdjustMode, false, InputPriority.MODE);
            }
            else
            {
                endGridAdjustMode();
            }
        }

        // 조절 모드를 끝내고 리스너, 키 반복, 힌트를 정리한 뒤 드로우 모드 입력을 되살림
        private static function endGridAdjustMode():void
        {
            HintController.hideBottomHint();
            MouseState.endDrag("gridSlider");
            KeyState.removeKeyRepeatEvents(null);
            AppContext.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownGridAdjustMode);
            AppContext.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpGridSlider);
            AppContext.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownGridAdjustMode);
            AppContext.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveGridSlider);
            AppContext.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpGridAdjustMode);
            UIController.topBar.setReplaySpeedBarToGridSliderOFF(AppContext.stage);
            KeyState.clearKeyBuffer();
            if (onDrawEventsAddedFunc != null) onDrawEventsAddedFunc();
        }

        // 간격 단계에 해당하는 위치로 슬라이더 커서를 옮김
        private static function setGridSliderCursorByGapMultiplier(gapMultiplier:Number):void
        {
            UIController.topBar.gridSliderCursor.x = gapMultiplier * gridSliderPixelsPerStep + gridSliderMinX;
        }

        // 슬라이더 위 마우스 x를 간격 단계로 바꿔 적용함. 단계가 그대로면 무시하되 forceApply면 다시 적용함
        // 0단계는 격자 끄기, 1단계 이상은 이동량을 단계 비율만큼 늘이거나 줄여서 격자 위치를 유지함
        private static function applyGridGapMultiplierFromSliderX(sliderMouseX:Number, forceApply:Boolean):void
        {
            if (sliderMouseX < gridSliderMinX)
            {
                sliderMouseX = gridSliderMinX;
            }
            else if (sliderMouseX > gridSliderMaxX)
            {
                sliderMouseX = gridSliderMaxX;
            }

            const newGapMultiplier:Number = Math.floor((sliderMouseX - gridSliderMinX) / gridSliderPixelsPerStep);

            if (previousGridGapMultiplier !== newGapMultiplier || forceApply)
            {
                setGridSliderCursorByGapMultiplier(newGapMultiplier);

                if (newGapMultiplier === 0)
                {
                    gridGapMultiplier = 0;
                    previousGridGapMultiplier = 0;
                    HintController.hideBottomHint();
                    clearGrid();
                    return;
                }
                else
                {
                    if (UIController.topBar.isGridMoveButtonOFFAlpha())
                        UIController.topBar.setGridMoveButtonAlpha(1.0);

                    if (previousGridGapMultiplier > 0 && newGapMultiplier > 0)
                    {
                        gridDrawOffsetX = gridDrawOffsetX * (newGapMultiplier / previousGridGapMultiplier);
                        gridDrawOffsetY = gridDrawOffsetY * (newGapMultiplier / previousGridGapMultiplier);
                    }

                    gridGapMultiplier = newGapMultiplier;
                    previousGridGapMultiplier = newGapMultiplier;
                    HintController.showMouseHintTemp(HintStrings.getGridGapAdjustHintString(newGapMultiplier, GRID_GAP));
                    drawGrid();
                }
            }

            Utils.setAsTopChild(canvasGrid);
        }

        // 슬라이더 드래그를 끝내고 드래그용 리스너를 뺌 (조절 모드는 계속 유지)
        private static function onMouseUpGridSlider(e:MouseEvent):void
        {
            MouseState.endDrag("gridSlider");
            AppContext.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpGridSlider);
            AppContext.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveGridSlider);
        }

        // MouseState가 포커스 상실 등으로 슬라이더 드래그를 강제로 끝낼 때 부름
        private static function onGridSliderDragForceEnded():void
        {
            onMouseUpGridSlider(null);
        }

        // 슬라이더를 드래그하는 동안 마우스 위치로 간격 단계를 바꾸고 힌트를 보여줌
        private static function onMouseMoveGridSlider(e:MouseEvent):void
        {
            applyGridGapMultiplierFromSliderX(UIController.topBar.gridSliderWrapper.mouseX, false);
            HintController.showBottomHint(HintStrings.getHintFromTargetName("gridSliderWrapper"));
        }

        // 이동 버튼을 누르고 있는 동안 키 반복마다 격자를 (moveX, moveY)만큼 옮김. 거울 상태면 x는 반대로 옮김
        private static function startGridOffsetKeyRepeat(moveX:Number, moveY:Number):void
        {
            gridOffsetRepeatMoveX = moveX;
            gridOffsetRepeatMoveY = moveY;
            KeyState.startKeyRepeat(true, onGridOffsetKeyRepeat);
        }

        // 키 반복 1회분: 이동량을 더하고 한 칸 이상 밀렸으면 0으로 돌려서 다시 그림
        private static function onGridOffsetKeyRepeat():void
        {
            gridDrawOffsetX += gridOffsetRepeatMoveX * (DrawCanvas.mirrorON ? -1 : 1);
            gridDrawOffsetY += gridOffsetRepeatMoveY;

            if (Math.abs(gridDrawOffsetX) >= gridGapMultiplier * GRID_GAP)
                gridDrawOffsetX = 0.0;
            if (Math.abs(gridDrawOffsetY) >= gridGapMultiplier * GRID_GAP)
                gridDrawOffsetY = 0.0;

            lastDrawnGridGapPixels = 0;
            if (gridGapMultiplier > 0)
                drawGrid();
        }

        // 조절 모드 중 왼쪽 클릭: 격자 버튼/바깥이면 모드 끝, 이동 버튼이면 이동 반복, 슬라이더면 드래그 시작
        private static function onMouseDownGridAdjustMode(e:MouseEvent):void
        {
            if (!e.target)
                return;
            const targetName:String = e.target.name;

            if (targetName === "gridButton" || UIController.topBar.gridButtonWrapper.hitTestPoint(AppContext.stage.mouseX, AppContext.stage.mouseY) === false)
            {
                endGridAdjustMode();
                return;
            }

            if (UIController.topBar.gridMoveButtonWrapper.hitTestPoint(AppContext.stage.mouseX, AppContext.stage.mouseY))
            {
                // 이동 버튼은 격자가 켜져 있을 때(alpha 1.0)만 동작함
                if (e.target.alpha === 1.0)
                {
                    var moveDirection:Point;

                    // 캔버스가 회전해 있어도 화면 기준 방향으로 움직이도록 회전을 반영함
                    if (targetName === "gridMoveLeftButton")
                        moveDirection = Utils.rotatePoint(-1, 0, CanvasView.canvasAnchorPoint.rotation);
                    else if (targetName === "gridMoveRightButton")
                        moveDirection = Utils.rotatePoint(1, 0, CanvasView.canvasAnchorPoint.rotation);
                    else if (targetName === "gridMoveUpButton")
                        moveDirection = Utils.rotatePoint(0, -1, CanvasView.canvasAnchorPoint.rotation);
                    else if (targetName === "gridMoveDownButton")
                        moveDirection = Utils.rotatePoint(0, 1, CanvasView.canvasAnchorPoint.rotation);

                    if (moveDirection !== null)
                        startGridOffsetKeyRepeat(moveDirection.x, moveDirection.y);
                }
            }
            else if (UIController.topBar.gridSliderWrapper.hitTestPoint(AppContext.stage.mouseX, AppContext.stage.mouseY))
            {
                previousGridGapMultiplier = gridGapMultiplier;
                applyGridGapMultiplierFromSliderX(UIController.topBar.gridSliderWrapper.mouseX, true);
                AppContext.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveGridSlider);
                AppContext.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpGridSlider, false, InputPriority.DEFAULT);
                MouseState.beginDrag("gridSlider", onGridSliderDragForceEnded);
            }
        }

        // 조절 모드 중 F2/F8을 뗌: 드래그 중이 아니면 shift+키는 격자 끄기, 그냥 키는 조절 모드 끝
        private static function onKeyUpGridAdjustMode(e:KeyboardEvent):void
        {
            if (e.keyCode === KeyState.KEY.f2 || e.keyCode === KeyState.KEY.f8)
            {
                if (!(MouseState.isLeftDown || MouseState.isDragging))
                {
                    if (KeyState.isPressingShift())
                    {
                        if (gridGapMultiplier !== 0)
                        {
                            HintController.hideBottomHint();
                            previousGridGapMultiplier = 0;
                            resetGrid();
                        }
                    }
                    else
                    {
                        endGridAdjustMode();
                    }
                }
            }
        }

        // 조절 모드 중 오른쪽 클릭: 좌우 이동 버튼은 x 이동량, 상하 이동 버튼은 y 이동량, 슬라이더는 격자 끄기, 그 외는 모드 끝
        private static function onRightMouseDownGridAdjustMode(e:MouseEvent):void
        {
            if (!e.target)
                return;

            const targetName:String = e.target.name;

            if (targetName === "gridMoveLeftButton" || targetName === "gridMoveRightButton")
            {
                if (gridGapMultiplier > 0)
                {
                    gridDrawOffsetX = 0.0;
                    lastDrawnGridGapPixels = 0.0;
                    drawGrid();
                }
            }
            else if (targetName === "gridMoveUpButton" || targetName === "gridMoveDownButton")
            {
                if (gridGapMultiplier > 0)
                {
                    gridDrawOffsetY = 0.0;
                    lastDrawnGridGapPixels = 0.0;
                    drawGrid();
                }
            }
            else if (targetName === "gridSliderWrapper")
            {
                if (gridGapMultiplier !== 0)
                {
                    HintController.hideBottomHint();
                    resetGrid();
                }
            }
            else
            {
                endGridAdjustMode();
            }
        }
    }
}
