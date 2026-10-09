package Modules.DrawEngine
{
    import Modules.ColorPickerController;
    import Modules.FileManager;
    import Modules.ImageViewWindow;
    import Modules.ReferenceLayerController;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayDrawCommands;
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.ReplayEngine.ReplayState;
    import Modules.UIEngine.CanvasNavigator;
    import Modules.UIEngine.HintController;
    import Modules.Utils;

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.geom.ColorTransform;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    // 드로우 모드 캔버스 데이터: 크기, 배경색, 레이어 1/2 비트맵, 미러 상태와 픽셀 처리
    // 층: L2 엔진 - 드로우 모드 캔버스 데이터 (크기, 배경색, 레이어 비트맵, 미러)
    public class DrawCanvas
    {
        public static const CANVAS_MAX_SIZE:Number = 2000;
        public static var CANVAS_WIDTH:Number = 600;
        public static var CANVAS_HEIGHT:Number = 390;
        public static var CANVAS_BG_COLOR:uint = 0xFFFFFF;
        public static var canvasLayer1BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH, CANVAS_HEIGHT, true, 0);
        public static var canvasLayer2BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH, CANVAS_HEIGHT, true, 0);
        public static var canvasLayer1Bitmap:Bitmap = new Bitmap(canvasLayer1BitmapData, "auto", false);
        public static var canvasLayer2Bitmap:Bitmap = new Bitmap(canvasLayer2BitmapData, "auto", false);
        public static var mirrorON:Boolean = false;
        private static const copyPixelRect:Rectangle = new Rectangle();

        public static function updateLayer1BitmapData(newbmpd:BitmapData):void
        {
            canvasLayer1BitmapData = newbmpd.clone();
            canvasLayer1Bitmap.bitmapData = canvasLayer1BitmapData;
        }

        public static function updateBitmapData(targetbmpd:BitmapData, newbmpd:BitmapData, targetBitmap:Bitmap):BitmapData
        {
            if (targetbmpd !== null && targetbmpd === newbmpd)
            {
                return targetbmpd;
            }
            const clone:BitmapData = newbmpd.clone();
            // currentbmpd distpos를 해주고 싶지만 뭔가 이미지 적용이 안되는 현상이 있어서 안해줌
            if (targetBitmap !== null)
            {
                targetBitmap.bitmapData = clone;
            }
            return clone;
        }

        // maxOutputEdge > 0이면 긴 축이 그 값 이하가 되도록 처음부터 작게 합성함 (대표색 추출처럼 큰 이미지가 필요 없을때)
        public static function getMergedBitmapData(transparentBG:Boolean, layer1merge:Boolean, layer2merge:Boolean, clipRect:Rectangle, maxOutputEdge:Number = 0):BitmapData
        {
            var xBitmapData1:BitmapData;
            var xBitmapData11:BitmapData;
            var xDrawLayer:Sprite;
            var xBGCOLOR:uint;
            var alpha:Number;
            var mat:Matrix;
            var bmpd:BitmapData;
            if (ReplayState.isReplayModeON)
            {
                xBitmapData1 = ReplayDrawer.rCanvasLayer1BitmapData;
                xBitmapData11 = ReplayDrawer.rCanvasLayer2BitmapData;
                xDrawLayer = ReplayDrawer.rCanvasDrawLayer;
                xBGCOLOR = ReplayState.RCANVAS_BG_COLOR;
                alpha = ReplayDrawCommands.getLineStyleAlpha();
            }
            else
            {
                xBitmapData1 = canvasLayer1BitmapData;
                xBitmapData11 = canvasLayer2BitmapData;
                xDrawLayer = StrokeBuffer.canvasDrawLayer;
                xBGCOLOR = CANVAS_BG_COLOR;
                alpha = 1.0;
            }
            const sourceWidth:Number = (clipRect !== null) ? clipRect.width : xBitmapData1.width;
            const sourceHeight:Number = (clipRect !== null) ? clipRect.height : xBitmapData1.height;
            const longEdge:Number = (sourceWidth > sourceHeight) ? sourceWidth : sourceHeight;
            const scale:Number = (maxOutputEdge > 0 && longEdge > maxOutputEdge) ? maxOutputEdge / longEdge : 1.0;
            if (scale !== 1.0)
            {
                // 축소할때 최소길이 1 유지
                bmpd = new BitmapData(Math.max(1, Math.floor(sourceWidth * scale)), Math.max(1, Math.floor(sourceHeight * scale)), true, (transparentBG) ? 0 : 0xFF000000 | xBGCOLOR);
                mat = new Matrix();
                if (clipRect !== null)
                {
                    mat.translate(-clipRect.x, -clipRect.y);
                }
                mat.scale(scale, scale);
            }
            else if (clipRect !== null)
            {
                bmpd = new BitmapData(clipRect.width, clipRect.height, true, (transparentBG) ? 0 : 0xFF000000 | xBGCOLOR);
                mat = new Matrix();
                mat.translate(-clipRect.x, -clipRect.y);
            }
            else
            {
                bmpd = new BitmapData(xBitmapData1.width, xBitmapData1.height, true, (transparentBG) ? 0 : 0xFF000000 | xBGCOLOR);
            }
            if (layer2merge)
            {
                bmpd.draw(xBitmapData11, mat); // 레이어 쌓기
            }
            const isLayer2Drawing:Boolean = (ReplayState.isReplayModeON) ? ReplayDrawer.isLayer2SelectedReplayMode() : CanvasLayers.isLayer2Selected;
            if (isLayer2Drawing) // 레이어 2번을 그리고 있을때
            {
                if (layer2merge)
                    bmpd.draw(xDrawLayer, mat, new ColorTransform(1, 1, 1, alpha));
                if (layer1merge)
                    bmpd.draw(xBitmapData1, mat);
            }
            else // 리플레이에서 레이어 1번그리고 있을때
            {
                if (layer1merge)
                {
                    bmpd.draw(xBitmapData1, mat);
                    bmpd.draw(xDrawLayer, mat, new ColorTransform(1, 1, 1, alpha));
                }
            }
            return bmpd;
        }

        public static function mirrorBmpdDrawmode():void
        {
            var tmpbmpd:BitmapData = new BitmapData(canvasLayer1BitmapData.width, canvasLayer1BitmapData.height, true, 0);
            var flipMat:Matrix = new Matrix(-1, 0, 0, 1, canvasLayer1BitmapData.width);
            tmpbmpd.draw(canvasLayer1BitmapData, flipMat);
            copyPixels(canvasLayer1BitmapData, tmpbmpd);
            tmpbmpd.fillRect(new Rectangle(0, 0, canvasLayer1BitmapData.width, canvasLayer1BitmapData.height), 0);
            tmpbmpd.draw(canvasLayer2BitmapData, flipMat);
            copyPixels(canvasLayer2BitmapData, tmpbmpd);
            tmpbmpd.dispose();
            tmpbmpd = null;
        }

        public static function applyCanvasSizeDrawMode(w:Number, h:Number, moveX:Number = 0, moveY:Number = 0, centerMovedFlag:Boolean = false):void
        {
            setCanvasSizeDrawMode(w, h, moveX, moveY, centerMovedFlag);
            CanvasView.updateCanvasPanelColorAndSize();
        }

        public static function syncDrawModeCanvasSizeToReplayMode(w:Number, h:Number):void
        {
            if (CANVAS_WIDTH === w && CANVAS_HEIGHT === h)
            {
                return;
            }

            CanvasView.updateCanvasPanelMask(w, h);

            // 실제 레이어는 이미 리플레이 결과로 교체되었으므로
            // 임시 그리기 버퍼만 새 크기로 준비.
            const oldDrawBitmapData:BitmapData = StrokeBuffer.canvasDrawLayerBitmapData;

            StrokeBuffer.canvasDrawLayerBitmapData = new BitmapData(w, h, true, 0);
            StrokeBuffer.canvasDrawLayerBitmap.bitmapData = StrokeBuffer.canvasDrawLayerBitmapData;

            if (oldDrawBitmapData !== null)
            {
                oldDrawBitmapData.dispose();
            }

            // 이 함수는 이전 CANVAS_WIDTH/HEIGHT와 새 크기의 차이를 사용.
            // 따라서 크기 변수 갱신보다 먼저 호출해야 함.
            ReferenceLayerController.updateRefLayerImagePos(w, h, false);

            CANVAS_WIDTH = w;
            CANVAS_HEIGHT = h;
        }

        public static function setCanvasSizeDrawMode(w:Number, h:Number, moveX:Number = 0, moveY:Number = 0, centerMovedFlag:Boolean = false):void
        {
            if (CANVAS_WIDTH === w && CANVAS_HEIGHT === h)
            {
                return;
            }

            const maxSize:uint = CANVAS_MAX_SIZE;

            if (w > maxSize)
            {
                w = maxSize;
            }
            else if (w < 1)
            {
                w = 1;
            }

            if (h > maxSize)
            {
                h = maxSize;
            }
            else if (h < 1)
            {
                h = 1;
            }

            CanvasView.updateCanvasPanelMask(w, h);
            canvasLayer1BitmapData = new BitmapData(w, h, true, 0);
            canvasLayer2BitmapData = new BitmapData(w, h, true, 0);
            StrokeBuffer.canvasDrawLayerBitmapData = new BitmapData(w, h, true, 0);
            if (centerMovedFlag)
            {
                // movex y는 캔버스 사이즈 조절에서 원점이 움직였을경우 그만큼 bitmapdata를 움직여줘야
                // 원래 이미지대로 나옴
                var mat:Matrix = new Matrix();
                const rp:Point = Utils.rotatePoint(moveX, moveY, -CanvasView.canvasAnchorPoint.rotation); // 캔버스가 회전되어있으면 회전된 방향으로 움직여줘야함
                mat.translate(moveX, moveY);
                canvasLayer1BitmapData.draw(canvasLayer1Bitmap, mat);
                canvasLayer2BitmapData.draw(canvasLayer2Bitmap, mat);
                CanvasView.canvasAnchorPoint.x -= Math.round(rp.x * CanvasView.canvasZoomMultiplier);
                CanvasView.canvasAnchorPoint.y -= Math.round(rp.y * CanvasView.canvasZoomMultiplier);
            }
            else
            {
                canvasLayer1BitmapData.draw(canvasLayer1Bitmap);
                canvasLayer2BitmapData.draw(canvasLayer2Bitmap);
            }

            if (canvasLayer1Bitmap.bitmapData)
            {
                canvasLayer1Bitmap.bitmapData.dispose();
            }

            canvasLayer1Bitmap.bitmapData = canvasLayer1BitmapData;

            if (canvasLayer2Bitmap.bitmapData)
            {
                canvasLayer2Bitmap.bitmapData.dispose();
            }

            canvasLayer2Bitmap.bitmapData = canvasLayer2BitmapData;

            // canvas width가 갱신되게 전에 업데이트 해야함
            ReferenceLayerController.updateRefLayerImagePos(w, h, centerMovedFlag);
            CANVAS_WIDTH = w;
            CANVAS_HEIGHT = h;
        }

        public static function clearCanvas():void
        {
            const rect:Rectangle = new Rectangle(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
            if (canvasLayer1BitmapData)
                canvasLayer1BitmapData.fillRect(rect, 0);
            if (canvasLayer2BitmapData)
                canvasLayer2BitmapData.fillRect(rect, 0);
            if (StrokeBuffer.canvasDrawLayerBitmapData)
                StrokeBuffer.canvasDrawLayerBitmapData.fillRect(rect, 0);
        }

        public static function applyCanvasBGColorDrawMode(color:uint):void
        {
            setCanvasBGColorDrawMode(color);
            CanvasView.updateCanvasPanelColorAndSize();
        }

        public static function setCanvasBGColorDrawMode(color:uint):void
        {
            if (color === CANVAS_BG_COLOR)
            {
                return;
            }

            FileManager.isFileAlreadySaved = false;
            CANVAS_BG_COLOR = color;

            if (ColorPickerController.colorPickerBox.scratchPad)
            {
                ColorPickerController.colorPickerBox.scratchPad.updateBGColor(color);
            }
        }

        // 드로우 모드 캔버스 상태를 리플레 캔버스 상태랑 똑같이 만들어줌
        public static function applyReplayCanvasToDrawModeCanvas():void
        {
            canvasLayer1BitmapData = updateBitmapData(canvasLayer1BitmapData, ReplayDrawer.rCanvasLayer1BitmapData, canvasLayer1Bitmap);
            canvasLayer2BitmapData = updateBitmapData(canvasLayer2BitmapData, ReplayDrawer.rCanvasLayer2BitmapData, canvasLayer2Bitmap);
            syncDrawModeCanvasSizeToReplayMode(ReplayDrawer.rCanvasLayer1BitmapData.width, ReplayDrawer.rCanvasLayer1BitmapData.height);
            setCanvasBGColorDrawMode(ReplayState.RCANVAS_BG_COLOR);
            CanvasView.updateCanvasPanelColorAndSize();
            FileManager.isFileAlreadySaved = false;
            ReplayController.preserveDrawMirrorStateAfterReplayCopy();
            CanvasNavigator.box.updateImage();
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
                ImageViewWindow.updateCanvasWindowBitmapSize();
            }
        }

        public static function copyPixels(target:BitmapData, source:BitmapData):void
        {
            if (target.width !== source.width || target.height !== source.height)
            {
                HintController.showMouseHintTemp("DrawCanvas.copyPixels() failed : Not same size", 10.0);
                return;
            }

            copyPixelRect.setTo(0, 0, source.width, source.height);
            target.lock();
            target.copyPixels(source, copyPixelRect, Utils.ZERO_POINT, null, null, false);
            target.unlock();
        }
    }
}
