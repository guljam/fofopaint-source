package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;

	public class toolTipBoxSet extends Sprite {
		public var toolTipBoxBG:SimpleButton;
		public var toolTipInfoText:TextField;
		private const baseColor:ColorTransform = new ColorTransform();
	
		public function updateBGPosition(scaled:Boolean):void
		{
			if(scaled) toolTipBoxBG.y = 0;
			else toolTipBoxBG.y = -1;
		}

		public function changeUIColor(base:uint,op:uint):void
		{
			baseColor.color = base;

			toolTipBoxBG.transform.colorTransform = baseColor;
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
