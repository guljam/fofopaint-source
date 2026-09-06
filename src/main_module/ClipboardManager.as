package main_module
{
    import flash.desktop.Clipboard;
    import flash.desktop.ClipboardFormats;
    import flash.display.BitmapData;
    import flash.filesystem.File;

    public class ClipboardManager
    {
        public static var isClipBoardButtonActivated:Boolean = false;

        public static function tryLoadClipboardImage(toRefLayer:Boolean):void
        {
            const main:Main = Main._instance;

            if (main.isFileLoadBlocked())
            {
                return;
            }

            main.rFileStream.close();
            if (main.isReplayRestartTimerON())
            {
                main.cancelReplayRestartTimer();
            }

            const data:* = getSystemClipboardData();

            if (data)
            {
                if (data is BitmapData)
                {
                    main.prepareOpenLoadBox(false, toRefLayer, null, data as BitmapData, "clipboard");
                }
                else if (data is Array && data.length > 0)
                {
                    const file:File = data[0] as File;
                    if (main.canDisplayLoadMenuBox(file))
                    {
                        main.prepareLoadMenuBoxFromImageFile(file, toRefLayer);
                    }
                }
            }
        }

        public static function getSystemClipboardData():*
        {
            return Clipboard.generalClipboard.getData(ClipboardFormats.BITMAP_FORMAT)
                || Clipboard.generalClipboard.getData(ClipboardFormats.FILE_LIST_FORMAT);
        }

        public static function disableTopBarClipboardButton():void
        {
            const main:Main = Main._instance;
            MainUI.topBar.clipBoardButton.alpha = Global.OFFALPHA;
            main.refLayerMenuBox.refClipBoardButton.alpha = Global.OFFALPHA;
            isClipBoardButtonActivated = false;
        }

        public static function enableTopBarClipboardButton():void
        {
            const main:Main = Main._instance;
            MainUI.topBar.clipBoardButton.alpha = 1.0;
            main.refLayerMenuBox.refClipBoardButton.alpha = 1.0;
            isClipBoardButtonActivated = true;
        }

        public static function checkCanUseClipBoardButton():void
        {
            const main:Main = Main._instance;
            const data:* = getSystemClipboardData();

            if (data is BitmapData)
            {
                enableTopBarClipboardButton();
                return;
            }

            if (data is Array && data.length > 0)
            {
                main.validateImageFile(data[0] as File,
                        function(type:String, file:File, bmpd:BitmapData):void
                        {
                            enableTopBarClipboardButton();
                        },
                        function():void
                        {
                            disableTopBarClipboardButton();
                        });
            }
            else
            {
                disableTopBarClipboardButton();
            }
        }
    }
}
