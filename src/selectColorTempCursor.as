package
{
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.Stage;
    import flash.events.Event;
    import flash.utils.setTimeout;
    import flash.utils.Timer;
    import flash.events.TimerEvent;

    public class selectColorTempCursor extends Sprite
    {

        public static function active(stage:Stage):void
        {
            const circle:Shape = new Shape();
            var cursor:selectColorTempCursor = new selectColorTempCursor();

            circle.graphics.lineStyle(15, 0x000000);
            circle.graphics.drawCircle(0, 0, 70);
            cursor.addChild(circle);
            cursor.x = stage.mouseX;
            cursor.y = stage.mouseY;
            stage.addChild(cursor);

            cursor.addEventListener(Event.ENTER_FRAME, function(e:Event):void
            {
                cursor.x = stage.mouseX;
                cursor.y = stage.mouseY;
            });

            setTimeout(function():void
            {
                var fadeOut:Timer = new Timer(10, 0);
                fadeOut.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void
                {
                    cursor.alpha -= 0.05;
                    if (cursor.alpha <= 0)
                    {
                    fadeOut.stop();
                    fadeOut.removeEventListener(TimerEvent.TIMER, arguments.callee);
                    stage.removeChild(cursor);
                    }
                });
                fadeOut.start();
            }, 300);
        }

        public function selectColorTempCursor()
        {

        }
    }
}