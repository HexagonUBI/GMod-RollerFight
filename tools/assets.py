import os
import glob
import shutil
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAMEMODE = os.path.join(ROOT, "gamemodes", "rollerfight")
SOURCE = os.path.join(ROOT, "dev-notes")

LOGO_HEIGHT = 128


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


def main():
    build_backgrounds()

    logo = os.path.join(SOURCE, "logo-v2.png")
    if os.path.isfile(logo):
        build_logo(Image.open(logo).convert("RGBA"))
    else:
        print("no logo at %s" % logo)

    print("icon24.png left untouched on purpose")


if __name__ == "__main__":
    main()
