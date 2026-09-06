package main_module
{
    import symbols.ColorPickerSet;
    import symbols.NumPadSet;
    import flash.display.BitmapData;
    import main_module.tools.PenTool;
    import flash.geom.Point;
    import flash.events.MouseEvent;
    import flash.ui.ContextMenuBuiltInItems;
    import flash.display.DisplayObject;
    import flash.ui.ContextMenuClipboardItems;

    public class ColorPickerController
    {
        // TODO : numpad, hsv, 스크레치패드+drawr+tegaki로 나눠야함
        public static const colorPickerBox:ColorPickerSet = new ColorPickerSet();
        public static const numPadBox:NumPadSet = new NumPadSet();
        public static const hsvColorData:Vector.<Number> = new Vector.<Number>(3, true); // h,s,v순서 hue컬러 다른 함수들이랑 통신하기 위해서 전역으로 만들어줌

        public static var isColorPickerModeBG:Boolean = false; // false이면 펜컬러 true이면 배경색
        public static var isColorPickerModeResetEventAdded:Boolean = false; // 배경색 선택하고 나서 커서가 사이드바를 나가면 리셋해주는 이벤트를 올려주는 플래그

        public static var isColorPickerBoxPositionSwapped:Boolean = false; // 마이팔래트랑 컬러피커박스 위치 바뀌면 올려줌
        public static var pickerIgnoreHistoryColor:* = null; // 히스토리 색 등록 할때 여기에 등록된 색은 등록 안하게함
        public static var lastRGBInfoColorPartIndex:int = -1; // 처음 클릭했을때 R G B중 어느 영역을 클릭했는지
        public static var isHSVInfoTextMode:Boolean = false; // true가 되면 hsv false이면 rgb
        public static var numpadInputBuffer:String = ""; // 숫자키 누르면 어기다가 저장해주고 필터링해줘서 rgbinfotext에 갱신해줌

        public static function getImageDominantColor(bitmapData:BitmapData, k:int = 3, maxIter:int = 10):uint
        {
            var pixels:Vector.<uint> = bitmapData.getVector(bitmapData.rect);
            var totalPixels:int = pixels.length;

            // 초기 클러스터 중심을 무작위 픽셀에서 선택
            var centers:Array = [];

            for (var i:int = 0;i < k;i++)
            {
                var randPixel:uint = pixels[int(Math.random() * totalPixels)];

                centers.push([
                            (randPixel >> 16) & 0xFF,
                            (randPixel >> 8) & 0xFF,
                            randPixel & 0xFF
                        ]);
            }

            var assignments:Vector.<int> = new Vector.<int>(totalPixels, true);

            // 반복 학습
            for (var iter:int = 0;iter < maxIter;iter++)
            {
                // 1. 각 픽셀을 가장 가까운 클러스터에 할당
                for (var p:int = 0;p < totalPixels;p++)
                {
                    var pixel:uint = pixels[p];

                    var r:int = (pixel >> 16) & 0xFF;
                    var g:int = (pixel >> 8) & 0xFF;
                    var b:int = pixel & 0xFF;

                    var bestCluster:int = 0;
                    var bestDist:Number = Number.MAX_VALUE;

                    for (var c:int = 0;c < k;c++)
                    {
                        var cr:int = centers[c][0];
                        var cg:int = centers[c][1];
                        var cb:int = centers[c][2];

                        var dist:Number = (r - cr) * (r - cr) + (g - cg) * (g - cg) + (b - cb) * (b - cb);

                        if (dist < bestDist)
                        {
                            bestDist = dist;
                            bestCluster = c;
                        }
                    }

                    assignments[p] = bestCluster;
                }

                // 2. 클러스터 중심 재계산
                var sum:Array = [];
                var count:Array = [];

                for (c = 0;c < k;c++)
                {
                    sum[c] = [0, 0, 0];
                    count[c] = 0;
                }

                for (p = 0;p < totalPixels;p++)
                {
                    var cluster:int = assignments[p];
                    pixel = pixels[p];

                    sum[cluster][0] += (pixel >> 16) & 0xFF;
                    sum[cluster][1] += (pixel >> 8) & 0xFF;
                    sum[cluster][2] += pixel & 0xFF;

                    count[cluster]++;
                }

                for (c = 0;c < k;c++)
                {
                    if (count[c] > 0)
                    {
                        centers[c][0] = sum[c][0] / count[c];
                        centers[c][1] = sum[c][1] / count[c];
                        centers[c][2] = sum[c][2] / count[c];
                    }
                }
            }

            // 가장 큰 클러스터 찾기
            var maxCluster:int = 0;
            var maxCount:int = 0;

            for (c = 0;c < k;c++)
            {
                if (count[c] > maxCount)
                {
                    maxCount = count[c];
                    maxCluster = c;
                }
            }

            var rFinal:int = centers[maxCluster][0];
            var gFinal:int = centers[maxCluster][1];
            var bFinal:int = centers[maxCluster][2];

            return (rFinal << 16) | (gFinal << 8) | bFinal;
        }

        public static function showPickColorScratchPad():void
        {
            pickColor(colorPickerBox.scratchPad.pickColor());
        }

        public static function updatePickerBoxTransBGBrightness():void
        {
            colorPickerBox.applyTransparentColorBrightness(Global.getUIColorIndex());

            PaletteController.updateMyPaletteList();
            PaletteController.updateHistoryList();

            if (PenTool.isTransparentPenColor)
            {
                colorPickerBox.setRGBInfoBackgroundTransparent(PaletteController.myPalettePresetType);
            }
        }

        public static function rgbInfoNumPadIncKey(inc:int):void
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

        public static function pressNumpadKey(num:String):void
        {
            var startIndex:int = colorPickerBox.rgbInfoText.selectionBeginIndex;
            var endIndex:int = colorPickerBox.rgbInfoText.selectionEndIndex;
            const main:Main = Main._instance;

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

                const hsv:Vector.<Number> = Global.HEXtoHSV(Global.RGBtoHEX(arr[0], arr[1], arr[2]), hsvColorData[0]);

                hsvColorData[0] = hsv[0];
                hsvColorData[1] = hsv[1];
                hsvColorData[2] = hsv[2];
            }

            updateColorPickerCursorPosAndRGBInfo(hsvColorData);

            numPadBox.updateOkBaseColor(Global.HSVtoHEX(hsvColorData[0], hsvColorData[1], hsvColorData[2]));

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
        public static function getRGBInfoTextCursorPos(customIndex:* = null):int
        {
            if (customIndex === null)
            {
                customIndex = colorPickerBox.rgbInfoText.caretIndex;
            }

            const textBeforeCursor:String = colorPickerBox.getRGBInfoText().substring(0, customIndex);
            const rgb:Array = textBeforeCursor.split(",");

            return rgb.length - 1;
        }

        public static function keepRGBInfoTextPartFocus():void
        {

            FOFOTimer.addByName("keepRGBInfoTextPartFocusTimer", 0.0, false, function ():void
                {
                    const main:Main = Main._instance;
                    main.stage.focus = colorPickerBox.rgbInfoText;
                    selectRGBInfoTextByIndex(lastRGBInfoColorPartIndex);
                });
        }

        // index 값에 해당하는 RGB 텍스트 영역을 선택함
        public static function selectRGBInfoTextByIndex(index:int):void
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

        public static function getColorValueFromRGBInfoText():Array
        {
            var rgbText:String = colorPickerBox.getRGBInfoText().slice(4); // "RGB"와 공백 제거
            var rgb:Array = rgbText.split(","); // 쉼표로 숫자를 나눔

            return rgb;
        }

        public static function adjustSingleValueHSV(inc:int):void
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

        public static function adjustSingleValueRGB(inc:int):void
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

            updateColorPickerCursorPosAndRGBInfo(Global.RGBtoHEX(rgb[0], rgb[1], rgb[2]));

            keepRGBInfoTextPartFocus();
        }

        public static function getRgbInfoTextClickedPosIndex():int
        {
            return colorPickerBox.rgbInfoText.getCharIndexAtPoint(colorPickerBox.rgbInfoText.mouseX, 10);
        }

        public static function openNumPad():void
        {
            if (numPadBox.visible === false)
            {
                const main:Main = Main._instance;
                numPadBox.readyLCHAdjustment(Global.HSVtoHEX(hsvColorData[0], 1.0, 1.0), colorPickerBox.getRGBInfoBGColor());

                const gp:Point = colorPickerBox.rgbInfoBG.localToGlobal(new Point(0, 0));

                numPadBox.x = Math.floor(gp.x);
                numPadBox.y = Math.floor(gp.y + colorPickerBox.rgbInfoBG.height * Global.getUIScale() + 1);

                Utils.setAsTopChild(numPadBox);

                main.resetLastKey();

                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownNumPad, false, -2);
                main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownNumPad, false, -2);
            }
        }

        public static function closeNumpad():void
        {
            const main:Main = Main._instance;
            if (colorPickerBox.getRGBInfoBGColor() !== colorPickerBox.getCurrentColor())
            {
                applyAdjustedColor();
            }

            numPadBox.off();

            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownNumPad);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownNumPad);

            FOFOTimer.addByName("rgbInfoTextFocusOutEventDelayInput", 0.0, false, function ():void
                {
                    const main:Main = Main._instance;
                    main.addInputEventsDrawMode();
                });
        }

        public static function checkNumPadMouseUp(oldTargetName:String):void
        {
            const main:Main = Main._instance;
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

            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpNumpad);
        }

        public static function onRightMouseDownNumPad(e:MouseEvent):void
        {
            closeNumpad();
        }

        public static function onMouseDownNumPad(e:MouseEvent):void
        {
            if (!e.target)
            {
                return;
            }

            const targetName:String = e.target.name;
            const main:Main = Main._instance;

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
                main.startKeyRepeat(true, rgbInfoNumPadIncKey, 1);
            }
            else if (targetName === "numDec")
            {
                main.startKeyRepeat(true, rgbInfoNumPadIncKey, -1);
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

        public static function startAdjustOKLCH(index:int):void
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
        public static function toggleRGBInfoTextColorType():void
        {
            const cursorPosSave:int = getRGBInfoTextCursorPos();

            if (isHSVInfoTextMode)
            {
                isHSVInfoTextMode = false;
                colorPickerBox.updateRGBInfoText("RGB", Global.HEXtoRGB(colorPickerBox.getRGBInfoBGColor()));
            }
            else
            {
                isHSVInfoTextMode = true;
                colorPickerBox.updateRGBInfoText("HSV", Global.HEXtoHSV(colorPickerBox.getRGBInfoBGColor(), hsvColorData[0]));
            }
        }

        public static function applyAdjustedColor():void
        {
            const main:Main = Main._instance;
            const color:uint = colorPickerBox.getRGBInfoBGColor();

            if (isPenColorMode())
            {
                PenTool.penColor = color;
                main.updateOpacityCursorPos(PenTool.penAlphaIndex);
            }
            else if (isBackgroundColorMode())
            {
                updateCanvasBGColorDrawMode(color);

                if (ImageViewWindow.isCanvasWindowON)
                {
                    ImageViewWindow.updateCanvasWindowBGColor(main.CANVAS_BG_COLOR, ImageViewWindow.canvasWindowLayer1Bitmap.bitmapData);
                }

                main.addUndoBGColorData(color);
            }
        }

        public static function onMouseDownRGBInfoText(e:MouseEvent):void
        {
            var clickedPos:int = getRgbInfoTextClickedPosIndex();

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
                    const main:Main = Main._instance;
                    colorPickerBox.restoreRGBInfoBackground();
                    main.selectPenToolIfNotDrawingTool(false);
                    openNumPad();
                }
            }
        }

        public static function selectRGBInfoTextColorPart(clickedIndex:int):void
        {
            const main:Main = Main._instance;

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
            const main:Main = Main._instance;
            const hexColor:uint = colorPickerBox.currentColor;
            PenTool.isTransparentPenColor = false;

            if (bgmode)
            {
                updateCanvasBGColorDrawMode(hexColor);

                if (ImageViewWindow.isCanvasWindowON)
                {
                    ImageViewWindow.updateCanvasWindowBGColor(main.CANVAS_BG_COLOR, ImageViewWindow.canvasWindowLayer1Bitmap.bitmapData);
                }

                updateColorPickerCursorPosAndRGBInfo(hexColor);
                main.addUndoBGColorData(hexColor);
            }
            else
            {
                PenTool.penColor = hexColor;
                main.updateOpacityCursorPos(PenTool.penAlphaIndex);
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

        public static function onMouseDownColorPickerBoxModeBGOFF(e:MouseEvent):void
        {
            const main:Main = Main._instance;
            if (main.isCursorInDrawArea())
            {
                isColorPickerModeResetEventAdded = false;
                main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownColorPickerBoxModeBGOFF);

                switchColorPickerModePen();
            }
        }

        public static function switchColorPickerModeBG():void
        {
            const main:Main = Main._instance;
            const color:uint = main.CANVAS_BG_COLOR;

            isColorPickerModeBG = true;

            updateColorPickerCursorPosAndRGBInfo(color);
            updatePickerCurrentColor(color);

            colorPickerBox.activePaperColorButton(true);
            colorPickerBox.transColorButton.visible = false;

            PenTool.isTransparentPenColor = false;

            if (isColorPickerModeResetEventAdded === false)
            {
                isColorPickerModeResetEventAdded = true;
                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownColorPickerBoxModeBGOFF);
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
                const main:Main = Main._instance;
                isColorPickerModeResetEventAdded = false;
                main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownColorPickerBoxModeBGOFF);
            }
        }

        public static function updatePenColor(color:uint):void
        {
            const main:Main = Main._instance;

            PenTool.penColor = color;
            main.updateOpacityCursorPos(PenTool.penAlphaIndex);
        }

        public static function isBackgroundColorMode():Boolean
        {
            const main:Main = Main._instance;
            return isColorPickerModeBG === true && main.isFillPenStarted === false;
        }

        public static function isPenColorMode():Boolean
        {
            return isColorPickerModeBG === false;
        }

        public static function updateHSVColorData(h:Number, s:Number, v:Number):void
        {
            hsvColorData[0] = h;
            hsvColorData[1] = s;
            hsvColorData[2] = v;
        }

        public static function startHueColorSelection():void
        {
            const main:Main = Main._instance;
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
                const baseColor:Vector.<uint> = Global.HSVtoRGB(hueValue, 1.0, 1.0);
                const baseHexColor:uint = Global.RGBtoHEX(baseColor[0], baseColor[1], baseColor[2]);

                updateHSVColorData(hueValue, hsvColorData[1], hsvColorData[2]);

                pickedColor = Global.HSVtoHEX(hueValue, hsvColorData[1], hsvColorData[2]);

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
                    updateCanvasBGColorDrawMode(pickedColor);

                    if (ImageViewWindow.isCanvasWindowON)
                    {
                        ImageViewWindow.updateCanvasWindowBGColor(main.CANVAS_BG_COLOR, ImageViewWindow.canvasWindowLayer1Bitmap.bitmapData);
                    }

                    main.addUndoBGColorData(pickedColor);
                }

                main.isPenSizeCursorInvisible = false;
                colorPickerBox.setRGBInfoVisible(true);
                main.selectPenToolIfNotDrawingTool(false);
            }

            function onDragStart():void
            {
                Utils.setAsTopChild(colorPickerBox.hueCursor);

                main.isPenSizeCursorInvisible = true;
                PenTool.isTransparentPenColor = false;

                colorPickerBox.setRGBInfoVisible(false);

                pickHueColor(colorPickerBox.hueColor.mouseX);
            }

            DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
        }

        public static function startSVColorSelection():void
        {
            const main:Main = Main._instance;
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

                pickedColor = Global.HSVtoHEX(hueValue, sValue, vValue);

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
                    main.updateOpacityCursorPos(PenTool.penAlphaIndex);
                }
                else if (isBackgroundColorMode())
                {
                    updateCanvasBGColorDrawMode(pickedColor);

                    if (ImageViewWindow.isCanvasWindowON)
                    {
                        ImageViewWindow.updateCanvasWindowBGColor(main.CANVAS_BG_COLOR, ImageViewWindow.canvasWindowLayer1Bitmap.bitmapData);
                    }

                    main.addUndoBGColorData(pickedColor);
                }

                main.isPenSizeCursorInvisible = false;
                colorPickerBox.setRGBInfoVisible(true);

                main.selectPenToolIfNotDrawingTool(false);
            }

            function onDragStart():void
            {
                Utils.setAsTopChild(colorPickerBox.svCursor);

                main.isPenSizeCursorInvisible = true;
                PenTool.isTransparentPenColor = false;

                colorPickerBox.setRGBInfoVisible(false);

                pickSVColor(colorPickerBox.svBox.mouseX, colorPickerBox.svBox.mouseY);
            }

            DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
        }

        public static function updateCanvasBGColorDrawMode(color:uint):void
        {
            const main:Main = Main._instance;
            main.isFileAlreadySaved = false;
            main.CANVAS_BG_COLOR = color;

            main.canvasNavigatorBox.changeprevBitmapBGColor(color);
            main.updateCanvasBGColor(main.canvasPanel, main.CANVAS_WIDTH, main.CANVAS_HEIGHT, color);

            if (colorPickerBox.scratchPad)
            {
                colorPickerBox.scratchPad.updateBGColor(color);
            }
        }

        public static function getTegakiColorPresetIndex(index:int):int
        {
            if (index >= 10)
            {
                index = index - 10;
            }

            return Math.floor(index / 2) * 2;
        }

        public static function selectTegakiColorPreset(index:int):void
        {
            const main:Main = Main._instance;
            index = getTegakiColorPresetIndex(index);

            const mainColor:uint = PaletteController.myPaletteTegakiPreset[index];

            if (mainColor !== colorPickerBox.getRGBInfoBGColor())
            {
                PenTool.penColor = PaletteController.myPaletteTegakiPreset[index];
                updateColorPickerCursorPosAndRGBInfo(PenTool.penColor);
            }

            if (!main.isFillPenStarted)
            {
                const bgColor:uint = PaletteController.myPaletteTegakiPreset[index + 10];

                if (bgColor !== main.CANVAS_BG_COLOR)
                {
                    updateCanvasBGColorDrawMode(bgColor);

                    if (ImageViewWindow.isCanvasWindowON)
                    {
                        ImageViewWindow.updateCanvasWindowBGColor(main.CANVAS_BG_COLOR, ImageViewWindow.canvasWindowLayer1Bitmap.bitmapData);
                    }

                    main.addUndoBGColorData(bgColor);
                }

                main.selectPenToolIfNotDrawingTool(false);
            }
        }

        public static function pickColor(pickedColor:uint):void
        {
            const main:Main = Main._instance;

            if (isPenColorMode())
            {
                PenTool.penColor = pickedColor;

                updateColorPickerCursorPosAndRGBInfo(pickedColor);
                main.selectPenToolIfNotDrawingTool(false);
            }
            else if (isBackgroundColorMode())
            {
                updateCanvasBGColorDrawMode(pickedColor);

                if (ImageViewWindow.isCanvasWindowON)
                {
                    ImageViewWindow.updateCanvasWindowBGColor(main.CANVAS_BG_COLOR, ImageViewWindow.canvasWindowLayer1Bitmap.bitmapData);
                }

                main.addUndoBGColorData(pickedColor);
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
                hsvColor = Global.HEXtoHSV(hexColor, hsvColorData[0]);
            }
            else if (color is Vector.<Number>)
            {
                hexColor = Global.HSVtoHEX(color[0], color[1], color[2]);
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
            const baseColor:Vector.<uint> = Global.HSVtoRGB(hsvColor[0], 1.0, 1.0);
            const baseHexColor:uint = Global.RGBtoHEX(baseColor[0], baseColor[1], baseColor[2]);

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

        public static function handleColorPickerBoxClick(targetName:String):void
        {
            const main:Main = Main._instance;
            function onMouseUpColorPickerBox(e:MouseEvent):void
            {
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpColorPickerBox);

                const upTargetName:String = e.target.name;

                if (targetName === upTargetName)
                {
                    switch (upTargetName)
                    {
                        case "currentColor":
                            main.selectPenToolIfNotDrawingTool(false);
                            selectCurrentColor(isColorPickerModeBG);
                            break;

                        case "penColorButton":
                            if (isColorPickerModeBG)
                            {
                                switchColorPickerModePen();
                            }
                            break;

                        case "paperColorButton":
                            if (!isColorPickerModeBG)
                            {
                                switchColorPickerModeBG();
                            }
                            break;

                        case "colorHistoryBox":
                            PaletteController.selectHistoryColor();
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
                                main.selectPenToolIfNotDrawingTool(false);
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

            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpColorPickerBox);
        }

        public static function handleColorPickerBoxMouseDown(target:DisplayObject):Boolean
        {
            const main:Main = Main._instance;
            if (main.isToolBox2Showing || (main.isKeyPressed()
                        && !main.isSelectedToolPenOrLine()
                        && !main.isSelectedTool(main.TOOL_ERASER)
                        && !main.isSelectedTool(main.TOOL_FILLPEN)))
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
                    PaletteController.startColorHistoryBoxDragging();
                }
            }

            switch (targetName)
            {
                case "scratchPad":
                    colorPickerBox.scratchPad.drawReady(PenTool.penSize, PenTool.penColor, PenTool.penAlpha, PenTool.penIsSquare, pickColor);
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
                    main.startScratchPadResetTimer(target);
                    handleColorPickerBoxClick(targetName);
                    return true;

                case "penColorButton":
                case "paperColorButton":
                case "colorHistoryBox":
                case "transColorButton":
                case "currentColor":
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
