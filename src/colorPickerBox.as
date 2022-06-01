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
	import flash.display.DisplayObjectContainer;

	public class colorPickerBox extends Sprite {
		public var cpreset1:SimpleButton =  cpreset1;
		public var cpreset2:SimpleButton =  cpreset2;
		public var cpreset3:SimpleButton =  cpreset3;
		public var cpreset4:SimpleButton =  cpreset4;
		public var cpreset5:SimpleButton =  cpreset5;
		public var cpreset6:SimpleButton =  cpreset6;
		public var cpreset7:SimpleButton =  cpreset7;
		public var cpreset8:SimpleButton =  cpreset8;
		public var cpreset9:SimpleButton =  cpreset9;
		public var cpreset10:SimpleButton = cpreset10;
		public var cpreset11:SimpleButton = cpreset11;
		public var cpreset12:SimpleButton = cpreset12;
		public var cpreset13:SimpleButton = cpreset13;
		public var cpreset14:SimpleButton = cpreset14;
		public var cpreset15:SimpleButton = cpreset15;
		public var cpreset16:SimpleButton = cpreset16;
		public var cpreset17:SimpleButton = cpreset17;
		public var tegaki0:SimpleButton = tegaki0;
		public var tegaki1:SimpleButton = tegaki1;
		public var tegaki2:SimpleButton = tegaki2;
		public var tegaki3:SimpleButton = tegaki3;
		public var tegaki4:SimpleButton = tegaki4;

		public var mainColorPickerBox:Sprite = new Sprite();
		public var hsvSetBox:Sprite = new Sprite(); //메인 컬러 박스임
		public var hsvSetBoxMask:Shape = new Shape(); //메인 컬러 박스임
		public var svBase:Shape = new Shape(); //메인 컬러 박스에 뒤에 깔아주는 컬러
		public var svColor:Shape = new Shape();//흰색 검은색 그라디언트 깔아주는 컬러 임
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
		public var colorHistoryBoxBG:SimpleButton = colorHistoryBoxBG;

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
			tegakiPresetBox.addChild(tegaki0);
			tegakiPresetBox.addChild(tegaki1);
			tegakiPresetBox.addChild(tegaki2);
			tegakiPresetBox.addChild(tegaki3);
			tegakiPresetBox.addChild(tegaki4);

			tegaki0.x = 0;
			tegaki0.y = 0;
			tegaki1.x = tegaki0.x+tegaki0.width;
			tegaki1.y = 0;
			tegaki2.x = tegaki1.x+tegaki1.width;
			tegaki2.y = 0;
			tegaki3.x = tegaki2.x+tegaki2.width;
			tegaki3.y = 0;
			tegaki4.x = tegaki3.x+tegaki3.width;
			tegaki4.y = 0;
			tegaki0.useHandCursor = false;
			tegaki1.useHandCursor = false;
			tegaki2.useHandCursor = false;
			tegaki3.useHandCursor = false;
			tegaki4.useHandCursor = false;
		}

		private function initDrawrPreset():void
		{
			const floor:Function = Math.floor;
			var btn:SimpleButton;
			var width:Number = 17;
			var height:Number = 19;
			var x:Number = 0;
			var y:Number = 0;
			const offsetX:Number = 0;
			const offsetY:Number = 0;

			for(var i:uint=1;i<=17;i++)
			{
				btn = getChildByName("cpreset"+i) as SimpleButton;
				if(btn)
				{
					drawrPresetBox.addChild(btn);
					btn.width = width;
					btn.height = height;
					btn.x = offsetX+floor(((i-1)*width)-x);
					btn.y = offsetY+floor(y);
					btn.useHandCursor = false;
					
					if(i == 10)
					{
						x = width*7;
						y = height;
					}
				}
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

		public function updateRGBInfoBG(color:uint,borderColor:uint=0):void
		{
			const g:Graphics = rgbInfoBG.graphics;

			g.clear();
			if(borderColor === 0)
			{
				g.lineStyle(1,color);
			}
			else
			{
				g.lineStyle(1,borderColor);
			}
			g.beginFill(color);
			g.drawRect(0,0 ,rgbInfoWidth ,rgbInfoHeight);
			g.endFill();

			rgbInfoBGColor = color;
		}

		public function updateCurrentColor(color:uint,isSimilar:Boolean,invColor:uint):void
		{
			const g:Graphics = currentColor.graphics;
			currentColorColor = color;

			g.clear();
			if(isSimilar)
			{
				g.lineStyle(1,invColor);
			}
			else
			{
				invColor = 0;
				g.lineStyle(1,color);
			}
			g.beginFill(color);
			g.drawRoundRectComplex(0,0,currentColorWidth,19,0,lastCurrentShape,0,0);
			g.endFill();

			updateRGBInfoBG(color,invColor);
		}

		public function changeHueColor(color:uint):void
		{
			const g:Graphics = svBase.graphics;
			// const t:ColorTransform = new ColorTransform();
			// t.color = color;
			// svBase.transform.colorTransform = t;

			g.clear();
			g.lineStyle(0,0,0);
			g.beginFill(color);
			g.drawRect(0,0,svBoxWidth,svBoxHeight);
			g.endFill();

			svBaseColor = color;
		}

		public function colorPickerBox() {
			// visible = false;
			name = "pickerBox";
			initDrawrPreset();
			initTegakiPreset();
			updateRGBInfoBG(0);

			const floor:Function = Math.floor;
			// const baseGrap:Graphics = hsvSetBox.graphics;
			var gradMatrix:Matrix = new Matrix();
			var g:Graphics;

			//sv기본 컬러
			svBase.graphics.lineStyle(0,0,0);
			svBase.graphics.beginFill(0xFF0000,1);
			svBase.graphics.drawRect(0,0,svBoxWidth,svBoxHeight);
			svBase.graphics.endFill();

			//흰색 그라디언트
			gradMatrix.createGradientBox(svBoxWidth, svBoxHeight, 0, 0, 0);
			g = svColor.graphics;
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
			hsvSetBox.name = "hsvSetBox";

			colorPickerInfo.x = -2;
			colorPickerInfo.y = 0;
			colorPickerInfo.text = "Color";

			paperColorButton.x = colorPickerInfo.x+colorPickerInfo.textWidth+62;
			paperColorButton.y = colorPickerInfo.y;
			penColorButton.x = paperColorButton.x+paperColorButton.width+4;
			penColorButton.y = paperColorButton.y;

			penColorButton.useHandCursor = false;
			paperColorButton.useHandCursor = false;

			rgbInfo.x = 0
			rgbInfo.y = 0;
			rgbInfoBG.x = 0;
			rgbInfoBG.y = rgbInfo.y-1;
			currentColor.x = rgbInfoBG.x+rgbInfoBG.width+4;
			currentColor.y = rgbInfoBG.y;
			currentColor.name = "currentColor";

			g = hueColorMask.graphics;
			g.beginFill(0xFFFF0000);
			g.drawRect(0, 0, svBoxWidth, hueHeight);
			g.endFill();

			hueColor.x = 0;
			hueColor.y = rgbInfoBG.y+rgbInfoBG.height+4;
			hueColor.addChild(hueCursor);
			hueColor.addChild(hueColorMask);
			
			hueCursor.x = 0;
			hueCursor.y = -floor((hueCursor.height-hueHeight)/2);
			hueCursor.mask = hueColorMask;
			
			hsvSetBox.addChild(svBase);
			hsvSetBox.addChild(svColor);
			hsvSetBox.addChild(svCursor);
			hsvSetBox.y = floor(hueColor.y+hueColor.height+4);

			colorHistoryBox.name = "colorHistoryBox";
			colorHistoryBoxBG.x = 0;
			colorHistoryBoxBG.y = tegakiPresetBox.y+tegakiPresetBox.height+10;
			colorHistoryBoxBG.width = 170;//17픽셀 10개임
			colorHistoryBoxBG.height = 20;
			colorHistoryBoxBG.useHandCursor = false;
			colorHistoryBoxBG.alpha = 0;
			colorHistoryBox.x = hsvSetBox.x;
			colorHistoryBox.y = hsvSetBox.y+hsvSetBox.height+5;
			mainColorPickerBox.addChild(hsvSetBox); //curtom안에 hsvSetBox안에 svColor안에 svCursor
			mainColorPickerBox.addChild(hueColor);
			mainColorPickerBox.addChild(currentColor);
			mainColorPickerBox.addChild(rgbInfoBG);
			mainColorPickerBox.addChild(rgbInfo);
			mainColorPickerBox.x = 0;
			mainColorPickerBox.y = floor(penColorButton.y+penColorButton.height+5);

			g = hsvSetBoxMask.graphics;
			g.beginFill(0xFFFF0000);
			g.drawRect(0, 0, svBoxWidth, svBoxHeight);
			g.endFill();
			hsvSetBox.addChild(hsvSetBoxMask);

			mainPresetBox.addChild(colorHistoryText);
			mainPresetBox.addChild(colorHistoryBox);
			mainPresetBox.addChild(drawrText);
			mainPresetBox.addChild(drawrPresetBox);
			mainPresetBox.addChild(tegakiText);
			mainPresetBox.addChild(tegakiPresetBox);

			colorHistoryText.x = -1;
			colorHistoryText.y = -5;
			colorHistoryBox.x = 1;
			colorHistoryBox.y = floor(colorHistoryText.y+colorHistoryText.height);

			drawrText.x = colorHistoryText.x;
			drawrText.y = floor(colorHistoryBox.y+colorHistoryBox.height+21);
			drawrPresetBox.x = colorHistoryBox.x;
			drawrPresetBox.y =floor(drawrText.y+drawrText.height-1);

			tegakiText.x = colorHistoryText.x;
			tegakiText.y = floor(drawrPresetBox.y+drawrPresetBox.height+1);
			tegakiPresetBox.x = colorHistoryBox.x;
			tegakiPresetBox.y = floor(tegakiText.y+tegakiText.height);

			mainPresetBox.x = colorHistoryText.x;
			mainPresetBox.y = floor(mainColorPickerBox.y+mainColorPickerBox.height+5);
			
			addChild(mainColorPickerBox);
			addChild(mainPresetBox);

			panelWidth = 180;
			panelHeight = mainPresetBox.y+mainPresetBox.height+3;

			updateCurrentColor(0,false,0);
			svCursor.mask = hsvSetBoxMask;
			svCursor.useHandCursor = false;
			hueCursor.useHandCursor = false;
		}
	}
}
