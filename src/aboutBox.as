package
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.display.SimpleButton;

	public class aboutBox extends Sprite {

		public var versionInfo:TextField = versionInfo;
		public var appResetButton:TextField = appResetButton;
		public var aboutTwitterLink:SimpleButton = aboutTwitterLink;
		public var logo1:SimpleButton = logo1;
		public var logo2:SimpleButton = logo2;
		public var logo3:SimpleButton = logo3;
		public var logo4:SimpleButton = logo4;
		public var logo5:SimpleButton = logo5;
		private var imageIndex:int = 0;

		public function randomLogo():void
		{
			const arr:Array = [logo1,logo2,logo3,logo4,logo5];
			var index:int = imageIndex+1;
			if(index === arr.length) index = 0;
	
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
