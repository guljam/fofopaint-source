package
{

	import flash.display.Sprite;
	import flash.display.SimpleButton;

	public class penSizeList extends Sprite {
		public var penListResizeButton:SimpleButton;
		public var penListPanel:SimpleButton;

		public var shapeCircle:SimpleButton;
		public var shapeRect:SimpleButton;

		public var opaBorder:SimpleButton;

		public function penSizeList() {
			// constructor code
			penListPanel.useHandCursor = false;
			opaBorder.useHandCursor = false;
			useHandCursor = false;
			visible = false;
		}
	}
}
