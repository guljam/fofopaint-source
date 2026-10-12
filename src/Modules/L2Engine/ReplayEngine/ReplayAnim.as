package Modules.L2Engine.ReplayEngine
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
    import Modules.L2Engine.ReplayEngine.ReplayDrawCommands;
    import Modules.L2Engine.ReplayEngine.ReplayState;
    import Modules.L1Data.Tools.PenSettings;

    // 채우기(fill5), 올가미(lasso2), 이동(move, move1, move2) 명령을 실시간 재생할때 보여주는 연출
    // 길이는 타이밍 시트의 연출 길이(그 도구를 시작해서 끝낼때까지 걸린 시간)이고, 진행률은 시계의 녹화 시각으로 구함
    // 채우기, 올가미: 그려진 영역을 배경색 덮개로 가렸다가 위에서부터 서서히 지워서 드러나게 함 (스캔라인)
    // 이동: 이동 전 레이어 이미지가 목표 위치까지 감속(ease-out)하며 움직임
    // 명령은 연출이 시작하는 시점에 이미 실행된 상태(레이어 데이터는 최종 결과)이고, 연출은 그 위에 얹은 임시 표시라서
    // 중간에 멈추거나 탐색해도 clearAnimOverlay만 하면 정확한 최종 상태가 보임
    // 흐름: 그리기 루프가 명령을 실행하기 전에 reserveAnim → 명령이 실행되면서 start*Anim을 부름 → 틱마다 updateAnimToRecorded → 끝나거나 clearAnimOverlay
    // 층: L2 엔진 - 채우기·올가미·이동 명령의 실시간 재생 연출
    public class ReplayAnim
    {
        public static const MIN_REAL_MS:Number = 120; // 배속을 반영한 실제 연출 시간이 이보다 짧으면 연출 없이 바로 보여줌
        private static const ANIM_MODE_NONE:int = 0;
        private static const ANIM_MODE_SCANLINE:int = 1; // 채우기, 올가미: 스캔라인 덮개
        private static const ANIM_MODE_MOVE:int = 2; // 이동
        private static const ANIM_MODE_LINE:int = 3; // 선 도구 (점 순서대로 그려짐)

        private var reservedAnimLengthMs:Number = 0;
        private var reservedAnimStartRecordedMs:Number = 0; // 연출이 시작하는 녹화 시각
        private var reservedCommandFrame:Number = -1; // 연출할 명령의 프레임 번호 (점별 시각을 찾는데 씀)

        private var _isAnimActive:Boolean = false;
        private var isMoveEndFrameShown:Boolean = false; // 이동 연출이 끝난 프레임(진행률 1)을 이미 보여줬는지 (그 다음 틱에 clearAnimOverlay)
        private var animMode:int = ANIM_MODE_NONE;
        private var animStartRecordedMs:Number = 0;
        private var animLengthMs:Number = 0;

        // 스캔라인
        private var scanlineOverlayBitmap:Bitmap = null;
        private var scanlineOverlayBitmapData:BitmapData = null;
        private const scanlineAreaRect:Rectangle = new Rectangle();
        private var revealedScanlineRowCount:int = 0;

        // 이동
        private var moveCloneContainer:Sprite = null;
        private var moveCloneBitmap1:Bitmap = null;
        private var moveCloneBitmap2:Bitmap = null;
        private var moveCloneBitmapData1:BitmapData = null;
        private var moveCloneBitmapData2:BitmapData = null;
        private var isLayer1BitmapHidden:Boolean = false;
        private var isLayer2BitmapHidden:Boolean = false;
        private var savedLayer1BitmapVisible:Boolean = true;
        private var savedLayer2BitmapVisible:Boolean = true;
        private var isLayer1Moved:Boolean = false;
        private var isLayer2Moved:Boolean = false;
        private var moveDistanceX:Number = 0;
        private var moveDistanceY:Number = 0;

        // 선 도구: 실제 선은 그리기 레이어의 Shape에 이미 전부 그려져 있어서 숨겨두고, 임시 Shape에 지금까지의 경로만 다시 그림
        private var lineGrowShape:Shape = null;
        private var hiddenLineHostShape:Shape = null; // 숨긴 실제 선 Shape
        private var savedLineHostVisible:Boolean = true;
        private var lineXyData:Vector.<Number> = null;
        private var lineVertexStartOffsetsMs:Vector.<Number> = null; // 꼭짓점마다 그려지기 시작하는 시각 (연출 시작 기준 ms)
        private var useShapeLineStyle:Boolean = false;
        private var lineSize:uint = 0;
        private var lineColor:uint = 0;
        private const lineVertexBounds:Rectangle = new Rectangle(); // 꼭짓점들의 bbox (캔버스 좌표, 선 굵기 제외)

        // 연출이 진행 중인지 (reserveAnim만 한 상태는 아님)
        public function get isAnimActive():Boolean
        {
            return _isAnimActive;
        }

        // 카메라가 보는 연출 관심 영역 (캔버스 좌표). 채우기/올가미는 덮개 영역, 선은 꼭짓점 bbox, 진행 중인 연출이 없거나 이동 연출이면 null
        // 복사본이라 호출자가 고쳐도 됨
        public function get animFocusRect():Rectangle
        {
            if (!_isAnimActive)
            {
                return null;
            }

            if (animMode === ANIM_MODE_SCANLINE)
            {
                return scanlineAreaRect.clone();
            }

            if (animMode === ANIM_MODE_LINE)
            {
                return lineVertexBounds.clone();
            }

            return null;
        }

        // 연출 길이가 있는 명령을 실행하기 직전에 부름. 연출을 하지 않을 명령이면 cancelReservedAnim
        public function reserveAnim(newAnimLengthMs:Number, newAnimStartRecordedMs:Number, commandFrame:Number):void
        {
            reservedAnimLengthMs = newAnimLengthMs;
            reservedAnimStartRecordedMs = newAnimStartRecordedMs;
            reservedCommandFrame = commandFrame;
        }

        // reserveAnim으로 예약한 연출을 취소함 (진행 중인 연출은 건드리지 않음)
        public function cancelReservedAnim():void
        {
            reservedAnimLengthMs = 0;
        }

        // fill5가 모양을 그린 직후에 부름. 모양대로 배경색 덮개를 만들어 올림
        public function startFillScanlineAnim(fillPathCommands:Vector.<int>, fillPathXyData:Vector.<Number>):void
        {
            if (!beginReservedAnim())
            {
                return;
            }

            const bgColor:uint = ReplayState.RCANVAS_BG_COLOR;
            // 안티앨리어싱 가장자리와 에어브러시 번짐이 덮개 밖으로 남지 않게 선을 둘러서 조금 넓힘
            const offset:Number = (ReplayState.rAirBrushSize2 > 0) ? PenSettings.getClipRectOffsetAirBrush(ReplayState.rAirBrushSize2) : 1;
            const shape:Shape = new Shape();
            shape.graphics.lineStyle((offset + 1) * 2, bgColor, 1, false, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
            shape.graphics.beginFill(bgColor);
            shape.graphics.drawPath(fillPathCommands, fillPathXyData);
            shape.graphics.endFill();
            const bounds:Rectangle = shape.getBounds(shape);

            if (!setScanlineAreaClippedToCanvas(bounds))
            {
                return;
            }

            try
            {
                scanlineOverlayBitmapData = new BitmapData(scanlineAreaRect.width, scanlineAreaRect.height, true, 0);
                scanlineOverlayBitmapData.draw(shape, new Matrix(1, 0, 0, 1, -scanlineAreaRect.x, -scanlineAreaRect.y));
            }
            catch (error:Error)
            {
                clearAnimOverlay();
                return;
            }

            showScanlineOverlay();
        }

        // lasso2가 올가미 비트맵을 캔버스에 그린 직후에 부름. 같은 행렬로 올가미 모양 덮개를 만듬
        // layer1, layer2는 그린 쪽의 올가미 비트맵 (안 그렸으면 null)
        public function startLassoScanlineAnim(lassoMatrix:Matrix, lassoLayer1Bitmap:Bitmap, lassoLayer2Bitmap:Bitmap):void
        {
            if (!beginReservedAnim())
            {
                return;
            }

            const sources:Array = [];

            if (lassoLayer1Bitmap && lassoLayer1Bitmap.bitmapData)
            {
                sources.push(lassoLayer1Bitmap);
            }

            if (lassoLayer2Bitmap && lassoLayer2Bitmap.bitmapData)
            {
                sources.push(lassoLayer2Bitmap);
            }

            if (sources.length === 0)
            {
                return;
            }

            // 올가미 비트맵 네 모서리를 같은 행렬로 옮긴 영역
            const bounds:Rectangle = new Rectangle();
            var first:Boolean = true;

            for each (var lassoBitmap:Bitmap in sources)
            {
                const w:Number = lassoBitmap.bitmapData.width;
                const h:Number = lassoBitmap.bitmapData.height;

                for each (var corner:Array in [[0, 0], [w, 0], [0, h], [w, h]])
                {
                    const p:Point = lassoMatrix.transformPoint(new Point(corner[0], corner[1]));

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

            if (!setScanlineAreaClippedToCanvas(bounds))
            {
                return;
            }

            try
            {
                scanlineOverlayBitmapData = new BitmapData(scanlineAreaRect.width, scanlineAreaRect.height, true, 0);
                const m:Matrix = lassoMatrix.clone();
                m.translate(-scanlineAreaRect.x, -scanlineAreaRect.y);

                for each (lassoBitmap in sources)
                {
                    scanlineOverlayBitmapData.draw(lassoBitmap, m, null, null, null, true);
                }

                // 조금이라도 그려진 픽셀(알파 1 이상)은 불투명한 배경색으로 바꿈 (반투명 가장자리도 덮임)
                scanlineOverlayBitmapData.threshold(scanlineOverlayBitmapData, scanlineOverlayBitmapData.rect, new Point(0, 0), ">=", 0x01000000, 0xFF000000 | ReplayState.RCANVAS_BG_COLOR, 0xFF000000, true);
            }
            catch (error:Error)
            {
                clearAnimOverlay();
                return;
            }

            showScanlineOverlay();
        }

        // line4가 선을 그린 직후에 부름. 점(꼭짓점) 순서대로 선이 자라는 연출을 시작함
        // 점마다 찍은 시각이 있으면 그 시각대로, 없거나 맞지 않으면 경로 길이에 비례해서 연출 길이 안에 그림
        public function startLineGrowAnim(drawnLineCommands:Vector.<int>, drawnLineXyData:Vector.<Number>, isShapeLine:Boolean, drawnLineSize:uint, drawnLineColor:uint):void
        {
            const frame:Number = reservedCommandFrame;

            if (!beginReservedAnim())
            {
                return;
            }

            const vertexCount:int = drawnLineXyData.length / 2;

            if (vertexCount < 2 || drawnLineCommands.length !== vertexCount)
            {
                clearAnimOverlay();
                return;
            }

            // 선 도구는 moveTo(1)와 lineTo(2)만 씀. 다른 명령이 섞여 있으면 연출 없이 지나감
            for (var c:int = 0;c < drawnLineCommands.length;c++)
            {
                if (drawnLineCommands[c] !== 1 && drawnLineCommands[c] !== 2)
                {
                    clearAnimOverlay();
                    return;
                }
            }

            lineVertexStartOffsetsMs = new Vector.<Number>(vertexCount, true);
            const recorded:Vector.<uint> = ReplayClock.getPointOffsetsOfFrame(frame);
            var useRecorded:Boolean = recorded !== null && recorded.length === vertexCount;

            // 기록된 시각은 앞에서부터 줄어들지 않아야 하고 연출 길이를 넘지 않아야 씀
            for (var i:int = 0;useRecorded && i < vertexCount;i++)
            {
                if ((i > 0 && recorded[i] < recorded[i - 1]) || recorded[i] > animLengthMs)
                {
                    useRecorded = false;
                }
            }

            if (useRecorded)
            {
                for (i = 0;i < vertexCount;i++)
                {
                    lineVertexStartOffsetsMs[i] = recorded[i];
                }
            }
            else
            {
                // 경로 길이에 비례
                var total:Number = 0;

                for (i = 1;i < vertexCount;i++)
                {
                    total += Math.sqrt(Math.pow(drawnLineXyData[i * 2] - drawnLineXyData[i * 2 - 2], 2) + Math.pow(drawnLineXyData[i * 2 + 1] - drawnLineXyData[i * 2 - 1], 2));
                }

                var walked:Number = 0;
                lineVertexStartOffsetsMs[0] = 0;

                for (i = 1;i < vertexCount;i++)
                {
                    walked += Math.sqrt(Math.pow(drawnLineXyData[i * 2] - drawnLineXyData[i * 2 - 2], 2) + Math.pow(drawnLineXyData[i * 2 + 1] - drawnLineXyData[i * 2 - 1], 2));
                    lineVertexStartOffsetsMs[i] = total > 0 ? animLengthMs * walked / total : animLengthMs * i / (vertexCount - 1);
                }
            }

            hiddenLineHostShape = ReplayDrawer.rCanvasDrawShape;

            if (hiddenLineHostShape.parent === null)
            {
                clearAnimOverlay();
                return;
            }

            lineXyData = drawnLineXyData.concat();
            lineVertexBounds.setTo(lineXyData[0], lineXyData[1], 0, 0);

            for (i = 1;i < vertexCount;i++)
            {
                lineVertexBounds.left = Math.min(lineVertexBounds.left, lineXyData[i * 2]);
                lineVertexBounds.top = Math.min(lineVertexBounds.top, lineXyData[i * 2 + 1]);
                lineVertexBounds.right = Math.max(lineVertexBounds.right, lineXyData[i * 2]);
                lineVertexBounds.bottom = Math.max(lineVertexBounds.bottom, lineXyData[i * 2 + 1]);
            }

            useShapeLineStyle = isShapeLine;
            lineSize = drawnLineSize;
            lineColor = drawnLineColor;
            lineGrowShape = new Shape();
            lineGrowShape.filters = hiddenLineHostShape.filters;
            lineGrowShape.blendMode = hiddenLineHostShape.blendMode;
            const parent:DisplayObjectContainer = hiddenLineHostShape.parent;
            parent.addChildAt(lineGrowShape, parent.getChildIndex(hiddenLineHostShape) + 1);
            savedLineHostVisible = hiddenLineHostShape.visible;
            hiddenLineHostShape.visible = false;
            animMode = ANIM_MODE_LINE;
            _isAnimActive = true;
            updateAnimToRecorded(animStartRecordedMs);
        }

        // move 명령이 레이어를 옮기기 전에 부름. 옮기기 전 레이어 이미지를 복사해서 목표 위치까지 움직이는 덮개로 보여줌
        public function startMoveEaseOutAnim(moveDeltaX:Number, moveDeltaY:Number, shouldMoveLayer1:Boolean, shouldMoveLayer2:Boolean):void
        {
            if (!beginReservedAnim())
            {
                return;
            }

            if (moveDeltaX === 0 && moveDeltaY === 0)
            {
                clearAnimOverlay();
                return;
            }

            moveDistanceX = moveDeltaX;
            moveDistanceY = moveDeltaY;
            isLayer1Moved = shouldMoveLayer1;
            isLayer2Moved = shouldMoveLayer2;

            const bitmap1:Bitmap = ReplayDrawer.rCanvasLayer1Bitmap;
            const bitmap2:Bitmap = ReplayDrawer.rCanvasLayer2Bitmap;
            const show1:Boolean = bitmap1.visible && bitmap1.bitmapData !== null;
            const show2:Boolean = bitmap2.visible && bitmap2.bitmapData !== null;

            if (!show1 && !show2)
            {
                clearAnimOverlay();
                return;
            }

            try
            {
                moveCloneContainer = new Sprite();
                moveCloneContainer.mouseEnabled = false;
                moveCloneContainer.mouseChildren = false;

                // 실제와 같은 순서 (레이어2가 아래, 레이어1이 위), 움직이지 않는 레이어도 넣어서 순서가 어긋나지 않게 함
                if (show2)
                {
                    moveCloneBitmapData2 = bitmap2.bitmapData.clone();
                    moveCloneBitmap2 = new Bitmap(moveCloneBitmapData2, "auto", true);
                    moveCloneContainer.addChild(moveCloneBitmap2);
                }

                if (show1)
                {
                    moveCloneBitmapData1 = bitmap1.bitmapData.clone();
                    moveCloneBitmap1 = new Bitmap(moveCloneBitmapData1, "auto", true);
                    moveCloneContainer.addChild(moveCloneBitmap1);
                }

                addChildBelowCursor(moveCloneContainer);

                // 덮개가 올라간 뒤에 실제 레이어를 숨겨서 한 프레임도 빈 화면이 나오지 않게 함, 배경은 rCanvasPanel이 자기 graphics로 그림
                if (show1)
                {
                    savedLayer1BitmapVisible = bitmap1.visible;
                    bitmap1.visible = false;
                    isLayer1BitmapHidden = true;
                }

                if (show2)
                {
                    savedLayer2BitmapVisible = bitmap2.visible;
                    bitmap2.visible = false;
                    isLayer2BitmapHidden = true;
                }
            }
            catch (error:Error)
            {
                clearAnimOverlay();
                return;
            }

            animMode = ANIM_MODE_MOVE;
            _isAnimActive = true;
            updateAnimToRecorded(animStartRecordedMs);
        }

        // 지금 녹화 시각 recorded까지 연출을 진행시킴. 끝났으면 덮개를 치움
        public function updateAnimToRecorded(recordedTimeMs:Number):void
        {
            if (!_isAnimActive)
            {
                return;
            }

            const elapsedMs:Number = recordedTimeMs - animStartRecordedMs;

            if (elapsedMs >= animLengthMs)
            {
                if (animMode === ANIM_MODE_MOVE && !isMoveEndFrameShown)
                {
                    // 마지막 위치(진행률 1)를 한 프레임 실제로 보여준 뒤 다음 틱에 덮개를 치운다
                    // (바로 clearAnimOverlay하면 방금 맞춘 위치가 화면에 그려지지 않아 남은 오차만큼 튐)
                    isMoveEndFrameShown = true;
                    applyMoveCloneOffset(moveDistanceX, moveDistanceY);
                    ReplayDrawCommands.setRCursorPos(ReplayState.RCANVAS_WIDTH / 2 + moveDistanceX, ReplayState.RCANVAS_HEIGHT / 2 + moveDistanceY);
                    return;
                }

                clearAnimOverlay();
                return;
            }

            const progressRatio:Number = Math.max(0, elapsedMs / animLengthMs);

            if (animMode === ANIM_MODE_SCANLINE)
            {
                const revealedRowCount:int = Math.floor(scanlineAreaRect.height * progressRatio);

                if (revealedRowCount > revealedScanlineRowCount)
                {
                    scanlineOverlayBitmapData.fillRect(new Rectangle(0, revealedScanlineRowCount, scanlineAreaRect.width, revealedRowCount - revealedScanlineRowCount), 0);
                    revealedScanlineRowCount = revealedRowCount;
                }

                // 리플레이 커서는 영역 가운데 x에 두고 y만 지운 위치로 내려옴
                ReplayDrawCommands.setRCursorPos(scanlineAreaRect.x + scanlineAreaRect.width / 2, scanlineAreaRect.y + revealedRowCount);
            }
            else if (animMode === ANIM_MODE_LINE)
            {
                drawLinePathUntilElapsedMs(elapsedMs);
            }
            else if (animMode === ANIM_MODE_MOVE)
            {
                // 감속 이동 (ease-out): 남은 거리 비율은 남은 시간 비율의 제곱, 정수 픽셀 위치
                const remainingRatio:Number = (1 - progressRatio) * (1 - progressRatio);
                const offsetX:int = Math.round(moveDistanceX * (1 - remainingRatio));
                const offsetY:int = Math.round(moveDistanceY * (1 - remainingRatio));

                applyMoveCloneOffset(offsetX, offsetY);
                ReplayDrawCommands.setRCursorPos(ReplayState.RCANVAS_WIDTH / 2 + offsetX, ReplayState.RCANVAS_HEIGHT / 2 + offsetY);
            }
        }

        // 이동 연출의 복제 레이어를 (dx, dy)만큼 옮김 (진행 중 틱과 마지막 프레임에서 같이 씀)
        private function applyMoveCloneOffset(cloneOffsetX:Number, cloneOffsetY:Number):void
        {
            if (moveCloneBitmap1 && isLayer1Moved)
            {
                moveCloneBitmap1.x = cloneOffsetX;
                moveCloneBitmap1.y = cloneOffsetY;
            }

            if (moveCloneBitmap2 && isLayer2Moved)
            {
                moveCloneBitmap2.x = cloneOffsetX;
                moveCloneBitmap2.y = cloneOffsetY;
            }
        }

        // 연출 시작 후 elapsed ms 시점까지의 경로를 임시 Shape에 다시 그림: 이미 찍힌 점까지의 선분 + 다음 점을 향해 자라는 선분
        private function drawLinePathUntilElapsedMs(elapsedMs:Number):void
        {
            const vertexCount:int = lineVertexStartOffsetsMs.length;
            var reached:int = 0; // elapsedMs 이하의 시각을 가진 마지막 꼭짓점

            while (reached + 1 < vertexCount && lineVertexStartOffsetsMs[reached + 1] <= elapsedMs)
            {
                reached++;
            }

            const commands:Vector.<int> = new Vector.<int>();
            const coords:Vector.<Number> = new Vector.<Number>();

            for (var i:int = 0;i <= reached;i++)
            {
                commands.push(i === 0 ? 1 : 2);
                coords.push(lineXyData[i * 2], lineXyData[i * 2 + 1]);
            }

            var tipX:Number = lineXyData[reached * 2];
            var tipY:Number = lineXyData[reached * 2 + 1];

            if (reached + 1 < vertexCount)
            {
                const span:Number = lineVertexStartOffsetsMs[reached + 1] - lineVertexStartOffsetsMs[reached];
                const t:Number = span > 0 ? Math.max(0, Math.min(1, (elapsedMs - lineVertexStartOffsetsMs[reached]) / span)) : 1;
                tipX += (lineXyData[reached * 2 + 2] - tipX) * t;
                tipY += (lineXyData[reached * 2 + 3] - tipY) * t;
                commands.push(2);
                coords.push(tipX, tipY);
            }

            const g:Graphics = lineGrowShape.graphics;
            g.clear();

            if (useShapeLineStyle)
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
        public function clearAnimOverlay():void
        {
            reservedAnimLengthMs = 0;
            _isAnimActive = false;
            isMoveEndFrameShown = false;
            animMode = ANIM_MODE_NONE;

            try
            {
                if (scanlineOverlayBitmap)
                {
                    if (scanlineOverlayBitmap.parent)
                    {
                        scanlineOverlayBitmap.parent.removeChild(scanlineOverlayBitmap);
                    }

                    scanlineOverlayBitmap.bitmapData = null;
                }

                if (moveCloneContainer && moveCloneContainer.parent)
                {
                    moveCloneContainer.parent.removeChild(moveCloneContainer);
                }
            }
            finally
            {
                // 예외가 나도 실제 레이어(과 선 Shape)는 반드시 복구함
                if (lineGrowShape)
                {
                    if (lineGrowShape.parent)
                    {
                        lineGrowShape.parent.removeChild(lineGrowShape);
                    }

                    lineGrowShape.graphics.clear();
                    lineGrowShape = null;
                }

                if (hiddenLineHostShape)
                {
                    hiddenLineHostShape.visible = savedLineHostVisible;
                    hiddenLineHostShape = null;
                }

                lineXyData = null;
                lineVertexStartOffsetsMs = null;

                if (isLayer1BitmapHidden)
                {
                    ReplayDrawer.rCanvasLayer1Bitmap.visible = savedLayer1BitmapVisible;
                }

                if (isLayer2BitmapHidden)
                {
                    ReplayDrawer.rCanvasLayer2Bitmap.visible = savedLayer2BitmapVisible;
                }

                isLayer1BitmapHidden = false;
                isLayer2BitmapHidden = false;

                if (moveCloneBitmap1)
                {
                    moveCloneBitmap1.bitmapData = null;
                }

                if (moveCloneBitmap2)
                {
                    moveCloneBitmap2.bitmapData = null;
                }

                if (scanlineOverlayBitmapData)
                {
                    scanlineOverlayBitmapData.dispose();
                }

                if (moveCloneBitmapData1)
                {
                    moveCloneBitmapData1.dispose();
                }

                if (moveCloneBitmapData2)
                {
                    moveCloneBitmapData2.dispose();
                }

                scanlineOverlayBitmap = null;
                scanlineOverlayBitmapData = null;
                moveCloneContainer = null;
                moveCloneBitmap1 = null;
                moveCloneBitmap2 = null;
                moveCloneBitmapData1 = null;
                moveCloneBitmapData2 = null;
            }
        }

        // reserveAnim한 연출을 시작 상태로 옮김. reserveAnim하지 않았으면 false
        private function beginReservedAnim():Boolean
        {
            if (reservedAnimLengthMs <= 0)
            {
                return false;
            }

            // clearAnimOverlay가 reserveAnim 값도 지우므로 값을 먼저 보관해 둠
            const reservedLengthMs:Number = reservedAnimLengthMs;
            const reservedStartRecordedMs:Number = reservedAnimStartRecordedMs;
            clearAnimOverlay(); // 앞 연출이 남아 있으면 정리
            animLengthMs = reservedLengthMs;
            animStartRecordedMs = reservedStartRecordedMs;
            return true;
        }

        // 덮개를 올릴 영역을 비트맵 픽셀에 맞게 바깥으로 올리고 캔버스 안으로 자름. 덮을 영역이 없으면 false
        private function setScanlineAreaClippedToCanvas(bounds:Rectangle):Boolean
        {
            scanlineAreaRect.setTo(Math.floor(bounds.x), Math.floor(bounds.y), 0, 0);
            scanlineAreaRect.right = Math.ceil(bounds.right);
            scanlineAreaRect.bottom = Math.ceil(bounds.bottom);
            const clipped:Rectangle = scanlineAreaRect.intersection(new Rectangle(0, 0, ReplayState.RCANVAS_WIDTH, ReplayState.RCANVAS_HEIGHT));

            if (clipped.isEmpty())
            {
                return false;
            }

            scanlineAreaRect.copyFrom(clipped);
            return true;
        }

        private function showScanlineOverlay():void
        {
            scanlineOverlayBitmap = new Bitmap(scanlineOverlayBitmapData, "auto", true);
            scanlineOverlayBitmap.x = scanlineAreaRect.x;
            scanlineOverlayBitmap.y = scanlineAreaRect.y;
            addChildBelowCursor(scanlineOverlayBitmap);
            revealedScanlineRowCount = 0;
            animMode = ANIM_MODE_SCANLINE;
            _isAnimActive = true;
            updateAnimToRecorded(animStartRecordedMs);
        }

        // 리플레이 커서는 항상 맨 위라서 그 바로 아래에 넣음
        private function addChildBelowCursor(child:*):void
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
