package
{
    import flash.display.DisplayObject;
    import flash.geom.ColorTransform;
    import flash.display.DisplayObjectContainer;

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
                        // 주 컬러           반대색        stage 배경색   크기조절 막대색                 리플레이 완료색     리플레이 재시작색
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
    }
}