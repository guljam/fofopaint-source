package
{

	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;

	public class rotateCursor extends Sprite {
		public var rotateBG:SimpleButton = rotateBG;
		public var rotateArrow:SimpleButton = rotateArrow;
		public var rotateCircle:SimpleButton = rotateCircle;

		public function changeUIColor(base:uint,op:uint):void
		{
			const ct1:ColorTransform = new ColorTransform();
			const ct2:ColorTransform = new ColorTransform();
			ct1.color = base;
			ct2.color = op;

			rotateBG.transform.colorTransform = ct1;
			rotateArrow.transform.colorTransform = ct2;
			rotateCircle.transform.colorTransform = ct2;
		}

		public function rotateCursor() {
			visible = false;
			scaleX = 0.7;
			scaleY = 0.7;
		}
	}
}
