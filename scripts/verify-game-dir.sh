#!/usr/bin/env bash
# Verify a Crash Landing game directory, independent of launcher metadata.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GAME_DIR="${GAME_DIR:-${MINECRAFT_DIR:-}}"
STRICT_EXTRA="${STRICT_EXTRA:-1}"
FAIL=0

while [ $# -gt 0 ]; do
    case "$1" in
        --game-dir|-g)
            GAME_DIR="${2:-}"
            shift 2
            ;;
        --allow-extra)
            STRICT_EXTRA=0
            shift
            ;;
        -h|--help)
            echo "Usage: verify-game-dir.sh --game-dir <dir> [--allow-extra]"
            exit 0
            ;;
        *)
            if [ -z "$GAME_DIR" ]; then GAME_DIR="$1"; shift; else
                echo "Unknown argument: $1" >&2; exit 2
            fi
            ;;
    esac
done

if [ -z "$GAME_DIR" ]; then
    echo "Usage: verify-game-dir.sh --game-dir <dir> [--allow-extra]" >&2
    exit 2
fi

GAME_DIR="${GAME_DIR%/}"
MODS="$GAME_DIR/mods"

ok()   { echo "  OK   $*"; }
warn() { echo "  WARN $*"; }
bad()  { echo "  FAIL $*"; FAIL=1; }

echo "Game directory: $GAME_DIR"
if [ ! -d "$GAME_DIR" ]; then
    echo "Game directory not found." >&2
    exit 1
fi
if [ ! -d "$GAME_DIR/mods" ]; then
    echo "Not a Minecraft game directory (missing mods/)." >&2
    exit 1
fi
ok "mods/ present"
if [ -d "$GAME_DIR/config" ]; then
    ok "config/ present"
else
    warn "config/ missing; is Crash Landing installed?"
fi

for jar in legacyjavafixer-1.0.jar clchunkfix-1.1.jar; do
    if [ -f "$MODS/$jar" ]; then
        ok "required mod: $jar"
    else
        bad "missing required mod: $jar"
    fi
done

if [ ! -f "$ROOT/mods.sha256" ]; then
    bad "mods.sha256 not found in repo"
else
    python3 - "$MODS" "$ROOT/mods.sha256" "$STRICT_EXTRA" <<'PY' || FAIL=1
import hashlib
import os
import sys

mods_dir, manifest, strict = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
expected = {}
for line in open(manifest, encoding="utf-8"):
    line = line.rstrip("\n")
    if not line.strip():
        continue
    digest, name = line.split("  ", 1)
    expected[os.path.basename(name)] = digest.lower()

failed = False
for name, digest in expected.items():
    path = os.path.join(mods_dir, name)
    if not os.path.isfile(path):
        print("  FAIL missing mod: " + name)
        failed = True
        continue
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    if h.hexdigest() != digest:
        print("  FAIL checksum mismatch: " + name)
        failed = True
if not failed:
    print("  OK   all mod files match mods.sha256")

actual = {
    name for name in os.listdir(mods_dir)
    if name.endswith((".jar", ".zip", ".jar.disabled", ".zip.disabled"))
}
extra = sorted(actual - set(expected))
missing = sorted(set(expected) - actual)
if missing:
    print("  FAIL missing mods: " + ", ".join(missing))
    failed = True
if extra:
    label = "FAIL" if strict else "WARN"
    print(f"  {label} extra mods not in manifest: " + ", ".join(extra))
    if strict:
        failed = True
elif not failed:
    print("  OK   no unexpected mods")
if failed:
    sys.exit(1)
PY
fi

# Optional runtime log checks. These prove the Forge/Java versions without
# requiring any launcher metadata.
LOG="$GAME_DIR/logs/latest.log"
if [ -f "$LOG" ]; then
    if grep -q 'Forge Mod Loader version 6.4.49.965 for Minecraft 1.6.4' "$LOG" ||
       grep -q 'Minecraft Forge 9.11.1.965' "$LOG"; then
        ok "latest.log reports Minecraft 1.6.4 + Forge 9.11.1.965"
    else
        warn "latest.log present, but the expected Forge/Minecraft version was not found"
    fi
    if grep -q 'Java is .*version 1\.8\.' "$LOG"; then
        ok "latest.log reports Java 8"
    else
        warn "latest.log does not clearly report Java 8"
    fi
else
    warn "logs/latest.log not found; Forge/Java version cannot be verified"
fi

if [ -f "$ROOT/examples/options.txt" ] && [ -f "$GAME_DIR/options.txt" ]; then
    if diff -q "$ROOT/examples/options.txt" "$GAME_DIR/options.txt" >/dev/null 2>&1; then
        ok "options.txt matches the recorded profile"
    else
        warn "options.txt differs from the recorded profile (user changes allowed)"
    fi
fi

echo
if [ "$FAIL" = "0" ]; then
    echo "Integrity check: PASS"
    exit 0
else
    echo "Integrity check: FAIL"
    exit 1
fi
