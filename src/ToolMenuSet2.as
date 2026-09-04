package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.events.Event;
	import flash.utils.getTimer;
	import flash.display.Shape;
	import assets.VisualFieldCollector;
	import assets.VisualBuilder;

	public class ToolMenuSet2 extends Sprite
	{
		public var toolPen:SimpleButton;
		public var toolFillPen:SimpleButton;
		public var toolEraser:SimpleButton;
		public var toolUndo:SimpleButton;
		public var toolRedo:SimpleButton;
		public var toolEyedropper:SimpleButton;
		public var toolMirror:SimpleButton;
		public var toolLasso:SimpleButton;
		public var toolMove:SimpleButton;
		public var toolRotate2:SimpleButton;
		public var toolLine:SimpleButton;
		public var toolRefLayer:SimpleButton;
		public var toolZoom:SimpleButton;
		public var toolBoxBG:SimpleButton;
		public var toolBoxBG2:SimpleButton;
		public var toolQuickSidebar:SimpleButton;
		public var toolInfoText:TextField;
		private var constScale:Number = 1.0;
		private var infoDataBackup:Array = [];
		private const resizeButtonWaitTimeBar:Shape = new Shape();
		private var resizeButtonWaitTimeBarColor:uint = 0xFf0000;
		private var WIDTH:Number = 0.0;
		private var lastUsedToolPoint:Point = new Point(0, 0);
		private var onMouseOverTarget:DisplayObject;

		public function getMouseOverTarget():DisplayObject
		{
			return onMouseOverTarget;
		}

		public function setMouseOverTarget(target:DisplayObject):void
		{
			onMouseOverTarget = target;
		}
	
		public function getLastUsedToolPos():Point
		{
			return lastUsedToolPoint;
		}

		public function updateLastUsedToolPos(targetName:String):void
		{
			const btn:SimpleButton = this[targetName] as SimpleButton;
			lastUsedToolPoint.setTo((btn.x + btn.width / 2) * constScale, (btn.y + btn.height / 2) * constScale);
		}

		public function hint(str:String):void
		{
			if (str.indexOf("\n") !== -1)
			{
				if (infoDataBackup.length === 0)
				{
					infoDataBackup[0] = toolInfoText.y;
					infoDataBackup[1] = toolInfoText.height;
					infoDataBackup[2] = toolBoxBG.y;
					infoDataBackup[3] = toolBoxBG.height;

					toolInfoText.y -= 20;
					toolInfoText.height += 20;
					toolBoxBG.y -= 20;
					toolBoxBG.height += 20;
				}
			}
			else if (infoDataBackup.length !== 0)
			{
				toolInfoText.y = infoDataBackup[0];
				toolInfoText.height = infoDataBackup[1];
				toolBoxBG.y = infoDataBackup[2];
				toolBoxBG.height = 60;
				infoDataBackup.length = 0;
			}

			toolInfoText.text = str;
		}

		public function setToolButtonsForCheckedLayerON():void
		{
			const offAlpha:Number = Global.OFFALPHA;
			toolPen.alpha = offAlpha;
			toolEraser.alpha = offAlpha;
			toolFillPen.alpha = offAlpha;
			toolEyedropper.alpha = offAlpha;
			toolLine.alpha = offAlpha;
		}

		public function setToolButtonsForCheckedLayerOFF():void
		{
			toolPen.alpha = 1.0;
			toolEraser.alpha = 1.0;
			toolFillPen.alpha = 1.0;
			toolEyedropper.alpha = 1.0;
			toolLine.alpha = 1.0;
		}

		public function changeUIColor():void
		{
			var btn:SimpleButton;
			var btnUp:DisplayObject;
			var btnOver:DisplayObjectContainer;

			const leftButtonArr:Array = [
					toolZoom,
					toolMove,
					toolRotate2,
					toolRefLayer,
				];

			const rightButtonArr:Array = [
					toolPen,
					toolFillPen,
					toolEraser,
					toolUndo,
					toolRedo,
					toolEyedropper,
					toolMirror,
					toolLasso,
					toolLine,
					toolQuickSidebar
				];

			Global.applyToolBoxBGColor(toolBoxBG);
			Global.applyToolBoxBGTopColor(toolBoxBG2);

			var i:uint = 0;

			for (i = 0; i < leftButtonArr.length; i++)
			{
				btn = leftButtonArr[i];
				btnUp = btn.upState as DisplayObject;

				Global.applyToolBoxButtonUpBGColor(btnUp);
				Global.setButtonColorWithBG(btn.overState as DisplayObjectContainer,4,5);
				btn.downState = btn.overState;
			}

			for (i = 0; i < rightButtonArr.length; i++)
			{
				btn = rightButtonArr[i];
				btnUp = btn.upState as DisplayObject;
				btnOver = btn.overState as DisplayObjectContainer;

				Global.applyToolBoxButtonUpFGColor(btnUp);
				Global.setButtonColorWithBG(btn.overState as DisplayObjectContainer,4,3);
				btn.downState = btn.overState;
			}
			// 텍스트
			toolInfoText.textColor = Global.getToolBoxButtonUpBGColor()
			resizeButtonWaitTimeBarColor = Global.getToolBoxButtonOverBGColor();

			btn = null;
			btnUp = null;
			btnOver = null;
		}

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale * constScale;
			this.scaleY = newScale * constScale;
		}

		public function startResizeButtonWaitBarAnimation(duration:Number):void
		{
			var totalWidth:Number = WIDTH;
			var color:uint = resizeButtonWaitTimeBarColor;
			var elapsed:Number = 0;
			var startTime:int = getTimer();
			var toolbox2:DisplayObjectContainer = this;

			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);

			function onEnterFrame(e:Event):void
			{
				elapsed = (getTimer() - startTime) / 1000; // 초 단위 경과 시간
				var progress:Number = Math.min(elapsed / duration, 1); // 0~1 사이 비율

				var currentWidth:Number = totalWidth * progress;

				resizeButtonWaitTimeBar.graphics.clear();
				resizeButtonWaitTimeBar.graphics.lineStyle(4, color, 1.0, false, "normal", "none");
				resizeButtonWaitTimeBar.graphics.moveTo(0, 0);
				resizeButtonWaitTimeBar.graphics.lineTo(currentWidth, 0);

				if (progress >= 1 || toolbox2.visible === false)
				{
					removeEventListener(Event.ENTER_FRAME, onEnterFrame);
				}
			}
		}
		[Embed(
            source="../raw_resource/source/fofoPaint-animate-27.13.swf",
            symbol="ToolMenuSet2"
        )]
        private static const EmbeddedClass:Class;
		public function ToolMenuSet2()
		{
			const fields:Array = VisualFieldCollector.collectNullVisualFields(this);
			VisualBuilder.buildInto(this,EmbeddedClass,fields);
			toolPen.useHandCursor = false;
			toolFillPen.useHandCursor = false;
			toolEraser.useHandCursor = false;
			toolUndo.useHandCursor = false;
			toolRedo.useHandCursor = false;
			toolEyedropper.useHandCursor = false;
			toolMirror.useHandCursor = false;
			toolLasso.useHandCursor = false;
			toolMove.useHandCursor = false;
			toolRotate2.useHandCursor = false;
			toolLine.useHandCursor = false;
			toolRefLayer.useHandCursor = false;
			toolZoom.useHandCursor = false;
			toolQuickSidebar.useHandCursor = false;
			toolBoxBG2.mouseEnabled = false;
			toolBoxBG.mouseEnabled = false;

			toolPen.visible = false;
			toolEraser.visible = true;
			visible = false;

			updateLastUsedToolPos("toolPen");
			onMouseOverTarget = toolPen;

			constScale = 34 / toolPen.width;
			setScale(1.0);
			WIDTH = this.width / constScale;

			resizeButtonWaitTimeBar.y = 2;
			addChild(resizeButtonWaitTimeBar);
		}
	}

}
