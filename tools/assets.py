import os
import glob
import shutil
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAMEMODE = os.path.join(ROOT, "gamemodes", "rollerfight")
MATS = os.path.join(ROOT, "materials", "rollerfight")
SOURCE = os.path.join(ROOT, "dev-notes")

LOGO_HEIGHT = 128

# The lobby draws a banner at 410x132 and paints its own black title bar over
# the bottom 32 of those pixels, so keep the mines out of the lowest quarter.
BANNER = (820, 264)
BANNER_BAR = 32 / 132.0

BANNERS = [
    ("gt_dm.png", "dm.jpg", (220, 285, 1920, 832)),
    ("gt_tdm.png", "tdm.jpg", (0, 290, 1920, 908)),
    ("gt_lots.png", "lots.jpg", (0, 235, 1920, 853)),
]


def build_backgrounds():
    out = os.path.join(GAMEMODE, "backgrounds")
    os.makedirs(out, exist_ok=True)

    found = []
    for pattern in ("*.jpg", "*.JPG", "*.jpeg", "*.JPEG"):
        found.extend(glob.glob(os.path.join(SOURCE, "backgrounds", pattern)))

    for index, path in enumerate(sorted(set(found)), 1):
        dest = os.path.join(out, "rollerfight%02d.jpg" % index)
        shutil.copyfile(path, dest)
        print("background -> %s" % os.path.basename(dest))


def build_banners():
    source = os.path.join(SOURCE, "banners")

    if not os.path.isdir(source):
        print("no banner sources at %s" % source)
        return

    for name, shot, box in BANNERS:
        path = os.path.join(source, shot)

        if not os.path.isfile(path):
            print("missing banner source %s" % shot)
            continue

        image = Image.open(path).convert("RGB").crop(box).resize(BANNER, Image.LANCZOS)
        image.save(os.path.join(MATS, name), optimize=True)
        print("%s -> %dx%d from %s" % (name, BANNER[0], BANNER[1], shot))


def build_logo(image):
    width, height = image.size
    scaled_width = max(1, int(round(width * LOGO_HEIGHT / float(height))))
    resized = image.resize((scaled_width, LOGO_HEIGHT), Image.LANCZOS)
    resized.save(os.path.join(GAMEMODE, "logo.png"), optimize=True)
    print("logo.png -> %dx%d" % (scaled_width, LOGO_HEIGHT))


def main():
    build_backgrounds()
    build_banners()

    logo = os.path.join(SOURCE, "logo-v2.png")
    if os.path.isfile(logo):
        build_logo(Image.open(logo).convert("RGBA"))
    else:
        print("no logo at %s" % logo)

    print("icon24.png left untouched on purpose")


if __name__ == "__main__":
    main()
