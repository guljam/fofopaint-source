package com.fofo.pigmentmix
{
    import flash.display.BitmapData;
    import flash.external.ExtensionContext;

    // ANE의 library.swf에 들어가는 AS3 쪽 연결 클래스
    // createExtensionContext는 이 library.swf 안의 코드에서 불러야 함 (앱 SWF 코드에서 부르면 Error #2113)
    // 앱은 워커와 ANE가 없는 환경을 위해 getDefinitionByName으로 이 클래스를 찾아서 씀
    public class PigmentMix
    {
        public static const EXTENSION_ID:String = "com.fofo.pigmentmix";
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

        // draw의 알파를 획 모양으로 보고 color, alpha 획을 layer에 안료 혼합으로 합성함
        // threads가 0이면 CPU 스레드 수만큼 씀
        // 성공하면 네이티브 처리 시간(마이크로초), 실패하면 음수
        public static function composite(layer:BitmapData, draw:BitmapData, x:int, y:int, width:int, height:int, color:uint, alpha:Number, threads:int = 0):Number
        {
            return Number(context.call("composite", layer, draw, x, y, width, height, color, alpha, threads));
        }

        // 검증용 mixbox 원본 결과 (RGB)
        public static function lerpRef(color1:uint, color2:uint, t:Number):int
        {
            return int(context.call("lerpRef", color1, color2, t));
        }

        public static function hardwareThreads():int
        {
            return int(context.call("hardwareThreads"));
        }
    }
}
