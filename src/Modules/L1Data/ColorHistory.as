package Modules.L1Data
{

    // 최근에 쓴 색 10개. My Palette와 완전히 별개의 배열을 쓰며 저장은 PaletteController.saveMypPaletteList가 함께 해줌
    // 층: L1 데이터 - 최근에 쓴 색 10개
    public final class ColorHistory
    {
        // 최근에 쓴 색 목록이 바뀌어 팔레트의 히스토리 칸을 다시 그려야 한다는 보고
        public static var onColorHistoryChangedFunc:Function;

        public static const HISTORY_COUNT:int = 10;

        // 최신 색이 0번. uint만 들어가고 빈 칸은 뒤쪽에 length만큼만 비어있음. 화면에서는 좌우 반전되어 0번이 맨 오른쪽 칸에 그려짐
        public static var list:Array = [];

        public static function initialize():void
        {
            list = [0];
            if (onColorHistoryChangedFunc != null) onColorHistoryChangedFunc();
        }

        // 저장 파일에서 읽은 배열을 넣음. uint가 아닌 값은 버림
        public static function setList(src:Array):void
        {
            const result:Array = [];

            for (var i:int = 0;i < src.length && result.length < HISTORY_COUNT;i++)
            {
                if (src[i] is uint)
                {
                    result.push(src[i]);
                }
            }

            list = result;
        }

        public static function add(color:uint):void
        {
            // 색깔 같으면 체크안함
            if (list.length > 0 && list[0] === color)
            {
                return;
            }

            const ignoreColor:* = ColorHistory.pickerIgnoreHistoryColor;

            if (ignoreColor !== null && ignoreColor !== undefined && (ignoreColor as uint) === color)
            {
                ColorHistory.pickerIgnoreHistoryColor = null;
                return;
            }

            // 이미 있는 색깔이면 다시 최신으로 갱신
            const existIndex:int = list.indexOf(color);

            if (existIndex >= 0)
            {
                list.removeAt(existIndex);
            }
            else if (list.length >= HISTORY_COUNT)
            {
                list.length = HISTORY_COUNT - 1;
            }

            list.insertAt(0, color);
            if (onColorHistoryChangedFunc != null) onColorHistoryChangedFunc();
        }

        public static function isEmpty(index:int):Boolean
        {
            return !(list[index] is uint);
        }


        public static var pickerIgnoreHistoryColor:* = null; // 히스토리 색 등록 할때 여기에 등록된 색은 등록 안하게함

    }
}
