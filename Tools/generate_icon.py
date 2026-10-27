"""Draws the Strengthspan app icon (1024×1024, opaque) into the asset catalog.

Run from the repository root:  python Tools/generate_icon.py
Concept: three rising bars on a teal gradient — measure, train, improve.
"""
import json
import pathlib

from PIL import Image, ImageDraw

SIZE = 1024
TOP = (15, 118, 110)      # #0F766E — design-system accent
BOTTOM = (20, 184, 166)   # #14B8A6
BAR = (255, 255, 255)

root = pathlib.Path(__file__).resolve().parent.parent
iconset = root / "Strengthspan" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset"

image = Image.new("RGB", (SIZE, SIZE))
pixels = image.load()
for y in range(SIZE):
    for x in range(SIZE):
        t = (x + y) / (2 * (SIZE - 1))
        pixels[x, y] = tuple(round(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3))

draw = ImageDraw.Draw(image)
bar_width = 150
gap = 70
heights = [200, 330, 470]
total = 3 * bar_width + 2 * gap
left = (SIZE - total) // 2
head = 120
head_gap = 40
# Centre the whole figure (bars + head) vertically.
baseline = (SIZE + heights[2] + head_gap + head) // 2
for index, height in enumerate(heights):
    x0 = left + index * (bar_width + gap)
    draw.rounded_rectangle((x0, baseline - height, x0 + bar_width, baseline), radius=bar_width // 2, fill=BAR)

# A small "head" above the tallest bar turns the bars into a rising figure.
cx = left + 2 * (bar_width + gap) + bar_width // 2
head_bottom = baseline - heights[2] - head_gap
draw.ellipse((cx - head // 2, head_bottom - head, cx + head // 2, head_bottom), fill=BAR)

out = iconset / "AppIcon.png"
image.save(out, "PNG")

contents = {
    "images": [{"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
    "info": {"author": "xcode", "version": 1},
}
(iconset / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n", encoding="utf-8")
print(f"Wrote {out} ({image.mode}, {image.size[0]}×{image.size[1]})")
