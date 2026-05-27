#!/usr/bin/env python3
"""
Scale Floor 2 backgrounds to 8x and regenerate walls with larger radii.
"""

import re
import math
import random
from pathlib import Path

SCENES_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/scenes/rooms")
OUTPUT_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/scenes/rooms")

ROOMS = [
    ("Floor2_Entry", 960, 900, 900, 700, 3),
    ("Floor2_Upper", 960, 800, 1000, 750, 2),
    ("Floor2_Middle", 960, 800, 950, 720, 2),
    ("Floor2_Lower", 960, 800, 1000, 750, 2),
    ("Floor2_Secret", 960, 540, 700, 500, 1),
    ("Floor2_SporeHeart", 960, 800, 1100, 820, 1),
]

def generate_walls(room_name, cx, cy, rx, ry, num_gaps):
    """Generate organic bubble wall collision for a room."""
    random.seed(hash(room_name) % 2**32)
    
    n_segments = 22
    gap_indices = set()
    
    # Distribute gaps evenly
    for i in range(num_gaps):
        gap_indices.add(int(i * n_segments / num_gaps + n_segments / (2 * num_gaps)) % n_segments)
    
    walls = []
    for i in range(n_segments):
        if i in gap_indices:
            continue
        
        t1 = 2 * math.pi * i / n_segments
        t2 = 2 * math.pi * (i + 1) / n_segments
        
        # Organic noise
        r1 = 1.0 + random.uniform(-0.06, 0.06)
        r2 = 1.0 + random.uniform(-0.06, 0.06)
        
        p1x = cx + rx * r1 * math.cos(t1)
        p1y = cy + ry * r1 * math.sin(t1)
        p2x = cx + rx * r2 * math.cos(t2)
        p2y = cy + ry * r2 * math.sin(t2)
        
        # Inner edge (60px thick walls)
        nx = p2y - p1y
        ny = p1x - p2x
        mag = math.sqrt(nx * nx + ny * ny)
        if mag > 0:
            nx, ny = nx / mag * 30, ny / mag * 30
        else:
            nx, ny = 0, 0
        
        walls.append([
            (p1x, p1y), (p2x, p2y),
            (p2x + nx, p2y + ny), (p1x + nx, p1y + ny)
        ])
    
    return walls

def process_room(room_name, cx, cy, rx, ry, num_gaps):
    filepath = SCENES_DIR / f"{room_name}.tscn"
    if not filepath.exists():
        print(f"  [SKIP] {room_name} not found")
        return
    
    content = filepath.read_text()
    
    # Scale background to 8x
    content = re.sub(
        r'scale = Vector2\(5, 5\)\n(texture = ExtResource\("2_bg"\))',
        r'scale = Vector2(8, 8)\n\1',
        content
    )
    content = re.sub(
        r'(texture = ExtResource\("2_bg"\)\n)scale = Vector2\(5, 5\)',
        r'\1scale = Vector2(8, 8)',
        content
    )
    # Also handle if scale is on a different line order
    content = content.replace('scale = Vector2(5, 5)', 'scale = Vector2(8, 8)')
    
    # Remove old wall sprites and collision
    content = re.sub(r'\n\[node name="Wall_\d+" type="CollisionPolygon2D" parent="Walls"\]\npolygon = PackedVector2Array\([^\)]*\)\n', '\n', content)
    content = re.sub(r'\n\[node name="WallSprite_\d+" type="Sprite2D" parent="Walls"\]\n(?:.*\n)*?\n(?=\[node name=|\Z)', '\n', content)
    
    # Generate new walls
    walls = generate_walls(room_name, cx, cy, rx, ry, num_gaps)
    
    # Find Walls node
    walls_match = re.search(r'\[node name="Walls" type="StaticBody2D" parent="\."\]\n', content)
    if not walls_match:
        print(f"  [WARN] {room_name}: Walls node not found")
        return
    
    insert_pos = walls_match.end()
    
    wall_lines = []
    for i, wall in enumerate(walls):
        pts = ", ".join(f"{x:.1f}, {y:.1f}" for x, y in wall)
        wall_lines.append(f'[node name="Wall_{i+1:03d}" type="CollisionPolygon2D" parent="Walls"]')
        wall_lines.append(f'polygon = PackedVector2Array({pts})')
        wall_lines.append('')
    
    content = content[:insert_pos] + '\n' + '\n'.join(wall_lines) + '\n' + content[insert_pos:]
    
    filepath.write_text(content)
    print(f"  [OK] {room_name}: {len(walls)} walls, bg 8x, radius {rx}x{ry}")

def main():
    print("=" * 60)
    print("Floor 2 Room Resizer")
    print("=" * 60)
    
    for room_name, cx, cy, rx, ry, gaps in ROOMS:
        process_room(room_name, cx, cy, rx, ry, gaps)
    
    print("\n" + "=" * 60)
    print("Done — backgrounds scaled 8x, walls regenerated")
    print("=" * 60)

if __name__ == "__main__":
    main()
