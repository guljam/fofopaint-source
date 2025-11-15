package
{
    import flash.display.DisplayObject;
    import flash.geom.ColorTransform;
    import flash.display.DisplayObjectContainer;
    import flash.utils.Dictionary;

    public class Global
    {
        static public const OFFALPHA:Number = Math.round(0.25 * 256) / 256;

        static public function setColorTransform(target:DisplayObject,color:uint,customAlpha:Number=NaN):void
        {
            if(!target)
            {
                return;
            }

            const alphaSave:Number = (isNaN(customAlpha)) ? target.alpha : customAlpha;
            const c:ColorTransform = target.transform.colorTransform;
            c.color = color;
            c.alphaMultiplier = alphaSave;
            target.transform.colorTransform = c;
        }

        static public const  UI_COLOR_DARK:uint = 0x323232, //어두운색
                            UI_COLOR_MID_DARK:uint = 0x535353,//0x5B5B5B//중간 어두운색
                            UI_COLOR_MID_BRIGHT:uint = 0xB8B8B8,//중간 밝은색
                            UI_COLOR_BRIGHT:uint = 0xF0F0F0,//0xECEAE7//밝은색
                            UI_RESIZE_BUTTON_COLOR:uint = 0xA5A5A5;

        
        static private var uiScaleIndex:int = 0;
        static private const uiScales:Array = [1.0,1.25,1.5,1.75,2.0,2.25];
        static private var uiColorIndex:int = 1;
        static private const uiColorSets:Array = [
                        // 주 컬러           반대색        stage 배경색        크기조절 막대색                 리플레이 완료색     리플레이 재시작색
                        [UI_COLOR_DARK,       0xE5E5E5,        0x4B4B4B,       0x676767,               0x74AC74,            0xE8BE71],
                        [UI_COLOR_MID_DARK,   UI_COLOR_BRIGHT, 0x888888,  UI_RESIZE_BUTTON_COLOR,      0xA1CE9D,            0xF7DA83],
                        [UI_COLOR_MID_BRIGHT, 0x505050,        0xC9C9C9,       0xB0B0B0,               0xB6DAAF,            0xF7EA8D],
                        [UI_COLOR_BRIGHT,     0x505050,        0xE1E1E1,       0xCBCBCB,               0xCEE5C5,            0xF7F2A0]
                    ];
        static private const uiToolBoxColorSets:Array = [
                        // 주 컬러           윗부분 막대색      upstate 배경색     upstate 아이콘색     overstate 배경색     overstate 아이콘색
                        [UI_COLOR_DARK,        0x434343,      0xE5E5E5,       0xE5E5E5,            0x6E98B4,            0xE5E5E5],
                        [UI_COLOR_MID_DARK,    0xE3E3E1,      0xE3E3E1,       UI_COLOR_MID_DARK,   0xB1DFEE,            UI_COLOR_MID_DARK],
                        [UI_COLOR_MID_BRIGHT,  0xD6D5D4,      0x505050,       0x505050,            0xBADAE5,            0x505050],
                        [UI_COLOR_BRIGHT,      0xE7E7E7,      0x505050,       0x505050,            0xCEEBF2,            0x505050]
                    ];

        static private const hintBGColors:Array = [0xFF7943,0xFF8A2C,0xFFAF45,0xFFCF46];
        static private const hintHighlightBoxColors:Array = [0x73B5E4,0x7AC3F0,0x6C9CDB,0x609CFF];

        static public function setUIColorIndex(index:int):void
        {
            uiColorIndex = index;
        }

        static public function setNextUIColor():void
        {
            uiColorIndex++;
            if(uiColorIndex >= uiColorSets.length)
            {
                uiColorIndex = 0;
            }
        }

        static public function setUIColorString():String
        {
            return (uiColorIndex === 0) ? "Black":
            (uiColorIndex === 1) ? "Dark Gray":
            (uiColorIndex === 2) ? "Medium Gray":
            (uiColorIndex === 3) ? "Light Gray" : "What color?";
        }

        static public function applyUIBGColor(target:DisplayObject):void
        {
            setColorTransform(target,uiColorSets[uiColorIndex][0]);
        }

        static public function applyUIFGColor(target:DisplayObject):void
        {
            setColorTransform(target,uiColorSets[uiColorIndex][1]);
        }

        static public function getUIColorIndex():int
        {
            return uiColorIndex;
        }

        static public function getUIBGColor():uint
        {
            return uiColorSets[uiColorIndex][0];
        }

        static public function getUIFGColor():uint
        {
            return uiColorSets[uiColorIndex][1];
        }

        static public function getUIStageColor():uint
        {
            return uiColorSets[uiColorIndex][2];
        }

        static public function getUIResizeBarColor():uint
        {
            return uiColorSets[uiColorIndex][3];
        }

        static public function getUIReplayEndBarColor():uint
        {
            return uiColorSets[uiColorIndex][4];
        }

        static public function getUIReplayRestartBarColor():uint
        {
            return uiColorSets[uiColorIndex][5];
        }

        static public function getHintHightlightColor():uint
        {
            return hintHighlightBoxColors[uiColorIndex];
        }

        static public function getHintBGColor():uint
        {
            return hintBGColors[uiColorIndex];
        }

        static public function setButtonColorWithBG(btn:DisplayObjectContainer,index1:int,index2:int,alpha:Number=1.0):void
        {
            setColorTransform(btn.getChildAt(0) as DisplayObject,uiToolBoxColorSets[uiColorIndex][index1],alpha);
            setColorTransform(btn.getChildAt(1) as DisplayObject,uiToolBoxColorSets[uiColorIndex][index2]);
        }

        static public function getToolBoxBGColor():uint
        {
            return uiToolBoxColorSets[uiColorIndex][0];
        }

        static public function getToolBoxBGTopColor():uint
        {
            return uiToolBoxColorSets[uiColorIndex][1];
        }

        static public function getToolBoxButtonUpBGColor():uint
        {
            return uiToolBoxColorSets[uiColorIndex][2];
        }

        static public function getToolBoxButtonUpFGColor():uint
        {
            return uiToolBoxColorSets[uiColorIndex][3]
        }

        static public function getToolBoxButtonOverBGColor():uint
        {
            return uiToolBoxColorSets[uiColorIndex][4];
        }

        static public function getToolBoxButtonOverFGColor():uint
        {
            return uiToolBoxColorSets[uiColorIndex][5];
        }

        static public function applyToolBoxBGColor(target:DisplayObject):void
        {
            setColorTransform(target,uiToolBoxColorSets[uiColorIndex][0]);
        }

        static public function applyToolBoxBGTopColor(target:DisplayObject):void
        {
            setColorTransform(target,uiToolBoxColorSets[uiColorIndex][1])
        }

        static public function applyToolBoxButtonUpBGColor(target:DisplayObject):void
        {
            setColorTransform(target,uiToolBoxColorSets[uiColorIndex][2]);
        }

        static public function applyToolBoxButtonUpFGColor(target:DisplayObject):void
        {
            setColorTransform(target, uiToolBoxColorSets[uiColorIndex][3]);
        }

        static public function applyToolBoxButtonOverBGColor(target:DisplayObject):void
        {
            setColorTransform(target, uiToolBoxColorSets[uiColorIndex][4]);
        }

        static public function applyToolBoxButtonOverFGColor(target:DisplayObject):void
        {
            setColorTransform(target, uiToolBoxColorSets[uiColorIndex][5]);
        }

        static public function getHintHighlightBoxColor():uint
        {
            return hintHighlightBoxColors[uiColorIndex];
        }

        static public function setScale(target:DisplayObjectContainer,scale:Number):void
        {
            target.scaleX = scale;
            target.scaleY = scale;
        }
        
        static public function getScaleIndex():int
        {
            return uiScaleIndex;
        }

        static public function resetScaleIndex():void
        {
            uiScaleIndex = 0;
        }

        static public function setScaleIndex(index:int):void
        {
            uiScaleIndex = index;
        }

        static public function setNextScaleIndex():void
        {
            uiScaleIndex++;
            if(uiScaleIndex >= uiScales.length)
            {
                uiScaleIndex = 0;
            }
        }
    
        static public function getUIScaleIndex():int
        {
            return uiScaleIndex;
        }

        static public function getUIScale():Number
        {
            return uiScales[uiScaleIndex];
        }

        static public function getUIScaleString():String
        {
            return getUIScale()*100+"%";
        }
        
        static public function RGBtoHSV(r:Number, g:Number, b:Number, baseHue:Number):Vector.<Number>
        {
            r = r/255;
            g = g/255;
            b = b/255;

            const max:Number = Math.max(r, g, b);
            const min:Number = Math.min(r, g, b);
            var h:Number = 0;
            var s:Number = 0;
            var v:Number = max;
            const d:Number = max - min;

            s = (max == 0) ? 0 : d/max;

            if (max == min)
            {
                h = 0; //achromatic
            }
            else
            {
                if(max === r) h = (g - b) / d + (g < b ? 6 : 0);
                else if(max === g) h = (b - r) / d + 2;
                else if(max === b) h = (r - g) / d + 4;

                h = h/6;
            }

            const hsv:Vector.<Number> = new <Number> [h,s,v];
            if(s === 0) hsv[0] = baseHue;

            return hsv;
        }

        
        //hex에서 rgb vector 배열로 반환
        static public function HEXtoRGB(hex:uint):Vector.<Number>
        {
            const r:uint = (hex >> 16) & 0xFF;
            const g:uint = (hex >> 8) & 0xFF;
            const b:uint = hex & 0xFF;

            return new <Number> [r,g,b];
        }
        
        static public function HEXtoHSV(color:uint,baseHue:Number):Vector.<Number>
        {
            const r:uint = (color >> 16) & 0xFF;
            const g:uint = (color >> 8) & 0xFF;
            const b:uint = color & 0xFF;

            return RGBtoHSV(r,g,b,baseHue);
        }

        //rgb값을 16진수로 hex값으로 만들어줌
        static public function RGBtoHEX(r:uint, g:uint, b:uint):uint
        {
            return (r << 16 | g << 8 | b);
        }

        static public function HSVtoHEX(h:Number, s:Number, v:Number):uint
        {
            const rgb:Vector.<uint> = HSVtoRGB(h,s,v);
            return RGBtoHEX(rgb[0],rgb[1],rgb[2]);
        }

        //h s v는 0~1.0 사이값 넣어줘야함
        static public function HSVtoRGB(h:Number, s:Number, v:Number):Vector.<uint>
        {
            v = Math.round(v * 255);

            const i:Number = Math.floor(h * 6);
            const f:Number = h * 6 - i;
            const p:Number = Math.round(v * (1 - s));
            const q:Number = Math.round(v * (1 - f * s));
            const t:Number = Math.round(v * (1 - (1 - f) * s));

            switch(i)
            {
                case 6:
                case 0: return new <uint> [v,t,p];
                case 1: return new <uint> [q,v,p];
                case 2: return new <uint> [p,v,t];
                case 3: return new <uint> [p,q,v];
                case 4: return new <uint> [t,p,v];
                case 5: return new <uint> [v,p,q];
            }

            return new <uint> [0,0,0];
        }

        static public function hexToRGBHSVVector(color:uint,lastHue:Number,isHSVMode:Boolean):Vector.<Number>
        {
            const rgb:Vector.<Number> = HEXtoRGB(color);
            const hsv:Vector.<Number> = HEXtoHSV(color,lastHue);

            if(isHSVMode === true) return hsv;
            if(isHSVMode === false) return rgb;

            return new <Number>[rgb[0],rgb[1],rgb[2],hsv[0],hsv[1],hsv[2]];
        }

        //주어진 컬러 알파값을 기반으로 반전 컬러를 구함
        static public function getInvertedColor(color:uint):uint
        {
            const dark:uint   = (getUIColorIndex() >= 2) ? getUIFGColor():getUIBGColor();
            const bright:uint = (getUIColorIndex() >= 2) ? getUIBGColor():getUIFGColor();

            return (getColorDifferenceForHuman(color,bright) <= 30) ? dark : bright;
        }

        //리턴값
		// <= 1.0	인간의 눈으로 인식 할 수 없음
		// 1 ~ 2	면밀한 관찰을 통해 인식 가능
		// 2 ~ 10	한눈에 알아볼 수 있음
		// 11-49	색상이 반대보다 비슷
		// 100	    색상이 정반대
		static public function getColorDifferenceForHuman(rgbA:uint, rgbB:uint):Number
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
				_x = (_x > 0.008856) ? Math.pow(_x, 1/3) : (7.787 * _x) + 16/116;
				_y = (_y > 0.008856) ? Math.pow(_y, 1/3) : (7.787 * _y) + 16/116;
				_z = (_z > 0.008856) ? Math.pow(_z, 1/3) : (7.787 * _z) + 16/116;

                const result:Vector.<Number> = new <Number> [(116 * _y) - 16, 500 * (_x - _y), 200 * (_y - _z)];

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
			const sc:Number= 1.0 + 0.045 * c1;
			const sh:Number= 1.0 + 0.015 * c1;
			const deltaLKlsl:Number = deltaL / (1.0);
			const deltaCkcsc:Number = deltaC / (sc);
			const deltaHkhsh:Number = deltaH / (sh);
			const i:Number = deltaLKlsl * deltaLKlsl + deltaCkcsc * deltaCkcsc + deltaHkhsh * deltaHkhsh;

			return i < 0 ? 0 : Math.sqrt(i);
		}
      
        public function traceArr(data:*):void
        {
            var stack:Array = [];
            stack.push({value: data, key: "", level: 0});

            trace("--- PRINT START ---");

            while (stack.length > 0)
            {
                var current:Object = stack.pop();
                var value:* = current.value;
                var key:String = current.key;
                var level:int = current.level;

                var indent:String = new Array(level + 1).join("   ");
                if (key !== "")
                {
                    trace(indent + "> index[" + key + "]");
                }

                if (value is Dictionary)
                {
                    trace(indent + "{");
                    for (var dkey:* in value)
                    {
                        var dval:* = value[dkey];
                        if (dval !== null && typeof dval === "object")
                        {
                            stack.push({value: dval, key: dkey.toString(), level: level + 1});
                        }
                        else
                        {
                            trace(indent + "   | " + dkey + " : " + dval);
                        }
                    }
                    trace(indent + "}");
                }
                else if (value is Array)
                {
                    trace(indent + "{");
                    for (var j:int = value.length - 1; j >= 0; j--)
                    {
                        var item:* = value[j];
                        if (item !== null && typeof item === "object")
                        {
                            stack.push({value: item, key: "[" + j + "]", level: level + 1});
                        }
                        else
                        {
                            trace(indent + "   | [" + j + "] : " + item);
                        }
                    }
                    trace(indent + "}");
                }
                else if (typeof value === "object")
                {
                    trace(indent + "{");
                    for (var i:String in value)
                    {
                        var objVal:* = value[i];
                        if (objVal !== null && typeof objVal === "object")
                        {
                            stack.push({value: objVal, key: i, level: level + 1});
                        }
                        else
                        {
                            trace(indent + "   | " + i + " : " + objVal);
                        }
                    }
                    trace(indent + "}");
                }
                else
                {
                    trace(indent + "| " + key + " : " + value);
                }
            }
        }
    }
}