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
		static private const timerList:Object = {};
		static private const deadTimers:Object = {};

		static private function tick(e:Event):void
		{
			var len:int = timerList.length;
			var loopCount:int = 0;
			var deadTimerCount:int = 0;

			for (var key:String in timerList)
			{
				loopCount++;
				const timer:Object = timerList[key];
				if (timer === null)
				{
					deadTimerCount++;
					deadTimers[key] = 0;
					continue;
				}

				if (getTimer() >= timer.callTime)
				{
					const flag:* = (timer.func).apply(Main, timer.args);

					if (timer.loop && flag !== false)
					{
						timer.callTime = getTimer() + timer.nextTime;
					}
					else
					{
						deadTimerCount++;
						timerList[key] = null;
						deadTimers[key] = 0;
					}
				}
			}

			if (deadTimerCount > 0)
			{
				for (var deadKey:String in deadTimers)
				{
					delete timerList[deadKey];
					delete deadTimers[deadKey];
				}
			}

			if (loopCount === 0)
			{
				started = false;
				dummy.removeEventListener(Event.ENTER_FRAME, tick);
			}
		}

		static public function hasTimer(name:String):Boolean
		{
			return timerList.hasOwnProperty(name) && timerList[name] !== null;
		}

		static public function remove(name:String):void
		{
			if (timerList.hasOwnProperty(name))
			{
				delete timerList[name];
				delete deadTimers[name];
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

			timerList[name] = {
					callTime: getTimer() + (time * 1000),
					nextTime: (time * 1000),
					loop: loopFlag,
					func: func,
					args: args
				};
		}
	}
}
