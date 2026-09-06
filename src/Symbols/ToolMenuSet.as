package symbols
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Shape;
    import flash.display.SimpleButton;
    import flash.display.Sprite;
    import flash.geom.ColorTransform;
    import flash.geom.Matrix;
    import assets.VisualBuilder;
    import assets.VisualFieldCollector;

    public class ToolMenuSet extends Sprite
    {
        public var toolPen:SimpleButton;
        public var toolFillPen:SimpleButton;
        public var toolFillPenOK:SimpleButton;
        public var toolFillPenCancel:SimpleButton;
        public var toolEraser:SimpleButton;
        public var toolUndo:SimpleButton;
        public var toolRedo:SimpleButton;
        public var toolEyedropper:SimpleButton;
        public var toolMirror:SimpleButton;
        public var toolLasso:SimpleButton;
        public var toolMove:SimpleButton;
        public var toolRotate:SimpleButton;
        public var toolLine:SimpleButton;
        public var toolRefLayer:SimpleButton;
        public var toolZoomIn:SimpleButton;
        public var toolZoomOut:SimpleButton;
        public var toolHand:SimpleButton;
        public var toolSelectCursor:SimpleButton;
        private var lastTool:String = "toolPen";

        public const BOX_WIDTH:Number = 34;
        public const BOX_HEIGHT:Number = 476;

        public var bgBox:Shape = new Shape();
        private var deafultY:Number = 0;

        private const base:ColorTransform = new ColorTransform();
        private const iconLeft:ColorTransform = new ColorTransform();
        private const activeColor:ColorTransform = new ColorTransform();
        private const activeIconColor:ColorTransform = new ColorTransform();
        private const defaultColor:ColorTransform = new ColorTransform();
        private var btn:SimpleButton;
        private var btnUp:DisplayObject;
        private var btnOver:DisplayObjectContainer;
        private var btnDown:DisplayObjectContainer;
        private var buttonArr:Array;

        private var checkedLayerONFlag:Boolean = false;
        private const toolSelectViewBmpdCache:Object = {};

        public function isToolSelectViewBmpdCached(key:String):Boolean
        {
            return toolSelectViewBmpdCache.hasOwnProperty(key);
        }

        public function getToolSelectViewBmpd(index:int, button:SimpleButton):BitmapData
        {
            const key:String = Global.getUIBGColor() + "_" + String(index);

            if (!toolSelectViewBmpdCache.hasOwnProperty(key))
            {
                makeCacheToolSelectViewBmpd(key, button);
            }

            return toolSelectViewBmpdCache[key];
        }

        public function makeCacheToolSelectViewBmpd(key:String, toolButton:SimpleButton):void
        {
            const extend:Number = 20;
            const bgcolor:uint = Global.getUIBGColor();
            const scale:Number = this.scaleX;
            const bmpd:BitmapData = new BitmapData(toolButton.width / scale + extend, toolButton.height / scale + extend, true, 0);
            const sprite:Sprite = new Sprite();
            const mask:Shape = new Shape();
            const mat:Matrix = new Matrix();

            mat.translate(5, 5);

            mask.graphics.clear();
            mask.graphics.beginFill(bgcolor, 0.7);
            mask.graphics.drawCircle(bmpd.width / 2, bmpd.height / 2, toolButton.width / scale / 2 + extend / 2);
            mask.graphics.endFill();

            bmpd.draw(mask);
            bmpd.draw(toolButton, mat);

            toolSelectViewBmpdCache[key] = bmpd;
        }

        public function setFillPenModeOFF():void
        {
            toolEraser.alpha = 1.0;
            toolFillPen.alpha = 1.0;
            toolEyedropper.alpha = 1.0;
            toolLine.alpha = 1.0;
            toolLasso.alpha = 1.0;
            toolMove.alpha = 1.0;
            toolRefLayer.alpha = 1.0;
            toolMirror.alpha = 1.0;

            toolSelectCursor.visible = true;
            toolRedo.visible = true;
            toolPen.visible = true;
            toolFillPenOK.visible = false;
            toolFillPenCancel.visible = false;
        }

        public function setFillPenModeON():void
        {
            const offAlpha:Number = Global.OFFALPHA;
            toolEraser.alpha = offAlpha;
            toolFillPen.alpha = offAlpha;
            toolEyedropper.alpha = offAlpha;
            toolLine.alpha = offAlpha;
            toolLasso.alpha = offAlpha;
            toolMove.alpha = offAlpha;
            toolRefLayer.alpha = offAlpha;
            toolMirror.alpha = offAlpha;

            toolSelectCursor.visible = false;
            toolRedo.visible = false;
            toolPen.visible = false;
            toolFillPenOK.visible = true;
            toolFillPenCancel.visible = true;
        }

        public function setIconAlphaOnLassoToolON(alpha:Number):void
        {
            toolMirror.alpha = alpha;
            toolMove.alpha = alpha;
            toolUndo.alpha = alpha;
            toolRedo.alpha = alpha;
            toolLasso.alpha = alpha;

            if (alpha < 1.0)
            {
                toolPen.alpha = alpha;
                toolEraser.alpha = alpha;
                toolFillPen.alpha = alpha;
                toolEyedropper.alpha = alpha;
                toolLine.alpha = alpha;
                toolRefLayer.alpha = alpha;
            }
            else if (checkedLayerONFlag === false)
            {
                toolPen.alpha = alpha;
                toolEraser.alpha = alpha;
                toolFillPen.alpha = alpha;
                toolEyedropper.alpha = alpha;
                toolLine.alpha = alpha;
                toolRefLayer.alpha = alpha;
            }
        }

        public function setToolButtonsForCheckedLayerOFF():void
        {
            checkedLayerONFlag = false;
            toolPen.alpha = 1.0;
            toolEraser.alpha = 1.0;
            toolFillPen.alpha = 1.0;
            toolEyedropper.alpha = 1.0;
            toolLine.alpha = 1.0;
            toolSelectCursor.alpha = 1.0;
        }

        public function setToolButtonsForCheckedLayerON():void
        {
            const offalpha:Number = Global.OFFALPHA;
            checkedLayerONFlag = true;
            toolPen.alpha = offalpha;
            toolEraser.alpha = offalpha;
            toolFillPen.alpha = offalpha;
            toolEyedropper.alpha = offalpha;
            toolLine.alpha = offalpha;

            const btn:SimpleButton = getChildByName(lastTool) as SimpleButton;
            if (btn)
            {
                toolSelectCursor.alpha = btn.alpha;
            }
        }

        public function bgBoxVisible(flag:Boolean):void
        {
            if (flag)
            {
                addChild(bgBox);
                setChildIndex(bgBox, 0);
            }
            else
            {
                removeChild(bgBox);
            }
        }

        public function setCursorVisible(flag:Boolean):void
        {
            toolSelectCursor.visible = flag;
        }

        public function getDeafultY():Number
        {
            return deafultY;
        }

        public function setDeafultY(y:Number):void
        {
            deafultY = y;
        }

        public function checkBottomOFF():void
        {
            y = deafultY;
        }

        public function moveCanvasControlButtonsTo(newParent:DisplayObjectContainer):void
        {
            newParent.addChild(toolZoomIn);
            newParent.addChild(toolZoomOut);
            newParent.addChild(toolRotate);
            newParent.addChild(toolMirror);

            toolZoomIn.x = 26;
            toolZoomIn.y = 23;
            toolZoomOut.x = toolZoomIn.x + toolZoomIn.width + 7;
            toolZoomOut.y = toolZoomIn.y;
            toolRotate.x = toolZoomOut.x + toolZoomOut.width + 8;
            toolRotate.y = toolZoomIn.y;
            toolMirror.x = toolRotate.x + toolRotate.width + 7;
            toolMirror.y = toolZoomIn.y;
        }

        public function changeUIColor():void
        {
            var btn:SimpleButton;
            var i:uint;
            for (i = 0; i < buttonArr.length; i++)
            {
                btn = buttonArr[i] as SimpleButton;
                Global.applyToolBoxButtonUpBGColor(btn.upState as DisplayObject);
                Global.setButtonColorWithBG(btn.overState as DisplayObjectContainer, 4, 2, 0.0);
                Global.setButtonColorWithBG(btn.downState as DisplayObjectContainer, 4, 2, 0.0);
                btn.downState.x = 2;
                btn.downState.y = 2;
            }

            const fillPenButtons:Array = [toolFillPenOK, toolFillPenCancel];
            for (i = 0; i < fillPenButtons.length; i++)
            {
                btn = fillPenButtons[i] as SimpleButton;
                Global.applyToolBoxButtonUpBGColor(btn.upState as DisplayObject);
                Global.setButtonColorWithBG(btn.overState as DisplayObjectContainer, 4, 2, 0.0);
                Global.setButtonColorWithBG(btn.downState as DisplayObjectContainer, 4, 2, 0.0);
                btn.downState.x = 2;
                btn.downState.y = 2;
            }

            const rotateButtonDownState:DisplayObjectContainer = toolRotate.downState as DisplayObjectContainer;
            rotateButtonDownState.x = 0;
            rotateButtonDownState.y = 0;
            toolHand.x = 0;
            toolHand.y = 0;

            bgBox.graphics.lineStyle(0, 0, 0);
            bgBox.graphics.beginFill(Global.getToolBoxBGColor());
            bgBox.graphics.drawRect(-4, -1, BOX_WIDTH + 8, BOX_HEIGHT + 2);
            bgBox.graphics.endFill();

            btn = null;
            btnUp = null;
            btnOver = null;
            btnDown = null;
        }

        public function getLastTool():String
        {
            return lastTool;
        }

        public function moveToolCursorInit():void
        {
            moveToolCursor(lastTool);
        }

        public function moveToolCursor(childName:String, newParent:DisplayObjectContainer = null):void
        {
            var btn:SimpleButton;
            if (newParent !== null)
            {
                if (!newParent.contains(toolSelectCursor))
                {
                    newParent.addChild(toolSelectCursor);
                }
                btn = newParent.getChildByName(childName) as SimpleButton;
            }
            else
            {
                if (!this.contains(toolSelectCursor))
                {
                    this.addChild(toolSelectCursor);
                }
                btn = this.getChildByName(childName) as SimpleButton;
            }

            if (!btn)
            {
                return;
            }

            toolSelectCursor.x = btn.x;
            toolSelectCursor.y = btn.y;
            lastTool = childName;

            toolSelectCursor.alpha = btn.alpha;
        }

        public function initButtonsPos():void
        {
            const len:uint = buttonArr.length;

            buttonArr[0].x = 0;
            buttonArr[0].y = 0;
            buttonArr[0].useHandCursor = false;

            for (var i:uint = 1; i < len; i++)
            {
                buttonArr[i].x = buttonArr[i - 1].x;
                buttonArr[i].y = buttonArr[i - 1].y + buttonArr[i - 1].height + 2;
                buttonArr[i].useHandCursor = false;
            }

            toolFillPenOK.x = toolRedo.x;
            toolFillPenOK.y = toolRedo.y;
            toolFillPenCancel.x = toolPen.x;
            toolFillPenCancel.y = toolPen.y;
        }

        [Embed(
            source="fofoPaint-animate-27.13.swf",
            symbol="ToolMenuSet"
        )]
        private static const EmbeddedClass:Class;

        public function ToolMenuSet()
        {
            const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
            VisualBuilder.buildInto(this, EmbeddedClass, fields);
            moveToolCursorInit();

            toolSelectCursor.mouseEnabled = false;
            toolPen.useHandCursor = false;
            toolFillPen.useHandCursor = false;
            toolFillPenOK.useHandCursor = false;
            toolFillPenCancel.useHandCursor = false;
            toolEraser.useHandCursor = false;
            toolUndo.useHandCursor = false;
            toolRedo.useHandCursor = false;
            toolEyedropper.useHandCursor = false;
            toolMirror.useHandCursor = false;
            toolLasso.useHandCursor = false;
            toolMove.useHandCursor = false;
            toolRotate.useHandCursor = false;
            toolLine.useHandCursor = false;
            toolRefLayer.useHandCursor = false;
            toolZoomIn.useHandCursor = false;
            toolZoomOut.useHandCursor = false;
            toolHand.mouseEnabled = false;
            toolHand.visible = false;

            toolFillPenOK.visible = false;
            toolFillPenCancel.visible = false;

            buttonArr = [
                toolUndo,
                toolRedo,
                toolPen,
                toolEraser,
                toolFillPen,
                toolEyedropper,
                toolLine,
                toolLasso,
                toolMove,
                toolRefLayer,
                toolZoomIn,
                toolZoomOut,
                toolRotate,
                toolMirror,
                toolHand
            ];
            initButtonsPos();
        }
    }
}
