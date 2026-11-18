# Installation

## Prerequisites

1. Install **Minecraft 1.6.4 + Forge 9.11.1.965** with any launcher.
2. Install **Crash Landing 1.1.3** with that launcher:
   - CurseForge project ID: `229330`
   - file: `CrashLanding-1.1.3-1.6.4.zip`
   - file ID: `2235312`
3. Use **Java 8 64-bit**.
4. Download or clone this repository.

No specific launcher is required. Prism, CurseForge, MultiMC, ATLauncher, GDLauncher, the vanilla launcher and others are all fine, as long as the pack runs.

## Game directory

The installer targets the folder that directly contains:

```
mods/
config/
saves/
options.txt
```

Examples:

| Launcher | Typical game directory |
|---|---|
| Prism / MultiMC | `instances/<pack>/minecraft` |
| CurseForge App | the instance folder that contains `mods/` |
| ATLauncher / GDLauncher | the instance folder |
| Vanilla launcher | `%APPDATA%\.minecraft`, `~/.minecraft`, `~/Library/Application Support/minecraft` |

If the launcher has a “game directory” or “instance folder” setting, that is the folder to use. The scripts do **not** read `instance.cfg` or `mmc-pack.json`.

These fixes do not bypass launcher authentication. Current Prism, MultiMC,
CurseForge, ATLauncher and GDLauncher builds require a Microsoft account that
owns Minecraft before they will launch the game or add an offline profile.
Legacy GDLauncher 1.1.30 can remain on `Loading...`; that is a launcher issue,
not a fix failure.

## Linux / macOS

```bash
./scripts/install.sh --game-dir "/path/to/game-dir"
```

Keep the current video settings:

```bash
./scripts/install.sh --game-dir "/path/to/game-dir" --no-options
```

The installer:

1. copies `legacyjavafixer-1.0.jar` and `clchunkfix-1.1.jar` to `mods/`;
2. backs up and applies `examples/options.txt` (unless `--no-options`);
3. fixes the CustomChestLoot configs;
4. disables obsolete update/radio checks;
5. prints the recommended JVM arguments.

It does not modify launcher-specific files.

## Windows

PowerShell 5.1+ is built into Windows 10/11.

```powershell
.\scripts\install.ps1 -GameDir "C:\path\to\game-dir"
```

Keep the current video settings:

```powershell
.\scripts\install.ps1 -GameDir "C:\path\to\game-dir" -NoOptions
```

## Manual installation

Copy into `mods/`:

- `mods/legacyjavafixer-1.0.jar`
- `mods/clchunkfix-1.1.jar`

Then apply config fixes:

```bash
python3 scripts/fix-customchestloot.py "<game-dir>/config/CustomChestLoot"
python3 scripts/cleanup-network-checks.py "<game-dir>"
```

Windows:

```powershell
.\scripts\fix-customchestloot.ps1 -ConfigDir "<game-dir>\config\CustomChestLoot"
.\scripts\cleanup-network-checks.ps1 -MinecraftDir "<game-dir>"
```

Optionally copy `examples/options.txt` to `<game-dir>/options.txt` after backing up the old file.

## JVM arguments

Set these in the launcher's Java/JVM arguments field:

```text
-Xms4096m -Xmx4096m
-XX:+UseG1GC
-XX:+UnlockExperimentalVMOptions
-XX:G1NewSizePercent=20
-XX:G1ReservePercent=20
-XX:MaxGCPauseMillis=50
-XX:G1HeapRegionSize=32M
-XX:+DisableExplicitGC
-XX:+ParallelRefProcEnabled
-XX:+PerfDisableSharedMem
```

Menu names vary:

- Prism/MultiMC: Instance Settings → Java → JVM arguments
- CurseForge App: instance settings/Java or profile arguments
- ATLauncher: Settings → Java/Memory
- GDLauncher: instance settings
- Vanilla launcher: profile → More Options → JVM arguments

The installer prints the same block after installation.

## After installation

1. Restart the launcher.
2. Select Java 8 64-bit.
3. Launch the pack.
4. Verify with:

```bash
./scripts/verify-game-dir.sh --game-dir "<game-dir>"
```

```powershell
.\scripts\verify-game-dir.ps1 -GameDir "C:\path\to\game-dir"
```

## Pack updates

If the launcher updates/reinstalls the pack, re-run the installer and confirm both jars are still in `mods/`. Pack updates can overwrite `config/` and `options.txt`.

## No backup

This project does not create world backups. Crash Landing's hardcore world deletion is intentional. Backup is a separate decision and is not included.
