import math
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MATS = os.path.join(ROOT, "materials", "rollerfight")
UI = os.path.join(MATS, "ui")

DARK = (20, 20, 22, 255)
SHAPE = (168, 168, 168, 255)
TEXT = (225, 225, 225, 255)


def dashed(draw, w, h, col):
    step = 12
    for x in range(0, w, step * 2):
        draw.rectangle([x, 0, x + step, 2], fill=col)
        draw.rectangle([x, h - 3, x + step, h - 1], fill=col)
    for y in range(0, h, step * 2):
        draw.rectangle([0, y, 2, y + step], fill=col)
        draw.rectangle([w - 3, y, w - 1, y + step], fill=col)


def stripes(draw, w, h, col, gap=34):
    for i in range(-h, w, gap):
        draw.line([(i, h), (i + h, 0)], fill=col, width=3)


def mine(draw, cx, cy, r, col=SHAPE, spikes=True):
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)
    if not spikes:
        return
    for i in range(6):
        a = math.radians(i * 60 + 15)
        tip = (cx + math.cos(a) * r * 1.5, cy + math.sin(a) * r * 1.5)
        draw.polygon([
            (cx + math.cos(a + 0.28) * r * 0.9, cy + math.sin(a + 0.28) * r * 0.9),
            (cx + math.cos(a - 0.28) * r * 0.9, cy + math.sin(a - 0.28) * r * 0.9),
            tip,
        ], fill=col)


def cross(draw, cx, cy, r, col):
    d = r * 1.1
    draw.line([(cx - d, cy - d), (cx + d, cy + d)], fill=col, width=6)
    draw.line([(cx - d, cy + d), (cx + d, cy - d)], fill=col, width=6)


def caption(draw, w, h, title, spec, accent):
    draw.rectangle([0, h - 30, w, h], fill=(0, 0, 0, 205))
    draw.text((10, h - 24), title, fill=accent)
    draw.text((w - 8 - len(spec) * 6, h - 24), spec, fill=TEXT)


def banner(path, title, accent, painter, w=640, h=300):
    img = Image.new("RGBA", (w, h), DARK)
    d = ImageDraw.Draw(img)
    stripes(d, w, h, (accent[0] // 5, accent[1] // 5, accent[2] // 5, 255))
    painter(d, w, h, accent)
    dashed(d, w, h, accent)
    caption(d, w, h, title, "%dx%d PLACEHOLDER" % (w, h), accent)
    img.save(path, optimize=True)
    print("  %-26s %dx%d" % (os.path.basename(path), w, h))


def paint_dm(d, w, h, accent):
    mine(d, w // 2, h // 2 - 16, 54, accent)
    for i, x in enumerate((w * 0.22, w * 0.78)):
        mine(d, int(x), int(h * 0.5 - 16), 26, SHAPE)


def paint_tdm(d, w, h, accent):
    blue = (70, 140, 240, 255)
    gold = (245, 165, 30, 255)
    d.rectangle([0, 0, w // 2, h], fill=(blue[0] // 6, blue[1] // 6, blue[2] // 6, 255))
    for x, col in ((w * 0.3, blue), (w * 0.7, gold)):
        mine(d, int(x), h // 2 - 16, 46, col)
    d.line([(w // 2, 26), (w // 2, h - 40)], fill=accent, width=3)


def paint_lots(d, w, h, accent):
    mine(d, w // 2, h // 2 - 16, 50, accent)
    for i, x in enumerate((w * 0.16, w * 0.32, w * 0.68, w * 0.84)):
        cx, cy = int(x), int(h * 0.5 - 16)
        mine(d, cx, cy, 24, (90, 90, 90, 255))
        cross(d, cx, cy, 24, (190, 60, 55, 255))


def paint_header(d, w, h, accent):
    mine(d, 44, h // 2, 20, accent)
    d.text((78, h // 2 - 6), "SCOREBOARD HEADER", fill=TEXT)


def icon(path, size, label, painter, accent):
    img = Image.new("RGBA", (size, size), DARK)
    d = ImageDraw.Draw(img)
    painter(d, size, accent)
    dashed(d, size, size, accent)
    img.save(path, optimize=True)
    print("  %-26s %dx%d" % (os.path.basename(path), size, size))


def ic_avatar(d, s, accent):
    d.ellipse([s * 0.32, s * 0.16, s * 0.68, s * 0.52], fill=SHAPE)
    d.pieslice([s * 0.16, s * 0.5, s * 0.84, s * 1.12], 180, 360, fill=SHAPE)


def ic_ready(d, s, accent):
    d.line([(s * 0.24, s * 0.52), (s * 0.44, s * 0.72), (s * 0.78, s * 0.28)], fill=accent, width=max(3, s // 9))


def ic_training(d, s, accent):
    d.polygon([(s * 0.5, s * 0.2), (s * 0.76, s * 0.68), (s * 0.24, s * 0.68)], fill=accent)
    d.rectangle([s * 0.18, s * 0.68, s * 0.82, s * 0.78], fill=accent)


def ic_spectate(d, s, accent):
    d.ellipse([s * 0.12, s * 0.3, s * 0.88, s * 0.7], outline=accent, width=max(3, s // 12))
    d.ellipse([s * 0.38, s * 0.38, s * 0.62, s * 0.62], fill=accent)


def ic_pause(d, s, accent):
    d.rectangle([s * 0.28, s * 0.24, s * 0.43, s * 0.76], fill=accent)
    d.rectangle([s * 0.57, s * 0.24, s * 0.72, s * 0.76], fill=accent)


def main():
    os.makedirs(UI, exist_ok=True)

    print("gametype banners")
    banner(os.path.join(MATS, "gt_dm.png"), "DEATHMATCH", (238, 130, 32, 255), paint_dm)
    banner(os.path.join(MATS, "gt_tdm.png"), "TEAM DEATHMATCH", (80, 160, 245, 255), paint_tdm)
    banner(os.path.join(MATS, "gt_lots.png"), "LAST ONE TO STAND", (215, 70, 60, 255), paint_lots)

    print("interface")
    banner(os.path.join(MATS, "sb_header.png"), "SCOREBOARD", (238, 130, 32, 255), paint_header, 960, 86)

    print("icons")
    icon(os.path.join(UI, "ph_avatar.png"), 64, "avatar", ic_avatar, (150, 150, 150, 255))
    icon(os.path.join(UI, "ph_ready.png"), 48, "ready", ic_ready, (90, 190, 100, 255))
    icon(os.path.join(UI, "ph_training.png"), 48, "training", ic_training, (238, 130, 32, 255))
    icon(os.path.join(UI, "ph_spectate.png"), 48, "spectate", ic_spectate, (150, 170, 220, 255))
    icon(os.path.join(UI, "ph_pause.png"), 48, "pause", ic_pause, (238, 130, 32, 255))

    for stale in ("ph_banner.png", "ph_watermark.png"):
        path = os.path.join(UI, stale)
        if os.path.isfile(path):
            os.remove(path)
            print("  removed stale %s" % stale)

    print("logos")
    for src, dst, height in (("logo-v1.png", "logo_wide.png", 96), ("logo-v2.png", "logo.png", 256)):
        source = os.path.join(ROOT, "dev-notes", src)
        if not os.path.isfile(source):
            print("  missing %s" % src)
            continue
        img = Image.open(source).convert("RGBA")
        box = img.split()[3].getbbox() or (0, 0) + img.size
        img = img.crop(box)
        scale = float(height) / img.size[1]
        out = img.resize((max(1, int(img.size[0] * scale)), height), Image.LANCZOS)
        out.save(os.path.join(MATS, dst), optimize=True)
        print("  %-26s %s  from %s" % (dst, out.size, src))


if __name__ == "__main__":
    main()
