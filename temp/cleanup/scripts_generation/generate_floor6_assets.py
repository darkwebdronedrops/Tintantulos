#!/usr/bin/env python3
"""Generate pixel art assets for Floor 6 — The Lunar University"""

from PIL import Image, ImageDraw, ImageFont
import os
import math
import random

BASE_PATH = "/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/floor6"

def ensure_dir(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)

def get_font(size=8):
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size)
    except:
        return ImageFont.load_default()

def get_font_regular(size=8):
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", size)
    except:
        return ImageFont.load_default()

# ===================================================================
# BACKGROUND HELPERS
# ===================================================================

def draw_moonlight_gradient(draw, w, h, top_color, bottom_color, horizon_y=None):
    if horizon_y is None:
        horizon_y = h * 2 // 3
    for y in range(horizon_y):
        t = y / horizon_y
        r = int(top_color[0] * (1-t) + bottom_color[0] * t)
        g = int(top_color[1] * (1-t) + bottom_color[1] * t)
        b = int(top_color[2] * (1-t) + bottom_color[2] * t)
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))

def draw_moon(draw, x, y, radius, glow_radius=60):
    """Draw a glowing moon with craters"""
    for glow in range(glow_radius, 0, -5):
        alpha = int(30 * (1 - glow / glow_radius))
        draw.ellipse([x-glow, y-glow, x+glow, y+glow], fill=(220, 220, 240, alpha))
    draw.ellipse([x-radius, y-radius, x+radius, y+radius], fill=(240, 240, 255, 255), outline=(200, 200, 220, 255), width=2)
    # Craters
    for cx, cy, cr in [(x-8, y-5, 4), (x+6, y+3, 3), (x-3, y+8, 2), (x+10, y-8, 2)]:
        draw.ellipse([cx-cr, cy-cr, cx+cr, cy+cr], fill=(210, 210, 230, 200), outline=(190, 190, 210, 150), width=1)

def draw_brass_spire(draw, x, y_bottom, height, width=40, detail=True):
    """Draw a brass/gothic spire"""
    # Main tower body
    draw.rectangle([x-width//2, y_bottom-height, x+width//2, y_bottom], fill=(120, 100, 70, 255), outline=(160, 130, 90, 255), width=2)
    if detail:
        # Windows
        for wy in range(y_bottom-height+20, y_bottom-20, 30):
            draw.rectangle([x-8, wy, x+8, wy+15], fill=(60, 50, 40, 255), outline=(100, 80, 60, 255), width=1)
    # Spire tip
    draw.polygon([(x, y_bottom-height-60), (x-width//2-5, y_bottom-height), (x+width//2+5, y_bottom-height)], fill=(140, 120, 80, 255), outline=(180, 150, 100, 255), width=2)
    # Clock face (if applicable)
    draw.ellipse([x-12, y_bottom-height+10, x+12, y_bottom-height+34], fill=(200, 190, 170, 255), outline=(160, 130, 90, 255), width=2)

def draw_steam_leak(draw, x, y, length=40, direction='up'):
    """Draw steam leak effect"""
    for i in range(5):
        offset = i * 8
        alpha = int(100 - i * 15)
        sx = x + random.randint(-5, 5)
        sy = y - offset if direction == 'up' else y + offset
        draw.ellipse([sx-8, sy-4, sx+8, sy+4], fill=(200, 200, 210, alpha), outline=(180, 180, 190, alpha//2), width=1)

# ===================================================================
# ROOM BACKGROUNDS
# ===================================================================

def create_bg_quadrangle(output_path, size=(2400, 1600)):
    """The Quadrangle — moonlit courtyard, clocktower, statue garden"""
    ensure_dir(output_path)
    w, h = size
    img = Image.new('RGBA', size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    
    # Night sky with moon
    draw_moonlight_gradient(draw, w, h, (15, 18, 35), (35, 38, 55), h*3//4)
    draw_moon(draw, w*3//4, h//5, 35)
    
    # Stars
    for _ in range(60):
        sx = random.randint(0, w)
        sy = random.randint(0, h//3)
        br = random.randint(150, 220)
        draw.ellipse([sx-1, sy-1, sx+1, sy+1], fill=(br, br, 220, 255))
    
    # Ground — moonlit stone courtyard
    ground_y = h * 2 // 3
    draw.rectangle([0, ground_y, w, h], fill=(45, 45, 55, 255))
    # Cobblestone pattern
    for cx in range(0, w, 80):
        for cy in range(ground_y, h, 50):
            offset = (cy - ground_y) % 100 // 2
            draw.rectangle([cx+offset, cy, cx+offset+70, cy+40], fill=(50, 50, 60, 255), outline=(60, 60, 70, 255), width=1)
    
    # Clocktower (center)
    tower_x = w // 2
    draw_brass_spire(draw, tower_x, ground_y, 500, 60, True)
    # Clock face glowing
    draw.ellipse([tower_x-25, ground_y-490, tower_x+25, ground_y-440], fill=(240, 220, 150, 255), outline=(200, 180, 100, 255), width=3)
    # Clock hands
    draw.line([(tower_x, ground_y-465), (tower_x, ground_y-445)], fill=(80, 60, 40, 255), width=3)
    draw.line([(tower_x, ground_y-465), (tower_x+15, ground_y-455)], fill=(80, 60, 40, 255), width=2)
    
    # Bells at top
    for bx in [tower_x-35, tower_x+35]:
        draw.ellipse([bx-12, ground_y-560, bx+12, ground_y-530], fill=(180, 150, 80, 255), outline=(220, 190, 120, 255), width=2)
    
    # Statue garden (right side)
    for sx in [w*3//4, w*3//4+150, w*3//4-100]:
        # Pedestal
        draw.rectangle([sx-20, ground_y-30, sx+20, ground_y], fill=(70, 70, 80, 255), outline=(90, 90, 100, 255), width=2)
        # Statue (blocky humanoid)
        draw.rectangle([sx-12, ground_y-80, sx+12, ground_y-30], fill=(90, 90, 100, 255), outline=(110, 110, 120, 255), width=1)
        # Head
        draw.ellipse([sx-10, ground_y-100, sx+10, ground_y-80], fill=(100, 100, 110, 255), outline=(120, 120, 130, 255), width=1)
    
    # College buildings (background, at edges)
    for bx, by in [(200, ground_y), (w-200, ground_y)]:
        draw_brass_spire(draw, bx, by, 350, 50, False)
    
    # Moonlight beams (subtle)
    for mx in [400, w//2, w-400]:
        for my in range(ground_y, h, 20):
            alpha = int(20 + 10 * math.sin(mx * 0.01 + my * 0.02))
            draw.line([(mx-30, my), (mx+30, my)], fill=(200, 200, 240, alpha), width=2)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_bg_gears(output_path, size=(2200, 1600)):
    """College of Gears — mechanical workshops, brass machinery, gear gardens"""
    ensure_dir(output_path)
    w, h = size
    img = Image.new('RGBA', size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    
    # Dark workshop interior
    draw.rectangle([0, 0, w, h], fill=(25, 22, 18, 255))
    
    # Ceiling beams
    for y in [40, 100, 160]:
        draw.rectangle([0, y, w, y+15], fill=(60, 50, 40, 255), outline=(80, 70, 60, 255), width=1)
    
    # Floor
    floor_y = h * 2 // 3
    draw.rectangle([0, floor_y, w, h], fill=(50, 42, 35, 255))
    for x in range(0, w, 100):
        draw.line([(x, floor_y), (x, h)], fill=(70, 60, 50, 255), width=1)
    
    # Brass machinery (large gears along walls)
    for gx in [150, w-150]:
        for gy in [floor_y-100, floor_y-250, floor_y-400]:
            teeth = 8
            outer_r = 45
            inner_r = 35
            gear_points = []
            for i in range(teeth * 2):
                angle = (360 / (teeth * 2)) * i
                rad = math.radians(angle)
                r = outer_r if i % 2 == 0 else inner_r
                x = gx + r * math.cos(rad)
                y = gy + r * math.sin(rad)
                gear_points.append((x, y))
            draw.polygon(gear_points, fill=(140, 110, 60, 255), outline=(184, 134, 11, 255), width=2)
            draw.ellipse([gx-8, gy-8, gx+8, gy+8], fill=(120, 95, 50, 255))
    
    # Central gear garden (interlocking gears)
    center_x, center_y = w//2, floor_y-200
    gear_configs = [
        (0, 0, 60, 10),
        (100, 0, 50, 8),
        (-90, 40, 40, 6),
        (50, -70, 35, 6),
    ]
    for dx, dy, radius, teeth in gear_configs:
        gx, gy = center_x+dx, center_y+dy
        outer_r = radius
        inner_r = radius - 10
        gear_points = []
        for i in range(teeth * 2):
            angle = (360 / (teeth * 2)) * i
            rad = math.radians(angle)
            r = outer_r if i % 2 == 0 else inner_r
            x = gx + r * math.cos(rad)
            y = gy + r * math.sin(rad)
            gear_points.append((x, y))
        draw.polygon(gear_points, fill=(160, 130, 80, 255), outline=(200, 170, 110, 255), width=2)
        draw.ellipse([gx-6, gy-6, gx+6, gy+6], fill=(184, 134, 11, 255))
    
    # Workbenches
    for wx in [400, w-400]:
        draw.rectangle([wx-60, floor_y-40, wx+60, floor_y], fill=(100, 80, 60, 255), outline=(130, 110, 80, 255), width=2)
        # Tools on bench
        draw.rectangle([wx-30, floor_y-50, wx-10, floor_y-35], fill=(180, 180, 190, 255), outline=(150, 150, 160, 255), width=1)
    
    # Steam pipes
    for px in [250, w-250]:
        draw.rectangle([px-6, 0, px+6, floor_y], fill=(80, 65, 45, 255), outline=(120, 100, 70, 255), width=1)
    
    # Clocktower mechanism visible through window
    draw.rectangle([w//2-80, 50, w//2+80, 200], fill=(20, 18, 25, 255), outline=(80, 70, 60, 255), width=3)
    # Gears visible through window
    for gx, gy, r in [(w//2, 125, 30), (w//2-40, 125, 20), (w//2+40, 125, 20)]:
        draw.ellipse([gx-r, gy-r, gx+r, gy+r], fill=(140, 110, 60, 200), outline=(184, 134, 11, 255), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_bg_echoes(output_path, size=(2200, 1600)):
    """College of Echoes — Undead library, spectral students, stacks of books"""
    ensure_dir(output_path)
    w, h = size
    img = Image.new('RGBA', size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    
    # Dark library interior
    draw.rectangle([0, 0, w, h], fill=(20, 20, 25, 255))
    
    # Bookshelves (walls of books)
    shelf_y = h * 2 // 3
    for sx in [50, w-300, w//2-150]:
        for row in range(5):
            y = shelf_y - row * 60
            # Shelf board
            draw.rectangle([sx, y, sx+250, y+10], fill=(50, 45, 40, 255), outline=(70, 65, 60, 255), width=1)
            # Books on shelf
            for bx in range(sx+5, sx+240, 18):
                book_h = random.randint(25, 45)
                book_color = random.choice([
                    (80, 40, 40), (40, 60, 80), (60, 60, 40), (70, 50, 70),
                    (50, 50, 60), (90, 70, 40), (40, 40, 60)
                ])
                draw.rectangle([bx, y-book_h, bx+14, y], fill=(*book_color, 255), outline=(90, 85, 80, 255), width=1)
    
    # Floor — dark carpet
    draw.rectangle([0, shelf_y, w, h], fill=(35, 32, 38, 255))
    for x in range(0, w, 40):
        draw.line([(x, shelf_y), (x, h)], fill=(45, 42, 50, 255), width=1)
    
    # Reading tables
    for tx in [w//3, w*2//3]:
        draw.rectangle([tx-50, shelf_y-30, tx+50, shelf_y], fill=(60, 55, 50, 255), outline=(80, 75, 70, 255), width=2)
        # Open book on table
        draw.polygon([(tx-15, shelf_y-20), (tx, shelf_y-25), (tx+15, shelf_y-20)], fill=(150, 140, 120, 255), outline=(120, 110, 100, 255), width=1)
    
    # Spectral students (ghostly figures)
    for _ in range(5):
        sx = random.randint(200, w-200)
        sy = random.randint(shelf_y-150, shelf_y-20)
        # Ghostly body
        draw.ellipse([sx-12, sy-30, sx+12, sy], fill=(100, 120, 140, 80), outline=(120, 150, 180, 120), width=1)
        # Ghostly head
        draw.ellipse([sx-8, sy-48, sx+8, sy-32], fill=(110, 140, 170, 100), outline=(140, 180, 220, 150), width=1)
        # Eyes
        draw.ellipse([sx-4, sy-42, sx-1, sy-38], fill=(200, 230, 255, 200))
        draw.ellipse([sx+1, sy-42, sx+4, sy-38], fill=(200, 230, 255, 200))
    
    # Toxic ink vats (glowing green)
    for vx in [150, w-150]:
        vy = shelf_y - 20
        draw.rectangle([vx-25, vy-60, vx+25, vy], fill=(30, 50, 30, 255), outline=(50, 80, 50, 255), width=2)
        # Ink surface (glowing)
        draw.ellipse([vx-20, vy-65, vx+20, vy-55], fill=(60, 180, 60, 200), outline=(80, 220, 80, 255), width=2)
        # Toxic fumes
        for _ in range(3):
            fx = vx + random.randint(-15, 15)
            fy = vy - 70 - random.randint(0, 20)
            draw.ellipse([fx-6, fy-3, fx+6, fy+3], fill=(80, 200, 80, 100), outline=(100, 255, 100, 150), width=1)
    
    # Chandelier (dim, spectral light)
    cx, cy = w//2, 80
    draw.line([(cx, 0), (cx, cy)], fill=(100, 100, 90, 255), width=2)
    draw.ellipse([cx-20, cy, cx+20, cy+20], fill=(200, 200, 150, 80), outline=(220, 220, 180, 120), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_bg_aether(output_path, size=(2000, 1400)):
    """College of Aether — closed/renovation, boarded doors, steam leaks"""
    ensure_dir(output_path)
    w, h = size
    img = Image.new('RGBA', size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    
    # Dark, abandoned interior
    draw.rectangle([0, 0, w, h], fill=(20, 18, 22, 255))
    
    # Boarded-up doors (center)
    door_x = w // 2
    door_y = h * 2 // 3
    # Door frame
    draw.rectangle([door_x-60, door_y-120, door_x+60, door_y], fill=(50, 45, 40, 255), outline=(70, 65, 60, 255), width=2)
    # Boards across door
    for by in range(door_y-110, door_y, 25):
        draw.rectangle([door_x-55, by, door_x+55, by+15], fill=(40, 35, 30, 255), outline=(60, 55, 50, 255), width=1)
    # Hazard tape
    for i in range(3):
        y1 = door_y - 100 + i * 35
        y2 = y1 + 25
        # Diagonal stripes
        for sx in range(door_x-50, door_x+50, 15):
            color = (180, 160, 40, 255) if (sx//15) % 2 == 0 else (40, 40, 40, 255)
            draw.rectangle([sx, y1, sx+10, y2], fill=color, outline=(150, 130, 30, 255), width=1)
    # Sign: "CLOSED - RENOVATION"
    font = get_font(10)
    draw.rectangle([door_x-70, door_y-150, door_x+70, door_y-120], fill=(180, 160, 40, 255), outline=(200, 180, 60, 255), width=2)
    bbox = draw.textbbox((0, 0), "RENOVATION", font=font)
    tw = bbox[2] - bbox[0]
    draw.text((door_x-tw//2, door_y-145), "RENOVATION", fill=(40, 35, 20, 255), font=font)
    
    # Steam leaks from pipes
    for px in [200, w-200, w//2-100, w//2+100]:
        draw_steam_leak(draw, px, h*2//3-50)
    
    # Cracked foundation (bottom center)
    crack_x = w // 2
    crack_y = h - 50
    draw.polygon([
        (crack_x-40, crack_y), (crack_x+40, crack_y),
        (crack_x+30, crack_y+30), (crack_x-30, crack_y+30)
    ], fill=(25, 20, 30, 255), outline=(50, 40, 60, 255), width=2)
    # Glimpse of floor 5 through crack (blue sky peek)
    draw.ellipse([crack_x-15, crack_y+5, crack_x+15, crack_y+25], fill=(60, 80, 120, 200), outline=(80, 120, 180, 255), width=1)
    
    # Scattered debris
    for _ in range(15):
        dx = random.randint(50, w-50)
        dy = random.randint(h*2//3, h-30)
        draw.rectangle([dx-5, dy-3, dx+5, dy+3], fill=(45, 40, 35, 255), outline=(55, 50, 45, 255), width=1)
    
    # Dust particles in air
    for _ in range(30):
        dx = random.randint(0, w)
        dy = random.randint(0, h*2//3)
        draw.ellipse([dx-1, dy-1, dx+1, dy+1], fill=(150, 140, 120, 80))
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_bg_pacts(output_path, size=(2000, 1400)):
    """College of Pacts — locked Demonology, heavy brass doors, summoning circles"""
    ensure_dir(output_path)
    w, h = size
    img = Image.new('RGBA', size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    
    # Dark corridor
    draw.rectangle([0, 0, w, h], fill=(18, 15, 20, 255))
    
    # Heavy brass doors (center)
    door_x = w // 2
    door_y = h * 2 // 3
    # Door frame (ornate)
    draw.rectangle([door_x-100, door_y-180, door_x+100, door_y], fill=(40, 35, 30, 255), outline=(100, 80, 50, 255), width=3)
    # Double doors
    draw.rectangle([door_x-95, door_y-175, door_x-5, door_y], fill=(60, 50, 40, 255), outline=(120, 100, 70, 255), width=2)
    draw.rectangle([door_x+5, door_y-175, door_x+95, door_y], fill=(60, 50, 40, 255), outline=(120, 100, 70, 255), width=2)
    # Brass studs
    for sy in range(door_y-160, door_y, 30):
        for sx in [door_x-80, door_x-50, door_x-20, door_x+20, door_x+50, door_x+80]:
            draw.ellipse([sx-4, sy-4, sx+4, sy+4], fill=(180, 150, 80, 255), outline=(220, 190, 120, 255), width=1)
    # Demon seal on door
    draw.ellipse([door_x-30, door_y-120, door_x+30, door_y-60], fill=(80, 20, 20, 200), outline=(150, 30, 30, 255), width=2)
    
    # Windows (left and right of door)
    for wx in [door_x-150, door_x+150]:
        draw.rectangle([wx-30, door_y-150, wx+30, door_y-50], fill=(15, 10, 15, 255), outline=(80, 60, 50, 255), width=2)
        # Summoning circle visible through window
        draw.ellipse([wx-20, door_y-130, wx+20, door_y-70], fill=(80, 10, 10, 150), outline=(150, 20, 20, 200), width=2)
        # Symbols in circle
        for angle in [0, 72, 144, 216, 288]:
            rad = math.radians(angle)
            sx = wx + 12 * math.cos(rad)
            sy = door_y - 100 + 12 * math.sin(rad)
            draw.ellipse([sx-2, sy-2, sx+2, sy+2], fill=(200, 50, 50, 255))
        # Red glow
        draw.ellipse([wx-25, door_y-135, wx+25, door_y-65], fill=(120, 20, 20, 60), outline=(180, 30, 30, 100), width=1)
    
    # Warning signs
    font = get_font(8)
    for sx, sy in [(door_x-140, door_y-200), (door_x+80, door_y-200)]:
        draw.rectangle([sx, sy, sx+60, sy+25], fill=(100, 20, 20, 255), outline=(150, 30, 30, 255), width=2)
        bbox = draw.textbbox((0, 0), "DANGER", font=font)
        tw = bbox[2] - bbox[0]
        draw.text((sx+30-tw//2, sy+5), "DANGER", fill=(255, 200, 200, 255), font=font)
    
    # Torches on walls
    for tx in [100, w-100]:
        draw.rectangle([tx-3, door_y-120, tx+3, door_y], fill=(60, 50, 40, 255), outline=(80, 70, 60, 255), width=1)
        # Flame
        draw.polygon([(tx, door_y-140), (tx-8, door_y-120), (tx+8, door_y-120)], fill=(200, 100, 30, 255), outline=(255, 150, 50, 255), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_bg_undercroft(output_path, size=(1800, 1200)):
    """The Undercroft — steam tunnels, maintenance shafts, narrow pipes"""
    ensure_dir(output_path)
    w, h = size
    img = Image.new('RGBA', size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    
    # Dark tunnel
    draw.rectangle([0, 0, w, h], fill=(15, 15, 18, 255))
    
    # Ceiling pipes
    for y in [30, 70, 110]:
        draw.rectangle([0, y, w, y+15], fill=(50, 50, 60, 255), outline=(70, 70, 80, 255), width=1)
        # Pipe joints
        for x in [200, 600, 1000, 1400]:
            draw.ellipse([x-8, y-3, x+8, y+18], fill=(70, 70, 80, 255), outline=(90, 90, 100, 255), width=1)
    
    # Floor (metal grating)
    floor_y = h * 3 // 4
    draw.rectangle([0, floor_y, w, h], fill=(35, 35, 40, 255))
    for x in range(0, w, 20):
        draw.line([(x, floor_y), (x, h)], fill=(50, 50, 55, 255), width=1)
    
    # Steam leaks
    for px in [300, 700, 1100, 1500]:
        draw_steam_leak(draw, px, floor_y-30)
    
    # Maintenance shafts (side walls)
    for sx in [100, w-150]:
        draw.rectangle([sx, 150, sx+50, floor_y], fill=(25, 25, 30, 255), outline=(50, 50, 60, 255), width=2)
        # Ladder rungs
        for ly in range(180, floor_y-20, 30):
            draw.line([(sx+5, ly), (sx+45, ly)], fill=(80, 80, 90, 255), width=2)
    
    # Control valves
    for vx in [400, w-400]:
        draw.ellipse([vx-15, floor_y-80, vx+15, floor_y-50], fill=(80, 70, 60, 255), outline=(120, 100, 80, 255), width=2)
        draw.line([(vx, floor_y-50), (vx, floor_y-30)], fill=(100, 90, 80, 255), width=3)
    
    # Narrow crawlspace (background)
    draw.rectangle([w//2-40, 130, w//2+40, 180], fill=(20, 20, 25, 255), outline=(40, 40, 50, 255), width=2)
    
    # Water puddles (reflective)
    for _ in range(4):
        px = random.randint(200, w-200)
        py = random.randint(floor_y+10, h-20)
        draw.ellipse([px-20, py-5, px+20, py+5], fill=(30, 35, 45, 200), outline=(50, 60, 80, 255), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_bg_clocktower_apex(output_path, size=(2400, 1600)):
    """Clocktower Apex — boss arena, circular chamber, glass dome, moonlight, bells"""
    ensure_dir(output_path)
    w, h = size
    img = Image.new('RGBA', size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    
    # Night sky visible through dome
    draw_moonlight_gradient(draw, w, h, (10, 12, 25), (20, 22, 35), h)
    draw_moon(draw, w*3//4, h//6, 40)
    
    # Stars
    for _ in range(80):
        sx = random.randint(0, w)
        sy = random.randint(0, h//2)
        br = random.randint(150, 255)
        draw.ellipse([sx-1, sy-1, sx+1, sy+1], fill=(br, br, 240, 255))
    
    # Glass dome (arched structure)
    dome_center = w // 2
    dome_top = 50
    dome_bottom = h * 2 // 3
    dome_width = w // 2 + 100
    
    # Dome glass panes
    for i in range(-5, 6):
        x = dome_center + i * (dome_width // 5)
        y_top = dome_top + abs(i) * 30
        draw.polygon([
            (x - dome_width//10, y_top), (x + dome_width//10, y_top),
            (x + dome_width//12, dome_bottom), (x - dome_width//12, dome_bottom)
        ], fill=(40, 50, 70, 80), outline=(80, 100, 140, 150), width=2)
    
    # Dome frame
    for i in range(-6, 7):
        x = dome_center + i * (dome_width // 6)
        y_top = dome_top + abs(i) * 25
        draw.line([(x, y_top), (x, dome_bottom)], fill=(100, 100, 110, 200), width=3)
    
    # Floor — circular pattern
    floor_y = dome_bottom
    center_y = h * 3 // 4
    for ring in range(6, 0, -1):
        r = ring * 150
        color_val = 30 + ring * 5
        draw.ellipse([dome_center-r, center_y-r//2, dome_center+r, center_y+r//2],
                     fill=(color_val, color_val, color_val+5, 255),
                     outline=(color_val+15, color_val+15, color_val+20, 255), width=2)
    
    # Central clock mechanism (boss platform)
    draw.ellipse([dome_center-80, center_y-40, dome_center+80, center_y+40],
                 fill=(50, 50, 55, 255), outline=(120, 120, 130, 255), width=3)
    # Central gear
    teeth = 12
    outer_r = 50
    inner_r = 40
    gear_points = []
    for i in range(teeth * 2):
        angle = (360 / (teeth * 2)) * i
        rad = math.radians(angle)
        r = outer_r if i % 2 == 0 else inner_r
        x = dome_center + r * math.cos(rad)
        y = center_y + r * math.sin(rad) * 0.5
        gear_points.append((x, y))
    draw.polygon(gear_points, fill=(140, 110, 60, 255), outline=(184, 134, 11, 255), width=2)
    
    # Bells around the dome
    for angle in [30, 90, 150, 210, 270, 330]:
        rad = math.radians(angle)
        bx = dome_center + int(350 * math.cos(rad))
        by = dome_bottom - 100 + int(50 * math.sin(rad))
        draw.ellipse([bx-15, by-20, bx+15, by+20], fill=(180, 150, 80, 255), outline=(220, 190, 120, 255), width=2)
        # Bell clapper
        draw.line([(bx, by+15), (bx, by+30)], fill=(120, 100, 60, 255), width=2)
    
    # Moonlight beams (stronger in arena)
    for mx in [dome_center-300, dome_center, dome_center+300]:
        for my in range(floor_y, h, 15):
            alpha = int(25 + 15 * math.sin(mx * 0.01 + my * 0.02))
            draw.line([(mx-40, my), (mx+40, my)], fill=(200, 200, 240, alpha), width=3)
    
    img.save(output_path)
    print(f"Created: {output_path}")

# ===================================================================
# TILES
# ===================================================================

def create_hex_tile(draw, center, radius, color, outline_color=(255,255,255,200), width=2):
    points = []
    for i in range(6):
        angle = math.radians(60 * i - 30)
        x = center[0] + radius * math.cos(angle)
        y = center[1] + radius * math.sin(angle)
        points.append((x, y))
    draw.polygon(points, fill=color, outline=outline_color, width=width)
    return points

def create_tile_courtyard_stone(output_path, size=64):
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    center = (size//2, size//2)
    radius = size//2 - 2
    
    # Moonlit stone
    create_hex_tile(draw, center, radius, (60, 60, 75, 220), (100, 100, 120, 255), 2)
    
    # Stone texture lines
    for i in range(-1, 2):
        y = center[1] + i * 10
        draw.line([(center[0]-radius+6, y), (center[0]+radius-6, y)], fill=(50, 50, 60, 255), width=1)
    
    # Moonlight shimmer
    draw.ellipse([center[0]-3, center[1]-3, center[0]+3, center[1]+3], fill=(180, 180, 220, 150))
    
    font = get_font(8)
    bbox = draw.textbbox((0, 0), "STONE", font=font)
    text_width = bbox[2] - bbox[0]
    draw.text(((size - text_width)//2, size//2 - 4), "STONE", fill=(180, 180, 200, 200), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_tile_library_carpet(output_path, size=64):
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    center = (size//2, size//2)
    radius = size//2 - 2
    
    # Dark carpet
    create_hex_tile(draw, center, radius, (45, 35, 50, 220), (70, 60, 80, 255), 2)
    
    # Carpet pattern
    for i in range(3):
        inset = radius * 0.2 * (i + 1)
        inner_points = []
        for j in range(6):
            angle = math.radians(60 * j - 30)
            x = center[0] + inset * math.cos(angle)
            y = center[1] + inset * math.sin(angle)
            inner_points.append((x, y))
        color = (55, 45, 60, 255) if i % 2 == 0 else (40, 30, 45, 255)
        draw.polygon(inner_points, fill=color, outline=(60, 50, 70, 255), width=1)
    
    font = get_font(8)
    bbox = draw.textbbox((0, 0), "CARPET", font=font)
    text_width = bbox[2] - bbox[0]
    draw.text(((size - text_width)//2, size//2 - 4), "CARPET", fill=(150, 140, 160, 200), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_tile_tunnel_brick(output_path, size=64):
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    center = (size//2, size//2)
    radius = size//2 - 2
    
    # Brick tunnel
    create_hex_tile(draw, center, radius, (55, 45, 40, 220), (80, 70, 65, 255), 2)
    
    # Brick lines
    for i in range(-1, 2):
        y = center[1] + i * 12
        offset = 6 if i % 2 == 0 else 0
        draw.line([(center[0]-radius+8+offset, y), (center[0]+radius-8+offset, y)], fill=(65, 55, 50, 255), width=1)
    
    font = get_font(8)
    bbox = draw.textbbox((0, 0), "BRICK", font=font)
    text_width = bbox[2] - bbox[0]
    draw.text(((size - text_width)//2, size//2 - 4), "BRICK", fill=(160, 150, 140, 200), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

# ===================================================================
# ENVIRONMENTAL SPRITES
# ===================================================================

def create_moonlight_beam(output_path, size=(128, 256)):
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Shifting moonlight beam (vertical cone)
    for y in range(0, size[1], 4):
        width = int(20 + y * 0.3)
        alpha = int(40 - y * 0.05)
        cx = size[0] // 2 + int(5 * math.sin(y * 0.05))
        draw.ellipse([cx-width//2, y, cx+width//2, y+8], fill=(200, 200, 240, alpha), outline=(220, 220, 255, alpha//2), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_clocktower_bell(output_path, size=(64, 96)):
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Brass bell
    draw.ellipse([8, 20, 56, 76], fill=(180, 150, 80, 255), outline=(220, 190, 120, 255), width=2)
    # Bell top
    draw.rectangle([20, 10, 44, 25], fill=(160, 130, 70, 255), outline=(200, 170, 100, 255), width=1)
    # Clapper
    draw.line([(32, 70), (32, 88)], fill=(120, 100, 60, 255), width=3)
    # Mount ring
    draw.ellipse([24, 4, 40, 16], fill=(140, 120, 70, 255), outline=(180, 160, 100, 255), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_statue_construct(output_path, size=(96, 128)):
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Pedestal
    draw.rectangle([20, 100, 76, 128], fill=(80, 80, 90, 255), outline=(100, 100, 110, 255), width=2)
    
    # Construct statue body (blocky)
    draw.rectangle([28, 50, 68, 100], fill=(100, 100, 115, 255), outline=(120, 120, 135, 255), width=2)
    # Head
    draw.rectangle([32, 20, 64, 50], fill=(110, 110, 125, 255), outline=(130, 130, 145, 255), width=2)
    # Eyes (glowing faintly)
    draw.ellipse([38, 32, 44, 38], fill=(150, 180, 220, 200))
    draw.ellipse([52, 32, 58, 38], fill=(150, 180, 220, 200))
    # Arms
    draw.rectangle([18, 55, 28, 85], fill=(95, 95, 110, 255), outline=(115, 115, 130, 255), width=1)
    draw.rectangle([68, 55, 78, 85], fill=(95, 95, 110, 255), outline=(115, 115, 130, 255), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_book_stack(output_path, size=(64, 80)):
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    colors = [(80, 40, 40), (40, 60, 80), (60, 60, 40), (70, 50, 70)]
    for i, color in enumerate(colors):
        y = 60 - i * 14
        w_book = 50 - i * 4
        x = (64 - w_book) // 2
        draw.rectangle([x, y, x+w_book, y+12], fill=(*color, 255), outline=(90, 85, 80, 255), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_ink_vat(output_path, size=(64, 96)):
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Vat body
    draw.rectangle([12, 24, 52, 88], fill=(30, 50, 30, 255), outline=(50, 80, 50, 255), width=2)
    # Ink surface (glowing green)
    draw.ellipse([14, 16, 50, 32], fill=(60, 180, 60, 200), outline=(80, 220, 80, 255), width=2)
    # Toxic fumes
    for _ in range(4):
        fx = 32 + random.randint(-12, 12)
        fy = 10 - random.randint(0, 15)
        draw.ellipse([fx-5, fy-3, fx+5, fy+3], fill=(80, 200, 80, 120), outline=(100, 255, 100, 150), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_lecture_desk(output_path, size=(128, 80)):
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Desk body
    draw.rectangle([8, 30, 120, 72], fill=(80, 70, 55, 255), outline=(110, 95, 75, 255), width=2)
    # Desk top
    draw.rectangle([4, 20, 124, 35], fill=(100, 85, 65, 255), outline=(130, 115, 90, 255), width=2)
    # Lectern
    draw.rectangle([40, 4, 88, 25], fill=(90, 75, 55, 255), outline=(120, 105, 80, 255), width=2)
    # Open book on lectern
    draw.polygon([(52, 8), (64, 4), (76, 8)], fill=(150, 140, 120, 255), outline=(120, 110, 100, 255), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_summoning_circle(output_path, size=(96, 96)):
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = 48
    # Outer circle
    draw.ellipse([4, 4, 92, 92], fill=(80, 10, 10, 150), outline=(150, 20, 20, 255), width=2)
    # Inner circle
    draw.ellipse([20, 20, 76, 76], fill=(60, 5, 5, 180), outline=(120, 15, 15, 255), width=2)
    # Symbols
    for angle in [0, 60, 120, 180, 240, 300]:
        rad = math.radians(angle)
        sx = center + 28 * math.cos(rad)
        sy = center + 28 * math.sin(rad)
        draw.ellipse([sx-4, sy-4, sx+4, sy+4], fill=(200, 50, 50, 255), outline=(255, 80, 80, 255), width=1)
    # Central pentagram (simplified)
    for i in range(5):
        angle1 = math.radians(72 * i - 90)
        angle2 = math.radians(72 * (i + 2) - 90)
        r = 22
        x1 = center + r * math.cos(angle1)
        y1 = center + r * math.sin(angle1)
        x2 = center + r * math.cos(angle2)
        y2 = center + r * math.sin(angle2)
        draw.line([(x1, y1), (x2, y2)], fill=(200, 40, 40, 200), width=2)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_steam_pipe(output_path, size=(32, 128)):
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Pipe body
    draw.rectangle([4, 0, 28, 128], fill=(60, 60, 75, 255), outline=(90, 90, 110, 255), width=2)
    # Pipe joints
    for y in [20, 60, 100]:
        draw.ellipse([2, y-4, 30, y+4], fill=(80, 80, 95, 255), outline=(110, 110, 125, 255), width=1)
    # Steam leak at top
    for _ in range(3):
        fx = 16 + random.randint(-5, 5)
        fy = -5 - random.randint(0, 15)
        draw.ellipse([fx-4, fy-2, fx+4, fy+2], fill=(180, 180, 200, 80), outline=(200, 200, 220, 100), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_dean_door(output_path, size=(128, 192)):
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Heavy door frame
    draw.rectangle([4, 4, 124, 188], fill=(50, 45, 40, 255), outline=(100, 80, 50, 255), width=3)
    # Double doors
    draw.rectangle([8, 8, 60, 184], fill=(60, 50, 40, 255), outline=(120, 100, 70, 255), width=2)
    draw.rectangle([68, 8, 120, 184], fill=(60, 50, 40, 255), outline=(120, 100, 70, 255), width=2)
    # Brass studs
    for y in range(20, 180, 25):
        for x in [22, 46, 82, 106]:
            draw.ellipse([x-4, y-4, x+4, y+4], fill=(180, 150, 80, 255), outline=(220, 190, 120, 255), width=1)
    # Seal
    draw.ellipse([44, 60, 84, 100], fill=(80, 20, 20, 200), outline=(150, 30, 30, 255), width=2)
    
    img.save(output_path)
    print(f"Created: {output_path}")

# ===================================================================
# ENEMY SPRITES
# ===================================================================

def create_enemy_sprite(name, faction, frame_type, output_path, size=64):
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    colors = {
        'construct': (160, 130, 90),      # Brass
        'undead': (120, 140, 160),        # Spectral blue-gray
        'goblin': (80, 140, 80),          # Goblin green
        'aberration': (140, 60, 180),     # Purple
    }
    
    base_color = colors.get(faction.lower(), (100, 100, 100))
    
    if frame_type == 'idle':
        offset_y = 0
        intensity = 1.0
    elif frame_type == 'attack':
        offset_y = -4
        intensity = 1.3
    elif frame_type == 'damage':
        offset_y = 0
        intensity = 0.6
        base_color = (255, 100, 100)
    elif frame_type == 'death':
        offset_y = 6
        intensity = 0.4
        base_color = (50, 50, 55)
    else:
        offset_y = 0
        intensity = 1.0
    
    center = size // 2
    body_color = tuple(min(255, int(c * intensity)) for c in base_color)
    
    # Body shape based on enemy type
    if "drone" in name.lower() or "calibration" in name.lower():
        # Small flying drone
        draw.ellipse([center-15, center-10+offset_y, center+15, center+10+offset_y],
                     fill=body_color, outline=(255, 255, 255, 150), width=2)
        # Rotor
        draw.line([(center-20, center-15+offset_y), (center+20, center-15+offset_y)],
                  fill=(180, 180, 190, 255), width=2)
        # Eye (scanner)
        draw.ellipse([center-5, center-5+offset_y, center+5, center+1+offset_y], fill=(200, 50, 50, 255))
    
    elif "core" in name.lower() and "logic" in name.lower():
        # Floating logic core — crystalline
        draw.polygon([(center, center-20+offset_y), (center-18, center+5+offset_y),
                      (center+18, center+5+offset_y)],
                     fill=body_color, outline=(255, 255, 255, 180), width=2)
        draw.polygon([(center, center+15+offset_y), (center-18, center-5+offset_y),
                      (center+18, center-5+offset_y)],
                     fill=body_color, outline=(255, 255, 255, 180), width=2)
        # Core glow
        draw.ellipse([center-6, center-6+offset_y, center+6, center+6+offset_y],
                     fill=(min(255, body_color[0]+60), min(255, body_color[1]+60), min(255, body_color[2]+60)),
                     outline=(255, 255, 255, 255), width=1)
    
    elif "enforcer" in name.lower() or "brass" in name.lower():
        # Large brass enforcer — armored
        draw.rectangle([center-18, center-22+offset_y, center+18, center+18+offset_y],
                       fill=body_color, outline=(255, 255, 255, 180), width=2)
        # Shoulder pads
        draw.rectangle([center-22, center-18+offset_y, center-18, center-8+offset_y],
                       fill=(140, 110, 60, 255), outline=(184, 134, 11, 255), width=1)
        draw.rectangle([center+18, center-18+offset_y, center+22, center-8+offset_y],
                       fill=(140, 110, 60, 255), outline=(184, 134, 11, 255), width=1)
        # Helmet visor
        draw.rectangle([center-10, center-16+offset_y, center+10, center-6+offset_y],
                       fill=(60, 50, 40, 255), outline=(100, 80, 60, 255), width=1)
        # Visor glow
        draw.ellipse([center-4, center-13+offset_y, center+4, center-9+offset_y], fill=(200, 180, 50, 255))
    
    elif "forgotten" in name.lower():
        # Undead student — slumped, decaying
        draw.ellipse([center-14, center-12+offset_y, center+14, center+14+offset_y],
                     fill=body_color, outline=(255, 255, 255, 120), width=2)
        # Sunken eyes
        draw.ellipse([center-8, center-6+offset_y, center-3, center-1+offset_y], fill=(40, 40, 60, 255))
        draw.ellipse([center+3, center-6+offset_y, center+8, center-1+offset_y], fill=(40, 40, 60, 255))
        # Tattered cloak
        draw.polygon([(center-14, center+10+offset_y), (center-20, center+28+offset_y), (center-8, center+20+offset_y)],
                     fill=(80, 90, 110, 200), outline=(100, 120, 150, 150), width=1)
    
    elif "remembers" in name.lower() or "one_who" in name.lower():
        # Undead professor — tall, knowing
        draw.rectangle([center-10, center-24+offset_y, center+10, center+16+offset_y],
                       fill=body_color, outline=(255, 255, 255, 150), width=2)
        # Robe bottom
        draw.polygon([(center-10, center+16+offset_y), (center-16, center+30+offset_y), (center+16, center+30+offset_y), (center+10, center+16+offset_y)],
                     fill=body_color, outline=(255, 255, 255, 120), width=1)
        # Spectral eyes (bright)
        draw.ellipse([center-6, center-16+offset_y, center-1, center-11+offset_y], fill=(150, 200, 255, 255))
        draw.ellipse([center+1, center-16+offset_y, center+6, center-11+offset_y], fill=(150, 200, 255, 255))
        # Book in hand
        draw.rectangle([center+12, center+5+offset_y, center+22, center+18+offset_y],
                       fill=(80, 60, 40, 255), outline=(100, 80, 60, 255), width=1)
    
    elif "marrow" in name.lower() or "priest" in name.lower():
        # Marrow priest — skeletal, ceremonial
        draw.rectangle([center-12, center-20+offset_y, center+12, center+20+offset_y],
                       fill=body_color, outline=(255, 255, 255, 150), width=2)
        # Skull face
        draw.ellipse([center-8, center-22+offset_y, center+8, center-10+offset_y],
                     fill=(180, 190, 200, 255), outline=(200, 210, 220, 255), width=1)
        # Hollow eyes
        draw.ellipse([center-5, center-18+offset_y, center-1, center-14+offset_y], fill=(20, 20, 30, 255))
        draw.ellipse([center+1, center-18+offset_y, center+5, center-14+offset_y], fill=(20, 20, 30, 255))
        # Staff
        draw.line([(center+18, center-10+offset_y), (center+18, center+30+offset_y)], fill=(140, 120, 80, 255), width=3)
        draw.ellipse([center+14, center-18+offset_y, center+22, center-10+offset_y], fill=(60, 180, 60, 200), outline=(80, 220, 80, 255), width=1)
    
    elif "dean" in name.lower():
        # The Dean — boss, imposing administrator
        if frame_type == 'death':
            # Collapsed
            draw.rectangle([center-20, center+5+offset_y, center+20, center+25+offset_y],
                           fill=body_color, outline=(100, 100, 110, 150), width=2)
        else:
            # Towering figure
            draw.rectangle([center-18, center-30+offset_y, center+18, center+20+offset_y],
                           fill=body_color, outline=(255, 255, 255, 200), width=3)
            # Shoulders
            draw.rectangle([center-24, center-20+offset_y, center-18, center-10+offset_y],
                           fill=(140, 110, 60, 255), outline=(184, 134, 11, 255), width=2)
            draw.rectangle([center+18, center-20+offset_y, center+24, center-10+offset_y],
                           fill=(140, 110, 60, 255), outline=(184, 134, 11, 255), width=2)
            # Crown/headpiece
            draw.polygon([(center, center-45+offset_y), (center-12, center-30+offset_y), (center+12, center-30+offset_y)],
                         fill=(180, 150, 80, 255), outline=(220, 190, 120, 255), width=2)
            # Eyes (administrative glare)
            eye_color = (200, 180, 100) if frame_type == 'idle' else (255, 100, 100) if frame_type == 'damage' else (255, 255, 255)
            draw.ellipse([center-8, center-22+offset_y, center-2, center-16+offset_y], fill=eye_color)
            draw.ellipse([center+2, center-22+offset_y, center+8, center-16+offset_y], fill=eye_color)
            # Robe
            draw.polygon([(center-18, center+20+offset_y), (center-22, center+32+offset_y), (center+22, center+32+offset_y), (center+18, center+20+offset_y)],
                         fill=(60, 55, 70, 255), outline=(90, 85, 100, 255), width=2)
    
    else:
        # Default humanoid
        draw.ellipse([center-12, center-12+offset_y, center+12, center+12+offset_y],
                     fill=body_color, outline=(255, 255, 255, 150), width=2)
    
    # Eyes (unless death)
    if frame_type != 'death':
        eye_colors = {
            'construct': (255, 200, 50),
            'undead': (150, 200, 255),
            'goblin': (255, 255, 100),
            'aberration': (200, 100, 255)
        }
        eye_color = eye_colors.get(faction.lower(), (255, 255, 255))
        eye_y = center - 8 + offset_y
        eye_offset = 7
        if "dean" in name.lower():
            pass  # Dean has custom eyes above
        else:
            draw.ellipse([center-eye_offset-3, eye_y-3, center-eye_offset+3, eye_y+3], fill=eye_color)
            draw.ellipse([center+eye_offset-3, eye_y-3, center+eye_offset+3, eye_y+3], fill=eye_color)
    else:
        # Dead eyes (X marks)
        eye_y = center - 8 + offset_y
        eye_offset = 7
        draw.line([(center-eye_offset-3, eye_y-3), (center-eye_offset+3, eye_y+3)], fill=(80, 80, 80, 255), width=2)
        draw.line([(center-eye_offset-3, eye_y+3), (center-eye_offset+3, eye_y-3)], fill=(80, 80, 80, 255), width=2)
        draw.line([(center+eye_offset-3, eye_y-3), (center+eye_offset+3, eye_y+3)], fill=(80, 80, 80, 255), width=2)
        draw.line([(center+eye_offset-3, eye_y+3), (center+eye_offset+3, eye_y-3)], fill=(80, 80, 80, 255), width=2)
    
    # Faction symbol
    font = get_font(8)
    symbol = {'construct': 'C', 'undead': 'U', 'goblin': 'G', 'aberration': 'A', 'demon': 'D'}.get(faction.lower(), '?')
    bbox = draw.textbbox((0, 0), symbol, font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (size - text_width) // 2
    text_y = center + 12 + offset_y
    draw.text((text_x, text_y), symbol, fill=(255, 255, 255, 180), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

# ===================================================================
# NPC / ITEM SPRITES
# ===================================================================

def create_npc_registrar(output_path, size=(80, 112)):
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Construct registrar — brass automaton at desk
    center = 40
    # Body (behind desk)
    draw.rectangle([center-20, 30, center+20, 70], fill=(140, 120, 90, 255), outline=(180, 160, 120, 255), width=2)
    # Head
    draw.rectangle([center-14, 10, center+14, 32], fill=(160, 140, 110, 255), outline=(200, 180, 150, 255), width=2)
    # Eyes (glowing)
    draw.ellipse([center-8, 18, center-2, 24], fill=(200, 180, 50, 255))
    draw.ellipse([center+2, 18, center+8, 24], fill=(200, 180, 50, 255))
    # Desk
    draw.rectangle([4, 60, 76, 90], fill=(100, 80, 60, 255), outline=(130, 110, 80, 255), width=2)
    # Papers on desk
    draw.rectangle([center-15, 52, center+15, 62], fill=(200, 190, 170, 255), outline=(170, 160, 140, 255), width=1)
    # Stamp
    draw.rectangle([center+18, 50, center+28, 65], fill=(80, 60, 40, 255), outline=(110, 90, 60, 255), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_npc_sneak_thief(output_path, size=(64, 80)):
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = 32
    # Goblin janitor — small, hunched, wearing overalls
    # Body
    draw.ellipse([center-14, 25, center+14, 55], fill=(80, 130, 80, 255), outline=(60, 100, 60, 255), width=2)
    # Overalls
    draw.rectangle([center-10, 35, center+10, 55], fill=(60, 80, 120, 255), outline=(80, 100, 150, 255), width=1)
    # Head
    draw.ellipse([center-10, 10, center+10, 28], fill=(90, 150, 90, 255), outline=(70, 120, 70, 255), width=2)
    # Ears
    draw.polygon([(center-10, 16), (center-18, 8), (center-8, 20)], fill=(80, 130, 80, 255), outline=(60, 100, 60, 255), width=1)
    draw.polygon([(center+10, 16), (center+18, 8), (center+8, 20)], fill=(80, 130, 80, 255), outline=(60, 100, 60, 255), width=1)
    # Eyes (mischievous)
    draw.ellipse([center-6, 16, center-2, 20], fill=(255, 255, 100, 255))
    draw.ellipse([center+2, 16, center+6, 20], fill=(255, 255, 100, 255))
    # Wrench
    draw.line([(center+14, 40), (center+24, 30)], fill=(180, 180, 190, 255), width=3)
    draw.ellipse([center+22, 26, center+28, 32], fill=(180, 180, 190, 255), outline=(150, 150, 160, 255), width=1)
    # Grin
    draw.arc([center-6, 18, center+6, 26], start=0, end=180, fill=(255, 255, 255, 255), width=2)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_item_master_key(output_path, size=(48, 48)):
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = 24
    # Key shaft
    draw.rectangle([center-3, 8, center+3, 32], fill=(180, 150, 80, 255), outline=(220, 190, 120, 255), width=1)
    # Key bow (fancy)
    draw.ellipse([center-12, 4, center+12, 20], fill=(160, 130, 70, 255), outline=(200, 170, 100, 255), width=2)
    draw.ellipse([center-4, 8, center+4, 16], fill=(80, 60, 30, 255), outline=(120, 100, 60, 255), width=1)
    # Key teeth
    draw.rectangle([center+3, 26, center+10, 30], fill=(180, 150, 80, 255), outline=(220, 190, 120, 255), width=1)
    draw.rectangle([center+3, 32, center+8, 36], fill=(180, 150, 80, 255), outline=(220, 190, 120, 255), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_item_deans_key(output_path, size=(48, 48)):
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = 24
    # Ornate key — longer, fancier
    draw.rectangle([center-2, 6, center+2, 38], fill=(200, 180, 100, 255), outline=(240, 220, 150, 255), width=1)
    # Bow with cross pattern
    draw.ellipse([center-14, 2, center+14, 18], fill=(180, 160, 90, 255), outline=(230, 210, 140, 255), width=2)
    draw.line([(center-10, 10), (center+10, 10)], fill=(220, 200, 130, 255), width=2)
    draw.line([(center, 4), (center, 16)], fill=(220, 200, 130, 255), width=2)
    # Long teeth
    draw.rectangle([center+2, 30, center+12, 34], fill=(200, 180, 100, 255), outline=(240, 220, 150, 255), width=1)
    draw.rectangle([center+2, 36, center+10, 40], fill=(200, 180, 100, 255), outline=(240, 220, 150, 255), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

# ===================================================================
# FACTION BANNERS
# ===================================================================

def create_faction_banner(faction, color, output_path, size=(64, 96)):
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Banner cloth
    draw.polygon([(10, 10), (54, 10), (50, 80), (14, 80)], fill=(*color, 200), outline=(255, 255, 255, 150), width=2)
    # Pole
    draw.line([(10, 10), (10, 90)], fill=(150, 140, 130, 255), width=3)
    # Symbol
    symbols = {'construct': '⚙', 'undead': '💀', 'goblin': '🔧'}
    sym = symbols.get(faction, '?')
    font = get_font(14)
    bbox = draw.textbbox((0, 0), sym, font=font)
    tw = bbox[2] - bbox[0]
    # Fallback to letter if emoji doesn't render
    if tw == 0:
        sym = {'construct': 'C', 'undead': 'U', 'goblin': 'G'}.get(faction, '?')
        bbox = draw.textbbox((0, 0), sym, font=font)
        tw = bbox[2] - bbox[0]
    draw.text(((64-tw)//2, 38), sym, fill=(255, 255, 255, 255), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

# ===================================================================
# MAIN
# ===================================================================

def main():
    os.makedirs(BASE_PATH, exist_ok=True)
    print("=== Generating Floor 6 Assets ===\n")
    
    # 1. Room Backgrounds (7)
    create_bg_quadrangle(os.path.join(BASE_PATH, "bg_quadrangle.png"))
    create_bg_gears(os.path.join(BASE_PATH, "bg_gears.png"))
    create_bg_echoes(os.path.join(BASE_PATH, "bg_echoes.png"))
    create_bg_aether(os.path.join(BASE_PATH, "bg_aether.png"))
    create_bg_pacts(os.path.join(BASE_PATH, "bg_pacts.png"))
    create_bg_undercroft(os.path.join(BASE_PATH, "bg_undercroft.png"))
    create_bg_clocktower_apex(os.path.join(BASE_PATH, "bg_clocktower_apex.png"))
    
    # 2. Tiles (3)
    create_tile_courtyard_stone(os.path.join(BASE_PATH, "tile_courtyard_stone.png"))
    create_tile_library_carpet(os.path.join(BASE_PATH, "tile_library_carpet.png"))
    create_tile_tunnel_brick(os.path.join(BASE_PATH, "tile_tunnel_brick.png"))
    
    # 3. Environmental Sprites (9)
    create_moonlight_beam(os.path.join(BASE_PATH, "moonlight_beam.png"))
    create_clocktower_bell(os.path.join(BASE_PATH, "clocktower_bell.png"))
    create_statue_construct(os.path.join(BASE_PATH, "statue_construct.png"))
    create_book_stack(os.path.join(BASE_PATH, "book_stack.png"))
    create_ink_vat(os.path.join(BASE_PATH, "ink_vat.png"))
    create_lecture_desk(os.path.join(BASE_PATH, "lecture_desk.png"))
    create_summoning_circle(os.path.join(BASE_PATH, "summoning_circle.png"))
    create_steam_pipe(os.path.join(BASE_PATH, "steam_pipe.png"))
    create_dean_door(os.path.join(BASE_PATH, "dean_door.png"))
    
    # 4. Enemy Sprites (7 enemies × 4 frames = 28)
    enemies = [
        ("calibration_drone", "construct"),
        ("logic_core", "construct"),
        ("brass_enforcer", "construct"),
        ("the_forgotten", "undead"),
        ("the_one_who_remembers", "undead"),
        ("marrow_priest", "undead"),
        ("the_dean", "construct"),  # Boss
    ]
    frames = ["idle", "attack", "damage", "death"]
    
    for enemy_name, faction in enemies:
        for frame in frames:
            prefix = "boss_" if "dean" in enemy_name else "enemy_"
            output_path = os.path.join(BASE_PATH, f"{prefix}{enemy_name}_{frame}.png")
            create_enemy_sprite(enemy_name, faction, frame, output_path)
    
    # 5. NPC/Item Sprites (4)
    create_npc_registrar(os.path.join(BASE_PATH, "npc_registrar.png"))
    create_npc_sneak_thief(os.path.join(BASE_PATH, "npc_sneak_thief.png"))
    create_item_master_key(os.path.join(BASE_PATH, "item_master_key.png"))
    create_item_deans_key(os.path.join(BASE_PATH, "item_deans_key.png"))
    
    # 6. Faction Banners (3)
    create_faction_banner("construct", (184, 134, 11), os.path.join(BASE_PATH, "banner_construct.png"))
    create_faction_banner("undead", (120, 140, 160), os.path.join(BASE_PATH, "banner_undead.png"))
    create_faction_banner("goblin", (80, 160, 80), os.path.join(BASE_PATH, "banner_goblin.png"))
    
    print("\n=== FLOOR 6 ASSET GENERATION COMPLETE ===")
    print(f"All assets saved to: {BASE_PATH}")

if __name__ == "__main__":
    main()
