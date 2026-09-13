$main   = Join-Path $PSScriptRoot "Main.as"
$replay = Join-Path $PSScriptRoot "Modules\ReplayController.as"

$methodNames = Get-Content $replay |
    Select-String -Pattern '^\s*public\s+static\s+function\s+([A-Za-z_]\w*)\s*\(' |
    ForEach-Object {
        $_.Matches[0].Groups[1].Value
    }

Write-Host "ReplayController public static 함수 수:" $methodNames.Count
Write-Host ""

foreach ($name in $methodNames) {
    $escaped = [regex]::Escape($name)

    $matches = Select-String `
        -Path $main `
        -Pattern "\bfunction\s+$escaped\s*\("

    if ($matches) {
        foreach ($m in $matches) {
            Write-Host "$name -> Main.as:$($m.LineNumber)"
            Write-Host "    $($m.Line.Trim())"
        }
    }
}