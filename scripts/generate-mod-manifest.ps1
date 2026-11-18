#!/usr/bin/env pwsh
param(
    [string]$Instance = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Instance)) {
    $candidates = @(
        (Join-Path $env:APPDATA "PrismLauncher\instances\Crash Landing"),
        (Join-Path $env:LOCALAPPDATA "PrismLauncher\instances\Crash Landing")
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath (Join-Path $candidate "instance.cfg")) {
            $Instance = $candidate
            break
        }
    }
}
if ([string]::IsNullOrWhiteSpace($Instance)) { throw "Pass -Instance 'C:\path\to\instances\Crash Landing'." }

$mods = Join-Path $Instance "minecraft\mods"
if (-not (Test-Path -LiteralPath $mods)) { throw "Mods directory not found: $mods" }

$lines = Get-ChildItem -LiteralPath $mods -File | Where-Object {
    $_.Name -match '\.(jar|zip|jar\.disabled|zip\.disabled)$'
} | Sort-Object Name | ForEach-Object {
    $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLower()
    "$hash  ./$($_.Name)"
}
[System.IO.File]::WriteAllLines((Join-Path $Root "mods.sha256"), $lines, [System.Text.UTF8Encoding]::new($false))
Write-Host "Wrote $(Join-Path $Root 'mods.sha256')"
Write-Host "$($lines.Count) entries"
