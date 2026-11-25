#!/usr/bin/env bash
# Build clchunkfix against the Forge 1.6.4 universal jar.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="1.8"
JAR_NAME="clchunkfix-${VERSION}.jar"
FORGE_JAR="${FORGE_JAR:-}"
ASM_JAR="${ASM_JAR:-$ROOT/build/asm-all-4.1.jar}"
LAUNCHWRAPPER_JAR="${LAUNCHWRAPPER_JAR:-$ROOT/build/launchwrapper-1.8.jar}"

if [ -z "$FORGE_JAR" ]; then
    echo "Set FORGE_JAR to the Forge 1.6.4-9.11.1.965 universal jar." >&2
    echo "Download: https://maven.minecraftforge.net/net/minecraftforge/forge/1.6.4-9.11.1.965/forge-1.6.4-9.11.1.965-universal.jar" >&2
    exit 1
fi
ECJ_VERSION="3.33.0"
ECJ_URL="https://repo1.maven.org/maven2/org/eclipse/jdt/ecj/${ECJ_VERSION}/ecj-${ECJ_VERSION}.jar"
ECJ_JAR="$ROOT/build/ecj.jar"
ASM_URL="https://repo1.maven.org/maven2/org/ow2/asm/asm-all/4.1/asm-all-4.1.jar"
LAUNCHWRAPPER_URL="https://libraries.minecraft.net/net/minecraft/launchwrapper/1.8/launchwrapper-1.8.jar"

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
if [ ! -f "$ASM_JAR" ]; then
    echo "Downloading ASM 4.1..."
    curl -fsSL -o "$ASM_JAR" "$ASM_URL"
fi
if [ ! -f "$LAUNCHWRAPPER_JAR" ]; then
    echo "Downloading LaunchWrapper 1.8..."
    curl -fsSL -o "$LAUNCHWRAPPER_JAR" "$LAUNCHWRAPPER_URL"
fi

echo "Compiling (Java 7 bytecode for FML 1.6.4/ASM 4.1)..."
java -jar "$ECJ_JAR" \
    -source 1.7 -target 1.7 -proc:none \
    -cp "$FORGE_JAR:$ASM_JAR:$LAUNCHWRAPPER_JAR" \
    -d "$ROOT/build/classes" \
    "$ROOT/src/clchunkfix/ChunkFix.java" \
    "$ROOT/src/clchunkfix/core/ChunkFixCorePlugin.java" \
    "$ROOT/src/clchunkfix/core/WorldExtensionTransformer.java" \
    "$ROOT/src/clchunkfix/core/WorldExtensionHooks.java" \
    "$ROOT/src/clchunkfix/core/InvTweaksTransformer.java" \
    "$ROOT/src/clchunkfix/core/InvTweaksHooks.java" \
    "$ROOT/src/clchunkfix/core/HqmTransformer.java" \
    "$ROOT/src/clchunkfix/core/HqmHooks.java" \
    "$ROOT/src/clchunkfix/core/ItemRenderTransformer.java"

mkdir -p "$ROOT/build/jar/META-INF"
printf 'Manifest-Version: 1.0\r\nFMLCorePlugin: clchunkfix.core.ChunkFixCorePlugin\r\nFMLCorePluginContainsFMLMod: true\r\n' \
    > "$ROOT/build/jar/META-INF/MANIFEST.MF"
cp "$ROOT/src/mcmod.info" "$ROOT/build/jar/"
cp -r "$ROOT/build/classes/." "$ROOT/build/jar/"

(
    cd "$ROOT/build/jar"
    zip -q -r "$ROOT/build/$JAR_NAME" .
)

rm -f "$ROOT/mods/clchunkfix-1.0.jar" "$ROOT/mods/clchunkfix-1.1.jar" "$ROOT/mods/clchunkfix-1.2.jar" "$ROOT/mods/clchunkfix-1.3.jar" "$ROOT/mods/clchunkfix-1.4.jar" "$ROOT/mods/clchunkfix-1.5.jar" "$ROOT/mods/clchunkfix-1.6.jar" "$ROOT/mods/clchunkfix-1.7.jar"
cp "$ROOT/build/$JAR_NAME" "$ROOT/mods/$JAR_NAME"

for class_file in \
    "$ROOT/build/classes/clchunkfix/ChunkFix.class" \
    "$ROOT/build/classes/clchunkfix/core/WorldExtensionTransformer.class" \
    "$ROOT/build/classes/clchunkfix/core/WorldExtensionHooks.class" \
    "$ROOT/build/classes/clchunkfix/core/ChunkFixCorePlugin.class" \
    "$ROOT/build/classes/clchunkfix/core/InvTweaksTransformer.class" \
    "$ROOT/build/classes/clchunkfix/core/InvTweaksHooks.class" \
    "$ROOT/build/classes/clchunkfix/core/HqmTransformer.class" \
    "$ROOT/build/classes/clchunkfix/core/HqmHooks.class" \
    "$ROOT/build/classes/clchunkfix/core/ItemRenderTransformer.class"; do
    MAJOR="$(od -An -t u1 -j 6 -N 2 "$class_file" | awk '{print $2}')"
    if [ "$MAJOR" != "51" ]; then
        echo "Unexpected class major version in $class_file: $MAJOR (expected 51/Java 7)" >&2
        exit 1
    fi
done

echo "Built: $ROOT/mods/$JAR_NAME"
echo "Class major version: 51"
if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$ROOT/mods/$JAR_NAME"
else
    shasum -a 256 "$ROOT/mods/$JAR_NAME"
fi
