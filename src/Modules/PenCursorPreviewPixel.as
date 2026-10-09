package Modules {
    import flash.display.GraphicsPathCommand;
    import flash.display.Sprite;
    import flash.geom.ColorTransform;

    /**
     * 정수 픽셀 원 및 사각형/직사각형을 감싸는 외곽선 알고리즘 클래스
     * setInverted()는 ColorTransform만 바꾸므로 지오메트리 계산이나 다시 그리기를 하지 않습니다.
     */
    // 층: L4 UI - 정수 픽셀 원·사각형 외곽선을 그리는 펜 커서 픽셀
    public class PenCursorPreviewPixel extends Sprite {

        public static const SHAPE_CIRCLE:String = "circle";
        public static const SHAPE_SQUARE:String = "square";
        public static const SHAPE_RECTANGLE:String = "rectangle";

        // 칸 표시값 (0: 빈 칸, 1: 본선, 2: 외곽선)
        private static const CELL_MAIN:uint = 1;
        private static const CELL_OUTLINE:uint = 2;

        // RGB만 반전, 알파 유지
        private static const INVERT_TRANSFORM:ColorTransform = new ColorTransform(-1, -1, -1, 1, 255, 255, 255, 0);
        private static const NORMAL_TRANSFORM:ColorTransform = new ColorTransform();

        // 모양을 계산할 때 쓰는 공용 칸 배열 (render마다 새로 만들지 않음)
        private static var _grid:Vector.<uint> = new Vector.<uint>();

        private var _currentType:String = SHAPE_CIRCLE;
        private var _baseSize:Number = 10;
        private var _currentZoom:Number = 1.0;

        // 사각형/직사각형 지오메트리 변수
        private var _rectX:int = 0;
        private var _rectY:int = 0;
        private var _rectWidth:int = 10;
        private var _rectHeight:int = 10;

        // 직전에 그린 모양 (같으면 다시 그리지 않음)
        private var _drawnType:String = null;
        private var _drawnA:int = 0;
        private var _drawnB:int = 0;
        private var _drawnC:int = 0;
        private var _drawnD:int = 0;

        // 색상 반전 플래그 (false: 검은색 메인선 + 흰색 알파 외곽선 / true: 흰색 메인선 + 검은색 알파 외곽선)
        private var _isInverted:Boolean = false;

        public function PenCursorPreviewPixel() {
            this.mouseEnabled = false;
            this.mouseChildren = false;
        }

        public function get isInverted():Boolean {
            return _isInverted;
        }

        /**
         * 색상 반전 여부를 설정합니다.
         * @param inverted true인 경우 흰색 메인선(1.0) + 검은색 외곽선(0.25)으로 보입니다.
         */
        public function setInverted(inverted:Boolean):void {
            if (_isInverted != inverted) {
                _isInverted = inverted;
                this.transform.colorTransform = inverted ? INVERT_TRANSFORM : NORMAL_TRANSFORM;
            }
        }


        public function createCircle(diameter:Number, zoomScale:Number = 1.0):void {
            _currentType = SHAPE_CIRCLE;
            _baseSize = diameter;
            _currentZoom = zoomScale;
            render();
        }

        public function createSquare(size:Number, zoomScale:Number = 1.0):void {
            _currentType = SHAPE_SQUARE;
            _baseSize = size;
            _currentZoom = zoomScale;

            var pixelSize:int = Math.round(_baseSize * _currentZoom);
            var half:int = Math.round(pixelSize * 0.5);

            _rectX = -half;
            _rectY = -half;
            _rectWidth = pixelSize;
            _rectHeight = pixelSize;

            render();
        }

        /**
         * createRectangle 래퍼 메서드
         * 크기는 줌을 곱한 뒤 반올림하고, 위치는 중심 기준으로 반올림합니다. (x와 w를 따로 반올림하면 회전 중심이 어긋남)
         */
        public function createRectangle(startX:Number, startY:Number, width:Number, height:Number, zoomScale:Number = 1.0):void {
            _currentType = SHAPE_RECTANGLE;
            _currentZoom = zoomScale;

            var w:int = Math.round(width * _currentZoom);
            var h:int = Math.round(height * _currentZoom);
            var centerX:Number = (startX + width * 0.5) * _currentZoom;
            var centerY:Number = (startY + height * 0.5) * _currentZoom;

            _rectWidth = w;
            _rectHeight = h;
            _rectX = Math.round(centerX - w * 0.5);
            _rectY = Math.round(centerY - h * 0.5);

            render();
        }

        public function updateZoom(zoomScale:Number):void {
            _currentZoom = zoomScale;
            render();
        }

        private function render():void {
            if (_currentType == SHAPE_CIRCLE) {
                var pixelSize:int = Math.round(_baseSize * _currentZoom);
                if (pixelSize < 2) pixelSize = 2;
                if (_drawnType == SHAPE_CIRCLE && _drawnA == pixelSize) return;

                _drawnType = SHAPE_CIRCLE;
                _drawnA = pixelSize;
                this.graphics.clear();
                renderNonOverlappingPixelCircle(pixelSize);
            } else if (_currentType == SHAPE_SQUARE || _currentType == SHAPE_RECTANGLE) {
                var width:int = (_rectWidth < 1) ? 1 : _rectWidth;
                var height:int = (_rectHeight < 1) ? 1 : _rectHeight;
                if (_drawnType == SHAPE_RECTANGLE && _drawnA == _rectX && _drawnB == _rectY && _drawnC == width && _drawnD == height) return;

                _drawnType = SHAPE_RECTANGLE;
                _drawnA = _rectX;
                _drawnB = _rectY;
                _drawnC = width;
                _drawnD = height;
                this.graphics.clear();
                renderNonOverlappingPixelRectangle(_rectX, _rectY, width, height);
            }
        }

        /**
         * 칸 배열을 gridWidth x gridHeight 크기로 준비하고 0으로 비움
         */
        private function prepareGrid(gridWidth:int, gridHeight:int):void {
            var count:int = gridWidth * gridHeight;
            if (_grid.length < count) _grid.length = count;
            for (var i:int = 0; i < count; i++) {
                _grid[i] = 0;
            }
        }

        /**
         * 지정한 정수 영역에 픽셀 사각형 및 외곽선을 드로잉 (바깥 1칸 여백을 둠)
         */
        private function renderNonOverlappingPixelRectangle(startX:int, startY:int, width:int, height:int):void {
            var gw:int = width + 2;
            var gh:int = height + 2;
            var ox:int = 1 - startX;
            var oy:int = 1 - startY;
            prepareGrid(gw, gh);

            // 1. 메인 선 사각형 1px 정수 좌표 추출
            var lastRow:int = (height) * gw;
            for (var x:int = 1; x <= width; x++) {
                _grid[gw + x] = CELL_MAIN;                  // 상단
                _grid[lastRow + x] = CELL_MAIN;             // 하단
            }
            for (var y:int = 1; y <= height; y++) {
                _grid[y * gw + 1] = CELL_MAIN;              // 좌측
                _grid[y * gw + width] = CELL_MAIN;          // 우측
            }

            // 2. 4방향 이웃 중 빈 칸에만 외곽선 표시
            markOutline(gw, gh);

            // 3. 색마다 한 번씩 drawPath
            drawPixels(gw, gh, ox, oy);
        }

        /**
         * 정수 픽셀 원형 알고리즘 및 외곽선 드로잉
         */
        private function renderNonOverlappingPixelCircle(diameter:int):void {
            var radius:int = Math.floor(diameter * 0.5);
            var x:int = radius;
            var y:int = 0;
            var d:int = 1 - radius;

            var shift:int = (diameter % 2 == 0) ? -1 : 0;

            // 좌표 범위 [-radius, radius] + 외곽선 1칸
            var gw:int = 2 * radius + 3;
            var ox:int = radius + 1;
            prepareGrid(gw, gw);

            // 1. Bresenham 알고리즘 기반 메인 픽셀 좌표 추출
            while (x >= y) {
                collect4x(gw, ox, x, y, shift);
                collect4x(gw, ox, y, x, shift);

                y++;
                if (d < 0) {
                    d += 2 * y + 1;
                } else {
                    x--;
                    d += 2 * (y - x) + 1;
                }
            }

            // 2. 4방향 이웃 검사로 빈 칸에만 외곽선 표시
            markOutline(gw, gw);

            // 3. 색마다 한 번씩 drawPath
            drawPixels(gw, gw, ox, ox);
        }

        private function collect4x(gw:int, o:int, px:int, py:int, shift:int):void {
            _grid[(py + shift + o) * gw + (px + shift + o)] = CELL_MAIN;
            _grid[(py + shift + o) * gw + (-px + o)] = CELL_MAIN;
            _grid[(-py + o) * gw + (px + shift + o)] = CELL_MAIN;
            _grid[(-py + o) * gw + (-px + o)] = CELL_MAIN;
        }

        /**
         * 본선 칸의 상하좌우 이웃 중 비어 있는 칸을 외곽선으로 표시
         * 배열 가장자리 한 줄은 항상 비어 있으므로 범위 검사가 필요 없음
         */
        private function markOutline(gw:int, gh:int):void {
            for (var y:int = 1; y < gh - 1; y++) {
                for (var x:int = 1; x < gw - 1; x++) {
                    var i:int = y * gw + x;
                    if (_grid[i] != CELL_MAIN) continue;
                    if (_grid[i - 1] == 0) _grid[i - 1] = CELL_OUTLINE;
                    if (_grid[i + 1] == 0) _grid[i + 1] = CELL_OUTLINE;
                    if (_grid[i - gw] == 0) _grid[i - gw] = CELL_OUTLINE;
                    if (_grid[i + gw] == 0) _grid[i + gw] = CELL_OUTLINE;
                }
            }
        }

        /**
         * 기본 상태(검은 본선 1.0 + 흰 외곽선 0.25)로만 그림. 반전은 ColorTransform이 처리
         */
        private function drawPixels(gw:int, gh:int, ox:int, oy:int):void {
            drawRuns(CELL_OUTLINE, 0xFFFFFF, 0.25, gw, gh, ox, oy);
            drawRuns(CELL_MAIN, 0x000000, 1.0, gw, gh, ox, oy);
        }

        /**
         * 같은 표시값이 가로로 이어진 칸을 사각형 하나로 합쳐 drawPath 한 번으로 그림 (사각형끼리 겹치지 않음)
         */
        private function drawRuns(mark:uint, color:uint, alpha:Number, gw:int, gh:int, ox:int, oy:int):void {
            var commands:Vector.<int> = new Vector.<int>();
            var coords:Vector.<Number> = new Vector.<Number>();

            for (var y:int = 0; y < gh; y++) {
                var row:int = y * gw;
                var x:int = 0;
                while (x < gw) {
                    if (_grid[row + x] != mark) {
                        x++;
                        continue;
                    }
                    var start:int = x;
                    while (x < gw && _grid[row + x] == mark) x++;

                    var left:int = start - ox;
                    var right:int = x - ox;
                    var top:int = y - oy;
                    commands.push(GraphicsPathCommand.MOVE_TO, GraphicsPathCommand.LINE_TO, GraphicsPathCommand.LINE_TO, GraphicsPathCommand.LINE_TO);
                    coords.push(left, top, right, top, right, top + 1, left, top + 1);
                }
            }

            if (commands.length == 0) return;
            this.graphics.beginFill(color, alpha);
            this.graphics.drawPath(commands, coords);
            this.graphics.endFill();
        }
    }
}
