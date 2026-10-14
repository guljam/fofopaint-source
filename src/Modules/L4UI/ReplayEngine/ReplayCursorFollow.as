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

    // 리플레이 캔버스를 옮겨서 곧 그려질 영역(연출 중이면 연출 영역, 아니면 커서)을 화면 안에 두는 카메라 (ReplayDrawer.cursorFollow)
    // 앵커를 한 번에 옮기지 않고 목표만 정한 뒤 별도 타이머에서 실제 시간 기준으로 감쇠하며 따라감
    // 화면 상태(창 크기, 캔버스 경계, 줌, 회전)는 캐시하지 않고 계산할 때마다 읽음
    // 층: L4 UI - 곧 그려질 영역을 화면 안에 두는 리플레이 카메라
    public class ReplayCursorFollow
    {
        private static const CAMERA_TAU_MS:Number = 300; // 감쇠 시간. 클수록 느긋하게 따라감
        private static const DEAD_ZONE_INSET:Number = 0.2; // 화면 각 변에서 이 비율만큼 안쪽까지가 데드존 바깥 (가운데 60%가 데드존)
        private static const SAFETY_PADDING:Number = 20; // 커서가 화면 가장자리에서 이보다 가까우면 감쇠 없이 바로 따라감
        private static const EDGE_MARGIN:Number = 20; // 화면보다 큰 캔버스의 가장자리가 화면 안으로 들어올 수 있는 최대 px
        private static const MAX_DT_MS:Number = 100; // 한 틱 dt 상한 (멈췄다 재개할 때 튀지 않게)
        private static const SETTLED_DIST:Number = 0.5; // 목표와 이 거리 미만이면 도착한 것으로 봄

        // 자동 줌. 배율은 캔버스 전체가 보이는 맞춤 배율(최소)과 확대 상한(최대) 사이에서만 움직임 (조정용 값은 여기 모음)
        private static const FIT_MARGIN:Number = 20; // 맞춤 배율에서 화면 가장자리에 남기는 여백 px
        private static const FOCUS_FRAMING_RATIO:Number = 0.65; // 확대할 때 집중 영역이 화면에서 차지하게 할 비율. 키우면 더 많이 확대함
        private static const FOCUS_KEEP_RATIO:Number = 0.9; // 집중 영역이 지금 배율에서 화면의 이 비율을 넘으면 줌아웃. FOCUS_FRAMING_RATIO보다 커야 경계에서 들락날락하지 않음
        private static const PIXEL_MAGNIFY_LIMIT:Number = 1.5; // 확대 상한 1: 캔버스 1px을 화면 몇 px까지 키울지 (UI 배율을 곱해서 고해상도 화면에서도 같은 크기로 보이게 함)
        private static const CONTEXT_ZOOM_LIMIT:Number = 3; // 확대 상한 2: 맞춤 배율의 몇 배까지 들어갈지. 줄이면 주변 맥락을 더 남김
        private static const ZOOM_IN_DWELL_MS:Number = 1500; // 더 큰 배율로 들어가도 되는 상태가 이만큼 이어져야 확대
        private static const ZOOM_OUT_TAU_MS:Number = 200; // 줌아웃 감쇠 시간 (빠르게)
        private static const ZOOM_IN_TAU_MS:Number = 600; // 줌인 감쇠 시간 (느리게)
        private static const ZOOM_SETTLED_LOG:Number = 0.002; // 로그 배율 차이가 이 값 미만이면 도착

        // 전체 보기(맞춤 배율로 강제) 계기
        private static const OVERVIEW_SPEED_IN:Number = 8; // D: 이 배속 이상이면 전체 보기
        private static const OVERVIEW_SPEED_OUT:Number = 5; // D: 이 배속 미만이어야 전체 보기를 풂 (들어가는 값보다 낮게 둬서 경계에서 흔들리지 않게 함)
        private static const CANVAS_WIDE_OVERVIEW_MS:Number = 2000; // B: 캔버스 전체에 영향을 주는 명령(지우기, 크기 변경, 대칭 등) 뒤 전체 보기를 유지하는 실제 시간
        private static const START_OVERVIEW_MS:Number = 1500; // C: 처음부터 재생을 시작한 뒤 전체 보기를 유지하는 실제 시간
        private static const JUMP_DISTANCE_RATIO:Number = 0.5; // A: 먼 영역과 가까운 영역의 중심 거리가 지금 화면 짧은 변의 이 비율 이상이고 겹치지 않으면 다른 영역으로 넘어가는 것으로 봄

        // 미리 읽은 커서 경로로 영역을 추적
        private static const REGION_LOOKAHEAD_REAL_MS:Number = 500; // 집중 영역을 계산하는 미리 보기 시간 (실제 시간). 이 뒤부터 ReplayCommandWindow.LOOKAHEAD_REAL_MS까지는 A 판정에만 씀
        private static const EXCURSION_IGNORE_MS:Number = 800; // 데드존 밖으로 나가 있던 시간이 이보다 짧으면 따라가지 않음 (실제 시간)
        private static const REGION_LOW:Number = 0.1; // 시간 가중 10~90% 구간을 영역으로 봄
        private static const REGION_HIGH:Number = 0.9;
        private static const MAX_PATH_SAMPLES:int = 600; // 계산에 쓰는 경로 점 수 상한
        private static const EXCURSION_GAP_MS:Number = 150; // 데드존 밖 구간 사이에 안으로 들어와 있던 실제 시간이 이보다 짧으면 같은 바깥 이동으로 이음 (경계를 스치는 점 하나로 구간이 갈라졌다 합쳐지며 영역이 튀는 것을 막음)

        // 감쇠 중인 앵커 위치와 목표 (전역 좌표, 소수 유지. 앵커에 넣을 때만 반올림)
        private var anchorPosX:Number = 0;
        private var anchorPosY:Number = 0;
        private var anchorTargetX:Number = 0;
        private var anchorTargetY:Number = 0;
        private var lastCameraStepTimeMs:int = 0;

        // 미리 읽은 경로로 구한 값 (매 틱 다시 계산). isUpcomingRegionReady가 false면 커서 한 점과 배속 기준으로 되돌아감
        private var isUpcomingRegionReady:Boolean = false;
        private var upcomingRegionMissReasonCode:String = "";
        private const upcomingRegionRect:Rectangle = new Rectangle(); // 캔버스 좌표, 시간 가중 10~90% 영역
        private var isUpcomingJumpDetected:Boolean = false; // A: 가까운 영역 뒤에 멀리 떨어진 영역으로 넘어감
        private const upcomingJumpUnionRect:Rectangle = new Rectangle(); // A일 때 가까운 영역과 먼 영역을 합친 사각형 (캔버스 좌표)
        private var isShortExcursionIgnored:Boolean = false; // 지금 커서가 무시하는 짧은 바깥 이동 안에 있음
        private var cursorOutsideDeadZoneSinceMs:int = -1; // 커서가 데드존 밖으로 나간 시각 (getTimer), 안이면 -1
        private const upcomingCursorPath:Vector.<Number> = new Vector.<Number>();
        private const regionSampleRecordedMs:Vector.<Number> = new Vector.<Number>(); // 샘플의 녹화 시각
        private const regionSampleX:Vector.<Number> = new Vector.<Number>();
        private const regionSampleY:Vector.<Number> = new Vector.<Number>();
        private const regionSampleWeightMs:Vector.<Number> = new Vector.<Number>(); // 샘플의 가중치(그 위치에 머문 녹화 시간)
        private const regionSampleOutsideDeadZone:Vector.<Boolean> = new Vector.<Boolean>(); // 샘플이 데드존 밖인지
        private const jumpSampleX:Vector.<Number> = new Vector.<Number>(); // A 판정용 먼 구간(REGION_LOOKAHEAD_REAL_MS 뒤) 샘플
        private const jumpSampleY:Vector.<Number> = new Vector.<Number>();
        private const jumpSampleWeightMs:Vector.<Number> = new Vector.<Number>();

        // 자동 줌 상태 (사용자 줌은 없음. 외부가 배율을 바꾸면 그 값에서 이어서 움직임)
        private var appliedZoomMultiplier:Number = NaN; // 카메라가 마지막으로 적용한 배율. 실제 배율과 다르면 외부(창 맞춤, 캡처 복귀 등)가 바꾼 것
        private var isZoomMovingToHeldZoom:Boolean = false; // 배율이 heldZoomMultiplier을 향해 움직이는 중
        private var heldZoomMultiplier:Number = NaN; // 유지하려는 배율. 줌아웃은 바로 낮추고, 올리는 것(줌인)은 확인 시간을 거쳐서만 올림
        private var zoomInCandidateSinceMs:int = -1; // 더 큰 배율로 들어가도 되는 상태가 이어지기 시작한 시각, 아니면 -1
        private var isSpeedOverviewOn:Boolean = false; // D: 배속 때문에 전체 보기 중 (OVERVIEW_SPEED_IN/OUT 사이에서는 직전 상태 유지)
        private var startOverviewUntilMs:int = -1000000; // C: 이 시각(getTimer)까지 전체 보기

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

        // C: 처음부터 재생을 시작할 때 부름. START_OVERVIEW_MS 동안 전체 보기를 유지한 뒤 집중 영역으로 들어감
        public function holdOverviewAfterReplayStart():void
        {
            startOverviewUntilMs = getTimer() + START_OVERVIEW_MS;
        }

        // 외부가 화면을 바꿨을 때 부름. 카메라 내부 값을 실제 앵커로 다시 맞추고 진행 중인 이동을 멈춤
        public function resyncCameraWithAnchor():void
        {
            loadCameraFromAnchor();

            // 재생 중 외부가 배율을 바꾼 직후 커서가 화면 밖이면 다음 그리기 틱을 기다리지 않고 바로 안전 구역으로 끌어옴 (무시 구간이면 3-3 규칙대로 안 끌어옴)
            if (syncZoomIfChangedExternally() && ReplayState.isReplayStarted && !isShortExcursionIgnored && !isCameraBlocked())
            {
                keepCursorInSafeZone();
            }
        }

        // 이번 틱에 영역을 쓰지 못한 이유 ("": 영역 사용 중). unaligned = 탐색 직후 등으로 큐가 어긋남, fewSamples = 미리 볼 커서 지점이 3개 미만, coverage = 프레임/묶음 상한으로 목표 시간만큼 못 봄
        public function get upcomingRegionMissReason():String
        {
            return upcomingRegionMissReasonCode;
        }

        // 이번 틱에 미리 읽은 경로의 영역으로 줌/초점을 정했는지. false면 커서 한 점과 배속 규칙을 씀 (경로가 없거나, 상한 때문에 목표 시간만큼 못 봤을 때)
        public function get isUsingUpcomingRegion():Boolean
        {
            return isUpcomingRegionReady;
        }

        // 지금 커서가 짧은 바깥 이동(EXCURSION_IGNORE_MS 미만)으로 판단되어 따라가지 않는 중인지. 이때는 커서가 화면 밖에 있을 수 있음
        public function get isIgnoringShortCursorMove():Boolean
        {
            return isShortExcursionIgnored;
        }

        // 재생 중 그리기 바로 뒤에 한 번 부름 (replayDrawTimer). 그리기 타이머가 갱신하므로 카메라 타이머와 두 번 움직이지 않음
        // (즉시 맞추는 moveCameraToCursorNow은 탐색 경로와 자동 건너뛰기에서만 씀)
        public function updateCameraAfterDraw():void
        {
            if (ReplayState.isReplayStarted)
            {
                stepCameraTowardTarget();
            }
        }

        // 목표를 계산하고 앵커와 배율을 바로 그 위치로 옮김 (탐색, 재생이 멈췄을 때). 진행 중인 줌 전환도 유지 배율로 바로 끝냄
        // 카메라가 앵커를 움직이는 곳은 재생 중 updateCameraAfterDraw와 이 함수뿐임 (멈춘 뒤 남은 이동을 애니메이션하는 타이머는 없음)
        public function moveCameraToCursorNow():void
        {
            if (!ReplayState.isReplayModeON || isCameraBlocked())
            {
                return;
            }

            loadCameraFromAnchor();
            computeUpcomingCursorRegion();

            // 멈추거나 탐색한 자리에서는 무시 중이던 바깥 이동도 커서를 화면에 보여 줌
            if (isUpcomingRegionReady && isShortExcursionIgnored)
            {
                const cursorPos:Point = ReplayDrawCommands.getRCursorPos();
                const regionLeft:Number = Math.min(upcomingRegionRect.left, cursorPos.x);
                const regionTop:Number = Math.min(upcomingRegionRect.top, cursorPos.y);
                upcomingRegionRect.setTo(regionLeft, regionTop, Math.max(upcomingRegionRect.right, cursorPos.x) - regionLeft, Math.max(upcomingRegionRect.bottom, cursorPos.y) - regionTop);
                isShortExcursionIgnored = false;
            }

            updateCameraZoom(ReplayState.isReplayStarted, true);
            loadCameraFromAnchor();
            const cursor:Point = ReplayDrawCommands.getRCursorPos();
            const view:Rectangle = getCanvasViewRect();
            const canvas:Rectangle = canvasScreenRect();
            const focus:Rectangle = focusScreenRect(cursor);
            anchorPosX += getAnchorShiftOnAxis(true, focus, view, canvas);
            anchorPosY += getAnchorShiftOnAxis(false, focus, view, canvas);
            anchorTargetX = anchorPosX;
            anchorTargetY = anchorPosY;
            applyCameraToAnchor();
            keepCursorInSafeZone();
        }

        // 줌 → 목표 재계산 → 안전 구역 → 감쇠 → 앵커 적용. updateCameraAfterDraw가 씀
        private function stepCameraTowardTarget():void
        {
            if (isCameraBlocked())
            {
                loadCameraFromAnchor();
                return;
            }

            // 소수 위치는 앵커가 외부에서 옮겨졌을 때만 버림 (매번 맞추면 작은 이동분이 반올림에 지워짐)
            if (Math.round(anchorPosX) !== ReplayDrawer.rCanvasAnchorPoint.x || Math.round(anchorPosY) !== ReplayDrawer.rCanvasAnchorPoint.y)
            {
                loadCameraFromAnchor();
            }

            const nowMs:int = getTimer();
            const deltaMs:Number = Math.min(Math.max(0, nowMs - lastCameraStepTimeMs), MAX_DT_MS);
            lastCameraStepTimeMs = nowMs;
            computeUpcomingCursorRegion();
            updateCameraZoom(ReplayState.isReplayStarted, false, deltaMs);
            updateCameraTargetFromFocus();

            if (!isShortExcursionIgnored)
            {
                keepCursorInSafeZone();
            }

            const followRatio:Number = 1 - Math.exp(-deltaMs / CAMERA_TAU_MS);
            anchorPosX += (anchorTargetX - anchorPosX) * followRatio;
            anchorPosY += (anchorTargetY - anchorPosY) * followRatio;

            if (isCameraSettled())
            {
                anchorPosX = anchorTargetX;
                anchorPosY = anchorTargetY;
            }

            applyCameraToAnchor();
        }

        // 지금 화면 상태와 초점으로 목표를 다시 계산함 (현재 앵커 기준으로 필요한 이동량만큼)
        private function updateCameraTargetFromFocus():void
        {
            const cursor:Point = ReplayDrawCommands.getRCursorPos();
            const view:Rectangle = getCanvasViewRect();
            const canvas:Rectangle = canvasScreenRect();
            const focus:Rectangle = focusScreenRect(cursor);
            anchorTargetX = ReplayDrawer.rCanvasAnchorPoint.x + getAnchorShiftOnAxis(true, focus, view, canvas);
            anchorTargetY = ReplayDrawer.rCanvasAnchorPoint.y + getAnchorShiftOnAxis(false, focus, view, canvas);
        }

        // 커서를 놓치지 않게 안전 구역 밖이면 그 축은 가장자리에 오는 위치까지 즉시 옮김
        // 목표 이동량에 맞춰 자르지 않음 (초점이 영역이면 목표가 커서와 반대 방향일 수 있음). 대신 옮긴 뒤 그 축의 목표를 커서가 안전 구역 안에 남는 범위로 다시 자름
        // 캔버스 경계 규칙(EDGE_MARGIN)이 우선이라 경계 때문에 못 옮기는 만큼은 남음
        private function keepCursorInSafeZone():void
        {
            const cursor:Point = ReplayDrawCommands.getRCursorPos();
            const cursorScreen:Point = canvasToScreen(cursor.x, cursor.y);
            cursorScreen.offset(anchorPosX - ReplayDrawer.rCanvasAnchorPoint.x, anchorPosY - ReplayDrawer.rCanvasAnchorPoint.y); // 화면에 그려진 건 반올림된 앵커 기준이라 소수 위치(pos) 기준으로 맞춤 (안 맞추면 반올림 차이로 경계를 넘나들며 한 칸씩 흔들림)
            const view:Rectangle = getCanvasViewRect();
            const canvas:Rectangle = canvasScreenRect();
            const safeLeft:Number = view.left + SAFETY_PADDING;
            const safeRight:Number = view.right - SAFETY_PADDING;
            const safeTop:Number = view.top + SAFETY_PADDING;
            const safeBottom:Number = view.bottom - SAFETY_PADDING;
            var safeShiftX:Number = 0;
            var safeShiftY:Number = 0;

            if (cursorScreen.x < safeLeft || cursorScreen.x > safeRight)
            {
                safeShiftX = limitShiftByCanvasEdge(cursorScreen.x < safeLeft ? safeLeft - cursorScreen.x : safeRight - cursorScreen.x, view.left, view.right, canvas.left, canvas.right);
            }

            if (cursorScreen.y < safeTop || cursorScreen.y > safeBottom)
            {
                safeShiftY = limitShiftByCanvasEdge(cursorScreen.y < safeTop ? safeTop - cursorScreen.y : safeBottom - cursorScreen.y, view.top, view.bottom, canvas.top, canvas.bottom);
            }

            if (safeShiftX !== 0 || safeShiftY !== 0)
            {
                anchorPosX += safeShiftX;
                anchorPosY += safeShiftY;
                applyCameraToAnchor();
            }

            // 옮긴 뒤(또는 이미 안쪽일 때) 남은 목표 이동이 커서를 안전 구역 밖으로 끌고 가지 않게 자름
            anchorTargetX = anchorPosX + clampShiftToRange(anchorTargetX - anchorPosX, safeLeft - (cursorScreen.x + safeShiftX), safeRight - (cursorScreen.x + safeShiftX));
            anchorTargetY = anchorPosY + clampShiftToRange(anchorTargetY - anchorPosY, safeTop - (cursorScreen.y + safeShiftY), safeBottom - (cursorScreen.y + safeShiftY));
        }

        // 한 축의 이동량이 캔버스 경계 규칙을 넘지 않게 자름. 캔버스가 화면보다 작으면(중앙 고정) 옮기지 않음
        private function limitShiftByCanvasEdge(shift:Number, viewLo:Number, viewHi:Number, canvasLo:Number, canvasHi:Number):Number
        {
            if (canvasHi - canvasLo <= viewHi - viewLo)
            {
                return 0;
            }

            return Math.max(viewHi - EDGE_MARGIN - canvasHi, Math.min(viewLo + EDGE_MARGIN - canvasLo, shift));
        }

        // 이동량을 minShift~maxShift 범위로 자름 (범위가 뒤집혀 있으면 옮기지 않음)
        private function clampShiftToRange(shift:Number, minShift:Number, maxShift:Number):Number
        {
            return (minShift > maxShift) ? 0 : Math.max(minShift, Math.min(maxShift, shift));
        }

        // 실제 앵커 위치를 카메라 위치와 목표로 읽어 들임 (진행 중인 이동은 버림)
        private function loadCameraFromAnchor():void
        {
            anchorPosX = ReplayDrawer.rCanvasAnchorPoint.x;
            anchorPosY = ReplayDrawer.rCanvasAnchorPoint.y;
            anchorTargetX = anchorPosX;
            anchorTargetY = anchorPosY;
        }

        // 카메라의 소수 위치를 반올림해서 실제 앵커에 적용
        private function applyCameraToAnchor():void
        {
            ReplayDrawer.rCanvasAnchorPoint.x = Math.round(anchorPosX);
            ReplayDrawer.rCanvasAnchorPoint.y = Math.round(anchorPosY);
        }

        // 카메라 위치가 목표에 도착했는지
        private function isCameraSettled():Boolean
        {
            return Math.abs(anchorTargetX - anchorPosX) < SETTLED_DIST && Math.abs(anchorTargetY - anchorPosY) < SETTLED_DIST;
        }


        // ---- 미리 읽은 경로로 영역 추적 (3단계) ----

        // 앞으로 REGION_LOOKAHEAD_REAL_MS * 배속 동안의 커서 경로에서 시간 가중 10~90% 영역을 구함
        // 데드존 밖으로 나가는 구간이 EXCURSION_IGNORE_MS보다 짧으면 그 구간은 계산에서 빼고, 지금 커서가 그 안에 있으면 안전 구역 즉시 이동도 하지 않음
        // 그 뒤 ReplayCommandWindow.LOOKAHEAD_REAL_MS * 배속까지의 경로는 다른 영역으로 넘어가는지(A) 판정에만 씀
        // 읽어 둔 경로가 없거나 부족하면 isUpcomingRegionReady=false (커서 한 점 기준으로 되돌아감)
        private function computeUpcomingCursorRegion():void
        {
            isUpcomingRegionReady = false;
            isUpcomingJumpDetected = false;
            upcomingRegionMissReasonCode = "unaligned";
            isShortExcursionIgnored = false;
            const commandWindow:ReplayCommandWindow = ReplayDrawer.commandWindow;
            const nowFrame:Number = ReplayState.rNowFrame;
            const cursor:Point = ReplayDrawCommands.getRCursorPos();
            const view:Rectangle = getCanvasViewRect();
            const canvasOriginGlobal:Point = ReplayDrawer.rCanvasLayer1Bitmap.localToGlobal(new Point(0, 0));
            const rotationRad:Number = ReplayDrawer.rCanvasAnchorPoint.rotation * Math.PI / 180;
            const cos:Number = Math.cos(rotationRad);
            const sin:Number = Math.sin(rotationRad);
            const zoomMultiplier:Number = ReplayState.rCanvasZoomMultiplier;
            const insetX:Number = view.width * DEAD_ZONE_INSET;
            const insetY:Number = view.height * DEAD_ZONE_INSET;
            const zoneLeft:Number = view.left + insetX;
            const zoneRight:Number = view.right - insetX;
            const zoneTop:Number = view.top + insetY;
            const zoneBottom:Number = view.bottom - insetY;

            // 지금 커서가 데드존 밖에 있던 시간 (현재 앵커 기준)
            const cursorScreenX:Number = canvasOriginGlobal.x + (cursor.x * cos - cursor.y * sin) * zoomMultiplier;
            const cursorScreenY:Number = canvasOriginGlobal.y + (cursor.x * sin + cursor.y * cos) * zoomMultiplier;
            const nowOutside:Boolean = cursorScreenX < zoneLeft || cursorScreenX > zoneRight || cursorScreenY < zoneTop || cursorScreenY > zoneBottom;

            if (!nowOutside)
            {
                cursorOutsideDeadZoneSinceMs = -1;
            }
            else if (cursorOutsideDeadZoneSinceMs < 0)
            {
                cursorOutsideDeadZoneSinceMs = getTimer();
            }

            if (!commandWindow.isQueueAlignedWithByte(ReplayState.rFileLastBytePosition) && !ReplayState.rMemoryDataReadON)
            {
                return;
            }

            const speed:Number = Math.max(1, ReplayState.rReplaySpeedMultipler);
            const lookaheadSpanMs:Number = REGION_LOOKAHEAD_REAL_MS * speed;
            const jumpLookaheadSpanMs:Number = ReplayCommandWindow.LOOKAHEAD_REAL_MS * speed;
            const startRecordedMs:Number = ReplayClock.getRecordedTimeOfFrame(nowFrame);
            upcomingCursorPath.length = 0;
            commandWindow.collectCursorPath(nowFrame, nowFrame + ReplayCommandWindow.LOOKAHEAD_MAX_FRAMES, upcomingCursorPath);

            // 프레임/묶음 상한 때문에 목표 시간(span)만큼 못 봤으면 영역이 실제보다 작게 나오므로 믿지 않음 (데이터가 끝나서 못 본 경우는 믿음)
            const coveredRecordedMs:Number = ReplayClock.getRecordedTimeOfFrame(Math.min(commandWindow.coveredEndFrame, ReplayState.TOTAL_FRAME)) - startRecordedMs;

            if (!commandWindow.coveredToDataEnd && coveredRecordedMs < lookaheadSpanMs)
            {
                upcomingRegionMissReasonCode = "coverage";
                return;
            }

            // 먼 구간도 끝까지 봤을 때만 A를 판정함 (덜 본 먼 구간은 실제보다 가까워 보여서 믿지 않음)
            const isJumpSpanCovered:Boolean = commandWindow.coveredToDataEnd || coveredRecordedMs >= jumpLookaheadSpanMs;

            // 샘플: 지금 커서 + 앞으로 커서가 바뀌는 지점. 가까운 구간(span 안)은 영역용, 그 뒤 먼 구간은 A 판정용
            regionSampleRecordedMs.length = 0;
            regionSampleX.length = 0;
            regionSampleY.length = 0;
            regionSampleWeightMs.length = 0;
            jumpSampleX.length = 0;
            jumpSampleY.length = 0;
            jumpSampleWeightMs.length = 0;
            regionSampleRecordedMs.push(startRecordedMs);
            regionSampleX.push(cursor.x);
            regionSampleY.push(cursor.y);
            var sampleStride:int = Math.max(1, int(upcomingCursorPath.length / 3 / MAX_PATH_SAMPLES));
            var lastJumpSampleRecordedMs:Number = NaN;

            for (var i:int = 0;i < upcomingCursorPath.length;i += 3 * sampleStride)
            {
                const t:Number = ReplayClock.getRecordedTimeOfFrame(upcomingCursorPath[i]);

                if (t - startRecordedMs > jumpLookaheadSpanMs)
                {
                    break;
                }

                if (t - startRecordedMs > lookaheadSpanMs)
                {
                    // 먼 구간 가중치 = 다음 점까지 머문 녹화 시간 (마지막 점은 아래에서 span 끝까지 채움)
                    if (jumpSampleX.length > 0)
                    {
                        jumpSampleWeightMs.push(Math.max(0, t - lastJumpSampleRecordedMs));
                    }

                    jumpSampleX.push(upcomingCursorPath[i + 1]);
                    jumpSampleY.push(upcomingCursorPath[i + 2]);
                    lastJumpSampleRecordedMs = t;
                    continue;
                }

                regionSampleRecordedMs.push(Math.max(t, regionSampleRecordedMs[regionSampleRecordedMs.length - 1]));
                regionSampleX.push(upcomingCursorPath[i + 1]);
                regionSampleY.push(upcomingCursorPath[i + 2]);
            }

            if (jumpSampleX.length > 0)
            {
                jumpSampleWeightMs.push(Math.max(1, startRecordedMs + jumpLookaheadSpanMs - lastJumpSampleRecordedMs));
            }

            const sampleCount:int = regionSampleRecordedMs.length;

            if (sampleCount < 3)
            {
                upcomingRegionMissReasonCode = "fewSamples";
                return; // 미리 볼 데이터가 부족함
            }

            // 가중치 = 그 위치에 머문 녹화 시간 (마지막 샘플은 span 끝까지, 데이터가 모자라면 아주 짧게)
            const lastSampleEndMs:Number = Math.min(startRecordedMs + lookaheadSpanMs, regionSampleRecordedMs[sampleCount - 1] + 1);

            for (i = 0;i < sampleCount;i++)
            {
                regionSampleWeightMs.push((i + 1 < sampleCount ? regionSampleRecordedMs[i + 1] : lastSampleEndMs) - regionSampleRecordedMs[i]);
            }

            // 데드존 밖 연속 구간의 실제 시간이 EXCURSION_IGNORE_MS보다 짧으면 제외 (구간이 span 끝까지 이어지면 끝을 알 수 없어 제외하지 않음)
            regionSampleOutsideDeadZone.length = sampleCount;

            for (i = 0;i < sampleCount;i++)
            {
                var sampleScreenX:Number = canvasOriginGlobal.x + (regionSampleX[i] * cos - regionSampleY[i] * sin) * zoomMultiplier;
                var sampleScreenY:Number = canvasOriginGlobal.y + (regionSampleX[i] * sin + regionSampleY[i] * cos) * zoomMultiplier;
                regionSampleOutsideDeadZone[i] = sampleScreenX < zoneLeft || sampleScreenX > zoneRight || sampleScreenY < zoneTop || sampleScreenY > zoneBottom;
            }

            var outsideRunStart:int = -1;

            for (i = 0;i <= sampleCount;i++)
            {
                var outside:Boolean = (i < sampleCount) && regionSampleOutsideDeadZone[i];

                if (outside && outsideRunStart < 0)
                {
                    outsideRunStart = i;
                }
                else if (!outside && outsideRunStart >= 0)
                {
                    // 안으로 잠깐 들어왔다 다시 나가면 같은 바깥 이동으로 이음
                    var insideGapMs:Number = 0;
                    var indexAfterGap:int = i;

                    while (indexAfterGap < sampleCount && !regionSampleOutsideDeadZone[indexAfterGap])
                    {
                        insideGapMs += regionSampleWeightMs[indexAfterGap];
                        indexAfterGap++;
                    }

                    if (indexAfterGap < sampleCount && insideGapMs / speed < EXCURSION_GAP_MS)
                    {
                        i = indexAfterGap;
                        continue;
                    }

                    var outsideRunRecordedMs:Number = 0;

                    for (var j:int = outsideRunStart;j < i;j++)
                    {
                        outsideRunRecordedMs += regionSampleWeightMs[j];
                    }

                    var outsideRunRealMs:Number = outsideRunRecordedMs / speed + ((outsideRunStart === 0 && cursorOutsideDeadZoneSinceMs >= 0) ? (getTimer() - cursorOutsideDeadZoneSinceMs) : 0);
                    const runReachesSpanEnd:Boolean = (i === sampleCount);

                    if (!runReachesSpanEnd && outsideRunRealMs < EXCURSION_IGNORE_MS)
                    {
                        for (j = outsideRunStart;j < i;j++)
                        {
                            regionSampleWeightMs[j] = 0;
                        }

                        if (outsideRunStart === 0)
                        {
                            isShortExcursionIgnored = true;
                        }
                    }

                    outsideRunStart = -1;
                }
            }

            // 가중 중앙값 구간: x, y 각각 시간 가중 10%~90% 위치를 영역으로 함 (중앙값은 이 구간 안에 있음)
            var totalWeightMs:Number = 0;

            for (i = 0;i < sampleCount;i++)
            {
                totalWeightMs += regionSampleWeightMs[i];
            }

            if (totalWeightMs <= 0)
            {
                isShortExcursionIgnored = false;

                for (i = 0;i < sampleCount;i++)
                {
                    regionSampleWeightMs[i] = 1;
                }
            }

            const lowX:Number = getWeightedPercentile(regionSampleX, regionSampleWeightMs, REGION_LOW);
            const highX:Number = getWeightedPercentile(regionSampleX, regionSampleWeightMs, REGION_HIGH);
            const lowY:Number = getWeightedPercentile(regionSampleY, regionSampleWeightMs, REGION_LOW);
            const highY:Number = getWeightedPercentile(regionSampleY, regionSampleWeightMs, REGION_HIGH);
            upcomingRegionRect.setTo(lowX, lowY, highX - lowX, highY - lowY);

            // 지금 커서는 항상 영역 안에 둠 (영역 밖 10%를 놓치지 않게). 짧은 바깥 이동으로 무시하는 중이면 넣지 않음
            if (!isShortExcursionIgnored)
            {
                const regionLeft:Number = Math.min(upcomingRegionRect.left, cursor.x);
                const regionTop:Number = Math.min(upcomingRegionRect.top, cursor.y);
                upcomingRegionRect.setTo(regionLeft, regionTop, Math.max(upcomingRegionRect.right, cursor.x) - regionLeft, Math.max(upcomingRegionRect.bottom, cursor.y) - regionTop);
            }

            isUpcomingRegionReady = true;
            upcomingRegionMissReasonCode = "";

            if (isJumpSpanCovered && jumpSampleX.length >= 2)
            {
                detectUpcomingJump(view, zoomMultiplier);
            }
        }

        // A: 먼 구간의 영역(시간 가중 10~90%)이 가까운 영역과 겹치지 않고 중심이 지금 화면 짧은 변의 JUMP_DISTANCE_RATIO 이상 떨어져 있으면 다른 영역으로 넘어가는 것으로 봄
        // 넘어가면 두 영역을 합친 사각형을 upcomingJumpUnionRect에 넣음 (줌아웃해서 둘 다 보여 줌)
        private function detectUpcomingJump(view:Rectangle, zoomMultiplier:Number):void
        {
            const farLeft:Number = getWeightedPercentile(jumpSampleX, jumpSampleWeightMs, REGION_LOW);
            const farRight:Number = getWeightedPercentile(jumpSampleX, jumpSampleWeightMs, REGION_HIGH);
            const farTop:Number = getWeightedPercentile(jumpSampleY, jumpSampleWeightMs, REGION_LOW);
            const farBottom:Number = getWeightedPercentile(jumpSampleY, jumpSampleWeightMs, REGION_HIGH);
            const farRect:Rectangle = new Rectangle(farLeft, farTop, farRight - farLeft, farBottom - farTop);
            const isOverlapping:Boolean = farRect.left <= upcomingRegionRect.right && farRect.right >= upcomingRegionRect.left && farRect.top <= upcomingRegionRect.bottom && farRect.bottom >= upcomingRegionRect.top;
            const centerDistX:Number = (farRect.left + farRect.right - upcomingRegionRect.left - upcomingRegionRect.right) / 2;
            const centerDistY:Number = (farRect.top + farRect.bottom - upcomingRegionRect.top - upcomingRegionRect.bottom) / 2;
            const jumpDistanceCanvasPx:Number = Math.min(view.width, view.height) * JUMP_DISTANCE_RATIO / zoomMultiplier;

            if (isOverlapping || centerDistX * centerDistX + centerDistY * centerDistY < jumpDistanceCanvasPx * jumpDistanceCanvasPx)
            {
                return;
            }

            isUpcomingJumpDetected = true;
            const unionLeft:Number = Math.min(upcomingRegionRect.left, farRect.left);
            const unionTop:Number = Math.min(upcomingRegionRect.top, farRect.top);
            upcomingJumpUnionRect.setTo(unionLeft, unionTop, Math.max(upcomingRegionRect.right, farRect.right) - unionLeft, Math.max(upcomingRegionRect.bottom, farRect.bottom) - unionTop);
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

        // ---- 자동 줌 ----

        // 카메라가 적용하지 않은 배율 변화(창 맞춤, 캡처 복귀 등)면 그 값을 유지 배율로 받아들이고 진행 중인 전환을 멈춤 (다음 틱부터 그 값에서 이어서 움직임)
        // 반환: 외부 배율 변화를 감지했는지 (처음 값 읽기는 제외)
        private function syncZoomIfChangedExternally():Boolean
        {
            const actualZoomMultiplier:Number = ReplayState.rCanvasZoomMultiplier;

            if (isNaN(appliedZoomMultiplier) || Math.abs(actualZoomMultiplier - appliedZoomMultiplier) > 1e-9)
            {
                const isFirstRead:Boolean = isNaN(appliedZoomMultiplier);
                appliedZoomMultiplier = actualZoomMultiplier;
                heldZoomMultiplier = actualZoomMultiplier;
                isZoomMovingToHeldZoom = false;
                zoomInCandidateSinceMs = -1;
                return !isFirstRead;
            }

            return false;
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

        // 상태를 정하고(재생 중일 때만) 배율을 유지 배율(heldZoomMultiplier)로 감쇠시킴. instant면 전환을 바로 끝냄
        // 유지 배율은 항상 맞춤 배율(최소)~getMaxFocusZoom(최대) 안으로 자름 (창 크기나 회전이 바뀌면 범위도 바뀜)
        private function updateCameraZoom(playing:Boolean, instant:Boolean, dt:Number = 0):void
        {
            syncZoomIfChangedExternally();
            const view:Rectangle = getCanvasViewRect();
            const fitZoom:Number = getFitWholeCanvasZoom(view);
            const maxZoom:Number = getMaxFocusZoom(fitZoom);
            heldZoomMultiplier = Math.max(fitZoom, Math.min(heldZoomMultiplier, maxZoom));

            if (playing)
            {
                decideHeldZoom(view, fitZoom, maxZoom);
            }

            const target:Number = heldZoomMultiplier;
            const logDiff:Number = Math.log(target) - Math.log(appliedZoomMultiplier);

            if (instant || Math.abs(logDiff) < ZOOM_SETTLED_LOG)
            {
                const wasMoving:Boolean = isZoomMovingToHeldZoom;
                setZoomKeepingFocus(target);
                isZoomMovingToHeldZoom = false;

                if (wasMoving)
                {
                    finishZoomTransition();
                }

                return;
            }

            isZoomMovingToHeldZoom = true;
            const zoomTauMs:Number = (logDiff < 0) ? ZOOM_OUT_TAU_MS : ZOOM_IN_TAU_MS;
            setZoomKeepingFocus(Math.exp(Math.log(appliedZoomMultiplier) + logDiff * (1 - Math.exp(-dt / zoomTauMs))));
        }

        // 지금 전체 보기(맞춤 배율)를 강제하는 계기가 있는지. B(캔버스 전체 명령 직후), C(처음 시작 직후), D(고배속)
        // D는 OVERVIEW_SPEED_IN 이상에서 켜지고 OVERVIEW_SPEED_OUT 미만에서 꺼짐
        private function isOverviewForcedNow():Boolean
        {
            const speed:Number = ReplayState.rReplaySpeedMultipler;

            if (speed >= OVERVIEW_SPEED_IN)
            {
                isSpeedOverviewOn = true;
            }
            else if (speed < OVERVIEW_SPEED_OUT)
            {
                isSpeedOverviewOn = false;
            }

            const now:int = getTimer();
            return isSpeedOverviewOn || now < startOverviewUntilMs || now - ReplayState.lastCanvasWideCommandTimeMs < CANVAS_WIDE_OVERVIEW_MS;
        }

        // 지금 상황에서 유지하려는 배율(heldZoomMultiplier)을 정함
        // 줌아웃 목표(바로 따라감): 전체 보기 계기가 있으면 맞춤 배율, 아니면 영역(연출 영역 > A면 합친 영역 > 집중 영역)이 화면의 FOCUS_KEEP_RATIO에 들어가는 배율
        // 줌인 후보(ZOOM_IN_DWELL_MS 확인 필요): 영역이 화면의 FOCUS_FRAMING_RATIO를 차지하는 배율. 영역 정보가 없으면 지금 배율 유지
        private function decideHeldZoom(view:Rectangle, fitZoom:Number, maxZoom:Number):void
        {
            const animArea:Rectangle = ReplayDrawer.anim.animFocusRect;
            var zoomOutTarget:Number;
            var zoomInCandidate:Number;

            if (isOverviewForcedNow())
            {
                zoomOutTarget = fitZoom;
                zoomInCandidate = fitZoom;
            }
            else if (animArea !== null || isUpcomingRegionReady)
            {
                const region:Rectangle = (animArea !== null) ? animArea : (isUpcomingJumpDetected ? upcomingJumpUnionRect : upcomingRegionRect);
                const regionFillZoom:Number = getRegionFillZoom(region, view);
                zoomOutTarget = Math.max(fitZoom, Math.min(regionFillZoom * FOCUS_KEEP_RATIO, maxZoom));
                zoomInCandidate = isUpcomingJumpDetected ? zoomOutTarget : Math.max(fitZoom, Math.min(regionFillZoom * FOCUS_FRAMING_RATIO, maxZoom)); // 넘어가는 중에는 합친 영역보다 더 들어가지 않음
            }
            else
            {
                zoomOutTarget = heldZoomMultiplier;
                zoomInCandidate = heldZoomMultiplier;
            }

            if (zoomOutTarget < heldZoomMultiplier)
            {
                heldZoomMultiplier = zoomOutTarget; // 더 낮춰야 하면 바로 따라감
                zoomInCandidateSinceMs = -1;
                return;
            }

            // 올리는 후보는 줌아웃이 끝나 유지 배율에 도착한 뒤부터 셈 (줌아웃 중에 쌓인 시간으로 끝나자마자 줌인하지 않게)
            const hasArrivedAtHeldZoom:Boolean = !isZoomMovingToHeldZoom && Math.abs(Math.log(heldZoomMultiplier) - Math.log(appliedZoomMultiplier)) < ZOOM_SETTLED_LOG;

            if (!hasArrivedAtHeldZoom || zoomInCandidate <= heldZoomMultiplier * (1 + ZOOM_SETTLED_LOG))
            {
                zoomInCandidateSinceMs = -1;
                return;
            }

            const now:int = getTimer();

            if (zoomInCandidateSinceMs < 0)
            {
                zoomInCandidateSinceMs = now;
            }
            else if (now - zoomInCandidateSinceMs >= ZOOM_IN_DWELL_MS)
            {
                heldZoomMultiplier = zoomInCandidate; // 그 시점의 값으로 올림
                zoomInCandidateSinceMs = -1;
            }
        }

        // 초점(연출 영역 중심 또는 커서)의 화면 위치가 변하지 않게 배율을 바꾸고 앵커를 보정함
        // 정보 상자 갱신은 하지 않음 (finishZoomTransition에서 한 번만). 예전 형식 에어브러시 블러는 화면 픽셀 기준이라 배율이 바뀔 때마다 다시 넣음 (필터 값만 바꾸는 것이라 가벼움)
        private function setZoomKeepingFocus(newZoomMultiplier:Number):void
        {
            if (newZoomMultiplier === appliedZoomMultiplier)
            {
                return;
            }

            const cursor:Point = ReplayDrawCommands.getRCursorPos();
            const area:Rectangle = ReplayDrawer.anim.animFocusRect;
            const focusCanvasX:Number = (area === null) ? cursor.x : area.x + area.width / 2;
            const focusCanvasY:Number = (area === null) ? cursor.y : area.y + area.height / 2;
            const before:Point = canvasToScreen(focusCanvasX, focusCanvasY);
            ReplayState.rCanvasZoomMultiplier = newZoomMultiplier;
            ReplayDrawer.rCanvasAnchorPoint.scaleX = newZoomMultiplier;
            ReplayDrawer.rCanvasAnchorPoint.scaleY = newZoomMultiplier;
            ReplayDrawer.updateReplayCursorScale(newZoomMultiplier);

            if (ReplayState.rAirBrushSize > 0)
            {
                ReplayDrawer.blurReplayCanvasByValue(ReplayState.rAirBrushSize);
            }

            const after:Point = canvasToScreen(focusCanvasX, focusCanvasY);
            anchorPosX = ReplayDrawer.rCanvasAnchorPoint.x + before.x - after.x;
            anchorPosY = ReplayDrawer.rCanvasAnchorPoint.y + before.y - after.y;
            applyCameraToAnchor();
            appliedZoomMultiplier = newZoomMultiplier;

            // 배율이 커지면서 큰 캔버스의 가장자리가 화면 안쪽으로 들어왔으면 바로 되돌림 (이동 감쇠를 기다리면 그 사이 경계를 넘음)
            const view:Rectangle = getCanvasViewRect();
            const canvas:Rectangle = canvasScreenRect();
            anchorPosX += (canvas.width > view.width) ? Math.max(view.right - EDGE_MARGIN - canvas.right, Math.min(view.left + EDGE_MARGIN - canvas.left, 0)) : 0;
            anchorPosY += (canvas.height > view.height) ? Math.max(view.bottom - EDGE_MARGIN - canvas.bottom, Math.min(view.top + EDGE_MARGIN - canvas.top, 0)) : 0;
            anchorTargetX = anchorPosX;
            anchorTargetY = anchorPosY;
            applyCameraToAnchor();
        }

        // 전환이 끝났을 때 한 번만 하는 갱신
        private function finishZoomTransition():void
        {
            UIController.canvasInfoBox.setZoom(appliedZoomMultiplier);
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
            const canvasBounds:Object = Utils.getBoundRect(ReplayDrawer.rCanvasLayer1Bitmap);
            return new Rectangle(canvasBounds.left, canvasBounds.top, canvasBounds.right - canvasBounds.left, canvasBounds.bottom - canvasBounds.top);
        }

        // 카메라가 따라갈 초점의 화면 사각형: 연출 영역이 있으면 그 영역, 없으면 커서 한 점
        private function focusScreenRect(cursor:Point):Rectangle
        {
            const area:Rectangle = ReplayDrawer.anim.animFocusRect;

            if (area === null && !isUpcomingRegionReady)
            {
                const cursorScreenPos:Point = canvasToScreen(cursor.x, cursor.y);
                return new Rectangle(cursorScreenPos.x, cursorScreenPos.y, 0, 0);
            }

            const target:Rectangle = (area === null) ? upcomingRegionRect : area;
            const corners:Array = [canvasToScreen(target.left, target.top), canvasToScreen(target.right, target.top), canvasToScreen(target.left, target.bottom), canvasToScreen(target.right, target.bottom)];
            var minX:Number = corners[0].x;
            var maxX:Number = minX;
            var minY:Number = corners[0].y;
            var maxY:Number = minY;

            for each (var corner:Point in corners)
            {
                minX = Math.min(minX, corner.x);
                maxX = Math.max(maxX, corner.x);
                minY = Math.min(minY, corner.y);
                maxY = Math.max(maxY, corner.y);
            }

            return new Rectangle(minX, minY, maxX - minX, maxY - minY);
        }

        // 한 축에서 앵커를 옮길 양: 초점을 데드존 안에 두고, 캔버스 경계 규칙으로 자름
        private function getAnchorShiftOnAxis(isX:Boolean, focus:Rectangle, view:Rectangle, canvas:Rectangle):Number
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
