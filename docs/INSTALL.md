# Installation

## Prerequisites

1. Install **Prism Launcher 11.x**.
2. Install **Crash Landing 1.1.3** from CurseForge in Prism:
   - project ID: `229330`
   - file: `CrashLanding-1.1.3-1.6.4.zip`
   - file ID: `2235312`
3. Let Prism download/select **Java 8 64-bit** for the instance.
4. Download or clone this repository.

Do not install OptiFine. Do not update Forge.

## Prism instance paths

Use these paths to find the instance directory:

| OS | Typical path |
|---|---|
| Linux Flatpak | `~/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances/Crash Landing` |
| Linux native | `~/.local/share/PrismLauncher/instances/Crash Landing` |
| macOS | `~/Library/Application Support/PrismLauncher/instances/Crash Landing` |
| Windows | `%APPDATA%\PrismLauncher\instances\Crash Landing` |

The instance directory must contain `instance.cfg`, `mmc-pack.json` and `minecraft/`.

## Linux / macOS

The installer detects the common Prism paths. If it cannot find the instance, pass `INSTANCE`.

```bash
INSTANCE="$HOME/.local/share/PrismLauncher/instances/Crash Landing" \
  ./scripts/install.sh
```

Flatpak:

```bash
INSTANCE="$HOME/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances/Crash Landing" \
  ./scripts/install.sh
```

macOS:

```bash
INSTANCE="$HOME/Library/Application Support/PrismLauncher/instances/Crash Landing" \
  ./scripts/install.sh
```

The script:

1. copies `legacyjavafixer-1.0.jar` and `clchunkfix-1.1.jar` to `minecraft/mods`;
2. sets 4 GB + G1GC in `instance.cfg`;
3. backs up and applies `examples/options.txt` (max fidelity);
4. fixes CustomChestLoot and disables obsolete network checks.

Preserve your current video options:

```bash
APPLY_OPTIONS=0 INSTANCE="..." ./scripts/install.sh
```

## Windows

PowerShell 5.1+ is built into Windows 10/11.

```powershell
.\scripts\install.ps1 -Instance "C:\Users\<you>\AppData\Roaming\PrismLauncher\instances\Crash Landing"
```

Preserve your current video options:

```powershell
.\scripts\install.ps1 -Instance "..." -NoOptions
```

The PowerShell script does the same steps as the bash installer without requiring Python.

## Manual installation

Copy these files into `minecraft/mods`:

- `mods/legacyjavafixer-1.0.jar`
- `mods/clchunkfix-1.1.jar`

Then apply the configuration fixes manually:

```bash
python3 scripts/fix-customchestloot.py "<instance>/minecraft/config/CustomChestLoot"
python3 scripts/cleanup-network-checks.py "<instance>/minecraft"
```

Windows equivalents:

```powershell
.\scripts\fix-customchestloot.ps1 -ConfigDir "<instance>\minecraft\config\CustomChestLoot"
.\scripts\cleanup-network-checks.ps1 -MinecraftDir "<instance>\minecraft"
```

Optionally copy `examples/options.txt` to `minecraft/options.txt` (back up the old file first).

## After installation

1. Restart Prism.
2. Launch the instance.
3. Confirm Java 8 in **Instance Settings → Java**.
4. Check the log for `LegacyJavaFixer` and `[CLWorldFix]` lines after leaving a world.
5. Run `scripts/verify-instance.sh` / `.ps1` for integrity.

## Updating the pack

If Prism updates/reinstalls the pack, re-run the installer and confirm both jars are still present. Pack updates can overwrite `config/` and `options.txt`.

## No backup

This project does not create world backups. Crash Landing's hardcore world deletion is intentional. If you want backups, that is a separate decision and is not included here.
