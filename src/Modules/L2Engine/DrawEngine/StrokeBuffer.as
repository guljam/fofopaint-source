package Modules.L2Engine.DrawEngine
{

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.geom.Rectangle;
    import Modules.L1Data.Tools.PenSettings;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L3Feature.Tools.PenTool;

    // 획을 레이어에 합치기 전에 임시로 그리는 버퍼와 갱신 영역(클립 사각형)
    // 층: L2 엔진 - 획을 레이어에 합치기 전의 임시 그리기 버퍼와 갱신 영역
    public class StrokeBuffer
    {
        public static var canvasDrawLayer:Sprite = new Sprite(); // 캔버스 2번 임시로 그려주는 캔버스 버퍼?
        public static var canvasDrawLayerChild:Shape = new Shape(); // 실제로 선을 긋는 요소
        public static var canvasDrawLayerBitmapData:BitmapData = new BitmapData(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, true, 0);
        public static var canvasDrawLayerBitmap:Bitmap = new Bitmap(canvasDrawLayerBitmapData, "auto", false);
        public static var canvasDrawLayerClipRect:Rectangle = new Rectangle(); // 그려준 영역 만큼만 캔버스bitmap1에 그려주는 사각형

        public static function resetCanvasDrawLayerClipRect():void
        {
            canvasDrawLayerClipRect.x = 0;
            canvasDrawLayerClipRect.y = 0;
            canvasDrawLayerClipRect.width = 0;
            canvasDrawLayerClipRect.height = 0;
        }

        public static function extendCanvasDrawLayerClipRect():void
        {
            var airBrushOffset:Number = (PenSettings.airBrushSizeDrawMode > 0) ? PenTool.getClipRectOffsetAirBrush(PenSettings.airBrushSizeDrawMode) : 1;
            canvasDrawLayerClipRect.x -= airBrushOffset;
            canvasDrawLayerClipRect.y -= airBrushOffset;
            canvasDrawLayerClipRect.width += (airBrushOffset * 2);
            canvasDrawLayerClipRect.height += (airBrushOffset * 2);
        }

        public static function updateCanvasDrawLayerClipRect():void
        {
            canvasDrawLayerClipRect = canvasDrawLayerClipRect.union(canvasDrawLayerChild.getBounds(CanvasView.canvasPanel));
        }
    }
}
