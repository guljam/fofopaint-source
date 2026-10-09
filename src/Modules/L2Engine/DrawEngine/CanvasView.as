package Modules.L2Engine.DrawEngine
{
    import Modules.ReferenceLayerController;
    import Modules.ReplayEngine.ReplayState;
    import Modules.Tools.ZoomTool;
    import Modules.UIEngine.CanvasNavigator;
    import Modules.Utils;

    import flash.display.DisplayObjectContainer;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import Modules.L4UI.CanvasGridOverlay;
    import Modules.L4UI.ColorPickerController;
    import Modules.L3Feature.Tools.EyeDropperTool;
    import Modules.L5App.FileManager;
    import Modules.L4UI.ImageViewWindow;
    import Modules.L3Feature.Tools.LassoTool;
    import Modules.L4UI.SidebarController;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L4UI.PenSizePreviewCursor;
    import Modules.DrawEngine.DrawViewport;
    import Modules.DrawEngine.StrokeBuffer;

    // 드로우 모드 캔버스의 화면 배치: 앵커/패널 표시 트리, 이동, 줌, 회전/미러 화면 처리
    // 층: L2 엔진 - 드로우 모드 캔버스의 화면 배치 (이동, 줌, 회전·미러)
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
        public static const viewport:DrawViewport = new DrawViewport();

        public static function resetRotationDrawMode():void
        {
            const center:Point = UIController.getStageCenterPos("draw");
            PenSizePreviewCursor.updateSizeAndShape();
            viewport.moveAnchorPoint(center.x, center.y);
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
                viewport.moveAnchorPoint(panelLimitedPos.x + gp.x, panelLimitedPos.y + gp.y);
                canvasZoomIndex = canvasZoomMultiplierList.indexOf(1.0);
                viewport.setScale(1.0);
                PenSizePreviewCursor.updateSizeAndShape();
                CanvasGridOverlay.drawGrid();
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
            viewport.moveAnchorPoint(p.x, p.y); // regpoint를 회전한 캔버스 중점으로 두고
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
            ReferenceLayerController.canvasRefHolder.addChild(ReferenceLayerController.canvasRefLayer);
            canvasPanel.addChild(ReferenceLayerController.canvasRefHolder);
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

        public static function updateCanvasPanelColorAndSize():void
        {
            canvasPanel.graphics.clear();
            canvasPanel.graphics.beginFill(DrawCanvas.CANVAS_BG_COLOR);
            canvasPanel.graphics.drawRect(0, 0, DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT);
            canvasPanel.graphics.endFill();

            viewport.keepInStage();
            CanvasNavigator.box.changeprevBitmapBGColor(DrawCanvas.CANVAS_BG_COLOR);
            UIController.canvasInfoBox.setSize(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT);

            if (CanvasGridOverlay.gridGapMultiplier > 0)
            {
                CanvasGridOverlay.drawGrid();
            }
        }
    }
}
