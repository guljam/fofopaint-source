package Modules.L4UI
{
    import Modules.UIEngine.UITheme;
    import Symbols.ColorPickerSet;
    import Symbols.NumPadSet;
    import flash.display.BitmapData;
    import flash.geom.Point;
    import flash.events.MouseEvent;
    import flash.display.DisplayObject;
    import Symbols.FillPenMenuSet;
    import flash.utils.getTimer;
    import Modules.L5App.InputManager.DrawModeInput;
    import Modules.L3Feature.Tools.FillPenTool;
    import Modules.L5App.InputManager.InputManager;
    import Modules.InputPriority;
    import Modules.L3Feature.Tools.LineTool;
    import Modules.L3Feature.Tools.ToolController;
    import Modules.L4UI.Tools.ToolPanel;
    import Modules.L1Data.KeyState;
    import Modules.L1Data.Tools.PenSettings;
    import Modules.L1Data.ToolState;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L3Feature.Tools.PenTool;
    import Modules.L1Data.ColorHistory;
    import Modules.L3Feature.UndoController;
    import Modules.L1Data.DragInteraction;
    import Modules.L1Data.Utils;
    import Modules.L4UI.UIEngine.UIController;

    // 층: L4 UI - 색 선택기 박스와 숫자패드, 색 프리셋 선택 처리
    public class ColorPickerController
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static const colorPickerBox:ColorPickerSet = new ColorPickerSet();
        public static const numPadBox:NumPadSet = new NumPadSet();
        public static const hsvColorData:Vector.<Number> = new Vector.<Number>(3, true); // h,s,v순서 hue컬러 다른 함수들이랑 통신하기 위해서 전역으로 만들어줌

        public static var isColorPickerModeBG:Boolean = false; // false이면 펜컬러 true이면 배경색
        private static var isColorPickerModeResetEventAdded:Boolean = false; // 배경색 선택하고 나서 커서가 사이드바를 나가면 리셋해주는 이벤트를 올려주는 플래그

        public static var isColorPickerBoxPositionSwapped:Boolean = false; // 마이팔래트랑 컬러피커박스 위치 바뀌면 올려줌
        private static var lastRGBInfoColorPartIndex:int = -1; // 처음 클릭했을때 R G B중 어느 영역을 클릭했는지
        public static var isHSVInfoTextMode:Boolean = false; // true가 되면 hsv false이면 rgb
        private static var numpadInputBuffer:String = ""; // 숫자키 누르면 어기다가 저장해주고 필터링해줘서 rgbinfotext에 갱신해줌

        public static function showPickColorScratchPad():void
        {
            pickColor(colorPickerBox.scratchPad.pickColor());
        }

        public static function updatePickerBoxTransBGBrightness():void
        {
            colorPickerBox.applyTransparentColorBrightness(UITheme.getUIColorIndex());

            PaletteController.updateMyPaletteList();
            PaletteController.updateColorHistory();

            if (PenTool.isTransparentPenColor)
            {
                colorPickerBox.setRGBInfoBackgroundTransparent(PaletteController.myPalettePresetType);
            }
        }

        private static function rgbInfoNumPadIncKey(inc:int):void
        {
            if (isHSVInfoTextMode)
            {
                adjustSingleValueHSV(inc);
                numPadBox.updateOkBaseColor(colorPickerBox.getRGBInfoBGColor());
            }
            else
            {
                adjustSingleValueRGB(inc);
                numPadBox.updateOkBaseColor(colorPickerBox.getRGBInfoBGColor());
            }
        }

        private static function pressNumpadKey(num:String):void
        {
            var startIndex:int = colorPickerBox.rgbInfoText.selectionBeginIndex;
            var endIndex:int = colorPickerBox.rgbInfoText.selectionEndIndex;

            if (numpadInputBuffer.length >= 3)
            {
                main.stage.focus = null;
                return;
            }

            numpadInputBuffer += num;
            var value:int = parseInt(numpadInputBuffer);

            if (isHSVInfoTextMode)
            {
                if (lastRGBInfoColorPartIndex === 0)
                {
                    if (value > 360)
                    {
                        value = 360;
                    }

                    hsvColorData[lastRGBInfoColorPartIndex] = value / 360;
                }
                else
                {
                    if (value > 100)
                    {
                        value = 100;
                    }

                    hsvColorData[lastRGBInfoColorPartIndex] = value / 100;
                }
            }
            else
            {
                if (value > 255)
                {
                    value = 255;
                }

                const arr:Array = getColorValueFromRGBInfoText();
                arr[lastRGBInfoColorPartIndex] = value;

                const hsv:Vector.<Number> = Utils.HEXtoHSV(Utils.RGBtoHEX(arr[0], arr[1], arr[2]), hsvColorData[0]);

                hsvColorData[0] = hsv[0];
                hsvColorData[1] = hsv[1];
                hsvColorData[2] = hsv[2];
            }

            updateColorPickerCursorPosAndRGBInfo(hsvColorData);

            numPadBox.updateOkBaseColor(Utils.HSVtoHEX(hsvColorData[0], hsvColorData[1], hsvColorData[2]));

            keepRGBInfoTextPartFocus();

            if (colorPickerBox.getRGBInfoBGColor() !== colorPickerBox.getCurrentColor())
            {
                applyAdjustedColor();
            }
        }

        public static function activeColorPreset(type:int):void
        {
            if (PaletteController.myPalettePresetType === type)
            {
                return;
            }

            var myPalettePresetTypeSave:int = PaletteController.myPalettePresetType;

            PaletteController.myPalettePresetType = type;
            PaletteController.updateMyPaletteList();

            colorPickerBox.setActiveColorPreset(type);

            if (isColorPickerModeBG)
            {
                switchColorPickerModePen();
            }
            else if (!FillPenTool.isStarted) // 펜 모드에서 프리셋만 바뀌어도 paperColorButton 알파를 갱신함 (채우기펜 중에는 둘 다 꺼져있으므로 건드리지 않음)
            {
                colorPickerBox.activePaperColorButton(false);
            }

            if (type === 1) // drawr
            {
                PaletteController.myPaletteSaveColorBeforeOtherType[myPalettePresetTypeSave] = colorPickerBox.getRGBInfoBGColor();
                pickColor(PaletteController.myPaletteSaveColorBeforeOtherType[1]);
            }
            else if (type === 2) // tegaki
            {
                PaletteController.myPaletteSaveColorBeforeOtherType[myPalettePresetTypeSave] = colorPickerBox.getRGBInfoBGColor();
                pickColor(PaletteController.myPaletteSaveColorBeforeOtherType[2]);
            }
            else
            {
                PaletteController.myPaletteSaveColorBeforeOtherType[myPalettePresetTypeSave] = colorPickerBox.getRGBInfoBGColor();
                pickColor(PaletteController.myPaletteSaveColorBeforeOtherType[0]);
            }

            SidebarController.checkFOFOPosition();
        }

        // 123,123,123에서 커서가 어느 지점이 있는지 반환함 0=R, 1=G, 2=B
        private static function getRGBInfoTextCursorPos(customIndex:* = null):int
        {
            if (customIndex === null)
            {
                customIndex = colorPickerBox.rgbInfoText.caretIndex;
            }

            const textBeforeCursor:String = colorPickerBox.getRGBInfoText().substring(0, customIndex);
            const rgb:Array = textBeforeCursor.split(",");

            return rgb.length - 1;
        }

        private static function keepRGBInfoTextPartFocus():void
        {
            FOFOTimer.addByName("keepRGBInfoTextPartFocusTimer", 0.0, false, function ():void
                {
                    main.stage.focus = colorPickerBox.rgbInfoText;
                    selectRGBInfoTextByIndex(lastRGBInfoColorPartIndex);
                });
        }

        // index 값에 해당하는 RGB 텍스트 영역을 선택함
        private static function selectRGBInfoTextByIndex(index:int):void
        {
            if (index < 0 || index > 2)
            {
                return;
            }

            var start:int;
            var end:int;

            if (index === 0)
            {
                start = 4;
                end = colorPickerBox.getRGBInfoText().indexOf(",");
            }
            else if (index === 1)
            {
                start = colorPickerBox.getRGBInfoText().indexOf(",") + 1;
                end = colorPickerBox.getRGBInfoText().lastIndexOf(",");
            }
            else if (index === 2)
            {
                start = colorPickerBox.getRGBInfoText().lastIndexOf(",") + 1;
                end = colorPickerBox.getRGBInfoText().length;
            }

            colorPickerBox.rgbInfoText.setSelection(start, end);

            lastRGBInfoColorPartIndex = index;
        }

        private static function getColorValueFromRGBInfoText():Array
        {
            var rgbText:String = colorPickerBox.getRGBInfoText().slice(4); // "RGB"와 공백 제거
            var rgb:Array = rgbText.split(","); // 쉼표로 숫자를 나눔

            return rgb;
        }

        private static function adjustSingleValueHSV(inc:int):void
        {
            const index:int = lastRGBInfoColorPartIndex;
            const hsv:Array = getColorValueFromRGBInfoText();

            var num:int = int(hsv[lastRGBInfoColorPartIndex]);
            num += inc;

            if (num < 0)
            {
                num = 0;
            }

            if (index === 0)
            {
                if (num > 360)
                {
                    num = 360;
                }
            }
            else
            {
                if (num > 100)
                {
                    num = 100;
                }
            }

            hsv[index] = Number(num);

            hsv[0] = hsv[0] / 360;
            hsv[1] = hsv[1] / 100;
            hsv[2] = hsv[2] / 100;

            const hsvvec:Vector.<Number> = new <Number>[hsv[0], hsv[1], hsv[2]];

            updateColorPickerCursorPosAndRGBInfo(hsvvec);

            keepRGBInfoTextPartFocus();
        }

        private static function adjustSingleValueRGB(inc:int):void
        {
            const index:int = lastRGBInfoColorPartIndex;
            const rgb:Array = getColorValueFromRGBInfoText();

            var num:int = int(rgb[index]);
            num += inc;

            if (num < 0)
            {
                num = 0;
            }
            else if (num > 255)
            {
                num = 255;
            }

            rgb[index] = Number(num);

            updateColorPickerCursorPosAndRGBInfo(Utils.RGBtoHEX(rgb[0], rgb[1], rgb[2]));

            keepRGBInfoTextPartFocus();
        }

        private static function getRgbInfoTextClickedPosIndex():int
        {
            return colorPickerBox.rgbInfoText.getCharIndexAtPoint(colorPickerBox.rgbInfoText.mouseX, 10);
        }

        private static function openNumPad():void
        {
            if (numPadBox.visible === false)
            {

                numPadBox.readyLCHAdjustment(Utils.HSVtoHEX(hsvColorData[0], 1.0, 1.0), colorPickerBox.getRGBInfoBGColor());

                const gp:Point = colorPickerBox.rgbInfoBG.localToGlobal(new Point(0, 0));

                numPadBox.x = Math.floor(gp.x);
                numPadBox.y = Math.floor(gp.y + colorPickerBox.rgbInfoBG.height * UITheme.getUIScale() + 1);

                Utils.setAsTopChild(numPadBox);

                KeyState.resetLastKey();

                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownNumPad, false, InputPriority.LATE);
                main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownNumPad, false, InputPriority.LATE);
            }
        }

        public static function closeNumpad():void
        {
            if (colorPickerBox.getRGBInfoBGColor() !== colorPickerBox.getCurrentColor())
            {
                applyAdjustedColor();
            }

            numPadBox.off();

            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownNumPad);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownNumPad);

            FOFOTimer.addByName("rgbInfoTextFocusOutEventDelayInput", 0.0, false, function ():void
                {
                    DrawModeInput.addEvents();
                });
        }

        private static function checkNumPadMouseUp(oldTargetName:String):void
        {
            function onMouseUpNumpad(e:MouseEvent):void
            {
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpNumpad);

                if (oldTargetName === e.target.name)
                {
                    switch (e.target.name)
                    {
                        case "num0":
                        case "num1":
                        case "num2":
                        case "num3":
                        case "num4":
                        case "num5":
                        case "num6":
                        case "num7":
                        case "num8":
                        case "num9":
                            pressNumpadKey(e.target.name.charAt(3));
                            break;

                        case "numClip":
                            const color:* = numPadBox.getClipboardColor();

                            if (color as uint)
                            {
                                numPadBox.updateOkBaseColor(color);
                                updateColorPickerCursorPosAndRGBInfo(color);
                            }
                            break;
                    }
                }
            }

            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpNumpad, false, InputPriority.DEFAULT);
        }

        private static function onRightMouseDownNumPad(e:MouseEvent):void
        {
            closeNumpad();
        }

        private static function onMouseDownNumPad(e:MouseEvent):void
        {
            if (!e.target)
            {
                return;
            }

            const targetName:String = e.target.name;

            if (!numPadBox.hitTestPoint(main.stage.mouseX, main.stage.mouseY) && !colorPickerBox.rgbInfoText.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
            {
                if (numPadBox.visible)
                {
                    closeNumpad();
                }

                return;
            }

            if (targetName === "numInc")
            {
                KeyState.startKeyRepeat(true, rgbInfoNumPadIncKey, 1);
            }
            else if (targetName === "numDec")
            {
                KeyState.startKeyRepeat(true, rgbInfoNumPadIncKey, -1);
            }
            else if (targetName === "okLWrapper")
            {
                startAdjustOKLCH(0);
            }
            else if (targetName === "okCWrapper")
            {
                startAdjustOKLCH(1);
            }
            else if (targetName === "okHWrapper")
            {
                startAdjustOKLCH(2);
            }
            else
            {
                checkNumPadMouseUp(targetName);
            }
        }

        private static function startAdjustOKLCH(index:int):void
        {
            numPadBox.startAdjustLCH(index, function (pickedColor:uint):void
                {
                    updateColorPickerCursorPosAndRGBInfo(pickedColor);

                    if (colorPickerBox.getRGBInfoBGColor() !== colorPickerBox.getCurrentColor())
                    {
                        applyAdjustedColor();
                    }
                });
        }

        // hsv rgb로 왔다갔다함
        private static function toggleRGBInfoTextColorType():void
        {
            const cursorPosSave:int = getRGBInfoTextCursorPos();

            if (isHSVInfoTextMode)
            {
                isHSVInfoTextMode = false;
                colorPickerBox.updateRGBInfoText("RGB", Utils.HEXtoRGB(colorPickerBox.getRGBInfoBGColor()));
            }
            else
            {
                isHSVInfoTextMode = true;
                colorPickerBox.updateRGBInfoText("HSV", Utils.HEXtoHSV(colorPickerBox.getRGBInfoBGColor(), hsvColorData[0]));
            }
        }

        private static function applyAdjustedColor():void
        {
            const color:uint = colorPickerBox.getRGBInfoBGColor();

            if (isPenColorMode())
            {
                PenTool.penColor = color;
                ToolPanel.updateOpacityCursorPos(PenSettings.penAlphaIndex);
            }
            else if (isBackgroundColorMode())
            {
                applyBGColorCanvases(color);
            }
        }

        private static function applyBGColorCanvases(color:uint):void
        {
            DrawCanvas.applyCanvasBGColorDrawMode(color);

            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowBGColor(DrawCanvas.CANVAS_BG_COLOR, ImageViewWindow.canvasWindowLayer1Bitmap.bitmapData);
            }

            UndoController.addUndoBGColorData(color);
        }

        // rgbInfoText와 그 뒤의 rgbInfoBG 공용. 5px 이내로 떼면 클릭, 5px 넘게 움직이면 배경색을 my palette로 드래그
        public static function onMouseDownRGBInfo(e:MouseEvent):void
        {
            if (!colorPickerBox.rgbInfoText.visible) // 스크래치패드가 켜져있으면 글자가 숨겨지고 배경만 남음
            {
                return;
            }

            // 눌렀던 위치로 R G B 구간을 정함 (mouse up 때 읽으면 5px 움직인 만큼 옆 구간으로 밀릴 수 있음)
            const clickedPos:int = getRgbInfoTextClickedPosIndex();

            if (numPadBox.visible) // 숫자패드로 값을 고르는 중에는 드래그 없이 클릭만 받음
            {
                onClickRGBInfo(clickedPos);
                return;
            }

            const canDrag:Boolean = PaletteController.myPalettePresetType === 0 && !PenTool.isTransparentPenColor;

            PaletteController.startColorBoxClickOrDrag(colorPickerBox.rgbInfoBG, colorPickerBox.getRGBInfoBGColor(), canDrag, function ():void
                {
                    onClickRGBInfo(clickedPos);
                });
        }

        public static function onMouseDownCurrentColor(e:MouseEvent):void
        {
            if (numPadBox.visible || LineTool.isStarted
                    || (KeyState.isKeyPressed() && !ToolState.isSelectedToolPenOrLine()
                    && !ToolState.isSelectedTool(ToolState.TOOL_ERASER)
                    && !ToolState.isSelectedTool(ToolState.TOOL_FILLPEN)))
            {
                return;
            }

            PaletteController.startColorBoxClickOrDrag(colorPickerBox.currentColorBox, colorPickerBox.getCurrentColor(), PaletteController.myPalettePresetType === 0, function ():void
                {
                    ToolController.selectPenToolIfNotDrawingTool(false);
                    selectCurrentColor(isColorPickerModeBG);
                });
        }

        private static function onClickRGBInfo(clickedPos:int):void
        {
            numpadInputBuffer = "";
            PenTool.isTransparentPenColor = false;

            if (colorPickerBox.getRGBInfoText() === "")
            {
                colorPickerBox.restoreRGBInfoText();
            }

            if (clickedPos >= 0 && clickedPos <= 3)
            {
                toggleRGBInfoTextColorType();
            }
            else
            {
                selectRGBInfoTextColorPart(clickedPos);

                if (!numPadBox.visible)
                {

                    colorPickerBox.restoreRGBInfoBackground();
                    ToolController.selectPenToolIfNotDrawingTool(false);
                    openNumPad();
                }
            }
        }

        private static function selectRGBInfoTextColorPart(clickedIndex:int):void
        {
            main.stage.focus = colorPickerBox.rgbInfoText;

            var clickedRGBPart:int = getRGBInfoTextCursorPos(clickedIndex);

            if (clickedIndex < 0)
            {
                // 음수이면 가장 오른쪽 부분 클릭
                clickedRGBPart = 2;
            }

            selectRGBInfoTextByIndex(clickedRGBPart);
        }

        public static function selectTransparentColor():void
        {
            PenTool.isTransparentPenColor = true;
            colorPickerBox.setRGBInfoBackgroundTransparent(PaletteController.myPalettePresetType);
        }

        public static function selectCurrentColor(bgmode:Boolean):void
        {
            const hexColor:uint = colorPickerBox.currentColor;
            PenTool.isTransparentPenColor = false;

            if (bgmode)
            {
                applyBGColorCanvases(hexColor);

                updateColorPickerCursorPosAndRGBInfo(hexColor);
            }
            else
            {
                PenTool.penColor = hexColor;
                ToolPanel.updateOpacityCursorPos(PenSettings.penAlphaIndex);
                updateColorPickerCursorPosAndRGBInfo(hexColor);
            }
        }

        public static function isCurrentColorSamePickedColor():Boolean
        {
            return colorPickerBox.getRGBInfoBGColor() === colorPickerBox.getCurrentColor();
        }

        public static function updatePickerCurrentColor(color:uint):void
        {
            colorPickerBox.updateCurrentColor(color);
        }

        private static function onMouseDownColorPickerBoxModeBGOFF(e:MouseEvent):void
        {
            if (UIController.isCursorInDrawArea())
            {
                isColorPickerModeResetEventAdded = false;
                main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownColorPickerBoxModeBGOFF);

                switchColorPickerModePen();
            }
        }

        private static function switchColorPickerModeBG():void
        {
            const color:uint = DrawCanvas.CANVAS_BG_COLOR;

            isColorPickerModeBG = true;

            updateColorPickerCursorPosAndRGBInfo(color);
            updatePickerCurrentColor(color);

            colorPickerBox.activePaperColorButton(true);
            colorPickerBox.transColorButton.visible = false;

            PenTool.isTransparentPenColor = false;

            if (isColorPickerModeResetEventAdded === false)
            {
                isColorPickerModeResetEventAdded = true;
                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownColorPickerBoxModeBGOFF, false, InputPriority.DEFAULT);
            }
        }

        public static function switchColorPickerModePen():void
        {
            const color:uint = PenTool.penColor;

            isColorPickerModeBG = false;

            updateColorPickerCursorPosAndRGBInfo(color);
            updatePickerCurrentColor(color);

            colorPickerBox.activePaperColorButton(false);
            colorPickerBox.transColorButton.visible = true;

            PenTool.isTransparentPenColor = false;

            if (isColorPickerModeResetEventAdded === true)
            {

                isColorPickerModeResetEventAdded = false;
                main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownColorPickerBoxModeBGOFF);
            }
        }

        private static function updatePenColor(color:uint):void
        {
            PenTool.penColor = color;
            ToolPanel.updateOpacityCursorPos(PenSettings.penAlphaIndex);
        }

        private static function isBackgroundColorMode():Boolean
        {
            return isColorPickerModeBG === true && FillPenTool.isStarted === false && LineTool.isStarted === false;
        }

        private static function isPenColorMode():Boolean
        {
            return isColorPickerModeBG === false;
        }

        private static function updateHSVColorData(h:Number, s:Number, v:Number):void
        {
            hsvColorData[0] = h;
            hsvColorData[1] = s;
            hsvColorData[2] = v;
        }

        private static function startHueColorSelection():void
        {
            const offsetX:Number = colorPickerBox.offsetX;
            const max:Number = colorPickerBox.svBoxWidth;

            var pickedColor:uint = 0;

            function pickHueColor(mx:Number):void
            {
                var hueCursorX:Number = mx;

                if (hueCursorX < 0)
                {
                    hueCursorX = 0;
                }
                else if (hueCursorX > max)
                {
                    hueCursorX = max;
                }

                colorPickerBox.hueCursor.x = hueCursorX;

                const hueValue:Number = hueCursorX / max;
                const baseColor:Vector.<uint> = Utils.HSVtoRGB(hueValue, 1.0, 1.0);
                const baseHexColor:uint = Utils.RGBtoHEX(baseColor[0], baseColor[1], baseColor[2]);

                updateHSVColorData(hueValue, hsvColorData[1], hsvColorData[2]);

                pickedColor = Utils.HSVtoHEX(hueValue, hsvColorData[1], hsvColorData[2]);

                colorPickerBox.updateHueColor(baseHexColor);
                colorPickerBox.updateRGBInfoBG(pickedColor, PaletteController.myPalettePresetType);

                if (isHSVInfoTextMode)
                {
                    colorPickerBox.updateRGBInfoText("HSV", hsvColorData);
                }
                else
                {
                    colorPickerBox.updateRGBInfoText("RGB", pickedColor);
                }
            }

            function onMouseMove():void
            {
                pickHueColor(colorPickerBox.hueColor.mouseX);
            }

            function onMouseUp():void
            {
                pickHueColor(colorPickerBox.hueColor.mouseX);

                if (isPenColorMode())
                {
                    updatePenColor(pickedColor);
                }
                else if (isBackgroundColorMode())
                {
                    applyBGColorCanvases(pickedColor);
                }

                PenSizePreviewCursor.setCursorInVisibleFlag(false);
                colorPickerBox.setRGBInfoVisible(true);
                ToolController.selectPenToolIfNotDrawingTool(false);
            }

            function onDragStart():void
            {
                Utils.setAsTopChild(colorPickerBox.hueCursor);

                PenSizePreviewCursor.setCursorInVisibleFlag(true);
                PenTool.isTransparentPenColor = false;

                colorPickerBox.setRGBInfoVisible(false);

                pickHueColor(colorPickerBox.hueColor.mouseX);
            }

            DragInteraction.start(onDragStart, onMouseMove, onMouseUp);
        }

        private static function startSVColorSelection():void
        {
            const colorBarWidth:Number = colorPickerBox.svBoxWidth;
            const colorBarHeight:Number = colorPickerBox.svBoxHeight;

            var pickedColor:uint = 0;

            function pickSVColor(mx:Number, my:Number):void
            {
                var svCursorX:Number = mx;
                var svCursorY:Number = my;

                if (svCursorX < 0)
                {
                    svCursorX = 0;
                }
                else if (svCursorX > colorBarWidth)
                {
                    svCursorX = colorBarWidth;
                }

                if (svCursorY < 0)
                {
                    svCursorY = 0;
                }
                else if (svCursorY > colorBarHeight)
                {
                    svCursorY = colorBarHeight;
                }

                colorPickerBox.svCursor.x = svCursorX;
                colorPickerBox.svCursor.y = svCursorY;

                const hueValue:Number = hsvColorData[0];
                const sValue:Number = svCursorX / colorBarWidth;
                const vValue:Number = 1 - (svCursorY / colorBarHeight);

                updateHSVColorData(hueValue, sValue, vValue);

                pickedColor = Utils.HSVtoHEX(hueValue, sValue, vValue);

                colorPickerBox.updateRGBInfoBG(pickedColor, PaletteController.myPalettePresetType);
                colorPickerBox.setRGBInfoVisible(false);

                if (isHSVInfoTextMode)
                {
                    colorPickerBox.updateRGBInfoText("HSV", hsvColorData);
                }
                else
                {
                    colorPickerBox.updateRGBInfoText("RGB", pickedColor);
                }
            }

            function onMouseMove():void
            {
                pickSVColor(colorPickerBox.svBox.mouseX, colorPickerBox.svBox.mouseY);
            }

            function onMouseUp():void
            {
                pickSVColor(colorPickerBox.svBox.mouseX, colorPickerBox.svBox.mouseY);

                if (isPenColorMode())
                {
                    PenTool.penColor = pickedColor;
                    ToolPanel.updateOpacityCursorPos(PenSettings.penAlphaIndex);
                }
                else if (isBackgroundColorMode())
                {
                    applyBGColorCanvases(pickedColor);
                }

                PenSizePreviewCursor.setCursorInVisibleFlag(false);
                colorPickerBox.setRGBInfoVisible(true);

                ToolController.selectPenToolIfNotDrawingTool(false);
            }

            function onDragStart():void
            {
                Utils.setAsTopChild(colorPickerBox.svCursor);

                PenSizePreviewCursor.setCursorInVisibleFlag(true);
                PenTool.isTransparentPenColor = false;

                colorPickerBox.setRGBInfoVisible(false);

                pickSVColor(colorPickerBox.svBox.mouseX, colorPickerBox.svBox.mouseY);
            }

            DragInteraction.start(onDragStart, onMouseMove, onMouseUp);
        }

        private static function getTegakiColorPresetIndex(index:int):int
        {
            if (index >= 10)
            {
                index = index - 10;
            }

            return Math.floor(index / 2) * 2;
        }

        public static function selectTegakiColorPreset(index:int):void
        {
            index = getTegakiColorPresetIndex(index);

            const mainColor:uint = PaletteController.myPaletteTegakiPreset[index];

            if (mainColor !== colorPickerBox.getRGBInfoBGColor())
            {
                PenTool.penColor = PaletteController.myPaletteTegakiPreset[index];
                updateColorPickerCursorPosAndRGBInfo(PenTool.penColor);
            }

            if (!FillPenTool.isStarted && !LineTool.isStarted)
            {
                const bgColor:uint = PaletteController.myPaletteTegakiPreset[index + 10];

                if (bgColor !== DrawCanvas.CANVAS_BG_COLOR)
                {
                    applyBGColorCanvases(bgColor);
                }

                ToolController.selectPenToolIfNotDrawingTool(false);
            }
        }

        public static function pickColor(pickedColor:uint):void
        {
            if (isPenColorMode())
            {
                PenTool.penColor = pickedColor;

                updateColorPickerCursorPosAndRGBInfo(pickedColor);
                ToolController.selectPenToolIfNotDrawingTool(false);
            }
            else if (isBackgroundColorMode())
            {
                applyBGColorCanvases(pickedColor);
            }
        }

        // hsv커서가 color에 맞춰서 위치를 움직여줌
        public static function updateColorPickerCursorPosAndRGBInfo(color:*):void
        {
            var hexColor:uint;
            var hsvColor:Vector.<Number>;

            if (color is uint)
            {
                hexColor = color as uint;
                hsvColor = Utils.HEXtoHSV(hexColor, hsvColorData[0]);
            }
            else if (color is Vector.<Number>)
            {
                hexColor = Utils.HSVtoHEX(color[0], color[1], color[2]);
                hsvColor = color as Vector.<Number>;
            }

            PenTool.isTransparentPenColor = false;

            hsvColorData[1] = hsvColor[1];
            hsvColorData[2] = hsvColor[2];

            if (hsvColor[1] > 0 || color is Vector.<Number>) // 채도값이 있을때만 갱신시킴
            {
                hsvColorData[0] = hsvColor[0];
                colorPickerBox.hueCursor.x = Math.round(hsvColor[0] * colorPickerBox.svBoxWidth);
            }

            colorPickerBox.svCursor.x = Math.round(hsvColor[1] * colorPickerBox.svBoxWidth);
            colorPickerBox.svCursor.y = Math.round(colorPickerBox.svBoxHeight - hsvColor[2] * colorPickerBox.svBoxHeight);

            // s v값을 제외한 순수 hue 컬러
            const baseColor:Vector.<uint> = Utils.HSVtoRGB(hsvColor[0], 1.0, 1.0);
            const baseHexColor:uint = Utils.RGBtoHEX(baseColor[0], baseColor[1], baseColor[2]);

            colorPickerBox.updateHueColor(baseHexColor);
            colorPickerBox.updateRGBInfoBG(hexColor, PaletteController.myPalettePresetType);

            if (isHSVInfoTextMode)
            {
                colorPickerBox.updateRGBInfoText("HSV", hsvColor);
            }
            else
            {
                colorPickerBox.updateRGBInfoText("RGB", hexColor);
            }
        }

        private static function handleColorPickerBoxClick(targetName:String):void
        {
            function onMouseUpColorPickerBox(e:MouseEvent):void
            {
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpColorPickerBox);

                const upTargetName:String = e.target.name;

                if (targetName === upTargetName)
                {
                    switch (upTargetName)
                    {
                        case "penColorButton":
                            if (isColorPickerModeBG)
                            {
                                switchColorPickerModePen();
                            }
                            break;

                        case "paperColorButton":
                            if (!isColorPickerModeBG && PaletteController.myPalettePresetType !== 2) // tegaki에서는 배경색 변경 불가
                            {
                                switchColorPickerModeBG();
                            }
                            break;

                        case "colorHistoryBox":
                            PaletteController.selectColorHistory();
                            break;

                        case "myPaletteBox":
                            if (PaletteController.myPaletteDragStarted === false)
                            {
                                PaletteController.selectMyPaletteColor();
                            }
                            break;

                        case "transColorButton":
                            if (colorPickerBox.transColorButton.alpha === 1.0 && PenTool.isTransparentPenColor === false)
                            {
                                ToolController.selectPenToolIfNotDrawingTool(false);
                                selectTransparentColor();
                            }
                            break;

                        case "swapPositionButton":
                            isColorPickerBoxPositionSwapped = !isColorPickerBoxPositionSwapped;
                            colorPickerBox.swapColorBoxPositions(isColorPickerBoxPositionSwapped);
                            break;

                        case "drawrPresetButton":
                            FOFOTimer.remove("clearScratchPadTimer");
                            activeColorPreset(1);
                            break;

                        case "tegakiPresetButton":
                            FOFOTimer.remove("clearScratchPadTimer");
                            activeColorPreset(2);
                            break;
                    }
                }
            }

            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpColorPickerBox, false, InputPriority.DEFAULT);
        }

        public static function handleColorPickerBoxMouseDown(target:DisplayObject):Boolean
        {
            if (ToolPanel.isToolBox2Showing || (KeyState.isKeyPressed()
                        && !ToolState.isSelectedToolPenOrLine()
                        && !ToolState.isSelectedTool(ToolState.TOOL_ERASER)
                        && !ToolState.isSelectedTool(ToolState.TOOL_FILLPEN)))
            {
                return false;
            }

            const targetName:String = target.name;

            if (targetName === "myPaletteBox")
            {
                if (PaletteController.myPalettePresetType === 0)
                {
                    PaletteController.startMyPaletteBoxDragging();
                }
            }
            else if (targetName === "colorHistoryBox")
            {
                if (PaletteController.myPalettePresetType === 0)
                {
                    PaletteController.startDraggingColorHistory();
                }
            }

            switch (targetName)
            {
                case "scratchPad":
                    colorPickerBox.scratchPad.drawReady(PenSettings.penSize, PenTool.penColor, PenSettings.penAlpha, PenSettings.penIsSquare, pickColor);
                    return true;

                case "svBox":
                    if (colorPickerBox.scratchPad && !colorPickerBox.scratchPad.visible)
                    {
                        startSVColorSelection();
                    }
                    return true;

                case "hueColor":
                    if (colorPickerBox.scratchPad && !colorPickerBox.scratchPad.visible)
                    {
                        startHueColorSelection();
                    }
                    return true;

                case "myPaletteBox":
                    if (PaletteController.myPalettePresetType === 0)
                    {
                        PaletteController.startSelectOrAddColorMyPalette();
                    }
                    else
                    {
                        handleColorPickerBoxClick(targetName);
                    }
                    return true;

                case "myPaletteButton":
                    PaletteController.selectOrResetMyPalette();
                    return true;

                case "drawrPresetButton":
                case "tegakiPresetButton":
                    InputManager.startScratchPadResetTimer(target);
                    handleColorPickerBoxClick(targetName);
                    return true;

                case "penColorButton":
                case "paperColorButton":
                case "colorHistoryBox":
                case "transColorButton":
                case "swapPositionButton":
                    handleColorPickerBoxClick(targetName);
                    return true;

                default:
                    return false;
            }

            return false;
        }
    }
}
