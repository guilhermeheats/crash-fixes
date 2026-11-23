package clchunkfix.core;

import net.minecraft.launchwrapper.IClassTransformer;
import org.objectweb.asm.ClassReader;
import org.objectweb.asm.ClassWriter;
import org.objectweb.asm.Opcodes;
import org.objectweb.asm.tree.ClassNode;
import org.objectweb.asm.tree.InsnList;
import org.objectweb.asm.tree.MethodInsnNode;
import org.objectweb.asm.tree.MethodNode;
import org.objectweb.asm.tree.VarInsnNode;

/**
 * Adds a defensive world-extension lookup before CodeChickenLib's world tick.
 *
 * WorldExtensionManager.preTick does:
 *
 *     for (WorldExtension extension : worldMap.get(world)) {
 *         extension.preTick();
 *     }
 *
 * If a world is ticked without a matching WorldEvent.Load (or after its map
 * entry was removed), worldMap.get(world) is null and the server tick loop
 * crashes. The hook creates the missing entry, or installs an empty extension
 * set if creation fails, so the world can keep ticking.
 */
public class WorldExtensionTransformer implements IClassTransformer {

    private static final String TARGET = "codechicken.lib.world.WorldExtensionManager";
    private static final String HOOK = "clchunkfix/core/WorldExtensionHooks";

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
            if (!"preTick".equals(method.name) && !"postTick".equals(method.name)) {
                continue;
            }
            if (!method.desc.startsWith("(L") || !method.desc.endsWith(")V")) {
                continue;
            }

            InsnList hook = new InsnList();
            hook.add(new VarInsnNode(Opcodes.ALOAD, 0));
            hook.add(new MethodInsnNode(
                    Opcodes.INVOKESTATIC,
                    HOOK,
                    "ensureWorld",
                    "(Ljava/lang/Object;)V"));
            method.instructions.insert(hook);
            patched = true;
        }

        if (!patched) {
            return basicClass;
        }

        ClassWriter writer = new ClassWriter(ClassWriter.COMPUTE_MAXS);
        node.accept(writer);
        System.out.println("[CLWorldFix] Patched CodeChickenLib WorldExtensionManager tick guard.");
        return writer.toByteArray();
    }
}
