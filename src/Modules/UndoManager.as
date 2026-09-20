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
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
            addUndoData = cAddUndoData();
        }

        // Undo / Redo 상태 관리
        public static var undoDataIndex:int = -1; // undo redo 상태 인덱스임
        public static var isDeleteUndoDataPending:Boolean = false; // undo하고 나서 addundo가 되었을때 뒷부분 데이터 전부 날려주는 플래그
        public static var canAddUndoData:Boolean = false; // 선을 그어줄대 선전체가 캔버스 바깥쪽에 있을수도 있으니까 이걸 판단해줌

        // 딥언도 (Deep Undo)
        public static var isDeepUndoEnabled:Boolean = false;
        public static var lastDeepUndoEnabledFlag:Boolean = false; // 리플레이 켜줄때 딥 플래그를 꺼줘서 여기다가 미리 저장해둠
        public static var lastReplayFrameOnDeepUndoStart:Number = -1; // 리플레이 켜줄때 rNowFrame이 변하니까 그전에 백업해주고 꺼주고 다시 undo실행할때 이 프레임 기준으로 하려고
        private static var _mirrorCommandReady:Boolean = false; // 미러 커맨드를 넣어줄지 말지 결정

        // Undo 매니저 클로저 객체
        public static var addUndoData:Object;

        public static function get mirrorCommandReady():Boolean
        {
            return _mirrorCommandReady;
        }

        public static function set mirrorCommandReady(flag:Boolean):void
        {
            _mirrorCommandReady = flag;
        }

        public static function flipMirrorComandReadyFlag():void
        {
            _mirrorCommandReady = !_mirrorCommandReady;
        }

        // todo : undo 뿐만 아니고 나중에 인스턴스 객체로 바꾸어서 main에다가 서로 부품연결하듯이 깔아주는구조
        public static function cAddUndoData():Object
        {
            var dataWriteCount:uint = 0; // 데이터로 저장할때  rDataFrame 카운터 누적
            var rFileTotalFrame:Number = 0; // file에저장된 프레임수 누적해서 저장

            // undo 할때 이 데이터를 기준점으로 rData그려줌 메모리 적게 하려고
            var undoBaseImage:Array = [
                    ReplayController.rFirstImageLayer1BitmapData.clone(),
                    ReplayController.rFirstImageLayer2BitmapData.clone(),
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
                        ReplayController.rCanvasLayer1BitmapData.clone(),
                        ReplayController.rCanvasLayer2BitmapData.clone(),
                        ReplayController.rCanvasLayer1BitmapData.width,
                        ReplayController.rCanvasLayer1BitmapData.height,
                        ReplayController.RCANVAS_BG_COLOR,
                        ReplayController.rMirrorON
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
                var rMirrorSave:Boolean = ReplayController.rMirrorON;

                if (undoBaseImage[2] !== ReplayController.RCANVAS_WIDTH || undoBaseImage[3] !== ReplayController.RCANVAS_HEIGHT)
                {
                    ReplayController.updateCanvasSizeReplayMode(undoBaseImage[2], undoBaseImage[3], 0, 0, false);
                }

                if (undoBaseImage[4] !== ReplayController.RCANVAS_BG_COLOR)
                {
                    ReplayController.updateCanvasBGColorReplayMode(undoBaseImage[4]);
                }

                ReplayController.rCanvasLayer1BitmapData = CanvasController.updateBitmapData(ReplayController.rCanvasLayer1BitmapData, undoBaseImage[0], ReplayController.rCanvasLayer1Bitmap);
                ReplayController.rCanvasLayer2BitmapData = CanvasController.updateBitmapData(ReplayController.rCanvasLayer2BitmapData, undoBaseImage[1], ReplayController.rCanvasLayer2Bitmap);

                ReplayController.drawReplayByCommand.setData(ReplayController.rData[0]);
                ReplayController.drawReplayByCommand.drawAll();

                if (undoBaseImage[0] && undoBaseImage[0] !== ReplayController.rCanvasLayer1BitmapData)
                {
                    undoBaseImage[0].dispose();
                }

                if (undoBaseImage[1] && undoBaseImage[1] !== ReplayController.rCanvasLayer2BitmapData)
                {
                    undoBaseImage[1].dispose();
                }

                undoBaseImage[0] = ReplayController.rCanvasLayer1BitmapData.clone();
                undoBaseImage[1] = ReplayController.rCanvasLayer2BitmapData.clone();
                undoBaseImage[2] = ReplayController.RCANVAS_WIDTH;
                undoBaseImage[3] = ReplayController.RCANVAS_HEIGHT;
                undoBaseImage[4] = ReplayController.RCANVAS_BG_COLOR;

                if (ReplayController.rMirrorON !== rMirrorSave)
                {
                    undoBaseImage[5] = !undoBaseImage[5];
                }

                ReplayController.drawReplayByCommand.setFirstRCursorPosCurrent();
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
                    sum += ReplayController.rDataFrame[i];
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
            // todo ReplayController가 자주 호출되므로 ReplayController에 함수를 하나 따로 만들어서 깔끔하게 하는게 나음
            function updateLastRDataMirror():void
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
            function addContinue():void
            {
                if (ReplayController.rData.length === 0)
                    return;

                if (isDeleteUndoDataPending)
                {
                    isDeleteUndoDataPending = false;
                    ReplayController.rData.splice(undoDataIndex + 1);
                    ReplayController.rDataFrame.splice(undoDataIndex + 1);
                }

                updateLastRDataMirror();

                // 버퍼에mirror가 있을수도 있기 때문에 요소를 하나씩 push해주어야함
                const len:uint = ReplayController.rDataBuffer.length;

                for (var i:uint = 0;i < len;i++)
                {
                    ReplayController.rData[ReplayController.rData.length - 1].push(ReplayController.rDataBuffer[i]); // 배열안에 배열이 들어있음
                }

                ReplayController.rDataFrame[ReplayController.rDataFrame.length - 1] = ReplayController.rData[ReplayController.rData.length - 1].length;
                ReplayController.rDataBuffer = [];

                ReplayController.rPrevFrame = ReplayController.rNowFrame;
                ReplayController.rNowFrame = ReplayController.getTotalFrame();

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
                    ReplayController.rData.splice(undoDataIndex + 1);
                    ReplayController.rDataFrame.splice(undoDataIndex + 1);
                }

                if (ReplayController.rData.length >= 10) // 첫번째 이미지는 빼야하니깐 -1로 계산해야함
                {
                    var oldData:Array = ReplayController.rData[0];

                    if (oldData.length > 0)
                    {
                        const fs:FileStream = new FileStream();
                        const c:uint = ReplayController.rDataFrame[0];
                        const rf:File = FileManager.replayDataFilePath;

                        fs.open(rf, FileMode.APPEND);
                        fs.writeObject(oldData);
                        fs.close();

                        oldData = null;
                        rFileTotalFrame += c;
                        dataWriteCount += c;

                        updateReplayCanvasFromUndoBaseInfo();

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

                undoDataIndex = ReplayController.rData.length - 1;

                CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);

                if (ImageViewWindow.isCanvasWindowON)
                {
                    ImageViewWindow.updateCanvasWindowImage();
                }

                ReplayController.rPrevFrame = ReplayController.rNowFrame;
                ReplayController.rNowFrame = ReplayController.getTotalFrame();

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
                if (ReplayController.drawReplayByCommand.hasRCursorFirstPos())
                {
                    const p:Point = ReplayController.drawReplayByCommand.getFirstRCursorPos();
                    ReplayController.drawReplayByCommand.setRCursorPos(p.x, p.y); // 커서 위치도 업에이트 해줘야함 대칭해줄띠 getRcursor로 하기 때문에
                    ReplayController.drawReplayByCommand.updateRCursorPosToFirst();
                }
                else
                {
                    ReplayController.rReplayFOFOCursor.visible = false;
                    MainUI.hideMouseHint();
                }
            }
            else
            {
                ReplayController.drawReplayByCommand.updateRCursorPos();
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

            ReplayController.rData = [];
            ReplayController.rDataFrame = [];
            ReplayController.rDataBuffer = [];

            canAddUndoData = false;
            isDeleteUndoDataPending = false;
            ReplayController.rReplayFOFOCursor.visible = false;
            isDeepUndoEnabled = false;
        }

        public static function getNowFrameUntilUndoIndex(index:int):Number
        {
            return addUndoData.getRFileTotalFrame() + addUndoData.getRDataTotalFrame(index);
        }

        public static function getHowCanvasMoveAfterUndoOrRedo(index:int, redoFlag:Boolean):Point
        {
            const prevData:Array = (redoFlag) ? ReplayController.rData[index] : ReplayController.rData[index + 1];

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
                ReplayController.moveToNextStep();
                CanvasController.applyReplayCanvasToDrawModeCanvas();
                Utils.showDisplayTargetAndFadeOut(ReplayController.rReplayFOFOCursor, 1.0, 0.3);

                if (ReplayController.rNowFrame >= addUndoData.getRFileTotalFrame())
                {
                    disableDeepUndo();
                    undoDataIndex = -1;
                }
            }
            else
            {
                undoDataIndex++;

                if (undoDataIndex > ReplayController.rData.length - 1)
                {
                    FileManager.isFileAlreadySaved = false;
                    isDeleteUndoDataPending = false;
                    undoDataIndex = ReplayController.rData.length - 1;
                }
                else if (ReplayController.rData.length > 0)
                {
                    FileManager.isFileAlreadySaved = false;
                    UndoManager.updateCanvasStateAfterRedo();
                    Utils.showDisplayTargetAndFadeOut(ReplayController.rReplayFOFOCursor, 1.0, 0.3);
                }
            }
        }

        public static function undoToIndex(index:int):void
        {
            undoDataIndex = index;
            FileManager.isFileAlreadySaved = false;
            FileManager.enableNewFileButton();
            UndoManager.updateCanvasStateAfterUndo();
        }

        public static function disableDeepUndo():void
        {
            isDeepUndoEnabled = false;
            lastDeepUndoEnabledFlag = false;
            ReplayController.rDataReadFlag = true;
            showRCursorOnUndo(-1);
            ReplayController.clearRFrameTempCache();
        }

        public static function enableDeepUndo():void
        {
            isDeepUndoEnabled = true;
            ReplayController.rDataReadFlag = false;

            if (ReplayController.rReplayImageCacheState === ReplayController.REPLAY_IMAGE_CAHCHE_READY)
            {
                InputController.removeInputEventsDrawMode();
                Utils.setAsTopChild(MainUI.seekBarBox);
                MainUI.seekBarBox.updatePos(main.stage.stageWidth);
                ReplayController.startGeneratingReplayCacheImage();
            }
            else
            {
                ReplayController.updateTotalFrameAndReplayMaxSpeedFor10Sec(ReplayController.getTotalFrame());
                // 이미지 캐시 해주고 rPrevFrame 갱신해주고
                ReplayController.renderReplayFrame(addUndoData.getRFileTotalFrame() - 1, ReplayController.JUMP_FRAME_MANUAL);
                // 실제 rPrevFrame으로 점프
                ReplayController.renderReplayFrame(ReplayController.rPrevFrame, ReplayController.JUMP_FRAME_MANUAL);
                CanvasController.applyReplayCanvasToDrawModeCanvas();
            }
        }

        // addundo data에서 캔버스 비트맵 데이터가 변경되기 전, rdatabuffer 비어있을때 넣어줘야함
        public static function applyDeepUndo():void
        {
            const fs:FileStream = new FileStream();
            fs.open(FileManager.replayDataFilePath, FileMode.UPDATE);
            fs.position = ReplayController.rFileLastBytePosition;
            fs.truncate(); // 데이터 위에 짤라주고
            fs.close();
            // 썸네일 이미지도 날려줌
            const rNowFrameSave:Number = ReplayController.rNowFrame;
            const list:Array = FileManager.replayCacheImageFolderPath.getDirectoryListing();
            const index:Number = ReplayController.getCachedFrameImageIndex(rNowFrameSave);
            const len:uint = list.length;
            // index번 이후 파일 삭제
            for (var i:uint = 0;i < len;i++)
            {
                if (parseInt(list[i].name) > index)
                {
                    list[i].deleteFile();
                }
            }
            // framedata도 인덱스 이후꺼 날려줌
            ReplayController.rJumpImageFrameData.splice(index + 1);
            UndoManager.addUndoData.setRFileTotalFrame(rNowFrameSave);
            ReplayController.updateTotalFrameAndReplayMaxSpeedFor10Sec(rNowFrameSave);
            ReplayController.resetReplayTime();
            UndoManager.resetUndoState(true);
            ReplayController.rReplayFOFOCursor.visible = true; // 대칭된 커서 위치를 갱신해주려고 임시로 켜줌
            // checkMirrorCanvasReplayMirror();
            CanvasController.canvasInfoBox.setMirror(CanvasController.isCanvasMirrored);
            ReplayController.drawReplayByCommand.setFirstRCursorPosCurrent();
            ReplayController.rReplayFOFOCursor.visible = false;
            CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
                ImageViewWindow.updateCanvasWindowBitmapSize();
            }
            UndoManager.disableDeepUndo();
        }

        public static function undo():void
        {
            if (ReplayController.isGeneratingCacheImages())
            {
                InputController.removeKeyRepeatEvents(null);
                return;
            }
            if (UndoManager.isDeepUndoEnabled)
            {
                if (ReplayController.rNowFrame > 0)
                {
                    ReplayController.moveToPreviousStep();
                    CanvasController.applyReplayCanvasToDrawModeCanvas();
                    Utils.showDisplayTargetAndFadeOut(ReplayController.rReplayFOFOCursor, 1.0, 0.3);
                }
            }
            else
            {
                UndoManager.undoDataIndex--;
                if (UndoManager.undoDataIndex < -1)
                {
                    FileManager.isFileAlreadySaved = false;
                    UndoManager.undoDataIndex = -1;
                    if (ReplayController.rReplayImageCacheState === ReplayController.REPLAY_IMAGE_CAHCHE_READY || (ReplayController.rReplayImageCacheState === ReplayController.REPLAY_IMAGE_CAHCHE_COMPLETE && UndoManager.addUndoData.getRFileTotalFrame() > 0))
                    {
                        UndoManager.enableDeepUndo();
                        Utils.showDisplayTargetAndFadeOut(ReplayController.rReplayFOFOCursor, 1.0, 0.3);
                    }
                }
                else if (ReplayController.rData.length > 0)
                {
                    FileManager.isFileAlreadySaved = false;
                    UndoManager.isDeleteUndoDataPending = true;
                    updateCanvasStateAfterUndo();
                    Utils.showDisplayTargetAndFadeOut(ReplayController.rReplayFOFOCursor, 1.0, 0.3);
                }
            }
        }

        public static function updateCanvasStateAfterRedo():void
        {
            _updateCanvasState(true);
        }

        public static function updateCanvasStateAfterUndo():void
        {
            _updateCanvasState(false);
        }

        public static function _updateCanvasState(redoFlag:Boolean):void
        {
            const undoRefData:Array = UndoManager.addUndoData.getUndoBaseImage();
            const undoIndexSave:int = UndoManager.undoDataIndex;

            // 리플레이 캔버스 먼저 갱신
            ReplayController.updateReplayCanvasFromUndoRefData(undoRefData, undoIndexSave);

            // 앞 뒤 데이터가 캔버스 원점 이동 되었을때 반대방향으로 다시 움직여줌
            const movedRegPos:Point = UndoManager.getHowCanvasMoveAfterUndoOrRedo(undoIndexSave, redoFlag);
            if (movedRegPos)
            {
                CanvasController.canvasAnchorPoint.x += movedRegPos.x * CanvasController.canvasZoomMultipler;
                CanvasController.canvasAnchorPoint.y += movedRegPos.y * CanvasController.canvasZoomMultipler;
                ReferenceLayerController.updateRefLayerBitmapPos(movedRegPos);
            }
            CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, ReplayController.rCanvasLayer1BitmapData, CanvasController.canvasLayer1Bitmap);
            CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, ReplayController.rCanvasLayer2BitmapData, CanvasController.canvasLayer2Bitmap);
            UndoManager.showRCursorOnUndo(UndoManager.undoDataIndex);
            ReplayController.checkMirrorCanvasReplayMirror();
            CanvasController.canvasNavigatorBox.updateImage(CanvasController.canvasLayer1BitmapData, CanvasController.canvasLayer2BitmapData, CanvasController.CANVAS_BG_COLOR);

            // canvas window 상태 갱신
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
                ImageViewWindow.updateCanvasWindowBitmapSize();
            }
            CanvasController.keepCanvasPanelInStage(); // 사이즈가 크가 줄었을때 캔버스가 창 밖으로 나가는거 체크
            MainUIController.updateCanvasNaigatorCursor();
            FileManager.enableNewFileButton();
        }
    }
}
