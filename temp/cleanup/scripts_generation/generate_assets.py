#!/usr/bin/env python3
"""Generate placeholder sprites for Floor 3 Gearworks Demo"""

from PIL import Image, ImageDraw, ImageFont
import os

# Base paths
BASE_PATH = "/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites"

def ensure_dir(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)

def create_hex_tile(color, label, output_path, size=64):
    """Create a hexagonal tile with label"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw hexagon
    center = size // 2
    radius = size // 2 - 2
    points = []
    for i in range(6):
        angle = 60 * i - 30
        x = center + radius * 0.9 * __import__('math').cos(__import__('math').radians(angle))
        y = center + radius * 0.9 * __import__('math').sin(__import__('math').radians(angle))
        points.append((x, y))
    
    draw.polygon(points, fill=color, outline=(255, 255, 255, 200), width=2)
    
    # Add label text
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 8)
    except:
        font = ImageFont.load_default()
    
    bbox = draw.textbbox((0, 0), label, font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (size - text_width) // 2
    text_y = size // 2 - 4
    draw.text((text_x, text_y), label, fill=(255, 255, 255, 255), font=font)
    
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

def create_ui_dial_button(output_path, size=64):
    """Create gear-themed dial button"""
    ensure_dir(output_path)
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    
    # Draw gear teeth
    outer_radius = size // 2 - 2
    inner_radius = size // 2 - 8
    teeth = 8
    
    for i in range(teeth * 2):
        angle = (360 / (teeth * 2)) * i
        rad = __import__('math').radians(angle)
        if i % 2 == 0:
            x1 = center + outer_radius * 0.9 * __import__('math').cos(rad)
            y1 = center + outer_radius * 0.9 * __import__('math').sin(rad)
        else:
            x1 = center + inner_radius * 0.9 * __import__('math').cos(rad)
            y1 = center + inner_radius * 0.9 * __import__('math').sin(rad)
        
        if i > 0:
            draw.line([(x0, y0), (x1, y1)], fill=(184, 134, 11), width=3)
        x0, y0 = x1, y1
    
    # Close the gear shape
    angle = 0
    rad = __import__('math').radians(angle)
    x1 = center + outer_radius * 0.9 * __import__('math').cos(rad)
    y1 = center + outer_radius * 0.9 * __import__('math').sin(rad)
    draw.line([(x0, y0), (x1, y1)], fill=(184, 134, 11), width=3)
    
    # Draw center circle
    draw.ellipse([center - 12, center - 12, center + 12, center + 12], 
                 fill=(139, 90, 43), outline=(255, 215, 0), width=2)
    
    # Draw "DIAL" text
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 8)
    except:
        font = ImageFont.load_default()
    
    bbox = draw.textbbox((0, 0), "DIAL", font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (size - text_width) // 2
    text_y = center - 4
    draw.text((text_x, text_y), "DIAL", fill=(255, 215, 0), font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def create_light_beam(output_path, orientation, size=(128, 32)):
    """Create glowing light beam effect"""
    ensure_dir(output_path)
    
    if orientation == 'v':
        size = (32, 128)
    elif orientation == 'diag':
        size = (128, 128)
    else:  # h
        size = (128, 32)
    
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Create gradient glow
    center_color = (255, 255, 200, 230)  # Bright yellow-white
    edge_color = (255, 200, 100, 0)      # Fade to transparent
    
    if orientation == 'h':
        for y in range(size[1]):
            alpha = int(230 * (1 - abs(y - size[1]/2) / (size[1]/2)))
            color = (255, 255, 200, alpha)
            draw.line([(0, y), (size[0], y)], fill=color, width=1)
        # Bright center line
        draw.line([(0, size[1]//2), (size[0], size[1]//2)], fill=(255, 255, 255, 255), width=2)
    
    elif orientation == 'v':
        for x in range(size[0]):
            alpha = int(230 * (1 - abs(x - size[0]/2) / (size[0]/2)))
            color = (255, 255, 200, alpha)
            draw.line([(x, 0), (x, size[1])], fill=color, width=1)
        # Bright center line
        draw.line([(size[0]//2, 0), (size[0]//2, size[1])], fill=(255, 255, 255, 255), width=2)
    
    elif orientation == 'diag':
        # Diagonal beam
        for offset in range(-20, 21):
            alpha = int(230 * (1 - abs(offset) / 20))
            color = (255, 255, 200, alpha)
            draw.line([(0, 64 + offset), (128, 64 + offset + 32)], fill=color, width=1)
            draw.line([(0, 64 + offset), (128, 64 + offset - 32)], fill=color, width=1)
        # Bright center diagonal
        draw.line([(0, 64), (128, 96)], fill=(255, 255, 255, 255), width=3)
    
    img.save(output_path)
    print(f"Created: {output_path}")

def main():
    # Create effects directory
    effects_dir = os.path.join(BASE_PATH, "effects")
    os.makedirs(effects_dir, exist_ok=True)
    
    # 1. Create UI Dial Button
    create_ui_dial_button(os.path.join(BASE_PATH, "ui", "ui_dial_button.png"))
    
    # 2. Create Light Beam Effects
    create_light_beam(os.path.join(BASE_PATH, "effects", "light_beam_h.png"), 'h')
    create_light_beam(os.path.join(BASE_PATH, "effects", "light_beam_v.png"), 'v')
    create_light_beam(os.path.join(BASE_PATH, "effects", "light_beam_diag.png"), 'diag')
    
    # 3. Create Boss Animation Frames
    bosses = [
        ('the_caldera', 'construct'),
        ('gear_mother', 'construct'),
        ('goblin_king_grimgut', 'goblin'),
        ('the_consumption', 'aberration'),
        ('the_interview', 'demon'),
        ('the_unsent_letter', 'undead'),
    ]
    
    frames = ['idle', 'attack', 'damage', 'death']
    
    for boss_name, faction in bosses:
        for frame in frames:
            output_path = os.path.join(BASE_PATH, "enemies", f"boss_{boss_name}_{frame}.png")
            create_boss_frame(boss_name, faction, frame, output_path)
    
    # 4. Create Room Terrain Variants (11 rooms)
    rooms = [
        ('quench', (100, 149, 237), 'WATER'),      # Water/steam - cornflower blue
        ('spark', (255, 69, 0), 'FIRE'),           # Fire/ignition - red-orange
        ('governor', (112, 128, 144), 'CTRL'),     # Control/mechanical - slate
        ('draft', (176, 196, 222), 'AIR'),         # Air/steam - light steel
        ('temper', (178, 34, 34), 'FORGE'),        # Forge/heat - firebrick
        ('beacon', (255, 215, 0), 'LIGHT'),        # Tower/light - gold
        ('escapement', (70, 130, 180), 'TIME'),    # Clockwork/time - steel blue
        ('bearing', (192, 192, 192), 'METAL'),     # Friction/metal - silver
        ('flywheel', (218, 165, 32), 'SPIN'),      # Spinning/momentum - goldenrod
        ('counterweight', (205, 133, 63), 'BAL'),  # Balance/scale - peru
        ('oiler', (107, 142, 35), 'OIL'),          # Maintenance/grease - olive
    ]
    
    for room_name, color, label in rooms:
        output_path = os.path.join(BASE_PATH, "terrain", f"hex_room_{room_name}.png")
        create_hex_tile(color + (200,), label, output_path)
    
    print("\n=== ASSET GENERATION COMPLETE ===")

if __name__ == "__main__":
    main()
