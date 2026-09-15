package Modules.Tools
{
    import Modules.ReplayController;
    import Modules.UndoManager;
    import flash.filters.BlurFilter;
    import flash.geom.ColorTransform;
    import Modules.CanvasController;
    import Modules.ToolController;

    public class DrawingFinish
    {
        private static var drawLayerAlpha:ColorTransform = new ColorTransform();

        public static function finish():void
        {
            if (UndoManager.canAddUndoData === false)
            {
                ReplayController.rDataBuffer = [];
                CanvasController.canvasDrawLayerChild.graphics.clear();
                return;
            }

            if (UndoManager.isDeepUndoEnabled)
            {
                var rDataBufferSave:Array = ReplayController.rDataBuffer.concat();
                UndoManager.applyDeepUndo();
                ReplayController.rDataBuffer = rDataBufferSave;
                rDataBufferSave = null;
            }

            UndoManager.canAddUndoData = false;

            if (PenTool.airBrushSizeDrawMode > 0)
            {
                const blurSize:Number = CanvasController.getBlurSize(PenTool.airBrushSizeDrawMode, 1.0);
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

                if (CanvasController.isLayer2Selected)
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

                if (CanvasController.isLayer2Selected)
                {
                    CanvasController.canvasLayer2BitmapData.draw(CanvasController.canvasDrawLayerBitmap, null, drawLayerAlpha, "erase", CanvasController.canvasDrawLayerClipRect);
                }
                else
                {
                    CanvasController.canvasLayer1BitmapData.draw(CanvasController.canvasDrawLayerBitmap, null, drawLayerAlpha, "erase", CanvasController.canvasDrawLayerClipRect);
                }
            }

            ReplayController.rDataBuffer.push(["drawDone5", CanvasController.isLayer2Selected]);

            if (CanvasController.isLayer2Selected)
            {
                CanvasController.canvasLayer2Bitmap.bitmapData = CanvasController.canvasLayer2BitmapData;
            }
            else
            {
                CanvasController.canvasLayer1Bitmap.bitmapData = CanvasController.canvasLayer1BitmapData;
            }

            CanvasController.canvasDrawLayerBitmapData.fillRect(CanvasController.canvasDrawLayerClipRect, 0); // 그려준 영역만
            CanvasController.canvasDrawLayerChild.graphics.clear();

            UndoManager.addUndoData.addNew();
        }
    }
}
