# com.fofo.nativecore ANE 빌드 (Windows x86/x64 DLL + default 플랫폼)
# 결과: extension\com.fofo.nativecore.ane (패키징용), .ane-debug\com.fofo.nativecore.ane (디버그 실행용, launch.json extdir)
# 소스가 바뀌었을때만 다시 빌드하고, ANE가 바뀌었을때만 다시 풀어줌
# -Force: 소스가 그대로여도 다시 빌드
# macOS/Linux 네이티브 빌드는 없음, 그 운영체제에서는 default 플랫폼으로 들어가서 AS3 경로로 동작함
param(
    [switch]$Force
)
$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot
$root = (Resolve-Path "$here\..\..").Path
$sdk = 'D:\adobe_air_sdk_manager\AIRSDK_51.4.1'
$build = "$here\build"
$extensionId = 'com.fofo.nativecore'
$output = "$root\extension\$extensionId.ane"
$debugRoot = "$root\.ane-debug"
$debugExtension = "$debugRoot\$extensionId.ane"
$debugStamp = "$debugRoot\$extensionId.stamp"

Add-Type -AssemblyName System.IO.Compression.FileSystem

$sources = @(Get-Item -Path "$here\extension.xml", $PSCommandPath) +
    @(Get-ChildItem -Path "$here\src", "$here\as3", "$here\third_party" -Recurse -File)
$needBuild = $Force -or -not (Test-Path -Path $output)

if (-not $needBuild) {
    $outputTime = (Get-Item -Path $output).LastWriteTime
    $needBuild = [bool]($sources | Where-Object { $_.LastWriteTime -gt $outputTime })
}

if ($needBuild) {
    Write-Host "Compiling $extensionId ANE..."

    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $vs) { throw 'Visual Studio C++ 빌드 도구를 찾을 수 없음' }
    $env:PATH = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer;$env:PATH" # vcvars가 vswhere를 PATH에서 찾음

    # C++ 소스와 외부 라이브러리 C 소스 (third_party\<라이브러리>\*.c)
    $cppFiles = @(Get-ChildItem -Path "$here\src" -Filter *.cpp | ForEach-Object { "`"$($_.FullName)`"" })
    $cFiles = @(Get-ChildItem -Path "$here\third_party" -Recurse -Filter *.c -ErrorAction SilentlyContinue | ForEach-Object { "`"$($_.FullName)`"" })
    $includes = @("/I`"$sdk\include`"") + @(Get-ChildItem -Path "$here\third_party" -Directory -ErrorAction SilentlyContinue | ForEach-Object { "/I`"$($_.FullName)`"" })

    # /MT: VC 런타임 DLL 없이 동작 (정적 CRT)
    # _WIN32_WINNT=0x0601: Windows 7 API까지만 선언되게 함
    # x86은 SSE2까지만 씀 (/arch:SSE2, x64는 기본이 SSE2)
    $common = "/nologo /utf-8 /O2 /MT /W3 /GS /Zi /MP /D_WIN32_WINNT=0x0601 /DWINVER=0x0601 /D_CRT_SECURE_NO_WARNINGS " + ($includes -join ' ')

    foreach ($arch in @(@{ name = 'x86'; vcvars = 'vcvars32.bat'; lib = 'win'; flags = '/arch:SSE2' }, @{ name = 'x64'; vcvars = 'vcvars64.bat'; lib = 'win64'; flags = '' })) {
        $out = "$build\$($arch.name)"
        $obj = "$out\obj"
        New-Item -ItemType Directory -Force $obj | Out-Null
        Remove-Item -Path "$obj\*" -Force -ErrorAction SilentlyContinue
        $compileC = if ($cFiles.Count -gt 0) { " && cl /c $common $($arch.flags) /Fo`"$obj\\`" /Fd`"$obj\c.pdb`" $($cFiles -join ' ')" } else { '' }
        $compileCpp = " && cl /c $common $($arch.flags) /EHsc /std:c++17 /Fo`"$obj\\`" /Fd`"$obj\cpp.pdb`" $($cppFiles -join ' ')"
        $link = " && link /nologo /DLL /DEBUG /OPT:REF /OPT:ICF /OUT:`"$out\fofonative.dll`" /PDB:`"$out\fofonative.pdb`" `"$obj\*.obj`" `"$sdk\lib\$($arch.lib)\FlashRuntimeExtensions.lib`""
        $cmd = "call `"$vs\VC\Auxiliary\Build\$($arch.vcvars)`" >nul$compileC$compileCpp$link"
        cmd /c $cmd
        if ($LASTEXITCODE -ne 0) { throw "$($arch.name) DLL 빌드 실패" }
    }

    # library.swf용 SWC
    & "$sdk\bin\acompc.bat" "-source-path=$here\as3" '-include-classes=com.fofo.nativecore.NativeBridge' '-swf-version=51' "-output=$build\nativecore.swc"
    if ($LASTEXITCODE -ne 0) { throw 'SWC 빌드 실패' }

    $zip = [IO.Compression.ZipFile]::OpenRead("$build\nativecore.swc")
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
        & "$sdk\bin\adt.bat" -package -target ane $output "$here\extension.xml" -swc nativecore.swc `
            -platform Windows-x86 -C x86 fofonative.dll library.swf `
            -platform Windows-x86-64 -C x64 fofonative.dll library.swf `
            -platform default -C default library.swf
        if ($LASTEXITCODE -ne 0) { throw 'ANE 패키징 실패' }
    }
    finally {
        Pop-Location
    }

    Write-Host "Built $output"
}
else {
    Write-Host "$extensionId ANE is up to date. Skipping compilation."
}

# adl은 압축을 푼 ANE 폴더가 필요함, 풀어둔 것이 지금 ANE와 다를때만 다시 풀어줌
$aneStamp = (Get-Item -Path $output).LastWriteTimeUtc.Ticks.ToString()
$unpackedStamp = if (Test-Path -Path $debugStamp) { (Get-Content -Path $debugStamp -Raw).Trim() } else { '' }

if ($unpackedStamp -ne $aneStamp -or -not (Test-Path -Path "$debugExtension\META-INF\ANE\extension.xml")) {
    if (Test-Path -Path $debugExtension) {
        Remove-Item -Path $debugExtension -Recurse -Force
    }

    New-Item -ItemType Directory -Force $debugExtension | Out-Null
    [IO.Compression.ZipFile]::ExtractToDirectory($output, $debugExtension)
    Set-Content -Path $debugStamp -Value $aneStamp
    Write-Host "Unpacked $debugExtension"
}
else {
    Write-Host "Unpacked $extensionId ANE is up to date."
}
