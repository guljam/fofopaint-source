package Modules.L2Engine.DrawEngine
{
    import flash.display.Graphics;

    // 층: L2 엔진 - 손으로 그린 듯한 노이즈 선과 사각형 그리기 (draw, drawRect)
    public class HandDrawnLine
    {
        // 제어점 간격 및 샘플링 간격
        private static const BASE_CONTROL_SPACING:Number = 20.0;
        private static const FINE_CONTROL_SPACING:Number = 6.0;
        private static const SAMPLE_SPACING:Number = 2.0;

        // 노이즈 강도 설정
        private static const BASE_WOBBLE_AMPLITUDE:Number = 0.25;  // 큰 완만한 구불거림
        private static const FINE_WOBBLE_AMPLITUDE:Number = 0.2; // 세밀한 잔떨림
        private static const TANGENT_WOBBLE_RATIO:Number = 0.25;  // 진행 방향 흔들림 비율

        // 두께(필압) 노이즈 변동 폭 (기본 두께의 범위 내 변화)
        private static const THICKNESS_WOBBLE_RATIO:Number = 0.27;

        public static function draw(
            graphics:Graphics,
            thickness:Number,
            color:uint,
            alpha:Number,
            startX:Number,
            startY:Number,
            endX:Number,
            endY:Number
        ):void
        {
            drawPath(graphics, startX, startY, endX, endY, thickness, color, alpha);
        }

        public static function drawRect(
            graphics:Graphics,
            thickness:Number, //선두깨
            color:uint, //선 색깔
            alpha:Number, //선 알파
            startX:Number,
            startY:Number,
            width:Number,
            height:Number,
            fillColor:* = null, // 채우기 색깔 null이면 채우지 않음
            fillAlpha:Number = 1.0, // 채우기 색깔 알파
            cornerRadius:Number = 0.01 //사각형 모서리 둥글기
        ):void
        {
            // width -= thickness;
            // height -= thickness;
            const endX:Number = startX+width;
            const endY:Number = startY+height;
            const minX:Number = Math.min(startX, endX);
            const maxX:Number = Math.max(startX, endX);
            const minY:Number = Math.min(startY, endY);
            const maxY:Number = Math.max(startY, endY);

            const r:Number = Math.min(cornerRadius, Math.min(width * 0.5, height * 0.5));

            if (r <= 0)
            {
                return;
            }

            // 1. fillColor가 지정되어 있으면 일반 둥근 사각형으로 면을 먼저 채움
            if (fillColor !== null)
            {
                graphics.lineStyle();
                graphics.beginFill(uint(fillColor), fillAlpha);
                graphics.drawRoundRect(minX, minY, width, height, r * 2, r * 2);
                graphics.endFill();
            }

            // 2. 면 채우기 위에 손그림 스타일의 외곽선을 덧칠함
            const points:Array = [
                {x: minX + r, y: minY},
                {x: maxX - r, y: minY},
                {x: maxX,     y: minY + r},
                {x: maxX,     y: maxY - r},
                {x: maxX - r, y: maxY},
                {x: minX + r, y: maxY},
                {x: minX,     y: maxY - r},
                {x: minX,     y: minY + r}
            ];

            for (var i:int = 0; i < points.length; i += 2)
            {
                var pStart:Object = points[i];
                var pEnd:Object = points[i + 1];

                // 직선 구간
                drawPath(graphics, pStart.x, pStart.y, pEnd.x, pEnd.y, thickness, color, alpha);

                // 모서리 둥근 구간
                var pNext:Object = points[(i + 2) % points.length];
                drawPath(graphics, pEnd.x, pEnd.y, pNext.x, pNext.y, thickness, color, alpha);
            }
        }

        private static function drawPath(
            graphics:Graphics,
            startX:Number,
            startY:Number,
            endX:Number,
            endY:Number,
            baseThickness:Number,
            color:uint,
            alpha:Number
        ):void
        {
            const dx:Number = endX - startX;
            const dy:Number = endY - startY;
            const length:Number = Math.sqrt(dx * dx + dy * dy);

            if (length === 0)
            {
                graphics.lineStyle(baseThickness, color, alpha);
                graphics.moveTo(startX, startY);
                return;
            }

            const dirX:Number = dx / length;
            const dirY:Number = dy / length;
            const normalX:Number = -dirY;
            const normalY:Number = dirX;

            // 1. 위치 오프셋 제어점 생성
            const baseCount:int = Math.max(2, Math.ceil(length / BASE_CONTROL_SPACING));
            const baseNormal:Vector.<Number> = createRandomArray(baseCount + 1);
            const baseTangent:Vector.<Number> = createRandomArray(baseCount + 1);

            // 2. 세밀한 잔떨림 제어점 생성
            const fineCount:int = Math.max(2, Math.ceil(length / FINE_CONTROL_SPACING));
            const fineNormal:Vector.<Number> = createRandomArray(fineCount + 1);

            // 3. 두께 변동용 제어점 생성
            const thicknessValues:Vector.<Number> = createRandomArray(baseCount + 1);

            const sampleCount:int = Math.max(2, Math.ceil(length / SAMPLE_SPACING));

            var prevPx:Number = 0;
            var prevPy:Number = 0;

            for (var sample:int = 0; sample <= sampleCount; sample++)
            {
                const t:Number = sample / sampleCount;

                // 위치 노이즈 계산
                const basePos:Number = t * baseCount;
                const baseSeg:int = Math.min(baseCount - 1, int(basePos));
                const baseLocalT:Number = basePos - baseSeg;

                const baseN:Number = sampleCatmullRom(baseNormal, baseCount, baseSeg, baseLocalT);
                const baseT:Number = sampleCatmullRom(baseTangent, baseCount, baseSeg, baseLocalT);

                const finePos:Number = t * fineCount;
                const fineSeg:int = Math.min(fineCount - 1, int(finePos));
                const fineLocalT:Number = finePos - fineSeg;

                const fineN:Number = sampleCatmullRom(fineNormal, fineCount, fineSeg, fineLocalT);

                const normalOffset:Number = (baseN * BASE_WOBBLE_AMPLITUDE) + (fineN * FINE_WOBBLE_AMPLITUDE);
                const tangentOffset:Number = (baseT * BASE_WOBBLE_AMPLITUDE * TANGENT_WOBBLE_RATIO);

                const px:Number = startX + dx * t + normalX * normalOffset + dirX * tangentOffset;
                const py:Number = startY + dy * t + normalY * normalOffset + dirY * tangentOffset;

                // 두께 노이즈 계산 (Catmull-Rom으로 매끄럽게 변화)
                const thickN:Number = sampleCatmullRom(thicknessValues, baseCount, baseSeg, baseLocalT);
                const currentThickness:Number = Math.max(
                    0.5,
                    baseThickness * (1.0 + thickN * THICKNESS_WOBBLE_RATIO)
                );

                if (sample === 0)
                {
                    graphics.lineStyle(currentThickness, color, alpha);
                    graphics.moveTo(px, py);
                }
                else
                {
                    // 두께가 계속 바뀌므로 세그먼트마다 lineStyle 적용 후 lineTo 호출
                    graphics.lineStyle(currentThickness, color, alpha);
                    graphics.lineTo(px, py);
                }

                prevPx = px;
                prevPy = py;
            }
        }

        private static function createRandomArray(size:int):Vector.<Number>
        {
            const arr:Vector.<Number> = new Vector.<Number>(size, true);
            for (var i:int = 0; i < size; i++)
            {
                arr[i] = Math.random() * 2.0 - 1.0;
            }
            return arr;
        }

        private static function sampleCatmullRom(values:Vector.<Number>, maxIndex:int, segment:int, t:Number):Number
        {
            const p0:Number = values[Math.max(0, segment - 1)];
            const p1:Number = values[segment];
            const p2:Number = values[Math.min(maxIndex, segment + 1)];
            const p3:Number = values[Math.min(maxIndex, segment + 2)];

            return catmullRom(p0, p1, p2, p3, t);
        }

        private static function catmullRom(p0:Number, p1:Number, p2:Number, p3:Number, t:Number):Number
        {
            const t2:Number = t * t;
            const t3:Number = t2 * t;
            return 0.5 * (
                2.0 * p1 +
                (-p0 + p2) * t +
                (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
                (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
            );
        }
    }
}
