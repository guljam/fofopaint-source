package Modules.L4UI.UIEngine
{
    import Modules.L1Data.Utils;

    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.text.TextField;

    // 뷰포트 좌상단 메시지 상자 하나. 클릭·마우스 올림 판정은 MessageBoxController가 좌표로 함
    // 층: L4 UI - 메시지 상자 하나 (배경 사각형 + 글자)
    public class MessageBox extends Sprite
    {
        private var messageBG:Shape = new Shape();
        private var messageText:TextField;
        private var bgColor:uint = 0xFFFFFF;
        private var bgAlpha:Number = 1.0;

        public function MessageBox(fontSize:Number)
        {
            // 이벤트를 표시 객체로 받으면 HintController.onMouseMoveBottomHint가 이 상자를 대상으로 잡아 하단 힌트가 꺼짐
            mouseEnabled = false;
            mouseChildren = false;

            messageText = Utils.createTextField("", 0x000000, fontSize);
            messageText.multiline = true;
            addChild(messageBG);
            addChild(messageText);
        }

        public function setMessageText(str:String):void
        {
            messageText.text = str;
            drawMessageBG();
        }

        public function getMessageText():String
        {
            return messageText.text;
        }

        public function setMessageColors(newBGColor:uint, newBGAlpha:Number, newTextColor:uint):void
        {
            bgColor = newBGColor;
            bgAlpha = newBGAlpha;
            messageText.textColor = newTextColor;
            drawMessageBG();
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
            return messageText.textColor;
        }

        // HintBoxSet.setHintText와 같은 여백, 테두리 없음
        private function drawMessageBG():void
        {
            messageBG.graphics.clear();
            messageBG.graphics.beginFill(bgColor, bgAlpha);
            messageBG.graphics.drawRect(-2, -2, messageText.width + 6, messageText.height + 3);
            messageBG.graphics.endFill();
        }
    }
}
