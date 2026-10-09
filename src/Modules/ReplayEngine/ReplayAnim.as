package Modules.ReplayEngine
{

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.CapsStyle;
    import flash.display.DisplayObjectContainer;
    import flash.display.JointStyle;
    import flash.display.Graphics;
    import flash.display.LineScaleMode;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import Modules.L2Engine.ReplayEngine.ReplayClock;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.L3Feature.Tools.PenTool;
    import Modules.L2Engine.ReplayEngine.ReplayDrawCommands;
    import Modules.L2Engine.ReplayEngine.ReplayState;

    // 채우기(fill5), 올가미(lasso2), 이동(move, move1, move2) 명령을 실시간 재생할때 보여주는 연출
    // 길이는 타이밍 시트의 연출 길이(그 도구를 시작해서 끝낼때까지 걸린 시간)이고, 진행률은 시계의 녹화 시각으로 구함
    // 채우기, 올가미: 그려진 영역을 배경색 덮개로 가렸다가 위에서부터 서서히 지워서 드러나게 함 (스캔라인)
    // 이동: 이동 전 레이어 이미지가 목표 위치까지 감속(ease-out)하며 움직임
    // 명령은 연출이 시작하는 시점에 이미 실행된 상태(레이어 데이터는 최종 결과)이고, 연출은 그 위에 얹은 임시 표시라서
    // 중간에 멈추거나 탐색해도 clear만 하면 정확한 최종 상태가 보임
    // 흐름: 그리기 루프가 명령을 실행하기 전에 arm → 명령이 실행되면서 start*를 부름 → 틱마다 update → 끝나거나 clear
    // 층: L2 엔진 - 채우기·올가미·이동 명령의 실시간 재생 연출
    public class ReplayAnim
    {
        public static const MIN_REAL_MS:Number = 120; // 배속을 반영한 실제 연출 시간이 이보다 짧으면 연출 없이 바로 보여줌

        private var armedMs:Number = 0;
        private var armedStart:Number = 0; // 연출이 시작하는 녹화 시각
        private var armedFrame:Number = -1; // 연출할 명령의 프레임 번호 (점별 시각을 찾는데 씀)

        private var active:Boolean = false;
        private var endFrameShown:Boolean = false; // 이동 연출이 끝난 프레임(진행률 1)을 이미 보여줬는지 (그 다음 틱에 clear)
        private var mode:int = 0; // 1 = 스캔라인 덮개, 2 = 이동, 3 = 선 도구 (점 순서대로 그려짐)
        private var startTime:Number = 0;
        private var totalMs:Number = 0;

        // 스캔라인
        private var overlay:Bitmap = null;
        private var overlayData:BitmapData = null;
        private const area:Rectangle = new Rectangle();
        private var revealedRows:int = 0;

        // 이동
        private var container:Sprite = null;
        private var ref1:Bitmap = null;
        private var ref2:Bitmap = null;
        private var clone1:BitmapData = null;
        private var clone2:BitmapData = null;
        private var hidden1:Boolean = false;
        private var hidden2:Boolean = false;
        private var savedVisible1:Boolean = true;
        private var savedVisible2:Boolean = true;
        private var moveLayer1:Boolean = false;
        private var moveLayer2:Boolean = false;
        private var distX:Number = 0;
        private var distY:Number = 0;

        // 선 도구: 실제 선은 그리기 레이어의 Shape에 이미 전부 그려져 있어서 숨겨두고, 임시 Shape에 지금까지의 경로만 다시 그림
        private var lineTemp:Shape = null;
        private var lineHost:Shape = null; // 숨긴 실제 선 Shape
        private var lineHostVisible:Boolean = true;
        private var lineXY:Vector.<Number> = null;
        private var lineOffsets:Vector.<Number> = null; // 꼭짓점마다 그려지기 시작하는 시각 (연출 시작 기준 ms)
        private var lineShape:Boolean = false;
        private var lineSize:uint = 0;
        private var lineColor:uint = 0;
        private const lineBounds:Rectangle = new Rectangle(); // 꼭짓점들의 bbox (캔버스 좌표, 선 굵기 제외)

        public function get isActive():Boolean
        {
            return active;
        }

        // 카메라가 보는 연출 관심 영역 (캔버스 좌표). 채우기/올가미는 덮개 영역, 선은 꼭짓점 bbox, 진행 중인 연출이 없거나 이동 연출이면 null
        // 복사본이라 호출자가 고쳐도 됨
        public function get focusRect():Rectangle
        {
            if (!active)
            {
                return null;
            }

            if (mode === 1)
            {
                return area.clone();
            }

            if (mode === 3)
            {
                return lineBounds.clone();
            }

            return null;
        }

        // 연출 길이가 있는 명령을 실행하기 직전에 부름. 연출을 하지 않을 명령이면 disarm
        public function arm(animMs:Number, startRecorded:Number, frame:Number):void
        {
            armedMs = animMs;
            armedStart = startRecorded;
            armedFrame = frame;
        }

        public function disarm():void
        {
            armedMs = 0;
        }

        // fill5가 모양을 그린 직후에 부름. 모양대로 배경색 덮개를 만들어 올림
        public function startFill(command:Vector.<int>, xyData:Vector.<Number>):void
        {
            if (!takeArmed())
            {
                return;
            }

            const bgColor:uint = ReplayState.RCANVAS_BG_COLOR;
            // 안티앨리어싱 가장자리와 에어브러시 번짐이 덮개 밖으로 남지 않게 선을 둘러서 조금 넓힘
            const offset:Number = (ReplayState.rAirBrushSize2 > 0) ? PenTool.getClipRectOffsetAirBrush(ReplayState.rAirBrushSize2) : 1;
            const shape:Shape = new Shape();
            shape.graphics.lineStyle((offset + 1) * 2, bgColor, 1, false, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
            shape.graphics.beginFill(bgColor);
            shape.graphics.drawPath(command, xyData);
            shape.graphics.endFill();
            const bounds:Rectangle = shape.getBounds(shape);

            if (!setArea(bounds))
            {
                return;
            }

            try
            {
                overlayData = new BitmapData(area.width, area.height, true, 0);
                overlayData.draw(shape, new Matrix(1, 0, 0, 1, -area.x, -area.y));
            }
            catch (error:Error)
            {
                clear();
                return;
            }

            showOverlay();
        }

        // lasso2가 올가미 비트맵을 캔버스에 그린 직후에 부름. 같은 행렬로 올가미 모양 덮개를 만듬
        // layer1, layer2는 그린 쪽의 올가미 비트맵 (안 그렸으면 null)
        public function startLasso(mat:Matrix, layer1:Bitmap, layer2:Bitmap):void
        {
            if (!takeArmed())
            {
                return;
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
                return;
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

            if (!setArea(bounds))
            {
                return;
            }

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
                return;
            }

            showOverlay();
        }

        // line4가 선을 그린 직후에 부름. 점(꼭짓점) 순서대로 선이 자라는 연출을 시작함
        // 점마다 찍은 시각이 있으면 그 시각대로, 없거나 맞지 않으면 경로 길이에 비례해서 연출 길이 안에 그림
        public function startLine(command:Vector.<int>, xyData:Vector.<Number>, shape:Boolean, size:uint, color:uint):void
        {
            const frame:Number = armedFrame;

            if (!takeArmed())
            {
                return;
            }

            const vertexCount:int = xyData.length / 2;

            if (vertexCount < 2 || command.length !== vertexCount)
            {
                clear();
                return;
            }

            // 선 도구는 moveTo(1)와 lineTo(2)만 씀. 다른 명령이 섞여 있으면 연출 없이 지나감
            for (var c:int = 0;c < command.length;c++)
            {
                if (command[c] !== 1 && command[c] !== 2)
                {
                    clear();
                    return;
                }
            }

            lineOffsets = new Vector.<Number>(vertexCount, true);
            const recorded:Vector.<uint> = ReplayClock.pointOffsetsOfFrame(frame);
            var useRecorded:Boolean = recorded !== null && recorded.length === vertexCount;

            // 기록된 시각은 앞에서부터 줄어들지 않아야 하고 연출 길이를 넘지 않아야 씀
            for (var i:int = 0;useRecorded && i < vertexCount;i++)
            {
                if ((i > 0 && recorded[i] < recorded[i - 1]) || recorded[i] > totalMs)
                {
                    useRecorded = false;
                }
            }

            if (useRecorded)
            {
                for (i = 0;i < vertexCount;i++)
                {
                    lineOffsets[i] = recorded[i];
                }
            }
            else
            {
                // 경로 길이에 비례
                var total:Number = 0;

                for (i = 1;i < vertexCount;i++)
                {
                    total += Math.sqrt(Math.pow(xyData[i * 2] - xyData[i * 2 - 2], 2) + Math.pow(xyData[i * 2 + 1] - xyData[i * 2 - 1], 2));
                }

                var walked:Number = 0;
                lineOffsets[0] = 0;

                for (i = 1;i < vertexCount;i++)
                {
                    walked += Math.sqrt(Math.pow(xyData[i * 2] - xyData[i * 2 - 2], 2) + Math.pow(xyData[i * 2 + 1] - xyData[i * 2 - 1], 2));
                    lineOffsets[i] = total > 0 ? totalMs * walked / total : totalMs * i / (vertexCount - 1);
                }
            }

            lineHost = ReplayDrawer.rCanvasDrawShape;

            if (lineHost.parent === null)
            {
                clear();
                return;
            }

            lineXY = xyData.concat();
            lineBounds.setTo(lineXY[0], lineXY[1], 0, 0);

            for (i = 1;i < vertexCount;i++)
            {
                lineBounds.left = Math.min(lineBounds.left, lineXY[i * 2]);
                lineBounds.top = Math.min(lineBounds.top, lineXY[i * 2 + 1]);
                lineBounds.right = Math.max(lineBounds.right, lineXY[i * 2]);
                lineBounds.bottom = Math.max(lineBounds.bottom, lineXY[i * 2 + 1]);
            }

            lineShape = shape;
            lineSize = size;
            lineColor = color;
            lineTemp = new Shape();
            lineTemp.filters = lineHost.filters;
            lineTemp.blendMode = lineHost.blendMode;
            const parent:DisplayObjectContainer = lineHost.parent;
            parent.addChildAt(lineTemp, parent.getChildIndex(lineHost) + 1);
            lineHostVisible = lineHost.visible;
            lineHost.visible = false;
            mode = 3;
            active = true;
            update(startTime);
        }

        // move 명령이 레이어를 옮기기 전에 부름. 옮기기 전 레이어 이미지를 복사해서 목표 위치까지 움직이는 덮개로 보여줌
        public function startMove(dx:Number, dy:Number, layer1:Boolean, layer2:Boolean):void
        {
            if (!takeArmed())
            {
                return;
            }

            if (dx === 0 && dy === 0)
            {
                clear();
                return;
            }

            distX = dx;
            distY = dy;
            moveLayer1 = layer1;
            moveLayer2 = layer2;

            const bitmap1:Bitmap = ReplayDrawer.rCanvasLayer1Bitmap;
            const bitmap2:Bitmap = ReplayDrawer.rCanvasLayer2Bitmap;
            const show1:Boolean = bitmap1.visible && bitmap1.bitmapData !== null;
            const show2:Boolean = bitmap2.visible && bitmap2.bitmapData !== null;

            if (!show1 && !show2)
            {
                clear();
                return;
            }

            try
            {
                container = new Sprite();
                container.mouseEnabled = false;
                container.mouseChildren = false;

                // 실제와 같은 순서 (레이어2가 아래, 레이어1이 위), 움직이지 않는 레이어도 넣어서 순서가 어긋나지 않게 함
                if (show2)
                {
                    clone2 = bitmap2.bitmapData.clone();
                    ref2 = new Bitmap(clone2, "auto", true);
                    container.addChild(ref2);
                }

                if (show1)
                {
                    clone1 = bitmap1.bitmapData.clone();
                    ref1 = new Bitmap(clone1, "auto", true);
                    container.addChild(ref1);
                }

                addAboveLayers(container);

                // 덮개가 올라간 뒤에 실제 레이어를 숨겨서 한 프레임도 빈 화면이 나오지 않게 함, 배경은 rCanvasPanel이 자기 graphics로 그림
                if (show1)
                {
                    savedVisible1 = bitmap1.visible;
                    bitmap1.visible = false;
                    hidden1 = true;
                }

                if (show2)
                {
                    savedVisible2 = bitmap2.visible;
                    bitmap2.visible = false;
                    hidden2 = true;
                }
            }
            catch (error:Error)
            {
                clear();
                return;
            }

            mode = 2;
            active = true;
            update(startTime);
        }

        // 지금 녹화 시각 recorded까지 연출을 진행시킴. 끝났으면 덮개를 치움
        public function update(recorded:Number):void
        {
            if (!active)
            {
                return;
            }

            const elapsed:Number = recorded - startTime;

            if (elapsed >= totalMs)
            {
                if (mode === 2 && !endFrameShown)
                {
                    // 마지막 위치(진행률 1)를 한 프레임 실제로 보여준 뒤 다음 틱에 덮개를 치운다
                    // (바로 clear하면 방금 맞춘 위치가 화면에 그려지지 않아 남은 오차만큼 튐)
                    endFrameShown = true;
                    applyMoveOffset(distX, distY);
                    ReplayDrawCommands.setRCursorPos(ReplayState.RCANVAS_WIDTH / 2 + distX, ReplayState.RCANVAS_HEIGHT / 2 + distY);
                    return;
                }

                clear();
                return;
            }

            const p:Number = Math.max(0, elapsed / totalMs);

            if (mode === 1)
            {
                const rows:int = Math.floor(area.height * p);

                if (rows > revealedRows)
                {
                    overlayData.fillRect(new Rectangle(0, revealedRows, area.width, rows - revealedRows), 0);
                    revealedRows = rows;
                }

                // 리플레이 커서는 영역 가운데 x에 두고 y만 지운 위치로 내려옴
                ReplayDrawCommands.setRCursorPos(area.x + area.width / 2, area.y + rows);
            }
            else if (mode === 3)
            {
                drawLinePartial(elapsed);
            }
            else if (mode === 2)
            {
                // 감속 이동 (ease-out): 남은 거리 비율은 남은 시간 비율의 제곱, 정수 픽셀 위치
                const remainingRatio:Number = (1 - p) * (1 - p);
                const offsetX:int = Math.round(distX * (1 - remainingRatio));
                const offsetY:int = Math.round(distY * (1 - remainingRatio));

                applyMoveOffset(offsetX, offsetY);
                ReplayDrawCommands.setRCursorPos(ReplayState.RCANVAS_WIDTH / 2 + offsetX, ReplayState.RCANVAS_HEIGHT / 2 + offsetY);
            }
        }

        // 이동 연출의 복제 레이어를 (dx, dy)만큼 옮김 (진행 중 틱과 마지막 프레임에서 같이 씀)
        private function applyMoveOffset(dx:Number, dy:Number):void
        {
            if (ref1 && moveLayer1)
            {
                ref1.x = dx;
                ref1.y = dy;
            }

            if (ref2 && moveLayer2)
            {
                ref2.x = dx;
                ref2.y = dy;
            }
        }

        // 연출 시작 후 elapsed ms 시점까지의 경로를 임시 Shape에 다시 그림: 이미 찍힌 점까지의 선분 + 다음 점을 향해 자라는 선분
        private function drawLinePartial(elapsed:Number):void
        {
            const vertexCount:int = lineOffsets.length;
            var reached:int = 0; // elapsed 이하의 시각을 가진 마지막 꼭짓점

            while (reached + 1 < vertexCount && lineOffsets[reached + 1] <= elapsed)
            {
                reached++;
            }

            const commands:Vector.<int> = new Vector.<int>();
            const coords:Vector.<Number> = new Vector.<Number>();

            for (var i:int = 0;i <= reached;i++)
            {
                commands.push(i === 0 ? 1 : 2);
                coords.push(lineXY[i * 2], lineXY[i * 2 + 1]);
            }

            var tipX:Number = lineXY[reached * 2];
            var tipY:Number = lineXY[reached * 2 + 1];

            if (reached + 1 < vertexCount)
            {
                const span:Number = lineOffsets[reached + 1] - lineOffsets[reached];
                const t:Number = span > 0 ? Math.max(0, Math.min(1, (elapsed - lineOffsets[reached]) / span)) : 1;
                tipX += (lineXY[reached * 2 + 2] - tipX) * t;
                tipY += (lineXY[reached * 2 + 3] - tipY) * t;
                commands.push(2);
                coords.push(tipX, tipY);
            }

            const g:Graphics = lineTemp.graphics;
            g.clear();

            if (lineShape)
            {
                g.lineStyle(lineSize, lineColor, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.ROUND);
            }
            else
            {
                g.lineStyle(lineSize, lineColor);
            }

            if (commands.length > 1)
            {
                g.drawPath(commands, coords);
            }

            ReplayDrawCommands.setRCursorPos(tipX, tipY);
        }

        // 덮개를 치우고 숨긴 레이어를 복구함 (끝났을때, 일시정지, 탐색, 모드 탈출). 쉬고 있어도 불러도 됨
        public function clear():void
        {
            armedMs = 0;
            active = false;
            endFrameShown = false;
            mode = 0;

            try
            {
                if (overlay)
                {
                    if (overlay.parent)
                    {
                        overlay.parent.removeChild(overlay);
                    }

                    overlay.bitmapData = null;
                }

                if (container && container.parent)
                {
                    container.parent.removeChild(container);
                }
            }
            finally
            {
                // 예외가 나도 실제 레이어(과 선 Shape)는 반드시 복구함
                if (lineTemp)
                {
                    if (lineTemp.parent)
                    {
                        lineTemp.parent.removeChild(lineTemp);
                    }

                    lineTemp.graphics.clear();
                    lineTemp = null;
                }

                if (lineHost)
                {
                    lineHost.visible = lineHostVisible;
                    lineHost = null;
                }

                lineXY = null;
                lineOffsets = null;

                if (hidden1)
                {
                    ReplayDrawer.rCanvasLayer1Bitmap.visible = savedVisible1;
                }

                if (hidden2)
                {
                    ReplayDrawer.rCanvasLayer2Bitmap.visible = savedVisible2;
                }

                hidden1 = false;
                hidden2 = false;

                if (ref1)
                {
                    ref1.bitmapData = null;
                }

                if (ref2)
                {
                    ref2.bitmapData = null;
                }

                if (overlayData)
                {
                    overlayData.dispose();
                }

                if (clone1)
                {
                    clone1.dispose();
                }

                if (clone2)
                {
                    clone2.dispose();
                }

                overlay = null;
                overlayData = null;
                container = null;
                ref1 = null;
                ref2 = null;
                clone1 = null;
                clone2 = null;
            }
        }

        // arm한 연출을 시작 상태로 옮김. arm하지 않았으면 false
        private function takeArmed():Boolean
        {
            if (armedMs <= 0)
            {
                return false;
            }

            // clear가 arm 값도 지우므로 값을 먼저 보관해 둠
            const ms:Number = armedMs;
            const start:Number = armedStart;
            clear(); // 앞 연출이 남아 있으면 정리
            totalMs = ms;
            startTime = start;
            return true;
        }

        // 덮개를 올릴 영역을 비트맵 픽셀에 맞게 바깥으로 올리고 캔버스 안으로 자름. 덮을 영역이 없으면 false
        private function setArea(bounds:Rectangle):Boolean
        {
            area.setTo(Math.floor(bounds.x), Math.floor(bounds.y), 0, 0);
            area.right = Math.ceil(bounds.right);
            area.bottom = Math.ceil(bounds.bottom);
            const clipped:Rectangle = area.intersection(new Rectangle(0, 0, ReplayState.RCANVAS_WIDTH, ReplayState.RCANVAS_HEIGHT));

            if (clipped.isEmpty())
            {
                return false;
            }

            area.copyFrom(clipped);
            return true;
        }

        private function showOverlay():void
        {
            overlay = new Bitmap(overlayData, "auto", true);
            overlay.x = area.x;
            overlay.y = area.y;
            addAboveLayers(overlay);
            revealedRows = 0;
            mode = 1;
            active = true;
            update(startTime);
        }

        // 리플레이 커서는 항상 맨 위라서 그 바로 아래에 넣음
        private function addAboveLayers(child:*):void
        {
            if (ReplayDrawer.rReplayFOFOCursor.parent === ReplayDrawer.rCanvasPanel)
            {
                ReplayDrawer.rCanvasPanel.addChildAt(child, ReplayDrawer.rCanvasPanel.getChildIndex(ReplayDrawer.rReplayFOFOCursor));
            }
            else
            {
                ReplayDrawer.rCanvasPanel.addChild(child);
            }
        }
    }
}
