# Verification and integrity

The verifier works on any Minecraft **game directory**; it does not need launcher metadata.

## Repository checksums

`checksums.txt` covers:

- `mods/legacyjavafixer-1.0.jar`
- `mods/clchunkfix-1.1.jar`
- `mods.sha256`

Linux/macOS:

```bash
./scripts/verify.sh
```

Windows:

```powershell
.\scripts\verify.ps1
```

## Mod manifest

`mods.sha256` contains the SHA-256 of the **63 mod files** in a Crash Landing 1.1.3 game directory, including the two `.disabled` pack mods and the two technical fixes.

Regenerate it from any game directory:

```bash
./scripts/generate-mod-manifest.sh --game-dir "<game-dir>"
```

```powershell
.\scripts\generate-mod-manifest.ps1 -GameDir "C:\path\to\game-dir"
```

The manifest is strict. If you intentionally add/remove mods, verification fails unless you use the allow-extra option.

## Game directory verification

Linux/macOS:

```bash
./scripts/verify-game-dir.sh --game-dir "/path/to/game-dir"
```

Windows:

```powershell
.\scripts\verify-game-dir.ps1 -GameDir "C:\path\to\game-dir"
```

It checks:

- `mods/` exists and `config/` is present (warning if missing);
- `legacyjavafixer-1.0.jar` and `clchunkfix-1.1.jar`;
- every mod against `mods.sha256`;
- missing/extra mods;
- `options.txt` against `examples/options.txt` (warning only);
- if `logs/latest.log` exists, Minecraft 1.6.4, Forge 9.11.1.965 and Java 8.

It does **not** require `instance.cfg`, `mmc-pack.json`, a specific launcher, or a specific Java path. If `logs/latest.log` is absent, the runtime version check is a warning; launch the game once and re-run.

Allow extra mods intentionally:

```bash
./scripts/verify-game-dir.sh --game-dir "..." --allow-extra
```

```powershell
.\scripts\verify-game-dir.ps1 -GameDir "..." -AllowExtra
```

## Expected output

```text
Integrity check: PASS
```

A game directory that has not been launched yet may show:

```text
WARN logs/latest.log not found; Forge/Java version cannot be verified
```

That is expected until the first launch.

## What is not verified

- Real game rendering on Windows/macOS (needs a real machine or VM).
- World content/save integrity (no world backup is made).
- Third-party mod licenses beyond those documented in `THIRD_PARTY.md`/`CREDITS.md`.
