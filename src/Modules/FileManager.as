package Modules
{
    import Modules.Tools.LassoTool;
    import Modules.Tools.PenTool;

    import Symbols.LoadBoxSet;

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
    import Modules.Tools.LineTool;

    public class FileManager
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
            replayCacheImageFrameDataFilePath = dataFolderPath.resolvePath("jumpframedata");
        }
        // todo load box는 load box controller로 따로 분리, app state로 따로분리, app state save load 키값 파일에서 main 다른 클래스 스코프 되어있는지 조심
        // todo 저장할때 rdata undo 되어있을때 데이터가 사라짐 deepundo쪽은 그대로 살아있음
        private static var dataFolderPath:File;
        private static var isWritingCrashLog:Boolean = false;
        public static var appStateFilePath:File;
        public static var scratchPadDataFilePath:File;
        public static var undoDataFilePath:File;
        public static var myPaletteDataFilePath:File;
        public static var replayDataFilePath:File;
        public static var replayCacheImageFolderPath:File;
        public static var replayCacheImageFrameDataFilePath:File;
        public static const appUpTimePath:File = File.applicationStorageDirectory.resolvePath("appuptime");
        public static var repFileTemp:File; // 파일을 저장하거나 불러올때 씀

        public static const loadMenuBox:LoadBoxSet = new LoadBoxSet();

        // todo gpt한테 이 변수 곳곳에 쓰이는데 이를 최적화로  종합적으로 관리가 가능한지 묻기 아마 캔버스가 변경될때에만 내려주면 될것같은데 과연?
        public static var isFileAlreadySaved:Boolean = false; // 세이브 버튼 여러번 눌러서 데이터 계속 쓰여지는거 방지
        public static var isContinueSaveON:Boolean = false; // 한번 저장후에 다른이름으로 저장하기 전까지는 똑같은 이름으로 저장
        public static var lastSaveFileName:String = getRandomFileName(); // 세이브 파일 저장후에 이름을 이쪽에다가 보관해서 계속 그 이름으로 저장할수있게함
        public static var lastSaveFilePath:String = lastSaveFileName; // 파일 저장경로로 계속 저장 초기에는 filename이랑 똑같게 해줌
        private static var lastSaveCaptureFilePath:String = lastSaveFileName;
        private static var rLayer1FirstImageData:ByteArray = new ByteArray(); // 리플레이 데이터 저장해줄때 쓰는 바이트 배열 전역으로 돌려서 새로운 객체 하나만 생성하도록함
        private static var rLayer2FirstImageData:ByteArray = new ByteArray();
        private static var rLayer1CurrentImageData:ByteArray = new ByteArray();
        private static var rLayer2CurrentImageData:ByteArray = new ByteArray();
        private static var replayDataReadBytes:ByteArray = new ByteArray();

        public static var isLoadPendingAfterSaving:Boolean = false;
        public static var isFileBrowserOpened:Boolean = false;
        public static var lastLoadedFile:File;
        private static var loadMenuBoxBitmapData:BitmapData;
        private static var loadMenuBoxFileType:String;
        private static var loadMenuBoxFile:File;

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
                if (now.month + 1 < 10) dateKey += "0";
                dateKey += String(now.month + 1);
                if (now.date < 10) dateKey += "0";
                dateKey += String(now.date);

                const logFolder:File = dataFolderPath.resolvePath("log");
                logFolder.createDirectory();
                const logFile:File = logFolder.resolvePath("fofo_crash_log_" + dateKey + ".txt");
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
            fs.open(FileManager.replayCacheImageFrameDataFilePath, FileMode.WRITE);
            fs.writeObject(ReplayController.rJumpImageFrameData);
            fs.close();
        }

        public static function loadFOFOFile(oldFile:File):void // loadrep
        {
            if (FileManager.isTrue2020File(oldFile) === false)
            {
                FileManager.showLoadFaildMouseHint();
                return;
            }

            const fs:FileStream = new FileStream();
            var imgStartByte:uint = 0;
            var imgW:uint = 0;
            var imgH:uint = 0;
            var bg:uint = 0;
            const rect:Rectangle = new Rectangle();
            ReplayController.initializeReplayDataFile(true); // 일단 썸네일 이미지랑 리플레이 데이터 청소\
            oldFile.copyTo(repFileTemp, true); // repdata.c3p를 복사 덮어씌우기

            if (ReferenceLayerController.refLayerRawTransformData)
            {
                ReferenceLayerController.refLayerRawBitmapData.dispose();
                ReferenceLayerController.refLayerRawBitmapData = null;
                ReferenceLayerController.refLayerRawTransformData = null;
            }

            fs.open(repFileTemp, FileMode.READ);
            ReplayController.rJumpImageFrameData = [0];
            var d:Array;
            var ba:ByteArray;
            var replayData:ByteArray = new ByteArray();
            const isNew2020FileFlag:Boolean = FileManager.isNew2020File(oldFile);

            if (isNew2020FileFlag)
            {
                const a:String = fs.readUTFBytes(9); // FOFOPAINT헤더 읽어줌
                const compBytes:uint = fs.readUnsignedInt(); // 압축된 데이터 길이 읽어줌

                if (compBytes > 0)
                {
                    // 압축된 데이터 써주고 압축 풀어줌
                    fs.readBytes(replayData, 0, compBytes);
                    replayData.uncompress();
                    if (ReplayDataCodec.isEncoded(replayData))
                    {
                        const decodedReplayData:ByteArray = ReplayDataCodec.decode(replayData);
                        replayData.clear();
                        replayData = decodedReplayData;
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
                        ReplayController.rFirstImageLayer1BitmapData = new BitmapData(d[2], d[3], true, 0);
                        ReplayController.rFirstImageLayer1BitmapData.lock();
                        ReplayController.rFirstImageLayer1BitmapData.setPixels(rect, ba);
                        ReplayController.rFirstImageLayer1BitmapData.unlock();
                        ba.clear();
                        ba = null;
                        ReplayController.rLastCanvasBGColor = d[4];
                        ReplayController.updateCanvasBGColorReplayMode(ReplayController.rLastCanvasBGColor);
                        ReplayController.createFirstImageCache(ReplayController.rFirstImageLayer1BitmapData, null, d[4]);
                    }
                    else // 신버전
                    {
                        ba = d[1] as ByteArray;
                        rect.setTo(0, 0, d[3], d[4]);
                        ba.uncompress();
                        ReplayController.rFirstImageLayer1BitmapData = new BitmapData(d[3], d[4], true, 0);
                        ReplayController.rFirstImageLayer1BitmapData.lock();
                        ReplayController.rFirstImageLayer1BitmapData.setPixels(rect, ba);
                        ReplayController.rFirstImageLayer1BitmapData.unlock();
                        ba.clear();
                        ba = d[2] as ByteArray;
                        ba.uncompress();
                        ReplayController.rFirstImageLayer2BitmapData = new BitmapData(d[3], d[4], true, 0);
                        ReplayController.rFirstImageLayer2BitmapData.lock();
                        ReplayController.rFirstImageLayer2BitmapData.setPixels(rect, ba);
                        ReplayController.rFirstImageLayer2BitmapData.unlock();
                        ba.clear();
                        ba = null;
                        ReplayController.rLastCanvasBGColor = d[5];
                        ReplayController.updateCanvasBGColorReplayMode(ReplayController.rLastCanvasBGColor);
                        // air sdk 이전이후 첫 패치된거라서 값이 있으면 읽어주어야함 불리언 값
                        const firstMirrorFlag:Boolean = d.length > 6 && d[6] === true;
                        if (d[6])
                        {
                            ReplayController.rMirrorON = firstMirrorFlag;
                        }
                        ReplayController.createFirstImageCache(ReplayController.rFirstImageLayer1BitmapData, ReplayController.rFirstImageLayer2BitmapData, d[5], firstMirrorFlag); // 0.cache 파일 갱신
                    }
                }
                else if (d[0] === "rFinalImage")
                {
                    // 아래에서 imgStartByte로 세고있어서 이걸 안넣으면 바이트 읽기 순서가 어긋남 지우면 안됨
                }
                else if (d[0] === "refimage" || d[0] === "traceImage")
                {
                    ba = d[1] as ByteArray;
                    rect.setTo(0, 0, d[2], d[3]);
                    ba.uncompress();
                    ReferenceLayerController.refLayerRawBitmapData = new BitmapData(d[2], d[3], true, 0);
                    ReferenceLayerController.refLayerRawBitmapData.lock();
                    ReferenceLayerController.refLayerRawBitmapData.setPixels(rect, ba);
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
                fs.open(FileManager.replayDataFilePath, FileMode.WRITE);
                fs.position = 0;
                fs.writeBytes(replayData);
                fs.close();
            }
            else
            {
                // 이미지직전까지 바이트를 기준으로 짤라줌, 즉 뒤에 붙은 첫 이미지 + 마지막 이미지를 지워줌
                fs.open(repFileTemp, FileMode.UPDATE);
                fs.position = imgStartByte;
                fs.truncate();
                fs.close();
                repFileTemp.moveTo(FileManager.replayDataFilePath, true);
            }

            if (repFileTemp.exists)
            {
                repFileTemp.deleteFile();
            }

            replayData.clear();
            replayData = null;
            FileManager.finalizeLoadFile(0, 0, null, null, false, 0);
            ReplayController.startGeneratingReplayCacheImage(true,null);
        }

        public static function loadImageFile(width:Number, height:Number, layer1Image:IBitmapDrawable, layer2Image:IBitmapDrawable):void
        {
            ReplayController.updateTotalFrameAndReplayMaxSpeedFor10Sec(0);
            ReplayController.setRFileTotalFrame(0);
            ReplayController.rReplayImageCacheState = ReplayController.REPLAY_IMAGE_CAHCHE_COMPLETE;
            ReferenceLayerController.refLayerRawBitmapData = null;
            ReferenceLayerController.refLayerRawTransformData = null;
            FileManager.finalizeLoadFile(width, height, layer1Image, layer2Image, true, 0xFFFFFF);
            ReplayController.initializeReplayDataFile(true); // 일단 썸네일 이미지랑 리플레이 데이터 청소
            ReplayController.createFirstImageCache(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
        }

        public static function resetDrawAndReplayCanvasState(canvasWidth:Number,canvasHeight:Number):void
        {
            CanvasController.canvasAnchorPoint.rotation = 0;
            ReplayController.setRcursorRotation(0);
            CanvasController.canvasZoomIndex = 3;
            CanvasController.updateCanvasScale(1.0);
            CanvasController.setCavnvasSizeDrawMode(canvasWidth, canvasHeight, 0, 0, false);
            CanvasController.updateCanvasPanelColorAndSize();
            ReplayController.setReplayCanvasBmpdFromDrawMode();
            ReplayController.setReplayCanvasStateFromDrawMode();
            CanvasController.centerCanvas("draw");
        }

        public static function finalizeLoadFile(width:uint, height:uint, imageData:IBitmapDrawable, imageData1:IBitmapDrawable, imageOnlyFlag:Boolean, bgColor:uint):void
        {
            if (CaptureController.isCaptureModeON)
            {
                CaptureController.handleExitCaptureMode();
            }

            ReplayController.resetReplaySpeedBar();
            ReplayController.resetReplayTime();
            ReplayController.clearCanvasReplayMode();
            ReplayController.updateReplayPrograssText(true, 0);
            MainUI.seekBarBox.resetReplayPrograssBarWidth();

            if(bgColor > 0)
            {
                CanvasController.setCanvasBGColorDrawMode(bgColor);
                ReplayController.updateCanvasBGColorReplayMode(bgColor);
            }

            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowBGColor(CanvasController.CANVAS_BG_COLOR, ImageViewWindow.canvasWindowLayer1Bitmap.bitmapData);
            }

            // updateLastFilePathByRandomFileName();
            isContinueSaveON = false; // 연속 세이브 플래그 취소
            ReplayController.rMirrorON = false;
            CanvasController.isCanvasMirrored = false;
            UndoManager.mirrorCommandReady = false;
            CanvasController.canvasInfoBox.setMirror(false);
            CanvasGridOverlay.updateGridMirror(false);
            LassoTool.cancelIfActive();

            if (FillPenTool.isStarted)
            {
                FillPenTool.cancel();
            }
            else if(LineTool.isStarted)            
            {
                LineTool.cancel();
            }

            if(width > 0 && height > 0 && (imageData || imageData1))
            {
                var maxLength:Number = (width > height) ? width : height;
                var scaleLimitMultiplier:Number = (maxLength > CanvasController.CANVAS_MAX_SIZE) ? CanvasController.CANVAS_MAX_SIZE / maxLength : 1.0;
                const limitedImageWidth:Number = Math.floor(width * scaleLimitMultiplier);
                const limitedImageHeight:Number = Math.floor(height * scaleLimitMultiplier); // CANVAS_MAX_SIZE 값을 넘으면 리사이즈 해줌
                var scaleMat:Matrix = new Matrix();
                scaleMat.scale(scaleLimitMultiplier, scaleLimitMultiplier);
                // 최종표시이미지 깔아주ㄱ load fofo에서는 리플레이 명령그대로 입력을 최종 깔아주므로 필요가 없음
                var tmpbmpd:BitmapData = new BitmapData(limitedImageWidth, limitedImageHeight, true, 0);

                if (imageData !== null)
                {
                    tmpbmpd.draw(imageData, scaleMat, null, null, null, true);
                    CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, tmpbmpd, CanvasController.canvasLayer1Bitmap);

                    if (imageOnlyFlag)
                    {
                        if (ReplayController.rFirstImageLayer1BitmapData && tmpbmpd !== ReplayController.rFirstImageLayer1BitmapData)
                            ReplayController.rFirstImageLayer1BitmapData.dispose();
                        ReplayController.rFirstImageLayer1BitmapData = tmpbmpd.clone(); // 이미지만 불러와주면 첫 이미지를 갱신해줌
                    }
                }

                if (imageData1 !== null)
                {
                    tmpbmpd.fillRect(new Rectangle(0, 0, limitedImageWidth, limitedImageHeight), 0);
                    tmpbmpd.draw(imageData1, scaleMat, null, null, null, true);
                    CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, tmpbmpd, CanvasController.canvasLayer2Bitmap);
                    if (imageOnlyFlag)
                    {
                        ReplayController.rFirstImageLayer2BitmapData = tmpbmpd.clone();
                    }
                }
                else
                {
                    CanvasController.canvasLayer2BitmapData = new BitmapData(CanvasController.canvasLayer1BitmapData.width, CanvasController.canvasLayer1BitmapData.height, true, 0);
                    CanvasController.canvasLayer2Bitmap.bitmapData = CanvasController.canvasLayer2BitmapData;
                }
                
                tmpbmpd.dispose();
                tmpbmpd = null;
                resetDrawAndReplayCanvasState(limitedImageWidth,limitedImageHeight);
                UndoManager.resetUndoState();
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
            MainUIController.updateWindowTitle();
            CanvasController.selectLayer1(false);
            ReplayController.selectReplaySubLayer(false);
            if (ToolController.toolOptionsBox.layer1CheckedButton.visible)
            {
                CanvasController.toggleLayer1Check();
            }
            if (ToolController.toolOptionsBox.layer2CheckedButton.visible)
            {
                CanvasController.toggleLayer2Check();
            }
            MainUIController.updateResizeButtonPos(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
            InputManager.removeKeyRepeatEvents(null);
            CanvasController.canvasLayer1Bitmap.visible = true;
            CanvasController.canvasLayer2Bitmap.visible = true;
            MainUI.topBar.captureButton.alpha = 1.0;
            MainUI.topBar.newFileButton.alpha = 1.0;
            ReferenceLayerController.refLayerMenuBox.refTransferCanvasImageButton.alpha = 1.0;
            ColorPickerController.selectCurrentColor(false);
            ToolController.selectPenToolIfNotDrawingTool(false);
            CanvasController.canvasNavigatorBox.updateImage();
            MainUIController.updateCanvasNaigatorCursor();
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
                ImageViewWindow.canvasWindowIgnoreResizeEventFlag = true;
                ImageViewWindow.updateCanvasWindowBitmapSize();
            }
            CaptureController.resetCaptureCanvasChangeValue();
            lastLoadedFile = null;
            isLoadPendingAfterSaving = false;
            closeLoadMenuBox();
        }

        public static function closeLoadMenuBox():void
        {
            main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownLoadMenuBox);
            loadMenuBox.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownLoadMenuBox);
            loadMenuBox.visible = false;
        }

        public static function openLoadMenuBoxOnClosing():void
        {
            if (loadMenuBox.visible === false)
            {
                const bmpd:BitmapData = CanvasController.getMergedBitmapdtata(false, true, true, null);
                loadMenuBox.setPreviewImage(bmpd);
                loadMenuBox.showPleaseWait("Closing fofo paint...");
                loadMenuBox.updateClickBlockerSize(main.stage.stageWidth, main.stage.stageHeight);
                Utils.setAsTopChild(loadMenuBox);
                loadMenuBox.visible = true;
            }
        }

        public static function openLoadMenuBox():void
        {
            if (loadMenuBox.visible === false)
            {
                main.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownLoadMenuBox);
                loadMenuBox.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownLoadMenuBox);
                loadMenuBox.visible = true;
            }
            loadMenuBox.updateClickBlockerSize(main.stage.stageWidth, main.stage.stageHeight);
            Utils.setAsTopChild(loadMenuBox);
        }

        private static function getJumpImageFolder():File
        {
            return File.applicationStorageDirectory.resolvePath("imagecache");
        }

        public static function initializeRepTempFile():void
        {
            repFileTemp = File.applicationStorageDirectory.resolvePath("tmp\\tmp_" + Utils.getRandomString(32));
        }

        private static function handleLoadMenuBoxClick(oldTargetName:String):void
        {
            loadMenuBox.addEventListener(MouseEvent.MOUSE_UP, onMouseUpLoadMenuBox);
            function onMouseUpLoadMenuBox(e:MouseEvent):void
            {
                loadMenuBox.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpLoadMenuBox);
                if (!e.target || e.target.alpha < 1.0)
                {
                    return;
                }
                if (oldTargetName === e.target.name
                        && isLoadPendingAfterSaving === false && BackgroundWorkerCoordinator.isSaveInProgress === 0 && !isFileBrowserOpened)
                {
                    switch (e.target.name)
                    {
                        case "dragDropLoadButton":
                            {
                                if (!loadMenuBox.isRefLayerLoadMode())
                                {
                                    closeLoadMenuBox();
                                    loadFileTo("canvas");
                                }
                            }
                            break;
                        case "dragDropSaveAndLoadButton":
                            {
                                if (!loadMenuBox.isRefLayerLoadMode())
                                {
                                    isLoadPendingAfterSaving = true;
                                    loadMenuBox.showPleaseWait("Saving in progress...");
                                    openSaveFileBrowser(false);
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
            MainUI.showMouseHintTemp("Load failed");
            MainUI.mouseHint.y = main.stage.mouseY;
            MainUI.mouseHint.x = main.stage.mouseX;
        }

        public static function setFileBrowserIsOpen(flag:Boolean):void
        {
            isFileBrowserOpened = flag;
            InputManager.clearKeyBuffer();
        }

        public static function updateLastFilePathByRandomFileName():void
        {
            const newFileName:String = getRandomFileName();
            lastSaveFileName = newFileName;
            lastSaveFilePath = getDirectoryOnly(lastSaveFilePath) + File.separator + newFileName;
        }

        private static function getRandomFileName():String
        {
            return CaptureStamp.getTimeStampTailHead() + "_" + Utils.getRandomString(8) + ".png";
        }

        public static function enableNewFileButton():void
        {
            if (!BackgroundWorkerCoordinator.isSaveInProgress && MainUI.topBar.newFileButton.alpha < 1.0)
            {
                MainUI.topBar.newFileButton.alpha = 1.0;
            }
            if (ToolController.toolOptionsBox.layerMergeButton.alpha < 1.0)
            {
                ToolController.toolOptionsBox.layerMergeButton.alpha = 1.0;
            }
            MainUIController.markWindowTitleAsDirty();
        }

        private static function getFinalBitmapDataFrom2020File(file:File, bgFlag:Boolean):BitmapData
        {
            const fs:FileStream = new FileStream();
            fs.open(file, FileMode.READ);
            var finalIMGBMPD:BitmapData;
            var finalIMGBMPD1:BitmapData;
            if (isNew2020File(file))
            {
                fs.readUTFBytes(9); // FOFOPAINT헤더 읽어줌
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
                        finalIMGBMPD.setPixels(newRectangle, ba);
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
                        finalIMGBMPD.setPixels(newRectangle, ba);
                        finalIMGBMPD.unlock();
                        ba.clear();
                        ba = d[1] as ByteArray;
                        ba.uncompress();
                        finalIMGBMPD1 = new BitmapData(d[3], d[4], true, 0);
                        finalIMGBMPD1.lock();
                        finalIMGBMPD1.setPixels(newRectangle, ba);
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

        public static function isNew2020File(file:File):Boolean
        {
            if (!file)
            {
                return false;
            }
            const fs:FileStream = new FileStream();
            fs.open(file, FileMode.READ);
            try
            {
                const header:String = fs.readUTFBytes(9);
                if (header === "FOFOPAINT")
                {
                    fs.close();
                    return true;
                }
                fs.close();
                fs.open(file, FileMode.READ);
            }
            catch (err:Error)
            {
                fs.close();
                return false;
            }
            return false;
        }
        private static function isOld2020File(file:File):Boolean
        {
            const fs:FileStream = new FileStream();
            fs.open(file, FileMode.READ);
            try
            {
                // 구버전 파일 읽기 헤더가 없고 바로 배열임
                const arr:Array = (fs.readObject() as Array);
                if (!arr)
                    return false;
                if (!(arr[0][0] is String))
                    return false;
                fs.close();
                return true;
            }
            catch (err:Error)
            {
                fs.close();
                return false;
            }
            return false;
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
        private static function isImageFileExt(path:String):Boolean
        {
            // 가장 마지막 확장자만 따짐
            const gif:int = path.lastIndexOf(".gif");
            const jpg:int = path.lastIndexOf(".jpg");
            const png:int = path.lastIndexOf(".png");
            const find2020:int = path.lastIndexOf(".2020");
            const maxIndex:int = Math.max(gif, jpg, png, find2020);
            return maxIndex === find2020;
        }
        public static function createNewFile(fromShortcut:Boolean):void
        {
            InputManager.startPressHoldKey((!fromShortcut) ? MainUI.topBar.newFileButton : null, HintStrings.getNewFileHintString(), null, CanvasController.resetAllCanvasAndReplayData, null);
        }
        public static function openLocalManualFolder():void
        {
            var targetFolder:File = File.applicationDirectory.resolvePath("manual");
            if (targetFolder.exists && targetFolder.isDirectory)
            {
                var request:URLRequest = new URLRequest(targetFolder.url);
                navigateToURL(request);
            }
        }

        private static function keyDownLoadMenuBox(e:KeyboardEvent):void
        {
            const firstKey:uint = InputManager.getFirstPressedKey();
            if (firstKey === InputManager.KEY.esc || firstKey === InputManager.KEY.backspace)
            {
                closeLoadMenuBox();
            }
        }
        public static function prepareOpenLoadBox(fromUpdate:Boolean, reflayermenu:Boolean, file:File, bmpd:BitmapData, filetype:String):void
        {
            InputManager.clearKeyBuffer();
            ToolController.closeToolBox2();
            loadMenuBoxFileType = filetype;
            loadMenuBoxFile = file;
            loadMenuBoxBitmapData = bmpd;

            if (LassoTool._isLassoToolStarted === true)
            {
                LassoTool.cancelLassoTool();
                ToolController.resetLastTool();
                ToolController.selectPenTool();
            }

            if (bmpd)
            {
                loadMenuBox.setPreviewImage(bmpd);
                loadMenuBox.updateClickBlockerSize(main.stage.stageWidth, main.stage.stageHeight);
            }
            if (loadMenuBox.visible === false)
            {
                loadMenuBox.updateUIColor();
                if (fromUpdate)
                {
                    loadMenuBox.showPleaseWait("Waiting for the file to be saved");
                }
                else
                {
                    loadMenuBox.hidePleaseWait();
                    if (reflayermenu)
                    {
                        loadMenuBox.activateReflayerButtonOnly();
                    }
                    else
                    {
                        loadMenuBox.activateAllButtons();
                    }
                }
                openLoadMenuBox();
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
        public static function canDisplayLoadMenuBox(file:File):Boolean
        {
            return !loadMenuBox.visible || !isSameFile(file, lastLoadedFile);
        }
        public static function prepareLoadMenuBoxFromImageFile(file:File, toRefLayer:Boolean):void
        {
            validateImageFile(file,
                    function (type:String, file:File, bmpd:BitmapData):void
                    {
                        lastLoadedFile = file;
                        if (type === "image")
                        {
                            prepareOpenLoadBox(false, toRefLayer, file, bmpd, "image");
                        }
                        else if (type === "2020")
                        {
                            prepareOpenLoadBox(false, toRefLayer, file, getFinalBitmapDataFrom2020File(file, true), "2020");
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

        public static function isFileLoadBlocked():Boolean
        {
            return isFileBrowserOpened || BackgroundWorkerCoordinator.isSaveInProgress
                || ReplayController.isGeneratingCacheImages();
        }

        // 운영체제에서 2020파일 연결을 FOFOPAINT로 해줬을때
        public static function onInvokeEvent(e:InvokeEvent):void
        {
            if (isFileLoadBlocked())
            {
                e.preventDefault();
                return;
            }
            var arguments:Array = e.arguments;
            if (arguments && arguments.length > 0)
            {
                try
                {
                    var file:File = new File(arguments[0] as String);
                    if (file.exists)
                    {
                        if (!canDisplayLoadMenuBox(file))
                        {
                            return;
                        }
                        lastLoadedFile = file;
                        if (ReplayController.isReplayStarted)
                        {
                            ReplayController.stopReplay();
                        }
                        if (ReplayController.isReplayRestartTimerON())
                        {
                            ReplayController.cancelReplayRestartTimer();
                        }
                        prepareLoadMenuBoxFromImageFile(file, false);
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
            ReplayController.rFileStream.close();
            ReplayController.cancelReplayRestartTimer();
            const data:Array = e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
            if (data && data.length > 0)
            {
                const file:File = data[0] as File;
                if (canDisplayLoadMenuBox(file))
                {
                    prepareLoadMenuBoxFromImageFile(file, false);
                    return;
                }
            }
        }

        public static function loadFileTo(where:String):void
        {
            if (where === "reflayer")
            {
                if (loadMenuBoxBitmapData)
                {
                    ReferenceLayerController.transferLoadedImageToRefLayer(loadMenuBoxBitmapData, loadMenuBoxBitmapData.width, loadMenuBoxBitmapData.height);
                    if (!ReplayController.isReplayModeON && !CaptureController.isCaptureModeON)
                    {
                        ReferenceLayerController.openRefLayerMenu();
                    }
                    loadMenuBoxBitmapData.dispose();
                    loadMenuBoxBitmapData = null;
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
                            lastSaveFileName = loadMenuBoxFile.name;
                            lastSaveFilePath = loadMenuBoxFile.nativePath;
                            enterDrawModeOnLoadFile();
                            // todo : load repllay file은 따로?
                            loadFOFOFile(loadMenuBoxFile);
                            loadMenuBoxFile = null;
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
                        enterDrawModeOnLoadFile();
                        lastSaveFileName = loadMenuBoxFile.name;
                        lastSaveFilePath = loadMenuBoxFile.nativePath;
                        loadImageFile(loadMenuBoxBitmapData.width, loadMenuBoxBitmapData.height, loadMenuBoxBitmapData, null);
                    }
                }
                else
                {
                    showLoadFaildMouseHint();
                }
            }
            else if (loadMenuBoxFileType === "clipboard")
            {
                enterDrawModeOnLoadFile();
                lastSaveFileName = getRandomFileName();
                loadImageFile(loadMenuBoxBitmapData.width, loadMenuBoxBitmapData.height, loadMenuBoxBitmapData, null);
            }
        }

        public static function enableFileOperationButtonsTopbar():void
        {
            MainUI.topBar.enableFileOperationButtons(ClipboardManager.isClipBoardButtonActivated);
            if (ReplayController.isReplayModeON)
            {
                ReplayController.updateDeleteReplayDataButtonsState();
            }
        }
        private static function disableFileOperationButtonsTopbar():void
        {
            if (BackgroundWorkerCoordinator.isSaveInProgress === 0)
            {
                BackgroundWorkerCoordinator.isSaveInProgress = 1;
            }
            if (MainUI.topBar.saveButton.alpha === 1.0)
            {
                MainUI.topBar.disableFileOperationButtons();
            }
        }
        private static function saveFOFOFile():void
        {
            if (replayDataFilePath.exists)
            {
                rLayer1FirstImageData.position = 0;
                rLayer2FirstImageData.position = 0;
                rLayer1CurrentImageData.position = 0;
                rLayer2CurrentImageData.position = 0;
                ReferenceLayerController.refLayerImageData.position = 0;
                replayDataReadBytes.position = 0;
                rLayer1FirstImageData.length = 0;
                rLayer2FirstImageData.length = 0;
                rLayer1CurrentImageData.length = 0;
                rLayer2CurrentImageData.length = 0;
                ReferenceLayerController.refLayerImageData.length = 0;
                replayDataReadBytes.length = 0;
                ReplayController.lastMirrorReadyFlag = UndoManager.mirrorCommandReady;

                // 첫번째 이미지 레이어 1 2 저장
                const rImgDataW:Number = ReplayController.rFirstImageLayer1BitmapData.width;
                const rImgDataH:Number = ReplayController.rFirstImageLayer1BitmapData.height;
                var newRectangle:Rectangle = new Rectangle(0, 0, rImgDataW, rImgDataH);
                ReplayController.rFirstImageLayer1BitmapData.copyPixelsToByteArray(newRectangle, rLayer1FirstImageData);
                ReplayController.rFirstImageLayer2BitmapData.copyPixelsToByteArray(newRectangle, rLayer2FirstImageData);
                // 현재 캔버스 이미지 레이어 1 2 저장
                newRectangle = new Rectangle(0, 0, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
                CanvasController.canvasLayer1BitmapData.copyPixelsToByteArray(newRectangle, rLayer1CurrentImageData);
                CanvasController.canvasLayer2BitmapData.copyPixelsToByteArray(newRectangle, rLayer2CurrentImageData);
                // 참고 레이어 이미지 저장
                if (ReferenceLayerController.canvasRefLayerBitmapData)
                {
                    const refImgWidth:Number = ReferenceLayerController.canvasRefLayerBitmapData.width;
                    const refImgHeight:Number = ReferenceLayerController.canvasRefLayerBitmapData.height;
                    newRectangle = new Rectangle(0, 0, refImgWidth, refImgHeight);
                    ReferenceLayerController.canvasRefLayerBitmapData.copyPixelsToByteArray(newRectangle, ReferenceLayerController.refLayerImageData);
                }
                // 리플레이 파일을 임시파일로 복사해서 이 내부의 바이트만 읽어서 워커에게 보냄
                replayDataFilePath.copyTo(repFileTemp, true);

                const fs:FileStream = new FileStream();

                // 딥 언도일때는 읽은 바이트 까지만 읽어줌
                if (UndoManager.isDeepUndoEnabled)
                {
                    // 마지막 바이트가 0이상일때만 읽어주어야함
                    // ReplayController.rFileLastBytePosition = 0이면 안읽는것이 아니고 전체 바이트를 읽음그래서 0이면 안읽게 해주어야함
                    if (ReplayController.rFileLastBytePosition > 0)
                    {
                        fs.open(repFileTemp, FileMode.READ);
                        fs.position = 0;
                        fs.readBytes(replayDataReadBytes, 0, ReplayController.rFileLastBytePosition);
                        fs.close();
                    }
                }
                else
                {
                    // 그게 아니면 전체 리플레이 데이터 끝까지 읽고 undo데이터까지 넣어줌
                    fs.open(repFileTemp, FileMode.READ);
                    fs.position = 0;
                    fs.readBytes(replayDataReadBytes, 0, fs.bytesAvailable);
                    fs.close();

                    replayDataReadBytes.position = replayDataReadBytes.length;
                    for (var i:int = 0, len:int = UndoManager.undoDataIndex;i <= len;i++) // 리플레이 데이터랑 첫이미지 마지막 이미지 추가적으로 붙여줌
                    {
                        if (ReplayController.rData[i] && ReplayController.rData[i].length === 0)
                        {
                            continue;
                        }
                        replayDataReadBytes.writeObject(ReplayController.rData[i]);
                    }
                }
                BackgroundWorkerCoordinator.startReplayDataCompressionWorker(rLayer1FirstImageData, rLayer2FirstImageData, rLayer1CurrentImageData, rLayer2CurrentImageData, ReferenceLayerController.refLayerImageData, replayDataReadBytes);
            }
        }

        public static function openLoadFileBrowser(toRefLayer:Boolean = false):void
        {
            if (ReplayController.isReplayStarted)
            {
                ReplayController.stopReplay();
            }
            if (LassoTool._isLassoToolStarted || isFileBrowserOpened
            || FillPenTool.isStarted || LineTool.isStarted
            || BackgroundWorkerCoordinator.isSaveInProgress)
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
                prepareLoadMenuBoxFromImageFile(file, toRefLayer);
            }
            setFileBrowserIsOpen(true);
            MainUIController.showCanvasResizeButtonVisibleDelay(false);
            InputManager.removeInputEventsReplayMode();
            InputManager.removeInputEventsDrawMode();
            file.browseForOpen(windowTitle, [new FileFilter("All supported formats", "*.2020;*.png;*.jpg;*.jpeg;*.jfif;*.gif;*.webp")]);
            file.addEventListener(Event.SELECT, onFileSelected);
            file.addEventListener(Event.COMPLETE, onFileSelectComplete);
            file.addEventListener(Event.CANCEL, onFileSelectCancel);
        }

        public static function saveCaptureImage():void
        {
            if (isFileBrowserOpened)
            {
                return;
            }
            CaptureController.executeCaptureFlashEffect();
            const replayMode:Boolean = ReplayController.isReplayModeON;
            var name:String = lastSaveFileName;
            var path:String = getExistingParentDirectory(lastSaveCaptureFilePath);
            setFileBrowserIsOpen(true);
            name = CaptureStamp.cutTimeStamp(name);
            name = name.substr(0, name.lastIndexOf(".png")) + "_capture_" + CaptureStamp.getTimeStampTail() + ".png"; // 뒤에 프레임 번호 붙여줌
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
                BackgroundWorkerCoordinator.captureImageDataQueue.push([file.name, e.target.nativePath]);
                BackgroundWorkerCoordinator.startPngEncodingWorker(CaptureController.getCaptrueImageBitmapdata(false), 0, true, CaptureController.isCaptureTransparentBGShowing);
                BackgroundWorkerCoordinator.pollTimerWaitWorkerForSaveCaptureImage();
            }
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
                // 파일 쓰기가 실패하면 뒤에 new 붙임
                filePath = _path.substr(0, _path.lastIndexOf(".png")) + "_copy.png";
                fileName = _name.substr(0, _name.lastIndexOf(".png")) + "_copy.png";
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

        private static function convertToPNGFilePath(path:String):String
        {
            const extArr:Array = [".2020", ".jpg", ".jpeg", ".gif", "jfif"];
            var pathOnly:String = getDirectoryOnly(path) + File.separator;
            var name:String = getFileNameFromPath(path);
            for (var i:uint = 0;i < 3;i++)
            {
                if (name.toLowerCase().lastIndexOf(extArr[i]) !== -1)
                {
                    return pathOnly + name.substr(0, name.lastIndexOf(extArr[i])) + ".png";
                }
            }
            if (name.lastIndexOf(".png") === -1)
            {
                return pathOnly + name + ".png";
            }
            return path;
        }

        // 끝의 파일 구분자가 있으면 제거해줌
        private static function removeLastFileSeparator(path:String):String
        {
            if (path.charAt(path.length - 1) === File.separator)
            {
                return path.substring(0, path.length - 1);
            }
            return path;
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
            if (ReplayController.isReplayStarted)
            {
                ReplayController.stopReplay();
            }
            const continueFlag:Boolean = (isContinueSaveON === true && asFlag === false);
            const nextPath:String = getExistingParentDirectory(lastSaveFilePath);
            const replayFilePath:String = ReplayController.getReplayFileNameFromPath(lastSaveFilePath);
            const rawFile:File = new File(replayFilePath);
            if (nextPath === lastSaveFilePath && isFileAlreadySaved && continueFlag && rawFile.exists)
            {
                if (AppUpdater.isUpdatePendingAfterSaving)
                {
                    AppUpdater.startUpdate();
                }
                else if (isLoadPendingAfterSaving)
                {
                    loadFileTo("canvas");
                }
                else
                {
                    MainUI.showMouseHintTemp("Already saved");
                }
                return;
            }
            if (LassoTool._isLassoToolStarted || FillPenTool.isStarted || LineTool.isStarted || BackgroundWorkerCoordinator.isSaveInProgress)
            {
                return;
            }
            const fs:FileStream = new FileStream();
            const mergedImage:BitmapData = CanvasController.getMergedBitmapdtata(false, true, true, null);
            if (nextPath !== lastSaveFilePath)
            {
                lastSaveFilePath = nextPath;
            }
            function onErrorSaveFileContinue(e:Event):void
            {
                fs.close();
                fs.removeEventListener(IOErrorEvent.IO_ERROR, onErrorSaveFileContinue);
                isFileAlreadySaved = false;
                if (isLoadPendingAfterSaving)
                {
                    loadFileTo("canvas");
                }
                else
                {
                    openSaveFileBrowser(true, true);
                }
            }
            function pollTimerWaitWorkerForImageSave(lastPath:String, isContinueSave:Boolean):void
            {
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
            if (continueFlag)
            {
                if (rawFile.exists)
                {
                    disableFileOperationButtonsTopbar();
                    BackgroundWorkerCoordinator.receivedSaveImageDataFromWorker = null;
                    BackgroundWorkerCoordinator.startPngEncodingWorker(mergedImage.clone(), CanvasController.CANVAS_BG_COLOR, false, false);
                    saveFOFOFile();
                    MainUIController.updateWindowTitle();
                    InputManager.clearKeyBuffer();
                    isFileAlreadySaved = true;
                    pollTimerWaitWorkerForImageSave(lastSaveFilePath, true);
                }
                else // 파일을 못찾으면 새로 저장
                {
                    isContinueSaveON = false;
                    openSaveFileBrowser(true);
                }
            }
            else
            {
                if (isFileBrowserOpened)
                {
                    return;
                }
                const file:File = checkSaveFailedFileName(saveFailed);
                const saveWindowTitle:String = (saveFailed) ? "Failed to save file! save with new name"
                    : (asFlag === true) ? "Save file As.."
                    : (isLoadPendingAfterSaving) ? "Save file before load file"
                    : (AppUpdater.isUpdatePendingAfterSaving) ? "Save file before update" : "Save file";
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
                    setFileBrowserIsOpen(false);
                    file.cancel();
                    removeEvent();
                    if (isLoadPendingAfterSaving)
                    {
                        loadFileTo("canvas");
                    }
                    else if (AppUpdater.isUpdatePendingAfterSaving)
                    {
                        AppUpdater.startUpdate();
                    }
                }
                function onSelectEvent(e:Event):void
                {
                    setFileBrowserIsOpen(false);
                    disableFileOperationButtonsTopbar();
                    removeEvent();
                    isFileAlreadySaved = true;
                    isContinueSaveON = true;
                    lastSaveFilePath = convertToPNGFilePath(e.target.nativePath);
                    lastSaveFileName = getFileNameFromPath(lastSaveFilePath);
                    BackgroundWorkerCoordinator.receivedSaveImageDataFromWorker = null;
                    BackgroundWorkerCoordinator.startPngEncodingWorker(mergedImage.clone(), CanvasController.CANVAS_BG_COLOR, false, false);
                    saveFOFOFile();
                    MainUIController.updateWindowTitle();
                    pollTimerWaitWorkerForImageSave(lastSaveFilePath, false);
                }
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
            bmpd.setPixels(new Rectangle(0, 0, arr[1], arr[2]), arr[0]);
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
            AppStateManager.saveAppSatate();
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
                MainUIController.lastAppWindowState = 1;
                main.stage.nativeWindow.restore();
            }
            else
            {
                MainUIController.lastAppWindowState = 0;
                deleteTempDirectory();
                saveAllAppData();
                main.stage.nativeWindow.close();
            }
        }

        public static function onWindowDeactivate(e:Event):void
        {
            CanvasController.isMouseClickBlocked = true;
            main.resizeCanvas.exit(true);
            InputManager.clearKeyBuffer();
            InputManager.removeKeyRepeatEvents(null);
            FOFOTimer.remove("pressholdtimer");
            if (ToolController.isToolBox2Showing)
            {
                CanvasController.isRightMouseClicked = false;
                ToolController.closeToolBox2();
            }
            if (!SidebarController.isSidebarVisible)
            {
                SidebarController.startHidingSidebarTemporary();
            }
            if (getTimer() - main.lastWindowDeactivateTime >= 3000
                    && !BackgroundWorkerCoordinator.isSaveInProgress
                    && !isFileBrowserOpened
                    && !isLoadPendingAfterSaving
                    && !AppUpdater.isUpdatePendingAfterSaving
                    && !loadMenuBox.visible
                    && !ReplayController.isGeneratingCacheImages())
            {
                saveAllAppData();
            }
            main.lastWindowDeactivateTime = getTimer();
            if (SidebarController.isQuickSidebarActive && !UndoManager.isDeepUndoEnabled)
            {
                SidebarController.deactivateQuickSidebar();
            }
            if (ColorPickerController.numPadBox.visible)
            {
                ColorPickerController.closeNumpad();
            }
            if (ColorPickerController.numPadBox.isLCHSliderActive())
            {
                ColorPickerController.numPadBox.removeOKLCHMouseEvent();
            }
            if (ColorPickerController.colorPickerBox.scratchPad.isScratchStarted)
            {
                ColorPickerController.colorPickerBox.scratchPad.removeCheckMouseDistEvent();
            }
            MainUI.hideBottomHint();
            ToolController.selectLastUsedTool();
        }

        // todo 이것은 mainui controller로 가야하지 않을까
        private static function enterDrawModeOnLoadFile():void
        {
            if (CaptureController.isCaptureModeON)
            {
                CaptureController.exitCaptureMode();
            }
            if (ReplayController.isReplayModeON)
            {
                ReplayController.exitReplayMode();
            }
        }

        public static function onWindowClosingEvent(e:Event):void
        {
            main.isAppClosing = true;
            e.preventDefault();
            main.stage.nativeWindow.removeEventListener(Event.DEACTIVATE, onWindowDeactivate);
            InputManager.removeInputEventCaptrueMode();
            InputManager.removeInputEventsDrawMode();
            InputManager.removeInputEventsReplayMode();
            ActivityWorkTimer.stop();

            if (ImageViewWindow.canvasWindow !== null)
            {
                ImageViewWindow.canvasWindow.visible = false;
            }

            if (CaptureController.isCaptureModeON === true)
            {
                CaptureController.handleExitCaptureMode();
            }

            if (ReplayController.isReplayStarted === true)
            {
                ReplayController.stopReplay();
            }

            if (LassoTool.isLassoToolStarted)
            {
                LassoTool.cancelLassoTool();
            }

            if (BackgroundWorkerCoordinator.isWorkerRunning())
            {
                if (!FOFOTimer.hasTimer("pollTimerWaitWorkerStop"))
                {
                    main.stage.nativeWindow.title = "Waiting for remaining tasks...";
                    openLoadMenuBoxOnClosing();
                    FOFOTimer.addByName("pollTimerWaitWorkerStop", BackgroundWorkerCoordinator.getWaitPollingInterval(), true, function ():Boolean
                        {
                            if (BackgroundWorkerCoordinator.isWorkerStopped())
                            {
                                FOFOTimer.remove("pollTimerWaitWorkerStop");
                                checkWindowMaximizedAndSaveAllData();
                                return false;
                            }
                            return true;
                        });
                }
            }
            else
            {
                checkWindowMaximizedAndSaveAllData();
            }
        }

        public static function loadUndoData():void
        {
            if (undoDataFilePath.exists === false)
            {
                return;
            }

            ReplayController.rMirrorON = false;
            CanvasController.isCanvasMirrored = false;
            CanvasController.canvasInfoBox.setMirror(false);

            const fs:FileStream = new FileStream();
            fs.open(undoDataFilePath, FileMode.READ);

            const lastUndoIndex:int = fs.readInt();
            var arr:Array = fs.readObject() as Array; // undodata first

            const bmpdRect:Rectangle = new Rectangle(0, 0, arr[2], arr[3]);
            var bmpd:BitmapData = new BitmapData(arr[2], arr[3], true, 0);
            var bmpd1:BitmapData = new BitmapData(arr[2], arr[3], true, 0);

            if (arr[6] is Number)
            {
                ReplayController.setRFileTotalFrame(arr[6]);
            }

            ReplayController.rData = (fs.readObject() as Array).concat();
            ReplayController.rDataFrame = (fs.readObject() as Array).concat();
            fs.close();

            UndoManager.undoDataIndex = lastUndoIndex;

            bmpd.lock();
            bmpd.setPixels(bmpdRect, arr[0]);
            bmpd.unlock();

            bmpd1.lock();
            bmpd1.setPixels(bmpdRect, arr[1]);
            bmpd1.unlock();

            UndoController.updateUndoBaseImage(bmpd.clone(), bmpd1.clone(), arr[2], arr[3], arr[4], arr[5]);
            UndoManager.updateCanvasStateAfterUndo();

            ReplayController.rReplayFOFOCursor.visible = false;
            MainUI.hideMouseHint();

            bmpd.dispose();
            bmpd1.dispose();
            bmpd = null;
            bmpd1 = null;

            arr.length = 0;
            arr = null;

            // undo index가 arr의 가장 마지막 부분이 아니면 undo를 하던 중이니까 isDeleteUndoDataPending 켜줌
            if (lastUndoIndex < ReplayController.rData.length - 1)
            {
                UndoManager.isDeleteUndoDataPending = true;
            }
            else
            {
                UndoManager.isDeleteUndoDataPending = false;
            }
        }

        public static function saveUndoData():void
        {
            const fs:FileStream = new FileStream();
            const arr:Array = UndoController.getUndoBaseImage();
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
            var newArr:Array = [ba, ba1, arr[2], arr[3], arr[4], arr[5], ReplayController.getRFileTotalFrame()];

            fs.open(undoDataFilePath, FileMode.WRITE);
            fs.writeInt(UndoManager.undoDataIndex);
            fs.writeObject(newArr);
            fs.writeObject(ReplayController.rData);
            fs.writeObject(ReplayController.rDataFrame);
            fs.close();

            ba.clear();
            ba1.clear();
            ba = null;
            ba1 = null;
        }
    }
}
