package Modules.DrawEngine
{
    import Modules.ToolController;
    import Modules.UndoController;
    import Modules.UndoHistory;
    import Modules.ReplayEngine.ReplayState;
    import Modules.Tools.LassoTool;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UITheme;

    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.geom.Rectangle;

    // 드로우 모드 레이어 1/2: 선택, 잠금(체크), 스왑, 병합
    public class CanvasLayers
    {
        public static var isLayer2Selected:Boolean = false;
        public static var checkedLayer:int = 0; // 레이어가 체크되면 저장해줌
        public static var isLayerSwapped:Boolean = false; // 1<->2 번호 바뀌는 힌트 써주려고 만듬

        public static function playLayerSwapEffect(target:DisplayObject):void
        {
            target.alpha = UITheme.OFFALPHA;
            FOFOTimer.addByName("layerSwapFlickEffect", 0.5, false, function ():void
                {
                    target.alpha = 1.0;
                });
        }

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
            if (ToolController.toolOptionsBox.layer1CheckedButton.visible === false)
            {
                checkedLayer = 1;
                ToolController.toolOptionsBox.layer1CheckedButton.visible = true;
                ToolController.toolOptionsBox.layer1UncheckedButton.visible = false;
                ToolController.toolOptionsBox.layer2CheckedButton.visible = false;
                ToolController.toolOptionsBox.layer2UncheckedButton.visible = true;
                ToolController.toolBox.setToolButtonsForCheckedLayerON();
                ToolController.toolBox2.setToolButtonsForCheckedLayerON();
            }
            else
            {
                checkedLayer = 0;
                ToolController.toolOptionsBox.layer1CheckedButton.visible = false;
                ToolController.toolOptionsBox.layer1UncheckedButton.visible = true;
                ToolController.toolBox.setToolButtonsForCheckedLayerOFF();
                ToolController.toolBox2.setToolButtonsForCheckedLayerOFF();
            }
        }
        public static function toggleLayer2Check():void
        {
            if (ToolController.toolOptionsBox.layer2CheckedButton.visible === false)
            {
                checkedLayer = 2;
                ToolController.toolOptionsBox.layer2CheckedButton.visible = true;
                ToolController.toolOptionsBox.layer2UncheckedButton.visible = false;
                ToolController.toolOptionsBox.layer1CheckedButton.visible = false;
                ToolController.toolOptionsBox.layer1UncheckedButton.visible = true;
                ToolController.toolBox.setToolButtonsForCheckedLayerON();
                ToolController.toolBox2.setToolButtonsForCheckedLayerON();
            }
            else
            {
                checkedLayer = 0;
                ToolController.toolOptionsBox.layer2CheckedButton.visible = false;
                ToolController.toolOptionsBox.layer2UncheckedButton.visible = true;
                ToolController.toolBox.setToolButtonsForCheckedLayerOFF();
                ToolController.toolBox2.setToolButtonsForCheckedLayerOFF();
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
                ReplayState.pushCommand(["merge"]);
                UndoHistory.addNew();
            }
            ToolController.toolOptionsBox.layerMergeButton.alpha = UITheme.OFFALPHA;
        }

        public static function swapLayer():void
        {
            if (ToolController.toolOptionsBox.layerSwapButton.alpha < 1.0)
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
            playLayerSwapEffect(ToolController.toolOptionsBox.layerSwapButton);
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
            ToolController.toolOptionsBox.setSelectLayerButtonActiveAlpha(1);
            if (onlyViewFlag)
            {
                DrawCanvas.canvasLayer1Bitmap.visible = true;
                DrawCanvas.canvasLayer2Bitmap.visible = false;
                ToolController.toolOptionsBox.moveLayerInvisibleLineToLayer2();
            }
            else
            {
                DrawCanvas.canvasLayer1Bitmap.visible = true;
                DrawCanvas.canvasLayer2Bitmap.visible = true;
                ToolController.toolOptionsBox.removeLayerInvisibleLine();
            }
            bringCanvasDrawLayerAboveLayer1();
        }
        public static function selectLayer2(onlyViewFlag:Boolean):void
        {
            isLayer2Selected = true;
            ToolController.toolOptionsBox.setSelectLayerButtonActiveAlpha(2);
            if (onlyViewFlag)
            {
                DrawCanvas.canvasLayer1Bitmap.visible = false;
                DrawCanvas.canvasLayer2Bitmap.visible = true;
                ToolController.toolOptionsBox.moveLayerInvisibleLineToLayer1();
            }
            else
            {
                DrawCanvas.canvasLayer1Bitmap.visible = true;
                DrawCanvas.canvasLayer2Bitmap.visible = true;
                ToolController.toolOptionsBox.removeLayerInvisibleLine();
            }
            bringCanvasDrawLayerAboveLayer2();
        }
    }
}
