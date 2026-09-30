package Modules.CaptureEngine
{
    import Modules.Utils;
    import Modules.SidebarController;
    import Modules.PenSizePreviewCursor;
    import Modules.MainUIController;
    import Modules.MainUI;
    import Modules.FileManager;
    import Modules.ColorPickerController;
    import Modules.CanvasController;
    import Modules.BackgroundWorkerCoordinator;
    import flash.desktop.Clipboard;
    import flash.desktop.ClipboardFormats;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.ReplayEngine.ReplayState;

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

        private static var _isCaptureModeON:Boolean = false; // 스크린샷 켜지면 올려줌
        private static var _isCaptureCanvasFlipped:Boolean = false; // 캡쳐 대칭한 변수 저장
        private static var _isCaptureTransparentBGShowing:Boolean = false; // 배경 제외하고 저장하는 플래그
        private static var canvasStateBeforeCaptureMode:Object = {}; // 캡쳐 키면 캔버스 이전 상태 저장함
        private static var _drawModeCanvasStateForSaveAppState:Object = {}; // save app state에서 캔버스가 capture모드 상태로 저장해주기 때문에 백업한 데이터로 저장시켜줌
        private static var _captureWindowMove:Point = new Point(0, 0); // 스크린샷이 켜져있는 상태에서 창을 조절했을때 스크린샷이 끝나고 나서 regpoint를 그만큼 움직여줘야함
        private static var _captureCanvasRotationStep:uint = 0; // 캡쳐 회전한 변수 저장
        private static var capTransparentBGBMPDSize:Number = 32;
        private static var _capTransparentBGBMPD:BitmapData;

        public static function get isCaptureModeON():Boolean
        {
            return _isCaptureModeON;
        }

        public static function get isCaptureCanvasFlipped():Boolean
        {
            return _isCaptureCanvasFlipped;
        }

        public static function get isCaptureTransparentBGShowing():Boolean
        {
            return _isCaptureTransparentBGShowing;
        }

        public static function get captureCanvasRotationStep():uint
        {
            return _captureCanvasRotationStep;
        }

        public static function get capTransparentBGBMPD():BitmapData
        {
            return _capTransparentBGBMPD;
        }

        public static function get drawModeCanvasStateForSaveAppState():Object
        {
            return _drawModeCanvasStateForSaveAppState;
        }

        // 90도/270도 회전이라 가로세로가 바뀐 상태
        public static function isCaptureAxisSwapped():Boolean
        {
            return _captureCanvasRotationStep % 2 === 1;
        }

        // 캡쳐 중 창 크기 조절은 여러 번 일어날 수 있고 dx/dy는 직전 배치 대비 변화량이라 누적해야 함
        public static function addCaptureWindowMove(dx:Number, dy:Number):void
        {
            _captureWindowMove.offset(dx, dy);
        }

        // ---- CaptureArea/CaptureStamp가 서로 직접 참조하지 않고 Controller를 거치도록 하는 중계 ----
        public static function isFullImageCapture():Boolean
        {
            return CaptureArea.isFullImageCapture();
        }

        public static function getCaptureArea():Rectangle
        {
            return CaptureArea.getCaptureArea();
        }

        public static function startCaptureAreaSelection():void
        {
            CaptureArea.start();
        }

        public static function resetCaptureAreaSelection():void
        {
            CaptureArea.resetCaptureArea();
        }

        public static function resetCaptureArea():void
        {
            CaptureArea.reset();
        }

        public static function updateCaptureAreaOverlay(forceFlag:Boolean = false):void
        {
            CaptureArea.updateDrawArea(forceFlag);
        }

        // CaptureArea가 영역을 선택/이동/리사이즈 시작했을 때 (스탬프 임시 숨김)
        public static function onCaptureAreaDragStarted():void
        {
            CaptureStamp.setVisible(false);
        }

        // CaptureArea의 영역이 확정/초기화/갱신됐을 때 (스탬프 재계산)
        public static function onCaptureAreaChanged():void
        {
            CaptureStamp.update();
        }

         public static function toggleLayerCaptureMode(layer:int):void
        {
            MainUI.topBar.capClipBoard.alpha = 1.0;
            const replayMode:Boolean = ReplayState.isReplayModeON;
            var bitmap:Bitmap = replayMode
                ? (layer == 1 ? ReplayDrawer.rCanvasLayer1Bitmap : ReplayDrawer.rCanvasLayer2Bitmap)
                : (layer == 1 ? CanvasController.canvasLayer1Bitmap : CanvasController.canvasLayer2Bitmap);
            var button:DisplayObject = (layer == 1)
                ? MainUI.topBar.capLayer1VisibleButton
                : MainUI.topBar.capLayer2VisibleButton;
            var otherButton:DisplayObject = (layer == 1)
                ? MainUI.topBar.capLayer2VisibleButton
                : MainUI.topBar.capLayer1VisibleButton;

            if (bitmap.visible)
            {
                bitmap.visible = false;
                button.alpha = Global.OFFALPHA;

                if (replayMode)
                {
                    if ((layer == 1 && !ReplayDrawer.isLayer2SelectedReplayMode())
                            || (layer == 2 && ReplayDrawer.isLayer2SelectedReplayMode()))
                    {
                        ReplayDrawer.rCanvasDrawLayer.visible = false;
                    }
                }

                if (otherButton.alpha < 1.0)
                {
                    toggleLayerCaptureMode((layer == 1) ? 2 : 1);
                }
            }
            else
            {
                bitmap.visible = true;
                button.alpha = 1.0;

                if (replayMode)
                {
                    if ((layer == 1 && !ReplayDrawer.isLayer2SelectedReplayMode())
                            || (layer == 2 && ReplayDrawer.isLayer2SelectedReplayMode()))
                    {
                        ReplayDrawer.rCanvasDrawLayer.visible = true;
                    }
                }
            }

            CaptureArea.updateDrawArea();
        }

        public static function executeCaptureFlashEffect():void
        {
            var xPanel:Sprite = (ReplayState.isReplayModeON) ? ReplayDrawer.rCanvasPanel : CanvasController.canvasPanel;
            var posX:Number;
            var posY:Number;
            var canvasWidth:Number;
            var canvasHeight:Number;

            if (CaptureArea.isFullImageCapture())
            {
                posX = 0;
                posY = 0;
                if (ReplayState.isReplayModeON)
                {
                    canvasWidth = ReplayState.RCANVAS_WIDTH;
                    canvasHeight = ReplayState.RCANVAS_HEIGHT;
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
                    return !_isCaptureModeON;
                });
        }

        public static function getCaptrueImageBitmapdata(clipBoardCopyFlag:Boolean):BitmapData
        {
            const isReplayMode:Boolean = ReplayState.isReplayModeON;
            var rect:Rectangle = (!CaptureArea.isFullImageCapture()) ? CaptureArea.getCaptureArea() : null;
            var layer1:Boolean;
            var layer2:Boolean;

            if (isReplayMode)
            {
                layer1 = ReplayDrawer.rCanvasLayer1Bitmap.visible;
                layer2 = ReplayDrawer.rCanvasLayer2Bitmap.visible;
            }
            else
            {
                layer1 = CanvasController.canvasLayer1Bitmap.visible;
                layer2 = CanvasController.canvasLayer2Bitmap.visible;
            }

            const bmpd:BitmapData = CanvasController.getMergedBitmapdtata((_isCaptureModeON && _isCaptureTransparentBGShowing && !clipBoardCopyFlag) ? true : false, layer1, layer2, rect);
            const mat:Matrix = new Matrix();
            const deg:Number = 90 * _captureCanvasRotationStep;
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

            if (_isCaptureCanvasFlipped)
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
            _capTransparentBGBMPD = new BitmapData(capTransparentBGBMPDSize, capTransparentBGBMPDSize, false, 0xFFFFFF);
            _capTransparentBGBMPD.fillRect(new Rectangle(0, 0, halfSize, halfSize), 0xC8C8C8);
            _capTransparentBGBMPD.fillRect(new Rectangle(halfSize, halfSize, halfSize, halfSize), 0xCCCCCC);
        }

        public static function flipCaptureImage(flag:Boolean, initFlag:Boolean):void
        {
            _isCaptureCanvasFlipped = flag;
            CanvasController.fitCanvasToViewportMargin();
            const xAnc:Sprite = (ReplayState.isReplayModeON) ? ReplayDrawer.rCanvasAnchorPoint : CanvasController.canvasAnchorPoint;

            if (_captureCanvasRotationStep === 1)
            {
                _captureCanvasRotationStep = 3;
                xAnc.rotation = 270;
            }
            else if (_captureCanvasRotationStep === 3)
            {
                _captureCanvasRotationStep = 1;
                xAnc.rotation = 90;
            }

            MainUI.topBar.capClipBoard.alpha = 1.0;
            if (!initFlag)
            {
                CaptureArea.updateDrawArea();
            }
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
            var panel:Sprite = ReplayDrawer.rCanvasPanel;
            var w:Number = ReplayState.RCANVAS_WIDTH;
            var h:Number = ReplayState.RCANVAS_HEIGHT;
            var color:uint = ReplayState.RCANVAS_BG_COLOR;

            panel.graphics.clear();
            panel.graphics.beginFill(color);
            panel.graphics.drawRect(0, 0, w, h);
            panel.graphics.endFill();
        }

        public static function applyTransparentCanvasBGCaptureMode(flag:Boolean):void
        {
            _isCaptureTransparentBGShowing = flag;

            if (_isCaptureTransparentBGShowing)
            {
                BackgroundWorkerCoordinator.applyTransparentCanvasBackground(ReplayState.isReplayModeON);
            }
            else if (ReplayState.isReplayModeON)
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
            _captureCanvasRotationStep = rotateValue;

            CanvasController.fitCanvasToViewportMargin();
            MainUI.topBar.capClipBoard.alpha = 1.0;
            if (!initFlag)
            {
                CaptureArea.updateDrawArea();
            }
        }

        public static function enterCaptureMode():void
        {
            if (_isCaptureModeON || ReplayState.isGeneratingCacheImages())
            {
                return;
            }

            if (ReplayState.isReplayStarted)
            {
                ReplayController.stopReplay();
            }

            _isCaptureModeON = true;
            PenSizePreviewCursor.setCursorInVisibleFlag(true);

            if (ColorPickerController.numPadBox.visible)
            {
                ColorPickerController.closeNumpad();
            }

            if (!SidebarController.isSidebarVisible && SidebarController.sideBar.visible)
            {
                SidebarController.startHidingSidebarTemporary();
            }

            MainUIController.activateCaptureUI();
            CaptureArea.startHoverTracking();
            MainUI.hideBottomHint();

            var xAnc:Sprite;
            var xPanel:Sprite;
            var xZoomed:Number;
            var layer1:Boolean;
            var layer2:Boolean;

            if (ReplayState.isReplayModeON)
            {
                xAnc = ReplayDrawer.rCanvasAnchorPoint;
                xPanel = ReplayDrawer.rCanvasPanel;
                xZoomed = ReplayState.rCanvasZoomMultiplier;
                ReplayDrawer.rReplayFOFOCursor.visible = false;
                ReplayDrawer.rCanvasPanel.addChild(CaptureArea.captureDragAreaOverlay);
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

            _drawModeCanvasStateForSaveAppState = {
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
            _captureCanvasRotationStep = 0;
            _isCaptureCanvasFlipped = false;
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
            _captureCanvasRotationStep = 0;
            _isCaptureCanvasFlipped = false;
            _isCaptureTransparentBGShowing = false;
        }

        public static function exitCaptureMode():void
        {
            const replayMode:Boolean = ReplayState.isReplayModeON;
            const data:Object = canvasStateBeforeCaptureMode;
            const xBitmap1:Bitmap = (replayMode) ? ReplayDrawer.rCanvasLayer1Bitmap : CanvasController.canvasLayer1Bitmap;
            const xBitmap11:Bitmap = (replayMode) ? ReplayDrawer.rCanvasLayer2Bitmap : CanvasController.canvasLayer2Bitmap;
            const xAnc:Sprite = (replayMode) ? ReplayDrawer.rCanvasAnchorPoint : CanvasController.canvasAnchorPoint;
            const xPanel:Sprite = (replayMode) ? ReplayDrawer.rCanvasPanel : CanvasController.canvasPanel;

            xBitmap1.smoothing = false;
            xBitmap11.smoothing = false;
            _isCaptureModeON = false;
            PenSizePreviewCursor.setCursorInVisibleFlag(false);

            CaptureArea.stopHoverTracking();
            CaptureArea.captureDragAreaOverlay.graphics.clear();
            CaptureStamp.off();
            CaptureArea.captureDragAreaOverlay.visible = false;

            // 캔버스 이전 모양 위치로 복원
            xAnc.rotation = data.r;
            xAnc.x = data.x + _captureWindowMove.x;
            xAnc.y = data.y + _captureWindowMove.y;
            xPanel.x = data.px;
            xPanel.y = data.py;

            if (replayMode)
            {
                ReplayDrawer.rCanvasLayer1Bitmap.visible = true;
                ReplayDrawer.rCanvasLayer2Bitmap.visible = true;
                ReplayDrawer.rCanvasDrawLayer.visible = true;
            }
            else
            {
                CanvasController.canvasLayer1Bitmap.visible = data.layer1;
                CanvasController.canvasLayer2Bitmap.visible = data.layer2;
            }

            if (!ReplayState.isReplayCanvasFitToWindow)
            {
                CanvasController.updateCanvasScale(data.z, replayMode);
            }

            MainUI.resetLastBottomHintTargetRect();
            MainUI.hideMouseHint();
            _captureWindowMove.setTo(0, 0);
            PenSizePreviewCursor.updateSizeAndShape();

            // prev box 사각형 업데이트가 있기 때문에 xAnc위치가 갱신된 다음에 해주어야함
            MainUIController.deactivateCaptureUI();
            MainUI.hideBottomHint();

            if (replayMode)
            {
                restoreCanvasBackgroundColorReplayMode();
                ReplayDrawer.rReplayFOFOCursor.visible = true;
            }
            else if (!replayMode)
            {
                restoreCanvasBackgroundColorDrawMode();
            }

            CanvasController.keepCanvasPanelInStage(replayMode);
            canvasStateBeforeCaptureMode = {};
        }
    }
}
