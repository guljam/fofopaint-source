package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;

	public class traceButtons extends Sprite {
		public var traceOpaButton:SimpleButton;
		public var traceOpaBar:SimpleButton;

		public var traceButtonWrapper:SimpleButton;

		public var traceMenuMoveButton:SimpleButton;
		public var traceMenuBG:SimpleButton;
		public var traceMenuBG2:SimpleButton;

		public var traceImageButton:SimpleButton;
		public var traceClipButton:SimpleButton;
		public var traceLoadButton:SimpleButton;

		public var traceMoveButton:SimpleButton;
		public var traceMirrorButton:SimpleButton;
		public var traceResizeButton:SimpleButton;
		public var traceRotateButton:SimpleButton;
		public var traceCancelButton:SimpleButton;
		public var traceVisibleOFFButton:SimpleButton;
		public var traceVisibleONButton:SimpleButton;
		public var traceDeleteButton:SimpleButton;
		public var traceInfo:TextField;
		private var traceInfoBackup:Array = [];
		public const fixedScale:Number = 0.875;

		private const base:ColorTransform = new ColorTransform();
		private const subBase:ColorTransform = new ColorTransform();
		private const iconLeft:ColorTransform = new ColorTransform();
		private const iconRight:ColorTransform = new ColorTransform();
		private const activeColor:ColorTransform = new ColorTransform();
		private const activeIconColor:ColorTransform = new ColorTransform();

		private var leftButtonArr:Array;
		private var rightButtonArr:Array;

		public function changeUIColor(arr:Array,brightBarFlag:Boolean):void
		{
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

		public function getHintStr():String
		{
			return traceInfo.text;
		}

		public function hint(str:String):void
		{
			if(str.indexOf("\n") !== -1)
			{
				if(traceInfoBackup.length === 0)
				{
					traceInfoBackup[0] = traceInfo.y;
					traceInfoBackup[1] = traceInfo.height;
					traceInfoBackup[2] = traceMenuMoveButton.y;
					traceInfoBackup[3] = traceMenuMoveButton.height;
					traceInfo.y -= 18;
					traceInfo.height += 18;
					traceMenuMoveButton.y -= 18;
					traceMenuMoveButton.height += 18;
				}
			}
			else if(traceInfoBackup.length !== 0)
			{
				traceInfo.y = traceInfoBackup[0];
				traceInfo.height = traceInfoBackup[1];
				traceMenuMoveButton.y = traceInfoBackup[2];
				traceMenuMoveButton.height = 27;
				traceInfoBackup.length = 0;
			}
			traceInfo.text = str;
		}

		public function traceButtons()
		{
			visible = false;
			scaleX = fixedScale;
			scaleY = fixedScale;

			const offsetX:Number = traceOpaButton.width/2;

			traceOpaButton.x = traceOpaBar.x+offsetX+traceOpaBar.width*0.5-offsetX;
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

			leftButtonArr =
			[
				traceImageButton,
				traceClipButton,
				traceLoadButton,
			];

			rightButtonArr =
			[
				traceMoveButton,
				traceMirrorButton,
				traceResizeButton,
				traceRotateButton,
				traceVisibleOFFButton,
				traceVisibleONButton,
				traceDeleteButton,
			];
		}
	}
}
