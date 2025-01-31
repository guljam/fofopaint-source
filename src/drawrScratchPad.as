package
{
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.display.LineScaleMode;
    import flash.display.CapsStyle;
    import flash.display.JointStyle;
    import flash.geom.Rectangle;
    import flash.utils.Timer;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;

    public class drawrScratchPad extends Sprite
    {

        private const scratchPadDraw:Shape = new Shape();
        private var scratchPadBitmap:Bitmap;
        private const scratchPadBG:Shape = new Shape();
        private var scratchPadBGColor:uint = 0;
        private const scratchPadZoom:Number = 16;
        private var isPadCleared:Boolean = false;
        // private var scratcthPadDrawClearTimer:int = 0;

        public function drawrScratchPad(bmpdWidth:Number, bmpdHeight:Number):void
        {
            bmpdWidth = bmpdWidth / scratchPadZoom;
            bmpdHeight = bmpdHeight / scratchPadZoom;
            scratchPadBitmap = new Bitmap(new BitmapData(Math.floor(bmpdWidth), Math.floor(bmpdHeight), true, 0));

            addChild(scratchPadBG);
            addChild(scratchPadBitmap);
            addChild(scratchPadDraw);
            addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, pickColor);

            name = "scratchPad";

            this.width = Math.floor(bmpdWidth * scratchPadZoom);
            this.height = Math.floor(bmpdHeight * scratchPadZoom);
            scrollRect = new Rectangle(0, 0, bmpdWidth - 1, bmpdHeight - 1);
        }

        public function pickerColor(borderColorFunc:Function):uint
        {
            if (scratchPadBitmap.bitmapData)
            {
                const bgBmpd:BitmapData = new BitmapData(1, 1, true, 0xFF000000 | scratchPadBGColor);
                var color:uint = scratchPadBitmap.bitmapData.getPixel32(scratchPadBitmap.mouseX, scratchPadBitmap.mouseY);
                const tmpBmpd:BitmapData = new BitmapData(1, 1, true, 0);
                tmpBmpd.setPixel32(0, 0, color);
                bgBmpd.draw(tmpBmpd);
                color = bgBmpd.getPixel(0, 0);

                const lineSize:Number = 1 / scratchPadZoom;
                scratchPadDraw.graphics.clear();
                scratchPadDraw.graphics.lineStyle(lineSize, borderColorFunc(color, 0) <= 40 ? 0xFFFFFF : 0);
                scratchPadDraw.graphics.drawRect(Math.floor(scratchPadBitmap.mouseX), Math.floor(scratchPadBitmap.mouseY), 1, 1);

                // clearTimeout(scratcthPadDrawClearTimer);
                // scratcthPadDrawClearTimer = setTimeout(function():void
                // {
                // scratcthPadDrawClearTimer = -1;
                // scratchPadDraw.graphics.clear();
                // }, 1000);

                if (color === 0)
                {
                    return color;
                }
                return color;
            }

            return 0;
        }

        public function updateBGColor(bgColor:uint):void
        {
            if (scratchPadBitmap)
            {
                scratchPadBGColor = bgColor;
                scratchPadBG.graphics.clear();
                scratchPadBG.graphics.beginFill(bgColor);
                scratchPadBG.graphics.drawRect(0, 0, scratchPadBitmap.width, scratchPadBitmap.height);
                scratchPadBG.graphics.endFill();
            }
        }

        public function setLineStyle(linseSize:Number, lineColor:uint, lineAlpha:Number, sqShape:Boolean):void
        {
            linseSize /= scratchPadZoom;
            if (linseSize < 1)
            {
                linseSize = 1.0;
            }
            // if (scratcthPadDrawClearTimer !== 0)
            // {
            //     clearTimeout(scratcthPadDrawClearTimer);
            // }

            scratchPadDraw.graphics.clear();

            if (sqShape)
            {
                scratchPadDraw.graphics.lineStyle(linseSize, lineColor, lineAlpha, false, LineScaleMode.NORMAL, CapsStyle.SQUARE, JointStyle.BEVEL);
            }
            else
            {
                scratchPadDraw.graphics.lineStyle(linseSize, lineColor, lineAlpha);
            }
        }

        public function clearPad():void
        {
            if (!isPadCleared)
            {
                isPadCleared = true;
                if (scratchPadBitmap.bitmapData != null)
                {
                    scratchPadBitmap.bitmapData.fillRect(scratchPadBitmap.bitmapData.rect, 0);
                }
            }
        }

        public function pickColor(e:MouseEvent):void
        {
            var color:uint = scratchPadBitmap.bitmapData.getPixel(scratchPadBitmap.mouseX, scratchPadBitmap.mouseY);
        }

        public function startDraw():void
        {
            scratchPadDraw.graphics.moveTo(scratchPadBitmap.mouseX, scratchPadBitmap.mouseY);

            stage.addEventListener(MouseEvent.MOUSE_MOVE, drawing);
            stage.addEventListener(MouseEvent.MOUSE_UP, stopDraw);
        }

        private function drawing(e:MouseEvent):void
        {
            scratchPadDraw.graphics.lineTo(scratchPadBitmap.mouseX, scratchPadBitmap.mouseY);
        }

        private function stopDraw(e:MouseEvent):void
        {
            isPadCleared = false;
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, drawing);
            stage.removeEventListener(MouseEvent.MOUSE_UP, stopDraw);
            scratchPadBitmap.bitmapData.draw(scratchPadDraw);
            scratchPadDraw.graphics.clear();
        }

        public function getBitmapData():BitmapData
        {
            return scratchPadBitmap.bitmapData;
        }
    }
}