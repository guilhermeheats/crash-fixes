# Changelog

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
