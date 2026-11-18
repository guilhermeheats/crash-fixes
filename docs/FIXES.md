# Technical fixes

Target: **Crash Landing 1.1.3**, Minecraft 1.6.4, Forge 9.11.1.965, Java 8u202 64-bit, Prism Launcher 11.x.

## 1. LaunchWrapper `ConcurrentModificationException`

Symptom:

```text
[ForgeModLoader] Calling tweak class cpw.mods.fml.common.launcher.FMLInjectionAndSortingTweaker
[SEVERE] [ForgeModLoader] Unable to launch
java.util.ConcurrentModificationException
    at java.util.ArrayList$Itr.checkForComodification(ArrayList.java:909)
    at java.util.ArrayList$Itr.remove(ArrayList.java:873)
    at net.minecraft.launchwrapper.Launch.launch(Launch.java:114)
```

Cause: Java 8u20 changed `Collections.sort` (JDK-8032636). Old FML sorts LaunchWrapper's tweaker list while LaunchWrapper iterates it.

Fix: `legacyjavafixer-1.0.jar` from MinecraftForge/LexManos. It is loaded as a tweaker and replaces the broken sort. The log should contain:

```text
[LegacyJavaFixer] Replacing tweaker ... with net.minecraftforge.lex.legacyjavafixer.LegacyJavaFixer$SortReplacement
```

## 2. ChickenChunks `loginTimes.dat`

Symptom:

```text
Description: Exception in server tick loop
java.lang.RuntimeException: java.io.IOException: No such file or directory
    at codechicken.chunkloader.ChunkLoaderManager.updateLoginTimes(ChunkLoaderManager.java:891)
...
Caused by: java.io.IOException: No such file or directory
    at java.io.UnixFileSystem.createFileExclusively(Native Method)
    at java.io.File.createNewFile(File.java:1012)
    at codechicken.chunkloader.ChunkLoaderManager.updateLoginTimes(ChunkLoaderManager.java:878)
```

Cause: Crash Landing deletes the hardcore world on death. ChickenChunks stores the save directory in a static field. When a new world is created in the same game session, the old directory is used and the file creation fails.

Fix: `clchunkfix-1.1.jar` listens for `FMLServerStoppedEvent` and calls the public `ChunkLoaderManager.serverShutdown()`. The next world load recalculates its `saveDir`.

## 3. Ruins `RuinsPositionsFile.txt`

Symptom:

```text
java.io.FileNotFoundException: .../saves/Crash Landing 3/RuinsPositionsFile.txt (No such file or directory)
```

Cause: Ruins 11.0 caches `WorldHandle`/`RuinGenerator` instances per dimension in `generatorMap`. After a world switch, the new world reuses the old generator and points to the deleted world's positions file.

Fix: `clchunkfix-1.1.jar` clears the private `generatorMap` of `atomicstryker.ruins.common.RuinsMod` on `FMLServerStopped`. The next world creates fresh handlers.

Expected log after stopping a world:

```text
[CLWorldFix] ChickenChunks reset for the next world.
[CLWorldFix] Ruins world handles reset for the next world.
```

## 4. CustomChestLoot configs

Symptom:

```text
[CustomChestLoot] Invalid number of arguments! @.../bonusChest.txt
```

Cause: `contents=` lists are wrapped over multiple lines without a backslash. Java Properties reads only the first line and treats the rest as invalid keys.

Fix: `scripts/fix-customchestloot.py` / `fix-customchestloot.ps1` join only the continuation lines. IDs, metadata, weights and quantities are unchanged.

## 5. Obsolete update checks / radio

Crash Landing is a 2015 pack. Several mods try to contact dead update/radio endpoints, causing timeouts and log noise.

Fix: `scripts/cleanup-network-checks.py` / `.ps1` disable only update/version checks and the OpenBlocks radio station list. No recipes, loot, difficulty, hunger, mobs, world settings or chunk loaders are touched.

CoFH/Thermal Expansion may still log two `403` version-check lines; their mod has no config switch for that request. It is harmless.

## What is intentionally not changed

- No world backup; the hardcore deletion is part of the pack.
- No AromaBackup or similar.
- No OptiFine/FastCraft/BetterFPS/FpsPlus.
- No mod updates or Forge updates.
- No gameplay/QoL mods.
- The EnderIO MineTweaker script is kept: `config/minetweaker/main.cfg` includes it. Removing it causes `Could not process scripts`.
