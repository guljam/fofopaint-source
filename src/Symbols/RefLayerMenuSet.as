package Symbols
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.text.TextFieldAutoSize;
	import assets.VisualBuilder;
	import assets.VisualFieldCollector;

	public class RefLayerMenuSet extends Sprite
	{
		public var refInfoText:TextField;
		public var refMenuCloseButton:SimpleButton;
		public var refLayerMenuMoveButton:SimpleButton;

		public var refTransferCanvasImageButton:SimpleButton;
		public var refLoadImageButton:SimpleButton;
		public var refClipBoardButton:SimpleButton;
		public var refLayerMenuBGLeft:SimpleButton;

		public var refOpacityCursor:SimpleButton;
		public var refOpacityBar:SimpleButton;
		public var refOpacitySliderWrapper:SimpleButton;

		public var refMoveImageButton:SimpleButton;
		public var refRotateImageButton:SimpleButton;
		public var refResizeImageButton:SimpleButton;
		public var refMirrorImageButton:SimpleButton;
		public var refMemoryTrainingOnButton:SimpleButton;
		public var refMemoryTrainingOffButton:SimpleButton;
		public var refClearImageButton:SimpleButton;
		public var refLayerMenuBGRight:SimpleButton;

		private var refLayerMenuInfoPos:Array = [0, 0]; // y ,height
		private var constScale:Number = 1.0;

		public function updateUIColor():void
		{
			const leftButtonArr:Array = [
					refTransferCanvasImageButton,
					refClipBoardButton,
					refLoadImageButton,
				];

			const rightButtonArr:Array = [
					refMoveImageButton,
					refMirrorImageButton,
					refResizeImageButton,
					refRotateImageButton,
					refMemoryTrainingOffButton,
					refMemoryTrainingOnButton,
					refClearImageButton,
				];

			var i:uint = 0;
			var len:uint = leftButtonArr.length;
			var btn:SimpleButton;
			var btnUp:DisplayObject;
			var btnOver:DisplayObjectContainer;

			for (i = 0; i < len; i++)
			{
				btn = leftButtonArr[i];
				btnUp = btn.upState as DisplayObject;
				btnOver = btn.overState as DisplayObjectContainer;
				Global.applyToolBoxButtonUpBGColor(btnUp);
				Global.setButtonColorWithBG(btnOver,4,5);
				btn.downState = btn.overState;
			}

			len = rightButtonArr.length;
			for (i = 0; i < len; i++)
			{
				btn = rightButtonArr[i];
				btnUp = btn.upState as DisplayObject;
				btnOver = btn.overState as DisplayObjectContainer;

				Global.applyToolBoxButtonUpFGColor(btnUp);
				Global.setButtonColorWithBG(btnOver,4,3);
				btn.downState = btn.overState;
			};

			Global.applyToolBoxBGColor(refLayerMenuMoveButton);
			Global.applyToolBoxBGColor(refLayerMenuBGLeft);
			Global.applyToolBoxBGTopColor(refLayerMenuBGRight);
			Global.applyToolBoxButtonUpBGColor(refMenuCloseButton);
			Global.applyToolBoxButtonUpBGColor(refOpacityBar);
			Global.applyToolBoxButtonUpBGColor(refOpacityCursor);

			refInfoText.textColor = Global.getToolBoxButtonUpBGColor();
		}

		public function getHintStr():String
		{
			return refInfoText.text;
		}

		public function hint(str:String):void
		{
			refInfoText.text = str;

			if (str.indexOf("\n") !== -1)
			{
				refInfoText.y = refLayerMenuInfoPos[0] - (refInfoText.height - refLayerMenuInfoPos[1]);
				refLayerMenuMoveButton.y = Math.floor(refInfoText.y - 3);
			}
			else if (refLayerMenuInfoPos[0] !== refInfoText.y)
			{
				refInfoText.y = refLayerMenuInfoPos[0];
				refLayerMenuMoveButton.y = 0;
			}
		}

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale * constScale;
			this.scaleY = newScale * constScale;
		}

		[Embed(
            source="fofoPaint-animate-27.13.swf",
            symbol="RefLayerMenuSet"
        )]
		private static const EmbeddedClass:Class;

		public function RefLayerMenuSet()
		{
			const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
			VisualBuilder.buildInto(this,EmbeddedClass,fields);

			visible = false;

			constScale = 34 / refTransferCanvasImageButton.width;
			setScale(1.0);

			const offsetX:Number = refOpacityCursor.width / 2;

			refOpacityCursor.x = refOpacityBar.x + offsetX + refOpacityBar.width * 0.5 - offsetX;
			refOpacityCursor.useHandCursor = false;
			refOpacityBar.useHandCursor = false;
			refOpacitySliderWrapper.useHandCursor = false;
			refLayerMenuMoveButton.useHandCursor = false;
			refTransferCanvasImageButton.useHandCursor = false;
			refClipBoardButton.useHandCursor = false;
			refLoadImageButton.useHandCursor = false;
			refMoveImageButton.useHandCursor = false;
			refMirrorImageButton.useHandCursor = false;
			refResizeImageButton.useHandCursor = false;
			refRotateImageButton.useHandCursor = false;
			refMenuCloseButton.useHandCursor = false;
			refMemoryTrainingOffButton.useHandCursor = false;
			refMemoryTrainingOnButton.useHandCursor = false;
			refClearImageButton.useHandCursor = false;
			refMemoryTrainingOnButton.visible = false;
			refLayerMenuBGLeft.mouseEnabled = false;
			refLayerMenuBGRight.mouseEnabled = false;

			refInfoText.mouseEnabled = false;
			refInfoText.autoSize = TextFieldAutoSize.LEFT;
			refLayerMenuInfoPos[0] = refInfoText.y;
			refLayerMenuInfoPos[1] = refInfoText.height;
		}
	}
}
