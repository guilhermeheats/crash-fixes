#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigDir
)

$ErrorActionPreference = "Stop"
$changedFiles = @()

Get-ChildItem -LiteralPath $ConfigDir -Recurse -File -Filter "*.txt" | ForEach-Object {
    $path = $_.FullName
    $lines = [System.IO.File]::ReadAllLines($path)
    $out = [System.Collections.Generic.List[string]]::new()
    $changed = $false
    $i = 0

    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        if ($line.StartsWith("contents=")) {
            $parts = [System.Collections.Generic.List[string]]::new()
            $parts.Add($line)
            $i++
            while ($i -lt $lines.Count) {
                $next = $lines[$i]
                if ([string]::IsNullOrWhiteSpace($next) -or
                    $next.Contains("=") -or
                    $next.TrimStart().StartsWith("#")) {
                    break
                }
                $parts.Add($next.Trim())
                $i++
            }
            $joined = -join $parts
            if ($joined -ne $line) { $changed = $true }
            $out.Add($joined)
        }
        else {
            $out.Add($line)
            $i++
        }
    }

    if ($changed) {
        [System.IO.File]::WriteAllLines($path, $out, [System.Text.UTF8Encoding]::new($false))
        $changedFiles += $path
    }
}

if ($changedFiles.Count -eq 0) {
    Write-Host "CustomChestLoot configs already OK."
}
else {
    Write-Host "Fixed CustomChestLoot configs:"
    $changedFiles | ForEach-Object { Write-Host "  $_" }
}
