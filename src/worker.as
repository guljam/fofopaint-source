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

		// private var gcCount:int;
		// private function doGC(evt:Event):void
		// {
		// 	System.gc();
		// 	if(++gcCount > 1)
		// 	{
		// 		removeEventListener(Event.ENTER_FRAME, doGC);
		// 		setTimeout(lastGC,40);
		// 	}
		// }

		// private function lastGC():void
		// {
		// 	System.gc();
		// }

		// private function startGC():void
		// {
		// 	gcCount = 0;
		// 	addEventListener(Event.ENTER_FRAME, doGC);
		// }


		private function encodePNG(msg:Object):void
		{
			var ba:ByteArray = msg.bytes;
			var w:Number = msg.width;
			var h:Number = msg.height;
			var bg:uint = ((0xFF000000 | msg.bg) & 0xFFFFFFFF);
			var bmpd:BitmapData = new BitmapData(w,h,true,bg);
			var bmpd2:BitmapData = new BitmapData(w,h,true,0);
			ba.position = 0;
			bmpd2.lock();
			bmpd2.setPixels(new Rectangle(0,0,w,h),ba);
			bmpd2.unlock();
			bmpd.draw(bmpd2);
			ba.clear();
			bmpd.encode(new Rectangle(0,0,w,h),new PNGEncoderOptions(),ba);
			var obj:Object = {command:"encodePNGDone",bytes:ba};
			backToMain.send(obj);
			bmpd.dispose();
			bmpd2.dispose();
			ba = null;
			obj = null;
		}

		private function compressUndoData(msg:Object):void
		{
			var ba:ByteArray = msg.data;
			ba.compress();
			var obj:Object = {command:"compress_UndoDataDone",data:ba};
			backToMain.send(obj);
			ba.length = 0;
			ba = null;
			obj = null;
		}

		private function compressReplayData(msg:Object):void
		{
			var ba1:ByteArray = msg.dataA;
			var ba2:ByteArray = msg.dataB;
			var ba3:ByteArray = msg.dataC;
			var ba4:ByteArray = msg.dataD;
			ba1.compress();
			ba2.compress();
			ba3.compress();
			ba4.compress();
			var obj:Object = {command:"compress_ReplayDataDone"
							,dataA:ba1
							,dataB:ba2
							,dataC:ba3
							,dataD:ba4};
			backToMain.send(obj);
			ba1 = null;
			ba2 = null;
			ba3 = null;
			ba4 = null;
			obj = null;
		}

		private function onFromMain(event:Event):void
		{
			var msg:* = mainToBack.receive();
			
			if(msg as Object)
			{
				const command:String = msg.command;
				if(command === "compress_ReplayData") compressReplayData(msg);
				else if(command === "compress_UndoData") compressUndoData(msg);
				else if(command === "encodePNG") encodePNG(msg);
			}
			msg = null;
		}
	}
}
