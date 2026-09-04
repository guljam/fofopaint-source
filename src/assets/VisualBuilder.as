package assets {
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;

    public final class VisualBuilder {
        public static function buildInto(
                target:Object,
                embeddedClass:Class,
                fields:Array
            ):Sprite {
            if (!target)
                throw new ArgumentError("target must not be null.");

            if (!embeddedClass)
                throw new ArgumentError("embeddedClass must not be null.");

            var visual:Sprite = new embeddedClass() as Sprite;

            if (!visual)
                throw new TypeError("Embedded symbol is not a Sprite.");

            var targetContainer:DisplayObjectContainer =
                target as DisplayObjectContainer;

            if (!targetContainer)
                throw new TypeError(
                        "target must be a DisplayObjectContainer."
                    );

            // 먼저 변수 연결
            bindFields(target, visual, fields);

            // Animate의 원래 timeline 구조처럼
            // visual의 직접 자식을 target의 직접 자식으로 이동
            while (visual.numChildren > 0) {
                var child:DisplayObject = visual.getChildAt(0);

                // addChild하면 기존 visual에서 자동 제거됨
                targetContainer.addChild(child);
            }

            return visual;
        }

        private static function bindFields(
                target:Object,
                visual:DisplayObjectContainer,
                fields:Array
            ):void {
            for each (var fieldName:String in fields) {
                if (!(fieldName in target)) {
                    throw new ReferenceError(
                            "Target does not declare field: " + fieldName
                        );
                }

                var child:DisplayObject =
                    findNamedChild(visual, fieldName);

                if (!child) {
                    throw new ReferenceError(
                            "Embedded symbol is missing instance: " +
                            fieldName
                        );
                }

                target[fieldName] = child;
            }
        }

        private static function findNamedChild(
                root:DisplayObjectContainer,
                instanceName:String
            ):DisplayObject {
            var child:DisplayObject =
                root.getChildByName(instanceName);

            if (child)
                return child;

            for (var i:int = 0; i < root.numChildren; i++) {
                var container:DisplayObjectContainer =
                    root.getChildAt(i) as DisplayObjectContainer;

                if (!container)
                    continue;

                child = findNamedChild(container, instanceName);

                if (child)
                    return child;
            }

            return null;
        }
    }
}
