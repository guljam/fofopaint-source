package
{
	import flash.display.Sprite;
	import flash.display.Graphics;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	import flash.filters.BlurFilter;

	public class controlMenu extends Sprite
	{
		public const penSizeTransButtonBox:penSizeTransButtonSet = new penSizeTransButtonSet();
		public const opaBox:opaButtons = new opaButtons();
		public const moreOptionsBox:Sprite = new Sprite();
		public const sharpLineButtonWrapper:Sprite = new Sprite();
		public const airBrushButtonWrapper:Sprite = new Sprite();
		public const layerButtonWrapper:Sprite = new Sprite();

		public var sizeSelectCursor:SimpleButton;
		public var rectSizeSet:SimpleButton;
		public var circleSizeSet:SimpleButton;
		public var shapeRect:SimpleButton;
		public var shapeCircle:SimpleButton;
		public var penSizeGrid:SimpleButton;

		public var moreOptionsButton:SimpleButton;
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
		public var controlInfo:TextField;
		public var penSmoothSliderSet:Sprite;

		public var layer1CheckButton:SimpleButton;
		public var layer1UncheckButton:SimpleButton;
		public var layer2CheckButton:SimpleButton;
		public var layer2UncheckButton:SimpleButton;
		public var layerSwapButton:SimpleButton;
		public var layerMergeButton:SimpleButton;

		private var layerVisibleBackup:Array;
		private const blurFilter:BlurFilter = new BlurFilter(3, 3, 2);

		private const BOX_WIDTH:Number = 180;
		private var BOX_HEIGHT:Number = 260;

		private const opColor:ColorTransform = new ColorTransform();

		public function moreOptionsOFF():void
		{
			moreOptionsBox.visible = false;

			layer1CheckButton.visible = layerVisibleBackup[0];
			layer1UncheckButton.visible = layerVisibleBackup[1];
			layer2CheckButton.visible = layerVisibleBackup[2];
			layer2UncheckButton.visible = layerVisibleBackup[3];

			layer1SelectButton.visible = true;
			layer2SelectButton.visible = true;

			layerSwapButton.visible = true;
			layerMergeButton.visible = true;
			moreOptionsButton.visible = true;
		}

		public function moreOptionsON():void
		{
			layerVisibleBackup = [layer1CheckButton.visible,layer1UncheckButton.visible
								 ,layer2CheckButton.visible,layer2UncheckButton.visible];

			layer1CheckButton.visible = false;
			layer1UncheckButton.visible = false;
			layer2CheckButton.visible = false;
			layer2UncheckButton.visible = false;

			layer1SelectButton.visible = false;
			layer2SelectButton.visible = false;

			layerSwapButton.visible = false;
			layerMergeButton.visible = false;
			moreOptionsButton.visible = false;

			moreOptionsBox.visible = true;
		}

		public function isMoreOptionsON():Boolean
		{
			return moreOptionsBox.visible;
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
			var alphaBackup:Number; //레이어 버튼이 색깔 바꾸면 알파가 초기화 되는 버그있어서 수동으로 만들어줌
			opColor.color = op;

			controlInfo.textColor = op;

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
			penSizeGrid.transform.colorTransform = opColor;

			sharpLineText.transform.colorTransform = opColor;
			sharpLineONButton.transform.colorTransform = opColor;
			sharpLineOFFButton.transform.colorTransform = opColor;

			airBrushText.transform.colorTransform = opColor;
			airBrushOFFButton.transform.colorTransform = opColor;
			airBrushONButton.transform.colorTransform = opColor;

			moreOptionsButton.transform.colorTransform = opColor;

			opaBox.alphaBG.transform.colorTransform = opColor;

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

		public function hintText(str:String):void
		{
			if(str.lastIndexOf("\n") === -1)
			{
				shapeRect.visible = true;
				shapeCircle.visible = true;
				penSmoothSliderSet.visible = true;
			}
			else
			{
				shapeRect.visible = false;
				shapeCircle.visible = false;
				penSmoothSliderSet.visible = false;
			}

			controlInfo.text = str;
		}

		public function movePenSizeCursor(index:uint):void
		{
			const btn:SimpleButton = penSizeTransButtonBox.getChildByName("nSizeButton"+index) as SimpleButton;
			if (btn)
			{
				const _sizeSelectCursor:SimpleButton = sizeSelectCursor;

				_sizeSelectCursor.x = penSizeTransButtonBox.x+btn.x;
				_sizeSelectCursor.y = penSizeTransButtonBox.y+btn.y;
				btn.useHandCursor = false;
			}
		}

		public function initAirBrushButtonWrapper():void
		{
			const g:Graphics = airBrushButtonWrapper.graphics;
			const w:Number = airBrushOFFButton.width+sharpLineText.width;
			const h:Number = airBrushOFFButton.height+2;

			g.beginFill(0xFF0000,0);
			g.drawRect(0,0,w,h);
			g.endFill();

			airBrushButtonWrapper.addChild(airBrushOFFButton);
			airBrushButtonWrapper.addChild(airBrushONButton);
			airBrushButtonWrapper.addChild(airBrushText);

			airBrushONButton.x = 0;
			airBrushONButton.y = 0;
			airBrushOFFButton.x = airBrushONButton.x;
			airBrushOFFButton.y = airBrushONButton.y;
			airBrushOFFButton.visible = false;

			airBrushText.x = airBrushOFFButton.x+airBrushOFFButton.width+2;
			airBrushText.y = airBrushOFFButton.y+2;

			airBrushONButton.useHandCursor = false;
			airBrushOFFButton.useHandCursor = false;
			airBrushText.useHandCursor = false;

			airBrushButtonWrapper.name = "airBrushButtonWrapper";
		}

		public function initSharpLineButtonWrapper():void
		{
			const g:Graphics = sharpLineButtonWrapper.graphics;
			const w:Number = sharpLineOFFButton.width+sharpLineText.width+4;
			const h:Number = sharpLineOFFButton.height+2;

			g.beginFill(0xFF0000,0);
			g.drawRect(0,0,w,h);
			g.endFill();

			sharpLineButtonWrapper.addChild(sharpLineOFFButton);
			sharpLineButtonWrapper.addChild(sharpLineONButton);
			sharpLineButtonWrapper.addChild(sharpLineText);

			sharpLineONButton.x = 0;
			sharpLineONButton.y = 0;
			sharpLineOFFButton.x = sharpLineONButton.x;
			sharpLineOFFButton.y = sharpLineONButton.y;
			sharpLineOFFButton.visible = false;

			sharpLineText.x = sharpLineOFFButton.x+sharpLineOFFButton.width;
			sharpLineText.y = sharpLineOFFButton.y+2;

			sharpLineOFFButton.useHandCursor = false;
			sharpLineONButton.useHandCursor = false;
			sharpLineText.useHandCursor = false;

			sharpLineButtonWrapper.name = "sharpLineButtonWrapper";
		}

		public function initMoreOptionsBox():void
		{
			const g:Graphics = moreOptionsBox.graphics;

			g.beginFill(0xFF0000,0);
			g.drawRect(0,-2,170,43);
			g.endFill();

			moreOptionsBox.visible = false;
			moreOptionsBox.addChild(sharpLineButtonWrapper);
			moreOptionsBox.addChild(airBrushButtonWrapper);

			airBrushButtonWrapper.x = sharpLineButtonWrapper.x+sharpLineButtonWrapper.width+8;
			airBrushButtonWrapper.y = sharpLineButtonWrapper.y;

			moreOptionsButton.useHandCursor = false;
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

			layerButtonWrapper.x = opaBox.x;
			layerButtonWrapper.y = opaBox.y+opaBox.height-3;

			layerSwapButton.x = 0;
			layerSwapButton.y = 0;

			layer1CheckButton.x = layerSwapButton.x+layerSwapButton.width+3;
			layer1CheckButton.y = layerSwapButton.y+2;
			layer1UncheckButton.x = layer1CheckButton.x;
			layer1UncheckButton.y = layer1CheckButton.y;

			layer1SelectButton.x = layer1CheckButton.x+layer1CheckButton.width+2;
			layer1SelectButton.y = layer1CheckButton.y;

			layerMergeButton.x = layer1SelectButton.x+layer1SelectButton.width+3;
			layerMergeButton.y = layer1SelectButton.y+7;

			layer2CheckButton.x = layer1CheckButton.x;
			layer2CheckButton.y = layer1CheckButton.y+layer1CheckButton.height+4;
			layer2UncheckButton.x = layer2CheckButton.x;
			layer2UncheckButton.y = layer2CheckButton.y;

			layer2SelectButton.x = layer2CheckButton.x+layer2CheckButton.width+2;
			layer2SelectButton.y = layer2CheckButton.y;
		}

		public function initPenSizeButton():void
		{
			const _penSizeTransButtonBox:penSizeTransButtonSet = penSizeTransButtonBox;
			var btn:SimpleButton;
			for (var i:int = 1; i <= 12; i++)
			{
				btn = _penSizeTransButtonBox.getChildByName("nSizeButton"+i) as SimpleButton;

				if (btn)
				{
					btn.useHandCursor = false;
				}
			}
		}

		public function controlMenu()
		{
			name = "controlBox";
			// initPenSizeCursor();
			// initShapeSet();
			initPenSizeButton();

			const floor:Function = Math.floor;
			const offsetX:Number = 0;
			const infoBottom:Number = floor(controlInfo.y+controlInfo.height+1);

			controlInfo.width = BOX_WIDTH - 5;
			controlInfo.height = 50;
			controlInfo.x = -3;
			controlInfo.y = 0;

			shapeCircle.x = offsetX;
			shapeCircle.y = infoBottom;
			shapeCircle.useHandCursor = false;
			shapeRect.x = offsetX+shapeCircle.x+shapeCircle.width+5;
			shapeRect.y = infoBottom;
			shapeRect.useHandCursor = false;

			penSmoothSliderSet.x = floor(shapeRect.x+shapeRect.width+11);
			penSmoothSliderSet.y = floor(shapeRect.y)+5;

			penSmoothSliderSet["penSmoothBar"].useHandCursor = false;
			penSmoothSliderSet["penSmoothButton"].useHandCursor = false;
			penSmoothSliderSet["penSmoothSlider"].useHandCursor = false;

			penSizeGrid.x = offsetX;
			penSizeGrid.y = floor(penSmoothSliderSet.y+penSmoothSliderSet.height)-10;
			penSizeTransButtonBox.x = penSizeGrid.x+2;
			penSizeTransButtonBox.y = penSizeGrid.y+2;

			sizeSelectCursor.useHandCursor = false;

			rectSizeSet.x = floor(penSizeGrid.x)+9;
			rectSizeSet.y = floor(penSizeGrid.y)+10;
			circleSizeSet.x = rectSizeSet.x;
			circleSizeSet.y = rectSizeSet.y+1;

			opaBox.x = offsetX;
			opaBox.y = floor(penSizeGrid.y+penSizeGrid.height+3);

			initSharpLineButtonWrapper();
			initAirBrushButtonWrapper();
			initMoreOptionsBox();
			initLayerButton();

			moreOptionsButton.x = layerButtonWrapper.x+layerButtonWrapper.width;
			moreOptionsButton.y = layerButtonWrapper.y+layerButtonWrapper.height/2-moreOptionsButton.height/2;

			moreOptionsBox.x = opaBox.x;
			moreOptionsBox.y = opaBox.y+opaBox.height;

			BOX_HEIGHT = opaBox.y+opaBox.height+7;

			addChild(penSizeGrid);
			addChild(penSizeTransButtonBox);
			addChild(opaBox);
			addChild(moreOptionsButton);
			addChild(moreOptionsBox);
			addChild(layerButtonWrapper);
			setChildIndex(controlInfo, this.numChildren-1);
			setChildIndex(sizeSelectCursor, this.numChildren-1);

			penSizeGrid.useHandCursor = false;

			setChildIndex(controlInfo,0);
		}
	}
}
