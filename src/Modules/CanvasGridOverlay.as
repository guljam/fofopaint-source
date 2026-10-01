package Modules
{
    import Modules.DrawEngine.CanvasView;
    import Modules.DrawEngine.DrawCanvas;
    import Modules.InputManager.InputManager;
    import Modules.InputManager.DrawModeInput;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;
    import Modules.UIEngine.UITheme;
    import flash.display.Shape;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Point;

    public class CanvasGridOverlay
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
            initialize();
        }

        public static const GRID_GAP:uint = 10;
        private static const GRID_NORMAL_COLOR:uint = 0x808080;

        public static const canvasGrid:Shape = new Shape();
        private static var gridGraphicsCommands:Vector.<int> = new Vector.<int>();
        private static var gridGraphicsData:Vector.<Number> = new Vector.<Number>();

        public static var gridGapMultiplier:uint = 0;
        private static var lastGridGapValue:Number = 0.0;
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

        private static function clearGrid():void
        {
            lastGridGapValue = 0;
            UIController.topBar.setGridMoveButtonAlpha(UITheme.OFFALPHA);
            canvasGrid.visible = false;
            canvasGrid.graphics.clear();
        }

        public static function drawGrid():void
        {
            if (gridGapMultiplier === 0)
            {
                clearGrid();
                return;
            }

            var gridgap:Number = gridGapMultiplier * GRID_GAP;
            if (gridgap * CanvasView.canvasZoomMultiplier < gridgap)
            {
                gridgap = gridgap / CanvasView.canvasZoomMultiplier;
            }

            if (gridgap !== lastGridGapValue)
            {
                lastGridGapValue = gridgap;

                const gridWidth:Number = DrawCanvas.CANVAS_WIDTH;
                const gridHeight:Number = DrawCanvas.CANVAS_HEIGHT;
                const offsetX:Number = gridDrawOffsetX;
                const offsetY:Number = gridDrawOffsetY;

                var i:uint = 1;
                var len:Number = Math.floor(gridHeight / gridgap + 0.5);

                if (offsetY < 0)
                    len += 1;
                else if (offsetY > 0)
                    i = 0;

                gridGraphicsCommands = new Vector.<int>();
                gridGraphicsData = new Vector.<Number>();

                for (;i <= len;i++)
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

                for (;i <= len;i++)
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
            canvasGrid.graphics.lineStyle(1 / CanvasView.canvasZoomMultiplier, GRID_NORMAL_COLOR, 0.5, false);
            canvasGrid.graphics.drawPath(gridGraphicsCommands, gridGraphicsData);

            updateGridMirror(DrawCanvas.mirrorON);
            canvasGrid.cacheAsBitmap = true;
            canvasGrid.visible = true;
        }

        private static function cGridFunc():Object
        {
            const minDist:Number = UIController.topBar.gridSlider.x + 1.5;
            const maxDist:Number = minDist + UIController.topBar.gridSlider.width - 2.5;
            const step:Number = 20;
            const div:Number = (maxDist - minDist) / step;
            var oldValue:Number;

            function setCursorPosByValue(value:Number):void
            {
                UIController.topBar.gridSliderCursor.x = value * div + minDist;
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
                        HintController.hideBottomHint();
                        clearGrid();
                        return;
                    }
                    else
                    {
                        if (UIController.topBar.isGridMoveButtonOFFAlpha())
                            UIController.topBar.setGridMoveButtonAlpha(1.0);

                        if (oldValue > 0 && value > 0)
                        {
                            gridDrawOffsetX = gridDrawOffsetX * (value / oldValue);
                            gridDrawOffsetY = gridDrawOffsetY * (value / oldValue);
                        }

                        gridGapMultiplier = value;
                        oldValue = value;
                        HintController.showMouseHintTemp(HintStrings.getGridGapAdjustHintString(value, GRID_GAP));
                        drawGrid();
                    }
                }

                Utils.setAsTopChild(canvasGrid);
            }

            function onMouseUpGridButton(e:MouseEvent):void
            {
                MouseState.endDrag("gridSlider");
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpGridButton);
                main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveGridButton);
            }

            function onMouseMoveGridButton(e:MouseEvent):void
            {
                var mx:Number = UIController.topBar.gridSliderWrapper.mouseX;

                if (mx < minDist)
                {
                    mx = minDist;
                }
                else if (mx > maxDist)
                {
                    mx = maxDist;
                }

                drawGridByValue(mx, false);
                HintController.showBottomHint(HintStrings.getHintFromTargetName("gridSliderWrapper"));
            }

            function repeatGridMoveByValue(moveX:Number, moveY:Number):void
            {
                InputManager.startKeyRepeat(true, function ():void
                    {
                        gridDrawOffsetX += moveX * (DrawCanvas.mirrorON ? -1 : 1);
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

                if (targetName === "gridButton" || UIController.topBar.gridButtonWrapper.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
                {
                    off();
                    return;
                }

                if (UIController.topBar.gridMoveButtonWrapper.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                {
                    if (e.target.alpha === 1.0)
                    {
                        var p:Point;

                        if (targetName === "gridMoveLeftButton")
                            p = Utils.rotatePoint(-1, 0, CanvasView.canvasAnchorPoint.rotation);
                        else if (targetName === "gridMoveRightButton")
                            p = Utils.rotatePoint(1, 0, CanvasView.canvasAnchorPoint.rotation);
                        else if (targetName === "gridMoveUpButton")
                            p = Utils.rotatePoint(0, -1, CanvasView.canvasAnchorPoint.rotation);
                        else if (targetName === "gridMoveDownButton")
                            p = Utils.rotatePoint(0, 1, CanvasView.canvasAnchorPoint.rotation);

                        if (p !== null)
                            repeatGridMoveByValue(p.x, p.y);
                    }
                }
                else if (UIController.topBar.gridSliderWrapper.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                {
                    oldValue = gridGapMultiplier;
                    drawGridByValue(UIController.topBar.gridSliderWrapper.mouseX, true);
                    main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveGridButton);
                    main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpGridButton, false, InputPriority.DEFAULT);
                    MouseState.beginDrag("gridSlider", function ():void
                        {
                            onMouseUpGridButton(null);
                        });
                }
            }

            function onKeyUpGridButton(e:KeyboardEvent):void
            {
                if (e.keyCode === InputManager.KEY.f2 || e.keyCode === InputManager.KEY.f8)
                {
                    if (!(MouseState.isLeftDown || MouseState.isDragging))
                    {
                        if (InputManager.isPressingShift())
                        {
                            if (gridGapMultiplier !== 0)
                            {
                                HintController.hideBottomHint();
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
                        HintController.hideBottomHint();
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
                HintController.hideBottomHint();
                MouseState.endDrag("gridSlider");
                InputManager.removeKeyRepeatEvents(null);
                main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownGridButton);
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpGridButton);
                main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownGridButton);
                main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveGridButton);
                main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpGridButton);
                UIController.topBar.setReplaySpeedBarToGridSliderOFF(main.stage);
                InputManager.clearKeyBuffer();
                DrawModeInput.addEvents();
            }

            function start(shortcutKey:Boolean):void
            {
                if (UIController.topBar.gridButtonWrapper.visible === false)
                {
                    DrawModeInput.removeEvents();
                    UIController.topBar.setGridMoveButtonAlpha(gridGapMultiplier > 0 ? 1.0 : UITheme.OFFALPHA);
                    UIController.topBar.setReplaySpeedBarToGridSliderON(shortcutKey);
                    setCursorPosByValue(gridGapMultiplier);

                    if (shortcutKey)
                    {
                        const p:Point = UIController.topBar.globalToLocal(new Point(main.stage.mouseX, main.stage.mouseY));
                        UIController.topBar.gridButtonWrapper.x = p.x - UIController.topBar.gridSliderWrapper.x - UIController.topBar.gridSliderCursor.x;
                        UIController.topBar.gridButtonWrapper.y = p.y - UIController.topBar.gridSliderWrapper.y - UIController.topBar.gridSliderCursor.y;
                    }

                    main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownGridButton, false, InputPriority.MODE);
                    main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownGridButton, false, InputPriority.MODE);
                    main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpGridButton, false, InputPriority.MODE);
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
                canvasGrid.x = DrawCanvas.CANVAS_WIDTH;
            }
            else
            {
                canvasGrid.scaleX = 1;
                canvasGrid.x = 0;
            }
        }
    }
}
