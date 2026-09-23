package Modules
{
    import flash.display.BitmapData;
    import flash.display.Bitmap;
    import flash.text.TextFormat;
    import flash.geom.Rectangle;
    import flash.geom.Matrix;
    import Symbols.CapStampFontListSet;
    import flash.geom.ColorTransform;
    import flash.events.FocusEvent;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.utils.getTimer;
    import flash.events.KeyboardEvent;

    public class CaptureStamp
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }
        public static var captureStampFontListBox:CapStampFontListSet = new CapStampFontListSet();
        private static var captrueStampBMPD:BitmapData = new BitmapData(1, 1, false, 0);
        private static var captureStampBitmap:Bitmap = new Bitmap(captrueStampBMPD);
        private static const stampAlpha:uint = 0xCB000000;
        private static const textformat:TextFormat = new TextFormat();
        private static const captureStampRect:Rectangle = new Rectangle();
        private static const bmpdMat:Matrix = new Matrix();
        private static const defaultFontSize:int = 13;
        private static var defaultBmpdHeight:int = defaultFontSize + 2;
        private static var inputUpdateTimer:int = 0;
        private static var stampBGColor:* = null;
        private static const lastRectArea:Rectangle = new Rectangle();
        private static var lastBitmapVisibleFlag:int = 0;
        private static var captureStampDominantColorRefBmpd:BitmapData = null;
        public static var isCaptureStampTextFieldFocused:Boolean = false; // 포커스 되면 올려줌
        public static var isCaptureStampEnabled:Boolean = false;

        captureStampBitmap.name = "captureStampBitmap";
        captureStampBitmap.visible = false;

        public static function updateCaptureStampButtonAlpha():void
        {
            if (CaptureStamp.isCaptureStampEnabled)
            {
                MainUI.topBar.capStamp.alpha = 1.0;
                MainUI.topBar.captureInputWarpper.visible = true;
                MainUI.topBar.capStampFont.visible = true;
            }
            else
            {
                MainUI.topBar.capStamp.alpha = Global.OFFALPHA;
                MainUI.topBar.captureInputWarpper.visible = false;
                MainUI.topBar.capStampFont.visible = false;
            }
        }

        public static function toggleCaptureStampButton():void
        {
            MainUI.topBar.capClipBoard.alpha = 1.0;
            CaptureStamp.isCaptureStampEnabled = !CaptureStamp.isCaptureStampEnabled;
            updateCaptureStampButtonAlpha();
            CaptureStamp.update();
        }

        public static function cutTimeStamp(str:String):String
        {
            const pattern:RegExp = /_\d\d\d\d\d\d\d\d\d/g;
            const findTimeStamp:String = pattern.exec(str);

            if (findTimeStamp === null)
            {
                return str;
            }

            const cutIndex:int = str.lastIndexOf(findTimeStamp);
            const cutStr:String = str.substr(0, cutIndex);

            return cutStr;
        }

        public static function getTimeStampTailHead():String
        {
            const date:Date = new Date();

            const y:Number = date.getFullYear();
            const m:Number = date.getMonth() + 1;
            const d:Number = date.getDate();

            const daystr:String = (d < 10) ? "0" + d : "" + d;
            const monthstr:String = (m < 10) ? "0" + m : "" + m;

            const timeStr:String = "[" + y + "-" + monthstr + "-" + daystr + "]";

            return timeStr;
        }

        public static function getTimeStampTail():String
        {
            const date:Date = new Date();

            const hour:Number = date.getHours();
            const min:Number = date.getMinutes();
            const sec:Number = date.getSeconds();

            const hourstr:String = (hour < 10) ? "0" + hour : "" + hour;
            const minstr:String = (min < 10) ? "0" + min : "" + min;
            const secstr:String = (sec < 10) ? "0" + sec : "" + sec;

            var milisecStr:String = new String(getTimer());

            if (milisecStr.length > 3)
                milisecStr = milisecStr.substr(milisecStr.length - 3);

            const timeStr:String = hourstr + minstr + secstr + milisecStr;

            return timeStr;
        }

        public static function hideStampFontList():void
        {
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownShowStampFontList);
            captureStampFontListBox.visible = false;
        }

        private static function onMouseDownShowStampFontList(e:MouseEvent):void
        {
            if (!(captureStampFontListBox.hitTestPoint(main.stage.mouseX, main.stage.mouseY) || MainUI.topBar.capStampFont.hitTestPoint(main.stage.mouseX, main.stage.mouseY)))
            {
                hideStampFontList();
            }
        }

        public static function showStampFontList():void
        {
            if (!captureStampFontListBox.visible)
            {
                const gp:Point = MainUI.topBar.capStampFont.localToGlobal(new Point(0, 0));
                captureStampFontListBox.x = gp.x;
                captureStampFontListBox.y = MainUI.topBar.BARSIZE * MainUI.topBar.scaleX;
                captureStampFontListBox.updateSystemFontList();
                captureStampFontListBox.setScale(Global.getUIScale());
                Utils.setAsTopChild(captureStampFontListBox);
                captureStampFontListBox.visible = true;
                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownShowStampFontList, false, -1);
            }
        }

        private static function updateLastRectArea(rect:Rectangle):void
        {
            lastRectArea.setTo(rect.x, rect.y, rect.width, rect.height);
        }

        public static function getFontName():String
        {
            return textformat.font;
        }

        private static function checkCaptrueStampBMPDHeight(twolineFlag:Boolean, mainTextWidth:Number):Number
        {
            var maxHeight:Number = kungDateStr(twolineFlag, true);
            const lines1:int = MainUI.topBar.getCaptureInputFinalLines();

            if (lines1 === 2)
                return maxHeight;

            const height2:Number = kungMainStr(twolineFlag, mainTextWidth, true);
            const lines2:int = MainUI.topBar.getCaptureInputFinalLines();

            if (lines2 === 2)
                return height2;
            else if (maxHeight < height2)
                maxHeight = height2;

            return maxHeight;
        }

        public static function changeFont(newFont:String, updateFlag:Boolean):void
        {
            textformat.font = newFont;
            captureStampFontListBox.setSelectFont(newFont);
            captureStampFontListBox.updateFontListSelect(newFont);
            MainUI.topBar.captureInputFinal.setTextFormat(textformat);

            if (updateFlag)
            {
                update();
            }
        }

        private static function getCaptureStampDate(newLine:Boolean):String
        {
            const date:Date = new Date();
            const y:Number = date.getFullYear();
            const m:Number = date.getMonth() + 1;
            const d:Number = date.getDate();
            const hour:Number = date.getHours();
            const min:Number = date.getMinutes();
            const sec:Number = date.getSeconds();

            const monthstr:String = (m < 10) ? "0" + m : "" + m;
            const daystr:String = (d < 10) ? "0" + d : "" + d;
            const hourstr:String = (hour < 10) ? "0" + hour : "" + hour;
            const minstr:String = (min < 10) ? "0" + min : "" + min;
            const secstr:String = (sec < 10) ? "0" + sec : "" + sec;

            // return y+"-"+monthstr+"-"+daystr+" "+hourstr+":"+minstr+":"+secstr;
            return y + "-" + monthstr + "-" + daystr
                + ((newLine) ? "\n" : " ")
                + hourstr + ":" + minstr + ":" + secstr;
        }

        private static function getAppNameString(newLine:Boolean):String
        {
            return "FOFO PAINT"
                + ((newLine) ? "\n" : " ")
                + main.APP_VERSION;
        }

        private static function getTextWidthText(text:String, offset:Number):Number
        {
            const backupStr:String = MainUI.topBar.captureInputFinal.text;
            const backupWidth:Number = MainUI.topBar.getCaptureInputFinalWidth();

            MainUI.topBar.setCaptureInputFinalWidth(CanvasController.CANVAS_MAX_SIZE);
            MainUI.topBar.setCaptureInputFinalString(text);

            const width:Number = MainUI.topBar.captureInputFinal.textWidth + offset;

            MainUI.topBar.setCaptureInputFinalString(backupStr);
            MainUI.topBar.setCaptureInputFinalWidth(backupWidth);

            return width;
        }

        private static function getTextWidthAppName(newLine:Boolean):Number
        {
            return getTextWidthText(getAppNameString(newLine), 5);
        }

        private static function getTextWidthDate(newLine:Boolean):Number
        {
            return getTextWidthText(getCaptureStampDate(newLine), 10);
        }

        private static function getTextWidthMain():Number
        {
            return getTextWidthText(MainUI.topBar.getCaptureInputString(), 2);
        }

        private static function kungStamp(textStr:String, textWidth:Number, align:String, posX:Number, offsetX:Number, testHeightFlag:Boolean):Number
        {
            textformat.align = align;
            MainUI.topBar.captureInputFinal.defaultTextFormat = textformat;
            MainUI.topBar.setCaptureInputFinalWidth(textWidth);
            MainUI.topBar.setCaptureInputFinalString(textStr);

            if (testHeightFlag)
            {
                return MainUI.topBar.captureInputFinal.textHeight;
            }

            bmpdMat.identity();
            bmpdMat.translate(posX + offsetX, 0);
            captrueStampBMPD.draw(MainUI.topBar.captureInputFinal, bmpdMat);

            return 0;
        }

        private static function kungAppnameStr(newLine:Boolean, testHeightFlag:Boolean):Number
        {
            const textWidth:Number = getTextWidthAppName(newLine);

            return kungStamp(getAppNameString(newLine), textWidth, "right", captrueStampBMPD.width - textWidth, 2, testHeightFlag);
        }

        private static function kungMainStr(newLine:Boolean, textWidth:Number, testHeightFlag:Boolean):Number
        {
            return kungStamp(MainUI.topBar.getCaptureInputString(), textWidth, "left", getTextWidthDate(newLine), 0, testHeightFlag);
        }

        private static function kungDateStr(newLine:Boolean, testHeightFlag:Boolean):Number
        {
            return kungStamp(getCaptureStampDate(newLine), getTextWidthDate(newLine), "left", 2, 0, testHeightFlag);
        }

        public static function kungFinal(inputBMPD:BitmapData):void
        {
            update(); // 미자막 시간 찍어줘야함

            const mat:Matrix = new Matrix();
            const ct:ColorTransform = new ColorTransform();

            mat.translate(0, inputBMPD.height - captrueStampBMPD.height);
            inputBMPD.draw(captureStampBitmap, mat, ct);
        }

        private static function getCaptureAreaBmpd(clipRect:Rectangle, layer1:Boolean, layer2:Boolean):BitmapData
        {
            var longEdge:Number;
            var areaWidth:Number;
            var areaHeight:Number;

            const fullImageFlag:Boolean = clipRect.width === 0 && clipRect.height === 0;

            if (fullImageFlag)
            {
                longEdge = CanvasController.CANVAS_HEIGHT > CanvasController.CANVAS_WIDTH ? CanvasController.CANVAS_HEIGHT : CanvasController.CANVAS_WIDTH;
                areaWidth = CanvasController.CANVAS_WIDTH;
                areaHeight = CanvasController.CANVAS_HEIGHT;
            }
            else
            {
                longEdge = clipRect.height > clipRect.width ? clipRect.height : clipRect.width;
                areaWidth = clipRect.width;
                areaHeight = clipRect.height;
            }

            if (areaWidth === 0 || areaHeight === 0)
            {
                return null;
            }

            var scale:Number = 1.0;

            if (longEdge > 100)
            {
                scale = 100 / longEdge;
            }

            const scaledWidth:Number = areaWidth * scale;
            const scaledHeight:Number = areaHeight * scale;

            const mat:Matrix = new Matrix();
            mat.scale(scale, scale);

            const tmpbmpd:BitmapData = new BitmapData(scaledWidth, scaledHeight, true, 0);
            const rawbmpd:BitmapData = CanvasController.getMergedBitmapdtata(false, layer1, layer2, (fullImageFlag) ? null : clipRect);

            tmpbmpd.draw(rawbmpd, mat);
            rawbmpd.dispose();

            return tmpbmpd;
        }

        private static function onFocusOutCaptureStampInput(e:FocusEvent):void
        {
            FOFOTimer.add(0.2, false, function ():void
                {
                    InputController.tryDisableIME();
                    isCaptureStampTextFieldFocused = false;
                });
        }

        private static function onFocusInCaptureStampInput(e:FocusEvent):void
        {
            isCaptureStampTextFieldFocused = true;

            FOFOTimer.add(0.0, false, function ():void
                {
                    MainUI.topBar.captureInput.setSelection(0, MainUI.topBar.captureInput.text.length);
                });
        }

        private static function onChangeCaptureStampInput(e:Event):void
        {
            MainUI.topBar.capClipBoard.alpha = 1.0;

            if (!FOFOTimer.hasTimer("inputUpdateTimer"))
            {
                FOFOTimer.addByName("inputUpdateTimer", 0.2, false, update);
            }
        }

        public static function setVisible(flag:Boolean):void
        {
            if (captureStampBitmap.visible !== flag)
            {
                captureStampBitmap.visible = flag;
            }
        }

        private static function checkPosition(bmpdHeight:Number):void
        {
            const rect:Rectangle = CaptureArea.getCaptureArea();
            const rotateFlag:uint = CaptureController.captureCanvasRotationStep;
            var offsetX:Number;
            var offsetY:Number;

            if (CaptureArea.isFullImageCapture())
            {

                offsetX = (ReplayController.isReplayModeON) ? ReplayController.RCANVAS_WIDTH : CanvasController.CANVAS_WIDTH;
                offsetY = (ReplayController.isReplayModeON) ? ReplayController.RCANVAS_HEIGHT : CanvasController.CANVAS_HEIGHT;
            }
            else
            {
                offsetX = rect.width;
                offsetY = rect.height;
            }

            if (CaptureController.isCaptureCanvasFlipped)
            {
                captureStampBitmap.scaleX = -1.0;

                if (rotateFlag === 0)
                {
                    captureStampBitmap.rotation = 0;
                    captureStampBitmap.x = rect.x + offsetX;
                    captureStampBitmap.y = rect.y + offsetY - bmpdHeight;
                }
                else if (rotateFlag === 1)
                {
                    captureStampBitmap.rotation = 90;
                    captureStampBitmap.x = rect.x + bmpdHeight;
                    captureStampBitmap.y = rect.y + offsetY;
                }
                else if (rotateFlag === 2)
                {
                    captureStampBitmap.rotation = 180;
                    captureStampBitmap.x = rect.x;
                    captureStampBitmap.y = rect.y + bmpdHeight;
                }
                else if (rotateFlag === 3)
                {
                    captureStampBitmap.rotation = -90;
                    captureStampBitmap.x = rect.x + offsetX - bmpdHeight;
                    captureStampBitmap.y = rect.y;
                }
            }
            else
            {
                captureStampBitmap.scaleX = 1.0;

                if (rotateFlag === 0)
                {
                    captureStampBitmap.rotation = 0;
                    captureStampBitmap.x = rect.x;
                    captureStampBitmap.y = rect.y + offsetY - bmpdHeight;
                }
                else if (rotateFlag === 1)
                {
                    captureStampBitmap.rotation = -90;
                    captureStampBitmap.x = rect.x + offsetX - bmpdHeight;
                    captureStampBitmap.y = rect.y + offsetY;
                }
                else if (rotateFlag === 2)
                {
                    captureStampBitmap.rotation = 180;
                    captureStampBitmap.x = rect.x + offsetX;
                    captureStampBitmap.y = rect.y + bmpdHeight;
                }
                else if (rotateFlag === 3)
                {
                    captureStampBitmap.rotation = 90;
                    captureStampBitmap.x = rect.x + bmpdHeight;
                    captureStampBitmap.y = rect.y;
                }
            }
        }

        private static function getCaptureAreaWidth(rect:Rectangle):Number
        {
            const notRotatedFlag:Boolean = CaptureController.captureCanvasRotationStep % 2 === 0;

            if (notRotatedFlag)
            {
                if (CaptureArea.isFullImageCapture())
                {

                    return (ReplayController.isReplayModeON) ? ReplayController.RCANVAS_WIDTH : CanvasController.CANVAS_WIDTH;
                }
                else
                {
                    return rect.width;
                }
            }
            else
            {
                if (CaptureArea.isFullImageCapture())
                {
                    return (ReplayController.isReplayModeON) ? ReplayController.RCANVAS_HEIGHT : CanvasController.CANVAS_HEIGHT;
                }
                else
                {
                    return rect.height;
                }
            }

            return 0;
        }

        private static function getColorBrightness(color:uint):Number
        {
            var red:int = (color >> 16) & 0xFF;
            var green:int = (color >> 8) & 0xFF;
            var blue:int = color & 0xFF;

            // 밝기 계산
            var brightness:Number = 0.299 * red + 0.587 * green + 0.114 * blue;

            return brightness;
        }

        /**
         * 비슷한 RGB 색상을 k개 이하로 묶고,
         * 가장 많은 표본이 속한 묶음의 평균색을 반환합니다.
         *
         * 주의:
         * 전달받은 bitmapData는 이 함수에서 dispose()합니다.
         * 현재처럼 분석용 임시 BitmapData만 전달해야 합니다.
         *
         * alpha < 128인 픽셀은 분석에서 제외합니다.
         * 유효한 픽셀이 없으면 흰색을 반환합니다.
         *
         * 동일한 이미지와 인자는 항상 같은 결과를 반환합니다.
         * gpt6-mediaum
         */
        private static function getImageDominantColor(
                bitmapData:BitmapData,
                k:int = 3,
                maxIter:int = 6,
                maxSamples:int = 3000):uint
        {
            if (bitmapData === null)
            {
                return 0xFFFFFF;
            }

            // 잘못된 인자는 최소 유효값으로 보정합니다.
            if (k < 1)
            {
                k = 1;
            }

            if (maxIter < 1)
            {
                maxIter = 1;
            }

            if (maxSamples < 1)
            {
                maxSamples = 1;
            }

            var pixels:Vector.<uint>;

            // 픽셀 추출 후에는 원본 임시 이미지가 필요하지 않습니다.
            try
            {
                pixels = bitmapData.getVector(bitmapData.rect);
            }
            finally
            {
                bitmapData.dispose();
            }

            const total:int = pixels.length;

            if (total === 0)
            {
                return 0xFFFFFF;
            }

            const capacity:int =
                (maxSamples < total) ? maxSamples : total;

            const sampleR:Vector.<int> = new Vector.<int>(capacity, true);
            const sampleG:Vector.<int> = new Vector.<int>(capacity, true);
            const sampleB:Vector.<int> = new Vector.<int>(capacity, true);

            var sampleCount:int = 0;
            var validCount:int = 0;

            // 고정 시드: 호출할 때마다 같은 표본을 선택합니다.
            var randomState:uint = 0x6D2B79F5;

            var p:int;
            var pixel:uint;
            var slot:int;

            // 1. 불투명 픽셀 중 최대 capacity개를 선택합니다.
            // 고정 간격 대신 reservoir sampling을 사용합니다.
            for (p = 0;p < total;p++)
            {
                pixel = pixels[p];

                if ((pixel >>> 24) < 128)
                {
                    continue;
                }

                validCount++;

                if (sampleCount < capacity)
                {
                    slot = sampleCount;
                    sampleCount++;
                }
                else
                {
                    // xorshift32
                    randomState ^= randomState << 13;
                    randomState ^= randomState >>> 17;
                    randomState ^= randomState << 5;

                    // 0 이상 validCount 미만의 인덱스.
                    slot = int(
                            (Number(randomState) / 4294967296.0)
                            * validCount);

                    if (slot >= capacity)
                    {
                        continue;
                    }
                }

                sampleR[slot] = (pixel >>> 16) & 0xFF;
                sampleG[slot] = (pixel >>> 8) & 0xFF;
                sampleB[slot] = pixel & 0xFF;
            }

            pixels = null;

            if (sampleCount === 0)
            {
                return 0xFFFFFF;
            }

            if (sampleCount === 1)
            {
                return uint(
                        (sampleR[0] << 16)
                        | (sampleG[0] << 8)
                        | sampleB[0]);
            }

            if (k > sampleCount)
            {
                k = sampleCount;
            }

            // 2. 서로 떨어진 색상으로 초기 중심을 구성합니다.
            const centerR:Vector.<int> = new Vector.<int>(k, true);
            const centerG:Vector.<int> = new Vector.<int>(k, true);
            const centerB:Vector.<int> = new Vector.<int>(k, true);

            centerR[0] = sampleR[0];
            centerG[0] = sampleG[0];
            centerB[0] = sampleB[0];

            // 각 표본과 가장 가까운 기존 중심 사이의 거리.
            const nearestDistance:Vector.<int> =
                new Vector.<int>(sampleCount, true);

            var i:int;
            var c:int;
            var dr:int;
            var dg:int;
            var db:int;
            var distance:int;

            for (i = 0;i < sampleCount;i++)
            {
                nearestDistance[i] = 0x7FFFFFFF;
            }

            var farthestIndex:int;
            var farthestDistance:int;

            for (c = 1;c < k;c++)
            {
                farthestIndex = 0;
                farthestDistance = -1;

                for (i = 0;i < sampleCount;i++)
                {
                    // 직전에 추가한 중심까지의 거리만 추가 계산합니다.
                    dr = sampleR[i] - centerR[c - 1];
                    dg = sampleG[i] - centerG[c - 1];
                    db = sampleB[i] - centerB[c - 1];

                    distance = dr * dr + dg * dg + db * db;

                    if (distance < nearestDistance[i])
                    {
                        nearestDistance[i] = distance;
                    }

                    if (nearestDistance[i] > farthestDistance)
                    {
                        farthestDistance = nearestDistance[i];
                        farthestIndex = i;
                    }
                }

                // 모든 표본 색상이 이미 기존 중심에 포함됩니다.
                if (farthestDistance <= 0)
                {
                    k = c;
                    break;
                }

                centerR[c] = sampleR[farthestIndex];
                centerG[c] = sampleG[farthestIndex];
                centerB[c] = sampleB[farthestIndex];
            }

            // 3. 표본을 가까운 중심에 할당하고 평균색을 구합니다.
            // 합계는 인자 확장 시 정수 오버플로를 피하도록 Number 사용.
            const sumR:Vector.<Number> = new Vector.<Number>(k, true);
            const sumG:Vector.<Number> = new Vector.<Number>(k, true);
            const sumB:Vector.<Number> = new Vector.<Number>(k, true);
            const counts:Vector.<int> = new Vector.<int>(k, true);

            var iter:int;
            var bestCluster:int;
            var bestDistance:int;

            var nextR:int;
            var nextG:int;
            var nextB:int;
            var changed:Boolean;

            // 마지막 중심 갱신 뒤 한 번 더 분류하여
            // 최종 중심에 대응하는 표본 수와 합계를 얻습니다.
            for (iter = 0;iter <= maxIter;iter++)
            {
                for (c = 0;c < k;c++)
                {
                    sumR[c] = 0;
                    sumG[c] = 0;
                    sumB[c] = 0;
                    counts[c] = 0;
                }

                for (i = 0;i < sampleCount;i++)
                {
                    bestCluster = 0;
                    bestDistance = 0x7FFFFFFF;

                    for (c = 0;c < k;c++)
                    {
                        dr = sampleR[i] - centerR[c];
                        dg = sampleG[i] - centerG[c];
                        db = sampleB[i] - centerB[c];

                        distance = dr * dr + dg * dg + db * db;

                        if (distance < bestDistance)
                        {
                            bestDistance = distance;
                            bestCluster = c;
                        }
                    }

                    sumR[bestCluster] += sampleR[i];
                    sumG[bestCluster] += sampleG[i];
                    sumB[bestCluster] += sampleB[i];
                    counts[bestCluster]++;
                }

                if (iter === maxIter)
                {
                    break;
                }

                changed = false;

                for (c = 0;c < k;c++)
                {
                    if (counts[c] === 0)
                    {
                        continue;
                    }

                    nextR = int(sumR[c] / counts[c] + 0.5);
                    nextG = int(sumG[c] / counts[c] + 0.5);
                    nextB = int(sumB[c] / counts[c] + 0.5);

                    if (nextR !== centerR[c]
                            || nextG !== centerG[c]
                            || nextB !== centerB[c])
                    {
                        changed = true;
                    }

                    centerR[c] = nextR;
                    centerG[c] = nextG;
                    centerB[c] = nextB;
                }

                if (!changed)
                {
                    break;
                }
            }

            // 4. 가장 많은 표본이 속한 묶음을 선택합니다.
            var dominantCluster:int = 0;

            for (c = 1;c < k;c++)
            {
                if (counts[c] > counts[dominantCluster])
                {
                    dominantCluster = c;
                }
            }

            // sampleCount > 0이므로 선택된 묶음에는 표본이 있습니다.
            const dominantCount:int = counts[dominantCluster];

            const resultR:int =
                int(sumR[dominantCluster] / dominantCount + 0.5);
            const resultG:int =
                int(sumG[dominantCluster] / dominantCount + 0.5);
            const resultB:int =
                int(sumB[dominantCluster] / dominantCount + 0.5);

            return uint(
                    (resultR << 16)
                    | (resultG << 8)
                    | resultB);
        }

        public static function update():void
        {
            if (isCaptureStampEnabled)
            {
                const rect:Rectangle = CaptureArea.getCaptureArea();
                const bmpdWidth:Number = getCaptureAreaWidth(rect);

                if (bmpdWidth < 300)
                {
                    if (captureStampBitmap.visible === true)
                    {
                        captureStampBitmap.visible = false;
                    }
                    return;
                }

                const layer1Visible:Boolean = (ReplayController.isReplayModeON) ? ReplayController.rCanvasLayer1Bitmap.visible : CanvasController.canvasLayer1Bitmap.visible;
                const layer2Visible:Boolean = (ReplayController.isReplayModeON) ? ReplayController.rCanvasLayer2Bitmap.visible : CanvasController.canvasLayer2Bitmap.visible;

                var bitmapVisibleFlag:int = 0;

                if (layer1Visible)
                {
                    bitmapVisibleFlag += 1;
                }
                if (layer2Visible)
                {
                    bitmapVisibleFlag += 2;
                }

                if (stampBGColor === null || !rect.equals(lastRectArea) || lastBitmapVisibleFlag !== bitmapVisibleFlag)
                {
                    const tegakiBGColorIndex:int = PaletteController.myPaletteTegakiPreset.indexOf((ReplayController.isReplayModeON) ? ReplayController.RCANVAS_BG_COLOR : CanvasController.CANVAS_BG_COLOR);

                    if (tegakiBGColorIndex >= 0)
                    {
                        stampBGColor = PaletteController.myPaletteTegakiPreset[tegakiBGColorIndex - 10];
                    }
                    else
                    {
                        stampBGColor = getImageDominantColor(getCaptureAreaBmpd(rect, layer1Visible, layer2Visible));
                    }

                    updateLastRectArea(rect);
                }

                lastBitmapVisibleFlag = bitmapVisibleFlag;

                var dateStrWidth:Number = getTextWidthDate(false);
                var appStrWidth:Number = getTextWidthAppName(false);
                var mainTextWidth:Number = bmpdWidth - (dateStrWidth + appStrWidth) - 1;

                textformat.size = defaultFontSize;
                MainUI.topBar.captureInput.maxChars = 0;
                MainUI.topBar.captureInputFinal.defaultTextFormat = textformat;
                MainUI.topBar.setCaptureInputFinalWidth(mainTextWidth);
                MainUI.topBar.setCaptureInputFinalString(MainUI.topBar.getCaptureInputString());

                var twolineFlag:Boolean = false;

                if (MainUI.topBar.getCaptureInputFinalLines() >= 2)
                {
                    twolineFlag = true;
                    var loopcount:int = 0;

                    do
                    {
                        textformat.size = defaultFontSize - loopcount;
                        MainUI.topBar.captureInputFinal.defaultTextFormat = textformat;

                        dateStrWidth = getTextWidthDate(true);
                        appStrWidth = getTextWidthAppName(true);
                        mainTextWidth = bmpdWidth - (dateStrWidth + appStrWidth) - 1;

                        MainUI.topBar.setCaptureInputFinalWidth(mainTextWidth);
                        MainUI.topBar.setCaptureInputFinalString(MainUI.topBar.getCaptureInputString());

                        loopcount++;

                        if (defaultFontSize - loopcount <= 13)
                        {
                            // 글씨크기를 한계까지 줄이고 칸이 꽉차면 더이상 입력 못하게함
                            if (MainUI.topBar.captureInputFinal.numLines >= 3)
                            {
                                MainUI.topBar.captureInput.maxChars = 1;
                                MainUI.topBar.captureInput.text = MainUI.topBar.captureInput.text.slice(0, -1);
                            }
                            break;
                        }
                    }
                    while (MainUI.topBar.getCaptureInputFinalLines() >= 3);
                }

                if (captrueStampBMPD)
                {
                    captrueStampBMPD.dispose();
                }

                var bmpdHeight:Number = checkCaptrueStampBMPDHeight(twolineFlag, mainTextWidth);

                captrueStampBMPD = new BitmapData(bmpdWidth, bmpdHeight, true, stampAlpha | stampBGColor);
                captureStampBitmap.bitmapData = captrueStampBMPD;

                if (getColorBrightness(stampBGColor) >= 150)
                {
                    MainUI.topBar.captureInputFinal.textColor = 0x0;
                }
                else
                {
                    MainUI.topBar.captureInputFinal.textColor = 0xFFFFFF;
                }

                kungDateStr(twolineFlag, false);
                kungMainStr(twolineFlag, mainTextWidth, false);
                kungAppnameStr(twolineFlag, false);

                if (captureStampBitmap.visible === false)
                {
                    captureStampBitmap.visible = true;
                }

                if (ReplayController.isReplayModeON)
                {
                    if (ReplayController.rCanvasPanel.getChildByName("captureStampBitmap") === null)
                    {
                        ReplayController.rCanvasPanel.addChild(captureStampBitmap);
                    }
                }
                else if (CanvasController.canvasPanel.getChildByName("captureStampBitmap") === null)
                {
                    CanvasController.canvasPanel.addChild(captureStampBitmap);
                }

                checkPosition(bmpdHeight);
            }
            else if (captureStampBitmap.visible === true)
            {
                if (ReplayController.isReplayModeON)
                {
                    if (ReplayController.rCanvasPanel.getChildByName("captureStampBitmap") !== null)
                    {
                        ReplayController.rCanvasPanel.removeChild(captureStampBitmap);
                    }
                }
                else if (CanvasController.canvasPanel.getChildByName("captureStampBitmap") !== null)
                {
                    CanvasController.canvasPanel.removeChild(captureStampBitmap);
                }

                captureStampBitmap.visible = false;
            }
        }

        public static function off():void
        {
            if (ReplayController.isReplayModeON)
            {
                ReplayController.rCanvasPanel.scrollRect = new Rectangle(0, 0, ReplayController.RCANVAS_WIDTH, ReplayController.RCANVAS_HEIGHT);
            }
            else
            {
                CanvasController.canvasPanel.scrollRect = new Rectangle(0, 0, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
            }

            if (captrueStampBMPD)
            {
                captrueStampBMPD.dispose();
            }

            captrueStampBMPD = null;

            MainUI.topBar.captureInput.removeEventListener(Event.CHANGE, onChangeCaptureStampInput);
            MainUI.topBar.captureInput.removeEventListener(FocusEvent.FOCUS_IN, onFocusInCaptureStampInput);
            MainUI.topBar.captureInput.removeEventListener(FocusEvent.FOCUS_OUT, onFocusOutCaptureStampInput);

            captureStampBitmap.visible = false;

            if (CanvasController.canvasPanel.getChildByName("captureStampBitmap") !== null)
            {
                CanvasController.canvasPanel.removeChild(captureStampBitmap);
            }
        }

        public static function init():void
        {
            if (ReplayController.isReplayModeON)
            {
                ReplayController.rCanvasPanel.scrollRect = null;
            }
            else
            {
                CanvasController.canvasPanel.scrollRect = null;
            }

            textformat.font = null;
            stampBGColor = null;

            MainUI.topBar.captureInput.addEventListener(Event.CHANGE, onChangeCaptureStampInput);
            MainUI.topBar.captureInput.addEventListener(FocusEvent.FOCUS_IN, onFocusInCaptureStampInput);
            MainUI.topBar.captureInput.addEventListener(FocusEvent.FOCUS_OUT, onFocusOutCaptureStampInput);
        }
    }
}
