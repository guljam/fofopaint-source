package main_module
{
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.geom.Point;
    import flash.display.Stage;

    public class Utils
    {
        // 객체의 alpha값이 8비트int로 변환된후 다시 Number로 변환되기 때문에 실제 소수점 비교를 할때도 같은 방식을 써주어야함
        public static function normalizeAlphaValue(alp:Number):Number
        {
            return Math.round(alp * 256) / 256;
        }

        // 0,0을 기준으로 점tx,ty를 rad만큼 회전함,
        // 3시 방향이 0도이고, 반시계 방향이 양수값임.
        public static function rotatePoint(tx:Number, ty:Number, deg:Number):Point
        {
            const rad:Number = -(deg / 180) * Math.PI;
            const cosO:Number = Math.cos(rad);
            const sinO:Number = Math.sin(rad);
            const rp:Point = new Point(tx * cosO - ty * sinO, tx * sinO + ty * cosO);

            return rp;
        }

        public static function setAsTopChild(target:DisplayObject):void
        {
            const parent:DisplayObjectContainer = target.parent as DisplayObjectContainer;

            if (parent === null)
            {
                return;
            }

            if (parent.getChildIndex(target) === parent.numChildren - 1)
            {
                return;
            }

            parent.setChildIndex(target, parent.numChildren - 1);
        }

        public static function updateImageScaleMouseDrag(sc:Number):Function
        {
            const stage:Stage = Main._instance.stage;
            var clickX:Number = stage.mouseX;
            var clickY:Number = stage.mouseY;
            var scale:Number = Math.abs(sc);
            var mxLastPos:Number;
            var myLastPos:Number;
            var moveFlag:int;

            return function (mx:Number, my:Number):Number
            {
                const main:Main = Main._instance;
                if (moveFlag != 0)
                {
                    if (moveFlag === 1)
                    {
                        const subX:Number = mx - mxLastPos;

                        if (subX !== 0) // 차이가 0이 될때가 있어서 이건 스킵
                        {
                            scale *= Math.pow(2, subX * 0.008);
                            ReferenceLayerController.refLayerMenuDragXMoveSum += subX;
                        }
                    }
                    else if (moveFlag === 2)
                    {
                        const subY:Number = myLastPos - my;

                        if (subY !== 0)
                        {
                            scale *= Math.pow(2, subY * 0.008);
                            ReferenceLayerController.refLayerMenuDragXMoveSum += subY;
                        }
                    }
                }
                else if (moveFlag === 0)
                {
                    if (Math.abs(mx - clickX) > 5)
                    {
                        moveFlag = 1;
                    }
                    else if (Math.abs(my - clickY) > 5)
                    {
                        moveFlag = 2;
                    }
                }

                mxLastPos = mx;
                myLastPos = my;

                if (scale > 4.0)
                {
                    scale = 4.0;
                }
                else if (scale < 0.1)
                {
                    scale = 0.1;
                }

                return scale;
            };
        }

        public static function updateImagePosMouseDrag(target:DisplayObject, targetAngle:Number, customScaleX:Number = 1.0, customScaleY:Number = 1.0):Function
        {
            const main:Main = Main._instance;

            var oldX:Number = target.x;
            var oldY:Number = target.y;
            var mx:Number = main.stage.mouseX;
            var my:Number = main.stage.mouseY;
            const zoom:Number = main.canvasZoomMultipler;
            const angle:Number = targetAngle;

            return function ():Point
            {
                const dx:Number = main.stage.mouseX - mx;
                const dy:Number = main.stage.mouseY - my;
                const newPos:Point = Utils.rotatePoint(dx, dy, angle);

                newPos.setTo(oldX + newPos.x / zoom / customScaleX, oldY + newPos.y / zoom / customScaleY);

                return newPos;
            };
        }

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
