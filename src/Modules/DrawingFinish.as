package Modules
{
    import Modules.Tools.PenSettings;
    import Modules.DrawEngine.StrokeBuffer;
    import Modules.DrawEngine.DrawCanvas;
    import Modules.DrawEngine.CanvasLayers;
    import Modules.Tools.ToolController;
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
                ReplayState.rMemoryDataBuffer = [];
                StrokeBuffer.canvasDrawLayerChild.graphics.clear();
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

            if (PenSettings.airBrushSizeDrawMode > 0)
            {
                const blurSize:Number = PenTool.getBlurSize(PenSettings.airBrushSizeDrawMode, 1.0);
                StrokeBuffer.canvasDrawLayerChild.filters = [new BlurFilter(blurSize, blurSize, 3)];
                StrokeBuffer.canvasDrawLayerBitmapData.draw(StrokeBuffer.canvasDrawLayerChild);
                StrokeBuffer.canvasDrawLayerChild.filters = [];
            }
            else
            {
                StrokeBuffer.canvasDrawLayerBitmapData.draw(StrokeBuffer.canvasDrawLayerChild);
            }

            StrokeBuffer.canvasDrawLayerBitmap.bitmapData = StrokeBuffer.canvasDrawLayerBitmapData;

            StrokeBuffer.updateCanvasDrawLayerClipRect();
            StrokeBuffer.extendCanvasDrawLayerClipRect(); // 그린 영역을 100% 다 포함하지 않아서 약간 늘려줌

            if (ToolController.isSelectedToolPenOrLine() || ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
            {
                drawLayerAlpha.alphaMultiplier = PenSettings.penAlpha;

                if (CanvasLayers.isLayer2Selected)
                {
                    DrawCanvas.canvasLayer2BitmapData.draw(StrokeBuffer.canvasDrawLayerBitmap, null, drawLayerAlpha, (PenTool.isTransparentPenColor) ? "erase" : null, StrokeBuffer.canvasDrawLayerClipRect);
                }
                else
                {
                    DrawCanvas.canvasLayer1BitmapData.draw(StrokeBuffer.canvasDrawLayerBitmap, null, drawLayerAlpha, (PenTool.isTransparentPenColor) ? "erase" : null, StrokeBuffer.canvasDrawLayerClipRect);
                }
            }
            else if (ToolController.isSelectedTool(ToolController.TOOL_ERASER))
            {
                drawLayerAlpha.alphaMultiplier = PenSettings.eraserAlpha;

                if (CanvasLayers.isLayer2Selected)
                {
                    DrawCanvas.canvasLayer2BitmapData.draw(StrokeBuffer.canvasDrawLayerBitmap, null, drawLayerAlpha, "erase", StrokeBuffer.canvasDrawLayerClipRect);
                }
                else
                {
                    DrawCanvas.canvasLayer1BitmapData.draw(StrokeBuffer.canvasDrawLayerBitmap, null, drawLayerAlpha, "erase", StrokeBuffer.canvasDrawLayerClipRect);
                }
            }

            ReplayState.rMemoryDataBuffer.push(["drawDone5", CanvasLayers.isLayer2Selected]);

            if (CanvasLayers.isLayer2Selected)
            {
                DrawCanvas.canvasLayer2Bitmap.bitmapData = DrawCanvas.canvasLayer2BitmapData;
            }
            else
            {
                DrawCanvas.canvasLayer1Bitmap.bitmapData = DrawCanvas.canvasLayer1BitmapData;
            }

            StrokeBuffer.canvasDrawLayerBitmapData.fillRect(StrokeBuffer.canvasDrawLayerClipRect, 0); // 그려준 영역만
            StrokeBuffer.canvasDrawLayerChild.graphics.clear();

            UndoHistory.addNew();
        }
    }
}
