package Symbols
{
	import flash.display.Sprite;
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.display.Shape;
	import flash.ui.ContextMenu;
	import flash.display.BitmapData;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Rectangle;
	import flash.text.TextFieldType;
	import assets.VisualBuilder;
	import assets.VisualFieldCollector;

	public class ColorPickerSet extends Sprite
	{
		public var mainColorPickerBox:Sprite = new Sprite();
		public var colorPickerPresetBox:Sprite = new Sprite();
		public var colorPickerTypeBox:Sprite = new Sprite();
		public var svBox:Sprite = new Sprite(); //hue랑 sv합친거
		public var svBase:Shape = new Shape(); //메인 컬러 박스에 뒤에 깔아주는 컬러
		public var svGradient:Shape = new Shape();//흰색 검은색 그라디언트 깔아주는 컬러 임
		public var hueColor:Sprite = new Sprite();
		public var hueColorMask:Shape = new Shape();
		public var rgbInfoText:TextField;
		public var drawrPresetButton:SimpleButton;
		public var tegakiPresetButton:SimpleButton;
		public var myPaletteButton:SimpleButton;
		public var swapPositionButton:SimpleButton;
		public const rgbInfoBG:Shape = new Shape();
		public var rgbInfoBGColor:uint = 0;
		private var rgbInfoBGBorderColor:uint = 0;
		private var rgbInfoPaletteTypeSave:int = 0;
		public const myPaletteBox:Sprite = new Sprite();
		public const colorHistoryBox:Sprite = new Sprite();
		public const myPaletteDragColor:Shape = new Shape();
		public var penColorButton:SimpleButton;
		public var paperColorButton:SimpleButton;
		public var transColorButton:SimpleButton;
		public var transColorButtonBmpd:BitmapData;
		public var myPaletteTransBG:SimpleButton;
		public var myPaletteTransBGBmpd:BitmapData;

		public var offsetX:Number = 0; //customcolor 박스 떨어진 위치

		public var currentColorBox:Sprite = new Sprite();
		public var currentColor:uint = 0;
		public var currentColorBoxWidth:Number = 28;
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

		private var rgbInfoWidth:int = 108;
		private var rgbInfoHeight:int = 19;

		private var firstRGBInfoColorText:String = "";
		private var colorBoxPositionSave:Array = [0,0];
		private var transBGBrightnessList:Array = [0.8,0.85,0.88,0.98];

		public var scratchPad:DrawrScratchPad;

		private var lastRGBInfoText:String = "";

		// public function setRGBInfoTextTypeToInput(flag:Boolean):void
		// {
		// 	rgbInfoText.type = (flag) ? TextFieldType.DYNAMIC:TextFieldType.INPUT;
		// }
		
		private function initScratcPad():void
		{
			scratchPad = new DrawrScratchPad(svBoxWidth,mainColorPickerBox.height-24);
			scratchPad.x = 0
			scratchPad.y = hueColor.y;
			mainColorPickerBox.addChild(scratchPad);
		}
		
		private function hideScratchPad():void
		{
			if(!scratchPad)
			{
				return;
			}

			if(scratchPad.visible)
			{
				scratchPad.visible = false;
			}

			for(var i:int = 0; i < mainColorPickerBox.numChildren; i++) {
				var child:* = mainColorPickerBox.getChildAt(i);
				if(child != scratchPad) {
					child.visible = true;
				}
			}
		}

		private function showScratchPad():void
		{
			if(!scratchPad)
			{
				return;
			}

			if(!scratchPad.visible)
			{
				scratchPad.visible = true;
			}

			for(var i:int = 0; i < mainColorPickerBox.numChildren; i++) {
				var child:* = mainColorPickerBox.getChildAt(i);
				if(child === scratchPad
				|| child === rgbInfoBG
				|| child === colorHistoryBox)
				{
					continue;
				}
				child.visible = false;
			}
		}

		public function swapColorBoxPositions(flag:Boolean):void
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

			updateMainColorPickerBoxPosition(flag);
		}

		public function updateMainColorPickerBoxPosition(checkflag:Boolean):void
		{
			if(checkflag)
			{
				colorPickerPresetBox.y = myPaletteBox.y+myPaletteBox.height+9;
				colorPickerTypeBox.y = colorPickerPresetBox.y+colorPickerPresetBox.height+6;
			}
			else
			{
				mainColorPickerBox.y = myPaletteBox.y+myPaletteBox.height+5;
				colorPickerPresetBox.y = mainColorPickerBox.y+mainColorPickerBox.height+8;
				colorPickerTypeBox.y = colorPickerPresetBox.y+colorPickerPresetBox.height+6;
			}
		}

		public function setActiveColorPreset(type:int):void
		{
			if(type === 0)
			{
				myPaletteButton.alpha = 1.0;
				drawrPresetButton.alpha = 0.6;
				tegakiPresetButton.alpha = 0.6;
				hideScratchPad();
			}
			else if(type === 1)
			{
				myPaletteButton.alpha = 0.6;
				drawrPresetButton.alpha = 1.0;
				tegakiPresetButton.alpha = 0.6;
				showScratchPad();
			}
			else if(type === 2)
			{
				myPaletteButton.alpha = 0.6;
				drawrPresetButton.alpha = 0.6;
				tegakiPresetButton.alpha = 1.0;
				showScratchPad();
			}
		}

		public function getFirstRGBInfoColorText():String
		{
			return firstRGBInfoColorText;
		}

		public function updateFirstRGBInfoColorText():void
		{
			firstRGBInfoColorText = rgbInfoText.text;
		}

		public function fillPenModeON():void
		{
			penColorButton.alpha = 0.2;
			paperColorButton.alpha = 0.2;
		}
			
		public function activePaperColorButton(flag:Boolean):void
		{
			if(flag)
			{
				penColorButton.alpha = 0.6;
				paperColorButton.alpha = 1.0;
			}
			else
			{
				penColorButton.alpha = 1.0;
				paperColorButton.alpha = 0.6;
			}
		}

		public function updateUIColor():void
		{
			const fgColor:uint = Global.getUIFGColor()
			rgbInfoText.textColor = Global.getUIFGColor();
			const arr:Array = [
								myPaletteButton,
								drawrPresetButton,
								tegakiPresetButton,
								swapPositionButton,
								penColorButton,
								penColorButton,
								paperColorButton
								];

			for (var i:uint = 0; i < arr.length; i++)
			{
				Global.applyUIFGColor(arr[i]);
			}
		}

		public function restoreRGBInfoText():void
		{
			rgbInfoText.text = lastRGBInfoText;
		}

		public function updateRGBInfoText(mode:String,data:*):void
		{
			function pad(n:Number):String
			{
				return ("  " + n).substr(-3);
			}

			if(mode === "HSV")
			{
				if(data[0] <= 1.0)
				{
					rgbInfoText.text = mode+" "+pad(Math.round(data[0]*360))+","+pad(Math.round(data[1]*100))+","+pad(Math.round(data[2]*100));
				}
				else
				{
					rgbInfoText.text = mode+" "+pad(data[0])+","+pad(data[1])+","+pad(data[2]);
				}
			}
			else
			{
				if(data is uint)
				{
					const rgb:Vector.<Number> = Global.HEXtoRGB(data as uint);
					rgbInfoText.text = mode+" "+pad(rgb[0])+","+pad(rgb[1])+","+pad(rgb[2]);
				}
				else if(data is Vector.<Number> || data is Array)
				{
					rgbInfoText.text = mode+" "+pad(data[0])+","+pad(data[1])+","+pad(data[2]);
				}
			}

			rgbInfoText.textColor = Global.getInvertedColor(rgbInfoBGColor);
		}

		public function setRGBInfoTextColor(color:uint):void
		{
			rgbInfoText.textColor = color;
		}

		public function getRGBInfoBGColor():uint
		{
			return rgbInfoBGColor;
		}

		public function getRGBInfoText():String
		{
			return rgbInfoText.text;
		}

		public function setRGBInfoVisible(flag:Boolean):void
		{
			rgbInfoText.visible = flag;
		}

		public function restoreRGBInfoBackground():void
		{
			updateRGBInfoBG(rgbInfoBGColor,rgbInfoPaletteTypeSave);
		}

		public function setRGBInfoBackgroundTransparent(paletteType:int):void
		{
			if(rgbInfoText.text !== "")
			{
				const rgbInfoBGwidth:Number = (paletteType !== 0)?svBoxWidth:rgbInfoWidth;
				rgbInfoBG.graphics.clear();
				rgbInfoBG.graphics.lineStyle(0,0,0);
				rgbInfoBG.graphics.beginBitmapFill(transColorButtonBmpd);
				rgbInfoBG.graphics.drawRect(0,0,rgbInfoBGwidth,rgbInfoHeight);
				rgbInfoBG.graphics.endFill();
				
				lastRGBInfoText = rgbInfoText.text;
				rgbInfoText.text = "";
			}
		}

		public function getRGBInfoBorderColor(color:uint):uint
        {
            const diff:Number = Global.getColorDifferenceForHuman(color,Global.getUIBGColor());
            return (diff <= 15) ? Global.getUIFGColor() : 0;
        }

		public function updateRGBInfoBG(color:uint,paletteType:int):void
		{	
			const rgbInfoBGwidth:Number = (paletteType !== 0)?svBoxWidth:rgbInfoWidth;
			const borderColor:uint = getRGBInfoBorderColor(color);

			rgbInfoBG.graphics.clear();
			rgbInfoBG.graphics.beginFill(color);
			rgbInfoBG.graphics.drawRect(0,0,rgbInfoBGwidth,rgbInfoHeight);
			rgbInfoBG.graphics.endFill();
			rgbInfoBG.graphics.lineStyle(1, (borderColor === 0) ? color:borderColor);
			rgbInfoBG.graphics.drawRect(0,0, rgbInfoBGwidth,19);

			rgbInfoBGColor = color;
			rgbInfoBGBorderColor = borderColor;
			if(rgbInfoPaletteTypeSave != paletteType)
			{
				rgbInfoPaletteTypeSave = paletteType;
			}
		}

		public function getCurrentColor():uint
		{
			return currentColor;
		}

		public function updateCurrentColor(color:uint):void
		{
			if(currentColor !== color)
			{
				const borderColor:uint = getRGBInfoBorderColor(color);
				currentColor = color;
				currentColorBox.graphics.clear();
				currentColorBox.graphics.beginFill(color);
				currentColorBox.graphics.drawRect(0,0,currentColorBoxWidth,19);
				currentColorBox.graphics.endFill();
				currentColorBox.graphics.lineStyle(1, (borderColor === 0) ? color:borderColor);
				currentColorBox.graphics.drawRect(0,0, currentColorBoxWidth,19);
			}
		}

		public function updateHueColor(color:uint):void
		{
			svBase.graphics.clear();
			svBase.graphics.lineStyle(0,0,0);
			svBase.graphics.beginFill(color);
			svBase.graphics.drawRect(0,0,svBoxWidth,svBoxHeight);
			svBase.graphics.endFill();

			svBaseColor = color;
		}

		public function removeDragColor():void
		{
			myPaletteDragColor.visible = false;
			myPaletteDragColor.graphics.clear();
		}

		public function updateDragColorPosToCursor():void
		{
			myPaletteDragColor.x = this.mouseX-myPaletteDragColor.width/2;
			myPaletteDragColor.y = this.mouseY-myPaletteDragColor.height/2;
		}

		public function updateDragColor(color:uint,colorWidth:Number,colorHeight:Number):void
		{
			myPaletteDragColor.graphics.clear();
			myPaletteDragColor.graphics.beginFill(color);
			myPaletteDragColor.graphics.drawRect(0,0,colorWidth,colorHeight);
			myPaletteDragColor.graphics.endFill();

			setChildIndex(myPaletteDragColor,this.numChildren-1);
			myPaletteDragColor.visible = true;
		}

		private function initMyPaletteTransBG():void
		{
			const checkerPatternWidth:Number = myPaletteTransBG.width;
			const checkerPatternHeight:Number = myPaletteTransBG.height;
			const mat:Matrix = new Matrix();
			mat.scale(myPaletteTransBG.scaleX,myPaletteTransBG.scaleY);
			myPaletteTransBGBmpd = new BitmapData(checkerPatternWidth,checkerPatternHeight,false,0);
			myPaletteTransBGBmpd.draw(myPaletteTransBG,mat);

			if(this.contains(myPaletteTransBG))
			{
				removeChild(myPaletteTransBG);
			}
		}

		public function applyTransparentColorBrightness(uiColorIndex:int):void
		{
			const brightness:Number = transBGBrightnessList[uiColorIndex];
			var colorMatrix:Array = [
				brightness, 0, 0, 0, 0,
				0, brightness, 0, 0, 0,
				0, 0, brightness, 0, 0,
				0, 0, 0, 1, 0
			];
			var colorMatrixFilter:ColorMatrixFilter = new ColorMatrixFilter(colorMatrix);
			transColorButton.filters = [colorMatrixFilter];
			myPaletteTransBG.filters = [colorMatrixFilter];

			initTransparentColorButton();
			initMyPaletteTransBG();
		}

		private function initTransparentColorButton():void
		{
			const checkerPatternWidth:Number = transColorButton.width;
			const checkerPatternHeight:Number = transColorButton.height;
			const mat:Matrix = new Matrix();
			mat.scale(transColorButton.scaleX,transColorButton.scaleY);
			transColorButtonBmpd = new BitmapData(checkerPatternWidth-10,checkerPatternHeight,false,0);
			transColorButtonBmpd.draw(transColorButton,mat);
		}

		//피커박스 구조
		//custom color, colorhistoryBox, drawr프리셋 따로따로 전부가 첫번째 자식들임

		[Embed(
            source="fofoPaint-animate-27.13.swf",
            symbol="ColorPickerSet"
        )]
		private static const EmbeddedClass:Class;

		public function ColorPickerSet()
		{
			const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
			VisualBuilder.buildInto(this,EmbeddedClass,fields);
			// visible = false;
			name = "pickerBox";
			initTransparentColorButton();
			initMyPaletteTransBG();

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
			hueColor.name = "hueColor";
			hueColor.graphics.lineStyle(0,0,0);
			hueColor.graphics.beginGradientFill(GradientType.LINEAR, [0xFF0000,0xFFFF00,0x00FF00,0x00FFFF,0x0000FF,0xFF00FF,0xFF0000],
															[1,1,1,1,1,1,1],//255/6 = 42.5 x n
															[0,42.5,85,127.5,170,212.5,255], gradMatrix);
			hueColor.graphics.drawRect(0, 0, svBoxWidth, hueHeight);
			hueColor.graphics.endFill();

			colorPickerTypeBox.addChild(swapPositionButton);
			colorPickerTypeBox.addChild(paperColorButton);
			colorPickerTypeBox.addChild(penColorButton);

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

			rgbInfoText.type = TextFieldType.DYNAMIC;
			rgbInfoText.selectable = false;
			rgbInfoText.x = 0;
			rgbInfoText.y = 0.5;

			rgbInfoBG.x = 0;
			rgbInfoBG.y = 0;

			transColorButton.x = Math.floor(rgbInfoBG.x+rgbInfoWidth+5);
			transColorButton.y = rgbInfoBG.y;
			transColorButton.useHandCursor = false;
			currentColorBox.x = Math.floor(transColorButton.x+transColorButton.width);
			currentColorBox.y = transColorButton.y;
			currentColorBox.name = "currentColor";
			currentColorBox.graphics.clear();
			currentColorBox.graphics.beginFill(0);
			currentColorBox.graphics.drawRect(0,0,currentColorBoxWidth,19);

			hueColorMask.graphics.beginFill(0xFFFF0000);
			hueColorMask.graphics.drawRect(0, 0, svBoxWidth, hueHeight);
			hueColorMask.graphics.endFill();

			hueCursor.x = 0;
			hueCursor.y = -Math.floor((hueCursor.height-hueHeight)/2);
			hueCursor.mask = hueColorMask;

			hueColor.x = 0;
			hueColor.y = Math.floor(rgbInfoBG.y+rgbInfoHeight+4);
			hueColor.addChild(hueCursor);
			hueColor.addChild(hueColorMask);

			svBox.name = "svBox";
			svBox.addChild(svBase);
			svBox.addChild(svGradient);
			svBox.addChild(svCursor);
			svBox.y = Math.floor(hueColor.y+hueColor.height+4);
			svBox.scrollRect = new Rectangle(0,0,svBoxWidth,svBoxHeight);

			mainColorPickerBox.addChild(svBox); //mainColorPickerBox svBox안에 svColor안에 svCursor
			mainColorPickerBox.addChild(hueColor);
			mainColorPickerBox.addChild(transColorButton);
			mainColorPickerBox.addChild(currentColorBox);
			mainColorPickerBox.addChild(rgbInfoBG);
			mainColorPickerBox.addChild(rgbInfoText);
			mainColorPickerBox.addChild(colorHistoryBox);
			initScratcPad();
			
			colorHistoryBox.name = "colorHistoryBox";
			colorHistoryBox.y = svBox.y+svBox.height+5;

			colorPickerPresetBox.addChild(myPaletteButton);
			colorPickerPresetBox.addChild(tegakiPresetButton);
			colorPickerPresetBox.addChild(drawrPresetButton);

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
			addChild(colorPickerPresetBox);
			addChild(colorPickerTypeBox);
			addChild(myPaletteDragColor);
			myPaletteDragColor.visible = false;

			panelWidth = 180;
			panelHeight = colorPickerPresetBox.y+colorPickerPresetBox.height+3;

			colorBoxPositionSave[0] = myPaletteBox.y;
			colorBoxPositionSave[1] = mainColorPickerBox.y;

			svCursor.mouseEnabled = false;
			hueCursor.mouseEnabled = false;
		}
	}
}
