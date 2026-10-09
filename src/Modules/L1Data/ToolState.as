package Modules.L1Data
{
    // 툴 번호(TOOL_*)와 지금 고른 툴, 임시로 바꾸기 전에 백업해 둔 이전 툴
    // 층: L1 데이터 - 툴 번호와 현재 툴 상태
    public class ToolState
    {
        public static const TOOL_NONE:int = 0;

        public static const TOOL_PEN:int = (1 << 0);

        public static const TOOL_ERASER:int = (1 << 1);

        public static const TOOL_LINE:int = (1 << 2);

        public static const TOOL_FILLPEN:int = (1 << 3);

        public static const TOOL_HAND:int = (1 << 4);

        public static const TOOL_LASSO:int = (1 << 5);

        public static const TOOL_EYEDROPPER:int = (1 << 6);

        public static const TOOL_ZOOM:int = (1 << 7);

        public static const TOOL_ROTATE:int = (1 << 8);

        public static const TOOL_MOVE:int = (1 << 9);

        public static const TOOL_UNDO:int = (1 << 10);

        public static const TOOL_REDO:int = (1 << 11);

        public static const TOOL_MIRROR:int = (1 << 12);

        public static var nowTool:int = 1; // 현재 툴 번호

        public static var lastTool:int = TOOL_NONE; // 툴백업

        // 현재 툴이 펜이나 직선인지
        public static function isSelectedToolPenOrLine():Boolean
        {
            return nowTool === TOOL_PEN || nowTool === TOOL_LINE;
        }

        // 현재 툴이 tool인지
        public static function isSelectedTool(tool:int):Boolean
        {
            return nowTool === tool;
        }

        // 현재 툴 번호를 바꿈
        public static function setSelectedTool(tool:int):void
        {
            nowTool = tool;
        }

        // 백업해 둔 이전 툴을 지움
        public static function resetLastTool():void
        {
            lastTool = TOOL_NONE;
        }

        // 백업해 둔 이전 툴이 tool인지
        public static function isLastTool(tool:int):Boolean
        {
            return lastTool === tool;
        }

        // 이전 툴을 직접 백업함
        public static function setLastTool(tool:int):void
        {
            lastTool = tool;
        }

        // 백업해 둔 이전 툴이 없을 때만 현재 툴을 백업함
        public static function updateLastTool():void
        {
            if (lastTool === TOOL_NONE)
            {
                lastTool = nowTool;
            }
        }

    }
}
