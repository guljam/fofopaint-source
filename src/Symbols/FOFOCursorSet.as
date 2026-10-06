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
		// 리플레이가 쉬는(AFK) 구간을 기다리는 동안 커서 위에 띄우는 검정 배경, 흰 테두리, 흰 글씨의 "afk" 상자. 회전 레이어 바깥이라 같이 돌지 않음
		private static const WAITING_BOX_GAP:Number = 3; // 상자와 몸통 회전 반경 사이 간격
		private static const WAITING_BOX_BORDER:Number = 2; // 흰색 테두리 두께
		private static const WAITING_BOX_RADIUS:Number = 4; // 모서리 둥글기 (반지름)
		private static const WAITING_BOX_PAD_X:Number = 3; // 테두리 안쪽 글자 여백
		private static const WAITING_BOX_PAD_Y:Number = 1;
		private var waitingBox:Sprite = new Sprite();
		private var waitBoxText:TextField = new TextField();
		private var isWaitingBoxInitialized:Boolean = false;

		// AFK 상자의 글꼴을 정함 (앱의 다른 글자와 같은 글꼴을 쓰도록 이미 쓰는 TextFormat을 받음). 처음 한번만 하면 됨
		public function initWaitingTextBox(format:TextFormat, embedFonts:Boolean):void
		{
			if (isWaitingBoxInitialized)
			{
				return;
			}
			// 상자 글꼴은 시크바 글자와 같은 것을 씀
			isWaitingBoxInitialized = true;
			waitBoxText.defaultTextFormat = format;
			waitBoxText.embedFonts = embedFonts;
			waitBoxText.selectable = false;
			waitBoxText.mouseEnabled = false;
			waitBoxText.autoSize = TextFieldAutoSize.LEFT;
			waitBoxText.textColor = 0xFFFFFF;
			waitBoxText.text = "waiting...";
			waitBoxText.x = WAITING_BOX_BORDER + WAITING_BOX_PAD_X;
			waitBoxText.y = WAITING_BOX_BORDER + WAITING_BOX_PAD_Y;
			// 검정 배경에 흰색 테두리, 모서리는 약간 둥글게. 테두리 선이 상자 바깥 크기 안에 들어오도록 반 두께만큼 안쪽으로 그림
			const boxW:Number = waitBoxText.width + (WAITING_BOX_BORDER + WAITING_BOX_PAD_X) * 2;
			const boxH:Number = waitBoxText.height + (WAITING_BOX_BORDER + WAITING_BOX_PAD_Y) * 2;
			waitingBox.graphics.clear();
			waitingBox.graphics.lineStyle(WAITING_BOX_BORDER, 0xFFFFFF, 1, true);
			waitingBox.graphics.beginFill(0x000000);
			waitingBox.graphics.drawRoundRect(WAITING_BOX_BORDER / 2, WAITING_BOX_BORDER / 2, boxW - WAITING_BOX_BORDER, boxH - WAITING_BOX_BORDER, WAITING_BOX_RADIUS * 2, WAITING_BOX_RADIUS * 2);
			waitingBox.graphics.endFill();
			waitingBox.x = -14;
			waitingBox.y = -fofoCursor.height+2;
			waitingBox.addChild(waitBoxText);
		}

		// 몸통이 연출로 닿는 범위 바깥, 커서 위쪽에 상자를 보임. 위쪽이 limit(target 좌표계의 보여지는 영역, 보통 캔버스)을 벗어나면 아래쪽에 보임
		// scaleFactor: 몸통이 커지는 최대 배율, extraUp: 위로 더 올라가는 최대 거리(점프)
		public function showAfkBox():void
		{
			if (!isWaitingBoxInitialized)
			{
				return;
			}

			fofoCursor.visible = true;
			waitingBox.visible = true;
		}

		public function hideAfkBox():void
		{
			waitingBox.visible = false;
			fofoCursor.visible = true;
		}

		// AFK 상자가 보이는지 (테스트 하네스 test-output 전용, 앱 코드 호출 없음)
		public function get isAfkBoxVisible():Boolean
		{
			return waitingBox.visible;
		}

		// 상자 영역을 target 좌표계로 돌려줌 (테스트 하네스 전용, 앱 코드 호출 없음)
		public function getAfkBoxBounds(target:DisplayObject):Rectangle
		{
			return waitingBox.getBounds(target);
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
			waitingBox.visible = false;
			waitingBox.mouseEnabled = false;
			waitingBox.mouseChildren = false;
			fofoCursor.mouseEnabled = false;
			fofoCursor.useHandCursor = false;
			this.visible = false;
			this.mouseEnabled = false;
			this.useHandCursor = false;
			this.addChild(fofoCursor);
			this.addChild(waitingBox);
		}
	}
}
