package Modules
{
    import Modules.UIEngine.UITheme;
    import flash.desktop.Clipboard;
    import flash.desktop.ClipboardFormats;
    import flash.display.BitmapData;
    import flash.filesystem.File;
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.L5App.FileManager;
    import Modules.L4UI.LoadBoxController;
    import Modules.L5App.ReplayEngine.ReplayController;

    // 층: L3 기능 - 클립보드 이미지 불러오기
    public class ClipboardManager
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static var isClipBoardButtonActivated:Boolean = false;

        public static function tryLoadClipboardImage(toRefLayer:Boolean):void
        {
            if ((toRefLayer) ? FileManager.isRefLayerLoadBlocked() : FileManager.isFileLoadBlocked())
            {
                return;
            }

            ReplayDrawer.rFileStream.close();
            if (ReplayController.isReplayRestartTimerON())
            {
                ReplayController.cancelReplayRestartTimer();
            }

            const data:* = getSystemClipboardData();

            if (data)
            {
                if (data is BitmapData)
                {
                    LoadBoxController.prepareOpenLoadBox(false, toRefLayer, null, data as BitmapData, "clipboard");
                }
                else if (data is Array && data.length > 0)
                {
                    const file:File = data[0] as File;
                    if (LoadBoxController.canDisplayLoadMenuBox(file))
                    {
                        LoadBoxController.prepareLoadMenuBoxFromImageFile(file, toRefLayer);
                    }
                }
            }
        }

        private static function getSystemClipboardData():*
        {
            return Clipboard.generalClipboard.getData(ClipboardFormats.BITMAP_FORMAT)
                || Clipboard.generalClipboard.getData(ClipboardFormats.FILE_LIST_FORMAT);
        }

        // 상단 클립보드 버튼은 캔버스로 불러오기라서 worker 잠금 상태와 합쳐서 계산함
        private static function disableTopBarClipboardButton():void
        {
            ReferenceLayerController.refLayerMenuBox.refClipBoardButton.alpha = UITheme.OFFALPHA;
            isClipBoardButtonActivated = false;
            FileManager.refreshFileOperationButtonsTopbar();
        }

        private static function enableTopBarClipboardButton():void
        {
            ReferenceLayerController.refLayerMenuBox.refClipBoardButton.alpha = 1.0;
            isClipBoardButtonActivated = true;
            FileManager.refreshFileOperationButtonsTopbar();
        }

        public static function checkCanUseClipBoardButton():void
        {
            const data:* = getSystemClipboardData();

            if (data is BitmapData)
            {
                enableTopBarClipboardButton();
                return;
            }

            if (data is Array && data.length > 0)
            {
                FileManager.validateImageFile(data[0] as File,
                        function (type:String, file:File, bmpd:BitmapData):void
                        {
                            enableTopBarClipboardButton();
                        },
                        function ():void
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
