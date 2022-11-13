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
				// trace('스테이지 추가');
				framerate = initStage.frameRate;
				stage = initStage;
			}
			else
			{
				// trace('이미 추가되어있음');
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
							// // trace('반복 시작 ',list[i][0],'오차',getTimer()-list[i][1]);
							list[i][1] += list[i][2];
						}
					}
					else
					{
						// // trace('타임아웃',list[i][0],'오차',getTimer()-list[i][1]);
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
					// trace('타이머가 존재함',name);
					return true;
				}
			}
			// trace('타이머가 존재하지 않음',name);
			return false;
		}

		public function remove(name:String):void
		{
			const len:uint = list.length;
			for(var i:uint=0;i<len;i++)
			{
				if(name === list[i][0])
				{
					// trace('타이머 삭제',name);
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
			// trace('[타이머 추가] ',name);
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
