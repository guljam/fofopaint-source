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
    import flash.geom.Point;
    import flash.geom.Rectangle;

    // 채우기 펜(fill5, drawDone5) 바로 뒤의 ["fillanim", 높이]를 실시간 재생할때 보여주는 스캔라인 애니메이션 (ReplayDrawer.fillAnim)
    // 채워진 영역을 리플레이 배경색 덮개로 가렸다가 위에서부터 서서히 지워서 채우기가 드러나게 함
    // 덮개는 리플레이 캔버스 맨 위에 얹은 임시 비트맵이라 레이어 데이터는 건드리지 않음, 중간에 멈추거나 탐색해도 clear만 하면 됨
    public class ReplayFillAnim
    {
        private var overlay:Bitmap = null;
        private var overlayData:BitmapData = null;
        private const area:Rectangle = new Rectangle(); // 덮개가 덮는 영역 (캔버스 좌표)
        private var totalMs:Number = 0;
        private var elapsedMs:Number = 0; // 애니메이션이 시작하고 흐른 시간
        private var lastUpdateMs:Number = 0; // 덮개를 마지막으로 지운 때의 elapsedMs
        private var revealedRows:int = 0; // 위에서부터 이미 지운 줄 수
        private var active:Boolean = false;
        // lassoanim 칸을 읽고 다음 lasso2에서 애니메이션을 시작할 준비를 한 상태
        // 묶음 배열과 칸 번호에 묶어서, 정리가 빠져도 다른 묶음(다른 파일 포함)의 lasso2에는 적용되지 않게 함
        private var armedData:Array = null;
        private var armedIndex:int = -1;
        private var armedHeight:Number = 0;

        public function get isActive():Boolean
        {
            return active;
        }

        // lassoanim 칸을 읽은 직후에 불러야 함. group과 index는 다음에 읽을 칸 (ReplayDrawCommands.data, index)
        public function arm(group:Array, index:int, height:Number):void
        {
            armedData = group;
            armedIndex = index;
            armedHeight = height;
        }

        public function disarm():void
        {
            armedData = null;
            armedIndex = -1;
            armedHeight = 0;
        }

        // 지금 그리려는 칸이 준비해 둔 lasso2 칸인지
        public function isArmedFor(group:Array, index:int):Boolean
        {
            return armedData !== null && armedData === group && armedIndex === index;
        }

        // lasso2가 올가미 비트맵을 캔버스에 그리는 곳에서 불러서, 같은 행렬로 올가미 모양 덮개를 만들고 애니메이션을 시작함
        // layer1, layer2는 그리는 쪽에 쓰는 비트맵 (안 쓰면 null), 덮개를 못 만들면 false (그냥 지나감)
        public function startLasso(mat:Matrix, layer1:Bitmap, layer2:Bitmap):Boolean
        {
            const height:Number = armedHeight;
            disarm();
            clear();
            totalMs = ReplayState.getFillAnimMs(height);

            if (totalMs <= 0)
            {
                return false;
            }

            const sources:Array = [];

            if (layer1 && layer1.bitmapData)
            {
                sources.push(layer1);
            }

            if (layer2 && layer2.bitmapData)
            {
                sources.push(layer2);
            }

            if (sources.length === 0)
            {
                return false;
            }

            // 올가미 비트맵 네 모서리를 같은 행렬로 옮긴 영역
            const bounds:Rectangle = new Rectangle();
            var first:Boolean = true;

            for each (var src:Bitmap in sources)
            {
                const w:Number = src.bitmapData.width;
                const h:Number = src.bitmapData.height;

                for each (var corner:Array in [[0, 0], [w, 0], [0, h], [w, h]])
                {
                    const p:Point = mat.transformPoint(new Point(corner[0], corner[1]));

                    if (first)
                    {
                        bounds.setTo(p.x, p.y, 0, 0);
                        first = false;
                    }
                    else
                    {
                        bounds.left = Math.min(bounds.left, p.x);
                        bounds.top = Math.min(bounds.top, p.y);
                        bounds.right = Math.max(bounds.right, p.x);
                        bounds.bottom = Math.max(bounds.bottom, p.y);
                    }
                }
            }

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
                const m:Matrix = mat.clone();
                m.translate(-area.x, -area.y);

                for each (src in sources)
                {
                    overlayData.draw(src, m, null, null, null, true);
                }

                // 조금이라도 그려진 픽셀(알파 1 이상)은 불투명한 배경색으로 바꿈 (반투명 가장자리도 덮임)
                overlayData.threshold(overlayData, overlayData.rect, new Point(0, 0), ">=", 0x01000000, 0xFF000000 | ReplayState.RCANVAS_BG_COLOR, 0xFF000000, true);
            }
            catch (error:Error)
            {
                clear();
                return false;
            }

            return show();
        }

        // 덮개를 만들지 못하면 false (그 채우기는 그냥 지나감)
        // 부르는 쪽에서 fillanim 칸을 읽은 직후에 불러야 함 (fill5를 그 칸 앞에서 찾음)
        public function start(height:Number):Boolean
        {
            clear();
            totalMs = ReplayState.getFillAnimMs(height);

            if (totalMs <= 0)
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

            return show();
        }

        // 만들어 둔 overlayData와 area로 덮개를 올리고 애니메이션을 시작함
        private function show():Boolean
        {
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

            elapsedMs = 0;
            lastUpdateMs = 0;
            revealedRows = 0;
            active = true;
            moveCursor(0);
            return true;
        }

        // dMs만큼 진행시킴. 끝났으면 덮개를 치우고 남은 시간(ms)을 돌려주고, 아직이면 -1
        public function advance(dMs:Number):Number
        {
            if (!active)
            {
                return dMs;
            }

            elapsedMs += dMs;

            // 덮개를 지우는 것도 리플레이 커서처럼 일정 주기로만 갱신함 (시간은 계속 흐르고 줄 수는 그 시간만큼 한번에 따라잡음), 끝날때는 바로 마무리
            if (elapsedMs < totalMs && elapsedMs - lastUpdateMs < ReplayState.REPLAY_VISUAL_UPDATE_MS)
            {
                return -1;
            }

            lastUpdateMs = elapsedMs;
            const rows:int = (elapsedMs >= totalMs) ? area.height : Math.floor(area.height * elapsedMs / totalMs);

            if (rows > revealedRows)
            {
                overlayData.fillRect(new Rectangle(0, revealedRows, area.width, rows - revealedRows), 0);
                revealedRows = rows;
            }

            moveCursor(rows);

            if (elapsedMs >= totalMs)
            {
                const leftover:Number = elapsedMs - totalMs;
                clear();
                return leftover;
            }

            return -1;
        }

        public function getRemainingMs():Number
        {
            // 준비만 해둔 상태면 곧 시작할 애니메이션 시간까지 더함
            if (active)
            {
                return Math.max(0, totalMs - elapsedMs);
            }

            return armedData !== null ? ReplayState.getFillAnimMs(armedHeight) : 0;
        }

        // 덮개를 치움 (탐색, 모드 탈출, 처음부터 다시 시작할때). 쉬고 있어도 불러도 됨
        public function clear():void
        {
            disarm();

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
        // 좌표만 바꾸고 아이콘 위치 갱신은 다른 명령처럼 진행바 타이머의 주기(startUpdatingPrograssBarTimer)에 맡김
        private function moveCursor(rows:int):void
        {
            ReplayDrawCommands.setRCursorPos(area.x + area.width / 2, area.y + rows);
        }
    }
}
