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

        // 미리 읽은 커서 경로로 영역을 추적 (3단계)
        private static const EXCURSION_IGNORE_MS:Number = 800; // 데드존 밖으로 나가 있던 시간이 이보다 짧으면 따라가지 않음 (실제 시간)
        private static const REGION_LOW:Number = 0.1; // 시간 가중 10~90% 구간을 영역으로 봄
        private static const REGION_HIGH:Number = 0.9;
        private static const MAX_PATH_SAMPLES:int = 600; // 계산에 쓰는 경로 점 수 상한

        private static const USER_OVERRIDE_MS:Number = 3000; // 수동 줌(휠, 키, 버튼) 뒤 이 시간 동안은 자동 줌아웃을 시작하지 않음. 위치 추적과 안전 구역은 계속 동작

        private static const REGION_CALM_RATIO:Number = 1.15; // 줌인(복원)은 영역이 이 비율만큼 여유 있게 더 큰 배율에 들어갈 때만 후보가 됨 (줌아웃 기준과 같은 값이면 경계에서 들락날락함)

        private static const ZOOM_FOLLOW:int = 0; // 사용자 줌
        private static const ZOOM_HELD:int = 1; // 줌아웃해서 zoomCommit 배율을 유지하는 중 (그 배율로 가는 중도 포함)

        // 감쇠 중인 앵커 위치와 목표 (전역 좌표, 소수 유지. 앵커에 넣을 때만 반올림)
        private var posX:Number = 0;
        private var posY:Number = 0;
        private var targetX:Number = 0;
        private var targetY:Number = 0;
        private var lastStepTime:int = 0;

        // 미리 읽은 경로로 구한 값 (매 틱 다시 계산). lookReady가 false면 커서 한 점과 배속 기준으로 되돌아감
        private var lookReady:Boolean = false;
        private var lookMiss:String = "";
        private const regionRect:Rectangle = new Rectangle(); // 캔버스 좌표, 시간 가중 10~90% 영역
        private var regionZoom:Number = NaN; // 영역이 화면에 들어가는 배율
        private var ignoringExcursion:Boolean = false; // 지금 커서가 무시하는 짧은 바깥 이동 안에 있음
        private var outsideSince:int = -1; // 커서가 데드존 밖으로 나간 시각 (getTimer), 안이면 -1
        private const pathBuf:Vector.<Number> = new Vector.<Number>();
        private const sampleT:Vector.<Number> = new Vector.<Number>(); // 샘플의 녹화 시각
        private const sampleX:Vector.<Number> = new Vector.<Number>();
        private const sampleY:Vector.<Number> = new Vector.<Number>();
        private const sampleW:Vector.<Number> = new Vector.<Number>(); // 샘플의 가중치(그 위치에 머문 녹화 시간)

        // 자동 줌 상태. userZoom은 사용자가 정한 배율이고 외부가 배율을 바꿨을 때만 갱신됨 (자동 줌은 rCanvasZoomIndex 등 사용자 줌 값을 건드리지 않음)
        private var zoomState:int = ZOOM_FOLLOW;
        private var userZoom:Number = NaN;
        private var curZoom:Number = NaN; // 카메라가 마지막으로 적용한 배율. 실제 배율과 다르면 외부가 바꾼 것
        private var zoomMoving:Boolean = false; // 배율이 zoomCommit을 향해 움직이는 중
        private var zoomCommit:Number = NaN; // 줌아웃 뒤 유지하려는 배율. 줌아웃은 바로 낮추고, 올리는 것(줌인)은 확인 시간을 거쳐서만 올림
        private var upSince:int = -1;
        private var userZoomAt:int = -1000000; // 마지막 수동 줌(카메라가 적용하지 않은 배율 변화를 감지한) 시각 // 더 큰 배율이어도 영역이 들어가는 상태가 이어지기 시작한 시각, 아니면 -1

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

            // 재생 중 수동 줌 직후 커서가 화면 밖이면 다음 그리기 틱을 기다리지 않고 바로 안전 구역으로 끌어옴 (무시 구간이면 3-3 규칙대로 안 끌어옴)
            if (detectExternalZoom() && ReplayState.isReplayStarted && !ignoringExcursion && !isBlocked())
            {
                keepCursorInSafeZone();
            }
        }

        // 이번 틱에 영역을 쓰지 못한 이유 ("": 영역 사용 중). unaligned = 탐색 직후 등으로 큐가 어긋남, fewSamples = 미리 볼 커서 지점이 3개 미만, coverage = 프레임/묶음 상한으로 목표 시간만큼 못 봄
        public function get lookMissReason():String
        {
            return lookMiss;
        }

        // 이번 틱에 미리 읽은 경로의 영역으로 줌/초점을 정했는지. false면 커서 한 점과 배속 규칙을 씀 (경로가 없거나, 상한 때문에 목표 시간만큼 못 봤을 때)
        public function get isUsingRegion():Boolean
        {
            return lookReady;
        }

        // 지금 커서가 짧은 바깥 이동(EXCURSION_IGNORE_MS 미만)으로 판단되어 따라가지 않는 중인지. 이때는 커서가 화면 밖에 있을 수 있음
        public function get isIgnoringExcursion():Boolean
        {
            return ignoringExcursion;
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

        // 목표를 계산하고 앵커와 배율을 바로 그 위치로 옮김 (탐색, 재생이 멈췄을 때). 진행 중인 줌 전환도 유지 배율로 바로 끝냄
        // 카메라가 앵커를 움직이는 곳은 재생 중 update와 이 함수뿐임 (멈춘 뒤 남은 이동을 애니메이션하는 타이머는 없음)
        public function snap():void
        {
            if (!ReplayState.isReplayModeON || isBlocked())
            {
                return;
            }

            syncToAnchor();
            computeLookahead();

            // 멈추거나 탐색한 자리에서는 무시 중이던 바깥 이동도 커서를 화면에 보여 줌
            if (lookReady && ignoringExcursion)
            {
                const cur:Point = ReplayDrawCommands.getRCursorPos();
                const l:Number = Math.min(regionRect.left, cur.x);
                const t:Number = Math.min(regionRect.top, cur.y);
                regionRect.setTo(l, t, Math.max(regionRect.right, cur.x) - l, Math.max(regionRect.bottom, cur.y) - t);
                ignoringExcursion = false;
            }

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
            keepCursorInSafeZone();
        }

        // 줌 → 목표 재계산 → 안전 구역 → 감쇠 → 앵커 적용. update가 씀
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
            computeLookahead();
            stepZoom(ReplayState.isReplayStarted, false, dt);
            retarget();

            if (!ignoringExcursion)
            {
                keepCursorInSafeZone();
            }

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

        // 커서를 놓치지 않게 안전 구역 밖이면 그 축은 가장자리에 오는 위치까지 즉시 옮김
        // 목표 이동량에 맞춰 자르지 않음 (초점이 영역이면 목표가 커서와 반대 방향일 수 있음). 대신 옮긴 뒤 그 축의 목표를 커서가 안전 구역 안에 남는 범위로 다시 자름
        // 캔버스 경계 규칙(EDGE_MARGIN)이 우선이라 경계 때문에 못 옮기는 만큼은 남음
        private function keepCursorInSafeZone():void
        {
            const cursor:Point = ReplayDrawCommands.getRCursorPos();
            const cursorScreen:Point = canvasToScreen(cursor.x, cursor.y);
            const view:Rectangle = viewportRect();
            const canvas:Rectangle = canvasScreenRect();
            const safeLeft:Number = view.left + SAFETY_PADDING;
            const safeRight:Number = view.right - SAFETY_PADDING;
            const safeTop:Number = view.top + SAFETY_PADDING;
            const safeBottom:Number = view.bottom - SAFETY_PADDING;
            var sx:Number = 0;
            var sy:Number = 0;

            if (cursorScreen.x < safeLeft || cursorScreen.x > safeRight)
            {
                sx = limitByCanvasEdge(cursorScreen.x < safeLeft ? safeLeft - cursorScreen.x : safeRight - cursorScreen.x, view.left, view.right, canvas.left, canvas.right);
            }

            if (cursorScreen.y < safeTop || cursorScreen.y > safeBottom)
            {
                sy = limitByCanvasEdge(cursorScreen.y < safeTop ? safeTop - cursorScreen.y : safeBottom - cursorScreen.y, view.top, view.bottom, canvas.top, canvas.bottom);
            }

            if (sx !== 0 || sy !== 0)
            {
                posX += sx;
                posY += sy;
                applyToAnchor();
            }

            // 옮긴 뒤(또는 이미 안쪽일 때) 남은 목표 이동이 커서를 안전 구역 밖으로 끌고 가지 않게 자름
            targetX = posX + clampDelta(targetX - posX, safeLeft - (cursorScreen.x + sx), safeRight - (cursorScreen.x + sx));
            targetY = posY + clampDelta(targetY - posY, safeTop - (cursorScreen.y + sy), safeBottom - (cursorScreen.y + sy));
        }

        // 한 축의 이동량이 캔버스 경계 규칙을 넘지 않게 자름. 캔버스가 화면보다 작으면(중앙 고정) 옮기지 않음
        private function limitByCanvasEdge(shift:Number, viewLo:Number, viewHi:Number, canvasLo:Number, canvasHi:Number):Number
        {
            if (canvasHi - canvasLo <= viewHi - viewLo)
            {
                return 0;
            }

            return Math.max(viewHi - EDGE_MARGIN - canvasHi, Math.min(viewLo + EDGE_MARGIN - canvasLo, shift));
        }

        private function clampDelta(delta:Number, lo:Number, hi:Number):Number
        {
            return (lo > hi) ? 0 : Math.max(lo, Math.min(hi, delta));
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


        // ---- 미리 읽은 경로로 영역 추적 (3단계) ----

        // 앞으로 LOOKAHEAD_REAL_MS * 배속 동안의 커서 경로에서 시간 가중 10~90% 영역을 구함
        // 데드존 밖으로 나가는 구간이 EXCURSION_IGNORE_MS보다 짧으면 그 구간은 계산에서 빼고, 지금 커서가 그 안에 있으면 안전 구역 즉시 이동도 하지 않음
        // 읽어 둔 경로가 없거나 부족하면 lookReady=false (커서 한 점 기준으로 되돌아감)
        private function computeLookahead():void
        {
            lookReady = false;
            lookMiss = "unaligned";
            ignoringExcursion = false;
            const win:ReplayCommandWindow = ReplayDrawer.commandWindow;
            const nowFrame:Number = ReplayState.rNowFrame;
            const cursor:Point = ReplayDrawCommands.getRCursorPos();
            const view:Rectangle = viewportRect();
            const gp:Point = ReplayDrawer.rCanvasLayer1Bitmap.localToGlobal(new Point(0, 0));
            const rad:Number = ReplayDrawer.rCanvasAnchorPoint.rotation * Math.PI / 180;
            const cos:Number = Math.cos(rad);
            const sin:Number = Math.sin(rad);
            const zoom:Number = ReplayState.rCanvasZoomMultiplier;
            const insetX:Number = view.width * DEAD_ZONE_INSET;
            const insetY:Number = view.height * DEAD_ZONE_INSET;
            const zoneLeft:Number = view.left + insetX;
            const zoneRight:Number = view.right - insetX;
            const zoneTop:Number = view.top + insetY;
            const zoneBottom:Number = view.bottom - insetY;

            // 지금 커서가 데드존 밖에 있던 시간 (현재 앵커 기준)
            const csx:Number = gp.x + (cursor.x * cos - cursor.y * sin) * zoom;
            const csy:Number = gp.y + (cursor.x * sin + cursor.y * cos) * zoom;
            const nowOutside:Boolean = csx < zoneLeft || csx > zoneRight || csy < zoneTop || csy > zoneBottom;

            if (!nowOutside)
            {
                outsideSince = -1;
            }
            else if (outsideSince < 0)
            {
                outsideSince = getTimer();
            }

            if (!win.isAlignedWith(ReplayState.rFileLastBytePosition) && !ReplayState.rMemoryDataReadON)
            {
                return;
            }

            const speed:Number = Math.max(1, ReplayState.rReplaySpeedMultipler);
            const spanMs:Number = ReplayCommandWindow.LOOKAHEAD_REAL_MS * speed;
            const t0:Number = ReplayClock.timeOfFrame(nowFrame);
            pathBuf.length = 0;
            win.collectCursorPath(nowFrame, nowFrame + ReplayCommandWindow.LOOKAHEAD_MAX_FRAMES, pathBuf);

            // 프레임/묶음 상한 때문에 목표 시간(span)만큼 못 봤으면 영역이 실제보다 작게 나오므로 믿지 않음 (데이터가 끝나서 못 본 경우는 믿음)
            if (!win.coveredToDataEnd && ReplayClock.timeOfFrame(Math.min(win.coveredEndFrame, ReplayState.TOTAL_FRAME)) - t0 < spanMs)
            {
                lookMiss = "coverage";
                return;
            }

            // 샘플: 지금 커서 + 앞으로 커서가 바뀌는 지점 (span 안만)
            sampleT.length = 0;
            sampleX.length = 0;
            sampleY.length = 0;
            sampleW.length = 0;
            sampleT.push(t0);
            sampleX.push(cursor.x);
            sampleY.push(cursor.y);
            var stride:int = Math.max(1, int(pathBuf.length / 3 / MAX_PATH_SAMPLES));

            for (var i:int = 0;i < pathBuf.length;i += 3 * stride)
            {
                const t:Number = ReplayClock.timeOfFrame(pathBuf[i]);

                if (t - t0 > spanMs)
                {
                    break;
                }

                sampleT.push(Math.max(t, sampleT[sampleT.length - 1]));
                sampleX.push(pathBuf[i + 1]);
                sampleY.push(pathBuf[i + 2]);
            }

            const n:int = sampleT.length;

            if (n < 3)
            {
                lookMiss = "fewSamples";
                return; // 미리 볼 데이터가 부족함
            }

            // 가중치 = 그 위치에 머문 녹화 시간 (마지막 샘플은 span 끝까지, 데이터가 모자라면 아주 짧게)
            const endT:Number = Math.min(t0 + spanMs, sampleT[n - 1] + 1);

            for (i = 0;i < n;i++)
            {
                sampleW.push((i + 1 < n ? sampleT[i + 1] : endT) - sampleT[i]);
            }

            // 데드존 밖 연속 구간의 실제 시간이 EXCURSION_IGNORE_MS보다 짧으면 제외 (구간이 span 끝까지 이어지면 끝을 알 수 없어 제외하지 않음)
            var runStart:int = -1;

            for (i = 0;i <= n;i++)
            {
                var outside:Boolean = false;

                if (i < n)
                {
                    const sx:Number = gp.x + (sampleX[i] * cos - sampleY[i] * sin) * zoom;
                    const sy:Number = gp.y + (sampleX[i] * sin + sampleY[i] * cos) * zoom;
                    outside = sx < zoneLeft || sx > zoneRight || sy < zoneTop || sy > zoneBottom;
                }

                if (outside && runStart < 0)
                {
                    runStart = i;
                }
                else if (!outside && runStart >= 0)
                {
                    var runMs:Number = 0;

                    for (var j:int = runStart;j < i;j++)
                    {
                        runMs += sampleW[j];
                    }

                    var realMs:Number = runMs / speed + ((runStart === 0 && outsideSince >= 0) ? (getTimer() - outsideSince) : 0);
                    const touchesEnd:Boolean = (i === n);

                    if (!touchesEnd && realMs < EXCURSION_IGNORE_MS)
                    {
                        for (j = runStart;j < i;j++)
                        {
                            sampleW[j] = 0;
                        }

                        if (runStart === 0)
                        {
                            ignoringExcursion = true;
                        }
                    }

                    runStart = -1;
                }
            }

            // 가중 중앙값 구간: x, y 각각 시간 가중 10%~90% 위치를 영역으로 함 (중앙값은 이 구간 안에 있음)
            var total:Number = 0;

            for (i = 0;i < n;i++)
            {
                total += sampleW[i];
            }

            if (total <= 0)
            {
                ignoringExcursion = false;

                for (i = 0;i < n;i++)
                {
                    sampleW[i] = 1;
                }
            }

            const lowX:Number = weightedQuantile(sampleX, sampleW, REGION_LOW);
            const highX:Number = weightedQuantile(sampleX, sampleW, REGION_HIGH);
            const lowY:Number = weightedQuantile(sampleY, sampleW, REGION_LOW);
            const highY:Number = weightedQuantile(sampleY, sampleW, REGION_HIGH);
            regionRect.setTo(lowX, lowY, highX - lowX, highY - lowY);

            // 지금 커서는 항상 영역 안에 둠 (영역 밖 10%를 놓치지 않게). 짧은 바깥 이동으로 무시하는 중이면 넣지 않음
            if (!ignoringExcursion)
            {
                const left:Number = Math.min(regionRect.left, cursor.x);
                const top:Number = Math.min(regionRect.top, cursor.y);
                regionRect.setTo(left, top, Math.max(regionRect.right, cursor.x) - left, Math.max(regionRect.bottom, cursor.y) - top);
            }

            const boxW:Number = regionRect.width * Math.abs(cos) + regionRect.height * Math.abs(sin);
            const boxH:Number = regionRect.width * Math.abs(sin) + regionRect.height * Math.abs(cos);
            regionZoom = Math.min(boxW > 0 ? (view.width - FIT_MARGIN * 2) / boxW : Number.MAX_VALUE, boxH > 0 ? (view.height - FIT_MARGIN * 2) / boxH : Number.MAX_VALUE);
            lookReady = true;
            lookMiss = "";
        }

        // 값(values)을 가중치(weights)로 센 분위수 q (0~1)
        private function weightedQuantile(values:Vector.<Number>, weights:Vector.<Number>, q:Number):Number
        {
            const n:int = values.length;
            const order:Array = new Array(n);
            var total:Number = 0;

            for (var i:int = 0;i < n;i++)
            {
                order[i] = i;
                total += weights[i];
            }

            order.sort(function (a:int, b:int):int
                {
                    return values[a] < values[b] ? -1 : (values[a] > values[b] ? 1 : 0);
                });
            const goal:Number = total * q;
            var acc:Number = 0;

            for (i = 0;i < n;i++)
            {
                acc += weights[order[i]];

                if (acc >= goal && weights[order[i]] > 0)
                {
                    return values[order[i]];
                }
            }

            return values[order[n - 1]];
        }

        // ---- 자동 줌 ----

        // 카메라가 적용하지 않은 배율 변화(사용자 줌, 창 맞춤, 재생 끝 복원 등)면 그 값을 사용자 줌으로 받아들이고 자동 줌을 풀음
        // 반환: 외부 배율 변화를 감지했는지 (처음 값 읽기는 제외)
        private function detectExternalZoom():Boolean
        {
            const actual:Number = ReplayState.rCanvasZoomMultiplier;

            if (isNaN(curZoom) || Math.abs(actual - curZoom) > 1e-9)
            {
                const first:Boolean = isNaN(curZoom);

                if (!first)
                {
                    userZoomAt = getTimer();
                }

                curZoom = actual;
                userZoom = actual;
                zoomState = ZOOM_FOLLOW;
                zoomCommit = NaN;
                zoomMoving = false;
                upSince = -1;
                return !first;
            }

            return false;
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

        // 상태를 정하고(재생 중일 때만) 배율을 유지 배율(zoomCommit)로 감쇠시킴. instant면 전환을 바로 끝냄
        // 줌아웃은 필요한 만큼 바로 낮추고, 줌인(올림)은 "더 큰 배율이어도 영역이 여유 있게 들어간다"가 RETURN_DWELL_MS 동안 이어지고 줌아웃 전환이 끝난 뒤일 때만 올림
        private function stepZoom(playing:Boolean, instant:Boolean, dt:Number = 0):void
        {
            detectExternalZoom();
            const view:Rectangle = viewportRect();
            const fit:Number = Math.min(fitZoom(view), userZoom);
            const cap:Number = userZoom * RETURN_ZOOM_RATIO;

            if (playing)
            {
                decideZoom(view, fit, cap);
            }

            if (zoomState === ZOOM_FOLLOW)
            {
                return;
            }

            const target:Number = Math.max(fit, Math.min(zoomCommit, cap)); // 창 크기가 바뀌어 맞춤 배율이 달라져도 범위 안으로
            const logDiff:Number = Math.log(target) - Math.log(curZoom);

            if (instant || Math.abs(logDiff) < ZOOM_SETTLED_LOG)
            {
                const wasMoving:Boolean = zoomMoving;
                applyZoom(target);
                zoomMoving = false;

                if (target >= cap)
                {
                    zoomState = ZOOM_FOLLOW; // 사용자 줌까지 돌아옴
                    zoomCommit = NaN;
                    upSince = -1;
                }

                if (wasMoving)
                {
                    finishZoom();
                }

                return;
            }

            zoomMoving = true;
            const tau:Number = (logDiff < 0) ? ZOOM_OUT_TAU_MS : ZOOM_IN_TAU_MS;
            applyZoom(Math.exp(Math.log(curZoom) + logDiff * (1 - Math.exp(-dt / tau))));
        }

        // 지금 상황에서 유지하려는 배율(zoomCommit)을 정함
        // 줌아웃 목표(바로 따라감): 슬라이드쇼/큰 연출이면 맞춤 배율, 영역이 있으면 영역이 들어가는 배율, 없으면(배속 규칙) 배속이 높을 때만 맞춤 배율
        // 줌인 후보(확인 시간 필요): 영역이 REGION_CALM_RATIO만큼 여유 있게 들어가는 더 큰 배율 (배속 규칙에서는 배속이 낮을 때 사용자 줌)
        private function decideZoom(view:Rectangle, fit:Number, cap:Number):void
        {
            // 방금 사용자가 정한 배율을 존중: 수동 줌 뒤 USER_OVERRIDE_MS 동안은 자동 줌아웃을 시작하지 않음 (슬라이드쇼/큰 연출의 강제 맞춤 포함)
            if (zoomState === ZOOM_FOLLOW && getTimer() - userZoomAt < USER_OVERRIDE_MS)
            {
                return;
            }

            const speed:Number = ReplayState.rReplaySpeedMultipler;
            const forced:Boolean = ReplayState.isReplaySlideShowMode || isBigAnim(view); // 영역과 상관없이 화면 전체를 보여 줌
            var busy:Boolean;
            var downTarget:Number;
            var upCandidate:Number;

            if (forced)
            {
                busy = true;
                downTarget = fit;
                upCandidate = fit;
            }
            else if (lookReady)
            {
                busy = regionZoom < cap;
                downTarget = Math.max(fit, Math.min(regionZoom, cap));
                upCandidate = Math.max(fit, Math.min(regionZoom / REGION_CALM_RATIO, cap));
            }
            else
            {
                busy = speed >= AUTO_FIT_SPEED_IN;
                downTarget = fit;
                upCandidate = (speed < AUTO_FIT_SPEED_OUT) ? cap : fit;
            }

            if (zoomState === ZOOM_FOLLOW)
            {
                if (busy)
                {
                    zoomState = ZOOM_HELD;
                    zoomCommit = downTarget;
                    upSince = -1;
                }

                return;
            }

            if (downTarget < zoomCommit)
            {
                zoomCommit = downTarget; // 더 낮춰야 하면 바로 따라감
                upSince = -1;
                return;
            }

            // 올리는 후보는 줌아웃이 끝나 유지 배율에 도착한 뒤부터 셈 (줌아웃 중에 쌓인 시간으로 끝나자마자 줌인하지 않게)
            const arrived:Boolean = !zoomMoving && Math.abs(Math.log(zoomCommit) - Math.log(curZoom)) < ZOOM_SETTLED_LOG;

            if (!arrived || upCandidate <= zoomCommit * (1 + ZOOM_SETTLED_LOG))
            {
                upSince = -1;
                return;
            }

            const now:int = getTimer();

            if (upSince < 0)
            {
                upSince = now;
            }
            else if (now - upSince >= RETURN_DWELL_MS)
            {
                zoomCommit = upCandidate; // 그 시점의 값으로 올림
                upSince = -1;
            }
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

            if (area === null && !lookReady)
            {
                const p:Point = canvasToScreen(cursor.x, cursor.y);
                return new Rectangle(p.x, p.y, 0, 0);
            }

            const target:Rectangle = (area === null) ? regionRect : area;
            const corners:Array = [canvasToScreen(target.left, target.top), canvasToScreen(target.right, target.top), canvasToScreen(target.left, target.bottom), canvasToScreen(target.right, target.bottom)];
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
    }
}
