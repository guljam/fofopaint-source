package Modules.L4UI
{
    import Modules.DrawEngine.CanvasView;
    import Modules.Tools.PenTool;
    import Modules.DrawEngine.DrawCanvas;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.getTimer;
    import Modules.L2Engine.DrawEngine.CanvasResizer;
    import Modules.L4UI.LoadBoxController;
    import Modules.L3Feature.Tools.ToolController;
    import Modules.MouseState;
    import Modules.PenCursorPreviewPixel;
    import Modules.L1Data.Tools.PenSettings;
    import Modules.ReferenceLayerController;
    import Modules.Utils;

    // 층: L4 UI - 펜 크기 미리보기 커서 (모양, 위치, 보임 여부)
    public class PenSizePreviewCursor
    {

        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
            _cursor.name = "penSizeCursor";
            _cursor.visible = false;
        }

        // 밑 색 밝기(L*)가 검은 커서면 이 값 이하, 흰 커서면 100 - 이 값 이상일 때 "커서와 비슷함"
        // 반드시 50 미만이어야 함. 50 이상이면 같은 밝기에서 두 조건이 동시에 참이 되어 확인할 때마다 검정<->흰색이 오감
        private static const LIGHTNESS_THRESHOLD:Number = 49;
        // 화면 기준 커서 지름(펜 크기 x 줌)이 이 값 미만이면 중심 1점만, 이 값 이상이면 중심 + 4점
        private static const SAMPLE_5_MIN_DIAMETER:Number = 16;
        // 이 값 이상이면 중심 + 8점 (총 개수는 1/5/9로 홀수라 동점이 없음)
        private static const SAMPLE_9_MIN_DIAMETER:Number = 40;
        private static const CHECK_INTERVAL:Number = 0.4; // 밑 색 확인 간격(초)
        private static const CHECK_TIMER_NAME:String = "penCursorInvertTimer";

        private static const _cursor:PenCursorPreviewPixel = new PenCursorPreviewPixel(); // 펜사이즈 미리 보기
        private static var lastCheckTime:int = -1000000;

        // 테두리 샘플 방향: 상하좌우 4개 다음에 대각선 4개
        private static const SAMPLE_DIR:Vector.<Number> = new <Number>[1, 0, 0, 1, -1, 0, 0, -1, Math.SQRT1_2, Math.SQRT1_2, -Math.SQRT1_2, Math.SQRT1_2, -Math.SQRT1_2, -Math.SQRT1_2, Math.SQRT1_2, -Math.SQRT1_2];
        private static const samplePoint:Point = new Point();
        private static var _cursorSize:Number = PenSettings.penSize;
        private static var _cursorShape:Boolean = PenSettings.penIsSquare;
        private static var cursorSize:Number = 3.0;
        private static var isPenSizeCursorInvisible:Boolean = false; // 펜 커서가 보이지 않게 설정

        public static function setRotation(angle:Number):void
        {
            _cursor.rotation = angle;
        }

        public static function getSize():Number
        {
            return _cursorSize;
        }

        public static function isSqure():Boolean
        {
            return _cursorShape;
        }

        public static function getCursorBoundsWithCanvasPanel():Rectangle
        {
            return _cursor.getBounds(CanvasView.canvasPanel);
        }

        public static function getCursorShape():PenCursorPreviewPixel
        {
            return _cursor;
        }

        public static function setCursorInVisibleFlag(flag:Boolean):void
        {
            isPenSizeCursorInvisible = flag;
        }

        public static function setVisible(flag:Boolean):void
        {
            _cursor.visible = flag;
        }

        public static function checkCursorVisibility():void
        {
            if (cursorSize <= 4 || ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
            {
                if (_cursor.visible)
                {
                    _cursor.visible = false;
                }
            }
            else if (_cursor.visible === false)
            {
                _cursor.visible = true;
            }
        }

        public static function getCursorSize():Number
        {
            return cursorSize;
        }

        public static function updateCursorSize(size:Number):void
        {
            cursorSize = size * CanvasView.canvasZoomMultiplier;
        }

        public static function updateZoom(z:Number):void
        {
            if (ToolController.isSelectedToolPenOrLine())
            {
                cursorSize = PenSettings.penSize * CanvasView.canvasZoomMultiplier;
            }
            else if (ToolController.isSelectedTool(ToolController.TOOL_ERASER))
            {
                cursorSize = PenSettings.eraserSize * CanvasView.canvasZoomMultiplier;
            }
            else
            {
                cursorSize = 0;
            }
        }

        public static function updatePosAndVisibility():void
        {
            const mx:Number = main.stage.mouseX;
            const my:Number = main.stage.mouseY;
            // 아마 이거 preview커서 박스 커서가 커져서 sidebar 바운더리가 커졌을때
            // 제대로 확인못해서 썼던걸거임
            // || (!quickSidebarON && !isCursorInDrawArea())
            // (sideBar.visible && (sideBarScrollBar.hitTestPoint(mouseX,mouseY) || sideBar.hitTestPoint(mouseX,mouseY)))
            if (isPenSizeCursorInvisible
                    || (ToolController.nowTool > ToolController.TOOL_LINE && ToolController.nowTool !== ToolController.TOOL_FILLPEN) // 1 2 3 4 펜 지우개 라인툴 라인-지우개툴
                    || !Utils.isCursorInDrawArea()
                    || CanvasResizer.isCanvasResizing()
                    || (ReferenceLayerController.refLayerMenuBox.visible && ReferenceLayerController.refLayerMenuBox.hitTestPoint(mx, my))
                    || LoadBoxController.loadMenuBox.visible)
            {
                _cursor.visible = false;
            }
            else
            {
                // addundo플래그가 커서가 캔버스 안에 들어올때 해주기 때문에 위치를 계속 갱신해줘야함
                _cursor.x = Math.floor(mx);
                _cursor.y = Math.floor(my);
                checkCursorVisibility();
                const nt:int = getTimer();
                
                requestColorCheck();
                trace("time = ",getTimer()-nt);
            }
        }

        // size, size drag, zoom, rotate시 업데이트 해줌
        public static function updateSizeAndShape():void
        {
            const isPenTool:Boolean = ToolController.isSelectedToolPenOrLine();
            if (!isPenTool && !ToolController.isSelectedTool(ToolController.TOOL_ERASER))
            {
                return;
            }
            if (isPenTool)
            {
                _cursorSize = PenSettings.penSize;
                _cursorShape = PenSettings.penIsSquare;
            }
            else
            {
                _cursorSize = PenSettings.eraserSize;
                _cursorShape = PenSettings.eraserIsSquare;
            }
            const z:Number = CanvasView.canvasZoomMultiplier;
            if (_cursorSize * z === PenTool.penLastSizeAndShape[0] && _cursorShape === PenTool.penLastSizeAndShape[1])
            {
                return;
            }
            PenTool.penLastSizeAndShape[0] = _cursorSize * z;
            PenTool.penLastSizeAndShape[1] = _cursorShape;
            if (_cursorShape === false)
            {
                _cursor.createCircle(_cursorSize, z);
                _cursor.rotation = 0;
            }
            else if (_cursorShape === true)
            {
                _cursor.createRectangle(-_cursorSize / 2, -_cursorSize / 8, _cursorSize, _cursorSize / 4, z);
            }
        }

        // 마우스를 누르면 대기 중인 확인을 취소함 (드래그 중에 실행되면 안 됨)
        public static function cancelPendingColorCheck():void
        {
            FOFOTimer.remove(CHECK_TIMER_NAME);
        }

        // 획이 레이어 비트맵에 반영된 뒤 호출. 대기 시간 없이 즉시 한 번 확인함
        public static function checkColorNow():void
        {
            cancelPendingColorCheck();
            if (_cursor.visible)
            {
                checkColor();
            }
        }

        // 마우스를 움직일 때 호출. 마지막 확인에서 CHECK_INTERVAL이 지났으면 즉시, 아니면 남은 시간 뒤에 한 번 확인
        private static function requestColorCheck():void
        {
            if (MouseState.isLeftDown || !_cursor.visible)
            {
                return;
            }
            const remain:Number = CHECK_INTERVAL * 1000 - (getTimer() - lastCheckTime);
            if (remain <= 0)
            {
                cancelPendingColorCheck();
                checkColor();
            }
            else if (!FOFOTimer.hasTimer(CHECK_TIMER_NAME))
            {
                FOFOTimer.addByName(CHECK_TIMER_NAME, remain / 1000, false, onCheckTimer);
            }
        }

        private static function onCheckTimer():void
        {
            if (!MouseState.isLeftDown && _cursor.visible)
            {
                checkColor();
            }
        }

        // 캔버스 좌표 (px, py) 한 점의 합성색: 배경 위에 레이어2, 그 위에 레이어1 (숨긴 레이어는 건너뜀)
        private static function compositeAt(px:int, py:int):uint
        {
            const bg:uint = DrawCanvas.CANVAS_BG_COLOR;
            var r:Number = (bg >>> 16) & 0xFF;
            var g:Number = (bg >>> 8) & 0xFF;
            var b:Number = bg & 0xFF;

            if (DrawCanvas.canvasLayer2Bitmap.visible)
            {
                const c2:uint = DrawCanvas.canvasLayer2BitmapData.getPixel32(px, py);
                const a2:Number = c2 >>> 24;
                r = (((c2 >>> 16) & 0xFF) * a2 + r * (255 - a2)) / 255;
                g = (((c2 >>> 8) & 0xFF) * a2 + g * (255 - a2)) / 255;
                b = ((c2 & 0xFF) * a2 + b * (255 - a2)) / 255;
            }
            if (DrawCanvas.canvasLayer1Bitmap.visible)
            {
                const c1:uint = DrawCanvas.canvasLayer1BitmapData.getPixel32(px, py);
                const a1:Number = c1 >>> 24;
                r = (((c1 >>> 16) & 0xFF) * a1 + r * (255 - a1)) / 255;
                g = (((c1 >>> 8) & 0xFF) * a1 + g * (255 - a1)) / 255;
                b = ((c1 & 0xFF) * a1 + b * (255 - a1)) / 255;
            }
            return (Math.round(r) << 16) | (Math.round(g) << 8) | Math.round(b);
        }

        // 샘플 i(1~)의 커서 로컬 좌표를 samplePoint에 넣음. 원은 반지름 위, 납작한 사각형은 변의 중점/꼭짓점 (본선 위)
        private static function setSampleLocal(i:int, diameter:Number):void
        {
            const dx:Number = SAMPLE_DIR[(i - 1) * 2];
            const dy:Number = SAMPLE_DIR[(i - 1) * 2 + 1];
            if (_cursorShape === false)
            {
                const radius:Number = Math.max(diameter / 2 - 0.5, 0);
                samplePoint.setTo(dx * radius, dy * radius);
            }
            else
            {
                const halfW:Number = Math.max(diameter / 2 - 0.5, 0);
                const halfH:Number = Math.max(diameter / 8 - 0.5, 0);
                samplePoint.setTo((dx > 0 ? halfW : (dx < 0 ? -halfW : 0)), (dy > 0 ? halfH : (dy < 0 ? -halfH : 0)));
            }
        }

        // 커서 중심과 테두리 여러 점 밑의 밝기(L*)를 보고, 엄격한 과반이 커서와 비슷하면 반전 상태를 뒤집음
        private static function checkColor():void
        {
            lastCheckTime = getTimer();
            const diameter:Number = _cursorSize * CanvasView.canvasZoomMultiplier;
            const count:int = (diameter < SAMPLE_5_MIN_DIAMETER) ? 1 : ((diameter < SAMPLE_9_MIN_DIAMETER) ? 5 : 9);
            const isInverted:Boolean = _cursor.isInverted;
            var valid:int = 0;
            var similar:int = 0;

            for (var i:int = 0; i < count; i++)
            {
                var px:int;
                var py:int;
                if (i === 0)
                {
                    px = Math.floor(CanvasView.canvasPanel.mouseX);
                    py = Math.floor(CanvasView.canvasPanel.mouseY);
                }
                else
                {
                    // 줌, 캔버스 회전, 미러, 커서 회전이 한 번에 반영됨
                    setSampleLocal(i, diameter);
                    const canvasPos:Point = CanvasView.canvasPanel.globalToLocal(_cursor.localToGlobal(samplePoint));
                    px = Math.floor(canvasPos.x);
                    py = Math.floor(canvasPos.y);
                }
                if (px < 0 || py < 0 || px >= DrawCanvas.CANVAS_WIDTH || py >= DrawCanvas.CANVAS_HEIGHT)
                {
                    continue; // 캔버스 밖 점은 세지 않음
                }
                valid++;
                const lightness:Number = Utils.getLightness(compositeAt(px, py));
                if (isInverted ? (lightness >= 100 - LIGHTNESS_THRESHOLD) : (lightness <= LIGHTNESS_THRESHOLD))
                {
                    similar++;
                }
            }

            if (valid > 0 && similar * 2 > valid)
            {
                _cursor.setInverted(!isInverted);
            }
        }
    }
}
