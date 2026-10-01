package Modules
{
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UIController;
    import Modules.UIEngine.UITheme;
    import Modules.CaptureEngine.CaptureController;
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
    import Modules.Tools.EyeDropperTool;
    import flash.ui.MouseCursor;
    import Modules.Tools.ZoomTool;
    import flash.utils.getTimer;
    import flash.trace.Trace;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayDrawCommands;
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.ReplayEngine.ReplayState;

    public class CanvasController
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        // todo : canvasNavigatorBox 분리하기
        // todo : 포멧팅 필요
        public static const CANVAS_MAX_SIZE:Number = 2000;
        public static var CANVAS_WIDTH:Number = 600;
        public static var CANVAS_HEIGHT:Number = 390;
        public static var CANVAS_BG_COLOR:uint = 0xFFFFFF;
        public static const canvasRotateCursor:RotateCursorSet = new RotateCursorSet(); // 회전이 얼마나 됐는지 표시,
        public static const canvasNavigatorBox:CanvasNavigatorBoxSet = new CanvasNavigatorBoxSet();
        public static const canvasInfoBox:CanvasInfoSet = new CanvasInfoSet();
        public static const canvasFlashEffect:Sprite = new Sprite();

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
        public static var mirrorON:Boolean = false;
        public static var canvasZoomMultiplerList:Array = [0.125, 0.25, 0.5, 0.75, 1.0, 1.50, 2.0, 3.0, 4.0, 6.0, 8.0];
        public static var canvasZoomMultipler:Number = 1.0;
        public static var canvasZoomIndex:int = 4;

        public static var isLayer2Selected:Boolean = false;
        public static var checkedLayer:int = 0; // 레이어가 체크되면 저장해줌
        public static var isLayerSwapped:Boolean = false; // 1<->2 번호 바뀌는 힌트 써주려고 만듬

        private static const copyPixelRect:Rectangle = new Rectangle();

        // 네비게이터로 캔버스 이동 이벤트 한번만 올려주기
        private static var canvasMoveByCanvasNavigatorEventStarted:Boolean = false;

        public static function resetRotationDrawMode():void
        {
            const center:Point = UIController.getStageCenterPos("draw");
            PenSizePreviewCursor.updateSizeAndShape();
            moveCanvasAnchorPoint(center.x, center.y, false);
            canvasAnchorPoint.rotation = 0;
            ReplayDrawer.setRcursorRotation(0);
            canvasInfoBox.setRotate(0);
        }

        public static function updateLayer1BitmapData(newbmpd:BitmapData):void
        {
            canvasLayer1BitmapData = newbmpd.clone();
            canvasLayer1Bitmap.bitmapData = canvasLayer1BitmapData;
        }

        public static function updateBitmapData(targetbmpd:BitmapData, newbmpd:BitmapData, targetBitmap:Bitmap):BitmapData
        {
            if (targetbmpd !== null && targetbmpd === newbmpd)
            {
                return targetbmpd;
            }
            const clone:BitmapData = newbmpd.clone();
            // currentbmpd distpos를 해주고 싶지만 뭔가 이미지 적용이 안되는 현상이 있어서 안해줌
            if (targetBitmap !== null)
            {
                targetBitmap.bitmapData = clone;
            }
            return clone;
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

        public static function resetCanvasDrawLayerCliprect():void
        {
            canvasDrawLayerClipRect.x = 0;
            canvasDrawLayerClipRect.y = 0;
            canvasDrawLayerClipRect.width = 0;
            canvasDrawLayerClipRect.height = 0;
        }

        public static function extandCanvasDrawLayerCliprect():void
        {
            var airBrushOffset:Number = (PenTool.airBrushSizeDrawMode > 0) ? PenTool.getClipRectOffsetAirBrush(PenTool.airBrushSizeDrawMode) : 1;
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
            target.alpha = UITheme.OFFALPHA;
            FOFOTimer.addByName("layerSwapFlickEffect", 0.5, false, function ():void
                {
                    target.alpha = 1.0;
                });
        }

        public static function isAllLayerInvisible():Boolean
        {
            if (!canvasLayer1Bitmap.visible && !canvasLayer2Bitmap.visible)
            {
                HintController.showMouseHintTemp("All layer locked");
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
            if (ReplayState.hasLastRMemoryDataCommand("merge"))
            {
                ReplayState.deleteLastRMemoryDataCommand("merge");
            }
            else
            {
                if (UndoController.isDeepUndoEnabled)
                {
                    UndoController.applyDeepUndo();
                }
                canvasLayer2BitmapData.draw(canvasLayer1BitmapData);
                canvasLayer1BitmapData.fillRect(new Rectangle(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT), 0);
                ReplayState.pushCommand(["merge"]);
                UndoHistory.addNew();
            }
            ToolController.toolOptionsBox.layerMergeButton.alpha = UITheme.OFFALPHA;
        }

        public static function swapLayer():void
        {
            if (ToolController.toolOptionsBox.layerSwapButton.alpha < 1.0)
            {
                return;
            }
            if (UndoController.isDeepUndoEnabled)
            {
                UndoController.applyDeepUndo();
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
            if (ReplayState.hasLastRMemoryDataCommand("swap"))
            {
                ReplayState.deleteLastRMemoryDataCommand("swap");
            }
            else
            {
                ReplayState.pushCommand(["swap"]);
                UndoHistory.addNew();
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

        public static function resetZoomDrawMode():void
        {
            if (canvasZoomMultipler !== 1.0)
            {
                const center:Point = UIController.getStageCenterPos("draw");
                const gcenter:Point = canvasPanel.globalToLocal(new Point(center.x, center.y));
                const gp:Point = canvasPanel.localToGlobal(new Point(0, 0));
                const panelLimitedPos:Point = ZoomTool.getCanvasBoundLimitPoint(canvasPanel, gcenter.x, gcenter.y, CANVAS_WIDTH, CANVAS_HEIGHT, canvasAnchorPoint.scaleY, -canvasAnchorPoint.rotation);
                moveCanvasAnchorPoint(panelLimitedPos.x + gp.x, panelLimitedPos.y + gp.y, false);
                canvasZoomIndex = canvasZoomMultiplerList.indexOf(1.0);
                updateCanvasScale(1.0, false);
                PenSizePreviewCursor.updateSizeAndShape();
                CanvasGridOverlay.drawGrid();
            }
        }

        public static function zoomInCanvas(zoomInFlag:Boolean, isReplayMode:Boolean):void
        {
            const xAnc:Sprite = (isReplayMode) ? ReplayDrawer.rCanvasAnchorPoint : canvasAnchorPoint;
            const zoomMax:int = canvasZoomMultiplerList.length - 1;
            var center:Point;
            var newZoomIndex:int = (isReplayMode) ? ReplayState.rCanvasZoomIndex : canvasZoomIndex;
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
                center = UIController.getStageCenterPos("replay");
                ReplayState.rLastCanvasZoomMultiplier = newZoom;
                ReplayController.setFitReplayCanvasToViewportOFF();
                ReplayState.rCanvasZoomIndex = newZoomIndex;
                moveCanvasAnchorPoint(center.x, center.y, true);
                updateCanvasScale(newZoom, isReplayMode);
                ReplayController.rFollowMouse.updateBounds();
                HintController.showMouseHintTemp(String(Math.floor(newZoom * 100)) + "%");
            }
            else
            {
                center = UIController.getStageCenterPos("draw");
                const gcenter:Point = canvasPanel.globalToLocal(new Point(center.x, center.y));
                const gp:Point = canvasPanel.localToGlobal(new Point(0, 0));
                const panelLimitedPos:Point = ZoomTool.getCanvasBoundLimitPoint(canvasPanel, gcenter.x, gcenter.y, CANVAS_WIDTH, CANVAS_HEIGHT, xAnc.scaleY, -xAnc.rotation);
                canvasZoomIndex = newZoomIndex;
                moveCanvasAnchorPoint(panelLimitedPos.x + gp.x, panelLimitedPos.y + gp.y, false);
                updateCanvasScale(newZoom, isReplayMode);
                PenSizePreviewCursor.updateSizeAndShape();
                UIController.updateCanvasNaigatorCursor();
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
            const uiScale:Number = UITheme.getUIScale();

            ReferenceLayerController.setRefLayerAndGridVisible(false);
            HintController.hideBottomHint();

            function centerCanvas(mx:Number, my:Number):void
            {
                const b:Object = Utils.getBoundRect(canvasNavigatorBox.navCursor);
                const scale:Number = UITheme.getUIScale();
                // prevToCanvasMultiply를 나눠 줘야 커서랑 같은 속도가 나옴
                const rectCenterX:Number = b.left + (b.right - b.left) / 2;
                const rectCenterY:Number = b.top + (b.bottom - b.top) / 2;
                var moveX:Number = (rectCenterX - mx) / prevCursorScale / uiScale;
                var moveY:Number = (rectCenterY - my) / prevCursorScale / uiScale;
                var p:Point = Utils.rotatePoint(moveX, moveY, -canvasAnchorPoint.rotation);
                canvasAnchorPoint.x += Math.round(p.x);
                canvasAnchorPoint.y += Math.round(p.y);
                UIController.updateCanvasNaigatorCursor();
            }

            function onMouseUpCanvasNavigator(e:MouseEvent):void
            {
                MouseState.endDrag("canvasNavigator");
                ReferenceLayerController.setRefLayerAndGridVisible(true);
                keepCanvasPanelInStage();
                UIController.updateCanvasNaigatorCursor();
                if (LassoTool.isStarted)
                {
                    if (LassoTool.isLassoMenuHiddenTemp === true)
                    {
                        LassoTool.showLassoMenuBox();
                    }
                }
                main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveCanvasNavigator);
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpCanvasNavigator);
                canvasMoveByCanvasNavigatorEventStarted = false;
            }

            function onMouseMoveCanvasNavigator(e:MouseEvent):void
            {
                const scale:Number = UITheme.getUIScale();
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
                UIController.updateCanvasNaigatorCursor();
            }
            moveCanvasAnchorPoint(0, 0);
            if (LassoTool.isStarted)
            {
                LassoTool._lassoMenuBox.visible = false;
                LassoTool.isLassoMenuHiddenTemp = true;
            }
            // 클릭한 지점이 커서 바깥부분일때 강제로 캔버스 중심으로 옮겨줌
            if (!navCursorClicked)
            {
                centerCanvas(main.stage.mouseX, main.stage.mouseY);
            }

            if (canvasMoveByCanvasNavigatorEventStarted === false)
            {
                canvasMoveByCanvasNavigatorEventStarted = true;
                main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpCanvasNavigator, false, InputPriority.DEFAULT);
                main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveCanvasNavigator);
                MouseState.beginDrag("canvasNavigator", function ():void
                    {
                        onMouseUpCanvasNavigator(null);
                    });
            }
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

        // maxOutputEdge > 0이면 긴 축이 그 값 이하가 되도록 처음부터 작게 합성함 (대표색 추출처럼 큰 이미지가 필요 없을때)
        public static function getMergedBitmapdtata(transparentBG:Boolean, layer1merge:Boolean, layer2merge:Boolean, clipRect:Rectangle, maxOutputEdge:Number = 0):BitmapData
        {
            var xBitmapData1:BitmapData;
            var xBitmapData11:BitmapData;
            var xDrawLayer:Sprite;
            var xBGCOLOR:uint;
            var alpha:Number;
            var mat:Matrix;
            var bmpd:BitmapData;
            if (ReplayState.isReplayModeON)
            {
                xBitmapData1 = ReplayDrawer.rCanvasLayer1BitmapData;
                xBitmapData11 = ReplayDrawer.rCanvasLayer2BitmapData;
                xDrawLayer = ReplayDrawer.rCanvasDrawLayer;
                xBGCOLOR = ReplayState.RCANVAS_BG_COLOR;
                alpha = ReplayDrawCommands.getLineStyleAlpha();
            }
            else
            {
                xBitmapData1 = canvasLayer1BitmapData;
                xBitmapData11 = canvasLayer2BitmapData;
                xDrawLayer = canvasDrawLayer;
                xBGCOLOR = CANVAS_BG_COLOR;
                alpha = 1.0;
            }
            const sourceWidth:Number = (clipRect !== null) ? clipRect.width : xBitmapData1.width;
            const sourceHeight:Number = (clipRect !== null) ? clipRect.height : xBitmapData1.height;
            const longEdge:Number = (sourceWidth > sourceHeight) ? sourceWidth : sourceHeight;
            const scale:Number = (maxOutputEdge > 0 && longEdge > maxOutputEdge) ? maxOutputEdge / longEdge : 1.0;
            if (scale !== 1.0)
            {
                // 축소할때 최소길이 1 유지
                bmpd = new BitmapData(Math.max(1, Math.floor(sourceWidth * scale)), Math.max(1, Math.floor(sourceHeight * scale)), true, (transparentBG) ? 0 : 0xFF000000 | xBGCOLOR);
                mat = new Matrix();
                if (clipRect !== null)
                {
                    mat.translate(-clipRect.x, -clipRect.y);
                }
                mat.scale(scale, scale);
            }
            else if (clipRect !== null)
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
            if (ReplayDrawer.isLayer2SelectedReplayMode()) // 레이어 2번을 그리고 있을때
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
            mirrorON = !mirrorON;
            ReplayState.mirrorCommandReady = !ReplayState.mirrorCommandReady;
            mirrorBmpdDrawmode();
            canvasInfoBox.setMirror(mirrorON);
            // 회전각 부호를 바꿔야 제대로 mirror가됨
            moveCanvasAnchorPoint(p.x, p.y); // regpoint를 회전한 캔버스 중점으로 두고
            if (canvasOnly === false) // 보통 미러할때, canvasonly가 true일때는 appdata에서 바꿔줄때 밖에 없음
            {
                canvasAnchorPoint.rotation = -canvasAnchorPoint.rotation; // 반대각으로 세팅
                ReplayDrawer.setRcursorRotation(canvasAnchorPoint.rotation);
                ReferenceLayerController.mirrorRefLayerImage();
            }
            CanvasGridOverlay.updateGridMirror(mirrorON);
            const halfCanvas:Number = (main.stage.stageWidth - SidebarController.sideBar.getWidth()) / 2;
            var stageHalf:Number = (SidebarController.sideBar.visible === false) ? main.stage.stageWidth / 2
                : (SidebarController.isRightSidebar) ? halfCanvas
                : UIController.STAGE_LEFT_OFFSET + halfCanvas;
            // 창 절반을 기준점으로 앵커포인트 x축 이동.
            canvasAnchorPoint.x += Math.round((stageHalf - p.x) * 2);
            UIController.updateCanvasNaigatorCursor();
            FileManager.isFileAlreadySaved = false; // 미러도 화면이 바뀌기 때문에 세이브 플래그 꺼줌
            ReplayDrawer.mirrorRCursorPos();

            CanvasController.canvasNavigatorBox.updateImage();
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
            }
        }

        public static function mirrorBmpdDrawmode():void
        {
            var tmpbmpd:BitmapData = new BitmapData(canvasLayer1BitmapData.width, canvasLayer1BitmapData.height, true, 0);
            var flipMat:Matrix = new Matrix(-1, 0, 0, 1, canvasLayer1BitmapData.width);
            tmpbmpd.draw(canvasLayer1BitmapData, flipMat);
            copyPixels(canvasLayer1BitmapData, tmpbmpd);
            tmpbmpd.fillRect(new Rectangle(0, 0, canvasLayer1BitmapData.width, canvasLayer1BitmapData.height), 0);
            tmpbmpd.draw(canvasLayer2BitmapData, flipMat);
            copyPixels(canvasLayer2BitmapData, tmpbmpd);
            tmpbmpd.dispose();
            tmpbmpd = null;
        }

        public static function applyCavnvasSizeDrawMode(w:Number, h:Number, moveX:Number = 0, moveY:Number = 0, centerMovedFlag:Boolean = false):void
        {
            setCavnvasSizeDrawMode(w, h, moveX, moveY, centerMovedFlag);
            updateCanvasPanelColorAndSize();
        }

        public static function syncDrawModeCanvasSizeToReplayMode(w:Number, h:Number):void
        {
            if (CANVAS_WIDTH === w && CANVAS_HEIGHT === h)
            {
                return;
            }

            updateCanvasPanelMask(w, h);

            // 실제 레이어는 이미 리플레이 결과로 교체되었으므로
            // 임시 그리기 버퍼만 새 크기로 준비.
            const oldDrawBitmapData:BitmapData = canvasDrawLayerBitmapData;

            canvasDrawLayerBitmapData = new BitmapData(w, h, true, 0);
            canvasDrawLayerBitmap.bitmapData = canvasDrawLayerBitmapData;

            if (oldDrawBitmapData !== null)
            {
                oldDrawBitmapData.dispose();
            }

            // 이 함수는 이전 CANVAS_WIDTH/HEIGHT와 새 크기의 차이를 사용.
            // 따라서 크기 변수 갱신보다 먼저 호출해야 함.
            ReferenceLayerController.updateRefLayerImagePos(w, h, false);

            CANVAS_WIDTH = w;
            CANVAS_HEIGHT = h;
        }

        public static function setCavnvasSizeDrawMode(w:Number, h:Number, moveX:Number = 0, moveY:Number = 0, centerMovedFlag:Boolean = false):void
        {
            if (CANVAS_WIDTH === w && CANVAS_HEIGHT === h)
            {
                return;
            }

            const maxSize:uint = CANVAS_MAX_SIZE;

            if (w > maxSize)
            {
                w = maxSize;
            }
            else if (w < 1)
            {
                w = 1;
            }

            if (h > maxSize)
            {
                h = maxSize;
            }
            else if (h < 1)
            {
                h = 1;
            }

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
            {
                canvasLayer1Bitmap.bitmapData.dispose();
            }

            canvasLayer1Bitmap.bitmapData = canvasLayer1BitmapData;

            if (canvasLayer2Bitmap.bitmapData)
            {
                canvasLayer2Bitmap.bitmapData.dispose();
            }

            canvasLayer2Bitmap.bitmapData = canvasLayer2BitmapData;

            // todo applyCanvasBGColorDrawMode로 옮겨야 할것 같은데 centerMovedFlag를 전역 상태로 처리해주어야하나? 함수끼리 통신해야하니까
            // canvas width가 갱신되게 전에 업데이트 해야함
            ReferenceLayerController.updateRefLayerImagePos(w, h, centerMovedFlag);
            CANVAS_WIDTH = w;
            CANVAS_HEIGHT = h;
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
                xAnc = ReplayDrawer.rCanvasAnchorPoint;
                xCanvas = ReplayDrawer.rCanvasPanel;
                xZoomed = ReplayState.rCanvasZoomMultiplier;
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
            UIController.stageBG.name = "stageBG";
            ReferenceLayerController.canvasRefLayer.name = "canvasRefLayer";
            CanvasGridOverlay.canvasGrid.name = "canvasGrid";
            canvasFlashEffect.name = "canvasFlash";
            LassoTool.lassoLayer1.name = "lassoBox1";
            LassoTool.lassoLayer1.addChild(LassoTool.lassoLayer1Bitmap);
            LassoTool.lassoLayer1.addChild(LassoTool.lassoDraw);
            LassoTool.lassoLayer1.addChild(LassoTool.lassoDrawCloseLine);
            LassoTool.lassoLayer1.visible = false;
            LassoTool.lassoLayer2.name = "lassoBox2";
            LassoTool.lassoLayer2.addChild(LassoTool.lassoLayer2Bitmap);
            LassoTool.lassoLayer2.visible = false;
            // setCanvasBGColorDrawMode는 같은 색이면 바로 리턴하므로, 초기값(흰색)은 스크래치 패드에 전달되지 않아
            // 최초 실행시 패드 배경이 안 그려졌음. 초기 색은 직접 전달함
            ColorPickerController.colorPickerBox.scratchPad.updateBGColor(CANVAS_BG_COLOR);
            updateCanvasPanelMask(CANVAS_WIDTH, CANVAS_HEIGHT);
            ReferenceLayerController.canvasRefLayer.alpha = ReferenceLayerController.refLayerLastAlpha;
            ReferenceLayerController.canvasRefLayer.addChild(ReferenceLayerController.canvasRefLayerBitmap);
            canvasDrawLayer.addChild(canvasDrawLayerBitmap);
            canvasDrawLayer.addChild(canvasDrawLayerChild);
            canvasDrawLayer.blendMode = "layer"; // 캔버스1이랑 알파 불투명도가 겹치지 않게 layer모드로 해줌
            ReplayDrawer.rReplayFOFOCursor.visible = false;
            canvasPanel.addChild(ReferenceLayerController.canvasRefLayer);
            canvasPanel.addChild(canvasLayer2Bitmap);
            canvasPanel.addChild(LassoTool.lassoLayer2);
            canvasPanel.addChild(canvasLayer1Bitmap);
            canvasPanel.addChild(LassoTool.lassoLayer1);
            canvasPanel.addChild(canvasDrawLayer);
            canvasPanel.addChild(CanvasGridOverlay.canvasGrid);
            canvasPanel.addChild(ReplayDrawer.rReplayFOFOCursor);
            // canvasrotate가 중점으로 올수있게 위치를 절반으로세팅
            canvasPanel.x = Math.floor(-canvasPanel.width / 2);
            canvasPanel.y = Math.floor(-canvasPanel.height / 2);
            canvasAnchorPoint.addChild(canvasPanel);
            main.stage.addChild(UIController.stageBG);
            main.stage.addChild(EyeDropperTool.eyedropperLens);
            main.stage.addChild(LassoTool._lassoMenuBox);
            main.stage.addChild(canvasAnchorPoint);
            main.stage.addChild(PenSizePreviewCursor.getCursorShape());
            main.stage.setChildIndex(canvasAnchorPoint, 0);
            main.stage.setChildIndex(UIController.stageBG, 0);
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
                    PenSizePreviewCursor.updateZoom(zoomValue);
                }
                if (LassoTool.isStarted)
                {
                    LassoTool.redrawLassoOutline();
                }
            }
            else
            {
                ReplayState.rCanvasZoomMultiplier = zoomValue;
                xAnc = ReplayDrawer.rCanvasAnchorPoint;
                if (ReplayState.rAirBrushSize > 0)
                {
                    ReplayDrawer.blurReplayCanvasByValue(ReplayState.rAirBrushSize);
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
            ReplayDrawer.updateReplayCursorScale(zoomValue);
        }

        // check box position함수는 요소 전체가 창에서 넘어가만 않게 하는거고
        public static function keepCanvasPanelInStage(replayMode:Boolean = false):void
        {
            var xAnc:Sprite;
            var xCanvas:Bitmap;
            if (replayMode)
            {
                xAnc = ReplayDrawer.rCanvasAnchorPoint;
                xCanvas = ReplayDrawer.rCanvasLayer1Bitmap;
            }
            else
            {
                xAnc = canvasAnchorPoint;
                xCanvas = canvasLayer1Bitmap;
            }
            const offset:int = 100; // 최소 100픽셀 은 보여야함
            const bounds:Object = Utils.getBoundRect(xCanvas);
            const leftLimit:Number = UIController.STAGE_LEFT_OFFSET + offset;
            const rightLimit:Number = main.stage.stageWidth - (UIController.STAGE_RIGHT_OFFSET + offset);
            const topLimit:Number = UIController.STAGE_TOP_OFFSET + offset;
            const bottomLimit:Number = main.stage.stageHeight - (UIController.STAGE_BOTTOM_OFFSET + offset);
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
            var center:Point = UIController.getStageCenterPos(mode);
            // mode "capture"는 중심 좌표 계산용이고 대상 캔버스는 현재 모드(리플레이/드로우)를 따라감
            if (mode === "replay" || (mode === "capture" && ReplayState.isReplayModeON))
            {
                xAnc = ReplayDrawer.rCanvasAnchorPoint;
                xCanvas = ReplayDrawer.rCanvasPanel;
                w = ReplayState.RCANVAS_WIDTH;
                h = ReplayState.RCANVAS_HEIGHT;
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

        public static function fitCanvasToViewportMargin(fitting:Boolean = false):void
        {
            if (!ReplayState.isReplayModeON && !CaptureController.isCaptureModeON)
            {
                return;
            }
            const uiscale:Number = UITheme.getUIScale();
            const offsetX:Number = 44 + UIController.STAGE_LEFT_OFFSET + UIController.STAGE_RIGHT_OFFSET;
            const offsetY:Number = (CaptureController.isCaptureModeON) ? (UIController.topBar.BARSIZE) * uiscale + 42 * uiscale : (UIController.topBar.BARSIZE) * uiscale + 42 * uiscale;
            const stw:int = main.stage.stageWidth - offsetX;
            const sth:int = main.stage.stageHeight - offsetY - UIController.STAGE_BOTTOM_OFFSET;
            var xBitmap1:Bitmap;
            var xBitmap11:Bitmap;
            var xAnc:Sprite;
            var canvasWidth:Number;
            var canvasHeight:Number;
            if (ReplayState.isReplayModeON)
            {
                xBitmap1 = ReplayDrawer.rCanvasLayer1Bitmap;
                xBitmap11 = ReplayDrawer.rCanvasLayer2Bitmap;
                xAnc = ReplayDrawer.rCanvasAnchorPoint;
                if (fitting)
                {
                    xAnc.scaleX = 1.0;
                    xAnc.scaleY = 1.0; // 크기를 원래대로 해놓고 해야 길이 측정이 됨
                    const b:Rectangle = ReplayDrawer.rCanvasLayer1Bitmap.getBounds(main.stage);
                    canvasWidth = b.right - b.left;
                    canvasHeight = b.bottom - b.top;
                }
                else
                {
                    canvasWidth = ReplayState.RCANVAS_WIDTH;
                    canvasHeight = ReplayState.RCANVAS_HEIGHT;
                }
            }
            else
            {
                xBitmap1 = canvasLayer1Bitmap;
                xBitmap11 = canvasLayer2Bitmap;
                xAnc = canvasAnchorPoint;
                canvasWidth = CANVAS_WIDTH;
                canvasHeight = CANVAS_HEIGHT;
            }
            if (CaptureController.isCaptureModeON)
            {
                if (CaptureController.captureCanvasRotationStep === 1 || CaptureController.captureCanvasRotationStep === 3)
                {
                    const widthSave:Number = canvasWidth;
                    canvasWidth = canvasHeight;
                    canvasHeight = widthSave;
                }
            }
            const scaleW:Number = stw / canvasWidth;
            const scaleH:Number = sth / canvasHeight;
            var scale:Number = Math.min(scaleW, scaleH);
            if (!fitting && scale > 1.0)
            {
                scale = 1.0;
            }
            if (CaptureController.isCaptureModeON)
            {
                xAnc.rotation = 90 * CaptureController.captureCanvasRotationStep;
            }
            if (ReplayState.isReplayModeON && !ReplayState.isReplayCanvasFitToWindow)
            {
                ReplayState.isReplayFinishedWithFiwWindow = true;
            }
            if (CaptureController.isCaptureModeON)
            {
                updateCanvasScale(scale, ReplayState.isReplayModeON);
                centerCanvas("capture");
            }
            else if (ReplayState.isReplayModeON)
            {
                updateCanvasScale(scale, ReplayState.isReplayModeON);
                centerCanvas("replay");
            }
            if (!fitting || ReplayState.isReplayFinished)
            {
                xBitmap1.smoothing = true;
                xBitmap11.smoothing = true;
            }
        }

        public static function updateCanvasPanelColorAndSize():void
        {
            canvasPanel.graphics.clear();
            canvasPanel.graphics.beginFill(CANVAS_BG_COLOR);
            canvasPanel.graphics.drawRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
            canvasPanel.graphics.endFill();

            keepCanvasPanelInStage();
            canvasNavigatorBox.changeprevBitmapBGColor(CANVAS_BG_COLOR);
            canvasInfoBox.setSize(CANVAS_WIDTH, CANVAS_HEIGHT);

            if (CanvasGridOverlay.gridGapMultiplier > 0)
            {
                CanvasGridOverlay.drawGrid();
            }
        }

        public static function applyCanvasBGColorDrawMode(color:uint):void
        {
            setCanvasBGColorDrawMode(color);
            updateCanvasPanelColorAndSize();
        }

        public static function setCanvasBGColorDrawMode(color:uint):void
        {
            if (color === CANVAS_BG_COLOR)
            {
                return;
            }

            FileManager.isFileAlreadySaved = false;
            CANVAS_BG_COLOR = color;

            if (ColorPickerController.colorPickerBox.scratchPad)
            {
                ColorPickerController.colorPickerBox.scratchPad.updateBGColor(color);
            }
        }

        public static function resetAllCanvasAndReplayData():void
        {
            // 길게 누르는 동안 worker가 시작되었을 수 있음
            if (FileManager.isReplayDataLocked())
            {
                FileManager.showReplayDataLockedHint();
                return;
            }
            clearCanvas();
            centerCanvas("replay");
            centerCanvas("draw");
            resetZoomDrawMode();
            resetRotationDrawMode();
            ReplayController.resetCanvasAndReplayData();

            // reset vars보다 뒤에 와야함
            // addundo에서 활성화 해주고 있기 때문에
            FileManager.setNewFileAvailable(false);
            AppWindowState.markWindowTitleAsDirty();
            UIController.updateCanvasNaigatorCursor();
        }

        // 드로우 모드 캔버스 상태를 리플레 캔버스 상태랑 똑같이 만들어줌
        public static function applyReplayCanvasToDrawModeCanvas():void
        {
            canvasLayer1BitmapData = updateBitmapData(canvasLayer1BitmapData, ReplayDrawer.rCanvasLayer1BitmapData, canvasLayer1Bitmap);
            canvasLayer2BitmapData = updateBitmapData(canvasLayer2BitmapData, ReplayDrawer.rCanvasLayer2BitmapData, canvasLayer2Bitmap);
            syncDrawModeCanvasSizeToReplayMode(ReplayDrawer.rCanvasLayer1BitmapData.width, ReplayDrawer.rCanvasLayer1BitmapData.height);
            setCanvasBGColorDrawMode(ReplayState.RCANVAS_BG_COLOR);
            updateCanvasPanelColorAndSize();
            FileManager.isFileAlreadySaved = false;
            ReplayController.preserveDrawMirrorStateAfterReplayCopy();
            CanvasController.canvasNavigatorBox.updateImage();
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
                ImageViewWindow.updateCanvasWindowBitmapSize();
            }
        }

        public static function copyPixels(target:BitmapData, source:BitmapData):void
        {
            if (target.width !== source.width || target.height !== source.height)
            {
                HintController.showMouseHintTemp("CanvasController.copyPixels() failed : Not same size", 10.0);
                return;
            }

            copyPixelRect.setTo(0, 0, source.width, source.height);
            target.lock();
            target.copyPixels(source, copyPixelRect, Utils.ZERO_POINT, null, null, false);
            target.unlock();
        }
    }
}
