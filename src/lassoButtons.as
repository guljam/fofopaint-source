package
{

	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;

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
		public var lassoCHand:SimpleButton;
		public var lassoCZoom:SimpleButton;
		public var lassoCRotate:SimpleButton;
		public var lassoTrace:SimpleButton;
		public var lasso1pxLeft:SimpleButton;
		public var lasso1pxRight:SimpleButton;
		public var lasso1pxDown:SimpleButton;
		public var lasso1pxUp:SimpleButton;
		public const fixedScale:Number = 0.875;

		private var lassoInfoBackup:Array = [];
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
			if(str.indexOf("\n") !== -1)
			{
				if(lassoInfoBackup.length === 0)
				{
					lassoInfoBackup[0] = lassoInfo.y;
					lassoInfoBackup[1] = lassoInfo.height;
					lassoInfoBackup[2] = lassoMenuMoveButton.y;
					lassoInfoBackup[3] = lassoMenuMoveButton.height;

					lassoInfo.y -= 18;
					lassoInfo.height += 18;
					lassoMenuMoveButton.y -= 18;
					lassoMenuMoveButton.height += 18;
				}
			}
			else if(lassoInfoBackup.length !== 0)
			{
				lassoInfo.y = lassoInfoBackup[0];
				lassoInfo.height = lassoInfoBackup[1];
				lassoMenuMoveButton.y = lassoInfoBackup[2];
				lassoMenuMoveButton.height = 27;
				lassoInfoBackup.length = 0;
			}
			lassoInfo.text = str;
		}

		public function lassoButtons()
		{
			scaleX = fixedScale;
			scaleY = fixedScale;

			lassoMenuMoveButton.useHandCursor = false;
			lassoMenuBG.useHandCursor = false;
			lassoMenuBG2.useHandCursor = false;
			lassoRotate.useHandCursor = false;
			lassoResize.useHandCursor = false;
			lassoMirror.useHandCursor = false;
			lassoOK.useHandCursor = false;
			lassoCancel.useHandCursor = false;
			lassoCopy.useHandCursor = false;
			lassoCHand.useHandCursor = false;
			lassoCZoom.useHandCursor = false;
			lassoCRotate.useHandCursor = false;
			lassoTrace.useHandCursor = false;
			lasso1pxLeft.useHandCursor = false;
			lasso1pxRight.useHandCursor = false;
			lasso1pxDown.useHandCursor = false;
			lasso1pxUp.useHandCursor = false;
			visible = false;

			lassoInfo.text = "LASSO TOOL";

			leftButtonArr2 =[
								lassoOK,
								lassoCancel,
								lassoCHand,
								lassoCZoom,
								lassoCRotate,
								lassoTrace,
							];
							
			rightButtonArr =[
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