package
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.display.Sprite;

	public class toolTipBoxSet extends Sprite {
		public var toolTipInfoText:TextField;
		private const toolTipInfoBG:Sprite = new Sprite();
		private const bgColor:uint = 0xFFA700;

		public function getHeight():Number
		{
			return (toolTipInfoBG.height-1)*scaleX;
		}

		public function setText(str:String):void
		{
			toolTipInfoText.text = str;
			toolTipInfoBG.graphics.clear();
			toolTipInfoBG.graphics.beginFill(bgColor);
			toolTipInfoBG.graphics.drawRect(0,0,toolTipInfoText.width,toolTipInfoText.height);
			(0,0,toolTipInfoText.width,toolTipInfoText.height);
			toolTipInfoBG.graphics.endFill();
		}

		public function toolTipBoxSet() {
			// constructor code
			visible = false;
			toolTipInfoText.mouseEnabled = false;
			toolTipInfoText.autoSize = TextFieldAutoSize.LEFT;
			mouseEnabled = false;

			toolTipInfoBG.y = -1;
			addChild(toolTipInfoBG);
			setChildIndex(toolTipInfoBG,0);
		}
	}
}
