package
{
	import flash.display.Sprite;
	import flash.display.Graphics;
	import flash.geom.ColorTransform;
	import flash.display.Shape;

	public class sidePanel extends Sprite {
		private const sideBG:Shape = new Shape();
		public const w:Number = 220;
		public var h:Number = 0;

		public function updateSideBGSize(sth:Number):void
		{
			sideBG.width = w;
			sideBG.height = sth;
			h = sth;
		}

		public function changeUIColor(color:uint,op:uint):void
		{
			const b:ColorTransform = new ColorTransform();
			const o:ColorTransform = new ColorTransform();
			b.color = color;
			o.color = op;
			o.alphaMultiplier = 0.25;
			sideBG.transform.colorTransform = b;
		}

		public function sidePanel()
		{
			const g:Graphics = sideBG.graphics;
            g.clear();
            g.lineStyle(0,0,0);
            g.beginFill(0xCCCCCC);
            g.drawRect(0,0,10,10);
            g.endFill();
			addChild(sideBG);
			cacheAsBitmap = true;
		}
	}
}
