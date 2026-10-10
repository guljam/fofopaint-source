package Modules.L4UI
{
    import Symbols.AboutWindowSet;

    import flash.events.MouseEvent;
    import flash.filesystem.File;
    import flash.geom.Rectangle;
    import flash.net.navigateToURL;
    import flash.net.URLRequest;
    import flash.utils.getTimer;
    import Modules.InputPriority;
    import Modules.L1Data.AppDataPaths;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L1Data.MouseState;
    import Modules.L1Data.Utils;

    // 층: L4 UI - 정보(About) 창 열기·닫기와 크기·위치
    public class AboutBoxController
    {
        // 로컬 매뉴얼 폴더를 열어야 한다는 보고
        public static var onLocalManualOpenedFunc:Function;
        // 버튼을 눌렀을 때의 클릭 처리(마우스를 뗀 곳이 같은 버튼이면 실행)를 시작해야 한다는 보고 (인자: 버튼 이름, 선택적으로 실행할 함수)
        public static var onButtonPressedFunc:Function;
        // 앱 초기화 전에 창 닫기·비활성화 리스너를 빼야 한다는 보고
        public static var onWindowListenersRemovedFunc:Function;

        // 드로우 모드의 입력 이벤트를 빼야 한다는 보고
        public static var onDrawEventsRemovedFunc:Function;
        // 드로우 모드의 입력 이벤트를 다시 달아야 한다는 보고
        public static var onDrawEventsAddedFunc:Function;
        // 캡처 모드의 입력 이벤트를 빼야 한다는 보고
        public static var onCaptureEventsRemovedFunc:Function;
        // 리플레이 모드의 입력 이벤트를 빼야 한다는 보고
        public static var onReplayEventsRemovedFunc:Function;

        public static var main:Main;

        public static function setMainInstance(instance:Main):void
        {
            main = instance;

            _aboutBox = new AboutWindowSet();
            _aboutBox.name = "aboutPanel";
            _aboutBox.setVersionInfo(main.APP_VERSION);
        }

        private static var _aboutBox:AboutWindowSet;
        private static var _isAboutBoxOpened:Boolean = false; // 어바웃 창 떴을때 킴
        public static const FOFOPAINT_RELEASE_NOTE_URL:String = "https://raw.githubusercontent.com/guljam/2020FlashPaint/master/releasenote.txt";
        public static const FOFOPAINT_GITHUB_URL:String = "https://github.com/guljam/2020FlashPaint";

        private static const driveUsageCalculationTimerName:String = "driveUsageCalculationTimer";

        public static function handlerMouseUpAboutBox(targetName:String):void
        {
            switch (targetName)
            {
                case "resetAppButton":
                    {
                        resetApp();
                        main.stage.nativeWindow.close();
                    }
                    break;
                case "versionInfo":
                case "releaseNoteButton":
                    navigateToURL(new URLRequest(FOFOPAINT_RELEASE_NOTE_URL));
                    break;
                case "aboutButton":
                    closeAboutBox();
                    break;
                case "aboutHomePageLink":
                    navigateToURL(new URLRequest(FOFOPAINT_GITHUB_URL));
                    break;
                case "aboutManualFolder":
                    if (onLocalManualOpenedFunc != null) onLocalManualOpenedFunc();
                    break;
                case "aboutErrorLogFolder":
                    AppDataPaths.openCrashLogFolder();
                    break;
                    // case "aboutMeLink":
                    // navigateToURL(new URLRequest("https://twitter.com/ninanoninini"));
                    // break;
                default:
                    closeAboutBox();
                    break;
            }
        }

        public static function get aboutBox():AboutWindowSet
        {
            return _aboutBox;
        }

        public static function setAboutBoxScale(scale:Number):void
        {
            _aboutBox.setScale(scale);
        }

        public static function setAboutBoxVisible(flag:Boolean):void
        {
            _aboutBox.visible = flag;
        }

        public static function set isAboutBoxOpened(flag:Boolean):void
        {
            _isAboutBoxOpened = flag;
        }

        public static function get isAboutBoxOpened():Boolean
        {
            return _isAboutBoxOpened;
        }

        public static function openAboutBox(welcome:Boolean):void
        {
            var stage:Object;

            Utils.setAsTopChild(_aboutBox);
            _isAboutBoxOpened = true;

            MouseState.isClickBlocked = true;
            HintController.hideBottomHint();

            if (onDrawEventsRemovedFunc != null) onDrawEventsRemovedFunc();

            if (welcome === true)
            {
                _aboutBox.resetAppButton.visible = false;

                FOFOTimer.addByName("openAboutPanelOFFTimer", 1.0, false, function ():void
                    {
                        main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onAboutWindowMouseDown, false, InputPriority.DEFAULT);
                    });
            }
            else
            {
                _aboutBox.resetAppButton.visible = true;

                AppUpdater.checkUpdate();
                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onAboutWindowMouseDown, false, InputPriority.DEFAULT);
            }

            _aboutBox.randomLogo();
            updateAboutPanelCenterPos();
            _aboutBox.visible = true;
        }

        public static function closeAboutBox():void
        {
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onAboutWindowMouseDown);

            if (onCaptureEventsRemovedFunc != null) onCaptureEventsRemovedFunc();
            if (onReplayEventsRemovedFunc != null) onReplayEventsRemovedFunc();
            if (onDrawEventsAddedFunc != null) onDrawEventsAddedFunc();

            isAboutBoxOpened = false;
            aboutBox.visible = false;
            FOFOTimer.remove(driveUsageCalculationTimerName);

            FOFOTimer.addByName("clickBlockTimer", 0.15, false, function ():void
                {
                    MouseState.isClickBlocked = false;
                });
        }

        private static function onAboutWindowMouseDown(e:MouseEvent):void
        {
            const targetName:String = e.target.name;

            switch (targetName)
            {
                case "appResetButton":
                case "versionInfo":
                case "releaseNoteButton":
                case "resetAppButton":
                case "aboutButton":
                case "aboutHomePageLink":
                case "aboutManualFolder":
                case "aboutErrorLogFolder":
                    // case "aboutMeLink":
                    if (onButtonPressedFunc != null) onButtonPressedFunc(targetName);
                    break;

                default:
                    closeAboutBox();
                    break;
            }
        }

        public static function resetApp():void
        {
            if (onWindowListenersRemovedFunc != null) onWindowListenersRemovedFunc();
            const files:File = File.applicationStorageDirectory;
            files.deleteDirectory(true);
        }

        public static function updateAboutPanelCenterPos():void
        {
            // 테두리가 원점 기준 대칭이 아니므로 실제 내용 범위의 중심을 기준으로 맞춤
            const localBounds:Rectangle = _aboutBox.getBounds(_aboutBox);
            _aboutBox.x = Math.floor(main.stage.stageWidth / 2) + Math.floor(-(localBounds.x + localBounds.width / 2) * _aboutBox.scaleX);
            _aboutBox.y = Math.floor((main.stage.stageHeight - 39) / 2) + Math.floor(-(localBounds.y + localBounds.height / 2) * _aboutBox.scaleY);
        }
    }
}
