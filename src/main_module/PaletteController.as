package main_module
{

    import main_module.SidebarController;
    import flash.events.MouseEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileStream;
    import flash.filesystem.FileMode;
    import flash.geom.Point;
    import main_module.tools.PenTool;
    import flash.display.Graphics;

    public final class PaletteController
    {
        public static const myPaletteDataFilePath:File = File.applicationStorageDirectory.resolvePath("mypalettedata");

        public static var isMyPaletteExpended:Boolean = false, // 전체로 보면 올려줌
            myPaletteColorBeforeAddColor:Array = [-1, 0], // index, hexcolor
            myPaletteColorLimit:int = 100,
            myPaletteColorWidth:Number = 17, // Math.floor(pickerBox.svBoxWidth/myPaletteLimit)//히스토리 개별 색깔 가로 크기
            myPaletteColorHeight:Number = 17,
            myPaletteClickPos:Point = new Point(), // 컬러 히스토리 클릭하면 위치 넣어줌
            myPaletteMovePos:Point = new Point(), // 컬러 히스토리 드래그할때 움직이는 포인트 넣어줌
            myPaletteDragClickedColor:uint = 0, // 드래그 준비 클릭한 컬러 저장해줌
            myPaletteDragClickedIndex:int = -1, // 드래그 준비 클릭한 컬러 인덱스 저장
            myPaletteDragStarted:Boolean = false, // 컬러 히스토리 드래그 시작하면 올려줌
            myPalettePresetType:int = 0, // 타입저정 0=mypalette, 1=drawr, 2=tegaki
            myPalettePreset:Array = [],
            myPaletteDrawrPreset:Array = [0xFFFFFF, 0xC0C0C0, 0xFF3B21, 0xFFBD16, 0xF5F30F, 0xA5E975, 0x71DBFD, 0xFA80F9, null, null,
                0x000000, 0x808080, 0x8E0000, 0xFFCC99, 0x877D30, 0x008F47, 0x313BCD, 0xC02E97, 0x3F037E, null],
            myPaletteTegakiPreset:Array = [0xA80515, 0xA80515, 0x800000, 0x800000, 0x4B3D38, 0x4B3D38, 0x313768, 0x313768, 0x394C44, 0x394C44,
                0xF1D0D0, 0xF1D0D0, 0xF1E1D7, 0xF1E1D7, 0xEAE5D5, 0xEAE5D5, 0xD5E9F3, 0xD5E9F3, 0xD0EBDE, 0xD0EBDE],
            myPaletteSaveColorBeforeOtherType:Array = [0, 0, 0xA80515]; // 다른 타입으로 바꾸기 전에 저장된 컬러

        public static function selectOrResetMyPalette():void
        {
            const main:Main = Main._instance;

            function onMouseUpMyPalette(e:MouseEvent):void
            {
                FOFOTimer.remove("selectMyPaletteDelayTimer");
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpMyPalette);

                if (e.target && e.target.name === "myPaletteButton")
                {
                    if (myPalettePresetType === 0)
                    {
                        if (isMyPaletteExpended === false)
                        {
                            switchMyPaletteToExpended();
                        }
                        else
                        {
                            switchMyPaletteToCompact();
                        }
                    }
                    else
                    {
                        ColorPickerController.activeColorPreset(0);
                    }
                }
            }
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpMyPalette);

            FOFOTimer.addByName("selectMyPaletteDelayTimer", 0.4, false, function():void
                {
                    main.startPressHoldKey(ColorPickerController.colorPickerBox.myPaletteButton, "Clearing my palette..", null, clearMyPaletteList, null);
                    main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpMyPalette);
                });
        }

        public static function startSelectOrAddColorMyPalette():void
        {
            const main:Main = Main._instance;

            const firstClickColorIndex:uint = getMyPaletteIndexByMousePos();
            var colorAddedFlag:Boolean = false;

            function onMyPaletteMouseUp(e:MouseEvent):void
            {
                FOFOTimer.remove("addColorMyPaletteDelayTimer");
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMyPaletteMouseUp);
                if (colorAddedFlag === false)
                {
                    selectMyPaletteColor();
                }
            }
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMyPaletteMouseUp);

            FOFOTimer.addByName("addColorMyPaletteDelayTimer", 0.6, true, function():Boolean
                {
                    if (firstClickColorIndex === getMyPaletteIndexByMousePos())
                    {
                        colorAddedFlag = true;
                        addColorToMyPalette(ColorPickerController.colorPickerBox.getRGBInfoBGColor(), getMyPaletteIndexByMousePos());
                    }
                    else
                    {
                        return false;
                    }
                    return true;
                });
        }

        public static function getMyPaletteIndexByMousePosLimitBound():int
        {
            const main:Main = Main._instance;

            const isAllViewMode:Boolean = (myPalettePresetType === 0 && isMyPaletteExpended);
            const paletteLines:int = (isAllViewMode) ? 8 : 2;
            var xLineIndex:int = Math.floor(ColorPickerController.colorPickerBox.myPaletteBox.mouseX / myPaletteColorWidth);
            var yLineIndex:int = Math.floor(ColorPickerController.colorPickerBox.myPaletteBox.mouseY / myPaletteColorHeight);

            if (xLineIndex < 0)
                xLineIndex = 0;
            else if (xLineIndex > 9)
                xLineIndex = 9;

            if (yLineIndex < 0)
                yLineIndex = 0;
            else if (yLineIndex >= paletteLines)
            {
                if (isAllViewMode)
                {
                    yLineIndex = paletteLines;
                }
                else
                {
                    yLineIndex = paletteLines - 1;
                }
            }

            return xLineIndex + yLineIndex * 10;
        }

        public static function getHistoryIndexByMousePos():int
        {
            const main:Main = Main._instance;

            const xLineIndex:int = Math.floor(ColorPickerController.colorPickerBox.colorHistoryBox.mouseX / myPaletteColorWidth);
            const yLineIndex:int = 10 * (Math.floor(ColorPickerController.colorPickerBox.colorHistoryBox.mouseY / myPaletteColorHeight));

            if (xLineIndex + yLineIndex < 0 || xLineIndex + yLineIndex > myPaletteColorLimit)
            {
                return -1;
            }

            return xLineIndex + yLineIndex;
        }

        public static function getMyPaletteIndexByMousePos():int
        {
            const main:Main = Main._instance;

            var xLineIndex:int = Math.floor(ColorPickerController.colorPickerBox.myPaletteBox.mouseX / myPaletteColorWidth);
            var yLineIndex:int = 10 * (Math.floor(ColorPickerController.colorPickerBox.myPaletteBox.mouseY / myPaletteColorHeight));
            if (xLineIndex > 9)
                xLineIndex = 9;
            if (yLineIndex > 80)
                yLineIndex = 80;

            if (xLineIndex + yLineIndex < 0 || xLineIndex + yLineIndex > myPaletteColorLimit)
            {
                return -1;
            }

            return xLineIndex + yLineIndex;
        }

        public static function isSelctedHistoryColorEmpty(index:int):Boolean
        {
            return !(myPalettePreset[index + 90] is uint);
        }

        public static function isSelctedColorEmpty(index:int):Boolean
        {
            var list:Array = (myPalettePresetType === 1) ? myPaletteDrawrPreset
                : (myPalettePresetType === 2) ? myPaletteTegakiPreset
                : myPalettePreset;

            return !(list[index] is uint);
        }

        public static function selectHistoryColor():void
        {
            const main:Main = Main._instance;

            const index:int = getHistoryIndexByMousePos();

            if (index < 0 || myPaletteDragStarted) // || index !== myPaletteDragClickedIndex)
            {
                return;
            }

            if (!(myPalettePreset[index + 90] is uint))
            {
                if (PenTool.isTransparentPenColor === false)
                {
                    ColorPickerController.selectTransparentColor();
                }
                return;
            }

            const pickedColor:uint = myPalettePreset[index + 90];

            if (pickedColor === ColorPickerController.colorPickerBox.getRGBInfoBGColor() && !PenTool.isTransparentPenColor)
            {
                return;
            }

            ColorPickerController.pickColor(pickedColor);
        }

        public static function selectMyPaletteColor():void
        {
            const main:Main = Main._instance;

            const index:int = getMyPaletteIndexByMousePos();

            if (index < 0)
            {
                return;
            }

            if (index !== myPaletteDragClickedIndex)
            {
                if (myPalettePresetType === 0)
                {
                    return;
                }
            }

            var pickedColor:uint;

            if (myPalettePresetType === 0)
            {
                if (isSelctedColorEmpty(index))
                {
                    if (PenTool.isTransparentPenColor === false && ColorPickerController.isColorPickerModeBG === false)
                    {
                        ColorPickerController.selectTransparentColor();
                    }
                    return;
                }

                pickedColor = myPalettePreset[index];

                // if(pickedColor === pickerBox.getRGBInfoBGColor() && !penColorTransparentFlag)
                // {
                // return;
                // }
            }
            else if (myPalettePresetType === 1)
            {
                if (isSelctedColorEmpty(index))
                {
                    if (PenTool.isTransparentPenColor === false && ColorPickerController.isColorPickerModeBG === false)
                    {
                        ColorPickerController.selectTransparentColor();
                    }
                    return;
                }

                pickedColor = myPaletteDrawrPreset[index];

                // if(pickedColor === CANVAS_BG_COLOR && !penColorTransparentFlag)
                // {
                // return;
                // }
            }
            else if (myPalettePresetType === 2)
            {
                ColorPickerController.selectTegakiColorPreset(index);
                return;
            }

            ColorPickerController.pickColor(pickedColor);
        }

        public static function saveMypPaletteList():void
        {
            const fs:FileStream = new FileStream();

            fs.open(myPaletteDataFilePath, FileMode.WRITE);
            fs.writeObject(myPalettePreset);
            fs.close();
        }

        public static function initializeMyPaletteList():void
        {
            updateHistoryList();
            updateMyPaletteList();

            if (!myPaletteDataFilePath.exists)
            {
                saveMypPaletteList();
            }
        }

        public static function switchMyPaletteToCompact():void
        {
            const main:Main = Main._instance;

            isMyPaletteExpended = false;
            updateMyPaletteList();
            MainUI.hideBottomHint();
            SidebarController.checkFOFOPosition();
        }

        public static function switchMyPaletteToExpended():void
        {
            const main:Main = Main._instance;

            isMyPaletteExpended = true;
            updateMyPaletteList();
            MainUI.hideBottomHint();
            SidebarController.checkFOFOPosition();
        }

        public static function addColorToMyPalette(color:uint, index:int):void
        {
            const main:Main = Main._instance;

            if (index < 0)
                return;

            if (isSelctedColorEmpty(index))
            {
                if (myPaletteColorBeforeAddColor[0] === index)
                {
                    myPalettePreset[index] = myPaletteColorBeforeAddColor[1];
                    updateMyPaletteList();
                    addColorMyPaletteHistory(color);
                }
                else
                {
                    myPalettePreset[index] = color;
                    updateMyPaletteList();
                    addColorMyPaletteHistory(color);
                }
            }
            else
            {
                if (myPalettePreset[index] !== ColorPickerController.colorPickerBox.getRGBInfoBGColor())
                {
                    myPaletteColorBeforeAddColor[0] = index;
                    myPaletteColorBeforeAddColor[1] = myPalettePreset[index];
                    myPalettePreset[index] = (PenTool.isTransparentPenColor) ? null : color;
                    updateMyPaletteList();
                    addColorMyPaletteHistory(color);
                }
                else
                {
                    if (PenTool.isTransparentPenColor)
                    {
                        myPaletteColorBeforeAddColor[0] = index;
                        myPaletteColorBeforeAddColor[1] = myPalettePreset[index];
                    }

                    myPalettePreset[index] = null;
                    updateMyPaletteList();
                    addColorMyPaletteHistory(color);
                }
            }
        }

        public static function clearMyPaletteList():void
        {
            for (var i:int = 0; i < 90; i++)
            {
                myPalettePreset[i] = null;
            }

            if (myPalettePresetType === 0)
            {
                updateHistoryList();
                updateMyPaletteList();
            }
        }

        public static function initMyPaletteHistory():void
        {
            myPalettePreset[90] = 0;
            updateHistoryList();
        }

        public static function addColorMyPaletteHistory(color:uint):void
        {
            const main:Main = Main._instance;

            // 색깔 같으면 체크안함
            if (myPalettePreset[90] === color)
            {
                return;
            }

            if ((ColorPickerController.pickerIgnoreHistoryColor as uint) === color)
            {
                ColorPickerController.pickerIgnoreHistoryColor = null;
                return;
            }

            // 이미 있는 색깔이면 다시 최신으로 갱신
            for (var i:uint = 90; i < 100; i++)
            {
                if (color === myPalettePreset[i])
                {
                    const tmpColor:uint = myPalettePreset.splice(i, 1);
                    if (myPalettePreset[90] === null || myPalettePreset[90] === undefined)
                    {
                        myPalettePreset[90] = tmpColor;
                    }
                    else
                    {
                        myPalettePreset.insertAt(90, tmpColor);
                    }
                    updateHistoryList();
                    return;
                }
            }

            // 첫부분에 셕이 없으면 그대로 넣어줌
            if (myPalettePreset[90] === null || myPalettePreset[90] === undefined)
            {
                myPalettePreset[90] = color;
            }
            else
            {
                myPalettePreset.insertAt(90, color);
                myPalettePreset.removeAt(100);
            }

            updateHistoryList();
        }

        public static function updateHistoryList(ignoreIndex:int = -1):void
        {
            const main:Main = Main._instance;

            ColorPickerController.colorPickerBox.colorHistoryBox.graphics.clear();

            for (var i:uint = 0; i < 10; i++)
            {
                if (90 + i === ignoreIndex)
                {
                    PaletteController.drawColorStartPos(ColorPickerController.colorPickerBox.colorHistoryBox.graphics, myPaletteColorWidth * i, 0, myPaletteColorWidth, myPaletteColorHeight);
                    continue;
                }
                if (!(myPalettePreset[90 + i] is uint))
                {
                    ColorPickerController.colorPickerBox.colorHistoryBox.graphics.beginBitmapFill(ColorPickerController.colorPickerBox.myPaletteTransBGBmpd);
                }
                else
                {
                    ColorPickerController.colorPickerBox.colorHistoryBox.graphics.beginFill(myPalettePreset[i + 90]);
                }

                ColorPickerController.colorPickerBox.colorHistoryBox.graphics.drawRect(myPaletteColorWidth * i, 0, myPaletteColorWidth, myPaletteColorHeight);
            }

            ColorPickerController.colorPickerBox.colorHistoryBox.graphics.endFill();
            ColorPickerController.colorPickerBox.colorHistoryBox.graphics.lineStyle(1, 0, 0.2);

            for (i = 1; i < 10; i++)
            {
                ColorPickerController.colorPickerBox.colorHistoryBox.graphics.moveTo(myPaletteColorWidth * i, 0);
                ColorPickerController.colorPickerBox.colorHistoryBox.graphics.lineTo(myPaletteColorWidth * i, myPaletteColorHeight);
            }
        }

        public static function updateMyPaletteList(ignoreIndex:int = -1):void
        {
            const main:Main = Main._instance;

            const type:int = myPalettePresetType;
            const arr:Array = (type === 0) ? myPalettePreset
                : (type === 1) ? myPaletteDrawrPreset
                : (type === 2) ? myPaletteTegakiPreset : null;

            if (arr === null)
                return;

            const ww:Number = myPaletteColorWidth;
            const hh:Number = myPaletteColorHeight;

            var len:int = (type === 0 && isMyPaletteExpended) ? myPaletteColorLimit - 10 : 20;
            var nextX:Number = 0.0;
            var nextY:Number = 0.0;

            ColorPickerController.colorPickerBox.myPaletteBox.graphics.clear();
            ColorPickerController.colorPickerBox.myPaletteBox.graphics.lineStyle(0, 0, 0);

            var px:Number;
            var py:Number;

            // 색깔 쭉 그려주기
            for (var i:uint = 0; i < len; i++)
            {
                if (i > 0 && i % 10 === 0)
                {
                    nextX = 0;
                    nextY++;
                }

                px = ww * nextX;
                py = hh * (nextY);
                nextX += 1.0;

                if (i === ignoreIndex)
                {
                    drawColorStartPos(ColorPickerController.colorPickerBox.myPaletteBox.graphics, px, py, ww, hh);
                    continue;
                }

                if (!(arr[i] is uint))
                {
                    ColorPickerController.colorPickerBox.myPaletteBox.graphics.beginBitmapFill(ColorPickerController.colorPickerBox.myPaletteTransBGBmpd);
                }
                else
                {
                    ColorPickerController.colorPickerBox.myPaletteBox.graphics.beginFill(arr[i]);
                }

                ColorPickerController.colorPickerBox.myPaletteBox.graphics.drawRect(px, py, ww, hh);
            }
            ColorPickerController.colorPickerBox.myPaletteBox.graphics.endFill();

            // 구분선 그려주기
            if (type === 2) // tegaki
            {
                ColorPickerController.colorPickerBox.myPaletteBox.graphics.lineStyle(1, 0, 0.2);
                ColorPickerController.colorPickerBox.myPaletteBox.graphics.moveTo(0, hh);
                ColorPickerController.colorPickerBox.myPaletteBox.graphics.lineTo(ww * 10, hh);

                for (i = 2; i < 10; i += 2)
                {
                    ColorPickerController.colorPickerBox.myPaletteBox.graphics.moveTo(ww * i, 0);
                    ColorPickerController.colorPickerBox.myPaletteBox.graphics.lineTo(ww * i, hh * 2);
                }
            }
            else if (type === 1) // drawr
            {
                ColorPickerController.colorPickerBox.myPaletteBox.graphics.lineStyle(1, 0, 0.2);
                ColorPickerController.colorPickerBox.myPaletteBox.graphics.moveTo(0, hh);
                ColorPickerController.colorPickerBox.myPaletteBox.graphics.lineTo(ww * 10, hh);

                for (i = 1; i < 10; i++)
                {
                    ColorPickerController.colorPickerBox.myPaletteBox.graphics.moveTo(ww * i, 0);
                    ColorPickerController.colorPickerBox.myPaletteBox.graphics.lineTo(ww * i, hh * 2);
                }
            }
            else // my palette
            {
                if (isMyPaletteExpended === false)
                {
                    // 가로선
                    ColorPickerController.colorPickerBox.myPaletteBox.graphics.lineStyle(1, 0, 0.2);
                    ColorPickerController.colorPickerBox.myPaletteBox.graphics.moveTo(0, hh);
                    ColorPickerController.colorPickerBox.myPaletteBox.graphics.lineTo(ww * 10, hh);

                    // 세로
                    for (i = 1; i < 10; i++)
                    {
                        ColorPickerController.colorPickerBox.myPaletteBox.graphics.moveTo(myPaletteColorWidth * i, 0);
                        ColorPickerController.colorPickerBox.myPaletteBox.graphics.lineTo(myPaletteColorWidth * i, hh * 2);
                    }
                }
                else
                {
                    ColorPickerController.colorPickerBox.myPaletteBox.graphics.lineStyle(1, 0, 0.2);

                    // 가로
                    for (i = 1; i < 9; i++)
                    {
                        ColorPickerController.colorPickerBox.myPaletteBox.graphics.moveTo(0, hh * i);
                        ColorPickerController.colorPickerBox.myPaletteBox.graphics.lineTo(myPaletteColorWidth * 10, hh * i);
                    }
                    // 세로
                    for (i = 1; i < 10; i++)
                    {
                        ColorPickerController.colorPickerBox.myPaletteBox.graphics.moveTo(myPaletteColorWidth * i, 0);
                        ColorPickerController.colorPickerBox.myPaletteBox.graphics.lineTo(myPaletteColorWidth * i, hh * 9);
                    }
                }
            }

            ColorPickerController.colorPickerBox.updateMainColorPickerBoxPosition(ColorPickerController.isColorPickerBoxPositionSwapped);
        }

        public static function startColorHistoryBoxDragging():void
        {
            const main:Main = Main._instance;

            const index:int = getHistoryIndexByMousePos();

            function onDragStart():void
            {
                myPaletteDragClickedIndex = index + 90;
                myPaletteDragClickedColor = myPalettePreset[index + 90];
                myPaletteClickPos.setTo(ColorPickerController.colorPickerBox.mouseX, ColorPickerController.colorPickerBox.mouseY);
                myPaletteMovePos.setTo(ColorPickerController.colorPickerBox.mouseX, ColorPickerController.colorPickerBox.mouseY);
            }

            function onMouseMove():void
            {
                if (Point.distance(myPaletteClickPos, myPaletteMovePos) >= 4)
                {
                    if (myPaletteDragStarted === false)
                    {
                        myPaletteDragStarted = true;
                        ColorPickerController.colorPickerBox.updateDragColor(myPaletteDragClickedColor, myPaletteColorWidth, myPaletteColorHeight);
                        updateMyPaletteList(myPaletteDragClickedIndex);
                        updateHistoryList(myPaletteDragClickedIndex);
                    }

                    ColorPickerController.colorPickerBox.updateDragColorPosToCursor();
                }
                else
                {
                    myPaletteMovePos.setTo(ColorPickerController.colorPickerBox.mouseX, ColorPickerController.colorPickerBox.mouseY);
                }
            }

            function onMouseUp():void
            {
                if (myPaletteDragStarted === true)
                {
                    myPaletteDragStarted = false;

                    if (ColorPickerController.colorPickerBox.myPaletteBox.hitTestPoint(main.mouseX, main.mouseY))
                    {
                        const putIndex:int = getMyPaletteIndexByMousePosLimitBound();
                        const colorSave:* = myPalettePreset[putIndex];

                        myPalettePreset[putIndex] = myPaletteDragClickedColor;
                        myPalettePreset[myPaletteDragClickedIndex] = (colorSave === null || colorSave === undefined) ? null : colorSave;
                        myPalettePreset.removeAt(myPaletteDragClickedIndex);

                        updateMyPaletteList(myPaletteDragClickedIndex);
                    }
                }

                updateHistoryList();
                ColorPickerController.colorPickerBox.removeDragColor();
            }

            if (index >= 0 && !isSelctedHistoryColorEmpty(index))
            {
                DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
            }
        }

        public static function startMyPaletteBoxDragging():void
        {
            const main:Main = Main._instance;

            var index:int = getMyPaletteIndexByMousePos();

            function onDragStart():void
            {
                if (index >= 0 && !isSelctedColorEmpty(index))
                {
                    myPaletteDragClickedIndex = index;
                    myPaletteDragClickedColor = myPalettePreset[index];
                    myPaletteClickPos.setTo(ColorPickerController.colorPickerBox.mouseX, ColorPickerController.colorPickerBox.mouseY);
                    myPaletteMovePos.setTo(ColorPickerController.colorPickerBox.mouseX, ColorPickerController.colorPickerBox.mouseY);
                }
            }

            function onMouseMouse():void
            {
                if (Point.distance(myPaletteClickPos, myPaletteMovePos) >= 4)
                {
                    if (myPaletteDragStarted === false)
                    {
                        FOFOTimer.remove("addColorMyPaletteDelayTimer");
                        myPaletteDragStarted = true;
                        ColorPickerController.colorPickerBox.updateDragColor(myPaletteDragClickedColor, myPaletteColorWidth, myPaletteColorHeight);
                        updateMyPaletteList(myPaletteDragClickedIndex);
                    }

                    ColorPickerController.colorPickerBox.updateDragColorPosToCursor();
                }
                else
                {
                    myPaletteMovePos.setTo(ColorPickerController.colorPickerBox.mouseX, ColorPickerController.colorPickerBox.mouseY);
                }
            }

            function onMouseUp():void
            {
                if (myPaletteDragStarted === true)
                {
                    myPaletteDragStarted = false;

                    const putIndex:int = getMyPaletteIndexByMousePosLimitBound();
                    const colorSave:* = myPalettePreset[putIndex];

                    myPalettePreset[putIndex] = myPaletteDragClickedColor;
                    myPalettePreset[myPaletteDragClickedIndex] = (colorSave === null || colorSave === undefined) ? null : colorSave;
                    updateMyPaletteList();
                }

                ColorPickerController.colorPickerBox.removeDragColor();
            }

            if (index >= 0 && !isSelctedColorEmpty(index))
            {
                DragInteraction.startDragInteraction(onDragStart, onMouseMouse, onMouseUp);
            }
        }

        public static function drawColorStartPos(g:Graphics, px:Number, py:Number, ww:Number, hh:Number):void
        {
            g.beginFill(0xFFFFFF);
            g.drawRect(px, py, PaletteController.myPaletteColorWidth, PaletteController.myPaletteColorHeight);
            g.endFill();

            g.lineStyle(3, 0xFF6600);
            g.moveTo(px + 5, py + 5);
            g.lineTo(px + ww - 5, py + hh - 5);
            g.moveTo(px + ww - 5, py + 5);
            g.lineTo(px + 5, py + hh - 5);
            g.lineStyle(0, 0, 0);
        }
    }
}
