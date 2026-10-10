# .air 패키지(legacy): 공유 런타임 AIR 51.3.4 + desktop 프로필, 네이티브 확장(ANE) 없이 AS3 경로로 동작함
# 디버깅(F5)과 번들(make-air-bundle.ps1)은 최신 SDK(51.4.1)를 쓰고, 이 스크립트만 $legacySdk를 씀
# 메인/worker SWF를 debug=false로 bin\release-legacy에 따로 컴파일 (F5용 fofoPaint.swf, bin\release는 건드리지 않음)
# fofoPaint-app.xml은 51.4/extendedDesktop/<extensions>라 그대로는 못 쓰므로 임시 descriptor를 만듦 (원본은 그대로)
#   네임스페이스 51.4 -> 51.3, <extensions> 제거, supportedProfiles -> desktop
# 인증서 비밀번호는 넣지 않음: adt가 실행 중에 물어보면 터미널에 입력
Set-Location $PSScriptRoot
$legacySdk = 'D:\adobe_air_sdk_manager\AIRSDK_51.3.4'
$keystore = 'F:\페인트앱_백업\fofopaintKey\secretkey3.p12'
$release = 'bin\release-legacy'
$desc = 'bin\fofoPaint-air-app.xml'
$options = @('-target-player=51.1', '-swf-version=51', '-debug=false', '-strict=true', '-warnings=true', '-verbose-stacktraces=true')

New-Item -ItemType Directory -Force $release | Out-Null

Write-Host "Compiling release SWFs (SDK $legacySdk) to $release ..."
& "$legacySdk\bin\amxmlc.bat" "-source-path+=$PSScriptRoot\src" "-library-path+=$PSScriptRoot\extension\libwebp.swc" @options "-output=$PSScriptRoot\$release\fofoPaint.swf" "$PSScriptRoot\src\Main.as"
if ($LASTEXITCODE -ne 0) { Write-Host 'main SWF compile failed'; exit $LASTEXITCODE }
& "$legacySdk\bin\amxmlc.bat" "-source-path+=$PSScriptRoot\src" @options "-output=$PSScriptRoot\$release\worker.swf" "$PSScriptRoot\src\worker\BackgroundImageProcessor.as"
if ($LASTEXITCODE -ne 0) { Write-Host 'worker SWF compile failed'; exit $LASTEXITCODE }

$xml = [IO.File]::ReadAllText("$PSScriptRoot\fofoPaint-app.xml")
$xml = $xml -replace 'http://ns\.adobe\.com/air/application/51\.4', 'http://ns.adobe.com/air/application/51.3'
$xml = $xml -replace '(?s)<extensions>.*?</extensions>', ''
$xml = $xml -replace '<supportedProfiles>[^<]*</supportedProfiles>', '<supportedProfiles>desktop</supportedProfiles>'
[IO.File]::WriteAllText("$PSScriptRoot\$desc", $xml, (New-Object System.Text.UTF8Encoding($false)))

Write-Host 'Packaging bin\fofoPaint.air (certificate password prompt) ...'
& "$legacySdk\bin\adt.bat" -package -storetype pkcs12 -keystore $keystore 'bin\fofoPaint.air' $desc 'resource\icon' 'manual' -C $release 'fofoPaint.swf' 'worker.swf'
$code = $LASTEXITCODE
Remove-Item $desc -ErrorAction SilentlyContinue
if ($code -eq 0) { Write-Host 'Built bin\fofoPaint.air' }
exit $code
