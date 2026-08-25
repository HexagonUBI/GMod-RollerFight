"""Assemble the workshop publish folder.

Run from anywhere:  python tools/build.py

Writes dist/ holding only the files that ship: addon.json, gamemodes/rollerfight
and materials/rollerfight. Every output file is checked against the Garry's Mod
addon whitelist, so anything that would be rejected at upload time is reported
here instead.

Point gmpublisher at dist/, or run:  gmad create -folder dist -out rollerfight.gma

gmad honours the ignore list in addon.json, gmpublisher does not, which is why
this folder exists. Standard library only.
"""

import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIST = os.path.join(ROOT, "dist")

SHIP = [
    "addon.json",
    os.path.join("gamemodes", "rollerfight"),
    os.path.join("materials", "rollerfight"),
]

# The Garry's Mod addon whitelist. A star matches any run of characters,
# path separators included, which is why one entry covers nested folders.
WHITELIST = [
    "addon.json",
    "lua/*.lua",
    "scenes/*.vcd",
    "particles/*.pcf",
    "resource/fonts/*.ttf",
    "scripts/vehicles/*.txt",
    "resource/localization/*/*.properties",
    "maps/*.bsp",
    "maps/*.lmp",
    "maps/*.nav",
    "maps/*.ain",
    "maps/thumb/*.png",
    "sound/*.wav",
    "sound/*.mp3",
    "sound/*.ogg",
    "materials/*.vmt",
    "materials/*.vtf",
    "materials/*.png",
    "materials/*.jpg",
    "materials/*.jpeg",
    "materials/colorcorrection/*.raw",
    "models/*.mdl",
    "models/*.vtx",
    "models/*.phy",
    "models/*.ani",
    "models/*.vvd",
    "gamemodes/*/*.txt",
    "gamemodes/*/*.fgd",
    "gamemodes/*/logo.png",
    "gamemodes/*/icon24.png",
    "gamemodes/*/gamemode/*.lua",
    "gamemodes/*/entities/effects/*.lua",
    "gamemodes/*/entities/weapons/*.lua",
    "gamemodes/*/entities/entities/*.lua",
    "gamemodes/*/backgrounds/*.jpg",
    "gamemodes/*/backgrounds/*.jpeg",
    "gamemodes/*/backgrounds/*.png",
    "gamemodes/*/content/models/*.mdl",
    "gamemodes/*/content/models/*.vtx",
    "gamemodes/*/content/models/*.phy",
    "gamemodes/*/content/models/*.ani",
    "gamemodes/*/content/models/*.vvd",
    "gamemodes/*/content/materials/*.vmt",
    "gamemodes/*/content/materials/*.vtf",
    "gamemodes/*/content/materials/*.png",
    "gamemodes/*/content/materials/*.jpg",
    "gamemodes/*/content/materials/*.jpeg",
    "gamemodes/*/content/scenes/*.vcd",
    "gamemodes/*/content/particles/*.pcf",
    "gamemodes/*/content/resource/fonts/*.ttf",
    "gamemodes/*/content/scripts/vehicles/*.txt",
    "gamemodes/*/content/maps/*.bsp",
    "gamemodes/*/content/maps/*.nav",
    "gamemodes/*/content/maps/*.ain",
    "gamemodes/*/content/sound/*.wav",
    "gamemodes/*/content/sound/*.mp3",
    "gamemodes/*/content/sound/*.ogg",
]

PATTERNS = [
    re.compile(re.escape(p).replace(r"\*", ".*") + "$", re.I) for p in WHITELIST
]


def allowed(name):
    return any(p.match(name) for p in PATTERNS)


def walk(base):
    for dirpath, dirnames, filenames in os.walk(base):
        dirnames[:] = [d for d in dirnames if d not in (".git", "__pycache__")]
        for fn in sorted(filenames):
            yield os.path.join(dirpath, fn)


def sources():
    for entry in SHIP:
        full = os.path.join(ROOT, entry)
        if os.path.isfile(full):
            yield full
        elif os.path.isdir(full):
            for path in walk(full):
                yield path
        else:
            print("  missing, skipped: " + entry.replace(os.sep, "/"))


def main():
    if os.path.isdir(DIST):
        shutil.rmtree(DIST)

    count, size, rejected = 0, 0, []

    for src in sources():
        rel = os.path.relpath(src, ROOT).replace(os.sep, "/")

        if not allowed(rel):
            rejected.append(rel)
            continue

        dst = os.path.join(DIST, rel.replace("/", os.sep))
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(src, dst)

        count += 1
        size += os.path.getsize(src)

    print("  %d files, %.1f KB -> %s" % (count, size / 1024.0, os.path.relpath(DIST, ROOT)))

    if rejected:
        print("")
        print("REJECTED (%d), these would fail the workshop whitelist:" % len(rejected))
        for r in rejected:
            print("   " + r)
        return 1

    print("")
    print("publish folder ready, point gmpublisher at:")
    print("   " + DIST)
    return 0


if __name__ == "__main__":
    sys.exit(main())
