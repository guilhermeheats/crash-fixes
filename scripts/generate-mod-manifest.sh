#!/usr/bin/env bash
# Regenerate mods.sha256 from any Minecraft game directory.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GAME_DIR="${1:-${GAME_DIR:-${MINECRAFT_DIR:-}}}"

if [ -z "$GAME_DIR" ]; then
    echo "Usage: generate-mod-manifest.sh --game-dir <dir>" >&2
    exit 2
fi
GAME_DIR="${GAME_DIR%/}"
MODS="$GAME_DIR/mods"
if [ ! -d "$MODS" ]; then
    echo "Mods directory not found: $MODS" >&2
    exit 1
fi

cd "$MODS"
python3 - "$ROOT/mods.sha256" <<'PY'
import hashlib
import os
import sys

out = sys.argv[1]
entries = []
for name in os.listdir("."):
    if not os.path.isfile(name):
        continue
    if not name.endswith((".jar", ".zip", ".jar.disabled", ".zip.disabled")):
        continue
    h = hashlib.sha256()
    with open(name, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    entries.append((name, h.hexdigest()))

entries.sort()
with open(out, "w", encoding="utf-8", newline="\n") as f:
    for name, digest in entries:
        f.write(f"{digest}  ./{name}\n")
print(f"Wrote {out} ({len(entries)} entries)")
PY
