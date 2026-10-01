package Modules
{
    import flash.events.KeyboardEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.system.Capabilities;
    import flash.system.IME;
    import flash.ui.Keyboard;
    import flash.utils.getTimer;

    // 일본어/중국어 등 IME 환경에서 키 입력과 IME 상태를 기록하는 진단 도구
    // 키보드 조합은 IME가 켜진 상태에서 동작하지 않을 수 있으므로, 앱 저장 폴더에 마커 파일을 만들어서 켬
    //   1) <앱 저장 폴더>/ime_diag_on.txt (빈 파일) 생성
    //   2) 앱을 실행(이미 실행 중이면 창을 다시 활성화)하고 IME 모드별로 키를 눌러봄
    //   3) <앱 저장 폴더>/ime_diag.txt 를 전달. 마커 파일을 지우면 꺼짐
    public class ImeDiagnostics
    {
        public static const MARKER_FILE:String = "ime_diag_on.txt";
        public static const LOG_FILE:String = "ime_diag.txt";
        private static const MAX_LINES:int = 4000;
        private static const NEWLINE:String = String.fromCharCode(10);

        private static var _enabled:Boolean = false;
        private static var lineCount:int = 0;

        public static function get enabled():Boolean
        {
            return _enabled;
        }

        // 마커 파일 유무로 켜고 끔. 켜질때 환경 정보를 헤더로 기록함
        public static function checkMarker():void
        {
            var markerExists:Boolean = false;

            try
            {
                markerExists = File.applicationStorageDirectory.resolvePath(MARKER_FILE).exists;
            }
            catch (err:Error)
            {
            }

            if (markerExists && !_enabled)
            {
                _enabled = true;
                lineCount = 0;
                writeHeader();
            }
            else if (!markerExists)
            {
                _enabled = false;
            }
        }

        public static function log(tag:String, detail:String = ""):void
        {
            if (!_enabled)
            {
                return;
            }

            if (lineCount >= MAX_LINES)
            {
                _enabled = false;
                write("[" + getTimer() + "] LOG_CAP_REACHED (" + MAX_LINES + " lines), logging stopped");
                return;
            }

            lineCount++;
            write("[" + getTimer() + "] " + tag + (detail !== "" ? " " + detail : ""));
        }

        public static function logKey(type:String, e:KeyboardEvent, focusDesc:String, textInputFocused:Boolean, verdict:String):void
        {
            log("KEY_" + type,
                "keyCode=" + e.keyCode
                + " charCode=" + e.charCode
                + " location=" + e.keyLocation
                + " ctrl=" + e.ctrlKey + " alt=" + e.altKey + " shift=" + e.shiftKey
                + " focus=" + focusDesc
                + " textInput=" + textInputFocused
                + " verdict=" + verdict
                + " ime[" + describeImeState() + "]");
        }

        public static function describeImeState():String
        {
            var enabledStr:String;
            var modeStr:String;

            try
            {
                enabledStr = String(IME.enabled);
            }
            catch (err:Error)
            {
                enabledStr = "err:" + err.message;
            }

            try
            {
                modeStr = String(IME.conversionMode);
            }
            catch (err2:Error)
            {
                modeStr = "n/a";
            }

            return "enabled=" + enabledStr + " mode=" + modeStr;
        }

        private static function writeHeader():void
        {
            var languages:String = "";

            try
            {
                languages = Capabilities.languages.join(",");
            }
            catch (err:Error)
            {
            }

            write("===== IME diagnostics start " + new Date().toString() + " =====");
            write("os=" + Capabilities.os
                + " language=" + Capabilities.language
                + " languages=" + languages
                + " hasIME=" + Capabilities.hasIME
                + " playerVersion=" + Capabilities.version
                + " physicalKeyboardType=" + Keyboard.physicalKeyboardType);
            write("ime[" + describeImeState() + "]");
        }

        private static function write(line:String):void
        {
            try
            {
                const fs:FileStream = new FileStream();
                fs.open(File.applicationStorageDirectory.resolvePath(LOG_FILE), FileMode.APPEND);
                fs.writeUTFBytes(line + NEWLINE);
                fs.close();
            }
            catch (err:Error)
            {
                // 진단 기록 실패가 앱 동작에 영향을 주면 안됨
            }
        }
    }
}
