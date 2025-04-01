package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.text.TextFieldAutoSize;

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
		private var traceInfoPos:Array = [0,0];
		private var fixedScale:Number = 1.0;

		public function changeUIColor(arr:Array,brightBarFlag:Boolean):void
		{

			const base:ColorTransform = new ColorTransform();
			const subBase:ColorTransform = new ColorTransform();
			const iconLeft:ColorTransform = new ColorTransform();
			const iconRight:ColorTransform = new ColorTransform();
			const activeColor:ColorTransform = new ColorTransform();
			const activeIconColor:ColorTransform = new ColorTransform();


			const leftButtonArr:Array = [
											traceImageButton,
											traceClipButton,
											traceLoadButton,
										];

			const rightButtonArr:Array =[
											traceMoveButton,
											traceMirrorButton,
											traceResizeButton,
											traceRotateButton,
											traceVisibleOFFButton,
											traceVisibleONButton,
											traceDeleteButton,
										];

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
			traceInfo.text = str;

			if(str.indexOf("\n") !== -1)
			{
				traceInfo.y = traceInfoPos[0]-(traceInfo.height-traceInfoPos[1]);
				traceMenuMoveButton.y = Math.floor(traceInfo.y-3);
			}
			else if(traceInfoPos[0] !== traceInfo.y)
			{
				traceInfo.y = traceInfoPos[0];
				traceMenuMoveButton.y = 0;
			}

			// traceMenuMoveButton.height = traceInfo.height+5;
		}

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale*fixedScale;
			this.scaleY = newScale*fixedScale;
		}

		public function traceButtons()
		{
			visible = false;

			fixedScale = 34/traceImageButton.width;
			setScale(1.0);

			const offsetX:Number = traceOpaButton.width/2;

			traceOpaButton.x = traceOpaBar.x+offsetX+traceOpaBar.width*0.5-offsetX;
			traceOpaButton.useHandCursor = false;
			traceOpaBar.useHandCursor = false;
			traceButtonWrapper.useHandCursor = false;
			traceMenuMoveButton.useHandCursor = false;
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
			traceMenuBG.mouseEnabled = false;
			traceMenuBG2.mouseEnabled = false;

			traceInfo.mouseEnabled = false;
			traceInfo.autoSize = TextFieldAutoSize.LEFT;
			traceInfoPos[0] = traceInfo.y;
			traceInfoPos[1] = traceInfo.height;
		}
	}
}
