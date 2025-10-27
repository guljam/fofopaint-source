package
{
    import Main;

	public class shortCutMapSet {
        private var m:Main;
		private const maps:Object =
		{
			"aaa":function():void{m.hello()}
		}

		public function start(key:String):String
		{
			return key[key]();
		}

        public function shortCutMapSet():void
        {
            // m = mainInstance;
        }
	}
}

