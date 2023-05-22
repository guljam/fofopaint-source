package
{

	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	import flash.display.Graphics;

	public class replayTimeBar extends Sprite {
		public var replayBGBar:Sprite = new Sprite();
		public var replayDeleteBar:Sprite = new Sprite();
		public var replayTotalBar:Sprite = new Sprite();
		public var replayNowBar:Sprite = new Sprite();
		public var playButton:SimpleButton = playButton;
		public var pauseButton:SimpleButton = pauseButton;
		public var replayPrev:SimpleButton = replayPrev;
		public var replayNext:SimpleButton = replayNext;
		public var frameInfo:TextField = frameInfo;
		public var BARSIZE:Number = 35;
		private var nowBarColorSave:uint = 0;

		public function tempTotalBarX():void
		{
			replayTotalBar.x = 5;
			replayTotalBar.y = 9;
			replayDeleteBar.x = replayTotalBar.x;
			replayDeleteBar.y = replayTotalBar.y;
			replayNowBar.x = replayTotalBar.x;
			replayNowBar.y = replayTotalBar.y;
			frameInfo.x = replayTotalBar.x;
			frameInfo.y = replayTotalBar.y;
			frameInfo.width = replayTotalBar.width;
		}

		public function initTotalBarX():void
		{
			replayTotalBar.x = Math.floor(replayNext.x+replayNext.width+7);
			replayTotalBar.y = 5;
			replayDeleteBar.x = replayTotalBar.x;
			replayDeleteBar.y = replayTotalBar.y;
			replayNowBar.x = replayTotalBar.x;
			replayNowBar.y = replayTotalBar.y;
			frameInfo.x = replayTotalBar.x;
			frameInfo.y = replayTotalBar.y;
			frameInfo.width = replayTotalBar.width;
		}

		public function resetNowbarColor():void
		{
			if(nowBarColorSave === 0)
			{
				return;
			}

			const c1:ColorTransform = new ColorTransform();
			c1.color = nowBarColorSave;
			replayNowBar.transform.colorTransform = c1;

		}
		public function changeUIColor(base:uint,op:uint,color1:uint,index:uint):void
		{
			const b:ColorTransform = new ColorTransform();
			const o:ColorTransform = new ColorTransform();
			const c1:ColorTransform = new ColorTransform();
			const c2:ColorTransform = new ColorTransform();

			b.color = base;
			o.color = op;
			c1.color = color1;
			replayBGBar.transform.colorTransform = b;
            replayNowBar.transform.colorTransform = c1;
            playButton.transform.colorTransform = o;
            pauseButton.transform.colorTransform = o;
            replayPrev.transform.colorTransform = o;
            replayNext.transform.colorTransform = o;

			nowBarColorSave = color1;

			if(index === 2)
            {
				c2.color = 0xE7E7E7;
                replayTotalBar.transform.colorTransform = c2;
                frameInfo.textColor = op;
            }
            else if(index === 3)
			{
				c2.color = 0xFFFFFF;
                replayTotalBar.transform.colorTransform = c2;
				frameInfo.textColor = op;
			}
            else 
            {
                replayTotalBar.transform.colorTransform = o;
                frameInfo.textColor = base;
            }
		}

		public function initReplayBox():void
		{
			var g:Graphics;

			g = replayBGBar.graphics;
			g.lineStyle(0,0,0);
			g.beginFill(0xFFFFFF);
			g.drawRect(0,0,31,31);
			g.endFill();
			replayBGBar.name = "replayBGBar";

			g = replayDeleteBar.graphics;
			g.lineStyle(0,0,0);
			// g.beginFill(0xFD7A80);
			g.beginFill(0xFE8185);
			g.drawRect(0,0,20,20);
			g.endFill();
			replayDeleteBar.name = "replayDeleteBar";

			g = replayNowBar.graphics;
			g.lineStyle(0,0,0);
			g.beginFill(0xFFFFFF);
			g.drawRect(0,0,20,20);
			g.endFill();
			replayNowBar.name = "replayNowBar";

			g = replayTotalBar.graphics;
			g.lineStyle(0,0,0);
			g.beginFill(0xFFFFFF);
			g.drawRect(0,0,20,20);
			g.endFill();
			replayTotalBar.name = "replayTotalBar";

			addChild(replayBGBar);
			addChild(replayTotalBar);
			addChild(replayNowBar);
			addChild(replayDeleteBar);
			setChildIndex(replayBGBar,0);
			setChildIndex(replayTotalBar,1);
			setChildIndex(replayNowBar,2);
			setChildIndex(replayDeleteBar,3);
		}

		public function replayTimeBar() {
			// constructor code
			visible = false;

			const floor:Function = Math.floor;

			initReplayBox();

			replayTotalBar.y = 5;
			replayNowBar.y = replayTotalBar.y;
			replayDeleteBar.y = replayTotalBar.y;

			playButton.useHandCursor = false;
			pauseButton.useHandCursor = false;
			replayPrev.useHandCursor = false;
			replayNext.useHandCursor = false;

			playButton.x = 4;
			playButton.y = replayTotalBar.y-5;
			pauseButton.x = playButton.x;
			pauseButton.y = playButton.y;
			replayPrev.x = pauseButton.x+pauseButton.width+5;
			replayPrev.y = playButton.y;
			replayNext.x = replayPrev.x+replayPrev.width+8;
			replayNext.y = playButton.y;

			replayDeleteBar.visible = false;

			initTotalBarX();
			cacheAsBitmap = true;
		}
	}
}
