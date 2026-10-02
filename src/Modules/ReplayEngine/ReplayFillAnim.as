package Modules.ReplayEngine
{
    import Modules.Tools.PenTool;

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.CapsStyle;
    import flash.display.JointStyle;
    import flash.display.LineScaleMode;
    import flash.display.Shape;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;

    // 채우기 펜(fill5, drawDone5) 바로 뒤의 ["fillanim", 높이]를 실시간 재생할때 보여주는 스캔라인 애니메이션 (ReplayDrawer.fillAnim)
    // 채워진 영역을 리플레이 배경색 덮개로 가렸다가 위에서부터 서서히 지워서 채우기가 드러나게 함
    // 덮개는 리플레이 캔버스 맨 위에 얹은 임시 비트맵이라 레이어 데이터는 건드리지 않음, 중간에 멈추거나 탐색해도 clear만 하면 됨
    public class ReplayFillAnim
    {
        private var overlay:Bitmap = null;
        private var overlayData:BitmapData = null;
        private const area:Rectangle = new Rectangle(); // 덮개가 덮는 영역 (캔버스 좌표)
        private var totalTicks:Number = 0;
        private var clock:Number = 0; // 애니메이션이 시작하고 흐른 틱
        private var revealedRows:int = 0; // 위에서부터 이미 지운 줄 수
        private var active:Boolean = false;

        public function get isActive():Boolean
        {
            return active;
        }

        // 지금 재생 속도에서 애니메이션이 나오지 않거나 덮개를 만들지 못하면 false (그 채우기는 그냥 지나감)
        // 부르는 쪽에서 fillanim 칸을 읽은 직후에 불러야 함 (fill5를 그 칸 앞에서 찾음)
        public function start(height:Number, speed:Number):Boolean
        {
            clear();
            totalTicks = ReplayState.getFillAnimTicksAtSpeed(height, speed);

            if (totalTicks <= 0)
            {
                return false;
            }

            const bgColor:uint = ReplayState.RCANVAS_BG_COLOR;
            const fill:Array = ReplayDrawCommands.findFillBefore();
            var shape:Shape = null;
            var bounds:Rectangle;

            if (fill)
            {
                // 채워진 모양 그대로 덮음, 안티앨리어싱 가장자리와 에어브러시 번짐이 덮개 밖으로 남지 않게 선을 둘러서 조금 넓힘
                const offset:Number = (ReplayState.rAirBrushSize2 > 0) ? PenTool.getClipRectOffsetAirBrush(ReplayState.rAirBrushSize2) : 1;
                shape = new Shape();
                shape.graphics.lineStyle((offset + 1) * 2, bgColor, 1, false, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
                shape.graphics.beginFill(bgColor);
                shape.graphics.drawPath(fill[4], fill[5]);
                shape.graphics.endFill();
                bounds = shape.getBounds(shape);
            }
            else
            {
                // 모양을 못 찾으면 그려진 영역 사각형을 통째로 덮음
                bounds = ReplayDrawer.rCanvasDrawLayerClipRect;
            }

            // 비트맵 픽셀에 맞게 바깥으로 올림
            area.setTo(Math.floor(bounds.x), Math.floor(bounds.y), 0, 0);
            area.right = Math.ceil(bounds.right);
            area.bottom = Math.ceil(bounds.bottom);
            const clipped:Rectangle = area.intersection(new Rectangle(0, 0, ReplayState.RCANVAS_WIDTH, ReplayState.RCANVAS_HEIGHT));

            if (clipped.isEmpty())
            {
                return false;
            }

            area.copyFrom(clipped);

            try
            {
                overlayData = new BitmapData(area.width, area.height, true, 0);

                if (shape)
                {
                    overlayData.draw(shape, new Matrix(1, 0, 0, 1, -area.x, -area.y));
                }
                else
                {
                    overlayData.fillRect(overlayData.rect, 0xFF000000 | bgColor);
                }
            }
            catch (error:Error)
            {
                // 비트맵 크기 제한 등으로 못 만들면 애니메이션 없이 지나감
                clear();
                return false;
            }

            overlay = new Bitmap(overlayData, "auto", true);
            overlay.x = area.x;
            overlay.y = area.y;

            // 리플레이 커서는 항상 맨 위라서 그 바로 아래에 넣음
            if (ReplayDrawer.rReplayFOFOCursor.parent === ReplayDrawer.rCanvasPanel)
            {
                ReplayDrawer.rCanvasPanel.addChildAt(overlay, ReplayDrawer.rCanvasPanel.getChildIndex(ReplayDrawer.rReplayFOFOCursor));
            }
            else
            {
                ReplayDrawer.rCanvasPanel.addChild(overlay);
            }

            clock = 0;
            revealedRows = 0;
            active = true;
            moveCursor(0);
            return true;
        }

        // dTicks만큼 진행시킴. 끝났으면 덮개를 치우고 남은 틱을 돌려주고, 아직이면 -1
        public function advance(dTicks:Number):Number
        {
            if (!active)
            {
                return dTicks;
            }

            clock += dTicks;

            const rows:int = (clock >= totalTicks) ? area.height : Math.floor(area.height * clock / totalTicks);

            if (rows > revealedRows)
            {
                overlayData.fillRect(new Rectangle(0, revealedRows, area.width, rows - revealedRows), 0);
                revealedRows = rows;
            }

            moveCursor(rows);

            if (clock >= totalTicks)
            {
                const leftover:Number = clock - totalTicks;
                clear();
                return leftover;
            }

            return -1;
        }

        public function getRemainingTicks():Number
        {
            return active ? Math.max(0, totalTicks - clock) : 0;
        }

        // 덮개를 치움 (탐색, 모드 탈출, 처음부터 다시 시작할때). 쉬고 있어도 불러도 됨
        public function clear():void
        {
            if (overlay)
            {
                if (overlay.parent)
                {
                    overlay.parent.removeChild(overlay);
                }

                overlay.bitmapData = null;
                overlay = null;
            }

            if (overlayData)
            {
                overlayData.dispose();
                overlayData = null;
            }

            active = false;
        }

        // 리플레이 커서는 영역 가운데 x에 두고 y만 지운 위치로 내려옴
        private function moveCursor(rows:int):void
        {
            ReplayDrawCommands.setRCursorPos(area.x + area.width / 2, area.y + rows);
            ReplayDrawCommands.updateRCursorPos();
        }
    }
}
