package
{

	import flash.display.Sprite;
	import flash.display.SimpleButton;

	public class penSizeList extends Sprite {
		public var penListResizeButton:SimpleButton = penListResizeButton;
		public var penListPanel:SimpleButton = penListPanel;

		public var shapeCircle:SimpleButton = shapeCircle;
		public var shapeRect:SimpleButton = shapeRect;

		public var opaBorder:SimpleButton = opaBorder;

		public function penSizeList() {
			// constructor code
			penListPanel.useHandCursor = false;
			opaBorder.useHandCursor = false;
			useHandCursor = false;
			visible = false;
		}
	}
}
