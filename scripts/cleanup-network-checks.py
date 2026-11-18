#!/usr/bin/env python3
"""Disable obsolete network checks/radio endpoints without touching gameplay.

Only update-check/version-check/radio settings are changed. Recipes, loot,
difficulty, hunger, mobs and world settings are untouched.
"""
import os
import re
import sys


def replace_once(path, old, new, changes):
    if not os.path.isfile(path):
        return
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        text = f.read()
    if old not in text:
        return
    text = text.replace(old, new, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    changes.append(path)


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: cleanup-network-checks.py <minecraft-dir>")
    mc = sys.argv[1]
    changes = []

    # OpenBlocks radio: empty station list. The radio block remains, but it has
    # no URLs to connect to, so the timeout spam disappears. Chest loot and
    # villager trades are deliberately untouched.
    openblocks = os.path.join(mc, "config/OpenBlocks.cfg")
    if os.path.isfile(openblocks):
        with open(openblocks, "r", encoding="utf-8", errors="replace") as f:
            text = f.read()
        new_text, count = re.subn(
            r"(?ms)(\n[ \t]*S:radioStations[ \t]*<).*?(\n[ \t]*>)",
            r"\1\n     >",
            text,
            count=1,
        )
        if count and new_text != text:
            with open(openblocks, "w", encoding="utf-8") as f:
                f.write(new_text)
            changes.append(openblocks)

    replacements = [
        ("config/enviromine/EnviroMine.cfg", 'B:"Check For Updates"=true', 'B:"Check For Updates"=false'),
        ("config/BiblioCraft.cfg", "B:CheckForUpdates=true", "B:CheckForUpdates=false"),
        ("config/AppliedEnergistics.cfg", "B:enableVersionChecker=true", "B:enableVersionChecker=false"),
        ("config/powercrystals/core/client.cfg", "B:EnableUpdateCheck=true", "B:EnableUpdateCheck=false"),
        ("config/cofh/CoFHCore.cfg", "B:EnableUpdateNotifications=true", "B:EnableUpdateNotifications=false"),
        ("config/cofh/ThermalExpansion.cfg", "B:EnableUpdateNotifications=true", "B:EnableUpdateNotifications=false"),
        ("config/modstats.cfg", "B:AllowUpdates=true", "B:AllowUpdates=false"),
        ("config/NEI.cfg", "checkUpdates=true", "checkUpdates=false"),
        ("config/ChickenChunks.cfg", "checkUpdates=true", "checkUpdates=false"),
        ("config/CodeChickenCore.cfg", "checkUpdates=true", "checkUpdates=false"),
    ]

    for rel, old, new in replacements:
        replace_once(os.path.join(mc, rel), old, new, changes)

    if changes:
        print("Network/update checks disabled:")
        for path in changes:
            print("  " + path)
    else:
        print("Network/update checks already disabled.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
