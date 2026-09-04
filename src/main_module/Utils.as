package main_module
{
    import flash.display.DisplayObject;

    public class Utils
    {
        public static function binarySearchIndex(list:Array, target:Number, valueExtractor:Function):int
        {
            var low:int = 0;
            var high:int = list.length - 1;
            if (high <= 0)
            {
                return high;
            }

            var index:int = Math.floor((low + high) / 2);

            while (low <= high)
            {
                var value:Number = valueExtractor(list[index]);

                if (value === target)
                {
                    break;
                }
                else if (value > target)
                {
                    high = index - 1;
                }
                else
                {
                    low = index + 1;
                }

                index = Math.floor((low + high) / 2);
            }

            return index;
        }

        public static function getRandomString(charLength:int = 6):String
        {
            const chars:String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            const charsLen:uint = chars.length;
            var randomString:String = "";
            var index:int;

            while (charLength > 0)
            {
                index = Math.floor(charsLen * Math.random());
                randomString += chars.charAt(index);
                charLength--;
            }

            return randomString;
        }

        public static function calculateSliderValueFromMouseX(mousex:Number, minx:Number, maxx:Number, minvalue:Number, maxvalue:Number, cursor:DisplayObject):Number
        {
            if (mousex < minx)
            {
                mousex = minx;
            }
            else if (mousex > maxx)
            {
                mousex = maxx;
            }

            const per:Number = (mousex - minx) / (maxx - minx);
            const value:Number = minvalue + (maxvalue - minvalue) * per;

            if (cursor !== null)
            {
                cursor.x = mousex;
            }

            return value;
        }

    }
}
