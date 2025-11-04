package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;

	public class FOFOTimer extends Sprite
	{
		static private const dummy:Sprite = new Sprite();
		static private var timerCount:Number = 0;
		static private var started:Boolean = false;
		static private const timerListName:Object ={};
		static private const timerList:Array = [];

		static private function tick(e:Event):void
		{
			var len:uint = timerList.length;
			if (len === 0)
			{
				started = false;
				dummy.removeEventListener(Event.ENTER_FRAME, tick);
			}

			var _func:Array;
			for (var i:uint = 0; i < len; i++)
			{
				if (timerList[i])
				{
					if (getTimer() >= timerList[i][1]) // time out
					{
						if (timerList[i][3]) // check loop flag
						{
							// false를 반환하면 타이머제거하고 종료
							if (timerList[i][4].apply(Main, timerList[i][5]) === false || !timerList[i])
							{
								delete timerListName[timerList[i][0]];
								timerList.splice(i, 1)[0];
								i--;
								len--;
							}
							else // 아니면 다음 시간을 추가하고 연장
							{
								timerList[i][1] = getTimer() + timerList[i][2];
							}
						}
						else // call func and remove timer
						{
							delete timerListName[timerList[i][0]];
							_func = timerList.splice(i, 1)[0];
							_func[4].apply(Main, _func[5]);
							i--;
							len--;
						}
					}
				}
			}
		}

		static public function hasTimer(name:String):Boolean
		{
			return timerListName.hasOwnProperty(name);
		}

		static public function remove(name:String):void
		{
			if(timerListName.hasOwnProperty(name))
			{
				delete timerListName[name];

				const len:uint = timerList.length;
				for (var i:uint = 0; i < len; i++)
				{
					if (name === timerList[i][0])
					{
						timerList.splice(i, 1);
						break;
					}
				}
			}
		}

		static public function add(time:Number, loopFlag:Boolean, func:Function, args:Array = null):void
		{
			addByName("_timer_" + timerCount, time, loopFlag, func, args);
			timerCount++;
		}

		static public function addByName(name:String, time:Number, loopFlag:Boolean, func:Function, args:Array = null):void
		{
			if (!started)
			{
				started = true;
				dummy.addEventListener(Event.ENTER_FRAME, tick);
			}

			remove(name);

			timerListName[name] = 0;
			timerList.push([name, // 이름
						getTimer() + (time * 1000), // 실행할 시간
						time * 1000, // 루프힐때 더해줄 시간
						loopFlag, // 루프 인지아닌지?
						func, // 타이머 다되면 실행할 함수
						args]); // 실행할 함수의 매개변수
		}
	}
}
