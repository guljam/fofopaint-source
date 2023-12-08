package  {

	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;

	public class canvasResizeButton extends SimpleButton {

		public function setColor(color:uint):void
		{
			const c:ColorTransform = new ColorTransform();
			c.color = color;
			transform.colorTransform = c;
		}

		public function canvasResizeButton() {
			// constructor code
			visible = false;
			useHandCursor = false;
		}
	}

}
