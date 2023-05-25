package
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.display.SimpleButton;

	public class aboutBox extends Sprite {

		public var versionInfo:TextField;
		public var appResetButton:TextField;
		public var releaseNote:TextField;
		public var aboutTwitterLink:SimpleButton;
		public var aboutHomePageLink:SimpleButton;
		public var logo1:SimpleButton;
		public var logo2:SimpleButton;
		public var logo3:SimpleButton;
		public var logo4:SimpleButton;
		public var logo5:SimpleButton;
		private var imageIndex:int = 0;

		public function randomLogo():void
		{
			const arr:Array = [logo1,logo2,logo3,logo4,logo5];
			var index:int = imageIndex+1;

			if(index === arr.length)
			{
				index = 0;
			}
	
			arr[imageIndex].visible = false;
			arr[index].visible = true;

			imageIndex = index;
		}

		public function setVersionInfo(str:String):void
		{
			versionInfo.text = "version " + str;
		}

		public function aboutBox() {
			// constructor codef
			imageIndex = Math.floor(Math.random()*4);
			visible = false;

			logo2.visible = false;
			logo3.visible = false;
			logo4.visible = false;
			logo5.visible = false;

			logo1.useHandCursor = false;
			logo2.useHandCursor = false;
			logo3.useHandCursor = false;
			logo4.useHandCursor = false;
			logo5.useHandCursor = false;
		}
	}
}
