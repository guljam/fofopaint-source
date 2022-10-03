package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;

	public class toolTipBoxSet extends Sprite {
		public var toolTipBoxBG:SimpleButton = toolTipBoxBG;
		public var toolTipInfoText:TextField = toolTipInfoText;
	
		public function changeUIColor(base:uint,op:uint):void
		{
			const b:ColorTransform = new ColorTransform();
			b.color = base;

			toolTipBoxBG.transform.colorTransform = b;
			toolTipInfoText.textColor = op;
		}

		public function toolTipBoxSet() {
			// constructor code
			visible = false;
			toolTipBoxBG.x = -1;
			toolTipBoxBG.y = -1;
			toolTipBoxBG.useHandCursor = false;
			toolTipInfoText.width = 350;
			toolTipInfoText.height = 60;
		}
	}
}
