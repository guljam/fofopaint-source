package Symbols
{
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import assets.VisualFieldCollector;

	public class FOFOCursorSet extends Sprite
	{
		private var fofoCursor:SimpleButton;
		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale;
			this.scaleY = newScale;
		}

		[Embed(source="fofoPaint-animate-27.13.swf",symbol="FOFOCursor")]
		private static const EmbeddedClass:Class;

		public function FOFOCursorSet()
		{
			fofoCursor = new EmbeddedClass() as SimpleButton;
			this.addChild(fofoCursor);
			visible = false;
			mouseEnabled = false;
			useHandCursor = false;
		}
	}
}
