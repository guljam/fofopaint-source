package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.display.Shape;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.text.TextFieldAutoSize;

	public class topMenu extends Sprite {
		public const BARSIZE:Number = 38;
		private var miniTimer:fofoTimer;

		//버튼 추가시 해야할거
		//change uicolor, mouse down state 추가, handcursor false로 하기 button order추가, 모드에 속하는거 에 추가
		public var captureButton:SimpleButton;
		public var repCaptureButton:SimpleButton;
		public var capRotate:SimpleButton;
		public var capFlip:SimpleButton;
		public var capFull:SimpleButton;
		public var capOff:SimpleButton;
		public var capTrans:SimpleButton;
		public var capClipBoard:SimpleButton;
		public var saveButton:SimpleButton;
		public var repSaveButton:SimpleButton;
		public var loadButton:SimpleButton;
		public var repLoadButton:SimpleButton;
		public var clipButton:SimpleButton;
		public var clearButton:SimpleButton;
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
		public var reRecordingButton:SimpleButton;
		public var newWindowButton:SimpleButton;
		public var newWindowCloseButton:SimpleButton;
		public var aboutButton:SimpleButton;
		public var updateButton:SimpleButton;
		public var replayZoomInButton:SimpleButton;
		public var replayZoomOutButton:SimpleButton;
		public var replayFitToWindowButton:SimpleButton;
		public var replayRotateButton:SimpleButton;
		public var timer:TextField;
		public var timerAFkDot:TextField;

		private var buttonOrder:Array = [];
		private var drawModeButtons:Array = [];
		private var replayModeButtons:Array = [];
		private var captureModeButtons:Array = [];
		private var topbarBG:Shape = new Shape();
		private var topbarBGColor:uint = 0;
		private var hintOKBGColor:uint = 0;
		private var hintFontColor:uint = 0;

		public var replaySpeedSliderCursor:SimpleButton;
		public var replaySpeedSlider:SimpleButton;
		public var replaySpeedSliderWrapper:Sprite = new Sprite();

		private var isHintLocked:Boolean = false;
		private var hintWaitAnimTimer:int = 0;
		private var hintWaitAnimCount:int = 0;

		private var newWindowIconStateSaveLayerButton:Boolean = false // 뉴윈도우인지 끄기 버튼인지 구분
		private var newWindowIconStateDrawModeIcon:Boolean = false // 뉴윈도우인지 끄기 버튼인지 구분

		private const baseColor:ColorTransform = new ColorTransform();
		private const opColor:ColorTransform = new ColorTransform();

		public function setScale(scale:Number):void
		{
			this.scaleX = scale;
			this.scaleY = scale;
		}

		public function isGridMoveButtonOFFAlpha():Boolean
		{
			return gridMoveLeftButton.alpha < 1.0;
		}

		public function setGridMoveButtonAlpha(alpha:Number):void
		{
			gridMoveLeftButton.alpha = alpha;
			gridMoveRightButton.alpha = alpha;
			gridMoveUpButton.alpha = alpha;
			gridMoveDownButton.alpha = alpha;
		}

		public function initGridButtonWrapper():void
		{
			gridButtonWrapper.name = "gridButtonWrapper";

			initGridSliderWrapper();
			initGridMoveButtonWrapper();

			gridButtonWrapper.addChild(gridSliderWrapper);
			gridButtonWrapper.addChild(gridMoveButtonWrapper);

			gridSliderWrapper.x = 0;
			gridSliderWrapper.y = 1.5;
			gridMoveButtonWrapper.x = gridSliderWrapper.x+gridButtonWrapper.width+5;
			gridMoveButtonWrapper.y = 0;
			gridButtonWrapper.visible = false;
		}

		//control menu initPenSmoothSliderWrapper와 같음
		public function initGridMoveButtonWrapper():void
		{
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
			gridMoveRightButton.x = gridMoveLeftButton.x+gridMoveLeftButton.width;
			gridMoveRightButton.y = 0;
			gridMoveUpButton.x = gridMoveRightButton.x+gridMoveRightButton.width;
			gridMoveUpButton.y = 0;
			gridMoveDownButton.x = gridMoveUpButton.x+gridMoveUpButton.width;
			gridMoveDownButton.y= 0;

			gridMoveButtonWrapper.graphics.clear();
			gridMoveButtonWrapper.graphics.beginFill(0,0.0);
			gridMoveButtonWrapper.graphics.drawRect(0,0,gridMoveButtonWrapper.width,gridMoveButtonWrapper.height);
			gridMoveButtonWrapper.graphics.endFill();
		}

		public function initGridSliderWrapper():void
		{
			gridSliderWrapper.name = "gridSliderWrapper";
			gridSliderWrapper.addChild(gridSlider);
			gridSliderWrapper.addChild(gridSliderCursor);
			gridSlider.useHandCursor = false;
			gridSliderCursor.useHandCursor = false;

			gridSlider.mouseEnabled = false;
			gridSlider.x = 6;
			gridSlider.y = 2;

			gridSliderCursor.mouseEnabled = false;
			gridSliderCursor.x = gridSlider.x;
			gridSliderCursor.y = gridSlider.height+5;

			gridSliderWrapper.graphics.clear();
			gridSliderWrapper.graphics.beginFill(0,0.0);
			gridSliderWrapper.graphics.drawRect(0,0,gridSlider.x+gridSlider.width+gridSliderCursor.width/2+1.5
													,gridSlider.y+gridSlider.height+gridSlider.y+gridSlider.height+3);
			gridSliderWrapper.graphics.endFill();
		}

		public function initReplaySpeedSliderWrapper():void
		{
			replaySpeedSliderWrapper.name = "replaySpeedSliderWrapper";
			replaySpeedSliderWrapper.addChild(replaySpeedSlider);
			replaySpeedSliderWrapper.addChild(replaySpeedSliderCursor);

			replaySpeedSlider.mouseEnabled = false;
			replaySpeedSlider.x = 6;
			replaySpeedSlider.y = 2;

			replaySpeedSliderCursor.mouseEnabled = false;
			replaySpeedSliderCursor.x = replaySpeedSlider.x;
			replaySpeedSliderCursor.y = replaySpeedSlider.height+5;
		}

		public function setReplaySpeedBarToGridSliderON(color:uint):void
		{
			gridButtonWrapper.graphics.clear();
			gridButtonWrapper.graphics.beginFill(color);
			gridButtonWrapper.graphics.drawRect(-1,0,gridMoveButtonWrapper.x+gridMoveButtonWrapper.width+2,gridButtonWrapper.height+1);
			gridButtonWrapper.graphics.endFill();

			if(this.getChildByName("gridButtonWrapper") === null)
			{
				this.addChild(gridButtonWrapper);
			}

			gridButtonWrapper.x = gridButton.x;
			gridButtonWrapper.y = BARSIZE;
			gridButtonWrapper.visible = true;
		}

		public function setReplaySpeedBarToGridSliderOFF():void
		{
			gridButtonWrapper.visible = false;
			if(this.getChildByName("gridButtonWrapper") !== null)
			{
				this.removeChild(gridButtonWrapper);
			}
		}

		public function setButtonAlphaONSaving(clipFlag:Boolean):void
		{
			saveButton.alpha = 1.0;
			repSaveButton.alpha = 1.0;
			loadButton.alpha = 1.0;
			repLoadButton.alpha = 1.0;
			clearButton.alpha = 1.0;
			reRecordingButton.alpha = 1.0;
			superUndoButton.alpha = 1.0;
			cutPrevDataButton.alpha = 1.0;

			if(clipFlag) clipButton.alpha = 1.0;
		}

		public function setButtonAlphaOFFSaving(offAlpha:Number):void
		{
			saveButton.alpha = offAlpha;
			repSaveButton.alpha = offAlpha;
			loadButton.alpha = offAlpha;
			repLoadButton.alpha = offAlpha;
			clipButton.alpha = offAlpha;
			clearButton.alpha = offAlpha;
			reRecordingButton.alpha = offAlpha;
			superUndoButton.alpha = offAlpha;
			cutPrevDataButton.alpha = offAlpha;
		}

		public function updateButtonVisible(flag:Boolean):void
		{
			updateButton.visible = flag;
			aboutButton.visible = !flag;
		}

		public function updateTimerPos(stw:Number):void
		{
			const limitX:Number = (replaySpeedSliderWrapper.x+replaySpeedSliderWrapper.width+8)*this.scaleX;
			var newX:Number = stw-(timer.textWidth+10)*this.scaleX;
			if(newX < limitX) newX = limitX;
			timer.x = newX/this.scaleX;
			timerAFkDot.x = timer.x-5;
		}

		public function changeUIColor(base:uint,op:uint,hintOKColor:uint):void
		{

			var alphaBackup:Number = 0.0;

			opColor.color = op;
			baseColor.color = base;
			topbarBGColor = base;
			hintOKBGColor = hintOKColor;
			hintFontColor = op;

			topbarBG.transform.colorTransform = baseColor;
			captureButton.transform.colorTransform = opColor;
			repCaptureButton.transform.colorTransform = opColor;
			capRotate.transform.colorTransform = opColor;
			capFlip.transform.colorTransform = opColor;
			capFull.transform.colorTransform = opColor;
			capOff.transform.colorTransform = opColor;
			capTrans.transform.colorTransform = opColor;
			capClipBoard.transform.colorTransform = opColor;
			saveButton.transform.colorTransform = opColor;
			repSaveButton.transform.colorTransform = opColor;
			loadButton.transform.colorTransform = opColor;
			repLoadButton.transform.colorTransform = opColor;
			clipButton.transform.colorTransform = opColor;
			clearButton.transform.colorTransform = opColor;
			gridButton.transform.colorTransform = opColor;
			replayModeButton.transform.colorTransform = opColor;
			drawModeButton.transform.colorTransform = opColor;
			topBarColorButton.transform.colorTransform = opColor;
			dpiButton.transform.colorTransform = opColor;

			capLayer1VisibleButton.transform.colorTransform = opColor;
			capLayer2VisibleButton.transform.colorTransform = opColor;

			alphaBackup = sideBarPositionButton.alpha;
			sideBarPositionButton.transform.colorTransform = opColor;
			sideBarPositionButton.alpha = alphaBackup;
			alphaBackup = sideBarPositionButton2.alpha;
			sideBarPositionButton2.transform.colorTransform = opColor;
			sideBarPositionButton2.alpha = alphaBackup;
			sideBarOFFButton.transform.colorTransform = opColor;
			sideBarOFFButton2.transform.colorTransform = opColor;
			sideBarONButton.transform.colorTransform = opColor;
			sideBarONButton2.transform.colorTransform = opColor;
			cutPrevDataButton.transform.colorTransform = opColor;
			superUndoButton.transform.colorTransform = opColor;
			reRecordingButton.transform.colorTransform = opColor;
			aboutButton.transform.colorTransform = opColor;
			newWindowButton.transform.colorTransform = opColor;
			newWindowCloseButton.transform.colorTransform = opColor;
			replayZoomInButton.transform.colorTransform = opColor;
			replayZoomOutButton.transform.colorTransform = opColor;
			replayFitToWindowButton.transform.colorTransform = opColor;
			replayRotateButton.transform.colorTransform = opColor;
			replaySpeedSliderCursor.transform.colorTransform = opColor;
            replaySpeedSlider.transform.colorTransform = opColor;

			gridSlider.transform.colorTransform = opColor;
			gridSliderCursor.transform.colorTransform = opColor;
			gridMoveLeftButton.transform.colorTransform = opColor;
			gridMoveRightButton.transform.colorTransform = opColor;
			gridMoveUpButton.transform.colorTransform = opColor;
			gridMoveDownButton.transform.colorTransform = opColor;

			timer.textColor = op;
			timerAFkDot.textColor = op;
		}

		public function setSpeedButtonPosByValue(rSpeed:Number, maxSpeed:Number):void
		{
			if(maxSpeed <= 1) return;

			const unitX:Number = replaySpeedSlider.width/maxSpeed;
			//속도가 지수 형식으로 가서 log로 다시 역계산 해줘야함
			const exp:Number = Math.log(rSpeed)/Math.log(maxSpeed);
			const nowX:Number = exp*replaySpeedSlider.width;

			replaySpeedSliderCursor.x = replaySpeedSlider.x+nowX;
		}

		public function updateTopbarBG(stw:int):void
		{
			topbarBG.width = Math.ceil(stw/this.scaleX);
		}

		public function makeTopbarBG(color:uint):void
        {
            topbarBG.graphics.clear();
            topbarBG.graphics.beginFill(color);
            topbarBG.graphics.drawRect(0,0,10,BARSIZE);
			topbarBG.graphics.endFill();
			topbarBGColor = color;
        }

		public function checkSideBarONOFFButton(visible:Boolean,rightSidebar:Boolean):void
		{
			function check(index:int):void
			{
				const arr:Array = [sideBarONButton,
									sideBarOFFButton,
									sideBarONButton2,
									sideBarOFFButton2];
				const len:uint = arr.length;

				for(var i:uint=0;i<len;i++)
				{
					if(i === index)
					{
						(arr[i] as SimpleButton).visible = true;
					}
					else
					{
						(arr[i] as SimpleButton).visible = false;
					}
				}
			}

			if(rightSidebar)
			{
				if(visible) check(1);
				else check(0);
			}
			else
			{
				if(visible) check(3);
				else check(2);
			}
		}

		public function buttonSetVisible(mode:String,flag:Boolean,rightSidebar:Boolean=false,sidebarVisible:Boolean=false):void
		{
			const arr:Array = (mode === "replay")  ? replayModeButtons
							: (mode === "capture") ? captureModeButtons
							: (mode === "draw")    ? drawModeButtons
							: null;
			if(!arr) return;

			const len:uint = arr.length;
			var ent:DisplayObject;

			for(var i:uint=0;i<len;i++)
			{
				ent = arr[i] as DisplayObject;
				if(ent) arr[i].visible = flag;
			}

			if(mode === "draw" && flag === true)
			{
				if(rightSidebar) sideBarPositionButton.visible = false;
				else sideBarPositionButton2.visible = false;

				checkSideBarONOFFButton(sidebarVisible,rightSidebar);
			}
		}

		public function initMouseDownState():void
		{
			const arr:Vector.<SimpleButton> = new <SimpleButton>[
												captureButton,
												repCaptureButton,
												capRotate,
												capFlip,
												capFull,
												capOff,
												capTrans,
												capClipBoard,
												capLayer1VisibleButton,
												capLayer2VisibleButton,

												saveButton,
												repSaveButton,
												loadButton,
												repLoadButton,
												clipButton,
												clearButton,
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
												reRecordingButton,
												replayZoomInButton,
												replayZoomOutButton,
												replayFitToWindowButton,

												gridMoveLeftButton,
												gridMoveRightButton,
												gridMoveUpButton,
												gridMoveDownButton
												];
			const len:uint = arr.length;
			var btnDown:DisplayObjectContainer;

			for(var i:uint=0;i<len;i++)
			{
				btnDown = arr[i].downState as DisplayObjectContainer;
				btnDown.x = 2;
				btnDown.y = 2;
			}
		}

		public function initModeButtons():void //버튼위치 설정
		{
			const startX:Number = 3;
			const startY:Number = 2;
			const gap:Number = 36;

			for(var i:uint=0,len:uint=buttonOrder.length;i<len;i++)
			{
				const set:Array = buttonOrder[i];
				const len2:uint= set.length;

				for(var j:uint=0;j<len2;j++)
				{
					const ele:DisplayObject = set[j] as DisplayObject;
					if(ele)
					{
						ele.x = Math.floor(startX)+gap*i;
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
		}

		public function topMenu()
		{
			initReplaySpeedSliderWrapper();
			initGridButtonWrapper();

			capRotate.visible = false;
			capFlip.visible = false;
			capFull.visible = false;
			capOff.visible = false;
			capTrans.visible = false;
			capClipBoard.visible = false;
			drawModeButton.visible = false;

			repLoadButton.visible = false;
			repSaveButton.visible = false;
			repCaptureButton.visible = false;
			cutPrevDataButton.visible = false;
			superUndoButton.visible = false;
			reRecordingButton.visible = false;
			drawModeButton.visible = false;

			captureButton.useHandCursor = false;
			repCaptureButton.useHandCursor = false;
			capRotate.useHandCursor = false;
			capFlip.useHandCursor = false;
			capFull.useHandCursor = false;
			capOff.useHandCursor = false;
			capTrans.useHandCursor = false;
			capClipBoard.useHandCursor = false;
			saveButton.useHandCursor = false;
			repSaveButton.useHandCursor = false;
			loadButton.useHandCursor = false;
			repLoadButton.useHandCursor = false;
			clipButton.useHandCursor = false;
			clearButton.useHandCursor = false;
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
			reRecordingButton.useHandCursor = false;
			aboutButton.useHandCursor = false;
			updateButton.useHandCursor = false;
			newWindowButton.useHandCursor = false;
			newWindowCloseButton.useHandCursor = false;
			replayZoomInButton.useHandCursor = false;
			replayZoomOutButton.useHandCursor = false;
			replayFitToWindowButton.useHandCursor = false;
			replayRotateButton.useHandCursor = false;

			newWindowCloseButton.visible = false;

			sideBarOFFButton2.visible = false;
			sideBarONButton.visible = false;
			sideBarONButton2.visible = false;

			buttonOrder =   [
								[replayModeButton,drawModeButton,capOff],
								[captureButton,repCaptureButton,capFull],
								[saveButton,repSaveButton,capClipBoard],
								[loadButton,repLoadButton,capRotate],
								[clipButton,reRecordingButton,capFlip],
								[clearButton,cutPrevDataButton,capTrans],
								[gridButton,superUndoButton,capLayer1VisibleButton],
								[sideBarPositionButton,replayZoomOutButton,capLayer2VisibleButton],
								[sideBarOFFButton,replayZoomInButton],
								[topBarColorButton,replayFitToWindowButton],
								[dpiButton,replayRotateButton],
								[replaySpeedSliderWrapper,newWindowButton,newWindowCloseButton],
								[aboutButton]
							];

			drawModeButtons = [
									replayModeButton,
									captureButton,
									saveButton,
									loadButton,
									clipButton,
									clearButton,
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
									reRecordingButton,
									cutPrevDataButton,
									superUndoButton,
									repCaptureButton,
									repSaveButton,
									repLoadButton,
									replayZoomInButton,
									replayZoomOutButton,
									replayFitToWindowButton,
									replayRotateButton,
									replaySpeedSliderWrapper
								];

			captureModeButtons = [
									capOff,
									capFull,
									capRotate,
									capFlip,
									capTrans,
									capClipBoard,
									capLayer1VisibleButton,
									capLayer2VisibleButton,
								 ];
			initModeButtons();
			initMouseDownState();

			updateButton.visible = false;

			timer.y = 7;
			timer.autoSize = TextFieldAutoSize.LEFT;
			timerAFkDot.y = timer.y;
			timerAFkDot.autoSize = TextFieldAutoSize.LEFT;
			timerAFkDot.text =".";

			addChild(replaySpeedSliderWrapper);
			addChild(topbarBG);
			setChildIndex(topbarBG,0);
			cacheAsBitmap = true;

			miniTimer = new fofoTimer(stage);
		}
	}
}