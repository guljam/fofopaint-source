package Modules
{
    import Modules.Tools.PenTool;
    import flash.display.Shape;
    import flash.geom.Rectangle;

    public class PenSizePreviewCursor
    {

        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
            _cursor.name = "penSizeCursor";
            _cursor.visible = false;
        }

        private static const _cursor:Shape = new Shape(); // 펜사이즈 미리 보기
        private static var _cursorSize:Number = PenTool.penSize;
        private static var _cursorShape:Boolean = PenTool.penIsSquare;
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
            return _cursor.getBounds(CanvasController.canvasPanel);
        }

        public static function getCursorShape():Shape
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
            cursorSize = size * CanvasController.canvasZoomMultipler;
        }

        public static function updateZoom(z:Number):void
        {
            if (ToolController.isSelectedToolPenOrLine())
            {
                cursorSize = PenTool.penSize * CanvasController.canvasZoomMultipler;
            }
            else if (ToolController.isSelectedTool(ToolController.TOOL_ERASER))
            {
                cursorSize = PenTool.eraserSize * CanvasController.canvasZoomMultipler;
            }
            else
            {
                cursorSize = 0;
            }
        }

        //todo 툴선택메서드(펜지우게 등)에서  updatePosAndVisibility updateSizeAndShape등 제거하고 툴선택이 완료된시점에  refreshCursorAfterToolSelection만 호출하기
        private static function refreshCursorAfterToolSelection():void
        {
            PenSizePreviewCursor.updateSizeAndShape();
            PenSizePreviewCursor.updatePosAndVisibility();
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
                    || !main.isCursorInDrawArea()
                    || main.resizeCanvas.isCanvasResizing()
                    || (ReferenceLayerController.refLayerMenuBox.visible && ReferenceLayerController.refLayerMenuBox.hitTestPoint(mx, my))
                    || FileManager.loadMenuBox.visible)
            {
                _cursor.visible = false;
            }
            else
            {
                // addundo플래그가 커서가 캔버스 안에 들어올때 해주기 때문에 위치를 계속 갱신해줘야함
                _cursor.x = mx;
                _cursor.y = my;
                checkCursorVisibility();
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
                _cursorSize = PenTool.penSize;
                _cursorShape = PenTool.penIsSquare;
            }
            else
            {
                _cursorSize = PenTool.eraserSize;
                _cursorShape = PenTool.eraserIsSquare;
            }
            const z:Number = CanvasController.canvasZoomMultipler;
            if (_cursorSize * z === PenTool.penLastSizeAndShape[0] && _cursorShape === PenTool.penLastSizeAndShape[1])
            {
                return;
            }
            PenTool.penLastSizeAndShape[0] = _cursorSize * z;
            PenTool.penLastSizeAndShape[1] = _cursorShape;
            _cursor.graphics.clear();
            if (_cursorShape === false)
            {
                _cursor.graphics.lineStyle(1, 0xFFFFFF);
                _cursor.graphics.drawCircle(0, 0, (_cursorSize / 2 - 1 / z) * z);
                _cursor.graphics.lineStyle(1, 0);
                _cursor.graphics.drawCircle(0, 0, (_cursorSize / 2) * z);
                _cursor.rotation = 0;
            }
            else if (_cursorShape === true)
            {
                _cursor.graphics.lineStyle(1, 0xFFFFFF);
                _cursor.graphics.drawRect((-_cursorSize / 2 + 1 / z) * z, (-_cursorSize / 8 + 1 / z) * z, (_cursorSize - 2 / z) * z, (_cursorSize / 4 - 2 / z) * z);
                _cursor.graphics.lineStyle(1, 0);
                _cursor.graphics.drawRect(-_cursorSize / 2 * z, -_cursorSize / 8 * z, _cursorSize * z, _cursorSize * z / 4);
            }
        }
    }
}
