package Modules.Tools
{
    import flash.display.Graphics;
    import flash.geom.Point;

    // 층: L3 기능 - 점선 그리기
    public class DottedLineTool
    {
        private static const lastDotPos:Point = new Point(0, 0);
        private static var dotLineLength:Number = 5;
        private static var subDotLength:Number;
        private static var startPos:Point = new Point(0, 0);
        private static var lastInterpPos:Point = new Point(0, 0);
        private static var lineSize:Number = 1;
        private static var dotLineColor:uint = 0;
        private static var graphics:Graphics;
        private static const nowPos:Point = new Point();
        private static const interpPoint:Point = new Point();

        public static function setLineScale(zoomed:Number):void
        {
            lineSize = 1 / zoomed;
            dotLineLength = 5 / zoomed;
        }

        private static function toggleLineColor():uint
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

        public static function drawClosingLine(g:Graphics, x:Number, y:Number):void
        {
            const savedGraphics:Graphics = graphics;
            const savedColor:uint = dotLineColor;
            const savedSub:Number = subDotLength;
            const savedDotX:Number = lastDotPos.x;
            const savedDotY:Number = lastDotPos.y;
            const savedInterpX:Number = lastInterpPos.x;
            const savedInterpY:Number = lastInterpPos.y;

            graphics = g;
            g.lineStyle(lineSize, dotLineColor, 1.0, false, "normal", "none");
            g.moveTo(lastInterpPos.x, lastInterpPos.y); // 새 Graphics는 펜 위치가 (0,0)이라 반드시 필요
            lineTo(x, y, true);

            graphics = savedGraphics;
            dotLineColor = savedColor;
            subDotLength = savedSub;
            lastDotPos.setTo(savedDotX, savedDotY);
            lastInterpPos.setTo(savedInterpX, savedInterpY);
        }

        public static function lineTo(x:Number, y:Number, closeLine:Boolean = false):void
        {
            nowPos.setTo(x, y);
            interpPoint.setTo(lastDotPos.x, lastDotPos.y);

            var dist:Number = Point.distance(lastDotPos, nowPos);
            // var interpPoint:Point = new Point(lastDotPos.x, lastDotPos.y);
            var ratio:Number;

            subDotLength -= dist;

            while (subDotLength < 0)
            {
                ratio = (dist - subDotLength) / dist - 1.0;
                interpPoint.setTo(nowPos.x + ratio * (interpPoint.x - nowPos.x),
                        nowPos.y + ratio * (interpPoint.y - nowPos.y));
                toggleLineColor();
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
