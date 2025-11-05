package
{
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.geom.ColorTransform;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;

	public class ToolMenuSet extends Sprite
	{
		public var toolPen:SimpleButton;
		public var toolFillPen:SimpleButton;
		public var toolFillPenOK:SimpleButton;
		public var toolFillPenCancel:SimpleButton;
		public var toolScanFill:SimpleButton;
		public var toolErase:SimpleButton;
		public var toolUndo:SimpleButton;
		public var toolRedo:SimpleButton;
		public var toolEyedropper:SimpleButton;
		public var toolMirror:SimpleButton;
		public var toolLasso:SimpleButton;
		public var toolMove:SimpleButton;
		public var toolRotate:SimpleButton;
		public var toolLine:SimpleButton;
		public var toolRefLayer:SimpleButton;
		public var toolZoomIn:SimpleButton;
		public var toolZoomOut:SimpleButton;
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

		private var checkedLayerONFlag:Boolean = false;

		public function setFillPenModeOFF():void
		{
			toolErase.alpha = 1.0;
			toolFillPen.alpha = 1.0;
			toolEyedropper.alpha = 1.0;
			toolLine.alpha = 1.0;
			toolLasso.alpha = 1.0;
			toolLasso.alpha = 1.0;
			toolMove.alpha = 1.0;
			toolRefLayer.alpha = 1.0;
			toolMirror.alpha = 1.0;

			toolSelectCursor.visible = true;
			toolRedo.visible = true;
			toolPen.visible = true;
			toolFillPenOK.visible = false;
			toolFillPenCancel.visible = false;
		}

		public function setFillPenModeON(offAlpha:Number):void
		{
			toolErase.alpha = offAlpha;
			toolFillPen.alpha = offAlpha;
			toolEyedropper.alpha = offAlpha;
			toolLine.alpha = offAlpha;
			toolLasso.alpha = offAlpha;
			toolLasso.alpha = offAlpha;
			toolMove.alpha = offAlpha;
			toolRefLayer.alpha = offAlpha;
			toolMirror.alpha = offAlpha;

			toolSelectCursor.visible = false;
			toolRedo.visible = false;
			toolPen.visible = false;
			toolFillPenOK.visible = true;
			toolFillPenCancel.visible = true;
		}

		public function setIconAlphaOnLassoToolON(alpha:Number):void
		{
			if (alpha < 1.0)
			{
				toolMirror.alpha = alpha;
				toolMove.alpha = alpha;
				toolUndo.alpha = alpha;
				toolRedo.alpha = alpha;
				toolPen.alpha = alpha;
				toolErase.alpha = alpha;
				toolFillPen.alpha = alpha;
				// toolScanFill.alpha = alpha;
				toolEyedropper.alpha = alpha;
				toolLasso.alpha = alpha;
				toolLine.alpha = alpha;
				toolRefLayer.alpha = alpha;
			}
			else
			{
				toolMirror.alpha = alpha;
				toolMove.alpha = alpha;
				toolUndo.alpha = alpha;
				toolRedo.alpha = alpha;
				toolLasso.alpha = alpha;

				if (checkedLayerONFlag === false)
				{
					toolPen.alpha = alpha;
					toolErase.alpha = alpha;
					toolFillPen.alpha = alpha;
					// toolScanFill.alpha = alpha;
					toolEyedropper.alpha = alpha;
					toolLine.alpha = alpha;
					toolRefLayer.alpha = alpha;
				}

			}
		}

		public function setToolButtonsForCheckedLayerOFF():void
		{
			checkedLayerONFlag = false;
			toolPen.alpha = 1.0;
			toolErase.alpha = 1.0;
			toolFillPen.alpha = 1.0;
			// toolScanFill.alpha = 1.0;
			toolEyedropper.alpha = 1.0;
			toolLine.alpha = 1.0;
			toolSelectCursor.alpha = 1.0;
		}

		public function setToolButtonsForCheckedLayerON(alp:Number):void
		{
			checkedLayerONFlag = true;
			toolPen.alpha = alp;
			toolErase.alpha = alp;
			toolFillPen.alpha = alp;
			// toolScanFill.alpha = alp;
			toolEyedropper.alpha = alp;
			toolLine.alpha = alp;

			const btn:SimpleButton = getChildByName(lastTool) as SimpleButton;
			if (btn)
				toolSelectCursor.alpha = btn.alpha;
		}

		public function bgBoxVisible(flag:Boolean):void
		{
			if (flag)
			{
				addChild(bgBox);
				setChildIndex(bgBox, 0);
			}
			else
			{
				removeChild(bgBox);
			}
		}

		public function updateBGBoxColor(color:uint):void
		{
			bgBox.graphics.lineStyle(0, 0, 0);
			bgBox.graphics.beginFill(color);
			bgBox.graphics.drawRect(-4, -1, BOX_WIDTH + 8, BOX_HEIGHT + 2);
			bgBox.graphics.endFill();
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

		public function checkBottomOFF():void
		{
			y = deafultY;
		}

		public function initCanvasControlButtons(newParent:DisplayObjectContainer):void
		{
			newParent.addChild(toolZoomIn);
			newParent.addChild(toolZoomOut);
			newParent.addChild(toolRotate);
			newParent.addChild(toolMirror);

			toolZoomIn.x = 26;
			toolZoomIn.y = 23;
			toolZoomOut.x = toolZoomIn.x + toolZoomIn.width + 7;
			toolZoomOut.y = toolZoomIn.y;
			toolRotate.x = toolZoomOut.x + toolZoomOut.width + 8;
			toolRotate.y = toolZoomIn.y;
			toolMirror.x = toolRotate.x + toolRotate.width + 7;
			toolMirror.y = toolZoomIn.y;
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
			const fillPenButtons:Array = [toolFillPenOK, toolFillPenCancel];

			for (var i:uint = 0; i < len; i++)
			{
				btn = buttonArr[i];
				btnUp = btn.upState as DisplayObject;
				btnUp.transform.colorTransform = iconLeft;
				btnOver = btn.overState as DisplayObjectContainer;
				btnOver.getChildAt(0).transform.colorTransform = activeColor; // 버튼 배경
				btnOver.getChildAt(1).transform.colorTransform = iconLeft; // 버튼 아이콘
				btnDown = btn.downState as DisplayObjectContainer;
				btnDown.getChildAt(0).transform.colorTransform = activeColor; // 버튼 배경
				btnDown.getChildAt(1).transform.colorTransform = iconLeft; // 버튼 아이콘
				btnDown.x = 2;
				btnDown.y = 2;
			}

			len = fillPenButtons.length;
			for (i = 0; i < len; i++)
			{
				btn = fillPenButtons[i];
				btnUp = btn.upState as DisplayObject;
				btnUp.transform.colorTransform = iconLeft;
				btnOver = btn.overState as DisplayObjectContainer;
				btnOver.getChildAt(0).transform.colorTransform = activeColor; // 버튼 배경
				btnOver.getChildAt(1).transform.colorTransform = iconLeft; // 버튼 아이콘
				btnDown = btn.downState as DisplayObjectContainer;
				btnDown.getChildAt(0).transform.colorTransform = activeColor; // 버튼 배경
				btnDown.getChildAt(1).transform.colorTransform = iconLeft; // 버튼 아이콘
				btnDown.x = 2;
				btnDown.y = 2;
			}

			const rotateButton:DisplayObjectContainer = toolRotate.downState as DisplayObjectContainer;
			rotateButton.x = 0;
			rotateButton.y = 0;

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

		public function moveToolCursor(childName:String, newParent:DisplayObjectContainer = null):void
		{
			var btn:SimpleButton;
			if (newParent !== null)
			{
				if (!newParent.contains(toolSelectCursor))
				{
					newParent.addChild(toolSelectCursor);
				}
				btn = newParent.getChildByName(childName) as SimpleButton;
			}
			else
			{
				if (!this.contains(toolSelectCursor))
				{
					this.addChild(toolSelectCursor);
				}
				btn = this.getChildByName(childName) as SimpleButton;
			}

			if (!btn)
			{
				return;
			}

			toolSelectCursor.x = btn.x;
			toolSelectCursor.y = btn.y;
			lastTool = childName;

			toolSelectCursor.alpha = btn.alpha;
		}

		public function initButtonsPos():void
		{
			const len:uint = buttonArr.length;

			buttonArr[0].x = 0;
			buttonArr[0].y = 0;
			buttonArr[0].useHandCursor = false;

			for (var i:uint = 1; i < len; i++)
			{
				buttonArr[i].x = buttonArr[i - 1].x;
				buttonArr[i].y = buttonArr[i - 1].y + buttonArr[i - 1].height + 2;
				buttonArr[i].useHandCursor = false;
			}

			toolFillPenOK.x = toolRedo.x;
			toolFillPenOK.y = toolRedo.y;
			toolFillPenCancel.x = toolPen.x;
			toolFillPenCancel.y = toolPen.y;
		}

		public function ToolMenuSet()
		{
		trace("toolSelectCursor",toolSelectCursor);
			moveToolCursorInit();

			// initPenSizeCursor();
			toolSelectCursor.mouseEnabled = false;
			toolPen.useHandCursor = false;
			toolFillPen.useHandCursor = false;
			toolFillPenOK.useHandCursor = false;
			toolFillPenCancel.useHandCursor = false;
			// toolScanFill.useHandCursor = false;
			toolErase.useHandCursor = false;
			toolUndo.useHandCursor = false;
			toolRedo.useHandCursor = false;
			toolEyedropper.useHandCursor = false;
			toolMirror.useHandCursor = false;
			toolLasso.useHandCursor = false;
			toolMove.useHandCursor = false;
			toolRotate.useHandCursor = false;
			toolLine.useHandCursor = false;
			toolRefLayer.useHandCursor = false;
			toolZoomIn.useHandCursor = false;
			toolZoomOut.useHandCursor = false;

			toolFillPenOK.visible = false;
			toolFillPenCancel.visible = false;

			buttonArr = [
					toolUndo,
					toolRedo,
					toolPen,
					toolErase,
					toolFillPen,
					// toolScanFill,
					toolEyedropper,
					toolLine,
					toolLasso,
					toolMove,
					toolRefLayer,
					toolZoomIn,
					toolZoomOut,
					toolRotate,
					toolMirror
				];

			initButtonsPos();
		}
	}
}
