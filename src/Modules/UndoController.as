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

            // undo 할때 이 데이터를 기준점으로 rData그려줌 메모리 적게 하려고
            private static var undoBaseImage:Array = [
                    ReplayController.rFirstImageLayer1BitmapData.clone(),
                    ReplayController.rFirstImageLayer2BitmapData.clone(),
                    CanvasController.CANVAS_WIDTH,
                    CanvasController.CANVAS_HEIGHT,
                    CanvasController.CANVAS_BG_COLOR,
                    CanvasController.isCanvasMirrored
                ];

           public static  function resetRJumpImageCount():void
            {
                dataWriteCount = 0;
            }

           public static  function updateUndoBaseImageMirrorFlag(flag:Boolean):void
            {
                undoBaseImage[5] = flag;
            }

           public static  function updateUndoBaseImageFromReplayMode():void
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

           public static  function updateUndoBaseImageFromDrawMode():void
            {
                updateUndoBaseImage(
                        CanvasController.canvasLayer1BitmapData.clone(),
                        CanvasController.canvasLayer2BitmapData.clone(),
                        CanvasController.canvasLayer1BitmapData.width,
                        CanvasController.canvasLayer1BitmapData.height,
                        CanvasController.CANVAS_BG_COLOR,
                        CanvasController.isCanvasMirrored
                    );
            }

           public static  function getUndoBaseImage():Array
            {
                return undoBaseImage;
            }

           public static  function updateUndoBaseImage(bmpd1:BitmapData, bmpd2:BitmapData, width:Number, height:Number, bgColor:uint, mirrorFlag:Boolean):void
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
           public static  function getRDataTotalFrame(index:int):Number
            {
                if (index < 0)
                {
                    return 0;
                }

                var sum:Number = 0;

                for (var i:int = 0;i <= index;i++)
                {
                    sum += ReplayController.rDataFrame[i];
                }

                return sum;
            }

            // 미러가 되어있는지 확인해서 mirror커맨드를 무조건 앞으로 보냄
            // 그게 아니면 미러 커맨드 지워줌
            // todo ReplayController가 자주 호출되므로 ReplayController에 함수를 하나 따로 만들어서 깔끔하게 하는게 나음
           public static  function updateLastRDataMirror():void
            {
                var popArr:Array;

                if (UndoManager.mirrorCommandReady)
                {
                    // 마지막 데이터에 1개만의 미러 커맨드가 있으먼 미러를 무효로함 mirror mirror니까 원래대로임
                    if (ReplayController.rData.length > 0 && ReplayController.rData[ReplayController.rData.length - 1].length === 1 && ReplayController.rData[ReplayController.rData.length - 1][0][0] === "mirror")
                    {
                        UndoManager.mirrorCommandReady = false;
                        ReplayController.rData.pop();
                        ReplayController.rDataFrame.pop();
                    }
                    // 그게 아니면 가장 앞에 미러커맨드를 넣어줌
                    else if (ReplayController.rDataBuffer.length > 0 && ReplayController.rDataBuffer[0][0] !== "mirror")
                    {
                        UndoManager.mirrorCommandReady = false;
                        ReplayController.rDataBuffer.unshift(["mirror"]);
                    }
                }
                else
                {
                    // 미러 커맨드가 꺼져있는데 독립인 미러커맨드가 있으면 지워주고 미러 커맨드 플래그를 올려줘서 다음번에
                    // 미러 커맨드가 가장 앞에 오도록함
                    if (ReplayController.rData.length > 0 && ReplayController.rData[ReplayController.rData.length - 1].length === 1 && ReplayController.rData[ReplayController.rData.length - 1][0][0] === "mirror")
                    {
                        ReplayController.rData.pop();
                        ReplayController.rDataFrame.pop();
                        UndoManager.mirrorCommandReady = true;
                    }
                    // 그게 아니면 그냥 지워줌
                    else if (ReplayController.rDataBuffer.length > 0 && ReplayController.rDataBuffer[0][0] === "mirror")
                    {
                        ReplayController.rDataBuffer.shift();
                    }
                }
            }

            // 끝 부분 중복처리 일때 넣어주는 거
           public static  function addContinue():void
            {
                if (ReplayController.rData.length === 0)
                    return;

                if (UndoManager.isDeleteUndoDataPending)
                {
                    UndoManager.isDeleteUndoDataPending = false;
                    ReplayController.rData.splice(UndoManager.undoDataIndex + 1);
                    ReplayController.rDataFrame.splice(UndoManager.undoDataIndex + 1);
                }

                updateLastRDataMirror();

                // 버퍼에mirror가 있을수도 있기 때문에 요소를 하나씩 push해주어야함
                const len:uint = ReplayController.rDataBuffer.length;

                for (var i:uint = 0; i < len; i++)
                {
                    ReplayController.rData[ReplayController.rData.length - 1].push(ReplayController.rDataBuffer[i]); // 배열안에 배열이 들어있음
                }

                ReplayController.rDataFrame[ReplayController.rDataFrame.length - 1] = ReplayController.rData[ReplayController.rData.length - 1].length;
                ReplayController.rDataBuffer = [];

                ReplayController.rPrevFrame = ReplayController.rNowFrame;
                ReplayController.rNowFrame = ReplayController.getTotalFrame();

                CanvasController.canvasNavigatorBox.updateImage();

                if (ImageViewWindow.isCanvasWindowON)
                {
                    ImageViewWindow.updateCanvasWindowImage();
                }
            }

           public static  function addNew():void
            {
                if (UndoManager.isDeleteUndoDataPending === true)
                {
                    UndoManager.isDeleteUndoDataPending = false;
                    ReplayController.rData.splice(UndoManager.undoDataIndex + 1);
                    ReplayController.rDataFrame.splice(UndoManager.undoDataIndex + 1);
                }

                if (ReplayController.rData.length >= 10) // 첫번째 이미지는 빼야하니깐 -1로 계산해야함
                {
                    var oldData:Array = ReplayController.rData[0];

                    if (oldData.length > 0)
                    {
                        const fs:FileStream = new FileStream();
                        const firstElementFrameCount:uint = ReplayController.rDataFrame[0];
                        const rf:File = FileManager.replayDataFilePath;

                        fs.open(rf, FileMode.APPEND);
                        fs.writeObject(oldData);
                        fs.close();

                        oldData = null;
                        ReplayController.increaseRFileTotalFrame(firstElementFrameCount);
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

                                BackgroundWorkerCoordinator.undoDataQueue.push([w, h, bgColor, rf.size, ReplayController.getRFileTotalFrame(), CanvasController.isCanvasMirrored]);
                                BackgroundWorkerCoordinator.startUndoImageCompressionWorker(imgData, imgData1);
                                BackgroundWorkerCoordinator.pollTimerWaitWorkerForCacheUndoData();
                            }
                        }
                    }

                    ReplayController.rData[0].length = 0;
                    ReplayController.rData[0] = null;
                    ReplayController.rDataFrame[0] = null;
                    ReplayController.rData.shift();
                    ReplayController.rDataFrame.shift();
                }

                updateLastRDataMirror();

                if (ReplayController.rDataBuffer.length > 0)
                {
                    ReplayController.rData.push(ReplayController.rDataBuffer);
                    ReplayController.rDataFrame.push(ReplayController.rDataBuffer.length);
                    ReplayController.rDataBuffer = [];
                    FileManager.isFileAlreadySaved = false;
                    ReplayController.rDataReadFlag = true;
                }

                UndoManager.undoDataIndex = ReplayController.rData.length - 1;

                CanvasController.canvasNavigatorBox.updateImage();

                if (ImageViewWindow.isCanvasWindowON)
                {
                    ImageViewWindow.updateCanvasWindowImage();
                }

                ReplayController.rPrevFrame = ReplayController.rNowFrame;
                ReplayController.rNowFrame = ReplayController.getTotalFrame();

                FileManager.enableNewFileButton();
            };
    }
}
