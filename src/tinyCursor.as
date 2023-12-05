package
{
	import flash.display.SimpleButton;

	public class tinyCursor extends SimpleButton {

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale;
			this.scaleY = newScale;
		}

		public function tinyCursor() {
			// constructor code
			visible = false;
			mouseEnabled = false;
			useHandCursor = false;
		}
	}

}
