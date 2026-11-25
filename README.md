# crash-fixes

![verify](https://github.com/guilhermeheats/crash-fixes/actions/workflows/verify.yml/badge.svg)
![license](https://img.shields.io/badge/license-MIT-blue.svg)

Launcher-agnostic technical fixes for **Crash Landing 1.1.3** (Minecraft 1.6.4 / Forge 9.11.1.965) with **Java 8**.

**Prism Launcher is not required.** The fixes install into the Minecraft **game directory** — the folder containing `mods/`, `config/`, `saves/` and `options.txt`. Use Prism, CurseForge, MultiMC, ATLauncher, GDLauncher, the vanilla launcher, or any other launcher that can run the pack.

This repository contains only fixes, scripts, documentation and checksums. It does **not** contain the Crash Landing modpack, its mods or its world. Install the official pack with your launcher, then apply these fixes.

## Why the name “crash-fixes”?

`crash-landing-fixes` could imply that this is an official Crash Landing project. It is not. `crash-fixes` is deliberately neutral:

- it is an informal, fan-made compatibility/integrity project;
- it is not affiliated with or endorsed by the Crash Landing authors, CurseForge, Mojang, Microsoft, or OptiFine;
- it does not redistribute the modpack or its assets.

## Fixes

1. **Startup crash** — `ConcurrentModificationException` in LaunchWrapper with Forge 1.6.4 + Java 8u20+.
   Fix: `legacyjavafixer-1.0.jar` (MinecraftForge, MIT).
2. **Death → new world crash** — ChickenChunks keeps the deleted world's save directory and throws `IOException` in `updateLoginTimes`.
   Fix: `clchunkfix-1.6.jar` resets ChickenChunks on server stop.
3. **Ruins writing to the old world** — stale `generatorMap` after a world switch.
   Fix: `clchunkfix-1.6.jar` clears the Ruins map on server stop.
4. **Frozen world after breaking a chest** — CodeChickenLib ticks a world that is missing from its static `worldMap`, throwing `NullPointerException` in `WorldExtensionManager.preTick`. The integrated server stops ticking, so mobs freeze and chests stop opening.
   Fix: `clchunkfix-1.6.jar` initializes the missing extension set (or installs a safe empty one) before the world tick.
5. **Chest/item desync and rollback** — Inventory Tweaks sends a click for a slot that no longer exists on the server (stale chest GUI), causing `IndexOutOfBoundsException` in `Container.clickSlot` and stopping the integrated server.
   Fix: `clchunkfix-1.6.jar` validates the click against the server container and closes the stale GUI instead of crashing.
6. **World freeze with many items on the ground** — HQM compares every pickup against every quest item and calls `OreDictionary.getOreID`, which scans the whole ore dictionary and stalls the server.
   Fix: `clchunkfix-1.6.jar` caches HQM's OreDictionary lookups per `ItemStack`.
7. **Dropped items invisible at distance** — the client culls `EntityItem` at 16 blocks because of its 0.25-block hitbox, even though the server tracks items up to 64 blocks.
   Fix: `clchunkfix-1.6.jar` raises the client item render distance to 64 blocks (plus a 1-block camera margin).
8. **Unloaded band at the edge with Far render distance** — the integrated server's default view distance is 10 chunks while the client renders Far (16), leaving a band of unloaded chunks at the edge.
   Fix: `clchunkfix-1.6.jar` raises the integrated-server view distance to 16 chunks on server start.
9. **CustomChestLoot ignoring entries** — broken multi-line `contents=` lists.
   Fix: `scripts/fix-customchestloot.py` / `.ps1`.
10. **Obsolete network noise** — update checks/radio timeouts.
   Fix: `scripts/cleanup-network-checks.py` / `.ps1`.
11. **Max-fidelity video profile** — `examples/options.txt`.

Details: [docs/FIXES.md](docs/FIXES.md).

## Requirements

- Minecraft **1.6.4** with **Forge 9.11.1.965**.
- **Crash Landing 1.1.3** installed by your launcher.
  - CurseForge project: `229330`
  - File: `CrashLanding-1.1.3-1.6.4.zip` (file ID `2235312`)
- **Java 8 64-bit**.
- Linux/macOS: `python3`.
- Windows: PowerShell 5.1+ (built into Windows 10/11).
- No world backup is included; the hardcore behavior is kept.

## Find your game directory

The installer needs the folder that directly contains:

```text
mods/
config/
saves/
options.txt
```

Examples (not requirements):

| Launcher | Typical game directory |
|---|---|
| Prism / MultiMC | `instances/<pack>/minecraft` |
| CurseForge App | the instance folder that contains `mods/` |
| ATLauncher / GDLauncher | the instance folder |
| Vanilla launcher | `%APPDATA%\.minecraft` (Windows), `~/.minecraft` (Linux), `~/Library/Application Support/minecraft` (macOS) |

If your launcher asks for a “game directory”, select this folder.

## Install

### Linux / macOS

```bash
./scripts/install.sh --game-dir "/path/to/game-dir"
```

Keep your current video options:

```bash
./scripts/install.sh --game-dir "/path/to/game-dir" --no-options
```

### Windows

```powershell
.\scripts\install.ps1 -GameDir "C:\path\to\game-dir"
```

Keep your current video options:

```powershell
.\scripts\install.ps1 -GameDir "C:\path\to\game-dir" -NoOptions
```

### Manual

Copy `mods/legacyjavafixer-1.0.jar` and `mods/clchunkfix-1.6.jar` into your `mods/` folder. Then run the CustomChestLoot and network-cleanup scripts against the game directory, and optionally copy `examples/options.txt` to `options.txt`.

## JVM arguments

The installer cannot edit every launcher's JVM settings, so set these in your launcher:

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

Use **Java 8 64-bit**. The exact menu varies by launcher: “Java/JVM arguments”, “Advanced options”, “Additional Java parameters”, or a profile's JVM arguments.

Optional: add `-Dclchunkfix.itemRenderDistance=48` to lower the dropped-item render distance (default 64, range 16–64; the client cutoff is the value plus a 1-block camera margin).

For **Far + the 16-chunk server view distance**, use a **5–6 GB heap** (`-Xms5120m -Xmx6144m` or 6144 MB in the launcher) and close heavy background apps. The recorded 4 GB profile is the baseline; the real session was using about 4.25 GB RSS with a 4 GB heap, which is tight for Far chunk loading.

## Verify

```bash
./scripts/verify-game-dir.sh --game-dir "/path/to/game-dir"
```

```powershell
.\scripts\verify-game-dir.ps1 -GameDir "C:\path\to\game-dir"
```

It checks:

- `mods/` and `config/`;
- the two required fix jars;
- all 63 mod files against `mods.sha256`;
- extra/missing mods;
- `options.txt` against the reference profile;
- if a runtime log exists (`ForgeModLoader-client-0.log` on 1.6.4, or `logs/latest.log`), Minecraft 1.6.4, Forge 9.11.1.965 and Java 8.

Allow intentional extra mods:

```bash
./scripts/verify-game-dir.sh --game-dir "..." --allow-extra
```

```powershell
.\scripts\verify-game-dir.ps1 -GameDir "..." -AllowExtra
```

## Testing status

| Platform | Status |
|---|---|
| Linux | Installer/verifier tested against a real Crash Landing game directory; game launch and death → new world cycles tested via Prism as one launcher, with no Prism metadata required by the scripts. Prism, MultiMC, ATLauncher, GDLauncher and the Technic installer were also exercised at runtime level. |
| Windows | PowerShell 5.1 installer/verifier PASS in a Windows 10 LTSC VM; full Minecraft 1.6.4 + Forge 9.11.1.965 launch reached the main menu with `LegacyJavaFixer` and CustomChestLoot. Prism, MultiMC, ATLauncher, GDLauncher and CurseForge were exercised at runtime level. Launcher game launch needs a Microsoft account owning Minecraft; the VM has none. |
| macOS | Bash installer/verifier and build tested by GitHub Actions; no real Mac available for a full game launch |

The CI matrix runs on Ubuntu, Windows and macOS and includes installer smoke tests. The Windows full game launch used a test game directory and the same Forge classpath directly; current launchers require a Microsoft account to start the game. See [docs/TESTING.md](docs/TESTING.md) for the launcher matrix and evidence. Known benign log messages, fixed issues and open pack-asset issues are listed in [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md).

## Performance / OptiFine

The recorded profile is maximum fidelity. Java is pinned to 8u202 with 4 GB and G1GC.

**Do not install OptiFine 1.6.4 for Crash Landing.** The jar is an installer/tweaker, not a normal Forge mod; placing it in `mods` is ignored. Patching the game jar or using OptiFineFML is unofficial, conflicts with ChickenChunks/Tinkers, and has no guaranteed FPS gain. See [docs/PERFORMANCE.md](docs/PERFORMANCE.md).

No backup, AromaBackup, OptiFine, performance mods, QoL mods, mod updates or Forge updates are included. The goal is fidelity to the hardcore pack.

## Credits

See [CREDITS.md](CREDITS.md) for the full credits:

- Crash Landing pack team;
- Minecraft/Mojang/Microsoft;
- Forge/FML contributors;
- LegacyJavaFixer;
- ChickenChunks, Ruins, CustomChestLoot and every mod in the pack;
- OptiFine (credited, not included).

## Legal

- **crash-fixes** code: MIT (see `LICENSE`).
- **LegacyJavaFixer**: MIT, MinecraftForge/LexManos.
- **Crash Landing**: All Rights Reserved. This repository does not redistribute the pack, its mods or its world.
- **Minecraft/Forge**: not redistributed.
- **OptiFine**: not included; its license prohibits modifying/redistributing it.

See [docs/LEGAL.md](docs/LEGAL.md) and [THIRD_PARTY.md](THIRD_PARTY.md).

## Repository layout

```
mods/                  clchunkfix-1.6.jar, legacyjavafixer-1.0.jar
src/                   clchunkfix source + mcmod.info
examples/options.txt   max-fidelity video profile
mods.sha256            hashes of the 63 mod files in a Crash Landing 1.1.3 instance
scripts/               install/verify/build/maintenance scripts (bash + PowerShell + Python)
docs/                  install, fixes, verification, performance, testing, known issues, legal
pack/PROVENANCE.md     official pack URL and SHA-256 (no pack file)
.github/workflows/     CI matrix and release workflow
checksums.txt          repository artifact checksums
CREDITS.md             full credits
```
