package Symbols
{
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import Modules.Utils;
	import flash.text.TextField;
	import flash.display.SimpleButton;
	import flash.text.TextFieldAutoSize;
	import assets.VisualBuilder;
	import assets.VisualFieldCollector;

	public class AboutWindowSet extends Sprite
	{
		public var versionInfo:TextField;
		public var memoryInfo:TextField;
		public var resetAppButton:SimpleButton;
		public var releaseNoteButton:SimpleButton;
		public var aboutMeLink:SimpleButton;
		public var aboutHomePageLink:SimpleButton;
		public var aboutManualFolder:SimpleButton;
		public var logo1:SimpleButton;
		public var logo2:SimpleButton;
		public var logo3:SimpleButton;
		public var logo4:SimpleButton;
		public var logo5:SimpleButton;
		private static const LINK_UP_COLOR:uint = 0x303BE2;
		private static const LINK_OVER_COLOR:uint = 0x3A72E0;
		private var imageIndex:int = 0;

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale;
			this.scaleY = newScale;
		}

		public function randomLogo():void
		{
			const arr:Array = [logo1, logo2, logo3, logo4, logo5];
			var index:int = imageIndex + 1;

			if (index === arr.length)
			{
				index = 0;
			}

			arr[imageIndex].visible = false;
			arr[index].visible = true;

			imageIndex = index;
		}

		public function setVersionInfo(str:String):void
		{
			versionInfo.text = "Version " + str;
		}

		[Embed(source="fofoPaint-animate-27.13.swf",symbol="AboutWindowSet")]
		private static const EmbeddedClass:Class;

		public function AboutWindowSet()
		{
			const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
			VisualBuilder.buildInto(this, EmbeddedClass, fields);
			// constructor codef
			imageIndex = Math.floor(Math.random() * 4);
			visible = false;

			logo2.visible = false;
			logo3.visible = false;
			logo4.visible = false;
			logo5.visible = false;

			logo1.mouseEnabled = false;
			logo2.mouseEnabled = false;
			logo3.mouseEnabled = false;
			logo4.mouseEnabled = false;
			logo5.mouseEnabled = false;

			aboutMeLink.mouseEnabled = false;

			memoryInfo.autoSize = TextFieldAutoSize.RIGHT;
			memoryInfo.text = "Adobe AIR SDK " + Main.ADOBE_AIR_SDK_VERSION;

			redesignWindow();
		}

		// 어바웃 창 재디자인: 테두리 확장, Manual 줄 / 링크 줄 재배치, Reset 버튼 교체, 하단 글자 정리
		private function redesignWindow():void
		{
			const centerX:Number = 216;

			addFrame(10);
			centerAboutMe(centerX);
			removeLegacyManualRow();
			layoutLinkRow(centerX, 344);
			redesignResetButton();

			setButtonText(releaseNoteButton, "(Release note)");

			// 글자가 길어져 패널 오른쪽 여백을 넘으면 왼쪽으로 당김
			const overflow:Number = releaseNoteButton.getBounds(this).right - 430;
			if (overflow > 0)
			{
				releaseNoteButton.x -= overflow;
				versionInfo.x -= overflow; // 두 글자 사이 간격 유지				
			}
		}

		private function centerAboutMe(centerX:Number):void
		{
			alignTextCenter(aboutMeLink.upState);
			alignTextCenter(aboutMeLink.overState);
			alignTextCenter(aboutMeLink.downState);
			const b:Rectangle = aboutMeLink.getBounds(this);
			aboutMeLink.x += centerX - (b.x + b.width / 2);
			aboutMeLink.y += 3;
		}

		// 기존 패널 바깥으로 여백을 넓혀 둥근 회색 테두리를 깔아줌
		private function addFrame(margin:Number):void
		{
			// 기존 배경(검은 테두리 포함)은 새 테두리가 대신하므로 숨김
			const oldBg:DisplayObject = getChildAt(0);
			const bg:Rectangle = oldBg.getBounds(this);
			oldBg.visible = false;
			const frame:Shape = new Shape();
			frame.graphics.lineStyle(3, 0x8C8C8C, 1, true);
			frame.graphics.beginFill(0xFFFFFF);
			frame.graphics.drawRoundRect(bg.x - margin, bg.y - margin, bg.width + margin * 2, bg.height + margin * 2, 16, 16);
			frame.graphics.endFill();
			addChildAt(frame, 0);
		}

		// Github page | Manual | Open error log
		private function layoutLinkRow(centerX:Number, centerY:Number):void
		{
			// describeType에 잡히지 않도록 public 변수로 선언하지 않음
			const errorLogButton:SimpleButton = Utils.cloneSimpleButton(aboutManualFolder);
			errorLogButton.name = "aboutErrorLogFolder";
			addChild(errorLogButton);

			// 원본 스케일(가로로 눌려있음)을 풀어 다른 링크와 같은 크기로
			aboutManualFolder.scaleX = aboutManualFolder.scaleY = 1;
			errorLogButton.scaleX = errorLogButton.scaleY = 1;

			// 상태 안쪽이 StaticText(읽기 전용)라서 TextField로 갈아끼움
			setButtonLabel(aboutManualFolder, "Manual");
			setButtonLabel(errorLogButton, "Open error log");

			const separator1:Shape = createSeparator(this, 15);
			const separator2:Shape = createSeparator(this, 15);

			const items:Array = [aboutHomePageLink, separator1, aboutManualFolder, separator2, errorLogButton];
			const gap:Number = 14;
			placeRow(this, items, gap, centerX - measureRow(this, items, gap) / 2, centerY);
		}

		private function measureRow(container:DisplayObjectContainer, items:Array, gap:Number):Number
		{
			var total:Number = gap * (items.length - 1);
			for each (var item:DisplayObject in items)
			{
				total += item.getBounds(container).width;
			}
			return total;
		}

		// items를 gap 간격으로 가로로 이어 붙이고 세로 중심을 centerY에 맞춤 (centerY가 0이면 세로는 그대로)
		private function placeRow(container:DisplayObjectContainer, items:Array, gap:Number, startX:Number, centerY:Number):void
		{
			var cursor:Number = startX;
			for each (var item:DisplayObject in items)
			{
				const b:Rectangle = item.getBounds(container);
				item.x += cursor - b.x;
				if (centerY !== 0)
				{
					item.y += centerY - (b.y + b.height / 2);
				}
				cursor += b.width + gap;
			}
		}

		// 세로 구분선
		private function createSeparator(container:DisplayObjectContainer, height:Number):Shape
		{
			const s:Shape = new Shape();
			s.graphics.lineStyle(1, 0x9A9A9A);
			s.graphics.moveTo(0.5, 0);
			s.graphics.lineTo(0.5, height);
			container.addChild(s);
			return s;
		}

		// 붉은 테두리 + 옅은 붉은 배경의 둥근 Reset 버튼으로 교체
		private function redesignResetButton():void
		{
			const up:Sprite = createResetState(0xFDECEC);
			const over:Sprite = createResetState(0xF9D6D6);

			resetAppButton.upState = up;
			resetAppButton.overState = over;
			resetAppButton.downState = over;

			const hit:Sprite = new Sprite();
			hit.graphics.beginFill(0x000000);
			hit.graphics.drawRect(0, 0, up.width, up.height);
			hit.graphics.endFill();
			resetAppButton.hitTestState = hit;

			resetAppButton.x = 0;
			resetAppButton.y = 385;
		}

		private function createResetState(fillColor:uint):Sprite
		{
			const padX:Number = 20;
			const field:TextField = createLabelField("Reset app", 0xFF0000, 15);
			const w:Number = Math.ceil(field.width) + padX * 2;
			const h:Number = Math.ceil(field.height) + 10;

			const state:Sprite = new Sprite();
			state.graphics.lineStyle(2, 0xEF8C8C, 1, true);
			state.graphics.beginFill(fillColor);
			state.graphics.drawRoundRect(0, 0, w, h, 10, 10);
			state.graphics.endFill();

			field.x = padX;
			field.y = Math.round((h - field.height) / 2);
			state.addChild(field);
			return state;
		}

		// 버튼 상태 안의 TextField 글자를 바꿈 (TextField로 이뤄진 버튼 전용)
		private function setButtonText(button:SimpleButton, label:String):void
		{
			const states:Array = [button.upState, button.overState, button.downState, button.hitTestState];
			for each (var state:DisplayObject in states)
			{
				setTextInTree(state, label);
			}
		}

		private function alignTextCenter(target:DisplayObject):void
		{
			const field:TextField = target as TextField;
			if (field !== null)
			{
				const format:TextFormat = field.defaultTextFormat;
				format.align = TextFormatAlign.CENTER;
				field.defaultTextFormat = format;
				field.setTextFormat(format);
				return;
			}

			const container:DisplayObjectContainer = target as DisplayObjectContainer;
			if (container === null)
			{
				return;
			}

			for (var i:int = 0; i < container.numChildren; i++)
			{
				alignTextCenter(container.getChildAt(i));
			}
		}

		private function setTextInTree(target:DisplayObject, label:String):void
		{
			const field:TextField = target as TextField;
			if (field !== null)
			{
				field.wordWrap = false;
				field.text = label;
				return;
			}

			const container:DisplayObjectContainer = target as DisplayObjectContainer;
			if (container === null)
			{
				return;
			}

			for (var i:int = 0; i < container.numChildren; i++)
			{
				setTextInTree(container.getChildAt(i), label);
			}
		}

		// 언어별 메뉴얼 링크(kor/jp/eng)가 든 swf의 Manual 줄은 manual.html 하나로 통합되어 통째로 제거
		private function removeLegacyManualRow():void
		{
			for (var i:int = numChildren - 1; i >= 0; i--)
			{
				const child:DisplayObjectContainer = getChildAt(i) as DisplayObjectContainer;
				if (child !== null && child.getChildByName("kor") !== null)
				{
					removeChildAt(i);
				}
			}
		}

		private function createLabelField(label:String, color:uint, size:Number):TextField
		{
			const field:TextField = new TextField();
			field.embedFonts = true;
			field.selectable = false;
			field.mouseEnabled = false;
			field.autoSize = TextFieldAutoSize.LEFT;
			field.defaultTextFormat = new TextFormat("Si Kancil", size, color);
			field.text = label;
			return field;
		}

		private function setButtonLabel(button:SimpleButton, label:String):void
		{
			// 원래 글자의 위치를 이어받음 (복제 버튼은 상태가 Bitmap이라 같은 좌표를 가짐)
			const baseX:Number = button.upState.x;
			const baseY:Number = button.upState.y;

			// 마우스를 올리면 다른 링크 버튼(Korean 등)과 같은 색(#3A72E0)으로 바뀜
			button.upState = createLabelState(label, baseX, baseY, LINK_UP_COLOR);
			button.overState = createLabelState(label, baseX, baseY, LINK_OVER_COLOR);
			button.downState = createLabelState(label, baseX, baseY, LINK_OVER_COLOR);

			const field:TextField = Sprite(button.upState).getChildAt(0) as TextField;
			const hit:Sprite = new Sprite();
			hit.graphics.beginFill(0x000000);
			hit.graphics.drawRect(field.x, field.y, field.width, field.height);
			hit.graphics.endFill();
			hit.x = baseX;
			hit.y = baseY;
			button.hitTestState = hit;
		}

		private function createLabelState(label:String, baseX:Number, baseY:Number, color:uint):Sprite
		{
			const field:TextField = createLabelField(label, color, 16);
			field.x = -1;
			field.y = -3;

			const state:Sprite = new Sprite();
			state.x = baseX;
			state.y = baseY;
			state.addChild(field);
			return state;
		}
	}
}
