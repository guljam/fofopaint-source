package Modules.DrawEngine
{
    import Modules.Tools.ToolPanel;
    import Modules.Tools.ToolController;
    import Modules.UndoController;
    import Modules.UndoHistory;
    import Modules.ReplayEngine.ReplayState;
    import Modules.Tools.LassoTool;
    import Modules.UIEngine.HintController;

    import flash.display.BitmapData;
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
                ReplayState.pushCommand(["merge"]);
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
                ReplayState.pushCommand(["swap"]);
                UndoHistory.addNew();
            }
            ToolPanel.flickLayerSwapButton();
        }

        public static function isToolEnabledByLayerUnChecked():Boolean
        {
            return checkedLayer === 0;
        }

        public static function bringCanvasDrawLayerAboveLayer1():void
        {
            if (CanvasView.canvasPanel.getChildIndex(StrokeBuffer.canvasDrawLayer) < CanvasView.canvasPanel.getChildIndex(LassoTool.lassoLayer1))
            {
                CanvasView.canvasPanel.setChildIndex(StrokeBuffer.canvasDrawLayer, CanvasView.canvasPanel.getChildIndex(LassoTool.lassoLayer1));
            }
        }
        public static function bringCanvasDrawLayerAboveLayer2():void
        {
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
