package Modules.L4UI.ReplayEngine
{
    import Modules.L1Data.AppContext;

    import flash.display.Stage;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.getTimer;
    import Modules.L5App.ReplayEngine.ReplayController;
    import Modules.L2Engine.ReplayEngine.ReplayClock;
    import Modules.L2Engine.ReplayEngine.ReplayCommandWindow;
    import Modules.L2Engine.ReplayEngine.ReplayDrawer;
    import Modules.L4UI.UIEngine.UIController;
    import Modules.L2Engine.ReplayEngine.ReplayDrawCommands;
    import Modules.L2Engine.ReplayEngine.ReplayState;
    import Modules.L1Data.Utils;
    import Modules.L2Engine.UndoHistory;
    import Modules.L1Data.UIEngine.UITheme;

    // 리플레이 카메라 (ReplayDrawer.cursorFollow). 커서 경로만 보고 배율과 위치를 정함
    // 지나간 커서(PAST_WINDOW_REAL_MS)와 앞으로의 커서(ReplayCommandWindow.LOOKAHEAD_REAL_MS)를 실제 시간 가중으로 묶은 활동 영역이
    // 넓으면 멀리서(최소는 캔버스 전체가 보이는 맞춤 배율), 좁으면 확대해서 따라감. 배속 규칙은 따로 없음 (고배속이면 같은 시간에 커서가 더 많이 움직여 영역이 넓어짐)
    // 화면 중심(캔버스 좌표)과 로그 배율을 임계 감쇠 스프링으로 따라가서 출발과 정지가 부드러움
    // 화면 상태(창 크기, 캔버스 경계, 줌, 회전)는 캐시하지 않고 계산할 때마다 읽음
    // 층: L4 UI - 커서 활동 영역을 화면에 보여주는 리플레이 카메라
    public class ReplayCursorFollow
    {
        // 이동
        private static const CENTER_SMOOTH_MS:Number = 450; // 화면 중심이 활동 영역 중심을 따라가는 스프링 시간. 클수록 느긋하게 따라감
        private static const SAFETY_PADDING:Number = 20; // 커서가 화면 가장자리에서 이보다 가까우면 스프링을 기다리지 않고 바로 옮김
        private static const EDGE_MARGIN:Number = 20; // 화면보다 큰 캔버스의 가장자리가 화면 안으로 들어올 수 있는 최대 px
        private static const MAX_DT_MS:Number = 100; // 한 틱 dt 상한 (멈췄다 재개할 때 튀지 않게)

        // 줌. 배율은 맞춤 배율(최소)과 확대 상한(최대) 사이에서만 움직임
        private static const FIT_MARGIN:Number = 20; // 맞춤 배율에서 화면 가장자리에 남기는 여백 px
        private static const FRAMING_RATIO:Number = 0.6; // 활동 영역이 화면에서 차지하게 할 비율. 키우면 더 확대함
        private static const MIN_REGION_CANVAS_PX:Number = 200; // 활동 영역의 최소 가로/세로 (캔버스 px). 커서가 거의 안 움직일 때 상한까지 빨려 들어가지 않게 함
        private static const PIXEL_MAGNIFY_LIMIT:Number = 3; // 확대 상한 1: 캔버스 1px을 화면 몇 px까지 키울지 (UI 배율을 곱해서 고해상도 화면에서도 같은 크기로 보이게 함)
        private static const CONTEXT_ZOOM_LIMIT:Number = 6; // 확대 상한 2: 맞춤 배율의 몇 배까지 들어갈지. 줄이면 주변 맥락을 더 남김
        private static const ZOOM_OUT_SMOOTH_MS:Number = 500; // 줌아웃 스프링 시간 (조금 빠르게)
        private static const ZOOM_IN_SMOOTH_MS:Number = 1000; // 줌인 스프링 시간 (느긋하게)
        private static const START_OVERVIEW_MS:Number = 1500; // 처음부터 재생을 시작한 뒤 전체 보기를 유지하는 실제 시간

        // 활동 영역
        private static const PAST_WINDOW_REAL_MS:Number = 1000; // 지나간 커서를 영역에 넣는 실제 시간
        private static const REGION_LOW:Number = 0.1; // 시간 가중 10~90% 구간을 영역으로 봄 (잠깐 튀는 커서는 빠짐)
        private static const REGION_HIGH:Number = 0.9;
        private static const MAX_PATH_SAMPLES:int = 600; // 계산에 쓰는 앞으로의 경로 점 수 상한

        // 스프링 상태. 화면 중심에 둘 캔버스 좌표와 배율의 로그
        private var cameraCenterX:Number = 0;
        private var cameraCenterY:Number = 0;
        private var cameraLogZoom:Number = 0;
        private const cameraVelocity:Vector.<Number> = new Vector.<Number>(3, true); // 채널별 스프링 속도 (0: 중심 x, 1: 중심 y, 2: 로그 배율), 단위/ms
        private var isCameraStateLoaded:Boolean = false; // false면 다음 틱에 실제 화면에서 상태를 읽음
        private var appliedZoomMultiplier:Number = NaN; // 카메라가 마지막으로 적용한 배율과 앵커. 실제 값과 다르면 외부(창 맞춤, 회전, 창 크기 등)가 바꾼 것
        private var appliedAnchorX:Number = NaN;
        private var appliedAnchorY:Number = NaN;
        private var lastCameraStepTimeMs:int = 0;
        private var startOverviewUntilMs:int = -1000000; // 이 시각(getTimer)까지 전체 보기
        private var reportedZoomPercent:int = -1; // 정보 상자에 마지막으로 보낸 배율(%)

        // 이번 틱의 목표 (computeCameraTarget이 채움)
        private var targetCenterX:Number = 0;
        private var targetCenterY:Number = 0;
        private var targetLogZoom:Number = 0;
        private const activityRegionRect:Rectangle = new Rectangle(); // 캔버스 좌표

        // 지나간 커서 기록 (틱마다 한 점, 실제 시각)
        private const pastCursorTimeMs:Vector.<Number> = new Vector.<Number>();
        private const pastCursorX:Vector.<Number> = new Vector.<Number>();
        private const pastCursorY:Vector.<Number> = new Vector.<Number>();

        // 계산용 버퍼
        private const upcomingCursorPath:Vector.<Number> = new Vector.<Number>();
        private const upcomingSampleRecordedMs:Vector.<Number> = new Vector.<Number>();
        private const regionSampleX:Vector.<Number> = new Vector.<Number>();
        private const regionSampleY:Vector.<Number> = new Vector.<Number>();
        private const regionSampleWeightMs:Vector.<Number> = new Vector.<Number>(); // 샘플의 가중치(그 위치에 머문 실제 시간)

        // 화면에서 캔버스를 보여주는 영역. 위쪽은 상단바(+시크바가 겹치는 띠) 아래, 시크바는 위쪽에 붙어 있어 아래쪽은 스테이지 끝까지
        private function getCanvasViewRect():Rectangle
        {
            const top:Number = UIController.topBar.BARSIZE * UITheme.getUIScale();
            const stage:Stage = AppContext.stage;
            return new Rectangle(0, top, stage.stageWidth, stage.stageHeight - top);
        }

        // 카메라가 앵커를 건드리면 안 되는 상태
        private function isCameraBlocked():Boolean
        {
            return ReplayState.isReplayCanvasFitToWindow || UndoHistory.isDeepUndoEnabled;
        }

        // 처음부터 재생을 시작할 때 부름. START_OVERVIEW_MS 동안 전체 보기를 유지한 뒤 활동 영역으로 들어감
        public function holdOverviewAfterReplayStart():void
        {
            startOverviewUntilMs = getTimer() + START_OVERVIEW_MS;
        }

        // 외부가 화면을 바꿨을 때 부름. 스프링 상태를 실제 화면에서 다시 읽고 진행 중인 움직임을 멈춤
        public function resyncCameraWithAnchor():void
        {
            loadCameraStateFromScreen();

            // 재생 중이면 바뀐 화면에서도 커서가 보이게 바로 맞춤
            if (ReplayState.isReplayStarted && !isCameraBlocked())
            {
                applyCameraStateToCanvas();
            }
        }

        // 재생 중 그리기 바로 뒤에 한 번 부름 (replayDrawTimer)
        public function updateCameraAfterDraw():void
        {
            if (ReplayState.isReplayStarted)
            {
                stepCameraTowardTarget();
            }
        }

        // 목표를 계산하고 스프링 없이 바로 그 위치와 배율로 옮김 (탐색, 창 맞춤 해제). 지나간 커서 기록은 버림 (탐색 전 위치가 영역에 남지 않게)
        public function moveCameraToCursorNow():void
        {
            if (!ReplayState.isReplayModeON || isCameraBlocked())
            {
                return;
            }

            clearPastCursorRecord();
            loadCameraStateFromScreen();
            lastCameraStepTimeMs = getTimer();
            computeCameraTarget(lastCameraStepTimeMs);
            cameraCenterX = targetCenterX;
            cameraCenterY = targetCenterY;
            cameraLogZoom = targetLogZoom;
            applyCameraStateToCanvas();
        }

        // 지나간 커서 기록 → 목표 계산 → 스프링 → 화면 적용. updateCameraAfterDraw가 씀
        private function stepCameraTowardTarget():void
        {
            if (isCameraBlocked())
            {
                isCameraStateLoaded = false;
                clearPastCursorRecord();
                return;
            }

            if (!isCameraStateLoaded || isScreenChangedExternally())
            {
                loadCameraStateFromScreen();
            }

            const nowMs:int = getTimer();
            const deltaMs:Number = Math.min(Math.max(0, nowMs - lastCameraStepTimeMs), MAX_DT_MS);
            lastCameraStepTimeMs = nowMs;
            recordPastCursor(nowMs);
            computeCameraTarget(nowMs);
            cameraCenterX = getSpringStepValue(0, cameraCenterX, targetCenterX, CENTER_SMOOTH_MS, deltaMs);
            cameraCenterY = getSpringStepValue(1, cameraCenterY, targetCenterY, CENTER_SMOOTH_MS, deltaMs);
            cameraLogZoom = getSpringStepValue(2, cameraLogZoom, targetLogZoom, (targetLogZoom < cameraLogZoom) ? ZOOM_OUT_SMOOTH_MS : ZOOM_IN_SMOOTH_MS, deltaMs);
            applyCameraStateToCanvas();
        }

        // 임계 감쇠 스프링 한 걸음 (채널 channel의 속도를 갱신하고 새 값을 돌려줌). smoothMs는 목표에 거의 닿는 데 걸리는 시간의 대략 절반
        private function getSpringStepValue(channel:int, current:Number, target:Number, smoothMs:Number, deltaMs:Number):Number
        {
            const omega:Number = 2 / smoothMs;
            const x:Number = omega * deltaMs;
            const decay:Number = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x);
            const change:Number = current - target;
            const temp:Number = (cameraVelocity[channel] + omega * change) * deltaMs;
            cameraVelocity[channel] = (cameraVelocity[channel] - omega * temp) * decay;
            return target + (change + temp) * decay;
        }

        // 카메라가 적용한 뒤 배율이나 앵커가 바뀌었는지 (창 맞춤, 회전, 창 크기, 캔버스 크기 변경 등)
        private function isScreenChangedExternally():Boolean
        {
            return Math.abs(ReplayState.rCanvasZoomMultiplier - appliedZoomMultiplier) > 1e-9 || ReplayDrawer.rCanvasAnchorPoint.x !== appliedAnchorX || ReplayDrawer.rCanvasAnchorPoint.y !== appliedAnchorY;
        }

        // 지금 화면(화면 중심의 캔버스 좌표, 배율)을 스프링 상태로 읽어 들이고 속도는 0으로 함
        private function loadCameraStateFromScreen():void
        {
            const view:Rectangle = getCanvasViewRect();
            const centerOnCanvas:Point = ReplayDrawer.rCanvasLayer1Bitmap.globalToLocal(new Point(view.x + view.width / 2, view.y + view.height / 2));
            cameraCenterX = centerOnCanvas.x;
            cameraCenterY = centerOnCanvas.y;
            cameraLogZoom = Math.log(ReplayState.rCanvasZoomMultiplier);
            cameraVelocity[0] = 0;
            cameraVelocity[1] = 0;
            cameraVelocity[2] = 0;
            appliedZoomMultiplier = ReplayState.rCanvasZoomMultiplier;
            appliedAnchorX = ReplayDrawer.rCanvasAnchorPoint.x;
            appliedAnchorY = ReplayDrawer.rCanvasAnchorPoint.y;
            isCameraStateLoaded = true;
        }

        // 스프링 상태를 화면에 적용: 배율을 범위 안으로 자르고, 중심을 화면 가운데에 둔 뒤 캔버스 경계와 커서 안전 구역 규칙으로 앵커를 보정
        // 보정 때문에 실제 중심이 상태와 달라지면 상태를 실제 중심으로 맞춤 (경계 밖으로 상태가 계속 밀려나 있다가 늦게 돌아오는 것을 막음)
        private function applyCameraStateToCanvas():void
        {
            const view:Rectangle = getCanvasViewRect();
            const fitZoom:Number = getFitWholeCanvasZoom(view);
            cameraLogZoom = Math.max(Math.log(fitZoom), Math.min(cameraLogZoom, Math.log(getMaxFocusZoom(fitZoom))));
            const zoomMultiplier:Number = Math.exp(cameraLogZoom);

            if (Math.abs(zoomMultiplier - ReplayState.rCanvasZoomMultiplier) > 1e-9)
            {
                applyZoomToCanvas(zoomMultiplier);
            }

            const viewCenterX:Number = view.x + view.width / 2;
            const viewCenterY:Number = view.y + view.height / 2;
            const centerScreen:Point = ReplayDrawer.rCanvasLayer1Bitmap.localToGlobal(new Point(cameraCenterX, cameraCenterY));
            const canvas:Rectangle = canvasScreenRect();
            const wantShiftX:Number = viewCenterX - centerScreen.x;
            const wantShiftY:Number = viewCenterY - centerScreen.y;
            var shiftX:Number = limitShiftByCanvasEdge(wantShiftX, view.left, view.right, canvas.left, canvas.right);
            var shiftY:Number = limitShiftByCanvasEdge(wantShiftY, view.top, view.bottom, canvas.top, canvas.bottom);

            // 커서가 안전 구역 밖으로 나가면 그 축은 가장자리에 오는 위치까지 바로 옮김 (캔버스 경계 규칙이 우선)
            const cursor:Point = ReplayDrawCommands.getRCursorPos();
            const cursorScreen:Point = ReplayDrawer.rCanvasLayer1Bitmap.localToGlobal(cursor);
            const cursorX:Number = cursorScreen.x + shiftX;
            const cursorY:Number = cursorScreen.y + shiftY;

            if (cursorX < view.left + SAFETY_PADDING || cursorX > view.right - SAFETY_PADDING)
            {
                shiftX = limitShiftByCanvasEdge(shiftX + ((cursorX < view.left + SAFETY_PADDING) ? view.left + SAFETY_PADDING - cursorX : view.right - SAFETY_PADDING - cursorX), view.left, view.right, canvas.left, canvas.right);
            }

            if (cursorY < view.top + SAFETY_PADDING || cursorY > view.bottom - SAFETY_PADDING)
            {
                shiftY = limitShiftByCanvasEdge(shiftY + ((cursorY < view.top + SAFETY_PADDING) ? view.top + SAFETY_PADDING - cursorY : view.bottom - SAFETY_PADDING - cursorY), view.top, view.bottom, canvas.top, canvas.bottom);
            }

            ReplayDrawer.rCanvasAnchorPoint.x = Math.round(ReplayDrawer.rCanvasAnchorPoint.x + shiftX);
            ReplayDrawer.rCanvasAnchorPoint.y = Math.round(ReplayDrawer.rCanvasAnchorPoint.y + shiftY);
            appliedAnchorX = ReplayDrawer.rCanvasAnchorPoint.x;
            appliedAnchorY = ReplayDrawer.rCanvasAnchorPoint.y;

            if (Math.abs(shiftX - wantShiftX) > 1 || Math.abs(shiftY - wantShiftY) > 1)
            {
                const centerOnCanvas:Point = ReplayDrawer.rCanvasLayer1Bitmap.globalToLocal(new Point(viewCenterX, viewCenterY));
                cameraCenterX = centerOnCanvas.x;
                cameraCenterY = centerOnCanvas.y;
            }
        }

        // 한 축의 이동량을 캔버스 경계 규칙으로 자름. 캔버스가 화면보다 작으면 요청과 상관없이 가운데에 둠
        private function limitShiftByCanvasEdge(shift:Number, viewLo:Number, viewHi:Number, canvasLo:Number, canvasHi:Number):Number
        {
            if (canvasHi - canvasLo <= viewHi - viewLo)
            {
                return (viewLo + viewHi) / 2 - (canvasLo + canvasHi) / 2;
            }

            return Math.max(viewHi - EDGE_MARGIN - canvasHi, Math.min(viewLo + EDGE_MARGIN - canvasLo, shift));
        }

        // 캔버스 배율을 바꿈 (앵커 위치는 applyCameraStateToCanvas가 이어서 맞춤). 예전 형식 에어브러시 블러는 화면 픽셀 기준이라 배율이 바뀔 때마다 다시 넣음
        // 정보 상자는 % 값이 바뀔 때만 갱신함
        private function applyZoomToCanvas(newZoomMultiplier:Number):void
        {
            ReplayState.rCanvasZoomMultiplier = newZoomMultiplier;
            ReplayDrawer.rCanvasAnchorPoint.scaleX = newZoomMultiplier;
            ReplayDrawer.rCanvasAnchorPoint.scaleY = newZoomMultiplier;
            ReplayDrawer.updateReplayCursorScale(newZoomMultiplier);
            appliedZoomMultiplier = newZoomMultiplier;

            if (ReplayState.rAirBrushSize > 0)
            {
                ReplayDrawer.blurReplayCanvasByValue(ReplayState.rAirBrushSize);
            }

            const zoomPercent:int = Math.round(newZoomMultiplier * 100);

            if (zoomPercent !== reportedZoomPercent)
            {
                reportedZoomPercent = zoomPercent;
                UIController.canvasInfoBox.setZoom(newZoomMultiplier);
            }
        }

        // 회전을 반영한 캔버스의 화면 경계
        private function canvasScreenRect():Rectangle
        {
            const canvasBounds:Object = Utils.getBoundRect(ReplayDrawer.rCanvasLayer1Bitmap);
            return new Rectangle(canvasBounds.left, canvasBounds.top, canvasBounds.right - canvasBounds.left, canvasBounds.bottom - canvasBounds.top);
        }


        // ---- 활동 영역과 목표 ----

        // 지금 커서를 지나간 커서 기록에 넣고 PAST_WINDOW_REAL_MS보다 오래된 기록은 버림
        private function recordPastCursor(nowMs:int):void
        {
            const cursor:Point = ReplayDrawCommands.getRCursorPos();
            pastCursorTimeMs.push(nowMs);
            pastCursorX.push(cursor.x);
            pastCursorY.push(cursor.y);
            var expiredCount:int = 0;

            while (expiredCount < pastCursorTimeMs.length && nowMs - pastCursorTimeMs[expiredCount] > PAST_WINDOW_REAL_MS)
            {
                expiredCount++;
            }

            if (expiredCount > 0)
            {
                pastCursorTimeMs.splice(0, expiredCount);
                pastCursorX.splice(0, expiredCount);
                pastCursorY.splice(0, expiredCount);
            }
        }

        // 지나간 커서 기록을 비움 (탐색, 카메라가 막혔을 때)
        private function clearPastCursorRecord():void
        {
            pastCursorTimeMs.length = 0;
            pastCursorX.length = 0;
            pastCursorY.length = 0;
        }

        // 이번 틱의 목표 중심과 목표 배율을 정함
        // 처음 재생 직후는 전체 보기. 그 외에는 활동 영역(지나간 커서 + 지금 커서 + 앞으로의 커서, 실제 시간 가중 10~90%)의 중심과, 그 영역이 화면의 FRAMING_RATIO를 차지하는 배율
        // 미리 읽기가 상한(프레임/묶음 수)에 걸려 앞을 다 못 봤으면 본 비율만큼만 확대함 (덜 본 영역은 실제보다 작아서 잘못 확대하지 않게)
        // 앞을 읽을 수 없는 상태(탐색 직후 등)면 목표를 지금 상태로 둠 (움직이지 않음)
        private function computeCameraTarget(nowMs:int):void
        {
            const view:Rectangle = getCanvasViewRect();
            const fitZoom:Number = getFitWholeCanvasZoom(view);
            targetCenterX = cameraCenterX;
            targetCenterY = cameraCenterY;
            targetLogZoom = cameraLogZoom;

            if (nowMs < startOverviewUntilMs)
            {
                targetCenterX = ReplayState.RCANVAS_WIDTH / 2;
                targetCenterY = ReplayState.RCANVAS_HEIGHT / 2;
                targetLogZoom = Math.log(fitZoom);
                return;
            }

            const commandWindow:ReplayCommandWindow = ReplayDrawer.commandWindow;

            if (!commandWindow.isQueueAlignedWithByte(ReplayState.rFileLastBytePosition) && !ReplayState.rMemoryDataReadON)
            {
                return;
            }

            const lookaheadCoverageRatio:Number = collectActivityRegionSamples(nowMs);

            if (regionSampleX.length === 0)
            {
                return;
            }

            var totalWeightMs:Number = 0;

            for (var i:int = 0;i < regionSampleWeightMs.length;i++)
            {
                totalWeightMs += regionSampleWeightMs[i];
            }

            if (totalWeightMs <= 0)
            {
                for (i = 0;i < regionSampleWeightMs.length;i++)
                {
                    regionSampleWeightMs[i] = 1;
                }
            }

            // x, y 각각 시간 가중 10%~90% 위치를 영역으로 하고 지금 커서는 항상 넣음
            const cursor:Point = ReplayDrawCommands.getRCursorPos();
            const regionLeft:Number = Math.min(cursor.x, getWeightedPercentile(regionSampleX, regionSampleWeightMs, REGION_LOW));
            const regionRight:Number = Math.max(cursor.x, getWeightedPercentile(regionSampleX, regionSampleWeightMs, REGION_HIGH));
            const regionTop:Number = Math.min(cursor.y, getWeightedPercentile(regionSampleY, regionSampleWeightMs, REGION_LOW));
            const regionBottom:Number = Math.max(cursor.y, getWeightedPercentile(regionSampleY, regionSampleWeightMs, REGION_HIGH));
            const regionWidth:Number = Math.max(MIN_REGION_CANVAS_PX, regionRight - regionLeft);
            const regionHeight:Number = Math.max(MIN_REGION_CANVAS_PX, regionBottom - regionTop);
            targetCenterX = (regionLeft + regionRight) / 2;
            targetCenterY = (regionTop + regionBottom) / 2;
            activityRegionRect.setTo(targetCenterX - regionWidth / 2, targetCenterY - regionHeight / 2, regionWidth, regionHeight);

            const maxZoom:Number = getMaxFocusZoom(fitZoom);
            const regionZoom:Number = Math.max(fitZoom, Math.min(getRegionFillZoom(activityRegionRect, view) * FRAMING_RATIO, maxZoom));
            targetLogZoom = Math.log(fitZoom) + (Math.log(regionZoom) - Math.log(fitZoom)) * lookaheadCoverageRatio;
        }

        // 활동 영역 샘플(regionSampleX/Y/WeightMs)을 채움. 가중치는 그 위치에 머문 실제 시간 (앞으로의 경로는 녹화 시간 / 배속)
        // 반환: 앞으로 볼 시간(LOOKAHEAD_REAL_MS * 배속) 중 실제로 읽어 둔 비율 (0~1, 데이터 끝까지 봤으면 1)
        private function collectActivityRegionSamples(nowMs:int):Number
        {
            regionSampleX.length = 0;
            regionSampleY.length = 0;
            regionSampleWeightMs.length = 0;

            // 지나간 커서: 다음 기록까지 머문 시간 (마지막 기록은 지금 커서와 같아서 0)
            const pastCount:int = pastCursorTimeMs.length;

            for (var i:int = 0;i < pastCount;i++)
            {
                regionSampleX.push(pastCursorX[i]);
                regionSampleY.push(pastCursorY[i]);
                regionSampleWeightMs.push(((i + 1 < pastCount) ? pastCursorTimeMs[i + 1] : nowMs) - pastCursorTimeMs[i]);
            }

            // 앞으로의 커서: 지금 커서가 첫 지점까지, 각 지점은 다음 지점까지 머문 시간
            const nowFrame:Number = ReplayState.rNowFrame;
            const speed:Number = Math.max(1, ReplayState.rReplaySpeedMultipler);
            const lookaheadSpanMs:Number = ReplayCommandWindow.LOOKAHEAD_REAL_MS * speed;
            const startRecordedMs:Number = ReplayClock.getRecordedTimeOfFrame(nowFrame);
            const commandWindow:ReplayCommandWindow = ReplayDrawer.commandWindow;
            upcomingCursorPath.length = 0;
            commandWindow.collectCursorPath(nowFrame, nowFrame + ReplayCommandWindow.LOOKAHEAD_MAX_FRAMES, upcomingCursorPath);
            const coveredRecordedMs:Number = ReplayClock.getRecordedTimeOfFrame(Math.min(commandWindow.coveredEndFrame, ReplayState.TOTAL_FRAME)) - startRecordedMs;
            const coverageRatio:Number = commandWindow.coveredToDataEnd ? 1 : Math.max(0, Math.min(1, coveredRecordedMs / lookaheadSpanMs));
            const cursor:Point = ReplayDrawCommands.getRCursorPos();
            upcomingSampleRecordedMs.length = 0;
            upcomingSampleRecordedMs.push(startRecordedMs);
            regionSampleX.push(cursor.x);
            regionSampleY.push(cursor.y);
            const sampleStride:int = Math.max(1, int(upcomingCursorPath.length / 3 / MAX_PATH_SAMPLES));

            for (i = 0;i < upcomingCursorPath.length;i += 3 * sampleStride)
            {
                const t:Number = ReplayClock.getRecordedTimeOfFrame(upcomingCursorPath[i]);

                if (t - startRecordedMs > lookaheadSpanMs)
                {
                    break;
                }

                upcomingSampleRecordedMs.push(Math.max(t, upcomingSampleRecordedMs[upcomingSampleRecordedMs.length - 1]));
                regionSampleX.push(upcomingCursorPath[i + 1]);
                regionSampleY.push(upcomingCursorPath[i + 2]);
            }

            // 마지막 지점은 읽어 둔 끝(목표 시간 안)까지 머문 것으로 봄. 데이터 끝이면 아주 짧게
            const upcomingCount:int = upcomingSampleRecordedMs.length;
            const lastUpcomingEndMs:Number = commandWindow.coveredToDataEnd ? upcomingSampleRecordedMs[upcomingCount - 1] + 1 : startRecordedMs + Math.min(lookaheadSpanMs, Math.max(0, coveredRecordedMs));

            for (i = 0;i < upcomingCount;i++)
            {
                const endMs:Number = (i + 1 < upcomingCount) ? upcomingSampleRecordedMs[i + 1] : Math.max(lastUpcomingEndMs, upcomingSampleRecordedMs[i]);
                regionSampleWeightMs.push((endMs - upcomingSampleRecordedMs[i]) / speed);
            }

            return coverageRatio;
        }

        // 값(values)을 가중치(weights)로 센 분위수 q (0~1)
        private function getWeightedPercentile(values:Vector.<Number>, weights:Vector.<Number>, q:Number):Number
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

        // 지금 회전과 창 크기에서 캔버스 전체가 화면에 들어가는 배율 (연속값, 순수 계산). 자동 줌의 최소 배율
        private function getFitWholeCanvasZoom(view:Rectangle):Number
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

        // 자동 줌의 최대 배율: 픽셀 확대 한계(UI 배율 반영)와 맞춤 배율의 CONTEXT_ZOOM_LIMIT배 중 작은 값. 맞춤 배율이 이미 더 크면 맞춤 배율 (확대하지 않음)
        private function getMaxFocusZoom(fitZoom:Number):Number
        {
            return Math.max(fitZoom, Math.min(PIXEL_MAGNIFY_LIMIT * UITheme.getUIScale(), fitZoom * CONTEXT_ZOOM_LIMIT));
        }

        // 캔버스 좌표 사각형이 지금 회전에서 화면(view)에 꽉 차는 배율. 크기가 0이면 Number.MAX_VALUE (최대 배율로 잘림)
        private function getRegionFillZoom(region:Rectangle, view:Rectangle):Number
        {
            const rad:Number = ReplayDrawer.rCanvasAnchorPoint.rotation * Math.PI / 180;
            const cos:Number = Math.abs(Math.cos(rad));
            const sin:Number = Math.abs(Math.sin(rad));
            const boxW:Number = region.width * cos + region.height * sin;
            const boxH:Number = region.width * sin + region.height * cos;
            return Math.min(boxW > 0 ? view.width / boxW : Number.MAX_VALUE, boxH > 0 ? view.height / boxH : Number.MAX_VALUE);
        }
    }
}
