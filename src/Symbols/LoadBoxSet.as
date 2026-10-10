package Symbols
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
	import Modules.L1Data.UIEngine.UITheme;

	// 층: L4 UI - 불러오기 박스 화면 묶음
	public class LoadBoxSet extends Sprite
	{
		public var dragDropLoadButton:SimpleButton;
		public var dragDropLoadRefLayerButton:SimpleButton;
		public var dragDropSaveAndLoadButton:SimpleButton;
		public var dragDropCancelButton:SimpleButton;
		public var pleaseWaitText:TextField;
		public var stageClickBlocker:Sprite = new Sprite();

		private var plaseWaitTextBase:String = "";
		private var plaseWaitHintText:String = ""; // 진행 문구 아래 줄에 붙는 안내 문구
		private static const PREVIEW_MAX_SIZE:Number = 1024; // 배경 이미지 긴 변 최대 크기
		private var clickBlockerBitmap:Bitmap = new Bitmap(); // 흐린 배경 이미지, 없으면 bitmapData가 null
		private var menuBox:Sprite = new Sprite();
		private var mainBox:Sprite = new Sprite();
		private var refLayerLoadMode:Boolean = false;

		public function isShowing():Boolean
		{
			return this.visible;
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
			setPleaseWaitText(plaseWaitTextBase + " " + prograss);
		}

		// hintText가 있으면 줄바꿈 한 다음 줄에 괄호로 넣어줌
		public function showPleaseWaitTextOrCustomText(str:String = "Please Wait...", hintText:String = ""):void
		{
			plaseWaitTextBase = str;
			plaseWaitHintText = hintText;
			pleaseWaitText.multiline = true;
			pleaseWaitText.autoSize = "left";
			setPleaseWaitText(str);
			pleaseWaitText.visible = true;
			mainBox.visible = false;
		}

		private function setPleaseWaitText(str:String):void
		{
			pleaseWaitText.text = (plaseWaitHintText.length > 0) ? str + "\n" + plaseWaitHintText : str;
			pleaseWaitText.x = stageClickBlocker.width / 2 - pleaseWaitText.width / 2;
			pleaseWaitText.y = stageClickBlocker.height / 2 - pleaseWaitText.height / 2;
		}

		public function hide():void
		{
			clearPreviewImage();
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

		// 배경 이미지는 흐리게 깔아주는 용도라 긴 변이 PREVIEW_MAX_SIZE를 넘을때만 줄인 복사본을 만들어 씀
		// 넘지 않으면 받은 bmpd를 그대로 씀 (부르는 쪽은 isPreviewImage로 확인해서 해제하지 않게 해야함)
		// 이전 배경 이미지는 해제함
		public function setPreviewImage(bmpd:BitmapData):void
		{
			const longWidth:Number = (bmpd.width > bmpd.height) ? bmpd.width : bmpd.height;
			var preview:BitmapData = bmpd;

			if (longWidth > PREVIEW_MAX_SIZE)
			{
				const f:Number = PREVIEW_MAX_SIZE / longWidth;
				const mat:Matrix = new Matrix();
				mat.scale(f, f);
				preview = new BitmapData(Math.max(1, Math.round(bmpd.width * f)), Math.max(1, Math.round(bmpd.height * f)), bmpd.transparent, 0);
				preview.draw(bmpd, mat, null, null, null, true);
			}

			if (clickBlockerBitmap.bitmapData !== preview)
			{
				clearPreviewImage();
			}

			clickBlockerBitmap.bitmapData = preview;
		}

		public function clearPreviewImage():void
		{
			if (clickBlockerBitmap.bitmapData)
			{
				clickBlockerBitmap.bitmapData.dispose();
				clickBlockerBitmap.bitmapData = null;
			}
		}

		// 배경 이미지가 없으면 null
		public function getPreviewImage():BitmapData
		{
			return clickBlockerBitmap.bitmapData;
		}

		public function isPreviewImage(bmpd:BitmapData):Boolean
		{
			return bmpd !== null && clickBlockerBitmap.bitmapData === bmpd;
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

			for (var i:uint = 0;i < len;i++)
			{
				btn = buttonList[i] as SimpleButton;
				btnUp = btn.upState as DisplayObjectContainer;
				btnOver = btn.overState as DisplayObjectContainer;

				// 배경 깔아줌
				(btnUp.getChildAt(0) as DisplayObject).alpha = 0.0;
				UITheme.applyToolBoxButtonOverBGColor(btnOver.getChildAt(0) as DisplayObject);
				btn.downState = btn.overState;

				// 폰트색깔
				childText = btnUp.getChildAt(1) as TextField;
				childText.textColor = UITheme.getToolBoxButtonOverFGColor();

				childText = btnOver.getChildAt(1) as TextField;
				childText.textColor = UITheme.getToolBoxButtonUpFGColor();
			}

			mainBox.graphics.clear();
			mainBox.graphics.lineStyle(1, 0);
			mainBox.graphics.beginFill(UITheme.getToolBoxBGTopColor(), 0.8);
			mainBox.graphics.drawRect(-10, -10, mainBox.width + 20, mainBox.height + 20);
			mainBox.graphics.endFill();
		}

		[Embed(source="fofoPaint-animate-27.13.swf",symbol="LoadBoxSet")]
		private static const EmbeddedClass:Class;

		public function LoadBoxSet()
		{
			const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
			VisualBuilder.buildInto(this, EmbeddedClass, fields);
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
			dragDropLoadButton.y = dragDropSaveAndLoadButton.y + dragDropSaveAndLoadButton.height + 10;
			dragDropLoadRefLayerButton.x = 0;
			dragDropLoadRefLayerButton.y = dragDropLoadButton.y + dragDropLoadButton.height + 5;
			dragDropCancelButton.x = 0;
			dragDropCancelButton.y = dragDropLoadRefLayerButton.y + dragDropLoadRefLayerButton.height + 5;

			mainBox.addChild(menuBox);
			mainBox.graphics.clear();
			mainBox.graphics.lineStyle(1, 0);
			mainBox.graphics.beginFill(0xCCCCCC, 0.5);
			mainBox.graphics.drawRect(-10, -10, mainBox.width + 20, mainBox.height + 20);
			mainBox.graphics.endFill();
			this.addChild(mainBox);

			pleaseWaitText.textColor = 0xFFFFFF;

			setChildIndex(pleaseWaitText, numChildren - 1);
		}
	}
}
