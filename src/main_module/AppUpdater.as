package main_module
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

    public final class AppUpdater
    {
        public static const FLAG_NO_UPDATE:int = 0;
        public static const FLAG_CHECKING_UPDATE:int = (1 << 0);
        public static const FLAG_UPDATE_READY:int = (1 << 1);
        public static const FLAG_NEED_UPDATE_MANUAL:int = (1 << 2);
        public static const UPDATE_VERSION_URL:String = "https://raw.githubusercontent.com/guljam/2020FlashPaint/master/versionInfo.txt";
        public static const UPDATE_FILE_URL:String = "https://github.com/guljam/2020FlashPaint/releases/download/update2/fofoPaint.air";
        public static const FOFOPAINT_GITHUB_URL:String = "https://github.com/guljam/2020FlashPaint";
        public static const FOFOPAINT_RELEASE_NOTE_URL:String = "https://raw.githubusercontent.com/guljam/2020FlashPaint/master/releasenote.txt";
        public static const UPDATE_MAX_DOWNLOAD_RETRY:int = 5;
        public static const UPDATE_RETRY_DELAY:Number = 3.0;
        public static var status:int = FLAG_NO_UPDATE; // 새버전 나왔을때 올려주는 플래그
        public static var newVersionStr:String = ""; // 새버전 문자열 저장

        public static const updateFilePath:File = File.applicationStorageDirectory.resolvePath("updateTmpFile.air");
        public static var isUpdatePendingAfterSaving:Boolean = false; // 업데이트 버튼 눌렀을 때 저장 후 대기 플래그

        public static function prepareUpdate():void
        {
            const main:Main = Main._instance;

            main.prepareOpenLoadBox(true, false, null, null, null);
            isUpdatePendingAfterSaving = true;
            main.openSaveFileBrowser(false);
        }

        public static function startUpdate():void
        {
            const main:Main = Main._instance;
            main.closeLoadMenuBox();
            isUpdatePendingAfterSaving = false;
            MainUI.topBar.hideUpdateButton();

            if (status === FLAG_UPDATE_READY)
            {
                FOFOTimer.add(0.5, false, function():void
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

        public static function installNewVersion():void
        {
            if (updateFilePath.exists)
            {
                var updater:Updater = new Updater();
                updater.update(updateFilePath, newVersionStr);
            }
        }

        public static function checkUpdate():void
        {
            if (status === FLAG_CHECKING_UPDATE)
            {
                return;
            }

            status = FLAG_CHECKING_UPDATE;

            var versionInfo:URLRequest = new URLRequest(UPDATE_VERSION_URL);
            var loader:URLLoader = new URLLoader();

            versionInfo.useCache = false;

            loader.addEventListener(Event.COMPLETE, onCompleteCheckVersion);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onErrorCheckVersion);
            loader.load(versionInfo);

            function onErrorCheckVersion(e:IOErrorEvent):void
            {
                status = FLAG_NO_UPDATE;
                loader.removeEventListener(Event.COMPLETE, onCompleteCheckVersion);
                loader.removeEventListener(IOErrorEvent.IO_ERROR, onErrorCheckVersion);
                loader = null;
            }

            function parseVersion(str:String):Number
            {
                return parseFloat(str);
            }

            function isNewVersion(newVersionArray:Array):Boolean
            {
                const main:Main = Main._instance;
                var current:Array = main.APP_VERSION.toFixed(2).split(".");

                var newMajor:Number = parseFloat(newVersionArray[0]);
                var newMinor:Number = parseFloat(newVersionArray[1]);
                var curMajor:Number = parseFloat(current[0]);
                var curMinor:Number = parseFloat(current[1]);

                return (newMajor > curMajor) || (newMajor === curMajor && newMinor > curMinor);
            }

            function onCompleteCheckVersion(e:Event):void
            {
                const versionStr:String = loader.data as String;
                if (!versionStr)
                {
                    return;
                }

                const versionArray:Array = versionStr.split(".");

                if (versionArray.length === 2)
                {
                    var tryCount:uint = 0;

                    const updateFile:URLRequest = new URLRequest(UPDATE_FILE_URL);
                    if (isNewVersion(versionArray))
                    {
                        newVersionStr = versionStr;
                        var fileLoader:URLLoader = e.target as URLLoader;

                        fileLoader.dataFormat = URLLoaderDataFormat.BINARY;
                        fileLoader.addEventListener(Event.COMPLETE, downloadSuccessEvent);
                        fileLoader.addEventListener(IOErrorEvent.IO_ERROR, downloadFailedEvent);

                        function onUpdateCheckFinished(updateState:int):void
                        {
                            fileLoader.removeEventListener(Event.COMPLETE, downloadSuccessEvent);
                            fileLoader.removeEventListener(IOErrorEvent.IO_ERROR, downloadFailedEvent);

                            status = updateState;
                            MainUI.topBar.showUpdateButton();
                        }

                        function downloadFailedEvent(e:Event):void
                        {
                            if (tryCount < 5)
                            {
                                FOFOTimer.addByName("updateRryTimer", 1.0, false, function():void
                                    {
                                        tryCount++;
                                        fileLoader.load(updateFile);
                                    });
                            }
                            else
                            {
                                onUpdateCheckFinished(FLAG_NEED_UPDATE_MANUAL);
                            }
                        }

                        function downloadSuccessEvent(e:Event):void
                        {
                            var fs:FileStream = new FileStream();
                            fs.open(updateFilePath, FileMode.WRITE);
                            fs.writeBytes(fileLoader.data);
                            fs.close();
                            onUpdateCheckFinished(FLAG_UPDATE_READY);
                        }

                        if (Updater.isSupported)
                        {
                            fileLoader.load(updateFile); // 다운로드를 시작함
                        }
                        else
                        {
                            onUpdateCheckFinished(FLAG_NEED_UPDATE_MANUAL);
                        }
                    }
                    else
                    {
                        status = FLAG_NO_UPDATE;
                        // 최신 버전이면 이미 다운로드한 파일 있는지 체크하고 제거
                        if (updateFilePath.exists)
                        {
                            updateFilePath.deleteFile();
                        }
                    }
                }
                else
                {
                    status = FLAG_NO_UPDATE;
                }
                loader.removeEventListener(Event.COMPLETE, onCompleteCheckVersion);
                loader.removeEventListener(IOErrorEvent.IO_ERROR, onErrorCheckVersion);
                loader = null;
            }
        }
    }
}
