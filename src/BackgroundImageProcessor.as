package
{

	import flash.display.Sprite;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.display.BitmapData;
	import flash.display.PNGEncoderOptions;
	import flash.geom.Rectangle;

	public class BackgroundImageProcessor extends Sprite
	{
		private var bgWorker:Worker;
		private var mainToBack:MessageChannel;
		private var backToMain:MessageChannel;
		private var command:String;
		private var args:Array;

		public function BackgroundImageProcessor()
		{
			bgWorker = Worker.current;
			mainToBack = bgWorker.getSharedProperty("mainToBack");
			mainToBack.addEventListener(Event.CHANNEL_MESSAGE, onFromMain);
			backToMain = bgWorker.getSharedProperty("backToMain");
		}

		private function encodePNG(ba:ByteArray, w:Number, h:Number, bg:uint, transBGFlag:Boolean, isCaptureImage:Boolean):void
		{
			var bmpd:BitmapData = new BitmapData(w, h, true, (transBGFlag) ? 0 : bg);
			var bmpd2:BitmapData = new BitmapData(w, h, true, 0);

			ba.position = 0;
			bmpd2.lock();
			bmpd2.setPixels(new Rectangle(0, 0, w, h), ba);
			bmpd2.unlock();
			bmpd.draw(bmpd2);
			ba.clear();
			bmpd.encode(new Rectangle(0, 0, w, h), new PNGEncoderOptions(), ba);

			if (isCaptureImage)
				backToMain.send("encodePNGCaptureDone");
			else
				backToMain.send("encodePNGSaveDone");

			backToMain.send(ba);

			ba.clear();
			ba = null;
		}

		private function compressUndoData(ba:ByteArray, ba1:ByteArray):void
		{
			ba.compress();
			ba1.compress();
			backToMain.send("compressed " + ba.length + " / " + ba1.length);
			backToMain.send("compress_UndoDataDone");
			backToMain.send(ba);
			backToMain.send(ba1);

			ba.clear();
			ba1.clear();
			ba = null;
			ba1 = null;
		}

		private function compressReplayData(ba1:ByteArray
				, ba2:ByteArray
				, ba3:ByteArray
				, ba4:ByteArray
				, ba5:ByteArray
				, ba6:ByteArray):void
		{
			ba1.compress();
			ba2.compress();
			ba3.compress();
			ba4.compress();
			ba5.compress();
			ba6.compress();

			backToMain.send("compress_ReplayDataDone");
			backToMain.send(ba1);
			backToMain.send(ba2);
			backToMain.send(ba3);
			backToMain.send(ba4);
			backToMain.send(ba5);
			backToMain.send(ba6);

			ba1.clear();
			ba2.clear();
			ba3.clear();
			ba4.clear();
			ba5.clear();
			ba6.clear();

			ba1 = null;
			ba2 = null;
			ba3 = null;
			ba4 = null;
			ba5 = null;
			ba6 = null;
		}

		private function onFromMain(event:Event):void
		{
			var msg:* = mainToBack.receive();
			var command:String = msg as String;

			if (command === "encodePNG")
			{
				encodePNG(mainToBack.receive(true)
						, mainToBack.receive(true)
						, mainToBack.receive(true)
						, mainToBack.receive(true)
						, mainToBack.receive(true)
						, mainToBack.receive(true));
			}
			else if (command === "compress_ReplayData")
			{
				compressReplayData(mainToBack.receive(true)
						, mainToBack.receive(true)
						, mainToBack.receive(true)
						, mainToBack.receive(true)
						, mainToBack.receive(true)
						, mainToBack.receive(true));
			}
			else if (command === "compress_UndoData")
			{
				compressUndoData(mainToBack.receive(true)
						, mainToBack.receive(true));

			}
		}
	}
}
