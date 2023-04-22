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
		public const laggyButtonWrapper:Sprite = new Sprite();

		public var sizeSelectCursor:SimpleButton = sizeSelectCursor;
		public var rectSizeSet:SimpleButton = rectSizeSet;
		public var circleSizeSet:SimpleButton = circleSizeSet;
		public var shapeRect:SimpleButton = shapeRect;
		public var shapeCircle:SimpleButton = shapeCircle;
		public var penSizeGrid:SimpleButton = penSizeGrid;

		public var moreOptionsButton:SimpleButton = moreOptionsButton;
		public var sharpLineONButton:SimpleButton = sharpLineONButton;
		public var sharpLineOFFButton:SimpleButton = sharpLineOFFButton;
		public var sharpLineText:SimpleButton = sharpLineText;
		public var airBrushONButton:SimpleButton = airBrushONButton;
		public var airBrushOFFButton:SimpleButton = airBrushOFFButton;
		public var airBrushText:SimpleButton = airBrushText;
		public var laggyText:SimpleButton = laggyText;
		public var laggyONButton:SimpleButton = laggyONButton;
		public var laggyOFFButton:SimpleButton = laggyOFFButton;

		public var layer1SelectButton:SimpleButton = layer1SelectButton;
		public var layer2SelectButton:SimpleButton = layer2SelectButton;
		public var layer1Button:SimpleButton = layer1Button;
		public var layer2Button:SimpleButton = layer2Button;
		public var controlInfo:TextField = controlInfo;
		public var penSmoothSliderSet:Sprite = penSmoothSliderSet;

		public var layer1VisibleButton:SimpleButton = layer1VisibleButton;
		public var layer1InvisibleButton:SimpleButton = layer1InvisibleButton;
		public var layer2VisibleButton:SimpleButton = layer1VisibleButton;
		public var layer2InvisibleButton:SimpleButton = layer2InvisibleButton;
		public var layerSwapButton:SimpleButton = layerSwapButton;
		public var layerMergeButton:SimpleButton = layerMergeButton;

		private var layerVisibleBackup:Array;
		private const blurFilter:BlurFilter = new BlurFilter(3, 3, 2);

		private const BOX_WIDTH:Number = 180;
		private var BOX_HEIGHT:Number = 260;

		public function moreOptionsOFF():void
		{
			moreOptionsBox.visible = false;

			layer1VisibleButton.visible = layerVisibleBackup[0];
			layer1InvisibleButton.visible = layerVisibleBackup[1];
			layer2VisibleButton.visible = layerVisibleBackup[2];
			layer2InvisibleButton.visible = layerVisibleBackup[3];

			layer1SelectButton.visible = true;
			layer2SelectButton.visible = true;

			layerSwapButton.visible = true;
			layerMergeButton.visible = true;
			moreOptionsButton.visible = true;
		}

		public function moreOptionsON():void
		{
			layerVisibleBackup = [layer1VisibleButton.visible,layer1InvisibleButton.visible
								 ,layer2VisibleButton.visible,layer2InvisibleButton.visible];

			layer1VisibleButton.visible = false;
			layer1InvisibleButton.visible = false;
			layer2VisibleButton.visible = false;
			layer2InvisibleButton.visible = false;

			layer1SelectButton.visible = false;
			layer2SelectButton.visible = false;

			layerSwapButton.visible = false;
			layerMergeButton.visible = false;
			moreOptionsButton.visible = false;

			moreOptionsBox.visible = true;
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

		public function changeUIColor(base:uint, op:uint):void
		{
			const b:ColorTransform = new ColorTransform();
			const o:ColorTransform = new ColorTransform();
			var alphaBackup:Number; //레이어 버튼이 색깔 바꾸면 알파가 초기화 되는 버그있어서 수동으로 만들어줌

			b.color = base;
			o.color = op;

			controlInfo.textColor = op;

			alphaBackup = layer1SelectButton.alpha;
			layer1SelectButton.transform.colorTransform = o;
			layer1SelectButton.alpha = alphaBackup;
			layer1InvisibleButton.transform.colorTransform = o;
			layer1VisibleButton.transform.colorTransform = o;

			alphaBackup = layer2SelectButton.alpha;
			layer2SelectButton.transform.colorTransform = o;
			layer2SelectButton.alpha = alphaBackup;
			layer2InvisibleButton.transform.colorTransform = o;
			layer2VisibleButton.transform.colorTransform = o;

			layerSwapButton.transform.colorTransform = o;
			layerMergeButton.transform.colorTransform = o;

			shapeRect.transform.colorTransform = o;
			shapeCircle.transform.colorTransform = o;
			rectSizeSet.transform.colorTransform = o;
			circleSizeSet.transform.colorTransform = o;
			penSizeGrid.transform.colorTransform = o;

			sharpLineText.transform.colorTransform = o;
			sharpLineONButton.transform.colorTransform = o;
			sharpLineOFFButton.transform.colorTransform = o;

			airBrushText.transform.colorTransform = o;
			airBrushOFFButton.transform.colorTransform = o;
			airBrushONButton.transform.colorTransform = o;

			laggyText.transform.colorTransform = o;
			laggyOFFButton.transform.colorTransform = o;
			laggyONButton.transform.colorTransform = o;

			moreOptionsButton.transform.colorTransform = o;

			opaBox.alphaBG.transform.colorTransform = o;

			penSmoothSliderSet["penSmoothBar"].transform.colorTransform = o;
			penSmoothSliderSet["penSmoothButton"].transform.colorTransform = o;
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

		public function initLaggyButtonWrapper():void
		{
			const g:Graphics = laggyButtonWrapper.graphics;
			const w:Number = laggyOFFButton.width+sharpLineText.width-20;
			const h:Number = laggyOFFButton.height+2;

			g.beginFill(0xFFFF00,0);
			g.drawRect(0,0,w,h);
			g.endFill();

			laggyButtonWrapper.addChild(laggyOFFButton);
			laggyButtonWrapper.addChild(laggyONButton);
			laggyButtonWrapper.addChild(laggyText);

			laggyONButton.x = 0;
			laggyONButton.y = 0;
			laggyOFFButton.x = laggyONButton.x;
			laggyOFFButton.y = laggyONButton.y;
			laggyOFFButton.visible = false;

			laggyText.x = laggyOFFButton.x+laggyOFFButton.width+2;
			laggyText.y = laggyOFFButton.y;

			laggyOFFButton.useHandCursor = false;
			laggyONButton.useHandCursor = false;
			laggyText.useHandCursor = false;

			laggyButtonWrapper.name = "laggyButtonWrapper";
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
			moreOptionsBox.addChild(laggyButtonWrapper);

			laggyButtonWrapper.x = sharpLineButtonWrapper.x+sharpLineButtonWrapper.width+8;
			laggyButtonWrapper.y = sharpLineButtonWrapper.y;

			airBrushButtonWrapper.x = sharpLineButtonWrapper.x;
			airBrushButtonWrapper.y = sharpLineButtonWrapper.y+sharpLineButtonWrapper.height+2;
			
			moreOptionsButton.useHandCursor = false;
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
			initLaggyButtonWrapper();
			initMoreOptionsBox();

			layer1VisibleButton.visible = false;
			layer2VisibleButton.visible = false;
			layer1SelectButton.useHandCursor = false;
			layer2SelectButton.useHandCursor = false;
			layer1VisibleButton.useHandCursor = false;
			layer1InvisibleButton.useHandCursor = false;
			layer2VisibleButton.useHandCursor = false;
			layer2InvisibleButton.useHandCursor = false;
			layerSwapButton.useHandCursor = false;
			layerMergeButton.useHandCursor = false;

			layerSwapButton.x = opaBox.x;
			layerSwapButton.y = opaBox.y+opaBox.height-3;
			
			layer1VisibleButton.x = layerSwapButton.x+layerSwapButton.width+3;
			layer1VisibleButton.y = layerSwapButton.y+2;
			layer1InvisibleButton.x = layer1VisibleButton.x;
			layer1InvisibleButton.y = layer1VisibleButton.y;
			
			layer1SelectButton.x = layer1VisibleButton.x+layer1VisibleButton.width+2;
			layer1SelectButton.y = layer1VisibleButton.y;

			layerMergeButton.x = layer1SelectButton.x+layer1SelectButton.width+3;
			layerMergeButton.y = layer1SelectButton.y+7;

			layer2VisibleButton.x = layer1VisibleButton.x;
			layer2VisibleButton.y = layer1VisibleButton.y+layer1VisibleButton.height+4;
			layer2InvisibleButton.x = layer2VisibleButton.x;
			layer2InvisibleButton.y = layer2VisibleButton.y;

			layer2SelectButton.x = layer2VisibleButton.x+layer2VisibleButton.width+2;
			layer2SelectButton.y = layer2VisibleButton.y;

			moreOptionsButton.x = layerMergeButton.x+layerMergeButton.width;
			moreOptionsButton.y = layer2VisibleButton.y-12;

			moreOptionsBox.x = opaBox.x;
			moreOptionsBox.y = opaBox.y+opaBox.height;

			BOX_HEIGHT = opaBox.y+opaBox.height+7;

			addChild(penSizeGrid);
			addChild(penSizeTransButtonBox);
			addChild(opaBox);
			addChild(moreOptionsButton);
			addChild(moreOptionsBox);
			setChildIndex(controlInfo, this.numChildren - 1);
			setChildIndex(sizeSelectCursor, this.numChildren - 1);

			penSizeGrid.useHandCursor = false;

			setChildIndex(controlInfo,0);
		}
	}
}


