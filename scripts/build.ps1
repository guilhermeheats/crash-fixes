#!/usr/bin/env pwsh
param(
    [string]$ForgeJar = "",
    [string]$EcjJar = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Build = Join-Path $Root "build"
$Classes = Join-Path $Build "classes"
$Stage = Join-Path $Build "jar"
$Jar = Join-Path $Build "clchunkfix-1.1.jar"

$forgeUrl = "https://maven.minecraftforge.net/net/minecraftforge/forge/1.6.4-9.11.1.965/forge-1.6.4-9.11.1.965-universal.jar"
$ecjUrl = "https://repo1.maven.org/maven2/org/eclipse/jdt/ecj/3.33.0/ecj-3.33.0.jar"

New-Item -ItemType Directory -Force -Path $Build, $Classes, $Stage | Out-Null
Remove-Item -LiteralPath $Classes -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $Stage -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $Classes, $Stage | Out-Null

if ([string]::IsNullOrWhiteSpace($ForgeJar)) {
    $ForgeJar = Join-Path $Build "forge-1.6.4-9.11.1.965-universal.jar"
    if (-not (Test-Path -LiteralPath $ForgeJar)) {
        Write-Host "Downloading Forge universal jar..."
        Invoke-WebRequest -Uri $forgeUrl -OutFile $ForgeJar -UseBasicParsing
    }
}
if (-not (Test-Path -LiteralPath $ForgeJar)) { throw "Forge jar not found: $ForgeJar" }

if ([string]::IsNullOrWhiteSpace($EcjJar)) {
    $EcjJar = Join-Path $Build "ecj-3.33.0.jar"
    if (-not (Test-Path -LiteralPath $EcjJar)) {
        Write-Host "Downloading Eclipse Compiler for Java..."
        Invoke-WebRequest -Uri $ecjUrl -OutFile $EcjJar -UseBasicParsing
    }
}

Write-Host "Compiling (Java 7 bytecode for FML 1.6.4/ASM 4.1)..."
& java -jar $EcjJar -source 1.7 -target 1.7 -proc:none -cp $ForgeJar -d $Classes (Join-Path $Root "src\clchunkfix\ChunkFix.java")
if ($LASTEXITCODE -ne 0) { throw "ECJ compilation failed" }

Copy-Item -LiteralPath (Join-Path $Root "src\mcmod.info") -Destination $Stage -Force
Copy-Item -Path (Join-Path $Classes "*") -Destination $Stage -Recurse -Force

if (Get-Command jar -ErrorAction SilentlyContinue) {
    & jar cf $Jar -C $Stage .
    if ($LASTEXITCODE -ne 0) { throw "jar packaging failed" }
}
else {
    Compress-Archive -Path (Join-Path $Stage "*") -DestinationPath $Jar -Force
}

$classFile = Join-Path $Classes "clchunkfix\ChunkFix.class"
$bytes = [System.IO.File]::ReadAllBytes($classFile)
$major = ([int]$bytes[6] -shl 8) -bor [int]$bytes[7]
if ($major -ne 51) { throw "Unexpected class file version: $major (expected 51/Java 7)" }

Copy-Item -LiteralPath $Jar -Destination (Join-Path $Root "mods\clchunkfix-1.1.jar") -Force
Write-Host "Built: $(Join-Path $Root 'mods\clchunkfix-1.1.jar')"
Write-Host "Class major version: $major"
Get-FileHash -LiteralPath (Join-Path $Root "mods\clchunkfix-1.1.jar") -Algorithm SHA256
