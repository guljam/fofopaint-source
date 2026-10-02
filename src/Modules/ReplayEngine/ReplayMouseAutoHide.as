package Modules.ReplayEngine
{
    import Modules.MouseState;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;

    import flash.geom.Point;
    import flash.ui.Mouse;

    // 리플레이 재생중 마우스가 가만히 있으면 시스템 마우스 포인터를 숨김
    public class ReplayMouseAutoHide
    {
        private static const TIMER_NAME:String = "replayHideCursorCheckTimer";

        private static var isMouseHided:Boolean = false;
        private static var count:int = 0;
        private static const pos:Point = new Point(0, 0);

        public static function start():void
        {
            if (FOFOTimer.hasTimer(TIMER_NAME))
            {
                return;
            }

            FOFOTimer.addByName(TIMER_NAME, 0.0, true, function ():Boolean
                {
                    if (!ReplayState.isReplayModeON || UIController.topBar.visible)
                    {
                        show();
                        return false;
                    }

                    check();
                    return true;
                });
        }

        private static function isMouseMoved():Boolean
        {
            return pos.x !== ReplayController.main.stage.mouseX || pos.y !== ReplayController.main.stage.mouseY || MouseState.isLeftDown || MouseState.isRightDown;
        }

        private static function updateMousePos():void
        {
            pos.setTo(ReplayController.main.stage.mouseX, ReplayController.main.stage.mouseY);
        }

        private static function show():void
        {
            Mouse.show();
            isMouseHided = false;
            count = 0;
        }

        private static function check():void
        {
            const frameRate:Number = ReplayController.main.stage.frameRate;

            if (isMouseHided)
            {
                if (isMouseMoved())
                {
                    count = 0;
                    show();
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
                        HintController.hideBottomHint();
                        isMouseHided = true;
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
