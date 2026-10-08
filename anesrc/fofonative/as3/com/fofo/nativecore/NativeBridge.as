package com.fofo.nativecore
{
    import flash.events.StatusEvent;
    import flash.external.ExtensionContext;

    // ANE의 library.swf에 들어가는 AS3 쪽 연결 클래스
    // createExtensionContext는 이 library.swf 안의 코드에서 불러야 함 (앱 SWF 코드에서 부르면 Error #2113)
    // 앱은 워커와 ANE가 없는 환경을 위해 getDefinitionByName으로 이 클래스를 찾아서 씀 (Modules.NativeCore)
    // 기능은 네이티브 함수 이름으로 부르게 해서 기능이 늘어도 이 클래스는 바뀌지 않게 함
    public class NativeBridge
    {
        public static const EXTENSION_ID:String = "com.fofo.nativecore";
        private static var context:ExtensionContext = null;

        // 네이티브 빌드가 없는 운영체제(default 플랫폼)면 false
        public static function open():Boolean
        {
            if (context === null)
            {
                context = ExtensionContext.createExtensionContext(EXTENSION_ID, null);
            }

            return context !== null;
        }

        public static function close():void
        {
            if (context !== null)
            {
                context.dispose();
                context = null;
            }
        }

        public static function call(name:String, args:Array):*
        {
            return context.call.apply(context, [name].concat(args));
        }

        // 네이티브 스레드가 끝낸 작업 알림 (FREDispatchStatusEventAsync)
        public static function addStatusListener(listener:Function):void
        {
            context.addEventListener(StatusEvent.STATUS, listener);
        }

        public static function removeStatusListener(listener:Function):void
        {
            if (context !== null)
            {
                context.removeEventListener(StatusEvent.STATUS, listener);
            }
        }
    }
}
