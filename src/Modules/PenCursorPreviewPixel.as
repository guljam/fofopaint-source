package Modules {
    import flash.display.Sprite;
    import flash.utils.Dictionary;

    /**
     * 정수 픽셀 원 및 사각형/직사각형을 감싸는 외곽선 알고리즘 클래스
     * setInverted()를 통해 메인 선과 외곽선의 색상을 즉시 반전시킬 수 있습니다.
     */
    public class PenCursorPreviewPixel extends Sprite {
        
        public static const SHAPE_CIRCLE:String = "circle";
        public static const SHAPE_SQUARE:String = "square";
        public static const SHAPE_RECTANGLE:String = "rectangle";

        private var _currentType:String = SHAPE_CIRCLE;
        private var _baseSize:Number = 10;
        private var _currentZoom:Number = 1.0;

        // 사각형/직사각형 지오메트리 변수
        private var _rectX:int = 0;
        private var _rectY:int = 0;
        private var _rectWidth:int = 10;
        private var _rectHeight:int = 10;

        // 색상 반전 플래그 (false: 검은색 메인선 + 흰색 알파 외곽선 / true: 흰색 메인선 + 검은색 알파 외곽선)
        private var _isInverted:Boolean = false;

        public function PenCursorPreviewPixel() {
            this.mouseEnabled = false;
            this.mouseChildren = false;
        }

        /**
         * 색상 반전 여부를 설정합니다.
         * @param inverted true인 경우 흰색 메인선(1.0) + 검은색 외곽선(0.4)으로 그려집니다.
         */
        public function setInverted(inverted:Boolean):void {
            if (_isInverted != inverted) {
                _isInverted = inverted;
                render();
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
         */
        public function createRectangle(startX:int, startY:int, width:int, height:int, zoomScale:Number = 1.0):void {
            _currentType = SHAPE_RECTANGLE;
            _currentZoom = zoomScale;
            
            _rectX = Math.round(startX * _currentZoom);
            _rectY = Math.round(startY * _currentZoom);
            _rectWidth = Math.round(width * _currentZoom);
            _rectHeight = Math.round(height * _currentZoom);

            render();
        }

        public function updateZoom(zoomScale:Number):void {
            _currentZoom = zoomScale;
            render();
        }

        private function render():void {
            this.graphics.clear();

            if (_currentType == SHAPE_CIRCLE) {
                var pixelSize:int = Math.round(_baseSize * _currentZoom);
                if (pixelSize < 2) pixelSize = 2;
                renderNonOverlappingPixelCircle(pixelSize);
            } else if (_currentType == SHAPE_SQUARE || _currentType == SHAPE_RECTANGLE) {
                renderNonOverlappingPixelRectangle(_rectX, _rectY, _rectWidth, _rectHeight);
            }
        }

        /**
         * 지정한 정수 영역에 픽셀 사각형 및 외곽선을 드로잉
         */
        private function renderNonOverlappingPixelRectangle(startX:int, startY:int, width:int, height:int):void {
            if (width < 1) width = 1;
            if (height < 1) height = 1;

            var blackMap:Dictionary = new Dictionary();
            var whiteMap:Dictionary = new Dictionary();

            // 1. 메인 선 사각형 1px 정수 좌표 추출
            for (var x:int = 0; x < width; x++) {
                blackMap[(startX + x) + "," + startY] = true;                     // 상단
                blackMap[(startX + x) + "," + (startY + height - 1)] = true;     // 하단
            }
            for (var y:int = 0; y < height; y++) {
                blackMap[startX + "," + (startY + y)] = true;                     // 좌측
                blackMap[(startX + width - 1) + "," + (startY + y)] = true;      // 우측
            }

            // 2. 메인 선 픽셀 주변 8방향 이웃 중 빈 공간에만 외곽선 좌표 수집
            collectOutlinePixels(blackMap, whiteMap);

            // 3. 반전 플래그에 맞춘 픽셀 렌더링
            drawPixelsWithColor(whiteMap, blackMap);
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

            var blackMap:Dictionary = new Dictionary();
            var whiteMap:Dictionary = new Dictionary();

            // 1. Bresenham 알고리즘 기반 메인 픽셀 좌표 추출
            while (x >= y) {
                collect4x(blackMap, x, y, shift);
                collect4x(blackMap, y, x, shift);

                y++;
                if (d < 0) {
                    d += 2 * y + 1;
                } else {
                    x--;
                    d += 2 * (y - x) + 1;
                }
            }

            // 2. 8방향 이웃 검사로 빈 공간에만 외곽선 좌표 수집
            collectOutlinePixels(blackMap, whiteMap);

            // 3. 반전 플래그에 맞춘 픽셀 렌더링
            drawPixelsWithColor(whiteMap, blackMap);
        }

        private function collect4x(map:Dictionary, px:int, py:int, shift:int):void {
            map[(px + shift) + "," + (py + shift)] = true;
            map[(-px) + "," + (py + shift)] = true;
            map[(px + shift) + "," + (-py)] = true;
            map[(-px) + "," + (-py)] = true;
        }

        /**
         * 메인 픽셀 좌표 주변 8방향 중 비어 있는 정수 칸을 외곽선 좌표로 수집
         */
        private function collectOutlinePixels(mainMap:Dictionary, outlineMap:Dictionary):void {
            var dirX:Array = [-1, 0, 1, -1, 1, -1, 0, 1];
            var dirY:Array = [-1, -1, -1, 0, 0, 1, 1, 1];

            for (var key:String in mainMap) {
                var pos:Array = key.split(",");
                var bx:int = int(pos[0]);
                var by:int = int(pos[1]);

                for (var i:int = 0; i < 8; i++) {
                    var nx:int = bx + dirX[i];
                    var ny:int = by + dirY[i];
                    var neighborKey:String = nx + "," + ny;

                    if (!mainMap[neighborKey]) {
                        outlineMap[neighborKey] = true;
                    }
                }
            }
        }

        /**
         * _isInverted 플래그에 따라 메인선과 외곽선의 색상을 결정하여 그리드에 드로잉
         */
        private function drawPixelsWithColor(outlineMap:Dictionary, mainMap:Dictionary):void {
            var mainColor:uint = _isInverted ? 0xFFFFFF : 0x000000;
            var mainAlpha:Number = 1.0;

            var outlineColor:uint = _isInverted ? 0x000000 : 0xFFFFFF;
            var outlineAlpha:Number = 0.25;

            // 1. 외곽선 픽셀 드로잉 (Alpha 0.4)
            this.graphics.beginFill(outlineColor, outlineAlpha);
            for (var oKey:String in outlineMap) {
                var oPos:Array = oKey.split(",");
                this.graphics.drawRect(int(oPos[0]), int(oPos[1]), 1, 1);
            }
            this.graphics.endFill();

            // 2. 메인 선 픽셀 드로잉 (Alpha 1.0)
            this.graphics.beginFill(mainColor, mainAlpha);
            for (var mKey:String in mainMap) {
                var mPos:Array = mKey.split(",");
                this.graphics.drawRect(int(mPos[0]), int(mPos[1]), 1, 1);
            }
            this.graphics.endFill();
        }
    }
}
