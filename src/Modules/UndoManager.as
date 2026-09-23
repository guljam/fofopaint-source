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
        }

        // Undo / Redo 상태 관리
        public static var undoDataIndex:int = -1; // undo redo 상태 인덱스임
        public static var canAddUndoData:Boolean = false; // 선을 그어줄대 선전체가 캔버스 바깥쪽에 있을수도 있으니까 이걸 판단해줌
        public static var isDeleteUndoDataPending:Boolean = false; // undo하고 나서 addundo가 되었을때 뒷부분 데이터 전부 날려주는 플래그

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
                UndoController.updateUndoBaseImageFromReplayMode();
            }
            else
            {
                UndoController.updateUndoBaseImageFromDrawMode();
            }

            UndoController.resetRJumpImageCount();

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
            return ReplayController.getRFileTotalFrame() + UndoController.getRDataTotalFrame(index);
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

                if (ReplayController.rNowFrame >= ReplayController.getRFileTotalFrame())
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
                ReplayController.renderReplayFrame(ReplayController.getRFileTotalFrame() - 1, ReplayController.JUMP_FRAME_MANUAL);
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
            ReplayController.setRFileTotalFrame(rNowFrameSave);
            ReplayController.updateTotalFrameAndReplayMaxSpeedFor10Sec(rNowFrameSave);
            ReplayController.resetReplayTime();
            UndoManager.resetUndoState(true);
            ReplayController.rReplayFOFOCursor.visible = true; // 대칭된 커서 위치를 갱신해주려고 임시로 켜줌
            // checkMirrorCanvasReplayMirror();
            CanvasController.canvasInfoBox.setMirror(CanvasController.isCanvasMirrored);
            ReplayController.drawReplayByCommand.setFirstRCursorPosCurrent();
            ReplayController.rReplayFOFOCursor.visible = false;
            CanvasController.canvasNavigatorBox.updateImage();
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
                    if (ReplayController.rReplayImageCacheState === ReplayController.REPLAY_IMAGE_CAHCHE_READY || (ReplayController.rReplayImageCacheState === ReplayController.REPLAY_IMAGE_CAHCHE_COMPLETE && ReplayController.getRFileTotalFrame() > 0))
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
            const undoRefData:Array = UndoController.getUndoBaseImage();
            const undoIndexSave:int = UndoManager.undoDataIndex;

            // 리플레이 캔버스 먼저 갱신
            ReplayController.updateReplayCanvasFromUndoRefData(undoRefData, undoIndexSave);

            //드로우 모드 캔버스 bmpd갱신하고 크기 정보 갱신
            CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData,ReplayController.rCanvasLayer1BitmapData,CanvasController.canvasLayer1Bitmap)
            CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData,ReplayController.rCanvasLayer2BitmapData,CanvasController.canvasLayer2Bitmap)
            CanvasController.syncDrawModeCanvasSizeToReplayMode(CanvasController.canvasLayer1BitmapData.width,CanvasController.canvasLayer1BitmapData.height);

            // 앞 뒤 데이터가 캔버스 원점 이동 되었을때 반대방향으로 다시 움직여줌
            const movedRegPos:Point = UndoManager.getHowCanvasMoveAfterUndoOrRedo(undoIndexSave, redoFlag);
            if (movedRegPos)
            {
                CanvasController.canvasAnchorPoint.x += movedRegPos.x * CanvasController.canvasZoomMultipler;
                CanvasController.canvasAnchorPoint.y += movedRegPos.y * CanvasController.canvasZoomMultipler;
                ReferenceLayerController.updateRefLayerBitmapPos(movedRegPos);
            }

            ReplayController.updateMirrorStateDrawModeNotSameRreplayMirrorState();
            CanvasController.canvasNavigatorBox.updateImage();
            CanvasController.setCanvasBGColorDrawMode(ReplayController.RCANVAS_BG_COLOR);
            CanvasController.updateCanvasPanelColorAndSize();

            UndoManager.showRCursorOnUndo(UndoManager.undoDataIndex);
            // canvas window 상태 갱신
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
                ImageViewWindow.updateCanvasWindowBitmapSize();
            }
            
            MainUIController.updateCanvasNaigatorCursor();
            FileManager.enableNewFileButton();
        }
    }
}
