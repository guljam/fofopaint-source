package Modules.ReplayEngine
{
    import Modules.MouseState;
    import Modules.UIEngine.UIController;
    import Modules.UIEngine.UITheme;
    import Modules.UndoController;
    import Modules.Utils;

    import flash.display.Stage;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.getTimer;

    // 리플레이 캔버스를 옮겨서 곧 그려질 영역(연출 중이면 연출 영역, 아니면 커서)을 화면 안에 두는 카메라 (ReplayDrawer.cursorFollow)
    // 앵커를 한 번에 옮기지 않고 목표만 정한 뒤 별도 타이머에서 실제 시간 기준으로 감쇠하며 따라감
    // 화면 상태(창 크기, 캔버스 경계, 줌, 회전)는 캐시하지 않고 계산할 때마다 읽음
    public class ReplayCursorFollow
    {
        private static const CAMERA_TIMER_NAME:String = "replayCameraTimer";
        private static const CAMERA_TAU_MS:Number = 300; // 감쇠 시간. 클수록 느긋하게 따라감
        private static const DEAD_ZONE_INSET:Number = 0.2; // 화면 각 변에서 이 비율만큼 안쪽까지가 데드존 바깥 (가운데 60%가 데드존)
        private static const SAFETY_PADDING:Number = 20; // 커서가 화면 가장자리에서 이보다 가까우면 감쇠 없이 바로 따라감
        private static const EDGE_MARGIN:Number = 20; // 화면보다 큰 캔버스의 가장자리가 화면 안으로 들어올 수 있는 최대 px
        private static const MAX_DT_MS:Number = 100; // 한 틱 dt 상한 (멈췄다 재개할 때 튀지 않게)
        private static const SETTLED_DIST:Number = 0.5; // 목표와 이 거리 미만이면 도착한 것으로 봄

        // 감쇠 중인 앵커 위치와 목표 (전역 좌표, 소수 유지. 앵커에 넣을 때만 반올림)
        private var posX:Number = 0;
        private var posY:Number = 0;
        private var targetX:Number = 0;
        private var targetY:Number = 0;
        private var lastStepTime:int = 0;

        // 화면에서 캔버스를 보여주는 영역. 위쪽은 상단바(+시크바가 겹치는 띠) 아래, 시크바는 위쪽에 붙어 있어 아래쪽은 스테이지 끝까지
        private function viewportRect():Rectangle
        {
            const top:Number = UIController.topBar.BARSIZE * UITheme.getUIScale();
            const stage:Stage = ReplayController.main.stage;
            return new Rectangle(0, top, stage.stageWidth, stage.stageHeight - top);
        }

        // 카메라가 앵커를 건드리면 안 되는 상태
        private function isBlocked():Boolean
        {
            return ReplayState.isReplayCanvasFitToWindow || MouseState.isLeftDown || UndoController.isDeepUndoEnabled;
        }

        // 외부가 화면을 바꿨을 때 부름. 카메라 내부 값을 실제 앵커로 다시 맞추고 진행 중인 이동을 멈춤
        public function updateBounds():void
        {
            syncToAnchor();
            stopTimer();
        }

        // 재생 중 그리기 바로 뒤에 한 번 부름 (replayDrawTimer). 그리기 타이머가 갱신하므로 카메라 타이머와 두 번 움직이지 않음
        // 슬라이드쇼는 감쇠 없이 바로 맞춤
        public function update():void
        {
            if (!ReplayState.isReplayStarted)
            {
                return;
            }

            if (ReplayState.isReplaySlideShowMode)
            {
                snap();
                return;
            }

            step();
        }

        // 재생이 멈췄을 때 부름. 목표에 도착하지 않았으면 카메라 타이머로 남은 이동을 마무리함
        public function finishMove():void
        {
            if (!isBlocked() && !isSettled())
            {
                startTimer();
            }
        }

        // 목표를 계산하고 앵커를 바로 그 위치로 옮김 (탐색, 슬라이드쇼)
        public function snap():void
        {
            stopTimer();
            syncToAnchor();
            const cursor:Point = ReplayDrawCommands.getRCursorPos();
            const view:Rectangle = viewportRect();
            const canvas:Rectangle = canvasScreenRect();
            const focus:Rectangle = focusScreenRect(cursor);
            posX += targetShift(true, focus, view, canvas);
            posY += targetShift(false, focus, view, canvas);
            targetX = posX;
            targetY = posY;
            applyToAnchor();
        }

        // 재생이 멈춘 뒤 남은 이동을 마무리하는 타이머 콜백. 재생 중에는 update가 움직이므로 아무것도 하지 않고 꺼짐
        private function tick():Boolean
        {
            if (ReplayState.isReplayStarted)
            {
                return false;
            }

            if (!ReplayState.isReplayModeON || isBlocked())
            {
                syncToAnchor();
                return false;
            }

            step();
            return !isSettled();
        }

        // 목표 재계산 → 안전 구역 → 감쇠 → 앵커 적용. update와 tick이 같이 씀
        private function step():void
        {
            if (isBlocked())
            {
                syncToAnchor();
                return;
            }

            // 소수 위치는 앵커가 외부에서 옮겨졌을 때만 버림 (매번 맞추면 작은 이동분이 반올림에 지워짐)
            if (Math.round(posX) !== ReplayDrawer.rCanvasAnchorPoint.x || Math.round(posY) !== ReplayDrawer.rCanvasAnchorPoint.y)
            {
                syncToAnchor();
            }

            retarget();
            keepCursorInSafeZone();
            const now:int = getTimer();
            const dt:Number = Math.min(Math.max(0, now - lastStepTime), MAX_DT_MS);
            lastStepTime = now;
            const k:Number = 1 - Math.exp(-dt / CAMERA_TAU_MS);
            posX += (targetX - posX) * k;
            posY += (targetY - posY) * k;

            if (isSettled())
            {
                posX = targetX;
                posY = targetY;
            }

            applyToAnchor();
        }

        // 지금 화면 상태와 초점으로 목표를 다시 계산함 (현재 앵커 기준으로 필요한 이동량만큼)
        private function retarget():void
        {
            const cursor:Point = ReplayDrawCommands.getRCursorPos();
            const view:Rectangle = viewportRect();
            const canvas:Rectangle = canvasScreenRect();
            const focus:Rectangle = focusScreenRect(cursor);
            targetX = ReplayDrawer.rCanvasAnchorPoint.x + targetShift(true, focus, view, canvas);
            targetY = ReplayDrawer.rCanvasAnchorPoint.y + targetShift(false, focus, view, canvas);
        }

        // 커서를 놓치지 않게 안전 구역 밖이면 그 축은 가장자리에 오는 위치까지 즉시 옮김 (목표를 넘지는 않음)
        private function keepCursorInSafeZone():void
        {
            const cursor:Point = ReplayDrawCommands.getRCursorPos();
            const cursorScreen:Point = canvasToScreen(cursor.x, cursor.y);
            const view:Rectangle = viewportRect();
            const sx:Number = safetyShift(cursorScreen.x, view.left + SAFETY_PADDING, view.right - SAFETY_PADDING, targetX - posX);
            const sy:Number = safetyShift(cursorScreen.y, view.top + SAFETY_PADDING, view.bottom - SAFETY_PADDING, targetY - posY);

            if (sx !== 0 || sy !== 0)
            {
                posX += sx;
                posY += sy;
                applyToAnchor();
            }
        }

        private function startTimer():void
        {
            if (!FOFOTimer.hasTimer(CAMERA_TIMER_NAME))
            {
                lastStepTime = getTimer();
                FOFOTimer.addByName(CAMERA_TIMER_NAME, 0.0, true, tick);
            }
        }

        private function stopTimer():void
        {
            FOFOTimer.remove(CAMERA_TIMER_NAME);
        }

        private function syncToAnchor():void
        {
            posX = ReplayDrawer.rCanvasAnchorPoint.x;
            posY = ReplayDrawer.rCanvasAnchorPoint.y;
            targetX = posX;
            targetY = posY;
        }

        private function applyToAnchor():void
        {
            ReplayDrawer.rCanvasAnchorPoint.x = Math.round(posX);
            ReplayDrawer.rCanvasAnchorPoint.y = Math.round(posY);
        }

        private function isSettled():Boolean
        {
            return Math.abs(targetX - posX) < SETTLED_DIST && Math.abs(targetY - posY) < SETTLED_DIST;
        }

        // 캔버스 좌표를 지금 앵커 기준 화면 좌표로 바꿈 (회전, 줌 반영)
        private function canvasToScreen(x:Number, y:Number):Point
        {
            const gp:Point = ReplayDrawer.rCanvasLayer1Bitmap.localToGlobal(new Point(0, 0));
            const rg:Point = Utils.rotatePoint(x, y, -ReplayDrawer.rCanvasAnchorPoint.rotation);
            const zoom:Number = ReplayState.rCanvasZoomMultiplier;
            return new Point(gp.x + rg.x * zoom, gp.y + rg.y * zoom);
        }

        // 회전을 반영한 캔버스의 화면 경계
        private function canvasScreenRect():Rectangle
        {
            const b:Object = Utils.getBoundRect(ReplayDrawer.rCanvasLayer1Bitmap);
            return new Rectangle(b.left, b.top, b.right - b.left, b.bottom - b.top);
        }

        // 카메라가 따라갈 초점의 화면 사각형: 연출 영역이 있으면 그 영역, 없으면 커서 한 점
        private function focusScreenRect(cursor:Point):Rectangle
        {
            const area:Rectangle = ReplayDrawer.anim.focusRect;

            if (area === null)
            {
                const p:Point = canvasToScreen(cursor.x, cursor.y);
                return new Rectangle(p.x, p.y, 0, 0);
            }

            const corners:Array = [canvasToScreen(area.left, area.top), canvasToScreen(area.right, area.top), canvasToScreen(area.left, area.bottom), canvasToScreen(area.right, area.bottom)];
            var minX:Number = corners[0].x;
            var maxX:Number = minX;
            var minY:Number = corners[0].y;
            var maxY:Number = minY;

            for each (var c:Point in corners)
            {
                minX = Math.min(minX, c.x);
                maxX = Math.max(maxX, c.x);
                minY = Math.min(minY, c.y);
                maxY = Math.max(maxY, c.y);
            }

            return new Rectangle(minX, minY, maxX - minX, maxY - minY);
        }

        // 한 축에서 앵커를 옮길 양: 초점을 데드존 안에 두고, 캔버스 경계 규칙으로 자름
        private function targetShift(isX:Boolean, focus:Rectangle, view:Rectangle, canvas:Rectangle):Number
        {
            const viewLo:Number = isX ? view.left : view.top;
            const viewHi:Number = isX ? view.right : view.bottom;
            const canvasLo:Number = isX ? canvas.left : canvas.top;
            const canvasHi:Number = isX ? canvas.right : canvas.bottom;
            const focusLo:Number = isX ? focus.left : focus.top;
            const focusHi:Number = isX ? focus.right : focus.bottom;

            // 화면보다 작은 캔버스는 중심을 화면 중심에 맞춤
            if (canvasHi - canvasLo <= viewHi - viewLo)
            {
                return (viewLo + viewHi) / 2 - (canvasLo + canvasHi) / 2;
            }

            const inset:Number = (viewHi - viewLo) * DEAD_ZONE_INSET;
            const zoneLo:Number = viewLo + inset;
            const zoneHi:Number = viewHi - inset;
            var shift:Number = 0;

            if (focusHi - focusLo >= zoneHi - zoneLo)
            {
                shift = (viewLo + viewHi) / 2 - (focusLo + focusHi) / 2; // 데드존보다 큰 초점은 중심을 화면 중심에
            }
            else if (focusLo < zoneLo)
            {
                shift = zoneLo - focusLo;
            }
            else if (focusHi > zoneHi)
            {
                shift = zoneHi - focusHi;
            }

            // 캔버스 가장자리가 화면 안쪽으로 EDGE_MARGIN 넘게 들어오지 않게 자름
            return Math.max(viewHi - EDGE_MARGIN - canvasHi, Math.min(viewLo + EDGE_MARGIN - canvasLo, shift));
        }

        // 커서가 안전 구역 밖이면 가장자리에 오게 하는 이동량. 목표 이동량(targetDelta)을 넘지 않음. 안쪽이면 0
        private function safetyShift(cursor:Number, safeLo:Number, safeHi:Number, targetDelta:Number):Number
        {
            var need:Number = 0;

            if (cursor < safeLo)
            {
                need = Math.max(0, Math.min(safeLo - cursor, targetDelta));
            }
            else if (cursor > safeHi)
            {
                need = Math.min(0, Math.max(safeHi - cursor, targetDelta));
            }

            return need;
        }
    }
}
