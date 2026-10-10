# 용어집: 5층 리팩토링 (task-19-05-refactor-new)

작성: 2026-10-10 (0단계). 브랜치 `refactor-layers`, 기준 077e56e. 이 파일은 단계마다 갱신한다.

## 1. 층 (0단계에서 사용자가 확정)

| 층 | 이름 | 폴더 (package) | 뜻 |
|---|---|---|---|
| L1 | 데이터 | `Modules.L1Data` | 아무것도 부르지 않는 바닥. 값, 상태, 공용 함수, 형식 정의 |
| L2 | 엔진 | `Modules.L2Engine` | 캔버스, 리플레이, 파일 캐시, 워커 |
| L3 | 기능 | `Modules.L3Feature` | UI를 모르는 편집 동작 (undo/redo, 획 마무리, 레이어 조작 등). 3단계 이후 툴·캡처는 L4로 옮겨 L3는 작아짐 |
| L4 | UI | `Modules.L4UI` | 박스·패널·메뉴 소유, 그리고 마우스·키 입력을 직접 받아 UI를 함께 바꾸는 상호작용 클래스(툴, 캡처, 클립보드, 화면 배치 등). 3단계에서 사용자가 승인해 범위를 넓힘 |
| L5 | 앱 흐름 | `Modules.L5App` | 조립, 모드 전환, 입력 분배 |

규칙: 아래층은 위층을 참조하지 않는다 (R1). 위 → 아래 호출은 자유. 같은 층 안의 순환은 RESULT에 기록.
아래층이 위층에 알릴 때는 `Function` 슬롯을 두고 위층이 등록한다 (R3).

## 2. 이름 결정 기록 (R4)

| 항목 | 결정 | 근거로 제시한 기존 이름 | 날짜 |
|---|---|---|---|
| 브랜치 | `refactor-layers` | 지시서 기본안 | 2026-10-10 |
| 층 이름 | 데이터 / 엔진 / 기능 / UI / 앱 흐름 | 폴더 `~Engine` 관례 | 2026-10-10 |
| 층 주석 형식 | `// 층: L2 엔진 - <역할 한 줄>` (클래스 선언 바로 위, 메타데이터 줄 `[...]`이 있으면 그 위) | 부록 C 주석 관례 | 2026-10-10 |
| 층 폴더 이름 | L1Data / L2Engine / L3Feature / L4UI / L5App (`Modules` 바로 아래) | 코드베이스에서 처음 쓰는 번호 접두사 (사용자 선택) | 2026-10-10 |
| 기능 폴더 | 기존 `DrawEngine`, `ReplayEngine`, `UIEngine`, `CaptureEngine`, `Tools`, `InputManager`를 층 폴더 아래에 유지 | 기존 폴더 이름 | 2026-10-10 |
| 기타 폴더 | `Symbols`, `assets`, `worker`는 그대로 | 이동 위험 | 2026-10-10 |
| 보조 지표 | 의존 측정에 타입 표기(`:B`, `as B`, `is B`, `new B`, `Vector.<B>`) 수를 별도로 표시 | 부록 B | 2026-10-10 |

### 3단계 결정 (2026-10-10)
툴 12개(`PenTool`, `LineTool`, `DotTool`, `DottedLineTool`, `FillPenTool`, `LassoTool`, `MoveTool`, `HandTool`, `ZoomTool`, `RotateTool`, `EyeDropperTool`), `ToolController`, 캡처 3개(`CaptureController`, `CaptureArea`, `CaptureStamp`), `ClipboardManager`, `ActivityWorkTimer`, `ImeController`, `AppUpdater`를 L3 → L4로 층 변경. 근거: 마우스 이벤트·메뉴 상자·힌트·커서·패널 갱신이 한 흐름에 섞인 상호작용 클래스라 슬롯·함수 이동 수십 건 대신 층을 맞춤. 역방향 524 → 147.

### 1단계에서 정한 이름 (2026-10-10)

| 항목 | 결정 | 뜻 | 근거로 제시한 기존 이름 |
|---|---|---|---|
| 키 상태 클래스 | `KeyState` (L1, `Modules.L1Data`) | 키코드 표(`KEY`), 눌린 키 목록(`keyBuffer`), 마지막 키, 키 반복의 단일 소유자 | `MouseState`, ~State 접미사 (ReplayState, AppWindowState) |
| 앱 데이터 경로 클래스 | `AppDataPaths` (L1) | 앱 데이터 폴더(`portable_<버전>`)와 그 안의 파일·폴더 경로(변수 16개), 크래시 로그 쓰기·열기, 불러오는 중 플래그 | 코드의 AppData(saveAllAppData, loadAppUpTimeFromAppData), 변수 접미사 ~Path |
| 경로 초기화 함수 | `AppDataPaths.initialize(appStateVersion)` | `AppStateManager.setMainInstance`가 `main.APP_STATE_VERSION`을 넘겨 부름 (옛 위치에서 하던 시점 그대로) | `initialize…` 5곳 (사용자 선택), 인자는 상수 APP_STATE_VERSION의 camelCase |
| 툴 상태 클래스 | `ToolState` (L1) | 툴 번호(`TOOL_*`), 지금 고른 툴(`nowTool`), 백업해 둔 이전 툴(`lastTool`)과 이 변수만 읽고 쓰는 함수 7개 | `MouseState`, `KeyState` |

### 2단계에서 정한 이름과 결정

| 항목 | 결정 | 뜻 |
|---|---|---|
| 보고용 슬롯 명명 규칙 | `on` + 사건 + `Func` (예: `onToolChangedFunc`) | 아래층의 `public static var …:Function`. 위층이 `Main.registerSlots`에서 등록. 근거: Function 변수의 `~Func` 접미사 관례 (mainPickColorFunc 등) |
| 슬롯 등록 메서드 | `Main.registerSlots()` | `initializeModule` 끝에서 부름 (`loadAppState`보다 앞) |
| 올가미 이미지 상자 클래스 | `LassoLayers` (L2) | 올가미 표시 객체(상자 1, 2)와 이미지 옮기기·바꾸기 함수 |
| 이동한 함수 이름 규칙 | 팔레트로 옮긴 색 히스토리 함수는 `…ColorHistory` 접미사 | `selectColorHistory` 등 |
| 층 변경 | `CanvasViewport`, `DrawViewport`, `ReplayViewport` L2 → L4 | 사이드바·상단 바·UI 여백에 따라 캔버스 위치를 계산하는 화면 배치 클래스라 UI 층으로 (사용자 승인) |
| 층 변경 | `UndoHistory` L1 → L2 | 값을 읽는 L2 클래스(DrawCanvas, ReplayDrawer 등)가 많아 엔진 층으로 (사용자 승인) |

### 1단계 이후 새 L1 클래스의 위치
`KeyState`, `AppDataPaths`, `ToolState`는 모두 `Modules.L1Data`(루트)에 있다.

## 3. 층 배치 확정 (부록 A 초안 대비 변경)

부록 A 초안과 다른 곳은 한 곳뿐이다: `DrawrScratchPad` L2 → **L4** (ColorPickerSet이 만들어 쓰는 UI 위젯).
애매함 목록의 나머지 결정: HintController, CanvasNavigator, PenSizePreviewCursor, PenCursorPreviewPixel = **L4**, UITheme, ColorHistory, HintStrings, Utils = **L1**.
층이 나중에 바뀌면 그 클래스는 한 번 더 옮긴다 (3-5).

## 4. 기존 코드의 이해하기 어려운 이름 (해당 코드의 주석에서 가져옴)

| 이름 | 뜻 | 출처 |
|---|---|---|
| R0, T0 (ReplayClock) | 재생 시작 지점의 녹화 시각 R0, 그때의 `getTimer()` 값 T0. 지금 녹화 시각 R = R0 + (getTimer() - T0) * 배속 | ReplayClock 머리 주석 |
| 연출 (ReplayAnim) | 채우기(fill5), 올가미(lasso2), 이동(move, move1, move2) 명령을 실시간 재생할 때 보여주는 효과. 길이는 타이밍 시트의 연출 길이(그 도구를 시작해서 끝낼 때까지 걸린 시간) | ReplayAnim 머리 주석 |
| 타이밍 시트 (TimingSheet) | 명령(프레임) 하나마다 직전 명령과의 간격(ms)을 기록한 표. 프레임 i의 시각 = delta[0] + ... + delta[i] | TimingSheet 머리 주석 |
| TimingSheetFile | repdata 파일에 들어 있는 프레임마다의 시간 기록을 이어 쓴 파일. 프레임 하나는 uint 둘(8바이트): 직전 프레임과의 간격(ms), 그 명령의 연출 길이(ms) | TimingSheetFile 머리 주석 |
| 딥 언두 (Deep Undo) | UndoController 안의 별도 undo 방식. 자세한 정의는 코드 주석에 없음 (확인 필요) | UndoController |
| rMemoryData / rMemoryDataBuffer | 메모리 undo 데이터 (UndoHistory 머리 주석: `ReplayState.rMemoryData`) | UndoHistory 머리 주석 |
| 접두사 `r` | 리플레이 쪽 변수 (`rNowFrame`, `rCanvasPanel` 등, static 53개) | 부록 C |
| CAP_MS / ENTRY_MS (ReplayClock) | 리플레이 대기 건너뛰기 규칙의 상수 (대기가 CAP_MS를 넘으면 CAP_MS만 기다리고 나머지는 건너뜀) | ReplayClock 주석 |
| FRC2 / FCI2 | 리플레이 블록 형식("FRC2"), 캐시 이미지 파일 형식("FCI2") 식별자 | ReplayDataCodec, CacheImageFormat 머리 주석 |
| ~Set (Symbols) | FLA 라이브러리의 화면 묶음 클래스 | 부록 C |

## 5. 명명 관례 (부록 C, 077e56e 기준)

- 클래스 접미사: `~Controller`(UI·기능 관리), `~Manager`, `~State`, `~Settings`, `~History`, `~Tool`, `~Set`, `~File`, `~Engine`(폴더)
- 함수 동사 빈도: `on` 238, `set` 189, `get` 174, `update` 150, `is` 94, `start` 68, `show` 47, `reset` 45, `apply` 34, `handle` 33, `add` 26, `check` 25, `remove`·`hide` 19, `create` 18, `clear` 17, `toggle` 16, `save` 15, `load` 13, `stop`·`exit` 5, `enter` 4
- 초기화: `init` 7곳, `initialize…` 5곳 (혼용)
- 불리언: `is…ON` 14개, `…Flag` 61개
- 타이머 이름 문자열: `…Timer` 접미사
- 주석: 한국어, 함수 바로 위 `//` 한 줄, 클래스 머리에 역할 설명 여러 줄

## 6. 클래스별 목적지 (폴더 이동은 각 클래스를 처음 손대는 단계에서 함, R9)

- 현재 package가 `(루트)`인 클래스 중 `Main`만 제자리 (document class). 나머지 루트 클래스(AppWindowState, DrawrScratchPad, FOFOTimer, HintStrings)는 층 폴더로 옮긴다: 옮길 때 사용처에 import가 추가된다.
- `worker`가 import하는 CacheImageFormat, PixelRestore, ReplayDataCodec를 옮기면 worker.swf를 다시 빌드한다 (3-5).
- 같은 이름의 기능 폴더가 층마다 생긴다 (예: `L1Data.ReplayEngine`, `L2Engine.ReplayEngine`, `L5App.ReplayEngine`). 클래스 이름은 겹치지 않는다.

| 클래스 | 층 | 현재 package | 목적지 package |
|---|---|---|---|
| AppStateVars | L1 | Modules | Modules.L1Data |
| CacheImageFormat | L1 | Modules | Modules.L1Data |
| CacheImageMetaData | L2 | (층 변경) | Modules.L2Engine |
| ColorHistory | L1 | Modules | Modules.L1Data |
| DragInteraction | L1 | Modules | Modules.L1Data |
| FOFOTimer | L1 | (루트) | Modules.L1Data |
| HintStrings | L4 | (층 변경) | Modules.L4UI |
| InputPriority | L1 | Modules | Modules.L1Data |
| MouseState | L1 | Modules | Modules.L1Data |
| NativeCacheJobs | L1 | Modules | Modules.L1Data |
| NativeCore | L1 | Modules | Modules.L1Data |
| NativeSave | L1 | Modules | Modules.L1Data |
| PixelRestore | L1 | Modules | Modules.L1Data |
| ReplayDataCodec | L1 | Modules | Modules.L1Data |
| UndoHistory | L2 | Modules.L1Data | Modules.L2Engine |
| Utils | L1 | Modules | Modules.L1Data |
| ReplaySaveMetaData | L1 | Modules.ReplayEngine | Modules.L1Data.ReplayEngine |
| ReplayState | L2 | (층 변경) | Modules.L2Engine.ReplayEngine |
| TimingSheet | L1 | Modules.ReplayEngine | Modules.L1Data.ReplayEngine |
| TimingSmoother | L1 | Modules.ReplayEngine | Modules.L1Data.ReplayEngine |
| PenSettings | L1 | Modules.Tools | Modules.L1Data.Tools |
| UITheme | L1 | Modules.UIEngine | Modules.L1Data.UIEngine |
| VisualBuilder | L1 | assets | assets |
| VisualFieldCollector | L1 | assets | assets |
| BackgroundWorkerCoordinator | L2 | Modules | Modules.L2Engine |
| CacheImageFile | L2 | Modules | Modules.L2Engine |
| CanvasViewport | L4 | (이전 L2) | Modules.L4UI |
| CanvasLayers | L3 | (층 변경) | Modules.L3Feature.DrawEngine |
| CanvasResizer | L4 | (층 변경) | Modules.L4UI.DrawEngine |
| CanvasView | L2 | Modules.DrawEngine | Modules.L2Engine.DrawEngine |
| DrawCanvas | L2 | Modules.DrawEngine | Modules.L2Engine.DrawEngine |
| DrawViewport | L4 | (이전 L2) | Modules.L4UI.DrawEngine |
| HandDrawnLine | L2 | Modules.DrawEngine | Modules.L2Engine.DrawEngine |
| StrokeBuffer | L2 | Modules.DrawEngine | Modules.L2Engine.DrawEngine |
| ReplayAnim | L2 | Modules.ReplayEngine | Modules.L2Engine.ReplayEngine |
| ReplayClock | L2 | Modules.ReplayEngine | Modules.L2Engine.ReplayEngine |
| ReplayCommandWindow | L2 | Modules.ReplayEngine | Modules.L2Engine.ReplayEngine |
| ReplayCursorFollow | L4 | (층 변경) | Modules.L4UI.ReplayEngine |
| ReplayDrawCommands | L2 | Modules.ReplayEngine | Modules.L2Engine.ReplayEngine |
| ReplayDrawer | L2 | Modules.ReplayEngine | Modules.L2Engine.ReplayEngine |
| ReplayFileCache | L2 | Modules.ReplayEngine | Modules.L2Engine.ReplayEngine |
| ReplayViewport | L4 | (이전 L2) | Modules.L4UI.ReplayEngine |
| TimingSheetFile | L2 | Modules.ReplayEngine | Modules.L2Engine.ReplayEngine |
| PenStabilizer | L2 | Modules.Tools | Modules.L2Engine.Tools |
| ActivityWorkTimer | L4 | (층 변경) | Modules.L4UI |
| AppUpdater | L4 | (층 변경) | Modules.L4UI |
| ClipboardManager | L5 | (층 변경) | Modules.L5App |
| DrawingFinish | L3 | Modules | Modules.L3Feature |
| ImeController | L4 | (층 변경) | Modules.L4UI |
| ImeDiagnostics | L3 | Modules | Modules.L3Feature |
| UndoController | L3 | Modules | Modules.L3Feature |
| CaptureArea | L4 | (층 변경) | Modules.L4UI.CaptureEngine |
| CaptureController | L4 | (층 변경) | Modules.L4UI.CaptureEngine |
| CaptureStamp | L4 | (층 변경) | Modules.L4UI.CaptureEngine |
| DotTool | L4 | (층 변경) | Modules.L4UI.Tools |
| DottedLineTool | L4 | (층 변경) | Modules.L4UI.Tools |
| EyeDropperTool | L4 | (층 변경) | Modules.L4UI.Tools |
| FillPenTool | L4 | (층 변경) | Modules.L4UI.Tools |
| HandTool | L4 | (층 변경) | Modules.L4UI.Tools |
| LassoTool | L4 | (층 변경) | Modules.L4UI.Tools |
| LineTool | L4 | (층 변경) | Modules.L4UI.Tools |
| MoveTool | L4 | (층 변경) | Modules.L4UI.Tools |
| PenTool | L4 | (층 변경) | Modules.L4UI.Tools |
| RotateTool | L4 | (층 변경) | Modules.L4UI.Tools |
| ToolController | L4 | (층 변경) | Modules.L4UI.Tools |
| ZoomTool | L4 | (층 변경) | Modules.L4UI.Tools |
| AboutBoxController | L4 | Modules | Modules.L4UI |
| CanvasGridOverlay | L4 | Modules | Modules.L4UI |
| ColorPickerController | L4 | Modules | Modules.L4UI |
| DrawrScratchPad | L4 | (루트) | Modules.L4UI |
| ImageViewWindow | L4 | Modules | Modules.L4UI |
| LoadBoxController | L5 | (층 변경) | Modules.L5App |
| PaletteController | L4 | Modules | Modules.L4UI |
| PenCursorPreviewPixel | L4 | Modules | Modules.L4UI |
| PenSizePreviewCursor | L4 | Modules | Modules.L4UI |
| ReferenceLayerController | L4 | Modules | Modules.L4UI |
| SidebarController | L4 | Modules | Modules.L4UI |
| LayerPreview | L4 | Modules.DrawEngine | Modules.L4UI.DrawEngine |
| ReplayMouseAutoHide | L4 | Modules.ReplayEngine | Modules.L4UI.ReplayEngine |
| ToolPanel | L4 | Modules.Tools | Modules.L4UI.Tools |
| CanvasNavigator | L4 | Modules.UIEngine | Modules.L4UI.UIEngine |
| HintController | L4 | Modules.UIEngine | Modules.L4UI.UIEngine |
| UIController | L4 | Modules.UIEngine | Modules.L4UI.UIEngine |
| AboutWindowSet | L4 | Symbols | Symbols |
| CanvasInfoSet | L4 | Symbols | Symbols |
| CanvasNavigatorBoxSet | L4 | Symbols | Symbols |
| CapStampFontListSet | L4 | Symbols | Symbols |
| ColorPickerSet | L4 | Symbols | Symbols |
| EyedropperLensSet | L4 | Symbols | Symbols |
| FOFO | L4 | Symbols | Symbols |
| FOFOCursorSet | L4 | Symbols | Symbols |
| FillPenMenuSet | L4 | Symbols | Symbols |
| HintBoxSet | L4 | Symbols | Symbols |
| LassoMenuSet | L4 | Symbols | Symbols |
| LoadBoxSet | L4 | Symbols | Symbols |
| NumPadSet | L4 | Symbols | Symbols |
| RefLayerMenuSet | L4 | Symbols | Symbols |
| RotateCursorSet | L4 | Symbols | Symbols |
| SeekBarSet | L4 | Symbols | Symbols |
| SidePanelSet | L4 | Symbols | Symbols |
| ToolMenuSet | L4 | Symbols | Symbols |
| ToolMenuSet2 | L4 | Symbols | Symbols |
| ToolOptionsSet | L4 | Symbols | Symbols |
| TopMenuSet | L4 | Symbols | Symbols |
| Main | L5 | (루트) | (루트) |
| AppStateManager | L5 | Modules | Modules.L5App |
| AppWindowState | L5 | (루트) | Modules.L5App |
| FileManager | L5 | Modules | Modules.L5App |
| CaptureModeInput | L5 | Modules.InputManager | Modules.L5App.InputManager |
| DrawModeInput | L5 | Modules.InputManager | Modules.L5App.InputManager |
| InputManager | L5 | Modules.InputManager | Modules.L5App.InputManager |
| ReplayModeInput | L5 | Modules.InputManager | Modules.L5App.InputManager |
| ReplayController | L5 | Modules.ReplayEngine | Modules.L5App.ReplayEngine |
| KeyState | L1 | (신설) | Modules.L1Data |
| AppDataPaths | L1 | (신설) | Modules.L1Data |
| ToolState | L1 | (신설) | Modules.L1Data |
| LassoLayers | L2 | (신설) | Modules.L2Engine |
