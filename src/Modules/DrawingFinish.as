package Modules
{
    import Modules.DrawEngine.CanvasLayers;
    import Modules.CanvasController;
    import Modules.ToolController;
    import Modules.Tools.PenTool;
    import Modules.UndoController;

    import flash.filters.BlurFilter;
    import flash.geom.ColorTransform;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayState;

    public class DrawingFinish
    {
        private static var drawLayerAlpha:ColorTransform = new ColorTransform();

        public static function run():void
        {
            if (UndoHistory.canAddUndoData === false)
            {
                ReplayState.clearCommandBuffer();
                CanvasController.canvasDrawLayerChild.graphics.clear();
                return;
            }

            if (UndoController.isDeepUndoEnabled)
            {
                var rDataBufferSave:Array = ReplayState.rMemoryDataBuffer.concat();
                UndoController.applyDeepUndo();
                ReplayState.rMemoryDataBuffer = rDataBufferSave;
                rDataBufferSave = null;
            }

            UndoHistory.canAddUndoData = false;

            if (PenTool.airBrushSizeDrawMode > 0)
            {
                const blurSize:Number = PenTool.getBlurSize(PenTool.airBrushSizeDrawMode, 1.0);
                CanvasController.canvasDrawLayerChild.filters = [new BlurFilter(blurSize, blurSize, 3)];
                CanvasController.canvasDrawLayerBitmapData.draw(CanvasController.canvasDrawLayerChild);
                CanvasController.canvasDrawLayerChild.filters = [];
            }
            else
            {
                CanvasController.canvasDrawLayerBitmapData.draw(CanvasController.canvasDrawLayerChild);
            }

            CanvasController.canvasDrawLayerBitmap.bitmapData = CanvasController.canvasDrawLayerBitmapData;

            CanvasController.updateCanvasDrawLayerCliprect();
            CanvasController.extandCanvasDrawLayerCliprect(); // 그린 영역을 100% 다 포함하지 않아서 약간 늘려줌

            if (ToolController.isSelectedToolPenOrLine() || ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
            {
                drawLayerAlpha.alphaMultiplier = PenTool.penAlpha;

                if (CanvasLayers.isLayer2Selected)
                {
                    CanvasController.canvasLayer2BitmapData.draw(CanvasController.canvasDrawLayerBitmap, null, drawLayerAlpha, (PenTool.isTransparentPenColor) ? "erase" : null, CanvasController.canvasDrawLayerClipRect);
                }
                else
                {
                    CanvasController.canvasLayer1BitmapData.draw(CanvasController.canvasDrawLayerBitmap, null, drawLayerAlpha, (PenTool.isTransparentPenColor) ? "erase" : null, CanvasController.canvasDrawLayerClipRect);
                }
            }
            else if (ToolController.isSelectedTool(ToolController.TOOL_ERASER))
            {
                drawLayerAlpha.alphaMultiplier = PenTool.eraserAlpha;

                if (CanvasLayers.isLayer2Selected)
                {
                    CanvasController.canvasLayer2BitmapData.draw(CanvasController.canvasDrawLayerBitmap, null, drawLayerAlpha, "erase", CanvasController.canvasDrawLayerClipRect);
                }
                else
                {
                    CanvasController.canvasLayer1BitmapData.draw(CanvasController.canvasDrawLayerBitmap, null, drawLayerAlpha, "erase", CanvasController.canvasDrawLayerClipRect);
                }
            }

            ReplayState.pushCommand(["drawDone5", CanvasLayers.isLayer2Selected]);

            if (CanvasLayers.isLayer2Selected)
            {
                CanvasController.canvasLayer2Bitmap.bitmapData = CanvasController.canvasLayer2BitmapData;
            }
            else
            {
                CanvasController.canvasLayer1Bitmap.bitmapData = CanvasController.canvasLayer1BitmapData;
            }

            CanvasController.canvasDrawLayerBitmapData.fillRect(CanvasController.canvasDrawLayerClipRect, 0); // 그려준 영역만
            CanvasController.canvasDrawLayerChild.graphics.clear();

            UndoHistory.addNew();
        }
    }
}
