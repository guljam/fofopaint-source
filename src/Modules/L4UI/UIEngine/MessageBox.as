package Modules.L4UI.UIEngine
{
    import Modules.L1Data.Utils;

    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.text.TextField;

    // 좌하단 메시지 상자 하나. 클릭·마우스 올림 판정은 MessageController가 좌표로 함
    // 층: L4 UI - 메시지 상자 하나 (배경 사각형 + 글자)
    public class MessageBox extends Sprite
    {
        private var bg:Shape = new Shape();
        private var field:TextField;
        private var bgColor:uint = 0xFFFFFF;
        private var bgAlpha:Number = 1.0;
        private var textColor:uint = 0x000000;

        public function MessageBox(fontSize:Number)
        {
            // 이벤트를 표시 객체로 받으면 HintController.onMouseMoveBottomHint가 이 상자를 대상으로 잡아 하단 힌트가 꺼짐
            mouseEnabled = false;
            mouseChildren = false;

            field = Utils.createTextField("", textColor, fontSize);
            field.multiline = true;
            addChild(bg);
            addChild(field);
        }

        public function setText(str:String):void
        {
            field.text = str;
            redraw();
        }

        public function getText():String
        {
            return field.text;
        }

        public function setStyle(newBGColor:uint, newBGAlpha:Number, newTextColor:uint):void
        {
            bgColor = newBGColor;
            bgAlpha = newBGAlpha;
            textColor = newTextColor;
            field.textColor = newTextColor;
            redraw();
        }

        public function getBGColor():uint
        {
            return bgColor;
        }

        public function getBGAlpha():Number
        {
            return bgAlpha;
        }

        public function getTextColor():uint
        {
            return field.textColor;
        }

        // HintBoxSet.setHintText와 같은 여백, 테두리 없음
        private function redraw():void
        {
            bg.graphics.clear();
            bg.graphics.beginFill(bgColor, bgAlpha);
            bg.graphics.drawRect(-2, -2, field.width + 6, field.height + 3);
            bg.graphics.endFill();
        }
    }
}
