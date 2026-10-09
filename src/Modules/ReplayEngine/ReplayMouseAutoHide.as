package Modules.ReplayEngine
{
    import Modules.MouseState;

    import flash.geom.Point;
    import flash.ui.Mouse;
    import flash.display.Stage;
    import Modules.L5App.ReplayEngine.ReplayController;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L2Engine.ReplayEngine.ReplayState;

    // 리플레이 재생중 마우스가 가만히 있으면 시스템 마우스 포인터를 숨김
    // 층: L4 UI - 리플레이 재생 중 마우스가 가만히 있으면 포인터 숨김
    public class ReplayMouseAutoHide
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
            frameRate = main.stage.frameRate;
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
            return pos.x !== main.stage.mouseX || pos.y !== main.stage.mouseY || MouseState.isLeftDown || MouseState.isRightDown;
        }

        private static function updateMousePos():void
        {
            pos.setTo(main.stage.mouseX, main.stage.mouseY);
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
                        ReplayController.hideTopbarOnPlayback();
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
