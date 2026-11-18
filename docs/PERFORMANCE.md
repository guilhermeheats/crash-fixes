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

Crash Landing is mostly CPU/mod-bound. The 2015 rendering and entity logic dominate; the GPU is rarely the limiting factor at normal render distances.

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
- Use the discrete GPU on hybrid laptops (`UseDiscreteGpu` in Prism or `DRI_PRIME=1` on Linux).
- Close background applications; the instance uses a 4 GB heap.
- Do not raise the heap above 5 GB without evidence; larger heaps can increase GC pauses.

## Hardcore fidelity

No world backup, no AromaBackup, no gameplay/QoL mods and no mod/Forge updates are part of this project.
