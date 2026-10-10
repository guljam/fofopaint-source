package Modules.L4UI.ReplayEngine
{
    import Modules.L1Data.AppContext;

    import flash.geom.Point;
    import flash.ui.Mouse;
    import flash.display.Stage;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L2Engine.ReplayEngine.ReplayState;
    import Modules.L1Data.MouseState;
    import Modules.L1Data.FOFOTimer;

    // 리플레이 재생중 마우스가 가만히 있으면 시스템 마우스 포인터를 숨김
    // 층: L4 UI - 리플레이 재생 중 마우스가 가만히 있으면 포인터 숨김
    public class ReplayMouseAutoHide
    {
        // 리플레이 재생 중 상단 바를 숨겨야 한다는 보고
        public static var onReplayTopbarHiddenFunc:Function;

        public static function initialize():void
        {
            frameRate = AppContext.stage.frameRate;
        }

        private static const TIMER_NAME:String = "replayHideCursorCheckTimer";
        private static var frameRate:Number = 0;

        private static var _isMouseHided:Boolean = false;
        private static var count:int = 0;
        private static const pos:Point = new Point(0, 0);

        public static function get isMouseHided():Boolean
        {
            return _isMouseHided;
        }

        public static function start():void
        {
            if (FOFOTimer.hasTimer(TIMER_NAME))
            {
                return;
            }

            FOFOTimer.addByName(TIMER_NAME, 0.0, true, function ():Boolean
                {
                    if (!ReplayState.isReplayModeON)
                    {
                        showMouse();
                        return false;
                    }

                    check();
                    return true;
                });
        }

        private static function isMouseMoved():Boolean
        {
            return pos.x !== AppContext.stage.mouseX || pos.y !== AppContext.stage.mouseY || MouseState.isLeftDown || MouseState.isRightDown;
        }

        private static function updateMousePos():void
        {
            pos.setTo(AppContext.stage.mouseX, AppContext.stage.mouseY);
        }

        private static function showMouse():void
        {
            Mouse.show();
            _isMouseHided = false;
            count = 0;
        }

        private static function check():void
        {
            if (_isMouseHided)
            {
                if (isMouseMoved())
                {
                    count = 0;
                    showMouse();
                }
            }
            else
            {
                if (count > frameRate)
                {
                    count = frameRate;

                    if (!HintController.isHighlightBoxVisible())
                    {
                        Mouse.hide();
                        _isMouseHided = true;
                        updateMousePos();
                    }
                }
                else
                {
                    count++;
                }

                if (isMouseMoved())
                {
                    count = 0;
                }

                updateMousePos();
            }
        }
    }
}
