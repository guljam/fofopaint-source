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
		public var playButton:SimpleButton;
		public var pauseButton:SimpleButton;
		public var replayPrev:SimpleButton;
		public var replayNext:SimpleButton;
		public var frameInfo:TextField;
		public var BARSIZE:Number = 27;
		private var nowBarColorSave:ColorTransform = new ColorTransform();
		private const baseColor:ColorTransform = new ColorTransform();
		private const opColor:ColorTransform = new ColorTransform();
		private const nowBarColor:ColorTransform = new ColorTransform();
		private const totalBarColor:ColorTransform = new ColorTransform();

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
			if(nowBarColorSave.color === 0)
			{
				return;
			}

			replayNowBar.transform.colorTransform = nowBarColorSave;
		}
		public function changeUIColor(base:uint,op:uint,color1:uint,index:uint):void
		{
			baseColor.color = base;
			opColor.color = op;
			nowBarColor.color = color1;
			replayBGBar.transform.colorTransform = baseColor;
            replayNowBar.transform.colorTransform = nowBarColor;
            playButton.transform.colorTransform = opColor;
            pauseButton.transform.colorTransform = opColor;
            replayPrev.transform.colorTransform = opColor;
            replayNext.transform.colorTransform = opColor;

			nowBarColorSave.color = color1;

			if(index === 2)
            {
				totalBarColor.color = 0xE7E7E7;
                replayTotalBar.transform.colorTransform = totalBarColor;
                frameInfo.textColor = op;
            }
            else if(index === 3)
			{
				totalBarColor.color = 0xFFFFFF;
                replayTotalBar.transform.colorTransform = totalBarColor;
				frameInfo.textColor = op;
			}
            else
            {
                replayTotalBar.transform.colorTransform = opColor;
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
			frameInfo.mouseEnabled = false;
			visible = false;

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
