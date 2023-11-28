package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.display.Graphics;
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
		public var realTimeOFFButton:SimpleButton;
		public var realTimeONButton:SimpleButton;
		public var aboutButton:SimpleButton;
		public var updateButton:SimpleButton;
		public var replayZoomInButton:SimpleButton;
		public var replayZoomOutButton:SimpleButton;
		public var replayFitToWindowButton:SimpleButton;
		public var replayRotateButton:SimpleButton;
		public var timer:TextField;

		private var buttonOrder:Array = [];
		private var drawModeButtons:Array = [];
		private var replayModeButtons:Array = [];
		private var captureModeButtons:Array = [];
		private var topbarBG:Shape = new Shape();
		private var topbarBGColor:uint = 0;
		private var hintOKBGColor:uint = 0;
		private var hintFontColor:uint = 0;

		public var replaySpeedBarWrapper:SimpleButton;
		public var replaySpeedMoveButton:SimpleButton;
		public var replaySpeedBar:SimpleButton;
		public var replaySpeedSet:Sprite = new Sprite();

		private var isHintLocked:Boolean = false;
		private var hintWaitAnimTimer:int = 0;
		private var hintWaitAnimCount:int = 0;

		private var newWindowIconStateSaveLayerButton:Boolean = false // 뉴윈도우인지 끄기 버튼인지 구분
		private var newWindowIconStateDrawModeIcon:Boolean = false // 뉴윈도우인지 끄기 버튼인지 구분

		private const baseColor:ColorTransform = new ColorTransform();
		private const opColor:ColorTransform = new ColorTransform();

		public function setScale(scale:Number):void
		{
			scaleX = scale;
			scaleY = scale;
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

		public function setRealTimeUpdateButtonVisible(flag:Boolean):void
		{
			realTimeONButton.visible = flag;
			realTimeOFFButton.visible = !flag;
		}

		public function updateButtonVisible(flag:Boolean):void
		{
			updateButton.visible = flag;
			aboutButton.visible = !flag;
		}

		public function updateTimerPos(stw:Number):void
		{
			const limitX:Number = (replaySpeedSet.x+replaySpeedSet.width+3)*scaleX;
			var newX:Number = stw-(timer.textWidth+15)*scaleX;
			if(newX < limitX) newX = limitX;
			timer.x = newX/scaleX;
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
			realTimeOFFButton.transform.colorTransform = opColor;
			realTimeONButton.transform.colorTransform = opColor;
			replayZoomInButton.transform.colorTransform = opColor;
			replayZoomOutButton.transform.colorTransform = opColor;
			replayFitToWindowButton.transform.colorTransform = opColor;
			replayRotateButton.transform.colorTransform = opColor;
			replaySpeedMoveButton.transform.colorTransform = opColor;
            replaySpeedBar.transform.colorTransform = opColor;

			timer.textColor = op;
		}

		public function setSpeedButtonPosByValue(rSpeed:Number, maxSpeed:Number):void
		{
			if(maxSpeed <= 1) return;

			const unitX:Number = replaySpeedBar.width/maxSpeed;
			const log:Function = Math.log;
			//속도가 지수 형식으로 가서 log로 다시 역계산 해줘야함
			const exp:Number = log(rSpeed)/log(maxSpeed);
			const nowX:Number = exp*replaySpeedBar.width;

			replaySpeedMoveButton.x = replaySpeedBar.x+nowX;
		}

		public function updateTopbarBG(stw:int):void
		{
			topbarBG.width = Math.ceil(stw/scaleX);
		}

		public function makeTopbarBG(color:uint):void
        {
            const g:Graphics = topbarBG.graphics;
            g.clear();
            g.beginFill(color);
            g.drawRect(0,0,10,BARSIZE);
			g.endFill();
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
				const len:int = arr.length;

				for(var i:int=0;i<len;i++)
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

		public function initMouseDownState():void //버튼위치 설정
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
												realTimeOFFButton,
												realTimeONButton,

												cutPrevDataButton,
												superUndoButton,
												reRecordingButton,
												replayZoomInButton,
												replayZoomOutButton,
												replayFitToWindowButton
												];
			const len:int = arr.length;
			var btnDown:DisplayObjectContainer;

			for(var i:int=0;i<len;i++)
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
			const floor:Function = Math.floor;

			for(var i:uint=0,len:uint=buttonOrder.length;i<len;i++)
			{
				const set:Array = buttonOrder[i];
				const len2:uint= set.length;

				for(var j:uint=0;j<len2;j++)
				{
					const ele:DisplayObject = set[j] as DisplayObject;
					if(ele)
					{
						ele.x = floor(startX)+gap*i;
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
			replaySpeedSet.addChild(replaySpeedBar);
			replaySpeedSet.addChild(replaySpeedMoveButton);
			replaySpeedSet.addChild(replaySpeedBarWrapper);
			replaySpeedBarWrapper.x = 2;
			replaySpeedBarWrapper.y = 0;
			replaySpeedBar.x = 5;
			replaySpeedBar.y = Math.floor(replaySpeedBarWrapper.height/2-11);
			replaySpeedMoveButton.x = replaySpeedBar.x+3;
			replaySpeedMoveButton.y = Math.floor(replaySpeedBar.y+replaySpeedBar.height)+3;

			replaySpeedBarWrapper.useHandCursor = false;
			replaySpeedBar.useHandCursor = false;
			replaySpeedMoveButton.useHandCursor = false;

			capRotate.visible = false;
			capFlip.visible = false;
			capFull.visible = false;
			capOff.visible = false;
			capTrans.visible = false;
			capClipBoard.visible = false;
			drawModeButton.visible = false;
			cutPrevDataButton.alpha = 0.15;
			superUndoButton.alpha = 0.15;
			reRecordingButton.alpha = 0.15;

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
			realTimeOFFButton.useHandCursor = false;
			realTimeONButton.useHandCursor = false;
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
								[sideBarPositionButton,replayZoomInButton,capLayer2VisibleButton],
								[sideBarOFFButton,replayZoomOutButton],
								[topBarColorButton,replayFitToWindowButton],
								[dpiButton,replayRotateButton],
								[replaySpeedSet,newWindowButton,newWindowCloseButton],
								[realTimeOFFButton,realTimeONButton],
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
									realTimeOFFButton,
									realTimeONButton,
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
									replaySpeedSet
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
			realTimeOFFButton.visible = false;

			timer.y = 6;
			timer.autoSize = TextFieldAutoSize.LEFT;

			addChild(replaySpeedSet);
			addChild(topbarBG);
			setChildIndex(topbarBG,0);
			cacheAsBitmap = true;

			miniTimer = new fofoTimer(stage);
		}
	}
}