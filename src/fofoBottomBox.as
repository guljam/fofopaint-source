package  {
	
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;
	
	public class fofoBottomBox extends Sprite {
		public var fofoBottom:SimpleButton = fofoBottom;

		public function flipImage(flag:Boolean):void
		{
			if(flag)
			{
				fofoBottom.scaleX = -1.0;
				fofoBottom.x = fofoBottom.width;
			}
			else
			{
				fofoBottom.x = 0;
				fofoBottom.scaleX = 1.0;
			}
		}

		public function setY(sideBarHeight:Number):void
		{
			y = sideBarHeight-height+2;
		}

		public function changeColor(color:uint):void
		{
			const c:ColorTransform = new ColorTransform();
			c.color = color;
			fofoBottom.transform.colorTransform = c;
		}
		
		public function fofoBottomBox() {
			fofoBottom.useHandCursor = false;
			alpha = 0.5;
			visible = false;

			scaleX = 0.65;
			scaleY = 0.65;
		}
	}
	
}
