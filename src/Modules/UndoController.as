package Modules
{
    import flash.display.BitmapData;
    import flash.filesystem.FileStream;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.utils.ByteArray;
    import flash.geom.Rectangle;

    public class UndoController
    {
        private static var dataWriteCount:uint = 0; // 데이터로 저장할때  rDataFrame 카운터 누적
        private static const NATIVE_UNDO_LIMIT_COUNT:int = 10;

        // undo 할때 이 데이터를 기준점으로 rData그려줌 메모리 적게 하려고
        private static var undoBaseImage:Array = [
                ReplayController.rFirstImageLayer1BitmapData.clone(),
                ReplayController.rFirstImageLayer2BitmapData.clone(),
                CanvasController.CANVAS_WIDTH,
                CanvasController.CANVAS_HEIGHT,
                CanvasController.CANVAS_BG_COLOR,
                CanvasController.mirrorON
            ];

        public static function resetRJumpImageCount():void
        {
            dataWriteCount = 0;
        }

        public static function updateUndoBaseImageMirrorFlag(flag:Boolean):void
        {
            undoBaseImage[5] = flag;
        }

        public static function updateUndoBaseImageFromReplayMode():void
        {
            updateUndoBaseImage(
                    ReplayController.rCanvasLayer1BitmapData.clone(),
                    ReplayController.rCanvasLayer2BitmapData.clone(),
                    ReplayController.rCanvasLayer1BitmapData.width,
                    ReplayController.rCanvasLayer1BitmapData.height,
                    ReplayController.RCANVAS_BG_COLOR,
                    ReplayController.rMirrorON
                );
        }

        public static function updateUndoBaseImageFromDrawMode():void
        {
            updateUndoBaseImage(
                    CanvasController.canvasLayer1BitmapData.clone(),
                    CanvasController.canvasLayer2BitmapData.clone(),
                    CanvasController.canvasLayer1BitmapData.width,
                    CanvasController.canvasLayer1BitmapData.height,
                    CanvasController.CANVAS_BG_COLOR,
                    CanvasController.mirrorON
                );
        }

        public static function getUndoBaseImage():Array
        {
            return undoBaseImage;
        }

        public static function updateUndoBaseImage(bmpd1:BitmapData, bmpd2:BitmapData, width:Number, height:Number, bgColor:uint, mirrorFlag:Boolean):void
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

        // 끝 부분 중복처리 일때 넣어주는 거
        public static function addContinue():void
        {
            if (ReplayController.rMemoryData.length === 0)
                return;

            if (UndoManager.isDeleteUndoDataPending)
            {
                UndoManager.isDeleteUndoDataPending = false;
                ReplayController.rMemoryData.splice(UndoManager.undoDataIndex + 1);
                ReplayController.rMemoryDataFrame.splice(UndoManager.undoDataIndex + 1);
            }

            ReplayController.updateLastRMemoryDataMirror();

            // 버퍼에mirror가 있을수도 있기 때문에 요소를 하나씩 push해주어야함
            const len:uint = ReplayController.rMemoryDataBuffer.length;

            for (var i:uint = 0;i < len;i++)
            {
                ReplayController.rMemoryData[ReplayController.rMemoryData.length - 1].push(ReplayController.rMemoryDataBuffer[i]); // 배열안에 배열이 들어있음
            }

            ReplayController.rMemoryDataFrame[ReplayController.rMemoryDataFrame.length - 1] = ReplayController.rMemoryData[ReplayController.rMemoryData.length - 1].length;
            ReplayController.rMemoryDataBuffer = [];
            ReplayController.syncRNowFrameWithTotalFrame();

            CanvasController.canvasNavigatorBox.updateImage();

            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
            }
        }

        public static function addNew():void
        {
            if (UndoManager.isDeleteUndoDataPending === true)
            {
                UndoManager.isDeleteUndoDataPending = false;
                ReplayController.rMemoryData.splice(UndoManager.undoDataIndex + 1);
                ReplayController.rMemoryDataFrame.splice(UndoManager.undoDataIndex + 1);
            }

            if (ReplayController.rMemoryData.length >= NATIVE_UNDO_LIMIT_COUNT) // 첫번째 이미지는 빼야하니깐 -1로 계산해야함
            {
                var oldData:Array = ReplayController.rMemoryData[0];

                if (oldData.length > 0)
                {
                    const fs:FileStream = new FileStream();
                    const firstElementFrameCount:uint = ReplayController.rMemoryDataFrame[0];
                    const rf:File = FileManager.replayDataFilePath;
                    const lastRDataTotalFrame:Number = ReplayController.getRFileDataTotalFrame();

                    fs.open(rf, FileMode.APPEND);
                    fs.writeObject(oldData);
                    fs.close();

                    oldData = null;
                    ReplayController.increaseRFileDataTotalFrame(firstElementFrameCount);
                    dataWriteCount += firstElementFrameCount;

                    ReplayController.updateReplayCanvasFromUndoBaseInfo();

                    if (ReplayController.rReplayImageCacheState === ReplayController.REPLAY_IMAGE_CAHCHE_COMPLETE)
                    {
                        if (dataWriteCount > ReplayController.REPLAY_DISK_CACHE_FRAME_INTERVAL)
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

                            if (BackgroundWorkerCoordinator.receivedUndoImageQueueFromWorker === null)
                                BackgroundWorkerCoordinator.receivedUndoImageQueueFromWorker = [];

                            if (BackgroundWorkerCoordinator.undoDataQueue === null)
                                BackgroundWorkerCoordinator.undoDataQueue = [];

                            BackgroundWorkerCoordinator.undoDataQueue.push(
                                    new CacheImageMetaData(
                                        w,
                                        h,
                                        bgColor,
                                        rf.size,
                                        lastRDataTotalFrame,
                                        ReplayController.getRFileDataTotalFrame(),
                                        data[5]));
                            BackgroundWorkerCoordinator.startUndoImageCompressionWorker(imgData, imgData1);
                            BackgroundWorkerCoordinator.pollTimerWaitWorkerForCacheUndoData();
                        }
                    }
                }

                ReplayController.rMemoryData[0].length = 0;
                ReplayController.rMemoryData[0] = null;
                ReplayController.rMemoryDataFrame[0] = null;
                ReplayController.rMemoryData.shift();
                ReplayController.rMemoryDataFrame.shift();
            }

            ReplayController.updateLastRMemoryDataMirror();

            if (ReplayController.rMemoryDataBuffer.length > 0)
            {
                ReplayController.rMemoryData.push(ReplayController.rMemoryDataBuffer);
                ReplayController.rMemoryDataFrame.push(ReplayController.rMemoryDataBuffer.length);
                ReplayController.rMemoryDataBuffer = [];
                FileManager.isFileAlreadySaved = false;
                ReplayDrawer.rMemoryDataReadON = true;
            }

            UndoManager.undoDataIndex = ReplayController.rMemoryData.length - 1;

            CanvasController.canvasNavigatorBox.updateImage();

            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
            }

            ReplayController.syncRNowFrameWithTotalFrame();

            FileManager.enableNewFileButton();
        };
    }
}
