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
	import flash.geom.Point;

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
		public var colorPickerInfo:TextField = colorPickerInfo;
		public var rgbInfo:TextField = rgbInfo;
		public var drawrText:TextField = drawrText;
		public var tegakiText:TextField = tegakiText;
		public var colorHistoryText:TextField = colorHistoryText;
		private const rgbInfoBG:Shape = new Shape();
		public var rgbInfoBGColor:uint = 0;
		public const colorHistoryBox:Sprite = new Sprite()//컬러 히스토리
		public var penColorButton:SimpleButton = penColorButton;
		public var paperColorButton:SimpleButton = paperColorButton;
		public var colorHistoryBoxBG:Sprite = new Sprite();

		public var offsetX:Number = 0; //customcolor 박스 떨어진 위치

		public var currentColor:Sprite = new Sprite();
		public var currentColorColor:uint = 0;
		public var currentColorWidth:Number = 28;
		private var lastCurrentShape:int = 0;
		public var hueCursor:SimpleButton = hueCursor;
		public var svCursor:SimpleButton = svCursor;
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

		private var rgbInfoWidth:int = 136;
		private var rgbInfoHeight:int = 19;

		public function colorPickerBox() {
			// visible = false;
			name = "pickerBox";
			initDrawrPreset();
			initTegakiPreset();
			updateRGBInfoBG(0,0);

			const floor:Function = Math.floor;
			var gradMatrix:Matrix = new Matrix();
			var g:Graphics;

			//sv기본 컬러
			svBase.graphics.lineStyle(0,0,0);
			svBase.graphics.beginFill(0xFF0000,1);
			svBase.graphics.drawRect(0,0,svBoxWidth,svBoxHeight);
			svBase.graphics.endFill();

			//흰색 그라디언트
			gradMatrix.createGradientBox(svBoxWidth, svBoxHeight, 0, 0, 0);
			g = svGradient.graphics;
			g.beginGradientFill(GradientType.LINEAR, [0xFFFFFF, 0xFFFFFF], [1,0], [0,255], gradMatrix);
			g.drawRect(0, 0, svBoxWidth, svBoxHeight);
			g.endFill();

			//검은색 그라디언트
			gradMatrix.createGradientBox(svBoxWidth, svBoxHeight, Math.PI / 2, 0, 0);
			g.beginGradientFill(GradientType.LINEAR, [0x000000, 0x000000], [0,1], [0,255], gradMatrix);
			g.drawRect(0, 0, svBoxWidth, svBoxHeight);
			g.endFill();

			//hue 그라디언트
			gradMatrix.createGradientBox(svBoxWidth, hueHeight, 0, 0, 0); //
			g = hueColor.graphics;
			g.lineStyle(0,0,0);
			g.beginGradientFill(GradientType.LINEAR, [0xFF0000,0xFFFF00,0x00FF00,0x00FFFF,0x0000FF,0xFF00FF,0xFF0000],
															[1,1,1,1,1,1,1],//255/6 = 42.5 x n
															[0,42.5,85,127.5,170,212.5,255], gradMatrix);
			g.drawRect(0, 0, svBoxWidth, hueHeight);
			g.endFill();

			hueColor.name = "hueColor";
			svBox.name = "svBox";

			colorPickerInfo.x = -2;
			colorPickerInfo.y = 0;
			colorPickerInfo.text = "Color";
			colorPickerInfo.width = svBoxWidth;

			paperColorButton.x = floor(colorPickerInfo.x+colorPickerInfo.textWidth+62);
			paperColorButton.y = floor(colorPickerInfo.y);
			penColorButton.x = floor(paperColorButton.x+paperColorButton.width+5);
			penColorButton.y = floor(paperColorButton.y);

			penColorButton.useHandCursor = false;
			paperColorButton.useHandCursor = false;

			rgbInfo.x = 0
			rgbInfo.y = 0;
			rgbInfoBG.x = 0;
			rgbInfoBG.y = floor(rgbInfo.y-1);
			currentColor.x = floor(rgbInfoBG.x+rgbInfoBG.width+4);
			currentColor.y = floor(rgbInfoBG.y);
			currentColor.name = "currentColor";

			g = hueColorMask.graphics;
			g.beginFill(0xFFFF0000);
			g.drawRect(0, 0, svBoxWidth, hueHeight);
			g.endFill();

			hueCursor.x = 0;
			hueCursor.y = -floor((hueCursor.height-hueHeight)/2);
			hueCursor.mask = hueColorMask;
			
			hueColor.x = 0;
			hueColor.y = floor(rgbInfoBG.y+rgbInfoBG.height+4);
			hueColor.addChild(hueCursor);
			hueColor.addChild(hueColorMask);

			svBox.addChild(svBase);
			svBox.addChild(svGradient);
			svBox.addChild(svCursor);
			svBox.y = floor(hueColor.y+hueColor.height+4);
			g = hsvSetBoxMask.graphics;
			g.beginFill(0xFFFF0000);
			g.drawRect(0, 0, svBoxWidth, svBoxHeight);
			g.endFill();
			svBox.addChild(hsvSetBoxMask);

			mainColorPickerBox.addChild(svBox); //mainColorPickerBox svBox안에 svColor안에 svCursor
			mainColorPickerBox.addChild(hueColor);
			mainColorPickerBox.addChild(currentColor);
			mainColorPickerBox.addChild(rgbInfoBG);
			mainColorPickerBox.addChild(rgbInfo);
			mainColorPickerBox.x = 0;
			mainColorPickerBox.y = floor(penColorButton.y+penColorButton.height+5);

			colorHistoryText.x = -1;
			colorHistoryText.y = -5;
			colorHistoryBox.x = 1;
			colorHistoryBox.y = floor(colorHistoryText.y+colorHistoryText.height);

			colorHistoryBox.name = "colorHistoryBox";
			g = colorHistoryBoxBG.graphics;
			g.lineStyle(0,0,0);
			g.beginFill(0xFFFFFF,0);
			g.drawRect(0,0,170,20); //17픽셀 10개임
			g.endFill();

			drawrText.x = colorHistoryText.x;
			drawrText.y = floor(colorHistoryBox.y+colorHistoryBox.height+21);
			drawrPresetBox.x = colorHistoryBox.x;
			drawrPresetBox.y =floor(drawrText.y+drawrText.height-1);

			tegakiText.x = colorHistoryText.x;
			tegakiText.y = floor(drawrPresetBox.y+drawrPresetBox.height+1);
			tegakiPresetBox.x = colorHistoryBox.x;
			tegakiPresetBox.y = floor(tegakiText.y+tegakiText.height);

			mainPresetBox.addChild(colorHistoryText);
			mainPresetBox.addChild(colorHistoryBox);
			mainPresetBox.addChild(drawrText);
			mainPresetBox.addChild(drawrPresetBox);
			mainPresetBox.addChild(tegakiText);
			mainPresetBox.addChild(tegakiPresetBox);
			mainPresetBox.x = colorHistoryText.x;
			mainPresetBox.y = floor(mainColorPickerBox.y+mainColorPickerBox.height+5);
			addChild(mainColorPickerBox);
			addChild(mainPresetBox);

			panelWidth = 180;
			panelHeight = mainPresetBox.y+mainPresetBox.height+3;

			updateCurrentColor(0,0);
			svCursor.mask = hsvSetBoxMask;
			svCursor.useHandCursor = false;
			hueCursor.useHandCursor = false;
		}

		//피커박스 구조
		//custom color, colorhistoryBox, drawr프리셋 따로따로 전부가 첫번째 자식들임
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
			const c:ColorTransform = new ColorTransform();
			const def:ColorTransform = new ColorTransform();
			c.color = color;

			rgbInfo.textColor = color;
			colorPickerInfo.textColor = color;
			colorHistoryText.textColor = color;
			drawrText.textColor = color;
			tegakiText.textColor = color;
			
			penColorButton.transform.colorTransform = c;
			paperColorButton.transform.colorTransform = c;
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

			for(var i:int=0;i<10;i+=2)
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
			const floor:Function = Math.floor;
			var colorT:ColorTransform;
			var g:Graphics;
			var btn:Sprite;
			var x:Number = 0;
			var y:Number = 0;
			const width:Number = 17;
			const height:Number = 19;
			const offsetX:Number = 0;
			const offsetY:Number = 0;

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
			const len:int = drawrColor.length;
			for(var i:uint=0;i<len;i++)
			{
				btn = new Sprite();
				btn.name = "drawr"+i;
				g = btn.graphics;
				g.lineStyle(0,0,0);
				g.beginFill(0);
				g.drawRect(0,0,width,height);
				g.endFill();
				colorT = new ColorTransform()
				colorT.color = drawrColor[i];
				btn.transform.colorTransform = colorT;
				btn.x = (i*width)-x;
				btn.y = y;

				if(i == 7)
				{
					x = width*8;
					y = height;
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

		public function updateRGBInfoBG(color:uint,borderColor:uint):void
		{
			const g:Graphics = rgbInfoBG.graphics;

			g.clear();
			g.lineStyle(1,(borderColor === 0) ? color:borderColor);
			g.beginFill(color);
			g.drawRect(0,0 ,rgbInfoWidth ,rgbInfoHeight);
			g.endFill();

			rgbInfoBGColor = color;
		}

		public function updateCurrentColor(color:uint,invColor:uint):void
		{
			const g:Graphics = currentColor.graphics;
			currentColorColor = color;

			g.clear();
			g.lineStyle(1,(invColor === 0) ? color:invColor);
			g.beginFill(color);
			g.drawRoundRectComplex(0,0,currentColorWidth,19,0,lastCurrentShape,0,0);
			g.endFill();
		}

		public function changeHueColor(color:uint):void
		{
			const g:Graphics = svBase.graphics;

			g.clear();
			g.lineStyle(0,0,0);
			g.beginFill(color);
			g.drawRect(0,0,svBoxWidth,svBoxHeight);
			g.endFill();

			svBaseColor = color;
		}
	}
}
