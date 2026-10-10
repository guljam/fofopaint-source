package Modules.L4UI.Tools
{
    import Modules.InputPriority;
	import Modules.ReferenceLayerController;

	import flash.display.CapsStyle;
	import flash.display.Graphics;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.display.Shape;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	import Modules.L4UI.ColorPickerController;
	import Modules.L5App.ReplayEngine.ReplayController;
	import Modules.L4UI.PaletteController;
	import Modules.L3Feature.DrawingFinish;
	import Modules.L1Data.Tools.PenSettings;
	import Modules.L4UI.PenSizePreviewCursor;
	import Modules.L2Engine.DrawEngine.CanvasView;
	import Modules.L2Engine.DrawEngine.DrawCanvas;
	import Modules.Tools.PenStabilizer;
	import Modules.L1Data.ColorHistory;
	import Modules.L2Engine.UndoHistory;
	import Modules.L2Engine.ReplayEngine.ReplayState;
	import Modules.L3Feature.DrawEngine.CanvasLayers;
	import Modules.L1Data.MouseState;
	import Modules.L2Engine.DrawEngine.StrokeBuffer;

	// 층: L3 기능 - 펜 그리기와 지우개
	public final class PenTool
	{
		public static var main:Main;
		public static function setMainInstance(instance:Main):void
		{
			main = instance;
		}

		private static const clickPos:Point = new Point(); // 점찍어 줄 때 판단하는 클릭한 자리 저장
		private static const clickPosDot:Point = new Point(); // 점 찍어주는지 검사할때 sharpline offset이 적용된 지점을 비교하는 변수
		private static const smoothPos:Point = new Point(); // 선이 시작되는 좌표 저장 (스무딩 없을때는 마지막 커서 위치)
		private static const stabilizerLastDrawPos:Point = new Point(); // 펜 스무딩에서 마지막으로 선을 그려준 좌표, 너무 촘촘하게 그리지 않기 위해 저장
		private static const stabilizedPoints:Vector.<Number> = new Vector.<Number>(); // 펜 스무딩에서 이번 프레임에 그려줄 좌표
		private static const stabilizerPreviewPoints:Vector.<Number> = new Vector.<Number>(); // 펜 스무딩 미리보기 좌표
		private static const stabilizerPreview:Shape = new Shape(); // 펜 스무딩에서 선이 아직 따라가지 못한 커서까지의 구간을 임시로 보여줌 (replay에 기록 안함)
		private static const moveEventLast:Point = new Point(); // 마우스 move이벤트에서 브러시 크기 필터 해주기 위해 현재 위치 저장
		private static const moveEventDistSave:Point = new Point(); // 마우스 move이벤트에서 브러시 크기 필터 해주기 위해 마지막 위치 저장
		private static const moveEvent2Last:Point = new Point(); // penMove2함수에서 smooth pos를 저장해서 같은 위치면 안그려주기 위해서 마지막 위치를 저장
		private static const sqPenCursorLast:Point = new Point(); // 사각형 커서 각도를 위한 위치저장
		private static const sqLinePosLast:Point = new Point(); // 사각형라인일 때 일정 길이이상 일때만 그려주기 위한 위치
		private static const extendedPos:Point = new Point(); // 사각형라인일 때 양끝점을 약간 확장해주기 위한 위치
		private static const penPoints:Vector.<Number> = new Vector.<Number>(); // 그냥 펜 좌표
		private static const canvasSizeRect:Rectangle = new Rectangle();

		private static var isPenTool:Boolean;
		private static var xSize:uint; // x변수는 pen 또는 erase에서 쓰이는거라서 그럼
		private static var xColor:uint;
		private static var xAlpha:Number;
		private static var xShape:Boolean;
		private static var xBlendMode:String;
		private static var offsetForSharpline:Number; // 경계선 0.5를 조절해서 번지게 보이느냐 샤프하게 보이느냐
		private static var mouseMovedCount:int; // 마우스 이벤트에서 움직일때 올려주는 카운터 한번에 너무 많이 움직여주면 cpu부하 먹어서 100카운트 마다 bmp에 그려줌
		private static var isMouseMoved:Boolean;
		private static var lastMouseMoveDist:Number; // penmove에서 distlimit이하이면 jump해주는거임, 이동시킬때 이 limit을 dist 만큼 빼줌
		private static var dotflag:Boolean; // 펜스무딩이 강하게 들어갔을때 아주 작은 위치만 그려주면 표현이 제대로 안되기 때문에 너무 작게 선이 그려졌을때 올려주는 플래그
		private static var sq1pxCursor:Boolean = false; // 1픽셀 사각형 커서인경우 올려주고 커서 미리보기 회전적용되게 함
		private static var isStabilizerON:Boolean; // 이번 획에 펜 스무딩이 적용되는지
		private static var stabilizerDrawDist:Number; // 펜 스무딩에서 이 거리 이상 움직였을때만 선을 그려줌

		// 샤프라인 펜 스무딩: 꼭짓점이 floor로 정수화되기 때문에 2px마다 찍으면 짧은 선분 기울기가 흔들려서 선이 울퉁불퉁해짐
		// 매끄러운 좌표가 정수화된 직선에서 SHARP_STABILIZER_TOLERANCE 이상 벗어날 때만 꼭짓점을 찍어서 직선 구간은 길게, 휘는 곳은 촘촘하게 그림
		private static const SHARP_STABILIZER_TOLERANCE:Number = 0.5;
		private static const SHARP_STABILIZER_MAX_SEGMENT:Number = 12; // 선이 커서를 너무 늦게 따라가지 않도록 선분 최대 길이
		private static const sharpStabilizerAnchor:Point = new Point(); // 마지막으로 그린 꼭짓점 (정수화된 좌표)
		private static const sharpStabilizerCandidate:Point = new Point(); // 다음 꼭짓점 후보 (정수화된 좌표), 없으면 NaN
		private static const sharpStabilizerPending:Vector.<Number> = new Vector.<Number>(); // anchor 뒤로 아직 안그린 매끄러운 좌표
		private static var isSharpStabilizer:Boolean; // 이번 획이 샤프라인 펜 스무딩인지

		public static var penColor:uint = 0x000000;
		public static var isTransparentPenColor:Boolean = false; // 펜 컬러 투명 켜졌을때 올려줌
		public static var penLastSizeAndShape:Array = [null, null]; // updatePenSizeCursor 중복 사용 방지를 위해서 마지막 크기 저장해놓고 같으면 건너뜀

		public static function getRefinedPoint(mx:Number, my:Number):Point
		{
			mx = Math.round(mx * 100) / 100;
			my = Math.round(my * 100) / 100;
			if (PenSettings.isSharpLineON)
			{
				my = Math.floor(my);
				mx = Math.floor(mx);
			}
			else if (PenSettings.penSmoothSlideValue === 0 && (CanvasView.canvasAnchorPoint.rotation % 90 === 0))
			{
				my = Math.round(my);
				mx = Math.round(mx);
			}
			return new Point(mx, my);
		}

		private static function isCircleRectColliding(cx:Number, cy:Number, r:Number, rx:Number, ry:Number, w:Number, h:Number):Boolean
		{
			const px:Number = Math.max(rx, Math.min(cx, rx + w));
			const py:Number = Math.max(ry, Math.min(cy, ry + h));
			const distance:Number = (Math.sqrt(Math.pow(px - cx, 2) + Math.pow(py - cy, 2)));

			return distance <= r / 2;
		}

		private static function setCanUndoDataFlagON():void
		{
			if (DrawCanvas.canvasLayer1Bitmap.hitTestPoint(main.stage.mouseX, main.stage.mouseY, true))
			{
				UndoHistory.canAddUndoData = true;
			}
			else if (PenSizePreviewCursor.isSqure())
			{
				if (canvasSizeRect.intersects(PenSizePreviewCursor.getCursorBoundsWithCanvasPanel()))
				{
					UndoHistory.canAddUndoData = true;
				}
			}
			else if (isCircleRectColliding(CanvasView.canvasPanel.mouseX, CanvasView.canvasPanel.mouseY, PenSizePreviewCursor.getSize(), 0, 0, DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT))
			{
				UndoHistory.canAddUndoData = true;
			}
		}

		private static function lineStyleReady(shape:Boolean, size:uint, color:uint, alpha:Number):void
		{
			StrokeBuffer.canvasDrawLayer.alpha = alpha;

			if (shape === false)
			{
				StrokeBuffer.canvasDrawLayerChild.graphics.lineStyle(size, color);
			}
			else
			{
				StrokeBuffer.canvasDrawLayerChild.graphics.lineStyle(size, color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.BEVEL);
			}
		}

		private static function onStabilizerTimer():Boolean
		{
			PenStabilizer.update(stabilizedPoints, getTimer());

			if (stabilizedPoints.length > 0 || PenStabilizer.isPreviewChanged())
			{
				drawStabilizedPoints(false);
				drawStabilizerPreview();
			}

			return true;
		}

		// 스태빌라이저가 계산한 좌표를 실제 선으로 그려줌 (handleMouseMove를 거치므로 replay에도 lineTo로 기록됨)
		private static function drawStabilizedPoints(isFinish:Boolean):void
		{
			const len:uint = stabilizedPoints.length;

			if (isSharpStabilizer)
			{
				for (var j:uint = 0; j < len; j += 2)
				{
					addSharpStabilizedPoint(stabilizedPoints[j], stabilizedPoints[j + 1]);
				}

				// 끝낼때는 남은 후보(커서 위치)까지 그려줌
				if (isFinish)
				{
					drawSharpStabilizerCandidate();
				}

				stabilizedPoints.length = 0;
				return;
			}

			for (var i:uint = 0; i < len; i += 2)
			{
				const x:Number = stabilizedPoints[i];
				const y:Number = stabilizedPoints[i + 1];
				const dx:Number = x - stabilizerLastDrawPos.x;
				const dy:Number = y - stabilizerLastDrawPos.y;

				// 끝낼때 마지막 좌표는 거리와 상관없이 커서 위치까지 그려줌
				if (dx * dx + dy * dy >= stabilizerDrawDist * stabilizerDrawDist || (isFinish && i === len - 2))
				{
					handleMouseMove(x, y);
					stabilizerLastDrawPos.setTo(x, y);
				}
			}

			stabilizedPoints.length = 0;
		}

		private static function addSharpStabilizedPoint(x:Number, y:Number):void
		{
			const candidate:Point = PenTool.getRefinedPoint(x, y);
			sharpStabilizerPending.push(x, y);

			const isValid:Boolean = isSharpStabilizerSegmentValid(candidate);

			if (isValid || isNaN(sharpStabilizerCandidate.x))
			{
				sharpStabilizerCandidate.copyFrom(candidate);

				// 확정할 이전 후보가 없는데 허용 오차를 넘으면 이번 좌표를 바로 꼭짓점으로 그려줌
				if (!isValid)
				{
					drawSharpStabilizerCandidate();
				}

				return;
			}

			// 이번 좌표까지 이으면 허용 오차를 넘으므로 직전까지 맞던 후보를 꼭짓점으로 확정하고 이번 좌표부터 다시 모음
			drawSharpStabilizerCandidate();
			sharpStabilizerPending.push(x, y);
			sharpStabilizerCandidate.copyFrom(candidate);
		}

		// anchor에서 candidate까지 직선으로 그렸을때 모아둔 매끄러운 좌표가 모두 허용 오차 안에 있는지
		private static function isSharpStabilizerSegmentValid(candidate:Point):Boolean
		{
			const ax:Number = sharpStabilizerAnchor.x;
			const ay:Number = sharpStabilizerAnchor.y;
			const vx:Number = candidate.x - ax;
			const vy:Number = candidate.y - ay;
			const lengthSq:Number = vx * vx + vy * vy;

			if (lengthSq > SHARP_STABILIZER_MAX_SEGMENT * SHARP_STABILIZER_MAX_SEGMENT)
			{
				return false;
			}

			const len:uint = sharpStabilizerPending.length;

			for (var i:uint = 0; i < len; i += 2)
			{
				// floor는 평균 0.5px 왼쪽 위로 치우치므로 그만큼 옮겨서 비교함
				const px:Number = sharpStabilizerPending[i] - 0.5;
				const py:Number = sharpStabilizerPending[i + 1] - 0.5;
				var t:Number = (lengthSq > 0) ? ((px - ax) * vx + (py - ay) * vy) / lengthSq : 0;
				t = (t < 0) ? 0 : (t > 1) ? 1 : t;
				const ex:Number = ax + vx * t - px;
				const ey:Number = ay + vy * t - py;

				if (ex * ex + ey * ey > SHARP_STABILIZER_TOLERANCE * SHARP_STABILIZER_TOLERANCE)
				{
					return false;
				}
			}

			return true;
		}

		private static function drawSharpStabilizerCandidate():void
		{
			if (isNaN(sharpStabilizerCandidate.x))
			{
				return;
			}

			handleMouseMove(sharpStabilizerCandidate.x, sharpStabilizerCandidate.y);
			sharpStabilizerAnchor.copyFrom(sharpStabilizerCandidate);
			sharpStabilizerCandidate.setTo(NaN, NaN);
			sharpStabilizerPending.length = 0;
		}

		// 선이 커서를 늦게 따라가는 구간을 마우스를 떼면 그려질 모양 그대로 임시로 보여줌
		private static function drawStabilizerPreview():void
		{
			const g:Graphics = stabilizerPreview.graphics;
			g.clear();

			stabilizerPreviewPoints.length = 0;
			PenStabilizer.getPreview(stabilizerPreviewPoints);

			const len:uint = stabilizerPreviewPoints.length;

			if (len === 0)
			{
				return;
			}

			if (xShape === false)
			{
				g.lineStyle(xSize, xColor);
			}
			else
			{
				g.lineStyle(xSize, xColor, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.BEVEL);
			}

			// 실제 선이 끝난 자리부터 이어줌 (moveEvent2Last, clickPosDot는 offsetForSharpline이 적용된 좌표)
			if (isMouseMoved)
			{
				g.moveTo(moveEvent2Last.x, moveEvent2Last.y);
			}
			else
			{
				g.moveTo(clickPosDot.x, clickPosDot.y);
			}

			for (var i:uint = 0; i < len; i += 2)
			{
				g.lineTo(stabilizerPreviewPoints[i] + offsetForSharpline, stabilizerPreviewPoints[i + 1] + offsetForSharpline);
			}
		}

		private static function finishStabilizer():void
		{
			FOFOTimer.remove("penStabilizerTimer");
			stabilizerPreview.graphics.clear();

			// 마지막 move 이벤트 이후 움직인 곳까지 포함해서 커서 위치까지 이어줌
			const upPos:Point = PenTool.getRefinedPoint(StrokeBuffer.canvasDrawLayerChild.mouseX, StrokeBuffer.canvasDrawLayerChild.mouseY);
			PenStabilizer.addInput(upPos.x, upPos.y, getTimer());
			PenStabilizer.finish(stabilizedPoints);
			drawStabilizedPoints(true);
		}

		// 끝 부분점을 distance만큼 길게 늘임
		private static function updateExtendEndPoint(x1:Number, y1:Number, x2:Number, y2:Number, distance:Number):void
		{
			// 선분 방향 벡터 계산
			const directionX:Number = x2 - x1;
			const directionY:Number = y2 - y1;

			// 선분 길이 계산
			const length:Number = Math.sqrt(directionX * directionX + directionY * directionY);

			if (length === 0)
			{
				extendedPos.setTo(x2, y2);
				return;
			}
		
			// 선분 방향 벡터 정규화
			const normalizedDirectionX:Number = directionX / length;
			const normalizedDirectionY:Number = directionY / length;

			// 리플레이에 원시 number가 저장되지 않도록 getRefinedPoint로 정제
				const refined:Point = PenTool.getRefinedPoint(x2 + normalizedDirectionX * distance, y2 + normalizedDirectionY * distance);
				extendedPos.setTo(refined.x, refined.y);
		}

		private static function handleMouseMove(mx:Number, my:Number):void
		{
			if (UndoHistory.canAddUndoData === false)
			{
				setCanUndoDataFlagON();
			}

			const filteredPos:Point = PenTool.getRefinedPoint(mx, my);
			mx = filteredPos.x + offsetForSharpline;
			my = filteredPos.y + offsetForSharpline;

			if (xShape === true)
			{
				const sx:Number = sqLinePosLast.x - mx;
				const sy:Number = sqLinePosLast.y - my;
				const dist:Number = Math.sqrt(sx * sx + sy * sy);

				if (dist <= 2.5)
				{
					return;
				}
				else
				{
					sqLinePosLast.setTo(mx, my);
				}
			}

			if (isMouseMoved === false) // 움직이기 시작할때 linestyle이랑 moveto넣어줌
			{
				isMouseMoved = true;

				StrokeBuffer.canvasDrawLayerChild.graphics.clear();
				lineStyleReady(xShape, xSize, xColor, xAlpha);

				if (xShape)
				{
					const filteredStartPos:Point = PenTool.getRefinedPoint(clickPos.x, clickPos.y);
					filteredStartPos.x = filteredStartPos.x + offsetForSharpline;
					filteredStartPos.y = filteredStartPos.y + offsetForSharpline;

					updateExtendEndPoint(mx, my, filteredStartPos.x, filteredStartPos.y, xSize / 8);

					ReplayState.rMemoryDataBuffer.push(ReplayState.stampTimingSheetCommand(["lineStyle5", xShape, xSize, xColor, xAlpha, extendedPos.x, extendedPos.y, xBlendMode, false, DrawCanvas.isLayer2Selected, PenSettings.airBrushSizeDrawMode]));
					penPoints.push(extendedPos.x);
					penPoints.push(extendedPos.y);
					StrokeBuffer.canvasDrawLayerChild.graphics.moveTo(extendedPos.x, extendedPos.y);
				}
				else
				{
					ReplayState.rMemoryDataBuffer.push(ReplayState.stampTimingSheetCommand(["lineStyle5", xShape, xSize, xColor, xAlpha, smoothPos.x + offsetForSharpline, smoothPos.y + offsetForSharpline, xBlendMode, false, DrawCanvas.isLayer2Selected, PenSettings.airBrushSizeDrawMode]));
					penPoints.push(smoothPos.x + offsetForSharpline);
					penPoints.push(smoothPos.y + offsetForSharpline);
					StrokeBuffer.canvasDrawLayerChild.graphics.moveTo(smoothPos.x + offsetForSharpline, smoothPos.y + offsetForSharpline);
				}
			}

			if (isMouseMoved)
			{
				if (moveEvent2Last.x === mx && moveEvent2Last.y === my)
				{
					return;
				}

				ReplayState.rMemoryDataBuffer.push(ReplayState.stampTimingSheetCommand(["lineTo", mx, my]));
				penPoints.push(mx);
				penPoints.push(my);

				moveEvent2Last.setTo(mx, my);
				StrokeBuffer.canvasDrawLayerChild.graphics.lineTo(mx, my);

				mouseMovedCount++;

				if (mouseMovedCount >= 100)
				{
					mouseMovedCount = 0;

					if (PenSettings.airBrushSizeDrawMode > 0)
					{
						const blurSize:Number = PenSettings.getBlurSize(PenSettings.airBrushSizeDrawMode, 1.0);
						StrokeBuffer.canvasDrawLayerChild.filters = [new BlurFilter(blurSize, blurSize, 3)];
						StrokeBuffer.canvasDrawLayerBitmapData.draw(StrokeBuffer.canvasDrawLayerChild, null, null, "layer");
						StrokeBuffer.canvasDrawLayerChild.filters = [];
					}
					else
					{
						StrokeBuffer.canvasDrawLayerBitmapData.draw(StrokeBuffer.canvasDrawLayerChild, null, null, "layer");
					}

					StrokeBuffer.canvasDrawLayerBitmap.bitmapData = StrokeBuffer.canvasDrawLayerBitmapData;
					StrokeBuffer.updateCanvasDrawLayerClipRect();

					StrokeBuffer.canvasDrawLayerChild.graphics.clear();
					lineStyleReady(xShape, xSize, xColor, xAlpha);

					const prevX:Number = penPoints[penPoints.length - 4];
					const prevY:Number = penPoints[penPoints.length - 3];

					penPoints.length = 0;

					ReplayState.rMemoryDataBuffer.push(["tempDone4"]);

					if (xShape === true)
					{
						ReplayState.rMemoryDataBuffer.push(ReplayState.stampTimingSheetCommand(["lineStyle5", xShape, xSize, xColor, xAlpha, prevX, prevY, xBlendMode, false, DrawCanvas.isLayer2Selected, PenSettings.airBrushSizeDrawMode]));
						penPoints.push(prevX);
						penPoints.push(prevY);
						StrokeBuffer.canvasDrawLayerChild.graphics.moveTo(prevX, prevY);
					}
					else
					{
						ReplayState.rMemoryDataBuffer.push(ReplayState.stampTimingSheetCommand(["lineStyle5", xShape, xSize, xColor, xAlpha, mx, my, xBlendMode, false, DrawCanvas.isLayer2Selected, PenSettings.airBrushSizeDrawMode]));
						penPoints.push(mx);
						penPoints.push(my);
						StrokeBuffer.canvasDrawLayerChild.graphics.moveTo(mx, my);
					}
				}

				if (xShape === true || sq1pxCursor === true)
				{
					const rad:Number = Math.atan2(mx - sqPenCursorLast.x, my - sqPenCursorLast.y);
					const deg:Number = -rad * (180 / Math.PI) + CanvasView.canvasAnchorPoint.rotation;

					PenSizePreviewCursor.setRotation(deg);

					sqPenCursorLast.x = mx;
					sqPenCursorLast.y = my;
				}

				if (Point.distance(clickPosDot, moveEvent2Last) >= 0.2)
				{
					dotflag = false;
				}
			}
		}

		private static function skipMouseMovePos(mx:Number, my:Number):Boolean
		{
			var filteredPos:Point = PenTool.getRefinedPoint(mx, my);
			mx = filteredPos.x;
			my = filteredPos.y;

			moveEventDistSave.setTo(mx, my);
			const dist:Number = Point.distance(moveEventDistSave, moveEventLast);

			if (dist < lastMouseMoveDist)
			{
				lastMouseMoveDist = lastMouseMoveDist - dist;

				if (lastMouseMoveDist <= 0)
				{
					lastMouseMoveDist = xSize / 5;
				}

				return true;
			}

			lastMouseMoveDist = lastMouseMoveDist - dist;

			if (lastMouseMoveDist <= 0)
			{
				lastMouseMoveDist = xSize / 5;
			}

			moveEventLast.setTo(mx, my);

			return false;
		}

		private static function onMouseMovePenTool(e:MouseEvent):void
		{
			const mx:Number = StrokeBuffer.canvasDrawLayerChild.mouseX;
			const my:Number = StrokeBuffer.canvasDrawLayerChild.mouseY;

			if (isStabilizerON)
			{
				// 스무딩은 입력 경로가 촘촘할수록 곡선이 정확해지므로 skipMouseMovePos를 거치지 않고 전부 넣어줌
				// 실제 그리기는 onStabilizerTimer에서 프레임마다 해줌
				const filteredPos:Point = PenTool.getRefinedPoint(mx, my);
				PenStabilizer.addInput(filteredPos.x, filteredPos.y, getTimer());
				return;
			}

			if (skipMouseMovePos(mx, my))
			{
				return;
			}

			handleMouseMove(mx, my);
			smoothPos.setTo(mx, my);
		}

		private static const STROKE_DRAG_OWNER:String = "penStroke";
		private static var isStrokeActive:Boolean = false;

		private static function onMouseUpPenTool(e:MouseEvent):void
		{
			finishStroke();
		}

		// 이벤트 객체를 쓰지 않음. mouseUp을 못받는 경우(alt+tab 등)에도 MouseState.finishAllDrags가 직접 호출함
		private static function finishStroke():void
		{
			isStrokeActive = false;
			MouseState.endDrag(STROKE_DRAG_OWNER);
			main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpPenTool);
			main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMovePenTool);

			ReferenceLayerController.hideMemoryTrainingMask();
			CanvasLayers.endEraserToolPreview(); // DrawingFinish가 레이어를 갱신하기 전에 원래 순서로 복귀

			if (isStabilizerON)
			{
				finishStabilizer();
			}

			if (xShape === true)
			{
				PenSizePreviewCursor.setRotation(0);

				if (isMouseMoved === true)
				{
					const pointLen:uint = penPoints.length;

					if (pointLen >= 4)
					{
						updateExtendEndPoint(penPoints[pointLen - 4], penPoints[pointLen - 3], penPoints[pointLen - 2], penPoints[pointLen - 1], xSize / 8);

						ReplayState.rMemoryDataBuffer.push(ReplayState.stampTimingSheetCommand(["lineTo", extendedPos.x, extendedPos.y]));
						StrokeBuffer.canvasDrawLayerChild.graphics.lineTo(extendedPos.x, extendedPos.y);
					}
				}
			}

			if (isMouseMoved === false || (isPenTool && isMouseMoved === true && dotflag))
			{
				ReplayState.rMemoryDataBuffer = [];
				ReplayState.rMemoryDataBuffer.push(ReplayState.stampTimingSheetCommand(["dot4", xShape, xSize, xColor, xAlpha, clickPos.x, clickPos.y, xBlendMode, DrawCanvas.isLayer2Selected, PenSettings.airBrushSizeDrawMode, CanvasView.canvasAnchorPoint.rotation]));

				DotTool.start(xShape, xSize, xColor, clickPos.x, clickPos.y, CanvasView.canvasAnchorPoint.rotation);
				StrokeBuffer.resetCanvasDrawLayerClipRect();
			}

			penPoints.length = 0;

			DrawingFinish.run();
			PenSizePreviewCursor.checkColorNow(); // 획이 레이어에 반영된 뒤 커서 색 확인
		}

		public static function start():void
		{
			startStroke(true);
		}

		public static function startWithEraserMode():void
		{
			startStroke(false);
		}

		public static function startStroke(flag:Boolean):void
		{
			// mouseUp을 놓쳐서 이전 획이 열려있으면 먼저 마무리함 (replay/undo 명령이 섞이지 않게)
			if (isStrokeActive)
			{
				finishStroke();
			}

			isPenTool = flag;

			if (isPenTool)
			{
				xSize = PenSettings.penSize;
				xAlpha = PenSettings.penAlpha;
				xShape = PenSettings.penIsSquare;
				dotflag = true;

				if (isTransparentPenColor)
				{
					xColor = DrawCanvas.CANVAS_BG_COLOR;
					xBlendMode = "erase";
				}
				else
				{
					xColor = penColor;
					xBlendMode = null;

					if (!ColorPickerController.isCurrentColorSamePickedColor())
					{
						ColorPickerController.updatePickerCurrentColor(ColorPickerController.colorPickerBox.getRGBInfoBGColor());
						ColorHistory.add(ColorPickerController.colorPickerBox.getRGBInfoBGColor());
					}
				}
			}
			else
			{
				xSize = PenSettings.eraserSize;
				xColor = DrawCanvas.CANVAS_BG_COLOR;
				xAlpha = PenSettings.eraserAlpha;
				xShape = PenSettings.eraserIsSquare;
				xBlendMode = "erase";
			}

			if (xSize === 1)
			{
				sq1pxCursor = true;
				xShape = false;
			}
			else
			{
				sq1pxCursor = false;
			}

			if (flag && ReferenceLayerController.isRefLayerMemoryTrainingON)
			{
				ReferenceLayerController.showMemoryTrainingMask();
			}

			offsetForSharpline = PenSettings.getSharpLinePosOffset(xSize);
			mouseMovedCount = 0;
			isMouseMoved = false;

			canvasSizeRect.width = DrawCanvas.CANVAS_WIDTH;
			canvasSizeRect.height = DrawCanvas.CANVAS_HEIGHT;

			StrokeBuffer.resetCanvasDrawLayerClipRect();

			const filteredPos:Point = PenTool.getRefinedPoint(StrokeBuffer.canvasDrawLayerChild.mouseX, StrokeBuffer.canvasDrawLayerChild.mouseY);

			clickPos.copyFrom(filteredPos);
			clickPosDot.setTo(filteredPos.x + offsetForSharpline, filteredPos.y + offsetForSharpline);
			smoothPos.copyFrom(filteredPos);
			moveEventLast.copyFrom(filteredPos);
			moveEvent2Last.setTo(NaN, NaN);

			if (xShape === true || sq1pxCursor)
			{
				sqPenCursorLast.copyFrom(smoothPos);
			}

			if (xShape === true)
			{
				sqLinePosLast.copyFrom(smoothPos);
			}

			lastMouseMoveDist = xSize / 5;

			if (UndoHistory.canAddUndoData === false)
			{
				setCanUndoDataFlagON();
			}

			StrokeBuffer.canvasDrawLayerChild.filters = [];

			if (!isPenTool)
			{
				CanvasLayers.beginEraserToolPreview(DrawCanvas.isLayer2Selected); // 선택된 레이어만 지워지는 미리보기
			}

			isStabilizerON = isPenTool && PenSettings.penSmoothSlideValue > 1;

			if (isStabilizerON)
			{
				PenStabilizer.reset(filteredPos.x, filteredPos.y, getTimer(), PenStabilizer.getWindowLength(PenSettings.penSmoothValue), PenStabilizer.getWindowTime(PenSettings.penSmoothValue));
				stabilizerLastDrawPos.copyFrom(filteredPos);
				stabilizerDrawDist = Math.max(2, xSize / 5);
				isSharpStabilizer = PenSettings.isSharpLineON;
				sharpStabilizerAnchor.copyFrom(filteredPos); // 샤프라인이면 getRefinedPoint에서 이미 정수화된 좌표
				sharpStabilizerCandidate.setTo(NaN, NaN);
				sharpStabilizerPending.length = 0;
				stabilizedPoints.length = 0;
				stabilizerPreview.graphics.clear();
				StrokeBuffer.canvasDrawLayer.alpha = xAlpha; // 첫 선이 그려지기 전에 미리보기가 먼저 보일 수 있어서 미리 맞춰줌

				if (stabilizerPreview.parent !== StrokeBuffer.canvasDrawLayer)
				{
					StrokeBuffer.canvasDrawLayer.addChild(stabilizerPreview);
				}

				FOFOTimer.addByName("penStabilizerTimer", 0, true, onStabilizerTimer);
			}

			main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMovePenTool);
			main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpPenTool, false, InputPriority.DEFAULT);
			isStrokeActive = true;
			MouseState.beginDrag(STROKE_DRAG_OWNER, finishStroke);
		}
	}
}
