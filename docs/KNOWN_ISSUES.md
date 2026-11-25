# Known issues and upstream reports

Last updated: 2026-11-25.

This page separates the fixed crash/performance bugs from harmless log noise.
The public issue tracker is:

https://github.com/guilhermeheats/crash-fixes/issues

## Fixed in `crash-fixes`

| Issue | Cause | Fixed by |
|---|---|---|
| [#1 HQM freezes on item pickup](https://github.com/guilhermeheats/crash-fixes/issues/1) | HQM 4.0.5 calls `OreDictionary.getOreID` for every inventory/quest item comparison; the ore dictionary scan stalls the integrated server | `clchunkfix-1.4.jar` per-`ItemStack` cache (included in 1.8) |
| [#2 Inventory Tweaks stale container click](https://github.com/guilhermeheats/crash-fixes/issues/2) | Client chest GUI is stale; server is on `ContainerPlayer` (45 slots) and Inventory Tweaks sends slot 55, crashing the server | `clchunkfix-1.3.jar` click validation + stale GUI close |
| [#3 CodeChickenLib `preTick` NPE](https://github.com/guilhermeheats/crash-fixes/issues/3) | A world is ticked without a `WorldExtensionManager.worldMap` entry | `clchunkfix-1.2.jar` on-demand extension set / empty fallback |
| Dropped items invisible beyond ~16 blocks | `EntityItem` hitbox 0.25 → `0.25 × 64`; the server already tracks items at 64 blocks | `clchunkfix-1.5.jar` 64-block render override (included in 1.8) |
| Unloaded band at the edge with Far | Client Far (16 chunks) vs integrated-server default view distance (10 chunks) | `clchunkfix-1.8.jar` raises the server view distance to 16 on server start (1.6/1.7 failed field lookup) |

Upstream reports:

- HQM: https://github.com/lorddusk/HQM/issues/710
- CodeChickenLib: https://github.com/Chicken-Bones/CodeChickenLib/issues/61#issuecomment-7111703831
- Inventory Tweaks: the upstream repository is archived/read-only; the 1.56 report is documented in
  https://github.com/guilhermeheats/crash-fixes/issues/2

## Open pack asset issue

[#4 Ruins `farm.tml` invalid blockID 2261](https://github.com/guilhermeheats/crash-fixes/issues/4)

- File: `mods/resources/ruins/dust planet/farm.tml`
- Rule: `rule13=0,100,2261-2`
- Ruins falls back to block 0 (air), logs 12 warnings, and may leave holes in the structure.
- Local workaround (not redistributed): change `rule13` to `0,100,2763-4`
  (Chisel marble slab) in your own instance and keep a backup. This fills the
  2-block gap in new farms; existing farms keep the gap and can be filled
  manually.
- Verified locally: after the change, a new world produced 0 `Invalid blockID`
  warnings. The pack asset issue remains open upstream.
- This is a Crash Landing pack asset issue. `crash-fixes` does not redistribute
  or patch pack assets.

## Benign log messages

These appear in normal Crash Landing logs and are not crash causes:

- `java.lang.NullPointerException` during Rock Digger preInit; Rock Digger continues loading.
- `FileNotFoundException: .../sticks.txt` from an old update check.
- `UnknownHostException: skins.minecraft.net` when the skin service is unavailable.
- `Did not find any valid wall styles!` from structure generation.
- `MineTweaker /EnderIO.cfg: No item with id 8790`; EnderIO is disabled in the pack.
- `Waila [IC2] ClassNotFoundException`; IC2 is not installed.
- Missing textures from old mods (`MISSING_ICON_*`).
- `Realms: Server not available!`; Realms is not used.
- `Can't keep up!` was observed again on 2026-11-24 at 20:27–20:28 in the real session. A GC log from the test copy showed a maximum stop-the-world pause of 0.066 s at startup, so it was not a single long GC pause. It was a transient server-tick spike; the pattern is consistent with chunk generation or mob pathfinding. The real session was also at about 4.25 GB RSS with a 4 GB heap, so GC pressure under load is likely to contribute; use 6144 MB for Far/16 chunks and close background apps. In the 1.8 real `New World` test with 6144 MB, no `Can't keep up!` line appeared after the load. The HQM OreDictionary fix remains in place.
- `Memory connection overburdened` was observed with the stale Inventory Tweaks GUI; the `1.3` guard prevents the invalid click/crash path.

If a new crash appears, include:

1. the full `crash-reports/*.txt`;
2. the tail of `ForgeModLoader-client-0.log`;
3. whether it happens in a fresh world or only in the current save;
4. the `clchunkfix` version from `mods/`.
