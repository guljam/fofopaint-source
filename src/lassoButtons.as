package
{

	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.text.TextFieldAutoSize;

	public class lassoButtons extends Sprite
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
		public var lassoTrace:SimpleButton;
		public var lasso1pxLeft:SimpleButton;
		public var lasso1pxRight:SimpleButton;
		public var lasso1pxDown:SimpleButton;
		public var lasso1pxUp:SimpleButton;
		public var lassoLayerSwap:SimpleButton;
		public var lassoLayerMerge:SimpleButton;
		private const fixedScale:Number = 0.875;

		private var lassoInfoPos:Array = [0,0];
		private const base:ColorTransform = new ColorTransform();
		private const subBase:ColorTransform = new ColorTransform();
		private const iconLeft:ColorTransform = new ColorTransform();
		private const iconRight:ColorTransform = new ColorTransform();
		private const activeColor:ColorTransform = new ColorTransform();
		private const activeIconColor:ColorTransform = new ColorTransform();
		private var leftButtonArr2:Array;
		private var rightButtonArr:Array;

		public function changeUIColor(arr:Array):void
		{
			base.color = arr[0];
			subBase.color = arr[1];
			iconLeft.color = arr[2];
			iconRight.color = arr[3];
			activeColor.color = arr[4];
			activeIconColor.color = arr[5];

			var i:uint = 0;
			var len:uint = leftButtonArr2.length;
			var btn:SimpleButton;
			var btnUp:DisplayObject;
			var btnOver:DisplayObjectContainer;

			for (i = 0; i < len; i++)
			{
				btn = leftButtonArr2[i];
				btnUp = btn.upState as DisplayObject;
				btnOver = btn.overState as DisplayObjectContainer;
				btnUp.transform.colorTransform = iconLeft;
				btnOver.getChildAt(0).transform.colorTransform = activeColor; // 버튼 배경
				btnOver.getChildAt(1).transform.colorTransform = activeIconColor;
				btn.downState = btn.overState;
			}

			len = rightButtonArr.length;
			for (i = 0; i < len; i++)
			{
				btn = rightButtonArr[i];
				btnUp = btn.upState as DisplayObject;
				btnOver = btn.overState as DisplayObjectContainer;
				btnUp.transform.colorTransform = iconRight;
				btnOver.getChildAt(0).transform.colorTransform = activeColor; //
				btnOver.getChildAt(1).transform.colorTransform = iconRight;
				btn.downState = btn.overState;
			}

			lassoMenuMoveButton.transform.colorTransform = base;
			lassoMenuBG.transform.colorTransform = base;
			lassoMenuBG2.transform.colorTransform = subBase;
			lassoInfo.textColor = arr[2];
		}

		public function getHintStr():String
		{
			return lassoInfo.text;
		}

		public function hint(str:String):void
		{
			lassoInfo.text = str;

			if(str.indexOf("\n") !== -1)
			{
				lassoInfo.y = lassoInfoPos[0]-(lassoInfo.height-lassoInfoPos[1])-3;
				lassoMenuMoveButton.y = lassoInfo.y;
			}
			else if(lassoInfoPos[0] !== lassoInfo.y)
			{
				lassoInfo.y = lassoInfoPos[0];
				lassoMenuMoveButton.y = 0;
			}

			lassoMenuMoveButton.height = lassoInfo.height+5;
		}

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale*fixedScale;
			this.scaleY = newScale*fixedScale;
		}

		public function lassoButtons()
		{
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
			lassoTrace.useHandCursor = false;
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

			leftButtonArr2 = [
								lassoOK,
								lassoCancel,
								lassoTrace,
								lassoLayerSwap,
								lassoLayerMerge
							 ];

			rightButtonArr = [
								lassoCopy,
								lassoRotate,
								lassoResize,
								lassoMirror,
								lasso1pxLeft,
								lasso1pxRight,
								lasso1pxUp,
								lasso1pxDown,
							 ];
		}
	}

}