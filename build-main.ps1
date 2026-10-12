# fofoPaint.swf 빌드 (F5 preLaunchTask "FOFO PAINT swf build and debug" 안의 "Compile Main SWF")
# 컴파일 매개변수는 asconfig.json의 compilerOptions를 읽어서 amxmlc 인자로 바꿔 씀
# 다시 빌드할지는 수정 시각이 아니라 내용으로 정함: src 전체 + asconfig.json + 앱 설명 파일 + library-path swc + SDK 경로의 SHA-256을 fofoPaint.swf.srchash와 비교
# -Force: 소스가 그대로여도 다시 빌드
param(
    [switch]$Force
)
$ErrorActionPreference = 'Stop'

$sdk = 'D:\adobe_air_sdk_manager\AIRSDK_51.4.1'
$configPath = "${PSScriptRoot}\asconfig.json"

# asconfig.json은 // 주석이 있어서 줄 시작 주석만 지우고 읽음
$configText = (Get-Content -Path $configPath -Raw -Encoding UTF8) -replace '(?m)^\s*//.*$', ''
$config = $configText | ConvertFrom-Json
$opts = $config.compilerOptions
$out = "${PSScriptRoot}\$($opts.output)"
$stamp = "$out.srchash"

$inputs = @(Get-ChildItem -Path "${PSScriptRoot}\$($opts.'source-path'[0])" -Recurse -File) +
    @(Get-Item -Path $configPath, "${PSScriptRoot}\$($config.application)") +
    @($opts.'library-path' | ForEach-Object { Get-Item -Path "${PSScriptRoot}\$_" })

$sha = [Security.Cryptography.SHA256]::Create()
$hashText = New-Object System.Text.StringBuilder
[void]$hashText.Append("$sdk`n")
foreach ($file in ($inputs | Sort-Object -Property FullName)) {
    $relative = $file.FullName.Substring($PSScriptRoot.Length).Replace('\', '/')
    # 줄바꿈(CRLF/LF)이 달라도 같은 값이 나오게 텍스트 파일은 CR을 빼고 해시함
    if ($file.Extension -match '^\.(as|xml|json)$') {
        $bytes = [Text.Encoding]::UTF8.GetBytes(([IO.File]::ReadAllText($file.FullName) -replace "`r", ''))
    }
    else {
        $bytes = [IO.File]::ReadAllBytes($file.FullName)
    }
    [void]$hashText.Append("$relative $([BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', ''))`n")
}
$hash = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($hashText.ToString()))).Replace('-', '')
$saved = if (Test-Path -Path $stamp) { ([IO.File]::ReadAllText($stamp)).Trim() } else { '' }

if ($Force -or -not (Test-Path -Path $out) -or $saved -ne $hash) {
    Write-Host "Compiling $($config.mainClass) -> $($opts.output)..."
    $compileArgs = @("+configname=$($config.config)", "-source-path+=${PSScriptRoot}\$($opts.'source-path'[0])")
    foreach ($lib in $opts.'library-path') { $compileArgs += "-library-path+=${PSScriptRoot}\$lib" }
    $compileArgs += "-target-player=$($opts.'target-player')", "-swf-version=$($opts.'swf-version')"
    foreach ($flag in 'debug', 'strict', 'warnings', 'verbose-stacktraces') {
        $compileArgs += "-$flag=$("$($opts.$flag)".ToLower())"
    }
    $compileArgs += "-output=$out", "${PSScriptRoot}\src\$($config.mainClass).as"

    & "$sdk\bin\amxmlc.bat" @compileArgs
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    [IO.File]::WriteAllText($stamp, $hash)
}
else {
    Write-Host "Main SWF is up to date. Skipping compilation."
}
