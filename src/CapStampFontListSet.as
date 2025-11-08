package
{

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
	import flash.display.DisplayObjectContainer;

	public class CapStampFontListSet extends Sprite
	{
		public var capFontListPrev:SimpleButton;
		public var capFontListNext:SimpleButton;
		private const capFontListBG:Shape = new Shape();
		private const capFontListWapper:Sprite = new Sprite();
		private const fontList:Array = [];
		private const fontBoxWidth:Number = 200;
		private const fontBoxHeight:Number = 25;
		private const fontBoxRow:Number = 1;
		private const fontBoxColumn:Number = 10;
		private const defaultFontSize:Number = fontBoxHeight - 8;
		private const bgOffset:Number = 5;
		private const childTextFieldBoxName:String = "capStampFont";
		private var childTextFieldBoxMouseOverSave:Sprite = null;
		private var listViewIndex:int = 0;
		private var listViewIndexSave:int = -1;
		private const listViewCount:int = fontBoxRow * fontBoxColumn;
		private var listViewMaxCount:int = 0;
		private var fontColor:uint = 0;
		private var fontSelectedColor:uint = 0;
		private var selectedFont:String = "";

		public function setSelectFont(newFont:String):void
		{
			selectedFont = newFont;
		}

		public function setSelectFontBG(target:Sprite):void
		{
			target.graphics.clear();
			target.graphics.lineStyle(0, 0, 0);
			target.graphics.beginFill(fontSelectedColor);
			target.graphics.drawRect(0, 0, fontBoxWidth, fontBoxHeight);
		}

		public function childTextFieldBoxHoverOFF(target:Sprite):void
		{
			const textfield:TextField = target.getChildAt(0) as TextField;
			if (textfield && textfield.getTextFormat().font === selectedFont)
			{

			}
			else
			{
				target.graphics.clear();
			}
		}

		public function childTextFieldBoxHoverON(target:Sprite):void
		{
			const textfield:TextField = target.getChildAt(0) as TextField;
			if (textfield && textfield.getTextFormat().font === selectedFont)
			{

			}
			else
			{
				target.graphics.clear();
				target.graphics.lineStyle(0, 0, 0);
				target.graphics.beginFill(fontColor, 0.2);
				target.graphics.drawRect(0, 0, fontBoxWidth, fontBoxHeight);
			}
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

		private function initFontListCells():void
		{
			const row:int = fontBoxRow;
			const column:int = fontBoxColumn;

			for (var i:int = 0; i < row; i++)
			{
				for (var j:int = 0; j < column; j++)
				{
					const childTextFieldBox:Sprite = new Sprite();
					childTextFieldBox.scrollRect = new Rectangle(0, 0, fontBoxWidth, fontBoxHeight);
					childTextFieldBox.x = fontBoxWidth * i;
					childTextFieldBox.y = fontBoxHeight * j;
					childTextFieldBox.name = childTextFieldBoxName + j;

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
			if (nextFlag)
			{
				listViewIndex++;
			}
			else
			{
				listViewIndex--;
			}

			if (listViewIndex > listViewMaxCount)
			{
				listViewIndex = 0;
			}
			else if (listViewIndex < 0)
			{
				listViewIndex = listViewMaxCount;
			}

			updateFontList(listViewIndex, selectedFont);
		}

		public function updateFontListSelect(newFont:String):void
		{
			updateFontList(listViewIndex, newFont);
		}

		public function updateFontList(pageIndex:int, customSelectFont:String):void
		{
			if (pageIndex === listViewIndexSave && customSelectFont !== selectedFont)
			{
				return;
			}

			listViewIndexSave = pageIndex;
			selectedFont = customSelectFont;

			const len:int = listViewCount;

			for (var i:int = 0; i < len; i++)
			{
				const textChildBox:Sprite = capFontListWapper.getChildAt(i) as Sprite;
				const textchild:TextField = textChildBox.getChildAt(0) as TextField;
				var textFormat:TextFormat = textchild.getTextFormat();
				if (!textFormat)
				{
					textFormat = new TextFormat();
				}

				const index:int = pageIndex * listViewCount + i;

				if (fontList[index])
				{
					textFormat.font = fontList[index];
					textFormat.color = fontColor;
					textchild.text = fontList[index];
					textFormat.size = defaultFontSize;
					textchild.setTextFormat(textFormat);

					var metrics:TextLineMetrics = textchild.getLineMetrics(0);
					textchild.y = (textchild.height - metrics.height) / 2;

					if (fontList[index] === customSelectFont)
					{
						setSelectFontBG(textChildBox);
					}
					else
					{
						textChildBox.graphics.clear();
					}
				}
				else
				{
					textChildBox.graphics.clear();
					textchild.text = "";
				}
			}
		}

		public function updateSystemFontList():void
		{
			const rawFontList:Array = Font.enumerateFonts(true);
			const len:int = rawFontList.length;
			var selectedFontIndex:int = -1;

			fontList.length = 0;

			for (var i:int = 0; i < len; i++)
			{
				fontList.push(rawFontList[i].fontName);
				if (selectedFont === rawFontList[i].fontName)
				{
					selectedFontIndex = i;
				}
			}

			listViewMaxCount = int(fontList.length / listViewCount);

			// 선택된 폰트 페이지로 가기
			if (selectedFontIndex >= 0)
			{
				listViewIndex = int(selectedFontIndex / listViewCount);
			}

			updateFontList(listViewIndex, selectedFont);
		}

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale;
			this.scaleY = newScale;
		}

		public function updateUIColor():void
		{
			capFontListBG.graphics.clear();
			capFontListBG.graphics.lineStyle(0, 0, 0);
			capFontListBG.graphics.beginFill(Global.getUIBGColor());
			capFontListBG.graphics.drawRect(-bgOffset, 0, this.width + bgOffset * 2, this.height + bgOffset);
			capFontListBG.graphics.endFill();

			Global.applyUIFGColor(capFontListPrev);
			Global.applyUIFGColor(capFontListNext);

			fontColor = Global.getUIFGColor();
			fontSelectedColor = Global.getHintBGColor();
		}

		public function mouseOverEvent(e:MouseEvent):void
		{
			const target:DisplayObject = e.target as DisplayObject;
			if (!target)
			{
				return;
			}

			const targetName:String = target.name;

			if (childTextFieldBoxMouseOverSave && childTextFieldBoxMouseOverSave !== target)
			{
				childTextFieldBoxHoverOFF(childTextFieldBoxMouseOverSave);
				childTextFieldBoxMouseOverSave = null;
			}

			if (target === stage || target.parent === stage)
			{
				return;
			}

			if (targetName &&targetName.indexOf(childTextFieldBoxName) !== -1
					|| (target.parent && target.parent.name && target.parent.name.indexOf(childTextFieldBoxName) !== -1))
			{
				childTextFieldBoxMouseOverSave = target as Sprite;
				childTextFieldBoxHoverON(target as Sprite);
			}
		}

		public function CapStampFontListSet()
		{
			visible = false;
			addChild(capFontListBG);
			setChildIndex(capFontListBG, 0);
			initFontListCells();

			capFontListPrev.useHandCursor = false;
			capFontListNext.useHandCursor = false;

			capFontListNext.x = 0;
			capFontListPrev.y = 0;
			capFontListNext.x = capFontListPrev.x + capFontListPrev.width;
			capFontListNext.y = capFontListPrev.y;
			capFontListWapper.x = 0;
			capFontListWapper.y = capFontListPrev.y + capFontListPrev.height;

			const listMoveBttons:Array = [capFontListPrev, capFontListNext];
			var btn:SimpleButton;
			var btnDown:DisplayObjectContainer;

			for (var i:uint = 0; i < listMoveBttons.length; i++)
			{
				btn = listMoveBttons[i] as SimpleButton;
				btnDown = btn.downState as DisplayObjectContainer;
				btnDown.x = 2;
				btnDown.y = 2;
			}

			addChild(capFontListWapper);

			this.addEventListener(MouseEvent.MOUSE_OVER, mouseOverEvent);
			// visible = true;
		}
	}
}
