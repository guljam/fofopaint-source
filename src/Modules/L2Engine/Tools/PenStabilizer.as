package Modules.L2Engine.Tools
{
	// 펜 손떨림 보정 (시간 + 경로 길이 이동 평균 스태빌라이저)
	// 입력 경로를 SAMPLE_SPACING 간격으로 다시 샘플링하고 각 샘플에 입력 시간을 붙여서 보관함
	// 실제로 그려줄 좌표는 "최근 averageWindowTimeMs(ms) 이내" 이면서 "최근 windowLength(px) 이내"인 샘플들의 평균
	//
	// 느리게 그릴때: 시간 범위가 먼저 차서 평균 범위가 짧아짐 → 선이 커서에 가깝게 붙어서 따라오고 꺾는 곳이 날카롭게 남음
	// 빠르게 그릴때: 경로 길이 범위가 먼저 차서 평균 범위가 windowLength로 제한됨 → 곡선을 따라가되 둥글어지는 정도에 상한이 있음
	// 멈췄을때: 시간이 지나면서 오래된 샘플이 빠지므로 따로 판단하지 않아도 선이 커서까지 따라옴
	// 급하게 꺾일때(CORNER_ANGLE 이하): 앞뒤 CORNER_SPAN개 샘플로 판단해서 꼭짓점까지 선을 확정하고 새로 평균을 냄
	//
	// 지나온 입력 경로를 버리지 않고 평균을 내기 때문에 빠르게 휘두른 곡선도 그 경로를 따라감
	// 선이 커서를 늦게 따라가는 구간은 PenTool에서 미리보기(getPreviewPoints)로 채워줌
	// 디스플레이 객체에 의존하지 않고 좌표 계산만 함, 그려주는건 PenTool에서 함
	// 층: L2 엔진 - 펜 손떨림 보정 (시간 + 경로 길이 이동 평균)
	public final class PenStabilizer
	{
		public static const SAMPLE_SPACING:Number = 1.0; // 입력 경로를 다시 샘플링하는 간격(px)
		public static const MAX_WINDOW_LENGTH:Number = 100; // 스무딩 최대일때 평균을 내는 최대 경로 길이(px)
		public static const MAX_WINDOW_TIME:Number = 150; // 스무딩 최대일때 평균을 내는 최대 시간(ms)
		public static const CORNER_SPAN:int = 10; // 모서리를 판단할 때 앞뒤로 보는 샘플 개수
		public static const CORNER_ANGLE:Number = 55; // 이 각도(도) 이하로 꺾이면 모서리로 판단
		public static const CORNER_WAIT_TIME:Number = 50; // 앞쪽 샘플이 모이지 않아도 이 시간(ms)이 지나면 평균에 넣음 (커서가 멈췄을때 선이 멈추지 않게)

		private static const CORNER_COS:Number = Math.cos(CORNER_ANGLE * Math.PI / 180);

		// 평균을 내는 샘플 원형 버퍼 (sampleStart부터 sampleCount개)
		private static const sampleX:Vector.<Number> = new Vector.<Number>();
		private static const sampleY:Vector.<Number> = new Vector.<Number>();
		private static const sampleTime:Vector.<Number> = new Vector.<Number>();
		private static var sampleCapacity:int = 1;
		private static var sampleStart:int;
		private static var sampleCount:int;
		private static var sampleSumX:Number = 0;
		private static var sampleSumY:Number = 0;
		private static var averageWindowTimeMs:Number = 0;

		// 모서리 판단을 위해 평균 버퍼에 넣기 전에 잠시 보관하는 샘플 (queueNextSampleIndex 앞은 이미 넣은 샘플, 뒤는 아직 안넣은 샘플)
		private static const queueX:Vector.<Number> = new Vector.<Number>();
		private static const queueY:Vector.<Number> = new Vector.<Number>();
		private static const queueTime:Vector.<Number> = new Vector.<Number>();
		private static var queueNextSampleIndex:int;
		private static var cornerCooldownSampleCount:int; // 모서리를 확정한 뒤 같은 모서리를 다시 판단하지 않도록 건너뛸 샘플 개수

		private static var lastInputX:Number = 0;
		private static var lastInputY:Number = 0;
		private static var lastInputTime:Number = 0;
		private static var lastSampleX:Number = 0; // 마지막으로 다시 샘플링한 좌표
		private static var lastSampleY:Number = 0;
		private static var isSettledAtLastInput:Boolean; // 선이 커서(lastInput)에 도착한 상태
		private static var isPreviewChangedFlag:Boolean; // 커서가 움직여서 미리보기를 다시 그려야 하는지

		// getPreviewPoints에서 상태를 되돌리기 위한 백업
		private static const backupSampleX:Vector.<Number> = new Vector.<Number>();
		private static const backupSampleY:Vector.<Number> = new Vector.<Number>();
		private static const backupSampleTime:Vector.<Number> = new Vector.<Number>();
		private static var isPreviewing:Boolean; // getPreviewPoints 안에서 finishStrokeAndAppendRemainingPoints를 돌리는 중, 대기열 앞쪽 정리를 건너뜀 (대기열 내용을 그대로 두어 queueNextSampleIndex만 되돌리면 됨)

		// penSmoothValue(0.85 ~ 0.02, 작을수록 강함)를 슬라이더 단계에 비례하는 0 ~ 1 강도로 바꿈
		private static function getSmoothStrength(penSmoothValue:Number):Number
		{
			if (!(penSmoothValue > 0) || penSmoothValue >= 0.85)
			{
				return 0;
			}

			return Math.min(1, (0.85 - penSmoothValue) / (0.85 - 0.02));
		}

		// 스무딩 값에 맞는 평균 경로 길이 범위(px)
		public static function getWindowLengthFromSmoothValue(penSmoothValue:Number):Number
		{
			return MAX_WINDOW_LENGTH * getSmoothStrength(penSmoothValue);
		}

		// 스무딩 값에 맞는 평균 시간 범위(ms)
		public static function getWindowTimeFromSmoothValue(penSmoothValue:Number):Number
		{
			return MAX_WINDOW_TIME * getSmoothStrength(penSmoothValue);
		}

		public static function resetStabilizerForNewStroke(startX:Number, startY:Number, startTimeMs:Number, windowLengthPx:Number, windowTimeMs:Number):void
		{
			const sampleCountLimit:int = Math.round(windowLengthPx / SAMPLE_SPACING);
			sampleCapacity = (sampleCountLimit < 1) ? 1 : sampleCountLimit;
			sampleX.length = sampleCapacity;
			sampleY.length = sampleCapacity;
			sampleTime.length = sampleCapacity;
			sampleStart = 0;
			sampleCount = 0;
			sampleSumX = 0;
			sampleSumY = 0;
			averageWindowTimeMs = windowTimeMs;
			addSampleToAverageBuffer(startX, startY, startTimeMs);

			// 시작점은 이미 평균 버퍼에 들어간 샘플로 둠 (모서리 판단할때 지나온 방향으로 사용)
			queueX.length = 0;
			queueY.length = 0;
			queueTime.length = 0;
			queueX.push(startX);
			queueY.push(startY);
			queueTime.push(startTimeMs);
			queueNextSampleIndex = 1;
			cornerCooldownSampleCount = 0;

			lastInputX = startX;
			lastInputY = startY;
			lastInputTime = startTimeMs;
			lastSampleX = startX;
			lastSampleY = startY;
			isSettledAtLastInput = true;
			isPreviewChangedFlag = true;
		}

		// 마지막 샘플에서 SAMPLE_SPACING 이상 떨어진 경로를 일정 간격으로 나눠서 넣어줌
		// 나눈 샘플의 시간은 이전 입력 시간과 이번 입력 시간 사이를 거리 비율로 나눠서 정함
		public static function addStrokeInputPoint(inputX:Number, inputY:Number, inputTimeMs:Number):void
		{
			if (inputX === lastInputX && inputY === lastInputY)
			{
				return;
			}

			const previousInputTimeMs:Number = lastInputTime;
			const inputDX:Number = inputX - lastInputX;
			const inputDY:Number = inputY - lastInputY;
			const inputDist:Number = Math.sqrt(inputDX * inputDX + inputDY * inputDY);

			lastInputX = inputX;
			lastInputY = inputY;
			lastInputTime = inputTimeMs;
			isSettledAtLastInput = false;
			isPreviewChangedFlag = true;

			const dx:Number = inputX - lastSampleX;
			const dy:Number = inputY - lastSampleY;
			const dist:Number = Math.sqrt(dx * dx + dy * dy);

			if (dist < SAMPLE_SPACING)
			{
				return;
			}

			const resampleStepCount:int = Math.floor(dist / SAMPLE_SPACING);
			const stepX:Number = dx / dist * SAMPLE_SPACING;
			const stepY:Number = dy / dist * SAMPLE_SPACING;

			for (var i:int = 1; i <= resampleStepCount; i++)
			{
				const resampledX:Number = lastSampleX + stepX * i;
				const resampledY:Number = lastSampleY + stepY * i;

				// 이번 입력 선분에서 샘플이 떨어진 거리 비율로 시간을 보간함
				// 샘플은 lastSample → (inputX, inputY) 직선 위에 SAMPLE_SPACING 간격으로 있으므로 커서까지 남은 거리를 바로 구함
				const remainingDistanceToInput:Number = dist - SAMPLE_SPACING * i;
				var ratio:Number = (inputDist > 0) ? 1 - remainingDistanceToInput / inputDist : 1;
				ratio = (ratio < 0) ? 0 : (ratio > 1) ? 1 : ratio;

				const queueLength:uint = queueX.length;
				queueX[queueLength] = resampledX;
				queueY[queueLength] = resampledY;
				queueTime[queueLength] = previousInputTimeMs + (inputTimeMs - previousInputTimeMs) * ratio;
			}

			lastSampleX += stepX * resampleStepCount;
			lastSampleY += stepY * resampleStepCount;
		}

		// 한 프레임에 한번 호출, 새로 그려줄 좌표를 outStabilizedPoints에 inputX, inputY 순서로 추가함
		// inputTimeMs은 getTimer() 값, 시간이 지나 범위를 벗어난 샘플을 빼서 선이 커서를 따라오게 함
		public static function appendStabilizedPointsForFrame(outStabilizedPoints:Vector.<Number>, nowTimeMs:Number):void
		{
			moveQueuedSamplesToAverageBuffer(outStabilizedPoints, false, nowTimeMs);

			// 모서리 판단 때문에 기다리는 샘플이 있으면 마지막으로 넣은 샘플 시간 기준으로 오래된 샘플을 뺌
			// 현재 시간 기준으로 빼면 기다린 시간만큼 평균 범위가 짧아짐, 기다리는 샘플이 없으면(커서가 멈춤) 현재 시간 기준으로 빼서 커서까지 따라오게 함
			const expireTime:Number = (queueNextSampleIndex < queueX.length) ? queueTime[queueNextSampleIndex - 1] : nowTimeMs;

			expireSamplesOlderThanWindowTime(expireTime, outStabilizedPoints);

			// 커서가 멈춰서 샘플이 하나만 남았으면 커서 위치에 맞춤
			if (sampleCount === 1 && queueNextSampleIndex === queueX.length)
			{
				settleStrokeAtLastInput(outStabilizedPoints);
			}
		}

		// 마우스 up 할 때 호출, 남은 입력을 처리하고 오래된 샘플부터 하나씩 빼면서 커서 위치까지 도착하는 좌표를 전부 outStabilizedPoints에 추가함
		public static function finishStrokeAndAppendRemainingPoints(outStabilizedPoints:Vector.<Number>):void
		{
			moveQueuedSamplesToAverageBuffer(outStabilizedPoints, true, lastInputTime);
			drainOldSamplesUntilLatestRemains(outStabilizedPoints);
			settleStrokeAtLastInput(outStabilizedPoints);
		}

		// 커서가 움직여서 미리보기를 다시 그려야 하는지
		public static function isPreviewChanged():Boolean
		{
			return isPreviewChangedFlag;
		}

		// 지금 마우스를 떼면 그려질 좌표를 outPreviewPoints에 추가함
		// finishStrokeAndAppendRemainingPoints를 그대로 실행한 뒤 상태를 되돌리기 때문에 미리보기와 실제로 확정되는 선이 항상 같음
		public static function getPreviewPoints(outPreviewPoints:Vector.<Number>):void
		{
			isPreviewChangedFlag = false;

			const savedSampleStart:int = sampleStart;
			const savedSampleCount:int = sampleCount;
			var i:int;

			// 샘플 버퍼는 sampleStart부터 sampleCount개 칸만 읽히므로 그 구간만 백업함
			backupSampleX.length = savedSampleCount;
			backupSampleY.length = savedSampleCount;
			backupSampleTime.length = savedSampleCount;

			for (i = 0; i < savedSampleCount; i++)
			{
				const backupIndex:int = (savedSampleStart + i) % sampleCapacity;
				backupSampleX[i] = sampleX[backupIndex];
				backupSampleY[i] = sampleY[backupIndex];
				backupSampleTime[i] = sampleTime[backupIndex];
			}

			const savedSampleSumX:Number = sampleSumX;
			const savedSampleSumY:Number = sampleSumY;
			const savedIsSettled:Boolean = isSettledAtLastInput;
			const savedQueueNextSampleIndex:int = queueNextSampleIndex;
			const savedCornerCooldownSampleCount:int = cornerCooldownSampleCount;
			const savedLastSampleX:Number = lastSampleX;
			const savedLastSampleY:Number = lastSampleY;

			isPreviewing = true;
			finishStrokeAndAppendRemainingPoints(outPreviewPoints);
			isPreviewing = false;

			for (i = 0; i < savedSampleCount; i++)
			{
				const restoreIndex:int = (savedSampleStart + i) % sampleCapacity;
				sampleX[restoreIndex] = backupSampleX[i];
				sampleY[restoreIndex] = backupSampleY[i];
				sampleTime[restoreIndex] = backupSampleTime[i];
			}

			sampleStart = savedSampleStart;
			sampleCount = savedSampleCount;
			sampleSumX = savedSampleSumX;
			sampleSumY = savedSampleSumY;
			isSettledAtLastInput = savedIsSettled;
			queueNextSampleIndex = savedQueueNextSampleIndex;
			cornerCooldownSampleCount = savedCornerCooldownSampleCount;
			lastSampleX = savedLastSampleX;
			lastSampleY = savedLastSampleY;
		}

		// 보관중인 샘플 중 앞쪽으로 CORNER_SPAN개가 모였거나 CORNER_WAIT_TIME이 지난 샘플부터 평균 버퍼에 넣어줌 (isFinishing면 전부 넣어줌)
		private static function moveQueuedSamplesToAverageBuffer(outStabilizedPoints:Vector.<Number>, isFinishing:Boolean, timeMs:Number):void
		{
			while (queueNextSampleIndex < queueX.length)
			{
				if (!isFinishing && queueX.length - 1 - queueNextSampleIndex < CORNER_SPAN && queueTime[queueNextSampleIndex] > timeMs - CORNER_WAIT_TIME)
				{
					break;
				}

				if (cornerCooldownSampleCount > 0)
				{
					cornerCooldownSampleCount--;
					pushNextQueuedSampleToAverage(outStabilizedPoints);
					continue;
				}

				const cornerIndex:int = findCornerSampleIndex(queueNextSampleIndex);

				if (cornerIndex < 0)
				{
					pushNextQueuedSampleToAverage(outStabilizedPoints);
					continue;
				}

				// 꼭짓점까지 넣고 오래된 샘플을 빼면서 선이 꼭짓점에 정확히 닿게 함
				while (queueNextSampleIndex <= cornerIndex)
				{
					pushNextQueuedSampleToAverage(outStabilizedPoints);
				}

				drainOldSamplesUntilLatestRemains(outStabilizedPoints);
				cornerCooldownSampleCount = CORNER_SPAN;
			}

			// 모서리 판단에 필요한 지나온 샘플 CORNER_SPAN개만 남기고 지움 (미리보기 중에는 대기열을 건드리지 않음)
			const removeCount:int = queueNextSampleIndex - CORNER_SPAN;

			if (removeCount > 0 && !isPreviewing)
			{
				// splice는 잘라낸 원소를 담은 새 Vector를 만들기 때문에 앞으로 당기고 length만 줄임
				const remain:int = queueX.length - removeCount;

				for (var i:int = 0; i < remain; i++)
				{
					queueX[i] = queueX[i + removeCount];
					queueY[i] = queueY[i + removeCount];
					queueTime[i] = queueTime[i + removeCount];
				}

				queueX.length = remain;
				queueY.length = remain;
				queueTime.length = remain;
				queueNextSampleIndex -= removeCount;
			}
		}

		// index 샘플에서 CORNER_ANGLE 이하로 꺾이면 꼭짓점 샘플 index를 돌려줌, 아니면 -1
		private static function findCornerSampleIndex(index:int):int
		{
			const pastSpanCount:int = Math.min(CORNER_SPAN, index);
			const futureSpanCount:int = Math.min(CORNER_SPAN, queueX.length - 1 - index);

			// 획 시작이나 끝이라서 양쪽 방향을 충분히 알 수 없으면 판단하지 않음
			if (pastSpanCount * 2 < CORNER_SPAN || futureSpanCount * 2 < CORNER_SPAN)
			{
				return -1;
			}

			const incomingStartIndex:int = index - pastSpanCount;
			const outgoingEndIndex:int = index + futureSpanCount;
			const inX:Number = queueX[index] - queueX[incomingStartIndex];
			const inY:Number = queueY[index] - queueY[incomingStartIndex];
			const outX:Number = queueX[outgoingEndIndex] - queueX[index];
			const outY:Number = queueY[outgoingEndIndex] - queueY[index];
			const inLength:Number = Math.sqrt(inX * inX + inY * inY);
			const outLength:Number = Math.sqrt(outX * outX + outY * outY);
			// 양쪽이 거의 곧게 뻗은 경우만 모서리로 봄 (샘플 간격이 일정하므로 경로 길이 대비 직선 거리로 판단)
			// 느리게 그릴때 손떨림으로 생긴 작은 지그재그는 직선 거리가 짧아서 모서리로 보지 않음
			const minInLength:Number = SAMPLE_SPACING * pastSpanCount * 0.8;
			const minOutLength:Number = SAMPLE_SPACING * futureSpanCount * 0.8;

			if (inLength < minInLength || outLength < minOutLength)
			{
				return -1;
			}

			// 들어온 방향을 뒤집은 벡터와 나가는 방향 사이의 각도가 모서리 안쪽 각도임
			const cornerCosine:Number = -(inX * outX + inY * outY) / (inLength * outLength);

			if (cornerCosine < CORNER_COS)
			{
				return -1;
			}

			// 꼭짓점은 양 끝(incomingStartIndex, outgoingEndIndex)까지 거리의 합이 가장 큰 샘플로 정함 (아직 버퍼에 안넣은 index 이후에서만 찾음)
			var cornerIndex:int = index;
			var maxDist:Number = -1;

			for (var i:int = index; i <= outgoingEndIndex; i++)
			{
				const dax:Number = queueX[i] - queueX[incomingStartIndex];
				const day:Number = queueY[i] - queueY[incomingStartIndex];
				const dbx:Number = queueX[i] - queueX[outgoingEndIndex];
				const dby:Number = queueY[i] - queueY[outgoingEndIndex];
				const dist:Number = Math.sqrt(dax * dax + day * day) + Math.sqrt(dbx * dbx + dby * dby);

				if (dist > maxDist)
				{
					maxDist = dist;
					cornerIndex = i;
				}
			}

			return cornerIndex;
		}

		// 보관 중인 샘플 하나를 평균 버퍼에 넣고, 범위를 벗어난 오래된 샘플을 빼면서 평균을 outStabilizedPoints에 추가함
		private static function pushNextQueuedSampleToAverage(outStabilizedPoints:Vector.<Number>):void
		{
			const sampleTimeMs:Number = queueTime[queueNextSampleIndex];
			expireSamplesOlderThanWindowTime(sampleTimeMs, outStabilizedPoints);
			addSampleToAverageBuffer(queueX[queueNextSampleIndex], queueY[queueNextSampleIndex], sampleTimeMs);
			appendAveragePointToOutput(outStabilizedPoints);
			queueNextSampleIndex++;
		}

		// 오래된 샘플부터 하나씩 빼면서 평균을 outStabilizedPoints에 추가함, 가장 최근 샘플 하나만 남음
		private static function drainOldSamplesUntilLatestRemains(outStabilizedPoints:Vector.<Number>):void
		{
			while (sampleCount > 1)
			{
				removeOldestSample();
				appendAveragePointToOutput(outStabilizedPoints);
			}
		}

		// 평균 버퍼(원형)에 샘플 하나를 추가함
		private static function addSampleToAverageBuffer(newSampleX:Number, newSampleY:Number, newSampleTimeMs:Number):void
		{
			// 경로 길이 범위가 가득 차면 가장 오래된 샘플을 뺌
			if (sampleCount === sampleCapacity)
			{
				removeOldestSample();
			}

			const index:int = (sampleStart + sampleCount) % sampleCapacity;
			sampleX[index] = newSampleX;
			sampleY[index] = newSampleY;
			sampleTime[index] = newSampleTimeMs;
			sampleCount++;
			sampleSumX += newSampleX;
			sampleSumY += newSampleY;
		}

		// 평균 버퍼에서 가장 오래된 샘플 하나를 뺌 (누적합도 같이 갱신)
		private static function removeOldestSample():void
		{
			sampleSumX -= sampleX[sampleStart];
			sampleSumY -= sampleY[sampleStart];
			sampleStart = (sampleStart + 1) % sampleCapacity;
			sampleCount--;

			// 누적합 오차를 없앰
			if (sampleCount === 1)
			{
				sampleSumX = sampleX[sampleStart];
				sampleSumY = sampleY[sampleStart];
			}
			else if (sampleCount === 0)
			{
				sampleSumX = 0;
				sampleSumY = 0;
			}
		}

		// timeMs 기준으로 averageWindowTimeMs보다 오래된 샘플을 뺌 (가장 최근 샘플 하나는 남김)
		// 하나 뺄 때마다 평균을 outStabilizedPoints에 추가함, 여러 개를 한꺼번에 빼고 평균을 한 번만 내면
		// 커서가 느려지거나 멈췄다 움직일때 선이 곡선을 따라가지 않고 직선으로 건너뛰어서 미리보기와 다른 모양이 남음
		private static function expireSamplesOlderThanWindowTime(timeMs:Number, outStabilizedPoints:Vector.<Number>):void
		{
			while (sampleCount > 1 && sampleTime[sampleStart] < timeMs - averageWindowTimeMs)
			{
				removeOldestSample();
				appendAveragePointToOutput(outStabilizedPoints);
			}
		}

		// 지금 평균 버퍼의 평균 좌표를 outStabilizedPoints에 x, y 순서로 추가함
		private static function appendAveragePointToOutput(outStabilizedPoints:Vector.<Number>):void
		{
			const outputLength:uint = outStabilizedPoints.length;
			outStabilizedPoints[outputLength] = sampleSumX / sampleCount;
			outStabilizedPoints[outputLength + 1] = sampleSumY / sampleCount;
		}

		// 샘플이 하나만 남았을때 호출, 선을 커서 위치에 정확히 맞춤 (마지막 샘플은 커서에서 SAMPLE_SPACING 이내)
		private static function settleStrokeAtLastInput(outStabilizedPoints:Vector.<Number>):void
		{
			if (isSettledAtLastInput)
			{
				return;
			}

			// 다음 평균이 커서 위치에서 시작하도록 남은 샘플을 커서 위치로 맞춤
			sampleX[sampleStart] = lastInputX;
			sampleY[sampleStart] = lastInputY;
			sampleSumX = lastInputX;
			sampleSumY = lastInputY;
			// 다시 움직일때 재샘플링도 커서 위치에서 시작해야 함, 마지막 샘플(커서에서 최대 SAMPLE_SPACING 뒤)에서 시작하면 선이 살짝 뒤로 갔다가 나아감
			lastSampleX = lastInputX;
			lastSampleY = lastInputY;
			isSettledAtLastInput = true;
			outStabilizedPoints.push(lastInputX, lastInputY);
		}
	}
}
