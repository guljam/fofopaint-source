package Modules
{
    import Modules.DrawEngine.DrawCanvas;
    import Modules.UIEngine.CanvasNavigator;
    import flash.display.BitmapData;
    import flash.filesystem.FileStream;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import Modules.ReplayEngine.ReplayClock;
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.ReplayEngine.ReplayFileCache;
    import Modules.ReplayEngine.ReplayState;
    import Modules.ReplayEngine.TimingSheetFile;

    // 메모리 undo 데이터(ReplayState.rMemoryData)를 쌓고 자르는 일과 undo 위치, undo 기준 이미지를 맡음
    // undo 위치를 옮겨서 캔버스를 다시 그리는 일은 UndoController가 함
    public class UndoHistory
    {
        private static const NATIVE_UNDO_LIMIT_COUNT:int = 10;

        private static var _undoDataIndex:int = -1; // undo redo 상태 인덱스임
        public static var canAddUndoData:Boolean = false; // 선을 그어줄대 선전체가 캔버스 바깥쪽에 있을수도 있으니까 이걸 판단해줌

        // undo 할때 이 데이터를 기준점으로 rData그려줌 메모리 적게 하려고
        private static var undoBaseImage:Array = [
                ReplayFileCache.rFirstImageLayer1BitmapData.clone(),
                ReplayFileCache.rFirstImageLayer2BitmapData.clone(),
                DrawCanvas.CANVAS_WIDTH,
                DrawCanvas.CANVAS_HEIGHT,
                DrawCanvas.CANVAS_BG_COLOR,
                DrawCanvas.mirrorON
            ];

        public static function get undoDataIndex():int
        {
            return _undoDataIndex;
        }

        public static function setUndoDataIndex(index:int):void
        {
            _undoDataIndex = index;
        }

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
                    DrawCanvas.canvasLayer1BitmapData.clone(),
                    DrawCanvas.canvasLayer2BitmapData.clone(),
                    DrawCanvas.canvasLayer1BitmapData.width,
                    DrawCanvas.canvasLayer1BitmapData.height,
                    DrawCanvas.CANVAS_BG_COLOR,
                    DrawCanvas.mirrorON
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

        // 메모리 undo 데이터만 비움, undo 기준 이미지는 그대로 둠
        public static function clearMemoryUndoData():void
        {
            _undoDataIndex = -1;
            ReplayState.rMemoryData = [];
            ReplayState.rMemoryDataFrames = [];
            ReplayState.rMemoryDataTimingSheet = [];
            ReplayState.rMemoryDataBuffer = [];
        }

        // 기준 이미지를 지금 캔버스로 바꾸고 메모리 undo 데이터를 비움
        public static function reset(fromReplayMode:Boolean):void
        {
            if (fromReplayMode)
            {
                updateUndoBaseImageFromReplayMode();
            }
            else
            {
                updateUndoBaseImageFromDrawMode();
            }

            clearMemoryUndoData();
            canAddUndoData = false;
        }

        // 끝 부분 중복처리 일때 넣어주는 거
        public static function addContinue():void
        {
            if (ReplayState.rMemoryData.length === 0)
                return;

            discardRedoData();
            ReplayState.updateLastRMemoryDataMirror();

            // 버퍼에mirror가 있을수도 있기 때문에 요소를 하나씩 push해주어야함
            const len:uint = ReplayState.rMemoryDataBuffer.length;
            const bufferTimes:Array = ReplayState.takeTimingSheetBufferTimes();

            for (var i:uint = 0;i < len;i++)
            {
                ReplayState.rMemoryData[ReplayState.rMemoryData.length - 1].push(ReplayState.rMemoryDataBuffer[i]); // 배열안에 배열이 들어있음
                ReplayState.rMemoryDataTimingSheet[ReplayState.rMemoryDataTimingSheet.length - 1].push(bufferTimes[i]);
            }

            ReplayState.rMemoryDataFrames[ReplayState.rMemoryDataFrames.length - 1] = ReplayState.rMemoryData[ReplayState.rMemoryData.length - 1].length;
            ReplayState.rMemoryDataBuffer = [];
            ReplayState.syncRNowFrameWithTotalFrame();

            updateCanvasPreviews();
        }

        public static function addNew():void
        {
            discardRedoData();

            if (ReplayState.rMemoryData.length >= NATIVE_UNDO_LIMIT_COUNT)
            {
                moveOldestUndoDataToReplayFile();
            }

            ReplayState.updateLastRMemoryDataMirror();

            if (ReplayState.rMemoryDataBuffer.length > 0)
            {
                ReplayState.rMemoryDataTimingSheet.push(ReplayState.takeTimingSheetBufferTimes());
                ReplayState.rMemoryData.push(ReplayState.rMemoryDataBuffer);
                ReplayState.rMemoryDataFrames.push(ReplayState.rMemoryDataBuffer.length);
                ReplayState.rMemoryDataBuffer = [];
                FileManager.isFileAlreadySaved = false;
                ReplayState.rMemoryDataReadON = true;
            }

            _undoDataIndex = ReplayState.rMemoryData.length - 1;

            updateCanvasPreviews();
            ReplayState.syncRNowFrameWithTotalFrame();
            FileManager.enableNewFileButton();
        }

        // undo 해서 뒤로 간 상태에서 새 데이터가 들어오면 지금 위치 뒤의 데이터는 버림, 끝에 있으면 아무것도 안 함
        private static function discardRedoData():void
        {
            ReplayState.rMemoryData.splice(_undoDataIndex + 1);
            ReplayState.rMemoryDataFrames.splice(_undoDataIndex + 1);
            ReplayState.rMemoryDataTimingSheet.splice(_undoDataIndex + 1);
        }

        // 가장 오래된 undo 뭉치를 리플레이 파일 끝에 붙이고, 기준 이미지를 그 뭉치까지 그린 이미지로 옮김
        private static function moveOldestUndoDataToReplayFile():void
        {
            var oldData:Array = ReplayState.rMemoryData[0];

            if (oldData.length > 0)
            {
                const fs:FileStream = new FileStream();
                const firstElementFrameCount:uint = ReplayState.rMemoryDataFrames[0];
                const rf:File = AppStateManager.replayDataFilePath;
                const lastRDataTotalFrame:Number = ReplayState.getRFileDataTotalFrame();

                fs.open(rf, FileMode.APPEND);
                fs.writeObject(oldData);
                fs.close();
                oldData = null;
                const written:Vector.<uint> = TimingSheetFile.appendGroupAtFrame(ReplayState.rMemoryDataTimingSheet[0], lastRDataTotalFrame);
                ReplayState.increaseRFileDataTotalFrame(firstElementFrameCount);
                ReplayClock.extendFileIndexWith(written, lastRDataTotalFrame); // 덧붙은 프레임만 시간 색인에 반영 (파일을 다시 읽지 않음)
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
            ReplayState.rMemoryDataFrames[0] = null;
            ReplayState.rMemoryDataFrames.shift();
            ReplayState.rMemoryDataTimingSheet.shift();
        }

        private static function updateCanvasPreviews():void
        {
            CanvasNavigator.box.updateImage();

            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
            }
        }
    }
}
