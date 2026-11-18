#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$fail = $false

Push-Location $Root
try {
    foreach ($line in Get-Content -LiteralPath "checksums.txt") {
        if ($line -notmatch '^([0-9a-fA-F]{64})\s{2}(.+)$') { continue }
        $expected = $Matches[1].ToLower()
        $file = $Matches[2].Trim()
        if (-not (Test-Path -LiteralPath $file)) {
            Write-Host "MISSING $file"
            $fail = $true
            continue
        }
        $actual = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLower()
        if ($actual -eq $expected) {
            Write-Host "OK      $file"
        }
        else {
            Write-Host "FAIL    $file"
            $fail = $true
        }
    }
}
finally {
    Pop-Location
}

if ($fail) { exit 1 }
Write-Host "All repository checksums OK."
