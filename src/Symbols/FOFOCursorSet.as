package Symbols
{
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.geom.Rectangle;

	public class FOFOCursorSet extends Sprite
	{
		private var fofoCursor:SimpleButton;
		// 그림 중심을 축으로 도는 레이어, 바깥(this)의 위치/회전/크기는 펜 위치, 캔버스 회전 상쇄, 줌 보정에 쓰이므로 건드리지 않음
		private var spinLayer:Sprite = new Sprite();
		// 그림 중심 기준 회전 각도 (화면 기준, 캔버스 회전과 상관없음)
		public function get spinRotation():Number
		{
			return spinLayer.rotation;
		}

		public function set spinRotation(angle:Number):void
		{
			spinLayer.rotation = angle;
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
			// 등록점(0,0)이 그림 왼쪽 아래라서 그림 중심으로 회전축을 옮김, 회전이 0이면 지금과 똑같이 보임
			const bounds:Rectangle = fofoCursor.getBounds(fofoCursor);
			const centerX:Number = bounds.x + bounds.width / 2;
			const centerY:Number = bounds.y + bounds.height / 2;
			spinLayer.x = centerX;
			spinLayer.y = centerY;
			fofoCursor.x = -centerX;
			fofoCursor.y = -centerY;
			spinLayer.addChild(fofoCursor);
			spinLayer.mouseEnabled = false;
			spinLayer.mouseChildren = false;
			this.addChild(spinLayer);
			visible = false;
			fofoCursor.mouseEnabled = false;
			fofoCursor.useHandCursor = false;
			this.mouseEnabled = false;
			this.useHandCursor = false;
		}
	}
}
