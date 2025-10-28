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
		static private const list:Array = [];

		static private function tick(e:Event):void
		{
			var len:uint = list.length;
			if (len === 0)
			{
				started = false;
				dummy.removeEventListener(Event.ENTER_FRAME, tick);
			}

			var _func:Array;
			for (var i:uint = 0; i < len; i++)
			{
				if (list[i])
				{
					if (getTimer() >= list[i][1]) // time out
					{
						if (list[i][3]) // check loop flag
						{
							// false를 반환하면 타이머제거하고 종료
							if (list[i][4].apply(Main, list[i][5]) === false || !list[i])
							{
								list.splice(i, 1)[0];
								i--;
								len--;
							}
							else // 아니면 다음 시간을 추가하고 연장
							{
								list[i][1] = getTimer() + list[i][2];
							}
						}
						else // call func and remove timer
						{
							_func = list.splice(i, 1)[0];
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
			const len:uint = list.length;
			for (var i:uint = 0; i < len; i++)
			{
				if (name === list[i][0])
				{
					return true;
				}
			}
			return false;
		}

		static public function remove(name:String):void
		{
			const len:uint = list.length;
			for (var i:uint = 0; i < len; i++)
			{
				if (name === list[i][0])
				{
					list.splice(i, 1);
					break;
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

			list.push([name, // 이름
						getTimer() + (time * 1000), // 실행할 시간
						time * 1000, // 루프힐때 더해줄 시간
						loopFlag, // 루프 인지아닌지?
						func, // 타이머 다되면 실행할 함수
						args]); // 실행할 함수의 매개변수
		}
	}
}
