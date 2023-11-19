package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.display.Shape;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.ColorTransform;
	import flash.text.TextField;

	public class fillPenButtons extends Sprite
	{
		public var fillPenInfo:TextField;
		public var fillPenOK:SimpleButton;
		public var fillPenCancel:SimpleButton;
		public var fillPenUndo:SimpleButton;
		public const fillPenBoxBGTitle:Shape = new Shape();
		public const fillPenBoxBG:Shape = new Shape();

		public function hint(str:String):void
		{
			fillPenInfo.text = str;
		}

		public function changeBGColor(arr:Array):void
		{
			const bgWidth:Number = fillPenOK.width*3;

			fillPenBoxBG.graphics.clear();
			fillPenBoxBG.graphics.lineStyle(0,0,0);
			fillPenBoxBG.graphics.beginFill(arr[1]);
			fillPenBoxBG.graphics.drawRect(0,0,bgWidth,fillPenOK.height+fillPenInfo.height);
			fillPenBoxBG.graphics.endFill();

			fillPenBoxBGTitle.graphics.clear();
			fillPenBoxBGTitle.graphics.lineStyle(0,0,0);
			fillPenBoxBGTitle.graphics.beginFill(arr[0]);
			fillPenBoxBGTitle.graphics.drawRect(0,0,bgWidth,fillPenInfo.height);
			fillPenBoxBGTitle.graphics.endFill();

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

			for (var i:int = 0; i < len; i++)
			{
				btn = buttonArr[i];
				btnUp = btn.upState as DisplayObject;
				btnUp.transform.colorTransform = iconLeft;
				btnOver = btn.overState as DisplayObjectContainer;
				btnOver.getChildAt(1).transform.colorTransform = iconLeft; // 버튼 아이콘
				btnOver.getChildAt(0).transform.colorTransform = activeColor; // 버튼 배경
			}

			fillPenInfo.textColor = arr[2];
		}

		public function fillPenButtons()
		{
			visible = false;
			fillPenOK.useHandCursor = false;
			fillPenCancel.useHandCursor = false;
			fillPenUndo.useHandCursor = false;

			addChild(fillPenBoxBG);
			addChild(fillPenBoxBGTitle);
			setChildIndex(fillPenBoxBGTitle,0);
			setChildIndex(fillPenBoxBG,0);
		}
	}

}

