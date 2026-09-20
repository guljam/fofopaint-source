package Modules
{
    import Symbols.AboutWindowSet;

    import flash.events.MouseEvent;
    import flash.events.Event;
    import flash.filesystem.File;

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
            MainUI.hideBottomHint();

            InputController.removeInputEventsDrawMode();

            if (welcome === true)
            {
                _aboutBox.resetAppButton.visible = false;

                FOFOTimer.addByName("openAboutPanelOFFTimer", 1.0, false, function ():void
                    {
                        main.stage.addEventListener(MouseEvent.MOUSE_DOWN, MainUIController.onAboutWindowMouseDown);
                    });
            }
            else
            {
                InputController.removeInputEventsDrawMode();
                _aboutBox.resetAppButton.visible = true;

                AppUpdater.checkUpdate();
                main.stage.addEventListener(MouseEvent.MOUSE_DOWN, MainUIController.onAboutWindowMouseDown);
            }

            _aboutBox.randomLogo();
            _aboutBox.updateMemoryInfo(FileManager.getDriveUsageString());

            updateAboutPanelCenterPos();
            _aboutBox.visible = true;
        }

        public static function closeAboutBox():void
        {
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, MainUIController.onAboutWindowMouseDown);

            InputController.removeInputEventCaptrueMode();
            InputController.removeInputEventsReplayMode();
            InputController.addInputEventsDrawMode();

            isAboutBoxOpened = false;
            aboutBox.visible = false;

            FOFOTimer.addByName("clickBlockTimer", 0.15, false, function ():void
                {
                    CanvasController.isMouseClickBlocked = false;
                });
        }

        public static function resetApp():void
        {
            main.stage.nativeWindow.removeEventListener(Event.CLOSING, FileManager.onWindowClosingEvent);
            main.stage.nativeWindow.removeEventListener(Event.DEACTIVATE, FileManager.onWindowDeactivate);
            const files:File = File.applicationStorageDirectory;
            files.deleteDirectory(true);
        }

        public static function updateAboutPanelCenterPos():void
        {
            _aboutBox.x = Math.floor(main.stage.stageWidth / 2) + Math.floor(-_aboutBox.width / 2);
            _aboutBox.y = Math.floor((main.stage.stageHeight - 39) / 2) + Math.floor(-_aboutBox.height / 2);
        }
    }
}
