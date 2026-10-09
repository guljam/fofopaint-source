package Modules
{

    import flash.display.DisplayObject;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import Modules.L4UI.UIEngine.UIController;

    // 층: L1 데이터 - 드래그 박스 상호작용 시작과 이동·종료 처리
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
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, handleMouseUpDragInteraction);
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, handleMouseMoveDragInteraction);

            if (dragInteractionMouseUpFunc !== null)
            {
                dragInteractionMouseUpFunc();
            }
            dragInteractionMouseUpFunc = null;
            dragInteractionMouseMoveFunc = null;
        }

        public static function start(onDragStartFunc:Function, onMouseMoveFunc:Function, onMouseUpFunc:Function):void
        {
            // mouseUp을 놓쳐서 이전 드래그가 열려있으면 먼저 마무리함 (콜백 슬롯이 하나라서 덮어쓰면 이전 드래그의 mouseUp 처리가 사라짐)
            if (dragInteractionMouseEventStarted)
            {
                finishDragInteraction();
            }

            dragInteractionMouseUpFunc = onMouseUpFunc;
            dragInteractionMouseMoveFunc = onMouseMoveFunc;
            // onDragStartFunc 안에서도 isDragging이 켜져 있도록 먼저 등록함
            MouseState.beginDrag(DRAG_OWNER, finishDragInteraction);
            onDragStartFunc();

            if (dragInteractionMouseEventStarted === false)
            {
                dragInteractionMouseEventStarted = true;
                main.stage.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMoveDragInteraction);
                main.stage.addEventListener(MouseEvent.MOUSE_UP, handleMouseUpDragInteraction, false, InputPriority.DEFAULT);
            }
        }

        public static function startDragBox(target:DisplayObject):void
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
                UIController.keepBoxInsideViewPort(target);
            }

            start(onDragStart, onMouseMove, onMouseUp);
        }
    }
}
