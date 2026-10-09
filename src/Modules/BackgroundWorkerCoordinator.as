package Modules
{
    import Modules.DrawEngine.CanvasView;
    import Modules.DrawEngine.DrawCanvas;
    import Modules.CaptureEngine.CaptureController;
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
        // 캐시 이미지를 못 만든 프레임, 쓰기 실패가 계속될때 스트로크마다 레이어 복사, 압축을 반복하지 않게 이 프레임부터 다시 간격을 셈
        private static var cacheFailedFrame:Number = 0;
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

                if (LoadBoxController.isLoadPendingAfterSaving)
                {
                    LoadBoxController.loadFileTo("canvas");
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
            var w:Number = DrawCanvas.CANVAS_WIDTH;
            var h:Number = DrawCanvas.CANVAS_HEIGHT;

            if (replayMode)
            {
                xPanel = ReplayDrawer.rCanvasPanel;
                w = ReplayState.RCANVAS_WIDTH;
                h = ReplayState.RCANVAS_HEIGHT;
            }
            else
            {
                xPanel = CanvasView.canvasPanel;
                w = DrawCanvas.CANVAS_WIDTH;
                h = DrawCanvas.CANVAS_HEIGHT;
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
            NativeCacheJobs.setGeneration(cacheGeneration);
            // 캐시를 잘라내거나 새로 만들면 프레임 기준이 바뀌므로 실패 기록도 버림
            cacheFailedFrame = 0;
        }

        public static function getCacheGeneration():int
        {
            return cacheGeneration;
        }

        // 마지막으로 만들었거나 만들고 있거나 만들지 못한 캐시 이미지의 프레임, 취소된 이전 세대 작업은 빼고 봄
        public static function getLastCacheImageFrame():Number
        {
            var frame:Number = -1;

            if (undoDataQueue !== null)
            {
                for (var i:int = undoDataQueue.length - 1;i >= 0;i--)
                {
                    if (undoDataQueue[i][1] === cacheGeneration)
                    {
                        frame = undoDataQueue[i][3].nowFrame;
                        break;
                    }
                }
            }

            if (frame < 0)
            {
                const jump:Array = ReplayFileCache.rJumpImageFrameData;
                frame = (jump.length > 0) ? jump[jump.length - 1] : 0;
            }

            return Math.max(frame, cacheFailedFrame);
        }

        // 캐시 이미지 압축과 파일 쓰기를 worker에 맡김
        // worker는 임시 파일에 쓰고, 캐시 번호는 main이 finishCacheImageJob에서 확정해줌
        // 캐시는 리플레이 데이터로 다시 만들수 있어서 준비에 실패하면 이번 캐시만 건너뜀, 예외를 밖으로 보내면 호출한 addNew의 undo 이관이 중간에 끊김
        public static function startCacheImageWorker(layer1:BitmapData, layer2:BitmapData, metadata:CacheImageMetaData):void
        {
            // 진행중인 작업이 없을때만 지난 실행에서 남은 임시 파일을 정리, 준비가 끝난 뒤에 대기열을 만듬
            if (undoDataQueue === null)
            {
                if (!prepareCacheTempFolder())
                {
                    cacheFailedFrame = metadata.nowFrame;
                    return;
                }

                undoDataQueue = [];
            }

            const jobId:int = ++cacheJobSeq;
            const generation:int = cacheGeneration;
            const tempFile:File = AppStateManager.replayCacheImageTempFolderPath.resolvePath(jobId + ".tmp");
            undoDataQueue.push([jobId, generation, tempFile, metadata]);

            // 네이티브: 두 레이어 내부 버퍼를 복사하고 압축·쓰기는 네이티브 스레드에서 (내부 버퍼 원본 덤프라 손실 없음)
            if (NativeCacheJobs.start(tempFile.nativePath, layer1, layer2, metadata, generation, true, function (result:Object):void
                    {
                        finishCacheImageJob(jobId, (result.status === "done") ? "done" : (result.status === "cancelled") ? "cancelled:native" : "error:native " + result.error);
                    }) === NativeCore.OK)
            {
                return;
            }

            const rect:Rectangle = new Rectangle(0, 0, metadata.bmpdWidth, metadata.bmpdHeight);
            // shareable로 넘기면 채널에서 복사가 안일어나서 메모리 최고치가 줄어듬
            var data:ByteArray = new ByteArray();
            var data1:ByteArray = new ByteArray();
            data.shareable = true;
            data1.shareable = true;
            layer1.copyPixelsToByteArray(rect, data);
            layer2.copyPixelsToByteArray(rect, data1);

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
                if (job[1] !== cacheGeneration || result.indexOf("cancelled") === 0)
                {
                    deleteFileQuietly(tempFile);
                }
                else if (result !== "done" || !ReplayFileCache.commitCacheImage(tempFile, job[3]))
                {
                    // 세대 변경으로 인한 취소가 아닌 쓰기, 이동 실패만 기록해서 다음 캐시 간격 동안 재시도를 쉼
                    cacheFailedFrame = Math.max(cacheFailedFrame, job[3].nowFrame);
                    AppStateManager.writeCrashLog("Cache image job " + jobId + " failed: " + result);
                    deleteFileQuietly(tempFile);
                }
            }

            if (undoDataQueue.length === 0)
            {
                undoDataQueue = null;
                // 잠금이 풀렸으니 대기 중인 불러오기를 이어감 (worker 작업이면 worker가 멈출때 stopWorkerIfIdle이 함)
                FileManager.refreshFileOperationButtonsTopbar();

                if (LoadBoxController.isLoadPendingAfterSaving && !FileManager.isReplayDataLocked())
                {
                    LoadBoxController.loadFileTo("canvas");
                }
            }
        }

        // 폴더를 지우고 바로 다시 만들면 다른 프로그램이 안의 파일을 잡고 있을때 삭제 대기 상태가 되어 생성이 실패할수 있음
        // 그래서 폴더는 두고 안의 파일만 지움, 확정은 작업별 임시 파일 하나만 옮기고 worker는 덮어쓰기로 쓰니 못 지운 파일이 남아도 결과는 같음
        private static function prepareCacheTempFolder():Boolean
        {
            const folder:File = AppStateManager.replayCacheImageTempFolderPath;

            try
            {
                if (!folder.exists)
                {
                    folder.createDirectory();
                    return true;
                }

                const list:Array = folder.getDirectoryListing();

                for (var i:int = 0;i < list.length;i++)
                {
                    deleteFileQuietly(list[i]);
                }

                return true;
            }
            catch (error:Error)
            {
                AppStateManager.writeCrashLog(error);
            }

            return false;
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
