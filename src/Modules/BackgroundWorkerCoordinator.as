package Modules
{
    import flash.display.Sprite;
    import flash.display.BitmapData;
    import flash.events.Event;
    import flash.filesystem.File;
    import flash.filesystem.FileStream;
    import flash.filesystem.FileMode;
    import flash.geom.Rectangle;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.system.Worker;
    import flash.system.WorkerDomain;
    import flash.system.MessageChannel;
    import flash.utils.ByteArray;
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.ReplayEngine.ReplayFileCache;
    import Modules.ReplayEngine.ReplayState;

    public final class BackgroundWorkerCoordinator
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static const WORKER_WAIT_INTERVAL:Number = 1.0,
            WORKER_STATE_STOPPED:int = 0,
            WORKER_STATE_INIT:int = (1 << 0),
            WORKER_STATE_RUNNING:int = (1 << 1);

        private static var worker:Worker;
        public static var mainToBack:MessageChannel;
        public static var backToMain:MessageChannel;
        public static var isSaveInProgress:int = 0;
        public static var receivedSaveImageDataFromWorker:ByteArray = null;
        public static var captureImageDataQueue:Array = null;
        public static var receivedCaptureImageQueueFromWorker:Vector.<ByteArray>;
        public static var undoDataQueue:Array; // worker에 보낸 캐시 이미지 작업 [jobId, generation, tempFile, metadata], 비어있으면 null
        // 딥 언두등으로 캐시 이미지를 잘라낼때마다 올려줌, 이전 세대 작업은 worker가 건너뛰고 main도 결과를 버림
        private static var cacheGeneration:int = 0;
        private static const cacheGenerationShared:ByteArray = createCacheGenerationShared(); // worker가 작업 중간에 읽어가는 cacheGeneration
        private static var cacheJobSeq:int = 0;
        private static var workerSWF:ByteArray = null;
        private static var workerDataSendCount:int = 0;
        private static var workerDataReceiveCount:int = 0;
        private static var workerState:int = WORKER_STATE_STOPPED;
        private static var workerWaitCount:int = 0; // 워커 시작하고나서 약간 대기 시켜줘야함,
        private static var workerFunctionsBeforeStart:Array = [];
        private static var waitWorkerReadyEnterFrameEventStarted:Boolean = false; // 워커 대기 프레임 한번만 실행

        public static function getWaitPollingInterval():Number
        {
            return WORKER_WAIT_INTERVAL;
        }

        public static function isWorkerStopped():Boolean
        {
            return workerState === WORKER_STATE_STOPPED;
        }

        public static function isWorkerBusy():Boolean
        {
            return worker !== null || workerFunctionsBeforeStart.length > 0;
        }

        public static function isWorkerRunning():Boolean
        {
            return workerState === WORKER_STATE_RUNNING;
        }

        private static function onFromWorker(e:Event):void
        {
            var msg:* = backToMain.receive();
            const command:String = msg as String;

            if (command === "encodePNGCaptureDone")
            {
                workerDataReceiveCount++;
                receivedCaptureImageQueueFromWorker.push(backToMain.receive(true));
            }
            else if (command === "encodePNGSaveDone")
            {
                workerDataReceiveCount++;
                receivedSaveImageDataFromWorker = backToMain.receive(true);
            }
            else if (command === "compress_ReplayDataDone")
            {
                workerDataReceiveCount++;
                ReplayFileCache.writeReplayFile(backToMain.receive(true)
                        , backToMain.receive(true)
                        , backToMain.receive(true)
                        , backToMain.receive(true)
                        , backToMain.receive(true)
                        , backToMain.receive(true)
                    );
            }
            else if (command === "compress_UndoDataDone")
            {
                workerDataReceiveCount++;
                finishCacheImageJob(backToMain.receive(true), backToMain.receive(true));
            }

            if (!FOFOTimer.hasTimer("workerStopTimer"))
            {
                FOFOTimer.addByName("workerStopTimer", WORKER_WAIT_INTERVAL, true, stopWorkerIfIdle);
            }
        }

        public static function sendDataToWorker(func:Function):void
        {
            if (workerState === WORKER_STATE_RUNNING)
            {
                func();
            }
            else
            {
                workerFunctionsBeforeStart.push(func);
                function waitWorkerReady(e:Event):void
                {
                    if (worker === null)
                    {
                        main.stage.removeEventListener(Event.ENTER_FRAME, waitWorkerReady);
                        waitWorkerReadyEnterFrameEventStarted = false;
                        workerWaitCount = 0;
                        workerState = WORKER_STATE_STOPPED;
                        return;
                    }

                    if (worker.state === "running")
                    {
                        workerWaitCount++;
                        if (workerWaitCount > 10)
                        {
                            workerWaitCount = 0;
                            workerState = WORKER_STATE_RUNNING;
                            main.stage.removeEventListener(Event.ENTER_FRAME, waitWorkerReady);
                            waitWorkerReadyEnterFrameEventStarted = false;
                            while (workerFunctionsBeforeStart.length)
                            {
                                workerFunctionsBeforeStart[0]();
                                workerFunctionsBeforeStart[0] = null;
                                workerFunctionsBeforeStart.shift();
                            }
                        }
                    }
                    else
                    {
                        workerWaitCount = 0;
                    }
                }
                if (waitWorkerReadyEnterFrameEventStarted === false)
                {
                    waitWorkerReadyEnterFrameEventStarted = true;
                    main.stage.addEventListener(Event.ENTER_FRAME, waitWorkerReady);
                }

                if (workerState === WORKER_STATE_STOPPED)
                {
                    startWorker();
                }
            }
        }

        private static function stopWorkerIfIdle(forceFlag:Boolean = false):Boolean
        {
            if ((workerDataSendCount === workerDataReceiveCount
                        && captureImageDataQueue === null
                        && receivedSaveImageDataFromWorker === null
                        && undoDataQueue === null)
                    || (forceFlag === true))
            {
                workerState = WORKER_STATE_STOPPED;
                workerDataSendCount = 0;
                workerDataReceiveCount = 0;

                if (worker)
                {
                    worker.terminate();
                    worker = null;
                }

                if (FileManager.isLoadPendingAfterSaving)
                {
                    FileManager.loadFileTo("canvas");
                }
                else if (AppUpdater.isUpdatePendingAfterSaving)
                {
                    AppUpdater.startUpdate();
                }

                // worker가 완전히 멈춘 뒤에만 파일 불러오기, 새 파일, 리플레이 데이터 삭제 잠금을 풀어줌
                FileManager.refreshFileOperationButtonsTopbar();
                return false;
            }
            return true;
        }

        private static function startWorker():void
        {
            if (worker === null || worker.state === "new")
            {
                workerState = WORKER_STATE_INIT;
                worker = WorkerDomain.current.createWorker(workerSWF, true);
                mainToBack = Worker.current.createMessageChannel(worker);
                backToMain = worker.createMessageChannel(Worker.current);
                backToMain.addEventListener(Event.CHANNEL_MESSAGE, onFromWorker);
                worker.setSharedProperty("backToMain", backToMain);
                worker.setSharedProperty("mainToBack", mainToBack);
                worker.setSharedProperty("cacheGeneration", cacheGenerationShared);
                worker.start();
                // worker가 시작되는 즉시 파일 불러오기, 새 파일, 리플레이 데이터 삭제를 잠금
                FileManager.refreshFileOperationButtonsTopbar();
            }
        }

        public static function initializeWorker():void
        {
            var workerLoader:URLLoader = new URLLoader();
            workerLoader.dataFormat = URLLoaderDataFormat.BINARY;
            workerLoader.addEventListener(Event.COMPLETE, onCompleteWorker);
            workerLoader.load(new URLRequest("worker.swf"));

            function onCompleteWorker(e:Event):void
            {
                workerSWF = e.target.data as ByteArray;
                workerLoader = null;
            }
        }

        public static function applyTransparentCanvasBackground(replayMode:Boolean):void
        {
            var xPanel:Sprite;
            var w:Number = CanvasController.CANVAS_WIDTH;
            var h:Number = CanvasController.CANVAS_HEIGHT;

            if (replayMode)
            {
                xPanel = ReplayDrawer.rCanvasPanel;
                w = ReplayState.RCANVAS_WIDTH;
                h = ReplayState.RCANVAS_HEIGHT;
            }
            else
            {
                xPanel = CanvasController.canvasPanel;
                w = CanvasController.CANVAS_WIDTH;
                h = CanvasController.CANVAS_HEIGHT;
            }

            xPanel.graphics.clear();
            xPanel.graphics.lineStyle(0, 0, 0);
            xPanel.graphics.beginBitmapFill(CaptureController.capTransparentBGBMPD);
            xPanel.graphics.drawRect(0, 0, w, h);
            xPanel.graphics.endFill();
        }

        public static function startPngEncodingWorker(bmpd:BitmapData, bg:uint, isCaptureImage:Boolean, isTransBG:Boolean):void
        {
            sendDataToWorker(function ():void
                {
                    workerDataSendCount++;
                    var ba:ByteArray = new ByteArray();
                    bmpd.copyPixelsToByteArray(new Rectangle(0, 0, bmpd.width, bmpd.height), ba);

                    mainToBack.send("encodePNG");
                    mainToBack.send(ba);
                    mainToBack.send(bmpd.width);
                    mainToBack.send(bmpd.height);
                    mainToBack.send(bg);
                    mainToBack.send(isTransBG);
                    mainToBack.send(isCaptureImage);

                    ba.clear();

                    ba = null;
                    bmpd.dispose();
                    bmpd = null;
                });
        }

        private static function createCacheGenerationShared():ByteArray
        {
            const ba:ByteArray = new ByteArray();
            ba.shareable = true;
            ba.length = 4;
            return ba;
        }

        // 아직 worker에서 만들고 있는 캐시 이미지 작업을 전부 무효로 만듬
        // worker는 단계마다 이 값을 확인해서 남은 압축을 건너뛰고, main은 결과를 받을때 한번 더 확인함
        public static function cancelPendingCacheImages():void
        {
            const oldGeneration:int = cacheGeneration++;
            cacheGenerationShared.atomicCompareAndSwapIntAt(0, oldGeneration, cacheGeneration);
        }

        // 마지막으로 만들었거나 만들고 있는 캐시 이미지의 프레임, 취소된 이전 세대 작업은 빼고 봄
        public static function getLastCacheImageFrame():Number
        {
            if (undoDataQueue !== null)
            {
                for (var i:int = undoDataQueue.length - 1;i >= 0;i--)
                {
                    if (undoDataQueue[i][1] === cacheGeneration)
                    {
                        return undoDataQueue[i][3].nowFrame;
                    }
                }
            }

            const jump:Array = ReplayFileCache.rJumpImageFrameData;
            return (jump.length > 0) ? jump[jump.length - 1] : 0;
        }

        // 캐시 이미지 압축과 파일 쓰기를 worker에 맡김
        // worker는 임시 파일에 쓰고, 캐시 번호는 main이 finishCacheImageJob에서 확정해줌
        public static function startCacheImageWorker(layer1:BitmapData, layer2:BitmapData, metadata:CacheImageMetaData):void
        {
            const rect:Rectangle = new Rectangle(0, 0, metadata.bmpdWidth, metadata.bmpdHeight);
            // shareable로 넘기면 채널에서 복사가 안일어나서 메모리 최고치가 줄어듬
            var data:ByteArray = new ByteArray();
            var data1:ByteArray = new ByteArray();
            data.shareable = true;
            data1.shareable = true;
            layer1.copyPixelsToByteArray(rect, data);
            layer2.copyPixelsToByteArray(rect, data1);

            if (undoDataQueue === null)
            {
                undoDataQueue = [];
                // 진행중인 작업이 없을때만 지난 실행에서 남은 임시 파일을 정리
                resetCacheTempFolder();
            }

            const jobId:int = ++cacheJobSeq;
            const generation:int = cacheGeneration;
            const tempFile:File = FileManager.replayCacheImageTempFolderPath.resolvePath(jobId + ".tmp");
            undoDataQueue.push([jobId, generation, tempFile, metadata]);

            sendDataToWorker(function ():void
                {
                    workerDataSendCount++;
                    mainToBack.send("compress_UndoData");
                    mainToBack.send(jobId);
                    mainToBack.send(generation);
                    mainToBack.send(tempFile.nativePath); // worker의 applicationStorageDirectory는 경로가 달라서 전체 경로로 넘김
                    mainToBack.send(metadata);
                    mainToBack.send(data);
                    mainToBack.send(data1);
                    // worker가 다 쓰기 전에 clear하지 않도록 참조만 놓음, 해제는 worker가 복사 직후에 해줌
                    data = null;
                    data1 = null;
                });
        }

        // result: "done", "cancelled:<단계>", "error:<메세지>"
        private static function finishCacheImageJob(jobId:int, result:String):void
        {
            var job:Array = null;

            for (var i:int = 0;i < undoDataQueue.length;i++)
            {
                if (undoDataQueue[i][0] === jobId)
                {
                    job = undoDataQueue.splice(i, 1)[0];
                    break;
                }
            }

            trace("cache image job " + jobId + ": " + result);

            if (job !== null)
            {
                const tempFile:File = job[2];

                // worker가 확인한 뒤에 세대가 바뀌었을수도 있어서 여기서 다시 확인
                if (result !== "done" || job[1] !== cacheGeneration || !ReplayFileCache.commitCacheImage(tempFile, job[3]))
                {
                    deleteFileQuietly(tempFile);
                }
            }

            if (undoDataQueue.length === 0)
            {
                undoDataQueue = null;
            }
        }

        private static function resetCacheTempFolder():void
        {
            const folder:File = FileManager.replayCacheImageTempFolderPath;

            try
            {
                if (folder.exists)
                {
                    folder.deleteDirectory(true);
                }
            }
            catch (error:Error)
            {
                trace("Cache temp folder cleanup failed: " + error);
            }

            folder.createDirectory();
        }

        private static function deleteFileQuietly(file:File):void
        {
            try
            {
                if (file.exists)
                {
                    file.deleteFile();
                }
            }
            catch (error:Error)
            {
                trace("Cache temp file delete failed: " + error);
            }
        }

        public static function startReplayDataCompressionWorker(dataA:ByteArray, dataA1:ByteArray, dataB:ByteArray, dataB1:ByteArray, dataC:ByteArray, dataD:ByteArray):void
        {
            sendDataToWorker(function ():void
                {
                    workerDataSendCount++;
                    mainToBack.send("compress_ReplayData");
                    mainToBack.send(dataA);
                    mainToBack.send(dataA1);
                    mainToBack.send(dataB);
                    mainToBack.send(dataB1);
                    mainToBack.send(dataC);
                    mainToBack.send(dataD);
                    dataA.clear();
                    dataA1.clear();
                    dataB.clear();
                    dataB1.clear();
                    dataC.clear();
                    dataD.clear();
                    dataA = null;
                    dataA1 = null;
                    dataB = null;
                    dataB1 = null;
                    dataC = null;
                    dataD = null;
                });
        }

        public static function pollTimerWaitWorkerForSaveCaptureImage():void
        {
            if (!FOFOTimer.hasTimer("workerPNGCaptureTimer"))
            {
                FOFOTimer.addByName("workerPNGCaptureTimer", WORKER_WAIT_INTERVAL, true, function ():Boolean
                    {
                        if (receivedCaptureImageQueueFromWorker.length > 0)
                        {
                            while (receivedCaptureImageQueueFromWorker.length > 0)
                            {
                                const fileName:String = captureImageDataQueue[0][0];
                                const filePath:String = captureImageDataQueue[0][1];

                                // 마지막 경로 업데이트
                                // saveFilePath = filePath.substr(0,filePath.lastIndexOf(fileName))+saveFileName;

                                const fs:FileStream = new FileStream();
                                var file:File = new File(filePath);
                                if (fileName.lastIndexOf(".png") === -1) // png를 안붙여 줬을때
                                {
                                    const fixedPath:String = filePath.replace(fileName, ""); // 이름짜르고 경로만 저장
                                    const dotPNG:String = fileName + ".png";
                                    file = new File(fixedPath + dotPNG);
                                }

                                fs.open(file, FileMode.WRITE);
                                fs.writeBytes(receivedCaptureImageQueueFromWorker[0]);
                                fs.close();
                                receivedCaptureImageQueueFromWorker[0].clear();
                                receivedCaptureImageQueueFromWorker[0] = null;
                                receivedCaptureImageQueueFromWorker.shift();

                                captureImageDataQueue[0] = null;
                                captureImageDataQueue.shift();
                            }
                        }
                        else if (receivedCaptureImageQueueFromWorker.length === 0 && captureImageDataQueue.length === 0)
                        {
                            captureImageDataQueue = null;
                            receivedCaptureImageQueueFromWorker = null;
                            return false;
                        }
                        return true;
                    });
            }
        }
    }
}
