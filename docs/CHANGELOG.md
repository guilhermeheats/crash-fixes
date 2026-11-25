# Changelog

## v2.5.0 — Integrated-server Far view distance

- `clchunkfix-1.6.jar` raises the integrated-server view distance to 16 chunks
  on server start, matching the client's Far render distance.
- Fixes the band of unloaded chunks at the edge when the client is set to Far
  but the integrated server keeps its smaller default view distance.
- The client FPS is not limited; the trade-off is more chunk generation,
  chunk loading and memory use.
- Optional JVM property `-Dclchunkfix.serverViewDistance=<3-16>`; default 16.
- Recommended for Far: 5–6 GB heap (the real session was using about 4.25 GB
  RSS with a 4 GB heap) and no heavy browser in the background.
- The expected log line is
  `[CLWorldFix] Set integrated-server view distance to 16 chunks.`
- Installers remove older `clchunkfix-1.0` through `1.5`.
- No pack, mod, recipe, loot or world data is redistributed or changed.

## v2.4.0 — Dropped-item render distance

- `clchunkfix-1.5.jar` raises the client-side render distance of dropped item
  entities from 16 to 64 blocks, plus a 1-block camera margin.
- Cause: `EntityItem`'s 0.25-block hitbox makes vanilla
  `Entity.isInRangeToRenderDist` cull it at 16 blocks, while the server
  `EntityTracker` already tracks item entities up to 64 blocks.
- Visual-only: pickup range, physics, despawn and server tracking are
  unchanged.
- Optional JVM property `-Dclchunkfix.itemRenderDistance=<16-64>`; default 64.
- Verified in a copy of the world: a dropped block was visible from 60 blocks
  above; the transformer log shows the 64-block override; no crash report.
- GC logging during the test showed a maximum stop-the-world pause of 0.066 s,
  so the observed `Can't keep up!` warnings were not GC pauses; they were
  transient server-tick spikes.
- Installers remove older `clchunkfix-1.0` through `1.4`.
- No pack, mod, recipe, loot or world data is redistributed or changed.

## v2.3.0 — HQM OreDictionary cache

- `clchunkfix-1.4.jar` caches Hardcore Questing Mode 4.0.5 OreDictionary
  lookups during item pickup detection.
- Fixes the server thread spending seconds inside
  `QuestTaskItemsDetect.onPickUp` → `ItemPrecision$4.same` →
  `OreDictionary.getOreID`, which scans the whole ore dictionary for every
  inventory/quest item comparison.
- This was observed with a thread dump while the world was frozen: mobs stopped,
  chests delayed and eating did not advance.
- The cache is per `ItemStack`; quest definitions, progress and item matching
  semantics are unchanged.
- Installers remove older `clchunkfix-1.0` through `1.3`.
- Verified with a thread dump before/after on a copy of the real save.
- Confirmed in live gameplay: chest opening, item pickup, mob movement and
  block breaking are normal.
- No pack, mod, recipe, loot or world data is redistributed or changed.

## v2.2.0 — Inventory Tweaks stale GUI guard

- `clchunkfix-1.3.jar` adds a coremod guard for Inventory Tweaks 1.56.
- Fixes the `Container.clickSlot` `IndexOutOfBoundsException` (for example
  `Index: 55, Size: 45`) that stops the integrated server when a stale chest
  GUI sends a click for a slot that no longer exists.
- The guard drops the invalid click and closes the stale GUI so the next chest
  interaction reopens cleanly.
- Installers remove older `clchunkfix-1.0.jar`, `1.1.jar` and `1.2.jar`.
- Verified with a synthetic invalid click (slot 55 of a 45-slot container):
  valid clicks pass, invalid clicks are blocked and the fake GUI closes.
- The real instance launched with 1.3: both guards logged, 102 mods loaded,
  no new crash report.
- No pack, mod, recipe, loot or world data is redistributed or changed.

## v2.1.0 — CodeChickenLib world tick guard

- `clchunkfix-1.2.jar` adds a coremod guard for CodeChickenLib 1.0.0.62.
- Fixes the `WorldExtensionManager.preTick` `NullPointerException` that stops
  the integrated server tick loop (frozen mobs, chests that no longer open).
- The guard creates missing world-extension state on demand, with an empty
  extension set as a safe fallback.
- Installers remove older `clchunkfix-1.0.jar` and `clchunkfix-1.1.jar`.
- Verified with a synthetic unregistered-world call (`preTick` NPE before,
  no NPE after), a Linux client launch to the main menu with 102 mods, and a
  Windows 10 LTSC launch with 102 mods plus `verify-game-dir.ps1` PASS.
- No pack, mod, recipe, loot or world data is redistributed or changed.

## Unreleased — launcher/dependency validation

- Windows 10 LTSC VM: `install.ps1` and `verify-game-dir.ps1` PASS, including a
  CurseForge-style path with spaces.
- Windows: Minecraft 1.6.4 + Forge 9.11.1.965 + Java 8 reached the main menu;
  `LegacyJavaFixer`, CustomChestLoot and OpenAL initialized; no new crash report.
- Runtime checks for Prism, MultiMC, ATLauncher, GDLauncher, CurseForge,
  Technic, FUSE/AppImage, OpenGL/3D, Guest Additions and the shared folder.
- Documented that current launchers require a Microsoft account owning Minecraft
  to launch the game, and that legacy GDLauncher 1.1.30 can hang at `Loading...`.
- No fix jar or pack asset changed.

## v2.0.1 — 1.6.4 log verification

- `verify-game-dir` now checks `ForgeModLoader-client-0.log` (the 1.6.4 log) as well as `logs/latest.log`.
- This makes the runtime Forge/Java check work on actual 1.6.4 launches.
- Verified on Linux with a copy of a real Crash Landing game directory: menu launch, `LegacyJavaFixer`, CustomChestLoot and `Integrity check: PASS`.

## v2.0.0 — launcher-agnostic

- Removed the Prism Launcher dependency from installers and verifiers.
- Installers now take a generic Minecraft **game directory** (`--game-dir` / `-GameDir`) containing `mods/`, `config/`, `saves/` and `options.txt`.
- Verification no longer requires `instance.cfg` or `mmc-pack.json`; it checks the game directory, mod manifest, options and optional 1.6.4 log (`ForgeModLoader-client-0.log` or `logs/latest.log`).
- JVM arguments are documented for each launcher instead of being written into a Prism config.
- Added full `CREDITS.md` including all pack mod authors.
- Rebuilt `clchunkfix-1.1.jar` with the correct author metadata.
- Updated CI to smoke-test installers against generic game directories.
- Works with Prism, CurseForge, MultiMC, ATLauncher, GDLauncher, vanilla, etc. Prism is no longer required.

## v1.3.1 — CI installer smoke tests

- GitHub Actions now smoke-tests the Linux/macOS and Windows installers on fixture instances.
- CI matrix passes on Ubuntu, Windows and macOS.
- Release assets unchanged: `clchunkfix-1.1.jar`, `legacyjavafixer-1.0.jar`, checksums, mod manifest, reference options.

## v1.3.0 — public release

- Public repository with clean history; no modpack redistribution.
- `legacyjavafixer-1.0.jar` for the Forge 1.6.4 + Java 8 startup crash.
- `clchunkfix-1.1.jar` for ChickenChunks and Ruins world-switch state.
- CustomChestLoot continuation-line fix.
- Obsolete update-check/radio cleanup.
- Max-fidelity video profile.
- `mods.sha256` integrity manifest.
- Bash, PowerShell and Python installers/verifiers.
- GitHub Actions verification and release workflows.
- Linux tested in a real Prism instance; Windows/macOS CI/static only.
