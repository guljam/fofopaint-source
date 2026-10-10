package Modules.L1Data.Tools
{
    import Modules.L1Data.ToolState;
    import Modules.L1Data.UIEngine.UITheme;

    // 펜/지우개 설정값(크기, 투명도, 모양, 손떨림 보정, 에어브러시, 샤프 라인)과 그 변경 함수
    // 현재 도구(ToolController)에 맞는 값을 바꾸고, 옵션 박스 표시는 ToolPanel에 맡김
    // 층: L1 데이터 - 펜·지우개 설정값(크기, 투명도, 모양 등)과 그 변경 함수
    public class PenSettings
    {
        // 마우스 옆에 임시 힌트 문구를 보여달라는 보고 (인자: 문구)
        public static var onMouseHintTempFunc:Function;
        // 그리기 도구 투명도를 적용했다는 보고 (인자: 투명도 인덱스)
        public static var onAlphaAppliedFunc:Function;
        // 그리기 도구 크기를 적용했다는 보고 (인자: 크기 인덱스)
        public static var onSizeIndexAppliedFunc:Function;
        // 펜 모양(사각/원) 버튼을 골랐다는 보고 (인자: 사각 여부)
        public static var onShapeSelectedFunc:Function;
        // 샤프 라인을 켜거나 껐다는 보고 (인자: 켬 여부)
        public static var onSharpLineToggledFunc:Function;
        // 에어브러시 체크박스를 켜거나 껐다는 보고 (인자: 켬 여부)
        public static var onAirBrushToggledFunc:Function;
        // 블러 모양 표시를 바꿔야 한다는 보고 (인자: 블러 여부)
        public static var onBlurShapeSetFunc:Function;
        // 그리기 임시 레이어의 필터를 비워야 한다는 보고
        public static var onDrawLayerFilterClearedFunc:Function;
        // 펜 크기 미리보기 커서의 크기와 모양을 다시 맞춰야 한다는 보고
        public static var onCursorShapeChangedFunc:Function;
        // 펜 크기 미리보기 커서의 위치와 보임 여부를 다시 맞춰야 한다는 보고
        public static var onCursorPosChangedFunc:Function;
        // 펜 크기 미리보기 커서의 크기를 바꿔야 한다는 보고 (인자: 크기)
        public static var onCursorSizeChangedFunc:Function;
        // 그리는 툴이 아니면 펜 툴로 바꿔야 한다는 보고 (인자: 지우개도 그리는 툴로 볼지)
        public static var onPenToolNeededFunc:Function;

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
            return ToolState.isSelectedTool(ToolState.TOOL_FILLPEN) && isPenAirBrushON;
        }

        // 지금 도구의 이름, 크기, 투명도를 마우스 옆 임시 힌트로 보여줌
        public static function showDrawToolHintSizeOpacity():void
        {
            var tooltype:String = "";
            var size:Number;
            var alpha:Number;

            if (ToolState.isSelectedTool(ToolState.TOOL_PEN))
            {
                tooltype = "Pen ";
                size = penSizeList[penSizeIndex];
                alpha = penAlphaList[penAlphaIndex];
            }
            else if (ToolState.isSelectedTool(ToolState.TOOL_LINE))
            {
                tooltype = "Line ";
                size = penSizeList[penSizeIndex];
                alpha = penAlphaList[penAlphaIndex];
            }
            else if (ToolState.isSelectedTool(ToolState.TOOL_FILLPEN))
            {
                tooltype = "Fill Pen ";
                size = (isPenAirBrushON) ? fillPenSize : 1;
                alpha = penAlphaList[penAlphaIndex];
            }
            else if (ToolState.isSelectedTool(ToolState.TOOL_ERASER))
            {
                tooltype = "Eraser ";
                size = penSizeList[eraserSizeIndex];
                alpha = penAlphaList[eraserAlphaIndex];
            }

            if (onMouseHintTempFunc != null) onMouseHintTempFunc(tooltype + size + "px, " + alpha * 100 + "%");
        }

        // 현재 도구(펜/지우개)에 투명도를 적용하고 투명도 커서 위치를 맞춤
        public static function applyDrawingToolAlpha(alpha:Number = 0.0):void
        {
            const index:int = penAlphaList.indexOf(alpha);
            const eraseFlag:Boolean = ToolState.isSelectedTool(ToolState.TOOL_ERASER);

            if (onAlphaAppliedFunc != null) onAlphaAppliedFunc(index);

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

        // 단축키로 투명도를 한 단계 올리거나 내림 (그리는 도구가 아니면 펜으로 바꿈)
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
            if (onPenToolNeededFunc != null) onPenToolNeededFunc(true);

            if (ToolState.isSelectedToolPenOrLine() || ToolState.isSelectedTool(ToolState.TOOL_FILLPEN))
            {
                setAlpha(penAlpha, penSize);
            }
            else if (ToolState.isSelectedTool(ToolState.TOOL_ERASER))
            {
                setAlpha(eraserAlpha, eraserSize);
            }
        }

        // 단축키로 크기를 한 단계 올리거나 내림 (그리는 도구가 아니면 펜으로 바꿈)
        public static function adjustDrawToolSizeByShortcut(increase:Boolean):void
        {
            if (ToolState.isSelectedTool(ToolState.TOOL_FILLPEN) && !isFillPenSizeChangeable())
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

                if (onCursorShapeChangedFunc != null) onCursorShapeChangedFunc();
                if (onCursorPosChangedFunc != null) onCursorPosChangedFunc();
            }

            if (onPenToolNeededFunc != null) onPenToolNeededFunc(true);

            if (ToolState.isSelectedTool(ToolState.TOOL_FILLPEN))
            {
                setSize(fillPenSizeIndex, penAlpha);

                if (isPenAirBrushON && fillPenSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = fillPenSize;
                }
            }
            else if (ToolState.isSelectedToolPenOrLine())
            {
                setSize(penSizeIndex, penAlpha);
                // 이거 get set함수로 변환
                if (isPenAirBrushON && penSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = penSize;
                }
            }
            else if (ToolState.isSelectedTool(ToolState.TOOL_ERASER))
            {
                setSize(eraserSizeIndex, eraserAlpha);

                if (isEraserAirBrushON && eraserSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = eraserSize;
                }
            }
        }

        // 크기 버튼(이름 끝 번호)을 눌러 크기를 정함
        public static function selectPenSizeButton(targetName:String):void
        {
            const numberOnly:String = targetName.substr(UITheme.NSIZE_BUTTON_PREFIX.length);
            const index:uint = parseInt(numberOnly);

            if (ToolState.isSelectedTool(ToolState.TOOL_FILLPEN) && !isFillPenSizeChangeable())
            {
                return;
            }

            setDrawToolSize(index);
            if (onCursorShapeChangedFunc != null) onCursorShapeChangedFunc();

            if (ToolState.isSelectedTool(ToolState.TOOL_FILLPEN))
            {
                if (isPenAirBrushON && fillPenSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = fillPenSize;
                }
            }
            else if (ToolState.isSelectedToolPenOrLine())
            {
                if (isPenAirBrushON && penSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = penSize;
                }
            }
            else if (ToolState.isSelectedTool(ToolState.TOOL_ERASER))
            {
                if (isEraserAirBrushON && eraserSize !== airBrushSizeDrawMode)
                {
                    airBrushSizeDrawMode = eraserSize;
                }
            }
        }

        // 현재 도구의 크기를 인덱스로 정하고 크기 커서를 옮김
        public static function setDrawToolSize(index:uint):void
        {
            const size:uint = penSizeList[index];

            if (ToolState.isSelectedToolPenOrLine())
            {
                penSize = size;
                penSizeIndex = index;
                if (onCursorSizeChangedFunc != null) onCursorSizeChangedFunc(penSize);
            }
            else if (ToolState.isSelectedTool(ToolState.TOOL_FILLPEN))
            {
                // 펜 크기는 건드리지 않음. 도구를 바꾸면 select*Tool이 원래 크기를 다시 적용함
                fillPenSize = size;
                fillPenSizeIndex = index;
            }
            else if (ToolState.isSelectedTool(ToolState.TOOL_ERASER))
            {
                eraserSize = size;
                eraserSizeIndex = index;
                if (onCursorSizeChangedFunc != null) onCursorSizeChangedFunc(eraserSize);
            }

            if (onSizeIndexAppliedFunc != null) onSizeIndexAppliedFunc(index);
        }

        // 펜/지우개 모양(사각 여부)을 정함
        public static function selectPenShapeButton(shapeFlag:Boolean):void
        {
            penListShapeIsSqare = shapeFlag;

            if (ToolState.isSelectedToolPenOrLine())
            {
                if (penIsSquare !== shapeFlag)
                {
                    penIsSquare = shapeFlag;
                }
            }
            else if (ToolState.isSelectedTool(ToolState.TOOL_ERASER))
            {
                if (eraserIsSquare !== shapeFlag)
                {
                    eraserIsSquare = shapeFlag;
                }
            }

            if (onShapeSelectedFunc != null) onShapeSelectedFunc(shapeFlag);
            if (onCursorShapeChangedFunc != null) onCursorShapeChangedFunc();
        }

        // 샤프 라인을 켜거나 끔
        public static function toggleSharpLine(flag:Boolean):void
        {
            isSharpLineON = flag;
            if (onSharpLineToggledFunc != null) onSharpLineToggledFunc(flag);
            if (onCursorShapeChangedFunc != null) onCursorShapeChangedFunc();
        }

        public static function getSharpLinePosOffset(size:Number):Number
        {
            return (isSharpLineON) ? (size % 2.0 === 0) ? 0.0 : 0.5
                : (size % 2.0 === 0) ? 0.5 : 0.0;
        }

        // 단축키로 샤프 라인을 켜고 끄며 힌트를 보여줌
        public static function toggleSharpLineByShortcut():void
        {
            toggleSharpLine(!isSharpLineON);

            if (isSharpLineON)
            {
                if (onMouseHintTempFunc != null) onMouseHintTempFunc("Sharp line ON");
            }
            else
            {
                if (onMouseHintTempFunc != null) onMouseHintTempFunc("Sharp line OFF");
            }
        }

        // 단축키로 펜 에어브러시를 켜고 끄며 힌트를 보여줌
        public static function togglePenAirBrushButtonShortCut():void
        {
            isPenAirBrushON = !isPenAirBrushON;
            toggleAirBrushCheckBox(isPenAirBrushON, true);
            if (isPenAirBrushON)
            {
                if (onMouseHintTempFunc != null) onMouseHintTempFunc("Pen Air brush ON");
            }
            else
            {
                if (onMouseHintTempFunc != null) onMouseHintTempFunc("Pen Air brush OFF");
            }
        }

        public static function togglePenAirBrushButton(flag:Boolean):void
        {
            isPenAirBrushON = flag;
            toggleAirBrushCheckBox(flag, true);
        }

        // 에어브러시 체크박스를 켜거나 끄고 블러 크기를 정함
        public static function toggleAirBrushCheckBox(flag:Boolean, penFlag:Boolean):void
        {
            if (onAirBrushToggledFunc != null) onAirBrushToggledFunc(flag);

            if (flag)
            {
                if (penFlag)
                {
                    airBrushSizeDrawMode = (ToolState.isSelectedTool(ToolState.TOOL_FILLPEN)) ? fillPenSize : penSize;
                }
                else
                {
                    airBrushSizeDrawMode = eraserSize;
                }
                if (onBlurShapeSetFunc != null) onBlurShapeSetFunc(true);
            }
            else if (airBrushSizeDrawMode !== 0)
            {
                airBrushSizeDrawMode = 0;
                if (onDrawLayerFilterClearedFunc != null) onDrawLayerFilterClearedFunc();
                if (onBlurShapeSetFunc != null) onBlurShapeSetFunc(false);
            }
        }

        // 단축키로 지우개 에어브러시를 켜고 끄며 힌트를 보여줌
        public static function toggleEraseAirBrushButtonShortCut():void
        {
            isEraserAirBrushON = !isEraserAirBrushON;
            toggleAirBrushCheckBox(isEraserAirBrushON, false);
            if (isEraserAirBrushON)
            {
                if (onMouseHintTempFunc != null) onMouseHintTempFunc("Eraser Air brush ON");
            }
            else
            {
                if (onMouseHintTempFunc != null) onMouseHintTempFunc("Eraser Air brush OFF");
            }
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

		// 에어브러시 크기(size)에 맞는 블러 크기를 2~30 범위로 계산함 (z는 배율)
		public static function getBlurSize(size:Number, z:Number):Number
		{
			var blurSize:Number = size / 2;
			if (blurSize <= 2)
				blurSize = 2;
			else if (blurSize > 30)
				blurSize = 30;
			return blurSize * z;
		}


		// 에어브러시 크기에 맞는 갱신 영역(클립 사각형) 여백을 계산함
		public static function getClipRectOffsetAirBrush(size:int):Number
		{
			const len:uint = PenSettings.penSizeList.length;
			for (var i:uint = 1;i < len;i++)
			{
				if (PenSettings.penSizeList[i] === size)
				{
					return size + airBrushClipRectOffsetData[i];
				}
			}
			return 0;
		}


		public static var airBrushClipRectOffsetData:Array = [0, 4, 2, 2, 0, 0, 0, -2, -5, -5, -10, -16, -43];


		public static var isTransparentPenColor:Boolean = false; // 펜 컬러 투명 켜졌을때 올려줌

    }
}
