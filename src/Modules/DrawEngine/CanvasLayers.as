package Modules.DrawEngine
{
    import Modules.Tools.ToolPanel;
    import Modules.Tools.ToolController;
    import Modules.UndoController;
    import Modules.UndoHistory;
    import Modules.ReplayEngine.ReplayState;
    import Modules.Tools.LassoTool;
    import Modules.UIEngine.HintController;

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.BlendMode;
    import flash.display.Sprite;
    import flash.geom.Rectangle;

    // 드로우 모드 레이어 1/2: 선택, 잠금(체크), 스왑, 병합
    public class CanvasLayers
    {
        public static var isLayer2Selected:Boolean = false;
        public static var checkedLayer:int = 0; // 레이어가 체크되면 저장해줌
        public static var isLayerSwapped:Boolean = false; // 1<->2 번호 바뀌는 힌트 써주려고 만듬

        public static function isAllLayerInvisible():Boolean
        {
            if (!DrawCanvas.canvasLayer1Bitmap.visible && !DrawCanvas.canvasLayer2Bitmap.visible)
            {
                HintController.showMouseHintTemp("All layer locked");
                return true;
            }
            return false;
        }

        public static function toggleLayer1Check():void
        {
            checkedLayer = (checkedLayer === 1) ? 0 : 1;
            ToolPanel.updateLayerCheckButtons();
        }
        public static function toggleLayer2Check():void
        {
            checkedLayer = (checkedLayer === 2) ? 0 : 2;
            ToolPanel.updateLayerCheckButtons();
        }

        public static function mergeImageIntoLayer2():void
        {
            if (ReplayState.hasLastRMemoryDataCommand("merge"))
            {
                ReplayState.deleteLastRMemoryDataCommand("merge");
            }
            else
            {
                if (UndoController.isDeepUndoEnabled)
                {
                    UndoController.applyDeepUndo();
                }
                DrawCanvas.canvasLayer2BitmapData.draw(DrawCanvas.canvasLayer1BitmapData);
                DrawCanvas.canvasLayer1BitmapData.fillRect(new Rectangle(0, 0, DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT), 0);
                ReplayState.rMemoryDataBuffer.push(["merge"]);
                UndoHistory.addNew();
            }
            ToolPanel.setLayerMergeButtonEnabled(false);
        }

        public static function swapLayer():void
        {
            if (!ToolPanel.isLayerSwapButtonReady())
            {
                return;
            }
            if (UndoController.isDeepUndoEnabled)
            {
                UndoController.applyDeepUndo();
            }
            isLayerSwapped = !isLayerSwapped;
            var tempbmpd1:BitmapData = DrawCanvas.canvasLayer1BitmapData.clone();
            var tempbmpd11:BitmapData = DrawCanvas.canvasLayer2BitmapData.clone();
            const rect:Rectangle = new Rectangle(0, 0, DrawCanvas.canvasLayer1BitmapData.width, DrawCanvas.canvasLayer1BitmapData.height);
            DrawCanvas.canvasLayer1BitmapData.fillRect(rect, 0);
            DrawCanvas.canvasLayer2BitmapData.fillRect(rect, 0);
            DrawCanvas.canvasLayer1BitmapData.draw(tempbmpd11);
            DrawCanvas.canvasLayer2BitmapData.draw(tempbmpd1);
            tempbmpd1.dispose();
            tempbmpd11.dispose();
            tempbmpd1 = null;
            tempbmpd11 = null;
            if (ReplayState.hasLastRMemoryDataCommand("swap"))
            {
                ReplayState.deleteLastRMemoryDataCommand("swap");
            }
            else
            {
                ReplayState.rMemoryDataBuffer.push(["swap"]);
                UndoHistory.addNew();
            }
            ToolPanel.flickLayerSwapButton();
        }

        public static function isToolEnabledByLayerUnChecked():Boolean
        {
            return checkedLayer === 0;
        }

        // 지우개 미리보기: 선택된 레이어 비트맵과 canvasDrawLayer를 layer 블렌드 홀더에 묶고 canvasDrawLayer를 ERASE로 그려
        // 그 레이어만 지워진 것처럼 보이게 함 (참조/다른 레이어/배경은 홀더 밖이라 그대로). 획이 진행되는 동안에만 유지함
        private static const erasePreviewHolder:Sprite = new Sprite();
        private static var erasePreviewLayer2:Boolean = false;

        public static function beginErasePreview(layer2:Boolean):void
        {
            endErasePreview(); // 이전 획이 정상적으로 끝나지 못했어도 복구함

            const panel:Sprite = CanvasView.canvasPanel;
            const layerBitmap:Bitmap = (layer2) ? DrawCanvas.canvasLayer2Bitmap : DrawCanvas.canvasLayer1Bitmap;

            erasePreviewLayer2 = layer2;
            erasePreviewHolder.blendMode = BlendMode.LAYER;
            panel.addChildAt(erasePreviewHolder, panel.getChildIndex(layerBitmap));
            erasePreviewHolder.addChild(layerBitmap);
            erasePreviewHolder.addChild(StrokeBuffer.canvasDrawLayer);
            StrokeBuffer.canvasDrawLayer.blendMode = BlendMode.ERASE;
        }

        // 여러 번 호출해도 안전함. 저장해둔 인덱스 없이 현재 상태 기준으로 원래 순서를 다시 계산함
        public static function endErasePreview():void
        {
            if (erasePreviewHolder.parent === null)
            {
                return;
            }

            const panel:Sprite = CanvasView.canvasPanel;
            const layerBitmap:Bitmap = (erasePreviewLayer2) ? DrawCanvas.canvasLayer2Bitmap : DrawCanvas.canvasLayer1Bitmap;

            panel.addChildAt(layerBitmap, panel.getChildIndex(erasePreviewHolder));
            panel.removeChild(erasePreviewHolder);
            erasePreviewHolder.blendMode = BlendMode.NORMAL;

            StrokeBuffer.canvasDrawLayer.blendMode = BlendMode.LAYER;

            if (erasePreviewLayer2)
            {
                panel.addChildAt(StrokeBuffer.canvasDrawLayer, panel.getChildIndex(DrawCanvas.canvasLayer1Bitmap)); // 레이어 2번 선택 시 layer1 바로 아래
            }
            else
            {
                panel.addChildAt(StrokeBuffer.canvasDrawLayer, panel.getChildIndex(LassoTool.lassoLayer1) + 1);
            }
        }

        public static function bringCanvasDrawLayerAboveLayer1():void
        {
            endErasePreview();

            if (CanvasView.canvasPanel.getChildIndex(StrokeBuffer.canvasDrawLayer) < CanvasView.canvasPanel.getChildIndex(LassoTool.lassoLayer1))
            {
                CanvasView.canvasPanel.setChildIndex(StrokeBuffer.canvasDrawLayer, CanvasView.canvasPanel.getChildIndex(LassoTool.lassoLayer1));
            }
        }
        public static function bringCanvasDrawLayerAboveLayer2():void
        {
            endErasePreview();

            if (CanvasView.canvasPanel.getChildIndex(StrokeBuffer.canvasDrawLayer) > CanvasView.canvasPanel.getChildIndex(DrawCanvas.canvasLayer1Bitmap))
            {
                CanvasView.canvasPanel.setChildIndex(StrokeBuffer.canvasDrawLayer, CanvasView.canvasPanel.getChildIndex(DrawCanvas.canvasLayer1Bitmap));
            }
        }

        public static function selectLayer1(onlyViewFlag:Boolean):void
        {
            isLayer2Selected = false;
            if (onlyViewFlag)
            {
                DrawCanvas.canvasLayer1Bitmap.visible = true;
                DrawCanvas.canvasLayer2Bitmap.visible = false;
            }
            else
            {
                DrawCanvas.canvasLayer1Bitmap.visible = true;
                DrawCanvas.canvasLayer2Bitmap.visible = true;
            }
            ToolPanel.updateLayerSelectButtons(1, onlyViewFlag);
            bringCanvasDrawLayerAboveLayer1();
        }
        public static function selectLayer2(onlyViewFlag:Boolean):void
        {
            isLayer2Selected = true;
            if (onlyViewFlag)
            {
                DrawCanvas.canvasLayer1Bitmap.visible = false;
                DrawCanvas.canvasLayer2Bitmap.visible = true;
            }
            else
            {
                DrawCanvas.canvasLayer1Bitmap.visible = true;
                DrawCanvas.canvasLayer2Bitmap.visible = true;
            }
            ToolPanel.updateLayerSelectButtons(2, onlyViewFlag);
            bringCanvasDrawLayerAboveLayer2();
        }
    }
}
