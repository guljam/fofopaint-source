package
{

	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObjectContainer;
	import flash.text.TextFieldAutoSize;

	public class loadBox extends Sprite {
		public var dragDropLoadButton:SimpleButton;
		public var dragDropLoadRefLayerButton:SimpleButton;
		public var dragDropSaveAndLoadButton:SimpleButton;
		public var dragDropCancelButton:SimpleButton;
		public var pleaseWaitText:TextField;
		public var dragDropFileBG:Sprite = new Sprite();
		private var filePathText:TextField = new TextField();
		private var filePathTextBG:Sprite = new Sprite();

		private const base:ColorTransform = new ColorTransform();
		private const subBase:ColorTransform = new ColorTransform();
		private const activeColor:ColorTransform = new ColorTransform();
		private const activeIconColor:ColorTransform = new ColorTransform();
		private var buttonList:Array;

		public function setFilePathString(str:String):void
		{
			if(filePathText)
			{
				filePathText.text = str;
				filePathTextBG.graphics.clear();
				filePathTextBG.graphics.beginFill(0xFFFFFF);
				filePathTextBG.graphics.drawRect(0,0,filePathText.width,filePathText.height);
				filePathTextBG.graphics.endFill();
				filePathTextBG.x = dragDropLoadButton.x;
				filePathTextBG.y = dragDropLoadButton.y-filePathTextBG.height;
			}
		}

		public function setPleaseWait(flag:Boolean):void
		{
			pleaseWaitText.visible = flag;
			filePathTextBG.visible = !flag;
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

           	base.color = arr[0];
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
			dragDropLoadButton.useHandCursor = true;
			dragDropLoadRefLayerButton.useHandCursor = true;
			dragDropCancelButton.useHandCursor = true;
			dragDropSaveAndLoadButton.useHandCursor = true;

			filePathText.type = "input";
			filePathText.wordWrap = true;
			filePathText.width = this.width;
			filePathText.autoSize = TextFieldAutoSize.LEFT;
			filePathText.mouseEnabled = false;

			pleaseWaitText.textColor = 0;
			filePathText.textColor = 0;

			filePathTextBG.addChild(filePathText);
			addChild(filePathTextBG);
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
