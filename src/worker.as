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

		private function onFromMain(event:Event):void
		{
			const msg:* = mainToBack.receive();

			if(msg as Array)
			{
				if(msg[0] === "compress_ReplayData")
				{
					backToMain.send("start");
					const ba1:ByteArray = msg[1];
					const ba2:ByteArray = msg[2];
					const ba3:ByteArray = msg[3];
					const ba4:ByteArray = msg[4];
					ba1.compress();
					ba2.compress();
					ba3.compress();
					ba4.compress();
					backToMain.send(["compress_ReplayDataDone",ba1,ba2,ba3,ba4]);
					backToMain.send("end");
					ba1.clear();
					ba2.clear();
					ba3.clear();
					ba4.clear();
				}
				else if(msg[0] === "encodePNG")
				{
					backToMain.send("start");
					const ba:ByteArray = msg[1];
					const w:Number = msg[2];
					const h:Number = msg[3];
					const bg:uint = ((0xFF000000 | msg[4]) & 0xFFFFFFFF);
					const bmpd:BitmapData = new BitmapData(w,h,true,bg);
					const bmpd2:BitmapData = new BitmapData(w,h,true,0);
					ba.position = 0;
                    bmpd2.lock();
                    bmpd2.setPixels(new Rectangle(0,0,w,h),ba);
                    bmpd2.unlock();
					bmpd.draw(bmpd2);
					ba.clear();
					bmpd.encode(new Rectangle(0,0,w,h),new PNGEncoderOptions(),ba);
					backToMain.send(["encodePNGDone",ba]);
					backToMain.send("end");
					ba.clear();
				}
			}
		}
	}
}
