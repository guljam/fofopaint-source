package
{
    import Main;

    public class HintStrings
    {
        static private var m:Main;
        static public function init(mainclass:Main):void
        {
            m = mainclass;
        }

        static private const hints:Object =
            {
                // 드로우 모드
                "drawModeButton": "Switch to draw mode [f1, f7]",
                "captureButton": "Capture mode [ctrl+c, ctrl+,]",
                "saveButton": "Save [ctrl+s] _Save as.. [shift+ctrl+s, right-click]",
                "timer": "Actual working time _ Reset [click] {STRING_PRESS_HOLD}",
                "loadButton": "Load [ctrl+o]",
                "clipBoardButton": "Load clipboard image [ctrl+v, ctrl+m] _ There are no copied images",
                "newFileButton": "New file [click, esc, backspace, delete] {STRING_PRESS_HOLD}",
                "gridButton": "Grid [f2, f8] _ Reset [right-click, while holding Shift: f2, f8]",
                "sideBarPositionButton": "Right sidebar [f3]",
                "sideBarPositionButton2": "Left sidebar [f3]",
                "sideBarOFFButton": "Turn sidebar OFF [tab, \\  ]",
                "sideBarOFFButton2": "Turn sidebar OFF [tab, \\ ]",
                "sideBarONButton": "Turn sidebar ON [tab, \\ ]",
                "sideBarONButton2": "Turn sidebar ON [tab, \\ ]",
                "topBarColorButton": "Change UI color [f4]",
                "dpiButton": "Current UI scale : {getUIScaleString()} _ Change UI scale [f5] _ Reset [right-click, shift+F5]",
                "newWindowCloseButton": "Close image view window [esc on window]",
                "newWindowButton": "Open image view window [f6] _ Move window [drag on window] _ Fit to image size [right-click on window]",
                "aboutButton": "About FOFO PAINT..",
                "updateButton": "Version {newVersionStr} released!",

                // 리플레이 모드
                "replayModeButton": "Switch to replay mode [f1, f7]",
                "repSaveButton": "Save [ctrl+s] _ Save as.. [shift+ctrl+s, right-click]",
                "repLoadButton": "Load [ctrl+o]",
                "repCaptureButton": "Capture mode [ctrl+c, ctrl+m]",
                "playButton": "Play [enter, space]",
                "pauseButton": "Pause [enter, space]",
                "replayPrev": "Prev step [left, z, .] _ Prev frame [right-click, while holding Shift: left, z, .]",
                "replayNext": "Next step [right, x, ,] _ Next frame [right-click, while holding Shift: left, z, .]",
                "reRecordingButton": "New file from this image [click, f2]  {STRING_PRESS_HOLD}",
                "cutPrevDataButton": "Delete data before current frame [click, f3]  {STRING_PRESS_HOLD}",
                "superUndoButton": "Delete data after current frame [click, f4]  {STRING_PRESS_HOLD}",
                "replaySpeedSliderWrapper": "Change playback speed [up, down / f, v / h, n]",
                "replayZoomOutButton": "Zoom out [f5] _ Reset [right-click, while holding Shift: f5, f6]",
                "replayZoomInButton": "Zoom in [f6] _ Reset [right-click, while holding Shift: f5, f6]",
                "replayFitToWindowButton": "Canvas center alignment ON/OFF [right-click on canvas]",
                "replayRotateButton": "Rotate {STRING_RIGHT_CLICK_TO_RESET}",
                "replayRepeatButton": "Repeat replay ON/OFF",

                // 캡쳐 모드
                "capOff": "Exit capture mode (esc, backspace, f1, f7]",
                "capSave": "Save {getCaptureSaveHint()} [ctrl+s, ctrl+;]",
                "capClipBoard": "Copy {getCaptureSaveHint()} to clipboard [ctrl+c, ctrl+,]",
                "capTrans": "Background color ON/OFF [d, j]",
                "capRotate": "Rotate canvas by 90° [s, k]",
                "capFlip": "Flip image [a, l]",
                "capLayer1VisibleButton": "Layer 1 visible ON/OFF [1, 9]",
                "capLayer2VisibleButton": "Layer 2 visible ON/OFF [2, 0]",
                "capStamp": "Stamp ON/OFF [f, h]",
                "capStampFont": "Change stamp font",

                // 그리드 슬라이더
                "gridSliderWrapper": "Grid {getGridGapHint()} _ {STRING_RIGHT_CLICK_TO_RESET}",
                "gridMoveLeftButton": "Move grid by 1 pixel _ Repeat [hold-click], Reset [right-click]",
                "gridMoveRightButton": "Move grid by 1 pixel _ Repeat [hold-click], Reset [right-click]",
                "gridMoveUpButton": "Move grid by 1 pixel _ Repeat [hold-click], Reset [right-click]",
                "gridMoveDownButton": "Move grid by 1 pixel _ Repeat [hold-click], Reset [right-click]",

                // 펜옵션
                "shapeCircle": "circle",
                "shapeRect": "Square",
                "penSmoothSliderWapper": "Pen smoothing {penSmoothSlideValue} / {penSmoothSlideTotal}",
                "alphaButton1": "{getOpacityButtonHint(1)}",
                "alphaButton2": "{getOpacityButtonHint(2)}",
                "alphaButton3": "{getOpacityButtonHint(3)}",
                "alphaButton4": "{getOpacityButtonHint(4)}",
                "alphaButton5": "{getOpacityButtonHint(5)}",
                "alphaButton6": "{getOpacityButtonHint(6)}",
                "alphaButton7": "{getOpacityButtonHint(7)}",
                "alphaButton8": "{getOpacityButtonHint(8)}",
                "alphaButton9": "{getOpacityButtonHint(9)}",
                "alphaButton10": "{getOpacityButtonHint(10)}",
                "nSizeButton1": "{getSizeButtonHint(1)}",
                "nSizeButton2": "{getSizeButtonHint(2)}",
                "nSizeButton3": "{getSizeButtonHint(3)}",
                "nSizeButton4": "{getSizeButtonHint(4)}",
                "nSizeButton5": "{getSizeButtonHint(5)}",
                "nSizeButton6": "{getSizeButtonHint(6)}",
                "nSizeButton7": "{getSizeButtonHint(7)}",
                "nSizeButton8": "{getSizeButtonHint(8)}",
                "nSizeButton9": "{getSizeButtonHint(9)}",
                "nSizeButton10": "{getSizeButtonHint(10)}",
                "nSizeButton11": "{getSizeButtonHint(11)}",
                "nSizeButton12": "{getSizeButtonHint(12)}",

                "sharpLineButtonWrapper": "Sharp line [3, 8]",
                "sharpLineOFFButton": "Sharp line [3, 8]",
                "sharpLineONButton": "Sharp line [3, 8]",
                "sharpLineText": "Sharp line [3, 8]",
                "airBrushButtonWrapper": "Air brush [4, 7]",
                "airBrushOFFButton": "Air brush [4, 7]",
                "airBrushONButton": "Air brush [4, 7]",
                "airBrushText": "Air brush [4, 7]",

                "layer1SelectButton": "Select layer 1 [1, 9] Show only layer 1 ON/OFF [click x 2]",
                "layer2SelectButton": "Select layer 2 [2, 0] Show only layer 2 ON/OFF [click x 2]",
                "layer1CheckedButton": "Check layer 1 [1+w, 9+i] (for move image tool, lasso tool, reference layer)",
                "layer1UncheckedButton": "Check layer 1 [1+w, 9+i] (for move image tool, lasso tool, reference layer)",
                "layer2CheckedButton": "Check layer 2 [2+w, 0+i] (for move image tool, lasso tool, reference layer)",
                "layer2UncheckedButton": "Check layer 2 [2+w, 0+i] (for move image tool, lasso tool, reference layer)",
                "layerSwapButton": "Swap layers [shift+d, shift+j]",
                "layerMergeButton": "Merge image into layer 2 [shift+e, shift+o]",

                // 툴박스 2
                "toolQuickSidebar": "[6, s+d, j+k]",
                "toolPen": "Pen [q , o key up]",
                "toolFillPen": "Fill pen [q, o]",
                "toolErase": "Eraser [d, j]",
                "toolLasso": "Lasso [r, y]",
                "toolEyedropper": "Eye dropper [c, m]",
                "toolUndo": "Undo [z, .]",
                "toolRedo": "Redo [x, ,]",
                "toolMirror": "Flip canvas [a, l]",
                "toolLine": "Line [shift]",
                "toolMove": "Move image [e, u]",
                "toolZoom": "Zoom canvas [w, i]",
                "toolZoomIn": "Zoom-in canvas _ {STRING_RIGHT_CLICK_TO_RESET}",
                "toolZoomOut": "Zoom-out canvas _ {STRING_RIGHT_CLICK_TO_RESET}",
                "toolRotate": "Rotate canvas [s, k] _ {STRING_RIGHT_CLICK_TO_RESET}",
                "toolRotate2": "Rotate canvas [s, k]",
                "toolRefLayer": "Reference layer [t]",
                "sideBarScrollBar":"Scroll [drag, mouse wheel on sidebar] _ {STRING_RIGHT_CLICK_TO_RESET}",

                "toolFillPenOK" : "OK [right-click, enter, q / o key up)",
                "toolFillPenCancel" : "Cancel [esc]",
                
                //컬러 픽커
                "hueColor": "Hue",
                "svBox": "Situation and Value",
                "swapPositionButton": "Swap palette position [click]",
                "historyBox": "Move color to my palette [drag]",
                "myPaletteBox": "Add, remove, restore color [hold click] _ Swap color position [drag]",
                "rgbInfoText": "Change value [click] _ Change color model [click {getRGBorHSVString()} text]",
                "paperColorButton": "Change background color",
                "penColorButton": "Change pen color",
                "currentColor":"{getCurrentColorHint()}",
                "transColorButton": "Transparent color ON/OFF [c+space, m+space]",
                "myPaletteButton": "My palette _ Expand palette ON/OFF [click x 2] _ Clear palette [click] {STRING_PRESS_HOLD}",
                "drawrPresetButton": "Drawr color preset _ Clear scratch pad [click] {STRING_PRESS_HOLD}",
                "tegakiPresetButton": "Tegaki color preset _ Clear scratch pad [click] {STRING_PRESS_HOLD}",
                "scratchPad": "Scratch pad _ Draw [drag] _ Select color [c, m, click]",

                //캔버스 네비게이터
                "navStageBG":"Canvas Navigator",
                "navBitmapBG":"Canvas Navigator",
                "navCursor":"Canvas Navigator",
                "navLayer1Bitmap":"Canvas Navigator",
                "navLayer2Bitmap":"Canvas Navigator"
            };

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

                        if (m.hasOwnProperty(fnName) && m[fnName] is Function)
                        {
                            value = m[fnName].apply(m, argList);
                        }
                        else
                        {
                            value = "{" + expr + "}";
                        }
                    }
                    else
                    {
                        // 변수 치환 {varName}
                        if (m.hasOwnProperty(expr))
                        {
                            // 함수여도 ()가 없으면 실행하지 않고 함수 객체를 문자열로 표시
                            value = m[expr];
                        }
                        else
                        {
                            value = "{" + expr + "}";
                        }
                    }

                    return value != null ? value.toString() : "";
                });
        }

        static public function getHintFromTargetName(targetName:String):String
        {
            if (m === null || !hints.hasOwnProperty(targetName))
            {
                return null;
            }

            return resolveTemplate(hints[targetName]);
        }
    }
}
