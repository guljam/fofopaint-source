package Modules.Tools
{
    import Modules.PenSizePreviewCursor;
    import Modules.DrawEngine.StrokeBuffer;
    import Modules.UIEngine.HintController;
    import Modules.UIEngine.UITheme;

    // 펜/지우개 설정값(크기, 투명도, 모양, 손떨림 보정, 에어브러시, 샤프 라인)과 그 변경 함수
    // 현재 도구(ToolController)에 맞는 값을 바꾸고, 옵션 박스 표시는 ToolPanel에 맡김
    // 층: L1 데이터 - 펜·지우개 설정값(크기, 투명도, 모양 등)과 그 변경 함수
    public class PenSettings
    {
        public static var penAlpha:Number = 1.0;
        public static var penSize:uint = 3;
        public static var penIsSquare:Boolean = false;
        public static var penSizeList:Array = [0, 1, 2, 3, 4, 5, 7, 10, 13, 18, 30, 45, 80];
        public static var penAlphaList:Array = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0];
        public static var penSizeIndex:uint = 3;
        public static var penAlphaIndex:uint = 9;
        public static var penSmoothValue:Number = 0; // 펜 손떨방 플래그
        public static var penSmoothSlideValue:int = 0; // 펜 손떨방 플래그
        public static var penSmoothSlideTotal:Number = 20; // 손떨방 총 단계
        public static var penListShapeIsSqare:Boolean = false; // 펜 리스트에서 펜 모양 버튼 눌러줄때 툴이랑 상관없이 바꿔줌, 펜 미리보기 할때 필요
        public static var eraserSize:uint = 12;
        public static var eraserSizeIndex:uint = 8;
        public static var eraserIsSquare:Boolean = false;
        public static var eraserAlpha:Number = 1.0;
        public static var eraserAlphaIndex:uint = 9;
        public static var isEraserAirBrushON:Boolean = false;
        public static var airBrushSizeDrawMode:int = 0;

        public static var isSharpLineON:Boolean = false; // 0.5픽셀어긋나게 안하고 완전히 정확하게 할때씀
        public static var isPenAirBrushON:Boolean = false;

        // 채우기 펜 전용 크기. 에어브러시가 켜졌을 때 번짐(블러) 정도만 정함. 펜 크기(penSize)와는 따로 둠
        public static var fillPenSize:uint = 3;
        public static var fillPenSizeIndex:uint = 3;

        // 채우기 펜의 크기는 에어브러시가 켜져 있을때만 바꿀 수 있음 (진행 중에도 가능, 블러는 OK할 때 적용함)
        public static function isFillPenSizeChangeable():Boolean
        {
            return ToolController.isSelectedTool(ToolController.TOOL_FILLPEN) && isPenAirBrushON;
        }

        public static function showDrawToolHintSizeOpacity():void
        {
            var tooltype:String = "";
            var size:Number;
            var alpha:Number;

            if (ToolController.isSelectedTool(ToolController.TOOL_PEN))
            {
                tooltype = "Pen ";
                size = penSizeList[penSizeIndex];
                alpha = penAlphaList[penAlphaIndex];
            }
            else if (ToolController.isSelectedTool(ToolController.TOOL_LINE))
            {
                tooltype = "Line ";
                size = penSizeList[penSizeIndex];
                alpha = penAlphaList[penAlphaIndex];
            }
            else if (ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
            {
                tooltype = "Fill Pen ";
                size = (isPenAirBrushON) ? fillPenSize : 1;
                alpha = penAlphaList[penAlphaIndex];
            }
            else if (ToolController.isSelectedTool(ToolController.TOOL_ERASER))
            {
                tooltype = "Eraser ";
                size = penSizeList[eraserSizeIndex];
                alpha = penAlphaList[eraserAlphaIndex];
            }

            HintController.showMouseHintTemp(tooltype + size + "px, " + alpha * 100 + "%");
        }

        public static function applyDrawingToolAlpha(alpha:Number = 0.0):void
        {
            const index:int = penAlphaList.indexOf(alpha);
            const eraseFlag:Boolean = ToolController.isSelectedTool(ToolController.TOOL_ERASER);

            ToolPanel.updateOpacityCursorPos(index);

            if (eraseFlag === false)
            {
                penAlpha = alpha;
                penAlphaIndex = index;
            }
            else if (eraseFlag === true)
            {
                eraserAlpha = alpha;
                eraserAlphaIndex = index;
            }
        }

        public static function adjustDrawToolAlphaByShortcut(increase:Boolean):void
        {
            function setAlpha(alp:Number, size:uint):void
            {
                var index:Number = penAlphaList.indexOf(alp);
                const len:uint = penAlphaList.length - 1;

                if (increase)
                {
                    index++;

                    if (index > len)
                    {
                        index = len;
                    }
                }
                else
                {
                    index--;

                    if (index < 1)
                    {
                        index = 1;
                    }
                }

                applyDrawingToolAlpha(penAlphaList[index]);
                showDrawToolHintSizeOpacity();
            }
            ToolController.selectPenToolIfNotDrawingTool(true);

            if (ToolController.isSelectedToolPenOrLine() || ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
            {
                setAlpha(penAlpha, penSize);
            }
            else if (ToolController.isSelectedTool(ToolController.TOOL_ERASER))
            {
                setAlpha(eraserAlpha, eraserSize);
            }
        }

        public static function adjustDrawToolSizeByShortcut(increase:Boolean):void
        {
            if (ToolController.isSelectedTool(ToolController.TOOL_FILLPEN) && !isFillPenSizeChangeable())
            {
                return;
            }

            const len:uint = penSizeList.length - 1;

            function setSize(index:uint, alpha:Number):void
            {
                if (increase)
                {
                    index++;

                    if (index > len)
                    {
                        index = len;
                    }
                }
                else
                {
                    index--;

                    if (index < 1)
                    {
                        index = 1;
                    }
                }

                setDrawToolSize(index);
                showDrawToolHintSizeOpacity();

                PenSizePreviewCursor.updateSizeAndShape();
                PenSizePreviewCursor.updatePosAndVisibility();
            }

            ToolController.selectPenToolIfNotDrawingTool(true);

            if (ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
            {
                setSize(fillPenSizeIndex, penAlpha);

                if (isPenAirBrushON && fillPenSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = fillPenSize;
                }
            }
            else if (ToolController.isSelectedToolPenOrLine())
            {
                setSize(penSizeIndex, penAlpha);
                // 이거 get set함수로 변환
                if (isPenAirBrushON && penSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = penSize;
                }
            }
            else if (ToolController.isSelectedTool(ToolController.TOOL_ERASER))
            {
                setSize(eraserSizeIndex, eraserAlpha);

                if (isEraserAirBrushON && eraserSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = eraserSize;
                }
            }
        }

        public static function selectPenSizeButton(targetName:String):void
        {
            const numberOnly:String = targetName.substr(UITheme.NSIZE_BUTTON_PREFIX.length);
            const index:uint = parseInt(numberOnly);

            if (ToolController.isSelectedTool(ToolController.TOOL_FILLPEN) && !isFillPenSizeChangeable())
            {
                return;
            }

            setDrawToolSize(index);
            PenSizePreviewCursor.updateSizeAndShape();

            if (ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
            {
                if (isPenAirBrushON && fillPenSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = fillPenSize;
                }
            }
            else if (ToolController.isSelectedToolPenOrLine())
            {
                if (isPenAirBrushON && penSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = penSize;
                }
            }
            else if (ToolController.isSelectedTool(ToolController.TOOL_ERASER))
            {
                if (isEraserAirBrushON && eraserSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = eraserSize;
                }
            }
        }

        public static function setDrawToolSize(index:uint):void
        {
            const size:uint = penSizeList[index];

            if (ToolController.isSelectedToolPenOrLine())
            {
                penSize = size;
                penSizeIndex = index;
                PenSizePreviewCursor.updateCursorSize(penSize);
            }
            else if (ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
            {
                // 펜 크기는 건드리지 않음. 도구를 바꾸면 select*Tool이 원래 크기를 다시 적용함
                fillPenSize = size;
                fillPenSizeIndex = index;
            }
            else if (ToolController.isSelectedTool(ToolController.TOOL_ERASER))
            {
                eraserSize = size;
                eraserSizeIndex = index;
                PenSizePreviewCursor.updateCursorSize(eraserSize);
            }

            ToolPanel.movePenSizeCursor(index);
        }

        public static function selectPenShapeButton(shapeFlag:Boolean):void
        {
            penListShapeIsSqare = shapeFlag;

            if (ToolController.isSelectedToolPenOrLine())
            {
                if (penIsSquare !== shapeFlag)
                {
                    penIsSquare = shapeFlag;
                }
            }
            else if (ToolController.isSelectedTool(ToolController.TOOL_ERASER))
            {
                if (eraserIsSquare !== shapeFlag)
                {
                    eraserIsSquare = shapeFlag;
                }
            }

            ToolPanel.updatePenShapeSet(shapeFlag);
            PenSizePreviewCursor.updateSizeAndShape();
        }

        public static function toggleSharpLine(flag:Boolean):void
        {
            isSharpLineON = flag;
            ToolPanel.updateSharpLineButtons(flag);
            PenSizePreviewCursor.updateSizeAndShape();
        }

        public static function getSharpLinePosOffset(size:Number):Number
        {
            return (isSharpLineON) ? (size % 2.0 === 0) ? 0.0 : 0.5
                : (size % 2.0 === 0) ? 0.5 : 0.0;
        }

        public static function toggleSharpLineByShortcut():void
        {
            toggleSharpLine(!isSharpLineON);

            if (isSharpLineON)
            {
                HintController.showMouseHintTemp("Sharp line ON");
            }
            else
            {
                HintController.showMouseHintTemp("Sharp line OFF");
            }
        }

        public static function togglePenAirBrushButtonShortCut():void
        {
            isPenAirBrushON = !isPenAirBrushON;
            toggleAirBrushCheckBox(isPenAirBrushON, true);
            if (isPenAirBrushON)
                HintController.showMouseHintTemp("Pen Air brush ON");
            else
                HintController.showMouseHintTemp("Pen Air brush OFF");
        }

        public static function togglePenAirBrushButton(flag:Boolean):void
        {
            isPenAirBrushON = flag;
            toggleAirBrushCheckBox(flag, true);
        }

        public static function toggleAirBrushCheckBox(flag:Boolean, penFlag:Boolean):void
        {
            ToolPanel.updateAirBrushButtons(flag);

            if (flag)
            {
                if (penFlag)
                {
                    airBrushSizeDrawMode = (ToolController.isSelectedTool(ToolController.TOOL_FILLPEN)) ? fillPenSize : penSize;
                }
                else
                {
                    airBrushSizeDrawMode = eraserSize;
                }
                ToolPanel.setBlurShapeSet(true);
            }
            else if (airBrushSizeDrawMode !== 0)
            {
                airBrushSizeDrawMode = 0;
                StrokeBuffer.canvasDrawLayerChild.filters = [];
                ToolPanel.setBlurShapeSet(false);
            }
        }

        public static function toggleEraseAirBrushButtonShortCut():void
        {
            isEraserAirBrushON = !isEraserAirBrushON;
            toggleAirBrushCheckBox(isEraserAirBrushON, false);
            if (isEraserAirBrushON)
                HintController.showMouseHintTemp("Eraser Air brush ON");
            else
                HintController.showMouseHintTemp("Eraser Air brush OFF");
        }

        public static function toggleEraseAirBrushButton(flag:Boolean):void
        {
            isEraserAirBrushON = flag;
            toggleAirBrushCheckBox(flag, false);
        }

        public static function setDrawingToolOpacity(targetName:String):void
        {
            const number:String = targetName.substr(UITheme.ALPHA_BUTTON_PREFIX.length);
            const index:int = parseInt(number);
            applyDrawingToolAlpha(penAlphaList[index]);
        }
    }
}
