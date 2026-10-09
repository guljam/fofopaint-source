package Modules.Tools
{
    import Modules.InputPriority;
    import Modules.MouseState;
    import flash.events.MouseEvent;
    import flash.utils.getTimer;
    import Modules.Utils;
    import flash.display.BitmapData;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.geom.Point;
    import Modules.ReplayEngine.ReplayState;
    import Modules.L3Feature.Tools.LassoTool;
    import Modules.L5App.ReplayEngine.ReplayController;
    import Modules.L3Feature.UndoController;
    import Modules.L1Data.UndoHistory;
    import Modules.L4UI.PenSizePreviewCursor;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L2Engine.DrawEngine.CanvasLayers;

    // 층: L3 기능 - 이동 툴
    public class MoveTool
    {
        public static var main:Main;

        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static var getMovedPos:Function;

        private static function resetLayerBitmapPos():void
        {
            DrawCanvas.canvasLayer1Bitmap.x = 0;
            DrawCanvas.canvasLayer1Bitmap.y = 0;
            DrawCanvas.canvasLayer2Bitmap.x = 0;
            DrawCanvas.canvasLayer2Bitmap.y = 0;
        }

        private static const DRAG_OWNER:String = "moveTool";

        private static function onMouseUpMoveTool(e:MouseEvent):void
        {
            finishMoveTool();
        }

        // 이벤트 객체를 쓰지 않음. mouseUp을 못받는 경우(alt+tab 등)에도 MouseState.finishAllDrags가 직접 호출함
        private static function finishMoveTool():void
        {
            MouseState.endDrag(DRAG_OWNER);
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveMovetool);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpMoveTool);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpMoveTool);

            PenSizePreviewCursor.setCursorInVisibleFlag(false);

            getMovedPos = null;

            const movex:Number = Math.floor(DrawCanvas.canvasLayer1Bitmap.x);
            const movey:Number = Math.floor(DrawCanvas.canvasLayer1Bitmap.y);
            const movex1:Number = Math.floor(DrawCanvas.canvasLayer2Bitmap.x);
            const movey1:Number = Math.floor(DrawCanvas.canvasLayer2Bitmap.y);

            // onMouseMoveMovetool 과 같은 기준으로 "실제로 움직인 레이어"를 판단
            const checked:int = CanvasLayers.checkedLayer;
            const layer1Moved:Boolean = (checked === 1 || (checked === 0 && DrawCanvas.canvasLayer1Bitmap.visible))
                && (movex !== 0.0 || movey !== 0.0);
            const layer2Moved:Boolean = (checked === 2 || (checked === 0 && DrawCanvas.canvasLayer2Bitmap.visible))
                && (movex1 !== 0.0 || movey1 !== 0.0);

            if (!layer1Moved && !layer2Moved)
            {
                // B2: 1px 미만 이동으로 남은 소수점 오프셋도 원위치
                resetLayerBitmapPos();
                return;
            }

            var tmpbmpd:BitmapData = new BitmapData(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, true, 0);
            const rect:Rectangle = new Rectangle(0, 0, DrawCanvas.canvasLayer1BitmapData.width, DrawCanvas.canvasLayer1BitmapData.height);
            var movedMat:Matrix = new Matrix();

            if (UndoController.isDeepUndoEnabled)
            {
                UndoController.applyDeepUndo();
            }

            // 최종적으로 움직인 거리를 실제로 비트맵 데이터 조작
            if (CanvasLayers.checkedLayer === 0)
            {
                if (DrawCanvas.canvasLayer1Bitmap.visible)
                {
                    movedMat.translate(movex, movey);
                    tmpbmpd.draw(DrawCanvas.canvasLayer1BitmapData, movedMat);
                    DrawCanvas.copyPixels(DrawCanvas.canvasLayer1BitmapData, tmpbmpd);
                }

                if (DrawCanvas.canvasLayer2Bitmap.visible)
                {
                    movedMat = new Matrix();
                    movedMat.translate(movex1, movey1);
                    tmpbmpd.fillRect(rect, 0);
                    tmpbmpd.draw(DrawCanvas.canvasLayer2BitmapData, movedMat);
                    DrawCanvas.copyPixels(DrawCanvas.canvasLayer2BitmapData, tmpbmpd);
                }
            }
            else if (CanvasLayers.checkedLayer === 1)
            {
                movedMat.translate(movex, movey);
                tmpbmpd.draw(DrawCanvas.canvasLayer1BitmapData, movedMat);
                DrawCanvas.copyPixels(DrawCanvas.canvasLayer1BitmapData, tmpbmpd);
            }
            else if (CanvasLayers.checkedLayer === 2)
            {

                movedMat = new Matrix();
                movedMat.translate(movex1, movey1);
                tmpbmpd.fillRect(new Rectangle(0, 0, DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT), 0);
                tmpbmpd.draw(DrawCanvas.canvasLayer2BitmapData, movedMat);
                DrawCanvas.copyPixels(DrawCanvas.canvasLayer2BitmapData, tmpbmpd);
            }

            tmpbmpd.dispose();
            tmpbmpd = null;

            resetLayerBitmapPos();

            if (LassoTool.isStarted === false)
            {
                var command:String = "move";

                if (CanvasLayers.checkedLayer === 1)
                {
                    command = "move1";
                    ReplayState.rMemoryDataBuffer.push(ReplayState.stampTimingSheetToolCommand([command, movex, movey], moveStartStamp));
                }
                else if (CanvasLayers.checkedLayer === 2)
                {
                    command = "move2";
                    ReplayState.rMemoryDataBuffer.push(ReplayState.stampTimingSheetToolCommand([command, movex1, movey1], moveStartStamp));
                }
                else
                {
                    if (!DrawCanvas.canvasLayer2Bitmap.visible)
                    {
                        command = "move1";
                        ReplayState.rMemoryDataBuffer.push(ReplayState.stampTimingSheetToolCommand([command, movex, movey], moveStartStamp));
                    }
                    else if (!DrawCanvas.canvasLayer1Bitmap.visible)
                    {
                        command = "move2";
                        ReplayState.rMemoryDataBuffer.push(ReplayState.stampTimingSheetToolCommand([command, movex1, movey1], moveStartStamp));
                    }
                    else
                    {
                        ReplayState.rMemoryDataBuffer.push(ReplayState.stampTimingSheetToolCommand([command, movex, movey], moveStartStamp));
                    }
                }

                UndoHistory.addNew();
            }
        }

        private static function onMouseMoveMovetool(e:MouseEvent):void
        {
            const pos:Point = getMovedPos();

            if (CanvasLayers.checkedLayer === 0)
            {
                if (DrawCanvas.canvasLayer1Bitmap.visible)
                {
                    DrawCanvas.canvasLayer1Bitmap.x = pos.x;
                    DrawCanvas.canvasLayer1Bitmap.y = pos.y;
                }

                if (DrawCanvas.canvasLayer2Bitmap.visible)
                {
                    DrawCanvas.canvasLayer2Bitmap.x = pos.x;
                    DrawCanvas.canvasLayer2Bitmap.y = pos.y;
                }
            }
            else if (CanvasLayers.checkedLayer === 1)
            {
                DrawCanvas.canvasLayer1Bitmap.x = pos.x;
                DrawCanvas.canvasLayer1Bitmap.y = pos.y;
            }
            else if (CanvasLayers.checkedLayer === 2)
            {
                DrawCanvas.canvasLayer2Bitmap.x = pos.x;
                DrawCanvas.canvasLayer2Bitmap.y = pos.y;
            }
        }

        private static var moveStartStamp:int = 0; // 이동을 시작(마우스를 누른) getTimer 값, 놓을때 타이밍 시트에 연출 시간으로 기록함

        public static function start():void
        {
            if (CanvasLayers.isAllLayerInvisible())
            {
                return;
            }

            moveStartStamp = getTimer();
            getMovedPos = Utils.updateImagePosMouseDrag(DrawCanvas.canvasLayer1Bitmap, CanvasView.canvasAnchorPoint.rotation);
            PenSizePreviewCursor.setCursorInVisibleFlag(true);

            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveMovetool);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpMoveTool, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpMoveTool, false, InputPriority.DEFAULT);
            MouseState.beginDrag(DRAG_OWNER, finishMoveTool);
        };
    }
}
