# Known issues and upstream reports

Last updated: 2026-11-23.

This page separates the fixed crash/performance bugs from harmless log noise.
The public issue tracker is:

https://github.com/guilhermeheats/crash-fixes/issues

## Fixed in `crash-fixes`

| Issue | Cause | Fixed by |
|---|---|---|
| [#1 HQM freezes on item pickup](https://github.com/guilhermeheats/crash-fixes/issues/1) | HQM 4.0.5 calls `OreDictionary.getOreID` for every inventory/quest item comparison; the ore dictionary scan stalls the integrated server | `clchunkfix-1.4.jar` per-`ItemStack` cache |
| [#2 Inventory Tweaks stale container click](https://github.com/guilhermeheats/crash-fixes/issues/2) | Client chest GUI is stale; server is on `ContainerPlayer` (45 slots) and Inventory Tweaks sends slot 55, crashing the server | `clchunkfix-1.3.jar` click validation + stale GUI close |
| [#3 CodeChickenLib `preTick` NPE](https://github.com/guilhermeheats/crash-fixes/issues/3) | A world is ticked without a `WorldExtensionManager.worldMap` entry | `clchunkfix-1.2.jar` on-demand extension set / empty fallback |

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
- This is a Crash Landing pack asset issue. `crash-fixes` does not redistribute or patch pack assets.

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
- `Can't keep up!` was the HQM pickup issue; it should not recur with `clchunkfix-1.4.jar`.
- `Memory connection overburdened` was observed with the stale Inventory Tweaks GUI; the `1.3` guard prevents the invalid click/crash path.

If a new crash appears, include:

1. the full `crash-reports/*.txt`;
2. the tail of `ForgeModLoader-client-0.log`;
3. whether it happens in a fresh world or only in the current save;
4. the `clchunkfix` version from `mods/`.
