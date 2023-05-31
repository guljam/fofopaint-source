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
		private var command:String;
		private var msg:* = null;
		private var mode:int = 0;
		private var args:Array = [];
		private var data:ByteArray;

		private var MODE_PNG_ENCODE_CAPTURE:int = (1 << 0);
		// private var MODE_PNG_ENCODE_CAPTURE:int = (1 << 1);
		// private var MODE_PNG_ENCODE_CAPTURE:int = (1 << 2);
		// private var MODE_PNG_ENCODE_CAPTURE:int = (1 << 3);

		public function worker()
		{
			bgWorker = Worker.current;
			mainToBack = bgWorker.getSharedProperty("mainToBack");
			mainToBack.addEventListener(Event.CHANNEL_MESSAGE, onFromMain);
			backToMain = bgWorker.getSharedProperty("backToMain");
		}

		private function encodePNG(msg:Array,isCaptureImage:Boolean):void
		{
			backToMain.send("encode start "+msg);
			try
			{
				var ba:ByteArray = new ByteArray();
				ba.writeBytes(data);

				var w:Number = msg[0];
				var h:Number = msg[1];
				var bg:uint = msg[2];
				var transBGFlag:uint = msg[3];
				
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
				ba.clear();
				ba = null;
				bmpd.dispose();
				bmpd2.dispose();
				arr.length = 0;
				arr = null;
			}
			catch(err:Error)
			{
				backToMain.send("err"+err)
			}
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
		}

		private function compressReplayData(msg:Array):void
		{
			var ba:ByteArray = msg[1];

			ba.compress();

			var arr:Array = ["compress_ReplayDataDone",ba];
			backToMain.send(arr);

			ba.clear();
		}

		private function onFromMain(event:Event):void
		{
			msg = mainToBack.receive();
			
			if(msg as String)
			{
				backToMain.send(msg);
			}
			else if(msg as ByteArray || msg as Array)
			{
				backToMain.send("bytearra size :"+msg.length);
			}
			else
			{
				backToMain.send(typeof(msg));
			}

			if(msg as String)
			{
				if(msg === "end")
				{
					if(mode === MODE_PNG_ENCODE_CAPTURE) encodePNG(args,true);
				}
				else if(msg === "encodePNGCapture")
				{
					mode = MODE_PNG_ENCODE_CAPTURE;
					backToMain.send("set mode png encode cap "+mode);
				}
			}
			else if(msg as ByteArray)
			{
				data = msg;
			}
			else
			{
				args.push(msg);
			}
			// if(msg as ByteArray)
			// {
			// 	var arr:Array = msg.readObject();
			// 	var command:String = arr[0];

			// 	if(command === "compress_ReplayData") compressReplayData(arr);
			// 	else if(command === "compress_UndoData") compressUndoData(arr);
			// 	else if(command === "encodePNGSave") encodePNG(arr,false);

			// 	msg = null;
			// 	arr = null;
			// 	command = null;
			// }
		}
	}
}
