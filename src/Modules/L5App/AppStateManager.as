package Modules.L5App
{
    import Modules.DrawEngine.CanvasLayers;
    import Modules.UIEngine.CanvasNavigator;
    import Modules.UIEngine.UITheme;
    import Modules.CaptureEngine.CaptureStamp;
    import Modules.CaptureEngine.CaptureController;
    import Modules.Tools.PenTool;

    import Modules.L1Data.AppDataPaths;
    import flash.display.BitmapData;
    import flash.display.NativeWindowDisplayState;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import flash.utils.getTimer;
    import Modules.ReplayEngine.ReplayDrawCommands;
    import Modules.ReplayEngine.ReplayState;
    import Modules.ReplayEngine.ReplaySaveMetaData;
    import flash.trace.Trace;
    import Modules.L3Feature.ActivityWorkTimer;
    import Modules.L5App.AppWindowState;
    import Modules.L4UI.CanvasGridOverlay;
    import Modules.L2Engine.DrawEngine.CanvasResizer;
    import Modules.L4UI.ColorPickerController;
    import Modules.L5App.FileManager;
    import Modules.L4UI.ImageViewWindow;
    import Modules.L4UI.LoadBoxController;
    import Modules.L5App.ReplayEngine.ReplayController;
    import Modules.L4UI.SidebarController;
    import Modules.L3Feature.Tools.ToolController;
    import Modules.L4UI.Tools.ToolPanel;
    import Modules.L3Feature.UndoController;
    import Modules.L4UI.AboutBoxController;
    import Modules.AppStateVars;
    import Modules.CacheImageFile;
    import Modules.CacheImageMetaData;
    import Modules.ColorHistory;
    import Modules.L4UI.PaletteController;
    import Modules.PixelRestore;
    import Modules.ReferenceLayerController;
    import Modules.L2Engine.ReplayEngine.ReplayClock;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.L2Engine.ReplayEngine.ReplayFileCache;
    import Modules.L2Engine.ReplayEngine.TimingSheetFile;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L1Data.UndoHistory;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L1Data.Tools.PenSettings;
    import Modules.L4UI.PenSizePreviewCursor;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L2Engine.DrawEngine.DrawCanvas;

    // 층: L5 앱 흐름 - 앱 상태 저장·불러오기와 크래시 로그, 임시 폴더 관리
    public class AppStateManager
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
            AppDataPaths.initialize(main.APP_STATE_VERSION);
        }

        private static var isRebuildFromReplayFileNeeded:Boolean = false; // loadUndoData에서 저장본이 리플레이 파일과 맞지 않아 쓰지 못했을때
        public static const appUpTimePath:File = File.applicationStorageDirectory.resolvePath("appuptime");

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

            var windowBounds:Rectangle = main.stage.nativeWindow.bounds;

            if (main.stage.nativeWindow.displayState !== NativeWindowDisplayState.MINIMIZED)
            {
                AppWindowState.lastNormalWindowBounds = windowBounds.clone();
            }
            else if (AppWindowState.lastNormalWindowBounds !== null)
            {
                windowBounds = AppWindowState.lastNormalWindowBounds;
            }

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
            fs.open(AppDataPaths.appStateFilePath, FileMode.WRITE);
            fs.writeObject(appStateObject);
            fs.close();
        }

        public static function loadAppState():void
        {
            AppDataPaths.isLoadingAppData = true;
            ReplayFileCache.clearLoadCacheTempFolder(); // 지난 실행에서 끝나지 못한 불러오기 캐시 임시 파일
            const fs:FileStream = new FileStream();
            var arr:Array = [];
            var metaData:CacheImageMetaData;
            var newRectangle:Rectangle;
            const firstCachedImage:File = AppDataPaths.replayCacheImageFolderPath.resolvePath("0");

            // 앱 경로에 마지막 저장 파일이 있으면 끄기전의 상태로 세팅해줌
            if (firstCachedImage.exists && CacheImageFile.isNewFormatFile(firstCachedImage))
            {
                // 새 형식 (네이티브 덤프 또는 AS3 straight)
                const cached:Object = CacheImageFile.read(firstCachedImage);
                metaData = cached.metadata as CacheImageMetaData;

                if (ReplayFileCache.rFirstImageLayer1BitmapData)
                    ReplayFileCache.rFirstImageLayer1BitmapData.dispose();
                if (ReplayFileCache.rFirstImageLayer2BitmapData)
                    ReplayFileCache.rFirstImageLayer2BitmapData.dispose();

                ReplayFileCache.rFirstImageLayer1BitmapData = cached.bmpd1;
                ReplayFileCache.rFirstImageLayer2BitmapData = cached.bmpd2;
                ReplaySaveMetaData.firstImageBG = metaData.bgColor;
                ReplaySaveMetaData.firstImageMirrorFlag = metaData.mirrorFlag;
            }
            else if (firstCachedImage.exists)
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

                if(!ReferenceLayerController.isRefLayerEmpty())
                {
                    ReferenceLayerController.setRefLayerMenuButtonsOn();
                }

                tmpbmpd.dispose();
                tmpbmpd = null;
            }

            if (AppDataPaths.replayCacheImageFrameDataFilePath.exists)
            {
                fs.open(AppDataPaths.replayCacheImageFrameDataFilePath, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();

                ReplayFileCache.rJumpImageFrameData = arr.concat();
            }

            if (AppDataPaths.myPaletteDataFilePath.exists)
            {
                fs.open(AppDataPaths.myPaletteDataFilePath, FileMode.READ);
                var list:Object = fs.readObject();
                fs.close(); // 기존 코드에 없던 항목 변경을 막기 위해 유지

                PaletteController.applyMyPaletteData(list);
                list = null;
            }

            if (AppDataPaths.undoDataFilePath.exists)
            {
                loadUndoData(); // ReplayController.undo data 복구 먼저 해줘야함
            }
            else if (AppDataPaths.replayDataFilePath.exists && AppDataPaths.replayDataFilePath.size > 0)
            {
                // undo 저장본 없이 리플레이 파일만 있으면 파일부터 다시 읽음
                isRebuildFromReplayFileNeeded = true;
            }

            TimingSheetFile.loadLegacy(ReplayState.getRFileDataTotalFrame()); // 요약보다 먼저: 요약이 이 값으로 만든 것인지 확인함
            ReplayClock.loadIndex(); // 복구한 프레임 수와 시트가 요약과 맞으면 첫 사용 때 전체 읽기를 건너뜀

            if (AppDataPaths.scratchPadDataFilePath.exists)
            {
                loadScratchPadImage();
            }

            if (AppDataPaths.appStateFilePath.exists)
            {
                fs.open(AppDataPaths.appStateFilePath, FileMode.READ);
                const appStateObject:AppStateVars = fs.readObject() as AppStateVars;
                fs.close();

                // loadUndoData함수에서 canvaspanel이 호출되는데 이전에 reflayer 이미지 정보값을 넣어두어야함
                // 그냥 해주면 창크기 적용이 안되서 타이머 걸어줌
                FOFOTimer.addByName("loadAppDataDelayTimer", 0.2, false, function ():void
                    {
                        // Window Size & Position
                        const windowBounds:Rectangle = AppWindowState.getVisibleWindowBounds(new Rectangle(appStateObject.stageNativeWindowX, appStateObject.stageNativeWindowY, appStateObject.stageNativeWindowWidth, appStateObject.stageNativeWindowHeight), 1000, 800);
                        main.stage.nativeWindow.width = windowBounds.width;
                        main.stage.nativeWindow.height = windowBounds.height;
                        main.stage.nativeWindow.x = windowBounds.x;
                        main.stage.nativeWindow.y = windowBounds.y;
                        AppWindowState.lastNormalWindowBounds = windowBounds.clone();

                        AppWindowState.lastAppWindowSize.width = windowBounds.width;
                        AppWindowState.lastAppWindowSize.height = windowBounds.height;

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
                            UIController.mirrorCanvas(true);

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

                        ColorHistory.update();
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
                        AppDataPaths.isLoadingAppData = false;
                        AppWindowState.updateWindowTitle();
                        CanvasLayers.selectLayer(1, false);

                        // undo 저장본과 리플레이 파일이 맞지 않으면 캐시 이미지를 처음부터 다시 만들면서 최종 캔버스까지 갱신함
                        const rebuildFromReplayFile:Boolean = isRebuildFromReplayFileNeeded;
                        isRebuildFromReplayFileNeeded = false;

                        if (rebuildFromReplayFile || ReplayState.isGeneratingCacheImages())
                        {
                            if (!rebuildFromReplayFile)
                            {
                                // 닫을때 로드박스에 깔려있던 흐린 배경 이미지를 다시 깔아줌
                                const preview:BitmapData = ReplayFileCache.loadCachePreview();

                                if (preview)
                                {
                                    LoadBoxController.loadMenuBox.setPreviewImage(preview);
                                }
                            }

                            // 캐시 이미지 만드는 도중에 닫았으면 마지막으로 확정된 캐시 이미지부터 이어서 만듬
                            const resumeIndex:int = rebuildFromReplayFile ? -1 : ReplayFileCache.restoreCacheProgress();

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
                CanvasLayers.selectLayer(1, false);

                ColorHistory.init();

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

                AppDataPaths.isLoadingAppData = false;
            }

            loadAppUpTimeFromAppData();
        }

        public static function saveReplayFrameData():void
        {
            const fs:FileStream = new FileStream();
            fs.open(AppDataPaths.replayCacheImageFrameDataFilePath, FileMode.WRITE);
            fs.writeObject(ReplayFileCache.rJumpImageFrameData);
            fs.close();
        }

        public static function loadScratchPadImage():void
        {
            const fs:FileStream = new FileStream();
            const ba:ByteArray = new ByteArray();
            const bmpd:BitmapData = ColorPickerController.colorPickerBox.scratchPad.getBitmapData();
            fs.open(AppDataPaths.scratchPadDataFilePath, FileMode.READ);
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
            fs.open(AppDataPaths.scratchPadDataFilePath, FileMode.WRITE);
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
            ReplayClock.saveIndex();
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
            if (AppDataPaths.undoDataFilePath.exists === false)
            {
                return;
            }

            ReplayState.rMirrorON = false;
            DrawCanvas.mirrorON = false;
            UIController.canvasInfoBox.setMirror(false);

            const fs:FileStream = new FileStream();
            fs.open(AppDataPaths.undoDataFilePath, FileMode.READ);

            const lastUndoIndex:int = fs.readInt();
            var arr:Array = fs.readObject() as Array; // undodata first

            const bmpdRect:Rectangle = new Rectangle(0, 0, arr[2], arr[3]);
            var bmpd:BitmapData = new BitmapData(arr[2], arr[3], true, 0);
            var bmpd1:BitmapData = new BitmapData(arr[2], arr[3], true, 0);

            // 저장 없이 앱이 죽으면(정전, 강제 종료, 딥 언두로 파일이 잘린 뒤 종료 등) 리플레이 파일과 저장본이 서로 다른 시점이 됨
            // 저장한 파일 크기와 지금 크기가 다르거나 크기를 기록하지 않던 저장본이면 저장본(메모리 뭉치, 기준 이미지)은 버리고
            // 리플레이 파일을 처음부터 읽어서 캐시 이미지와 캔버스를 다시 만듬 (undo 기록은 사라짐)
            const nowReplayFileSize:Number = AppDataPaths.replayDataFilePath.exists ? AppDataPaths.replayDataFilePath.size : 0;

            if (!(arr[6] is Number) || arr[7] !== nowReplayFileSize)
            {
                AppDataPaths.writeCrashLog("Replay file does not match undo data: saved frame " + arr[6] + ", saved byte " + arr[7] + ", now byte " + nowReplayFileSize);
                fs.close();
                bmpd.dispose();
                bmpd1.dispose();
                isRebuildFromReplayFileNeeded = true;
                return;
            }

            ReplayState.setRFileDataTotalFrame(arr[6]);

            ReplayState.rMemoryData = (fs.readObject() as Array).concat();
            ReplayState.rMemoryDataFrames = (fs.readObject() as Array).concat();
            restoreMemoryDataTimingSheet(fs);
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

        // 저장해둔 명령별 시각을 읽어서 지금 getTimer 기준으로 옮김. 앱이 꺼져있던 시간은 세지 않음
        // 저장본에 없거나 메모리 뭉치와 모양이 맞지 않으면 전부 지금 시각으로 채움 (간격 0)
        private static function restoreMemoryDataTimingSheet(fs:FileStream):void
        {
            const now:int = getTimer();
            var times:Array = null;
            var offset:int = 0;

            if (fs.bytesAvailable > 0)
            {
                times = fs.readObject() as Array;
                offset = now - fs.readInt();
                TimingSheetFile.setLastStamp(fs.readBoolean(), (fs.readInt() + offset) | 0);
            }

            var isValid:Boolean = times !== null && times.length === ReplayState.rMemoryData.length;

            for (var i:int = 0;isValid && i < times.length;i++)
            {
                isValid = (times[i] as Array) !== null && times[i].length === ReplayState.rMemoryData[i].length;
            }

            if (isValid)
            {
                for (i = 0;i < times.length;i++)
                {
                    for (var j:int = 0;j < times[i].length;j++)
                    {
                        times[i][j] = TimingSheetFile.shiftElement(times[i][j], offset);
                    }
                }

                ReplayState.rMemoryDataTimingSheet = times;
                return;
            }

            ReplayState.rMemoryDataTimingSheet = [];

            for (i = 0;i < ReplayState.rMemoryData.length;i++)
            {
                const filled:Array = new Array(ReplayState.rMemoryData[i].length);

                for (j = 0;j < filled.length;j++)
                {
                    filled[j] = TimingSheetFile.packStamp(now, 0);
                }

                ReplayState.rMemoryDataTimingSheet.push(filled);
            }

            TimingSheetFile.breakClock();
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
            // 레이어 1,레이어2,가로,세로,배경색, 미러, repdata 합계 프레임, repdata 파일 크기 (불러올때 저장 시점과 맞는지 확인하는데 씀)
            var newArr:Array = [ba, ba1, arr[2], arr[3], arr[4], arr[5], ReplayState.getRFileDataTotalFrame(), AppDataPaths.replayDataFilePath.exists ? AppDataPaths.replayDataFilePath.size : 0];

            fs.open(AppDataPaths.undoDataFilePath, FileMode.WRITE);
            fs.writeInt(UndoHistory.undoDataIndex);
            fs.writeObject(newArr);
            fs.writeObject(ReplayState.rMemoryData);
            fs.writeObject(ReplayState.rMemoryDataFrames);
            // 명령별 시각과 저장 시점의 getTimer, 시간 간격 파일의 마지막 시각 (불러올때 이 값을 새 getTimer 기준으로 옮김)
            const timingLast:Object = TimingSheetFile.getLastStamp();
            fs.writeObject(ReplayState.rMemoryDataTimingSheet);
            fs.writeInt(getTimer());
            fs.writeBoolean(timingLast.has);
            fs.writeInt(timingLast.stamp);
            fs.close();

            ba.clear();
            ba1.clear();
            ba = null;
            ba1 = null;
        }
    }
}
