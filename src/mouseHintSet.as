package
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class mouseHintSet extends Sprite {
		public var mouseHintText:TextField;
		private const mouseHintGB:Sprite = new Sprite();
		private var bgColor:uint = 0xFFA700;
		private var HEIGHT:Number = 0;

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale;
			this.scaleY = newScale;
		}

		public function getText():String
		{
			return mouseHintText.text;
		}

		public function updateBGColor(color:uint):void
		{
			bgColor = color;
		}

		public function getDefaultHeight():Number
		{
			return HEIGHT;
		}

		public function getScaledTextHeight():Number
		{
			return mouseHintText.height*scaleX;
		}

		public function getScaledTextWidth():Number
		{
			return mouseHintText.width*scaleX;
		}
		public function getScaledHeight():Number
		{
			return (mouseHintGB.height-1)*scaleX;
		}

		public function setHintText(str:String):void
		{
			mouseHintText.text = str;
			mouseHintGB.graphics.clear();
			mouseHintGB.graphics.lineStyle(1,0,0.5);
			mouseHintGB.graphics.beginFill(bgColor,0.75);
			mouseHintGB.graphics.drawRect(-1,-1,mouseHintText.width+2,mouseHintText.height+2);
			mouseHintGB.graphics.endFill();
		}

		public function show():void
		{
			this.visible = true;
		}

		public function hide():void
		{
			this.visible = false;
		}

		public function isShowing():Boolean
		{
			return this.visible;
		}

		public function mouseHintSet() {
			// constructor code
			visible = false;
			mouseHintText.mouseEnabled = false;
			mouseHintText.autoSize = TextFieldAutoSize.LEFT;
			this.mouseEnabled = false;
			// mouseEnabled = false;

			setHintText("FOFO PAINT HINT");
			HEIGHT = this.height;
			setHintText("");

			mouseHintGB.y = -1;
			addChild(mouseHintGB);
			setChildIndex(mouseHintGB,0);
			mouseHintGB.mouseEnabled = false;
			mouseHintText.mouseEnabled = false;
			mouseEnabled = false;
		}
	}
}
