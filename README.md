# crash-fixes

![verify](https://github.com/guilhermeheats/crash-fixes/actions/workflows/verify.yml/badge.svg)
![license](https://img.shields.io/badge/license-MIT-blue.svg)

Unofficial technical fixes for running **Crash Landing 1.1.3** (Minecraft 1.6.4 / Forge 9.11.1.965) on **Prism Launcher** with **Java 8**.

This repository contains **only fixes, scripts, documentation and checksums**. It does **not** contain the Crash Landing modpack, its mods, or its world. Install the official pack from CurseForge and then apply these fixes.

## Why the name “crash-fixes”?

`crash-landing-fixes` could imply that this is an official Crash Landing project. It is not. `crash-fixes` is deliberately neutral:

- it is a **fan-made compatibility/integrity project**;
- it is **not affiliated with or endorsed by** the Crash Landing authors, CurseForge, Mojang, Microsoft, or OptiFine;
- it does not redistribute the modpack or its assets.

## What it fixes

1. **Startup crash** — `ConcurrentModificationException` in LaunchWrapper when Forge 1.6.4 runs on Java 8u20+.
   Fix: `legacyjavafixer-1.0.jar` (MinecraftForge, MIT).

2. **Death → new world crash** — ChickenChunks keeps the deleted world's save directory and throws `IOException: No such file or directory` in `updateLoginTimes`.
   Fix: `clchunkfix-1.1.jar` calls `ChunkLoaderManager.serverShutdown()` on `FMLServerStopped`.

3. **Ruins writing to the old world** — the Ruins `generatorMap` survives a world switch and points to the deleted world.
   Fix: `clchunkfix-1.1.jar` clears the Ruins `generatorMap` on `FMLServerStopped`.

4. **CustomChestLoot ignoring entries** — `contents=` lists wrapped across multiple lines are not valid Java Properties; the mod logs `Invalid number of arguments!`.
   Fix: `scripts/fix-customchestloot.py` / `.ps1` join only the continuation lines, preserving IDs and weights.

5. **Obsolete network noise** — update checks and OpenBlocks radio endpoints time out on a 2015 pack.
   Fix: `scripts/cleanup-network-checks.py` / `.ps1` disable only those checks; gameplay is untouched.

6. **Max-fidelity video profile** — `examples/options.txt` records Far/Fancy/Maximum smooth lighting/clouds/particles/VSync/Advanced OpenGL.

## Requirements

- Prism Launcher 11.x (Flatpak or native).
- Java 8 64-bit. Let Prism download Java 8 if needed.
- The official **Crash Landing 1.1.3** instance installed in Prism.
  - CurseForge project: `229330`
  - File: `CrashLanding-1.1.3-1.6.4.zip` (file ID `2235312`)
- Linux/macOS: `python3`.
- Windows: PowerShell 5.1+ (built into Windows 10/11).
- No world backup is included or performed: the pack is intentionally hardcore.

## Install

### Linux / macOS

The script auto-detects the usual Prism instance paths. You can also pass `INSTANCE`.

```bash
INSTANCE="$HOME/.local/share/PrismLauncher/instances/Crash Landing" \
  ./scripts/install.sh
```

Flatpak default:

```bash
INSTANCE="$HOME/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances/Crash Landing" \
  ./scripts/install.sh
```

macOS:

```bash
INSTANCE="$HOME/Library/Application Support/PrismLauncher/instances/Crash Landing" \
  ./scripts/install.sh
```

To keep your current `options.txt`:

```bash
APPLY_OPTIONS=0 INSTANCE="..." ./scripts/install.sh
```

### Windows

```powershell
.\scripts\install.ps1 -Instance "C:\Users\<you>\AppData\Roaming\PrismLauncher\instances\Crash Landing"
```

To keep your current `options.txt`:

```powershell
.\scripts\install.ps1 -Instance "..." -NoOptions
```

### Manual install

Copy:

- `mods/legacyjavafixer-1.0.jar`
- `mods/clchunkfix-1.1.jar`

into `minecraft/mods`, then apply the configuration fixes with the Python/PowerShell scripts and optionally copy `examples/options.txt` to `minecraft/options.txt`.

## Verify

Repository artifacts:

```bash
./scripts/verify.sh          # Linux/macOS
.\scripts\verify.ps1         # Windows
```

Installed instance:

```bash
INSTANCE="..." ./scripts/verify-instance.sh
.\scripts\verify-instance.ps1 -Instance "C:\...\Crash Landing"
```

`verify-instance` checks:

- Minecraft 1.6.4, Forge 9.11.1.965, LWJGL 2.9.4;
- `legacyjavafixer` and `clchunkfix`;
- all 63 mod files against `mods.sha256`;
- extra/missing mods (strict by default);
- Java 8 and the 4 GB + G1GC profile;
- `options.txt` against the recorded max-fidelity profile.

Allow intentional extra mods:

```bash
STRICT_EXTRA=0 ./scripts/verify-instance.sh
```

```powershell
.\scripts\verify-instance.ps1 -Instance "..." -AllowExtra
```

## Testing status

| Platform | Status |
|---|---|
| Linux | Fully tested: launch to menu, death → new world cycles, CustomChestLoot, max video profile, integrity checks |
| Windows | PowerShell installer/verifier and build are exercised by GitHub Actions; **not** launched on a real Windows machine |
| macOS | Bash installer path detection and CI checks; **not** launched on a real Mac |

The GitHub Actions matrix validates builds, script syntax, checksums and manifests on Linux, Windows and macOS. A real game launch on Windows/macOS still needs a physical machine or VM; see [docs/TESTING.md](docs/TESTING.md).

## Performance / OptiFine

The repository keeps the **max-fidelity** video profile. Java is pinned to 8u202 with 4 GB and G1GC.

**Do not install OptiFine 1.6.4 for Crash Landing.** The 1.6.4 OptiFine jar is an installer/tweaker, not a normal Forge mod; placing it in `mods` is ignored. Patching the game jar or using OptiFineFML is unofficial, still conflicts with ChickenChunks/Tinkers, and has no guaranteed FPS gain. See [docs/PERFORMANCE.md](docs/PERFORMANCE.md).

No backup, AromaBackup, QoL mods, mod updates, or Forge updates are included: the goal is fidelity to the hardcore pack.

## Legal / licenses

- **crash-fixes** code: MIT (see `LICENSE`).
- **LegacyJavaFixer**: MIT, MinecraftForge/LexManos. Included as `mods/legacyjavafixer-1.0.jar`.
- **Crash Landing**: All Rights Reserved by its authors. This repository does **not** redistribute the pack, its mods, or its world.
- **Minecraft/Forge**: not redistributed.
- **OptiFine**: not included; its license prohibits modifying/redistributing it.

See [docs/LEGAL.md](docs/LEGAL.md) and [THIRD_PARTY.md](THIRD_PARTY.md).

## Repository layout

```
mods/                  clchunkfix-1.1.jar, legacyjavafixer-1.0.jar
src/                   clchunkfix source + mcmod.info
examples/options.txt   max-fidelity video profile
mods.sha256            hashes of the 63 mod files in a Crash Landing 1.1.3 instance
scripts/               install/verify/build/maintenance scripts (bash + PowerShell + Python)
docs/                  install, fixes, verification, performance, testing, legal
pack/PROVENANCE.md     official pack URL and SHA-256 (no pack file)
.github/workflows/     CI matrix and release workflow
checksums.txt          repository artifact checksums
```
