package
{
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.display.BitmapData;
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.text.TextField;
	import flash.geom.Rectangle;

	public class previewPanel extends Sprite {		
		public var prevCursor:Sprite = new Sprite();
		private var prevInfo:TextField;
		private var prevStageBG:Sprite = new Sprite();
		public var prevBitmapBG:Sprite = new Sprite();
		public var prevBitmap:Bitmap = new Bitmap();
		public var prevBitmapSub:Bitmap = new Bitmap();
		public var prevBitmapLastWidth:Number = 0;
		public var prevBitmapLastHeight:Number = 0;
		public const BOX_WIDTH:Number = 210;
		public const BOX_HEIGHT:Number = 170;
		private const maskShape:Sprite = new Sprite();
		private const prevCursorOffsetX:Number = 0;
		private const prevCursorOffsetY:Number = 0;
		public var prevCursorMultiply:Number = 0;

		private const stageColor:ColorTransform = new ColorTransform();
		private const prevBMPBGColor:ColorTransform = new ColorTransform();

		public function setMask():void
		{
			const g:Graphics = maskShape.graphics;
			g.clear();
			g.lineStyle(0,0,0);
			g.beginFill(0xFF0000);
			g.drawRect(0,0,BOX_WIDTH,BOX_HEIGHT);
			g.endFill();
			mask = maskShape;
		}

		//x, y canvas1bitmap을 기준으로 창 왼쪽 오른쪽 점의 좌표임, 회전을 하면 캔버스를 회전한 기준으로 잡힘
		//w, h 캔버스 전체 영역가로 세로 길이 (캔버스 자체 길이가 아님 빈공백칸을 말하는거)
		//canvasWidth 줌배율을 적용한 캔버스 크기
		public function updateCursor(x:Number,y:Number,w:Number,h:Number,canvasWidth:Number,rotation:Number):void
		{
			const floor:Function = Math.floor;
			const _prevBitmap:Bitmap = prevBitmap;
			const f1:Number = _prevBitmap.width/canvasWidth;
			// const f2:Number = _prevBitmap.height/canvasHeight;
			const g:Graphics = prevCursor.graphics;
			var cursorWidth:Number = floor(w*f1);
			var cursorHeight:Number = floor(h*f1);

			prevCursorMultiply = f1;

			g.clear();
			g.lineStyle(2,0xFF6600);
			g.beginFill(0xFF0000,0);
			g.drawRect(0,0,cursorWidth,cursorHeight)//썸네일 비트맵/실제 캔버스 길이 배율을 곱해주면 캔버스 부분이 작게 축소됨
			g.endFill();

			prevCursor.rotation = -rotation;
			//캔버스 원점 위치 음수값으로 넣어주고 당연 배율 적용하고,
			//중앙정렬해준 x y 값이 있으니깐오프셋으로 더해줌
			prevCursor.x = floor(x*f1+_prevBitmap.x);
			prevCursor.y = floor(y*f1+_prevBitmap.y);
		}

		public function setFitBitmapforBox(w:Number,h:Number,bw:Number,bh:Number):Rectangle
		{
			const round:Function = Math.round;
			var ratio:Number = bw/w;
			var fw:Number = w*ratio;
			var fh:Number = h*ratio;
			var alignWidthFlag:Boolean = true;

			if(fh > bh)
			{
				alignWidthFlag = false;
				ratio = bh/fh;
				fw = fw*ratio;
				fh = fh*ratio;
			}

			if(alignWidthFlag)
			{
				return new Rectangle(0,round(bh/2-fh/2),round(fw),round(fh));
			}

			return new Rectangle(round(bw/2-fw/2),0,round(fw),round(fh));
		}

		public function updateImage(bmpd:BitmapData,bmpd1:BitmapData,bg:uint):void
		{
			const _bitmap:Bitmap = prevBitmap;
			const _bitmapSub:Bitmap = prevBitmapSub;
			const w:Number = bmpd.width;
			const h:Number = bmpd.height;

			_bitmap.bitmapData = bmpd;
			_bitmap.smoothing = true;
			_bitmapSub.bitmapData = bmpd1;
			_bitmapSub.smoothing = true;

			if(prevBitmapLastWidth === w && prevBitmapLastHeight === h)
			{
				return;
			}

			prevBitmapLastWidth = w;
			prevBitmapLastHeight = h;

			const bounds:Rectangle = setFitBitmapforBox(_bitmap.width,_bitmap.height,BOX_WIDTH,BOX_HEIGHT);
			_bitmap.x = bounds.x;
			_bitmap.y = bounds.y;
			_bitmap.width = bounds.width;
			_bitmap.height = bounds.height;
			_bitmapSub.x = bounds.x;
			_bitmapSub.y = bounds.y;
			_bitmapSub.width = bounds.width;
			_bitmapSub.height = bounds.height;

			const _bitmapBG:Sprite = prevBitmapBG;
			_bitmapBG.width = _bitmap.width;
			_bitmapBG.height = _bitmap.height;
			_bitmapBG.x = _bitmap.x;
			_bitmapBG.y = _bitmap.y;
			changeprevBitmapBGColor(bg);
		}

		public function changeprevBitmapBGColor(color:uint):void
		{
			prevBMPBGColor.color = color;
			prevBitmapBG.transform.colorTransform = prevBMPBGColor;
		}

		public function chanegStageColor(consoleBGColor:uint):void
		{
			stageColor.color = consoleBGColor;
			prevStageBG.transform.colorTransform = stageColor;
		}

		public function previewPanel() {
			// constructor code
			name = "prevBox";
			var g:Graphics = prevStageBG.graphics;
			g.lineStyle(0,0,0);
			g.beginFill(0xFFFFFF);
			g.drawRect(0,0,BOX_WIDTH,BOX_HEIGHT);

			g = prevBitmapBG.graphics;
			g.lineStyle(0,0,0);
			g.beginFill(0xFFFFFF);
			g.drawRect(0,0,100,100);

			prevStageBG.name = "prevStageBG";
			prevBitmapBG.name = "prevBitmapBG"
			prevBitmap.name = "prevBitmap";
			prevCursor.name = "prevCursor";

			addChild(prevStageBG);
			addChild(prevBitmapBG);
			addChild(prevBitmapSub);
			addChild(prevBitmap);
			// addChild(consoleBG);
			addChild(prevCursor);
			addChild(maskShape);
			setMask();
		}
	}

}
