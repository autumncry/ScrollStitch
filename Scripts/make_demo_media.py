#!/usr/bin/env python3
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError as exc:
    raise SystemExit("Install Pillow first: python3 -m pip install Pillow") from exc


OUT = Path("DemoMedia")
WIDTH = 390
ROW_HEIGHT = 90
OVERLAP_ROWS = 2


def make(rows, path):
    img = Image.new("RGB", (WIDTH, ROW_HEIGHT * len(rows)), "#f8fafc")
    draw = ImageDraw.Draw(img)
    for index, color in enumerate(rows):
        y = index * ROW_HEIGHT
        draw.rounded_rectangle(
            (20, y + 18, WIDTH - 20, y + ROW_HEIGHT - 18),
            radius=18,
            fill=color,
        )
        draw.text((38, y + 38), f"Demo row {index + 1}", fill="#111827")
    img.save(path)


def main():
    OUT.mkdir(exist_ok=True)
    shared = ["#60a5fa", "#34d399"]
    first = ["#fca5a5", "#fdba74", *shared]
    second = [*shared, "#c4b5fd", "#f9a8d4"]
    make(first, OUT / "scrollstitch-demo-01.png")
    make(second, OUT / "scrollstitch-demo-02.png")
    print(f"Wrote demo images to {OUT.resolve()} with {OVERLAP_ROWS} overlapping rows.")


if __name__ == "__main__":
    main()
