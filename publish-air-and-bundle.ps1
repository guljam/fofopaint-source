# 배포파일 3개(legacy .air, bundle x86, bundle x64)를 한 번에 만듦
# 인증서 비밀번호는 환경변수 FOFO_STOREPASS로 받음 (tasks.json "Publish AIR and Bundle"의 입력창 값), 없으면 -StorePass
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

$publishSteps = @(
    @{ Name = 'legacy .air';          ScriptPath = $legacyScriptPath; Arguments = @() },
    @{ Name = 'bundle x86 + x64';     ScriptPath = $bundleScriptPath; Arguments = @('-Arch', 'both') }
)

foreach ($publishStep in $publishSteps) {
    Write-Host ""
    Write-Host "=== $($publishStep.Name) ==="
    if ($DryRun) { Write-Host "[DryRun] pwsh -File $($publishStep.ScriptPath) $($publishStep.Arguments) -StorePass ****"; continue }
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $publishStep.ScriptPath @($publishStep.Arguments) -StorePass $StorePass
    if ($LASTEXITCODE -ne 0) { Write-Host "$($publishStep.Name) failed ($LASTEXITCODE)"; exit $LASTEXITCODE }
}

Write-Host ""
Write-Host 'Published: bin\fofoPaint.air, bin\fofoPaint-bundle-x86, bin\fofoPaint-bundle-x64'
exit 0
