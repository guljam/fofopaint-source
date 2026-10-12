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
    import flash.display.Stage;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import flash.utils.getTimer;

    // 좌하단에 쌓이는 상태(녹색)/오류(빨간색) 메시지 상자 관리. 최신 메시지가 맨 아래, 최대 6개, 정해진 시간이 지나면 사라짐
    // 메시지 위 왼쪽 클릭: 그 메시지를 지움. 오른쪽·휠 클릭: 지우지 않고 가로채기만 함 (아래 캔버스·UI로 전달하지 않음)
    // 클릭 판정은 상자 + 상하좌우 MESSAGE_CLICK_MARGIN, 파란 하이라이트는 상자 자체만
    // 층: L4 UI - 좌하단 메시지 상자 쌓기, 만료 타이머, 클릭 가로채기, 배치
    public final class MessageBoxController
    {
        public static const MAX_MESSAGE_COUNT:int = 6;
        public static const DEFAULT_MESSAGE_DURATION:Number = 5.0;
        private static const MESSAGE_CLICK_MARGIN:Number = 5; // 클릭 판정 영역: 상자 + 상하좌우 이만큼
        private static const GAP_ABOVE_BOTTOM_BAR:Number = 5; // 하단 힌트 바와 맨 아래 메시지 사이
        private static const GAP_BETWEEN_MESSAGES:Number = 2;
        private static const MAX_MESSAGE_LENGTH:int = 200; // 넘으면 잘라서 "..."을 붙임
        private static const MESSAGE_LEFT_X:Number = 2; // 하단 힌트의 x와 같게
        private static const MESSAGE_EXPIRE_TIMER:String = "messageExpireTimer";

        private static const messageBoxContainer:Sprite = new Sprite();
        private static const messageHighlightBox:Shape = new Shape(); // HintController의 hintHighlightBox와 따로 씀
        private static var messageHighlightDrawnWidth:Number = NaN; // messageHighlightBox에 마지막으로 그린 크기와 색. 같으면 다시 그리지 않고 위치만 옮김
        private static var messageHighlightDrawnHeight:Number = NaN;
        private static var messageHighlightDrawnColor:uint = 0;
        private static const messageBoxes:Vector.<MessageBox> = new Vector.<MessageBox>(); // 미리 만든 상자를 재사용, messageBoxes[i]가 messages[i]를 표시
        private static const messages:Array = []; // {isError, text, repeatCount, expireTime}. 앞이 가장 오래된(맨 위) 것, 맨 뒤가 최신(맨 아래)
        private static var isInitialized:Boolean = false;

        // 메시지 위에서 DOWN을 가로챈 버튼은 뒤따르는 UP/CLICK도 가로챔
        // (DOWN만 막으면 MouseState에 눌림 없이 뗌만 기록되고, 아래 버튼이 UP/CLICK에 반응함)
        // 같은 버튼의 다음 DOWN에서 다시 판정함
        private static var isLeftClickIntercepted:Boolean = false;
        private static var isRightClickIntercepted:Boolean = false;
        private static var isMiddleClickIntercepted:Boolean = false;

        // 메시지 상자들을 만들어 stage에 올리고 마우스 이벤트를 붙임. stage 접근은 여기서만 함 (static 초기화 순서 때문)
        public static function initialize():void
        {
            const fontSize:Number = Number(HintController.mouseHint.hintText.defaultTextFormat.size);

            messageBoxContainer.mouseEnabled = false;
            messageBoxContainer.mouseChildren = false;
            for (var i:int = 0; i < MAX_MESSAGE_COUNT; i++)
            {
                const messageBox:MessageBox = new MessageBox(fontSize);
                messageBox.visible = false;
                messageBoxes.push(messageBox);
                messageBoxContainer.addChild(messageBox);
            }
            messageHighlightBox.visible = false;
            messageBoxContainer.addChild(messageHighlightBox);

            AppContext.stage.addChild(messageBoxContainer);
            addMessageBoxMouseEvents();
            isInitialized = true;
        }

        // 캔버스·UI 입력보다 먼저 받도록 캡처 단계, 가장 높은 우선순위로 붙임. 메시지가 없으면 각 핸들러는 바로 끝남
        private static function addMessageBoxMouseEvents():void
        {
            const stage:Stage = AppContext.stage;
            stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownMessageBox, true, InputPriority.MESSAGE_BOX);
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpOrClickMessageBox, true, InputPriority.MESSAGE_BOX);
            stage.addEventListener(MouseEvent.CLICK, onMouseUpOrClickMessageBox, true, InputPriority.MESSAGE_BOX);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownMessageBox, true, InputPriority.MESSAGE_BOX);
            stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpOrClickMessageBox, true, InputPriority.MESSAGE_BOX);
            stage.addEventListener(MouseEvent.RIGHT_CLICK, onRightMouseUpOrClickMessageBox, true, InputPriority.MESSAGE_BOX);
            stage.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, onMiddleMouseDownMessageBox, true, InputPriority.MESSAGE_BOX);
            stage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMiddleMouseUpOrClickMessageBox, true, InputPriority.MESSAGE_BOX);
            stage.addEventListener(MouseEvent.MIDDLE_CLICK, onMiddleMouseUpOrClickMessageBox, true, InputPriority.MESSAGE_BOX);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveMessageBox, true); // 하이라이트용, 전파는 건드리지 않음
        }

        public static function showStatusMessage(text:String, duration:Number = DEFAULT_MESSAGE_DURATION):void
        {
            addMessage(false, text, duration);
        }

        public static function showErrorMessage(text:String, duration:Number = DEFAULT_MESSAGE_DURATION):void
        {
            addMessage(true, text, duration);
        }

        // 메시지 상자의 글자, 색, 위치를 지금 메시지 목록대로 다시 맞춤. 창 크기, UI 배율, 테마가 바뀔 때도 부름
        public static function updateMessageBoxes():void
        {
            if (!isInitialized)
            {
                return;
            }

            const scale:Number = UITheme.getUIScale();
            var bottom:Number = AppContext.stage.stageHeight - (HintController.BOTTOM_BAR_HEIGHT + GAP_ABOVE_BOTTOM_BAR) * scale;

            // 맨 아래(최신) 상자의 아랫변을 하단 바 위에 맞추고 위로 쌓음. 높이가 달라도 아랫변 기준
            for (var i:int = messageBoxes.length - 1; i >= 0; i--)
            {
                const messageBox:MessageBox = messageBoxes[i];
                if (i >= messages.length)
                {
                    messageBox.visible = false;
                    continue;
                }

                const message:Object = messages[i];
                messageBox.visible = true;
                messageBox.scaleX = scale;
                messageBox.scaleY = scale;
                messageBox.setMessageText(getMessageDisplayText(message));
                messageBox.setMessageColors(message.isError ? UITheme.getMessageErrorBGColor() : UITheme.getMessageStatusBGColor(), UITheme.messageBGAlpha, UITheme.messageTextColor);
                messageBox.x = 0;
                messageBox.y = 0;

                const bounds:Rectangle = messageBox.getBounds(messageBoxContainer); // 컨테이너는 (0,0), 배율 1이라 stage 좌표와 같음
                messageBox.x = Math.round(MESSAGE_LEFT_X * scale - bounds.left);
                messageBox.y = Math.round(bottom - bounds.bottom);
                bottom = messageBox.y + bounds.top - GAP_BETWEEN_MESSAGES * scale;
            }

            updateMessageHighlightBox(AppContext.stage.mouseX, AppContext.stage.mouseY);
        }

        public static function getMessageCount():int
        {
            return messages.length;
        }

        // 화면에 보이는 문장. index 0이 가장 오래된(맨 위) 메시지
        public static function getMessageText(index:int):String
        {
            return getMessageDisplayText(messages[index]);
        }

        public static function getMessageBox(index:int):MessageBox
        {
            return messageBoxes[index];
        }

        public static function getMessageHighlightBox():Shape
        {
            return messageHighlightBox;
        }

        // 호출할 때마다 셋 중 하나를 무작위로 실행: 성공 메시지 하나 / 실패 메시지 하나 / 같은 메시지를 1~3초 간격으로 2~5개 (성공 또는 실패)
        public static function testCallMessageBox():void
        {
            const kind:int = int(Math.random() * 3);
            const id:int = int(Math.random() * 1000);
            if (kind === 0)
            {
                showStatusMessage("Test status " + id);
            }
            else if (kind === 1)
            {
                showErrorMessage("Test error " + id);
            }
            else
            {
                const isError:Boolean = Math.random() < 0.5;
                showRepeatedTestMessage(isError, (isError ? "Test repeated error " : "Test repeated status ") + id, 2 + int(Math.random() * 4));
            }
        }

        private static function showRepeatedTestMessage(isError:Boolean, text:String, remainingCount:int):void
        {
            addMessage(isError, text, DEFAULT_MESSAGE_DURATION);
            if (remainingCount > 1)
            {
                FOFOTimer.add(1.0 + Math.random() * 2.0, false, showRepeatedTestMessage, [isError, text, remainingCount - 1]);
            }
        }

        // 200자를 넘으면 자르고, 같은 문장이 2번 이상이면 뒤에 " (횟수)"를 붙임 (자른 뒤에 붙여서 횟수가 항상 보이게)
        private static function getMessageDisplayText(message:Object):String
        {
            const text:String = message.text;
            const cutText:String = text.length > MAX_MESSAGE_LENGTH ? text.substr(0, MAX_MESSAGE_LENGTH) + "..." : text;
            return message.repeatCount >= 2 ? cutText + " (" + message.repeatCount + ")" : cutText;
        }

        // 같은 종류·같은 문장이 이미 보이면 횟수를 올려 맨 아래로 옮기고 시간을 다시 잼, 없으면 맨 아래에 추가
        private static function addMessage(isError:Boolean, text:String, duration:Number):void
        {
            if (!isInitialized || text === null || text === "") // 초기화 전 전역 오류가 TypeError를 또 내지 않게
            {
                return;
            }

            const expireTime:int = getTimer() + int(duration * 1000);
            var message:Object = null;
            for (var i:int = 0; i < messages.length; i++)
            {
                if (messages[i].isError === isError && messages[i].text === text)
                {
                    message = messages.splice(i, 1)[0];
                    message.repeatCount++;
                    message.expireTime = expireTime;
                    break;
                }
            }

            if (message === null)
            {
                message = {isError: isError, text: text, repeatCount: 1, expireTime: expireTime};
            }
            messages.push(message);
            if (messages.length > MAX_MESSAGE_COUNT)
            {
                messages.shift();
            }

            updateMessageBoxes();
            Utils.setAsTopChild(messageBoxContainer);
            if (HintController.mouseHint.visible)
            {
                Utils.setAsTopChild(HintController.mouseHint);
            }

            if (!FOFOTimer.hasTimer(MESSAGE_EXPIRE_TIMER))
            {
                FOFOTimer.addByName(MESSAGE_EXPIRE_TIMER, 0.0, true, removeExpiredMessages);
            }
        }

        // 매 프레임 도는 타이머. 메시지가 남아 있는 동안만 계속함 (false를 반환하면 FOFOTimer가 지움)
        private static function removeExpiredMessages():Boolean
        {
            const now:int = getTimer();
            var isRemoved:Boolean = false;
            for (var i:int = messages.length - 1; i >= 0; i--)
            {
                if (messages[i].expireTime - now <= 0)
                {
                    messages.splice(i, 1);
                    isRemoved = true;
                }
            }

            if (isRemoved)
            {
                updateMessageBoxes();
            }
            return messages.length > 0;
        }

        // 지운 즉시 다시 배치해서, 커서를 움직이지 않고 다시 클릭하면 내려온 다음 메시지가 지워지게 함
        private static function removeMessageAt(index:int):void
        {
            messages.splice(index, 1);
            updateMessageBoxes();
        }

        // stage 기준 상자 사각형. margin 0이면 상자 자체(하이라이트), MESSAGE_CLICK_MARGIN이면 클릭 판정 영역
        private static function getMessageBoxRect(index:int, margin:Number):Rectangle
        {
            const rect:Rectangle = messageBoxes[index].getBounds(AppContext.stage);
            const scaledMargin:Number = margin * UITheme.getUIScale();
            rect.inflate(scaledMargin, scaledMargin);
            return rect;
        }

        // (x, y)에 있는 메시지 번호, 없으면 -1. 영역이 겹치는 곳은 아래쪽(최신) 메시지가 이김
        private static function findMessageIndexAt(x:Number, y:Number, margin:Number):int
        {
            for (var i:int = messages.length - 1; i >= 0; i--)
            {
                if (getMessageBoxRect(i, margin).contains(x, y))
                {
                    return i;
                }
            }
            return -1;
        }

        // 커서가 상자 위에 있으면 파란 테두리를 보여줌. 그리는 중·드래그 중(버튼을 누르고 있을 때)에는 띄우지 않음
        // 상자 크기는 글자에 따라 바뀌므로 크기별로 저장하지 않고, 크기나 색이 지난번과 다를 때만 지우고 다시 그림 (모양은 HintController와 같은 seed로 고정)
        private static function updateMessageHighlightBox(x:Number, y:Number):void
        {
            const index:int = (MouseState.isLeftDown || MouseState.isRightDown) ? -1 : findMessageIndexAt(x, y, 0);
            if (index < 0)
            {
                messageHighlightBox.visible = false;
                return;
            }

            const rect:Rectangle = getMessageBoxRect(index, 0);
            const highlightColor:uint = UITheme.getHintHightlightColor();
            if (rect.width !== messageHighlightDrawnWidth || rect.height !== messageHighlightDrawnHeight || highlightColor !== messageHighlightDrawnColor)
            {
                messageHighlightBox.graphics.clear();
                HandDrawnLine.drawRect(messageHighlightBox.graphics, 2, highlightColor, 1.0, 0, 0, rect.width, rect.height, null, 1.0, 0.01, HintController.HIGHLIGHT_BOX_SEED);
                messageHighlightDrawnWidth = rect.width;
                messageHighlightDrawnHeight = rect.height;
                messageHighlightDrawnColor = highlightColor;
            }

            messageHighlightBox.x = rect.x;
            messageHighlightBox.y = rect.y;
            messageHighlightBox.visible = true;
        }

        // 클릭 판정 영역 안이면 이벤트를 가로채고 true를 반환. isRemoving이면 그 메시지를 지움
        private static function interceptClickOnMessage(e:MouseEvent, isRemoving:Boolean):Boolean
        {
            const index:int = findMessageIndexAt(e.stageX, e.stageY, MESSAGE_CLICK_MARGIN);
            if (index < 0)
            {
                return false;
            }

            e.stopImmediatePropagation();
            if (isRemoving)
            {
                removeMessageAt(index);
            }
            return true;
        }

        private static function onMouseDownMessageBox(e:MouseEvent):void
        {
            isLeftClickIntercepted = interceptClickOnMessage(e, true);
        }

        private static function onRightMouseDownMessageBox(e:MouseEvent):void
        {
            isRightClickIntercepted = interceptClickOnMessage(e, false);
        }

        private static function onMiddleMouseDownMessageBox(e:MouseEvent):void
        {
            isMiddleClickIntercepted = interceptClickOnMessage(e, false);
        }

        private static function onMouseUpOrClickMessageBox(e:MouseEvent):void
        {
            if (isLeftClickIntercepted)
            {
                e.stopImmediatePropagation();
            }
        }

        private static function onRightMouseUpOrClickMessageBox(e:MouseEvent):void
        {
            if (isRightClickIntercepted)
            {
                e.stopImmediatePropagation();
            }
        }

        private static function onMiddleMouseUpOrClickMessageBox(e:MouseEvent):void
        {
            if (isMiddleClickIntercepted)
            {
                e.stopImmediatePropagation();
            }
        }

        private static function onMouseMoveMessageBox(e:MouseEvent):void
        {
            if (messages.length > 0)
            {
                updateMessageHighlightBox(e.stageX, e.stageY);
            }
        }
    }
}
