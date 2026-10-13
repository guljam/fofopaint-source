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
        private static const BASE_WOBBLE_AMPLITUDE:Number = 0.2;  // 큰 완만한 구불거림
        private static const FINE_WOBBLE_AMPLITUDE:Number = 0.1; // 세밀한 잔떨림
        private static const TANGENT_WOBBLE_RATIO:Number = 0.2;  // 진행 방향 흔들림 비율

        // 두께(필압) 노이즈 변동 폭 (기본 두께의 범위 내 변화)
        private static const THICKNESS_WOBBLE_RATIO:Number = 0.27;

        // 해진 사각형 마스크(drawWornRectFill)용 설정. 선 그리기(draw, drawRect)와 별개라서 힌트/메시지 상자에는 영향이 없음
        private static const WORN_MAX_EROSION:Number = 1.0; // 가장자리가 안쪽으로 깎이는 최대 두께(px)
        private static const WORN_CORNER_RADIUS:Number = 1.0; // 모서리가 둥글게 깎이는 반경(px)
        private static const WORN_BASE_WEIGHT:Number = 0.21; // 큰 완만한 깎임 비중
        private static const WORN_FINE_WEIGHT:Number = 0.075; // 세밀한 깎임 비중

        private static const WORN_BASE_SPACING:Number = 14.0; // 큰 굴곡 제어점 간격(px)
        private static const WORN_FINE_SPACING:Number = 12.0; // 잔떨림 제어점 간격(px)
        private static const WORN_SAMPLE_SPACING:Number = 1.5; // 가장자리를 훑는 간격(px)

        // drawRect가 randomSeed를 받았을 때 같은 모양을 내도록 쓰는 난수 상태
        private static var randomSeedState:uint = 0;
        private static var isRandomSeeded:Boolean = false;

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

        // 손으로 그린 듯한 사각형 선. randomSeed가 0 이상이면 같은 seed와 같은 크기에서 늘 같은 모양이 나오고, -1이면 그릴 때마다 달라짐
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
            cornerRadius:Number = 0.01, //사각형 모서리 둥글기
            randomSeed:int = -1 // 0 이상이면 이 seed로 모양을 고정, -1이면 그릴 때마다 무작위
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

            if (randomSeed >= 0)
            {
                randomSeedState = randomSeed;
                isRandomSeeded = true;
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

            isRandomSeeded = false;
        }

        // 마스크용: 사각형 가장자리를 안쪽으로만 불규칙하게 깎아서 손으로 그린 듯 해진 모양으로 채움.
        // 바깥으로는 나가지 않아서 원래 사각형 범위 안에 머물고, 같은 seed는 항상 같은 모양이 나옴.
        // 깎임 값을 변의 절대 위치(위/아래 변은 x, 왼쪽/오른쪽 변은 y)로 정해서, 너비나 높이가 바뀌어도 겹치는 부분의 모양은 그대로임.
        // erosionScale은 깎이는 두께에 곱하는 배율(1.0이 기본). 모양은 그대로이고 깊이만 달라짐
        public static function drawWornRectFill(
            graphics:Graphics,
            width:Number,
            height:Number,
            seed:uint,
            erosionScale:Number = 1.0
        ):void
        {
            const outlinePointList:Vector.<Number> = new Vector.<Number>();

            // 시계 방향 네 변: 위(왼→오), 오른쪽(위→아래), 아래(오→왼), 왼쪽(아래→위). 각 변은 안쪽 방향(inward)으로 깎임
            appendWornEdgePoints(outlinePointList, seed, 0, false, 0, 0, 1, 0, 0, 1, width, erosionScale);
            appendWornEdgePoints(outlinePointList, seed, 1, false, width, 0, 0, 1, -1, 0, height, erosionScale);
            appendWornEdgePoints(outlinePointList, seed, 2, true, width, height, -1, 0, 0, -1, width, erosionScale);
            appendWornEdgePoints(outlinePointList, seed, 3, true, 0, height, 0, -1, 1, 0, height, erosionScale);

            graphics.beginFill(0);
            graphics.moveTo(outlinePointList[0], outlinePointList[1]);

            for (var i:int = 2; i < outlinePointList.length; i += 2)
            {
                graphics.lineTo(outlinePointList[i], outlinePointList[i + 1]);
            }

            graphics.endFill();
        }

        // 사각형 한 변을 1.5px 간격으로 훑으면서 안쪽(inwardX, inwardY 방향)으로 깎인 점을 outlinePointList에 이어 붙임.
        // isEdgeReversed는 변을 훑는 방향이 좌표 축과 반대(아래 변, 왼쪽 변)일 때 true. 깎임 값은 축 좌표 기준이라 변 길이가 달라져도 같은 자리는 같은 값
        private static function appendWornEdgePoints(
            outlinePointList:Vector.<Number>,
            seed:uint,
            edgeId:int,
            isEdgeReversed:Boolean,
            startX:Number,
            startY:Number,
            dirX:Number,
            dirY:Number,
            inwardX:Number,
            inwardY:Number,
            edgeLength:Number,
            erosionScale:Number
        ):void
        {
            // 훑는 점을 축 좌표 1.5px 격자에 맞춰서 변 길이가 달라져도 같은 자리의 점은 같은 위치에 찍힘. 반대 방향 변은 시작 모서리 점을 먼저 찍고 격자를 거꾸로 따라감
            const gridCount:int = Math.max(1, Math.ceil(edgeLength / WORN_SAMPLE_SPACING));
            const sampleCount:int = isEdgeReversed ? gridCount + 1 : Math.max(2, gridCount);

            for (var sample:int = 0; sample < sampleCount; sample++)
            {
                var distanceFromEdgeStart:Number = sample * WORN_SAMPLE_SPACING;

                if (isEdgeReversed)
                {
                    distanceFromEdgeStart = (sample === 0) ? 0 : edgeLength - (gridCount - sample) * WORN_SAMPLE_SPACING;
                }

                const axisPosition:Number = isEdgeReversed ? edgeLength - distanceFromEdgeStart : distanceFromEdgeStart;

                const baseN:Number = sampleWornNoise(seed, edgeId, 0, axisPosition / WORN_BASE_SPACING);
                const fineN:Number = sampleWornNoise(seed, edgeId, 1, axisPosition / WORN_FINE_SPACING);

                // 0~1로 맞춘 뒤 제곱해서 대부분은 얕게 깎이고 가끔 깊게 파이게 함
                const wear:Number = Math.max(0.0, Math.min(1.0, 0.5 + baseN * WORN_BASE_WEIGHT + fineN * WORN_FINE_WEIGHT));
                var erosion:Number = WORN_MAX_EROSION * wear * wear;

                // 모서리 가까이는 둥글게 깎음
                const distanceFromEdgeEnd:Number = Math.min(distanceFromEdgeStart, edgeLength - distanceFromEdgeStart);

                if (distanceFromEdgeEnd < WORN_CORNER_RADIUS)
                {
                    const cornerRatio:Number = 1.0 - distanceFromEdgeEnd / WORN_CORNER_RADIUS;
                    erosion += WORN_CORNER_RADIUS * cornerRatio * cornerRatio;
                }

                erosion *= erosionScale;

                outlinePointList.push(
                    startX + dirX * distanceFromEdgeStart + inwardX * erosion,
                    startY + dirY * distanceFromEdgeStart + inwardY * erosion
                );
            }
        }

        // 변 위치(제어점 단위 position)에서의 깎임 노이즈(-1~1). 제어점 값은 seed, 변 번호, 층(0 큰 굴곡, 1 잔떨림), 제어점 번호로만 정해져서 길이와 상관없음
        private static function sampleWornNoise(seed:uint, edgeId:int, layer:int, position:Number):Number
        {
            const segment:int = Math.floor(position);
            const localT:Number = position - segment;

            return catmullRom(
                wornControlValue(seed, edgeId, layer, segment - 1),
                wornControlValue(seed, edgeId, layer, segment),
                wornControlValue(seed, edgeId, layer, segment + 1),
                wornControlValue(seed, edgeId, layer, segment + 2),
                localT
            );
        }

        // seed, 변 번호, 층, 제어점 번호에서 뽑은 고정 난수(-1~1)
        private static function wornControlValue(seed:uint, edgeId:int, layer:int, controlIndex:int):Number
        {
            var hashState:Number = mixWornHash(seed + 1);
            hashState = mixWornHash(hashState + edgeId * 977 + 1);
            hashState = mixWornHash(hashState + layer * 131 + 7);
            hashState = mixWornHash(hashState + controlIndex + 100000);
            hashState = mixWornHash(hashState);
            return (hashState / 4294967296) * 2.0 - 1.0;
        }

        // 해시 한 단계: LCG에 상위 비트를 섞음. 곱셈 결과가 2^53 안에 들어오도록 입력을 2^32 미만으로 맞춤
        private static function mixWornHash(value:Number):Number
        {
            const input:uint = uint(value % 4294967296);
            const scrambled:uint = input ^ (input >>> 15);
            return (scrambled * 1664525 + 1013904223) % 4294967296;
        }

        // 난수 한 개(0~1). drawRect에 randomSeed가 있으면 seed에서 만든 같은 순서의 값, 그 외에는 Math.random
        private static function nextRandom():Number
        {
            if (!isRandomSeeded)
            {
                return Math.random();
            }

            randomSeedState = (randomSeedState * 1664525 + 1013904223) % 4294967296;
            return randomSeedState / 4294967296;
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
                arr[i] = nextRandom() * 2.0 - 1.0;
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
