package  {
	
	import flash.display.Sprite;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.events.Event;
	import flash.utils.ByteArray;

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
					var ba1:ByteArray = msg[1];
					var ba2:ByteArray = msg[2];
					var ba3:ByteArray = msg[3];
					var ba4:ByteArray = msg[4];
					ba1.compress();
					ba2.compress();
					ba3.compress();
					ba4.compress();
					backToMain.send(["compress_ReplayDataDone",ba1,ba2,ba3,ba4]);
				}
			}
		}
	}
}
