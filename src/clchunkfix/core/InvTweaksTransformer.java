package clchunkfix.core;

import net.minecraft.launchwrapper.IClassTransformer;
import org.objectweb.asm.ClassReader;
import org.objectweb.asm.ClassWriter;
import org.objectweb.asm.Opcodes;
import org.objectweb.asm.Type;
import org.objectweb.asm.tree.ClassNode;
import org.objectweb.asm.tree.InsnList;
import org.objectweb.asm.tree.InsnNode;
import org.objectweb.asm.tree.JumpInsnNode;
import org.objectweb.asm.tree.LabelNode;
import org.objectweb.asm.tree.MethodInsnNode;
import org.objectweb.asm.tree.MethodNode;
import org.objectweb.asm.tree.VarInsnNode;

/**
 * Adds a stale-container guard to Inventory Tweaks 1.56's server packet
 * handler. The original handler blindly calls Container.clickSlot with a
 * client-supplied slot id; an out-of-range id crashes the integrated server.
 */
public class InvTweaksTransformer implements IClassTransformer {

    private static final String TARGET = "invtweaks.forge.PacketHandler";
    private static final String HOOK = "clchunkfix/core/InvTweaksHooks";

    @Override
    public byte[] transform(String name, String transformedName, byte[] basicClass) {
        if (basicClass == null) {
            return null;
        }
        if (!TARGET.equals(name) && !TARGET.equals(transformedName)) {
            return basicClass;
        }

        ClassReader reader = new ClassReader(basicClass);
        ClassNode node = new ClassNode();
        reader.accept(node, 0);

        boolean patched = false;
        for (Object entry : node.methods) {
            MethodNode method = (MethodNode) entry;
            if (!"onClickPacket".equals(method.name)) {
                continue;
            }
            if (Type.getArgumentTypes(method.desc).length != 3) {
                continue;
            }
            if (!Type.getReturnType(method.desc).equals(Type.VOID_TYPE)) {
                continue;
            }

            LabelNode original = new LabelNode();
            InsnList guard = new InsnList();
            guard.add(new VarInsnNode(Opcodes.ALOAD, 3));
            guard.add(new VarInsnNode(Opcodes.ALOAD, 2));
            guard.add(new MethodInsnNode(
                    Opcodes.INVOKESTATIC,
                    HOOK,
                    "allowClick",
                    "(Ljava/lang/Object;[B)Z"));
            guard.add(new JumpInsnNode(Opcodes.IFNE, original));
            guard.add(new InsnNode(Opcodes.RETURN));
            guard.add(original);
            method.instructions.insert(guard);
            patched = true;
        }

        if (!patched) {
            return basicClass;
        }

        ClassWriter writer = new ClassWriter(ClassWriter.COMPUTE_MAXS);
        node.accept(writer);
        System.out.println("[CLWorldFix] Patched Inventory Tweaks container click guard.");
        return writer.toByteArray();
    }
}
