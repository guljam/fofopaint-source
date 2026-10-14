# com.fofo.nativecore ANE 빌드 (Windows x86/x64 DLL + default 플랫폼)
# 결과: extension\com.fofo.nativecore.ane (패키징용), .ane-debug\com.fofo.nativecore.ane (디버그 실행용, launch.json extdir)
# 소스가 바뀌었을때만 다시 빌드하고, ANE가 바뀌었을때만 다시 풀어줌
# 다시 빌드할 때는 x86/x64 DLL을 동시에 빌드하고, third_party obj와 nativecore.swc는 해당 소스가 그대로면 재사용함 (-Force면 전부 다시 빌드)
# 바뀌었는지는 수정 시각이 아니라 내용으로 정함: 소스 + SDK 경로의 SHA-256을 extension\com.fofo.nativecore.ane.srchash(저장소에 추적)와 비교
#   (수정 시각으로 정하면 브랜치를 바꿀 때 git이 시각을 새로 찍어서 다시 빌드하고, 빌드할 때마다 DLL·.ane 바이트가 달라져서 .ane가 늘 수정됨으로 뜸)
#   .ane와 .srchash는 같이 커밋할 것
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
$sourceStamp = "$output.srchash"

Add-Type -AssemblyName System.IO.Compression.FileSystem

$sources = @(Get-Item -Path "$here\extension.xml", $PSCommandPath) +
    @(Get-ChildItem -Path "$here\src", "$here\as3", "$here\third_party" -Recurse -File)

# 줄바꿈(CRLF/LF)이 달라도 같은 값이 나오게 텍스트 파일은 CR을 빼고 해시함, 경로는 이 폴더 기준 상대 경로
$sha = [Security.Cryptography.SHA256]::Create()
$hashText = New-Object System.Text.StringBuilder
[void]$hashText.Append("$sdk`n")
# 외부 라이브러리 obj 재사용, SWC 재사용 판단용으로 third_party와 as3 파일 해시는 따로도 모아둠
$thirdPartyHashText = New-Object System.Text.StringBuilder
$as3HashText = New-Object System.Text.StringBuilder
[void]$as3HashText.Append("$sdk`n")

foreach ($file in ($sources | Sort-Object -Property FullName)) {
    $relative = $file.FullName.Substring($here.Length).Replace('\', '/')

    if ($file.Extension -match '^\.(c|h|cpp|as|xml|ps1|txt)$') {
        $content = [IO.File]::ReadAllText($file.FullName) -replace "`r", ''
        $bytes = [Text.Encoding]::UTF8.GetBytes($content)
    }
    else {
        $bytes = [IO.File]::ReadAllBytes($file.FullName)
    }

    $fileHashLine = "$relative $([BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', ''))`n"
    [void]$hashText.Append($fileHashLine)
    if ($relative.StartsWith('/third_party/')) { [void]$thirdPartyHashText.Append($fileHashLine) }
    if ($relative.StartsWith('/as3/')) { [void]$as3HashText.Append($fileHashLine) }
}

$sourceHash = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($hashText.ToString()))).Replace('-', '')
$savedHash = if (Test-Path -Path $sourceStamp) { ([IO.File]::ReadAllText($sourceStamp)).Trim() } else { '' }
$needBuild = $Force -or -not (Test-Path -Path $output) -or $savedHash -ne $sourceHash

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

    # x86과 x64 DLL은 서로 상관없어서 cmd를 동시에 띄워 빌드함 (두 빌드 출력이 한 콘솔에 섞여 나옴)
    # 외부 라이브러리 obj는 build\<아키텍처>\obj-third_party에 따로 두고, third_party 소스와 컴파일 옵션이 그대로면 다시 컴파일하지 않고 링크에 재사용함 (-Force면 다시 컴파일)
    # cmd는 배치 파일을 OEM 코드 페이지로 읽어서 같은 인코딩으로 씀
    $batchFileEncoding = [Text.Encoding]::GetEncoding([Globalization.CultureInfo]::CurrentCulture.TextInfo.OEMCodePage)
    $dllBuildJobs = @()

    foreach ($arch in @(@{ name = 'x86'; vcvars = 'vcvars32.bat'; lib = 'win'; flags = '/arch:SSE2' }, @{ name = 'x64'; vcvars = 'vcvars64.bat'; lib = 'win64'; flags = '' })) {
        $out = "$build\$($arch.name)"
        $obj = "$out\obj"
        $thirdPartyObj = "$out\obj-third_party"
        $thirdPartyObjStamp = "$thirdPartyObj\third_party.srchash"
        New-Item -ItemType Directory -Force $obj, $thirdPartyObj | Out-Null
        Remove-Item -Path "$obj\*" -Force -ErrorAction SilentlyContinue

        $thirdPartyObjHash = "$common $($arch.flags)`n$($thirdPartyHashText.ToString())"
        $savedThirdPartyObjHash = if (Test-Path -Path $thirdPartyObjStamp) { [IO.File]::ReadAllText($thirdPartyObjStamp) } else { '' }
        $thirdPartyObjReusable = -not $Force -and $savedThirdPartyObjHash -eq $thirdPartyObjHash -and (Test-Path -Path "$thirdPartyObj\*.obj")
        $compileC = ''
        $linkThirdPartyObj = ''
        if ($cFiles.Count -gt 0) {
            if (-not $thirdPartyObjReusable) {
                Remove-Item -Path "$thirdPartyObj\*" -Force -ErrorAction SilentlyContinue
                $compileC = " && cl /c $common $($arch.flags) /Fo`"$thirdPartyObj\\`" /Fd`"$thirdPartyObj\c.pdb`" $($cFiles -join ' ')"
            }
            else {
                Write-Host "$($arch.name): third_party obj is up to date. Reusing."
            }
            $linkThirdPartyObj = " `"$thirdPartyObj\*.obj`""
        }

        $compileCpp = " && cl /c $common $($arch.flags) /EHsc /std:c++17 /Fo`"$obj\\`" /Fd`"$obj\cpp.pdb`" $($cppFiles -join ' ')"
        $link = " && link /nologo /DLL /DEBUG /OPT:REF /OPT:ICF /OUT:`"$out\fofonative.dll`" /PDB:`"$out\fofonative.pdb`" `"$obj\*.obj`"$linkThirdPartyObj `"$sdk\lib\$($arch.lib)\FlashRuntimeExtensions.lib`""
        $cmd = "call `"$vs\VC\Auxiliary\Build\$($arch.vcvars)`" >nul$compileC$compileCpp$link"
        $dllBuildBatch = "$out\build-dll.cmd"
        [IO.File]::WriteAllText($dllBuildBatch, "@echo off`r`n$cmd`r`nexit /b %ERRORLEVEL%`r`n", $batchFileEncoding)

        $dllBuildProcess = Start-Process -FilePath 'cmd.exe' -ArgumentList "/c `"$dllBuildBatch`"" -NoNewWindow -PassThru
        $null = $dllBuildProcess.Handle # 핸들을 미리 잡아둬야 끝난 뒤 ExitCode를 읽을 수 있음
        $dllBuildJobs += @{ arch = $arch.name; process = $dllBuildProcess; thirdPartyObjStamp = $thirdPartyObjStamp; thirdPartyObjHash = $thirdPartyObjHash }
    }

    # 두 빌드가 다 끝날때까지 기다린 다음 실패를 확인함, 성공한 아키텍처만 third_party obj 스탬프를 남김
    $failedDllArchNames = @()
    foreach ($dllBuildJob in $dllBuildJobs) {
        $dllBuildJob.process.WaitForExit()
        if ($dllBuildJob.process.ExitCode -ne 0) {
            $failedDllArchNames += $dllBuildJob.arch
        }
        elseif ($cFiles.Count -gt 0) {
            [IO.File]::WriteAllText($dllBuildJob.thirdPartyObjStamp, $dllBuildJob.thirdPartyObjHash)
        }
    }
    if ($failedDllArchNames.Count -gt 0) { throw "$($failedDllArchNames -join ', ') DLL 빌드 실패" }

    # library.swf용 SWC, as3 소스가 그대로면 이전 SWC를 재사용함 (-Force면 다시 빌드)
    $swcStamp = "$build\nativecore.swc.srchash"
    $as3Hash = $as3HashText.ToString()
    $savedAs3Hash = if (Test-Path -Path $swcStamp) { [IO.File]::ReadAllText($swcStamp) } else { '' }
    if ($Force -or -not (Test-Path -Path "$build\nativecore.swc") -or $savedAs3Hash -ne $as3Hash) {
        & "$sdk\bin\acompc.bat" "-source-path=$here\as3" '-include-classes=com.fofo.nativecore.NativeBridge' '-swf-version=51' "-output=$build\nativecore.swc"
        if ($LASTEXITCODE -ne 0) { throw 'SWC 빌드 실패' }
        [IO.File]::WriteAllText($swcStamp, $as3Hash)
    }
    else {
        Write-Host 'nativecore.swc is up to date. Reusing.'
    }

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

    [IO.File]::WriteAllText($sourceStamp, $sourceHash)
    Write-Host "Built $output"
}
else {
    Write-Host "$extensionId ANE is up to date. Skipping compilation."
}

# adl은 압축을 푼 ANE 폴더가 필요함, 풀어둔 것이 지금 ANE와 다를때만 다시 풀어줌
$aneStamp = (Get-FileHash -Path $output -Algorithm SHA256).Hash
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
