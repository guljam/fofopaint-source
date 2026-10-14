# F5(launch.json preLaunchTask "FOFO PAINT swf build and debug")용 빌드 묶음
# worker.swf, nativecore ANE, fofoPaint.swf 빌드 스크립트를 동시에 띄우고 다 끝날때까지 기다림
#   (Main은 worker.swf를 실행 중에 URLRequest로 읽고, ANE도 컴파일 단계에서 쓰지 않아서 서로 기다릴 필요가 없음)
#   세 출력이 한 콘솔에 섞여 나오므로 끝난 뒤 빌드별 결과와 걸린 시간을 따로 정리해서 보여줌
# 각 빌드 스크립트는 그대로 따로 돌릴수 있고, 패키징 태스크는 이 스크립트를 쓰지 않음
# -DryRun: 띄울 빌드 명령만 보여주고 아무것도 실행하지 않음
param(
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'

$debugBuildScripts = @(
    @{ name = 'Worker SWF'; path = "${PSScriptRoot}\build-worker.ps1" },
    @{ name = 'nativecore ANE'; path = "${PSScriptRoot}\anesrc\fofonative\build-ane.ps1" },
    @{ name = 'Main SWF'; path = "${PSScriptRoot}\build-main.ps1" }
)
$pwshPath = "$PSHOME\pwsh.exe"

# 빌드 결과 목록(name, exitCode)에서 실패한 빌드 이름만 골라냄
function Get-FailedDebugBuildNames($debugBuildResults) {
    $failedNames = @()
    foreach ($debugBuildResult in $debugBuildResults) {
        if ($debugBuildResult.exitCode -ne 0) {
            $failedNames += $debugBuildResult.name
        }
    }
    return , $failedNames
}

# 실행 전 점검: 실패 판정 로직을 가짜 결과로 확인하고, 빌드 스크립트와 pwsh가 있는지 확인함
function Test-DebugBuildPreconditions {
    $mockResults = @(@{ name = 'a'; exitCode = 0 }, @{ name = 'b'; exitCode = 1 }, @{ name = 'c'; exitCode = -1 })
    $mockFailedNames = Get-FailedDebugBuildNames $mockResults
    if (($mockFailedNames -join ',') -ne 'b,c') { throw "실패 판정 점검 실패: $($mockFailedNames -join ',')" }
    $mockAllPassedNames = Get-FailedDebugBuildNames @(@{ name = 'a'; exitCode = 0 })
    if ($mockAllPassedNames.Count -ne 0) { throw '실패 판정 점검 실패: 성공만 있는데 실패가 나옴' }

    if (-not (Test-Path -Path $pwshPath)) { throw "pwsh를 찾을 수 없음: $pwshPath" }
    foreach ($debugBuildScript in $debugBuildScripts) {
        if (-not (Test-Path -Path $debugBuildScript.path)) { throw "빌드 스크립트를 찾을 수 없음: $($debugBuildScript.path)" }
    }
}

Test-DebugBuildPreconditions

if ($DryRun) {
    foreach ($debugBuildScript in $debugBuildScripts) {
        Write-Host "[DryRun] $($debugBuildScript.name): `"$pwshPath`" -NoProfile -ExecutionPolicy Bypass -File `"$($debugBuildScript.path)`""
    }
    exit 0
}

$totalStopwatch = [Diagnostics.Stopwatch]::StartNew()
$debugBuildJobs = @()
foreach ($debugBuildScript in $debugBuildScripts) {
    $buildProcess = Start-Process -FilePath $pwshPath -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($debugBuildScript.path)`"" -NoNewWindow -PassThru
    $null = $buildProcess.Handle # 핸들을 미리 잡아둬야 끝난 뒤 ExitCode를 읽을 수 있음
    $debugBuildJobs += @{ name = $debugBuildScript.name; process = $buildProcess }
}

$debugBuildResults = @()
foreach ($debugBuildJob in $debugBuildJobs) {
    $debugBuildJob.process.WaitForExit()
    $elapsedSeconds = ($debugBuildJob.process.ExitTime - $debugBuildJob.process.StartTime).TotalSeconds
    $debugBuildResults += @{ name = $debugBuildJob.name; exitCode = $debugBuildJob.process.ExitCode; seconds = $elapsedSeconds }
}

Write-Host ''
foreach ($debugBuildResult in $debugBuildResults) {
    $state = if ($debugBuildResult.exitCode -eq 0) { 'ok' } else { "FAILED (exit $($debugBuildResult.exitCode))" }
    Write-Host ('{0,-15} {1,6:N1}s  {2}' -f $debugBuildResult.name, $debugBuildResult.seconds, $state)
}
Write-Host ('{0,-15} {1,6:N1}s' -f 'Total', $totalStopwatch.Elapsed.TotalSeconds)

$failedDebugBuildNames = Get-FailedDebugBuildNames $debugBuildResults
if ($failedDebugBuildNames.Count -gt 0) {
    Write-Host "빌드 실패: $($failedDebugBuildNames -join ', ')"
    exit 1
}
