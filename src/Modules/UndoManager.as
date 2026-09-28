package Modules
{
    import flash.display.BitmapData;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayDrawCommands;
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.ReplayEngine.ReplayFileCache;
    import Modules.ReplayEngine.ReplayState;

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
                if (ReplayDrawCommands.hasRCursorFirstPos())
                {
                    const p:Point = ReplayDrawCommands.getFirstRCursorPos();
                    ReplayDrawCommands.setRCursorPos(p.x, p.y); // 커서 위치도 업에이트 해줘야함 대칭해줄띠 getRcursor로 하기 때문에
                    ReplayDrawCommands.updateRCursorPosToFirst();
                }
                else
                {
                    ReplayDrawer.rReplayFOFOCursor.visible = false;
                    MainUI.hideMouseHint();
                }
            }
            else
            {
                ReplayDrawCommands.updateRCursorPos();
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

            ReplayState.rMemoryData = [];
            ReplayState.rMemoryDataFrame = [];
            ReplayState.rMemoryDataBuffer = [];

            canAddUndoData = false;
            isDeleteUndoDataPending = false;
            ReplayDrawer.rReplayFOFOCursor.visible = false;
            isDeepUndoEnabled = false;
        }

        public static function getHowCanvasMoveAfterUndoOrRedo(index:int, redoFlag:Boolean):Point
        {
            const prevData:Array = (redoFlag) ? ReplayState.rMemoryData[index] : ReplayState.rMemoryData[index + 1];

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
                Utils.showDisplayTargetAndFadeOut(ReplayDrawer.rReplayFOFOCursor, 1.0, 0.3);

                if (ReplayState.rNowFrame >= ReplayState.getRFileDataTotalFrame())
                {
                    exitDeepUndo();
                    undoDataIndex = -1;
                }
            }
            else
            {
                undoDataIndex++;

                if (undoDataIndex > ReplayState.rMemoryData.length - 1)
                {
                    FileManager.isFileAlreadySaved = false;
                    isDeleteUndoDataPending = false;
                    undoDataIndex = ReplayState.rMemoryData.length - 1;
                }
                else if (ReplayState.rMemoryData.length > 0)
                {
                    FileManager.isFileAlreadySaved = false;
                    UndoManager.updateCanvasStateAfterRedo();
                    Utils.showDisplayTargetAndFadeOut(ReplayDrawer.rReplayFOFOCursor, 1.0, 0.3);
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

        public static function exitDeepUndo():void
        {
            isDeepUndoEnabled = false;
            lastDeepUndoEnabledFlag = false;
            ReplayState.rMemoryDataReadON = true;
            showRCursorOnUndo(-1);
            ReplayFileCache.clearRFrameTempCache();
        }

        public static function enterDeepUndo():void
        {
            isDeepUndoEnabled = true;
            ReplayState.rMemoryDataReadON = false;
            ReplayController.updateTotalFrameAndReplayMaxSpeedFor10Sec(ReplayState.getTotalFrame());
            // 이미지 캐시 해주고 rPrevFrame 갱신해주고
            ReplayDrawer.renderReplayFrame(ReplayState.getRFileDataTotalFrame() - 1, ReplayDrawer.JUMP_FRAME_MANUAL);
            // 실제 rPrevFrame으로 점프
            ReplayDrawer.renderReplayFrame(ReplayState.rPrevFrame, ReplayDrawer.JUMP_FRAME_MANUAL);
            CanvasController.applyReplayCanvasToDrawModeCanvas();
        }

        // addundo data에서 캔버스 비트맵 데이터가 변경되기 전, rdatabuffer 비어있을때 넣어줘야함
        public static function applyDeepUndo():void
        {
            const fs:FileStream = new FileStream();
            fs.open(FileManager.replayDataFilePath, FileMode.UPDATE);
            fs.position = ReplayState.rFileLastBytePosition;
            fs.truncate(); // 데이터 위에 짤라주고
            fs.close();
            // 썸네일 이미지도 날려줌
            const rNowFrameSave:Number = ReplayState.rNowFrame;
            ReplayFileCache.truncateCacheImagesAfterFrame(rNowFrameSave);
            ReplayState.setRFileDataTotalFrame(rNowFrameSave);
            ReplayController.updateTotalFrameAndReplayMaxSpeedFor10Sec(rNowFrameSave);
            ReplayController.resetReplayTime();
            UndoManager.resetUndoState(true);
            ReplayDrawer.rReplayFOFOCursor.visible = true; // 대칭된 커서 위치를 갱신해주려고 임시로 켜줌
            // checkMirrorCanvasReplayMirror();
            CanvasController.canvasInfoBox.setMirror(CanvasController.mirrorON);
            ReplayDrawCommands.setFirstRCursorPosCurrent();
            ReplayDrawer.rReplayFOFOCursor.visible = false;
            CanvasController.canvasNavigatorBox.updateImage();
            UndoManager.exitDeepUndo();
        }

        public static function undo():void
        {
            if (ReplayState.isGeneratingCacheImages())
            {
                InputManager.removeKeyRepeatEvents(null);
                return;
            }
            if (UndoManager.isDeepUndoEnabled)
            {
                if (ReplayState.rNowFrame > 0)
                {
                    ReplayController.moveToPreviousStep();
                    CanvasController.applyReplayCanvasToDrawModeCanvas();
                    Utils.showDisplayTargetAndFadeOut(ReplayDrawer.rReplayFOFOCursor, 1.0, 0.3);
                }
            }
            else
            {
                UndoManager.undoDataIndex--;
                if (UndoManager.undoDataIndex < -1)
                {
                    FileManager.isFileAlreadySaved = false;
                    UndoManager.undoDataIndex = -1;
                    UndoManager.enterDeepUndo();
                    Utils.showDisplayTargetAndFadeOut(ReplayDrawer.rReplayFOFOCursor, 1.0, 0.3);
                }
                else if (ReplayState.rMemoryData.length > 0)
                {
                    FileManager.isFileAlreadySaved = false;
                    UndoManager.isDeleteUndoDataPending = true;
                    updateCanvasStateAfterUndo();
                    Utils.showDisplayTargetAndFadeOut(ReplayDrawer.rReplayFOFOCursor, 1.0, 0.3);
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
            ReplayDrawer.updateReplayCanvasFromUndoRefData(undoRefData, undoIndexSave);

            //드로우 모드 캔버스 bmpd갱신하고 크기 정보 갱신
            CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData,ReplayDrawer.rCanvasLayer1BitmapData,CanvasController.canvasLayer1Bitmap)
            CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData,ReplayDrawer.rCanvasLayer2BitmapData,CanvasController.canvasLayer2Bitmap)
            CanvasController.syncDrawModeCanvasSizeToReplayMode(CanvasController.canvasLayer1BitmapData.width,CanvasController.canvasLayer1BitmapData.height);

            // 앞 뒤 데이터가 캔버스 원점 이동 되었을때 반대방향으로 다시 움직여줌
            const movedRegPos:Point = UndoManager.getHowCanvasMoveAfterUndoOrRedo(undoIndexSave, redoFlag);
            if (movedRegPos)
            {
                CanvasController.canvasAnchorPoint.x += movedRegPos.x * CanvasController.canvasZoomMultipler;
                CanvasController.canvasAnchorPoint.y += movedRegPos.y * CanvasController.canvasZoomMultipler;
                ReferenceLayerController.updateRefLayerBitmapPos(movedRegPos);
            }

            // updateMirrorStateDrawModeNotSameRreplayMirrorState 이 함수 직전에 해줘야 나중에 제대로 대칭된 좌표가 됨
            UndoManager.showRCursorOnUndo(UndoManager.undoDataIndex);

            ReplayController.preserveDrawMirrorStateAfterReplayCopy();
            CanvasController.canvasNavigatorBox.updateImage();
            CanvasController.setCanvasBGColorDrawMode(ReplayState.RCANVAS_BG_COLOR);
            CanvasController.updateCanvasPanelColorAndSize();

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
