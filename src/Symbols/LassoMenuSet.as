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
	import Modules.L1Data.Utils;
	import Modules.L1Data.UIEngine.UITheme;
	import Modules.L4UI.UIEngine.MenuBoxBorderUI;

	// 층: L4 UI - 올가미 메뉴 화면 묶음
	public class LassoMenuSet extends Sprite
	{
		public var lassoMenuMoveButton:SimpleButton;
		public var lassoMenuBG:SimpleButton;
		public var lassoMenuBG2:SimpleButton;
		public var lassoRotate:SimpleButton;
		public var lassoResize:SimpleButton;
		public var lassoMirror:SimpleButton;
		public var lassoOK:SimpleButton;
		public var lassoCancel:SimpleButton;
		public var lassoCopy:SimpleButton;
		public var lassoInfo:TextField;
		public var lassoRefLayer:SimpleButton;
		public var lasso1pxLeft:SimpleButton;
		public var lasso1pxRight:SimpleButton;
		public var lasso1pxDown:SimpleButton;
		public var lasso1pxUp:SimpleButton;
		public var lassoLayerSwap:SimpleButton;
		public var lassoLayerMerge:SimpleButton;
		private const constScale:Number = 0.875;

		private var lassoInfoPos:Array = [0, 0];
		private var menuBoxBorderUI:MenuBoxBorderUI; //배경 조각의 겉 테두리를 해진 모양으로 자르는 마스크 (생성자 맨 끝에서 만듦)
		private static const MENU_BOX_BORDER_SEED:uint = 402;
		private static const MENU_BOX_BORDER_EROSION_SCALE:Number = 1.1; //이 상자 가장자리 깎임 강도 배율 (1.0이 기본)

		public function updateUIColor():void
		{
			const leftButtonArr2:Array = [
					lassoOK,
					lassoCancel,
					lassoRefLayer,
					lassoLayerSwap,
					lassoLayerMerge
				];

			const rightButtonArr:Array = [
					lassoCopy,
					lassoRotate,
					lassoResize,
					lassoMirror,
					lasso1pxLeft,
					lasso1pxRight,
					lasso1pxUp,
					lasso1pxDown,
				];

			var i:uint = 0;
			var btn:SimpleButton;

			for (i = 0;i < leftButtonArr2.length;i++)
			{
				btn = leftButtonArr2[i];
				UITheme.applyToolBoxButtonUpBGColor(btn.upState as DisplayObject);
				UITheme.setButtonColorWithBG(btn.overState as DisplayObjectContainer, 4, 5);
				btn.downState = btn.overState;
			}

			for (i = 0;i < rightButtonArr.length;i++)
			{
				btn = rightButtonArr[i];
				// Utils.setColorTransform(btn.upState as DisplayObject,0xFF0000);
				UITheme.applyToolBoxButtonUpFGColor(btn.upState as DisplayObject);
				UITheme.setButtonColorWithBG(btn.overState as DisplayObjectContainer, 4, 3, 1.0);
				btn.downState = btn.overState;
			}

			UITheme.applyToolBoxBGColor(lassoMenuMoveButton);
			UITheme.applyToolBoxBGColor(lassoMenuBG);
			UITheme.applyToolBoxBGTopColor(lassoMenuBG2);
			lassoInfo.textColor = UITheme.getToolBoxButtonUpBGColor();
		}

		public function getHintStr():String
		{
			return lassoInfo.text;
		}

		// 힌트 글자를 바꿈. 여러 줄이면 글자와 이동 버튼 배경(lassoMenuMoveButton)을 위로 올렸다가 한 줄이 되면 되돌리고, 바뀐 배경에 맞춰 가장자리 마스크를 갱신함.
		// 이동 버튼은 위쪽 변이 EXTEND_PX 늘어나 있어서 그만큼 더 위가 기준 위치임
		public function hint(str:String):void
		{
			lassoInfo.text = str;

			if (str && str.indexOf("\n") !== -1)
			{
				lassoInfo.y = lassoInfoPos[0] - (lassoInfo.height - lassoInfoPos[1]);
				lassoMenuMoveButton.y = Math.floor(lassoInfo.y - 3) - MenuBoxBorderUI.EXTEND_PX;
			}
			else if (lassoInfoPos[0] !== lassoInfo.y)
			{
				lassoInfo.y = lassoInfoPos[0];
				lassoMenuMoveButton.y = -MenuBoxBorderUI.EXTEND_PX;
			}

			menuBoxBorderUI.updateMenuBoxBorderRect();

			// lassoMenuMoveButton.height = lassoInfo.height+5;
		}

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale * constScale;
			this.scaleY = newScale * constScale;
		}

		[Embed(source="fofoPaint-animate-27.13.swf",symbol="LassoMenuSet")]
		private static const EmbeddedClass:Class;

		public function LassoMenuSet()
		{
			const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
			VisualBuilder.buildInto(this, EmbeddedClass, fields);

			setScale(1.0);

			lassoMenuMoveButton.useHandCursor = false;
			lassoMenuBG.mouseEnabled = false;
			lassoMenuBG2.mouseEnabled = false;
			lassoRotate.useHandCursor = false;
			lassoResize.useHandCursor = false;
			lassoMirror.useHandCursor = false;
			lassoOK.useHandCursor = false;
			lassoCancel.useHandCursor = false;
			lassoCopy.useHandCursor = false;
			lassoRefLayer.useHandCursor = false;
			lasso1pxLeft.useHandCursor = false;
			lasso1pxRight.useHandCursor = false;
			lasso1pxDown.useHandCursor = false;
			lasso1pxUp.useHandCursor = false;
			lassoLayerSwap.useHandCursor = false;
			lassoLayerMerge.useHandCursor = false;
			visible = false;

			lassoInfo.text = "LASSO TOOL";
			lassoInfo.autoSize = TextFieldAutoSize.LEFT;
			lassoInfo.mouseEnabled = false;
			lassoInfoPos[0] = lassoInfo.y;
			lassoInfoPos[1] = lassoInfo.height;

			menuBoxBorderUI = new MenuBoxBorderUI(this, [lassoMenuBG, lassoMenuMoveButton, lassoMenuBG2], [], MENU_BOX_BORDER_SEED, MENU_BOX_BORDER_EROSION_SCALE);
		}
	}
}
