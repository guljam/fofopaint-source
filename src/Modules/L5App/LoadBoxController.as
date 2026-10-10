package Modules.L5App
{
    import Modules.L1Data.AppContext;


    import flash.display.BitmapData;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.utils.ByteArray;

    import libwebp.DecodeWebp;
    import Modules.L5App.FileManager;
    import Modules.L5App.ReplayEngine.ReplayController;
    import Modules.L4UI.Tools.ToolPanel;
    import Modules.L1Data.KeyState;
    import Modules.L2Engine.BackgroundWorkerCoordinator;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L1Data.ToolState;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L2Engine.ReplayEngine.ReplayState;
    import Modules.L1Data.Utils;
    import Modules.L4UI.Tools.LassoTool;
    import Modules.L4UI.Tools.ToolController;
    import Modules.L4UI.CaptureEngine.CaptureController;
    import Modules.L4UI.ReferenceLayerController;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L1Data.InputPriority;

    // 불러오기 메뉴(로드박스)의 열기/닫기, 버튼 처리, 불러올 이미지/파일 보관, 확정 시 실제 불러오기 호출을 담당함
    // 층: L5 앱 흐름 - 불러오기 메뉴(로드박스) 열기·닫기와 버튼 처리
    public class LoadBoxController
    {
        public static var isLoadPendingAfterSaving:Boolean = false;
        public static var lastLoadedFile:File; // invoke나 파일 드래그 드롭했을때 저장해줘서 같은 파일을 다시 열지 않게 함
        private static var loadMenuBoxBitmapData:BitmapData;
        private static var loadMenuBoxFileType:String;
        private static var loadMenuBoxFile:File;

        public static function closeLoadMenuBox():void
        {
            AppContext.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownLoadMenuBox);
            UIController.loadMenuBox.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownLoadMenuBox);
            UIController.loadMenuBox.visible = false;
        }

        public static function openLoadMenuBoxOnClosing():void
        {
            if (UIController.loadMenuBox.visible === false)
            {
                const bmpd:BitmapData = DrawCanvas.getMergedBitmapData(false, true, true, null);
                UIController.loadMenuBox.setPreviewImage(bmpd);

                // 줄인 복사본을 배경으로 썼으면 합성 이미지는 필요 없음
                if (!UIController.loadMenuBox.isPreviewImage(bmpd))
                {
                    bmpd.dispose();
                }

                UIController.loadMenuBox.showPleaseWaitTextOrCustomText("Closing fofo paint...");
                UIController.loadMenuBox.updateClickBlockerSize(AppContext.stage.stageWidth, AppContext.stage.stageHeight);
                Utils.setAsTopChild(UIController.loadMenuBox);
                UIController.loadMenuBox.visible = true;
            }
        }

        public static function openLoadMenuBox():void
        {
            if (UIController.loadMenuBox.visible === false)
            {
                AppContext.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownLoadMenuBox, false, InputPriority.DEFAULT);
                UIController.loadMenuBox.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownLoadMenuBox);
                UIController.loadMenuBox.visible = true;
            }
            UIController.loadMenuBox.updateClickBlockerSize(AppContext.stage.stageWidth, AppContext.stage.stageHeight);
            Utils.setAsTopChild(UIController.loadMenuBox);
        }

        private static function handleLoadMenuBoxClick(oldTargetName:String):void
        {
            UIController.loadMenuBox.addEventListener(MouseEvent.MOUSE_UP, onMouseUpLoadMenuBox);
            function onMouseUpLoadMenuBox(e:MouseEvent):void
            {
                UIController.loadMenuBox.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpLoadMenuBox);
                if (!e.target || e.target.alpha < 1.0)
                {
                    return;
                }
                if (oldTargetName === e.target.name
                        && isLoadPendingAfterSaving === false && BackgroundWorkerCoordinator.isSaveInProgress === 0 && !UIController.isFileBrowserOpened)
                {
                    switch (e.target.name)
                    {
                        case "dragDropLoadButton":
                            {
                                if (!UIController.loadMenuBox.isRefLayerLoadMode())
                                {
                                    if (FileManager.isReplayDataLocked())
                                    {
                                        // worker 작업이 끝나면 stopWorkerIfIdle에서 불러옴
                                        isLoadPendingAfterSaving = true;
                                        UIController.loadMenuBox.showPleaseWaitTextOrCustomText("Waiting for background tasks...");
                                        return;
                                    }
                                    closeLoadMenuBox();
                                    loadFileTo("canvas");
                                }
                            }
                            break;
                        case "dragDropSaveAndLoadButton":
                            {
                                if (!UIController.loadMenuBox.isRefLayerLoadMode())
                                {
                                    isLoadPendingAfterSaving = true;
                                    UIController.loadMenuBox.showPleaseWaitTextOrCustomText("Saving in progress...");
                                    FileManager.openSaveFileBrowser(false);
                                }
                            }
                            break;
                        case "dragDropLoadRefLayerButton":
                            {
                                loadFileTo("reflayer");
                                closeLoadMenuBox();
                            }
                            break;
                        case "dragDropCancelButton":
                            {
                                closeLoadMenuBox();
                                releaseLoadMenuBoxBitmapData(true);
                            }
                            break;
                    }
                }
            }
        }

        private static function onMouseDownLoadMenuBox(e:MouseEvent):void
        {
            if (!e.target)
            {
                return;
            }
            handleLoadMenuBoxClick(e.target.name);
        }

        public static function showLoadFaildMouseHint():void
        {
            isLoadPendingAfterSaving = false;
            HintController.showMouseHintTemp("Load failed");
            HintController.mouseHint.y = AppContext.stage.mouseY;
            HintController.mouseHint.x = AppContext.stage.mouseX;
        }

        private static function keyDownLoadMenuBox(e:KeyboardEvent):void
        {
            const firstKey:uint = KeyState.getFirstPressedKey();
            if (firstKey === KeyState.KEY.esc || firstKey === KeyState.KEY.backspace)
            {
                // 캐시 이미지를 만드는 중이면 멈추고 새 파일로 초기화함
                if (ReplayState.isGeneratingCacheImages())
                {
                    ReplayController.cancelGeneratingReplayCacheImageAndCreateNewFile();
                    return;
                }
                closeLoadMenuBox();

                // 저장 후 불러오기 대기중이거나 캐시 이미지를 만드는 중이면 이미지가 아직 필요함
                if (!isLoadPendingAfterSaving && BackgroundWorkerCoordinator.isSaveInProgress === 0 && !ReplayState.isGeneratingCacheImages())
                {
                    releaseLoadMenuBoxBitmapData(true);
                }
            }
        }

        // 불러오기 메뉴에 쓰던 이미지를 해제함
        // 로드박스 배경으로 그대로 쓰고 있으면 clearPreview가 true일때만 배경까지 해제하고, false면 배경으로 남겨둠
        private static function releaseLoadMenuBoxBitmapData(clearPreview:Boolean):void
        {
            if (loadMenuBoxBitmapData === null)
            {
                return;
            }

            if (UIController.loadMenuBox.isPreviewImage(loadMenuBoxBitmapData))
            {
                if (clearPreview)
                {
                    UIController.loadMenuBox.clearPreviewImage();
                }
            }
            else
            {
                loadMenuBoxBitmapData.dispose();
            }

            loadMenuBoxBitmapData = null;
        }

        public static function prepareOpenLoadBox(fromUpdate:Boolean, reflayermenu:Boolean, file:File, bmpd:BitmapData, filetype:String):void
        {
            KeyState.clearKeyBuffer();
            ToolPanel.closeToolBox2();
            loadMenuBoxFileType = filetype;
            loadMenuBoxFile = file;

            // 이전에 불러오려던 이미지가 남아있으면 해제 (배경으로 쓰던건 setPreviewImage에서 해제됨)
            if (loadMenuBoxBitmapData !== bmpd)
            {
                releaseLoadMenuBoxBitmapData(false);
            }

            loadMenuBoxBitmapData = bmpd;

            if (LassoTool.isStarted === true)
            {
                LassoTool.cancelLassoTool();
                ToolState.resetLastTool();
                ToolController.selectPenTool();
            }

            if (bmpd)
            {
                UIController.loadMenuBox.setPreviewImage(bmpd);
                UIController.loadMenuBox.updateClickBlockerSize(AppContext.stage.stageWidth, AppContext.stage.stageHeight);
            }
            if (UIController.loadMenuBox.visible === false)
            {
                UIController.loadMenuBox.updateUIColor();
                if (fromUpdate)
                {
                    UIController.loadMenuBox.showPleaseWaitTextOrCustomText("Waiting for the file to be saved");
                }
                else
                {
                    UIController.loadMenuBox.hidePleaseWait();
                    if (reflayermenu)
                    {
                        UIController.loadMenuBox.activateReflayerButtonOnly();
                    }
                    else
                    {
                        UIController.loadMenuBox.activateAllButtons();
                    }
                }
                openLoadMenuBox();
            }
        }

        public static function canDisplayLoadMenuBox(file:File):Boolean
        {
            return !UIController.loadMenuBox.visible || !isSameFile(file, lastLoadedFile);
        }

        public static function prepareLoadMenuBoxFromImageFile(file:File, toRefLayer:Boolean):void
        {
            FileManager.validateImageFile(file,
                    function (type:String, file:File, bmpd:BitmapData):void
                    {
                        lastLoadedFile = file;
                        if (type === "image")
                        {
                            prepareOpenLoadBox(false, toRefLayer, file, bmpd, "image");
                        }
                        else if (type === "2020")
                        {
                            prepareOpenLoadBox(false, toRefLayer, file, FileManager.getFinalBitmapDataFrom2020File(file, true), "2020");
                        }
                        else if (type === "webp")
                        {
                            var byteArray:ByteArray = new ByteArray();
                            var stream:FileStream = new FileStream();
                            stream.open(file, FileMode.READ);
                            stream.readBytes(byteArray, 0, stream.bytesAvailable);
                            stream.close();
                            prepareOpenLoadBox(false, toRefLayer, file, libwebp.DecodeWebp(byteArray), "webp");
                        }
                    }, showLoadFaildMouseHint);
        }

        private static function isSameFile(file1:File, file2:File):Boolean
        {
            if (!lastLoadedFile)
            {
                return false;
            }
            return file1.nativePath === file2.nativePath
                && file1.size === file2.size
                && file1.modificationDate.getTime() === file2.modificationDate.getTime()
                && file1.creationDate.getTime() === file2.creationDate.getTime();
        }

        public static function loadFileTo(where:String):void
        {
            if (where !== "reflayer" && FileManager.isReplayDataLocked())
            {
                // worker 작업이 끝나면 stopWorkerIfIdle에서 다시 불러옴
                isLoadPendingAfterSaving = true;
                return;
            }
            if (where === "reflayer")
            {
                if (loadMenuBoxBitmapData)
                {
                    ReferenceLayerController.transferLoadedImageToRefLayer(loadMenuBoxBitmapData, loadMenuBoxBitmapData.width, loadMenuBoxBitmapData.height);
                    if (!ReplayState.isReplayModeON && !CaptureController.isCaptureModeON)
                    {
                        ReferenceLayerController.openRefLayerMenu();
                    }
                    releaseLoadMenuBoxBitmapData(true);
                }
            }
            else if (loadMenuBoxFile !== null)
            {
                if (loadMenuBoxFile.exists)
                {
                    if (loadMenuBoxFileType === "2020")
                    {
                        var fs:FileStream = new FileStream();
                        function onCompleteFileStream(e:Event):void
                        {
                            fs.removeEventListener(Event.COMPLETE, onCompleteFileStream);
                            fs.removeEventListener(IOErrorEvent.IO_ERROR, onErrorFileStream);
                            fs.close();
                            fs = null;
                            // 비동기로 파일을 여는 사이에 worker가 시작되었을 수 있음
                            if (FileManager.isReplayDataLocked())
                            {
                                isLoadPendingAfterSaving = true;
                                return;
                            }
                            FileManager.lastSaveFileName = loadMenuBoxFile.name;
                            FileManager.lastSaveFilePath = loadMenuBoxFile.nativePath;
                            FileManager.enterDrawModeOnLoadFile();
                            FileManager.loadFOFOFile(loadMenuBoxFile);
                            loadMenuBoxFile = null;
                            // 캐시 이미지 만드는 동안 로드박스 배경으로 쓰므로 배경은 남겨둠
                            releaseLoadMenuBoxBitmapData(false);
                        }
                        function onErrorFileStream(e:Event):void
                        {
                            showLoadFaildMouseHint();
                            fs.removeEventListener(Event.COMPLETE, onCompleteFileStream);
                            fs.removeEventListener(IOErrorEvent.IO_ERROR, onErrorFileStream);
                            fs.close();
                            fs = null;
                            loadMenuBoxFile = null;
                        }
                        fs.addEventListener(Event.COMPLETE, onCompleteFileStream);
                        fs.addEventListener(IOErrorEvent.IO_ERROR, onErrorFileStream);
                        fs.openAsync(loadMenuBoxFile, FileMode.READ);
                    }
                    else if (loadMenuBoxFileType === "webp" || loadMenuBoxFileType === "image")
                    {
                        FileManager.enterDrawModeOnLoadFile();
                        FileManager.lastSaveFileName = loadMenuBoxFile.name;
                        FileManager.lastSaveFilePath = loadMenuBoxFile.nativePath;
                        FileManager.loadImageFile(loadMenuBoxBitmapData.width, loadMenuBoxBitmapData.height, loadMenuBoxBitmapData, null);
                        releaseLoadMenuBoxBitmapData(true);
                    }
                }
                else
                {
                    showLoadFaildMouseHint();
                }
            }
            else if (loadMenuBoxFileType === "clipboard")
            {
                FileManager.enterDrawModeOnLoadFile();
                FileManager.lastSaveFileName = FileManager.getRandomFileName();
                FileManager.loadImageFile(loadMenuBoxBitmapData.width, loadMenuBoxBitmapData.height, loadMenuBoxBitmapData, null);
                releaseLoadMenuBoxBitmapData(true);
            }
        }
    }
}
