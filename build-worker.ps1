# worker.swf 빌드 (F5 preLaunchTask "Compile Worker SWF")
# 다시 빌드할지는 파일 수정 시각이 아니라 내용으로 정함: 입력 소스 + SDK 경로 + 옵션의 SHA-256을 worker.swf.srchash(저장소에 추적)와 비교
# 수정 시각으로 정하면 브랜치를 바꿀 때 git이 바뀐 소스의 시각을 새로 찍어서 다시 빌드하는데,
# amxmlc는 같은 소스로도 매번 다른 바이트를 만들어서(실측) worker.swf가 늘 수정됨으로 뜸
# worker.swf와 worker.swf.srchash는 같이 커밋할 것
$sdk = 'D:\adobe_air_sdk_manager\AIRSDK_51.4.1'
$src = "${PSScriptRoot}\src\worker\BackgroundImageProcessor.as"
$out = "${PSScriptRoot}\worker.swf"
$stamp = "${PSScriptRoot}\worker.swf.srchash"
$options = @('-target-player=51.1', '-swf-version=51', '-debug=true', '-strict=true', '-warnings=true', '-verbose-stacktraces=true')
$inputs = @(Get-ChildItem -Path "${PSScriptRoot}\src\worker" -Filter *.as) + @(Get-Item -Path "${PSScriptRoot}\src\Modules\L1Data\PixelRestore.as", "${PSScriptRoot}\src\Modules\L1Data\NativeCore.as", "${PSScriptRoot}\src\Modules\L1Data\CacheImageFormat.as") +@(Get-Item -Path "${PSScriptRoot}\src\Modules\L1Data\ReplayDataCodec.as")

# 줄바꿈(CRLF/LF)이 달라도 같은 값이 나오게 CR을 빼고 해시함
$text = "$sdk`n$($options -join ' ')`n"
foreach ($file in ($inputs | Sort-Object -Property Name)) {
    $text += $file.Name + "`n" + ([IO.File]::ReadAllText($file.FullName) -replace "`r", '') + "`n"
}
$sha = [Security.Cryptography.SHA256]::Create()
$hash = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text))).Replace('-', '')
$saved = if (Test-Path -Path $stamp) { ([IO.File]::ReadAllText($stamp)).Trim() } else { '' }

if (-not (Test-Path -Path $out) -or $saved -ne $hash) {
    Write-Host "Compiling BackgroundImageProcessor.as..."
    & "$sdk\bin\amxmlc.bat" "-source-path+=${PSScriptRoot}\src" @options "-output=$out" $src

    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    [IO.File]::WriteAllText($stamp, $hash)
} else {
    Write-Host "Worker SWF is up to date. Skipping compilation."
}
