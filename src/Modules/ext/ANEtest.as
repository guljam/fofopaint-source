package Modules.ext
{
    import flash.events.EventDispatcher;
    import flash.events.StatusEvent;
    import flash.external.ExtensionContext;

    public class ANEtest extends EventDispatcher
    {
        private var ctx:ExtensionContext;

        public function ANEtest()
        {
            ctx = ExtensionContext.createExtensionContext("com.fofo.threadtest", null);
            ctx.addEventListener(StatusEvent.STATUS, onStatus);
        }

        public function callnativefunc():void
        {
            ctx.call("callnativefunc"); // 네이티브 함수 호출
        }

        private function onStatus(e:StatusEvent):void
        {
            trace("받음: " + e.code); // "hello", "world" 출력
        }

    }
}
