package Modules.L4UI {
    import flash.display.GraphicsPathCommand;
    import flash.display.Sprite;
    import flash.geom.ColorTransform;

    /**
     * 정수 픽셀 원 및 사각형/직사각형을 감싸는 외곽선 알고리즘 클래스
     * setCursorColorInverted()는 ColorTransform만 바꾸므로 지오메트리 계산이나 다시 그리기를 하지 않습니다.
     */
    // 층: L4 UI - 정수 픽셀 원·사각형 외곽선을 그리는 펜 커서 픽셀
    public class PenCursorPreviewPixel extends Sprite {

        public static const SHAPE_CIRCLE:String = "circle";
        public static const SHAPE_SQUARE:String = "square";
        public static const SHAPE_RECTANGLE:String = "rectangle";

        // 칸 표시값 (0: 빈 칸, 1: 본선, 2: 외곽선)
        private static const CELL_MAIN:uint = 1;
        private static const CELL_OUTLINE:uint = 2;
        private static const CELL_OUTLINE_ALPHA:Number = 0.35;

        // RGB만 반전, 알파 유지
        private static const INVERTED_COLOR_TRANSFORM:ColorTransform = new ColorTransform(-1, -1, -1, 1, 255, 255, 255, 0);
        private static const NORMAL_COLOR_TRANSFORM:ColorTransform = new ColorTransform();

        // 모양을 계산할 때 쓰는 공용 칸 배열 (그릴 때마다 새로 만들지 않음)
        private static var cellMarkGrid:Vector.<uint> = new Vector.<uint>();

        private var _currentShapeType:String = SHAPE_CIRCLE;
        private var _currentShapeSize:Number = 10;
        private var _currentCanvasZoom:Number = 1.0;

        // 사각형/직사각형 지오메트리 변수
        private var _rectangleStartX:int = 0;
        private var _rectangleStartY:int = 0;
        private var _rectangleWidth:int = 10;
        private var _rectangleHeight:int = 10;

        // 직전에 그린 모양 (같으면 다시 그리지 않음)
        private var _lastDrawnShapeType:String = null;
        private var _lastDrawnCircleDiameter:int = 0;
        private var _lastDrawnRectangleStartX:int = 0;
        private var _lastDrawnRectangleStartY:int = 0;
        private var _lastDrawnRectangleWidth:int = 0;
        private var _lastDrawnRectangleHeight:int = 0;

        // 색상 반전 플래그 (false: 검은색 메인선 + 흰색 알파 외곽선 / true: 흰색 메인선 + 검은색 알파 외곽선)
        private var _isCursorColorInverted:Boolean = false;

        public function PenCursorPreviewPixel() {
            this.mouseEnabled = false;
            this.mouseChildren = false;
        }

        public function get isCursorColorInverted():Boolean {
            return _isCursorColorInverted;
        }

        /**
         * 색상 반전 여부를 설정합니다.
         * @param isInverted true인 경우 흰색 메인선(1.0) + 검은색 외곽선(CELL_OUTLINE_ALPHA)으로 보입니다.
         */
        public function setCursorColorInverted(isInverted:Boolean):void {
            if (_isCursorColorInverted != isInverted) {
                _isCursorColorInverted = isInverted;
                this.transform.colorTransform = isInverted ? INVERTED_COLOR_TRANSFORM : NORMAL_COLOR_TRANSFORM;
            }
        }


        public function createCircleCursorShape(diameter:Number, canvasZoom:Number = 1.0):void {
            _currentShapeType = SHAPE_CIRCLE;
            _currentShapeSize = diameter;
            _currentCanvasZoom = canvasZoom;
            drawCurrentShapeIfChanged();
        }

        public function createSquareCursorShape(sideLength:Number, canvasZoom:Number = 1.0):void {
            _currentShapeType = SHAPE_SQUARE;
            _currentShapeSize = sideLength;
            _currentCanvasZoom = canvasZoom;

            var sideLengthInPixels:int = Math.round(_currentShapeSize * _currentCanvasZoom);
            var halfSideLengthInPixels:int = Math.round(sideLengthInPixels * 0.5);

            _rectangleStartX = -halfSideLengthInPixels;
            _rectangleStartY = -halfSideLengthInPixels;
            _rectangleWidth = sideLengthInPixels;
            _rectangleHeight = sideLengthInPixels;

            drawCurrentShapeIfChanged();
        }

        /**
         * createRectangleCursorShape 래퍼 메서드
         * 크기는 줌을 곱한 뒤 반올림하고, 위치는 중심 기준으로 반올림합니다. (x와 w를 따로 반올림하면 회전 중심이 어긋남)
         */
        public function createRectangleCursorShape(startX:Number, startY:Number, width:Number, height:Number, canvasZoom:Number = 1.0):void {
            _currentShapeType = SHAPE_RECTANGLE;
            _currentCanvasZoom = canvasZoom;

            var widthInPixels:int = Math.round(width * _currentCanvasZoom);
            var heightInPixels:int = Math.round(height * _currentCanvasZoom);
            var centerX:Number = (startX + width * 0.5) * _currentCanvasZoom;
            var centerY:Number = (startY + height * 0.5) * _currentCanvasZoom;

            _rectangleWidth = widthInPixels;
            _rectangleHeight = heightInPixels;
            _rectangleStartX = Math.round(centerX - widthInPixels * 0.5);
            _rectangleStartY = Math.round(centerY - heightInPixels * 0.5);

            drawCurrentShapeIfChanged();
        }

        public function updateCursorShapeCanvasZoom(canvasZoom:Number):void {
            _currentCanvasZoom = canvasZoom;
            drawCurrentShapeIfChanged();
        }

        private function drawCurrentShapeIfChanged():void {
            if (_currentShapeType == SHAPE_CIRCLE) {
                var circleDiameterInPixels:int = Math.round(_currentShapeSize * _currentCanvasZoom);
                if (circleDiameterInPixels < 2) circleDiameterInPixels = 2;
                if (_lastDrawnShapeType == SHAPE_CIRCLE && _lastDrawnCircleDiameter == circleDiameterInPixels) return;

                _lastDrawnShapeType = SHAPE_CIRCLE;
                _lastDrawnCircleDiameter = circleDiameterInPixels;
                this.graphics.clear();
                drawNonOverlappingPixelCircle(circleDiameterInPixels);
            } else if (_currentShapeType == SHAPE_SQUARE || _currentShapeType == SHAPE_RECTANGLE) {
                var rectangleWidthInPixels:int = (_rectangleWidth < 1) ? 1 : _rectangleWidth;
                var rectangleHeightInPixels:int = (_rectangleHeight < 1) ? 1 : _rectangleHeight;
                if (_lastDrawnShapeType == SHAPE_RECTANGLE
                        && _lastDrawnRectangleStartX == _rectangleStartX && _lastDrawnRectangleStartY == _rectangleStartY
                        && _lastDrawnRectangleWidth == rectangleWidthInPixels && _lastDrawnRectangleHeight == rectangleHeightInPixels) return;

                _lastDrawnShapeType = SHAPE_RECTANGLE;
                _lastDrawnRectangleStartX = _rectangleStartX;
                _lastDrawnRectangleStartY = _rectangleStartY;
                _lastDrawnRectangleWidth = rectangleWidthInPixels;
                _lastDrawnRectangleHeight = rectangleHeightInPixels;
                this.graphics.clear();
                drawNonOverlappingPixelRectangle(_rectangleStartX, _rectangleStartY, rectangleWidthInPixels, rectangleHeightInPixels);
            }
        }

        /**
         * 칸 배열을 gridWidth x gridHeight 크기로 준비하고 0으로 비움
         */
        private function clearCellMarkGrid(gridWidth:int, gridHeight:int):void {
            var cellCount:int = gridWidth * gridHeight;
            if (cellMarkGrid.length < cellCount) cellMarkGrid.length = cellCount;
            for (var cellIndex:int = 0; cellIndex < cellCount; cellIndex++) {
                cellMarkGrid[cellIndex] = 0;
            }
        }

        /**
         * 지정한 정수 영역에 픽셀 사각형 및 외곽선을 드로잉 (바깥 1칸 여백을 둠)
         */
        private function drawNonOverlappingPixelRectangle(startX:int, startY:int, width:int, height:int):void {
            var gridWidth:int = width + 2;
            var gridHeight:int = height + 2;
            var gridOriginOffsetX:int = 1 - startX;
            var gridOriginOffsetY:int = 1 - startY;
            clearCellMarkGrid(gridWidth, gridHeight);

            // 1. 메인 선 사각형 1px 정수 좌표 추출
            var bottomRowStartIndex:int = (height) * gridWidth;
            for (var columnIndex:int = 1; columnIndex <= width; columnIndex++) {
                cellMarkGrid[gridWidth + columnIndex] = CELL_MAIN;                  // 상단
                cellMarkGrid[bottomRowStartIndex + columnIndex] = CELL_MAIN;        // 하단
            }
            for (var rowIndex:int = 1; rowIndex <= height; rowIndex++) {
                cellMarkGrid[rowIndex * gridWidth + 1] = CELL_MAIN;                 // 좌측
                cellMarkGrid[rowIndex * gridWidth + width] = CELL_MAIN;             // 우측
            }

            // 2. 4방향 이웃 중 빈 칸에만 외곽선 표시
            markOutlineCellsAroundMainCells(gridWidth, gridHeight);

            // 3. 색마다 한 번씩 drawPath
            drawOutlineAndMainCells(gridWidth, gridHeight, gridOriginOffsetX, gridOriginOffsetY);
        }

        /**
         * 정수 픽셀 원형 알고리즘 및 외곽선 드로잉
         */
        private function drawNonOverlappingPixelCircle(diameter:int):void {
            var radius:int = Math.floor(diameter * 0.5);
            var offsetFromCenterX:int = radius;
            var offsetFromCenterY:int = 0;
            var decisionValue:int = 1 - radius;

            var evenDiameterShift:int = (diameter % 2 == 0) ? -1 : 0;

            // 좌표 범위 [-radius, radius] + 외곽선 1칸
            var gridWidth:int = 2 * radius + 3;
            var gridOriginOffset:int = radius + 1;
            clearCellMarkGrid(gridWidth, gridWidth);

            // 1. Bresenham 알고리즘 기반 메인 픽셀 좌표 추출
            while (offsetFromCenterX >= offsetFromCenterY) {
                markMainCellsInFourQuadrants(gridWidth, gridOriginOffset, offsetFromCenterX, offsetFromCenterY, evenDiameterShift);
                markMainCellsInFourQuadrants(gridWidth, gridOriginOffset, offsetFromCenterY, offsetFromCenterX, evenDiameterShift);

                offsetFromCenterY++;
                if (decisionValue < 0) {
                    decisionValue += 2 * offsetFromCenterY + 1;
                } else {
                    offsetFromCenterX--;
                    decisionValue += 2 * (offsetFromCenterY - offsetFromCenterX) + 1;
                }
            }

            // 2. 4방향 이웃 검사로 빈 칸에만 외곽선 표시
            markOutlineCellsAroundMainCells(gridWidth, gridWidth);

            // 3. 색마다 한 번씩 drawPath
            drawOutlineAndMainCells(gridWidth, gridWidth, gridOriginOffset, gridOriginOffset);
        }

        private function markMainCellsInFourQuadrants(gridWidth:int, gridOriginOffset:int, offsetFromCenterX:int, offsetFromCenterY:int, evenDiameterShift:int):void {
            cellMarkGrid[(offsetFromCenterY + evenDiameterShift + gridOriginOffset) * gridWidth + (offsetFromCenterX + evenDiameterShift + gridOriginOffset)] = CELL_MAIN;
            cellMarkGrid[(offsetFromCenterY + evenDiameterShift + gridOriginOffset) * gridWidth + (-offsetFromCenterX + gridOriginOffset)] = CELL_MAIN;
            cellMarkGrid[(-offsetFromCenterY + gridOriginOffset) * gridWidth + (offsetFromCenterX + evenDiameterShift + gridOriginOffset)] = CELL_MAIN;
            cellMarkGrid[(-offsetFromCenterY + gridOriginOffset) * gridWidth + (-offsetFromCenterX + gridOriginOffset)] = CELL_MAIN;
        }

        /**
         * 본선 칸의 상하좌우 이웃 중 비어 있는 칸을 외곽선으로 표시
         * 배열 가장자리 한 줄은 항상 비어 있으므로 범위 검사가 필요 없음
         */
        private function markOutlineCellsAroundMainCells(gridWidth:int, gridHeight:int):void {
            for (var rowIndex:int = 1; rowIndex < gridHeight - 1; rowIndex++) {
                for (var columnIndex:int = 1; columnIndex < gridWidth - 1; columnIndex++) {
                    var cellIndex:int = rowIndex * gridWidth + columnIndex;
                    if (cellMarkGrid[cellIndex] != CELL_MAIN) continue;
                    if (cellMarkGrid[cellIndex - 1] == 0) cellMarkGrid[cellIndex - 1] = CELL_OUTLINE;
                    if (cellMarkGrid[cellIndex + 1] == 0) cellMarkGrid[cellIndex + 1] = CELL_OUTLINE;
                    if (cellMarkGrid[cellIndex - gridWidth] == 0) cellMarkGrid[cellIndex - gridWidth] = CELL_OUTLINE;
                    if (cellMarkGrid[cellIndex + gridWidth] == 0) cellMarkGrid[cellIndex + gridWidth] = CELL_OUTLINE;
                }
            }
        }

        /**
         * 기본 상태(검은 본선 1.0 + 흰 외곽선 CELL_OUTLINE_ALPHA)로만 그림. 반전은 ColorTransform이 처리
         */
        private function drawOutlineAndMainCells(gridWidth:int, gridHeight:int, gridOriginOffsetX:int, gridOriginOffsetY:int):void {
            drawHorizontalCellRuns(CELL_OUTLINE, 0xFFFFFF, CELL_OUTLINE_ALPHA, gridWidth, gridHeight, gridOriginOffsetX, gridOriginOffsetY);
            drawHorizontalCellRuns(CELL_MAIN, 0x000000, 1.0, gridWidth, gridHeight, gridOriginOffsetX, gridOriginOffsetY);
        }

        /**
         * 같은 표시값이 가로로 이어진 칸을 사각형 하나로 합쳐 drawPath 한 번으로 그림 (사각형끼리 겹치지 않음)
         */
        private function drawHorizontalCellRuns(cellMark:uint, fillColor:uint, fillAlpha:Number, gridWidth:int, gridHeight:int, gridOriginOffsetX:int, gridOriginOffsetY:int):void {
            var pathCommands:Vector.<int> = new Vector.<int>();
            var pathCoordinates:Vector.<Number> = new Vector.<Number>();

            for (var rowIndex:int = 0; rowIndex < gridHeight; rowIndex++) {
                var rowStartIndex:int = rowIndex * gridWidth;
                var columnIndex:int = 0;
                while (columnIndex < gridWidth) {
                    if (cellMarkGrid[rowStartIndex + columnIndex] != cellMark) {
                        columnIndex++;
                        continue;
                    }
                    var runStartColumnIndex:int = columnIndex;
                    while (columnIndex < gridWidth && cellMarkGrid[rowStartIndex + columnIndex] == cellMark) columnIndex++;

                    var runLeftX:int = runStartColumnIndex - gridOriginOffsetX;
                    var runRightX:int = columnIndex - gridOriginOffsetX;
                    var runTopY:int = rowIndex - gridOriginOffsetY;
                    pathCommands.push(GraphicsPathCommand.MOVE_TO, GraphicsPathCommand.LINE_TO, GraphicsPathCommand.LINE_TO, GraphicsPathCommand.LINE_TO);
                    pathCoordinates.push(runLeftX, runTopY, runRightX, runTopY, runRightX, runTopY + 1, runLeftX, runTopY + 1);
                }
            }

            if (pathCommands.length == 0) return;
            this.graphics.beginFill(fillColor, fillAlpha);
            this.graphics.drawPath(pathCommands, pathCoordinates);
            this.graphics.endFill();
        }
    }
}
