#!/usr/bin/env pwsh
param(
    [string]$Instance = "",
    [switch]$NoOptions
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

if ([string]::IsNullOrWhiteSpace($Instance) -or
    -not (Test-Path -LiteralPath (Join-Path $Instance "instance.cfg"))) {
    throw "Crash Landing Prism instance not found. Pass -Instance 'C:\path\to\instances\Crash Landing'."
}

$Minecraft = Join-Path $Instance "minecraft"
$Mods = Join-Path $Minecraft "mods"
New-Item -ItemType Directory -Force -Path $Mods | Out-Null

Write-Host "Installing fixes into: $Instance"
Copy-Item -LiteralPath (Join-Path $Root "mods\legacyjavafixer-1.0.jar") -Destination (Join-Path $Mods "legacyjavafixer-1.0.jar") -Force
Copy-Item -LiteralPath (Join-Path $Root "mods\clchunkfix-1.1.jar") -Destination (Join-Path $Mods "clchunkfix-1.1.jar") -Force
Remove-Item -LiteralPath (Join-Path $Mods "clchunkfix-1.0.jar") -Force -ErrorAction SilentlyContinue

function Set-GeneralSettings {
    param([string]$Path)

    $settings = [ordered]@{
        MinMemAlloc          = "4096"
        MaxMemAlloc          = "4096"
        OverrideMemory       = "true"
        OverrideJavaArgs     = "true"
        JvmArgs              = '"-XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:G1NewSizePercent=20 -XX:G1ReservePercent=20 -XX:MaxGCPauseMillis=50 -XX:G1HeapRegionSize=32M -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem"'
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    Get-Content -LiteralPath $Path | ForEach-Object { $lines.Add($_) }

    $start = -1
    $end = $lines.Count
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq "[General]") {
            $start = $i
        }
        elseif ($start -ge 0 -and $lines[$i].StartsWith("[") -and $lines[$i].Trim() -ne "[General]") {
            $end = $i
            break
        }
    }
    if ($start -lt 0) { throw "No [General] section in $Path" }

    $changed = @()
    foreach ($key in $settings.Keys) {
        $prefix = "$key="
        $found = $false
        for ($i = $start + 1; $i -lt $end; $i++) {
            if ($lines[$i].StartsWith($prefix)) {
                $newLine = "$key=$($settings[$key])"
                if ($lines[$i] -ne $newLine) {
                    $lines[$i] = $newLine
                    $changed += $key
                }
                $found = $true
                break
            }
        }
        if (-not $found) {
            $lines.Insert($end, "$key=$($settings[$key])")
            $end++
            $changed += $key
        }
    }

    [System.IO.File]::WriteAllLines($Path, $lines, [System.Text.UTF8Encoding]::new($false))
    if ($changed.Count -eq 0) {
        Write-Host "instance.cfg: settings already present"
    }
    else {
        Write-Host ("instance.cfg updated: " + ($changed -join ", "))
    }
}

Write-Host "Applying Java/memory settings..."
Set-GeneralSettings -Path (Join-Path $Instance "instance.cfg")

if (-not $NoOptions) {
    $options = Join-Path $Minecraft "options.txt"
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

$lootDir = Join-Path $Minecraft "config\CustomChestLoot"
if (Test-Path -LiteralPath $lootDir) {
    & (Join-Path $PSScriptRoot "fix-customchestloot.ps1") -ConfigDir $lootDir
}
else {
    Write-Host "CustomChestLoot config not found; skipping."
}

& (Join-Path $PSScriptRoot "cleanup-network-checks.ps1") -MinecraftDir $Minecraft

Write-Host ""
Write-Host "Done. Required mods:"
Write-Host "  $(Join-Path $Mods 'legacyjavafixer-1.0.jar')"
Write-Host "  $(Join-Path $Mods 'clchunkfix-1.1.jar')"
Write-Host "Keep Java 8 selected in Prism."
