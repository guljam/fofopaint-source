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
	import Modules.L1Data.UIEngine.UITheme;
	import Modules.L4UI.UIEngine.MenuBoxBorderUI;

	// 층: L4 UI - 참조 레이어 메뉴 화면 묶음
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
		private var menuBoxBorderUI:MenuBoxBorderUI; //배경 조각의 겉 테두리를 해진 모양으로 자르는 마스크 (생성자 맨 끝에서 만듦)
		private static const MENU_BOX_BORDER_SEED:uint = 403;

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

			for (i = 0;i < len;i++)
			{
				btn = leftButtonArr[i];
				btnUp = btn.upState as DisplayObject;
				btnOver = btn.overState as DisplayObjectContainer;
				UITheme.applyToolBoxButtonUpBGColor(btnUp);
				UITheme.setButtonColorWithBG(btnOver, 4, 5);
				btn.downState = btn.overState;
			}

			len = rightButtonArr.length;
			for (i = 0;i < len;i++)
			{
				btn = rightButtonArr[i];
				btnUp = btn.upState as DisplayObject;
				btnOver = btn.overState as DisplayObjectContainer;

				UITheme.applyToolBoxButtonUpFGColor(btnUp);
				UITheme.setButtonColorWithBG(btnOver, 4, 3);
				btn.downState = btn.overState;
			};

			UITheme.applyToolBoxBGColor(refLayerMenuMoveButton);
			UITheme.applyToolBoxBGColor(refLayerMenuBGLeft);
			UITheme.applyToolBoxBGTopColor(refLayerMenuBGRight);
			UITheme.applyToolBoxButtonUpBGColor(refMenuCloseButton);
			UITheme.applyToolBoxButtonUpBGColor(refOpacityBar);
			UITheme.applyToolBoxButtonUpBGColor(refOpacityCursor);

			refInfoText.textColor = UITheme.getToolBoxButtonUpBGColor();
		}

		public function getHintStr():String
		{
			return refInfoText.text;
		}

		// 힌트 글자를 바꿈. 여러 줄이면 글자와 이동 버튼 배경(refLayerMenuMoveButton)을 위로 올렸다가 한 줄이 되면 되돌리고, 바뀐 배경에 맞춰 가장자리 마스크를 갱신함.
		// 이동 버튼은 위쪽 변이 EXTEND_PX 늘어나 있어서 그만큼 더 위가 기준 위치임
		public function hint(str:String):void
		{
			refInfoText.text = str;

			if (str.indexOf("\n") !== -1)
			{
				refInfoText.y = refLayerMenuInfoPos[0] - (refInfoText.height - refLayerMenuInfoPos[1]);
				refLayerMenuMoveButton.y = Math.floor(refInfoText.y - 3) - MenuBoxBorderUI.EXTEND_PX;
			}
			else if (refLayerMenuInfoPos[0] !== refInfoText.y)
			{
				refInfoText.y = refLayerMenuInfoPos[0];
				refLayerMenuMoveButton.y = -MenuBoxBorderUI.EXTEND_PX;
			}

			menuBoxBorderUI.updateMenuBoxBorderRect();
		}

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale * constScale;
			this.scaleY = newScale * constScale;
		}

		[Embed(source="fofoPaint-animate-27.13.swf",symbol="RefLayerMenuSet")]
		private static const EmbeddedClass:Class;

		public function RefLayerMenuSet()
		{
			const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
			VisualBuilder.buildInto(this, EmbeddedClass, fields);

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

			menuBoxBorderUI = new MenuBoxBorderUI(this, [refLayerMenuMoveButton, refLayerMenuBGLeft, refLayerMenuBGRight], [], MENU_BOX_BORDER_SEED);
		}
	}
}
