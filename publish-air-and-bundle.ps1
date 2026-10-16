# 배포파일 3개(legacy .air, bundle x86, bundle x64)를 한 번에 만듦, legacy와 bundle은 동시에 만들고 bundle 안의 x86/x64와 각 SWF 컴파일도 동시에 함
# 인증서 비밀번호는 환경변수 FOFO_STOREPASS로 받음 (tasks.json "Publish AIR and Bundle"의 입력창 값), 없으면 -StorePass
# 순서: 경로 점검 → p12 비밀번호 점검(틀리면 즉시 중단) → nativecore ANE 빌드 → legacy/bundle 패키징
# -DryRun: 아무것도 만들지 않고 필요한 파일/경로 존재 여부와 실행할 순서만 출력
param(
    [string]$StorePass = '',
    [switch]$DryRun
)
Set-Location $PSScriptRoot
if ($StorePass -eq '') { $StorePass = $env:FOFO_STOREPASS }
if (-not $DryRun -and ($null -eq $StorePass -or $StorePass -eq '')) { Write-Host 'Certificate password is empty'; exit 1 }

$legacyScriptPath = "$PSScriptRoot\make-air-legacy.ps1"
$bundleScriptPath = "$PSScriptRoot\make-air-bundle.ps1"
$keystorePath = 'F:\페인트앱_백업\fofopaintKey\secretkey3.p12'

# 사전 점검: 하나라도 없으면 컴파일을 시작하기 전에 중단
$requiredPaths = @($legacyScriptPath, $bundleScriptPath, $keystorePath, 'D:\adobe_air_sdk_manager\AIRSDK_51.4.1\bin\adt.bat', 'D:\adobe_air_sdk_manager\AIRSDK_51.3.4\bin\adt.bat')
$missingCount = 0
foreach ($requiredPath in $requiredPaths) {
    if (Test-Path $requiredPath) { Write-Host "OK      $requiredPath" } else { Write-Host "MISSING $requiredPath"; $missingCount++ }
}
if ($missingCount -gt 0) { Write-Host "$missingCount required path(s) missing"; exit 1 }

# 인증서 비밀번호 점검: ANE 빌드와 컴파일을 시작하기 전에 p12를 열어보고, 비밀번호가 틀리면 바로 중단
if ($DryRun) {
    Write-Host "[DryRun] keystore password check: $keystorePath"
} else {
    try {
        $keystoreCertificates = [System.Security.Cryptography.X509Certificates.X509Certificate2Collection]::new()
        $keystoreCertificates.Import($keystorePath, $StorePass, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::EphemeralKeySet)
        Write-Host "OK      keystore password ($($keystoreCertificates.Count) certificate(s))"
    } catch {
        Write-Host "Keystore password is wrong or keystore can't be opened: $($_.Exception.InnerException.Message)"
        exit 1
    }
}

# nativecore ANE 빌드 (예전에는 tasks.json dependsOn으로 비밀번호 입력 전에 돌았음, 비밀번호 점검 뒤로 옮김)
$aneBuildScriptPath = "$PSScriptRoot\anesrc\fofonative\build-ane.ps1"
if ($DryRun) {
    Write-Host "[DryRun] pwsh -File $aneBuildScriptPath"
} else {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $aneBuildScriptPath
    if ($LASTEXITCODE -ne 0) { Write-Host "nativecore ANE build failed ($LASTEXITCODE)"; exit $LASTEXITCODE }
}

$publishSteps = @(
    @{ Name = 'legacy .air';          ScriptPath = $legacyScriptPath; Arguments = @() },
    @{ Name = 'bundle x86 + x64';     ScriptPath = $bundleScriptPath; Arguments = @('-Arch', 'both') }
)

if ($DryRun) {
    foreach ($publishStep in $publishSteps) {
        Write-Host ""
        Write-Host "=== $($publishStep.Name) ==="
        Write-Host "[DryRun] pwsh -File $($publishStep.ScriptPath) $($publishStep.Arguments) -StorePass **** (단계들을 동시에 실행)"
    }
    Write-Host ""
    exit 0
}

# legacy와 bundle은 SDK와 출력 폴더(bin\release-legacy, bin\release)가 달라서 스레드 작업으로 동시에 만듦
# 출력은 끝난 뒤 단계별로 모아서 보여주고, 하나라도 실패하면 그 종료 코드로 끝냄
$publishJobs = @()
foreach ($publishStep in $publishSteps) {
    $publishJobs += Start-ThreadJob -Name $publishStep.Name -ScriptBlock {
        $publishStep = $using:publishStep
        $stepArguments = @($publishStep.Arguments)
        $lines = & pwsh -NoProfile -ExecutionPolicy Bypass -File $publishStep.ScriptPath @stepArguments -StorePass $using:StorePass 2>&1
        @{ lines = $lines; exitCode = $LASTEXITCODE }
    }
}

$publishFailedCode = 0
foreach ($publishJob in $publishJobs) {
    $publishResult = Receive-Job -Job $publishJob -Wait -AutoRemoveJob
    Write-Host ""
    Write-Host "=== $($publishJob.Name) ==="
    foreach ($line in $publishResult.lines) { Write-Host "$line" }
    if ($publishResult.exitCode -ne 0) { Write-Host "$($publishJob.Name) failed ($($publishResult.exitCode))"; $publishFailedCode = $publishResult.exitCode }
}
if ($publishFailedCode -ne 0) { exit $publishFailedCode }

Write-Host ""
Write-Host 'Published: bin\fofoPaint.air, bin\fofoPaint-bundle-x86, bin\fofoPaint-bundle-x64'
exit 0
