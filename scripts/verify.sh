#!/usr/bin/env bash
# Verify repository artifact checksums.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT/checksums.txt" "$ROOT" <<'PY'
import hashlib
import os
import sys

manifest, root = sys.argv[1], sys.argv[2]
fail = False
with open(manifest, encoding="utf-8") as f:
    for line in f:
        line = line.rstrip("\n")
        if not line.strip():
            continue
        digest, name = line.split("  ", 1)
        path = os.path.join(root, name)
        if not os.path.isfile(path):
            print(f"MISSING {name}")
            fail = True
            continue
        h = hashlib.sha256()
        with open(path, "rb") as fh:
            for chunk in iter(lambda: fh.read(1024 * 1024), b""):
                h.update(chunk)
        if h.hexdigest() == digest:
            print(f"OK      {name}")
        else:
            print(f"FAIL    {name}")
            fail = True
if fail:
    sys.exit(1)
print("All repository checksums OK.")
PY
