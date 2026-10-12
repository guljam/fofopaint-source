package Modules.L4UI.UIEngine
{
    import flash.display.Sprite;

    // 층: L4 UI - 하단 힌트 바(HintController.bottomBar)의 가장자리를 손으로 그린 듯 해진 모양으로 자르는 마스크(WornBorderMask)를 소유함.
    // 바 배경을 다시 그리거나 선을 덧그리지 않고 마스크로 잘라내서 반투명 배경이 그대로 비침. 바는 좌/우/아래가 화면 밖이라 실제로는 위쪽 경계가 해져 보임
    public class BottomHintBorderUI
    {
        private static const BOTTOM_HINT_BAR_SEED:uint = 301;
        private static const BAR_LEFT_OVERFLOW:Number = 3; // 바 배경이 화면 왼쪽으로 삐져나가는 폭 (HintController.updateBottomBarLayoutAndColor와 같음)

        private const bottomBarBorderMask:WornBorderMask = new WornBorderMask(BOTTOM_HINT_BAR_SEED);

        // bottomBar의 자식으로 마스크를 넣고 bottomBar의 mask로 지정함. 크기는 updateBottomBarBorderSize로 맞춰야 함
        public function BottomHintBorderUI(bottomBar:Sprite)
        {
            bottomBarBorderMask.x = -BAR_LEFT_OVERFLOW;
            bottomBar.addChild(bottomBarBorderMask);
            bottomBar.mask = bottomBarBorderMask;
        }

        // 마스크를 바 배경 크기에 맞춤. 창 너비가 바뀔 때만 다시 그리고, 겹치는 부분의 모양은 그대로임
        public function updateBottomBarBorderSize(barWidth:Number, barHeight:Number):void
        {
            bottomBarBorderMask.updateMaskSize(barWidth, barHeight);
        }
    }
}
