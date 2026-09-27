package Modules.Tools
{
    import Modules.CanvasController;
    import flash.events.MouseEvent;
    import Modules.Utils;
    import flash.display.BitmapData;
    import flash.geom.Matrix;
    import Modules.UndoManager;
    import flash.geom.Rectangle;
    import flash.geom.Point;
    import Modules.PenSizePreviewCursor;
    import Modules.UndoController;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayState;

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
            CanvasController.canvasLayer1Bitmap.x = 0;
            CanvasController.canvasLayer1Bitmap.y = 0;
            CanvasController.canvasLayer2Bitmap.x = 0;
            CanvasController.canvasLayer2Bitmap.y = 0;
        }

        private static function onMouseUpMoveTool(e:MouseEvent):void
        {
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveMovetool);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpMoveTool);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpMoveTool);

            CanvasController.isMouseDragging = false;
            PenSizePreviewCursor.setCursorInVisibleFlag(false);

            getMovedPos = null;

            const movex:Number = Math.floor(CanvasController.canvasLayer1Bitmap.x);
            const movey:Number = Math.floor(CanvasController.canvasLayer1Bitmap.y);
            const movex1:Number = Math.floor(CanvasController.canvasLayer2Bitmap.x);
            const movey1:Number = Math.floor(CanvasController.canvasLayer2Bitmap.y);

            // onMouseMoveMovetool 과 같은 기준으로 "실제로 움직인 레이어"를 판단
            const checked:int = CanvasController.checkedLayer;
            const layer1Moved:Boolean = (checked === 1 || (checked === 0 && CanvasController.canvasLayer1Bitmap.visible))
                && (movex !== 0.0 || movey !== 0.0);
            const layer2Moved:Boolean = (checked === 2 || (checked === 0 && CanvasController.canvasLayer2Bitmap.visible))
                && (movex1 !== 0.0 || movey1 !== 0.0);

            if (!layer1Moved && !layer2Moved)
            {
                // B2: 1px 미만 이동으로 남은 소수점 오프셋도 원위치
                resetLayerBitmapPos();
                return;
            }

            var tmpbmpd:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
            const rect:Rectangle = new Rectangle(0, 0, CanvasController.canvasLayer1BitmapData.width, CanvasController.canvasLayer1BitmapData.height);
            var movedMat:Matrix = new Matrix();

            if (UndoManager.isDeepUndoEnabled)
            {
                UndoManager.applyDeepUndo();
            }

            // 최종적으로 움직인 거리를 실제로 비트맵 데이터 조작
            if (CanvasController.checkedLayer === 0)
            {
                if (CanvasController.canvasLayer1Bitmap.visible)
                {
                    movedMat.translate(movex, movey);
                    tmpbmpd.draw(CanvasController.canvasLayer1BitmapData, movedMat);
                    CanvasController.copyPixels(CanvasController.canvasLayer1BitmapData, tmpbmpd);
                }

                if (CanvasController.canvasLayer2Bitmap.visible)
                {
                    movedMat = new Matrix();
                    movedMat.translate(movex1, movey1);
                    tmpbmpd.fillRect(rect, 0);
                    tmpbmpd.draw(CanvasController.canvasLayer2BitmapData, movedMat);
                    CanvasController.copyPixels(CanvasController.canvasLayer2BitmapData, tmpbmpd);
                }
            }
            else if (CanvasController.checkedLayer === 1)
            {
                movedMat.translate(movex, movey);
                tmpbmpd.draw(CanvasController.canvasLayer1BitmapData, movedMat);
                CanvasController.copyPixels(CanvasController.canvasLayer1BitmapData, tmpbmpd);
            }
            else if (CanvasController.checkedLayer === 2)
            {

                movedMat = new Matrix();
                movedMat.translate(movex1, movey1);
                tmpbmpd.fillRect(new Rectangle(0, 0, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT), 0);
                tmpbmpd.draw(CanvasController.canvasLayer2BitmapData, movedMat);
                CanvasController.copyPixels(CanvasController.canvasLayer2BitmapData, tmpbmpd);
            }

            tmpbmpd.dispose();
            tmpbmpd = null;

            resetLayerBitmapPos();

            if (LassoTool._isLassoToolStarted === false)
            {
                var command:String = "move";

                if (CanvasController.checkedLayer === 1)
                {
                    command = "move1";
                    ReplayState.rMemoryDataBuffer.push([command, movex, movey]);
                }
                else if (CanvasController.checkedLayer === 2)
                {
                    command = "move2";
                    ReplayState.rMemoryDataBuffer.push([command, movex1, movey1]);
                }
                else
                {
                    if (!CanvasController.canvasLayer2Bitmap.visible)
                    {
                        command = "move1";
                        ReplayState.rMemoryDataBuffer.push([command, movex, movey]);
                    }
                    else if (!CanvasController.canvasLayer1Bitmap.visible)
                    {
                        command = "move2";
                        ReplayState.rMemoryDataBuffer.push([command, movex1, movey1]);
                    }
                    else
                    {
                        ReplayState.rMemoryDataBuffer.push([command, movex, movey]);
                    }
                }

                UndoController.addNew();
            }
        }

        private static function onMouseMoveMovetool(e:MouseEvent):void
        {
            const pos:Point = getMovedPos();

            if (CanvasController.checkedLayer === 0)
            {
                if (CanvasController.canvasLayer1Bitmap.visible)
                {
                    CanvasController.canvasLayer1Bitmap.x = pos.x;
                    CanvasController.canvasLayer1Bitmap.y = pos.y;
                }

                if (CanvasController.canvasLayer2Bitmap.visible)
                {
                    CanvasController.canvasLayer2Bitmap.x = pos.x;
                    CanvasController.canvasLayer2Bitmap.y = pos.y;
                }
            }
            else if (CanvasController.checkedLayer === 1)
            {
                CanvasController.canvasLayer1Bitmap.x = pos.x;
                CanvasController.canvasLayer1Bitmap.y = pos.y;
            }
            else if (CanvasController.checkedLayer === 2)
            {
                CanvasController.canvasLayer2Bitmap.x = pos.x;
                CanvasController.canvasLayer2Bitmap.y = pos.y;
            }
        }

        public static function start():void
        {
            if (CanvasController.isAllLayerInvisible())
            {
                return;
            }

            getMovedPos = Utils.updateImagePosMouseDrag(CanvasController.canvasLayer1Bitmap, CanvasController.canvasAnchorPoint.rotation);
            PenSizePreviewCursor.setCursorInVisibleFlag(true);

            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveMovetool);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpMoveTool);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpMoveTool);
        };
    }
}
