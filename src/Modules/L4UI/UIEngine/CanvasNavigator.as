package Modules.L4UI.UIEngine
{
    import Symbols.CanvasNavigatorBoxSet;

    import flash.display.DisplayObject;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import Modules.L4UI.SidebarController;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L4UI.UIEngine.HintController;
    import Modules.L2Engine.DrawEngine.CanvasView;
    import Modules.L2Engine.DrawEngine.DrawCanvas;
    import Modules.L1Data.MouseState;
    import Modules.L1Data.Utils;
    import Modules.L4UI.Tools.LassoTool;
    import Modules.L4UI.ReferenceLayerController;
    import Modules.L1Data.InputPriority;
    import Modules.L1Data.UIEngine.UITheme;

    // 사이드바의 캔버스 미리보기(네비게이터): 보이는 영역 커서 갱신, 클릭/드래그로 캔버스 이동
    // 층: L4 UI - 사이드바 캔버스 미리보기(네비게이터)와 클릭·드래그 이동
    public class CanvasNavigator
    {
        public static var main:Main;
        public static function setMainInstance(instance:Main):void
        {
            main = instance;
        }

        public static const box:CanvasNavigatorBoxSet = new CanvasNavigatorBoxSet();

        // 네비게이터로 캔버스 이동 이벤트 한번만 올려주기
        private static var canvasMoveEventStarted:Boolean = false;

        public static function isNavigatorChild(target:DisplayObject):Boolean
        {
            const targetName:String = target.name;
            return (targetName === "navStageBG"
                    || targetName === "navBitmapBG"
                    || targetName === "navLayer1Bitmap"
                    || targetName === "navLayer2Bitmap"
                    || targetName === "navCursor");
        }

        // 지금 창에서 보이는 캔버스 영역을 네비게이터 커서로 표시
        public static function updateCursor():void
        {
            var newRightOffset:Number = 0;
            var newLeftOffset:Number = 0;

            if (SidebarController.isSidebarVisible === true)
            {
                newRightOffset = UIController.STAGE_RIGHT_OFFSET;
                newLeftOffset = UIController.STAGE_LEFT_OFFSET;

                if (SidebarController.isRightSidebar)
                {
                    newRightOffset = Math.round(SidebarController.sideBar.getWidth());
                }
                else
                {
                    newLeftOffset = Math.round(SidebarController.sideBar.getWidth());
                }
            }

            const gp:Point = DrawCanvas.canvasLayer1Bitmap.globalToLocal(new Point(newLeftOffset, UIController.STAGE_TOP_OFFSET));
            const zoom:Number = CanvasView.canvasZoomMultiplier;
            box.updateCursor(gp.x * zoom, gp.y * zoom
                    , main.stage.stageWidth - newRightOffset - newLeftOffset
                    , main.stage.stageHeight - UIController.STAGE_TOP_OFFSET - UIController.STAGE_BOTTOM_OFFSET
                    , DrawCanvas.CANVAS_WIDTH * zoom, CanvasView.canvasAnchorPoint.rotation);
        }

        public static function startCanvasMove(navCursorClicked:Boolean):void
        {
            var sx:Number = box.mouseX;
            var sy:Number = box.mouseY;
            const prevCursorScale:Number = box.navCursorMultiply;
            const uiScale:Number = UITheme.getUIScale();

            ReferenceLayerController.setRefLayerAndGridVisible(false);
            HintController.hideBottomHint();

            function centerCanvas(mx:Number, my:Number):void
            {
                const b:Object = Utils.getBoundRect(box.navCursor);
                const scale:Number = UITheme.getUIScale();
                // prevToCanvasMultiply를 나눠 줘야 커서랑 같은 속도가 나옴
                const rectCenterX:Number = b.left + (b.right - b.left) / 2;
                const rectCenterY:Number = b.top + (b.bottom - b.top) / 2;
                var moveX:Number = (rectCenterX - mx) / prevCursorScale / uiScale;
                var moveY:Number = (rectCenterY - my) / prevCursorScale / uiScale;
                var p:Point = Utils.rotatePoint(moveX, moveY, -CanvasView.canvasAnchorPoint.rotation);
                CanvasView.canvasAnchorPoint.x += Math.round(p.x);
                CanvasView.canvasAnchorPoint.y += Math.round(p.y);
                updateCursor();
            }

            function onMouseUpCanvasNavigator(e:MouseEvent):void
            {
                MouseState.endDrag("canvasNavigator");
                ReferenceLayerController.setRefLayerAndGridVisible(true);
                CanvasView.viewport.keepInStage();
                updateCursor();
                if (LassoTool.isStarted)
                {
                    if (LassoTool.isLassoMenuHiddenTemp === true)
                    {
                        LassoTool.showLassoMenuBox();
                    }
                }
                main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveCanvasNavigator);
                main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpCanvasNavigator);
                canvasMoveEventStarted = false;
            }

            function onMouseMoveCanvasNavigator(e:MouseEvent):void
            {
                const scale:Number = UITheme.getUIScale();
                var mx:Number = box.mouseX;
                var my:Number = box.mouseY;
                // previewBox.prevCursorMultiply를 곱해줘야 커서랑 같은 속도가 나옴
                var moveX:Number = (sx - mx) / prevCursorScale;
                var moveY:Number = (sy - my) / prevCursorScale;
                var p:Point = Utils.rotatePoint(moveX, moveY, -CanvasView.canvasAnchorPoint.rotation);
                CanvasView.canvasAnchorPoint.x += Math.round(p.x);
                CanvasView.canvasAnchorPoint.y += Math.round(p.y);
                sx = mx;
                sy = my;
                updateCursor();
            }
            CanvasView.viewport.moveAnchorPoint(0, 0);
            if (LassoTool.isStarted)
            {
                LassoTool._lassoMenuBox.visible = false;
                LassoTool.isLassoMenuHiddenTemp = true;
            }
            // 클릭한 지점이 커서 바깥부분일때 강제로 캔버스 중심으로 옮겨줌
            if (!navCursorClicked)
            {
                centerCanvas(main.stage.mouseX, main.stage.mouseY);
            }

            if (canvasMoveEventStarted === false)
            {
                canvasMoveEventStarted = true;
                main.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpCanvasNavigator, false, InputPriority.DEFAULT);
                main.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveCanvasNavigator);
                MouseState.beginDrag("canvasNavigator", function ():void
                    {
                        onMouseUpCanvasNavigator(null);
                    });
            }
        }
    }
}
