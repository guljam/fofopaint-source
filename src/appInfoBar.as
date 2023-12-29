package
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.display.SimpleButton;
	import flash.text.TextFieldAutoSize;
	import flash.geom.ColorTransform;

	public class appInfoBar extends Sprite {
		public var appInfoArrow:SimpleButton;
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
			canvasRotate = Math.abs(r);
			update();
		}

		public function getMirorrString():String
		{
			return (canvasMirror) ? "m*" : "";
		}

		public function getStringFixedLength(str:String,fixedLength:int):String
		{
			const strlen:uint = str.length;
			const len:int = fixedLength-strlen;
			var finalstr:String = "";

			for(var i:uint=0;i<len;i++)
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
			canvasInfo.text = canvasWidth +" x "+ canvasHeight +"  "
							+ getStringFixedLength(canvasZoom.toString(),3)+"%  "
							+ getStringFixedLength(canvasRotate.toString(),3)+"°  "
							+ getMirorrString();
		}

		public function changeUIColor(color:uint):void
		{
			const appInfoArrowColor:ColorTransform = new ColorTransform();

			canvasInfo.textColor = color;
			appInfoArrowColor.color = color;
			appInfoArrow.transform.colorTransform = appInfoArrowColor
		}

		public function appInfoBar() {
			mouseEnabled = false;
			canvasInfo.mouseEnabled = false;
			canvasInfo.autoSize = TextFieldAutoSize.LEFT;
			appInfoArrow.mouseEnabled = false;
			appInfoArrow.x = 10;
			appInfoArrow.y = 0;
			canvasInfo.x = appInfoArrow.x+appInfoArrow.width+3;
			canvasInfo.y = 0;
		}
	}
}
