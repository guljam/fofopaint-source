package Symbols
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.display.SimpleButton;
	import flash.text.TextFieldAutoSize;
	import assets.VisualBuilder;
	import assets.VisualFieldCollector;

	public class AboutWindowSet extends Sprite
	{
		private var versionInfo:TextField;
		private var memoryInfo:TextField;
		public var resetAppButton:SimpleButton;
		private var releaseNoteButton:SimpleButton;
		private var aboutMeLink:SimpleButton;
		private var aboutHomePageLink:SimpleButton;
		private var aboutManualFolder:SimpleButton;
		private var logo1:SimpleButton;
		private var logo2:SimpleButton;
		private var logo3:SimpleButton;
		private var logo4:SimpleButton;
		private var logo5:SimpleButton;
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

		[Embed(
            source="fofoPaint-animate-27.13.swf",
            symbol="AboutWindowSet"
        )]
		private static const EmbeddedClass:Class;
		public function AboutWindowSet()
		{
			const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
			VisualBuilder.buildInto(this,EmbeddedClass,fields);
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
