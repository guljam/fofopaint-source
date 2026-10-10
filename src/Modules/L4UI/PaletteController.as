package Modules.L4UI
{

    import Symbols.ColorPickerSet;

    import flash.display.DisplayObject;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Point;
    import Modules.L4UI.ColorPickerController;
    import Modules.L5App.InputManager.InputManager;
    import Modules.L4UI.SidebarController;
    import Modules.InputPriority;
    import Modules.L1Data.AppDataPaths;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L3Feature.Tools.PenTool;
    import Modules.L1Data.ColorHistory;
    import Modules.L1Data.DragInteraction;

    // 층: L4 UI - My Palette 선택·추가·저장과 적용
    public final class PaletteController
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static const COLOR_BOX_DRAG_DISTANCE:Number = 5; // 현재 색 박스를 이만큼(colorPickerBox 좌표 기준) 움직여야 드래그로 봄

        public static const MYPALETTE_COUNT:int = 100; // my palette 칸 수 (10x10)
        public static const MYPALETTE_COLUMNS:int = 10;

        public static var isMyPaletteExpended:Boolean = false, // 전체로 보면 올려줌
            myPaletteColorBeforeAddColor:Array = [-1, 0], // index, hexcolor
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
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpMyPalette, false, InputPriority.DEFAULT);

            FOFOTimer.addByName("selectMyPaletteDelayTimer", 0.4, false, function ():void
                {
                    InputManager.startPressHoldKey(ColorPickerController.colorPickerBox.myPaletteButton, "Clearing my palette..", null, clearMyPaletteList, null);
                    main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpMyPalette);
                });
        }

        public static function startSelectOrAddColorMyPalette():void
        {
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
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMyPaletteMouseUp, false, InputPriority.DEFAULT);

            FOFOTimer.addByName("addColorMyPaletteDelayTimer", 0.7, true, function ():Boolean
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
            return calcMyPaletteIndexLimitBound(ColorPickerController.colorPickerBox.myPaletteBox.mouseX, ColorPickerController.colorPickerBox.myPaletteBox.mouseY);
        }

        // 박스 밖이어도 가장 가까운 칸을 돌려줌. 압축 보기는 2줄, 확장 보기는 전체 줄까지
        public static function calcMyPaletteIndexLimitBound(localX:Number, localY:Number):int
        {
            const isAllViewMode:Boolean = (myPalettePresetType === 0 && isMyPaletteExpended);
            const paletteLines:int = (isAllViewMode) ? MYPALETTE_COUNT / MYPALETTE_COLUMNS : 2;
            var xLineIndex:int = Math.floor(localX / myPaletteColorWidth);
            var yLineIndex:int = Math.floor(localY / myPaletteColorHeight);

            if (xLineIndex < 0)
                xLineIndex = 0;
            else if (xLineIndex >= MYPALETTE_COLUMNS)
                xLineIndex = MYPALETTE_COLUMNS - 1;

            if (yLineIndex < 0)
                yLineIndex = 0;
            else if (yLineIndex >= paletteLines)
                yLineIndex = paletteLines - 1;

            return xLineIndex + yLineIndex * MYPALETTE_COLUMNS;
        }

        private static function getMyPaletteIndexByMousePos():int
        {
            return calcMyPaletteIndex(ColorPickerController.colorPickerBox.myPaletteBox.mouseX, ColorPickerController.colorPickerBox.myPaletteBox.mouseY);
        }

        public static function calcMyPaletteIndex(localX:Number, localY:Number):int
        {
            var xLineIndex:int = Math.floor(localX / myPaletteColorWidth);
            var yLineIndex:int = MYPALETTE_COLUMNS * (Math.floor(localY / myPaletteColorHeight));
            if (xLineIndex >= MYPALETTE_COLUMNS)
                xLineIndex = MYPALETTE_COLUMNS - 1;
            if (yLineIndex > MYPALETTE_COUNT - MYPALETTE_COLUMNS)
                yLineIndex = MYPALETTE_COUNT - MYPALETTE_COLUMNS;

            if (xLineIndex + yLineIndex < 0 || xLineIndex + yLineIndex >= MYPALETTE_COUNT)
            {
                return -1;
            }

            return xLineIndex + yLineIndex;
        }

        private static function isSelctedColorEmpty(index:int):Boolean
        {
            var list:Array = (myPalettePresetType === 1) ? myPaletteDrawrPreset
                : (myPalettePresetType === 2) ? myPaletteTegakiPreset
                : myPalettePreset;

            return !(list[index] is uint);
        }

        public static function selectMyPaletteColor():void
        {
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
                // 빈 칸은 투명색조차 선택하지 않음
                if (isSelctedColorEmpty(index))
                {
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

            fs.open(AppDataPaths.myPaletteDataFilePath, FileMode.WRITE);
            fs.writeObject({palette: myPalettePreset, history: ColorHistory.list});
            fs.close();
        }

        // 저장 파일에서 읽은 {palette, history}를 적용함
        public static function applyMyPaletteData(data:Object):void
        {
            const palette:Array = data.palette as Array;
            const history:Array = data.history as Array;

            myPalettePreset = (palette) ? palette.concat() : [];
            myPalettePreset.length = MYPALETTE_COUNT;
            ColorHistory.setList((history) ? history : []);
        }

        public static function initializeMyPaletteList():void
        {
            PaletteController.updateColorHistory();
            updateMyPaletteList();

            if (!AppDataPaths.myPaletteDataFilePath.exists)
            {
                saveMypPaletteList();
            }
        }

        private static function switchMyPaletteToCompact():void
        {
            isMyPaletteExpended = false;
            updateMyPaletteList();
            HintController.hideBottomHint();
            SidebarController.checkFOFOPosition();
        }

        public static function switchMyPaletteToExpended():void
        {
            isMyPaletteExpended = true;
            updateMyPaletteList();
            HintController.hideBottomHint();
            SidebarController.checkFOFOPosition();
        }

        private static function addColorToMyPalette(color:uint, index:int):void
        {
            if (index < 0)
                return;

            if (isSelctedColorEmpty(index))
            {
                if (myPaletteColorBeforeAddColor[0] === index)
                {
                    myPalettePreset[index] = myPaletteColorBeforeAddColor[1];
                    updateMyPaletteList();
                    ColorHistory.add(color);
                }
                else
                {
                    myPalettePreset[index] = color;
                    updateMyPaletteList();
                    ColorHistory.add(color);
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
                    ColorHistory.add(color);
                }
                else if (PenTool.isTransparentPenColor)
                {
                    myPaletteColorBeforeAddColor[0] = index;
                    myPaletteColorBeforeAddColor[1] = myPalettePreset[index];
                    myPalettePreset[index] = null;
                    updateMyPaletteList();
                    ColorHistory.add(color);
                }
                else if (myPaletteColorBeforeAddColor[0] === index && myPaletteColorBeforeAddColor[1] is uint)
                {
                    // 이미 현재 색이면 이전 색과 맞바꿔서 "현재 색 - 이전 색"으로 순환함 (지우기는 svBox로 드래그)
                    const colorSwap:uint = myPalettePreset[index];
                    myPalettePreset[index] = myPaletteColorBeforeAddColor[1];
                    myPaletteColorBeforeAddColor[1] = colorSwap;
                    updateMyPaletteList();
                    ColorHistory.add(color);
                }
            }
        }

        private static function clearMyPaletteList():void
        {
            for (var i:int = 0;i < MYPALETTE_COUNT;i++)
            {
                myPalettePreset[i] = null;
            }

            if (myPalettePresetType === 0)
            {
                updateMyPaletteList();
            }
        }

        public static function updateMyPaletteList(ignoreIndex:int = -1):void
        {
            const type:int = myPalettePresetType;
            const arr:Array = (type === 0) ? myPalettePreset
                : (type === 1) ? myPaletteDrawrPreset
                : (type === 2) ? myPaletteTegakiPreset : null;

            if (arr === null)
                return;

            const ww:Number = myPaletteColorWidth;
            const hh:Number = myPaletteColorHeight;

            var len:int = (type === 0 && isMyPaletteExpended) ? MYPALETTE_COUNT : 20;
            var nextX:Number = 0.0;
            var nextY:Number = 0.0;

            ColorPickerController.colorPickerBox.myPaletteBox.graphics.clear();
            ColorPickerController.colorPickerBox.myPaletteBox.graphics.lineStyle(0, 0, 0);

            var px:Number;
            var py:Number;

            // 색깔 쭉 그려주기
            for (var i:uint = 0;i < len;i++)
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
                    drawRedXMark(ColorPickerController.colorPickerBox.myPaletteBox.graphics, px, py, ww, hh);
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

                for (i = 2;i < 10;i += 2)
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

                for (i = 1;i < 10;i++)
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
                    for (i = 1;i < 10;i++)
                    {
                        ColorPickerController.colorPickerBox.myPaletteBox.graphics.moveTo(myPaletteColorWidth * i, 0);
                        ColorPickerController.colorPickerBox.myPaletteBox.graphics.lineTo(myPaletteColorWidth * i, hh * 2);
                    }
                }
                else
                {
                    ColorPickerController.colorPickerBox.myPaletteBox.graphics.lineStyle(1, 0, 0.2);

                    // 가로
                    for (i = 1;i < MYPALETTE_COUNT / MYPALETTE_COLUMNS;i++)
                    {
                        ColorPickerController.colorPickerBox.myPaletteBox.graphics.moveTo(0, hh * i);
                        ColorPickerController.colorPickerBox.myPaletteBox.graphics.lineTo(myPaletteColorWidth * 10, hh * i);
                    }
                    // 세로
                    for (i = 1;i < 10;i++)
                    {
                        ColorPickerController.colorPickerBox.myPaletteBox.graphics.moveTo(myPaletteColorWidth * i, 0);
                        ColorPickerController.colorPickerBox.myPaletteBox.graphics.lineTo(myPaletteColorWidth * i, hh * (MYPALETTE_COUNT / MYPALETTE_COLUMNS));
                    }
                }
            }

            ColorPickerController.colorPickerBox.updateMainColorPickerBoxPosition(ColorPickerController.isColorPickerBoxPositionSwapped);
        }

        // 드래그 중인 색 사각형을 my palette 박스 위에 있을 때만 놓일 칸에 붙이고, 박스 밖에서는 커서를 부드럽게 따라가게 함
        public static function updateDragColorPosition():void
        {
            const box:ColorPickerSet = ColorPickerController.colorPickerBox;

            if (box.myPaletteBox.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
            {
                box.snapDragColorToCell(getMyPaletteIndexByMousePosLimitBound(), myPaletteColorWidth, myPaletteColorHeight);
            }
            else
            {
                box.updateDragColorPosToCursor();
            }
        }

        // 현재 색 박스(rgbInfoBG, currentColor)용. 누른 위치에서 5px 넘게 움직이면 색 사각형이 생겨서 my palette에 놓을 수 있고,
        // 그 전에 박스 위에서 떼면 onClick을 호출함. canDrag가 false면 드래그 없이 클릭만 받음
        public static function startColorBoxClickOrDrag(clickArea:DisplayObject, color:uint, canDrag:Boolean, onClick:Function):void
        {
            const clickPos:Point = new Point();
            var dragStarted:Boolean = false;

            function onDragStart():void
            {
                clickPos.setTo(ColorPickerController.colorPickerBox.mouseX, ColorPickerController.colorPickerBox.mouseY);
            }

            function onMouseMove():void
            {
                if (canDrag === false)
                {
                    return;
                }

                if (dragStarted === false)
                {
                    const dx:Number = ColorPickerController.colorPickerBox.mouseX - clickPos.x;
                    const dy:Number = ColorPickerController.colorPickerBox.mouseY - clickPos.y;

                    if (dx * dx + dy * dy < COLOR_BOX_DRAG_DISTANCE * COLOR_BOX_DRAG_DISTANCE)
                    {
                        return;
                    }

                    dragStarted = true;
                    ColorPickerController.colorPickerBox.updateDragColor(color, myPaletteColorWidth, myPaletteColorHeight);
                }

                updateDragColorPosition();
            }

            function onMouseUp():void
            {
                if (dragStarted)
                {
                    ColorPickerController.colorPickerBox.removeDragColor();

                    if (ColorPickerController.colorPickerBox.myPaletteBox.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                    {
                        putColorToMyPalette(color, getMyPaletteIndexByMousePosLimitBound(), true);
                    }
                }
                else if (clickArea.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                {
                    onClick();
                }
            }

            DragInteraction.start(onDragStart, onMouseMove, onMouseUp);
        }

        // 선택한 칸의 색을 덮어씀 (addColorToMyPalette와 달리 같은 색이어도 지우지 않음)
        public static function putColorToMyPalette(color:uint, index:int, addHistory:Boolean):void
        {
            if (index < 0)
            {
                return;
            }

            // 덮어쓰기 전 색을 저장해서 길게 클릭했을때 "새 색 - 이전 색 - 투명" 순환이 되게 함
            if (!isSelctedColorEmpty(index) && myPalettePreset[index] !== color)
            {
                myPaletteColorBeforeAddColor[0] = index;
                myPaletteColorBeforeAddColor[1] = myPalettePreset[index];
            }

            myPalettePreset[index] = color;
            updateMyPaletteList();

            if (addHistory)
            {
                ColorHistory.add(color);
            }
        }

        public static function startMyPaletteBoxDragging():void
        {
            var index:int = getMyPaletteIndexByMousePos();
            var isOverDeleteTarget:Boolean = false;

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

                        // 드래그를 시작하면 svBox를 밝게 하고 힌트를 띄워서 지울 수 있음을 알려줌
                        ColorPickerController.colorPickerBox.setSVBoxHighlight(1);
                        HintController.showMouseHintAtCenter(HintStrings.getDeleteColorHint(), ColorPickerController.colorPickerBox.svBox);
                        HintController.mouseHint.x -= 3;//위치 미조정
                    }

                    updateDeleteTarget();
                    updateDragColorPosition();
                }
                else
                {
                    myPaletteMovePos.setTo(ColorPickerController.colorPickerBox.mouseX, ColorPickerController.colorPickerBox.mouseY);
                }
            }

            // 드래그 중인 커서가 svBox에 들어가면 더 밝게, 나오면 삭제 대상 표시 정도로 되돌림
            function updateDeleteTarget():void
            {
                const isOver:Boolean = ColorPickerController.colorPickerBox.isSVBoxUnderMouse();

                if (isOver === isOverDeleteTarget)
                {
                    return;
                }

                isOverDeleteTarget = isOver;
                ColorPickerController.colorPickerBox.setSVBoxHighlight(isOver ? 2 : 1);
            }

            function onMouseUp():void
            {
                if (myPaletteDragStarted === true)
                {
                    myPaletteDragStarted = false;
                    isOverDeleteTarget = false;
                    ColorPickerController.colorPickerBox.setSVBoxHighlight(0);
                    HintController.hideMouseHint();

                    if (ColorPickerController.colorPickerBox.isSVBoxUnderMouse())
                    {
                        // 지우기 전 색을 저장해서 길게 클릭했을때 이전 색으로 복원되게 함
                        myPaletteColorBeforeAddColor[0] = myPaletteDragClickedIndex;
                        myPaletteColorBeforeAddColor[1] = myPaletteDragClickedColor;
                        myPalettePreset[myPaletteDragClickedIndex] = null;
                    }
                    else
                    {
                        const putIndex:int = getMyPaletteIndexByMousePosLimitBound();
                        const colorSave:* = myPalettePreset[putIndex];

                        myPalettePreset[putIndex] = myPaletteDragClickedColor;
                        myPalettePreset[myPaletteDragClickedIndex] = (colorSave === null || colorSave === undefined) ? null : colorSave;
                    }
                    updateMyPaletteList();
                }

                ColorPickerController.colorPickerBox.removeDragColor();
            }

            if (index >= 0 && !isSelctedColorEmpty(index))
            {
                DragInteraction.start(onDragStart, onMouseMouse, onMouseUp);
            }
        }

        //팔레트 색깔 드래깅 해줄때 원래 있던 자리위치에 x표시해주는 함수
        public static function drawRedXMark(g:Graphics, px:Number, py:Number, ww:Number, hh:Number):void
        {
            //배경깔아주기
            g.beginFill(0xFFFFFF);
            g.drawRect(px, py, PaletteController.myPaletteColorWidth, PaletteController.myPaletteColorHeight);
            g.endFill();

            //X표시
            g.lineStyle(3, 0xFF6600);
            g.moveTo(px + 5, py + 5);
            g.lineTo(px + ww - 5, py + hh - 5);
            g.moveTo(px + ww - 5, py + 5);
            g.lineTo(px + 5, py + hh - 5);
            g.lineStyle(0, 0, 0);
        }

        private static function getColorHistoryIndexByMousePos():int
        {
            const box:Sprite = ColorPickerController.colorPickerBox.colorHistoryBox;

            return calcColorHistoryIndex(box.mouseX, box.mouseY);
        }

        public static function calcColorHistoryIndex(localX:Number, localY:Number):int
        {
            const xLineIndex:int = Math.floor(localX / PaletteController.myPaletteColorWidth);
            const yLineIndex:int = Math.floor(localY / PaletteController.myPaletteColorHeight);

            if (yLineIndex !== 0 || xLineIndex < 0 || xLineIndex >= ColorHistory.HISTORY_COUNT)
            {
                return -1;
            }

            return xLineIndex; // 화면 칸 순서가 list와 반대
        }

        public static function selectColorHistory():void
        {
            const index:int = getColorHistoryIndexByMousePos();

            if (index < 0 || PaletteController.myPaletteDragStarted)
            {
                return;
            }

            // 빈 칸은 투명색조차 선택하지 않음
            if (ColorHistory.isEmpty(index))
            {
                return;
            }

            const pickedColor:uint = ColorHistory.list[index];

            if (pickedColor === ColorPickerController.colorPickerBox.getRGBInfoBGColor() && !PenTool.isTransparentPenColor)
            {
                return;
            }

            ColorPickerController.pickColor(pickedColor);
        }

        public static function updateColorHistory(ignoreIndex:int = -1):void
        {
            const g:Graphics = ColorPickerController.colorPickerBox.colorHistoryBox.graphics;
            const ww:Number = PaletteController.myPaletteColorWidth;
            const hh:Number = PaletteController.myPaletteColorHeight;

            g.clear();

            for (var i:uint = 0;i < ColorHistory.HISTORY_COUNT;i++)
            {
                if (i === ignoreIndex)
                {
                    PaletteController.drawRedXMark(g, ww * i, 0, ww, hh);
                    continue;
                }

                if (ColorHistory.isEmpty(i))
                {
                    g.beginBitmapFill(ColorPickerController.colorPickerBox.myPaletteTransBGBmpd);
                }
                else
                {
                    g.beginFill(ColorHistory.list[i]);
                }

                g.drawRect(ww * i, 0, ww, hh);
            }

            g.endFill();
            g.lineStyle(1, 0, 0.2);

            for (i = 1;i < ColorHistory.HISTORY_COUNT;i++)
            {
                g.moveTo(ww * i, 0);
                g.lineTo(ww * i, hh);
            }
        }

        // 히스토리 색을 드래그해서 my palette에 복제해 놓음 (히스토리는 그대로)
        public static function startDraggingColorHistory():void
        {
            const index:int = getColorHistoryIndexByMousePos();

            function onDragStart():void
            {
                PaletteController.myPaletteDragClickedIndex = -1;
                PaletteController.myPaletteDragClickedColor = ColorHistory.list[index];
                PaletteController.myPaletteClickPos.setTo(ColorPickerController.colorPickerBox.mouseX, ColorPickerController.colorPickerBox.mouseY);
                PaletteController.myPaletteMovePos.setTo(ColorPickerController.colorPickerBox.mouseX, ColorPickerController.colorPickerBox.mouseY);
            }

            function onMouseMove():void
            {
                if (Point.distance(PaletteController.myPaletteClickPos, PaletteController.myPaletteMovePos) >= 4)
                {
                    if (PaletteController.myPaletteDragStarted === false)
                    {
                        PaletteController.myPaletteDragStarted = true;
                        ColorPickerController.colorPickerBox.updateDragColor(PaletteController.myPaletteDragClickedColor, PaletteController.myPaletteColorWidth, PaletteController.myPaletteColorHeight);
                    }

                    PaletteController.updateDragColorPosition();
                }
                else
                {
                    PaletteController.myPaletteMovePos.setTo(ColorPickerController.colorPickerBox.mouseX, ColorPickerController.colorPickerBox.mouseY);
                }
            }

            function onMouseUp():void
            {
                if (PaletteController.myPaletteDragStarted === true)
                {
                    PaletteController.myPaletteDragStarted = false;

                    if (ColorPickerController.colorPickerBox.myPaletteBox.hitTestPoint(PaletteController.main.mouseX, PaletteController.main.mouseY))
                    {
                        PaletteController.putColorToMyPalette(PaletteController.myPaletteDragClickedColor, PaletteController.getMyPaletteIndexByMousePosLimitBound(), false);
                    }
                }

                ColorPickerController.colorPickerBox.removeDragColor();
            }

            if (index >= 0 && !ColorHistory.isEmpty(index))
            {
                DragInteraction.start(onDragStart, onMouseMove, onMouseUp);
            }
        }

    }
}
