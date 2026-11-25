#!/usr/bin/env pwsh
param(
    [string]$ForgeJar = "",
    [string]$EcjJar = "",
    [string]$AsmJar = "",
    [string]$LaunchwrapperJar = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Build = Join-Path $Root "build"
$Classes = Join-Path $Build "classes"
$Stage = Join-Path $Build "jar"
$Jar = Join-Path $Build "clchunkfix-1.8.jar"

$forgeUrl = "https://maven.minecraftforge.net/net/minecraftforge/forge/1.6.4-9.11.1.965/forge-1.6.4-9.11.1.965-universal.jar"
$ecjUrl = "https://repo1.maven.org/maven2/org/eclipse/jdt/ecj/3.33.0/ecj-3.33.0.jar"
$asmUrl = "https://repo1.maven.org/maven2/org/ow2/asm/asm-all/4.1/asm-all-4.1.jar"
$launchwrapperUrl = "https://libraries.minecraft.net/net/minecraft/launchwrapper/1.8/launchwrapper-1.8.jar"

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
if ([string]::IsNullOrWhiteSpace($AsmJar)) {
    $AsmJar = Join-Path $Build "asm-all-4.1.jar"
    if (-not (Test-Path -LiteralPath $AsmJar)) {
        Write-Host "Downloading ASM 4.1..."
        Invoke-WebRequest -Uri $asmUrl -OutFile $AsmJar -UseBasicParsing
    }
}
if ([string]::IsNullOrWhiteSpace($LaunchwrapperJar)) {
    $LaunchwrapperJar = Join-Path $Build "launchwrapper-1.8.jar"
    if (-not (Test-Path -LiteralPath $LaunchwrapperJar)) {
        Write-Host "Downloading LaunchWrapper 1.8..."
        Invoke-WebRequest -Uri $launchwrapperUrl -OutFile $LaunchwrapperJar -UseBasicParsing
    }
}

$Sources = @(
    (Join-Path $Root "src\clchunkfix\ChunkFix.java"),
    (Join-Path $Root "src\clchunkfix\core\ChunkFixCorePlugin.java"),
    (Join-Path $Root "src\clchunkfix\core\WorldExtensionTransformer.java"),
    (Join-Path $Root "src\clchunkfix\core\WorldExtensionHooks.java"),
    (Join-Path $Root "src\clchunkfix\core\InvTweaksTransformer.java"),
    (Join-Path $Root "src\clchunkfix\core\InvTweaksHooks.java"),
    (Join-Path $Root "src\clchunkfix\core\HqmTransformer.java"),
    (Join-Path $Root "src\clchunkfix\core\HqmHooks.java"),
    (Join-Path $Root "src\clchunkfix\core\ItemRenderTransformer.java")
)

Write-Host "Compiling (Java 7 bytecode for FML 1.6.4/ASM 4.1)..."
& java -jar $EcjJar -source 1.7 -target 1.7 -proc:none `
    -cp "$ForgeJar;$AsmJar;$LaunchwrapperJar" `
    -d $Classes $Sources
if ($LASTEXITCODE -ne 0) { throw "ECJ compilation failed" }

Copy-Item -LiteralPath (Join-Path $Root "src\mcmod.info") -Destination $Stage -Force
Copy-Item -Path (Join-Path $Classes "*") -Destination $Stage -Recurse -Force
New-Item -ItemType Directory -Force -Path (Join-Path $Stage "META-INF") | Out-Null
Set-Content -LiteralPath (Join-Path $Stage "META-INF\MANIFEST.MF") -Encoding ASCII -Value @(
    "Manifest-Version: 1.0",
    "FMLCorePlugin: clchunkfix.core.ChunkFixCorePlugin",
    "FMLCorePluginContainsFMLMod: true"
)

if (Get-Command jar -ErrorAction SilentlyContinue) {
    & jar cf $Jar -C $Stage .
    if ($LASTEXITCODE -ne 0) { throw "jar packaging failed" }
}
else {
    Compress-Archive -Path (Join-Path $Stage "*") -DestinationPath $Jar -Force
}

$classFiles = @(
    (Join-Path $Classes "clchunkfix\ChunkFix.class"),
    (Join-Path $Classes "clchunkfix\core\WorldExtensionTransformer.class"),
    (Join-Path $Classes "clchunkfix\core\WorldExtensionHooks.class"),
    (Join-Path $Classes "clchunkfix\core\ChunkFixCorePlugin.class"),
    (Join-Path $Classes "clchunkfix\core\InvTweaksTransformer.class"),
    (Join-Path $Classes "clchunkfix\core\InvTweaksHooks.class"),
    (Join-Path $Classes "clchunkfix\core\HqmTransformer.class"),
    (Join-Path $Classes "clchunkfix\core\HqmHooks.class"),
    (Join-Path $Classes "clchunkfix\core\ItemRenderTransformer.class")
)
foreach ($classFile in $classFiles) {
    $bytes = [System.IO.File]::ReadAllBytes($classFile)
    $major = ([int]$bytes[6] -shl 8) -bor [int]$bytes[7]
    if ($major -ne 51) { throw "Unexpected class file version in $classFile : $major (expected 51/Java 7)" }
}

Remove-Item -LiteralPath (Join-Path $Root "mods\clchunkfix-1.0.jar") -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $Root "mods\clchunkfix-1.1.jar") -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $Root "mods\clchunkfix-1.2.jar") -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $Root "mods\clchunkfix-1.3.jar") -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $Root "mods\clchunkfix-1.4.jar") -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $Root "mods\clchunkfix-1.5.jar") -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $Root "mods\clchunkfix-1.6.jar") -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $Root "mods\clchunkfix-1.7.jar") -Force -ErrorAction SilentlyContinue
Copy-Item -LiteralPath $Jar -Destination (Join-Path $Root "mods\clchunkfix-1.8.jar") -Force
Write-Host "Built: $(Join-Path $Root 'mods\clchunkfix-1.8.jar')"
Write-Host "Class major version: 51"
Get-FileHash -LiteralPath (Join-Path $Root "mods\clchunkfix-1.8.jar") -Algorithm SHA256
