package
{
	import Main;

	public class shortcutManager
	{
		private var _main:Main;
		private const maps:Object =
			{
				"f": function():void
				{
					// _main.startKeyRepeat(true,_main.adjustPenSizeByShortcut,true)
				}
			};

		public function find(key:String):Boolean
		{
			return true;
		}

		public function shortcutManager(mm:Main):void
		{
			_main = mm;
		}
	}
}
