package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;

	
	public class traceButtons extends Sprite {
		public var traceOpaButton:SimpleButton = traceOpaButton;
		public var traceOpaBar:SimpleButton = traceOpaBar;

		public var traceButtonWrapper:SimpleButton = traceButtonWrapper;

		public var traceMenuMoveButton:SimpleButton = traceMenuMoveButton;
		public var traceMenuBG:SimpleButton = traceMenuBG;
		public var traceMenuBG2:SimpleButton = traceMenuBG2;

		public var traceImageButton:SimpleButton = traceImageButton;
		public var traceClipButton:SimpleButton = traceClipButton;
		public var traceLoadButton:SimpleButton = traceLoadButton;

		public var traceMoveButton:SimpleButton = traceMoveButton;
		public var traceMirrorButton:SimpleButton = traceMirrorButton;
		public var traceResizeButton:SimpleButton = traceResizeButton;
		public var traceRotateButton:SimpleButton = traceRotateButton;
		public var traceCancelButton:SimpleButton = traceCancelButton;
		public var traceVisibleOFFButton:SimpleButton = traceVisibleOFFButton;
		public var traceVisibleONButton:SimpleButton = traceVisibleONButton;
		public var traceDeleteButton:SimpleButton = traceDeleteButton;
		public var traceInfo:TextField = traceInfo;
		

		public function changeUIColor(arr:Array,brightBarFlag:Boolean):void
		{
			const leftButtonArr:Array =
			[
				traceImageButton,
				traceClipButton,
				traceLoadButton,
			];

			const rightButtonArr:Array =
			[
				traceMoveButton,
				traceMirrorButton,
				traceResizeButton,
				traceRotateButton,
				traceVisibleOFFButton,
				traceVisibleONButton,
				traceDeleteButton,
			];

			const base:ColorTransform = new ColorTransform();
			const subBase:ColorTransform = new ColorTransform();
			const iconLeft:ColorTransform = new ColorTransform();
			const iconRight:ColorTransform = new ColorTransform();
			const activeColor:ColorTransform = new ColorTransform();
			const activeIconColor:ColorTransform = new ColorTransform();
           	base.color = arr[0];
           	subBase.color = arr[1];
           	iconLeft.color = arr[2];
           	iconRight.color = arr[3];
           	activeColor.color = arr[4];
           	activeIconColor.color = arr[5];

			var i:uint = 0;
			var len:uint = leftButtonArr.length;
			var btn:SimpleButton ;
			var btnUp:DisplayObject;
			var btnOver:DisplayObjectContainer;

			for(i=0;i<len;i++)
			{
				btn = leftButtonArr[i];
				btnUp = btn.upState as DisplayObject;
				btnOver = btn.overState as DisplayObjectContainer;
				btnUp.transform.colorTransform = iconLeft;
				btnOver.getChildAt(0).transform.colorTransform = activeColor;//버튼 배경
				btnOver.getChildAt(1).transform.colorTransform = activeIconColor; //버튼 아이콘
				btn.downState = btn.overState;
			}

			len = rightButtonArr.length;
			for(i=0;i<len;i++)
			{
				btn = rightButtonArr[i];
				btnUp = btn.upState as DisplayObject;
				btnOver = btn.overState as DisplayObjectContainer;
				btnUp.transform.colorTransform = iconRight;
				btnOver.getChildAt(0).transform.colorTransform = activeColor; //d
				btnOver.getChildAt(1).transform.colorTransform = iconRight;
				btn.downState = btn.overState;
			};

			traceMenuMoveButton.transform.colorTransform = base;
			traceMenuBG.transform.colorTransform = base;
			traceMenuBG2.transform.colorTransform = subBase;
			traceCancelButton.transform.colorTransform = iconLeft;

			traceOpaBar.transform.colorTransform = iconLeft;
			traceOpaButton.transform.colorTransform = iconLeft;

			traceInfo.textColor = arr[2];
		}

		public function traceButtons() {
			// constructor code
			// alpha = 0.9;
			scaleX = 0.875;
			scaleY = 0.875;

			const offsetX:Number = traceOpaButton.width/2;
			const barWidth:Number = traceOpaBar.width*0.5;
			const buttonMin:Number = traceOpaBar.x+offsetX;
			traceOpaButton.x = buttonMin+barWidth-offsetX;

			visible = false;

			traceOpaButton.useHandCursor = false;
			traceOpaBar.useHandCursor = false;
			traceButtonWrapper.useHandCursor = false;
			traceMenuMoveButton.useHandCursor = false;
			traceMenuBG.useHandCursor = false;
			traceMenuBG2.useHandCursor = false;
			traceImageButton.useHandCursor = false;
			traceClipButton.useHandCursor = false;
			traceLoadButton.useHandCursor = false;
			traceMoveButton.useHandCursor = false;
			traceMirrorButton.useHandCursor = false;
			traceResizeButton.useHandCursor = false;
			traceRotateButton.useHandCursor = false;
			traceCancelButton.useHandCursor = false;
			traceVisibleOFFButton.useHandCursor = false;
			traceVisibleONButton.useHandCursor = false;
			traceDeleteButton.useHandCursor = false;
			traceVisibleONButton.visible = false;
		}
	}
}
