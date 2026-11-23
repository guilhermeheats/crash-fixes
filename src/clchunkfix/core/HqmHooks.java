package clchunkfix.core;

import java.lang.reflect.Method;
import java.util.Collections;
import java.util.Map;
import java.util.WeakHashMap;

/**
 * Caches Hardcore Questing Mode's OreDictionary lookups.
 *
 * HQM 4.0.5 compares every picked-up item against every quest item using
 * ItemPrecision.ORE_DICTIONARY. Each comparison calls
 * OreDictionary.getOreID(ItemStack), which scans the whole ore dictionary.
 * With a large inventory/quest list this blocks the integrated server thread
 * for seconds. The ore ID is stable for an ItemStack, so cache it by stack.
 */
public final class HqmHooks {

    private static final Map<Object, Integer> CACHE =
            Collections.synchronizedMap(new WeakHashMap<Object, Integer>());
    private static Method getOreId;
    private static boolean resolved;
    private static boolean loggedFailure;

    private HqmHooks() {
    }

    /**
     * Replacement for OreDictionary.getOreID(ItemStack) used by HQM.
     */
    public static int oreId(Object stack) {
        if (stack == null) {
            return -1;
        }
        Integer cached = CACHE.get(stack);
        if (cached != null) {
            return cached;
        }

        int id = -1;
        try {
            if (!resolved) {
                resolve();
            }
            if (getOreId != null) {
                Object value = getOreId.invoke(null, stack);
                if (value instanceof Integer) {
                    id = (Integer) value;
                }
            }
        } catch (Throwable t) {
            if (!loggedFailure) {
                loggedFailure = true;
                System.out.println("[CLWorldFix] Could not cache HQM OreDictionary lookup: " + t);
            }
        }
        CACHE.put(stack, id);
        return id;
    }

    private static synchronized void resolve() {
        if (resolved) {
            return;
        }
        resolved = true;
        try {
            Class<?> oreDictionary = Class.forName("net.minecraftforge.oredict.OreDictionary");
            Class<?> itemStack = Class.forName("net.minecraft.item.ItemStack");
            getOreId = oreDictionary.getMethod("getOreID", itemStack);
        } catch (Throwable t) {
            System.out.println("[CLWorldFix] Could not resolve HQM OreDictionary method: " + t);
        }
    }
}
