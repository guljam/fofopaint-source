# realtime2 브랜치 정적 분석 검토 (b711c268 → 17f255dc)

- 검토일: 2026-10-06
- 범위: `b711c268a3b0f17d8584b50f42023699df9aa38f`..`17f255dc4d431187d28df6ce7f51d3e0491558b5` (커밋 22개, 파일 25개, +3165 / −42)
- 신규 파일: `ReplayAnim.as`, `ReplayClock.as`, `CursorAfkAnimation.as`, `TimingSheet.as`, `TimingSheetFile.as`, `TimingSmoother.as`
- 수정 파일(주요): `ReplayController.as`, `ReplayDrawer.as`, `ReplayDrawCommands.as`, `ReplayState.as`, `FOFOCursorSet.as`, `SeekBarSet.as`, `AppStateManager.as`, `FileManager.as`, `UndoHistory.as`, `UndoController.as`, `Tools/*`, `Utils.as`
- 이 문서는 **검토 기록만**입니다. 소스 코드는 수정하지 않았습니다(제안 코드는 "적용 안 함").

## 0. 검토 방법과 근거 등급

| 등급 | 의미 |
|---|---|
| [실행] | AIR SDK(51.3.4)로 헤드리스 하네스를 컴파일/실행해 확인 (`test-output/rt2-review`, 170개 체크 전부 통과, 부록 A) |
| [근거] | 소스 코드 인용 (`파일:라인`). 라인 번호는 커밋 `17f255d` 기준 |
| [추론] | 코드만으로 확정 불가(렌더/실기기 확인 필요) — 6장에 별도 정리 |

검토 순서: 변경 전문 정독 → 심볼 참조 전수 grep(호출/미호출 판정) → 값 계산·I/O 경로는 하네스로 실행 검증 → 의심 항목마다 "정상 동작할 수 있는 조건"을 찾아 반증 시도(5장).

이 문서는 1차 검토 직후 **2차 리뷰(외부 리뷰어)** 를 받아 항목별로 재검증했고, 그 결과를 반영해 갱신했습니다. 2차 리뷰 지적 중 사실로 확인된 것(R9 검증 방식 오류, R4 방어 코드의 핸들 누수/도달 불가 가드, R5 필요성 미입증, 문서의 "미커밋" 표기 오류)은 되돌리거나 다시 고쳤고, 사실과 다른 것(src 11개 파일 → 실제 10개, 스타일 출처)은 판정 근거와 함께 정정했습니다. 아래 2.6은 1차 검토 당시의 작업 트리 상태 기록입니다.

## 1. 결론 요약

### 1.1 수정 반영 상태 (2026-10-06 갱신)

| 항목 | 상태 | 근거 |
|---|---|---|
| R1 | **수정 완료** (`404615e` + 2차 잔여 수정) | `clearAfkState()` 단일화 + 재시작 조건 + **연출 재시작 시 상자 위치 재계산**(2차) (2장 R1) |
| R2 | **수정 완료** (`560728f` + `15f4242`) — 검토 통과 | 슬라이드쇼 경로 정리 + `anim.clear()`를 가드 밖으로 + 전환 시 `clearAfkState()` (2장 R2) |
| R3 | **제외**(반증 성공) | 호출 2곳 모두 직후 버퍼를 비움 (5장 14번) |
| R4 | **되돌림**(리뷰 2차) | 방어 코드 제거 — 예외는 그대로 전파(fail-fast). 사유는 2장 R4 |
| R5 | **되돌림**(리뷰 2차) | 필요성 미입증(조회 1회 ≈0.5ms, 프레임 41ms) → 색인 제거 (2장 R5) |
| R6 | **수정 완료** (`7580229`) | 중복 `refreshAfkRanges()` 제거, 갱신 1회 (2장 R6) |
| R7 | **수정 완료** (`e1c7aa2`) — 검토 통과 | `memory === null`, 컴파일 경고 0 (2장 R7) |
| R8 | **수정 완료** — 주석/문서 4건 정정 | 2장 R8 |
| R9 | **수정 완료**(2차, `793ab95`는 커서만) | 종료 프레임을 **한 프레임 렌더**한 뒤 덮개 정리 (2장 R9) |
| B | **정리 완료**(2차) | `MAX_AFK_SECONDS`·`toTimes`·`INFO_*`·`findSegment*`·`isArmed` 삭제, 작동 중인 하네스가 쓰는 심볼만 '테스트 전용' 표시 | 3장 |

### 1.2 검토 시점(`17f255d`) 결론 요약

| ID | 심각도 | 위치 | 요약 | 상태 |
|---|---|---|---|---|
| R1 | 중 | `ReplayController.as:532` `:1013` `:1438` | 시크바 드래그로 AFK(쉬는 구간) 중단 시 `isAfkBoxShown` 상태가 어긋나, 같은 구간으로 되돌아오면 afk 상자만 뜨고 커서 연출이 재개되지 않음 | 수정 완료(404615e) |
| R2 | 하 | `ReplayController.as:356` + `ReplayDrawer.as:315` | 슬라이드쇼 모드에서 AFK 연출을 시작하자마자 매 틱 취소(상자는 남음) | 부분 수정(560728f) + 회귀 R2-a |
| R4 | 하 | `ReplayClock.as:394` (`loadSegment`) | 타이밍 파일이 없을 때 `segmentStart[segment]` 범위 밖 접근 가능성 | 반증 성공(5.4) — 방어 코드만 제안 |
| R5 | 하(성능) | `ReplayClock.as:347` → `TimingSheetFile.as:298` | 재생 중 line4(선 도구) 명령마다 점 시각 파일을 처음부터 선형 탐색 | 코드 경로 확정(2차에서 되돌림) |
| R6 | 하(중복) | `ReplayController.as:97-121` | 배속 클램프 시 `refreshAfkRanges()`가 시크바를 두 번 다시 그림 | 코드 경로 확정 |
| R7 | 정보 | `ReplayClock.as:358` | `memory === undefined`는 타입상 항상 거짓(컴파일러 경고 확인) | 수정 완료(e1c7aa2) |
| R8 | 정보 | `prepareFrameAnim` 주석 등 4건 | 주석/문서가 코드와 불일치 | 코드 근거 확정 |
| R9 | 하 | `ReplayAnim.as:384` `:495` | 이동 연출이 끝날 때 최종 오프셋을 적용하지 않고 `clear()` → 짧은 연출에서 커서/복제 이미지가 몇 px 어긋난 상태로 사라짐 | 코드 근거 + 계산 |
| B | 정보 | 3장 표 | 데드 코드 16건 | 참조 0회 grep |
| — | — | 5장 | 반증 성공(문제 아님) 14건 (R3 포함) | [실행]/[근거] |

데이터 손상·예외로 이어지는 버그는 발견하지 못했습니다. 새로 들어온 타이밍 시트 저장/불러오기, AFK 시간 계산, 축(시크바) 변환은 실행 검증까지 통과했습니다(부록 A).

## 2. 버그 위험 상세

### R1. 시크바 드래그 경로에서 AFK 상자/연출 상태 불일치 (중)

**수정 반영(커밋 `404615e`) — 검토 통과.** `clearAfkState()`(`ReplayController.as:1013-1023`)로 정리를 단일화하고 `onDragStart`(`:540`)·`stopReplay`(`:1458`)에서 부르며, `updateAfkState`는 `!isAfkBoxShown || !CursorAfkAnimation.isRunning`(`:1034`)일 때 연출을 (재)시작합니다. 제안한 형태와 같고, 전체 앱 컴파일(`src/Main.as`, strict+warnings)은 오류 0 / 경고 0입니다. 2차 리뷰 반영: ① 연출이 취소됐다가 다시 시작하면 `CursorAfkAnimation.start()`가 종류를 새로 고르는데 상자는 처음 범위로만 놓이던 문제 → `showAfkBox`를 `if (!isAfkBoxShown)` 밖으로 옮겨 **재시작 때도 새 `extents`로 상자 위치를 다시 잡음**(`ReplayController.as:1031-1045`). ② `onDragStart`의 호출은 재생 중일 때만 실행되는데 상자는 재생 중에만 표시되므로 미정리 상태가 도달하지 않음. ③ `isAfk`가 참인데 커서가 숨겨진 상태가 되면 `tick()`이 `reset()`(mode=IDLE) 하므로 `updateAfkState`가 매 틱 `start()`를 다시 부를 수 있음 — 현재 흐름에서는 도달하지 않지만, 원하면 조건에 커서 표시 여부를 하나 더 두면 안전합니다.

아래는 수정 전 분석 기록입니다.

증상: 재생 중 AFK 대기에서 시크바를 잡아 끌었다가 **같은 쉬는 구간 안**으로 놓으면, "afk" 상자는 보이는데 커서 연출(회전/흔들림 등)은 이미 복귀한 자세로 굳어 있고 그 구간이 끝날 때까지 다시 시작되지 않습니다.

발생 경로:

1. 재생 중 쉬는 구간 진입 → `updateAfkState()`가 `CursorAfkAnimation.start()` + `showAfkBox()`, `isAfkBoxShown = true` (`ReplayController.as:1013-1035`).
2. 사용자가 시크바를 잡음 → `onDragStart()` (`ReplayController.as:532-548`)는 `isReplayStarted = false`, `replayDrawTimer`/`prograssBarUpdateTimer` 제거만 하고 **`stopReplay()`를 부르지 않음** → `hideAfkBox()`/`isAfkBoxShown` 정리 없음.
3. 드래그 중 `onMouseMove()`(`:550-561`) → `ReplayDrawer.renderReplayFrame(..., JUMP_FRAME_MANUAL)` → `CursorAfkAnimation.stop()`만 호출(`ReplayDrawer.as:315`), `hideAfkBox()`는 호출되지 않음 → 상자는 화면에 남고 `isAfkBoxShown`도 `true` 유지.
4. 같은 쉬는 구간 안에서 손을 떼고 재생 재개(`onMouseUp` → `startReplay`, `:563-587`) → 다음 틱 `ReplayClock.frameCountDue`가 다시 `isAfk = true`로 만드는데, `updateAfkState()`는 `if (!isAfkBoxShown)` 조건(`:1027`) 때문에 `CursorAfkAnimation.start()`를 다시 부르지 않음 → 상자만 표시되고 연출은 없음.

반증 시도:

- (a) "드래그가 상자를 숨긴다" → `onDragStart`/`renderReplayFrame` 어디에도 `hideAfkBox()` 없음 → 거짓.
- (b) "다음 틱에 정리된다" → 쉬는 구간 **밖**으로 이동했다면 `:1017-1022`에서 정리되므로 문제 없음. 같은 구간 안이면 `isAfk`가 참이라 정리도 재시작도 안 됨 → 문제 유지.
- (c) "리플레이 데이터/타이밍에 영향" → 없음. 표시 상태만 어긋남(심각도 중/하).

정상 동작 조건(반증 시도 결과): 사용자가 드래그로 쉬는 구간을 벗어나거나, 재생을 멈추는 버튼을 누르거나, 끝까지 끌어 리플레이가 끝나는 경우에는 `stopReplay()`(`:1438-1451`)가 3종 정리를 하므로 문제가 재현되지 않습니다. 즉 재현 조건은 "AFK 표시 중 + 시크바 드래그 + 같은 구간 내 복귀"의 조합입니다.

수정 제안(적용 안 함) — 정리 주체를 한 곳으로 모으고, 연출이 취소됐으면 다시 시작:

```as
// ReplayController.as — 상태 정리 단일화 (updateAfkState 안의 3줄, stopReplay 안의 3줄을 대체)
public static function clearAfkState():void
{
    if (isAfkBoxShown)
    {
        isAfkBoxShown = false;
        ReplayDrawer.rReplayFOFOCursor.hideAfkBox();
    }

    CursorAfkAnimation.stop();
}

private static function updateAfkState():void
{
    if (!ReplayClock.isAfk)
    {
        clearAfkState();
        return;
    }

    // 상자가 이미 보여도 연출이 취소(복귀 중)됐으면 다시 시작해야 함
    if (!isAfkBoxShown || !CursorAfkAnimation.isRunning)
    {
        const extents:Object = CursorAfkAnimation.start();

        if (!isAfkBoxShown)
        {
            isAfkBoxShown = true;
            ReplayDrawer.rReplayFOFOCursor.configureAfkBox(seekBarBox.prograssInfo.defaultTextFormat, seekBarBox.prograssInfo.embedFonts);
            ReplayDrawer.rReplayFOFOCursor.showAfkBox(ReplayDrawer.rCanvasPanel, new Rectangle(0, 0, ReplayState.RCANVAS_WIDTH, ReplayState.RCANVAS_HEIGHT), extents.scaleFactor, extents.extraUp);
        }
    }
}

// onDragStart() 안, isReplayStarted를 내리는 지점에 추가
ReplayController.clearAfkState();
// stopReplay() 안의 3줄도 clearAfkState() 한 줄로 교체 (동작 동일)
```

참고: 여기서 쓰는 `CursorAfkAnimation.isRunning`은 현재 아무도 호출하지 않는 데드 getter입니다(3장 B3). 이 수정을 적용하면 살아납니다.

※ 위 R1 수정 제안은 커밋 `404615e`로 반영되었습니다(적용됨).

### R2. 슬라이드쇼 모드에서 AFK 연출이 시작 즉시 취소됨 (하)

**수정 반영(커밋 `560728f`) — 부분 수정.** 의도(매 틱 취소 방지)는 달성했으나 가드 범위가 넓어 회귀 1건이 생겼습니다.

- 적용 형태: ① 슬라이드쇼 경로에서 `updateAfkState()` 호출 제거(`ReplayController.as:365` 부근), ② `renderReplayFrame`에서 `CursorAfkAnimation.stop(); anim.clear();`를 `if (!ReplayState.isReplaySlideShowMode)`로 감쌈(`ReplayDrawer.as:315-320`).
- 좋아진 점: 슬라이드쇼 중 AFK 연출이 매 틱 취소되지 않고 자체 타이머로 계속 진행됩니다.
- **회귀 수정 완료(커밋 `15f4242`) — 검토 통과.** 아래 R2-a/R2-b 두 잔여를 정확히 제안한 형태로 고쳤습니다: ① `anim.clear()`를 `if (!ReplayState.isReplaySlideShowMode)` **밖으로** 이동(`ReplayDrawer.as:315-319`) ② 슬라이드쇼 전환 분기에 `ReplayController.clearAfkState()` 추가(`ReplayController.as:998`). 아래 R2-a/R2-b는 수정 전 분석 기록입니다.
- **잔여 회귀 R2-a(하)**: 같은 가드가 `anim.clear()`까지 감싸므로 **연출(채우기/올가미/이동/선) 진행 중에 배속이 60을 넘겨 슬라이드쇼로 전환되면 연출의 덮개 Bitmap · 숨긴 레이어 · 숨긴 선 Shape가 정리되지 않습니다.** `anim.update()`는 `drawDueFrames()`에서만 불리므로 슬라이드쇼에서는 연출이 스스로 끝나지 못하고, 정리 시점은 배속을 ≤60으로 내려 `update()`→`clear()`가 불릴 때나 재생 정지(`stopReplay`)뿐입니다. 수정 전에는 슬라이드쇼 틱마다 `clear()`가 실행되어 정리됐으므로 이번 변경으로 생긴 회귀입니다. 도달 조건: 슬라이드쇼가 가능한 긴 녹화(1배속 축 ≥ 약 10분) + 전환 순간 연출 진행 중.
- **부수 관찰 R2-b(하)**: 슬라이드쇼에서는 AFK 상자도 정리 주체가 없어, 슬라이드쇼 진행으로 AFK가 아니게 되어도 배속을 내리거나 재생이 끝날 때까지 상자가 남습니다(연출 자체는 계속 돌아 상태는 일관).

최소 수정 제안(적용 안 함) — 가드 범위를 AFK 정지에만 좁히고, 슬라이드쇼 전환 시 AFK 표시를 정리:

```as
if (!ReplayState.isReplaySlideShowMode)
{
    CursorAfkAnimation.stop();   // 슬라이드쇼에서는 AFK 연출만 건드리지 않음
}

anim.clear();                    // 연출 정리는 슬라이드쇼에서도 필요
```

```as
// startReplayDrawTimer()의 슬라이드쇼 전환 분기
if (shouldUseReplaySlideShowMode())
{
    ReplayState.isReplaySlideShowMode = true;
    ReplayController.clearAfkState();   // 슬라이드쇼에서는 AFK 표시를 쓰지 않음
    ReplayDrawer.rFileStream.close();
}
```

아래는 수정 전 분석 기록입니다.

- 경로: `drawCanvasFromReplayDataSlideShowMode()`(`ReplayController.as:356-378`)가 `ReplayClock.frameCountDue` → `updateAfkState()`(`:361-363`)로 연출을 시작한 뒤 같은 틱에 `ReplayDrawer.renderReplayFrame(...)` → `CursorAfkAnimation.stop()`(`ReplayDrawer.as:315`) → 항상 복귀 모드로 취소됩니다. 상자(`hideAfkBox`)는 `isAfk`가 거짓이 될 때만 정리되므로 남습니다.
- 도달 조건: `shouldUseReplaySlideShowMode()`(배속 > 60) **그리고** 녹화 공간 ≥ `ENTRY_MS * 배속` (60배속이면 360초 공백) → 사실상 도달 어려움. 그래서 심각도 하.
- 그래도 코드 흐름은 "AFK 연출은 실시간 재생 전용"이라는 의도와 어긋납니다.
- 수정 제안(적용 안 함): 슬라이드쇼 경로에서 호출 순서를 바꾸거나 제거.

```as
// drawCanvasFromReplayDataSlideShowMode() 안
const shouldStop:Boolean = ReplayDrawer.renderReplayFrame(dueFrame, ReplayDrawer.JUMP_FRAME_MANUAL);
updateAfkState(); // renderReplayFrame(내부에서 CursorAfkAnimation.stop) 뒤로 이동
```

### R3. ~~`takeTimingSheetBufferTimes()` 계약 위험~~ → **반증 성공, 문제 목록에서 제외**

호출 지점은 `UndoHistory.as:134`(addContinue)와 `:162`(addNew) **2곳뿐**이고, 두 곳 모두 `:143` / `:165`에서 무조건 `rMemoryDataBuffer = []`로 비웁니다(early return `:125-126`은 take 이전). `take()`의 부작용은 시각 Dictionary 재생성(`ReplayState.as:209`)뿐이고, 버퍼를 `take()` 없이 비우는 `UndoHistory.as:104`는 딥 언두 경로에서 같은 객체로 복원됩니다(`DrawingFinish.as:29-33`). "소비된 뒤 버퍼가 남는" 도달 가능한 경로가 없습니다 → 상세 근거는 **5장 14번**.

### R4. 타이밍 파일 부재 시 `segmentStart` 범위 밖 접근 가능성 (하) — 반증 성공 + 방어 적용

**되돌림(리뷰 2차).** 1차에서 넣었던 방어(rebuild try/catch + 옛 간격 폴백, loadSegment 범위/읽기 방어, `readRange`가 읽은 개수 반환)를 **전부 제거**했습니다. 제거 사유(리뷰 지적 + 확인):

- **핸들 누수**: `rebuild()`의 `fs.close()`가 try의 성공 경로에만 있어, 읽기 도중 예외가 나면 방어하려던 바로 그 상황에서 스트림이 열린 채 남았습니다(실제 결함).
- **도달 불가 가드**: `segmentStart`는 `alignTo`가 항상 채우므로 `segment < segmentStart.length` 삼항/`framesDueAt` 가드는 성공·실패 어느 경로에서도 도달 불가였습니다(제 문서도 "주입으로 도달 못 함"이라 자인).
- **비대칭**: 쓰기 쪽(`appendGroup`/`appendPointsRecord`/`cutBefore`)은 예외를 그대로 던지는데 읽기만 삼키면 실패가 숨겨집니다(재생이 42ms로 조용히 진행).
- 현재 동작(fail-fast): 시간 파일을 못 만들면 `rebuild()`가 예외를 그대로 올리고, 호출부(파일 열기/자르기/언두 경로)에서 실패가 드러납니다. 하네스 `r4.throwsOnFailure`로 고정했습니다.

아래는 최초 분석·반증 기록입니다(수정 전 기준).

- 위치: `ReplayClock.as:394-420` (`loadSegment` → `var sum:Number = segmentStart[segment];`), `:422` (`framesDueAt`의 `segmentStart[0]`).
- 반증: `rebuild()`(`:70-164`)가 먼저 `TimingSheetFile.alignTo(fileFrames)`(`:74`)를 호출하고, `alignTo`는 `frameCount`(= `file.exists ? size/8 : 0`)가 모자라면 `LEGACY_FRAME_DELTA`(42ms)로 채워 파일을 **항상 생성**합니다(`TimingSheetFile.as:110-141`). 따라서 `fileFrames > 0`이면 파일이 존재하고 `segmentStart`도 채워집니다(5.4 참고). 실질 위험 없음 → 문제 목록에서 제외. (이후 방어를 적용했다가 **리뷰 2차에서 되돌림** — 방어가 핸들 누수와 도달 불가 가드를 만들었고, 실패는 예외로 드러내는 편(fail-fast)이 낫다고 판단: 2장 R4)
- 참고 제안(선택): 디스크 오류 등으로 `alignTo`가 예외를 던지면 위로 전파되므로, 방어를 원하면 `rebuild()`를 try/catch로 감싸고 실패 시 `segmentStart`를 채운 뒤 진행하는 편이 안전합니다.

### R5. `readPoints`가 재생 중 매 선 명령마다 파일을 선형 탐색 (하, 성능)

**되돌림(리뷰 2차).** 1차에서 넣었던 점 시각 파일 위치 색인(`pointsIndex`/`buildPointsIndex`/무효화 4곳)을 **전부 제거**하고 원래 선형 탐색(`TimingSheetFile.readPoints`)으로 되돌렸습니다. 사유:

- **필요성 미입증**: 조회는 연출이 걸린 line4 명령마다 1회이고, 실측 이득은 400회 조회에서 213ms → 47ms였지만 **조회 1회 ≈0.5ms**(3000레코드 기준)로 프레임 예산(41ms)에 비해 무시할 수준입니다. 앱 부하(선 도구를 수천 번 쓴 녹화에서 프레임 드랍)가 관측되면 그때 다시 도입하는 편이 맞습니다.
- **새 위험**: 점 파일을 쓰는 곳에 무효화를 빠뜨리면 오래된 색인이 조용히 틀린 위치를 가리키는 실패 모드가 생깁니다(1차 구현에서는 4곳 모두 처리 + 하네스 12건으로 검증했지만, 코드 60줄+상태 1개가 추가됨).

아래는 최초 분석·제안 기록입니다.

- 경로: `ReplayDrawer.prepareFrameAnim()`(`ReplayDrawer.as:690-716`) → 프레임 그리기 → `ReplayAnim.startLine()`(`ReplayAnim.as:213`) → `ReplayClock.pointOffsetsOfFrame()`(`ReplayClock.as:347`) → `TimingSheetFile.readPoints()`(`TimingSheetFile.as:298-333`).
- 근거: 메모리(파일 뒤) 구간의 점 시각은 `ReplayClock.memoryPoints`로 캐시하지만(`:144-158`), **파일 구간은 매 조회마다 파일을 열고 프레임 번호가 나올 때까지 앞에서부터 훑습니다**(`TimingSheetFile.as:316-330`). 점 레코드는 line4(선 도구) 명령마다 1개씩 생기므로, 선 도구를 많이 쓴 긴 녹화에서 전체 비용이 O(line4 개수 × 점 레코드 수)가 됩니다.
- 반증 시도: `startLine`은 arm된 경우(연출 길이 ≥ `MIN_REAL_MS`이고 시계가 연출 구간 안)에만 호출되므로 대부분의 프레임에서는 파일 접근이 없습니다. 실시간 24fps 재생에서 프레임당 1회 파일 열기+스캔은 체감 지연(프레임 드랍) 요인이 될 수 있으나, 실측 없이는 확정 불가 → 성능 "의심"으로만 기록.
- 수정 제안(적용 안 함): `rebuild()`에서 점 파일을 한 번 훑어 프레임→점 배열 인덱스를 만들어 두고(메모리 구간과 동일 방식), `readPoints` 대신 그 인덱스를 조회.

```as
// ReplayClock.rebuild() 끝에 파일 점 레코드도 메모리에 인덱싱 (메모리 구간 memoryPoints와 같은 방식)
//   PointsFileRecord: [frame, count, v0, v1, ...] 를 한 번 순회하며 filePoints[frame] = [v0, v1, ...]
// pointOffsetsOfFrame(frame)에서 frame < fileFrames 면 filePoints[String(frame)] 사용
```

### R6. 프레임 수/배속 변경 시 AFK 표시를 두 번 그림 (하, 중복)

**수정 완료(커밋 `7580229`).** `refreshAfkRanges()` 단독 호출을 지우고 `onReplaySpeedChanged()`를 클램프 여부와 무관하게 **한 번만** 호출하도록 정리했습니다 → `getIdleMarks()` 계산과 시크바 `afkRangeBar` redraw가 함수 1회당 1회로 줄었습니다(예전에는 클램프 때 2회). 배속이 그대로인 경우에도 축/시크바 위치가 갱신되며(`onReplaySpeedChanged`는 `seekBarBox && !ReplayState.isReplayStarted`일 때만 위치를 직접 씀), 전체 앱 컴파일 오류 0/경고 0 + 하네스 `r6.*` 5건 통과입니다.


- 위치(수정 전 기준): `updateTotalFrameAndReplayMaxSpeedFor10Sec()`(`ReplayController.as:97-121`): `:109 refreshAfkRanges()` 후 `:119 onReplaySpeedChanged()` → `:126 refreshAfkRanges()`. 수정 후에는 `:123`의 `onReplaySpeedChanged()` 1회뿐입니다.
- 결과: 배속이 최대치로 클램프되는 경우 `ReplayClock.getIdleMarks()`(전 구간 순회 + Vector 생성)와 `SeekBarSet`의 `afkRangeBar` 그래픽 clear/redraw가 한 번의 갱신에 두 번 수행.
- 수정 제안(적용 안 함): 클램프 분기에서만 `onReplaySpeedChanged()`가 갱신하도록 정리.

```as
ReplayState.REPLAY_MAX_SPEED = maxSpeed;

// 제안: 배속을 먼저 클램프한 뒤 갱신을 한 번만 (refreshAfkRanges는 onReplaySpeedChanged 안에서 이미 호출됨)
if (ReplayState.rReplaySpeedMultipler > maxSpeed)
{
    ReplayState.rReplaySpeedMultipler = maxSpeed;
}

onReplaySpeedChanged();   // refreshAfkRanges + 시크바 위치 갱신
// 위처럼 하면 109 줄의 refreshAfkRanges()는 삭제 가능
```

(부작용 확인: `onReplaySpeedChanged()`는 `ReplayState.isReplayStarted`가 거짓일 때만 시크바 위치를 직접 갱신하므로, 배속이 그대로여도 호출 비용/동작 차이는 없습니다.)

### R7. `memory === undefined` 비교 (정보)

- 위치: `ReplayClock.as:356-360`. 컴파일 시 경고로 확인됨(하네스 빌드 로그):

```
ReplayClock.as:358 Warning: Illogical comparison with undefined. Only untyped variables (or variables of type *) can be undefined.
```

- 타입이 `Array`인 지역 변수는 `undefined`가 될 수 없으므로(대입 시 null로 강제) 조건의 뒤쪽 절반은 죽은 코드입니다.
- **수정 완료**(커밋 `e1c7aa2`): `if (memory === null)` — 검토 결과 정확(타입상 `undefined` 불가). 전체 앱 컴파일에서 경고 0/오류 0 확인.

### R8. 주석/문서 불일치 (정보)

**반영 완료.** ① `ReplayDrawer.prepareFrameAnim` 주석에 `line4` 추가 ② `CursorAfkAnimation.MAX_AFK_SECONDS`의 "상자 위치 계산에 씀" 주석은 상수 자체가 데드라 **삭제** ③ `SeekBarSet.setAfkRanges` 주석을 "트랙 위에 어둡게 표시 + 폭 1px 미만은 눈금"으로 정정(시크바 AFK 안내 문구는 커밋 `0287d01`에서 삭제됨) ④ `AppStateManager`에서 `replayTimingSheetFilePath`(프레임 간격)와 `replayTimingPointsFilePath`(점별 시각) 설명을 분리. 부가로 `TimingSheet` 클래스 헤더의 "구간 정보(INFO_*)를 메모리에 둠" 설명을 현재 설계(구간 blob 저장 + `ReplayClock`이 한 구간씩 풀어 씀)로 정정하고, `INFO_*`·`findSegment*` 블록에는 "테스트 하네스 전용" 주석을 달았습니다.


| 위치 | 현재 | 실제 코드 |
|---|---|---|
| `ReplayDrawer.as:686-688` | "연출이 있는 명령(fill5, lasso2, move*)" | `:700`에서 `line4`도 arm |
| `CursorAfkAnimation.as:18` | `MAX_AFK_SECONDS` "AFK 상자 위치를 정하는데 씀" | 어디서도 사용 안 함(3장 B1) |
| `SeekBarSet.as:45` | "AFK 안내를 시크바 아래 왼쪽에 보여줌" | 커밋 `0287d01`에서 시크바 AFK 안내 삭제, 지금은 트랙 위 어둡게 표시 |
| `AppStateManager.as:64` | `replayTimingPointsFilePath` 주석에 두 파일 설명이 섞임 | 앞 주석은 `replayTimingSheetFilePath`(시간 간격)에 해당 |

### R9. 이동 연출 종료 시 최종 위치 미보정 (하)

**수정 완료(2차).** 1차 수정(`793ab95`)은 **부분 수정**이었습니다 — 리뷰 지적대로 `ref1/ref2`에 목표 오프셋을 대입한 **직후** `clear()`가 같은 호출 안에서 컨테이너를 제거하고 `ref.bitmapData`를 비우므로 그 위치는 화면에 한 번도 그려지지 않았고, 실제로 효과가 있던 줄은 `setRCursorPos`(커서)뿐이었습니다. `update()`는 틱당 1회(`ReplayController.as:1054`)라 마지막으로 보이는 덮개는 직전 틱(p<1) 위치 그대로였습니다.

2차 수정: 종료 틱에 목표 오프셋을 적용하고 **그 프레임을 그대로 둔 채 `return`**, 다음 틱에 `clear()` 합니다(`endFrameShown` 플래그, `ReplayAnim.applyMoveOffset`로 진행 틱과 공용화). 종료 틱이 한 번 더 그려지므로 남은 오차 `dist×(1-p)²`만큼 튀던 것이 사라집니다.

- 검증을 **화면에 실제로 올라온 덮개 위치**로 바꿨습니다(`test-output/rt2-review`의 `overlayAt(x, y)`): 80% 시점 덮개 (192,96) → 종료 틱 덮개 **(200,100)이 화면에 존재**(= 렌더됨) + `isActive` 유지 → 다음 틱 정리 후 덮개 없음, 커서 (500,295), 음수 이동 (0,-100)/(300,95). `r9.*` 10건 통과.
- 1차처럼 "커서 좌표만 확인"하면 이 결함을 검출할 수 없습니다(검증 방식 자체가 잘못이었음).

### 2.6 `CursorAfkAnimation.GROW_MAX` 변경(당시 미커밋, 현재 `2bd648a`로 커밋) 관련 메모

`CursorAfkAnimation.GROW_MAX`가 2.2 → 5.0으로 바뀌어 있습니다. (커밋 `2bd648a`) 커밋 `2c60113`("커짐 연출에서도 AFK 상자 위치를 기본 간격에 고정")에 따라 커짐/늘어짐 연출은 `extentsOf()`에서 `scaleFactor = 1`을 돌려주고 상자를 기본 간격에 두므로(`CursorAfkAnimation.as:172-186`), 몸통이 최대 5배까지 커지면 AFK 상자와 겹칠 수 있습니다(의도된 트레이드오프로 보이나, `GROW_MAX`를 키우면 겹침 폭도 같이 커짐). 상자를 겹치지 않게 하려면 `extentsOf`의 `KIND_GROW` 분기에 `Math.min(GROW_MAX, 1 + GROW_RATE_PER_SEC[forVariant] * MAX_AFK_SECONDS)`를 넣는 방법이 있습니다(이런 계산에 쓸 상수는 없음 — `MAX_AFK_SECONDS`는 쓰이지 않아 이번 정리에서 삭제됨).

## 3. 데드 코드 (메서드/변수)

판정 기준: 전체 `src`에서 참조 횟수가 선언 1회뿐인 심볼(grep 전수). "테스트 하네스"는 `test-output/`의 별도 스크립트를 의미하며 앱 동작과 무관합니다.

| # | 심볼 | 위치 | 근거 |
|---|---|---|---|
| B1 | `MAX_AFK_SECONDS` | (삭제) | **삭제 완료** — 앱·하네스 참조 0. 잘못된 주석도 함께 제거 |
| B2 | `get currentPose()` | `CursorAfkAnimation.as` | 앱 호출 0회 → **테스트 전용 표시**(작성자 하네스가 AFK 자세 확인) |
| B3 | `get isRunning()` | `CursorAfkAnimation.as` | → **R1 수정(`404615e`)에서 사용됨(해소)** |
| B4 | `get isArmed()` | `ReplayAnim.as` | **삭제 완료**(2차): 가드를 되돌리면서 호출자 0이 됨 |
| B5 | `get totalMs()` | `ReplayClock.as` | 앱 호출 0회 → **테스트 전용 표시** |
| B6 | `get frameCount()` | `ReplayClock.as` | 앱 호출 0회 → **테스트 전용 표시** |
| B7 | `afkRemainingMs()` | `ReplayClock.as` | 앱 호출 0회(시크바 AFK 카운트다운 삭제 후 잔존) → **테스트 전용 표시**(하네스가 AFK 남은 시간 검증) |
| B8 | `remainingRealMs()` | `ReplayClock.as` | 앱 호출 0회(앱은 `remainingRealMsAt` 사용) → **테스트 전용 표시** |
| B9 | `remainingMsFrom()` | `ReplayClock.as` | 앱 호출 0회 → **테스트 전용 표시** |
| B10 | `INFO_FIRST_FRAME`/`INFO_FRAME_COUNT`/`INFO_START_TIME`/`INFO_DURATION` | `TimingSheet.as` (삭제) | **삭제 완료**(2차): 유일 소비자가 이미 컴파일 불가한 낡은 하네스라 근거가 약함 |
| B11 | `toTimes()` | `TimingSheet.as` (삭제) | **삭제 완료** (누적 시각은 `ReplayClock.loadSegment`가 계산) |
| B12 | `findSegmentByFrame()` | `TimingSheet.as` (삭제) | **삭제 완료**(2차): 소비자 `timing_sheet` 하네스가 이미 컴파일 불가 |
| B13 | `findSegmentByTime()` | `TimingSheet.as` (삭제) | **삭제 완료**(2차): 위와 같은 이유 |
| B14 | `findSegment()` (private) | `TimingSheet.as` (삭제) | **삭제 완료**(2차) |
| B15 | `get isAfkBoxVisible()` | `FOFOCursorSet.as` | 앱 호출 0회 → **테스트 전용 표시**(작성자 하네스가 AFK 상자 표시 확인) |
| B16 | `getAfkBoxBounds()` | `FOFOCursorSet.as` | 앱 호출 0회 → **테스트 전용 표시**(작성자 하네스가 상자 위치/크기 검증) |

추가 정리 대상(코드 데드는 아니지만 낡음):

- `test-output/timing_sheet/TimingSheetTest.as`: `TimingSheet.decodeSegment(blob, n)`(2인자), `findSegmentByFrame(infos, frame)` 형태를 사용 → **현재 소스로는 컴파일 불가**(정리 전에도 이미 불가). 이번 정리로 `findSegment*`가 삭제되어 참조만 늘었으니, 최신 API로 고치거나 삭제 필요.
- 반대로 `test-output/realtime_rec/RealtimeRecTest.as`(작성자 하네스, 1038줄)는 현재 API와 맞고 최근 실행 기록도 정상입니다(부록 A).

정리 결과(리뷰 2차 반영): **삭제 5건** — B1 `MAX_AFK_SECONDS`, B4 `isArmed`, B10 `INFO_*`, B11 `toTimes`, B12~B14 `findSegment*`. **"테스트 전용" 표시로 유지 8건** — B2 `currentPose`, B5~B9(시계 getter/래퍼), B15/B16(AFK 상자 조회).
유지 근거: **작동 중인** 하네스가 실제로 사용하기 때문입니다 — `test-output/realtime_rec/RealtimeRecTest.as`가 AFK 커서 자세(`currentPose.spin`)·afk 상자 표시/위치(`isAfkBoxVisible`, `getAfkBoxBounds`)·시계 총량(`totalMs`/`frameCount`)·AFK 남은 대기(`afkRemainingMs`)·종료 시각(`remainingMsFrom`)을 검증합니다(호출부 15곳). 이 8개를 완전히 지우려면 그 하네스 호출부를 대체 구현으로 바꿔야 하고 AFK 캡/재개 검증 커버리지가 사라집니다.
리뷰가 지적한 `INFO_*`/`findSegment*`는 유일 소비자(`timing_sheet` 하네스)가 정리 전부터 컴파일 불가라 근거가 약해 **삭제로 정리**했습니다(그 하네스는 여전히 `decodeSegment` 2인자 호출 때문에 컴파일 불가 — 최신 API로 고치거나 삭제 필요).

## 4. 중복 호출/성능 의심 검토 결과

| 의심 | 판정 | 근거 |
|---|---|---|
| `updateReplayPrograssBarWidthByNowFame`가 매 프레임 AFK 그래픽까지 다시 그림 | **아님** | `SeekBarSet.as:85-96`은 `prograssBar.width`만 설정. `redrawAfkRanges()`는 `updatePos`(`:148`)와 `setAfkRanges`(`:47-50`)에서만 호출 |
| 재생 중 시크바 텍스트 갱신이 무거움(전 구간 순회) | 낮음 | `getReplayRemainingTimeString` → `remainingRealMsAt`이 `gapRanges`를 전부 순회(`ReplayClock.as:633-668`). 1초에 1회(`:929-938`)이므로 무시 가능 |
| `recordedNow()`가 두 타이머(재생 틱/시크바 틱)에서 각각 호출되어 앵커가 흔들림 | **아님** | 동일 배속이면 앵커 재설정이 없음(`ReplayClock.as:516-530`). 배속이 바뀐 직후의 첫 호출에서만 이동 |
| `refreshAfkRanges()` 중복 호출(R6) | 맞음(하) → **수정 완료(커밋 `7580229`)** | 수정 전: `:109`와 `:119`→`:126`. 수정 후: `onReplaySpeedChanged()` 1회. (2차 소견: 프레임 수 변경 시 시크바 바가 한 번 중간값으로 그려졌다 덮임 — 표시 영향 없음) |
| `pc.replacePoint`류 값 객체 중복 유틸 | 해당 없음 | 이 범위에 값 객체 없음 |
| `TimingSheetFile.frameCount`가 매번 파일 `size` 조회 | 낮음 | `alignTo`/`cutBefore`/`readRange`에서만 호출(`:110` `:197` `:481`), 구간 로딩은 세그먼트가 바뀔 때만 |
| `readPoints` 선형 탐색(R5) | 맞음(하, 성능) → **되돌림**(리뷰 2차) | 위 R5 |
| `prepareFrameAnim`/`drawFromMemoryData`/`drawFromFileData`의 `arm → drawNext → disarm` 3줄 중복 | 의도적 중복 | 두 경로(파일/메모리)가 같은 규약을 유지해야 해서 분리 불가에 가까움. 중복 제거보다 주석 유지가 안전 |
| `updateAfkState`와 `stopReplay`의 정리 3줄 중복 | 맞음(R1 수정안에서 단일화) | `:1017-1022`, `:1446-1450` |

## 5. 반증에 성공해 "문제 목록에서 제외"한 항목

의심했지만 "이 코드가 정상 동작하는 조건"을 찾아 제외한 항목입니다. (a)~(e)는 실행 검증까지 했습니다.

1. **`packStamp` 2^53 정밀도**: `MAX_ANIM_MS(2^21-1) * 2^32 + uint(stamp)`는 최대 2^53-1이라 배정도 정수로 정확합니다. [실행] 24조합(음수 시각 포함) 왕복 일치, 상·하한 클램프 확인(부록 A `pack.*`).
2. **구간(varint) 인코딩/디코딩 경계**: 0/1/127/128/129/16383/16384/16385/2^21-1/2^32-2/2^32-1 왕복 일치, 0개 구간, 남는 바이트 오류 검출. [실행] `segment.*`.
3. **`.fofo` 타이밍 시트 저장/불러오기 왕복**: `buildFileObject` → `loadFileObject` 후 프레임별 간격/연출 길이가 원본과 일치. **10000프레임 구간 경계를 넘는 경우(총 10002프레임, 2구간)** 도 인덱스 off-by-one 없음. 점별 시각 blob도 파일 구간/메모리 구간 모두 왕복. [실행] `buildLoad(...).*`.
4. **자르기/패딩 시 점 레코드 프레임 번호 재매핑**: `cutBefore(3)`에서 점 레코드 프레임 6 → 3, 첫 간격 0, `truncateAfter`/`alignTo`(모자라면 42ms 채움, 남으면 자름), 끊긴 점 레코드 방어. [실행] `file.*`. → 3장의 `alignTo` 선행 호출(R4)도 함께 반증됨.
5. **AFK 대기/중간 재개/캡 건너뛰기/배속별 임계/축 변환**: 같은 공백에서 ① 입장 시 그리지 않고 대기, ② 구간 중간에서 재개하면 남은 유지 시간만 대기(5200-3000=2200ms), ③ 유지 시간이 지나면 공백 끝까지 건너뜀(프레임 7까지 진행), ④ 배속 8에서는 임계 48초라 AFK 아님, ⑤ `frameRatio ↔ ratioToFrame` 왕복 일치, ⑥ 축 길이 = 전체 − (7000−5000). [실행] `clock.*`. 작성자 하네스도 `bar backward steps=0`(시크바 역주행 없음)과 정상 종료를 보고(`test-output/realtime_rec/report.txt`).
6. **펜 점 시각 보정(TimingSmoother)**: 같은 시각 묶음 균등 분배(100→142 구간), 간격 100ms 초과 시 미분배, 중간에 다른 명령이 끼면 분리, 이미 다른 시각이면 유지, 시작 묶음(간격 0)은 나눌 근거가 없어 유지. [실행] `smooth.*`.
7. **연출(Line) 숨김과 실제 합성 순서**: `ReplayAnim.startLine`이 `rCanvasDrawShape`를 숨기고 임시 Shape를 그 위에 올립니다(`ReplayAnim.as:278-303`). 실제 선은 다음 `drawDone5`(=`DrawingFinish.run()`이 `line4` 직후 push, `DrawingFinish.as:83` → `UndoHistory.addNew()`)에서 합성되는데, 그 명령의 녹화 시각은 항상 `line4의 시각 + 연출 길이` 이상입니다(연출 길이 = 도구 시작~적용 시간, 커밋 시각 = 적용 시각 + α). 게다가 두 명령이 같은 틱에 몰리면 arm 조건(`ReplayDrawer.as:709`의 `recordedPeek() - startRecorded < animMs`)이 걸러내므로, **연출 진행 중에 실제 선이 레이어에 합성되는 경우가 없습니다**. `clear()`(`:495`)는 `lineHost.graphics`를 건드리지 않고 visible만 복원하므로 이후 합성 결과도 정확합니다.
8. **AFK 타이머 중복 등록**: `FOFOTimer.addByName`은 같은 이름이면 항목을 덮어씁니다(`FOFOTimer.as:112-125`). 복귀 중 재시작해도 틱이 2번 돌지 않습니다. 콜백 안에서 `remove`하는 것도 스냅샷+동일성 검사로 안전합니다(`FOFOTimer.as:20-56`).
9. **일시정지 후 재개 시 남은 대기 시각 유지**: `rememberPosition`/`anchorAtFrame`의 조건(`ReplayClock.as:492-514`)으로 같은 프레임 사이(공백 내부)면 기억한 녹화 시각에서 이어갑니다. [실행] `clock.afkResumeWait/afkResumeRemaining`.
10. **시크바 클릭 → 재생 재개의 프레임 일치**: `onMouseUp`은 `renderReplayFrame(finalFrame)` **다음에** `rememberPosition(ReplayState.rNowFrame, ...)`를 호출하므로(`ReplayController.as:563-572`) 기억되는 프레임과 시각이 어긋나지 않습니다(순서가 반대였다면 무시되었을 경로).
11. **`rMemoryDataTimingSheet` 동기화 누락**: `rMemoryData`를 변형하는 5곳(`ReplayController.as:195` `:276`, `UndoHistory.as:139` `:162` `:182` `:235`, `UndoHistory.as:103` 초기화)에 모두 대응하는 타이밍 배열 조작이 있습니다. 형태 불일치 시 `AppStateManager.restoreMemoryDataTimingSheet`(`:868-917`)가 전체를 현재 시각으로 채우는 방어도 있어, 어긋나도 예외 없이 안전한 방향으로 수렴합니다.
12. **getTimer 32비트 랩(앱 연속 실행 24.8일)**: 간격은 `(stamp - last) | 0`로 차이가 보존되고(`TimingSheetFile.as:144-180`의 `appendGroup`, `:197-222`의 `cutBefore`), 음수로 감긴 연출 길이는 `packStamp`가 0으로 클램프합니다(`:33-43`). 예외/오염 경로 없음.
13. **`loadFileObject` 손상 입력 방어**: 버전 불일치/풀기 실패/남는 바이트 검출 시 `false` 반환 + 파일 리셋(빈 시트로 취급)이며, 이후 `rebuild()`가 `alignTo`로 42ms 기본 간격을 채웁니다. [실행] `buildLoad(...).badVersion`, `segment.trailing`.
14. **`takeTimingSheetBufferTimes()`의 버퍼 비우기 계약(R3)**: 호출 지점은 `UndoHistory.as:134`(addContinue)와 `:162`(addNew) 2곳뿐이고, 두 곳 모두 `:143`/`:165`에서 무조건 `rMemoryDataBuffer = []`로 비웁니다(early return은 `:125-126`으로 take 이전). `take()`의 부작용은 시각 Dictionary 재생성(`ReplayState.as:209`)뿐이며, 버퍼를 `take()` 없이 비우는 `UndoHistory.as:104`는 딥 언두 경로에서 같은 객체로 복원됩니다(`DrawingFinish.as:29-33`). 도달 가능한 결함 없음 → 문제 아님. (참고: 하네스가 같은 버퍼로 일부러 두 번 호출한 실험 `buf.notCleared`/`buf.secondCallLosesStamp`에서만 시각이 0으로 오염되며 이는 앱 경로가 아님. 선택: 함수 상단에 "호출부가 버퍼를 비운다" 주석 한 줄)

## 6. 정적으로 확정하지 못한 항목 (실기기/시각 확인 필요)

여기는 코드 판독만으로 확정하지 못했습니다(추론). 우선순위 순.

1. **커서 회전 중심**: `FOFOCursorSet` 생성자(`FOFOCursorSet.as:124-141`)가 `fofoCursor.getBounds(fofoCursor)`로 중심·반지름을 잡습니다. 심볼 생성 직후 bounds가 비어 있으면(=0) 회전축이 등록점(0,0)이 되어 "회전" 연출이 몸통 중심이 아니라 왼쪽 아래를 축으로 돕니다. 확인법: 리플레이 모드에서 `Utils.testFoFoCursorAnim(0, -1, 5)`(회전 강제) 후 커서가 제자리에서 도는지 눈으로 확인.
2. **AFK 상자 위치/크기**: 캔버스 확대(`rCanvasAnchorPoint.scale`)·회전 상태에서 상자가 캔버스 밖으로 잘리거나(스크롤Rect) 글자가 뭉개지는지, 커서가 캔버스 위쪽일 때 아래로 뒤집히는 판정(`FOFOCursorSet.as:79-101`)이 실제로 자연스러운지. (작성자 하네스는 bounds/픽셀만 확인)
3. **채우기/올가미 스캔라인**: 참고 레이어 이미지가 켜져 있거나 배경색이 캔버스와 다를 때 덮개 색(`RCANVAS_BG_COLOR`)이 어색하지 않은지.
4. **이동 연출 좌표**: `ReplayAnim.startMove`가 클론을 `rCanvasPanel` 좌표에 붙이므로 레이어 비트맵이 (0,0) 기준이라는 전제에 의존합니다(초기화 코드 `ReplayController.as:1846-1866`에서 확인했으나, 확대/회전 중 실제 오차는 육안 확인 권장). R9의 종료 오차는 `793ab95`로 해소(하네스 검증)되었고, 확대/회전 중 표시는 여전히 육안 확인 대상입니다.
5. **AFK 연출 6종의 체감**: `MAX_AFK_SECONDS`(현재 5초)와 상수 조합에서 늘어짐(최대 3.5배)·커짐(최대 2.2/5.0배)이 5초 캡 안에 자연스럽게 끝나는지.

## 7. 부록

### A. 검증 하네스 (`test-output/rt2-review/`)

- 대상: 이번 커밋 범위에서 새로 들어온 순수 로직(`TimingSheet`, `TimingSheetFile`, `ReplayClock`, `TimingSmoother`, `ReplayState` 버퍼 기록)
- 구성: `TimingFileTest.as`(하네스), `rt2review-app.xml`, `build.sh`(컴파일), `worker.swf`(앱 정적 초기화 대비 복사), `report.txt`
- 실행 방법(이 환경에서 확인한 명령):

```bash
# 컴파일 (AIRSDK 51.3.4). cmd.exe 직접 실행이 막혀 있어 sh 래퍼로 호출
cd test-output/rt2-review
sh /d/adobe_air_sdk_manager/AIRSDK_51.3.4/bin/amxmlc \
  -source-path+=E:/fofopaint-source/src \
  -source-path+=E:/fofopaint-source/test-output/rt2-review \
  -library-path+=E:/fofopaint-source/extension/libwebp.swc \
  -target-player=51.1 -swf-version=51 -debug=true -strict=true -warnings=true \
  -output=E:/fofopaint-source/test-output/rt2-review/TimingFileTest.swf \
  E:/fofopaint-source/test-output/rt2-review/TimingFileTest.as

# 실행
cmd.exe /c "D:\adobe_air_sdk_manager\AIRSDK_51.3.4\bin\adl.exe -profile extendedDesktop rt2review-app.xml E:/fofopaint-source/test-output/rt2-review"
```

- 결과: `RESULT pass=170 fail=0` (`test-output/rt2-review/report.txt`) — 시계/AFK/파일 경로 + R6 경로 스모크 5건(`r6.*`) + R4 fail-fast 3건(`r4.*`) + R9 이동 종료 10건(`r9.*`, 화면에 올라온 덮개 위치 검증) 포함 (R5 색인 테스트 12건은 색인 되돌림에 따라 제거)
- R4: 되돌림 후 하네스가 "시간 파일을 못 만들면 `rebuild()`가 예외를 올린다"(`r4.throwsOnFailure`)와 "경로 복구 시 정상값 복구"를 고정
- R5: 색인 되돌림으로 성능 측정 코드도 제거(측정 기록: 3000레코드 400회 조회가 선형 148~219ms, 색인 28~50ms → 조회 1회 ≈0.4~0.5ms)
- 전체 앱 컴파일 확인: `sh .../amxmlc -source-path+=E:/fofopaint-source/src ... src/Main.as` → 오류 0 / 경고 0 (`test-output/rt2-review/check-app.swf`)
- 컴파일러 경고: R7 수정(`e1c7aa2`) 이후 0건 (수정 전에는 `ReplayClock.as:358` 1건).
- 정리 후 검증: 앱 컴파일 오류 0/경고 0 + 하네스 2종 컴파일 성공(`rt2-review` 170 pass / `realtime_rec` 컴파일 성공)
- 낡은 하네스 `timing_sheet/TimingSheetTest.as`: `decodeSegment(blob, n)` 2인자 호출 때문에 정리 전/후 모두 컴파일 불가. 2차 정리로 `findSegment*`를 삭제해 참조 오류가 더 늘었으므로 **최신 API로 고치거나 파일을 삭제**해야 합니다
- 이 하네스는 `src/`를 건드리지 않는 별도 테스트 스크립트이며, 필요 없으면 폴더째 삭제해도 됩니다.

### B. 기존 하네스 산출물(작성자 실행 기록)

- `test-output/realtime_rec/report.txt`: AFK 대기 중 시크바 진행(역주행 0회), 5초 캡 후 공백 끝으로 건너뛰어 종료(`END t=5287 now=12/12`), 실시간 재생에서 프레임이 시계를 따라감(`nowFrame` vs `clock due` 일치). → 이 범위의 핵심 동작은 작성자도 헤드리스로 확인한 상태입니다.
- `test-output/timing_sheet/TimingSheetTest.as`: 구 API 사용으로 현재 소스와 불일치(3장 정리 대상).

### C. 검토에서 다루지 않은 것

- 커밋 이전부터 존재하던 코드(리플레이 그리기 파이프라인, 캐시 이미지 워커, 도구 로직 전반)는 이 범위의 변경과 상호작용이 있는 부분만 확인했습니다.
- 커서/캔버스의 최종 렌더 품질(6장)과 실기기 성능(프레임 드랍)은 실행 검증 범위 밖입니다.

### 2.7 `if (anim.isArmed) anim.disarm();` 가드(리뷰 2차에서 되돌림)

`prepareFrameAnim()`의 `anim.disarm()` 호출 3곳(`ReplayDrawer.as:698` `:709` `:723`)을 감쌌던 `if (anim.isArmed)` 가드를 **원래대로 되돌렸습니다**(동작은 동일했고 읽는 사람에게만 의문을 만들었음). 그 결과 `ReplayAnim.isArmed`의 호출자가 사라져 **getter도 삭제**했습니다(B4 = 삭제 완료).
