# Changelog

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
