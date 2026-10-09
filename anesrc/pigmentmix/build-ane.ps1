# com.fofo.pigmentmix ANE 빌드 (Windows x86/x64 DLL + default 플랫폼)
# 결과: build\com.fofo.pigmentmix.ane, build\ext\com.fofo.pigmentmix.ane (adl -extdir용으로 압축 푼 것)
# mixbox 소스는 저장소에 넣지 않고 $mixboxDir에서 include함 (CC BY-NC 4.0)
param(
    [string]$mixboxDir = 'D:\github_clones\mixbox\cpp'
)
$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot
$sdk = 'D:\adobe_air_sdk_manager\AIRSDK_51.3.4'
$build = "$here\build"
$output = "$build\com.fofo.pigmentmix.ane"
$unpacked = "$build\ext\com.fofo.pigmentmix.ane"

if (-not (Test-Path -Path "$mixboxDir\mixbox.cpp")) { throw "mixbox.cpp를 찾을 수 없음: $mixboxDir" }

Add-Type -AssemblyName System.IO.Compression.FileSystem

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vs) { throw 'Visual Studio C++ 빌드 도구를 찾을 수 없음' }

# /fp:precise, FMA 없음: 그리기와 리플레이 결과가 비트 단위로 같아야 해서 빠른 부동소수 옵션을 쓰지 않음
foreach ($arch in @(@{ name = 'x86'; vcvars = 'vcvars32.bat'; lib = 'win' }, @{ name = 'x64'; vcvars = 'vcvars64.bat'; lib = 'win64' })) {
    $out = "$build\$($arch.name)"
    New-Item -ItemType Directory -Force $out | Out-Null
    $cmd = "call `"$vs\VC\Auxiliary\Build\$($arch.vcvars)`" >nul && cl /nologo /utf-8 /O2 /fp:precise /EHsc /std:c++17 /W3 /LD /I`"$sdk\include`" /I`"$mixboxDir`" `"$here\pigmentmix.cpp`" /Fo`"$out\\`" /Fe`"$out\pigmentmix.dll`" /link `"$sdk\lib\$($arch.lib)\FlashRuntimeExtensions.lib`""
    cmd /c $cmd
    if ($LASTEXITCODE -ne 0) { throw "$($arch.name) DLL 빌드 실패" }
}

# library.swf용 SWC (extension 네임스페이스 33.1은 SWF 버전 44 이하만 받음)
& "$sdk\bin\acompc.bat" "-source-path=$here\as3" '-include-classes=com.fofo.pigmentmix.PigmentMix' '-swf-version=44' "-output=$build\pigmentmix.swc"
if ($LASTEXITCODE -ne 0) { throw 'SWC 빌드 실패' }

$zip = [IO.Compression.ZipFile]::OpenRead("$build\pigmentmix.swc")
try {
    $library = $zip.Entries | Where-Object { $_.Name -eq 'library.swf' }
    foreach ($platform in @('x86', 'x64', 'default')) {
        New-Item -ItemType Directory -Force "$build\$platform" | Out-Null
        [IO.Compression.ZipFileExtensions]::ExtractToFile($library, "$build\$platform\library.swf", $true)
    }
}
finally {
    $zip.Dispose()
}

Push-Location $build
try {
    & "$sdk\bin\adt.bat" -package -target ane $output "$here\extension.xml" -swc pigmentmix.swc `
        -platform Windows-x86 -C x86 pigmentmix.dll library.swf `
        -platform Windows-x86-64 -C x64 pigmentmix.dll library.swf `
        -platform default -C default library.swf
    if ($LASTEXITCODE -ne 0) { throw 'ANE 패키징 실패' }
}
finally {
    Pop-Location
}

if (Test-Path -Path $unpacked) { Remove-Item -Path $unpacked -Recurse -Force }
New-Item -ItemType Directory -Force $unpacked | Out-Null
[IO.Compression.ZipFile]::ExtractToDirectory($output, $unpacked)
Write-Host "Built $output"
