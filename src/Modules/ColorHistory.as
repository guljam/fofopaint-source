package Modules
{
    import Modules.Tools.PenTool;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.geom.Point;
    import Modules.L4UI.ColorPickerController;

    // 최근에 쓴 색 10개. My Palette와 완전히 별개의 배열을 쓰며 저장은 PaletteController.saveMypPaletteList가 함께 해줌
    // 층: L1 데이터 - 최근에 쓴 색 10개
    public final class ColorHistory
    {
        public static const HISTORY_COUNT:int = 10;

        // 최신 색이 0번. uint만 들어가고 빈 칸은 뒤쪽에 length만큼만 비어있음. 화면에서는 좌우 반전되어 0번이 맨 오른쪽 칸에 그려짐
        public static var list:Array = [];

        public static function init():void
        {
            list = [0];
            update();
        }

        // 저장 파일에서 읽은 배열을 넣음. uint가 아닌 값은 버림
        public static function setList(src:Array):void
        {
            const result:Array = [];

            for (var i:int = 0;i < src.length && result.length < HISTORY_COUNT;i++)
            {
                if (src[i] is uint)
                {
                    result.push(src[i]);
                }
            }

            list = result;
        }

        public static function add(color:uint):void
        {
            // 색깔 같으면 체크안함
            if (list.length > 0 && list[0] === color)
            {
                return;
            }

            const ignoreColor:* = ColorPickerController.pickerIgnoreHistoryColor;

            if (ignoreColor !== null && ignoreColor !== undefined && (ignoreColor as uint) === color)
            {
                ColorPickerController.pickerIgnoreHistoryColor = null;
                return;
            }

            // 이미 있는 색깔이면 다시 최신으로 갱신
            const existIndex:int = list.indexOf(color);

            if (existIndex >= 0)
            {
                list.removeAt(existIndex);
            }
            else if (list.length >= HISTORY_COUNT)
            {
                list.length = HISTORY_COUNT - 1;
            }

            list.insertAt(0, color);
            update();
        }

        private static function getIndexByMousePos():int
        {
            const box:Sprite = ColorPickerController.colorPickerBox.colorHistoryBox;

            return calcIndex(box.mouseX, box.mouseY);
        }

        public static function calcIndex(localX:Number, localY:Number):int
        {
            const xLineIndex:int = Math.floor(localX / PaletteController.myPaletteColorWidth);
            const yLineIndex:int = Math.floor(localY / PaletteController.myPaletteColorHeight);

            if (yLineIndex !== 0 || xLineIndex < 0 || xLineIndex >= HISTORY_COUNT)
            {
                return -1;
            }

            return xLineIndex; // 화면 칸 순서가 list와 반대
        }

        private static function isEmpty(index:int):Boolean
        {
            return !(list[index] is uint);
        }

        public static function select():void
        {
            const index:int = getIndexByMousePos();

            if (index < 0 || PaletteController.myPaletteDragStarted)
            {
                return;
            }

            // 빈 칸은 투명색조차 선택하지 않음
            if (isEmpty(index))
            {
                return;
            }

            const pickedColor:uint = list[index];

            if (pickedColor === ColorPickerController.colorPickerBox.getRGBInfoBGColor() && !PenTool.isTransparentPenColor)
            {
                return;
            }

            ColorPickerController.pickColor(pickedColor);
        }

        public static function update(ignoreIndex:int = -1):void
        {
            const g:Graphics = ColorPickerController.colorPickerBox.colorHistoryBox.graphics;
            const ww:Number = PaletteController.myPaletteColorWidth;
            const hh:Number = PaletteController.myPaletteColorHeight;

            g.clear();

            for (var i:uint = 0;i < HISTORY_COUNT;i++)
            {
                if (i === ignoreIndex)
                {
                    PaletteController.drawRedXMark(g, ww * i, 0, ww, hh);
                    continue;
                }

                if (isEmpty(i))
                {
                    g.beginBitmapFill(ColorPickerController.colorPickerBox.myPaletteTransBGBmpd);
                }
                else
                {
                    g.beginFill(list[i]);
                }

                g.drawRect(ww * i, 0, ww, hh);
            }

            g.endFill();
            g.lineStyle(1, 0, 0.2);

            for (i = 1;i < HISTORY_COUNT;i++)
            {
                g.moveTo(ww * i, 0);
                g.lineTo(ww * i, hh);
            }
        }

        // 히스토리 색을 드래그해서 my palette에 복제해 놓음 (히스토리는 그대로)
        public static function startDragging():void
        {
            const index:int = getIndexByMousePos();

            function onDragStart():void
            {
                PaletteController.myPaletteDragClickedIndex = -1;
                PaletteController.myPaletteDragClickedColor = list[index];
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

            if (index >= 0 && !isEmpty(index))
            {
                DragInteraction.start(onDragStart, onMouseMove, onMouseUp);
            }
        }
    }
}
