package Modules
{
    import Modules.Tools.PenSettings;
    import Modules.Tools.ToolPanel;
    import Modules.Tools.ToolController;
    import Modules.DrawEngine.CanvasView;
    import Modules.DrawEngine.DrawCanvas;
    import Modules.DrawEngine.CanvasLayers;
    import Modules.UIEngine.CanvasNavigator;
    import Modules.DrawEngine.CanvasResizer;
    import Modules.UIEngine.UIController;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UITheme;
    import Modules.CaptureEngine.CaptureStamp;
    import Modules.CaptureEngine.CaptureController;
    import Modules.Tools.PenTool;

    import flash.display.BitmapData;
    import flash.events.ErrorEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayDrawCommands;
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.ReplayEngine.ReplayFileCache;
    import Modules.ReplayEngine.ReplayState;
    import Modules.ReplayEngine.ReplaySaveMetaData;
    import flash.trace.Trace;

    public class AppStateManager
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
            dataFolderPath = File.applicationStorageDirectory.resolvePath(main.APP_STATE_VERSION);
            appStateFilePath = dataFolderPath.resolvePath("appstate" + main.APP_STATE_VERSION);
            scratchPadDataFilePath = dataFolderPath.resolvePath("scratchdata");
            undoDataFilePath = dataFolderPath.resolvePath("undodata");
            myPaletteDataFilePath = dataFolderPath.resolvePath("mypalettedata");
            replayDataFilePath = dataFolderPath.resolvePath("repdata");
            replayCacheImageFolderPath = dataFolderPath.resolvePath("imagecache");
            replayCacheImageTempFolderPath = dataFolderPath.resolvePath("imagecache_tmp");
            replayCacheImageFrameDataFilePath = dataFolderPath.resolvePath("jumpframedata");
            replayCacheProgressFilePath = dataFolderPath.resolvePath("imagecacheprogress");
            replayCachePreviewFilePath = dataFolderPath.resolvePath("imagecachepreview");
        }

        private static var dataFolderPath:File;
        private static var isWritingCrashLog:Boolean = false;
        public static var appStateFilePath:File;
        public static var scratchPadDataFilePath:File;
        public static var undoDataFilePath:File;
        public static var myPaletteDataFilePath:File;
        public static var replayDataFilePath:File;
        public static var replayCacheImageFolderPath:File;
        public static var replayCacheImageTempFolderPath:File; // worker가 캐시 이미지를 쓰는 곳, main이 확인 후 imagecache로 옮김
        public static var replayCacheImageFrameDataFilePath:File;
        public static var replayCacheProgressFilePath:File; // 캐시 이미지 만드는 도중 앱을 닫았을때 이어서 만들기 위한 진행 기록
        public static var replayCachePreviewFilePath:File; // 그때 로드박스에 깔려있던 흐린 배경 이미지
        public static const appUpTimePath:File = File.applicationStorageDirectory.resolvePath("appuptime");

        public static var isLoadingAppData:Boolean = false;

        private static function loadAppUpTimeFromAppData():void
        {
            const fs:FileStream = new FileStream();

            if (appUpTimePath.exists)
            {
                fs.open(appUpTimePath, FileMode.READ);
                const appUpTime:int = fs.readInt();
                ActivityWorkTimer.updateAppUpTime(appUpTime);
                fs.close();
            }
        }

        public static function saveAppState():void
        {
            const appStateObject:AppStateVars = new AppStateVars();
            appStateObject.canvasZoomIndex = CanvasView.canvasZoomIndex;
            appStateObject.canvasZoomedMultiplier = (CaptureController.isCaptureModeON) ? CaptureController.drawModeCanvasStateForSaveAppState.z : CanvasView.canvasZoomMultiplier;

            appStateObject.canvasPanelX = (CaptureController.isCaptureModeON) ? CaptureController.drawModeCanvasStateForSaveAppState.px : CanvasView.canvasPanel.x;
            appStateObject.canvasPanelY = (CaptureController.isCaptureModeON) ? CaptureController.drawModeCanvasStateForSaveAppState.py : CanvasView.canvasPanel.y;

            appStateObject.canvasAnchorPointX = (CaptureController.isCaptureModeON) ? CaptureController.drawModeCanvasStateForSaveAppState.x : CanvasView.canvasAnchorPoint.x;
            appStateObject.canvasAnchorPointY = (CaptureController.isCaptureModeON) ? CaptureController.drawModeCanvasStateForSaveAppState.y : CanvasView.canvasAnchorPoint.y;
            appStateObject.canvasAnchorPointRotation = (CaptureController.isCaptureModeON) ? CaptureController.drawModeCanvasStateForSaveAppState.r : CanvasView.canvasAnchorPoint.rotation;

            appStateObject.penSmoothValue = PenSettings.penSmoothValue;
            appStateObject.penSmoothSlideValue = PenSettings.penSmoothSlideValue;
            appStateObject.penSmoothButtonX = ToolPanel.toolOptionsBox.penSmoothSliderCursor.x;

            appStateObject.penSize = PenSettings.penSize;
            appStateObject.penSizeIndex = PenSettings.penSizeIndex;
            appStateObject.penColor = PenTool.penColor;
            appStateObject.penAlpha = PenSettings.penAlpha;
            appStateObject.penIsSquare = PenSettings.penIsSquare;

            appStateObject.eraseSize = PenSettings.eraserSize;
            appStateObject.eraseSizeIndex = PenSettings.eraserSizeIndex;
            appStateObject.eraserIsSquare = PenSettings.eraserIsSquare;
            appStateObject.eraseAlpha = PenSettings.eraserAlpha;

            const windowBounds:Rectangle = main.stage.nativeWindow.bounds;
            appStateObject.stageNativeWindowX = windowBounds.x;
            appStateObject.stageNativeWindowY = windowBounds.y;
            appStateObject.stageNativeWindowWidth = windowBounds.width;
            appStateObject.stageNativeWindowHeight = windowBounds.height;

            appStateObject.saveFileName = FileManager.lastSaveFileName;
            appStateObject.lastWindowState = AppWindowState.lastAppWindowState;
            appStateObject.uiColorIndex = UITheme.getUIColorIndex();
            appStateObject.appRunningTime = ActivityWorkTimer.getRunningTime();

            appStateObject.refLayerLastAlpha = ReferenceLayerController.refLayerLastAlpha;
            appStateObject.refOpacityCursorX = ReferenceLayerController.refLayerMenuBox.refOpacityCursor.x;
            appStateObject.refLayerMenuDragXMoveSum = ReferenceLayerController.refLayerMenuDragXMoveSum;

            appStateObject.canvasRefLayerBitmapX = ReferenceLayerController.canvasRefLayerBitmap.x;
            appStateObject.canvasRefLayerBitmapY = ReferenceLayerController.canvasRefLayerBitmap.y;
            appStateObject.canvasRefLayerRotation = ReferenceLayerController.canvasRefLayer.rotation;
            appStateObject.canvasRefLayerScaleX = ReferenceLayerController.canvasRefLayer.scaleX;
            appStateObject.canvasRefLayerScaleY = ReferenceLayerController.canvasRefLayer.scaleY;

            appStateObject.refLayerMenuBox0 = ReferenceLayerController.refLayerMenuBox.x;
            appStateObject.refLayerMenuBox1 = ReferenceLayerController.refLayerMenuBox.y;

            appStateObject.isCanvasMirrored = DrawCanvas.mirrorON;

            appStateObject.gridValue = CanvasGridOverlay.gridGapMultiplier;
            appStateObject.hsvColorData0 = ColorPickerController.hsvColorData[0];
            appStateObject.gridDrawOffsetX = CanvasGridOverlay.gridDrawOffsetX;
            appStateObject.gridDrawOffsetY = CanvasGridOverlay.gridDrawOffsetY;

            appStateObject.hueCursorX = ColorPickerController.colorPickerBox.hueCursor.x;
            appStateObject.svBaseColor = ColorPickerController.colorPickerBox.svBaseColor;
            appStateObject.isHSVInfoTextMode = ColorPickerController.isHSVInfoTextMode;

            appStateObject.rReplayImageCacheState = ReplayState.rReplayImageCacheState;

            appStateObject.isRightSidebar = SidebarController.getActualIsRightSidebar();
            appStateObject.saveFilePath = FileManager.lastSaveFilePath;
            appStateObject.isSidebarVisible = SidebarController.isSidebarVisible;
            appStateObject.uiScaleIndex = UITheme.getUIScaleIndex();

            appStateObject.canvasWindowON = ImageViewWindow.isCanvasWindowON;

            appStateObject.newWindowInfo0 = ImageViewWindow.canvasWindowInfo[0];
            appStateObject.newWindowInfo1 = ImageViewWindow.canvasWindowInfo[1];
            appStateObject.newWindowInfo2 = ImageViewWindow.canvasWindowInfo[2];
            appStateObject.newWindowInfo3 = ImageViewWindow.canvasWindowInfo[3];

            appStateObject.getFirstRCursorPosX = ReplayDrawCommands.getFirstRCursorPos().x;
            appStateObject.getFirstRCursorPosY = ReplayDrawCommands.getFirstRCursorPos().y;

            appStateObject.myPalettePresetType = PaletteController.myPalettePresetType;
            appStateObject.isMyPaletteExpended = PaletteController.isMyPaletteExpended;
            appStateObject.isColorPickerBoxPositionSwapped = ColorPickerController.isColorPickerBoxPositionSwapped;

            appStateObject.captureStampText = UIController.topBar.captureInput.text;
            appStateObject.isCaptureStampON = CaptureStamp.isCaptureStampEnabled;
            appStateObject.captureStampFont = CaptureStamp.getFontName();

            appStateObject.scrollSetMovedY = SidebarController.scrollSetMovedY;
            appStateObject.isRefLayerMemoryTrainingON = ReferenceLayerController.isRefLayerMemoryTrainingON;

            const fs:FileStream = new FileStream();
            fs.open(appStateFilePath, FileMode.WRITE);
            fs.writeObject(appStateObject);
            fs.close();
        }

        public static function loadAppState():void
        {
            isLoadingAppData = true;
            const fs:FileStream = new FileStream();
            var arr:Array = [];
            var metaData:CacheImageMetaData;
            var newRectangle:Rectangle;
            const firstCachedImage:File = replayCacheImageFolderPath.resolvePath("0");

            // 앱 경로에 마지막 저장 파일이 있으면 끄기전의 상태로 세팅해줌
            if (firstCachedImage.exists)
            {
                fs.open(firstCachedImage, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();

                // 신버전
                if (arr[2] is CacheImageMetaData)
                {
                    metaData = arr[2];
                    arr[0].uncompress();
                    newRectangle = new Rectangle(0, 0, metaData.bmpdWidth, metaData.bmpdHeight);

                    if (ReplayFileCache.rFirstImageLayer1BitmapData)
                        ReplayFileCache.rFirstImageLayer1BitmapData.dispose();
                    ReplayFileCache.rFirstImageLayer1BitmapData = new BitmapData(metaData.bmpdWidth, metaData.bmpdHeight, true, 0);
                    ReplayFileCache.rFirstImageLayer1BitmapData.lock();
                    PixelRestore.setPixels(ReplayFileCache.rFirstImageLayer1BitmapData, newRectangle, arr[0]);
                    ReplayFileCache.rFirstImageLayer1BitmapData.unlock();

                    arr[1].uncompress();

                    if (ReplayFileCache.rFirstImageLayer2BitmapData)
                        ReplayFileCache.rFirstImageLayer2BitmapData.dispose();
                    ReplayFileCache.rFirstImageLayer2BitmapData = new BitmapData(metaData.bmpdWidth, metaData.bmpdHeight, true, 0);
                    ReplayFileCache.rFirstImageLayer2BitmapData.lock();
                    PixelRestore.setPixels(ReplayFileCache.rFirstImageLayer2BitmapData, newRectangle, arr[1]);
                    ReplayFileCache.rFirstImageLayer2BitmapData.unlock();

                    ReplaySaveMetaData.firstImageBG = metaData.bgColor;
                    ReplaySaveMetaData.firstImageMirrorFlag = metaData.mirrorFlag;
                }
                else // 구버전
                {
                    arr[0].uncompress();
                    newRectangle = new Rectangle(0, 0, arr[1], arr[2]);

                    if (ReplayFileCache.rFirstImageLayer1BitmapData)
                    {
                        ReplayFileCache.rFirstImageLayer1BitmapData.dispose();
                    }
                    ReplayFileCache.rFirstImageLayer1BitmapData = new BitmapData(arr[1], arr[2], true, 0);
                    ReplayFileCache.rFirstImageLayer1BitmapData.lock();
                    PixelRestore.setPixels(ReplayFileCache.rFirstImageLayer1BitmapData, newRectangle, arr[0]);
                    ReplayFileCache.rFirstImageLayer1BitmapData.unlock();

                    if (ReplayFileCache.rFirstImageLayer2BitmapData)
                    {
                        ReplayFileCache.rFirstImageLayer2BitmapData.dispose();
                    }
                    ReplayFileCache.rFirstImageLayer2BitmapData = new BitmapData(arr[1], arr[2], true, 0);

                    ReplaySaveMetaData.firstImageBG = arr[3];
                }
            }
            else
            {
                ReplayFileCache.rFirstImageLayer1BitmapData.dispose();
                ReplayFileCache.rFirstImageLayer2BitmapData.dispose();

                ReplayFileCache.rFirstImageLayer1BitmapData = new BitmapData(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, true, 0);
                ReplayFileCache.rFirstImageLayer2BitmapData = new BitmapData(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, true, 0);
            }

            if (ReferenceLayerController.refLayerImageFilePath.exists)
            {
                fs.open(ReferenceLayerController.refLayerImageFilePath, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();

                // arr[0].uncompress();
                newRectangle = new Rectangle(0, 0, arr[1], arr[2]);

                var tmpbmpd:BitmapData = new BitmapData(arr[1], arr[2], true, 0);
                tmpbmpd.lock();
                PixelRestore.setPixels(tmpbmpd, newRectangle, arr[0]);
                tmpbmpd.unlock();

                ReferenceLayerController.canvasRefLayerBitmapData = DrawCanvas.updateBitmapData(ReferenceLayerController.canvasRefLayerBitmapData, tmpbmpd, ReferenceLayerController.canvasRefLayerBitmap);
                ReferenceLayerController.canvasRefLayerBitmap.smoothing = true;

                tmpbmpd.dispose();
                tmpbmpd = null;
            }

            if (replayCacheImageFrameDataFilePath.exists)
            {
                fs.open(replayCacheImageFrameDataFilePath, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();

                ReplayFileCache.rJumpImageFrameData = arr.concat();
            }

            if (myPaletteDataFilePath.exists)
            {
                fs.open(myPaletteDataFilePath, FileMode.READ);
                var list:Array = fs.readObject();
                fs.close(); // 기존 코드에 없던 항목 변경을 막기 위해 유지

                PaletteController.myPalettePreset = list.concat();
                list.length = 0;
                list = null;
            }

            if (undoDataFilePath.exists)
            {
                loadUndoData(); // ReplayController.undo data 복구 먼저 해줘야함
            }

            if (scratchPadDataFilePath.exists)
            {
                loadScratchPadImage();
            }

            if (appStateFilePath.exists)
            {
                fs.open(appStateFilePath, FileMode.READ);
                const appStateObject:AppStateVars = fs.readObject() as AppStateVars;
                fs.close();

                // loadUndoData함수에서 canvaspanel이 호출되는데 이전에 reflayer 이미지 정보값을 넣어두어야함
                // 그냥 해주면 창크기 적용이 안되서 타이머 걸어줌
                FOFOTimer.addByName("loadAppDataDelayTimer", 0.2, false, function ():void
                    {
                        // Window Size & Position
                        main.stage.nativeWindow.width = appStateObject.stageNativeWindowWidth;
                        main.stage.nativeWindow.height = appStateObject.stageNativeWindowHeight;
                        main.stage.nativeWindow.x = appStateObject.stageNativeWindowX;
                        main.stage.nativeWindow.y = appStateObject.stageNativeWindowY;

                        AppWindowState.lastAppWindowSize.width = appStateObject.stageNativeWindowWidth;
                        AppWindowState.lastAppWindowSize.height = appStateObject.stageNativeWindowHeight;

                        // 캔버스 bg를 한번 업데이트해춤 on window resize이벤트에서는 앱이 정보가 로드되고 있을때 차단되기 때문에
                        UIController.updateStageBGSize();

                        // UI Scale & Color
                        UITheme.setScaleIndex(appStateObject.uiScaleIndex);
                        UIController.applyUIScale();
                        UITheme.setUIColorIndex(appStateObject.uiColorIndex);
                        UIController.applyUIColorSet();

                        // Canvas Settings
                        CanvasView.canvasZoomIndex = appStateObject.canvasZoomIndex;
                        CanvasView.viewport.setScale(appStateObject.canvasZoomedMultiplier);

                        CanvasView.canvasPanel.x = appStateObject.canvasPanelX;
                        CanvasView.canvasPanel.y = appStateObject.canvasPanelY;

                        CanvasView.canvasAnchorPoint.x = appStateObject.canvasAnchorPointX;
                        CanvasView.canvasAnchorPoint.y = appStateObject.canvasAnchorPointY;
                        CanvasView.canvasAnchorPoint.rotation = appStateObject.canvasAnchorPointRotation;

                        ReplayDrawer.setRcursorRotation(appStateObject.canvasAnchorPointRotation);
                        CanvasResizer.updateButtonPos(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT);
                        UIController.canvasRotateCursor.rotateArrow.rotation = appStateObject.canvasAnchorPointRotation;

                        // Pen Tool Settings
                        PenSettings.penSmoothValue = appStateObject.penSmoothValue;
                        PenSettings.penSmoothSlideValue = appStateObject.penSmoothSlideValue;
                        ToolPanel.toolOptionsBox.penSmoothSliderCursor.x = appStateObject.penSmoothButtonX;

                        PenSettings.penSize = appStateObject.penSize;
                        PenTool.penColor = appStateObject.penColor;

                        // Color Picker
                        ColorPickerController.hsvColorData[0] = appStateObject.hsvColorData0; // 순서 중요 이게 먼저오고 밑에 rgb info갱신해주어야함
                        ColorPickerController.isHSVInfoTextMode = appStateObject.isHSVInfoTextMode;
                        ColorPickerController.updatePickerCurrentColor(PenTool.penColor);
                        ColorPickerController.updateColorPickerCursorPosAndRGBInfo(PenTool.penColor);
                        ColorPickerController.colorPickerBox.updateHueColor(appStateObject.svBaseColor);
                        ColorPickerController.colorPickerBox.hueCursor.x = appStateObject.hueCursorX;

                        // Draw Tool Alpha & Shape
                        PenSettings.penAlpha = appStateObject.penAlpha;
                        PenSettings.penAlphaIndex = PenSettings.penAlphaList.indexOf(appStateObject.penAlpha);
                        PenSettings.applyDrawingToolAlpha(appStateObject.penAlpha);

                        PenSettings.penIsSquare = appStateObject.penIsSquare;
                        PenSettings.penListShapeIsSqare = appStateObject.penIsSquare;
                        ToolPanel.toolOptionsBox.updatePenShapeSet(appStateObject.penIsSquare);

                        // Eraser Settings
                        PenSettings.eraserSize = appStateObject.eraseSize;
                        PenSettings.eraserIsSquare = appStateObject.eraserIsSquare;
                        PenSettings.eraserAlpha = appStateObject.eraseAlpha;
                        PenSettings.eraserAlphaIndex = PenSettings.penAlphaList.indexOf(appStateObject.eraseAlpha);
                        PenSettings.eraserSizeIndex = appStateObject.eraseSizeIndex;
                        PenSettings.setDrawToolSize(appStateObject.penSizeIndex);

                        // File Path Settings
                        FileManager.lastSaveFilePath = appStateObject.saveFilePath;
                        FileManager.lastSaveFileName = appStateObject.saveFileName;

                        if (FileManager.lastSaveFilePath === FileManager.lastSaveFileName)
                        {
                            FileManager.lastSaveFilePath = File.desktopDirectory.nativePath + File.separator + FileManager.lastSaveFileName;
                        }

                        // Timer
                        ActivityWorkTimer.setRunningTime(appStateObject.appRunningTime);
                        ActivityWorkTimer.update();

                        // Reference Layer
                        ReferenceLayerController.refLayerLastAlpha = appStateObject.refLayerLastAlpha;
                        ReferenceLayerController.canvasRefLayer.alpha = appStateObject.refLayerLastAlpha;

                        ReferenceLayerController.refLayerMenuBox.refOpacityCursor.x = appStateObject.refOpacityCursorX;
                        ReferenceLayerController.refLayerMenuBox.x = appStateObject.refLayerMenuBox0;
                        ReferenceLayerController.refLayerMenuBox.y = appStateObject.refLayerMenuBox1;
                        ReferenceLayerController.refLayerMenuDragXMoveSum = appStateObject.refLayerMenuDragXMoveSum;

                        if (appStateObject.isRefLayerMemoryTrainingON)
                        {
                            ReferenceLayerController.isRefLayerMemoryTrainingON = false;
                            ReferenceLayerController.toggleRefLayerMemoryTraining();
                        }

                        // Sidebar Settings
                        SidebarController.restoreTempSideFlip();
                        SidebarController.isRightSidebar = appStateObject.isRightSidebar;
                        SidebarController.isSidebarVisible = appStateObject.isSidebarVisible;

                        if (appStateObject.isRightSidebar)
                            SidebarController.moveSideBar("right", true);

                        if (!appStateObject.isSidebarVisible)
                            SidebarController.hideSidebarPermanent();

                        // Replay Controller
                        ReplayState.rReplayImageCacheState = appStateObject.rReplayImageCacheState;
                        ReplayDrawCommands.setFirstRCursorPos(appStateObject.getFirstRCursorPosX, appStateObject.getFirstRCursorPosY);

                        ReferenceLayerController.updateRefLayerImageTransform(
                                appStateObject.canvasRefLayerBitmapX,
                                appStateObject.canvasRefLayerBitmapY,
                                appStateObject.canvasRefLayerRotation,
                                appStateObject.canvasRefLayerScaleX,
                                appStateObject.canvasRefLayerScaleY
                            );

                        if (DrawCanvas.mirrorON !== appStateObject.isCanvasMirrored)
                            CanvasView.mirrorCanvas(true);

                        // Grid Overlay
                        CanvasGridOverlay.gridGapMultiplier = appStateObject.gridValue;
                        CanvasGridOverlay.gridDrawOffsetX = appStateObject.gridDrawOffsetX;
                        CanvasGridOverlay.gridDrawOffsetY = appStateObject.gridDrawOffsetY;

                        if (!CanvasGridOverlay.gridDrawOffsetX)
                            CanvasGridOverlay.gridDrawOffsetX = 0.0;

                        if (!CanvasGridOverlay.gridDrawOffsetY)
                            CanvasGridOverlay.gridDrawOffsetY = 0.0;

                        if (appStateObject.gridValue > 0)
                            CanvasGridOverlay.drawGrid();

                        // Image View Window
                        if (appStateObject.canvasWindowON)
                        {
                            ImageViewWindow.canvasWindowInfo = [
                                    appStateObject.newWindowInfo0,
                                    appStateObject.newWindowInfo1,
                                    appStateObject.newWindowInfo2,
                                    appStateObject.newWindowInfo3
                                ];
                            ImageViewWindow.openImageViewWindow();
                            main.stage.nativeWindow.activate();
                        }

                        ReplayState.rMemoryDataIndex = UndoHistory.undoDataIndex;
                        ReplayState.rNowFrame = ReplayState.getNowFrameUntilUndoIndex(UndoHistory.undoDataIndex);
                        ReplayState.rPrevFrame = ReplayState.getNowFrameUntilUndoIndex(UndoHistory.undoDataIndex - 1);

                        // 혹시 몰라서 위치 체크 해줌
                        UIController.canvasInfoBox.setRotate(CanvasView.canvasAnchorPoint.rotation);
                        ReplayDrawer.viewport.centerIn("replay");
                        CanvasView.viewport.keepInStage();
                        ReplayDrawer.viewport.keepInStage();

                        // Palette Settings
                        PaletteController.myPaletteSaveColorBeforeOtherType[0] = PenTool.penColor;

                        if (appStateObject.myPalettePresetType > 0)
                            ColorPickerController.activeColorPreset(appStateObject.myPalettePresetType);

                        PaletteController.updateHistoryList();
                        PaletteController.isMyPaletteExpended = appStateObject.isMyPaletteExpended;

                        if (PaletteController.myPalettePresetType === 0 && appStateObject.isMyPaletteExpended)
                        {
                            PaletteController.switchMyPaletteToExpended();
                        }
                        else
                        {
                            PaletteController.updateMyPaletteList();
                        }

                        ColorPickerController.isColorPickerBoxPositionSwapped = appStateObject.isColorPickerBoxPositionSwapped;

                        if (appStateObject.isColorPickerBoxPositionSwapped)
                        {
                            ColorPickerController.colorPickerBox.swapColorBoxPositions(appStateObject.isColorPickerBoxPositionSwapped);
                        }

                        // UI Miscellaneous
                        SidebarController.sideBarScrollPanel.y = appStateObject.scrollSetMovedY;

                        UIController.topBar.captureInput.text = appStateObject.captureStampText;
                        CaptureStamp.setCaptureStampEnabled(appStateObject.isCaptureStampON);

                        if (appStateObject.captureStampFont)
                        {
                            CaptureStamp.changeFont(appStateObject.captureStampFont, false);
                        }

                        CanvasNavigator.updateCursor();
                        PenSizePreviewCursor.updateSizeAndShape();
                        isLoadingAppData = false;
                        AppWindowState.updateWindowTitle();
                        CanvasLayers.selectLayer1(false);

                        if (ReplayState.isGeneratingCacheImages())
                        {
                            // 닫을때 로드박스에 깔려있던 흐린 배경 이미지를 다시 깔아줌
                            const preview:BitmapData = ReplayFileCache.loadCachePreview();

                            if (preview)
                            {
                                LoadBoxController.loadMenuBox.setPreviewImage(preview);
                            }

                            // 캐시 이미지 만드는 도중에 닫았으면 마지막으로 확정된 캐시 이미지부터 이어서 만듬
                            const resumeIndex:int = ReplayFileCache.restoreCacheProgress();

                            if (resumeIndex >= 0)
                            {
                                ReplayController.startGeneratingReplayCacheImage(true, null, resumeIndex);
                                return;
                            }

                            ReplayFileCache.createFirstImageCache(
                                    ReplayFileCache.rFirstImageLayer1BitmapData,
                                    ReplayFileCache.rFirstImageLayer2BitmapData,
                                    ReplaySaveMetaData.firstImageBG,
                                    ReplaySaveMetaData.firstImageMirrorFlag);
                            ReplayController.startGeneratingReplayCacheImage(true, null);
                        }
                        // 캔버스 위치까지 전부 다해준 다음에 이전 상태가 풀스크린이었으면 세팅해줌
                        if (appStateObject.lastWindowState === 1)
                        {
                            main.stage.nativeWindow.maximize();

                            // 최대화 완료 RESIZE 이벤트가 오지 않아도 화면이 갱신되도록 한 번 더 예약해둔다.
                            // applyLayout은 멱등이라 이벤트가 먼저 처리했으면 dx 0으로 지나간다.
                            FOFOTimer.addByName("settleLayoutTimer", 0.3, false, UIController.applyLayout);
                        }
                    });
            }
            else // 복원파일이 없을때
            {
                if (FileManager.lastSaveFilePath === FileManager.lastSaveFileName)
                {
                    FileManager.lastSaveFilePath = File.desktopDirectory.nativePath + File.separator + FileManager.lastSaveFileName;
                }

                PaletteController.initializeMyPaletteList();

                AppWindowState.lastAppWindowSize.width = 1000;
                AppWindowState.lastAppWindowSize.height = 800;

                DrawCanvas.applyCanvasSizeDrawMode(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, 0, 0, false);
                CanvasResizer.updateButtonPos(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT);

                ColorPickerController.updatePickerCurrentColor(PenTool.penColor);
                ColorPickerController.updateColorPickerCursorPosAndRGBInfo(PenTool.penColor);

                AboutBoxController.openAboutBox(true);
                UIController.applyUIColorSet();

                UIController.canvasInfoBox.init(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, Math.floor(CanvasView.canvasZoomMultiplier * 100), CanvasView.canvasAnchorPoint.rotation, false);
                CanvasLayers.selectLayer1(false);

                PaletteController.initMyPaletteHistory();

                FOFOTimer.add(0.3, true, function ():Boolean
                    {
                        if (main.stage.nativeWindow.width === 1000 && main.stage.nativeWindow.height === 800)
                        {
                            CanvasView.viewport.centerIn("draw");
                            CanvasNavigator.updateCursor();

                            // lastAppWindowSize를 미리 1000x800으로 채워뒀기 때문에 리사이즈 이벤트의 applyLayout은 dx/dy 0으로 지나간다.
                            // 크기가 확정된 이 시점에 UI 배치를 강제로 한 번 맞춰준다.
                            UIController.applyLayout(true);
                            return false;
                        }

                        main.stage.nativeWindow.width = AppWindowState.lastAppWindowSize.width;
                        main.stage.nativeWindow.height = AppWindowState.lastAppWindowSize.height;
                        return true;
                    });

                isLoadingAppData = false;
            }

            loadAppUpTimeFromAppData();
        }

        public static function writeCrashLog(errorObject:*):void
        {
            if (isWritingCrashLog || dataFolderPath === null)
            {
                return;
            }

            isWritingCrashLog = true;
            var stream:FileStream;
            try
            {
                const now:Date = new Date();
                var dateKey:String = String(now.fullYear);
                if (now.month + 1 < 10)
                    dateKey += "0";
                dateKey += String(now.month + 1);
                if (now.date < 10)
                    dateKey += "0";
                dateKey += String(now.date);

                const logFolder:File = dataFolderPath.resolvePath("log");
                logFolder.createDirectory();
                const logFile:File = logFolder.resolvePath("fofo_error_log_" + dateKey + ".txt");
                var logText:String = "[" + now.toString() + "]\r\n";

                if (errorObject is Error)
                {
                    const runtimeError:Error = errorObject as Error;
                    logText += runtimeError.toString() + "\r\n";
                    logText += "Message: " + runtimeError.message + "\r\n";
                    logText += "Error ID: " + runtimeError.errorID + "\r\n";
                    const stack:String = runtimeError.getStackTrace();
                    logText += "Stack trace:\r\n" + (stack ? stack : "(unavailable)") + "\r\n";
                }
                else if (errorObject is ErrorEvent)
                {
                    const errorEvent:ErrorEvent = errorObject as ErrorEvent;
                    logText += errorEvent.toString() + "\r\n";
                    logText += "Message: " + errorEvent.text + "\r\n";
                    logText += "Error ID: " + errorEvent.errorID + "\r\n";
                    logText += "Stack trace: (unavailable for ErrorEvent)\r\n";
                }
                else
                {
                    logText += "Thrown value: " + String(errorObject) + "\r\n";
                    logText += "Stack trace: (unavailable)\r\n";
                }
                logText += "\r\n";

                stream = new FileStream();
                stream.open(logFile, FileMode.APPEND);
                stream.writeUTFBytes(logText);
            }
            catch (writeError:Error)
            {
                trace("Crash log write failed: " + writeError);
            }
            finally
            {
                if (stream !== null)
                {
                    try
                    {
                        stream.close();
                    }
                    catch (closeError:Error)
                    {
                        trace("Crash log close failed: " + closeError);
                    }
                }
                isWritingCrashLog = false;
            }
        }

        public static function saveReplayFrameData():void
        {
            const fs:FileStream = new FileStream();
            fs.open(replayCacheImageFrameDataFilePath, FileMode.WRITE);
            fs.writeObject(ReplayFileCache.rJumpImageFrameData);
            fs.close();
        }

        // 앱데이터\버전\log 폴더를 탐색기로 염, 크래시가 없어서 폴더가 없으면 만들어서 엶
        public static function openCrashLogFolder():void
        {
            if (dataFolderPath === null)
            {
                return;
            }

            const logFolder:File = dataFolderPath.resolvePath("log");
            try
            {
                if (!logFolder.exists)
                {
                    logFolder.createDirectory();
                }
                logFolder.openWithDefaultApplication();
            }
            catch (error:Error)
            {
                trace("Open crash log folder failed: " + error);
            }
        }

        public static function loadScratchPadImage():void
        {
            const fs:FileStream = new FileStream();
            const ba:ByteArray = new ByteArray();
            const bmpd:BitmapData = ColorPickerController.colorPickerBox.scratchPad.getBitmapData();
            fs.open(scratchPadDataFilePath, FileMode.READ);
            var arr:Array = fs.readObject() as Array;
            fs.close();
            bmpd.lock();
            PixelRestore.setPixels(bmpd, new Rectangle(0, 0, arr[1], arr[2]), arr[0]);
            bmpd.unlock();
        }

        private static function saveScratchPadImage():void
        {
            const fs:FileStream = new FileStream();
            const ba:ByteArray = new ByteArray();
            const bmpd:BitmapData = ColorPickerController.colorPickerBox.scratchPad.getBitmapData();
            const newRectangle:Rectangle = new Rectangle(0, 0, bmpd.width, bmpd.height);
            bmpd.copyPixelsToByteArray(ColorPickerController.colorPickerBox.scratchPad.getBitmapData().rect, ba);
            fs.open(scratchPadDataFilePath, FileMode.WRITE);
            fs.writeObject([ba, newRectangle.width, newRectangle.height]);
            fs.close();
        }

        public static function deleteTempDirectory():void
        {
            const file:File = File.applicationStorageDirectory.resolvePath("tmp");
            if (file.exists)
            {
                file.deleteDirectory(true);
            }
        }

        public static function saveAllAppData():void
        {
            saveAppState();
            saveUndoData();
            saveReplayFrameData();
            ReferenceLayerController.saveRefLayerImage();
            PaletteController.saveMypPaletteList();
            saveScratchPadImage();
            saveAppUpTime();
        }

        private static function saveAppUpTime():void
        {
            const fs:FileStream = new FileStream();

            const appUpTime:int = ActivityWorkTimer.getAppUpTime();
            fs.open(appUpTimePath, FileMode.WRITE);
            fs.writeInt(appUpTime);
            fs.close();
        }

        public static function checkWindowMaximizedAndSaveAllData():void
        {
            if (main.stage.nativeWindow.displayState === "maximized")
            {
                AppWindowState.lastAppWindowState = 1;
                main.stage.nativeWindow.restore();
            }
            else
            {
                AppWindowState.lastAppWindowState = 0;
                deleteTempDirectory();
                saveAllAppData();
                main.stage.nativeWindow.close();
            }
        }

        public static function loadUndoData():void
        {
            if (undoDataFilePath.exists === false)
            {
                return;
            }

            ReplayState.rMirrorON = false;
            DrawCanvas.mirrorON = false;
            UIController.canvasInfoBox.setMirror(false);

            const fs:FileStream = new FileStream();
            fs.open(undoDataFilePath, FileMode.READ);

            const lastUndoIndex:int = fs.readInt();
            var arr:Array = fs.readObject() as Array; // undodata first

            const bmpdRect:Rectangle = new Rectangle(0, 0, arr[2], arr[3]);
            var bmpd:BitmapData = new BitmapData(arr[2], arr[3], true, 0);
            var bmpd1:BitmapData = new BitmapData(arr[2], arr[3], true, 0);

            if (arr[6] is Number)
            {
                ReplayState.setRFileDataTotalFrame(arr[6]);
            }

            ReplayState.rMemoryData = (fs.readObject() as Array).concat();
            ReplayState.rMemoryDataFrame = (fs.readObject() as Array).concat();
            fs.close();

            UndoHistory.setUndoDataIndex(lastUndoIndex);

            bmpd.lock();
            PixelRestore.setPixels(bmpd, bmpdRect, arr[0]);
            bmpd.unlock();

            bmpd1.lock();
            PixelRestore.setPixels(bmpd1, bmpdRect, arr[1]);
            bmpd1.unlock();

            UndoHistory.updateUndoBaseImage(bmpd.clone(), bmpd1.clone(), arr[2], arr[3], arr[4], arr[5]);
            UndoController.updateCanvasStateAfterUndo();

            ReplayDrawer.rReplayFOFOCursor.visible = false;
            HintController.hideMouseHint();

            bmpd.dispose();
            bmpd1.dispose();
            bmpd = null;
            bmpd1 = null;

            arr.length = 0;
            arr = null;
        }

        public static function saveUndoData():void
        {
            const fs:FileStream = new FileStream();
            const arr:Array = UndoHistory.getUndoBaseImage();
            const bmpd:BitmapData = arr[0];
            const bmpd1:BitmapData = arr[1];

            var ba:ByteArray = new ByteArray();
            var ba1:ByteArray = new ByteArray();
            var newRectangle:Rectangle = new Rectangle(0, 0, arr[2], arr[3]);

            bmpd.copyPixelsToByteArray(newRectangle, ba);
            bmpd1.copyPixelsToByteArray(newRectangle, ba1);

            // ba.compress();
            // ba1.compress();
            // 레이어 1,레이어2,가로,세로,배경색, repdata 합계 프레임
            var newArr:Array = [ba, ba1, arr[2], arr[3], arr[4], arr[5], ReplayState.getRFileDataTotalFrame()];

            fs.open(undoDataFilePath, FileMode.WRITE);
            fs.writeInt(UndoHistory.undoDataIndex);
            fs.writeObject(newArr);
            fs.writeObject(ReplayState.rMemoryData);
            fs.writeObject(ReplayState.rMemoryDataFrame);
            fs.close();

            ba.clear();
            ba1.clear();
            ba = null;
            ba1 = null;
        }
    }
}
