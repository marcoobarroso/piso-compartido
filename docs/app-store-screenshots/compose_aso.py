import sys
from PIL import Image, ImageDraw, ImageFont

CANVAS_W, CANVAS_H = 1320, 2868
BG = (10, 10, 10)  # #0a0a0a
WHITE = (250, 250, 250)
ORANGE = (223, 108, 50)  # #df6c32
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"

TOP_PAD = 130
LINE_GAP = 12
SHOT_TOP_MARGIN = 60
SHOT_SIDE_MARGIN = 60
SHOT_BOTTOM_MARGIN = 90
CORNER_RADIUS = 64


def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([(0, 0), (size[0] - 1, size[1] - 1)], radius=radius, fill=255)
    return mask


def compose(screenshot_path, line1, line2, out_path, font_size=104):
    canvas = Image.new("RGB", (CANVAS_W, CANVAS_H), BG)
    draw = ImageDraw.Draw(canvas)

    font1 = ImageFont.truetype(FONT_BOLD, font_size)
    font2 = ImageFont.truetype(FONT_BOLD, font_size)

    def centered_text(y, text, font, color):
        bbox = draw.textbbox((0, 0), text, font=font)
        w = bbox[2] - bbox[0]
        draw.text(((CANVAS_W - w) / 2, y), text, font=font, fill=color)
        return bbox[3] - bbox[1]

    y = TOP_PAD
    h1 = centered_text(y, line1, font1, WHITE)
    y += h1 + LINE_GAP
    h2 = centered_text(y, line2, font2, ORANGE)
    y += h2

    shot_top = y + SHOT_TOP_MARGIN
    shot = Image.open(screenshot_path).convert("RGB")
    target_w = CANVAS_W - 2 * SHOT_SIDE_MARGIN
    scale = target_w / shot.width
    target_h = int(shot.height * scale)
    max_h = CANVAS_H - shot_top - SHOT_BOTTOM_MARGIN
    if target_h > max_h:
        target_h = max_h
        target_w = int(shot.width * (target_h / shot.height))
    shot = shot.resize((target_w, target_h), Image.LANCZOS)

    mask = rounded_mask(shot.size, CORNER_RADIUS)
    shot_x = (CANVAS_W - target_w) // 2
    canvas.paste(shot, (shot_x, shot_top), mask)

    # subtle border
    border = ImageDraw.Draw(canvas)
    border.rounded_rectangle(
        [(shot_x, shot_top), (shot_x + target_w - 1, shot_top + target_h - 1)],
        radius=CORNER_RADIUS,
        outline=(255, 255, 255, 40),
        width=2,
    )

    canvas.save(out_path, "PNG")
    print(f"wrote {out_path} ({canvas.size})")


if __name__ == "__main__":
    jobs = [
        ("tab-inicio.png", "Tu piso,", "bajo control", "01-inicio.png"),
        ("tab-gastos.png", "Cuentas claras,", "cero líos", "02-gastos.png"),
        ("tareas-calendario.png", "Turnos justos,", "sin pelear", "03-tareas.png"),
        ("tab-compra.png", "La compra,", "siempre lista", "04-compra.png"),
        ("tab-stats.png", "Vuestro progreso,", "mes a mes", "05-stats.png"),
    ]
    src_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    out_dir = sys.argv[2] if len(sys.argv) > 2 else "."
    import os
    for src, l1, l2, out in jobs:
        src_path = os.path.join(src_dir, src)
        if not os.path.exists(src_path):
            print(f"SKIP missing {src_path}")
            continue
        compose(src_path, l1, l2, os.path.join(out_dir, out))
