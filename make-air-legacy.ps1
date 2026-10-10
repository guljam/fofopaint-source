# .air 패키지(legacy): 공유 런타임 AIR 51.3.4 + desktop 프로필, 네이티브 확장(ANE) 없이 AS3 경로로 동작함
# 디버깅(F5)과 번들(make-air-bundle.ps1)은 최신 SDK(51.4.1)를 쓰고, 이 스크립트만 $legacySdk를 씀
# 메인/worker SWF를 debug=false로 bin\release-legacy에 따로 컴파일 (F5용 fofoPaint.swf, bin\release는 건드리지 않음)
# fofoPaint-app.xml은 51.4/extendedDesktop/<extensions>라 그대로는 못 쓰므로 임시 descriptor를 만듦 (원본은 그대로)
#   네임스페이스 51.4 -> 51.3, <extensions> 제거, supportedProfiles -> desktop
# 버전 표기는 옛 형식(xx.xx)으로 맞춤: 컴파일 때만 Main.as 복사본(bin\legacy-src)의 APP_VERSION/APP_STATE_VERSION과 descriptor versionNumber를 바꿈 (원본 소스는 그대로)
# 인증서 비밀번호는 넣지 않음: adt가 실행 중에 물어보면 터미널에 입력
Set-Location $PSScriptRoot
$legacySdk = 'D:\adobe_air_sdk_manager\AIRSDK_51.3.4'
# 버전은 legacy_version.txt (예: 28.01)에서 읽음, 올릴 때는 그 파일만 고치면 됨 (28.02, 28.03 ...)
$legacyVersion = ([IO.File]::ReadAllText("$PSScriptRoot\legacy_version.txt")).Trim()
if ($legacyVersion -notmatch '^\d+\.\d+$') { Write-Host "legacy_version.txt must be a.b (e.g. 28.01): '$legacyVersion'"; exit 1 }
$legacyStateVersion = $legacyVersion.Replace('.', '')  # 28.01 -> 2801
$keystore = 'F:\페인트앱_백업\fofopaintKey\secretkey3.p12'
$release = 'bin\release-legacy'
$desc = 'bin\fofoPaint-air-app.xml'
$options = @('-target-player=51.1', '-swf-version=51', '-debug=false', '-strict=true', '-warnings=true', '-verbose-stacktraces=true')

New-Item -ItemType Directory -Force $release | Out-Null

# Main.as 복사본에 옛 버전 값을 넣음 (치환이 안 되면 형식이 바뀐 것이므로 중단)
$legacySrc = 'bin\legacy-src'
New-Item -ItemType Directory -Force $legacySrc | Out-Null
$main = [IO.File]::ReadAllText("$PSScriptRoot\src\Main.as")
$patched = $main -replace '(APP_VERSION:String = ")[^"]*(")', "`${1}$legacyVersion`$2"
$patched = $patched -replace '(APP_STATE_VERSION:String = ")[^"]*(")', "`${1}$legacyStateVersion`$2"
if ($patched -notmatch "APP_VERSION:String = `"$([regex]::Escape($legacyVersion))`"" -or $patched -notmatch "APP_STATE_VERSION:String = `"$([regex]::Escape($legacyStateVersion))`"") { Write-Host 'Main.as version patch failed'; exit 1 }
[IO.File]::WriteAllText("$PSScriptRoot\$legacySrc\Main.as", $patched, (New-Object System.Text.UTF8Encoding($true)))

Write-Host "Compiling release SWFs (SDK $legacySdk) to $release ..."
& "$legacySdk\bin\amxmlc.bat" "-source-path+=$PSScriptRoot\src" "-library-path+=$PSScriptRoot\extension\libwebp.swc" @options "-output=$PSScriptRoot\$release\fofoPaint.swf" "$PSScriptRoot\$legacySrc\Main.as"
if ($LASTEXITCODE -ne 0) { Write-Host 'main SWF compile failed'; exit $LASTEXITCODE }
& "$legacySdk\bin\amxmlc.bat" "-source-path+=$PSScriptRoot\src" @options "-output=$PSScriptRoot\$release\worker.swf" "$PSScriptRoot\src\worker\BackgroundImageProcessor.as"
if ($LASTEXITCODE -ne 0) { Write-Host 'worker SWF compile failed'; exit $LASTEXITCODE }

$xml = [IO.File]::ReadAllText("$PSScriptRoot\fofoPaint-app.xml")
$xml = $xml -replace 'http://ns\.adobe\.com/air/application/51\.4', 'http://ns.adobe.com/air/application/51.3'
$xml = $xml -replace '(?s)<extensions>.*?</extensions>', ''
$xml = $xml -replace '<versionNumber>[^<]*</versionNumber>', "<versionNumber>$legacyVersion</versionNumber>"
$xml = $xml -replace '<supportedProfiles>[^<]*</supportedProfiles>', '<supportedProfiles>desktop</supportedProfiles>'
[IO.File]::WriteAllText("$PSScriptRoot\$desc", $xml, (New-Object System.Text.UTF8Encoding($false)))

Write-Host 'Packaging bin\fofoPaint.air (certificate password prompt) ...'
& "$legacySdk\bin\adt.bat" -package -storetype pkcs12 -keystore $keystore 'bin\fofoPaint.air' $desc 'resource\icon' 'manual' -C $release 'fofoPaint.swf' 'worker.swf'
$code = $LASTEXITCODE
Remove-Item $desc -ErrorAction SilentlyContinue
if ($code -eq 0) { Write-Host 'Built bin\fofoPaint.air' }
exit $code
