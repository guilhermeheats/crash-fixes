# Testing status and cross-platform checklist

## Matrix

| Test | Linux | Windows | macOS |
|---|---|---|---|
| Build `clchunkfix` (Java 7 bytecode) | Yes | GitHub Actions | GitHub Actions |
| Repository checksums | Yes | GitHub Actions | GitHub Actions |
| Script syntax / Python compile | Yes | PowerShell parser via Actions | Bash/Python via Actions |
| Installer on a fixture | Yes | CI smoke test | CI smoke test |
| Full game launch | Yes | **No real machine** | **No real machine** |
| Death → new world cycle | Yes (Crash Landing 4 → 5) | **No real machine** | **No real machine** |
| CustomChestLoot load | Yes | **No real machine** | **No real machine** |
| Max video profile | Yes | Same file, not launched | Same file, not launched |

The test machine available for this project is Linux only. Windows and macOS are covered by CI for build/checksum/script checks, but **not by an actual Minecraft launch**. This limitation is intentional and documented.

## Linux test evidence

Verified in a real Prism instance:

- launch reaches the main menu with 102 mods active;
- `LegacyJavaFixer` replaces the broken tweaker;
- death → new world cycles complete without the ChickenChunks/Ruins crash;
- `[CLWorldFix]` lines appear on `FMLServerStopped`;
- CustomChestLoot loads with no `Invalid number of arguments!`;
- maximum video profile loads;
- `verify-instance.sh` reports `Integrity check: PASS`;
- no new crash report after the fixes.

## Windows/macOS manual checklist

On a real Windows or macOS machine:

1. Install Prism Launcher and Java 8.
2. Install Crash Landing 1.1.3 from CurseForge (project `229330`, file `2235312`).
3. Run:
   - Windows: `.\scripts\install.ps1 -Instance "..."`
   - macOS: `INSTANCE="..." ./scripts/install.sh`
4. Restart Prism and launch the instance.
5. Confirm Java 8 in Instance Settings.
6. Confirm the main menu loads and the log shows `LegacyJavaFixer`.
7. Create/enter a world, then quit to title and re-enter. Check `[CLWorldFix]` lines.
8. If testing hardcore: die, create the next world, and confirm no `loginTimes.dat`/`RuinsPositionsFile.txt` crash.
9. Run `verify-instance.ps1`/`verify-instance.sh`.
10. Check `minecraft/crash-reports` for new files.

## CI workflows

- `.github/workflows/verify.yml`: matrix on Ubuntu/Windows/macOS; checksums, script parsing, build, class version.
- `.github/workflows/release.yml`: builds `clchunkfix` and creates a GitHub release with the fix jars, checksums and manifest. It never uploads the modpack.

## Known benign log messages

- CoFH/Thermal Expansion version-check `403` (two lines).
- EnderIO MineTweaker item 8790 (EnderIO is disabled in the pack).
- `MapWriter` missing in the template world.
- `EnviroMine Unable to get EnviroTracker for GUI`.
- Missing textures in old mods.
- `missing pack.mcmeta` warnings.
