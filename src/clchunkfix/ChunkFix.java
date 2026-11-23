package clchunkfix;

import cpw.mods.fml.common.Loader;
import cpw.mods.fml.common.Mod;
import cpw.mods.fml.common.ModContainer;
import cpw.mods.fml.common.event.FMLServerStoppedEvent;

import java.lang.reflect.Field;
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
 */
@Mod(modid = "clchunkfix", name = "Crash Landing World Switch Fixes", version = "1.3")
public class ChunkFix {

    @Mod.EventHandler
    public void onServerStopped(FMLServerStoppedEvent event) {
        resetChickenChunks();
        resetRuins();
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
