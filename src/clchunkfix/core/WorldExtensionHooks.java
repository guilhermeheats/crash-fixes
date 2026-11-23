package clchunkfix.core;

import java.lang.reflect.Array;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.Map;

/**
 * Runtime hooks used by the transformed CodeChickenLib methods.
 *
 * Kept deliberately small and reflection-based so the fix does not need to
 * link against CodeChickenLib at compile time.
 */
public final class WorldExtensionHooks {

    private static boolean initialized;
    private static boolean loggedOnDemand;
    private static boolean loggedEmpty;
    private static boolean loggedFailure;
    private static Field worldMapField;
    private static Method onWorldLoad;
    private static Class<?> extensionClass;
    private static Map<Object, Object> worldMap;

    private WorldExtensionHooks() {
    }

    private static synchronized void init() {
        if (initialized) {
            return;
        }
        initialized = true;
        try {
            Class<?> manager = Class.forName("codechicken.lib.world.WorldExtensionManager");
            worldMapField = manager.getDeclaredField("worldMap");
            worldMapField.setAccessible(true);
            worldMap = (Map<Object, Object>) worldMapField.get(null);
            extensionClass = Class.forName("codechicken.lib.world.WorldExtension");

            for (Method method : manager.getDeclaredMethods()) {
                if ("onWorldLoad".equals(method.getName()) && method.getParameterTypes().length == 1) {
                    method.setAccessible(true);
                    onWorldLoad = method;
                    break;
                }
            }
        } catch (Throwable t) {
            logFailure("initialise", t);
        }
    }

    /**
     * Called from the start of WorldExtensionManager.preTick/postTick.
     *
     * The original code assumes that every ticked World has an entry in the
     * static worldMap. If it does not, install a real extension set when
     * possible, or an empty set as a safe fallback. This prevents a null
     * iteration from stopping the integrated server.
     */
    public static void ensureWorld(Object world) {
        if (world == null) {
            return;
        }
        if (!initialized) {
            init();
        }
        if (worldMap == null || extensionClass == null) {
            return;
        }

        try {
            Object current = worldMap.get(world);
            if (isValidExtensionArray(current)) {
                return;
            }
            if (current != null) {
                worldMap.remove(world);
            }

            boolean created = false;
            if (onWorldLoad != null) {
                try {
                    onWorldLoad.invoke(null, world);
                    created = true;
                } catch (Throwable t) {
                    worldMap.remove(world);
                    logFailure("create world extensions", t);
                }
            }

            Object extensions = worldMap.get(world);
            if (!isValidExtensionArray(extensions)) {
                if (extensions != null) {
                    worldMap.remove(world);
                }
                Object empty = Array.newInstance(extensionClass, 0);
                worldMap.put(world, empty);
                if (!loggedEmpty) {
                    loggedEmpty = true;
                    System.out.println("[CLWorldFix] Installed an empty CodeChickenLib extension set for a world that missed WorldEvent.Load.");
                }
            } else if (created && !loggedOnDemand) {
                loggedOnDemand = true;
                System.out.println("[CLWorldFix] Created missing CodeChickenLib world extensions on demand.");
            }
        } catch (Throwable t) {
            logFailure("ensure world extensions", t);
        }
    }

    private static boolean isValidExtensionArray(Object value) {
        if (value == null || !value.getClass().isArray()) {
            return false;
        }
        int length = Array.getLength(value);
        for (int i = 0; i < length; i++) {
            if (Array.get(value, i) == null) {
                return false;
            }
        }
        return true;
    }

    private static void logFailure(String action, Throwable t) {
        if (!loggedFailure) {
            loggedFailure = true;
            System.out.println("[CLWorldFix] Could not " + action + " CodeChickenLib world extensions: " + t);
        }
    }
}
