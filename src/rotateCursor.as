package
{

	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;

	public class rotateCursor extends Sprite {
		public var rotateBG:SimpleButton;
		public var rotateArrow:SimpleButton;
		public var rotateCircle:SimpleButton;
		private const baseColor:ColorTransform = new ColorTransform();
		private const opColor:ColorTransform = new ColorTransform();
		private const fixedScale:Number = 0.7;

		public function setScale(scale:Number):void
		{
			this.scaleX = scale*fixedScale;
			this.scaleY = scale*fixedScale;
		}

		public function changeUIColor(base:uint,op:uint):void
		{
			baseColor.color = base;
			opColor.color = op;

			rotateBG.transform.colorTransform = baseColor;
			rotateArrow.transform.colorTransform = opColor;
			rotateCircle.transform.colorTransform = opColor;
		}

		public function rotateCursor() {
			visible = false;
			setScale(1.0);
		}
	}
}
