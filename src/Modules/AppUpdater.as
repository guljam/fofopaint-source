package Modules
{
    import Modules.UIEngine.UIController;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.filesystem.File;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.navigateToURL;

    // GitHub의 versionInfo.txt로 새 버전이 있는지만 확인하고, 업데이트 버튼을 누르면 배포 사이트(GitHub 릴리스 페이지)를 엶
    // Windows bundle(captive runtime) 배포라 .air 내려받기와 flash.desktop.Updater 설치는 쓰지 않음
    public final class AppUpdater
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static const FLAG_NO_UPDATE:int = 0;
        private static const FLAG_CHECKING_UPDATE:int = (1 << 0);
        private static const FLAG_UPDATE_AVAILABLE:int = (1 << 1);
        private static const UPDATE_VERSION_URL:String = "https://raw.githubusercontent.com/guljam/2020FlashPaint/master/versionInfo.txt";
        private static const RELEASE_PAGE_URL:String = "https://github.com/guljam/2020FlashPaint/releases/latest";
        private static var status:int = FLAG_NO_UPDATE; // 새버전 나왔을때 올려주는 플래그
        public static var newVersionStr:String = ""; // 새버전 문자열 저장

        public static function needUpdate():Boolean
        {
            return status === FLAG_UPDATE_AVAILABLE;
        }

        // 업데이트 버튼
        public static function openReleasePage():void
        {
            UIController.topBar.hideUpdateButton();
            navigateToURL(new URLRequest(RELEASE_PAGE_URL));
        }

        private static function isNewVersion(newVersion:String):Boolean
        {
            var currentStr:String = main.APP_VERSION; // 또는 APP_VERSION.toString()
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

        public static function checkUpdate():void
        {
            if (status === FLAG_CHECKING_UPDATE)
                return;

            status = FLAG_CHECKING_UPDATE;
            deleteOldUpdateFile();

            getVersionFileFromGithub(function (versionStr:String):void
                {
                    if (!versionStr || !isNewVersion(versionStr))
                    {
                        status = FLAG_NO_UPDATE;
                        return;
                    }

                    newVersionStr = versionStr;
                    status = FLAG_UPDATE_AVAILABLE;
                    UIController.topBar.showUpdateButton();
                });
        }

        // 이전 버전의 .air 자동 업데이트가 받아두었던 파일이 남아있으면 지움
        private static function deleteOldUpdateFile():void
        {
            try
            {
                const oldFile:File = File.applicationStorageDirectory.resolvePath("updateTmpFile.air");

                if (oldFile.exists)
                {
                    oldFile.deleteFile();
                }
            }
            catch (error:Error)
            {
                trace("Old update file delete failed: " + error);
            }
        }
    }
}
