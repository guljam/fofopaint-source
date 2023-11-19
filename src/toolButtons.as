package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.display.Graphics;
	import flash.events.MouseEvent;

	public class toolButtons extends Sprite {
		public var toolPen:SimpleButton;
		public var toolFillPen:SimpleButton;
		public var toolErase:SimpleButton;
		public var toolUndo:SimpleButton;
		public var toolRedo:SimpleButton;
		public var toolSpuit:SimpleButton;
		public var toolMirror:SimpleButton;
		public var toolLasso:SimpleButton;
		public var toolMove:SimpleButton;
		public var toolRotate:SimpleButton;
		public var toolLine:SimpleButton;
		public var toolTrace:SimpleButton;
		public var toolZoom:SimpleButton;
		public var zoomInButton:SimpleButton;
		public var zoomOutButton:SimpleButton;
		public var toolSelectCursor:SimpleButton;
		private var lastTool:String = "toolPen";

		public const BOX_WIDTH:Number = 34;
		public const BOX_HEIGHT:Number = 476;

		// public var toolBoxBG2:SimpleButton = toolBoxBG2;
		public var bgBox:Shape = new Shape();
		private var deafultY:Number = 0;

		private const base:ColorTransform = new ColorTransform();
		private const iconLeft:ColorTransform = new ColorTransform();
		private const activeColor:ColorTransform = new ColorTransform();
		private const activeIconColor:ColorTransform = new ColorTransform();
		private const defaultColor:ColorTransform = new ColorTransform();
		private var btn:SimpleButton;
		private var btnUp:DisplayObject;
		private var btnOver:DisplayObjectContainer;
		private var btnDown:DisplayObjectContainer;
		private var buttonArr:Array;

		public function setToolButtonsForCheckedLayerOFF():void
		{
			toolPen.alpha = 1.0;
			toolErase.alpha = 1.0;
			toolFillPen.alpha = 1.0;
			toolSpuit.alpha = 1.0;
			toolLine.alpha = 1.0;
			toolSelectCursor.alpha = 1.0;
		}

		public function setToolButtonsForCheckedLayerON(alp:Number):void
		{
			toolPen.alpha = alp;
			toolErase.alpha = alp;
			toolFillPen.alpha = alp;
			toolSpuit.alpha = alp;
			toolLine.alpha = alp;

			const btn:SimpleButton = getChildByName(lastTool) as SimpleButton;
			if(btn) toolSelectCursor.alpha = btn.alpha;
		}

		public function bgBoxVisible(flag:Boolean):void
		{
			if(flag)
			{
				addChild(bgBox);
				setChildIndex(bgBox,0);
			}
			else
			{
				removeChild(bgBox);
			}
		}

		public function updateBGBoxColor(color:uint):void
		{
			const g:Graphics = bgBox.graphics;
			g.lineStyle(0,0,0);
			g.beginFill(color);
			g.drawRect(-4,-1,BOX_WIDTH+8,BOX_HEIGHT+2);
			g.endFill();
		}

		public function setCursorVisible(flag:Boolean):void
		{
			toolSelectCursor.visible = flag;
		}

		public function getDeafultY():Number
		{
			return deafultY;
		}

		public function setDeafultY(y:Number):void
		{
			deafultY = y;
		}

		public function isZoomIconON():Boolean
		{
			return zoomInButton.visible;
		}

		private function zoomIconOFFEvent(e:MouseEvent):void
		{
            const targetName:String = e.target.name;

			if(!(targetName === "zoomInButton" || targetName === "zoomOutButton"))
			{
			    stage.removeEventListener(MouseEvent.MOUSE_MOVE,zoomIconOFFEvent);
				zoomIconOFF();
			}
		}

		public function checkBottomOFF():void
		{
			y = deafultY;
		}

		public function zoomIconON():void
		{
			toolZoom.visible = false;
			toolRotate.visible = false;
			zoomInButton.visible = true;
			zoomOutButton.visible = true;
			stage.addEventListener(MouseEvent.MOUSE_MOVE,zoomIconOFFEvent);
		}

		public function zoomIconOFF():void
		{
			toolZoom.visible = true;
			toolRotate.visible = true;
			zoomInButton.visible = false;
			zoomOutButton.visible = false;
		}

		public function changeUIColor(arr:Array):void
		{
           	base.color = arr[0];
           	// subBase.color = arr[1];
           	iconLeft.color = arr[2];
           	// iconRight.color = arr[3];
           	activeColor.color = arr[4];
			activeColor.alphaMultiplier = 0.0;
           	activeIconColor.color = arr[5];

			var len:uint = buttonArr.length;

			for(var i:uint=0;i<len;i++)
			{
				btn = buttonArr[i];
				btnUp = btn.upState as DisplayObject;
				btnUp.transform.colorTransform = iconLeft;
				btnOver = btn.overState as DisplayObjectContainer;
				btnOver.getChildAt(0).transform.colorTransform = activeColor;//버튼 배경
				btnOver.getChildAt(1).transform.colorTransform = iconLeft; //버튼 아이콘
				btnDown = btn.downState as DisplayObjectContainer;
				btnDown.getChildAt(0).transform.colorTransform = activeColor;//버튼 배경
				btnDown.getChildAt(1).transform.colorTransform = iconLeft; //버튼 아이콘
				btnDown.x = 2;
				btnDown.y = 2;
			}

			zoomInButton.x = toolZoom.x;
			zoomInButton.y = toolZoom.y;
			zoomOutButton.x = toolRotate.x;
			zoomOutButton.y = toolRotate.y;

			setChildIndex(zoomInButton,numChildren-1);
			setChildIndex(zoomOutButton,numChildren-1);

			const rotateButton:DisplayObjectContainer = toolRotate.downState as DisplayObjectContainer;
			rotateButton.x = 0;
			rotateButton.y = 0;

			//텍스트
			updateBGBoxColor(arr[0]);

			btn = null;
			btnUp = null;
			btnOver = null;
			btnDown = null;
		}

		public function getLastTool():String
		{
			return lastTool;
		}

		public function moveToolCursorInit():void
		{
			moveToolCursor(lastTool);
		}

		public function moveToolCursor(childName:String):void
		{
			const btn:SimpleButton = getChildByName(childName) as SimpleButton;

			if(!btn) return;

			toolSelectCursor.x = btn.x;
			toolSelectCursor.y = btn.y;
			lastTool = childName;

			toolSelectCursor.alpha = btn.alpha;
		}

		public function toolButtons() {

			moveToolCursorInit();

			zoomInButton.visible = false;
			zoomOutButton.visible = false;

			// initPenSizeCursor();

			toolSelectCursor.useHandCursor = false;
			toolSelectCursor.mouseEnabled = false;
			toolPen.useHandCursor = false;
			toolFillPen.useHandCursor = false;
			toolErase.useHandCursor = false;
			toolUndo.useHandCursor = false;
			toolRedo.useHandCursor = false;
			toolSpuit.useHandCursor = false;
			toolMirror.useHandCursor = false;
			toolLasso.useHandCursor = false;
			toolMove.useHandCursor = false;
			toolRotate.useHandCursor = false;
			toolLine.useHandCursor = false;
			toolTrace.useHandCursor = false;
			toolZoom.useHandCursor = false;
			zoomInButton.useHandCursor = false;
			zoomOutButton.useHandCursor = false;

			buttonArr = [
							zoomInButton,
							zoomOutButton,
							toolZoom,
							toolMove,
							toolRotate,
							toolTrace,
							toolPen,
							toolFillPen,
							toolErase,
							toolUndo,
							toolRedo,
							toolSpuit,
							toolMirror,
							toolLasso,
							toolLine,
						];
		}
	}

}
