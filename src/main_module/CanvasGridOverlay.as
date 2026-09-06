package main_module
{
    import flash.display.Shape;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Point;

    public class CanvasGridOverlay
    {
        public static const GRID_GAP:uint = 10;
        public static const GRID_NORMAL_COLOR:uint = 0x808080;

        public static const canvasGrid:Shape = new Shape();
        public static const gridGraphicsCommands:Vector.<int> = new Vector.<int>();
        public static const gridGraphicsData:Vector.<Number> = new Vector.<Number>();

        public static var gridGapMultiplier:uint = 0;
        public static var lastGridGapValue:Number = 0.0;
        public static var gridDrawOffsetX:Number = 0.0;
        public static var gridDrawOffsetY:Number = 0.0;
        public static var gridButton:Object;

        public static function initialize():void
        {
            if (gridButton === null)
            {
                gridButton = cGridFunc();
            }
        }

        public static function resetGrid():void
        {
            lastGridGapValue = 0;
            gridGapMultiplier = 0;
            gridButton.setCursorPosByValue(0);
            clearGrid();
        }

        public static function clearGrid():void
        {
            const main:Main = Main._instance;
            lastGridGapValue = 0;
            MainUI.topBar.setGridMoveButtonAlpha(Global.OFFALPHA);
            canvasGrid.visible = false;
            canvasGrid.graphics.clear();
        }

        public static function drawGrid():void
        {
            const main:Main = Main._instance;

            if (gridGapMultiplier === 0)
            {
                clearGrid();
                return;
            }

            var gridgap:Number = gridGapMultiplier * GRID_GAP;
            if (gridgap * main.canvasZoomMultipler < gridgap)
            {
                gridgap = gridgap / main.canvasZoomMultipler;
            }

            if (gridgap !== lastGridGapValue)
            {
                lastGridGapValue = gridgap;

                const gridWidth:Number = main.CANVAS_WIDTH;
                const gridHeight:Number = main.CANVAS_HEIGHT;
                const offsetX:Number = gridDrawOffsetX;
                const offsetY:Number = gridDrawOffsetY;

                var i:uint = 1;
                var len:Number = Math.floor(gridHeight / gridgap + 0.5);

                if (offsetY < 0)
                    len += 1;
                else if (offsetY > 0)
                    i = 0;

                gridGraphicsCommands.length = 0;
                gridGraphicsData.length = 0;

                for (; i <= len; i++)
                {
                    gridGraphicsCommands.push(1);
                    gridGraphicsCommands.push(2);
                    gridGraphicsData.push(0);
                    gridGraphicsData.push(gridgap * i + offsetY);
                    gridGraphicsData.push(gridWidth);
                    gridGraphicsData.push(gridgap * i + offsetY);
                }

                i = 1;
                len = Math.floor(gridWidth / gridgap + 0.5);

                if (offsetX < 0)
                    len += 1;
                else if (offsetX > 0)
                    i = 0;

                for (; i <= len; i++)
                {
                    gridGraphicsCommands.push(1);
                    gridGraphicsCommands.push(2);
                    gridGraphicsData.push(gridgap * i + offsetX);
                    gridGraphicsData.push(0);
                    gridGraphicsData.push(gridgap * i + offsetX);
                    gridGraphicsData.push(gridHeight);
                }
            }

            canvasGrid.graphics.clear();
            canvasGrid.graphics.lineStyle(1 / main.canvasZoomMultipler, GRID_NORMAL_COLOR, 0.5, false);
            canvasGrid.graphics.drawPath(gridGraphicsCommands, gridGraphicsData);

            updateGridMirror(main.isCanvasMirrored);
            canvasGrid.cacheAsBitmap = true;
            canvasGrid.visible = true;
        }

        public static function cGridFunc():Object
        {
            const main:Main = Main._instance;
            const minDist:Number = MainUI.topBar.gridSlider.x + 1.5;
            const maxDist:Number = minDist + MainUI.topBar.gridSlider.width - 2.5;
            const step:Number = 20;
            const div:Number = (maxDist - minDist) / step;
            var oldValue:Number;

            function setCursorPosByValue(value:Number):void
            {
                MainUI.topBar.gridSliderCursor.x = value * div + minDist;
            }

            function drawGridByValue(mx:Number, initFlag:Boolean):void
            {
                if (mx < minDist)
                {
                    mx = minDist;
                }
                else if (mx > maxDist)
                {
                    mx = maxDist;
                }

                const value:Number = Math.floor((mx - minDist) / div);

                if (oldValue !== value || initFlag)
                {
                    setCursorPosByValue(value);

                    if (value === 0)
                    {
                        gridGapMultiplier = 0;
                        oldValue = 0;
                        MainUI.hideBottomHint();
                        clearGrid();
                        return;
                    }
                    else
                    {
                        if (MainUI.topBar.isGridMoveButtonOFFAlpha())
                            MainUI.topBar.setGridMoveButtonAlpha(1.0);

                        if (oldValue > 0 && value > 0)
                        {
                            gridDrawOffsetX = gridDrawOffsetX * (value / oldValue);
                            gridDrawOffsetY = gridDrawOffsetY * (value / oldValue);
                        }

                        gridGapMultiplier = value;
                        oldValue = value;
                        MainUI.showMouseHintTemp(HintStrings.getGridGapAdjustHintString(value, GRID_GAP));
                        drawGrid();
                    }
                }

                Utils.setAsTopChild(canvasGrid);
            }

            function onMouseUpGridButton(e:MouseEvent):void
            {
                main.isMouseDragging = false;
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpGridButton);
                main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveGridButton);
            }

            function onMouseMoveGridButton(e:MouseEvent):void
            {
                var mx:Number = MainUI.topBar.gridSliderWrapper.mouseX;

                if (mx < minDist)
                {
                    mx = minDist;
                }
                else if (mx > maxDist)
                {
                    mx = maxDist;
                }

                drawGridByValue(mx, false);
                MainUI.showBottomHint(HintStrings.getHintFromTargetName("gridSliderWrapper"));
            }

            function repeatGridMoveByValue(moveX:Number, moveY:Number):void
            {
                main.startKeyRepeat(true, function():void
                    {
                        gridDrawOffsetX += moveX * (main.isCanvasMirrored ? -1 : 1);
                        gridDrawOffsetY += moveY;

                        if (Math.abs(gridDrawOffsetX) >= gridGapMultiplier * GRID_GAP)
                            gridDrawOffsetX = 0.0;
                        if (Math.abs(gridDrawOffsetY) >= gridGapMultiplier * GRID_GAP)
                            gridDrawOffsetY = 0.0;

                        lastGridGapValue = 0;
                        if (gridGapMultiplier > 0)
                            drawGrid();
                    });
            }

            function onMouseDownGridButton(e:MouseEvent):void
            {
                if (!e.target)
                    return;
                const targetName:String = e.target.name;

                if (targetName === "gridButton" || MainUI.topBar.gridButtonWrapper.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
                {
                    off();
                    return;
                }

                if (MainUI.topBar.gridMoveButtonWrapper.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                {
                    if (e.target.alpha === 1.0)
                    {
                        var p:Point;

                        if (targetName === "gridMoveLeftButton")
                            p = Utils.rotatePoint(-1, 0, main.canvasAnchorPoint.rotation);
                        else if (targetName === "gridMoveRightButton")
                            p = Utils.rotatePoint(1, 0, main.canvasAnchorPoint.rotation);
                        else if (targetName === "gridMoveUpButton")
                            p = Utils.rotatePoint(0, -1, main.canvasAnchorPoint.rotation);
                        else if (targetName === "gridMoveDownButton")
                            p = Utils.rotatePoint(0, 1, main.canvasAnchorPoint.rotation);

                        if (p !== null)
                            repeatGridMoveByValue(p.x, p.y);
                    }
                }
                else if (MainUI.topBar.gridSliderWrapper.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                {
                    main.isMouseDragging = true;
                    oldValue = gridGapMultiplier;
                    drawGridByValue(MainUI.topBar.gridSliderWrapper.mouseX, true);
                    main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveGridButton);
                    main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpGridButton);
                }
            }

            function onKeyUpGridButton(e:KeyboardEvent):void
            {
                if (e.keyCode === main.KEY.f2 || e.keyCode === main.KEY.f8)
                {
                    if (!(main.isMouseClicked || main.isMouseDragging))
                    {
                        if (main.isPressingShift())
                        {
                            if (gridGapMultiplier !== 0)
                            {
                                MainUI.hideBottomHint();
                                oldValue = 0;
                                resetGrid();
                            }
                        }
                        else
                        {
                            off();
                        }
                    }
                }
            }

            function onRightMouseDownGridButton(e:MouseEvent):void
            {
                if (!e.target)
                    return;

                const targetName:String = e.target.name;

                if (targetName === "gridMoveLeftButton" || targetName === "gridMoveRightButton")
                {
                    if (gridGapMultiplier > 0)
                    {
                        gridDrawOffsetX = 0.0;
                        lastGridGapValue = 0.0;
                        drawGrid();
                    }
                }
                else if (targetName === "gridMoveUpButton" || targetName === "gridMoveDownButton")
                {
                    if (gridGapMultiplier > 0)
                    {
                        gridDrawOffsetY = 0.0;
                        lastGridGapValue = 0.0;
                        drawGrid();
                    }
                }
                else if (targetName === "gridSliderWrapper")
                {
                    if (gridGapMultiplier !== 0)
                    {
                        MainUI.hideBottomHint();
                        resetGrid();
                    }
                }
                else
                {
                    off();
                }
            }

            function off():void
            {
                MainUI.hideBottomHint();
                main.isMouseDragging = false;
                main.removeKeyRepeatEvents(null);
                main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownGridButton);
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpGridButton);
                main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownGridButton);
                main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveGridButton);
                main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpGridButton);
                MainUI.topBar.setReplaySpeedBarToGridSliderOFF(main.stage);
                main.clearKeyBuffer();
                main.addInputEventsDrawMode();
            }

            function start(shortcutKey:Boolean):void
            {
                if (MainUI.topBar.gridButtonWrapper.visible === false)
                {
                    main.removeInputEventsDrawMode();
                    MainUI.topBar.setGridMoveButtonAlpha(gridGapMultiplier > 0 ? 1.0 : Global.OFFALPHA);
                    MainUI.topBar.setReplaySpeedBarToGridSliderON(shortcutKey);
                    setCursorPosByValue(gridGapMultiplier);

                    if (shortcutKey)
                    {
                        const p:Point = MainUI.topBar.globalToLocal(new Point(main.stage.mouseX, main.stage.mouseY));
                        MainUI.topBar.gridButtonWrapper.x = p.x - MainUI.topBar.gridSliderWrapper.x - MainUI.topBar.gridSliderCursor.x;
                        MainUI.topBar.gridButtonWrapper.y = p.y - MainUI.topBar.gridSliderWrapper.y - MainUI.topBar.gridSliderCursor.y;
                    }

                    main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownGridButton, false, -1);
                    main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownGridButton, false, -1);
                    main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpGridButton, false, -1);
                }
                else
                {
                    off();
                }
            }

            return {
                    start: start,
                    setCursorPosByValue: setCursorPosByValue
                };
        }

        public static function updateGridMirror(mirrorflag:Boolean):void
        {
            if (mirrorflag)
            {
                canvasGrid.scaleX = -1.0;
                canvasGrid.x = Main._instance.CANVAS_WIDTH;
            }
            else
            {
                canvasGrid.scaleX = 1;
                canvasGrid.x = 0;
            }
        }
    }
}
