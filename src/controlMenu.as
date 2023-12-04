package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;
	import flash.filters.BlurFilter;

	public class controlMenu extends Sprite
	{
		public const penSizeBox:Sprite = new Sprite();
		public const opaBox:Sprite = new Sprite();
		public const sharpLineButtonWrapper:Sprite = new Sprite();
		public const airBrushButtonWrapper:Sprite = new Sprite();
		public const layerButtonWrapper:Sprite = new Sprite();
		public const opaSizeButtonWrapper:Sprite = new Sprite();

		public var infoPenOptions:SimpleButton;
		public var infoEraserOptions:SimpleButton;
		public var infoFillPenOptions:SimpleButton;
		public var infoLineOptions:SimpleButton;

		public var rectSizeSet:SimpleButton;
		public var circleSizeSet:SimpleButton;
		public var shapeRect:SimpleButton;
		public var shapeCircle:SimpleButton;
		public var penSizeGuide:SimpleButton;
		public var penSizeSelectCursor:SimpleButton;
		public var opaGuide:SimpleButton;
		public var opaCursor:SimpleButton;

		public var sharpLineONButton:SimpleButton;
		public var sharpLineOFFButton:SimpleButton;
		public var sharpLineText:SimpleButton;
		public var airBrushONButton:SimpleButton;
		public var airBrushOFFButton:SimpleButton;
		public var airBrushText:SimpleButton;

		public var layer1SelectButton:SimpleButton;
		public var layer2SelectButton:SimpleButton;
		public var layer1Button:SimpleButton;
		public var layer2Button:SimpleButton;
		public var penSmoothSliderSet:Sprite;

		public var layer1CheckButton:SimpleButton;
		public var layer1UncheckButton:SimpleButton;
		public var layer2CheckButton:SimpleButton;
		public var layer2UncheckButton:SimpleButton;
		public var layerSwapButton:SimpleButton;
		public var layerMergeButton:SimpleButton;
		public var saperateLine:SimpleButton;

		private var layerVisibleBackup:Array;
		private const blurFilter:BlurFilter = new BlurFilter(3, 3, 2);

		private const BOX_WIDTH:Number = 180;
		private var BOX_HEIGHT:Number = 260;

		private const opColor:ColorTransform = new ColorTransform();

		public function blurShapeSetON():void
		{
			rectSizeSet.filters = [blurFilter];
			circleSizeSet.filters = [blurFilter];
		}

		public function blurShapeSetOFF():void
		{
			rectSizeSet.filters = null;
			circleSizeSet.filters = null;
		}

		public function changeUIColor(op:uint):void
		{
			var alphaBackup:Number; //레이어 버튼이 색깔 바꾸면 알파가 초기화 되는 버그있어서 수동으로 만들어줌
			opColor.color = op;

			infoPenOptions.transform.colorTransform = opColor;
			infoEraserOptions.transform.colorTransform = opColor;
			infoFillPenOptions.transform.colorTransform = opColor;
			infoLineOptions.transform.colorTransform = opColor;

			alphaBackup = layer1SelectButton.alpha;
			layer1SelectButton.transform.colorTransform = opColor;
			layer1SelectButton.alpha = alphaBackup;
			layer1UncheckButton.transform.colorTransform = opColor;
			layer1CheckButton.transform.colorTransform = opColor;

			alphaBackup = layer2SelectButton.alpha;
			layer2SelectButton.transform.colorTransform = opColor;
			layer2SelectButton.alpha = alphaBackup;
			layer2UncheckButton.transform.colorTransform = opColor;
			layer2CheckButton.transform.colorTransform = opColor;

			layerSwapButton.transform.colorTransform = opColor;
			layerMergeButton.transform.colorTransform = opColor;

			shapeRect.transform.colorTransform = opColor;
			shapeCircle.transform.colorTransform = opColor;
			rectSizeSet.transform.colorTransform = opColor;
			circleSizeSet.transform.colorTransform = opColor;
			penSizeGuide.transform.colorTransform = opColor;

			sharpLineText.transform.colorTransform = opColor;
			sharpLineONButton.transform.colorTransform = opColor;
			sharpLineOFFButton.transform.colorTransform = opColor;

			airBrushText.transform.colorTransform = opColor;
			airBrushOFFButton.transform.colorTransform = opColor;
			airBrushONButton.transform.colorTransform = opColor;

			opaGuide.transform.colorTransform = opColor;
			saperateLine.transform.colorTransform = opColor;

			penSmoothSliderSet["penSmoothBar"].transform.colorTransform = opColor;
			penSmoothSliderSet["penSmoothButton"].transform.colorTransform = opColor;
		}

		public function shapeFlag(flag:Boolean):void // true이면 rect임
		{
			if (flag === true)
			{
				rectSizeSet.visible = true;
				circleSizeSet.visible = false;
			}
			else
			{
				rectSizeSet.visible = false;
				circleSizeSet.visible = true;
			}
		}

		public function hintText(toolStr:String):void
		{
			if(toolStr === "Pen")
			{
				infoPenOptions.visible = true;
				infoEraserOptions.visible = false;
				infoFillPenOptions.visible = false;
				infoLineOptions.visible = false;
			}
			else if(toolStr === "Eraser")
			{
				infoPenOptions.visible = false;
				infoEraserOptions.visible = true;
				infoFillPenOptions.visible = false;
				infoLineOptions.visible = false;
			}
			else if(toolStr === "Fill-pen")
			{
				infoPenOptions.visible = false;
				infoEraserOptions.visible = false;
				infoFillPenOptions.visible = true;
				infoLineOptions.visible = false;
			}
			else if(toolStr === "Line")
			{
				infoPenOptions.visible = false;
				infoEraserOptions.visible = false;
				infoFillPenOptions.visible = false;
				infoLineOptions.visible = true;
			}
		}

		public function movePenSizeCursor(index:uint):void
		{
			const btn:Sprite = penSizeBox.getChildByName("nSizeButton"+index) as Sprite;

			if (btn)
			{
				penSizeSelectCursor.x = penSizeBox.x+btn.x;
				penSizeSelectCursor.y = penSizeBox.y+btn.y;
			}
		}

		public function initAirBrushButtonWrapper():void
		{
			const w:Number = airBrushOFFButton.width+sharpLineText.width+14;
			const h:Number = airBrushOFFButton.height+2;

			airBrushButtonWrapper.graphics.beginFill(0xFF0000,0);
			airBrushButtonWrapper.graphics.drawRect(0,0,w,h);
			airBrushButtonWrapper.graphics.endFill();

			airBrushOFFButton.mouseEnabled = false;
			airBrushONButton.mouseEnabled = false;
			airBrushText.mouseEnabled = false;

			airBrushButtonWrapper.addChild(airBrushOFFButton);
			airBrushButtonWrapper.addChild(airBrushONButton);
			airBrushButtonWrapper.addChild(airBrushText);

			airBrushONButton.x = 0;
			airBrushONButton.y = 0;
			airBrushOFFButton.x = airBrushONButton.x;
			airBrushOFFButton.y = airBrushONButton.y;
			airBrushOFFButton.visible = false;

			airBrushText.x = airBrushOFFButton.x+airBrushOFFButton.width+3;
			airBrushText.y = airBrushOFFButton.y+2;

			airBrushONButton.useHandCursor = false;
			airBrushOFFButton.useHandCursor = false;
			airBrushText.useHandCursor = false;

			airBrushButtonWrapper.name = "airBrushButtonWrapper";
		}

		public function initSharpLineButtonWrapper():void
		{
			const w:Number = sharpLineOFFButton.width+sharpLineText.width+14;
			const h:Number = sharpLineOFFButton.height+2;

			sharpLineButtonWrapper.graphics.beginFill(0xFF0000,0.0);
			sharpLineButtonWrapper.graphics.drawRect(0,0,w,h);
			sharpLineButtonWrapper.graphics.endFill();

			sharpLineOFFButton.mouseEnabled = false;
			sharpLineONButton.mouseEnabled = false;
			sharpLineText.mouseEnabled = false;

			sharpLineButtonWrapper.addChild(sharpLineOFFButton);
			sharpLineButtonWrapper.addChild(sharpLineONButton);
			sharpLineButtonWrapper.addChild(sharpLineText);

			sharpLineONButton.x = 0;
			sharpLineONButton.y = 0;
			sharpLineOFFButton.x = sharpLineONButton.x;
			sharpLineOFFButton.y = sharpLineONButton.y;
			sharpLineOFFButton.visible = false;

			sharpLineText.x = sharpLineOFFButton.x+sharpLineOFFButton.width+3;
			sharpLineText.y = sharpLineOFFButton.y+1;

			sharpLineOFFButton.useHandCursor = false;
			sharpLineONButton.useHandCursor = false;
			sharpLineText.useHandCursor = false;

			sharpLineButtonWrapper.name = "sharpLineButtonWrapper";
		}

		public function initLayerButton():void
		{
			layer1CheckButton.visible = false;
			layer2CheckButton.visible = false;
			layer1SelectButton.useHandCursor = false;
			layer2SelectButton.useHandCursor = false;
			layer1CheckButton.useHandCursor = false;
			layer1UncheckButton.useHandCursor = false;
			layer2CheckButton.useHandCursor = false;
			layer2UncheckButton.useHandCursor = false;
			layerSwapButton.useHandCursor = false;
			layerMergeButton.useHandCursor = false;

			layerButtonWrapper.addChild(layer1SelectButton);
			layerButtonWrapper.addChild(layer2SelectButton);
			layerButtonWrapper.addChild(layer1CheckButton);
			layerButtonWrapper.addChild(layer1UncheckButton);
			layerButtonWrapper.addChild(layer2CheckButton);
			layerButtonWrapper.addChild(layer2UncheckButton);
			layerButtonWrapper.addChild(layerSwapButton);
			layerButtonWrapper.addChild(layerMergeButton);
			layerButtonWrapper.addChild(saperateLine);

			layerSwapButton.x = 0;
			layerSwapButton.y = 0;

			layer1CheckButton.x = layerSwapButton.x+layerSwapButton.width+3;
			layer1CheckButton.y = layerSwapButton.y+2;
			layer1UncheckButton.x = layer1CheckButton.x;
			layer1UncheckButton.y = layer1CheckButton.y;

			layer1SelectButton.x = layer1CheckButton.x+layer1CheckButton.width+3;
			layer1SelectButton.y = layer1CheckButton.y-1;

			layerMergeButton.x = layer1SelectButton.x+layer1SelectButton.width+1;
			layerMergeButton.y = layer1SelectButton.y+1;

			layer2CheckButton.x = layer1CheckButton.x;
			layer2CheckButton.y = layer1CheckButton.y+layer1CheckButton.height+4;
			layer2UncheckButton.x = layer2CheckButton.x;
			layer2UncheckButton.y = layer2CheckButton.y;

			layer2SelectButton.x = layer2CheckButton.x+layer2CheckButton.width+3;
			layer2SelectButton.y = layer2CheckButton.y-1;

			saperateLine.x = layerMergeButton.x+layerMergeButton.width+5;
			saperateLine.y = 4;

			saperateLine.mouseEnabled = false;
		}

		public function initOpaSizeButtonWapper():void
		{
			initInfoButton();
			opaSizeButtonWrapper.addChild(infoPenOptions);
			opaSizeButtonWrapper.addChild(infoEraserOptions);
			opaSizeButtonWrapper.addChild(infoLineOptions);
			opaSizeButtonWrapper.addChild(infoLineOptions);
			opaSizeButtonWrapper.addChild(shapeCircle);
			opaSizeButtonWrapper.addChild(shapeRect);
			opaSizeButtonWrapper.addChild(penSmoothSliderSet);
			opaSizeButtonWrapper.addChild(penSizeGuide);
			opaSizeButtonWrapper.addChild(penSizeBox);
			opaSizeButtonWrapper.addChild(rectSizeSet);
			opaSizeButtonWrapper.addChild(circleSizeSet);
			opaSizeButtonWrapper.addChild(opaGuide);
			opaSizeButtonWrapper.addChild(opaBox);
			opaSizeButtonWrapper.addChild(penSizeSelectCursor);

			shapeCircle.x = 0;
			shapeCircle.y = Math.floor(infoPenOptions.y+infoPenOptions.height);
			shapeCircle.useHandCursor = false;
			shapeRect.x = 0+shapeCircle.x+shapeCircle.width+1;
			shapeRect.y = shapeCircle.y;
			shapeRect.useHandCursor = false;

			penSmoothSliderSet.x = Math.floor(shapeRect.x+shapeRect.width+11);
			penSmoothSliderSet.y = Math.floor(shapeRect.y)+8;

			penSmoothSliderSet["penSmoothBar"].useHandCursor = false;
			penSmoothSliderSet["penSmoothButton"].useHandCursor = false;
			penSmoothSliderSet["penSmoothSlider"].useHandCursor = false;

			penSizeGuide.x = 0;
			penSizeGuide.y = Math.floor(penSmoothSliderSet.y+penSmoothSliderSet.height)-6;
			penSizeBox.x = penSizeGuide.x+2;
			penSizeBox.y = penSizeGuide.y+2;
			penSizeSelectCursor.useHandCursor = false;

			rectSizeSet.x = Math.floor(penSizeGuide.x)+9;
			rectSizeSet.y = Math.floor(penSizeGuide.y)+10;
			circleSizeSet.x = rectSizeSet.x;
			circleSizeSet.y = rectSizeSet.y+1;

			opaGuide.x = 0;
			opaGuide.y = Math.floor(penSizeGuide.y+penSizeGuide.height+3);
			opaBox.x = opaGuide.x;
			opaBox.y = opaGuide.y;

			circleSizeSet.mouseEnabled = false;
			rectSizeSet.mouseEnabled = false;
			opaGuide.mouseEnabled = false;
			opaCursor.mouseEnabled = false;
			penSizeGuide.useHandCursor = false;
			penSizeGuide.mouseEnabled = false;
			penSizeSelectCursor.mouseEnabled = false;

			opaSizeButtonWrapper.name = "opaSizeButtonWrapper";
		}

		public function initOpaButton():void
		{
			var offset:Number = 1.0;
			for(var i:uint = 1; i <= 10; i++)
			{
				const btn:Sprite = new Sprite();

				btn.name = "alphaButton"+i;
				btn.graphics.beginFill(0xFF00FF,0.0);
				btn.graphics.drawRect(0,0,17,16);
				btn.graphics.endFill();

				if(i === 4)
				{
					offset = -1.0;
				}

				btn.x = 17*(i-1)+offset;
				btn.y = 1;


				opaBox.addChild(btn);
			}

			opaCursor.x = 0;
			opaCursor.y = 0;
			opaBox.addChild(opaCursor);
		}

		public function initPenSizeButton():void
		{
			const offset:Number = 1.0;
			for (var i:uint = 1; i <= 12; i++)
			{
				const btn:Sprite = new Sprite();

				btn.name = "nSizeButton"+i;
				btn.graphics.beginFill(0xFFFF00,0.0);
				btn.graphics.drawRect(0,0,28,28);
				btn.graphics.endFill();
				btn.x = (i >= 7) ? 28*(i-7):28*(i-1);
				btn.y = (i >= 7) ? 28 : 0;
				btn.x -= offset;
				btn.y -= offset;

				penSizeBox.addChild(btn);
			}
		}

		public function initInfoButton():void
		{
			infoPenOptions.mouseEnabled = false;
			infoPenOptions.x = 0;
			infoPenOptions.y = 0;

			infoEraserOptions.mouseEnabled = false;
			infoEraserOptions.x = 0;
			infoEraserOptions.y = 0;

			infoFillPenOptions.mouseEnabled = false;
			infoFillPenOptions.x = 0;
			infoFillPenOptions.y = 0;

			infoLineOptions.mouseEnabled = false;
			infoLineOptions.x = 0;
			infoLineOptions.y = 0;
		}

		public function controlMenu()
		{
			name = "controlBox";

			initPenSizeButton();
			initOpaButton();
			initOpaSizeButtonWapper();

			initSharpLineButtonWrapper();
			initAirBrushButtonWrapper();
			initLayerButton();

			opaSizeButtonWrapper.x = 0;
			opaSizeButtonWrapper.y = 0;

			layerButtonWrapper.x = opaSizeButtonWrapper.x;
			layerButtonWrapper.y = opaSizeButtonWrapper.y+opaSizeButtonWrapper.height-2;

			sharpLineButtonWrapper.x = layerButtonWrapper.x+layerButtonWrapper.width+9;
			sharpLineButtonWrapper.y = layerButtonWrapper.y+2;

			airBrushButtonWrapper.x = sharpLineButtonWrapper.x;
			airBrushButtonWrapper.y = sharpLineButtonWrapper.y+sharpLineButtonWrapper.height+2;

			BOX_HEIGHT = opaBox.y+opaBox.height+7;

			addChild(opaSizeButtonWrapper);
			addChild(layerButtonWrapper);
			addChild(sharpLineButtonWrapper);
			addChild(airBrushButtonWrapper);

			hintText("Pen");
		}
	}
}
