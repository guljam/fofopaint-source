package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;

	public class toolTipBoxSet extends Sprite {
		public var toolTipBoxBG:SimpleButton = toolTipBoxBG;
		public var toolTipInfoText:TextField = toolTipInfoText;
	
		public function setText(str:String):void
		{
			trace('set text',str);
			toolTipInfoText.text = str;

			toolTipInfoText.width = toolTipInfoText.textWidth+50;
			// if(toolTipInfoText.textWidth+20 > 120)
			// else
			// 	toolTipInfoText.width = 120;
			toolTipInfoText.height = toolTipInfoText.textHeight+10;

			trace('toolTipInfoText.width',toolTipInfoText.width,toolTipInfoText.height);
			trace('toolTipInfoText.textWidth',toolTipInfoText.textWidth,toolTipInfoText.textHeight);
		}

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
			toolTipBoxBG.y = -1;
			toolTipBoxBG.x = -1;
			toolTipBoxBG.useHandCursor = false;
		}
	}
}
