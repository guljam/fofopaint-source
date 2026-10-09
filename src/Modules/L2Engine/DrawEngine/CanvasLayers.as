package Modules.L2Engine.DrawEngine
{

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.BlendMode;
    import flash.display.Sprite;
    import flash.geom.Rectangle;
    import Modules.L3Feature.Tools.ToolController;
    import Modules.L4UI.Tools.ToolPanel;
    import Modules.L3Feature.UndoController;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.DrawEngine.StrokeBuffer;
    import Modules.L2Engine.LassoLayers;
    import Modules.L2Engine.UndoHistory;
    import Modules.L2Engine.ReplayEngine.ReplayState;

    // 드로우 모드 레이어 1/2: 선택, 잠금(체크), 스왑, 병합
    // 층: L2 엔진 - 드로우 모드 레이어 1/2 선택, 잠금, 스왑, 병합
    public class CanvasLayers
    {
        public static var isLayer2Selected:Boolean = false;
        public static var checkedLayer:int = 0; // 레이어가 체크되면 저장해줌
        public static var isLayerSwapped:Boolean = false; // 1<->2 번호 바뀌는 힌트 써주려고 만듬

        // 지우개 미리보기: 선택된 레이어 비트맵과 canvasDrawLayer를 layer 블렌드 홀더에 묶고 canvasDrawLayer를 ERASE로 그려
        // 그 레이어만 지워진 것처럼 보이게 함 (참조/다른 레이어/배경은 홀더 밖이라 그대로). 획이 진행되는 동안에만 유지함
        private static const eraserToolPreviewHolder:Sprite = new Sprite();
        private static var eraserToolPreviewLayer2:Boolean = false;

        public static function isAllLayerInvisible():Boolean
        {
            if (!DrawCanvas.canvasLayer1Bitmap.visible && !DrawCanvas.canvasLayer2Bitmap.visible)
            {
                HintController.showMouseHintTemp("All layer locked");
                return true;
            }
            return false;
        }

        public static function toggleLayerCheck(layer:int):void
        {
            if(layer === 1)
            {
                checkedLayer = (checkedLayer === 1) ? 0 : 1;
                ToolPanel.updateLayerCheckButtons();
            }
            else if(layer === 2)
            {
                checkedLayer = (checkedLayer === 2) ? 0 : 2;
                ToolPanel.updateLayerCheckButtons();
            }
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

        public static function beginEraserToolPreview(layer2:Boolean):void
        {
            endEraserToolPreview(); // 이전 획이 정상적으로 끝나지 못했어도 복구함

            const panel:Sprite = CanvasView.canvasPanel;
            const layerBitmap:Bitmap = (layer2) ? DrawCanvas.canvasLayer2Bitmap : DrawCanvas.canvasLayer1Bitmap;

            eraserToolPreviewLayer2 = layer2;
            eraserToolPreviewHolder.blendMode = BlendMode.LAYER;
            panel.addChildAt(eraserToolPreviewHolder, panel.getChildIndex(layerBitmap));
            eraserToolPreviewHolder.addChild(layerBitmap);
            eraserToolPreviewHolder.addChild(StrokeBuffer.canvasDrawLayer);
            StrokeBuffer.canvasDrawLayer.blendMode = BlendMode.ERASE;
        }

        // 여러 번 호출해도 안전함. 저장해둔 인덱스 없이 현재 상태 기준으로 원래 순서를 다시 계산함
        public static function endEraserToolPreview():void
        {
            if (eraserToolPreviewHolder.parent === null)
            {
                return;
            }

            const panel:Sprite = CanvasView.canvasPanel;
            const layerBitmap:Bitmap = (eraserToolPreviewLayer2) ? DrawCanvas.canvasLayer2Bitmap : DrawCanvas.canvasLayer1Bitmap;

            panel.addChildAt(layerBitmap, panel.getChildIndex(eraserToolPreviewHolder));
            panel.removeChild(eraserToolPreviewHolder);
            eraserToolPreviewHolder.blendMode = BlendMode.NORMAL;

            StrokeBuffer.canvasDrawLayer.blendMode = BlendMode.LAYER;

            if (eraserToolPreviewLayer2)
            {
                panel.addChildAt(StrokeBuffer.canvasDrawLayer, panel.getChildIndex(DrawCanvas.canvasLayer1Bitmap)); // 레이어 2번 선택 시 layer1 바로 아래
            }
            else
            {
                panel.addChildAt(StrokeBuffer.canvasDrawLayer, panel.getChildIndex(LassoLayers.lassoLayer1) + 1);
            }
        }

        // drawLayer를 레이어 1번 선택 위치(lassoLayer1 바로 위)에 놓음. 현재 위치와 상관없이 항상 같은 자리로 가고, 이미 거기 있으면 아무것도 안 함
        public static function bringCanvasDrawLayerAboveLayer1():void
        {
            endEraserToolPreview();

            const panel:Sprite = CanvasView.canvasPanel;
            const current:int = panel.getChildIndex(StrokeBuffer.canvasDrawLayer);
            const anchor:int = panel.getChildIndex(LassoLayers.lassoLayer1);
            const target:int = (current < anchor) ? anchor : anchor + 1; // setChildIndex는 이동 후의 인덱스를 받음

            if (current !== target)
            {
                panel.setChildIndex(StrokeBuffer.canvasDrawLayer, target);
            }
        }

        // drawLayer를 레이어 2번 선택 위치(layer1Bitmap 바로 아래)에 놓음. 마찬가지로 항상 같은 자리, 멱등
        public static function bringCanvasDrawLayerAboveLayer2():void
        {
            endEraserToolPreview();

            const panel:Sprite = CanvasView.canvasPanel;
            const current:int = panel.getChildIndex(StrokeBuffer.canvasDrawLayer);
            const anchor:int = panel.getChildIndex(DrawCanvas.canvasLayer1Bitmap);
            const target:int = (current < anchor) ? anchor - 1 : anchor;

            if (current !== target)
            {
                panel.setChildIndex(StrokeBuffer.canvasDrawLayer, target);
            }
        }

        // 선택된 레이어(isLayer2Selected)에 맞춰 drawLayer 위치를 한 번에 맞춤. 지우개 임시 홀더도 먼저 풀어줌
        public static function syncDrawLayerOrder():void
        {
            if (isLayer2Selected)
            {
                bringCanvasDrawLayerAboveLayer2();
            }
            else
            {
                bringCanvasDrawLayerAboveLayer1();
            }
        }

        // layer: 1 또는 2. onlyViewFlag가 true면 선택한 레이어만 보이게 함 (solo)
        public static function selectLayer(layer:int, onlyViewFlag:Boolean):void
        {
            isLayer2Selected = (layer === 2);
            DrawCanvas.canvasLayer1Bitmap.visible = !onlyViewFlag || layer === 1;
            DrawCanvas.canvasLayer2Bitmap.visible = !onlyViewFlag || layer === 2;
            ToolPanel.updateLayerSelectButtons(layer, onlyViewFlag);
            syncDrawLayerOrder();
        }
    }
}
