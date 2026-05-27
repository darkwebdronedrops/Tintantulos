#!/usr/bin/env python3
"""Generate pixel art assets for Floor 5 — The Airship Docks"""

from PIL import Image, ImageDraw, ImageFont
import os
import math
import random

BASE_PATH = "/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/floor5"

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
# BACKGROUND GENERATORS (atmospheric, thematic)
# ===================================================================

def create_sky_gradient(draw, w, h, top_color, bottom_color, horizon_y=None):
    """Draw sky gradient from top_color to bottom_color"""
    if horizon_y is None:
        horizon_y = h * 2 // 3
    for y in range(horizon_y):
        t = y / horizon_y
        r = int(top_color[0] * (1-t) + bottom_color[0] * t)
        g = int(top_color[1] * (1-t) + bottom_color[1] * t)
        b = int(top_color[2] * (1-t) + bottom_color[2] * t)
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))

def draw_clouds(draw, w, h, count=8, color=(200, 200, 220, 120)):
    """Draw stylized pixel clouds"""
    for _ in range(count):
        cx = random.randint(50, w-50)
        cy = random.randint(20, h//2)
        size = random.randint(30, 80)
        for i in range(size):
            x = cx + i - size//2
            cloud_h = int(math.sin(i * math.pi / size) * 15)
            draw.ellipse([x-5, cy-cloud_h, x+5, cy+cloud_h], fill=color)

def draw_stars(draw, w, h, count=30):
    """Draw stars in the sky"""
    for _ in range(count):
        x = random.randint(0, w)
        y = random.randint(0, h//3)
        size = random.choice([1, 1, 1, 2, 2, 3])
        brightness = random.randint(180, 255)
        draw.ellipse([x-size, y-size, x+size, y+size], fill=(brightness, brightness, 220, 255))

def draw_wind_lines(draw, w, h, count=20, color=(200, 220, 240, 80)):
    """Draw diagonal wind streaks"""
    for _ in range(count):
        x = random.randint(0, w)
        y = random.randint(0, h)
        length = random.randint(40, 120)
        thickness = random.choice([1, 1, 2])
        draw.line([(x, y), (x + length, y - length//3)], fill=color, width=thickness)

# -------------------------------------------------------------------
# ROOM BACKGROUNDS
# -------------------------------------------------------------------

def create_bg_mooring(output_path, size=(2400, 1400)):
    """The Mooring — wind-whipped landing platform, cargo crates, swaying tethers"""
    ensure_dir(output_path)
    w, h = size
    img = Image.new('RGBA', size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    
    # Sky — stormy gray-blue
    create_sky_gradient(draw, w, h, (60, 70, 90), (100, 110, 130), h*3//4)
    draw_clouds(draw, w, h, 10, (140, 150, 160, 100))
    draw_wind_lines(draw, w, h, 25, (180, 200, 220, 60))
    
    # Distant airship silhouettes
    for sx in [400, 1600, 2000]:
        sy = h * 2 // 5
        draw.ellipse([sx-100, sy-30, sx+100, sy+30], fill=(80, 85, 95, 200), outline=(60, 65, 75, 255), width=2)
        # Balloon
        draw.polygon([(sx, sy-60), (sx-60, sy-20), (sx+60, sy-20)], fill=(70, 75, 85, 200))
    
    # Main platform (stone/brass)
    plat_y = h * 2 // 3
    draw.polygon([
        (0, plat_y), (w, plat_y),
        (w, plat_y+80), (0, plat_y+80)
    ], fill=(120, 110, 100, 255), outline=(140, 130, 120, 255), width=2)
    
    # Platform edge detail
    for x in range(0, w, 60):
        draw.rectangle([x, plat_y, x+30, plat_y+15], fill=(100, 90, 80, 255), outline=(130, 120, 110, 255), width=1)
    
    # Mooring towers
    for tx in [200, 2200]:
        draw.rectangle([tx-40, plat_y-300, tx+40, plat_y], fill=(90, 85, 75, 255), outline=(110, 105, 95, 255), width=2)
        # Tower top
        draw.polygon([(tx, plat_y-350), (tx-50, plat_y-300), (tx+50, plat_y-300)], fill=(100, 95, 85, 255))
        # Tether ring
        draw.ellipse([tx-10, plat_y-340, tx+10, plat_y-320], fill=(184, 134, 11, 255), outline=(218, 165, 32, 255), width=2)
    
    # Cargo crates (cover objects)
    crate_positions = [(500, plat_y-40), (700, plat_y-40), (1500, plat_y-40), (1700, plat_y-40), (900, plat_y-80), (1300, plat_y-80)]
    for cx, cy in crate_positions:
        draw.rectangle([cx-25, cy-25, cx+25, cy+25], fill=(100, 75, 50, 255), outline=(130, 100, 70, 255), width=2)
        # Crate detail
        draw.line([(cx-25, cy-10), (cx+25, cy-10)], fill=(80, 60, 40, 255), width=1)
        draw.line([(cx-10, cy-25), (cx-10, cy+25)], fill=(80, 60, 40, 255), width=1)
    
    # Crash site (left side)
    crash_x = 300
    draw.polygon([
        (crash_x-80, plat_y), (crash_x+80, plat_y),
        (crash_x+60, plat_y-40), (crash_x-100, plat_y-30)
    ], fill=(60, 55, 50, 255), outline=(80, 75, 70, 255), width=2)
    # Broken hull splinters
    for i in range(5):
        sx = crash_x + random.randint(-60, 60)
        sy = plat_y - random.randint(10, 50)
        draw.polygon([(sx, sy), (sx+15, sy-5), (sx+5, sy+15)], fill=(50, 45, 40, 255))
    
    # Tether ropes (swaying)
    for tx in [150, 600, 1200, 1800, 2100]:
        draw.line([(tx, 0), (tx+20, plat_y-40)], fill=(150, 140, 120, 200), width=2)
        draw.line([(tx+5, 0), (tx+25, plat_y-40)], fill=(130, 120, 100, 200), width=1)
    
    # Wind shear lines
    draw_wind_lines(draw, w, h, 30, (220, 230, 240, 40))
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_bg_breeze(output_path, size=(2200, 1600)):
    """The Breeze — wind airship hull, open sky, canvas balloon"""
    ensure_dir(output_path)
    w, h = size
    img = Image.new('RGBA', size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    
    # Sky — bright open blue
    create_sky_gradient(draw, w, h, (100, 150, 200), (140, 180, 220), h*2//3)
    draw_clouds(draw, w, h, 12, (220, 230, 240, 140))
    draw_stars(draw, w, h, 15)
    
    # Airship hull (main deck)
    deck_y = h * 2 // 3
    draw.polygon([
        (0, deck_y), (w, deck_y),
        (w, deck_y+100), (0, deck_y+100)
    ], fill=(139, 119, 101, 255), outline=(160, 140, 120, 255), width=2)
    
    # Hull planks
    for x in range(0, w, 40):
        draw.line([(x, deck_y), (x, deck_y+100)], fill=(120, 100, 85, 255), width=1)
    
    # Canvas balloon (above)
    balloon_y = deck_y - 250
    draw.ellipse([w//2-300, balloon_y-100, w//2+300, balloon_y+100], fill=(210, 190, 170, 255), outline=(180, 160, 140, 255), width=2)
    # Balloon panels
    for i in range(-2, 3):
        x = w//2 + i * 120
        draw.line([(x, balloon_y-80), (x, balloon_y+80)], fill=(190, 170, 150, 255), width=2)
    
    # Rigging lines
    for rx in [w//2-200, w//2, w//2+200]:
        draw.line([(rx, balloon_y+100), (rx, deck_y)], fill=(150, 140, 120, 200), width=1)
    
    # Open edge (left side = gap)
    draw.polygon([
        (0, deck_y), (150, deck_y),
        (100, deck_y+150), (0, deck_y+150)
    ], fill=(80, 90, 110, 255), outline=(100, 110, 130, 255), width=2)
    # Sky through gap
    draw.rectangle([0, deck_y+100, 100, h], fill=(100, 140, 190, 255))
    
    # Wind gust zones (visible streaks)
    draw_wind_lines(draw, w, h, 35, (200, 220, 240, 70))
    
    # Mast
    mast_x = w - 200
    draw.rectangle([mast_x-10, deck_y-400, mast_x+10, deck_y], fill=(100, 85, 70, 255), outline=(130, 115, 100, 255), width=2)
    # Crow's nest platform
    draw.rectangle([mast_x-40, deck_y-380, mast_x+40, deck_y-360], fill=(120, 105, 90, 255), outline=(150, 135, 120, 255), width=2)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_bg_boiler(output_path, size=(2200, 1600)):
    """The Boiler — steam airship, brass pipes, pressure gauges"""
    ensure_dir(output_path)
    w, h = size
    img = Image.new('RGBA', size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    
    # Sky — warm steamy orange-gray
    create_sky_gradient(draw, w, h, (80, 70, 60), (120, 110, 100), h*2//3)
    draw_clouds(draw, w, h, 8, (150, 140, 130, 80))
    
    # Steam haze overlay
    for y in range(0, h, 20):
        alpha = int(30 * math.sin(y * 0.01))
        draw.line([(0, y), (w, y)], fill=(200, 200, 190, alpha), width=2)
    
    # Brass deck
    deck_y = h * 2 // 3
    draw.polygon([
        (0, deck_y), (w, deck_y),
        (w, deck_y+100), (0, deck_y+100)
    ], fill=(160, 130, 80, 255), outline=(184, 134, 11, 255), width=2)
    
    # Brass pipes (vertical and horizontal)
    pipe_colors = [(140, 110, 60, 255), (160, 130, 80, 255), (120, 95, 55, 255)]
    for i in range(6):
        px = 200 + i * 300
        draw.rectangle([px-8, deck_y-300, px+8, deck_y], fill=pipe_colors[i%3], outline=(184, 134, 11, 255), width=1)
        # Pipe joint
        draw.ellipse([px-12, deck_y-300-12, px+12, deck_y-300+12], fill=(184, 134, 11, 255), outline=(218, 165, 32, 255), width=2)
        # Horizontal pipe
        draw.rectangle([px, deck_y-280, px+150, deck_y-260], fill=pipe_colors[i%3], outline=(184, 134, 11, 255), width=1)
    
    # Pressure gauges
    for gx in [350, 950, 1550]:
        gy = deck_y - 250
        draw.ellipse([gx-20, gy-20, gx+20, gy+20], fill=(220, 220, 210, 255), outline=(184, 134, 11, 255), width=2)
        # Gauge needle
        needle_angle = random.randint(30, 150)
        nx = gx + 15 * math.cos(math.radians(needle_angle))
        ny = gy - 15 * math.sin(math.radians(needle_angle))
        draw.line([(gx, gy), (nx, ny)], fill=(200, 50, 50, 255), width=2)
    
    # Steam tanks (for secret room fake wall area)
    for sx in [1800, 1900]:
        draw.rectangle([sx-30, deck_y-120, sx+30, deck_y], fill=(100, 95, 90, 255), outline=(130, 125, 120, 255), width=2)
        draw.line([(sx-30, deck_y-80), (sx+30, deck_y-80)], fill=(80, 75, 70, 255), width=1)
    
    # Balloon (darker, soot-stained)
    balloon_y = deck_y - 280
    draw.ellipse([w//2-280, balloon_y-90, w//2+280, balloon_y+90], fill=(140, 130, 110, 255), outline=(160, 150, 130, 255), width=2)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_bg_gale(output_path, size=(2200, 1600)):
    """The Gale — mixed airship, storm clouds, rigging"""
    ensure_dir(output_path)
    w, h = size
    img = Image.new('RGBA', size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    
    # Sky — stormy dark gray
    create_sky_gradient(draw, w, h, (40, 45, 55), (60, 65, 75), h*2//3)
    draw_clouds(draw, w, h, 15, (80, 85, 95, 150))
    
    # Storm approach — dark clouds at top
    for i in range(8):
        cx = random.randint(100, w-100)
        cy = random.randint(20, 150)
        size_c = random.randint(60, 120)
        draw.ellipse([cx-size_c, cy-size_c//2, cx+size_c, cy+size_c//2], fill=(30, 35, 45, 200), outline=(50, 55, 65, 255), width=2)
    
    # Mixed deck (wood + brass)
    deck_y = h * 2 // 3
    for x in range(0, w, 200):
        color = (139, 119, 101, 255) if (x//200) % 2 == 0 else (160, 130, 80, 255)
        draw.polygon([
            (x, deck_y), (x+200, deck_y),
            (x+200, deck_y+100), (x, deck_y+100)
        ], fill=color, outline=(140, 130, 120, 255), width=2)
    
    # Rigging lines (more complex)
    for rx in [w//2-250, w//2, w//2+250]:
        draw.line([(rx, 100), (rx, deck_y)], fill=(120, 110, 100, 180), width=1)
        # Cross rigging
        draw.line([(rx-100, 200), (rx+100, deck_y-100)], fill=(120, 110, 100, 120), width=1)
    
    # Balloon (patched look)
    balloon_y = deck_y - 260
    draw.ellipse([w//2-250, balloon_y-80, w//2+250, balloon_y+80], fill=(170, 160, 140, 255), outline=(150, 140, 120, 255), width=2)
    # Patch
    draw.rectangle([w//2+50, balloon_y-30, w//2+120, balloon_y+10], fill=(150, 140, 120, 255), outline=(130, 120, 100, 255), width=1)
    
    # Wind lines (stronger)
    draw_wind_lines(draw, w, h, 40, (180, 200, 220, 90))
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_bg_crow(output_path, size=(2000, 1600)):
    """The Crow's Nest — highest mooring tower, lightning rods, narrow walkways"""
    ensure_dir(output_path)
    w, h = size
    img = Image.new('RGBA', size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    
    # Sky — dark storm, high altitude
    create_sky_gradient(draw, w, h, (25, 30, 45), (45, 50, 65), h//2)
    draw_stars(draw, w, h, 50)
    draw_clouds(draw, w, h, 6, (60, 65, 80, 120))
    
    # Distant towers below
    for tx in [400, 1600]:
        ty = h * 3 // 4
        draw.rectangle([tx-20, ty-200, tx+20, ty], fill=(50, 55, 65, 255), outline=(60, 65, 75, 255), width=1)
        draw.polygon([(tx, ty-250), (tx-30, ty-200), (tx+30, ty-200)], fill=(55, 60, 70, 255))
    
    # Main tower (stone)
    tower_x = w // 2
    tower_top = h // 3
    draw.rectangle([tower_x-100, tower_top, tower_x+100, h], fill=(70, 65, 60, 255), outline=(90, 85, 80, 255), width=2)
    # Tower stonework detail
    for y in range(tower_top, h, 40):
        draw.line([(tower_x-100, y), (tower_x+100, y)], fill=(60, 55, 50, 255), width=1)
    
    # Narrow walkways (left and right)
    for wx in [tower_x-200, tower_x+200]:
        draw.rectangle([wx-80, tower_top+50, wx+80, tower_top+70], fill=(80, 75, 70, 255), outline=(100, 95, 90, 255), width=2)
        # Walkway supports
        draw.line([(wx, tower_top+70), (wx, tower_top+150)], fill=(60, 55, 50, 255), width=3)
    
    # Lightning rods (tall, crackling)
    for rx in [tower_x-150, tower_x+150]:
        draw.rectangle([rx-3, tower_top-200, rx+3, tower_top], fill=(180, 180, 190, 255), outline=(200, 200, 210, 255), width=1)
        # Rod tip (glowing)
        draw.ellipse([rx-8, tower_top-210, rx+8, tower_top-190], fill=(200, 220, 255, 255), outline=(150, 200, 255, 255), width=2)
        # Energy arcs
        for _ in range(3):
            ax = rx + random.randint(-30, 30)
            ay = tower_top - 180 + random.randint(-20, 20)
            draw.arc([ax-15, ay-15, ax+15, ay+15], start=0, end=180, fill=(150, 200, 255, 200), width=2)
    
    # Central platform
    draw.rectangle([tower_x-120, tower_top, tower_x+120, tower_top+40], fill=(80, 75, 70, 255), outline=(100, 95, 90, 255), width=2)
    
    # Gangplank connections (to boss)
    draw.rectangle([tower_x-60, tower_top-40, tower_x+60, tower_top-20], fill=(100, 90, 80, 255), outline=(120, 110, 100, 255), width=2)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_bg_aetherworks(output_path, size=(2400, 1600)):
    """The Aetherworks — circular engine room, central aether-core, pistons"""
    ensure_dir(output_path)
    w, h = size
    img = Image.new('RGBA', size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    
    # Dark industrial interior
    draw.rectangle([0, 0, w, h], fill=(20, 20, 25, 255))
    
    # Floor — circular pattern
    center_x, center_y = w // 2, h * 2 // 3
    for ring in range(8, 0, -1):
        radius = ring * 120
        color_val = 30 + ring * 8
        draw.ellipse([center_x-radius, center_y-radius//2, center_x+radius, center_y+radius//2],
                     fill=(color_val, color_val, color_val+5, 255),
                     outline=(color_val+15, color_val+15, color_val+20, 255), width=2)
    
    # Central aether-core (glowing)
    core_r = 80
    # Glow rings
    for glow in range(5, 0, -1):
        r = core_r + glow * 15
        alpha = int(60 / glow)
        draw.ellipse([center_x-r, center_y-r//2, center_x+r, center_y+r//2],
                     fill=(100, 80, 150, alpha), outline=(120, 100, 180, alpha+30), width=2)
    
    # Core itself
    draw.ellipse([center_x-core_r, center_y-core_r//2, center_x+core_r, center_y+core_r//2],
                 fill=(80, 60, 120, 255), outline=(150, 120, 220, 255), width=3)
    # Inner core (bright)
    draw.ellipse([center_x-core_r//2, center_y-core_r//4, center_x+core_r//2, center_y+core_r//4],
                 fill=(200, 180, 255, 255), outline=(220, 200, 255, 255), width=2)
    
    # Pistons (around the core)
    piston_count = 6
    for i in range(piston_count):
        angle = (2 * math.pi * i) / piston_count
        px = center_x + int(300 * math.cos(angle))
        py = center_y + int(100 * math.sin(angle))
        # Piston body
        draw.rectangle([px-20, py-60, px+20, py+60], fill=(100, 95, 90, 255), outline=(120, 115, 110, 255), width=2)
        # Piston head
        draw.rectangle([px-25, py-70, px+25, py-50], fill=(140, 135, 130, 255), outline=(160, 155, 150, 255), width=2)
        # Connecting rod to center
        draw.line([(px, py), (center_x, center_y)], fill=(80, 75, 70, 255), width=3)
    
    # Ceiling beams
    for y in [50, 150]:
        draw.rectangle([0, y, w, y+20], fill=(40, 40, 45, 255), outline=(60, 60, 65, 255), width=1)
    
    # Wall pipes
    for y in range(200, h-200, 100):
        draw.rectangle([50, y-8, 200, y+8], fill=(60, 60, 70, 255), outline=(80, 80, 90, 255), width=1)
        draw.rectangle([w-200, y-8, w-50, y+8], fill=(60, 60, 70, 255), outline=(80, 80, 90, 255), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_bg_cargo(output_path, size=(1600, 1200)):
    """The Cargo Hold — hidden cargo hold, steam tanks, fake wall"""
    ensure_dir(output_path)
    w, h = size
    img = Image.new('RGBA', size, (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    
    # Dark, cramped interior
    draw.rectangle([0, 0, w, h], fill=(25, 22, 20, 255))
    
    # Fake wall area (right side, slightly different texture)
    draw.rectangle([w-300, 100, w-50, h-100], fill=(35, 32, 30, 255), outline=(50, 47, 45, 255), width=2)
    # Wall seam hint
    draw.line([(w-300, 100), (w-300, h-100)], fill=(60, 55, 50, 255), width=3)
    
    # Steam tanks
    for tx in [200, 500, 800]:
        ty = h * 2 // 3
        draw.rectangle([tx-40, ty-150, tx+40, ty], fill=(60, 55, 50, 255), outline=(80, 75, 70, 255), width=2)
        # Tank bands
        for by in [ty-120, ty-80, ty-40]:
            draw.line([(tx-40, by), (tx+40, by)], fill=(100, 95, 90, 255), width=2)
        # Pressure gauge on tank
        draw.ellipse([tx-15, ty-170, tx+15, ty-140], fill=(220, 220, 210, 255), outline=(150, 150, 140, 255), width=1)
    
    # Cargo crates (stacked)
    crate_positions = [(150, h-80), (350, h-80), (550, h-80), (750, h-80),
                       (250, h-160), (450, h-160), (650, h-160)]
    for cx, cy in crate_positions:
        draw.rectangle([cx-30, cy-30, cx+30, cy+30], fill=(80, 65, 50, 255), outline=(100, 85, 70, 255), width=2)
        draw.line([(cx-30, cy-10), (cx+30, cy-10)], fill=(65, 50, 40, 255), width=1)
    
    # Aberrant glow (wrong frequency)
    for _ in range(10):
        gx = random.randint(100, w-100)
        gy = random.randint(100, h-100)
        draw.ellipse([gx-20, gy-10, gx+20, gy+10], fill=(120, 50, 180, 40), outline=(150, 80, 220, 60), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

# ===================================================================
# TILES
# ===================================================================

def create_hex_tile(draw, center, radius, color, outline_color=(255,255,255,200), width=2):
    """Draw a hexagon"""
    points = []
    for i in range(6):
        angle = math.radians(60 * i - 30)
        x = center[0] + radius * math.cos(angle)
        y = center[1] + radius * math.sin(angle)
        points.append((x, y))
    draw.polygon(points, fill=color, outline=outline_color, width=width)
    return points

def create_tile_airship_deck(output_path, size=64):
    """Wooden/brass deck hex tile"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    center = (size//2, size//2)
    radius = size//2 - 2
    
    # Wood base with brass edge
    create_hex_tile(draw, center, radius, (139, 119, 101, 220), (184, 134, 11, 255), 2)
    
    # Plank lines
    for i in range(-2, 3):
        y = center[1] + i * 8
        draw.line([(center[0]-radius+5, y), (center[0]+radius-5, y)], fill=(120, 100, 85, 255), width=1)
    
    # Brass nail
    draw.ellipse([center[0]-2, center[1]-2, center[0]+2, center[1]+2], fill=(184, 134, 11, 255))
    
    font = get_font(8)
    bbox = draw.textbbox((0, 0), "DECK", font=font)
    text_width = bbox[2] - bbox[0]
    draw.text(((size - text_width)//2, size//2 - 4), "DECK", fill=(255, 255, 255, 200), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_tile_sky_gap(output_path, size=64):
    """Open sky/void hex tile"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    center = (size//2, size//2)
    radius = size//2 - 2
    
    # Sky blue with transparency
    create_hex_tile(draw, center, radius, (80, 120, 160, 180), (120, 160, 200, 255), 2)
    
    # Wind streak
    draw.line([(center[0]-10, center[1]-5), (center[0]+10, center[1]+5)], fill=(200, 220, 240, 150), width=1)
    
    font = get_font(8)
    bbox = draw.textbbox((0, 0), "SKY", font=font)
    text_width = bbox[2] - bbox[0]
    draw.text(((size - text_width)//2, size//2 - 4), "SKY", fill=(200, 220, 240, 200), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_tile_mooring_stone(output_path, size=64):
    """Stone tower hex tile"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    center = (size//2, size//2)
    radius = size//2 - 2
    
    # Stone gray
    create_hex_tile(draw, center, radius, (90, 85, 80, 220), (110, 105, 100, 255), 2)
    
    # Stonework lines
    for i in range(-1, 2):
        y = center[1] + i * 12
        draw.line([(center[0]-radius+8, y), (center[0]+radius-8, y)], fill=(70, 65, 60, 255), width=1)
    
    font = get_font(8)
    bbox = draw.textbbox((0, 0), "STONE", font=font)
    text_width = bbox[2] - bbox[0]
    draw.text(((size - text_width)//2, size//2 - 4), "STONE", fill=(200, 195, 190, 200), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

# ===================================================================
# ENVIRONMENTAL SPRITES
# ===================================================================

def create_wind_gust(output_path, size=(128, 64)):
    """Visible wind shear effect — diagonal streaks"""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    for i in range(5):
        y = 10 + i * 12
        alpha = int(150 - i * 15)
        draw.line([(0, y), (size[0], y-10)], fill=(200, 220, 240, alpha), width=3)
        draw.line([(20, y+5), (size[0]-20, y-5)], fill=(180, 200, 220, alpha//2), width=2)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_steam_vent(output_path, size=(64, 128)):
    """Brass pipe with pressure gauge"""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Pipe body
    draw.rectangle([20, 0, 44, 80], fill=(140, 110, 60, 255), outline=(184, 134, 11, 255), width=2)
    
    # Pressure gauge
    draw.ellipse([10, 40, 54, 84], fill=(220, 220, 210, 255), outline=(184, 134, 11, 255), width=2)
    # Needle
    draw.line([(32, 62), (20, 50)], fill=(200, 50, 50, 255), width=2)
    
    # Steam jets (top)
    for i in range(3):
        x = 32 + (i-1) * 10
        draw.arc([x-8, -10, x+8, 10], start=180, end=360, fill=(200, 200, 210, 100), width=2)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_lightning_rod(output_path, size=(48, 192)):
    """Tall rod with crackling energy"""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Rod
    draw.rectangle([20, 40, 28, 180], fill=(180, 180, 190, 255), outline=(200, 200, 210, 255), width=1)
    
    # Tip (glowing)
    draw.ellipse([14, 20, 34, 40], fill=(200, 220, 255, 255), outline=(150, 200, 255, 255), width=2)
    
    # Energy arcs
    for _ in range(6):
        ax = 24 + random.randint(-15, 15)
        ay = 30 + random.randint(-10, 40)
        draw.arc([ax-10, ay-10, ax+10, ay+10], start=0, end=180, fill=(150, 200, 255, 200), width=2)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_gangplank(output_path, size=(400, 80)):
    """Rickety bridge between platforms — WIDE for 3+ entities (Caleb note)"""
    ensure_dir(output_path)
    w, h = size
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Planks
    plank_w = 36
    for i in range(w // plank_w):
        x = i * plank_w
        # Slight vertical offset for "rickety" look
        offset = (i % 3) * 3
        color = (120, 100, 80, 255) if i % 2 == 0 else (100, 80, 65, 255)
        draw.rectangle([x, 10+offset, x+plank_w-2, h-10+offset], fill=color, outline=(80, 65, 50, 255), width=1)
    
    # Rope railings
    draw.line([(0, 5), (w, 5)], fill=(140, 130, 110, 255), width=2)
    draw.line([(0, h-5), (w, h-5)], fill=(140, 130, 110, 255), width=2)
    
    # Support posts
    for x in [20, w//2, w-20]:
        draw.rectangle([x-3, 0, x+3, h], fill=(100, 90, 80, 255), outline=(120, 110, 100, 255), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path} ({w}x{h} — wide for 3+ entities)")

def create_cargo_crane(output_path, size=(128, 192)):
    """Cargo lift mechanism"""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Tower
    draw.rectangle([50, 0, 78, 160], fill=(100, 95, 90, 255), outline=(120, 115, 110, 255), width=2)
    
    # Arm
    draw.rectangle([20, 20, 110, 40], fill=(120, 115, 110, 255), outline=(140, 135, 130, 255), width=2)
    
    # Cable
    draw.line([(90, 40), (90, 120)], fill=(150, 140, 130, 255), width=2)
    
    # Lift platform
    draw.rectangle([70, 120, 110, 140], fill=(100, 95, 90, 255), outline=(120, 115, 110, 255), width=2)
    
    # Gear at base
    teeth = 6
    gear_points = []
    for i in range(teeth * 2):
        angle = (360 / (teeth * 2)) * i
        rad = math.radians(angle)
        r = 18 if i % 2 == 0 else 12
        x = 64 + r * math.cos(rad)
        y = 170 + r * math.sin(rad)
        gear_points.append((x, y))
    draw.polygon(gear_points, fill=(184, 134, 11, 255), outline=(218, 165, 32, 255), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_airship_tether(output_path, size=(64, 256)):
    """Rope anchor line"""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Main rope
    draw.line([(32, 0), (32, 220)], fill=(150, 140, 120, 255), width=4)
    # Secondary rope
    draw.line([(28, 0), (28, 220)], fill=(130, 120, 100, 200), width=2)
    draw.line([(36, 0), (36, 220)], fill=(130, 120, 100, 200), width=2)
    
    # Anchor point (top)
    draw.ellipse([20, 0, 44, 20], fill=(184, 134, 11, 255), outline=(218, 165, 32, 255), width=2)
    
    # Sway indicator (bottom hook)
    draw.arc([24, 210, 40, 240], start=0, end=180, fill=(150, 140, 120, 255), width=3)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_mooring_valve(output_path, size=(64, 64)):
    """Steam valve for puzzle"""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Valve wheel
    center = 32
    teeth = 8
    wheel_points = []
    for i in range(teeth * 2):
        angle = (360 / (teeth * 2)) * i
        rad = math.radians(angle)
        r = 24 if i % 2 == 0 else 18
        x = center + r * math.cos(rad)
        y = center + r * math.sin(rad)
        wheel_points.append((x, y))
    draw.polygon(wheel_points, fill=(184, 134, 11, 255), outline=(218, 165, 32, 255), width=2)
    
    # Center hub
    draw.ellipse([center-8, center-8, center+8, center+8], fill=(139, 90, 43, 255), outline=(184, 134, 11, 255), width=1)
    
    # Handle
    draw.line([(center, center), (center+20, center-10)], fill=(160, 130, 60, 255), width=4)
    
    img.save(output_path)
    print(f"Created: {output_path}")

# ===================================================================
# ENEMY SPRITES
# ===================================================================

def create_enemy_sprite(name, faction, frame_type, output_path, size=64):
    """Create an enemy animation frame with faction-appropriate colors"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Faction colors
    colors = {
        'elemental': (100, 180, 220),    # Blue/white wind
        'undead': (120, 130, 140),       # Slate gray/ghostly
        'aberration': (140, 60, 180),    # Purple interference
        'goblin': (80, 160, 80),         # Green
        'construct': (160, 130, 90),     # Brass
    }
    
    base_color = colors.get(faction.lower(), (100, 100, 100))
    
    # Frame modifiers
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
    body_w, body_h = size // 2, size // 2 + 4
    
    # Body color
    body_color = tuple(min(255, int(c * intensity)) for c in base_color)
    
    # Draw body shape based on enemy type
    if "goblin" in name.lower():
        # Small, hunched
        draw.ellipse([center-body_w//2, center-body_h//2+offset_y,
                      center+body_w//2, center+body_h//2+offset_y],
                     fill=body_color, outline=(255, 255, 255, 150), width=2)
        # Ears
        draw.polygon([(center-body_w//2, center-5+offset_y), (center-body_w//2-8, center-12+offset_y), (center-body_w//2, center+offset_y)],
                     fill=body_color, outline=(255, 255, 255, 100), width=1)
        draw.polygon([(center+body_w//2, center-5+offset_y), (center+body_w//2+8, center-12+offset_y), (center+body_w//2, center+offset_y)],
                     fill=body_color, outline=(255, 255, 255, 100), width=1)
    elif "shepherd" in name.lower() or "wisp" in name.lower():
        # Flowing, wispy
        for i in range(3):
            ry = 8 + i * 6
            draw.ellipse([center-body_w//2+i*3, center-ry+offset_y,
                          center+body_w//2-i*3, center+ry+offset_y],
                         fill=(*body_color[:3], int(80+i*40)), outline=(255, 255, 255, 100), width=1)
    elif "core" in name.lower():
        # Boss — large, imposing
        draw.ellipse([center-body_w, center-body_h+offset_y,
                      center+body_w, center+body_h+offset_y],
                     fill=body_color, outline=(255, 255, 255, 200), width=3)
        # Inner core glow
        draw.ellipse([center-body_w//2, center-body_h//2+offset_y,
                      center+body_w//2, center+body_h//2+offset_y],
                     fill=(min(255, body_color[0]+60), min(255, body_color[1]+60), min(255, body_color[2]+60)),
                     outline=(255, 255, 255, 255), width=2)
    elif "knot" in name.lower() or "pressure" in name.lower():
        # Bulbous, steamy
        draw.ellipse([center-body_w//2-4, center-body_h//2+offset_y,
                      center+body_w//2+4, center+body_h//2+offset_y],
                     fill=body_color, outline=(255, 255, 255, 150), width=2)
        # Pressure lines
        draw.arc([center-10, center-10+offset_y, center+10, center+10+offset_y], start=0, end=180, fill=(255, 255, 255, 150), width=2)
    elif "resonance" in name.lower() or "aberration" in name.lower():
        # Shimmering interference
        for i in range(5):
            offset = i * 3
            alpha = int(120 - i * 20)
            c = (body_color[0], body_color[1], body_color[2], alpha)
            draw.ellipse([center-body_w//2+offset, center-body_h//2+offset_y+offset,
                          center+body_w//2-offset, center+body_h//2+offset_y-offset],
                         fill=c, outline=(255, 255, 255, 80), width=1)
    else:
        # Default humanoid
        draw.ellipse([center-body_w//2, center-body_h//2+offset_y,
                      center+body_w//2, center+body_h//2+offset_y],
                     fill=body_color, outline=(255, 255, 255, 150), width=2)
    
    # Eyes
    if frame_type != 'death':
        eye_color = (255, 255, 200) if "elemental" in faction.lower() else (255, 100, 100) if "undead" in faction.lower() else (200, 100, 255)
        eye_y = center - 6 + offset_y
        eye_offset = 7
        draw.ellipse([center-eye_offset-3, eye_y-3, center-eye_offset+3, eye_y+3], fill=eye_color)
        draw.ellipse([center+eye_offset-3, eye_y-3, center+eye_offset+3, eye_y+3], fill=eye_color)
    else:
        # Dead eyes (X marks)
        eye_y = center - 6 + offset_y
        eye_offset = 7
        draw.line([(center-eye_offset-3, eye_y-3), (center-eye_offset+3, eye_y+3)], fill=(80, 80, 80, 255), width=2)
        draw.line([(center-eye_offset-3, eye_y+3), (center-eye_offset+3, eye_y-3)], fill=(80, 80, 80, 255), width=2)
        draw.line([(center+eye_offset-3, eye_y-3), (center+eye_offset+3, eye_y+3)], fill=(80, 80, 80, 255), width=2)
        draw.line([(center+eye_offset-3, eye_y+3), (center+eye_offset+3, eye_y-3)], fill=(80, 80, 80, 255), width=2)
    
    # Faction symbol
    font = get_font(8)
    symbol = {
        'elemental': 'E', 'undead': 'U', 'aberration': 'A',
        'goblin': 'G', 'construct': 'C', 'demon': 'D'
    }.get(faction.lower(), '?')
    bbox = draw.textbbox((0, 0), symbol, font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (size - text_width) // 2
    text_y = center + 10 + offset_y
    draw.text((text_x, text_y), symbol, fill=(255, 255, 255, 180), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

# ===================================================================
# SHARED ITEMS
# ===================================================================

def create_anchor_point(output_path, size=64):
    """Wind anchor/cover"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    # Anchor shape
    draw.polygon([
        (center, 10), (center-15, 30), (center+15, 30)
    ], fill=(150, 140, 130, 255), outline=(170, 160, 150, 255), width=2)
    draw.line([(center, 30), (center, 50)], fill=(150, 140, 130, 255), width=4)
    draw.line([(center-15, 50), (center+15, 50)], fill=(150, 140, 130, 255), width=4)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_cargo_crate(output_path, size=64):
    """Cover object"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    draw.rectangle([center-20, center-20, center+20, center+20], fill=(100, 75, 50, 255), outline=(130, 100, 70, 255), width=2)
    draw.line([(center-20, center-5), (center+20, center-5)], fill=(80, 60, 40, 255), width=1)
    draw.line([(center-5, center-20), (center-5, center+20)], fill=(80, 60, 40, 255), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_aether_lens(output_path, size=64):
    """Secret room reward item"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    # Lens shape
    draw.ellipse([center-18, center-22, center+18, center+22], fill=(100, 80, 150, 180), outline=(180, 150, 255, 255), width=2)
    # Inner glow
    draw.ellipse([center-8, center-10, center+8, center+10], fill=(200, 180, 255, 255), outline=(220, 200, 255, 255), width=1)
    # Shine
    draw.line([(center-12, center-12), (center-4, center-4)], fill=(255, 255, 255, 255), width=2)
    
    img.save(output_path)
    print(f"Created: {output_path}")

# ===================================================================
# MAIN
# ===================================================================

def main():
    os.makedirs(BASE_PATH, exist_ok=True)
    print("=== Generating Floor 5 Assets ===\n")
    
    # 1. Room Backgrounds
    create_bg_mooring(os.path.join(BASE_PATH, "bg_mooring.png"))
    create_bg_breeze(os.path.join(BASE_PATH, "bg_breeze.png"))
    create_bg_boiler(os.path.join(BASE_PATH, "bg_boiler.png"))
    create_bg_gale(os.path.join(BASE_PATH, "bg_gale.png"))
    create_bg_crow(os.path.join(BASE_PATH, "bg_crow.png"))
    create_bg_aetherworks(os.path.join(BASE_PATH, "bg_aetherworks.png"))
    create_bg_cargo(os.path.join(BASE_PATH, "bg_cargo.png"))
    
    # 2. Tiles
    create_tile_airship_deck(os.path.join(BASE_PATH, "tile_airship_deck.png"))
    create_tile_sky_gap(os.path.join(BASE_PATH, "tile_sky_gap.png"))
    create_tile_mooring_stone(os.path.join(BASE_PATH, "tile_mooring_stone.png"))
    
    # 3. Environmental Sprites
    create_wind_gust(os.path.join(BASE_PATH, "wind_gust.png"))
    create_steam_vent(os.path.join(BASE_PATH, "steam_vent.png"))
    create_lightning_rod(os.path.join(BASE_PATH, "lightning_rod.png"))
    create_gangplank(os.path.join(BASE_PATH, "gangplank.png"))
    create_cargo_crane(os.path.join(BASE_PATH, "cargo_crane.png"))
    create_airship_tether(os.path.join(BASE_PATH, "airship_tether.png"))
    create_mooring_valve(os.path.join(BASE_PATH, "mooring_valve.png"))
    
    # 4. Enemy Sprites (6 enemies × 4 frames)
    enemies = [
        ("goblin_grunt", "goblin"),
        ("sneak_thief", "goblin"),
        ("debt_eternal", "undead"),
        ("jetstream_shepherd", "elemental"),
        ("pressure_knot", "elemental"),
        ("elemental_core", "elemental"),  # Boss — 3-phase handled via color in frames
    ]
    frames = ["idle", "attack", "damage", "death"]
    
    for enemy_name, faction in enemies:
        for frame in frames:
            output_path = os.path.join(BASE_PATH, f"enemy_{enemy_name}_{frame}.png")
            create_enemy_sprite(enemy_name, faction, frame, output_path)
    
    # 5. Shared Items
    create_anchor_point(os.path.join(BASE_PATH, "anchor_point.png"))
    create_cargo_crate(os.path.join(BASE_PATH, "cargo_crate.png"))
    create_aether_lens(os.path.join(BASE_PATH, "aether_lens.png"))
    
    # 6. Faction banners (for room decoration)
    for faction, color in [("elemental", (100, 180, 220)), ("undead", (120, 130, 140)), ("aberration", (140, 60, 180))]:
        img = Image.new('RGBA', (64, 96), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        # Banner cloth
        draw.polygon([(10, 10), (54, 10), (50, 80), (14, 80)], fill=(*color, 200), outline=(255, 255, 255, 150), width=2)
        # Pole
        draw.line([(10, 10), (10, 90)], fill=(150, 140, 130, 255), width=3)
        # Symbol
        sym = {"elemental": "E", "undead": "U", "aberration": "A"}[faction]
        font = get_font(14)
        bbox = draw.textbbox((0, 0), sym, font=font)
        tw = bbox[2] - bbox[0]
        draw.text(((64-tw)//2, 38), sym, fill=(255, 255, 255, 255), font=font)
        path = os.path.join(BASE_PATH, f"banner_{faction}.png")
        img.save(path)
        print(f"Created: {path}")
    
    print("\n=== FLOOR 5 ASSET GENERATION COMPLETE ===")
    print(f"All assets saved to: {BASE_PATH}")

if __name__ == "__main__":
    main()
