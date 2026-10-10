package Modules.L4UI.Tools
{
    import Modules.UIEngine.CanvasNavigator;
    import Modules.UIEngine.UITheme;
    import Modules.InputPriority;
    import Modules.ReferenceLayerController;

    import Symbols.LassoMenuSet;

    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.Stage;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.utils.getTimer;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import Symbols.RotateCursorSet;
    import Modules.L4UI.ColorPickerController;
    import Modules.L5App.InputManager.DrawModeInput;
    import Modules.L4UI.ImageViewWindow;
    import Modules.L5App.InputManager.InputManager;
    import Modules.L5App.ReplayEngine.ReplayController;
    import Modules.L4UI.SidebarController;
    import Modules.L4UI.Tools.ToolPanel;
    import Modules.L3Feature.UndoController;
    import Modules.L1Data.KeyState;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L1Data.ToolState;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L2Engine.LassoLayers;
    import Modules.L2Engine.UndoHistory;
    import Modules.L2Engine.ReplayEngine.ReplayState;
    import Modules.L4UI.HintStrings;
    import Modules.L3Feature.DrawEngine.CanvasLayers;
    import Modules.L1Data.DragInteraction;
    import Modules.L1Data.MouseState;
    import Modules.L2Engine.DrawEngine.StrokeBuffer;
    import Modules.L1Data.Utils;
    import Modules.L4UI.Tools.DottedLineTool;
    import Modules.L4UI.CaptureEngine.CaptureController;

    // 층: L4 UI - 올가미 선택과 이동·회전·크기·미러
    public class LassoTool
    {
        // todo: 포멧팅 필요

        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        private static const LASSO_1PX_MOVE_UP:int = (1 << 0);
        private static const LASSO_1PX_MOVE_DOWN:int = (1 << 1);
        private static const LASSO_1PX_MOVE_LEFT:int = (1 << 2);
        private static const LASSO_1PX_MOVE_RIGHT:int = (1 << 3);

        public static var _lassoMenuBox:LassoMenuSet = new LassoMenuSet(); // 라소툴 버튼

        private static var _isStarted:Boolean = false; // 라소툴로 영역 선택하면 올려줌
        private static var _isLassoMenuHiddenTemp:Boolean = false; // 툴 고정 상태에서 줌툴 클릭 시 메뉴를 잠시 숨기는 플래그
        public static var lassoFirstData:Array = []; // 이 값과 비교해서 달라진 게 있으면 OK할 때 적용
        private static var isLassoMirrorON:Boolean = false; // 라소 mirror 클릭할 때마다 반전

        public static var lassoTransformData:Array = []; // 라소 변형 데이터
        public static var isLassoImageCopied:Boolean = false; // lasso 복사 누르면 올려줌

        public static var lassoLayer1LastBitmapdata:BitmapData; // copy나 취소했을 때 원래대로 돌려주는 이미지
        public static var lassoLayer2LastBitmapdata:BitmapData; // copy나 취소했을 때 원래대로 돌려주는 이미지
        public static var lassoLayerCommandData:Array = null; // 스왑/머지 순서 저장

        public static var isLassoLayerSwapButtonClicked:Boolean; // 스왑 버튼 클릭할 때마다 true/false 변경

        public static var lassoAndRefLayerBoxLastPos:Array = [0, 0, 0, 0, 0, 0, 0, 0]; // 사이즈바 켜줄때 임시로 사이드바 안쪽으로 밀려나게 하고 위치가 변경되지 않았으면 원래대로 복귀해줌

        private static function setOptimizeView(flag:Boolean):void
        {
            LassoLayers.lassoDraw.visible = !flag;
            LassoLayers.lassoDrawCloseLine.visible = !flag;
            LassoLayers.lassoLayer1Bitmap.smoothing = !flag;
            LassoLayers.lassoLayer2Bitmap.smoothing = !flag;
            _lassoMenuBox.visible = !flag;
        }

        public static function redrawLassoOutline():void
        {
            if (!_isStarted || lassoTransformData.length < 2)
                return;

            const pts:Array = lassoTransformData[1];
            const len:uint = pts.length;
            if (len < 2)
                return;

            // 라소 이미지 리사이즈 배율까지 반영해야 화면에서 늘 1px / 5px 로 보임
            DottedLineTool.setLineScale(CanvasView.canvasZoomMultiplier * Math.abs(LassoLayers.lassoLayer1.scaleY));

            LassoLayers.lassoDraw.graphics.clear(); // lassoDraw.x/y 보정값은 그대로 두므로 위치는 유지됨
            DottedLineTool.moveTo(LassoLayers.lassoDraw.graphics, pts[0][0], pts[0][1]);
            for (var i:uint = 1;i < len;i++)
            {
                DottedLineTool.lineTo(pts[i][0], pts[i][1]);
            }
            DottedLineTool.lineTo(pts[0][0], pts[0][1], true);
        }

        private static function resetLassoLayerScale():void
        {
            if (LassoLayers.lassoLayer1.scaleY !== 1.0)
            {
                LassoLayers.lassoLayer1.scaleX = (isLassoMirrorON) ? -1.0 : 1.0;
                LassoLayers.lassoLayer1.scaleY = 1.0;
                LassoLayers.lassoLayer2.scaleX = LassoLayers.lassoLayer1.scaleX;
                LassoLayers.lassoLayer2.scaleY = LassoLayers.lassoLayer1.scaleY;
                LassoTool.redrawLassoOutline();
            }
        }
        private static function resetLassoLayerRotation():void
        {
            if (LassoLayers.lassoLayer1.rotation !== 0)
            {
                LassoLayers.lassoLayer1.rotation = 0;
                LassoLayers.lassoLayer2.rotation = 0;
            }
        }
        public static function get isStarted():Boolean
        {
            return _isStarted;
        }

        public static function get lassoMenuBox():LassoMenuSet
        {
            return _lassoMenuBox;
        }

        public static function get isLassoMenuHiddenTemp():Boolean
        {
            return _isLassoMenuHiddenTemp;
        }

        public static function set isLassoMenuHiddenTemp(flag:Boolean):void
        {
            _isLassoMenuHiddenTemp = flag;
        }

        public static function showLassoMenuBox():void
        {
            _lassoMenuBox.visible = true;
            _isLassoMenuHiddenTemp = false;
            KeyState.resetLastKey();
        }

        public static function mergeLassoImageToRefLayer():void
        {
            if (isLassoImageCopied)
            {
                applyLassoBoxImageToCanvas(true);
                disposeAllLayerBitmapData();
                resetLassoBox();
            }
            else
            {
                if (UndoHistory.isDeepUndoEnabled)
                {
                    UndoController.applyDeepUndo();
                }
                const lassoInfo:Array = applyLassoBoxImageToCanvas(true);
                const point1:Vector.<Number> = lassoTransformData[0].concat();
                const point2:Array = lassoTransformData[1].concat();
                var l1:Boolean = true;
                var l2:Boolean = true;
                if (CanvasLayers.checkedLayer === 1 || (DrawCanvas.canvasLayer1Bitmap.visible && !DrawCanvas.canvasLayer2Bitmap.visible))
                {
                    l1 = true;
                    l2 = false;
                }
                else if (CanvasLayers.checkedLayer === 2 || (!DrawCanvas.canvasLayer1Bitmap.visible && DrawCanvas.canvasLayer2Bitmap.visible))
                {
                    l1 = false;
                    l2 = true;
                }
                ReplayState.rMemoryDataBuffer.push(["lassodel2", point1, point2, lassoInfo, isLassoImageCopied, l1, l2]);
                UndoHistory.addNew();
                disposeAllLayerBitmapData();
                resetLassoBox();
            }
            if (ReferenceLayerController.canvasRefLayer.visible === false || ReferenceLayerController.refLayerLastAlpha === 0.0)
            {
                ReferenceLayerController.updateRefLayerOpacityCursorPosByValue(0.5);
                ReferenceLayerController.refLayerLastAlpha = 0.5;
                ReferenceLayerController.canvasRefLayer.visible = true;
                ReferenceLayerController.canvasRefLayer.alpha = 0.5;
            }
            ReferenceLayerController.canvasRefLayerBitmap.smoothing = true;
        }

        // 1초정도 켜지지 않게함
        public static function restoreLassoAndRefLayerBoxLastPos():void
        {
            const arr:Array = lassoAndRefLayerBoxLastPos;
            if ((arr[0] !== arr[2] || arr[1] !== arr[3])
                    && _lassoMenuBox.x === arr[2] && _lassoMenuBox.y === arr[3])
            {
                _lassoMenuBox.x = arr[0];
                _lassoMenuBox.y = arr[1];
            }
            if ((arr[4] !== arr[6] || arr[5] !== arr[7])
                    && ReferenceLayerController.refLayerMenuBox.x === arr[6] && ReferenceLayerController.refLayerMenuBox.y === arr[7])
            {
                ReferenceLayerController.refLayerMenuBox.x = arr[4];
                ReferenceLayerController.refLayerMenuBox.y = arr[5];
            }
        }

        public static function recordLassoAndRefLayerBoxLastPos():void
        {
            const arr:Array = lassoAndRefLayerBoxLastPos;
            if (_isStarted)
            {
                arr[0] = _lassoMenuBox.x;
                arr[1] = _lassoMenuBox.y;
                UIController.keepBoxInsideViewPort(_lassoMenuBox);
                arr[2] = _lassoMenuBox.x;
                arr[3] = _lassoMenuBox.y;
            }
            if (ReferenceLayerController.isRefLayerMenuON)
            {
                arr[4] = ReferenceLayerController.refLayerMenuBox.x;
                arr[5] = ReferenceLayerController.refLayerMenuBox.y;
                UIController.keepBoxInsideViewPort(ReferenceLayerController.refLayerMenuBox);
                arr[6] = ReferenceLayerController.refLayerMenuBox.x;
                arr[7] = ReferenceLayerController.refLayerMenuBox.y;
            }
        }

        private static function mergeLassoImageIntoToRefLayer():void
        {
            ReferenceLayerController.handleOneMoreClickMergeIntoRefLayer(
                    _lassoMenuBox,
                    _lassoMenuBox.lassoRefLayer,
                    HintStrings.STRING_MERGE_INTO_REFLAYER,
                    function ():void
                    {
                        mergeLassoImageToRefLayer();
                        ReferenceLayerController.openRefLayerMenu();
                    });
        }

        private static function lassoMenuHintONEvent(e:MouseEvent):void
        {
            if (!_isStarted)
            {
                main.stage.removeEventListener(MouseEvent.MOUSE_OVER, lassoMenuHintONEvent);
                return;
            }
            if (_lassoMenuBox.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
            {
                if (_lassoMenuBox.getHintStr() !== "Lasso tool")
                {
                    _lassoMenuBox.hint("Lasso tool");
                }
                return;
            }
            if (MouseState.isDragging === true)
            {
                return;
            }
            _lassoMenuBox.hint(HintStrings.getHintFromTargetNameLassoTool(e.target.name));
        }

        public static function addLassoLayerMergeCommand(command:int):void
        {
            if (lassoLayerCommandData === null)
            {
                lassoLayerCommandData = [];
            }
            // 0번 스왑명령, 1번 머지 명령
            if (command === 0)
            {
                if (lassoLayerCommandData.length > 0 && lassoLayerCommandData[lassoLayerCommandData.length - 1] === 0)
                {
                    lassoLayerCommandData.pop();
                }
                else
                {
                    lassoLayerCommandData.push(0);
                }
            }
            else if (lassoLayerCommandData[lassoLayerCommandData.length - 1] !== command)
            {
                lassoLayerCommandData.push(command);
            }
        }

        private static function mergeLayerByLassoTool():void
        {
            _lassoMenuBox.lassoLayerMerge.alpha = UITheme.OFFALPHA;
            LassoLayers.mergeLassoImage();
            addLassoLayerMergeCommand(1);
        }
        private static function swapLayerByLassoTool():void
        {
            if (_lassoMenuBox.lassoLayerSwap.alpha < 1.0)
            {
                return;
            }
            isLassoLayerSwapButtonClicked = !isLassoLayerSwapButtonClicked;
            LassoLayers.swapLassoImage();
            addLassoLayerMergeCommand(0);
            _lassoMenuBox.hint(HintStrings.getLassoMenuHintSwapLayer());
            ToolPanel.playLayerSwapEffect(_lassoMenuBox.lassoLayerSwap);
        }

        private static function copyCanvasImageToLassoTool():void
        {
            if (isLassoImageCopied)
            {
                return;
            }
            isLassoImageCopied = true;
            _lassoMenuBox.lassoCopy.alpha = UITheme.OFFALPHA;
            restoreToLastBmpd();
        }

        private static function startLassoImageRotation():void
        {
            var getAngle:Function = UIController.showCanvasRotateCursorMouseDrag(LassoLayers.lassoLayer1);
            function onDragStart():void
            {
                setOptimizeView(true);
            }
            function onMouseUp():void
            {
                getAngle = null;
                UIController.hideCanvasRotateCursor();
                setOptimizeView(false);
            }
            function onMouseMove():void
            {
                const angle:Number = getAngle(false);
                LassoLayers.lassoLayer1.rotation = angle;
                LassoLayers.lassoLayer2.rotation = angle;
            }
            DragInteraction.start(onDragStart, onMouseMove, onMouseUp);
        }

        private static function startLassoImageResize():void
        {
            const mirrorScale:Number = (LassoLayers.lassoLayer1.scaleX < 0) ? -1.0 : 1.0;
            var getScale:Function = LassoTool.updateImageScaleMouseDrag(LassoLayers.lassoLayer1.scaleX);

            function onDragStart():void
            {
                setOptimizeView(true);
                HintController.showMouseHint(HintStrings.getImageScaleHint(LassoLayers.lassoLayer1.width, LassoLayers.lassoLayer1.height, Math.abs(LassoLayers.lassoLayer1.scaleX), false));
            }
            function onMouseUp():void
            {
                getScale = null;
                UIController.keepBoxInsideViewPort(_lassoMenuBox);
                HintController.hideMouseHint();
                LassoTool.redrawLassoOutline();
                setOptimizeView(false);
            }
            function onMouseMove():void
            {
                const scale:Number = getScale(main.stage.mouseX, main.stage.mouseY);
                LassoLayers.lassoLayer1.scaleX = scale * mirrorScale;
                LassoLayers.lassoLayer1.scaleY = scale;
                LassoLayers.lassoLayer2.scaleX = LassoLayers.lassoLayer1.scaleX;
                LassoLayers.lassoLayer2.scaleY = LassoLayers.lassoLayer1.scaleY;
                HintController.showMouseHint(HintStrings.getImageScaleHint(LassoLayers.lassoLayer1.width, LassoLayers.lassoLayer1.height, Math.abs(LassoLayers.lassoLayer1.scaleX), false));
            }
            DragInteraction.start(onDragStart, onMouseMove, onMouseUp);
        }

        public static function hasLassoImageChanges():Boolean
        {
            if (isLassoImageCopied
                    || lassoFirstData[0] !== LassoLayers.lassoLayer1.x
                    || lassoFirstData[1] !== LassoLayers.lassoLayer1.y
                    || lassoFirstData[2] !== LassoLayers.lassoLayer1.scaleX
                    || lassoFirstData[3] !== LassoLayers.lassoLayer1.scaleY
                    || lassoFirstData[4] !== LassoLayers.lassoLayer1.rotation
                    || (lassoLayerCommandData && lassoLayerCommandData.length > 0))
            {
                return true;
            }
            return false;
        }

        private static function startLassoImageMove():void
        {
            var getMovedPos:Function = LassoTool.updateImagePosMouseDrag(LassoLayers.lassoLayer1, CanvasView.canvasAnchorPoint.rotation);
            function onMouseUp():void
            {
                getMovedPos = null;
                UIController.keepBoxInsideViewPort(_lassoMenuBox);
                setOptimizeView(false);
            }
            function onMouseMove():void
            {
                const pos:Point = getMovedPos();
                LassoLayers.lassoLayer1.x = Math.round(pos.x);
                LassoLayers.lassoLayer1.y = Math.round(pos.y);
                LassoLayers.lassoLayer2.x = LassoLayers.lassoLayer1.x;
                LassoLayers.lassoLayer2.y = LassoLayers.lassoLayer1.y;
            }
            function onDragStart():void
            {
                setOptimizeView(true);
            }
            DragInteraction.start(onDragStart, onMouseMove, onMouseUp);
        }

        public static function isHintAvailableWithLassoToolStarted(target:DisplayObject):Boolean
        {
            if (target === ToolPanel.toolBox.toolZoomIn
                    || target === ToolPanel.toolBox.toolZoomOut
                    || target === ToolPanel.toolBox.toolRotate
                    || target === SidebarController.sideBarScrollBar)
            {
                return true;
            }
            return false;
        }

        public static function setAlphaButtonsOnLassoTool(alpha:Number):void
        {
            ColorPickerController.colorPickerBox.alpha = alpha;
            ToolPanel.toolBox.alpha = alpha;
            ToolPanel.toolOptionsBox.alpha = alpha;
            ToolPanel.toolBox.toolMirror.alpha = alpha;
        }

        // ---------------------------------------------------------------------
        // 라소 영역 선택 (드래그로 점을 모으고 마우스 업에서 라소 박스로 옮김)
        // ---------------------------------------------------------------------
        private static const LASSO_PREVIEW_TIMER:String = "LassoDrawDelayTimer";

        private static var lassoSelectRect:Vector.<Number>; // left, top, right, bottom순임
        private static var lassoSelectPoints:Array; // [[x, y], ...] 마우스업 후 lassoTransformData[1]로 그대로 넘겨짐
        private static var lassoPreviewDrawnCount:uint = 0; // 증분 그리기: 점선으로 이미 그린 점 개수

        private static const SELECTION_DRAG_OWNER:String = "lassoSelection";
        private static var isLassoSelecting:Boolean = false;
        private static var lassoStartStamp:int = 0; // 올가미를 시작한 getTimer 값, 적용할때 타이밍 시트에 연출 시간(시작~적용)으로 기록함

        public static function startLassoSelection():void
        {
            // mouseUp을 놓쳐서 이전 선택이 열려있으면 먼저 마무리함
            if (isLassoSelecting)
            {
                finishLassoSelection();
            }

            if (_isStarted === true || CanvasLayers.isAllLayerInvisible())
                return;

            const clickX:Number = StrokeBuffer.canvasDrawLayerChild.mouseX;
            const clickY:Number = StrokeBuffer.canvasDrawLayerChild.mouseY;

            lassoStartStamp = getTimer();
            lassoPreviewDrawnCount = 0;
            _lassoMenuBox.hint("Lasso tool");
            LassoLayers.lassoDraw.x = 0;
            LassoLayers.lassoDraw.y = 0;
            lassoSelectRect = new <Number>[clickX, clickY, clickX, clickY];
            lassoSelectPoints = [[clickX, clickY]];
            lassoTransformData = [];
            StrokeBuffer.canvasDrawLayer.alpha = 1.0; // 알파값이 조정되어 있을 수도 있기 때문에 해줌
            LassoLayers.lassoDraw.graphics.clear();
            LassoLayers.lassoDrawCloseLine.graphics.clear();
            LassoLayers.lassoLayer1.visible = true;
            DottedLineTool.setLineScale(CanvasView.canvasZoomMultiplier);

            const needLayer1:Boolean = DrawCanvas.canvasLayer1Bitmap.visible && CanvasLayers.checkedLayer !== 2;
            const needLayer2:Boolean = DrawCanvas.canvasLayer2Bitmap.visible && CanvasLayers.checkedLayer !== 1;
            if (needLayer1)
            {
                if (lassoLayer1LastBitmapdata != null)
                    lassoLayer1LastBitmapdata.dispose();

                lassoLayer1LastBitmapdata = DrawCanvas.canvasLayer1BitmapData.clone();
            }
            if (needLayer2)
            {
                if (lassoLayer2LastBitmapdata != null)
                    lassoLayer2LastBitmapdata.dispose();

                lassoLayer2LastBitmapdata = DrawCanvas.canvasLayer2BitmapData.clone();
            }

            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveLassoSelection);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpLassoSelection, false, InputPriority.DEFAULT);
            isLassoSelecting = true;
            MouseState.beginDrag(SELECTION_DRAG_OWNER, finishLassoSelection);
        }

        private static function resetLassoSelectionData():void
        {
            lassoPreviewDrawnCount = 0;
            LassoLayers.lassoDrawCloseLine.graphics.clear();

            if (lassoSelectRect)
                lassoSelectRect.length = 0;
            if (lassoSelectPoints)
                lassoSelectPoints.length = 0;
            lassoSelectRect = null;
            lassoSelectPoints = null;
        }

        private static function drawLassoPreviewLine(isFinal:Boolean = false):void
        {
            if (lassoSelectPoints === null || lassoSelectPoints.length < 2)
                return;

            const points:Array = lassoSelectPoints;
            const len:uint = points.length;

            if (lassoPreviewDrawnCount === 0)
            {
                LassoLayers.lassoDraw.graphics.clear();
                DottedLineTool.moveTo(LassoLayers.lassoDraw.graphics, points[0][0], points[0][1]);
                lassoPreviewDrawnCount = 1;
            }

            for (var i:uint = lassoPreviewDrawnCount;i < len;i++)
            {
                DottedLineTool.lineTo(points[i][0], points[i][1]);
            }
            lassoPreviewDrawnCount = len;

            LassoLayers.lassoDrawCloseLine.graphics.clear();

            if (isFinal)
            {
                // 확정: lassoDraw에 점선으로 닫음 (lassoDraw의 좌표 보정을 그대로 따라감)
                DottedLineTool.lineTo(points[0][0], points[0][1], true);
            }
            else
            {
                // 드래그 중: 점선 상태를 건드리지 않고 별도 Shape에 닫는 점선
                DottedLineTool.drawClosingLine(LassoLayers.lassoDrawCloseLine.graphics, points[0][0], points[0][1]);
            }
        }

        private static function setDefaultLassoMenuPos(lassoMenu:LassoMenuSet):void
        {
            const g:Point = LassoLayers.lassoLayer1.localToGlobal(new Point(0, 0));
            const lassoW:Number = (lassoMenu.width > main.stage.stageWidth)
                ? main.stage.stageWidth : lassoMenu.width;
            lassoMenu.x = Math.floor(g.x - lassoW / 2);
            lassoMenu.y = Math.floor(g.y + (((LassoLayers.lassoLayer1.height) / 2) * CanvasView.canvasZoomMultiplier + 20));
        }

        private static function onMouseMoveLassoSelection(e:MouseEvent):void
        {
            const mx:Number = StrokeBuffer.canvasDrawLayerChild.mouseX;
            const my:Number = StrokeBuffer.canvasDrawLayerChild.mouseY;
            const rect:Vector.<Number> = lassoSelectRect;

            lassoSelectPoints.push([mx, my]);

            if (!FOFOTimer.hasTimer(LASSO_PREVIEW_TIMER))
            {
                FOFOTimer.addByName(LASSO_PREVIEW_TIMER, 0.1, false, drawLassoPreviewLine);
            }

            // 사각형 꼭지점 체크
            if (mx < rect[0])
                rect[0] = mx;
            else if (mx > rect[2])
                rect[2] = mx;

            if (my < rect[1])
                rect[1] = my;
            else if (my > rect[3])
                rect[3] = my;
        }

        private static function onMouseUpLassoSelection(e:MouseEvent):void
        {
            finishLassoSelection();
        }

        // 이벤트 객체를 쓰지 않음. mouseUp을 못받는 경우(alt+tab 등)에도 MouseState.finishAllDrags가 직접 호출함
        private static function finishLassoSelection():void
        {
            isLassoSelecting = false;
            MouseState.endDrag(SELECTION_DRAG_OWNER);
            FOFOTimer.remove(LASSO_PREVIEW_TIMER);
            main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveLassoSelection);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpLassoSelection);

            const rect:Vector.<Number> = lassoSelectRect;

            if (Math.abs(rect[0] - rect[2]) < 5 || Math.abs(rect[1] - rect[3]) < 5)
            {
                resetLassoBox();
                return;
            }

            if (rect[0] < 0)
                rect[0] = 0;
            if (rect[1] < 0)
                rect[1] = 0;
            if (rect[2] > DrawCanvas.CANVAS_WIDTH)
                rect[2] = DrawCanvas.CANVAS_WIDTH;
            if (rect[3] > DrawCanvas.CANVAS_HEIGHT)
                rect[3] = DrawCanvas.CANVAS_HEIGHT;

            lassoTransformData.push(rect);
            lassoTransformData.push(lassoSelectPoints);

            var checklayer1:Boolean = DrawCanvas.canvasLayer1Bitmap.visible;
            var checklayer2:Boolean = DrawCanvas.canvasLayer2Bitmap.visible;
            if (CanvasLayers.checkedLayer === 1)
            {
                checklayer1 = true;
                checklayer2 = false;
            }
            else if (CanvasLayers.checkedLayer === 2)
            {
                checklayer1 = false;
                checklayer2 = true;
            }

            if (LassoLayers.moveSelectedAreaToLassoBox(false, rect, lassoSelectPoints, isLassoImageCopied, checklayer1, checklayer2) === false)
            {
                resetLassoBox();
                return;
            }

            drawLassoPreviewLine(true);
            // 라소 메뉴 마우스 커서에보이기
            lassoFirstData = [LassoLayers.lassoLayer1.x, LassoLayers.lassoLayer1.y, LassoLayers.lassoLayer1.scaleX, LassoLayers.lassoLayer1.scaleY, LassoLayers.lassoLayer1.rotation];
            _isStarted = true;
            setDefaultLassoMenuPos(_lassoMenuBox);
            UIController.keepBoxInsideViewPort(_lassoMenuBox);
            if (CanvasLayers.checkedLayer || !checklayer1 || !checklayer2)
            {
                _lassoMenuBox.lassoLayerSwap.alpha = UITheme.OFFALPHA;
                _lassoMenuBox.lassoLayerMerge.alpha = UITheme.OFFALPHA;
            }
            else
            {
                _lassoMenuBox.lassoLayerSwap.alpha = 1.0;
                _lassoMenuBox.lassoLayerMerge.alpha = 1.0;
            }
            LassoLayers.lassoLayer2.visible = true;
            _lassoMenuBox.visible = true;
            Utils.setAsTopChild(_lassoMenuBox);
            if (ReferenceLayerController.isRefLayerMenuON === true)
            {
                ReferenceLayerController.refLayerMenuBox.visible = false;
            }
            setAlphaButtonsOnLassoTool(UITheme.OFFALPHA);
            addInputEventsLassoTool();
        }

        // zoom이나 rotate reg포인트 바뀔때마다
        // 캔버스 판넬위치 따라 다니면서 크기 똑같이 해줌
        public static function applyLassoBoxImageToCanvas(isTransferRefLayer:Boolean):Array
        {
            const lassoBMPScaleX:Number = LassoLayers.lassoLayer1.scaleX;
            const lassoBMPScaleY:Number = LassoLayers.lassoLayer1.scaleY;
            var lassoBMPWidth:Number = LassoLayers.lassoLayer1Bitmap.width * lassoBMPScaleX;
            var lassoBMPHeight:Number = LassoLayers.lassoLayer1Bitmap.height * lassoBMPScaleY;
            if (CanvasLayers.checkedLayer === 2 || DrawCanvas.canvasLayer1Bitmap.visible === false)
            {
                lassoBMPWidth = LassoLayers.lassoLayer2Bitmap.width * lassoBMPScaleX;
                lassoBMPHeight = LassoLayers.lassoLayer2Bitmap.height * lassoBMPScaleY;
            }
            const boxX:Number = LassoLayers.lassoLayer1.x;
            const boxY:Number = LassoLayers.lassoLayer1.y;
            const ang:Number = LassoLayers.lassoLayer1.rotation * Math.PI / 180;
            var posMatrix:Matrix = new Matrix();
            posMatrix.scale(lassoBMPScaleX, lassoBMPScaleY); // 스케일부터 조절해주고
            posMatrix.translate(-lassoBMPWidth / 2, -lassoBMPHeight / 2); // 회전 중심점을 bmp중심으로 옮겨주고
            posMatrix.rotate(ang); // 회전해줌
            posMatrix.translate(boxX, boxY); // 라소박스 위치 그대로 붙여주면됨
            LassoLayers.lassoLayer1Bitmap.smoothing = true;
            LassoLayers.lassoLayer2Bitmap.smoothing = true;
            if (isTransferRefLayer === false)
            {
                if (DrawCanvas.canvasLayer1Bitmap.visible)
                    DrawCanvas.canvasLayer1BitmapData.draw(LassoLayers.lassoLayer1Bitmap, posMatrix);
                if (DrawCanvas.canvasLayer2Bitmap.visible)
                    DrawCanvas.canvasLayer2BitmapData.draw(LassoLayers.lassoLayer2Bitmap, posMatrix);
            }
            else
            {
                var layer1Bmpd:BitmapData;
                var layer2Bmpd:BitmapData;
                if (DrawCanvas.canvasLayer1Bitmap.visible)
                {
                    layer1Bmpd = new BitmapData(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, true, 0);
                    layer1Bmpd.draw(LassoLayers.lassoLayer1Bitmap, posMatrix);
                }
                if (DrawCanvas.canvasLayer2Bitmap.visible)
                {
                    layer2Bmpd = new BitmapData(DrawCanvas.CANVAS_WIDTH, DrawCanvas.CANVAS_HEIGHT, true, 0);
                    layer2Bmpd.draw(LassoLayers.lassoLayer2Bitmap, posMatrix);
                }
                ReferenceLayerController.mergeImageToRefLayer(layer1Bmpd, layer2Bmpd);
                if (layer1Bmpd)
                {
                    layer1Bmpd.dispose();
                    layer1Bmpd = null;
                }
                if (layer2Bmpd)
                {
                    layer2Bmpd.dispose();
                    layer2Bmpd = null;
                }
                ReferenceLayerController.resetRefLayerImageTransform();
            }
            if (lassoLayer1LastBitmapdata)
            {
                lassoLayer1LastBitmapdata.dispose();
                lassoLayer1LastBitmapdata = null;
            }
            if (lassoLayer2LastBitmapdata)
            {
                lassoLayer2LastBitmapdata.dispose();
                lassoLayer2LastBitmapdata = null;
            }
            return [lassoBMPScaleX, lassoBMPScaleY,
                    lassoBMPWidth, lassoBMPHeight,
                    ang, boxX, boxY];
        }

        private static function applyLassoImageToCanvas():void
        {
            if (_isStarted === true)
            {
                if (hasLassoImageChanges() === true) // 사용후에 ok하면 처리해줌
                {
                    if (UndoHistory.isDeepUndoEnabled)
                    {
                        UndoController.applyDeepUndo();
                    }
                    const lassoInfo:Array = applyLassoBoxImageToCanvas(false);
                    const point1:Vector.<Number> = lassoTransformData[0].concat();
                    const point2:Array = lassoTransformData[1].concat();
                    var command:Array = null;
                    if (lassoLayerCommandData && lassoLayerCommandData.length > 0)
                    {
                        command = lassoLayerCommandData.concat();
                    }
                    var checklayer1:Boolean = DrawCanvas.canvasLayer1Bitmap.visible;
                    var checklayer2:Boolean = DrawCanvas.canvasLayer2Bitmap.visible;
                    if (CanvasLayers.checkedLayer === 1)
                    {
                        checklayer1 = true;
                        checklayer2 = false;
                    }
                    else if (CanvasLayers.checkedLayer === 2)
                    {
                        checklayer1 = false;
                        checklayer2 = true;
                    }
                    ReplayState.rMemoryDataBuffer.push(ReplayState.stampTimingSheetToolCommand(["lasso2", point1, point2
                                , lassoInfo
                                , isLassoImageCopied
                                , checklayer1
                                , checklayer2
                                , command], lassoStartStamp));
                    UndoHistory.addNew();
                }
                else
                {
                    restoreToLastBmpd();
                }
                disposeAllLayerBitmapData();
            }
            resetLassoBox();
        }

        public static function disposeAllLayerBitmapData():void
        {
            if (LassoLayers.lassoLayer1Bitmap.bitmapData)
            {
                LassoLayers.lassoLayer1Bitmap.bitmapData.dispose();
            }
            if (LassoLayers.lassoLayer2Bitmap.bitmapData)
            {
                LassoLayers.lassoLayer2Bitmap.bitmapData.dispose();
            }
        }

        public static function restoreToLastBmpd():void
        {
            if (lassoLayer1LastBitmapdata === null && lassoLayer2LastBitmapdata === null)
            {
                return;
            }

            if (lassoLayer1LastBitmapdata)
            {
                DrawCanvas.copyPixels(DrawCanvas.canvasLayer1BitmapData, lassoLayer1LastBitmapdata);
            }
            if (lassoLayer2LastBitmapdata)
            {
                DrawCanvas.copyPixels(DrawCanvas.canvasLayer2BitmapData, lassoLayer2LastBitmapdata);
            }
            CanvasNavigator.box.updateImage();
            if (ImageViewWindow.isCanvasWindowON)
            {
                ImageViewWindow.updateCanvasWindowImage();
            }
        }

        public static function cancelIfActive():void
        {
            if (!_isStarted)
            {
                return;
            }

            cancelLassoTool();
        }

        public static function cancelLassoTool():void
        {
            disposeAllLayerBitmapData();
            restoreToLastBmpd();
            resetLassoBox();
        }

        // 라소박스 변형이랑 플래그 초기화
        public static function resetLassoBox():void
        {
            removeInputEventsLassoTool();
            _isStarted = false;
            isLassoMirrorON = false;
            isLassoImageCopied = false;
            _isLassoMenuHiddenTemp = false;
            lassoLayerCommandData = null;
            isLassoLayerSwapButtonClicked = false;
            lassoFirstData = [];
            lassoTransformData = [];
            LassoLayers.lassoLayer1Bitmap.filters = [];
            LassoLayers.lassoLayer2Bitmap.filters = [];
            _lassoMenuBox.visible = false;
            LassoLayers.lassoDraw.x = 0;
            LassoLayers.lassoDraw.y = 0;
            LassoLayers.lassoLayer1.visible = false;
            LassoLayers.lassoLayer1.x = 0;
            LassoLayers.lassoLayer1.y = 0;
            LassoLayers.lassoLayer1.scaleX = 1.0;
            LassoLayers.lassoLayer1.scaleY = 1.0;
            LassoLayers.lassoLayer1.rotation = 0;
            LassoLayers.lassoLayer2.visible = false;
            LassoLayers.lassoLayer2.x = 0;
            LassoLayers.lassoLayer2.y = 0;
            LassoLayers.lassoLayer2.scaleX = 1.0;
            LassoLayers.lassoLayer2.scaleY = 1.0;
            LassoLayers.lassoLayer2.rotation = 0;
            _lassoMenuBox.lassoCopy.alpha = 1.0;
            _lassoMenuBox.lassoLayerMerge.alpha = 1.0;
            LassoLayers.lassoDraw.visible = true;
            LassoLayers.lassoDrawCloseLine.visible = true;
            resetLassoSelectionData();
            if (lassoLayer1LastBitmapdata)
            {
                lassoLayer1LastBitmapdata.dispose();
                lassoLayer1LastBitmapdata = null;
            }
            if (lassoLayer2LastBitmapdata)
            {
                lassoLayer2LastBitmapdata.dispose();
                lassoLayer2LastBitmapdata = null;
            }
            if (ReferenceLayerController.isRefLayerMenuON === true)
                ReferenceLayerController.refLayerMenuBox.visible = true;
            if (CanvasLayers.checkedLayer !== 0)
            {
                ToolPanel.toolBox.setToolButtonsForCheckedLayerON();
            }
            ToolPanel.toolBox.setIconAlphaOnLassoToolON(1.0);
            ToolPanel.toolOptionsBox.layerButtonWrapper.alpha = 1.0;
            ToolPanel.toolOptionsBox.airBrushButtonWrapper.alpha = 1.0;
            ToolPanel.toolOptionsBox.sharpLineButtonWrapper.alpha = 1.0;
            ToolPanel.toolOptionsBox.opaSizeButtonWrapper.alpha = 1.0;
            ToolController.selectLastUsedTool();
            setAlphaButtonsOnLassoTool(1.0);
        }

        private static function move1PXUp():void
        {
            _move1PX(LASSO_1PX_MOVE_UP);
        }

        private static function move1PXDown():void
        {
            _move1PX(LASSO_1PX_MOVE_DOWN);
        }

        private static function move1PXRight():void
        {
            _move1PX(LASSO_1PX_MOVE_RIGHT);
        }

        private static function move1PXLeft():void
        {
            _move1PX(LASSO_1PX_MOVE_LEFT);
        }

        private static function _move1PX(command:int):void
        {
            var posX:Number = 0;
            var posY:Number = 0;
            if (command === LASSO_1PX_MOVE_UP)
                posY = -1;
            else if (command === LASSO_1PX_MOVE_DOWN)
                posY = 1;
            else if (command === LASSO_1PX_MOVE_LEFT)
                posX = -1;
            else if (command === LASSO_1PX_MOVE_RIGHT)
                posX = 1;

            const rotatedPoint:Point = Utils.rotatePoint(posX, posY, CanvasView.canvasAnchorPoint.rotation);
            LassoLayers.lassoLayer1.x += rotatedPoint.x;
            LassoLayers.lassoLayer1.y += rotatedPoint.y;
            LassoLayers.lassoLayer2.x = LassoLayers.lassoLayer1.x;
            LassoLayers.lassoLayer2.y = LassoLayers.lassoLayer1.y;
        }

        // ---- 입력 처리 ----

        // 올가미 메뉴 버튼은 누른 버튼에서 마우스를 뗐을때 실행됨 (InputManager.handleMouseClickStage가 호출)
        private static function onClickLassoMenu(targetName:String):void
        {
            switch (targetName)
            {
                case "lassoRefLayer":
                    {
                        mergeLassoImageIntoToRefLayer();
                    }
                    break;
                case "lassoOK":
                    {
                        applyLassoImageToCanvas();
                    }
                    break;
                case "lassoCancel":
                    {
                        cancelIfActive();
                    }
                    break;
                case "lassoLayerMerge":
                    {
                        if (_lassoMenuBox.lassoLayerMerge.alpha === 1.0)
                        {
                            mergeLayerByLassoTool();
                        }
                    }
                    break;
                case "lassoLayerSwap":
                    {
                        if (_lassoMenuBox.lassoLayerSwap.alpha === 1.0)
                        {
                            swapLayerByLassoTool();
                        }
                    }
                    break;
                case "lasso1pxUp":
                    {
                        _move1PX(LASSO_1PX_MOVE_UP);
                    }
                    break;
                case "lasso1pxDown":
                    {
                        _move1PX(LASSO_1PX_MOVE_DOWN);
                    }
                    break;
                case "lasso1pxLeft":
                    {
                        _move1PX(LASSO_1PX_MOVE_LEFT);
                    }
                    break;
                case "lasso1pxRight":
                    {
                        _move1PX(LASSO_1PX_MOVE_RIGHT);
                    }
                    break;
                case "lassoCopy":
                    {
                        copyCanvasImageToLassoTool();
                    }
                    break;
                case "lassoMirror":
                    {
                        isLassoMirrorON = !isLassoMirrorON;
                        LassoLayers.lassoLayer1.scaleX = -LassoLayers.lassoLayer1.scaleX;
                        LassoLayers.lassoLayer2.scaleX = LassoLayers.lassoLayer1.scaleX;
                        // 캔버스가 회전한각도도 있어서 항상 세로축을 중심으로 대칭되게 regpoint각도를 보정값으로 넣어줌
                        LassoLayers.lassoLayer1.rotation = -LassoLayers.lassoLayer1.rotation - (CanvasView.canvasAnchorPoint.rotation * 2);
                        LassoLayers.lassoLayer2.rotation = LassoLayers.lassoLayer1.rotation;
                    }
                    break;
            }
        }

        private static function onMouseUpLassoTool(e:MouseEvent):void
        {
            if (KeyState.getPressedKeyCount() === 1 && KeyState.getFirstPressedKey() === KeyState.KEY.space)
            {
                KeyState.updateLastKey();
                _isLassoMenuHiddenTemp = true;
                ToolState.setSelectedTool(ToolState.TOOL_HAND);
                ToolPanel.showNowToolIconToCursorTemp(ToolState.TOOL_HAND);
            }
        }

        private static function onMouseDownLassoTool(e:MouseEvent):void
        {
            if (MouseState.isRightDown)
            {
                return;
            }
            const target:DisplayObject = e.target as DisplayObject;
            if (!target)
            {
                return;
            }
            const targetName:String = target.name;
            if (UIController.isCursorInDrawArea() && _lassoMenuBox.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false)
            {
                if (_isLassoMenuHiddenTemp)
                {
                    lassoMenuBox.visible = false;
                    if (ToolState.isSelectedTool(ToolState.TOOL_HAND))
                        HandTool.startInDrawMode();
                    else if (ToolState.isSelectedTool(ToolState.TOOL_ZOOM))
                        ZoomTool.start();
                    else if (ToolState.isSelectedTool(ToolState.TOOL_ROTATE))
                        RotateTool.startInDrawMode();
                }
                else
                {
                    startLassoImageMove();
                }
            }
            else
            {
                switch (targetName)
                {
                    case "lassoMove":
                        {
                            startLassoImageMove();
                        }
                        break;
                    case "lassoResize":
                        {
                            startLassoImageResize();
                        }
                        break;
                    case "lassoRotate":
                        {
                            startLassoImageRotation();
                        }
                        break;
                    case "navStageBG":
                    case "navBitmapBG":
                    case "navLayer1Bitmap":
                    case "navLayer2Bitmap":
                        {
                            CanvasNavigator.startCanvasMove(false);
                        }
                        break;
                    case "navCursor":
                        {
                            CanvasNavigator.startCanvasMove(true);
                        }
                        break;
                    case "lassoMenuMoveButton":
                        {
                            Utils.setAsTopChild(lassoMenuBox);
                            DragInteraction.startDragBox(lassoMenuBox);
                        }
                        break;
                    case "sideBarScrollBar":
                        {
                            SidebarController.startScrollSidebarByDrag();
                        }
                        break;
                    case "toolZoomIn":
                        {
                            CanvasView.viewport.zoomStep(true);
                        }
                        break;
                    case "toolZoomOut":
                        {
                            CanvasView.viewport.zoomStep(false);
                        }
                        break;
                    case "toolRotate":
                        {
                            lassoMenuBox.visible = false;
                            _isLassoMenuHiddenTemp = true;
                            RotateTool.startInDrawMode();
                        }
                        break;
                    case "lasso1pxUp":
                    case "lasso1pxDown":
                    case "lasso1pxLeft":
                    case "lasso1pxRight":
                    case "lassoCopy":
                    case "lassoOK":
                    case "lassoCancel":
                    case "lassoRefLayer":
                    case "lassoLayerMerge":
                    case "lassoLayerSwap":
                    case "lassoMirror":
                        InputManager.handleMouseClickStage(targetName, onClickLassoMenu);
                        break;
                    case "sideBarPositionButton":
                    case "sideBarPositionButton2":
                    case "sideBarOFFButton":
                    case "sideBarOFFButton2":
                    case "sideBarONButton":
                    case "sideBarONButton2":
                        InputManager.handleMouseClickStage(targetName, DrawModeInput.onClickDrawModeButton);
                        break;
                    default:
                        break;
                }
            }
        }

        private static function onKeyUpLassoTool(e:KeyboardEvent):void
        {
            const keyCode:uint = e.keyCode;
            if (_isLassoMenuHiddenTemp && !MouseState.isLeftDown)
            {
                _isLassoMenuHiddenTemp = false;
            }
            KeyState.checkGeneralKeyUp();

            // 마지막으로 처리한 키를 뗐는데 아직 누르고 있는 키가 있으면 남은 키로 다시 처리함
            if (KeyState.isKeyPressed() && !CaptureController.isCaptureModeON && !ReplayState.isReplayModeON && KeyState.isLastKey(keyCode))
            {
                onKeyDownLassoTool(null);
            }
        }

        private static function onKeyDownLassoTool(e:KeyboardEvent):void
        {
            if (MouseState.isLeftDown || MouseState.isRightDown || MouseState.isDragging)
            {
                return;
            }

            const keyCode:uint = KeyState.getFirstPressedKey();

            if (keyCode === KeyState.KEY.space)
            {
                if (KeyState.checkSubKey(2, true, handleSpaceSubKeyLassoTool))
                {
                    return;
                }

                if (KeyState.isLastKey(keyCode))
                {
                    return;
                }

                KeyState.updateLastKey();
                _isLassoMenuHiddenTemp = true;
                ToolState.setSelectedTool(ToolState.TOOL_HAND);
                ToolPanel.showNowToolIconToCursorTemp(ToolState.TOOL_HAND);
            }
            else if (KeyState.isPressingShift())
            {
                if (KeyState.checkSubKey(2, true, handleShiftSubKeyLassoTool))
                {
                    return;
                }
            }

            if (KeyState.isLastKey(keyCode))
            {
                return;
            }

            KeyState.updateLastKey();

            switch (keyCode)
            {
                case KeyState.KEY.tab:
                case KeyState.KEY.backslash:
                    if (SidebarController.isSidebarVisible)
                    {
                        SidebarController.hideSidebarPermanent();
                    }
                    else
                    {
                        SidebarController.showSidebarPermanent();
                    }
                    break;

                case KeyState.KEY.w:
                case KeyState.KEY.i:
                    _isLassoMenuHiddenTemp = true;
                    KeyState.updateLastKey();
                    ToolState.setSelectedTool(ToolState.TOOL_ZOOM);
                    ToolPanel.showNowToolIconToCursorTemp(ToolState.TOOL_ZOOM);
                    break;

                case KeyState.KEY.s:
                case KeyState.KEY.k:
                    _isLassoMenuHiddenTemp = true;
                    KeyState.updateLastKey();
                    ToolState.setSelectedTool(ToolState.TOOL_ROTATE);
                    ToolPanel.showNowToolIconToCursorTemp(ToolState.TOOL_ROTATE);
                    break;

                case KeyState.KEY.enter:
                    applyLassoImageToCanvas();
                    break;

                case KeyState.KEY.esc:
                case KeyState.KEY.backspace:
                    cancelIfActive();
                    break;
            }
        }

        private static function onRightMouseDownLassoTool(e:MouseEvent):void
        {
            if (!isStarted)
            {
                return;
            }
            const target:DisplayObject = e.target as DisplayObject;
            if (!target)
                return;
            const targetName:String = target.name;
            if (targetName === "toolZoom"
                    || targetName === "toolZoomIn"
                    || targetName === "toolZoomOut")
            {
                if (CanvasView.canvasZoomMultiplier !== 1.0)
                {
                    UIController.resetZoomDrawMode();
                    CanvasNavigator.updateCursor();
                }
            }
            else if (targetName === "toolRotate")
            {
                if (CanvasView.canvasAnchorPoint.rotation !== 0.0)
                {
                    UIController.resetRotationDrawMode();
                    CanvasNavigator.updateCursor();
                }
            }
        }

        private static function onRightMouseUpLassoTool(e:MouseEvent):void
        {
            if (!isStarted || MouseState.isLeftDown)
            {
                return;
            }
            const target:DisplayObject = e.target as DisplayObject;
            if (!target)
                return;
            const targetName:String = target.name;
            if (targetName === "toolZoom"
                    || targetName === "toolZoomIn"
                    || targetName === "toolZoomOut"
                    || targetName === "toolRotate")
            {
                return;
            }
            if (lassoMenuBox.hitTestPoint(main.stage.mouseX, main.stage.mouseY) === false || targetName === "lassoOK")
            {
                applyLassoImageToCanvas();
                return;
            }
            if (targetName === "lassoRotate")
            {
                resetLassoLayerRotation();
            }
            else if (targetName === "lassoResize")
            {
                resetLassoLayerScale();
            }
        }

        private static function removeInputEventsLassoTool():void
        {
            main.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUpLassoTool);
            main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownLassoTool);
            main.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownLassoTool);
            main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpLassoTool);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownLassoTool);
            main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpLassoTool);
            DrawModeInput.addEvents();
        }

        private static function addInputEventsLassoTool():void
        {
            main.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUpLassoTool, false, InputPriority.DEFAULT);
            main.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownLassoTool, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownLassoTool, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpLassoTool, false, InputPriority.MODE);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDownLassoTool, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUpLassoTool, false, InputPriority.DEFAULT);
            main.stage.addEventListener(MouseEvent.MOUSE_OVER, lassoMenuHintONEvent);
            DrawModeInput.removeEvents();
        }

        private static function handleShiftSubKeyLassoTool(input:int):void
        {
            switch (input)
            {
                case KeyState.KEY.s:
                case KeyState.KEY.k:
                    if (CanvasView.canvasAnchorPoint.rotation !== 0.0)
                    {
                        UIController.resetRotationDrawMode();
                        CanvasNavigator.updateCursor();
                    }
                    return;

                case KeyState.KEY.w:
                case KeyState.KEY.i:
                    if (CanvasView.canvasZoomMultiplier !== 1.0)
                    {
                        UIController.resetZoomDrawMode();
                        CanvasNavigator.updateCursor();
                    }
                    return;
            }
        }
        private static function handleSpaceSubKeyLassoTool(input:int):void
        {
            // 키 2개 조합만 체크함
            if (!KeyState.isTwoKeyPressed())
            {
                return;
            }

            switch (input)
            {
                case KeyState.KEY.w:
                case KeyState.KEY.i:
                    move1PXUp();
                    break;

                case KeyState.KEY.a:
                case KeyState.KEY.j:
                    move1PXLeft();
                    break;

                case KeyState.KEY.s:
                case KeyState.KEY.k:
                    move1PXDown();
                    break;

                case KeyState.KEY.d:
                case KeyState.KEY.l:
                    move1PXRight();
                    break;
            }
        }

        // 마우스 드래그로 이미지 배율을 정하는 함수를 만들어 돌려줌 (0.1~4.0배로 제한)
        public static function updateImageScaleMouseDrag(sc:Number):Function
        {
            const stage:Stage = main.stage;
            var clickX:Number = stage.mouseX;
            var clickY:Number = stage.mouseY;
            var scale:Number = Math.abs(sc);
            var mxLastPos:Number;
            var myLastPos:Number;
            var moveFlag:int;

            return function (mx:Number, my:Number):Number
            {
                if (moveFlag != 0)
                {
                    if (moveFlag === 1)
                    {
                        const subX:Number = mx - mxLastPos;

                        if (subX !== 0) // 차이가 0이 될때가 있어서 이건 스킵
                        {
                            scale *= Math.pow(2, subX * 0.008);
                            ReferenceLayerController.refLayerMenuDragXMoveSum += subX;
                        }
                    }
                    else if (moveFlag === 2)
                    {
                        const subY:Number = myLastPos - my;

                        if (subY !== 0)
                        {
                            scale *= Math.pow(2, subY * 0.008);
                            ReferenceLayerController.refLayerMenuDragXMoveSum += subY;
                        }
                    }
                }
                else if (moveFlag === 0)
                {
                    if (Math.abs(mx - clickX) > 5)
                    {
                        moveFlag = 1;
                    }
                    else if (Math.abs(my - clickY) > 5)
                    {
                        moveFlag = 2;
                    }
                }

                mxLastPos = mx;
                myLastPos = my;

                if (scale > 4.0)
                {
                    scale = 4.0;
                }
                else if (scale < 0.1)
                {
                    scale = 0.1;
                }

                return scale;
            };
        }

        // 마우스 드래그로 이미지 위치를 정하는 함수를 만들어 돌려줌
        public static function updateImagePosMouseDrag(target:DisplayObject, targetAngle:Number, customScaleX:Number = 1.0, customScaleY:Number = 1.0):Function
        {
            var oldX:Number = target.x;
            var oldY:Number = target.y;
            var mx:Number = main.stage.mouseX;
            var my:Number = main.stage.mouseY;
            const zoom:Number = CanvasView.canvasZoomMultiplier;
            const angle:Number = targetAngle;

            return function ():Point
            {
                const dx:Number = main.stage.mouseX - mx;
                const dy:Number = main.stage.mouseY - my;
                const newPos:Point = Utils.rotatePoint(dx, dy, angle);

                newPos.setTo(Math.round(oldX + newPos.x / zoom / customScaleX), Math.round(oldY + newPos.y / zoom / customScaleY));

                return newPos;
            };
        }

    }
}
