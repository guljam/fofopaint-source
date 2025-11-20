package
{

	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;

	public class RotateCursorSet extends Sprite
	{
		public var rotateBG:SimpleButton;
		public var rotateArrow:SimpleButton;
		public var rotateCircle:SimpleButton;
		private const constScale:Number = 0.7;

		public function setScale(scale:Number):void
		{
			this.scaleX = scale * constScale;
			this.scaleY = scale * constScale;
		}

		public function changeUIColor():void
		{
			Global.applyUIBGColor(rotateBG);
			Global.applyUIFGColor(rotateArrow);
			Global.applyUIFGColor(rotateCircle);
		}

		public function RotateCursorSet()
		{
			visible = false;
			setScale(1.0);
		}
	}
}
