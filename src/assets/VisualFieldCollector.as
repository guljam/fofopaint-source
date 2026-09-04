package assets {
    import flash.utils.describeType;

    public final class VisualFieldCollector {
        public static function collectNullVisualFields(target:Object):Array {
            var result:Array = [];
            var typeInfo:XML = describeType(target);

            for each (var variable:XML in typeInfo.variable) {
                var fieldName:String = variable.@name;
                var fieldType:String = variable.@type;

                var supported:Boolean =
                    fieldType == "flash.display::SimpleButton" ||
                    fieldType == "flash.text::TextField";

                if (supported && target[fieldName] == null) {
                    result.push(fieldName);
                }
            }

            return result;
        }
    }
}
