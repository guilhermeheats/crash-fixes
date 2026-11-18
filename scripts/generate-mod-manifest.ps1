#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory = $true)]
    [string]$GameDir
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$mods = Join-Path $GameDir "mods"
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
