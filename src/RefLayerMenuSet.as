package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.text.TextFieldAutoSize;

	public class RefLayerMenuSet extends Sprite {
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

		private var refLayerMenuInfoPos:Array = [0,0]; //y ,height
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
											refTransferCanvasImageButton,
											refClipBoardButton,
											refLoadImageButton,
										];

			const rightButtonArr:Array =[
											refMoveImageButton,
											refMirrorImageButton,
											refResizeImageButton,
											refRotateImageButton,
											refMemoryTrainingOffButton,
											refMemoryTrainingOnButton,
											refClearImageButton,
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

			refLayerMenuMoveButton.transform.colorTransform = base;
			refLayerMenuBGLeft.transform.colorTransform = base;
			refLayerMenuBGRight.transform.colorTransform = subBase;
			refMenuCloseButton.transform.colorTransform = iconLeft;

			refOpacityBar.transform.colorTransform = iconLeft;
			refOpacityCursor.transform.colorTransform = iconLeft;

			refInfoText.textColor = arr[2];
		}

		public function getHintStr():String
		{
			return refInfoText.text;
		}

		public function hint(str:String):void
		{
			refInfoText.text = str;

			if(str.indexOf("\n") !== -1)
			{
				refInfoText.y = refLayerMenuInfoPos[0]-(refInfoText.height-refLayerMenuInfoPos[1]);
				refLayerMenuMoveButton.y = Math.floor(refInfoText.y-3);
			}
			else if(refLayerMenuInfoPos[0] !== refInfoText.y)
			{
				refInfoText.y = refLayerMenuInfoPos[0];
				refLayerMenuMoveButton.y = 0;
			}
		}

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale*fixedScale;
			this.scaleY = newScale*fixedScale;
		}

		public function RefLayerMenuSet()
		{
			visible = false;

			fixedScale = 34/refTransferCanvasImageButton.width;
			setScale(1.0);

			const offsetX:Number = refOpacityCursor.width/2;

			refOpacityCursor.x = refOpacityBar.x+offsetX+refOpacityBar.width*0.5-offsetX;
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
