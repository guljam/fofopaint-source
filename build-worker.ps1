$src = "${PSScriptRoot}\src\worker\BackgroundImageProcessor.as"
$out = "${PSScriptRoot}\worker.swf"
$inputs = @(Get-ChildItem -Path "${PSScriptRoot}\src\worker" -Filter *.as) + @(Get-Item -Path "${PSScriptRoot}\src\Modules\PixelRestore.as") + @(Get-Item -Path "${PSScriptRoot}\src\Modules\ReplayDataCodec.as")

if (-not (Test-Path -Path $out) -or ($inputs | Where-Object { $_.LastWriteTime -gt (Get-Item -Path $out).LastWriteTime })) {
    Write-Host "Compiling BackgroundImageProcessor.as..."
    & 'D:\adobe_air_sdk_manager\AIRSDK_51.3.4\bin\amxmlc.bat' '-source-path+=E:\fofopaint-source\src' '-target-player=51.1' '-swf-version=51' '-debug=true' '-strict=true' '-warnings=true' '-verbose-stacktraces=true' '-output=E:\fofopaint-source\worker.swf' $src
} else {
    Write-Host "Worker SWF is up to date. Skipping compilation."
}
