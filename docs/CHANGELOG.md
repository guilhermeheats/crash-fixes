# Changelog

## v2.0.0 — launcher-agnostic

- Removed the Prism Launcher dependency from installers and verifiers.
- Installers now take a generic Minecraft **game directory** (`--game-dir` / `-GameDir`) containing `mods/`, `config/`, `saves/` and `options.txt`.
- Verification no longer requires `instance.cfg` or `mmc-pack.json`; it checks the game directory, mod manifest, options and optional `logs/latest.log`.
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
