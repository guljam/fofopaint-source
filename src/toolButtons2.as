package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;

	public class toolButtons2 extends Sprite {
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
		public var toolBoxBG:SimpleButton;
		public var toolBoxBG2:SimpleButton;
		public var toolSidebar:SimpleButton;
		public var toolInfo:TextField;
		private var fixedScale:Number = 1.0;
		private var infoDataBackup:Array = [];

		private var lastUsedToolPoint:Point = new Point(0,0);

		public function getLastUsedToolPos():Point
		{
			return lastUsedToolPoint;
		}

		public function updateLastUsedToolPos(targetName:String):void
		{
			const btn:SimpleButton = this.getChildByName(targetName) as SimpleButton;
			lastUsedToolPoint.setTo((btn.x+btn.width/2)*fixedScale,(btn.y+btn.height/2)*fixedScale);

		}

		public function hint(str:String):void
		{
			if(str.indexOf("\n") !== -1)
			{
				if(infoDataBackup.length === 0)
				{
					infoDataBackup[0] = toolInfo.y;
					infoDataBackup[1] = toolInfo.height;
					infoDataBackup[2] = toolBoxBG.y;
					infoDataBackup[3] = toolBoxBG.height;

					toolInfo.y -= 20;
					toolInfo.height += 20;
					toolBoxBG.y -= 20;
					toolBoxBG.height += 20;
				}
			}
			else if(infoDataBackup.length !== 0)
			{
				toolInfo.y = infoDataBackup[0];
				toolInfo.height = infoDataBackup[1];
				toolBoxBG.y = infoDataBackup[2];
				toolBoxBG.height = 60;
				infoDataBackup.length = 0;
			}

			toolInfo.text = str;
		}

		public function setToolButtonsForCheckedLayerON(alp:Number):void
		{
			toolPen.alpha = alp;
			toolErase.alpha = alp;
			toolFillPen.alpha = alp;
			toolSpuit.alpha = alp;
			toolLine.alpha = alp;
		}

		public function setToolButtonsForCheckedLayerOFF():void
		{
			toolPen.alpha = 1.0;
			toolErase.alpha = 1.0;
			toolFillPen.alpha = 1.0;
			toolSpuit.alpha = 1.0;
			toolLine.alpha = 1.0;
		}

		public function deepUndoEtcIconAlpha(alpha:Number):void
		{
			toolPen.alpha = alpha;
			toolFillPen.alpha = alpha;
			toolErase.alpha = alpha;
			toolSpuit.alpha = alpha;
			toolMirror.alpha = alpha;
			toolLasso.alpha = alpha;
			toolLine.alpha = alpha;
			toolMove.alpha = alpha;
			toolTrace.alpha = alpha;
		}


		public function changeUIColor(arr:Array):void
		{
			const base:ColorTransform = new ColorTransform();
			const subBase:ColorTransform = new ColorTransform();
			const iconLeft:ColorTransform = new ColorTransform();
			const iconRight:ColorTransform = new ColorTransform();
			const activeColor:ColorTransform = new ColorTransform();
			const activeIconColor:ColorTransform = new ColorTransform();
			var btn:SimpleButton;
			var btnUp:DisplayObject;
			var btnOver:DisplayObjectContainer;

			const leftButtonArr:Array = [
											toolZoom,
											toolMove,
											toolRotate,
											toolTrace,
										];

			const rightButtonArr:Array = [
											toolPen,
											toolFillPen,
											toolErase,
											toolUndo,
											toolRedo,
											toolSpuit,
											toolMirror,
											toolLasso,
											toolLine,
											toolSidebar
										];

           	base.color = arr[0];
           	subBase.color = arr[1];
           	iconLeft.color = arr[2];
           	iconRight.color = arr[3];
           	activeColor.color = arr[4];
           	activeIconColor.color = arr[5];

			//배경
			toolBoxBG.transform.colorTransform = base;
			toolBoxBG2.transform.colorTransform = subBase;
			var i:uint = 0;
			var len:uint = leftButtonArr.length;

			for(i=0;i<len;i++)
			{
				btn = leftButtonArr[i];
				btnUp = btn.upState as DisplayObject;
				btnOver = btn.overState as DisplayObjectContainer;
				btnUp.transform.colorTransform = iconLeft;
				btnOver.getChildAt(0).transform.colorTransform = activeColor;//버튼 배경
				btnOver.getChildAt(1).transform.colorTransform = activeIconColor; //버튼 아이콘
				btn.downState = btn.overState;
			}

			len = rightButtonArr.length;
			for(i=0;i<len;i++)
			{
				btn = rightButtonArr[i];
				btnUp = btn.upState as DisplayObject;
				btnOver = btn.overState as DisplayObjectContainer;
				btnUp.transform.colorTransform = iconRight;
				btnOver.getChildAt(0).transform.colorTransform = activeColor; //d
				btnOver.getChildAt(1).transform.colorTransform = iconRight;
				btn.downState = btn.overState;
			}
			//텍스트
			toolInfo.textColor = arr[2];

			btn = null;
			btnUp = null;
			btnOver = null;
		}

		public function setScale(newScale:Number):void
		{
			this.scaleX = newScale*fixedScale;
			this.scaleY = newScale*fixedScale;
		}

		public function toolButtons2()
		{
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
			toolSidebar.useHandCursor = false;
			toolBoxBG2.mouseEnabled = false;
			toolBoxBG.mouseEnabled = false;

			toolPen.visible = false;
			toolErase.visible = true;
			visible = false;

			fixedScale = 34/toolPen.width;
			setScale(1.0);
		}
	}

}
