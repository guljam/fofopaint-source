package Symbols
{
	import flash.display.DisplayObject;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	public class FOFOCursorSet extends Sprite
	{
		private var fofoCursor:SimpleButton;
		// 몸통(그림 중심)을 축으로 도는 레이어, 바깥(this)의 위치/회전/크기는 펜 위치, 캔버스 회전 상쇄, 줌 보정에 쓰이므로 건드리지 않음
		private var spinLayer:Sprite = new Sprite();
		// 몸통 회전의 중심과 반경(중심에서 가장 먼 모서리까지), AFK 상자를 회전하는 몸통에 닿지 않는 자리에 놓는데 씀
		private var spinCenterX:Number = 0;
		private var spinCenterY:Number = 0;
		private var spinRadius:Number = 0;
		// 리플레이가 쉬는(AFK) 구간을 기다리는 동안 커서 위에 띄우는 검정 배경, 흰 테두리, 흰 글씨의 "afk" 상자. 회전 레이어 바깥이라 같이 돌지 않음
		private static const AFK_BOX_GAP:Number = 3;
		private var afkBox:Sprite = new Sprite();
		private var afkText:TextField = new TextField();
		private var isAfkBoxConfigured:Boolean = false;

		// 몸통 중심 기준 회전 각도 (화면 기준, 캔버스 회전과 상관없음)
		public function get spinRotation():Number
		{
			return spinLayer.rotation;
		}

		public function set spinRotation(angle:Number):void
		{
			spinLayer.rotation = angle;
		}

		// AFK 상자의 글꼴을 정함 (앱의 다른 글자와 같은 글꼴을 쓰도록 이미 쓰는 TextFormat을 받음). 처음 한번만 하면 됨
		public function configureAfkBox(format:TextFormat, embedFonts:Boolean):void
		{
			if (isAfkBoxConfigured)
			{
				return;
			}

			isAfkBoxConfigured = true;
			afkText.defaultTextFormat = format;
			afkText.embedFonts = embedFonts;
			afkText.selectable = false;
			afkText.mouseEnabled = false;
			afkText.autoSize = TextFieldAutoSize.LEFT;
			afkText.textColor = 0xFFFFFF;
			afkText.text = "afk";
			afkText.x = 3;
			afkText.y = 1;
			afkBox.graphics.clear();
			// 검정 배경에 흰색 1px 테두리 (선이 안쪽 가장자리에 걸리도록 반 픽셀 안으로 그림)
			afkBox.graphics.lineStyle(1, 0xFFFFFF, 1, true);
			afkBox.graphics.beginFill(0x000000);
			afkBox.graphics.drawRect(0.5, 0.5, afkText.width + 5, afkText.height + 1);
			afkBox.graphics.endFill();
			afkBox.addChild(afkText);
		}

		// 몸통 회전 반경 바깥, 커서 위쪽에 상자를 보임. 위쪽이 limit(target 좌표계의 보여지는 영역, 보통 캔버스)을 벗어나면 아래쪽에 보임
		public function showAfkBox(target:DisplayObject, limit:Rectangle):void
		{
			if (!isAfkBoxConfigured)
			{
				return;
			}

			const w:Number = afkBox.width;
			const h:Number = afkBox.height;
			afkBox.x = spinCenterX - w / 2;
			afkBox.y = spinCenterY - spinRadius - AFK_BOX_GAP - h;
			afkBox.visible = true;

			if (limit !== null && target !== null && !limit.containsRect(afkBox.getBounds(target)))
			{
				afkBox.y = spinCenterY + spinRadius + AFK_BOX_GAP;
			}
		}

		public function hideAfkBox():void
		{
			afkBox.visible = false;
		}

		public function get isAfkBoxVisible():Boolean
		{
			return afkBox.visible;
		}

		// 상자 영역을 target 좌표계로 돌려줌 (위치 확인용)
		public function getAfkBoxBounds(target:DisplayObject):Rectangle
		{
			return afkBox.getBounds(target);
		}

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale;
			this.scaleY = newScale;
		}

		[Embed(source="fofoPaint-animate-27.13.swf",symbol="FOFOCursor")]
		private static const EmbeddedClass:Class;

		public function FOFOCursorSet()
		{
			fofoCursor = new EmbeddedClass() as SimpleButton;
			// 등록점(0,0)이 그림 왼쪽 아래라서 그림 중심으로 회전축을 옮김, 회전이 0이면 이전과 똑같이 보임
			const bounds:Rectangle = fofoCursor.getBounds(fofoCursor);
			const centerX:Number = bounds.x + bounds.width / 2;
			const centerY:Number = bounds.y + bounds.height / 2;
			spinCenterX = centerX;
			spinCenterY = centerY;
			spinRadius = Math.sqrt(bounds.width * bounds.width + bounds.height * bounds.height) / 2;
			spinLayer.x = centerX;
			spinLayer.y = centerY;
			fofoCursor.x = -centerX;
			fofoCursor.y = -centerY;
			spinLayer.addChild(fofoCursor);
			spinLayer.mouseEnabled = false;
			spinLayer.mouseChildren = false;
			this.addChild(spinLayer);
			afkBox.visible = false;
			afkBox.mouseEnabled = false;
			afkBox.mouseChildren = false;
			this.addChild(afkBox);
			visible = false;
			fofoCursor.mouseEnabled = false;
			fofoCursor.useHandCursor = false;
			this.mouseEnabled = false;
			this.useHandCursor = false;
		}
	}
}
