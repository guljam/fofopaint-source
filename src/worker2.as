package  {
	
	import flash.display.Sprite;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.display.BitmapData;
	import flash.display.PNGEncoderOptions;
	import flash.geom.Rectangle;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;

	public class worker2 extends Sprite
	{
		private var bgWorker:Worker;
		private var mainToBack:MessageChannel;
		private var backToMain:MessageChannel;
		private var workerSharedBA:ByteArray;
		private var file:File = File.applicationStorageDirectory.resolvePath("test");
		private var fs:FileStream = new FileStream();

		public function worker2()
		{
			bgWorker = Worker.current;
			mainToBack = bgWorker.getSharedProperty("mainToBack");
			mainToBack.addEventListener(Event.CHANNEL_MESSAGE, onFromMain);
			backToMain = bgWorker.getSharedProperty("backToMain");
			workerSharedBA = Worker.current.getSharedProperty("workerSharedBA");
			trace('hello workder2');
		}

		private function encodePNG(msg:Array,isCaptureImage:Boolean):void
		{
			var ba:ByteArray = msg[1];
			var w:Number = msg[2];
			var h:Number = msg[3];
			var bg:uint = msg[4];
			var transBGFlag:uint = msg[5];
			var bmpd:BitmapData = new BitmapData(w,h,true,(transBGFlag)?0:bg);
			var bmpd2:BitmapData = new BitmapData(w,h,true,0);

			ba.position = 0;
			bmpd2.lock();
			bmpd2.setPixels(new Rectangle(0,0,w,h),ba);
			bmpd2.unlock();
			bmpd.draw(bmpd2);
			ba.clear();
			bmpd.encode(new Rectangle(0,0,w,h),new PNGEncoderOptions(),ba);

			var arr:Array = [(isCaptureImage) ? "encodePNGCaptureDone" : "encodePNGSaveDone",ba];

			backToMain.send(arr);
			bmpd.dispose();
			bmpd2.dispose();
			ba = null;
			arr = null;
		}

		private function compressUndoData(msg:Array):void
		{
			var ba:ByteArray = msg[1];
			var ba1:ByteArray = msg[2];

			ba.compress();
			ba1.compress();

			var arr:Array = ["compress_UndoDataDone",ba,ba1];

			backToMain.send(arr);

			ba.clear();
			ba1.clear();
			ba = null;
			ba1 = null;
			arr = null;
		}

		private function compressReplayData(msg:Array):void
		{
			var ba:ByteArray = msg[1];
			workerSharedBA.writeUTFBytes("hello");
			Worker.current.setSharedProperty("workerSharedBA", workerSharedBA);
			ba.compress();

			var arr:Array = ["compress_ReplayDataDone",ba];
			backToMain.send(arr);

			ba.clear();
			ba = null;

			fs.open(file,FileMode.WRITE);
			fs.writeByte(77);
			fs.writeByte(55);
			fs.close();
		}

		private function onFromMain(event:Event):void
		{
			var msg:* = mainToBack.receive();

			if(msg as Array)
			{
				const command:String = msg[0];
				if(command === "compress_ReplayData") compressReplayData(msg);
				else if(command === "compress_UndoData") compressUndoData(msg);
				else if(command === "encodePNGCapture") encodePNG(msg,true);
				else if(command === "encodePNGSave") encodePNG(msg,false);
			}
			msg = null;
		}
	}
}
