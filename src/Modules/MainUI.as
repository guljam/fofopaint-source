package Modules
{
    import Modules.CaptureEngine.CaptureStamp;
    import Modules.CaptureEngine.CaptureArea;
    import Modules.CaptureEngine.CaptureController;
	import Modules.MainUIController;
	import Modules.SidebarController;
	import Modules.Tools.LassoTool;

	import Symbols.CapStampFontListSet;
	import Symbols.HintBoxSet;
	import Symbols.TopMenuSet;
	import Symbols.SeekBarSet;

	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import Modules.Tools.LineTool;
	import Modules.ReplayEngine.ReplayController;
	import Modules.ReplayEngine.ReplayDrawer;
	import Modules.ReplayEngine.ReplayState;

	public final class MainUI
	{
		public static var main:Main;
		public static function setMainInstance(instance:Main):void
		{
			main = instance;
		}
		public static var mouseHint:HintBoxSet = new HintBoxSet(true);
		public static var bottomHint:HintBoxSet = new HintBoxSet(false);
		// todo main ui topbar stage bg 는 따로빼고 hint 클래스로 만들어버리기, 타이머에서 앱전체 가동 시간 힌트로 표시하기 바로 밑에, 힌트은 예전처럼 툴 옆에 표시해보기, topbar힌트는 조금 고민임,
		// todo 커스텀 마우스 커서랑 최종적으로 앱 상세 살정할수있는 작은 옵션 버튼들 창 만들어야함, 현재 계속 누르고 있는 확인은 실제 확인창 만들어서 그냥 쉽게 선택하게 하기
		// todo ui색깔 변경 스케일 변경 등 클래스를더 쪼개야함
		public static const stageBG:Sprite = new Sprite(); // 드래그 불러오기가 stage공백에서는 안되서 수동으로 전체바탕으로 만들어줌
		public static const topBar:TopMenuSet = new TopMenuSet();
		private static const BOTTOM_HINT_SCROLL_TIMER:String = "bottomHintScrollTimer";
		private static var bottomHintScrollWaitFrames:int = 0;
		private static var bottomHintScrollToLeft:Boolean = true;
		private static const BOTTOM_HINT_SCROLL_SPEED:Number = 2;
		public static const bottomBar:Sprite = new Sprite();
		private static const hintHighlightBox:Shape = new Shape(); // 요소에 마우스 클릭하면 사각형으로 하이라이트 표시해줌
		private static const lastBottomHintTargetRect:Rectangle = new Rectangle(); // bottomhint mosue move에서 자꾸 호출해주니까 저장해서 호출 덜하게 해줌
		private static var canvasStateBeforeCaptureMode:Object = {}; // 캡쳐 키면 캔버스 이전 상태 저장함
		public static var drawModeCanvasStateForSaveAppState:Object = {}; // save app state에서 캔버스가 capture모드 상태로 저장해주기 때문에 백업한 데이터로 저장시켜줌

		public static function isSameWithLastBottomHintTargetRect(target:DisplayObject):Boolean
		{
			return lastBottomHintTargetRect.equals(target.getBounds(main.stage));
		}

		private static function updateLastBottomHintTargetRect(target:DisplayObject):void
		{
			const rect:Rectangle = target.getBounds(main.stage);

			lastBottomHintTargetRect.x = rect.x;
			lastBottomHintTargetRect.y = rect.y;
			lastBottomHintTargetRect.width = rect.width;
			lastBottomHintTargetRect.height = rect.height;
		}

		public static function resetLastBottomHintTargetRect():void
		{
			lastBottomHintTargetRect.x = 0;
			lastBottomHintTargetRect.y = 0;
			lastBottomHintTargetRect.width = 0;
			lastBottomHintTargetRect.height = 0;
		}

		public static function getImageScaleHint(width:Number, height:Number, scale:Number, scaleXFlag:Boolean):String
		{
			const scaleStr:String = Math.round(scale * 100) + "%";
			if (scaleXFlag)
			{
				return Math.round(width * scale) + " x " + Math.round(height * scale) + " (" + scaleStr + ")";
			}
			return Math.round(width) + " x " + Math.round(height) + " (" + scaleStr + ")";
		}

		public static function isHintUnavailable():Boolean
		{
			return CanvasController.isMouseLeftClicked || CanvasController.isRightMouseClicked || CanvasController.isMouseDragging || ToolController.isToolBox2Showing
				|| ColorPickerController.numPadBox.visible || AboutBoxController.isAboutBoxOpened || ReplayState.isGeneratingCacheImages();
			// || isFillPenStarted
			// || isLassoToolStarted
		}

		public static function showMouseHintLayerVisible():void
		{
			showMouseHintTemp(HintStrings.getLayerVisibleHint(CanvasController.canvasLayer1Bitmap.visible, CanvasController.canvasLayer2Bitmap.visible));
		}

		private static function showBottomHintForTargetCaptureMode(target:DisplayObject):void
		{
			if (isHintUnavailable())
			{
				return;
			}

			const hint:String = HintStrings.getHintFromTargetNameCaptureMode(target.name);

			if (hint)
			{
				FOFOTimer.remove("bottomHintOffDelay");

				const targetName:String = target.name;
				const xCanvasPanel:Sprite = (ReplayState.isReplayModeON) ? ReplayDrawer.rCanvasPanel : CanvasController.canvasPanel;
				if (CaptureArea.isFullImageCapture() && xCanvasPanel.hitTestPoint(main.stage.mouseX, main.stage.mouseY, true))
				{
					showHintHighlightBox((ReplayState.isReplayModeON) ? ReplayDrawer.rCanvasLayer1Bitmap : CanvasController.canvasLayer1Bitmap);
					showBottomHint(hint);
				}
				else if (!(targetName === "rCanvasPanel"
							|| targetName === "rCanvasDrawLayer"
							|| targetName === "canvasPanel"
							|| targetName === "canvasDrawLayer"))
				{
					showHintHighlightBox(target);
					showBottomHint(hint);
				}
			}
			else
			{
				if (!FOFOTimer.hasTimer("bottomHintOffDelay"))
				{
					FOFOTimer.addByName("bottomHintOffDelay", 0.3, false, hideBottomHint);
				}
			}
		}

		public static function isHintAvailableWithFillPen(target:DisplayObject):Boolean
		{
			const targetName:String = target.name;
			if (FillPenTool.isStarted || LineTool.isStarted)
			{
				if (target.alpha > 0.5
						&&
						(ToolController.toolBox.contains(target)
							|| CanvasController.canvasInfoBox.contains(target)
							|| ColorPickerController.colorPickerBox.contains(target))
						|| target === SidebarController.sideBarScrollBar
						|| (targetName && targetName.indexOf(Global.ALPHA_BUTTON_PREFIX) !== -1))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else if (ToolController.isSelectedTool(ToolController.TOOL_FILLPEN))
			{
				if ((targetName && targetName.indexOf(Global.NSIZE_BUTTON_PREFIX) !== -1) || target.alpha < 0.5)
				{
					return false;
				}
			}
			else if (isHintUnavailable())
			{
				return false;
			}
			return true;
		}

		public static function onMouseMoveBottomHint(e:MouseEvent):void
		{
			const target:DisplayObject = e.target as DisplayObject;
			if (!target)
			{
				return;
			}

			if (isSameWithLastBottomHintTargetRect(target) || ToolController.isToolBox2Showing)
			{
				return;
			}

			FOFOTimer.remove("bottomHintOnDelay");
			updateLastBottomHintTargetRect(target);

			if (CaptureController.isCaptureModeON)
			{
				showBottomHintForTargetCaptureMode(target);
			}
			else if (LassoTool._isLassoToolStarted)
			{
				if (LassoTool.isHintAvailableWithLassoToolStarted(target))
				{
					showBottomHintForTarget(target);
				}
			}
			else if (isHintAvailableWithFillPen(target))
			{
				showBottomHintForTarget(target);
			}
		}

		public static function showBottomHintForTarget(target:DisplayObject):void
		{
			const hint:String = HintStrings.getHintFromTargetName(target.name);

			if (hint)
			{
				FOFOTimer.remove("bottomHintOffDelay");

				if (CanvasController.isCanvasNaviatorChild(target))
				{
					showHintHighlightBox(CanvasController.canvasNavigatorBox.navStageBG);
				}
				else
				{
					showHintHighlightBox(target);
				}

				if (!isBottomBarVisible())
				{
					FOFOTimer.addByName("bottomHintOnDelay", 1.0, false, showBottomHint, [hint]);
				}
				else if (bottomHint.visible)
				{
					showBottomHint(hint);
				}
			}
			else
			{
				if (!FOFOTimer.hasTimer("bottomHintOffDelay"))
				{
					FOFOTimer.addByName("bottomHintOffDelay", 0.3, false, hideBottomHint);
				}
			}
		}

		public static function showHintHighlightBox(target:DisplayObject):void
		{
			const scale:Number = Global.getUIScale();
			hintHighlightBox.graphics.clear();
			hintHighlightBox.graphics.lineStyle(2 * scale, Global.getHintHightlightColor(), 1.0);

			if (target.parent === CanvasController.canvasNavigatorBox)
			{
				target = CanvasController.canvasNavigatorBox;
			}

			const rect:Rectangle = target.getBounds(main.stage);

			if (target === ColorPickerController.colorPickerBox.rgbInfoText)
			{
				// rect.y -= 2*scale;
				rect.height -= 2 * scale;
			}
			else if (target === SidebarController.sideBarScrollBar)
			{
				rect.x += 1 * scale;
				rect.y += 1 * scale;
				rect.width -= 2 * scale;
				rect.height -= 2 * scale;
			}

			hintHighlightBox.x = rect.x;
			hintHighlightBox.y = rect.y;
			hintHighlightBox.graphics.drawRect(0, 0, rect.width, rect.height);
			updateHightLightBoxZOrderByTarget(target);
			hintHighlightBox.visible = true;
		}

		private static function updateHightLightBoxZOrderByTarget(target:DisplayObject):void
		{
			const topIndex:int = main.stage.numChildren - 1;
			const tbIndex:int = main.stage.getChildIndex(topBar);
			const hIndex:int = main.stage.getChildIndex(hintHighlightBox);

			if (topBar.contains(target) || ReplayController.seekBarBox.contains(target))
			{
				var desiredIndex:int = Math.min(tbIndex + 1, topIndex);
				if (hIndex != desiredIndex)
				{
					main.stage.setChildIndex(hintHighlightBox, desiredIndex);
				}
			}
			else
			{
				var desiredIndex2:int = Math.max(tbIndex - 1, 0);
				if (hIndex != desiredIndex2)
				{
					main.stage.setChildIndex(hintHighlightBox, desiredIndex2);
				}
			}
		}

		private static function hideHintHighlightBox():void
		{
			hintHighlightBox.graphics.clear();
			hintHighlightBox.visible = false;
		}

		public static function isBottomBarVisible():Boolean
		{
			return bottomBar.visible;
		}

		public static function isHighlightBoxVisible():Boolean
		{
			return hintHighlightBox.visible;
		}

		public static function hideBottomHint():void
		{
			FOFOTimer.remove("bottomHintOnDelay");
			hideHintHighlightBox();
			bottomBar.visible = false;
			bottomHint.hide();
		}

		public static function showBottomHint(str:String):void
		{
			if (str === "")
			{
				return;
			}

			const wasVisible:Boolean = bottomBar.visible && bottomHint.visible;
			const textChanged:Boolean = !bottomHint.hasHintText(str);

			if (textChanged)
			{
				bottomHint.setHintText(str);
			}

			bottomHint.show();

			if (!bottomBar.visible)
			{
				MainUIController.updateBottomBarLayoutAndColor();
			}

			bottomBar.visible = true;
			Utils.setAsTopChild(bottomBar);

			if (textChanged || !wasVisible)
			{
				if (bottomHint.width > main.stage.stageWidth)
				{
					startBottomHintScrolling();
				}
				else
				{
					stopBottomHintScrolling();
				}
			}
		}

		public static function hideMouseHint():void
		{
			mouseHint.hide();
		}

		public static function showMouseHintTemp(str:String, duration:Number = 2.0):void
		{
			showMouseHint(str, duration);
		}

		public static function showMouseHint(str:String, duration:Number = 0.0):void
		{
			if (str !== "")
			{
				mouseHint.setHintText(str);
			}

			const stw:uint = main.stage.stageWidth + 1;
			const sth:uint = main.stage.stageHeight + 1;
			const hintWidth:Number = mouseHint.getScaledTextWidth();
			const hintHeight:Number = mouseHint.getScaledTextHeight();
			var hintX:Number = Math.floor(main.mouseX - hintWidth / 2) + 5;
			var hintY:Number = Math.floor(main.mouseY - 45 * Global.getUIScale());
			const hintRight:int = hintX + hintWidth;
			const hintBottom:int = hintY + hintHeight;

			if (hintX < 0)
			{
				hintX = 0;
			}
			else if (hintRight > stw)
			{
				hintX = stw - hintWidth;
			}

			if (hintY < 0)
			{
				hintY = 0;
			}
			else if (hintBottom >= sth)
			{
				hintY = sth - hintHeight;
			}

			mouseHint.x = Math.floor(hintX);
			mouseHint.y = Math.floor(hintY);
			mouseHint.setHintText(str);
			mouseHint.show(duration);
			Utils.setAsTopChild(mouseHint);
		}

		public static function initializeAppMenus():void
		{
			topBar.name = "topBar";
			SidebarController.sideBarScrollBar.name = "sideBarScrollBar";
			topBar.makeTopbarBG(Global.setDefaultUIColor());
			MainUIController.updateTopbarIconsDrawMode();

			FillPenTool.fillPenBox.x = -FillPenTool.fillPenBox.width - 3;
			FillPenTool.fillPenBox.y = -FillPenTool.fillPenBox.height - 3;

			CanvasController.canvasNavigatorBox.scrollRect = new Rectangle(0, 0, CanvasController.canvasNavigatorBox.width, CanvasController.canvasNavigatorBox.height);

			SidebarController.sideBarScrollPanel.addChild(CanvasController.canvasNavigatorBox);
			SidebarController.sideBarScrollPanel.addChild(CanvasController.canvasInfoBox);
			ToolController.toolBox.moveCanvasControlButtonsTo(CanvasController.canvasInfoBox);
			SidebarController.sideBarScrollPanel.addChild(ToolController.toolBox);
			SidebarController.sideBarScrollPanel.addChild(ToolController.toolOptionsBox);
			SidebarController.sideBarScrollPanel.addChild(ColorPickerController.colorPickerBox);

			SidebarController.sideBar.addChild(SidebarController.sideBarScrollBar);
			SidebarController.sideBar.addChild(SidebarController.sideBarScrollPanel);
			SidebarController.sideBar.updateSideBGSize(SidebarController.getSideBarBGHeight());
			SidebarController.sideBarScrollBar.alpha = 0.75;
			MainUIController.STAGE_TOP_OFFSET = topBar.BARSIZE;

			CaptureStamp.captureStampFontListBox.y = 100;

			topBar.updateTimerPos(main.stage.stageWidth);
			topBar.replayFitToWindowButton.alpha = Global.OFFALPHA;

			bottomBar.name = "bottomBar";
			bottomBar.addChild(bottomHint);
			bottomHint.x = 2;
			bottomHint.y = 3;

			ToolController.selectedToolViewBitmap.name = "selectedToolViewBitmap";
			ToolController.selectedToolViewBitmap.visible = false;

			main.stage.addChild(FileManager.loadMenuBox);
			main.stage.addChild(ReferenceLayerController.refLayerMenuBox);
			main.stage.addChild(AboutBoxController.aboutBox);
			main.stage.addChild(SidebarController.sideBar);
			main.stage.addChild(FillPenTool.fillPenBox);
			main.stage.addChild(ToolController.toolBox2);
			main.stage.addChild(CanvasController.canvasRotateCursor);
			main.stage.addChild(ColorPickerController.numPadBox);
			main.stage.addChild(CaptureStamp.captureStampFontListBox);
			main.stage.addChild(topBar);
			main.stage.addChild(hintHighlightBox);
			main.stage.addChild(bottomBar);
			main.stage.addChild(mouseHint);
			main.stage.addChild(ToolController.selectedToolViewBitmap);
		}

		public static function hideCanvasRotateCursor():void
		{
			CanvasController.canvasRotateCursor.visible = false;
		}

		public static function showCanvasRotateCursorMouseDrag(target:DisplayObject):Function
		{
			const snapThreshold:Number = 82;
			CanvasController.canvasRotateCursor.x = main.stage.mouseX;
			CanvasController.canvasRotateCursor.y = main.stage.mouseY + (65 * Global.getUIScale());
			CanvasController.canvasRotateCursor.rotateArrow.rotation = target.rotation;
			Utils.setAsTopChild(CanvasController.canvasRotateCursor);
			CanvasController.canvasRotateCursor.visible = true;

			const toDeg:Number = 180.0 / Math.PI;
			// 움직인 각도합 로테이트 캔버스 마지막각도를 넣어줌 rad로 변환

			var sumAng:Number = target.rotation;
			// 각도 차이 구하기 위해서 넣어줌, 초기 값은 마우스 클릭한 위치의 각도값
			var lastAng:Number = Math.atan2(main.stage.mouseX - CanvasController.canvasRotateCursor.x, main.stage.mouseY - CanvasController.canvasRotateCursor.y) * toDeg;
			var activateSnapFlag:Boolean = false;
			var ignoreSnapFlag:Boolean = true;
			var snappedAng:Number = 0;

			return function ():Number
			{
				const nowAng:Number = Math.atan2(main.stage.mouseX - CanvasController.canvasRotateCursor.x, main.stage.mouseY - CanvasController.canvasRotateCursor.y) * toDeg;
				const subAng:Number = lastAng - nowAng;

				lastAng = nowAng;
				sumAng += subAng;
				var deg:Number = sumAng;
				const snap90:Number = Math.abs(deg % 90.0); // 90도 스냅 변수
				const snap90N:Number = 90.0 - snap90;
				const snapAng:Number = (snap90 > snap90N) ? snap90 : snap90N;

				if (snapAng > snapThreshold && ignoreSnapFlag === false)
				{
					activateSnapFlag = true;
					deg = Math.round(deg / 90) * 90;
					if (snappedAng !== deg)
					{
						snappedAng = deg;
					}
				}
				else if (activateSnapFlag === true)
				{
					sumAng = snappedAng;
					deg = snappedAng;
					activateSnapFlag = false;
					ignoreSnapFlag = true;
				}
				else if (ignoreSnapFlag === true)
				{
					if (snapAng <= snapThreshold)
					{
						ignoreSnapFlag = false;
					}
				}

				CanvasController.canvasRotateCursor.rotateArrow.rotation = deg;
				return Math.round(deg);
			};
		}

		private static function resetBottomHintScrolling():void
		{
			bottomHint.x = 0;
			bottomHintScrollWaitFrames = 0;
			bottomHintScrollToLeft = true;
		}

		private static function animateBottomHintScrolling():Boolean
		{
			if (!bottomHint.visible)
			{
				resetBottomHintScrolling();
				return false;
			}

			const rect:Rectangle = bottomHint.getBounds(main.stage);
			const scale:Number = rect.width / bottomHint.width;
			const move:Number = BOTTOM_HINT_SCROLL_SPEED * scale;

			if (bottomHintScrollWaitFrames < main.stage.frameRate)
			{
				bottomHintScrollWaitFrames++;
				return true;
			}

			if (bottomHintScrollToLeft)
			{
				if (rect.right > main.stage.stageWidth)
				{
					bottomHint.x -= move;
				}
				else
				{
					bottomHintScrollToLeft = false;
					bottomHintScrollWaitFrames = 0;
				}
			}
			else
			{
				if (rect.left < 0)
				{
					bottomHint.x += move;
				}
				else
				{
					bottomHintScrollToLeft = true;
					bottomHintScrollWaitFrames = 0;
				}
			}

			return true;
		}

		private static function startBottomHintScrolling():void
		{
			resetBottomHintScrolling();

			FOFOTimer.remove(BOTTOM_HINT_SCROLL_TIMER);
			FOFOTimer.addByName(
					BOTTOM_HINT_SCROLL_TIMER,
					0.0,
					true,
					animateBottomHintScrolling
				);
		}

		private static function stopBottomHintScrolling():void
		{
			FOFOTimer.remove(BOTTOM_HINT_SCROLL_TIMER);
			resetBottomHintScrolling();
		}

		public static function showTopbarOnReplayEnd():void
		{
			if (topBar.visible === false)
			{

				topBar.visible = true;
				ReplayController.seekBarBox.y = ReplayController.lastReplayTimeBoxYPos;
				ReplayController.seekBarBox.setPlayButtonVisible(true);
				ReplayController.seekBarBox.showReplayControlButton();
				hideBottomHint();
				hideMouseHint();

			}
		}
	}
}
