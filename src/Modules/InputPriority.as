package Modules
{
    /**
     * stage 입력 이벤트 리스너 우선순위. 높을수록 먼저 호출된다.
     * 같은 값이면 등록 순서대로 호출된다.
     * 이벤트 종류/캡처 단계별로 리스트가 따로 정렬되므로, 서로 경합하는 stage의
     * MOUSE_DOWN/UP, RIGHT_MOUSE_DOWN/UP, KEY_DOWN/UP 리스너는 모두 이 상수를 쓴다.
     */
    public class InputPriority
    {
        public static const EARLY_KEY:int = 12;
        public static const STAGE_ROOT:int = 11;
        public static const DEFAULT:int = 10;
        public static const MODE:int = 9;
        public static const LATE:int = 8;
    }
}
