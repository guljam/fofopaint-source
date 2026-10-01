package Modules.DrawEngine
{
    import Modules.CanvasGridOverlay;
    import Modules.CaptureEngine.CaptureController;
    import Modules.ColorPickerController;
    import Modules.FileManager;
    import Modules.ImageViewWindow;
    import Modules.PenSizePreviewCursor;
    import Modules.ReferenceLayerController;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.ReplayEngine.ReplayState;
    import Modules.SidebarController;
    import Modules.Tools.EyeDropperTool;
    import Modules.Tools.LassoTool;
    import Modules.Tools.ZoomTool;
    import Modules.UIEngine.CanvasNavigator;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;
    import Modules.UIEngine.UITheme;
    import Modules.Utils;

    import flash.display.Bitmap;
    import flash.display.DisplayObjectContainer;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    // 드로우 모드 캔버스의 화면 배치: 앵커/패널 표시 트리, 이동, 줌, 회전/미러 화면 처리
    public class CanvasView
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static const canvasFlashEffect:Sprite = new Sprite();
        public static var canvasAnchorPoint:Sprite = new Sprite(); // 회전 스프라이트 부모
        public static var canvasPanel:Sprite = new Sprite(); // 회색 부분을 제외한 그리기 영역 추가
        public static var canvasZoomMultiplierList:Array = [0.125, 0.25, 0.5, 0.75, 1.0, 1.50, 2.0, 3.0, 4.0, 6.0, 8.0];
        public static var canvasZoomMultiplier:Number = 1.0;
        public static var canvasZoomIndex:int = 4;

        public static function resetRotationDrawMode():void
        {
            const center:Point = UIController.getStageCenterPos("draw");
            PenSizePreviewCursor.updateSizeAndShape();
            moveCanvasAnchorPoint(center.x, center.y, false);
            canvasAnchorPoint.rotation = 0;
            ReplayDrawer.setRcursorRotation(0);
            UIController.canvasInfoBox.setRotate(0);
        }

        public static function applyCanvasFlashEffect(parent:DisplayObjectContainer, ox:Number, oy:Number, width:Number, height:Number, stopHandler:Function):void
        {
            if (!parent.getChildByName("canvasFlash"))
            {
                parent.addChild(canvasFlashEffect);
            }
            canvasFlashEffect.visible = true;
            canvasFlashEffect.graphics.beginFill(0xFFFFFF);
            canvasFlashEffect.graphics.drawRect(ox, oy, width, height);
            canvasFlashEffect.graphics.endFill();
            canvasFlashEffect.alpha = 1.0;
            const fadeStep:Number = Math.floor(0.05 * 256) / 256;
            FOFOTimer.addByName("flashingTimer", 0.0, true, function ():Boolean
                {
                    if (canvasFlashEffect.alpha < 0.1 || stopHandler())
                    {
                        canvasFlashEffect.alpha = 0.0;
                        canvasFlashEffect.visible = false;
                        canvasFlashEffect.graphics.clear();
                        if (parent.getChildByName("canvasFlash"))
                        {
                            parent.removeChild(canvasFlashEffect);
                        }
                        return false;
                    }
                    canvasFlashEffect.alpha -= fadeStep;
                    return true;
                });
        }

        public static function updateCanvasPanelMask(w:Number, h:Number):void
        {
            canvasPanel.scrollRect = new Rectangle(0, 0, w, h);
        }

        public static function resetZoomDrawMode():void
        {
            if (canvasZoomMultiplier !== 1.0)
            {
                const center:Point = UIController.getStageCenterPos("draw");
                const gcenter:Point = canvasPanel.globalToLocal(new Point(center.x, center.y));
                const gp:Point = canvasPanel.localToGlobal(new Point(0, 0));
                const panelLimitedPos:Point = ZoomTool.getCanvasBoundLimitPoint(canvasPanel, gcenter.x, gcenter.y, DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, canvasAnchorPoint.scaleY, -canvasAnchorPoint.rotation);
                moveCanvasAnchorPoint(panelLimitedPos.x + gp.x, panelLimitedPos.y + gp.y, false);
                canvasZoomIndex = canvasZoomMultiplierList.indexOf(1.0);
                updateCanvasScale(1.0, false);
                PenSizePreviewCursor.updateSizeAndShape();
                CanvasGridOverlay.drawGrid();
            }
        }

        public static function zoomInCanvas(zoomInFlag:Boolean, isReplayMode:Boolean):void
        {
            const xAnc:Sprite = (isReplayMode) ? ReplayDrawer.rCanvasAnchorPoint : canvasAnchorPoint;
            const zoomMax:int = canvasZoomMultiplierList.length - 1;
            var center:Point;
            var newZoomIndex:int = (isReplayMode) ? ReplayState.rCanvasZoomIndex : canvasZoomIndex;
            if (zoomInFlag)
            {
                newZoomIndex++;
                if (newZoomIndex > zoomMax)
                {
                    newZoomIndex = zoomMax;
                }
            }
            else
            {
                newZoomIndex--;
                if (newZoomIndex < 0)
                {
                    newZoomIndex = 0;
                }
            }
            const newZoom:Number = canvasZoomMultiplierList[newZoomIndex];
            if (isReplayMode)
            {
                center = UIController.getStageCenterPos("replay");
                ReplayState.rLastCanvasZoomMultiplier = newZoom;
                ReplayController.setFitReplayCanvasToViewportOFF();
                ReplayState.rCanvasZoomIndex = newZoomIndex;
                moveCanvasAnchorPoint(center.x, center.y, true);
                updateCanvasScale(newZoom, isReplayMode);
                ReplayController.rFollowMouse.updateBounds();
                HintController.showMouseHintTemp(String(Math.floor(newZoom * 100)) + "%");
            }
            else
            {
                center = UIController.getStageCenterPos("draw");
                const gcenter:Point = canvasPanel.globalToLocal(new Point(center.x, center.y));
                const gp:Point = canvasPanel.localToGlobal(new Point(0, 0));
                const panelLimitedPos:Point = ZoomTool.getCanvasBoundLimitPoint(canvasPanel, gcenter.x, gcenter.y, DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, xAnc.scaleY, -xAnc.rotation);
                canvasZoomIndex = newZoomIndex;
                moveCanvasAnchorPoint(panelLimitedPos.x + gp.x, panelLimitedPos.y + gp.y, false);
                updateCanvasScale(newZoom, isReplayMode);
                PenSizePreviewCursor.updateSizeAndShape();
                CanvasNavigator.updateCursor();
                if (CanvasGridOverlay.gridGapMultiplier > 0)
                {
                    CanvasGridOverlay.drawGrid();
                }
            }
        }

        public static function getNearZoomIndex(nowZoom:Number):int
        {
            var index:int = Utils.binarySearchIndex(canvasZoomMultiplierList, nowZoom, function (item:*):Number
                {
                    return item;
                });
            if (index <= 0)
                return 0;
            else if (index >= canvasZoomMultiplierList.length - 1)
                return canvasZoomMultiplierList.length - 1;
            else if (canvasZoomMultiplierList[index + 1] - nowZoom < nowZoom - canvasZoomMultiplierList[index - 1])
            {
                return index + 1;
            }
            return index;
        }

        // 캔버스의 중심좌표를 구함 컨트롤 박스 옵션 박스 포함
        public static function getCanvasPanelMidPos():Point
        {
            const boundRect:Object = Utils.getBoundRect(DrawCanvas.canvasLayer1Bitmap);
            const left:Number = boundRect.left;
            const top:Number = boundRect.top;
            const right:Number = boundRect.right;
            const bottom:Number = boundRect.bottom;
            const visualWidth:Number = right - left; // 회전해있어도 상관없음
            const visualHeight:Number = bottom - top; // 양끝 모서리들의 직선거리를 구함
            const visualMidX:Number = Math.round((left + right) / 2); // 회전한 캔버스의 중심점을 구함
            const visualMidY:Number = Math.round((top + bottom) / 2); // floor안하면 1픽셀씩 내려감 0.5를 아래 setRegPoint 함수 에서 반올림 해줘서 그럼
            const p:Point = new Point(visualMidX, visualMidY);
            return p;
        }

        public static function mirrorCanvas(canvasOnly:Boolean = false):void
        {
            // canvaspanel로 하면 중점이 안맞아서 canvas1로함
            const p:Point = getCanvasPanelMidPos();
            DrawCanvas.mirrorON = !DrawCanvas.mirrorON;
            ReplayState.mirrorCommandReady = !ReplayState.mirrorCommandReady;
            DrawCanvas.mirrorBmpdDrawmode();
            UIController.canvasInfoBox.setMirror(DrawCanvas.mirrorON);
            // 회전각 부호를 바꿔야 제대로 mirror가됨
            moveCanvasAnchorPoint(p.x, p.y); // regpoint를 회전한 캔버스 중점으로 두고
            if (canvasOnly === false) // 보통 미러할때, canvasonly가 true일때는 appdata에서 바꿔줄때 밖에 없음
            {
                canvasAnchorPoint.rotation = -canvasAnchorPoint.rotation; // 반대각으로 세팅
                ReplayDrawer.setRcursorRotation(canvasAnchorPoint.rotation);
                ReferenceLayerController.mirrorRefLayerImage();
            }
            CanvasGridOverlay.updateGridMirror(DrawCanvas.mirrorON);
            const halfCanvas:Number = (main.stage.stageWidth - SidebarController.sideBar.getWidth()) / 2;
            var stageHalf:Number = (SidebarController.sideBar.visible === false) ? main.stage.stageWidth / 2
                : (SidebarController.isRightSidebar) ? halfCanvas
                : UIController.STAGE_LEFT_OFFSET + halfCanvas;
            // 창 절반을 기준점으로 앵커포인트 x축 이동.
            canvasAnchorPoint.x += Math.round((stageHalf - p.x) * 2);
            CanvasNavigator.updateCursor();
            FileManager.isFileAlreadySaved = false; // 미러도 화면이 바뀌기 때문에 세이브 플래그 꺼줌
            ReplayDrawer.mirrorRCursorPos();

            CanvasNavigator.box.updateImage();
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
            }
        }

        public static function moveCanvasAnchorPoint(tx:Number, ty:Number, replayMode:Boolean = false):void
        {
            tx = Math.round(tx);
            ty = Math.round(ty);
            var xAnc:Sprite;
            var xCanvas:Sprite;
            var xZoomed:Number;
            if (replayMode)
            {
                xAnc = ReplayDrawer.rCanvasAnchorPoint;
                xCanvas = ReplayDrawer.rCanvasPanel;
                xZoomed = ReplayState.rCanvasZoomMultiplier;
            }
            else
            {
                xAnc = canvasAnchorPoint;
                xCanvas = canvasPanel;
                xZoomed = canvasZoomMultiplier;
            }
            if (xAnc.x === tx && xAnc.y === ty)
            {
                return;
            }
            // round하면 정확도가 약간 줄어드는데, 안하면 그릴때 픽셀 어긋남
            // 캔버스 회전됐을때 점 위치를 구해줌
            // zoom된값을 나눠줘야 제대로된 이동거리가 나옴
            const rotateToolMoveEvent:Point = Utils.rotatePoint((xAnc.x - tx) / xZoomed,
                    (xAnc.y - ty) / xZoomed,
                    xAnc.rotation);
            xAnc.x = tx;
            xAnc.y = ty;
            xCanvas.x += Math.round(rotateToolMoveEvent.x); // 이동한 만큼 거꾸로 움직여줌
            xCanvas.y += Math.round(rotateToolMoveEvent.y); // rotate값 포함해서 움직여야함
        }

        public static function init():void
        {
            var g:Graphics;
            canvasPanel.name = "canvasPanel";
            canvasAnchorPoint.name = "canvasAnchorPoint";
            DrawCanvas.canvasLayer1Bitmap.name = "canvasLayer1Bitmap";
            DrawCanvas.canvasLayer2Bitmap.name = "canvasLayer2Bitmap";
            StrokeBuffer.canvasDrawLayer.name = "canvasDrawLayer";
            StrokeBuffer.canvasDrawLayerChild.name = "canvasDrawShape";
            UIController.stageBG.name = "stageBG";
            ReferenceLayerController.canvasRefLayer.name = "canvasRefLayer";
            CanvasGridOverlay.canvasGrid.name = "canvasGrid";
            canvasFlashEffect.name = "canvasFlash";
            LassoTool.lassoLayer1.name = "lassoBox1";
            LassoTool.lassoLayer1.addChild(LassoTool.lassoLayer1Bitmap);
            LassoTool.lassoLayer1.addChild(LassoTool.lassoDraw);
            LassoTool.lassoLayer1.addChild(LassoTool.lassoDrawCloseLine);
            LassoTool.lassoLayer1.visible = false;
            LassoTool.lassoLayer2.name = "lassoBox2";
            LassoTool.lassoLayer2.addChild(LassoTool.lassoLayer2Bitmap);
            LassoTool.lassoLayer2.visible = false;
            // setCanvasBGColorDrawMode는 같은 색이면 바로 리턴하므로, 초기값(흰색)은 스크래치 패드에 전달되지 않아
            // 최초 실행시 패드 배경이 안 그려졌음. 초기 색은 직접 전달함
            ColorPickerController.colorPickerBox.scratchPad.updateBGColor(DrawCanvas.CANVAS_BG_COLOR);
            updateCanvasPanelMask(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT);
            ReferenceLayerController.canvasRefLayer.alpha = ReferenceLayerController.refLayerLastAlpha;
            ReferenceLayerController.canvasRefLayer.addChild(ReferenceLayerController.canvasRefLayerBitmap);
            StrokeBuffer.canvasDrawLayer.addChild(StrokeBuffer.canvasDrawLayerBitmap);
            StrokeBuffer.canvasDrawLayer.addChild(StrokeBuffer.canvasDrawLayerChild);
            StrokeBuffer.canvasDrawLayer.blendMode = "layer"; // 캔버스1이랑 알파 불투명도가 겹치지 않게 layer모드로 해줌
            ReplayDrawer.rReplayFOFOCursor.visible = false;
            canvasPanel.addChild(ReferenceLayerController.canvasRefLayer);
            canvasPanel.addChild(DrawCanvas.canvasLayer2Bitmap);
            canvasPanel.addChild(LassoTool.lassoLayer2);
            canvasPanel.addChild(DrawCanvas.canvasLayer1Bitmap);
            canvasPanel.addChild(LassoTool.lassoLayer1);
            canvasPanel.addChild(StrokeBuffer.canvasDrawLayer);
            canvasPanel.addChild(CanvasGridOverlay.canvasGrid);
            canvasPanel.addChild(ReplayDrawer.rReplayFOFOCursor);
            // canvasrotate가 중점으로 올수있게 위치를 절반으로세팅
            canvasPanel.x = Math.floor(-canvasPanel.width / 2);
            canvasPanel.y = Math.floor(-canvasPanel.height / 2);
            canvasAnchorPoint.addChild(canvasPanel);
            main.stage.addChild(UIController.stageBG);
            main.stage.addChild(EyeDropperTool.eyedropperLens);
            main.stage.addChild(LassoTool._lassoMenuBox);
            main.stage.addChild(canvasAnchorPoint);
            main.stage.addChild(PenSizePreviewCursor.getCursorShape());
            main.stage.setChildIndex(canvasAnchorPoint, 0);
            main.stage.setChildIndex(UIController.stageBG, 0);
        }

        public static function updateCanvasScale(zoomValue:Number, isReplayMode:Boolean = false):void
        {
            if (!zoomValue)
                zoomValue = 1.0;
            if (zoomValue < 0.0)
                zoomValue = Math.abs(zoomValue);
            var xAnc:Sprite;
            if (!isReplayMode)
            {
                xAnc = canvasAnchorPoint;
                canvasZoomMultiplier = zoomValue;
                if (!CaptureController.isCaptureModeON)
                {
                    PenSizePreviewCursor.updateZoom(zoomValue);
                }
                if (LassoTool.isStarted)
                {
                    LassoTool.redrawLassoOutline();
                }
            }
            else
            {
                ReplayState.rCanvasZoomMultiplier = zoomValue;
                xAnc = ReplayDrawer.rCanvasAnchorPoint;
                if (ReplayState.rAirBrushSize > 0)
                {
                    ReplayDrawer.blurReplayCanvasByValue(ReplayState.rAirBrushSize);
                }
            }
            xAnc.scaleX = zoomValue;
            xAnc.scaleY = zoomValue;
            if (CaptureController.isCaptureModeON && CaptureController.isCaptureCanvasFlipped)
            {
                xAnc.scaleX = -xAnc.scaleX;
            }
            if (!CaptureController.isCaptureModeON)
            {
                UIController.canvasInfoBox.setZoom(zoomValue);
            }
            ReplayDrawer.updateReplayCursorScale(zoomValue);
        }

        // check box position함수는 요소 전체가 창에서 넘어가만 않게 하는거고
        public static function keepCanvasPanelInStage(replayMode:Boolean = false):void
        {
            var xAnc:Sprite;
            var xCanvas:Bitmap;
            if (replayMode)
            {
                xAnc = ReplayDrawer.rCanvasAnchorPoint;
                xCanvas = ReplayDrawer.rCanvasLayer1Bitmap;
            }
            else
            {
                xAnc = canvasAnchorPoint;
                xCanvas = DrawCanvas.canvasLayer1Bitmap;
            }
            const offset:int = 100; // 최소 100픽셀 은 보여야함
            const bounds:Object = Utils.getBoundRect(xCanvas);
            const leftLimit:Number = UIController.STAGE_LEFT_OFFSET + offset;
            const rightLimit:Number = main.stage.stageWidth - (UIController.STAGE_RIGHT_OFFSET + offset);
            const topLimit:Number = UIController.STAGE_TOP_OFFSET + offset;
            const bottomLimit:Number = main.stage.stageHeight - (UIController.STAGE_BOTTOM_OFFSET + offset);
            // getbound는 보이는 그대로 사각형 끝점 좌표를 반환함
            const left:Number = bounds.left;
            const top:Number = bounds.top;
            const right:Number = bounds.right;
            const bottom:Number = bounds.bottom;
            // 꼭지점이 경계offset을 넘어가면 넘어간 거리만큼 regpoint를 반대로 움직여줌
            if (left > rightLimit)
                xAnc.x -= left - rightLimit;
            else if (right < leftLimit)
                xAnc.x += leftLimit - right;
            if (bottom < topLimit)
                xAnc.y += topLimit - bottom;
            else if (top > bottomLimit)
                xAnc.y -= top - bottomLimit;
        }

        // 캔버스 정 가운데로
        public static function centerCanvas(mode:String):void
        {
            var xAnc:Sprite;
            var xCanvas:Sprite;
            var w:Number;
            var h:Number;
            var center:Point = UIController.getStageCenterPos(mode);
            // mode "capture"는 중심 좌표 계산용이고 대상 캔버스는 현재 모드(리플레이/드로우)를 따라감
            if (mode === "replay" || (mode === "capture" && ReplayState.isReplayModeON))
            {
                xAnc = ReplayDrawer.rCanvasAnchorPoint;
                xCanvas = ReplayDrawer.rCanvasPanel;
                w = ReplayState.RCANVAS_WIDTH;
                h = ReplayState.RCANVAS_HEIGHT;
            }
            else
            {
                xAnc = canvasAnchorPoint;
                xCanvas = canvasPanel;
                w = DrawCanvas.CANVAS_WIDTH;
                h = DrawCanvas.CANVAS_HEIGHT;
            }
            xAnc.x = Math.floor(center.x);
            xAnc.y = Math.floor(center.y);
            xCanvas.x = Math.floor(-w / 2);
            xCanvas.y = Math.floor(-h / 2);
        }

        public static function fitCanvasToViewportMargin(fitting:Boolean = false):void
        {
            if (!ReplayState.isReplayModeON && !CaptureController.isCaptureModeON)
            {
                return;
            }
            const uiscale:Number = UITheme.getUIScale();
            const offsetX:Number = 44 + UIController.STAGE_LEFT_OFFSET + UIController.STAGE_RIGHT_OFFSET;
            const offsetY:Number = (CaptureController.isCaptureModeON) ? (UIController.topBar.BARSIZE) * uiscale + 42 * uiscale : (UIController.topBar.BARSIZE) * uiscale + 42 * uiscale;
            const stw:int = main.stage.stageWidth - offsetX;
            const sth:int = main.stage.stageHeight - offsetY - UIController.STAGE_BOTTOM_OFFSET;
            var xBitmap1:Bitmap;
            var xBitmap11:Bitmap;
            var xAnc:Sprite;
            var canvasWidth:Number;
            var canvasHeight:Number;
            if (ReplayState.isReplayModeON)
            {
                xBitmap1 = ReplayDrawer.rCanvasLayer1Bitmap;
                xBitmap11 = ReplayDrawer.rCanvasLayer2Bitmap;
                xAnc = ReplayDrawer.rCanvasAnchorPoint;
                if (fitting)
                {
                    xAnc.scaleX = 1.0;
                    xAnc.scaleY = 1.0; // 크기를 원래대로 해놓고 해야 길이 측정이 됨
                    const b:Rectangle = ReplayDrawer.rCanvasLayer1Bitmap.getBounds(main.stage);
                    canvasWidth = b.right - b.left;
                    canvasHeight = b.bottom - b.top;
                }
                else
                {
                    canvasWidth = ReplayState.RCANVAS_WIDTH;
                    canvasHeight = ReplayState.RCANVAS_HEIGHT;
                }
            }
            else
            {
                xBitmap1 = DrawCanvas.canvasLayer1Bitmap;
                xBitmap11 = DrawCanvas.canvasLayer2Bitmap;
                xAnc = canvasAnchorPoint;
                canvasWidth = DrawCanvas.CANVAS_WIDTH;
                canvasHeight = DrawCanvas.CANVAS_HEIGHT;
            }
            if (CaptureController.isCaptureModeON)
            {
                if (CaptureController.captureCanvasRotationStep === 1 || CaptureController.captureCanvasRotationStep === 3)
                {
                    const widthSave:Number = canvasWidth;
                    canvasWidth = canvasHeight;
                    canvasHeight = widthSave;
                }
            }
            const scaleW:Number = stw / canvasWidth;
            const scaleH:Number = sth / canvasHeight;
            var scale:Number = Math.min(scaleW, scaleH);
            if (!fitting && scale > 1.0)
            {
                scale = 1.0;
            }
            if (CaptureController.isCaptureModeON)
            {
                xAnc.rotation = 90 * CaptureController.captureCanvasRotationStep;
            }
            if (ReplayState.isReplayModeON && !ReplayState.isReplayCanvasFitToWindow)
            {
                ReplayState.isReplayFinishedWithFiwWindow = true;
            }
            if (CaptureController.isCaptureModeON)
            {
                updateCanvasScale(scale, ReplayState.isReplayModeON);
                centerCanvas("capture");
            }
            else if (ReplayState.isReplayModeON)
            {
                updateCanvasScale(scale, ReplayState.isReplayModeON);
                centerCanvas("replay");
            }
            if (!fitting || ReplayState.isReplayFinished)
            {
                xBitmap1.smoothing = true;
                xBitmap11.smoothing = true;
            }
        }

        public static function updateCanvasPanelColorAndSize():void
        {
            canvasPanel.graphics.clear();
            canvasPanel.graphics.beginFill(DrawCanvas.CANVAS_BG_COLOR);
            canvasPanel.graphics.drawRect(0, 0, DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT);
            canvasPanel.graphics.endFill();

            keepCanvasPanelInStage();
            CanvasNavigator.box.changeprevBitmapBGColor(DrawCanvas.CANVAS_BG_COLOR);
            UIController.canvasInfoBox.setSize(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT);

            if (CanvasGridOverlay.gridGapMultiplier > 0)
            {
                CanvasGridOverlay.drawGrid();
            }
        }
    }
}
