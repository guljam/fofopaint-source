package
{
    import Main;

    public class HintStrings
    {
        static private var _main:Main;
        static public function init(mainclass:Main):void
        {
            _main = mainclass;
        }
                            
        static private const hintsCaptureMode:Object =
            {
                "capOff": "Exit capture mode [esc / backspace / f1 / f7]",
                "capSave": "Save {getCaptureSaveHintString()} [ctrl+s / ctrl+;]",
                "capClipBoard": "Copy {getCaptureSaveHintString()} to clipboard [ctrl+c / ctrl+,]",
                "capTrans": "Background color ON/OFF",
                "capRotate": "Rotate canvas by 90°",
                "capFlip": "Flip image",
                "capLayer1VisibleButton": "Layer 1 visible ON/OFF",
                "capLayer2VisibleButton": "Layer 2 visible ON/OFF",
                "capStamp": "Stamp ON/OFF",
                "capStampFont": "Change stamp font",
                "rCanvasPanel": "Drag on the canvas to select an area — Reset the capture area [right-click]",
                "rCanvasDrawLayer": "Drag on the canvas to select an area — Reset the capture area [right-click]",
                "canvasPanel": "Drag on the canvas to select an area — Reset the capture area [right-click]",
                "canvasDrawLayer": "Drag on the canvas to select an area — Reset the capture area [right-click]"
            };

        static private const hints:Object =
            {
                // 드로우 모드
                "drawModeButton": "Switch to draw mode [f1 / f7 / esc / backspace]",
                "captureButton": "Capture mode [ctrl+c / ctrl+,]",
                "saveButton": "Save [ctrl+s] _Save as.. [shift+ctrl+s / right-click]",
                "timer": "Actual working time — Reset [click and hold]",
                "loadButton": "Load [ctrl+o]",
                "clipBoardButton": "Load clipboard image [ctrl+v / ctrl+m] — There are no copied images",
                "newFileButton": "New file [press and hold esc / backspace / delete]",
                "gridButton": "Grid — Reset [right-click]",
                "sideBarPositionButton": "Right sidebar",
                "sideBarPositionButton2": "Left sidebar",
                "sideBarOFFButton": "Turn sidebar OFF [tab / \\ (back slash)]",
                "sideBarOFFButton2": "Turn sidebar OFF [tab / \\ (back slash)]",
                "sideBarONButton": "Turn sidebar ON [tab / \\ (back slash)]",
                "sideBarONButton2": "Turn sidebar ON [tab / \\ (back slash)]",
                "topBarColorButton": "Change UI color",
                "dpiButton": "Current UI scale : {getUIScaleString()} — Change UI scale — Reset [right-click]",
                "newWindowCloseButton": "Close image view window [esc on window]",
                "newWindowButton": "Open image view window — Move window [drag on window] — Fit to image size [right-click on window]",
                "aboutButton": "About FOFO PAINT..",
                "updateButton": "Version {newVersionStr} released!",

                // 리플레이 모드
                "replayModeButton": "Switch to replay mode [f1 / f7]",
                "repCaptureButton": "Capture mode [ctrl+c / ctrl+m]",
                "playButton": "Play [enter / space / right-click on viewport]",
                "pauseButton": "Pause [enter / space / esc / backspace]",
                "replayPrev": "Prev step [left / z / .] — Prev frame [right-click / Shift + (left / z / .)]",
                "replayNext": "Next step [right / x / ,] — Next frame [right-click / Shift + (right / x / ,)]",
                "repNewFileButton": "New file from this image",
                "cutPrevDataButton": "Delete data before current frame",
                "superUndoButton": "Delete data after current frame",
                "replaySpeedSliderWrapper": "Adjust playback speed [(up, down) / (f, v) / (h, n)]",
                "replayZoomOutButton": "Zoom out — Reset [right-click]",
                "replayZoomInButton": "Zoom in — Reset [right-click]",
                "replayFitToWindowButton": "Fit Canvas to viewport ON/OFF [right-click on canvas]",
                "replayRotateButton": "Rotate {STRING_RIGHT_CLICK_TO_RESET}",
                "replayRepeatButton": "Repeat replay ON/OFF",
                "trackBar":"{getTrackBarHintString()}",

                // 그리드 슬라이더
                "gridSliderWrapper": "Grid {getGridGapHintString()} — {STRING_RIGHT_CLICK_TO_RESET}",
                "gridMoveLeftButton": "Move grid by 1 pixel — Repeat [click and hold], Reset [right-click]",
                "gridMoveRightButton": "Move grid by 1 pixel — Repeat [click and hold], Reset [right-click]",
                "gridMoveUpButton": "Move grid by 1 pixel — Repeat [click and hold], Reset [right-click]",
                "gridMoveDownButton": "Move grid by 1 pixel — Repeat [click and hold], Reset [right-click]",

                // 펜옵션
                "shapeCircle": "circle",
                "shapeRect": "Square",
                "penSmoothSliderWapper": "Pen smoothing {penSmoothSlideValue} / {penSmoothSlideTotal}",
                "alphaButton1": "{getOpacityButtonHintString(1)}",
                "alphaButton2": "{getOpacityButtonHintString(2)}",
                "alphaButton3": "{getOpacityButtonHintString(3)}",
                "alphaButton4": "{getOpacityButtonHintString(4)}",
                "alphaButton5": "{getOpacityButtonHintString(5)}",
                "alphaButton6": "{getOpacityButtonHintString(6)}",
                "alphaButton7": "{getOpacityButtonHintString(7)}",
                "alphaButton8": "{getOpacityButtonHintString(8)}",
                "alphaButton9": "{getOpacityButtonHintString(9)}",
                "alphaButton10": "{getOpacityButtonHintString(10)}",
                "nSizeButton1": "{getSizeButtonHintString(1)}",
                "nSizeButton2": "{getSizeButtonHintString(2)}",
                "nSizeButton3": "{getSizeButtonHintString(3)}",
                "nSizeButton4": "{getSizeButtonHintString(4)}",
                "nSizeButton5": "{getSizeButtonHintString(5)}",
                "nSizeButton6": "{getSizeButtonHintString(6)}",
                "nSizeButton7": "{getSizeButtonHintString(7)}",
                "nSizeButton8": "{getSizeButtonHintString(8)}",
                "nSizeButton9": "{getSizeButtonHintString(9)}",
                "nSizeButton10": "{getSizeButtonHintString(10)}",
                "nSizeButton11": "{getSizeButtonHintString(11)}",
                "nSizeButton12": "{getSizeButtonHintString(12)}",

                "sharpLineButtonWrapper": "Sharp line [3 / 8]",
                "sharpLineOFFButton": "Sharp line [3 / 8]",
                "sharpLineONButton": "Sharp line [3 / 8]",
                "sharpLineText": "Sharp line [3 / 8]",
                "airBrushButtonWrapper": "Air brush [4 / 7]",
                "airBrushOFFButton": "Air brush [4 / 7]",
                "airBrushONButton": "Air brush [4 / 7]",
                "airBrushText": "Air brush [4 / 7]",

                "layer1SelectButton": "Select layer 1 [1 / 9] Show only layer 1 ON/OFF [click x 2]",
                "layer2SelectButton": "Select layer 2 [2 / 0] Show only layer 2 ON/OFF [click x 2]",
                "layer1CheckedButton": "Check layer 1 (for move image tool, lasso tool, merge into reference layer)",
                "layer1UncheckedButton": "Check layer 1 (for move image tool, lasso tool, merge into reference layer)",
                "layer2CheckedButton": "Check layer 2 (for move image tool, lasso tool, merge into reference layer)",
                "layer2UncheckedButton": "Check layer 2 (for move image tool, lasso tool, merge into reference layer)",
                "layerSwapButton": "Swap layers",
                "layerMergeButton": "Merge image into layer 2",

                // 툴박스 2
                "toolQuickSidebar": "[6 / s+d / j+k]",
                "toolPen": "Pen [q / o key up]",
                "toolFillPen": "Fill pen [q / o]",
                "toolErase": "Eraser [d / j]",
                "toolLasso": "Lasso [r / y]",
                "toolEyedropper": "Eye dropper [c /m]",
                "toolUndo": "Undo [z / .] — Continue [click and hold]",
                "toolRedo": "Redo [x / ,] — Continue [click and hold]",
                "toolMirror": "Flip canvas [a / l]",
                "toolLine": "Line [shift]",
                "toolMove": "Move image [e / u]",
                "toolZoom": "Zoom canvas [w / i]",
                "toolZoomIn": "Zoom-in canvas — {STRING_RIGHT_CLICK_TO_RESET}",
                "toolZoomOut": "Zoom-out canvas — {STRING_RIGHT_CLICK_TO_RESET}",
                "toolRotate": "Rotate canvas [s / k] — {STRING_RIGHT_CLICK_TO_RESET}",
                "toolRotate2": "Rotate canvas [s / k]",
                "toolRefLayer": "Reference layer [t]",
                "sideBarScrollBar": "Scroll [drag / mouse wheel on sidebar] — {STRING_RIGHT_CLICK_TO_RESET}",

                "toolFillPenOK": "OK [right-click / enter / (q , o) key up)",
                "toolFillPenCancel": "Cancel [esc]",

                // 컬러 픽커
                "hueColor": "Hue",
                "svBox": "Situation and Value",
                "swapPositionButton": "Swap palette position",
                "colorHistoryBox": "Color history — Move color to my palette [drag]",
                "myPaletteBox": "Add, remove, restore color [click hold] — Swap color position [drag]",
                "rgbInfoText": "Adjust value — Change color model [click {getRGBorHSVString()} part]",
                "paperColorButton": "Change background color",
                "penColorButton": "Change pen color",
                "currentColor": "{getCurrentColorHintString()}",
                "transColorButton": "Transparent color ON/OFF [c+space / m+space]",
                "myPaletteButton": "My palette — Expand palette ON/OFF [click x 2] — Clear palette [click and hold]",
                "drawrPresetButton": "Drawr color preset — Clear scratch pad [click and hold]",
                "tegakiPresetButton": "Tegaki color preset — Clear scratch pad [click and hold]",
                "scratchPad": "Scratch pad — Draw [drag] — Select color [click / c /  m]",

                // 캔버스 네비게이터
                "navStageBG": "Canvas Navigator",
                "navBitmapBG": "Canvas Navigator",
                "navCursor": "Canvas Navigator",
                "navLayer1Bitmap": "Canvas Navigator",
                "navLayer2Bitmap": "Canvas Navigator"
            };

        static public function getCaptureSaveHintString():String
        {
            return (_main.captureAreaManager.isFullImageCapture()) ? "image":"selected area";
        }

        static public function getUIScaleString():String
        {
            return Global.getUIScaleString();
        }

        static public function getTrackBarHintString():String
        {
            if(_main.isReplayRestartTimerON())
            {
                return "Seek bar — Cancel restart [click]";
            }
            return "Seek bar";
        }

        static public function getGridGapHintString():String
        {
            return _main.gridGapValue+_main.GRID_GAP +"px";
        }

        static public function getOpacityButtonHintString(index:int):String
        {
            return "Opacity "+(_main.penAlphaList[index]*100)+"% [g / b]";
        }

        static public function getSizeButtonHintString(index:int):String
        {
            return "Size "+_main.penSizeList[index]+ "px [(f, v) / (h, n)]";
        }

        static public function getCurrentColorHintString():String
        {
            const pickedColor:uint = _main.colorPickerBox.getRGBInfoBGColor();
            const arr:Vector.<Number> = (_main.isHSVInfoTextMode) ? Global.HEXtoHSV(pickedColor,_main.hsvColorData[0]) : Global.HEXtoRGB(pickedColor);
            const mode:String = (_main.isHSVInfoTextMode) ? "HSV" : "RGB";

            return "Current color : " + mode +" " + arr[0] + "," + arr[1] + "," + arr[2];
        }

        static public function resolveTemplate(template:String):String
        {
            return template.replace(/\{([^\}]+)\}/g, function(...args):String
                {
                    var expr:String = args[1]; // {} 안의 전체 내용
                    var value:*;

                    // 함수 호출 패턴 {func(arg1,arg2,...)}
                    var fnMatch:Array = expr.match(/^(\w+)\((.*)\)$/);
                    if (fnMatch)
                    {
                        var fnName:String = fnMatch[1];
                        var rawArgs:String = fnMatch[2];
                        var argList:Array = [];

                        if (rawArgs.length > 0)
                        {
                            var parts:Array = rawArgs.split(",");
                            for each (var p:String in parts)
                            {
                                p = p.replace(/^\s+|\s+$/g, ""); // trim
                                if (!isNaN(Number(p)))
                                    argList.push(Number(p));
                                else if (p == "true" || p == "false")
                                    argList.push(p == "true");
                                else
                                    argList.push(p.replace(/^['"]|['"]$/g, "")); // 문자열
                            }
                        }

                        if (HintStrings[fnName] && HintStrings[fnName] is Function)
                        {
                            value = HintStrings[fnName].apply(HintStrings, argList);
                        }
                        else
                        {
                            value = "{" + expr + "}";
                        }
                    }
                    else
                    {
                        // 변수 치환 {varName}
                        if (_main.hasOwnProperty(expr))
                        {
                            // 함수여도 ()가 없으면 실행하지 않고 함수 객체를 문자열로 표시
                            value = _main[expr];
                        }
                        else
                        {
                            value = "{" + expr + "}";
                        }
                    }

                    return value != null ? value.toString() : "";
                });
        }

        static public function getHintFromTargetNameCaptureMode(targetName:String):String
        {
            if (_main === null || !hintsCaptureMode.hasOwnProperty(targetName))
            {
                return null;
            }

            return resolveTemplate(hintsCaptureMode[targetName]);
        }

        static public function getHintFromTargetName(targetName:String):String
        {
            if (_main === null || !hints.hasOwnProperty(targetName))
            {
                return null;
            }

            return resolveTemplate(hints[targetName]);
        }
    }
}
