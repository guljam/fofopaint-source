package
{

	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObject;
	import flash.text.TextField;

	public class numPadButtons extends Sprite
	{
		public var numInc:SimpleButton = numInc;
		public var numDec:SimpleButton = numDec;
		public var num0:SimpleButton = num0;
		public var num1:SimpleButton = num1;
		public var num2:SimpleButton = num2;
		public var num3:SimpleButton = num3;
		public var num4:SimpleButton = num4;
		public var num5:SimpleButton = num5;
		public var num6:SimpleButton = num6;
		public var num7:SimpleButton = num7;
		public var num8:SimpleButton = num8;
		public var num9:SimpleButton = num9;
		public var numIncText:TextField = numIncText;
		public var numDecText:TextField = numDecText;
		public var num0Text:TextField = num0Text;
		public var num1Text:TextField = num1Text;
		public var num2Text:TextField = num2Text;
		public var num3Text:TextField = num3Text;
		public var num4Text:TextField = num4Text;
		public var num5Text:TextField = num5Text;
		public var num6Text:TextField = num6Text;
		public var num7Text:TextField = num7Text;
		public var num8Text:TextField = num8Text;
		public var num9Text:TextField = num9Text;

		private var fixedScale:Number = 0.7;

		public function setScale(newScale:Number):void
		{
			scaleX = newScale * fixedScale;
			scaleY = newScale * fixedScale;
		}

		public function changeUIColor(arr:Array):void
		{
			const base:ColorTransform = new ColorTransform();
			const over:ColorTransform = new ColorTransform();

			base.color = arr[0];
			over.color = arr[4];

			const texts:Array = [
					numIncText,
					numDecText,
					num0Text,
					num1Text,
					num2Text,
					num3Text,
					num4Text,
					num5Text,
					num6Text,
					num7Text,
					num8Text,
					num9Text
				];
			const buttons:Array = [
					numInc,
					numDec,
					num0,
					num1,
					num2,
					num3,
					num4,
					num5,
					num6,
					num7,
					num8,
					num9
				];

			var i:uint = 0;
			var len:uint = buttons.length;
			var btn:SimpleButton;
			var btnUp:DisplayObject;
			var btnOver:DisplayObject;

			for (i = 0; i < len; i++)
			{
				btn = buttons[i];
				btnUp = btn.upState as DisplayObject;
				btnOver = btn.overState as DisplayObject;
				btnUp.transform.colorTransform = base;
				btnOver.transform.colorTransform = over;
				btn.downState = btnOver;
			}

			for (i = 0; i < len; i++)
			{
				texts[i].textColor = arr[2];
			}
		}

		public function off():void
		{
			this.x = -this.width;
			this.y = -this.height;
			visible = false;
		}

		public function numPadButtons()
		{
			name = "numPadBox";
			numIncText.mouseEnabled = false;
			numDecText.mouseEnabled = false;
			num0Text.mouseEnabled = false;
			num1Text.mouseEnabled = false;
			num2Text.mouseEnabled = false;
			num3Text.mouseEnabled = false;
			num4Text.mouseEnabled = false;
			num5Text.mouseEnabled = false;
			num6Text.mouseEnabled = false;
			num7Text.mouseEnabled = false;
			num8Text.mouseEnabled = false;
			num9Text.mouseEnabled = false;

			fixedScale = 34 / num0.width;

			scaleX = fixedScale;
			scaleY = fixedScale;

			this.x = -this.width;
			this.y = -this.height;
			visible = false;
			alpha = 0.75;
		}
	}
}
