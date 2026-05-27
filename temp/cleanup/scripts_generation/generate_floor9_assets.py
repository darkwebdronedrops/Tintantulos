#!/usr/bin/env python3
"""Generate Floor 9 (The Bone Forges) pixel art assets using PIL"""

from PIL import Image, ImageDraw
import os
import math
import random

random.seed(42)

BASE_PATH = "/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/floor9"

def ensure_dir(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)

def draw_hexagon(draw, cx, cy, radius, fill, outline=None, width=2):
    pts = []
    for i in range(6):
        angle = math.radians(60 * i - 30)
        pts.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle)))
    draw.polygon(pts, fill=fill, outline=outline, width=width)

# =======================================================================
# PALETTE — Bone Forges
# =======================================================================
BONE_WHITE = (220, 215, 200)
BONE_DARK = (180, 170, 150)
FACTORY_GRAY = (90, 90, 95)
FACTORY_DARK = (55, 55, 60)
SOUL_GREEN = (50, 220, 80)
SOUL_GLOW = (30, 180, 60)
SOUL_DARK = (20, 100, 30)
RUST_ORANGE = (180, 80, 30)
RUST_DARK = (120, 50, 20)
BLOOD_BROWN = (100, 40, 30)
BRASS = (184, 150, 80)
BRASS_DARK = (140, 110, 60)
IRON = (120, 120, 125)
IRON_DARK = (80, 80, 85)
MARROW = (200, 100, 80)

def darken(c, factor=0.7):
    return tuple(min(255, int(x * factor)) for x in c)

def lighten(c, factor=1.3):
    return tuple(min(255, int(x * factor)) for x in c)

# =======================================================================
# ROOM BACKGROUNDS
# =======================================================================

def make_bg_loading_dock():
    w, h = 2200, 1600
    img = Image.new('RGBA', (w, h), (35, 32, 30, 255))
    draw = ImageDraw.Draw(img)
    # Factory floor with bone dust
    for y in range(0, h, 35):
        shade = 32 + int(12 * math.sin(y / 90))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 2, shade - 4), width=3)
    # Bone crates
    for i in range(5):
        x = 150 + i * 450
        y = 350 + (i % 2) * 280
        draw.rectangle([x, y, x + 180, y + 140], fill=(70, 65, 58, 230), outline=BONE_DARK, width=3)
        # Bone parts sticking out
        for j in range(4):
            bx = x + 20 + j * 35
            by = y - 15
            draw.rectangle([bx, by, bx + 8, by + 25], fill=BONE_WHITE, outline=BONE_DARK, width=1)
        # Lye stain
        for r in range(5, 30, 8):
            alpha = max(0, 60 - r)
            draw.ellipse([x + 80 - r, y + 100 - r * 0.3, x + 140 + r, y + 140 + r * 0.3], fill=(200, 200, 220, alpha))
    # Fresh corpses (covered, subtle)
    for i in range(3):
        x = 300 + i * 600
        y = 1100 + (i % 2) * 150
        draw.rectangle([x, y, x + 120, y + 60], fill=(80, 60, 55, 180), outline=(60, 45, 40), width=1)
        # Sheet draped
        draw.polygon([(x, y), (x + 120, y), (x + 100, y - 30), (x + 20, y - 20)], fill=(90, 85, 80, 150))
    # Iron hooks on chains
    for i in range(4):
        x = 250 + i * 500
        y = 100
        # Chain
        for j in range(12):
            cy = y + j * 30
            draw.ellipse([x - 4, cy - 4, x + 4, cy + 4], fill=IRON, outline=IRON_DARK, width=1)
        # Hook
        draw.polygon([(x - 8, y + 360), (x + 8, y + 360), (x, y + 390)], fill=IRON, outline=IRON_DARK, width=2)
    return img

def make_bg_assembly_line():
    w, h = 2400, 1600
    img = Image.new('RGBA', (w, h), (40, 35, 32, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 30):
        shade = 35 + int(10 * math.sin(y / 70))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 3, shade - 5), width=2)
    # Conveyor belts
    for i in range(4):
        x = 100 + i * 550
        y = 400 + (i % 2) * 400
        draw.rectangle([x, y, x + 450, y + 80], fill=(50, 50, 55, 240), outline=IRON, width=3)
        # Belt arrows
        for j in range(6):
            ax = x + 30 + j * 70
            ay = y + 40
            draw.polygon([(ax, ay - 8), (ax + 20, ay), (ax, ay + 8)], fill=(120, 120, 130, 200))
    # Ribcage parts on belt
    for i in range(5):
        x = 200 + i * 450
        y = 430 + (i % 3) * 400
        # Ribcage shape
        draw.arc([x, y, x + 60, y + 50], start=180, end=360, fill=BONE_WHITE, width=3)
        for j in range(3):
            rx = x + 10 + j * 15
            draw.line([(rx, y + 25), (rx + 5, y + 45)], fill=BONE_WHITE, width=2)
    # Brass arms
    for i in range(3):
        x = 500 + i * 700
        y = 800 + (i % 2) * 300
        draw.rectangle([x, y, x + 80, y + 30], fill=BRASS, outline=BRASS_DARK, width=2)
        draw.rectangle([x + 60, y - 10, x + 100, y + 40], fill=BRASS + (200,), outline=BRASS_DARK, width=2)
        # Hand (bone + brass)
        draw.ellipse([x + 90, y + 5, x + 120, y + 30], fill=BONE_WHITE, outline=BONE_DARK, width=2)
    # Glowing soul eyes
    for i in range(6):
        x = 300 + i * 350
        y = 600 + (i % 2) * 200
        draw.ellipse([x, y, x + 15, y + 12], fill=SOUL_GREEN + (200,), outline=SOUL_DARK, width=1)
        draw.ellipse([x + 20, y, x + 35, y + 12], fill=SOUL_GREEN + (200,), outline=SOUL_DARK, width=1)
        # Glow
        for r in range(5, 20, 5):
            alpha = max(0, 100 - r * 5)
            draw.ellipse([x - r, y - r, x + 35 + r, y + 12 + r], fill=SOUL_GREEN + (alpha,))
    return img

def make_bg_break_station():
    w, h = 2000, 1400
    img = Image.new('RGBA', (w, h), (55, 50, 45, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 45):
        shade = 50 + int(10 * math.sin(y / 90))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 3, shade - 5), width=3)
    # Assembly table
    draw.rectangle([600, 500, 1400, 900], fill=(80, 75, 70, 240), outline=BONE_DARK, width=3)
    # Bone piles on table
    for i in range(8):
        bx = 650 + i * 90
        by = 550 + (i % 2) * 40
        draw.rectangle([bx, by, bx + 30, by + 60], fill=BONE_WHITE, outline=BONE_DARK, width=1)
    # Gear stacks
    for i in range(5):
        gx = 1100 + i * 50
        gy = 600 + (i % 3) * 50
        draw.ellipse([gx, gy, gx + 40, gy + 40], fill=BRASS + (200,), outline=BRASS_DARK, width=1)
        draw.ellipse([gx + 10, gy + 10, gx + 30, gy + 30], fill=(80, 75, 70))
    # Safe room lanterns (green soul light)
    for i in range(3):
        x = 200 + i * 800
        y = 200
        draw.ellipse([x - 20, y - 20, x + 20, y + 20], fill=SOUL_GREEN + (100,))
        draw.line([(x, y + 20), (x, y + 80)], fill=IRON, width=2)
    # Chairs
    for i in range(4):
        x = 300 + i * 400
        y = 1100
        draw.rectangle([x, y, x + 60, y + 80], fill=(70, 65, 60))
        draw.rectangle([x - 5, y - 30, x + 65, y + 5], fill=(60, 55, 50))
    return img

def make_bg_furnace_room():
    w, h = 2200, 1600
    img = Image.new('RGBA', (w, h), (25, 22, 20, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 25):
        shade = 22 + int(8 * math.sin(y / 50))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 2, shade - 3), width=2)
    # 3 Soul forges (glowing green)
    for i in range(3):
        x = 300 + i * 700
        y = 400
        # Forge body
        draw.rectangle([x, y, x + 500, y + 500], fill=(50, 45, 40, 240), outline=FACTORY_GRAY, width=4)
        # Green glow from within
        for r in range(20, 150, 15):
            alpha = max(0, 180 - r)
            draw.ellipse([x + 50 - r, y + 100 - r * 0.6, x + 450 + r, y + 400 + r * 0.6], fill=SOUL_GREEN + (alpha,))
        # Soul flames
        for j in range(5):
            fx = x + 80 + j * 70
            fy = y + 350
            draw.ellipse([fx, fy - 30, fx + 20, fy + 10], fill=SOUL_GLOW + (200,), outline=SOUL_DARK, width=1)
    # Smokestacks of femurs
    for i in range(4):
        x = 200 + i * 550
        y = 100
        # Femur-shaped stack
        draw.rectangle([x, y, x + 40, y + 200], fill=BONE_WHITE, outline=BONE_DARK, width=2)
        draw.ellipse([x - 10, y - 15, x + 50, y + 20], fill=BONE_WHITE, outline=BONE_DARK, width=2)
        draw.ellipse([x - 10, y + 185, x + 50, y + 220], fill=BONE_WHITE, outline=BONE_DARK, width=2)
        # Green smoke
        for j in range(6):
            sy = y - 40 - j * 30
            sx = x + 20 + int(15 * math.sin(j))
            for r in range(5, 25, 8):
                alpha = max(0, 60 - r - j * 5)
                draw.ellipse([sx - r, sy - r, sx + r, sy + r], fill=SOUL_GREEN + (alpha,))
    # Trapped souls (floating orbs)
    for i in range(8):
        x = 150 + i * 260
        y = 950 + (i % 2) * 200
        for r in range(3, 15, 5):
            alpha = max(0, 150 - r * 8)
            draw.ellipse([x - r, y - r, x + r, y + r], fill=SOUL_GREEN + (alpha,))
        draw.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(200, 255, 200, 220))
    return img

def make_bg_quality_control():
    w, h = 2200, 1600
    img = Image.new('RGBA', (w, h), (40, 38, 35, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 30):
        shade = 35 + int(10 * math.sin(y / 70))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 3, shade - 5), width=2)
    # Testing chambers (glass pods)
    for i in range(3):
        x = 250 + i * 700
        y = 400
        draw.rectangle([x, y, x + 400, y + 450], fill=(60, 60, 65, 180), outline=(150, 160, 170), width=3)
        # Pod interior
        draw.rectangle([x + 20, y + 20, x + 380, y + 400], fill=(40, 45, 50, 200))
        # Construct inside (silhouette)
        draw.ellipse([x + 150, y + 200, x + 250, y + 300], fill=(80, 80, 85, 150))
        draw.ellipse([x + 170, y + 150, x + 230, y + 210], fill=(80, 80, 85, 150))
    # Combat arena center
    draw.rectangle([800, 950, 1400, 1250], fill=(70, 65, 60, 200), outline=RUST_ORANGE, width=3)
    # Arena markings
    for i in range(4):
        ax = 850 + i * 120
        draw.line([(ax, 1000), (ax, 1200)], fill=RUST_DARK, width=2)
    return img

def make_bg_bone_yard():
    w, h = 2400, 1600
    img = Image.new('RGBA', (w, h), (45, 42, 38, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 20):
        shade = 40 + int(8 * math.sin(y / 60))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 3, shade - 5), width=2)
    # Endless skeleton piles
    for i in range(20):
        x = random.randint(100, 2200)
        y = random.randint(300, 1400)
        # Pile of bones
        for j in range(5):
            bx = x + random.randint(-30, 30)
            by = y + random.randint(-20, 20)
            draw.rectangle([bx, by, bx + random.randint(20, 40), by + random.randint(10, 25)], fill=BONE_WHITE, outline=BONE_DARK, width=1)
            # Skull
            if j == 0:
                draw.ellipse([bx + 5, by - 15, bx + 25, by + 5], fill=BONE_WHITE, outline=BONE_DARK, width=1)
    # Bone dust clouds
    for i in range(8):
        x = random.randint(200, 2100)
        y = random.randint(200, 1300)
        for r in range(10, 60, 10):
            alpha = max(0, 40 - r // 2)
            draw.ellipse([x - r, y - r * 0.5, x + r, y + r * 0.5], fill=(180, 175, 160, alpha))
    # Respawning undead (silhouettes)
    for i in range(5):
        x = 300 + i * 450
        y = 1100
        draw.ellipse([x, y, x + 35, y + 50], fill=(60, 65, 60, 150), outline=(50, 55, 50), width=1)
        draw.ellipse([x + 5, y - 15, x + 30, y + 5], fill=(60, 65, 60, 150))
        # Glowing eyes
        draw.ellipse([x + 8, y - 8, x + 14, y - 2], fill=SOUL_GREEN + (150,))
        draw.ellipse([x + 20, y - 8, x + 26, y - 2], fill=SOUL_GREEN + (150,))
    return img

def make_bg_gear_works():
    w, h = 2000, 1400
    img = Image.new('RGBA', (w, h), (50, 48, 45, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 35):
        shade = 45 + int(10 * math.sin(y / 80))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 3, shade - 5), width=3)
    # Skull-faced machinists (workbenches)
    for i in range(4):
        x = 200 + i * 450
        y = 500
        # Workbench
        draw.rectangle([x, y, x + 250, y + 120], fill=(70, 68, 65, 240), outline=IRON, width=2)
        # Machinist silhouette
        draw.ellipse([x + 80, y - 60, x + 170, y + 10], fill=(60, 60, 65, 200))
        # Skull face
        draw.ellipse([x + 100, y - 50, x + 150, y - 10], fill=BONE_WHITE, outline=BONE_DARK, width=2)
        # Eye sockets (soul green)
        draw.ellipse([x + 110, y - 40, x + 122, y - 28], fill=SOUL_GREEN + (180,))
        draw.ellipse([x + 128, y - 40, x + 140, y - 28], fill=SOUL_GREEN + (180,))
    # Repair stations
    for i in range(3):
        x = 350 + i * 600
        y = 900
        draw.rectangle([x, y, x + 180, y + 100], fill=(65, 62, 58, 240), outline=BRASS, width=2)
        # Gears on station
        for j in range(3):
            gx = x + 30 + j * 50
            gy = y + 30
            draw.ellipse([gx, gy, gx + 35, gy + 35], fill=BRASS + (200,), outline=BRASS_DARK, width=1)
    return img

def make_bg_conveyor_maze():
    w, h = 2400, 1600
    img = Image.new('RGBA', (w, h), (35, 32, 30, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 25):
        shade = 30 + int(8 * math.sin(y / 50))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 3, shade - 5), width=2)
    # Moving platforms (conveyor segments at different heights)
    platform_heights = [400, 600, 800, 1000]
    for y_base in platform_heights:
        for i in range(5):
            x = 100 + i * 480
            draw.rectangle([x, y_base, x + 360, y_base + 60], fill=(50, 50, 55, 240), outline=IRON, width=2)
            # Direction arrows
            for j in range(4):
                ax = x + 40 + j * 80
                ay = y_base + 30
                draw.polygon([(ax, ay - 6), (ax + 18, ay), (ax, ay + 6)], fill=(120, 120, 130, 200))
    # Gaps between platforms (hazard zones)
    for i in range(3):
        x = 500 + i * 700
        y = 700
        for r in range(10, 40, 8):
            alpha = max(0, 80 - r)
            draw.ellipse([x - r, y - r * 0.3, x + r, y + r * 0.3], fill=SOUL_GREEN + (alpha,))
    # Shifting hazard (moving saw blade)
    for i in range(3):
        x = 300 + i * 900
        y = 500
        draw.ellipse([x, y, x + 50, y + 50], fill=(180, 30, 30, 180), outline=(220, 50, 50), width=2)
        for j in range(8):
            angle = math.radians(j * 45)
            x2 = x + 25 + 25 * math.cos(angle)
            y2 = y + 25 + 25 * math.sin(angle)
            draw.line([(x + 25, y + 25), (x2, y2)], fill=(220, 50, 50, 150), width=2)
    return img

def make_bg_foundry_pit():
    w, h = 2200, 1600
    img = Image.new('RGBA', (w, h), (30, 25, 22, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 30):
        shade = 25 + int(8 * math.sin(y / 50))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 3, shade - 5), width=2)
    # Soul-energy lava pit (bottom)
    for i in range(8):
        x = 100 + i * 280
        y = 1300
        for r in range(15, 60, 10):
            alpha = max(0, 120 - r)
            draw.ellipse([x - r, y - r * 0.3, x + r, y + r * 0.3], fill=SOUL_GREEN + (alpha,))
    # Soul-piston (massive central machine)
    draw.rectangle([800, 300, 1400, 900], fill=(60, 55, 50, 240), outline=IRON, width=5)
    # Piston head
    draw.rectangle([950, 200, 1250, 350], fill=BRASS + (240,), outline=BRASS_DARK, width=3)
    # Glowing soul core inside
    for r in range(10, 80, 10):
        alpha = max(0, 180 - r * 2)
        draw.ellipse([1000 - r, 500 - r * 0.6, 1200 + r, 700 + r * 0.6], fill=SOUL_GREEN + (alpha,))
    # Furnace choice markers
    draw.rectangle([300, 1100, 700, 1250], fill=(55, 50, 45, 240), outline=RUST_ORANGE, width=3)
    draw.rectangle([1500, 1100, 1900, 1250], fill=(55, 50, 45, 240), outline=SOUL_GREEN, width=3)
    return img

def make_bg_locker_room():
    w, h = 1800, 1200
    img = Image.new('RGBA', (w, h), (60, 55, 50, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 40):
        shade = 55 + int(8 * math.sin(y / 80))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 3, shade - 5), width=3)
    # Lockers (rows)
    for row in range(2):
        for col in range(6):
            x = 150 + col * 280
            y = 200 + row * 350
            draw.rectangle([x, y, x + 220, y + 280], fill=(75, 70, 65, 240), outline=IRON, width=2)
            # Locker door lines
            draw.line([(x + 110, y), (x + 110, y + 280)], fill=IRON_DARK, width=1)
            # Small vents
            for j in range(3):
                vy = y + 30 + j * 60
                draw.rectangle([x + 20, vy, x + 90, vy + 10], fill=(50, 50, 55))
    # Assembly station center
    draw.rectangle([700, 700, 1100, 950], fill=(80, 75, 70, 240), outline=BRASS, width=3)
    # Bone + gear slots on station
    draw.rectangle([750, 750, 850, 850], fill=(100, 100, 105), outline=BONE_DARK, width=2)
    draw.rectangle([950, 750, 1050, 850], fill=(100, 100, 105), outline=BRASS_DARK, width=2)
    # Companion card crafting area
    draw.rectangle([780, 880, 1020, 930], fill=(50, 100, 50, 180), outline=SOUL_GREEN, width=2)
    return img

def make_bg_foreman_office():
    w, h = 2600, 1800
    img = Image.new('RGBA', (w, h), (20, 18, 16, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 20):
        shade = 18 + int(6 * math.sin(y / 40))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 2, shade - 3), width=2)
    # Conveyor belt throne (raised platform on belt)
    draw.rectangle([900, 800, 1700, 1400], fill=(50, 45, 40, 240), outline=IRON, width=4)
    # Conveyor under throne
    for i in range(12):
        x = 920 + i * 60
        draw.rectangle([x, 1350, x + 50, 1380], fill=(40, 40, 45), outline=IRON_DARK, width=1)
    # Throne itself
    draw.rectangle([1100, 600, 1500, 1000], fill=(70, 60, 50, 240), outline=BRASS, width=4)
    draw.rectangle([1150, 550, 1450, 650], fill=(60, 50, 40, 220), outline=BRASS_DARK, width=3)
    # Glass case with skull on chest
    draw.rectangle([1250, 700, 1350, 850], fill=(150, 180, 200, 80), outline=(200, 220, 240), width=2)
    # The skull
    draw.ellipse([1260, 720, 1340, 800], fill=BONE_WHITE, outline=BONE_DARK, width=2)
    # Eye sockets (dark, but sometimes glow green)
    draw.ellipse([1275, 740, 1290, 755], fill=(30, 30, 35))
    draw.ellipse([1310, 740, 1325, 755], fill=(30, 30, 35))
    # The Foreman Eternal silhouette (behind throne)
    draw.ellipse([1200, 300, 1400, 550], fill=(40, 38, 35, 200), outline=(60, 58, 55), width=2)
    # Brass arms
    draw.rectangle([1150, 400, 1200, 600], fill=BRASS + (200,), outline=BRASS_DARK, width=2)
    draw.rectangle([1400, 400, 1450, 600], fill=BRASS + (200,), outline=BRASS_DARK, width=2)
    # Factory machinery in background
    for i in range(6):
        x = 200 + i * 400
        y = 200
        draw.rectangle([x, y, x + 150, y + 200], fill=(45, 42, 38, 220), outline=FACTORY_GRAY, width=1)
        draw.ellipse([x + 30, y + 50, x + 120, y + 140], fill=(55, 52, 48), outline=IRON_DARK, width=1)
    return img

# =======================================================================
# FLOOR TILES
# =======================================================================

def make_tile_bone_factory():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    base = FACTORY_GRAY + (220,)
    draw_hexagon(draw, size // 2, size // 2, size // 2 - 2, base, BONE_DARK, 2)
    # Marrow veins
    for i in range(3):
        x1 = random.randint(10, size - 10)
        y1 = random.randint(10, size - 10)
        x2 = x1 + random.randint(-20, 20)
        y2 = y1 + random.randint(-20, 20)
        draw.line([(x1, y1), (x2, y2)], fill=MARROW + (150,), width=random.randint(1, 3))
    return img

def make_tile_soul_glow():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    base = SOUL_DARK + (220,)
    draw_hexagon(draw, size // 2, size // 2, size // 2 - 2, base, SOUL_GLOW, 2)
    # Trapped soul energy (pulsing)
    for r in range(5, 25, 5):
        alpha = max(0, 120 - r * 4)
        draw.ellipse([size // 2 - r, size // 2 - r, size // 2 + r, size // 2 + r], fill=SOUL_GREEN + (alpha,))
    return img

def make_tile_conveyor_belt():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    base = (50, 50, 55, 220)
    draw_hexagon(draw, size // 2, size // 2, size // 2 - 2, base, IRON_DARK, 2)
    # Directional arrows
    for i in range(2):
        y = 18 + i * 28
        draw.polygon([(12, y), (28, y - 6), (28, y + 6)], fill=(120, 120, 130, 180))
        draw.polygon([(36, y), (52, y - 6), (52, y + 6)], fill=(120, 120, 130, 180))
    return img

# =======================================================================
# ENVIRONMENTAL SPRITES
# =======================================================================

def make_soul_furnace():
    size = 128
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Forge body
    draw.rectangle([15, 30, 113, 100], fill=(55, 50, 45, 240), outline=FACTORY_GRAY, width=3)
    # Glowing green interior
    for r in range(10, 50, 8):
        alpha = max(0, 180 - r * 3)
        draw.ellipse([35 - r, 40 - r * 0.5, 93 + r, 80 + r * 0.5], fill=SOUL_GREEN + (alpha,))
    # Soul flame
    draw.ellipse([50, 50, 78, 78], fill=SOUL_GLOW + (220,), outline=SOUL_DARK, width=1)
    # Top opening
    draw.rectangle([40, 20, 88, 35], fill=(30, 30, 35), outline=IRON, width=1)
    # Side pipes
    draw.rectangle([5, 50, 15, 70], fill=IRON, outline=IRON_DARK, width=1)
    draw.rectangle([113, 50, 123, 70], fill=IRON, outline=IRON_DARK, width=1)
    return img

def make_conveyor_belt():
    size = 96
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Belt segment
    draw.rectangle([8, 20, 88, 76], fill=(45, 45, 50, 240), outline=IRON, width=2)
    # Rollers
    for i in range(4):
        x = 18 + i * 20
        draw.ellipse([x, 65, x + 14, 79], fill=IRON_DARK, outline=IRON, width=1)
    # Arrows on belt
    for i in range(3):
        x = 20 + i * 24
        draw.polygon([(x, 40), (x + 16, 36), (x + 16, 44)], fill=(120, 120, 130, 200))
    return img

def make_assembly_station():
    size = 128
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Table
    draw.rectangle([10, 40, 118, 90], fill=(70, 65, 60, 240), outline=BONE_DARK, width=2)
    # Legs
    draw.rectangle([20, 90, 30, 120], fill=(60, 55, 50))
    draw.rectangle([98, 90, 108, 120], fill=(60, 55, 50))
    # Bone slot (left)
    draw.rectangle([20, 30, 55, 60], fill=(50, 50, 55), outline=BONE_DARK, width=2)
    draw.rectangle([25, 20, 50, 35], fill=BONE_WHITE, outline=BONE_DARK, width=1)
    # Gear slot (right)
    draw.rectangle([73, 30, 108, 60], fill=(50, 50, 55), outline=BRASS_DARK, width=2)
    draw.ellipse([78, 20, 103, 40], fill=BRASS, outline=BRASS_DARK, width=1)
    return img

def make_bone_crate():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Crate
    draw.rectangle([8, 15, 56, 50], fill=(65, 60, 55, 240), outline=BONE_DARK, width=2)
    # Bones sticking out
    for i in range(3):
        bx = 12 + i * 14
        draw.rectangle([bx, 5, bx + 6, 20], fill=BONE_WHITE, outline=BONE_DARK, width=1)
    # Label
    draw.rectangle([15, 30, 49, 40], fill=(80, 75, 70))
    draw.line([(20, 35), (44, 35)], fill=(40, 40, 40), width=1)
    return img

def make_gear_crate():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Crate
    draw.rectangle([8, 15, 56, 50], fill=(65, 60, 55, 240), outline=BRASS_DARK, width=2)
    # Gears inside
    for i in range(2):
        gx = 15 + i * 22
        gy = 20
        draw.ellipse([gx, gy, gx + 20, gy + 20], fill=BRASS + (200,), outline=BRASS_DARK, width=1)
        draw.ellipse([gx + 5, gy + 5, gx + 15, gy + 15], fill=(65, 60, 55))
    return img

def make_smokestack_femur():
    size = 96
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Femur shaft
    draw.rectangle([35, 30, 61, 90], fill=BONE_WHITE, outline=BONE_DARK, width=2)
    # Top ball
    draw.ellipse([28, 8, 68, 38], fill=BONE_WHITE, outline=BONE_DARK, width=2)
    # Bottom ball
    draw.ellipse([28, 78, 68, 108], fill=BONE_WHITE, outline=BONE_DARK, width=2)
    # Green smoke
    for i in range(5):
        sy = 5 - i * 12
        sx = 48 + int(10 * math.sin(i * 1.5))
        for r in range(4, 18, 5):
            alpha = max(0, 60 - r - i * 6)
            draw.ellipse([sx - r, sy - r, sx + r, sy + r], fill=SOUL_GREEN + (alpha,))
    return img

def make_glass_case_skull():
    size = 96
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Glass case
    draw.rectangle([15, 15, 81, 81], fill=(150, 180, 200, 60), outline=(200, 220, 240), width=2)
    # The skull
    draw.ellipse([25, 25, 71, 65], fill=BONE_WHITE, outline=BONE_DARK, width=2)
    # Eye sockets
    draw.ellipse([35, 35, 45, 45], fill=(30, 30, 35))
    draw.ellipse([51, 35, 61, 45], fill=(30, 30, 35))
    # Occasional green glow from eyes (weak point indicator)
    draw.ellipse([37, 37, 43, 43], fill=SOUL_GREEN + (120,))
    draw.ellipse([53, 37, 59, 43], fill=SOUL_GREEN + (120,))
    return img

def make_soul_orb():
    size = 48
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Trapped soul
    for r in range(3, 20, 4):
        alpha = max(0, 180 - r * 8)
        draw.ellipse([size // 2 - r, size // 2 - r, size // 2 + r, size // 2 + r], fill=SOUL_GREEN + (alpha,))
    # Core
    draw.ellipse([size // 2 - 5, size // 2 - 5, size // 2 + 5, size // 2 + 5], fill=(220, 255, 220, 220))
    return img

# =======================================================================
# ENEMY SPRITES (8 enemies x 4 frames)
# =======================================================================

def make_enemy_assembly_skeleton(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (4, -2), 'damage': (-3, 0), 'death': (0, 8)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.2, 'damage': 0.7, 'death': 0.5}[frame]
    ox, oy = offset
    body_color = tuple(min(255, int(c * intensity)) for c in BONE_WHITE)
    # Skeleton body
    draw.rectangle([cx - 8 + ox, cy + 5 + oy, cx + 8 + ox, cy + 25 + oy], fill=body_color, outline=BONE_DARK, width=1)
    # Ribs
    for i in range(3):
        ry = cy + 8 + i * 6
        draw.line([(cx - 8 + ox, ry + oy), (cx + 8 + ox, ry + oy)], fill=body_color, width=1)
    # Skull
    draw.ellipse([cx - 10 + ox, cy - 20 + oy, cx + 10 + ox, cy + 2 + oy], fill=body_color, outline=BONE_DARK, width=1)
    # Eyes (soul green glow)
    eye_color = SOUL_GREEN if frame != 'death' else (80, 80, 80)
    draw.ellipse([cx - 6 + ox, cy - 12 + oy, cx - 2 + ox, cy - 8 + oy], fill=eye_color + (200,))
    draw.ellipse([cx + 2 + ox, cy - 12 + oy, cx + 6 + ox, cy - 8 + oy], fill=eye_color + (200,))
    # Arms
    draw.line([(cx - 8 + ox, cy + 5 + oy), (cx - 18 + ox, cy + 15 + oy)], fill=body_color, width=2)
    draw.line([(cx + 8 + ox, cy + 5 + oy), (cx + 18 + ox, cy + 15 + oy)], fill=body_color, width=2)
    if frame == 'attack':
        draw.line([(cx + 18 + ox, cy + 15 + oy), (cx + 28 + ox, cy + 5 + oy)], fill=body_color, width=2)
    if frame == 'damage':
        draw.line([(cx - 15, cy - 10), (cx + 15, cy + 20)], fill=(255, 50, 50, 150), width=2)
    return img

def make_enemy_foreman_specter(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (3, -4), 'damage': (-2, 0), 'death': (0, 6)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.3, 'damage': 0.6, 'death': 0.4}[frame]
    ox, oy = offset
    # Ghostly body (translucent)
    body_color = tuple(min(255, int(c * intensity)) for c in (100, 120, 140))
    pts = [(cx + ox, cy - 25 + oy), (cx + 15 + ox, cy - 5 + oy), (cx + 10 + ox, cy + 20 + oy),
           (cx - 10 + ox, cy + 20 + oy), (cx - 15 + ox, cy - 5 + oy)]
    draw.polygon(pts, fill=body_color + (140,), outline=(140, 160, 180, 180), width=2)
    # Hard hat (foreman)
    draw.rectangle([cx - 12 + ox, cy - 28 + oy, cx + 12 + ox, cy - 20 + oy], fill=(180, 140, 40, 220), outline=(160, 120, 30), width=1)
    # Eyes
    eye_color = (200, 220, 255) if frame != 'death' else (100, 100, 100)
    draw.ellipse([cx - 6 + ox, cy - 15 + oy, cx - 2 + ox, cy - 11 + oy], fill=eye_color + (200,))
    draw.ellipse([cx + 2 + ox, cy - 15 + oy, cx + 6 + ox, cy - 11 + oy], fill=eye_color + (200,))
    if frame == 'attack':
        # Possession beam
        draw.line([(cx + ox, cy + oy), (cx + 30 + ox, cy - 10 + oy)], fill=(200, 220, 255, 150), width=3)
    if frame == 'damage':
        for _ in range(4):
            px = cx + random.randint(-15, 15)
            py = cy + random.randint(-15, 15)
            draw.ellipse([px - 3, py - 3, px + 3, py + 3], fill=(200, 220, 255, 100))
    return img

def make_enemy_soul_burner(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (2, -3), 'damage': (-2, 0), 'death': (0, 8)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.3, 'damage': 0.6, 'death': 0.3}[frame]
    ox, oy = offset
    # Burning body (charred)
    body_color = tuple(min(255, int(c * intensity)) for c in (60, 55, 50))
    draw.ellipse([cx - 14 + ox, cy - 5 + oy, cx + 14 + ox, cy + 22 + oy], fill=body_color, outline=(40, 38, 35), width=2)
    # Green soul flames
    flame_color = tuple(min(255, int(c * intensity)) for c in SOUL_GREEN)
    for i in range(5):
        fx = cx + random.randint(-12, 12) + ox
        fy = cy + random.randint(-15, 5) + oy
        draw.ellipse([fx - 5, fy - 8, fx + 5, fy + 4], fill=flame_color + (180,))
    # Eyes (burning bright)
    eye_color = (255, 255, 150) if frame != 'death' else (80, 80, 80)
    draw.ellipse([cx - 6 + ox, cy - 8 + oy, cx - 2 + ox, cy - 4 + oy], fill=eye_color + (220,))
    draw.ellipse([cx + 2 + ox, cy - 8 + oy, cx + 6 + ox, cy - 4 + oy], fill=eye_color + (220,))
    if frame == 'attack':
        # Explosive burst
        for i in range(8):
            rad = math.radians(i * 45)
            x2 = cx + 30 * math.cos(rad)
            y2 = cy + 30 * math.sin(rad)
            draw.line([(cx + ox, cy + oy), (x2 + ox, y2 + oy)], fill=flame_color + (150,), width=2)
    if frame == 'damage':
        draw.line([(cx - 15, cy - 10), (cx + 15, cy + 18)], fill=(255, 50, 50, 150), width=2)
    return img

def make_enemy_the_pensioned(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (3, -2), 'damage': (-2, 0), 'death': (0, 5)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.2, 'damage': 0.8, 'death': 0.6}[frame]
    ox, oy = offset
    # Ancient undead worker (ragged, patched)
    body_color = tuple(min(255, int(c * intensity)) for c in (120, 110, 100))
    draw.ellipse([cx - 16 + ox, cy - 3 + oy, cx + 16 + ox, cy + 24 + oy], fill=body_color, outline=(90, 85, 75), width=2)
    # Patches
    draw.rectangle([cx - 8 + ox, cy + 5 + oy, cx + 2 + ox, cy + 12 + oy], fill=(80, 70, 60, 200))
    draw.rectangle([cx + 5 + ox, cy + 10 + oy, cx + 12 + ox, cy + 18 + oy], fill=(80, 70, 60, 200))
    # Head
    head_color = tuple(min(255, int(c * intensity)) for c in BONE_WHITE)
    draw.ellipse([cx - 10 + ox, cy - 22 + oy, cx + 10 + ox, cy + 2 + oy], fill=head_color, outline=BONE_DARK, width=1)
    # Dull eyes
    eye_color = (150, 150, 140) if frame != 'death' else (80, 80, 80)
    draw.ellipse([cx - 6 + ox, cy - 12 + oy, cx - 2 + ox, cy - 8 + oy], fill=eye_color)
    draw.ellipse([cx + 2 + ox, cy - 12 + oy, cx + 6 + ox, cy - 8 + oy], fill=eye_color)
    # Name badge
    draw.rectangle([cx - 4 + ox, cy + 2 + oy, cx + 6 + ox, cy + 8 + oy], fill=(200, 180, 50, 180))
    if frame == 'attack':
        # Swings old wrench
        draw.line([(cx + 15 + ox, cy + 5 + oy), (cx + 30 + ox, cy - 15 + oy)], fill=IRON, width=3)
    if frame == 'damage':
        draw.line([(cx - 12, cy - 8), (cx + 12, cy + 15)], fill=(255, 50, 50, 150), width=2)
    return img

def make_enemy_ribcage_loader(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (2, -2), 'damage': (-2, 0), 'death': (0, 6)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.2, 'damage': 0.7, 'death': 0.5}[frame]
    ox, oy = offset
    # Carries bone crate
    body_color = tuple(min(255, int(c * intensity)) for c in (70, 65, 60))
    draw.ellipse([cx - 14 + ox, cy - 3 + oy, cx + 14 + ox, cy + 22 + oy], fill=body_color, outline=(50, 48, 45), width=2)
    # Skull
    skull_color = tuple(min(255, int(c * intensity)) for c in BONE_WHITE)
    draw.ellipse([cx - 10 + ox, cy - 20 + oy, cx + 10 + ox, cy + 2 + oy], fill=skull_color, outline=BONE_DARK, width=1)
    # Eyes
    eye_color = SOUL_GREEN if frame != 'death' else (80, 80, 80)
    draw.ellipse([cx - 6 + ox, cy - 12 + oy, cx - 2 + ox, cy - 8 + oy], fill=eye_color + (200,))
    draw.ellipse([cx + 2 + ox, cy - 12 + oy, cx + 6 + ox, cy - 8 + oy], fill=eye_color + (200,))
    # Bone crate on back
    draw.rectangle([cx - 18 + ox, cy - 5 + oy, cx + 18 + ox, cy + 15 + oy], fill=(65, 60, 55, 220), outline=BONE_DARK, width=1)
    for i in range(3):
        bx = cx - 12 + i * 10 + ox
        draw.rectangle([bx, cy - 15 + oy, bx + 5, cy - 2 + oy], fill=skull_color, outline=BONE_DARK, width=1)
    if frame == 'attack':
        # Drops bones
        for i in range(3):
            bx = cx + random.randint(-15, 15) + ox
            by = cy + 20 + random.randint(0, 10) + oy
            draw.rectangle([bx, by, bx + 6, by + 12], fill=skull_color, width=1)
    if frame == 'damage':
        draw.line([(cx - 15, cy - 8), (cx + 15, cy + 15)], fill=(255, 50, 50, 150), width=2)
    return img

def make_enemy_skull_machinist(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (3, -3), 'damage': (-3, 0), 'death': (0, 6)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.2, 'damage': 0.7, 'death': 0.5}[frame]
    ox, oy = offset
    # Construct body with skull face
    body_color = tuple(min(255, int(c * intensity)) for c in BRASS)
    draw.ellipse([cx - 14 + ox, cy - 3 + oy, cx + 14 + ox, cy + 22 + oy], fill=body_color, outline=BRASS_DARK, width=2)
    # Skull face (brass skull)
    skull_color = tuple(min(255, int(c * intensity)) for c in (160, 140, 100))
    draw.ellipse([cx - 12 + ox, cy - 22 + oy, cx + 12 + ox, cy + 2 + oy], fill=skull_color, outline=BRASS_DARK, width=2)
    # Glowing green eyes
    eye_color = SOUL_GREEN if frame != 'death' else (80, 80, 80)
    draw.ellipse([cx - 7 + ox, cy - 12 + oy, cx - 3 + ox, cy - 8 + oy], fill=eye_color + (220,))
    draw.ellipse([cx + 3 + ox, cy - 12 + oy, cx + 7 + ox, cy - 8 + oy], fill=eye_color + (220,))
    # Wrench
    draw.rectangle([cx + 12 + ox, cy + 5 + oy, cx + 28 + ox, cy + 12 + oy], fill=IRON, outline=IRON_DARK, width=1)
    if frame == 'attack':
        # Repair beam
        draw.line([(cx + 25 + ox, cy + 8 + oy), (cx + 40 + ox, cy - 5 + oy)], fill=SOUL_GREEN + (180,), width=3)
    if frame == 'damage':
        draw.line([(cx - 15, cy - 10), (cx + 15, cy + 15)], fill=(255, 50, 50, 150), width=2)
    return img

def make_enemy_femur_golem(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (4, -2), 'damage': (-3, 0), 'death': (0, 8)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.3, 'damage': 0.6, 'death': 0.4}[frame]
    ox, oy = offset
    # Heavy bone construct
    body_color = tuple(min(255, int(c * intensity)) for c in BONE_WHITE)
    draw.rectangle([cx - 18 + ox, cy - 5 + oy, cx + 18 + ox, cy + 28 + oy], fill=body_color, outline=BONE_DARK, width=3)
    # Femur arms
    draw.rectangle([cx - 28 + ox, cy + 5 + oy, cx - 18 + ox, cy + 25 + oy], fill=body_color, outline=BONE_DARK, width=2)
    draw.rectangle([cx + 18 + ox, cy + 5 + oy, cx + 28 + ox, cy + 25 + oy], fill=body_color, outline=BONE_DARK, width=2)
    # Skull head
    draw.ellipse([cx - 12 + ox, cy - 25 + oy, cx + 12 + ox, cy + 2 + oy], fill=body_color, outline=BONE_DARK, width=2)
    # Fierce eyes
    eye_color = (255, 50, 50) if frame != 'death' else (80, 80, 80)
    draw.ellipse([cx - 8 + ox, cy - 15 + oy, cx - 3 + ox, cy - 10 + oy], fill=eye_color + (200,))
    draw.ellipse([cx + 3 + ox, cy - 15 + oy, cx + 8 + ox, cy - 10 + oy], fill=eye_color + (200,))
    # Cracks (gets more as it loses limbs)
    if frame in ['damage', 'death']:
        draw.line([(cx - 10 + ox, cy + 5 + oy), (cx + 5 + ox, cy + 20 + oy)], fill=(60, 55, 50), width=1)
    if frame == 'attack':
        # Swings femur club
        draw.line([(cx + 25 + ox, cy + 10 + oy), (cx + 45 + ox, cy - 20 + oy)], fill=body_color, width=4)
    if frame == 'death':
        # Falls apart
        draw.line([(cx - 15, cy - 10), (cx + 15, cy + 20)], fill=(100, 100, 100, 150), width=2)
    return img

def make_enemy_soul_piston(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (2, -4), 'damage': (-2, 0), 'death': (0, 6)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.3, 'damage': 0.6, 'death': 0.3}[frame]
    ox, oy = offset
    # Piston body (brass cylinder)
    body_color = tuple(min(255, int(c * intensity)) for c in BRASS)
    draw.rectangle([cx - 12 + ox, cy - 10 + oy, cx + 12 + ox, cy + 25 + oy], fill=body_color, outline=BRASS_DARK, width=2)
    # Piston head (moves)
    ph_y = cy - 20 + oy if frame == 'attack' else cy - 15 + oy
    draw.rectangle([cx - 8 + ox, ph_y, cx + 8 + ox, ph_y + 15], fill=body_color, outline=BRASS_DARK, width=2)
    # Soul core (glowing green center)
    core_alpha = 220 if frame == 'attack' else 160
    for r in range(5, 20, 5):
        alpha = max(0, core_alpha - r * 8)
        draw.ellipse([cx - r + ox, cy + 5 - r + oy, cx + r + ox, cy + 5 + r + oy], fill=SOUL_GREEN + (alpha,))
    # Eye (single lens)
    eye_color = SOUL_GREEN if frame != 'death' else (80, 80, 80)
    draw.ellipse([cx - 4 + ox, cy - 5 + oy, cx + 4 + ox, cy + 3 + oy], fill=eye_color + (220,))
    if frame == 'attack':
        # Piston slam
        draw.rectangle([cx - 20 + ox, cy + 25 + oy, cx + 20 + ox, cy + 35 + oy], fill=SOUL_GREEN + (150,))
    if frame == 'damage':
        draw.line([(cx - 12, cy - 8), (cx + 12, cy + 15)], fill=(255, 50, 50, 150), width=2)
    return img

# =======================================================================
# BOSS — The Foreman Eternal
# =======================================================================

def make_boss_foreman_eternal(frame):
    size = 96
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (5, -5), 'damage': (-4, 0), 'death': (0, 12)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.3, 'damage': 0.7, 'death': 0.5}[frame]
    ox, oy = offset
    # Construct-lich body (brass + bone)
    body_color = tuple(min(255, int(c * intensity)) for c in (70, 65, 60))
    draw.ellipse([cx - 25 + ox, cy - 5 + oy, cx + 25 + ox, cy + 35 + oy], fill=body_color, outline=FACTORY_GRAY, width=3)
    # Brass shoulders
    draw.rectangle([cx - 35 + ox, cy + 5 + oy, cx - 25 + ox, cy + 25 + oy], fill=BRASS + (240,), outline=BRASS_DARK, width=2)
    draw.rectangle([cx + 25 + ox, cy + 5 + oy, cx + 35 + ox, cy + 25 + oy], fill=BRASS + (240,), outline=BRASS_DARK, width=2)
    # Glass case on chest
    case_color = (150, 180, 200, 100) if frame != 'death' else (100, 100, 100, 60)
    draw.rectangle([cx - 12 + ox, cy + 5 + oy, cx + 12 + ox, cy + 30 + oy], fill=case_color, outline=(200, 220, 240), width=2)
    # Skull inside glass case
    skull_color = tuple(min(255, int(c * intensity)) for c in BONE_WHITE)
    draw.ellipse([cx - 8 + ox, cy + 8 + oy, cx + 8 + ox, cy + 24 + oy], fill=skull_color, outline=BONE_DARK, width=1)
    # Skull eyes (green glow if alive)
    if frame != 'death':
        draw.ellipse([cx - 5 + ox, cy + 12 + oy, cx - 2 + ox, cy + 16 + oy], fill=SOUL_GREEN + (200,))
        draw.ellipse([cx + 2 + ox, cy + 12 + oy, cx + 5 + ox, cy + 16 + oy], fill=SOUL_GREEN + (200,))
    # Head (construct face - mostly machinery)
    head_color = tuple(min(255, int(c * intensity)) for c in (80, 75, 70))
    draw.ellipse([cx - 18 + ox, cy - 30 + oy, cx + 18 + ox, cy + 5 + oy], fill=head_color, outline=FACTORY_GRAY, width=2)
    # Glowing eye sensors (multiple)
    sensor_color = SOUL_GREEN if frame != 'death' else (60, 60, 60)
    for sx in [cx - 12, cx - 2, cx + 8]:
        draw.ellipse([sx + ox - 3, cy - 18 + oy, sx + ox + 3, cy - 12 + oy], fill=sensor_color + (200,))
    # Conveyor belt feet
    draw.rectangle([cx - 20 + ox, cy + 30 + oy, cx + 20 + ox, cy + 42 + oy], fill=(45, 45, 50), outline=IRON, width=1)
    if frame == 'attack':
        # Summoning gesture
        draw.line([(cx + 30 + ox, cy - 10 + oy), (cx + 50 + ox, cy - 30 + oy)], fill=SOUL_GREEN + (200,), width=4)
        # Assembly skeleton spawn indicator
        draw.ellipse([cx + 45 + ox, cy - 40 + oy, cx + 65 + ox, cy - 20 + oy], fill=BONE_WHITE + (150,), outline=BONE_DARK, width=1)
    if frame == 'damage':
        draw.line([(cx - 25, cy - 20), (cx + 25, cy + 30)], fill=(255, 50, 50, 150), width=3)
    if frame == 'death':
        # Glass case cracks
        draw.line([(cx - 10, cy + 10), (cx + 10, cy + 25)], fill=(200, 220, 240, 150), width=2)
        draw.line([(cx + 8, cy + 8), (cx - 8, cy + 28)], fill=(200, 220, 240, 150), width=2)
    return img

# =======================================================================
# NPC / ITEM SPRITES
# =======================================================================

def make_npc_liberated_soul():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    # Grateful ghost
    pts = [(cx, cy - 25), (cx + 15, cy - 5), (cx + 10, cy + 20), (cx - 10, cy + 20), (cx - 15, cy - 5)]
    draw.polygon(pts, fill=(200, 220, 255, 120), outline=(180, 200, 240, 180), width=2)
    # Face (peaceful)
    draw.ellipse([cx - 8, cy - 15, cx + 8, cy + 2], fill=(220, 240, 255, 160), outline=(180, 200, 240), width=1)
    # Closed happy eyes
    draw.line([(cx - 6, cy - 8), (cx - 2, cy - 6)], fill=(100, 120, 140), width=2)
    draw.line([(cx + 2, cy - 8), (cx + 6, cy - 6)], fill=(100, 120, 140), width=2)
    # Smile
    draw.arc([cx - 5, cy - 5, cx + 5, cy + 5], start=0, end=180, fill=(100, 120, 140), width=2)
    return img

def make_item_bone_material():
    size = 48
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Bone piece
    draw.rectangle([10, 18, 38, 30], fill=BONE_WHITE, outline=BONE_DARK, width=2)
    # Marrow visible
    draw.rectangle([16, 20, 22, 28], fill=MARROW + (180,), outline=MARROW, width=1)
    # Small chip
    draw.rectangle([30, 12, 36, 18], fill=BONE_WHITE, outline=BONE_DARK, width=1)
    return img

def make_item_gear_material():
    size = 48
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Brass gear
    draw.ellipse([8, 8, 40, 40], fill=BRASS + (220,), outline=BRASS_DARK, width=2)
    draw.ellipse([18, 18, 30, 30], fill=(50, 50, 55))
    # Teeth
    for a in [0, 45, 90, 135, 180, 225, 270, 315]:
        rad = math.radians(a)
        x1 = 24 + 14 * math.cos(rad)
        y1 = 24 + 14 * math.sin(rad)
        x2 = 24 + 20 * math.cos(rad)
        y2 = 24 + 20 * math.sin(rad)
        draw.line([(x1, y1), (x2, y2)], fill=BRASS_DARK, width=2)
    return img

def make_item_companion_card():
    size = 48
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Card shape
    draw.rectangle([6, 8, 42, 40], fill=(50, 80, 50, 220), outline=SOUL_GREEN, width=2)
    # Skull icon
    draw.ellipse([16, 14, 32, 28], fill=BONE_WHITE, outline=BONE_DARK, width=1)
    draw.ellipse([20, 18, 23, 22], fill=(30, 30, 35))
    draw.ellipse([25, 18, 28, 22], fill=(30, 30, 35))
    # Gear corner
    draw.ellipse([30, 26, 38, 34], fill=BRASS + (200,), outline=BRASS_DARK, width=1)
    return img

# =======================================================================
# FACTION BANNERS
# =======================================================================

def make_banner_undead():
    size = 32
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Gray/green necromantic banner
    draw.polygon([(4, 4), (28, 4), (24, 28), (8, 28)], fill=(80, 90, 80, 230), outline=SOUL_DARK, width=1)
    # Skull symbol
    draw.ellipse([10, 8, 22, 18], fill=BONE_WHITE, outline=BONE_DARK, width=1)
    draw.ellipse([13, 12, 15, 15], fill=(30, 30, 35))
    draw.ellipse([17, 12, 19, 15], fill=(30, 30, 35))
    return img

def make_banner_construct():
    size = 32
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Brass/bone hybrid banner
    draw.polygon([(4, 4), (28, 4), (24, 28), (8, 28)], fill=BRASS + (230,), outline=BRASS_DARK, width=1)
    # Gear + bone hybrid symbol
    draw.ellipse([10, 10, 22, 22], outline=BONE_WHITE, width=2)
    draw.ellipse([13, 13, 19, 19], fill=BRASS + (200,))
    # Small bone across
    draw.line([(10, 16), (22, 16)], fill=BONE_WHITE, width=2)
    return img

# =======================================================================
# MAIN GENERATION
# =======================================================================

def generate_all():
    os.makedirs(BASE_PATH, exist_ok=True)

    # Room backgrounds
    backgrounds = [
        ("bg_loading_dock.png", make_bg_loading_dock),
        ("bg_assembly_line.png", make_bg_assembly_line),
        ("bg_break_station.png", make_bg_break_station),
        ("bg_furnace_room.png", make_bg_furnace_room),
        ("bg_quality_control.png", make_bg_quality_control),
        ("bg_bone_yard.png", make_bg_bone_yard),
        ("bg_gear_works.png", make_bg_gear_works),
        ("bg_conveyor_maze.png", make_bg_conveyor_maze),
        ("bg_foundry_pit.png", make_bg_foundry_pit),
        ("bg_locker_room.png", make_bg_locker_room),
        ("bg_foreman_office.png", make_bg_foreman_office),
    ]
    for fname, maker in backgrounds:
        path = os.path.join(BASE_PATH, fname)
        img = maker()
        img.save(path)
        print(f"Created: {path} ({img.width}x{img.height})")

    # Floor tiles
    tiles = [
        ("tile_bone_factory.png", make_tile_bone_factory),
        ("tile_soul_glow.png", make_tile_soul_glow),
        ("tile_conveyor_belt.png", make_tile_conveyor_belt),
    ]
    for fname, maker in tiles:
        path = os.path.join(BASE_PATH, fname)
        img = maker()
        img.save(path)
        print(f"Created: {path} ({img.width}x{img.height})")

    # Environmental sprites
    env = [
        ("soul_furnace.png", make_soul_furnace),
        ("conveyor_belt.png", make_conveyor_belt),
        ("assembly_station.png", make_assembly_station),
        ("bone_crate.png", make_bone_crate),
        ("gear_crate.png", make_gear_crate),
        ("smokestack_femur.png", make_smokestack_femur),
        ("glass_case_skull.png", make_glass_case_skull),
        ("soul_orb.png", make_soul_orb),
    ]
    for fname, maker in env:
        path = os.path.join(BASE_PATH, fname)
        img = maker()
        img.save(path)
        print(f"Created: {path} ({img.width}x{img.height})")

    # Enemy sprites (8 enemies x 4 frames)
    enemies = [
        ("assembly_skeleton", make_enemy_assembly_skeleton),
        ("foreman_specter", make_enemy_foreman_specter),
        ("soul_burner", make_enemy_soul_burner),
        ("the_pensioned", make_enemy_the_pensioned),
        ("ribcage_loader", make_enemy_ribcage_loader),
        ("skull_machinist", make_enemy_skull_machinist),
        ("femur_golem", make_enemy_femur_golem),
        ("soul_piston", make_enemy_soul_piston),
    ]
    for name, maker in enemies:
        for frame in ["idle", "attack", "damage", "death"]:
            fname = f"enemy_{name}_{frame}.png"
            path = os.path.join(BASE_PATH, fname)
            img = maker(frame)
            img.save(path)
            print(f"Created: {path} ({img.width}x{img.height})")

    # Boss (The Foreman Eternal)
    for frame in ["idle", "attack", "damage", "death"]:
        fname = f"boss_foreman_eternal_{frame}.png"
        path = os.path.join(BASE_PATH, fname)
        img = make_boss_foreman_eternal(frame)
        img.save(path)
        print(f"Created: {path} ({img.width}x{img.height})")

    # NPC / items
    npc_items = [
        ("npc_liberated_soul.png", make_npc_liberated_soul),
        ("item_bone_material.png", make_item_bone_material),
        ("item_gear_material.png", make_item_gear_material),
        ("item_companion_card.png", make_item_companion_card),
    ]
    for fname, maker in npc_items:
        path = os.path.join(BASE_PATH, fname)
        img = maker()
        img.save(path)
        print(f"Created: {path} ({img.width}x{img.height})")

    # Faction banners
    banners = [
        ("banner_undead.png", make_banner_undead),
        ("banner_construct.png", make_banner_construct),
    ]
    for fname, maker in banners:
        path = os.path.join(BASE_PATH, fname)
        img = maker()
        img.save(path)
        print(f"Created: {path} ({img.width}x{img.height})")

    print(f"\n=== Floor 9 asset generation complete ===")
    print(f"Total files in {BASE_PATH}: {len(os.listdir(BASE_PATH))}")

if __name__ == "__main__":
    generate_all()
