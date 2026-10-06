# realtime2 브랜치 정적 분석 검토 (b711c268 → 17f255dc)

- 검토일: 2026-10-06
- 범위: `b711c268a3b0f17d8584b50f42023699df9aa38f`..`17f255dc4d431187d28df6ce7f51d3e0491558b5` (커밋 22개, 파일 25개, +3165 / −42)
- 신규 파일: `ReplayAnim.as`, `ReplayClock.as`, `CursorAfkAnimation.as`, `TimingSheet.as`, `TimingSheetFile.as`, `TimingSmoother.as`
- 수정 파일(주요): `ReplayController.as`, `ReplayDrawer.as`, `ReplayDrawCommands.as`, `ReplayState.as`, `FOFOCursorSet.as`, `SeekBarSet.as`, `AppStateManager.as`, `FileManager.as`, `UndoHistory.as`, `UndoController.as`, `Tools/*`, `Utils.as`
- 이 문서는 **검토 기록만**입니다. 소스 코드는 수정하지 않았습니다(제안 코드는 "적용 안 함").

## 0. 검토 방법과 근거 등급

| 등급 | 의미 |
|---|---|
| [실행] | AIR SDK(51.3.4)로 헤드리스 하네스를 컴파일/실행해 확인 (`test-output/rt2-review`, 181개 체크 전부 통과, 부록 A) |
| [근거] | 소스 코드 인용 (`파일:라인`). 라인 번호는 커밋 `17f255d` 기준 |
| [추론] | 코드만으로 확정 불가(렌더/실기기 확인 필요) — 6장에 별도 정리 |

검토 순서: 변경 전문 정독 → 심볼 참조 전수 grep(호출/미호출 판정) → 값 계산·I/O 경로는 하네스로 실행 검증 → 의심 항목마다 "정상 동작할 수 있는 조건"을 찾아 반증 시도(5장).

작업 트리에는 커밋 범위 밖의 사용자 편집 2건이 있습니다: `CursorAfkAnimation.GROW_MAX` 2.2 → 5.0(미커밋), `InputManager.as`의 테스트 호출 주석 처리. 아래 2.6에서 관련 영향만 언급합니다.

## 1. 결론 요약

### 1.1 수정 반영 상태 (2026-10-06 갱신)

| 항목 | 상태 | 근거 |
|---|---|---|
| R1 | **수정 완료** (`404615e`) — 검토 통과 | `clearAfkState()` 단일화 + `updateAfkState` 재시작 조건. 전체 앱 컴파일 오류 0/경고 0 (2장 R1) |
| R2 | **수정 완료** (`560728f` + `15f4242`) — 검토 통과 | 슬라이드쇼 경로 정리 + `anim.clear()`를 가드 밖으로 + 전환 시 `clearAfkState()` (2장 R2) |
| R3 | **제외**(반증 성공) | 호출 2곳 모두 직후 버퍼를 비움 (5장 14번) |
| R4 | **적용 완료**(R4 커밋) | 시간 파일 실패 시 옛 간격으로 계속 + 누락 프레임 기본값 (2장 R4) |
| R5 | **적용 완료**(R5 커밋) — 실측 400회 47ms vs 213ms | 점 시각 파일 위치 색인 (2장 R5) |
| R6 | **적용 완료**(작업 트리, 미커밋) | 중복 `refreshAfkRanges()` 제거, 갱신 1회 (2장 R6) |
| R7 | **수정 완료** (`e1c7aa2`) — 검토 통과 | `memory === null`, 컴파일 경고 0 (2장 R7) |
| R8 | 미반영(주석 4건) | 2장 R8 |
| R9 | **수정 완료**(`793ab95`) — 검토 통과 | 연출 종료 시 목표 위치 확정 (2장 R9) |
| B | B4만 해소(작업 트리 변경으로 `isArmed` 사용) | 3장 |

### 1.2 검토 시점(`17f255d`) 결론 요약

| ID | 심각도 | 위치 | 요약 | 상태 |
|---|---|---|---|---|
| R1 | 중 | `ReplayController.as:532` `:1013` `:1438` | 시크바 드래그로 AFK(쉬는 구간) 중단 시 `isAfkBoxShown` 상태가 어긋나, 같은 구간으로 되돌아오면 afk 상자만 뜨고 커서 연출이 재개되지 않음 | 수정 완료(404615e) |
| R2 | 하 | `ReplayController.as:356` + `ReplayDrawer.as:315` | 슬라이드쇼 모드에서 AFK 연출을 시작하자마자 매 틱 취소(상자는 남음) | 부분 수정(560728f) + 회귀 R2-a |
| R4 | 하 | `ReplayClock.as:394` (`loadSegment`) | 타이밍 파일이 없을 때 `segmentStart[segment]` 범위 밖 접근 가능성 | 반증 성공(5.4) — 방어 코드만 제안 |
| R5 | 하(성능) | `ReplayClock.as:347` → `TimingSheetFile.as:298` | 재생 중 line4(선 도구) 명령마다 점 시각 파일을 처음부터 선형 탐색 | 적용 완료(미커밋) — 47ms vs 213ms |
| R6 | 하(중복) | `ReplayController.as:97-121` | 배속 클램프 시 `refreshAfkRanges()`가 시크바를 두 번 다시 그림 | 코드 경로 확정 |
| R7 | 정보 | `ReplayClock.as:358` | `memory === undefined`는 타입상 항상 거짓(컴파일러 경고 확인) | 수정 완료(e1c7aa2) |
| R8 | 정보 | `prepareFrameAnim` 주석 등 4건 | 주석/문서가 코드와 불일치 | 코드 근거 확정 |
| R9 | 하 | `ReplayAnim.as:384` `:495` | 이동 연출이 끝날 때 최종 오프셋을 적용하지 않고 `clear()` → 짧은 연출에서 커서/복제 이미지가 몇 px 어긋난 상태로 사라짐 | 코드 근거 + 계산 |
| B | 정보 | 3장 표 | 데드 코드 16건 | 참조 0회 grep |
| — | — | 5장 | 반증 성공(문제 아님) 14건 (R3 포함) | [실행]/[근거] |

데이터 손상·예외로 이어지는 버그는 발견하지 못했습니다. 새로 들어온 타이밍 시트 저장/불러오기, AFK 시간 계산, 축(시크바) 변환은 실행 검증까지 통과했습니다(부록 A).

## 2. 버그 위험 상세

### R1. 시크바 드래그 경로에서 AFK 상자/연출 상태 불일치 (중)

**수정 반영(커밋 `404615e`) — 검토 통과.** `clearAfkState()`(`ReplayController.as:1013-1023`)로 정리를 단일화하고 `onDragStart`(`:540`)·`stopReplay`(`:1458`)에서 부르며, `updateAfkState`는 `!isAfkBoxShown || !CursorAfkAnimation.isRunning`(`:1034`)일 때 연출을 (재)시작합니다. 제안한 형태와 같고, 전체 앱 컴파일(`src/Main.as`, strict+warnings)은 오류 0 / 경고 0입니다. 보강 관찰 2건(문제 아님): ① `onDragStart`의 호출은 재생 중일 때만 실행되는데 상자는 재생 중에만 표시되므로 미정리 상태가 도달하지 않음. ② `isAfk`가 참인데 커서가 숨겨진 상태가 되면 `tick()`이 `reset()`(mode=IDLE) 하므로 `updateAfkState`가 매 틱 `start()`를 다시 부를 수 있음 — 현재 흐름에서는 도달하지 않지만, 원하면 조건에 커서 표시 여부를 하나 더 두면 안전합니다.

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

**적용 완료(R4 커밋).** 반증(아래)으로 실질 위험은 낮지만, 잔여 실패 경로(경로가 디렉터리로 점유됨, 권한 거부, 디스크 오류 등)에서 시계가 예외로 멈추지 않도록 방어를 넣었습니다.

- `rebuild()`(`ReplayClock.as:70-148`): `alignTo` + 파일 스캔을 try/catch로 감싸고(실패 시 `trace`), 실패/파일 없음이면 `segmentStart`와 합계를 **옛 기본 간격(42ms/프레임)** 으로 채웁니다(`:134-147`). 상태 초기화(`segmentStart`/`gapRanges`/구간 캐시)를 try 앞으로 옮겨 예외 시에도 상태가 일관됩니다.
- `loadSegment()`(`:423-467`): `segmentStart[segment]` 읽기에 범위 검사, `readRange` try/catch, **읽지 못한(모자란) 프레임을 옛 기본 간격으로 채움**(첫 프레임 간격 0). 예전에는 누락 구간이 간격 0으로 남아 그 프레임들이 즉시 재생됐습니다.
- `framesDueAt()`(`:469-...`): `segmentStart.length > 0` 가드 추가.
- `TimingSheetFile.readRange()`(`:622-655`)가 **읽은 개수를 반환**(`void → int`). 기존 호출부는 반환값을 무시하므로 동작 불변.
- 검증(하네스, 실패 주입 = 시트 경로를 디렉터리로 교체): 예외 없이 `frames=12`, `total=504`(=12×42), `timeOfFrame(0)=0`, `step(0→5)=210`, `framesDueAt(210)=6`, 경로 복구 후 `total=7400`/`time(5)=200`로 즉시 회복 → `r4.*` 8건 통과.
- 주의(시도 중 확인): "파일이 아예 없음"은 AIR의 `FileMode.APPEND`가 상위 폴더와 파일을 만들고 `alignTo`가 42ms로 패딩하므로 **원래도 예외가 나지 않았습니다**(R4를 반증으로 분류한 근거). 이번 방어는 그보다 드문 실패 경우를 덮습니다. `loadSegment`의 catch 블록 자체는 주입으로 도달시키지 못했습니다(이중 방어로 유지).

아래는 최초 분석·반증 기록입니다(수정 전 기준).

- 위치: `ReplayClock.as:394-420` (`loadSegment` → `var sum:Number = segmentStart[segment];`), `:422` (`framesDueAt`의 `segmentStart[0]`).
- 반증: `rebuild()`(`:70-164`)가 먼저 `TimingSheetFile.alignTo(fileFrames)`(`:74`)를 호출하고, `alignTo`는 `frameCount`(= `file.exists ? size/8 : 0`)가 모자라면 `LEGACY_FRAME_DELTA`(42ms)로 채워 파일을 **항상 생성**합니다(`TimingSheetFile.as:110-141`). 따라서 `fileFrames > 0`이면 파일이 존재하고 `segmentStart`도 채워집니다(5.4 참고). 실질 위험 없음 → 문제 목록에서 제외. (이후 잔여 실패 경로 방어를 R4 커밋으로 적용: `rebuild` try/catch + 옛 간격 채움, `loadSegment` 범위/읽기 방어, `readRange`가 읽은 개수 반환)
- 참고 제안(선택): 디스크 오류 등으로 `alignTo`가 예외를 던지면 위로 전파되므로, 방어를 원하면 `rebuild()`를 try/catch로 감싸고 실패 시 `segmentStart`를 채운 뒤 진행하는 편이 안전합니다.

### R5. `readPoints`가 재생 중 매 선 명령마다 파일을 선형 탐색 (하, 성능)

**적용 완료(R5 커밋).** 파일을 소유한 `TimingSheetFile` 안에 점 레코드 색인을 두는 형태로 구현했습니다(`ReplayClock` 인덱스 대신 → 무효화 지점을 한 클래스에 모음).

- `pointsIndex:Object`(프레임 번호 → 레코드 시작 위치, `:33`), `buildPointsIndex()`(`:313`), `readPoints()`(`:347`)가 위치로 바로 이동해 그 레코드만 읽음(값은 저장하지 않아 메모리 증가 최소).
- 점 파일을 쓰는 **4곳 전부**에서 `invalidatePointsIndex()` 호출: `reset()`(`:90`), `appendPointsRecord()`(`:248`), `rewritePoints()`(`:300`), `loadFileObject()`의 직접 쓰기(`:558`). 점 파일을 건드리는 코드는 이 클래스 4곳뿐임을 grep으로 전수 확인(읽기만 하는 `buildPointsBlob`은 영향 없음).
- 예전 선형 탐색과 결과가 같도록 색인 구축도 ① 프레임 번호가 비오름차순이면 중단 ② 끝이 잘린 레코드에서 중단.
- 실측(하네스, 3000개 레코드에서 400회 조회): **새 색인 47ms vs 예전 선형 탐색 213ms (약 4.5배)**. 색인 구축은 점 파일이 바뀔 때마다 1회이므로 재생처럼 반복 조회할 때 상각됩니다(조회가 1회뿐이면 비용은 기존과 동일).
- 등가성·무효화 검증 12건 추가(부록 A): 레코드 프레임 값 일치 · 없는 프레임 null · 123개 혼합 질의에서 선형 탐색과 100% 동일 · 이어 붙이기/자르기/reset 뒤 새 색인으로 정확 조회 · 잘린 레코드/비정렬 레코드에서도 예전과 동일. 전체 앱 컴파일 오류 0/경고 0.

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

**적용 완료(작업 트리, 미커밋).** `refreshAfkRanges()` 단독 호출을 지우고 `onReplaySpeedChanged()`를 클램프 여부와 무관하게 **한 번만** 호출하도록 정리했습니다 → `getIdleMarks()` 계산과 시크바 `afkRangeBar` redraw가 함수 1회당 1회로 줄었습니다(예전에는 클램프 때 2회). 배속이 그대로인 경우에도 축/시크바 위치가 갱신되며(`onReplaySpeedChanged`는 `seekBarBox && !ReplayState.isReplayStarted`일 때만 위치를 직접 씀), 전체 앱 컴파일 오류 0/경고 0 + 하네스 `r6.*` 5건 통과입니다.


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

| 위치 | 현재 | 실제 코드 |
|---|---|---|
| `ReplayDrawer.as:686-688` | "연출이 있는 명령(fill5, lasso2, move*)" | `:700`에서 `line4`도 arm |
| `CursorAfkAnimation.as:18` | `MAX_AFK_SECONDS` "AFK 상자 위치를 정하는데 씀" | 어디서도 사용 안 함(3장 B1) |
| `SeekBarSet.as:45` | "AFK 안내를 시크바 아래 왼쪽에 보여줌" | 커밋 `0287d01`에서 시크바 AFK 안내 삭제, 지금은 트랙 위 어둡게 표시 |
| `AppStateManager.as:64` | `replayTimingPointsFilePath` 주석에 두 파일 설명이 섞임 | 앞 주석은 `replayTimingSheetFilePath`(시간 간격)에 해당 |

### R9. 이동 연출 종료 시 최종 위치 미보정 (하)

**수정 완료(커밋 `793ab95`) — 검토 통과.** `update()`의 `elapsed >= totalMs` 분기에서 `mode === 2`(이동)이면 `ref1`/`ref2`를 목표 오프셋(`distX`/`distY`)으로 맞추고 커서도 목표 위치로 옮긴 뒤 `clear()` 합니다 — 제안한 형태와 동일합니다(`ReplayAnim.as:394-409`).

- 검증(하네스 `r9.*` 8건): 진행률 80% 시점 커서 x=492(오차 상태) → 연출 종료 시 **정확히 500/295**(600/390 캔버스 중심 + 이동량 200/100), 음수 이동도 300/95, 종료 후 `anim.isActive=false` + 숨겼던 레이어 복원(연출 중에는 숨김) 확인. 앱 컴파일 오류 0/경고 0.
- 관찰(동작 무관): 같은 커밋에서 `for`문 6곳의 공백(`for (var c:int = 0; c < ...; c++)` → `for (var c:int = 0;c < ...;c++)`)이 바뀌어 파일 내 다른 `for`문과 스타일이 다릅니다. 리뷰 문서 4장/6장의 "이동 연출 좌표·종료 오차 육안 확인" 항목은 이 수정으로 종료 오차 부분은 해소되었습니다.


- 위치: `ReplayAnim.update()`(`:384-440`)의 `if (elapsed >= totalMs) { clear(); return; }` — 마지막 갱신은 항상 `p < 1`이므로 `ref1/ref2`의 오프셋과 커서 위치가 목표치에 도달하기 전 상태로 `clear()`(`:495`)가 호출됩니다.
- 계산: 남은 오차 ≈ `dist * (1 - p)^2`. 틱 간격을 41ms(24fps)로 보면 연출 길이 3000ms일 때 오차 ≈ `dist * 0.0002`(무시 가능)이지만, `MIN_REAL_MS`(120ms)에 가까운 짧은 연출(예: 250ms)에서는 `p ≒ 0.82` → `dist` 400px일 때 약 13px 어긋난 위치에서 덮개가 사라지고 실제(이동 완료) 이미지로 바뀝니다.
- 수정 제안(적용 안 함): 종료 직전 마지막 위치를 한 번 적용.

```as
if (elapsed >= totalMs)
{
    if (mode === 2)
    {
        // 마지막 틱에서 목표 위치를 정확히 맞추고 커서도 그 위치로
        if (ref1 && moveLayer1) { ref1.x = distX; ref1.y = distY; }
        if (ref2 && moveLayer2) { ref2.x = distX; ref2.y = distY; }
        ReplayDrawCommands.setRCursorPos(ReplayState.RCANVAS_WIDTH / 2 + distX, ReplayState.RCANVAS_HEIGHT / 2 + distY);
    }

    clear();
    return;
}
```

### 2.6 작업 트리 변경(미커밋) 관련 메모

`CursorAfkAnimation.GROW_MAX`가 2.2 → 5.0으로 바뀌어 있습니다. (커밋 `2bd648a`) 커밋 `2c60113`("커짐 연출에서도 AFK 상자 위치를 기본 간격에 고정")에 따라 커짐/늘어짐 연출은 `extentsOf()`에서 `scaleFactor = 1`을 돌려주고 상자를 기본 간격에 두므로(`CursorAfkAnimation.as:172-186`), 몸통이 최대 5배까지 커지면 AFK 상자와 겹칠 수 있습니다(의도된 트레이드오프로 보이나, `GROW_MAX`를 키우면 겹침 폭도 같이 커짐). 상자를 겹치지 않게 하려면 `extentsOf`의 `KIND_GROW` 분기에 `Math.min(GROW_MAX, 1 + GROW_RATE_PER_SEC[forVariant] * MAX_AFK_SECONDS)`를 넣는 방법이 있습니다(현재 `MAX_AFK_SECONDS`가 데드인 이유이기도 함).

## 3. 데드 코드 (메서드/변수)

판정 기준: 전체 `src`에서 참조 횟수가 선언 1회뿐인 심볼(grep 전수). "테스트 하네스"는 `test-output/`의 별도 스크립트를 의미하며 앱 동작과 무관합니다.

| # | 심볼 | 위치 | 근거 |
|---|---|---|---|
| B1 | `MAX_AFK_SECONDS` | `CursorAfkAnimation.as:18` | 선언만 존재. 주석은 "상자 위치 계산에 씀"이라지만 `extentsOf`(`:170`)가 쓰지 않음 |
| B2 | `get currentPose()` | `CursorAfkAnimation.as:120` | 호출 0회 |
| B3 | `get isRunning()` | `CursorAfkAnimation.as:125` | ~~호출 0회~~ → **R1 수정(`404615e`)에서 사용됨(해소)** |
| B4 | `get isArmed()` | `ReplayAnim.as:74` | ~~호출 0회~~ → 작업 트리 변경(`if (anim.isArmed) anim.disarm();`)으로 **사용됨(해소)**. 동작 변화는 없음(2.6 참고) |
| B5 | `get totalMs()` | `ReplayClock.as:59` | 앱 코드 호출 0회 (하네스만 사용) |
| B6 | `get frameCount()` | `ReplayClock.as:64` | 앱 코드 호출 0회 (하네스만 사용) |
| B7 | `afkRemainingMs()` | `ReplayClock.as:579` | 호출 0회. 커밋 `0287d01`에서 시크바 AFK 카운트다운을 삭제한 뒤 남은 함수 |
| B8 | `remainingRealMs()` | `ReplayClock.as:671` | 호출 0회. `getReplayRemainingTimeString`이 `remainingRealMsAt`으로 바뀌며 남은 래퍼 |
| B9 | `remainingMsFrom()` | `ReplayClock.as:694` | 호출 0회 |
| B10 | `INFO_DURATION` | `TimingSheet.as:17` | 선언만 존재 (구간 정보 배열은 `SEGMENT_FRAMES` 기반 재생으로 대체됨) |
| B11 | `toTimes()` | `TimingSheet.as:99` | 호출 0회 (누적 시각은 `ReplayClock.loadSegment`가 직접 계산) |
| B12 | `findSegmentByFrame()` | `TimingSheet.as:114` | 호출 0회 |
| B13 | `findSegmentByTime()` | `TimingSheet.as:121` | 호출 0회 |
| B14 | `findSegment()` (private) | `TimingSheet.as:148` | 위 B12에서만 호출 → 함께 데드 |
| B15 | `get isAfkBoxVisible()` | `FOFOCursorSet.as:104` | 호출 0회 |
| B16 | `getAfkBoxBounds()` | `FOFOCursorSet.as:110` | 호출 0회 |

추가 정리 대상(코드 데드는 아니지만 낡음):

- `test-output/timing_sheet/TimingSheetTest.as`: `TimingSheet.decodeSegment(blob, n)`(2인자), `findSegmentByFrame(infos, frame)` 형태를 사용 → **현재 소스로는 컴파일 불가**. 하네스를 최신 API로 고치거나 삭제 필요.
- 반대로 `test-output/realtime_rec/RealtimeRecTest.as`(작성자 하네스, 1038줄)는 현재 API와 맞고 최근 실행 기록도 정상입니다(부록 A).

삭제 시 주의: B5/B6/B15/B16은 기존 테스트 하네스가 사용합니다. 하네스 유지가 필요하면 삭제 대신 "테스트 전용" 주석을 남기는 편이 안전합니다. B1~B4, B7~B14는 앱/하네스 어디서도 쓰이지 않습니다.

## 4. 중복 호출/성능 의심 검토 결과

| 의심 | 판정 | 근거 |
|---|---|---|
| `updateReplayPrograssBarWidthByNowFame`가 매 프레임 AFK 그래픽까지 다시 그림 | **아님** | `SeekBarSet.as:85-96`은 `prograssBar.width`만 설정. `redrawAfkRanges()`는 `updatePos`(`:148`)와 `setAfkRanges`(`:47-50`)에서만 호출 |
| 재생 중 시크바 텍스트 갱신이 무거움(전 구간 순회) | 낮음 | `getReplayRemainingTimeString` → `remainingRealMsAt`이 `gapRanges`를 전부 순회(`ReplayClock.as:633-668`). 1초에 1회(`:929-938`)이므로 무시 가능 |
| `recordedNow()`가 두 타이머(재생 틱/시크바 틱)에서 각각 호출되어 앵커가 흔들림 | **아님** | 동일 배속이면 앵커 재설정이 없음(`ReplayClock.as:516-530`). 배속이 바뀐 직후의 첫 호출에서만 이동 |
| `refreshAfkRanges()` 중복 호출(R6) | 맞음(하) → **수정 완료(미커밋)** | 수정 전: `:109`와 `:119`→`:126`. 수정 후: `onReplaySpeedChanged()` 1회 |
| `pc.replacePoint`류 값 객체 중복 유틸 | 해당 없음 | 이 범위에 값 객체 없음 |
| `TimingSheetFile.frameCount`가 매번 파일 `size` 조회 | 낮음 | `alignTo`/`cutBefore`/`readRange`에서만 호출(`:110` `:197` `:481`), 구간 로딩은 세그먼트가 바뀔 때만 |
| `readPoints` 선형 탐색(R5) | 맞음(하, 성능) | 위 R5 |
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

6. **R5 색인 적용 뒤 선 도구 연출**: 값 등가성은 하네스로 검증했지만, 재생 중 직선 연출(점 순서대로 자라는 선)이 이전과 동일하게 보이는지는 실기기 육안 확인이 필요합니다.

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

- 결과: `RESULT pass=181 fail=0` (`test-output/rt2-review/report.txt`) — R5 색인 검증 12건(`idx.*`, `perf.hits`) + R6 경로 스모크 5건(`r6.*`) + R4 실패 주입 8건(`r4.*`) + R9 이동 종료 위치 9건(`r9.*`) 포함
- R4 실패 주입 시 앱 로그에 `Replay timing sheet read failed: Error #3006: Not a file.`가 찍혀 `rebuild` catch 경로가 실제로 동작함을 확인
- R5 성능 실측(같은 실행 로그, 실행마다 조금씩 다름): `PERF points read x400 over 3000 records: new(index)=29ms old(scan)=148ms` (직전 실행 47ms vs 213ms)
- 전체 앱 컴파일 확인: `sh .../amxmlc -source-path+=E:/fofopaint-source/src ... src/Main.as` → 오류 0 / 경고 0 (`test-output/rt2-review/check-app.swf`)
- 컴파일러 경고: R7 수정(`e1c7aa2`) 이후 0건 (수정 전에는 `ReplayClock.as:358` 1건).
- 이 하네스는 `src/`를 건드리지 않는 별도 테스트 스크립트이며, 필요 없으면 폴더째 삭제해도 됩니다.

### B. 기존 하네스 산출물(작성자 실행 기록)

- `test-output/realtime_rec/report.txt`: AFK 대기 중 시크바 진행(역주행 0회), 5초 캡 후 공백 끝으로 건너뛰어 종료(`END t=5287 now=12/12`), 실시간 재생에서 프레임이 시계를 따라감(`nowFrame` vs `clock due` 일치). → 이 범위의 핵심 동작은 작성자도 헤드리스로 확인한 상태입니다.
- `test-output/timing_sheet/TimingSheetTest.as`: 구 API 사용으로 현재 소스와 불일치(3장 정리 대상).

### C. 검토에서 다루지 않은 것

- 커밋 이전부터 존재하던 코드(리플레이 그리기 파이프라인, 캐시 이미지 워커, 도구 로직 전반)는 이 범위의 변경과 상호작용이 있는 부분만 확인했습니다.
- 커서/캔버스의 최종 렌더 품질(6장)과 실기기 성능(프레임 드랍)은 실행 검증 범위 밖입니다.

### 2.7 미커밋 `ReplayDrawer` 변경(`if (anim.isArmed) anim.disarm();`) 관련 메모

작업 트리에는 `prepareFrameAnim()`의 `anim.disarm()` 호출 3곳(`ReplayDrawer.as:698` `:709` `:723`)을 `if (anim.isArmed)`로 감싼 변경이 있습니다. `disarm()`은 `armedMs = 0` 한 줄이고 `isArmed`는 `armedMs > 0`이므로 **동작은 원래와 완전히 동일**합니다(미arm 상태에서의 호출은 어차피 no-op). 효과는 ① `isArmed`가 사용되면서 데드 코드 B4가 해소된 것뿐이고, R2 회귀를 이 변경으로 막으려던 의도라면 목적을 달성하지 못합니다(슬라이드쇼/점프 경로는 `isRealtimePlay=false`라 arm 자체가 만들어지지 않음). 되돌려도 무해, 남겨도 무해입니다.
