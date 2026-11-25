# Testing status and manual checklist

Last validation: **2026-11-18**.

## Result summary

The launcher-agnostic installers and verifiers pass on Linux and Windows. The
1.6.4 + Forge game directory reaches the Minecraft main menu on both systems
with `LegacyJavaFixer` and CustomChestLoot active.

The remaining limitation is **launcher game launch**: current mainstream
launchers require a Microsoft account that owns Minecraft. The Windows test VM
has no such account. Prism 11 and MultiMC refuse to add an offline account
without an owning Microsoft account, and ATLauncher, CurseForge and GDLauncher
also require a login. The Windows game launch below was therefore started with
the same Forge 1.6.4 classpath directly, using Java 8, to validate the game and
the fixes without credentials.

## CodeChickenLib tick-guard validation (v1.2)

The real instance produced this crash report on 2026-11-22:

```text
Description: Exception in server tick loop
java.lang.NullPointerException
    at codechicken.lib.world.WorldExtensionManager.preTick(WorldExtensionManager.java:239)
```

Line 239 is `worldMap.get(world)`. The integrated server then stops ticking,
which matches the reported frozen mobs and unopenable chest.

Validation performed:

- A synthetic Java 8 test allocated an unregistered `World` and invoked
  `WorldExtensionManager.preTick` directly.
  - Original class: `THREW java.lang.NullPointerException`.
  - Patched class: `[CLWorldFix] Created missing CodeChickenLib world extensions on demand.` and `NO_NPE`.
- A Linux client launch used a copy of the game directory with
  `clchunkfix-1.2.jar`. The log shows:
  - `Registering transformer clchunkfix.core.WorldExtensionTransformer`
  - `[CLWorldFix] Patched CodeChickenLib WorldExtensionManager tick guard.`
  - `Forge Mod Loader has successfully loaded 102 mods`
  - the main menu rendered with 102 mods active.
- The real Prism instance and its save were not modified.

The exact chest-breaking sequence in the affected save was not replayed
automatically; the unit test exercises the same `preTick` null path.


## Inventory Tweaks guard validation (v1.3)

The real instance produced this crash on 2026-11-23:

```text
Description: Ticking memory connection
java.lang.IndexOutOfBoundsException: Index: 55, Size: 45
    at net.minecraft.inventory.Container.func_75144_a(SourceFile:207)
    at invtweaks.forge.PacketHandler.onClickPacket(PacketHandler.java:46)
```

The server container was the player inventory (45 slots), while the client
still had a chest GUI open and Inventory Tweaks sent a click for slot 55.

Validation performed:

- Synthetic Java 8 test with a 45-slot container:
  - slot 44: allowed (`true`);
  - slot 55: blocked (`false`), and the fake player's `closeScreen` was called.
- The transformer was applied to the actual `invtweaks.forge.PacketHandler`
  class; the patched `onClickPacket` starts with the `allowClick` guard.
- The real instance launched with `clchunkfix-1.4.jar`: the log shows
  `[CLWorldFix] Patched Inventory Tweaks container click guard.`,
  `[CLWorldFix] Patched CodeChickenLib WorldExtensionManager tick guard.`,
  102 mods loaded and no new crash report.
- The guard is defensive: it does not sort, move or delete items.


## HQM OreDictionary cache validation (v1.4)

A thread dump taken while the world was frozen showed the integrated server
thread in HQM item pickup detection:

```text
"Server thread" ... RUNNABLE
    at net.minecraftforge.oredict.OreDictionary.getOreID
    at hardcorequesting.quests.ItemPrecision$4.same
    at hardcorequesting.quests.QuestTaskItemsDetect.countItems
    at hardcorequesting.quests.QuestTaskItemsDetect.onPickUp
```

With `clchunkfix-1.4.jar`:

- the log shows `[CLWorldFix] Patched HQM OreDictionary lookup cache.`;
- a second thread dump no longer contains any HQM/OreDictionary frame;
- the server thread was in normal SpecialMobs pathfinding;
- the world loaded and ran with no new crash report;
- GC pauses stayed around 0.03–0.14 s in the diagnostic session.
- Live gameplay confirmation after 1.4: chest opens normally, items are picked
  up quickly, mobs move, and block breaking works.

The cache is per `ItemStack`; it does not change quest definitions, progress or
item matching semantics.

## Matrix

| Test | Linux | Windows 10 LTSC VM | macOS |
|---|---|---|---|
| Build `clchunkfix` (Java 7 bytecode) | Yes | CI | CI |
| Repository checksums | Yes | Yes | CI |
| PowerShell/Bash script syntax | Yes | Yes (PowerShell 5.1) | CI |
| Installer against generic game dir | Yes | Yes | CI |
| `verify-game-dir` | PASS | PASS | CI |
| Runtime Forge/Java log check | PASS | PASS | Not run |
| Full 1.6.4 + Forge launch to menu | Prism (copy) | Direct Forge jar | Not run |
| `LegacyJavaFixer` loaded | Yes | Yes | Not run |
| CustomChestLoot loaded | Yes | Yes | Not run |
| Death → new world cycle | Yes (earlier run) | Not tested | Not tested |
| Max video profile | Yes | Same file, not launched | Same file, not launched |
| Launcher UI/runtime matrix | See below | See below | Not run |

## Windows test environment

- VirtualBox 7.2.22, Windows 10 Enterprise LTSC 2021, build 19044.
- VM: 5 GB RAM, 4 vCPU, 256 MB VRAM, VBoxSVGA, 3D acceleration enabled.
- Guest Additions 7.2.20.
- Java 8: Eclipse Temurin 1.8.0_512, 64-bit.
- Java 17: Eclipse Temurin 17.0.21, 64-bit.
- Shared folder `Z:` from the host; nothing was written to the real Prism
  instance on the host.
- GPU exposed as `VirtualBox Graphics Adapter (WDDM)`; the launch reports
  `Mesa: SVGA3D` and reaches the game menu.

## Windows evidence

- `install.ps1 -GameDir C:\CrashLandingTest -NoOptions` succeeded.
- `verify-game-dir.ps1 -GameDir C:\CrashLandingTest` reported
  `Integrity check: PASS`.
- The same install/verify sequence passed under a CurseForge-style path with
  spaces: `C:\Users\lab-win10\curseforge\minecraft\Instances\Crash Landing Test`.
- With `clchunkfix-1.2.jar`, the launch log contains
  `Registering transformer clchunkfix.core.WorldExtensionTransformer`,
  `[CLWorldFix] Patched CodeChickenLib WorldExtensionManager tick guard.` and
  `Forge Mod Loader has successfully loaded 102 mods`.
- The 1.6.4 launch log contains:
  - `Forge Mod Loader version 6.4.49.965 for Minecraft 1.6.4`
  - `Java is OpenJDK 64-Bit Server VM, version 1.8.0_512`
  - `[LegacyJavaFixer] Replacing sort`
  - `[CustomChestLoot] Loading custom chest loot...`
  - `[CustomChestLoot] Done!`
  - `Starting up SoundSystem...` and `OpenAL initialized.`
- The game reached the main menu; no new crash report was created.

The direct Windows launch is a test harness, not a normal installation method.
It needs `-Dfml.ignoreInvalidMinecraftCertificates=true` and
`-Dfml.ignorePatchDiscrepancies=true` because the classpath is assembled
manually. Normal launchers pass these checks themselves.

## Launcher matrix

### Windows 10 LTSC

| Launcher | Version | Runtime result | Game result |
|---|---|---|---|
| Prism Launcher | 11.1.1 portable | Quick Setup and account UI opened | Not launched: Prism 11 requires an owning Microsoft account and refused an offline profile |
| MultiMC | 0.7.0-stable-3678 | Quick Setup and main window opened | Not launched: no account; offline CLI still required an account in this build |
| ATLauncher | 3.4.42.0 | UI opened on Java 17.0.21; console reported 5119 MB RAM, 4 cores and the VirtualBox GPU | Not launched: account required |
| GDLauncher | 1.1.30 (legacy Electron) | Window opened, stayed on `Loading...`; `--disable-gpu` did not change it; no error in `main.log` | Not launched |
| CurseForge | 1.327.0 updater / app 0.220.1.9343 | Installer `/S` succeeded; Welcome screen opened; app auto-updated and reopened | Not launched: account required |

The Prism and MultiMC instance folders were pointed at the test game directory
with Windows junctions. The fix scripts did not read launcher metadata.

### Linux

| Launcher | Version | Runtime result | Game result |
|---|---|---|---|
| Prism Launcher | 11.1.1 Flatpak | Opened in an isolated root | **Yes**: a copy of the real game directory reached the 1.6.4 menu; `Integrity check: PASS` |
| MultiMC | 0.7.0-stable-3673 | Quick Setup and main window opened | Not launched: no account; `-o -n TestPlayer` still stopped at the account prompt |
| ATLauncher | 3.4.42.0 | UI opened on Temurin 17.0.21 | Not launched: account required |
| GDLauncher | 1.1.30 AppImage | AppImage and FUSE worked; window stayed on `Loading...`; logged a read-only `7za` chmod error | Not launched |
| Technic Launcher | 4.1180 | Installer UI opened on Temurin 17.0.21 | Not installed: default target was the real home directory; stopped to avoid modifying it |
| CurseForge | — | No official Linux application | Not applicable |

## Dependency checks

| Dependency | Windows VM | Linux host |
|---|---|---|
| Java 8 64-bit | PASS: Temurin 1.8.0_512, used by Forge and the game | PASS: Prism JRE 8 used by the copy launch |
| Java for the launcher | PASS: Temurin 17.0.21 for ATLauncher; Prism and MultiMC portable launchers ran | PASS: Temurin 17.0.21 for ATLauncher and Technic |
| Minecraft 1.6.4 / Forge 9.11.1.965 | PASS in log | PASS in log |
| OpenGL / 3D | PASS: `Mesa: SVGA3D`; game menu rendered | PASS: `glxinfo` direct rendering, AMD Radeon 610M / Mesa 24.3.3 |
| Guest Additions | PASS: 7.2.20 | n/a |
| Shared folder | PASS: `Z:` mounted read/write | n/a |
| FUSE / AppImage | n/a | PASS: `/dev/fuse`, `fusermount3`; GDLauncher AppImage mounted and started |
| Launcher runtimes | PASS for Prism, MultiMC, ATLauncher, GDLauncher and CurseForge (UI level) | PASS for Prism, MultiMC, ATLauncher, GDLauncher and Technic (UI/installer level) |

## Why several launchers show no game launch

This is an account limitation, not a fix failure. The test copy has a valid
offline profile for Prism on Linux, which is why the Prism launch is real. On
Windows there is no Microsoft account in the VM. We deliberately did not copy
the host account tokens into the VM.

To close that last gap, either:

1. sign in to a Microsoft account in the VM, then launch through each launcher;
2. or run the documented manual checklist on the real machine with the normal
   account and report the result.

## Manual checklist (any launcher)

1. Install Minecraft 1.6.4 + Forge 9.11.1.965 and Crash Landing 1.1.3 with your launcher.
2. Locate the game directory (contains `mods/`, `config/`, `saves/`).
3. Run:
   - Linux/macOS: `./scripts/install.sh --game-dir "<dir>"`
   - Windows: `.\scripts\install.ps1 -GameDir "<dir>"`
4. Set Java 8 and the JVM arguments from `docs/INSTALL.md`.
5. Launch the pack.
6. Confirm the main menu and `LegacyJavaFixer` in `ForgeModLoader-client-0.log` (1.6.4) or `logs/latest.log`.
7. Create/enter a world, quit to title, re-enter; check `[CLWorldFix]`.
8. If testing hardcore: die, create the next world, confirm no `loginTimes.dat`/`RuinsPositionsFile.txt` crash.
9. Run `verify-game-dir.sh`/`.ps1`.
10. Check `crash-reports/` for new files.

## Dropped-item render distance validation (v1.5)

- Minecraft 1.6.4 bytecode inspection:
  - `Entity.isInRangeToRenderDist` uses
    `boundingBox.getAverageEdgeLength() * 64 * renderDistanceWeight`;
  - `EntityItem`'s hitbox is 0.25 blocks, so the vanilla client cutoff is
    16 blocks;
  - `EntityTracker` sends `EntityItem` up to 64 blocks.
- Test copy: the transformer log shows
  `[CLWorldFix] Patched dropped-item render distance to 64.0 blocks (+1.0 camera margin, a).`
- Visual check: a dropped block on the flat roof was visible from 60 blocks
  above in the test copy; under the vanilla 16-block formula it would be
  culled.
- GC log: the longest stop-the-world pause during the test was 0.066 s; no
  `Can't keep up!` warning appeared in the test session.
- Real instance: `clchunkfix-1.5.jar` installed; `verify-game-dir` PASS.

## Integrated-server Far view distance validation (v1.8)

Validation steps on the real instance:

1. Install `clchunkfix-1.8.jar` and restart the world so
   `FMLServerStartedEvent` runs.
2. Confirm the log line
   `[CLWorldFix] Set integrated-server view distance to 16 chunks (field ServerConfigurationManager.field_72402_d, 10 -> 17).`
3. Press F3 and check the `C:` loaded-chunk count. It should cover the
   16-chunk radius instead of the smaller default; the band at the old edge
   should be gone.
4. Keep the client FPS unlimited; the fix does not cap FPS.
5. Use a 6144 MB heap and close background applications. The real test used
   6144 MB and F3 showed `C: .../1081` (16-chunk radius); no `Can't keep up!`
   or `Invalid blockID` appeared after the load.

History: 1.6 failed with `Could not find server view distance field`; 1.7
printed an empty `ints:` list because it inspected only the concrete manager
class. 1.8 walks the hierarchy and finds
`ServerConfigurationManager.field_72402_d`.

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
- `You'll need a new app to open this ms-gamingoverlay link` on Windows when
  the Xbox Game Bar URI handler is not installed. It is a Windows shell dialog;
  the game still reaches the main menu.
