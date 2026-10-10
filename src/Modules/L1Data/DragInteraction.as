package Modules.L1Data
{

    import flash.display.DisplayObject;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;

    // 층: L1 데이터 - 드래그 박스 상호작용 시작과 이동·종료 처리
    public class DragInteraction
    {
        // 박스 드래그가 끝나 박스를 화면 안으로 되돌려야 한다는 보고 (인자: 드래그한 박스)
        public static var onDragEndedFunc:Function;

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
            AppContext.stage.removeEventListener(MouseEvent.MOUSE_UP, handleMouseUpDragInteraction);
            AppContext.stage.removeEventListener(MouseEvent.MOUSE_MOVE, handleMouseMoveDragInteraction);

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
                AppContext.stage.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMoveDragInteraction);
                AppContext.stage.addEventListener(MouseEvent.MOUSE_UP, handleMouseUpDragInteraction, false, InputPriority.DEFAULT);
            }
        }

        public static function startDragBox(target:DisplayObject):void
        {
            const clickPos:Point = new Point(AppContext.stage.mouseX, AppContext.stage.mouseY);

            function onDragStart():void
            {
                Utils.setAsTopChild(target);
            }

            function onMouseMove():void
            {
                target.x = Math.floor(target.x + AppContext.stage.mouseX - clickPos.x);
                target.y = Math.floor(target.y + AppContext.stage.mouseY - clickPos.y);

                clickPos.x = AppContext.stage.mouseX;
                clickPos.y = AppContext.stage.mouseY;
            }

            function onMouseUp():void
            {
                if (onDragEndedFunc != null) onDragEndedFunc(target);
            }

            start(onDragStart, onMouseMove, onMouseUp);
        }
    }
}
