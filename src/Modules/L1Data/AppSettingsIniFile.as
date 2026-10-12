package Modules.L1Data
{
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;

    // 앱 데이터 폴더(portable_<버전>)의 settings.ini 읽기와 쓰기. 사람이 메모장으로 고치는 key=value 형식
    // 층: L1 데이터 - 사용자가 직접 고치는 앱 설정 값
    public class AppSettingsIniFile
    {
        private static const KEY_LEFT_HANDED:String = "left-handed";

        public static var isLeftHandedMouseCursor:Boolean = false; // 마우스 커서 그림을 좌우 반전하고 핫스팟도 반대쪽으로

        private static var lastLoadedIniFileModificationTime:Number = NaN;

        // 앱을 켤 때 부름. 파일이 없으면 기본값으로 만들어 둠
        public static function loadSettingsFromIniFile():void
        {
            const iniFile:File = getFreshIniFile();
            if (!iniFile.exists)
            {
                writeSettingsToIniFile();
                return;
            }
            readSettingsFromIniFile(iniFile);
        }

        // 앱 창이 다시 포커스를 받을 때 부름. 파일이 바뀌었고 설정 값이 달라졌을 때만 true
        public static function reloadSettingsIfIniFileChanged():Boolean
        {
            const iniFile:File = getFreshIniFile();
            const wasLeftHandedMouseCursor:Boolean = isLeftHandedMouseCursor;
            if (!iniFile.exists)
            {
                isLeftHandedMouseCursor = false;
                writeSettingsToIniFile();
                return wasLeftHandedMouseCursor !== isLeftHandedMouseCursor;
            }
            if (iniFile.modificationDate.time === lastLoadedIniFileModificationTime)
            {
                return false;
            }
            readSettingsFromIniFile(iniFile);
            return wasLeftHandedMouseCursor !== isLeftHandedMouseCursor;
        }

        // File 객체는 수정 시각을 한번 읽으면 기억하므로 매번 새로 만듦
        private static function getFreshIniFile():File
        {
            return new File(AppDataPaths.settingsFilePath.nativePath);
        }

        private static function readSettingsFromIniFile(iniFile:File):void
        {
            var iniText:String = "";
            const stream:FileStream = new FileStream();
            try
            {
                stream.open(iniFile, FileMode.READ);
                iniText = stream.readUTFBytes(stream.bytesAvailable);
                stream.close();
            }
            catch (readError:Error)
            {
                trace("settings.ini read failed: " + readError);
                return;
            }
            lastLoadedIniFileModificationTime = iniFile.modificationDate.time;

            const lineList:Array = iniText.split(/\r?\n/);
            for each (var line:String in lineList)
            {
                const trimmedLine:String = line.replace(/^\s+|\s+$/g, "");
                if (trimmedLine.length === 0 || trimmedLine.charAt(0) === ";" || trimmedLine.charAt(0) === "#")
                {
                    continue;
                }
                const separatorIndex:int = trimmedLine.indexOf("=");
                if (separatorIndex < 0)
                {
                    continue;
                }
                const key:String = trimmedLine.substring(0, separatorIndex).replace(/\s+$/g, "").toLowerCase();
                const value:String = trimmedLine.substring(separatorIndex + 1).replace(/^\s+/g, "").toLowerCase();
                if (key === KEY_LEFT_HANDED)
                {
                    isLeftHandedMouseCursor = (value === "true");
                }
            }
        }

        private static function writeSettingsToIniFile():void
        {
            const stream:FileStream = new FileStream();
            try
            {
                AppDataPaths.settingsFilePath.parent.createDirectory();
                stream.open(AppDataPaths.settingsFilePath, FileMode.WRITE);
                stream.writeUTFBytes(KEY_LEFT_HANDED + "=" + (isLeftHandedMouseCursor ? "true" : "false") + "\r\n");
                stream.close();
                lastLoadedIniFileModificationTime = getFreshIniFile().modificationDate.time;
            }
            catch (writeError:Error)
            {
                trace("settings.ini write failed: " + writeError);
            }
        }
    }
}
