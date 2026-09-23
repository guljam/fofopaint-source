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
        // todo capture area와 stamp 기능 분리, 작은 입력 핸들 이벤트
        // todo capture area선택 영역에서 1px 정도 오차가 있음
        // todo 텍스트 입력하는데 ctrl+s누르면 입력폰트 나옴 아마 ctrl눌렀을때 포커스를 나오던가 입력못하게 해야할것같음 하지만 세이브는 바로 되어야함
        // todo 텍스트 입력하면 포커스 안되도 바로 입력시작?
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static var isCaptureModeON:Boolean = false; // 스크린샷 켜지면 올려줌
        public static var isCaptureCanvasFlipped:Boolean = false; // 캡쳐 대칭한 변수 저장
        public static var isCaptureTransparentBGShowing:Boolean = false; // 배경 제외하고 저장하는 플래그
        
        private static var canvasStateBeforeCaptureMode:Object = {}; // 캡쳐 키면 캔버스 이전 상태 저장함
        public static var drawModeCanvasStateForSaveAppState:Object = {}; // save app state에서 캔버스가 capture모드 상태로 저장해주기 때문에 백업한 데이터로 저장시켜줌
        public static var captureWindowMove:Point = new Point(0, 0); // 스크린샷이 켜져있는 상태에서 창을 조절했을때 스크린샷이 끝나고 나서 regpoint를 그만큼 움직여줘야함
        public static var captureCanvasRotationStep:uint = 0; // 캡쳐 회전한 변수 저장
        private static var capTransparentBGBMPDSize:Number = 32;
        public static var capTransparentBGBMPD:BitmapData;

        public static function executeCaptureFlashEffect():void
        {
            var xPanel:Sprite = (ReplayController.isReplayModeON) ? ReplayController.rCanvasPanel : CanvasController.canvasPanel;
            var posX:Number;
            var posY:Number;
            var canvasWidth:Number;
            var canvasHeight:Number;

            if (CaptureArea.isFullImageCapture())
            {
                posX = 0;
                posY = 0;
                if (ReplayController.isReplayModeON)
                {
                    canvasWidth = ReplayController.RCANVAS_WIDTH;
                    canvasHeight = ReplayController.RCANVAS_HEIGHT;
                }
                else
                {
                    canvasWidth = CanvasController.CANVAS_WIDTH;
                    canvasHeight = CanvasController.CANVAS_HEIGHT;
                }
            }
            else
            {
                const nowCaptureArea:Rectangle = CaptureArea.getCaptureArea();
                posX = nowCaptureArea.x;
                posY = nowCaptureArea.y;
                canvasWidth = nowCaptureArea.width;
                canvasHeight = nowCaptureArea.height;
            }

            CanvasController.applyCanvasFlashEffect(xPanel, posX, posY, canvasWidth, canvasHeight, function ():Boolean
                {
                    return !isCaptureModeON;
                });
        }

        public static function getCaptrueImageBitmapdata(clipBoardCopyFlag:Boolean):BitmapData
        {
            const isReplayMode:Boolean = ReplayController.isReplayModeON;
            var rect:Rectangle = (!CaptureArea.isFullImageCapture()) ? CaptureArea.getCaptureArea() : null;
            var layer1:Boolean;
            var layer2:Boolean;

            if (isReplayMode)
            {
                layer1 = ReplayController.rCanvasLayer1Bitmap.visible;
                layer2 = ReplayController.rCanvasLayer2Bitmap.visible;
            }
            else
            {
                layer1 = CanvasController.canvasLayer1Bitmap.visible;
                layer2 = CanvasController.canvasLayer2Bitmap.visible;
            }

            const bmpd:BitmapData = CanvasController.getMergedBitmapdtata((isCaptureModeON && isCaptureTransparentBGShowing && !clipBoardCopyFlag) ? true : false, layer1, layer2, rect);
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

            if (CaptureStamp.isCaptureStampEnabled && tmpbmpd.width >= 300)
            {
                CaptureStamp.kungFinal(tmpbmpd);
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
            const xAnc:Sprite = (ReplayController.isReplayModeON) ? ReplayController.rCanvasAnchorPoint : CanvasController.canvasAnchorPoint;
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
            CanvasController.fitCanvasToViewportMargin();
            const xAnc:Sprite = (ReplayController.isReplayModeON) ? ReplayController.rCanvasAnchorPoint : CanvasController.canvasAnchorPoint;

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
                CaptureArea.updateDrawArea();
            }
        }

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

        public static function handleExitCaptureMode():void
        {
            FileManager.setFileBrowserIsOpen(false);
            exitCaptureMode();
        }

        public static function restoreCanvasBackgroundColorDrawMode():void
        {
            var panel:Sprite = CanvasController.canvasPanel;
            var w:Number = CanvasController.CANVAS_WIDTH;
            var h:Number = CanvasController.CANVAS_HEIGHT;
            var color:uint = CanvasController.CANVAS_BG_COLOR;

            panel.graphics.clear();
            panel.graphics.beginFill(color);
            panel.graphics.drawRect(0, 0, w, h);
            panel.graphics.endFill();
        }

        public static function restoreCanvasBackgroundColorReplayMode():void
        {
            var panel:Sprite = ReplayController.rCanvasPanel;
            var w:Number = ReplayController.RCANVAS_WIDTH;
            var h:Number = ReplayController.RCANVAS_HEIGHT;
            var color:uint = ReplayController.RCANVAS_BG_COLOR;

            panel.graphics.clear();
            panel.graphics.beginFill(color);
            panel.graphics.drawRect(0, 0, w, h);
            panel.graphics.endFill();
        }

        public static function applyTransparentCanvasBGCaptureMode(flag:Boolean):void
        {
            isCaptureTransparentBGShowing = flag;

            if (isCaptureTransparentBGShowing)
            {
                BackgroundWorkerCoordinator.applyTransparentCanvasBackground(ReplayController.isReplayModeON);
            }
            else if (ReplayController.isReplayModeON)
            {
                restoreCanvasBackgroundColorReplayMode();
            }
            else
            {
                restoreCanvasBackgroundColorDrawMode();
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

            CanvasController.fitCanvasToViewportMargin();
            MainUI.topBar.capClipBoard.alpha = 1.0;
            if (!initFlag)
            {
                CaptureArea.updateDrawArea();
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
                const xCanvasPanel:Sprite = (ReplayController.isReplayModeON) ? ReplayController.rCanvasPanel : CanvasController.canvasPanel;

                if (CaptureArea.isFullImageCapture() && xCanvasPanel.hitTestPoint(main.stage.mouseX, main.stage.mouseY, true))
                {
                    MainUI.showHintHighlightBox((ReplayController) ? ReplayController.rCanvasLayer1Bitmap : CanvasController.canvasLayer1Bitmap);
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

        public static function enterCaptureMode():void
        {
            if (isCaptureModeON || ReplayController.isGeneratingCacheImages())
            {
                return;
            }

            if (ReplayController.isReplayStarted)
            {
                ReplayController.stopReplay();
            }

            isCaptureModeON = true;
            PenSizePreviewCursor.setCursorInVisibleFlag(true);

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

            if (ReplayController.isReplayModeON)
            {
                xAnc = ReplayController.rCanvasAnchorPoint;
                xPanel = ReplayController.rCanvasPanel;
                xZoomed = ReplayController.rCanvasZoomMultiplier;
                ReplayController.rReplayFOFOCursor.visible = false;
                ReplayController.rCanvasPanel.addChild(CaptureArea.captureDragAreaOverlay);
                layer1 = true;
                layer2 = true;
            }
            else
            {
                xAnc = CanvasController.canvasAnchorPoint;
                xPanel = CanvasController.canvasPanel;
                xZoomed = CanvasController.canvasZoomMultipler;
                CanvasController.canvasPanel.addChild(CaptureArea.captureDragAreaOverlay);
                if (CanvasController.canvasLayer1Bitmap.visible)
                    layer1 = true;
                if (CanvasController.canvasLayer2Bitmap.visible)
                    layer2 = true;
            }

            Utils.setAsTopChild(CaptureArea.captureDragAreaOverlay);
            CaptureArea.captureDragAreaOverlay.visible = true;

            drawModeCanvasStateForSaveAppState = {
                    "z": CanvasController.canvasZoomMultipler,
                    "x": Math.floor(CanvasController.canvasAnchorPoint.x), // 뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
                    "y": Math.floor(CanvasController.canvasAnchorPoint.y),
                    "r": CanvasController.canvasAnchorPoint.rotation,
                    "px": Math.floor(CanvasController.canvasPanel.x),
                    "py": Math.floor(CanvasController.canvasPanel.y)
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
            CanvasController.fitCanvasToViewportMargin();
            applyTransparentCanvasBGCaptureMode(false);
            CaptureStamp.init();

            if (CaptureStamp.isCaptureStampEnabled)
            {
                CaptureStamp.update();
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
            const replayMode:Boolean = ReplayController.isReplayModeON;
            const data:Object = canvasStateBeforeCaptureMode;
            const xBitmap1:Bitmap = (replayMode) ? ReplayController.rCanvasLayer1Bitmap : CanvasController.canvasLayer1Bitmap;
            const xBitmap11:Bitmap = (replayMode) ? ReplayController.rCanvasLayer2Bitmap : CanvasController.canvasLayer2Bitmap;
            const xAnc:Sprite = (replayMode) ? ReplayController.rCanvasAnchorPoint : CanvasController.canvasAnchorPoint;
            const xPanel:Sprite = (replayMode) ? ReplayController.rCanvasPanel : CanvasController.canvasPanel;

            xBitmap1.smoothing = false;
            xBitmap11.smoothing = false;
            isCaptureModeON = false;
            PenSizePreviewCursor.setCursorInVisibleFlag(false);

            CaptureArea.captureDragAreaOverlay.graphics.clear();
            CaptureStamp.off();
            CaptureArea.captureDragAreaOverlay.visible = false;

            // 캔버스 이전 모양 위치로 복원
            xAnc.rotation = data.r;
            xAnc.x = data.x + captureWindowMove.x;
            xAnc.y = data.y + captureWindowMove.y;
            xPanel.x = data.px;
            xPanel.y = data.py;

            if (replayMode)
            {
                ReplayController.rCanvasLayer1Bitmap.visible = true;
                ReplayController.rCanvasLayer2Bitmap.visible = true;
                ReplayController.rCanvasDrawLayer.visible = true;
            }
            else
            {
                CanvasController.canvasLayer1Bitmap.visible = data.layer1;
                CanvasController.canvasLayer2Bitmap.visible = data.layer2;
            }

            if (!ReplayController.isReplayCanvasFitToWindow)
            {
                CanvasController.updateCanvasScale(data.z, replayMode);
            }

            MainUI.resetLastBottomHintTargetRect();
            MainUI.hideMouseHint();
            captureWindowMove.setTo(0, 0);
            PenSizePreviewCursor.updateSizeAndShape();

            // prev box 사각형 업데이트가 있기 때문에 xAnc위치가 갱신된 다음에 해주어야함
            MainUI.deactivateCaptureUI();
            MainUI.hideBottomHint();

            if (replayMode)
            {
                restoreCanvasBackgroundColorReplayMode();
                ReplayController.rReplayFOFOCursor.visible = true;
            }
            else if (!replayMode)
            {
                restoreCanvasBackgroundColorDrawMode();
            }

            CanvasController.keepCanvasPanelInStage(replayMode);
            canvasStateBeforeCaptureMode = {};
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

    }
}
