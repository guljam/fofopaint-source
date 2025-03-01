package
{
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import flash.geom.Point;

    public class drawrScratchPad extends Sprite
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
        public var pickColorBorderFunc:Function;
        private var scratchStartCount:int = 0;
        private const scratchStartNow:int = 20;

        public function drawrScratchPad(bmpdWidth:Number, bmpdHeight:Number):void
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
                scratchPadDraw.graphics.lineStyle(1 / scratchPadZoom,pickColorBorderFunc(color, 0) <= 40 ? 0xFFFFFF : 0);
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

        public function setLineStyle(linseSize:Number, lineColor:uint, lineAlpha:Number, sqShape:Boolean):void
        {
            linseSize /= scratchPadZoom;
            if (linseSize < 1)
            {
                linseSize = 1.0;
            }
            // if (scratcthPadDrawClearTimer !== 0)
            // {
            // clearTimeout(scratcthPadDrawClearTimer);
            // }

            scratchPadDraw.graphics.clear();

            // if (sqShape)
            // {
            //     scratchPadDraw.graphics.lineStyle(1.0, lineColor, lineAlpha, false, LineScaleMode.NORMAL, CapsStyle.SQUARE, JointStyle.BEVEL);
            // }
            // else
            // {
            // }
            scratchPadDraw.graphics.lineStyle(1.0, lineColor, lineAlpha);
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
            stopDraw(null);
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, checkMouseDistMouseMove);
            stage.removeEventListener(MouseEvent.MOUSE_UP, checkMouseDistMouseUp);
        }

        public function checkMouseDistMouseUp(e:MouseEvent):void
        {
            scratchStartCount = 0;
            if (Math.floor(scratchPadBitmap.mouseX) === Math.floor(startPos.x) && Math.floor(scratchPadBitmap.mouseY) === Math.floor(startPos.y))
            {
                if(mainPickColorFunc !== null)
                {
                    mainPickColorFunc(pickColor());
                }
            }

            isScratchStarted = false;
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, checkMouseDistMouseMove);
            stage.removeEventListener(MouseEvent.MOUSE_UP, checkMouseDistMouseUp);
        }

        public function checkMouseDistMouseMove(e:MouseEvent):void
        {
            scratchStartCount++;
            nowPos.setTo(scratchPadBitmap.mouseX, scratchPadBitmap.mouseY);
            if (Point.distance(startPos, nowPos) >= 1.0 || scratchStartCount >= scratchStartNow)
            {
                scratchStartCount = 0;
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, checkMouseDistMouseMove);
                stage.removeEventListener(MouseEvent.MOUSE_UP, checkMouseDistMouseUp);
                setLineStyle(lineStyleData[0], lineStyleData[1], lineStyleData[2], lineStyleData[3]);
                startDraw();
            }
        }

        public function drawReady(lineSize:Number, lineColor:uint, lineAlpha:Number, sqShape:Boolean,pickColorFunc:Function,rectColorFunc:Function):void
        {
            if(mainPickColorFunc === null)
            {
                mainPickColorFunc = pickColorFunc;
            }

            if(pickColorBorderFunc === null)
            {
                pickColorBorderFunc = rectColorFunc;
            }

            if (isScratchStarted === false)
            {
                isScratchStarted = true;
                lineStyleData[0] = lineSize;
                lineStyleData[1] = lineColor;
                lineStyleData[2] = lineAlpha;
                lineStyleData[3] = sqShape;
                startPos.setTo(scratchPadBitmap.mouseX, scratchPadBitmap.mouseY);
                stage.addEventListener(MouseEvent.MOUSE_MOVE, checkMouseDistMouseMove);
                stage.addEventListener(MouseEvent.MOUSE_UP, checkMouseDistMouseUp);
            }
        }

        public function startDraw():void
        {
            scratchPadDraw.graphics.moveTo(startPos.x, startPos.y);

            stage.addEventListener(MouseEvent.MOUSE_MOVE, drawing);
            stage.addEventListener(MouseEvent.MOUSE_UP, stopDraw);
        }

        private function drawing(e:MouseEvent):void
        {
            scratchPadDraw.graphics.lineTo(scratchPadBitmap.mouseX, scratchPadBitmap.mouseY);
        }

        private function stopDraw(e:MouseEvent):void
        {
            isScratchStarted = false;
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