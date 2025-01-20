package
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.display.Sprite;

	public class toolTipBoxSet extends Sprite {
		public var toolTipInfoText:TextField;
		private const toolTipInfoBG:Sprite = new Sprite();
		private var bgColor:uint = 0xFFA700;
		private var HEIGHT:Number = 0;

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale;
			this.scaleY = newScale;
		}

		public function getText():String
		{
			return toolTipInfoText.text;
		}

		public function setTextColor(color:uint):void
		{
			toolTipInfoText.textColor = color;
		}

		public function setBGColor(color:uint):void
		{
			bgColor = color;
		}

		public function getDefaultHeight():Number
		{
			return HEIGHT;
		}

		public function getHeight():Number
		{
			return (toolTipInfoBG.height-1)*scaleX;
		}

		public function setText(str:String):void
		{
			toolTipInfoText.text = str;
			toolTipInfoBG.graphics.clear();
			toolTipInfoBG.graphics.lineStyle(1,0,0.5);
			toolTipInfoBG.graphics.beginFill(bgColor,0.75);
			toolTipInfoBG.graphics.drawRect(-1,-1,toolTipInfoText.width+2,toolTipInfoText.height+2);
			(0,0,toolTipInfoText.width,toolTipInfoText.height);
			toolTipInfoBG.graphics.endFill();
		}

		public function toolTipBoxSet() {
			// constructor code
			visible = false;
			toolTipInfoText.mouseEnabled = false;
			toolTipInfoText.autoSize = TextFieldAutoSize.LEFT;
			// mouseEnabled = false;

			setText("FOFO PAINT HINT");
			HEIGHT = this.height;
			setText("");

			toolTipInfoBG.y = -1;
			addChild(toolTipInfoBG);
			setChildIndex(toolTipInfoBG,0);
			toolTipInfoBG.mouseEnabled = false;
			toolTipInfoText.mouseEnabled = false;
			mouseEnabled = false;
		}
	}
}
