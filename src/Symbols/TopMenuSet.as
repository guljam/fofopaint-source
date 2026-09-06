package Symbols
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.display.Shape;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.text.TextFieldAutoSize;
	import flash.ui.ContextMenu;
	import flash.text.TextFormat;
	import assets.VisualBuilder;
	import assets.VisualFieldCollector;

	import main_module.AppUpdater;
	import main_module.ImageViewWindow;
	import main_module.MainUI;
	import main_module.Utils;

	public class TopMenuSet extends Sprite {

		public const BARSIZE:Number = 38;

		// 버튼 추가시 해야할거
		// change uicolor, mouse down state 추가, handcursor false로 하기 button order추가, 모드에 속하는거 에 추가
		public var captureButton:SimpleButton;
		public var repCaptureButton:SimpleButton;
		public var capRotate:SimpleButton;
		public var capFlip:SimpleButton;
		public var capSave:SimpleButton;
		public var capOff:SimpleButton;
		public var capTrans:SimpleButton;
		public var capClipBoard:SimpleButton;
		public var capStamp:SimpleButton;
		public var capStampFont:SimpleButton;
		public var saveButton:SimpleButton;
		public var loadButton:SimpleButton;
		public var clipBoardButton:SimpleButton;
		public var newFileButton:SimpleButton;
		public var gridButton:SimpleButton;
		public var gridMoveLeftButton:SimpleButton;
		public var gridMoveRightButton:SimpleButton;
		public var gridMoveUpButton:SimpleButton;
		public var gridMoveDownButton:SimpleButton;
		public var gridSlider:SimpleButton;
		public var gridSliderCursor:SimpleButton;
		public const gridButtonWrapper:Sprite = new Sprite();
		public const gridSliderWrapper:Sprite = new Sprite();
		public const gridMoveButtonWrapper:Sprite = new Sprite();
		public var replayModeButton:SimpleButton;
		public var drawModeButton:SimpleButton;
		public var topBarColorButton:SimpleButton;
		public var dpiButton:SimpleButton;
		public var capLayer1VisibleButton:SimpleButton;
		public var capLayer2VisibleButton:SimpleButton;
		public var sideBarPositionButton:SimpleButton;
		public var sideBarPositionButton2:SimpleButton;
		public var sideBarOFFButton:SimpleButton;
		public var sideBarOFFButton2:SimpleButton;
		public var sideBarONButton:SimpleButton;
		public var sideBarONButton2:SimpleButton;
		public var cutPrevDataButton:SimpleButton;
		public var superUndoButton:SimpleButton;
		public var repNewFileButton:SimpleButton;
		public var newWindowButton:SimpleButton;
		public var newWindowCloseButton:SimpleButton;
		public var aboutButton:SimpleButton;
		public var updateButton:SimpleButton;
		public var replayZoomInButton:SimpleButton;
		public var replayZoomOutButton:SimpleButton;
		public var replayFitToWindowButton:SimpleButton;
		public var replayRotateButton:SimpleButton;
		public var replayRepeatButton:SimpleButton;
		public var timer:TextField;
		public var timerAFkDot:TextField;

		private var buttonOrder:Array = [];
		private var drawModeButtons:Array = [];
		private var replayModeButtons:Array = [];
		private var captureModeButtons:Array = [];
		private var gridBoxButtons:Array = [];
		public var topbarBG:Shape = new Shape();
		private var topbarBGColor:uint = 0;
		private var hintOKBGColor:uint = 0;
		private var hintFontColor:uint = 0;

		public var replaySpeedSliderCursor:SimpleButton;
		public var replaySpeedSlider:SimpleButton;
		public var replaySpeedSliderWrapper:Sprite = new Sprite();

		private var isHintLocked:Boolean = false;
		private var hintWaitAnimTimer:int = 0;
		private var hintWaitAnimCount:int = 0;

		private var newWindowIconStateSaveLayerButton:Boolean = false; // 뉴윈도우인지 끄기 버튼인지 구분
		private var newWindowIconStateDrawModeIcon:Boolean = false; // 뉴윈도우인지 끄기 버튼인지 구분

		public var captureInputWarpper:Sprite = new Sprite();
		public var captureInput:TextField;
		public var captureInputFinal:TextField;
		public var captureInputBorder:SimpleButton;
		private var cpatureInputStringSave:String = "";

		public function getCaptureInputFinalWidth():Number {
			return captureInputFinal.width;
		}

		public function setCaptureInputFinalWidth(newWidth:Number):void {
			captureInputFinal.width = newWidth;
		}

		public function getCaptureInputFinalLines():int {
			return captureInputFinal.numLines;
		}

		public function getCaptureInputFinalHeight():Number {
			return captureInputFinal.height;
		}

		public function setCaptureInputFinalString(newText:String):void {
			captureInputFinal.text = newText;
		}

		public function setCaptureInputString(newText:String):void {
			captureInput.text = newText;
		}

		public function getCaptureInputFinalString():String {
			return captureInputFinal.text;
		}

		public function getCaptureInputString():String {

			return captureInput.text;
		}

		public function setScale(scale:Number):void {
			this.scaleX = scale;
			this.scaleY = scale;
		}

		public function isGridMoveButtonOFFAlpha():Boolean {
			return gridMoveLeftButton.alpha < 1.0;
		}

		public function setGridMoveButtonAlpha(alpha:Number):void {
			gridMoveLeftButton.alpha = alpha;
			gridMoveRightButton.alpha = alpha;
			gridMoveUpButton.alpha = alpha;
			gridMoveDownButton.alpha = alpha;
		}

		private function initGridButtonWrapper():void {
			gridButtonWrapper.name = "gridButtonWrapper";

			initGridSliderWrapper();
			initGridMoveButtonWrapper();

			gridButtonWrapper.addChild(gridSliderWrapper);
			gridButtonWrapper.addChild(gridMoveButtonWrapper);

			gridSliderWrapper.x = 7;
			gridSliderWrapper.y = 4;
			gridMoveButtonWrapper.x = gridSliderWrapper.x + gridButtonWrapper.width + 7;
			gridMoveButtonWrapper.y = 4;
			gridButtonWrapper.visible = false;
		}

		// control menu initPenSmoothSliderWrapper와 같음
		private function initGridMoveButtonWrapper():void {
			gridMoveButtonWrapper.name = "gridMoveButtonWrapper";

			gridMoveButtonWrapper.addChild(gridMoveLeftButton);
			gridMoveButtonWrapper.addChild(gridMoveRightButton);
			gridMoveButtonWrapper.addChild(gridMoveUpButton);
			gridMoveButtonWrapper.addChild(gridMoveDownButton);

			gridMoveLeftButton.useHandCursor = false;
			gridMoveRightButton.useHandCursor = false;
			gridMoveUpButton.useHandCursor = false;
			gridMoveDownButton.useHandCursor = false;

			gridMoveLeftButton.x = 0;
			gridMoveLeftButton.y = 0;
			gridMoveRightButton.x = gridMoveLeftButton.x + gridMoveLeftButton.width;
			gridMoveRightButton.y = 0;
			gridMoveUpButton.x = gridMoveRightButton.x + gridMoveRightButton.width;
			gridMoveUpButton.y = 0;
			gridMoveDownButton.x = gridMoveUpButton.x + gridMoveUpButton.width;
			gridMoveDownButton.y = 0;

			gridMoveButtonWrapper.graphics.clear();
			gridMoveButtonWrapper.graphics.beginFill(0, 0.0);
			gridMoveButtonWrapper.graphics.drawRect(0, 0, gridMoveButtonWrapper.width, gridMoveButtonWrapper.height);
			gridMoveButtonWrapper.graphics.endFill();
		}

		private function initGridSliderWrapper():void {
			gridSliderWrapper.name = "gridSliderWrapper";
			gridSliderWrapper.addChild(gridSlider);
			gridSliderWrapper.addChild(gridSliderCursor);
			gridSlider.useHandCursor = false;
			gridSliderCursor.useHandCursor = false;

			gridSlider.mouseEnabled = false;
			gridSlider.x = gridSliderCursor.width / 2 + 6;
			gridSlider.y = gridSliderCursor.height / 2 + 4;

			gridSliderCursor.mouseEnabled = false;
			gridSliderCursor.x = gridSlider.x;
			gridSliderCursor.y = gridSlider.y;

			gridSliderWrapper.graphics.clear();
			gridSliderWrapper.graphics.beginFill(0xFF0000, 0.0);
			gridSliderWrapper.graphics.drawRect(0, 0, gridSlider.x + gridSlider.width + gridSliderCursor.width / 2 + 5, gridSliderCursor.height + 7);
			gridSliderWrapper.graphics.endFill();
		}

		private function initReplaySpeedSliderWrapper():void {
			replaySpeedSliderWrapper.name = "replaySpeedSliderWrapper";
			replaySpeedSliderWrapper.addChild(replaySpeedSlider);
			replaySpeedSliderWrapper.addChild(replaySpeedSliderCursor);
			replaySpeedSlider.mouseEnabled = false;
			replaySpeedSlider.x = replaySpeedSliderCursor.width / 2 + 3;
			replaySpeedSlider.y = replaySpeedSliderCursor.height / 2 + 4;

			replaySpeedSliderCursor.mouseEnabled = false;
			replaySpeedSliderCursor.x = replaySpeedSlider.x + 1.5;
			replaySpeedSliderCursor.y = replaySpeedSlider.y;

			replaySpeedSliderWrapper.graphics.clear();
			replaySpeedSliderWrapper.graphics.beginFill(0xFF0000, 0.0);
			replaySpeedSliderWrapper.graphics.drawRect(0, 0, replaySpeedSlider.x + replaySpeedSlider.width + gridSliderCursor.width + 1 / 2, replaySpeedSliderCursor.height + 8);
			replaySpeedSliderWrapper.graphics.endFill();
		}

		public function setReplaySpeedBarToGridSliderON(shortcutKey:Boolean):void {
			gridButtonWrapper.graphics.clear();
			gridButtonWrapper.graphics.beginFill(Global.getUIBGColor());
			gridButtonWrapper.graphics.drawRect(0, 0, Math.floor(gridMoveButtonWrapper.x + gridMoveButtonWrapper.width + 7), Math.floor(gridButtonWrapper.height + 8));
			gridButtonWrapper.graphics.endFill();

			gridButtonWrapper.x = gridButton.x;
			gridButtonWrapper.y = BARSIZE;
			setChildIndex(gridButtonWrapper, numChildren - 1);
			gridButtonWrapper.visible = true;
		}

		public function setReplaySpeedBarToGridSliderOFF(stage:DisplayObjectContainer):void {
			gridButtonWrapper.visible = false;
			gridButtonWrapper.x = 0;
			gridButtonWrapper.y = -gridButtonWrapper.height;
		}

		public function enableFileOperationButtons(clipFlag:Boolean):void {
			saveButton.alpha = 1.0;
			loadButton.alpha = 1.0;
			newFileButton.alpha = 1.0;
			repNewFileButton.alpha = 1.0;
			superUndoButton.alpha = 1.0;
			cutPrevDataButton.alpha = 1.0;

			if (clipFlag) {
				clipBoardButton.alpha = 1.0;
			}
		}

		public function disableFileOperationButtons():void {
			const offAlpha:Number = Global.OFFALPHA;
			saveButton.alpha = offAlpha;
			loadButton.alpha = offAlpha;
			clipBoardButton.alpha = offAlpha;
			newFileButton.alpha = offAlpha;
			repNewFileButton.alpha = offAlpha;
			superUndoButton.alpha = offAlpha;
			cutPrevDataButton.alpha = offAlpha;
		}

		public function hideUpdateButton():void {
			updateButton.visible = false;
			aboutButton.visible = true;
		}

		public function showUpdateButton():void {
			updateButton.visible = true;
			aboutButton.visible = false;
		}

		public function updateTimerPos(stw:Number):void {
			const limitX:Number = (replaySpeedSliderWrapper.x + replaySpeedSliderWrapper.width + 8) * this.scaleX;
			var newX:Number = stw - (timer.textWidth + 10) * this.scaleX;
			if (newX < limitX)
				newX = limitX;
			timer.x = newX / this.scaleX;
			timerAFkDot.x = timer.x - 5;
		}

		public function updateUIColor():void {
			var i:int;

			Global.applyUIBGColor(topbarBG);
			for (i = 0; i < drawModeButtons.length; i++) {
				Global.applyUIFGColor(drawModeButtons[i]);
			}

			for (i = 0; i < replayModeButtons.length; i++) {
				Global.applyUIFGColor(replayModeButtons[i]);
			}

			for (i = 0; i < captureModeButtons.length; i++) {
				Global.applyUIFGColor(captureModeButtons[i]);
			}

			for (i = 0; i < gridBoxButtons.length; i++) {
				Global.applyUIFGColor(gridBoxButtons[i]);
			}

			const fgColor:uint = Global.getUIFGColor();

			timer.textColor = fgColor;
			timerAFkDot.textColor = fgColor;
			captureInput.textColor = fgColor;
		}

		public function setSpeedButtonPosByValue(rSpeed:Number, maxSpeed:Number):void {
			if (maxSpeed <= 1)
				return;

			const unitX:Number = replaySpeedSlider.width / maxSpeed;
			// 속도가 지수 형식으로 가서 log로 다시 역계산 해줘야함
			const exp:Number = Math.log(rSpeed) / Math.log(maxSpeed);
			const nowX:Number = exp * replaySpeedSlider.width;

			// setReplaySpeedButton 함수의 오프셋과 같아야함
			const minDist:Number = replaySpeedSlider.x + 1.5;
			const maxDist:Number = minDist + replaySpeedSlider.width - 2.5;

			replaySpeedSliderCursor.x = replaySpeedSlider.x + nowX;

			if (replaySpeedSliderCursor.x < minDist) {
				replaySpeedSliderCursor.x = minDist;
			}
			else if (replaySpeedSliderCursor.x > maxDist) {
				replaySpeedSliderCursor.x = maxDist;
			}
		}

		public function updateTopbarBG(stw:int):void {
			topbarBG.width = Math.ceil(stw / this.scaleX);
		}

		public function makeTopbarBG(color:uint):void {
			topbarBG.graphics.clear();
			topbarBG.graphics.beginFill(color);
			topbarBG.graphics.drawRect(0, 0, 10, BARSIZE);
			topbarBG.graphics.endFill();
			topbarBGColor = color;
		}

		public function checkSideBarONOFFButton(visible:Boolean, rightSidebar:Boolean):void {
			function check(index:int):void {
				const arr:Array = [sideBarONButton,
						sideBarOFFButton,
						sideBarONButton2,
						sideBarOFFButton2];
				const len:uint = arr.length;

				for (var i:uint = 0; i < len; i++) {
					if (i === index) {
						(arr[i] as SimpleButton).visible = true;
					}
					else {
						(arr[i] as SimpleButton).visible = false;
					}
				}
			}

			if (rightSidebar) {
				if (visible)
					check(1);
				else
					check(0);
			}
			else {
				if (visible)
					check(3);
				else
					check(2);
			}
		}

		private function setIconsVisible(arr:Array, flag:Boolean):void {
			const len:uint = arr.length;

			for (var i:uint = 0; i < len; i++) {
				if (arr[i] as DisplayObject)
					arr[i].visible = flag;
			}
		}

		public function hideModeIcons(mode:String, rightSidebar:Boolean = false, sidebarVisible:Boolean = false):void {
			const arr:Array = (mode === "replay") ? replayModeButtons
				: (mode === "capture") ? captureModeButtons
				: (mode === "draw") ? drawModeButtons
				: null;
			if (!arr) {
				return;
			}

			setIconsVisible(arr, false);
		}

		public function showModeIcons(mode:String, rightSidebar:Boolean = false, sidebarVisible:Boolean = false):void {
			const arr:Array = (mode === "replay") ? replayModeButtons
				: (mode === "capture") ? captureModeButtons
				: (mode === "draw") ? drawModeButtons
				: null;
			if (!arr) {
				return;
			}

			setIconsVisible(arr, true);

			if (mode === "draw") {
				if (rightSidebar) {
					sideBarPositionButton.visible = false;
				}
				else {
					sideBarPositionButton2.visible = false;
				}

				checkSideBarONOFFButton(sidebarVisible, rightSidebar);
			}
		}

		public function initMouseDownState():void {
			const arr:Vector.<SimpleButton> = new <SimpleButton>[
					captureButton,
					repCaptureButton,
					capRotate,
					capFlip,
					capSave,
					capOff,
					capTrans,
					capClipBoard,
					capLayer1VisibleButton,
					capLayer2VisibleButton,
					capStamp,
					capStampFont,

					saveButton,
					loadButton,
					clipBoardButton,
					newFileButton,
					gridButton,
					replayModeButton,
					drawModeButton,
					topBarColorButton,
					dpiButton,

					sideBarPositionButton,
					sideBarPositionButton2,
					sideBarOFFButton,
					sideBarOFFButton2,
					sideBarONButton,
					sideBarONButton2,
					aboutButton,
					updateButton,
					newWindowButton,
					newWindowCloseButton,

					cutPrevDataButton,
					superUndoButton,
					repNewFileButton,
					replayZoomInButton,
					replayZoomOutButton,
					replayFitToWindowButton,
					replayRepeatButton,

					gridMoveLeftButton,
					gridMoveRightButton,
					gridMoveUpButton,
					gridMoveDownButton
				];
			const len:uint = arr.length;
			var btnDown:DisplayObjectContainer;

			for (var i:uint = 0; i < len; i++) {
				btnDown = arr[i].downState as DisplayObjectContainer;
				btnDown.x = 2;
				btnDown.y = 2;
			}
		}

		public function initModeButtons():void // 버튼위치 설정
		{
			const startX:Number = 3;
			const startY:Number = 2;
			const gap:Number = 36;

			for (var i:uint = 0, len:uint = buttonOrder.length; i < len; i++) {
				const set :Array = buttonOrder[i];
				const len2:uint = set .length;

				for (var j:uint = 0; j < len2; j++) {
					const ele:DisplayObject = set [j] as DisplayObject;
					if (ele) {
						ele.x = Math.floor(startX) + gap * i;
						ele.y = 4;
					}
				}
			}

			sideBarPositionButton2.x = sideBarPositionButton.x;
			sideBarPositionButton2.y = sideBarPositionButton.y;
			sideBarOFFButton2.x = sideBarOFFButton.x;
			sideBarOFFButton2.y = sideBarOFFButton.y;
			sideBarONButton.x = sideBarOFFButton.x;
			sideBarONButton.y = sideBarOFFButton.y;
			sideBarONButton2.x = sideBarOFFButton.x;
			sideBarONButton2.y = sideBarOFFButton.y;

			updateButton.x = aboutButton.x;
			updateButton.y = aboutButton.y;

			replaySpeedSliderWrapper.y = 4;
		}

		public function updateIconsByMode(mode:int):void
		{
			const main:Main = Main._instance;
			if (main.isLassoToolStarted === true || main.isAboutBoxOpened === true)
			{
				return;
			}

			Utils.setAsTopChild(this);

			hideUpdateButton();

			if (mode === 0)
			{
				showModeIcons("draw", main.isRightSidebar, main.isSidebarVisible);
				hideModeIcons("replay");
				hideModeIcons("capture");
				main.updatePenSizeCursor();
				if (AppUpdater.status !== AppUpdater.FLAG_NO_UPDATE)
				{
					showUpdateButton();
				}

				if (ImageViewWindow.isCanvasWindowON)
					MainUI.topBar.newWindowButton.visible = false;
				else
					MainUI.topBar.newWindowCloseButton.visible = false;
			}
			else if (mode === 1)
			{
				showModeIcons("replay");
				hideModeIcons("draw");
				hideModeIcons("capture");
				main.seekBarBox.setPlayButtonVisible(!main.isReplayStarted);
			}
			else if (mode === 2)
			{
				showModeIcons("capture");
				hideModeIcons("replay");
				hideModeIcons("draw");

				if (main.canvasLayer1Bitmap.visible)
				{
					capLayer1VisibleButton.alpha = 1.0;
				}
				else
				{
					capLayer1VisibleButton.alpha = Global.OFFALPHA;
				}

				if (main.canvasLayer2Bitmap.visible)
				{
					capLayer2VisibleButton.alpha = 1.0;
				}
				else
				{
					capLayer2VisibleButton.alpha = Global.OFFALPHA;
				}

				main.updateCaptureStampButtonAlpha();
			}
		}

		[Embed(
            source="fofoPaint-animate-27.13.swf",
            symbol="TopMenuSet"
        )]
		private static const EmbeddedClass:Class;

		public function TopMenuSet() {
			const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
			VisualBuilder.buildInto(this,EmbeddedClass,fields);
			initReplaySpeedSliderWrapper();
			initGridButtonWrapper();

			capRotate.visible = false;
			capFlip.visible = false;
			capSave.visible = false;
			capOff.visible = false;
			capTrans.visible = false;
			capClipBoard.visible = false;
			drawModeButton.visible = false;

			repCaptureButton.visible = false;
			cutPrevDataButton.visible = false;
			superUndoButton.visible = false;
			repNewFileButton.visible = false;
			drawModeButton.visible = false;

			captureButton.useHandCursor = false;
			repCaptureButton.useHandCursor = false;
			capRotate.useHandCursor = false;
			capFlip.useHandCursor = false;
			capSave.useHandCursor = false;
			capOff.useHandCursor = false;
			capTrans.useHandCursor = false;
			capClipBoard.useHandCursor = false;
			capStamp.useHandCursor = false;
			capStampFont.useHandCursor = false;
			saveButton.useHandCursor = false;
			loadButton.useHandCursor = false;
			clipBoardButton.useHandCursor = false;
			newFileButton.useHandCursor = false;
			gridButton.useHandCursor = false;
			replayModeButton.useHandCursor = false;
			drawModeButton.useHandCursor = false;
			topBarColorButton.useHandCursor = false;
			dpiButton.useHandCursor = false;
			capLayer1VisibleButton.useHandCursor = false;
			capLayer2VisibleButton.useHandCursor = false;
			sideBarOFFButton.useHandCursor = false;
			sideBarOFFButton2.useHandCursor = false;
			sideBarONButton.useHandCursor = false;
			sideBarONButton2.useHandCursor = false;
			sideBarPositionButton.useHandCursor = false;
			sideBarPositionButton2.useHandCursor = false;
			cutPrevDataButton.useHandCursor = false;
			superUndoButton.useHandCursor = false;
			repNewFileButton.useHandCursor = false;
			aboutButton.useHandCursor = false;
			updateButton.useHandCursor = false;
			newWindowButton.useHandCursor = false;
			newWindowCloseButton.useHandCursor = false;
			replayZoomInButton.useHandCursor = false;
			replayZoomOutButton.useHandCursor = false;
			replayFitToWindowButton.useHandCursor = false;
			replayRotateButton.useHandCursor = false;
			replayRepeatButton.useHandCursor = false;

			newWindowCloseButton.visible = false;
			sideBarOFFButton2.visible = false;
			sideBarONButton.visible = false;
			sideBarONButton2.visible = false;

			buttonOrder = [
					[replayModeButton, drawModeButton, capOff],
					[captureButton, repCaptureButton, capSave],
					[saveButton, repNewFileButton, capClipBoard],
					[loadButton, cutPrevDataButton, capRotate],
					[clipBoardButton, superUndoButton, capFlip],
					[newFileButton, replayZoomInButton, capTrans],
					[gridButton, replayZoomOutButton, capLayer1VisibleButton],
					[sideBarPositionButton, replayRotateButton, capLayer2VisibleButton],
					[sideBarOFFButton, replayFitToWindowButton, capStamp],
					[topBarColorButton, replayRepeatButton, capStampFont],
					[dpiButton, replaySpeedSliderWrapper, captureInputWarpper],
					[newWindowButton, newWindowCloseButton],
					[aboutButton]
				];

			drawModeButtons = [
					replayModeButton,
					captureButton,
					saveButton,
					loadButton,
					clipBoardButton,
					newFileButton,
					gridButton,
					topBarColorButton,
					dpiButton,
					sideBarPositionButton,
					sideBarPositionButton2,
					sideBarOFFButton,
					sideBarOFFButton2,
					sideBarONButton,
					sideBarONButton2,
					newWindowButton,
					newWindowCloseButton,
					aboutButton
				];

			replayModeButtons = [
					drawModeButton,
					repNewFileButton,
					cutPrevDataButton,
					superUndoButton,
					repCaptureButton,
					replayZoomInButton,
					replayZoomOutButton,
					replayFitToWindowButton,
					replayRotateButton,
					replaySpeedSliderWrapper,
					replayRepeatButton
				];

			captureModeButtons = [
					capOff,
					capSave,
					capRotate,
					capFlip,
					capTrans,
					capClipBoard,
					capLayer1VisibleButton,
					capLayer2VisibleButton,
					capStamp,
					captureInputWarpper,
					capStampFont
				];

			gridBoxButtons = [
					gridSlider,
					gridSliderCursor,
					gridMoveLeftButton,
					gridMoveRightButton,
					gridMoveUpButton,
					gridMoveDownButton
				];

			initModeButtons();
			initMouseDownState();

			updateButton.visible = false;

			timer.y = 7;
			timer.autoSize = TextFieldAutoSize.LEFT;
			timerAFkDot.y = timer.y;
			timerAFkDot.autoSize = TextFieldAutoSize.LEFT;
			timerAFkDot.text = ".";

			addChild(replaySpeedSliderWrapper);
			addChild(topbarBG);
			addChild(gridButtonWrapper);

			captureInputWarpper.addChild(captureInput);
			captureInputWarpper.addChild(captureInputBorder);
			captureInputBorder.x = 0;
			captureInputBorder.y = 0;
			captureInputBorder.mouseEnabled = false;

			var emptyContextMenu:ContextMenu = new ContextMenu();
			const textFormat:TextFormat = new TextFormat();
			textFormat.font = null;
			captureInput.defaultTextFormat = textFormat;
			captureInput.embedFonts = false;
			captureInput.contextMenu = emptyContextMenu;
			captureInput.x = 3;
			captureInput.y = 3.5;
			captureInput.width = 150;
			captureInput.height = 30;

			captureInputFinal.embedFonts = false;
			captureInputFinal.x = -100;
			captureInputFinal.y = -100;
			captureInputFinal.visible = false;
			captureInputFinal.text = "";
			captureInputFinal.autoSize = TextFieldAutoSize.LEFT;
			captureInputFinal.wordWrap = true;
			captureInputFinal.multiline = true;

			addChild(captureInputWarpper);
			addChild(captureInputFinal);
			setChildIndex(topbarBG, 0);
			cacheAsBitmap = true;
		}
	}
}
