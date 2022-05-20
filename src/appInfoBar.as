package
{
	import flash.display.Sprite;
	import flash.text.TextField;
	
	public class appInfoBar extends Sprite {
		public var canvasInfo:TextField = canvasInfo;

		public var canvasInfoArr:Array = [0.0,0.0,100.0,0.0]; //tool, canvas w , canvas h , zoom , rotate, mirror
		
		public function insertCanvasInfo(arr:Array):void
		{
			if(arr[0] !== null) canvasInfoArr[0] = arr[0];
			if(arr[1] !== null) canvasInfoArr[1] = arr[1];
			if(arr[2] !== null) canvasInfoArr[2] = arr[2];
			if(arr[3] !== null) canvasInfoArr[3] = arr[3];

			updateCanvasInfo();
		}

		public function updateCanvasInfo():void
		{
			const arr:Array = canvasInfoArr;
			const str:String = arr[0] +" x "+ arr[1] +"  "
								+ arr[2]+"%  "
								+ arr[3]+"°"
			canvasInfo.text = str;
			canvasInfo.width = canvasInfo.textWidth+20;
		}

		public function appInfoBar() {
		}
	}
}
