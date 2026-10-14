import zlib
import struct
import math
import os

def write_png(filename, width, height, pixels):
    """
    Writes RGBA pixel buffer to a PNG file using pure Python (zlib + struct).
    pixels: bytearray of length width * height * 4
    """
    raw_data = bytearray()
    for y in range(height):
        raw_data.append(0)  # filter type None
        start = y * width * 4
        raw_data.extend(pixels[start:start + width * 4])

    compressed = zlib.compress(raw_data, 9)

    def chunk(chunk_type, data):
        c = chunk_type + data
        crc = zlib.crc32(c) & 0xffffffff
        return struct.pack(">I", len(data)) + c + struct.pack(">I", crc)

    png_header = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)

    with open(filename, "wb") as f:
        f.write(png_header)
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", compressed))
        f.write(chunk(b"IEND", b""))

def render_pulso_icon(size):
    """
    Renders the Pulso minimalist geometric pulse icon.
    Pure black background (#000000), white soundwave/pulse bars (#FFFFFF).
    """
    pixels = bytearray(size * size * 4)
    # Background: pure black #000000 with alpha 255
    for i in range(size * size):
        pixels[i * 4 + 0] = 0
        pixels[i * 4 + 1] = 0
        pixels[i * 4 + 2] = 0
        pixels[i * 4 + 3] = 255

    # 9 bars
    height_ratios = [0.22, 0.44, 0.74, 0.38, 0.95, 0.65, 0.32, 0.70, 0.42]
    num_bars = len(height_ratios)
    
    # Safe area: keep within 0.55 of icon size for adaptive icon circular mask
    max_wave_height = size * 0.48
    bar_width = max(2, int(size * 0.042))
    gap = max(2, int(size * 0.040))
    total_width = num_bars * bar_width + (num_bars - 1) * gap
    start_x = (size - total_width) / 2.0
    center_y = size / 2.0

    for idx, ratio in enumerate(height_ratios):
        bar_h = max_wave_height * ratio
        bx = start_x + idx * (bar_width + gap)
        by1 = center_y - bar_h / 2.0
        by2 = center_y + bar_h / 2.0
        radius = bar_width / 2.0

        # Draw rounded bar with supersampling / anti-aliasing
        min_px = max(0, int(math.floor(bx)))
        max_px = min(size - 1, int(math.ceil(bx + bar_width)))
        min_py = max(0, int(math.floor(by1)))
        max_py = min(size - 1, int(math.ceil(by2)))

        for py in range(min_py, max_py + 1):
            for px in range(min_px, max_px + 1):
                # Distance to capsule (rounded rectangle)
                cx = bx + radius
                # Clamp y to straight segment
                cy = max(by1 + radius, min(by2 - radius, float(py)))
                dx = (px + 0.5) - cx
                dy = (py + 0.5) - cy
                dist = math.sqrt(dx * dx + dy * dy)

                coverage = max(0.0, min(1.0, radius + 0.5 - dist))
                if coverage > 0:
                    idx_pix = (py * size + px) * 4
                    curr_val = pixels[idx_pix]
                    new_val = min(255, int(curr_val + coverage * 255))
                    pixels[idx_pix + 0] = new_val
                    pixels[idx_pix + 1] = new_val
                    pixels[idx_pix + 2] = new_val
                    pixels[idx_pix + 3] = 255

    return pixels

def main():
    sizes = {
        "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": 48,
        "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": 72,
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": 96,
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": 144,
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": 192,
        "assets/icon/pulso_icon_512.png": 512,
    }

    os.makedirs("assets/icon", exist_ok=True)

    for path, size in sizes.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        pixels = render_pulso_icon(size)
        write_png(path, size, size, pixels)
        print(f"Generated {path} ({size}x{size})")

if __name__ == "__main__":
    main()
