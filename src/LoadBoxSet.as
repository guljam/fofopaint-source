package
{

	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObjectContainer;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.display.Shape;
	import flash.filters.BlurFilter;

	public class LoadBoxSet extends Sprite
	{
		public var dragDropLoadButton:SimpleButton;
		public var dragDropLoadRefLayerButton:SimpleButton;
		public var dragDropSaveAndLoadButton:SimpleButton;
		public var dragDropCancelButton:SimpleButton;
		public var pleaseWaitText:TextField;
		public var stageClickBlocker:Sprite = new Sprite();

		private var previewBitmap:Bitmap = new Bitmap(new BitmapData(1, 1, false, 0));
		private var clickBlockerBitmap:Bitmap = new Bitmap(new BitmapData(1, 1, false, 0));
		private var previewBitmapBox:Sprite = new Sprite();
		private var menuBox:Sprite = new Sprite();
		private var mainBox:Sprite = new Sprite();
		private var bitmapSize:Number = 180;
		private var refLayerLoadMode:Boolean = false;

		public function isRefLayerLoadMode():Boolean
		{
			return refLayerLoadMode;
		}

		public function activateAllButtons():void
		{
			dragDropLoadButton.alpha = 1.0;
			dragDropSaveAndLoadButton.alpha = 1.0;
		}

		public function activateRelayerButtonOnly():void
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

		public function showPleaseWait():void
		{
			pleaseWaitText.visible = true;
			mainBox.visible = false;
		}

		public function updateClickBlockerSize(stw:int, sth:int):void
		{
			this.x = 0;
			this.y = 0;
			stageClickBlocker.x = 0;
			stageClickBlocker.y = 0;
			stageClickBlocker.width = stw;
			stageClickBlocker.height = sth;
			if(pleaseWaitText.visible)
			{
				pleaseWaitText.x = stageClickBlocker.width / 2 - mainBox.width / 2;
				pleaseWaitText.y = stageClickBlocker.height / 2 - mainBox.height / 2;
			}
			else
			{
				trace("stageClickBlocker",stageClickBlocker.width,stageClickBlocker.height);
				mainBox.x = stageClickBlocker.width / 2 - mainBox.width / 2;
				mainBox.y = stageClickBlocker.height / 2 - mainBox.height / 2;
				clickBlockerBitmap.x = -10;
				clickBlockerBitmap.y = -10;
				clickBlockerBitmap.width = stageClickBlocker.width + 20;
				clickBlockerBitmap.height = stageClickBlocker.height + 20;
				clickBlockerBitmap.alpha = 0.5;
				
			}
		}

		public function setPreviewImage(bmpd:BitmapData):void
		{
			const tmpbmpd:BitmapData = new BitmapData(bitmapSize, bitmapSize, true, 0);
			var longWidth:Number = (bmpd.width > bmpd.height) ? bmpd.width : bmpd.height;
			var f:Number = bitmapSize / longWidth;
			var imageOffsetX:Number = 0.0;
			var imageOffsetY:Number = 0.0;

			if (bmpd.width > bmpd.height)
			{
				imageOffsetY = (bitmapSize / 2) - (bmpd.height * f) / 2;
			}
			else
			{
				imageOffsetX = (bitmapSize / 2) - (bmpd.width * f) / 2;
			}

			const mat:Matrix = new Matrix();
			mat.scale(f, f);
			mat.translate(imageOffsetX, imageOffsetY);
			tmpbmpd.draw(bmpd, mat, null, null, null, true);

			if (previewBitmap.bitmapData)
			{
				previewBitmap.bitmapData.dispose();
			}

			previewBitmap.bitmapData = tmpbmpd;
			clickBlockerBitmap.bitmapData = bmpd;
		}

		// public function setScale(newScale:Number):void
		// {
		// // 로지스틱 함수의 매개변수 설정
		// var L:Number = 2.0; // 최대값
		// var k:Number = 1.2; // 경사도
		// var x0:Number = 3; // 중심 지점

		// // 로지스틱 함수 계산
		// var exponent:Number = -k * (newScale - x0);
		// const newScale2:Number = Math.floor((0.9 + (L / (1 + Math.exp(exponent)))) * 100) / 100;

		// this.scaleX = newScale2;
		// this.scaleY = newScale2;
		// }

		public function changeUIColor(arr:Array):void
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
			var childButton:SimpleButton;
			var textColorDeafult:uint;
			var textColorOver:uint;

			subBase.color = arr[1];
			textColorOver = arr[3];
			activeColor.color = arr[4];
			textColorDeafult = arr[5];

			for (var i:uint = 0; i < len; i++)
			{
				btn = buttonList[i] as SimpleButton;
				btnUp = btn.upState as DisplayObjectContainer;
				btnOver = btn.overState as DisplayObjectContainer;

				// 배경 깔아줌
				childButton = btnUp.getChildAt(0) as SimpleButton;
				btnUp.getChildAt(0).transform.colorTransform = subBase;
				childButton = btnOver.getChildAt(0) as SimpleButton;
				btnOver.getChildAt(0).transform.colorTransform = activeColor;
				btn.downState = btn.overState;

				// 폰트색깔
				childText = btnUp.getChildAt(1) as TextField;
				childText.textColor = textColorDeafult;

				childText = btnOver.getChildAt(1) as TextField;
				childText.textColor = textColorOver;
			}

			previewBitmapBox.graphics.clear();
			previewBitmapBox.graphics.beginFill(arr[1], 1.0);
			previewBitmapBox.graphics.drawRect(0, 0, bitmapSize, bitmapSize);
			previewBitmapBox.graphics.endFill();

			mainBox.graphics.clear();
			mainBox.graphics.beginFill(arr[1], 1.0);
			mainBox.graphics.drawRect(-10, -10, mainBox.width + 20, mainBox.height + 20);
			mainBox.graphics.endFill();
		}

		public function LoadBoxSet()
		{
			stageClickBlocker.name = "dragDropFileBG";
			stageClickBlocker.graphics.clear();
			stageClickBlocker.graphics.beginFill(0xFFFFFF, 1.0);
			stageClickBlocker.graphics.drawRect(0, 0, 50, 50);
			stageClickBlocker.graphics.endFill();

			clickBlockerBitmap.filters = [new BlurFilter(10, 10, 3)];
			addChild(clickBlockerBitmap);
			addChild(stageClickBlocker);
			setChildIndex(clickBlockerBitmap, 0);
			setChildIndex(stageClickBlocker, 0);

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
			dragDropLoadButton.y = dragDropSaveAndLoadButton.y + dragDropSaveAndLoadButton.height;
			dragDropLoadRefLayerButton.x = 0;
			dragDropLoadRefLayerButton.y = dragDropLoadButton.y + dragDropLoadButton.height;
			dragDropCancelButton.x = 0;
			dragDropCancelButton.y = dragDropLoadRefLayerButton.y + dragDropLoadRefLayerButton.height;

			previewBitmapBox.addChild(previewBitmap);
			menuBox.x = previewBitmapBox.x + bitmapSize + 5;
			menuBox.y = previewBitmapBox.y;
			mainBox.addChild(previewBitmapBox);
			mainBox.addChild(menuBox);
			mainBox.graphics.clear();
			mainBox.graphics.beginFill(0xFF0000, 0.5);
			mainBox.graphics.drawRect(-10, -10, mainBox.width + 20, mainBox.height + 20);
			mainBox.graphics.endFill();
			this.addChild(mainBox);

			pleaseWaitText.textColor = 0xFFFFFF;

			setChildIndex(pleaseWaitText, numChildren - 1);
		}
	}
}
