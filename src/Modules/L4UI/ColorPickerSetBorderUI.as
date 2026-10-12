package Modules.L4UI
{
    import Modules.L1Data.ColorHistory;
    import Modules.L2Engine.DrawEngine.HandDrawnLine;
    import Symbols.ColorPickerSet;
    import flash.display.DisplayObject;
    import flash.display.Shape;
    import flash.display.Sprite;

    // 층: L4 UI - ColorPickerSet의 각진 사각형 요소(my palette, 색 히스토리, rgbInfoBG, currentColor, 투명색 버튼, hue 바, svBox, 스크래치패드)의
    // 가장자리를 손으로 그린 듯 해진 모양으로 자르는 마스크를 소유함.
    // 요소를 작게 만들거나 선을 덧그리지 않고 마스크로 잘라내므로 사이드바 배경(반투명 포함)이 그대로 비침.
    // 마스크는 시작할 때 한 번 그리고, 크기가 바뀔 때만 같은 seed로 다시 그려서 모양이 변하지 않음
    public class ColorPickerSetBorderUI
    {
        private static const MY_PALETTE_BOX_SEED:uint = 101;
        private static const COLOR_HISTORY_BOX_SEED:uint = 102;
        private static const RGB_INFO_BG_SEED:uint = 103;
        private static const CURRENT_COLOR_BOX_SEED:uint = 104;
        private static const TRANS_COLOR_BUTTON_SEED:uint = 105;
        private static const HUE_COLOR_SEED:uint = 106;
        private static const SV_BOX_SEED:uint = 107;
        private static const SCRATCH_PAD_SEED:uint = 108;

        private static const MY_PALETTE_COMPACT_ROW_COUNT:int = 2;

        private const myPaletteBoxBorderMask:Shape = new Shape();
        private const colorHistoryBoxBorderMask:Shape = new Shape();
        private const rgbInfoBGBorderMask:Shape = new Shape();
        private const currentColorBoxBorderMask:Shape = new Shape();
        private const transColorButtonBorderMask:Shape = new Shape(); // transColorButton은 SimpleButton이라 자식을 못 달아서 mainColorPickerBox에 따로 둠
        private const hueColorBorderMask:Shape = new Shape();
        private const svBoxBorderMask:Shape = new Shape();
        private const scratchPadBorderMask:Shape = new Shape(); // scratchPad는 크기를 width/height로 늘려 쓰므로 자식이 아니라 mainColorPickerBox에 따로 둠

        private var colorPickerSet:ColorPickerSet;
        private var rgbInfoBoxHeight:Number;
        private var hueBarHeight:Number;
        private var currentColorBoxWidth:Number;

        private var myPaletteBoxRowCount:int = MY_PALETTE_COMPACT_ROW_COUNT;
        private var rgbInfoBGBorderWidth:Number;

        // 모든 요소에 마스크를 달고 처음 한 번 그림. ColorPickerSet 생성자 맨 끝(스크래치패드 생성 뒤)에서 불러야 함
        public function ColorPickerSetBorderUI(colorPickerSet:ColorPickerSet, mainColorPickerBox:Sprite, rgbInfoBoxHeight:Number, rgbInfoBGNarrowWidth:Number, hueBarHeight:Number, currentColorBoxWidth:Number)
        {
            this.colorPickerSet = colorPickerSet;
            this.rgbInfoBoxHeight = rgbInfoBoxHeight;
            this.hueBarHeight = hueBarHeight;
            this.currentColorBoxWidth = currentColorBoxWidth;
            rgbInfoBGBorderWidth = rgbInfoBGNarrowWidth;

            attachBorderMaskToChildOfElement(colorPickerSet.myPaletteBox, myPaletteBoxBorderMask);
            attachBorderMaskToChildOfElement(colorPickerSet.colorHistoryBox, colorHistoryBoxBorderMask);
            attachBorderMaskToChildOfElement(colorPickerSet.rgbInfoBG, rgbInfoBGBorderMask);
            attachBorderMaskToChildOfElement(colorPickerSet.currentColorBox, currentColorBoxBorderMask);
            attachBorderMaskToChildOfElement(colorPickerSet.hueColor, hueColorBorderMask);
            attachBorderMaskToChildOfElement(colorPickerSet.svBox, svBoxBorderMask);

            transColorButtonBorderMask.x = colorPickerSet.transColorButton.x;
            transColorButtonBorderMask.y = colorPickerSet.transColorButton.y;
            mainColorPickerBox.addChild(transColorButtonBorderMask);
            colorPickerSet.transColorButton.mask = transColorButtonBorderMask;

            scratchPadBorderMask.x = colorPickerSet.scratchPad.x;
            scratchPadBorderMask.y = colorPickerSet.scratchPad.y;
            mainColorPickerBox.addChild(scratchPadBorderMask);
            colorPickerSet.scratchPad.mask = scratchPadBorderMask;

            drawAllBorderMasks();
        }

        // element 안에 마스크를 자식으로 넣고 element의 mask로 지정함. 마스크는 element 범위 안에 머물러서 element의 크기(width/height)는 변하지 않음
        private function attachBorderMaskToChildOfElement(element:Sprite, borderMask:Shape):void
        {
            element.addChild(borderMask);
            element.mask = borderMask;
        }

        // borderMask를 maskWidth x maskHeight 크기의 해진 사각형으로 다시 그림. 같은 seed는 같은 모양
        private function drawBorderMask(borderMask:Shape, maskWidth:Number, maskHeight:Number, seed:uint):void
        {
            borderMask.graphics.clear();
            HandDrawnLine.drawWornRectFill(borderMask.graphics, maskWidth, maskHeight, seed);
        }

        // 모든 마스크를 지금 크기로 그림
        private function drawAllBorderMasks():void
        {
            drawMyPaletteBoxBorderMask();
            drawBorderMask(colorHistoryBoxBorderMask, PaletteController.myPaletteColorWidth * ColorHistory.HISTORY_COUNT, PaletteController.myPaletteColorHeight, COLOR_HISTORY_BOX_SEED);
            drawBorderMask(rgbInfoBGBorderMask, rgbInfoBGBorderWidth, rgbInfoBoxHeight, RGB_INFO_BG_SEED);
            drawBorderMask(currentColorBoxBorderMask, currentColorBoxWidth, rgbInfoBoxHeight, CURRENT_COLOR_BOX_SEED);
            drawBorderMask(transColorButtonBorderMask, colorPickerSet.transColorButton.width, rgbInfoBoxHeight, TRANS_COLOR_BUTTON_SEED);
            drawBorderMask(hueColorBorderMask, colorPickerSet.svBoxWidth, hueBarHeight, HUE_COLOR_SEED);
            drawBorderMask(svBoxBorderMask, colorPickerSet.svBoxWidth, colorPickerSet.svBoxHeight, SV_BOX_SEED);
            drawBorderMask(scratchPadBorderMask, colorPickerSet.scratchPad.width, colorPickerSet.scratchPad.height, SCRATCH_PAD_SEED);
        }

        // my palette 마스크를 지금 줄 수(myPaletteBoxRowCount) 크기로 그림
        private function drawMyPaletteBoxBorderMask():void
        {
            drawBorderMask(myPaletteBoxBorderMask, PaletteController.myPaletteColorWidth * PaletteController.MYPALETTE_COLUMNS, PaletteController.myPaletteColorHeight * myPaletteBoxRowCount, MY_PALETTE_BOX_SEED);
        }

        // my palette 줄 수(접힘 2, 펼침 10)가 바뀌면 마스크를 새 크기로 다시 그림. myPaletteBox.height로 위치를 계산하기 전에 불러야 함
        public function updateMyPaletteBoxBorderRowCount(rowCount:int):void
        {
            if (myPaletteBoxRowCount === rowCount)
            {
                return;
            }

            myPaletteBoxRowCount = rowCount;
            drawMyPaletteBoxBorderMask();
        }

        // rgbInfoBG 너비가 팔레트 종류에 따라 바뀔 때(my palette 108, drawr/tegaki는 svBox 너비) 마스크를 새 너비로 다시 그림
        public function updateRGBInfoBGBorderWidth(newWidth:Number):void
        {
            if (rgbInfoBGBorderWidth === newWidth)
            {
                return;
            }

            rgbInfoBGBorderWidth = newWidth;
            drawBorderMask(rgbInfoBGBorderMask, rgbInfoBGBorderWidth, rgbInfoBoxHeight, RGB_INFO_BG_SEED);
        }

        // child가 mainColorPickerBox에 따로 둔 마스크인지 알려줌. 스크래치패드 모드에서 자식을 숨길 때 이 마스크는 남겨둬야 해서 씀
        public function isBorderMaskObject(child:DisplayObject):Boolean
        {
            return child === transColorButtonBorderMask || child === scratchPadBorderMask;
        }
    }
}
