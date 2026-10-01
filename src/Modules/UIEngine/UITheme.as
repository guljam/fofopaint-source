package Modules.UIEngine
{
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import Modules.Utils;

    // UI 색상 테마와 UI 스케일 상태. 패널에 반영하는 쪽은 UIController가 담당
    public class UITheme
    {
        public static const OFFALPHA:Number = Math.round(0.25 * 256) / 256;

        public static const ALPHA_BUTTON_PREFIX:String = "alphaButton";
        public static const NSIZE_BUTTON_PREFIX:String = "nSizeButton";
        static private const UI_COLOR_DARK:uint = 0x323232; // 어두운색
        static private const UI_COLOR_MID_DARK:uint = 0x535353; // 0x5B5B5B//중간 어두운색
        static private const UI_COLOR_MID_BRIGHT:uint = 0xB8B8B8; // 중간 밝은색
        static private const UI_COLOR_BRIGHT:uint = 0xF0F0F0; // 0xECEAE7//밝은색
        static private const UI_RESIZE_BUTTON_COLOR:uint = 0xA5A5A5;

        static private var uiScaleIndex:int = 0;
        static private const uiScales:Array = [1.0, 1.25, 1.5, 1.75, 2.0, 2.25];
        static private var uiColorIndex:int = 1  ;
        static private const uiColorSets:Array = [
        // 주 컬러           반대색        stage 배경색        크기조절 막대색              리플레이 완료색     리플레이 재시작색
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

        static private const hintBGColors:Array = [0xFF7943, 0xFF8A2C, 0xFFAF45, 0xFFCF46];
        static private const hintHighlightBoxColors:Array = [0x73B5E4, 0x7AC3F0, 0x6C9CDB, 0x609CFF];

        public static function getDefaultUIColor():int
        {
            return UI_COLOR_DARK;
        }

        public static function setUIColorIndex(index:int):void
        {
            uiColorIndex = index;
        }

        public static function setNextUIColor():void
        {
            uiColorIndex++;
            if (uiColorIndex >= uiColorSets.length)
            {
                uiColorIndex = 0;
            }
        }

        public static function getUIColorName():String
        {
            return (uiColorIndex === 0) ? "Black" :
                (uiColorIndex === 1) ? "Dark Gray" :
                (uiColorIndex === 2) ? "Medium Gray" :
                (uiColorIndex === 3) ? "Light Gray" : "What color?";
        }

        public static function applyUIBGColor(target:DisplayObject):void
        {
            Utils.setColorTransform(target, uiColorSets[uiColorIndex][0]);
        }

        public static function applyUIFGColor(target:DisplayObject):void
        {
            Utils.setColorTransform(target, uiColorSets[uiColorIndex][1]);
        }

        public static function getUIColorIndex():int
        {
            return uiColorIndex;
        }

        public static function getUIBGColor():uint
        {
            return uiColorSets[uiColorIndex][0];
        }

        public static function getUIFGColor():uint
        {
            return uiColorSets[uiColorIndex][1];
        }

        public static function getUIStageColor():uint
        {
            return uiColorSets[uiColorIndex][2];
        }

        public static function getUIResizeBarColor():uint
        {
            return uiColorSets[uiColorIndex][3];
        }

        public static function getUIReplayEndBarColor():uint
        {
            return uiColorSets[uiColorIndex][4];
        }

        public static function getUIReplayRestartBarColor():uint
        {
            return uiColorSets[uiColorIndex][5];
        }

        public static function getHintHightlightColor():uint
        {
            return hintHighlightBoxColors[uiColorIndex];
        }

        public static function getHintBGColor():uint
        {
            return hintBGColors[uiColorIndex];
        }

        public static function setButtonColorWithBG(btn:DisplayObjectContainer, index1:int, index2:int, alpha:Number = 1.0):void
        {
            Utils.setColorTransform(btn.getChildAt(0) as DisplayObject, uiToolBoxColorSets[uiColorIndex][index1], alpha);
            Utils.setColorTransform(btn.getChildAt(1) as DisplayObject, uiToolBoxColorSets[uiColorIndex][index2]);
        }

        public static function getToolBoxBGColor():uint
        {
            return uiToolBoxColorSets[uiColorIndex][0];
        }

        public static function getToolBoxBGTopColor():uint
        {
            return uiToolBoxColorSets[uiColorIndex][1];
        }

        public static function getToolBoxButtonUpBGColor():uint
        {
            return uiToolBoxColorSets[uiColorIndex][2];
        }

        public static function getToolBoxButtonUpFGColor():uint
        {
            return uiToolBoxColorSets[uiColorIndex][3];
        }

        public static function getToolBoxButtonOverBGColor():uint
        {
            return uiToolBoxColorSets[uiColorIndex][4];
        }

        public static function getToolBoxButtonOverFGColor():uint
        {
            return uiToolBoxColorSets[uiColorIndex][5];
        }

        public static function applyToolBoxBGColor(target:DisplayObject):void
        {
            Utils.setColorTransform(target, uiToolBoxColorSets[uiColorIndex][0]);
        }

        public static function applyToolBoxBGTopColor(target:DisplayObject):void
        {
            Utils.setColorTransform(target, uiToolBoxColorSets[uiColorIndex][1]);
        }

        public static function applyToolBoxButtonUpBGColor(target:DisplayObject):void
        {
            Utils.setColorTransform(target, uiToolBoxColorSets[uiColorIndex][2]);
        }

        public static function applyToolBoxButtonUpFGColor(target:DisplayObject):void
        {
            Utils.setColorTransform(target, uiToolBoxColorSets[uiColorIndex][3]);
        }

        public static function applyToolBoxButtonOverBGColor(target:DisplayObject):void
        {
            Utils.setColorTransform(target, uiToolBoxColorSets[uiColorIndex][4]);
        }

        public static function resetScaleIndex():void
        {
            uiScaleIndex = 0;
        }

        public static function setScaleIndex(index:int):void
        {
            uiScaleIndex = index;
        }

        public static function setNextScaleIndex():void
        {
            uiScaleIndex++;
            if (uiScaleIndex >= uiScales.length)
            {
                uiScaleIndex = 0;
            }
        }

        public static function getUIScaleIndex():int
        {
            return uiScaleIndex;
        }

        public static function getUIScale():Number
        {
            return uiScales[uiScaleIndex];
        }

        public static function getUIScaleString():String
        {
            return getUIScale() * 100 + "%";
        }

        // 주어진 컬러 알파값을 기반으로 반전 컬러를 구함
        public static function getInvertedColor(color:uint):uint
        {
            const dark:uint = (getUIColorIndex() >= 2) ? getUIFGColor() : getUIBGColor();
            const bright:uint = (getUIColorIndex() >= 2) ? getUIBGColor() : getUIFGColor();

            return (Utils.getColorDifferenceForHuman(color, bright) <= 30) ? dark : bright;
        }
    }
}
