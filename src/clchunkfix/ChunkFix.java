package clchunkfix;

import cpw.mods.fml.common.FMLCommonHandler;
import cpw.mods.fml.common.Loader;
import cpw.mods.fml.common.Mod;
import cpw.mods.fml.common.ModContainer;
import cpw.mods.fml.common.event.FMLServerStartedEvent;
import cpw.mods.fml.common.event.FMLServerStoppedEvent;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.Map;

/**
 * Crash Landing 1.1.3 world-switch fixes.
 *
 * The pack keeps several pieces of world state in memory when the player
 * returns to the title screen. When a hardcore world is deleted and another
 * one is created in the same game session, those stale references point at
 * the deleted world directory. This tiny mod resets them when the integrated
 * server stops, so the next world starts cleanly.
 *
 * Fixes:
 *  - ChickenChunks 1.3.3.4: stale saveDir -> loginTimes.dat crash
 *  - Ruins 11.0: stale generatorMap -> writes/loads RuinsPositionsFile.txt
 *    from the previous world
 *  - CodeChickenLib 1.0.0.62: a world ticked without a worldMap entry
 *    -> NullPointerException in WorldExtensionManager.preTick, which stops
 *    the integrated server tick loop (frozen mobs, chests not opening)
 *  - Inventory Tweaks 1.56: a stale chest GUI sends a click for a slot that
 *    no longer exists on the server -> IndexOutOfBoundsException in
 *    Container.clickSlot, which also stops the integrated server
 *  - Hardcore Questing Mode 4.0.5: every item pickup compares against every
 *    quest item and calls OreDictionary.getOreID, which scans the whole ore
 *    dictionary and can stall the integrated server for seconds
 *  - EntityItem: the client culls dropped items at 16 blocks even though the
 *    server tracks them up to 64, so mob drops disappear at short range
 *  - Integrated server: the default server view distance is 10 chunks while
 *    the client can render Far (16), leaving a band of unloaded chunks at the
 *    edge; raise the server view distance to 16 on server start
 */
@Mod(modid = "clchunkfix", name = "Crash Landing World Switch Fixes", version = "1.6")
public class ChunkFix {

    @Mod.EventHandler
    public void onServerStarted(FMLServerStartedEvent event) {
        if (!FMLCommonHandler.instance().getSide().isClient()) {
            return;
        }
        try {
            Object fml = FMLCommonHandler.instance();
            Object server = fml.getClass().getMethod("getMinecraftServerInstance").invoke(fml);
            if (server == null) {
                System.out.println("[CLWorldFix] No integrated server instance; skipping view distance.");
                return;
            }

            Method getConfigurationManager = null;
            for (Method method : server.getClass().getMethods()) {
                if (method.getParameterTypes().length == 0
                        && method.getReturnType().getName().endsWith("ServerConfigurationManager")) {
                    getConfigurationManager = method;
                    break;
                }
            }
            if (getConfigurationManager == null) {
                System.out.println("[CLWorldFix] Could not find server configuration manager.");
                return;
            }

            Object manager = getConfigurationManager.invoke(server);
            Field viewDistance = null;
            for (Field field : manager.getClass().getDeclaredFields()) {
                if (field.getType() == int.class
                        && ("field_72402_d".equals(field.getName()) || "c".equals(field.getName()))) {
                    viewDistance = field;
                    break;
                }
            }
            if (viewDistance == null) {
                System.out.println("[CLWorldFix] Could not find server view distance field.");
                return;
            }

            int chunks = configuredServerViewDistance();
            viewDistance.setAccessible(true);
            // ServerConfigurationManager stores viewDistance + 1; PlayerManager
            // converts it back to (viewDistance) * 16 blocks.
            viewDistance.setInt(manager, chunks + 1);
            System.out.println("[CLWorldFix] Set integrated-server view distance to "
                    + chunks + " chunks.");
        } catch (Throwable t) {
            System.out.println("[CLWorldFix] Could not set server view distance: " + t);
        }
    }

    @Mod.EventHandler
    public void onServerStopped(FMLServerStoppedEvent event) {
        resetChickenChunks();
        resetRuins();
    }

    private static int configuredServerViewDistance() {
        int chunks = 16;
        String raw = System.getProperty("clchunkfix.serverViewDistance");
        if (raw != null) {
            try {
                chunks = Integer.parseInt(raw.trim());
            } catch (NumberFormatException e) {
                System.out.println("[CLWorldFix] Invalid serverViewDistance '" + raw
                        + "'; using 16.");
                chunks = 16;
            }
        }
        if (chunks < 3) {
            chunks = 3;
        }
        if (chunks > 16) {
            chunks = 16;
        }
        return chunks;
    }

    private void resetChickenChunks() {
        try {
            Class<?> manager = Class.forName("codechicken.chunkloader.ChunkLoaderManager");
            manager.getMethod("serverShutdown").invoke(null);
            System.out.println("[CLWorldFix] ChickenChunks reset for the next world.");
        } catch (Throwable t) {
            System.out.println("[CLWorldFix] Could not reset ChickenChunks: " + t);
        }
    }

    private void resetRuins() {
        try {
            ModContainer container = Loader.instance().getIndexedModList().get("AS_Ruins");
            if (container == null) {
                System.out.println("[CLWorldFix] Ruins mod not present; skipping reset.");
                return;
            }

            Object ruins = container.getMod();
            if (ruins == null) {
                System.out.println("[CLWorldFix] Ruins instance unavailable; skipping reset.");
                return;
            }

            Field field = ruins.getClass().getDeclaredField("generatorMap");
            field.setAccessible(true);
            Object value = field.get(ruins);
            if (value instanceof Map) {
                ((Map<?, ?>) value).clear();
                System.out.println("[CLWorldFix] Ruins world handles reset for the next world.");
            } else {
                System.out.println("[CLWorldFix] Ruins generatorMap is not a Map; skipping reset.");
            }
        } catch (Throwable t) {
            System.out.println("[CLWorldFix] Could not reset Ruins: " + t);
        }
    }
}
