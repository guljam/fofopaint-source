package Modules.L1Data
{
    import flash.display.DisplayObject;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;

    // 키보드 눌림 상태(눌린 키 목록, 마지막 키)와 키코드 표, 키 반복의 단일 소유자
    // 층: L1 데이터 - 키 눌림 상태와 키코드 표, 키 반복
    public class KeyState
    {
        public static const KEY:Object = {
                a: 65,
                b: 66,
                c: 67,
                d: 68,
                e: 69,
                f: 70,
                g: 71,
                h: 72,
                i: 73,
                j: 74,
                k: 75,
                l: 76,
                m: 77,
                n: 78,
                o: 79,
                p: 80,
                q: 81,
                r: 82,
                s: 83,
                t: 84,
                u: 85,
                v: 86,
                w: 87,
                x: 88,
                y: 89,
                z: 90,
                dot: 190,
                comma: 188,
                semicolon: 186,
                shift: 16,
                ctrl: 17,
                alt: 18,
                rightAlt: 21, // as에서는 한글모드
                rightCtrl: 25, // 한글 모드에서 오른쪽 컨트롤
                space: 32,
                backslash: 220,
                backspace: 8,
                enter: 13,
                esc: 27,
                del: 46,
                tab: 9,
                n0: 48,
                n1: 49,
                n2: 50,
                n3: 51,
                n4: 52,
                n5: 53,
                n6: 54,
                n7: 55,
                n8: 56,
                n8: 56,
                n9: 57,
                minus: 189,
                pgup: 33,
                pgdn: 34,
                home: 36,
                end: 35,
                left: 37,
                up: 38,
                right: 39,
                down: 40,
                f1: 112,
                f2: 113,
                f3: 114,
                f4: 115,
                f5: 116,
                f6: 117,
                f7: 118,
                f8: 119,
                f9: 120,
                f10: 121,
                f11: 122,
                f12: 123,
                window: 91
            };

        public static const KEY_REPEAT_START_DELAY:Number = 0.3;

        public static const KEY_REPEAT_INTERVAL:Number = 0.06;

        // 키 누름 관련
        public static var lastPressedKey:int = -1; // 마지막 누른거 여기다가 저장 반복호출되는 keydown 함수에서 한번만 호출되게 하는변수

        public static const keyBuffer:Array = []; // 정식 키 다운 눌러준 상태에서 다른 키가 눌러져 있으면 여기다가 저장

        public static const COMMAND_CTRL:int = (1 << 0);

        public static const COMMAND_SHIFT:int = (1 << 1);

        public static const COMMAND_CTRL_SHIFT:int = (1 << 2);

        // 지금 누르고 있는 키 중 마지막 키를 저장함 (반복되는 keydown에서 한 번만 처리하려고)
        public static function updateLastKey():void
        {
            lastPressedKey = getLastPressedKey();
        }

        // 마지막 키 기록을 지움
        public static function resetLastKey():void
        {
            lastPressedKey = -1;
        }

        // 마지막으로 기록한 키(lastPressedKey)와 같은 키인지
        public static function isLastKey(key:uint):Boolean
        {
            return lastPressedKey === key;
        }

        // 마우스가 target 밖으로 나가면 키 반복을 멈추는 타이머를 시작함
        public static function startKeyRepeatStopTimerOnMouseLeave(target:DisplayObject):void
        {
            FOFOTimer.addByName("checkKeyRepeatStop", 0.0, true, function ():Boolean
                {
                    if (!target.hitTestPoint(AppContext.stage.mouseX, AppContext.stage.mouseY))
                    {
                        removeKeyRepeatEvents(null);
                        return false;
                    }
                    return true;
                });
        }

        // 키를 누르고 있는 동안 func를 일정 간격으로 반복 호출함 (이미 반복 중이면 false)
        public static function startKeyRepeat(firstCall:Boolean, func:Function, ...args):Boolean
        {
            if (FOFOTimer.hasTimer("keyHoldWaitTimer") || FOFOTimer.hasTimer("keyHoldRepeatTimer"))
            {
                return false;
            }
            FOFOTimer.addByName("keyHoldWaitTimer", KEY_REPEAT_START_DELAY, false,
                    function ():void
                    {
                        func.apply(Main, args);
                        FOFOTimer.addByName("keyHoldRepeatTimer", KEY_REPEAT_INTERVAL, true, func, args);
                    });
            addKeyRepeatEvents();
            if (firstCall)
            {
                func.apply(Main, args);
            }
            return true;
        }

        // ctrl만 누르고 있는지
        public static function isPressingControl():Boolean
        {
            return getCommandKey() === COMMAND_CTRL;
        }

        // shift만 누르고 있는지
        public static function isPressingShift():Boolean
        {
            return getCommandKey() === COMMAND_SHIFT;
        }

        // ctrl과 shift를 같이 누르고 있는지
        public static function isPressingControlShift():Boolean
        {
            return getCommandKey() === COMMAND_CTRL_SHIFT;
        }

        // 누르고 있는 조합키(COMMAND_*)를 돌려줌, 없으면 0
        public static function getCommandKey():int
        {
            const first:uint = getFirstPressedKey();
            const second:uint = getSecondPressedKey();
            if ((second === KEY.shift && (first === KEY.ctrl || first === KEY.rightCtrl))
                    || (first === KEY.shift && (second === KEY.ctrl || second === KEY.rightCtrl)))
            {
                return COMMAND_CTRL_SHIFT;
            }
            if (first === KEY.shift)
            {
                return COMMAND_SHIFT;
            }
            if (first === KEY.ctrl || first === KEY.rightCtrl)
            {
                return COMMAND_CTRL;
            }
            return 0;
        }

        // 누르고 있는 키가 없으면 마지막 키 기록을 지움
        public static function checkGeneralKeyUp():void
        {
            if (keyBuffer.length === 0)
            {
                resetLastKey();
            }
        }

        // IME 등이 보낸 잘못된 키코드(229, 241, 242)나 alt+space가 있으면 키 버퍼를 비움
        public static function checkInvalidKey():void
        {
            const len:uint = keyBuffer.length;
            for (var i:int = 0;i < len;i++)
            {
                if (keyBuffer[i] === 229
                        || keyBuffer[i] === 241
                        || keyBuffer[i] === 242)
                {
                    clearKeyBuffer();
                    return;
                }
            }
            if (len >= 2)
            {
                if ((keyBuffer[0] === 18 && keyBuffer[1] === 32)
                        || (keyBuffer[0] === 32 && keyBuffer[1] === 18))
                {
                    clearKeyBuffer();
                }
            }
        }

        // 지금 누르고 있는 키 개수
        public static function getPressedKeyCount():int
        {
            return keyBuffer.length;
        }

        // 키를 하나라도 누르고 있는지
        public static function isKeyPressed():Boolean
        {
            return keyBuffer.length > 0;
        }

        // 키를 정확히 2개 누르고 있는지
        public static function isTwoKeyPressed():Boolean
        {
            return keyBuffer.length === 2;
        }

        // key를 지금 누르고 있는지
        public static function isPressedKey(key:int):Boolean
        {
            if (keyBuffer.lastIndexOf(key) > -1)
            {
                return true;
            }
            return false;
        }

        // 키 버퍼 안에서 key의 위치 (없으면 -1)
        public static function getPressedKeyIndex(key:int):int
        {
            return keyBuffer.lastIndexOf(key);
        }

        // 가장 먼저 누른 키
        public static function getFirstPressedKey():int
        {
            return keyBuffer[0];
        }

        // 두 번째로 누른 키
        public static function getSecondPressedKey():int
        {
            return keyBuffer[1];
        }

        // 가장 나중에 누른 키
        public static function getLastPressedKey():int
        {
            return keyBuffer[keyBuffer.length - 1];
        }

        // 키 반복을 멈추게 하는 이벤트(마우스 누름, 키 뗌, 창 비활성)를 등록함
        public static function addKeyRepeatEvents():void
        {
            AppContext.stage.nativeWindow.addEventListener(Event.DEACTIVATE, removeKeyRepeatEvents);
            AppContext.stage.addEventListener(MouseEvent.MOUSE_DOWN, removeKeyRepeatEvents, false, InputPriority.DEFAULT);
            AppContext.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, removeKeyRepeatEvents, false, InputPriority.DEFAULT);
            AppContext.stage.addEventListener(MouseEvent.MOUSE_UP, removeKeyRepeatEvents, false, InputPriority.DEFAULT);
            AppContext.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, removeKeyRepeatEvents, false, InputPriority.DEFAULT);
            AppContext.stage.addEventListener(KeyboardEvent.KEY_UP, removeKeyRepeatEvents, false, InputPriority.DEFAULT);
        }

        // 키 반복 타이머와 멈춤 이벤트를 모두 제거함
        public static function removeKeyRepeatEvents(e:Object):void
        {
            FOFOTimer.remove("checkKeyRepeatStop");
            FOFOTimer.remove("keyHoldWaitTimer");
            FOFOTimer.remove("keyHoldRepeatTimer");
            AppContext.stage.nativeWindow.removeEventListener(Event.DEACTIVATE, removeKeyRepeatEvents);
            AppContext.stage.removeEventListener(MouseEvent.MOUSE_DOWN, removeKeyRepeatEvents);
            AppContext.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, removeKeyRepeatEvents);
            AppContext.stage.removeEventListener(MouseEvent.MOUSE_UP, removeKeyRepeatEvents);
            AppContext.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, removeKeyRepeatEvents);
            AppContext.stage.removeEventListener(KeyboardEvent.KEY_UP, removeKeyRepeatEvents);
        }

        // 눌린 키가 expectedLength개일 때만 마지막 키를 callback에 넘기고 true를 돌려줌
        public static function checkSubKey(expectedLength:uint, updateFlag:Boolean, callback:Function):Boolean
        {
            if (getPressedKeyCount() !== expectedLength)
            {
                return false;
            }
            const subKey:uint = getLastPressedKey();
            if (updateFlag)
            {
                updateLastKey();
            }
            if (callback !== null)
            {
                callback(subKey);
            }
            return true;
        }

        // 키 버퍼와 마지막 키 기록을 모두 지움
        public static function clearKeyBuffer():void
        {
            keyBuffer.length = 0;
            resetLastKey();
        }

    }
}
