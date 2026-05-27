#!/usr/bin/env python3
"""
Wall Tile Placer v2 — Floor 2: Places generated wall sprites along collision polygons.
Uses fixed ExtResource IDs to avoid duplication and parsing issues.

Usage:
    python3 place_f2_wall_tiles_v2.py
"""

import math
import re
from pathlib import Path
from typing import List, Tuple, Optional, Set

ROOMS = [
    "Floor2_Entry",
    "Floor2_Upper",
    "Floor2_Middle",
    "Floor2_Lower",
    "Floor2_Secret",
    "Floor2_SporeHeart",
]

SCENES_DIR = Path("scenes/rooms")
WALLS_DIR = Path("assets/sprites/floor2/walls")

# All possible wall tiles and their fixed ExtResource IDs
WALL_TILE_IDS = {
    "wall_straight_n": "wall_straight_n",
    "wall_straight_s": "wall_straight_s",
    "wall_straight_e": "wall_straight_e",
    "wall_straight_w": "wall_straight_w",
    "wall_curve_nw": "wall_curve_nw",
    "wall_curve_ne": "wall_curve_ne",
    "wall_curve_sw": "wall_curve_sw",
    "wall_curve_se": "wall_curve_se",
    "wall_outer_nw": "wall_outer_nw",
    "wall_outer_ne": "wall_outer_ne",
    "wall_outer_sw": "wall_outer_sw",
    "wall_outer_se": "wall_outer_se",
    "wall_cap_n": "wall_cap_n",
    "wall_cap_s": "wall_cap_s",
    "wall_cap_w": "wall_cap_w",
    "wall_cap_e": "wall_cap_e",
    "wall_feature_moss_cluster": "wall_feature_moss_cluster",
    "wall_feature_crystal_growth": "wall_feature_crystal_growth",
    "wall_feature_fungal_shelf": "wall_feature_fungal_shelf",
    "wall_feature_root_tangle": "wall_feature_root_tangle",
    "wall_diag_nw_se": "wall_diag_nw_se",
    "wall_diag_ne_sw": "wall_diag_ne_sw",
}


def angle_to_cardinal(dx: float, dy: float) -> str:
    """Convert a direction vector to nearest cardinal/diagonal for tile selection."""
    angle = math.degrees(math.atan2(dy, dx))
    angle = (angle + 360) % 360
    
    if 337.5 <= angle or angle < 22.5:
        return "e"
    elif 22.5 <= angle < 67.5:
        return "se"
    elif 67.5 <= angle < 112.5:
        return "s"
    elif 112.5 <= angle < 157.5:
        return "sw"
    elif 157.5 <= angle < 202.5:
        return "w"
    elif 202.5 <= angle < 247.5:
        return "nw"
    elif 247.5 <= angle < 292.5:
        return "n"
    elif 292.5 <= angle < 337.5:
        return "ne"
    return "n"


def select_tile_for_segment(p1: Tuple[float, float], p2: Tuple[float, float],
                             mid: Tuple[float, float], center: Tuple[float, float]) -> Optional[str]:
    """Select the best tile file for a wall segment based on its orientation and curvature."""
    dx = p2[0] - p1[0]
    dy = p2[1] - p1[1]
    
    dir_card = angle_to_cardinal(dx, dy)
    
    mid_to_center_x = center[0] - mid[0]
    mid_to_center_y = center[1] - mid[1]
    
    cross = dx * mid_to_center_y - dy * mid_to_center_x
    is_convex = cross < 0
    
    tile_map = {
        "n": "wall_straight_s",
        "s": "wall_straight_n",
        "e": "wall_straight_w",
        "w": "wall_straight_e",
        "nw": "wall_diag_nw_se",
        "se": "wall_diag_nw_se",
        "ne": "wall_diag_ne_sw",
        "sw": "wall_diag_ne_sw",
    }
    
    if is_convex:
        curve_map = {
            "nw": "wall_outer_nw",
            "ne": "wall_outer_ne",
            "sw": "wall_outer_sw",
            "se": "wall_outer_se",
        }
        if dir_card in curve_map:
            return curve_map[dir_card]
    else:
        curve_map = {
            "nw": "wall_curve_nw",
            "ne": "wall_curve_ne",
            "sw": "wall_curve_sw",
            "se": "wall_curve_se",
        }
        if dir_card in curve_map:
            return curve_map[dir_card]
    
    return tile_map.get(dir_card)


def parse_polygon_points(line: str) -> List[Tuple[float, float]]:
    """Parse PackedVector2Array from a tscn line."""
    match = re.search(r'PackedVector2Array\((.*?)\)', line)
    if not match:
        return []
    
    nums = [float(x.strip()) for x in match.group(1).split(',')]
    return [(nums[i], nums[i+1]) for i in range(0, len(nums), 2)]


def compute_room_center(wall_points: List[List[Tuple[float, float]]]) -> Tuple[float, float]:
    """Compute approximate room center from all wall vertices."""
    all_x = []
    all_y = []
    for poly in wall_points:
        for p in poly:
            all_x.append(p[0])
            all_y.append(p[1])
    
    if not all_x:
        return (960, 800)
    
    return (sum(all_x) / len(all_x), sum(all_y) / len(all_y))


def generate_wall_sprites(room_name: str, filepath: Path) -> Tuple[List[str], Set[str]]:
    """Generate Sprite2D node lines for wall tiles in a room scene. Returns (lines, needed_tile_ids)."""
    lines = []
    needed_tiles: Set[str] = set()
    
    content = filepath.read_text()
    
    # Find all CollisionPolygon2D nodes and their polygons
    wall_polygons = []
    for match in re.finditer(r'\[node name="Wall_\d+" type="CollisionPolygon2D" parent="Walls"\]\npolygon = PackedVector2Array\((.*?)\)', content):
        points = parse_polygon_points(match.group(0))
        if points:
            wall_polygons.append(points)
    
    if not wall_polygons:
        print(f"  [WARN] {room_name}: No wall polygons found")
        return [], set()
    
    center = compute_room_center(wall_polygons)
    
    sprite_idx = 0
    for poly in wall_polygons:
        if len(poly) < 4:
            continue
        
        p1 = poly[0]
        p2 = poly[1]
        p3 = poly[2]
        p4 = poly[3]
        
        mid = ((p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2)
        
        dx = p2[0] - p1[0]
        dy = p2[1] - p1[1]
        angle = math.degrees(math.atan2(dy, dx))
        
        tile_id = select_tile_for_segment(p1, p2, mid, center)
        if not tile_id:
            tile_id = "wall_straight_n"
        
        tile_file = f"{tile_id}.png"
        tile_path = WALLS_DIR / tile_file
        if not tile_path.exists():
            # Try alternate direction
            alt_map = {
                "wall_straight_n": "wall_straight_s",
                "wall_straight_s": "wall_straight_n",
                "wall_straight_e": "wall_straight_w",
                "wall_straight_w": "wall_straight_e",
            }
            alt_id = alt_map.get(tile_id)
            if alt_id:
                tile_path = WALLS_DIR / f"{alt_id}.png"
                if tile_path.exists():
                    tile_id = alt_id
        
        if not tile_path.exists():
            print(f"  [WARN] Tile not found: {tile_file}, skipping placement")
            continue
        
        needed_tiles.add(tile_id)
        
        sprite_name = f"WallSprite_{sprite_idx:03d}"
        sprite_idx += 1
        
        lines.append(f'[node name="{sprite_name}" type="Sprite2D" parent="Walls"]')
        lines.append(f'position = Vector2({mid[0]:.1f}, {mid[1]:.1f})')
        lines.append(f'rotation = {math.radians(angle):.4f}')
        lines.append(f'texture = ExtResource("{tile_id}")')
        lines.append(f'z_index = 1')
        lines.append('')
    
    return lines, needed_tiles


def add_ext_resources(content: str, needed_tiles: Set[str]) -> str:
    """Add ExtResource entries for wall tile textures. Removes duplicates first."""
    
    # Remove any existing wall ext_resources to avoid duplicates
    content = re.sub(r'\[ext_resource type="Texture2D" path="res://assets/sprites/floor2/walls/.*?\n', '', content)
    
    # Also remove any references to old broken wall ext_resources in node textures
    # (we'll re-add the correct ones below)
    
    # Find highest existing ext_resource id number for ordering
    max_id = 0
    for match in re.finditer(r'\[ext_resource type="Texture2D".*?id="(\d+)_', content):
        max_id = max(max_id, int(match.group(1)))
    
    new_resources = []
    next_id = max(1, max_id + 1)
    
    for tile_id in sorted(needed_tiles):
        # Check if already present (non-wall texture)
        if f'id="{tile_id}"' in content:
            continue
        
        new_resources.append(
            f'[ext_resource type="Texture2D" path="res://assets/sprites/floor2/walls/{tile_id}.png" id="{tile_id}"]'
        )
    
    if new_resources:
        # Insert after last ext_resource line
        last_ext = content.rfind('[ext_resource')
        if last_ext != -1:
            last_ext_end = content.find('\n', last_ext) + 1
            content = content[:last_ext_end] + '\n'.join(new_resources) + '\n' + content[last_ext_end:]
    
    return content


def process_room(room_name: str):
    """Process a single room scene file."""
    filepath = SCENES_DIR / f"{room_name}.tscn"
    
    if not filepath.exists():
        print(f"  [SKIP] {room_name}.tscn not found")
        return
    
    print(f"\n[PROCESS] {room_name}")
    
    # Generate sprite nodes
    sprite_lines, needed_tiles = generate_wall_sprites(room_name, filepath)
    
    if not sprite_lines:
        print(f"  [INFO] No wall sprites to place")
        return
    
    # Read current content
    content = filepath.read_text()
    
    # Remove any existing WallSprite nodes
    content = re.sub(r'\n\[node name="WallSprite_\d+".*?\n(?:.*?\n)*?\n', '\n', content)
    
    # Find where to insert (after the Walls node section)
    walls_section_end = content.find('\n[node name="Walls"')
    if walls_section_end == -1:
        walls_section_end = len(content)
    else:
        # Find the next top-level node after Walls (Wall_### are children, not top-level)
        # Search for a top-level node (no parent="Walls" or parent="Interior" etc.)
        next_node = re.search(r'\n\[node name="(?!Wall_)', content[walls_section_end+1:])
        if next_node:
            walls_section_end += next_node.start() + 1
        else:
            walls_section_end = len(content)
    
    # Insert sprite nodes
    content = content[:walls_section_end] + '\n' + '\n'.join(sprite_lines) + '\n' + content[walls_section_end:]
    
    # Add ext_resources (cleaned of duplicates)
    content = add_ext_resources(content, needed_tiles)
    
    # Fix load_steps count (Godot recalculates on import, but let's be close)
    ext_count = content.count('[ext_resource')
    content = re.sub(r'load_steps=\d+', f'load_steps={ext_count + 1}', content)
    
    # Write back
    filepath.write_text(content)
    print(f"  [OK] Placed {len(sprite_lines) // 6} wall sprites in {room_name}")
    print(f"  [OK] Added {len(needed_tiles)} ext_resources")


def main():
    print("=" * 60)
    print("Floor 2 Wall Tile Placer v2")
    print("=" * 60)
    print(f"Scenes:  {SCENES_DIR}")
    print(f"Tiles:   {WALLS_DIR}")
    print("=" * 60)
    
    if not WALLS_DIR.exists():
        print("\n[ERROR] Wall tiles not found! Run generate_f2_wall_tileset.py first.")
        return
    
    for room in ROOMS:
        process_room(room)
    
    print("\n" + "=" * 60)
    print("WALL TILE PLACEMENT COMPLETE")
    print("=" * 60)


if __name__ == "__main__":
    main()
