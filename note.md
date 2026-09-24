# fofoPaint 전체 리뷰 노트 — 쉽게 풀어쓴 완전판

> 대상: `src/Main.as`, `src/Global.as`, `src/Modules/*`, `src/Tools/*`, `src/Symbols/*`, `src/worker/*`
> 방식: "지금 상태 → 뭐가 문제인가 → 예시 코드 → 고치면" 순서로 설명합니다.
> 파일 뒤 숫자는 `파일명:줄번호` (예: `AppUpdater.as:167` = 그 파일 167줄 근처).

**총평 한 줄:** 갓클래스(`main.as`)를 파일로 쪼개긴 했는데, 속은 그대로 전역 변수로 엮여 있습니다.
`Main/Global/Canvas/Replay/Tool/Input`이 서로 직접 부르고, 저장/그리기는 통째 복사가 많고,
에러 처리는 비어 있는 곳이 많습니다.

---

# Part A. 취약점 / 예외처리 (터지면 큰 것부터)

## A-1. 자동 업데이트가 해커 통로 (P0, 최우선)

**지금 상태** (`Modules/AppUpdater.as:27-28,118-213`):
1. 깃허브 `versionInfo.txt` 내려받기
2. 버전 다르면 `.air` 내려받아 `updateTmpFile.air`에 저장
3. 해시/서명 검사 없이 `Updater.update()` 실행

`COMPLETE/IO_ERROR`만 잡고 `SecurityError/HTTP_STATUS` 안 잡음.
재시도 상수(`31-32`)는 데드코드, 실제 값은 `186,188,191`에 하드코딩.
`158:deleteFile()`도 try 없음. `81-84:catch`는 타입 없이 삼킴.

**뭐가 문제인가:** 중간자 공격이나 깃허브 탈취 시 가짜 설치 파일이 그대로 실행됨.

**예시 (지금 축약):**
```actionscript
loader.dataFormat = URLLoaderDataFormat.BINARY;
loader.load(new URLRequest("https://github.com/.../fofoPaint.air"));
loader.addEventListener(Event.COMPLETE, function(e:Event):void {
    fs.open(updateFilePath, FileMode.WRITE);
    fs.writeBytes(loader.data); // 가짜라도 저장
    fs.close();
    new Updater().update(updateFilePath, newVersionStr); // 가짜 실행!
});
```

**고치면:**
```actionscript
var expected:String = versionInfo["sha256"];
if (SHA256.hashBytes(loader.data) != expected) { trace("위조! 중단"); return; }
loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onFail);
loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onStatus);
new Updater().update(updateFilePath, newVersionStr);
```
`Main.as:469,475,478,481,484` 외부 위키/릴리즈 URL 하드코딩도 상수로 모으기.

---

## A-2. 그림 파일 하나로 앱이 안 켜짐 (P0)

**지금 상태** (`FileManager.as:393-453,463-510,599-643,1144-1290,1292-1573`, `AppStateManager.as:20-31,131-256`):
`.2020`/자동저장/스크래치/Undo 파일에서 `open → readObject/readInt/readUTFBytes/uncompress → new BitmapData(파일지정 크기) → setPixels → close`를 `try/finally` 없이 직렬 호출.
`d[0]` null 체크 없음. `new BitmapData(d[2],d[3])` 차원 검증 없음. `close()`가 중간 예외 시 안 불림.

대표:
- `396:open` 노트라이, `401:readUTFBytes(9)`, `402:readUnsignedInt`, `412:readObject as Array` 후 `413:d[0]` 무검사, `420,433,440:uncompress` 노트라이
- `470,492,602:open`이 try 밖 (`isNew/isOld/isWebp`)
- `AppState:148:arr[0].uncompress`, `155,164,175,184:new BitmapData(arr[...])` 무검증 — 자동저장 하나 깨지면 시작 크래시

**예시:**
```actionscript
fs.open(file, FileMode.READ);
var d:Array = fs.readObject() as Array; // d[2]=가로, d[3]=세로
var bmp:BitmapData = new BitmapData(d[2], d[3]); // 100000x100000 → 터짐
bmp.setPixels(new Rect(0,0,d[2],d[3]), ba);
fs.close(); // 터지면 여기 못 옴 → 잠금 누수
```

**고치면:**
```actionscript
var W:int = int(d[2]), H:int = int(d[3]);
if (W<=0||H<=0||W>8000||H>8000) { trace("거부 "+W+"x"+H); return null; }
try { fs.open(file, FileMode.READ); /* 읽기 */ }
catch(e:Error){ trace("깨진 파일: "+e.message); }
finally { try{fs.close();}catch(e:Error){} }
```
저장 쪽 `1205:openAsync+1206:writeBytes+1207:close`, `1312,1342,1562:writeObject`도 같은 래퍼 필요.

---

## A-3. 캡처 저장 경로가 뚫림 + 파일명 검사 구멍 (P0)

**지금 상태** (`BackgroundWorkerCoordinator.as:304-349`, `FileManager.as:1029-1078`):
- `310,340:length` null 체크 없음, `314-315:queue[0][0]/[1]` 길이 검사 없음
- `322:lastIndexOf(".png")` 소문자만 → `.PNG` 우회
- `324:replace(fileName,"")` 단순 치환, `329:fs.open(WRITE)` try 없음 → 어디든 덮어쓰기
- `1034:lastIndexOf`가 -1이면 `substr(0,-1)` 오동작
- `1063` 배열 5개인데 `1066:i<3`이라 뒤 2개 절대 변환 안 됨, `"jfif"`는 `.` 누락

**예시:**
```actionscript
var fileName:String = queue[0][0];
var filePath:String = queue[0][1];
fs.open(new File(filePath), FileMode.WRITE); // 허용 폴더 밖도 씀
```

**고치면:**
```actionscript
var base:File = File.documentsDirectory.resolvePath("fofoPaint/");
if (new File(filePath).nativePath.toLowerCase().indexOf(base.nativePath.toLowerCase()) != 0) return;
if (!/\.png$/i.test(fileName)) return;
if (queue==null || queue.length==0 || queue[0].length<2) return;
```

---

## A-4. 드래그/외부 열기 무검증 + 검증용 로드도 위험 (P1)

**지금 상태** (`FileManager.as:647-755,757-844,930-980,982-1027`):
- `734:new File(arguments[0])` 확장자 검사 없이 수용
- `765:FILE_LIST_FORMAT as Array`, `768:data[0] as File` 타입 검사 없음, `763:rFileStream.close()` try 없음
- `945:new File(loadPath)`, `963:file.load()` 후 무조건 열기, `IO_ERROR` 핸들러 없음
- `993:name.substr/cutTimeStamp`, `path.lastIndexOf` -1 오동작, `1023:nativePath` 무검증 큐 삽입
- `700:loader.load(URLRequest(file.url))`는 COMPLETE/IO_ERROR만, `661:new BitmapData(loader.content.width,height)` 0/초대형 시 터짐, `content==null` 역참조

**고치면:**
```actionscript
var allow:Array = ["2020","png","jpg","jpeg","gif","webp"];
var ext:String = (f.extension||"").toLowerCase();
if (allow.indexOf(ext)==-1 || f.size>200*1024*1024) { showMessage("거부"); return; }
// 검증 로드도
if (loader.content==null || loader.content.width<=0 || loader.content.width>8000) return;
```

---

## A-5. 임시 파일명 예측 가능 (P2)

`FileManager.as:254:resolvePath("tmp\\tmp_"+Utils.getRandomString(32))` + `Utils.as:191-206 Math.random()`.
예측 가능 → 같은 PC 다른 프로세스가 가로채기 가능.

```actionscript
// 고친 후
import com.adobe.crypto.UIDUtil;
var name:String = "tmp_" + UIDUtil.createUID();
```

---

## A-6. 정규식 `g` 때문에 색상 들쭉날쭉 (P1, 1글자 수정)

`Symbols/NumPadSet.as:271-275`:
```actionscript
const pattern:RegExp = /^#?[0-9a-fA-F]{6}$/g; // g가 문제
return pattern.test(str);
```
`g+test()`는 `lastIndex` 기억해서 `true→false→true` 교대. 클립보드 판정(`277-302`)에 직접 사용.

```actionscript
trace(p.test("FF0000")); // true
trace(p.test("FF0000")); // false (!!)
```
고치기: `g` 빼기 → `/^#?[0-9a-fA-F]{6}$/`
`CaptureController.as:1663:new RegExp(/_\d{9}/g)` 매번 생성도 상수로 빼기.

---

## A-7. 에러를 묻어버림 + null/캐스팅 구멍 (P1)

- `Main.as:393-412:onGlobalError:e.preventDefault()`로 전부 삼키고 힌트 10초만. IO/OOM 원인 은폐 → 로그 파일 기록 + 치명적이면 팝업.
- `Main.as:456,504:e.target.name` null 가드 없음. `933:substr(11)+parseInt` 무검증 OOB. `195:showAndFadeOut(null)` → `target.alpha` 터짐 + 타이머가 target 강참조(누수). `360:getChildByName` 캐스팅 검증 없음.
- `Global.as:136:getChildAt(0/1)` numChildren 검사 없음. `207:setScale(null)` 무검사. `223:setScaleIndex` 범위 검사 없음 → `242:getUIScale`, `96:getUIColors` OOB.
- `Utils.as:20:getBoundRect(null/stage null)`, `56:setAsTopChild` 경쟁 시 ArgumentError, `230:traceArr` 깊이 제한 없음.
- `CaptureController.as:440:exitCaptureMode` — `{}` 초기값인데 2회 exit 시 `data.x=N/A` → NaN. `1011,1065:getChildByName("captureStampBitmap")` 분기 누락. `1085:addEventListener` 중복 가드 없음. `187:Clipboard.setData` 노트라이.
- `CapStampFontListSet.as:83:getChildByName as Sprite` null인데 `86:getChildAt(0)` → 확정 크래시. `InputController.as:2189` 부분일치로 부름. `55:getChildAt(0) as TextField` 수 검사 없음. `LoadBoxSet.as:158:as SimpleButton`, `getChildAt(0/1)` 무검사.
- `FileManager.as:41-49:static const File=resolvePath(main.APP_STATE_VERSION)` — 클래스 로드 시 `main==null`이면 TypeError. 지연 초기화 필요.

**공통 수정 패턴:**
```actionscript
var btn:SimpleButton = parent.getChildByName(name) as SimpleButton;
if (!btn) { trace("없음: "+name); return; }
try { fs.open(f, FileMode.READ); /*...*/ } finally { try{fs.close();}catch(e:Error){} }
```

---

## A-8. 일꾼(Worker) 대화 어긋남 (P1)

`BackgroundWorkerCoordinator.as:62-180,237-302,351-387` + `worker/BackgroundImageProcessor.as:28-115`:
- `64:receive() as String` 가정, `70,75,80` 큐 null 체크 없음
- 일꾼 디버그 `"compressed "+len`(`worker:62`)은 어떤 분기에도 안 걸림 → `sendCount!=receiveCount`로 영구 실행
- `140:ENTER_FRAME waitWorkerReady` 중복 등록 가능, `163:terminate` 후 리스너 해제 없음
- `243:copyPixels`, `267:send(ByteArray)` null/폐기 검사 없음, `256:bmpd.dispose()` 전송 직후 폐기
- `359:receivedUndo[0][0]`, `undoDataQueue[0][0..5]` 길이 검사 없음
- `worker:28:getSharedProperty` null인데 `addEventListener` → 즉시 크래시. `36:new BitmapData(w,h)` 무검증, `39:ba.position` null 체크 없음. `103:receive()` 검증 없음.
- `199:worker.swf` 로드는 COMPLETE만 → 실패 시 `null` 들고 `187:createWorker(null)` 크래시

**고치면:**
```actionscript
if (msg.indexOf("compressed ")==0) { trace(msg); return; } // 카운트 제외
workerLoader.addEventListener(IOErrorEvent.IO_ERROR, onFail);
workerLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onFail);
if (w<=0||h<=0||w>8000||h>8000||ba==null) return;
```

---

# Part B. 구조 / 중복 / 결합도 (고치면 버그가 줄어듦)

## B-1. 갓클래스가 30개 정적 모듈로 흩어짐

크기 순: `Replay 4136줄 > Input 2600 > Capture 1717 > File 1575 > Canvas 1517 > ToolCtrl 1513 > ColorPicker 1224 > Lasso 1028 > Main 939`.
`Main.as:72-74` "정적 아닌 인스턴스로 가는 게 맞음, 일단 컴파일만 되게 분리" — 본인이 인정한 상태.

**32개 파일 동일 패턴:**
```actionscript
// Pen/Line/Hand/Zoom/Move/Rotate/Lasso/EyeDropper + Canvas/Replay/Input/Tool...
public static var main:Main;
public static function setMainInstance(m:Main):void { main = m; }
// Main.as:107-150 에서 33연타 수동 와이어링
```
유일 예외 `TopMenuSet.as:594:Main._instance` 직접 접근.

**Global도 갓오브젝트** (`Global.as:10` "ui 많아서 따로 정리"라 적음):
38개 파일 확산. `OFFALPHA` 정의 1곳, 사용은 `ToolMenuSet 17회, TopMenu 12회, Replay 11회` + `Main:694,772` 상태 판정으로 굳음.
`getUIScale/getUIBG/FG`가 4파일에 산재 → 색 바꾸면 전역 파급.

**모듈끼리 직접 참조 (별형 아님, 메시):**
`CanvasController.*` 15곳, `ReplayController.*` 7곳, `ToolController.*` 6곳.
`Undo:150 ↔ Replay:86` 상호참조(순환). 단위 테스트 불가.

**고치면:** `Main`이 직접 들고 있는 `AppContext` 하나 만들고 생성자 주입. 당장 다 못 바꾸면 `Canvas/Replay` 접근을 함수(`getCanvasState()`)로 감싸기부터.

---

## B-2. Tools 6벌 복사 (부모 하나로 합치기)

`Pen/Line/Move/Hand/EyeDropper` 전부 문장 동일:
```actionscript
main.stage.addEventListener(MOUSE_MOVE, onMove);
main.stage.addEventListener(MOUSE_UP, onUp);
// 끝나면 remove — Pen:509-510 vs 368, Line:278 vs 200, Move:169 vs 27...
PenSizePreviewCursor.setCursorInVisibleFlag(true/false); // Hand:113/39, Move:167/32...
ReferenceLayerController.setRefLayerAndGridVisible(false/true); // Hand:118/45, Zoom:154/112...
```
`isRefLayerEmpty` 가드(`Pen:371,474` vs `Line:203,269`), 점찍기 폴백(`Pen:405,412` vs `Line:218,238` 인자 순서까지 동일),
`lineStyle`(`Pen:110` vs `Line:159`), 벡터 정규화(`Pen:148` vs `Line:129` vs `Line:100`) 3중복.
`isMouseDragging=false` 주인이 4곳에 분산. `DragInteraction(17-38)` 있는데 `Zoom/Rotate`만 씀.

`Lasso(1028줄)`는 `cLassoTool:734-773` 클로저 팩토리로 감춰놓고 `_isLassoStarted/lassoLayer1`을 `Hand:47, Zoom:137, Rotate:42, Main:764`에서 직접 읽음 — 캡슐화 깨짐 진원지.

**고치면:** `BaseTool.begin/end` 하나로 묶기 (A-9-3 예시 참조). `FillPenTool:356`의 도구→옵션UI 직접 조작도 이벤트로 끊기.

---

## B-3. Symbols 수동 할당 반복

긍정: `VisualFieldCollector.collectNull+VisualBuilder.buildInto` 2줄은 20개 Set에 통일 (`ToolMenu:350`, `TopMenu:660` 등).

잔재:
- `getChildByName+as` 문자열 바인딩 21건: `ToolOptions:275:"nSizeButton"+i`, `ToolMenu:183,301,309`, `CapStamp:85`, `ToolCtrl:244:"alphaButton"+i`, `ToolMenuSet2:59:this[targetName]`
- `ToolOptions:284-604 init*Wrapper` 7연타 + 투명 히트박스 `beginFill+drawRect` 반복
- `TopMenu:35-84` 버튼 40개 선언, 추가 시 주석대로 4곳 수정 강제. `changeUIColor/initModeButtons/initMouseDownState` 분산
- `ToolMenu:97-171 setFillPenMode/setIconAlpha` 8줄 나열 3벌복사
- 역참조: `TopMenu:4` View가 `Sidebar/Capture/Lasso/Canvas/Replay` import

**고치면:** `UIIds` 상수 + `getChild()` 헬퍼(null 체크 내장) + 버튼 테이블(`[{id, icon, hint}]`)로 40개 선언을 루프로.

---

## B-4. 리스너 짝이 안 맞음 + 매직값

- `Main:add24/remove3` — 전역은 의도적이나 문서 없음. `handleMouseClick:501` 클로저 `MOUSE_UP`은 타이밍 어긋나면 중첩.
- `Input:add38/remove39` 겉보기 균형이나 모드별 add/remove 분산 + `Lasso:701` 도구→입력 역호출.
- `File:add17/remove25`, `Canvas:add5/remove9` — remove 과다 = 방어적 중복 해제 흔적.
- `ImageView:add7/remove0` — 닫기는 visible만. 10번 열면 70개 누적.
- 우선순위 매직 `Main:371 true,1 / false,-2 / false,2`, `EyeDropper:293` 분산 → 선점 순서 추적 불가.
- 문자열: `"lineStyle5/dot4/line3/tempDone4"` 버전 숫자 박힘(생성 Pen/Line → 소비 Replay:2127 case). `"alphaButton/nSizeButton/toolPen"` 5파일 동시 수정. `Main:449` 60+ case 메가 스위치 + `HintStrings:331` 2차 스위치.
- 수치: 줌테이블 `Canvas:57`, 펜굵기 `Pen:62`, alpha `Pen:63`, `xSize/5`, `dist<=2.5`, `>=0.2`, `Zoom:26,>20`, `FillPen:>=10/>=6`, `Lasso:<5`, `Main:680/718`, `EyeDropper:<12.0` 전부 인라인. `Math.floor(z*100)+"%"` 5중복(`Main:303,308`, `Zoom:60,157`, `Canvas:469`).

---

# Part C. 성능 (체감이 느린 원인)

## C-1. Bitmap 통째 복사 + dispose 누락 (최대 효과)

- `Canvas:48` 시작 3장 상주(16MB x3). `800:updateCavnvasSize` 구본 dispose 없이 재할당 → 순간 2배.
- `89:updateBitmapData:clone()`만, `85:updateLayer1`도 clone 대입, 구본 폐기 스킵(주석). 호출부 `761,764,647`, `Main:893`, `Undo:114,647` 전부 누수.
- `357:swapLayer:clone x2+fillRect+draw x2+dispose` 피크 32MB+.
- `338:merge:draw`, `654:getMerged:new+draw` 최대 3회 — 저장/캡처/썸네일마다.
- `Capture:175:회전마다 new+draw+dispose(원본)`, `714:썸네일마다 new+getMerged+draw`, `rawbmpd` 미dispose. `507,988:captrueStampBMPD` 매 키입력 재할당.
- `File:85,117:new tmpbmpd+draw(smoothing)+clone x1~2`, `661:validate마다 new+draw`, `421,434,441:썸네일 루프 new+setPixels+draw`, `1176,1225:getMerged+clone` 추가 복사.
- `DrawrScratchPad:46:pickColor new 1x1` 매 클릭. `worker:36:new bmpd+bmpd2` 후 dispose 0.
- `Undo:58:clone x2` 상주 + 전환마다 x2 + `318:new ByteArray x2+Rect+copyPixels x2` 매 인터벌. `File:886:copyPixels x5` 연속.
- 공통: `new Rectangle` 인라인(`Replay:719`, `Ref:511`, `Undo:322`, `File:1311`) + ByteArray 풀 없음.

**고치면:** `old.dispose()` 한 줄 + dirty rect만 복사 + 썸네일은 캐시. 전송은 청크화(A-9-1 참조).

---

## C-2. 매 프레임 타이머 + 마우스 폭증

- `Main:378,381:MOUSE_MOVE` 2중 + `379:MOUSE_UP`에 MOVE 핸들러 오등록.
- `FOFOTimer:15:dummy ENTER_FRAME`가 `for..in+apply` 전수 + 죽은 타이머 2차 삭제. `time=0`은 매프레임.
- `0.0` 루프: `Main:200`, `Canvas:111,146,170`, `Replay:2313,2366`, `MainUI:554`, `Pen:141`, `ToolCtrl:1233`, `Input:163,212`, `FillPen:175`.
- `Pen:124:lineSmoothing` 안에서 `addByName(0.02)` 자기재등록. MOVE마다 `164-301` + 100타마다 `BlurFilter+draw`.
- `ToolMenuSet2:185:ENTER_FRAME` 시작마다 신규, `graphics.clear+line` 매프레임, 중복 시 누적.
- `Replay:3351,3255,2366,2313` 캐시+재생+프로그레스 3중 매프레임. `Coordinator:140` 미실행마다 ENTER_FRAME 추가.
- `MOUSE_MOVE` 무스로틀 15곳: `Pen:509`, `Eye:292`, `Move:169`, `Line:278`, `Lasso:766`, `Hand:126`, `ToolCtrl:471`, `Sidebar:591`, `Canvas:554`, `Capture:1600,1642`, `Input:631,682`, `NumPad:481`.
- `Capture:1153:onMouseMove` 픽셀마다 `round+graphics.clear+fill4+drawRect+showBottomHint(문자열)`.
- `EyeDropper:253:MOVE마다 pickColor+fillRect+draw x3`. `NumPad:436:MOVE마다 pow/exp+256 setPixel+lock/unlock`.

**고치면:** 16ms 스로틀 + Bitmap/문자열 재사용 (A-9-4 예시). `getBounds(stage)` 결과를 MOVE마다가 아니라 캐시.

---

## C-3. 탐색/문자열/배열 비용

- `MainUI:58,63,218,511:getBounds` 매 MOVE/매프레임. `Utils:22:getBounds` 네비 드래그 MOVE마다. `Canvas:106:getChildByName("canvasFlash")` 60fps 틱마다. `Capture:1011:getChildByName` 매 update. `PenSize:41:getBounds` 매 MOVE. `FillPen:265:getBounds` 매 apply. `ToolCtrl:244,824`, `ToolOptions:275`, `ToolMenu:183,301` 매 클릭 조회. `CapStamp:57,67,85` 스크롤/호버마다. `ColorPicker:105:numChildren+getChildAt` 루프, `399:setChildIndex(top)` 드래그 매틱.
- 문자열: `Capture:1663 new RegExp 매번`, `1481:w+" x "+h` MOVE마다, `Replay:2570 timeStr+=`, `2313` 0.0 타이머 문자열 재조립, `ColorPicker:286 split(",")` 매 키입력.
- 배열: `FillPen:379 concat x2` 전체복사, `398:splice O(n)`, `DrawingFinish:27 concat`, `Replay:255,266 concat` 스트로크마다, `Lasso:150,468,577 filters.concat()` 변형마다, `Undo:233 shift,247 splice`, `Replay:284 shift`, `Coordinator:131,334 shift` — 앞제거 O(n)이 저장/undo 핫패스.

**고치면:** `getChildByName` 결과 Dictionary 캐시, `shift` 대신 인덱스 포인터(`head++`), `concat` 대신 `push.apply` / 제자리 갱신, 정규식 상수화.

---

## C-4. Worker 메모리 3중 복사 + UI 블로킹

PNG: UI `copyPixels(16MB)` → `send` 복제 → Worker `setPixels` 3차 → `encode` → `send` 또 복사. `ba.clear()`는 전송 후라 피크 못 줄임.
Undo/리플레이: `compress()` 인플레이스이나 send 시 복사 + UI `writeReplayFile:3354:open+writeUTFBytes+writeObject x3+moveTo` 완료까지 블로킹.
`File:1195:0.5s 폴링+openAsync+writeBytes(전체)`, `AppState:148/uncompress`, `Replay:3467 uncompress` 전부 UI 동기.

**고치면:** 청크 전송 + Worker에서 바로 파일 쪼개 쓰기(가능 시) + 저장은 `openAsync` 유지 + `uncompress`는 크기 먼저 보고 거절.

---

## C-5. Symbols 매프레임 반복 (소소하지만 쌓임)

- `ToolMenuSet2:194:ENTER_FRAME graphics.clear+line`
- `NumPad:542:height(~256)x setPixel(Oklch pow/exp)+lock/unlock` + `572:clear+beginFill+drawRect x2` 동시
- `ColorPicker:418:new ColorMatrixFilter+filters x2+initMyPalette:new BitmapData+draw` 매번, 구본 미dispose. `392:clear+drawRect+setChildIndex(top)` 매틱
- `NavigatorBox:89:updateImage` undo/스왑마다(호출 자체가 스트로크마다) + `44:clear+drawRect` 이동마다
- `LoadBox:110:new tmpbmpd+draw` 후 미사용·미dispose, `137:getChildAt x버튼수+clear+drawRect` 매 열림
- `CapStamp:49:clear+getChildAt TextField` 호버마다, `HintBox:76+MainUI:288:showBottomHint` 캡처 MOVE 매번, `TopMenu:213 graphics.clear` 갱신마다

---

# Part D. 권장 순서표 (P0 → 체감 순서)

| 순서 | 할 일 | 파일 | 효과 | 난이도 |
|------|-------|------|------|--------|
| P0-1 | 업데이트 SHA-256 검증+Security 핸들링 | `AppUpdater.as` | 해킹 차단 | 중 |
| P0-2 | .2020/자동저장 크기 상한+try/finally | `FileManager.as`, `AppStateManager.as` | 깨진 파일 생존 | 하 |
| P0-3 | 저장 경로 화이트리스트+`.png/i` | `BackgroundWorkerCoordinator.as` | 덮어쓰기 차단 | 하 |
| P1-1 | 드래그/외부 열기 확장자+크기 검사 | `FileManager.as` | 악성 파일 차단 | 하 |
| P1-2 | 정규식 `g` 제거 | `NumPadSet.as:271` | 1글자 | 하 |
| P1-3 | `onGlobalError` 로그 기록 | `Main.as:393` | 원인 추적 | 하 |
| P1-4 | `getChildByName as` null 체크 | `CapStamp/LoadBox/Tool*` | 크래시 감소 | 하 |
| P1-5 | worker 로드 실패+프로토콜 분리 | `BackgroundWorkerCoordinator.as` | 멈춤 해소 | 하 |
| 1 | 저장 청크화/`clear()` | `BackgroundWorkerCoordinator`, `FileManager` | 멈춤 해소 | 중 |
| 2 | `clone()` 후 `old.dispose()`+dirty rect | `CanvasController`, `UndoManager` | 메모리 절반 | 하 |
| 3 | `BaseTool`로 6벌 복사 통합 | `Tools/*`, `DragInteraction` | 버그율↓ | 중 |
| 4 | MOVE/ENTER 스로틀+재사용 | `Pen/Eye/NumPad/Capture` | 체감↑ | 하 |
| 5 | 문자열 ID/`CMD_*` 상수화 | `ToolOptions/ToolCtrl/Replay` | 오타 컴파일에 | 하 |
| 6 | 팝업 리스너 해제 | `ImageViewWindow` | 누수 제거 | 하 |
| 7 | `shift`→인덱스, `getChild` 캐시 | `Undo/Replay/Coordinator` | 핫패스↑ | 하 |
| P2 | 임시명 `Math.random`→UID | `FileManager:254`, `Utils` | 예측 차단 | 하 |

> 실제 수정은 한 항목씩 이슈를 쪼개서 진행 권장. P0-1~3이 끝나기 전에는 배포 금지 권장.
