# com.fofo.pixeldump ANE 빌드 (Windows x86/x64 DLL + default 플랫폼)
# 결과: extension\com.fofo.pixeldump.ane (패키징용), .ane-debug\com.fofo.pixeldump.ane (디버그 실행용, launch.json extdir)
# 소스가 바뀌었을때만 다시 빌드하고, ANE가 바뀌었을때만 다시 풀어줌
# macOS/Linux 네이티브 빌드는 아직 없음, 그 운영체제에서는 default 플랫폼으로 들어가서 AS3 PixelRestore로 동작함
$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot
$root = (Resolve-Path "$here\..\..").Path
$sdk = 'D:\adobe_air_sdk_manager\AIRSDK_51.3.4'
$build = "$here\build"
$output = "$root\extension\com.fofo.pixeldump.ane"
$debugRoot = "$root\.ane-debug"
$debugExtension = "$debugRoot\com.fofo.pixeldump.ane"
$debugStamp = "$debugRoot\com.fofo.pixeldump.stamp"

Add-Type -AssemblyName System.IO.Compression.FileSystem

$sources = @(Get-Item -Path "$here\pixeldump.c", "$here\extension.xml", $PSCommandPath) + @(Get-ChildItem -Path "$here\as3" -Recurse -Filter *.as)
$needBuild = -not (Test-Path -Path $output)

if (-not $needBuild) {
    $outputTime = (Get-Item -Path $output).LastWriteTime
    $needBuild = [bool]($sources | Where-Object { $_.LastWriteTime -gt $outputTime })
}

if ($needBuild) {
    Write-Host "Compiling pixeldump ANE..."

    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $vs) { throw 'Visual Studio C++ 빌드 도구를 찾을 수 없음' }

    foreach ($arch in @(@{ name = 'x86'; vcvars = 'vcvars32.bat'; lib = 'win' }, @{ name = 'x64'; vcvars = 'vcvars64.bat'; lib = 'win64' })) {
        $out = "$build\$($arch.name)"
        New-Item -ItemType Directory -Force $out | Out-Null
        $cmd = "call `"$vs\VC\Auxiliary\Build\$($arch.vcvars)`" >nul && cl /nologo /utf-8 /O2 /W3 /LD /I`"$sdk\include`" `"$here\pixeldump.c`" /Fo`"$out\\`" /Fe`"$out\pixeldump.dll`" /link `"$sdk\lib\$($arch.lib)\FlashRuntimeExtensions.lib`""
        cmd /c $cmd
        if ($LASTEXITCODE -ne 0) { throw "$($arch.name) DLL 빌드 실패" }
    }

    # library.swf용 SWC (extension 네임스페이스 33.1은 SWF 버전 44 이하만 받음)
    & "$sdk\bin\acompc.bat" "-source-path=$here\as3" '-include-classes=com.fofo.pixeldump.PixelDump' '-swf-version=44' "-output=$build\pixeldump.swc"
    if ($LASTEXITCODE -ne 0) { throw 'SWC 빌드 실패' }

    $zip = [IO.Compression.ZipFile]::OpenRead("$build\pixeldump.swc")
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
        & "$sdk\bin\adt.bat" -package -target ane $output "$here\extension.xml" -swc pixeldump.swc `
            -platform Windows-x86 -C x86 pixeldump.dll library.swf `
            -platform Windows-x86-64 -C x64 pixeldump.dll library.swf `
            -platform default -C default library.swf
        if ($LASTEXITCODE -ne 0) { throw 'ANE 패키징 실패' }
    }
    finally {
        Pop-Location
    }

    Write-Host "Built $output"
}
else {
    Write-Host "pixeldump ANE is up to date. Skipping compilation."
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
    Write-Host "Unpacked pixeldump ANE is up to date."
}
