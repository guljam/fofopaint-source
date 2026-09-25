$src = "${PSScriptRoot}\src\worker\BackgroundImageProcessor.as"
$codec = "${PSScriptRoot}\src\Modules\ReplayDataCodec.as"
$out = "${PSScriptRoot}\worker.swf"

if (-not (Test-Path -Path $out) -or ((Get-Item -Path $src).LastWriteTime -gt (Get-Item -Path $out).LastWriteTime) -or ((Get-Item -Path $codec).LastWriteTime -gt (Get-Item -Path $out).LastWriteTime)) {
    Write-Host "Compiling BackgroundImageProcessor.as..."
    & 'D:\adobe_air_sdk_manager\AIRSDK_51.3.4\bin\amxmlc.bat' '-source-path+=E:\fofopaint-source\src' '-target-player=51.1' '-swf-version=51' '-debug=true' '-strict=true' '-warnings=true' '-verbose-stacktraces=true' '-output=E:\fofopaint-source\worker.swf' 'E:\fofopaint-source\src\worker\BackgroundImageProcessor.as'
} else {
    Write-Host "Worker SWF is up to date. Skipping compilation."
}
