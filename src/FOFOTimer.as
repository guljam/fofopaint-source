package
{
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	import flash.events.Event;
	import flash.utils.getTimer;

	public class FOFOTimer extends Sprite
	{
		private static const dummy:Sprite = new Sprite();
		private static const timerList:Dictionary = new Dictionary();
		private static var timerCount:int = 0;
		private static var nextTimerId:uint = 0;
		private static var started:Boolean = false;

		private static function tick(e:Event):void
		{
			// 콜백이 타이머를 추가하거나 제거해도 이번 프레임의 순회 대상은 고정한다.
			const snapshot:Array = [];
			for (var key:* in timerList)
			{
				snapshot.push({name: key, timer: timerList[key]});
			}

			for each (var entry:Object in snapshot)
			{
				const name:String = entry.name;
				const timer:Object = entry.timer;
				if (timerList[name] !== timer || uint(getTimer() - timer.startTime) < timer.delay)
				{
					continue;
				}

				var completed:Boolean = false;
				var result:*;
				try
				{
					result = timer.func.apply(Main, timer.args);
					completed = true;
				}
				finally
				{
					// 콜백이 같은 이름을 다시 등록했다면 새 타이머는 건드리지 않는다.
					if (timerList[name] === timer)
					{
						if (!completed || !timer.loop || result === false)
						{
							remove(name);
						}
						else
						{
							timer.startTime = getTimer();
						}
					}
				}
			}
		}

		public static function hasTimer(name:String):Boolean
		{
			return timerList[name] !== undefined;
		}

		public static function remove(name:String):void
		{
			if (!hasTimer(name))
			{
				return;
			}

			delete timerList[name];
			timerCount--;
			if (timerCount === 0)
			{
				started = false;
				dummy.removeEventListener(Event.ENTER_FRAME, tick);
			}
		}

		public static function add(time:Number, loopFlag:Boolean, func:Function, args:Array = null):void
		{
			var name:String;
			do
			{
				name = "_timer_" + nextTimerId++;
			}
			while (hasTimer(name));

			addByName(name, time, loopFlag, func, args);
		}

		public static function addByName(name:String, time:Number, loopFlag:Boolean, func:Function, args:Array = null):void
		{
			if (name === null || func === null || isNaN(time) || !isFinite(time) || time < 0 || time > 4294967.295)
			{
				throw new ArgumentError("Invalid FOFOTimer arguments");
			}

			if (!hasTimer(name))
			{
				timerCount++;
			}

			timerList[name] = {
				startTime: getTimer(),
				delay: time * 1000,
				loop: loopFlag,
				func: func,
				args: args
			};

			if (!started)
			{
				started = true;
				dummy.addEventListener(Event.ENTER_FRAME, tick);
			}
		}
	}
}
