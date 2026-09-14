$path = ".\Main.as"
$src = Get-Content $path -Raw

$names = @(
    "startScratchPadResetTimer",
    "startPressHoldKey",
    "updateLastKey",
    "resetLastKey",
    "isLastKey",
    "startKeyRepeatStopTimerOnMouseLeave",
    "startKeyRepeat",
    "checkPenOptionsKeyDown",
    "isPressingControl",
    "isPressingShift",
    "isPressingControlShift",
    "getCommandKey",
    "onMouseDownStage",
    "onRightMouseDownStage",
    "onMiddleMouseDownStage",
    "cRealWorkingTimer",
    "checkGeneralKeyUp",
    "checkInvalidKey",
    "getPressedKeyCount",
    "isKeyPressed",
    "getLastKey",
    "isTwoKeyPressed",
    "isPressdKey",
    "getFirstPressedKey",
    "getSecondPressedKey",
    "onKeyUpStage",
    "onKeyDownStage",
    "removeInputEventsDrawMode",
    "addInputEventsDrawMode",
    "removeInputEventsToolBox2",
    "addInputEventsToolBox2",
    "enableIME",
    "tryDisableIME",
    "addKeyRepeatEvents",
    "removeKeyRepeatEvents",
    "onKeyUpDrawMode",
    "checkSubKey",
    "onKeyDownDrawMode",
    "unblockMouseClickAfterDelay",
    "clearKeyBuffer"
)

$escaped = ($names | ForEach-Object {
    [regex]::Escape($_)
}) -join "|"

$pattern = "(?m)^[ \t]*public\s+function\s+(?:$escaped)\s*\("

$matches = [regex]::Matches($src, $pattern)

# 뒤쪽 함수부터 삭제해야 인덱스가 안 깨짐
$matches = $matches | Sort-Object Index -Descending

foreach ($m in $matches) {

    $start = $m.Index

    $braceStart = $src.IndexOf("{", $start)
    if ($braceStart -lt 0) {
        continue
    }

    $depth = 0
    $end = -1

    for ($i = $braceStart; $i -lt $src.Length; $i++) {

        if ($src[$i] -eq "{") {
            $depth++
        }
        elseif ($src[$i] -eq "}") {
            $depth--

            if ($depth -eq 0) {
                $end = $i + 1
                break
            }
        }
    }

    if ($end -gt $start) {

        # 함수 뒤 줄바꿈도 같이 제거
        while (
            $end -lt $src.Length -and
            ($src[$end] -eq "`r" -or $src[$end] -eq "`n")
        ) {
            $end++
        }

        $src = $src.Remove(
            $start,
            $end - $start
        )
    }
}

Set-Content $path $src -Encoding UTF8

Write-Host "삭제된 함수 수:" $matches.Count