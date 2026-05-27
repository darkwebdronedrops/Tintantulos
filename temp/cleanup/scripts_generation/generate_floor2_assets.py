#!/usr/bin/env python3
"""Generate placeholder sprites for Floor 2 — The Fungal Cavern"""

from PIL import Image, ImageDraw, ImageFilter, ImageFont
import os
import math
import random

BASE_PATH = "/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites"
FLOOR2_DIR = os.path.join(BASE_PATH, "floor2")

def ensure_dir(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)

def get_font(size=8):
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size)
    except:
        return ImageFont.load_default()

# ============================================================================
# COLOR PALETTES
# ============================================================================
CAVE_DARK = (15, 8, 20)
CAVE_MID = (30, 18, 35)
CAVE_LIGHT = (50, 30, 55)
FUNGAL_PURPLE = (80, 40, 90)
FUNGAL_GREEN = (40, 70, 35)
FUNGAL_BROWN = (60, 45, 30)
BIOLUM_TEAL = (60, 180, 160)
BIOLUM_CYAN = (80, 200, 220)
BIOLUM_GOLD = (200, 180, 80)
STONE_GRAY = (55, 50, 45)
MOSS_GREEN = (50, 80, 40)
WATER_DEEP = (20, 60, 90)
WATER_SHALLOW = (40, 100, 140)
GLITCH_PINK = (220, 60, 180)
GLITCH_BLUE = (60, 120, 255)

def noise_color(base, variance=20):
    return tuple(min(255, max(0, c + random.randint(-variance, variance))) for c in base)

def draw_cave_wall(draw, x1, y1, x2, y2, color, segments=8):
    """Draw jagged cave wall edge"""
    w = x2 - x1
    h = y2 - y1
    points = []
    for i in range(segments + 1):
        t = i / segments
        px = x1 + w * t
        py = y1 + h * t + random.randint(-15, 15)
        points.append((px, py))
    # Close the polygon
    points.append((x2, y2))
    points.append((x1, y2))
    points.append((x1, y1))
    draw.polygon(points, fill=color)

# ============================================================================
# ROOM BACKGROUNDS
# ============================================================================

def create_room_bg(name, size, theme, output_path):
    """Create a large room background texture"""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, CAVE_DARK)
    draw = ImageDraw.Draw(img)
    w, h = size
    
    if theme == "entry":
        # Dramatic overlook with distant cavern glows
        # Base gradient - darker at top
        for y in range(h):
            darkness = int(255 * (y / h) * 0.3)
            color = (15 + darkness//3, 8 + darkness//5, 20 + darkness//4)
            draw.line([(0, y), (w, y)], fill=color)
        
        # Distant cavern layers
        for layer in range(5):
            ly = int(h * (0.2 + layer * 0.15))
            alpha = int(80 - layer * 12)
            color = (20 + layer*5, 12 + layer*3, 30 + layer*4, alpha)
            pts = []
            for i in range(20):
                px = int(w * (i / 19))
                py = ly + random.randint(-30, 30)
                pts.append((px, py))
            pts += [(w, ly+50), (0, ly+50)]
            draw.polygon(pts, fill=color)
        
        # Bioluminescent glows in distance
        glows = [(w*0.3, h*0.3, 80), (w*0.7, h*0.35, 100), (w*0.5, h*0.5, 120)]
        for gx, gy, gr in glows:
            for r in range(int(gr), 0, -5):
                alpha = int(30 * (1 - r/gr))
                draw.ellipse([gx-r, gy-r, gx+r, gy+r], fill=(60, 200, 180, alpha))
        
        # Fungal overlook platforms
        for px, py, pw, ph in [(w*0.2, h*0.55, w*0.15, 40), (w*0.6, h*0.6, w*0.2, 50), (w*0.4, h*0.75, w*0.25, 45)]:
            draw.polygon([(px, py), (px+pw, py), (px+pw+20, py+ph), (px-20, py+ph)], fill=FUNGAL_PURPLE + (200,))
            # Moss on edges
            for i in range(5):
                mx = px + random.randint(0, int(pw))
                my = py + random.randint(0, 10)
                draw.ellipse([mx-5, my-5, mx+5, my+5], fill=MOSS_GREEN + (180,))
    
    elif theme == "upper":
        # Dense fungal forest (The Rot Garden)
        for y in range(h):
            t = y / h
            r = int(20 + t * 30)
            g = int(10 + t * 20)
            b = int(25 + t * 15)
            draw.line([(0, y), (w, y)], fill=(r, g, b))
        
        # Dense fungal clusters
        for _ in range(40):
            fx = random.randint(0, w)
            fy = random.randint(h//4, h)
            fw = random.randint(40, 120)
            fh = random.randint(60, 200)
            color = noise_color(FUNGAL_PURPLE, 25)
            draw.polygon([(fx, fy), (fx+fw//2, fy-fh//3), (fx+fw, fy), (fx+fw//2, fy+fh)], fill=color)
        
        # Dead trees
        for _ in range(8):
            tx = random.randint(0, w)
            ty = random.randint(h//3, h)
            th = random.randint(80, 200)
            tw = random.randint(8, 16)
            draw.rectangle([tx-tw//2, ty-th, tx+tw//2, ty], fill=(35, 20, 15))
            # Branches
            for _ in range(3):
                bx = tx + random.randint(-30, 30)
                by = ty - random.randint(20, th-10)
                draw.line([(tx, by), (bx, by-random.randint(10, 30))], fill=(40, 25, 18), width=3)
        
        # Spore particles
        for _ in range(100):
            sx = random.randint(0, w)
            sy = random.randint(0, h)
            sr = random.randint(2, 6)
            alpha = random.randint(30, 80)
            draw.ellipse([sx-sr, sy-sr, sx+sr, sy+sr], fill=(180, 150, 200, alpha))
    
    elif theme == "middle":
        # The Grotto - vast pool with bioluminescence
        for y in range(h):
            t = y / h
            r = int(10 + t * 15)
            g = int(20 + t * 25)
            b = int(40 + t * 30)
            draw.line([(0, y), (w, y)], fill=(r, g, b))
        
        # Central pool
        px, py = w//2, int(h*0.55)
        pw, ph = int(w*0.5), int(h*0.3)
        for r in range(max(pw, ph), 0, -10):
            alpha = int(120 * (1 - r/max(pw, ph)))
            color = (30 + int(40*(1-r/max(pw,ph))), 80 + int(100*(1-r/max(pw,ph))), 120 + int(80*(1-r/max(pw,ph))), alpha)
            draw.ellipse([px-r, py-r//2, px+r, py+r//2], fill=color)
        
        # Stalactites
        for _ in range(12):
            sx = random.randint(0, w)
            sy = 0
            sh = random.randint(60, 180)
            sw = random.randint(10, 30)
            draw.polygon([(sx, sy), (sx+sw//2, sy+sh), (sx+sw, sy)], fill=STONE_GRAY + (220,))
            # Glow tip
            draw.ellipse([sx+sw//2-4, sy+sh-8, sx+sw//2+4, sy+sh], fill=BIOLUM_TEAL + (180,))
        
        # Stalagmites
        for _ in range(8):
            sx = random.randint(0, w)
            sy = h
            sh = random.randint(40, 120)
            sw = random.randint(12, 28)
            draw.polygon([(sx, sy), (sx+sw//2, sy-sh), (sx+sw, sy)], fill=STONE_GRAY + (200,))
        
        # Waterfall
        wx = int(w * 0.2)
        for y in range(0, int(h*0.6), 3):
            alpha = int(100 + 50 * math.sin(y * 0.1))
            draw.line([(wx + random.randint(-5, 5), y), (wx + random.randint(-5, 5), y+3)], fill=(60, 150, 200, alpha), width=4)
    
    elif theme == "lower":
        # Overgrown Excavation - sprawling gears/tunnels
        for y in range(h):
            t = y / h
            r = int(25 + t * 20)
            g = int(20 + t * 15)
            b = int(15 + t * 10)
            draw.line([(0, y), (w, y)], fill=(r, g, b))
        
        # Large gears overgrown with fungus
        for _ in range(6):
            gx = random.randint(100, w-100)
            gy = random.randint(100, h-100)
            gr = random.randint(40, 100)
            teeth = random.randint(6, 10)
            gear_pts = []
            for i in range(teeth * 2):
                angle = (360 / (teeth * 2)) * i
                rad = math.radians(angle)
                r = gr if i % 2 == 0 else gr * 0.7
                gear_pts.append((gx + r * math.cos(rad), gy + r * math.sin(rad)))
            draw.polygon(gear_pts, fill=(80, 65, 45, 220), outline=(120, 100, 70, 255), width=2)
            draw.ellipse([gx-15, gy-15, gx+15, gy+15], fill=(60, 50, 35, 255))
            
            # Fungal overgrowth on gear
            for _ in range(5):
                fx = gx + random.randint(-gr, gr)
                fy = gy + random.randint(-gr, gr)
                fr = random.randint(8, 20)
                color = noise_color(FUNGAL_GREEN if random.random() > 0.5 else FUNGAL_PURPLE, 15)
                draw.ellipse([fx-fr, fy-fr, fx+fr, fy+fr], fill=color + (180,))
        
        # Tunnel entrances
        for tx in [int(w*0.15), int(w*0.85)]:
            ty = int(h * 0.85)
            draw.polygon([(tx-60, ty-40), (tx+60, ty-40), (tx+80, ty+60), (tx-80, ty+60)], fill=(20, 15, 12, 255))
            # Dark tunnel interior
            draw.polygon([(tx-40, ty-20), (tx+40, ty-20), (tx+50, ty+40), (tx-50, ty+40)], fill=(10, 8, 6, 255))
    
    elif theme == "secret":
        # The Mycelial Glitch - corrupted digital-fungal hybrid
        for y in range(h):
            t = y / h
            r = int(30 + t * 20)
            g = int(15 + t * 10)
            b = int(40 + t * 15)
            draw.line([(0, y), (w, y)], fill=(r, g, b))
        
        # Glitch blocks
        for _ in range(30):
            bx = random.randint(0, w)
            by = random.randint(0, h)
            bw = random.randint(20, 80)
            bh = random.randint(10, 40)
            color = random.choice([GLITCH_PINK, GLITCH_BLUE, (180, 80, 220)])
            alpha = random.randint(60, 150)
            draw.rectangle([bx, by, bx+bw, by+bh], fill=color + (alpha,))
        
        # Corrupted fungal patches
        for _ in range(15):
            fx = random.randint(0, w)
            fy = random.randint(0, h)
            fr = random.randint(15, 40)
            draw.ellipse([fx-fr, fy-fr, fx+fr, fy+fr], fill=(120, 50, 100, 160))
            # Pixelated edges
            for _ in range(4):
                px = fx + random.randint(-fr, fr)
                py = fy + random.randint(-fr, fr)
                draw.rectangle([px, py, px+8, py+8], fill=(80, 30, 70, 200))
        
        # Scanlines
        for y in range(0, h, 4):
            draw.line([(0, y), (w, y)], fill=(0, 0, 0, 30))
    
    elif theme == "spore_heart":
        # Boss arena - grand fungal throne
        for y in range(h):
            t = y / h
            r = int(12 + t * 15)
            g = int(20 + t * 20)
            b = int(12 + t * 10)
            draw.line([(0, y), (w, y)], fill=(r, g, b))
        
        # Arena floor - glowing fungal circle
        cx, cy = w//2, int(h*0.6)
        for r in range(int(w*0.45), 0, -15):
            alpha = int(40 * (1 - r/(w*0.45)))
            glow = int(60 * (1 - r/(w*0.45)))
            draw.ellipse([cx-r, cy-r*0.5, cx+r, cy+r*0.5], fill=(20+glow, 50+glow, 15+glow, alpha))
        
        # Throne
        tx, ty = w//2, int(h*0.35)
        # Throne base
        draw.polygon([(tx-80, ty+80), (tx+80, ty+80), (tx+100, ty+160), (tx-100, ty+160)], fill=(40, 70, 30, 255))
        # Throne back
        draw.polygon([(tx-100, ty-60), (tx+100, ty-60), (tx+80, ty+80), (tx-80, ty+80)], fill=(50, 90, 40, 255))
        # Throne glow
        for r in range(60, 0, -5):
            alpha = int(50 * (1 - r/60))
            draw.ellipse([tx-r, ty-r*0.3, tx+r, ty+r*0.3], fill=(60, 200, 50, alpha))
        
        # Four pillars
        for px, py in [(int(w*0.15), int(h*0.3)), (int(w*0.85), int(h*0.3)), (int(w*0.15), int(h*0.75)), (int(w*0.85), int(h*0.75))]:
            draw.rectangle([px-30, py-100, px+30, py+100], fill=(25, 45, 20, 255))
            # Pillar glow
            draw.ellipse([px-15, py-80, px+15, py+80], fill=(40, 100, 35, 120))
        
        # Cavern ceiling
        pts = [(-50, -50), (w+50, -50), (w, 80), (w*0.7, 120), (w*0.5, 90), (w*0.3, 110), (0, 80)]
        draw.polygon(pts, fill=(10, 15, 10, 255))
        
        # Floating spores
        for _ in range(80):
            sx = random.randint(0, w)
            sy = random.randint(0, h)
            sr = random.randint(2, 5)
            alpha = random.randint(40, 100)
            draw.ellipse([sx-sr, sy-sr, sx+sr, sy+sr], fill=(100, 200, 80, alpha))
    
    img.save(output_path)
    print(f"Created bg: {output_path}")

# ============================================================================
# ENVIRONMENTAL SPRITES
# ============================================================================

def create_mushroom(output_path, size=(80, 120), cap_color=FUNGAL_PURPLE, glow=False):
    """Glowing mushroom sprite"""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    w, h = size
    
    # Stem
    stem_w = w // 4
    draw.polygon([(w//2-stem_w//2, h//3), (w//2+stem_w//2, h//3), (w//2+stem_w//3, h-5), (w//2-stem_w//3, h-5)], fill=(180, 160, 140, 255))
    
    # Cap
    cap_h = h // 2
    cap_w = w // 2 + 5
    draw.polygon([(w//2-cap_w, h//3), (w//2+cap_w, h//3), (w//2+cap_w//2, h//3-cap_h), (w//2-cap_w//2, h//3-cap_h)], fill=cap_color + (255,))
    
    # Spots on cap
    for _ in range(3):
        sx = w//2 + random.randint(-cap_w//2, cap_w//2)
        sy = h//3 - random.randint(5, cap_h-5)
        sr = random.randint(3, 6)
        draw.ellipse([sx-sr, sy-sr, sx+sr, sy+sr], fill=(200, 180, 200, 180))
    
    if glow:
        # Bioluminescent glow at base
        for r in range(20, 0, -3):
            alpha = int(40 * (1 - r/20))
            draw.ellipse([w//2-r, h-15-r//2, w//2+r, h-15+r//2], fill=BIOLUM_TEAL + (alpha,))
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_stalactite(output_path, size=(40, 120), has_glow=True):
    """Cave stalactite hanging from ceiling"""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    w, h = size
    
    draw.polygon([(0, 0), (w, 0), (w*0.6, h), (w*0.4, h)], fill=STONE_GRAY + (230,))
    # Texture lines
    for i in range(3):
        x = int(w * (0.3 + i * 0.2))
        draw.line([(x, 5), (x+3, h-5)], fill=(70, 65, 60, 150), width=2)
    
    if has_glow:
        # Glowing tip
        draw.ellipse([w*0.4-5, h-10, w*0.6+5, h+2], fill=BIOLUM_CYAN + (200,))
        for r in range(15, 0, -3):
            alpha = int(30 * (1 - r/15))
            draw.ellipse([w//2-r, h-5-r, w//2+r, h-5+r], fill=BIOLUM_CYAN + (alpha,))
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_spore_cloud(output_path, size=(200, 100)):
    """Floating spore cloud"""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    w, h = size
    
    for _ in range(30):
        cx = random.randint(0, w)
        cy = random.randint(0, h)
        cr = random.randint(10, 30)
        alpha = random.randint(20, 60)
        color = random.choice([FUNGAL_PURPLE, FUNGAL_GREEN, (150, 120, 160)])
        draw.ellipse([cx-cr, cy-cr, cx+cr, cy+cr], fill=color + (alpha,))
    
    # Small bright spores
    for _ in range(50):
        sx = random.randint(0, w)
        sy = random.randint(0, h)
        sr = random.randint(1, 3)
        alpha = random.randint(80, 180)
        draw.ellipse([sx-sr, sy-sr, sx+sr, sy+sr], fill=(220, 200, 240, alpha))
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_water_pool(output_path, size=(300, 150)):
    """Glowing water pool surface"""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    w, h = size
    
    for y in range(h):
        t = y / h
        alpha = int(120 * (1 - t * 0.5))
        r = int(20 + t * 20)
        g = int(60 + t * 40)
        b = int(100 + t * 30)
        draw.line([(0, y), (w, y)], fill=(r, g, b, alpha))
    
    # Surface shimmer
    for _ in range(20):
        sx = random.randint(0, w)
        sy = random.randint(0, h//2)
        sw = random.randint(20, 60)
        alpha = random.randint(40, 100)
        draw.line([(sx, sy), (sx+sw, sy+2)], fill=(120, 200, 220, alpha), width=2)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_gear_overgrown(output_path, size=(120, 120)):
    """Overgrown gear with fungus"""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    w, h = size
    center = w // 2
    
    teeth = 8
    outer_r = w // 2 - 5
    inner_r = w // 2 - 20
    gear_pts = []
    for i in range(teeth * 2):
        angle = (360 / (teeth * 2)) * i
        rad = math.radians(angle)
        r = outer_r if i % 2 == 0 else inner_r
        gear_pts.append((center + r * math.cos(rad), center + r * math.sin(rad)))
    
    draw.polygon(gear_pts, fill=(100, 80, 55, 230), outline=(140, 115, 80, 255), width=2)
    draw.ellipse([center-12, center-12, center+12, center+12], fill=(80, 65, 45, 255))
    
    # Fungal growth patches
    for _ in range(6):
        fx = center + random.randint(-outer_r, outer_r)
        fy = center + random.randint(-outer_r, outer_r)
        fr = random.randint(8, 18)
        color = noise_color(FUNGAL_GREEN, 20) if random.random() > 0.4 else noise_color(FUNGAL_PURPLE, 20)
        draw.ellipse([fx-fr, fy-fr, fx+fr, fy+fr], fill=color + (200,))
    
    # Moss tendrils
    for _ in range(4):
        x0 = center + random.randint(-outer_r, outer_r)
        y0 = center + random.randint(-outer_r, outer_r)
        length = random.randint(15, 30)
        angle = random.uniform(0, math.pi*2)
        x1 = x0 + length * math.cos(angle)
        y1 = y0 + length * math.sin(angle)
        draw.line([(x0, y0), (x1, y1)], fill=(50, 90, 40, 200), width=3)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_faction_banner(output_path, faction, size=(48, 96)):
    """Faction banner on pole"""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    w, h = size
    
    colors = {
        'undead': (100, 120, 100),
        'elemental': (60, 150, 200),
        'construct': (160, 130, 80),
    }
    base_color = colors.get(faction, (128, 128, 128))
    
    # Pole
    draw.rectangle([w//2-2, 0, w//2+2, h], fill=(80, 70, 60, 255))
    
    # Banner cloth
    banner_w = w - 8
    banner_h = int(h * 0.5)
    draw.polygon([
        (4, 5), (w-4, 5), (w-4, banner_h), (4, banner_h),
        (8, banner_h+5), (w-8, banner_h-5)
    ], fill=base_color + (240,))
    
    # Faction symbol
    symbol = {'undead': 'U', 'elemental': 'E', 'construct': 'C'}.get(faction, '?')
    font = get_font(12)
    bbox = draw.textbbox((0, 0), symbol, font=font)
    tw = bbox[2] - bbox[0]
    draw.text(((w-tw)//2, banner_h//2 - 6), symbol, fill=(255, 255, 255, 255), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_portal(output_path, portal_type, size=(80, 100)):
    """Portal sprite - cavern entrance or fungal passage"""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    w, h = size
    
    if portal_type == "cavern":
        # Rock archway
        draw.polygon([(10, h), (w-10, h), (w-5, h//3), (w//2+10, 5), (w//2-10, 5), (5, h//3)], fill=(40, 35, 30, 255))
        # Dark interior
        draw.polygon([(15, h-5), (w-15, h-5), (w-10, h//3+5), (w//2+5, 10), (w//2-5, 10), (10, h//3+5)], fill=(15, 10, 8, 255))
    elif portal_type == "fungal":
        # Glowing fungal passage
        draw.polygon([(5, h), (w-5, h), (w-3, h//2), (w//2+8, 3), (w//2-8, 3), (3, h//2)], fill=(50, 35, 60, 255))
        # Inner glow
        for r in range(w//2, 0, -5):
            alpha = int(60 * (1 - r/(w//2)))
            draw.ellipse([w//2-r, h//2-r, w//2+r, h//2+r], fill=BIOLUM_TEAL + (alpha,))
        draw.ellipse([w//2-15, h//2-15, w//2+15, h//2+15], fill=(100, 220, 200, 200))
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_elevator_part(output_path, part_name, size=(48, 48)):
    """Gear part for elevator collection"""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    w, h = size
    center = w // 2
    
    if "gear" in part_name.lower():
        teeth = 6
        outer_r = w // 2 - 4
        inner_r = w // 2 - 12
        gear_pts = []
        for i in range(teeth * 2):
            angle = (360 / (teeth * 2)) * i
            rad = math.radians(angle)
            r = outer_r if i % 2 == 0 else inner_r
            gear_pts.append((center + r * math.cos(rad), center + r * math.sin(rad)))
        draw.polygon(gear_pts, fill=(184, 134, 11, 255), outline=(218, 165, 32, 255), width=2)
        draw.ellipse([center-6, center-6, center+6, center+6], fill=(139, 90, 43, 255))
    elif "valve" in part_name.lower():
        draw.ellipse([4, 4, w-4, h-4], fill=(150, 150, 160, 255), outline=(200, 200, 210, 255), width=2)
        draw.line([(center, 4), (center, h-4)], fill=(180, 180, 190, 255), width=3)
        draw.line([(4, center), (w-4, center)], fill=(180, 180, 190, 255), width=3)
    else:
        draw.rectangle([8, 8, w-8, h-8], fill=(184, 134, 11, 255), outline=(218, 165, 32, 255), width=2)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_floor_tile(output_path, tile_type, size=64):
    """Floor tile for floor2"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    if tile_type == "fungal_hex":
        center = size // 2
        radius = size // 2 - 2
        points = []
        for i in range(6):
            angle = 60 * i - 30
            x = center + radius * 0.9 * math.cos(math.radians(angle))
            y = center + radius * 0.9 * math.sin(math.radians(angle))
            points.append((x, y))
        
        base = noise_color((65, 40, 70), 15)
        draw.polygon(points, fill=base, outline=(90, 60, 100, 255), width=2)
        # Fungal spot
        draw.ellipse([center-8, center-8, center+8, center+8], fill=(80, 55, 90, 200))
    
    elif tile_type == "cavern_stone":
        base = noise_color(STONE_GRAY, 15)
        draw.rectangle([2, 2, size-2, size-2], fill=base, outline=(75, 70, 65, 255), width=2)
        # Crack
        draw.line([(5, size//2), (size-5, size//2+5)], fill=(40, 35, 30, 200), width=2)
    
    elif tile_type == "mossy_platform":
        base = noise_color((55, 75, 50), 15)
        draw.rectangle([2, 2, size-2, size-2], fill=base, outline=(70, 95, 60, 255), width=2)
        # Moss patches
        for _ in range(3):
            mx = random.randint(8, size-8)
            my = random.randint(8, size-8)
            mr = random.randint(4, 8)
            draw.ellipse([mx-mr, my-mr, mx+mr, my+mr], fill=(70, 110, 55, 180))
    
    img.save(output_path)
    print(f"Created: {output_path}")

# ============================================================================
# ENEMY SPRITES
# ============================================================================

def create_enemy_sprite(name, faction, frame_type, output_path, size=64):
    """Create enemy animation frame"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    colors = {
        'undead': (80, 50, 60),      # Rot brown/purple
        'elemental': (60, 120, 180),   # Water blue
        'construct': (139, 90, 43),   # Bronze
    }
    base_color = colors.get(faction, (100, 100, 100))
    
    if frame_type == 'idle':
        offset_y = 0
        intensity = 1.0
    elif frame_type == 'attack':
        offset_y = -3
        intensity = 1.3
    elif frame_type == 'damage':
        offset_y = 0
        intensity = 0.7
        base_color = (255, 100, 100)
    elif frame_type == 'death':
        offset_y = 5
        intensity = 0.5
        base_color = (50, 50, 50)
    else:
        offset_y = 0
        intensity = 1.0
    
    center = size // 2
    
    if name == "flesh_debt":
        # Zombie-like with fungal growth
        body_color = tuple(min(255, int(c * intensity)) for c in base_color)
        # Body
        draw.ellipse([center-18, center-15+offset_y, center+18, center+20+offset_y], fill=body_color, outline=(120, 80, 90, 200), width=2)
        # Head
        draw.ellipse([center-12, center-30+offset_y, center+12, center-8+offset_y], fill=(100, 70, 75, 255), outline=(130, 90, 100, 200), width=2)
        # Fungal spots
        for _ in range(4):
            fx = center + random.randint(-10, 10)
            fy = center + random.randint(-15, 10) + offset_y
            fr = random.randint(3, 6)
            draw.ellipse([fx-fr, fy-fr, fx+fr, fy+fr], fill=(60, 120, 50, 180))
        # Eyes
        eye_color = (180, 220, 100) if frame_type != 'death' else (80, 80, 80)
        draw.ellipse([center-7, center-22+offset_y, center-3, center-16+offset_y], fill=eye_color)
        draw.ellipse([center+3, center-22+offset_y, center+7, center-16+offset_y], fill=eye_color)
        # Mouth
        draw.arc([center-8, center-18+offset_y, center+8, center-8+offset_y], start=0, end=180, fill=(150, 100, 100, 200), width=2)
    
    elif name == "flesh_crawler":
        # Crawling mass of limbs
        body_color = tuple(min(255, int(c * intensity)) for c in base_color)
        # Main mass
        draw.ellipse([center-14, center-8+offset_y, center+14, center+18+offset_y], fill=body_color, outline=(100, 70, 80, 200), width=2)
        # Crawling limbs
        for angle in [30, 90, 150, 210, 270, 330]:
            rad = math.radians(angle)
            x0 = center + 12 * math.cos(rad)
            y0 = center + 12 * math.sin(rad) + offset_y
            x1 = center + 22 * math.cos(rad)
            y1 = center + 22 * math.sin(rad) + offset_y
            draw.line([(x0, y0), (x1, y1)], fill=(90, 60, 70, 200), width=3)
        # Eye cluster
        for _ in range(3):
            ex = center + random.randint(-6, 6)
            ey = center + random.randint(-4, 4) + offset_y
            draw.ellipse([ex-2, ey-2, ex+2, ey+2], fill=(200, 80, 80, 255) if frame_type != 'death' else (80, 80, 80, 255))
    
    elif name == "forgetful_wound":
        # Open wound that won't close
        body_color = tuple(min(255, int(c * intensity)) for c in base_color)
        # Body shape
        draw.polygon([
            (center, center-25+offset_y),
            (center+20, center+offset_y),
            (center, center+25+offset_y),
            (center-20, center+offset_y)
        ], fill=body_color, outline=(120, 70, 80, 200), width=2)
        # The wound - open gash
        wound_color = (180, 40, 40, 220) if frame_type != 'death' else (60, 60, 60, 200)
        draw.polygon([
            (center, center-12+offset_y),
            (center+8, center+offset_y),
            (center, center+15+offset_y),
            (center-8, center+offset_y)
        ], fill=wound_color)
        # Bleeding edges / fungal threads
        for _ in range(5):
            x0 = center + random.randint(-6, 6)
            y0 = center + random.randint(-10, 10) + offset_y
            length = random.randint(5, 15)
            angle = random.uniform(0, math.pi*2)
            x1 = x0 + length * math.cos(angle)
            y1 = y0 + length * math.sin(angle)
            draw.line([(x0, y0), (x1, y1)], fill=(160, 50, 50, 180), width=2)
        # Eye - one big one
        draw.ellipse([center-5, center-20+offset_y, center+5, center-12+offset_y], fill=(200, 200, 150, 255) if frame_type != 'death' else (80, 80, 80, 255))
    
    elif name == "flesh_garden":
        # Boss - amalgamation of fungal decay
        body_color = tuple(min(255, int(c * intensity)) for c in base_color)
        # Large irregular mass
        pts = []
        for angle in range(0, 360, 20):
            rad = math.radians(angle)
            r = 22 + random.randint(-5, 8)
            pts.append((center + r * math.cos(rad), center + r * math.sin(rad) + offset_y))
        draw.polygon(pts, fill=body_color, outline=(100, 70, 80, 200), width=2)
        
        # Garden features - smaller growths
        for _ in range(6):
            gx = center + random.randint(-18, 18)
            gy = center + random.randint(-18, 18) + offset_y
            gr = random.randint(5, 10)
            color = random.choice([FUNGAL_GREEN, FUNGAL_PURPLE, (100, 60, 50)])
            draw.ellipse([gx-gr, gy-gr, gx+gr, gy+gr], fill=color + (200,))
        
        # Central eye
        draw.ellipse([center-8, center-8+offset_y, center+8, center+8+offset_y], fill=(180, 220, 100, 255) if frame_type != 'death' else (80, 80, 80, 255))
        draw.ellipse([center-3, center-3+offset_y, center+3, center+3+offset_y], fill=(50, 30, 30, 255))
        
        # Crown of mushrooms
        for angle in [45, 135, 225, 315]:
            rad = math.radians(angle)
            mx = center + 18 * math.cos(rad)
            my = center + 18 * math.sin(rad) + offset_y
            draw.polygon([(mx-5, my), (mx+5, my), (mx+7, my-10), (mx-7, my-10)], fill=FUNGAL_PURPLE + (220,))
    
    else:
        # Generic fallback
        body_color = tuple(min(255, int(c * intensity)) for c in base_color)
        draw.ellipse([center-15, center-15+offset_y, center+15, center+15+offset_y], fill=body_color, outline=(255, 255, 255, 150), width=2)
        eye_color = (255, 255, 0) if frame_type != 'death' else (100, 100, 100)
        draw.ellipse([center-6, center-6+offset_y, center-2, center-2+offset_y], fill=eye_color)
        draw.ellipse([center+2, center-6+offset_y, center+6, center-2+offset_y], fill=eye_color)
    
    img.save(output_path)
    print(f"Created enemy: {output_path}")

# ============================================================================
# MAIN
# ============================================================================

def main():
    os.makedirs(FLOOR2_DIR, exist_ok=True)
    os.makedirs(os.path.join(BASE_PATH, "enemies", "Undead"), exist_ok=True)
    
    print("=== Generating Floor 2 Assets ===\n")
    
    # 1. Room backgrounds
    create_room_bg("entry", (3120, 1400), "entry", os.path.join(FLOOR2_DIR, "bg_entry.png"))
    create_room_bg("upper", (2720, 1600), "upper", os.path.join(FLOOR2_DIR, "bg_upper.png"))
    create_room_bg("middle", (2200, 1600), "middle", os.path.join(FLOOR2_DIR, "bg_middle.png"))
    create_room_bg("lower", (2320, 1600), "lower", os.path.join(FLOOR2_DIR, "bg_lower.png"))
    create_room_bg("secret", (1920, 1080), "secret", os.path.join(FLOOR2_DIR, "bg_secret.png"))
    create_room_bg("spore_heart", (2400, 1600), "spore_heart", os.path.join(FLOOR2_DIR, "bg_spore_heart.png"))
    
    # 2. Floor tiles
    create_floor_tile(os.path.join(FLOOR2_DIR, "tile_fungal_hex.png"), "fungal_hex")
    create_floor_tile(os.path.join(FLOOR2_DIR, "tile_cavern_stone.png"), "cavern_stone")
    create_floor_tile(os.path.join(FLOOR2_DIR, "tile_mossy_platform.png"), "mossy_platform")
    
    # 3. Environmental sprites
    create_mushroom(os.path.join(FLOOR2_DIR, "mushroom_giant.png"), (100, 140), FUNGAL_PURPLE, glow=True)
    create_mushroom(os.path.join(FLOOR2_DIR, "mushroom_small.png"), (60, 80), FUNGAL_GREEN, glow=False)
    create_stalactite(os.path.join(FLOOR2_DIR, "stalactite.png"), (40, 100), True)
    create_spore_cloud(os.path.join(FLOOR2_DIR, "spore_cloud.png"), (200, 100))
    create_water_pool(os.path.join(FLOOR2_DIR, "water_pool.png"), (300, 150))
    create_gear_overgrown(os.path.join(FLOOR2_DIR, "gear_overgrown.png"), (120, 120))
    
    # 4. Faction banners
    create_faction_banner(os.path.join(FLOOR2_DIR, "banner_undead.png"), "undead")
    create_faction_banner(os.path.join(FLOOR2_DIR, "banner_elemental.png"), "elemental")
    create_faction_banner(os.path.join(FLOOR2_DIR, "banner_construct.png"), "construct")
    
    # 5. Portals
    create_portal(os.path.join(FLOOR2_DIR, "portal_cavern.png"), "cavern")
    create_portal(os.path.join(FLOOR2_DIR, "portal_fungal.png"), "fungal")
    
    # 6. Elevator parts
    create_elevator_part(os.path.join(FLOOR2_DIR, "elevator_gear.png"), "gear")
    create_elevator_part(os.path.join(FLOOR2_DIR, "elevator_valve.png"), "valve")
    create_elevator_part(os.path.join(FLOOR2_DIR, "elevator_brass.png"), "brass")
    
    # 7. Enemy sprites
    for frame in ['idle', 'attack', 'damage', 'death']:
        create_enemy_sprite("flesh_debt", "undead", frame, os.path.join(BASE_PATH, "enemies", "Undead", f"enemy_flesh_debt_{frame}.png"))
        create_enemy_sprite("flesh_crawler", "undead", frame, os.path.join(BASE_PATH, "enemies", "Undead", f"enemy_flesh_crawler_{frame}.png"))
        create_enemy_sprite("forgetful_wound", "undead", frame, os.path.join(BASE_PATH, "enemies", "Undead", f"enemy_forgetful_wound_{frame}.png"))
        create_enemy_sprite("flesh_garden", "undead", frame, os.path.join(BASE_PATH, "enemies", "Undead", f"boss_the_flesh_garden_{frame}.png"))
    
    print("\n=== FLOOR 2 ASSET GENERATION COMPLETE ===")
    print(f"All assets saved to: {FLOOR2_DIR}")

if __name__ == "__main__":
    main()
