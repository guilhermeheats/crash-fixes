#!/usr/bin/env bash
# Install Crash Landing technical fixes into any Minecraft game directory.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON="${PYTHON:-python3}"
GAME_DIR="${GAME_DIR:-${MINECRAFT_DIR:-}}"
APPLY_OPTIONS=1

usage() {
    cat <<'EOF'
Usage: install.sh --game-dir <dir> [--no-options]

<dir> is the Minecraft game directory: the folder that contains mods/, config/
and saves/. It is not tied to a specific launcher.

Examples:
  ./scripts/install.sh --game-dir "$HOME/.minecraft"
  ./scripts/install.sh --game-dir "/path/to/launcher/instances/Crash Landing"
  APPLY_OPTIONS=0 ./scripts/install.sh --game-dir "..."
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --game-dir|-g)
            GAME_DIR="${2:-}"
            shift 2
            ;;
        --no-options)
            APPLY_OPTIONS=0
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [ -z "$GAME_DIR" ]; then
                GAME_DIR="$1"
                shift
            else
                echo "Unknown argument: $1" >&2
                usage >&2
                exit 2
            fi
            ;;
    esac
done

if [ -z "$GAME_DIR" ]; then
    usage >&2
    exit 2
fi

GAME_DIR="${GAME_DIR%/}"
if [ ! -d "$GAME_DIR" ]; then
    echo "Game directory not found: $GAME_DIR" >&2
    exit 1
fi
if [ ! -d "$GAME_DIR/mods" ]; then
    echo "Not a Minecraft/Crash Landing game directory (missing mods/): $GAME_DIR" >&2
    echo "Pass the folder that contains mods/, config/ and saves/." >&2
    exit 1
fi

command -v "$PYTHON" >/dev/null 2>&1 || {
    echo "Python 3 is required on Linux/macOS: $PYTHON" >&2
    exit 1
}

MODS="$GAME_DIR/mods"
echo "Installing fixes into: $GAME_DIR"
cp "$ROOT/mods/legacyjavafixer-1.0.jar" "$MODS/legacyjavafixer-1.0.jar"
cp "$ROOT/mods/clchunkfix-1.5.jar" "$MODS/clchunkfix-1.5.jar"
rm -f "$MODS/clchunkfix-1.0.jar" "$MODS/clchunkfix-1.1.jar" "$MODS/clchunkfix-1.2.jar" "$MODS/clchunkfix-1.3.jar" "$MODS/clchunkfix-1.4.jar"

if [ "$APPLY_OPTIONS" = "1" ]; then
    if [ -f "$GAME_DIR/options.txt" ]; then
        backup="$GAME_DIR/options.txt.bak.$(date +%Y%m%d-%H%M%S)"
        cp "$GAME_DIR/options.txt" "$backup"
        echo "Backed up options.txt to: $backup"
    fi
    cp "$ROOT/examples/options.txt" "$GAME_DIR/options.txt"
    echo "Applied max-fidelity options.txt"
else
    echo "Skipped options.txt (--no-options / APPLY_OPTIONS=0)"
fi

if [ -d "$GAME_DIR/config/CustomChestLoot" ]; then
    "$PYTHON" "$ROOT/scripts/fix-customchestloot.py" "$GAME_DIR/config/CustomChestLoot"
else
    echo "CustomChestLoot config not found; skipping. Is Crash Landing installed?"
fi

"$PYTHON" "$ROOT/scripts/cleanup-network-checks.py" "$GAME_DIR"

cat <<'EOF'

Done. Required mods:
  mods/legacyjavafixer-1.0.jar
  mods/clchunkfix-1.5.jar

Use Java 8 64-bit and set these JVM arguments in your launcher:
  -Xms4096m -Xmx4096m
  -XX:+UseG1GC
  -XX:+UnlockExperimentalVMOptions
  -XX:G1NewSizePercent=20
  -XX:G1ReservePercent=20
  -XX:MaxGCPauseMillis=50
  -XX:G1HeapRegionSize=32M
  -XX:+DisableExplicitGC
  -XX:+ParallelRefProcEnabled
  -XX:+PerfDisableSharedMem

Verify with:
  ./scripts/verify-game-dir.sh --game-dir "<game-dir>"
EOF
