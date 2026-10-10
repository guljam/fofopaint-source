package Modules.L3Feature
{

    import flash.filters.BlurFilter;
    import flash.geom.ColorTransform;
    import Modules.L5App.ReplayEngine.ReplayController;
    import Modules.L3Feature.UndoController;
    import Modules.L1Data.Tools.PenSettings;
    import Modules.L1Data.ToolState;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L3Feature.Tools.PenTool;
    import Modules.L2Engine.UndoHistory;
    import Modules.L2Engine.ReplayEngine.ReplayState;
    import Modules.L2Engine.DrawEngine.StrokeBuffer;

    // 층: L3 기능 - 획이 끝났을 때 임시 그리기 버퍼를 레이어에 합치고 undo 기록을 준비
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

            if (UndoHistory.isDeepUndoEnabled)
            {
                var rDataBufferSave:Array = ReplayState.rMemoryDataBuffer.concat();
                UndoController.applyDeepUndo();
                ReplayState.rMemoryDataBuffer = rDataBufferSave;
                rDataBufferSave = null;
            }

            UndoHistory.canAddUndoData = false;

            if (PenSettings.airBrushSizeDrawMode > 0)
            {
                const blurSize:Number = PenSettings.getBlurSize(PenSettings.airBrushSizeDrawMode, 1.0);
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

            if (ToolState.isSelectedToolPenOrLine() || ToolState.isSelectedTool(ToolState.TOOL_FILLPEN))
            {
                drawLayerAlpha.alphaMultiplier = PenSettings.penAlpha;

                if (DrawCanvas.isLayer2Selected)
                {
                    DrawCanvas.canvasLayer2BitmapData.draw(StrokeBuffer.canvasDrawLayerBitmap, null, drawLayerAlpha, (PenTool.isTransparentPenColor) ? "erase" : null, StrokeBuffer.canvasDrawLayerClipRect);
                }
                else
                {
                    DrawCanvas.canvasLayer1BitmapData.draw(StrokeBuffer.canvasDrawLayerBitmap, null, drawLayerAlpha, (PenTool.isTransparentPenColor) ? "erase" : null, StrokeBuffer.canvasDrawLayerClipRect);
                }
            }
            else if (ToolState.isSelectedTool(ToolState.TOOL_ERASER))
            {
                drawLayerAlpha.alphaMultiplier = PenSettings.eraserAlpha;

                if (DrawCanvas.isLayer2Selected)
                {
                    DrawCanvas.canvasLayer2BitmapData.draw(StrokeBuffer.canvasDrawLayerBitmap, null, drawLayerAlpha, "erase", StrokeBuffer.canvasDrawLayerClipRect);
                }
                else
                {
                    DrawCanvas.canvasLayer1BitmapData.draw(StrokeBuffer.canvasDrawLayerBitmap, null, drawLayerAlpha, "erase", StrokeBuffer.canvasDrawLayerClipRect);
                }
            }

            ReplayState.rMemoryDataBuffer.push(["drawDone5", DrawCanvas.isLayer2Selected]);

            if (DrawCanvas.isLayer2Selected)
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
