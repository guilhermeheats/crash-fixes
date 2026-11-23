package clchunkfix.core;

import cpw.mods.fml.relauncher.IFMLLoadingPlugin;

import java.util.Map;

/**
 * Coremod entry point for the CodeChickenLib world-extension guard.
 *
 * The regular clchunkfix mod handles stale ChickenChunks/Ruins state on a
 * world switch. This coremod handles a separate failure: CodeChickenLib can
 * tick a World that was never registered in its static worldMap, producing a
 * NullPointerException in WorldExtensionManager.preTick and stopping the
 * integrated server tick loop.
 */
@IFMLLoadingPlugin.Name("CLChunkFixCore")
@IFMLLoadingPlugin.MCVersion("1.6.4")
public class ChunkFixCorePlugin implements IFMLLoadingPlugin {

    @Override
    @Deprecated
    public String[] getLibraryRequestClass() {
        return null;
    }

    @Override
    public String[] getASMTransformerClass() {
        return new String[]{
                "clchunkfix.core.WorldExtensionTransformer",
                "clchunkfix.core.InvTweaksTransformer"
        };
    }

    @Override
    public String getModContainerClass() {
        return null;
    }

    @Override
    public String getSetupClass() {
        return null;
    }

    @Override
    public void injectData(Map<String, Object> data) {
    }
}
