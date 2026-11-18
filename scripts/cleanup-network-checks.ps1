#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory = $true)]
    [string]$MinecraftDir
)

$ErrorActionPreference = "Stop"
$changes = @()

function Replace-Text {
    param([string]$Path, [string]$Old, [string]$New)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $text = [System.IO.File]::ReadAllText($Path)
    if (-not $text.Contains($Old)) { return }
    $text = $text.Replace($Old, $New)
    [System.IO.File]::WriteAllText($Path, $text, [System.Text.UTF8Encoding]::new($false))
    $script:changes += $Path
}

$openBlocks = Join-Path $MinecraftDir "config\OpenBlocks.cfg"
if (Test-Path -LiteralPath $openBlocks) {
    $text = [System.IO.File]::ReadAllText($openBlocks)
    $pattern = '(?ms)(\r?\n[ \t]*S:radioStations[ \t]*<).*?(\r?\n[ \t]*>)'
    $newText = [regex]::Replace($text, $pattern, "`$1`r`n     >`r`n", 1)
    if ($newText -ne $text) {
        [System.IO.File]::WriteAllText($openBlocks, $newText, [System.Text.UTF8Encoding]::new($false))
        $changes += $openBlocks
    }
}

$replacements = @(
    @("config\enviromine\EnviroMine.cfg", 'B:"Check For Updates"=true', 'B:"Check For Updates"=false'),
    @("config\BiblioCraft.cfg", "B:CheckForUpdates=true", "B:CheckForUpdates=false"),
    @("config\AppliedEnergistics.cfg", "B:enableVersionChecker=true", "B:enableVersionChecker=false"),
    @("config\powercrystals\core\client.cfg", "B:EnableUpdateCheck=true", "B:EnableUpdateCheck=false"),
    @("config\cofh\CoFHCore.cfg", "B:EnableUpdateNotifications=true", "B:EnableUpdateNotifications=false"),
    @("config\cofh\ThermalExpansion.cfg", "B:EnableUpdateNotifications=true", "B:EnableUpdateNotifications=false"),
    @("config\modstats.cfg", "B:AllowUpdates=true", "B:AllowUpdates=false"),
    @("config\NEI.cfg", "checkUpdates=true", "checkUpdates=false"),
    @("config\ChickenChunks.cfg", "checkUpdates=true", "checkUpdates=false"),
    @("config\CodeChickenCore.cfg", "checkUpdates=true", "checkUpdates=false")
)

foreach ($item in $replacements) {
    Replace-Text -Path (Join-Path $MinecraftDir $item[0]) -Old $item[1] -New $item[2]
}

if ($changes.Count -eq 0) {
    Write-Host "Network/update checks already disabled."
}
else {
    Write-Host "Network/update checks disabled:"
    $changes | Sort-Object -Unique | ForEach-Object { Write-Host "  $_" }
}
