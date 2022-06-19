package  {
	
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;
	
	public class canvasResizeButton extends SimpleButton {
		
		public function setColor(color:uint):void
		{
			const c1:ColorTransform = new ColorTransform();
			c1.color = color;
			transform.colorTransform = c1;
		}
		
		public function canvasResizeButton() {
			// constructor code
			useHandCursor = false;
		}
	}
	
}
