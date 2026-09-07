package Symbols
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.display.SimpleButton;
	import flash.text.TextFieldAutoSize;
	import assets.VisualBuilder;
	import assets.VisualFieldCollector;

	public class CanvasInfoSet extends Sprite
	{
		public var canvasInfo:TextField;
		public var appInfoBorder:SimpleButton;
		private var canvasWidth:Number = 0;
		private var canvasHeight:Number = 0;
		private var canvasZoom:Number = 0;
		private var canvasRotate:Number = 0;
		private var canvasMirror:Boolean = false;

		public function init(w:Number, h:Number, z:Number, r:Number, flag:Boolean):void
		{
			canvasWidth = w;
			canvasHeight = h;
			canvasZoom = z;
			canvasRotate = r;
			canvasMirror = flag;
			update();
		}

		public function setWidth(width:Number):void
		{
			canvasInfo.width = width;
		}

		public function setSize(w:Number, h:Number):void
		{
			canvasWidth = w;
			canvasHeight = h;
			update();
		}

		public function setZoom(z:Number):void
		{
			canvasZoom = Math.floor(z * 100);
			update();
		}

		public function setRotate(r:Number):void
		{
			canvasRotate = Math.abs(r);
			update();
		}

		public function getMirorrString():String
		{
			return (canvasMirror) ? "m*" : "";
		}

		public function getStringFixedLength(str:String, fixedLength:int):String
		{
			const strlen:uint = str.length;
			const len:int = fixedLength - strlen;
			var finalstr:String = "";

			for (var i:uint = 0; i < len; i++)
			{
				finalstr += " ";
			}

			return finalstr + str;
		}

		public function setMirror(flag:Boolean):void
		{
			canvasMirror = flag;
			update();
		}

		public function update():void
		{
			canvasInfo.text = canvasWidth + " x " + canvasHeight + "  "
				+ getStringFixedLength(canvasZoom.toString(), 3) + "%  "
				+ getStringFixedLength(canvasRotate.toString(), 3) + "°  "
				+ getMirorrString();
		}

		public function updateUIColor():void
		{
			canvasInfo.textColor = Global.getUIFGColor();
			Global.applyUIFGColor(appInfoBorder);
		}

		[Embed(
            source="fofoPaint-animate-27.13.swf",
            symbol="CanvasInfoSet"
        )]
		private static const EmbeddedClass:Class;

		public function CanvasInfoSet()
		{
			const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
			VisualBuilder.buildInto(this,EmbeddedClass,fields);
			mouseEnabled = false;
			canvasInfo.mouseEnabled = false;
			canvasInfo.autoSize = TextFieldAutoSize.LEFT;
			canvasInfo.x = 20;
			canvasInfo.y = 4;
			appInfoBorder.mouseEnabled = false;
		}
	}
}
