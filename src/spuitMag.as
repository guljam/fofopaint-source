package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;
	import flash.display.Shape;
	import flash.display.Graphics;

	public class spuitMag extends Sprite {

		public var spuitNowColor:SimpleButton = spuitNowColor;
		public var spuitOldColor:SimpleButton = spuitOldColor;
		public const historyColorFoundCircle:Shape = new Shape();

		public function setCircleColor(color:uint):void
		{
			const c:ColorTransform = new ColorTransform();
			c.color = color;
			historyColorFoundCircle.transform.colorTransform = c;
		}

		public function setCircleVisible(flag:Boolean):void
		{
			historyColorFoundCircle.visible = flag;
		}

		public function spuitMag() {
			const g:Graphics = historyColorFoundCircle.graphics;
			g.lineStyle(0,0,0);
			g.beginFill(0);
			g.drawCircle(0,0,5);
			g.endFill();

			historyColorFoundCircle.y = -107;
			addChild(historyColorFoundCircle);

			visible = false;
		}
	}

}
