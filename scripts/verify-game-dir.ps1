#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory = $true)]
    [string]$GameDir,
    [switch]$AllowExtra
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$fail = $false

function Ok($message)   { Write-Host "  OK   $message" }
function Warn($message) { Write-Host "  WARN $message" }
function Bad($message)  { Write-Host "  FAIL $message"; $script:fail = $true }

Write-Host "Game directory: $GameDir"
$Mods = Join-Path $GameDir "mods"
$Config = Join-Path $GameDir "config"
if (-not (Test-Path -LiteralPath $Mods)) {
    throw "Not a Minecraft game directory (missing mods/): $GameDir"
}
Ok "mods/ present"
if (Test-Path -LiteralPath $Config) { Ok "config/ present" }
else { Warn "config/ missing; is Crash Landing installed?" }

foreach ($jar in @("legacyjavafixer-1.0.jar", "clchunkfix-1.8.jar")) {
    if (Test-Path -LiteralPath (Join-Path $Mods $jar)) {
        Ok "required mod: $jar"
    }
    else {
        Bad "missing required mod: $jar"
    }
}

$manifestPath = Join-Path $Root "mods.sha256"
if (-not (Test-Path -LiteralPath $manifestPath)) {
    Bad "mods.sha256 not found"
}
else {
    $expectedNames = @{}
    foreach ($line in Get-Content -LiteralPath $manifestPath) {
        if ($line -notmatch '^([0-9a-fA-F]{64})\s{2}(.+)$') { continue }
        $expectedHash = $Matches[1].ToLower()
        $name = [System.IO.Path]::GetFileName($Matches[2].Trim())
        $expectedNames[$name] = $true
        $file = Join-Path $Mods $name
        if (-not (Test-Path -LiteralPath $file)) {
            Bad "missing mod: $name"
            continue
        }
        $actual = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLower()
        if ($actual -ne $expectedHash) { Bad "checksum mismatch: $name" }
    }
    Ok "all mod files match mods.sha256"

    $actualNames = @{}
    Get-ChildItem -LiteralPath $Mods -File | Where-Object {
        $_.Name -match '\.(jar|zip|jar\.disabled|zip\.disabled)$'
    } | ForEach-Object { $actualNames[$_.Name] = $true }

    $extra = @($actualNames.Keys | Where-Object { -not $expectedNames.ContainsKey($_) } | Sort-Object)
    $missing = @($expectedNames.Keys | Where-Object { -not $actualNames.ContainsKey($_) } | Sort-Object)
    if ($missing.Count -gt 0) { Bad ("missing mods: " + ($missing -join ", ")) }
    if ($extra.Count -gt 0) {
        if ($AllowExtra) { Warn ("extra mods not in manifest: " + ($extra -join ", ")) }
        else { Bad ("extra mods not in manifest: " + ($extra -join ", ")) }
    }
    if ($missing.Count -eq 0 -and $extra.Count -eq 0) { Ok "no unexpected mods" }
}

$logCandidates = @(
    (Join-Path $GameDir "logs\latest.log"),
    (Join-Path $GameDir "ForgeModLoader-client-0.log")
)
$log = $logCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if ($log) {
    $text = Get-Content -LiteralPath $log -Raw
    $logName = Split-Path -Leaf $log
    if ($text -match 'Forge Mod Loader version 6\.4\.49\.965 for Minecraft 1\.6\.4' -or
        $text -match 'Minecraft Forge 9\.11\.1\.965') {
        Ok "$logName reports Minecraft 1.6.4 + Forge 9.11.1.965"
    }
    else { Warn "$logName present, but expected Forge/Minecraft version not found" }
    if ($text -match 'Java is .*version 1\.8\.') { Ok "$logName reports Java 8" }
    else { Warn "$logName does not clearly report Java 8" }
}
else {
    Warn "No 1.6.4 log found (ForgeModLoader-client-0.log or logs/latest.log); Forge/Java version cannot be verified"
}

$options = Join-Path $GameDir "options.txt"
$reference = Join-Path $Root "examples\options.txt"
if ((Test-Path -LiteralPath $options) -and (Test-Path -LiteralPath $reference)) {
    $diff = Compare-Object (Get-Content -LiteralPath $reference) (Get-Content -LiteralPath $options)
    if ($null -eq $diff) { Ok "options.txt matches the recorded profile" }
    else { Warn "options.txt differs from the recorded profile (user changes allowed)" }
}

Write-Host ""
if ($fail) {
    Write-Host "Integrity check: FAIL"
    exit 1
}
Write-Host "Integrity check: PASS"
