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

	public class loadBox extends Sprite {
		public var dragDropLoadButton:SimpleButton;
		public var dragDropLoadRefLayerButton:SimpleButton;
		public var dragDropSaveAndLoadButton:SimpleButton;
		public var dragDropCancelButton:SimpleButton;
		public var pleaseWaitText:TextField;
		public var dragDropFileBG:Sprite = new Sprite();

		private const subBase:ColorTransform = new ColorTransform();
		private const activeColor:ColorTransform = new ColorTransform();
		private const activeIconColor:ColorTransform = new ColorTransform();
		private var buttonList:Array;
		private var previewBitmap:Bitmap = new Bitmap(new BitmapData(1,1,false,0));
		private var previewBitmapBox:Sprite = new Sprite();
		private var bitmapSize:Number = 150;

		public function setPreviewImage(newImage:BitmapData):void
        {
            const bmpd:BitmapData = new BitmapData(bitmapSize,bitmapSize,true,0);
            var longWidth:Number = (newImage.width > newImage.height) ? newImage.width:newImage.height;
            var f:Number = bitmapSize/longWidth;
            var imageOffsetX:Number = 0.0;
            var imageOffsetY:Number = 0.0;

            if(newImage.width > newImage.height) imageOffsetY = (bitmapSize/2)-(newImage.height*f)/2;
            else imageOffsetX = (bitmapSize/2)-(newImage.width*f)/2;

            const mat:Matrix = new Matrix();
            mat.scale(f,f);
            mat.translate(imageOffsetX,imageOffsetY);
            bmpd.draw(newImage,mat);

			if(previewBitmap.bitmapData) previewBitmap.bitmapData.dispose();
            previewBitmap.bitmapData = bmpd;
        }


		public function setPleaseWait(flag:Boolean):void
		{
			pleaseWaitText.visible = flag;
			previewBitmapBox.visible = !flag;
			dragDropLoadButton.visible = !flag;
			dragDropLoadRefLayerButton.visible = !flag;
			dragDropSaveAndLoadButton.visible = !flag;
			dragDropCancelButton.visible = !flag;
		}

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale;
			this.scaleY = newScale;
		}

		public function changeUIColor(arr:Array):void
		{
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

			for(var i:uint=0;i<len;i++)
			{
				btn = buttonList[i] as SimpleButton;
				btnUp = btn.upState as DisplayObjectContainer;
				btnOver = btn.overState as DisplayObjectContainer;

				 //배경 깔아줌
				childButton = btnUp.getChildAt(0) as SimpleButton;
				btnUp.getChildAt(0).transform.colorTransform = subBase;
				childButton = btnOver.getChildAt(0) as SimpleButton;
				btnOver.getChildAt(0).transform.colorTransform = activeColor;
				btn.downState = btn.overState;

				//폰트색깔
				childText = btnUp.getChildAt(1) as TextField;
				childText.textColor = textColorDeafult;

				childText = btnOver.getChildAt(1) as TextField;
				childText.textColor = textColorOver;
			}

			previewBitmapBox.graphics.clear();
			previewBitmapBox.graphics.beginFill(arr[1]);
			previewBitmapBox.graphics.drawRect(0,0,bitmapSize,bitmapSize);
			previewBitmapBox.graphics.endFill();
		}

		public function loadBox() {
			// constructor code

			dragDropFileBG.name = "dragDropFileBG";
			dragDropFileBG.graphics.clear();
			dragDropFileBG.graphics.beginFill(0,0.5);
			dragDropFileBG.graphics.drawRect(0,0,50,50);
			dragDropFileBG.graphics.endFill();

			addChild(dragDropFileBG);
			setChildIndex(dragDropFileBG,0);

			visible = false;
			pleaseWaitText.visible = false;
			pleaseWaitText.x = this.width/2-pleaseWaitText.width/2;
			pleaseWaitText.y = this.height/2-pleaseWaitText.height/2;

			dragDropLoadButton.useHandCursor = true;
			dragDropLoadRefLayerButton.useHandCursor = true;
			dragDropCancelButton.useHandCursor = true;
			dragDropSaveAndLoadButton.useHandCursor = true;

			previewBitmapBox.addChild(previewBitmap);
			addChild(previewBitmapBox);

			pleaseWaitText.textColor = 0xFFFFFF;

			setChildIndex(pleaseWaitText,numChildren-1);

			buttonList = [
							dragDropLoadButton,
							dragDropSaveAndLoadButton,
							dragDropLoadRefLayerButton,
							dragDropCancelButton,
						];
		}
	}
}
