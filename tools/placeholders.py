import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "materials", "rollerfight", "ui")

BG = (22, 22, 22, 255)
EDGE = (238, 130, 32, 255)
SHAPE = (150, 150, 150, 255)
TEXT = (200, 200, 200, 255)


def frame(draw, w, h):
    step = 10
    for x in range(0, w, step * 2):
        draw.rectangle([x, 0, x + step, 2], fill=EDGE)
        draw.rectangle([x, h - 3, x + step, h - 1], fill=EDGE)
    for y in range(0, h, step * 2):
        draw.rectangle([0, y, 2, y + step], fill=EDGE)
        draw.rectangle([w - 3, y, w - 1, y + step], fill=EDGE)


def label(draw, w, h, text):
    draw.text((6, h - 14), text, fill=TEXT)


def mine(draw, cx, cy, r):
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=SHAPE)
    for i in range(6):
        import math
        a = math.radians(i * 60)
        x = cx + math.cos(a) * r * 1.35
        y = cy + math.sin(a) * r * 1.35
        draw.polygon([
            (cx + math.cos(a) * r * 0.8, cy + math.sin(a) * r * 0.8),
            (x + math.cos(a + 1.4) * r * 0.22, y + math.sin(a + 1.4) * r * 0.22),
            (x + math.cos(a - 1.4) * r * 0.22, y + math.sin(a - 1.4) * r * 0.22),
        ], fill=SHAPE)


def person(draw, cx, cy, s):
    draw.ellipse([cx - s * 0.3, cy - s * 0.75, cx + s * 0.3, cy - s * 0.15], fill=SHAPE)
    draw.pieslice([cx - s * 0.6, cy - s * 0.1, cx + s * 0.6, cy + s * 1.1], 180, 360, fill=SHAPE)


def tick(draw, cx, cy, s):
    draw.line([(cx - s * 0.5, cy), (cx - s * 0.1, cy + s * 0.45), (cx + s * 0.6, cy - s * 0.5)],
              fill=SHAPE, width=max(2, int(s * 0.22)))


def eye(draw, cx, cy, s):
    draw.ellipse([cx - s * 0.75, cy - s * 0.45, cx + s * 0.75, cy + s * 0.45], outline=SHAPE, width=max(2, int(s * 0.14)))
    draw.ellipse([cx - s * 0.22, cy - s * 0.22, cx + s * 0.22, cy + s * 0.22], fill=SHAPE)


def pause(draw, cx, cy, s):
    draw.rectangle([cx - s * 0.45, cy - s * 0.55, cx - s * 0.12, cy + s * 0.55], fill=SHAPE)
    draw.rectangle([cx + s * 0.12, cy - s * 0.55, cx + s * 0.45, cy + s * 0.55], fill=SHAPE)


def cone(draw, cx, cy, s):
    draw.polygon([(cx, cy - s * 0.6), (cx + s * 0.55, cy + s * 0.5), (cx - s * 0.55, cy + s * 0.5)], fill=SHAPE)
    draw.rectangle([cx - s * 0.7, cy + s * 0.5, cx + s * 0.7, cy + s * 0.68], fill=SHAPE)


SLOTS = [
    ("ph_banner.png", 640, 300, "gametype banner 640x300", lambda d, w, h: mine(d, w // 2, h // 2 - 10, 46)),
    ("ph_avatar.png", 64, 64, "avatar 64", lambda d, w, h: person(d, w // 2, h // 2, 30)),
    ("ph_ready.png", 48, 48, "ready 48", lambda d, w, h: tick(d, w // 2, h // 2, 18)),
    ("ph_training.png", 48, 48, "training 48", lambda d, w, h: cone(d, w // 2, h // 2, 18)),
    ("ph_spectate.png", 48, 48, "spectate 48", lambda d, w, h: eye(d, w // 2, h // 2, 18)),
    ("ph_pause.png", 48, 48, "pause 48", lambda d, w, h: pause(d, w // 2, h // 2, 18)),
    ("ph_watermark.png", 256, 96, "watermark 256x96", lambda d, w, h: mine(d, 44, h // 2, 24)),
]


def main():
    os.makedirs(OUT, exist_ok=True)

    for name, w, h, text, shape in SLOTS:
        img = Image.new("RGBA", (w, h), BG)
        draw = ImageDraw.Draw(img)
        shape(draw, w, h)
        frame(draw, w, h)
        if h >= 40:
            label(draw, w, h, text)
        img.save(os.path.join(OUT, name), optimize=True)
        print("placeholder %-22s %dx%d" % (name, w, h))

    logo = os.path.join(ROOT, "dev-notes", "logo-v2.png")
    if os.path.isfile(logo):
        src = Image.open(logo).convert("RGBA")
        scale = 256.0 / src.size[1]
        wide = src.resize((int(src.size[0] * scale), 256), Image.LANCZOS)
        wide.save(os.path.join(ROOT, "materials", "rollerfight", "logo.png"), optimize=True)
        print("logo            %-22s %s" % ("logo.png", wide.size))


if __name__ == "__main__":
    main()
