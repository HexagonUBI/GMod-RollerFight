"""Static checks for the RollerFight gamemode.

Run from anywhere:  python tools/verify.py
Exit code is non zero if anything fails, so it can gate a commit.

Needs luaparser for the syntax pass:  python -m pip install luaparser
Everything else is standard library.
"""

import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAMEMODE = os.path.join(ROOT, "gamemodes", "rollerfight")
BINARY = (".png", ".jpg", ".jpeg", ".gma", ".vtf", ".mdl", ".dll", ".bsp")

# Entity methods that must never be shadowed by an instance field on a SENT.
# self.Input was a real bug: it resolved to Entity:Input and broke all input.
ENTITY_METHODS = set("""Activate AddCallback AddEffects AddEFlags AddFlags AddGesture AddSolidFlags
AddSpawnFlags AddToMotionController Alive BoundingRadius CallOnRemove CreateShadow DeleteOnRemove
DrawModel DrawShadow DropToFloor EmitSound EntIndex Extinguish EyeAngles EyePos Fire FireBullets
GetTable GetVar Health Ignite Input IsNPC IsOnGround IsPlayer IsRagdoll IsSolid IsValid IsVehicle
IsWeapon IsWorld LocalToWorld LookupAttachment LookupBone LookupSequence MuzzleFlash NearestPoint
NetworkVar NextThink OBBCenter OBBMaxs OBBMins OnGround PhysicsDestroy PhysicsInit PhysicsInitBox
PhysicsInitSphere PhysicsInitStatic PhysicsUpdate Respawn SetupBones SetupMove ShouldCollide
ShouldDraw StartMotionController StopSound TakeDamage TakeDamageInfo TestCollision Think Touch
TranslateBoneToPhysBone TriggerInput TriggerOutput UpdateTransmitState WorldSpaceAABB WorldToLocal
Remove Spawn Draw DrawTranslucent OnRemove Initialize SetNextClientThink GetVelocity GetPos SetPos
GetAngles SetAngles GetModel SetModel GetOwner SetOwner GetParent SetParent""".split())

failures = []
notes = []


def fail(msg):
    failures.append(msg)


def lua_files(base):
    for dirpath, dirnames, filenames in os.walk(base):
        for fn in sorted(filenames):
            if fn.endswith(".lua"):
                yield os.path.join(dirpath, fn)


def rel(path):
    return os.path.relpath(path, ROOT).replace(os.sep, "/")


def check_syntax():
    try:
        from luaparser import ast
    except ImportError:
        notes.append("luaparser not installed, syntax pass skipped")
        return

    count = 0
    for path in lua_files(GAMEMODE):
        src = io.open(path, encoding="utf-8").read()
        try:
            ast.parse(src)
            count += 1
        except Exception as exc:
            fail("syntax: %s -> %s" % (rel(path), str(exc).split("\n")[0]))
    notes.append("%d lua files parsed" % count)


def check_ascii_and_comments():
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in (".git", "__pycache__")]
        for fn in filenames:
            if fn.lower().endswith(BINARY):
                continue
            path = os.path.join(dirpath, fn)
            raw = open(path, "rb").read()
            for i, line in enumerate(raw.split(b"\n"), 1):
                if any(b > 127 for b in bytearray(line)):
                    fail("non ascii: %s:%d" % (rel(path), i))
            if fn.endswith(".lua"):
                for i, line in enumerate(raw.decode("utf-8", "replace").split("\n"), 1):
                    if "--" in line:
                        fail("comment in lua: %s:%d" % (rel(path), i))


def check_rf_members():
    quoted = re.compile(r'"[^"\n]*"')
    define = re.compile(r"^\s*(?:function\s+)?RF\.(\w+)\s*(?:=|\()", re.M)
    use = re.compile(r"\bRF\.(\w+)")

    defined, used = set(), {}
    for path in lua_files(GAMEMODE):
        text = io.open(path, encoding="utf-8").read()
        bare = quoted.sub('""', text)
        for m in define.finditer(text):
            defined.add(m.group(1))
        for m in use.finditer(bare):
            used.setdefault(m.group(1), set()).add(rel(path))

    for name in sorted(used):
        if name not in defined:
            fail("RF.%s used but never defined (%s)" % (name, ", ".join(sorted(used[name]))))
    notes.append("%d RF members defined, %d used" % (len(defined), len(used)))


def check_entity_fields():
    base = os.path.join(GAMEMODE, "entities")
    for path in lua_files(base):
        text = io.open(path, encoding="utf-8").read()
        for m in re.finditer(r"self\.(\w+)", text):
            if m.group(1) in ENTITY_METHODS:
                fail("self.%s shadows Entity:%s in %s" % (m.group(1), m.group(1), rel(path)))


def check_convars():
    cfg = io.open(os.path.join(GAMEMODE, "gamemode", "sh_config.lua"), encoding="utf-8").read()
    keys = re.findall(r'key\s*=\s*"(\w+)"', cfg)
    names = ["rf_" + k.lower() for k in keys]
    for name in sorted(set(n for n in names if names.count(n) > 1)):
        fail("duplicate convar %s" % name)

    wanted = set()
    for path in lua_files(GAMEMODE):
        text = io.open(path, encoding="utf-8").read()
        wanted |= set(re.findall(r'RF\.Get\("(\w+)"\)', text))
    for key in sorted(wanted - set(keys)):
        fail('RF.Get("%s") has no VarList entry' % key)
    notes.append("%d convars" % len(keys))


def check_net_strings():
    registered, used = set(), set()
    for path in lua_files(GAMEMODE):
        text = io.open(path, encoding="utf-8").read()
        registered |= set(re.findall(r'util\.AddNetworkString\("(\w+)"\)', text))
        used |= set(re.findall(r'net\.(?:Start|Receive)\("(\w+)"', text))
    for name in sorted(used - registered):
        fail("net string %s used but never registered" % name)
    notes.append("%d net strings" % len(registered))


def check_materials():
    refs = set()
    for path in lua_files(GAMEMODE):
        text = io.open(path, encoding="utf-8").read()
        refs |= set(re.findall(r'"(rollerfight/[a-z0-9_/]+\.(?:png|jpg))"', text))

    # dynamic feed icons are built from RF.CauseIcon
    feed = io.open(os.path.join(GAMEMODE, "gamemode", "cl_killfeed.lua"), encoding="utf-8").read()
    block = feed[feed.index("RF.CauseIcon"):feed.index("RF.CauseText")]
    for name in re.findall(r'=\s*"(\w+)"', block):
        refs.add("rollerfight/feed/%s.png" % name)

    for ref in sorted(refs):
        if not os.path.isfile(os.path.join(ROOT, "materials", ref)):
            fail("missing material %s" % ref)
    notes.append("%d materials referenced" % len(refs))


def check_sounds():
    cfg = io.open(os.path.join(GAMEMODE, "gamemode", "sh_config.lua"), encoding="utf-8").read()
    tracks = sorted(set(re.findall(r'"(music/[^"]+\.mp3)"', cfg)))
    notes.append("%d music tracks referenced, existence is checked in game by Music.Has" % len(tracks))


def main():
    check_syntax()
    check_ascii_and_comments()
    check_rf_members()
    check_entity_fields()
    check_convars()
    check_net_strings()
    check_materials()
    check_sounds()

    for note in notes:
        print("  " + note)

    print("")
    if failures:
        print("FAILED (%d)" % len(failures))
        for f in failures:
            print("   " + f)
        return 1

    print("all checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
