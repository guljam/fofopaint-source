package Symbols
{
    import flash.display.SimpleButton;
    import flash.display.Sprite;
    import assets.VisualBuilder;
    import assets.VisualFieldCollector;
    import Modules.L1Data.UIEngine.UITheme;

    // 층: L4 UI - FOFO 캐릭터 버튼 화면 묶음 (크기, 미러, 위·아래 위치)
    public class FOFO extends Sprite
    {
        public var fofo:SimpleButton;
        private var constScale:Number = 0.65;
        private var topPos:Boolean = false;

        public static const COLLISION_NONE:int = 0;
        public static const COLLISION_TOP:int = 1;
        public static const COLLISION_BOTTOM:int = 2;
        public static const COLLISION_ALL:int = 3;

        public function setScale(newScale:Number):void
        {
            this.scaleX = newScale * constScale;
            this.scaleY = newScale * constScale;
        }

        public function setMirror(flag:Boolean):void
        {
            if (flag)
            {
                fofo.scaleX = -1.0;
                fofo.x = fofo.width;
            }
            else
            {
                fofo.x = 0;
                fofo.scaleX = 1.0;
            }
        }

        public function setTop(topY:Number):void
        {
            topPos = true;
            fofo.scaleY = -1.0;
            fofo.y = fofo.height;
            y = topY;
        }

        public function setBottom(sideBarHeight:Number):void
        {
            topPos = false;
            fofo.scaleY = 1.0;
            fofo.y = 0;
            y = sideBarHeight - height + 2;
        }

        public function updateColor():void
        {
            UITheme.applyUIFGColor(fofo);
        }

        [Embed(source="fofoPaint-animate-27.13.swf",symbol="FOFO")]
        private static const EmbeddedClass:Class;

        public function FOFO()
        {
            const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
            VisualBuilder.buildInto(this, EmbeddedClass, fields);

            fofo.useHandCursor = false;
            this.alpha = 1.0;
            setScale(1.0);
        }
    }
}
