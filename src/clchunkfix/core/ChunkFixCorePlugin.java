package clchunkfix.core;

import cpw.mods.fml.relauncher.IFMLLoadingPlugin;

import java.util.Map;

/**
 * Coremod entry point for the Crash Landing compatibility guards.
 *
 * The regular clchunkfix mod handles stale ChickenChunks/Ruins state on a
 * world switch. The coremod transformers handle separate failures:
 * CodeChickenLib can tick a World that was never registered in its static
 * worldMap (NullPointerException in preTick), Inventory Tweaks can send a
 * stale container click, HQM scans the OreDictionary on every pickup, and
 * EntityItem is culled by the client at 16 blocks even though the server
 * tracks it up to 64.
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
                "clchunkfix.core.InvTweaksTransformer",
                "clchunkfix.core.HqmTransformer",
                "clchunkfix.core.ItemRenderTransformer"
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
