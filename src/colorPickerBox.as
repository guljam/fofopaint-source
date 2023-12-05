package
{
	import flash.display.Sprite;
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	import flash.display.Shape;
	import flash.ui.ContextMenu;
	import flash.display.BitmapData;

	public class colorPickerBox extends Sprite {
		public var mainColorPickerBox:Sprite = new Sprite();
		public var svBox:Sprite = new Sprite(); //hue랑 sv합친거
		public var hsvSetBoxMask:Shape = new Shape(); //메인 컬러 박스임
		public var svBase:Shape = new Shape(); //메인 컬러 박스에 뒤에 깔아주는 컬러
		public var svGradient:Shape = new Shape();//흰색 검은색 그라디언트 깔아주는 컬러 임
		public var hueColor:Sprite = new Sprite();
		public var hueColorMask:Shape = new Shape();
		public var drawrPresetBox:Sprite = new Sprite();
		public var tegakiPresetBox:Sprite = new Sprite();
		public var mainPresetBox:Sprite = new Sprite();
		public var rgbInfo:TextField;
		public var drawrText:SimpleButton;
		public var tegakiText:SimpleButton;
		public var colorHistoryText:SimpleButton;
		public var infoColorPicker:SimpleButton;
		public const rgbInfoBG:Shape = new Shape();
		private var rgbInfoBGColor:uint = 0;
		private var rgbInfoBGBorderColor:uint = 0;
		public const colorHistoryBox:Sprite = new Sprite();//컬러 히스토리
		public const colorHistoryDragBox:Shape = new Shape();
		public var penColorButton:SimpleButton;
		public var paperColorButton:SimpleButton;
		public var transColorButton:SimpleButton;
		public var transColorButtonBmpd:BitmapData;

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

		private const baseColor:ColorTransform = new ColorTransform();

		private var lastRGBInfoText:String = "";
		private var firstRGBInfoColorText:String = "";

		public function drawHistoryBoxBG():void
		{
			colorHistoryBox.graphics.clear();
			colorHistoryBox.graphics.beginFill(0xFF0000,0.0);
			colorHistoryBox.graphics.drawRect(0,0,170,34);
			colorHistoryBox.graphics.endFill();
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
			baseColor.color = color;

			rgbInfo.textColor = color;

			colorHistoryText.transform.colorTransform = baseColor
			drawrText.transform.colorTransform = baseColor
			tegakiText.transform.colorTransform = baseColor

			infoColorPicker.transform.colorTransform = baseColor;
			penColorButton.transform.colorTransform = baseColor;
			penColorButton.transform.colorTransform = baseColor;
			paperColorButton.transform.colorTransform = baseColor;
		}

		private function initTegakiPreset():void
		{
			const tegakiColor:Vector.<uint> = new <uint> [
															0x800000,
															0xF1E1D7,
															0x4B3D38,
															0xEAE5D5,
															0x394C44,
															0xD0EBDE,
															0x313768,
															0xD5E9F3,
															0xA80515,
															0xF1D0D0
														 ];
			const width:Number = 17;
			const height:Number = 19;
			var g:Graphics;
			var colorT:ColorTransform;
			var btn:Sprite;

			for(var i:uint=0;i<10;i+=2)
			{
				btn = new Sprite();
				btn.name = "tegaki"+(i/2);

				g = btn.graphics;
				g.lineStyle(0,0,0);
				g.beginFill(tegakiColor[i]);
				g.drawRect(0,0,width,height);
				g.beginFill(tegakiColor[i+1]);
				g.drawRect(width,0,width,height);
				g.endFill();

				btn.x = i*width;
				tegakiPresetBox.addChild(btn);
			}
		}

		private function initDrawrPreset():void
		{
			const drawrColor:Vector.<uint> = new <uint> [
															0xFFFFFF,
															0xC0C0C0,
															0xFF3B21,//빨간색
															0xFFBD16,
															0xF5F30F,
															0xA5E975,
															0x71DBFD,
															0xFA80F9,
															0x000000,
															0x808080,
															0x8E0000,//갈색
															0xFFCC99,
															0x877D30,
															0x008F47,
															0x313BCD,
															0xC02E97,
															0x3F037E
														];

			const width:Number = 17;
			const height:Number = 19;
			const len:int = drawrColor.length;

			var posX:Number = 0;
			var posY:Number = 0;
			var btn:Sprite;
			var colorT:ColorTransform;

			for(var i:uint=0;i<len;i++)
			{
				btn = new Sprite();
				btn.name = "drawr"+i;
				btn.graphics.lineStyle(0,0,0);
				btn.graphics.beginFill(0);
				btn.graphics.drawRect(0,0,width,height);
				btn.graphics.endFill();

				colorT = new ColorTransform()
				colorT.color = drawrColor[i];

				btn.transform.colorTransform = colorT;
				btn.x = (i*width)-posX;
				btn.y = posY;

				if(i == 7)
				{
					posX = width*8;
					posY = height;
				}

				drawrPresetBox.addChild(btn);
			}
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
			colorHistoryDragBox.visible = false;
			colorHistoryDragBox.graphics.clear();
		}

		public function setColorHistoryDragBoxPos(mx:Number,my:Number):void
		{
			colorHistoryDragBox.x = mx-colorHistoryDragBox.width/2;
			colorHistoryDragBox.y = my-colorHistoryDragBox.height/2;
		}

		public function setColorHistoryDragBoxColor(color:uint):void
		{
			colorHistoryDragBox.graphics.clear();
			colorHistoryDragBox.graphics.beginFill(color);
			colorHistoryDragBox.graphics.drawRect(0,0,17,19);
			colorHistoryDragBox.graphics.endFill();

			setChildIndex(colorHistoryDragBox,this.numChildren-1);
			colorHistoryDragBox.visible = true;
		}

		private function inittransColorButtonBmpd():void
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
			initDrawrPreset();
			initTegakiPreset();
			inittransColorButtonBmpd();

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

			infoColorPicker.mouseEnabled = false;
			infoColorPicker.x = 0;
			infoColorPicker.y = 0;

			paperColorButton.x = Math.floor(infoColorPicker.x+infoColorPicker.width+12);
			paperColorButton.y = Math.floor(infoColorPicker.y-7);
			penColorButton.x = Math.floor(paperColorButton.x+paperColorButton.width+5);
			penColorButton.y = Math.floor(paperColorButton.y);

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
			mainColorPickerBox.x = 0;
			mainColorPickerBox.y = Math.floor(penColorButton.y+penColorButton.height+6);

			colorHistoryText.mouseEnabled = false;
			colorHistoryText.x = 0;
			colorHistoryText.y = 2;
			colorHistoryBox.x = 1;
			colorHistoryBox.y = Math.floor(colorHistoryText.y+colorHistoryText.height)-14;
			colorHistoryBox.name = "colorHistoryBox";
			drawHistoryBoxBG();

			drawrText.mouseEnabled = false;
			drawrText.x = colorHistoryText.x;
			drawrText.y = Math.floor(colorHistoryBox.y+colorHistoryBox.height+10);
			drawrPresetBox.x = colorHistoryBox.x;
			drawrPresetBox.y =Math.floor(drawrText.y+drawrText.height);

			tegakiText.mouseEnabled = false;
			tegakiText.x = colorHistoryText.x;
			tegakiText.y = Math.floor(drawrPresetBox.y+drawrPresetBox.height+10);
			tegakiPresetBox.x = colorHistoryBox.x;
			tegakiPresetBox.y = Math.floor(tegakiText.y+tegakiText.height);

			colorHistoryDragBox.visible = false;

			mainPresetBox.addChild(colorHistoryText);
			mainPresetBox.addChild(drawrText);
			mainPresetBox.addChild(tegakiText);
			mainPresetBox.addChild(colorHistoryBox);
			mainPresetBox.addChild(drawrPresetBox);
			mainPresetBox.addChild(tegakiPresetBox);
			mainPresetBox.x = colorHistoryText.x;
			mainPresetBox.y = Math.floor(mainColorPickerBox.y+mainColorPickerBox.height+5);
			addChild(mainColorPickerBox);
			addChild(mainPresetBox);
			addChild(colorHistoryDragBox);

			panelWidth = 180;
			panelHeight = mainPresetBox.y+mainPresetBox.height+3;

			updateCurrentColor(1,0);
			svCursor.mouseEnabled = false;
			svCursor.mask = hsvSetBoxMask;
			hueCursor.mouseEnabled = false;
		}
	}
}
