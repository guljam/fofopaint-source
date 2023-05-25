package
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;

	public class rToolButtons extends Sprite {
		public var rToolInfo:TextField;
		public var replayZoom:SimpleButton;
		public var replayRotate:SimpleButton;
		public var replayAutoScrollOFF:SimpleButton;
		public var replayAutoScrollON:SimpleButton;

		public function changeUIColor(arr:Array):void
		{	
			const buttonArr:Array =
			[
				replayAutoScrollOFF,
				replayAutoScrollON,
				replayZoom,
				replayRotate,
			];

			const base:ColorTransform = new ColorTransform();
			const subBase:ColorTransform = new ColorTransform();
			const iconRight:ColorTransform = new ColorTransform();
			const activeColor:ColorTransform = new ColorTransform();
			const activeIconColor:ColorTransform = new ColorTransform();
           	base.color = arr[0];
           	subBase.color = arr[1];
           	iconRight.color = arr[3];
           	activeColor.color = arr[4];
           	activeIconColor.color = arr[5];

			var i:uint = 0;
			var len:uint = buttonArr.length;
			var btn:SimpleButton ;
			var btnUp:DisplayObject;
			var btnOver:DisplayObjectContainer;

			for(i=0;i<len;i++)
			{
				btn = buttonArr[i];
				btnUp = btn.upState as DisplayObject;
				btnOver = btn.overState as DisplayObjectContainer;
				btnUp.transform.colorTransform = iconRight;
				btnOver.getChildAt(0).transform.colorTransform = activeColor;//버튼 배경
				btnOver.getChildAt(1).transform.colorTransform = activeIconColor; //버튼 아이콘
				if(i === 0)
				{
					btnOver.getChildAt(2).transform.colorTransform = activeIconColor;
				}
				btn.downState = btn.overState;
			}

			//텍스트
			rToolInfo.textColor = arr[2];
		}

		public function rToolButtons() {
			// constructor code
			visible = false;
		}
	}
}