package
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;

	public class appInfoBar extends Sprite {
		private const canvasInfoFormat:TextFormat = new TextFormat();
		public var canvasInfo:TextField;
		private var canvasWidth:Number = 0;
		private var canvasHeight:Number = 0;
		private var canvasZoom:Number = 0;
		private var canvasRotate:Number = 0;
		private var canvasMirror:Boolean = false;

		public function init(w:Number,h:Number,z:Number,r:Number,flag:Boolean):void
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

		public function setAlignRight():void
		{
			canvasInfoFormat.align = TextFormatAlign.RIGHT;
			canvasInfo.defaultTextFormat = canvasInfoFormat;
		}

		public function setAlignLeft():void
		{
			canvasInfoFormat.align = TextFormatAlign.LEFT;
			canvasInfo.defaultTextFormat = canvasInfoFormat;
		}

		public function setSize(w:Number,h:Number):void
		{
			canvasWidth = w;
			canvasHeight = h;
			update();
		}

		public function setZoom(z:Number):void
		{
			canvasZoom = Math.floor(z*100);
			update();
		}

		public function setRotate(r:Number):void
		{
			canvasRotate = r;
			update();
		}

		public function getMirorrString():String
		{
			return (canvasMirror) ? "flipped" : "";
		}

		public function getStringFixedLength(str:String,fixedLength:int):String
		{
			const strlen:int = str.length;
			const len:int = fixedLength-strlen;
			var finalstr:String = "";

			for(var i:int=0;i<len;i++)
			{
				finalstr+= " ";
			}

			return finalstr+str;
		}

		public function setMirror(flag:Boolean):void
		{
			canvasMirror = flag;
			update();
		}

		public function update():void
		{
			if(canvasInfoFormat.align === TextFormatAlign.RIGHT)
			{
				canvasInfo.text = getMirorrString()+"  "+canvasWidth +" x "+ canvasHeight +"  "
								+ getStringFixedLength(canvasZoom.toString(),3)+"%  "
								+ getStringFixedLength(canvasRotate.toString(),3)+"° "
			}
			else
			{
				canvasInfo.text = canvasWidth +" x "+ canvasHeight +"  "
								+ getStringFixedLength(canvasZoom.toString(),3)+"%  "
								+ getStringFixedLength(canvasRotate.toString(),3)+"°  "
								+ getMirorrString();
			}
			// canvasInfo.width = canvasInfo.textWidth+10;
			canvasInfo.defaultTextFormat = canvasInfoFormat;
		}

		public function appInfoBar() {
			mouseEnabled = false;
		}
	}
}
