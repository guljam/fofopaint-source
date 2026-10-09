package assets
{
    import flash.utils.describeType;
    import flash.text.TextInteractionMode;

    // 층: L1 데이터 - Symbols의 비어 있는 시각 필드를 찾아 모음
    public final class VisualFieldCollector
    {
        public static function collectNullVisualFields(target:Object):Array
        {
            var result:Array = [];
            var typeInfo:XML = describeType(target);

            for each (var variable:XML in typeInfo.variable)
            {
                var fieldName:String = variable.@name;
                var fieldType:String = variable.@type;

                var supported:Boolean =
                    fieldType == "flash.display::SimpleButton" ||
                    fieldType == "flash.text::TextField";
                if (supported && target[fieldName] == null)
                {
                    result.push(fieldName);
                }
            }

            return result;
        }
    }
}
