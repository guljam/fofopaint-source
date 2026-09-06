package main_module
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

    public final class BackgroundWorkerCoordinator
    {
        public static const WORKER_WAIT_INTERVAL:Number = 0.5,
            WORKER_STATE_STOPPED:int = 0,
            WORKER_STATE_INIT:int = (1 << 0),
            WORKER_STATE_RUNNING:int = (1 << 1);

        public static var worker:Worker,
            mainToBack:MessageChannel,
            backToMain:MessageChannel,
            isSaveInProgress:int = 0,
            isSaveInProgressOFFDelayTimer:int = 0,
            receivedSaveImageDataFromWorker:ByteArray = null,
            captureImageDataQueue:Array = null,
            receivedCaptureImageQueueFromWorker:Vector.<ByteArray>,
            receivedUndoImageQueueFromWorker:Array = null,
            undoDataQueue:Array = null,
            workerSWF:ByteArray = null,
            workerDataSendCount:int = 0,
            workerDataReceiveCount:int = 0,
            workerState:int = WORKER_STATE_STOPPED,
            workerWaitCount:int = 0, // 워커 시작하고나서 약간 대기 시켜줘야함,
            workerFunctionsBeforeStart:Array = [];

        public static function onFromWorker(e:Event):void
        {
            const main:Main = Main._instance;

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
                main.writeReplayFile(backToMain.receive(true)
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
                receivedUndoImageQueueFromWorker.push([backToMain.receive(true), backToMain.receive(true)]);
            }

            if (!FOFOTimer.hasTimer("workerStopTimer"))
            {
                FOFOTimer.addByName("workerStopTimer", WORKER_WAIT_INTERVAL, true, stopWorkerIfIdle);
            }
        }

        public static function sendDataToWorker(func:Function):void
        {
            const main:Main = Main._instance;

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
                main.stage.addEventListener(Event.ENTER_FRAME, waitWorkerReady);

                if (workerState === WORKER_STATE_STOPPED)
                {
                    startWorker();
                }
            }
        }

        public static function stopWorkerIfIdle(forceFlag:Boolean = false):Boolean
        {
            const main:Main = Main._instance;

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

                if (main.isLoadPendingAfterSaving)
                {
                    main.loadFileTo("canvas");
                }
                else if (AppUpdater.isUpdatePendingAfterSaving)
                {
                    AppUpdater.startUpdate();
                }

                main.enableFileOperationButtonsTopbar();
                return false;
            }
            return true;
        }

        public static function startWorker():void
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
                worker.start();
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
            const main:Main = Main._instance;

            var xPanel:Sprite;
            var w:Number = main.CANVAS_WIDTH;
            var h:Number = main.CANVAS_HEIGHT;

            if (replayMode)
            {
                xPanel = main.rCanvasPanel;
                w = main.RCANVAS_WIDTH;
                h = main.RCANVAS_HEIGHT;
            }
            else
            {
                xPanel = main.canvasPanel;
                w = main.CANVAS_WIDTH;
                h = main.CANVAS_HEIGHT;
            }

            xPanel.graphics.clear();
            xPanel.graphics.lineStyle(0, 0, 0);
            xPanel.graphics.beginBitmapFill(main.capTransparentBGBMPD);
            xPanel.graphics.drawRect(0, 0, w, h);
            xPanel.graphics.endFill();
        }

        public static function startPngEncodingWorker(bmpd:BitmapData, bg:uint, isCaptureImage:Boolean, isTransBG:Boolean):void
        {
            sendDataToWorker(function():void
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

        public static function startUndoImageCompressionWorker(data:ByteArray, data1:ByteArray):void
        {
            sendDataToWorker(function():void
            {
                workerDataSendCount++;
                mainToBack.send("compress_UndoData");
                mainToBack.send(data);
                mainToBack.send(data1);

                data.clear();
                data1.clear();
                data = null;
                data1 = null;
            });
        }

        public static function startReplayDataCompressionWorker(dataA:ByteArray, dataA1:ByteArray, dataB:ByteArray, dataB1:ByteArray, dataC:ByteArray, dataD:ByteArray):void
        {
            sendDataToWorker(function():void
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
                FOFOTimer.addByName("workerPNGCaptureTimer", WORKER_WAIT_INTERVAL, true, function():Boolean
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

        public static function pollTimerWaitWorkerForCacheUndoData():void
        {
            const main:Main = Main._instance;

            if (!FOFOTimer.hasTimer("workerUndoDataTimer"))
            {
                FOFOTimer.addByName("workerUndoDataTimer", WORKER_WAIT_INTERVAL, true, function():Boolean
                {
                    if (receivedUndoImageQueueFromWorker.length > 0)
                    {
                        main.createCacheImage(receivedUndoImageQueueFromWorker[0][0],
                        receivedUndoImageQueueFromWorker[0][1],
                        undoDataQueue[0][0],
                        undoDataQueue[0][1],
                        undoDataQueue[0][2],
                        undoDataQueue[0][3],
                        undoDataQueue[0][4],
                        undoDataQueue[0][5]);

                        receivedUndoImageQueueFromWorker[0][0].clear();
                        receivedUndoImageQueueFromWorker[0][1].clear();
                        receivedUndoImageQueueFromWorker[0][0] = null;
                        receivedUndoImageQueueFromWorker[0][1] = null;
                        receivedUndoImageQueueFromWorker[0] = null;
                        undoDataQueue[0] = null;
                        receivedUndoImageQueueFromWorker.shift();
                        undoDataQueue.shift();
                    }
                    else if (undoDataQueue.length === 0 && receivedUndoImageQueueFromWorker.length === 0)
                    {
                        receivedUndoImageQueueFromWorker = null;
                        undoDataQueue = null;

                        return false;
                    }
                    return true;
                });
            }
        }

        public static function onWindowClosingEvent(e:Event):void
        {
            const main:Main = Main._instance;

            main.isAppClosing = true;

            e.preventDefault();
            main.stage.nativeWindow.removeEventListener(Event.DEACTIVATE, main.onWindowDeactivate);
            main.removeInputEventCaptrueMode();
            main.removeInputEventsDrawMode();
            main.removeInputEventsReplayMode();
            main.realWorkingTimer.stop();

            if (ImageViewWindow.canvasWindow !== null)
            {
                ImageViewWindow.canvasWindow.visible = false;
            }

            if (main.isCaptureModeON === true)
            {
                main.handleExitCaptureMode();
            }

            if (main.isReplayStarted === true)
            {
                main.stopReplay();
            }

            if (main.isLassoToolStarted)
            {
                main.cancelLassoTool();
            }

            if (workerState === WORKER_STATE_RUNNING)
            {
                if (!FOFOTimer.hasTimer("pollTimerWaitWorkerStop"))
                {
                    main.stage.nativeWindow.title = "Waiting for remaining tasks...";
                    main.openLoadMenuBoxOnClosing();
                    FOFOTimer.addByName("pollTimerWaitWorkerStop", WORKER_WAIT_INTERVAL, true, function():Boolean
                    {
                        if (workerState === WORKER_STATE_STOPPED)
                        {
                            FOFOTimer.remove("pollTimerWaitWorkerStop");
                            main.checkWindowMaximizedAndSaveAllData();
                            return false;
                        }
                        return true;
                    });
                }
            }
            else
            {
                main.checkWindowMaximizedAndSaveAllData();
            }
        }
    }
}
