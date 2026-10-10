package Modules.L5App
{

    import flash.desktop.ClipboardFormats;
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.InvokeEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.NativeDragEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Rectangle;
    import flash.net.FileFilter;
    import flash.net.URLRequest;
    import flash.net.navigateToURL;
    import flash.utils.ByteArray;
    import flash.utils.getTimer;

    import libwebp.DecodeWebp;
    import flash.display.IBitmapDrawable;
    import flash.geom.Matrix;
    import Modules.L4UI.CanvasGridOverlay;
    import Modules.L4UI.ColorPickerController;
    import Modules.L5App.InputManager.DrawModeInput;
    import Modules.L4UI.ImageViewWindow;
    import Modules.L5App.ReplayEngine.ReplayController;
    import Modules.L5App.InputManager.ReplayModeInput;
    import Modules.L4UI.Tools.ToolPanel;
    import Modules.L3Feature.UndoController;
    import Modules.L1Data.KeyState;
    import Modules.L2Engine.BackgroundWorkerCoordinator;
    import Modules.L2Engine.ReplayEngine.ReplayClock;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.L2Engine.ReplayEngine.ReplayFileCache;
    import Modules.L2Engine.ReplayEngine.TimingSheetFile;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L1Data.AppDataPaths;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L4UI.PenSizePreviewCursor;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L2Engine.ReplayEngine.ReplayDrawCommands;
    import Modules.L2Engine.UndoHistory;
    import Modules.L4UI.DrawEngine.CanvasResizer;
    import Modules.L2Engine.ReplayEngine.ReplayState;
    import Modules.L1Data.ReplayEngine.ReplaySaveMetaData;
    import Modules.L4UI.HintStrings;
    import Modules.L3Feature.DrawEngine.CanvasLayers;
    import Modules.L1Data.Utils;
    import Modules.L4UI.Tools.PenTool;
    import Modules.L4UI.Tools.LineTool;
    import Modules.L4UI.Tools.FillPenTool;
    import Modules.L4UI.Tools.LassoTool;
    import Modules.L4UI.Tools.ToolController;
    import Modules.L4UI.CaptureEngine.CaptureController;
    import Modules.L4UI.CaptureEngine.CaptureStamp;
    import Modules.L4UI.ReferenceLayerController;
    import Modules.L4UI.UIEngine.CanvasNavigator;
    import Modules.L1Data.FOFOTimer;
    import Modules.L1Data.NativeSave;
    import Modules.L1Data.PixelRestore;
    import Modules.L1Data.ReplayDataCodec;
    import Modules.L1Data.UIEngine.UITheme;

    // 층: L5 앱 흐름 - 파일(.fofo, 이미지) 불러오기와 저장, 불러온 뒤 캔버스 초기화
    public class FileManager
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }
        public static const REPLAY_FILE_HEADER_V1:String = "FOFOPAINT"; // 리플레이 블록이 zlib
        public static const REPLAY_FILE_HEADER_V2:String = "V2FOFOPAINT"; // 리플레이 블록이 ReplayDataCodec, 이전 버전 앱에서 못 읽음

        // todo gpt한테 이 변수 곳곳에 쓰이는데 이를 최적화로  종합적으로 관리가 가능한지 묻기 아마 캔버스가 변경될때에만 내려주면 될것같은데 과연?
        public static var isFileAlreadySaved:Boolean = false; // 세이브 버튼 여러번 눌러서 데이터 계속 쓰여지는거 방지
        public static var isContinueSaveON:Boolean = false; // 한번 저장후에 다른이름으로 저장하기 전까지는 똑같은 이름으로 저장
        private static var pendingInvokeArguments:Array; // 앱 상태 복원이 끝나기 전에 받은 invoke 인자
        public static var saveStartTime:int = 0; // saveFOFOFile 호출 시각, 저장 완료 힌트에 걸린 시간 표시용
        public static var lastSaveFileName:String = getRandomFileName(); // 세이브 파일 저장후에 이름을 이쪽에다가 보관해서 계속 그 이름으로 저장할수있게함
        public static var lastSaveFilePath:String = lastSaveFileName; // 파일 저장경로로 계속 저장 초기에는 filename이랑 똑같게 해줌
        private static var lastSaveCaptureFilePath:String = lastSaveFileName;
        private static var rLayer1FirstImageData:ByteArray = new ByteArray(); // 리플레이 데이터 저장해줄때 쓰는 바이트 배열 전역으로 돌려서 새로운 객체 하나만 생성하도록함
        private static var rLayer2FirstImageData:ByteArray = new ByteArray();
        private static var rLayer1CurrentImageData:ByteArray = new ByteArray();
        private static var rLayer2CurrentImageData:ByteArray = new ByteArray();
        private static var replayDataReadBytes:ByteArray = new ByteArray();

        private static var isNewFileAvailable:Boolean = true; // 새 파일 만들기 가능 여부, 아이콘 alpha는 refreshFileOperationButtonsTopbar에서 잠금 상태와 합쳐서 계산

        public static function loadFOFOFile(oldFile:File):void // loadrep
        {
            if (isTrue2020File(oldFile) === false)
            {
                LoadBoxController.showLoadFaildMouseHint();
                return;
            }

            const fs:FileStream = new FileStream();
            var imgStartByte:uint = 0;
            var imgW:uint = 0;
            var imgH:uint = 0;
            var bg:uint = 0;
            const rect:Rectangle = new Rectangle();
            ReplayFileCache.initializeReplayDataFile(true); // 일단 썸네일 이미지랑 리플레이 데이터 청소\
            oldFile.copyTo(ReplayFileCache.repFileTemp, true); // repdata.c3p를 복사 덮어씌우기

            if (ReferenceLayerController.refLayerRawTransformData)
            {
                ReferenceLayerController.refLayerRawBitmapData.dispose();
                ReferenceLayerController.refLayerRawBitmapData = null;
                ReferenceLayerController.refLayerRawTransformData = null;
            }

            fs.open(ReplayFileCache.repFileTemp, FileMode.READ);
            ReplayFileCache.rJumpImageFrameData = [0];
            var d:Array;
            var ba:ByteArray;
            var replayData:ByteArray = new ByteArray();
            const headerLength:int = get2020FileHeaderLength(oldFile);
            const isNew2020FileFlag:Boolean = headerLength > 0;

            if (isNew2020FileFlag)
            {
                fs.readUTFBytes(headerLength); // FOFOPAINT / V2FOFOPAINT 헤더 읽어줌
                const compBytes:uint = fs.readUnsignedInt(); // 압축된 데이터 길이 읽어줌

                if (compBytes > 0)
                {
                    // 압축된 데이터 써주고 압축 풀어줌
                    fs.readBytes(replayData, 0, compBytes);
                    if (headerLength === REPLAY_FILE_HEADER_V2.length)
                    {
                        const decodedReplayData:ByteArray = ReplayDataCodec.decodeAuto(replayData); // 네이티브가 있으면 네이티브로
                        replayData.clear();
                        replayData = decodedReplayData;
                    }
                    else
                    {
                        replayData.uncompress();
                    }
                }
            }

            while (true)
            {
                if (fs.bytesAvailable === 0)
                {
                    break;
                }

                d = fs.readObject();

                if (d[0] === "rFirstImage")
                {
                    if (d[2] is ByteArray === false) // 구버전
                    {
                        ba = d[1] as ByteArray;
                        rect.setTo(0, 0, d[2], d[3]);
                        ba.uncompress();
                        ReplayFileCache.rFirstImageLayer1BitmapData = new BitmapData(d[2], d[3], true, 0);
                        ReplayFileCache.rFirstImageLayer1BitmapData.lock();
                        PixelRestore.setPixels(ReplayFileCache.rFirstImageLayer1BitmapData, rect, ba);
                        ReplayFileCache.rFirstImageLayer1BitmapData.unlock();
                        ba.clear();
                        ba = null;
                        ReplayDrawer.updateCanvasBGColorReplayMode(d[4]);
                        ReplayFileCache.createFirstImageCache(ReplayFileCache.rFirstImageLayer1BitmapData, null, d[4]);
                    }
                    else // 신버전
                    {
                        ba = d[1] as ByteArray;
                        rect.setTo(0, 0, d[3], d[4]);
                        ba.uncompress();
                        ReplayFileCache.rFirstImageLayer1BitmapData = new BitmapData(d[3], d[4], true, 0);
                        ReplayFileCache.rFirstImageLayer1BitmapData.lock();
                        PixelRestore.setPixels(ReplayFileCache.rFirstImageLayer1BitmapData, rect, ba);
                        ReplayFileCache.rFirstImageLayer1BitmapData.unlock();
                        ba.clear();
                        ba = d[2] as ByteArray;
                        ba.uncompress();
                        ReplayFileCache.rFirstImageLayer2BitmapData = new BitmapData(d[3], d[4], true, 0);
                        ReplayFileCache.rFirstImageLayer2BitmapData.lock();
                        PixelRestore.setPixels(ReplayFileCache.rFirstImageLayer2BitmapData, rect, ba);
                        ReplayFileCache.rFirstImageLayer2BitmapData.unlock();
                        ba.clear();
                        ba = null;
                        ReplayDrawer.updateCanvasBGColorReplayMode(d[5]);
                        // air sdk 이전이후 첫 패치된거라서 값이 있으면 읽어주어야함 불리언 값
                        const firstMirrorFlag:Boolean = d.length > 6 && d[6] === true;
                        if (d[6])
                        {
                            ReplayState.rMirrorON = firstMirrorFlag;
                        }
                        ReplayFileCache.createFirstImageCache(ReplayFileCache.rFirstImageLayer1BitmapData, ReplayFileCache.rFirstImageLayer2BitmapData, d[5], firstMirrorFlag); // 0.cache 파일 갱신
                    }
                }
                else if (d[0] === "rFinalImage")
                {
                    // 아래에서 imgStartByte로 세고있어서 이걸 안넣으면 바이트 읽기 순서가 어긋남 지우면 안됨
                }
                else if (d[0] === "rTimingSheet")
                {
                    TimingSheetFile.loadFileObject(d);
                }
                else if (d[0] === "refimage" || d[0] === "traceImage")
                {
                    ba = d[1] as ByteArray;
                    rect.setTo(0, 0, d[2], d[3]);
                    ba.uncompress();
                    ReferenceLayerController.refLayerRawBitmapData = new BitmapData(d[2], d[3], true, 0);
                    ReferenceLayerController.refLayerRawBitmapData.lock();
                    PixelRestore.setPixels(ReferenceLayerController.refLayerRawBitmapData, rect, ba);
                    ReferenceLayerController.refLayerRawBitmapData.unlock();
                    ba.clear();
                    ba = null;
                    d[0] = null;
                    d[1] = null;
                    ReferenceLayerController.refLayerRawTransformData = d.concat();
                }
                else if (isNew2020FileFlag) // 신포멧인데 rData옛 버전에서rData압축안하고 넣어준거 읽어줌
                {
                    replayData.position = replayData.length;
                    replayData.writeObject(d);
                }
                else
                {
                    imgStartByte = fs.position;
                }
            }

            fs.close();

            if (isNew2020FileFlag)
            {
                fs.open(AppDataPaths.replayDataFilePath, FileMode.WRITE);
                fs.position = 0;
                fs.writeBytes(replayData);
                fs.close();
            }
            else
            {
                // 이미지직전까지 바이트를 기준으로 짤라줌, 즉 뒤에 붙은 첫 이미지 + 마지막 이미지를 지워줌
                fs.open(ReplayFileCache.repFileTemp, FileMode.UPDATE);
                fs.position = imgStartByte;
                fs.truncate();
                fs.close();
                ReplayFileCache.repFileTemp.moveTo(AppDataPaths.replayDataFilePath, true);
            }

            ReplayDrawer.commandWindow.dispose(); // repdata가 바뀌었으니 미리 읽은 묶음은 버림

            if (ReplayFileCache.repFileTemp.exists)
            {
                ReplayFileCache.repFileTemp.deleteFile();
            }

            replayData.clear();
            replayData = null;
            finalizeLoadFile(0, 0, null, null, false, 0);
            ReplayController.startGeneratingReplayCacheImage(true, null);
        }

        public static function loadImageFile(width:Number, height:Number, layer1Image:IBitmapDrawable, layer2Image:IBitmapDrawable):void
        {
            ReplayState.setRFileDataTotalFrame(0);
            ReplayClock.rebuildFileIndex();
            ReplayController.updateTotalFrameAndReplayMaxSpeedFor10Sec(0);
            ReplayState.rReplayImageCacheState = ReplayState.REPLAY_IMAGE_CAHCHE_COMPLETE;
            ReferenceLayerController.refLayerRawBitmapData = null;
            ReferenceLayerController.refLayerRawTransformData = null;
            finalizeLoadFile(width, height, layer1Image, layer2Image, true, 0xFFFFFF);
            ReplayFileCache.initializeReplayDataFile(true); // 일단 썸네일 이미지랑 리플레이 데이터 청소
            ReplayFileCache.createFirstImageCache(DrawCanvas.canvasLayer1BitmapData, DrawCanvas.canvasLayer2BitmapData, DrawCanvas.CANVAS_BG_COLOR);
        }

        public static function resetDrawAndReplayCanvasState(canvasWidth:Number, canvasHeight:Number):void
        {
            CanvasView.canvasAnchorPoint.rotation = 0;
            ReplayDrawer.setRcursorRotation(0);
            CanvasView.canvasZoomIndex = 3;
            CanvasView.viewport.setScale(1.0);
            DrawCanvas.setCanvasSizeDrawMode(canvasWidth, canvasHeight, 0, 0, false);
            CanvasView.updateCanvasPanelColorAndSize();
            ReplayDrawer.setReplayCanvasBmpdFromDrawMode();
            ReplayController.setReplayCanvasStateFromDrawMode();
            CanvasView.viewport.centerIn("draw");
        }

        public static function finalizeLoadFile(width:uint, height:uint, imageData:IBitmapDrawable, imageData1:IBitmapDrawable, imageOnlyFlag:Boolean, bgColor:uint):void
        {
            if (CaptureController.isCaptureModeON)
            {
                CaptureController.handleExitCaptureMode();
            }

            ReplayController.resetReplaySpeedBar();
            ReplayController.resetReplayTime();
            ReplayDrawer.clearCanvasReplayMode();
            ReplayController.updateReplayPrograssText(true, 0);
            UIController.seekBarBox.resetReplayPrograssBarWidth();

            if (bgColor > 0)
            {
                DrawCanvas.setCanvasBGColorDrawMode(bgColor);
                ReplayDrawer.updateCanvasBGColorReplayMode(bgColor);
            }

            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowBGColor(DrawCanvas.CANVAS_BG_COLOR, ImageViewWindow.canvasWindowLayer1Bitmap.bitmapData);
            }

            // updateLastFilePathByRandomFileName();
            isContinueSaveON = false; // 연속 세이브 플래그 취소
            ReplayState.rMirrorON = false;
            DrawCanvas.mirrorON = false;
            ReplayState.mirrorCommandReady = false;
            UIController.canvasInfoBox.setMirror(false);
            CanvasGridOverlay.updateGridMirror(false);
            LassoTool.cancelIfActive();

            if (FillPenTool.isStarted)
            {
                FillPenTool.cancel();
            }
            else if (LineTool.isStarted)
            {
                LineTool.cancel();
            }

            if (width > 0 && height > 0 && (imageData || imageData1))
            {
                var maxLength:Number = (width > height) ? width : height;
                var scaleLimitMultiplier:Number = (maxLength > DrawCanvas.CANVAS_MAX_SIZE) ? DrawCanvas.CANVAS_MAX_SIZE / maxLength : 1.0;
                // CANVAS_MAX_SIZE 값을 넘으면 리사이즈 해줌 최소길이는 1ㅎ
                const limitedImageWidth:int = Math.max(1, Math.floor(width * scaleLimitMultiplier));
                const limitedImageHeight:int = Math.max(1, Math.floor(height * scaleLimitMultiplier));
                var scaleMat:Matrix = new Matrix();
                scaleMat.scale(scaleLimitMultiplier, scaleLimitMultiplier);
                // 최종표시이미지 깔아주ㄱ load fofo에서는 리플레이 명령그대로 입력을 최종 깔아주므로 필요가 없음
                var tmpbmpd:BitmapData = new BitmapData(limitedImageWidth, limitedImageHeight, true, 0);

                if (imageData !== null)
                {
                    tmpbmpd.draw(imageData, scaleMat, null, null, null, true);
                    DrawCanvas.canvasLayer1BitmapData = DrawCanvas.updateBitmapData(DrawCanvas.canvasLayer1BitmapData, tmpbmpd, DrawCanvas.canvasLayer1Bitmap);

                    if (imageOnlyFlag)
                    {
                        if (ReplayFileCache.rFirstImageLayer1BitmapData && tmpbmpd !== ReplayFileCache.rFirstImageLayer1BitmapData)
                            ReplayFileCache.rFirstImageLayer1BitmapData.dispose();
                        ReplayFileCache.rFirstImageLayer1BitmapData = tmpbmpd.clone(); // 이미지만 불러와주면 첫 이미지를 갱신해줌
                    }
                }

                if (imageData1 !== null)
                {
                    tmpbmpd.fillRect(new Rectangle(0, 0, limitedImageWidth, limitedImageHeight), 0);
                    tmpbmpd.draw(imageData1, scaleMat, null, null, null, true);
                    DrawCanvas.canvasLayer2BitmapData = DrawCanvas.updateBitmapData(DrawCanvas.canvasLayer2BitmapData, tmpbmpd, DrawCanvas.canvasLayer2Bitmap);
                    if (imageOnlyFlag)
                    {
                        ReplayFileCache.rFirstImageLayer2BitmapData = tmpbmpd.clone();
                    }
                }
                else
                {
                    DrawCanvas.canvasLayer2BitmapData = new BitmapData(DrawCanvas.canvasLayer1BitmapData.width, DrawCanvas.canvasLayer1BitmapData.height, true, 0);
                    DrawCanvas.canvasLayer2Bitmap.bitmapData = DrawCanvas.canvasLayer2BitmapData;
                }

                tmpbmpd.dispose();
                tmpbmpd = null;
                resetDrawAndReplayCanvasState(limitedImageWidth, limitedImageHeight);
                UndoController.resetUndoState();
            }

            PenSizePreviewCursor.updateSizeAndShape();
            if (CanvasGridOverlay.gridGapMultiplier > 0)
            {
                CanvasGridOverlay.drawGrid();
            }

            ReplayDrawCommands.resetFirstRCursorPos();
            if (ReferenceLayerController.refLayerRawTransformData === null)
            {
                ReferenceLayerController.clearRefLayerImage();
            }
            else
            {
                ReferenceLayerController.canvasRefLayerBitmapData = ReferenceLayerController.refLayerRawBitmapData.clone();
                ReferenceLayerController.canvasRefLayerBitmap.bitmapData = ReferenceLayerController.canvasRefLayerBitmapData;
                ReferenceLayerController.updateRefLayerImageTransform(ReferenceLayerController.refLayerRawTransformData[4],
                        ReferenceLayerController.refLayerRawTransformData[5],
                        ReferenceLayerController.refLayerRawTransformData[6],
                        ReferenceLayerController.refLayerRawTransformData[7],
                        ReferenceLayerController.refLayerRawTransformData[8]);
                ReferenceLayerController.refLayerMenuDragXMoveSum = ReferenceLayerController.refLayerRawTransformData[10];
                ReferenceLayerController.refLayerLastAlpha = ReferenceLayerController.refLayerRawTransformData[11];
                ReferenceLayerController.canvasRefLayer.visible = true;
                ReferenceLayerController.canvasRefLayer.alpha = Utils.normalizeAlphaValue(ReferenceLayerController.refLayerRawTransformData[11]);
                ReferenceLayerController.updateRefLayerOpacityCursorPosByValue(ReferenceLayerController.refLayerRawTransformData[11]);
                ReferenceLayerController.refLayerRawBitmapData.dispose();
                ReferenceLayerController.refLayerRawBitmapData = null;
                ReferenceLayerController.refLayerRawTransformData = null;
                ReferenceLayerController.canvasRefLayerBitmap.smoothing = true;
            }
            AppWindowState.updateWindowTitle();
            CanvasLayers.selectLayer(1, false);
            ReplayDrawer.selectReplaySubLayer(false);
            if (CanvasLayers.checkedLayer === 1)
            {
                CanvasLayers.toggleLayerCheck(1);
            }
            if (CanvasLayers.checkedLayer === 2)
            {
                CanvasLayers.toggleLayerCheck(2);
            }
            CanvasResizer.updateButtonPos(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT);
            KeyState.removeKeyRepeatEvents(null);
            DrawCanvas.canvasLayer1Bitmap.visible = true;
            DrawCanvas.canvasLayer2Bitmap.visible = true;
            UIController.topBar.captureButton.alpha = 1.0;
            setNewFileAvailable(true);
            ReferenceLayerController.refLayerMenuBox.refTransferCanvasImageButton.alpha = 1.0;
            ColorPickerController.selectCurrentColor(false);
            ToolController.selectPenToolIfNotDrawingTool(false);
            CanvasNavigator.box.updateImage();
            CanvasNavigator.updateCursor();
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
                ImageViewWindow.canvasWindowIgnoreResizeEventFlag = true;
                ImageViewWindow.updateCanvasWindowBitmapSize();
            }
            CaptureController.resetCaptureCanvasChangeValue();
            LoadBoxController.lastLoadedFile = null;
            LoadBoxController.isLoadPendingAfterSaving = false;
            LoadBoxController.closeLoadMenuBox();
        }

        public static function setFileBrowserIsOpen(flag:Boolean):void
        {
            UIController.isFileBrowserOpened = flag;
            KeyState.clearKeyBuffer();
        }

        public static function updateLastFilePathByRandomFileName():void
        {
            const newFileName:String = getRandomFileName();
            lastSaveFileName = newFileName;
            lastSaveFilePath = getDirectoryOnly(lastSaveFilePath) + File.separator + newFileName;
        }

        public static function getRandomFileName():String
        {
            return CaptureStamp.getTimeStampTailHead() + "_" + Utils.getRandomString(8) + ".png";
        }

        public static function enableNewFileButton():void
        {
            setNewFileAvailable(true);
            ToolPanel.setLayerMergeButtonEnabled(true);
            AppWindowState.markWindowTitleAsDirty();
        }

        public static function getFinalBitmapDataFrom2020File(file:File, bgFlag:Boolean):BitmapData
        {
            const fs:FileStream = new FileStream();
            fs.open(file, FileMode.READ);
            var finalIMGBMPD:BitmapData;
            var finalIMGBMPD1:BitmapData;
            const headerLength:int = get2020FileHeaderLength(file);
            if (headerLength > 0)
            {
                fs.readUTFBytes(headerLength); // FOFOPAINT / V2FOFOPAINT 헤더 읽어줌
                const compBytes:uint = fs.readUnsignedInt(); // 압축된 데이터 길이 읽어줌
                fs.position += compBytes;
            }
            var ba:ByteArray;
            var newRectangle:Rectangle;
            var bg:uint;
            while (true)
            {
                if (fs.bytesAvailable === 0)
                    break;
                const d:Array = fs.readObject() as Array;
                if (d[0] === "rFinalImage")
                {
                    // 구버전 파일 레이어 없을때
                    if (d[2] is ByteArray === false)
                    {
                        ba = d[1] as ByteArray;
                        newRectangle = new Rectangle(0, 0, d[2], d[3]);
                        ba.uncompress();
                        finalIMGBMPD = new BitmapData(d[2], d[3], true, 0);
                        finalIMGBMPD.lock();
                        PixelRestore.setPixels(finalIMGBMPD, newRectangle, ba);
                        finalIMGBMPD.unlock();
                        ba.clear();
                        ba = null;
                        bg = d[4];
                    }
                    else
                    {
                        ba = d[2] as ByteArray;
                        newRectangle = new Rectangle(0, 0, d[3], d[4]);
                        ba.uncompress();
                        finalIMGBMPD = new BitmapData(d[3], d[4], true, 0);
                        finalIMGBMPD.lock();
                        PixelRestore.setPixels(finalIMGBMPD, newRectangle, ba);
                        finalIMGBMPD.unlock();
                        ba.clear();
                        ba = d[1] as ByteArray;
                        ba.uncompress();
                        finalIMGBMPD1 = new BitmapData(d[3], d[4], true, 0);
                        finalIMGBMPD1.lock();
                        PixelRestore.setPixels(finalIMGBMPD1, newRectangle, ba);
                        finalIMGBMPD1.unlock();
                        ba.clear();
                        ba = null;
                        bg = d[5];
                        finalIMGBMPD.draw(finalIMGBMPD1);
                        finalIMGBMPD1.dispose();
                    }
                }
            }
            fs.close();
            if (bgFlag)
            {
                const bgBmpd:BitmapData = new BitmapData(finalIMGBMPD.width, finalIMGBMPD.height, false, bg);
                bgBmpd.draw(finalIMGBMPD);
                return bgBmpd;
            }
            return finalIMGBMPD;
        }

        // 열기 실패, 짧은 파일은 false. 어느 경로로 나가도 finally에서 닫아줌
        public static function isNew2020File(file:File):Boolean
        {
            return get2020FileHeaderLength(file) > 0;
        }

        // .fofo / .2020 파일 헤더 길이
        // 0 = 헤더 없는 구버전, 9 = "FOFOPAINT"(zlib 리플레이 블록), 11 = "V2FOFOPAINT"(ReplayDataCodec 블록)
        public static function get2020FileHeaderLength(file:File):int
        {
            if (!file)
            {
                return 0;
            }

            const fs:FileStream = new FileStream();
            var opened:Boolean = false;

            try
            {
                fs.open(file, FileMode.READ);
                opened = true;
                // 이전 버전 앱이 앞 9바이트를 "FOFOPAINT"로 오인하지 않게 V2 헤더는 앞에 붙임
                if (fs.bytesAvailable >= REPLAY_FILE_HEADER_V2.length && fs.readUTFBytes(REPLAY_FILE_HEADER_V2.length) === REPLAY_FILE_HEADER_V2)
                {
                    return REPLAY_FILE_HEADER_V2.length;
                }
                fs.position = 0;
                if (fs.bytesAvailable < REPLAY_FILE_HEADER_V1.length || fs.readUTFBytes(REPLAY_FILE_HEADER_V1.length) !== REPLAY_FILE_HEADER_V1)
                {
                    return 0;
                }
                return REPLAY_FILE_HEADER_V1.length;
            }
            catch (error:Error)
            {
                return 0;
            }
            finally
            {
                if (opened)
                {
                    fs.close();
                }
            }

            return 0; // 실행되지 않음, 컴파일러용
        }

        private static function isOld2020File(file:File):Boolean
        {
            if (!file)
            {
                return false;
            }

            const fs:FileStream = new FileStream();
            var opened:Boolean = false;

            try
            {
                fs.open(file, FileMode.READ);
                opened = true;
                // 구버전 파일 읽기 헤더가 없고 바로 배열임
                const arr:Array = (fs.readObject() as Array);
                return arr !== null && arr[0][0] is String;
            }
            catch (err:Error)
            {
                return false;
            }
            finally
            {
                if (opened)
                {
                    fs.close();
                }
            }

            return false; // 실행되지 않음, 컴파일러용
        }
        public static function isTrue2020File(file:File):Boolean
        {
            if (!file || !(file is File))
                return false;
            if (isNew2020File(file))
            {
                return true;
            }
            if (isOld2020File(file))
            {
                return true;
            }
            return false;
        }

        public static function createNewFile(fromShortcut:Boolean):void
        {
            if (!canCreateNewFile())
            {
                return;
            }
            HintController.startPressHoldKey((!fromShortcut) ? UIController.topBar.newFileButton : null, HintStrings.getNewFileHintString(), null, resetAllCanvasAndReplayData, null, isReplayDataLocked);
        }

        public static function resetAllCanvasAndReplayData():void
        {
            // 길게 누르는 동안 worker가 시작되었을 수 있음
            if (FileManager.isReplayDataLocked())
            {
                FileManager.showReplayDataLockedHint();
                return;
            }
            DrawCanvas.clearCanvas();
            ReplayDrawer.viewport.centerIn("replay");
            CanvasView.viewport.centerIn("draw");
            UIController.resetZoomDrawMode();
            UIController.resetRotationDrawMode();
            ReplayController.resetCanvasAndReplayData();

            // reset vars보다 뒤에 와야함
            // addundo에서 활성화 해주고 있기 때문에
            FileManager.setNewFileAvailable(false);
            AppWindowState.markWindowTitleAsDirty();
            CanvasNavigator.updateCursor();
        }

        // 통합 메뉴얼(manual/manual.html)을 기본 브라우저로 염
        public static function openLocalManual():void
        {
            var manualFile:File = File.applicationDirectory.resolvePath("manual/manual.html");
            if (manualFile.exists)
            {
                var request:URLRequest = new URLRequest(manualFile.url);
                navigateToURL(request);
            }
        }

        private static function isWebpFile(file:File):Boolean
        {
            var stream:FileStream = new FileStream();
            stream.open(file, FileMode.READ);
            var header:ByteArray = new ByteArray();
            stream.readBytes(header, 0, Math.min(12, stream.bytesAvailable));
            stream.close();
            // Check "RIFF" at bytes 0–3
            if (header.length >= 12 &&
                    header[0] == 0x52 && header[1] == 0x49 &&
                    header[2] == 0x46 && header[3] == 0x46 &&
                    header[8] == 0x57 && header[9] == 0x45 &&
                    header[10] == 0x42 && header[11] == 0x50)
            {
                return true;
            }
            return false;
        }
        public static function validateImageFile(file:File, callbackOk:Function, callbackCancel:Function = null):void
        {
            var loader:Loader = new Loader();
            function cleanEvents():void
            {
                loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onCompleteValidateFile);
                loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onErrorValidateFile);
                loader.unload();
                loader = null;
            }
            function onCompleteValidateFile(e:Event):void
            {
                if (callbackOk !== null)
                {
                    const bmpd:BitmapData = new BitmapData(loader.content.width, loader.content.height, true, 0);
                    bmpd.draw(loader);
                    callbackOk("image", file, bmpd);
                }
                cleanEvents();
            }
            function onErrorValidateFile(e:IOErrorEvent):void
            {
                cleanEvents();
                try
                {
                    if (file.exists)
                    {
                        if (isTrue2020File(file))
                        {
                            if (callbackOk !== null)
                            {
                                callbackOk("2020", file, null);
                                return;
                            }
                        }
                        else if (isWebpFile(file))
                        {
                            if (callbackOk !== null)
                            {
                                callbackOk("webp", file, null);
                                return;
                            }
                        }
                    }
                }
                catch (error:Error) {}
                if (callbackCancel !== null)
                {
                    callbackCancel();
                }
            }
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onCompleteValidateFile);
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onErrorValidateFile);
            loader.load(new URLRequest(file.url));
        }

        // 캔버스로 불러오기 (드래그 드롭, 운영체제 파일 연결, 클립보드)
        public static function isFileLoadBlocked():Boolean
        {
            return isRefLayerLoadBlocked() || isReplayDataLocked();
        }

        // 참고 레이어로 불러오기는 리플레이 데이터를 건드리지 않으므로 worker 잠금과 무관
        public static function isRefLayerLoadBlocked():Boolean
        {
            return UIController.isFileBrowserOpened || BackgroundWorkerCoordinator.isSaveInProgress
                || ReplayState.isGeneratingCacheImages();
        }

        // worker의 저장, 캡처, undo 캐시 작업 결과가 바뀐 리플레이 데이터에 섞이지 않도록
        // worker가 완전히 멈출때까지 리플레이 데이터를 초기화하거나 잘라내는 작업을 막음
        // (파일 불러오기, 새 파일, 리플레이 앞/뒤 삭제, 현재 프레임으로 새 파일)
        // 네이티브 undo 캐시 작업(undoDataQueue)도 worker 작업처럼 잠금, 불러오기 캐시 작업은 캐시 생성 상태가 따로 막음
        public static function isReplayDataLocked():Boolean
        {
            return BackgroundWorkerCoordinator.isSaveInProgress !== 0 || BackgroundWorkerCoordinator.isWorkerBusy()
                || BackgroundWorkerCoordinator.undoDataQueue !== null;
        }

        public static function showReplayDataLockedHint():void
        {
            HintController.showMouseHintTemp("Waiting for background tasks...");
        }

        public static function canCreateNewFile():Boolean
        {
            return isNewFileAvailable && !isReplayDataLocked();
        }

        public static function setNewFileAvailable(flag:Boolean):void
        {
            isNewFileAvailable = flag;
            refreshFileOperationButtonsTopbar();
        }

        // 운영체제에서 fofo/2020파일 연결을 FOFOPAINT로 해줬을때
        public static function onInvokeEvent(e:InvokeEvent):void
        {
            // 앱 상태 복원 중에는 창 크기와 UI 배치가 확정되지 않아 로드박스 크기가 어긋나므로 복원이 끝난 뒤에 띄움
            if (AppDataPaths.isLoadingAppData)
            {
                pendingInvokeArguments = e.arguments;
                FOFOTimer.addByName("pendingInvokeTimer", 0.1, true, function ():Boolean
                    {
                        if (AppDataPaths.isLoadingAppData)
                        {
                            return true;
                        }
                        openInvokeFile(pendingInvokeArguments);
                        pendingInvokeArguments = null;
                        return false;
                    });
                return;
            }
            if (isFileLoadBlocked())
            {
                e.preventDefault();
                return;
            }
            openInvokeFile(e.arguments);
        }

        private static function openInvokeFile(arguments:Array):void
        {
            if (isFileLoadBlocked())
            {
                return;
            }
            if (arguments && arguments.length > 0)
            {
                try
                {
                    var file:File = new File(arguments[0] as String);
                    if (file.exists)
                    {
                        if (!LoadBoxController.canDisplayLoadMenuBox(file))
                        {
                            return;
                        }

                        LoadBoxController.lastLoadedFile = file;

                        if (ReplayState.isReplayStarted)
                        {
                            ReplayController.stopReplay();
                        }
                        if (ReplayState.isReplayRestartTimerON)
                        {
                            ReplayController.cancelReplayRestartTimer();
                        }
                        LoadBoxController.prepareLoadMenuBoxFromImageFile(file, false);
                    }
                }
                catch (err:Error) {}
            }
        }

        public static function onDragDropStage(e:NativeDragEvent):void
        {
            if (isFileLoadBlocked())
            {
                return;
            }
            ReplayDrawer.rFileStream.close();
            ReplayController.cancelReplayRestartTimer();
            const data:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
            if (data && data.length > 0)
            {
                const file:File = data[0] as File;
                if (LoadBoxController.canDisplayLoadMenuBox(file))
                {
                    LoadBoxController.prepareLoadMenuBoxFromImageFile(file, false);
                    return;
                }
            }
        }

        // 각 버튼의 사용 가능 상태와 잠금 상태로 아이콘을 다시 계산함
        // 잠금 중에 클립보드가 바뀌거나 스트로크로 새 파일이 가능해져도 잠금이 풀릴때 그대로 반영됨
        public static function refreshFileOperationButtonsTopbar():void
        {
            const locked:Boolean = isReplayDataLocked();
            const offAlpha:Number = UITheme.OFFALPHA;
            UIController.topBar.saveButton.alpha = (BackgroundWorkerCoordinator.isSaveInProgress) ? offAlpha : 1.0;
            UIController.topBar.loadButton.alpha = (locked) ? offAlpha : 1.0;
            UIController.topBar.clipBoardButton.alpha = (!locked && ClipboardManager.isClipBoardButtonActivated) ? 1.0 : offAlpha;
            UIController.topBar.newFileButton.alpha = (!locked && isNewFileAvailable) ? 1.0 : offAlpha;
            if (ReplayState.isReplayModeON)
            {
                ReplayController.updateDeleteReplayDataButtonsState();
            }
        }

        private static function disableFileOperationButtonsTopbar():void
        {
            BackgroundWorkerCoordinator.isSaveInProgress = 1;
            refreshFileOperationButtonsTopbar();
        }

        // 저장 시작: 네이티브(NativeSave)로 저장할 수 있으면 네이티브, 아니면 기존 worker 경로
        // mergedImage는 소유권을 가져가서 처리 후 dispose함
        private static function startSave(mergedImage:BitmapData, isContinueSave:Boolean):void
        {
            if (startNativeSave(mergedImage))
            {
                mergedImage.dispose();
                return;
            }

            startWorkerSave(mergedImage, isContinueSave);
        }

        // 기존 경로: worker가 PNG 인코드와 이미지/리플레이 압축, main이 PNG와 .fofo를 씀
        private static function startWorkerSave(mergedImage:BitmapData, isContinueSave:Boolean):void
        {
            BackgroundWorkerCoordinator.receivedSaveImageDataFromWorker = null;
            // 소유권을 Worker로 넘김, Worker 쪽에서 dispose함
            BackgroundWorkerCoordinator.startPngEncodingWorker(mergedImage, DrawCanvas.CANVAS_BG_COLOR, false, false);
            saveFOFOFile();
            pollTimerWaitWorkerForImageSave(lastSaveFilePath, isContinueSave);
        }

        private static function pollTimerWaitWorkerForImageSave(lastPath:String, isContinueSave:Boolean):void
        {
            const fs:FileStream = new FileStream();

            function onErrorSaveFileContinue(e:Event):void
            {
                fs.close();
                fs.removeEventListener(IOErrorEvent.IO_ERROR, onErrorSaveFileContinue);
                isFileAlreadySaved = false;
                if (LoadBoxController.isLoadPendingAfterSaving)
                {
                    LoadBoxController.loadFileTo("canvas");
                }
                else
                {
                    openSaveFileBrowser(true, true);
                }
            }

            if (isContinueSave)
            {
                fs.addEventListener(IOErrorEvent.IO_ERROR, onErrorSaveFileContinue);
            }
            FOFOTimer.addByName("workerPNGSaveTimer", BackgroundWorkerCoordinator.WORKER_WAIT_INTERVAL, true, function (_path:String):Boolean
                {
                    if (BackgroundWorkerCoordinator.receivedSaveImageDataFromWorker !== null)
                    {
                        fs.openAsync(new File(_path), FileMode.WRITE);
                        fs.writeBytes(BackgroundWorkerCoordinator.receivedSaveImageDataFromWorker);
                        fs.close();
                        if (isContinueSave)
                        {
                            fs.removeEventListener(IOErrorEvent.IO_ERROR, onErrorSaveFileContinue);
                        }
                        BackgroundWorkerCoordinator.receivedSaveImageDataFromWorker.clear();
                        BackgroundWorkerCoordinator.receivedSaveImageDataFromWorker = null;
                        return false;
                    }
                    return true;
                }, [lastPath]);
        }

        // 테스트에서 저장 옵션을 바꿀때 씀 (1 = 리플레이 블록을 FRC2 대신 zlib)
        public static var nativeSaveOptions:int = 0;

        // 네이티브 저장: 지금 상태(비트맵 6개, repdata 길이, 메모리 뭉치, 메타)를 한 번에 넘기고 바로 돌아옴
        // 저장 결과는 onNativeSaveDone, 끝날때까지 isSaveInProgress를 유지해서 repdata 자르기/초기화를 막음
        private static function startNativeSave(mergedImage:BitmapData):Boolean
        {
            if (!NativeSave.isAvailable || !AppDataPaths.replayDataFilePath.exists)
            {
                return false;
            }

            const first1:BitmapData = ReplayFileCache.rFirstImageLayer1BitmapData;
            const first2:BitmapData = ReplayFileCache.rFirstImageLayer2BitmapData;
            const current1:BitmapData = DrawCanvas.canvasLayer1BitmapData;
            const current2:BitmapData = DrawCanvas.canvasLayer2BitmapData;
            const reference:BitmapData = ReferenceLayerController.canvasRefLayerBitmapData;

            // 기존 경로는 첫 레이어 크기, 캔버스 크기로 copyPixelsToByteArray를 했음, 비트맵 크기가 그와 다르면(일어나지 않아야 함) 기존 경로로
            if (first2.width !== first1.width || first2.height !== first1.height
                    || current1.width !== DrawCanvas.CANVAS_WIDTH || current1.height !== DrawCanvas.CANVAS_HEIGHT
                    || current2.width !== DrawCanvas.CANVAS_WIDTH || current2.height !== DrawCanvas.CANVAS_HEIGHT)
            {
                return false;
            }

            saveStartTime = getTimer();
            ReplayState.lastMirrorReadyFlag = ReplayState.mirrorCommandReady;

            // 딥 언두면 읽은 바이트까지만 (0이면 리플레이 블록 없음), 아니면 지금 파일 전체 + 메모리 undo 뭉치
            var repdataLength:Number = 0;
            const memoryGroups:ByteArray = new ByteArray();

            if (UndoHistory.isDeepUndoEnabled)
            {
                repdataLength = (ReplayState.rFileLastBytePosition > 0) ? ReplayState.rFileLastBytePosition : 0;
            }
            else
            {
                repdataLength = AppDataPaths.replayDataFilePath.size;

                for (var i:int = 0, len:int = UndoHistory.undoDataIndex;i <= len;i++)
                {
                    const data:Array = ReplayState.rMemoryData[i];

                    if (data && data.length === 0)
                    {
                        continue;
                    }
                    memoryGroups.writeObject(data);
                }
            }

            const memoryTime:int = getTimer();
            // 타이밍 시트: 파일에 쓰는 프레임과 같은 범위 (saveFOFOFile과 같음)
            const sheet:Array = TimingSheetFile.buildFileObject(
                    UndoHistory.isDeepUndoEnabled ? ReplayState.rNowFrame : ReplayState.getRFileDataTotalFrame(),
                    ReplayState.rMemoryDataTimingSheet,
                    UndoHistory.isDeepUndoEnabled ? 0 : UndoHistory.undoDataIndex + 1,
                    ReplayState.lastMirrorReadyFlag ? 1 : 0);
            const timingBytes:ByteArray = new ByteArray();

            if (sheet !== null)
            {
                timingBytes.writeObject(sheet);
            }

            const sheetTime:int = getTimer();
            FileManager.updateReplaySaveMetaData();
            const mirrorBytes:ByteArray = new ByteArray();

            // 임시 미러가 되어있을때 진짜 캔버스로 반전되어있는데 리플레이 데이터에는 아직 써주지 않았으니까 넣어줌
            if (ReplayState.lastMirrorReadyFlag)
            {
                mirrorBytes.writeObject([["mirror"]]);
            }

            const firstMeta:Array = [ReplaySaveMetaData.firstImageWidth, ReplaySaveMetaData.firstImageHeight, ReplaySaveMetaData.firstImageBG, ReplaySaveMetaData.firstImageMirrorFlag];
            const finalMeta:Array = [ReplaySaveMetaData.finalImageWidth, ReplaySaveMetaData.finalImageHeight, ReplaySaveMetaData.finalImageBG];
            const referenceMeta:Array = (reference !== null) ? [ReplaySaveMetaData.refImageWidth,
                    ReplaySaveMetaData.refImageHeight,
                    ReplaySaveMetaData.refImageBitmapX,
                    ReplaySaveMetaData.refImageBitmapY,
                    ReplaySaveMetaData.refImageBitmapRotation,
                    ReplaySaveMetaData.refImageBitmapScaleX,
                    ReplaySaveMetaData.refImageBitmapScaleY,
                    ReplaySaveMetaData.refImageBitmapMirrorFlag,
                    ReplaySaveMetaData.refImageBitmapMoveSum,
                    ReplaySaveMetaData.refImageAlpha] : null;

            // PNG는 worker encodePNG와 같은 합성 (배경색 비트맵 위에 그림), BitmapData.draw는 네이티브로 같게 만들기 어려워서 AS3로
            const composite:BitmapData = new BitmapData(mergedImage.width, mergedImage.height, true, DrawCanvas.CANVAS_BG_COLOR);
            composite.draw(mergedImage);
            const compositeTime:int = getTimer();
            const pngPath:String = lastSaveFilePath;
            const started:Boolean = NativeSave.startSave(pngPath, ReplayFileCache.getReplayFileNameFromPath(pngPath), composite,
                    first1, first2, current1, current2, reference,
                    AppDataPaths.replayDataFilePath.nativePath, repdataLength, memoryGroups, mirrorBytes, timingBytes,
                    firstMeta, finalMeta, referenceMeta, nativeSaveOptions, onNativeSaveDone);
            trace("Native save start: memory groups " + (memoryTime - saveStartTime) + "ms, timing sheet " + (sheetTime - memoryTime)
                + "ms, composite " + (compositeTime - sheetTime) + "ms, native call " + (getTimer() - compositeTime) + "ms");
            composite.dispose();
            memoryGroups.clear();
            mirrorBytes.clear();
            timingBytes.clear();
            return started;
        }

        private static function onNativeSaveDone(result:Object):void
        {
            trace("Native save " + result.status + " codec=" + result.codec + " encode=" + result.encodeMs + "ms write=" + result.writeMs + "ms " + result.message);

            switch (result.status)
            {
                case NativeSave.STATUS_OK:
                    finishSave(result.fofoSize, false);
                    break;
                case NativeSave.STATUS_RENAMED:
                    // 원래 파일을 다른 프로그램이 잡고 있거나 읽기 전용이라 이름_new 쌍으로 저장함, 이후 저장도 새 이름으로
                    lastSaveFilePath = result.pngPath;
                    lastSaveFileName = getFileNameFromPath(lastSaveFilePath);
                    AppWindowState.updateWindowTitle();
                    AppDataPaths.writeCrashLog("Save renamed to " + result.pngPath + " (" + result.message + ")");
                    finishSave(result.fofoSize, true);
                    break;
                case NativeSave.STATUS_FAILED:
                    handleSaveWriteFailed(result);
                    break;
                default:
                    // 네이티브 내부 오류(메모리 부족 등)는 쓰기 실패가 아님, 이 저장을 기존 worker 경로로 다시 함 (지금 캔버스 기준)
                    AppDataPaths.writeCrashLog("Native save internal error, retry with worker: " + result.stage + " " + result.message);
                    startWorkerSave(DrawCanvas.getMergedBitmapData(false, true, true, null), true);
                    break;
            }
        }

        private static function finishSave(fofoSize:Number, renamed:Boolean):void
        {
            BackgroundWorkerCoordinator.isSaveInProgress = 0;
            refreshFileOperationButtonsTopbar();
            HintController.showMouseHintTemp((renamed ? "Saved as " + stripExtension(lastSaveFileName) + " (file was in use) (" : "Saved (")
                + (getTimer() - saveStartTime) + " ms, " + ReplayFileCache.formatFileSize(fofoSize) + ")", 10.0);

            if (LoadBoxController.isLoadPendingAfterSaving)
            {
                // 다른 백그라운드 작업이 남아있으면 loadFileTo가 다시 대기로 돌리고, worker가 멈출때 불러옴
                LoadBoxController.loadFileTo("canvas");
            }
        }

        // 폴더 없음, 권한 없음, 디스크 부족처럼 이름을 바꿔도 안 되는 쓰기 실패: 재시도하지 않고 알림, 저장 안 됨 상태로 둠
        private static function handleSaveWriteFailed(result:Object):void
        {
            AppDataPaths.writeCrashLog("Save failed: stage=" + result.stage + " win32 error=" + result.error
                + " png=" + result.pngPath + " fofo=" + result.fofoPath + " " + result.message);
            BackgroundWorkerCoordinator.isSaveInProgress = 0;
            isFileAlreadySaved = false;

            if (LoadBoxController.isLoadPendingAfterSaving)
            {
                LoadBoxController.isLoadPendingAfterSaving = false;
                LoadBoxController.closeLoadMenuBox();
            }

            refreshFileOperationButtonsTopbar();
            AppWindowState.markWindowTitleAsDirty();
            HintController.showMouseHintTemp("Save failed: " + describeWriteError(result.error), 10.0);
        }

        private static function describeWriteError(code:int):String
        {
            switch (code)
            {
                case 2: // ERROR_FILE_NOT_FOUND
                case 3: // ERROR_PATH_NOT_FOUND
                    return "folder not found";
                case 5: // ERROR_ACCESS_DENIED
                    return "no permission";
                case 39: // ERROR_HANDLE_DISK_FULL
                case 112: // ERROR_DISK_FULL
                    return "disk is full";
                case 123: // ERROR_INVALID_NAME
                    return "invalid file name";
                default:
                    return "error " + code;
            }
        }

        private static function saveFOFOFile():void
        {
            saveStartTime = getTimer();

            if (AppDataPaths.replayDataFilePath.exists)
            {
                rLayer1FirstImageData = new ByteArray();
                rLayer2FirstImageData = new ByteArray();
                rLayer1CurrentImageData = new ByteArray();
                rLayer2CurrentImageData = new ByteArray();

                ReferenceLayerController.refLayerImageData.position = 0;
                ReferenceLayerController.refLayerImageData = new ByteArray();
                replayDataReadBytes = new ByteArray();
                ReplayState.lastMirrorReadyFlag = ReplayState.mirrorCommandReady;

                // 첫번째 이미지 레이어 1 2 저장
                const rImgDataW:Number = ReplayFileCache.rFirstImageLayer1BitmapData.width;
                const rImgDataH:Number = ReplayFileCache.rFirstImageLayer1BitmapData.height;
                var newRectangle:Rectangle = new Rectangle(0, 0, rImgDataW, rImgDataH);
                ReplayFileCache.rFirstImageLayer1BitmapData.copyPixelsToByteArray(newRectangle, rLayer1FirstImageData);
                ReplayFileCache.rFirstImageLayer2BitmapData.copyPixelsToByteArray(newRectangle, rLayer2FirstImageData);
                // 현재 캔버스 이미지 레이어 1 2 저장
                newRectangle = new Rectangle(0, 0, DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT);
                DrawCanvas.canvasLayer1BitmapData.copyPixelsToByteArray(newRectangle, rLayer1CurrentImageData);
                DrawCanvas.canvasLayer2BitmapData.copyPixelsToByteArray(newRectangle, rLayer2CurrentImageData);
                // 참고 레이어 이미지 저장
                if (ReferenceLayerController.canvasRefLayerBitmapData)
                {
                    const refImgWidth:Number = ReferenceLayerController.canvasRefLayerBitmapData.width;
                    const refImgHeight:Number = ReferenceLayerController.canvasRefLayerBitmapData.height;
                    newRectangle = new Rectangle(0, 0, refImgWidth, refImgHeight);
                    ReferenceLayerController.canvasRefLayerBitmapData.copyPixelsToByteArray(newRectangle, ReferenceLayerController.refLayerImageData);
                }
                // 리플레이 파일을 임시파일로 복사해서 이 내부의 바이트만 읽어서 워커에게 보냄
                AppDataPaths.replayDataFilePath.copyTo(ReplayFileCache.repFileTemp, true);

                const fs:FileStream = new FileStream();

                // 딥 언도일때는 읽은 바이트 까지만 읽어줌
                if (UndoHistory.isDeepUndoEnabled)
                {
                    // 마지막 바이트가 0이상일때만 읽어주어야함
                    // ReplayController.rFileLastBytePosition = 0이면 안읽는것이 아니고 전체 바이트를 읽음그래서 0이면 안읽게 해주어야함
                    if (ReplayState.rFileLastBytePosition > 0)
                    {
                        fs.open(ReplayFileCache.repFileTemp, FileMode.READ);
                        fs.position = 0;
                        fs.readBytes(replayDataReadBytes, 0, ReplayState.rFileLastBytePosition);
                        fs.close();
                    }
                }
                else
                {
                    // 그게 아니면 전체 리플레이 데이터 끝까지 읽고 undo데이터까지 넣어줌
                    fs.open(ReplayFileCache.repFileTemp, FileMode.READ);
                    fs.position = 0;
                    fs.readBytes(replayDataReadBytes, 0, fs.bytesAvailable);
                    fs.close();

                    replayDataReadBytes.position = replayDataReadBytes.length;
                    for (var i:int = 0, len:int = UndoHistory.undoDataIndex;i <= len;i++) // 리플레이 데이터랑 첫이미지 마지막 이미지 추가적으로 붙여줌
                    {
                        const data:Array = ReplayState.rMemoryData[i];

                        if (data && data.length === 0)
                        {
                            continue;
                        }
                        replayDataReadBytes.writeObject(data);
                    }
                }

                // 타이밍 시트: 파일에 쓰는 프레임과 같은 범위(딥 언두면 읽은 곳까지, 아니면 파일 + 메모리 뭉치 + 임시 미러 1프레임)
                ReplayFileCache.rTimingSheetFileObject = TimingSheetFile.buildFileObject(
                        UndoHistory.isDeepUndoEnabled ? ReplayState.rNowFrame : ReplayState.getRFileDataTotalFrame(),
                        ReplayState.rMemoryDataTimingSheet,
                        UndoHistory.isDeepUndoEnabled ? 0 : UndoHistory.undoDataIndex + 1,
                        ReplayState.lastMirrorReadyFlag ? 1 : 0);
                FileManager.updateReplaySaveMetaData();
                BackgroundWorkerCoordinator.startReplayDataCompressionWorker(rLayer1FirstImageData, rLayer2FirstImageData, rLayer1CurrentImageData, rLayer2CurrentImageData, ReferenceLayerController.refLayerImageData, replayDataReadBytes);
            }
        }

        public static function openLoadFileBrowser(toRefLayer:Boolean = false):void
        {
            if (ReplayState.isReplayStarted)
            {
                ReplayController.stopReplay();
            }
            if (LassoTool.isStarted || UIController.isFileBrowserOpened
                    || FillPenTool.isStarted || LineTool.isStarted
                    || BackgroundWorkerCoordinator.isSaveInProgress
                    || (!toRefLayer && isReplayDataLocked()))
            {
                return;
            }
            var windowTitle:String = "Open file";
            if (toRefLayer === true)
            {
                windowTitle = "Open reference layer image";
            }
            const loadPath:String = getDirectoryOnly(getExistingParentDirectory(lastSaveFilePath));
            const file:File = (lastSaveFilePath === lastSaveFileName) ? new File() : new File(loadPath);
            function cleanUpEvents():void
            {
                file.removeEventListener(Event.SELECT, onFileSelected);
                file.removeEventListener(Event.COMPLETE, onFileSelectComplete);
                file.removeEventListener(Event.CANCEL, onFileSelectCancel);
            }
            function onFileSelectCancel(e:Event):void
            {
                setFileBrowserIsOpen(false);
                cleanUpEvents();
                ReplayController.addInputEventsDrawModeOrReplayMode();
            }
            function onFileSelected(e:Event):void
            {
                setFileBrowserIsOpen(false);
                file.removeEventListener(Event.SELECT, onFileSelected);
                file.load();
            }
            function onFileSelectComplete(e:Event):void
            {
                cleanUpEvents();
                setFileBrowserIsOpen(false);
                ReplayController.addInputEventsDrawModeOrReplayMode();
                LoadBoxController.prepareLoadMenuBoxFromImageFile(file, toRefLayer);
            }
            setFileBrowserIsOpen(true);
            CanvasResizer.showButtonsWithDelay(false);
            ReplayModeInput.removeEvents();
            DrawModeInput.removeEvents();
            file.browseForOpen(windowTitle, [new FileFilter("All supported formats", "*.fofo;*.2020;*.png;*.jpg;*.jpeg;*.jfif;*.gif;*.webp")]);
            file.addEventListener(Event.SELECT, onFileSelected);
            file.addEventListener(Event.COMPLETE, onFileSelectComplete);
            file.addEventListener(Event.CANCEL, onFileSelectCancel);
        }

        public static function saveCaptureImage():void
        {
            if (UIController.isFileBrowserOpened)
            {
                return;
            }
            CaptureController.executeCaptureFlashEffect();
            const replayMode:Boolean = ReplayState.isReplayModeON;
            var name:String = lastSaveFileName;
            var path:String = getExistingParentDirectory(lastSaveCaptureFilePath);
            setFileBrowserIsOpen(true);
            name = CaptureStamp.cutTimeStamp(name);
            name = stripExtension(name) + "_capture_" + CaptureStamp.getTimeStampTail() + ".png"; // 뒤에 프레임 번호 붙여줌
            path = path.substr(0, path.lastIndexOf(lastSaveFileName)) + name;
            var file:File = (name !== path) ? new File(path) : File.desktopDirectory.resolvePath(name);
            const fs:FileStream = new FileStream();
            const saveWindowTitle:String = "Save capture image";
            file.addEventListener(IOErrorEvent.IO_ERROR, onCancelSaveCaptureImage);
            file.addEventListener(Event.CANCEL, onCancelSaveCaptureImage);
            file.addEventListener(Event.SELECT, onSelectSaveCaptureImage);
            file.browseForSave(saveWindowTitle);
            function onCancelSaveCaptureImage(e:Event):void
            {
                setFileBrowserIsOpen(false);
                file.cancel();
                file.removeEventListener(IOErrorEvent.IO_ERROR, onCancelSaveCaptureImage);
                file.removeEventListener(Event.CANCEL, onCancelSaveCaptureImage);
                file.removeEventListener(Event.SELECT, onSelectSaveCaptureImage);
            }
            function onSelectSaveCaptureImage(e:Event):void
            {
                setFileBrowserIsOpen(false);
                file.cancel();
                file.removeEventListener(IOErrorEvent.IO_ERROR, onCancelSaveCaptureImage);
                file.removeEventListener(Event.CANCEL, onCancelSaveCaptureImage);
                file.removeEventListener(Event.SELECT, onSelectSaveCaptureImage);
                if (BackgroundWorkerCoordinator.receivedCaptureImageQueueFromWorker === null)
                    BackgroundWorkerCoordinator.receivedCaptureImageQueueFromWorker = new Vector.<ByteArray>();
                if (BackgroundWorkerCoordinator.captureImageDataQueue === null)
                    BackgroundWorkerCoordinator.captureImageDataQueue = [];
                lastSaveCaptureFilePath = getDirectoryOnly(e.target.nativePath) + File.separator + lastSaveFileName;

                if (saveCaptureImageNative(file.name, e.target.nativePath))
                {
                    return;
                }

                BackgroundWorkerCoordinator.captureImageDataQueue.push([file.name, e.target.nativePath]);
                BackgroundWorkerCoordinator.startPngEncodingWorker(CaptureController.getCaptrueImageBitmapdata(false), 0, true, CaptureController.isCaptureTransparentBGShowing);
                BackgroundWorkerCoordinator.pollTimerWaitWorkerForSaveCaptureImage();
            }
        }

        // 캡처 이미지를 네이티브로 PNG 저장, 시작하지 못하면 false (기존 worker 경로)
        private static function saveCaptureImageNative(fileName:String, filePath:String):Boolean
        {
            if (!NativeSave.isAvailable)
            {
                return false;
            }

            var path:String = filePath;

            if (fileName.lastIndexOf(".png") === -1) // png를 안붙여 줬을때 (worker 경로와 같은 규칙)
            {
                path = filePath.replace(fileName, "") + fileName + ".png";
            }

            // worker encodePNG와 같은 합성: 투명 비트맵 위에 그림
            const captureImage:BitmapData = CaptureController.getCaptrueImageBitmapdata(false);
            const composite:BitmapData = new BitmapData(captureImage.width, captureImage.height, true, 0);
            composite.draw(captureImage);
            captureImage.dispose();
            const started:Boolean = NativeSave.startPng(path, composite, function (result:Object):void
                {
                    if (result.status !== NativeSave.STATUS_OK)
                    {
                        AppDataPaths.writeCrashLog("Capture save failed: stage=" + result.stage + " win32 error=" + result.error + " " + result.pngPath + " " + result.message);
                        HintController.showMouseHintTemp("Capture save failed: " + describeWriteError(result.error), 10.0);
                    }
                });
            composite.dispose();
            return started;
        }

        private static function checkSaveFailedFileName(saveFailed:Boolean):File
        {
            var _path:String = lastSaveFilePath;
            var _name:String = lastSaveFileName;
            // 파일 이름 빼고 경로만 추출
            const nameStatIndex:int = _path.lastIndexOf(_name);
            const pathonly:String = _path.substr(0, nameStatIndex);
            // 파일 이름에 시간이 찍혀있으면 이름 그대로 반환하고 없으면 앞에 붙여줌
            var fileName:String = _name;
            var filePath:String = pathonly + fileName;
            if (saveFailed)
            {
                // 파일 쓰기가 실패하면 뒤에 _new, 이미 있으면 _new2, _new3 ... (네이티브 저장과 같은 규칙)
                const basePath:String = _path.substr(0, _path.length - (_name.length - stripExtension(_name).length));
                var suffix:String = "_new";

                for (var number:int = 2;number < 1000;number++)
                {
                    try
                    {
                        if (!new File(basePath + suffix + ".png").exists && !new File(basePath + suffix + ".fofo").exists)
                        {
                            break;
                        }
                    }
                    catch (error:Error)
                    {
                        break;
                    }
                    suffix = "_new" + number;
                }

                filePath = basePath + suffix + ".png";
                fileName = stripExtension(_name) + suffix + ".png";
            }
            return (_name !== _path) ? new File(filePath) : File.desktopDirectory.resolvePath(fileName);
        }
        private static function getFileNameFromPath(path:String):String
        {
            if (!path || path.length == 0)
            {
                return "";
            }
            var lastSlash:int = path.lastIndexOf(File.separator);
            if (lastSlash >= 0)
            {
                return path.substring(lastSlash + 1);
            }
            return path;
        }

        // 파일 이름 끝의 알려진 확장자를 떼어냄. 확장자가 없으면 그대로 반환
        public static function stripExtension(name:String):String
        {
            return name.replace(/\.(fofo|2020|jpg|jpeg|gif|jfif|webp|png)$/i, "");
        }

        public static function convertToPNGFilePath(path:String):String
        {
            var name:String = getFileNameFromPath(path);
            const directory:String = getDirectoryOnly(path);
            const ext:RegExp = /\.(fofo|2020|jpg|jpeg|gif|jfif|webp|png)$/i;
            name = ext.test(name) ? name.replace(ext, ".png") : name + ".png";
            return directory.length > 0 ? directory + File.separator + name : name;
        }

        private static function getDirectoryOnly(path:String):String
        {
            if (!path || path.length == 0)
            {
                return "";
            }
            // 마지막 구분자 위치 찾기
            var lastSlash:int = Math.max(path.lastIndexOf("\\"), path.lastIndexOf("/"));
            if (lastSlash >= 0)
            {
                // 마지막 구분자 앞부분만 반환
                return path.substring(0, lastSlash);
            }
            // 구분자가 없으면 경로가 아니라 파일명만 있는 경우 → 빈 문자열 반환
            return "";
        }

        // 해당 디렉토리가 없으면 그 상위 디렉토리로 위치를 바꾸어줌
        private static function getExistingParentDirectory(path:String):String
        {
            try
            {
                const oldFild:File = new File(path);
                if (oldFild.exists)
                {
                    return path;
                }
                var testPath:String = path;
                var file:File = new File(testPath);
                var lastSep:int;
                while (true)
                {
                    if (file.exists && file.isDirectory)
                    {
                        return testPath + File.separator + lastSaveFileName;
                    }
                    // 마지막 separator 위치 찾기
                    lastSep = testPath.lastIndexOf(File.separator);
                    if (lastSep === -1)
                    {
                        break;
                    }
                    // 상위 경로로 이동
                    testPath = testPath.substring(0, lastSep);
                    file = new File(testPath);
                }
            }
            catch (e:Error)
            {
                return File.desktopDirectory.nativePath + File.separator + lastSaveFileName;
            }
            return File.desktopDirectory.nativePath + File.separator + lastSaveFileName;
        }

        public static function openSaveFileBrowser(asFlag:Boolean, saveFailed:Boolean = false):void
        {
            // 계속 저장하는거 방지 다른 이름으로 저장은 예외
            if (ReplayState.isReplayStarted)
            {
                ReplayController.stopReplay();
            }

            const continueFlag:Boolean = (isContinueSaveON === true && asFlag === false);
            const nextPath:String = getExistingParentDirectory(lastSaveFilePath);
            const replayFilePath:String = ReplayFileCache.getReplayFileNameFromPath(lastSaveFilePath);
            const rawFile:File = new File(replayFilePath);

            if (nextPath === lastSaveFilePath && isFileAlreadySaved && continueFlag && rawFile.exists)
            {
                if (LoadBoxController.isLoadPendingAfterSaving)
                {
                    LoadBoxController.loadFileTo("canvas");
                }
                else
                {
                    HintController.showMouseHintTemp("Already saved");
                }
                return;
            }

            if (LassoTool.isStarted || FillPenTool.isStarted || LineTool.isStarted || BackgroundWorkerCoordinator.isSaveInProgress)
            {
                return;
            }

            if (nextPath !== lastSaveFilePath)
            {
                lastSaveFilePath = nextPath;
            }

            if (continueFlag)
            {
                if (rawFile.exists)
                {
                    disableFileOperationButtonsTopbar();
                    // 병합 이미지는 startSave가 처리 후 dispose함
                    startSave(DrawCanvas.getMergedBitmapData(false, true, true, null), true);
                    AppWindowState.updateWindowTitle();
                    KeyState.clearKeyBuffer();
                    isFileAlreadySaved = true;
                }
                else // 파일을 못찾으면 새로 저장
                {
                    isContinueSaveON = false;
                    openSaveFileBrowser(true);
                }
            }
            else
            {
                if (UIController.isFileBrowserOpened)
                {
                    return;
                }
                const file:File = checkSaveFailedFileName(saveFailed);
                const saveWindowTitle:String = (saveFailed) ? "Failed to save file! save with new name"
                    : (asFlag === true) ? "Save file As.."
                    : (LoadBoxController.isLoadPendingAfterSaving) ? "Save file before load file" : "Save file";
                // 대화상자 연 시점의 이미지로 저장, 선택하면 Worker로 넘기고 취소하면 여기서 dispose
                var mergedImage:BitmapData = DrawCanvas.getMergedBitmapData(false, true, true, null);
                file.addEventListener(IOErrorEvent.IO_ERROR, onErrorEvent);
                file.addEventListener(Event.CANCEL, onErrorEvent);
                file.addEventListener(Event.SELECT, onSelectEvent);
                file.browseForSave(saveWindowTitle);
                setFileBrowserIsOpen(true);
                function removeEvent():void
                {
                    file.removeEventListener(IOErrorEvent.IO_ERROR, onErrorEvent);
                    file.removeEventListener(Event.CANCEL, onErrorEvent);
                    file.removeEventListener(Event.SELECT, onSelectEvent);
                }
                function onErrorEvent(e:Event):void
                {
                    if (mergedImage !== null)
                    {
                        mergedImage.dispose();
                        mergedImage = null;
                    }
                    setFileBrowserIsOpen(false);
                    file.cancel();
                    removeEvent();
                    if (LoadBoxController.isLoadPendingAfterSaving)
                    {
                        LoadBoxController.loadFileTo("canvas");
                    }
                }
                function onSelectEvent(e:Event):void
                {
                    setFileBrowserIsOpen(false);
                    removeEvent();
                    // 소유권을 넘김, startSave가 처리 후 dispose함
                    saveAsPath(e.target.nativePath, mergedImage);
                    mergedImage = null;
                }
            }
        }

        // 저장 대화상자에서 고른 경로로 저장 시작 (자동화 테스트도 이 함수로 대화상자 없이 저장함)
        // mergedImage는 소유권을 가져가서 처리 후 dispose함
        public static function saveAsPath(path:String, mergedImage:BitmapData):void
        {
            disableFileOperationButtonsTopbar();
            isFileAlreadySaved = true;
            isContinueSaveON = true;
            lastSaveFilePath = convertToPNGFilePath(path);
            lastSaveFileName = getFileNameFromPath(lastSaveFilePath);
            startSave(mergedImage, false);
            AppWindowState.updateWindowTitle();
        }

        public static function enterDrawModeOnLoadFile():void
        {
            if (CaptureController.isCaptureModeON)
            {
                CaptureController.exitCaptureMode();
            }
            if (ReplayState.isReplayModeON)
            {
                ReplayController.exitReplayMode();
            }
        }

        public static function updateReplaySaveMetaData():void
        {
            ReplaySaveMetaData.firstImageWidth = ReplayFileCache.rFirstImageLayer1BitmapData.width;
            ReplaySaveMetaData.firstImageHeight = ReplayFileCache.rFirstImageLayer1BitmapData.height;
            ReplaySaveMetaData.finalImageWidth = DrawCanvas.canvasLayer1BitmapData.width;
            ReplaySaveMetaData.finalImageHeight = DrawCanvas.canvasLayer1BitmapData.height;
            ReplaySaveMetaData.finalImageBG = DrawCanvas.CANVAS_BG_COLOR;
            ReplaySaveMetaData.refImageWidth = ReferenceLayerController.canvasRefLayerBitmapData.width;
            ReplaySaveMetaData.refImageHeight = ReferenceLayerController.canvasRefLayerBitmapData.height;
            ReplaySaveMetaData.refImageBitmapX = ReferenceLayerController.canvasRefLayerBitmap.x;
            ReplaySaveMetaData.refImageBitmapY = ReferenceLayerController.canvasRefLayerBitmap.y;
            ReplaySaveMetaData.refImageBitmapRotation = ReferenceLayerController.canvasRefLayer.rotation;
            ReplaySaveMetaData.refImageBitmapScaleX = ReferenceLayerController.canvasRefLayer.scaleX;
            ReplaySaveMetaData.refImageBitmapScaleY = ReferenceLayerController.canvasRefLayer.scaleY;
            ReplaySaveMetaData.refImageBitmapMirrorFlag = Boolean(ReferenceLayerController.canvasRefLayer.scaleX < 0);
            ReplaySaveMetaData.refImageBitmapMoveSum = ReferenceLayerController.refLayerMenuDragXMoveSum;
            ReplaySaveMetaData.refImageAlpha = ReferenceLayerController.refLayerLastAlpha;
        }

        // worker가 압축한 이미지와 리플레이 데이터를 .fofo 파일 형식으로 임시 파일에 쓴 뒤 저장 경로로 옮기고 저장 힌트를 보여줌
        public static function writeReplayFile(
                firstImageLayer1:ByteArray,
                firstImageLayer2:ByteArray,
                finalImageLayer1:ByteArray,
                finalImageLayer2:ByteArray,
                referenceImage:ByteArray,
                replayFileByteArray:ByteArray):void
        {
            const fs:FileStream = new FileStream();
            var isWritten:Boolean = true;

            try
            {
                // 실제 저장할 파일을 다시 써줌
                fs.open(ReplayFileCache.repFileTemp, FileMode.WRITE);
                fs.position = 0;
                // 파일 헤더, 리플레이 블록이 코덱 형식이면 이전 버전과 구분되게 V2FOFOPAINT
                fs.writeUTFBytes(ReplayDataCodec.isEncoded(replayFileByteArray) ? FileManager.REPLAY_FILE_HEADER_V2 : FileManager.REPLAY_FILE_HEADER_V1);
                fs.writeUnsignedInt(replayFileByteArray.length); // 뒤에 압축된 바이트를 얼마나 건너 뛰어야 하는지 저장
                fs.writeBytes(replayFileByteArray);

                // 임시 미러 플래그임
                if (ReplayState.lastMirrorReadyFlag) // 임시 미러가 되어있을때 진짜 캔버스로 반전되어있는데 리플레이 데이터에는 아직 써주지 않았으니까 넣어줌
                {
                    const tempMirrorData:Array = [["mirror"]];
                    fs.writeObject(tempMirrorData);
                }

                fs.writeObject(["rFirstImage", firstImageLayer1,
                                            firstImageLayer2,
                                            ReplaySaveMetaData.firstImageWidth,
                                            ReplaySaveMetaData.firstImageHeight,
                                            ReplaySaveMetaData.firstImageBG,
                                            ReplaySaveMetaData.firstImageMirrorFlag]);
                fs.writeObject(["rFinalImage", finalImageLayer1, finalImageLayer2, ReplaySaveMetaData.finalImageWidth,ReplaySaveMetaData.finalImageHeight,ReplaySaveMetaData.finalImageBG]);

                if (ReferenceLayerController.canvasRefLayerBitmapData)
                {
                    fs.writeObject(["refimage", referenceImage, // 1
                                ReplaySaveMetaData.refImageWidth,
                                ReplaySaveMetaData.refImageHeight,
                                ReplaySaveMetaData.refImageBitmapX,
                                ReplaySaveMetaData.refImageBitmapY,
                                ReplaySaveMetaData.refImageBitmapRotation,
                                ReplaySaveMetaData.refImageBitmapScaleX,
                                ReplaySaveMetaData.refImageBitmapScaleY,
                                ReplaySaveMetaData.refImageBitmapMirrorFlag,
                                ReplaySaveMetaData.refImageBitmapMoveSum,
                                ReplaySaveMetaData.refImageAlpha]);
                }

                // 타이밍 시트는 파일 맨 뒤에 둠. 읽을때 이 객체가 없으면 시트 없는 파일로 봄
                if (ReplayFileCache.rTimingSheetFileObject !== null)
                {
                    fs.writeObject(ReplayFileCache.rTimingSheetFileObject);
                }

                fs.close();
            }
            catch (writeErr:Error)
            {
                // 임시 파일 쓰기 실패(디스크 부족, 잠김 등), 아래에서 저장 잠금을 풀고 새 파일로 저장해줌
                isWritten = false;

                try
                {
                    fs.close();
                }
                catch (closeErr:Error)
                {
                }
            }

            ReplayFileCache.rTimingSheetFileObject = null;
            firstImageLayer1.clear();
            firstImageLayer2.clear();
            finalImageLayer1.clear();
            finalImageLayer2.clear();
            referenceImage.clear();
            replayFileByteArray.clear();
            firstImageLayer1 = null;
            firstImageLayer2 = null;
            finalImageLayer1 = null;
            finalImageLayer2 = null;
            referenceImage = null;
            replayFileByteArray = null;

            var savedFile:File;

            try
            {
                if (isWritten === false)
                {
                    throw new Error("replay temp file write failed");
                }
                const newPath:String = ReplayFileCache.getReplayFileNameFromPath(FileManager.lastSaveFilePath);
                savedFile = new File(newPath);
                ReplayFileCache.repFileTemp.moveTo(savedFile, true);
            }
            catch (err:Error)
            {
                // 파일 엑세스가 불가하므로 새로운 파일로 저장해줌

                if (BackgroundWorkerCoordinator.isSaveInProgress === 1)
                {
                    BackgroundWorkerCoordinator.isSaveInProgress = 0;
                }

                FileManager.openSaveFileBrowser(true, true);
                return;
            }

            if (BackgroundWorkerCoordinator.isSaveInProgress === 1)
            {
                BackgroundWorkerCoordinator.isSaveInProgress = 0;
            }

            HintController.showMouseHintTemp("Saved (" + (getTimer() - FileManager.saveStartTime) + " ms, " + ReplayFileCache.formatFileSize(savedFile.size) + ")",10.0);
        }

    }
}
