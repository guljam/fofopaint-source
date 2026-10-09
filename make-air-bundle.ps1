# Windows bundle(captive runtime) x86(32비트, Windows 7 호환 목표)과 x64를 만듦
#   bin\fofoPaint-bundle-x86, bin\fofoPaint-bundle-x64
# 메인 SWF와 worker SWF를 release(-debug=false)로 bin\release에 따로 컴파일해서 넣음
#   (F5용 fofoPaint.swf와 저장소에 있는 debug worker.swf는 건드리지 않음, 옵션은 asconfig.json/build-worker.ps1과 같고 debug만 false)
# descriptor(fofoPaint-app.xml)에 extendedDesktop 프로필과 네이티브 확장이 선언되어 있어 그대로 씀, ANE는 -extdir extension
# extension\com.fofo.nativecore.ane가 최신이어야 함 (tasks.json "Make AIR Bundle"이 ANE를 먼저 빌드)
# 인증서 비밀번호가 들어 있어서 저장소에 넣지 않음 (.gitignore)
param(
    [ValidateSet('both', 'x86', 'x64')]
    [string]$Arch = 'both'
)
Set-Location $PSScriptRoot
$sdk = 'D:\adobe_air_sdk_manager\AIRSDK_51.4.1'
$adt = "$sdk\bin\adt.bat"
$release = 'bin\release'
New-Item -ItemType Directory -Force $release | Out-Null
$options = @('-target-player=51.1', '-swf-version=51', '-debug=false', '-strict=true', '-warnings=true', '-verbose-stacktraces=true')

Write-Host "Compiling release SWFs to $release ..."
& "$sdk\bin\amxmlc.bat" "-source-path+=$PSScriptRoot\src" "-library-path+=$PSScriptRoot\extension\libwebp.swc" @options "-output=$PSScriptRoot\$release\fofoPaint.swf" "$PSScriptRoot\src\Main.as"
if ($LASTEXITCODE -ne 0) { Write-Host 'main SWF compile failed'; exit $LASTEXITCODE }
& "$sdk\bin\amxmlc.bat" "-source-path+=$PSScriptRoot\src" @options "-output=$PSScriptRoot\$release\worker.swf" "$PSScriptRoot\src\worker\BackgroundImageProcessor.as"
if ($LASTEXITCODE -ne 0) { Write-Host 'worker SWF compile failed'; exit $LASTEXITCODE }

$archs = if ($Arch -eq 'both') { @('x86', 'x64') } else { @($Arch) }
$code = 0

foreach ($a in $archs) {
    $out = "bin\fofoPaint-bundle-$a"
    if (Test-Path $out) { Remove-Item $out -Recurse -Force }
    Write-Host "Packaging $out ..."
    # 패키지 루트 이름이 descriptor의 <content>fofoPaint.swf</content>, 앱의 URLRequest("worker.swf")와 맞게 -C로 넣음
    & $adt -package -storetype pkcs12 -keystore "F:\페인트앱_백업\fofopaintKey\secretkey3.p12" -target bundle -arch $a $out 'fofoPaint-app.xml' 'resource\icon' 'manual' -C $release 'fofoPaint.swf' 'worker.swf' -extdir 'extension'
    if ($LASTEXITCODE -ne 0) { $code = $LASTEXITCODE; Write-Host "$a bundle failed ($LASTEXITCODE)" } else { Write-Host "Built $out" }
}

exit $code
