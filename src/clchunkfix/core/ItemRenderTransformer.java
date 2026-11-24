package clchunkfix.core;

import net.minecraft.launchwrapper.IClassTransformer;
import org.objectweb.asm.ClassReader;
import org.objectweb.asm.ClassWriter;
import org.objectweb.asm.Opcodes;
import org.objectweb.asm.tree.ClassNode;
import org.objectweb.asm.tree.InsnList;
import org.objectweb.asm.tree.InsnNode;
import org.objectweb.asm.tree.JumpInsnNode;
import org.objectweb.asm.tree.LabelNode;
import org.objectweb.asm.tree.LdcInsnNode;
import org.objectweb.asm.tree.MethodNode;
import org.objectweb.asm.tree.VarInsnNode;

import java.util.Iterator;

/**
 * Raises the client-side render distance of dropped item entities.
 *
 * Minecraft 1.6.4 culls every entity with:
 *
 *     distance^2 < (boundingBox.getAverageEdgeLength() * 64 * renderDistanceWeight)^2
 *
 * EntityItem's bounding box is 0.25 blocks, so the vanilla cutoff is
 * 0.25 * 64 = 16 blocks. The server already tracks item entities up to
 * 64 blocks, so the item is present on the client but never rendered beyond
 * 16 blocks. This transformer adds an override of
 * Entity.isInRangeToRenderDist(double) to EntityItem that keeps items
 * visible up to 64 blocks.
 *
 * This is a visual change only: pickup range, physics, despawn and server
 * tracking are untouched.
 */
public class ItemRenderTransformer implements IClassTransformer {

    private static final String TARGET = "net.minecraft.entity.item.EntityItem";
    private static final String OBF_TARGET = "ss";
    private static final String NAMED_ENTITY = "net/minecraft/entity/Entity";
    private static final String OBF_ENTITY = "nn";
    private static final String NAMED_METHOD = "func_70112_a";
    private static final String OBF_METHOD = "a";
    private static final String PROPERTY = "clchunkfix.itemRenderDistance";
    private static final double DEFAULT_DISTANCE = 64.0D;
    private static final double MIN_DISTANCE = 16.0D;
    private static final double MAX_DISTANCE = 64.0D;
    // The server tracks items 64 blocks from the player's position, but the
    // client measures from the camera (about 1.6 blocks above the feet). Keep
    // a one-block margin so items at the tracking edge are still rendered.
    private static final double CAMERA_MARGIN = 1.0D;

    @Override
    public byte[] transform(String name, String transformedName, byte[] basicClass) {
        if (basicClass == null) {
            return null;
        }
        if (!TARGET.equals(name) && !TARGET.equals(transformedName)
                && !OBF_TARGET.equals(name) && !OBF_TARGET.equals(transformedName)) {
            return basicClass;
        }

        ClassReader reader = new ClassReader(basicClass);
        ClassNode node = new ClassNode();
        reader.accept(node, 0);

        boolean named = isNamedClass(node);
        String methodName = named ? NAMED_METHOD : OBF_METHOD;

        // Replace an existing override instead of adding a duplicate method.
        for (Iterator it = node.methods.iterator(); it.hasNext(); ) {
            MethodNode existing = (MethodNode) it.next();
            if (methodName.equals(existing.name) && "(D)Z".equals(existing.desc)) {
                it.remove();
            }
        }

        double distance = configuredDistance();
        double renderDistance = distance + CAMERA_MARGIN;
        double limitSq = renderDistance * renderDistance;

        MethodNode method = new MethodNode(
                Opcodes.ACC_PUBLIC,
                methodName,
                "(D)Z",
                null,
                null);
        LabelNode outside = new LabelNode();
        InsnList code = method.instructions;
        code.add(new VarInsnNode(Opcodes.DLOAD, 1));
        code.add(new LdcInsnNode(Double.valueOf(limitSq)));
        code.add(new InsnNode(Opcodes.DCMPG));
        code.add(new JumpInsnNode(Opcodes.IFGE, outside));
        code.add(new InsnNode(Opcodes.ICONST_1));
        code.add(new InsnNode(Opcodes.IRETURN));
        code.add(outside);
        code.add(new InsnNode(Opcodes.ICONST_0));
        code.add(new InsnNode(Opcodes.IRETURN));
        method.maxStack = 2;
        method.maxLocals = 3;
        node.methods.add(method);

        ClassWriter writer = new ClassWriter(ClassWriter.COMPUTE_MAXS);
        node.accept(writer);
        System.out.println("[CLWorldFix] Patched dropped-item render distance to "
                + distance + " blocks (+" + CAMERA_MARGIN + " camera margin, "
                + methodName + ").");
        return writer.toByteArray();
    }

    /**
     * The class is deobfuscated if its own name/superclass use named classes,
     * or if its methods use FML's func_* names. Handle both forms so the
     * transformer works regardless of when FML's deobfuscation runs.
     */
    private static boolean isNamedClass(ClassNode node) {
        if (TARGET.equals(node.name) || NAMED_ENTITY.equals(node.superName)) {
            return true;
        }
        if (OBF_TARGET.equals(node.name) || OBF_ENTITY.equals(node.superName)) {
            return false;
        }
        for (Object entry : node.methods) {
            MethodNode method = (MethodNode) entry;
            if (method.name != null && method.name.startsWith("func_")) {
                return true;
            }
        }
        return false;
    }

    private static double configuredDistance() {
        String raw = System.getProperty(PROPERTY);
        if (raw == null || raw.trim().length() == 0) {
            return DEFAULT_DISTANCE;
        }
        try {
            double value = Double.parseDouble(raw.trim());
            if (Double.isNaN(value) || Double.isInfinite(value)) {
                return warnDefault(raw);
            }
            if (value < MIN_DISTANCE) {
                System.out.println("[CLWorldFix] itemRenderDistance " + raw
                        + " is below " + MIN_DISTANCE + "; using " + MIN_DISTANCE + ".");
                return MIN_DISTANCE;
            }
            if (value > MAX_DISTANCE) {
                System.out.println("[CLWorldFix] itemRenderDistance " + raw
                        + " is above the server tracking limit; using " + MAX_DISTANCE + ".");
                return MAX_DISTANCE;
            }
            return value;
        } catch (NumberFormatException e) {
            return warnDefault(raw);
        }
    }

    private static double warnDefault(String raw) {
        System.out.println("[CLWorldFix] Invalid itemRenderDistance '" + raw
                + "'; using " + DEFAULT_DISTANCE + ".");
        return DEFAULT_DISTANCE;
    }
}
