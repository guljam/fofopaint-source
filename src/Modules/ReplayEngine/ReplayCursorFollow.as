package Modules.ReplayEngine
{
    import Modules.UIEngine.UIController;
    import Modules.UIEngine.UITheme;
    import Modules.Utils;

    import flash.geom.Point;

    // 리플레이 커서가 창 밖으로 나가지 않게 리플레이 캔버스를 옮겨줌 (ReplayDrawer.cursorFollow)
    public class ReplayCursorFollow
    {
        private static const PADDING:Number = 20;

        private const cursorPos:Point = new Point(0, 0);
        private const windowCenterPos:Point = new Point(0, 0); // 캔버스 중점위치, 창 중점위치 사이 거리
        private var stw:Number;
        private var sth:Number; // 프레임 탐색막대 길이 빼줌]
        private var left:Number; // 바운드 상하좌우
        private var right:Number;
        private var top:Number;
        private var bottom:Number;
        private var zoom:Number = 1.0;
        // rcanvas1 글로벌 좌표에 회전된 캔버스에서 커서 위치를 더해줌. 즉 윈도우 기준에서 커서 커서 위치를 구하는거임
        private var isCanvasWidthSmallerStage:Boolean; // 캔버스 가로 새로 길이가 스테이지 길이보다 클때 체크
        private var isCanvasHeightSmallerStage:Boolean;
        private var isNotCenterX:Boolean; // 캔버스 중점위치, 창 중점위치 사이 거리
        private var isNotCenterY:Boolean;
        private const leftLimit:Number = PADDING;
        private var topLimit:Number; // topBar가 만들어진 뒤에 계산해야해서 updateBounds에서 구함
        private var rightLimit:Number;
        private var bottomLimit:Number;

        public function updateBounds():void
        {
            const bounds:Object = Utils.getBoundRect(ReplayDrawer.rCanvasLayer1Bitmap); // 바운드 저장하는 객체
            const scale:Number = UITheme.getUIScale();
            left = bounds.left;
            right = bounds.right;
            top = bounds.top;
            bottom = bounds.bottom;
            stw = ReplayController.main.stage.stageWidth;
            sth = ReplayController.main.stage.stageHeight - (UIController.topBar.BARSIZE) * scale;
            zoom = ReplayState.rCanvasZoomMultiplier;
            isCanvasWidthSmallerStage = right - left < stw;
            isCanvasHeightSmallerStage = bottom - top < sth;
            // 캔버스 중점위치, 창 중점위치 사이 거리
            windowCenterPos.setTo(Math.floor(stw / 2 - (right + left) / 2), Math.floor((UIController.topBar.BARSIZE) * scale + sth / 2 - (bottom + top) / 2));
            isNotCenterX = Math.abs(windowCenterPos.x) > 0; // 캔버스 중점위치, 창 중점위치 사이 거리
            isNotCenterY = Math.abs(windowCenterPos.y) > 0;
            topLimit = PADDING + UIController.topBar.BARSIZE;
            rightLimit = stw - PADDING;
            bottomLimit = sth + UIController.topBar.BARSIZE - PADDING;
        }

        public function check(viewCenterFlag:Boolean):void
        {
            const cp:Point = ReplayDrawCommands.getRCursorPos(); // 커서 좌표
            var gp:Point; // 캔버스 글로벌 좌표
            var rg:Point; // 캔버스 회전된 글로벌 좌표
            var globalChecked:Boolean = false;
            const div:Number = (viewCenterFlag) ? 1 : 3;

            if (isCanvasWidthSmallerStage)
            {
                if (isNotCenterX)
                {
                    ReplayDrawer.rCanvasAnchorPoint.x += windowCenterPos.x;
                    updateBounds();
                }
            }
            else
            {
                globalChecked = true;
                gp = ReplayDrawer.rCanvasLayer1Bitmap.localToGlobal(new Point(0, 0));
                rg = Utils.rotatePoint(cp.x, cp.y, -ReplayDrawer.rCanvasAnchorPoint.rotation);
                cursorPos.x = gp.x + (rg.x * zoom);

                if (cursorPos.x < leftLimit)
                {
                    ReplayDrawer.rCanvasAnchorPoint.x += Math.floor(Math.abs((cursorPos.x - stw / 2) / div));
                    updateBounds();
                }
                else if (cursorPos.x > rightLimit)
                {
                    ReplayDrawer.rCanvasAnchorPoint.x -= Math.floor(Math.abs((cursorPos.x - stw / 2) / div));
                    updateBounds();
                }
            }

            if (isCanvasHeightSmallerStage)
            {
                if (isNotCenterY)
                {
                    ReplayDrawer.rCanvasAnchorPoint.y += windowCenterPos.y;
                    updateBounds();
                }
            }
            else
            {
                if (globalChecked === false)
                {
                    globalChecked = true;
                    gp = ReplayDrawer.rCanvasLayer1Bitmap.localToGlobal(new Point(0, 0));
                    rg = Utils.rotatePoint(cp.x, cp.y, -ReplayDrawer.rCanvasAnchorPoint.rotation);
                }

                cursorPos.y = gp.y + (rg.y * zoom);

                if (cursorPos.y < topLimit)
                {
                    ReplayDrawer.rCanvasAnchorPoint.y += Math.floor(Math.abs((cursorPos.y - sth / 2) / div));
                    updateBounds();
                }
                else if (cursorPos.y > bottomLimit)
                {
                    ReplayDrawer.rCanvasAnchorPoint.y -= Math.floor(Math.abs((cursorPos.y - sth / 2) / div));
                    updateBounds();
                }
            }
        }
    }
}
