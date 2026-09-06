# Main.as 클래스 분리 리팩토링 계획

> fofoPaint — AS3 → AIR SDK 단독 빌드 전환 작업의 일부

---

## 개요

Main.as(약 22,000줄 갓클래스)를 4단계에 걸쳐 정적(static) 클래스들로 분리한다.
단일 인스턴스 앱이므로 인스턴스 방식 대신 static 네임스페이스 방식을 사용한다.

---

## 1단계 — 독립 기능과 유틸리티

기계적으로 옮겨도 영향이 거의 없는 항목.

- 기존 `FOFOTimer` 직접 사용
- `SearchUtil` — `binarySearchIndex`
- `StringUtil` — `getRandomString`
- `SliderUtil` — `calculateSliderValueFromMouseX`
- `GridOverlay`
- `DragInteraction`
- `ClipboardBridge`

### 예시

```actionscript
public final class GridOverlay
{
    public static const canvasGrid:Shape = new Shape();

    public static var gridGapMultiplier:uint;
    public static var lastGridGapValue:Number;

    public static function drawGrid():void
    {
    }

    private static function clearGraphics():void
    {
    }
}
```

호출부 변경 예:

| 기존 | 변경 후 |
|---|---|
| `gridGapMultiplier` | `GridOverlay.gridGapMultiplier` |
| `drawGrid()` | `GridOverlay.drawGrid()` |

---

## 2단계 — UI·주변 기능·파일 계층

### 대상 클래스 (이동 순서)

1. `WorkspaceUI` — 힌트, 상단·하단 UI, 공통 표시 객체
2. `WindowLayout`
3. `SidebarRuntime`
4. `CanvasWindowRuntime`
5. `ColorPickerRuntime`
6. `PaletteRuntime`
7. `ReferenceLayerRuntime`
8. `BackgroundWorker`
9. `DocumentSession`
10. `CaptureRuntime`
11. `AppUpdate`

### 주의사항 — AppUpdate

`AppUpdate`에는 실제 **앱 업데이트** 관련 메서드만 포함한다.

- ✅ `prepareUpdate`, `startUpdatingApp`, `installNewVersion`, `checkVersion...`
- ❌ `createPosUpdateFunctionByMouseDrag` (위치 갱신 목적 → 무관하므로 제외)

---

## 3단계 — 캔버스와 도구

핵심 드로잉 부분을 4개 클래스로 분리.

```
CanvasRuntime
├─ BitmapData와 Bitmap
├─ 레이어 선택 상태
├─ 캔버스 크기와 배경색
├─ 임시 드로잉 레이어
└─ 레이어 합성·초기화

CanvasTransform
├─ 확대·축소
├─ 회전
├─ 중심 이동
├─ 좌표 변환
└─ 화면 경계 계산

LassoRuntime
├─ 라소 레이어
├─ 선택 상태
├─ 복사·스왑·미러
└─ 변형 적용

ToolRuntime
├─ 현재 도구와 이전 도구
├─ 펜·지우개·에어브러시 상태
├─ 우클릭 도구 상자
├─ 도구 클로저
└─ 기존 PenTool 호출
```

> **주의**: `CanvasRuntime`에 줌·회전·윈도우 좌표 계산까지 전부 넣으면 다시 비대해지므로, `CanvasTransform`을 반드시 별도로 분리한다.

---

## 4단계 — Replay·Undo·입력, Main 정리

가장 강하게 연결된 항목을 마지막에 옮긴다.

```
ReplayRuntime
├─ 재생 상태
├─ 현재 프레임
├─ 속도
├─ 재생/정지
├─ 프레임 이동
└─ 드로우 모드 전환

ReplayCache
├─ 점프 이미지
├─ 임시 캐시 이미지
├─ 캐시 프레임 인덱스
└─ 캐시 생성 상태

ReplayRepository
├─ repFileTemp
├─ rFileStream
├─ replayDataFilePath
├─ 리플레이 파일 읽기·쓰기
└─ 파일 프레임 위치

UndoHistory
├─ undoDataIndex
├─ Undo 기준 이미지
├─ Deep Undo
├─ undo/redo
└─ ReplayRuntime과의 동기화

InputRuntime
├─ KEY_BUFFER
├─ LAST_KEY
├─ 조합키와 반복 입력
├─ 키보드 이벤트
├─ 마우스 입력 분기
└─ 각 Runtime의 public static 메서드 호출
```

> `InputRuntime`은 다른 모든 Runtime의 기능을 호출하므로 **가장 마지막**에 옮긴다.

---

## 정적 클래스 작성 시 주의점

가장 위험한 부분은 메서드 이동이 아니라 **정적 변수 초기화 순서**다.

다음과 같이 다른 클래스의 정적 변수나 `stage`에 의존하는 초기화는 선언 시 바로 생성하지 말 것:

```actionscript
new BitmapData(CANVAS_WIDTH, CANVAS_HEIGHT, true, 0)
new HintBoxSet(stage, true)
cDrawDone()
getRandomFileName()
```

대신 `initialize()` 메서드 안에서 생성한다.

```actionscript
public final class WorkspaceUI
{
    public static var mouseHint:HintBoxSet;

    public static function initialize(stage:Stage):void
    {
        mouseHint = new HintBoxSet(stage, true);
    }
}
```

### Main.onStageAdded() 초기화 순서

```actionscript
CanvasRuntime.initialize();
WorkspaceUI.initialize(stage);
WindowLayout.initialize(stage);
BackgroundWorker.initialize();
DocumentSession.initialize();
ReferenceLayerRuntime.initialize();
CaptureRuntime.initialize();
ReplayRuntime.initialize();
InputRuntime.initialize(stage);
```

---

## 공개 범위(접근 제한자) 기준

| 상황 | 접근 제한자 |
|---|---|
| 다른 클래스에서도 호출 | `public static function drawGrid():void` |
| 해당 클래스 내부에서만 호출 | `private static function rebuildCommands():void` |
| 다른 클래스가 직접 읽거나 변경 | `public static var gridGapMultiplier:uint;` |
| 클래스 내부 상태 | `private static var lastCalculatedGap:Number;` |

---

## 최종적으로 Main에 남길 것

- `onStageAdded`
- 정적 클래스들의 `initialize()` 호출
- AIR 최상위 이벤트
- 예외 처리
- 앱 시작·종료

---

## 전체 작업 순서 요약

1. **Util / Timer / Grid / Drag / Clipboard**
2. **UI / Window / Color / File / Worker / Capture**
3. **Canvas / Transform / Lasso / Tool**
4. **Replay / Cache / Undo / Input / Main 정리**
