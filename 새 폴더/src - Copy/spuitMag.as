package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.display.Graphics;

	public class spuitMag extends Sprite {
		private const deafultZoom:Number = 2.0;
		public const magSize:Number = 112;
		public const spuitZoomBitmapBox:Sprite = new Sprite()
		private const circleMask:Shape = new Shape();

		public var magZoom:Number = 1.0;
		public var spuitNowColor:SimpleButton;
		public var spuitOldColor:SimpleButton;
		public var spuitZoomBitmap:Bitmap = new Bitmap();
		public var WIDTH:Number = width;
		public var HEIGHT:Number = height;

		public function rotateBitmap(r:Number):void
		{
			spuitZoomBitmapBox.rotation = r;
		}

		public function spuitMag() {
			visible = false;

			const halfMagSize:Number = magSize/2;
			const g:Graphics = circleMask.graphics;
			g.beginFill(0);
			g.drawCircle(-1,0,halfMagSize+2);
			g.endFill();

			circleMask.x = 0;
			circleMask.y = 0;
			const z1:Number = Math.round(-magSize/2);
			spuitZoomBitmap.x = z1;
			spuitZoomBitmap.y = z1;
			spuitZoomBitmapBox.addChild(spuitZoomBitmap);
			spuitZoomBitmap.mask = circleMask;

			addChild(spuitZoomBitmapBox);
			addChild(circleMask);
			setChildIndex(spuitZoomBitmapBox,0);
		}
	}
}
