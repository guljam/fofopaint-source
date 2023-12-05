package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.ColorTransform;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.geom.ColorTransform;


	public class fillPenButtons extends Sprite
	{
		public var fillPenInfo:TextField;
		public var fillPenOK:SimpleButton;
		public var fillPenCancel:SimpleButton;
		public var fillPenUndo:SimpleButton;
		public var fillPenBGTitle:SimpleButton;
		public var fillPenBG:SimpleButton;
		private const fillPenInfoPos:Array = [0,0];
		private var fixedScale:Number = 1.0;
		private const baseColor:ColorTransform = new ColorTransform();
		private const opColor:ColorTransform = new ColorTransform();

		public function hint(str:String):void
		{
			fillPenInfo.text = str;

			if(str.indexOf("\n") !== -1)
			{
				fillPenInfo.y = fillPenInfoPos[0]-(fillPenInfo.height-fillPenInfoPos[1])-3;
				fillPenBGTitle.y = fillPenInfo.y;
			}
			else if(fillPenInfoPos[0] !== fillPenInfo.y)
			{
				fillPenInfo.y = fillPenInfoPos[0];
				fillPenBGTitle.y = 0;
			}

			fillPenBGTitle.height = fillPenInfo.height+5;
		}

		public function changeBGColor(arr:Array):void
		{
			const bgWidth:Number = fillPenOK.width*2+fillPenCancel.width;

			baseColor.color = arr[0];
			opColor.color = arr[1];

			fillPenBGTitle.transform.colorTransform = baseColor;
			fillPenBG.transform.colorTransform = opColor;

			const buttonArr:Array =
			[
				fillPenUndo,
				fillPenOK,
				fillPenCancel
			];

			var len:int = buttonArr.length;
			var btn:SimpleButton;
			var btnUp:DisplayObject;
			var btnOver:DisplayObjectContainer;

			const iconLeft:ColorTransform = new ColorTransform();
			const activeColor:ColorTransform = new ColorTransform();

			iconLeft.color = arr[3];
			activeColor.color = arr[4];
			activeColor.alphaMultiplier = 0.7;

			for (var i:uint = 0; i < len; i++)
			{
				btn = buttonArr[i];
				btnUp = btn.upState as DisplayObject;
				btnUp.transform.colorTransform = iconLeft;
				btnOver = btn.overState as DisplayObjectContainer;
				btnOver.getChildAt(1).transform.colorTransform = iconLeft; // 버튼 아이콘
				btnOver.getChildAt(0).transform.colorTransform = activeColor; // 버튼 배경
				btn.downState = btn.overState;
			}

			fillPenInfo.textColor = arr[2];
		}

		public function getScale():Number
		{
			return scaleX;
		}

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale*fixedScale;
			this.scaleY = newScale*fixedScale;
		}

		public function fillPenButtons()
		{
			fixedScale = 34/fillPenCancel.width;
			setScale(1.0);

			visible = false;
			fillPenOK.useHandCursor = false;
			fillPenCancel.useHandCursor = false;
			fillPenUndo.useHandCursor = false;
			fillPenInfo.autoSize = TextFieldAutoSize.LEFT;
			fillPenInfoPos[0] = fillPenInfo.y;
			fillPenInfoPos[1] = fillPenInfo.height;
		}
	}

}

