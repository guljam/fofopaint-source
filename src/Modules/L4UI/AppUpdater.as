package Modules.L4UI
{
    import Modules.L1Data.AppContext;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.filesystem.File;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.navigateToURL;
    import Modules.L4UI.UIEngine.UIController;

    // GitHub의 versionInfo.txt로 새 버전이 있는지만 확인하고, 업데이트 버튼을 누르면 배포 사이트(GitHub 릴리스 페이지)를 엶
    // Windows bundle(captive runtime) 배포라 .air 내려받기와 flash.desktop.Updater 설치는 쓰지 않음
    // 층: L4 UI - GitHub의 새 버전 확인과 배포 사이트 열기
    public final class AppUpdater
    {
        private static const FLAG_NO_UPDATE:int = 0;
        private static const FLAG_CHECKING_UPDATE:int = (1 << 0);
        private static const FLAG_UPDATE_AVAILABLE:int = (1 << 1);
        private static const UPDATE_VERSION_URL:String = "https://raw.githubusercontent.com/guljam/2020FlashPaint/refs/heads/master/versionInfov2.txt"; // a.b.c 버전
        private static const UPDATE_VERSION_URL_LEGACY:String = "https://raw.githubusercontent.com/guljam/2020FlashPaint/refs/heads/master/versionInfo.txt"; // a.b 버전 (legacy 배포)
        private static const RELEASE_NOTE_URL:String = "https://raw.githubusercontent.com/guljam/2020FlashPaint/refs/heads/master/releasenotev2.txt";
        private static const RELEASE_PAGE_URL:String = "https://github.com/guljam/2020FlashPaint/releases";
        private static var status:int = FLAG_NO_UPDATE; // 새버전 나왔을때 올려주는 플래그
        public static var newVersionStr:String = "{VERSION}"; // 새버전 문자열 저장

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
        
        // 현재 버전이 a.b 형식(legacy 배포)이면 legacy 파일, a.b.c 형식이면 v2 파일을 봄
        private static function getVersionUrl():String
        {
            return (AppContext.appVersion.split(".").length === 2) ? UPDATE_VERSION_URL_LEGACY : UPDATE_VERSION_URL;
        }

        //gemini 생성 파일 a.b / a.b.c 형식비교, 현재 버전과 같은 형식끼리만 비교함
        private static function isNewVersion(newVersion:String):Boolean
        {
            if (!newVersion)
                return false;

            var currentStr:String = AppContext.appVersion;
            var current:Array = currentStr.split(".");
            var newVersionArray:Array = newVersion.split(".");

            // 현재 버전과 자리수가 같은 a.b 또는 a.b.c 형식인지 확인
            if (current.length < 2 || current.length > 3 || newVersionArray.length !== current.length)
            {
                return false;
            }

            var newMajor:int = parseInt(newVersionArray[0], 10);
            var newMinor:int = parseInt(newVersionArray[1], 10);
            var newPatch:int = (newVersionArray.length === 3) ? parseInt(newVersionArray[2], 10) : 0;

            var curMajor:int = parseInt(current[0], 10);
            var curMinor:int = parseInt(current[1], 10);
            var curPatch:int = (current.length === 3) ? parseInt(current[2], 10) : 0;

            // NaN 체크
            if (isNaN(newMajor) || isNaN(newMinor) || isNaN(newPatch) ||
                    isNaN(curMajor) || isNaN(curMinor) || isNaN(curPatch))
            {
                return false;
            }

            // 1. Major 비교
            if (newMajor !== curMajor)
            {
                return newMajor > curMajor;
            }

            // 2. Minor 비교
            if (newMinor !== curMinor)
            {
                return newMinor > curMinor;
            }

            // 3. Patch 비교
            return newPatch > curPatch;
        }

        private static function getVersionFileFromGithub(onComplete:Function):void
        {
            var request:URLRequest = new URLRequest(getVersionUrl());
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
    }
}
