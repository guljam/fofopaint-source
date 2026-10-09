package Symbols
{

	import Modules.UIEngine.UITheme;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	import flash.display.Graphics;
	import assets.VisualBuilder;
	import assets.VisualFieldCollector;
	import Modules.Utils;

	// 층: L4 UI - 리플레이 재생 막대(시크바) 화면 묶음
	public class SeekBarSet extends Sprite
	{
		private var replayBGBar:Sprite = new Sprite();
		private var deleteRangeBar:Sprite = new Sprite();
		private var replayWaitingRangeBar:Sprite = new Sprite(); // 쉬는(Replay Waiting) 구간을 트랙 위에 어둡게 칠하는 층
		private var replayWaitingList:Vector.<Number> = new Vector.<Number>(); // 마지막으로 받은 구간 비율 쌍 (0~1)
		public var trackBar:Sprite = new Sprite();
		public var prograssBar:Sprite = new Sprite();
		public var prograssInfo:TextField;
		public var playButton:SimpleButton;
		public var pauseButton:SimpleButton;
		public var replayPrev:SimpleButton;
		public var replayNext:SimpleButton;
		private var nowBarColorSave:ColorTransform = new ColorTransform();
		public const BARSIZE:Number = 27;
		private var isPrograssBarMaxWidth:Boolean = false;
		private var playbackControls:Array = []; // 재생 중 멈춤 버튼 오른쪽에 놓는 컨트롤(줌 버튼, 배속 슬라이더). 표시 객체를 받기만 하고 어디서 가져왔는지는 모름
		private const CONTROL_GAP:Number = 7; // 기존 버튼 간격과 같음

		// 컨트롤을 멈춤 버튼 오른쪽에 순서대로 놓고 트랙 시작 위치를 그만큼 옮김. 옮기고 되돌리는 책임은 호출한 쪽
		public function attachPlaybackControls(list:Array):void
		{
			detachPlaybackControls();
			playbackControls = list.concat();

			for each (var c:DisplayObject in playbackControls)
			{
				addChild(c);
			}

			if (stage)
			{
				updatePos(stage.stageWidth);
			}
		}

		// 컨트롤을 시크바에서 떼어 냄 (다시 붙이는 건 호출한 쪽)
		public function detachPlaybackControls():void
		{
			for each (var c:DisplayObject in playbackControls)
			{
				if (c.parent === this)
				{
					removeChild(c);
				}
			}

			playbackControls = [];

			if (stage)
			{
				updatePos(stage.stageWidth);
			}
		}

		public function showReplayControlButton():void
		{
			replayPrev.visible = true;
			replayNext.visible = true;
			updatePos(stage.stageWidth);
		}

		public function hideReplayControlButton():void
		{
			replayPrev.visible = false;
			replayNext.visible = false;
			updatePos(stage.stageWidth);
		}

		// 쉬는(Replay Waiting) 구간을 시크바 트랙 위에 어둡게 표시. ranges는 [시작 비율, 끝 비율] 쌍(0~1)을 이어붙인 목록
		// 폭이 1px 이상이면 그 폭만큼, 1px 미만이면 그 자리에 1px 눈금만 그림
		public function setReplayWaitingRanges(ranges:Vector.<Number>):void
		{
			replayWaitingList = ranges;
			redrawReplayWaitingRanges();
		}

		private function redrawReplayWaitingRanges():void
		{
			const g:Graphics = replayWaitingRangeBar.graphics;
			g.clear();
			const w:Number = trackBar.width;
			const h:Number = trackBar.height;

			for (var i:int = 0; i < replayWaitingList.length; i += 2)
			{
				const x0:Number = w * replayWaitingList[i];
				const width:Number = w * (replayWaitingList[i + 1] - replayWaitingList[i]);

				if (width >= 1)
				{
					// 줄어든 폭이 1px 이상이면 그 폭 그대로(실수값) 어둡게 칠함
					g.beginFill(0x000000, 0.2);
					g.drawRect(x0, 0, width, h);
				}
				else
				{
					// 폭이 1px 미만이면 축 위치는 그대로 두고 그 자리에 조금 진한 1px 눈금만 덧그림
					g.beginFill(0x000000, 0.5);
					g.drawRect(x0, 0, 1, h);
				}

				g.endFill();
			}

			replayWaitingRangeBar.x = trackBar.x;
			replayWaitingRangeBar.y = trackBar.y;
		}

		public function updateReplayPrograssBarWidthByNowFame(frameRaio:Number):void
		{
			if(isNaN(frameRaio))
			{
				setReplayPrograssBarWidth(0);
			}
			else
			{
				setReplayPrograssBarWidth(trackBar.width * frameRaio);
			}
		}

		public function setReplayPrograssBarMaxWidth():void
		{
			setReplayPrograssBarWidth(trackBar.width);
		}

		public function resetReplayPrograssBarWidth():void
		{
			setReplayPrograssBarWidth(0);
		}

		public function setReplayPrograssBarWidth(newWidth:Number):void
		{
			prograssBar.x = trackBar.x;
			prograssBar.width = newWidth;

			if (newWidth >= trackBar.width)
			{
				if (!isPrograssBarMaxWidthReached())
				{
					setPrograssBarMaxWidthFlag(true);
				}
			}
			else if (isPrograssBarMaxWidthReached() || newWidth === 0)
			{
				setPrograssBarMaxWidthFlag(false);
				UITheme.applyToolBoxButtonOverBGColor(prograssBar);
			}
		}

		public function updatePos(stw:Number):void
		{
			var startX:Number = 0.0;
			if (replayNext.visible)
			{
				startX = Math.floor(replayNext.x + replayNext.width + 7);
			}
			else
			{
				startX = Math.floor(playButton.x + playButton.width + 7);
			}

			// 재생 중 컨트롤이 있으면 멈춤 버튼 오른쪽에 차례로 놓고(세로 가운데 정렬) 트랙은 그 오른쪽에서 시작
			for each (var c:DisplayObject in playbackControls)
			{
				c.x = startX;
				c.y = Math.floor((BARSIZE - c.height) / 2);
				startX = Math.floor(startX + c.width + CONTROL_GAP);
			}

			trackBar.x = startX;

			const scale:Number = this.scaleX;
			const maxWidth:Number = stw - (trackBar.x + 5) * scale;
			const trackBarWidthSave:Number = trackBar.width;
			trackBar.width = Math.floor(maxWidth / scale);
			const scaleFactor:Number = trackBar.width / trackBarWidthSave;
			replayBGBar.width = Math.floor(stw / scale) + 1;
			prograssBar.x = startX;
			prograssBar.width = prograssBar.width * scaleFactor;
			redrawReplayWaitingRanges();
			prograssInfo.x = startX;
			prograssInfo.width = Math.floor(maxWidth / scale);
		}

		public function updateDeleteDangeBarPosWidth(mode:String):void
		{
			var dangX:Number;
			var dangWidth:Number;

			if (mode === "before")
			{
				dangX = trackBar.x;
				dangWidth = prograssBar.width;
			}
			else if (mode === "after")
			{
				dangX = trackBar.x + prograssBar.width;
				dangWidth = trackBar.width - prograssBar.width;
			}
			else if (mode === "total")
			{
				dangX = trackBar.x;
				dangWidth = deleteRangeBar.width = trackBar.width;
			}
			else
			{
				return;
			}

			deleteRangeBar.x = dangX;
			deleteRangeBar.width = dangWidth;
			setDeleteRangeBarVisible(true);
		}

		public function setDeleteRangeBarVisible(flag:Boolean):void
		{
			deleteRangeBar.visible = flag;
			prograssBar.visible = !flag;
		}

		public function setPlayButtonVisible(flag:Boolean):void
		{
			playButton.visible = flag;
			pauseButton.visible = !flag;
		}

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale;
			this.scaleY = newScale;
		}

		private function isPrograssBarMaxWidthReached():Boolean
		{
			return isPrograssBarMaxWidth;
		}

		private function setPrograssBarMaxWidthFlag(flag:Boolean):void
		{
			isPrograssBarMaxWidth = flag;

		}

		public function resetPrograssBarColor():void
		{
			if (nowBarColorSave.color === 0)
			{
				return;
			}

			prograssBar.transform.colorTransform = nowBarColorSave;
		}

		private function initializeTrackBarX():void
		{
			trackBar.x = Math.floor(replayNext.x + replayNext.width + 7);
			trackBar.y = 8;
			deleteRangeBar.x = trackBar.x;
			deleteRangeBar.y = trackBar.y;
			prograssBar.x = trackBar.x;
			prograssBar.y = trackBar.y;
			prograssInfo.x = trackBar.x;
			prograssInfo.y = trackBar.y;
			prograssInfo.width = trackBar.width;
		}

		public function updateUIColor():void
		{
			UITheme.applyUIBGColor(replayBGBar);
			UITheme.applyUIFGColor(playButton);
			UITheme.applyUIFGColor(pauseButton);
			UITheme.applyUIFGColor(replayPrev);
			UITheme.applyUIFGColor(replayNext);
			UITheme.applyToolBoxButtonOverBGColor(prograssBar);

			const index:int = UITheme.getUIColorIndex();
			if (index === 2)
			{
				Utils.setColorTransform(trackBar, 0xE7E7E7);
				prograssInfo.textColor = UITheme.getUIFGColor();
			}
			else if (index === 3)
			{
				Utils.setColorTransform(trackBar, 0xFFFFFF);
				prograssInfo.textColor = UITheme.getUIFGColor();
			}
			else
			{
				UITheme.applyUIFGColor(trackBar);
				prograssInfo.textColor = UITheme.getUIBGColor();
			}
		}

		private function initReplayBox():void
		{
			var g:Graphics;

			g = replayBGBar.graphics;
			g.lineStyle(0, 0, 0);
			g.beginFill(0xFFFFFF);
			g.drawRect(0, 0, 31, 36);
			g.endFill();
			replayBGBar.name = "replayBGBar";
			replayBGBar.mouseEnabled = false;

			g = deleteRangeBar.graphics;
			g.lineStyle(0, 0, 0);
			// g.beginFill(0xFD7A80);
			g.beginFill(0xFE8185);
			g.drawRect(0, 0, 20, 20);
			g.endFill();
			deleteRangeBar.name = "deleteRangeBar";
			deleteRangeBar.mouseEnabled = false;

			g = prograssBar.graphics;
			g.lineStyle(0, 0, 0);
			g.beginFill(0xFFFFFF);
			g.drawRect(0, 0, 20, 20);
			g.endFill();
			prograssBar.name = "prograssBar";
			prograssBar.mouseEnabled = false;

			g = trackBar.graphics;
			g.lineStyle(0, 0, 0);
			g.beginFill(0xFFFFFF);
			g.drawRect(0, 0, 20, 20);
			g.endFill();
			trackBar.name = "trackBar";

			addChild(replayBGBar);
			addChild(trackBar);
			addChild(prograssBar);
			replayWaitingRangeBar.mouseEnabled = false;
			replayWaitingRangeBar.mouseChildren = false;
			addChild(deleteRangeBar);
			addChild(replayWaitingRangeBar);
			setChildIndex(replayBGBar, 0);
			setChildIndex(trackBar, 1);
			setChildIndex(prograssBar, 2);
			setChildIndex(deleteRangeBar, 3);
			setChildIndex(replayWaitingRangeBar, 2); // 트랙 위, 진행 막대 아래
		}

		[Embed(source="fofoPaint-animate-27.13.swf",symbol="seekBarSet")]
		private static const EmbeddedClass:Class;

		public function SeekBarSet()
		{
			const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
			VisualBuilder.buildInto(this, EmbeddedClass, fields);

			prograssInfo.mouseEnabled = false;
			visible = false;

			initReplayBox();
			playButton.useHandCursor = false;
			pauseButton.useHandCursor = false;
			replayPrev.useHandCursor = false;
			replayNext.useHandCursor = false;

			playButton.x = 4;
			playButton.y = 3;
			pauseButton.x = playButton.x;
			pauseButton.y = playButton.y;
			replayPrev.x = pauseButton.x + pauseButton.width + 5;
			replayPrev.y = playButton.y;
			replayNext.x = replayPrev.x + replayPrev.width + 8;
			replayNext.y = playButton.y;

			deleteRangeBar.visible = false;

			initializeTrackBarX();
			// cacheAsBitmap = true;
		}
	}
}
