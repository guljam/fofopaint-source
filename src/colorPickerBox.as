package
{
	import flash.display.Sprite;
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	import flash.display.Shape;
	import flash.ui.ContextMenu;
	import flash.display.BitmapData;

	public class colorPickerBox extends Sprite {
		public var mainColorPickerBox:Sprite = new Sprite();
		public var mainPresetButtonBox:Sprite = new Sprite();
		public var mainPickerMenuBox:Sprite = new Sprite();
		public var svBox:Sprite = new Sprite(); //hue랑 sv합친거
		public var hsvSetBoxMask:Shape = new Shape(); //메인 컬러 박스임
		public var svBase:Shape = new Shape(); //메인 컬러 박스에 뒤에 깔아주는 컬러
		public var svGradient:Shape = new Shape();//흰색 검은색 그라디언트 깔아주는 컬러 임
		public var hueColor:Sprite = new Sprite();
		public var hueColorMask:Shape = new Shape();
		public var rgbInfo:TextField;
		public var drawrPresetButton:SimpleButton;
		public var tegakiPresetButton:SimpleButton;
		public var myPaletteButton:SimpleButton;
		public var swapPositionButton:SimpleButton;
		public const rgbInfoBG:Shape = new Shape();
		private var rgbInfoBGColor:uint = 0;
		private var rgbInfoBGBorderColor:uint = 0;
		public const myPaletteBox:Sprite = new Sprite();
		public const historyBox:Sprite = new Sprite();
		public const myPaletteDragColor:Shape = new Shape();
		public var penColorButton:SimpleButton;
		public var paperColorButton:SimpleButton;
		public var transColorButton:SimpleButton;
		public var transColorButtonBmpd:BitmapData;
		public var myPaletteTransBG:SimpleButton;
		public var myPaletteTransBGBmpd:BitmapData;

		public var offsetX:Number = 0; //customcolor 박스 떨어진 위치

		public var currentColor:Sprite = new Sprite();
		public var currentColorColor:uint = 0;
		public var currentColorWidth:Number = 28;
		public var hueCursor:SimpleButton;
		public var svCursor:SimpleButton;
		// public var preset17:SimpleButton = preset17;

		public const svBoxWidth:uint = 170; //sv가로 세로 사이즈
		public const svBoxHeight:uint = 170;
		private const hueHeight:uint = 13; //hue 새로 세이즈
		private const halfPI:Number = Math.PI/2;
		private const angles:Array = [0,halfPI*2,halfPI,halfPI*3];
		private var lastMixColor:uint = 0;
		private var lastMixAlpha:uint = 0;
		private var rotateCount:uint = 0;
		public var svBaseColor:uint = 0xFF0000;

		private var panelWidth:Number = 0;
		private var panelHeight:Number = 0;

		private var rgbInfoWidth:int = 107;
		private var rgbInfoHeight:int = 19;

		private var lastRGBInfoText:String = "";
		private var firstRGBInfoColorText:String = "";

		private var colorBoxPositionSave:Array = [0,0];

		public function swapColorBoxPosition(flag:Boolean):void
		{
			if(flag)
			{
				mainColorPickerBox.y = 0;
				myPaletteBox.y = mainColorPickerBox.y+mainColorPickerBox.height+4;
			}
			else
			{
				myPaletteBox.y = colorBoxPositionSave[0];
				mainColorPickerBox.y = colorBoxPositionSave[1];
			}

			checkMainColorPickerBoxPosition(flag);
		}

		public function checkMainColorPickerBoxPosition(checkflag:Boolean):void
		{
			if(checkflag)
			{
				mainPresetButtonBox.y = myPaletteBox.y+myPaletteBox.height+3;
				mainPickerMenuBox.y = mainPresetButtonBox.y+mainPresetButtonBox.height+3;
			}
			else
			{
				mainColorPickerBox.y = myPaletteBox.y+myPaletteBox.height+4;
				mainPresetButtonBox.y = mainColorPickerBox.y+mainColorPickerBox.height+3;
				mainPickerMenuBox.y = mainPresetButtonBox.y+mainPresetButtonBox.height+3;
			}
		}

		public function selectPresetButton(type:int):void
		{
			if(type === 0)
			{
				myPaletteButton.alpha = 1.0;
				drawrPresetButton.alpha = 0.6;
				tegakiPresetButton.alpha = 0.6;
			}
			else if(type === 1)
			{
				myPaletteButton.alpha = 0.6;
				drawrPresetButton.alpha = 1.0;
				tegakiPresetButton.alpha = 0.6;
			}
			else if(type === 2)
			{
				myPaletteButton.alpha = 0.6;
				drawrPresetButton.alpha = 0.6;
				tegakiPresetButton.alpha = 1.0;
			}
		}

		public function getFirstRGBInfoColorText():String
		{
			return firstRGBInfoColorText;
		}

		public function updateFirstRGBInfoColorText():void
		{
			firstRGBInfoColorText = rgbInfo.text;
		}

		public function resetToOldRGBInfoText():void
		{
			rgbInfo.text = lastRGBInfoText;
		}

		public function updateOldRGBInfoText():void
		{
			lastRGBInfoText = rgbInfo.text;
		}

		public function setoldRGBInfoText(str:String):void
		{
			lastRGBInfoText = str;
		}

		public function getOldRGBInfoText():String
		{
			return lastRGBInfoText;
		}

		public function setPickerMode(mode:int):void
		{
			if(mode === 1)
			{
				penColorButton.alpha = 1.0;
				paperColorButton.alpha = 0.6;
			}
			else
			{
				penColorButton.alpha = 0.6;
				paperColorButton.alpha = 1.0;
			}
		}

		public function changeUIColor(color:uint):void
		{
			const baseColor:ColorTransform = new ColorTransform();
			baseColor.color = color;

			rgbInfo.textColor = color;
			var alphaSave:Number = myPaletteButton.alpha;

			myPaletteButton.transform.colorTransform = baseColor;
			myPaletteButton.alpha = alphaSave;

			alphaSave = drawrPresetButton.alpha;
			drawrPresetButton.transform.colorTransform = baseColor;
			drawrPresetButton.alpha = alphaSave;

			alphaSave = tegakiPresetButton.alpha;
			tegakiPresetButton.transform.colorTransform = baseColor;
			tegakiPresetButton.alpha = alphaSave;

			swapPositionButton.transform.colorTransform = baseColor;
			penColorButton.transform.colorTransform = baseColor;
			penColorButton.transform.colorTransform = baseColor;
			paperColorButton.transform.colorTransform = baseColor;
		}

		public function setRGBInfoColor(color:uint):void
		{
			rgbInfo.textColor = color;
		}

		public function getRGBInfo():String
		{
			return rgbInfo.text;
		}

		public function setRGBInfo(str:String):void
		{
			rgbInfo.text = str;
		}

		public function setRGBInfoVisible(flag:Boolean):void
		{
			rgbInfo.visible = flag;
		}

		public function setRGBInfoBGTransparentColorOFF():void
		{
			updateRGBInfoBG(rgbInfoBGColor,rgbInfoBGBorderColor);
		}

		public function setRGBInfoBGTransparentColorON():void
		{
			rgbInfoBG.graphics.clear();
            rgbInfoBG.graphics.lineStyle(0,0,0);
            rgbInfoBG.graphics.beginBitmapFill(transColorButtonBmpd);
            rgbInfoBG.graphics.drawRect(0,0,rgbInfoWidth,rgbInfoHeight);
            rgbInfoBG.graphics.endFill();
			rgbInfo.textColor = 0xFF0000;
		}

		public function updateRGBInfoBG(color:uint,borderColor:uint):void
		{
			rgbInfoBG.graphics.clear();
			rgbInfoBG.graphics.lineStyle(1,(borderColor === 0) ? color:borderColor);
			rgbInfoBG.graphics.beginFill(color);
			rgbInfoBG.graphics.drawRect(0,0,rgbInfoWidth,rgbInfoHeight);
			rgbInfoBG.graphics.endFill();

			rgbInfoBGColor = color;
			rgbInfoBGBorderColor = borderColor;
		}

		public function getRGBInfoBGColor():uint
		{
			return rgbInfoBGColor;
		}

		public function getCurrentColor():uint
		{
			return currentColorColor;
		}

		public function updateCurrentColor(color:uint,invColor:uint):void
		{
			if(currentColorColor !== color)
			{
				currentColorColor = color;

				currentColor.graphics.clear();
				currentColor.graphics.lineStyle(1,(invColor === 0) ? color:invColor);
				currentColor.graphics.beginFill(color);
				currentColor.graphics.drawRect(0,0,currentColorWidth,19);
				currentColor.graphics.endFill();
			}
		}

		public function changeHueColor(color:uint):void
		{
			svBase.graphics.clear();
			svBase.graphics.lineStyle(0,0,0);
			svBase.graphics.beginFill(color);
			svBase.graphics.drawRect(0,0,svBoxWidth,svBoxHeight);
			svBase.graphics.endFill();

			svBaseColor = color;
		}

		public function removeColorHistoryDragBox():void
		{
			myPaletteDragColor.visible = false;
			myPaletteDragColor.graphics.clear();
		}

		public function setColorHistoryDragBoxPos(mx:Number,my:Number):void
		{
			myPaletteDragColor.x = mx-myPaletteDragColor.width/2;
			myPaletteDragColor.y = my-myPaletteDragColor.height/2;
		}

		public function setColorHistoryDragBoxColor(color:uint,colorWidth:Number,colorHeight:Number):void
		{
			myPaletteDragColor.graphics.clear();
			myPaletteDragColor.graphics.beginFill(color);
			myPaletteDragColor.graphics.drawRect(0,0,colorWidth,colorHeight);
			myPaletteDragColor.graphics.endFill();

			setChildIndex(myPaletteDragColor,this.numChildren-1);
			myPaletteDragColor.visible = true;
		}

		private function initMyPaletteTransBGBmpd():void
		{
			const checkerPatternWidth:Number = myPaletteTransBG.width;
			const checkerPatternHeight:Number = myPaletteTransBG.height;
			const mat:Matrix = new Matrix();
			mat.scale(myPaletteTransBG.scaleX,myPaletteTransBG.scaleY);
			myPaletteTransBGBmpd = new BitmapData(checkerPatternWidth,checkerPatternHeight,false,0);
			myPaletteTransBGBmpd.draw(myPaletteTransBG,mat);
			removeChild(myPaletteTransBG);
		}

		private function initTransparentColorButtonBmpd():void
		{
			const checkerPatternWidth:Number = transColorButton.width;
			const checkerPatternHeight:Number = transColorButton.height;
			const mat:Matrix = new Matrix()
			mat.scale(transColorButton.scaleX,transColorButton.scaleY);
			transColorButtonBmpd = new BitmapData(checkerPatternWidth,checkerPatternHeight,false,0);
			transColorButtonBmpd.draw(transColorButton,mat);
		}

		//피커박스 구조
		//custom color, colorhistoryBox, drawr프리셋 따로따로 전부가 첫번째 자식들임
		public function colorPickerBox() {
			// visible = false;
			name = "pickerBox";
			initTransparentColorButtonBmpd();
			initMyPaletteTransBGBmpd();

			updateRGBInfoBG(0,0);

			var gradMatrix:Matrix = new Matrix();
			//sv기본 컬러
			svBase.graphics.lineStyle(0,0,0);
			svBase.graphics.beginFill(0xFF0000,1);
			svBase.graphics.drawRect(0,0,svBoxWidth,svBoxHeight);
			svBase.graphics.endFill();

			//흰색 그라디언트
			gradMatrix.createGradientBox(svBoxWidth, svBoxHeight, 0, 0, 0);
			svGradient.graphics.beginGradientFill(GradientType.LINEAR, [0xFFFFFF, 0xFFFFFF], [1,0], [0,255], gradMatrix);
			svGradient.graphics.drawRect(0, 0, svBoxWidth, svBoxHeight);
			svGradient.graphics.endFill();

			//검은색 그라디언트
			gradMatrix.createGradientBox(svBoxWidth, svBoxHeight, Math.PI / 2, 0, 0);
			svGradient.graphics.beginGradientFill(GradientType.LINEAR, [0x000000, 0x000000], [0,1], [0,255], gradMatrix);
			svGradient.graphics.drawRect(0, 0, svBoxWidth, svBoxHeight);
			svGradient.graphics.endFill();

			//hue 그라디언트
			gradMatrix.createGradientBox(svBoxWidth, hueHeight, 0, 0, 0); //
			hueColor.graphics.lineStyle(0,0,0);
			hueColor.graphics.beginGradientFill(GradientType.LINEAR, [0xFF0000,0xFFFF00,0x00FF00,0x00FFFF,0x0000FF,0xFF00FF,0xFF0000],
															[1,1,1,1,1,1,1],//255/6 = 42.5 x n
															[0,42.5,85,127.5,170,212.5,255], gradMatrix);
			hueColor.graphics.drawRect(0, 0, svBoxWidth, hueHeight);
			hueColor.graphics.endFill();

			hueColor.name = "hueColor";
			svBox.name = "svBox";

			mainPickerMenuBox.addChild(swapPositionButton);
			mainPickerMenuBox.addChild(paperColorButton);
			mainPickerMenuBox.addChild(penColorButton);

			penColorButton.x = 0;
			penColorButton.y = 0;
			paperColorButton.x = Math.floor(penColorButton.x+penColorButton.width+7);
			paperColorButton.y = Math.floor(penColorButton.y);
			swapPositionButton.useHandCursor = false;
			swapPositionButton.x = Math.floor(paperColorButton.x+paperColorButton.width+7);
			swapPositionButton.y = Math.floor(paperColorButton.y);

			penColorButton.useHandCursor = false;
			paperColorButton.useHandCursor = false;

			var emptyContextMenu:ContextMenu = new ContextMenu();
			emptyContextMenu.hideBuiltInItems();

			rgbInfo.contextMenu = emptyContextMenu;
			rgbInfo.restrict = "0-9";
			rgbInfo.maxChars = 15;
			rgbInfo.x = 0;
			rgbInfo.y = 0;
			rgbInfoBG.x = 0;
			rgbInfoBG.y = Math.floor(rgbInfo.y-1);
			transColorButton.x = Math.floor(rgbInfoBG.x+rgbInfoBG.width+5);
			transColorButton.y = rgbInfoBG.y;
			transColorButton.useHandCursor = false;
			currentColor.x = Math.floor(transColorButton.x+transColorButton.width);
			currentColor.y = rgbInfoBG.y;
			currentColor.name = "currentColor";

			hueColorMask.graphics.beginFill(0xFFFF0000);
			hueColorMask.graphics.drawRect(0, 0, svBoxWidth, hueHeight);
			hueColorMask.graphics.endFill();

			hueCursor.x = 0;
			hueCursor.y = -Math.floor((hueCursor.height-hueHeight)/2);
			hueCursor.mask = hueColorMask;

			hueColor.x = 0;
			hueColor.y = Math.floor(rgbInfoBG.y+rgbInfoBG.height+4);
			hueColor.addChild(hueCursor);
			hueColor.addChild(hueColorMask);
			svBox.addChild(svBase);
			svBox.addChild(svGradient);
			svBox.addChild(svCursor);
			svBox.y = Math.floor(hueColor.y+hueColor.height+4);
			hsvSetBoxMask.graphics.beginFill(0xFFFF0000);
			hsvSetBoxMask.graphics.drawRect(0, 0, svBoxWidth, svBoxHeight);
			hsvSetBoxMask.graphics.endFill();
			svBox.addChild(hsvSetBoxMask);

			mainColorPickerBox.addChild(svBox); //mainColorPickerBox svBox안에 svColor안에 svCursor
			mainColorPickerBox.addChild(hueColor);
			mainColorPickerBox.addChild(transColorButton);
			mainColorPickerBox.addChild(currentColor);
			mainColorPickerBox.addChild(rgbInfoBG);
			mainColorPickerBox.addChild(rgbInfo);
			mainColorPickerBox.addChild(historyBox);
			mainColorPickerBox.x = 0;
			mainColorPickerBox.y = 0;
			historyBox.name = "historyBox";
			historyBox.y = svBox.y+svBox.height+5;

			mainPresetButtonBox.addChild(myPaletteButton);
			mainPresetButtonBox.addChild(tegakiPresetButton);
			mainPresetButtonBox.addChild(drawrPresetButton);

			myPaletteButton.useHandCursor = false;
			myPaletteButton.x = 0;
			myPaletteButton.y = 0;

			drawrPresetButton.useHandCursor = false;
			drawrPresetButton.x = myPaletteButton.x+myPaletteButton.width+9;
			drawrPresetButton.y = myPaletteButton.y;

			tegakiPresetButton.useHandCursor = false;
			tegakiPresetButton.x = drawrPresetButton.x+drawrPresetButton.width+9;
			tegakiPresetButton.y = myPaletteButton.y;

			myPaletteBox.name = "myPaletteBox";

			addChild(myPaletteBox);
			addChild(mainColorPickerBox);
			addChild(mainPresetButtonBox);
			addChild(mainPickerMenuBox);
			addChild(myPaletteDragColor);
			myPaletteDragColor.visible = false;

			panelWidth = 180;
			panelHeight = mainPresetButtonBox.y+mainPresetButtonBox.height+3;

			colorBoxPositionSave[0] = myPaletteBox.y;
			colorBoxPositionSave[1] = mainColorPickerBox.y;

			updateCurrentColor(1,0);
			svCursor.mouseEnabled = false;
			svCursor.mask = hsvSetBoxMask;
			hueCursor.mouseEnabled = false;
		}
	}
}
