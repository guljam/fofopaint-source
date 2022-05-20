package
{

	import flash.display.Sprite;
	// import flash.display.Shape;
	import flash.display.Graphics;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	import flash.filters.BlurFilter;

	public class controlMenu extends Sprite
	{

		public const penSizeTransButtonBox:penSizeTransButtonSet = new penSizeTransButtonSet();
		public const opaBox:opaButtons = new opaButtons();
		public const pixelSnapButtonWrapper:Sprite = new Sprite();
		public const subLayerButtonWrapper:Sprite = new Sprite();
		public const airBrushButtonWrapper:Sprite = new Sprite();

		public var sizeSelectCursor:SimpleButton = sizeSelectCursor;
		public var rectSizeSet:SimpleButton = rectSizeSet;
		public var circleSizeSet:SimpleButton = circleSizeSet;
		public var shapeRect:SimpleButton = shapeRect;
		public var shapeCircle:SimpleButton = shapeCircle;
		public var penSizeGrid:SimpleButton = penSizeGrid;
		public var pixelSnapONButton:SimpleButton = pixelSnapONButton;
		public var pixelSnapOFFButton:SimpleButton = pixelSnapOFFButton;
		public var pixelSnapText:SimpleButton = pixelSnapText;
		public var subLayerONButton:SimpleButton = subLayerONButton;
		public var subLayerOFFButton:SimpleButton = subLayerOFFButton;
		public var subLayerText:SimpleButton = subLayerText;
		public var airBrushONButton:SimpleButton = airBrushONButton;
		public var airBrushOFFButton:SimpleButton = airBrushOFFButton;
		public var airBrushText:SimpleButton = airBrushText;
		public var controlInfo:TextField = controlInfo;
		public var penSmoothSliderSet:Sprite = penSmoothSliderSet;
		private const blurFilter:BlurFilter = new BlurFilter(3, 3, 2);

		private const BOX_WIDTH:Number = 180;
		private var BOX_HEIGHT:Number = 260;

		public function blurShapeSetON():void
		{
			rectSizeSet.filters = [blurFilter];
			circleSizeSet.filters = [blurFilter];
		}

		public function blurShapeSetOFF():void
		{
			rectSizeSet.filters = [];
			circleSizeSet.filters = [];
		}

		// public function initShapeSet():void
		// {
		// const floor:Function = Math.floor;
		// const ceil:Function = Math.ceil;
		// const sizeArr:Array = [1,2,3,5,7,8,11,13,17,21,21,21]; //main이랑 맞춰야댐
		// const offset:Number = 14;
		// var g:Graphics = rectSizeSet.graphics;
		// var x:Number = 0;
		// var y:Number = 0;
		// var size:Number = 2;
		// var hsize:Number = 1;

		// g.clear();
		// for(var i:int=0;i<12;i++)
		// {
		// g.beginFill(0xCCCCCC);
		// size = sizeArr[i];
		// hsize = floor(size/2);
		// g.drawRect(x*28-hsize+offset,y-hsize+offset,size,size); //28이 그리드 간격임
		// x++;
		// if(i===5)
		// {
		// x = 0;
		// y = 28;
		// }
		// }
		// g.endFill();

		// g = circleSizeSet.graphics;
		// x = 0;
		// y = 0;
		// for(i=0;i<12;i++)
		// {
		// g.beginFill(0xCCCCCC);
		// size = floor(sizeArr[i]/2+0.5);
		// g.drawCircle(x*28+offset,y+offset,size); //28이 그리드 간격임
		// x++;
		// if(i===5)
		// {
		// x = 0;
		// y = 28;
		// }
		// g.endFill();
		// }
		// }

		public function changeUIColor(base:uint, op:uint):void
		{
			const b:ColorTransform = new ColorTransform();
			const o:ColorTransform = new ColorTransform();
			b.color = base;
			o.color = op;

			controlInfo.textColor = op;
			pixelSnapText.transform.colorTransform = o;
			subLayerText.transform.colorTransform = o;
			airBrushText.transform.colorTransform = o;
			shapeRect.transform.colorTransform = o;
			shapeCircle.transform.colorTransform = o;
			rectSizeSet.transform.colorTransform = o;
			circleSizeSet.transform.colorTransform = o;
			penSizeGrid.transform.colorTransform = o;
			// sizeSelectCursor.transform.colorTransform = o;

			pixelSnapONButton.transform.colorTransform = o;
			pixelSnapOFFButton.transform.colorTransform = o;
			airBrushOFFButton.transform.colorTransform = o;
			airBrushONButton.transform.colorTransform = o;
			subLayerOFFButton.transform.colorTransform = o;
			subLayerONButton.transform.colorTransform = o;

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
			controlInfo.text = str;
		}

		// public function initPenSizeCursor():void
		// {
		// const g:Graphics = sizeSelectCursor.graphics;
		// const btn:SimpleButton = penSizeTransButtonBox.getChildByName("nSizeButton1") as SimpleButton;

		// g.clear();
		// g.lineStyle(1,0xFF6600,1.0,true);
		// g.drawRect(0,0,btn.width,btn.height);
		// }

		public function movePenSizeCursor(index:uint):void
		{
			const btn:SimpleButton = penSizeTransButtonBox.getChildByName("nSizeButton" + index) as SimpleButton;
			if (btn)
			{
				const _sizeSelectCursor:SimpleButton = sizeSelectCursor;

				_sizeSelectCursor.x = penSizeTransButtonBox.x + btn.x;
				_sizeSelectCursor.y = penSizeTransButtonBox.y + btn.y;
				btn.useHandCursor = false;
			}
		}

		public function initAirBrushButtonWrapper():void
		{
			const g:Graphics = airBrushButtonWrapper.graphics;
			const w:Number = airBrushOFFButton.width + pixelSnapText.width;
			const h:Number = airBrushOFFButton.height + 2;

			g.beginFill(0xFF0000, 0);
			g.drawRect(0, 0, w, h);
			g.endFill();

			airBrushButtonWrapper.addChild(airBrushOFFButton);
			airBrushButtonWrapper.addChild(airBrushONButton);
			airBrushButtonWrapper.addChild(airBrushText);

			airBrushONButton.x = 0;
			airBrushONButton.y = 0;
			airBrushOFFButton.x = airBrushONButton.x;
			airBrushOFFButton.y = airBrushONButton.y;
			airBrushOFFButton.visible = false;

			airBrushText.x = airBrushOFFButton.x + airBrushOFFButton.width + 4;
			airBrushText.y = airBrushOFFButton.y;

			airBrushONButton.useHandCursor = false;
			airBrushOFFButton.useHandCursor = false;

			airBrushButtonWrapper.name = "airBrushButtonWrapper";
		}

		public function initSubLayerButtonWrapper():void
		{
			const g:Graphics = subLayerButtonWrapper.graphics;
			const w:Number = subLayerOFFButton.width + pixelSnapText.width;
			const h:Number = subLayerOFFButton.height + 2;

			g.beginFill(0xFF0000, 0);
			g.drawRect(0, 0, w, h);
			g.endFill();

			subLayerButtonWrapper.addChild(subLayerOFFButton);
			subLayerButtonWrapper.addChild(subLayerONButton);
			subLayerButtonWrapper.addChild(subLayerText);

			subLayerONButton.x = 0;
			subLayerONButton.y = 0;
			subLayerOFFButton.x = subLayerONButton.x;
			subLayerOFFButton.y = subLayerONButton.y;
			subLayerOFFButton.visible = false;

			subLayerText.x = subLayerOFFButton.x + subLayerOFFButton.width + 4;
			subLayerText.y = subLayerOFFButton.y;

			subLayerONButton.useHandCursor = false;
			subLayerOFFButton.useHandCursor = false;

			subLayerButtonWrapper.name = "subLayerButtonWrapper";
		}

		public function initPixelSnapButtonWrapper():void
		{
			const g:Graphics = pixelSnapButtonWrapper.graphics;
			const w:Number = pixelSnapOFFButton.width + pixelSnapText.width + 4;
			const h:Number = pixelSnapOFFButton.height + 2;

			g.beginFill(0xFF0000, 0);
			g.drawRect(0, 0, w, h);
			g.endFill();

			pixelSnapButtonWrapper.addChild(pixelSnapOFFButton);
			pixelSnapButtonWrapper.addChild(pixelSnapONButton);
			pixelSnapButtonWrapper.addChild(pixelSnapText);

			pixelSnapONButton.x = 0;
			pixelSnapONButton.y = 0;
			pixelSnapOFFButton.x = pixelSnapONButton.x;
			pixelSnapOFFButton.y = pixelSnapONButton.y;
			pixelSnapOFFButton.visible = false;

			pixelSnapText.x = pixelSnapOFFButton.x + pixelSnapOFFButton.width + 2;
			pixelSnapText.y = pixelSnapOFFButton.y;

			pixelSnapOFFButton.useHandCursor = false;
			pixelSnapONButton.useHandCursor = false;
			pixelSnapButtonWrapper.name = "pixelSnapButtonWrapper";
		}

		public function initPenSizeButton():void
		{
			const _penSizeTransButtonBox:penSizeTransButtonSet = penSizeTransButtonBox;
			var btn:SimpleButton;
			for (var i:int = 1; i <= 12; i++)
			{
				btn = _penSizeTransButtonBox.getChildByName("nSizeButton" + i) as SimpleButton;
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
			const infoBottom:Number = floor(controlInfo.y + controlInfo.height + 7);

			controlInfo.width = BOX_WIDTH - 5;
			controlInfo.x = -3;
			controlInfo.y = 0;

			shapeCircle.x = offsetX;
			shapeCircle.y = infoBottom;
			shapeCircle.useHandCursor = false;
			shapeRect.x = offsetX + shapeCircle.x + shapeCircle.width + 5;
			shapeRect.y = infoBottom;
			shapeRect.useHandCursor = false;

			penSmoothSliderSet.x = floor(shapeRect.x + shapeRect.width + 11);
			penSmoothSliderSet.y = floor(shapeRect.y) + 5;

			penSmoothSliderSet["penSmoothBar"].useHandCursor = false;
			penSmoothSliderSet["penSmoothButton"].useHandCursor = false;
			penSmoothSliderSet["penSmoothSlider"].useHandCursor = false;

			// const smoothSlider:SimpleButton = penSmoothSliderSet.getChildByName("penSmoothSlider") as SimpleButton;
			// if(smoothSlider)
			// {
			// smoothSlider.useHandCursor = false;
			// }

			penSizeGrid.x = offsetX;
			penSizeGrid.y = floor(penSmoothSliderSet.y + penSmoothSliderSet.height) - 5;
			penSizeTransButtonBox.x = penSizeGrid.x + 2;
			penSizeTransButtonBox.y = penSizeGrid.y + 2;
			// penSizeTransButtonBox.addChild(sizeSelectCursor);
			sizeSelectCursor.useHandCursor = false;

			rectSizeSet.x = floor(penSizeGrid.x) + 9;
			rectSizeSet.y = floor(penSizeGrid.y) + 10;
			circleSizeSet.x = rectSizeSet.x;
			circleSizeSet.y = rectSizeSet.y + 1;

			initPixelSnapButtonWrapper();
			initSubLayerButtonWrapper();
			initAirBrushButtonWrapper();

			pixelSnapText.useHandCursor = false;
			pixelSnapButtonWrapper.x = penSizeGrid.x;
			pixelSnapButtonWrapper.y = penSizeGrid.y + penSizeGrid.height + 8;

			airBrushText.useHandCursor = false;
			airBrushButtonWrapper.x = floor(pixelSnapButtonWrapper.x + pixelSnapButtonWrapper.width + 11);
			airBrushButtonWrapper.y = floor(penSizeGrid.y + penSizeGrid.height + 8);

			subLayerText.useHandCursor = false;
			subLayerButtonWrapper.x = airBrushButtonWrapper.x;
			subLayerButtonWrapper.y = airBrushButtonWrapper.y + airBrushButtonWrapper.height + 5;

			opaBox.x = offsetX;
			opaBox.y = floor(pixelSnapButtonWrapper.y + pixelSnapButtonWrapper.height + 2) + 2;

			BOX_HEIGHT = opaBox.y + opaBox.height + 7;

			addChild(penSizeGrid);
			addChild(opaBox);
			addChild(penSizeTransButtonBox);
			addChild(pixelSnapButtonWrapper);
			addChild(subLayerButtonWrapper);
			addChild(airBrushButtonWrapper);
			setChildIndex(controlInfo, this.numChildren - 1);
			setChildIndex(sizeSelectCursor, this.numChildren - 1);

			penSizeGrid.useHandCursor = false;
		}
	}
}


