#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory = $true)]
    [string]$GameDir,
    [switch]$NoOptions
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

if (-not (Test-Path -LiteralPath (Join-Path $GameDir "mods"))) {
    throw "Not a Minecraft/Crash Landing game directory (missing mods/): $GameDir"
}

$Mods = Join-Path $GameDir "mods"
Write-Host "Installing fixes into: $GameDir"
Copy-Item -LiteralPath (Join-Path $Root "mods\legacyjavafixer-1.0.jar") -Destination (Join-Path $Mods "legacyjavafixer-1.0.jar") -Force
Copy-Item -LiteralPath (Join-Path $Root "mods\clchunkfix-1.6.jar") -Destination (Join-Path $Mods "clchunkfix-1.6.jar") -Force
Remove-Item -LiteralPath (Join-Path $Mods "clchunkfix-1.0.jar") -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $Mods "clchunkfix-1.1.jar") -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $Mods "clchunkfix-1.2.jar") -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $Mods "clchunkfix-1.3.jar") -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $Mods "clchunkfix-1.4.jar") -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $Mods "clchunkfix-1.5.jar") -Force -ErrorAction SilentlyContinue

if (-not $NoOptions) {
    $options = Join-Path $GameDir "options.txt"
    if (Test-Path -LiteralPath $options) {
        $backup = "$options.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -LiteralPath $options -Destination $backup -Force
        Write-Host "Backed up options.txt to: $backup"
    }
    Copy-Item -LiteralPath (Join-Path $Root "examples\options.txt") -Destination $options -Force
    Write-Host "Applied max-fidelity options.txt"
}
else {
    Write-Host "Skipped options.txt (-NoOptions)"
}

$lootDir = Join-Path $GameDir "config\CustomChestLoot"
if (Test-Path -LiteralPath $lootDir) {
    & (Join-Path $PSScriptRoot "fix-customchestloot.ps1") -ConfigDir $lootDir
}
else {
    Write-Host "CustomChestLoot config not found; skipping. Is Crash Landing installed?"
}

& (Join-Path $PSScriptRoot "cleanup-network-checks.ps1") -MinecraftDir $GameDir

Write-Host ""
Write-Host "Done. Required mods:"
Write-Host "  mods\legacyjavafixer-1.0.jar"
Write-Host "  mods\clchunkfix-1.6.jar"
Write-Host ""
Write-Host "Use Java 8 64-bit and set these JVM arguments in your launcher:"
@'
  -Xms4096m -Xmx4096m
  -XX:+UseG1GC
  -XX:+UnlockExperimentalVMOptions
  -XX:G1NewSizePercent=20
  -XX:G1ReservePercent=20
  -XX:MaxGCPauseMillis=50
  -XX:G1HeapRegionSize=32M
  -XX:+DisableExplicitGC
  -XX:+ParallelRefProcEnabled
  -XX:+PerfDisableSharedMem
'@ | Write-Host
Write-Host ""
Write-Host "Verify with:"
Write-Host "  .\scripts\verify-game-dir.ps1 -GameDir `"$GameDir`""
