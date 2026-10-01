package Modules.DrawEngine
{
    import Modules.CanvasController;
    import Modules.ImageViewWindow;
    import Modules.InputPriority;
    import Modules.MouseState;
    import Modules.PenSizePreviewCursor;
    import Modules.ToolController;
    import Modules.UndoController;
    import Modules.UndoHistory;
    import Modules.Utils;
    import Modules.CaptureEngine.CaptureController;
    import Modules.InputManager.InputManager;
    import Modules.ReplayEngine.ReplayState;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;
    import Modules.UIEngine.UITheme;

    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.geom.Point;

    // 캔버스 상하좌우 리사이즈 버튼과 드래그로 캔버스 크기 조절
    public class CanvasResizer
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static const CANVAS_MIN_SIZE:Number = 100;
        private static const RATIO_LIST:Array = [
                "1:2", (1.0 / 2.0),
                "9:16", (9.0 / 16.0),
                "10:16", (10.0 / 16.0),
                "3:4", (3.0 / 4.0),
                "1:1", 1.0,
                "4:3", (4.0 / 3.0),
                "16:10", (16.0 / 10.0),
                "16:9", (16.0 / 9.0),
                "2:1", 2.0
            ];

        private static const
            resizeButtonR:Sprite = new Sprite(), // 캔버스 리사이즈 하는 버튼
            resizeButtonD:Sprite = new Sprite(),
            resizeButtonL:Sprite = new Sprite(),
            resizeButtonU:Sprite = new Sprite();

        private static const resizePreviewRect:Shape = new Shape();
        private static const resizePreviewRatioRect:Shape = new Shape();
        private static const resizeClickPos:Point = new Point(0, 0);
        private static const ratioGuidePosBackUp:Point = new Point(0, 0);

        private static var started:Boolean = false;
        private static var subX:Number = 0;
        private static var subY:Number = 0;
        private static var ratioSizeArr:Array = [];
        private static var guideLineWidth:Number = 0;
        private static var isResizingWidth:Boolean = false; // 가로인지 새로인지 결정
        private static var targetName:String;
        private static var oldWidth:Number;
        private static var oldHeight:Number;
        private static var bgColor:uint;
        private static var stageColor:uint;
        private static var finalWidth:uint;
        private static var finalHeight:uint;
        private static var canvasSizeChanging:Boolean;
        private static var rightMouseupEventON:Boolean = false;

        public static function init():void
        {
            function drawRect(target:Sprite):void
            {
                target.visible = false;
                target.graphics.clear();
                target.graphics.beginFill(0xFF0000);
                target.graphics.drawRect(0, 0, 10, 10);
                target.graphics.endFill();
            }
            resizeButtonU.name = "resizeButtonU";
            resizeButtonD.name = "resizeButtonD";
            resizeButtonR.name = "resizeButtonR";
            resizeButtonL.name = "resizeButtonL";

            drawRect(resizeButtonU);
            drawRect(resizeButtonD);
            drawRect(resizeButtonL);
            drawRect(resizeButtonR);

            CanvasController.canvasAnchorPoint.addChild(resizeButtonU);
            CanvasController.canvasAnchorPoint.addChild(resizeButtonD);
            CanvasController.canvasAnchorPoint.addChild(resizeButtonR);
            CanvasController.canvasAnchorPoint.addChild(resizeButtonL);
        }

        public static function start(_targetName:String):void
        {
            PenSizePreviewCursor.setCursorInVisibleFlag(true);
            PenSizePreviewCursor.setVisible(false);
            HintController.showMouseHint(CanvasController.CANVAS_WIDTH + " x " + CanvasController.CANVAS_HEIGHT);

            // TODO:Drag인터렉션으로 변환
            if (started === false)
            {
                started = true;
                initVars();
            }
            targetName = _targetName;
            resizeClickPos.setTo(CanvasController.canvasPanel.mouseX, CanvasController.canvasPanel.mouseY);
            canvasSizeChanging = true;
            drawRatioSnapGuide(oldWidth, oldHeight, targetName);
            updateRatioSnapGuidePos();

            if (ToolController.isToolBox2Showing)
            {
                ToolController.closeToolBox2();
            }

            updateButtonVisible(false);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, resizeButtonMouseUpEvent, false, InputPriority.DEFAULT);
            if (rightMouseupEventON === false)
            {
                rightMouseupEventON = true;
                main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, resizeButtonRightMouseUpEvent, false, InputPriority.DEFAULT);
            }
            var onMouseMove:Function;
            if (targetName === "resizeButtonL")
                onMouseMove = onMouseMoveReizeButtonL;
            else if (targetName === "resizeButtonR")
                onMouseMove = onMouseMoveReizeButtonR;
            else if (targetName === "resizeButtonU")
                onMouseMove = onMouseMoveReizeButtonU;
            else if (targetName === "resizeButtonD")
                onMouseMove = onMouseMoveReizeButtonD;
            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        }

        public static function exit():void
        {
            if (started)
            {
                started = false;
                if (targetName !== null)
                {
                    main.stage.removeEventListener(MouseEvent.MOUSE_UP, resizeButtonMouseUpEvent);
                    if (!MouseState.isRightDown)
                    {
                        rightMouseupEventON = false;
                        main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, resizeButtonRightMouseUpEvent);
                    }
                    if (targetName === "resizeButtonL")
                        main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveReizeButtonL);
                    else if (targetName === "resizeButtonR")
                        main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveReizeButtonR);
                    else if (targetName === "resizeButtonU")
                        main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveReizeButtonU);
                    else if (targetName === "resizeButtonD")
                        main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveReizeButtonD);
                }
                canvasSizeChanging = false;
                HintController.hideMouseHint();
                updateButtonVisible((isMouseCursorInStage() && MouseState.isRightDown) || InputManager.isPressingControl());
                CanvasController.canvasAnchorPoint.removeChild(resizePreviewRect);
                CanvasController.canvasAnchorPoint.removeChild(resizePreviewRatioRect);
                resizePreviewRect.graphics.clear();
                resizePreviewRatioRect.graphics.clear();
                if (subX !== 0 || subY !== 0)
                {
                    const centerMovedFlag:Boolean = (targetName === "resizeButtonL" || targetName === "resizeButtonU") ? true : false;
                    if (UndoController.isDeepUndoEnabled)
                    {
                        UndoController.applyDeepUndo();
                    }
                    CanvasController.applyCavnvasSizeDrawMode(finalWidth, finalHeight, subX, subY, centerMovedFlag);
                    updateButtonPos(finalWidth, finalHeight);
                    ReplayState.pushCommand(["canvasSize", finalWidth, finalHeight, subX, subY, centerMovedFlag]);
                    UndoHistory.addNew();
                    if (ImageViewWindow.isCanvasWindowON)
                    {
                        ImageViewWindow.updateCanvasWindowBitmapSize();
                    }
                }
                targetName = null;
            }
            else
            {
                updateButtonVisible(false);
                rightMouseupEventON = false;
                main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, resizeButtonRightMouseUpEvent);
            }
        }

        public static function isResizing():Boolean
        {
            return started;
        }

        public static function isCanvasResizing():Boolean
        {
            return canvasSizeChanging;
        }

        public static function isButtonVisible():Boolean
        {
            return resizeButtonR.visible;
        }

        public static function updateButtonPos(width:Number, height:Number):void
        {
            function setpos(target:Sprite, x:Number, y:Number, w:Number, h:Number):void
            {
                target.x = x;
                target.y = y;
                target.width = (w === 0) ? buttonSize : w;
                target.height = (h === 0) ? buttonSize : h;
            }

            const z:Number = 1 / CanvasController.canvasZoomMultipler;
            const buttonSize:Number = 20 * z;
            const buttonSize2:Number = 40 * z;
            const cpPosX:Number = CanvasController.canvasPanel.x;
            const cpPosY:Number = CanvasController.canvasPanel.y;
            const top:Number = cpPosY - buttonSize;
            const bottom:Number = cpPosY + height;
            const left:Number = cpPosX - buttonSize;
            const right:Number = cpPosX + width;

            setpos(resizeButtonU, left, top, width + buttonSize2, 0);
            setpos(resizeButtonD, left, bottom, width + buttonSize2, 0);
            setpos(resizeButtonL, left, top, 0, height + buttonSize);
            setpos(resizeButtonR, right, top, 0, height + buttonSize);
        }

        public static function updateButtonVisible(flag:Boolean):void
        {
            if (resizeButtonR.visible === flag)
            {
                return;
            }

            if (flag)
            {
                updateButtonPos(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
                showButtons();
            }
            else
            {
                hideButtons();
            }
        }

        public static function showButtonsWithDelay(flag:Boolean):void
        {
            if (flag)
            {
                updateButtonPos(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
                ToolController.toolBox2.startResizeButtonWaitPrograssBarAnimation();
                FOFOTimer.addByName("resizeButtonVisibleDelayTimer", 0.9, false, function ():void
                    {
                        showButtons();
                        fadeInTransparentBG();
                    });
            }
            else
            {
                FOFOTimer.remove("resizeButtonVisibleDelayTimer");
                hideButtons();
                fadeOutTransparentBG();
            }
        }

        public static function setButtonColor():void
        {
            const color:uint = UITheme.getUIResizeBarColor();

            Utils.setColorTransform(resizeButtonL, color);
            Utils.setColorTransform(resizeButtonR, color);
            Utils.setColorTransform(resizeButtonU, color);
            Utils.setColorTransform(resizeButtonD, color);
        }

        private static function hideButtons():void
        {
            PenSizePreviewCursor.setCursorInVisibleFlag(false);
            resizeButtonR.visible = false;
            resizeButtonL.visible = false;
            resizeButtonD.visible = false;
            resizeButtonU.visible = false;
        }

        private static function showButtons():void
        {
            PenSizePreviewCursor.setCursorInVisibleFlag(true);
            resizeButtonR.visible = true;
            resizeButtonL.visible = true;
            resizeButtonD.visible = true;
            resizeButtonU.visible = true;
        }

        // 리사이즈 버튼이 보일때 캔버스 뒤에 투명 배경 격자를 서서히 보여줌
        private static function fadeOutTransparentBG():void
        {
            const canvasPanel:Sprite = CanvasController.canvasPanel;
            const canvasFlashEffect:Sprite = CanvasController.canvasFlashEffect;
            if (!canvasPanel.getChildByName("canvasFlash"))
            {
                return;
            }
            const fadeStep:Number = Math.floor(0.1 * 256) / 256;
            FOFOTimer.addByName("viewTransBGTimer", 0.0, true, function ():Boolean
                {
                    if (canvasFlashEffect.alpha < 0.0 || CaptureController.isCaptureModeON)
                    {
                        canvasFlashEffect.alpha = 0.0;
                        canvasFlashEffect.visible = false;
                        canvasFlashEffect.graphics.clear();
                        if (canvasPanel.getChildByName("canvasFlash"))
                        {
                            canvasPanel.removeChild(canvasFlashEffect);
                        }
                        return false;
                    }
                    canvasFlashEffect.alpha -= fadeStep;
                    return true;
                });
        }

        private static function fadeInTransparentBG():void
        {
            const canvasPanel:Sprite = CanvasController.canvasPanel;
            const canvasFlashEffect:Sprite = CanvasController.canvasFlashEffect;
            if (!canvasPanel.getChildByName("canvasFlash"))
            {
                canvasPanel.addChild(canvasFlashEffect);
                canvasPanel.setChildIndex(canvasFlashEffect, 0);
                canvasFlashEffect.visible = true;
                canvasFlashEffect.graphics.beginBitmapFill(CaptureController.capTransparentBGBMPD);
                canvasFlashEffect.graphics.drawRect(0, 0, CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT);
                canvasFlashEffect.graphics.endFill();
                canvasFlashEffect.alpha = 0.0;
            }
            if (canvasFlashEffect.alpha >= 1.0)
            {
                return;
            }
            const fadeStep:Number = Math.floor(0.1 * 256) / 256;
            FOFOTimer.addByName("viewTransBGTimer", 0.0, true, function ():Boolean
                {
                    if (canvasFlashEffect.alpha >= 1.0 || CaptureController.isCaptureModeON)
                    {
                        canvasFlashEffect.alpha = 1.0;
                        return false;
                    }
                    canvasFlashEffect.alpha += fadeStep;
                    return true;
                });
        }

        private static function initVars():void
        {
            oldWidth = CanvasController.CANVAS_WIDTH;
            oldHeight = CanvasController.CANVAS_HEIGHT;
            finalWidth = oldWidth;
            finalHeight = oldHeight;
            bgColor = CanvasController.CANVAS_BG_COLOR;
            stageColor = UIController.STAGE_BG_COLOR;
            subX = 0;
            subY = 0;
            canvasSizeChanging = false;
            resizePreviewRect.x = CanvasController.canvasPanel.x;
            resizePreviewRect.y = CanvasController.canvasPanel.y;
            resizePreviewRatioRect.x = resizePreviewRect.x;
            resizePreviewRatioRect.y = resizePreviewRect.y;
            ratioGuidePosBackUp.setTo(resizePreviewRatioRect.x, resizePreviewRatioRect.y);
            guideLineWidth = 30 / CanvasController.canvasZoomMultipler;
            CanvasController.canvasAnchorPoint.addChild(resizePreviewRect);
            CanvasController.canvasAnchorPoint.addChild(resizePreviewRatioRect);
            Utils.setAsTopChild(resizePreviewRect);
            Utils.setAsTopChild(resizePreviewRatioRect);
        }

        private static function updateRatioSnapGuidePos():void
        {
            if (isResizingWidth)
            {
                if (CanvasController.canvasPanel.mouseY > oldHeight / 2)
                {
                    if (resizePreviewRatioRect.y === ratioGuidePosBackUp.y)
                    {
                        resizePreviewRatioRect.y = ratioGuidePosBackUp.y + oldHeight + guideLineWidth;
                    }
                }
                else if (resizePreviewRatioRect.y !== ratioGuidePosBackUp.y)
                {
                    resizePreviewRatioRect.y = ratioGuidePosBackUp.y;
                }
            }
            else
            {
                if (CanvasController.canvasPanel.mouseX > oldWidth / 2)
                {
                    if (resizePreviewRatioRect.x === ratioGuidePosBackUp.x)
                    {
                        resizePreviewRatioRect.x = ratioGuidePosBackUp.x + oldWidth + guideLineWidth;
                    }
                }
                else if (resizePreviewRatioRect.x !== ratioGuidePosBackUp.x)
                {
                    resizePreviewRatioRect.x = ratioGuidePosBackUp.x;
                }
            }
        }

        private static function getNearestRatio(width:Number):Array
        {
            var index:Number = Utils.binarySearchIndex(ratioSizeArr, width, function (item:*):Number
                {
                    return item[0];
                });
            return ratioSizeArr[index + 1];
        }

        private static function drawRatioSnapGuide(w:Number, h:Number, target:String):void
        {
            const min:Number = CANVAS_MIN_SIZE;
            const max:Number = CanvasController.CANVAS_MAX_SIZE;
            isResizingWidth = (target === "resizeButtonL" || target === "resizeButtonR") ? true : false;
            function _drawRatioLine(referenceSize:Number, offset:Number):void
            {
                ratioSizeArr = [];
                // hittestpoint를 위해서 배경을 그려줌
                resizePreviewRatioRect.graphics.beginFill(0xFFFF00, 0.0);
                if (isResizingWidth)
                    resizePreviewRatioRect.graphics.drawRect(-max / 2, -guideLineWidth, max * 2, guideLineWidth);
                else
                    resizePreviewRatioRect.graphics.drawRect(-guideLineWidth, -max / 2, guideLineWidth, max * 2);
                resizePreviewRatioRect.graphics.endFill();
                const color:uint = UITheme.getUIFGColor();
                var snapGuideStartPos:Number; // 스냅 격자 그려주는 위치
                var scaledSize:Number; // 스냅 걸릴때 실제 사이즈
                const len:uint = RATIO_LIST.length;
                const flipFlag:Boolean = (target === "resizeButtonU" || target === "resizeButtonL") ? true : false;
                for (var i:uint = 0;i < len;i += 2)
                {
                    scaledSize = Math.round(referenceSize * RATIO_LIST[i + 1]);
                    snapGuideStartPos = scaledSize;
                    if (scaledSize > max || scaledSize < min)
                    {
                        continue;
                    }
                    resizePreviewRatioRect.graphics.lineStyle(3 / CanvasController.canvasZoomMultipler, color, 1.0, true, "normal", "none");
                    if (flipFlag)
                    {
                        snapGuideStartPos = -snapGuideStartPos + offset;
                    }
                    if (isResizingWidth)
                    {
                        resizePreviewRatioRect.graphics.moveTo(snapGuideStartPos, 0);
                        resizePreviewRatioRect.graphics.lineTo(snapGuideStartPos, -guideLineWidth);
                    }
                    else
                    {
                        resizePreviewRatioRect.graphics.moveTo(0, snapGuideStartPos);
                        resizePreviewRatioRect.graphics.lineTo(-guideLineWidth, snapGuideStartPos);
                    }
                    ratioSizeArr.push([scaledSize, RATIO_LIST[i]]);
                }
            }
            if (isResizingWidth) // 가로 조절
            {
                _drawRatioLine(h, w);
            }
            else
            {
                _drawRatioLine(w, h);
            }
        }

        private static function isMouseCursorInStage():Boolean
        {
            return main.stage.mouseX >= 0 && main.stage.mouseY >= 0 && main.stage.mouseX <= main.stage.stageWidth && main.stage.mouseY <= main.stage.stageHeight;
        }

        private static function resizeButtonRightMouseUpEvent(e:MouseEvent):void
        {
            exit();
        }

        private static function resizeButtonMouseUpEvent(e:MouseEvent):void
        {
            exit();
        }

        private static function drawResizePreviewRect(size:Number, x:Number, y:Number, w:Number, h:Number):void
        {
            resizePreviewRect.graphics.clear();
            if (size > 0)
            {
                resizePreviewRect.graphics.beginFill(bgColor);
            }
            else
            {
                resizePreviewRect.graphics.beginFill(stageColor);
            }
            resizePreviewRect.graphics.drawRect(x, y, w, h);
            updateRatioSnapGuidePos();
        }

        private static function flipRatioString(r:String):String
        {
            var p:Array = r.split(":");
            return p[1] + ":" + p[0];
        }

        private static function updateHeight(flipFlag:Boolean):Number
        {
            const min:Number = CANVAS_MIN_SIZE;
            const max:Number = CanvasController.CANVAS_MAX_SIZE;
            subY = (flipFlag) ? resizeClickPos.y - CanvasController.canvasPanel.mouseY
                : CanvasController.canvasPanel.mouseY - resizeClickPos.y;
            var height:Number = (oldHeight + subY < min) ? min :
                (oldHeight + subY > max) ? max :
                Math.floor(oldHeight + subY);
            if (height === max)
                subY = max - oldHeight;
            else if (height === min)
                subY = min - oldHeight;
            if (resizePreviewRatioRect.hitTestPoint(main.stage.mouseX, main.stage.mouseY, true))
            {
                const info:Array = getNearestRatio(height);
                if (info)
                {
                    subY = info[0] - oldHeight;
                    finalHeight = info[0];
                    const str:String = flipRatioString(info[1]);
                    HintController.showMouseHint(oldWidth + " x " + finalHeight + " (" + str + ")");
                    return subY;
                }
            }
            finalHeight = height;
            HintController.showMouseHint(oldWidth + " x " + finalHeight);
            return subY;
        }

        private static function updateWidth(flipFlag:Boolean):Number
        {
            const min:Number = CANVAS_MIN_SIZE;
            const max:Number = CanvasController.CANVAS_MAX_SIZE;
            subX = (flipFlag) ? resizeClickPos.x - CanvasController.canvasPanel.mouseX
                : CanvasController.canvasPanel.mouseX - resizeClickPos.x;
            var width:Number = (oldWidth + subX < min) ? min :
                (oldWidth + subX > max) ? max :
                Math.floor(oldWidth + subX);
            if (width === max)
                subX = max - oldWidth;
            else if (width === min)
                subX = min - oldWidth;
            if (resizePreviewRatioRect.hitTestPoint(main.stage.mouseX, main.stage.mouseY, true))
            {
                const info:Array = getNearestRatio(width);
                if (info)
                {
                    subX = info[0] - oldWidth;
                    finalWidth = info[0];
                    HintController.showMouseHint(oldWidth + " x " + finalHeight + " (" + info[1] + ")");
                    return subX;
                }
            }
            finalWidth = width;
            HintController.showMouseHint(finalWidth + " x " + oldHeight);
            return subX;
        }

        private static function onMouseMoveReizeButtonD(e:MouseEvent):void
        {
            const dy:Number = updateHeight(false);
            drawResizePreviewRect(dy, 0, oldHeight, oldWidth, dy);
        }

        private static function onMouseMoveReizeButtonU(e:MouseEvent):void
        {
            const dy:Number = updateHeight(true);
            drawResizePreviewRect(dy, 0, -dy, oldWidth, dy);
        }

        private static function onMouseMoveReizeButtonR(e:MouseEvent):void
        {
            const dx:Number = updateWidth(false);
            drawResizePreviewRect(dx, oldWidth, 0, dx, oldHeight);
        }

        private static function onMouseMoveReizeButtonL(e:MouseEvent):void
        {
            const dx:Number = updateWidth(true);
            drawResizePreviewRect(dx, -dx, 0, dx, oldHeight);
        }
    }
}
