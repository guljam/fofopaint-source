package
{
    import flash.display.DisplayObject;
    import flash.geom.Rectangle;
    import flash.display.Stage;

    public class HintScrolling
    {
        static private var instanceCount:int = 0;
        private var _target:DisplayObject;
        private var timerName:String;
        private var _stage:Stage;
        private var hintScrollWaitTimeSum:int = 0;
        private var hintMoveDirection:Boolean = true;
        private var hintMoveSpeed:Number = 2;

        private function resetVars():void
        {
            if (_target.x !== 0)
            {
                _target.x = 0;
            }
            hintScrollWaitTimeSum = 0;
            hintMoveDirection = true;
        }

        private function animateHintBounce():Boolean
        {
            if (_target.visible === false)
            {
                resetVars();
                return false;
            }

            const targetRect:Rectangle = _target.getBounds(_stage);
            const scale:Number = targetRect.width / _target.width;
            const targetWidth:Number = _target.width * scale;

            if (targetWidth > _stage.stageWidth)
            {
                if (hintScrollWaitTimeSum >= _stage.frameRate)
                {
                    if (hintMoveDirection)
                    {
                        if (targetRect.x + targetWidth > _stage.stageWidth)
                        {
                            _target.x = _target.x - hintMoveSpeed * scale;
                        }
                        else
                        {
                            hintMoveDirection = !hintMoveDirection;
                            hintScrollWaitTimeSum = 0;
                        }
                    }
                    else
                    {
                        if (targetRect.x < 0)
                        {
                            _target.x = _target.x + hintMoveSpeed * scale;
                        }
                        else
                        {
                            hintMoveDirection = !hintMoveDirection;
                            hintScrollWaitTimeSum = 0;
                        }
                    }
                }
                else
                {
                    hintScrollWaitTimeSum++;
                }
            }
            else
            {
                resetVars();
            }

            return true;
        }
        public function start():void
        {
            FOFOTimer.addByName(timerName, 0.0, true, animateHintBounce);
        }

        public function HintScrolling(target:HintBoxSet, stage:Stage)
        {
            timerName = "hintScrollTimer_" + instanceCount;
            _target = target;
            _stage = stage;
            instanceCount++;
        }
    }
}