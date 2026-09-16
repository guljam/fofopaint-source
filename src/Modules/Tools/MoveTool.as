package Modules.Tools
{
    import Modules.CanvasController;
    import flash.events.MouseEvent;
    import Modules.Utils;
    import flash.display.BitmapData;
    import flash.geom.Matrix;
    import Modules.UndoManager;
    import flash.geom.Rectangle;
    import Modules.ReplayController;
    import flash.geom.Point;

    public class MoveTool
    {
        public static var main:Main;

        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static var getMovedPos:Function;

        private static function onMouseUpMoveTool(e:MouseEvent):void
        {
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveMovetool);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpMoveTool);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpMoveTool);

            CanvasController.isMouseDragging = false;
            CanvasController.isPenSizeCursorInvisible = false;
            getMovedPos = null;

            var tmpbmpd:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);

            const movex:Number = Math.floor(CanvasController.canvasLayer1Bitmap.x);
            const movey:Number = Math.floor(CanvasController.canvasLayer1Bitmap.y);
            const movex1:Number = Math.floor(CanvasController.canvasLayer2Bitmap.x);
            const movey1:Number = Math.floor(CanvasController.canvasLayer2Bitmap.y);

            var movedMat:Matrix = new Matrix();

            if (UndoManager.isDeepUndoEnabled)
                UndoManager.applyDeepUndo();

            // 최종적으로 움직인 거리를 실제로 비트맵 데이터 조작
            if (CanvasController.checkedLayer === 0)
            {
                if (CanvasController.canvasLayer1Bitmap.visible)
                {
                    movedMat.translate(movex, movey);
                    tmpbmpd.draw(CanvasController.canvasLayer1BitmapData, movedMat);
                    CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, tmpbmpd, CanvasController.canvasLayer1Bitmap);
                }

                if (CanvasController.canvasLayer2Bitmap.visible)
                {
                    movedMat = new Matrix();
                    movedMat.translate(movex1, movey1);
                    tmpbmpd.fillRect(new Rectangle(0, 0, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT), 0);
                    tmpbmpd.draw(CanvasController.canvasLayer2BitmapData, movedMat);
                    CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, tmpbmpd, CanvasController.canvasLayer2Bitmap);
                }
            }
            else if (CanvasController.checkedLayer === 1)
            {
                movedMat.translate(movex, movey);
                tmpbmpd.draw(CanvasController.canvasLayer1BitmapData, movedMat);
                CanvasController.canvasLayer1BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer1BitmapData, tmpbmpd, CanvasController.canvasLayer1Bitmap);
            }
            else if (CanvasController.checkedLayer === 2)
            {
                movedMat = new Matrix();
                movedMat.translate(movex1, movey1);
                tmpbmpd.fillRect(new Rectangle(0, 0, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT), 0);
                tmpbmpd.draw(CanvasController.canvasLayer2BitmapData, movedMat);
                CanvasController.canvasLayer2BitmapData = CanvasController.updateBitmapData(CanvasController.canvasLayer2BitmapData, tmpbmpd, CanvasController.canvasLayer2Bitmap);
            }

            tmpbmpd.dispose();
            tmpbmpd = null;

            CanvasController.canvasLayer1Bitmap.x = 0;
            CanvasController.canvasLayer1Bitmap.y = 0;
            CanvasController.canvasLayer2Bitmap.x = 0;
            CanvasController.canvasLayer2Bitmap.y = 0;

            if (LassoTool.isLassoToolStarted === false)
            {
                var command:String = "move";

                if (CanvasController.checkedLayer === 1)
                {
                    command = "move1";
                    ReplayController.rDataBuffer.push([command, movex, movey]);
                }
                else if (CanvasController.checkedLayer === 2)
                {
                    command = "move2";
                    ReplayController.rDataBuffer.push([command, movex1, movey1]);
                }
                else
                {
                    if (!CanvasController.canvasLayer2Bitmap.visible)
                    {
                        command = "move1";
                        ReplayController.rDataBuffer.push([command, movex, movey]);
                    }
                    else if (!CanvasController.canvasLayer1Bitmap.visible)
                    {
                        command = "move2";
                        ReplayController.rDataBuffer.push([command, movex1, movey1]);
                    }
                    else
                    {
                        ReplayController.rDataBuffer.push([command, movex, movey]);
                    }
                }

                if (ReplayController.hasLastRDataCommand(command))
                    UndoManager.addUndoData.addContinue();
                else
                    UndoManager.addUndoData.addNew();
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
                return;

            getMovedPos = Utils.updateImagePosMouseDrag(CanvasController.canvasLayer1Bitmap, CanvasController.canvasAnchorPoint.rotation);
            CanvasController.isPenSizeCursorInvisible = true;

            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveMovetool);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpMoveTool);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpMoveTool);
        };
    }
}
