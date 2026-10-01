package Modules
{
    import Modules.InputManager.InputManager;
    import Modules.InputManager.DrawModeInput;
    import Modules.InputManager.ReplayModeInput;
    import Modules.InputManager.CaptureModeInput;
    import Modules.UIEngine.HintController;
    import Symbols.AboutWindowSet;

    import flash.events.MouseEvent;
    import flash.events.Event;
    import flash.filesystem.File;
    import flash.geom.Rectangle;
    import flash.net.navigateToURL;
    import flash.net.URLRequest;
    import flash.utils.getTimer;

    public class AboutBoxController
    {
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
                    FileManager.openLocalManual();
                    break;
                case "aboutErrorLogFolder":
                    FileManager.openCrashLogFolder();
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

            CanvasController.isMouseClickBlocked = true;
            HintController.hideBottomHint();

            DrawModeInput.removeEvents();

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

            CaptureModeInput.removeEvents();
            ReplayModeInput.removeEvents();
            DrawModeInput.addEvents();

            isAboutBoxOpened = false;
            aboutBox.visible = false;
            FOFOTimer.remove(driveUsageCalculationTimerName);

            FOFOTimer.addByName("clickBlockTimer", 0.15, false, function ():void
                {
                    CanvasController.isMouseClickBlocked = false;
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
                    InputManager.handleMouseClickStage(targetName);
                    break;

                default:
                    closeAboutBox();
                    break;
            }
        }

        public static function resetApp():void
        {
            main.stage.nativeWindow.removeEventListener(Event.CLOSING, AppWindowState.onWindowClosingEvent);
            main.stage.nativeWindow.removeEventListener(Event.DEACTIVATE, AppWindowState.onWindowDeactivate);
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
