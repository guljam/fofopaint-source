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
		public var lassoMenuMoveButton:SimpleButton = lassoMenuBG;
		public var lassoMenuBG:SimpleButton = lassoMenuBG;
		public var lassoMenuBG2:SimpleButton = lassoMenuBG2;
		public var lassoRotate:SimpleButton = lassoRotate;
		public var lassoResize:SimpleButton = lassoResize;
		public var lassoMirror:SimpleButton = lassoMirror;
		public var lassoOK:SimpleButton = lassoOK;
		public var lassoCancel:SimpleButton = lassoCancel;
		public var lassoCopy:SimpleButton = lassoCopy;
		public var lassoInfo:TextField = lassoInfo;
		public var lassoCHand:SimpleButton = lassoCHand;
		public var lassoCZoom:SimpleButton = lassoCZoom;
		public var lassoCRotate:SimpleButton = lassoCRotate;
		public var lasso1pxLeft:SimpleButton = lasso1pxLeft;
		public var lasso1pxRight:SimpleButton = lasso1pxRight;
		public var lasso1pxDown:SimpleButton = lasso1pxDown;
		public var lasso1pxUp:SimpleButton = lasso1pxUp;

		public function changeUIColor(arr:Array):void
		{
			// const leftButtonArr:Array =
			// 	[
			// 		lassoOK,
			// 		lassoCancel
			// 	];

			const leftButtonArr2:Array =
				[
					lassoOK,
					lassoCancel,
					lassoCHand,
					lassoCZoom,
					lassoCRotate,
				];
			const rightButtonArr:Array =
				[
					lassoCopy,
					lassoRotate,
					lassoResize,
					lassoMirror,
					lasso1pxLeft,
					lasso1pxRight,
					lasso1pxUp,
					lasso1pxDown,
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
			var len:uint = leftButtonArr2.length;
			var btn:SimpleButton;
			var btnUp:DisplayObject;
			var btnOver:DisplayObjectContainer;

			// for (i = 0; i < len; i++)
			// {
			// 	btn = leftButtonArr[i];
			// 	btnOver = btn.overState as DisplayObjectContainer;
			// 	btnOver.getChildAt(0).transform.colorTransform = activeColor; // 버튼 배경
			// 	btnOver.getChildAt(1).transform.colorTransform = activeIconColor;
			// 	btn.downState = btn.overState;
			// }

			// len = leftButtonArr2.length;

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

		public function lassoButtons()
		{
			// const shadow:DropShadowFilter = new DropShadowFilter();
			// shadow.blurX = 7;
			// shadow.blurY = 7;
			// shadow.alpha = 0.2;
			// shadow.distance = 7;
			// shadow.strength	= 1;
			// shadow.angle = 30;
			// filters = [shadow];

			// alpha = 0.9;
			scaleX = 0.875;
			scaleY = 0.875;

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
			lasso1pxLeft.useHandCursor = false;
			lasso1pxRight.useHandCursor = false;
			lasso1pxDown.useHandCursor = false;
			lasso1pxUp.useHandCursor = false;
			visible = false;

			lassoInfo.text = "LASSO TOOL";
		}
	}

}


