package Modules
{
    import Symbols.RotateCursorSet;
    import Symbols.CanvasNavigatorBoxSet;
    import flash.display.Shape;
    import flash.display.Sprite;
    import Symbols.CanvasInfoSet;
    import flash.display.BitmapData;
    import flash.display.Bitmap;
    import flash.geom.Rectangle;
    import flash.display.DisplayObjectContainer;
    import flash.events.MouseEvent;
    import flash.display.DisplayObject;
    import Modules.Tools.PenTool;
    import flash.events.Event;
    import flash.geom.Point;
    import Modules.Tools.LassoTool;
    import flash.geom.Matrix;
    import flash.geom.ColorTransform;
    import flash.display.Graphics;

    public class CanvasController
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        // todo : mouse clicked right clicked, dragging은 마우스 관련 이벤트 변수로 옮기기,canvasNavigatorBox 분리하기
        // todo : 캔버스 줌 로테이트 작동 이상함, 앵커포인트안잡히는듯
        public static const CANVAS_MIN_SIZE:Number = 100;
        public static const CANVAS_MAX_SIZE:Number = 2000;
        public static var CANVAS_WIDTH:Number = 600;
        public static var CANVAS_HEIGHT:Number = 390;
        public static var CANVAS_BG_COLOR:uint = 0xFFFFFF;
        public static const canvasRotateCursor:RotateCursorSet = new RotateCursorSet(); // 회전이 얼마나 됐는지 표시,
        public static const canvasNavigatorBox:CanvasNavigatorBoxSet = new CanvasNavigatorBoxSet();
        public static const canvasInfoBox:CanvasInfoSet = new CanvasInfoSet();
        public static const canvasFlashEffect:Sprite = new Sprite();
        public static const penSizePreviewCursor:Shape = new Shape(); // 펜사이즈 미리 보기

        public static var canvasAnchorPoint:Sprite = new Sprite(); // 회전 스프라이트 부모
        public static var canvasPanel:Sprite = new Sprite(); // 회색 부분을 제외한 그리기 영역 추가
        public static var canvasDrawLayer:Sprite = new Sprite(); // 캔버스 2번 임시로 그려주는 캔버스 버퍼?
        public static var canvasDrawLayerChild:Shape = new Shape(); // 실제로 선을 긋는 요소
        public static var canvasLayer1BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH, CANVAS_HEIGHT, true, 0);
        public static var canvasLayer2BitmapData:BitmapData = new BitmapData(CANVAS_WIDTH, CANVAS_HEIGHT, true, 0);
        public static var canvasDrawLayerBitmapData:BitmapData = new BitmapData(CANVAS_WIDTH, CANVAS_HEIGHT, true, 0);
        public static var canvasLayer1Bitmap:Bitmap = new Bitmap(canvasLayer1BitmapData, "auto", true);
        public static var canvasLayer2Bitmap:Bitmap = new Bitmap(canvasLayer2BitmapData, "auto", true);
        public static var canvasDrawLayerBitmap:Bitmap = new Bitmap(canvasDrawLayerBitmapData, "auto", true);

        public static var canvasDrawLayerClipRect:Rectangle = new Rectangle(); // 그려준 영역 만큼만 캔버스bitmap1에 그려주는 사각형
        public static var isCanvasMirrored:Boolean = false;
        public static var canvasZoomMultiplerList:Array = [0.125, 0.25, 0.5, 0.75, 1.0, 1.50, 2.0, 3.0, 4.0, 6.0, 8.0];
        public static var canvasZoomMultipler:Number = 1.0;
        public static var canvasZoomIndex:int = 4;

        // todo 나중에 앱창 마우스 관련으로 분리
        public static var isMouseClicked:Boolean = false; // 클릭하면 올려줌
        public static var isRightMouseClicked:Boolean = false; // 클릭하면 올려줌
        public static var isMouseDragging:Boolean = false; // 툴을 계속 클릭한채로 움직이면 topmenu의 힌트가 안켜지도록 함
        public static var isMouseClickBlocked:Boolean = false; // 알탭 하고나서 창활성화 되면 일정시간동안 작동하지 않게함
        public static var isKeyReleasedBeforeMouseUp:Boolean = false; // 키 떼기 전에 마우스 먼저 떼주었을때 플래그 올려줌

        public static var isLayer2Selected:Boolean = false;
        public static var checkedLayer:int = 0; // 레이어가 체크되면 저장해줌
        public static var isLayerSwapped:Boolean = false; // 1<->2 번호 바뀌는 힌트 써주려고 만듬

        public static var isPenSizeCursorInvisible:Boolean = false; // 펜 커서가 보이지 않게 설정

        public static function updateLayer1BitmapData(newbmpd:BitmapData):void
        {
            canvasLayer1BitmapData = newbmpd.clone();
            canvasLayer1Bitmap.bitmapData = canvasLayer1BitmapData;
        }

        public static function updateBitmapData(currentbmpd:BitmapData, newbmpd:BitmapData, targetBitmap:Bitmap):BitmapData
        {
            if (currentbmpd !== null && currentbmpd === newbmpd)
            {
                return currentbmpd;
            }
            const clone:BitmapData = newbmpd.clone();
            // currentbmpd distpos를 해주고 싶지만 뭔가 이미지 적용이 안되는 현상이 있어서 안해줌
            if (targetBitmap !== null)
            {
                targetBitmap.bitmapData = clone;
            }
            return clone;
        }

        public static function disableTransparentBGDrawMode():void
        {
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

        public static function enableTransparentBGDrawMode():void
        {
            if (!canvasPanel.getChildByName("canvasFlash"))
            {
                canvasPanel.addChild(canvasFlashEffect);
                canvasPanel.setChildIndex(canvasFlashEffect, 0);
                canvasFlashEffect.visible = true;
                canvasFlashEffect.graphics.beginBitmapFill(CaptureController.capTransparentBGBMPD);
                canvasFlashEffect.graphics.drawRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
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

        public static function applyCanvasFlashEffect(parent:DisplayObjectContainer, ox:Number, oy:Number, width:Number, height:Number, stopHandler:Function):void
        {
            if (!parent.getChildByName("canvasFlash"))
            {
                parent.addChild(canvasFlashEffect);
            }
            canvasFlashEffect.visible = true;
            canvasFlashEffect.graphics.beginFill(0xFFFFFF);
            canvasFlashEffect.graphics.drawRect(ox, oy, width, height);
            canvasFlashEffect.graphics.endFill();
            canvasFlashEffect.alpha = 1.0;
            const fadeStep:Number = Math.floor(0.05 * 256) / 256;
            FOFOTimer.addByName("flashingTimer", 0.0, true, function ():Boolean
                {
                    if (canvasFlashEffect.alpha < 0.1 || stopHandler())
                    {
                        canvasFlashEffect.alpha = 0.0;
                        canvasFlashEffect.visible = false;
                        canvasFlashEffect.graphics.clear();
                        if (parent.getChildByName("canvasFlash"))
                        {
                            parent.removeChild(canvasFlashEffect);
                        }
                        return false;
                    }
                    canvasFlashEffect.alpha -= fadeStep;
                    return true;
                });
        }

        public static function resetRCanvasDrawLayerCliprect2():void
        {
            main.rCanvasDrawLayerClipRect.x = 0;
            main.rCanvasDrawLayerClipRect.y = 0;
            main.rCanvasDrawLayerClipRect.width = 0;
            main.rCanvasDrawLayerClipRect.height = 0;
        }

        public static function extandRCanvasDrawLayerCliprect2():void
        {
            var rairBrushOffset:Number = (main.rAirBrushSize2 > 0) ? main.getClipRectOffsetAirBrush(main.rAirBrushSize2) : 1;
            main.rCanvasDrawLayerClipRect.x -= rairBrushOffset;
            main.rCanvasDrawLayerClipRect.y -= rairBrushOffset;
            main.rCanvasDrawLayerClipRect.width += (rairBrushOffset * 2);
            main.rCanvasDrawLayerClipRect.height += (rairBrushOffset * 2);
        }

        public static function extandRCanvasDrawLayerCliprect():void
        {
            var rairBrushOffset:Number = (main.rAirBrushSize > 0) ? main.getClipRectOffsetAirBrush(main.rAirBrushSize) : 1;
            main.rCanvasDrawLayerClipRectLegacy.x -= rairBrushOffset;
            main.rCanvasDrawLayerClipRectLegacy.y -= rairBrushOffset;
            main.rCanvasDrawLayerClipRectLegacy.width += (rairBrushOffset * 2);
            main.rCanvasDrawLayerClipRectLegacy.height += (rairBrushOffset * 2);
        }

        public static function resetRCanvasDrawLayerCliprect():void
        {
            main.rCanvasDrawLayerClipRectLegacy.x = 0;
            main.rCanvasDrawLayerClipRectLegacy.y = 0;
            main.rCanvasDrawLayerClipRectLegacy.width = 0;
            main.rCanvasDrawLayerClipRectLegacy.height = 0;
        }

        public static function updateRCanvasDrawLayerCliprect():void
        {
            main.rCanvasDrawLayerClipRectLegacy = main.rCanvasDrawLayerClipRectLegacy.union(main.rCanvasDrawShape.getBounds(main.rCanvasPanel));
        }

        public static function resetCanvasDrawLayerCliprect():void
        {
            canvasDrawLayerClipRect.x = 0;
            canvasDrawLayerClipRect.y = 0;
            canvasDrawLayerClipRect.width = 0;
            canvasDrawLayerClipRect.height = 0;
        }

        public static function extandCanvasDrawLayerCliprect():void
        {
            var airBrushOffset:Number = (PenTool.airBrushSizeDrawMode > 0) ? main.getClipRectOffsetAirBrush(PenTool.airBrushSizeDrawMode) : 1;
            canvasDrawLayerClipRect.x -= airBrushOffset;
            canvasDrawLayerClipRect.y -= airBrushOffset;
            canvasDrawLayerClipRect.width += (airBrushOffset * 2);
            canvasDrawLayerClipRect.height += (airBrushOffset * 2);
        }

        public static function updateCanvasDrawLayerCliprect():void
        {
            canvasDrawLayerClipRect = canvasDrawLayerClipRect.union(canvasDrawLayerChild.getBounds(canvasPanel));
        }

        public static function playLayerSwapEffect(target:DisplayObject):void
        {
            target.alpha = Global.OFFALPHA;
            FOFOTimer.addByName("layerSwapFlickEffect", 0.5, false, function ():void
                {
                    target.alpha = 1.0;
                });
        }

        public static function isAllLayerInvisible():Boolean
        {
            if (!canvasLayer1Bitmap.visible && !canvasLayer2Bitmap.visible)
            {
                MainUI.showMouseHintTemp("All layer locked");
                return true;
            }
            return false;
        }

        public static function toggleLayer1Check():void
        {
            if (ToolController.toolOptionsBox.layer1CheckedButton.visible === false)
            {
                checkedLayer = 1;
                ToolController.toolOptionsBox.layer1CheckedButton.visible = true;
                ToolController.toolOptionsBox.layer1UncheckedButton.visible = false;
                ToolController.toolOptionsBox.layer2CheckedButton.visible = false;
                ToolController.toolOptionsBox.layer2UncheckedButton.visible = true;
                ToolController.toolBox.setToolButtonsForCheckedLayerON();
                ToolController.toolBox2.setToolButtonsForCheckedLayerON();
            }
            else
            {
                checkedLayer = 0;
                ToolController.toolOptionsBox.layer1CheckedButton.visible = false;
                ToolController.toolOptionsBox.layer1UncheckedButton.visible = true;
                ToolController.toolBox.setToolButtonsForCheckedLayerOFF();
                ToolController.toolBox2.setToolButtonsForCheckedLayerOFF();
            }
        }
        public static function toggleLayer2Check():void
        {
            if (ToolController.toolOptionsBox.layer2CheckedButton.visible === false)
            {
                checkedLayer = 2;
                ToolController.toolOptionsBox.layer2CheckedButton.visible = true;
                ToolController.toolOptionsBox.layer2UncheckedButton.visible = false;
                ToolController.toolOptionsBox.layer1CheckedButton.visible = false;
                ToolController.toolOptionsBox.layer1UncheckedButton.visible = true;
                ToolController.toolBox.setToolButtonsForCheckedLayerON();
                ToolController.toolBox2.setToolButtonsForCheckedLayerON();
            }
            else
            {
                checkedLayer = 0;
                ToolController.toolOptionsBox.layer2CheckedButton.visible = false;
                ToolController.toolOptionsBox.layer2UncheckedButton.visible = true;
                ToolController.toolBox.setToolButtonsForCheckedLayerOFF();
                ToolController.toolBox2.setToolButtonsForCheckedLayerOFF();
            }
        }

        public static function mergeImageIntoLayer2():void
        {
            if (main.hasLastRDataCommand("merge"))
            {
                main.deleteLastRDataCommand("merge");
            }
            else
            {
                if (main.isDeepUndoEnabled)
                {
                    main.applyDeepUndo();
                }
                canvasLayer2BitmapData.draw(canvasLayer1BitmapData);
                canvasLayer1BitmapData.fillRect(new Rectangle(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT), 0);
                main.rDataBuffer.push(["merge"]);
                main.undoManager.addNew();
            }
            ToolController.toolOptionsBox.layerMergeButton.alpha = Global.OFFALPHA;
        }

        public static function swapLayer():void
        {
            if (ToolController.toolOptionsBox.layerSwapButton.alpha < 1.0)
            {
                return;
            }
            if (main.isDeepUndoEnabled)
            {
                main.applyDeepUndo();
            }
            isLayerSwapped = !isLayerSwapped;
            var tempbmpd1:BitmapData = canvasLayer1BitmapData.clone();
            var tempbmpd11:BitmapData = canvasLayer2BitmapData.clone();
            const rect:Rectangle = new Rectangle(0, 0, canvasLayer1BitmapData.width, canvasLayer1BitmapData.height);
            canvasLayer1BitmapData.fillRect(rect, 0);
            canvasLayer2BitmapData.fillRect(rect, 0);
            canvasLayer1BitmapData.draw(tempbmpd11);
            canvasLayer2BitmapData.draw(tempbmpd1);
            tempbmpd1.dispose();
            tempbmpd11.dispose();
            tempbmpd1 = null;
            tempbmpd11 = null;
            if (main.hasLastRDataCommand("swap"))
            {
                main.deleteLastRDataCommand("swap");
            }
            else
            {
                main.rDataBuffer.push(["swap"]);
                main.undoManager.addNew();
            }
            playLayerSwapEffect(ToolController.toolOptionsBox.layerSwapButton);
        }

        public static function updateCanvasPanelMask(w:Number, h:Number):void
        {
            canvasPanel.scrollRect = new Rectangle(0, 0, w, h);
        }

        public static function isToolEnabledByLayerUnChecked():Boolean
        {
            return checkedLayer === 0;
        }

        public static function onMouseUpStage(e:MouseEvent):void
        {
            main.checkInvalidKey();
            const mx:Number = main.stage.mouseX;
            const my:Number = main.stage.mouseY;
            isMouseClicked = false;
            if (!isMouseClicked && isRightMouseClicked)
            {
                isMouseDragging = false;
            }
        }

        public static function getRefinedPoint(mx:Number, my:Number):Point
        {
            mx = Math.round(mx * 100) / 100;
            my = Math.round(my * 100) / 100;
            if (ToolController.isSharpLineON)
            {
                my = Math.floor(my);
                mx = Math.floor(mx);
            }
            else if (PenTool.penSmoothSlideValue === 0 && (canvasAnchorPoint.rotation % 90 === 0))
            {
                my = Math.round(my);
                mx = Math.round(mx);
            }
            return new Point(mx, my);
        }

        public static function resetZoomDrawMode():void
        {
            if (canvasZoomMultipler !== 1.0)
            {
                const center:Point = MainUIController.getStageCenterPos("draw");
                const gcenter:Point = canvasPanel.globalToLocal(new Point(center.x, center.y));
                const gp:Point = canvasPanel.localToGlobal(new Point(0, 0));
                const panelLimitedPos:Point = main.getCanvasBoundLimitPoint(canvasPanel, gcenter.x, gcenter.y, CANVAS_WIDTH, CANVAS_HEIGHT, canvasAnchorPoint.scaleY, -canvasAnchorPoint.rotation);
                moveCanvasAnchorPoint(panelLimitedPos.x + gp.x, panelLimitedPos.y + gp.y, false);
                canvasZoomIndex = canvasZoomMultiplerList.indexOf(1.0);
                updateCanvasScale(1.0, false);
                main.updatePenSizeCursor();
                MainUIController.updateCanvasNaigatorCursor();
                CanvasGridOverlay.drawGrid();
            }

        }

        public static function zoomInCanvas(zoomInFlag:Boolean, isReplayMode:Boolean):void
        {
            const xAnc:Sprite = (isReplayMode) ? main.rCanvasAnchorPoint : canvasAnchorPoint;
            const zoomMax:int = canvasZoomMultiplerList.length - 1;
            var center:Point;
            var newZoomIndex:int = (isReplayMode) ? main.rCanvasZoomIndex : canvasZoomIndex;
            if (zoomInFlag)
            {
                newZoomIndex++;
                if (newZoomIndex > zoomMax)
                {
                    newZoomIndex = zoomMax;
                }
            }
            else
            {
                newZoomIndex--;
                if (newZoomIndex < 0)
                {
                    newZoomIndex = 0;
                }
            }
            const newZoom:Number = canvasZoomMultiplerList[newZoomIndex];
            if (isReplayMode)
            {
                center = MainUIController.getStageCenterPos("replay");
                main.rLastCanvasZoomMultiplier = newZoom;
                main.setFitReplayCanvasToViewportOFF();
                main.rCanvasZoomIndex = newZoomIndex;
                moveCanvasAnchorPoint(center.x, center.y, true);
                updateCanvasScale(newZoom, isReplayMode);
                main.rFollowMouse.updateBounds();
                MainUI.showMouseHintTemp(String(Math.floor(newZoom * 100)) + "%");
            }
            else
            {
                center = MainUIController.getStageCenterPos("draw");
                const gcenter:Point = canvasPanel.globalToLocal(new Point(center.x, center.y));
                const gp:Point = canvasPanel.localToGlobal(new Point(0, 0));
                const panelLimitedPos:Point = main.getCanvasBoundLimitPoint(canvasPanel, gcenter.x, gcenter.y, CANVAS_WIDTH, CANVAS_HEIGHT, xAnc.scaleY, -xAnc.rotation);
                canvasZoomIndex = newZoomIndex;
                moveCanvasAnchorPoint(panelLimitedPos.x + gp.x, panelLimitedPos.y + gp.y, false);
                updateCanvasScale(newZoom, isReplayMode);
                main.updatePenSizeCursor();
                MainUIController.updateCanvasNaigatorCursor();
                if (CanvasGridOverlay.gridGapMultiplier > 0)
                {
                    CanvasGridOverlay.drawGrid();
                }
            }
        }

        public static function startCanvasMoveByCanvasNavigator(navCursorClicked:Boolean):void
        {
            var sx:Number = canvasNavigatorBox.mouseX;
            var sy:Number = canvasNavigatorBox.mouseY;
            const prevCursorScale:Number = canvasNavigatorBox.navCursorMultiply;
            const uiScale:Number = Global.getUIScale();
            ReferenceLayerController.setRefLayerAndGridVisible(false);
            MainUI.hideBottomHint();
            function centerCanvas(mx:Number, my:Number):void
            {
                const b:Object = Utils.getBoundRect(canvasNavigatorBox.navCursor);
                const scale:Number = Global.getUIScale();
                // prevToCanvasMultiply를 나눠 줘야 커서랑 같은 속도가 나옴
                const rectCenterX:Number = b.left + (b.right - b.left) / 2;
                const rectCenterY:Number = b.top + (b.bottom - b.top) / 2;
                var moveX:Number = (rectCenterX - mx) / prevCursorScale / uiScale;
                var moveY:Number = (rectCenterY - my) / prevCursorScale / uiScale;
                var p:Point = Utils.rotatePoint(moveX, moveY, -canvasAnchorPoint.rotation);
                canvasAnchorPoint.x += Math.round(p.x);
                canvasAnchorPoint.y += Math.round(p.y);
                MainUIController.updateCanvasNaigatorCursor();
            }
            function onMouseUpCanvasNavigator(e:MouseEvent):void
            {
                ReferenceLayerController.setRefLayerAndGridVisible(true);
                keepCanvasPanelInStage();
                MainUIController.updateCanvasNaigatorCursor();
                isMouseDragging = false;
                if (LassoTool.isLassoToolStarted)
                {
                    if (LassoTool.isLassoMenuHiddenTemp === true)
                    {
                        LassoTool.hideLassoMenuBoxTemp();
                    }
                }
                main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveCanvasNavigator);
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpCanvasNavigator);
            }
            function onMouseMoveCanvasNavigator(e:MouseEvent):void
            {
                const scale:Number = Global.getUIScale();
                var mx:Number = canvasNavigatorBox.mouseX;
                var my:Number = canvasNavigatorBox.mouseY;
                // previewBox.prevCursorMultiply를 곱해줘야 커서랑 같은 속도가 나옴
                var moveX:Number = (sx - mx) / prevCursorScale;
                var moveY:Number = (sy - my) / prevCursorScale;
                var p:Point = Utils.rotatePoint(moveX, moveY, -canvasAnchorPoint.rotation);
                canvasAnchorPoint.x += Math.round(p.x);
                canvasAnchorPoint.y += Math.round(p.y);
                sx = mx;
                sy = my;
                MainUIController.updateCanvasNaigatorCursor();
            }
            moveCanvasAnchorPoint(0, 0);
            if (LassoTool.isLassoToolStarted)
            {
                LassoTool.lassoMenuBox.visible = false;
                LassoTool.isLassoMenuHiddenTemp = true;
            }
            // 클릭한 지점이 커서 바깥부분일때 강제로 캔버스 중심으로 옮겨줌
            if (!navCursorClicked)
            {
                centerCanvas(main.stage.mouseX, main.stage.mouseY);
            }
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpCanvasNavigator);
            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveCanvasNavigator);
        }

        // 원점 penSmoothX oy로부터 dx쪽으로 dist 만큼 떨어진 거리 점을 리턴함
        public static function movePointAngleDist(ox:Number, oy:Number, dx:Number, dy:Number, dist:Number):Point
        {
            const rad:Number = Math.atan2(dx - ox, dy - oy);
            return new Point(ox + dist * Math.sin(rad)
                    , oy + dist * Math.cos(rad));
        }

        public static function getBlurSize(size:Number, z:Number):Number
        {
            var blurSize:Number = size / 2;
            if (blurSize <= 2)
                blurSize = 2;
            else if (blurSize > 30)
                blurSize = 30;
            return blurSize * z;
        }

        public static function bringCanvasDrawLayerAboveLayer1():void
        {
            if (canvasPanel.getChildIndex(canvasDrawLayer) < canvasPanel.getChildIndex(LassoTool.lassoLayer1))
            {
                canvasPanel.setChildIndex(canvasDrawLayer, canvasPanel.getChildIndex(LassoTool.lassoLayer1));
            }
        }
        public static function bringCanvasDrawLayerAboveLayer2():void
        {
            if (canvasPanel.getChildIndex(canvasDrawLayer) > canvasPanel.getChildIndex(canvasLayer1Bitmap))
            {
                canvasPanel.setChildIndex(canvasDrawLayer, canvasPanel.getChildIndex(canvasLayer1Bitmap));
            }
        }

        public static function selectLayer1(onlyViewFlag:Boolean):void
        {
            isLayer2Selected = false;
            ToolController.toolOptionsBox.setSelectLayerButtonActiveAlpha(1);
            if (onlyViewFlag)
            {
                canvasLayer1Bitmap.visible = true;
                canvasLayer2Bitmap.visible = false;
                ToolController.toolOptionsBox.moveLayerInvisibleLineToLayer2();
            }
            else
            {
                canvasLayer1Bitmap.visible = true;
                canvasLayer2Bitmap.visible = true;
                ToolController.toolOptionsBox.removeLayerInvisibleLine();
            }
            bringCanvasDrawLayerAboveLayer1();
        }
        public static function selectLayer2(onlyViewFlag:Boolean):void
        {
            isLayer2Selected = true;
            ToolController.toolOptionsBox.setSelectLayerButtonActiveAlpha(2);
            if (onlyViewFlag)
            {
                canvasLayer1Bitmap.visible = false;
                canvasLayer2Bitmap.visible = true;
                ToolController.toolOptionsBox.moveLayerInvisibleLineToLayer1();
            }
            else
            {
                canvasLayer1Bitmap.visible = true;
                canvasLayer2Bitmap.visible = true;
                ToolController.toolOptionsBox.removeLayerInvisibleLine();
            }
            bringCanvasDrawLayerAboveLayer2();
        }

        public static function getMergedBitmapdtata(transparentBG:Boolean, layer1merge:Boolean, layer2merge:Boolean, clipRect:Rectangle):BitmapData
        {
            var xBitmapData1:BitmapData;
            var xBitmapData11:BitmapData;
            var xDrawLayer:Sprite;
            var xBGCOLOR:uint;
            var alpha:Number;
            var mat:Matrix;
            var bmpd:BitmapData;
            if (main.isReplayModeON)
            {
                xBitmapData1 = main.rCanvasLayer1BitmapData;
                xBitmapData11 = main.rCanvasLayer2BitmapData;
                xDrawLayer = main.rCanvasDrawLayer;
                xBGCOLOR = main.RCANVAS_BG_COLOR;
                alpha = main.drawReplayByCommand.getLineStyleAlpha();
            }
            else
            {
                xBitmapData1 = canvasLayer1BitmapData;
                xBitmapData11 = canvasLayer2BitmapData;
                xDrawLayer = canvasDrawLayer;
                xBGCOLOR = CANVAS_BG_COLOR;
                alpha = 1.0;
            }
            if (clipRect !== null)
            {
                bmpd = new BitmapData(clipRect.width, clipRect.height, true, (transparentBG) ? 0 : 0xFF000000 | xBGCOLOR);
                mat = new Matrix();
                mat.translate(-clipRect.x, -clipRect.y);
            }
            else
            {
                bmpd = new BitmapData(xBitmapData1.width, xBitmapData1.height, true, (transparentBG) ? 0 : 0xFF000000 | xBGCOLOR);
            }
            if (layer2merge)
            {
                bmpd.draw(xBitmapData11, mat); // 레이어 쌓기
            }
            if (main.isLayer2SelectedReplayMode()) // 레이어 2번을 그리고 있을때
            {
                if (layer2merge)
                    bmpd.draw(xDrawLayer, mat, new ColorTransform(1, 1, 1, alpha));
                if (layer1merge)
                    bmpd.draw(xBitmapData1, mat);
            }
            else // 리플레이에서 레이어 1번그리고 있을때
            {
                if (layer1merge)
                {
                    bmpd.draw(xBitmapData1, mat);
                    bmpd.draw(xDrawLayer, mat, new ColorTransform(1, 1, 1, alpha));
                }
            }
            return bmpd;
        }

        public static function getNearZoomIndex(nowZoom:Number):int
        {
            var index:int = Utils.binarySearchIndex(canvasZoomMultiplerList, nowZoom, function (item:*):Number
                {
                    return item;
                });
            if (index <= 0)
                return 0;
            else if (index >= canvasZoomMultiplerList.length - 1)
                return canvasZoomMultiplerList.length - 1;
            else if (canvasZoomMultiplerList[index + 1] - nowZoom < nowZoom - canvasZoomMultiplerList[index - 1])
            {
                return index + 1;
            }
            return index;
        }

        public static function isCanvasNaviatorChild(target:DisplayObject):Boolean
        {
            const targetName:String = target.name;
            return (targetName === "navStageBG"
                    || targetName === "navBitmapBG"
                    || targetName === "navLayer1Bitmap"
                    || targetName === "navLayer2Bitmap"
                    || targetName === "navCursor");
        }

        // 캔버스의 중심좌표를 구함 컨트롤 박스 옵션 박스 포함
        public static function getCanvasPanelMidPos():Point
        {
            const boundRect:Object = Utils.getBoundRect(canvasLayer1Bitmap);
            const left:Number = boundRect.left;
            const top:Number = boundRect.top;
            const right:Number = boundRect.right;
            const bottom:Number = boundRect.bottom;
            const visualWidth:Number = right - left; // 회전해있어도 상관없음
            const visualHeight:Number = bottom - top; // 양끝 모서리들의 직선거리를 구함
            const visualMidX:Number = Math.round((left + right) / 2); // 회전한 캔버스의 중심점을 구함
            const visualMidY:Number = Math.round((top + bottom) / 2); // floor안하면 1픽셀씩 내려감 0.5를 아래 setRegPoint 함수 에서 반올림 해줘서 그럼
            const p:Point = new Point(visualMidX, visualMidY);
            return p;
        }

        public static function mirrorCanvas(canvasOnly:Boolean = false):void
        {
            // canvaspanel로 하면 중점이 안맞아서 canvas1로함
            const p:Point = getCanvasPanelMidPos();
            isCanvasMirrored = !isCanvasMirrored;
            main.mirrorCommandReady = !main.mirrorCommandReady;
            main.mirrorDraw();
            canvasInfoBox.setMirror(isCanvasMirrored);
            // 회전각 부호를 바꿔야 제대로 mirror가됨
            moveCanvasAnchorPoint(p.x, p.y); // regpoint를 회전한 캔버스 중점으로 두고
            if (canvasOnly === false) // 보통 미러할때, canvasonly가 true일때는 appdata에서 바꿔줄때 밖에 없음
            {
                canvasAnchorPoint.rotation = -canvasAnchorPoint.rotation; // 반대각으로 세팅
                main.setRcursorRotation(canvasAnchorPoint.rotation);
                ReferenceLayerController.mirrorRefLayerImage();
            }
            CanvasGridOverlay.updateGridMirror(isCanvasMirrored);
            const halfCanvas:Number = (main.stage.stageWidth - SidebarController.sideBar.getWidth()) / 2;
            var stageHalf:Number = (SidebarController.sideBar.visible === false) ? main.stage.stageWidth / 2
                : (SidebarController.isRightSidebar) ? halfCanvas
                : MainUIController.STAGE_LEFT_OFFSET + halfCanvas;
            // 창 절반을 기준점으로 앵커포인트 x축 이동.
            canvasAnchorPoint.x += Math.round((stageHalf - p.x) * 2);
            MainUIController.updateCanvasNaigatorCursor();
            FileManager.isFileAlreadySaved = false; // 미러도 화면이 바뀌기 때문에 세이브 플래그 꺼줌
            main.mirrorRCursorPos();
        }

        public static function updateCavnvasSizeDrawMode(w:Number, h:Number, moveX:Number = 0, moveY:Number = 0, centerMovedFlag:Boolean = false):void
        {
            const maxSize:uint = CANVAS_MAX_SIZE;
            if (w > maxSize)
                w = maxSize;
            else if (w < 1)
                w = 1;
            if (h > maxSize)
                h = maxSize;
            else if (h < 1)
                h = 1;
            main.updateCanvasBGColor(canvasPanel, w, h, CANVAS_BG_COLOR);
            updateCanvasPanelMask(w, h);
            canvasLayer1BitmapData = new BitmapData(w, h, true, 0);
            canvasLayer2BitmapData = new BitmapData(w, h, true, 0);
            canvasDrawLayerBitmapData = new BitmapData(w, h, true, 0);
            if (centerMovedFlag)
            {
                // movex y는 캔버스 사이즈 조절에서 원점이 움직였을경우 그만큼 bitmapdata를 움직여줘야
                // 원래 이미지대로 나옴
                var mat:Matrix = new Matrix();
                const rp:Point = Utils.rotatePoint(moveX, moveY, -canvasAnchorPoint.rotation); // 캔버스가 회전되어있으면 회전된 방향으로 움직여줘야함
                mat.translate(moveX, moveY);
                canvasLayer1BitmapData.draw(canvasLayer1Bitmap, mat);
                canvasLayer2BitmapData.draw(canvasLayer2Bitmap, mat);
                canvasAnchorPoint.x -= Math.round(rp.x * canvasZoomMultipler);
                canvasAnchorPoint.y -= Math.round(rp.y * canvasZoomMultipler);
            }
            else
            {
                canvasLayer1BitmapData.draw(canvasLayer1Bitmap);
                canvasLayer2BitmapData.draw(canvasLayer2Bitmap);
            }
            if (canvasLayer1Bitmap.bitmapData)
                canvasLayer1Bitmap.bitmapData.dispose();
            canvasLayer1Bitmap.bitmapData = canvasLayer1BitmapData;
            if (canvasLayer2Bitmap.bitmapData)
                canvasLayer2Bitmap.bitmapData.dispose();
            canvasLayer2Bitmap.bitmapData = canvasLayer2BitmapData;
            ReferenceLayerController.updateRefLayerImagePos(w, h, centerMovedFlag); // canvas width가 갱신되게 전에 체크해야함
            CANVAS_WIDTH = w;
            CANVAS_HEIGHT = h;
            keepCanvasPanelInStage();
            if (CanvasGridOverlay.gridGapMultiplier > 0)
                CanvasGridOverlay.drawGrid();
            canvasInfoBox.setSize(w, h);
        }

        public static function cResizeCanvas():Object
        {
            var started:Boolean = false;
            const resizePreviewRect:Shape = new Shape();
            const resizePreviewRatioRect:Shape = new Shape();
            const resizeClickPos:Point = new Point(0, 0);
            var subX:Number = 0;
            var subY:Number = 0;
            const min:Number = CANVAS_MIN_SIZE;
            const max:Number = CANVAS_MAX_SIZE;
            const ratioSizeArr:Array = [];
            const ratioArr:Array = [
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
            var guideLineWidth:Number = 0;
            var ratioGuidePosBackUp:Point = new Point(0, 0);
            var isResizingWidth:Boolean = false; // 가로인지 새로인지 결정
            var targetName:String;
            var oldWidth:Number;
            var oldHeight:Number;
            var bgColor:uint;
            var stageColor:uint;
            var finalWidth:uint;
            var finalHeight:uint;
            var canvasSizeChanging:Boolean;
            var rightMouseupEventON:Boolean = false;
            function updateRatioSnapGuidePos():void
            {
                if (isResizingWidth)
                {
                    if (canvasPanel.mouseY > oldHeight / 2)
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
                    if (canvasPanel.mouseX > oldWidth / 2)
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
            function getNearestRatio(width:Number):Array
            {
                var index:Number = Utils.binarySearchIndex(ratioSizeArr, width, function (item:*):Number
                    {
                        return item[0];
                    });
                return ratioSizeArr[index + 1];
            }
            function drawRatioSnapGuide(w:Number, h:Number, targetName:String):void
            {
                isResizingWidth = (targetName === "resizeButtonL" || targetName === "resizeButtonR") ? true : false;
                function _drawRatioLine(referenceSize:Number, offset:Number):void
                {
                    ratioSizeArr.length = 0;
                    // hittestpoint를 위해서 배경을 그려줌
                    resizePreviewRatioRect.graphics.beginFill(0xFFFF00, 0.0);
                    if (isResizingWidth)
                        resizePreviewRatioRect.graphics.drawRect(-max / 2, -guideLineWidth, max * 2, guideLineWidth);
                    else
                        resizePreviewRatioRect.graphics.drawRect(-guideLineWidth, -max / 2, guideLineWidth, max * 2);
                    resizePreviewRatioRect.graphics.endFill();
                    const color:uint = Global.getUIFGColor();
                    var snapGuideStartPos:Number; // 스냅 격자 그려주는 위치
                    var scaledSize:Number; // 스냅 걸릴때 실제 사이즈
                    const len:uint = ratioArr.length;
                    const flipFlag:Boolean = (targetName === "resizeButtonU" || targetName === "resizeButtonL") ? true : false;
                    for (var i:uint = 0;i < len;i += 2)
                    {
                        scaledSize = Math.round(referenceSize * ratioArr[i + 1]);
                        snapGuideStartPos = scaledSize;
                        if (scaledSize > max || scaledSize < min)
                        {
                            continue;
                        }
                        resizePreviewRatioRect.graphics.lineStyle(3 / canvasZoomMultipler, color, 1.0, true, "normal", "none");
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
                        ratioSizeArr.push([scaledSize, ratioArr[i]]);
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
            function isCanvasResizing():Boolean
            {
                return canvasSizeChanging;
            }
            function exitResizeCanvas():void
            {
                if (started)
                {
                    started = false;
                    if (targetName !== null)
                    {
                        main.stage.removeEventListener(MouseEvent.MOUSE_UP, resizeButtonMouseUpEvent);
                        if (!isRightMouseClicked)
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
                    MainUI.hideMouseHint();
                    MainUIController.updateCanvasResizeButtonVisible((isMouseCursorInStage() && isRightMouseClicked) || main.isPressingControl());
                    canvasAnchorPoint.removeChild(resizePreviewRect);
                    canvasAnchorPoint.removeChild(resizePreviewRatioRect);
                    resizePreviewRect.graphics.clear();
                    resizePreviewRatioRect.graphics.clear();
                    if (subX !== 0 || subY !== 0)
                    {
                        const centerMovedFlag:Boolean = (targetName === "resizeButtonL" || targetName === "resizeButtonU") ? true : false;
                        if (main.isDeepUndoEnabled)
                        {
                            main.applyDeepUndo();
                        }
                        updateCavnvasSizeDrawMode(finalWidth, finalHeight, subX, subY, centerMovedFlag);
                        MainUIController.updateResizeButtonPos(finalWidth, finalHeight);
                        main.rDataBuffer.push(["canvasSize", finalWidth, finalHeight, subX, subY, centerMovedFlag]);
                        if (main.hasLastRDataCommand("canvasSize"))
                        {
                            main.undoManager.addContinue();
                        }
                        else
                        {
                            main.undoManager.addNew();
                            if (ImageViewWindow.isCanvasWindowON)
                            {
                                ImageViewWindow.updateCanvasWindowBitmapSize();
                            }
                        }
                    }
                    targetName = null;
                }
                else
                {
                    MainUIController.updateCanvasResizeButtonVisible(false);
                    rightMouseupEventON = false;
                    main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, resizeButtonRightMouseUpEvent);
                }
            }
            function isMouseCursorInStage():Boolean
            {
                return main.stage.mouseX >= 0 && main.stage.mouseY >= 0 && main.stage.mouseX <= main.stage.stageWidth && main.stage.mouseY <= main.stage.stageHeight;
            }
            function resizeButtonRightMouseUpEvent(e:MouseEvent):void
            {
                exitResizeCanvas();
            }
            function resizeButtonMouseUpEvent(e:MouseEvent):void
            {
                exitResizeCanvas();
            }
            function drawResizePreviewRect(size:Number, x:Number, y:Number, w:Number, h:Number):void
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
            function flipRatioString(r:String):String
            {
                var p:Array = r.split(":");
                return p[1] + ":" + p[0];
            }
            function updateHeight(flipFlag:Boolean):Number
            {
                subY = (flipFlag) ? resizeClickPos.y - canvasPanel.mouseY
                    : canvasPanel.mouseY - resizeClickPos.y;
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
                        MainUI.showMouseHint(oldWidth + " x " + finalHeight + " (" + str + ")");
                        return subY;
                    }
                }
                finalHeight = height;
                MainUI.showMouseHint(oldWidth + " x " + finalHeight);
                return subY;
            }
            function updateWidth(flipFlag:Boolean):Number
            {
                subX = (flipFlag) ? resizeClickPos.x - canvasPanel.mouseX
                    : canvasPanel.mouseX - resizeClickPos.x;
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
                        MainUI.showMouseHint(oldWidth + " x " + finalHeight + " (" + info[1] + ")");
                        return subX;
                    }
                }
                finalWidth = width;
                MainUI.showMouseHint(finalWidth + " x " + oldHeight);
                return subX;
            }
            function onMouseMoveReizeButtonD(e:MouseEvent):void
            {
                var subY:Number = updateHeight(false);
                drawResizePreviewRect(subY, 0, oldHeight, oldWidth, subY);
            }
            function onMouseMoveReizeButtonU(e:MouseEvent):void
            {
                var subY:Number = updateHeight(true);
                drawResizePreviewRect(subY, 0, -subY, oldWidth, subY);
            }
            function onMouseMoveReizeButtonR(e:MouseEvent):void
            {
                var subX:Number = updateWidth(false);
                drawResizePreviewRect(subX, oldWidth, 0, subX, oldHeight);
            }
            function onMouseMoveReizeButtonL(e:MouseEvent):void
            {
                var subX:Number = updateWidth(true);
                drawResizePreviewRect(subX, -subX, 0, subX, oldHeight);
            }
            function isResizing():Boolean
            {
                return started;
            }
            function initVars():void
            {
                oldWidth = CANVAS_WIDTH;
                oldHeight = CANVAS_HEIGHT;
                finalWidth = oldWidth;
                finalHeight = oldHeight;
                bgColor = CANVAS_BG_COLOR;
                stageColor = MainUIController.STAGE_BG_COLOR;
                subX = 0;
                subY = 0;
                canvasSizeChanging = false;
                resizePreviewRect.x = canvasPanel.x;
                resizePreviewRect.y = canvasPanel.y;
                resizePreviewRatioRect.x = resizePreviewRect.x;
                resizePreviewRatioRect.y = resizePreviewRect.y;
                ratioGuidePosBackUp.setTo(resizePreviewRatioRect.x, resizePreviewRatioRect.y);
                guideLineWidth = 30 / canvasZoomMultipler;
                canvasAnchorPoint.addChild(resizePreviewRect);
                canvasAnchorPoint.addChild(resizePreviewRatioRect);
                Utils.setAsTopChild(resizePreviewRect);
                Utils.setAsTopChild(resizePreviewRatioRect);
            }
            function startResizeCanvas(_targetName:String):void
            {
                // TODO:Drag인터렉션으로 변환
                if (started === false)
                {
                    started = true;
                    initVars();
                }
                targetName = _targetName;
                resizeClickPos.setTo(canvasPanel.mouseX, canvasPanel.mouseY);
                canvasSizeChanging = true;
                drawRatioSnapGuide(oldWidth, oldHeight, targetName);
                updateRatioSnapGuidePos();

                if (ToolController.isToolBox2Showing)
                {
                    ToolController.closeToolBox2();
                }

                MainUIController.updateCanvasResizeButtonVisible(false);
                main.stage.addEventListener(MouseEvent.MOUSE_UP, resizeButtonMouseUpEvent);
                if (rightMouseupEventON === false)
                {
                    rightMouseupEventON = true;
                    main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, resizeButtonRightMouseUpEvent);
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
            return {
                    start: startResizeCanvas,
                    exit: exitResizeCanvas,
                    isCanvasResizing: isCanvasResizing,
                    isResizing: isResizing
                };
        }

        public static function moveCanvasAnchorPoint(tx:Number, ty:Number, replayMode:Boolean = false):void
        {
            tx = Math.round(tx);
            ty = Math.round(ty);
            var xAnc:Sprite;
            var xCanvas:Sprite;
            var xZoomed:Number;
            if (replayMode)
            {
                xAnc = main.rCanvasAnchorPoint;
                xCanvas = main.rCanvasPanel;
                xZoomed = main.rCanvasZoomMultiplier;
            }
            else
            {
                xAnc = canvasAnchorPoint;
                xCanvas = canvasPanel;
                xZoomed = canvasZoomMultipler;
            }
            if (xAnc.x === tx && xAnc.y === ty)
            {
                return;
            }
            // round하면 정확도가 약간 줄어드는데, 안하면 그릴때 픽셀 어긋남
            // 캔버스 회전됐을때 점 위치를 구해줌
            // zoom된값을 나눠줘야 제대로된 이동거리가 나옴
            const rotateToolMoveEvent:Point = Utils.rotatePoint((xAnc.x - tx) / xZoomed,
                    (xAnc.y - ty) / xZoomed,
                    xAnc.rotation);
            xAnc.x = tx;
            xAnc.y = ty;
            xCanvas.x += Math.round(rotateToolMoveEvent.x); // 이동한 만큼 거꾸로 움직여줌
            xCanvas.y += Math.round(rotateToolMoveEvent.y); // rotate값 포함해서 움직여야함
        }

        public static function initializeCanvas():void
        {
            var g:Graphics;
            canvasPanel.name = "canvasPanel";
            canvasAnchorPoint.name = "canvasAnchorPoint";
            canvasLayer1Bitmap.name = "canvasLayer1Bitmap";
            canvasLayer2Bitmap.name = "canvasLayer2Bitmap";
            canvasDrawLayer.name = "canvasDrawLayer";
            canvasDrawLayerChild.name = "canvasDrawShape";
            penSizePreviewCursor.name = "penSizeCursor";
            MainUI.stageBG.name = "WorkspaceView.stageBG";
            ReferenceLayerController.canvasRefLayer.name = "canvasRefLayer";
            CanvasGridOverlay.canvasGrid.name = "canvasGrid";
            canvasFlashEffect.name = "canvasFlash";
            penSizePreviewCursor.visible = false;
            LassoTool.lassoLayer1.name = "lassoBox1";
            LassoTool.lassoLayer1.addChild(LassoTool.lassoLayer1Bitmap);
            LassoTool.lassoLayer1.addChild(LassoTool.lassoDraw);
            LassoTool.lassoLayer1.visible = false;
            LassoTool.lassoLayer2.name = "lassoBox2";
            LassoTool.lassoLayer2.addChild(LassoTool.lassoLayer2Bitmap);
            LassoTool.lassoLayer2.visible = false;
            ColorPickerController.updateCanvasBGColorDrawMode(CANVAS_BG_COLOR);
            updateCanvasPanelMask(CANVAS_WIDTH, CANVAS_HEIGHT);
            ReferenceLayerController.canvasRefLayer.alpha = ReferenceLayerController.refLayerLastAlpha;
            ReferenceLayerController.canvasRefLayer.addChild(ReferenceLayerController.canvasRefLayerBitmap);
            canvasDrawLayer.addChild(canvasDrawLayerBitmap);
            canvasDrawLayer.addChild(canvasDrawLayerChild);
            canvasDrawLayer.blendMode = "layer"; // 캔버스1이랑 알파 불투명도가 겹치지 않게 layer모드로 해줌
            main.rReplayFOFOCursor.visible = false;
            canvasPanel.addChild(ReferenceLayerController.canvasRefLayer);
            canvasPanel.addChild(canvasLayer2Bitmap);
            canvasPanel.addChild(LassoTool.lassoLayer2);
            canvasPanel.addChild(canvasLayer1Bitmap);
            canvasPanel.addChild(LassoTool.lassoLayer1);
            canvasPanel.addChild(canvasDrawLayer);
            canvasPanel.addChild(CanvasGridOverlay.canvasGrid);
            canvasPanel.addChild(main.rReplayFOFOCursor);
            // canvasrotate가 중점으로 올수있게 위치를 절반으로세팅
            canvasPanel.x = Math.floor(-canvasPanel.width / 2);
            canvasPanel.y = Math.floor(-canvasPanel.height / 2);
            canvasAnchorPoint.addChild(canvasPanel);
            main.stage.addChild(MainUI.stageBG);
            main.stage.addChild(main.eyedropperLens);
            main.stage.addChild(LassoTool.lassoMenuBox);
            main.stage.addChild(canvasAnchorPoint);
            main.stage.addChild(penSizePreviewCursor);
            main.stage.setChildIndex(canvasAnchorPoint, 0);
            main.stage.setChildIndex(MainUI.stageBG, 0);
        }

        public static function updateCanvasScale(zoomValue:Number, isReplayMode:Boolean = false):void
        {
            if (!zoomValue)
                zoomValue = 1.0;
            if (zoomValue < 0.0)
                zoomValue = Math.abs(zoomValue);
            var xAnc:Sprite;
            if (!isReplayMode)
            {
                xAnc = canvasAnchorPoint;
                canvasZoomMultipler = zoomValue;
                if (!CaptureController.isCaptureModeON)
                {
                    main.penCursorManager.updateZoom(zoomValue);
                }
            }
            else
            {
                main.rCanvasZoomMultiplier = zoomValue;
                xAnc = main.rCanvasAnchorPoint;
                if (main.rAirBrushSize > 0)
                {
                    main.blurReplayCanvasByValue(main.rAirBrushSize);
                }
            }
            xAnc.scaleX = zoomValue;
            xAnc.scaleY = zoomValue;
            if (CaptureController.isCaptureModeON && CaptureController.isCaptureCanvasFlipped)
            {
                xAnc.scaleX = -xAnc.scaleX;
            }
            if (!CaptureController.isCaptureModeON)
            {
                canvasInfoBox.setZoom(zoomValue);
            }
            main.updateReplayCursorScale(zoomValue);
        }

        // check box position함수는 요소 전체가 창에서 넘어가만 않게 하는거고
        public static function keepCanvasPanelInStage(replayMode:Boolean = false):void
        {
            var xAnc:Sprite;
            var xCanvas:Bitmap;
            if (replayMode)
            {
                xAnc = main.rCanvasAnchorPoint;
                xCanvas = main.rCanvasLayer1Bitmap;
            }
            else
            {
                xAnc = canvasAnchorPoint;
                xCanvas = canvasLayer1Bitmap;
            }
            const offset:int = 100; // 최소 100픽셀 은 보여야함
            const bounds:Object = Utils.getBoundRect(xCanvas);
            const leftLimit:Number = MainUIController.STAGE_LEFT_OFFSET + offset;
            const rightLimit:Number = main.stage.stageWidth - (MainUIController.STAGE_RIGHT_OFFSET + offset);
            const topLimit:Number = MainUIController.STAGE_TOP_OFFSET + offset;
            const bottomLimit:Number = main.stage.stageHeight - (MainUIController.STAGE_BOTTOM_OFFSET + offset);
            // getbound는 보이는 그대로 사각형 끝점 좌표를 반환함
            const left:Number = bounds.left;
            const top:Number = bounds.top;
            const right:Number = bounds.right;
            const bottom:Number = bounds.bottom;
            // 꼭지점이 경계offset을 넘어가면 넘어간 거리만큼 regpoint를 반대로 움직여줌
            if (left > rightLimit)
                xAnc.x -= left - rightLimit;
            else if (right < leftLimit)
                xAnc.x += leftLimit - right;
            if (bottom < topLimit)
                xAnc.y += topLimit - bottom;
            else if (top > bottomLimit)
                xAnc.y -= top - bottomLimit;
        }

        // 캔버스 정 가운데로
        public static function centerCanvas(mode:String):void
        {
            var xAnc:Sprite;
            var xCanvas:Sprite;
            var w:Number;
            var h:Number;
            var center:Point = MainUIController.getStageCenterPos(mode);
            // todo : 이거 원래 isreplaymode on 플래그로 검사하는데 리팩토링후에 캔버스 위치 적용이 안되서
            // mode로 탐지하는걸로 고침 버그날수도있음
            if (mode === "replay")
            {
                xAnc = main.rCanvasAnchorPoint;
                xCanvas = main.rCanvasPanel;
                w = main.RCANVAS_WIDTH;
                h = main.RCANVAS_HEIGHT;
            }
            else
            {
                xAnc = canvasAnchorPoint;
                xCanvas = canvasPanel;
                w = CANVAS_WIDTH;
                h = CANVAS_HEIGHT;
            }
            xAnc.x = Math.floor(center.x);
            xAnc.y = Math.floor(center.y);
            xCanvas.x = Math.floor(-w / 2);
            xCanvas.y = Math.floor(-h / 2);
            if (!main.isReplayModeON)
            {
                MainUIController.updateCanvasNaigatorCursor();
            }
        }

        public static function clearCanvas():void
        {
            const rect:Rectangle = new Rectangle(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
            if (canvasLayer1BitmapData)
                canvasLayer1BitmapData.fillRect(rect, 0);
            if (canvasLayer2BitmapData)
                canvasLayer2BitmapData.fillRect(rect, 0);
            if (canvasDrawLayerBitmapData)
                canvasDrawLayerBitmapData.fillRect(rect, 0);
        }

        public static function startCanvasResizing(targetName:String):void
        {
            CanvasController.isPenSizeCursorInvisible = true;
            penSizePreviewCursor.visible = false;
            MainUI.showMouseHint(CANVAS_WIDTH + " x " + CANVAS_HEIGHT);
            main.resizeCanvas.start(targetName);
        }
    }
}
