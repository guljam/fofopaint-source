package
{

	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;

	public class FOFO extends Sprite
	{
		public var fofo:SimpleButton;
		public var fixedScale:Number = 0.65;
		public var topPos:Boolean = false;

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale * fixedScale;
			this.scaleY = newScale * fixedScale;
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

		public function changeColor(color:uint):void
		{
			const c:ColorTransform = new ColorTransform();
			c.color = color;
			fofo.transform.colorTransform = c;
		}

		public function FOFO()
		{
			fofo.useHandCursor = false;
			alpha = 1.0;
			setScale(1.0);
		}
	}
}
