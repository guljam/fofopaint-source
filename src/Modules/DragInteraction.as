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
        private static const DRAG_OWNER:String = "dragInteraction";

        public static function handleMouseMoveDragInteraction(event:Event):void
        {
            dragInteractionMouseMoveFunc();
        }
        public static function handleMouseUpDragInteraction(event:Event):void
        {
            finishDragInteraction();
        }

        // 이벤트 객체를 쓰지 않음. mouseUp을 못받는 경우(alt+tab 등)에도 MouseState.finishAllDrags가 직접 호출함
        private static function finishDragInteraction():void
        {
            dragInteractionMouseEventStarted = false;
            MouseState.endDrag(DRAG_OWNER);
            CanvasController.isMouseDragging = false;
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, handleMouseUpDragInteraction);
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, handleMouseMoveDragInteraction);

            if (dragInteractionMouseUpFunc !== null)
            {
                dragInteractionMouseUpFunc();
            }
            dragInteractionMouseUpFunc = null;
            dragInteractionMouseMoveFunc = null;
        }

        public static function startDragInteraction(onDragStartFunc:Function, onMouseMoveFunc:Function, onMouseUpFunc:Function):void
        {
            // mouseUp을 놓쳐서 이전 드래그가 열려있으면 먼저 마무리함 (콜백 슬롯이 하나라서 덮어쓰면 이전 드래그의 mouseUp 처리가 사라짐)
            if (dragInteractionMouseEventStarted)
            {
                finishDragInteraction();
            }

            CanvasController.isMouseDragging = true;
            dragInteractionMouseUpFunc = onMouseUpFunc;
            dragInteractionMouseMoveFunc = onMouseMoveFunc;
            onDragStartFunc();

            if (dragInteractionMouseEventStarted === false)
            {
                dragInteractionMouseEventStarted = true;
                main.stage.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMoveDragInteraction);
                main.stage.addEventListener(MouseEvent.MOUSE_UP, handleMouseUpDragInteraction, false, InputPriority.DEFAULT);
                MouseState.beginDrag(DRAG_OWNER, finishDragInteraction);
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
