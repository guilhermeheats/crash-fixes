#!/usr/bin/env bash
# Install the Crash Landing technical fixes into an existing Prism instance.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON="${PYTHON:-python3}"
APPLY_OPTIONS="${APPLY_OPTIONS:-1}"

if [ -z "${INSTANCE:-}" ]; then
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

if [ -z "${INSTANCE:-}" ] || [ ! -f "$INSTANCE/instance.cfg" ]; then
    echo "Crash Landing Prism instance not found." >&2
    echo "Set INSTANCE to the instance directory, for example:" >&2
    echo '  INSTANCE="$HOME/.local/share/PrismLauncher/instances/Crash Landing" ./scripts/install.sh' >&2
    exit 1
fi

command -v "$PYTHON" >/dev/null 2>&1 || {
    echo "Python 3 is required on Linux/macOS: $PYTHON" >&2
    exit 1
}

MINECRAFT="$INSTANCE/minecraft"
MODS="$MINECRAFT/mods"
mkdir -p "$MODS"

echo "Installing fixes into: $INSTANCE"
cp "$ROOT/mods/legacyjavafixer-1.0.jar" "$MODS/legacyjavafixer-1.0.jar"
cp "$ROOT/mods/clchunkfix-1.1.jar" "$MODS/clchunkfix-1.1.jar"
rm -f "$MODS/clchunkfix-1.0.jar"

echo "Applying Java/memory settings..."
"$PYTHON" - "$INSTANCE/instance.cfg" <<'PY'
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    lines = f.read().splitlines()

settings = {
    "MinMemAlloc": "4096",
    "MaxMemAlloc": "4096",
    "OverrideMemory": "true",
    "OverrideJavaArgs": "true",
    "JvmArgs": '"-XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:G1NewSizePercent=20 -XX:G1ReservePercent=20 -XX:MaxGCPauseMillis=50 -XX:G1HeapRegionSize=32M -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem"',
}

start = None
end = len(lines)
for i, line in enumerate(lines):
    if line.strip() == "[General]":
        start = i
    elif start is not None and line.startswith("[") and line.strip() != "[General]":
        end = i
        break

if start is None:
    raise SystemExit("No [General] section in instance.cfg")

changed = []
for key, value in settings.items():
    needle = key + "="
    found = False
    for i in range(start + 1, end):
        if lines[i].startswith(needle):
            new_line = f"{key}={value}"
            if lines[i] != new_line:
                lines[i] = new_line
                changed.append(key)
            found = True
            break
    if not found:
        lines.insert(end, f"{key}={value}")
        end += 1
        changed.append(key)

with open(path, "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")

print("Updated: " + (", ".join(changed) if changed else "nothing (already set)"))
PY

if [ "$APPLY_OPTIONS" = "1" ]; then
    if [ -f "$MINECRAFT/options.txt" ]; then
        backup="$MINECRAFT/options.txt.bak.$(date +%Y%m%d-%H%M%S)"
        cp "$MINECRAFT/options.txt" "$backup"
        echo "Backed up options.txt to: $backup"
    fi
    cp "$ROOT/examples/options.txt" "$MINECRAFT/options.txt"
    echo "Applied max-fidelity options.txt"
else
    echo "Skipped options.txt (APPLY_OPTIONS=0)"
fi

if [ -d "$MINECRAFT/config/CustomChestLoot" ]; then
    "$PYTHON" "$ROOT/scripts/fix-customchestloot.py" "$MINECRAFT/config/CustomChestLoot"
else
    echo "CustomChestLoot config not found; skipping."
fi

"$PYTHON" "$ROOT/scripts/cleanup-network-checks.py" "$MINECRAFT"

echo
echo "Done. Required mods:"
echo "  $MODS/legacyjavafixer-1.0.jar"
echo "  $MODS/clchunkfix-1.1.jar"
echo "Keep Java 8 selected in Prism."
