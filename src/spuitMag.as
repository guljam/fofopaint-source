package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.geom.ColorTransform;
	import flash.utils.setTimeout;
	import flash.events.MouseEvent;
	import flash.utils.clearTimeout;
	import flash.geom.Transform;
	import flash.utils.getTimer;
	import flash.events.Event;
	import flash.display.BitmapData;

	public class spuitMag extends Sprite
	{
		private const deafultZoom:Number = 2.0;
		public const magSize:Number = 112;
		public const spuitZoomBitmapBox:Sprite = new Sprite();
		private const circleMask:Shape = new Shape();

		public var spuitNowColor:SimpleButton;
		public var spuitOldColor:SimpleButton;
		public var spuitZoomBitmap:Bitmap = new Bitmap(new BitmapData(magSize, magSize, true, 0));
		private var spuitOldColorTransform:ColorTransform = new ColorTransform();
		private var offTimer:int = 0;

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale;
			this.scaleY = newScale;
		}

		public function rotateBitmap(r:Number):void
		{
			spuitZoomBitmapBox.rotation = r;
		}

		// public function visibleONAnimation():void
		// {
		// 	if (visible)
		// 	{
		// 		return;
		// 	}
		// 	this.scaleX = 0;
		// 	this.scaleY = 0;
		// 	visible = true;

		// 	var startTime:Number = getTimer();
		// 	var duration:Number = 160; // 0.5 seconds

		// 	this.addEventListener(Event.ENTER_FRAME, function(event:Event):void
		// 		{
		// 			var target:spuitMag = event.currentTarget as spuitMag;
		// 			if (!target.visible)
		// 			{
		// 				target.scaleX = 1.0;
		// 				target.scaleY = 1.0;
		// 				target.removeEventListener(Event.ENTER_FRAME, arguments.callee);
		// 				return;
		// 			}
		// 			var elapsed:Number = getTimer() - startTime;
		// 			var progress:Number = elapsed / duration;

		// 			if (progress >= 1)
		// 			{
		// 				progress = 1;
		// 				target.scaleX = 1.0;
		// 				target.scaleY = 1.0;
		// 				target.removeEventListener(Event.ENTER_FRAME, arguments.callee);
		// 			}

		// 			var easeOutProgress:Number = 1 - Math.pow(1 - progress, 3); // Strong.easeOut equivalent
		// 			target.scaleX = easeOutProgress;
		// 			target.scaleY = easeOutProgress;
		// 		});
		// }

		private function pickedConfirmColorEffectMouseMoveEvent(event:MouseEvent):void
		{
			this.x = event.stageX;
			this.y = event.stageY;
		}

		public function spuitMag()
		{
			visible = false;

			const halfMagSize:Number = magSize / 2;

			circleMask.graphics.beginFill(0);
			circleMask.graphics.drawCircle(-1, 0, halfMagSize + 2);
			circleMask.graphics.endFill();

			circleMask.x = 0;
			circleMask.y = 0;
			const z1:Number = Math.round(-magSize / 2);
			spuitZoomBitmap.x = z1;
			spuitZoomBitmap.y = z1;
			spuitZoomBitmapBox.addChild(spuitZoomBitmap);
			spuitZoomBitmap.mask = circleMask;

			addChild(spuitZoomBitmapBox);
			addChild(circleMask);
			setChildIndex(spuitZoomBitmapBox, 0);
			cacheAsBitmap = true;
		}
	}
}
