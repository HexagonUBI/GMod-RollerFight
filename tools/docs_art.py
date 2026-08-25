"""Build the images the GitHub README points at.

Run from anywhere:  python tools/docs_art.py

Reads the logo from dev-notes and the shots from the shipped menu backgrounds,
writes docs/. dev-notes is private and never pushed, docs/ is tracked so the
raw.githubusercontent links in README.md resolve. docs/ is excluded from the
gma, both by addon.json and by tools/build.py.

Needs Pillow:  python -m pip install pillow
"""

import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, "dev-notes")
SHOTS = os.path.join(ROOT, "gamemodes", "rollerfight", "backgrounds")
DOCS = os.path.join(ROOT, "docs")

ACCENT = (238, 130, 32)

HERO = (1280, 440)
HERO_SHOT = "rollerfight05.jpg"
HERO_CROP = (0, 190, 1920, 850)
TAGLINE = "Drive a Half-Life 2 rollermine. Ram everything else."

GALLERY = [
    ("shot-1.jpg", "rollerfight04.jpg"),
    ("shot-2.jpg", "rollerfight06.jpg"),
    ("shot-3.jpg", "rollerfight02.jpg"),
    ("shot-4.jpg", "rollerfight01.jpg"),
]
GALLERY_SIZE = (960, 540)

FONTS = ["verdanab.ttf", "segoeuib.ttf", "arialbd.ttf", "DejaVuSans-Bold.ttf"]


def load_font(size):
    for name in FONTS:
        try:
            return ImageFont.truetype(name, size)
        except (OSError, IOError):
            continue
    return ImageFont.load_default()


def ramp(count, start, end):
    if count < 2:
        return [start]

    step = (end - start) / float(count - 1)

    return [int(start + step * i) for i in range(count)]


def fade(image, box, left, right):
    x0, y0, x1, y1 = box
    width, height = x1 - x0, y1 - y0

    strip = Image.new("L", (width, 1))
    strip.putdata(ramp(width, left, right))

    image.paste(Image.new("RGB", (width, height), (0, 0, 0)), (x0, y0), strip.resize((width, height)))


def veil(image, box, top, bottom):
    x0, y0, x1, y1 = box
    width, height = x1 - x0, y1 - y0

    strip = Image.new("L", (1, height))
    strip.putdata(ramp(height, top, bottom))

    image.paste(Image.new("RGB", (width, height), (0, 0, 0)), (x0, y0), strip.resize((width, height)))


def build_hero():
    shot = Image.open(os.path.join(SHOTS, HERO_SHOT)).convert("RGB")
    hero = shot.crop(HERO_CROP).resize(HERO, Image.LANCZOS)

    hero = Image.blend(hero, Image.new("RGB", HERO, (0, 0, 0)), 0.30)
    veil(hero, (0, 170, HERO[0], HERO[1]), 0, 175)
    fade(hero, (0, 0, 800, HERO[1]), 205, 0)

    logo = Image.open(os.path.join(SOURCE, "logo-v2.png")).convert("RGBA")
    width = 470
    logo = logo.resize((width, int(logo.height * width / float(logo.width))), Image.LANCZOS)
    hero.paste(logo, (52, 110), logo)

    draw = ImageDraw.Draw(hero)
    draw.text((62, 290), TAGLINE, font=load_font(23), fill=(232, 232, 232))
    draw.text((62, 328), "A Garry's Mod gamemode", font=load_font(18), fill=(158, 158, 158))

    draw.rectangle([0, HERO[1] - 6, HERO[0], HERO[1]], fill=ACCENT)

    out = os.path.join(DOCS, "hero.png")
    hero.save(out, optimize=True)

    return out


def build_logo():
    logo = Image.open(os.path.join(SOURCE, "logo-v2.png")).convert("RGBA")
    width = 480
    logo = logo.resize((width, int(logo.height * width / float(logo.width))), Image.LANCZOS)

    out = os.path.join(DOCS, "logo.png")
    logo.save(out, optimize=True)

    return out


def build_gallery():
    made = []

    for name, source in GALLERY:
        path = os.path.join(SHOTS, source)

        if not os.path.isfile(path):
            print("  missing, skipped: " + source)
            continue

        shot = Image.open(path).convert("RGB").resize(GALLERY_SIZE, Image.LANCZOS)
        out = os.path.join(DOCS, name)
        shot.save(out, quality=88, optimize=True)
        made.append(out)

    return made


def main():
    if not os.path.isdir(SOURCE):
        print("dev-notes is missing, nothing to build from")
        return 1

    os.makedirs(DOCS, exist_ok=True)

    made = [build_hero(), build_logo()] + build_gallery()

    for path in made:
        print("  %-24s %d KB" % (os.path.basename(path), os.path.getsize(path) // 1024))

    print("")
    print("%d images in %s" % (len(made), os.path.relpath(DOCS, ROOT)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
