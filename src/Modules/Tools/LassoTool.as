package Modules.Tools
{
    import Modules.InputPriority;
    import Modules.CanvasController;
    import Modules.ColorPickerController;
    import Modules.DragInteraction;
    import Modules.ImageViewWindow;
    import Modules.InputManager;
    import Modules.MainUI;
    import Modules.MainUIController;
    import Modules.ReferenceLayerController;
    import Modules.SidebarController;
    import Modules.ToolController;
    import Modules.UndoManager;
    import Modules.Utils;

    import Symbols.LassoMenuSet;

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.filters.ConvolutionFilter;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import Symbols.RotateCursorSet;
    import Modules.UndoController;
    import Modules.ReplayEngine.ReplayController;
    import Modules.ReplayEngine.ReplayDrawer;
    import Modules.ReplayEngine.ReplayState;

    public class LassoTool
    {
        // todo : 나중에 이 컨트롤러도 분해해서 lasso, pen fillpen등 투명도 크기 색깔 조정하는 클래스로 분리
        // todo: 포멧팅 필요, 라소툴 관련 메서드는 tool controller에 분할되어 이식되어야함
        // ane나 내부 구현으로 리사이즈시 뿌옇게되는거 란초스보간이나 average color 방식으로 바꾸어야함, 리플레이에도 적은것같은데 라소녹화 이미지는 비트맵 캐시되어야함 성능문제

        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static const LASSO_SHARP_DATA:Array = [[[
                        0, -1, 0,
                        -1, 12, -1
                        , 0, -1, 0
                    ], 8],
                [[
                        0, -1, 0,
                        -1, 10, -1
                        , 0, -1, 0
                    ], 6],
                [[
                        0, -1, 0,
                        -1, 7, -1
                        , 0, -1, 0
                    ], 3]];

        public static const LASSO_1PX_MOVE_UP:int = (1 << 0);
        public static const LASSO_1PX_MOVE_DOWN:int = (1 << 1);
        public static const LASSO_1PX_MOVE_LEFT:int = (1 << 2);
        public static const LASSO_1PX_MOVE_RIGHT:int = (1 << 3);

        public static var _lassoMenuBox:LassoMenuSet = new LassoMenuSet(); // 라소툴 버튼
        public static const lassoDraw:Shape = new Shape(); // 라소 영역 선 그려주는 쉐이프
        public static const lassoDrawCloseLine:Shape = new Shape(); // 라소 영역 증분그리기로 되어서 선 닫아주는 그래픽은 따로 추가해줌
        public static var lassoLayer1:Sprite = new Sprite(); // 선택한 이미지를 그려주고 확대/축소 등 조작
        public static var lassoLayer1Bitmap:Bitmap = new Bitmap();

        public static var lassoLayer2:Sprite = new Sprite(); // lassoLayer2 레이어
        public static var lassoLayer2Bitmap:Bitmap = new Bitmap(); // lassoLayer2의 비트맵

        private static var _isStarted:Boolean = false; // 라소툴로 영역 선택하면 올려줌
        private static var _isLassoMenuHiddenTemp:Boolean = false; // 툴 고정 상태에서 줌툴 클릭 시 메뉴를 잠시 숨기는 플래그
        public static var lassoFirstData:Array = []; // 이 값과 비교해서 달라진 게 있으면 OK할 때 적용
        public static var isLassoMirrorON:Boolean = false; // 라소 mirror 클릭할 때마다 반전

        public static var lassoTransformData:Array = []; // 라소 변형 데이터
        public static var isLassoImageCopied:Boolean = false; // lasso 복사 누르면 올려줌

        public static var lassoLayer1LastBitmapdata:BitmapData; // copy나 취소했을 때 원래대로 돌려주는 이미지
        public static var lassoLayer2LastBitmapdata:BitmapData; // copy나 취소했을 때 원래대로 돌려주는 이미지
        public static var lassoLayerCommandData:Array = null; // 스왑/머지 순서 저장

        public static var isLassoLayerSwapButtonClicked:Boolean; // 스왑 버튼 클릭할 때마다 true/false 변경

        public static var lassoAndRefLayerBoxLastPos:Array = [0, 0, 0, 0, 0, 0, 0, 0]; // 사이즈바 켜줄때 임시로 사이드바 안쪽으로 밀려나게 하고 위치가 변경되지 않았으면 원래대로 복귀해줌

        private static function setOptimizeView(flag:Boolean):void
        {
            lassoDraw.visible = !flag;
            lassoDrawCloseLine.visible = !flag;
            lassoLayer1Bitmap.smoothing = !flag;
            lassoLayer2Bitmap.smoothing = !flag;
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
            DottedLineTool.setLineScale(CanvasController.canvasZoomMultipler * Math.abs(lassoLayer1.scaleY));

            lassoDraw.graphics.clear(); // lassoDraw.x/y 보정값은 그대로 두므로 위치는 유지됨
            DottedLineTool.moveTo(lassoDraw.graphics, pts[0][0], pts[0][1]);
            for (var i:uint = 1;i < len;i++)
            {
                DottedLineTool.lineTo(pts[i][0], pts[i][1]);
            }
            DottedLineTool.lineTo(pts[0][0], pts[0][1], true);
        }

        public static function resetLassoLayerScale():void
        {
            if (lassoLayer1.scaleY !== 1.0)
            {
                lassoLayer1.scaleX = (isLassoMirrorON) ? -1.0 : 1.0;
                lassoLayer1.scaleY = 1.0;
                lassoLayer2.scaleX = lassoLayer1.scaleX;
                lassoLayer2.scaleY = lassoLayer1.scaleY;
                LassoTool.redrawLassoOutline();
            }
        }
        public static function resetLassoLayerRotation():void
        {
            if (lassoLayer1.rotation !== 0)
            {
                lassoLayer1.rotation = 0;
                lassoLayer2.rotation = 0;
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
            InputManager.resetLastKey();
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
                if (UndoManager.isDeepUndoEnabled)
                {
                    UndoManager.applyDeepUndo();
                }
                const lassoInfo:Array = applyLassoBoxImageToCanvas(true);
                const point1:Vector.<Number> = lassoTransformData[0].concat();
                const point2:Array = lassoTransformData[1].concat();
                var l1:Boolean = true;
                var l2:Boolean = true;
                if (CanvasController.checkedLayer === 1 || (CanvasController.canvasLayer1Bitmap.visible && !CanvasController.canvasLayer2Bitmap.visible))
                {
                    l1 = true;
                    l2 = false;
                }
                else if (CanvasController.checkedLayer === 2 || (!CanvasController.canvasLayer1Bitmap.visible && CanvasController.canvasLayer2Bitmap.visible))
                {
                    l1 = false;
                    l2 = true;
                }
                ReplayState.rMemoryDataBuffer.push(["lassodel2", point1, point2, lassoInfo, isLassoImageCopied, l1, l2]);
                UndoController.addNew();
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
                MainUIController.keepBoxInsideViewPort(_lassoMenuBox);
                arr[2] = _lassoMenuBox.x;
                arr[3] = _lassoMenuBox.y;
            }
            if (ReferenceLayerController.isRefLayerMenuON)
            {
                arr[4] = ReferenceLayerController.refLayerMenuBox.x;
                arr[5] = ReferenceLayerController.refLayerMenuBox.y;
                MainUIController.keepBoxInsideViewPort(ReferenceLayerController.refLayerMenuBox);
                arr[6] = ReferenceLayerController.refLayerMenuBox.x;
                arr[7] = ReferenceLayerController.refLayerMenuBox.y;
            }
        }

        public static function mergeLassoImageIntoToRefLayer():void
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

        public static function lassoMenuHintONEvent(e:MouseEvent):void
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
            if (CanvasController.isMouseDragging === true)
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

        public static function swapLassoImage():void
        {
            var tmpbmpd:BitmapData = lassoLayer1Bitmap.bitmapData;
            lassoLayer1Bitmap.bitmapData = lassoLayer2Bitmap.bitmapData;
            lassoLayer2Bitmap.bitmapData = tmpbmpd;
            tmpbmpd = null;
        }

        public static function mergeLassoImage():void
        {
            var rect:Rectangle = new Rectangle(0, 0, lassoLayer1Bitmap.bitmapData.width, lassoLayer1Bitmap.bitmapData.height);
            lassoLayer2Bitmap.bitmapData.draw(lassoLayer1Bitmap);
            lassoLayer1Bitmap.bitmapData.fillRect(rect, 0);
            rect = null;
        }

        public static function mergeLayerByLassoTool():void
        {
            _lassoMenuBox.lassoLayerMerge.alpha = Global.OFFALPHA;
            mergeLassoImage();
            addLassoLayerMergeCommand(1);
        }
        public static function swapLayerByLassoTool():void
        {
            if (_lassoMenuBox.lassoLayerSwap.alpha < 1.0)
            {
                return;
            }
            isLassoLayerSwapButtonClicked = !isLassoLayerSwapButtonClicked;
            swapLassoImage();
            addLassoLayerMergeCommand(0);
            _lassoMenuBox.hint(HintStrings.getLassoMenuHintSwapLayer());
            CanvasController.playLayerSwapEffect(_lassoMenuBox.lassoLayerSwap);
        }

        public static function copyCanvasImageToLassoTool():void
        {
            if (isLassoImageCopied)
            {
                return;
            }
            isLassoImageCopied = true;
            _lassoMenuBox.lassoCopy.alpha = Global.OFFALPHA;
            restoreToLastBmpd();
        }

        public static function startLassoImageRotation():void
        {
            var getAngle:Function = MainUI.showCanvasRotateCursorMouseDrag(lassoLayer1);
            function onDragStart():void
            {
                setOptimizeView(true);
            }
            function onMouseUp():void
            {
                getAngle = null;
                MainUI.hideCanvasRotateCursor();
                setOptimizeView(false);
            }
            function onMouseMove():void
            {
                const angle:Number = getAngle(false);
                lassoLayer1.rotation = angle;
                lassoLayer2.rotation = angle;
            }
            DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
        }

        public static function startLassoImageResize():void
        {
            const mirrorScale:Number = (lassoLayer1.scaleX < 0) ? -1.0 : 1.0;
            var getScale:Function = Utils.updateImageScaleMouseDrag(lassoLayer1.scaleX);

            function onDragStart():void
            {
                setOptimizeView(true);
                MainUI.showMouseHint(MainUI.getImageScaleHint(lassoLayer1.width, lassoLayer1.height, Math.abs(lassoLayer1.scaleX), false));
            }
            function onMouseUp():void
            {
                getScale = null;
                MainUIController.keepBoxInsideViewPort(_lassoMenuBox);
                MainUI.hideMouseHint();
                LassoTool.redrawLassoOutline();
                setOptimizeView(false);
            }
            function onMouseMove():void
            {
                const scale:Number = getScale(main.stage.mouseX, main.stage.mouseY);
                lassoLayer1.scaleX = scale * mirrorScale;
                lassoLayer1.scaleY = scale;
                lassoLayer2.scaleX = lassoLayer1.scaleX;
                lassoLayer2.scaleY = lassoLayer1.scaleY;
                MainUI.showMouseHint(MainUI.getImageScaleHint(lassoLayer1.width, lassoLayer1.height, Math.abs(lassoLayer1.scaleX), false));
            }
            DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
        }

        public static function hasLassoImageChanges():Boolean
        {
            if (isLassoImageCopied
                    || lassoFirstData[0] !== lassoLayer1.x
                    || lassoFirstData[1] !== lassoLayer1.y
                    || lassoFirstData[2] !== lassoLayer1.scaleX
                    || lassoFirstData[3] !== lassoLayer1.scaleY
                    || lassoFirstData[4] !== lassoLayer1.rotation
                    || (lassoLayerCommandData && lassoLayerCommandData.length > 0))
            {
                return true;
            }
            return false;
        }

        public static function startLassoImageMove():void
        {
            var getMovedPos:Function = Utils.updateImagePosMouseDrag(lassoLayer1, CanvasController.canvasAnchorPoint.rotation);
            function onMouseUp():void
            {
                getMovedPos = null;
                MainUIController.keepBoxInsideViewPort(_lassoMenuBox);
                setOptimizeView(false);
            }
            function onMouseMove():void
            {
                const pos:Point = getMovedPos();
                lassoLayer1.x = Math.round(pos.x);
                lassoLayer1.y = Math.round(pos.y);
                lassoLayer2.x = lassoLayer1.x;
                lassoLayer2.y = lassoLayer1.y;
            }
            function onDragStart():void
            {
                setOptimizeView(true);
            }
            DragInteraction.startDragInteraction(onDragStart, onMouseMove, onMouseUp);
        }

        public static function applyLassoShapen(scale:Number):void
        {
            if (scale === 0.0)
                return;
            var index:uint = Math.abs(Math.floor(scale - 1.0));
            if (index > 2)
                index = 2;
            var sharpen:ConvolutionFilter = new ConvolutionFilter(3, 3, LASSO_SHARP_DATA[index][0], LASSO_SHARP_DATA[index][1]);
            lassoLayer1Bitmap.filters = [sharpen];
            lassoLayer2Bitmap.filters = [sharpen];
        }

        public static function isHintAvailableWithLassoToolStarted(target:DisplayObject):Boolean
        {
            if (target === ToolController.toolBox.toolZoomIn
                    || target === ToolController.toolBox.toolZoomOut
                    || target === ToolController.toolBox.toolRotate
                    || target === SidebarController.sideBarScrollBar)
            {
                return true;
            }
            return false;
        }

        public static function moveSelectedAreaToLassoBox(replayMode:Boolean, rectArr:Vector.<Number>, points:Array, copyFlag:Boolean, layer1:Boolean, layer2:Boolean):Boolean
        {
            // 라소 경계 사각형 좌표와 크기
            const rectLeft:Number = rectArr[0];
            const rectTop:Number = rectArr[1];
            const rectWidth:Number = rectArr[2] - rectLeft;
            const rectHeight:Number = rectArr[3] - rectTop;
            const lassoPointsLen:uint = points.length;
            // 가로세로 길이가 0 이하이면 실행하지 않음
            if (Math.floor(rectWidth) <= 0 || Math.floor(rectHeight) <= 0)
                return false;
            var xCanvasDrawLayer:Shape;
            var canvasBitmapData:BitmapData;
            var canvasBitmapDataSub:BitmapData;
            var canvasBitmap:Bitmap;
            var canvasBitmapSub:Bitmap;
            var canvasDrawLayerFilterBackUp:Array = null;
            // 에어브러시 켜줄때 필터 백업함
            if (replayMode)
            {
                canvasDrawLayerFilterBackUp = ReplayDrawer.rCanvasDrawShape.filters.concat();
                ReplayDrawer.rCanvasDrawShape.filters = [];
                xCanvasDrawLayer = ReplayDrawer.rCanvasDrawShape;
                if (layer1)
                {
                    canvasBitmapData = ReplayDrawer.rCanvasLayer1BitmapData;
                    canvasBitmap = ReplayDrawer.rCanvasLayer1Bitmap;
                }
                if (layer2)
                {
                    canvasBitmapDataSub = ReplayDrawer.rCanvasLayer2BitmapData;
                    canvasBitmapSub = ReplayDrawer.rCanvasLayer2Bitmap;
                }
            }
            else
            {
                canvasDrawLayerFilterBackUp = CanvasController.canvasDrawLayerChild.filters.concat();
                CanvasController.canvasDrawLayerChild.filters = [];
                xCanvasDrawLayer = CanvasController.canvasDrawLayerChild;
                if (layer1)
                {
                    canvasBitmapData = CanvasController.canvasLayer1BitmapData;
                    canvasBitmap = CanvasController.canvasLayer1Bitmap;
                }
                if (layer2)
                {
                    canvasBitmapDataSub = CanvasController.canvasLayer2BitmapData;
                    canvasBitmapSub = CanvasController.canvasLayer2Bitmap;
                }
            }
            const newRectangle:Rectangle = new Rectangle(rectLeft, rectTop, rectWidth, rectHeight);
            var lassoBmpd1:BitmapData = (layer1) ? new BitmapData(rectWidth, rectHeight, true, 0) : null;
            var lassoBmpd2:BitmapData = (layer2) ? new BitmapData(rectWidth, rectHeight, true, 0) : null;
            var i:uint;
            // 지우기 전에 사각형 모양으로 그려준 부분을 copypixel 함.
            if (layer1)
                lassoBmpd1.copyPixels(canvasBitmapData, newRectangle, new Point(0, 0), null, null, true);
            if (layer2)
                lassoBmpd2.copyPixels(canvasBitmapDataSub, newRectangle, new Point(0, 0), null, null, true);
            lassoLayer1Bitmap.smoothing = true;
            lassoLayer2Bitmap.smoothing = true;
            // bitmap1canvas에서 그려준 영역을 지워줌
            if (!copyFlag)
            {
                xCanvasDrawLayer.graphics.clear();
                xCanvasDrawLayer.graphics.beginFill(CanvasController.CANVAS_BG_COLOR);
                xCanvasDrawLayer.graphics.moveTo(points[0][0], points[0][1]);
                // rectLeft를 빼줘서 canvasdraw2의 0,0영역에 그려줌
                for (i = 1;i < lassoPointsLen;i++)
                {
                    xCanvasDrawLayer.graphics.lineTo(points[i][0], points[i][1]);
                }
                xCanvasDrawLayer.graphics.endFill();
                if (layer1)
                {
                    canvasBitmapData.draw(xCanvasDrawLayer, null, null, "erase");
                    canvasBitmap.bitmapData = canvasBitmapData;
                }
                if (layer2)
                {
                    canvasBitmapDataSub.draw(xCanvasDrawLayer, null, null, "erase");
                    canvasBitmapSub.bitmapData = canvasBitmapDataSub;
                }
            }
            // -------------------------
            // clip하기 위해서 그려운 영역의 반전 부분을 0,0영역을 기준으로 그려줌
            // 2번 반복하는게 좀 그런데 다른 방법 모르겠음
            // 가로세로 절반 크기만큼 더해줘서 bmp의 중점으로 이동해주기 때문에 또 그만큼 빼줌
            xCanvasDrawLayer.graphics.clear();
            xCanvasDrawLayer.graphics.beginFill(0x00FF00);
            xCanvasDrawLayer.graphics.drawRect(0, 0, rectWidth, rectHeight);
            xCanvasDrawLayer.graphics.moveTo(points[0][0] - rectLeft, points[0][1] - rectTop);
            // rectLeft를 빼줘서 canvasdraw2의 0,0영역에 그려줌
            for (i = 1;i < lassoPointsLen;i++)
            {
                xCanvasDrawLayer.graphics.lineTo(points[i][0] - rectLeft, points[i][1] - rectTop);
            }
            // 마지막으로 시작점을 이어줌
            xCanvasDrawLayer.graphics.endFill();
            if (layer1)
            {
                lassoLayer1Bitmap.bitmapData = lassoBmpd1;
                lassoLayer1Bitmap.bitmapData.draw(xCanvasDrawLayer, null, null, "erase");
            }
            if (layer2)
            {
                lassoLayer2Bitmap.bitmapData = lassoBmpd2;
                lassoLayer2Bitmap.bitmapData.draw(xCanvasDrawLayer, null, null, "erase");
            }
            xCanvasDrawLayer.graphics.clear(); // 꼭 해줘야함
            // 회전 확대를 bmp사각형의 중심으로 맞추어줌
            if (layer1)
            {
                lassoLayer1Bitmap.x = -rectWidth / 2;
                lassoLayer1Bitmap.y = -rectHeight / 2;
            }
            if (layer2)
            {
                lassoLayer2Bitmap.x = -rectWidth / 2;
                lassoLayer2Bitmap.y = -rectHeight / 2;
            }
            lassoLayer1.x = rectLeft + rectWidth / 2;
            lassoLayer1.y = rectTop + rectHeight / 2;
            lassoLayer2.x = lassoLayer1.x;
            lassoLayer2.y = lassoLayer1.y;
            lassoDraw.x = -lassoLayer1.x;
            lassoDraw.y = -lassoLayer1.y;
            if (replayMode)
            {
                ReplayDrawer.rCanvasDrawShape.filters = canvasDrawLayerFilterBackUp.concat();
            }
            else
            {
                CanvasController.canvasDrawLayerChild.filters = canvasDrawLayerFilterBackUp.concat();
            }
            return true;
        }

        public static function setAlphaButtonsOnLassoTool(alpha:Number):void
        {
            ColorPickerController.colorPickerBox.alpha = alpha;
            ToolController.toolBox.alpha = alpha;
            ToolController.toolOptionsBox.alpha = alpha;
            ToolController.toolBox.toolMirror.alpha = alpha;
        }

        // ---------------------------------------------------------------------
        // 라소 영역 선택 (드래그로 점을 모으고 마우스 업에서 라소 박스로 옮김)
        // ---------------------------------------------------------------------
        private static const LASSO_PREVIEW_TIMER:String = "LassoDrawDelayTimer";

        private static var lassoSelectRect:Vector.<Number>; // left, top, right, bottom순임
        private static var lassoSelectPoints:Array; // [[x, y], ...] 마우스업 후 lassoTransformData[1]로 그대로 넘겨짐
        private static var lassoPreviewDrawnCount:uint = 0; // 증분 그리기: 점선으로 이미 그린 점 개수

        public static function startLassoSelection():void
        {
            if (_isStarted === true || CanvasController.isAllLayerInvisible())
                return;

            const clickX:Number = CanvasController.canvasDrawLayerChild.mouseX;
            const clickY:Number = CanvasController.canvasDrawLayerChild.mouseY;

            lassoPreviewDrawnCount = 0;
            CanvasController.isMouseDragging = true;
            _lassoMenuBox.hint("Lasso tool");
            lassoDraw.x = 0;
            lassoDraw.y = 0;
            lassoSelectRect = new <Number>[clickX, clickY, clickX, clickY];
            lassoSelectPoints = [[clickX, clickY]];
            lassoTransformData = [];
            CanvasController.canvasDrawLayer.alpha = 1.0; // 알파값이 조정되어 있을 수도 있기 때문에 해줌
            lassoDraw.graphics.clear();
            lassoDrawCloseLine.graphics.clear();
            lassoLayer1.visible = true;
            DottedLineTool.setLineScale(CanvasController.canvasZoomMultipler);

            const needLayer1:Boolean = CanvasController.canvasLayer1Bitmap.visible && CanvasController.checkedLayer !== 2;
            const needLayer2:Boolean = CanvasController.canvasLayer2Bitmap.visible && CanvasController.checkedLayer !== 1;
            if (needLayer1)
            {
                if (lassoLayer1LastBitmapdata != null)
                    lassoLayer1LastBitmapdata.dispose();

                lassoLayer1LastBitmapdata = CanvasController.canvasLayer1BitmapData.clone();
            }
            if (needLayer2)
            {
                if (lassoLayer2LastBitmapdata != null)
                    lassoLayer2LastBitmapdata.dispose();

                lassoLayer2LastBitmapdata = CanvasController.canvasLayer2BitmapData.clone();
            }

            main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveLassoSelection);
            main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpLassoSelection, false, InputPriority.DEFAULT);
        }

        private static function resetLassoSelectionData():void
        {
            lassoPreviewDrawnCount = 0;
            lassoDrawCloseLine.graphics.clear();

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
                lassoDraw.graphics.clear();
                DottedLineTool.moveTo(lassoDraw.graphics, points[0][0], points[0][1]);
                lassoPreviewDrawnCount = 1;
            }

            for (var i:uint = lassoPreviewDrawnCount;i < len;i++)
            {
                DottedLineTool.lineTo(points[i][0], points[i][1]);
            }
            lassoPreviewDrawnCount = len;

            lassoDrawCloseLine.graphics.clear();

            if (isFinal)
            {
                // 확정: lassoDraw에 점선으로 닫음 (lassoDraw의 좌표 보정을 그대로 따라감)
                DottedLineTool.lineTo(points[0][0], points[0][1], true);
            }
            else
            {
                // 드래그 중: 점선 상태를 건드리지 않고 별도 Shape에 닫는 점선
                DottedLineTool.drawClosingLine(lassoDrawCloseLine.graphics, points[0][0], points[0][1]);
            }
        }

        private static function setDefaultLassoMenuPos(lassoMenu:LassoMenuSet):void
        {
            const g:Point = lassoLayer1.localToGlobal(new Point(0, 0));
            const lassoW:Number = (lassoMenu.width > main.stage.stageWidth)
                ? main.stage.stageWidth : lassoMenu.width;
            lassoMenu.x = Math.floor(g.x - lassoW / 2);
            lassoMenu.y = Math.floor(g.y + (((lassoLayer1.height) / 2) * CanvasController.canvasZoomMultipler + 20));
        }

        private static function onMouseMoveLassoSelection(e:MouseEvent):void
        {
            const mx:Number = CanvasController.canvasDrawLayerChild.mouseX;
            const my:Number = CanvasController.canvasDrawLayerChild.mouseY;
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
            CanvasController.isMouseDragging = false;
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
            if (rect[2] > CanvasController.CANVAS_WIDTH)
                rect[2] = CanvasController.CANVAS_WIDTH;
            if (rect[3] > CanvasController.CANVAS_HEIGHT)
                rect[3] = CanvasController.CANVAS_HEIGHT;

            lassoTransformData.push(rect);
            lassoTransformData.push(lassoSelectPoints);

            var checklayer1:Boolean = CanvasController.canvasLayer1Bitmap.visible;
            var checklayer2:Boolean = CanvasController.canvasLayer2Bitmap.visible;
            if (CanvasController.checkedLayer === 1)
            {
                checklayer1 = true;
                checklayer2 = false;
            }
            else if (CanvasController.checkedLayer === 2)
            {
                checklayer1 = false;
                checklayer2 = true;
            }

            if (moveSelectedAreaToLassoBox(false, rect, lassoSelectPoints, isLassoImageCopied, checklayer1, checklayer2) === false)
            {
                resetLassoBox();
                return;
            }

            drawLassoPreviewLine(true);
            // 라소 메뉴 마우스 커서에보이기
            lassoFirstData = [lassoLayer1.x, lassoLayer1.y, lassoLayer1.scaleX, lassoLayer1.scaleY, lassoLayer1.rotation];
            _isStarted = true;
            setDefaultLassoMenuPos(_lassoMenuBox);
            MainUIController.keepBoxInsideViewPort(_lassoMenuBox);
            if (CanvasController.checkedLayer || !checklayer1 || !checklayer2)
            {
                _lassoMenuBox.lassoLayerSwap.alpha = Global.OFFALPHA;
                _lassoMenuBox.lassoLayerMerge.alpha = Global.OFFALPHA;
            }
            else
            {
                _lassoMenuBox.lassoLayerSwap.alpha = 1.0;
                _lassoMenuBox.lassoLayerMerge.alpha = 1.0;
            }
            lassoLayer2.visible = true;
            _lassoMenuBox.visible = true;
            Utils.setAsTopChild(_lassoMenuBox);
            if (ReferenceLayerController.isRefLayerMenuON === true)
            {
                ReferenceLayerController.refLayerMenuBox.visible = false;
            }
            setAlphaButtonsOnLassoTool(Global.OFFALPHA);
            InputManager.addInputEventsLassoTool();
        }

        // zoom이나 rotate reg포인트 바뀔때마다
        // 캔버스 판넬위치 따라 다니면서 크기 똑같이 해줌
        public static function applyLassoBoxImageToCanvas(isTransferRefLayer:Boolean):Array
        {
            const lassoBMPScaleX:Number = lassoLayer1.scaleX;
            const lassoBMPScaleY:Number = lassoLayer1.scaleY;
            var lassoBMPWidth:Number = lassoLayer1Bitmap.width * lassoBMPScaleX;
            var lassoBMPHeight:Number = lassoLayer1Bitmap.height * lassoBMPScaleY;
            if (CanvasController.checkedLayer === 2 || CanvasController.canvasLayer1Bitmap.visible === false)
            {
                lassoBMPWidth = lassoLayer2Bitmap.width * lassoBMPScaleX;
                lassoBMPHeight = lassoLayer2Bitmap.height * lassoBMPScaleY;
            }
            const boxX:Number = lassoLayer1.x;
            const boxY:Number = lassoLayer1.y;
            const ang:Number = lassoLayer1.rotation * Math.PI / 180;
            var posMatrix:Matrix = new Matrix();
            posMatrix.scale(lassoBMPScaleX, lassoBMPScaleY); // 스케일부터 조절해주고
            posMatrix.translate(-lassoBMPWidth / 2, -lassoBMPHeight / 2); // 회전 중심점을 bmp중심으로 옮겨주고
            posMatrix.rotate(ang); // 회전해줌
            posMatrix.translate(boxX, boxY); // 라소박스 위치 그대로 붙여주면됨
            lassoLayer1Bitmap.smoothing = true;
            lassoLayer2Bitmap.smoothing = true;
            if (isTransferRefLayer === false)
            {
                if (CanvasController.canvasLayer1Bitmap.visible)
                    CanvasController.canvasLayer1BitmapData.draw(lassoLayer1Bitmap, posMatrix);
                if (CanvasController.canvasLayer2Bitmap.visible)
                    CanvasController.canvasLayer2BitmapData.draw(lassoLayer2Bitmap, posMatrix);
            }
            else
            {
                var layer1Bmpd:BitmapData;
                var layer2Bmpd:BitmapData;
                if (CanvasController.canvasLayer1Bitmap.visible)
                {
                    layer1Bmpd = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
                    layer1Bmpd.draw(lassoLayer1Bitmap, posMatrix);
                }
                if (CanvasController.canvasLayer2Bitmap.visible)
                {
                    layer2Bmpd = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0);
                    layer2Bmpd.draw(lassoLayer2Bitmap, posMatrix);
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

        public static function applyLassoImageToCanvas():void
        {
            if (_isStarted === true)
            {
                if (hasLassoImageChanges() === true) // 사용후에 ok하면 처리해줌
                {
                    if (UndoManager.isDeepUndoEnabled)
                    {
                        UndoManager.applyDeepUndo();
                    }
                    const lassoInfo:Array = applyLassoBoxImageToCanvas(false);
                    const point1:Vector.<Number> = lassoTransformData[0].concat();
                    const point2:Array = lassoTransformData[1].concat();
                    var command:Array = null;
                    if (lassoLayerCommandData && lassoLayerCommandData.length > 0)
                    {
                        command = lassoLayerCommandData.concat();
                    }
                    var checklayer1:Boolean = CanvasController.canvasLayer1Bitmap.visible;
                    var checklayer2:Boolean = CanvasController.canvasLayer2Bitmap.visible;
                    if (CanvasController.checkedLayer === 1)
                    {
                        checklayer1 = true;
                        checklayer2 = false;
                    }
                    else if (CanvasController.checkedLayer === 2)
                    {
                        checklayer1 = false;
                        checklayer2 = true;
                    }
                    ReplayState.rMemoryDataBuffer.push(["lasso2", point1, point2
                                , lassoInfo
                                , isLassoImageCopied
                                , checklayer1
                                , checklayer2
                                , command]);
                    UndoController.addNew();
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
            if (lassoLayer1Bitmap.bitmapData)
            {
                lassoLayer1Bitmap.bitmapData.dispose();
            }
            if (lassoLayer2Bitmap.bitmapData)
            {
                lassoLayer2Bitmap.bitmapData.dispose();
            }
        }

        // todo cancel lasso bmpd 로 바꾸기, lasso툴이적용되었을경우 리플레이나 undo성능 향상을 위해서 캐싱하고 파일저장에도 써주여야함 이는 나중에 .fofo 새로운 세이브파일 구현때 하기
        public static function restoreToLastBmpd():void
        {
            if (lassoLayer1LastBitmapdata === null && lassoLayer2LastBitmapdata === null)
            {
                return;
            }

            if (lassoLayer1LastBitmapdata)
            {
                CanvasController.copyPixels(CanvasController.canvasLayer1BitmapData, lassoLayer1LastBitmapdata);
            }
            if (lassoLayer2LastBitmapdata)
            {
                CanvasController.copyPixels(CanvasController.canvasLayer2BitmapData, lassoLayer2LastBitmapdata);
            }
            CanvasController.canvasNavigatorBox.updateImage();
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
            InputManager.removeInputEventsLassoTool();
            _isStarted = false;
            isLassoMirrorON = false;
            isLassoImageCopied = false;
            _isLassoMenuHiddenTemp = false;
            lassoLayerCommandData = null;
            isLassoLayerSwapButtonClicked = false;
            lassoFirstData = [];
            lassoTransformData = [];
            lassoLayer1Bitmap.filters = [];
            lassoLayer2Bitmap.filters = [];
            _lassoMenuBox.visible = false;
            lassoDraw.x = 0;
            lassoDraw.y = 0;
            lassoLayer1.visible = false;
            lassoLayer1.x = 0;
            lassoLayer1.y = 0;
            lassoLayer1.scaleX = 1.0;
            lassoLayer1.scaleY = 1.0;
            lassoLayer1.rotation = 0;
            lassoLayer2.visible = false;
            lassoLayer2.x = 0;
            lassoLayer2.y = 0;
            lassoLayer2.scaleX = 1.0;
            lassoLayer2.scaleY = 1.0;
            lassoLayer2.rotation = 0;
            _lassoMenuBox.lassoCopy.alpha = 1.0;
            _lassoMenuBox.lassoLayerMerge.alpha = 1.0;
            lassoDraw.visible = true;
            lassoDrawCloseLine.visible = true;
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
            if (ToolController.toolOptionsBox.layer1CheckedButton.visible || ToolController.toolOptionsBox.layer2CheckedButton.visible)
            {
                ToolController.toolBox.setToolButtonsForCheckedLayerON();
            }
            ToolController.toolBox.setIconAlphaOnLassoToolON(1.0);
            ToolController.toolOptionsBox.layerButtonWrapper.alpha = 1.0;
            ToolController.toolOptionsBox.airBrushButtonWrapper.alpha = 1.0;
            ToolController.toolOptionsBox.sharpLineButtonWrapper.alpha = 1.0;
            ToolController.toolOptionsBox.opaSizeButtonWrapper.alpha = 1.0;
            ToolController.selectLastUsedTool();
            setAlphaButtonsOnLassoTool(1.0);
        }

        public static function move1PXUp():void
        {
            _move1PX(LASSO_1PX_MOVE_UP);
        }

        public static function move1PXDown():void
        {
            _move1PX(LASSO_1PX_MOVE_DOWN);
        }

        public static function move1PXRight():void
        {
            _move1PX(LASSO_1PX_MOVE_RIGHT);
        }

        public static function move1PXLeft():void
        {
            _move1PX(LASSO_1PX_MOVE_LEFT);
        }

        public static function _move1PX(command:int):void
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

            const rotatedPoint:Point = Utils.rotatePoint(posX, posY, CanvasController.canvasAnchorPoint.rotation);
            lassoLayer1.x += rotatedPoint.x;
            lassoLayer1.y += rotatedPoint.y;
            lassoLayer2.x = lassoLayer1.x;
            lassoLayer2.y = lassoLayer1.y;
        }
    }
}
