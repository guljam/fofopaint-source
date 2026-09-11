package Modules
{
    import flash.display.BitmapData;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;

    public class UndoManager
    {
        // 메인 인스턴스 참조
        public static var main:Main;

        // Undo / Redo 상태 관리
        public static var undoDataIndex:int = -1; // undo redo 상태 인덱스임
        public static var isDeleteUndoDataPending:Boolean = false; // undo하고 나서 addundo가 되었을때 뒷부분 데이터 전부 날려주는 플래그
        public static var canAddUndoData:Boolean = false; // 선을 그어줄대 선전체가 캔버스 바깥쪽에 있을수도 있으니까 이걸 판단해줌

        // 딥언도 (Deep Undo)
        public static var isDeepUndoEnabled:Boolean = false;
        public static var lastDeepUndoEnabledFlag:Boolean = false; // 리플레이 켜줄때 딥 플래그를 꺼줘서 여기다가 미리 저장해둠
        public static var lastReplayFrameOnDeepUndoStart:Number = -1; // 리플레이 켜줄때 rNowFrame이 변하니까 그전에 백업해주고 꺼주고 다시 undo실행할때 이 프레임 기준으로 하려고

        // Undo 매니저 클로저 객체
        public static var addUndoData:Object;

        public static function setMainInstance(instance:Main):void
        {
            main = instance;
            addUndoData = cAddUndoData();
        }

        // todo : undo 뿐만 아니고 나중에 인스턴스 객체로 바꾸어서 main에다가 서로 부품연결하듯이 깔아주는구조
        public static function cAddUndoData():Object
        {
            var dataWriteCount:uint = 0; // 데이터로 저장할때  rDataFrame 카운터 누적
            var rFileTotalFrame:Number = 0; // file에저장된 프레임수 누적해서 저장

            // undo 할때 이 데이터를 기준점으로 rData그려줌 메모리 적게 하려고
            trace('main', main);
            var undoBaseImage:Array = [
                    main.rFirstImageLayer1BitmapData.clone(),
                    main.rFirstImageLayer2BitmapData.clone(),
                    CanvasController.CANVAS_WIDTH,
                    CanvasController.CANVAS_HEIGHT,
                    CanvasController.CANVAS_BG_COLOR,
                    CanvasController.isCanvasMirrored
                ];

            function resetRJumpImageCount():void
            {
                dataWriteCount = 0;
            }

            function updateUndoBaseImageMirrorFlag(flag:Boolean):void
            {
                undoBaseImage[5] = flag;
            }

            function updateUndoBaseImageFromReplayMode():void
            {
                addUndoData.updateUndoBaseImage(
                        main.rCanvasLayer1BitmapData.clone(),
                        main.rCanvasLayer2BitmapData.clone(),
                        main.rCanvasLayer1BitmapData.width,
                        main.rCanvasLayer1BitmapData.height,
                        main.RCANVAS_BG_COLOR,
                        main.rMirrorON
                    );
            }

            function updateUndoBaseImageFromDrawMode():void
            {
                addUndoData.updateUndoBaseImage(
                        CanvasController.canvasLayer1BitmapData.clone(),
                        CanvasController.canvasLayer2BitmapData.clone(),
                        CanvasController.canvasLayer1BitmapData.width,
                        CanvasController.canvasLayer1BitmapData.height,
                        CanvasController.CANVAS_BG_COLOR,
                        CanvasController.isCanvasMirrored
                    );
            }

            function updateReplayCanvasFromUndoBaseInfo():void
            {
                var rMirrorSave:Boolean = main.rMirrorON;

                if (undoBaseImage[2] !== main.RCANVAS_WIDTH || undoBaseImage[3] !== main.RCANVAS_HEIGHT)
                {
                    main.updateCanvasSizeReplayMode(undoBaseImage[2], undoBaseImage[3], 0, 0, false);
                }

                if (undoBaseImage[4] !== main.RCANVAS_BG_COLOR)
                {
                    main.updateCanvasBGColorReplayMode(undoBaseImage[4]);
                }

                main.rCanvasLayer1BitmapData = CanvasController.updateBitmapData(main.rCanvasLayer1BitmapData, undoBaseImage[0], main.rCanvasLayer1Bitmap);
                main.rCanvasLayer2BitmapData = CanvasController.updateBitmapData(main.rCanvasLayer2BitmapData, undoBaseImage[1], main.rCanvasLayer2Bitmap);

                main.drawReplayByCommand.setData(main.rData[0]);
                main.drawReplayByCommand.drawAll();

                if (undoBaseImage[0] && undoBaseImage[0] !== main.rCanvasLayer1BitmapData)
                {
                    undoBaseImage[0].dispose();
                }

                if (undoBaseImage[1] && undoBaseImage[1] !== main.rCanvasLayer2BitmapData)
                {
                    undoBaseImage[1].dispose();
                }

                undoBaseImage[0] = main.rCanvasLayer1BitmapData.clone();
                undoBaseImage[1] = main.rCanvasLayer2BitmapData.clone();
                undoBaseImage[2] = main.RCANVAS_WIDTH;
                undoBaseImage[3] = main.RCANVAS_HEIGHT;
                undoBaseImage[4] = main.RCANVAS_BG_COLOR;

                if (main.rMirrorON !== rMirrorSave)
                {
                    undoBaseImage[5] = !undoBaseImage[5];
                }

                main.drawReplayByCommand.setFirstRCursorPosCurrent();
            }

            function getUndoBaseImage():Array
            {
                return undoBaseImage;
            }

            function updateUndoBaseImage(bmpd1:BitmapData, bmpd2:BitmapData, width:Number, height:Number, bgColor:uint, mirrorFlag:Boolean):void
            {
                if (undoBaseImage[0] && bmpd1 !== undoBaseImage[0])
                {
                    undoBaseImage[0].dispose();
                }

                if (undoBaseImage[1] && bmpd2 !== undoBaseImage[1])
                {
                    undoBaseImage[1].dispose();
                }

                undoBaseImage[0] = bmpd1;
                undoBaseImage[1] = bmpd2;
                undoBaseImage[2] = width;
                undoBaseImage[3] = height;
                undoBaseImage[4] = bgColor;
                undoBaseImage[5] = mirrorFlag;
            }

            // undo index까지의 프레임 합을 구함
            function getRDataTotalFrame(index:int):Number
            {
                if (index < 0)
                {
                    return 0;
                }

                var sum:Number = 0;

                for (var i:int = 0;i <= index;i++)
                {
                    sum += main.rDataFrame[i];
                }

                return sum;
            }

            function getRFileTotalFrame():Number
            {
                return rFileTotalFrame;
            }

            function setRFileTotalFrame(frame:Number):void
            {
                rFileTotalFrame = frame;
            }

            // 미러가 되어있는지 확인해서 mirror커맨드를 무조건 앞으로 보냄
            // 그게 아니면 미러 커맨드 지워줌
            function updateLastRDataMirror():void
            {
                var popArr:Array;

                if (main.mirrorCommandReady)
                {
                    // 마지막 데이터에 1개만의 미러 커맨드가 있으먼 미러를 무효로함 mirror mirror니까 원래대로임
                    if (main.rData.length > 0 && main.rData[main.rData.length - 1].length === 1 && main.rData[main.rData.length - 1][0][0] === "mirror")
                    {
                        main.mirrorCommandReady = false;
                        main.rData.pop();
                        main.rDataFrame.pop();
                    }
                    // 그게 아니면 가장 앞에 미러커맨드를 넣어줌
                    else if (main.rDataBuffer.length > 0 && main.rDataBuffer[0][0] !== "mirror")
                    {
                        main.mirrorCommandReady = false;
                        main.rDataBuffer.unshift(["mirror"]);
                    }
                }
                else
                {
                    // 미러 커맨드가 꺼져있는데 독립인 미러커맨드가 있으면 지워주고 미러 커맨드 플래그를 올려줘서 다음번에
                    // 미러 커맨드가 가장 앞에 오도록함
                    if (main.rData.length > 0 && main.rData[main.rData.length - 1].length === 1 && main.rData[main.rData.length - 1][0][0] === "mirror")
                    {
                        main.rData.pop();
                        main.rDataFrame.pop();
                        main.mirrorCommandReady = true;
                    }
                    // 그게 아니면 그냥 지워줌
                    else if (main.rDataBuffer.length > 0 && main.rDataBuffer[0][0] === "mirror")
                    {
                        main.rDataBuffer.shift();
                    }
                }
            }

            // 끝 부분 중복처리 일때 넣어주는 거
            function addContinue():void
            {
                if (main.rData.length === 0)
                    return;

                if (isDeleteUndoDataPending)
                {
                    isDeleteUndoDataPending = false;
                    main.rData.splice(undoDataIndex + 1);
                    main.rDataFrame.splice(undoDataIndex + 1);
                }

                updateLastRDataMirror();

                // 버퍼에mirror가 있을수도 있기 때문에 요소를 하나씩 push해주어야함
                const len:uint = main.rDataBuffer.length;

                for (var i:uint = 0;i < len;i++)
                {
                    main.rData[main.rData.length - 1].push(main.rDataBuffer[i]); // 배열안에 배열이 들어있음
                }

                main.rDataFrame[main.rDataFrame.length - 1] = main.rData[main.rData.length - 1].length;
                main.rDataBuffer = [];

                main.rPrevFrame = main.rNowFrame;
                main.rNowFrame = main.getTotalFrame();

                CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);

                if (ImageViewWindow.isCanvasWindowON)
                {
                    ImageViewWindow.updateCanvasWindowImage();
                    ImageViewWindow.updateCanvasWindowBitmapSize();
                }
            }

            function addNew():void
            {
                if (isDeleteUndoDataPending === true)
                {
                    isDeleteUndoDataPending = false;
                    main.rData.splice(undoDataIndex + 1);
                    main.rDataFrame.splice(undoDataIndex + 1);
                }

                if (main.rData.length >= 10) // 첫번째 이미지는 빼야하니깐 -1로 계산해야함
                {
                    var oldData:Array = main.rData[0];

                    if (oldData.length > 0)
                    {
                        const fs:FileStream = new FileStream();
                        const c:uint = main.rDataFrame[0];
                        const rf:File = FileManager.replayDataFilePath;

                        fs.open(rf, FileMode.APPEND);
                        fs.writeObject(oldData);
                        fs.close();

                        oldData = null;
                        rFileTotalFrame += c;
                        dataWriteCount += c;

                        updateReplayCanvasFromUndoBaseInfo();

                        if (main.rReplayImageCacheState === main.REPLAY_IMAGE_CAHCHE_COMPLETE)
                        {
                            if (dataWriteCount > main.REPLAY_DISK_CACHE_FRAME_INTERVAL)
                            {
                                dataWriteCount = 0;

                                const data:Array = undoBaseImage;
                                const bmpd:BitmapData = data[0];
                                const bmpd1:BitmapData = data[1];
                                const w:int = data[2];
                                const h:int = data[3];
                                const bgColor:uint = data[4];

                                var imgData:ByteArray = new ByteArray();
                                var imgData1:ByteArray = new ByteArray();
                                const newRectangle:Rectangle = new Rectangle(0, 0, w, h);

                                bmpd.copyPixelsToByteArray(newRectangle, imgData);
                                bmpd1.copyPixelsToByteArray(newRectangle, imgData1);

                                // 위에서 쓰고나서 가능한 바이트랑 실제 바이트는 rf.size랑 다름, rf.size가 정확함
                                if (BackgroundWorkerCoordinator.receivedUndoImageQueueFromWorker === null)
                                    BackgroundWorkerCoordinator.receivedUndoImageQueueFromWorker = [];

                                if (BackgroundWorkerCoordinator.undoDataQueue === null)
                                    BackgroundWorkerCoordinator.undoDataQueue = [];

                                BackgroundWorkerCoordinator.undoDataQueue.push([w, h, bgColor, rf.size, rFileTotalFrame, CanvasController.isCanvasMirrored]);
                                BackgroundWorkerCoordinator.startUndoImageCompressionWorker(imgData, imgData1);
                                BackgroundWorkerCoordinator.pollTimerWaitWorkerForCacheUndoData();
                            }
                        }
                    }

                    main.rData[0].length = 0;
                    main.rData[0] = null;
                    main.rDataFrame[0] = null;
                    main.rData.shift();
                    main.rDataFrame.shift();
                }

                updateLastRDataMirror();

                if (main.rDataBuffer.length > 0)
                {
                    main.rData.push(main.rDataBuffer);
                    main.rDataFrame.push(main.rDataBuffer.length);
                    main.rDataBuffer = [];
                    FileManager.isFileAlreadySaved = false;
                    main.rDataReadFlag = true;
                }

                undoDataIndex = main.rData.length - 1;

                CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);

                if (ImageViewWindow.isCanvasWindowON)
                {
                    ImageViewWindow.updateCanvasWindowImage();
                }

                main.rPrevFrame = main.rNowFrame;
                main.rNowFrame = main.getTotalFrame();

                FileManager.enableNewFileButton();
            };

            return {
                    addNew: addNew,
                    addContinue: addContinue,
                    setRFileTotalFrame: setRFileTotalFrame,
                    getRFileTotalFrame: getRFileTotalFrame,
                    getRDataTotalFrame: getRDataTotalFrame,
                    getUndoBaseImage: getUndoBaseImage,
                    updateUndoBaseImage: updateUndoBaseImage,
                    updateUndoBaseImageFromReplayMode: updateUndoBaseImageFromReplayMode,
                    updateUndoBaseImageFromDrawMode: updateUndoBaseImageFromDrawMode,
                    updateUndoBaseImageMirrorFlag: updateUndoBaseImageMirrorFlag,
                    resetRJumpImageCount: resetRJumpImageCount,
                    updateLastRDataMirror: updateLastRDataMirror
                };
        }

        public static function showRCursorOnUndo(undoIndex:int):void
        {
            if (undoIndex < 0)
            {
                if (main.drawReplayByCommand.hasRCursorFirstPos())
                {
                    const p:Point = main.drawReplayByCommand.getFirstRCursorPos();
                    main.drawReplayByCommand.setRCursorPos(p.x, p.y); // 커서 위치도 업에이트 해줘야함 대칭해줄띠 getRcursor로 하기 때문에
                    main.drawReplayByCommand.updateRCursorPosToFirst();
                }
                else
                {
                    main.rReplayFOFOCursor.visible = false;
                    MainUI.hideMouseHint();
                }
            }
            else
            {
                main.drawReplayByCommand.updateRCursorPos();
            }
        }

        public static function resetUndoState(fromReplayMode:Boolean = false):void
        {
            undoDataIndex = -1;

            if (fromReplayMode)
            {
                addUndoData.updateUndoBaseImageFromReplayMode();
            }
            else
            {
                addUndoData.updateUndoBaseImageFromDrawMode();
            }

            addUndoData.resetRJumpImageCount();

            main.rData = [];
            main.rDataFrame = [];
            main.rDataBuffer = [];

            canAddUndoData = false;
            isDeleteUndoDataPending = false;
            main.rReplayFOFOCursor.visible = false;
            isDeepUndoEnabled = false;
        }

        public static function getNowFrameUntilUndoIndex(index:int):Number
        {
            return addUndoData.getRFileTotalFrame() + addUndoData.getRDataTotalFrame(index);
        }

        public static function loadUndoData():void
        {
            if (FileManager.undoDataFilePath.exists === false)
            {
                return;
            }

            main.rMirrorON = false;
            CanvasController.isCanvasMirrored = false;
            CanvasController.canvasInfoBox.setMirror(false);

            const fs:FileStream = new FileStream();
            fs.open(FileManager.undoDataFilePath, FileMode.READ);

            const lastUndoIndex:int = fs.readInt();
            var arr:Array = fs.readObject() as Array; // undodata first

            const bmpdRect:Rectangle = new Rectangle(0, 0, arr[2], arr[3]);
            var bmpd:BitmapData = new BitmapData(arr[2], arr[3], true, 0);
            var bmpd1:BitmapData = new BitmapData(arr[2], arr[3], true, 0);

            if (arr[6] is Number)
            {
                addUndoData.setRFileTotalFrame(arr[6]);
            }

            main.rData = (fs.readObject() as Array).concat();
            main.rDataFrame = (fs.readObject() as Array).concat();
            fs.close();

            undoDataIndex = lastUndoIndex;

            bmpd.lock();
            bmpd.setPixels(bmpdRect, arr[0]);
            bmpd.unlock();

            bmpd1.lock();
            bmpd1.setPixels(bmpdRect, arr[1]);
            bmpd1.unlock();

            addUndoData.updateUndoBaseImage(bmpd.clone(), bmpd1.clone(), arr[2], arr[3], arr[4], arr[5]);
            main.drawUndoData();

            main.rReplayFOFOCursor.visible = false;
            MainUI.hideMouseHint();

            bmpd.dispose();
            bmpd1.dispose();
            bmpd = null;
            bmpd1 = null;

            arr.length = 0;
            arr = null;

            // undo index가 arr의 가장 마지막 부분이 아니면 undo를 하던 중이니까 isDeleteUndoDataPending 켜줌
            if (lastUndoIndex < main.rData.length - 1)
            {
                isDeleteUndoDataPending = true;
            }
            else
            {
                isDeleteUndoDataPending = false;
            }
        }

        public static function saveUndoData():void
        {
            const fs:FileStream = new FileStream();
            const arr:Array = addUndoData.getUndoBaseImage();
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
            var newArr:Array = [ba, ba1, arr[2], arr[3], arr[4], arr[5], addUndoData.getRFileTotalFrame()];

            fs.open(FileManager.undoDataFilePath, FileMode.WRITE);
            fs.writeInt(undoDataIndex);
            fs.writeObject(newArr);
            fs.writeObject(main.rData);
            fs.writeObject(main.rDataFrame);
            fs.close();

            ba.clear();
            ba1.clear();
            ba = null;
            ba1 = null;
        }

        public static function getCanvasMovedUndo(index:int, redoFlag:Boolean):Point
        {
            const prevData:Array = (redoFlag) ? main.rData[index] : main.rData[index + 1];

            if (!prevData)
                return null;

            var len:uint = prevData.length;
            var xSum:Number = 0;
            var ySum:Number = 0;

            for (var i:uint = 0;i < len;i++)
            {
                if (prevData[i][0] === "canvasSize" && prevData[i][5] === true)
                {
                    xSum += prevData[i][3];
                    ySum += prevData[i][4];
                }
            }

            if (xSum === 0 && ySum === 0)
                return null;

            const movedXY:Point = (redoFlag) ? new Point(-xSum, -ySum) : new Point(xSum, ySum);
            return movedXY;
        }

        public static function redo():void
        {
            if (isDeepUndoEnabled)
            {
                main.moveToNextStep();
                main.applyReplayCanvasToDrawModeCanvas();
                main.startAlphaFadeOut(main.rReplayFOFOCursor, 1.0, 0.3);

                if (main.rNowFrame >= addUndoData.getRFileTotalFrame())
                {
                    disableDeepUndo();
                    undoDataIndex = -1;
                }
            }
            else
            {
                undoDataIndex++;

                if (undoDataIndex > main.rData.length - 1)
                {
                    FileManager.isFileAlreadySaved = false;
                    isDeleteUndoDataPending = false;
                    undoDataIndex = main.rData.length - 1;
                }
                else if (main.rData.length > 0)
                {
                    FileManager.isFileAlreadySaved = false;
                    main.drawUndoData(true);
                    main.startAlphaFadeOut(main.rReplayFOFOCursor, 1.0, 0.3);
                }
            }
        }

        public static function undoToIndex(index:int):void
        {
            undoDataIndex = index;
            FileManager.isFileAlreadySaved = false;
            FileManager.enableNewFileButton();
            main.drawUndoData();
        }

        public static function disableDeepUndo():void
        {
            isDeepUndoEnabled = false;
            lastDeepUndoEnabledFlag = false;
            main.rDataReadFlag = true;
            showRCursorOnUndo(-1);
            main.clearRFrameTempCache();
        }

        public static function enableDeepUndo():void
        {
            isDeepUndoEnabled = true;
            main.rDataReadFlag = false;

            if (main.rReplayImageCacheState === main.REPLAY_IMAGE_CAHCHE_READY)
            {
                main.removeInputEventsDrawMode();
                Utils.setAsTopChild(MainUI.seekBarBox);
                MainUI.seekBarBox.updatePos(main.stage.stageWidth);
                main.startGeneratingReplayCacheImage();
            }
            else
            {
                main.updateTotalFrameAndReplayMaxSpeedFor10Sec(main.getTotalFrame());
                // 이미지 캐시 해주고 rPrevFrame 갱신해주고
                main.renderReplayFrame(addUndoData.getRFileTotalFrame() - 1, main.JUMP_FRAME_MANUAL);
                // 실제 rPrevFrame으로 점프
                main.renderReplayFrame(main.rPrevFrame, main.JUMP_FRAME_MANUAL);
                main.applyReplayCanvasToDrawModeCanvas();
            }
        }
    }
}
