package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.display.Shape;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.ColorTransform;

	public class fillPenButtons extends Sprite
	{
		public var fillPenOK:SimpleButton = fillPenOK;
		public var fillPenCancel:SimpleButton = fillPenCancel;
		public var fillPenUndo:SimpleButton = fillPenUndo;
		public const fillPenBoxBG:Shape = new Shape();

		public function changeBGColor(arr:Array):void
		{
			const bgWidth:Number = fillPenOK.width * 2;

			fillPenBoxBG.graphics.clear();
			fillPenBoxBG.graphics.lineStyle(0, 0, 0);
			fillPenBoxBG.graphics.beginFill(arr[0]);
			fillPenBoxBG.graphics.drawRect(0, 0, bgWidth, bgWidth);
			fillPenBoxBG.graphics.endFill();

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

			iconLeft.color = arr[2];
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
				btn.downState = btn.overState;

			}
		}

		public function fillPenButtons()
		{
			visible = false;

			fillPenOK.useHandCursor = false;
			fillPenCancel.useHandCursor = false;
			fillPenUndo.useHandCursor = false;

			addChild(fillPenBoxBG);
			setChildIndex(fillPenBoxBG, 0);
			// constructor codedf
		}
	}

}

