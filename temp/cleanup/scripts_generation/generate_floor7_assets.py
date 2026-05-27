#!/usr/bin/env python3
"""Generate Floor 7 (The Broken Pact) pixel art assets using PIL"""

from PIL import Image, ImageDraw
import os
import math
import random

random.seed(42)

BASE_PATH = "/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/floor7"

def ensure_dir(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)

def draw_hexagon(draw, cx, cy, radius, fill, outline=None, width=2):
    pts = []
    for i in range(6):
        angle = math.radians(60 * i - 30)
        pts.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle)))
    draw.polygon(pts, fill=fill, outline=outline, width=width)

# ========================================================================
# ROOM BACKGROUNDS
# ========================================================================

def make_bg_office():
    w, h = 2200, 1600
    img = Image.new('RGBA', (w, h), (30, 20, 15, 255))
    draw = ImageDraw.Draw(img)
    # Dark bureaucracy walls
    for y in range(0, h, 40):
        shade = 25 + int(10 * math.sin(y / 80))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 5, shade - 10), width=2)
    # Brass desks
    for i in range(5):
        x = 200 + i * 400
        y = 600 + (i % 2) * 200
        draw.rectangle([x, y, x + 300, y + 180], fill=(139, 115, 60, 220), outline=(180, 150, 80), width=3)
        draw.rectangle([x + 20, y + 20, x + 280, y + 80], fill=(100, 80, 40, 200))
        for j in range(3):
            px = x + 40 + j * 70
            draw.rectangle([px, y + 30, px + 50, y + 60], fill=(200, 190, 170, 180))
    # Filing cabinets
    for i in range(4):
        x = 100 + i * 500
        y = 1100
        for j in range(6):
            cy = y + j * 70
            draw.rectangle([x, cy, x + 120, cy + 60], fill=(80, 70, 60, 230), outline=(120, 110, 100), width=2)
            draw.rectangle([x + 10, cy + 20, x + 30, cy + 40], fill=(160, 140, 80))
    # Blood-ink contracts glow
    for i in range(3):
        x = 350 + i * 600
        y = 750
        draw.ellipse([x - 15, y - 15, x + 15, y + 15], fill=(180, 20, 20, 120))
    return img

def make_bg_court():
    w, h = 2200, 1600
    img = Image.new('RGBA', (w, h), (25, 20, 30, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 30):
        shade = 20 + int(8 * math.sin(y / 60))
        draw.line([(0, y), (w, y)], fill=(shade, shade, shade + 5), width=2)
    draw.rectangle([800, 300, 1400, 500], fill=(100, 70, 50, 230), outline=(150, 120, 90), width=4)
    draw.rectangle([850, 320, 1350, 380], fill=(80, 55, 40, 200))
    draw.rectangle([1100, 280, 1200, 320], fill=(139, 90, 43, 255))
    draw.rectangle([1180, 260, 1220, 340], fill=(139, 90, 43, 255))
    for i, x in enumerate([500, 1700]):
        draw.rectangle([x, 600, x + 200, 800], fill=(90, 70, 60, 220), outline=(130, 110, 100), width=2)
        draw.polygon([(x + 100, 550), (x + 50, 600), (x + 150, 600)], fill=(120, 100, 80))
    draw.rectangle([900, 100, 1300, 250], fill=(40, 35, 30, 240), outline=(100, 80, 60), width=3)
    for i in range(5):
        y = 130 + i * 22
        draw.line([(920, y), (1280, y)], fill=(180, 30, 30, 180), width=2)
    return img

def make_bg_break_room():
    w, h = 2000, 1400
    img = Image.new('RGBA', (w, h), (45, 40, 35, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 50):
        shade = 40 + int(10 * math.sin(y / 100))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 5, shade - 10), width=3)
    draw.rectangle([400, 500, 600, 800], fill=(80, 80, 90, 240), outline=(150, 150, 160), width=3)
    draw.rectangle([420, 520, 580, 600], fill=(60, 60, 70))
    draw.ellipse([460, 620, 540, 700], fill=(120, 80, 40))
    for i in range(3):
        x = 800 + i * 400
        draw.ellipse([x, 700, x + 250, 850], fill=(100, 80, 60, 220), outline=(140, 120, 100), width=2)
        draw.rectangle([x - 30, 850, x + 30, 950], fill=(120, 100, 80))
    draw.rectangle([1500, 900, 1900, 1300], fill=(60, 55, 50, 200), outline=(100, 90, 80), width=2)
    draw.rectangle([1550, 950, 1850, 1100], fill=(80, 70, 60))
    for _ in range(10):
        px = random.randint(200, 1800)
        py = random.randint(900, 1300)
        draw.rectangle([px, py, px + 30, py + 20], fill=(200, 190, 170, 150))
    return img

def make_bg_filing():
    w, h = 2000, 1400
    img = Image.new('RGBA', (w, h), (20, 18, 15, 255))
    draw = ImageDraw.Draw(img)
    for col in range(6):
        x = 100 + col * 320
        for row in range(8):
            y = 100 + row * 150
            shade = 40 + random.randint(-10, 10)
            draw.rectangle([x, y, x + 280, y + 130], fill=(shade, shade - 5, shade - 10, 230),
                          outline=(shade + 30, shade + 20, shade + 15), width=2)
            for d in range(3):
                dy = y + 20 + d * 40
                draw.rectangle([x + 120, dy, x + 160, dy + 15], fill=(120, 110, 90))
                draw.rectangle([x + 10, dy, x + 40, dy + 15], fill=(180, 30, 30, 150))
    for x in range(0, w, 40):
        draw.line([(x, 0), (x, h)], fill=(35, 30, 25), width=2)
    return img

def make_bg_corridor():
    w, h = 1800, 1200
    img = Image.new('RGBA', (w, h), (15, 10, 20, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 20):
        distortion = int(10 * math.sin(y / 50))
        draw.line([(50 + distortion, y), (w - 50 - distortion, y)], fill=(20 + distortion, 15, 25), width=2)
    for i in range(4):
        cx = 300 + i * 350
        cy = 400 + (i % 2) * 300
        for r in range(20, 80, 10):
            alpha = max(0, 200 - r * 3)
            color = (80 + r, 20, 120 + r // 2, alpha)
            draw.ellipse([cx - r, cy - r * 0.6, cx + r, cy + r * 0.6], fill=color)
        for a in range(0, 360, 30):
            rad = math.radians(a)
            x2 = cx + 100 * math.cos(rad)
            y2 = cy + 60 * math.sin(rad)
            draw.line([(cx, cy), (x2, y2)], fill=(180, 50, 220, 100), width=2)
    for _ in range(6):
        px = random.randint(200, 1600)
        py = random.randint(200, 1000)
        size = random.randint(40, 80)
        draw.polygon([(px, py), (px + size, py - size // 2), (px + size * 2, py),
                      (px + size * 1.5, py + size)], fill=(40, 20, 60, 100))
    return img

def make_bg_laboratory():
    w, h = 2200, 1600
    img = Image.new('RGBA', (w, h), (25, 20, 35, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 40):
        shade = 22 + int(8 * math.sin(y / 70))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 3, shade + 5), width=2)
    for i in range(4):
        x = 300 + i * 450
        y = 500 + (i % 2) * 300
        draw.rectangle([x, y, x + 300, y + 200], fill=(80, 70, 80, 220), outline=(120, 110, 120), width=2)
        draw.ellipse([x + 80, y - 40, x + 220, y + 40], fill=(60, 60, 70, 240), outline=(150, 150, 160), width=3)
        draw.ellipse([x + 100, y - 20, x + 200, y + 20], fill=(100 + i * 20, 50, 150, 180))
        for _ in range(5):
            bx = x + 110 + random.randint(0, 80)
            by = y - 30 - random.randint(0, 40)
            br = random.randint(3, 8)
            draw.ellipse([bx - br, by - br, bx + br, by + br], fill=(150, 100, 200, 150))
    for i in range(6):
        x = 200 + i * 320
        y = 1100
        draw.rectangle([x, y, x + 80, y + 150], fill=(100, 120, 130, 180), outline=(150, 170, 180), width=2)
        spec_color = [(200, 50, 50), (50, 200, 50), (50, 50, 200), (200, 200, 50)][i % 4]
        draw.ellipse([x + 15, y + 40, x + 65, y + 100], fill=spec_color + (150,))
    return img

def make_bg_storage():
    w, h = 1800, 1200
    img = Image.new('RGBA', (w, h), (30, 25, 20, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 30):
        shade = 28 + int(5 * math.sin(y / 50))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 3, shade - 5), width=2)
    for i in range(3):
        x = 400 + i * 500
        y = 700
        draw.rectangle([x, y, x + 150, y + 120], fill=(120, 90, 50, 230), outline=(180, 140, 80), width=3)
        draw.rectangle([x + 10, y + 10, x + 140, y + 50], fill=(100, 75, 45))
        draw.rectangle([x + 60, y + 40, x + 90, y + 60], fill=(180, 160, 80))
    for row in range(4):
        y = 200 + row * 200
        draw.line([(100, y), (1700, y)], fill=(80, 70, 60), width=8)
        for col in range(10):
            x = 150 + col * 160
            scroll_color = [(180, 150, 100), (150, 100, 80), (200, 180, 140)][col % 3]
            draw.rectangle([x, y - 40, x + 30, y], fill=scroll_color + (220,))
    draw.rectangle([800, 900, 1100, 1100], fill=(100, 80, 60, 240), outline=(150, 130, 100), width=3)
    draw.rectangle([820, 920, 1080, 1000], fill=(80, 65, 50))
    draw.rectangle([900, 880, 1000, 920], fill=(200, 190, 170))
    return img

def make_bg_court_ii():
    w, h = 2200, 1600
    img = Image.new('RGBA', (w, h), (20, 15, 25, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 25):
        shade = 15 + int(10 * math.sin(y / 50 + 1))
        draw.line([(0, y), (w, y)], fill=(shade, shade, shade + 3), width=2)
    draw.rectangle([700, 250, 1500, 450], fill=(80, 50, 40, 240), outline=(130, 90, 70), width=4)
    draw.rectangle([850, 50, 1350, 200], fill=(30, 25, 20, 250), outline=(150, 30, 30), width=4)
    for i in range(8):
        y = 80 + i * 15
        draw.line([(870, y), (1330, y)], fill=(200, 40, 40, 200), width=2)
    for i, x in enumerate([300, 600, 1600, 1900]):
        draw.rectangle([x, 550, x + 180, 750], fill=(70, 55, 50, 230), outline=(110, 95, 85), width=2)
        draw.polygon([(x + 90, 500), (x + 40, 550), (x + 140, 550)], fill=(100, 85, 75))
    draw.ellipse([1000, 1000, 1200, 1150], fill=(150, 20, 20, 100))
    draw.polygon([(1100, 1050), (1050, 1100), (1150, 1100)], fill=(180, 30, 30, 150))
    return img

def make_bg_void_lab():
    w, h = 2400, 1600
    img = Image.new('RGBA', (w, h), (10, 5, 20, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 15):
        wave = int(20 * math.sin(y / 40) + 15 * math.cos(y / 25))
        draw.line([(0 + wave, y), (w - wave, y)], fill=(15 + wave // 2, 8, 25 + wave), width=2)
    for i in range(5):
        cx = 400 + i * 400
        cy = 400 + (i % 2) * 400
        for sides in [3, 4, 5, 6]:
            r = 30 + sides * 15
            pts = []
            for j in range(sides):
                angle = math.radians(360 * j / sides + i * 30)
                pts.append((cx + r * math.cos(angle), cy + r * 0.7 * math.sin(angle)))
            color = (100 + sides * 20, 30, 150 + sides * 10, 80)
            draw.polygon(pts, fill=color)
        draw.ellipse([cx - 40, cy - 30, cx + 40, cy + 30], fill=(20, 10, 40, 200), outline=(150, 50, 200), width=2)
    for _ in range(8):
        x1 = random.randint(200, 2200)
        y1 = random.randint(200, 1400)
        x2 = x1 + random.randint(-100, 100)
        y2 = y1 + random.randint(-100, 100)
        draw.line([(x1, y1), (x2, y2)], fill=(180, 50, 220, 120), width=random.randint(2, 6))
    return img

def make_bg_antechamber():
    w, h = 2000, 1400
    img = Image.new('RGBA', (w, h), (25, 20, 18, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 35):
        shade = 22 + int(8 * math.sin(y / 60))
        draw.line([(0, y), (w, y)], fill=(shade, shade - 2, shade - 3), width=2)
    draw.rectangle([700, 200, 1300, 600], fill=(40, 35, 30, 240), outline=(80, 70, 60), width=5)
    for i in range(3):
        x = 750 + i * 180
        draw.rectangle([x, 250, x + 120, 550], fill=(35, 30, 25, 220), outline=(60, 55, 50), width=2)
        for ry in range(270, 530, 40):
            draw.ellipse([x + 10, ry, x + 25, ry + 15], fill=(100, 90, 80))
            draw.ellipse([x + 95, ry, x + 110, ry + 15], fill=(100, 90, 80))
    draw.rectangle([850, 900, 1150, 1100], fill=(100, 80, 60, 240), outline=(150, 130, 100), width=3)
    draw.rectangle([870, 920, 1130, 1000], fill=(80, 65, 50))
    draw.rectangle([920, 880, 1080, 920], fill=(200, 180, 140, 200))
    draw.ellipse([960, 860, 1040, 940], fill=(180, 150, 80, 120))
    for x in [600, 1400]:
        draw.rectangle([x, 400, x + 20, 500], fill=(80, 70, 60))
        draw.ellipse([x - 10, 350, x + 30, 420], fill=(255, 150, 50, 180))
    return img

def make_bg_auditorium():
    w, h = 2600, 1800
    img = Image.new('RGBA', (w, h), (20, 15, 25, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, h, 20):
        shade = 15 + int(12 * math.sin(y / 60))
        draw.line([(0, y), (w, y)], fill=(shade, shade, shade + 5), width=2)
    center_x, center_y = 1300, 900
    for tier in range(5):
        r = 400 + tier * 180
        draw.ellipse([center_x - r, center_y - r * 0.6, center_x + r, center_y + r * 0.6],
                     outline=(60 + tier * 15, 50 + tier * 10, 50 + tier * 12), width=4)
        for seat in range(12 + tier * 4):
            angle = math.radians(seat * 360 / (12 + tier * 4))
            sx = center_x + (r - 30) * math.cos(angle)
            sy = center_y + (r - 30) * 0.6 * math.sin(angle)
            draw.rectangle([sx - 15, sy - 10, sx + 15, sy + 10], fill=(80, 70, 65, 200))
    draw.rectangle([center_x - 150, center_y - 100, center_x + 150, center_y + 100],
                   fill=(60, 40, 80, 240), outline=(150, 100, 200), width=4)
    draw.polygon([(center_x, center_y - 150), (center_x - 120, center_y - 50),
                  (center_x + 120, center_y - 50)], fill=(80, 50, 120, 220))
    draw.ellipse([center_x - 80, center_y - 60, center_x + 80, center_y + 60], fill=(180, 100, 220, 100))
    for angle_deg in [0, 72, 144, 216, 288]:
        angle = math.radians(angle_deg)
        wx = center_x + 700 * math.cos(angle)
        wy = center_y + 400 * math.sin(angle)
        draw.rectangle([wx - 60, wy - 80, wx + 60, wy + 80], fill=(70, 60, 55, 220), outline=(110, 100, 90), width=2)
        draw.polygon([(wx, wy - 110), (wx - 40, wy - 80), (wx + 40, wy - 80)], fill=(100, 90, 80))
    return img

# ========================================================================
# FLOOR TILES
# ========================================================================

def make_tile_bureaucracy():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_hexagon(draw, size // 2, size // 2, size // 2 - 2, (139, 115, 60, 220), (180, 150, 80), 2)
    for y in range(15, size - 10, 8):
        draw.line([(12, y), (size - 12, y)], fill=(200, 190, 170, 150), width=1)
    draw.ellipse([size // 2 - 5, size // 2 - 3, size // 2 + 5, size // 2 + 3], fill=(100, 20, 20, 100))
    return img

def make_tile_void():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c1 = (20 + random.randint(0, 20), 5, 30 + random.randint(0, 20))
    c2 = (60 + random.randint(0, 30), 10, 80 + random.randint(0, 30))
    draw_hexagon(draw, size // 2, size // 2, size // 2 - 2, c1 + (220,), c2 + (180,), 2)
    for _ in range(3):
        x = random.randint(10, size - 10)
        y = random.randint(10, size - 10)
        s = random.randint(4, 10)
        draw.rectangle([x, y, x + s, y + s], fill=(150 + random.randint(-30, 30), 50, 200 + random.randint(-30, 30), 120))
    return img

def make_tile_marble():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_hexagon(draw, size // 2, size // 2, size // 2 - 2, (180, 180, 185, 230), (220, 220, 225), 2)
    for _ in range(2):
        x1 = random.randint(5, size - 5)
        y1 = random.randint(5, size - 5)
        x2 = x1 + random.randint(-20, 20)
        y2 = y1 + random.randint(-20, 20)
        draw.line([(x1, y1), (x2, y2)], fill=(140, 140, 150, 180), width=2)
    return img

# ========================================================================
# ENVIRONMENTAL SPRITES
# ========================================================================

def make_contract_station():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([8, 30, 56, 50], fill=(120, 90, 60, 230), outline=(160, 130, 90), width=2)
    draw.rectangle([12, 50, 18, 60], fill=(100, 75, 50))
    draw.rectangle([46, 50, 52, 60], fill=(100, 75, 50))
    draw.rectangle([20, 20, 44, 32], fill=(200, 190, 170, 220), outline=(180, 160, 130), width=1)
    draw.line([(48, 15), (48, 28)], fill=(220, 220, 200), width=2)
    draw.ellipse([46, 12, 50, 16], fill=(180, 50, 50))
    draw.ellipse([28, 22, 36, 30], fill=(255, 220, 150, 80))
    return img

def make_void_crack():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    pts = [(cx, 5), (cx + 8, 15), (cx - 5, 25), (cx + 12, 35),
           (cx - 8, 45), (cx + 5, 55), (cx, size - 5)]
    draw.polygon(pts, fill=(20, 5, 40, 200), outline=(150, 50, 220), width=2)
    for r in range(5, 25, 5):
        alpha = max(0, 150 - r * 6)
        draw.ellipse([cx - r, cy - r * 0.7, cx + r, cy + r * 0.7], fill=(100, 30, 180, alpha))
    for a in [0, 60, 120, 180, 240, 300]:
        rad = math.radians(a)
        x2 = cx + 25 * math.cos(rad)
        y2 = cy + 15 * math.sin(rad)
        draw.line([(cx, cy), (x2, y2)], fill=(200, 100, 255, 100), width=1)
    return img

def make_filing_cabinet():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([12, 4, 52, 60], fill=(70, 60, 55, 240), outline=(110, 100, 90), width=2)
    for i in range(4):
        y = 8 + i * 13
        draw.rectangle([16, y, 48, y + 10], fill=(80, 70, 65, 220), outline=(100, 90, 85), width=1)
        draw.rectangle([20, y + 3, 26, y + 7], fill=(160, 140, 80))
        draw.rectangle([36, y + 3, 42, y + 7], fill=(120, 110, 100))
    return img

def make_blood_ink_vat():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([15, 20, 49, 50], fill=(80, 70, 70, 230), outline=(120, 110, 110), width=2)
    draw.rectangle([18, 24, 46, 46], fill=(180, 20, 20, 200), outline=(220, 40, 40), width=1)
    for _ in range(3):
        bx = random.randint(22, 42)
        by = random.randint(26, 36)
        br = random.randint(2, 4)
        draw.ellipse([bx - br, by - br, bx + br, by + br], fill=(220, 60, 60, 150))
    draw.ellipse([20, 30, 44, 48], fill=(255, 50, 50, 60))
    return img

def make_summoning_circle():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    draw.ellipse([8, 8, 56, 56], fill=(20, 10, 40, 180), outline=(150, 50, 200), width=2)
    for sides in [3, 4, 6]:
        r = 8 + sides * 3
        pts = []
        for i in range(sides):
            angle = math.radians(360 * i / sides + sides * 15)
            pts.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
        draw.polygon(pts, outline=(180, 100, 220, 150), width=1)
    draw.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=(200, 100, 255, 120))
    return img

def make_witness_stand():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([10, 30, 54, 56], fill=(100, 80, 60, 230), outline=(140, 120, 100), width=2)
    draw.rectangle([14, 34, 50, 44], fill=(80, 65, 50))
    draw.polygon([(32, 12), (8, 32), (56, 32)], fill=(120, 100, 80, 220), outline=(160, 140, 120), width=2)
    draw.rectangle([28, 44, 36, 60], fill=(90, 75, 60))
    return img

def make_contract_altar():
    size = 96
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    draw.rectangle([20, 50, 76, 80], fill=(60, 40, 80, 240), outline=(120, 80, 160), width=3)
    draw.polygon([(cx, 20), (16, 52), (80, 52)], fill=(80, 50, 120, 220), outline=(150, 100, 200), width=2)
    draw.ellipse([cx - 15, cy - 10, cx + 15, cy + 15], fill=(180, 100, 220, 120))
    for x in [28, 68]:
        draw.line([(x, 55), (x, 75)], fill=(200, 150, 255, 180), width=2)
        draw.line([(x - 3, 60), (x + 3, 60)], fill=(200, 150, 255, 180), width=1)
    return img

# ========================================================================
# ENEMY SPRITES
# ========================================================================

def make_enemy_soul_clerk(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (3, -2), 'damage': (-2, 0), 'death': (0, 5)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.2, 'damage': 0.6, 'death': 0.4}[frame]
    ox, oy = offset
    body_color = tuple(min(255, int(c * intensity)) for c in (120, 110, 130))
    draw.ellipse([cx - 18 + ox, cy - 5 + oy, cx + 18 + ox, cy + 25 + oy], fill=body_color, outline=(160, 150, 170), width=2)
    head_color = tuple(min(255, int(c * intensity)) for c in (180, 170, 160))
    draw.ellipse([cx - 12 + ox, cy - 22 + oy, cx + 12 + ox, cy + 2 + oy], fill=head_color, outline=(200, 190, 180), width=1)
    eye_color = (50, 50, 200) if frame != 'death' else (80, 80, 80)
    draw.ellipse([cx - 8 + ox, cy - 14 + oy, cx - 3 + ox, cy - 9 + oy], fill=eye_color)
    draw.ellipse([cx + 3 + ox, cy - 14 + oy, cx + 8 + ox, cy - 9 + oy], fill=eye_color)
    draw.rectangle([cx + 12 + ox, cy - 5 + oy, cx + 22 + ox, cy + 15 + oy], fill=(150, 140, 120, 200))
    draw.line([(cx + 18 + ox, cy - 15 + oy), (cx + 18 + ox, cy - 5 + oy)], fill=(220, 220, 200), width=2)
    if frame == 'damage':
        draw.line([(cx - 20, cy - 20), (cx + 20, cy + 20)], fill=(255, 50, 50, 150), width=2)
    if frame == 'death':
        draw.line([(cx - 15, cy - 15), (cx + 15, cy + 15)], fill=(100, 100, 100, 150), width=2)
    return img

def make_enemy_contract_lawyer(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (4, -3), 'damage': (-3, 0), 'death': (0, 6)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.3, 'damage': 0.7, 'death': 0.5}[frame]
    ox, oy = offset
    body_color = tuple(min(255, int(c * intensity)) for c in (60, 60, 80))
    draw.ellipse([cx - 16 + ox, cy - 3 + oy, cx + 16 + ox, cy + 22 + oy], fill=body_color, outline=(100, 100, 130), width=2)
    head_color = tuple(min(255, int(c * intensity)) for c in (200, 180, 160))
    draw.ellipse([cx - 10 + ox, cy - 20 + oy, cx + 10 + ox, cy + 2 + oy], fill=head_color, outline=(220, 200, 180), width=1)
    draw.polygon([(cx + ox, cy - 5 + oy), (cx - 4 + ox, cy + 15 + oy), (cx + 4 + ox, cy + 15 + oy)], fill=(150, 20, 20, 200))
    draw.rectangle([cx - 9 + ox, cy - 14 + oy, cx + 9 + ox, cy - 8 + oy], fill=(20, 20, 20))
    draw.rectangle([cx - 20 + ox, cy + 5 + oy, cx - 8 + ox, cy + 18 + oy], fill=(80, 60, 40, 220), outline=(120, 90, 60), width=1)
    if frame == 'attack':
        draw.rectangle([cx + 10 + ox, cy - 10 + oy, cx + 25 + ox, cy + 5 + oy], fill=(80, 60, 40, 220))
        draw.line([(cx + 15 + ox, cy - 15 + oy), (cx + 18 + ox, cy - 10 + oy)], fill=(120, 90, 60), width=2)
    if frame == 'damage':
        draw.line([(cx - 18, cy - 18), (cx + 18, cy + 18)], fill=(255, 50, 50, 150), width=2)
    return img

def make_enemy_blood_notary(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (2, -2), 'damage': (-2, 0), 'death': (0, 5)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.2, 'damage': 0.7, 'death': 0.5}[frame]
    ox, oy = offset
    body_color = tuple(min(255, int(c * intensity)) for c in (120, 20, 20))
    draw.ellipse([cx - 18 + ox, cy - 5 + oy, cx + 18 + ox, cy + 25 + oy], fill=body_color, outline=(180, 40, 40), width=2)
    head_color = tuple(min(255, int(c * intensity)) for c in (220, 200, 200))
    draw.ellipse([cx - 11 + ox, cy - 22 + oy, cx + 11 + ox, cy + 2 + oy], fill=head_color, outline=(240, 220, 220), width=1)
    eye_color = (200, 20, 20) if frame != 'death' else (100, 100, 100)
    draw.ellipse([cx - 7 + ox, cy - 14 + oy, cx - 3 + ox, cy - 10 + oy], fill=eye_color)
    draw.ellipse([cx + 3 + ox, cy - 14 + oy, cx + 7 + ox, cy - 10 + oy], fill=eye_color)
    draw.ellipse([cx + 12 + ox, cy + 5 + oy, cx + 22 + ox, cy + 15 + oy], fill=(180, 30, 30, 200))
    if frame == 'attack':
        draw.rectangle([cx - 15 + ox, cy + 15 + oy, cx + 15 + ox, cy + 25 + oy], fill=(150, 20, 20, 150))
    if frame == 'damage':
        draw.line([(cx - 18, cy - 15), (cx + 18, cy + 15)], fill=(255, 100, 100, 150), width=2)
    return img

def make_enemy_debt_collector(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (3, -3), 'damage': (-3, 1), 'death': (0, 6)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.3, 'damage': 0.6, 'death': 0.4}[frame]
    ox, oy = offset
    body_color = tuple(min(255, int(c * intensity)) for c in (80, 80, 90))
    draw.ellipse([cx - 20 + ox, cy - 5 + oy, cx + 20 + ox, cy + 25 + oy], fill=body_color, outline=(120, 120, 140), width=3)
    draw.ellipse([cx - 14 + ox, cy - 22 + oy, cx + 14 + ox, cy + 2 + oy], fill=(90, 90, 100), outline=(130, 130, 150), width=2)
    visor_color = (200, 50, 50) if frame != 'death' else (60, 60, 60)
    draw.rectangle([cx - 10 + ox, cy - 12 + oy, cx + 10 + ox, cy - 6 + oy], fill=visor_color)
    draw.rectangle([cx - 18 + ox, cy + 5 + oy, cx - 5 + ox, cy + 18 + oy], fill=(150, 140, 120, 220))
    if frame == 'attack':
        for i in range(4):
            x = cx + 20 + i * 8
            y = cy - 5 + i * 5
            draw.ellipse([x + ox, y + oy, x + 6 + ox, y + 6 + oy], fill=(120, 120, 130), outline=(160, 160, 180), width=1)
    if frame == 'damage':
        draw.line([(cx - 20, cy - 10), (cx + 20, cy + 15)], fill=(255, 50, 50, 150), width=2)
    return img

def make_enemy_void_researcher(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (2, -4), 'damage': (-2, 0), 'death': (0, 5)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.2, 'damage': 0.7, 'death': 0.5}[frame]
    ox, oy = offset
    body_color = tuple(min(255, int(c * intensity)) for c in (180, 180, 190))
    draw.ellipse([cx - 15 + ox, cy - 3 + oy, cx + 15 + ox, cy + 22 + oy], fill=body_color, outline=(210, 210, 220), width=2)
    head_color = tuple(min(255, int(c * intensity)) for c in (120, 80, 160))
    draw.ellipse([cx - 12 + ox, cy - 20 + oy, cx + 12 + ox, cy + 2 + oy], fill=head_color, outline=(160, 110, 200), width=1)
    for i in range(3):
        tx = cx - 10 + i * 10
        ty = cy - 5
        draw.line([(tx + ox, ty + oy), (tx + ox + 5, ty + oy - 15)], fill=(140, 90, 180), width=2)
    eye_color = (150, 50, 250) if frame != 'death' else (80, 80, 80)
    draw.ellipse([cx - 7 + ox, cy - 14 + oy, cx - 2 + ox, cy - 9 + oy], fill=eye_color)
    draw.ellipse([cx + 2 + ox, cy - 14 + oy, cx + 7 + ox, cy - 9 + oy], fill=eye_color)
    draw.rectangle([cx + 12 + ox, cy + 2 + oy, cx + 20 + ox, cy + 15 + oy], fill=(100, 120, 150, 200))
    draw.ellipse([cx + 10 + ox, cy - 2 + oy, cx + 22 + ox, cy + 4 + oy], fill=(120, 140, 170, 180))
    if frame == 'attack':
        draw.line([(cx + 16 + ox, cy - 5 + oy), (cx + 30 + ox, cy - 20 + oy)], fill=(150, 50, 250, 150), width=3)
    if frame == 'damage':
        draw.line([(cx - 15, cy - 15), (cx + 15, cy + 15)], fill=(255, 100, 100, 150), width=2)
    return img

def make_enemy_paper_cut(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (5, -2), 'damage': (-2, 0), 'death': (0, 5)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.3, 'damage': 0.6, 'death': 0.4}[frame]
    ox, oy = offset
    body_color = tuple(min(255, int(c * intensity)) for c in (200, 190, 170))
    pts = [(cx + ox, cy - 20 + oy), (cx + 18 + ox, cy + 5 + oy), (cx + 8 + ox, cy + 20 + oy),
           (cx - 8 + ox, cy + 20 + oy), (cx - 18 + ox, cy + 5 + oy)]
    draw.polygon(pts, fill=body_color, outline=(180, 170, 150), width=2)
    for i in range(3):
        y = cy - 8 + i * 7
        draw.line([(cx - 10 + ox, y + oy), (cx + 10 + ox, y + oy)], fill=(80, 70, 60, 150), width=1)
    if frame == 'attack':
        draw.polygon([(cx + 20 + ox, cy - 15 + oy), (cx + 30 + ox, cy + 5 + oy), (cx + 20 + ox, cy + 10 + oy)],
                     fill=(200, 200, 190), outline=(180, 180, 170), width=1)
    if frame == 'damage':
        draw.line([(cx - 15, cy - 10), (cx + 15, cy + 15)], fill=(255, 50, 50, 150), width=2)
    if frame == 'death':
        for _ in range(5):
            px = cx + random.randint(-15, 15)
            py = cy + random.randint(-10, 15)
            s = random.randint(3, 8)
            draw.polygon([(px, py), (px + s, py - s), (px + s * 2, py)], fill=(180, 170, 150, 150))
    return img

def make_enemy_the_redacted(frame):
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (3, -3), 'damage': (-3, 0), 'death': (0, 5)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.3, 'damage': 0.6, 'death': 0.3}[frame]
    ox, oy = offset
    body_color = tuple(min(255, int(c * intensity)) for c in (15, 10, 20))
    draw.ellipse([cx - 17 + ox, cy - 5 + oy, cx + 17 + ox, cy + 22 + oy], fill=body_color, outline=(40, 30, 50), width=2)
    bar_alpha = 220 if frame != 'death' else 100
    draw.rectangle([cx - 14 + ox, cy - 12 + oy, cx + 14 + ox, cy - 4 + oy],
                   fill=(20, 20, 20, bar_alpha), outline=(180, 20, 20), width=2)
    if frame != 'death':
        for _ in range(4):
            px = cx + random.randint(-15, 15)
            py = cy + random.randint(-15, 15)
            draw.rectangle([px + ox, py + oy, px + 4 + ox, py + 4 + oy], fill=(180, 50, 220, 150))
    if frame == 'attack':
        draw.line([(cx + 20 + ox, cy - 15 + oy), (cx + 35 + ox, cy + 5 + oy)], fill=(200, 50, 250, 200), width=4)
    if frame == 'damage':
        draw.line([(cx - 18, cy - 12), (cx + 18, cy + 15)], fill=(255, 50, 50, 150), width=2)
    return img

def make_boss_the_denied(frame):
    size = 96
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    offset = {'idle': (0, 0), 'attack': (4, -4), 'damage': (-4, 0), 'death': (0, 8)}[frame]
    intensity = {'idle': 1.0, 'attack': 1.3, 'damage': 0.7, 'death': 0.5}[frame]
    ox, oy = offset
    body_color = tuple(min(255, int(c * intensity)) for c in (40, 30, 60))
    draw.ellipse([cx - 30 + ox, cy - 10 + oy, cx + 30 + ox, cy + 35 + oy], fill=body_color, outline=(80, 60, 120), width=3)
    head_color = tuple(min(255, int(c * intensity)) for c in (60, 50, 80))
    draw.ellipse([cx - 20 + ox, cy - 30 + oy, cx + 20 + ox, cy + 5 + oy], fill=head_color, outline=(100, 80, 150), width=2)
    draw.rectangle([cx + 22 + ox, cy - 25 + oy, cx + 28 + ox, cy + 30 + oy], fill=(139, 90, 43, 240))
    draw.rectangle([cx + 18 + ox, cy - 30 + oy, cx + 32 + ox, cy - 20 + oy], fill=(160, 120, 80))
    eye_color = (255, 50, 50) if frame != 'death' else (80, 80, 80)
    draw.ellipse([cx - 12 + ox, cy - 18 + oy, cx - 4 + ox, cy - 12 + oy], fill=eye_color)
    draw.ellipse([cx + 4 + ox, cy - 18 + oy, cx + 12 + ox, cy - 12 + oy], fill=eye_color)
    draw.line([(cx - 8 + ox, cy - 5 + oy), (cx + 8 + ox, cy - 5 + oy)], fill=(200, 50, 50), width=2)
    for i in range(3):
        y = cy + 10 + i * 8
        draw.ellipse([cx - 25 + ox, y + oy, cx - 15 + ox, y + 6 + oy], fill=(120, 100, 60, 180))
        draw.ellipse([cx + 15 + ox, y + oy, cx + 25 + ox, y + 6 + oy], fill=(120, 100, 60, 180))
    if frame == 'attack':
        draw.rectangle([cx + 10 + ox, cy + 20 + oy, cx + 40 + ox, cy + 35 + oy], fill=(180, 140, 100, 200))
        draw.ellipse([cx + 20 + ox, cy + 10 + oy, cx + 45 + ox, cy + 40 + oy], fill=(200, 50, 50, 100))
    if frame == 'damage':
        draw.line([(cx - 25, cy - 20), (cx + 25, cy + 25)], fill=(255, 50, 50, 150), width=3)
    if frame == 'death':
        draw.line([(cx - 20, cy - 15), (cx + 20, cy + 20)], fill=(100, 100, 100, 150), width=2)
        draw.line([(cx - 15, cy + 10), (cx + 15, cy - 10)], fill=(100, 100, 100, 150), width=2)
    return img

# ========================================================================
# NPC / ITEM SPRITES
# ========================================================================

def make_npc_goblin_forger():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    draw.ellipse([cx - 14, cy - 5, cx + 14, cy + 22], fill=(60, 80, 60, 230), outline=(90, 120, 90), width=2)
    draw.rectangle([cx - 12, cy + 5, cx + 12, cy + 22], fill=(80, 80, 100, 220))
    draw.ellipse([cx - 12, cy - 20, cx + 12, cy + 2], fill=(80, 160, 80), outline=(100, 200, 100), width=1)
    draw.ellipse([cx - 22, cy - 12, cx - 10, cy - 2], fill=(70, 140, 70))
    draw.ellipse([cx + 10, cy - 12, cx + 22, cy - 2], fill=(70, 140, 70))
    draw.ellipse([cx - 7, cy - 12, cx - 3, cy - 8], fill=(255, 255, 0))
    draw.ellipse([cx + 3, cy - 12, cx + 7, cy - 8], fill=(255, 255, 0))
    draw.rectangle([cx + 10, cy + 8, cx + 28, cy + 20], fill=(200, 190, 170, 220))
    draw.line([(cx + 12, cy + 12), (cx + 26, cy + 12)], fill=(80, 70, 60), width=1)
    draw.line([(cx + 12, cy + 16), (cx + 22, cy + 16)], fill=(80, 70, 60), width=1)
    return img

def make_item_pact_scroll():
    size = 48
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    draw.rectangle([cx - 12, cy - 18, cx + 12, cy + 18], fill=(220, 200, 160, 230), outline=(200, 180, 140), width=1)
    draw.ellipse([cx - 14, cy - 20, cx + 14, cy - 14], fill=(180, 160, 120))
    draw.ellipse([cx - 14, cy + 14, cx + 14, cy + 20], fill=(180, 160, 120))
    for i in range(3):
        y = cy - 8 + i * 7
        draw.line([(cx - 8, y), (cx + 8, y)], fill=(80, 60, 40, 150), width=1)
    draw.ellipse([cx - 16, cy - 16, cx + 16, cy + 16], fill=(255, 220, 150, 60))
    return img

def make_item_void_stabilizer():
    size = 48
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    draw.rectangle([cx - 14, cy - 10, cx + 14, cy + 10], fill=(60, 60, 80, 230), outline=(100, 100, 140), width=2)
    draw.line([(cx, cy - 10), (cx, cy - 22)], fill=(180, 180, 200), width=2)
    draw.ellipse([cx - 3, cy - 26, cx + 3, cy - 20], fill=(150, 150, 200))
    draw.ellipse([cx - 6, cy - 4, cx + 6, cy + 4], fill=(100, 200, 255, 180))
    for i in range(3):
        bx = cx - 8 + i * 8
        draw.ellipse([bx - 2, cy + 4, bx + 2, cy + 8], fill=(50 + i * 50, 200, 100))
    return img

# ========================================================================
# FACTION BANNERS
# ========================================================================

def make_banner_demon():
    size = 32
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.polygon([(4, 4), (28, 4), (24, 28), (8, 28)], fill=(139, 0, 0, 230), outline=(80, 0, 0), width=1)
    draw.polygon([(8, 8), (24, 8), (20, 24), (12, 24)], fill=(20, 10, 10, 200))
    draw.line([(12, 14), (10, 10)], fill=(180, 140, 40), width=2)
    draw.line([(20, 14), (22, 10)], fill=(180, 140, 40), width=2)
    draw.ellipse([14, 16, 18, 20], fill=(200, 50, 50))
    return img

def make_banner_aberration():
    size = 32
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.polygon([(4, 4), (28, 4), (24, 28), (8, 28)], fill=(75, 0, 130, 230), outline=(40, 0, 80), width=1)
    draw.polygon([(8, 8), (24, 8), (20, 24), (12, 24)], fill=(30, 10, 50, 200))
    draw.ellipse([12, 12, 20, 20], fill=(255, 215, 0, 180))
    draw.ellipse([14, 14, 18, 18], fill=(75, 0, 130))
    draw.polygon([(16, 8), (22, 22), (10, 22)], outline=(255, 215, 0, 150), width=1)
    return img

# ========================================================================
# MAIN GENERATION
# ========================================================================

def generate_all():
    os.makedirs(BASE_PATH, exist_ok=True)
    
    # Room backgrounds
    backgrounds = [
        ("bg_office.png", make_bg_office),
        ("bg_court.png", make_bg_court),
        ("bg_break_room.png", make_bg_break_room),
        ("bg_filing.png", make_bg_filing),
        ("bg_corridor.png", make_bg_corridor),
        ("bg_laboratory.png", make_bg_laboratory),
        ("bg_storage.png", make_bg_storage),
        ("bg_court_ii.png", make_bg_court_ii),
        ("bg_void_lab.png", make_bg_void_lab),
        ("bg_antechamber.png", make_bg_antechamber),
        ("bg_auditorium.png", make_bg_auditorium),
    ]
    for fname, maker in backgrounds:
        path = os.path.join(BASE_PATH, fname)
        img = maker()
        img.save(path)
        print(f"Created: {path} ({img.width}x{img.height})")
    
    # Floor tiles
    tiles = [
        ("tile_bureaucracy.png", make_tile_bureaucracy),
        ("tile_void.png", make_tile_void),
        ("tile_marble.png", make_tile_marble),
    ]
    for fname, maker in tiles:
        path = os.path.join(BASE_PATH, fname)
        img = maker()
        img.save(path)
        print(f"Created: {path} ({img.width}x{img.height})")
    
    # Environmental sprites
    env = [
        ("contract_station.png", make_contract_station),
        ("void_crack.png", make_void_crack),
        ("filing_cabinet.png", make_filing_cabinet),
        ("blood_ink_vat.png", make_blood_ink_vat),
        ("summoning_circle.png", make_summoning_circle),
        ("witness_stand.png", make_witness_stand),
        ("contract_altar.png", make_contract_altar),
    ]
    for fname, maker in env:
        path = os.path.join(BASE_PATH, fname)
        img = maker()
        img.save(path)
        print(f"Created: {path} ({img.width}x{img.height})")
    
    # Enemy sprites (8 enemies x 4 frames)
    enemies = [
        ("soul_clerk", make_enemy_soul_clerk),
        ("contract_lawyer", make_enemy_contract_lawyer),
        ("blood_notary", make_enemy_blood_notary),
        ("debt_collector", make_enemy_debt_collector),
        ("void_researcher", make_enemy_void_researcher),
        ("paper_cut", make_enemy_paper_cut),
        ("the_redacted", make_enemy_the_redacted),
    ]
    for name, maker in enemies:
        for frame in ["idle", "attack", "damage", "death"]:
            fname = f"enemy_{name}_{frame}.png"
            path = os.path.join(BASE_PATH, fname)
            img = maker(frame)
            img.save(path)
            print(f"Created: {path} ({img.width}x{img.height})")
    
    # Boss (The Denied)
    for frame in ["idle", "attack", "damage", "death"]:
        fname = f"boss_the_denied_{frame}.png"
        path = os.path.join(BASE_PATH, fname)
        img = make_boss_the_denied(frame)
        img.save(path)
        print(f"Created: {path} ({img.width}x{img.height})")
    
    # NPC / items
    npc_items = [
        ("npc_goblin_forger.png", make_npc_goblin_forger),
        ("item_pact_scroll.png", make_item_pact_scroll),
        ("item_void_stabilizer.png", make_item_void_stabilizer),
    ]
    for fname, maker in npc_items:
        path = os.path.join(BASE_PATH, fname)
        img = maker()
        img.save(path)
        print(f"Created: {path} ({img.width}x{img.height})")
    
    # Faction banners
    banners = [
        ("banner_demon.png", make_banner_demon),
        ("banner_aberration.png", make_banner_aberration),
    ]
    for fname, maker in banners:
        path = os.path.join(BASE_PATH, fname)
        img = maker()
        img.save(path)
        print(f"Created: {path} ({img.width}x{img.height})")
    
    print(f"\n=== Floor 7 asset generation complete ===")
    print(f"Total files in {BASE_PATH}: {len(os.listdir(BASE_PATH))}")

if __name__ == "__main__":
    generate_all()
