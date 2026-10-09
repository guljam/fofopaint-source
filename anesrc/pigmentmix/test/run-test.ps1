# pigmentmix ANE 속도 테스트 실행 (먼저 ..\build-ane.ps1로 ANE를 빌드해야 함)
# 결과: test-output\pigmentmix\report.txt, demo_normal_vs_pigment.png, noise_*.png
# -threads 0이면 CPU 스레드 수만큼, 1이면 단일 스레드
param([int]$threads = 0)
$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot
$root = (Resolve-Path "$here\..\..\..").Path
$sdk = 'D:\adobe_air_sdk_manager\AIRSDK_51.3.4'
$out = "$root\test-output\pigmentmix"
$image = "$root\test_sample\testimage.jpg"

New-Item -ItemType Directory -Force $out | Out-Null
Copy-Item "$here\PigmentMixTest-app.xml" "$out\PigmentMixTest-app.xml" -Force

$outDefine = "-define+=TEST::OUT,'" + ($out -replace '\\', '/') + "'"
$imageDefine = "-define+=TEST::IMAGE,'" + ($image -replace '\\', '/') + "'"
& "$sdk\bin\amxmlc.bat" "-source-path+=$here" '-target-player=51.1' '-swf-version=51' '-debug=false' '-strict=true' $outDefine $imageDefine "-define+=TEST::THREADS,$threads" "-output=$out\PigmentMixTest.swf" "$here\PigmentMixTest.as"
if ($LASTEXITCODE -ne 0) { throw '테스트 SWF 빌드 실패' }

# 별도 app id라 사용자 작업 저장소와 섞이지 않음
& "$sdk\bin\adl.exe" -profile extendedDesktop -extdir "$here\..\build\ext" "$out\PigmentMixTest-app.xml" $out
Get-Content "$out\report.txt"
