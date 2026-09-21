package Modules
{
    import flash.display.DisplayObject;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.events.Event;

    public class DragInteraction
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static var dragInteractionMouseMoveFunc:Function;
        private static var dragInteractionMouseUpFunc:Function;
        private static var dragInteractionMouseEventStarted:Boolean = false;

        public static function handleMouseMoveDragInteraction(event:Event):void
        {
            dragInteractionMouseMoveFunc();
        }
        public static function handleMouseUpDragInteraction(event:Event):void
        {
            dragInteractionMouseEventStarted = false;
            CanvasController.isMouseDragging = false;
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, handleMouseUpDragInteraction);
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, handleMouseMoveDragInteraction);

            dragInteractionMouseUpFunc();
            dragInteractionMouseUpFunc = null;
            dragInteractionMouseMoveFunc = null;
        }

        public static function startDragInteraction(onDragStartFunc:Function, onMouseMoveFunc:Function, onMouseUpFunc:Function):void
        {
            CanvasController.isMouseDragging = true;
            dragInteractionMouseUpFunc = onMouseUpFunc;
            dragInteractionMouseMoveFunc = onMouseMoveFunc;
            onDragStartFunc();

            if (dragInteractionMouseEventStarted === false)
            {
                dragInteractionMouseEventStarted = true;
                main.stage.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMoveDragInteraction);
                main.stage.addEventListener(MouseEvent.MOUSE_UP, handleMouseUpDragInteraction);
            }
        }

        public static function startBoxDrag(target:DisplayObject):void
        {
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
                MainUIController.keepBoxInsideViewPort(target);
            }

            startDragInteraction(onDragStart, onMouseMove, onMouseUp);
        }
    }
}
