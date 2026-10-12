package Modules.L1Data
{
    import flash.events.ErrorEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;

    // 앱 데이터 폴더(portable_<버전>) 안의 파일 경로 모음, 크래시 로그 쓰기와 여는 함수, 앱 데이터를 불러오는 중인지 여부
    // 층: L1 데이터 - 앱 데이터 파일 경로 모음, 크래시 로그, 불러오는 중 플래그
    public class AppDataPaths
    {
        private static var dataFolderPath:File;

        private static var isWritingCrashLog:Boolean = false;

        public static var appStateFilePath:File;

        public static var scratchPadDataFilePath:File;

        public static var undoDataFilePath:File;

        public static var myPaletteDataFilePath:File;

        public static var replayDataFilePath:File;

        public static var replayTimingSheetFilePath:File; // repdata 프레임마다의 시간 간격 (TimingSheetFile)

        public static var replayTimingLegacyFilePath:File; // 타이밍 기록이 없는 옛 프레임 수 L (TimingSheetFile). 바뀔 때마다 바로 씀

        public static var replayTimingIndexFilePath:File; // 시계 시간 색인 요약 (ReplayClock). 앱 상태 저장 때 쓰고 시작할 때 읽음

        public static var replayTimingPointsFilePath:File; // 점마다 시각이 필요한 명령(line4)의 점별 시각 (TimingSheetFile)

        public static var replayCacheImageFolderPath:File;

        public static var replayCacheImageTempFolderPath:File; // worker가 캐시 이미지를 쓰는 곳, main이 확인 후 imagecache로 옮김

        // 불러오기 캐시 네이티브 작업이 쓰는 곳, main이 앞 번호부터 확인해서 imagecache로 옮김
        // undo 캐시 임시 폴더(prepareCacheTempFolder가 안의 파일을 다 지움)와 섞이지 않게 따로 둠
        public static var replayCacheImageLoadTempFolderPath:File;

        public static var replayCacheImageFrameDataFilePath:File;

        public static var replayCacheProgressFilePath:File; // 캐시 이미지 만드는 도중 앱을 닫았을때 이어서 만들기 위한 진행 기록

        public static var replayCachePreviewFilePath:File; // 그때 로드박스에 깔려있던 흐린 배경 이미지

        public static var isLoadingAppData:Boolean = false;

        // 앱 데이터 폴더(portable_<버전>)와 그 안의 파일 경로를 정함 (AppStateManager.initialize에서 부름)
        public static function initialize(appStateVersion:String):void
        {
            dataFolderPath = File.applicationStorageDirectory.resolvePath("portable_"+appStateVersion);
            appStateFilePath = dataFolderPath.resolvePath("appstate" + appStateVersion);
            scratchPadDataFilePath = dataFolderPath.resolvePath("scratchdata");
            undoDataFilePath = dataFolderPath.resolvePath("undodata");
            myPaletteDataFilePath = dataFolderPath.resolvePath("mypalettedata");
            replayDataFilePath = dataFolderPath.resolvePath("repdata");
            replayTimingSheetFilePath = dataFolderPath.resolvePath("reptimingsheet");
            replayTimingPointsFilePath = dataFolderPath.resolvePath("reptimingpoints");
            replayTimingIndexFilePath = dataFolderPath.resolvePath("reptimingindex");
            replayTimingLegacyFilePath = dataFolderPath.resolvePath("reptiminglegacy");
            replayCacheImageFolderPath = dataFolderPath.resolvePath("imagecache");
            replayCacheImageTempFolderPath = dataFolderPath.resolvePath("imagecache_tmp");
            replayCacheImageLoadTempFolderPath = dataFolderPath.resolvePath("imagecache_loadtmp");
            replayCacheImageFrameDataFilePath = dataFolderPath.resolvePath("jumpframedata");
            replayCacheProgressFilePath = dataFolderPath.resolvePath("imagecacheprogress");
            replayCachePreviewFilePath = dataFolderPath.resolvePath("imagecachepreview");
        }

        // 에러 내용을 데이터 폴더\log\ 의 날짜별 파일에 덧붙여 씀 (쓰는 중에 다시 불리면 무시함)
        public static function writeCrashLog(errorObject:*):void
        {
            if (isWritingCrashLog || dataFolderPath === null)
            {
                return;
            }

            isWritingCrashLog = true;
            var stream:FileStream;
            try
            {
                const now:Date = new Date();
                var dateKey:String = String(now.fullYear);
                if (now.month + 1 < 10)
                    dateKey += "0";
                dateKey += String(now.month + 1);
                if (now.date < 10)
                    dateKey += "0";
                dateKey += String(now.date);

                const logFolder:File = dataFolderPath.resolvePath("log");
                logFolder.createDirectory();
                const logFile:File = logFolder.resolvePath("fofo_error_log_" + dateKey + ".txt");
                var logText:String = "[" + now.toString() + "]\r\n";

                if (errorObject is Error)
                {
                    const runtimeError:Error = errorObject as Error;
                    logText += runtimeError.toString() + "\r\n";
                    logText += "Message: " + runtimeError.message + "\r\n";
                    logText += "Error ID: " + runtimeError.errorID + "\r\n";
                    const stack:String = runtimeError.getStackTrace();
                    logText += "Stack trace:\r\n" + (stack ? stack : "(unavailable)") + "\r\n";
                }
                else if (errorObject is ErrorEvent)
                {
                    const errorEvent:ErrorEvent = errorObject as ErrorEvent;
                    logText += errorEvent.toString() + "\r\n";
                    logText += "Message: " + errorEvent.text + "\r\n";
                    logText += "Error ID: " + errorEvent.errorID + "\r\n";
                    logText += "Stack trace: (unavailable for ErrorEvent)\r\n";
                }
                else
                {
                    logText += "Thrown value: " + String(errorObject) + "\r\n";
                    logText += "Stack trace: (unavailable)\r\n";
                }
                logText += "\r\n";

                stream = new FileStream();
                stream.open(logFile, FileMode.APPEND);
                stream.writeUTFBytes(logText);
            }
            catch (writeError:Error)
            {
                trace("Crash log write failed: " + writeError);
            }
            finally
            {
                if (stream !== null)
                {
                    try
                    {
                        stream.close();
                    }
                    catch (closeError:Error)
                    {
                        trace("Crash log close failed: " + closeError);
                    }
                }
                isWritingCrashLog = false;
            }
        }

        // 앱데이터\버전\log 폴더를 탐색기로 염, 크래시가 없어서 폴더가 없으면 만들어서 엶
        public static function openCrashLogFolder():void
        {
            if (dataFolderPath === null)
            {
                return;
            }

            const logFolder:File = dataFolderPath.resolvePath("log");
            try
            {
                if (!logFolder.exists)
                {
                    logFolder.createDirectory();
                }
                logFolder.openWithDefaultApplication();
            }
            catch (error:Error)
            {
                trace("Open crash log folder failed: " + error);
            }
        }

    }
}
