package Modules.L3Feature
{
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Point;
    import Modules.L1Data.KeyState;
    import Modules.L2Engine.ReplayEngine.ReplayClock;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.L2Engine.ReplayEngine.ReplayFileCache;
    import Modules.L2Engine.ReplayEngine.TimingSheetFile;
    import Modules.L1Data.AppDataPaths;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L2Engine.ReplayEngine.ReplayDrawCommands;
    import Modules.L2Engine.UndoHistory;
    import Modules.L2Engine.ReplayEngine.ReplayState;
    import Modules.L1Data.Utils;

    // undo / redo / 딥 언두로 위치를 옮기고 그 위치의 캔버스를 다시 그려줌
    // 메모리 undo 데이터와 undo 위치 자체는 UndoHistory가 가지고 있음
    // 층: L3 기능 - undo / redo / 딥 언두로 위치를 옮기고 캔버스를 다시 그림
    public class UndoController
    {
        // 마우스 옆 힌트를 숨겨야 한다는 보고
        public static var onMouseHintHideFunc:Function;
        // 딥 언두 구간에서 리플레이를 다음 단계로 옮겨야 한다는 보고
        public static var onReplayStepNextFunc:Function;
        // 딥 언두 구간에서 리플레이를 이전 단계로 옮겨야 한다는 보고
        public static var onReplayStepPreviousFunc:Function;
        // undo/redo로 캔버스가 바뀌어 파일이 저장된 상태가 아니게 됐다는 보고
        public static var onFileChangedFunc:Function;
        // undo/redo 뒤 새 파일 버튼을 켜야 한다는 보고
        public static var onNewFileButtonNeededFunc:Function;
        // 리플레이 총 프레임이 바뀌어 최대 배속을 다시 계산해야 한다는 보고 (인자: 총 프레임)
        public static var onReplayTotalFrameChangedFunc:Function;
        // 리플레이 시간 표시를 처음으로 되돌려야 한다는 보고
        public static var onReplayTimeResetFunc:Function;
        // 미러 상태가 바뀌어 캔버스 정보 박스의 미러 표시를 바꿔야 한다는 보고 (인자: 미러 여부)
        public static var onMirrorChangedFunc:Function;
        // 캔버스 이미지가 바뀌어 네비게이터 이미지를 갱신해야 한다는 보고
        public static var onNavigatorImageChangedFunc:Function;
        // 캔버스가 움직인 만큼 참조 레이어 이미지 위치를 옮겨야 한다는 보고 (인자: 옮긴 거리)
        public static var onRefLayerMovedFunc:Function;
        // 리플레이 캔버스를 드로우 캔버스에 복사한 뒤 드로우 모드의 미러 상태를 맞춰야 한다는 보고
        public static var onReplayCanvasAppliedFunc:Function;
        // 이미지 보기 창이 열려 있으면 이미지와 크기를 갱신해야 한다는 보고
        public static var onCanvasWindowChangedFunc:Function;
        // 네비게이터의 보이는 영역 커서를 갱신해야 한다는 보고
        public static var onNavigatorCursorChangedFunc:Function;

        // 딥언도 (Deep Undo)
        private static var deepUndoBeforeSuspend:Boolean = false; // 리플레이 켜줄때 딥 플래그를 꺼줘서 여기다가 미리 저장해둠

        // 리플레이 모드에 들어갈때 딥 언두를 잠시 꺼둠
        public static function suspendDeepUndo():void
        {
            deepUndoBeforeSuspend = UndoHistory.isDeepUndoEnabled;
            UndoHistory.isDeepUndoEnabled = false;
        }

        // 리플레이 모드에서 나올때 꺼두었던 딥 언두를 되돌림, 리플레이 모드에서 exitDeepUndo 했으면 꺼진 채로 둠
        public static function resumeDeepUndo():void
        {
            UndoHistory.isDeepUndoEnabled = deepUndoBeforeSuspend;
        }

        private static function showRCursorOnUndo(undoIndex:int):void
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
                    if (onMouseHintHideFunc != null) onMouseHintHideFunc();
                }
            }
            else
            {
                ReplayDrawCommands.updateRCursorPos();
            }
        }

        public static function resetUndoState(fromReplayMode:Boolean = false):void
        {
            UndoHistory.reset(fromReplayMode);
            ReplayDrawer.rReplayFOFOCursor.visible = false;
            UndoHistory.isDeepUndoEnabled = false;
        }

        private static function getHowCanvasMoveAfterUndoOrRedo(index:int, redoFlag:Boolean):Point
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
            if (UndoHistory.isDeepUndoEnabled)
            {
                if (onReplayStepNextFunc != null) onReplayStepNextFunc();
                DrawCanvas.applyReplayCanvasToDrawModeCanvas();
                Utils.showDisplayTargetAndFadeOut(ReplayDrawer.rReplayFOFOCursor, 1.0, 0.3);

                if (ReplayState.rNowFrame >= ReplayState.getRFileDataTotalFrame())
                {
                    exitDeepUndo();
                    UndoHistory.setUndoDataIndex(-1);
                }
            }
            else
            {
                const lastIndex:int = ReplayState.rMemoryData.length - 1;

                if (UndoHistory.undoDataIndex + 1 > lastIndex)
                {
                    if (onFileChangedFunc != null) onFileChangedFunc();
                    UndoHistory.setUndoDataIndex(lastIndex);
                }
                else
                {
                    UndoHistory.setUndoDataIndex(UndoHistory.undoDataIndex + 1);
                    if (onFileChangedFunc != null) onFileChangedFunc();
                    updateCanvasState(true);
                    Utils.showDisplayTargetAndFadeOut(ReplayDrawer.rReplayFOFOCursor, 1.0, 0.3);
                }
            }
        }

        public static function undoToIndex(index:int):void
        {
            UndoHistory.setUndoDataIndex(index);
            if (onFileChangedFunc != null) onFileChangedFunc();
            if (onNewFileButtonNeededFunc != null) onNewFileButtonNeededFunc();
            updateCanvasStateAfterUndo();
        }

        public static function exitDeepUndo():void
        {
            UndoHistory.isDeepUndoEnabled = false;
            deepUndoBeforeSuspend = false;
            ReplayState.rMemoryDataReadON = true;
            showRCursorOnUndo(-1);
            ReplayFileCache.clearRFrameTempCache();
        }

        private static function enterDeepUndo():void
        {
            UndoHistory.isDeepUndoEnabled = true;
            ReplayState.rMemoryDataReadON = false;
            if (onReplayTotalFrameChangedFunc != null) onReplayTotalFrameChangedFunc(ReplayState.getTotalFrame());
            // 이미지 캐시 해주고 rPrevFrame 갱신해주고
            ReplayDrawer.renderReplayFrame(ReplayState.getRFileDataTotalFrame() - 1, ReplayDrawer.JUMP_FRAME_MANUAL);
            // 실제 rPrevFrame으로 점프
            ReplayDrawer.renderReplayFrame(ReplayState.rPrevFrame, ReplayDrawer.JUMP_FRAME_MANUAL);
            DrawCanvas.applyReplayCanvasToDrawModeCanvas();
        }

        // addundo data에서 캔버스 비트맵 데이터가 변경되기 전, rdatabuffer 비어있을때 넣어줘야함
        public static function applyDeepUndo():void
        {
            const fs:FileStream = new FileStream();
            fs.open(AppDataPaths.replayDataFilePath, FileMode.UPDATE);
            fs.position = ReplayState.rFileLastBytePosition;
            fs.truncate(); // 데이터 위에 짤라주고
            fs.close();
            ReplayDrawer.commandWindow.dispose(); // repdata가 바뀌었으니 미리 읽은 묶음은 버림
            // 썸네일 이미지도 날려줌
            const rNowFrameSave:Number = ReplayState.rNowFrame;
            ReplayFileCache.truncateCacheImagesAfterFrame(rNowFrameSave);
            ReplayState.setRFileDataTotalFrame(rNowFrameSave);
            TimingSheetFile.truncateAfter(rNowFrameSave);
            ReplayClock.truncateFileIndex(rNowFrameSave);
            if (onReplayTotalFrameChangedFunc != null) onReplayTotalFrameChangedFunc(rNowFrameSave);
            if (onReplayTimeResetFunc != null) onReplayTimeResetFunc();
            resetUndoState(true);
            ReplayDrawer.rReplayFOFOCursor.visible = true; // 대칭된 커서 위치를 갱신해주려고 임시로 켜줌
            if (onMirrorChangedFunc != null) onMirrorChangedFunc(DrawCanvas.mirrorON);
            ReplayDrawCommands.setFirstRCursorPosCurrent();
            ReplayDrawer.rReplayFOFOCursor.visible = false;
            if (onNavigatorImageChangedFunc != null) onNavigatorImageChangedFunc();
            exitDeepUndo();
        }

        public static function undo():void
        {
            if (ReplayState.isGeneratingCacheImages())
            {
                KeyState.removeKeyRepeatEvents(null);
                return;
            }
            if (UndoHistory.isDeepUndoEnabled)
            {
                if (ReplayState.rNowFrame > 0)
                {
                    if (onReplayStepPreviousFunc != null) onReplayStepPreviousFunc();
                    DrawCanvas.applyReplayCanvasToDrawModeCanvas();
                    Utils.showDisplayTargetAndFadeOut(ReplayDrawer.rReplayFOFOCursor, 1.0, 0.3);
                }
            }
            else
            {
                if (UndoHistory.undoDataIndex - 1 < -1)
                {
                    if (onFileChangedFunc != null) onFileChangedFunc();
                    UndoHistory.setUndoDataIndex(-1);
                    enterDeepUndo();
                    Utils.showDisplayTargetAndFadeOut(ReplayDrawer.rReplayFOFOCursor, 1.0, 0.3);
                }
                else
                {
                    UndoHistory.setUndoDataIndex(UndoHistory.undoDataIndex - 1);

                    if (ReplayState.rMemoryData.length > 0)
                    {
                        if (onFileChangedFunc != null) onFileChangedFunc();
                        updateCanvasStateAfterUndo();
                        Utils.showDisplayTargetAndFadeOut(ReplayDrawer.rReplayFOFOCursor, 1.0, 0.3);
                    }
                }
            }
        }

        public static function updateCanvasStateAfterUndo():void
        {
            updateCanvasState(false);
        }

        private static function updateCanvasState(redoFlag:Boolean):void
        {
            const undoRefData:Array = UndoHistory.getUndoBaseImage();
            const undoIndexSave:int = UndoHistory.undoDataIndex;

            // 리플레이 캔버스 먼저 갱신
            ReplayDrawer.updateReplayCanvasFromUndoRefData(undoRefData, undoIndexSave);

            //드로우 모드 캔버스 bmpd갱신하고 크기 정보 갱신
            DrawCanvas.canvasLayer1BitmapData = DrawCanvas.updateBitmapData(DrawCanvas.canvasLayer1BitmapData,ReplayDrawer.rCanvasLayer1BitmapData,DrawCanvas.canvasLayer1Bitmap)
            DrawCanvas.canvasLayer2BitmapData = DrawCanvas.updateBitmapData(DrawCanvas.canvasLayer2BitmapData,ReplayDrawer.rCanvasLayer2BitmapData,DrawCanvas.canvasLayer2Bitmap)
            DrawCanvas.syncDrawModeCanvasSizeToReplayMode(DrawCanvas.canvasLayer1BitmapData.width,DrawCanvas.canvasLayer1BitmapData.height);

            // 앞 뒤 데이터가 캔버스 원점 이동 되었을때 반대방향으로 다시 움직여줌
            const movedRegPos:Point = getHowCanvasMoveAfterUndoOrRedo(undoIndexSave, redoFlag);
            if (movedRegPos)
            {
                CanvasView.canvasAnchorPoint.x += movedRegPos.x * CanvasView.canvasZoomMultiplier;
                CanvasView.canvasAnchorPoint.y += movedRegPos.y * CanvasView.canvasZoomMultiplier;
                if (onRefLayerMovedFunc != null) onRefLayerMovedFunc(movedRegPos);
            }

            // updateMirrorStateDrawModeNotSameRreplayMirrorState 이 함수 직전에 해줘야 나중에 제대로 대칭된 좌표가 됨
            showRCursorOnUndo(undoIndexSave);

            if (onReplayCanvasAppliedFunc != null) onReplayCanvasAppliedFunc();
            if (onNavigatorImageChangedFunc != null) onNavigatorImageChangedFunc();
            DrawCanvas.setCanvasBGColorDrawMode(ReplayState.RCANVAS_BG_COLOR);
            CanvasView.updateCanvasPanelColorAndSize();

            // canvas window 상태 갱신
            if (onCanvasWindowChangedFunc != null) onCanvasWindowChangedFunc();

            if (onNavigatorCursorChangedFunc != null) onNavigatorCursorChangedFunc();
            if (onNewFileButtonNeededFunc != null) onNewFileButtonNeededFunc();
        }

        // 배경색 변경을 undo 데이터에 기록함 (직전 명령이 배경색이면 이어 붙임)
        public static function addUndoBGColorData(color:uint):void
        {
            if (ReplayState.hasLastRMemoryDataCommand("bgColor"))
            {
                ReplayState.rMemoryDataBuffer.push(["bgColor", color]);
                ReplayState.updateLastRMemoryDataCommand("bgColor");
                UndoHistory.addContinue();
            }
            else
            {
                if (UndoHistory.isDeepUndoEnabled)
                {
                    UndoController.applyDeepUndo();
                }

                ReplayState.rMemoryDataBuffer.push(["bgColor", color]);
                UndoHistory.addNew();
            }
        }

    }
}
