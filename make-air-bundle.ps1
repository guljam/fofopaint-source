# Windows bundle(captive runtime) x86(32비트, Windows 7 호환 목표)과 x64를 만듦
#   bin\fofoPaint-bundle-x86, bin\fofoPaint-bundle-x64
# 메인 SWF와 worker SWF를 release(-debug=false)로 bin\release에 따로 컴파일해서 넣음
#   (F5용 fofoPaint.swf와 저장소에 있는 debug worker.swf는 건드리지 않음, 옵션은 asconfig.json/build-worker.ps1과 같고 debug만 false)
# descriptor(fofoPaint-app.xml)에 extendedDesktop 프로필과 네이티브 확장이 선언되어 있어 그대로 씀, ANE는 -extdir extension
# extension\com.fofo.nativecore.ane가 최신이어야 함 (tasks.json "Make AIR Bundle"이 ANE를 먼저 빌드)
# 인증서 비밀번호가 들어 있어서 저장소에 넣지 않음 (.gitignore)
param(
    [ValidateSet('both', 'x86', 'x64')]
    [string]$Arch = 'both',
    [string]$StorePass = ''
)
Set-Location $PSScriptRoot
$storePassArguments = @()
if ($StorePass -ne '') { $storePassArguments = @('-storepass', $StorePass) }
$sdk = 'D:\adobe_air_sdk_manager\AIRSDK_51.4.1'
$adt = "$sdk\bin\adt.bat"
$release = 'bin\release'
New-Item -ItemType Directory -Force $release | Out-Null
$options = @('-target-player=51.1', '-swf-version=51', '-debug=false', '-strict=true', '-warnings=true', '-verbose-stacktraces=true')

# 메인과 worker SWF는 서로 의존이 없어서 스레드 작업으로 동시에 컴파일함, 출력은 끝난 뒤 작업별로 모아서 보여줌
Write-Host "Compiling release SWFs to $release ..."
$releaseCompileJobs = @(
    (Start-ThreadJob -Name 'main SWF' -ScriptBlock {
        $root = $using:PSScriptRoot
        $options = $using:options
        $lines = & "$using:sdk\bin\amxmlc.bat" "-source-path+=$root\src" "-library-path+=$root\extension\libwebp.swc" @options "-output=$root\$using:release\fofoPaint.swf" "$root\src\Main.as" 2>&1
        @{ lines = $lines; exitCode = $LASTEXITCODE }
    }),
    (Start-ThreadJob -Name 'worker SWF' -ScriptBlock {
        $root = $using:PSScriptRoot
        $options = $using:options
        $lines = & "$using:sdk\bin\amxmlc.bat" "-source-path+=$root\src" @options "-output=$root\$using:release\worker.swf" "$root\src\worker\BackgroundImageProcessor.as" 2>&1
        @{ lines = $lines; exitCode = $LASTEXITCODE }
    })
)
$compileFailedCode = 0
foreach ($releaseCompileJob in $releaseCompileJobs) {
    $compileResult = Receive-Job -Job $releaseCompileJob -Wait -AutoRemoveJob
    foreach ($line in $compileResult.lines) { Write-Host "$line" }
    if ($compileResult.exitCode -ne 0) { Write-Host "$($releaseCompileJob.Name) compile failed"; $compileFailedCode = $compileResult.exitCode }
}
if ($compileFailedCode -ne 0) { exit $compileFailedCode }

$archs = if ($Arch -eq 'both') { @('x86', 'x64') } else { @($Arch) }
$code = 0

# 아키텍처별 bundle은 같은 bin\release를 읽기만 하고 서로 다른 폴더에 써서 adt를 스레드 작업으로 동시에 돌림
$bundlePackageJobs = @()
foreach ($a in $archs) {
    $out = "bin\fofoPaint-bundle-$a"
    if (Test-Path $out) { Remove-Item $out -Recurse -Force }
    Write-Host "Packaging $out ..."
    $bundlePackageJobs += Start-ThreadJob -Name $a -ScriptBlock {
        # adt 인자가 상대 경로라서 작업 안에서도 저장소 루트에서 실행함
        Set-Location $using:PSScriptRoot
        $storePassArguments = $using:storePassArguments
        # 패키지 루트 이름이 descriptor의 <content>fofoPaint.swf</content>, 앱의 URLRequest("worker.swf")와 맞게 -C로 넣음
        $lines = & $using:adt -package -storetype pkcs12 -keystore "F:\페인트앱_백업\fofopaintKey\secretkey3.p12" @storePassArguments -target bundle -arch $using:a $using:out 'fofoPaint-app.xml' 'resource\icon' 'manual' -C $using:release 'fofoPaint.swf' 'worker.swf' -extdir 'extension' 2>&1
        @{ lines = $lines; exitCode = $LASTEXITCODE }
    }
}

foreach ($bundlePackageJob in $bundlePackageJobs) {
    $packageResult = Receive-Job -Job $bundlePackageJob -Wait -AutoRemoveJob
    foreach ($line in $packageResult.lines) { Write-Host "$line" }
    $a = $bundlePackageJob.Name
    if ($packageResult.exitCode -ne 0) { $code = $packageResult.exitCode; Write-Host "$a bundle failed ($($packageResult.exitCode))" } else { Write-Host "Built bin\fofoPaint-bundle-$a" }
}

exit $code
