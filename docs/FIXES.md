# Technical fixes

Target: **Crash Landing 1.1.3**, Minecraft 1.6.4, Forge 9.11.1.965, Java 8, any launcher that can run the pack.

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

Fix: `clchunkfix-1.5.jar` listens for `FMLServerStoppedEvent` and calls the public `ChunkLoaderManager.serverShutdown()`. The next world load recalculates its `saveDir`.

## 3. Ruins `RuinsPositionsFile.txt`

Symptom:

```text
java.io.FileNotFoundException: .../saves/Crash Landing 3/RuinsPositionsFile.txt (No such file or directory)
```

Cause: Ruins 11.0 caches `WorldHandle`/`RuinGenerator` instances per dimension in `generatorMap`. After a world switch, the new world reuses the old generator and points to the deleted world's positions file.

Fix: `clchunkfix-1.5.jar` clears the private `generatorMap` of `atomicstryker.ruins.common.RuinsMod` on `FMLServerStopped`. The next world creates fresh handlers.

Expected log after stopping a world:

```text
[CLWorldFix] ChickenChunks reset for the next world.
[CLWorldFix] Ruins world handles reset for the next world.
```

## 4. CodeChickenLib `WorldExtensionManager.preTick` NPE

Symptom:

```text
Description: Exception in server tick loop
java.lang.NullPointerException
    at codechicken.lib.world.WorldExtensionManager.preTick(WorldExtensionManager.java:239)
    at codechicken.lib.world.WorldExtensionManager$WorldExtensionServerTickHandler.tickStart(WorldExtensionManager.java:160)
```

In game this looks like a frozen world: mobs stop moving and chests no longer open, because the integrated server tick loop has stopped. It can happen after a chunk/chest interaction in a world that CodeChickenLib is still ticking but that has no entry in its static `worldMap`.

Cause: CodeChickenLib 1.0.0.62 iterates `worldMap.get(world)` without a null check. The map is populated by `WorldEvent.Load`; if a world tick arrives without that entry (or after it was removed), the loop throws.

Fix: `clchunkfix-1.5.jar` contains a small coremod. It injects a guard at the start of `preTick`/`postTick`; the guard creates the missing `WorldExtension[]` through CodeChickenLib's own `onWorldLoad`, or installs an empty array if that fails. The server keeps ticking instead of crashing. The guard logs one of:

```text
[CLWorldFix] Created missing CodeChickenLib world extensions on demand.
[CLWorldFix] Installed an empty CodeChickenLib extension set for a world that missed WorldEvent.Load.
```

The guard is defensive; it does not change chunk-loader behavior, recipes, mobs, loot or world data.

## 5. Inventory Tweaks stale container click

Symptom:

```text
Description: Ticking memory connection
java.lang.IndexOutOfBoundsException: Index: 55, Size: 45
    at net.minecraft.inventory.Container.func_75144_a(SourceFile:207)
    at invtweaks.forge.PacketHandler.onClickPacket(PacketHandler.java:46)
```

In game this appears as a lagging/desynchronised chest: blocks and items roll back, item pickup is delayed, and the chest GUI stops responding. The integrated server has already returned to the player inventory (45 slots), but the client still has a chest GUI open and Inventory Tweaks sends a click for a chest/player slot that no longer exists.

Fix: `clchunkfix-1.5.jar` adds a coremod guard at the start of `PacketHandler.onClickPacket`. It reads the requested slot from the packet, compares it with the server container size, and drops the click if it is out of range. It also closes the stale GUI so the next interaction reopens the chest cleanly.

Expected log when an invalid click is blocked:

```text
[CLWorldFix] Blocked Inventory Tweaks click for slot 55 (server container has 45 slots); closing the stale GUI.
```

## 6. HQM OreDictionary pickup lag

Symptom:

```text
"Server thread" ... RUNNABLE
    at net.minecraftforge.oredict.OreDictionary.getOreID
    at hardcorequesting.quests.ItemPrecision$4.same
    at hardcorequesting.quests.QuestTaskItemsDetect.countItems
    at hardcorequesting.quests.QuestTaskItemsDetect.onPickUp
```

In game: the world freezes when many items are on the ground, especially after
breaking full chests. Mobs stop moving, chest GUIs open late, item pickup is
delayed and eating never completes.

Cause: HQM 4.0.5 checks every picked-up item against every quest item. For
OreDictionary precision it calls `OreDictionary.getOreID` for each comparison;
that method scans the entire ore dictionary. A large inventory plus many quest
items makes the server thread spend seconds in this loop.

Fix: `clchunkfix-1.5.jar` replaces HQM's direct `getOreID` calls with a
per-`ItemStack` weak cache. The first lookup is unchanged; repeated comparisons
of the same stack are constant-time. Quest definitions, progress and matching
semantics are unchanged.

## 7. CustomChestLoot configs

Symptom:

```text
[CustomChestLoot] Invalid number of arguments! @.../bonusChest.txt
```

Cause: `contents=` lists are wrapped over multiple lines without a backslash. Java Properties reads only the first line and treats the rest as invalid keys.

Fix: `scripts/fix-customchestloot.py` / `fix-customchestloot.ps1` join only the continuation lines. IDs, metadata, weights and quantities are unchanged.

## 8. Obsolete update checks / radio

Crash Landing is a 2015 pack. Several mods try to contact dead update/radio endpoints, causing timeouts and log noise.

Fix: `scripts/cleanup-network-checks.py` / `.ps1` disable only update/version checks and the OpenBlocks radio station list. No recipes, loot, difficulty, hunger, mobs, world settings or chunk loaders are touched.

CoFH/Thermal Expansion may still log two `403` version-check lines; their mod has no config switch for that request. It is harmless.

## 9. Dropped-item render distance

Symptom: dropped items and mob drops are only visible when the player is very
close (about 16 blocks); they disappear at distance even though the server
still tracks them.

Cause: Minecraft 1.6.4 culls every entity with:

```text
distance^2 < (boundingBox.getAverageEdgeLength() * 64 * renderDistanceWeight)^2
```

`EntityItem` has a 0.25-block hitbox, so the client cutoff is
`0.25 * 64 = 16` blocks. The server's `EntityTracker` already sends item
entities within 64 blocks, so the item is present on the client but never
rendered beyond 16 blocks.

Fix: `clchunkfix-1.5.jar` adds a coremod override of
`EntityItem.func_70112_a(D)Z` (the SRG name of `isInRangeToRenderDist`; the
transformer also handles the pre-deobfuscation `a(D)Z`). The override keeps
items visible up to the 64-block server tracking limit plus a 1-block margin
for the camera height.

Expected log:

```text
[CLWorldFix] Patched dropped-item render distance to 64.0 blocks (+1.0 camera margin, a).
```

The method name in parentheses is `a` when the transformer runs before FML
deobfuscation and `func_70112_a` otherwise; both forms are handled.

Optional tuning: add `-Dclchunkfix.itemRenderDistance=48` to the JVM arguments
(allowed range 16–64, default 64). The client cutoff is the value plus 1 block.

This is visual only. Pickup range, physics, despawn, server tracking and world
data are unchanged. The server still sends item entities only within 64 blocks,
so a higher client value has no effect.

## What is intentionally not changed

- No world backup; the hardcore deletion is part of the pack.
- No AromaBackup or similar.
- No OptiFine/FastCraft/BetterFPS/FpsPlus.
- No mod updates or Forge updates.
- No gameplay/QoL mods.
- The EnderIO MineTweaker script is kept: `config/minetweaker/main.cfg` includes it. Removing it causes `Could not process scripts`.
