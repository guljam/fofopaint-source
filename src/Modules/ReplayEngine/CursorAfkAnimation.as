package Modules.ReplayEngine
{
    import Symbols.FOFOCursorSet;

    import flash.utils.getTimer;

    // 리플레이가 쉬는(AFK) 구간을 기다리는 동안 리플레이 커서(fofocursor)에 주는 연출 모음. AFK에 들어갈때마다 종류를 균등하게 하나 고르고, 그 종류의 변형 중 하나를 고름
    //   0 회전 (한바퀴 도는 시간 3가지), 1 흔들림 (시계, 반시계 방향 흔들림 주기 3가지), 2 점프 (높이와 주기 3가지),
    //   3 늘어짐 (가로, 세로, 대각선 2가지 방향), 4 커짐 (속도 3가지), 5 심장 박동 (크기와 주기 3가지)
    // 모든 속도, 크기, 주기는 아래 상수에 모아두었음. 값을 바꿔서 직접 확인할때는 Utils.testFoFoCursorAnim을 부르면 됨
    // 연출은 커서 안쪽 레이어(FOFOCursorSet.setPose)에만 주므로 바깥의 위치, 줌 보정, 캔버스 회전 상쇄와 섞이지 않음
    // 이 클래스는 ReplayController가 시작, 정지를 부르는 곳과 Utils의 테스트 함수 외에는 아무것도 모름
    public final class CursorAfkAnimation
    {
        // ---- 공통
        public static const RETURN_MS:Number = 200; // AFK가 끝난 뒤 원래 모양으로 감속(ease-out)하며 돌아가는 시간, 0이면 바로 돌아감
        public static const BLEND_IN_MS:Number = 100; // 연출이 시작할때 직전 모양에서 연출 모양으로 이어지는 시간 (복귀 도중에 다시 시작해도 튀지 않게)
        public static const MAX_AFK_SECONDS:Number = 5; // AFK가 가장 길게 이어지는 시간(초), 점점 변하는 연출의 최대 크기를 미리 계산해서 AFK 상자 위치를 정하는데 씀

        // ---- 시험용 고정 선택 (-1이면 무작위). Utils.testFoFoCursorAnim이 바꿈
        public static var forceKind:int = -1;
        public static var forceVariant:int = -1;

        // ---- 0 회전: 한바퀴 도는 시간(ms), 시계 방향. 24fps에서는 250ms보다 짧으면 떨리는 것처럼 보일 수 있음
        public static const SPIN_TURN_MS:Vector.<Number> = new <Number>[100, 400, 900];

        // ---- 1 흔들림: 몸통 중심을 축으로 시계, 반시계 방향으로 번갈아 흔들리는 각도(도)와 한번 오가는 주기(ms)
        public static const SHAKE_AMPLITUDE_DEG:Number = 20;
        public static const SHAKE_PERIOD_MS:Vector.<Number> = new <Number>[300, 600, 1000];

        // ---- 2 점프: 위로 뛰어오르는 높이(커서 좌표 px, 화면에서 일정한 크기)와 한번 뛰는 시간(ms), 포물선(2차 함수)으로 올라갈때 감속, 내려올때 가속
        public static const JUMP_HEIGHT_PX:Vector.<Number> = new <Number>[16, 26, 38];
        public static const JUMP_PERIOD_MS:Vector.<Number> = new <Number>[450, 650, 900];

        // ---- 3 늘어짐: 늘어나는 방향(도, 화면 기준 0 = 가로, 90 = 세로, 45와 135 = 대각선) 4가지
        //      한 방향으로 계속 늘어나고 AFK가 끝나면 원래대로 돌아옴. 늘어나는 배율 = 1 + 속도 * 경과 초, 최대 STRETCH_MAX배
        public static const STRETCH_DIRECTION_DEG:Vector.<Number> = new <Number>[0, 90, 45, 135];
        public static const STRETCH_RATE_PER_SEC:Number = 0.5;
        public static const STRETCH_MAX:Number = 3.5;

        // ---- 4 커짐: 몸통 중심에서 서서히 커짐. 배율 = 1 + 속도 * 경과 초, 최대 GROW_MAX배
        public static const GROW_RATE_PER_SEC:Vector.<Number> = new <Number>[0.1, 0.18, 0.26];
        public static const GROW_MAX:Number = 2.2;

        // ---- 5 심장 박동: 몸통 중심에서 두번 연달아 뛰고(쿵쿵) 쉬는 리듬. 커지는 정도와 한 박동 주기(ms), 쉴때 줄어드는 정도
        public static const HEART_BEAT_AMPLITUDE:Vector.<Number> = new <Number>[0.2, 0.3, 0.4];
        public static const HEART_PERIOD_MS:Vector.<Number> = new <Number>[1100, 850, 650];
        public static const HEART_REST_SHRINK:Number = 0.08;

        private static const KIND_SPIN:int = 0;
        private static const KIND_SHAKE:int = 1;
        private static const KIND_JUMP:int = 2;
        private static const KIND_STRETCH:int = 3;
        private static const KIND_GROW:int = 4;
        private static const KIND_HEART:int = 5;
        private static const KIND_COUNT:int = 6;
        private static const TIMER_NAME:String = "replayCursorAfkAnimTimer";

        private static const MODE_IDLE:int = 0;
        private static const MODE_RUNNING:int = 1;
        private static const MODE_RETURNING:int = 2;

        // 지금 커서에 적용된 모양 (회전각은 도, 늘어지는 축각은 도, 이동은 커서 좌표 px)
        private static var spin:Number = 0;
        private static var scaleX:Number = 1;
        private static var scaleY:Number = 1;
        private static var axis:Number = 0;
        private static var offsetX:Number = 0;
        private static var offsetY:Number = 0;

        private static var mode:int = MODE_IDLE;
        private static var kind:int = 0;
        private static var variant:int = 0;
        private static var startTime:int = 0;
        private static var startSpin:Number = 0;
        private static var fromSpin:Number = 0, fromScaleX:Number = 1, fromScaleY:Number = 1, fromAxis:Number = 0, fromOffsetX:Number = 0, fromOffsetY:Number = 0;

        // 연출을 시작함. 이미 하고 있으면 그대로 두고, 복귀 중이면 지금 모양에서 이어서 시작함
        // 반환값: AFK 상자가 연출이 닿는 범위 바깥에 놓이도록 알려주는 {scaleFactor: 몸통이 커지는 최대 배율, extraUp: 위로 더 올라가는 최대 거리(px)}
        public static function start():Object
        {
            if (mode === MODE_RUNNING)
            {
                return extentsOf(kind, variant);
            }

            kind = (forceKind >= 0 && forceKind < KIND_COUNT) ? forceKind : int(Math.random() * KIND_COUNT);
            const count:int = variantCount(kind);
            variant = (forceVariant >= 0 && forceVariant < count) ? forceVariant : int(Math.random() * count);
            startTime = getTimer();
            startSpin = normalizeAngle(spin);
            captureFrom();
            mode = MODE_RUNNING;
            FOFOTimer.addByName(TIMER_NAME, 0.0, true, tick);
            return extentsOf(kind, variant);
        }

        // 연출을 끝내고 원래 모양으로 돌아감. 하고 있지 않았으면 false
        public static function stop():Boolean
        {
            if (mode !== MODE_RUNNING)
            {
                return false;
            }

            if (RETURN_MS <= 0 || !cursor.visible)
            {
                reset();
                return true;
            }

            spin = normalizeAngle(spin);
            captureFrom();
            startTime = getTimer();
            mode = MODE_RETURNING;
            return true;
        }

        // 지금 커서에 적용된 모양 (확인, 시험용)
        public static function get currentPose():Object
        {
            return {spin: spin, scaleX: scaleX, scaleY: scaleY, axis: axis, offsetX: offsetX, offsetY: offsetY, kind: kind, variant: variant, mode: mode};
        }

        public static function get isRunning():Boolean
        {
            return mode === MODE_RUNNING;
        }

        // 시험용: 지정한 연출을 seconds초 동안 커서에 보여준 뒤 멈춤 (kind, variant가 -1이면 무작위). 리플레이 모드에서 쓰는 것을 전제로 함
        public static function test(testKind:int, testVariant:int, seconds:Number):void
        {
            forceKind = testKind;
            forceVariant = testVariant;
            cursor.visible = true;
            reset();
            const extents:Object = start();
            trace("CursorAfkAnimation test: kind=" + kind + " variant=" + variant + " scaleFactor=" + extents.scaleFactor + " extraUp=" + extents.extraUp);
            FOFOTimer.addByName(TIMER_NAME + "Test", seconds, false, function ():void
                {
                    forceKind = -1;
                    forceVariant = -1;
                    stop();
                });
        }

        private static function get cursor():FOFOCursorSet
        {
            return ReplayDrawer.rReplayFOFOCursor;
        }

        private static function variantCount(forKind:int):int
        {
            switch (forKind)
            {
                case KIND_SPIN:
                    return SPIN_TURN_MS.length;
                case KIND_SHAKE:
                    return SHAKE_PERIOD_MS.length;
                case KIND_JUMP:
                    return JUMP_HEIGHT_PX.length;
                case KIND_STRETCH:
                    return STRETCH_DIRECTION_DEG.length;
                case KIND_GROW:
                    return GROW_RATE_PER_SEC.length;
                default:
                    return HEART_BEAT_AMPLITUDE.length;
            }
        }

        // 연출이 몸통을 키우는 최대 배율과 위로 더 올라가는 최대 거리 (AFK는 MAX_AFK_SECONDS를 넘지 않으므로 그 시점의 값). 늘어짐은 제외
        private static function extentsOf(forKind:int, forVariant:int):Object
        {
            var factor:Number = 1;
            var up:Number = 0;

            // 늘어짐(KIND_STRETCH)은 상자를 옮기지 않고 기본 간격(AFK_BOX_GAP)에 고정함 (늘어나는 몸통이 상자와 겹쳐도 괜찮음)
            if (forKind === KIND_JUMP)
            {
                up = JUMP_HEIGHT_PX[forVariant];
            }
            else if (forKind === KIND_GROW)
            {
                factor = Math.min(GROW_MAX, 1 + GROW_RATE_PER_SEC[forVariant] * MAX_AFK_SECONDS);
            }
            else if (forKind === KIND_HEART)
            {
                factor = 1 + HEART_BEAT_AMPLITUDE[forVariant];
            }

            return {scaleFactor: factor, extraUp: up};
        }

        private static function captureFrom():void
        {
            fromSpin = spin;
            fromScaleX = scaleX;
            fromScaleY = scaleY;
            fromAxis = axis;
            fromOffsetX = offsetX;
            fromOffsetY = offsetY;
        }

        // -180 ~ 180도로 맞춤 (원래 각도로 돌아갈때 가까운 방향으로 가도록)
        private static function normalizeAngle(angle:Number):Number
        {
            var a:Number = angle % 360;

            if (a > 180)
            {
                a -= 360;
            }
            else if (a <= -180)
            {
                a += 360;
            }

            return a;
        }

        private static function reset():void
        {
            FOFOTimer.remove(TIMER_NAME);
            mode = MODE_IDLE;
            spin = 0;
            scaleX = 1;
            scaleY = 1;
            axis = 0;
            offsetX = 0;
            offsetY = 0;
            apply();
        }

        private static function apply():void
        {
            cursor.setPose(spin, scaleX, scaleY, axis, offsetX, offsetY);
        }

        // 매 프레임 불림: 연출 중이면 경과 시간으로 모양을 구하고, 복귀 중이면 감속하며 원래 모양으로 돌림
        private static function tick():Boolean
        {
            if (!cursor.visible)
            {
                reset();
                return false;
            }

            const elapsed:Number = getTimer() - startTime;

            if (mode === MODE_RETURNING)
            {
                const t:Number = elapsed / RETURN_MS;

                if (t >= 1)
                {
                    reset();
                    return false;
                }

                const rest:Number = (1 - t) * (1 - t); // 남은 비율 (ease-out)
                spin = fromSpin * rest;
                scaleX = 1 + (fromScaleX - 1) * rest;
                scaleY = 1 + (fromScaleY - 1) * rest;
                offsetX = fromOffsetX * rest;
                offsetY = fromOffsetY * rest;
                axis = fromAxis;
                apply();
                return true;
            }

            computePose(elapsed);
            apply();
            return true;
        }

        // 연출 시작 후 elapsed ms 시점의 모양을 구해서 지금 모양(spin, scale, axis, offset)에 넣음
        private static function computePose(elapsed:Number):void
        {
            var targetSpin:Number = 0;
            var targetScaleX:Number = 1;
            var targetScaleY:Number = 1;
            var targetAxis:Number = 0;
            var targetOffsetY:Number = 0;
            const seconds:Number = elapsed / 1000;

            switch (kind)
            {
                case KIND_SPIN:
                    // 회전은 직전 각도에서 이어서 돎 (복귀 도중에 다시 시작해도 각도가 튀지 않음)
                    targetSpin = startSpin + elapsed * 360 / SPIN_TURN_MS[variant];
                    break;
                case KIND_SHAKE:
                    targetSpin = SHAKE_AMPLITUDE_DEG * Math.sin(2 * Math.PI * elapsed / SHAKE_PERIOD_MS[variant]);
                    break;
                case KIND_JUMP:
                    // 포물선: 0에서 올라갈때 감속, 꼭대기에서 0, 내려올때 가속. u는 한번 뛰는 시간 안에서의 진행 비율
                    const u:Number = (elapsed % JUMP_PERIOD_MS[variant]) / JUMP_PERIOD_MS[variant];
                    targetOffsetY = -JUMP_HEIGHT_PX[variant] * 4 * u * (1 - u);
                    break;
                case KIND_STRETCH:
                    targetAxis = STRETCH_DIRECTION_DEG[variant];
                    targetScaleX = Math.min(STRETCH_MAX, 1 + STRETCH_RATE_PER_SEC * seconds); // 축 방향으로만 늘어남
                    break;
                case KIND_GROW:
                    targetScaleX = Math.min(GROW_MAX, 1 + GROW_RATE_PER_SEC[variant] * seconds);
                    targetScaleY = targetScaleX;
                    break;
                default:
                    targetScaleX = heartScale(elapsed);
                    targetScaleY = targetScaleX;
                    break;
            }

            // 시작 직후에는 직전 모양에서 연출 모양으로 이어서 감 (회전 연출의 각도는 이미 이어서 계산해서 섞지 않음)
            const w:Number = Math.min(1, elapsed / BLEND_IN_MS);
            spin = (kind === KIND_SPIN) ? targetSpin : fromSpin * (1 - w) + targetSpin * w;
            scaleX = fromScaleX * (1 - w) + targetScaleX * w;
            scaleY = fromScaleY * (1 - w) + targetScaleY * w;
            axis = (kind === KIND_STRETCH) ? targetAxis : (w < 1 ? fromAxis : 0);
            offsetX = 0;
            offsetY = fromOffsetY * (1 - w) + targetOffsetY * w;
        }

        // 쿵쿵 두번 뛰고 쉬는 박동의 배율. 한 주기 안에서 두 박동(둘째는 70% 크기)이 코사인 곡선으로 뛰고 나머지는 약간 줄어든 상태
        private static function heartScale(elapsed:Number):Number
        {
            const amplitude:Number = HEART_BEAT_AMPLITUDE[variant];
            const u:Number = (elapsed % HEART_PERIOD_MS[variant]) / HEART_PERIOD_MS[variant];
            const beat:Number = Math.max(bump(u, 0.12, 0.12), 0.7 * bump(u, 0.34, 0.12));
            return 1 - HEART_REST_SHRINK + (amplitude + HEART_REST_SHRINK) * beat;
        }

        // 중심 center에서 1이고 중심에서 width만큼 떨어지면 0이 되는 부드러운 봉우리
        private static function bump(u:Number, center:Number, width:Number):Number
        {
            const d:Number = Math.abs(u - center);

            if (d >= width)
            {
                return 0;
            }

            const c:Number = Math.cos(Math.PI / 2 * d / width);
            return c * c;
        }
    }
}
