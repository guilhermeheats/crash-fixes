#!/usr/bin/env bash
# Verify a Crash Landing instance against the pinned pack/fix manifest.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_INSTANCE="$HOME/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances/Crash Landing"
INSTANCE="${INSTANCE:-${1:-}}"
if [ -z "$INSTANCE" ]; then
    for candidate in \
        "$HOME/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances/Crash Landing" \
        "$HOME/.local/share/PrismLauncher/instances/Crash Landing" \
        "$HOME/Library/Application Support/PrismLauncher/instances/Crash Landing"
    do
        if [ -f "$candidate/instance.cfg" ]; then
            INSTANCE="$candidate"
            break
        fi
    done
fi
INSTANCE="${INSTANCE:-$DEFAULT_INSTANCE}"
MC="$INSTANCE/minecraft"
MODS="$MC/mods"
STRICT_EXTRA="${STRICT_EXTRA:-1}"
FAIL=0

ok()   { echo "  OK   $*"; }
warn() { echo "  WARN $*"; }
bad()  { echo "  FAIL $*"; FAIL=1; }

echo "Instance: $INSTANCE"

if [ ! -f "$INSTANCE/instance.cfg" ] || [ ! -f "$INSTANCE/mmc-pack.json" ]; then
    echo "Not a Prism instance: missing instance.cfg/mmc-pack.json" >&2
    exit 1
fi
ok "instance.cfg and mmc-pack.json present"

python3 - "$INSTANCE/mmc-pack.json" <<'PY' || FAIL=1
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
components = {c.get("uid"): c.get("version") for c in data.get("components", [])}
required = {
    "net.minecraft": "1.6.4",
    "net.minecraftforge": "9.11.1.965",
    "org.lwjgl": "2.9.4-nightly-20150209",
}
failed = False
for uid, version in required.items():
    actual = components.get(uid)
    if actual == version:
        print(f"  OK   {uid} == {version}")
    else:
        print(f"  FAIL {uid}: expected {version}, got {actual}")
        failed = True
if failed:
    sys.exit(1)
PY

for jar in legacyjavafixer-1.0.jar clchunkfix-1.1.jar; do
    if [ -f "$MODS/$jar" ]; then
        ok "required mod: $jar"
    else
        bad "missing required mod: $jar"
    fi
done

if [ ! -f "$ROOT/mods.sha256" ]; then
    bad "mods.sha256 not found in repo"
elif [ ! -d "$MODS" ]; then
    bad "mods directory missing: $MODS"
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

JAVA_PATH="$(awk -F= '/^JavaPath=/{print substr($0, index($0,"=")+1)}' "$INSTANCE/instance.cfg" | tr -d '"')"
if [ -n "$JAVA_PATH" ] && [ -x "$JAVA_PATH" ]; then
    JAVA_VERSION="$("$JAVA_PATH" -version 2>&1 | head -n1 || true)"
    if echo "$JAVA_VERSION" | grep -q '1\.8\.'; then
        ok "Java 8: $JAVA_VERSION"
    else
        bad "expected Java 8, got: $JAVA_VERSION"
    fi
elif grep -q '^AutomaticJava=true' "$INSTANCE/instance.cfg"; then
    warn "AutomaticJava=true; Prism must select Java 8"
else
    bad "no valid JavaPath and AutomaticJava is not enabled"
fi

if grep -q '^MaxMemAlloc=4096$' "$INSTANCE/instance.cfg" && \
   grep -q '^MinMemAlloc=4096$' "$INSTANCE/instance.cfg" && \
   grep -q 'UseG1GC' "$INSTANCE/instance.cfg"; then
    ok "4 GB + G1GC settings present"
else
    warn "memory/JVM settings differ from the tested 4 GB + G1GC profile"
fi

if [ -f "$ROOT/examples/options.txt" ] && [ -f "$MC/options.txt" ]; then
    if diff -q "$ROOT/examples/options.txt" "$MC/options.txt" >/dev/null 2>&1; then
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
