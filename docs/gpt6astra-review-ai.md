# worker-test 변경 구간 리뷰 — AI 작업용

## 검토 기준

- 검토 시점: 2026-09-28 밤~09-29, Windows / AIR SDK `51.3.4`.
- 브랜치: `worker-test`.
- 시작 커밋 **포함**: `8c6ad2c26df70bdae4ba5aa74fb96950fc934a11`.
- 마지막 커밋: `f373b6d09f87cf0ab1a9e91016e7b6de2740f333`.
- 실제 비교: `git diff a9021d725e53e40a8554e93e1ba700ea22d428dc f373b6d09f87cf0ab1a9e91016e7b6de2740f333`.
- 6개 커밋, 42개 파일, 텍스트 +1,011/-491행. 로컬 브랜치의 최신 커밋을 고정했다. 원격 fetch는 하지 않았다.
- 줄 번호는 위 마지막 커밋 기준. 검토 대상 소스·배포 SWF·ANE는 수정하지 않았다. 문서의 예시는 적용된 패치가 아니다.
- 이번 범위 밖의 기존 결함을 새 회귀로 재분류하지 않았다. 기존 리뷰 문서는 검증 결과를 그대로 재사용하지 않았다.
- 리뷰 도중 별도로 이동된 기존 `docs/gpt6astra-review.md`는 건드리지 않았다.

**판정 원칙:** 도달 가능한 호출 경로, 구체적인 실패 조건, 정상 동작 조건에 대한 반증을 함께 제시한다. 아래 세 건은 모두 파일 작업 실패 조건에서 분리 실행으로 관찰했다. 정상 파일 권한에서 상시 발생하는 문제라는 뜻은 아니다. 발견 건수를 늘리기 위한 스타일·방어 코드 누락 목록은 만들지 않았다.

## 결과

| ID | 우선순위 | 판정 | 문제 |
|---|---|---|---|
| R1 | P1 | 원본 Undo/Coordinator 경로 실행 재현 | 캐시 임시 폴더 생성 예외가 Undo 기록 이관을 중단하여 디스크/메모리 중복 상태를 남김 |
| R2 | P2 | Windows AIR 51.3.4 권한 제한 조건에서 재현 | 이동되지 않은 캐시 파일의 프레임을 완료 목록에 등록하여 이후 읽기가 실패함 |
| R3 | P2 | 실제 Worker/Coordinator 연결 실행 재현 | 캐시 쓰기 실패 후 재시도 간격이 없어 이후 기록마다 전체 레이어 복사·압축을 반복함 |

P1은 기록 무결성 때문에 우선 수정할 항목, P2는 조건부 기능/성능 문제다. R2는 특히 SDK의 문서상 예외 계약과 실행 결과가 달랐던 환경 의존 항목이다. 다른 AIR 버전·OS에서도 동일하다고 확대하지 말 것.

## R1 — 파생 캐시 준비 실패가 Undo의 필수 상태 변경을 끊음

**도입:** `8ba0361`의 `resetCacheTempFolder()` 및 호출 위치.

**주요 위치**

- [BackgroundWorkerCoordinator.as:330](E:/fofopaint-source/src/Modules/BackgroundWorkerCoordinator.as:330), `startCacheImageWorker()`, 330–335행: `undoDataQueue = []` 후 폴더 준비.
- [BackgroundWorkerCoordinator.as:391](E:/fofopaint-source/src/Modules/BackgroundWorkerCoordinator.as:391), `resetCacheTempFolder()`, 395–407행: 삭제는 catch하지만 `createDirectory()`는 catch 밖.
- [UndoController.as:134](E:/fofopaint-source/src/Modules/UndoController.as:134), `addNew()`, 134–161행: 기존 기록 파일 append → 파일 프레임 증가 → 기준 이미지 갱신 → 캐시 요청.
- [UndoController.as:166](E:/fofopaint-source/src/Modules/UndoController.as:166), 166–179행: 이 **뒤에** 메모리 첫 원소 제거 및 현재 입력 버퍼 확정.

**진입 경로**

`PenTool.onMouseUpPenTool()` → `DrawingFinish.run():94` → `UndoController.addNew():151` → `BackgroundWorkerCoordinator.startCacheImageWorker():334` → `resetCacheTempFolder():407`.

출처: [PenTool.as:371](E:/fofopaint-source/src/Modules/Tools/PenTool.as:371), [DrawingFinish.as:94](E:/fofopaint-source/src/Modules/DrawingFinish.as:94).

**필수 조건**

1. 최근 메모리 기록이 10묶음 이상이고 가장 오래된 묶음이 비어 있지 않다.
2. 파일 프레임과 마지막 완료/진행 캐시의 차가 `10000`을 초과하고 캐시 상태가 COMPLETE이다.
3. 캐시 대기열이 `null`이다.
4. 기존 `repdata` append는 가능하지만 `imagecache_tmp` 생성은 실패한다. 실제 검증에서는 부모 폴더에 현재 계정의 `CreateDirectories` 권한만 거부했다. 기존 파일에 쓰기는 허용했다.

**확인된 결과**

```text
ADD_ERROR id=3003
  BackgroundWorkerCoordinator.resetCacheTempFolder
  BackgroundWorkerCoordinator.startCacheImageWorker
  UndoController.addNew
STATE fileFrames=10001 memoryGroups=10 sameOldest=true buffer=1
      queueIsNull=false queueLength=0
DISK records=2 frames=10001 oldestStillInMemory=1
```

이미 디스크로 보낸 첫 기록이 메모리 첫 원소에 그대로 남았으며 새 입력 버퍼도 확정되지 않았다. 다음 `addNew()`의 125/134/135행은 같은 원소를 다시 append할 수 있다. 중복 직전 상태는 실행 확인, 다음 입력에 따른 중복 append는 제어 흐름으로 확인했다. 전체 UI에서 추가 스트로크까지 자동 재현한 결과로 표현하지 말 것.

빈 배열 `[]`은 `null`과 다르다. 다른 작업으로 Worker가 이미 살아 있었다면 `stopWorkerIfIdle():172`의 `undoDataQueue === null`도 성립하지 않는다. 이 추가 영향은 정적 경로이며 별도의 종료 UI 실험은 하지 않았다.

**반증:** 폴더 생성이 성공하면 정상이다. Worker 내부 파일 쓰기 예외는 응답으로 돌려받으므로 이 현상과 다르다. 삭제 오류를 catch하는 402행은 407행의 생성 예외를 보호하지 않는다. [Main.as:242](E:/fofopaint-source/src/Main.as:242)의 전역 오류 처리도 로그/힌트만 남기며 중단된 `addNew()`를 재개하거나 롤백하지 않는다.

**수정 조건**

- 큐를 만들기 전에 폴더 준비를 완료한다.
- 캐시 준비 실패를 호출자에게 전파해 이미 진행된 Undo 이관을 끊지 않는다. 이 캐시는 원본 명령에서 재생성 가능하다.
- 폴더 준비 실패 시 큐는 `null`로 유지하고 실패 시각을 기록한다(R3와 연결).
- 권장 구조는 필수 기록 이관 완료와 선택적 캐시 예약의 경계를 명확히 하는 것이다. 단순히 `addNew()` 전체를 catch하고 반환하는 것으로는 상태 일관성이 회복되지 않는다.

**회귀 확인:** 위 권한 조건에서 예외가 밖으로 나가지 않음, 파일 append 1회, 가장 오래된 메모리 원소 제거, 새 버퍼 확정, 빈 큐 `null`, 기존 Worker 정상 종료. 권한 복구 후 캐시 재생성도 확인.

## R2 — 파일 이동의 사후조건 없이 캐시 인덱스를 확정

**도입:** `8ba0361`의 `commitCacheImage()`.

**주요 위치:** [ReplayFileCache.as:275](E:/fofopaint-source/src/Modules/ReplayEngine/ReplayFileCache.as:275), `commitCacheImage()`, 285–296행. `moveTo(..., true)` 반환 후 곧바로 `rJumpImageFrameData.push(metadata.nowFrame)`.

**진입/실패 경로**

1. `UndoController.addNew()` → `startCacheImageWorker()`.
2. Worker `writeCacheImage()`가 `imagecache_tmp/1.tmp`를 정상 기록.
3. `onFromWorker():103` → `finishCacheImageJob():379` → `commitCacheImage():287`.
4. `imagecache` 디렉터리는 있으나 그 안의 파일 생성 권한이 거부된 조건에서, 테스트 런타임의 `moveTo()`는 catch로 들어가지 않고 반환했다. 목적 파일은 생성되지 않았고 원본 임시 파일이 남았다.
5. 프레임 목록에는 `10001`이 추가된다.
6. 사용자가 해당 구간으로 탐색: `ReplayDrawer.renderReplayFrame():284` → `drawCacheImageFirst():197` → `loadReplayCacheImage():136`의 읽기 실패.

출처: [BackgroundWorkerCoordinator.as:359](E:/fofopaint-source/src/Modules/BackgroundWorkerCoordinator.as:359), [ReplayDrawer.as:150](E:/fofopaint-source/src/Modules/ReplayEngine/ReplayDrawer.as:150), [ReplayDrawer.as:284](E:/fofopaint-source/src/Modules/ReplayEngine/ReplayDrawer.as:284), [ReplayFileCache.as:132](E:/fofopaint-source/src/Modules/ReplayEngine/ReplayFileCache.as:132).

**실행 결과**

```text
cache image job 1: done
COMPLETED last=10001 total=10001 destinationExists=false tempExists=true
LOAD_CACHE_ERROR 3003
  ReplayFileCache.loadReplayCacheImage
```

동일 테스트의 정상 권한 대조군:

```text
COMPLETED last=10001 total=10001 destinationExists=true tempExists=false
LOAD_CACHE_OK frame=10001
```

**반증/범위 제한:** [AIR 공식 File.moveTo 문서](https://airsdk.dev/reference/actionscript/3.0/flash/filesystem/File.html#moveTo())는 이동 실패 시 예외 발생을 명시한다. 따라서 `catch`가 무조건 잘못됐다고 판정하지 않았다. **이 문서와 다르게 동작한 검토 환경의 재현 결과**가 본 항목의 근거다. 정상 권한이나 실제 예외가 throw되는 실패에서는 기존 코드가 각각 정상 확정 또는 `false` 반환한다. `moveToAsync()`와 혼동하거나 `ioError` 이벤트로 바꾸는 제안을 하지 말 것.

**영향:** 캐시 인덱스와 파일의 불일치, 해당 캐시 구간 탐색 실패. 원본 `repdata`가 지워졌다고 주장할 근거는 없다.

**수정 조건:** 이동 전 임시 파일의 크기/종류 확인, 이동 후 목적 파일 존재·종류·크기 및 원본 임시 경로 소멸 확인을 거쳐서만 프레임 추가. 실패하면 목록을 유지하고 R3의 재시도 제한 적용. 가능하면 읽기 경로도 없는 캐시를 버리고 이전 정상 캐시/원본 명령으로 재생성한다.

**회귀 확인:** 정상 이동, 목적 디렉터리 생성 권한 거부, 목적 파일 잠금, 원본 임시 파일 없음. 확정된 모든 인덱스가 읽을 수 있는 캐시 파일에 대응해야 한다. 권한 거부 외 나머지 실패 조건은 수정 후 추가할 테스트이며 이번에 모두 실행했다는 뜻은 아니다.

## R3 — Worker 오류 후 매 기록마다 캐시를 다시 압축

**도입:** `8ba0361`의 `dataWriteCount` 제거 및 마지막 캐시 프레임 기준 스케줄링.

**주요 위치**

- [UndoController.as:147](E:/fofopaint-source/src/Modules/UndoController.as:147): `fileTotal - getLastCacheImageFrame() > 10000`만으로 재요청 여부 판단.
- [BackgroundWorkerCoordinator.as:300](E:/fofopaint-source/src/Modules/BackgroundWorkerCoordinator.as:300): 진행 중 작업이 없으면 마지막 성공 캐시 프레임 반환.
- [BackgroundWorkerCoordinator.as:367](E:/fofopaint-source/src/Modules/BackgroundWorkerCoordinator.as:367), 367/379–387행: 실패한 작업은 제거하지만 실패 프레임·시각은 보관하지 않음.
- [BackgroundWorkerCoordinator.as:327](E:/fofopaint-source/src/Modules/BackgroundWorkerCoordinator.as:327): 매 요청에서 두 레이어 전체 픽셀 복사.
- [BackgroundImageProcessor.as:92](E:/fofopaint-source/src/worker/BackgroundImageProcessor.as:92), 92/100/113행: 두 레이어를 복사·압축한 **후** 파일 open.

**필수 조건:** 마지막 완료 캐시가 오래되었고, Worker가 임시 폴더 안에 파일을 쓰는 작업이 지속적으로 실패하며, 오류 응답을 받은 뒤 사용자가 다음 기록을 확정한다. 폴더 생성은 가능해야 R1과 분리된다.

**실행 결과:** 기존 `repdata` 쓰기는 허용하고 캐시 디렉터리의 파일 생성을 거부한 조건에서 실제 Coordinator와 Worker를 연결했다.

```text
ADD attempt=1 total=10001 queued=true memoryGroups=10
cache image job 1: error:Error #3001
COMPLETED last=0 total=10001
ADD attempt=2 total=10002 queued=true memoryGroups=10
cache image job 2: error:Error #3001
COMPLETED last=0 total=10002
ADD attempt=3 total=10003 queued=true memoryGroups=10
cache image job 3: error:Error #3001
COMPLETED last=0 total=10003
STOPPED last=0 attempts=3
```

정상 대조군은 첫 성공 후 두 번째/세 번째 기록에서 `queued=false`였다. 오류 실험 로그에 있는 `LOAD_CACHE_ERROR`는 진단 코드가 인덱스 1을 강제로 조회해서 생긴 것이므로 **R3의 앱 증상으로 채택하지 않는다**. R3에서 목록은 `[0]`으로 유지된다.

**반증:** 작업이 진행 중이면 pending metadata의 nowFrame이 중복 요청을 억제한다. 성공했다면 완료 프레임이 같은 역할을 한다. 이 방어는 실패 작업이 제거된 뒤에는 성립하지 않는다. Worker가 영원히 응답하지 않는다고 판정하지 않았다. 실제 테스트에서는 오류 응답을 보내고 최종 종료했다.

**성능 영향:** 2000×2000 두 레이어의 주 스레드 스냅샷만 시도당 `2000*2000*4*2 = 32,000,000`바이트(약 30.5 MiB). 여기에 Worker 복사 및 압축이 추가된다. 비용 발생은 소스/실행으로 확인했으며 이 오류 조건에서의 사용자 FPS나 영구 메모리 누수는 측정/입증하지 않았다.

**수정 조건:** 현재 세대의 실패 시각/시도 프레임을 따로 관리하고, 픽셀 복사 **전에** 재시도 제한 검사. 세대 변경에 의한 취소는 I/O 실패와 구분. 일시 오류 복구를 위해 재시도는 허용하되 매 스트로크마다 재시도하지 않도록 한다. 예: 실패 후 5초 또는 정해진 새 프레임 간격 동안 캐시만 건너뛰기. Undo 기록 자체는 계속 확정.

**관련 진단 개선:** Worker `writeCacheImage():118`은 `open()` 실패에도 무조건 `close()`한다. 쓰기 권한 실패 실험에서 `#3001`이 반환되어 원래 open 실패를 가릴 수 있다. `opened` 플래그와 중첩 `finally`로 원래 오류와 버퍼 정리를 보존할 것. 독립적인 고우선순위 결함으로 중복 계산하지 않았다.

## 픽셀 복원 성능 — 확인된 비용, 결함과 구분

`PixelRestore`는 반투명 값 보존을 위해 추가 연산을 한다. 그 정확성 목적을 무시하고 기존 `BitmapData.setPixels()`보다 느리다는 이유만으로 새 기능을 버그로 분류하지 않았다.

실행: Windows, SDK 51.3.4, `debug=true` SWF / `adl -nodebug`, 2000×2000 투명 BitmapData, 동일색 픽셀, 각 4회. 측정 구간은 복원 호출만이며 입력 ByteArray 복제·PNG 압축 시간은 제외했다. `getTimer()` 밀리초 값이므로 일반 벤치마크나 타 OS 수치로 사용하지 말 것.

| 실행 경로 | 픽셀 알파 | PixelRestore (ms) | 기본 setPixels (ms) |
|---|---:|---|---|
| AS3 대체 경로 / x86 | 255 | 19, 19, 17, 18 | 4, 5, 4, 4 |
| AS3 대체 경로 / x86 | 128 | 49, 50, 48, 52 | 10, 10, 10, 11 |
| 네이티브 / x86 | 255 | 2, 2, 2, 2 | 3, 5, 4, 4 |
| 네이티브 / x86 | 128 | 3, 3, 4, 2 | 10, 11, 11, 10 |
| 네이티브 / x64 | 255 | 3, 3, 2, 2 | 3, 4, 3, 3 |
| 네이티브 / x64 | 128 | 3, 3, 5, 4 | 11, 10, 11, 11 |

초기 테이블/자체 검증 비용은 AS3 22ms, native x86 26ms, x64 23ms였다. 본 실행 조건의 관찰값이다.

Worker에는 ANE 클래스가 없어서 Windows에서도 PNG 저장/캡처는 AS3 경로였다. 출처: [BackgroundImageProcessor.as:45](E:/fofopaint-source/src/worker/BackgroundImageProcessor.as:45), [PixelRestore.as:155](E:/fofopaint-source/src/Modules/PixelRestore.as:155). 배포 `worker.swf` 직접 실행에서도 `PixelRestore: actionscript`, PNG 복원 비교 `0`을 확인했다. 불투명임을 이미 확정할 수 있는 요청에 한해 보정을 생략하는 최적화는 검토 가능하지만 반투명 캡처에 일괄 적용하면 안 된다.

## 반증으로 결함 목록에서 제외한 항목

| 의심 | 확인한 방어/근거 |
|---|---|
| 공유 ByteArray를 main에서 먼저 비워 Worker 데이터가 유실됨 | 새 캐시 경로는 참조만 null로 놓는다(Coordinator 352–354행). Worker는 비공유 복사 직후 원본을 clear(129–134행). 실제 픽셀 2개 및 메타데이터 왕복 일치 |
| shareable ByteArray에 compress하여 #3735 | Worker `copyAndCompress()`에서 새 비공유 ByteArray를 만든 뒤 compress. 원본에 직접 compress하지 않음 |
| 캐시 취소 후 오래된 파일이 재등록됨 | Worker 단계별 generation 검사 + main 완료 시 generation 재검사. `cancelled:0` 실행 확인; 압축 중 모든 경쟁 시점의 완전 탐색은 미실행 |
| 캐시 alias가 달라 load 시 metadata가 null | main `CacheImageMetaData`, Worker `CacheImageMetaDataRecord`의 alias와 9개 필드 일치. 실제 Worker 파일을 main 클래스 타입으로 읽어 frame/lastByte/cursor 확인 |
| native restore의 짧은 ByteArray로 버퍼 초과 읽기 | C 73행 음수 offset 검사, 92–98행 uint64 길이 검사. 짧은 입력은 AS3 최종 #2030으로 종료. 임의 코드 실행/메모리 손상은 입증되지 않음 |
| C의 행 stride/상하 반전 처리 누락 | C 106–107행에서 런타임 descriptor의 isInvertedY/lineStride32 사용 |
| 모든 환경에서 native 클래스 없음 예외가 밖으로 나옴 | `getDefinitionByName()` 실패는 catch 후 AS3로 진행. ANE 없는 분리 실행 성공. macOS 실행 자체는 하지 않음 |
| LUT 또는 ANE가 정상 반투명 픽셀을 계속 변화시킴 | x86/x64 ANE 및 AS3에서 256×256 랜덤 RGBA, 20회 왕복 후 원본 `compare()==0`; 저장 PNG도 비교 0 |
| libwebp domainMemory가 복원 함수 후 바뀐 채 남음 | `remap()` 76/101–105행의 저장/복원 finally 확인. libwebp 연속 디코딩 UI까지 실행한 것은 아님 |
| AS3 remap이 원본 ByteArray를 수정하므로 현재 호출자에서 반드시 오염됨 | 현재 교체된 호출 지점은 읽어온/전달받은 소비용 픽셀 버퍼이며 재사용 가능한 원본으로 두 번 복원하는 경로를 찾지 못함. API 계약 개선 후보일 뿐 확정 버그 아님 |
| 메뉴 지연 타이머 삭제로 메뉴가 닫히지 않음 | `openToolBox2()`가 기존 up 리스너 연결 경로를 유지(InputManager 946–974행). 즉시 열림은 커밋 의도. 실제 닫힘 실패 경로를 입증하지 못해 제외 |
| 사이드바 힌트 변경이 강조 박스를 남김 | `bottomBar.visible || isHighlightBoxVisible()`에서 hideBottomHint 호출. 변경 의도와 일치 |
| private 데드 코드 삭제가 살아 있는 이벤트 경로를 삭제 | 삭제 diff 및 참조, 컴파일 확인. public reflection 필드 일괄 제거 변경이 아님. 컴파일만으로 임베디드 SWF 전체의 무결성을 보증하지는 않음 |
| 5d6d726의 10000 복원이 baseline 대비 캐시 간격 증가 | 시작 커밋 부모도 10000. 중간 커밋 값과 마지막 값만 비교해 최종 회귀로 계산하지 않음 |

## 검증 환경과 재현 자료

산출물 폴더: [test-output/gpt6astra-range-review](E:/fofopaint-source/test-output/gpt6astra-range-review). 이 경로는 저장소에서 ignore되므로 로그·실험 소스는 이 작업 환경에 남아 있으며 Git 문서만 옮기면 함께 전달되지 않는다.

| 검증 | 결과/자료 |
|---|---|
| 실제 Main strict/warnings 컴파일 | 성공, 오류·경고 없음. `Main-review.swf`로 별도 출력 |
| 실제 Worker strict/warnings 컴파일 | 성공, 오류·경고 없음. 테스트 폴더의 `worker.swf`로 별도 출력 |
| 원본 픽셀 복원 코드 + 배포 ANE x86/x64/ANE 없음 | [PixelReview.as](E:/fofopaint-source/test-output/gpt6astra-range-review/PixelReview.as), `pixel-native-x86.log`, `pixel-native-x64.log`, `pixel-as3.log` |
| Worker 정상/실패/취소/PNG | [WorkerReview.as](E:/fofopaint-source/test-output/gpt6astra-range-review/WorkerReview.as), [worker.log](E:/fofopaint-source/test-output/gpt6astra-range-review/worker.log), [worker-shipped.log](E:/fofopaint-source/test-output/gpt6astra-range-review/worker-shipped.log) |
| R1 | [CacheFailureReview.as](E:/fofopaint-source/test-output/gpt6astra-range-review/CacheFailureReview.as), [cache-failure.log](E:/fofopaint-source/test-output/gpt6astra-range-review/cache-failure.log) |
| R2/R3 정상 대조 및 권한 실패 | [CoordinatorReview.as](E:/fofopaint-source/test-output/gpt6astra-range-review/CoordinatorReview.as), [coordinator-normal.log](E:/fofopaint-source/test-output/gpt6astra-range-review/coordinator-normal.log), [coordinator-acl.log](E:/fofopaint-source/test-output/gpt6astra-range-review/coordinator-acl.log), [coordinator-write-failure.log](E:/fofopaint-source/test-output/gpt6astra-range-review/coordinator-write-failure.log) |

분리 앱은 보이지 않는 창과 별도 application id를 사용했다. 캐시 테스트는 사용자 데이터 대신 테스트 폴더 경로를 주입했다. 원본 `UndoController`, `BackgroundWorkerCoordinator`, `ReplayFileCache`, `ReplayState`, Worker의 대상 로직을 그대로 실행했다.

샌드박스에서 앱 저장소 디렉터리 생성이 막혔으므로 테스트 전용 overlay에서 `FileManager.appUpTimePath`와 `AppUpdater.updateFilePath`의 **정적 초기화 경로만** `File.applicationDirectory`로 바꿨다. 캐시·Undo 로직은 변경하지 않았다. Coordinator 테스트는 Main을 상속하되 전체 앱 초기화를 생략하고 필요한 stage/main 참조만 설정했다. overlay 컴파일의 중복 클래스/경로 경고는 의도한 테스트 경로 우선순위 때문이며 제품 Main/Worker 컴파일 경고가 아니다. 초기 하네스 설정 실패는 제품 결함으로 계산하지 않았다.

권한 재현은 테스트 디렉터리의 ACL만 잠시 변경하고 `finally`에서 복원했다. 종료 후 검사한 세 테스트 폴더의 Deny 규칙은 모두 0개였다. 실제 사용자 앱 저장 데이터의 ACL은 수정하지 않았다.

실행 예시:

```powershell
$sdk = 'D:\adobe_air_sdk_manager\AIRSDK_51.3.4'
$review = 'E:\fofopaint-source\test-output\gpt6astra-range-review'
& "$sdk\bin\adl.exe" -nodebug "$review\PixelReview-app.xml" $review
& "$sdk\bin\adl64.exe" -nodebug -extdir "$review\ane" "$review\PixelReview-native-app.xml" $review
& "$sdk\bin\adl.exe" -nodebug "$review\WorkerReview-app.xml" $review
```

권한 재현을 다시 할 경우 R1은 `failure-data`에 `CreateDirectories`, R2는 `coordinator-data/imagecache`에 `CreateFiles`, R3는 기존 `repdata` 파일 권한을 유지한 채 `coordinator-data`의 디렉터리들에만 `CreateFiles`를 거부한다. 각 ACL은 원본을 보관해 반드시 복원한다. 단순 실행은 정상 대조군이며 실패 조건을 자동으로 만들지 않는다.

검토한 배포 바이너리 SHA-256:

```text
worker.swf
65C041188018E419DF7438118D63E4A6D27A0F74FC5A231A308F4234985BDFAE
extension/com.fofo.pixeldump.ane
25A04E046A66A929ABF12216BE2596111AA744A35E898FBFF884650D4EFB4370
```

미실행: 전체 앱 UI 회귀, macOS/Linux 실제 실행, 정식 설치 패키지 생성·자동 업데이트, C 소스 재빌드/정적 분석기, 모든 Worker 경쟁 시점의 스트레스 테스트. 보안 검토에서는 새 네이티브 입력의 길이/offset/stride와 Worker 경로의 출처를 확인했지만, 새로운 임의 코드 실행·경로 탈출 취약점은 입증하지 못했다. 안전성이 완전히 증명됐다는 뜻은 아니다.

## 후속 AI가 지킬 사항

1. R1/R3을 고칠 때 취소 세대 검사를 제거하거나 공유 ByteArray를 main에서 clear하지 말 것.
2. R2를 SDK 전체의 일반 동작으로 설명하지 말고, 위 환경에서 성공/실패 대조를 재현할 것.
3. Worker 파일 쓰기 오류에서 목록이 증가하지 않는 것과, 기록 이관이 계속 완료되는 것을 각각 검증할 것.
4. PixelRestore는 정확성 테스트를 통과했다. 성능만 보고 기본 setPixels로 일괄 회귀시키지 말 것.
5. 코드 수정 후에만 새 Worker/ANE를 필요한 범위에서 다시 빌드한다. 리뷰 문서 작성 과정에서 제품 바이너리는 변경하지 않았다.
