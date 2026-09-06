package main_module
{
    import flash.display.DisplayObject;
    import flash.events.MouseEvent;
    import flash.geom.Point;

    public class DragInteraction
    {
        public static var dragInteractionFuncs:Object = {onDragStart: null, onMouseMove: null, onMouseUp: null};

        public static function startDragInteraction(onDragStartFunc:Function, onMouseMoveFunc:Function, onMouseUpFunc:Function):void
        {
            const main:Main = Main._instance;
            main.isMouseDragging = true;

            function onMouseUp(e:MouseEvent):void
            {
                main.isMouseDragging = false;
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
                main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);

                onMouseUpFunc();
            }

            function onMouseMove(e:MouseEvent):void
            {
                onMouseMoveFunc();
            }

            onDragStartFunc();

            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        }

        public static function startBoxDrag(target:DisplayObject):void
        {
            const main:Main = Main._instance;
            const clickPos:Point = new Point(main.stage.mouseX, main.stage.mouseY);

            function onDragStart():void
            {
                Utils.setAsTopChild(target);
            }

            function onMouseMove():void
            {
                target.x = Math.floor(target.x + main.stage.mouseX - clickPos.x);
                target.y = Math.floor(target.y + main.stage.mouseY - clickPos.y);

                clickPos.x = main.stage.mouseX;
                clickPos.y = main.stage.mouseY;
            }

            function onMouseUp():void
            {
                main.keepBoxInsideViewPort(target);
            }

            startDragInteraction(onDragStart, onMouseMove, onMouseUp);
        }
    }
}
