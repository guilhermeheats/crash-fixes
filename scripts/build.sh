#!/usr/bin/env bash
# Build clchunkfix against the Forge 1.6.4 universal jar.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="1.1"
JAR_NAME="clchunkfix-${VERSION}.jar"
FORGE_JAR="${FORGE_JAR:-}"

if [ -z "$FORGE_JAR" ]; then
    echo "Set FORGE_JAR to the Forge 1.6.4-9.11.1.965 universal jar." >&2
    echo "Download: https://maven.minecraftforge.net/net/minecraftforge/forge/1.6.4-9.11.1.965/forge-1.6.4-9.11.1.965-universal.jar" >&2
    exit 1
fi
ECJ_VERSION="3.33.0"
ECJ_URL="https://repo1.maven.org/maven2/org/eclipse/jdt/ecj/${ECJ_VERSION}/ecj-${ECJ_VERSION}.jar"
ECJ_JAR="$ROOT/build/ecj.jar"

if [ ! -f "$FORGE_JAR" ]; then
    echo "Forge jar not found: $FORGE_JAR" >&2
    echo "Set FORGE_JAR to the Forge 1.6.4-9.11.1.965 universal jar." >&2
    exit 1
fi

command -v java >/dev/null 2>&1 || { echo "java not found in PATH" >&2; exit 1; }
command -v zip >/dev/null 2>&1 || { echo "zip not found in PATH" >&2; exit 1; }

mkdir -p "$ROOT/build/classes" "$ROOT/build/jar"
rm -rf "$ROOT/build/classes" "$ROOT/build/jar"
mkdir -p "$ROOT/build/classes" "$ROOT/build/jar"

if [ ! -f "$ECJ_JAR" ]; then
    echo "Downloading Eclipse Compiler for Java ${ECJ_VERSION}..."
    curl -fsSL -o "$ECJ_JAR" "$ECJ_URL"
fi

echo "Compiling (Java 7 bytecode for FML 1.6.4/ASM 4.1)..."
java -jar "$ECJ_JAR" \
    -source 1.7 -target 1.7 -proc:none \
    -cp "$FORGE_JAR" \
    -d "$ROOT/build/classes" \
    "$ROOT/src/clchunkfix/ChunkFix.java"

cp "$ROOT/src/mcmod.info" "$ROOT/build/jar/"
cp -r "$ROOT/build/classes/." "$ROOT/build/jar/"

(
    cd "$ROOT/build/jar"
    zip -q -r "$ROOT/build/$JAR_NAME" .
)

cp "$ROOT/build/$JAR_NAME" "$ROOT/mods/$JAR_NAME"

MAJOR="$(od -An -t u1 -j 6 -N 2 "$ROOT/build/classes/clchunkfix/ChunkFix.class" | awk '{print $2}')"
if [ "$MAJOR" != "51" ]; then
    echo "Unexpected class major version: $MAJOR (expected 51/Java 7)" >&2
    exit 1
fi

echo "Built: $ROOT/mods/$JAR_NAME"
echo "Class major version: $MAJOR"
if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$ROOT/mods/$JAR_NAME"
else
    shasum -a 256 "$ROOT/mods/$JAR_NAME"
fi
