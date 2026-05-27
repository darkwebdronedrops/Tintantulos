#!/usr/bin/env python3
"""Generate Floor 10 (The Dragon — Apex of the Tower) pixel art assets using PIL"""

from PIL import Image, ImageDraw
import os
import math
import random

random.seed(42)

BASE_PATH = "/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/floor10"

def ensure_dir(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)

def darken(c, factor=0.7):
    if len(c) == 4:
        return tuple(min(255, int(x * factor)) for x in c[:3]) + (c[3],)
    return tuple(min(255, int(x * factor)) for x in c)

def lighten(c, factor=1.3):
    if len(c) == 4:
        return tuple(min(255, int(x * factor)) for x in c[:3]) + (c[3],)
    return tuple(min(255, int(x * factor)) for x in c)

# =======================================================================
# PALETTE — The Dragon's Lair (Sacred Emptiness)
# =======================================================================
VOID_BLACK = (8, 6, 10)
VOID_DEEP = (15, 12, 20)
GOLD_LIGHT = (255, 215, 100)
GOLD_MID = (220, 175, 60)
GOLD_DARK = (160, 120, 40)
GOLD_SHADOW = (100, 75, 25)
STONE_GRAY = (120, 115, 110)
STONE_DARK = (80, 75, 70)
STONE_LIGHT = (160, 155, 150)
GHOST_WHITE = (200, 210, 230)
GHOST_FAINT = (150, 160, 180)
MOLTEN_CORE = (255, 140, 30)
MOLTEN_GLOW = (255, 100, 20)
CRYSTAL_BLUE = (120, 200, 255)
CRYSTAL_GLOW = (80, 160, 220)
RUNE_GLOW = (180, 220, 255)
SACRED_PURPLE = (140, 80, 200)
SACRED_GLOW = (180, 120, 255)
CRACK_SHADOW = (30, 25, 35)

# =======================================================================
# BACKGROUNDS (11 moments)
# =======================================================================

def make_bg_threshold():
    """Moment 01 — stone pillars floating in void, ghostly light"""
    w, h = 2400, 1600
    img = Image.new('RGBA', (w, h), VOID_BLACK + (255,))
    draw = ImageDraw.Draw(img)
    # Void depth layers
    for y in range(0, h, 20):
        shade = 8 + int(6 * math.sin(y / 80))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 1, shade + 2), width=2)
    # Floating stone pillars
    for i in range(7):
        x = 200 + i * 340
        y = 400 + (i % 3) * 300
        # Pillar body
        draw.rectangle([x, y, x + 80, y + 280], fill=STONE_DARK + (240,), outline=STONE_GRAY, width=3)
        # Pillar top
        draw.polygon([(x - 10, y), (x + 90, y), (x + 70, y - 30), (x + 10, y - 30)], fill=STONE_GRAY + (220,), outline=STONE_LIGHT, width=2)
        # Pillar bottom
        draw.polygon([(x, y + 280), (x + 80, y + 280), (x + 60, y + 310), (x + 20, y + 310)], fill=STONE_DARK + (200,), outline=STONE_DARK, width=2)
        # Ghostly light orb near pillar
        for r in range(10, 50, 8):
            alpha = max(0, 100 - r)
            draw.ellipse([x + 30 - r, y - 60 - r, x + 50 + r, y - 40 + r], fill=GHOST_WHITE + (alpha,))
    # Floor path (subtle golden line)
    for x in range(0, w, 10):
        y = h - 200 + int(20 * math.sin(x / 200))
        draw.ellipse([x, y, x + 6, y + 6], fill=GOLD_SHADOW + (80,))
    return img

def make_bg_witness():
    """Moment 02 — fungal cavern echoes, spore memory clouds"""
    w, h = 2400, 1600
    img = Image.new('RGBA', (w, h), VOID_DEEP + (255,))
    draw = ImageDraw.Draw(img)
    # Void with faint echo of fungal green
    for y in range(0, h, 25):
        shade = 12 + int(8 * math.sin(y / 100))
        draw.line([(0, y), (w, y)], fill=(shade, shade + 3, shade), width=2)
    # Spore memory clouds (ethereal, drifting)
    for i in range(12):
        x = random.randint(200, 2200)
        y = random.randint(200, 1300)
        for r in range(15, 80, 10):
            alpha = max(0, 50 - r // 2)
            draw.ellipse([x - r, y - r * 0.4, x + r, y + r * 0.4], fill=(120, 160, 100, alpha))
    # Echo of fungal pillars (faint, translucent)
    for i in range(5):
        x = 300 + i * 450
        y = 500
        draw.rectangle([x, y, x + 60, y + 200], fill=(60, 80, 50, 60), outline=(80, 100, 60, 80), width=2)
    # Golden path continues
    for x in range(0, w, 8):
        y = h - 180 + int(15 * math.sin(x / 150))
        draw.ellipse([x, y, x + 5, y + 5], fill=GOLD_SHADOW + (60,))
    return img

def make_bg_memory():
    """Moment 03 — gearworks clockwork, rotating dial frozen"""
    w, h = 2400, 1600
    img = Image.new('RGBA', (w, h), VOID_BLACK + (255,))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 20):
        shade = 8 + int(5 * math.sin(y / 70))
        draw.line([(0, y), (w, y)], fill=(shade, shade, shade + 2), width=2)
    # Frozen clockwork gears (enormous, in background)
    for i in range(4):
        cx = 400 + i * 550
        cy = 400 + (i % 2) * 400
        radius = 150 + i * 30
        # Gear outline
        draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=(40, 38, 45, 120), outline=STONE_GRAY + (100,), width=2)
        # Gear teeth
        for j in range(12):
            angle = math.radians(j * 30)
            x1 = cx + (radius - 10) * math.cos(angle)
            y1 = cy + (radius - 10) * math.sin(angle)
            x2 = cx + (radius + 15) * math.cos(angle)
            y2 = cy + (radius + 15) * math.sin(angle)
            draw.line([(x1, y1), (x2, y2)], fill=STONE_GRAY + (80,), width=4)
        # Center frozen dial
        draw.ellipse([cx - 30, cy - 30, cx + 30, cy + 30], fill=GOLD_DARK + (150,), outline=GOLD_MID, width=2)
        # Frozen pointer
        draw.polygon([(cx, cy - 25), (cx + 8, cy + 5), (cx - 8, cy + 5)], fill=GOLD_LIGHT + (200,))
    # Golden path
    for x in range(0, w, 8):
        y = h - 190 + int(18 * math.sin(x / 160))
        draw.ellipse([x, y, x + 5, y + 5], fill=GOLD_SHADOW + (70,))
    return img

def make_bg_hoard():
    """Moment 04 — treasure not gold but crystallized moments"""
    w, h = 2600, 1800
    img = Image.new('RGBA', (w, h), VOID_BLACK + (255,))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 25):
        shade = 8 + int(6 * math.sin(y / 90))
        draw.line([(0, y), (w, y)], fill=(shade, shade, shade + 2), width=2)
    # Floating crystallized choice objects
    object_positions = [
        (400, 500, (200, 50, 50)),    # blood contract - red crystal
        (900, 400, (50, 200, 100)),   # soul gem - green crystal
        (1400, 600, (200, 150, 50)),  # reforged blade - gold crystal
        (1800, 450, (150, 150, 200)), # graduate scroll - purple crystal
        (700, 900, (100, 100, 200)),  # elevator gear - blue crystal
        (1200, 1000, (200, 100, 150)),# dial fragment - pink crystal
        (1700, 850, (150, 200, 200)), # lifter part - cyan crystal
        (500, 1200, (200, 200, 100)), # aether key - yellow crystal
        (1000, 1300, (180, 180, 180)),# master key - white crystal
        (1600, 1250, (200, 50, 100)), # pact scroll - crimson crystal
    ]
    for x, y, color in object_positions:
        # Crystal glow
        for r in range(10, 60, 8):
            alpha = max(0, 120 - r)
            draw.ellipse([x - r, y - r * 0.7, x + r, y + r * 0.7], fill=color + (alpha,))
        # Crystal body
        draw.polygon([(x, y - 40), (x + 25, y - 10), (x + 15, y + 30), (x - 15, y + 30), (x - 25, y - 10)], fill=color + (200,), outline=lighten(color, 1.5), width=2)
        # Inner glow core
        draw.ellipse([x - 8, y - 8, x + 8, y + 8], fill=lighten(color, 1.8) + (220,))
    # Golden path
    for x in range(0, w, 8):
        y = h - 200 + int(20 * math.sin(x / 180))
        draw.ellipse([x, y, x + 5, y + 5], fill=GOLD_SHADOW + (80,))
    return img

def make_bg_weight():
    """Moment 05 — player's "score" displayed as glowing runes"""
    w, h = 2400, 1600
    img = Image.new('RGBA', (w, h), VOID_BLACK + (255,))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 20):
        shade = 8 + int(5 * math.sin(y / 70))
        draw.line([(0, y), (w, y)], fill=(shade, shade, shade + 2), width=2)
    # Giant rune circle on ground
    cx, cy = w // 2, h // 2 + 200
    for r in range(100, 500, 50):
        alpha = max(0, 60 - r // 10)
        draw.ellipse([cx - r, cy - r * 0.3, cx + r, cy + r * 0.3], fill=GOLD_SHADOW + (alpha,), outline=GOLD_DARK + (alpha + 20,), width=2)
    # Rune symbols (simplified geometric shapes)
    rune_positions = [
        (cx - 300, cy - 100), (cx + 300, cy - 100),
        (cx - 200, cy + 50), (cx + 200, cy + 50),
        (cx, cy - 200), (cx, cy + 150),
        (cx - 150, cy - 50), (cx + 150, cy - 50),
    ]
    for rx, ry in rune_positions:
        for r in range(5, 30, 5):
            alpha = max(0, 150 - r * 4)
            draw.ellipse([rx - r, ry - r, rx + r, ry + r], fill=RUNE_GLOW + (alpha,))
        # Rune shape
        draw.polygon([(rx, ry - 15), (rx + 10, ry), (rx, ry + 15), (rx - 10, ry)], fill=RUNE_GLOW + (200,), outline=GHOST_WHITE, width=1)
    # Golden path
    for x in range(0, w, 8):
        y = h - 190 + int(15 * math.sin(x / 150))
        draw.ellipse([x, y, x + 5, y + 5], fill=GOLD_SHADOW + (70,))
    return img

def make_bg_aspect_time():
    """Moment 06 — clockwork dragon, scales showing player card history"""
    w, h = 2200, 1600
    img = Image.new('RGBA', (w, h), VOID_BLACK + (255,))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 20):
        shade = 8 + int(5 * math.sin(y / 70))
        draw.line([(0, y), (w, y)], fill=(shade, shade, shade + 2), width=2)
    # Clockwork dragon silhouette (coiled in background)
    # Body segments with clock faces
    segments = [(600, 500), (900, 400), (1200, 450), (1500, 500), (1700, 600), (1500, 800), (1200, 900)]
    for i, (sx, sy) in enumerate(segments):
        # Body segment
        draw.ellipse([sx - 60, sy - 40, sx + 60, sy + 40], fill=(50, 45, 55, 180), outline=STONE_GRAY + (120,), width=2)
        # Clock face on segment
        draw.ellipse([sx - 30, sy - 25, sx + 30, sy + 25], fill=(30, 28, 35, 200), outline=GOLD_MID + (150,), width=2)
        # Clock hands (different times = different cards used)
        angle = math.radians(i * 45)
        draw.line([(sx, sy), (sx + 20 * math.cos(angle), sy + 20 * math.sin(angle))], fill=GOLD_LIGHT + (180,), width=2)
    # Dragon head
    draw.polygon([(1700, 550), (1850, 520), (1900, 600), (1850, 650), (1700, 600)], fill=(50, 45, 55, 200), outline=STONE_GRAY, width=3)
    # Eyes (glowing blue clockwork)
    draw.ellipse([1780, 560, 1800, 580], fill=CRYSTAL_BLUE + (200,), outline=CRYSTAL_GLOW, width=1)
    draw.ellipse([1810, 560, 1830, 580], fill=CRYSTAL_BLUE + (200,), outline=CRYSTAL_GLOW, width=1)
    # Golden path
    for x in range(0, w, 8):
        y = h - 180 + int(15 * math.sin(x / 140))
        draw.ellipse([x, y, x + 5, y + 5], fill=GOLD_SHADOW + (70,))
    return img

def make_bg_aspect_greed():
    """Moment 07 — dragon of gold and flesh, growing with player's resources"""
    w, h = 2200, 1600
    img = Image.new('RGBA', (w, h), VOID_BLACK + (255,))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 20):
        shade = 8 + int(5 * math.sin(y / 70))
        draw.line([(0, y), (w, y)], fill=(shade, shade, shade + 2), width=2)
    # Gold and flesh dragon (more organic, bloated)
    segments = [(500, 600), (750, 500), (1000, 480), (1300, 520), (1600, 600)]
    for i, (sx, sy) in enumerate(segments):
        size = 50 + i * 15  # Gets larger
        color = (200 + i * 10, 160 + i * 5, 50 + i * 3)  # Gold tones
        draw.ellipse([sx - size, sy - size * 0.6, sx + size, sy + size * 0.6], fill=color + (180,), outline=GOLD_MID + (150,), width=2)
        # Flesh veins
        draw.line([(sx - size + 10, sy), (sx + size - 10, sy)], fill=(180, 100, 80, 100), width=2)
    # Dragon head (massive, crowned with gold)
    draw.ellipse([1550, 500, 1750, 700], fill=GOLD_MID + (200,), outline=GOLD_LIGHT, width=3)
    # Crown spikes
    for i in range(5):
        cx = 1580 + i * 35
        draw.polygon([(cx, 500), (cx + 10, 450), (cx + 20, 500)], fill=GOLD_LIGHT + (220,), outline=GOLD_MID, width=1)
    # Eyes (greedy red-gold)
    draw.ellipse([1620, 570, 1650, 600], fill=MOLTEN_GLOW + (220,), outline=GOLD_LIGHT, width=1)
    draw.ellipse([1680, 570, 1710, 600], fill=MOLTEN_GLOW + (220,), outline=GOLD_LIGHT, width=1)
    # Golden path
    for x in range(0, w, 8):
        y = h - 180 + int(15 * math.sin(x / 140))
        draw.ellipse([x, y, x + 5, y + 5], fill=GOLD_SHADOW + (70,))
    return img

def make_bg_aspect_transformation():
    """Moment 08 — shifting-form dragon, copies player enemies"""
    w, h = 2200, 1600
    img = Image.new('RGBA', (w, h), VOID_BLACK + (255,))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 20):
        shade = 8 + int(5 * math.sin(y / 70))
        draw.line([(0, y), (w, y)], fill=(shade, shade, shade + 2), width=2)
    # Shifting form dragon (distorted, multiple overlapping forms)
    forms = [
        # Form 1: Construct-like
        [(600, 550), (850, 450), (1100, 500), (1400, 550)],
        # Form 2: Aberration-like (offset)
        [(620, 580), (870, 480), (1120, 530), (1420, 580)],
        # Form 3: Undead-like (more offset, ghostly)
        [(640, 610), (890, 510), (1140, 560), (1440, 610)],
    ]
    colors = [STONE_GRAY + (100,), GHOST_FAINT + (80,), (100, 80, 120, 60)]
    for form, color in zip(forms, colors):
        for i, (sx, sy) in enumerate(form):
            draw.ellipse([sx - 50, sy - 35, sx + 50, sy + 35], fill=(40, 38, 45, 120), outline=color, width=2)
    # Dragon head (shifting between 3 forms)
    # Center form (dominant)
    draw.polygon([(1400, 520), (1550, 500), (1580, 600), (1520, 650), (1400, 600)], fill=(50, 45, 55, 180), outline=STONE_GRAY + (120,), width=2)
    # Eyes (shifting colors)
    draw.ellipse([1460, 550, 1485, 575], fill=CRYSTAL_BLUE + (150,), outline=GHOST_WHITE, width=1)
    draw.ellipse([1495, 550, 1520, 575], fill=SACRED_PURPLE + (150,), outline=GHOST_WHITE, width=1)
    # Golden path
    for x in range(0, w, 8):
        y = h - 180 + int(15 * math.sin(x / 140))
        draw.ellipse([x, y, x + 5, y + 5], fill=GOLD_SHADOW + (70,))
    return img

def make_bg_approach():
    """Moment 09 — Dragon visible in distance, throne of molten gold"""
    w, h = 2600, 1800
    img = Image.new('RGBA', (w, h), VOID_BLACK + (255,))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 20):
        shade = 8 + int(5 * math.sin(y / 70))
        draw.line([(0, y), (w, y)], fill=(shade, shade, shade + 2), width=2)
    # Throne of molten gold (in far distance, center)
    tx, ty = w // 2, 400
    # Throne base
    draw.rectangle([tx - 200, ty + 100, tx + 200, ty + 400], fill=GOLD_SHADOW + (200,), outline=GOLD_DARK, width=4)
    # Throne seat
    draw.polygon([(tx - 150, ty + 100), (tx + 150, ty + 100), (tx + 100, ty - 50), (tx - 100, ty - 50)], fill=GOLD_DARK + (220,), outline=GOLD_MID, width=3)
    # Throne back (tall)
    draw.polygon([(tx - 120, ty - 50), (tx + 120, ty - 50), (tx + 80, ty - 300), (tx - 80, ty - 300)], fill=GOLD_MID + (200,), outline=GOLD_LIGHT, width=3)
    # Molten gold glow from throne
    for r in range(20, 200, 15):
        alpha = max(0, 120 - r // 2)
        draw.ellipse([tx - r, ty + 200 - r * 0.3, tx + r, ty + 400 + r * 0.3], fill=MOLTEN_CORE + (alpha,))
    # Dragon silhouette on throne (massive, distant)
    # Wings
    draw.polygon([(tx - 400, ty - 200), (tx - 120, ty - 100), (tx - 150, ty - 50)], fill=(20, 15, 25, 180), outline=GOLD_SHADOW + (100,), width=2)
    draw.polygon([(tx + 400, ty - 200), (tx + 120, ty - 100), (tx + 150, ty - 50)], fill=(20, 15, 25, 180), outline=GOLD_SHADOW + (100,), width=2)
    # Dragon body (coiled around throne)
    for i in range(8):
        angle = math.radians(i * 45)
        bx = tx + 180 * math.cos(angle)
        by = ty + 50 + 80 * math.sin(angle)
        draw.ellipse([bx - 40, by - 25, bx + 40, by + 25], fill=(20, 15, 25, 200), outline=GOLD_SHADOW + (120,), width=2)
    # Dragon head (above throne)
    draw.polygon([(tx - 60, ty - 300), (tx + 60, ty - 300), (tx + 40, ty - 420), (tx - 40, ty - 420)], fill=(20, 15, 25, 220), outline=GOLD_MID + (150,), width=3)
    # Eyes (distant glowing dots)
    draw.ellipse([tx - 25, ty - 370, tx - 10, ty - 355], fill=MOLTEN_GLOW + (200,), outline=GOLD_LIGHT, width=1)
    draw.ellipse([tx + 10, ty - 370, tx + 25, ty - 355], fill=MOLTEN_GLOW + (200,), outline=GOLD_LIGHT, width=1)
    # Golden path (leading to throne)
    for x in range(0, w, 8):
        y = h - 200 + int(20 * math.sin(x / 200))
        draw.ellipse([x, y, x + 6, y + 6], fill=GOLD_SHADOW + (100,))
    # Final approach markers (golden pillars)
    for i in range(6):
        x = 300 + i * 400
        y = h - 350
        draw.rectangle([x, y, x + 30, y + 150], fill=GOLD_DARK + (180,), outline=GOLD_MID, width=2)
        draw.ellipse([x - 5, y - 10, x + 35, y + 10], fill=GOLD_MID + (200,), outline=GOLD_LIGHT, width=1)
    return img

def make_bg_revelation():
    """Moment 10 — Dragon Phase 1-2 arena, crack in wall behind throne (hidden)"""
    w, h = 2800, 1800
    img = Image.new('RGBA', (w, h), VOID_BLACK + (255,))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 20):
        shade = 8 + int(5 * math.sin(y / 70))
        draw.line([(0, y), (w, y)], fill=(shade, shade, shade + 2), width=2)
    # Massive throne (closer now)
    tx, ty = w // 2, 500
    # Throne platform
    draw.rectangle([tx - 300, ty + 200, tx + 300, ty + 600], fill=GOLD_SHADOW + (240,), outline=GOLD_DARK, width=4)
    # Throne itself
    draw.polygon([(tx - 200, ty + 200), (tx + 200, ty + 200), (tx + 150, ty), (tx - 150, ty)], fill=GOLD_DARK + (250,), outline=GOLD_MID, width=4)
    draw.polygon([(tx - 160, ty), (tx + 160, ty), (tx + 120, ty - 250), (tx - 120, ty - 250)], fill=GOLD_MID + (240,), outline=GOLD_LIGHT, width=4)
    # Molten gold dripping
    for i in range(8):
        x = tx - 120 + i * 35
        y = ty + 200
        draw.ellipse([x, y, x + 8, y + 30 + random.randint(0, 40)], fill=MOLTEN_CORE + (180,), outline=MOLTEN_GLOW, width=1)
    # Wall behind throne
    draw.rectangle([tx - 400, ty - 400, tx + 400, ty + 200], fill=(20, 18, 25, 200), outline=STONE_DARK + (100,), width=3)
    # Hidden crack in wall (barely visible — thin dark line)
    crack_x = tx + 50
    for i in range(30):
        cy = ty - 350 + i * 15
        cx = crack_x + int(5 * math.sin(i * 0.5))
        draw.line([(cx, cy), (cx + 2, cy + 8)], fill=CRACK_SHADOW + (40,), width=1)
    # Arena floor (golden runes)
    for r in range(100, 700, 80):
        alpha = max(0, 50 - r // 15)
        draw.ellipse([tx - r, ty + 600 - r * 0.2, tx + r, ty + 700 + r * 0.2], fill=GOLD_SHADOW + (alpha,), outline=GOLD_DARK + (alpha + 10,), width=1)
    # Golden path
    for x in range(0, w, 8):
        y = h - 200 + int(20 * math.sin(x / 200))
        draw.ellipse([x, y, x + 6, y + 6], fill=GOLD_SHADOW + (100,))
    return img

def make_bg_throne():
    """Moment 11 — Final Choice arena, three paths visible"""
    w, h = 2800, 1800
    img = Image.new('RGBA', (w, h), VOID_BLACK + (255,))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 20):
        shade = 8 + int(5 * math.sin(y / 70))
        draw.line([(0, y), (w, y)], fill=(shade, shade, shade + 2), width=2)
    # Central throne (now empty or occupied)
    tx, ty = w // 2, 500
    draw.rectangle([tx - 300, ty + 200, tx + 300, ty + 600], fill=GOLD_SHADOW + (240,), outline=GOLD_DARK, width=4)
    draw.polygon([(tx - 200, ty + 200), (tx + 200, ty + 200), (tx + 150, ty), (tx - 150, ty)], fill=GOLD_DARK + (250,), outline=GOLD_MID, width=4)
    # Three paths radiating from throne
    # Path A: Destroy (left, red runes)
    for i in range(20):
        x = tx - 300 - i * 60
        y = ty + 400 + i * 30
        draw.ellipse([x - 8, y - 8, x + 8, y + 8], fill=(200, 50, 50, 120), outline=(255, 80, 80), width=1)
    # Path B: Become (center, gold runes — brightest)
    for i in range(20):
        x = tx
        y = ty + 400 + i * 35
        draw.ellipse([x - 10, y - 10, x + 10, y + 10], fill=GOLD_MID + (180,), outline=GOLD_LIGHT, width=2)
    # Path C: Walk Away (right, green/blue runes)
    for i in range(20):
        x = tx + 300 + i * 60
        y = ty + 400 + i * 30
        draw.ellipse([x - 8, y - 8, x + 8, y + 8], fill=(50, 200, 150, 120), outline=(80, 255, 200), width=1)
    # Hidden door (Path C) — faint outline on right wall
    door_x = w - 300
    door_y = ty + 200
    draw.rectangle([door_x, door_y, door_x + 80, door_y + 160], fill=(20, 25, 30, 60), outline=(50, 80, 70, 80), width=2)
    draw.ellipse([door_x + 30, door_y + 70, door_x + 50, door_y + 90], fill=(50, 80, 70, 60), outline=(80, 120, 100), width=1)
    # Golden path
    for x in range(0, w, 8):
        y = h - 200 + int(20 * math.sin(x / 200))
        draw.ellipse([x, y, x + 6, y + 6], fill=GOLD_SHADOW + (100,))
    return img

# =======================================================================
# HOARD OBJECTS (crystallized choices)
# =======================================================================

def make_hoard_object(color, inner_color, shape="crystal"):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    # Glow
    for r in range(5, 35, 5):
        alpha = max(0, 140 - r * 3)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color + (alpha,))
    # Crystal body
    if shape == "crystal":
        draw.polygon([(cx, cy - 25), (cx + 20, cy - 5), (cx + 12, cy + 22), (cx - 12, cy + 22), (cx - 20, cy - 5)], fill=color + (220,), outline=lighten(color, 1.5), width=2)
    elif shape == "scroll":
        draw.rectangle([cx - 18, cy - 22, cx + 18, cy + 22], fill=color + (200,), outline=lighten(color, 1.5), width=2)
        draw.line([(cx - 14, cy - 15), (cx + 14, cy - 15)], fill=lighten(color, 1.3), width=1)
        draw.line([(cx - 14, cy), (cx + 14, cy)], fill=lighten(color, 1.3), width=1)
        draw.line([(cx - 14, cy + 15), (cx + 14, cy + 15)], fill=lighten(color, 1.3), width=1)
    elif shape == "blade":
        draw.polygon([(cx, cy - 28), (cx + 8, cy - 8), (cx + 3, cy + 20), (cx - 3, cy + 20), (cx - 8, cy - 8)], fill=color + (220,), outline=lighten(color, 1.5), width=2)
        draw.rectangle([cx - 4, cy + 18, cx + 4, cy + 28], fill=GOLD_DARK + (220,), outline=GOLD_MID, width=1)
    elif shape == "gear":
        draw.ellipse([cx - 18, cy - 18, cx + 18, cy + 18], fill=color + (200,), outline=lighten(color, 1.5), width=2)
        draw.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=(30, 30, 35))
    # Inner core
    draw.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=inner_color + (220,))
    return img

# =======================================================================
# ENVIRONMENTAL SPRITES
# =======================================================================

def make_stone_pillar():
    size = 128
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Pillar body
    draw.rectangle([30, 20, 98, 220], fill=STONE_DARK + (240,), outline=STONE_GRAY, width=3)
    # Pillar top
    draw.polygon([(20, 20), (108, 20), (98, 0), (40, 0)], fill=STONE_GRAY + (220,), outline=STONE_LIGHT, width=2)
    # Pillar bottom
    draw.polygon([(30, 220), (98, 220), (88, 240), (40, 240)], fill=STONE_DARK + (200,), outline=STONE_DARK, width=2)
    # Crack
    draw.line([(40, 40), (45, 80), (42, 120), (48, 160)], fill=CRACK_SHADOW + (150,), width=1)
    return img

def make_molten_gold_throne():
    size = 256
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Throne base
    draw.rectangle([20, 140, 236, 240], fill=GOLD_SHADOW + (240,), outline=GOLD_DARK, width=4)
    # Throne seat
    draw.polygon([(40, 140), (216, 140), (180, 60), (76, 60)], fill=GOLD_DARK + (250,), outline=GOLD_MID, width=3)
    # Throne back
    draw.polygon([(60, 60), (196, 60), (170, 10), (86, 10)], fill=GOLD_MID + (240,), outline=GOLD_LIGHT, width=3)
    # Molten gold glow
    for r in range(10, 80, 10):
        alpha = max(0, 160 - r * 2)
        draw.ellipse([60 - r, 160 - r * 0.3, 196 + r, 220 + r * 0.3], fill=MOLTEN_CORE + (alpha,))
    # Gold drips
    for i in range(6):
        x = 40 + i * 35
        draw.ellipse([x, 200, x + 6, 240 + random.randint(0, 20)], fill=MOLTEN_GLOW + (180,), outline=MOLTEN_CORE, width=1)
    return img

def make_void_sky():
    size = 512
    img = Image.new('RGBA', (size, size), VOID_BLACK + (255,))
    draw = ImageDraw.Draw(img)
    # Stars showing all floors simultaneously
    floor_colors = [
        (100, 150, 200),   # Floor 1 - blue portal
        (100, 200, 100),   # Floor 2 - green fungal
        (180, 180, 180),   # Floor 3 - gray gearworks
        (200, 150, 200),   # Floor 4 - purple bazaar
        (150, 200, 255),   # Floor 5 - light blue airship
        (200, 200, 150),   # Floor 6 - yellow university
        (200, 50, 50),     # Floor 7 - red pact
        (255, 100, 50),    # Floor 8 - orange forge
        (150, 150, 150),   # Floor 9 - gray bone
    ]
    for i, color in enumerate(floor_colors):
        x = 100 + (i % 3) * 150
        y = 100 + (i // 3) * 150
        for r in range(3, 25, 4):
            alpha = max(0, 120 - r * 4)
            draw.ellipse([x - r, y - r, x + r, y + r], fill=color + (alpha,))
        draw.ellipse([x - 4, y - 4, x + 4, y + 4], fill=color + (220,))
    return img

def make_hidden_crack():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Barely visible crack
    for i in range(10):
        cy = 10 + i * 5
        cx = 30 + int(3 * math.sin(i * 0.8))
        draw.line([(cx, cy), (cx + 2, cy + 4)], fill=CRACK_SHADOW + (50,), width=1)
    return img

def make_door_escape():
    size = 96
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Hidden door frame
    draw.rectangle([10, 10, 86, 86], fill=(20, 25, 30, 80), outline=(50, 80, 70, 120), width=2)
    # Door handle (faint)
    draw.ellipse([38, 40, 58, 60], fill=(50, 80, 70, 100), outline=(80, 120, 100), width=1)
    # Subtle glow around door (only visible to Liberator)
    for r in range(5, 30, 5):
        alpha = max(0, 60 - r)
        draw.ellipse([48 - r, 48 - r, 48 + r, 48 + r], fill=(50, 200, 150, alpha))
    return img

# =======================================================================
# ENEMY SPRITES (3 aspects + true Dragon, 4 frames each)
# =======================================================================

def make_enemy_aspect_time(frame):
    size = 96
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (5, -5), 'damage': (-4, 0), 'death': (0, 10)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.3, 'damage': 0.7, 'death': 0.5}[frame]
    ox, oy = offset
    # Clockwork dragon body
    body_color = tuple(min(255, int(c * intensity)) for c in (80, 75, 90))
    # Segments
    for i in range(3):
        sx = cx - 25 + i * 25 + ox
        sy = cy + 5 + oy
        draw.ellipse([sx - 18, sy - 12, sx + 18, sy + 12], fill=body_color + (200,), outline=STONE_GRAY + (150,), width=2)
        # Clock face on each segment
        draw.ellipse([sx - 10, sy - 8, sx + 10, sy + 8], fill=(40, 38, 50, 180), outline=GOLD_MID + (120,), width=1)
        angle = math.radians(i * 60 + (30 if frame == 'attack' else 0))
        draw.line([(sx, sy), (sx + 8 * math.cos(angle), sy + 8 * math.sin(angle))], fill=GOLD_LIGHT + (150,), width=1)
    # Head
    draw.polygon([(cx + 35 + ox, cy - 10 + oy), (cx + 55 + ox, cy - 20 + oy), (cx + 60 + ox, cy + oy), (cx + 50 + ox, cy + 15 + oy)], fill=body_color + (220,), outline=STONE_GRAY, width=2)
    # Eyes (blue crystal)
    eye_color = CRYSTAL_BLUE if frame != 'death' else (80, 80, 80)
    draw.ellipse([cx + 42 + ox, cy - 12 + oy, cx + 48 + ox, cy - 6 + oy], fill=eye_color + (200,), outline=CRYSTAL_GLOW, width=1)
    draw.ellipse([cx + 50 + ox, cy - 12 + oy, cx + 56 + ox, cy - 6 + oy], fill=eye_color + (200,), outline=CRYSTAL_GLOW, width=1)
    if frame == 'attack':
        # Time rewind effect (clock hands spin backward rapidly)
        for i in range(6):
            angle = math.radians(i * 60)
            x2 = cx + 40 + 20 * math.cos(angle)
            y2 = cy + 20 * math.sin(angle)
            draw.line([(cx + 40 + ox, cy + oy), (x2 + ox, y2 + oy)], fill=CRYSTAL_BLUE + (100,), width=2)
    if frame == 'damage':
        draw.line([(cx - 15, cy - 10), (cx + 15, cy + 15)], fill=(255, 50, 50, 150), width=2)
    if frame == 'death':
        # Gears fall apart
        for i in range(4):
            gx = cx + random.randint(-20, 20)
            gy = cy + random.randint(-10, 20)
            draw.ellipse([gx - 5, gy - 5, gx + 5, gy + 5], fill=STONE_GRAY + (100,))
    return img

def make_enemy_aspect_greed(frame):
    size = 96
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (6, -4), 'damage': (-4, 0), 'death': (0, 12)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.3, 'damage': 0.7, 'death': 0.4}[frame]
    ox, oy = offset
    # Gold and flesh dragon (bloated, growing)
    body_color = tuple(min(255, int(c * intensity)) for c in (200, 160, 60))
    # Bloated body
    draw.ellipse([cx - 30 + ox, cy - 15 + oy, cx + 30 + ox, cy + 25 + oy], fill=body_color + (200,), outline=GOLD_MID + (150,), width=2)
    # Flesh veins
    draw.line([(cx - 20 + ox, cy + oy), (cx + 20 + ox, cy + oy)], fill=(180, 100, 80, 100), width=2)
    # Crown of gold
    for i in range(5):
        sx = cx - 20 + i * 10 + ox
        draw.polygon([(sx, cy - 20 + oy), (sx + 5, cy - 35 + oy), (sx + 10, cy - 20 + oy)], fill=GOLD_LIGHT + (220,), outline=GOLD_MID, width=1)
    # Head
    draw.ellipse([cx + 20 + ox, cy - 25 + oy, cx + 50 + ox, cy + 5 + oy], fill=body_color + (220,), outline=GOLD_MID, width=2)
    # Eyes (greedy red-gold)
    eye_color = MOLTEN_GLOW if frame != 'death' else (80, 80, 80)
    draw.ellipse([cx + 28 + ox, cy - 18 + oy, cx + 34 + ox, cy - 12 + oy], fill=eye_color + (220,), outline=GOLD_LIGHT, width=1)
    draw.ellipse([cx + 38 + ox, cy - 18 + oy, cx + 44 + ox, cy - 12 + oy], fill=eye_color + (220,), outline=GOLD_LIGHT, width=1)
    if frame == 'attack':
        # Grasping claw (steals resources)
        draw.polygon([(cx + 45 + ox, cy + oy), (cx + 75 + ox, cy - 15 + oy), (cx + 80 + ox, cy + 5 + oy), (cx + 70 + ox, cy + 15 + oy)], fill=GOLD_DARK + (200,), outline=MOLTEN_GLOW, width=2)
    if frame == 'damage':
        draw.line([(cx - 15, cy - 10), (cx + 15, cy + 15)], fill=(255, 50, 50, 150), width=2)
    if frame == 'death':
        # Gold melts away
        for i in range(6):
            gx = cx + random.randint(-25, 25)
            gy = cy + random.randint(0, 20)
            draw.ellipse([gx - 4, gy - 4, gx + 4, gy + 4], fill=GOLD_MID + (100,))
    return img

def make_enemy_aspect_transformation(frame):
    size = 96
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (4, -3), 'damage': (-3, 0), 'death': (0, 8)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.2, 'damage': 0.7, 'death': 0.4}[frame]
    ox, oy = offset
    # Shifting form (multiple overlapping silhouettes)
    forms = [
        (cx - 5 + ox, cy + oy, (80, 75, 90)),    # Construct-like
        (cx + 5 + ox, cy - 3 + oy, (100, 90, 120)), # Aberration-like
        (cx + ox, cy + 5 + oy, (120, 110, 100)),   # Undead-like
    ]
    for fx, fy, color in forms:
        c = tuple(min(255, int(x * intensity)) for x in color)
        draw.ellipse([fx - 22, fy - 15, fx + 22, fy + 18], fill=c + (100,), outline=tuple(min(255, int(x * 1.2)) for x in c) + (80,), width=1)
    # Dominant head (center)
    head_color = tuple(min(255, int(c * intensity)) for c in (90, 85, 100))
    draw.polygon([(cx + 20 + ox, cy - 15 + oy), (cx + 45 + ox, cy - 25 + oy), (cx + 50 + ox, cy + oy), (cx + 40 + ox, cy + 15 + oy)], fill=head_color + (180,), outline=STONE_GRAY + (120,), width=2)
    # Shifting eyes (different colors)
    if frame != 'death':
        draw.ellipse([cx + 28 + ox, cy - 12 + oy, cx + 34 + ox, cy - 6 + oy], fill=CRYSTAL_BLUE + (150,), outline=GHOST_WHITE, width=1)
        draw.ellipse([cx + 38 + ox, cy - 12 + oy, cx + 44 + ox, cy - 6 + oy], fill=SACRED_PURPLE + (150,), outline=GHOST_WHITE, width=1)
    else:
        draw.ellipse([cx + 28 + ox, cy - 12 + oy, cx + 34 + ox, cy - 6 + oy], fill=(80, 80, 80))
        draw.ellipse([cx + 38 + ox, cy - 12 + oy, cx + 44 + ox, cy - 6 + oy], fill=(80, 80, 80))
    if frame == 'attack':
        # Copies player's form (mirror effect)
        draw.polygon([(cx - 30 + ox, cy + oy), (cx - 50 + ox, cy - 10 + oy), (cx - 55 + ox, cy + 5 + oy)], fill=(150, 150, 150, 80), outline=GHOST_WHITE, width=1)
    if frame == 'damage':
        draw.line([(cx - 15, cy - 10), (cx + 15, cy + 15)], fill=(255, 50, 50, 150), width=2)
    if frame == 'death':
        # Forms dissolve into mist
        for i in range(8):
            gx = cx + random.randint(-20, 20)
            gy = cy + random.randint(-10, 15)
            draw.ellipse([gx - 5, gy - 5, gx + 5, gy + 5], fill=GHOST_FAINT + (60,))
    return img

def make_boss_the_dragon(frame):
    size = 128
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (8, -8), 'damage': (-6, 0), 'death': (0, 15)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.3, 'damage': 0.7, 'death': 0.4}[frame]
    ox, oy = offset
    # True Dragon — molten gold scales
    # Coiled body segments
    for i in range(5):
        angle = math.radians(i * 72)
        bx = cx + 30 * math.cos(angle) + ox
        by = cy + 20 * math.sin(angle) + oy
        scale_color = tuple(min(255, int(c * intensity)) for c in GOLD_MID)
        draw.ellipse([bx - 22, by - 15, bx + 22, by + 15], fill=scale_color + (200,), outline=GOLD_LIGHT + (150,), width=2)
        # Scale texture
        for j in range(3):
            sx = bx - 12 + j * 12
            sy = by - 8
            draw.ellipse([sx, sy, sx + 8, sy + 6], fill=GOLD_DARK + (120,), outline=GOLD_SHADOW + (80,), width=1)
    # Wings
    wing_color = tuple(min(255, int(c * intensity)) for c in (30, 25, 20))
    draw.polygon([(cx - 40 + ox, cy - 30 + oy), (cx - 10 + ox, cy - 20 + oy), (cx - 20 + ox, cy + 10 + oy)], fill=wing_color + (180,), outline=GOLD_SHADOW + (100,), width=2)
    draw.polygon([(cx + 40 + ox, cy - 30 + oy), (cx + 10 + ox, cy - 20 + oy), (cx + 20 + ox, cy + 10 + oy)], fill=wing_color + (180,), outline=GOLD_SHADOW + (100,), width=2)
    # Head (massive, crowned)
    head_color = tuple(min(255, int(c * intensity)) for c in GOLD_DARK)
    draw.polygon([(cx + ox, cy - 50 + oy), (cx + 35 + ox, cy - 35 + oy), (cx + 40 + ox, cy + oy), (cx + 25 + ox, cy + 20 + oy), (cx - 25 + ox, cy + 20 + oy), (cx - 40 + ox, cy + oy), (cx - 35 + ox, cy - 35 + oy)], fill=head_color + (220,), outline=GOLD_MID, width=3)
    # Crown
    for i in range(7):
        sx = cx - 30 + i * 10 + ox
        draw.polygon([(sx, cy - 50 + oy), (sx + 5, cy - 70 + oy), (sx + 10, cy - 50 + oy)], fill=GOLD_LIGHT + (240,), outline=GOLD_MID, width=2)
    # Eyes (molten gold — piercing)
    eye_color = MOLTEN_CORE if frame != 'death' else (60, 60, 60)
    draw.ellipse([cx - 18 + ox, cy - 30 + oy, cx - 6 + ox, cy - 18 + oy], fill=eye_color + (240,), outline=GOLD_LIGHT, width=2)
    draw.ellipse([cx + 6 + ox, cy - 30 + oy, cx + 18 + ox, cy - 18 + oy], fill=eye_color + (240,), outline=GOLD_LIGHT, width=2)
    # Inner eye glow
    if frame != 'death':
        draw.ellipse([cx - 14 + ox, cy - 26 + oy, cx - 10 + ox, cy - 22 + oy], fill=(255, 255, 255, 200))
        draw.ellipse([cx + 10 + ox, cy - 26 + oy, cx + 14 + ox, cy - 22 + oy], fill=(255, 255, 255, 200))
    if frame == 'attack':
        # Molten breath
        for i in range(10):
            angle = math.radians(-30 + i * 6)
            x2 = cx + 60 * math.cos(angle)
            y2 = cy + 20 + 40 * math.sin(angle)
            draw.line([(cx + ox, cy + 10 + oy), (x2 + ox, y2 + oy)], fill=MOLTEN_CORE + (150,), width=3)
    if frame == 'damage':
        # Scales crack
        draw.line([(cx - 20, cy - 20), (cx + 10, cy + 10)], fill=(255, 50, 50, 150), width=3)
        draw.line([(cx + 15, cy - 15), (cx - 5, cy + 20)], fill=(255, 50, 50, 150), width=2)
    if frame == 'death':
        # Molten gold dissolves
        for i in range(12):
            gx = cx + random.randint(-35, 35)
            gy = cy + random.randint(-20, 30)
            draw.ellipse([gx - 5, gy - 5, gx + 5, gy + 5], fill=MOLTEN_GLOW + (80,))
        # Crown falls
        draw.polygon([(cx - 10, cy - 60), (cx + 10, cy - 60), (cx + 5, cy - 45)], fill=GOLD_MID + (100,))
    return img

# =======================================================================
# NPC/ITEM SPRITES
# =======================================================================

def make_ghost_boss(floor_num):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    # Ghostly translucent body
    # Different shape per floor
    if floor_num == 1:  # Snotling King — small, goblin-like ghost
        pts = [(cx, cy - 20), (cx + 15, cy - 5), (cx + 10, cy + 15), (cx - 10, cy + 15), (cx - 15, cy - 5)]
    elif floor_num == 2:  # Flesh Garden — wide, fungal ghost
        pts = [(cx, cy - 15), (cx + 20, cy - 5), (cx + 25, cy + 10), (cx - 25, cy + 10), (cx - 20, cy - 5)]
    elif floor_num == 3:  # Gear Mother — angular, construct ghost
        pts = [(cx, cy - 25), (cx + 18, cy - 10), (cx + 12, cy + 18), (cx - 12, cy + 18), (cx - 18, cy - 10)]
    elif floor_num == 4:  # The Eidolon — mirror ghost
        pts = [(cx, cy - 20), (cx + 12, cy - 5), (cx + 8, cy + 18), (cx - 8, cy + 18), (cx - 12, cy - 5)]
    elif floor_num == 5:  # Elemental Core — swirling ghost
        pts = [(cx, cy - 18), (cx + 15, cy - 8), (cx + 18, cy + 12), (cx - 18, cy + 12), (cx - 15, cy - 8)]
    elif floor_num == 6:  # The Dean — tall, academic ghost
        pts = [(cx, cy - 30), (cx + 12, cy - 10), (cx + 10, cy + 20), (cx - 10, cy + 20), (cx - 12, cy - 10)]
    elif floor_num == 7:  # The Denied — wide, bureaucratic ghost
        pts = [(cx, cy - 18), (cx + 18, cy - 5), (cx + 15, cy + 15), (cx - 15, cy + 15), (cx - 18, cy - 5)]
    elif floor_num == 8:  # Chief Engineer Blix — goblin ghost
        pts = [(cx, cy - 18), (cx + 14, cy - 5), (cx + 10, cy + 16), (cx - 10, cy + 16), (cx - 14, cy - 5)]
    elif floor_num == 9:  # The Foreman Eternal — construct ghost
        pts = [(cx, cy - 22), (cx + 16, cy - 8), (cx + 12, cy + 18), (cx - 12, cy + 18), (cx - 16, cy - 8)]
    else:
        pts = [(cx, cy - 20), (cx + 15, cy - 5), (cx + 10, cy + 15), (cx - 10, cy + 15), (cx - 15, cy - 5)]
    
    draw.polygon(pts, fill=GHOST_FAINT + (100,), outline=GHOST_WHITE + (120,), width=2)
    # Face (sad, remembering)
    draw.ellipse([cx - 6, cy - 8, cx - 2, cy - 4], fill=GHOST_WHITE + (150,))
    draw.ellipse([cx + 2, cy - 8, cx + 6, cy - 4], fill=GHOST_WHITE + (150,))
    # Mouth (small frown)
    draw.arc([cx - 4, cy - 2, cx + 4, cy + 4], start=0, end=180, fill=GHOST_WHITE + (100,), width=1)
    # Ghostly glow
    for r in range(5, 30, 5):
        alpha = max(0, 80 - r * 2)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GHOST_WHITE + (alpha,))
    return img

def make_item_wisdom():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    # Wisdom card — glowing book/tome
    for r in range(5, 40, 5):
        alpha = max(0, 120 - r * 2)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GOLD_MID + (alpha,))
    # Book shape
    draw.rectangle([cx - 18, cy - 22, cx + 18, cy + 22], fill=GOLD_DARK + (220,), outline=GOLD_LIGHT, width=2)
    # Pages
    draw.line([(cx, cy - 20), (cx, cy + 20)], fill=GHOST_WHITE + (150,), width=1)
    # Glow on pages
    for i in range(3):
        y = cy - 12 + i * 10
        draw.line([(cx - 12, y), (cx + 12, y)], fill=RUNE_GLOW + (180,), width=1)
    # Inner gem
    draw.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=GOLD_LIGHT + (240,), outline=GHOST_WHITE, width=1)
    return img

# =======================================================================
# MAIN
# =======================================================================

def main():
    print("Generating Floor 10 assets...")
    
    # Backgrounds
    backgrounds = [
        ("bg_threshold.png", make_bg_threshold),
        ("bg_witness.png", make_bg_witness),
        ("bg_memory.png", make_bg_memory),
        ("bg_hoard.png", make_bg_hoard),
        ("bg_weight.png", make_bg_weight),
        ("bg_aspect_time.png", make_bg_aspect_time),
        ("bg_aspect_greed.png", make_bg_aspect_greed),
        ("bg_aspect_transformation.png", make_bg_aspect_transformation),
        ("bg_approach.png", make_bg_approach),
        ("bg_revelation.png", make_bg_revelation),
        ("bg_throne.png", make_bg_throne),
    ]
    for name, fn in backgrounds:
        path = os.path.join(BASE_PATH, name)
        ensure_dir(path)
        fn().save(path)
        print(f"  [OK] {name}")
    
    # Hoard objects
    hoard_objects = [
        ("hoard_blood_contract.png", (180, 40, 40), (255, 100, 100), "scroll"),
        ("hoard_soul_gem.png", (40, 180, 100), (150, 255, 180), "crystal"),
        ("hoard_reforged_blade.png", (200, 160, 60), (255, 220, 120), "blade"),
        ("hoard_graduate_scroll.png", (140, 100, 200), (200, 160, 255), "scroll"),
        ("hoard_elevator_gear.png", (100, 120, 200), (150, 180, 255), "gear"),
        ("hoard_dial_fragment.png", (200, 100, 150), (255, 160, 200), "crystal"),
        ("hoard_lifter_part.png", (120, 180, 180), (180, 240, 240), "gear"),
        ("hoard_aether_key.png", (200, 200, 100), (255, 255, 150), "crystal"),
        ("hoard_master_key.png", (180, 180, 180), (240, 240, 240), "crystal"),
        ("hoard_pact_scroll.png", (180, 40, 80), (255, 100, 140), "scroll"),
    ]
    for name, color, inner, shape in hoard_objects:
        path = os.path.join(BASE_PATH, name)
        ensure_dir(path)
        make_hoard_object(color, inner, shape).save(path)
        print(f"  [OK] {name}")
    
    # Environmental
    env_sprites = [
        ("stone_pillar.png", make_stone_pillar),
        ("molten_gold_throne.png", make_molten_gold_throne),
        ("void_sky.png", make_void_sky),
        ("hidden_crack.png", make_hidden_crack),
        ("door_escape.png", make_door_escape),
    ]
    for name, fn in env_sprites:
        path = os.path.join(BASE_PATH, name)
        ensure_dir(path)
        fn().save(path)
        print(f"  [OK] {name}")
    
    # Enemy sprites (4 frames each)
    enemies = [
        ("enemy_aspect_time", make_enemy_aspect_time),
        ("enemy_aspect_greed", make_enemy_aspect_greed),
        ("enemy_aspect_transformation", make_enemy_aspect_transformation),
        ("boss_the_dragon", make_boss_the_dragon),
    ]
    for prefix, fn in enemies:
        for frame in ['idle', 'attack', 'damage', 'death']:
            name = f"{prefix}_{frame}.png"
            path = os.path.join(BASE_PATH, name)
            ensure_dir(path)
            fn(frame).save(path)
            print(f"  [OK] {name}")
    
    # Ghost bosses (f1 through f9)
    for i in range(1, 10):
        name = f"ghost_boss_f{i}.png"
        path = os.path.join(BASE_PATH, name)
        ensure_dir(path)
        make_ghost_boss(i).save(path)
        print(f"  [OK] {name}")
    
    # Item wisdom
    path = os.path.join(BASE_PATH, "item_wisdom.png")
    ensure_dir(path)
    make_item_wisdom().save(path)
    print(f"  [OK] item_wisdom.png")
    
    print(f"\nDone! All Floor 10 assets saved to {BASE_PATH}")

if __name__ == "__main__":
    main()
