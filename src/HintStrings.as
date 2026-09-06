package
{
    import Main;
    import main_module.CanvasGridOverlay;
    import main_module.tools.PenTool;
    import main_module.AppUpdater;
    import main_module.ColorPickerController;

    public class HintStrings
    {
        static private var _main:Main;
        static public function init(mainclass:Main):void
        {
            _main = mainclass;
            initSizeAndAlphaButtonHintString();
        }

        static public const STRING_MERGE_INTO_REFLAYER:String = "Merge into reference layer";
        static public const STRING_REFLAYER_IMAGE_OPACITY:String = "Image opacity ";
        static public const STRING_RIGHT_CLICK_TO_RESET:String = "Right-click to reset";
        static public const STRING_VARIBALE_HINT:String = "!";

        static private const hintsCaptureMode:Object =
            {
                "capOff": "Exit capture mode [esc / backspace / f1 / f7]",
                "capSave": STRING_VARIBALE_HINT,
                "capClipBoard": STRING_VARIBALE_HINT,
                "capTrans": "Toggle background color",
                "capRotate": "Rotate canvas by 90°",
                "capFlip": "Flip image",
                "capLayer1VisibleButton": "Show / Hide Layer 1",
                "capLayer2VisibleButton": "Show / Hide Layer 2",
                "capStamp": "Toggle stamp",
                "capStampFont": "Change stamp font",
                "rCanvasPanel": "Drag to select area _ Right-click to reset area",
                "rCanvasDrawLayer": "Drag to select area _ Right-click to reset area",
                "canvasPanel": "Drag to select area _ Right-click to reset area",
                "canvasDrawLayer": "Drag to select area _ Right-click to reset area"
            };

        static private const hints:Object =
            {
                // 드로우 모드
                "drawModeButton": "Enter draw mode [f1 / f7 / esc / backspace]",
                "captureButton": "Enter capture mode [ctrl+c / ctrl+,]",
                "saveButton": "Save [ctrl+s] _ Save as... [shift+ctrl+s / right-click]",
                "timer": "Work time _ Hold to reset",
                "loadButton": "Load image [ctrl+o]",
                "clipBoardButton": "Load from clipboard [ctrl+v / ctrl+m] _ No image found",
                "newFileButton": "New file [hold esc / backspace / delete]",
                "gridButton": "Grid _ " + STRING_RIGHT_CLICK_TO_RESET,
                "sideBarPositionButton": "Move sidebar to right",
                "sideBarPositionButton2": "Move sidebar to left",
                "sideBarOFFButton": "Hide sidebar [tab / \\]",
                "sideBarOFFButton2": "Hide sidebar [tab / \\]",
                "sideBarONButton": "Show sidebar [tab / \\]",
                "sideBarONButton2": "Show sidebar [tab / \\]",
                "topBarColorButton": "Change UI color theme",
                "dpiButton": STRING_VARIBALE_HINT,
                "newWindowCloseButton": "Close image view [esc]",
                "newWindowButton": "Image view _ Drag to move _ Right-click to fit size",
                "aboutButton": "About FOFO PAINT",
                "updateButton": STRING_VARIBALE_HINT,

                // 리플레이 모드
                "replayModeButton": "Enter replay mode [f1 / f7]",
                "repCaptureButton": "Enter capture mode [ctrl+c / ctrl+m]",
                "playButton": "Play [enter / space] _ Right-click on viewport",
                "pauseButton": "Pause [enter / space / esc / backspace]",
                "replayPrev": "Prev step [left / z / .] _ Prev frame [Shift + (left / z / .) / right-click]",
                "replayNext": "Next step [right / x / ,] _ Next frame [Shift + (right / x / ,) / right-click]",
                "repNewFileButton": "Create new file from current frame",
                "cutPrevDataButton": "Trim all before current frame",
                "superUndoButton": "Trim all after current frame",
                "replaySpeedSliderWrapper": "Playback speed [up / down, f  / v, h / n]",
                "replayZoomOutButton": "Zoom out _ " + STRING_RIGHT_CLICK_TO_RESET,
                "replayZoomInButton": "Zoom in _ " + STRING_RIGHT_CLICK_TO_RESET,
                "replayFitToWindowButton": "Toggle fit to viewport",
                "replayRotateButton": "Rotate _ " + STRING_RIGHT_CLICK_TO_RESET,
                "replayRepeatButton": "Toggle loop playback",
                "trackBar": STRING_VARIBALE_HINT,

                // 그리드 슬라이더
                "gridSliderWrapper": STRING_VARIBALE_HINT,
                "gridMoveLeftButton": "Nudge left _ Hold to repeat _ " + STRING_RIGHT_CLICK_TO_RESET,
                "gridMoveRightButton": "Nudge right _ Hold to repeat _ " + STRING_RIGHT_CLICK_TO_RESET,
                "gridMoveUpButton": "Nudge up _ Hold to repeat _ " + STRING_RIGHT_CLICK_TO_RESET,
                "gridMoveDownButton": "Nudge down _ Hold to repeat _ " + STRING_RIGHT_CLICK_TO_RESET,

                // 펜옵션
                "shapeCircle": "Circle",
                "shapeRect": "Rectangle",
                "penSmoothSliderWapper": STRING_VARIBALE_HINT,

                "sharpLineButtonWrapper": "Toggle Sharp line [3 / 8]",
                "sharpLineOFFButton": "Toggle Sharp line [3 / 8]",
                "sharpLineONButton": "Toggle Sharp line [3 / 8]",
                "sharpLineText": "Toggle Sharp line [3 / 8]",
                "airBrushButtonWrapper": "Toggle Air brush [4 / 7]",
                "airBrushOFFButton": "Toggle Air brush [4 / 7]",
                "airBrushONButton": "Toggle Air brush [4 / 7]",
                "airBrushText": "Toggle Air brush [4 / 7]",

                "layer1SelectButton": "Select Layer 1 [1 / 9] _ Click again to solo",
                "layer2SelectButton": "Select Layer 2 [2 / 0] _ Click again to solo",
                "layer1CheckedButton": "Enable Layer 1 (for Move, Lasso, Merge)",
                "layer1UncheckedButton": "Enable Layer 1 (for Move, Lasso, Merge)",
                "layer2CheckedButton": "Enable Layer 2 (for Move, Lasso, Merge)",
                "layer2UncheckedButton": "Enable Layer 2 (for Move, Lasso, Merge)",
                "layerSwapButton": "Swap layers",
                "layerMergeButton": "Merge into Layer 2",

                // 툴박스 2
                "toolQuickSidebar": "[6 / s+d / j+k]",
                "toolPen": "Pen [q / o key up]",
                "toolFillPen": "Fill pen [q / o]",
                "toolEraser": "Eraser [d / j]",
                "toolEyedropper": "Eyedropper [c / m]",
                "toolUndo": STRING_VARIBALE_HINT,
                "toolRedo": STRING_VARIBALE_HINT,
                "toolMirror": "Flip canvas [a / l]",
                "toolLasso": "Lasso [r / y]",
                "toolLine": "Line [shift]",
                "toolMove": "Move image [e / u]",
                "toolZoom": "Zoom canvas [w / i]",
                "toolZoomIn": "Zoom in _ " + STRING_RIGHT_CLICK_TO_RESET,
                "toolZoomOut": "Zoom out _ " + STRING_RIGHT_CLICK_TO_RESET,
                "toolRotate": "Rotate canvas [s / k] _ " + STRING_RIGHT_CLICK_TO_RESET,
                "toolRotate2": "Rotate canvas [s / k]",
                "toolRefLayer": "Reference layer [t]",
                "sideBarScrollBar": "Scroll [drag / wheel] _ " + STRING_RIGHT_CLICK_TO_RESET,

                "toolFillPenOK": "Confirm [right-click / enter / q or o]",
                "toolFillPenCancel": "Cancel [esc]",

                // 컬러 픽커
                "hueColor": "Hue",
                "svBox": "Saturation & Value",
                "swapPositionButton": "Swap palette position",
                "colorHistoryBox": "Color history _ Drag to add to My Palette",
                "myPaletteBox": "Hold to add, remove, or restore _ Drag to swap position",
                "rgbInfoText": STRING_VARIBALE_HINT,
                "paperColorButton": "Change background color",
                "penColorButton": "Change pen color",
                "currentColor": STRING_VARIBALE_HINT,
                "transColorButton": "Toggle transparency [c+space / m+space]",
                "myPaletteButton": "My Palette _ Click to expand / collapse _ Hold to clear",
                "drawrPresetButton": "Drawr presets _ Hold to clear scratch pad",
                "tegakiPresetButton": "Tegaki presets _ Hold to clear scratch pad",
                "scratchPad": "Scratch pad _ Drag to draw _ Click or [c / m] to select color",

                // 캔버스 네비게이터
                "navStageBG": "Canvas Navigator",
                "navBitmapBG": "Canvas Navigator",
                "navCursor": "Canvas Navigator",
                "navLayer1Bitmap": "Canvas Navigator",
                "navLayer2Bitmap": "Canvas Navigator"
            };

        static private function initSizeAndAlphaButtonHintString():void
        {
            if (_main === null)
            {
                return;
            }

            var len:int = PenTool.penAlphaList.length;
            var key:String = "alphaButton";
            for (var i:int = 1; i <= len; i++)
            {
                hints[key + i] = "Opacity " + (PenTool.penAlphaList[i] * 100) + "% [g / b]";
            }

            len = PenTool.penSizeList.length;
            key = "nSizeButton";
            for (i = 1; i <= len; i++)
            {
                hints[key + i] = "Size " + (PenTool.penSizeList[i]) + "px [f / v, h / n]";
            }
        }

        static public function getRedoButtonHint():String
        {
            if (_main === null || _main.toolBox2.visible)
            {
                return "Redo [x / ,]";
            }

            return "Redo [x / ,] _ Hold to repeat";
        }

        static public function getUndoButtonHint():String
        {
            if (_main === null || _main.toolBox2.visible)
            {
                return "Undo [z / .]";
            }

            return "Undo [z / .] _ Hold to repeat";
        }

        static public function getGridGapAdjustHintString(multi:uint, gap:uint):String
        {
            return "Grid " + (multi * gap) + "px (" + multi + "/20)";
        }

        static public function getNewFileHintString():String
        {
            return "Creating new file...";
        }

        static public function getResetTimerHintString():String
        {
            return "Resetting the timer...";
        }

        static public function getPenSmoothingValueString():String
        {
            if (_main === null)
            {
                return "";
            }

            return PenTool.penSmoothSlideValue + " / " + PenTool.penSmoothSlideTotal;
        }

        static public function getRGBorHSVString():String
        {
            if (_main === null)
            {
                return "";
            }
            return (ColorPickerController.isHSVInfoTextMode) ? "'HSV'" : "'RGB'";
        }

        static public function getCaptureSaveHintString():String
        {
            if (_main === null)
            {
                return "";
            }
            return (_main.captureAreaManager.isFullImageCapture()) ? "image" : "selected area";
        }

        static public function getUIScaleString():String
        {
            return Global.getUIScaleString();
        }

        static public function getTrackBarHintString():String
        {
            if (_main === null)
            {
                return "";
            }

            if (_main.isReplayRestartTimerON())
            {
                return "Seek bar _ Click to abort restart";
            }
            return "Seek bar";
        }

        static public function getGridGapHintString():String
        {
            if (_main === null)
            {
                return "";
            }

            return CanvasGridOverlay.gridGapMultiplier + CanvasGridOverlay.GRID_GAP + "px";
        }

        static public function getNewVersionAvailableHintString():String
        {
            return "Version " + AppUpdater.newVersionStr + " is available!";
        }

        static public function getOpacityButtonHintString(index:int):String
        {
            if (_main === null)
            {
                return "";
            }

            return "Opacity " + (PenTool.penAlphaList[index] * 100) + "% [g / b]";
        }

        static public function getSizeButtonHintString(index:int):String
        {
            if (_main === null)
            {
                return "";
            }

            return "Size " + (PenTool.penSizeList[index]) + "px [f / v, h / n]";
        }

        static public function getCurrentColorHintString():String
        {
            if (_main === null)
            {
                return "";
            }

            const pickedColor:uint = ColorPickerController.colorPickerBox.getRGBInfoBGColor();
            const arr:Vector.<Number> = (ColorPickerController.isHSVInfoTextMode) ? Global.HEXtoHSV(pickedColor, ColorPickerController.hsvColorData[0]) : Global.HEXtoRGB(pickedColor);
            const mode:String = (ColorPickerController.isHSVInfoTextMode) ? "HSV" : "RGB";

            return "Current color : " + mode + " " + arr[0] + "," + arr[1] + "," + arr[2];
        }

        static public function getHintFromTargetNameRefLayer(targetName:String):String
        {
            var str:String = "Reference layer";

            switch (targetName)
            {
                case "refMenuCloseButton":
                    str = "Close [esc, backspace, t]";
                    break;
                case "refTransferCanvasImageButton":
                    str = STRING_MERGE_INTO_REFLAYER;
                    break;
                case "refLoadImageButton":
                    str = "Load image";
                    break;
                case "refClipBoardButton":
                    str = "Load clipboard image";
                    break;
                case "refOpacitySliderWrapper":
                    str = "Adjust image opacity";
                    break;
                case "refRotateImageButton":
                    str = "Rotate _ " + STRING_RIGHT_CLICK_TO_RESET;
                    break;
                case "refMoveImageButton":
                    str = "Move _ " + STRING_RIGHT_CLICK_TO_RESET;
                    break;
                case "refResizeImageButton":
                    str = "Resize _ " + STRING_RIGHT_CLICK_TO_RESET;
                    break;
                case "refMirrorImageButton":
                    str = "Flip image";
                    break;
                case "refMemoryTrainingOnButton":
                case "refMemoryTrainingOffButton":
                    str = "Toggle Memory training";
                    break;
                case "refClearImageButton":
                    str = "Hold to erase reference image";
                    break;
                default:
                    break;
            }

            return str;
        }

        static public function getLassoMenuHintSwapLayer():String
        {
            if (_main === null)
            {
                return "";
            }

            return "Swap layers " + ((_main.isLassoLayerSwapButtonClicked) ? "*" : "");
        }

        static public function getLayerVisibleHint(layer1:Boolean, layer2:Boolean):String
        {
            if (layer1)
            {
                return layer2 ? "All layers visible" : "Layer 1 only";
            }

            return layer2 ? "Layer 2 only" : "No layers visible";
        }

        static public function getHintFromTargetNameLassoTool(targetName:String):String
        {
            var str:String = "Lasso tool";

            switch (targetName)
            {
                case "lassoOK":
                    str = "Confirm [enter, right-click]";
                    break;
                case "lassoCancel":
                    str = "Cancel [esc, backspace]";
                    break;
                case "lassoCopy":
                    str = "Copy selection";
                    break;
                case "lassoRotate":
                    str = "Rotate selection _ " + STRING_RIGHT_CLICK_TO_RESET;
                    break;
                case "lassoMirror":
                    str = "Flip selection";
                    break;
                case "lassoResize":
                    str = "Resize selection _ " + STRING_RIGHT_CLICK_TO_RESET;
                    break;
                case "lassoRefLayer":
                    str = STRING_MERGE_INTO_REFLAYER;
                    break;
                case "lasso1pxLeft":
                case "lasso1pxRight":
                case "lasso1pxUp":
                case "lasso1pxDown":
                    str = "Nudge image [space + wasd or ijkl]";
                    break;
                case "lassoLayerMerge":
                    str = "Merge into layer 2";
                    break;
                case "lassoLayerSwap":
                    str = getLassoMenuHintSwapLayer();
                    break;
                default:
                    break;
            }

            return str;
        }

        static public function getDeleteReplayDataHintString():String
        {
            return "Triming data..";
        }

        static public function getReplayRestartHintString(count:Number):String
        {
            return "Restarting in " + count + " sec";
        }

        static public function getReplaySpeedHintString(speed:Number, timeStr:String):String
        {
            return "Playback speed x" + speed + timeStr;
        }

        static public function getHintFromTargetNameCaptureMode(targetName:String):String
        {
            if (_main === null || !hintsCaptureMode.hasOwnProperty(targetName))
            {
                return null;
            }

            return getFinalHint(targetName, hintsCaptureMode);
        }

        static private function getFinalHint(targetName:String, hintSet:Object):String
        {
            if (hintSet[targetName] !== STRING_VARIBALE_HINT)
            {
                return hintSet[targetName];
            }

            if (targetName === "toolUndo")
            {
                return getUndoButtonHint();
            }

            if (targetName === "toolRedo")
            {
                return getRedoButtonHint();
            }

            if (targetName === "capSave")
            {
                return "Save " + getCaptureSaveHintString() + " [ctrl+s / ctrl+;]";
            }

            if (targetName === "capClipBoard")
            {
                return "Copy " + getCaptureSaveHintString() + " to clipboard [ctrl+c / ctrl+,]";
            }

            if (targetName === "dpiButton")
            {
                return "Change UI scale _ " + STRING_RIGHT_CLICK_TO_RESET + " (Current: " + getUIScaleString() + ")";
            }

            if (targetName === "trackBar")
            {
                return getTrackBarHintString();
            }

            if (targetName === "penSmoothSliderWapper")
            {
                return "Pen smoothing " + getPenSmoothingValueString();
            }

            if (targetName === "rgbInfoText")
            {
                return "Adjust values _ Click " + getRGBorHSVString() + " to change color model";
            }

            if (targetName === "currentColor")
            {
                return getCurrentColorHintString();
            }

            if (targetName === "updateButton")
            {
                return getNewVersionAvailableHintString();
            }

            if (targetName === "gridSliderWrapper")
            {
                return "Grid: " + getGridGapHintString() + " _ " + STRING_RIGHT_CLICK_TO_RESET;
            }

            return "";
        }

        static public function getHintFromTargetName(targetName:String):String
        {
            if (_main === null || !hints.hasOwnProperty(targetName))
            {
                return null;
            }

            return getFinalHint(targetName, hints);
        }
    }
}
