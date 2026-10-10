package Modules.L4UI
{
    import flash.display.InteractiveObject;
    import flash.events.FocusEvent;
    import flash.events.IMEEvent;
    import flash.events.KeyboardEvent;
    import flash.system.Capabilities;
    import flash.system.IME;
    import flash.system.System;
    import flash.text.TextField;
    import flash.text.TextFieldType;
    import flash.utils.getTimer;
    import Modules.L1Data.KeyState;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L4UI.HintStrings;
    import Modules.L1Data.FOFOTimer;
    import Modules.L3Feature.ImeDiagnostics;

    // IME 상태의 단일 관리자
    //  - 규칙: 텍스트 입력 필드에 포커스가 있으면 IME를 켜고, 그 외(캔버스 단축키 영역)에서는 끔
    //  - 끄기에 실패하거나 OS가 되돌려서 IME가 키를 가져가면(keyCode 229 등) 단축키로 처리하지 않고 안내 힌트를 띄움
    // 층: L4 UI - IME 상태의 단일 관리자 (입력 필드 포커스에 따라 켜고 끔)
    public class ImeController
    {
        public static var main:Main;

        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        // Windows VK_PROCESSKEY: IME가 가져간 키. 이 상태에서는 keyCode로 실제 키를 알 수 없음
        private static const VK_PROCESSKEY:int = 229;

        // 일본어/중국어/한국어 IME의 모드 전환 계열 키. 단축키가 아니므로 무시함 (VK_CONVERT 28, VK_NONCONVERT 29, VK_OEM_ATTN~VK_OEM_BACKTAB 240~245)
        // 21(한/영), 25(한자)는 KEY.rightAlt, KEY.rightCtrl 로 이미 쓰고 있어서 포함하지 않음. 값은 진단 출력으로 검증할 것
        private static const IME_MODE_KEYS:Array = [28, 29, 240, 241, 242, 243, 244, 245];

        // 힌트: 2초 안에 3번 이상 IME가 키를 가져가면 띄우고, 이후 30초 동안은 다시 띄우지 않음
        private static const HINT_WINDOW_MS:int = 2000;
        private static const HINT_TRIGGER_COUNT:int = 3;
        private static const HINT_COOLDOWN_MS:int = 30000;

        private static const REFRESH_TIMER:String = "imeRefreshTimer";

        private static var processKeyCount:int = 0;
        private static var processKeyWindowStart:int = 0;
        private static var lastHintTime:int = -HINT_COOLDOWN_MS;
        private static var isCompositionLogAttached:Boolean = false;

        public static function init():void
        {
            // 포커스 이동은 모든 텍스트 필드에서 한곳으로 감지함 (필드를 추가해도 따로 등록할 필요 없음)
            main.stage.addEventListener(FocusEvent.FOCUS_IN, onFocusChanged, true);
            main.stage.addEventListener(FocusEvent.FOCUS_OUT, onFocusChanged, true);

            ImeDiagnostics.checkMarker();
            attachCompositionLog();
            refresh();
        }

        public static function onWindowActivate():void
        {
            ImeDiagnostics.checkMarker();
            attachCompositionLog();
            ImeDiagnostics.log("WINDOW_ACTIVATE", "ime[" + ImeDiagnostics.describeImeState() + "]");
            refresh();
        }

        public static function onWindowDeactivate():void
        {
            ImeDiagnostics.log("WINDOW_DEACTIVATE", "ime[" + ImeDiagnostics.describeImeState() + "]");
        }

        public static function isTextInputFocused():Boolean
        {
            const f:InteractiveObject = main.stage.focus;
            return (f is TextField) && (f as TextField).type === TextFieldType.INPUT;
        }

        // 현재 포커스에 맞는 IME 상태로 맞춤. 상태가 이미 맞으면 아무것도 안함 (IME.enabled 읽기만 함)
        public static function refresh():void
        {
            if (!Capabilities.hasIME)
            {
                return;
            }

            const wantIme:Boolean = isTextInputFocused();

            try
            {
                if (IME.enabled === wantIme)
                {
                    return;
                }

                const before:String = (ImeDiagnostics.enabled) ? ImeDiagnostics.describeImeState() : "";

                if (!wantIme)
                {
                    IME.compositionAbandoned();
                }

                IME.enabled = wantIme;

                if (ImeDiagnostics.enabled)
                {
                    ImeDiagnostics.log("IME_SET", "want=" + wantIme + " before[" + before + "] after[" + ImeDiagnostics.describeImeState() + "]");
                }
            }
            catch (err:Error)
            {
                // IME가 비활성 상태이거나 환경(TSF IME, PC방 후킹 등)에 따라 조작 실패할 수 있음
                // 여기서 예외가 올라가면 단축키 입력 경로가 죽으므로 삼킴
                ImeDiagnostics.log("IME_SET_FAILED", "want=" + wantIme + " error=" + err.message);
            }
        }

        // 키 다운을 가장 먼저 검사함. IME가 가져간 키면 true (호출한 쪽은 단축키로 처리하지 않아야함)
        public static function interceptKeyDown(e:KeyboardEvent):Boolean
        {
            const textFocused:Boolean = isTextInputFocused();
            const code:int = e.keyCode;
            var verdict:String = "pass";

            if (!textFocused)
            {
                if (code === VK_PROCESSKEY)
                {
                    verdict = "ime-process";
                    onImeProcessKey();
                }
                else if (IME_MODE_KEYS.indexOf(code) !== -1)
                {
                    verdict = "ime-mode-key";
                }
            }

            if (ImeDiagnostics.enabled)
            {
                ImeDiagnostics.logKey("DOWN", e, describeFocus(), textFocused, verdict);
            }

            if (verdict === "pass")
            {
                return false;
            }

            // 누르고 있던 키 상태도 믿을 수 없으므로 비움
            KeyState.clearKeyBuffer();
            e.stopImmediatePropagation();
            return true;
        }

        public static function logKeyUp(e:KeyboardEvent):void
        {
            if (ImeDiagnostics.enabled)
            {
                ImeDiagnostics.logKey("UP", e, describeFocus(), isTextInputFocused(), "-");
            }
        }

        private static function onFocusChanged(e:FocusEvent):void
        {
            if (ImeDiagnostics.enabled)
            {
                ImeDiagnostics.log("FOCUS_" + ((e.type === FocusEvent.FOCUS_IN) ? "IN" : "OUT"), "target=" + describeObject(e.target as InteractiveObject));
            }

            // FOCUS_OUT 시점에는 다음 포커스가 아직 정해지지 않으므로 다음 프레임에 판단함
            if (!FOFOTimer.hasTimer(REFRESH_TIMER))
            {
                FOFOTimer.addByName(REFRESH_TIMER, 0.0, false, refresh);
            }
        }

        private static function onImeProcessKey():void
        {
            const now:int = getTimer();

            if (now - processKeyWindowStart > HINT_WINDOW_MS)
            {
                processKeyWindowStart = now;
                processKeyCount = 0;
            }

            processKeyCount++;

            if (processKeyCount >= HINT_TRIGGER_COUNT && now - lastHintTime > HINT_COOLDOWN_MS)
            {
                lastHintTime = now;
                processKeyCount = 0;
                HintController.showMouseHintTemp(HintStrings.STRING_IME_ON_HINT, 4.0);
            }
        }

        private static function describeFocus():String
        {
            return describeObject(main.stage.focus);
        }

        private static function describeObject(o:InteractiveObject):String
        {
            if (o === null)
            {
                return "null";
            }

            return o.name + "(" + String(o) + ")";
        }

        // IME 조합 결과가 들어오는지 진단용으로 기록함
        private static function attachCompositionLog():void
        {
            if (!ImeDiagnostics.enabled || isCompositionLogAttached)
            {
                return;
            }

            try
            {
                if (System.ime !== null)
                {
                    System.ime.addEventListener(IMEEvent.IME_COMPOSITION, onImeComposition);
                    isCompositionLogAttached = true;
                }
            }
            catch (err:Error)
            {
                ImeDiagnostics.log("IME_EVENT_ATTACH_FAILED", err.message);
            }
        }

        private static function onImeComposition(e:IMEEvent):void
        {
            ImeDiagnostics.log("IME_COMPOSITION", "text=" + e.text);
        }
    }
}
