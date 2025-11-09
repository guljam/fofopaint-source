package
{
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import flash.geom.Point;

    public class DrawrScratchPad extends Sprite
    {
        private const scratchPadDraw:Shape = new Shape();
        private var scratchPadBitmap:Bitmap;
        private const scratchPadBG:Shape = new Shape();
        private var scratchPadBGColor:uint = 0;
        private const scratchPadZoom:Number = 18;
        private var isPadCleared:Boolean = false;
        private const startPos:Point = new Point();
        private const nowPos:Point = new Point();
        public var isScratchStarted:Boolean = false;
        private var lineStyleData:Array = [];
        public var mainPickColorFunc:Function;
        private var scratchStartCount:int = 0;

        public function DrawrScratchPad(bmpdWidth:Number, bmpdHeight:Number):void
        {
            bmpdWidth = bmpdWidth / scratchPadZoom;
            bmpdHeight = bmpdHeight / scratchPadZoom;
            scratchPadBitmap = new Bitmap(new BitmapData(Math.floor(bmpdWidth), Math.floor(bmpdHeight), true, 0));

            addChild(scratchPadBG);
            addChild(scratchPadBitmap);
            addChild(scratchPadDraw);
            this.width = Math.floor(bmpdWidth * scratchPadZoom);
            this.height = Math.floor(bmpdHeight * scratchPadZoom);
            scrollRect = new Rectangle(0, 0, bmpdWidth, bmpdHeight);

            this.name = "scratchPad";
        }

        public function pickColor():uint
        {
            if (scratchPadBitmap.bitmapData)
            {
                const bgBmpd:BitmapData = new BitmapData(1, 1, true, 0xFF000000 | scratchPadBGColor);
                var color:uint = scratchPadBitmap.bitmapData.getPixel32(scratchPadBitmap.mouseX, scratchPadBitmap.mouseY);
                const tmpBmpd:BitmapData = new BitmapData(1, 1, true, 0);
                tmpBmpd.setPixel32(0, 0, color);
                bgBmpd.draw(tmpBmpd);
                color = bgBmpd.getPixel(0, 0);

                scratchPadDraw.graphics.clear();
                scratchPadDraw.graphics.lineStyle(1 / scratchPadZoom, Global.getColorDifferenceForHuman(color, 0) <= 40 ? 0xFFFFFF : 0);
                scratchPadDraw.graphics.drawRect(Math.floor(scratchPadBitmap.mouseX), Math.floor(scratchPadBitmap.mouseY), 1, 1);

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

        public function removeCheckMouseDistEvent():void
        {
            onMouseUpStopDrawLine(null);
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveScratchPad);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpScratchPad);
        }

        public function onMouseUpScratchPad(e:MouseEvent):void
        {
            if (Math.floor(scratchPadBitmap.mouseX) === Math.floor(startPos.x) && Math.floor(scratchPadBitmap.mouseY) === Math.floor(startPos.y))
            {
                if (mainPickColorFunc !== null)
                {
                    mainPickColorFunc(pickColor());
                }
            }

            isScratchStarted = false;
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveScratchPad);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpScratchPad);
        }

        public function onMouseMoveScratchPad(e:MouseEvent):void
        {
            scratchStartCount++;

            nowPos.setTo(scratchPadBitmap.mouseX, scratchPadBitmap.mouseY);

            if (Point.distance(startPos, nowPos) >= 1.0 || scratchStartCount >= 10)
            {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveScratchPad);
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpScratchPad);

                scratchPadDraw.graphics.clear();
                scratchPadDraw.graphics.lineStyle(1.0, lineStyleData[0], lineStyleData[1]);
                scratchPadDraw.graphics.moveTo(startPos.x, startPos.y);

                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveDrawLine);
                stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpStopDrawLine);
            }
        }

        public function drawReady(lineSize:Number, lineColor:uint, lineAlpha:Number, sqShape:Boolean, pickColorFunc:Function):void
        {
            if (mainPickColorFunc === null)
            {
                mainPickColorFunc = pickColorFunc;
            }

            if (isScratchStarted === false)
            {
                scratchStartCount = 0;
                isScratchStarted = true;
                lineStyleData[0] = lineColor;
                lineStyleData[1] = lineAlpha;
                startPos.setTo(scratchPadBitmap.mouseX, scratchPadBitmap.mouseY);
                stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveScratchPad);
                stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpScratchPad);
            }
        }

        private function onMouseMoveDrawLine(e:MouseEvent):void
        {
            scratchPadDraw.graphics.lineTo(scratchPadBitmap.mouseX, scratchPadBitmap.mouseY);
        }

        private function onMouseUpStopDrawLine(e:MouseEvent):void
        {
            isScratchStarted = false;
            isPadCleared = false;
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveDrawLine);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpStopDrawLine);
            scratchPadBitmap.bitmapData.draw(scratchPadDraw);
            scratchPadDraw.graphics.clear();
        }

        public function getBitmapData():BitmapData
        {
            return scratchPadBitmap.bitmapData;
        }
    }
}