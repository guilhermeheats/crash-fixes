#!/usr/bin/env pwsh
param(
    [string]$Destination = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Destination)) {
    $Destination = Join-Path $Root "pack\CrashLanding-1.1.3-1.6.4.zip"
}
$url = "https://mediafilez.forgecdn.net/files/2235/312/CrashLanding-1.1.3-1.6.4.zip"
$sha256 = "42996d8105bcea94460ca334f848343ea2f3e2dd47d2597d159418dd93e5071b"

$dir = Split-Path -Parent $Destination
if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

if (-not (Test-Path -LiteralPath $Destination)) {
    Write-Host "Downloading Crash Landing 1.1.3..."
    Invoke-WebRequest -Uri $url -OutFile $Destination -UseBasicParsing
}

$actual = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash.ToLower()
if ($actual -ne $sha256) { throw "SHA-256 mismatch: $actual" }
Write-Host "Pack file: $Destination"
Write-Host "Install it in Prism, then run scripts\install.ps1 on the instance."
