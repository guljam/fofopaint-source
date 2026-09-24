package Modules
{
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Stage;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;
    import flash.geom.ColorTransform;

    public class Utils
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }
        
        //요소 colortransform바꾸기
        public static function setColorTransform(target:DisplayObject, color:uint, customAlpha:Number = NaN):void
        {
            if (!target)
            {
                return;
            }

            const alphaSave:Number = (isNaN(customAlpha)) ? target.alpha : customAlpha;
            const c:ColorTransform = target.transform.colorTransform;
            c.color = color;
            c.alphaMultiplier = alphaSave;
            target.transform.colorTransform = c;
        }

        // 보여준후 천천히 알파값감소로 사라지게 하기
        public static function showDisplayTargetAndFadeOut(target:DisplayObject, startAlpha:Number = 1.0, waitDuration:Number = 0.0):void
        {
            target.alpha = startAlpha;
            target.visible = true;
            const startTime:int = getTimer() + waitDuration * 1000;
            FOFOTimer.addByName("alphaFadeOutTimer_" + target.name, 0.0, true, function ():Boolean
                {
                    if (getTimer() < startTime)
                    {
                        return true;
                    }
                    if (target.visible === false)
                    {
                        return false;
                    }
                    target.alpha -= 0.1;
                    if (target.alpha < 0.0)
                    {
                        target.visible = false;
                        target.alpha = 1.0;
                        return false;
                    }
                    return true;
                });
        }

        // stage를 기준으로 사각형 꼭지점들 구하기
        // 회전이나 기준점 상관없이 보이는 그대로 리턴함
        public static function getBoundRect(ent:DisplayObject):Object
        {
            const b:Rectangle = ent.getBounds(main.stage);
            const tl:Point = b.topLeft;
            const br:Point = b.bottomRight;
            const tlx:Number = tl.x;
            const tly:Number = tl.y;
            const brx:Number = br.x;
            const bry:Number = br.y;
            const o:Object = {
                    left: tlx,
                    top: tly,
                    right: brx,
                    bottom: bry
                };
            return o;
        }

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
            const stage:Stage = main.stage;
            var clickX:Number = stage.mouseX;
            var clickY:Number = stage.mouseY;
            var scale:Number = Math.abs(sc);
            var mxLastPos:Number;
            var myLastPos:Number;
            var moveFlag:int;

            return function (mx:Number, my:Number):Number
            {
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
            var oldX:Number = target.x;
            var oldY:Number = target.y;
            var mx:Number = main.stage.mouseX;
            var my:Number = main.stage.mouseY;
            const zoom:Number = CanvasController.canvasZoomMultipler;
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

        public static function traceTree(data:*):void
        {
            var visited:Dictionary = new Dictionary(true);
            trace("--- TREE START ---");
            if (data is Array)
            {
                visited[data] = true;
                trace("[root] Array[" + (data as Array).length + "]");
                printTreeChildren(data, "", visited, 0);
            }
            else
            {
                printTreeNode(data, "", "root", true, visited, 0);
            }
            trace("--- TREE END ---");
        }

        private static var printTreeChildrenLinesLimit:int = 0;

        private static function printTreeChildren(container:*, prefix:String, visited:Dictionary, depth:int):void
        {
            if (depth > 20 || printTreeChildrenLinesLimit > 5000)
            {
                trace(prefix + "... (생략)");
                return;
            }

            if (container is Array)
            {
                var arr:Array = container as Array;
                for (var i:int = 0;i < arr.length;i++)
                {
                    var isLast:Boolean = (i == arr.length - 1);
                    printTreeNode(arr[i], prefix, "[" + i + "]", isLast, visited, depth);
                }
            }
            else if (container is Dictionary)
            {
                var keys:Array = [];
                for (var k:* in container)
                    keys.push(k);
                for (var d:int = 0;d < keys.length;d++)
                {
                    var dLast:Boolean = (d == keys.length - 1);
                    printTreeNode(container[keys[d]], prefix, String(keys[d]), dLast, visited, depth);
                }
            }
            else
            {
                // 일반 Object ({size} 등)
                var names:Array = [];
                for (var n:String in container)
                    names.push(n);
                // primitive만 있으면 한 줄로
                var onlyPrimitive:Boolean = true;
                for (var p:int = 0;p < names.length;p++)
                {
                    var v:* = container[names[p]];
                    if (v !== null && typeof v == "object")
                    {
                        onlyPrimitive = false;
                        break;
                    }
                }
                if (onlyPrimitive)
                    return; // 호출측에서 이미 한 줄 출력함
                for (var q:int = 0;q < names.length;q++)
                {
                    var qLast:Boolean = (q == names.length - 1);
                    printTreeNode(container[names[q]], prefix, names[q], qLast, visited, depth);
                }
            }
        }

        private static function printTreeNode(value:*, prefix:String, label:String, isLast:Boolean, visited:Dictionary, depth:int):void
        {
            printTreeChildrenLinesLimit++;
            if (printTreeChildrenLinesLimit > 5000)
                return;
            var branch:String = isLast ? "└─ " : "├─ ";
            var childPrefix:String = prefix + (isLast ? "   " : "│  ");

            if (value === null || value === undefined)
            {
                trace(prefix + branch + label + " : null");
                return;
            }
            if (value is Array)
            {
                if (visited[value])
                {
                    trace(prefix + branch + label + " : [자기참조 Array]");
                    return;
                }
                visited[value] = true;
                trace(prefix + branch + label + " Array[" + (value as Array).length + "]");
                printTreeChildren(value, childPrefix, visited, depth + 1);
                return;
            }
            if (typeof value == "object")
            {
                if (visited[value])
                {
                    trace(prefix + branch + label + " : [자기참조 Object]");
                    return;
                }
                visited[value] = true;
                // {size:123} 같은 파일은 한 줄로
                var parts:Array = [];
                for (var f:String in value)
                {
                    var fv:* = value[f];
                    if (fv === null || typeof fv != "object")
                        parts.push(f + "=" + fv);
                }
                if (parts.length > 0)
                {
                    trace(prefix + branch + label + " {" + parts.join(", ") + "}");
                    // object 안에 object가 섞여 있으면 하위로 전개
                    for (var g:String in value)
                    {
                        var gv:* = value[g];
                        if (gv !== null && typeof gv == "object" && !(gv is Array))
                        {
                            // 파일 객체 안의 중첩은 드묾, 필요시 전개
                        }
                    }
                }
                else
                {
                    trace(prefix + branch + label + " Object");
                    printTreeChildren(value, childPrefix, visited, depth + 1);
                }
                return;
            }
            trace(prefix + branch + label + " : " + value);
        }
    }
}
