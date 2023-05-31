package
{
	import flash.events.Event;
	import flash.utils.getTimer;
	import flash.display.Stage;

	public class fofoTimer {
		static private var stage:Stage;
		static private var framerate:Number;
		static private var timerCount:Number = 0;
		static private var started:Boolean = false;
		static private const list:Array = [];

		public function fofoTimer(initStage:Stage)
		{
			if(!stage)
			{
				framerate = initStage.frameRate;
				stage = initStage;
			}
		}

		private function tick(e:Event):void
		{
			var len:uint = list.length;
			if(len === 0)
			{
				started = false;
				stage.removeEventListener(Event.ENTER_FRAME,tick);
			}

			var _func:Array;
			for(var i:uint=0;i<len;i++)
			{
				if(getTimer() >= list[i][1])
				{
					if(list[i][3])
					{
						if(list[i][4].apply(main,list[i][5]) === false)
						{
							list.splice(i,1)[0];
							i--;
							len--;
						}
						else
						{
							list[i][1] = getTimer()+list[i][2];
						}
					}
					else
					{
						_func = list.splice(i,1)[0];
						_func[4].apply(main,_func[5]);
						i--;
						len--;
					}
				}
			}
		}

		public function hasTimer(name:String):Boolean
		{
			const len:uint = list.length;
			for(var i:uint=0;i<len;i++)
			{
				if(name === list[i][0])
				{
					return true;
				}
			}
			return false;
		}

		public function remove(name:String):void
		{
			const len:uint = list.length;
			for(var i:uint=0;i<len;i++)
			{
				if(name === list[i][0])
				{
					list.splice(i,1);
					break;
				}
			}
		}

		public function add(time:Number,loopFlag:Boolean,func:Function,args:Array=null):void
		{
			addByName("_timer_"+timerCount,time,loopFlag,func,args);
			timerCount++;
		}

		public function addByName(name:String,time:Number,loopFlag:Boolean,func:Function,args:Array=null):void
		{
			if(!started)
			{
				started = true;
				stage.addEventListener(Event.ENTER_FRAME,tick);
			}

			remove(name);

			list.push([name,                   //이름
					   getTimer()+(time*1000), //실행할 시간
					   time*1000,              //루프힐때 더해줄 시간
					   loopFlag,               //루프 인지아닌지?
					   func,                   //타이머 다되면 실행할 함수
					   args]);                 //실행할 함수의 매개변수
		}
	}
}
