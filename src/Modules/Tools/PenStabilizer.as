package Modules.Tools
{
	// 펜 손떨림 보정 (시간 + 경로 길이 이동 평균 스태빌라이저)
	// 입력 경로를 SAMPLE_SPACING 간격으로 다시 샘플링하고 각 샘플에 입력 시간을 붙여서 보관함
	// 실제로 그려줄 좌표는 "최근 windowTime(ms) 이내" 이면서 "최근 windowLength(px) 이내"인 샘플들의 평균
	//
	// 느리게 그릴때: 시간 범위가 먼저 차서 평균 범위가 짧아짐 → 선이 커서에 가깝게 붙어서 따라오고 꺾는 곳이 날카롭게 남음
	// 빠르게 그릴때: 경로 길이 범위가 먼저 차서 평균 범위가 windowLength로 제한됨 → 곡선을 따라가되 둥글어지는 정도에 상한이 있음
	// 멈췄을때: 시간이 지나면서 오래된 샘플이 빠지므로 따로 판단하지 않아도 선이 커서까지 따라옴
	// 급하게 꺾일때(CORNER_ANGLE 이하): 앞뒤 CORNER_SPAN개 샘플로 판단해서 꼭짓점까지 선을 확정하고 새로 평균을 냄
	//
	// 지나온 입력 경로를 버리지 않고 평균을 내기 때문에 빠르게 휘두른 곡선도 그 경로를 따라감
	// 선이 커서를 늦게 따라가는 구간은 PenTool에서 미리보기(getPreview)로 채워줌
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
		private static var windowTime:Number = 0;

		// 모서리 판단을 위해 평균 버퍼에 넣기 전에 잠시 보관하는 샘플 (queueIndex 앞은 이미 넣은 샘플, 뒤는 아직 안넣은 샘플)
		private static const queueX:Vector.<Number> = new Vector.<Number>();
		private static const queueY:Vector.<Number> = new Vector.<Number>();
		private static const queueTime:Vector.<Number> = new Vector.<Number>();
		private static var queueIndex:int;
		private static var cornerCooldown:int; // 모서리를 확정한 뒤 같은 모서리를 다시 판단하지 않도록 건너뛸 샘플 개수

		private static var lastInputX:Number = 0;
		private static var lastInputY:Number = 0;
		private static var lastInputTime:Number = 0;
		private static var lastSampleX:Number = 0; // 마지막으로 다시 샘플링한 좌표
		private static var lastSampleY:Number = 0;
		private static var isSettled:Boolean; // 선이 커서(lastInput)에 도착한 상태
		private static var previewChanged:Boolean; // 커서가 움직여서 미리보기를 다시 그려야 하는지

		// getPreview에서 상태를 되돌리기 위한 백업
		private static const backupSampleX:Vector.<Number> = new Vector.<Number>();
		private static const backupSampleY:Vector.<Number> = new Vector.<Number>();
		private static const backupSampleTime:Vector.<Number> = new Vector.<Number>();
		private static const backupQueueX:Vector.<Number> = new Vector.<Number>();
		private static const backupQueueY:Vector.<Number> = new Vector.<Number>();
		private static const backupQueueTime:Vector.<Number> = new Vector.<Number>();

		// penSmoothValue(0.85 ~ 0.02, 작을수록 강함)를 슬라이더 단계에 비례하는 0 ~ 1 강도로 바꿈
		private static function getStrength(smoothValue:Number):Number
		{
			if (!(smoothValue > 0) || smoothValue >= 0.85)
			{
				return 0;
			}

			return Math.min(1, (0.85 - smoothValue) / (0.85 - 0.02));
		}

		public static function getWindowLength(smoothValue:Number):Number
		{
			return MAX_WINDOW_LENGTH * getStrength(smoothValue);
		}

		public static function getWindowTime(smoothValue:Number):Number
		{
			return MAX_WINDOW_TIME * getStrength(smoothValue);
		}

		public static function reset(x:Number, y:Number, time:Number, windowLength:Number, windowTimeValue:Number):void
		{
			const count:int = Math.round(windowLength / SAMPLE_SPACING);
			sampleCapacity = (count < 1) ? 1 : count;
			sampleX.length = sampleCapacity;
			sampleY.length = sampleCapacity;
			sampleTime.length = sampleCapacity;
			sampleStart = 0;
			sampleCount = 0;
			sampleSumX = 0;
			sampleSumY = 0;
			windowTime = windowTimeValue;
			addSample(x, y, time);

			// 시작점은 이미 평균 버퍼에 들어간 샘플로 둠 (모서리 판단할때 지나온 방향으로 사용)
			queueX.length = 0;
			queueY.length = 0;
			queueTime.length = 0;
			queueX.push(x);
			queueY.push(y);
			queueTime.push(time);
			queueIndex = 1;
			cornerCooldown = 0;

			lastInputX = x;
			lastInputY = y;
			lastInputTime = time;
			lastSampleX = x;
			lastSampleY = y;
			isSettled = true;
			previewChanged = true;
		}

		// 마지막 샘플에서 SAMPLE_SPACING 이상 떨어진 경로를 일정 간격으로 나눠서 넣어줌
		// 나눈 샘플의 시간은 이전 입력 시간과 이번 입력 시간 사이를 거리 비율로 나눠서 정함
		public static function addInput(x:Number, y:Number, time:Number):void
		{
			if (x === lastInputX && y === lastInputY)
			{
				return;
			}

			const prevTime:Number = lastInputTime;
			const inputDX:Number = x - lastInputX;
			const inputDY:Number = y - lastInputY;
			const inputDist:Number = Math.sqrt(inputDX * inputDX + inputDY * inputDY);

			lastInputX = x;
			lastInputY = y;
			lastInputTime = time;
			isSettled = false;
			previewChanged = true;

			const dx:Number = x - lastSampleX;
			const dy:Number = y - lastSampleY;
			const dist:Number = Math.sqrt(dx * dx + dy * dy);

			if (dist < SAMPLE_SPACING)
			{
				return;
			}

			const steps:int = Math.floor(dist / SAMPLE_SPACING);
			const stepX:Number = dx / dist * SAMPLE_SPACING;
			const stepY:Number = dy / dist * SAMPLE_SPACING;

			for (var i:int = 1; i <= steps; i++)
			{
				const sx:Number = lastSampleX + stepX * i;
				const sy:Number = lastSampleY + stepY * i;

				// 이번 입력 선분에서 샘플이 떨어진 거리 비율로 시간을 보간함
				const remainX:Number = x - sx;
				const remainY:Number = y - sy;
				const remain:Number = Math.sqrt(remainX * remainX + remainY * remainY);
				const ratio:Number = (inputDist > 0) ? Math.max(0, Math.min(1, 1 - remain / inputDist)) : 1;

				queueX.push(sx);
				queueY.push(sy);
				queueTime.push(prevTime + (time - prevTime) * ratio);
			}

			lastSampleX += stepX * steps;
			lastSampleY += stepY * steps;
		}

		// 한 프레임에 한번 호출, 새로 그려줄 좌표를 output에 x, y 순서로 추가함
		// time은 getTimer() 값, 시간이 지나 범위를 벗어난 샘플을 빼서 선이 커서를 따라오게 함
		public static function update(output:Vector.<Number>, time:Number):void
		{
			processQueue(output, false, time);

			// 모서리 판단 때문에 기다리는 샘플이 있으면 마지막으로 넣은 샘플 시간 기준으로 오래된 샘플을 뺌
			// 현재 시간 기준으로 빼면 기다린 시간만큼 평균 범위가 짧아짐, 기다리는 샘플이 없으면(커서가 멈춤) 현재 시간 기준으로 빼서 커서까지 따라오게 함
			const expireTime:Number = (queueIndex < queueX.length) ? queueTime[queueIndex - 1] : time;

			expireSamples(expireTime, output);

			// 커서가 멈춰서 샘플이 하나만 남았으면 커서 위치에 맞춤
			if (sampleCount === 1 && queueIndex === queueX.length)
			{
				settle(output);
			}
		}

		// 마우스 up 할 때 호출, 남은 입력을 처리하고 오래된 샘플부터 하나씩 빼면서 커서 위치까지 도착하는 좌표를 전부 output에 추가함
		public static function finish(output:Vector.<Number>):void
		{
			processQueue(output, true, lastInputTime);
			drainSamples(output);
			settle(output);
		}

		public static function isPreviewChanged():Boolean
		{
			return previewChanged;
		}

		// 지금 마우스를 떼면 그려질 좌표를 output에 추가함
		// finish를 그대로 실행한 뒤 상태를 되돌리기 때문에 미리보기와 실제로 확정되는 선이 항상 같음
		public static function getPreview(output:Vector.<Number>):void
		{
			previewChanged = false;

			copyVector(sampleX, backupSampleX);
			copyVector(sampleY, backupSampleY);
			copyVector(sampleTime, backupSampleTime);
			copyVector(queueX, backupQueueX);
			copyVector(queueY, backupQueueY);
			copyVector(queueTime, backupQueueTime);
			const start:int = sampleStart;
			const count:int = sampleCount;
			const sumX:Number = sampleSumX;
			const sumY:Number = sampleSumY;
			const settled:Boolean = isSettled;
			const index:int = queueIndex;
			const cooldown:int = cornerCooldown;
			const sampleXLast:Number = lastSampleX;
			const sampleYLast:Number = lastSampleY;

			finish(output);

			copyVector(backupSampleX, sampleX);
			copyVector(backupSampleY, sampleY);
			copyVector(backupSampleTime, sampleTime);
			copyVector(backupQueueX, queueX);
			copyVector(backupQueueY, queueY);
			copyVector(backupQueueTime, queueTime);
			sampleStart = start;
			sampleCount = count;
			sampleSumX = sumX;
			sampleSumY = sumY;
			isSettled = settled;
			queueIndex = index;
			cornerCooldown = cooldown;
			lastSampleX = sampleXLast;
			lastSampleY = sampleYLast;
		}

		// 보관중인 샘플 중 앞쪽으로 CORNER_SPAN개가 모였거나 CORNER_WAIT_TIME이 지난 샘플부터 평균 버퍼에 넣어줌 (isFinish면 전부 넣어줌)
		private static function processQueue(output:Vector.<Number>, isFinish:Boolean, time:Number):void
		{
			while (queueIndex < queueX.length)
			{
				if (!isFinish && queueX.length - 1 - queueIndex < CORNER_SPAN && queueTime[queueIndex] > time - CORNER_WAIT_TIME)
				{
					break;
				}

				if (cornerCooldown > 0)
				{
					cornerCooldown--;
					pushQueuedSample(output);
					continue;
				}

				const cornerIndex:int = findCornerIndex(queueIndex);

				if (cornerIndex < 0)
				{
					pushQueuedSample(output);
					continue;
				}

				// 꼭짓점까지 넣고 오래된 샘플을 빼면서 선이 꼭짓점에 정확히 닿게 함
				while (queueIndex <= cornerIndex)
				{
					pushQueuedSample(output);
				}

				drainSamples(output);
				cornerCooldown = CORNER_SPAN;
			}

			// 모서리 판단에 필요한 지나온 샘플 CORNER_SPAN개만 남기고 지움
			const removeCount:int = queueIndex - CORNER_SPAN;

			if (removeCount > 0)
			{
				queueX.splice(0, removeCount);
				queueY.splice(0, removeCount);
				queueTime.splice(0, removeCount);
				queueIndex -= removeCount;
			}
		}

		// index 샘플에서 CORNER_ANGLE 이하로 꺾이면 꼭짓점 샘플 index를 돌려줌, 아니면 -1
		private static function findCornerIndex(index:int):int
		{
			const past:int = Math.min(CORNER_SPAN, index);
			const future:int = Math.min(CORNER_SPAN, queueX.length - 1 - index);

			// 획 시작이나 끝이라서 양쪽 방향을 충분히 알 수 없으면 판단하지 않음
			if (past * 2 < CORNER_SPAN || future * 2 < CORNER_SPAN)
			{
				return -1;
			}

			const a:int = index - past;
			const b:int = index + future;
			const inX:Number = queueX[index] - queueX[a];
			const inY:Number = queueY[index] - queueY[a];
			const outX:Number = queueX[b] - queueX[index];
			const outY:Number = queueY[b] - queueY[index];
			const inLength:Number = Math.sqrt(inX * inX + inY * inY);
			const outLength:Number = Math.sqrt(outX * outX + outY * outY);
			// 양쪽이 거의 곧게 뻗은 경우만 모서리로 봄 (샘플 간격이 일정하므로 경로 길이 대비 직선 거리로 판단)
			// 느리게 그릴때 손떨림으로 생긴 작은 지그재그는 직선 거리가 짧아서 모서리로 보지 않음
			const minInLength:Number = SAMPLE_SPACING * past * 0.8;
			const minOutLength:Number = SAMPLE_SPACING * future * 0.8;

			if (inLength < minInLength || outLength < minOutLength)
			{
				return -1;
			}

			// 들어온 방향을 뒤집은 벡터와 나가는 방향 사이의 각도가 모서리 안쪽 각도임
			const cos:Number = -(inX * outX + inY * outY) / (inLength * outLength);

			if (cos < CORNER_COS)
			{
				return -1;
			}

			// 꼭짓점은 양 끝(a, b)까지 거리의 합이 가장 큰 샘플로 정함 (아직 버퍼에 안넣은 index 이후에서만 찾음)
			var cornerIndex:int = index;
			var maxDist:Number = -1;

			for (var i:int = index; i <= b; i++)
			{
				const dax:Number = queueX[i] - queueX[a];
				const day:Number = queueY[i] - queueY[a];
				const dbx:Number = queueX[i] - queueX[b];
				const dby:Number = queueY[i] - queueY[b];
				const dist:Number = Math.sqrt(dax * dax + day * day) + Math.sqrt(dbx * dbx + dby * dby);

				if (dist > maxDist)
				{
					maxDist = dist;
					cornerIndex = i;
				}
			}

			return cornerIndex;
		}

		private static function pushQueuedSample(output:Vector.<Number>):void
		{
			const time:Number = queueTime[queueIndex];
			expireSamples(time, output);
			addSample(queueX[queueIndex], queueY[queueIndex], time);
			pushAverage(output);
			queueIndex++;
		}

		// 오래된 샘플부터 하나씩 빼면서 평균을 output에 추가함, 가장 최근 샘플 하나만 남음
		private static function drainSamples(output:Vector.<Number>):void
		{
			while (sampleCount > 1)
			{
				removeOldestSample();
				pushAverage(output);
			}
		}

		private static function addSample(x:Number, y:Number, time:Number):void
		{
			// 경로 길이 범위가 가득 차면 가장 오래된 샘플을 뺌
			if (sampleCount === sampleCapacity)
			{
				removeOldestSample();
			}

			const index:int = (sampleStart + sampleCount) % sampleCapacity;
			sampleX[index] = x;
			sampleY[index] = y;
			sampleTime[index] = time;
			sampleCount++;
			sampleSumX += x;
			sampleSumY += y;
		}

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

		// time 기준으로 windowTime보다 오래된 샘플을 뺌 (가장 최근 샘플 하나는 남김)
		// 하나 뺄 때마다 평균을 output에 추가함, 여러 개를 한꺼번에 빼고 평균을 한 번만 내면
		// 커서가 느려지거나 멈췄다 움직일때 선이 곡선을 따라가지 않고 직선으로 건너뛰어서 미리보기와 다른 모양이 남음
		private static function expireSamples(time:Number, output:Vector.<Number>):void
		{
			while (sampleCount > 1 && sampleTime[sampleStart] < time - windowTime)
			{
				removeOldestSample();
				pushAverage(output);
			}
		}

		private static function pushAverage(output:Vector.<Number>):void
		{
			output.push(sampleSumX / sampleCount, sampleSumY / sampleCount);
		}

		// 샘플이 하나만 남았을때 호출, 선을 커서 위치에 정확히 맞춤 (마지막 샘플은 커서에서 SAMPLE_SPACING 이내)
		private static function settle(output:Vector.<Number>):void
		{
			if (isSettled)
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
			isSettled = true;
			output.push(lastInputX, lastInputY);
		}

		private static function copyVector(source:Vector.<Number>, target:Vector.<Number>):void
		{
			const len:uint = source.length;
			target.length = len;

			for (var i:uint = 0; i < len; i++)
			{
				target[i] = source[i];
			}
		}
	}
}
