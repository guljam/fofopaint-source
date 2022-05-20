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

	public class colorPickerBox extends Sprite {

		// public var pickerBoxPanel:SimpleButton = pickerBoxPanel
		public var preset1:SimpleButton =  preset1;
		public var preset2:SimpleButton =  preset2;
		public var preset3:SimpleButton =  preset3;
		public var preset4:SimpleButton =  preset4;
		public var preset5:SimpleButton =  preset5;
		public var preset6:SimpleButton =  preset6;
		public var preset7:SimpleButton =  preset7;
		public var preset8:SimpleButton =  preset8;
		public var preset9:SimpleButton =  preset9;
		public var preset10:SimpleButton = preset10;
		public var preset11:SimpleButton = preset11;
		public var preset12:SimpleButton = preset12;
		public var preset13:SimpleButton = preset13;
		public var preset14:SimpleButton = preset14;
		public var preset15:SimpleButton = preset15;
		public var preset16:SimpleButton = preset16;
		public var preset17:SimpleButton = preset17;
		public var tegakiPreset0:SimpleButton = tegakiPreset0;
		public var tegakiPreset1:SimpleButton = tegakiPreset1;
		public var tegakiPreset2:SimpleButton = tegakiPreset2;
		public var tegakiPreset3:SimpleButton = tegakiPreset3;
		public var tegakiPreset4:SimpleButton = tegakiPreset4;

		public var customColorBox:Sprite = new Sprite();
		public var mainPickerBox:Sprite = new Sprite(); //메인 컬러 박스임
		public var mainPickerBoxMask:Shape = new Shape(); //메인 컬러 박스임
		public var svBase:Shape = new Shape(); //메인 컬러 박스에 뒤에 깔아주는 컬러
		public var svColor:Shape = new Shape();//흰색 검은색 그라디언트 깔아주는 컬러 임
		public var hueColor:Sprite = new Sprite();
		public var hueColorMask:Shape = new Shape();
		public var presetBox:Sprite = new Sprite();
		public var rgbInfo:TextField = rgbInfo;
		private const rgbInfoBG:Shape = new Shape();
		public var rbInfoBGColor:uint = 0;
		public const colorHistoryBox:Sprite = new Sprite()//컬러 히스토리
		public var colorHistoryBoxBG:SimpleButton = colorHistoryBoxBG;

		public var bgText:TextField = bgText;

		public var offsetX:Number = 0; //customcolor 박스 떨어진 위치
		public var offsetY:Number = 0;

		public var currentColor:Sprite = new Sprite();
		public var currentColorColor:uint = 0;
		public var currentColorWidth:Number = 20;
		private var lastCurrentShape:int = 0;
		public var hueCursor:SimpleButton = hueCursor;
		public var svCursor:SimpleButton = svCursor;
		// public var preset17:SimpleButton = preset17;
		
		public const svBoxWidth:uint = 170; //sv가로 세로 사이즈
		public const svBoxHeight:uint = 170;
		private const hueHeight:uint = 12; //hue 새로 세이즈
		private const halfPI:Number = Math.PI/2;
		private const angles:Array = [0,halfPI*2,halfPI,halfPI*3];
		private var lastMixColor:uint = 0;
		private var lastMixAlpha:uint = 0;
		private var rotateCount:uint = 0;
		public var svBaseColor:uint = 0xFF0000;

		private var panelWidth:Number = 0;
		private var panelHeight:Number = 0;

		//피커박스 구조
		//custom color, colorhistoryBox, drawr프리셋 따로따로 전부가 첫번째 자식들임
		public function changeUIColor(base:uint,op:uint,index:int):void
		{
			const b:ColorTransform = new ColorTransform();
			// const o:ColorTransform = new ColorTransform();

			b.color = base;
			// o.color = op;
			// hueCursor.transform.colorTransform = o;
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
			const offsetY:Number = height;

			for(var i:uint=1;i<=17;i++)
			{
				btn = getChildByName("preset"+i) as SimpleButton;
				if(btn)
				{
					presetBox.addChild(btn);
					btn.width = width;
					btn.height = height;
					btn.x = offsetX+floor(((i-1)*width)-x);
					btn.y = offsetY+floor(y);
					btn.useHandCursor = false;
					
					if(i == 10)
					{
						x = width*7;
						y = -height;
					}
				}
			}
		}

		public function setBGTextColor(color:int):void
		{
			bgText.textColor = color;
		}

		public function changeBGTextToPicker(flag:Boolean):void
		{
			if(flag === true)
			{
				bgText.text = "Pen";
			}
			else
			{
				bgText.text = "BG";
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
			const a:TextField = rgbInfo;	
			const f:Function = Math.floor;
			var width:Number = a.width;
			var height:Number = a.height-1;
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
			g.drawRect(f(a.x-4),f(a.y),f(a.width-3),f(height));
			g.endFill();

			rbInfoBGColor = color;
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
			updateRGBInfoBG(0);
			
			const floor:Function = Math.floor;
			// const baseGrap:Graphics = mainPickerBox.graphics;
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

			//hu 그라디언트
			gradMatrix.createGradientBox(svBoxWidth, hueHeight, 0, 0, 0); //
			g = hueColor.graphics;
			g.lineStyle(0,0,0);
			g.beginGradientFill(GradientType.LINEAR, [0xFF0000,0xFFFF00,0x00FF00,0x00FFFF,0x0000FF,0xFF00FF,0xFF0000],
															[1,1,1,1,1,1,1],//255/6 = 42.5 x n
															[0,42.5,85,127.5,170,212.5,255], gradMatrix);
			g.drawRect(0, 0, svBoxWidth, hueHeight);
			g.endFill();

			hueColor.name = "hueColor";
			mainPickerBox.name = "mainPickerBox";x
			// svColor.name = "svColor";
			rgbInfo.x = 0;
			rgbInfo.y = 0;
			rgbInfoBG.x = 2;
			rgbInfoBG.y = -1;
		
			offsetX = 0;
			offsetY = rgbInfo.y+rgbInfo.height+3;

			g = hueColorMask.graphics;
			g.beginFill(0xFFFF0000);
			g.drawRect(0, 0, svBoxWidth, hueHeight);
			g.endFill();

			hueColor.addChild(hueCursor);
			hueColor.addChild(hueColorMask);
			hueCursor.x = offsetX;
			hueCursor.y = -floor((hueCursor.height-hueHeight)/2)-1;
			hueCursor.mask = hueColorMask;
			
			mainPickerBox.addChild(svBase);
			mainPickerBox.addChild(svColor);
			mainPickerBox.addChild(svCursor);

			customColorBox.addChild(mainPickerBox); //curtom안에 mainPickerBox안에 svColor안에 svCursor
			customColorBox.addChild(hueColor);
			customColorBox.x = offsetX;
			customColorBox.y = floor(offsetY+2);

			mainPickerBox.y = floor(hueColor.y+hueColor.height+5);

			g = mainPickerBoxMask.graphics;
			g.beginFill(0xFFFF0000);
			g.drawRect(0, 0, svBoxWidth, svBoxHeight);
			g.endFill();
			mainPickerBox.addChild(mainPickerBoxMask);

			presetBox.x = floor(customColorBox.x);
			presetBox.y = floor(customColorBox.y+customColorBox.height)+5;
			bgText.x = offsetX;
			bgText.y = presetBox.y-1;

			addChild(customColorBox);
			addChild(presetBox);

			tegakiPreset0.x = presetBox.x;
			tegakiPreset0.y = presetBox.y+presetBox.height+5;
			tegakiPreset1.x = tegakiPreset0.x+tegakiPreset0.width;
			tegakiPreset1.y = tegakiPreset0.y;
			tegakiPreset2.x = tegakiPreset1.x+tegakiPreset1.width;
			tegakiPreset2.y = tegakiPreset0.y;
			tegakiPreset3.x = tegakiPreset2.x+tegakiPreset2.width;
			tegakiPreset3.y = tegakiPreset0.y;
			tegakiPreset4.x = tegakiPreset3.x+tegakiPreset3.width;
			tegakiPreset4.y = tegakiPreset0.y;

			tegakiPreset0.useHandCursor = false;
			tegakiPreset1.useHandCursor = false;
			tegakiPreset2.useHandCursor = false;
			tegakiPreset3.useHandCursor = false;
			tegakiPreset4.useHandCursor = false;

			colorHistoryBox.name = "colorHistoryBox";
			colorHistoryBoxBG.x = offsetX;
			colorHistoryBoxBG.y = tegakiPreset0.y+tegakiPreset0.height+10;
			colorHistoryBoxBG.width = 170;//17픽셀 10개임
			colorHistoryBoxBG.height = 20;
			colorHistoryBoxBG.useHandCursor = false;
			colorHistoryBoxBG.alpha = 0;
			colorHistoryBox.x = colorHistoryBoxBG.x;
			colorHistoryBox.y = colorHistoryBoxBG.y;
		
			panelWidth = 180;//svBoxWidth+offsetX*2+1;
			panelHeight = colorHistoryBoxBG.y+colorHistoryBoxBG.height+3;

			addChild(colorHistoryBox);
			addChild(bgText);
			addChild(rgbInfoBG);
			
			setChildIndex(rgbInfo,numChildren-1);
			setChildIndex(rgbInfoBG,getChildIndex(rgbInfo)-1);
			updateCurrentColor(0,false,0);
			currentColor.x = rgbInfoBG.x+rgbInfoBG.width+3;
			currentColor.y = rgbInfoBG.y;
			currentColor.name = "currentColor";
			
			addChild(currentColor);
			

			svCursor.mask = mainPickerBoxMask;
			svCursor.useHandCursor = false;
			hueCursor.useHandCursor = false;

			rgbInfo.x += 2;


			// const shadow:DropShadowFilter = new DropShadowFilter();
			// shadow.blurX = 3;
			// shadow.blurY = 3;
			// shadow.alpha = 0.5;
			// shadow.distance = 7;
			// shadow.strength	= 1;
			// shadow.angle = 45;
			// filters = [shadow];
		}
	}
}
