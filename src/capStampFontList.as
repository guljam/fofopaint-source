package  {
	
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.text.Font;
	import flash.text.TextFormat;
	import flash.text.TextLineMetrics;
	import flash.geom.Rectangle;
	import flash.text.TextFieldType;
	import flash.display.Shape;
	import flash.geom.ColorTransform;
	import flash.events.MouseEvent;
	import flash.display.DisplayObject;
	import flash.text.engine.FontMetrics;
	import flash.display.DisplayObjectContainer;
	
	public class capStampFontList extends Sprite {
		
		public var capFontListPrev:SimpleButton;
		public var capFontListNext:SimpleButton;
		private const capFontListBG:Shape = new Shape();
		private const capFontListWapper:Sprite = new Sprite();
		private const fontList:Array = [];
		private const fontBoxWidth:Number = 200;
		private const fontBoxHeight:Number = 25;
		private const fontBoxRow:Number = 1
		private const fontBoxColumn:Number = 10;
		private const defaultFontSize:Number = fontBoxHeight-8;
		private const bgOffset:Number = 5;
		private const childTextFieldBoxName:String = "capStampFont";
		private var childTextFieldBoxMouseOverSave:Sprite = null;
		private var listViewIndex:int = 0;
		private var listViewIndexSave:int = -1;
		private const listViewCount:int = fontBoxRow*fontBoxColumn;
		private var listViewMaxCount:int = 0;
		private var fontColor:uint = 0;

		public function childTextFieldBoxHoverOFF(target:Sprite):void
		{
			target.graphics.clear();
		}

		public function childTextFieldBoxHoverON(target:Sprite):void
		{
			target.graphics.clear();
			target.graphics.lineStyle(0,0,0);
			target.graphics.beginFill(fontColor,0.2);
			target.graphics.drawRect(0,0,fontBoxWidth,fontBoxHeight);
		}

		public function getStampFontButtonName():String
		{
			return childTextFieldBoxName;
		}

		public function getFontName(targetName:String):String
		{
			const fontBox:Sprite = capFontListWapper.getChildByName(targetName) as Sprite;
			const childText:TextField = fontBox.getChildAt(0) as TextField;
			const textformat:TextFormat = childText.getTextFormat();

			return textformat.font;
		}

		private function makeFontListChildBox():void
		{
			const row:int = fontBoxRow;
			const column:int = fontBoxColumn;

			for(var i:int=0;i<row;i++)
			{
				for(var j:int=0;j<column;j++)
				{
					const childTextFieldBox:Sprite = new Sprite();
					childTextFieldBox.scrollRect = new Rectangle(0,0,fontBoxWidth,fontBoxHeight);
					childTextFieldBox.x = fontBoxWidth*i;
					childTextFieldBox.y = fontBoxHeight*j;
					childTextFieldBox.name = childTextFieldBoxName+j;

					const childTextField:TextField = new TextField();
					childTextField.border = false;
					// childTextField.borderColor = 0;
					childTextField.multiline = false;
					childTextField.wordWrap = false;
					childTextField.width = fontBoxWidth;
					childTextField.height = fontBoxHeight;
					childTextField.type = TextFieldType.DYNAMIC;
					childTextField.selectable = false;
					childTextField.mouseEnabled = false;
					// childTextField.autoSize = "left";

					childTextFieldBox.addChild(childTextField);
					capFontListWapper.addChild(childTextFieldBox);
				}
			}
		}

		public function updateNextFontList(nextFlag:Boolean):void
		{
			if(nextFlag)
			{
				listViewIndex++;
			}
			else
			{
				listViewIndex--;
			}

			if(listViewIndex > listViewMaxCount)
			{
				listViewIndex = 0;
			}
			else if(listViewIndex < 0)
			{
				listViewIndex = listViewMaxCount;
			}

			updateFontList(listViewIndex);
		}

		public function updateFontList(pageIndex:int):void
		{
			if(pageIndex === listViewIndexSave)
			{
				return;
			}

			listViewIndexSave = pageIndex;

			const len:int = listViewCount;

			for(var i:int=0;i<len;i++)
			{
				const textChildBox:Sprite = capFontListWapper.getChildAt(i) as Sprite;
				const textchild:TextField = textChildBox.getChildAt(0) as TextField;
				var textFormat:TextFormat = textchild.getTextFormat();
				if(!textFormat)
				{
					textFormat = new TextFormat();
				}

				const index:int = pageIndex*listViewCount+i;

				if(fontList[index])
				{
					textFormat.font = fontList[index];
					textFormat.color = fontColor;
					textchild.text = fontList[index];
					textFormat.size = defaultFontSize;
					textchild.setTextFormat(textFormat);

					var metrics:TextLineMetrics = textchild.getLineMetrics(0);
					textchild.y = (textchild.height-metrics.height)/2;
				}
				else
				{
					textchild.text = "";
				}
			}
		}

		public function updateSystemFontList():void
		{
			const rawFontList:Array = Font.enumerateFonts(true);
			const len:int = rawFontList.length;

			fontList.length = 0;

			for(var i:int=0;i<len;i++)
			{
				fontList.push(rawFontList[i].fontName);
			}

			listViewMaxCount = int(fontList.length/listViewCount);

			updateFontList(listViewIndex);
		}

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale;
			this.scaleY = newScale;
		}

		public function changeUIColor(base:uint,op:uint):void
		{
			capFontListBG.graphics.clear();
			capFontListBG.graphics.lineStyle(0,0,0);
			capFontListBG.graphics.beginFill(base);
			capFontListBG.graphics.drawRect(-bgOffset,0,this.width+bgOffset*2,this.height+bgOffset);
			capFontListBG.graphics.endFill();

			const opColor:ColorTransform = new ColorTransform();

			opColor.color = op;
			capFontListPrev.transform.colorTransform = opColor;
			capFontListNext.transform.colorTransform = opColor;

			fontColor = op;
		}

		public function mouseOverEvent(e:MouseEvent):void
		{
			const target:DisplayObject = e.target as DisplayObject;
			if(!target) return;

			const targetName:String = target.name;


			if(childTextFieldBoxMouseOverSave && childTextFieldBoxMouseOverSave !== target)
			{
				childTextFieldBoxHoverOFF(childTextFieldBoxMouseOverSave);	
				childTextFieldBoxMouseOverSave = null;
			}

			if(target === stage || target.parent === stage)
			{
				return;
			}

			if(targetName.indexOf(childTextFieldBoxName) !== -1
			|| (target.parent && target.parent.name.indexOf(childTextFieldBoxName) !== -1))
			{
				childTextFieldBoxMouseOverSave = target as Sprite;
				childTextFieldBoxHoverON(target as Sprite);
			}
		}

		public function capStampFontList() {
			visible = false;
			addChild(capFontListBG);
			setChildIndex(capFontListBG,0);
			makeFontListChildBox();

			capFontListPrev.useHandCursor = false;
			capFontListNext.useHandCursor = false;

			capFontListNext.x = 0
			capFontListPrev.y = 0
			capFontListNext.x = capFontListPrev.x+capFontListPrev.width;
			capFontListNext.y = capFontListPrev.y;
			capFontListWapper.x = 0;
			capFontListWapper.y = capFontListPrev.y+capFontListPrev.height;

			const listMoveBttons:Array = [capFontListPrev,capFontListNext];
			var btn:SimpleButton;
			var btnDown:DisplayObjectContainer;

			for(var i:uint=0;i<listMoveBttons.length;i++)
			{
				btn = listMoveBttons[i] as SimpleButton;
				btnDown = btn.downState as DisplayObjectContainer;
				btnDown.x = 2;
				btnDown.y = 2;
			}

			addChild(capFontListWapper);

			this.addEventListener(MouseEvent.MOUSE_OVER,mouseOverEvent)
			// visible = true;
		}
	}
}
