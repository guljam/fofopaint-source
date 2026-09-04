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
	import assets.VisualBuilder;
	import assets.VisualFieldCollector;

	public class FillPenMenuSet extends Sprite
	{
		public var fillPenInfo:TextField;
		public var fillPenOK:SimpleButton;
		public var fillPenCancel:SimpleButton;
		public var fillPenUndo:SimpleButton;
		public var fillPenBGTitle:SimpleButton;
		public var fillPenBG:SimpleButton;
		public var fillPenSidebar:SimpleButton;
		private const fillPenInfoPos:Array = [0, 0];
		private var constScale:Number = 1.0;
		private const baseColor:ColorTransform = new ColorTransform();
		private const opColor:ColorTransform = new ColorTransform();

		public function hint(str:String):void
		{
			fillPenInfo.text = str;

			if (str && str.indexOf("\n") !== -1)
			{
				fillPenInfo.y = fillPenInfoPos[0] - (fillPenInfo.height - fillPenInfoPos[1]);
				fillPenBGTitle.y = Math.floor(fillPenInfo.y - 3);
			}
			else if (fillPenInfoPos[0] !== fillPenInfo.y)
			{
				fillPenInfo.y = fillPenInfoPos[0];
				fillPenBGTitle.y = 0;
			}
		}

		public function updateUIColor():void
		{
			Global.applyToolBoxBGColor(fillPenBGTitle);
			Global.applyToolBoxBGTopColor(fillPenBG);

			const buttonArr:Array =
				[
					fillPenUndo,
					fillPenOK,
					fillPenCancel,
					fillPenSidebar
				];

			var len:int = buttonArr.length;
			var btn:SimpleButton;
			var btnUp:DisplayObject;

			// iconLeft.color = arr[3];
			// activeColor.color = arr[4];
			// activeColor.alphaMultiplier = 0.7;

			for (var i:uint = 0; i < len; i++)
			{
				btn = buttonArr[i];

				Global.applyToolBoxButtonUpFGColor(btn.upState as DisplayObject);
				Global.setButtonColorWithBG(btn.overState as DisplayObjectContainer,4,3);

				btn.downState = btn.overState;
			}

			fillPenInfo.textColor = Global.getToolBoxButtonUpBGColor();
		}

		public function getScale():Number
		{
			return scaleX;
		}

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale * constScale;
			this.scaleY = newScale * constScale;
		}

		[Embed(
            source="../raw_resource/source/fofoPaint-animate-27.13.swf",
            symbol="FillPenMenuSet"
        )]
		private static const EmbeddedClass:Class;

		public function FillPenMenuSet()
		{
			const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
			VisualBuilder.buildInto(this,EmbeddedClass,fields);
			
			constScale = 34 / fillPenCancel.width;
			setScale(1.0);

			visible = false;
			fillPenBGTitle.mouseEnabled = false;
			fillPenBG.mouseEnabled = false;
			fillPenOK.useHandCursor = false;
			fillPenCancel.useHandCursor = false;
			fillPenUndo.useHandCursor = false;
			fillPenSidebar.useHandCursor = false;
			fillPenInfo.autoSize = TextFieldAutoSize.LEFT;
			fillPenInfoPos[0] = fillPenInfo.y;
			fillPenInfoPos[1] = fillPenInfo.height;
		}
	}
}
