package Modules.L4UI
{
    import Modules.L1Data.AppContext;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.utils.getTimer;
    import Modules.L1Data.Tools.PenSettings;
    import Modules.L1Data.ToolState;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L4UI.DrawEngine.CanvasResizer;
    import Modules.L1Data.MouseState;
    import Modules.L1Data.Utils;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L4UI.Tools.PenTool;
    import Modules.L1Data.FOFOTimer;

    // 층: L4 UI - 펜 크기 미리보기 커서 (모양, 위치, 보임 여부)
    public class PenSizePreviewCursor
    {

        public static function initialize():void
        {
            _cursor.name = "penSizeCursor";
            _cursor.visible = false;
        }

        // 밑 색 밝기(L*)가 검은 커서면 이 값 이하, 흰 커서면 100 - 이 값 이상일 때 "커서와 비슷함"
        // 반드시 50 미만이어야 함. 50 이상이면 같은 밝기에서 두 조건이 동시에 참이 되어 확인할 때마다 검정<->흰색이 오감
        private static const LIGHTNESS_THRESHOLD:Number = 49;
        // 캔버스 안에 있는 테두리 점 중 이 비율 이상이 커서와 비슷하면 반전
        private static const INVERT_SIMILAR_OUTLINE_RATIO:Number = 0.51;
        private static const OUTLINE_COLOR_UNKNOWN:int = 0;
        private static const OUTLINE_COLOR_DARK:int = 1; // 밝기 L* <= LIGHTNESS_THRESHOLD
        private static const OUTLINE_COLOR_LIGHT:int = 2; // 밝기 L* >= 100 - LIGHTNESS_THRESHOLD
        private static const OUTLINE_COLOR_MIDDLE:int = 3;
        private static const OUTLINE_COLOR_OUTSIDE_CANVAS:int = 4;
        // 위 밝기 기준(L*)을 휘도 Y로 바꾼 값 (L* = 116 * Y^(1/3) - 16). 점마다 pow를 하지 않으려고 미리 계산
        private static const DARK_CURSOR_SIMILAR_MAX_LUMINANCE:Number = Math.pow((LIGHTNESS_THRESHOLD + 16) / 116, 3);
        private static const LIGHT_CURSOR_SIMILAR_MIN_LUMINANCE:Number = Math.pow((100 - LIGHTNESS_THRESHOLD + 16) / 116, 3);
        private static const SCAN_TIME_BUDGET_PER_FRAME_MS:int = 4; // 한 프레임에 테두리 탐색에 쓸 최대 시간
        private static const SCAN_POINTS_PER_TIME_CHECK:int = 32; // getTimer 호출은 이 점 수마다 한 번
        private static const CHECK_TIMER_NAME:String = "penCursorInvertTimer";

        private static const _cursor:PenCursorPreviewPixel = new PenCursorPreviewPixel(); // 펜사이즈 미리 보기

        // 테두리 점 목록 (커서 로컬 좌표). 크기/모양이 바뀔 때만 다시 만듦
        private static const outlineLocalXList:Vector.<Number> = new Vector.<Number>();
        private static const outlineLocalYList:Vector.<Number> = new Vector.<Number>();
        private static var outlinePointCount:int = 0;
        private static var nextScanPointIndex:int = 0; // 다음에 볼 점. 커서가 움직여도 유지하고, 크기/모양이 바뀌면 0
        // 점마다 마지막으로 본 밑 색 분류. 커서가 움직여도 지우지 않고 점을 다시 볼 때마다 갱신하므로 개수가 계속 따라감
        // 분류는 커서 색과 무관하게 저장하므로 반전되어도 그대로 쓸 수 있음
        private static const outlineColorStateList:Vector.<int> = new Vector.<int>();
        private static var darkPointCount:int = 0;
        private static var lightPointCount:int = 0;
        private static var middlePointCount:int = 0;
        private static var outsideCanvasPointCount:int = 0; // 캔버스 밖이라 비율 계산에서 뺀 점
        private static var isInvertSettled:Boolean = false; // 반전을 마친 상태. 커서가 움직이거나 분류를 버리기 전까지 탐색을 건너뜀
        private static const cursorLocalToCanvasMatrix:Matrix = new Matrix();
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
            if (cursorSize <= 4 || ToolState.isSelectedTool(ToolState.TOOL_FILLPEN))
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
            if (ToolState.isSelectedToolPenOrLine())
            {
                cursorSize = PenSettings.penSize * CanvasView.canvasZoomMultiplier;
            }
            else if (ToolState.isSelectedTool(ToolState.TOOL_ERASER))
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
            const mx:Number = AppContext.stage.mouseX;
            const my:Number = AppContext.stage.mouseY;
            // 아마 이거 preview커서 박스 커서가 커져서 sidebar 바운더리가 커졌을때
            // 제대로 확인못해서 썼던걸거임
            // || (!quickSidebarON && !isCursorInDrawArea())
            // (sideBar.visible && (sideBarScrollBar.hitTestPoint(mouseX,mouseY) || sideBar.hitTestPoint(mouseX,mouseY)))
            if (isPenSizeCursorInvisible
                    || (ToolState.nowTool > ToolState.TOOL_LINE && ToolState.nowTool !== ToolState.TOOL_FILLPEN) // 1 2 3 4 펜 지우개 라인툴 라인-지우개툴
                    || !UIController.isCursorInDrawArea()
                    || CanvasResizer.isCanvasResizing()
                    || (ReferenceLayerController.refLayerMenuBox.visible && ReferenceLayerController.refLayerMenuBox.hitTestPoint(mx, my))
                    || UIController.loadMenuBox.visible)
            {
                _cursor.visible = false;
            }
            else
            {
                // addundo플래그가 커서가 캔버스 안에 들어올때 해주기 때문에 위치를 계속 갱신해줘야함
                _cursor.x = Math.floor(mx);
                _cursor.y = Math.floor(my);
                checkCursorVisibility();
                startOutlineColorScanOnCursorMove();
            }
        }

        // size, size drag, zoom, rotate시 업데이트 해줌
        public static function updateSizeAndShape():void
        {
            const isPenTool:Boolean = ToolState.isSelectedToolPenOrLine();
            if (!isPenTool && !ToolState.isSelectedTool(ToolState.TOOL_ERASER))
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
            buildOutlineLocalPoints(_cursorSize * z, z);
        }

        // 테두리 점 목록을 새로 만들고 처음부터 다시 시작. 점 간격은 캔버스 약 1픽셀 (줌아웃이면 화면 1px)
        // 원은 반지름 위, 납작한 사각형은 본선 위 (시계 방향)
        private static function buildOutlineLocalPoints(cursorScreenDiameter:Number, canvasZoom:Number):void
        {
            const pointSpacingInScreenPixels:Number = Math.max(1, canvasZoom);
            const outlineHalfWidth:Number = Math.max(cursorScreenDiameter / 2 - 0.5, 0);
            outlineLocalXList.length = 0;
            outlineLocalYList.length = 0;
            if (_cursorShape === false)
            {
                const circlePointCount:int = Math.max(8, Math.ceil(2 * Math.PI * outlineHalfWidth / pointSpacingInScreenPixels));
                for (var circlePointIndex:int = 0; circlePointIndex < circlePointCount; circlePointIndex++)
                {
                    const pointAngle:Number = 2 * Math.PI * circlePointIndex / circlePointCount;
                    outlineLocalXList[circlePointIndex] = Math.cos(pointAngle) * outlineHalfWidth;
                    outlineLocalYList[circlePointIndex] = Math.sin(pointAngle) * outlineHalfWidth;
                }
                outlinePointCount = circlePointCount;
            }
            else
            {
                const outlineHalfHeight:Number = Math.max(cursorScreenDiameter / 8 - 0.5, 0);
                const rectangleWidth:Number = outlineHalfWidth * 2;
                const rectangleHeight:Number = outlineHalfHeight * 2;
                const perimeterLength:Number = 2 * (rectangleWidth + rectangleHeight);
                const rectanglePointCount:int = Math.max(8, Math.ceil(perimeterLength / pointSpacingInScreenPixels));
                for (var rectanglePointIndex:int = 0; rectanglePointIndex < rectanglePointCount; rectanglePointIndex++)
                {
                    var distanceFromRectangleTopLeft:Number = perimeterLength * rectanglePointIndex / rectanglePointCount;
                    if (distanceFromRectangleTopLeft < rectangleWidth)
                    {
                        outlineLocalXList[rectanglePointIndex] = -outlineHalfWidth + distanceFromRectangleTopLeft;
                        outlineLocalYList[rectanglePointIndex] = -outlineHalfHeight;
                    }
                    else if (distanceFromRectangleTopLeft < rectangleWidth + rectangleHeight)
                    {
                        outlineLocalXList[rectanglePointIndex] = outlineHalfWidth;
                        outlineLocalYList[rectanglePointIndex] = -outlineHalfHeight + (distanceFromRectangleTopLeft - rectangleWidth);
                    }
                    else if (distanceFromRectangleTopLeft < 2 * rectangleWidth + rectangleHeight)
                    {
                        outlineLocalXList[rectanglePointIndex] = outlineHalfWidth - (distanceFromRectangleTopLeft - rectangleWidth - rectangleHeight);
                        outlineLocalYList[rectanglePointIndex] = outlineHalfHeight;
                    }
                    else
                    {
                        outlineLocalXList[rectanglePointIndex] = -outlineHalfWidth;
                        outlineLocalYList[rectanglePointIndex] = outlineHalfHeight - (distanceFromRectangleTopLeft - 2 * rectangleWidth - rectangleHeight);
                    }
                }
                outlinePointCount = rectanglePointCount;
            }
            nextScanPointIndex = 0;
            clearOutlineColorStates();
        }

        // 모든 점의 분류를 "아직 모름"으로 되돌림. 크기/모양이 바뀌거나 그림이 바뀌어 예전 분류를 믿을 수 없을 때 호출
        private static function clearOutlineColorStates():void
        {
            isInvertSettled = false;
            outlineColorStateList.length = outlinePointCount;
            for (var pointIndex:int = 0; pointIndex < outlinePointCount; pointIndex++)
            {
                outlineColorStateList[pointIndex] = OUTLINE_COLOR_UNKNOWN;
            }
            darkPointCount = 0;
            lightPointCount = 0;
            middlePointCount = 0;
            outsideCanvasPointCount = 0;
        }

        // 점 하나의 분류가 바뀔 때 분류별 개수를 맞춰 줌
        private static function updatePointColorStateAndCounts(pointIndex:int, newColorState:int):void
        {
            const oldColorState:int = outlineColorStateList[pointIndex];
            if (oldColorState === newColorState)
            {
                return;
            }
            addAmountToColorStateCount(oldColorState, -1);
            addAmountToColorStateCount(newColorState, 1);
            outlineColorStateList[pointIndex] = newColorState;
        }

        private static function addAmountToColorStateCount(colorState:int, amount:int):void
        {
            if (colorState === OUTLINE_COLOR_DARK)
            {
                darkPointCount += amount;
            }
            else if (colorState === OUTLINE_COLOR_LIGHT)
            {
                lightPointCount += amount;
            }
            else if (colorState === OUTLINE_COLOR_MIDDLE)
            {
                middlePointCount += amount;
            }
            else if (colorState === OUTLINE_COLOR_OUTSIDE_CANVAS)
            {
                outsideCanvasPointCount += amount;
            }
        }

        // 마우스를 누르면 대기 중인 확인을 취소함 (드래그 중에 실행되면 안 됨)
        public static function stopOutlineColorScanTimer():void
        {
            FOFOTimer.remove(CHECK_TIMER_NAME);
        }

        // 획이 레이어 비트맵에 반영된 뒤 호출. 대기 시간 없이 즉시 한 번 확인함
        public static function rescanOutlineColorsAfterStrokeApplied():void
        {
            stopOutlineColorScanTimer();
            if (_cursor.visible)
            {
                clearOutlineColorStates(); // 그림이 바뀌었으므로 예전 분류는 버림
                startOutlineColorScanTimer();
            }
        }

        // 마우스를 움직일 때 호출. 점별 분류와 개수는 그대로 두고 탐색 위치도 이어서 돌림 (새로 본 점부터 개수가 바뀜)
        private static function startOutlineColorScanOnCursorMove():void
        {
            if (MouseState.isLeftDown || !_cursor.visible)
            {
                return;
            }
            startOutlineColorScanTimer();
        }

        private static function startOutlineColorScanTimer():void
        {
            isInvertSettled = false;
            if (!FOFOTimer.hasTimer(CHECK_TIMER_NAME))
            {
                FOFOTimer.addByName(CHECK_TIMER_NAME, 0, true, scanOutlineColorsWithinFrameBudget);
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

        // 프레임마다 FOFOTimer가 호출. 테두리 점을 SCAN_TIME_BUDGET_PER_FRAME_MS 안에서 이어서 돌며 센다.
        // 커서가 보이고 마우스를 누르지 않는 동안 true를 돌려줘 타이머가 유지됨. 숨겨지거나 눌리면 false로 타이머가 지워지고 다음 마우스 이동 때 다시 시작함
        private static function scanOutlineColorsWithinFrameBudget():Boolean
        {
            if (MouseState.isLeftDown || !_cursor.visible || outlinePointCount === 0)
            {
                return false;
            }
            if (isInvertSettled)
            {
                return true; // 반전을 마쳤으면 커서가 다시 움직일 때까지 타이머만 두고 바로 돌아옴
            }
            // 커서 로컬 -> 캔버스 좌표 행렬 (줌, 캔버스 회전, 미러, 커서 회전, 위치가 한 번에 반영됨)
            const canvasPanelInverseMatrix:Matrix = CanvasView.canvasPanel.transform.concatenatedMatrix;
            canvasPanelInverseMatrix.invert();
            cursorLocalToCanvasMatrix.copyFrom(_cursor.transform.concatenatedMatrix);
            cursorLocalToCanvasMatrix.concat(canvasPanelInverseMatrix);

            const isCursorInverted:Boolean = _cursor.isInverted;
            const scanStartTime:int = getTimer();
            var scannedPointCountInThisFrame:int = 0;
            while (true)
            {
                const pointLocalX:Number = outlineLocalXList[nextScanPointIndex];
                const pointLocalY:Number = outlineLocalYList[nextScanPointIndex];
                nextScanPointIndex = (nextScanPointIndex + 1 === outlinePointCount) ? 0 : nextScanPointIndex + 1;

                const canvasPixelX:int = Math.floor(cursorLocalToCanvasMatrix.a * pointLocalX + cursorLocalToCanvasMatrix.c * pointLocalY + cursorLocalToCanvasMatrix.tx);
                const canvasPixelY:int = Math.floor(cursorLocalToCanvasMatrix.b * pointLocalX + cursorLocalToCanvasMatrix.d * pointLocalY + cursorLocalToCanvasMatrix.ty);
                var pointColorState:int;
                if (canvasPixelX < 0 || canvasPixelY < 0 || canvasPixelX >= DrawCanvas.CANVAS_WIDTH || canvasPixelY >= DrawCanvas.CANVAS_HEIGHT)
                {
                    pointColorState = OUTLINE_COLOR_OUTSIDE_CANVAS; // 캔버스 밖 점은 읽지 않고 비율 계산에서도 뺌
                }
                else
                {
                    const canvasPixelLuminance:Number = Utils.getLuminance(compositeAt(canvasPixelX, canvasPixelY));
                    if (canvasPixelLuminance <= DARK_CURSOR_SIMILAR_MAX_LUMINANCE)
                    {
                        pointColorState = OUTLINE_COLOR_DARK;
                    }
                    else if (canvasPixelLuminance >= LIGHT_CURSOR_SIMILAR_MIN_LUMINANCE)
                    {
                        pointColorState = OUTLINE_COLOR_LIGHT;
                    }
                    else
                    {
                        pointColorState = OUTLINE_COLOR_MIDDLE;
                    }
                }
                updatePointColorStateAndCounts(nextScanPointIndex === 0 ? outlinePointCount - 1 : nextScanPointIndex - 1, pointColorState);

                // 아직 못 본 점도 모두 캔버스 안이라고 보고 센 최대 개수. 이 개수 기준으로 과반이 넘으면 나머지 점을 다 봐도 비율이 넘음
                const maxInsideCanvasPointCount:int = outlinePointCount - outsideCanvasPointCount;
                if (maxInsideCanvasPointCount === 0)
                {
                    return true; // 전부 캔버스 밖이어도 커서가 움직이면 바뀌므로 계속 돔
                }
                const similarPointCount:int = isCursorInverted ? lightPointCount : darkPointCount;
                if (similarPointCount >= INVERT_SIMILAR_OUTLINE_RATIO * maxInsideCanvasPointCount)
                {
                    _cursor.setInverted(!isCursorInverted);
                    isInvertSettled = true;
                    return true; // 타이머는 계속 돌지만, 커서가 다시 움직이기 전까지는 맨 앞에서 바로 돌아옴
                }
                ++scannedPointCountInThisFrame;
                if (scannedPointCountInThisFrame >= outlinePointCount || (scannedPointCountInThisFrame % SCAN_POINTS_PER_TIME_CHECK === 0 && getTimer() - scanStartTime >= SCAN_TIME_BUDGET_PER_FRAME_MS)) // 한 프레임에 한 바퀴를 넘게 돌지 않음
                {
                    return true;
                }
            }
            return false;
        }
    }
}
