package Symbols
{

	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	import flash.display.Graphics;
	import assets.VisualBuilder;
	import assets.VisualFieldCollector;

	public class seekBarSet extends Sprite
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
		private var isPrograssBarMaxWidth:Boolean = false;
		
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

		public function updateReplayPrograssBarWidthByNowFame(frameRaio:Number):void
        {
            setReplayPrograssBarWidth(trackBar.width*frameRaio);
        }

        public function increaseReplayPrograssBarWidth(inc:Number):void
        {
            setReplayPrograssBarWidth(prograssBar.width+inc);
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
        
            if(newWidth >= trackBar.width)
            {
                if(!isPrograssBarMaxWidthReached())
                {
                    setPrograssBarMaxWidthFlag(true);
                }
            }
            else if(isPrograssBarMaxWidthReached() || newWidth === 0)
            {
                setPrograssBarMaxWidthFlag(false);
                Global.applyToolBoxButtonOverBGColor(prograssBar);
            }
        }

        public function getReplayPrograssBarWidth():Number
		{
			return prograssBar.width;
		}

		public function updatePos(stw:Number):void
		{
			var startX:Number = 0.0;
			if(replayNext.visible)
			{
				startX = Math.floor(replayNext.x + replayNext.width + 7);
			}
			else
			{
				startX = Math.floor(playButton.x + playButton.width + 7);
			}

			trackBar.x = startX;

			const scale:Number = this.scaleX;
            const maxWidth:Number = stw-(trackBar.x+5)*scale;
			const trackBarWidthSave:Number = trackBar.width;
            trackBar.width =  Math.floor(maxWidth/scale);
			const scaleFactor:Number = trackBar.width/trackBarWidthSave;
            replayBGBar.width =  Math.floor(stw/scale)+1;
			prograssBar.x = startX
			prograssBar.width = prograssBar.width * scaleFactor;
            prograssInfo.x = startX;
            prograssInfo.width =  Math.floor(maxWidth/scale);
		}

		public function updateDeleteDangeBarPosWidth(mode:String):void
		{
			var dangX:Number;
			var dangWidth:Number;

			if(mode === "before")
			{
				dangX = trackBar.x;
				dangWidth = prograssBar.width;
			}
			else if(mode === "after")
			{
				dangX = trackBar.x+prograssBar.width;
				dangWidth = trackBar.width-prograssBar.width;
			}
			else if(mode === "total")
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

		public function isPrograssBarMaxWidthReached():Boolean
		{
			return isPrograssBarMaxWidth;
		}

		public function setPrograssBarMaxWidthFlag(flag:Boolean):void
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

		[Embed(
            source="fofoPaint-animate-27.13.swf",
            symbol="seekBarSet"
        )]
		private static const EmbeddedClass:Class;

		public function seekBarSet()
		{
			const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
			VisualBuilder.buildInto(this,EmbeddedClass,fields);

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
