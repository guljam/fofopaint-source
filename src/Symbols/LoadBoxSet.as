package symbols
{

	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObjectContainer;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.filters.BlurFilter;
	import flash.display.DisplayObject;
	import assets.VisualBuilder;
	import assets.VisualFieldCollector;

	public class LoadBoxSet extends Sprite
	{
		public var dragDropLoadButton:SimpleButton;
		public var dragDropLoadRefLayerButton:SimpleButton;
		public var dragDropSaveAndLoadButton:SimpleButton;
		public var dragDropCancelButton:SimpleButton;
		public var pleaseWaitText:TextField;
		public var stageClickBlocker:Sprite = new Sprite();

		private var plaseWaitTextBase:String = ""
		private var clickBlockerBitmap:Bitmap = new Bitmap(new BitmapData(1, 1, true, 0));
		private var menuBox:Sprite = new Sprite();
		private var mainBox:Sprite = new Sprite();
		private var bitmapSize:Number = 180;
		private var refLayerLoadMode:Boolean = false;

		public function isShowing():Boolean
		{
			return this.visible
		}

		public function isRefLayerLoadMode():Boolean
		{
			return refLayerLoadMode;
		}

		public function activateAllButtons():void
		{
			dragDropLoadButton.alpha = 1.0;
			dragDropSaveAndLoadButton.alpha = 1.0;
		}

		public function activateReflayerButtonOnly():void
		{
			refLayerLoadMode = true;
			dragDropLoadButton.alpha = 0.3;
			dragDropSaveAndLoadButton.alpha = 0.3;
		}

		public function hidePleaseWait():void
		{
			pleaseWaitText.visible = false;
			mainBox.visible = true;
		}

		public function updatePlaseWaitPrograss(prograss:String):void
		{
			pleaseWaitText.text = plaseWaitTextBase+" "+prograss;
		}

		public function showPleaseWait(str:String="Please Wait..."):void
		{
			plaseWaitTextBase = str;
			pleaseWaitText.text = str;
			pleaseWaitText.autoSize = "left";
			pleaseWaitText.visible = true;
			mainBox.visible = false;
		}

		public function hide():void
		{
			if (clickBlockerBitmap.bitmapData)
			{
				clickBlockerBitmap.bitmapData.dispose();
			}

			this.visible = false;
		}

		public function updateClickBlockerSize(stw:int, sth:int):void
		{
			this.x = 0;
			this.y = 0;

			stageClickBlocker.x = 0;
			stageClickBlocker.y = 0;
			stageClickBlocker.width = stw;
			stageClickBlocker.height = sth;

			pleaseWaitText.x = stageClickBlocker.width / 2 - pleaseWaitText.width / 2;
			pleaseWaitText.y = stageClickBlocker.height / 2 - pleaseWaitText.height / 2;

			mainBox.x = stageClickBlocker.width / 2 - mainBox.width / 2;
			mainBox.y = stageClickBlocker.height / 2 - mainBox.height / 2;
			
			clickBlockerBitmap.x = -10;
			clickBlockerBitmap.y = -10;
			clickBlockerBitmap.width = stageClickBlocker.width + 20;
			clickBlockerBitmap.height = stageClickBlocker.height + 20;
		}

		public function setPreviewImage(bmpd:BitmapData):void
		{
			const tmpbmpd:BitmapData = new BitmapData(bitmapSize, bitmapSize, true, 0);
			var longWidth:Number = (bmpd.width > bmpd.height) ? bmpd.width : bmpd.height;
			var f:Number = bitmapSize / longWidth;
			var imageOffsetX:Number = 0.0;
			var imageOffsetY:Number = 0.0;

			// if (bmpd.width > bmpd.height)
			// {
			// 	imageOffsetY = (bitmapSize / 2) - (bmpd.height * f) / 2;
			// }
			// else
			// {
			// 	imageOffsetX = (bitmapSize / 2) - (bmpd.width * f) / 2;
			// }

			const mat:Matrix = new Matrix();
			mat.scale(f, f);
			mat.translate(imageOffsetX, imageOffsetY);
			tmpbmpd.draw(bmpd, mat, null, null, null, true);

			if (clickBlockerBitmap.bitmapData)
			{
				clickBlockerBitmap.bitmapData.dispose();
			}
			clickBlockerBitmap.bitmapData = bmpd;
		}

		public function updateUIColor():void
		{
			const subBase:ColorTransform = new ColorTransform();
			const activeColor:ColorTransform = new ColorTransform();
			const activeIconColor:ColorTransform = new ColorTransform();
			const buttonList:Array = [
					dragDropLoadButton,
					dragDropSaveAndLoadButton,
					dragDropLoadRefLayerButton,
					dragDropCancelButton,
				];

			const len:uint = buttonList.length;

			var btn:SimpleButton;
			var btnUp:DisplayObjectContainer;
			var btnOver:DisplayObjectContainer;
			var childText:TextField;

			for (var i:uint = 0; i < len; i++)
			{
				btn = buttonList[i] as SimpleButton;
				btnUp = btn.upState as DisplayObjectContainer;
				btnOver = btn.overState as DisplayObjectContainer;

				// 배경 깔아줌
				(btnUp.getChildAt(0) as DisplayObject).alpha = 0.0;
				Global.applyToolBoxButtonOverBGColor(btnOver.getChildAt(0) as DisplayObject);
				btn.downState = btn.overState;

				// 폰트색깔
				childText = btnUp.getChildAt(1) as TextField;
				childText.textColor = Global.getToolBoxButtonOverFGColor();

				childText = btnOver.getChildAt(1) as TextField;
				childText.textColor = Global.getToolBoxButtonUpFGColor();
			}

			mainBox.graphics.clear();
			mainBox.graphics.lineStyle(1,0);
			mainBox.graphics.beginFill(Global.getToolBoxBGTopColor(), 0.8);
			mainBox.graphics.drawRect(-10, -10, mainBox.width + 20, mainBox.height + 20);
			mainBox.graphics.endFill();
		}

		[Embed(
            source="fofoPaint-animate-27.13.swf",
            symbol="LoadBoxSet"
        )]
		private static const EmbeddedClass:Class;

		public function LoadBoxSet()
		{
			const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
			VisualBuilder.buildInto(this,EmbeddedClass,fields);
			stageClickBlocker.name = "dragDropFileBG";
			stageClickBlocker.graphics.clear();
			stageClickBlocker.graphics.beginFill(0, 0.3);
			stageClickBlocker.graphics.drawRect(0, 0, 50, 50);
			stageClickBlocker.graphics.endFill();

			clickBlockerBitmap.filters = [new BlurFilter(10, 10, 3)];
			addChild(clickBlockerBitmap);
			addChild(stageClickBlocker);
			setChildIndex(stageClickBlocker, 0);
			setChildIndex(clickBlockerBitmap, 0);

			visible = false;

			dragDropLoadButton.useHandCursor = true;
			dragDropLoadRefLayerButton.useHandCursor = true;
			dragDropCancelButton.useHandCursor = true;
			dragDropSaveAndLoadButton.useHandCursor = true;

			menuBox.addChild(dragDropSaveAndLoadButton);
			menuBox.addChild(dragDropLoadButton);
			menuBox.addChild(dragDropLoadRefLayerButton);
			menuBox.addChild(dragDropCancelButton);

			dragDropSaveAndLoadButton.x = 0;
			dragDropSaveAndLoadButton.y = 0;
			dragDropLoadButton.x = 0;
			dragDropLoadButton.y = dragDropSaveAndLoadButton.y + dragDropSaveAndLoadButton.height+10;
			dragDropLoadRefLayerButton.x = 0;
			dragDropLoadRefLayerButton.y = dragDropLoadButton.y + dragDropLoadButton.height+5;
			dragDropCancelButton.x = 0;
			dragDropCancelButton.y = dragDropLoadRefLayerButton.y + dragDropLoadRefLayerButton.height+5;

			mainBox.addChild(menuBox);
			mainBox.graphics.clear();
			mainBox.graphics.lineStyle(1,0);
			mainBox.graphics.beginFill(0xCCCCCC, 0.5);
			mainBox.graphics.drawRect(-10, -10, mainBox.width + 20, mainBox.height + 20);
			mainBox.graphics.endFill();
			this.addChild(mainBox);

			pleaseWaitText.textColor = 0xFFFFFF;

			setChildIndex(pleaseWaitText, numChildren - 1);
		}
	}
}
