package
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class toolTipBoxSet extends Sprite {
		public var toolTipInfoText:TextField;
		private const bgColor:uint = 0xFFA31F;

		public function setText(str:String):void
		{
			toolTipInfoText.text = str;
		}

		public function changeUIColor(base:uint,op:uint):void
		{
			toolTipInfoText.backgroundColor = base;
			toolTipInfoText.textColor = op;
		}

		public function toolTipBoxSet() {

			changeUIColor(bgColor,0);
			// constructor code
			visible = false;
			toolTipInfoText.mouseEnabled = false;
			toolTipInfoText.border = true;
			toolTipInfoText.borderColor = 0;
			toolTipInfoText.background = true;
			toolTipInfoText.borderColor = 0;
			toolTipInfoText.autoSize = TextFieldAutoSize.LEFT;
			mouseEnabled = false;
		}
	}
}
