package
{
	public class hintStringsSet {
		private const hints:Object =
		{
			"replayModeButton":{str:"Switch to replay mode [f1, f7]",val:"APP_VERSION"}
		}

		public function get(targetName:String):String
		{
			return hints[targetName];
		}




		//         private function onMouseOverControlBoxHintON(e:MouseEvent):void
        // {
        //     const target:DisplayObject = e.target as DisplayObject;
        //     if(!target) return;
        //     const targetName:String = target.name;

        //     if(isFillPenStarted)
        //     {
        //         switch(targetName)
        //         {
        //             case "alphaButton":
        //             case "alphaButton2":
        //             case "alphaButton3":
        //             case "alphaButton4":
        //             case "alphaButton5":
        //             case "alphaButton6":
        //             case "alphaButton7":
        //             case "alphaButton8":
        //             case "alphaButton9":
        //             case "alphaButton10":
        //             {
        //                 showBottomHint(getSizeButtonHint(targetName),target);
        //             }
        //             return;

        //             default:
        //             return;
        //         }
        //         return;
        //     }
        //     else if(isHintUnavailable())
        //     {
        //         return;
        //     }

        //     var str:String = "";

        //     switch(targetName)
        //     {
        //         case "shapeCircle": str = "circle";
        //         break;

        //         case "shapeRect": str = "Square";
        //         break;

        //         case "penSmoothSliderWapper":
        //         {
        //             str = "Pen smoothing "+penSmoothSlideValue + "/" + penSmoothSlideTotal;
        //         }
        //         break;

        //         case "nSizeButton1":
        //         case "nSizeButton2":
        //         case "nSizeButton3":
        //         case "nSizeButton4":
        //         case "nSizeButton5":
        //         case "nSizeButton6":
        //         case "nSizeButton7":
        //         case "nSizeButton8":
        //         case "nSizeButton9":
        //         case "nSizeButton10":
        //         case "nSizeButton11":
        //         case "nSizeButton12":
        //         {
        //             showBottomHint(getSizeButtonHint(targetName),target);
        //         }
        //         return;

        //         case "alphaButton":
        //         case "alphaButton2":
        //         case "alphaButton3":
        //         case "alphaButton4":
        //         case "alphaButton5":
        //         case "alphaButton6":
        //         case "alphaButton7":
        //         case "alphaButton8":
        //         case "alphaButton9":
        //         case "alphaButton10":
        //         {
        //             showBottomHint(getOpacityButtonHint(targetName),target);
        //         }
        //         return;

        //         case "sharpLineButtonWrapper":
        //         case "sharpLineOFFButton":
        //         case "sharpLineONButton":
        //         case "sharpLineText":
        //             str = "Sharp line [3, 8]";
        //         break;

        //         case "airBrushButtonWrapper":
        //         case "airBrushOFFButton":
        //         case "airBrushONButton":
        //         case "airBrushText":
        //             str = "Air brush [4, 7]";
        //         break;

        //         case "layer1SelectButton":
        //             str = "Select layer 1 [1, 9]\nShow only layer 1 ON/OFF [click]";
        //         break;

        //          case "layer2SelectButton":
        //             str = "Select layer 2 [2, 0]\nShow only layer 2 ON/OFF [click]";
        //         break;

        //         case "layer1CheckButton":
        //         case "layer1UncheckButton":
        //             str = "Check layer 1 [1+w, 9+i]\nfor move image tool, lasso tool, reference layer";
        //         break;

        //         case "layer2CheckButton":
        //         case "layer2UncheckButton":
        //             str = "Check layer 2 [2+w, 0+i]\nfor move image tool, lasso tool, reference layer";
        //         break;

        //         case "layerSwapButton":
        //             str = "Swap layers [shift+d, shift+j]";
        //         break;

        //         case "layerMergeButton":
        //             str = "Merge image to layer 2 [shift+e, shift+o]";
        //         break;

        //         default:
        //         return;
        //     }

        //     if(str === "")
        //     {
        //         return;
        //     }

        //     showBottomHint(str,target);
        // }


        // private function onMouseOverTopBarHintON(e:MouseEvent):void //topbarhint
        // {
        //     const target:DisplayObject = e.target as DisplayObject;
        //     if(!target) return;

        //     const targetName:String = e.target.name;

        //     if(isLassoToolON)
        //     {
        //         if(targetName === "sideBarOFFButton"
        //         || targetName === "sideBarOFFButton2"
        //         || targetName === "sideBarONButton"
        //         || targetName === "sideBarONButton2"
        //         || targetName === "sideBarPositionButton"
        //         || targetName === "sideBarPositionButton2")
        //         {
        //             if(isMouseDragging)
        //             {
        //                 return;
        //             }
        //         }
        //         else
        //         {
        //             return;
        //         }
        //     }
        //     else if(isHintUnavailable())
        //     {
        //         return;
        //     }

        //     var str:String = "";

        //     switch(targetName)
        //     {
        //         case "frameInfo":
        //         case "replayTotalBar":
        //         case "replayNowBar":
        //         case "replayDeleteBar":
        //         {
        //             setTopBarHintOFF();
        //         }
        //         return;
        //         case "timer":
        //             str = "Actual working time\nReset [click]"+STRING_PRESS_HOLD;
        //         break;

        //         case "playButton":
        //             str = "Play [enter, space]";
        //         break;

        //         case "pauseButton":
        //             str = "Pause [enter, space]";
        //         break;

        //         case "replayPrev":
        //             str = "Prev [left, z, .]\nJump 1 frame [right-click, shift+left, shift+z, shift+.]";
        //         break;

        //         case "replayNext":
        //             str = "Next [right, x, ,]\nJump 1 frame [right-click, shift+right, shift+x, shift+,]";
        //         break;

        //         case "replaySpeedSliderWrapper":
        //         {
        //             if(rSpeedLastStr === "") str = "Change playback speed [up, down / f, v / h, n]";
        //             else str = rSpeedLastStr;
        //         }
        //         break;

        //         case "saveButton":
        //         case "repSaveButton":
        //             str = "Save [ctrl+s]\nSave as.. [shift+ctrl+s, right-click]";
        //         break;

        //         case "loadButton":
        //             str = "Load [ctrl+o]";
        //         break;

        //         case "repLoadButton":
        //             str = "Load [ctrl+o]";
        //         break;

        //         case "clipBoardButton":
        //             str = "Load clipboard image [ctrl+v, ctrl+n]"+((topBar.clipBoardButton.alpha < 1.0)?"\nThere are no copied images":"");
        //         break;

        //         case "newFileButton":
        //             str = "New file [click, esc, backspace, delete]"+STRING_PRESS_HOLD;
        //         break;

        //         case "captureButton":
        //         case "repCaptureButton":
        //             str = "Capture mode [ctrl+c, ctrl+m]";
        //         break;

        //         case "capOff":
        //             str = "Exit capture mode (esc, backspace, f1, f7]";
        //         break;

        //         case "capFull":
        //             str = (drawCaptureArea.isFullImageCapture()) ? "Save full image [ctrl+s, ctrl+k]" : "Save selected area [ctrl+s, ctrl+k]";
        //         break;

        //         case "capClipBoard":
        //         {
        //             str = (e.target.alpha === 1.0) ? "Copy "+((drawCaptureArea.isFullImageCapture()) ?
        //                                                     "full image"
        //                                                     :"selected area image")
        //                                                     + " to clipboard [ctrl+c, ctrl+m]"
        //                                                     :"Already copied to clipboard";
        //         }
        //         break;

        //         case "capTrans":
        //             str = "Background color ON/OFF [d, j]";
        //         break;

        //         case "capRotate":
        //             str = "Rotate image [s, k]";
        //         break;

        //         case "capFlip":
        //             str = "Flip image [a, l]";
        //         break;

        //         case "capLayer1VisibleButton":
        //             str = "Layer 1 visible ON/OFF [1, 9]";
        //         break;

        //         case "capLayer2VisibleButton":
        //             str = "Layer 2 visible ON/OFF [2, 0]";
        //         break;

        //         case "capStamp":
        //             str = "Stamp ON/OFF [f, h]";
        //         break;

        //         case "capStampFont":
        //             str = "Change stamp font";
        //         break;

        //         case "reRecordingButton":
        //             str = "New file from this image [click, f2]"+STRING_PRESS_HOLD;
        //         break;

        //         case "cutPrevDataButton":
        //             str = "Delete earlier replay data [click, f3]"+STRING_PRESS_HOLD;
        //         break;

        //         case "superUndoButton":
        //             str = "Delete later replay data [click, f4]"+STRING_PRESS_HOLD;
        //         break;

        //         case "gridButton":
        //             str = "Grid [f2, f8]\nReset [right-click, shift+f2, shift+f8]";
        //         break;

        //         case "gridSliderWrapper":
        //         {
        //             if(gridGapValue === 0)
        //             {
        //                 str = "Grid off";
        //             }
        //             else
        //             {
        //                 str = "Grid " + (gridGapValue*GRID_GAP)+"px ("+gridGapValue+"/20), "+STRING_RIGHT_CLICK_TO_RESET;
        //             }
        //         }
        //         break;

        //         case "gridMoveLeftButton":
        //         case "gridMoveRightButton":
        //         case "gridMoveUpButton":
        //         case "gridMoveDownButton":
        //             str = "Move gird by 1 pixel \nRepeat [hold-click], Reset [right-click]";
        //         break;

        //         case "sideBarOFFButton":
        //         case "sideBarOFFButton2":
        //             str = "Turn sidebar OFF [tab, \\ ]";
        //         break;

        //         case "sideBarONButton":
        //         case "sideBarONButton2":
        //             str = "Turn sidebar ON [tab, \\ ]";
        //         break;

        //         case "sideBarPositionButton":
        //             str = "Right sidebar [f3]";
        //         break;

        //         case "sideBarPositionButton2":
        //             str = "Left sidebar [f3]";
        //         break;

        //         case "topBarColorButton":
        //             str = "Change UI color [f4]";
        //         break;

        //         case "dpiButton":
        //             str = "Current UI scale : "+getUIScaleString(uiScaleIndex)+"\nChange UI scale [f5]\nReset [shift+F5, right-click]";
        //         break;

        //         case "layer1CheckButton":
        //         case "layer1UncheckButton":
        //             str = "Layer 1 visible ON/OFF [shift+1, shift+9]";
        //         break;

        //         case "layer2CheckButton":
        //         case "layer2UncheckButton":
        //             str = "Layer 2 visible ON/OFF [shift+2, shift+0]";
        //         break;

        //         case "layerSwapButton":
        //             str = "Swap layer [shift+q, shift+p]";
        //         break;

        //         case "layerMergeButton":
        //             str = "Merge image to layer 2 [shift+e, shift+o]";
        //         break;

        //         case "aboutButton":
        //             str = "About FOFO PAINT..";
        //         break;

        //         case "newWindowCloseButton":
        //             str = "Close image view window [esc on window]";
        //         break;

        //         case "newWindowButton":
        //             str = "Open image view window [f6]\nMove window [click+drag on window]\nFit to image size [right-click on window]";
        //         break;

        //         case "updateButton":
        //             str = "Version " + newVersionStr + " released!\nInstall update [click]";
        //         break;

        //         case "drawModeButton": str = "Draw mode [f1, f7]"; break;
        //         case "replayModeButton": str = "Replay mode [f1, f7]"; break;
        //         case "replayZoomOutButton": str = "Zoom out [f5]\nReset [right-click, shift+f5, shift+f6]";break;
        //         case "replayZoomInButton": str = "Zoom in [f6]\nReset [right-click, shift+f5, shift+f6]"; break;
        //         case "replayFitToWindowButton": str = "Canvas center alignment ON/OFF [right-click on canvas]"; break;
        //         case "replayRotateButton": str = "Rotate \n"+STRING_RIGHT_CLICK_TO_RESET; break;
        //         case "replayRepeatButton": str = "Repeat ON/OFF"; break;

        //         default:
        //         return;
        //     }

        //     showBottomHint(str,target);
        // }
	}
}

