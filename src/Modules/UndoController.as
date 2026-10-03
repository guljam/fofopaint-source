package Modules
{
    import Modules.DrawEngine.CanvasView;
    import Modules.DrawEngine.DrawCanvas;
    import Modules.UIEngine.CanvasNavigator;
    import Modules.InputManager.InputManager;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Point;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayDrawCommands;
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.ReplayEngine.ReplayFileCache;
    import Modules.ReplayEngine.ReplayState;
    import Modules.ReplayEngine.ReplayTimeline;

    // undo / redo / 딥 언두로 위치를 옮기고 그 위치의 캔버스를 다시 그려줌
    // 메모리 undo 데이터와 undo 위치 자체는 UndoHistory가 가지고 있음
    public class UndoController
    {
        // 딥언도 (Deep Undo)
        private static var _isDeepUndoEnabled:Boolean = false;
        private static var deepUndoBeforeSuspend:Boolean = false; // 리플레이 켜줄때 딥 플래그를 꺼줘서 여기다가 미리 저장해둠

        public static function get isDeepUndoEnabled():Boolean
        {
            return _isDeepUndoEnabled;
        }

        // 리플레이 모드에 들어갈때 딥 언두를 잠시 꺼둠
        public static function suspendDeepUndo():void
        {
            deepUndoBeforeSuspend = _isDeepUndoEnabled;
            _isDeepUndoEnabled = false;
        }

        // 리플레이 모드에서 나올때 꺼두었던 딥 언두를 되돌림, 리플레이 모드에서 exitDeepUndo 했으면 꺼진 채로 둠
        public static function resumeDeepUndo():void
        {
            _isDeepUndoEnabled = deepUndoBeforeSuspend;
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
                    HintController.hideMouseHint();
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
            _isDeepUndoEnabled = false;
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
            if (_isDeepUndoEnabled)
            {
                ReplayController.moveToNextStep();
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
                    FileManager.isFileAlreadySaved = false;
                    UndoHistory.setUndoDataIndex(lastIndex);
                }
                else
                {
                    UndoHistory.setUndoDataIndex(UndoHistory.undoDataIndex + 1);
                    FileManager.isFileAlreadySaved = false;
                    updateCanvasState(true);
                    Utils.showDisplayTargetAndFadeOut(ReplayDrawer.rReplayFOFOCursor, 1.0, 0.3);
                }
            }
        }

        public static function undoToIndex(index:int):void
        {
            UndoHistory.setUndoDataIndex(index);
            FileManager.isFileAlreadySaved = false;
            FileManager.enableNewFileButton();
            updateCanvasStateAfterUndo();
        }

        public static function exitDeepUndo():void
        {
            _isDeepUndoEnabled = false;
            deepUndoBeforeSuspend = false;
            ReplayState.rMemoryDataReadON = true;
            showRCursorOnUndo(-1);
            ReplayFileCache.clearRFrameTempCache();
        }

        private static function enterDeepUndo():void
        {
            _isDeepUndoEnabled = true;
            ReplayState.rMemoryDataReadON = false;
            ReplayController.updateTotalFrameAndReplayMaxSpeedFor10Sec(ReplayState.getTotalFrame());
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
            fs.open(AppStateManager.replayDataFilePath, FileMode.UPDATE);
            fs.position = ReplayState.rFileLastBytePosition;
            fs.truncate(); // 데이터 위에 짤라주고
            fs.close();
            ReplayTimeline.truncateFile(ReplayState.rFileLastBytePosition, ReplayState.rNowFrame);
            // 썸네일 이미지도 날려줌
            const rNowFrameSave:Number = ReplayState.rNowFrame;
            ReplayFileCache.truncateCacheImagesAfterFrame(rNowFrameSave);
            ReplayState.setRFileDataTotalFrame(rNowFrameSave);
            ReplayController.updateTotalFrameAndReplayMaxSpeedFor10Sec(rNowFrameSave);
            ReplayController.resetReplayTime();
            resetUndoState(true);
            ReplayDrawer.rReplayFOFOCursor.visible = true; // 대칭된 커서 위치를 갱신해주려고 임시로 켜줌
            UIController.canvasInfoBox.setMirror(DrawCanvas.mirrorON);
            ReplayDrawCommands.setFirstRCursorPosCurrent();
            ReplayDrawer.rReplayFOFOCursor.visible = false;
            CanvasNavigator.box.updateImage();
            exitDeepUndo();
        }

        public static function undo():void
        {
            if (ReplayState.isGeneratingCacheImages())
            {
                InputManager.removeKeyRepeatEvents(null);
                return;
            }
            if (_isDeepUndoEnabled)
            {
                if (ReplayState.rNowFrame > 0)
                {
                    ReplayController.moveToPreviousStep();
                    DrawCanvas.applyReplayCanvasToDrawModeCanvas();
                    Utils.showDisplayTargetAndFadeOut(ReplayDrawer.rReplayFOFOCursor, 1.0, 0.3);
                }
            }
            else
            {
                if (UndoHistory.undoDataIndex - 1 < -1)
                {
                    FileManager.isFileAlreadySaved = false;
                    UndoHistory.setUndoDataIndex(-1);
                    enterDeepUndo();
                    Utils.showDisplayTargetAndFadeOut(ReplayDrawer.rReplayFOFOCursor, 1.0, 0.3);
                }
                else
                {
                    UndoHistory.setUndoDataIndex(UndoHistory.undoDataIndex - 1);

                    if (ReplayState.rMemoryData.length > 0)
                    {
                        FileManager.isFileAlreadySaved = false;
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
                ReferenceLayerController.updateRefLayerBitmapPos(movedRegPos);
            }

            // updateMirrorStateDrawModeNotSameRreplayMirrorState 이 함수 직전에 해줘야 나중에 제대로 대칭된 좌표가 됨
            showRCursorOnUndo(undoIndexSave);

            ReplayController.preserveDrawMirrorStateAfterReplayCopy();
            CanvasNavigator.box.updateImage();
            DrawCanvas.setCanvasBGColorDrawMode(ReplayState.RCANVAS_BG_COLOR);
            CanvasView.updateCanvasPanelColorAndSize();

            // canvas window 상태 갱신
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
                ImageViewWindow.updateCanvasWindowBitmapSize();
            }

            CanvasNavigator.updateCursor();
            FileManager.enableNewFileButton();
        }
    }
}
