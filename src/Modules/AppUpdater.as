package Modules
{
    import flash.filesystem.File;
    import flash.net.navigateToURL;
    import flash.net.URLRequest;
    import flash.desktop.Updater;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.filesystem.FileStream;
    import flash.filesystem.FileMode;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.utils.ByteArray;

    public final class AppUpdater
    {
        private static const FLAG_NO_UPDATE:int = 0;
        private static const FLAG_CHECKING_UPDATE:int = (1 << 0);
        private static const FLAG_UPDATE_READY:int = (1 << 1);
        private static const FLAG_NEED_UPDATE_MANUAL:int = (1 << 2);
        private static const UPDATE_VERSION_URL:String = "https://raw.githubusercontent.com/guljam/2020FlashPaint/master/versionInfo.txt";
        private static const UPDATE_FILE_URL:String = "https://github.com/guljam/2020FlashPaint/releases/download/update2/fofoPaint.air";
        private static const FOFOPAINT_GITHUB_URL:String = "https://github.com/guljam/2020FlashPaint";
        private static const FOFOPAINT_RELEASE_NOTE_URL:String = "https://raw.githubusercontent.com/guljam/2020FlashPaint/master/releasenote.txt";
        private static const UPDATE_MAX_DOWNLOAD_RETRY:int = 5;
        private static const UPDATE_RETRY_DELAY:Number = 3.0;
        private static var status:int = FLAG_NO_UPDATE; // 새버전 나왔을때 올려주는 플래그
        public static var newVersionStr:String = ""; // 새버전 문자열 저장

        private static const updateFilePath:File = File.applicationStorageDirectory.resolvePath("updateTmpFile.air");
        public static var isUpdatePendingAfterSaving:Boolean = false; // 업데이트 버튼 눌렀을 때 저장 후 대기 플래그

        public static function needUpdate():Boolean
        {
            return status !== FLAG_NO_UPDATE;
        }

        public static function prepareUpdate():void
        {
            const main:Main = Main._instance;

            FileManager.prepareOpenLoadBox(true, false, null, null, null);
            isUpdatePendingAfterSaving = true;
            FileManager.openSaveFileBrowser(false);
        }

        public static function startUpdate():void
        {
            const main:Main = Main._instance;
            FileManager.closeLoadMenuBox();
            isUpdatePendingAfterSaving = false;
            MainUI.topBar.hideUpdateButton();

            if (status === FLAG_UPDATE_READY)
            {
                FOFOTimer.add(0.5, false, function ():void
                    {
                        installNewVersion();
                    });
            }
            else if (status === FLAG_NEED_UPDATE_MANUAL)
            {
                navigateToURL(new URLRequest(FOFOPAINT_GITHUB_URL));
            }
            navigateToURL(new URLRequest(FOFOPAINT_RELEASE_NOTE_URL));
        }

        private static function installNewVersion():void
        {
            try
            {
                if (updateFilePath.exists)
                {
                    var updater:Updater = new Updater();
                    updater.update(updateFilePath, newVersionStr);
                }
            }
            catch (err)
            {
                MainUI.showMouseHintTemp("Skip update (debub mode)");
            }
        }
        private static function isNewVersion(newVersion:String):Boolean
        {
            var currentStr:String = Main._instance.APP_VERSION; // 또는 APP_VERSION.toString()
            var current:Array = currentStr.split(".");
            const newVersionArray:Array = newVersion.split(".");

            // 최소 2자리인지 확인
            if (newVersionArray.length < 2 || current.length < 2)
            {
                return false;
            }

            var newMajor:int = parseInt(newVersionArray[0], 10);
            var newMinor:int = parseInt(newVersionArray[1], 10);
            var curMajor:int = parseInt(current[0], 10);
            var curMinor:int = parseInt(current[1], 10);

            // NaN 체크
            if (isNaN(newMajor) || isNaN(newMinor) || isNaN(curMajor) || isNaN(curMinor))
            {
                return false;
            }

            if (newMajor > curMajor)
                return true;
            if (newMajor < curMajor)
                return false;

            // major가 같으면 minor 비교
            return newMinor > curMinor;
        }

        private static function getVersionFileFromGithub(onComplete:Function):void
        {
            var request:URLRequest = new URLRequest(UPDATE_VERSION_URL);
            request.useCache = false;

            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onCompleteHandler);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onErrorHandler);
            loader.load(request);

            function onCompleteHandler(e:Event):void
            {
                const versionStr:String = loader.data as String;
                cleanup();
                onComplete(versionStr);
            }

            function onErrorHandler(e:IOErrorEvent):void
            {
                cleanup();
                onComplete(null); // 실패는 null로 통일
            }

            function cleanup():void
            {
                loader.removeEventListener(Event.COMPLETE, onCompleteHandler);
                loader.removeEventListener(IOErrorEvent.IO_ERROR, onErrorHandler);
                loader = null;
            }
        }

        private static function tryUpdate(versionStr:String):void
        {
            if (!isNewVersion(versionStr))
            {
                status = FLAG_NO_UPDATE;

                // 최신 버전이면 이미 받아놓은 업데이트 파일 삭제
                if (updateFilePath.exists)
                {
                    updateFilePath.deleteFile();
                }
                return;
            }

            // 3. 여기부터 실제 업데이트가 필요한 경우
            newVersionStr = versionStr;

            var tryCount:uint = 0;
            var fileLoader:URLLoader = new URLLoader();
            const updateRequest:URLRequest = new URLRequest(UPDATE_FILE_URL);

            fileLoader.dataFormat = URLLoaderDataFormat.BINARY;
            fileLoader.addEventListener(Event.COMPLETE, onDownloadSuccess);
            fileLoader.addEventListener(IOErrorEvent.IO_ERROR, onDownloadFailed);

            function onUpdateFinished(updateState:int):void
            {
                fileLoader.removeEventListener(Event.COMPLETE, onDownloadSuccess);
                fileLoader.removeEventListener(IOErrorEvent.IO_ERROR, onDownloadFailed);
                fileLoader = null;

                status = updateState;
                MainUI.topBar.showUpdateButton();
            }

            function onDownloadFailed(e:Event):void
            {
                if (tryCount < 5)
                {
                    FOFOTimer.addByName("updateRetryTimer", 2.0, false, function ():void
                        {
                            tryCount++;
                            fileLoader.load(updateRequest);
                        });
                }
                else
                {
                    onUpdateFinished(FLAG_NEED_UPDATE_MANUAL);
                }
            }

            function onDownloadSuccess(e:Event):void
            {
                var fs:FileStream = new FileStream();
                fs.open(updateFilePath, FileMode.WRITE);
                fs.writeBytes(fileLoader.data as ByteArray);
                fs.close();

                onUpdateFinished(FLAG_UPDATE_READY);
            }

            // 4. 실제 다운로드 시작 여부
            if (Updater.isSupported)
            {
                fileLoader.load(updateRequest);
            }
            else
            {
                onUpdateFinished(FLAG_NEED_UPDATE_MANUAL);
            }
        }

        public static function checkUpdate():void
        {
            if (status === FLAG_CHECKING_UPDATE)
                return;

            status = FLAG_CHECKING_UPDATE;

            getVersionFileFromGithub(function (versionStr:String):void
                {
                    if (!versionStr)
                    {
                        status = FLAG_NO_UPDATE;
                        return;
                    }

                    tryUpdate(versionStr);
                });
        }
    }
}
