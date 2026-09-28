package com.fofo.pixeldump
{
    import flash.display.BitmapData;
    import flash.external.ExtensionContext;
    import flash.utils.ByteArray;

    // ANE의 library.swf에 들어가는 AS3 쪽 연결 클래스
    // createExtensionContext는 이 library.swf 안의 코드에서 불러야 함 (앱 SWF 코드에서 부르면 Error #2113)
    // 앱은 워커와 ANE가 없는 환경을 위해 getDefinitionByName으로 이 클래스를 찾아서 씀 (Modules.PixelRestore)
    public class PixelDump
    {
        public static const EXTENSION_ID:String = "com.fofo.pixeldump";
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

        // table: [알파 << 8 | copyPixelsToByteArray 출력값] -> 내부 premultiplied 값, 65536바이트
        public static function setTable(table:ByteArray):int
        {
            return int(context.call("setTable", table));
        }

        // pixels의 offset부터 copyPixelsToByteArray 형식으로 bitmap 전체를 원래 내부값 그대로 채움, 성공하면 1
        public static function restore(bitmap:BitmapData, pixels:ByteArray, offset:int):int
        {
            return int(context.call("restore", bitmap, pixels, offset));
        }
    }
}
