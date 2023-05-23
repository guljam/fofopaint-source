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
	import flash.utils.clearInterval;
	import flash.geom.Rectangle;

	public class topMenu extends Sprite {

		private const startX:Number = 3;
		private const startY:Number = 2;
		private const gap:Number = 36;
		public const BARSIZE:Number = 38;
		private var miniTimer:fofoTimer;

		//버튼 추가시 해야할거
		//change uicolor, mouse down state 추가, handcursor false로 하기 button order추가, 모드에 속하는거 에 추가
		public var captureButton:SimpleButton = captureButton;
		public var repCaptureButton:SimpleButton = repCaptureButton;
		public var capRotate:SimpleButton = capRotate;
		public var capFlip:SimpleButton = capFlip;
		public var capFull:SimpleButton = capFull;
		public var capOff:SimpleButton = capOff;
		public var capTrans:SimpleButton = capTrans;
		public var capClipBoard:SimpleButton = capClipBoard;
		public var saveButton:SimpleButton = saveButton;
		public var repSaveButton:SimpleButton = repSaveButton;
		public var loadButton:SimpleButton = loadButton;
		public var repLoadButton:SimpleButton = repLoadButton;
		public var clipButton:SimpleButton = clipButton;
		public var clearButton:SimpleButton = clearButton;
		public var gridButton:SimpleButton = gridButton;
		public var replayModeButton:SimpleButton = replayModeButton;
		public var drawModeButton:SimpleButton = drawModeButton;
		public var topBarColorButton:SimpleButton = topBarColorButton;
		public var dpiButton:SimpleButton = dpiButton;
		public var capLayer1VisibleButton:SimpleButton = capLayer1VisibleButton;
		public var capLayer2VisibleButton:SimpleButton = capLayer2VisibleButton;
		public var sideBarPositionButton:SimpleButton = sideBarPositionButton;
		public var sideBarPositionButton2:SimpleButton = sideBarPositionButton2;
		public var sideBarOFFButton:SimpleButton = sideBarOFFButton;
		public var sideBarOFFButton2:SimpleButton = sideBarOFFButton2;
		public var sideBarONButton:SimpleButton = sideBarONButton;
		public var sideBarONButton2:SimpleButton = sideBarONButton2;
		public var cutPrevDataButton:SimpleButton = cutPrevDataButton;
		public var superUndoButton:SimpleButton = superUndoButton;
		public var reRecordingButton:SimpleButton = reRecordingButton;
		public var newWindowButton:SimpleButton = newWindowButton;
		public var newWindowCloseButton:SimpleButton = newWindowCloseButton;
		public var aboutButton:SimpleButton = aboutButton;
		public var updateButton:SimpleButton = updateButton;
		public var replayZoomInButton:SimpleButton = replayZoomInButton;
		public var replayZoomOutButton:SimpleButton = replayZoomOutButton;
		public var replayFitToWindowButton:SimpleButton = replayFitToWindowButton;
		public var replayRotateButton:SimpleButton = replayRotateButton;
		public var topMenuInfo:TextField = topMenuInfo;
		public var timer:TextField = timer;

		private var buttonOrder:Array = [];
		private var drawModeButtons:Array = [];
		private var replayModeButtons:Array = [];
		private var captureModeButtons:Array = [];
		private var topbarInfoBG:Shape = new Shape();
		private var topbarBG:Shape = new Shape();
		private var topbarBGColor:uint = 0;
		private var hintOKBGColor:uint = 0;
		private var hintFontColor:uint = 0;

		public var replaySpeedBarWrapper:SimpleButton = replaySpeedBarWrapper;
		public var replaySpeedMoveButton:SimpleButton = replaySpeedMoveButton;
		public var replaySpeedBar:SimpleButton = replaySpeedBar;
		public var replaySpeedSet:Sprite = new Sprite();

		private var isHintLocked:Boolean = false;
		private var hintWaitAnimTimer:int = 0;
		private var hintWaitAnimCount:int = 0;

		private var newWindowIconStateSaveLayerButton:Boolean = false // 뉴윈도우인지 끄기 버튼인지 구분
		private var newWindowIconStateDrawModeIcon:Boolean = false // 뉴윈도우인지 끄기 버튼인지 구분

		public function getHintBGHeight():Number
		{
			return topbarInfoBG.height;
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
			const limitX:Number = (replaySpeedSet.x+replaySpeedSet.width-10)*scaleX;
			var newX:Number = stw-(timer.textWidth+15)*scaleX;
			if(newX < limitX) newX = limitX;			
			timer.x = newX/scaleX;
		}

		public function changeUIColor(base:uint,op:uint,hintOKColor:uint):void
		{
			const o:ColorTransform = new ColorTransform();
			const b:ColorTransform = new ColorTransform();
			var alphaBackup:Number = 0.0;

			o.color = op;
			b.color = base;
			topbarBGColor = base;
			hintOKBGColor = hintOKColor;
			hintFontColor = op;

			topbarBG.transform.colorTransform = b;
			captureButton.transform.colorTransform = o;
			repCaptureButton.transform.colorTransform = o;
			capRotate.transform.colorTransform = o;
			capFlip.transform.colorTransform = o;
			capFull.transform.colorTransform = o;
			capOff.transform.colorTransform = o;
			capTrans.transform.colorTransform = o;
			capClipBoard.transform.colorTransform = o;
			saveButton.transform.colorTransform = o;
			repSaveButton.transform.colorTransform = o;
			loadButton.transform.colorTransform = o;
			repLoadButton.transform.colorTransform = o;
			clipButton.transform.colorTransform = o;
			clearButton.transform.colorTransform = o;
			gridButton.transform.colorTransform = o;
			replayModeButton.transform.colorTransform = o;
			drawModeButton.transform.colorTransform = o;
			topBarColorButton.transform.colorTransform = o;
			dpiButton.transform.colorTransform = o;

			capLayer1VisibleButton.transform.colorTransform = o;
			capLayer2VisibleButton.transform.colorTransform = o;

			alphaBackup = sideBarPositionButton.alpha;
			sideBarPositionButton.transform.colorTransform = o;
			sideBarPositionButton.alpha = alphaBackup;
			alphaBackup = sideBarPositionButton2.alpha;
			sideBarPositionButton2.transform.colorTransform = o;
			sideBarPositionButton2.alpha = alphaBackup;
			sideBarOFFButton.transform.colorTransform = o;
			sideBarOFFButton2.transform.colorTransform = o;
			sideBarONButton.transform.colorTransform = o;
			sideBarONButton2.transform.colorTransform = o;
			cutPrevDataButton.transform.colorTransform = o;
			superUndoButton.transform.colorTransform = o;
			reRecordingButton.transform.colorTransform = o;
			aboutButton.transform.colorTransform = o;
			newWindowButton.transform.colorTransform = o;
			newWindowCloseButton.transform.colorTransform = o;
			replayZoomInButton.transform.colorTransform = o;
			replayZoomOutButton.transform.colorTransform = o;
			replayFitToWindowButton.transform.colorTransform = o;
			replayRotateButton.transform.colorTransform = o;
			replaySpeedMoveButton.transform.colorTransform = o;
            replaySpeedBar.transform.colorTransform = o;

			if(isHintLocked === false)
			{
				topbarInfoBG.transform.colorTransform = b;
				topMenuInfo.textColor = op;
			}
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

		public function hintOFF():void
		{	
			if(isHintLocked) return;
			topMenuInfo.visible = false;
            topbarInfoBG.visible = false;
		}

		public function changeHintYPos(offset:Number):void
		{
			topMenuInfo.y = offset-4*scaleX;
			topbarInfoBG.y = offset-4;
		}

		public function resetHintColor():void
		{
			const c:ColorTransform = new ColorTransform();
			c.color = topbarBGColor;
			topbarInfoBG.transform.colorTransform = c;
			topMenuInfo.textColor = hintFontColor;
		}

		public function hintTimeOFFWithColor(time:Number=3.0):void
		{
			isHintLocked = false;
			hintTimeOFF();
			miniTimer.addByName("topBarHintColorOFFTimer",time,false,resetHintColor);
		}

		public function hintTimeOFF():void
		{
			miniTimer.addByName("topBarHintOFFTimer",3.0,false,hintOFF);
		}

		public function hintLoadError():void
		{
			miniTimer.remove("topBarHintColorOFFTimer");
			miniTimer.remove("topBarHintOFFTimer");
			clearInterval(hintWaitAnimTimer);
			isHintLocked = false;
			hint("Failed to load file",replayModeButton,true);
			setHintColor("red");
			isHintLocked = true;
			hintTimeOFFWithColor();
		}

		public function hintSaveError():void
		{
			miniTimer.remove("topBarHintColorOFFTimer");
			miniTimer.remove("topBarHintOFFTimer");
			clearInterval(hintWaitAnimTimer);
			isHintLocked = false;
			hint("Failed to save file",replayModeButton,true);
			setHintColor("red");
			isHintLocked = true;
			hintTimeOFFWithColor(7000);
		}

		public function setHintColor(colorStr:String):void
		{
			const c:ColorTransform = new ColorTransform()

			if(colorStr === "green")
			{
				c.color = hintOKBGColor;
				topbarInfoBG.transform.colorTransform = c;
				topMenuInfo.textColor = 0;
			}
			else if(colorStr === "red")
			{
				c.color = 0xE03B35;
				topbarInfoBG.transform.colorTransform = c;
				topMenuInfo.textColor = 0;
			}
			else if(colorStr === "yellow")
			{
				c.color = 0xF4CD6C;
				topbarInfoBG.transform.colorTransform = c;
				topMenuInfo.textColor = 0;
			}
		}

		public function updateHintBGWidth(stw:Number):void
		{
			topbarInfoBG.width = stw/scaleX;
		}

		public function hintTime(str:String,target:DisplayObject):void
		{
			hint(str,target,true);
			hintTimeOFF();
		}	

		public function hint(str:String,target:DisplayObject,timed:Boolean=false):void
		{
			if(isHintLocked) return;

			if(target)
			{
				if(!timed) miniTimer.remove("topBarHintOFFTimer");

				topMenuInfo.text = str;
				topMenuInfo.width = topMenuInfo.textWidth+4;
				topMenuInfo.x = (target.x+target.width/2-topMenuInfo.textWidth/2 < 5) ? 6
																					  : target.x+target.width/2-topMenuInfo.width/2; //17은 아이콘 크기의 절반임;

				if((topMenuInfo.x+topMenuInfo.textWidth)*scaleX > stage.stageWidth-3)
				{
					const b:Rectangle = topMenuInfo.getBounds(stage);
					topMenuInfo.x = topMenuInfo.x-(b.right-(stage.stageWidth-3))/scaleX;
				}

				topbarInfoBG.width = stage.stageWidth;
				topbarInfoBG.visible = true;
				topMenuInfo.visible = true;
			}
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

												cutPrevDataButton,
												superUndoButton,
												reRecordingButton,
												replayZoomInButton,
												replayZoomOutButton,
												replayFitToWindowButton,
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
			const floor:Function = Math.floor;
			const _buttonOrder:Array = buttonOrder;
			const _startX:Number = startX;
			const _startY:Number = 4;//topMenuInfo.height+1//startY;
			const _gap:Number = gap;

			for(var i:uint=0,len:uint=_buttonOrder.length;i<len;i++)
			{
				const set:Array = _buttonOrder[i];
				const len2:uint= set.length;

				for(var j:uint=0;j<len2;j++)
				{
					const ele:DisplayObject = set[j] as DisplayObject;
					if(ele)
					{
						ele.x = floor(_startX)+_gap*i;
						ele.y = _startY;
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
			replaySpeedBarWrapper.x = 0;
			replaySpeedBarWrapper.y = 2;
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
			topMenuInfo.width = 500;
			topMenuInfo.x = startX;

			timer.y = 6;

			topbarInfoBG.graphics.clear();
			topbarInfoBG.graphics.lineStyle(0,0,0);
			topbarInfoBG.graphics.beginFill(0xCCCCCC);
			topbarInfoBG.graphics.drawRect(0,0,10,10);
			topbarInfoBG.graphics.endFill();
			topbarInfoBG.x = 0;
			topbarInfoBG.height = Math.floor(topMenuInfo.textHeight+3);

			changeHintYPos(0);

			addChild(replaySpeedSet);
			addChild(topbarBG);
			addChild(topbarInfoBG);
			setChildIndex(topbarBG,0);
			setChildIndex(topMenuInfo,numChildren-1);
			cacheAsBitmap = true;

			miniTimer = new fofoTimer(stage);
		}
	}
}