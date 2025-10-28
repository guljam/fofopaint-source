package
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.display.SimpleButton;
	import flash.text.TextFieldAutoSize;

	public class AboutWindowSet extends Sprite
	{
		public var versionInfo:TextField;
		public var memoryInfo:TextField;
		public var resetAppButton:SimpleButton;
		public var releaseNoteButton:SimpleButton;
		public var aboutMeLink:SimpleButton;
		public var aboutHomePageLink:SimpleButton;
		public var logo1:SimpleButton;
		public var logo2:SimpleButton;
		public var logo3:SimpleButton;
		public var logo4:SimpleButton;
		public var logo5:SimpleButton;
		private var imageIndex:int = 0;

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale;
			this.scaleY = newScale;
		}

		public function updateMemoryInfo(driveUseage:String):void
		{
			memoryInfo.text = "Drive usage : " + driveUseage;
		}

		public function randomLogo():void
		{
			const arr:Array = [logo1, logo2, logo3, logo4, logo5];
			var index:int = imageIndex + 1;

			if (index === arr.length)
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

		public function AboutWindowSet()
		{
			// constructor codef
			imageIndex = Math.floor(Math.random() * 4);
			visible = false;

			logo2.visible = false;
			logo3.visible = false;
			logo4.visible = false;
			logo5.visible = false;

			logo1.mouseEnabled = false;
			logo2.mouseEnabled = false;
			logo3.mouseEnabled = false;
			logo4.mouseEnabled = false;
			logo5.mouseEnabled = false;

			aboutMeLink.mouseEnabled = false;

			memoryInfo.autoSize = TextFieldAutoSize.RIGHT;
		}
	}
}
