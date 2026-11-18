#!/usr/bin/env bash
# Download the official Crash Landing 1.1.3 pack file for your launcher.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
URL="https://mediafilez.forgecdn.net/files/2235/312/CrashLanding-1.1.3-1.6.4.zip"
EXPECTED="42996d8105bcea94460ca334f848343ea2f3e2dd47d2597d159418dd93e5071b"
DEST="${1:-$ROOT/pack/CrashLanding-1.1.3-1.6.4.zip}"
mkdir -p "$(dirname "$DEST")"

if [ ! -f "$DEST" ]; then
    echo "Downloading Crash Landing 1.1.3..."
    curl -fL --retry 3 -o "$DEST" "$URL"
fi

if command -v sha256sum >/dev/null 2>&1; then
    ACTUAL="$(sha256sum "$DEST" | awk '{print $1}')"
else
    ACTUAL="$(shasum -a 256 "$DEST" | awk '{print $1}')"
fi

if [ "$ACTUAL" != "$EXPECTED" ]; then
    echo "SHA-256 mismatch for $DEST" >&2
    exit 1
fi

echo "Pack file: $DEST"
echo "Install it with your launcher, then run:"
echo "  ./scripts/install.sh --game-dir <game-dir>"
