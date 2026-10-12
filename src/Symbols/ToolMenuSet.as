package Symbols
{
    import flash.display.Bitmap;
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Shape;
    import flash.display.SimpleButton;
    import flash.display.Sprite;
    import flash.geom.ColorTransform;
    import assets.VisualBuilder;
    import assets.VisualFieldCollector;
    import Modules.L1Data.UIEngine.UITheme;

    // 층: L4 UI - 툴 메뉴(툴박스) 화면 묶음
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

        private var bgBox:Shape = new Shape();
        private var deafultY:Number = 0;

        private const activeColor:ColorTransform = new ColorTransform();
        private const activeIconColor:ColorTransform = new ColorTransform();
        private var btn:SimpleButton;
        private var btnUp:DisplayObject;
        private var btnOver:DisplayObjectContainer;
        private var btnDown:DisplayObjectContainer;
        private var buttonArr:Array;

        private var checkedLayerONFlag:Boolean = false;
        private var toolSelectIconSourceVisual:Sprite = null; // 선택 툴 아이콘용으로 한 번만 만든 임베드 심볼 인스턴스; 여기서 버튼을 하나씩 꺼내 씀
        private const toolSelectViewEntryByButtonName:Object = {}; // 버튼 이름 -> {viewSprite, backgroundCircle, iconButton, circleX, circleY, circleRadius}

        // 마우스 옆에 잠깐 띄우는 선택 툴 아이콘: 배경 원 + 임베드 심볼에서 꺼낸 같은 이름의 버튼(벡터 그대로). 원 중심이 (0,0)
        // Animate로 그린 Shape는 graphics.copyFrom으로 복제되지 않아서 심볼 인스턴스에서 버튼을 직접 꺼내 보관하고, 테마 색만 표시할 때마다 다시 입힘
        public function getToolSelectViewSprite(toolButton:SimpleButton):Sprite
        {
            if (!toolSelectViewEntryByButtonName.hasOwnProperty(toolButton.name))
            {
                makeToolSelectViewEntry(toolButton);
            }

            const entry:Object = toolSelectViewEntryByButtonName[toolButton.name];
            const backgroundCircle:Shape = entry.backgroundCircle;

            backgroundCircle.graphics.clear();
            backgroundCircle.graphics.beginFill(UITheme.getUIBGColor(), 0.7);
            backgroundCircle.graphics.drawCircle(entry.circleX, entry.circleY, entry.circleRadius);
            backgroundCircle.graphics.endFill();
            UITheme.applyToolBoxButtonUpBGColor(entry.iconButton.upState);

            return entry.viewSprite;
        }

        private function makeToolSelectViewEntry(toolButton:SimpleButton):void
        {
            const extend:Number = 20;
            const scale:Number = this.scaleX;
            const iconBoxWidth:Number = toolButton.width / scale + extend;
            const iconBoxHeight:Number = toolButton.height / scale + extend;
            const iconBox:Sprite = new Sprite();
            const backgroundCircle:Shape = new Shape();
            const viewSprite:Sprite = new Sprite();

            if (toolSelectIconSourceVisual === null)
            {
                toolSelectIconSourceVisual = new EmbeddedClass() as Sprite;
            }

            const iconButton:SimpleButton = findButtonByNameIn(toolSelectIconSourceVisual, toolButton.name);

            iconButton.enabled = false;
            iconButton.scaleX = 1.0; // 예전 draw는 버튼 자신의 축소 변환을 무시하고 심볼 원래 크기로 그렸으므로 같게 맞춤
            iconButton.scaleY = 1.0;
            iconButton.x = 5;
            iconButton.y = 5;
            iconBox.addChild(backgroundCircle);
            iconBox.addChild(iconButton);
            iconBox.x = -iconBoxWidth / 2;
            iconBox.y = -iconBoxHeight / 2;
            viewSprite.addChild(iconBox);

            toolSelectViewEntryByButtonName[toolButton.name] = {
                    viewSprite: viewSprite,
                    backgroundCircle: backgroundCircle,
                    iconButton: iconButton,
                    circleX: iconBoxWidth / 2,
                    circleY: iconBoxHeight / 2,
                    circleRadius: toolButton.width / scale / 2 + extend / 2
                };
        }

        private function findButtonByNameIn(root:DisplayObjectContainer, buttonName:String):SimpleButton
        {
            const found:DisplayObject = root.getChildByName(buttonName);

            if (found is SimpleButton)
            {
                return found as SimpleButton;
            }

            for (var i:int = 0; i < root.numChildren; i++)
            {
                const childContainer:DisplayObjectContainer = root.getChildAt(i) as DisplayObjectContainer;

                if (childContainer !== null)
                {
                    const foundInChild:SimpleButton = findButtonByNameIn(childContainer, buttonName);

                    if (foundInChild !== null)
                    {
                        return foundInChild;
                    }
                }
            }

            return null;
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
            const offAlpha:Number = UITheme.OFFALPHA;
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
            const offalpha:Number = UITheme.OFFALPHA;
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
            for (i = 0;i < buttonArr.length;i++)
            {
                btn = buttonArr[i] as SimpleButton;
                UITheme.applyToolBoxButtonUpBGColor(btn.upState as DisplayObject);
                UITheme.setButtonColorWithBG(btn.overState as DisplayObjectContainer, 4, 2, 0.0);
                UITheme.setButtonColorWithBG(btn.downState as DisplayObjectContainer, 4, 2, 0.0);
                btn.downState.x = 2;
                btn.downState.y = 2;
            }

            const fillPenButtons:Array = [toolFillPenOK, toolFillPenCancel];
            for (i = 0;i < fillPenButtons.length;i++)
            {
                btn = fillPenButtons[i] as SimpleButton;
                UITheme.applyToolBoxButtonUpBGColor(btn.upState as DisplayObject);
                UITheme.setButtonColorWithBG(btn.overState as DisplayObjectContainer, 4, 2, 0.0);
                UITheme.setButtonColorWithBG(btn.downState as DisplayObjectContainer, 4, 2, 0.0);
                btn.downState.x = 2;
                btn.downState.y = 2;
            }

            const rotateButtonDownState:DisplayObjectContainer = toolRotate.downState as DisplayObjectContainer;
            rotateButtonDownState.x = 0;
            rotateButtonDownState.y = 0;
            toolHand.x = 0;
            toolHand.y = 0;

            bgBox.graphics.lineStyle(0, 0, 0);
            bgBox.graphics.beginFill(UITheme.getToolBoxBGColor());
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

        private function initializeMoveToolCursor():void
        {
            setToolSelectCursorPositionTo(lastTool);
        }

        public function setToolSelectCursorPositionTo(childName:String, newParent:DisplayObjectContainer = null):void
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

        private function initButtonsPos():void
        {
            const len:uint = buttonArr.length;

            buttonArr[0].x = 0;
            buttonArr[0].y = 0;
            buttonArr[0].useHandCursor = false;

            for (var i:uint = 1;i < len;i++)
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

        [Embed(source="fofoPaint-animate-27.13.swf",symbol="ToolMenuSet")]
        private static const EmbeddedClass:Class;

        public function ToolMenuSet()
        {
            const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
            VisualBuilder.buildInto(this, EmbeddedClass, fields);
            initializeMoveToolCursor();

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
                    toolRefLayer,
                    toolUndo,
                    toolRedo,
                    toolPen,
                    toolEraser,
                    toolFillPen,
                    toolEyedropper,
                    toolLine,
                    toolLasso,
                    toolMove,
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
