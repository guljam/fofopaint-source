package main_module
{
    import main_module.MainUIController;
    import flash.display.Sprite;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.SimpleButton;
    import flash.display.IBitmapDrawable;
    import flash.events.MouseEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileStream;
    import flash.filesystem.FileMode;
    import flash.geom.Point;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import flash.utils.getTimer;
    import symbols.RefLayerMenuSet;

    public final class ReferenceLayerController
    {
        public static const REFLAYER_VISIBLE_DELAY:Number = 0.7;

        public static const canvasRefLayer:Sprite = new Sprite(); // 트레이스 레이어임

        public static var isRefLayerMemoryTrainingON:Boolean = false, // 이거 켜지면 캔버스 그릴때 임시적으로 안보이게함
            canvasRefLayerBitmapData:BitmapData = new BitmapData(1, 1, true, 0),
            canvasRefLayerBitmap:Bitmap = new Bitmap(),
            refLayerMenuBox:RefLayerMenuSet = new RefLayerMenuSet(),
            refLayerMenuDragXMoveSum:Number = 0, // 전역으로 돌려서 다시 클릭하거나 이미지를 불러와도 원래 스케일을 저장하도록함
            isRefLayerMenuON:Boolean = false, // 참조레이어 메뉴 켜졌을때 올려줌
            refLayerRawBitmapData:BitmapData = null,
            refLayerRawTransformData:Array = null,
            refLayerMenuConfirmCount:int = 0, // 2번이상 클릭하면 되게
            refLayerLastAlpha:Number = 0.5,
            refLayerVisibleDelayOffTime:int = 0; // setCanvasRefLayerVisibleSlowly함수가 setCanvasRefLayerVisibleDelay함수보다 빨리 켜지지 않게 하기

        public static const refLayerImageFilePath:File = File.applicationStorageDirectory.resolvePath("refimg");

        public static var refLayerImageData:ByteArray = new ByteArray();

        public static function mergeImageToRefLayer(layer1:IBitmapDrawable, layer2:IBitmapDrawable):void
        {
            const main:Main = Main._instance;

            var tmpbmpd:BitmapData = new BitmapData(main.CANVAS_WIDTH, main.CANVAS_HEIGHT, true, 0);
            const mat:Matrix = new Matrix();

            mat.scale(canvasRefLayer.scaleX, canvasRefLayer.scaleY);
            mat.rotate(canvasRefLayer.rotation * Math.PI / 180);
            mat.translate(main.CANVAS_WIDTH / 2, main.CANVAS_HEIGHT / 2);

            tmpbmpd.draw(canvasRefLayer, mat);

            if (layer2 !== null)
            {
                tmpbmpd.draw(layer2);
            }
            if (layer1 !== null)
            {
                tmpbmpd.draw(layer1);
            }

            canvasRefLayerBitmapData = main.updateBitmapData(canvasRefLayerBitmapData, tmpbmpd, canvasRefLayerBitmap);

            tmpbmpd.dispose();
            tmpbmpd = null;
        }

        public static function handleOneMoreClickMergeIntoRefLayer(menuBox:DisplayObject, button:SimpleButton, hintstr:String, func:Function):void
        {
            Utils.setAsTopChild(menuBox);
            refLayerMenuConfirmCount++;

            function onMouseOutCancel(e:MouseEvent):void
            {
                button.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOutCancel);
                refLayerMenuConfirmCount = 0;
            }

            if (refLayerMenuConfirmCount === 1)
            {
                menuBox["hint"]("One more click to OK");
                button.addEventListener(MouseEvent.MOUSE_OUT, onMouseOutCancel);
            }
            else if (refLayerMenuConfirmCount === 2)
            {
                button.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOutCancel);
                refLayerMenuConfirmCount = 0;

                menuBox["hint"](hintstr);
                func();
            }
        }

        public static function mergeCanvasImageIntoRefLayer():void
        {
            if (refLayerMenuBox.refTransferCanvasImageButton.alpha !== 1.0)
            {
                return;
            }

            handleOneMoreClickMergeIntoRefLayer(
                    refLayerMenuBox,
                    refLayerMenuBox.refTransferCanvasImageButton,
                    HintStrings.STRING_MERGE_INTO_REFLAYER,
                    mergeCanvasImageToRefLayer);
        }

        public static function onMouseOverRefLayerMenuHint(e:MouseEvent):void
        {
            const main:Main = Main._instance;

            if (!isRefLayerMenuON)
            {
                main.stage.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOverRefLayerMenuHint);
                return;
            }

            if (refLayerMenuBox.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
            {
                if (refLayerMenuBox.getHintStr() !== "Reference layer")
                {
                    refLayerMenuBox.hint("Reference layer");
                }

                return;
            }

            if (main.isMouseDragging === true)
            {
                return;
            }

            refLayerMenuBox.hint(HintStrings.getHintFromTargetNameRefLayer(e.target.name));
        }

        public static function updateRefLayerOpacityCursorPosByValue(alpha:Number):void
        {
            refLayerMenuBox.refOpacityCursor.x = (refLayerMenuBox.refOpacityBar.x + 1) + (refLayerMenuBox.refOpacityBar.width * alpha);
        }

        public static function closeRefLayerMenu():void
        {
            isRefLayerMenuON = false;
            refLayerMenuBox.visible = false;
            refLayerMenuBox.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpRefLayerMenu);
        }

        public static function onRightMouseUpRefLayerMenu(e:MouseEvent):void
        {
            const main:Main = Main._instance;

            if (!isRefLayerMenuON)
                return;

            const target:DisplayObject = e.target as DisplayObject;
            if (!target)
            {
                return;
            }

            switch (target.name)
            {
                case "refRotateImageButton":
                    {
                        if (canvasRefLayer.rotation !== 0)
                        {
                            main.isFileAlreadySaved = false;

                            canvasRefLayer.rotation = 0;
                        }
                    }
                    break;

                case "refResizeImageButton":
                    {
                        if (canvasRefLayer.scaleY !== 1.0)
                        {
                            main.isFileAlreadySaved = false;

                            canvasRefLayer.scaleX = (canvasRefLayer.scaleX < 0) ? -1.0 : 1.0;
                            canvasRefLayer.scaleY = 1.0;
                        }
                    }
                    break;

                case "refMoveImageButton":
                    {
                        if (canvasRefLayerBitmap.x !== -canvasRefLayerBitmap.width / 2
                                && canvasRefLayerBitmap.y !== -canvasRefLayerBitmap.height / 2)
                        {
                            main.isFileAlreadySaved = false;

                            canvasRefLayer.x = main.CANVAS_WIDTH / 2;
                            canvasRefLayer.y = main.CANVAS_HEIGHT / 2;

                            canvasRefLayerBitmap.x = -canvasRefLayerBitmap.bitmapData.width / 2;
                            canvasRefLayerBitmap.y = -canvasRefLayerBitmap.bitmapData.height / 2;
                        }
                    }
                    break;

                default:
                    break;
            }
        }

        public static function openRefLayerMenu():void // load clip버튼에서 눌러줬을때 틀여줌
        {
            const main:Main = Main._instance;

            refLayerMenuBox.hint("Reference layer");
            refLayerMenuBox.x = Math.floor(main.stage.mouseX - refLayerMenuBox.width / 2);
            refLayerMenuBox.y = Math.floor(main.stage.mouseY - 8);
            refLayerMenuBox.visible = true;

            Utils.setAsTopChild(refLayerMenuBox);
            MainUIController.keepBoxInsideViewPort(refLayerMenuBox);

            if (isRefLayerMenuON === false)
            {
                refLayerMenuBox.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpRefLayerMenu);
                main.stage.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverRefLayerMenuHint);
            }

            isRefLayerMenuON = true;
            Utils.setAsTopChild(refLayerMenuBox);
        }

        public static function isRefLayerImageAlreadyCleared():Boolean
        {
            return (canvasRefLayerBitmapData && canvasRefLayerBitmapData.width > 1 && canvasRefLayerBitmapData.height > 1)
                || !canvasRefLayerBitmapData;
        }

        public static function startReflayerClear():void
        {
            Utils.setAsTopChild(refLayerMenuBox);

            if (isRefLayerImageAlreadyCleared())
            {
                clearRefLayerImage();
            }

            if (isRefLayerMemoryTrainingON)
            {
                toggleRefLayerMemoryTraining();
            }
        }

        public static function setCanvasRefLayerInvisible():void
        {
            if (FOFOTimer.hasTimer("refLayerVisibleDelayTimer"))
            {
                FOFOTimer.remove("refLayerVisibleDelayTimer");
                if (refLayerVisibleDelayOffTime === 0)
                {
                    refLayerVisibleDelayOffTime = getTimer();
                }
            }
            else
            {
                refLayerVisibleDelayOffTime = 0;
            }
            canvasRefLayer.visible = false;
        }

        public static function setCanvasRefLayerVisibleDelay(delay:Number = REFLAYER_VISIBLE_DELAY):void
        {
            FOFOTimer.addByName("refLayerVisibleDelayTimer", delay, false, function():void
                {
                    setCanvasRefLayerVisibleSlowly(true);
                });
        }

        public static function setCanvasRefLayerVisibleSlowly(flag:Boolean):void
        {
            const main:Main = Main._instance;

            var fadeStep:Number = Math.round(refLayerLastAlpha / (main.stage.frameRate * 2) * 256) / 256;

            if (fadeStep <= 0.04)
            {
                fadeStep = 0.04;
            }

            if (!canvasRefLayer.visible)
            {
                canvasRefLayer.alpha = 0.0;
            }

            canvasRefLayer.visible = true;

            FOFOTimer.addByName("refLayerVisibleFadingTimer", 0.0, true, function(refLayer:Sprite, fadeStep:Number, maxAlpha:Number):Boolean
                {
                    if (flag)
                    {
                        canvasRefLayer.alpha += fadeStep;

                        if (canvasRefLayer.alpha >= maxAlpha)
                        {
                            canvasRefLayer.alpha = maxAlpha;
                            return false;
                        }
                    }
                    else
                    {
                        canvasRefLayer.alpha -= fadeStep;

                        if (canvasRefLayer.alpha <= 0.0)
                        {
                            canvasRefLayer.alpha = 0.0;
                            return false;
                        }
                    }
                    return true;
                }, [canvasRefLayer, fadeStep, refLayerLastAlpha]);
        }

        public static function toggleRefLayerMemoryTraining():void
        {
            if (isRefLayerMemoryTrainingON === false)
            {
                isRefLayerMemoryTrainingON = true;
                refLayerMenuBox.refMemoryTrainingOffButton.visible = false;
                refLayerMenuBox.refMemoryTrainingOnButton.visible = true;
            }
            else if (isRefLayerMemoryTrainingON === true)
            {
                isRefLayerMemoryTrainingON = false;
                refLayerMenuBox.refMemoryTrainingOffButton.visible = true;
                refLayerMenuBox.refMemoryTrainingOnButton.visible = false;
            }
        }

        public static function startRefLayerImageMirror():void
        {
            const main:Main = Main._instance;

            var tmpbmpd:BitmapData = new BitmapData(canvasRefLayerBitmapData.width,
                    canvasRefLayerBitmapData.height, true, 0);
            var flipMat:Matrix = new Matrix(-1, 0, 0, 1, canvasRefLayerBitmapData.width);

            tmpbmpd.draw(canvasRefLayerBitmapData, flipMat);

            canvasRefLayerBitmapData = main.updateBitmapData(canvasRefLayerBitmapData, tmpbmpd, canvasRefLayerBitmap);

            tmpbmpd.dispose();
            tmpbmpd = null;

            canvasRefLayer.rotation = -canvasRefLayer.rotation; // 일단 각도 대칭해주고

            // canvas1을 기준으로 중심점 거리를 구해서 x값보정과 각도 보정을 함
            const canvasCenterX:Number = canvasRefLayer.x + canvasRefLayerBitmap.x + canvasRefLayerBitmap.width / 2;
            const subX:Number = Math.round((canvasRefLayer.x - canvasCenterX) * 2);
            const deg:Number = canvasRefLayer.rotation - (main.canvasAnchorPoint.rotation) * 2;

            canvasRefLayerBitmap.x = canvasRefLayerBitmap.x + subX;
            canvasRefLayer.rotation = deg; // 캔버스 전체가 회전해있을때 각도보정
            canvasRefLayerBitmap.smoothing = true;
            main.isFileAlreadySaved = false;
        }

        public static function startRefLayerRotation():void
        {
            const main:Main = Main._instance;

            const getangle:Function = MainUI.showCanvasRotateCursorMouseDrag(canvasRefLayer);

            function onDragStart():void
            {
                refLayerMenuBox.visible = false;
                canvasRefLayerBitmap.smoothing = false;
            }

            function onMouseMove():void
            {
                canvasRefLayer.rotation = getangle();
            }

            function onMouseUp():void
            {
                main.isFileAlreadySaved = false;
                refLayerMenuBox.visible = true;
                MainUI.hideCanvasRotateCursor();
                canvasRefLayerBitmap.smoothing = true;
            }

            DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
        }

        public static function startRefLayerImageScale():void
        {
            const main:Main = Main._instance;

            const getscale:Function = Utils.updateImageScaleMouseDrag(canvasRefLayer.scaleX);

            function onDragStart():void
            {
                MainUI.showMouseHint(MainUI.getImageScaleHint(canvasRefLayerBitmapData.width, canvasRefLayerBitmapData.height, Math.abs(canvasRefLayer.scaleX), true));
                refLayerMenuBox.visible = false;
                canvasRefLayerBitmap.smoothing = false;
            }

            function onMouseMove():void
            {
                const scale:Number = getscale(main.mouseX, main.mouseY);
                if (scale)
                    canvasRefLayer.scaleX = (canvasRefLayer.scaleX < 0) ? -scale : scale;
                canvasRefLayer.scaleY = scale;
                MainUI.showMouseHint(MainUI.getImageScaleHint(canvasRefLayerBitmapData.width, canvasRefLayerBitmapData.height, scale, true));
            }

            function onMouseUp():void
            {
                main.isFileAlreadySaved = false;
                refLayerMenuBox.visible = true;
                canvasRefLayerBitmap.smoothing = true;
                MainUI.hideMouseHint();
            }

            DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
        }

        public static function startRefLayerImageDrag():void
        {
            const main:Main = Main._instance;

            const getpos:Function = Utils.updateImagePosMouseDrag(canvasRefLayerBitmap,
                    canvasRefLayer.rotation + main.canvasAnchorPoint.rotation,
                    canvasRefLayer.scaleX,
                    canvasRefLayer.scaleY);
            function onDragStart():void
            {
                refLayerMenuBox.visible = false;
                canvasRefLayerBitmap.smoothing = false;
            }

            function onMouseMove():void
            {
                const pos:Point = getpos();

                canvasRefLayerBitmap.x = pos.x;
                canvasRefLayerBitmap.y = pos.y;
            }

            function onMouseUp():void
            {
                main.isFileAlreadySaved = false;
                refLayerMenuBox.visible = true;
                canvasRefLayerBitmap.smoothing = true;
            }

            DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
        }

        public static function resetRefLayerMenuOpacity():void
        {
            refLayerLastAlpha = 0.5;
            canvasRefLayer.alpha = 0.5;
            updateRefLayerOpacityCursorPosByValue(0.5);
            refLayerMenuBox.hint(HintStrings.STRING_REFLAYER_IMAGE_OPACITY + Math.floor(0.5 * 100) + "%");
            canvasRefLayer.visible = true;
        }

        public static function startRefLayerOpacityDrag():void
        {
            const main:Main = Main._instance;

            const barwidth:Number = refLayerMenuBox.refOpacityBar.width;
            const minx:Number = refLayerMenuBox.refOpacityBar.x + 1;
            const maxx:Number = minx + barwidth - 2;

            function onMouseMoveUpdateopacity():void
            {
                const value:Number = Utils.calculateSliderValueFromMouseX(refLayerMenuBox.mouseX,
                        minx,
                        maxx,
                        0,
                        1.0,
                        refLayerMenuBox.refOpacityCursor);
                const alpha:Number = Utils.normalizeAlphaValue(value);

                if (alpha <= 0.04)
                {
                    canvasRefLayer.visible = false;
                    canvasRefLayer.alpha = 0.0;
                    refLayerLastAlpha = 0.0;

                }
                else
                {
                    canvasRefLayer.visible = true;
                    canvasRefLayer.alpha = alpha;
                    refLayerLastAlpha = alpha;
                }

                refLayerMenuBox.hint(HintStrings.STRING_REFLAYER_IMAGE_OPACITY + Math.floor(alpha * 100 + 0.5) + "%");
            }

            function onDragStart():void
            {
                refLayerMenuBox.hint(HintStrings.STRING_REFLAYER_IMAGE_OPACITY + Math.floor(refLayerLastAlpha * 100 + 0.5) + "%");
                onMouseMoveUpdateopacity();
            }

            DragInteraction.startDragInteraction(onDragStart, onMouseMoveUpdateopacity, function():void
                {
                });
        }

        public static function saveRefLayerImage():void
        {
            if (!canvasRefLayerBitmap.bitmapData)
                return;

            const bmpd:BitmapData = canvasRefLayerBitmap.bitmapData; // 실제 보여주는 데이터를 저장해줌
            const w:Number = canvasRefLayerBitmap.width;
            const h:Number = canvasRefLayerBitmap.height;
            const fs:FileStream = new FileStream();
            var ba:ByteArray = new ByteArray();
            const newRectangle:Rectangle = new Rectangle(0, 0, w, h);

            bmpd.copyPixelsToByteArray(newRectangle, ba);
            // ba.compress();
            fs.open(refLayerImageFilePath, FileMode.WRITE);
            fs.writeObject([ba, w, h]);
            fs.close();
            ba.clear();
            ba = null;
        }

        public static function clearRefLayerImage():void
        {
            canvasRefLayerBitmapData.dispose();
            canvasRefLayerBitmapData = new BitmapData(1, 1, true, 0);
            canvasRefLayerBitmap.bitmapData = canvasRefLayerBitmapData;
            resetRefLayerImageTransform();
            canvasRefLayer.visible = false;
            canvasRefLayer.alpha = 0.0;
            refLayerLastAlpha = 0.0;
            saveRefLayerImage();
        }

        public static function resetRefLayerImageTransform():void
        {
            const ww:Number = -canvasRefLayerBitmap.width / 2;
            const hh:Number = -canvasRefLayerBitmap.height / 2;

            canvasRefLayerBitmap.x = ww;
            canvasRefLayerBitmap.y = hh; // 중점 셋팅
            canvasRefLayer.rotation = 0;
            canvasRefLayer.scaleX = 1;
            canvasRefLayer.scaleY = 1;
            refLayerMenuDragXMoveSum = 0;
        }

        public static function updateRefLayerImageTransform(x:Number, y:Number, rotation:Number, scaleX:Number, scaleY:Number):void
        {
            const main:Main = Main._instance;

            canvasRefLayer.x = main.CANVAS_WIDTH / 2;
            canvasRefLayer.y = main.CANVAS_HEIGHT / 2;
            canvasRefLayerBitmap.x = x;
            canvasRefLayerBitmap.y = y;
            canvasRefLayer.scaleX = scaleX;
            canvasRefLayer.scaleY = scaleY;
            canvasRefLayer.rotation = rotation;
        }

        public static function resetRefLayerOpacitySlider():void
        {
            const main:Main = Main._instance;

            if (canvasRefLayer.visible === false || refLayerLastAlpha === 0.0)
            {
                updateRefLayerOpacityCursorPosByValue(0.5);
                refLayerLastAlpha = 0.5;
                if (!main.isCaptureModeON) // 캡쳐 모드에서 reflayer로드시 뒤에 배경 생겨나서
                {
                    canvasRefLayer.visible = true;
                }
                canvasRefLayer.alpha = 0.5;
            }

            canvasRefLayerBitmap.smoothing = true;
            main.isFileAlreadySaved = false;
        }

        public static function mergeCanvasImageToRefLayer():void
        {
            const main:Main = Main._instance;

            if (main.isDeepUndoEnabled)
            {
                main.applyDeepUndo();
            }

            var layer1Flag:Boolean = main.canvasLayer1Bitmap.visible;
            var layer2Flag:Boolean = main.canvasLayer2Bitmap.visible;

            if (main.checkedLayer === 1)
            {
                layer1Flag = true;
                layer2Flag = false;
            }
            else if (main.checkedLayer === 2)
            {
                layer1Flag = false;
                layer2Flag = true;
            }

            mergeImageToRefLayer((layer1Flag) ? main.canvasLayer1BitmapData : null
                    , (layer2Flag) ? main.canvasLayer2BitmapData : null);
            const rect:Rectangle = new Rectangle(0, 0, main.canvasLayer1BitmapData.width, main.canvasLayer1BitmapData.height);
            var command:String = "clear";

            if (layer1Flag)
            {
                main.canvasLayer1BitmapData.fillRect(rect, 0);
            }

            if (layer2Flag)
            {
                main.canvasLayer2BitmapData.fillRect(rect, 0);
            }

            if ((layer1Flag && !layer2Flag) || !main.canvasLayer2Bitmap.visible)
            {
                command = "clear1";
            }
            else if ((layer2Flag && !layer1Flag) || !main.canvasLayer1Bitmap.visible)
            {
                command = "clear2";
            }

            if (main.hasLastRDataCommand(command))
            {
                main.undoManager.addContinue();
            }
            else
            {
                main.rDataBuffer = [[command]];
                main.undoManager.addNew();
            }

            resetRefLayerImageTransform();
            resetRefLayerOpacitySlider();
        }

        public static function transferLoadedImageToRefLayer(bmpd:IBitmapDrawable, w:Number, h:Number):void
        {
            const main:Main = Main._instance;

            const maxSize:Number = 1000;
            var maxLength:Number = (w > h) ? w : h;
            var scaleFix:Number = (maxLength > maxSize) ? maxSize / maxLength : 1.0;

            w = Math.floor(w * scaleFix);
            h = Math.floor(h * scaleFix); // maxSize 값을 넘으면 리사이즈 해줌
            var scaleMat:Matrix = new Matrix();
            scaleMat.scale(scaleFix, scaleFix);

            var tmpbmpd:BitmapData = new BitmapData(w, h, true, 0);

            tmpbmpd.draw(bmpd, scaleMat, null, null, null, true);

            canvasRefLayerBitmapData = main.updateBitmapData(canvasRefLayerBitmapData, tmpbmpd, canvasRefLayerBitmap);

            tmpbmpd.dispose();
            tmpbmpd = null;

            resetRefLayerImageTransform();

            const gw:Number = main.CANVAS_WIDTH;
            const gh:Number = main.CANVAS_HEIGHT;
            const widthFlag:Boolean = (w >= h) ? true : false;
            var autoScale:Number = 0;

            if (w > gw && widthFlag === true)
                autoScale = gw / w;
            else if (h > gh && widthFlag === false)
                autoScale = gh / h;

            if (autoScale > 0)
            {
                canvasRefLayer.scaleX = autoScale;
                canvasRefLayer.scaleY = autoScale;
            }

            resetRefLayerOpacitySlider();
        }

        public static function mirrorRefLayerImage():void
        {
            canvasRefLayer.scaleX = -canvasRefLayer.scaleX;
            canvasRefLayer.rotation = -canvasRefLayer.rotation;
        }

        public static function updateRefLayerImagePos(w:Number, h:Number, movedFlag:Boolean):void
        {
            const main:Main = Main._instance;

            const scX:Number = canvasRefLayer.scaleX;
            const scY:Number = canvasRefLayer.scaleX;
            const subW:Number = (main.CANVAS_WIDTH - w) / 2;
            const subH:Number = (main.CANVAS_HEIGHT - h) / 2;
            const rPos:Point = Utils.rotatePoint(subW, subH, canvasRefLayer.rotation);

            canvasRefLayer.x = w / 2;
            canvasRefLayer.y = h / 2;

            if (movedFlag)
            {
                canvasRefLayerBitmap.x += -rPos.x / scX;
                canvasRefLayerBitmap.y += -rPos.y / scY;
            }
            else
            {
                canvasRefLayerBitmap.x += rPos.x / scX;
                canvasRefLayerBitmap.y += rPos.y / scY;
            }
        }

        public static function showRefLayerIsEmptyHint():void
        {
            MainUI.showMouseHintTemp("The reference layer is empty");
        }

        public static function isRefLayerEmpty():Boolean
        {
            return canvasRefLayerBitmapData.width === 1 && canvasRefLayerBitmapData.height === 1;
        }

        public static function setRefLayerAndGridVisible(flag:Boolean):void
        {
            if (!isRefLayerEmpty() && refLayerLastAlpha > 0.0)
            {
                if (flag === false)
                {
                    setCanvasRefLayerInvisible();
                }
                else if (refLayerVisibleDelayOffTime > 0)
                {
                    const ondelay:Number = (getTimer() - refLayerVisibleDelayOffTime) / 1000;
                    if (ondelay < REFLAYER_VISIBLE_DELAY)
                    {
                        setCanvasRefLayerVisibleDelay(REFLAYER_VISIBLE_DELAY - ondelay);
                    }
                    else
                    {
                        setCanvasRefLayerVisibleSlowly(true);
                    }
                }
                else
                {
                    setCanvasRefLayerVisibleSlowly(true);
                }
            }

            if (CanvasGridOverlay.gridGapMultiplier > 0)
            {
                CanvasGridOverlay.canvasGrid.visible = flag;
            }
        }

        public static function updateRefLayerBitmapPos(pos:Point):void
        {
            canvasRefLayerBitmap.x += -pos.x * (1 / canvasRefLayer.scaleX);
            canvasRefLayerBitmap.y += -pos.y * (1 / canvasRefLayer.scaleY);
        }
    }
}
