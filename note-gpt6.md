# fofoPaint 구조·안정성 리뷰와 다음 작업 제안

작성일: 2026-09-21 · 대상: 현재 작업 폴더의 `src` 및 `note.md`

**가장 먼저 할 일은 저장 실패·취소 시 현재 그림을 보존하고, 저장 완료 판정을 실제 파일 쓰기 완료에 맞추는 것입니다.** 그다음 시작 시 복구 실패, Worker 실패를 처리하고, 이를 바탕으로 모듈의 상태 소유권을 분리하는 순서를 권합니다.

이 문서는 소스 정적 분석입니다. 앱 실행, 장애 주입, 메모리 프로파일링, 배포된 AIR 패키지 검증은 수행하지 않았습니다. 코드에서 확인한 사실과 실행 검증이 필요한 위험을 구분합니다. 예시 코드는 설계 설명용이며, 그대로 적용해 컴파일·실행한 패치가 아닙니다. 기존 소스와 `note.md`는 수정하지 않았습니다. 아래 파일 위치는 저장소 기준이며 줄 번호는 이번 리뷰 시점 기준입니다.

## 1. 지금 구조를 어떻게 이해하면 좋을까?

파일 분리는 의미 있는 진전입니다. 기능을 찾기 쉬워졌고, `DrawingFinish`, `DragInteraction`, `VisualBuilder`처럼 공통 처리의 출발점도 생겼습니다. 다만 대부분의 모듈이 `static` 상태와 `main:Main`을 공유하고 서로의 내부 데이터를 직접 바꾸므로, **파일 단위 분리는 진행됐지만 책임과 상태의 분리는 아직 진행 중**입니다.

비유하면 한 방에 있던 물건을 여러 방으로 옮겼지만, 어느 방에서든 다른 방 서랍을 마음대로 열 수 있는 상태입니다. 다음 목표는 방을 더 만드는 것보다 “누가 서랍을 관리하는가”를 정하는 것입니다.

### 주요 구성

| 구역 | 현재 역할 | 다음 분리 기준 |
|---|---|---|
| `Main.as` | 시작 순서, 모듈 연결, 전역 입력 이벤트, 메뉴 명령 일부 | 객체 연결과 앱 수명 관리 중심으로 축소 |
| `CanvasController` | 그림·임시 레이어, 크기·줌·회전, 내비게이터, 마우스 상태 | 그림 데이터 / 화면 변환 / 입력 상태 |
| `InputController`, `ToolController`, `Tools/*`, `FillPenTool` | 단축키, 도구 선택·옵션, 그리기·조작 | 입력 해석 / 명령 실행 / 도구별 상호작용 |
| `DrawingFinish`, `UndoManager` | 획 확정, Undo 기록·복원 | 그림 변경을 확정하는 공통 경로 / 이력 저장소 |
| `ReplayController` | 명령 해석·재생, 재생 캔버스, 탐색·캐시, 파일 입출력, 관련 UI | 명령 해석기 / 재생 상태 / 캐시 / 파일 형식 / UI |
| `FileManager`, `AppStateManager`, `AppStateVars` | 사용자 파일, 저장 창, 자동 복구, 설정 직렬화 | 문서 저장 / 복구 저장 / 설정 저장 / 대화상자 |
| `BackgroundWorkerCoordinator`, `worker/*` | PNG 인코딩, Undo·리플레이 압축 | 작업 요청·응답과 실패를 관리하는 서비스 |
| `MainUI`, `MainUIController`, `SidebarController`, 색상·팔레트·참조·캡처 모듈 | 화면 구성과 기능 제어 | 기능별 화면과 해당 상태의 연결 |
| `Symbols/*`, `assets/*` | Animate SWF 심볼과 AS3 필드 연결, UI 동작 | 시각 자산 계약과 표시 역할 |
| `Global`, `Utils`, `FOFOTimer` | 테마·배율·색 계산, 유틸리티, 프레임 기반 타이머 | 순수 계산 / UI 서비스 / 스케줄러 |

현재 큰 파일은 Replay 4,136줄, Input 2,600줄, Capture 1,717줄, File 1,575줄, Canvas 1,517줄, ToolController 1,513줄, Main 904줄입니다. 줄 수 자체가 결함은 아니지만, Replay가 파일 형식부터 화면 조작까지 담당한다는 점은 분리 이유가 됩니다. 도구 경로는 `src/Tools`가 아니라 `src/Modules/Tools`입니다.

### 대표 데이터 흐름

```text
앱 시작
  Main → 모듈·도구 연결 → 캔버스·UI 생성
       → Worker SWF 비동기 로드 시작 → 저장 상태 복구 → 입력 연결

그리기
  Stage 입력 → InputController / 도구
            → 임시 그리기 레이어 + 리플레이 명령 버퍼
            → DrawingFinish.run → 실제 레이어 반영 → Undo 기록

저장
  FileManager → 합성 이미지 생성 → Worker PNG 인코딩 → PNG 파일 쓰기
              → 리플레이 데이터 압축 → ReplayController.writeReplayFile

Undo
  UndoManager ↔ ReplayController → 캔버스 복원
```

여기서 특히 중요한 결합은 `UndoManager ↔ ReplayController`입니다. Undo는 재생 데이터를 바꾸고 재생 기능으로 그림을 복원합니다. 따라서 두 클래스를 단순히 인스턴스로 바꾸는 것만으로 독립시키기는 어렵습니다. 두 기능이 함께 사용할 **이력 데이터와 명령 실행기**를 먼저 추출하는 편이 안전합니다.

## 2. 가장 먼저 고칠 문제

우선순위 의미: **P0**는 그림 손실·실행 불가를 먼저 막는 작업, **P1**은 오류 회복과 큰 구조 결함, **P2**는 측정 후 최적화·유지보수 개선입니다. 보안 공격이 입증됐다는 등급은 아닙니다.

### P0-1. 저장 취소·실패가 다음 작업 진행으로 연결됨

**근거:** `FileManager.as:1144`의 `openSaveFileBrowser`, 특히 `onErrorSaveFileContinue`와 `onErrorEvent`.

- 계속 저장 중 오류가 나면 `isLoadPendingAfterSaving` 조건에서 `loadFileTo("canvas")`를 호출합니다.
- 저장 창의 `Event.CANCEL`과 `IO_ERROR`가 같은 핸들러에 연결되어 있습니다.
- 그 핸들러는 파일 열기 대기 중이면 불러오고, 업데이트 대기 중이면 `AppUpdater.startUpdate()`를 호출합니다.

**사용자가 겪을 수 있는 일:** 현재 그림을 저장하고 다른 그림을 열려다가 저장 창에서 취소했는데, 다른 그림으로 넘어갑니다. 업데이트 전 저장을 취소해도 설치 단계로 넘어갈 수 있습니다. 자동 복구가 별도로 있더라도 사용자가 요청한 저장이 성공했다는 뜻은 아닙니다.

**개선:** 결과를 `SUCCESS`, `CANCELLED`, `FAILED`로 나누고, 후속 열기·업데이트는 성공일 때만 진행합니다. “저장하지 않고 계속”은 별도 명시적 선택이어야 합니다. 취소·실패 때는 대기 플래그도 정리해 나중의 Worker 완료가 예전 작업을 재개하지 않도록 해야 합니다.

```actionscript
// 개념 예시: 호출부가 다음 행동을 소유하고, 저장 서비스는 결과만 반환.
function onSaveFinished(result:String):void
{
    if (result != "success")
    {
        isLoadPendingAfterSaving = false;
        AppUpdater.isUpdatePendingAfterSaving = false;
        return; // 현재 그림과 편집 가능 상태 유지
    }
    continuePendingAction(); // 새로 정의할 후속 작업 함수
}
```

**완료 기준:** 파일 열기 전 저장 취소, 업데이트 전 저장 취소, 접근 권한 없는 경로 저장 실패에서 현재 그림이 유지되고 후속 작업이 실행되지 않습니다.

### P0-2. “저장 요청함”과 “저장 끝남”을 구분하지 못함

**근거:** `FileManager.as:1229`, `1279`에서 `isFileAlreadySaved = true`를 먼저 설정합니다. PNG 쓰기는 이후 폴링 콜백에서 진행됩니다. `ReplayController.as:3354`의 파일 쓰기·이동도 별도 흐름입니다. `BackgroundWorkerCoordinator.stopWorkerIfIdle`은 카운터와 큐 상태로 후속 작업을 실행합니다.

PNG 압축이 끝난 것, PNG 쓰기를 요청한 것, `.2020` 저장이 끝난 것은 서로 다른 사건입니다. 지금 구조는 이들을 하나의 저장 성공으로 묶어 확인하지 않습니다. PNG 저장은 `openAsync → writeBytes → close` 호출 후 버퍼를 비우며, 계속 저장 경로의 오류 리스너도 즉시 제거합니다. 이 호출 순서만으로 파일이 디스크에 성공적으로 저장됐다고 판단해서는 안 됩니다.

추가로 `writeReplayFile`은 압축 결과를 받은 시점의 전역 캔버스 크기·배경·참조 이미지 크기와 `lastSaveFilePath`를 읽습니다. 요청 시점 데이터와 완료 시점 메타데이터가 섞일 여지가 있습니다. 실제로 저장 중 어떤 변경이 가능한지는 입력 차단 경로까지 실행 검증해야 합니다.

**개선:** 저장 한 번을 나타내는 `SaveJob`을 둡니다.

```text
SaveJob
  id, documentId, revision
  pngPath, replayPath
  요청 시점의 크기·배경·레이어·이력 스냅샷
  pngWriteDone, replayWriteDone, failed

두 파일의 필요한 쓰기·닫기·최종 교체가 성공
  → 해당 revision을 저장 완료로 기록
  → 후속 작업 실행
그중 하나라도 실패
  → 미저장 상태 유지, 오류 표시, 재시도 또는 다른 이름 저장
```

파일 쓰기 성공과 Worker 계산 완료를 분리하고, 완료·오류 이벤트는 작업이 끝날 때까지 유지합니다. PNG와 `.2020` 중 하나만 저장된 상황도 사용자에게 명확히 알려야 합니다.

저장 중 새 획이 생기는 경우를 처리하려면 Boolean보다 변경 번호가 좋습니다.

```actionscript
// 새 DocumentState 클래스의 핵심 부분 예시.
private var revision:uint = 0;
private var savedRevision:uint = 0;

public function markChanged():void { revision++; }
public function get isDirty():Boolean { return revision != savedRevision; }

public function acceptSave(savedSnapshotRevision:uint):void
{
    // 해당 문서의 저장을 직렬화하고 성공한 SaveJob에서만 호출.
    savedRevision = savedSnapshotRevision;
}
```

`job.documentId`도 확인해야 합니다. 다른 문서로 전환한 뒤 도착한 옛 결과가 새 문서를 “저장됨”으로 바꾸면 안 됩니다. 변경 번호는 획뿐 아니라 레이어 이동·삭제, 크기 변경, 배경 변경 등 저장되는 모든 변경에 적용해야 합니다.

### P0-3. 초기화 전 `main`으로 정적 파일 경로를 계산함

**근거:** `FileManager.as:41`, `43`.

```actionscript
public static var main:Main;
public static const dataFolderPath:File =
    File.applicationStorageDirectory.resolvePath(main.APP_STATE_VERSION);
```

클래스 정적 초기화가 `setMainInstance()` 본문 실행보다 먼저 필요한데, 그 초기화가 아직 주입되지 않은 `main`을 읽습니다. 현재 소스에서 초기화 순서 결함이 확인됩니다. 실제 배포 바이너리가 이 소스와 같은지, 현재 빌드의 최초 오류가 어디서 발생하는지는 깨끗한 재빌드·실행으로 확인해야 합니다.

**개선:** 앱 버전 같은 불변 설정을 Main 인스턴스에서 분리하거나, 경로를 명시적 초기화 단계에서 만듭니다. 단순히 `Main._instance`로 바꾸면 또 다른 시작 순서 의존성이 생깁니다.

```actionscript
// 별도 파일 예시
package Modules
{
    public final class AppConfig
    {
        public static const STATE_VERSION:String = "2801";
    }
}

// FileManager의 경로 선언은 인스턴스에 접근하지 않도록 변경
public static const dataFolderPath:File =
    File.applicationStorageDirectory.resolvePath(AppConfig.STATE_VERSION);
```

경로 생성 이후 저장 폴더 준비, UI 생성, 파일 복구 순서도 명시합니다. `UndoManager.setMainInstance`처럼 이름은 연결 함수인데 내부 상태 생성까지 수행하는 함수는 `bind`와 `initialize` 책임을 구분하면 순서를 이해하기 쉽습니다.

### P0-4. 손상된 복구 파일 하나가 시작 흐름 전체를 중단할 수 있음

**근거:** `AppStateManager.as:131`의 `loadAppState`, `FileManager.getFinalBitmapDataFrom2020File`, `loadScratchPadImage`, `loadUndoData`.

파일에서 읽은 배열의 길이·타입·크기를 확인하지 않고 `uncompress`, `BitmapData` 생성, `setPixels`를 호출하는 경로가 있습니다. `.2020`의 압축 영역 길이도 남은 파일 길이와 대조해야 합니다. `Main.initializeStage`에서는 복구 이후에 `addGlobalEvents()`를 실행하므로, 그 안에서 등록하는 전역 오류 처리기가 초기 복구 실패를 보호하지 못합니다.

**개선 순서:**

1. 설정·팔레트·그림 복구를 각각 독립된 읽기 작업으로 만듭니다. 팔레트 하나가 깨져도 그림 편집은 시작할 수 있어야 합니다.
2. 파일 크기, 형식 버전, 배열 구조, 숫자 타입·유한성·정수 여부, 픽셀 총량을 검사합니다.
3. 임시 객체에 완전히 복원한 뒤 현재 문서와 교체합니다. 중간 실패 때 기존 그림을 먼저 폐기하지 않습니다.
4. 실패한 복구 파일은 보존하거나 격리하고 기본 상태로 시작합니다. 복구 실패 직후 정상 복구본을 빈 그림으로 덮어쓰지 않도록 합니다.

```actionscript
// 숫자로 된 문자열 등을 허용할지는 파일 버전별 정책으로 결정.
function validateDimensions(w:*, h:*, maxSide:int,
                            maxPixels:Number):void
{
    if (!(w is Number) || !(h is Number) ||
        !isFinite(Number(w)) || !isFinite(Number(h)) ||
        w != Math.floor(w) || h != Math.floor(h) ||
        w < 1 || h < 1 || w > maxSide || h > maxSide ||
        Number(w) * Number(h) > maxPixels)
    {
        throw new ArgumentError("지원하지 않는 이미지 크기입니다.");
    }
}
```

상한은 기존 파일 호환성과 참조 이미지 크기 정책을 확인해 정합니다. UI의 `CANVAS_MAX_SIZE = 2000`과 파일 입력 검증은 별개의 문제입니다. 기존 리뷰의 8000×8000은 안전한 기본값으로 채택하지 마세요. RGBA 한 장만 약 244 MiB이고 여러 레이어·복사본이 동시에 존재할 수 있습니다.

압축 해제 후 `bytes.length == width * height * 4`를 확인하는 것은 필요하지만, **이미 압축을 푼 뒤이므로 압축 폭탄의 메모리 할당을 막지는 못합니다.** `readObject` 자체도 객체를 만들고 나서 검사하게 됩니다. 단기적으로 입력 파일 크기·작업 수를 제한하고, 장기적으로 크기 제한이 가능한 디코딩·블록 형식을 검토하세요. Worker 이동만으로 프로세스 메모리 고갈이 해결되지는 않습니다.

## 3. P1: 실패를 복구할 수 있게 만들기

### 3-1. Worker에 준비 완료·실패·작업 ID가 필요함

**근거:** `BackgroundWorkerCoordinator.as:62`, `100`, `182`, `197`, `worker/BackgroundImageProcessor.as:101`.

- `worker.swf`는 비동기 로드되는데 `startWorker()`는 `workerSWF` 준비 여부를 확인하지 않습니다. 누락·지연 상황의 실패 처리도 없습니다.
- 시작 대기는 `worker.state == "running"` 이후 프레임을 세는 방식입니다. 작업을 받을 준비가 됐다는 명시적 응답이 아닙니다.
- 명령과 인수를 여러 번 `send()`하고, 수신 측은 `receive(true)`로 다음 인수를 기다립니다.
- 작업 ID가 없어 결과와 메타데이터를 큐 순서·전역 변수로 맞춥니다.
- 실패 응답과 타임아웃이 없어 압축 실패 시 대기 플래그·버튼·카운터가 복구되지 않을 수 있습니다.

공식 문서상 `receive(true)`는 메시지가 없으면 해당 실행 스레드를 기다리게 합니다. 메인 측에서도 사용하는 만큼 상대 Worker의 중간 실패를 고려해야 합니다. [AIR MessageChannel 문서](https://airsdk.dev/reference/actionscript/3.0/flash/system/MessageChannel.html)

**개선 예시:** 명령과 인수를 하나의 메시지로 보내고, 응답도 한 덩어리로 돌려줍니다.

```actionscript
// 요청: 경로·문서 정보는 메인 SaveJob에 보관해도 됨.
mainToBack.send({
    protocol: 1, id: jobId, type: "encodePNG",
    width: width, height: height, pixels: pixels,
    background: background, transparent: transparent
});

// 성공 응답
backToMain.send({protocol: 1, id: jobId, type: "result", data: pngBytes});
// 실패 응답: Worker 내부 try/catch에서 전송
backToMain.send({protocol: 1, id: jobId, type: "error", message: error.message});
```

메인에서는 메시지 존재 여부를 확인하며 `receive()`로 처리하고, 타입·ID를 검증합니다. `ready` 응답 이후에만 작업을 시작하고, 타임아웃·Worker 종료 때 해당 작업을 실패로 정리합니다. 큐는 건수뿐 아니라 예상 바이트 총량도 제한해야 합니다. 취소·종료한 작업의 늦은 응답은 무시하고 자원을 회수합니다.

로그 메시지 `"compressed ..."`는 현재 완료 카운터를 증가시키지 않습니다. 따라서 **로그 문자열 자체 때문에 송수신 카운터가 어긋난다는 기존 리뷰의 설명은 맞지 않습니다.** 별도의 로그 메시지 타입은 가독성을 위해 좋지만 진짜 문제는 실패했을 때 완료되지 않는 작업입니다.

### 3-2. 파일 핸들은 성공·실패와 관계없이 닫아야 함

**근거:** `FileManager.as:463`의 `isNew2020File`은 헤더가 다르면 닫은 스트림을 다시 열고 `false`로 끝납니다. `isOld2020File`도 배열 검사 중 조기 반환하면 닫지 않는 경로가 있습니다. 두 함수 모두 최초 `open()`이 `try` 바깥입니다.

이 문제는 일반적인 “null 체크를 더하자”보다 구체적입니다. 파일 검사만 반복해도 핸들이 정리되지 않아 잠금·리소스 문제가 생길 가능성이 있습니다.

```actionscript
function hasFofoHeader(file:File):Boolean
{
    var fs:FileStream = new FileStream();
    var opened:Boolean = false;
    try
    {
        fs.open(file, FileMode.READ);
        opened = true;
        return fs.bytesAvailable >= 9 && fs.readUTFBytes(9) == "FOFOPAINT";
    }
    catch (error:Error)
    {
        return false; // 실제 앱에서는 검사 실패 원인을 로깅
    }
    finally
    {
        if (opened) fs.close();
    }
}
```

실제 공통 래퍼에서는 `close()` 실패도 기록하고 최초 오류가 덮이지 않게 처리합니다. `BitmapData.lock/unlock`, 이벤트 연결·해제도 같은 수명 관리 원칙을 적용할 수 있습니다.

### 3-3. 자동 저장을 여러 파일에 순서대로 덮어씀

**근거:** `FileManager.saveAllAppData`, `AppStateManager.saveAppSatate`와 각 상태 저장 함수.

설정 → Undo → 리플레이 프레임 → 참조 이미지 → 팔레트 → 스크래치 순으로 저장합니다. 중간 실패나 강제 종료가 일어나면 서로 다른 시점의 파일들이 섞일 수 있습니다. 단일 파일의 `try/finally`만으로 해결되지 않습니다.

**개선:** 복구 저장에 세대 번호를 둡니다. 새 세대 폴더에 필요한 파일을 모두 쓰고 검증한 뒤, 마지막에 “이 세대가 완료됐다”는 작은 manifest를 확정합니다. 시작할 때는 완료된 최신 세대를 선택하고 직전 세대도 남깁니다. 설정·팔레트처럼 문서와 독립적인 데이터는 따로 복구할 수 있게 합니다.

사용자 파일도 기존 파일을 바로 열어 잘라내기보다 같은 디렉터리의 임시 파일에 쓴 후 교체하는 방식이 좋습니다. 다만 단순 `moveTo` 한 번을 모든 파일 시스템에서 전원 장애까지 견디는 트랜잭션이라고 설명해서는 안 됩니다. 두 파일을 함께 저장하는 경우에도 부분 성공 복구 정책이 필요합니다.

### 3-4. 타이머 콜백의 예외와 자기 재등록

**근거:** `FOFOTimer.as:15`의 `tick`.

콜백을 호출한 다음 반복 예약 또는 삭제합니다. 콜백이 예외를 던지면 정리 전에 중단되어 같은 타이머가 계속 남을 수 있고, 같은 프레임의 다른 타이머 처리도 끊깁니다. 일회성 콜백이 같은 이름으로 새 타이머를 등록하면, 이전 콜백 뒤의 삭제 로직이 새 타이머까지 지울 수 있습니다.

**개선:** 프레임 시작 때 처리할 키 목록을 고정하고, 콜백 호출 후에도 현재 등록 객체가 이전 객체와 같은지 확인합니다. 콜백 오류는 해당 작업 실패로 전달한 뒤 정리하고, 다른 타이머는 계속 처리합니다.

```actionscript
// tick 내부 설계 조각. remove/add 중인 목록 순회 정책도 함께 정해야 함.
var scheduled:Object = timerList[key];
var keep:Boolean = false;
try
{
    keep = scheduled.func.apply(null, scheduled.args) !== false;
}
catch (error:Error)
{
    reportTimerFailure(key, error); // 로깅 + 소유 작업에 실패 전달
}
if (timerList[key] === scheduled)
{
    if (scheduled.loop && keep)
        scheduled.callTime = getTimer() + scheduled.nextTime;
    else
        delete timerList[key];
}
```

실패 로깅만 하고 저장 버튼을 영구 비활성 상태로 남기지 않도록, 타이머를 만든 작업에 종료 책임을 연결해야 합니다.

### 3-5. 전역 오류 처리는 복구를 대신하지 못함

**근거:** `Main.as:366`의 `addGlobalEvents` 내부 `onGlobalError`.

현재는 메시지를 힌트로 표시하고 `preventDefault()`합니다. 하지만 예외로 중단된 함수의 나머지 처리는 재개되지 않습니다. 저장 플래그·대기 큐·입력 리스너가 중간 상태로 남을 수 있습니다.

오류는 실패한 작업에서 처리해 상태를 정리하고, 전역 핸들러는 마지막 기록 장치로 사용하세요. 앱 버전, 작업 ID, 오류 종류·스택, 문서 크기·모드 정도를 크기 제한 로그에 남기면 좋습니다. 그림 원본이나 전체 개인 경로는 기본 로그에 담지 않는 편이 좋습니다. 초기화 오류 수집은 복구 파일을 읽기 전에 준비합니다.

## 4. 보안·파일 처리: 실제 위험과 과장을 구분하기

### 4-1. 업데이트는 검증 보강이 필요하지만 “가짜 AIR가 그대로 실행”은 입증되지 않음

**근거:** `AppUpdater.as`.

현재 URL은 HTTPS이며, 코드는 AIR `Updater.update()`를 사용합니다. AIR 설치 파일에는 코드 서명이 요구되고, 업데이트 API에는 앱 ID·버전 조건이 있습니다. 따라서 앱 코드에 별도 SHA-256 비교가 없다는 사실만으로 서명 없는 임의 프로그램 실행 취약점이라고 결론 내릴 수 없습니다. [AIR 코드 서명](https://airsdk.dev/docs/development/security/air-security/code-signing), [Updater API](https://airsdk.dev/reference/actionscript/3.0/flash/desktop/Updater.html)

실제로 보강할 부분은 다운로드·파일 쓰기 실패 처리, 시간 제한·용량 제한, 엄격한 버전 파싱, 실패 사유 표시, 릴리스 메타데이터와 파일의 일치 확인입니다. 배포 인증서·키 관리와 인증서 변경 절차도 별도로 점검해야 합니다. 인증서 변경에는 AIR의 마이그레이션 서명 절차가 있습니다. [ADT migrate](https://airsdk.dev/docs/building/air-developer-tool/commands/migrate)

같은 저장소에서 받은 AIR 파일과 해시를 비교하면 전송 오류·배포 불일치 검출에는 도움이 됩니다. 그러나 공격자가 둘 다 바꿀 수 있으면 출처 보증이 되지 않습니다. 출처 보증을 추가하려면 신뢰하는 키로 서명한 메타데이터 등 신뢰 기준이 필요합니다.

현재 코드의 구체적 파싱 문제도 있습니다. `isNewVersion`은 `parseInt()` 결과를 `int`에 넣은 뒤 `isNaN()`을 호출합니다. 유효하지 않은 값이 정수로 변환된 뒤에는 원래의 NaN을 검출하지 못합니다. `parseInt`는 숫자 뒤 쓰레기 문자도 일부 허용하므로 형식을 먼저 검사하세요.

```actionscript
// 현재 major.minor 정책을 유지하는 예시. 각 구간 1~4자리는 제안 정책.
function parseVersion(text:String):Array
{
    if (text == null) return null;
    text = text.replace(/^\s+|\s+$/g, "");
    if (!/^\d{1,4}\.\d{1,4}$/.test(text)) return null;
    var parts:Array = text.split(".");
    return [Number(parts[0]), Number(parts[1])];
}
```

비교용 숫자 배열과 설치 API에 전달하는 정규화된 버전 문자열을 일관되게 관리합니다. 현재 `UPDATE_MAX_DOWNLOAD_RETRY`, `UPDATE_RETRY_DELAY`는 실제로 사용되며, 임시 업데이트 파일 삭제도 `try/catch` 안에 있습니다. 기존 리뷰의 해당 지적은 현재 코드에 적용되지 않습니다.

### 4-2. 파일명 처리 오류는 확인되지만 임의 경로 공격은 별도 입증이 필요함

**근거:** `FileManager.as:1061`, `BackgroundWorkerCoordinator.pollTimerWaitWorkerForSaveCaptureImage`.

`convertToPNGFilePath`에는 확장자 배열 5개를 3개만 순회하는 문제, 소문자로 검사한 뒤 원문에서 다시 소문자 확장자를 찾는 문제, 확장자가 이름 끝인지 확인하지 않는 문제가 있습니다. 캡처 쪽도 `.png` 포함 여부와 문자열 치환으로 경로를 만듭니다. 예를 들어 `picture.JPG`, `picture.png.backup`을 일관되게 다루지 못합니다.

사용자가 저장 창에서 선택한 경로에 쓰는 것은 데스크톱 그림 앱의 정상 기능입니다. 외부 입력이 그 경로를 무단으로 통제한다는 데이터 흐름 없이 “어디든 덮어쓰기 취약점”으로 분류하면 안 됩니다. Documents 아래로 강제 제한하는 수정도 사용자 기능을 깨뜨립니다.

**개선:** 경로와 파일명을 `File.parent`, `File.name`, `File.extension`, `resolvePath`로 다룹니다. 끝 확장자만 대소문자 무관하게 바꾸고, 자동 저장·캐시 경로와 사용자 지정 저장 경로의 정책을 구분합니다. 최종 계산 경로가 대화상자에서 확인한 경로와 달라지면 그 경로의 덮어쓰기 확인도 필요합니다.

```actionscript
// 이름 변환만 담당하는 예시. 최종 덮어쓰기 확인은 호출부 책임.
function asPngFile(selected:File):File
{
    var name:String = selected.name;
    if (!/\.png$/i.test(name))
    {
        name = name.replace(/\.(2020|jpe?g|gif|jfif)$/i, "");
        name += ".png";
    }
    return selected.parent.resolvePath(name);
}
```

캐시 경로를 제한할 때도 단순 문자열 접두어 비교는 피해야 합니다. `C:\cache-other`도 `C:\cache`로 시작하기 때문입니다. 디렉터리 경계와 정규화된 경로를 기준으로 판단해야 합니다.

### 4-3. 외부 파일은 공통 검증 경계를 통과시키기

`FileManager.as:647`의 `validateImageFile`은 먼저 범용 `Loader`로 파일을 로드한 다음 결과를 그림으로 그립니다. 열기 창뿐 아니라 드롭·파일 연결·클립보드 파일 경로도 같은 정책을 적용해야 합니다.

허용 형식·파일 크기·시그니처·디코딩 결과 타입과 크기를 확인하고, 실행 콘텐츠를 이미지로 받지 않도록 로더 정책도 명시적으로 검토하세요. 확장자만 허용 목록에 넣으면 이미지로 이름을 바꾼 다른 형식을 걸러내지 못합니다. 현재 로더 경로에서 실제 코드 실행이 가능한지는 샌드박스·Loader 설정을 포함한 별도 검증이 필요하며, 이번 리뷰에서 공격 성공을 확인한 것은 아닙니다.

`libwebp.swc`는 소스 밖 외부 디코더 의존성입니다. 버전·출처·업데이트 방법을 기록하고 비정상 파일 회귀 테스트를 마련하는 것이 좋습니다. 바이너리 내부의 취약성 유무는 이번 리뷰 범위에서 판단하지 않았습니다.

## 5. 메모리와 성능: 소유권을 먼저 정하기

### 5-1. `dispose()`를 무조건 추가하면 오히려 그림이 사라질 수 있음

**근거:** `CanvasController.as:83`, `89`의 교체 함수, `ImageViewWindow.updateCanvasWindowImage`, Worker의 `encodePNG`, `FileManager.openSaveFileBrowser`.

`updateBitmapData`에는 이전 비트맵을 폐기하면 이미지 적용 문제가 있었다는 주석이 있습니다. 다른 화면이나 Undo가 같은 비트맵을 참조할 가능성을 확인해야 합니다. 참조가 남은 데이터를 폐기하는 것은 누수 해결이 아니라 사용 중 자원 파괴입니다.

`ImageViewWindow`는 내비게이터의 `bitmapData`를 공유합니다. 이런 객체는 “창이 닫힐 때 전부 dispose”로 처리하면 안 됩니다. 먼저 소유자·빌려 쓰는 객체·복사본을 구분하세요.

| 자원 | 권장 소유자 | 정리 시점 |
|---|---|---|
| 현재 문서 레이어 | 문서/레이어 모델 | 모든 뷰를 새 레이어로 연결한 뒤 이전 레이어 폐기 |
| Undo 스냅샷 | 이력 저장소 | 기록 제거 또는 문서 닫기 |
| 저장용 합성 이미지 | SaveJob | 복사·전송 계약이 끝나거나 작업 취소 시 |
| Worker 내부 PNG용 비트맵 | 개별 Worker 작업 | 성공·실패 모두 `finally`에서 폐기 |
| 내비게이터 이미지 | 내비게이터 | 공유 보조 창을 갱신한 뒤 교체 |

`FileManager.openSaveFileBrowser`는 대화상자 선택 전에 합성 이미지를 만들고 다시 clone을 Worker로 보냅니다. 취소·이미 대화상자 열림·재귀 재시도 경로까지 합성 이미지 수명을 관리하는 것이 구체적인 개선 지점입니다. 가능하면 실제 저장 선택 시점에 한 번 만들고 작업에 소유권을 넘기세요.

Worker `encodePNG`의 두 임시 비트맵에는 명시적 `dispose`가 없습니다. GC나 Worker 종료가 결국 회수할 수 있으므로 영구 누수라고 단정할 수는 없지만, 연속 캡처 중 최대 메모리가 커질 수 있습니다.

또한 캔버스 크기 변경 함수는 기존 레이어 1·2를 실제로 dispose합니다. 기존 리뷰의 “크기 변경 시 구본을 전혀 폐기하지 않는다”는 설명은 부정확합니다. 임시 그리기 버퍼와 다른 교체 경로는 별도로 추적해야 합니다.

### 5-2. 최적화는 획의 품질을 지키며 측정하기

RGBA 비트맵은 대략 `가로 × 세로 × 4` 바이트입니다. 현재 기본 600×390은 한 장 약 0.89 MiB, 2000×2000은 약 15.3 MiB입니다. “시작부터 세 장 각각 16MB”라고 보기는 어렵습니다. 최대 크기에서 여러 복사본을 만들 때의 피크가 중요합니다.

먼저 측정할 항목은 큰 문서에서 저장 시작까지 걸리는 시간, PNG·리플레이 저장 시간, Undo 지연, 캡처 연속 실행의 최대 메모리, 포커스 전환 시 자동 저장 시간입니다.

그다음 효과가 확인된 곳부터 처리하세요.

- 펜 입력 좌표와 리플레이 명령은 보존하고, 힌트·커서·썸네일 화면 갱신을 프레임당 한 번으로 합칩니다. 모든 `MOUSE_MOVE`에 16ms 제한을 걸면 곡선·빠른 획이 달라질 수 있습니다.
- 문서 변경 시 내비게이터를 갱신하고, 같은 이미지·같은 크기의 썸네일은 재사용합니다.
- Worker 큐에 큰 이미지가 무제한 쌓이지 않게 합니다. ByteArray 풀·공유 메모리는 수명 규칙이 정리된 뒤 검토합니다.
- `shift`, `concat`, `getChildByName`는 실제 비용을 측정한 뒤 바꿉니다. 작은 배열보다 이미지 복사 한 번이 더 비쌀 수 있습니다.

## 6. 모듈을 진짜 독립시키는 현실적인 순서

### 6-1. Main 참조를 AppContext로 이름만 바꾸지 않기

모든 객체가 모든 기능에 접근하는 거대한 `AppContext`를 주입하면 구조는 거의 같습니다. 클래스마다 필요한 작은 의존성만 전달하는 편이 좋습니다. 순수 색상 변환처럼 상태 없는 함수는 계속 static이어도 됩니다.

권장 목표 구조는 다음과 같습니다. 아래 이름은 새로 제안하는 역할입니다.

```text
Main / AppBootstrap: 생성과 연결
  ├─ DocumentState: 레이어·크기·배경·변경 번호
  ├─ HistoryStore + DrawingCommandExecutor: Undo와 Replay의 공통 기반
  ├─ SaveService + DocumentCodec + WorkerService: 저장과 파일 형식
  ├─ RecoveryStore / PreferencesStore: 복구와 설정
  ├─ ToolSession / InputRouter: 입력 수명과 도구 실행
  └─ 화면 컨트롤러 → Symbols: 표시와 사용자 의도 전달
```

핵심 규칙은 세 가지입니다. 문서 데이터는 화면 버튼을 모르고, 파일 형식 코드는 Stage를 모르며, Worker는 파일 열기나 업데이트를 시작하지 않습니다. 후속 행동은 앱 작업을 조정하는 쪽에서 결정합니다.

### 6-2. 먼저 분리하기 좋은 작은 단위

1. **버전·경로 설정:** 정적 초기화 문제를 제거하면서 시작할 수 있습니다.
2. **파일 읽기/쓰기와 SaveJob:** 데이터 손실 문제와 책임 분리를 함께 해결합니다.
3. **WorkerService:** MainUI·FileManager·AppUpdater 호출을 제거하고 작업 결과만 전달합니다.
4. **DocumentState와 변경 번호:** `isFileAlreadySaved`를 흩어져서 수정하는 방식을 줄입니다.
5. **Replay 명령 실행기:** 파일에서 읽기·UI 갱신과 분리한 뒤 Undo와 공동 사용합니다.

한 클래스씩 인스턴스로 바꾸되 기존 정적 메서드를 잠시 얇은 연결층으로 남길 수 있습니다. 중요한 것은 구 상태와 새 상태를 둘 다 보관하지 않는 것입니다. 같은 `penColor`나 캔버스 크기를 두 객체가 각각 갖고 동기화하면 새 버그가 생깁니다.

### 6-3. 도구 공통화는 상속보다 상호작용 수명부터

`DragInteraction`은 시작·이동·마우스 업을 묶지만 외부에서 취소하는 API가 없습니다. 도구 변경, ESC, 창 비활성화, 문서 닫기에도 같은 정리가 필요합니다.

공통 `ToolSession`이 MOVE/UP 리스너와 타이머를 소유하고 `finish()`와 `cancel()`을 제공하도록 만드세요. 두 함수는 여러 번 호출돼도 안전해야 합니다. 각 도구는 펜이면 획 처리, 줌이면 좌표 변환에 집중합니다.

펜·올가미·손·줌은 종료 의미가 다릅니다. 큰 `BaseTool`에 모든 경우를 넣기보다 이벤트 정리·커서 복원·참조 레이어 표시 복원 같은 공통 수명 기능을 조합하는 편이 낫습니다. `DrawingFinish`는 공통 획 확정 지점으로 유지하면서 이력과 문서 변경 알림을 정리할 수 있습니다.

### 6-4. 모드와 UI 표시를 구분하기

Replay·Capture·도구·드래그·저장 플래그가 여러 클래스에 분산되어 있습니다. 다만 전부 하나의 enum으로 합쳐도 안 됩니다. 캡처가 재생 화면 위에서 작동할 수 있다면 서로 배타적인 단일 모드가 아니기 때문입니다.

먼저 허용 조합을 표로 적으세요. 예를 들어 기본 화면(draw/replay), 캡처 활성 여부, 진행 중 상호작용, 저장 상태는 별도 축이 될 수 있습니다. 그 후 전환 함수에서 취소·입력 연결·UI 반영을 한 번에 수행하도록 합니다. 버튼의 alpha나 visible 값을 실제 기능 상태로 읽는 코드는 명시적 상태 조회로 옮깁니다.

### 6-5. 기존 파일 형식과 시각 자산 계약은 보존하기

리플레이 명령 문자열에 버전 숫자가 붙은 것은 단순 매직 문자열만의 문제가 아닙니다. 옛 그림의 재생 의미가 들어 있을 수 있습니다. 이름을 통일하기 전에 구버전 디코더 → 내부 명령 모델 → 실행기 구조를 만들고, 과거 파일의 마지막 그림이 같은지 비교해야 합니다.

`VisualBuilder`는 없는 심볼을 즉시 오류로 알려주는 좋은 기반입니다. `VisualFieldCollector`가 현재 수집하는 것은 null인 `SimpleButton`, `TextField`입니다. 임의의 Sprite 필드까지 자동 연결한다고 가정하지 않도록 이 규칙을 문서화하세요. 심볼 이름 중복·타입 불일치는 빌드/개발용 UI 생성 검사에서 찾고, 버튼이 없다고 조용히 return하여 기능을 숨기는 방식은 피합니다.

`TopMenuSet`의 `Main._instance` 접근 같은 역참조는 “저장 요청”, “도구 선택”처럼 사용자 의도를 전달하는 콜백/이벤트로 바꿀 수 있습니다. 모든 내부 함수 호출을 이벤트로 바꿀 필요는 없습니다. 직접 의존성이 더 명확한 경우에는 작은 인터페이스가 낫습니다.

## 7. 기존 note.md와 대조한 결과

| 기존 리뷰 주장 | 이번 판단 |
|---|---|
| 전역 static 모듈 간 결합이 크다 | 동의. 다만 static 자체보다 상태 소유권·직접 변경이 핵심 |
| 손상 파일 검사와 스트림 정리가 부족하다 | 동의. 초기 복구와 실제 조기 반환 경로를 우선 수정 |
| 업데이트 해시가 없으니 가짜 설치 파일이 그대로 실행된다 | 과도한 결론. HTTPS·AIR 설치 검증과 서명 체계를 함께 판단해야 함 |
| 업데이트 재시도 상수는 안 쓰며 삭제도 try가 없다 | 현재 코드와 다름. 상수 사용과 삭제 try/catch 확인 |
| 색상 정규식의 g 때문에 판정이 번갈아 바뀐다 | 현재 정규식에 g가 없음. 기존 코드 조각처럼 호출마다 새 RegExp를 만들어도 호출 간 lastIndex가 공유되지는 않음 |
| Worker 로그 문자열 때문에 완료 카운트가 어긋난다 | 로그는 카운터를 증가시키지 않음. 실패 응답 부재가 실제 문제 |
| 보조 창을 열 때마다 리스너가 누적된다 | `canvasWindow == null`일 때만 생성·연결. 재사용 자체를 누수라고 볼 수 없음 |
| 캔버스 크기 변경 시 이전 비트맵을 폐기하지 않는다 | 레이어 1·2 폐기 코드가 있음. 나머지 버퍼·공유 참조는 별도 검토 |
| old.dispose 한 줄이면 메모리가 절반으로 준다 | 소유권 확인 없이 위험. 절반이라는 수치도 측정 근거 없음 |
| 저장 경로를 Documents로 제한해야 한다 | 사용자 선택 저장 기능과 충돌. 캐시 경로와 사용자 경로 정책을 분리 |
| MOUSE_UP에 MOVE용 함수 연결은 잘못된 등록이다 | 커서 최종 갱신 의도일 수 있음. 함수 이름만으로 오류 판정 불가 |
| 리스너 add/remove 개수 차이가 누수 증거다 | 수명·함수 정체성·호출 횟수까지 확인해야 함 |
| 임시 이름을 UID로 바꾸면 예측 공격이 해결된다 | UID 자체가 보안 보장은 아님. 안전한 임시 파일 생성·접근 권한·덮어쓰기 방지가 우선 |

기존 리뷰는 조사할 후보 목록으로 유용합니다. 다만 재현·현재 코드 확인 없이 모든 항목을 결함으로 취급하거나, 제안 코드를 일괄 적용하는 것은 피하는 편이 좋습니다.

## 8. 앞으로의 작업 우선순위와 완료 기준

| 순서 | 작업 | 범위·난이도 | 완료 기준 |
|---|---|---|---|
| 1 / P0 | 정적 경로 초기화 제거·초기 오류 수집 | 작음 | 새 빌드가 복구 파일 유무 양쪽에서 시작 |
| 2 / P0 | 저장 취소·실패 시 후속 작업 중단 | 작음~중간 | 그림 보존, 열기·업데이트 진행 안 함, 대기 플래그 정리 |
| 3 / P0 | SaveJob과 실제 저장 완료 판정 | 중간~큼 | PNG·2020 결과를 함께 확인, 부분 실패 표시, 문서·revision 일치 |
| 4 / P0 | 복구/외부 파일 검증과 복구 실패 격리 | 중간~큼 | 손상 파일이 있어도 편집 시작, 현재 그림·이전 복구본 보존 |
| 5 / P1 | Worker ready·job ID·실패·타임아웃 | 중간 | 누락 SWF·압축 실패·늦은 응답에도 앱이 대기 상태에서 회복 |
| 6 / P1 | 스트림 정리·타이머 오류와 재등록 처리 | 작음~중간 | 반복 파일 검사, 콜백 오류·자기 재등록 검증 통과 |
| 7 / P1 | 복구 저장 세대 관리 | 중간~큼 | 중간 종료 이후 완결된 이전 세대로 복구 |
| 8 / P1 | 확장자·버전 파싱·업데이트 실패 처리 | 작음~중간 | 대문자 확장자·잘못된 버전·다운로드 실패를 일관되게 처리 |
| 9 / P1 | 비트맵 소유권·작업별 자원 회수 | 중간 | 공유 화면 손상 없이 반복 저장·캡처 메모리 추세 안정 |
| 10 / P2 | ToolSession과 모드 전환 정리 | 중간 | ESC·창 전환·도구 변경 후 입력·커서·리스너 상태 정상 |
| 11 / P2 | 문서/이력/명령 실행기 인스턴스 분리 | 큼, 여러 변경으로 나누기 | 순수 명령 실행 검사 가능, Undo·Replay 동일 결과 |
| 12 / P2 | 측정 기반 썸네일·화면 갱신 최적화 | 측정 결과에 따름 | 획 결과를 유지하며 지연·피크 메모리 개선 수치 확보 |

작업 1~4를 한 번의 대형 리팩터링으로 묶기보다, 각각 검증 가능한 작은 변경으로 진행하세요. Worker 결과 전달과 SaveJob 통합은 서로 맞물리므로 필요한 최소 연결을 먼저 넣고 프로토콜 교체를 이어가는 것이 좋습니다.

### 최소 회귀 검증 목록

| 시나리오 | 확인할 결과 |
|---|---|
| 저장 창 취소 후 열기/업데이트 대기 | 현재 그림 유지, 후속 실행 없음 |
| PNG 쓰기 실패 / 2020 쓰기 실패를 각각 발생시킴 | 저장됨 표시 안 함, 부분 성공 안내, 재시도 가능 |
| 저장 도중 새 획 또는 문서 전환 | 이전 저장 결과가 현재 그림의 미저장 표시를 지우지 않음 |
| 복구 파일 없음·0바이트·중간 잘림·잘못된 배열 | 시작 가능, 잘못된 파일 보존, 다른 정상 데이터 복구 |
| 이미지 크기 0·음수·NaN·상한 초과, 압축 데이터 손상 | 제한된 오류로 종료, 문서 교체 없음 |
| worker.swf 누락·로드 지연·작업 실패 | 무한 대기 없음, 버튼·플래그 복구 |
| 타이머 콜백에서 throw / 같은 이름 재등록 | 다른 작업 지속, 새 타이머 보존 |
| 펜·선·올가미 사용 중 ESC·Alt+Tab·도구 변경 | 임시 입력 종료, 화면 표시와 상태 일치 |
| 기존 1레이어·2레이어 파일, 미러·레이어 변경·깊은 Undo | 저장 전후 및 Replay 최종 픽셀 결과 일치 |
| 최대 지원 문서 반복 저장·Undo·크기 변경·보조 창 | 공유 이미지 정상, 메모리 지속 증가 여부 측정 |

현재 `asconfig.json`의 strict·warnings는 켜져 있으므로 유지할 가치가 있습니다. 디버그 설정과 실제 배포 빌드 설정을 분리하고, 앱 SWF와 worker SWF를 같은 소스 기준으로 함께 빌드·패키징하는 절차도 기록하세요. 순수 버전/경로/헤더 검사부터 자동화하고, 저장 실패·Undo·Replay처럼 그림 보존에 직접 영향을 주는 검증을 우선 추가하는 것이 효과적입니다.
