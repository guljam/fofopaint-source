package
{
	import flash.display.Sprite;
	import flash.text.TextField;
	
	public class appInfoBar extends Sprite {
		public var canvasInfo:TextField = canvasInfo;
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

		public function setMirror(flag:Boolean):void
		{
			canvasMirror = flag;
			update();
		}

		public function update():void
		{
			canvasInfo.text = canvasWidth +" x "+ canvasHeight +"  "
							 + canvasZoom+"%  "
							 + canvasRotate+"°  "
							 + getMirorrString();
			canvasInfo.width = canvasInfo.textWidth+10;
		}

		public function appInfoBar() {
		}
	}
}
