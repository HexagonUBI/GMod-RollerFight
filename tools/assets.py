import os
import glob
import shutil
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAMEMODE = os.path.join(ROOT, "gamemodes", "rollerfight")
SOURCE = os.path.join(ROOT, "dev-notes")

LOGO_HEIGHT = 128
ICON_SIZE = (24, 32)
ICON_CROP_WIDTH = 133


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


def build_logo(image):
    width, height = image.size
    scaled_width = max(1, int(round(width * LOGO_HEIGHT / float(height))))
    resized = image.resize((scaled_width, LOGO_HEIGHT), Image.LANCZOS)
    resized.save(os.path.join(GAMEMODE, "logo.png"), optimize=True)
    print("logo.png -> %dx%d" % (scaled_width, LOGO_HEIGHT))


def build_icon(image):
    box = image.split()[3].getbbox()
    if box is None:
        box = (0, 0) + image.size

    left, top, right, bottom = box
    glyph = image.crop((left, top, min(left + ICON_CROP_WIDTH, right), bottom))

    width, height = glyph.size
    scale = min(ICON_SIZE[0] / float(width), ICON_SIZE[1] / float(height))
    size = (max(1, int(width * scale)), max(1, int(height * scale)))
    resized = glyph.resize(size, Image.LANCZOS)

    icon = Image.new("RGBA", ICON_SIZE, (0, 0, 0, 0))
    icon.paste(resized, ((ICON_SIZE[0] - size[0]) // 2, (ICON_SIZE[1] - size[1]) // 2), resized)
    icon.save(os.path.join(GAMEMODE, "icon24.png"), optimize=True)
    print("icon24.png -> %dx%d" % ICON_SIZE)


def main():
    build_backgrounds()

    logo = os.path.join(SOURCE, "logo-v1.png")
    if not os.path.isfile(logo):
        print("no logo at %s" % logo)
        return

    image = Image.open(logo).convert("RGBA")
    build_logo(image)
    build_icon(image)


if __name__ == "__main__":
    main()
