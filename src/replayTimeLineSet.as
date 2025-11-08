package
{

	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	import flash.display.Graphics;

	public class ReplayTimelineSet extends Sprite
	{
		public var replayBGBar:Sprite = new Sprite();
		public var deleteRangeBar:Sprite = new Sprite();
		public var trackBar:Sprite = new Sprite();
		public var prograssBar:Sprite = new Sprite();
		public var prograssInfo:TextField;
		public var playButton:SimpleButton;
		public var pauseButton:SimpleButton;
		public var replayPrev:SimpleButton;
		public var replayNext:SimpleButton;
		private var nowBarColorSave:ColorTransform = new ColorTransform();
		public const BARSIZE:Number = 27;

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale;
			this.scaleY = newScale;
		}

		private function initializeTrackBarX():void
		{
			trackBar.x = Math.floor(replayNext.x + replayNext.width + 7);
			trackBar.y = 5;
			deleteRangeBar.x = trackBar.x;
			deleteRangeBar.y = trackBar.y;
			prograssBar.x = trackBar.x;
			prograssBar.y = trackBar.y;
			prograssInfo.x = trackBar.x;
			prograssInfo.y = trackBar.y;
			prograssInfo.width = trackBar.width;
		}

		public function resetPrograssBarColor():void
		{
			if (nowBarColorSave.color === 0)
			{
				return;
			}

			prograssBar.transform.colorTransform = nowBarColorSave;
		}

		public function updateUIColor():void
		{
			Global.applyUIBGColor(replayBGBar);
			Global.applyUIFGColor(playButton);
			Global.applyUIFGColor(pauseButton);
			Global.applyUIFGColor(replayPrev);
			Global.applyUIFGColor(replayNext);
			Global.applyToolBoxButtonOverBGColor(prograssBar);
			
			const index:int = Global.getUIColorIndex();
			if (index === 2)
			{
				Global.setColorTransform(trackBar,0xE7E7E7);
				prograssInfo.textColor = Global.getUIFGColor();
			}
			else if (index === 3)
			{
				Global.setColorTransform(trackBar,0xFFFFFF);
				prograssInfo.textColor = Global.getUIFGColor();
			}
			else
			{
				Global.applyUIFGColor(trackBar);
				prograssInfo.textColor = Global.getUIBGColor();
			}
		}

		public function initReplayBox():void
		{
			var g:Graphics;

			g = replayBGBar.graphics;
			g.lineStyle(0, 0, 0);
			g.beginFill(0xFFFFFF);
			g.drawRect(0, 0, 31, 31);
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
			addChild(deleteRangeBar);
			setChildIndex(replayBGBar, 0);
			setChildIndex(trackBar, 1);
			setChildIndex(prograssBar, 2);
			setChildIndex(deleteRangeBar, 3);
		}

		public function setReplayDeleteBarVisibleOFF():void
		{
			deleteRangeBar.visible = false;
			prograssBar.visible = true;
		}

		public function ReplayTimelineSet()
		{
			prograssInfo.mouseEnabled = false;
			visible = false;

			initReplayBox();

			trackBar.y = 5;
			prograssBar.y = trackBar.y;
			deleteRangeBar.y = trackBar.y;

			playButton.useHandCursor = false;
			pauseButton.useHandCursor = false;
			replayPrev.useHandCursor = false;
			replayNext.useHandCursor = false;

			playButton.x = 4;
			playButton.y = trackBar.y - 5;
			pauseButton.x = playButton.x;
			pauseButton.y = playButton.y;
			replayPrev.x = pauseButton.x + pauseButton.width + 5;
			replayPrev.y = playButton.y;
			replayNext.x = replayPrev.x + replayPrev.width + 8;
			replayNext.y = playButton.y;

			deleteRangeBar.visible = false;

			initializeTrackBarX();
			cacheAsBitmap = true;
		}
	}
}
