#!/usr/bin/env python3
"""Generate Floor 3 (The Gearworks) asset pass — backgrounds + Crown Cog + environmental"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os
import math
import random

random.seed(42)

BASE_PATH = "/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/floor3"

# ── helpers ─────────────────────────────────────────────────────────────

def ensure_dir(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)

def get_font(size=10):
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size)
    except Exception:
        return ImageFont.load_default()

def get_font_regular(size=10):
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", size)
    except Exception:
        return ImageFont.load_default()

def darken(c, factor=0.7):
    return tuple(int(v * factor) for v in c[:3]) + c[3:] if len(c) > 3 else tuple(int(v * factor) for v in c)

def lighten(c, factor=1.3):
    return tuple(min(255, int(v * factor)) for v in c[:3]) + c[3:] if len(c) > 3 else tuple(min(255, int(v * factor)) for v in c)

def gradient_bg(draw, w, h, top_color, bot_color, steps=40):
    for y in range(h):
        ratio = y / h
        color = tuple(int(top_color[i] * (1 - ratio) + bot_color[i] * ratio) for i in range(3))
        draw.line([(0, y), (w, y)], fill=color)

def noise_overlay(img, intensity=15):
    w, h = img.size
    for _ in range(w * h // 8):
        x = random.randint(0, w - 1)
        y = random.randint(0, h - 1)
        r, g, b, a = img.getpixel((x, y))
        delta = random.randint(-intensity, intensity)
        img.putpixel((x, y), (max(0, min(255, r + delta)), max(0, min(255, g + delta)), max(0, min(255, b + delta)), a))

# ── Room Backgrounds (~800×600) ───────────────────────────────────────

def create_room_background(name, theme_desc, palette, features_fn, output_path, size=(800, 600)):
    """Create a rich atmospheric room background."""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (20, 20, 25, 255))
    draw = ImageDraw.Draw(img)
    w, h = size

    # Base gradient
    top_c, bot_c = palette['sky']
    gradient_bg(draw, w, h, top_c, bot_c)

    # Floor area (bottom ~40%)
    floor_y = int(h * 0.55)
    floor_c = palette['floor']
    for y in range(floor_y, h):
        ratio = (y - floor_y) / (h - floor_y)
        color = tuple(int(floor_c[i] * (1 - ratio * 0.3) + bot_c[i] * (ratio * 0.3)) for i in range(3))
        draw.line([(0, y), (w, y)], fill=color)

    # Add thematic features
    features_fn(draw, img, w, h, palette)

    # Vignette
    for y in range(h):
        for x in range(0, w, 4):
            dist = math.sqrt((x - w / 2) ** 2 + (y - h / 2) ** 2)
            max_dist = math.sqrt((w / 2) ** 2 + (h / 2) ** 2)
            vignette = int(40 * (dist / max_dist) ** 1.5)
            r, g, b, a = img.getpixel((x, y))
            img.putpixel((x, y), (max(0, r - vignette), max(0, g - vignette), max(0, b - vignette), a))

    noise_overlay(img, 12)
    img.save(output_path)
    print(f"Created BG: {output_path}")

# ── Feature generators for each room ────────────────────────────────────

def features_reservoir(draw, img, w, h, palette):
    # Water pools with pipes
    for i in range(5):
        cx = random.randint(80, w - 80)
        cy = random.randint(int(h * 0.6), h - 40)
        rx = random.randint(40, 100)
        ry = random.randint(20, 50)
        color = palette['water']
        draw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=color + (140,), outline=lighten(color, 1.2) + (180,), width=2)
        # Water highlight
        draw.arc([cx - rx + 5, cy - ry + 5, cx + rx - 5, cy + ry - 5], start=200, end=340, fill=lighten(color, 1.4) + (120,), width=2)

    # Pipes along walls
    for y in [int(h * 0.3), int(h * 0.5), int(h * 0.7)]:
        draw.rectangle([0, y, w, y + 12], fill=(50, 55, 60, 200), outline=(80, 85, 90, 255), width=1)
        for x in range(40, w, 120):
            draw.ellipse([x - 6, y - 3, x + 6, y + 15], fill=(70, 75, 80, 255), outline=(100, 105, 110, 255), width=1)

    # Steam vents
    for x in [150, 400, 650]:
        draw.rectangle([x - 10, int(h * 0.45), x + 10, int(h * 0.55)], fill=(60, 65, 70, 200), outline=(90, 95, 100, 255), width=2)
        for j in range(3):
            y = int(h * 0.4) - j * 15
            draw.arc([x - 15 + j * 3, y - 6, x + 15 - j * 3, y + 6], start=180, end=360, fill=(200, 210, 220, 80), width=2)

    # Large central reservoir pool
    draw.ellipse([w // 2 - 120, int(h * 0.65) - 40, w // 2 + 120, int(h * 0.65) + 40], fill=palette['water'] + (160,), outline=(100, 180, 200, 200), width=3)


def features_spark(draw, img, w, h, palette):
    # Furnaces / fire pits
    for cx, cy in [(180, int(h * 0.75)), (w - 180, int(h * 0.75)), (w // 2, int(h * 0.82))]:
        draw.rectangle([cx - 35, cy - 25, cx + 35, cy + 20], fill=(60, 35, 25, 220), outline=(100, 60, 40, 255), width=2)
        # Fire glow inside
        for j in range(5):
            fx = cx + random.randint(-20, 20)
            fy = cy + random.randint(-10, 10)
            draw.ellipse([fx - 8, fy - 8, fx + 8, fy + 8], fill=(255, 100 + j * 20, 20, 140 - j * 20))

    # Sparks floating
    for _ in range(40):
        x = random.randint(50, w - 50)
        y = random.randint(int(h * 0.3), h - 30)
        size = random.randint(2, 5)
        draw.ellipse([x, y, x + size, y + size], fill=(255, random.randint(100, 200), 30, random.randint(100, 220)))

    # Heat haze lines at top
    for y in range(0, int(h * 0.4), 20):
        draw.line([(0, y), (w, y)], fill=(255, 120, 40, 15), width=1)

    # Forge anvils
    for cx in [120, w - 120]:
        draw.polygon([(cx, int(h * 0.68)), (cx - 20, int(h * 0.78)), (cx + 20, int(h * 0.78))], fill=(50, 45, 40, 230), outline=(80, 75, 70, 255), width=2)
        draw.rectangle([cx - 15, int(h * 0.65), cx + 15, int(h * 0.68)], fill=(80, 75, 70, 255))


def features_governor(draw, img, w, h, palette):
    # Control panels with levers and gauges
    for cx in [150, w - 150, w // 2]:
        cy = int(h * 0.72)
        # Panel box
        draw.rectangle([cx - 50, cy - 35, cx + 50, cy + 35], fill=(55, 55, 60, 220), outline=(100, 100, 105, 255), width=2)
        # Gauges
        for gx in [cx - 25, cx, cx + 25]:
            draw.ellipse([gx - 12, cy - 20, gx + 12, cy + 4], fill=(200, 200, 190, 200), outline=(80, 80, 80, 255), width=1)
            # Needle
            angle = random.uniform(-1.0, 1.0)
            nx = gx + int(10 * math.sin(angle))
            ny = cy - 8 + int(10 * math.cos(angle))
            draw.line([(gx, cy - 8), (nx, ny)], fill=(180, 40, 40, 255), width=2)
        # Lever
        draw.rectangle([cx - 3, cy + 5, cx + 3, cy + 30], fill=(120, 100, 60, 255))
        draw.ellipse([cx - 8, cy + 25, cx + 8, cy + 38], fill=(80, 60, 40, 255))

    # Overhead pipes and valves
    for y in [int(h * 0.25), int(h * 0.38)]:
        draw.rectangle([0, y, w, y + 8], fill=(70, 70, 75, 200), outline=(100, 100, 105, 255), width=1)

    # Large central governor wheel
    cx, cy = w // 2, int(h * 0.45)
    draw.ellipse([cx - 60, cy - 60, cx + 60, cy + 60], fill=(100, 95, 85, 180), outline=(150, 145, 135, 255), width=3)
    draw.ellipse([cx - 30, cy - 30, cx + 30, cy + 30], fill=(80, 75, 70, 200), outline=(120, 115, 110, 255), width=2)
    # Spokes
    for angle in range(0, 360, 45):
        rad = math.radians(angle)
        x1 = cx + int(30 * math.cos(rad))
        y1 = cy + int(30 * math.sin(rad))
        x2 = cx + int(55 * math.cos(rad))
        y2 = cy + int(55 * math.sin(rad))
        draw.line([(x1, y1), (x2, y2)], fill=(140, 135, 125, 255), width=3)


def features_draft(draw, img, w, h, palette):
    # Air/steam vents and turbines
    for cx in [120, w - 120, w // 2]:
        cy = int(h * 0.55)
        # Vent tower
        draw.polygon([(cx, cy - 60), (cx - 20, cy), (cx + 20, cy)], fill=(140, 145, 150, 200), outline=(180, 185, 190, 255), width=2)
        draw.rectangle([cx - 15, cy, cx + 15, cy + 40], fill=(120, 125, 130, 220), outline=(160, 165, 170, 255), width=2)
        # Steam coming out
        for j in range(4):
            y = cy - 70 - j * 18
            draw.arc([cx - 20 + j * 4, y - 8, cx + 20 - j * 4, y + 8], start=180, end=360, fill=(220, 225, 230, 100 - j * 15), width=3)

    # Horizontal steam pipes
    for y in [int(h * 0.75), int(h * 0.85)]:
        draw.rectangle([0, y, w, y + 10], fill=(110, 115, 120, 180), outline=(150, 155, 160, 255), width=1)

    # Small turbines along floor
    for x in [200, 400, 600]:
        cy = int(h * 0.88)
        for blade in range(6):
            angle = math.radians(blade * 60)
            x1 = x + int(15 * math.cos(angle))
            y1 = cy + int(15 * math.sin(angle))
            x2 = x + int(30 * math.cos(angle))
            y2 = cy + int(30 * math.sin(angle))
            draw.line([(x1, y1), (x2, y2)], fill=(160, 165, 170, 200), width=3)
        draw.ellipse([x - 8, cy - 8, x + 8, cy + 8], fill=(130, 135, 140, 255))


def features_temper(draw, img, w, h, palette):
    # Forge heat — large central forge
    cx, cy = w // 2, int(h * 0.68)
    draw.rectangle([cx - 70, cy - 40, cx + 70, cy + 30], fill=(50, 30, 20, 230), outline=(100, 60, 35, 255), width=3)
    # Inner fire glow
    for j in range(8):
        fx = cx + random.randint(-50, 50)
        fy = cy + random.randint(-20, 10)
        size = random.randint(10, 25)
        draw.ellipse([fx - size, fy - size, fx + size, fy + size], fill=(255, random.randint(80, 160), 20, 120))

    # Anvils
    for ax in [120, w - 120]:
        draw.polygon([(ax, int(h * 0.72)), (ax - 18, int(h * 0.8)), (ax + 18, int(h * 0.8))], fill=(55, 50, 45, 240), outline=(90, 85, 80, 255), width=2)
        draw.rectangle([ax - 14, int(h * 0.68), ax + 14, int(h * 0.72)], fill=(85, 80, 75, 255))

    # Heat waves (wavy horizontal lines in upper area)
    for y in range(0, int(h * 0.5), 15):
        for x in range(0, w, 8):
            wave = int(5 * math.sin(x * 0.05 + y * 0.1))
            draw.point((x, y + wave), fill=(255, 150, 50, 30))

    # Hanging chains
    for x in [80, 200, w - 200, w - 80]:
        for cy in range(0, int(h * 0.45), 12):
            draw.ellipse([x - 3, cy, x + 3, cy + 8], fill=(90, 85, 80, 200), outline=(120, 115, 110, 255), width=1)


def features_beacon(draw, img, w, h, palette):
    # Tower with light beams
    cx = w // 2
    # Tower base
    draw.polygon([(cx, 40), (cx - 40, int(h * 0.75)), (cx + 40, int(h * 0.75))], fill=(160, 150, 120, 220), outline=(200, 190, 160, 255), width=2)
    # Tower top
    draw.polygon([(cx, 10), (cx - 25, 50), (cx + 25, 50)], fill=(200, 190, 160, 255))
    # Light source
    draw.ellipse([cx - 12, 25, cx + 12, 50], fill=(255, 255, 220, 255), outline=(255, 240, 150, 255), width=2)

    # Light beams radiating
    for angle in range(-60, 61, 15):
        rad = math.radians(angle - 90)
        x1 = cx + int(15 * math.cos(rad))
        y1 = 38 + int(15 * math.sin(rad))
        x2 = cx + int(350 * math.cos(rad))
        y2 = 38 + int(350 * math.sin(rad))
        draw.line([(x1, y1), (x2, y2)], fill=(255, 255, 200, 40), width=8)
        draw.line([(x1, y1), (x2, y2)], fill=(255, 255, 255, 60), width=3)

    # Prisms on floor
    for px in [150, w - 150]:
        py = int(h * 0.82)
        draw.polygon([(px, py - 25), (px - 15, py), (px + 15, py)], fill=(180, 210, 255, 180), outline=(200, 230, 255, 255), width=2)
        # Prism light scatter
        for angle in [-30, 0, 30]:
            rad = math.radians(angle - 90)
            x2 = px + int(80 * math.cos(rad))
            y2 = py - 25 + int(80 * math.sin(rad))
            draw.line([(px, py - 25), (x2, y2)], fill=(255, 200, 150, 60), width=3)

    # Golden floor pattern
    for x in range(0, w, 60):
        draw.line([(x, int(h * 0.75)), (x + 30, h)], fill=(180, 160, 100, 40), width=2)


def features_escapement(draw, img, w, h, palette):
    # Clockwork gears and pendulums
    # Large gear left
    draw_gear(draw, 160, int(h * 0.5), 70, (140, 120, 90, 200), (110, 95, 70, 255), teeth=12)
    # Medium gear right
    draw_gear(draw, w - 160, int(h * 0.55), 50, (160, 140, 110, 180), (130, 115, 90, 255), teeth=8)
    # Small gear top
    draw_gear(draw, w // 2, int(h * 0.25), 35, (150, 130, 100, 190), (120, 105, 80, 255), teeth=6)

    # Pendulum
    px = w // 2
    draw.line([(px, int(h * 0.15)), (px, int(h * 0.72))], fill=(140, 120, 90, 255), width=4)
    draw.ellipse([px - 18, int(h * 0.70), px + 18, int(h * 0.78)], fill=(160, 140, 110, 230), outline=(130, 110, 85, 255), width=2)

    # Clock face rings on back wall
    for cx, cy in [(120, int(h * 0.3)), (w - 120, int(h * 0.3))]:
        for r in [25, 35, 45]:
            draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(140, 120, 90, 120), width=1)
        # Tick marks
        for t in range(12):
            angle = math.radians(t * 30)
            x1 = cx + int(35 * math.cos(angle))
            y1 = cy + int(35 * math.sin(angle))
            x2 = cx + int(42 * math.cos(angle))
            y2 = cy + int(42 * math.sin(angle))
            draw.line([(x1, y1), (x2, y2)], fill=(140, 120, 90, 200), width=2)

    # Chain links along top
    for x in range(40, w, 30):
        draw.ellipse([x - 4, int(h * 0.1), x + 4, int(h * 0.18)], fill=(120, 105, 80, 200), outline=(150, 130, 105, 255), width=1)


def features_bearing(draw, img, w, h, palette):
    # Ball bearings and friction surfaces
    # Large bearing races on floor
    for cx, cy in [(w // 2, int(h * 0.7)), (180, int(h * 0.8)), (w - 180, int(h * 0.8))]:
        for r in [45, 55]:
            draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(130, 135, 140, 180), width=2)
        # Ball bearings inside
        for b in range(10):
            angle = math.radians(b * 36)
            bx = cx + int(50 * math.cos(angle))
            by = cy + int(50 * math.sin(angle))
            draw.ellipse([bx - 5, by - 5, bx + 5, by + 5], fill=(180, 185, 190, 230), outline=(150, 155, 160, 255), width=1)
        # Inner hub
        draw.ellipse([cx - 15, cy - 15, cx + 15, cy + 15], fill=(100, 105, 110, 255), outline=(140, 145, 150, 255), width=2)

    # Steel plates on walls
    for y in [int(h * 0.25), int(h * 0.4)]:
        for x in [80, w - 80]:
            draw.rectangle([x - 40, y - 20, x + 40, y + 20], fill=(110, 115, 120, 180), outline=(150, 155, 160, 255), width=2)
            # Rivets
            for rx in [x - 30, x, x + 30]:
                for ry in [y - 12, y + 12]:
                    draw.ellipse([rx - 2, ry - 2, rx + 2, ry + 2], fill=(160, 165, 170, 255))

    # Friction sparks (small bright dots)
    for _ in range(25):
        x = random.randint(50, w - 50)
        y = random.randint(int(h * 0.6), h - 30)
        draw.ellipse([x, y, x + 3, y + 3], fill=(255, 255, 200, random.randint(80, 200)))


def features_flywheel(draw, img, w, h, palette):
    # Large flywheel dominating center
    cx, cy = w // 2, int(h * 0.5)
    # Outer rim
    draw.ellipse([cx - 130, cy - 130, cx + 130, cy + 130], outline=(140, 130, 90, 220), width=6)
    draw.ellipse([cx - 120, cy - 120, cx + 120, cy + 120], outline=(180, 170, 120, 180), width=3)
    # Inner hub
    draw.ellipse([cx - 30, cy - 30, cx + 30, cy + 30], fill=(120, 110, 75, 230), outline=(160, 150, 110, 255), width=3)
    # Spokes
    for angle in range(0, 360, 30):
        rad = math.radians(angle)
        x1 = cx + int(30 * math.cos(rad))
        y1 = cy + int(30 * math.sin(rad))
        x2 = cx + int(120 * math.cos(rad))
        y2 = cy + int(120 * math.sin(rad))
        draw.line([(x1, y1), (x2, y2)], fill=(150, 140, 100, 200), width=4)

    # Motion blur arcs
    for r in [100, 115]:
        draw.arc([cx - r, cy - r, cx + r, cy + r], start=0, end=120, fill=(100, 180, 100, 60), width=4)
        draw.arc([cx - r, cy - r, cx + r, cy + r], start=180, end=300, fill=(100, 180, 100, 60), width=4)

    # Green brass floor panels
    for x in range(40, w, 80):
        for y in range(int(h * 0.78), h - 20, 40):
            draw.rectangle([x, y, x + 60, y + 30], fill=(80, 100, 60, 150), outline=(120, 150, 90, 200), width=1)


def features_counterweight(draw, img, w, h, palette):
    # Scales and balance
    # Large central scale
    cx, cy = w // 2, int(h * 0.55)
    # Pillar
    draw.rectangle([cx - 8, cy - 60, cx + 8, cy + 40], fill=(120, 120, 125, 255), outline=(160, 160, 165, 255), width=2)
    # Balance beam
    draw.rectangle([cx - 100, cy - 65, cx + 100, cy - 55], fill=(140, 140, 145, 255), outline=(180, 180, 185, 255), width=2)
    # Left pan
    draw.line([(cx - 80, cy - 55), (cx - 80, cy - 20)], fill=(150, 150, 155, 255), width=3)
    draw.ellipse([cx - 100, cy - 20, cx - 60, cy + 10], outline=(160, 160, 165, 255), width=2)
    # Right pan
    draw.line([(cx + 80, cy - 55), (cx + 80, cy - 20)], fill=(150, 150, 155, 255), width=3)
    draw.ellipse([cx + 60, cy - 20, cx + 100, cy + 10], outline=(160, 160, 165, 255), width=2)

    # Weight piles on floor
    for wx in [120, w - 120]:
        for i in range(5):
            wy = int(h * 0.82) - i * 8
            size = 18 - i * 2
            draw.rectangle([wx - size, wy - 6, wx + size, wy + 6], fill=(130, 130, 135, 230), outline=(170, 170, 175, 255), width=1)

    # Chain links hanging from ceiling
    for x in [100, w - 100, w // 2]:
        for ly in range(20, int(h * 0.35), 14):
            draw.ellipse([x - 5, ly, x + 5, ly + 10], fill=(110, 110, 115, 200), outline=(150, 150, 155, 255), width=1)


def features_oiler(draw, img, w, h, palette):
    # Oil cans, nozzles, grease
    # Workbench with oil cans
    draw.rectangle([80, int(h * 0.65), w - 80, int(h * 0.75)], fill=(50, 40, 30, 230), outline=(80, 70, 60, 255), width=2)
    for cx in [150, w // 2, w - 150]:
        # Oil can body
        draw.rectangle([cx - 15, int(h * 0.55), cx + 15, int(h * 0.65)], fill=(80, 60, 40, 255), outline=(120, 100, 70, 255), width=2)
        # Spout
        draw.line([(cx + 10, int(h * 0.58)), (cx + 25, int(h * 0.52))], fill=(100, 80, 55, 255), width=3)
        draw.ellipse([cx + 22, int(h * 0.50), cx + 30, int(h * 0.55)], fill=(60, 50, 35, 255))

    # Grease puddles on floor
    for _ in range(6):
        cx = random.randint(80, w - 80)
        cy = random.randint(int(h * 0.78), h - 30)
        rx = random.randint(20, 50)
        ry = random.randint(10, 25)
        draw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=(40, 35, 25, 160), outline=(60, 55, 40, 180), width=1)

    # Drip lines from ceiling
    for x in [120, 250, 400, 550, w - 120]:
        draw.line([(x, 0), (x, random.randint(int(h * 0.25), int(h * 0.45)))], fill=(50, 45, 35, 150), width=2)
        draw.ellipse([x - 3, int(h * 0.42), x + 3, int(h * 0.46)], fill=(45, 40, 30, 200))

    # Nozzle array on back wall
    for x in range(100, w, 100):
        draw.rectangle([x - 6, int(h * 0.3), x + 6, int(h * 0.45)], fill=(70, 60, 50, 220), outline=(100, 90, 75, 255), width=1)
        draw.polygon([(x, int(h * 0.28)), (x - 8, int(h * 0.33)), (x + 8, int(h * 0.33))], fill=(90, 80, 65, 255))


def features_quench(draw, img, w, h, palette):
    # Crystal formations + water cooling (start room)
    # Crystal clusters
    for cx in [120, w - 120, w // 2]:
        cy = int(h * 0.72)
        for i in range(5):
            tip_x = cx + random.randint(-25, 25)
            tip_y = cy - random.randint(30, 70)
            base_x = cx + random.randint(-20, 20)
            draw.polygon([(base_x - 8, cy), (base_x + 8, cy), (tip_x, tip_y)], fill=palette['crystal'] + (180,), outline=lighten(palette['crystal'], 1.2) + (220,), width=1)

    # Central large crystal
    cx = w // 2
    draw.polygon([(cx - 20, int(h * 0.75)), (cx + 20, int(h * 0.75)), (cx, int(h * 0.35))], fill=palette['crystal'] + (200,), outline=(180, 230, 255, 255), width=2)
    draw.polygon([(cx - 10, int(h * 0.6)), (cx + 10, int(h * 0.6)), (cx - 5, int(h * 0.45))], fill=lighten(palette['crystal'], 1.1) + (160,))

    # Water pool at base
    draw.ellipse([w // 2 - 100, int(h * 0.82), w // 2 + 100, int(h * 0.95)], fill=(40, 80, 130, 160), outline=(80, 140, 190, 200), width=2)
    # Water highlights
    draw.arc([w // 2 - 80, int(h * 0.83), w // 2 + 80, int(h * 0.92)], start=200, end=340, fill=(120, 180, 230, 120), width=2)

    # Icicle-like drip formations from ceiling
    for x in range(60, w, 50):
        length = random.randint(20, 60)
        draw.polygon([(x - 5, 0), (x + 5, 0), (x, length)], fill=(180, 210, 240, 150), outline=(200, 230, 255, 200), width=1)

    # Cooling mist
    for _ in range(30):
        x = random.randint(50, w - 50)
        y = random.randint(int(h * 0.55), int(h * 0.8))
        draw.ellipse([x, y, x + 6, y + 4], fill=(200, 220, 240, random.randint(30, 80)))


# ── Gear helper ─────────────────────────────────────────────────────────

def draw_gear(draw, cx, cy, radius, fill_color, outline_color, teeth=8):
    points = []
    inner_r = radius * 0.65
    for i in range(teeth * 2):
        angle = (360 / (teeth * 2)) * i
        rad = math.radians(angle)
        if i % 2 == 0:
            r = radius
        else:
            r = inner_r
        x = cx + r * math.cos(rad)
        y = cy + r * math.sin(rad)
        points.append((x, y))
    draw.polygon(points, fill=fill_color, outline=outline_color, width=2)
    draw.ellipse([cx - radius * 0.2, cy - radius * 0.2, cx + radius * 0.2, cy + radius * 0.2], fill=darken(fill_color[:3], 0.8) + (fill_color[3] if len(fill_color) > 3 else 255,))


# ── Crown Cog Assets ───────────────────────────────────────────────────

def create_crown_cog_hub(output_path, size=512):
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = cy = size // 2

    # Outer ring with gear teeth
    outer_r = size // 2 - 10
    teeth = 16
    points = []
    inner_r = outer_r * 0.82
    for i in range(teeth * 2):
        angle = (360 / (teeth * 2)) * i
        rad = math.radians(angle)
        r = outer_r if i % 2 == 0 else inner_r
        points.append((cx + r * math.cos(rad), cy + r * math.sin(rad)))
    draw.polygon(points, fill=(184, 134, 11, 255), outline=(218, 165, 32, 255), width=3)

    # Middle ring
    mid_r = outer_r * 0.65
    draw.ellipse([cx - mid_r, cy - mid_r, cx + mid_r, cy + mid_r], fill=(160, 120, 20, 255), outline=(200, 170, 50, 255), width=3)

    # Inner hub
    hub_r = outer_r * 0.35
    draw.ellipse([cx - hub_r, cy - hub_r, cx + hub_r, cy + hub_r], fill=(139, 90, 43, 255), outline=(218, 165, 32, 255), width=3)

    # Center gem
    gem_r = hub_r * 0.4
    draw.ellipse([cx - gem_r, cy - gem_r, cx + gem_r, cy + gem_r], fill=(255, 220, 100, 255), outline=(255, 255, 200, 255), width=2)

    # Decorative spokes
    for angle in range(0, 360, 45):
        rad = math.radians(angle)
        x1 = cx + int(hub_r * math.cos(rad))
        y1 = cy + int(hub_r * math.sin(rad))
        x2 = cx + int(mid_r * 0.9 * math.cos(rad))
        y2 = cy + int(mid_r * 0.9 * math.sin(rad))
        draw.line([(x1, y1), (x2, y2)], fill=(218, 165, 32, 255), width=4)

    # Inscription ring text
    font = get_font(14)
    text = "CROWN COG"
    for i, ch in enumerate(text):
        angle = math.radians(180 + i * 18)
        tx = cx + int((mid_r + 20) * math.cos(angle))
        ty = cy + int((mid_r + 20) * math.sin(angle))
        draw.text((tx - 6, ty - 7), ch, fill=(255, 230, 150, 255), font=font)

    img.save(output_path)
    print(f"Created: {output_path}")


def create_machinist_npc(output_path, size=64):
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = size // 2

    # Body — bronze construct
    draw.ellipse([cx - 18, 18, cx + 18, 50], fill=(139, 90, 43, 255), outline=(184, 134, 11, 255), width=2)
    # Head
    draw.ellipse([cx - 12, 4, cx + 12, 24], fill=(160, 110, 50, 255), outline=(200, 160, 80, 255), width=2)
    # Eyes — glowing
    draw.ellipse([cx - 7, 10, cx - 2, 16], fill=(100, 200, 255, 255), outline=(150, 230, 255, 255), width=1)
    draw.ellipse([cx + 2, 10, cx + 7, 16], fill=(100, 200, 255, 255), outline=(150, 230, 255, 255), width=1)
    # Gear on chest
    draw_gear(draw, cx, 34, 8, (184, 134, 11, 255), (218, 165, 32, 255), teeth=6)
    # Arms
    draw.line([(cx - 18, 30), (cx - 28, 44)], fill=(139, 90, 43, 255), width=4)
    draw.line([(cx + 18, 30), (cx + 28, 44)], fill=(139, 90, 43, 255), width=4)
    # Wrench in right hand
    draw.line([(cx + 28, 40), (cx + 36, 32)], fill=(180, 180, 190, 255), width=3)
    draw.line([(cx + 33, 29), (cx + 39, 35)], fill=(180, 180, 190, 255), width=3)
    # Legs
    draw.line([(cx - 8, 50), (cx - 10, 62)], fill=(120, 80, 35, 255), width=4)
    draw.line([(cx + 8, 50), (cx + 10, 62)], fill=(120, 80, 35, 255), width=4)

    img.save(output_path)
    print(f"Created: {output_path}")


def create_dial_button(output_path, size=64):
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = size // 2

    # Outer ring with tick marks
    outer_r = size // 2 - 4
    draw.ellipse([cx - outer_r, cx - outer_r, cx + outer_r, cx + outer_r], fill=(50, 50, 55, 220), outline=(120, 120, 130, 255), width=2)

    # Tick marks
    for i in range(12):
        angle = math.radians(i * 30)
        x1 = cx + int((outer_r - 6) * math.cos(angle))
        y1 = cx + int((outer_r - 6) * math.sin(angle))
        x2 = cx + int(outer_r * math.cos(angle))
        y2 = cx + int(outer_r * math.sin(angle))
        draw.line([(x1, y1), (x2, y2)], fill=(180, 180, 190, 255), width=2)

    # Inner dial
    inner_r = outer_r * 0.6
    draw.ellipse([cx - inner_r, cx - inner_r, cx + inner_r, cx + inner_r], fill=(80, 75, 60, 255), outline=(180, 160, 80, 255), width=2)

    # Pointer
    draw.polygon([(cx, cx - inner_r + 4), (cx - 5, cx + 4), (cx + 5, cx + 4)], fill=(255, 100, 50, 255), outline=(255, 150, 80, 255), width=1)

    # "R" text for rotate
    font = get_font(12)
    bbox = draw.textbbox((0, 0), "R", font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text((cx - tw // 2, cx - th // 2 + 1), "R", fill=(255, 255, 255, 255), font=font)

    img.save(output_path)
    print(f"Created: {output_path}")


def create_boss_altar(output_path, size=128):
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    w = h = size
    cx = w // 2

    # Base platform
    draw.polygon([(cx, h - 10), (20, h - 35), (w - 20, h - 35)], fill=(60, 50, 40, 255), outline=(100, 85, 70, 255), width=2)
    draw.rectangle([20, h - 50, w - 20, h - 35], fill=(80, 70, 55, 255), outline=(120, 105, 85, 255), width=2)

    # Altar pillar
    draw.rectangle([cx - 20, h - 80, cx + 20, h - 50], fill=(100, 85, 65, 255), outline=(140, 125, 100, 255), width=2)

    # Crown Cog symbol on pillar
    draw_gear(draw, cx, h - 65, 12, (184, 134, 11, 255), (218, 165, 32, 255), teeth=8)

    # Glowing top orb
    draw.ellipse([cx - 14, h - 100, cx + 14, h - 72], fill=(255, 200, 50, 230), outline=(255, 240, 150, 255), width=2)
    # Inner bright core
    draw.ellipse([cx - 6, h - 92, cx + 6, h - 80], fill=(255, 255, 220, 255))

    # Side runes
    for x in [cx - 30, cx + 30]:
        draw.rectangle([x - 4, h - 70, x + 4, h - 55], fill=(120, 100, 70, 255))
        draw.text((x - 3, h - 68), "⚙", fill=(200, 180, 100, 255), font=get_font(8))

    img.save(output_path)
    print(f"Created: {output_path}")


def create_light_widget(output_path, size=32):
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = size // 2

    # Crystal lens
    draw.polygon([(cx, 2), (size - 4, cx), (cx, size - 2), (4, cx)], fill=(200, 220, 255, 200), outline=(255, 255, 255, 255), width=2)
    # Inner glow
    draw.polygon([(cx, 8), (size - 10, cx), (cx, size - 8), (10, cx)], fill=(255, 255, 200, 180))
    # Center bright dot
    draw.ellipse([cx - 3, cx - 3, cx + 3, cx + 3], fill=(255, 255, 255, 255))

    img.save(output_path)
    print(f"Created: {output_path}")


# ── Environmental Assets ────────────────────────────────────────────────

def create_hex_gearworks_floor(output_path, size=64):
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = size // 2
    radius = size // 2 - 2

    # Brass/metal hex
    points = []
    for i in range(6):
        angle = 60 * i - 30
        x = cx + radius * 0.9 * math.cos(math.radians(angle))
        y = cx + radius * 0.9 * math.sin(math.radians(angle))
        points.append((x, y))

    brass = (160, 130, 60, 220)
    draw.polygon(points, fill=brass, outline=(200, 170, 90, 255), width=2)

    # Gear imprint in center
    draw_gear(draw, cx, cx, radius * 0.35, (120, 95, 45, 200), (160, 135, 65, 255), teeth=6)

    # Metal grain lines
    for y in range(8, size, 12):
        draw.line([(4, y), (size - 4, y)], fill=(140, 115, 55, 60), width=1)

    img.save(output_path)
    print(f"Created: {output_path}")


def create_hex_ring_corridor(output_path, size=64):
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = size // 2
    radius = size // 2 - 2

    # Darker ring corridor hex
    points = []
    for i in range(6):
        angle = 60 * i - 30
        x = cx + radius * 0.9 * math.cos(math.radians(angle))
        y = cx + radius * 0.9 * math.sin(math.radians(angle))
        points.append((x, y))

    dark = (45, 42, 48, 230)
    draw.polygon(points, fill=dark, outline=(70, 65, 75, 255), width=2)

    # Ring band
    for r in [radius * 0.5, radius * 0.7]:
        draw.ellipse([cx - r, cx - r, cx + r, cx + r], outline=(80, 75, 85, 180), width=1)

    img.save(output_path)
    print(f"Created: {output_path}")


def create_wall_gearworks(output_path, size=64):
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Metal wall segment with rivets
    draw.rectangle([0, 0, size, size], fill=(70, 68, 72, 255), outline=(100, 98, 105, 255), width=2)

    # Vertical panel seams
    for x in [size // 3, 2 * size // 3]:
        draw.line([(x, 0), (x, size)], fill=(55, 53, 58, 255), width=2)

    # Rivets
    for x in [10, size // 2, size - 10]:
        for y in [10, size // 2, size - 10]:
            draw.ellipse([x - 2, y - 2, x + 2, y + 2], fill=(130, 128, 135, 255), outline=(160, 158, 165, 255), width=1)

    img.save(output_path)
    print(f"Created: {output_path}")


def create_trap_cog(output_path, size=64):
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = size // 2

    # Spinning cog trap
    draw_gear(draw, cx, cx, size // 2 - 4, (180, 40, 40, 220), (220, 60, 60, 255), teeth=8)
    # Danger spikes on teeth
    for i in range(8):
        angle = math.radians(i * 45)
        x = cx + int((size // 2 - 4) * math.cos(angle))
        y = cx + int((size // 2 - 4) * math.sin(angle))
        draw.polygon([(x, y), (x - 3 + int(8 * math.cos(angle + 0.3)), y - 3 + int(8 * math.sin(angle + 0.3))),
                      (x + 3 + int(8 * math.cos(angle - 0.3)), y + 3 + int(8 * math.sin(angle - 0.3)))],
                     fill=(255, 80, 80, 255), outline=(255, 120, 120, 255), width=1)

    img.save(output_path)
    print(f"Created: {output_path}")


def create_trap_compression(output_path, size=64):
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Two plates crushing together
    draw.rectangle([4, 4, size - 4, size // 2 - 4], fill=(120, 120, 125, 220), outline=(160, 160, 165, 255), width=2)
    draw.rectangle([4, size // 2 + 4, size - 4, size - 4], fill=(120, 120, 125, 220), outline=(160, 160, 165, 255), width=2)
    # Warning stripes
    for x in range(8, size - 8, 12):
        draw.polygon([(x, size // 2 - 8), (x + 6, size // 2 - 4), (x + 6, size // 2 + 4), (x, size // 2 + 8)], fill=(255, 180, 20, 200))

    # Sparks in middle
    for _ in range(8):
        x = random.randint(12, size - 12)
        y = random.randint(size // 2 - 6, size // 2 + 6)
        draw.ellipse([x, y, x + 3, y + 3], fill=(255, 200, 50, 220))

    img.save(output_path)
    print(f"Created: {output_path}")


def create_trap_recalibration(output_path, size=64):
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = size // 2

    # Target / calibration rings
    for r in [12, 20, 28]:
        draw.ellipse([cx - r, cx - r, cx + r, cx + r], outline=(255, 180, 30, 220), width=2)
    # Crosshairs
    draw.line([(cx, 4), (cx, size - 4)], fill=(255, 180, 30, 200), width=2)
    draw.line([(4, cx), (size - 4, cx)], fill=(255, 180, 30, 200), width=2)

    # Laser beams from corners
    for corner in [(4, 4), (size - 4, 4), (4, size - 4), (size - 4, size - 4)]:
        draw.line([corner, (cx, cx)], fill=(255, 80, 80, 120), width=2)

    # Center warning dot
    draw.ellipse([cx - 5, cx - 5, cx + 5, cx + 5], fill=(255, 60, 60, 255), outline=(255, 120, 120, 255), width=2)

    img.save(output_path)
    print(f"Created: {output_path}")


# ── Room background palettes ────────────────────────────────────────────

ROOMS = [
    ('reservoir', 'Water/cooling, pools and pipes', {
        'sky': ((25, 40, 60), (15, 30, 50)),
        'floor': (35, 50, 65),
        'water': (40, 100, 160),
    }, features_reservoir),
    ('spark', 'Fire/ignition, furnaces and sparks', {
        'sky': ((50, 20, 15), (30, 15, 10)),
        'floor': (70, 40, 30),
        'water': None,
    }, features_spark),
    ('governor', 'Control/mechanical, levers and gauges', {
        'sky': ((45, 45, 50), (30, 30, 35)),
        'floor': (55, 55, 60),
        'water': None,
    }, features_governor),
    ('draft', 'Air/steam pipes, vents and turbines', {
        'sky': ((55, 60, 65), (40, 45, 50)),
        'floor': (75, 80, 85),
        'water': None,
    }, features_draft),
    ('temper', 'Forge/heat, anvils and heat waves', {
        'sky': ((55, 30, 20), (35, 20, 15)),
        'floor': (80, 50, 35),
        'water': None,
    }, features_temper),
    ('beacon', 'Tower/light, light beams and prisms', {
        'sky': ((40, 38, 45), (25, 23, 30)),
        'floor': (70, 65, 50),
        'water': None,
    }, features_beacon),
    ('escapement', 'Clockwork/time, gears and pendulums', {
        'sky': ((50, 40, 30), (35, 28, 22)),
        'floor': (65, 55, 42),
        'water': None,
    }, features_escapement),
    ('bearing', 'Friction/metal, ball bearings', {
        'sky': ((50, 52, 55), (35, 37, 40)),
        'floor': (70, 72, 75),
        'water': None,
    }, features_bearing),
    ('flywheel', 'Spinning/momentum, large wheel', {
        'sky': ((35, 45, 30), (22, 30, 20)),
        'floor': (55, 70, 45),
        'water': None,
    }, features_flywheel),
    ('counterweight', 'Balance/scale, scales and weights', {
        'sky': ((48, 48, 52), (32, 32, 36)),
        'floor': (65, 65, 70),
        'water': None,
    }, features_counterweight),
    ('oiler', 'Maintenance/grease, oil cans and nozzles', {
        'sky': ((35, 32, 28), (22, 20, 18)),
        'floor': (45, 40, 35),
        'water': None,
    }, features_oiler),
    ('quench', 'Water/cooling, crystal formations', {
        'sky': ((30, 45, 60), (18, 30, 45)),
        'floor': (40, 55, 70),
        'water': (50, 110, 170),
        'crystal': (160, 210, 245),
    }, features_quench),
]


def main():
    os.makedirs(BASE_PATH, exist_ok=True)
    print("=== Generating Floor 3 Assets ===\n")

    # 1. Room backgrounds (12)
    for room_name, desc, palette, features_fn in ROOMS:
        output_path = os.path.join(BASE_PATH, f"bg_{room_name}.png")
        create_room_background(room_name, desc, palette, features_fn, output_path)

    print()

    # 2. Crown Cog assets
    create_crown_cog_hub(os.path.join(BASE_PATH, "crown_cog_hub.png"))
    create_machinist_npc(os.path.join(BASE_PATH, "machinist_npc.png"))
    create_dial_button(os.path.join(BASE_PATH, "dial_button.png"))
    create_boss_altar(os.path.join(BASE_PATH, "boss_altar.png"))
    create_light_widget(os.path.join(BASE_PATH, "light_widget.png"))

    print()

    # 3. Environmental
    create_hex_gearworks_floor(os.path.join(BASE_PATH, "hex_gearworks_floor.png"))
    create_hex_ring_corridor(os.path.join(BASE_PATH, "hex_ring_corridor.png"))
    create_wall_gearworks(os.path.join(BASE_PATH, "wall_gearworks.png"))
    create_trap_cog(os.path.join(BASE_PATH, "trap_cog.png"))
    create_trap_compression(os.path.join(BASE_PATH, "trap_compression.png"))
    create_trap_recalibration(os.path.join(BASE_PATH, "trap_recalibration.png"))

    print("\n=== FLOOR 3 ASSET GENERATION COMPLETE ===")
    # Count files
    files = [f for f in os.listdir(BASE_PATH) if f.endswith('.png')]
    print(f"Total PNG assets in {BASE_PATH}: {len(files)}")
    for f in sorted(files):
        print(f"  - {f}")


if __name__ == "__main__":
    main()
