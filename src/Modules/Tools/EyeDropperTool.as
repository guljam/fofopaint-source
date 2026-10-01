package Modules.Tools
{
    import Modules.DrawEngine.CanvasView;
    import Modules.DrawEngine.DrawCanvas;
    import Modules.DrawEngine.CanvasLayers;
    import Modules.MouseState;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;
    import Modules.InputPriority;
    import Modules.CaptureEngine.CaptureController;
    import Modules.ColorPickerController;
    import Modules.FileManager;
    import Modules.InputManager.InputManager;
    import Modules.ReferenceLayerController;
    import Modules.ToolController;
    import Modules.Utils;

    import Symbols.EyedropperLensSet;

    import flash.display.Shape;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayState;
    import flash.events.Event;

    public class EyeDropperTool
    {
        public static var main:Main;

        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        // 일단 흰색으로 배경 깔아줌
        public static const eyedropperLens:EyedropperLensSet = new EyedropperLensSet();

        private static const magSize:Number = eyedropperLens.magSize;
        private static const lensRect:Rectangle = new Rectangle(0, 0, magSize, magSize);
        private static const lensMat:Matrix = new Matrix();

        private static var penColorBackup:uint;
        private static var canvasBGShape:Shape = new Shape();

        private static var lastMouseX:Number = NaN;
        private static var lastMouseY:Number = NaN;

        private static function updateEyeDropperLensBitmap():void
        {
            const mid:Number = magSize / (4 * CanvasView.canvasZoomMultiplier); // 4는 기본 중앙값 magsize/2에서 zoomed나워주고 기본이 2배줌이니까 2로 나눠준값
            const tx:Number = -DrawCanvas.canvasLayer1Bitmap.mouseX + mid;
            const ty:Number = -DrawCanvas.canvasLayer1Bitmap.mouseY + mid;

            lensMat.identity();
            lensMat.translate(tx, ty);
            lensMat.scale(2.0 * CanvasView.canvasZoomMultiplier, 2.0 * CanvasView.canvasZoomMultiplier);

            eyedropperLens.bitmap.bitmapData.fillRect(lensRect, UIController.STAGE_BG_COLOR);
            eyedropperLens.bitmap.bitmapData.draw(canvasBGShape, lensMat, null, null, lensRect);

            if (DrawCanvas.canvasLayer2Bitmap.visible)
            {
                eyedropperLens.bitmap.bitmapData.draw(DrawCanvas.canvasLayer2Bitmap.bitmapData, lensMat, null, null, lensRect);
            }

            if (DrawCanvas.canvasLayer1Bitmap.visible)
            {
                eyedropperLens.bitmap.bitmapData.draw(DrawCanvas.canvasLayer1Bitmap.bitmapData, lensMat, null, null, lensRect);
            }
        }

        private static function pickColor(canShow:Boolean):uint
        {
            if (canShow)
            {
                // 배경색
                const r3:uint = (DrawCanvas.CANVAS_BG_COLOR & 0xFF0000) >> 16;
                const g3:uint = (DrawCanvas.CANVAS_BG_COLOR & 0x00FF00) >> 8;
                const b3:uint = (DrawCanvas.CANVAS_BG_COLOR & 0x0000FF);

                var aa:Number = 0;
                var rr:uint = 0;
                var gg:uint = 0;
                var bb:uint = 0;

                var a1:Number = 0;
                var r1:uint = 0;
                var g1:uint = 0;
                var b1:uint = 0;

                var a2:Number = 0;
                var r2:uint = 0;
                var g2:uint = 0;
                var b2:uint = 0;

                // 위 레이어
                if (DrawCanvas.canvasLayer1Bitmap.visible)
                {
                    const c1:uint = DrawCanvas.canvasLayer1BitmapData.getPixel32(DrawCanvas.canvasLayer1Bitmap.mouseX, DrawCanvas.canvasLayer1Bitmap.mouseY);
                    a1 = ((c1 & 0xFF000000) >>> 24) / 255;
                    r1 = (c1 & 0x00FF0000) >>> 16;
                    g1 = (c1 & 0x0000FF00) >>> 8;
                    b1 = (c1 & 0x000000FF);
                }

                // 밑 레이어
                if (DrawCanvas.canvasLayer2Bitmap.visible)
                {
                    const c2:uint = DrawCanvas.canvasLayer2BitmapData.getPixel32(DrawCanvas.canvasLayer1Bitmap.mouseX, DrawCanvas.canvasLayer1Bitmap.mouseY);
                    a2 = ((c2 & 0xFF000000) >>> 24) / 255;
                    r2 = (c2 & 0x00FF0000) >>> 16;
                    g2 = (c2 & 0x0000FF00) >>> 8;
                    b2 = (c2 & 0x000000FF);
                }

                // source over S 새로그린거 B는 원래 그려져 있던거
                // aR : the union alpha (as + ab * (1 - as)) //알파 혼합
                // r: ((S.r * S.a) + (B.r * B.a) * (1 - S.a)) / aR,
                // g: ((S.g * S.a) + (B.g * B.a) * (1 - S.a)) / aR,
                // b: ((S.b * S.a) + (B.b * B.a) * (1 - S.a)) / aR,
                // 아래 레이어 부터
                aa = 1.0 - a2;
                rr = Math.round(r2 * a2) + Math.round(r3 * aa);
                gg = Math.round(g2 * a2) + Math.round(g3 * aa);
                bb = Math.round(b2 * a2) + Math.round(b3 * aa);

                // 그 위에 위 레이어
                const aa1:Number = 1.0 - a1;
                const r:uint = Math.round(r1 * a1) + Math.round(rr * aa1);
                const g:uint = Math.round(g1 * a1) + Math.round(gg * aa1);
                const b:uint = Math.round(b1 * a1) + Math.round(bb * aa1);

                return Utils.RGBtoHEX(r, g, b);
            }
            else
            {
                return penColorBackup;
            }
        }

        private static function onRightMouseDownEyeDropper(e:MouseEvent):void
        {
            exitEyeDropperTool(false);
        }

        private static function onKeyDownEyeDropper(e:KeyboardEvent):void
        {
            if (isNotEyeDropperTool())
            {
                exitEyeDropperTool(false);
                return;
            }

            if (e.keyCode === InputManager.KEY.c || e.keyCode === InputManager.KEY.m) {}
            else if (e.keyCode === InputManager.KEY.space)
            {
                if (PenTool.isTransparentPenColor)
                {
                    ColorPickerController.selectCurrentColor(false);
                    HintController.showMouseHintTemp("Current color selected");
                }
                else
                {
                    ColorPickerController.selectCurrentColor(false);

                    if (PenTool.isTransparentPenColor === false)
                    {
                        ColorPickerController.selectTransparentColor();
                    }

                    HintController.showMouseHintTemp("Transparent color selected");
                }

                exitEyeDropperTool(false);
            }
            else
            {
                exitEyeDropperTool(false);
            }
        }

        private static function onKeyUpEyeDropper(e:KeyboardEvent):void
        {
            if (isNotEyeDropperTool())
            {
                exitEyeDropperTool(false);
                return;
            }

            if (e.keyCode === InputManager.KEY.c || e.keyCode === InputManager.KEY.m)
            {
                confirmEyeDropperSelection();
            }
        }

        private static function onMouseDownEyeDropper(e:MouseEvent):void
        {
            if (isNotEyeDropperTool())
            {
                exitEyeDropperTool(false);
                return;
            }

            if (canShowEyedropperLens())
            {
                confirmEyeDropperSelection();
            }
            else
            {
                exitEyeDropperTool(false);
            }
        }

        private static function exitEyeDropperTool(okFlag:Boolean):void
        {
            removeEyedropperEvents();

            eyedropperLens.visible = false;
            // canvasRefLayer.visible = true;

            canvasBGShape.graphics.clear();
            ReferenceLayerController.setRefLayerAndGridVisible(true);

            if (okFlag)
            {
                if (!(ToolController.isLastTool(ToolController.TOOL_FILLPEN)
                            || ToolController.isLastTool(ToolController.TOOL_LINE)
                            || ToolController.isLastTool(ToolController.TOOL_PEN)))
                {
                    ToolController.setLastTool(ToolController.TOOL_PEN);
                }
            }

            ToolController.selectLastUsedTool();
        }

        private static function isNotEyeDropperTool():Boolean
        {
            return !ToolController.isSelectedTool(ToolController.TOOL_EYEDROPPER) || ReplayState.isReplayModeON || CaptureController.isCaptureModeON || FileManager.isFileBrowserOpened || MouseState.isClickBlocked;
        }

        private static function confirmEyeDropperSelection():void
        {
            const canShow:Boolean = canShowEyedropperLens();

            if (canShow)
            {
                const pickedColor:uint = pickColor(true);
                PenTool.penColor = pickedColor;
                ColorPickerController.pickerIgnoreHistoryColor = pickedColor;
                ColorPickerController.updateColorPickerCursorPosAndRGBInfo(pickedColor);
            }

            exitEyeDropperTool(canShow);
        }

        private static function onEnterFrameEyeDropper(e:Event):void
        {
            if (isNotEyeDropperTool())
            {
                exitEyeDropperTool(false);
                return;
            }
            const mx:Number = main.stage.mouseX;
            const my:Number = main.stage.mouseY;
            if (mx === lastMouseX && my === lastMouseY)
            {
                return;
            }

            lastMouseX = mx;
            lastMouseY = my;
            eyedropperLens.x = main.stage.mouseX;
            eyedropperLens.y = main.stage.mouseY;

            const canShow:Boolean = canShowEyedropperLens();
            if (canShow)
            {
                Utils.setColorTransform(eyedropperLens.nowColor, pickColor(canShow));

                if (CanvasView.canvasZoomMultiplier < 12.0)
                {
                    updateEyeDropperLensBitmap();
                }

                eyedropperLens.visible = true;
            }
            else
            {
                eyedropperLens.visible = false;
            }
        }

        private static function removeEyedropperEvents():void
        {
            main.stage.removeEventListener(Event.ENTER_FRAME, onEnterFrameEyeDropper);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownEyeDropper);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownEyeDropper);
            main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpEyeDropper);
            main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownEyeDropper);
        }

        private static function addEyedropperEvents():void
        {
            main.stage.addEventListener(Event.ENTER_FRAME, onEnterFrameEyeDropper);
            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownEyeDropper, false, InputPriority.LATE);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownEyeDropper, false, InputPriority.LATE);
            main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpEyeDropper, false, InputPriority.EARLY_KEY);
            main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownEyeDropper, false, InputPriority.EARLY_KEY);
        }

        private static function canShowEyedropperLens():Boolean
        {
            return Utils.isCursorInDrawArea() && DrawCanvas.canvasLayer1Bitmap.hitTestPoint(main.stage.mouseX, main.stage.mouseY, true)
                && !(ReferenceLayerController.refLayerMenuBox.visible && ReferenceLayerController.refLayerMenuBox.hitTestPoint(main.stage.mouseX, main.stage.mouseY));
        }

        public static function start():void
        {
            if (CanvasLayers.checkedLayer !== 0 || CanvasLayers.isAllLayerInvisible())
            {
                return;
            }

            ToolController.toolBox.moveToolCursor("toolEyedropper");
            ToolController.setLastTool(ToolController.nowTool);
            // todo: 이것도 그냥 setLastToolPen, setSeletedToolPen이런식으로 메서드로 호출
            ToolController.setSelectedTool(ToolController.TOOL_EYEDROPPER);

            penColorBackup = PenTool.penColor;
            Utils.setColorTransform(eyedropperLens.oldColor, PenTool.penColor);

            ToolController.moveEraserButtonToOtherTool("toolEyedropper");
            eyedropperLens.rotateBitmap(CanvasView.canvasAnchorPoint.rotation);

            ReferenceLayerController.setCanvasRefLayerInvisible();

            canvasBGShape.graphics.clear();
            canvasBGShape.graphics.beginFill(DrawCanvas.CANVAS_BG_COLOR);
            canvasBGShape.graphics.drawRect(0, 0, DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT);

            const canShow:Boolean = canShowEyedropperLens();
            if (canShow)
            {
                eyedropperLens.x = main.stage.mouseX;
                eyedropperLens.y = main.stage.mouseY;

                Utils.setColorTransform(eyedropperLens.nowColor, pickColor(canShow));
                Utils.setAsTopChild(eyedropperLens);

                if (CanvasView.canvasZoomMultiplier < 12.0)
                {
                    eyedropperLens.circleBox.visible = true;
                    updateEyeDropperLensBitmap();
                }
                else
                {
                    eyedropperLens.circleBox.visible = false;
                }

                eyedropperLens.visible = true;
                lastMouseX = main.stage.mouseX;
                lastMouseY = main.stage.mouseY;
            }
            else
            {
                lastMouseX = NaN;
                lastMouseY = NaN;
            }

            addEyedropperEvents();

            return;
        }
    }
}
