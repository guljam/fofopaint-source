package Modules
{
    import flash.display.BitmapData;
    import flash.filesystem.FileStream;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.ReplayEngine.ReplayFileCache;
    import Modules.ReplayEngine.ReplayState;

    public class UndoController
    {
        private static const NATIVE_UNDO_LIMIT_COUNT:int = 10;

        // undo 할때 이 데이터를 기준점으로 rData그려줌 메모리 적게 하려고
        private static var undoBaseImage:Array = [
                ReplayFileCache.rFirstImageLayer1BitmapData.clone(),
                ReplayFileCache.rFirstImageLayer2BitmapData.clone(),
                CanvasController.CANVAS_WIDTH,
                CanvasController.CANVAS_HEIGHT,
                CanvasController.CANVAS_BG_COLOR,
                CanvasController.mirrorON
            ];

        public static function updateUndoBaseImageMirrorFlag(flag:Boolean):void
        {
            undoBaseImage[5] = flag;
        }

        public static function updateUndoBaseImageFromReplayMode():void
        {
            updateUndoBaseImage(
                    ReplayDrawer.rCanvasLayer1BitmapData.clone(),
                    ReplayDrawer.rCanvasLayer2BitmapData.clone(),
                    ReplayDrawer.rCanvasLayer1BitmapData.width,
                    ReplayDrawer.rCanvasLayer1BitmapData.height,
                    ReplayState.RCANVAS_BG_COLOR,
                    ReplayState.rMirrorON
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
            if (ReplayState.rMemoryData.length === 0)
                return;

            if (UndoManager.isDeleteUndoDataPending)
            {
                UndoManager.isDeleteUndoDataPending = false;
                ReplayState.rMemoryData.splice(UndoManager.undoDataIndex + 1);
                ReplayState.rMemoryDataFrame.splice(UndoManager.undoDataIndex + 1);
            }

            ReplayState.updateLastRMemoryDataMirror();

            // 버퍼에mirror가 있을수도 있기 때문에 요소를 하나씩 push해주어야함
            const len:uint = ReplayState.rMemoryDataBuffer.length;

            for (var i:uint = 0;i < len;i++)
            {
                ReplayState.rMemoryData[ReplayState.rMemoryData.length - 1].push(ReplayState.rMemoryDataBuffer[i]); // 배열안에 배열이 들어있음
            }

            ReplayState.rMemoryDataFrame[ReplayState.rMemoryDataFrame.length - 1] = ReplayState.rMemoryData[ReplayState.rMemoryData.length - 1].length;
            ReplayState.rMemoryDataBuffer = [];
            ReplayState.syncRNowFrameWithTotalFrame();

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
                ReplayState.rMemoryData.splice(UndoManager.undoDataIndex + 1);
                ReplayState.rMemoryDataFrame.splice(UndoManager.undoDataIndex + 1);
            }

            if (ReplayState.rMemoryData.length >= NATIVE_UNDO_LIMIT_COUNT) // 첫번째 이미지는 빼야하니깐 -1로 계산해야함
            {
                var oldData:Array = ReplayState.rMemoryData[0];

                if (oldData.length > 0)
                {
                    const fs:FileStream = new FileStream();
                    const firstElementFrameCount:uint = ReplayState.rMemoryDataFrame[0];
                    const rf:File = FileManager.replayDataFilePath;
                    const lastRDataTotalFrame:Number = ReplayState.getRFileDataTotalFrame();

                    fs.open(rf, FileMode.APPEND);
                    fs.writeObject(oldData);
                    fs.close();

                    oldData = null;
                    ReplayState.increaseRFileDataTotalFrame(firstElementFrameCount);

                    ReplayDrawer.updateReplayCanvasFromUndoBaseInfo();

                    if (ReplayState.rReplayImageCacheState === ReplayState.REPLAY_IMAGE_CAHCHE_COMPLETE)
                    {
                        // 따로 카운트를 누적하지 않고 마지막 캐시 이미지 프레임과 비교해서
                        // 딥 언두, 파일 불러오기, 리플레이 캐시 생성 이후에도 간격이 맞게 해줌
                        if (ReplayState.getRFileDataTotalFrame() - BackgroundWorkerCoordinator.getLastCacheImageFrame() > ReplayFileCache.REPLAY_DISK_CACHE_FRAME_INTERVAL)
                        {
                            const data:Array = undoBaseImage;

                            BackgroundWorkerCoordinator.startCacheImageWorker(
                                    data[0],
                                    data[1],
                                    new CacheImageMetaData(
                                        data[2],
                                        data[3],
                                        data[4],
                                        rf.size,
                                        lastRDataTotalFrame,
                                        ReplayState.getRFileDataTotalFrame(),
                                        data[5]));
                        }
                    }
                }

                ReplayState.rMemoryData[0].length = 0;
                ReplayState.rMemoryData[0] = null;
                ReplayState.rMemoryData.shift();
                ReplayState.rMemoryDataFrame[0] = null;
                ReplayState.rMemoryDataFrame.shift();
            }

            ReplayState.updateLastRMemoryDataMirror();

            if (ReplayState.rMemoryDataBuffer.length > 0)
            {
                ReplayState.rMemoryData.push(ReplayState.rMemoryDataBuffer);
                ReplayState.rMemoryDataFrame.push(ReplayState.rMemoryDataBuffer.length);
                ReplayState.rMemoryDataBuffer = [];
                FileManager.isFileAlreadySaved = false;
                ReplayState.rMemoryDataReadON = true;
            }

            UndoManager.undoDataIndex = ReplayState.rMemoryData.length - 1;

            CanvasController.canvasNavigatorBox.updateImage();

            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
            }

            ReplayState.syncRNowFrameWithTotalFrame();

            FileManager.enableNewFileButton();
        };
    }
}
