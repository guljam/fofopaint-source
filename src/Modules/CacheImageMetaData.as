package Modules
{
    import flash.display.BitmapData;
    import flash.geom.Point;

    public class CacheImageMetaData
    {
        public var bmpdWidth:Number;
        public var bmpdHeight:Number;
        public var bgColor:uint;
        public var lastByte:Number;
        public var lastFrame:Number;
        public var nowFrame:Number;
        public var mirrorFlag:Boolean;
        public var rCursorPosX:Number;
        public var rCursorPosY:Number;

        public function CacheImageMetaData
            (
                /*
                drawCacheImageFirst 함수에서 cachedImageData = fs.readObject() as Array;
                호출해줄때 alias에 등록된 CacheImageMetaData함수를 먼저 생성해주는데 매개변수 없이 생성해줘서 기본값을 넣어주어야한다고 함
                - gpt6
                */
                bmpdWidth:Number = 0,
                bmpdHeight:Number = 0,
                bgColor:uint = 0,
                lastByte:Number = 0.0,
                lastFrame:Number = 0.0,
                nowFrame:Number = 0.0,
                mirrorFlag:Boolean = false,
                rCursorPosX:Number = NaN,
                rCursorPosY:Number = NaN
            )
        {
            if(isNaN(rCursorPosX) || isNaN(rCursorPosY))
            {
                const lastRCursorPos:Point = ReplayDrawCommands.getRCursorPos();
                rCursorPosX = lastRCursorPos.x;
                rCursorPosY = lastRCursorPos.y;
            }

            this.bmpdWidth = bmpdWidth;
            this.bmpdHeight = bmpdHeight;
            this.bgColor = bgColor;
            this.lastByte = lastByte;
            this.lastFrame = lastFrame;
            this.nowFrame = nowFrame;
            this.mirrorFlag = mirrorFlag;
            this.rCursorPosX = rCursorPosX;
            this.rCursorPosY = rCursorPosY;
        }
    }
}
