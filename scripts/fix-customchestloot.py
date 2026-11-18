#!/usr/bin/env python3
"""Join broken multi-line `contents=` values in CustomChestLoot configs.

The Crash Landing configs wrap long `contents=` lines without a backslash.
Java Properties reads only the first line, so the remaining item IDs become
invalid keys and the mod logs "Invalid number of arguments!". Joining the
continuation lines restores the intended loot entries without changing their
contents.
"""
import os
import sys


def fix_file(path):
    with open(path, "r", encoding="utf-8") as f:
        lines = f.read().splitlines()

    out = []
    changed = False
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("contents="):
            parts = [line]
            i += 1
            while i < len(lines):
                nxt = lines[i]
                if not nxt.strip() or "=" in nxt or nxt.lstrip().startswith("#"):
                    break
                parts.append(nxt.strip())
                i += 1
            joined = "".join(parts)
            if joined != line:
                changed = True
            out.append(joined)
        else:
            out.append(line)
            i += 1

    if changed:
        with open(path, "w", encoding="utf-8") as f:
            f.write("\n".join(out) + "\n")
    return changed


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: fix-customchestloot.py <config/CustomChestLoot>")
    root = sys.argv[1]
    if not os.path.isdir(root):
        print("CustomChestLoot config directory not found: " + root)
        return 1

    fixed = []
    for dirpath, _, files in os.walk(root):
        for name in sorted(files):
            if not name.endswith(".txt"):
                continue
            path = os.path.join(dirpath, name)
            if fix_file(path):
                fixed.append(path)

    if fixed:
        print("Fixed CustomChestLoot configs:")
        for path in fixed:
            print("  " + path)
    else:
        print("CustomChestLoot configs already OK.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
