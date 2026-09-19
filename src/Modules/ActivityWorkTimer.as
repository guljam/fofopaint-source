package Modules
{
    import flash.utils.Timer;
    import flash.utils.getTimer;
    import flash.events.TimerEvent;

    public class ActivityWorkTimer
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static var workTimer:Timer = new Timer(1000);
        private static var totalWorkTime:int = 0;
        private static var lastWorkTime:int = 0; // 마지막 시간 저장해줌

        // 총 앱 시간
        private static var lastAppUpTime:int = 0; // 1초 단위임 worktime는 밀리초 단위이므로 계산할때주의
        // 시간 표시 관련 변수
        private static var tt:int;
        private static var hh:int;
        private static var mm:int;
        private static var ss:int;
        private static var lastMousePosX:Number = 0;
        private static var lastMousePosY:Number = 0;

        public static function reset():void
        {
            lastWorkTime = getTimer();
            lastAppUpTime += lastWorkTime / 1000;
            totalWorkTime = 0;
            MainUI.topBar.timer.text = "00:00:00";
            MainUI.topBar.updateTimerPos(main.stage.stageWidth);
        }

        public static function setRunningTime(newTime:int):void
        {
            totalWorkTime = newTime;
        }

        public static function getRunningTime():int
        {
            return totalWorkTime;
        }

        public static function updateAppUpTime(time:int):void
        {
            lastAppUpTime = time;
            trace('update app up time ', lastAppUpTime);
        }

        public static function getAppUpTime():int
        {
            return lastAppUpTime += getTimer() / 1000;
        }

        public static function getFormattedAppUpTimeString():String
        {
            var appUpTime:int = lastAppUpTime + 3761+ getTimer() / 1000;

            if (appUpTime < 0)
            {
                appUpTime = 0;
            }

            const hours:int = Math.floor(appUpTime / 3600);
            const minutes:int = Math.floor((appUpTime % 3600) / 60);

            return hours + ((hours === 1) ? " hour, " : " hours, ")
                + minutes + ((minutes === 1) ? " min" : " mins");
        }

        private static function getFormattedWorkTime():String
        {
            if (totalWorkTime < 0)
            {
                totalWorkTime = 0;
            }

            tt = totalWorkTime / 1000;
            hh = Math.floor(tt / 3600);
            mm = Math.floor((tt - hh * 3600) / 60);
            ss = Math.floor(tt % 60);

            return ((hh < 10) ? "0" + hh : "" + hh)
                + ":" + ((mm < 10) ? "0" + mm : "" + mm)
                + ":" + ((ss < 10) ? "0" + ss : "" + ss);
        }

        public static function update():void
        {
            MainUI.topBar.timer.text = getFormattedWorkTime();
            MainUI.topBar.timerAFkDot.visible = false;
            MainUI.topBar.updateTimerPos(main.stage.stageWidth);
        }
        private static function onTimer(event:TimerEvent):Boolean
        {
            const nowTime:int = getTimer();
            const subTime:int = nowTime - lastWorkTime;
            if (!main.stage.nativeWindow.active
                    || (!CanvasController.isMouseLeftClicked && !CanvasController.isRightMouseClicked && !InputController.isKeyPressed()
                        && main.stage.mouseX === lastMousePosX && main.stage.mouseY === lastMousePosY))
            {
                MainUI.topBar.timerAFkDot.visible = !MainUI.topBar.timerAFkDot.visible;
                MainUI.topBar.updateTimerPos(main.stage.stageWidth);
            }
            else
            {
                totalWorkTime += subTime;
                update();
            }
            lastMousePosX = main.stage.mouseX;
            lastMousePosY = main.stage.mouseY;
            lastWorkTime = nowTime;
            return true;
        }
        public static function stop():void
        {
            if (workTimer !== null)
            {
                workTimer.stop();
                workTimer.removeEventListener(TimerEvent.TIMER, onTimer);
                workTimer = null;
            }
        }
        public static function start():void
        {
            workTimer.addEventListener(TimerEvent.TIMER, onTimer);
            workTimer.start();
        }
    }
}
