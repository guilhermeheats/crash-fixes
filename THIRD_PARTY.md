# Third-party components

## LegacyJavaFixer 1.0

- File: `mods/legacyjavafixer-1.0.jar`
- Author: LexManos / MinecraftForge
- Source: https://github.com/MinecraftForge/LegacyJavaFixer
- License: MIT
- SHA-256: `056720325ac2c5031691fc2dbf9bd175cb0bc95d9ab6583b23fbace5b25c564a`
- Purpose: fix the `ConcurrentModificationException` in old FML/Forge on Java 8u20+.

## Crash Landing

- Not included. The pack is All Rights Reserved by its authors.
- Official source: https://www.curseforge.com/minecraft/modpacks/crash-landing
- The project only references the pack for compatibility; no pack archive, mods or world are redistributed.

## ChickenChunks, Ruins, CodeChickenLib, Inventory Tweaks and HQM

- Not included. They are part of the Crash Landing pack.
- `clchunkfix` uses the public `ChunkLoaderManager.serverShutdown()` method, reflection on Ruins' private `generatorMap`, and small ASM transformers that guard `CodeChickenLib`'s `WorldExtensionManager` world map, `Inventory Tweaks`' stale container clicks, and caches `Hardcore Questing Mode`'s OreDictionary lookups at runtime.
- The coremod references the ASM 4.1 API supplied by Forge/FML; it does not bundle or redistribute ASM.

## Full credits

See `CREDITS.md` for the pack team, every mod author, tooling and special thanks. This file only covers the third-party components that are directly relevant to the fixes.

## Minecraft and Forge

- Not redistributed. Minecraft is property of Mojang/Microsoft; Forge is property of its authors.

## OptiFine

- Not included. OptiFine is proprietary and its license prohibits modifying/redistributing it.
- This project does not provide an OptiFine fork or patched OptiFine jar.
