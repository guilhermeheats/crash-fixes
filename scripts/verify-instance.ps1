#!/usr/bin/env pwsh
param(
    [string]$Instance = "",
    [switch]$AllowExtra
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$fail = $false

function Ok($message)   { Write-Host "  OK   $message" }
function Warn($message) { Write-Host "  WARN $message" }
function Bad($message)  { Write-Host "  FAIL $message"; $script:fail = $true }

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

if ([string]::IsNullOrWhiteSpace($Instance) -or
    -not (Test-Path -LiteralPath (Join-Path $Instance "instance.cfg")) -or
    -not (Test-Path -LiteralPath (Join-Path $Instance "mmc-pack.json"))) {
    throw "Not a Prism instance. Pass -Instance 'C:\path\to\instances\Crash Landing'."
}

$Minecraft = Join-Path $Instance "minecraft"
$Mods = Join-Path $Minecraft "mods"
Write-Host "Instance: $Instance"
Ok "instance.cfg and mmc-pack.json present"

$pack = Get-Content -LiteralPath (Join-Path $Instance "mmc-pack.json") -Raw | ConvertFrom-Json
$components = @{}
foreach ($component in $pack.components) { $components[$component.uid] = $component.version }
$required = [ordered]@{
    "net.minecraft"      = "1.6.4"
    "net.minecraftforge" = "9.11.1.965"
    "org.lwjgl"          = "2.9.4-nightly-20150209"
}
foreach ($uid in $required.Keys) {
    if ($components[$uid] -eq $required[$uid]) {
        Ok "$uid == $($required[$uid])"
    }
    else {
        Bad "$uid expected $($required[$uid]), got $($components[$uid])"
    }
}

foreach ($jar in @("legacyjavafixer-1.0.jar", "clchunkfix-1.1.jar")) {
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
elseif (-not (Test-Path -LiteralPath $Mods)) {
    Bad "mods directory missing: $Mods"
}
else {
    $expectedNames = @{}
    foreach ($line in Get-Content -LiteralPath $manifestPath) {
        if ($line -notmatch '^([0-9a-fA-F]{64})\s{2}(.+)$') { continue }
        $expectedHash = $Matches[1].ToLower()
        $name = $Matches[2].Trim()
        $expectedNames[[System.IO.Path]::GetFileName($name)] = $true
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

$cfg = Get-Content -LiteralPath (Join-Path $Instance "instance.cfg") -Raw
$javaMatch = [regex]::Match($cfg, '(?m)^JavaPath=(.+)$')
if ($javaMatch.Success) {
    $javaPath = $javaMatch.Groups[1].Value.Trim().Trim('"')
    if (Test-Path -LiteralPath $javaPath) {
        $version = (& $javaPath -version 2>&1 | Select-Object -First 1)
        if ($version -match '1\.8\.') { Ok "Java 8: $version" }
        else { Bad "expected Java 8, got: $version" }
    }
    else {
        Bad "JavaPath does not exist: $javaPath"
    }
}
elseif ($cfg -match '(?m)^AutomaticJava=true$') {
    Warn "AutomaticJava=true; Prism must select Java 8"
}
else {
    Bad "no valid JavaPath and AutomaticJava is not enabled"
}

if ($cfg -match '(?m)^MaxMemAlloc=4096$' -and
    $cfg -match '(?m)^MinMemAlloc=4096$' -and
    $cfg -match 'UseG1GC') {
    Ok "4 GB + G1GC settings present"
}
else {
    Warn "memory/JVM settings differ from the tested 4 GB + G1GC profile"
}

$options = Join-Path $Minecraft "options.txt"
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
