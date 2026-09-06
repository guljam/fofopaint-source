package symbols
{

	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import assets.VisualBuilder;
	import assets.VisualFieldCollector;

	public class FOFO extends Sprite
	{
		public var fofo:SimpleButton;
		public var constScale:Number = 0.65;
		public var topPos:Boolean = false;

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale * constScale;
			this.scaleY = newScale * constScale;
		}

		public function isTopPos():Boolean
		{
			return topPos;
		}

		public function setMirror(flag:Boolean):void
		{
			if (flag)
			{
				fofo.scaleX = -1.0;
				fofo.x = fofo.width;
			}
			else
			{
				fofo.x = 0;
				fofo.scaleX = 1.0;
			}
		}

		public function setTop(topY:Number):void
		{
			topPos = true;
			fofo.scaleY = -1.0;
			fofo.y = fofo.height;
			y = topY;
		}

		public function setBottom(sideBarHeight:Number):void
		{
			topPos = false;
			fofo.scaleY = 1.0;
			fofo.y = 0;
			y = sideBarHeight - height + 2;
		}

		public function updateColor():void
		{
			Global.applyUIFGColor(fofo);
		}

		[Embed(
            source="fofoPaint-animate-27.13.swf",
            symbol="FOFO"
        )]
		private static const EmbeddedClass:Class;

		public function FOFO()
		{
			const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
			VisualBuilder.buildInto(this,EmbeddedClass,fields);

			fofo.useHandCursor = false;
			alpha = 1.0;
			setScale(1.0);
		}
	}
}
