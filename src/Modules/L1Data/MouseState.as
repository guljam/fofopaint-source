package Modules.L1Data
{
    import flash.events.MouseEvent;

    // 마우스 버튼 눌림 상태의 단일 소유자
    // 층: L1 데이터 - 마우스 버튼 눌림 상태의 단일 소유자
    public class MouseState
    {
        // 마우스 왼쪽 버튼을 눌렀을 때 펜 크기 미리보기 커서의 예약된 색 확인을 취소해야 한다는 보고
        public static var onMouseLeftDownFunc:Function;

        public static var isLeftDown:Boolean = false;
        public static var isRightDown:Boolean = false;
        public static var isMiddleDown:Boolean = false;
        public static var isClickBlocked:Boolean = false; // 알탭 하고나서 창활성화 되면 일정시간동안 작동하지 않게함

        // mouseUp으로 끝나는 진행 중인 상호작용(획 등)의 끝내기 함수 등록부 (owner -> Function)
        // mouseUp을 받을 수 없을때(alt+tab 등) 이벤트 객체 없이 직접 호출해서 정상 종료시키기 위함
        private static const activeDrags:Object = {};

        // 드래그 중인지는 등록부로만 판단함 (beginDrag ~ endDrag 사이). 따로 올리고 내리는 플래그를 두지 않음
        // 툴을 계속 클릭한채로 움직이면 topmenu의 힌트가 안켜지도록 하는 등에 사용
        public static function get isDragging():Boolean
        {
            for (var owner:String in activeDrags)
            {
                return true;
            }

            return false;
        }

        public static function beginDrag(owner:String, finishFunc:Function):void
        {
            activeDrags[owner] = finishFunc;
        }

        public static function endDrag(owner:String):void
        {
            delete activeDrags[owner];
        }

        // 등록된(아직 mouseUp으로 끝나지 않은) 드래그/획 개수
        public static function get activeDragCount():int
        {
            var count:int = 0;
            for (var owner:String in activeDrags)
            {
                count++;
            }
            return count;
        }

        // finishFunc는 이벤트 인자 없이 호출되므로 e를 쓰지 않는 함수만 등록해야함
        public static function finishAllDrags():void
        {
            const owners:Array = [];
            for (var owner:String in activeDrags)
            {
                owners.push(owner);
            }

            for each (owner in owners)
            {
                const finishFunc:Function = activeDrags[owner];
                delete activeDrags[owner];

                if (finishFunc !== null)
                {
                    // 하나가 실패해도 나머지 정리와 호출한 쪽(onWindowDeactivate)의 후속 처리는 계속되어야함
                    try
                    {
                        finishFunc();
                    }
                    catch (err:Error)
                    {
                        trace("MouseState.finishAllDrags: '" + owner + "' failed: " + err.message);
                    }
                }
            }
        }

        public static function onLeftDown():void
        {
            isLeftDown = true;
            if (onMouseLeftDownFunc != null) onMouseLeftDownFunc();
        }

        public static function onLeftUp():void
        {
            isLeftDown = false;
        }

        public static function onRightDown():void
        {
            isRightDown = true;
        }

        public static function onRightUp():void
        {
            isRightDown = false;
        }

        public static function onMiddleDown():void
        {
            isMiddleDown = true;
        }

        // stage 리스너로 직접 등록되므로 이벤트 인자를 받아야함 (컴파일러가 리스너 시그니처를 검사하지 않음)
        public static function onMiddleUp(e:MouseEvent = null):void
        {
            isMiddleDown = false;
        }

        // mouseUp을 놓쳤을때(창 밖에서 떼기, alt+tab 등) 마우스를 움직이면 복구함
        // 버튼 상태만 고치면 드래그 리스너와 등록이 남아서 isDragging이 계속 켜져있으므로 드래그도 정상 종료시킴
        public static function onMouseMoveHeal(e:MouseEvent):void
        {
            if (isLeftDown && !e.buttonDown)
            {
                onLeftUp();

                // 휠 클릭(HandTool) 등 다른 버튼으로 진행 중인 드래그는 건드리지 않음
                if (!isRightDown && !isMiddleDown)
                {
                    finishAllDrags();
                }
            }
        }

        // 창 비활성화, 마우스가 창을 벗어남 등 mouseUp을 기다릴 수 없을때 호출
        // 드래그 등록부는 건드리지 않음 (필요하면 호출하는 쪽에서 finishAllDrags를 먼저 호출)
        public static function resetAll():void
        {
            isLeftDown = false;
            isRightDown = false;
            isMiddleDown = false;
        }
    }
}
