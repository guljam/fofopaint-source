package Modules.L4UI.UIEngine
{
    import Modules.L2Engine.DrawEngine.HandDrawnLine;
    import flash.display.Shape;

    // 층: L4 UI - 사각형 요소 가장자리를 손으로 그린 듯 해진 모양으로 자르는 마스크 한 장.
    // 요소의 mask로 걸면 요소를 작게 하거나 선을 덧그리지 않고 가장자리만 잘라내서 뒤 배경(반투명 포함)이 그대로 비침.
    // 같은 seed는 같은 모양이고, 깎임이 위치로 정해져서 크기가 바뀌어도 겹치는 부분의 모양은 변하지 않음
    public class WornBorderMask extends Shape
    {
        private var wornSeed:uint;
        private var erosionScale:Number;
        private var drawnWidth:Number = -1;
        private var drawnHeight:Number = -1;

        // erosionScale은 가장자리가 깎이는 두께에 곱하는 배율(1.0이 기본)
        public function WornBorderMask(wornSeed:uint, erosionScale:Number = 1.0)
        {
            this.wornSeed = wornSeed;
            this.erosionScale = erosionScale;
        }

        // 마스크를 maskWidth x maskHeight 크기로 맞춤. 마지막으로 그린 크기와 같으면 다시 그리지 않음
        public function updateMaskSize(maskWidth:Number, maskHeight:Number):void
        {
            if (drawnWidth === maskWidth && drawnHeight === maskHeight)
            {
                return;
            }

            drawnWidth = maskWidth;
            drawnHeight = maskHeight;
            graphics.clear();
            HandDrawnLine.drawWornRectFill(graphics, maskWidth, maskHeight, wornSeed, erosionScale);
        }
    }
}
