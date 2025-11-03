package
{
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.text.TextField;
	import flash.geom.Rectangle;

	public class CanvasNavigatorBoxSet extends Sprite
	{
		public var navCursor:Sprite = new Sprite();
		private var navInfoText:TextField;
		public var navStageBG:Sprite = new Sprite();
		public var navBitmapBG:Sprite = new Sprite();
		public var navLayer1Bitmap:Bitmap = new Bitmap();
		public var navLayer2Bitmap:Bitmap = new Bitmap();
		public var navBitmapLastWidth:Number = 0;
		public var navBitmapLastHeight:Number = 0;
		public const BOX_WIDTH:Number = 213;
		public const BOX_HEIGHT:Number = 173;
		// public const maskShape:Sprite = new Sprite();
		private const navCursorOffsetX:Number = 0;
		private const navCursorOffsetY:Number = 0;
		public var navCursorMultiply:Number = 0;

		private const stageColor:ColorTransform = new ColorTransform();
		private const prevBMPBGColor:ColorTransform = new ColorTransform();

		// public function setMask():void
		// {
		// maskShape.graphics.clear();
		// maskShape.graphics.lineStyle(0,0,0);
		// maskShape.graphics.beginFill(0xFF0000);
		// maskShape.graphics.drawRect(0,0,BOX_WIDTH,BOX_HEIGHT);
		// maskShape.graphics.endFill();
		// mask = maskShape;
		// }

		// x, y canvas1bitmap을 기준으로 창 왼쪽 오른쪽 점의 좌표임, 회전을 하면 캔버스를 회전한 기준으로 잡힘
		// w, h 캔버스 전체 영역가로 세로 길이 (캔버스 자체 길이가 아님 빈공백칸을 말하는거)
		// canvasWidth 줌배율을 적용한 캔버스 크기
		public function updateCursor(x:Number, y:Number, w:Number, h:Number, canvasWidth:Number, rotation:Number):void
		{
			const f1:Number = navLayer1Bitmap.width / canvasWidth;
			// const f2:Number = _prevBitmap.height/canvasHeight;
			var cursorWidth:Number = Math.floor(w * f1);
			var cursorHeight:Number = Math.floor(h * f1);

			navCursorMultiply = f1;

			navCursor.graphics.clear();
			navCursor.graphics.lineStyle(2, 0xFF6600);
			navCursor.graphics.beginFill(0xFF0000, 0);
			navCursor.graphics.drawRect(0, 0, cursorWidth, cursorHeight) // 썸네일 비트맵/실제 캔버스 길이 배율을 곱해주면 캔버스 부분이 작게 축소됨
				navCursor.graphics.endFill();

			navCursor.rotation = -rotation;
			// 캔버스 원점 위치 음수값으로 넣어주고 당연 배율 적용하고,
			// 중앙정렬해준 x y 값이 있으니깐오프셋으로 더해줌
			navCursor.x = Math.floor(x * f1 + navLayer1Bitmap.x);
			navCursor.y = Math.floor(y * f1 + navLayer1Bitmap.y);
		}

		public function setFitBitmapforBox(w:Number, h:Number, bw:Number, bh:Number):Rectangle
		{
			var ratio:Number = bw / w;
			var fw:Number = w * ratio;
			var fh:Number = h * ratio;
			var alignWidthFlag:Boolean = true;

			if (fh > bh)
			{
				alignWidthFlag = false;
				ratio = bh / fh;
				fw = fw * ratio;
				fh = fh * ratio;
			}

			if (alignWidthFlag)
			{
				return new Rectangle(0, Math.round(bh / 2 - fh / 2), Math.round(fw), Math.round(fh));
			}

			return new Rectangle(Math.round(bw / 2 - fw / 2), 0, Math.round(fw), Math.round(fh));
		}

		public function updateImage(bmpd:BitmapData, bmpd1:BitmapData, bg:uint):void
		{
			const w:Number = bmpd.width;
			const h:Number = bmpd.height;

			navLayer1Bitmap.bitmapData = bmpd;
			navLayer1Bitmap.smoothing = true;
			navLayer2Bitmap.bitmapData = bmpd1;
			navLayer2Bitmap.smoothing = true;

			if (navBitmapLastWidth === w && navBitmapLastHeight === h)
			{
				return;
			}

			navBitmapLastWidth = w;
			navBitmapLastHeight = h;

			const bounds:Rectangle = setFitBitmapforBox(navLayer1Bitmap.width, navLayer1Bitmap.height, BOX_WIDTH, BOX_HEIGHT);
			navLayer1Bitmap.x = bounds.x;
			navLayer1Bitmap.y = bounds.y;
			navLayer1Bitmap.width = bounds.width;
			navLayer1Bitmap.height = bounds.height;
			navLayer2Bitmap.x = bounds.x;
			navLayer2Bitmap.y = bounds.y;
			navLayer2Bitmap.width = bounds.width;
			navLayer2Bitmap.height = bounds.height;

			navBitmapBG.width = navLayer1Bitmap.width;
			navBitmapBG.height = navLayer1Bitmap.height;
			navBitmapBG.x = navLayer1Bitmap.x;
			navBitmapBG.y = navLayer1Bitmap.y;
			changeprevBitmapBGColor(bg);
		}

		public function changeprevBitmapBGColor(color:uint):void
		{
			prevBMPBGColor.color = color;
			navBitmapBG.transform.colorTransform = prevBMPBGColor;
		}

		public function chanegStageColor(consoleBGColor:uint):void
		{
			stageColor.color = consoleBGColor;
			navStageBG.transform.colorTransform = stageColor;
		}

		public function CanvasNavigatorBoxSet()
		{
			name = "canvasNavigatorBox";
			navStageBG.graphics.lineStyle(0, 0, 0);
			navStageBG.graphics.beginFill(0xFFFFFF);
			navStageBG.graphics.drawRect(0, 0, BOX_WIDTH, BOX_HEIGHT);

			navBitmapBG.graphics.lineStyle(0, 0, 0);
			navBitmapBG.graphics.beginFill(0xFFFFFF);
			navBitmapBG.graphics.drawRect(0, 0, 100, 100);

			navStageBG.name = "navStageBG";
			navBitmapBG.name = "navBitmapBG";
			navLayer1Bitmap.name = "navLayer1Bitmap";
			navLayer2Bitmap.name = "navLayer2Bitmap";
			navCursor.name = "navCursor";

			addChild(navStageBG);
			addChild(navBitmapBG);
			addChild(navLayer2Bitmap);
			addChild(navLayer1Bitmap);
			addChild(navCursor);
			mouseEnabled = false;
		}
	}

}
