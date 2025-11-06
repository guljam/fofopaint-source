package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;
	import flash.filters.BlurFilter;
	import flash.display.DisplayObject;

	public class ToolOptionsSet extends Sprite
	{
		public const penSizeBox:Sprite = new Sprite();
		public const opaBox:Sprite = new Sprite();
		public const sharpLineButtonWrapper:Sprite = new Sprite();
		public const airBrushButtonWrapper:Sprite = new Sprite();
		public const layerButtonWrapper:Sprite = new Sprite();
		public const opaSizeButtonWrapper:Sprite = new Sprite();
		public const penShapeAndSmoothingWarpper:Sprite = new Sprite();
		public const etcOptionWrapper:Sprite = new Sprite();

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
		public var etcOptionBorder:SimpleButton;

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

		public const penSmoothSliderWapper:Sprite = new Sprite();
		public var penSmoothSlider:SimpleButton;
		public var penSmoothSliderCursor:SimpleButton;

		public var layer1CheckedButton:SimpleButton;
		public var layer1UncheckedButton:SimpleButton;
		public var layer2CheckedButton:SimpleButton;
		public var layer2UncheckedButton:SimpleButton;
		public var layerSwapButton:SimpleButton;
		public var layerMergeButton:SimpleButton;
		public var saperateLine:SimpleButton;

		private var layerVisibleBackup:Array;
		private const blurFilter:BlurFilter = new BlurFilter(3, 3, 2);

		private const BOX_WIDTH:Number = 180;
		private var BOX_HEIGHT:Number = 260;

		private const opColor:ColorTransform = new ColorTransform();

		public function restoreDisabledButtons():void
		{
			etcOptionWrapper.alpha = 1.0;
			penSizeGuide.alpha = 1.0;
			penSizeBox.alpha = 1.0;
			rectSizeSet.alpha = 1.0;
			circleSizeSet.alpha = 1.0;
			opaGuide.alpha = 1.0;
			penSizeSelectCursor.alpha = 1.0;
		}

		public function isSizeButtonsDisabled():Boolean
		{
			return penSizeGuide.alpha < 1.0;
		}

		public function updateButtonsAlphaFillPenSelected(alp:Number):void
		{
			penSizeGuide.alpha = alp;
			penSizeBox.alpha = alp;
			penSizeSelectCursor.alpha = alp;
			rectSizeSet.alpha = alp;
			circleSizeSet.alpha = alp;
			shapeRect.alpha = alp;
			shapeCircle.alpha = alp;
			penSmoothSliderWapper.alpha = alp;
			layer1CheckedButton.alpha = alp;
			layer1UncheckedButton.alpha = alp;
			layer2CheckedButton.alpha = alp;
			layer2UncheckedButton.alpha = alp;
		}

		public function disableButtonFillPenStarted(offAlpha:Number):void
		{
			etcOptionWrapper.alpha = offAlpha;
			penSizeGuide.alpha = offAlpha;
			penSizeBox.alpha = offAlpha;
			rectSizeSet.alpha = offAlpha;
			circleSizeSet.alpha = offAlpha;
			penSizeSelectCursor.alpha = offAlpha;
		}

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
			const opColor:ColorTransform = new ColorTransform();
			opColor.color = op;

			// 모든 UI 요소를 배열에 담기
			var uiElements:Array = [
				etcOptionBorder,
				infoPenOptions,
				infoEraserOptions,
				infoFillPenOptions,
				infoLineOptions,

				layer1SelectButton,
				layer1UncheckedButton,
				layer1CheckedButton,

				layer2SelectButton,
				layer2UncheckedButton,
				layer2CheckedButton,

				layerSwapButton,
				layerMergeButton,

				shapeRect,
				shapeCircle,
				rectSizeSet,
				circleSizeSet,
				penSizeGuide,

				sharpLineText,
				sharpLineONButton,
				sharpLineOFFButton,

				airBrushText,
				airBrushOFFButton,
				airBrushONButton,

				opaGuide,
				saperateLine,

				penSmoothSlider,
				penSmoothSliderCursor
			];

			var alphaSave:Number;
			// for문으로 순회하면서 적용
			for each (var element:DisplayObject in uiElements)
			{
				alphaSave = element.alpha;
				element.transform.colorTransform = opColor;
				element.alpha = alphaSave;
			}
		}
		// public function changeUIColor(op:uint):void
		// {
		// 	var alphaBackup:Number;
		// 	const opColor:ColorTransform = new ColorTransform()
		// 	opColor.color = op;
			
		// 	etcOptionBorder.transform.colorTransform = opColor;
		// 	infoPenOptions.transform.colorTransform = opColor;
		// 	infoEraserOptions.transform.colorTransform = opColor;
		// 	infoFillPenOptions.transform.colorTransform = opColor;
		// 	infoLineOptions.transform.colorTransform = opColor;

		// 	alphaBackup = layer1SelectButton.alpha;
		// 	layer1SelectButton.transform.colorTransform = opColor;
		// 	layer1SelectButton.alpha = alphaBackup;
		// 	layer1UncheckedButton.transform.colorTransform = opColor;
		// 	layer1CheckedButton.transform.colorTransform = opColor;

		// 	alphaBackup = layer2SelectButton.alpha;
		// 	layer2SelectButton.transform.colorTransform = opColor;
		// 	layer2SelectButton.alpha = alphaBackup;
		// 	layer2UncheckedButton.transform.colorTransform = opColor;
		// 	layer2CheckedButton.transform.colorTransform = opColor;

		// 	layerSwapButton.transform.colorTransform = opColor;
		// 	layerMergeButton.transform.colorTransform = opColor;
			
		// 	alphaBackup = shapeRect.alpha;
		// 	shapeRect.transform.colorTransform = opColor;
		// 	alphaBackup = shapeRect.alpha;
		// 	shapeCircle.transform.colorTransform = opColor;
		// 	rectSizeSet.transform.colorTransform = opColor;
		// 	circleSizeSet.transform.colorTransform = opColor;
		// 	penSizeGuide.transform.colorTransform = opColor;

		// 	sharpLineText.transform.colorTransform = opColor;
		// 	sharpLineONButton.transform.colorTransform = opColor;
		// 	sharpLineOFFButton.transform.colorTransform = opColor;

		// 	airBrushText.transform.colorTransform = opColor;
		// 	airBrushOFFButton.transform.colorTransform = opColor;
		// 	airBrushONButton.transform.colorTransform = opColor;

		// 	opaGuide.transform.colorTransform = opColor;
		// 	saperateLine.transform.colorTransform = opColor;

		// 	penSmoothSlider.transform.colorTransform = opColor;
		// 	penSmoothSliderCursor.transform.colorTransform = opColor;
		// }

		public function updatePenShapeSet(flag:Boolean):void // true이면 rect임
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
			if (toolStr === "Pen")
			{
				infoPenOptions.visible = true;
				infoEraserOptions.visible = false;
				infoFillPenOptions.visible = false;
				infoLineOptions.visible = false;
			}
			else if (toolStr === "Eraser")
			{
				infoPenOptions.visible = false;
				infoEraserOptions.visible = true;
				infoFillPenOptions.visible = false;
				infoLineOptions.visible = false;
			}
			else if (toolStr === "FillPen")
			{
				infoPenOptions.visible = false;
				infoEraserOptions.visible = false;
				infoFillPenOptions.visible = true;
				infoLineOptions.visible = false;
			}
			else if (toolStr === "Line")
			{
				infoPenOptions.visible = false;
				infoEraserOptions.visible = false;
				infoFillPenOptions.visible = false;
				infoLineOptions.visible = true;
			}
		}

		public function movePenSizeCursor(index:uint):void
		{
			const btn:Sprite = penSizeBox.getChildByName("nSizeButton" + index) as Sprite;

			if (btn)
			{
				penSizeSelectCursor.x = penSizeBox.x + btn.x;
				penSizeSelectCursor.y = penSizeBox.y + btn.y;
			}
		}

		public function initAirBrushButtonWrapper():void
		{
			const w:Number = airBrushOFFButton.width + sharpLineText.width + 7;
			const h:Number = airBrushOFFButton.height + 2;

			airBrushButtonWrapper.graphics.beginFill(0xFF0000, 0);
			airBrushButtonWrapper.graphics.drawRect(0, 0, w, h);
			airBrushButtonWrapper.graphics.endFill();

			airBrushOFFButton.mouseEnabled = false;
			airBrushONButton.mouseEnabled = false;
			airBrushText.mouseEnabled = false;

			airBrushButtonWrapper.addChild(airBrushOFFButton);
			airBrushButtonWrapper.addChild(airBrushONButton);
			airBrushButtonWrapper.addChild(airBrushText);

			airBrushONButton.x = 1;
			airBrushONButton.y = 1;
			airBrushOFFButton.x = airBrushONButton.x;
			airBrushOFFButton.y = airBrushONButton.y;
			airBrushOFFButton.visible = false;

			airBrushText.x = airBrushOFFButton.x + airBrushOFFButton.width + 3;
			airBrushText.y = airBrushOFFButton.y + 2;

			airBrushONButton.mouseEnabled = false;
			airBrushOFFButton.mouseEnabled = false;
			airBrushText.mouseEnabled = false;

			airBrushButtonWrapper.name = "airBrushButtonWrapper";
		}

		public function initSharpLineButtonWrapper():void
		{
			const w:Number = sharpLineOFFButton.width + sharpLineText.width + 7;
			const h:Number = sharpLineOFFButton.height + 2;

			sharpLineButtonWrapper.graphics.beginFill(0xFF0000, 0.0);
			sharpLineButtonWrapper.graphics.drawRect(0, 0, w, h);
			sharpLineButtonWrapper.graphics.endFill();

			sharpLineOFFButton.mouseEnabled = false;
			sharpLineONButton.mouseEnabled = false;
			sharpLineText.mouseEnabled = false;

			sharpLineButtonWrapper.addChild(sharpLineOFFButton);
			sharpLineButtonWrapper.addChild(sharpLineONButton);
			sharpLineButtonWrapper.addChild(sharpLineText);

			sharpLineONButton.x = 1;
			sharpLineONButton.y = 1;
			sharpLineOFFButton.x = sharpLineONButton.x;
			sharpLineOFFButton.y = sharpLineONButton.y;
			sharpLineOFFButton.visible = false;

			sharpLineText.x = sharpLineOFFButton.x + sharpLineOFFButton.width + 3;
			sharpLineText.y = sharpLineOFFButton.y + 1;

			sharpLineOFFButton.mouseEnabled = false;
			sharpLineONButton.mouseEnabled = false;
			sharpLineText.mouseEnabled = false;

			sharpLineButtonWrapper.name = "sharpLineButtonWrapper";
		}

		public function initLayerButton():void
		{
			layer1CheckedButton.visible = false;
			layer2CheckedButton.visible = false;
			layer1SelectButton.useHandCursor = false;
			layer2SelectButton.useHandCursor = false;
			layer1CheckedButton.useHandCursor = false;
			layer1UncheckedButton.useHandCursor = false;
			layer2CheckedButton.useHandCursor = false;
			layer2UncheckedButton.useHandCursor = false;
			layerSwapButton.useHandCursor = false;
			layerMergeButton.useHandCursor = false;

			layerButtonWrapper.addChild(layer1SelectButton);
			layerButtonWrapper.addChild(layer2SelectButton);
			layerButtonWrapper.addChild(layer1CheckedButton);
			layerButtonWrapper.addChild(layer1UncheckedButton);
			layerButtonWrapper.addChild(layer2CheckedButton);
			layerButtonWrapper.addChild(layer2UncheckedButton);
			layerButtonWrapper.addChild(layerSwapButton);
			layerButtonWrapper.addChild(layerMergeButton);
			layerButtonWrapper.addChild(saperateLine);

			layerSwapButton.x = 0;
			layerSwapButton.y = 0;

			layer1CheckedButton.x = layerSwapButton.x + layerSwapButton.width + 3;
			layer1CheckedButton.y = layerSwapButton.y + 2;
			layer1UncheckedButton.x = layer1CheckedButton.x;
			layer1UncheckedButton.y = layer1CheckedButton.y;

			layer1SelectButton.x = layer1CheckedButton.x + layer1CheckedButton.width + 3;
			layer1SelectButton.y = layer1CheckedButton.y - 1;

			layerMergeButton.x = layer1SelectButton.x + layer1SelectButton.width + 1;
			layerMergeButton.y = layer1SelectButton.y + 2;

			layer2CheckedButton.x = layer1CheckedButton.x;
			layer2CheckedButton.y = layer1CheckedButton.y + layer1CheckedButton.height + 4;
			layer2UncheckedButton.x = layer2CheckedButton.x;
			layer2UncheckedButton.y = layer2CheckedButton.y;

			layer2SelectButton.x = layer2CheckedButton.x + layer2CheckedButton.width + 3;
			layer2SelectButton.y = layer2CheckedButton.y - 1;

			saperateLine.x = layerMergeButton.x + layerMergeButton.width + 5;
			saperateLine.y = 4;

			saperateLine.mouseEnabled = false;
		}

		public function initPenSmoothSliderWrapper():void
		{
			penSmoothSliderWapper.name = "penSmoothSliderWapper";
			penSmoothSliderWapper.addChild(penSmoothSlider);
			penSmoothSliderWapper.addChild(penSmoothSliderCursor);

			penSmoothSlider.mouseEnabled = false;
			penSmoothSlider.x = penSmoothSliderCursor.width / 2;
			penSmoothSlider.y = penSmoothSliderCursor.height / 2 + 2;

			penSmoothSliderCursor.mouseEnabled = false;
			penSmoothSliderCursor.x = penSmoothSlider.x;
			penSmoothSliderCursor.y = penSmoothSlider.y;

			penSmoothSliderWapper.graphics.clear();
			penSmoothSliderWapper.graphics.beginFill(0xFF0000, 0.0);
			penSmoothSliderWapper.graphics.drawRect(0, 0, penSmoothSlider.x + penSmoothSlider.width + penSmoothSliderCursor.width / 2, penSmoothSliderCursor.height + 4);
			penSmoothSliderWapper.graphics.endFill();
		}

		public function initPenShapeSmoothingWarpper():void
		{
			initPenSmoothSliderWrapper();
			penShapeAndSmoothingWarpper.addChild(shapeCircle);
			penShapeAndSmoothingWarpper.addChild(shapeRect);
			penShapeAndSmoothingWarpper.addChild(penSmoothSliderWapper);

			shapeCircle.x = 5;
			shapeCircle.y = 0;
			shapeCircle.useHandCursor = false;
			shapeRect.x = shapeCircle.x + shapeCircle.width + 1;
			shapeRect.y = 1;
			shapeRect.useHandCursor = false;

			penSmoothSliderWapper.x = Math.floor(shapeRect.x + shapeRect.width + 6);
			penSmoothSliderWapper.y = Math.floor(shapeRect.y);
		}

		public function initOpaSizeButtonWapper():void
		{
			initPenSizeButton();
			initOpaButton();

			opaSizeButtonWrapper.addChild(penSizeGuide);
			opaSizeButtonWrapper.addChild(penSizeBox);
			opaSizeButtonWrapper.addChild(rectSizeSet);
			opaSizeButtonWrapper.addChild(circleSizeSet);
			opaSizeButtonWrapper.addChild(opaGuide);
			opaSizeButtonWrapper.addChild(opaBox);
			opaSizeButtonWrapper.addChild(penSizeSelectCursor);

			penSizeGuide.x = 0;
			penSizeGuide.y = 0;
			penSizeBox.x = penSizeGuide.x + 2;
			penSizeBox.y = penSizeGuide.y + 2;
			penSizeSelectCursor.x = 0;
			penSizeSelectCursor.y = 0;
			penSizeSelectCursor.useHandCursor = false;

			rectSizeSet.x = Math.floor(penSizeGuide.x) + 9;
			rectSizeSet.y = Math.floor(penSizeGuide.y) + 10;
			circleSizeSet.x = rectSizeSet.x;
			circleSizeSet.y = rectSizeSet.y + 1;

			opaGuide.x = 0;
			opaGuide.y = Math.floor(penSizeGuide.y + penSizeGuide.height + 3);
			opaBox.x = opaGuide.x;
			opaBox.y = opaGuide.y;

			circleSizeSet.mouseEnabled = false;
			rectSizeSet.mouseEnabled = false;
			opaGuide.mouseEnabled = false;
			opaCursor.mouseEnabled = false;
			penSizeGuide.mouseEnabled = false;
			penSizeSelectCursor.mouseEnabled = false;

			opaSizeButtonWrapper.name = "opaSizeButtonWrapper";
		}

		public function initOpaButton():void
		{
			var offset:Number = 1.0;
			for (var i:uint = 1; i <= 10; i++)
			{
				const btn:Sprite = new Sprite();

				btn.name = "alphaButton" + i;
				btn.graphics.beginFill(0xFF00FF, 0.0);
				btn.graphics.drawRect(0, 0, 17, 24);
				btn.graphics.endFill();

				if (i === 4)
				{
					offset = -1.0;
				}

				btn.x = 17 * (i - 1) + offset;
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

				btn.name = "nSizeButton" + i;
				btn.graphics.beginFill(0xFFFF00, 0.0);
				btn.graphics.drawRect(0, 0, 28, 28);
				btn.graphics.endFill();
				btn.x = (i >= 7) ? 28 * (i - 7) : 28 * (i - 1);
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

		private function initETCOptionsWrapper():void
		{
			initInfoButton();
			initPenShapeSmoothingWarpper();
			initLayerButton();
			initSharpLineButtonWrapper();
			initAirBrushButtonWrapper();

			etcOptionWrapper.addChild(infoPenOptions);
			etcOptionWrapper.addChild(infoEraserOptions);
			etcOptionWrapper.addChild(infoFillPenOptions);
			etcOptionWrapper.addChild(infoLineOptions);
			etcOptionWrapper.addChild(layerButtonWrapper);
			etcOptionWrapper.addChild(sharpLineButtonWrapper);
			etcOptionWrapper.addChild(airBrushButtonWrapper);
			etcOptionWrapper.addChild(penShapeAndSmoothingWarpper);
			etcOptionWrapper.addChild(etcOptionBorder);

			etcOptionBorder.mouseEnabled = false;
			etcOptionBorder.x = 0;
			etcOptionBorder.y = 0;

			infoPenOptions.x = 7;
			infoPenOptions.y = 10;
			infoEraserOptions.x = infoPenOptions.x;
			infoEraserOptions.y = infoPenOptions.y;
			infoFillPenOptions.x = infoPenOptions.x;
			infoFillPenOptions.y = infoPenOptions.y;
			infoLineOptions.x = infoPenOptions.x;
			infoLineOptions.y = infoPenOptions.y;

			layerButtonWrapper.x = 5;
			layerButtonWrapper.y = infoPenOptions.y + infoPenOptions.height;

			sharpLineButtonWrapper.x = layerButtonWrapper.x + layerButtonWrapper.width + 7;
			sharpLineButtonWrapper.y = layerButtonWrapper.y + 2;
			airBrushButtonWrapper.x = sharpLineButtonWrapper.x;
			airBrushButtonWrapper.y = sharpLineButtonWrapper.y + sharpLineButtonWrapper.height + 2;

			penShapeAndSmoothingWarpper.x = 0;
			penShapeAndSmoothingWarpper.y = layerButtonWrapper.y + layerButtonWrapper.height + 2;
		}

		public function ToolOptionsSet()
		{
			name = "controlBox";
			initOpaSizeButtonWapper();
			initETCOptionsWrapper();

			opaSizeButtonWrapper.x = 0;
			opaSizeButtonWrapper.y = etcOptionWrapper.y + etcOptionWrapper.height + 7;

			BOX_HEIGHT = opaBox.y + opaBox.height + 7;

			addChild(etcOptionWrapper);
			addChild(opaSizeButtonWrapper);

			hintText("Pen");
		}
	}
}
