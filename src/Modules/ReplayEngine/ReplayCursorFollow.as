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

        // 자동 줌 (2단계)
        private static const AUTO_FIT_SPEED_IN:Number = 8; // 이 배속 이상이면 줌아웃
        private static const AUTO_FIT_SPEED_OUT:Number = 5; // 이 배속 미만이어야 복원 후보 (들어가는 값보다 낮게 둬서 경계에서 흔들리지 않게 함)
        private static const RETURN_DWELL_MS:Number = 2500; // 복원 조건이 이만큼 이어져야 복원
        private static const ZOOM_OUT_TAU_MS:Number = 200; // 줌아웃 감쇠 시간 (빠르게)
        private static const ZOOM_IN_TAU_MS:Number = 600; // 복원 감쇠 시간 (느리게)
        private static const RETURN_ZOOM_RATIO:Number = 1.0; // 복원 배율 = 사용자 줌 * 이 값
        private static const FIT_MARGIN:Number = 20; // 맞춤 배율에서 화면 가장자리에 남기는 여백 px
        private static const BIG_ANIM_RATIO:Number = 0.9; // 연출 영역이 사용자 줌에서 화면의 이 비율보다 크면 줌아웃
        private static const ZOOM_SETTLED_LOG:Number = 0.002; // 로그 배율 차이가 이 값 미만이면 도착

        private static const ZOOM_FOLLOW:int = 0; // 사용자 줌
        private static const ZOOM_TO_FIT:int = 1; // 줌아웃 중
        private static const ZOOM_FIT:int = 2; // 맞춤 배율 유지
        private static const ZOOM_TO_USER:int = 3; // 복원 중

        // 감쇠 중인 앵커 위치와 목표 (전역 좌표, 소수 유지. 앵커에 넣을 때만 반올림)
        private var posX:Number = 0;
        private var posY:Number = 0;
        private var targetX:Number = 0;
        private var targetY:Number = 0;
        private var lastStepTime:int = 0;

        // 자동 줌 상태. userZoom은 사용자가 정한 배율이고 외부가 배율을 바꿨을 때만 갱신됨 (자동 줌은 rCanvasZoomIndex 등 사용자 줌 값을 건드리지 않음)
        private var zoomState:int = ZOOM_FOLLOW;
        private var userZoom:Number = NaN;
        private var curZoom:Number = NaN; // 카메라가 마지막으로 적용한 배율. 실제 배율과 다르면 외부가 바꾼 것
        private var zoomMoving:Boolean = false; // FIT 중 창 크기가 바뀌어 맞춤 배율을 다시 따라가는 중
        private var calmSince:int = -1; // 복원 조건이 이어지기 시작한 시각, 아니면 -1

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
            detectExternalZoom();
            stopTimer();
        }

        // 재생 중 그리기 바로 뒤에 한 번 부름 (replayDrawTimer). 그리기 타이머가 갱신하므로 카메라 타이머와 두 번 움직이지 않음
        // 슬라이드쇼도 같은 감쇠를 거침 (즉시 맞추는 snap은 탐색 경로에서만 씀)
        public function update():void
        {
            if (ReplayState.isReplayStarted)
            {
                step();
            }
        }

        // 재생이 멈췄을 때 부름. 목표에 도착하지 않았으면 카메라 타이머로 남은 이동을 마무리함
        public function finishMove():void
        {
            if (!isBlocked() && (!isSettled() || isZooming()))
            {
                startTimer();
            }
        }

        // 목표를 계산하고 앵커를 바로 그 위치로 옮김 (탐색, 슬라이드쇼 정지 후)
        public function snap():void
        {
            stopTimer();
            syncToAnchor();
            stepZoom(ReplayState.isReplayStarted, true);
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
            return !isSettled() || isZooming();
        }

        // 줌 → 목표 재계산 → 안전 구역 → 감쇠 → 앵커 적용. update와 tick이 같이 씀
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

            const now:int = getTimer();
            const dt:Number = Math.min(Math.max(0, now - lastStepTime), MAX_DT_MS);
            lastStepTime = now;
            stepZoom(ReplayState.isReplayStarted, false, dt);
            retarget();
            keepCursorInSafeZone();
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

        // ---- 자동 줌 ----

        private function isZooming():Boolean
        {
            return zoomState === ZOOM_TO_FIT || zoomState === ZOOM_TO_USER || zoomMoving;
        }

        // 카메라가 적용하지 않은 배율 변화(사용자 줌, 창 맞춤, 재생 끝 복원 등)면 그 값을 사용자 줌으로 받아들이고 자동 줌을 풀음
        private function detectExternalZoom():void
        {
            const actual:Number = ReplayState.rCanvasZoomMultiplier;

            if (isNaN(curZoom) || Math.abs(actual - curZoom) > 1e-9)
            {
                curZoom = actual;
                userZoom = actual;
                zoomState = ZOOM_FOLLOW;
                calmSince = -1;
            }
        }

        // 지금 회전과 창 크기에서 캔버스 전체가 화면에 들어가는 배율 (연속값, 순수 계산)
        private function fitZoom(view:Rectangle):Number
        {
            const rad:Number = ReplayDrawer.rCanvasAnchorPoint.rotation * Math.PI / 180;
            const cos:Number = Math.abs(Math.cos(rad));
            const sin:Number = Math.abs(Math.sin(rad));
            const w:Number = ReplayState.RCANVAS_WIDTH;
            const h:Number = ReplayState.RCANVAS_HEIGHT;
            const boxW:Number = w * cos + h * sin;
            const boxH:Number = w * sin + h * cos;
            return Math.min((view.width - FIT_MARGIN * 2) / boxW, (view.height - FIT_MARGIN * 2) / boxH);
        }

        // 연출 영역이 사용자 줌에서 화면의 BIG_ANIM_RATIO보다 큰지
        private function isBigAnim(view:Rectangle):Boolean
        {
            const area:Rectangle = ReplayDrawer.anim.focusRect;

            if (area === null)
            {
                return false;
            }

            const rad:Number = ReplayDrawer.rCanvasAnchorPoint.rotation * Math.PI / 180;
            const cos:Number = Math.abs(Math.cos(rad));
            const sin:Number = Math.abs(Math.sin(rad));
            const w:Number = (area.width * cos + area.height * sin) * userZoom;
            const h:Number = (area.width * sin + area.height * cos) * userZoom;
            return w > view.width * BIG_ANIM_RATIO || h > view.height * BIG_ANIM_RATIO;
        }

        // 상태를 정하고(재생 중일 때만) 배율을 목표로 감쇠시킴. instant면 전환을 바로 끝냄
        private function stepZoom(playing:Boolean, instant:Boolean, dt:Number = 0):void
        {
            detectExternalZoom();
            const view:Rectangle = viewportRect();
            const fit:Number = Math.min(fitZoom(view), userZoom);

            if (playing)
            {
                const busy:Boolean = ReplayState.rReplaySpeedMultipler >= AUTO_FIT_SPEED_IN || ReplayState.isReplaySlideShowMode || isBigAnim(view);

                if (zoomState === ZOOM_FOLLOW)
                {
                    if (busy)
                    {
                        zoomState = ZOOM_TO_FIT;
                    }
                }
                else if (busy)
                {
                    calmSince = -1;

                    if (zoomState === ZOOM_TO_USER)
                    {
                        zoomState = ZOOM_TO_FIT;
                    }
                }
                else
                {
                    // 들어가는 기준보다 낮은 기준(OUT)이 DWELL 동안 이어져야 복원, 중간에 기준을 벗어나면 처음부터 다시 셈
                    const calm:Boolean = ReplayState.rReplaySpeedMultipler < AUTO_FIT_SPEED_OUT && !isBigAnim(view);
                    const now:int = getTimer();

                    if (!calm)
                    {
                        calmSince = -1;
                    }
                    else if (calmSince < 0)
                    {
                        calmSince = now;
                    }
                    else if (now - calmSince >= RETURN_DWELL_MS && zoomState !== ZOOM_TO_USER)
                    {
                        zoomState = ZOOM_TO_USER;
                    }
                }
            }

            if (zoomState === ZOOM_FOLLOW)
            {
                return;
            }

            const target:Number = (zoomState === ZOOM_TO_USER) ? userZoom * RETURN_ZOOM_RATIO : fit;
            const logDiff:Number = Math.log(target) - Math.log(curZoom);

            if (instant || Math.abs(logDiff) < ZOOM_SETTLED_LOG)
            {
                const wasMoving:Boolean = isZooming();
                applyZoom(target);
                zoomState = (zoomState === ZOOM_TO_USER) ? ZOOM_FOLLOW : ZOOM_FIT;

                if (wasMoving)
                {
                    zoomMoving = false;
                    finishZoom();
                }

                return;
            }

            zoomMoving = true;

            const tau:Number = (logDiff < 0) ? ZOOM_OUT_TAU_MS : ZOOM_IN_TAU_MS;
            applyZoom(Math.exp(Math.log(curZoom) + logDiff * (1 - Math.exp(-dt / tau))));
        }

        // 초점(연출 영역 중심 또는 커서)의 화면 위치가 변하지 않게 배율을 바꾸고 앵커를 보정함
        // 매 프레임 배율이 바뀌는 중이라 에어브러시 블러와 정보 상자 갱신은 하지 않음 (finishZoom에서 한 번만)
        private function applyZoom(z:Number):void
        {
            if (z === curZoom)
            {
                return;
            }

            const cursor:Point = ReplayDrawCommands.getRCursorPos();
            const area:Rectangle = ReplayDrawer.anim.focusRect;
            const fx:Number = (area === null) ? cursor.x : area.x + area.width / 2;
            const fy:Number = (area === null) ? cursor.y : area.y + area.height / 2;
            const before:Point = canvasToScreen(fx, fy);
            ReplayState.rCanvasZoomMultiplier = z;
            ReplayDrawer.rCanvasAnchorPoint.scaleX = z;
            ReplayDrawer.rCanvasAnchorPoint.scaleY = z;
            ReplayDrawer.updateReplayCursorScale(z);
            const after:Point = canvasToScreen(fx, fy);
            posX = ReplayDrawer.rCanvasAnchorPoint.x + before.x - after.x;
            posY = ReplayDrawer.rCanvasAnchorPoint.y + before.y - after.y;
            applyToAnchor();
            curZoom = z;

            // 배율이 커지면서 큰 캔버스의 가장자리가 화면 안쪽으로 들어왔으면 바로 되돌림 (이동 감쇠를 기다리면 그 사이 경계를 넘음)
            const view:Rectangle = viewportRect();
            const canvas:Rectangle = canvasScreenRect();
            posX += (canvas.width > view.width) ? Math.max(view.right - EDGE_MARGIN - canvas.right, Math.min(view.left + EDGE_MARGIN - canvas.left, 0)) : 0;
            posY += (canvas.height > view.height) ? Math.max(view.bottom - EDGE_MARGIN - canvas.bottom, Math.min(view.top + EDGE_MARGIN - canvas.top, 0)) : 0;
            targetX = posX;
            targetY = posY;
            applyToAnchor();
        }

        // 전환이 끝났을 때 한 번만 하는 갱신
        private function finishZoom():void
        {
            if (ReplayState.rAirBrushSize > 0)
            {
                ReplayDrawer.blurReplayCanvasByValue(ReplayState.rAirBrushSize);
            }

            UIController.canvasInfoBox.setZoom(curZoom);
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
