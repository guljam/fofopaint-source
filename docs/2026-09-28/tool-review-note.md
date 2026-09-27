# Tools 정적 리뷰 노트 (2026-09-28)

## 범위

`src/Modules/Tools/` 안의 PenTool.as를 제외한 모든 툴

| 파일 | 줄 수 |
|---|---|
| LassoTool.as | 1049 |
| LineTool.as | 395 |
| EyeDropperTool.as | 361 |
| ZoomTool.as | 194 |
| MoveTool.as | 188 |
| HandTool.as | 133 |
| RotateTool.as | 109 |
| DottedLineTool.as | 72 |
| DotTool.as | 48 |

## 리뷰 원칙

- 각 의심 항목마다 **"이 코드가 정상 동작하는 조건"** 을 먼저 찾아 반증을 시도했고, 반증되면 본문 목록에서 빼서 맨 아래 [반증되어 제외된 항목](#반증되어-제외된-항목)에 근거와 함께 남겼습니다.
- 본문 항목에는 모두 **재현 경로(호출 출처 `파일:줄`)** 를 적었습니다.
- 런타임 측정 없이 판단한 성능 항목은 **"의심"** 으로 표시했습니다.

---

## 요약

| ID | 분류 | 심각도 | 파일 | 한 줄 요약 |
|---|---|---|---|---|
| B1 | 버그 | **중** | MoveTool.as:45 | 1번 레이어가 숨겨진 상태에서 움직이면 2번 레이어가 **화면에서만** 밀린 채로 남음 (데이터·리플레이 반영 안 됨) |
| B2 | 버그 | 중하 | MoveTool.as:45 | 1px 미만 드래그(확대 상태)에서 레이어 표시 위치가 소수점만큼 어긋난 채로 남음 |
| B3 | 버그 | 중하 | EyeDropperTool.as:308 | 레이어가 체크된 상태에서 `C`/`M`을 누르면 툴박스 커서만 스포이드로 가고 실제 툴은 그대로임 |
| B4 | 버그 | 하 | LassoTool.as:431 | 미러된 라소 이미지는 같은 배율에서도 다른 강도로 샤픈됨 (리플레이 전용) |
| P1 | 성능 | 중 | MoveTool.as:38 | 움직이지 않은 클릭에도 캔버스 크기 BitmapData를 매번 할당하고 dispose하지 않음 |
| P2 | 성능 | 하 | LassoTool.as:502 | 레이어 하나만 선택해도 라소 비트맵 2장을 항상 할당 (라이브·리플레이 둘 다) |
| P3 | 성능 | 하 | LassoTool.as:757 | 체크된 레이어와 상관없이 보이는 레이어를 전부 캔버스 크기로 clone |
| P4 | 성능(의심) | 하~중 | LassoTool.as:613 / DottedLineTool.as | 라소 미리보기가 100ms마다 경로 전체를 다시 그림: 드래그가 길어질수록 O(N²) |
| P5 | 성능(의심) | 하 | EyeDropperTool.as:254 | MOUSE_MOVE 한 번마다 같은 점을 hitTest 2번, 렌즈에 draw 3번 |
| D1 | 중복 | 정리 | EyeDropperTool.as:320 | `updateLastTool()` 결과를 바로 다음 줄에서 덮어씀 |
| D2 | 중복 | 정리 | LassoTool.as:1005 | `colorPickerBox.alpha = 1.0`을 두 번 설정 |
| D3 | 중복 | 정리 | LassoTool.as 3곳 | 대상 레이어(l1/l2) 계산 로직이 세 곳에 서로 다른 모양으로 복제됨 |
| D4 | 데드코드 | 정리 | 여러 곳 | 쓰이지 않는 변수·메서드·파라미터, 결과를 버리는 호출 |

---

## 확인된 버그

### B1. [중] MoveTool: 1번 레이어가 숨겨진 상태에서 이동하면 2번 레이어가 화면에서만 밀림

**위치:** `src/Modules/Tools/MoveTool.as:45-52`

```as3
if (CanvasController.checkedLayer <= 1 && movex === 0.0 && movey === 0.0)
{
    return;   // ← 1번 레이어의 이동량만 보고 조기 반환
}
```

**재현 경로**

1. 레이어 체크 없음(`checkedLayer === 0`), 2번 레이어 선택 상태에서 `2` 키(또는 layer2SelectButton)를 한 번 더 누름
   → `InputManager.as:2142` / `ToolController.as:1379` → `CanvasController.selectLayer2(true)` → **layer1.visible = false, layer2.visible = true** (`CanvasController.as:631-632`)
2. 이동 툴로 드래그
   → `onMouseMoveMovetool` (`MoveTool.as:147-159`): `checkedLayer === 0`이고 layer1은 invisible이라 **layer2Bitmap.x/y만 이동**, layer1Bitmap.x는 0으로 유지
3. 마우스 업 → `movex = floor(layer1.x) = 0`, `movey = 0` → `checkedLayer(0) <= 1` 조건이 참이 되어 **return**
4. 그래서 `MoveTool.as:102-105`의 위치 리셋, 비트맵 데이터 이동, 리플레이 기록(`MoveTool.as:128-131`의 `"move2"` 분기)이 **모두 실행되지 않음**

**결과**
- 2번 레이어는 화면에서만 밀려 있고 BitmapData는 그대로입니다. 이 상태에서 2번 레이어에 그리면 획이 확정되는 순간 밀린 만큼 튀어 보이고, 저장된 이미지는 화면과 다릅니다.
- `MoveTool.as:128-131`에 `!layer1.visible` → `"move2"` 분기가 있는 것으로 보아, 원래 이 상황을 처리하려던 의도였지만 조기 반환 때문에 그 분기에 도달하지 못합니다.

**반증 시도:** `checkedLayer === 0`이면서 layer1이 invisible인 상태가 가능한지 확인했습니다. 위 1번 경로로 가능하고, `isAllLayerInvisible()`(`MoveTool.as:175`)은 두 레이어가 **모두** 숨겨졌을 때만 막습니다. 반증에 실패했습니다.

**수정 제안** (B2도 함께 해결)

```as3
private static function onMouseUpMoveTool(e:MouseEvent):void
{
    main.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveMovetool);
    main.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpMoveTool);
    main.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUpMoveTool);

    CanvasController.isMouseDragging = false;
    PenSizePreviewCursor.setCursorInVisibleFlag(false);

    getMovedPos = null;

    const movex:Number = Math.floor(CanvasController.canvasLayer1Bitmap.x);
    const movey:Number = Math.floor(CanvasController.canvasLayer1Bitmap.y);
    const movex1:Number = Math.floor(CanvasController.canvasLayer2Bitmap.x);
    const movey1:Number = Math.floor(CanvasController.canvasLayer2Bitmap.y);

    // onMouseMoveMovetool 과 같은 기준으로 "실제로 움직인 레이어"를 판단
    const checked:int = CanvasController.checkedLayer;
    const layer1Moved:Boolean = (checked === 1 || (checked === 0 && CanvasController.canvasLayer1Bitmap.visible))
            && (movex !== 0.0 || movey !== 0.0);
    const layer2Moved:Boolean = (checked === 2 || (checked === 0 && CanvasController.canvasLayer2Bitmap.visible))
            && (movex1 !== 0.0 || movey1 !== 0.0);

    if (!layer1Moved && !layer2Moved)
    {
        // B2: 1px 미만 이동으로 남은 소수점 오프셋도 원위치
        resetLayerBitmapPos();
        return;
    }

    var tmpbmpd:BitmapData = new BitmapData(CanvasController.CANVAS_WIDTH, CanvasController.CANVAS_HEIGHT, true, 0); // P1: 조기 반환 뒤로 이동
    // ... 이하 기존 로직 동일 ...
    tmpbmpd.dispose();
    tmpbmpd = null;

    resetLayerBitmapPos();
    // ... 리플레이 기록 기존 로직 동일 ...
}

private static function resetLayerBitmapPos():void
{
    CanvasController.canvasLayer1Bitmap.x = 0;
    CanvasController.canvasLayer1Bitmap.y = 0;
    CanvasController.canvasLayer2Bitmap.x = 0;
    CanvasController.canvasLayer2Bitmap.y = 0;
}
```

> 참고: `checkedLayer === 0`이고 두 레이어가 모두 보일 때는 두 레이어가 같은 pos로 움직이므로 `movex === movex1`입니다. 그래서 기존 `"move"` 기록(movex, movey)과 호환됩니다.

---

### B2. [중하] MoveTool: 1px 미만 드래그 후 레이어 표시 위치가 소수점만큼 어긋남

**위치:** `src/Modules/Tools/MoveTool.as:40-52`

**재현 경로**
- 확대 상태(예: 400%)에서는 화면 1px이 캔버스 0.25px입니다 (`Utils.as:206`: `oldX + dx / zoom`).
- 오른쪽/아래로 화면 1~3px만 드래그 → `layer1Bitmap.x = 0.25~0.75` → `Math.floor(...) = 0` → 조기 반환 → **x 리셋 없이 반환**
- 비트맵 데이터는 그대로인데 화면에는 0.25~0.75 캔버스 px(400%에서 1~3 화면 px) 밀려 보입니다. 다음 획은 데이터 좌표에 그려지므로 확정 순간에 어긋나 보입니다.
- 반대로 왼쪽/위로 0.25px 드래그하면 `floor(-0.25) = -1`이라 1px 이동이 적용됩니다 (방향에 따라 비대칭).

**수정 제안:** B1 코드의 `resetLayerBitmapPos()` 조기 반환으로 함께 해결됩니다.
(비대칭까지 없애려면 `Math.floor` 대신 `Math.round`를 쓸 수 있습니다. 리플레이에는 정수로 반올림된 movex가 기록되므로 기존 리플레이 데이터와의 호환성 문제는 없습니다.)

---

### B3. [중하] EyeDropperTool: 레이어 체크 상태에서 툴박스 커서와 실제 툴이 어긋남

**위치:** `src/Modules/Tools/EyeDropperTool.as:306-318`

```as3
public static function start():void
{
    ToolController.toolBox.moveToolCursor("toolEyedropper");   // ① 커서 먼저 이동

    if (CanvasController.checkedLayer !== 0)                    // ② 그 다음에 거부
        return;
    if (CanvasController.isAllLayerInvisible())
        return;
    ...
    ToolController.setSelectedTool(ToolController.TOOL_EYEDROPPER);
```

**재현 경로**
1. 레이어 1 체크(`checkedLayer = 1`), 현재 툴은 이동 툴
2. `C` 키 → `InputManager.as:1634` → `ToolController.handleToolKeyDown` → `ToolController.as:919-922` → `EyeDropperTool.start()` 호출 후 `showNowToolIconToCursorTemp(TOOL_EYEDROPPER)` 실행
3. `start()` ①에서 툴박스 커서가 스포이드로 이동하고 `toolBox.lastTool = "toolEyedropper"`가 됨 (`ToolMenuSet.as:319`). 그 뒤 ②에서 반환되므로 `nowTool`은 여전히 **이동 툴**
4. 화면에는 스포이드 커서·아이콘이 떠 있지만, 캔버스를 클릭하면 **레이어가 이동**됩니다 (`InputManager.as:2425-2426`)
5. 추가로 `toolBox.lastTool`이 스포이드로 남아 있어서, 퀵 사이드바를 닫을 때 `SidebarController.as:181-183`이 `start()`를 다시 호출합니다 (다시 ②에서 반환됨)

**반증 시도:** 비활성 툴도 커서가 흐리게(alpha) 가는 설계(`ToolMenuSet.as:183-187`)가 있어서 의도된 동작인지 확인했습니다. 펜 등은 `nowTool` 자체가 바뀐 뒤 `isToolEnabledByLayerUnChecked()`로 막히므로 표시와 실제 툴이 일치합니다. 스포이드만 `nowTool`이 바뀌지 않아 불일치가 생기므로 반증에 실패했습니다.

**수정 제안**

```as3
public static function start():void
{
    if (CanvasController.checkedLayer !== 0 || CanvasController.isAllLayerInvisible())
    {
        return;
    }

    ToolController.toolBox.moveToolCursor("toolEyedropper");
    ToolController.setLastTool(ToolController.nowTool);          // D1: updateLastTool() 제거
    ToolController.setSelectedTool(ToolController.TOOL_EYEDROPPER);
    ...
}
```

호출부의 잘못된 아이콘 표시도 막으려면 `ToolController.as:921-922`를 이렇게 바꿉니다.

```as3
EyeDropperTool.start();
if (isSelectedTool(TOOL_EYEDROPPER))
{
    showNowToolIconToCursorTemp(TOOL_EYEDROPPER);
}
```

(`ToolController.as:1102-1103`도 같은 패턴입니다.)

---

### B4. [하] LassoTool.applyLassoShapen: 미러 상태에서 샤픈 강도가 달라짐

**위치:** `src/Modules/Tools/LassoTool.as:431`

```as3
var index:uint = Math.abs(Math.floor(scale - 1.0));
```

**경로:** `ReplayDrawCommands.as:1004-1006`에서 `bmpScaleX`(미러면 음수)를 그대로 넘깁니다. `applyLassoBoxImageToCanvas`가 `lassoLayer1.scaleX`를 저장하므로(`LassoTool.as:782, 845`), 미러 상태의 값은 음수입니다.

| scale | 미러 아님 index | 미러(-scale) index |
|---|---|---|
| 2.0 | `floor(1)=1` → 1 | `floor(-3)` → 3 → clamp 2 |
| 0.5 | `floor(-0.5)` → 1 | `floor(-1.5)` → 2 |

같은 배율이어도 미러된 이미지는 리플레이에서 다른 필터로 그려집니다. (구버전 `lasso` 명령에서만 사용되고, `lasso2`는 샤픈을 적용하지 않습니다.)

**수정 제안**

```as3
var index:uint = Math.abs(Math.floor(Math.abs(scale) - 1.0));
```

> ⚠️ 이미 저장된 리플레이의 재생 결과(구버전 lasso + 미러)가 미세하게 달라질 수 있습니다. 이 동작을 "리플레이 호환"으로 볼지 "버그 수정"으로 볼지는 판단이 필요합니다.

---

## 성능

### P1. [중] MoveTool: 움직이지 않은 클릭마다 캔버스 크기 BitmapData 할당

**위치:** `src/Modules/Tools/MoveTool.as:38` (할당) → `:45-52` (조기 반환, dispose 없음)

이동 툴로 클릭만 하거나 1px 미만으로 움직이면, `CANVAS_WIDTH × CANVAS_HEIGHT × 4바이트`(예: 3000×3000이면 약 36MB)가 할당되고 `dispose()` 없이 버려집니다. GC가 돌기 전까지는 네이티브 메모리가 유지되므로, 연속 클릭하면 메모리가 급증하고 GC가 멈칫할 수 있습니다.

**수정 제안:** B1 코드처럼 `new BitmapData(...)`를 조기 반환 **뒤로** 옮깁니다.

---

### P2. [하] LassoTool.moveSelectedAreaToLassoBox: 쓰지 않는 레이어 비트맵까지 할당

**위치:** `src/Modules/Tools/LassoTool.as:502-503`

```as3
var lassoBMPD:BitmapData = new BitmapData(rectWidth, rectHeight, true, 0);
var lassoBMPDsub:BitmapData = new BitmapData(rectWidth, rectHeight, true, 0);
```

`layer1`/`layer2`가 false이면 해당 비트맵은 `lassoLayerXBitmap`에 붙지 않고(`:550-559`) dispose도 되지 않습니다.
- 라이브: `checkedLayer`가 1 또는 2일 때 (`LassoTool.as:664-673`)
- 리플레이: 레이어가 하나만 기록된 `lasso`/`lasso2` 명령마다 (`ReplayDrawCommands.as:871, 958`). 리플레이 캐시를 생성할 때는 이 비용이 누적됩니다.

**수정 제안**

```as3
var lassoBMPD:BitmapData = layer1 ? new BitmapData(rectWidth, rectHeight, true, 0) : null;
var lassoBMPDsub:BitmapData = layer2 ? new BitmapData(rectWidth, rectHeight, true, 0) : null;
```

(이후 사용처가 모두 `if (layer1)` / `if (layer2)` 안에 있으므로 null이어도 안전합니다.)

---

### P3. [하] LassoTool.start: 체크되지 않은 레이어까지 캔버스 전체 clone

**위치:** `src/Modules/Tools/LassoTool.as:757-768`

`checkedLayer === 1`이어도 layer2가 보이면 `canvasLayer2BitmapData.clone()`(캔버스 전체)을 만듭니다. 선택 영역을 지우는 대상은 체크된 레이어뿐이라(`:664-673`, `:524-533`) 레이어 2 백업은 쓰이지 않습니다. `restoreToLastBmpd()`가 이 백업으로 layer2를 덮어써도 내용이 같아 결과는 같고, 비용만 듭니다.

**수정 제안**

```as3
const needL1:Boolean = CanvasController.canvasLayer1Bitmap.visible && CanvasController.checkedLayer !== 2;
const needL2:Boolean = CanvasController.canvasLayer2Bitmap.visible && CanvasController.checkedLayer !== 1;
if (needL1) { /* 기존 layer1 clone */ }
if (needL2) { /* 기존 layer2 clone */ }
```

> 이 수정은 `onMouseUpLassoTool`의 checklayer 계산(`:662-673`)과 기준이 같아야 합니다. D3의 헬퍼로 통일하는 것을 권장합니다.

---

### P4. [하~중, 의심] 라소 미리보기가 매번 전체 경로를 다시 그림

**위치:** `LassoTool.as:613-631` (`drawPreviewLine`), `:712-718` (100ms 타이머), `DottedLineTool.as:46-70`

- 100ms마다 `graphics.clear()`를 하고 **처음부터 모든 점**을 `DottedLineTool.lineTo`로 다시 그립니다. 점이 N개면 드래그 전체 비용은 O(N²)입니다.
- `DottedLineTool.lineTo`는 호출마다 `new Point` 2개, 대시마다 `Point.interpolate`(새 Point)와 `lineStyle` 변경을 합니다. 대시가 많을수록 Graphics 명령 수도 늘어 렌더링 비용이 커집니다.
- 짧은 선택에서는 체감되지 않고, **긴 드래그 + 저사양**에서 프레임 저하로 이어질 가능성이 있습니다 (측정하지 않았으므로 "의심"으로 분류).

**수정 제안 (증분 그리기):** DottedLineTool 상태(대시 위치, 색 토글)는 static으로 유지되므로, 새로 추가된 점만 이어 그릴 수 있습니다. 닫는 선은 매번 바뀌므로 별도 Shape에 그립니다.

```as3
// cLassoTool 클로저 안
var drawnCount:uint = 0;
const closeLineDraw:Shape = new Shape(); // lassoDraw 형제로 addChild 필요

function drawPreviewLine():void
{
    if (lassoPoints === null || lassoPoints.length < 2) return;
    const len:uint = lassoPoints.length;
    if (drawnCount === 0)
    {
        lassoDraw.graphics.clear();
        DottedLineTool.moveTo(lassoDraw.graphics, lassoPoints[0][0], lassoPoints[0][1]);
        drawnCount = 1;
    }
    for (var i:uint = drawnCount; i < len; i++)
        DottedLineTool.lineTo(lassoPoints[i][0], lassoPoints[i][1]);
    drawnCount = len;

    // 닫는 선은 단색 1px로 간단히 (줌 보정)
    closeLineDraw.graphics.clear();
    closeLineDraw.graphics.lineStyle(1 / CanvasController.canvasZoomMultipler, 0);
    closeLineDraw.graphics.moveTo(lassoPoints[len - 1][0], lassoPoints[len - 1][1]);
    closeLineDraw.graphics.lineTo(lassoPoints[0][0], lassoPoints[0][1]);
}
// start()와 resetPosData()에서 drawnCount = 0; closeLineDraw.graphics.clear();
// onMouseUpLassoTool 확정 시에는 기존처럼 전체를 한 번 다시 그려 닫는 선까지 점선으로 처리
```

DottedLineTool 쪽 할당 줄이기:

```as3
private static const nowPos:Point = new Point();
private static const interpPoint:Point = new Point();
public static function lineTo(x:Number, y:Number, closeLine:Boolean = false):void
{
    nowPos.setTo(x, y);
    interpPoint.setTo(lastDotPos.x, lastDotPos.y);
    var dist:Number = Point.distance(lastDotPos, nowPos);
    ...
    // Point.interpolate 대신 직접 계산
    interpPoint.setTo(nowPos.x + ratio * (interpPoint.x - nowPos.x),
                      nowPos.y + ratio * (interpPoint.y - nowPos.y));
    ...
}
```

---

### P5. [하, 의심] EyeDropperTool: MOUSE_MOVE마다 중복 hitTest와 렌즈 draw 3회

**위치:** `EyeDropperTool.as:254-280`

한 번의 MOUSE_MOVE에서 다음이 실행됩니다.
1. `canShowEyedropperLens()` → `canvasLayer1Bitmap.hitTestPoint(..., true)` (`:302`)
2. `pickColor()` → **같은 점에 대해** `canvasLayer1Bitmap.hitTestPoint(...)`를 다시 호출 (`:69`)
3. `updateEyeDropperLensBitmap()` → `fillRect` 1회 + `draw` 3회 (`:53-64`)

MOUSE_MOVE는 한 프레임 안에서도 여러 번 발생할 수 있어서, 화면에 보이지 않는 중간 결과까지 렌즈를 다시 그립니다.

**수정 제안**
- 2번 중복 제거: `pickColor`에서 hitTest 결과를 받도록 분리

```as3
private static function pickColorAtCursor():uint { /* 기존 pickColor의 if 블록 내부 */ }
private static function pickColor():uint
{
    return CanvasController.canvasLayer1Bitmap.hitTestPoint(main.stage.mouseX, main.stage.mouseY)
        ? pickColorAtCursor() : penColorBackup;
}
// onMouseMoveEyeDropper / start 에서는 canShowEyedropperLens()가 이미 true이므로 pickColorAtCursor() 직접 호출
```

- 3번은 dirty 플래그와 `Event.ENTER_FRAME`으로 프레임당 1회로 제한할 수 있습니다 (측정 후 판단 권장).

---

## 중복 / 정리 (동작 영향 없음)

### D1. EyeDropperTool.start: `updateLastTool()` 호출이 무의미함
`EyeDropperTool.as:320-322`

```as3
ToolController.updateLastTool();              // lastTool이 NONE이면 nowTool로 설정
ToolController.setLastTool(ToolController.nowTool); // 바로 무조건 nowTool로 덮어씀
```
`ToolController.as:159-170` 기준으로 첫 줄은 결과에 영향을 주지 않습니다. 첫 줄을 삭제하면 됩니다 (B3 제안 코드에 반영).

### D2. LassoTool.resetLassoBox: 컬러피커 알파를 두 번 설정
`LassoTool.as:1005` `ColorPickerController.colorPickerBox.alpha = 1.0;` 이후 `:1007` `setAlphaButtonsOnLassoTool(1.0)`가 `:591`에서 같은 값을 다시 설정합니다. `:1005`를 삭제하면 됩니다.

### D3. 대상 레이어(l1/l2) 계산이 세 곳에 복제됨
- `LassoTool.as:662-673` (선택 시)
- `LassoTool.as:868-879` (적용 시)
- `LassoTool.as:155-166` (참조 레이어 병합 시, 다른 모양의 식)

현재는 라소가 활성화되어 있는 동안 레이어 전환 키/마우스 입력이 차단되므로(`InputManager.addInputEventsLassoTool` → `removeInputEventsDrawMode()`, `InputManager.as:1935-1945`) 세 값이 일치합니다. 다만 입력 처리가 바뀌면 선택 시와 적용 시 값이 달라져 라이브와 리플레이가 어긋날 위험이 있습니다. **선택 시점의 값을 저장해 재사용**하는 것을 권장합니다.

```as3
public static var lassoTargetLayer1:Boolean;
public static var lassoTargetLayer2:Boolean;

private static function resolveTargetLayers():void
{
    lassoTargetLayer1 = CanvasController.canvasLayer1Bitmap.visible;
    lassoTargetLayer2 = CanvasController.canvasLayer2Bitmap.visible;
    if (CanvasController.checkedLayer === 1) { lassoTargetLayer1 = true;  lassoTargetLayer2 = false; }
    else if (CanvasController.checkedLayer === 2) { lassoTargetLayer1 = false; lassoTargetLayer2 = true; }
}
// onMouseUpLassoTool에서 1회 호출, apply/merge에서는 저장값 사용
// applyLassoBoxImageToCanvas의 `canvasLayerXBitmap.visible` 분기도 이 값으로 교체 (아래 제외 항목 E1 참고)
```

### D4. 데드코드 / 미사용
| 위치 | 내용 |
|---|---|
| `LineTool.as:372-375` | `checkPointInsideCanvas(mx, my)` 결과를 버림. 이후 클릭에서 점·선분 검사로 보완되므로 동작 영향은 없음 (제외 항목 E4). 삭제하거나 `hasLineTouchedCanvas = checkPointInsideCanvas(mx, my);`로 의도를 명확히 하는 것을 권장 |
| `LineTool.as:46, 335` | `xAirBrushON`: 대입만 하고 읽지 않음 (리플레이에는 `PenTool.airBrushSizeDrawMode` 사용) |
| `LineTool.as:18-22` | 미사용 import (`BitmapData`, `MainUI`, `ApplicationDomain`, `BrowserInvokeEvent`, `ReplayController`) |
| `HandTool.as:31, 111` | `xBitmap`: 대입만 하고 읽지 않음 |
| `RotateTool.as:107` | `private function updatePenSizeCursor():void {}`: Main.as에서 분리할 때 남은 빈 인스턴스 메서드 (static 클래스라 호출되지 않음) |
| `DottedLineTool.as:23` | `toggleLineColor(from:int)`: `from` 미사용 |
| `ZoomTool.as:68` | `var abs:Function = Math.abs;`: Function 변수를 통한 호출은 `Math.abs` 직접 호출보다 느림 (미미) |
| `LassoTool.as:131` | `hideLassoMenuBoxTemp()`는 실제로 메뉴를 **보이게** 함. 이름을 `restoreLassoMenuBoxTemp` 등으로 바꾸는 것을 권장 |
| `LassoTool.as:632` | 오타 `setDeafultLassoMenuPos` |
| `LassoTool.as:917-926` | `restoreToLastBmpd`의 `rect` 계산이 사용되지 않음 (`CanvasController.copyPixels`가 자체 rect 사용) |

---

## 반증되어 제외된 항목

의심했지만 **정상 동작 조건이 확인되어** 버그 목록에서 뺀 항목입니다.

| ID | 의심 내용 | 반증 근거 |
|---|---|---|
| E1 | `applyLassoBoxImageToCanvas`(`LassoTool.as:803-806`)가 체크 레이어가 아니라 **visible 기준**으로 그림. `checkedLayer=2` + layer1 visible이면, 이번 세션에 채워지지 않은 `lassoLayer1Bitmap`을 layer1에 draw함 | 이때 `lassoLayer1Bitmap.bitmapData`는 항상 **null이거나 이미 dispose된 상태**입니다. 모든 종료 경로가 dispose를 거칩니다: `cancelLassoTool` `:947`, `applyLassoImageToCanvas` `:892`, `mergeLassoImageToRefLayer` `:143,169`, 리플레이 `ReplayDrawCommands.resetLassoVars` `:825-829`. 따라서 빈 이미지가 그려져 결과는 바뀌지 않습니다. 다만 "우연히 안전한" 구조이므로 D3처럼 저장된 대상 레이어로 분기하는 것을 권장합니다. |
| E2 | `checkedLayer=1`인데 layer1이 invisible이면, start에서 백업을 만들지 않았는데 선택 영역이 지워져 취소 시 복구 불가 | `toggleLayer1Check`는 항상 `selectLayer1(false)`와 함께 호출되고(`ToolController.as:1342-1343`), `n1`로 보기 전용을 켜도 **layer1은 visible로 유지**됩니다(`CanvasController.as:613`). 따라서 `checkedLayer=k`이면 layer k는 항상 visible입니다. |
| E3 | `mergeLayerByLassoTool`에 비활성(alpha) 체크가 없음 | 유일한 호출부 `InputManager.as:613`에서 `alpha === 1.0`을 확인합니다. |
| E4 | `LineTool.start`에서 시작점의 캔버스 내부 판정을 버려서, 캔버스 안에서 그린 선이 적용되지 않을 수 있음 | 적용하려면 최소 1회 클릭이 필요합니다(`command.length > 2`, `:257`). 두 번째 점이 캔버스 안이면 `checkPointInsideCanvas`가, 밖이면 안→밖 선분이 경계를 가로지르므로 `thickLineTouchesCanvasBorder`가 true를 반환합니다. 판정이 누락되는 경우가 없습니다. |
| E5 | `LineTool.cancel()`을 시작 전에 호출하면 `command`가 null이라 오류 | 외부 호출부 `FileManager.as:403`이 `LineTool.isStarted`로 확인합니다. 내부 호출은 시작 후 등록된 리스너에서만 일어납니다. |
| E6 | 라소 활성 중에 이동 툴을 쓰면 `MoveTool.as:107` 때문에 리플레이 기록이 누락됨 | 라소 활성 중에는 `removeInputEventsDrawMode()`로 드로우 모드 마우스 입력이 해제되고(`InputManager.as:1944`), 툴박스2 우클릭도 닫힙니다(`:961-964`). 정상 경로로는 도달할 수 없습니다 (방어 코드). |
| E7 | `lassoMenuHintONEvent` MOUSE_OVER 리스너가 `removeInputEventsLassoTool`에서 제거되지 않음 | 라소가 비활성인 상태에서 다음 MOUSE_OVER가 오면 스스로 제거합니다(`LassoTool.as:236-239`). 누적되지 않습니다. |
| E8 | EyeDropper 종료 시 `setRefLayerAndGridVisible(true)`가 사용자가 숨긴 참조 레이어를 다시 켬 | 사용자가 숨긴 상태는 `refLayerLastAlpha = 0`으로 표현되고(`ReferenceLayerController.as:475-477`), `setRefLayerAndGridVisible`은 `refLayerLastAlpha > 0`일 때만 켭니다(`:714`). |
| E9 | 미러된 라소 이미지를 리사이즈할 때 음수 scale 때문에 튐 | `Utils.updateImageScaleMouseDrag`가 `Math.abs(sc)`로 처리하고(`Utils.as:133`), 호출부에서 `mirrorScale`을 다시 곱합니다. |
| E10 | `applyLassoBoxImageToCanvas`에서 미러(음수 scaleX)일 때 행렬 위치가 틀림 | `lassoBMPWidth = W * scaleX`(음수)로 `translate(-W*sx/2)`를 하면 디스플레이 변환 `R·S·(p − c) + box`와 정확히 같습니다. |
| E11 | RotateTool이 드로우 모드에서도 `getStageCenterPos("replay")`를 사용해 사이드바를 무시함 | Main.as에서 분리하기 전 원본(`ecd32a4^:src/Main.as:2009`)도 같은 코드입니다. 리팩토링 중 생긴 회귀가 아니고, 의도 여부를 코드만으로는 판단할 수 없어 제외했습니다. 사이드바가 있을 때 회전 중심이 캔버스 영역 중앙이 아니라는 점이 불편하다면 `"draw"`로 바꾸는 것을 검토할 수 있습니다. |
| E12 | DottedLineTool `ratio` 계산에서 0으로 나누기 | 루프에 들어가는 조건(`subDotLength < 0`)일 때 `dist = D − s > 0`이 보장됩니다. 보간 수식도 "현재 대시 시작점에서 정확히 s만큼 떨어진 점"과 일치합니다. |
