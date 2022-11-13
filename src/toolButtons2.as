package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	
	public class toolButtons2 extends Sprite {
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
		public var toolBoxBG:SimpleButton = toolBoxBG;
		public var toolBoxBG2:SimpleButton = toolBoxBG2;
		public var toolSidebar:SimpleButton = toolSidebar;
		public var toolInfo:TextField = toolInfo;
		public const fixedScale:Number = 0.85;
		private var infoDataBackup:Array = [];

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
			const leftButtonArr:Array =
			[
				toolZoom,
				toolMove,
				toolRotate,
				toolTrace,
			];

			const rightButtonArr:Array =
			[
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

			const base:ColorTransform = new ColorTransform();
			const subBase:ColorTransform = new ColorTransform();
			const iconLeft:ColorTransform = new ColorTransform();
			const iconRight:ColorTransform = new ColorTransform();
			const activeColor:ColorTransform = new ColorTransform();
			const activeIconColor:ColorTransform = new ColorTransform();
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
			var btn:SimpleButton ;
			var btnUp:DisplayObject;
			var btnOver:DisplayObjectContainer;

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
		}

		public function toolButtons2()
		{
			scaleX = fixedScale;
			scaleY = fixedScale;

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
			toolBoxBG.useHandCursor = false;
			toolBoxBG2.useHandCursor = false;
			toolSidebar.useHandCursor = false;
			
			toolPen.visible = false;
			toolErase.visible = true;

			visible = false;
		}
	}
	
}
