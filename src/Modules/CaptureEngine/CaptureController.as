package Modules.CaptureEngine
{
    import Modules.UIEngine.UITheme;
    import Modules.ReferenceLayerController;
    import flash.desktop.Clipboard;
    import flash.desktop.ClipboardFormats;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import Modules.L4UI.CanvasGridOverlay;
    import Modules.L5App.InputManager.CaptureModeInput;
    import Modules.L4UI.ColorPickerController;
    import Modules.L5App.InputManager.DrawModeInput;
    import Modules.L5App.FileManager;
    import Modules.L5App.InputManager.InputManager;
    import Modules.L5App.ReplayEngine.ReplayController;
    import Modules.L5App.InputManager.ReplayModeInput;
    import Modules.L4UI.SidebarController;
    import Modules.L2Engine.BackgroundWorkerCoordinator;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L4UI.PenSizePreviewCursor;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L4UI.CanvasViewport;
    import Modules.L4UI.DrawEngine.CanvasResizer;
    import Modules.L2Engine.ReplayEngine.ReplayState;
    import Modules.L1Data.Utils;

    // 층: L3 기능 - 캡처 모드 진입·종료와 캡처 처리
    public class CaptureController
    {
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
            UIController.topBar.capClipBoard.alpha = 1.0;
            const replayMode:Boolean = ReplayState.isReplayModeON;
            var bitmap:Bitmap = replayMode
                ? (layer == 1 ? ReplayDrawer.rCanvasLayer1Bitmap : ReplayDrawer.rCanvasLayer2Bitmap)
                : (layer == 1 ? DrawCanvas.canvasLayer1Bitmap : DrawCanvas.canvasLayer2Bitmap);
            var button:DisplayObject = (layer == 1)
                ? UIController.topBar.capLayer1VisibleButton
                : UIController.topBar.capLayer2VisibleButton;
            var otherButton:DisplayObject = (layer == 1)
                ? UIController.topBar.capLayer2VisibleButton
                : UIController.topBar.capLayer1VisibleButton;

            if (bitmap.visible)
            {
                bitmap.visible = false;
                button.alpha = UITheme.OFFALPHA;

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
            var xPanel:Sprite = CanvasViewport.current().panel;
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
                    canvasWidth = DrawCanvas.CANVAS_WIDTH;
                    canvasHeight = DrawCanvas.CANVAS_HEIGHT;
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

            CanvasView.applyCanvasFlashEffect(xPanel, posX, posY, canvasWidth, canvasHeight, function ():Boolean
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
                layer1 = DrawCanvas.canvasLayer1Bitmap.visible;
                layer2 = DrawCanvas.canvasLayer2Bitmap.visible;
            }

            const bmpd:BitmapData = DrawCanvas.getMergedBitmapData((_isCaptureModeON && _isCaptureTransparentBGShowing && !clipBoardCopyFlag) ? true : false, layer1, layer2, rect);
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
            UIController.topBar.capClipBoard.alpha = UITheme.OFFALPHA;
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
            CanvasViewport.current().fitToViewportMargin();
            const xAnc:Sprite = CanvasViewport.current().anchor;

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

            UIController.topBar.capClipBoard.alpha = 1.0;
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
            var panel:Sprite = CanvasView.canvasPanel;
            var w:Number = DrawCanvas.CANVAS_WIDTH;
            var h:Number = DrawCanvas.CANVAS_HEIGHT;
            var color:uint = DrawCanvas.CANVAS_BG_COLOR;

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
            UIController.topBar.capClipBoard.alpha = 1.0;
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

            CanvasViewport.current().fitToViewportMargin();
            UIController.topBar.capClipBoard.alpha = 1.0;
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

            activateCaptureUI();
            CaptureArea.initCanvas();
            CaptureArea.startHoverTracking();
            HintController.hideBottomHint();

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
                xAnc = CanvasView.canvasAnchorPoint;
                xPanel = CanvasView.canvasPanel;
                xZoomed = CanvasView.canvasZoomMultiplier;
                CanvasView.canvasPanel.addChild(CaptureArea.captureDragAreaOverlay);
                if (DrawCanvas.canvasLayer1Bitmap.visible)
                    layer1 = true;
                if (DrawCanvas.canvasLayer2Bitmap.visible)
                    layer2 = true;
            }

            Utils.setAsTopChild(CaptureArea.captureDragAreaOverlay);
            CaptureArea.captureDragAreaOverlay.visible = true;

            _drawModeCanvasStateForSaveAppState = {
                    "z": CanvasView.canvasZoomMultiplier,
                    "x": Math.floor(CanvasView.canvasAnchorPoint.x), // 뭔가 크기가 살짝 달라져서 소숫점 버림 해줌
                    "y": Math.floor(CanvasView.canvasAnchorPoint.y),
                    "r": CanvasView.canvasAnchorPoint.rotation,
                    "px": Math.floor(CanvasView.canvasPanel.x),
                    "py": Math.floor(CanvasView.canvasPanel.y)
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

            HintController.resetLastBottomHintTargetRect();
            UIController.topBar.capClipBoard.alpha = 1.0;
            _captureCanvasRotationStep = 0;
            _isCaptureCanvasFlipped = false;
            CanvasViewport.current().fitToViewportMargin();
            applyTransparentCanvasBGCaptureMode(false);
            CaptureStamp.init();

            if (CaptureStamp.isCaptureStampEnabled)
            {
                CaptureStamp.update();
            }
        }

        private static function activateCaptureUI():void
        {
            const replayMode:Boolean = ReplayState.isReplayModeON;
            resetCaptureArea();
            CanvasResizer.updateButtonVisible(false);
            FOFOTimer.remove("rCursorOffAlphaAnimTimer");

            if (replayMode)
            {
                ReplayController.showTopbarOnPlayback();
                ReplayController.seekBarBox.setDeleteRangeBarVisible(false);
                ReplayController.seekBarBox.visible = false;
                ReplayModeInput.removeEvents();
            }
            else
            {
                CanvasGridOverlay.canvasGrid.visible = false;
                DrawModeInput.removeEvents();
            }

            if (SidebarController.isSidebarVisible)
            {
                SidebarController.hideSidebarTemporary();
            }

            PenSizePreviewCursor.setCursorInVisibleFlag(true);
            PenSizePreviewCursor.setVisible(false);
            ReferenceLayerController.canvasRefLayer.visible = false;

            if (ReferenceLayerController.isRefLayerMenuON)
            {
                ReferenceLayerController.refLayerMenuBox.visible = false;
            }

            UIController.updateTopbarIconsCaptureMode();
            ReplayDrawer.rReplayFOFOCursor.visible = false;

            if (HintController.mouseHint.isShowing())
            {
                HintController.hideMouseHint();
            }

            CaptureModeInput.addEvents();
            UIController.updateStageOffset();
        }

        private static function deactivateCaptureUI():void
        {
            const replayMode:Boolean = ReplayState.isReplayModeON;
            CaptureModeInput.removeEvents();
            ReferenceLayerController.canvasRefLayer.visible = true;

            if (replayMode)
            {
                UIController.updateTopbarIconsReplayMode();
                ReplayModeInput.addEvents();
                ReplayController.seekBarBox.visible = true;
            }
            else
            {
                if (SidebarController.isSidebarVisible)
                {
                    SidebarController.showSidebarPermanent();
                }
                if (ReferenceLayerController.isRefLayerMenuON)
                {
                    ReferenceLayerController.refLayerMenuBox.visible = true;
                }
                PenSizePreviewCursor.setCursorInVisibleFlag(false);
                UIController.updateTopbarIconsDrawMode();
                DrawModeInput.addEvents();
            }

            ColorPickerController.switchColorPickerModePen();
            UIController.updateStageOffset();
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
            const xBitmap1:Bitmap = CanvasViewport.forMode(replayMode).layer1Bitmap;
            const xBitmap11:Bitmap = CanvasViewport.forMode(replayMode).layer2Bitmap;
            const xAnc:Sprite = CanvasViewport.forMode(replayMode).anchor;
            const xPanel:Sprite = CanvasViewport.forMode(replayMode).panel;

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
                DrawCanvas.canvasLayer1Bitmap.visible = data.layer1;
                DrawCanvas.canvasLayer2Bitmap.visible = data.layer2;
            }

            if (!ReplayState.isReplayCanvasFitToWindow)
            {
                CanvasViewport.forMode(replayMode).setScale(data.z);
            }

            HintController.resetLastBottomHintTargetRect();
            HintController.hideMouseHint();
            _captureWindowMove.setTo(0, 0);
            PenSizePreviewCursor.updateSizeAndShape();

            // prev box 사각형 업데이트가 있기 때문에 xAnc위치가 갱신된 다음에 해주어야함
            deactivateCaptureUI();
            HintController.hideBottomHint();

            if (replayMode)
            {
                restoreCanvasBackgroundColorReplayMode();
                ReplayDrawer.rReplayFOFOCursor.visible = true;
            }
            else if (!replayMode)
            {
                restoreCanvasBackgroundColorDrawMode();
            }

            CanvasViewport.forMode(replayMode).keepInStage();
            canvasStateBeforeCaptureMode = {};
        }
    }
}
