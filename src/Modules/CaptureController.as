package Modules
{
    import flash.display.BitmapData;
    import flash.display.Shape;
    import flash.geom.Point;
    import Symbols.CapStampFontListSet;
    import flash.events.MouseEvent;
    import flash.display.Sprite;
    import flash.geom.Rectangle;
    import flash.geom.Matrix;
    import flash.desktop.Clipboard;
    import flash.desktop.ClipboardFormats;
    import flash.utils.getTimer;
    import flash.display.DisplayObject;
    import flash.display.Bitmap;
    import flash.text.TextFormat;
    import flash.events.KeyboardEvent;
    import flash.geom.ColorTransform;
    import flash.events.FocusEvent;
    import flash.events.Event;
    import flash.ui.ContextMenu;

    public class CaptureController
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static var isCaptureModeON:Boolean = false; // 스크린샷 켜지면 올려줌
        public static var isCaptureCanvasFlipped:Boolean = false; // 캡쳐 대칭한 변수 저장
        public static var isCaptureTransparentBGShowing:Boolean = false; // 배경 제외하고 저장하는 플래그
        public static var isCaptureStampTextFieldFocused:Boolean = false; // 포커스 되면 올려줌
        public static var isCaptureStampEnabled:Boolean = false;
        private static var isCaptureModeInputEventsAdded:Boolean = false; // 이벤트 세트가 켜지거나 꺼지는거 보관 중복 이벤트 추가 피하려고

        public static var captureStampFontListBox:CapStampFontListSet = new CapStampFontListSet();
        private static var captureDragAreaOverlay:Shape = new Shape(); // 스크린샷 박스 미리보기 그려줌
        private static var canvasStateBeforeCaptureMode:Object = {}; // 캡쳐 키면 캔버스 이전 상태 저장함
        public static var drawModeCanvasStateForSaveAppState:Object = {}; // save app state에서 캔버스가 capture모드 상태로 저장해주기 때문에 백업한 데이터로 저장시켜줌
        public static var captureWindowMove:Point = new Point(0, 0); // 스크린샷이 켜져있는 상태에서 창을 조절했을때 스크린샷이 끝나고 나서 regpoint를 그만큼 움직여줘야함
        public static var captureCanvasRotationStep:uint = 0; // 캡쳐 회전한 변수 저장
        private static var capTransparentBGBMPDSize:Number = 32;
        public static var capTransparentBGBMPD:BitmapData;

        public static const captureAreaManager:Object = cDrawCaptureArea();
        public static const captureStampManager:Object = cDrawCaptureStamp();

        private static function hideStampFontList():void
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

        public static function executeCaptureFlashEffect():void
        {
            var xPanel:Sprite = (main.isReplayModeON) ? main.rCanvasPanel : main.canvasPanel;
            var posX:Number;
            var posY:Number;
            var canvasWidth:Number;
            var canvasHeight:Number;

            if (captureAreaManager.isFullImageCapture())
            {
                posX = 0;
                posY = 0;
                if (main.isReplayModeON)
                {
                    canvasWidth = main.RCANVAS_WIDTH;
                    canvasHeight = main.RCANVAS_HEIGHT;
                }
                else
                {
                    canvasWidth = main.CANVAS_WIDTH;
                    canvasHeight = main.CANVAS_HEIGHT;
                }
            }
            else
            {
                const nowCaptureArea:Rectangle = captureAreaManager.getCaptureArea();
                posX = nowCaptureArea.x;
                posY = nowCaptureArea.y;
                canvasWidth = nowCaptureArea.width;
                canvasHeight = nowCaptureArea.height;
            }

            main.applyCanvasFlashEffect(xPanel, posX, posY, canvasWidth, canvasHeight, function ():Boolean
                {
                    return !isCaptureModeON;
                });
        }

        public static function getCaptrueImageBitmapdata(clipBoardCopyFlag:Boolean):BitmapData
        {
            const isReplayMode:Boolean = main.isReplayModeON;
            var rect:Rectangle = (!captureAreaManager.isFullImageCapture()) ? captureAreaManager.getCaptureArea() : null;
            var layer1:Boolean;
            var layer2:Boolean;

            if (isReplayMode)
            {
                layer1 = main.rCanvasLayer1Bitmap.visible;
                layer2 = main.rCanvasLayer2Bitmap.visible;
            }
            else
            {
                layer1 = main.canvasLayer1Bitmap.visible;
                layer2 = main.canvasLayer2Bitmap.visible;
            }

            const bmpd:BitmapData = main.getMergedBitmapdtata((isCaptureModeON && isCaptureTransparentBGShowing && !clipBoardCopyFlag) ? true : false, layer1, layer2, rect);
            const mat:Matrix = new Matrix();
            const deg:Number = 90 * captureCanvasRotationStep;
            var swapWH:Boolean = false;

            mat.rotate(deg * Math.PI / 180);

            if (deg === 90)
            {
                mat.translate(bmpd.height, 0);
                swapWH = true;
            }
            else if (deg === -90 || deg === 270)
            {
                mat.translate(0, bmpd.width);
                swapWH = true;
            }
            else if (deg === 180)
            {
                mat.translate(bmpd.width, bmpd.height);
            }

            if (isCaptureCanvasFlipped)
            {
                if (swapWH)
                {
                    mat.scale(1, -1);
                    mat.translate(0, bmpd.width);
                }
                else
                {
                    mat.scale(-1, 1);
                    mat.translate(bmpd.width, 0);
                }
            }

            const tmpbmpd:BitmapData = (swapWH) ? new BitmapData(bmpd.height, bmpd.width, true, 0) : new BitmapData(bmpd.width, bmpd.height, true, 0);
            tmpbmpd.draw(bmpd, mat);

            if (isCaptureStampEnabled && tmpbmpd.width >= 300)
            {
                captureStampManager.kungFinal(tmpbmpd);
            }

            bmpd.dispose();
            return tmpbmpd;
        }

        public static function copyCaptureImageToCilpBoard():void
        {
            Clipboard.generalClipboard.setData(ClipboardFormats.BITMAP_FORMAT, getCaptrueImageBitmapdata(true), false);
            // WorkspaceView.showMouseHintTemp("The image copied to clipboard successfully");
            MainUI.topBar.capClipBoard.alpha = Global.OFFALPHA;
        }

        public static function initializeCaptureModeTransparentBG():void
        {
            const halfSize:Number = Math.floor(capTransparentBGBMPDSize / 2);
            capTransparentBGBMPD = new BitmapData(capTransparentBGBMPDSize, capTransparentBGBMPDSize, false, 0xFFFFFF);
            capTransparentBGBMPD.fillRect(new Rectangle(0, 0, halfSize, halfSize), 0xC8C8C8);
            capTransparentBGBMPD.fillRect(new Rectangle(halfSize, halfSize, halfSize, halfSize), 0xCCCCCC);
        }

        private static function updateCanvasFlipOnCaptureMode():void
        {
            const xAnc:Sprite = (main.isReplayModeON) ? main.rCanvasAnchorPoint : main.canvasAnchorPoint;
            if (captureCanvasRotationStep === 1)
            {
                xAnc.rotation = 90;
            }
            else if (captureCanvasRotationStep === 3)
            {
                xAnc.rotation = 270;
            }
        }

        public static function flipCaptureImage(flag:Boolean, initFlag:Boolean):void
        {
            isCaptureCanvasFlipped = flag;
            main.fitCanvasToViewportMargin();
            const xAnc:Sprite = (main.isReplayModeON) ? main.rCanvasAnchorPoint : main.canvasAnchorPoint;

            if (captureCanvasRotationStep === 1)
            {
                captureCanvasRotationStep = 3;
                xAnc.rotation = 270;
            }
            else if (captureCanvasRotationStep === 3)
            {
                captureCanvasRotationStep = 1;
                xAnc.rotation = 90;
            }

            MainUI.topBar.capClipBoard.alpha = 1.0;
            if (!initFlag)
            {
                captureAreaManager.updateDrawArea();
            }
        }

        public static function updateCaptureStampButtonAlpha():void
        {
            if (isCaptureStampEnabled)
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
            isCaptureStampEnabled = !isCaptureStampEnabled;
            updateCaptureStampButtonAlpha();
            captureStampManager.update();
        }

        public static function handleExitCaptureMode():void
        {
            FileManager.setFileBrowserIsOpen(false);
            exitCaptureMode();
        }

        public static function applyTransparentCanvasBGCaptureMode(flag:Boolean):void
        {
            isCaptureTransparentBGShowing = flag;

            if (isCaptureTransparentBGShowing)
            {
                BackgroundWorkerCoordinator.applyTransparentCanvasBackground(main.isReplayModeON);
            }
            else
            {
                main.restoreCanvasBackgroundColor(main.isReplayModeON);
            }
            MainUI.topBar.capClipBoard.alpha = 1.0;
        }

        public static function rotateCaptureImage(rotateValue:uint, initFlag:Boolean):void
        {
            // 90도 시계 방향으로 회전
            // 1: 90도 2: 180 3: 270
            if (rotateValue >= 4)
            {
                rotateValue = 0;
            }
            captureCanvasRotationStep = rotateValue;

            main.fitCanvasToViewportMargin();
            MainUI.topBar.capClipBoard.alpha = 1.0;
            if (!initFlag)
            {
                captureAreaManager.updateDrawArea();
            }
        }

        private static function showBottomHintForTargetCaptureMode(target:DisplayObject):void
        {
            if (MainUI.isHintUnavailable())
            {
                return;
            }

            const hint:String = HintStrings.getHintFromTargetNameCaptureMode(target.name);
            if (hint)
            {
                FOFOTimer.remove("bottomHintOffDelay");
                const targetName:String = target.name;
                const xCanvasPanel:Sprite = (main.isReplayModeON) ? main.rCanvasPanel : main.canvasPanel;

                if (captureAreaManager.isFullImageCapture() && xCanvasPanel.hitTestPoint(main.stage.mouseX, main.stage.mouseY, true))
                {
                    MainUI.showHintHighlightBox((main.isReplayModeON) ? main.rCanvasLayer1Bitmap : main.canvasLayer1Bitmap);
                    MainUI.showBottomHint(hint);
                }
                else if (!(targetName === "rCanvasPanel" || targetName === "rCanvasDrawLayer" || targetName === "canvasPanel" || targetName === "canvasDrawLayer"))
                {
                    MainUI.showHintHighlightBox(target);
                    MainUI.showBottomHint(hint);
                }
            }
            else
            {
                if (!FOFOTimer.hasTimer("bottomHintOffDelay"))
                {
                    FOFOTimer.addByName("bottomHintOffDelay", 0.3, false, MainUI.hideBottomHint);
                }
            }
        }

        private static function onRightMouseDownCaptureMode(e:MouseEvent):void
        {
            if (MainUI.topBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
            {
                if (!captureAreaManager.isFullImageCapture())
                {
                    captureAreaManager.resetCaptureArea();
                }
            }
        }

        private static function onMouseDownCaptureMode(e:MouseEvent):void
        {
            const target:DisplayObject = e.target as DisplayObject;
            if (!target)
            {
                return;
            }

            const targetName:String = target.name;

            if (targetName === "capLayer1VisibleButton" || targetName === "capLayer2VisibleButton" || targetName === "capStamp" || targetName === "capStampFont")
            {
                main.handleMouseClick(targetName);
                return;
            }

            if (targetName === "capClipBoard")
            {
                executeCaptureFlashEffect();
                if (target.alpha < 1.0 && MainUI.topBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
                {
                    return;
                }
                main.handleMouseClick(targetName);
            }

            if (target.alpha < 1.0 && MainUI.topBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY))
            {
                return;
            }

            if (captureStampFontListBox.visible)
            {
                if (targetName === "capFontListNext" || targetName === "capFontListPrev")
                {
                    main.handleMouseClick(targetName);
                }
                else if (targetName && targetName.indexOf(captureStampFontListBox.getStampFontButtonName()) !== -1)
                {
                    captureStampManager.changeFont(captureStampFontListBox.getFontName(targetName), true);
                }
                else if (target.parent)
                {
                    if (target.parent.name && target.parent.name.indexOf(captureStampFontListBox.getStampFontButtonName()) !== -1)
                    {
                        captureStampManager.changeFont(captureStampFontListBox.getFontName(target.parent.name), true);
                    }
                }
                return;
            }

            switch (targetName)
            {
                case "capRotate":
                case "capFlip":
                case "capSave":
                case "capOff":
                case "capTrans":
                    main.handleMouseClick(targetName);
                    break;
                case "timer":
                    main.startPressHoldKey(MainUI.topBar.timer, HintStrings.getResetTimerHintString(), null, main.realWorkingTimer.reset, null);
                    break;
                default:
                    if (!main.isMouseClickBlocked)
                    {
                        captureAreaManager.start();
                    }
                    break;
            }
        }

        private static function onKeyUpCaptureMode(e:KeyboardEvent):void
        {
            main.updateLastKey(main.getLastKey());
            main.checkGeneralKeyUp(e.keyCode);
        }

        private static function onKeyDownCaptureMode(e:KeyboardEvent):void
        {
            const firstKey:uint = main.getFirstPressedKey();
            if (captureStampFontListBox.visible)
            {
                if (firstKey === main.KEY.esc)
                {
                    hideStampFontList();
                }
                return;
            }

            if (firstKey === main.KEY.esc)
            {
                if (main.stage.focus === MainUI.topBar.captureInput)
                {
                    main.stage.focus = null;
                    return;
                }
            }

            if (main.stage.focus === MainUI.topBar.captureInput || main.isMouseClicked || main.isRightMouseClicked)
            {
                return;
            }

            if (main.isPressingControl())
            {
                const secondKey:uint = main.getSecondPressedKey();
                if (main.isLastKey(secondKey))
                {
                    return;
                }
                main.updateLastKey(secondKey);

                if (secondKey === main.KEY.s || secondKey === main.KEY.semicolon)
                {
                    FileManager.saveCaptureImage();
                }
                else if (secondKey === main.KEY.c || secondKey === main.KEY.comma)
                {
                    executeCaptureFlashEffect();
                    if (MainUI.topBar.capClipBoard.alpha === 1.0)
                    {
                        copyCaptureImageToCilpBoard();
                    }
                }
                else if (secondKey === main.KEY.v || secondKey === main.KEY.m)
                {
                    if (ClipboardManager.isClipBoardButtonActivated)
                    {
                        ClipboardManager.tryLoadClipboardImage(false);
                    }
                }
                return;
            }

            if (main.isLastKey(firstKey))
            {
                return;
            }

            main.updateLastKey(firstKey);

            switch (firstKey)
            {
                case main.KEY.esc:
                case main.KEY.backspace:
                case main.KEY.f1:
                case main.KEY.f7:
                    handleExitCaptureMode();
                    break;
                default:
                    break;
            }
        }

        public static function enterCaptureMode():void
        {
            if (isCaptureModeON || main.isGeneratingCacheImages())
            {
                return;
            }

            if (main.isReplayStarted)
            {
                main.stopReplay();
            }

            isCaptureModeON = true;
            main.isPenSizeCursorInvisible = true;

            if (ColorPickerController.numPadBox.visible)
            {
                ColorPickerController.closeNumpad();
            }

            if (!SidebarController.isSidebarVisible && SidebarController.sideBar.visible)
            {
                SidebarController.startHidingSidebarTemporary();
            }

            MainUI.activateCaptureUI();
            MainUI.hideBottomHint();

            var xAnc:Sprite;
            var xPanel:Sprite;
            var xZoomed:Number;
            var layer1:Boolean;
            var layer2:Boolean;

            if (main.isReplayModeON)
            {
                xAnc = main.rCanvasAnchorPoint;
                xPanel = main.rCanvasPanel;
                xZoomed = main.rCanvasZoomMultiplier;
                main.rReplayFOFOCursor.visible = false;
                main.rCanvasPanel.addChild(captureDragAreaOverlay);
                layer1 = true;
                layer2 = true;
            }
            else
            {
                xAnc = main.canvasAnchorPoint;
                xPanel = main.canvasPanel;
                xZoomed = main.canvasZoomMultipler;
                main.canvasPanel.addChild(captureDragAreaOverlay);
                if (main.canvasLayer1Bitmap.visible)
                    layer1 = true;
                if (main.canvasLayer2Bitmap.visible)
                    layer2 = true;
            }

            Utils.setAsTopChild(captureDragAreaOverlay);

            drawModeCanvasStateForSaveAppState = {
                    "z": main.canvasZoomMultipler,
                    "x": Math.floor(main.canvasAnchorPoint.x), // 뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
                    "y": Math.floor(main.canvasAnchorPoint.y),
                    "r": main.canvasAnchorPoint.rotation,
                    "px": Math.floor(main.canvasPanel.x),
                    "py": Math.floor(main.canvasPanel.y)
                };

            canvasStateBeforeCaptureMode = {
                    "z": xZoomed,
                    "x": Math.floor(xAnc.x), // 뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
                    "y": Math.floor(xAnc.y),
                    "r": xAnc.rotation,
                    "px": Math.floor(xPanel.x),
                    "py": Math.floor(xPanel.y),
                    "layer1": layer1,
                    "layer2": layer2
                };

            MainUI.resetLastBottomHintTargetRect();
            MainUI.topBar.capClipBoard.alpha = 1.0;
            captureCanvasRotationStep = 0;
            isCaptureCanvasFlipped = false;
            main.fitCanvasToViewportMargin();
            applyTransparentCanvasBGCaptureMode(false);
            captureStampManager.init();

            if (isCaptureStampEnabled)
            {
                captureStampManager.update();
            }
        }

        public static function resetCaptureCanvasChangeValue():void
        {
            captureCanvasRotationStep = 0;
            isCaptureCanvasFlipped = false;
            isCaptureTransparentBGShowing = false;
        }

        public static function exitCaptureMode():void
        {
            const replayMode:Boolean = main.isReplayModeON;
            const data:Object = canvasStateBeforeCaptureMode;
            const xBitmap1:Bitmap = (replayMode) ? main.rCanvasLayer1Bitmap : main.canvasLayer1Bitmap;
            const xBitmap11:Bitmap = (replayMode) ? main.rCanvasLayer2Bitmap : main.canvasLayer2Bitmap;
            const xAnc:Sprite = (replayMode) ? main.rCanvasAnchorPoint : main.canvasAnchorPoint;
            const xPanel:Sprite = (replayMode) ? main.rCanvasPanel : main.canvasPanel;

            xBitmap1.smoothing = false;
            xBitmap11.smoothing = false;
            isCaptureModeON = false;
            main.isPenSizeCursorInvisible = false;

            captureDragAreaOverlay.graphics.clear();
            captureStampManager.off();
            captureStampFontListBox.visible = false;

            // 캔버스 이전 모양 위치로 복원
            xAnc.rotation = data.r;
            xAnc.x = data.x + captureWindowMove.x;
            xAnc.y = data.y + captureWindowMove.y;
            xPanel.x = data.px;
            xPanel.y = data.py;

            if (replayMode)
            {
                main.rCanvasLayer1Bitmap.visible = true;
                main.rCanvasLayer2Bitmap.visible = true;
                main.rCanvasDrawLayer.visible = true;
            }
            else
            {
                main.canvasLayer1Bitmap.visible = data.layer1;
                main.canvasLayer2Bitmap.visible = data.layer2;
            }

            if (!main.isReplayCanvasFitToWindow)
            {
                main.updateCanvasScale(data.z, replayMode);
            }

            MainUI.resetLastBottomHintTargetRect();
            MainUI.hideMouseHint();
            captureWindowMove.setTo(0, 0);
            main.updatePenSizeCursor();

            // prev box 사각형 업데이트가 있기 때문에 xAnc위치가 갱신된 다음에 해주어야함
            MainUI.deactivateCaptureUI();
            MainUI.hideBottomHint();

            if (replayMode)
            {
                main.restoreCanvasBackgroundColor(true);
                main.rReplayFOFOCursor.visible = true;
            }
            else if (!replayMode)
            {
                main.restoreCanvasBackgroundColor(false);
            }

            main.keepCanvasPanelInStage(replayMode);
            canvasStateBeforeCaptureMode = {};
        }

        private static function cDrawCaptureStamp():Object
        {
            var captrueStampBMPD:BitmapData = new BitmapData(1, 1, false, 0);
            var captureStampBitmap:Bitmap = new Bitmap(captrueStampBMPD);
            const stampAlpha:uint = 0xCB000000;
            const textformat:TextFormat = new TextFormat();
            const captureStampRect:Rectangle = new Rectangle();
            const bmpdMat:Matrix = new Matrix();
            const defaultFontSize:int = 13;
            var defaultBmpdHeight:int = defaultFontSize + 2;
            var inputUpdateTimer:int = 0;
            var stampBGColor:* = null;
            const lastRectArea:Rectangle = new Rectangle();
            var lastBitmapVisibleFlag:int = 0;

            captureStampBitmap.name = "captureStampBitmap";
            captureStampBitmap.visible = false;

            function updateLastRectArea(rect:Rectangle):void
            {
                lastRectArea.x = rect.x;
                lastRectArea.y = rect.y;
                lastRectArea.width = rect.width;
                lastRectArea.height = rect.height;
            }

            function getFontName():String
            {
                return textformat.font;
            }

            function checkCaptrueStampBMPDHeight(twolineFlag:Boolean, mainTextWidth:Number):Number
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

            function changeFont(newFont:String, updateFlag:Boolean):void
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

            function getCaptureStampDate(newLine:Boolean):String
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

            function getAppNameString(newLine:Boolean):String
            {
                return "FOFO PAINT"
                    + ((newLine) ? "\n" : " ")
                    + main.APP_VERSION;
            }

            function getTextWidthText(text:String, offset:Number):Number
            {
                const backupStr:String = MainUI.topBar.captureInputFinal.text;
                const backupWidth:Number = MainUI.topBar.getCaptureInputFinalWidth();

                MainUI.topBar.setCaptureInputFinalWidth(main.CANVAS_MAX_SIZE);
                MainUI.topBar.setCaptureInputFinalString(text);

                const width:Number = MainUI.topBar.captureInputFinal.textWidth + offset;

                MainUI.topBar.setCaptureInputFinalString(backupStr);
                MainUI.topBar.setCaptureInputFinalWidth(backupWidth);

                return width;
            }

            function getTextWidthAppName(newLine:Boolean):Number
            {
                return getTextWidthText(getAppNameString(newLine), 5);
            }

            function getTextWidthDate(newLine:Boolean):Number
            {
                return getTextWidthText(getCaptureStampDate(newLine), 10);
            }

            function getTextWidthMain():Number
            {
                return getTextWidthText(MainUI.topBar.getCaptureInputString(), 2);
            }

            function kungStamp(textStr:String, textWidth:Number, align:String, posX:Number, offsetX:Number, testHeightFlag:Boolean):Number
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

            function kungAppnameStr(newLine:Boolean, testHeightFlag:Boolean):Number
            {
                const textWidth:Number = getTextWidthAppName(newLine);

                return kungStamp(getAppNameString(newLine), textWidth, "right", captrueStampBMPD.width - textWidth, 2, testHeightFlag);
            }

            function kungMainStr(newLine:Boolean, textWidth:Number, testHeightFlag:Boolean):Number
            {
                return kungStamp(MainUI.topBar.getCaptureInputString(), textWidth, "left", getTextWidthDate(newLine), 0, testHeightFlag);
            }

            function kungDateStr(newLine:Boolean, testHeightFlag:Boolean):Number
            {
                return kungStamp(getCaptureStampDate(newLine), getTextWidthDate(newLine), "left", 2, 0, testHeightFlag);
            }

            function kungFinal(inputBMPD:BitmapData):void
            {
                update(); // 미자막 시간 찍어줘야함

                const mat:Matrix = new Matrix();
                const ct:ColorTransform = new ColorTransform();

                mat.translate(0, inputBMPD.height - captrueStampBMPD.height);
                inputBMPD.draw(captureStampBitmap, mat, ct);
            }

            function getCaptureAreaBmpd(clipRect:Rectangle, layer1:Boolean, layer2:Boolean):BitmapData
            {
                var longEdge:Number;
                var areaWidth:Number;
                var areaHeight:Number;

                const fullImageFlag:Boolean = clipRect.width === 0 && clipRect.height === 0;

                if (fullImageFlag)
                {
                    longEdge = main.CANVAS_HEIGHT > main.CANVAS_WIDTH ? main.CANVAS_HEIGHT : main.CANVAS_WIDTH;
                    areaWidth = main.CANVAS_WIDTH;
                    areaHeight = main.CANVAS_HEIGHT;
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

                const width:Number = areaWidth * scale;
                const height:Number = areaHeight * scale;

                const mat:Matrix = new Matrix();
                mat.scale(scale, scale);

                const tmpbmpd:BitmapData = new BitmapData(width, height, true, 0);
                const rawbmpd:BitmapData = main.getMergedBitmapdtata(false, layer1, layer2, (fullImageFlag) ? null : clipRect);

                tmpbmpd.draw(rawbmpd, mat);

                return tmpbmpd;
            }

            function onFocusOutCaptureInput(e:FocusEvent):void
            {
                FOFOTimer.add(0.2, false, function ():void
                    {
                        main.tryDisableIME();
                        isCaptureStampTextFieldFocused = false;
                    });
            }

            function onFocusInCaptureInput(e:FocusEvent):void
            {
                isCaptureStampTextFieldFocused = true;

                FOFOTimer.add(0.0, false, function ():void
                    {
                        MainUI.topBar.captureInput.setSelection(0, MainUI.topBar.captureInput.text.length);
                    });
            }

            function onChangeCaptureInput(e:Event):void
            {
                MainUI.topBar.capClipBoard.alpha = 1.0;

                if (!FOFOTimer.hasTimer("inputUpdateTimer"))
                {
                    FOFOTimer.addByName("inputUpdateTimer", 0.2, false, update);
                }
            }

            function setVisible(flag:Boolean):void
            {
                if (captureStampBitmap.visible !== flag)
                {
                    captureStampBitmap.visible = flag;
                }
            }

            function checkPosition(bmpdHeight:Number):void
            {
                const rect:Rectangle = captureAreaManager.getCaptureArea();
                const rotateFlag:uint = captureCanvasRotationStep;
                var offsetX:Number;
                var offsetY:Number;

                if (captureAreaManager.isFullImageCapture())
                {

                    offsetX = (main.isReplayModeON) ? main.RCANVAS_WIDTH : main.CANVAS_WIDTH;
                    offsetY = (main.isReplayModeON) ? main.RCANVAS_HEIGHT : main.CANVAS_HEIGHT;
                }
                else
                {
                    offsetX = rect.width;
                    offsetY = rect.height;
                }

                if (isCaptureCanvasFlipped)
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

            function getCaptureAreaWidth(rect:Rectangle):Number
            {
                const notRotatedFlag:Boolean = captureCanvasRotationStep % 2 === 0;

                if (notRotatedFlag)
                {
                    if (captureAreaManager.isFullImageCapture())
                    {

                        return (main.isReplayModeON) ? main.RCANVAS_WIDTH : main.CANVAS_WIDTH;
                    }
                    else
                    {
                        return rect.width;
                    }
                }
                else
                {
                    if (captureAreaManager.isFullImageCapture())
                    {
                        return (main.isReplayModeON) ? main.RCANVAS_HEIGHT : main.CANVAS_HEIGHT;
                    }
                    else
                    {
                        return rect.height;
                    }
                }

                return 0;
            }

            function getColorBrightness(color:uint):Number
            {
                var red:int = (color >> 16) & 0xFF;
                var green:int = (color >> 8) & 0xFF;
                var blue:int = color & 0xFF;

                // 밝기 계산
                var brightness:Number = 0.299 * red + 0.587 * green + 0.114 * blue;

                return brightness;
            }

            function update():void
            {
                if (isCaptureStampEnabled)
                {
                    const rect:Rectangle = captureAreaManager.getCaptureArea();
                    const bmpdWidth:Number = getCaptureAreaWidth(rect);

                    if (bmpdWidth < 300)
                    {
                        if (captureStampBitmap.visible === true)
                        {
                            captureStampBitmap.visible = false;
                        }
                        return;
                    }

                    const layer1Visible:Boolean = (main.isReplayModeON) ? main.rCanvasLayer1Bitmap.visible : main.canvasLayer1Bitmap.visible;
                    const layer2Visible:Boolean = (main.isReplayModeON) ? main.rCanvasLayer2Bitmap.visible : main.canvasLayer2Bitmap.visible;

                    var bitmapVisibleFlag:int = 0;

                    if (layer1Visible)
                    {
                        bitmapVisibleFlag += 1;
                    }
                    if (layer2Visible)
                    {
                        bitmapVisibleFlag += 2;
                    }

                    const bmpd:BitmapData = getCaptureAreaBmpd(rect, layer1Visible, layer2Visible);

                    if (!bmpd)
                    {
                        return;
                    }

                    if (stampBGColor === null || !rect.equals(lastRectArea) || lastBitmapVisibleFlag !== bitmapVisibleFlag)
                    {
                        const tegakiBGColorIndex:int = PaletteController.myPaletteTegakiPreset.indexOf((main.isReplayModeON) ? main.RCANVAS_BG_COLOR : main.CANVAS_BG_COLOR);

                        if (tegakiBGColorIndex >= 0)
                        {
                            stampBGColor = PaletteController.myPaletteTegakiPreset[tegakiBGColorIndex - 10];
                        }
                        else
                        {
                            stampBGColor = ColorPickerController.getImageDominantColor(bmpd);
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

                    if (main.isReplayModeON)
                    {
                        if (main.rCanvasPanel.getChildByName("captureStampBitmap") === null)
                        {
                            main.rCanvasPanel.addChild(captureStampBitmap);
                        }
                    }
                    else if (main.canvasPanel.getChildByName("captureStampBitmap") === null)
                    {
                        main.canvasPanel.addChild(captureStampBitmap);
                    }

                    checkPosition(bmpdHeight);
                }
                else if (captureStampBitmap.visible === true)
                {
                    if (main.isReplayModeON)
                    {
                        if (main.rCanvasPanel.getChildByName("captureStampBitmap") !== null)
                        {
                            main.rCanvasPanel.removeChild(captureStampBitmap);
                        }
                    }
                    else if (main.canvasPanel.getChildByName("captureStampBitmap") !== null)
                    {
                        main.canvasPanel.removeChild(captureStampBitmap);
                    }

                    captureStampBitmap.visible = false;
                }
            }

            function off():void
            {
                if (main.isReplayModeON)
                {
                    main.rCanvasPanel.scrollRect = new Rectangle(0, 0, main.RCANVAS_WIDTH, main.RCANVAS_HEIGHT);
                }
                else
                {
                    main.canvasPanel.scrollRect = new Rectangle(0, 0, main.CANVAS_WIDTH, main.CANVAS_HEIGHT);
                }

                if (captrueStampBMPD)
                {
                    captrueStampBMPD.dispose();
                }

                captrueStampBMPD = null;

                MainUI.topBar.captureInput.removeEventListener(Event.CHANGE, onChangeCaptureInput);
                MainUI.topBar.captureInput.removeEventListener(FocusEvent.FOCUS_IN, onFocusInCaptureInput);
                MainUI.topBar.captureInput.removeEventListener(FocusEvent.FOCUS_OUT, onFocusOutCaptureInput);

                captureStampBitmap.visible = false;

                if (main.canvasPanel.getChildByName("captureStampBitmap") !== null)
                {
                    main.canvasPanel.removeChild(captureStampBitmap);
                }
            }

            function init():void
            {
                if (main.isReplayModeON)
                {
                    main.rCanvasPanel.scrollRect = null;
                }
                else
                {
                    main.canvasPanel.scrollRect = null;
                }

                textformat.font = null;
                stampBGColor = null;

                MainUI.topBar.captureInput.addEventListener(Event.CHANGE, onChangeCaptureInput);
                MainUI.topBar.captureInput.addEventListener(FocusEvent.FOCUS_IN, onFocusInCaptureInput);
                MainUI.topBar.captureInput.addEventListener(FocusEvent.FOCUS_OUT, onFocusOutCaptureInput);
            }

            return {
                    init: init,
                    off: off,
                    update: update,
                    setVisible: setVisible,
                    kungFinal: kungFinal,
                    changeFont: changeFont,
                    getFontName: getFontName
                };
        }

        // 마우스 클릭하면 캡쳐 영역그리는 함수
        private static function cDrawCaptureArea():Object
        {
            var xPanel:Sprite;
            var mouseMoved:Boolean = false;
            var canvasWidth:Number = 0;
            var canvasHeight:Number = 0;
            var clickPos:Point = new Point(0, 0);
            var limitWidthSave:Number = 0;
            var limitHeightSave:Number = 0;
            const rectFull:Rectangle = new Rectangle();
            const rectRaw:Rectangle = new Rectangle();
            const rectClamped:Rectangle = new Rectangle();
            var resizeFlag:Boolean = false;
            const resizeButtonSize:Number = 14.0;
            const resizeButtonPos:Point = new Point(0, 0);
            var minSize:Number = 10.0;
            const mouseMoveOffset:Number = 5.0;

            function validateCaptureArea():void
            {
                var intersection:Rectangle = rectFull.intersection(rectClamped);
                if (intersection.width >= minSize && intersection.height >= minSize)
                {
                    rectClamped.x = Math.round(intersection.x);
                    rectClamped.y = Math.round(intersection.y);
                    rectClamped.width = Math.round(intersection.width);
                    rectClamped.height = Math.round(intersection.height);
                }
                else
                {
                    FOFOTimer.add(0.0, false, function ():void
                        {
                            resetCaptureArea();
                        });
                }
            }

            function normalizeRectClamped():void
            {
                if (rectClamped.width < 0)
                {
                    rectClamped.width = Math.abs(rectClamped.width);
                    rectClamped.x = rectClamped.x - rectClamped.width;
                }
                if (rectClamped.height < 0)
                {
                    rectClamped.height = Math.abs(rectClamped.height);
                    rectClamped.y = rectClamped.y - rectClamped.height;
                }
            }

            function onMouseMoveCaptureAreaDrawed(e:MouseEvent):void
            {
                if (!isCaptureModeON)
                {
                    removeCaptureAreaEvents();
                    return;
                }

                const mx:Number = xPanel.mouseX;
                const my:Number = xPanel.mouseY;
                var subX:Number = Math.round(mx - clickPos.x);
                var subY:Number = Math.round(my - clickPos.y);

                if (mouseMoved === true)
                {
                    if (resizeFlag)
                    {
                        if (!isCaptureCanvasFlipped && captureCanvasRotationStep === 0 || isCaptureCanvasFlipped && captureCanvasRotationStep === 3)
                        {
                            rectRaw.width += subX;
                            rectRaw.height += subY;
                            rectClamped.width = rectRaw.width;
                            rectClamped.height = rectRaw.height;

                            if (rectClamped.width < minSize)
                                rectClamped.width = minSize;
                            else if (rectClamped.x + rectClamped.width > canvasWidth)
                                rectClamped.width = canvasWidth - rectClamped.x;

                            if (rectClamped.height < minSize)
                                rectClamped.height = minSize;
                            else if (rectClamped.y + rectClamped.height > canvasHeight)
                                rectClamped.height = canvasHeight - rectClamped.y;
                        }
                        else if (!isCaptureCanvasFlipped && captureCanvasRotationStep === 1 || isCaptureCanvasFlipped && captureCanvasRotationStep === 2)
                        {
                            rectRaw.width += subX;
                            rectRaw.height -= subY;
                            rectRaw.y += subY;
                            rectClamped.width = rectRaw.width;
                            rectClamped.height = rectRaw.height;
                            rectClamped.y = rectRaw.y;

                            if (rectClamped.y < 0.0)
                            {
                                rectClamped.y = 0.0;
                                rectClamped.height = limitHeightSave;
                            }
                            if (rectClamped.height < minSize)
                            {
                                rectClamped.height = minSize;
                                rectClamped.y = limitHeightSave - rectClamped.height;
                            }
                            if (rectClamped.width < minSize)
                                rectClamped.width = minSize;
                            else if (rectClamped.x + rectClamped.width > canvasWidth)
                                rectClamped.width = canvasWidth - rectClamped.x;
                        }
                        else if (!isCaptureCanvasFlipped && captureCanvasRotationStep === 2 || isCaptureCanvasFlipped && captureCanvasRotationStep === 1)
                        {
                            rectRaw.width -= subX;
                            rectRaw.height -= subY;
                            rectRaw.x += subX;
                            rectRaw.y += subY;
                            rectClamped.width = rectRaw.width;
                            rectClamped.height = rectRaw.height;
                            rectClamped.x = rectRaw.x;
                            rectClamped.y = rectRaw.y;

                            if (rectClamped.width < minSize)
                            {
                                rectClamped.width = minSize;
                                rectClamped.x = limitWidthSave - rectClamped.width;
                            }
                            if (rectClamped.height < minSize)
                            {
                                rectClamped.height = minSize;
                                rectClamped.y = limitHeightSave - rectClamped.height;
                            }
                            if (rectClamped.x < 0.0)
                            {
                                rectClamped.x = 0.0;
                                rectClamped.width = limitWidthSave;
                            }
                            if (rectClamped.y < 0.0)
                            {
                                rectClamped.y = 0.0;
                                rectClamped.height = limitHeightSave;
                            }
                        }
                        else if (!isCaptureCanvasFlipped && captureCanvasRotationStep === 3 || isCaptureCanvasFlipped && captureCanvasRotationStep === 0)
                        {
                            rectRaw.width -= subX;
                            rectRaw.height += subY;
                            rectRaw.x += subX;
                            rectClamped.width = rectRaw.width;
                            rectClamped.height = rectRaw.height;
                            rectClamped.x = rectRaw.x;

                            if (rectClamped.x < 0.0)
                            {
                                rectClamped.x = 0.0;
                                rectClamped.width = limitWidthSave;
                            }
                            if (rectClamped.width < minSize)
                            {
                                rectClamped.width = minSize;
                                rectClamped.x = limitWidthSave - rectClamped.width;
                            }
                            if (rectClamped.height < minSize)
                            {
                                rectClamped.height = minSize;
                            }
                            else if (rectClamped.y + rectClamped.height > canvasHeight)
                            {
                                rectClamped.height = canvasHeight - rectClamped.y;
                            }
                        }
                        MainUI.showBottomHint(getRotatedRectSizeString());
                    }
                    else
                    {
                        rectRaw.x += subX;
                        rectRaw.y += subY;
                        rectClamped.x = rectRaw.x;
                        rectClamped.y = rectRaw.y;

                        if (rectClamped.x < 0.0)
                        {
                            rectClamped.x = 0.0;
                        }
                        else if (rectClamped.x + rectClamped.width > canvasWidth)
                        {
                            rectClamped.x = canvasWidth - rectClamped.width;
                        }

                        if (rectClamped.y < 0.0)
                        {
                            rectClamped.y = 0.0;
                        }
                        else if (rectClamped.y + rectClamped.height > canvasHeight)
                        {
                            rectClamped.y = canvasHeight - rectClamped.height;
                        }
                    }
                    rectClamped.x = Math.round(rectClamped.x);
                    rectClamped.y = Math.round(rectClamped.y);
                    rectClamped.width = Math.round(rectClamped.width);
                    rectClamped.height = Math.round(rectClamped.height);
                    clickPos.setTo(xPanel.mouseX, xPanel.mouseY);
                    drawArea(false);
                }
                else if (Math.abs(subX) >= mouseMoveOffset || Math.abs(subY) >= mouseMoveOffset)
                {
                    mouseMoved = true;
                    clickPos.setTo(mx, my);
                    captureStampManager.setVisible(false);
                }
            }

            function onMouseMoveDrawCaptureArea(e:MouseEvent):void
            {
                if (!isCaptureModeON)
                {
                    removeCaptureAreaEvents();
                    return;
                }

                var mx:Number = xPanel.mouseX;
                var my:Number = xPanel.mouseY;
                var subX:Number = Math.round(mx - clickPos.x);
                var subY:Number = Math.round(my - clickPos.y);

                if (mouseMoved)
                {
                    rectRaw.width = subX;
                    rectRaw.height = subY;
                    rectClamped.x = rectRaw.x;
                    rectClamped.y = rectRaw.y;
                    rectClamped.width = rectRaw.width;
                    rectClamped.height = rectRaw.height;
                    normalizeRectClamped();
                    MainUI.showBottomHint(getRotatedRectSizeString());
                    drawArea(false);
                }
                else if (Math.abs(subX) >= mouseMoveOffset || Math.abs(subY) >= mouseMoveOffset)
                {
                    rectRaw.x = clickPos.x;
                    rectRaw.y = clickPos.y;
                    rectRaw.width = subX;
                    rectRaw.height = subY;
                    rectClamped.x = rectRaw.x;
                    rectClamped.y = rectRaw.y;
                    rectClamped.width = rectRaw.width;
                    rectClamped.height = rectRaw.height;
                    clickPos.setTo(mx, my);
                    MainUI.showBottomHint(getRotatedRectSizeString());
                    mouseMoved = true;
                    captureStampManager.setVisible(false);
                }
            }

            function onMouseUpCaptureArea(e:MouseEvent):void
            {
                main.isMouseDragging = false;
                removeCaptureAreaEvents();

                if (mouseMoved === true)
                {
                    // rect길이가 음수인경우 cx cy를 양수로 다시 맞추어줌
                    normalizeRectClamped();
                    validateCaptureArea();
                    MainUI.topBar.capClipBoard.alpha = 1.0;
                    drawArea(true);
                    captureStampManager.update();
                }
                mouseMoved = false;
            }

            function removeCaptureAreaEvents():void
            {
                main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveDrawCaptureArea);
                main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveCaptureAreaDrawed);
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpCaptureArea);
            }

            function updateDrawArea(forceFlag:Boolean = false):void
            {
                if (rectClamped.width > minSize && rectClamped.height > minSize || forceFlag)
                {
                    drawArea(true);
                }
                captureStampManager.update();
            }

            function getCanvasScale():Number
            {
                return (main.isReplayModeON) ? Math.abs(main.rCanvasAnchorPoint.scaleX) : Math.abs(main.canvasAnchorPoint.scaleX);
            }

            function drawResizeButton(scale:Number):void
            {
                if (isFullImageCapture())
                {
                    return;
                }

                captureDragAreaOverlay.graphics.lineStyle(1, 0xFFFFFF, 1.0, true);
                captureDragAreaOverlay.graphics.beginFill(0xFF6600);

                var posX:Number = rectClamped.x;
                var posY:Number = rectClamped.y;
                const offset:Number = 0;

                if (!isCaptureCanvasFlipped && captureCanvasRotationStep === 0 || isCaptureCanvasFlipped && captureCanvasRotationStep === 3)
                {
                    posX += rectClamped.width + offset;
                    posY += rectClamped.height + offset;
                }
                else if (!isCaptureCanvasFlipped && captureCanvasRotationStep === 1 || isCaptureCanvasFlipped && captureCanvasRotationStep === 2)
                {
                    posX += rectClamped.width + offset;
                    posY += -offset;
                }
                else if (!isCaptureCanvasFlipped && captureCanvasRotationStep === 3 || isCaptureCanvasFlipped && captureCanvasRotationStep === 0)
                {
                    posY += rectClamped.height + offset;
                    posX += -offset;
                }
                else
                {
                    posX += -offset;
                    posY += -offset;
                }

                resizeButtonPos.setTo(posX, posY);

                const longEdge:Number = resizeButtonSize / scale;
                const shortEdge:Number = (resizeButtonSize / 3) / scale;
                const cmd:Vector.<int> = new <int>[1, 2, 2, 2, 2, 2, 2];
                const pos:Vector.<Number> = new <Number>[
                        0, 0,
                        0, -longEdge,
                        shortEdge, -longEdge,
                        shortEdge, shortEdge,
                        -longEdge, shortEdge,
                        -longEdge, 0,
                        0, 0
                    ];
                const len:uint = pos.length;
                var p:Point;

                for (var i:uint = 0;i < len;i += 2)
                {
                    p = Utils.rotatePoint(pos[i], pos[i + 1], captureCanvasRotationStep * 90.0);
                    pos[i] = posX + p.x * ((isCaptureCanvasFlipped) ? -1.0 : 1.0);
                    pos[i + 1] = posY + p.y;
                }

                captureDragAreaOverlay.graphics.drawPath(cmd, pos);
                captureDragAreaOverlay.graphics.endFill();
            }

            function drawArea(resizeButtonON:Boolean):void
            {
                const zoomed:Number = getCanvasScale();
                const lineSize:Number = Math.ceil(1 / zoomed);

                captureDragAreaOverlay.graphics.clear();
                // 배경색 약간 어둡게 해줌
                captureDragAreaOverlay.graphics.lineStyle(0, 0, 0);
                captureDragAreaOverlay.graphics.beginFill(0, 0.3);
                captureDragAreaOverlay.graphics.drawRect(0, 0, canvasWidth, rectClamped.y); // 위
                captureDragAreaOverlay.graphics.drawRect(0, rectClamped.y, rectClamped.x, rectClamped.height); // 왼쪽
                captureDragAreaOverlay.graphics.drawRect(rectClamped.x + rectClamped.width, rectClamped.y, canvasWidth - (rectClamped.x + rectClamped.width), rectClamped.height); // 오른쪽
                captureDragAreaOverlay.graphics.drawRect(0, rectClamped.y + rectClamped.height, canvasWidth, canvasHeight - (rectClamped.y + rectClamped.height)); // 아래
                captureDragAreaOverlay.graphics.endFill();

                captureDragAreaOverlay.graphics.lineStyle(lineSize, 0xFFFFFF, 1.0, true);
                captureDragAreaOverlay.graphics.beginFill(0xFFFFFF, 0.0);
                captureDragAreaOverlay.graphics.drawRect(rectClamped.x, rectClamped.y, rectClamped.width, rectClamped.height);

                if (resizeButtonON)
                {
                    drawResizeButton(zoomed);
                }
            }

            function getRotatedRectSizeString():String
            {
                const w:Number = Math.abs(rectClamped.width);
                const h:Number = Math.abs(rectClamped.height);

                if (rectClamped.x === 0.0 && rectClamped.y === 0.0 && rectClamped.width === 0.0 && rectClamped.height === 0.0)
                {
                    if (main.isReplayModeON)
                    {
                        return (captureCanvasRotationStep === 0 || captureCanvasRotationStep === 2) ? main.RCANVAS_WIDTH + " x " + main.RCANVAS_HEIGHT : main.RCANVAS_HEIGHT + " x " + main.RCANVAS_WIDTH;
                    }
                    else
                    {
                        return (captureCanvasRotationStep === 0 || captureCanvasRotationStep === 2) ? canvasWidth + " x " + canvasHeight : canvasHeight + " x " + canvasWidth;
                    }
                }

                if (w < minSize || h < minSize)
                {
                    return "";
                }

                return (captureCanvasRotationStep === 0 || captureCanvasRotationStep === 2) ? w + " x " + h : h + " x " + w;
            }

            function resetCaptureArea():void
            {
                resizeButtonPos.setTo(0, 0);
                resizeFlag = false;
                clickPos.setTo(0, 0);
                rectClamped.x = 0;
                rectClamped.y = 0;
                rectClamped.width = 0;
                rectClamped.height = 0;
                rectRaw.x = 0;
                rectRaw.y = 0;
                rectRaw.width = 0;
                rectRaw.height = 0;
                rectFull.x = 0;
                rectFull.y = 0;
                rectFull.width = 0;
                rectFull.height = 0;
                limitWidthSave = 0;
                limitHeightSave = 0;
                captureDragAreaOverlay.graphics.clear();
                MainUI.topBar.capClipBoard.alpha = 1.0;
                captureStampManager.update();
            }

            function reset():void
            {
                resizeButtonPos.setTo(0, 0);
                resizeFlag = false;
                clickPos.setTo(0, 0);
                rectClamped.x = 0;
                rectClamped.y = 0;
                rectClamped.width = 0;
                rectClamped.height = 0;
                rectRaw.x = 0;
                rectRaw.y = 0;
                rectRaw.width = 0;
                rectRaw.height = 0;
                rectFull.x = 0;
                rectFull.y = 0;
                rectFull.width = 0;
                rectFull.height = 0;
                limitWidthSave = 0;
                limitHeightSave = 0;
                canvasWidth = 0;
                canvasHeight = 0;
                xPanel = null;
                mouseMoved = false;
                MainUI.topBar.capClipBoard.alpha = 1.0;
            }

            function isFullImageCapture():Boolean
            {
                return rectClamped.width === 0.0 || rectClamped.height === 0.0;
            }

            function getCaptureArea():Rectangle
            {
                return rectClamped;
            }

            function isCursorInCaptureDrea():Boolean
            {
                if (!xPanel)
                {
                    return false;
                }
                return rectClamped.contains(xPanel.mouseX, xPanel.mouseY);
            }

            function isCursorInResizeButton():Boolean
            {
                if (!xPanel)
                {
                    return false;
                }
                const p1:Point = new Point(xPanel.mouseX, xPanel.mouseY);
                if (Point.distance(p1, resizeButtonPos) * getCanvasScale() < resizeButtonSize)
                {
                    return true;
                }
                return false;
            }

            function startUpdatingCaptureAreaPosSize(mx:Number, my:Number, flag:Boolean):void
            {
                main.isMouseDragging = true;
                resizeFlag = flag;
                rectRaw.x = rectClamped.x;
                rectRaw.y = rectClamped.y;
                rectRaw.width = rectClamped.width;
                rectRaw.height = rectClamped.height;
                limitWidthSave = rectClamped.x + rectClamped.width;
                limitHeightSave = rectClamped.y + rectClamped.height;
                clickPos.setTo(mx, my);
                main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveCaptureAreaDrawed);
                main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpCaptureArea);
            }

            function start():void
            {
                if (MainUI.topBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
                {
                    if (main.isReplayModeON) // 리플레이 변수로 변경
                    {
                        canvasWidth = main.RCANVAS_WIDTH;
                        canvasHeight = main.RCANVAS_HEIGHT;
                        xPanel = main.rCanvasPanel;
                    }
                    else
                    {
                        canvasWidth = main.CANVAS_WIDTH;
                        canvasHeight = main.CANVAS_HEIGHT;
                        xPanel = main.canvasPanel;
                    }

                    var mx:Number = xPanel.mouseX;
                    var my:Number = xPanel.mouseY;

                    rectFull.x = 0;
                    rectFull.y = 0;
                    rectFull.width = canvasWidth;
                    rectFull.height = canvasHeight;
                    resizeFlag = false;

                    if (isCursorInResizeButton())
                    {
                        startUpdatingCaptureAreaPosSize(mx, my, true);
                    }
                    else if (isCursorInCaptureDrea())
                    {
                        startUpdatingCaptureAreaPosSize(mx, my, false);
                    }
                    else
                    {
                        clickPos.setTo(mx, my);
                        main.isMouseDragging = true;
                        main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveDrawCaptureArea);
                        main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpCaptureArea);
                    }
                }
            }

            return {
                    start: start,
                    reset: reset,
                    resetCaptureArea: resetCaptureArea,
                    getCaptureArea: getCaptureArea,
                    isFullImageCapture: isFullImageCapture,
                    getRotatedRectSizeString: getRotatedRectSizeString,
                    updateDrawArea: updateDrawArea,
                    isCursorInCaptureDrea: isCursorInCaptureDrea,
                    isCursorInResizeButton: isCursorInResizeButton
                };
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

        public static function removeInputEventCaptrueMode():void
        {
            isCaptureModeInputEventsAdded = false;
            main.stage.removeEventListener(KeyboardEvent.KEY_UP, CaptureController.onKeyUpCaptureMode);
            main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, CaptureController.onKeyDownCaptureMode);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, CaptureController.onMouseDownCaptureMode);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, CaptureController.onRightMouseDownCaptureMode);
        }

        public static function addInputEventsCaptrueMode():void
        {
            if (isCaptureModeInputEventsAdded === false)
            {

                isCaptureModeInputEventsAdded = true;
                // resetKeyBuffer();
                main.stage.addEventListener(KeyboardEvent.KEY_UP, CaptureController.onKeyUpCaptureMode, false, -1);
                main.stage.addEventListener(KeyboardEvent.KEY_DOWN, CaptureController.onKeyDownCaptureMode, false, -1);
                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, CaptureController.onMouseDownCaptureMode, false, -1);
                main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, CaptureController.onRightMouseDownCaptureMode, false, -1);
            }
        }
    }
}
