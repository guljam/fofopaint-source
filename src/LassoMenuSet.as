package
{

	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.text.TextFieldAutoSize;

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

			for (i = 0; i < leftButtonArr2.length; i++)
			{
				btn = leftButtonArr2[i];
				Global.applyToolBoxButtonUpBGColor(btn.upState as DisplayObject);
				Global.setButtonColorWithBG(btn.overState as DisplayObjectContainer, 4, 5);
				btn.downState = btn.overState;
			}

			for (i = 0; i < rightButtonArr.length; i++)
			{
				btn = rightButtonArr[i];
				// Global.setColorTransform(btn.upState as DisplayObject,0xFF0000);
				Global.applyToolBoxButtonUpFGColor(btn.upState as DisplayObject);
				Global.setButtonColorWithBG(btn.overState as DisplayObjectContainer, 4, 3,1.0);
				btn.downState = btn.overState;
			}

			Global.applyToolBoxBGColor(lassoMenuMoveButton);
			Global.applyToolBoxBGColor(lassoMenuBG);
			Global.applyToolBoxBGTopColor(lassoMenuBG2);
			lassoInfo.textColor = Global.getToolBoxButtonUpBGColor();
		}

		public function getHintStr():String
		{
			return lassoInfo.text;
		}

		public function hint(str:String):void
		{
			lassoInfo.text = str;

			if (str && str.indexOf("\n") !== -1)
			{
				lassoInfo.y = lassoInfoPos[0] - (lassoInfo.height - lassoInfoPos[1]);
				lassoMenuMoveButton.y = Math.floor(lassoInfo.y - 3);
			}
			else if (lassoInfoPos[0] !== lassoInfo.y)
			{
				lassoInfo.y = lassoInfoPos[0];
				lassoMenuMoveButton.y = 0;
			}

			// lassoMenuMoveButton.height = lassoInfo.height+5;
		}

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale * constScale;
			this.scaleY = newScale * constScale;
		}

		public function LassoMenuSet()
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
		}
	}
}