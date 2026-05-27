#!/usr/bin/env python3
"""Generate placeholder sprites for Floor 4 — The Curio Bazaar"""

from PIL import Image, ImageDraw, ImageFont
import os
import math

BASE_PATH = "/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites"

def ensure_dir(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)

def get_font(size=8):
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size)
    except:
        return ImageFont.load_default()

def create_hex_tile(color, label, output_path, size=64, secondary_color=None):
    """Create a hexagonal tile with label"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    radius = size // 2 - 2
    points = []
    for i in range(6):
        angle = 60 * i - 30
        x = center + radius * 0.9 * math.cos(math.radians(angle))
        y = center + radius * 0.9 * math.sin(math.radians(angle))
        points.append((x, y))
    
    if secondary_color:
        draw.polygon(points, fill=color)
        for i in range(3):
            inset = radius * 0.3 * (i + 1)
            inner_points = []
            for j in range(6):
                angle = 60 * j - 30
                x = center + inset * math.cos(math.radians(angle))
                y = center + inset * math.sin(math.radians(angle))
                inner_points.append((x, y))
            draw.polygon(inner_points, outline=secondary_color, width=1)
    else:
        draw.polygon(points, fill=color)
    
    draw.polygon(points, outline=(255, 255, 255, 200), width=2)
    
    font = get_font(8)
    bbox = draw.textbbox((0, 0), label, font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (size - text_width) // 2
    text_y = size // 2 - 4
    draw.text((text_x, text_y), label, fill=(255, 255, 255, 255), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_brass_hex_tile(label, output_path, size=64):
    """Brass-market hex tile with gear pattern"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    radius = size // 2 - 2
    
    brass = (184, 134, 11, 220)
    dark_brass = (139, 90, 43, 255)
    
    points = []
    for i in range(6):
        angle = 60 * i - 30
        x = center + radius * 0.9 * math.cos(math.radians(angle))
        y = center + radius * 0.9 * math.sin(math.radians(angle))
        points.append((x, y))
    
    draw.polygon(points, fill=brass, outline=(218, 165, 32, 255), width=2)
    
    teeth = 6
    for i in range(teeth * 2):
        angle = (360 / (teeth * 2)) * i
        rad = math.radians(angle)
        if i % 2 == 0:
            r_out = radius * 0.5
        else:
            r_out = radius * 0.35
        x1 = center + r_out * math.cos(rad)
        y1 = center + r_out * math.sin(rad)
        if i > 0:
            draw.line([(x0, y0), (x1, y1)], fill=dark_brass, width=2)
        x0, y0 = x1, y1
    angle = 0
    rad = math.radians(angle)
    r_out = radius * 0.5
    x1 = center + r_out * math.cos(rad)
    y1 = center + r_out * math.sin(rad)
    draw.line([(x0, y0), (x1, y1)], fill=dark_brass, width=2)
    
    draw.ellipse([center - 6, center - 6, center + 6, center + 6], fill=(218, 165, 32, 255))
    
    font = get_font(8)
    bbox = draw.textbbox((0, 0), label, font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (size - text_width) // 2
    text_y = size // 2 - 4
    draw.text((text_x, text_y), label, fill=(255, 255, 255, 255), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_dark_pipe_tile(label, output_path, size=64):
    """Dark pipe tunnel hex tile"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    radius = size // 2 - 2
    
    dark = (40, 40, 55, 230)
    pipe = (60, 60, 75, 255)
    
    points = []
    for i in range(6):
        angle = 60 * i - 30
        x = center + radius * 0.9 * math.cos(math.radians(angle))
        y = center + radius * 0.9 * math.sin(math.radians(angle))
        points.append((x, y))
    
    draw.polygon(points, fill=dark, outline=(80, 80, 100, 255), width=2)
    
    draw.rectangle([center - radius*0.6, center - 3, center + radius*0.6, center + 3], fill=pipe, outline=(100, 100, 120, 255), width=1)
    draw.rectangle([center - 3, center - radius*0.6, center + 3, center + radius*0.6], fill=pipe, outline=(100, 100, 120, 255), width=1)
    
    for ox in [-radius*0.4, radius*0.4]:
        draw.ellipse([center + ox - 2, center - radius*0.6 - 2, center + ox + 2, center - radius*0.6 + 2], fill=(120, 120, 140, 255))
    
    font = get_font(7)
    bbox = draw.textbbox((0, 0), label, font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (size - text_width) // 2
    text_y = size // 2 - 3
    draw.text((text_x, text_y), label, fill=(150, 150, 170, 255), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_refectory_tile(label, output_path, size=64):
    """Brass dining hex tile"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    radius = size // 2 - 2
    
    brass = (160, 130, 80, 220)
    plate = (200, 180, 140, 255)
    
    points = []
    for i in range(6):
        angle = 60 * i - 30
        x = center + radius * 0.9 * math.cos(math.radians(angle))
        y = center + radius * 0.9 * math.sin(math.radians(angle))
        points.append((x, y))
    
    draw.polygon(points, fill=brass, outline=(180, 160, 110, 255), width=2)
    
    draw.ellipse([center - 10, center - 10, center + 10, center + 10], fill=plate, outline=(140, 120, 80, 255), width=1)
    draw.line([(center - 15, center + 8), (center - 8, center + 8)], fill=(180, 160, 110, 255), width=2)
    draw.line([(center + 8, center + 8), (center + 15, center + 8)], fill=(180, 160, 110, 255), width=2)
    
    font = get_font(7)
    bbox = draw.textbbox((0, 0), label, font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (size - text_width) // 2
    text_y = size // 2 - 3
    draw.text((text_x, text_y), label, fill=(255, 255, 240, 255), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_great_lifter(output_path, size=128):
    """Center elevator — brass/bronze elevator with gear"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    
    draw.rounded_rectangle([10, 10, size-10, size-10], radius=8, fill=(139, 90, 43, 255), outline=(184, 134, 11, 255), width=3)
    draw.rounded_rectangle([20, 20, size-20, size-20], radius=4, fill=(100, 70, 30, 255), outline=(160, 120, 50, 255), width=2)
    
    teeth = 8
    outer_r = 30
    inner_r = 22
    gear_points = []
    for i in range(teeth * 2):
        angle = (360 / (teeth * 2)) * i
        rad = math.radians(angle)
        if i % 2 == 0:
            r = outer_r
        else:
            r = inner_r
        x = center + r * math.cos(rad)
        y = center + r * math.sin(rad)
        gear_points.append((x, y))
    
    draw.polygon(gear_points, fill=(184, 134, 11, 255), outline=(218, 165, 32, 255), width=2)
    draw.ellipse([center - 10, center - 10, center + 10, center + 10], fill=(139, 90, 43, 255))
    
    light_color = (255, 80, 80, 255)
    draw.ellipse([center - 5, 28, center + 5, 38], fill=light_color, outline=(255, 150, 150, 255), width=1)
    
    font = get_font(10)
    bbox = draw.textbbox((0, 0), "LIFTER", font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (size - text_width) // 2
    draw.text((text_x, size - 28), "LIFTER", fill=(255, 215, 0, 255), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_aether_slick(output_path, size=64):
    """Purple iridescent Aether Slick zone"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    for y in range(size):
        for x in range(size):
            dist = math.sqrt((x - size/2)**2 + (y - size/2)**2)
            if dist < size/2 - 2:
                shimmer = int(50 + 30 * math.sin(x * 0.5) * math.cos(y * 0.5))
                alpha = int(120 + 40 * math.sin(dist * 0.3))
                img.putpixel((x, y), (120, 50, 180, alpha))
    
    center = size // 2
    draw.ellipse([2, 2, size-2, size-2], outline=(180, 100, 255, 200), width=2)
    
    font = get_font(7)
    bbox = draw.textbbox((0, 0), "SLICK", font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (size - text_width) // 2
    text_y = size // 2 - 3
    draw.text((text_x, text_y), "SLICK", fill=(220, 180, 255, 255), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_booth_exterior(name, is_real, output_path, size=64):
    """Booth exterior marker — real vendors bigger, traps smaller"""
    ensure_dir(output_path)
    
    if is_real:
        size = 80
    else:
        size = 48
    
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    
    if is_real:
        color = (184, 134, 11, 230)
        outline = (218, 165, 32, 255)
        accent = (139, 90, 43, 255)
        draw.polygon([(center, 5), (size-5, center-5), (center, center-5), (5, center-5)], fill=color, outline=outline, width=2)
        draw.rectangle([10, center-5, size-10, size-8], fill=accent, outline=outline, width=2)
    else:
        color = (60, 55, 70, 200)
        outline = (100, 90, 120, 255)
        accent = (40, 35, 50, 255)
        draw.rectangle([5, 5, size-5, size-5], fill=color, outline=outline, width=2)
        for i in range(3):
            y = 12 + i * 12
            draw.line([(8, y), (size-8, y)], fill=(120, 50, 180, 150), width=1)
    
    font = get_font(7)
    short_name = name[:8]
    bbox = draw.textbbox((0, 0), short_name, font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (size - text_width) // 2
    text_y = size // 2 - 3
    draw.text((text_x, text_y), short_name, fill=(255, 255, 255, 255), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_vendor_interior(vendor_name, output_path, size=(256, 192)):
    """Vendor interior scene background"""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (30, 25, 20, 255))
    draw = ImageDraw.Draw(img)
    
    w, h = size
    
    draw.rectangle([0, h*0.7, w, h], fill=(60, 50, 40, 255))
    draw.rectangle([w*0.1, h*0.55, w*0.9, h*0.65], fill=(139, 90, 43, 255), outline=(184, 134, 11, 255), width=2)
    draw.rectangle([w*0.05, h*0.1, w*0.95, h*0.5], fill=(80, 70, 55, 255), outline=(120, 100, 80, 255), width=2)
    
    for y_frac in [0.25, 0.35, 0.45]:
        y = int(h * y_frac)
        draw.line([(int(w*0.05), y), (int(w*0.95), y)], fill=(139, 90, 43, 255), width=2)
    
    if "Gearwright" in vendor_name:
        for i in range(5):
            x = int(w * (0.15 + i * 0.15))
            draw.ellipse([x-8, int(h*0.18)-8, x+8, int(h*0.18)+8], fill=(184, 134, 11, 255), outline=(218, 165, 32, 255), width=1)
    elif "Steam" in vendor_name or "Press" in vendor_name:
        for i in range(4):
            x = int(w * (0.2 + i * 0.18))
            draw.rectangle([x-5, int(h*0.28)-12, x+5, int(h*0.28)], fill=(100, 200, 150, 255), outline=(150, 255, 200, 255), width=1)
    elif "Curio" in vendor_name:
        for i in range(3):
            x = int(w * (0.25 + i * 0.2))
            draw.rectangle([x-10, int(h*0.18)-14, x+10, int(h*0.18)], fill=(100, 50, 150, 255), outline=(180, 100, 255, 255), width=2)
    
    font = get_font(12)
    bbox = draw.textbbox((0, 0), vendor_name, font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (w - text_width) // 2
    draw.text((text_x, 8), vendor_name, fill=(255, 215, 0, 255), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_food_station(food_name, output_path, size=64):
    """Food station sprite for Refectory"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    
    draw.rectangle([10, center+5, size-10, size-8], fill=(100, 80, 60, 255), outline=(140, 110, 80, 255), width=2)
    draw.ellipse([center-15, center-10, center+15, center+15], fill=(200, 190, 170, 255), outline=(160, 150, 130, 255), width=2)
    
    if "stew" in food_name.lower():
        food_color = (100, 60, 40, 255)
    elif "bread" in food_name.lower():
        food_color = (200, 170, 100, 255)
    elif "meat" in food_name.lower():
        food_color = (150, 80, 80, 255)
    else:
        food_color = (150, 150, 100, 255)
    
    draw.ellipse([center-8, center-5, center+8, center+8], fill=food_color, outline=(180, 160, 120, 255), width=1)
    
    for i in range(2):
        x = center + (i - 0.5) * 10
        draw.arc([int(x-4), center-18, int(x+4), center-6], start=180, end=360, fill=(255, 255, 255, 150), width=2)
    
    font = get_font(7)
    short = food_name.replace("Memory ", "").replace("Nostalgia ", "").replace("Phantom ", "")[:8]
    bbox = draw.textbbox((0, 0), short, font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (size - text_width) // 2
    draw.text((text_x, size - 20), short, fill=(255, 255, 240, 255), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_gear_part(part_name, output_path, size=48):
    """Collectible gear part item"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    outer_r = size // 3
    
    if "gear" in part_name.lower():
        teeth = 6
        inner_r = size // 4
        gear_points = []
        for i in range(teeth * 2):
            angle = (360 / (teeth * 2)) * i
            rad = math.radians(angle)
            if i % 2 == 0:
                r = outer_r
            else:
                r = inner_r
            x = center + r * math.cos(rad)
            y = center + r * math.sin(rad)
            gear_points.append((x, y))
        draw.polygon(gear_points, fill=(184, 134, 11, 255), outline=(218, 165, 32, 255), width=2)
        draw.ellipse([center - 4, center - 4, center + 4, center + 4], fill=(139, 90, 43, 255))
    elif "valve" in part_name.lower():
        draw.ellipse([center - outer_r, center - outer_r, center + outer_r, center + outer_r], fill=(150, 150, 160, 255), outline=(200, 200, 210, 255), width=2)
        draw.line([(center, center - outer_r), (center, center + outer_r)], fill=(180, 180, 190, 255), width=3)
        draw.line([(center - outer_r, center), (center + outer_r, center)], fill=(180, 180, 190, 255), width=3)
    else:
        draw.rectangle([center-10, center-10, center+10, center+10], fill=(184, 134, 11, 255), outline=(218, 165, 32, 255), width=2)
    
    font = get_font(6)
    short = part_name[:6]
    bbox = draw.textbbox((0, 0), short, font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (size - text_width) // 2
    draw.text((text_x, size - 14), short, fill=(255, 255, 255, 255), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_transition_marker(marker_type, output_path, size=48):
    """Level transition markers"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    
    if marker_type == "grate":
        draw.rectangle([4, 4, size-4, size-4], fill=(40, 40, 45, 255), outline=(80, 80, 90, 255), width=2)
        for i in range(3):
            y = 10 + i * 12
            draw.line([(8, y), (size-8, y)], fill=(60, 60, 70, 255), width=3)
        draw.polygon([(center, size-8), (center-6, size-16), (center+6, size-16)], fill=(150, 150, 160, 255))
    
    elif marker_type == "stairs":
        draw.rectangle([8, 8, size-8, size-8], fill=(100, 85, 60, 255), outline=(140, 120, 80, 255), width=2)
        for i in range(4):
            y = 12 + i * 8
            draw.line([(10, y), (size-10, y)], fill=(120, 100, 70, 255), width=2)
        arrow = "⇑" if "up" in output_path else "⇓"
        font = get_font(12)
        bbox = draw.textbbox((0, 0), arrow, font=font)
        text_width = bbox[2] - bbox[0]
        text_x = (size - text_width) // 2
        draw.text((text_x, center - 6), arrow, fill=(255, 255, 200, 255), font=font)
    
    elif marker_type == "ladder":
        draw.rectangle([center-12, 4, center-8, size-4], fill=(139, 90, 43, 255), outline=(184, 134, 11, 255), width=1)
        draw.rectangle([center+8, 4, center+12, size-4], fill=(139, 90, 43, 255), outline=(184, 134, 11, 255), width=1)
        for i in range(4):
            y = 10 + i * 10
            draw.line([(center-10, y), (center+10, y)], fill=(160, 110, 50, 255), width=3)
        font = get_font(10)
        draw.text((center-6, 2), "⇑", fill=(255, 255, 200, 255), font=font)
    
    elif marker_type == "steam_vent":
        draw.ellipse([center-12, center-8, center+12, center+12], fill=(100, 100, 110, 255), outline=(150, 150, 160, 255), width=2)
        for i in range(3):
            y = center - 12 - i * 8
            draw.arc([center-8+i*3, y-4, center+8-i*3, y+4], start=180, end=360, fill=(200, 200, 210, 100), width=2)
        font = get_font(10)
        draw.text((center-6, center-6), "⇑", fill=(255, 255, 255, 255), font=font)
    
    elif marker_type == "dumbwaiter":
        draw.rectangle([8, 8, size-8, size-8], fill=(120, 100, 80, 255), outline=(160, 140, 110, 255), width=2)
        draw.line([(center, 4), (center, 8)], fill=(180, 160, 130, 255), width=2)
        font = get_font(8)
        draw.text((center-8, center-4), "⇓", fill=(255, 255, 200, 255), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_pipe(output_path, orientation='v', size=(32, 128)):
    """Pipe decoration for Undercroft"""
    ensure_dir(output_path)
    if orientation == 'h':
        size = (128, 32)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    if orientation == 'v':
        draw.rectangle([4, 0, size[0]-4, size[1]], fill=(60, 60, 75, 255), outline=(100, 100, 120, 255), width=2)
        for y in [20, 60, 100]:
            draw.ellipse([2, y-3, 8, y+3], fill=(120, 120, 140, 255))
            draw.ellipse([size[0]-8, y-3, size[0]-2, y+3], fill=(120, 120, 140, 255))
    else:
        draw.rectangle([0, 4, size[0], size[1]-4], fill=(60, 60, 75, 255), outline=(100, 100, 120, 255), width=2)
        for x in [30, 90]:
            draw.ellipse([x-3, 2, x+3, 8], fill=(120, 120, 140, 255))
            draw.ellipse([x-3, size[1]-8, x+3, size[1]-2], fill=(120, 120, 140, 255))
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_gear_cellar(output_path, size=(120, 80)):
    """Gear cellar decoration"""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    w, h = size
    draw.rectangle([4, 4, w-4, h-4], fill=(80, 70, 50, 255), outline=(120, 100, 70, 255), width=2)
    
    for i in range(3):
        x = int(w * (0.2 + i * 0.3))
        draw.ellipse([x-10, h//2-10, x+10, h//2+10], fill=(184, 134, 11, 255), outline=(218, 165, 32, 255), width=1)
    
    font = get_font(8)
    bbox = draw.textbbox((0, 0), "GEARS", font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (w - text_width) // 2
    draw.text((text_x, 8), "GEARS", fill=(255, 215, 0, 255), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_balcony_railing(output_path, size=(1600, 24)):
    """Balcony railing for Refectory"""
    ensure_dir(output_path)
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    w, h = size
    draw.rectangle([0, 0, w, 6], fill=(139, 90, 43, 255), outline=(184, 134, 11, 255), width=1)
    draw.rectangle([0, h-6, w, h], fill=(139, 90, 43, 255), outline=(184, 134, 11, 255), width=1)
    for x in range(0, w, 40):
        draw.rectangle([x, 0, x+6, h], fill=(100, 70, 30, 255), outline=(160, 120, 50, 255), width=1)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_boss_frame(boss_name, faction, frame_type, output_path, size=64):
    """Create a boss animation frame"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Faction colors
    colors = {
        'construct': (139, 90, 43),      # Bronze/brown
        'goblin': (34, 139, 34),         # Green
        'aberration': (75, 0, 130),      # Dark purple
        'demon': (139, 0, 0),            # Dark red
        'undead': (112, 128, 144),       # Slate gray
    }
    
    base_color = colors.get(faction.lower(), (100, 100, 100))
    
    # Frame modifiers
    if frame_type == 'idle':
        offset_y = 0
        intensity = 1.0
    elif frame_type == 'attack':
        offset_y = -3
        intensity = 1.3
    elif frame_type == 'damage':
        offset_y = 0
        intensity = 0.7
        base_color = (255, 100, 100)  # Flash red
    elif frame_type == 'death':
        offset_y = 5
        intensity = 0.5
        base_color = (50, 50, 50)  # Dark gray
    else:
        offset_y = 0
        intensity = 1.0
    
    center = size // 2
    radius = size // 3
    
    # Draw body
    body_color = tuple(min(255, int(c * intensity)) for c in base_color)
    draw.ellipse([center - radius, center - radius + offset_y, 
                  center + radius, center + radius + offset_y], 
                 fill=body_color, outline=(255, 255, 255, 150), width=2)
    
    # Draw eyes
    eye_color = (255, 255, 0) if frame_type != 'death' else (100, 100, 100)
    eye_offset = 8
    eye_y = center - 5 + offset_y
    draw.ellipse([center - eye_offset - 3, eye_y - 3, center - eye_offset + 3, eye_y + 3], fill=eye_color)
    draw.ellipse([center + eye_offset - 3, eye_y - 3, center + eye_offset + 3, eye_y + 3], fill=eye_color)
    
    # Add faction symbol
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 10)
    except:
        font = ImageFont.load_default()
    
    symbol = {
        'construct': 'C',
        'goblin': 'G',
        'aberration': 'A',
        'demon': 'D',
        'undead': 'U'
    }.get(faction.lower(), '?')
    
    bbox = draw.textbbox((0, 0), symbol, font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (size - text_width) // 2
    text_y = center + 8 + offset_y
    draw.text((text_x, text_y), symbol, fill=(255, 255, 255, 200), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")


def create_tiled_floor(base_tile_path, output_path, tiles_x=25, tiles_y=25):
    """Create a large floor texture by tiling a base hex tile"""
    ensure_dir(output_path)
    base = Image.open(base_tile_path)
    w, h = base.size
    
    offset_x = w // 2
    total_w = w * tiles_x + offset_x
    total_h = int(h * tiles_y * 0.75)
    
    img = Image.new('RGBA', (total_w, total_h), (0, 0, 0, 0))
    
    for row in range(tiles_y):
        for col in range(tiles_x):
            x = col * w + (offset_x if row % 2 == 1 else 0)
            y = int(row * h * 0.75)
            if x + w <= total_w and y + h <= total_h:
                img.paste(base, (x, y), base)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def main():
    floor4_dir = os.path.join(BASE_PATH, "floor4")
    os.makedirs(floor4_dir, exist_ok=True)
    
    print("=== Generating Floor 4 Assets ===\n")
    
    # 1. Floor tiles
    create_brass_hex_tile("BAZAAR", os.path.join(floor4_dir, "bazaar_hex.png"))
    create_dark_pipe_tile("PIPES", os.path.join(floor4_dir, "undercroft_hex.png"))
    create_refectory_tile("DINE", os.path.join(floor4_dir, "refectory_hex.png"))
    
    # 2. Great Lifter
    create_great_lifter(os.path.join(floor4_dir, "great_lifter.png"))
    
    # 3. Aether Slick
    create_aether_slick(os.path.join(floor4_dir, "aether_slick.png"))
    
    # 4. Booth exteriors (12 total: 3 real, 9 trap)
    create_booth_exterior("Gearwright", True, os.path.join(floor4_dir, "booth_gearwright.png"))
    create_booth_exterior("SteamPress", True, os.path.join(floor4_dir, "booth_steampress.png"))
    create_booth_exterior("Curio", True, os.path.join(floor4_dir, "booth_curio.png"))
    for i in range(1, 10):
        create_booth_exterior(f"Trap{i}", False, os.path.join(floor4_dir, f"booth_trap_{i}.png"))
    
    # 5. Vendor interior backgrounds
    create_vendor_interior("The Gearwright", os.path.join(floor4_dir, "vendor_gearwright_interior.png"))
    create_vendor_interior("Steam-Press", os.path.join(floor4_dir, "vendor_steampress_interior.png"))
    create_vendor_interior("Curio Collector", os.path.join(floor4_dir, "vendor_curio_interior.png"))
    
    # 6. Food stations
    create_food_station("Memory Stew", os.path.join(floor4_dir, "food_station_stew.png"))
    create_food_station("Nostalgia Bread", os.path.join(floor4_dir, "food_station_bread.png"))
    create_food_station("Phantom Meat", os.path.join(floor4_dir, "food_station_meat.png"))
    
    # 7. Gear parts
    create_gear_part("Gear Part", os.path.join(floor4_dir, "gear_part_1.png"))
    create_gear_part("Steam Valve", os.path.join(floor4_dir, "gear_part_2.png"))
    create_gear_part("Brass Ring", os.path.join(floor4_dir, "gear_part_3.png"))
    
    # 11. Floor 4 enemy sprites
    create_boss_frame("mirror_self", "aberration", "idle", os.path.join(BASE_PATH, "enemies", "enemy_mirror_self_idle.png"))
    create_boss_frame("afterimage", "aberration", "idle", os.path.join(BASE_PATH, "enemies", "enemy_afterimage_idle.png"))
    create_boss_frame("engine_block", "construct", "idle", os.path.join(BASE_PATH, "enemies", "Construct", "enemy_engine_block_idle.png"))
    create_boss_frame("drive_train", "construct", "idle", os.path.join(BASE_PATH, "enemies", "Construct", "enemy_drive_train_idle.png"))
    
    # 8. Level transition markers
    create_transition_marker("grate", os.path.join(floor4_dir, "grate.png"))
    create_transition_marker("stairs", os.path.join(floor4_dir, "stairs_up.png"))
    create_transition_marker("stairs", os.path.join(floor4_dir, "stairs_down.png"))
    create_transition_marker("ladder", os.path.join(floor4_dir, "ladder.png"))
    create_transition_marker("steam_vent", os.path.join(floor4_dir, "steam_vent.png"))
    create_transition_marker("dumbwaiter", os.path.join(floor4_dir, "dumbwaiter.png"))
    
    # 9. Undercroft decorations
    create_pipe(os.path.join(floor4_dir, "pipe_v.png"), 'v')
    create_pipe(os.path.join(floor4_dir, "pipe_h.png"), 'h')
    create_gear_cellar(os.path.join(floor4_dir, "gear_cellar.png"))
    
    # 10. Refectory decorations
    create_balcony_railing(os.path.join(floor4_dir, "balcony_railing.png"))
    
    print("\n=== FLOOR 4 ASSET GENERATION COMPLETE ===")
    print(f"All assets saved to: {floor4_dir}")
    
    # Generate floor textures
    create_tiled_floor(os.path.join(floor4_dir, "bazaar_hex.png"),
                       os.path.join(floor4_dir, "bazaar_floor.png"), 25, 25)
    create_tiled_floor(os.path.join(floor4_dir, "undercroft_hex.png"),
                       os.path.join(floor4_dir, "undercroft_floor.png"), 20, 20)
    create_tiled_floor(os.path.join(floor4_dir, "refectory_hex.png"),
                       os.path.join(floor4_dir, "refectory_floor.png"), 18, 18)
    
    print("\n=== FLOOR TEXTURES GENERATED ===")

if __name__ == "__main__":
    main()
