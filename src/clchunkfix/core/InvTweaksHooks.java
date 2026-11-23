package clchunkfix.core;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.nio.ByteBuffer;
import java.util.List;

/**
 * Guards Inventory Tweaks 1.56 against stale container clicks.
 *
 * Inventory Tweaks sends a custom packet when it wants to click a slot on the
 * server. If the client still has a chest GUI open while the server has
 * already returned to the player inventory, the slot index is outside the
 * server container and Container.clickSlot throws IndexOutOfBoundsException,
 * killing the integrated server tick loop.
 */
public final class InvTweaksHooks {

    private static boolean loggedInvalid;
    private static boolean loggedFailure;
    private static Field openContainerField;
    private static Field inventorySlotsField;
    private static Method closeScreenMethod;
    private static boolean resolved;
    private static boolean resolutionFailed;

    private InvTweaksHooks() {
    }

    /**
     * Called at the start of Inventory Tweaks' onClickPacket.
     *
     * @param player the EntityPlayerMP passed to the packet handler
     * @param data   the custom payload bytes
     * @return true to let the original click run, false to drop it
     */
    public static boolean allowClick(Object player, byte[] data) {
        if (player == null || data == null || data.length < 5 || data[0] != 1) {
            return true;
        }

        int slot = ByteBuffer.wrap(data, 1, 4).getInt();
        try {
            if (!resolved) {
                resolve(player);
            }
            if (resolutionFailed || openContainerField == null || inventorySlotsField == null) {
                return true;
            }

            Object container = openContainerField.get(player);
            if (container == null) {
                return true;
            }
            Object slots = inventorySlotsField.get(container);
            if (!(slots instanceof List)) {
                return true;
            }

            int size = ((List<?>) slots).size();
            if (slot >= 0 && slot < size) {
                return true;
            }

            if (!loggedInvalid) {
                loggedInvalid = true;
                System.out.println("[CLWorldFix] Blocked Inventory Tweaks click for slot " + slot
                        + " (server container has " + size + " slots); closing the stale GUI.");
            }
            closeScreen(player);
            return false;
        } catch (Throwable t) {
            if (!loggedFailure) {
                loggedFailure = true;
                System.out.println("[CLWorldFix] Could not validate an Inventory Tweaks click: " + t);
            }
            return true;
        }
    }

    private static void resolve(Object player) {
        resolved = true;
        Class<?> type = player.getClass();

        openContainerField = findField(type, "field_71070_bA", "openContainer");
        if (openContainerField == null) {
            openContainerField = findFieldByTypeName(type, "net.minecraft.inventory.Container");
        }

        Class<?> containerType = openContainerField == null ? null : openContainerField.getType();
        if (containerType != null) {
            inventorySlotsField = findField(containerType, "field_75151b", "inventorySlots");
            if (inventorySlotsField == null) {
                inventorySlotsField = findListField(containerType);
            }
        }

        closeScreenMethod = findMethod(type, "closeScreen", "func_71053_j");
        if (openContainerField == null || inventorySlotsField == null) {
            resolutionFailed = true;
        }
    }

    private static Field findField(Class<?> type, String... names) {
        for (Class<?> current = type; current != null; current = current.getSuperclass()) {
            for (String name : names) {
                try {
                    Field field = current.getDeclaredField(name);
                    field.setAccessible(true);
                    return field;
                } catch (NoSuchFieldException ignored) {
                }
            }
        }
        return null;
    }

    private static Field findFieldByTypeName(Class<?> type, String typeName) {
        for (Class<?> current = type; current != null; current = current.getSuperclass()) {
            for (Field field : current.getDeclaredFields()) {
                if (field.getType().getName().equals(typeName)) {
                    field.setAccessible(true);
                    return field;
                }
            }
        }
        return null;
    }

    private static Field findListField(Class<?> type) {
        for (Class<?> current = type; current != null; current = current.getSuperclass()) {
            for (Field field : current.getDeclaredFields()) {
                if (List.class.isAssignableFrom(field.getType())) {
                    field.setAccessible(true);
                    return field;
                }
            }
        }
        return null;
    }

    private static Method findMethod(Class<?> type, String... names) {
        for (Class<?> current = type; current != null; current = current.getSuperclass()) {
            for (String name : names) {
                try {
                    Method method = current.getDeclaredMethod(name);
                    method.setAccessible(true);
                    return method;
                } catch (NoSuchMethodException ignored) {
                }
            }
        }
        return null;
    }

    private static void closeScreen(Object player) {
        if (closeScreenMethod == null) {
            return;
        }
        try {
            closeScreenMethod.invoke(player);
        } catch (Throwable t) {
            if (!loggedFailure) {
                loggedFailure = true;
                System.out.println("[CLWorldFix] Could not close the stale Inventory Tweaks GUI: " + t);
            }
        }
    }
}
