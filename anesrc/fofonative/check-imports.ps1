# 빌드한 fofonative.dll(x86/x64)의 import를 검사함
# - VC 런타임 DLL(vcruntime, msvcp, ucrtbase, api-ms-win-crt-*) 의존이 없어야 함 (정적 CRT)
# - Windows 7 kernel32 등에 없는 API(아래 목록)를 정적으로 import하지 않아야 함
# 결과를 화면에 쓰고, 문제가 있으면 종료 코드 1
$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
$dumpbin = Get-ChildItem -Path "$vs\VC\Tools\MSVC\*\bin\Hostx64\x64\dumpbin.exe" | Select-Object -Last 1

# Windows 8 이상에서 생긴 API 중 이 DLL이 쓸 수도 있는 것들
$win8Plus = @(
    'GetSystemTimePreciseAsFileTime', 'CreateFile2', 'SetThreadDescription', 'GetThreadDescription',
    'GetSystemCpuSetInformation', 'SetThreadSelectedCpuSets', 'WaitOnAddress', 'WakeByAddressSingle', 'WakeByAddressAll',
    'InitializeSynchronizationBarrier', 'EnterSynchronizationBarrier', 'GetCurrentThreadStackLimits',
    'CopyFile2', 'GetFileInformationByHandleEx2', 'PrefetchVirtualMemory', 'VirtualAlloc2', 'MapViewOfFile3',
    'CreateRemoteThreadEx2', 'SetThreadInformation', 'GetThreadInformation', 'SetProcessInformation',
    'GetProcessMitigationPolicy', 'SetProcessMitigationPolicy', 'GetFirmwareType', 'GetPackageFamilyName',
    'GetCurrentPackageId', 'AddDllDirectory', 'SetDefaultDllDirectories', 'RemoveDllDirectory',
    'GetOverlappedResultEx', 'CreateFileMappingFromApp', 'MapViewOfFileFromApp', 'GetSystemFirmwareTable'
)
$runtimeDll = '^(vcruntime|msvcp|ucrtbase|concrt|vcomp|api-ms-win-crt-)'

$failed = $false
foreach ($arch in @('x86', 'x64')) {
    $dll = "$here\build\$arch\fofonative.dll"
    $imports = & $dumpbin.FullName /nologo /imports $dll
    $headers = & $dumpbin.FullName /nologo /headers $dll
    $currentDll = ''
    $list = @{}
    foreach ($line in $imports) {
        if ($line -match '^\s{4}(\S.*\.(dll|DLL))\s*$') {
            $currentDll = $Matches[1]
            $list[$currentDll] = @()
        }
        elseif ($currentDll -and $line -match '^\s+[0-9A-F]+\s+(\S+)\s*$') {
            $list[$currentDll] += $Matches[1]
        }
    }

    Write-Host "== $arch $dll"
    foreach ($name in ($list.Keys | Sort-Object)) {
        Write-Host ("  {0} ({1})" -f $name, $list[$name].Count)
        if ($name -match $runtimeDll) {
            Write-Host "    !! VC runtime DLL dependency"
            $failed = $true
        }
        foreach ($api in $list[$name]) {
            if ($win8Plus -contains $api) {
                Write-Host "    !! Windows 8+ API: $api"
                $failed = $true
            }
        }
    }
    $headers | Select-String -Pattern 'machine \(|operating system version|subsystem version' | ForEach-Object { Write-Host "  $($_.Line.Trim())" }
}

if ($failed) {
    Write-Host 'Import check FAILED'
    exit 1
}
Write-Host 'Import check OK'
