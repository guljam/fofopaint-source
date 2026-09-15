package Modules.Tools
{
    import flash.display.Graphics;
    import flash.geom.Point;

    public class DottedLineTool
    {
        private static const lastDotPos:Point = new Point(0, 0);
        private static var lastLineLength:Number = 0;
        private static var dotLineLength:Number = 5;
        private static var subDotLength:Number;
        private static var startPos:Point = new Point(0, 0);
        private static var lastInterpPos:Point = new Point(0, 0);
        private static var lineSize:Number = 1;
        private static var dotLineColor:uint = 0;
        private static var graphics:Graphics;

        public static function setLineScale(zoomed:Number):void
        {
            lineSize = 1 / zoomed;
            dotLineLength = 5 / zoomed;
        }
        private static function toggleLineColor(from:int):uint
        {
            if (dotLineColor === 0)
            {
                dotLineColor = 0xFFFFFF;
            }
            else
            {
                dotLineColor = 0;
            }
            return dotLineColor;
        }
        public static function moveTo(g:Graphics, x:Number, y:Number):void
        {
            graphics = g;
            dotLineColor = 0;
            subDotLength = dotLineLength;
            startPos.setTo(x, y);
            lastDotPos.setTo(x, y);
            lastInterpPos.setTo(x, y);
            graphics.lineStyle(lineSize, dotLineColor, 1.0, false, "normal", "none");
            graphics.moveTo(x, y);
        }
        public static function lineTo(x:Number, y:Number, closeLine:Boolean = false):void
        {
            const nowPos:Point = new Point(x, y);
            var dist:Number = Point.distance(lastDotPos, nowPos);
            var interpPoint:Point = new Point(lastDotPos.x, lastDotPos.y);
            var ratio:Number;
            subDotLength -= dist;
            while (subDotLength < 0)
            {
                ratio = (dist - subDotLength) / dist - 1.0;
                interpPoint = Point.interpolate(interpPoint, nowPos, ratio);
                toggleLineColor(1);
                graphics.lineStyle(lineSize, dotLineColor, 1.0, false, "normal", "none");
                graphics.moveTo(lastInterpPos.x, lastInterpPos.y);
                graphics.lineTo(interpPoint.x, interpPoint.y);
                lastInterpPos.setTo(interpPoint.x, interpPoint.y);
                dist = Point.distance(nowPos, interpPoint);
                subDotLength += dotLineLength;
            }
            if (closeLine)
            {
                graphics.lineTo(startPos.x, startPos.y);
            }
            lastDotPos.setTo(x, y);
        }
    }
}
