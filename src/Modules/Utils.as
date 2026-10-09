package Modules
{
    import Modules.DrawEngine.CanvasView;
    import Modules.UIEngine.UIController;
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Stage;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;
    import flash.geom.ColorTransform;
    import flash.display.SimpleButton;
    import avmplus.getQualifiedClassName;
    import Modules.ReplayEngine.ReplayController;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;

    // 층: L1 데이터 - 색 변환, 텍스트 필드 생성 등 공용 함수
    public class Utils
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static const ZERO_POINT:Point = new Point(0, 0);

        public static function createTextField(label:String, color:uint, size:Number):TextField
		{
			const field:TextField = new TextField();
			field.embedFonts = true;
			field.selectable = false;
			field.mouseEnabled = false;
			field.autoSize = TextFieldAutoSize.LEFT;
			field.defaultTextFormat = new TextFormat("Si Kancil", size, color);
			field.text = label;
			return field;
		}

        //커서가 드로우 영역에 있는지 검사
        public static function isCursorInDrawArea():Boolean
        {
            return !(UIController.topBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY)
                    || (SidebarController.sideBar.visible && SidebarController.sideBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                    || (ReplayController.seekBarBox.visible && ReplayController.seekBarBox.hitTestPoint(main.stage.mouseX, main.stage.mouseY)));
        }


        static private function RGBtoHSV(r:Number, g:Number, b:Number, baseHue:Number):Vector.<Number>
        {
            r = r / 255;
            g = g / 255;
            b = b / 255;

            const max:Number = Math.max(r, g, b);
            const min:Number = Math.min(r, g, b);
            var h:Number = 0;
            var s:Number = 0;
            var v:Number = max;
            const d:Number = max - min;

            s = (max == 0) ? 0 : d / max;

            if (max == min)
            {
                h = 0; // achromatic
            }
            else
            {
                if (max === r)
                    h = (g - b) / d + (g < b ? 6 : 0);
                else if (max === g)
                    h = (b - r) / d + 2;
                else if (max === b)
                    h = (r - g) / d + 4;

                h = h / 6;
            }

            const hsv:Vector.<Number> = new <Number>[h, s, v];
            if (s === 0)
                hsv[0] = baseHue;

            return hsv;
        }

        // hex에서 rgb vector 배열로 반환
        public static function HEXtoRGB(hex:uint):Vector.<Number>
        {
            const r:uint = (hex >> 16) & 0xFF;
            const g:uint = (hex >> 8) & 0xFF;
            const b:uint = hex & 0xFF;

            return new <Number>[r, g, b];
        }

        public static function HEXtoHSV(color:uint, baseHue:Number):Vector.<Number>
        {
            const r:uint = (color >> 16) & 0xFF;
            const g:uint = (color >> 8) & 0xFF;
            const b:uint = color & 0xFF;

            return RGBtoHSV(r, g, b, baseHue);
        }

        // rgb값을 16진수로 hex값으로 만들어줌
        public static function RGBtoHEX(r:uint, g:uint, b:uint):uint
        {
            return (r << 16 | g << 8 | b);
        }

        public static function HSVtoHEX(h:Number, s:Number, v:Number):uint
        {
            const rgb:Vector.<uint> = HSVtoRGB(h, s, v);
            return RGBtoHEX(rgb[0], rgb[1], rgb[2]);
        }

        // h s v는 0~1.0 사이값 넣어줘야함
        public static function HSVtoRGB(h:Number, s:Number, v:Number):Vector.<uint>
        {
            v = Math.round(v * 255);

            const i:Number = Math.floor(h * 6);
            const f:Number = h * 6 - i;
            const p:Number = Math.round(v * (1 - s));
            const q:Number = Math.round(v * (1 - f * s));
            const t:Number = Math.round(v * (1 - (1 - f) * s));

            switch (i)
            {
                case 6:
                case 0:
                    return new <uint>[v, t, p];
                case 1:
                    return new <uint>[q, v, p];
                case 2:
                    return new <uint>[p, v, t];
                case 3:
                    return new <uint>[p, q, v];
                case 4:
                    return new <uint>[t, p, v];
                case 5:
                    return new <uint>[v, p, q];
            }

            return new <uint>[0, 0, 0];
        }

        // 리턴값
        // <= 1.0    인간의 눈으로 인식 할 수 없음
        // 1 ~ 2    면밀한 관찰을 통해 인식 가능
        // 2 ~ 10    한눈에 알아볼 수 있음
        // 11-49    색상이 반대보다 비슷
        // 100        색상이 정반대
        public static function getColorDifferenceForHuman(rgbA:uint, rgbB:uint):Number
        {
            function rgb2lab(rgb:uint):Vector.<Number>
            {
                var _r:Number = ((rgb & 0xFF0000) >>> 16) / 255;
                var _g:Number = ((rgb & 0x00FF00) >>> 8) / 255;
                var _b:Number = ((rgb & 0x0000FF)) / 255;
                var _x:Number;
                var _y:Number;
                var _z:Number;

                _r = (_r > 0.04045) ? Math.pow((_r + 0.055) / 1.055, 2.4) : _r / 12.92;
                _g = (_g > 0.04045) ? Math.pow((_g + 0.055) / 1.055, 2.4) : _g / 12.92;
                _b = (_b > 0.04045) ? Math.pow((_b + 0.055) / 1.055, 2.4) : _b / 12.92;
                _x = (_r * 0.4124 + _g * 0.3576 + _b * 0.1805) / 0.95047;
                _y = (_r * 0.2126 + _g * 0.7152 + _b * 0.0722) / 1.00000;
                _z = (_r * 0.0193 + _g * 0.1192 + _b * 0.9505) / 1.08883;
                _x = (_x > 0.008856) ? Math.pow(_x, 1 / 3) : (7.787 * _x) + 16 / 116;
                _y = (_y > 0.008856) ? Math.pow(_y, 1 / 3) : (7.787 * _y) + 16 / 116;
                _z = (_z > 0.008856) ? Math.pow(_z, 1 / 3) : (7.787 * _z) + 16 / 116;

                const result:Vector.<Number> = new <Number>[(116 * _y) - 16, 500 * (_x - _y), 200 * (_y - _z)];

                return result;
            }

            const labA:Vector.<Number> = rgb2lab(rgbA);
            const labB:Vector.<Number> = rgb2lab(rgbB);
            const deltaL:Number = labA[0] - labB[0];
            const deltaA:Number = labA[1] - labB[1];
            const deltaB:Number = labA[2] - labB[2];
            const c1:Number = Math.sqrt(labA[1] * labA[1] + labA[2] * labA[2]);
            const c2:Number = Math.sqrt(labB[1] * labB[1] + labB[2] * labB[2]);
            const deltaC:Number = c1 - c2;
            var deltaH:Number = deltaA * deltaA + deltaB * deltaB - deltaC * deltaC;
            deltaH = deltaH < 0 ? 0 : Math.sqrt(deltaH);
            const sc:Number = 1.0 + 0.045 * c1;
            const sh:Number = 1.0 + 0.015 * c1;
            const deltaLKlsl:Number = deltaL / (1.0);
            const deltaCkcsc:Number = deltaC / (sc);
            const deltaHkhsh:Number = deltaH / (sh);
            const i:Number = deltaLKlsl * deltaLKlsl + deltaCkcsc * deltaCkcsc + deltaHkhsh * deltaHkhsh;

            return i < 0 ? 0 : Math.sqrt(i);
        }

        // sRGB 채널값(0~255) -> 선형값 표 (getLightness에서 조회)
        private static const LINEAR_TABLE:Vector.<Number> = buildLinearTable();

        private static function buildLinearTable():Vector.<Number>
        {
            const table:Vector.<Number> = new Vector.<Number>(256, true);
            for (var i:int = 0; i < 256; i++)
            {
                const c:Number = i / 255;
                table[i] = (c <= 0.04045) ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
            }
            return table;
        }

        // CIELAB 밝기 L* (0~100, sRGB D65). 무채색 커서와의 대비처럼 밝기만 필요할 때 사용
        public static function getLightness(rgb:uint):Number
        {
            const y:Number = 0.2126 * LINEAR_TABLE[(rgb >>> 16) & 0xFF] + 0.7152 * LINEAR_TABLE[(rgb >>> 8) & 0xFF] + 0.0722 * LINEAR_TABLE[rgb & 0xFF];
            const f:Number = (y > 0.008856) ? Math.pow(y, 1 / 3) : 7.787 * y + 16 / 116;
            return 116 * f - 16;
        }

        // 요소 colortransform바꾸기
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
            const zoom:Number = CanvasView.canvasZoomMultiplier;
            const angle:Number = targetAngle;

            return function ():Point
            {
                const dx:Number = main.stage.mouseX - mx;
                const dy:Number = main.stage.mouseY - my;
                const newPos:Point = Utils.rotatePoint(dx, dy, angle);

                newPos.setTo(Math.round(oldX + newPos.x / zoom / customScaleX), Math.round(oldY + newPos.y / zoom / customScaleY));

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

        public static function traceDisplayTree(target:DisplayObject, indent:String = ""):void
        {
            if (target == null)
            {
                trace(indent + "null");
                return;
            }

            trace(
                    indent + getQualifiedClassName(target) + " name=" + target.name
                );

            var container:DisplayObjectContainer = target as DisplayObjectContainer;

            if (container == null)
            {
                return;
            }

            for (var i:int = 0;i < container.numChildren;i++)
            {
                traceDisplayTree(container.getChildAt(i), indent + "    ");
            }
        }

        public static function cloneSimpleButton(originalButton:SimpleButton):SimpleButton
        {
            return SimpleButtonCloneUtil.clone(originalButton);
        }
    }
}

import flash.display.SimpleButton;
import avmplus.getQualifiedClassName;
import flash.utils.getDefinitionByName;
import flash.display.DisplayObject;
import flash.display.Bitmap;
import flash.geom.Rectangle;
import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.ColorTransform;
import flash.filters.BitmapFilter;

final class SimpleButtonCloneUtil
{
    public static function clone(source:SimpleButton):SimpleButton
    {
        if (source == null)
        {
            return null;
        }

        var result:SimpleButton = createSameButtonClass(source);

        if (result == null)
        {
            result = createButtonFromStates(source);
        }

        copyButtonProperties(source, result);

        return result;
    }

    private static function createSameButtonClass(source:SimpleButton):SimpleButton
    {
        try
        {
            var className:String = getQualifiedClassName(source);

            if (isBuiltInClass(className))
            {
                return null;
            }

            var ButtonClass:Class = getDefinitionByName(className) as Class;
            return new ButtonClass() as SimpleButton;
        }
        catch (error:Error)
        {
            return null;
        }
    }

    private static function createButtonFromStates(source:SimpleButton):SimpleButton
    {
        var result:SimpleButton = new SimpleButton();

        result.upState = cloneState(source.upState);
        result.overState = cloneState(source.overState);
        result.downState = cloneState(source.downState);
        result.hitTestState = cloneState(source.hitTestState);

        return result;
    }

    private static function cloneState(source:DisplayObject):DisplayObject
    {
        if (source == null)
        {
            return null;
        }

        var cloned:DisplayObject = createSameDisplayObjectClass(source);

        if (cloned != null)
        {
            copyDisplayObjectProperties(source, cloned);
            return cloned;
        }

        return cloneAsBitmap(source);
    }

    private static function createSameDisplayObjectClass(source:DisplayObject):DisplayObject
    {
        try
        {
            var className:String = getQualifiedClassName(source);

            if (isBuiltInClass(className))
            {
                return null;
            }

            var DisplayClass:Class = getDefinitionByName(className) as Class;
            return new DisplayClass() as DisplayObject;
        }
        catch (error:Error)
        {
            return null;
        }
    }

    private static function isBuiltInClass(className:String):Boolean
    {
        return className.indexOf("flash.") == 0;
    }

    private static function copyButtonProperties(source:SimpleButton, target:SimpleButton):void
    {
        copyDisplayObjectProperties(source, target);

        target.enabled = source.enabled;
        target.useHandCursor = source.useHandCursor;
        target.trackAsMenu = source.trackAsMenu;
        target.tabEnabled = source.tabEnabled;
        target.tabIndex = source.tabIndex;
        target.name = source.name;
        target.accessibilityProperties = source.accessibilityProperties;
    }

    private static function copyDisplayObjectProperties(source:DisplayObject, target:DisplayObject):void
    {
        target.transform.matrix = source.transform.matrix.clone();
        target.transform.colorTransform = cloneColorTransform(source.transform.colorTransform);
        target.alpha = source.alpha;
        target.visible = source.visible;
        target.blendMode = source.blendMode;
        target.cacheAsBitmap = source.cacheAsBitmap;
        target.opaqueBackground = source.opaqueBackground;
        target.filters = cloneFilters(source.filters);
    }

    private static function cloneAsBitmap(source:DisplayObject):Bitmap
    {
        var bounds:Rectangle = source.getBounds(source);
        var width:int = Math.max(1, Math.ceil(bounds.width));
        var height:int = Math.max(1, Math.ceil(bounds.height));

        var bitmapData:BitmapData = new BitmapData(width, height, true, 0x00000000);
        var matrix:Matrix = new Matrix();

        matrix.translate(-bounds.x, -bounds.y);
        bitmapData.draw(source, matrix, null, null, null, true);

        var bitmap:Bitmap = new Bitmap(bitmapData, "auto", true);
        bitmap.x = bounds.x;
        bitmap.y = bounds.y;

        return bitmap;
    }

    private static function cloneColorTransform(source:ColorTransform):ColorTransform
    {
        return new ColorTransform(
                source.redMultiplier,
                source.greenMultiplier,
                source.blueMultiplier,
                source.alphaMultiplier,
                source.redOffset,
                source.greenOffset,
                source.blueOffset,
                source.alphaOffset
            );
    }

    private static function cloneFilters(source:Array):Array
    {
        var result:Array = [];

        for each (var filter:BitmapFilter in source)
        {
            result.push(filter.clone());
        }

        return result;
    }
}
