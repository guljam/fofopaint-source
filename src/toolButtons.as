package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	public class toolButtons extends Sprite {
		public var toolPen:SimpleButton = toolPen;
		public var toolFillPen:SimpleButton = toolFillPen;
		public var toolErase:SimpleButton = toolErase;
		public var toolUndo:SimpleButton = toolUndo;
		public var toolRedo:SimpleButton = toolRedo;
		public var toolSpuit:SimpleButton = toolSpuit;
		public var toolMirror:SimpleButton = toolMirror;
		public var toolLasso:SimpleButton = toolLasso;
		public var toolMove:SimpleButton = toolMove;
		public var toolRotate:SimpleButton = toolRotate;
		public var toolLine:SimpleButton = toolLine;
		public var toolTrace:SimpleButton = toolTrace;
		public var toolZoom:SimpleButton = toolZoom;
		public var zoomInButton:SimpleButton = zoomInButton;
		public var zoomOutButton:SimpleButton = zoomOutButton;
		public var deepUndoOK:SimpleButton = deepUndoOK;
		public var deepUndoCancel:SimpleButton = deepUndoCancel;
		public var toolSelectCursor:SimpleButton = toolSelectCursor
		private var lastTool:String = "toolPen";
		
		public const BOX_WIDTH:Number = 34;
		public const BOX_HEIGHT:Number = 476;

		// public var toolBoxBG2:SimpleButton = toolBoxBG2;
		public var toolInfo:TextField = toolInfo;
		public var toolInfoBG:Shape = new Shape();
		private var deafultY:Number = 0;
		
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
		
		public function deepUndoEtcIconAlpha(alpha:Number):void
		{
			toolPen.alpha = alpha;
			toolFillPen.alpha = alpha;
			toolErase.alpha = alpha;
			toolSpuit.alpha = alpha;
			toolMirror.alpha = alpha;
			toolLasso.alpha = alpha;
			toolMove.alpha = alpha;
			toolRotate.alpha = alpha;
			toolLine.alpha = alpha;
			toolTrace.alpha = alpha;
			toolZoom.alpha = alpha;
		}

		public function deepUndoTempMoveOFF():void
		{
			y = deafultY;
		}

		public function deepUndoTempMoveON():void
		{
			const bottom:Number = (deepUndoCancel.localToGlobal(new Point(0,0)) as Point).y + deepUndoCancel.height;
			if(bottom > stage.stageHeight)
			{
				y = y-(bottom-stage.stageHeight);
			}
			else
			{
				y = y-(bottom-stage.stageHeight);
				if(y > deafultY) deepUndoTempMoveOFF();
			}
		}

		public function deepUndoIconON():void
		{
			deepUndoOK.visible = true;
			deepUndoCancel.visible = true;
			toolMove.visible = false;
			toolPen.visible = false
			toolSelectCursor.visible = false;
			deepUndoEtcIconAlpha(0.15);
		}

		public function deepUndoIconOFF():void
		{
			deepUndoOK.visible = false;
			deepUndoCancel.visible = false;
			toolMove.visible = true;
			toolPen.visible = true;
			toolSelectCursor.visible = true;

			deepUndoEtcIconAlpha(1.0);
		}

		public function zoomIconON():void
		{
			toolZoom.visible = false;
			toolRotate.visible = false;
			zoomInButton.visible = true;
			zoomOutButton.visible = true;
			hintOFF();
			stage.addEventListener(MouseEvent.MOUSE_MOVE,zoomIconOFFEvent);
		}

		public function zoomIconOFF():void
		{
			toolZoom.visible = true;
			toolRotate.visible = true;
			zoomInButton.visible = false;
			zoomOutButton.visible = false;
		}

		public function hintOFF():void
		{
			toolInfo.visible = false;
			toolInfoBG.visible = false;
			toolInfo.x = 0;
			toolInfo.y = 0;
			toolInfo.width = 0;
			toolInfo.height = 0;
			toolInfoBG.x = 0;
			toolInfoBG.y = 0;
			toolInfoBG.width = 0;
			toolInfoBG.height = 0;
		}

		public function hint(str:String,target:SimpleButton,rightPosition:Boolean):void
		{
			const index:uint  = str.lastIndexOf("(");
			const firstLine:String = str.substr(0,index);
			const secondLine:String = str.substr(index);
			str = firstLine +"\n"+secondLine;

			toolInfo.text = str;
			toolInfo.width = toolInfo.textWidth+5;
			toolInfo.height = toolInfo.textWidth+3;
			toolInfo.x = (rightPosition === false) ? target.x+target.width+7 : target.x-toolInfo.textWidth-10;
			toolInfo.y = target.y-1;
			toolInfoBG.x = toolInfo.x-3;
			toolInfoBG.y = target.y;
			toolInfoBG.width = Math.floor(toolInfo.textWidth+10);
			toolInfoBG.height = Math.floor(toolInfo.textHeight+3);

			toolInfo.visible = true;
			toolInfoBG.visible = true;
		}

		public function changeUIColor(arr:Array):void
		{	
			const buttonArr:Array =
			[
				deepUndoOK,
				deepUndoCancel,
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

			const base:ColorTransform = new ColorTransform();
			// const subBase:ColorTransform = new ColorTransfo1rm();
			const iconLeft:ColorTransform = new ColorTransform();
			// const iconRight:ColorTransform = new ColorTransform();
			const activeColor:ColorTransform = new ColorTransform();
			const activeIconColor:ColorTransform = new ColorTransform();
			const defaultColor:ColorTransform = new ColorTransform();
           	base.color = arr[0];
           	// subBase.color = arr[1];
           	iconLeft.color = arr[2];
           	// iconRight.color = arr[3];
           	activeColor.color = arr[4];
			activeColor.alphaMultiplier = 0.0;
           	activeIconColor.color = arr[5];

			toolInfoBG.transform.colorTransform = base;

			var len:uint = buttonArr.length;
			var btn:SimpleButton;
			var btnUp:DisplayObject;
			var btnOver:DisplayObjectContainer;
			var btnDown:DisplayObjectContainer;

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
			deepUndoOK.x = toolMove.x;
			deepUndoOK.y = toolMove.y;
			deepUndoCancel.x = toolPen.x;
			deepUndoCancel.y = toolPen.y;

			setChildIndex(zoomInButton,numChildren-1);
			setChildIndex(zoomOutButton,numChildren-1);

			const rotateButton:DisplayObjectContainer = toolRotate.downState as DisplayObjectContainer;
			rotateButton.x = 0;
			rotateButton.y = 0;
			
			//텍스트
			toolInfo.textColor = arr[2];
		}

		// public function initPenSizeCursor():void
		// {
		// 	const g:Graphics = toolSelectCursor.graphics;
		// 	const btn:SimpleButton = getChildByName("toolPen") as SimpleButton;

		// 	g.clear();
		// 	g.lineStyle(1,0xFF6600,1.0,true);
		// 	g.drawRect(0,0,btn.width,btn.height);
		// 	addChild(toolSelectCursor);
		// }

		public function moveToolCursorInit():void
		{
			moveToolCursor(lastTool);
		}

		public function moveToolCursor(childName:String):void
		{
			const btn:SimpleButton = getChildByName(childName) as SimpleButton;
			if(btn)
			{
				const _toolSelectCursor:SimpleButton = toolSelectCursor;

				_toolSelectCursor.x = btn.x;
				_toolSelectCursor.y = btn.y;
				lastTool = childName;
			}
		}

		public function toolButtons() {

			toolInfoBG.visible = false;
			const g:Graphics = toolInfoBG.graphics;
			g.lineStyle(0,0,0);
			g.beginFill(0xCCCCCC);
			g.drawRect(0,0,10,10);
			g.endFill();

			toolInfo.visible = false;

			addChild(toolInfoBG);
			setChildIndex(toolInfoBG,0);
			
			zoomInButton.visible = false;
			zoomOutButton.visible = false;
			deepUndoOK.visible = false;
			deepUndoCancel.visible = false;

			// initPenSizeCursor();
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
		}
	}

}
