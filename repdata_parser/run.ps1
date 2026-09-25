param(
    [Parameter(Mandatory = $true, Position = 0)][string]$InputFile,
    [Parameter(Position = 1)][string]$OutputDirectory
)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sdk = 'D:\adobe_air_sdk_manager\AIRSDK_51.3.4'
$source = (Resolve-Path -LiteralPath $InputFile).Path
if (-not $OutputDirectory) {
    $stem = [IO.Path]::GetFileNameWithoutExtension($source)
    if ($stem -eq 'repdata') { $stem = 'repdata' }
    $OutputDirectory = Join-Path $here (Join-Path 'output' $stem)
}
$target = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force -Path $target | Out-Null
$compiler = Join-Path $sdk 'bin\amxmlc.bat'
$adl = Join-Path $sdk 'bin\adl.exe'
$outputArg = '-output=' + (Join-Path $here 'ReplayParser.swf')
& $compiler $outputArg ('-source-path+=' + (Join-Path $here '..\src')) (Join-Path $here 'ReplayParser.as')
if ($LASTEXITCODE -ne 0) { throw 'AIR compilation failed' }
& $adl -nodebug (Join-Path $here 'ReplayParser-app.xml') $here -- $source $target
if ($LASTEXITCODE -ne 0) { throw "Replay parsing failed (exit $LASTEXITCODE)" }
if ([IO.Path]::GetExtension($source).ToLowerInvariant() -ne '.txt') {
    Write-Output (Join-Path $target ([IO.Path]::GetFileName($source) + '.txt'))
}
Write-Output (Join-Path $target 'index.html')
