# Verification and integrity

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

`mods.sha256` contains the SHA-256 of the **63 mod files** in a Crash Landing 1.1.3 instance, including the two `.disabled` pack mods and the two technical fixes.

Regenerate it from an installed instance:

```bash
./scripts/generate-mod-manifest.sh "<instance>"
```

```powershell
.\scripts\generate-mod-manifest.ps1 -Instance "C:\...\Crash Landing"
```

The manifest is intentionally strict: if you add or remove a mod, verification fails. For intentional additions, use the allow-extra option described below.

## Instance verification

Linux/macOS:

```bash
INSTANCE="$HOME/.local/share/PrismLauncher/instances/Crash Landing" \
  ./scripts/verify-instance.sh
```

Windows:

```powershell
.\scripts\verify-instance.ps1 -Instance "C:\Users\<you>\AppData\Roaming\PrismLauncher\instances\Crash Landing"
```

It checks:

- `instance.cfg` and `mmc-pack.json` exist;
- Minecraft `1.6.4`;
- Forge `9.11.1.965`;
- LWJGL `2.9.4-nightly-20150209`;
- `legacyjavafixer-1.0.jar` and `clchunkfix-1.1.jar`;
- every mod against `mods.sha256`;
- missing/extra mods;
- Java 8 via `JavaPath` or `AutomaticJava=true`;
- 4 GB + G1GC;
- `options.txt` against `examples/options.txt` (warning only).

Allow extra mods intentionally:

```bash
STRICT_EXTRA=0 ./scripts/verify-instance.sh
```

```powershell
.\scripts\verify-instance.ps1 -Instance "..." -AllowExtra
```

## Expected results

A healthy instance ends with:

```text
Integrity check: PASS
```

A clean instance installed by Prism may report:

```text
WARN AutomaticJava=true; Prism must select Java 8
```

That is expected; Prism should download/select Java 8 on first launch.

## What is not verified

- Real game rendering on Windows/macOS (needs a real machine or VM).
- World content/save integrity (no world backup is made).
- Third-party mod licenses beyond the ones documented in `THIRD_PARTY.md`.
