package clchunkfix.core;

import net.minecraft.launchwrapper.IClassTransformer;
import org.objectweb.asm.ClassReader;
import org.objectweb.asm.ClassWriter;
import org.objectweb.asm.tree.AbstractInsnNode;
import org.objectweb.asm.tree.ClassNode;
import org.objectweb.asm.tree.MethodInsnNode;
import org.objectweb.asm.tree.MethodNode;

/**
 * Replaces HQM's direct OreDictionary.getOreID calls with a cached lookup.
 */
public class HqmTransformer implements IClassTransformer {

    private static final String TARGET = "hardcorequesting.quests.ItemPrecision$4";
    private static final String ORE_DICTIONARY = "net/minecraftforge/oredict/OreDictionary";
    private static final String HOOK = "clchunkfix/core/HqmHooks";

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
            if (!"same".equals(method.name)) {
                continue;
            }
            for (AbstractInsnNode instruction = method.instructions.getFirst();
                 instruction != null;
                 instruction = instruction.getNext()) {
                if (!(instruction instanceof MethodInsnNode)) {
                    continue;
                }
                MethodInsnNode call = (MethodInsnNode) instruction;
                if (ORE_DICTIONARY.equals(call.owner)
                        && "getOreID".equals(call.name)
                        && "(Lnet/minecraft/item/ItemStack;)I".equals(call.desc)) {
                    call.owner = HOOK;
                    call.name = "oreId";
                    call.desc = "(Ljava/lang/Object;)I";
                    patched = true;
                }
            }
        }

        if (!patched) {
            return basicClass;
        }

        ClassWriter writer = new ClassWriter(ClassWriter.COMPUTE_MAXS);
        node.accept(writer);
        System.out.println("[CLWorldFix] Patched HQM OreDictionary lookup cache.");
        return writer.toByteArray();
    }
}
