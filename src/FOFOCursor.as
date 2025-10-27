package
{
	import flash.display.SimpleButton;

	public class FOFOCursor extends SimpleButton {

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale;
			this.scaleY = newScale;
		}

		public function FOFOCursor() {
			// constructor code
			visible = false;
			mouseEnabled = false;
			useHandCursor = false;
		}
	}
}
