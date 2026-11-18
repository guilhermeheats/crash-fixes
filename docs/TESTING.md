# Testing status and manual checklist

## Matrix

| Test | Linux | Windows | macOS |
|---|---|---|---|
| Build `clchunkfix` (Java 7 bytecode) | Yes | GitHub Actions | GitHub Actions |
| Repository checksums | Yes | GitHub Actions | GitHub Actions |
| Script syntax / Python compile | Yes | PowerShell parser via Actions | Bash/Python via Actions |
| Installer smoke test (generic game dir) | Yes | GitHub Actions | GitHub Actions |
| Full game launch | Yes | **No real machine** | **No real machine** |
| Death → new world cycle | Yes | **No real machine** | **No real machine** |
| CustomChestLoot load | Yes | **No real machine** | **No real machine** |
| Max video profile | Yes | Same file, not launched | Same file, not launched |

The development machine available for this project is Linux only. Windows and macOS are covered by CI for build/checksum/script/installer checks, but **not by an actual Minecraft launch**. This limitation is documented and not hidden.

## Linux evidence

- Install and verify against a real Crash Landing **game directory** without launcher metadata.
- Launch through Prism as one launcher; the fix scripts do not read Prism files.
- Death → new world cycles complete without the ChickenChunks/Ruins crash.
- `[CLWorldFix]` lines appear on `FMLServerStopped`.
- CustomChestLoot loads without `Invalid number of arguments!`.
- Maximum video profile loads.
- `verify-game-dir.sh` reports `Integrity check: PASS`.
- No new crash report after the fixes.

## Manual checklist (any launcher)

1. Install Minecraft 1.6.4 + Forge 9.11.1.965 and Crash Landing 1.1.3 with your launcher.
2. Locate the game directory (contains `mods/`, `config/`, `saves/`).
3. Run:
   - Linux/macOS: `./scripts/install.sh --game-dir "<dir>"`
   - Windows: `.\scripts\install.ps1 -GameDir "<dir>"`
4. Set Java 8 and the JVM arguments from `docs/INSTALL.md`.
5. Launch the pack.
6. Confirm the main menu and `LegacyJavaFixer` in `logs/latest.log`.
7. Create/enter a world, quit to title, re-enter; check `[CLWorldFix]`.
8. If testing hardcore: die, create the next world, confirm no `loginTimes.dat`/`RuinsPositionsFile.txt` crash.
9. Run `verify-game-dir.sh`/`.ps1`.
10. Check `crash-reports/` for new files.

## CI workflows

- `.github/workflows/verify.yml`: matrix Ubuntu/Windows/macOS; checksums, script parsing, build, class version, generic-game-dir installer smoke tests.
- `.github/workflows/release.yml`: release on `v*` tags with fix jars, checksums, manifest and docs. It never uploads the modpack.

## Known benign log messages

- CoFH/Thermal Expansion version-check `403` (two lines).
- EnderIO MineTweaker item 8790 (EnderIO is disabled in the pack).
- `MapWriter` missing in the template world.
- `EnviroMine Unable to get EnviroTracker for GUI`.
- Missing textures in old mods.
- `missing pack.mcmeta` warnings.
