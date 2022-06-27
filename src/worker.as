package  {
	
	import flash.display.Sprite;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.display.BitmapData;
	import flash.display.PNGEncoderOptions;
	import flash.geom.Rectangle;

	public class worker extends Sprite
	{
		private var bgWorker:Worker;
		private var mainToBack:MessageChannel;
		private var backToMain:MessageChannel;
		
		public function worker()
		{
			bgWorker = Worker.current;
			mainToBack = bgWorker.getSharedProperty("mainToBack");
			mainToBack.addEventListener(Event.CHANNEL_MESSAGE, onFromMain);
			backToMain = bgWorker.getSharedProperty("backToMain");
		}

		private function encodePNG(msg:Array):void
		{
			backToMain.send("start");
			var ba:ByteArray = msg[1];
			var w:Number = msg[2];
			var h:Number = msg[3];
			var bg:uint = ((0xFF000000 | msg[4]) & 0xFFFFFFFF);
			var bmpd:BitmapData = new BitmapData(w,h,true,bg);
			var bmpd2:BitmapData = new BitmapData(w,h,true,0);
			ba.position = 0;
			bmpd2.lock();
			bmpd2.setPixels(new Rectangle(0,0,w,h),ba);
			bmpd2.unlock();
			bmpd.draw(bmpd2);
			ba.clear();
			bmpd.encode(new Rectangle(0,0,w,h),new PNGEncoderOptions(),ba);
			var arr:Array = ["encodePNGDone",ba];
			backToMain.send(arr);
			backToMain.send("end");
			ba.length = 0;
			bmpd.dispose();
			bmpd2.dispose();
			arr = null;
		}

		private function compressUndoData(msg:Array):void
		{
			var ba:ByteArray = msg[1];
			ba.compress();
			var arr:Array = ["compress_UndoDataDone",ba];
			backToMain.send(arr);
			ba.length = 0;
			ba = null;
			arr = null;
		}

		private function compressReplayData(msg:Array):void
		{
			backToMain.send("start");
			var ba1:ByteArray = msg[1];
			var ba2:ByteArray = msg[2];
			var ba3:ByteArray = msg[3];
			var ba4:ByteArray = msg[4];
			ba1.compress();
			ba2.compress();
			ba3.compress();
			ba4.compress();
			var arr:Array = ["compress_ReplayDataDone",ba1,ba2,ba3,ba4];
			backToMain.send(arr);
			backToMain.send("end");
			ba1.length = 0;
			ba2.length = 0;
			ba3.length = 0;
			ba4.length = 0;
			ba1 = null;
			ba2 = null;
			ba3 = null;
			ba4 = null;
			arr = null;
		}

		private function onFromMain(event:Event):void
		{
			var msg:* = mainToBack.receive();

			if(msg as Array)
			{
				if(msg[0] === "compress_ReplayData")
				{
					compressReplayData(msg);
				}
				else if(msg[0] === "compress_UndoData")
				{
					compressUndoData(msg);
				}
				else if(msg[0] === "encodePNG")
				{
					encodePNG(msg);
				}
			}
			msg = null;
		}
	}
}
