package Modules.L1Data
{
    import flash.system.Worker;
    import flash.utils.getDefinitionByName;

    // 네이티브 확장(com.fofo.nativecore, anesrc/fofonative)을 앱에서 쓰는 곳은 이 클래스 하나로 모음
    // ANE가 없거나(default 플랫폼: macOS 등), 워커이거나, 컨텍스트를 못 만들면 isAvailable이 false이고
    // 호출한 쪽은 기존 AS3/워커 경로로 처리함
    // 층: L1 데이터 - 네이티브 확장(ANE) 호출을 모은 단일 창구
    public final class NativeCore
    {
        // ANE의 library.swf에 있는 연결 클래스, ANE가 없는 환경을 위해 직접 참조하지 않고 이름으로 찾음
        private static const NATIVE_BRIDGE_CLASS_NAME:String = "com.fofo.nativecore.NativeBridge";
        public static const OK:int = 1;

        // 테스트에서 대체 경로를 시험할때 처음 쓰기 전에 true로 둠
        public static var isDisabled:Boolean = false;
        private static var nativeBridge:Object = null;
        private static var isNativeBridgeOpenTried:Boolean = false;
        private static var nativeJobSequence:int = 0;

        // 네이티브 작업 번호 (저장, 캐시 작업의 결과를 같은 표에 보관하므로 한곳에서 발급)
        public static function nextNativeJobId():int
        {
            return ++nativeJobSequence;
        }

        // 네이티브 확장을 쓸 수 있는지 (처음 물어볼때 한 번만 열어봄)
        public static function get isAvailable():Boolean
        {
            if (!isNativeBridgeOpenTried)
            {
                openNativeBridge();
            }

            return nativeBridge !== null;
        }

        // 네이티브 확장 연결을 한 번 열어봄. 실패하거나 워커이면 nativeBridge는 null로 남음
        private static function openNativeBridge():void
        {
            isNativeBridgeOpenTried = true;

            // 워커에서도 ANE 클래스는 보이지만 ExtensionContext를 만들 수 없음(#3731)
            if (isDisabled || !Worker.current.isPrimordial)
            {
                return;
            }

            var nativeBridgeClass:Object;

            try
            {
                nativeBridgeClass = getDefinitionByName(NATIVE_BRIDGE_CLASS_NAME);
            }
            catch (error:Error)
            {
                trace("NativeCore: extension not found");
                return;
            }

            try
            {
                // 네이티브 빌드가 없는 운영체제(default 플랫폼)면 false
                if (nativeBridgeClass.open())
                {
                    nativeBridge = nativeBridgeClass;
                }
            }
            catch (error:Error)
            {
                trace("NativeCore: " + error);
            }

            trace("NativeCore: " + ((nativeBridge !== null) ? "native" : "actionscript"));
        }

        // 네이티브 함수 호출, 쓸 수 없거나 예외가 나면 undefined
        public static function callNativeFunction(nativeFunctionName:String, ...nativeArguments):*
        {
            if (!isAvailable)
            {
                return undefined;
            }

            try
            {
                return nativeBridge.call(nativeFunctionName, nativeArguments);
            }
            catch (error:Error)
            {
                trace("NativeCore " + nativeFunctionName + ": " + error);
            }

            return undefined;
        }

        // 결과 코드(int)를 돌려주는 네이티브 함수용, 실패하면 0 이하
        public static function callNativeFunctionForResultCode(nativeFunctionName:String, ...nativeArguments):int
        {
            if (!isAvailable)
            {
                return 0;
            }

            try
            {
                const nativeReturnValue:* = nativeBridge.call(nativeFunctionName, nativeArguments);
                return (nativeReturnValue is int) ? nativeReturnValue : 0;
            }
            catch (error:Error)
            {
                trace("NativeCore " + nativeFunctionName + ": " + error);
            }

            return 0;
        }

        // 네이티브가 보내는 StatusEvent를 받을 리스너를 등록
        public static function addNativeStatusListener(nativeStatusListener:Function):void
        {
            if (isAvailable)
            {
                nativeBridge.addStatusListener(nativeStatusListener);
            }
        }
    }
}
