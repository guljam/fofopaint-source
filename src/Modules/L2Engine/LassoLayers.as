package Modules.L2Engine
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.filters.ConvolutionFilter;
    import flash.geom.Rectangle;
    import flash.geom.Point;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.L2Engine.DrawEngine.StrokeBuffer;

    // 올가미로 고른 이미지를 올려 두는 표시 객체(상자 1, 2)와 그 이미지를 옮기고 바꾸는 함수
    // 드로우 모드의 LassoTool과 리플레이 재생(ReplayDrawCommands)이 함께 씀
    // 층: L2 엔진 - 올가미 이미지 상자 1/2와 이미지 옮기기·바꾸기
    public class LassoLayers
    {
        public static const LASSO_SHARP_DATA:Array = [[[
                        0, -1, 0,
                        -1, 12, -1
                        , 0, -1, 0
                    ], 8],
                [[
                        0, -1, 0,
                        -1, 10, -1
                        , 0, -1, 0
                    ], 6],
                [[
                        0, -1, 0,
                        -1, 7, -1
                        , 0, -1, 0
                    ], 3]];

        public static const lassoDraw:Shape = new Shape(); // 라소 영역 선 그려주는 쉐이프

        public static const lassoDrawCloseLine:Shape = new Shape(); // 라소 영역 증분그리기로 되어서 선 닫아주는 그래픽은 따로 추가해줌

        public static var lassoLayer1:Sprite = new Sprite(); // 선택한 이미지를 그려주고 확대/축소 등 조작

        public static var lassoLayer1Bitmap:Bitmap = new Bitmap();

        public static var lassoLayer2:Sprite = new Sprite(); // lassoLayer2 레이어

        public static var lassoLayer2Bitmap:Bitmap = new Bitmap(); // lassoLayer2의 비트맵

        // 올가미 상자 1, 2의 비트맵 이미지를 서로 바꿈
        public static function swapLassoImage():void
        {
            var tmpbmpd:BitmapData = lassoLayer1Bitmap.bitmapData;
            lassoLayer1Bitmap.bitmapData = lassoLayer2Bitmap.bitmapData;
            lassoLayer2Bitmap.bitmapData = tmpbmpd;
            tmpbmpd = null;
        }

        // 올가미 상자 1의 이미지를 2에 합치고 1을 비움
        public static function mergeLassoImage():void
        {
            var rect:Rectangle = new Rectangle(0, 0, lassoLayer1Bitmap.bitmapData.width, lassoLayer1Bitmap.bitmapData.height);
            lassoLayer2Bitmap.bitmapData.draw(lassoLayer1Bitmap);
            lassoLayer1Bitmap.bitmapData.fillRect(rect, 0);
            rect = null;
        }

        // 배율(scale)에 맞는 선명하게 필터를 올가미 상자 1, 2 비트맵에 적용함
        public static function applyLassoShapen(scale:Number):void
        {
            if (scale === 0.0)
                return;
            var index:uint = Math.abs(Math.floor(scale - 1.0));
            if (index > 2)
                index = 2;
            var sharpen:ConvolutionFilter = new ConvolutionFilter(3, 3, LASSO_SHARP_DATA[index][0], LASSO_SHARP_DATA[index][1]);
            lassoLayer1Bitmap.filters = [sharpen];
            lassoLayer2Bitmap.filters = [sharpen];
        }

        // 선택한 영역(rectArr, points)의 이미지를 올가미 상자 1/2 비트맵으로 옮김 (replayMode이면 리플레이 캔버스, 아니면 드로우 캔버스에서 가져옴)
        public static function moveSelectedAreaToLassoBox(replayMode:Boolean, rectArr:Vector.<Number>, points:Array, copyFlag:Boolean, layer1:Boolean, layer2:Boolean):Boolean
        {
            // 라소 경계 사각형 좌표와 크기
            const rectLeft:Number = rectArr[0];
            const rectTop:Number = rectArr[1];
            const rectWidth:Number = rectArr[2] - rectLeft;
            const rectHeight:Number = rectArr[3] - rectTop;
            const lassoPointsLen:uint = points.length;
            // 가로세로 길이가 0 이하이면 실행하지 않음
            if (Math.floor(rectWidth) <= 0 || Math.floor(rectHeight) <= 0)
                return false;
            var xCanvasDrawLayer:Shape;
            var canvasBitmapData:BitmapData;
            var canvasBitmapDataSub:BitmapData;
            var canvasBitmap:Bitmap;
            var canvasBitmapSub:Bitmap;
            var canvasDrawLayerFilterBackUp:Array = null;
            // 에어브러시 켜줄때 필터 백업함
            if (replayMode)
            {
                canvasDrawLayerFilterBackUp = ReplayDrawer.rCanvasDrawShape.filters.concat();
                ReplayDrawer.rCanvasDrawShape.filters = [];
                xCanvasDrawLayer = ReplayDrawer.rCanvasDrawShape;
                if (layer1)
                {
                    canvasBitmapData = ReplayDrawer.rCanvasLayer1BitmapData;
                    canvasBitmap = ReplayDrawer.rCanvasLayer1Bitmap;
                }
                if (layer2)
                {
                    canvasBitmapDataSub = ReplayDrawer.rCanvasLayer2BitmapData;
                    canvasBitmapSub = ReplayDrawer.rCanvasLayer2Bitmap;
                }
            }
            else
            {
                canvasDrawLayerFilterBackUp = StrokeBuffer.canvasDrawLayerChild.filters.concat();
                StrokeBuffer.canvasDrawLayerChild.filters = [];
                xCanvasDrawLayer = StrokeBuffer.canvasDrawLayerChild;
                if (layer1)
                {
                    canvasBitmapData = DrawCanvas.canvasLayer1BitmapData;
                    canvasBitmap = DrawCanvas.canvasLayer1Bitmap;
                }
                if (layer2)
                {
                    canvasBitmapDataSub = DrawCanvas.canvasLayer2BitmapData;
                    canvasBitmapSub = DrawCanvas.canvasLayer2Bitmap;
                }
            }
            const newRectangle:Rectangle = new Rectangle(rectLeft, rectTop, rectWidth, rectHeight);
            var lassoBmpd1:BitmapData = (layer1) ? new BitmapData(rectWidth, rectHeight, true, 0) : null;
            var lassoBmpd2:BitmapData = (layer2) ? new BitmapData(rectWidth, rectHeight, true, 0) : null;
            var i:uint;
            // 지우기 전에 사각형 모양으로 그려준 부분을 copypixel 함.
            if (layer1)
                lassoBmpd1.copyPixels(canvasBitmapData, newRectangle, new Point(0, 0), null, null, true);
            if (layer2)
                lassoBmpd2.copyPixels(canvasBitmapDataSub, newRectangle, new Point(0, 0), null, null, true);
            lassoLayer1Bitmap.smoothing = true;
            lassoLayer2Bitmap.smoothing = true;
            // bitmap1canvas에서 그려준 영역을 지워줌
            if (!copyFlag)
            {
                xCanvasDrawLayer.graphics.clear();
                xCanvasDrawLayer.graphics.beginFill(DrawCanvas.CANVAS_BG_COLOR);
                xCanvasDrawLayer.graphics.moveTo(points[0][0], points[0][1]);
                // rectLeft를 빼줘서 canvasdraw2의 0,0영역에 그려줌
                for (i = 1;i < lassoPointsLen;i++)
                {
                    xCanvasDrawLayer.graphics.lineTo(points[i][0], points[i][1]);
                }
                xCanvasDrawLayer.graphics.endFill();
                if (layer1)
                {
                    canvasBitmapData.draw(xCanvasDrawLayer, null, null, "erase");
                    canvasBitmap.bitmapData = canvasBitmapData;
                }
                if (layer2)
                {
                    canvasBitmapDataSub.draw(xCanvasDrawLayer, null, null, "erase");
                    canvasBitmapSub.bitmapData = canvasBitmapDataSub;
                }
            }
            // -------------------------
            // clip하기 위해서 그려운 영역의 반전 부분을 0,0영역을 기준으로 그려줌
            // 2번 반복하는게 좀 그런데 다른 방법 모르겠음
            // 가로세로 절반 크기만큼 더해줘서 bmp의 중점으로 이동해주기 때문에 또 그만큼 빼줌
            xCanvasDrawLayer.graphics.clear();
            xCanvasDrawLayer.graphics.beginFill(0x00FF00);
            xCanvasDrawLayer.graphics.drawRect(0, 0, rectWidth, rectHeight);
            xCanvasDrawLayer.graphics.moveTo(points[0][0] - rectLeft, points[0][1] - rectTop);
            // rectLeft를 빼줘서 canvasdraw2의 0,0영역에 그려줌
            for (i = 1;i < lassoPointsLen;i++)
            {
                xCanvasDrawLayer.graphics.lineTo(points[i][0] - rectLeft, points[i][1] - rectTop);
            }
            // 마지막으로 시작점을 이어줌
            xCanvasDrawLayer.graphics.endFill();
            if (layer1)
            {
                lassoLayer1Bitmap.bitmapData = lassoBmpd1;
                lassoLayer1Bitmap.bitmapData.draw(xCanvasDrawLayer, null, null, "erase");
            }
            if (layer2)
            {
                lassoLayer2Bitmap.bitmapData = lassoBmpd2;
                lassoLayer2Bitmap.bitmapData.draw(xCanvasDrawLayer, null, null, "erase");
            }
            xCanvasDrawLayer.graphics.clear(); // 꼭 해줘야함
            // 회전 확대를 bmp사각형의 중심으로 맞추어줌
            if (layer1)
            {
                lassoLayer1Bitmap.x = -rectWidth / 2;
                lassoLayer1Bitmap.y = -rectHeight / 2;
            }
            if (layer2)
            {
                lassoLayer2Bitmap.x = -rectWidth / 2;
                lassoLayer2Bitmap.y = -rectHeight / 2;
            }
            lassoLayer1.x = rectLeft + rectWidth / 2;
            lassoLayer1.y = rectTop + rectHeight / 2;
            lassoLayer2.x = lassoLayer1.x;
            lassoLayer2.y = lassoLayer1.y;
            lassoDraw.x = -lassoLayer1.x;
            lassoDraw.y = -lassoLayer1.y;
            if (replayMode)
            {
                ReplayDrawer.rCanvasDrawShape.filters = canvasDrawLayerFilterBackUp.concat();
            }
            else
            {
                StrokeBuffer.canvasDrawLayerChild.filters = canvasDrawLayerFilterBackUp.concat();
            }
            return true;
        }

    }
}
