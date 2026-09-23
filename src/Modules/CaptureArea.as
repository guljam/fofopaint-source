package Modules
{
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    public class CaptureArea
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static var captureDragAreaOverlay:Shape = new Shape(); // 스크린샷 박스 미리보기 그려줌
        private static var xPanel:Sprite;
        private static var mouseMoved:Boolean = false;
        private static var canvasWidth:Number = 0;
        private static var canvasHeight:Number = 0;
        private static var clickPos:Point = new Point(0, 0);
        private static var limitWidthSave:Number = 0;
        private static var limitHeightSave:Number = 0;
        private static const rectFull:Rectangle = new Rectangle();
        private static const rectRaw:Rectangle = new Rectangle();
        private static const rectClamped:Rectangle = new Rectangle();
        private static var resizeFlag:Boolean = false;
        private static const resizeButtonSize:Number = 14.0;
        private static const resizeButtonPos:Point = new Point(0, 0);
        private static var minSize:Number = 10.0;
        private static const mouseMoveOffset:Number = 5.0;

        private static function validateCaptureArea():void
        {
            var intersection:Rectangle = rectFull.intersection(rectClamped);
            if (intersection.width >= minSize && intersection.height >= minSize)
            {
                rectClamped.x = Math.round(intersection.x);
                rectClamped.y = Math.round(intersection.y);
                rectClamped.width = Math.round(intersection.width);
                rectClamped.height = Math.round(intersection.height);
            }
            else
            {
                FOFOTimer.add(0.0, false, function ():void
                    {
                        resetCaptureArea();
                    });
            }
        }

        private static function normalizeRectClamped():void
        {
            if (rectClamped.width < 0)
            {
                rectClamped.width = Math.abs(rectClamped.width);
                rectClamped.x = rectClamped.x - rectClamped.width;
            }
            if (rectClamped.height < 0)
            {
                rectClamped.height = Math.abs(rectClamped.height);
                rectClamped.y = rectClamped.y - rectClamped.height;
            }
        }

        private static function onMouseMoveCaptureAreaDrawed(e:MouseEvent):void
        {
            if (!CaptureController.isCaptureModeON)
            {
                removeCaptureAreaEvents();
                return;
            }

            const mx:Number = xPanel.mouseX;
            const my:Number = xPanel.mouseY;
            var subX:Number = Math.round(mx - clickPos.x);
            var subY:Number = Math.round(my - clickPos.y);

            if (mouseMoved === true)
            {
                if (resizeFlag)
                {
                    if (!CaptureController.isCaptureCanvasFlipped && CaptureController.captureCanvasRotationStep === 0
                            || CaptureController.isCaptureCanvasFlipped && CaptureController.captureCanvasRotationStep === 3)
                    {
                        rectRaw.width += subX;
                        rectRaw.height += subY;
                        rectClamped.width = rectRaw.width;
                        rectClamped.height = rectRaw.height;

                        if (rectClamped.width < minSize)
                            rectClamped.width = minSize;
                        else if (rectClamped.x + rectClamped.width > canvasWidth)
                            rectClamped.width = canvasWidth - rectClamped.x;

                        if (rectClamped.height < minSize)
                            rectClamped.height = minSize;
                        else if (rectClamped.y + rectClamped.height > canvasHeight)
                            rectClamped.height = canvasHeight - rectClamped.y;
                    }
                    else if (!CaptureController.isCaptureCanvasFlipped && CaptureController.captureCanvasRotationStep === 1
                            || CaptureController.isCaptureCanvasFlipped && CaptureController.captureCanvasRotationStep === 2)
                    {
                        rectRaw.width += subX;
                        rectRaw.height -= subY;
                        rectRaw.y += subY;
                        rectClamped.width = rectRaw.width;
                        rectClamped.height = rectRaw.height;
                        rectClamped.y = rectRaw.y;

                        if (rectClamped.y < 0.0)
                        {
                            rectClamped.y = 0.0;
                            rectClamped.height = limitHeightSave;
                        }
                        if (rectClamped.height < minSize)
                        {
                            rectClamped.height = minSize;
                            rectClamped.y = limitHeightSave - rectClamped.height;
                        }
                        if (rectClamped.width < minSize)
                            rectClamped.width = minSize;
                        else if (rectClamped.x + rectClamped.width > canvasWidth)
                            rectClamped.width = canvasWidth - rectClamped.x;
                    }
                    else if (!CaptureController.isCaptureCanvasFlipped && CaptureController.captureCanvasRotationStep === 2
                            || CaptureController.isCaptureCanvasFlipped && CaptureController.captureCanvasRotationStep === 1)
                    {
                        rectRaw.width -= subX;
                        rectRaw.height -= subY;
                        rectRaw.x += subX;
                        rectRaw.y += subY;
                        rectClamped.width = rectRaw.width;
                        rectClamped.height = rectRaw.height;
                        rectClamped.x = rectRaw.x;
                        rectClamped.y = rectRaw.y;

                        if (rectClamped.width < minSize)
                        {
                            rectClamped.width = minSize;
                            rectClamped.x = limitWidthSave - rectClamped.width;
                        }
                        if (rectClamped.height < minSize)
                        {
                            rectClamped.height = minSize;
                            rectClamped.y = limitHeightSave - rectClamped.height;
                        }
                        if (rectClamped.x < 0.0)
                        {
                            rectClamped.x = 0.0;
                            rectClamped.width = limitWidthSave;
                        }
                        if (rectClamped.y < 0.0)
                        {
                            rectClamped.y = 0.0;
                            rectClamped.height = limitHeightSave;
                        }
                    }
                    else if (!CaptureController.isCaptureCanvasFlipped && CaptureController.captureCanvasRotationStep === 3
                            || CaptureController.isCaptureCanvasFlipped && CaptureController.captureCanvasRotationStep === 0)
                    {
                        rectRaw.width -= subX;
                        rectRaw.height += subY;
                        rectRaw.x += subX;
                        rectClamped.width = rectRaw.width;
                        rectClamped.height = rectRaw.height;
                        rectClamped.x = rectRaw.x;

                        if (rectClamped.x < 0.0)
                        {
                            rectClamped.x = 0.0;
                            rectClamped.width = limitWidthSave;
                        }
                        if (rectClamped.width < minSize)
                        {
                            rectClamped.width = minSize;
                            rectClamped.x = limitWidthSave - rectClamped.width;
                        }
                        if (rectClamped.height < minSize)
                        {
                            rectClamped.height = minSize;
                        }
                        else if (rectClamped.y + rectClamped.height > canvasHeight)
                        {
                            rectClamped.height = canvasHeight - rectClamped.y;
                        }
                    }
                    MainUI.showBottomHint(getRotatedRectSizeString());
                }
                else
                {
                    rectRaw.x += subX;
                    rectRaw.y += subY;
                    rectClamped.x = rectRaw.x;
                    rectClamped.y = rectRaw.y;

                    if (rectClamped.x < 0.0)
                    {
                        rectClamped.x = 0.0;
                    }
                    else if (rectClamped.x + rectClamped.width > canvasWidth)
                    {
                        rectClamped.x = canvasWidth - rectClamped.width;
                    }

                    if (rectClamped.y < 0.0)
                    {
                        rectClamped.y = 0.0;
                    }
                    else if (rectClamped.y + rectClamped.height > canvasHeight)
                    {
                        rectClamped.y = canvasHeight - rectClamped.height;
                    }
                }
                rectClamped.x = Math.round(rectClamped.x);
                rectClamped.y = Math.round(rectClamped.y);
                rectClamped.width = Math.round(rectClamped.width);
                rectClamped.height = Math.round(rectClamped.height);
                clickPos.setTo(xPanel.mouseX, xPanel.mouseY);
                drawArea(false);
            }
            else if (Math.abs(subX) >= mouseMoveOffset || Math.abs(subY) >= mouseMoveOffset)
            {
                mouseMoved = true;
                clickPos.setTo(mx, my);
                CaptureStamp.setVisible(false);
            }
        }

        private static function onMouseMoveDrawCaptureArea(e:MouseEvent):void
        {
            if (!CaptureController.isCaptureModeON)
            {
                removeCaptureAreaEvents();
                return;
            }

            var mx:Number = xPanel.mouseX;
            var my:Number = xPanel.mouseY;
            var subX:Number = Math.round(mx - clickPos.x);
            var subY:Number = Math.round(my - clickPos.y);

            if (mouseMoved)
            {
                rectRaw.width = subX;
                rectRaw.height = subY;
                rectClamped.x = rectRaw.x;
                rectClamped.y = rectRaw.y;
                rectClamped.width = rectRaw.width;
                rectClamped.height = rectRaw.height;
                normalizeRectClamped();
                MainUI.showBottomHint(getRotatedRectSizeString());
                drawArea(false);
            }
            else if (Math.abs(subX) >= mouseMoveOffset || Math.abs(subY) >= mouseMoveOffset)
            {
                rectRaw.x = clickPos.x;
                rectRaw.y = clickPos.y;
                rectRaw.width = subX;
                rectRaw.height = subY;
                rectClamped.x = rectRaw.x;
                rectClamped.y = rectRaw.y;
                rectClamped.width = rectRaw.width;
                rectClamped.height = rectRaw.height;
                clickPos.setTo(mx, my);
                MainUI.showBottomHint(getRotatedRectSizeString());
                mouseMoved = true;
                CaptureStamp.setVisible(false);
            }
        }

        private static function onMouseUpCaptureArea(e:MouseEvent):void
        {
            CanvasController.isMouseDragging = false;
            removeCaptureAreaEvents();

            if (mouseMoved === true)
            {
                // rect길이가 음수인경우 cx cy를 양수로 다시 맞추어줌
                normalizeRectClamped();
                validateCaptureArea();
                MainUI.topBar.capClipBoard.alpha = 1.0;
                drawArea(true);
                CaptureStamp.update();
            }
            mouseMoved = false;
        }

        private static function removeCaptureAreaEvents():void
        {
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveDrawCaptureArea);
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveCaptureAreaDrawed);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpCaptureArea);
        }

        public static function updateDrawArea(forceFlag:Boolean = false):void
        {
            if (rectClamped.width > minSize && rectClamped.height > minSize || forceFlag)
            {
                drawArea(true);
            }
            CaptureStamp.update();
        }

        private static function getCanvasScale():Number
        {
            return (ReplayController.isReplayModeON) ? Math.abs(ReplayController.rCanvasAnchorPoint.scaleX) : Math.abs(CanvasController.canvasAnchorPoint.scaleX);
        }

        private static function drawResizeButton(scale:Number):void
        {
            if (isFullImageCapture())
            {
                return;
            }

            captureDragAreaOverlay.graphics.lineStyle(1, 0xFFFFFF, 1.0, true);
            captureDragAreaOverlay.graphics.beginFill(0xFF6600);

            var posX:Number = rectClamped.x;
            var posY:Number = rectClamped.y;
            const offset:Number = 0;

            if (!CaptureController.isCaptureCanvasFlipped && CaptureController.captureCanvasRotationStep === 0
                    || CaptureController.isCaptureCanvasFlipped && CaptureController.captureCanvasRotationStep === 3)
            {
                posX += rectClamped.width + offset;
                posY += rectClamped.height + offset;
            }
            else if (!CaptureController.isCaptureCanvasFlipped && CaptureController.captureCanvasRotationStep === 1
                    || CaptureController.isCaptureCanvasFlipped && CaptureController.captureCanvasRotationStep === 2)
            {
                posX += rectClamped.width + offset;
                posY += -offset;
            }
            else if (!CaptureController.isCaptureCanvasFlipped && CaptureController.captureCanvasRotationStep === 3
                    || CaptureController.isCaptureCanvasFlipped && CaptureController.captureCanvasRotationStep === 0)
            {
                posY += rectClamped.height + offset;
                posX += -offset;
            }
            else
            {
                posX += -offset;
                posY += -offset;
            }

            resizeButtonPos.setTo(posX, posY);

            const longEdge:Number = resizeButtonSize / scale;
            const shortEdge:Number = (resizeButtonSize / 3) / scale;
            const cmd:Vector.<int> = new <int>[1, 2, 2, 2, 2, 2, 2];
            const pos:Vector.<Number> = new <Number>[
                    0, 0,
                    0, -longEdge,
                    shortEdge, -longEdge,
                    shortEdge, shortEdge,
                    -longEdge, shortEdge,
                    -longEdge, 0,
                    0, 0
                ];
            const len:uint = pos.length;
            var p:Point;

            for (var i:uint = 0;i < len;i += 2)
            {
                p = Utils.rotatePoint(pos[i], pos[i + 1], CaptureController.captureCanvasRotationStep * 90.0);
                pos[i] = posX + p.x * ((CaptureController.isCaptureCanvasFlipped) ? -1.0 : 1.0);
                pos[i + 1] = posY + p.y;
            }

            captureDragAreaOverlay.graphics.drawPath(cmd, pos);
            captureDragAreaOverlay.graphics.endFill();
        }

        private static function drawArea(resizeButtonON:Boolean):void
        {
            const zoomed:Number = getCanvasScale();
            const lineSize:Number = Math.ceil(1 / zoomed);

            captureDragAreaOverlay.graphics.clear();
            // 배경색 약간 어둡게 해줌
            captureDragAreaOverlay.graphics.lineStyle(0, 0, 0);
            captureDragAreaOverlay.graphics.beginFill(0, 0.3);
            captureDragAreaOverlay.graphics.drawRect(0, 0, canvasWidth, rectClamped.y); // 위
            captureDragAreaOverlay.graphics.drawRect(0, rectClamped.y, rectClamped.x, rectClamped.height); // 왼쪽
            captureDragAreaOverlay.graphics.drawRect(rectClamped.x + rectClamped.width, rectClamped.y, canvasWidth - (rectClamped.x + rectClamped.width), rectClamped.height); // 오른쪽
            captureDragAreaOverlay.graphics.drawRect(0, rectClamped.y + rectClamped.height, canvasWidth, canvasHeight - (rectClamped.y + rectClamped.height)); // 아래
            captureDragAreaOverlay.graphics.endFill();

            captureDragAreaOverlay.graphics.lineStyle(lineSize, 0xFFFFFF, 1.0, true);
            captureDragAreaOverlay.graphics.beginFill(0xFFFFFF, 0.0);
            captureDragAreaOverlay.graphics.drawRect(rectClamped.x, rectClamped.y, rectClamped.width, rectClamped.height);

            if (resizeButtonON)
            {
                drawResizeButton(zoomed);
            }
        }

        public static function getRotatedRectSizeString():String
        {
            const w:Number = Math.abs(rectClamped.width);
            const h:Number = Math.abs(rectClamped.height);

            if (rectClamped.x === 0.0 && rectClamped.y === 0.0 && rectClamped.width === 0.0 && rectClamped.height === 0.0)
            {
                if (ReplayController.isReplayModeON)
                {
                    return (CaptureController.captureCanvasRotationStep === 0 || CaptureController.captureCanvasRotationStep === 2) ? ReplayController.RCANVAS_WIDTH + " x " + ReplayController.RCANVAS_HEIGHT : ReplayController.RCANVAS_HEIGHT + " x " + ReplayController.RCANVAS_WIDTH;
                }
                else
                {
                    return (CaptureController.captureCanvasRotationStep === 0 || CaptureController.captureCanvasRotationStep === 2) ? canvasWidth + " x " + canvasHeight : canvasHeight + " x " + canvasWidth;
                }
            }

            if (w < minSize || h < minSize)
            {
                return "";
            }

            return (CaptureController.captureCanvasRotationStep === 0 || CaptureController.captureCanvasRotationStep === 2) ? w + " x " + h : h + " x " + w;
        }

        public static function resetCaptureArea():void
        {
            resizeButtonPos.setTo(0, 0);
            resizeFlag = false;
            clickPos.setTo(0, 0);
            rectClamped.x = 0;
            rectClamped.y = 0;
            rectClamped.width = 0;
            rectClamped.height = 0;
            rectRaw.x = 0;
            rectRaw.y = 0;
            rectRaw.width = 0;
            rectRaw.height = 0;
            rectFull.x = 0;
            rectFull.y = 0;
            rectFull.width = 0;
            rectFull.height = 0;
            limitWidthSave = 0;
            limitHeightSave = 0;
            captureDragAreaOverlay.graphics.clear();
            MainUI.topBar.capClipBoard.alpha = 1.0;
            CaptureStamp.update();
        }

        public static function reset():void
        {
            resizeButtonPos.setTo(0, 0);
            resizeFlag = false;
            clickPos.setTo(0, 0);
            rectClamped.x = 0;
            rectClamped.y = 0;
            rectClamped.width = 0;
            rectClamped.height = 0;
            rectRaw.x = 0;
            rectRaw.y = 0;
            rectRaw.width = 0;
            rectRaw.height = 0;
            rectFull.x = 0;
            rectFull.y = 0;
            rectFull.width = 0;
            rectFull.height = 0;
            limitWidthSave = 0;
            limitHeightSave = 0;
            canvasWidth = 0;
            canvasHeight = 0;
            xPanel = null;
            mouseMoved = false;
            MainUI.topBar.capClipBoard.alpha = 1.0;
        }

        public static function isFullImageCapture():Boolean
        {
            return rectClamped.width === 0.0 || rectClamped.height === 0.0;
        }

        public static function getCaptureArea():Rectangle
        {
            return rectClamped;
        }

        public static function isCursorInCaptureDrea():Boolean
        {
            if (!xPanel)
            {
                return false;
            }
            return rectClamped.contains(xPanel.mouseX, xPanel.mouseY);
        }

        public static function isCursorInResizeButton():Boolean
        {
            if (!xPanel)
            {
                return false;
            }
            const p1:Point = new Point(xPanel.mouseX, xPanel.mouseY);
            if (Point.distance(p1, resizeButtonPos) * getCanvasScale() < resizeButtonSize)
            {
                return true;
            }
            return false;
        }

        private static function startUpdatingCaptureAreaPosSize(mx:Number, my:Number, flag:Boolean):void
        {
            CanvasController.isMouseDragging = true;
            resizeFlag = flag;
            rectRaw.x = rectClamped.x;
            rectRaw.y = rectClamped.y;
            rectRaw.width = rectClamped.width;
            rectRaw.height = rectClamped.height;
            limitWidthSave = rectClamped.x + rectClamped.width;
            limitHeightSave = rectClamped.y + rectClamped.height;
            clickPos.setTo(mx, my);
            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveCaptureAreaDrawed);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpCaptureArea);
        }

        public static function start():void
        {
            if (MainUI.topBar.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
            {
                if (ReplayController.isReplayModeON) // 리플레이 변수로 변경
                {
                    canvasWidth = ReplayController.RCANVAS_WIDTH;
                    canvasHeight = ReplayController.RCANVAS_HEIGHT;
                    xPanel = ReplayController.rCanvasPanel;
                }
                else
                {
                    canvasWidth = CanvasController.CANVAS_WIDTH;
                    canvasHeight = CanvasController.CANVAS_HEIGHT;
                    xPanel = CanvasController.canvasPanel;
                }

                var mx:Number = xPanel.mouseX;
                var my:Number = xPanel.mouseY;

                rectFull.x = 0;
                rectFull.y = 0;
                rectFull.width = canvasWidth;
                rectFull.height = canvasHeight;
                resizeFlag = false;

                if (isCursorInResizeButton())
                {
                    startUpdatingCaptureAreaPosSize(mx, my, true);
                }
                else if (isCursorInCaptureDrea())
                {
                    startUpdatingCaptureAreaPosSize(mx, my, false);
                }
                else
                {
                    clickPos.setTo(mx, my);
                    CanvasController.isMouseDragging = true;
                    main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveDrawCaptureArea);
                    main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpCaptureArea);
                }
            }
        }
    }
}
