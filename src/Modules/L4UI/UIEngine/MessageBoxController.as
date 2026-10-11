package Modules.L4UI.UIEngine
{
    import Modules.L1Data.AppContext;
    import Modules.L1Data.FOFOTimer;
    import Modules.L1Data.InputPriority;
    import Modules.L1Data.MouseState;
    import Modules.L1Data.UIEngine.UITheme;
    import Modules.L1Data.Utils;
    import Modules.L2Engine.DrawEngine.HandDrawnLine;

    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import flash.utils.getTimer;

    // 좌하단에 쌓이는 상태(녹색)/오류(빨간색) 메시지 상자. 지우기는 왼쪽/오른쪽 클릭, 판정은 이벤트의 stageX/stageY로 함
    // 층: L4 UI - 좌하단 메시지 상자 쌓기, 타이머, 입력 가로채기, 배치
    public final class MessageBoxController
    {
        public static const MAX_COUNT:int = 6;
        public static const DEFAULT_DURATION:Number = 5.0;
        private static const HIT_MARGIN:Number = 5; // 판정 영역: 상자 + 상하좌우 이만큼
        private static const BOTTOM_GAP:Number = 5; // 하단 힌트 바 위 간격
        private static const MESSAGE_GAP:Number = 2; // 메시지 사이 간격
        private static const MAX_TEXT_LENGTH:int = 200;
        private static const LEFT:Number = 2; // 하단 힌트의 x와 같게
        private static const TIMER_NAME:String = "messageBoxTimer";

        // 버튼 번호: 0 = 왼쪽, 1 = 오른쪽, 2 = 가운데(휠)
        private static const DOWN_TYPES:Array = [MouseEvent.MOUSE_DOWN, MouseEvent.RIGHT_MOUSE_DOWN, MouseEvent.MIDDLE_MOUSE_DOWN];
        private static const UP_TYPES:Array = [MouseEvent.MOUSE_UP, MouseEvent.RIGHT_MOUSE_UP, MouseEvent.MIDDLE_MOUSE_UP];
        private static const CLICK_TYPES:Array = [MouseEvent.CLICK, MouseEvent.RIGHT_CLICK, MouseEvent.MIDDLE_CLICK];

        private static const container:Sprite = new Sprite();
        private static const highlight:Shape = new Shape(); // HintController의 hintHighlightBox와 따로 씀
        private static const boxes:Vector.<MessageBox> = new Vector.<MessageBox>();
        private static const entries:Array = []; // {isError, raw, count, expire}. 앞이 가장 오래된 것, 맨 뒤가 맨 아래(최신)
        private static var isInitialized:Boolean = false;

        // 가로챈 DOWN 뒤에 가로채야 할 UP/CLICK/DOUBLE_CLICK. 버튼별로 켜고, 그 이벤트를 처리한 뒤 끔
        private static const upPending:Vector.<Boolean> = new <Boolean>[false, false, false];
        private static const clickPending:Vector.<Boolean> = new <Boolean>[false, false, false];
        private static var doubleClickPending:Boolean = false;

        private static const downAttached:Vector.<Boolean> = new <Boolean>[false, false, false];
        private static const upAttached:Vector.<Boolean> = new <Boolean>[false, false, false];
        private static const clickAttached:Vector.<Boolean> = new <Boolean>[false, false, false];
        private static var doubleClickAttached:Boolean = false;
        private static var moveAttached:Boolean = false;

        // 컨테이너(메시지 상자 + 하이라이트)를 stage에 올림. stage 접근은 여기서만 함 (static 초기화 순서 때문)
        public static function initialize():void
        {
            const fontSize:Number = Number(HintController.mouseHint.hintText.defaultTextFormat.size);

            container.mouseEnabled = false;
            container.mouseChildren = false;
            for (var i:int = 0; i < MAX_COUNT; i++)
            {
                const box:MessageBox = new MessageBox(fontSize);
                box.visible = false;
                boxes.push(box);
                container.addChild(box);
            }
            highlight.visible = false;
            container.addChild(highlight);

            AppContext.stage.addChild(container);
            isInitialized = true;
        }

        public static function showStatus(str:String, duration:Number = DEFAULT_DURATION):void
        {
            add(false, str, duration);
        }

        public static function showError(str:String, duration:Number = DEFAULT_DURATION):void
        {
            add(true, str, duration);
        }

        // 창 크기, UI 배율이 바뀔 때
        public static function updateLayout():void
        {
            render();
        }

        // 테마가 바뀔 때
        public static function updateColor():void
        {
            render();
        }

        public static function getCount():int
        {
            return entries.length;
        }

        // index 0이 가장 오래된(맨 위) 메시지
        public static function getDisplayText(index:int):String
        {
            return getDisplayString(entries[index]);
        }

        public static function getBox(index:int):MessageBox
        {
            return boxes[index];
        }

        public static function getHighlight():Shape
        {
            return highlight;
        }

        // 호출할 때마다 셋 중 하나를 무작위로 실행: 성공 메시지 하나 / 실패 메시지 하나 / 같은 메시지를 1~3초 간격으로 2~5개 (성공 또는 실패)
        public static function testCallMessageBox():void
        {
            const kind:int = int(Math.random() * 3);
            const id:int = int(Math.random() * 1000);
            if (kind === 0)
            {
                showStatus("Test status " + id);
            }
            else if (kind === 1)
            {
                showError("Test error " + id);
            }
            else
            {
                const isError:Boolean = Math.random() < 0.5;
                testRepeatMessage(isError, (isError ? "Test repeated error " : "Test repeated status ") + id, 2 + int(Math.random() * 4));
            }
        }

        private static function testRepeatMessage(isError:Boolean, str:String, remaining:int):void
        {
            add(isError, str, DEFAULT_DURATION);
            if (remaining > 1)
            {
                FOFOTimer.add(1.0 + Math.random() * 2.0, false, testRepeatMessage, [isError, str, remaining - 1]);
            }
        }

        private static function getDisplayString(entry:Object):String
        {
            const raw:String = entry.raw;
            const text:String = raw.length > MAX_TEXT_LENGTH ? raw.substr(0, MAX_TEXT_LENGTH) + "..." : raw;
            return entry.count >= 2 ? text + " (" + entry.count + ")" : text;
        }

        private static function add(isError:Boolean, str:String, duration:Number):void
        {
            if (!isInitialized || str === null || str === "")
            {
                return;
            }

            const expire:int = getTimer() + int(duration * 1000);
            var entry:Object = null;
            for (var i:int = 0; i < entries.length; i++)
            {
                if (entries[i].isError === isError && entries[i].raw === str)
                {
                    entry = entries.splice(i, 1)[0];
                    entry.count++;
                    entry.expire = expire;
                    break;
                }
            }

            if (entry === null)
            {
                entry = {isError: isError, raw: str, count: 1, expire: expire};
            }
            entries.push(entry);
            if (entries.length > MAX_COUNT)
            {
                entries.shift();
            }

            render();
            Utils.setAsTopChild(container);
            if (HintController.mouseHint.visible)
            {
                Utils.setAsTopChild(HintController.mouseHint);
            }

            if (!FOFOTimer.hasTimer(TIMER_NAME))
            {
                FOFOTimer.addByName(TIMER_NAME, 0.0, true, onTimer);
            }
            syncListeners();
        }

        private static function onTimer():Boolean
        {
            const now:int = getTimer();
            var removed:Boolean = false;
            for (var i:int = entries.length - 1; i >= 0; i--)
            {
                if (entries[i].expire - now <= 0)
                {
                    entries.splice(i, 1);
                    removed = true;
                }
            }

            if (removed)
            {
                render();
                syncListeners();
            }
            return entries.length > 0;
        }

        private static function removeAt(index:int):void
        {
            entries.splice(index, 1);
            if (entries.length === 0)
            {
                FOFOTimer.remove(TIMER_NAME);
            }
            render();
            syncListeners();
        }

        // 맨 아래(최신) 상자의 아랫변을 하단 바 위에 맞추고, 위로 쌓음. 높이가 달라도 아랫변 기준
        private static function render():void
        {
            if (!isInitialized)
            {
                return;
            }

            const scale:Number = UITheme.getUIScale();
            var bottom:Number = AppContext.stage.stageHeight - (HintController.BOTTOM_BAR_HEIGHT + BOTTOM_GAP) * scale;

            for (var i:int = boxes.length - 1; i >= 0; i--)
            {
                const box:MessageBox = boxes[i];
                if (i >= entries.length)
                {
                    box.visible = false;
                    continue;
                }

                const entry:Object = entries[i];
                box.visible = true;
                box.scaleX = scale;
                box.scaleY = scale;
                box.setText(getDisplayString(entry));
                box.setStyle(entry.isError ? UITheme.getMessageErrorBGColor() : UITheme.getMessageStatusBGColor(), UITheme.messageBGAlpha, UITheme.messageTextColor);
                box.x = 0;
                box.y = 0;

                const bounds:Rectangle = box.getBounds(container); // 컨테이너는 (0,0), 배율 1이라 stage 좌표와 같음
                box.x = Math.round(LEFT * scale - bounds.left);
                box.y = Math.round(bottom - bounds.bottom);
                bottom = box.y + bounds.top - MESSAGE_GAP * scale;
            }

            updateHighlight(AppContext.stage.mouseX, AppContext.stage.mouseY);
        }

        // margin 0이면 상자 자체, HIT_MARGIN이면 클릭 판정 영역
        private static function getHitRect(index:int, margin:Number):Rectangle
        {
            const rect:Rectangle = boxes[index].getBounds(AppContext.stage);
            const scaledMargin:Number = margin * UITheme.getUIScale();
            rect.inflate(scaledMargin, scaledMargin);
            return rect;
        }

        // 겹치는 곳은 아래쪽(최신) 메시지가 이김
        private static function hitIndex(x:Number, y:Number, margin:Number):int
        {
            for (var i:int = entries.length - 1; i >= 0; i--)
            {
                if (getHitRect(i, margin).contains(x, y))
                {
                    return i;
                }
            }
            return -1;
        }

        private static function updateHighlight(x:Number, y:Number):void
        {
            // 하이라이트는 상자 자체만 감지하고 그림 (여백은 클릭 판정에만 씀)
            const index:int = (MouseState.isLeftDown || MouseState.isRightDown) ? -1 : hitIndex(x, y, 0);
            highlight.graphics.clear();
            if (index < 0)
            {
                highlight.visible = false;
                return;
            }

            const rect:Rectangle = getHitRect(index, 0);
            highlight.x = rect.x;
            highlight.y = rect.y;
            HandDrawnLine.drawRect(highlight.graphics, 2, UITheme.getHintHightlightColor(), 1.0, 0, 0, rect.width, rect.height);
            highlight.visible = true;
        }

        // 메시지가 보일 때만 DOWN/MOVE 리스너를 붙이고, UP/CLICK은 가로채야 할 것이 남아 있는 동안만 붙임
        private static function syncListeners():void
        {
            const hasMessage:Boolean = entries.length > 0;
            setMoveListener(hasMessage);
            for (var b:int = 0; b < 3; b++)
            {
                const needDoubleClick:Boolean = (b === 0 && doubleClickPending);
                downAttached[b] = setListener(downAttached[b], hasMessage || upPending[b] || clickPending[b] || needDoubleClick, DOWN_TYPES[b], onDown);
                upAttached[b] = setListener(upAttached[b], upPending[b], UP_TYPES[b], onUp);
                clickAttached[b] = setListener(clickAttached[b], clickPending[b], CLICK_TYPES[b], onClick);
            }
            doubleClickAttached = setListener(doubleClickAttached, doubleClickPending, MouseEvent.DOUBLE_CLICK, onDoubleClick);
        }

        private static function setListener(attached:Boolean, need:Boolean, type:String, listener:Function):Boolean
        {
            if (need && !attached)
            {
                AppContext.stage.addEventListener(type, listener, true, InputPriority.MESSAGE_BOX);
            }
            else if (!need && attached)
            {
                AppContext.stage.removeEventListener(type, listener, true);
            }
            return need;
        }

        // 하이라이트용. 다른 이동 처리를 막지 않도록 전파는 건드리지 않음
        private static function setMoveListener(need:Boolean):void
        {
            if (need && !moveAttached)
            {
                AppContext.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, true);
            }
            else if (!need && moveAttached)
            {
                AppContext.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, true);
            }
            moveAttached = need;
        }

        private static function onMouseMove(e:MouseEvent):void
        {
            updateHighlight(e.stageX, e.stageY);
        }

        private static function onDown(e:MouseEvent):void
        {
            const button:int = DOWN_TYPES.indexOf(e.type);

            // 이전 클릭에서 CLICK이 오지 않아 남은 것이 새 클릭을 막지 않게 먼저 지움
            upPending[button] = false;
            clickPending[button] = false;
            if (button === 0)
            {
                doubleClickPending = false;
            }

            const index:int = hitIndex(e.stageX, e.stageY, HIT_MARGIN);
            if (index >= 0)
            {
                e.stopImmediatePropagation();
                upPending[button] = true;
                clickPending[button] = true;
                if (button === 0)
                {
                    doubleClickPending = true;
                }

                if (button <= 1) // 왼쪽, 오른쪽 클릭은 그 메시지를 지움 (휠은 가로채기만)
                {
                    removeAt(index);
                    return;
                }
            }
            syncListeners();
        }

        private static function onUp(e:MouseEvent):void
        {
            const button:int = UP_TYPES.indexOf(e.type);
            e.stopImmediatePropagation();
            upPending[button] = false;
            syncListeners();
        }

        private static function onClick(e:MouseEvent):void
        {
            const button:int = CLICK_TYPES.indexOf(e.type);
            e.stopImmediatePropagation();
            clickPending[button] = false;
            syncListeners();
        }

        private static function onDoubleClick(e:MouseEvent):void
        {
            e.stopImmediatePropagation();
            doubleClickPending = false;
            syncListeners();
        }
    }
}
