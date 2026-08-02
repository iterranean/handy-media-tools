#!/usr/bin/env python3
"""
Create a minimal valid image file for testing.

exiftool requires a structurally valid image to accept metadata writes.
We create a 1x1 pixel solid-color image via Pillow, auto-detecting format
from the file extension.
"""

import sys
from pathlib import Path

def make_image(path: str) -> None:
    from PIL import Image
    img = Image.new("RGB", (1, 1), color=(128, 128, 128))
    ext = Path(path).suffix.lower()
    fmt = "JPEG" if ext == ".jpg" else "PNG"
    img.save(path, fmt)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <output.jpg|png>", file=sys.stderr)
        sys.exit(1)
    make_image(sys.argv[1])
