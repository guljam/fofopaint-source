package Symbols
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.geom.ColorTransform;
	import flash.events.MouseEvent;
	import flash.display.BitmapData;
	import assets.VisualBuilder;
	import assets.VisualFieldCollector;

	public class EyedropperLensSet extends Sprite
	{
		public const magSize:Number = 112;
		public const circleBox:Sprite = new Sprite();
		private const circleMask:Shape = new Shape();

		public var nowColor:SimpleButton;
		public var oldColor:SimpleButton;
		public var bitmap:Bitmap = new Bitmap(new BitmapData(magSize, magSize, true, 0));

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale;
			this.scaleY = newScale;
		}

		public function rotateBitmap(r:Number):void
		{
			circleBox.rotation = r;
		}

		[Embed(source="fofoPaint-animate-27.13.swf",symbol="EyedropperLensSet")]
		private static const EmbeddedClass:Class;

		public function EyedropperLensSet()
		{
			const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
			VisualBuilder.buildInto(this, EmbeddedClass, fields);

			visible = false;

			const halfMagSize:Number = magSize / 2;

			circleMask.graphics.beginFill(0);
			circleMask.graphics.drawCircle(-1, 0, halfMagSize + 2);
			circleMask.graphics.endFill();

			circleMask.x = 0;
			circleMask.y = 0;
			const z1:Number = Math.round(-magSize / 2);
			bitmap.x = z1;
			bitmap.y = z1;
			circleBox.addChild(bitmap);
			bitmap.mask = circleMask;

			addChild(circleBox);
			addChild(circleMask);
			setChildIndex(circleBox, 0);
			cacheAsBitmap = true;
		}
	}
}
