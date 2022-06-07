package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObject;
	import flash.utils.setTimeout;
	import flash.utils.clearTimeout;
	import flash.display.DisplayObjectContainer;

	public class topMenu extends Sprite {
		private const startX:Number = 3;
		private const startY:Number = 2;
		private const gap:Number = 36;
		public const BARSIZE:Number = 38;

		public var captureButton:SimpleButton = captureButton;
		public var repCaptureButton:SimpleButton = repCaptureButton;
		public var capRotate:SimpleButton = capRotate;
		public var capFlip:SimpleButton = capFlip;
		public var capFull:SimpleButton = capFull;
		public var capOff:SimpleButton = capOff;
		public var capTrans:SimpleButton = capTrans;
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
		public var sideBarPositionButton:SimpleButton = sideBarPositionButton;
		public var sideBarPositionButton2:SimpleButton = sideBarPositionButton2;
		public var sideBarOFFButton:SimpleButton = sideBarOFFButton;
		public var sideBarOFFButton2:SimpleButton = sideBarOFFButton2;
		public var sideBarONButton:SimpleButton = sideBarONButton;
		public var sideBarONButton2:SimpleButton = sideBarONButton2;
		public var cutPrevDataButton:SimpleButton = cutPrevDataButton;
		public var superUndoButton:SimpleButton = superUndoButton;
		public var reRecordingButton:SimpleButton = reRecordingButton;
		public var aboutButton:SimpleButton = aboutButton;
		public var updateButton:SimpleButton = updateButton;
		public var replayZoomInButton:SimpleButton = replayZoomInButton;
		public var replayZoomOutButton:SimpleButton = replayZoomOutButton;
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
		private var hintTimer:int = 0;
		private var hintTimer2:int = 0;
		private var hintOKBGColor:uint = 0;
		private var hintFontColor:uint = 0;

		public var replaySpeedBarWrapper:SimpleButton = replaySpeedBarWrapper;
		public var replaySpeedMoveButton:SimpleButton = replaySpeedMoveButton;
		public var replaySpeedBar:SimpleButton = replaySpeedBar;
		public var replaySpeedSet:Sprite = new Sprite();
		
		public function updateButtonVisible(flag:Boolean):void
		{
			updateButton.visible = flag;
			aboutButton.visible = !flag;
		}
		public function updateTimerPos(stw:Number):void
		{
			const limitX:Number = replaySpeedSet.x+replaySpeedSet.width-10;
			var newX:Number = stw-timer.textWidth-15;
			if(newX < limitX) newX = limitX;
			
			timer.x = newX;
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
			topbarInfoBG.transform.colorTransform = b;
			captureButton.transform.colorTransform = o;
			repCaptureButton.transform.colorTransform = o;
			capRotate.transform.colorTransform = o;
			capFlip.transform.colorTransform = o;
			capFull.transform.colorTransform = o;
			capOff.transform.colorTransform = o;
			capTrans.transform.colorTransform = o;
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
			replayZoomInButton.transform.colorTransform = o;
			replayZoomOutButton.transform.colorTransform = o;
			replayRotateButton.transform.colorTransform = o;
			replaySpeedMoveButton.transform.colorTransform = o;
            replaySpeedBar.transform.colorTransform = o;
			
			topMenuInfo.textColor = op;
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
			topMenuInfo.visible = false;
            topbarInfoBG.visible = false;
		}

		public function changeHintYPos(offset:Number):void
		{
			topMenuInfo.y = offset-3;
			topbarInfoBG.y = offset-4;
		}

		public function resetHintColor():void
		{
			const c:ColorTransform = new ColorTransform();
			c.color = topbarBGColor;
			topbarInfoBG.transform.colorTransform = c;
			topMenuInfo.textColor = hintFontColor;
		}

		public function hintColorTimeOff():void
		{
			hintTimeOff();

			clearTimeout(hintTimer2);
			hintTimer2 = setTimeout(function():void
			{
				resetHintColor();
			},4000);
		}

		public function hintTimeOff():void
		{
			clearTimeout(hintTimer);
			hintTimer = setTimeout(function():void
			{
				hintOFF();
			},3000);
		}

		public function hintTimeOK(str:String):void
		{
			hint(str,replayModeButton,true,1);
			hintColorTimeOff();
		}

		public function hintTimeError(str:String):void
		{
			hint(str,replayModeButton,true,2);
			hintColorTimeOff();
		}

		public function hintTime(str:String,target:DisplayObject):void
		{
			hint(str,target,true);
			hintTimeOff();
		}

		public function hint(str:String,target:DisplayObject,timed:Boolean=false,colorFlag:int=0):void
		{
			if(target)
			{
				if(!timed)
				{
					clearTimeout(hintTimer);
				}

				const c:ColorTransform = new ColorTransform()

				if(colorFlag === 1)
				{
					c.color = hintOKBGColor;
					topbarInfoBG.transform.colorTransform = c;
					topMenuInfo.textColor = 0;
				}
				else if(colorFlag === 2)
				{
					c.color = 0xFD7A80;
					topbarInfoBG.transform.colorTransform = c;
					topMenuInfo.textColor = 0;
				}

				topMenuInfo.text = str;
				topMenuInfo.width = topMenuInfo.textWidth+4;
				topMenuInfo.x = (target.x+target.width/2-topMenuInfo.textWidth/2 < 5) ? 5 : target.x+target.width/2-topMenuInfo.width/2; //17은 아이콘 크기의 절반임;
				if(topMenuInfo.x+topMenuInfo.width > stage.stageWidth-3)
				{
					topMenuInfo.x -= (topMenuInfo.x+topMenuInfo.width)-(stage.stageWidth-3);
				}
				topbarInfoBG.width = stage.stageWidth;
				topbarInfoBG.visible = true;
				topMenuInfo.visible = true;
			}
		}

		public function updateTopbarBG(stw:int):void
		{
			topbarBG.width = stw;
		}
		
		public function makeTopbarBG(color:uint):void
        {
            const g:Graphics = topbarBG.graphics;
            g.clear();
            g.beginFill(color);
            g.drawRect(0,0,10,BARSIZE)
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
												sideBarPositionButton,
												sideBarPositionButton2,
												sideBarOFFButton,
												sideBarOFFButton2,
												sideBarONButton,
												sideBarONButton2,
												aboutButton,

												cutPrevDataButton,
												superUndoButton,
												reRecordingButton,
												replayZoomInButton,
												replayZoomOutButton,
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
			replaySpeedMoveButton.x = replaySpeedBar.x;
			replaySpeedMoveButton.y = Math.floor(replaySpeedBar.y+replaySpeedBar.height)+2;

			replaySpeedBarWrapper.useHandCursor = false;
			replaySpeedBar.useHandCursor = false;
			replaySpeedMoveButton.useHandCursor = false;

			capRotate.visible = false;
			capFlip.visible = false;
			capFull.visible = false;
			capOff.visible = false;
			capTrans.visible = false;
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
			replayZoomInButton.useHandCursor = false;
			replayZoomOutButton.useHandCursor = false;
			replayRotateButton.useHandCursor = false;

			sideBarOFFButton2.visible = false;
			sideBarONButton.visible = false;
			sideBarONButton2.visible = false;

			buttonOrder =   [ 
								[replayModeButton,drawModeButton,capOff],
								[captureButton,capFull,repCaptureButton],
								[saveButton,repSaveButton,capRotate],
								[loadButton,repLoadButton,capFlip],
								[clipButton,reRecordingButton,capTrans],
								[clearButton,superUndoButton],
								[gridButton,cutPrevDataButton],
								[sideBarPositionButton,replayZoomInButton],
								[sideBarOFFButton,replayZoomOutButton],
								[topBarColorButton,replayRotateButton],
								[aboutButton,replaySpeedSet]
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
									sideBarPositionButton,
									sideBarPositionButton2,
									sideBarOFFButton,
									sideBarOFFButton2,
									sideBarONButton,
									sideBarONButton2,
									aboutButton
							  ];

			replayModeButtons = [
									drawModeButton,
									reRecordingButton,
									superUndoButton,
									cutPrevDataButton,
									repCaptureButton,
									repSaveButton,
									repLoadButton,
									replayZoomInButton,
									replayZoomOutButton,
									replayRotateButton,
									replaySpeedSet
								];

			captureModeButtons = [
									capOff,
									capFull,
									capRotate,
									capFlip,
									capTrans
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
		}
	}
}