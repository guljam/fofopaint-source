package Modules
{
    import Modules.Tools.PenTool;

    import flash.display.BitmapData;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;

    public class AppStateManager
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static function loadAppUpTimeFromAppData():void
        {
            const fs:FileStream = new FileStream();

            if (FileManager.appUpTimePath.exists)
            {
                fs.open(FileManager.appUpTimePath, FileMode.READ);
                const appUpTime:int = fs.readInt();
                ActivityWorkTimer.updateAppUpTime(appUpTime);
                fs.close();
                trace('appUpTime',appUpTime);
            }
        }

        public static function saveAppSatate():void
        {
            const appStateObject:AppStateVars = new AppStateVars();
            appStateObject.canvasZoomIndex = CanvasController.canvasZoomIndex;
            appStateObject.canvasZoomedMultiplier = (CaptureController.isCaptureModeON) ? CaptureController.drawModeCanvasStateForSaveAppState.z : CanvasController.canvasZoomMultipler;

            appStateObject.canvasPanelX = (CaptureController.isCaptureModeON) ? CaptureController.drawModeCanvasStateForSaveAppState.px : CanvasController.canvasPanel.x;
            appStateObject.canvasPanelY = (CaptureController.isCaptureModeON) ? CaptureController.drawModeCanvasStateForSaveAppState.py : CanvasController.canvasPanel.y;

            appStateObject.canvasAnchorPointX = (CaptureController.isCaptureModeON) ? CaptureController.drawModeCanvasStateForSaveAppState.x : CanvasController.canvasAnchorPoint.x;
            appStateObject.canvasAnchorPointY = (CaptureController.isCaptureModeON) ? CaptureController.drawModeCanvasStateForSaveAppState.y : CanvasController.canvasAnchorPoint.y;
            appStateObject.canvasAnchorPointRotation = (CaptureController.isCaptureModeON) ? CaptureController.drawModeCanvasStateForSaveAppState.r : CanvasController.canvasAnchorPoint.rotation;

            appStateObject.penSmoothValue = PenTool.penSmoothValue;
            appStateObject.penSmoothSlideValue = PenTool.penSmoothSlideValue;
            appStateObject.penSmoothButtonX = ToolController.toolOptionsBox.penSmoothSliderCursor.x;

            appStateObject.penSize = PenTool.penSize;
            appStateObject.penSizeIndex = PenTool.penSizeIndex;
            appStateObject.penColor = PenTool.penColor;
            appStateObject.penAlpha = PenTool.penAlpha;
            appStateObject.penIsSquare = PenTool.penIsSquare;

            appStateObject.eraseSize = PenTool.eraserSize;
            appStateObject.eraseSizeIndex = PenTool.eraserSizeIndex;
            appStateObject.eraserIsSquare = PenTool.eraserIsSquare;
            appStateObject.eraseAlpha = PenTool.eraserAlpha;

            const windowBounds:Rectangle = main.stage.nativeWindow.bounds;
            appStateObject.stageNativeWindowX = windowBounds.x;
            appStateObject.stageNativeWindowY = windowBounds.y;
            appStateObject.stageNativeWindowWidth = windowBounds.width;
            appStateObject.stageNativeWindowHeight = windowBounds.height;

            appStateObject.saveFileName = FileManager.lastSaveFileName;
            appStateObject.lastWindowState = MainUIController.lastAppWindowState;
            appStateObject.uiColorIndex = Global.getUIColorIndex();
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

            appStateObject.isCanvasMirrored = CanvasController.isCanvasMirrored;

            appStateObject.gridValue = CanvasGridOverlay.gridGapMultiplier;
            appStateObject.hsvColorData0 = ColorPickerController.hsvColorData[0];
            appStateObject.gridDrawOffsetX = CanvasGridOverlay.gridDrawOffsetX;
            appStateObject.gridDrawOffsetY = CanvasGridOverlay.gridDrawOffsetY;

            appStateObject.hueCursorX = ColorPickerController.colorPickerBox.hueCursor.x;
            appStateObject.svBaseColor = ColorPickerController.colorPickerBox.svBaseColor;
            appStateObject.isHSVInfoTextMode = ColorPickerController.isHSVInfoTextMode;

            appStateObject.rReplayImageCacheState = (ReplayController.isGeneratingCacheImages()) ? ReplayController.REPLAY_IMAGE_CAHCHE_READY : ReplayController.rReplayImageCacheState;
            appStateObject.rLastCanvasBGColor = ReplayController.rLastCanvasBGColor;

            appStateObject.isRightSidebar = SidebarController.isRightSidebar;
            appStateObject.saveFilePath = FileManager.lastSaveFilePath;
            appStateObject.isSidebarVisible = SidebarController.isSidebarVisible;
            appStateObject.uiScaleIndex = Global.getUIScaleIndex();

            appStateObject.canvasWindowON = ImageViewWindow.isCanvasWindowON;

            appStateObject.newWindowInfo0 = ImageViewWindow.canvasWindowInfo[0];
            appStateObject.newWindowInfo1 = ImageViewWindow.canvasWindowInfo[1];
            appStateObject.newWindowInfo2 = ImageViewWindow.canvasWindowInfo[2];
            appStateObject.newWindowInfo3 = ImageViewWindow.canvasWindowInfo[3];

            appStateObject.getFirstRCursorPosX = ReplayController.drawReplayByCommand.getFirstRCursorPos().x;
            appStateObject.getFirstRCursorPosY = ReplayController.drawReplayByCommand.getFirstRCursorPos().y;

            appStateObject.myPalettePresetType = PaletteController.myPalettePresetType;
            appStateObject.isMyPaletteExpended = PaletteController.isMyPaletteExpended;
            appStateObject.isColorPickerBoxPositionSwapped = ColorPickerController.isColorPickerBoxPositionSwapped;

            appStateObject.captureStampText = MainUI.topBar.captureInput.text;
            appStateObject.isCaptureStampON = CaptureController.isCaptureStampEnabled;
            appStateObject.captureStampFont = CaptureController.captureStampManager.getFontName();

            appStateObject.scrollSetMovedY = SidebarController.scrollSetMovedY;
            appStateObject.isRefLayerMemoryTrainingON = ReferenceLayerController.isRefLayerMemoryTrainingON;

            const fs:FileStream = new FileStream();
            fs.open(FileManager.appStateFilePath, FileMode.WRITE);
            fs.writeObject(appStateObject);
            fs.close();
        }

        public static function loadAppState():void
        {
            const fs:FileStream = new FileStream();
            var arr:Array = [];
            var newRectangle:Rectangle;

            const firstCachedImage:File = FileManager.replayCacheImageFolderPath.resolvePath("0");

            // 앱 경로에 마지막 저장 파일이 있으면 끄기전의 상태로 세팅해줌
            if (firstCachedImage.exists)
            {
                fs.open(firstCachedImage, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();

                if (arr[1] is ByteArray === false)
                {
                    arr[0].uncompress();
                    newRectangle = new Rectangle(0, 0, arr[1], arr[2]);

                    if (ReplayController.rFirstImageLayer1BitmapData)
                    {
                        ReplayController.rFirstImageLayer1BitmapData.dispose();
                    }
                    ReplayController.rFirstImageLayer1BitmapData = new BitmapData(arr[1], arr[2], true, 0);
                    ReplayController.rFirstImageLayer1BitmapData.lock();
                    ReplayController.rFirstImageLayer1BitmapData.setPixels(newRectangle, arr[0]);
                    ReplayController.rFirstImageLayer1BitmapData.unlock();

                    if (ReplayController.rFirstImageLayer2BitmapData)
                    {
                        ReplayController.rFirstImageLayer2BitmapData.dispose();
                    }
                    ReplayController.rFirstImageLayer2BitmapData = new BitmapData(arr[1], arr[2], true, 0);

                    ReplayController.rFirstImageBGColor = arr[3];
                }
                else
                {
                    arr[0].uncompress();
                    newRectangle = new Rectangle(0, 0, arr[2], arr[3]);

                    if (ReplayController.rFirstImageLayer1BitmapData)
                        ReplayController.rFirstImageLayer1BitmapData.dispose();
                    ReplayController.rFirstImageLayer1BitmapData = new BitmapData(arr[2], arr[3], true, 0);
                    ReplayController.rFirstImageLayer1BitmapData.lock();
                    ReplayController.rFirstImageLayer1BitmapData.setPixels(newRectangle, arr[0]);
                    ReplayController.rFirstImageLayer1BitmapData.unlock();

                    arr[1].uncompress();

                    if (ReplayController.rFirstImageLayer2BitmapData)
                        ReplayController.rFirstImageLayer2BitmapData.dispose();
                    ReplayController.rFirstImageLayer2BitmapData = new BitmapData(arr[2], arr[3], true, 0);
                    ReplayController.rFirstImageLayer2BitmapData.lock();
                    ReplayController.rFirstImageLayer2BitmapData.setPixels(newRectangle, arr[1]);
                    ReplayController.rFirstImageLayer2BitmapData.unlock();

                    ReplayController.rFirstImageBGColor = arr[4];
                }
            }
            else
            {
                ReplayController.rFirstImageLayer1BitmapData.dispose();
                ReplayController.rFirstImageLayer2BitmapData.dispose();

                ReplayController.rFirstImageLayer1BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
                ReplayController.rFirstImageLayer2BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
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
                tmpbmpd.setPixels(newRectangle, arr[0]);
                tmpbmpd.unlock();

                ReferenceLayerController.canvasRefLayerBitmapData = CanvasController.updateBitmapData(ReferenceLayerController.canvasRefLayerBitmapData, tmpbmpd, ReferenceLayerController.canvasRefLayerBitmap);
                ReferenceLayerController.canvasRefLayerBitmap.smoothing = true;

                tmpbmpd.dispose();
                tmpbmpd = null;
            }

            if (FileManager.replayCacheImageFrameDataFilePath.exists)
            {
                fs.open(FileManager.replayCacheImageFrameDataFilePath, FileMode.READ);
                arr = fs.readObject() as Array;
                fs.close();

                ReplayController.rJumpImageFrameData = arr.concat();
            }

            if (FileManager.myPaletteDataFilePath.exists)
            {
                fs.open(FileManager.myPaletteDataFilePath, FileMode.READ);
                var list:Array = fs.readObject();
                fs.close(); // 기존 코드에 없던 항목 변경을 막기 위해 유지

                PaletteController.myPalettePreset = list.concat();
                list.length = 0;
                list = null;
            }

            if (FileManager.undoDataFilePath.exists)
            {
                FileManager.loadUndoData(); // ReplayController.undo data 복구 먼저 해줘야함
            }

            if (FileManager.scratchPadDataFilePath.exists)
            {
                FileManager.loadScratchPadImage();
            }

            if (FileManager.appStateFilePath.exists)
            {
                fs.open(FileManager.appStateFilePath, FileMode.READ);
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

                        MainUIController.lastAppWindowSize.width = appStateObject.stageNativeWindowWidth;
                        MainUIController.lastAppWindowSize.height = appStateObject.stageNativeWindowHeight;

                        // 캔버스 위치까지 전부 다해준 다음에 이전 상태가 풀스크린이었으면 세팅해줌
                        if (appStateObject.lastWindowState === 1)
                            main.stage.nativeWindow.maximize();

                        // UI Scale & Color
                        Global.setScaleIndex(appStateObject.uiScaleIndex);
                        MainUIController.applyUIScale();
                        Global.setUIColorIndex(appStateObject.uiColorIndex);
                        MainUIController.applyUIColorSet();

                        // Canvas Settings
                        CanvasController.canvasZoomIndex = appStateObject.canvasZoomIndex;
                        CanvasController.updateCanvasScale(appStateObject.canvasZoomedMultiplier);

                        CanvasController.canvasPanel.x = appStateObject.canvasPanelX;
                        CanvasController.canvasPanel.y = appStateObject.canvasPanelY;

                        CanvasController.canvasAnchorPoint.x = appStateObject.canvasAnchorPointX;
                        CanvasController.canvasAnchorPoint.y = appStateObject.canvasAnchorPointY;
                        CanvasController.canvasAnchorPoint.rotation = appStateObject.canvasAnchorPointRotation;

                        main.setRcursorRotation(appStateObject.canvasAnchorPointRotation);
                        MainUIController.updateResizeButtonPos(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
                        CanvasController.canvasRotateCursor.rotateArrow.rotation = appStateObject.canvasAnchorPointRotation;

                        // Pen Tool Settings
                        PenTool.penSmoothValue = appStateObject.penSmoothValue;
                        PenTool.penSmoothSlideValue = appStateObject.penSmoothSlideValue;
                        ToolController.toolOptionsBox.penSmoothSliderCursor.x = appStateObject.penSmoothButtonX;

                        PenTool.penSize = appStateObject.penSize;
                        PenTool.penColor = appStateObject.penColor;

                        // Color Picker
                        ColorPickerController.hsvColorData[0] = appStateObject.hsvColorData0; // 순서 중요 이게 먼저오고 밑에 rgb info갱신해주어야함
                        ColorPickerController.isHSVInfoTextMode = appStateObject.isHSVInfoTextMode;
                        ColorPickerController.updatePickerCurrentColor(PenTool.penColor);
                        ColorPickerController.updateColorPickerCursorPosAndRGBInfo(PenTool.penColor);
                        ColorPickerController.colorPickerBox.updateHueColor(appStateObject.svBaseColor);
                        ColorPickerController.colorPickerBox.hueCursor.x = appStateObject.hueCursorX;

                        // Draw Tool Alpha & Shape
                        PenTool.penAlpha = appStateObject.penAlpha;
                        PenTool.penAlphaIndex = PenTool.penAlphaList.indexOf(appStateObject.penAlpha);
                        ToolController.updateDrawToolAlpha(appStateObject.penAlpha);

                        PenTool.penIsSquare = appStateObject.penIsSquare;
                        PenTool.penListShapeIsSqare = appStateObject.penIsSquare;
                        ToolController.toolOptionsBox.updatePenShapeSet(appStateObject.penIsSquare);

                        // Eraser Settings
                        PenTool.eraserSize = appStateObject.eraseSize;
                        PenTool.eraserIsSquare = appStateObject.eraserIsSquare;
                        PenTool.eraserAlpha = appStateObject.eraseAlpha;
                        PenTool.eraserAlphaIndex = PenTool.penAlphaList.indexOf(appStateObject.eraseAlpha);
                        PenTool.eraserSizeIndex = appStateObject.eraseSizeIndex;
                        ToolController.setDrawToolSize(appStateObject.penSizeIndex);

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
                        SidebarController.isRightSidebar = appStateObject.isRightSidebar;
                        SidebarController.isSidebarVisible = appStateObject.isSidebarVisible;

                        if (appStateObject.isRightSidebar)
                            SidebarController.moveSideBar("right", true);

                        if (!appStateObject.isSidebarVisible)
                            SidebarController.hideSidebarPermanent();

                        // Replay Controller
                        ReplayController.rReplayImageCacheState = appStateObject.rReplayImageCacheState;
                        ReplayController.rLastCanvasBGColor = appStateObject.rLastCanvasBGColor;
                        ReplayController.drawReplayByCommand.setFirstRCursorPos(appStateObject.getFirstRCursorPosX, appStateObject.getFirstRCursorPosY);

                        ReferenceLayerController.updateRefLayerImageTransform(
                                appStateObject.canvasRefLayerBitmapX,
                                appStateObject.canvasRefLayerBitmapY,
                                appStateObject.canvasRefLayerRotation,
                                appStateObject.canvasRefLayerScaleX,
                                appStateObject.canvasRefLayerScaleY
                            );

                        if (CanvasController.isCanvasMirrored !== appStateObject.isCanvasMirrored)
                            CanvasController.mirrorCanvas(true);

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

                        ReplayController.rDataIndex = UndoManager.undoDataIndex;
                        ReplayController.rNowFrame = UndoManager.getNowFrameUntilUndoIndex(UndoManager.undoDataIndex);
                        ReplayController.rPrevFrame = UndoManager.getNowFrameUntilUndoIndex(UndoManager.undoDataIndex - 1);

                        // 혹시 몰라서 위치 체크 해줌
                        CanvasController.canvasInfoBox.setRotate(CanvasController.canvasAnchorPoint.rotation);
                        CanvasController.centerCanvas("replay");
                        CanvasController.keepCanvasPanelInStage();
                        CanvasController.keepCanvasPanelInStage(true);

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

                        MainUI.topBar.captureInput.text = appStateObject.captureStampText;
                        CaptureController.isCaptureStampEnabled = appStateObject.isCaptureStampON;

                        if (appStateObject.captureStampFont)
                        {
                            CaptureController.captureStampManager.changeFont(appStateObject.captureStampFont, false);
                        }

                        MainUIController.updateCanvasNaigatorCursor();
                        main.updatePenSizeCursor();
                        MainUIController.updateWindowTitle();
                        CanvasController.selectLayer1(false);
                    });
            }
            else // 복원파일이 없을때
            {
                if (FileManager.lastSaveFilePath === FileManager.lastSaveFileName)
                {
                    FileManager.lastSaveFilePath = File.desktopDirectory.nativePath + File.separator + FileManager.lastSaveFileName;
                }

                PaletteController.initializeMyPaletteList();

                MainUIController.lastAppWindowSize.width = 1000;
                MainUIController.lastAppWindowSize.height = 800;

                FOFOTimer.add(0.3, true, function ():Boolean
                    {
                        if (main.stage.nativeWindow.width === 1000 && main.stage.nativeWindow.height === 800)
                        {
                            CanvasController.centerCanvas("draw");
                            return false;
                        }

                        main.stage.nativeWindow.width = MainUIController.lastAppWindowSize.width;
                        main.stage.nativeWindow.height = MainUIController.lastAppWindowSize.height;
                        return true;
                    });

                CanvasController.updateCavnvasSizeDrawMode(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, 0, 0, false);
                MainUIController.updateResizeButtonPos(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);

                ColorPickerController.updatePickerCurrentColor(PenTool.penColor);
                ColorPickerController.updateColorPickerCursorPosAndRGBInfo(PenTool.penColor);

                AboutBoxController.openAboutBox(true);
                MainUIController.applyUIColorSet();
                MainUIController.updateCanvasNaigatorCursor();

                CanvasController.canvasInfoBox.init(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, Math.floor(CanvasController.canvasZoomMultipler * 100), CanvasController.canvasAnchorPoint.rotation, false);
                CanvasController.selectLayer1(false);

                PaletteController.initMyPaletteHistory();
            }

            loadAppUpTimeFromAppData();
        }
    }
}
