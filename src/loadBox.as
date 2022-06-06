package
{
	
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	
	public class loadBox extends Sprite {
		public var dragDropFileButton:SimpleButton = dragDropFileButton;
		public var dragDropRefButton:SimpleButton = dragDropRefButton;
		public var dragDropCancelButton:SimpleButton = dragDropCancelButton;
		public var dragDropFileBG:Sprite = new Sprite();

		public function changeUIColor(arr:Array):void
		{
			const buttonList:Array = 
			[
				dragDropFileButton,
				dragDropRefButton,
				dragDropCancelButton,
			]

			const len:uint = buttonList.length;
			const base:ColorTransform = new ColorTransform();
			const subBase:ColorTransform = new ColorTransform();
			const activeColor:ColorTransform = new ColorTransform();
			const activeIconColor:ColorTransform = new ColorTransform();
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
			dragDropFileButton.useHandCursor = false;
			dragDropRefButton.useHandCursor = false;
			dragDropCancelButton.useHandCursor = false;
		}
	}
	
}
