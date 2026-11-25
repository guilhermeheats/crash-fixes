# Performance and OptiFine

## Current profile

The repository records the **max-fidelity** video profile:

- Render Distance: Far
- Graphics: Fancy
- Smooth Lighting: Maximum
- Clouds: on
- Particles: All
- VSync: on
- FPS limit: unlimited
- Advanced OpenGL: on
- Music: off
- Sound: on

Java:

```text
Java 8u202 64-bit
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
```

The recorded baseline is 4 GB. The Far + 16-chunk real session used
`-Xms6144m -Xmx6144m` (6144 MB); see the view-distance section.

Crash Landing is mostly CPU/mod-bound. The 2015 rendering and entity logic dominate; the GPU is rarely the limiting factor at normal render distances.

## Dropped-item render distance (1.5)

Vanilla 1.6.4 culls `EntityItem` at 16 blocks because its hitbox is 0.25 blocks
(`0.25 × 64`). The server already tracks items up to 64 blocks.
`clchunkfix-1.5.jar` raises the client cutoff to 64 blocks plus a 1-block camera
margin.

- This can render more item entities when many items are on the ground. The
  default is the same 64-block limit the server already uses.
- If FPS drops with large item piles, set
  `-Dclchunkfix.itemRenderDistance=48` (range 16–64). The actual client cutoff
  is the value plus 1 block.
- The change is visual only; pickup range, physics, despawn and server tracking
  are unchanged.

## Integrated-server Far view distance (1.8)

The client can render Far (16 chunks), but the integrated server's default view
distance is smaller (10 chunks). `clchunkfix-1.8.jar` raises it to 16 on server
start.

- 1.6 and 1.7 failed to find the field at runtime; the manager object is a
  subclass of `ServerConfigurationManager`, and the first attempts inspected
  only the concrete class. 1.8 walks the class hierarchy and sets
  `ServerConfigurationManager.field_72402_d` from `10` to `17`.
- No FPS limit; the client still renders at the selected framerate. The real
  `New World` test ran at 120 FPS with a 6144 MB heap.
- The trade-off is more chunk generation, loading and memory. For Far + 16
  chunks, use 6144 MB (the real test) and close the browser/background apps.
- Optional `-Dclchunkfix.serverViewDistance=8` lowers the server view distance;
  with the client still on Far, a band at 8 chunks would remain.
- Expected log:
  `[CLWorldFix] Set integrated-server view distance to 16 chunks (field ServerConfigurationManager.field_72402_d, 10 -> 17).`
- The real test showed F3 `C:` total `1081`, no `Can't keep up!` and no
  `Invalid blockID` after the load.

## `Can't keep up!` warnings

`Can't keep up!` was observed on 2026-11-24 at 20:27–20:28 in the real session.
A GC log from the test copy showed a maximum stop-the-world pause of 0.066 s at
startup, so the warnings were not a single long GC pause. They were transient
server-tick spikes; the pattern is consistent with chunk generation or mob
pathfinding. The real session was also at about 4.25 GB RSS with a 4 GB heap,
so GC pressure under load is likely to contribute. Use 6144 MB for Far/16
chunks and close background applications. In the 1.8 real `New World` test
with 6144 MB, no `Can't keep up!` line appeared after the load. No crash report
was created.

## OptiFine 1.6.4

**Not recommended and not included.**

Test performed: OptiFine 1.6.4 HD U C6 was placed in `mods` on an isolated copy of the instance. Forge Mod Loader ignored it: the jar is an installer/version jar with `Main-Class: optifine.InstallerFrame` and `TweakClass: optifine.OptiFineForgeTweaker`; FML does not load that tweaker from the `mods` folder as a normal mod.

To even load it, one would need to patch the Minecraft/Forge game jar or use the old OptiFineFML patch. That is:

- unofficial and outdated;
- still affected by known `VerifyError` issues in `EntityRenderer` on Forge 1.6.4;
- known to conflict with **ChickenChunks**, which Crash Landing depends on;
- prone to rendering conflicts with Tinkers' Construct and other mods;
- not guaranteed to improve FPS in 1.6.4 modded.

OptiFine's license also forbids modifying/redistributing the jar. See `docs/LEGAL.md`.

## Other performance mods

| Mod | 1.6.4 status | Recommendation |
|---|---|---|
| OptiFine | Installer/tweaker, Forge conflicts | Do not install |
| FastCraft | No real 1.6.4 release | Not applicable |
| BetterFPS | 1.7.10+ releases | Not applicable |
| FpsPlus | 1.6.4 file-overwrite, known armor texture bugs | Avoid |
| CoFHTweaks / ArchaicFix / CoreTweaks / FoamFix | 1.7.10+ | Not applicable |

## If more FPS is needed

- Lower Render Distance to Normal/Short.
- Test fullscreen vs windowed.
- Use the discrete GPU on hybrid laptops (the launcher's GPU option, or `DRI_PRIME=1` on Linux).
- Close background applications; the Far + 16-chunk profile uses 6144 MB, while
  4 GB is the baseline for lower render distances.
- Do not raise the heap above 6 GB without evidence; larger heaps can increase
  GC pauses.

## Hardcore fidelity

No world backup, no AromaBackup, no gameplay/QoL mods and no mod/Forge updates are part of this project.
