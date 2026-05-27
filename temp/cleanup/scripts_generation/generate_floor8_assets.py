#!/usr/bin/env python3
"""Generate Floor 8 (The Overclock Forge / Kami Crucible) pixel art assets using PIL"""

from PIL import Image, ImageDraw
import os
import math
import random

random.seed(42)

BASE_PATH = "/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/floor8"

def ensure_dir(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)

def draw_hexagon(draw, cx, cy, radius, fill, outline=None, width=2):
    pts = []
    for i in range(6):
        angle = math.radians(60 * i - 30)
        pts.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle)))
    draw.polygon(pts, fill=fill, outline=outline, width=width)

# =======================================================================
# PALETTE
# =======================================================================
# Brass gold, magma orange, steam white, goblin green, warning-sign red
BRASS = (184, 134, 11)
BRASS_DARK = (139, 90, 43)
MAGMA = (255, 100, 20)
MAGMA_DARK = (180, 60, 10)
STEAM = (220, 220, 230)
GOBLIN_GREEN = (34, 139, 34)
GOBLIN_DARK = (20, 90, 20)
WARNING_RED = (200, 30, 30)
FACTORY_GRAY = (80, 80, 85)
FACTORY_DARK = (50, 50, 55)
CONTAINMENT_BLUE = (30, 60, 120)

def darken(c, factor=0.7):
    return tuple(min(255, int(x * factor)) for x in c)

def lighten(c, factor=1.3):
    return tuple(min(255, int(x * factor)) for x in c)

# =======================================================================
# ROOM BACKGROUNDS
# =======================================================================

def make_bg_loading_bay():
    w, h = 2200, 1600
    img = Image.new('RGBA', (w, h), (35, 30, 25, 255))
    draw = ImageDraw.Draw(img)
    # Factory floor
    for y in range(0, h, 40):
        shade = 30 + int(15 * math.sin(y / 100))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 5, shade - 8), width=3)
    # Brass cages
    for i in range(4):
        x = 200 + i * 500
        y = 400 + (i % 2) * 300
        draw.rectangle([x, y, x + 200, y + 250], fill=(60, 55, 50, 220), outline=BRASS, width=3)
        for j in range(5):
            cy = y + 20 + j * 45
            draw.line([(x + 10, cy), (x + 190, cy)], fill=(180, 160, 140, 150), width=2)
    # Goblin handlers dragging chains
    for i in range(3):
        x = 150 + i * 700
        y = 900 + (i % 2) * 200
        # Goblin silhouette
        draw.ellipse([x, y, x + 40, y + 50], fill=GOBLIN_GREEN, outline=GOBLIN_DARK, width=2)
        draw.ellipse([x + 5, y - 20, x + 35, y + 5], fill=GOBLIN_GREEN)
        # Chain
        for j in range(8):
            cx = x + 40 + j * 25
            cy = y + 20 + int(10 * math.sin(j))
            draw.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=(180, 170, 160), outline=(120, 110, 100), width=1)
    # Magma glow from floor
    for i in range(5):
        x = 300 + i * 400
        y = 1300
        for r in range(10, 60, 10):
            alpha = max(0, 120 - r * 2)
            draw.ellipse([x - r, y - r * 0.3, x + r, y + r * 0.3], fill=MAGMA + (alpha,))
    return img

def make_bg_lower_works():
    w, h = 2200, 1600
    img = Image.new('RGBA', (w, h), (40, 30, 25, 255))
    draw = ImageDraw.Draw(img)
    # Dark industrial walls
    for y in range(0, h, 30):
        shade = 35 + int(10 * math.sin(y / 80))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 5, shade - 8), width=2)
    # Fire+water containment vessel (massive central machine)
    draw.rectangle([700, 400, 1500, 1000], fill=(60, 55, 50, 240), outline=BRASS, width=4)
    draw.rectangle([750, 450, 1450, 600], fill=(40, 35, 30, 220))
    # Fire side (left half glows orange)
    for r in range(20, 120, 15):
        alpha = max(0, 150 - r)
        draw.ellipse([750 - r, 500 - r * 0.5, 1100 + r, 900 + r * 0.5], fill=MAGMA + (alpha,))
    # Water side (right half blue-white steam)
    for r in range(20, 100, 15):
        alpha = max(0, 120 - r)
        draw.ellipse([1100 - r, 520 - r * 0.5, 1450 + r, 880 + r * 0.5], fill=(150, 180, 220, alpha))
    # Steam pipes
    for i in range(6):
        x = 200 + i * 350
        y = 200 + (i % 2) * 100
        draw.rectangle([x, y, x + 80, y + 300], fill=FACTORY_GRAY, outline=FACTORY_DARK, width=2)
        draw.ellipse([x + 10, y - 15, x + 70, y + 15], fill=(200, 200, 210, 180))
    # Explosion scorch marks
    for i in range(4):
        x = 300 + i * 500
        y = 1200 + (i % 2) * 150
        for r in range(10, 50, 8):
            alpha = max(0, 80 - r)
            draw.ellipse([x - r, y - r, x + r, y + r], fill=(30, 25, 20, alpha), outline=(60, 50, 40), width=1)
    return img

def make_bg_break_room():
    w, h = 2000, 1400
    img = Image.new('RGBA', (w, h), (50, 45, 40, 255))
    draw = ImageDraw.Draw(img)
    # Warm factory break room
    for y in range(0, h, 50):
        shade = 45 + int(10 * math.sin(y / 100))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 3, shade - 5), width=3)
    # Tables
    for i in range(3):
        x = 400 + i * 600
        y = 600
        draw.ellipse([x, y, x + 300, y + 180], fill=(100, 90, 80, 220), outline=(140, 130, 120), width=2)
        for j in range(4):
            lx = x + 30 + j * 60
            draw.rectangle([lx, y + 160, lx + 20, y + 240], fill=(90, 80, 70))
    # Vending machine
    draw.rectangle([1400, 500, 1700, 1000], fill=(80, 80, 90, 240), outline=(120, 120, 130), width=3)
    draw.rectangle([1420, 520, 1680, 700], fill=(60, 60, 70))
    for i in range(4):
        y = 540 + i * 40
        draw.rectangle([1440, y, 1660, y + 30], fill=(100, 100, 110, 180))
    # Overclock tutorial posters on wall
    for i in range(3):
        x = 200 + i * 250
        y = 200
        draw.rectangle([x, y, x + 200, y + 280], fill=(200, 190, 170, 200), outline=(160, 150, 130), width=2)
        draw.line([(x + 20, y + 40), (x + 180, y + 40)], fill=WARNING_RED, width=3)
        draw.line([(x + 20, y + 80), (x + 160, y + 80)], fill=(80, 70, 60), width=2)
        draw.line([(x + 20, y + 120), (x + 140, y + 120)], fill=(80, 70, 60), width=2)
    return img

def make_bg_containment_hall():
    w, h = 2400, 1600
    img = Image.new('RGBA', (w, h), (30, 25, 22, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 35):
        shade = 28 + int(8 * math.sin(y / 70))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 3, shade - 5), width=2)
    # 3 massive vessels
    for i in range(3):
        x = 300 + i * 750
        y = 400
        draw.rectangle([x, y, x + 500, y + 600], fill=(55, 50, 45, 240), outline=BRASS, width=4)
        # Pressure gauge
        draw.ellipse([x + 50, y - 60, x + 150, y + 40], fill=(220, 220, 220, 200), outline=(100, 100, 100), width=2)
        draw.polygon([(x + 100, y - 20), (x + 100, y + 10)], fill=WARNING_RED)
        # Vent valve
        draw.ellipse([x + 350, y - 40, x + 420, y + 30], fill=(180, 20, 20, 220), outline=(220, 40, 40), width=2)
        # Warning stripes
        for j in range(5):
            sy = y + 450 + j * 25
            draw.rectangle([x + 10, sy, x + 490, sy + 12], fill=((220, 180, 20) if j % 2 == 0 else (20, 20, 20)))
    # Goblin handlers
    for i in range(2):
        x = 600 + i * 1000
        y = 1100
        draw.ellipse([x, y, x + 35, y + 45], fill=GOBLIN_GREEN, outline=GOBLIN_DARK, width=2)
        draw.ellipse([x + 5, y - 15, x + 30, y + 5], fill=GOBLIN_GREEN)
        # Wrench
        draw.rectangle([x + 30, y + 10, x + 60, y + 20], fill=(180, 170, 160))
    # Warning signs in 3 languages
    for i in range(3):
        x = 200 + i * 1000
        y = 200
        draw.rectangle([x, y, x + 180, y + 120], fill=(220, 180, 20, 230), outline=WARNING_RED, width=3)
        draw.line([(x + 20, y + 30), (x + 160, y + 30)], fill=(20, 20, 20), width=3)
        draw.line([(x + 20, y + 60), (x + 120, y + 60)], fill=(20, 20, 20), width=2)
        draw.line([(x + 20, y + 90), (x + 100, y + 90)], fill=(20, 20, 20), width=2)
    return img

def make_bg_the_leak():
    w, h = 2000, 1400
    img = Image.new('RGBA', (w, h), (25, 25, 30, 255))
    draw = ImageDraw.Draw(img)
    # Dark, wet, ruptured
    for y in range(0, h, 25):
        shade = 22 + int(8 * math.sin(y / 50))
        draw.line([(0, y), (w, y)], fill=(shade, shade, shade + 5), width=2)
    # Ruptured pipes
    for i in range(5):
        x = 150 + i * 400
        y = 300 + (i % 2) * 400
        draw.rectangle([x, y, x + 300, y + 60], fill=FACTORY_GRAY, outline=FACTORY_DARK, width=2)
        # Rupture point
        draw.ellipse([x + 120, y - 20, x + 180, y + 80], fill=(50, 50, 60, 200), outline=(180, 40, 40), width=2)
        # Leaking elemental energy
        for r in range(5, 40, 8):
            alpha = max(0, 100 - r * 2)
            color = MAGMA if i % 2 == 0 else (150, 180, 220)
            draw.ellipse([x + 130 - r, y + 50 + r, x + 170 + r, y + 90 + r], fill=color + (alpha,))
    # Elemental swarm (small glowing dots)
    for _ in range(30):
        px = random.randint(100, 1900)
        py = random.randint(100, 1300)
        color = random.choice([MAGMA, (150, 180, 220), (180, 220, 150), (220, 220, 250)])
        draw.ellipse([px, py, px + 15, py + 15], fill=color + (180,))
    # Only vents, no goblins
    for i in range(3):
        x = 500 + i * 500
        y = 100
        draw.rectangle([x, y, x + 80, y + 40], fill=(60, 60, 65), outline=(100, 100, 105), width=2)
    return img

def make_bg_middle_works():
    w, h = 2200, 1600
    img = Image.new('RGBA', (w, h), (32, 28, 25, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 30):
        shade = 28 + int(10 * math.sin(y / 60))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 3, shade - 5), width=2)
    # Earth+air containment vessels
    for i in range(2):
        x = 400 + i * 1000
        y = 400
        draw.rectangle([x, y, x + 450, y + 550], fill=(55, 50, 45, 240), outline=BRASS, width=4)
        # Glass tornado debris inside
        for j in range(8):
            bx = x + 50 + random.randint(0, 350)
            by = y + 50 + random.randint(0, 450)
            s = random.randint(10, 30)
            draw.polygon([(bx, by), (bx + s, by - s // 2), (bx + s * 2, by)], fill=(200, 220, 240, 150))
    # Shattered containment rings on floor
    for i in range(3):
        x = 600 + i * 500
        y = 1200
        for r in range(30, 100, 20):
            alpha = max(0, 150 - r)
            draw.ellipse([x - r, y - r * 0.3, x + r, y + r * 0.3], outline=(180, 160, 140, alpha), width=2)
    return img

def make_bg_union_hall():
    w, h = 2000, 1400
    img = Image.new('RGBA', (w, h), (45, 40, 35, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 40):
        shade = 40 + int(10 * math.sin(y / 80))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 3, shade - 5), width=3)
    # Union banners
    for i in range(4):
        x = 200 + i * 450
        y = 300
        draw.polygon([(x, y), (x + 120, y), (x + 100, y + 200), (x + 20, y + 200)], fill=GOBLIN_GREEN + (220,), outline=GOBLIN_DARK, width=2)
        draw.line([(x + 20, y + 40), (x + 100, y + 40)], fill=(220, 220, 200), width=2)
        draw.line([(x + 20, y + 80), (x + 80, y + 80)], fill=(220, 220, 200), width=2)
    # Strike signs
    for i in range(3):
        x = 350 + i * 500
        y = 700
        draw.rectangle([x, y, x + 140, y + 100], fill=(220, 180, 20, 230), outline=(20, 20, 20), width=2)
        draw.line([(x + 10, y + 30), (x + 130, y + 30)], fill=(20, 20, 20), width=3)
        draw.line([(x + 10, y + 60), (x + 110, y + 60)], fill=(20, 20, 20), width=2)
    # Chief Handler throne
    draw.rectangle([800, 500, 1200, 900], fill=(120, 90, 60, 240), outline=BRASS, width=4)
    draw.rectangle([850, 400, 1150, 550], fill=(100, 75, 50, 220), outline=BRASS_DARK, width=3)
    draw.polygon([(1000, 350), (900, 450), (1100, 450)], fill=(140, 110, 70, 220))
    return img

def make_bg_the_crack():
    w, h = 2000, 1400
    img = Image.new('RGBA', (w, h), (30, 25, 22, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 30):
        shade = 25 + int(8 * math.sin(y / 50))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 3, shade - 5), width=2)
    # Single massive vessel (cracking under pressure)
    draw.rectangle([500, 300, 1500, 1000], fill=(50, 45, 40, 240), outline=BRASS, width=5)
    # Pressure knot visible inside - pulsing glow
    for r in range(20, 180, 15):
        alpha = max(0, 160 - r)
        draw.ellipse([700 - r, 500 - r * 0.6, 1300 + r, 900 + r * 0.6], fill=(150, 180, 220, alpha))
    # The crack in the vessel
    pts = [(950, 300), (1000, 500), (980, 700), (1020, 900), (1000, 1000)]
    for i in range(len(pts) - 1):
        draw.line([pts[i], pts[i + 1]], fill=(255, 50, 50, 200), width=6)
        draw.line([pts[i], pts[i + 1]], fill=(255, 200, 200, 120), width=10)
    # Decision point marker
    draw.rectangle([850, 1100, 1150, 1250], fill=(60, 55, 50, 240), outline=WARNING_RED, width=3)
    draw.line([(880, 1150), (1120, 1150)], fill=(220, 220, 220), width=2)
    draw.line([(880, 1180), (1080, 1180)], fill=(220, 220, 220), width=2)
    return img

def make_bg_upper_works():
    w, h = 2400, 1600
    img = Image.new('RGBA', (w, h), (35, 30, 25, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 25):
        shade = 30 + int(10 * math.sin(y / 60))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 3, shade - 5), width=2)
    # Complex machinery maze
    for i in range(8):
        x = 200 + i * 280
        y = 200 + (i % 3) * 350
        draw.rectangle([x, y, x + 200, y + 150], fill=FACTORY_GRAY + (220,), outline=BRASS, width=2)
        # Gears inside
        for j in range(3):
            gx = x + 30 + j * 60
            gy = y + 40
            draw.ellipse([gx, gy, gx + 40, gy + 40], fill=(120, 110, 100, 180), outline=(180, 170, 160), width=1)
    # 2 vessels
    for i in range(2):
        x = 500 + i * 1200
        y = 600
        draw.rectangle([x, y, x + 400, y + 500], fill=(55, 50, 45, 240), outline=BRASS, width=4)
        # Shaman symbols
        for j in range(3):
            sx = x + 50 + j * 120
            sy = y + 50
            draw.polygon([(sx, sy), (sx + 30, sy + 40), (sx - 30, sy + 40)], fill=(180, 100, 20, 150))
    # Overclock shaman silhouette near center vessel
    draw.ellipse([1000, 1150, 1080, 1220], fill=(100, 20, 120, 220), outline=(150, 50, 180), width=2)
    draw.ellipse([1010, 1120, 1070, 1170], fill=(80, 15, 100, 220))
    return img

def make_bg_padlock_door():
    w, h = 1800, 1200
    img = Image.new('RGBA', (w, h), (40, 35, 30, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 40):
        shade = 35 + int(8 * math.sin(y / 70))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 3, shade - 5), width=3)
    # Heavy door
    draw.rectangle([400, 200, 1400, 1000], fill=(60, 55, 50, 250), outline=BRASS, width=5)
    draw.rectangle([480, 280, 1320, 920], fill=(45, 40, 35, 240), outline=FACTORY_DARK, width=3)
    # 17 padlocks
    for i in range(17):
        row = i // 5
        col = i % 5
        x = 550 + col * 160
        y = 350 + row * 180
        if i < 15:
            draw.rectangle([x, y, x + 50, y + 70], fill=(180, 160, 120, 230), outline=(140, 120, 90), width=2)
            draw.ellipse([x + 10, y - 15, x + 40, y + 15], fill=(160, 140, 100), outline=(120, 100, 70), width=2)
        else:
            # Last two are bigger
            draw.rectangle([x, y, x + 70, y + 90], fill=(160, 140, 100, 230), outline=(120, 100, 70), width=2)
            draw.ellipse([x + 15, y - 15, x + 55, y + 25], fill=(140, 120, 90), outline=(100, 80, 50), width=2)
    # Final cache
    draw.rectangle([200, 800, 400, 1000], fill=(100, 80, 60, 240), outline=BRASS, width=3)
    draw.rectangle([220, 820, 380, 950], fill=(80, 65, 50))
    return img

def make_bg_control_room():
    w, h = 2600, 1800
    img = Image.new('RGBA', (w, h), (25, 20, 18, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 25):
        shade = 20 + int(8 * math.sin(y / 50))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 2, shade - 3), width=2)
    # 4 containment consoles
    positions = [(400, 500), (1800, 500), (400, 1200), (1800, 1200)]
    for x, y in positions:
        draw.rectangle([x, y, x + 400, y + 250], fill=(50, 45, 40, 240), outline=BRASS, width=4)
        # Console screens
        draw.rectangle([x + 30, y + 30, x + 370, y + 120], fill=(20, 25, 30, 220), outline=(100, 100, 110), width=2)
        # Levers
        for j in range(3):
            lx = x + 50 + j * 100
            draw.rectangle([lx, y + 150, lx + 20, y + 220], fill=(180, 160, 140))
            draw.ellipse([lx - 5, y + 130, lx + 25, y + 160], fill=(200, 30, 30, 200))
        # Gauge
        draw.ellipse([x + 300, y + 150, x + 360, y + 210], fill=(220, 220, 220, 180), outline=(100, 100, 100), width=1)
    # Blast shield (center wall)
    draw.rectangle([900, 200, 1700, 400], fill=(80, 75, 70, 240), outline=(120, 115, 110), width=4)
    draw.rectangle([1000, 220, 1600, 380], fill=(60, 55, 50, 220))
    # Chief Engineer Blix platform
    draw.rectangle([1100, 1400, 1500, 1600], fill=(100, 80, 60, 240), outline=BRASS, width=3)
    draw.ellipse([1200, 1300, 1400, 1450], fill=(180, 20, 20, 100))
    return img

# =======================================================================
# FLOOR TILES
# =======================================================================

def make_tile_brass_factory():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_hexagon(draw, size // 2, size // 2, size // 2 - 2, BRASS + (220,), (180, 150, 80), 2)
    # Rivets
    for i in range(4):
        rx = 15 + i * 12
        ry = 15 + (i % 2) * 25
        draw.ellipse([rx - 2, ry - 2, rx + 2, ry + 2], fill=(160, 140, 100))
    # Pipe line
    draw.line([(10, 32), (54, 32)], fill=FACTORY_DARK + (150,), width=2)
    return img

def make_tile_magma_glow():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    base = (80, 50, 40, 220)
    draw_hexagon(draw, size // 2, size // 2, size // 2 - 2, base, MAGMA_DARK, 2)
    # Magma cracks
    for i in range(3):
        x1 = random.randint(10, size - 10)
        y1 = random.randint(10, size - 10)
        x2 = x1 + random.randint(-15, 15)
        y2 = y1 + random.randint(-15, 15)
        draw.line([(x1, y1), (x2, y2)], fill=MAGMA + (180,), width=random.randint(1, 3))
    return img

def make_tile_containment_ring():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_hexagon(draw, size // 2, size // 2, size // 2 - 2, FACTORY_GRAY + (220,), (180, 180, 190), 2)
    # Warning stripes
    for i in range(3):
        y = 12 + i * 16
        draw.line([(10, y), (size - 10, y)], fill=((220, 180, 20) if i % 2 == 0 else (20, 20, 20)), width=4)
    return img

# =======================================================================
# ENVIRONMENTAL SPRITES
# =======================================================================

def make_containment_vessel():
    size = 128
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Main body
    draw.rectangle([10, 20, 118, 100], fill=(60, 55, 50, 240), outline=BRASS, width=3)
    # Glass window showing elemental
    draw.rectangle([20, 30, 80, 80], fill=(20, 20, 30, 200), outline=(100, 100, 120), width=2)
    for r in range(5, 30, 8):
        alpha = max(0, 100 - r * 3)
        draw.ellipse([35 - r, 45 - r * 0.6, 65 + r, 65 + r * 0.6], fill=MAGMA + (alpha,))
    # Pressure gauge
    draw.ellipse([88, 30, 112, 54], fill=(220, 220, 220, 200), outline=(100, 100, 100), width=1)
    draw.line([(100, 42), (108, 36)], fill=WARNING_RED, width=2)
    # Vent valve
    draw.ellipse([90, 70, 116, 96], fill=(180, 20, 20, 220), outline=(220, 40, 40), width=2)
    draw.rectangle([100, 60, 106, 70], fill=(160, 160, 160))
    return img

def make_vent_valve():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse([8, 8, 56, 56], fill=(180, 20, 20, 220), outline=(220, 40, 40), width=3)
    draw.ellipse([18, 18, 46, 46], fill=(140, 15, 15, 200))
    # Valve handle
    draw.rectangle([28, 4, 36, 60], fill=(200, 200, 200), outline=(160, 160, 160), width=1)
    draw.rectangle([4, 28, 60, 36], fill=(200, 200, 200), outline=(160, 160, 160), width=1)
    return img

def make_overclock_console():
    size = 96
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Console body
    draw.rectangle([8, 20, 88, 80], fill=(50, 50, 55, 240), outline=(100, 100, 110), width=2)
    # Screen
    draw.rectangle([15, 25, 60, 50], fill=(20, 25, 30, 220), outline=(80, 90, 100), width=1)
    # Levers
    for i in range(3):
        lx = 65 + i * 8
        draw.rectangle([lx, 30, lx + 5, 55], fill=(180, 160, 140))
        draw.ellipse([lx - 2, 25, lx + 7, 32], fill=(200, 30, 30, 200))
    # Gauges
    for i in range(2):
        gx = 20 + i * 25
        draw.ellipse([gx, 58, gx + 18, 76], fill=(220, 220, 220, 180), outline=(100, 100, 100), width=1)
    return img

def make_goblin_alarm():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Bell
    draw.polygon([(32, 8), (8, 40), (56, 40)], fill=(200, 180, 50, 230), outline=(160, 140, 30), width=2)
    # Stand
    draw.rectangle([24, 40, 40, 56], fill=(120, 100, 80))
    # Pull cord
    draw.line([(32, 40), (32, 60)], fill=(180, 180, 180), width=2)
    draw.ellipse([28, 56, 36, 64], fill=(200, 30, 30, 200))
    return img

def make_coolant_pipe():
    size = 96
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Horizontal pipe
    draw.rectangle([8, 30, 88, 66], fill=(100, 120, 140, 230), outline=(140, 170, 190), width=2)
    # Joints
    draw.rectangle([8, 26, 20, 70], fill=(120, 140, 160), outline=(160, 180, 200), width=1)
    draw.rectangle([76, 26, 88, 70], fill=(120, 140, 160), outline=(160, 180, 200), width=1)
    # Coolant glow
    draw.line([(22, 42), (74, 42)], fill=(100, 200, 255, 180), width=4)
    return img

def make_padlock():
    size = 48
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Body
    draw.rectangle([10, 20, 38, 44], fill=(180, 160, 120, 230), outline=(140, 120, 90), width=2)
    # Shackle
    draw.ellipse([12, 6, 36, 26], fill=(160, 140, 100), outline=(120, 100, 70), width=2)
    draw.ellipse([16, 10, 32, 22], fill=(35, 30, 25))
    # Keyhole
    draw.ellipse([20, 28, 28, 36], fill=(20, 20, 20))
    return img

def make_reactor_core():
    size = 128
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Outer containment
    draw.ellipse([8, 8, 120, 120], fill=(50, 45, 40, 240), outline=BRASS, width=4)
    # Glowing core
    for r in range(10, 55, 8):
        alpha = max(0, 200 - r * 3)
        draw.ellipse([32 - r, 32 - r, 96 + r, 96 + r], fill=MAGMA + (alpha,))
    # Inner core
    draw.ellipse([44, 44, 84, 84], fill=(255, 200, 50, 220))
    # Energy arcs
    for a in [0, 72, 144, 216, 288]:
        rad = math.radians(a)
        x1 = 64 + 30 * math.cos(rad)
        y1 = 64 + 30 * math.sin(rad)
        x2 = 64 + 50 * math.cos(rad)
        y2 = 64 + 50 * math.sin(rad)
        draw.line([(x1, y1), (x2, y2)], fill=(255, 255, 200, 150), width=2)
    return img

# =======================================================================
# ENEMY SPRITES (8 enemies x 4 frames)
# =======================================================================

def make_enemy_steam_mote(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (3, -3), 'damage': (-2, 0), 'death': (0, 5)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.2, 'damage': 0.6, 'death': 0.4}[frame]
    ox, oy = offset
    # Steam cloud body
    body_color = tuple(min(255, int(c * intensity)) for c in (200, 210, 220))
    for i in range(5):
        rx = cx + ox + random.randint(-15, 15)
        ry = cy + oy + random.randint(-12, 12)
        r = random.randint(8, 16)
        draw.ellipse([rx - r, ry - r, rx + r, ry + r], fill=body_color + (180,))
    # Fire core
    core_color = tuple(min(255, int(c * intensity)) for c in MAGMA)
    draw.ellipse([cx - 8 + ox, cy - 8 + oy, cx + 8 + ox, cy + 8 + oy], fill=core_color + (200,))
    if frame == 'attack':
        draw.line([(cx + 10 + ox, cy - 15 + oy), (cx + 30 + ox, cy - 30 + oy)], fill=MAGMA + (150,), width=3)
    if frame == 'damage':
        draw.line([(cx - 18, cy - 10), (cx + 18, cy + 15)], fill=(255, 50, 50, 150), width=2)
    return img

def make_enemy_glass_wraith(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (4, -4), 'damage': (-3, 0), 'death': (0, 6)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.3, 'damage': 0.7, 'death': 0.5}[frame]
    ox, oy = offset
    # Glass shards body
    body_color = tuple(min(255, int(c * intensity)) for c in (180, 220, 240))
    pts = [(cx + ox, cy - 25 + oy), (cx + 18 + ox, cy - 5 + oy), (cx + 10 + ox, cy + 20 + oy),
           (cx - 10 + ox, cy + 20 + oy), (cx - 18 + ox, cy - 5 + oy)]
    draw.polygon(pts, fill=body_color + (160,), outline=(200, 240, 255, 180), width=2)
    # Eyes
    eye_color = (50, 150, 255) if frame != 'death' else (100, 100, 100)
    draw.ellipse([cx - 8 + ox, cy - 8 + oy, cx - 3 + ox, cy - 3 + oy], fill=eye_color + (200,))
    draw.ellipse([cx + 3 + ox, cy - 8 + oy, cx + 8 + ox, cy - 3 + oy], fill=eye_color + (200,))
    if frame == 'attack':
        draw.polygon([(cx + 20 + ox, cy - 15 + oy), (cx + 35 + ox, cy + 5 + oy), (cx + 20 + ox, cy + 10 + oy)],
                     fill=body_color + (200,), outline=(180, 220, 240), width=1)
    if frame == 'damage':
        for _ in range(5):
            px = cx + random.randint(-15, 15)
            py = cy + random.randint(-10, 15)
            s = random.randint(3, 8)
            draw.polygon([(px, py), (px + s, py - s), (px + s * 2, py)], fill=body_color + (150,))
    return img

def make_enemy_pressure_knot(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (2, -2), 'damage': (-2, 0), 'death': (0, 5)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.2, 'damage': 0.7, 'death': 0.5}[frame]
    ox, oy = offset
    # Compressed water sphere
    body_color = tuple(min(255, int(c * intensity)) for c in (100, 150, 220))
    draw.ellipse([cx - 20 + ox, cy - 20 + oy, cx + 20 + ox, cy + 20 + oy], fill=body_color + (180,), outline=(150, 200, 255), width=2)
    # Pressure lines
    for i in range(3):
        r = 8 + i * 6
        draw.ellipse([cx - r + ox, cy - r + oy, cx + r + ox, cy + r + oy], outline=(200, 220, 255, 100), width=1)
    # Core
    core = (50, 100, 200) if frame != 'death' else (80, 80, 80)
    draw.ellipse([cx - 6 + ox, cy - 6 + oy, cx + 6 + ox, cy + 6 + oy], fill=core + (220,))
    if frame == 'attack':
        for i in range(6):
            rad = math.radians(i * 60)
            x2 = cx + 35 * math.cos(rad)
            y2 = cy + 35 * math.sin(rad)
            draw.line([(cx + ox, cy + oy), (x2 + ox, y2 + oy)], fill=(150, 200, 255, 150), width=2)
    if frame == 'damage':
        draw.line([(cx - 18, cy - 12), (cx + 18, cy + 12)], fill=(255, 50, 50, 150), width=2)
    return img

def make_enemy_ion_howler(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (5, -3), 'damage': (-3, 0), 'death': (0, 5)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.3, 'damage': 0.6, 'death': 0.4}[frame]
    ox, oy = offset
    # Lightning body
    body_color = tuple(min(255, int(c * intensity)) for c in (220, 220, 250))
    pts = [(cx + ox, cy - 22 + oy), (cx + 12 + ox, cy - 8 + oy), (cx + 8 + ox, cy + 5 + oy),
           (cx + 15 + ox, cy + 18 + oy), (cx - 5 + ox, cy + 15 + oy), (cx - 12 + ox, cy + 5 + oy),
           (cx - 8 + ox, cy - 8 + oy)]
    draw.polygon(pts, fill=body_color + (140,), outline=(200, 200, 255), width=2)
    # Electric arcs
    if frame != 'death':
        for _ in range(4):
            x1 = cx + random.randint(-18, 18)
            y1 = cy + random.randint(-18, 18)
            x2 = x1 + random.randint(-10, 10)
            y2 = y1 + random.randint(-15, 15)
            draw.line([(x1 + ox, y1 + oy), (x2 + ox, y2 + oy)], fill=(255, 255, 100, 180), width=1)
    # Eyes
    eye_color = (100, 100, 255) if frame != 'death' else (80, 80, 80)
    draw.ellipse([cx - 6 + ox, cy - 10 + oy, cx - 2 + ox, cy - 6 + oy], fill=eye_color)
    draw.ellipse([cx + 2 + ox, cy - 10 + oy, cx + 6 + ox, cy - 6 + oy], fill=eye_color)
    if frame == 'attack':
        draw.line([(cx + ox, cy - 25 + oy), (cx + ox, cy - 45 + oy)], fill=(255, 255, 100, 200), width=3)
    if frame == 'damage':
        draw.line([(cx - 15, cy - 10), (cx + 15, cy + 15)], fill=(255, 50, 50, 150), width=2)
    return img

def make_enemy_containment_goblin(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (3, -2), 'damage': (-2, 0), 'death': (0, 5)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.2, 'damage': 0.7, 'death': 0.5}[frame]
    ox, oy = offset
    body_color = tuple(min(255, int(c * intensity)) for c in GOBLIN_GREEN)
    draw.ellipse([cx - 16 + ox, cy - 3 + oy, cx + 16 + ox, cy + 22 + oy], fill=body_color, outline=GOBLIN_DARK, width=2)
    head_color = tuple(min(255, int(c * intensity)) for c in (50, 160, 50))
    draw.ellipse([cx - 12 + ox, cy - 20 + oy, cx + 12 + ox, cy + 2 + oy], fill=head_color, outline=GOBLIN_DARK, width=1)
    # Ears
    draw.ellipse([cx - 22 + ox, cy - 12 + oy, cx - 12 + ox, cy - 2 + oy], fill=body_color)
    draw.ellipse([cx + 12 + ox, cy - 12 + oy, cx + 22 + ox, cy - 2 + oy], fill=body_color)
    # Eyes
    eye_color = (255, 255, 0) if frame != 'death' else (100, 100, 100)
    draw.ellipse([cx - 7 + ox, cy - 12 + oy, cx - 3 + ox, cy - 8 + oy], fill=eye_color)
    draw.ellipse([cx + 3 + ox, cy - 12 + oy, cx + 7 + ox, cy - 8 + oy], fill=eye_color)
    # Wrench
    draw.rectangle([cx + 12 + ox, cy + 5 + oy, cx + 28 + ox, cy + 15 + oy], fill=(180, 170, 160, 220))
    if frame == 'attack':
        draw.rectangle([cx + 25 + ox, cy - 10 + oy, cx + 35 + ox, cy + 5 + oy], fill=(180, 170, 160, 220))
    if frame == 'damage':
        draw.line([(cx - 15, cy - 10), (cx + 15, cy + 15)], fill=(255, 50, 50, 150), width=2)
    return img

def make_enemy_alarm_ringer(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (4, -2), 'damage': (-2, 0), 'death': (0, 5)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.3, 'damage': 0.6, 'death': 0.4}[frame]
    ox, oy = offset
    body_color = tuple(min(255, int(c * intensity)) for c in (160, 140, 120))
    draw.ellipse([cx - 14 + ox, cy - 3 + oy, cx + 14 + ox, cy + 20 + oy], fill=body_color, outline=(120, 100, 80), width=2)
    head_color = tuple(min(255, int(c * intensity)) for c in GOBLIN_GREEN)
    draw.ellipse([cx - 10 + ox, cy - 18 + oy, cx + 10 + ox, cy + 2 + oy], fill=head_color, outline=GOBLIN_DARK, width=1)
    # Alarm bell
    bell_color = (220, 180, 40) if frame != 'death' else (100, 100, 100)
    draw.polygon([(cx + ox, cy - 22 + oy), (cx - 12 + ox, cy - 5 + oy), (cx + 12 + ox, cy - 5 + oy)], fill=bell_color + (220,), outline=(180, 150, 30), width=2)
    # Eyes
    eye_color = (255, 50, 50) if frame == 'attack' else (255, 255, 0)
    if frame == 'death':
        eye_color = (100, 100, 100)
    draw.ellipse([cx - 6 + ox, cy - 10 + oy, cx - 2 + ox, cy - 6 + oy], fill=eye_color)
    draw.ellipse([cx + 2 + ox, cy - 10 + oy, cx + 6 + ox, cy - 6 + oy], fill=eye_color)
    if frame == 'attack':
        draw.ellipse([cx - 20 + ox, cy - 30 + oy, cx + 20 + ox, cy + 5 + oy], fill=(255, 50, 50, 80))
    if frame == 'damage':
        draw.line([(cx - 12, cy - 8), (cx + 12, cy + 12)], fill=(255, 50, 50, 150), width=2)
    return img

def make_enemy_overclock_shaman(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (3, -4), 'damage': (-3, 0), 'death': (0, 6)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.3, 'damage': 0.6, 'death': 0.4}[frame]
    ox, oy = offset
    body_color = tuple(min(255, int(c * intensity)) for c in (100, 20, 120))
    draw.ellipse([cx - 16 + ox, cy - 3 + oy, cx + 16 + ox, cy + 22 + oy], fill=body_color, outline=(150, 50, 180), width=2)
    head_color = tuple(min(255, int(c * intensity)) for c in (120, 40, 140))
    draw.ellipse([cx - 12 + ox, cy - 22 + oy, cx + 12 + ox, cy + 2 + oy], fill=head_color, outline=(180, 80, 200), width=2)
    # Horns
    draw.polygon([(cx - 12 + ox, cy - 18 + oy), (cx - 20 + ox, cy - 35 + oy), (cx - 5 + ox, cy - 22 + oy)],
                 fill=(180, 140, 40, 220), outline=(160, 120, 30), width=1)
    draw.polygon([(cx + 12 + ox, cy - 18 + oy), (cx + 20 + ox, cy - 35 + oy), (cx + 5 + ox, cy - 22 + oy)],
                 fill=(180, 140, 40, 220), outline=(160, 120, 30), width=1)
    # Staff
    draw.line([(cx + 18 + ox, cy - 10 + oy), (cx + 30 + ox, cy - 40 + oy)], fill=(140, 120, 100), width=3)
    draw.ellipse([cx + 25 + ox, cy - 45 + oy, cx + 35 + ox, cy - 35 + oy], fill=MAGMA + (200,))
    # Eyes glow
    eye_color = (255, 100, 50) if frame != 'death' else (80, 80, 80)
    draw.ellipse([cx - 7 + ox, cy - 12 + oy, cx - 3 + ox, cy - 8 + oy], fill=eye_color)
    draw.ellipse([cx + 3 + ox, cy - 12 + oy, cx + 7 + ox, cy - 8 + oy], fill=eye_color)
    if frame == 'attack':
        for i in range(4):
            rad = math.radians(i * 90)
            x2 = cx + 25 * math.cos(rad)
            y2 = cy + 25 * math.sin(rad)
            draw.line([(cx + ox, cy + oy), (x2 + ox, y2 + oy)], fill=MAGMA + (150,), width=2)
    if frame == 'damage':
        draw.line([(cx - 15, cy - 10), (cx + 15, cy + 15)], fill=(255, 50, 50, 150), width=2)
    return img

def make_boss_chief_engineer_blix(frame):
    size = 96
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (5, -5), 'damage': (-4, 0), 'death': (0, 10)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.3, 'damage': 0.7, 'death': 0.5}[frame]
    ox, oy = offset
    # Goblin body with brass prosthetics
    body_color = tuple(min(255, int(c * intensity)) for c in GOBLIN_GREEN)
    draw.ellipse([cx - 22 + ox, cy - 5 + oy, cx + 22 + ox, cy + 30 + oy], fill=body_color, outline=GOBLIN_DARK, width=2)
    # Brass arm (replaced)
    draw.rectangle([cx + 18 + ox, cy + 5 + oy, cx + 40 + ox, cy + 25 + oy], fill=BRASS + (240,), outline=BRASS_DARK, width=2)
    draw.ellipse([cx + 32 + ox, cy + 15 + oy, cx + 48 + ox, cy + 25 + oy], fill=(180, 160, 140, 220))
    # Brass leg
    draw.rectangle([cx - 5 + ox, cy + 25 + oy, cx + 10 + ox, cy + 48 + oy], fill=BRASS + (240,), outline=BRASS_DARK, width=2)
    # Head
    head_color = tuple(min(255, int(c * intensity)) for c in (50, 160, 50))
    draw.ellipse([cx - 14 + ox, cy - 28 + oy, cx + 14 + ox, cy + 2 + oy], fill=head_color, outline=GOBLIN_DARK, width=2)
    # Eye patch
    draw.ellipse([cx - 10 + ox, cy - 18 + oy, cx - 3 + ox, cy - 12 + oy], fill=(80, 80, 80))
    # Good eye
    eye_color = (255, 100, 20) if frame != 'death' else (80, 80, 80)
    draw.ellipse([cx + 3 + ox, cy - 18 + oy, cx + 10 + ox, cy - 12 + oy], fill=eye_color)
    # Reactor core glow in chest (phases)
    if frame != 'death':
        for r in range(5, 20, 5):
            alpha = max(0, 150 - r * 6)
            draw.ellipse([cx - r + ox, cy + 5 - r + oy, cx + r + ox, cy + 5 + r + oy], fill=MAGMA + (alpha,))
    # Engineer goggles on head
    draw.rectangle([cx - 12 + ox, cy - 30 + oy, cx + 12 + ox, cy - 24 + oy], fill=(100, 100, 110, 200))
    if frame == 'attack':
        draw.line([(cx + 30 + ox, cy - 20 + oy), (cx + 50 + ox, cy - 40 + oy)], fill=MAGMA + (200,), width=4)
        draw.ellipse([cx + 40 + ox, cy - 50 + oy, cx + 60 + ox, cy - 30 + oy], fill=(255, 100, 20, 120))
    if frame == 'damage':
        draw.line([(cx - 25, cy - 20), (cx + 25, cy + 25)], fill=(255, 50, 50, 150), width=3)
    if frame == 'death':
        draw.line([(cx - 20, cy - 15), (cx + 20, cy + 20)], fill=(100, 100, 100, 150), width=2)
        draw.line([(cx - 15, cy + 10), (cx + 15, cy - 10)], fill=(100, 100, 100, 150), width=2)
    return img

# =======================================================================
# NPC / ITEM SPRITES
# =======================================================================

def make_npc_union_representative():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    # Goblin with union banner
    draw.ellipse([cx - 14, cy - 5, cx + 14, cy + 22], fill=GOBLIN_GREEN, outline=GOBLIN_DARK, width=2)
    draw.ellipse([cx - 12, cy - 20, cx + 12, cy + 2], fill=GOBLIN_GREEN)
    # Banner staff
    draw.line([(cx + 15, cy - 15), (cx + 15, cy + 25)], fill=(160, 140, 100), width=3)
    # Banner
    draw.polygon([(cx + 15, cy - 15), (cx + 45, cy - 5), (cx + 40, cy + 20), (cx + 15, cy + 10)],
                 fill=GOBLIN_GREEN + (200,), outline=GOBLIN_DARK, width=1)
    draw.line([(cx + 20, cy - 5), (cx + 38, cy + 2)], fill=(220, 220, 200), width=2)
    # Eyes
    draw.ellipse([cx - 7, cy - 12, cx - 3, cy - 8], fill=(255, 255, 0))
    draw.ellipse([cx + 3, cy - 12, cx + 7, cy - 8], fill=(255, 255, 0))
    return img

def make_item_elemental_core():
    size = 48
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    # Glowing core
    for r in range(5, 25, 5):
        alpha = max(0, 200 - r * 7)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=MAGMA + (alpha,))
    # Inner fire
    draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(255, 200, 50, 220))
    # Brass housing
    draw.ellipse([cx - 12, cy - 12, cx + 12, cy + 12], outline=BRASS, width=2)
    return img

def make_item_wrench():
    size = 48
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Handle
    draw.rectangle([18, 8, 30, 36], fill=(180, 170, 160, 230), outline=(140, 130, 120), width=1)
    # Head
    draw.ellipse([8, 32, 40, 44], fill=(180, 170, 160, 230), outline=(140, 130, 120), width=1)
    draw.rectangle([14, 36, 18, 42], fill=(50, 50, 50))
    draw.rectangle([30, 36, 34, 42], fill=(50, 50, 50))
    return img

# =======================================================================
# FACTION BANNERS
# =======================================================================

def make_banner_elemental():
    size = 32
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Orange/white fire-water-earth-air
    draw.polygon([(4, 4), (28, 4), (24, 28), (8, 28)], fill=MAGMA + (230,), outline=MAGMA_DARK, width=1)
    # Four elements symbol
    draw.ellipse([10, 8, 14, 12], fill=(255, 100, 20))  # fire
    draw.ellipse([18, 8, 22, 12], fill=(50, 100, 220))  # water
    draw.ellipse([10, 16, 14, 20], fill=(100, 180, 50))  # earth
    draw.ellipse([18, 16, 22, 20], fill=(200, 200, 255))  # air
    return img

def make_banner_goblin():
    size = 32
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Green/brown goblin industrial
    draw.polygon([(4, 4), (28, 4), (24, 28), (8, 28)], fill=GOBLIN_GREEN + (230,), outline=GOBLIN_DARK, width=1)
    # Gear symbol
    draw.ellipse([10, 10, 22, 22], outline=(220, 220, 200), width=2)
    draw.ellipse([13, 13, 19, 19], fill=GOBLIN_GREEN + (200,))
    return img

# =======================================================================
# MAIN GENERATION
# =======================================================================

def generate_all():
    os.makedirs(BASE_PATH, exist_ok=True)

    # Room backgrounds
    backgrounds = [
        ("bg_loading_bay.png", make_bg_loading_bay),
        ("bg_lower_works.png", make_bg_lower_works),
        ("bg_break_room.png", make_bg_break_room),
        ("bg_containment_hall.png", make_bg_containment_hall),
        ("bg_the_leak.png", make_bg_the_leak),
        ("bg_middle_works.png", make_bg_middle_works),
        ("bg_union_hall.png", make_bg_union_hall),
        ("bg_the_crack.png", make_bg_the_crack),
        ("bg_upper_works.png", make_bg_upper_works),
        ("bg_padlock_door.png", make_bg_padlock_door),
        ("bg_control_room.png", make_bg_control_room),
    ]
    for fname, maker in backgrounds:
        path = os.path.join(BASE_PATH, fname)
        img = maker()
        img.save(path)
        print(f"Created: {path} ({img.width}x{img.height})")

    # Floor tiles
    tiles = [
        ("tile_brass_factory.png", make_tile_brass_factory),
        ("tile_magma_glow.png", make_tile_magma_glow),
        ("tile_containment_ring.png", make_tile_containment_ring),
    ]
    for fname, maker in tiles:
        path = os.path.join(BASE_PATH, fname)
        img = maker()
        img.save(path)
        print(f"Created: {path} ({img.width}x{img.height})")

    # Environmental sprites
    env = [
        ("containment_vessel.png", make_containment_vessel),
        ("vent_valve.png", make_vent_valve),
        ("overclock_console.png", make_overclock_console),
        ("goblin_alarm.png", make_goblin_alarm),
        ("coolant_pipe.png", make_coolant_pipe),
        ("padlock.png", make_padlock),
        ("reactor_core.png", make_reactor_core),
    ]
    for fname, maker in env:
        path = os.path.join(BASE_PATH, fname)
        img = maker()
        img.save(path)
        print(f"Created: {path} ({img.width}x{img.height})")

    # Enemy sprites (8 enemies x 4 frames)
    enemies = [
        ("steam_mote", make_enemy_steam_mote),
        ("glass_wraith", make_enemy_glass_wraith),
        ("pressure_knot", make_enemy_pressure_knot),
        ("ion_howler", make_enemy_ion_howler),
        ("containment_goblin", make_enemy_containment_goblin),
        ("alarm_ringer", make_enemy_alarm_ringer),
        ("overclock_shaman", make_enemy_overclock_shaman),
    ]
    for name, maker in enemies:
        for frame in ["idle", "attack", "damage", "death"]:
            fname = f"enemy_{name}_{frame}.png"
            path = os.path.join(BASE_PATH, fname)
            img = maker(frame)
            img.save(path)
            print(f"Created: {path} ({img.width}x{img.height})")

    # Boss (Chief Engineer Blix)
    for frame in ["idle", "attack", "damage", "death"]:
        fname = f"boss_chief_engineer_blix_{frame}.png"
        path = os.path.join(BASE_PATH, fname)
        img = make_boss_chief_engineer_blix(frame)
        img.save(path)
        print(f"Created: {path} ({img.width}x{img.height})")

    # NPC / items
    npc_items = [
        ("npc_union_representative.png", make_npc_union_representative),
        ("item_elemental_core.png", make_item_elemental_core),
        ("item_wrench.png", make_item_wrench),
    ]
    for fname, maker in npc_items:
        path = os.path.join(BASE_PATH, fname)
        img = maker()
        img.save(path)
        print(f"Created: {path} ({img.width}x{img.height})")

    # Faction banners
    banners = [
        ("banner_elemental.png", make_banner_elemental),
        ("banner_goblin.png", make_banner_goblin),
    ]
    for fname, maker in banners:
        path = os.path.join(BASE_PATH, fname)
        img = maker()
        img.save(path)
        print(f"Created: {path} ({img.width}x{img.height})")

    print(f"\n=== Floor 8 asset generation complete ===")
    print(f"Total files in {BASE_PATH}: {len(os.listdir(BASE_PATH))}")

if __name__ == "__main__":
    generate_all()
