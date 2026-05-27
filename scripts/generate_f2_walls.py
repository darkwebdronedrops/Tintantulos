#!/usr/bin/env python3
"""Generate organic bubble-shaped wall polygons for Floor 2 rooms."""

import math
import sys

def generate_walls(cx, cy, rx, ry, portals, num_segments=24, wall_thickness=60, noise_amp=40):
    """
    Generate organic bubble wall segments.
    
    portals: list of (angle_deg, num_segments_to_remove)
    Returns list of polygon point lists, each a flat list [x1,y1,x2,y2,x3,y3,x4,y4]
    """
    angles = [2 * math.pi * i / num_segments for i in range(num_segments)]
    
    # Mark which segments to keep
    keep = [True] * num_segments
    for portal_angle_deg, segments_to_remove in portals:
        portal_angle = math.radians(portal_angle_deg)
        # Find the segment closest to the portal angle
        best_idx = min(range(num_segments), key=lambda i: abs((angles[i] - portal_angle + math.pi) % (2*math.pi) - math.pi))
        # Remove segments_to_remove/2 on each side
        half = segments_to_remove // 2
        for offset in range(-half, half + 1):
            idx = (best_idx + offset) % num_segments
            keep[idx] = False
    
    def radius_at(angle):
        """Ellipse radius with organic noise."""
        r = math.sqrt(1.0 / (max(math.cos(angle)**2 / rx**2, 1e-10) + max(math.sin(angle)**2 / ry**2, 1e-10)))
        # Deterministic organic noise
        noise = noise_amp * math.sin(angle * 3.7 + 1.2) * math.cos(angle * 2.3 - 0.8)
        return r + noise
    
    def point_at(angle):
        r = radius_at(angle)
        return (cx + r * math.cos(angle), cy + r * math.sin(angle))
    
    walls = []
    for i in range(num_segments):
        j = (i + 1) % num_segments
        if not (keep[i] and keep[j]):
            continue
        
        x1, y1 = point_at(angles[i])
        x2, y2 = point_at(angles[j])
        
        # Direction along the wall
        dx = x2 - x1
        dy = y2 - y1
        length = math.hypot(dx, dy)
        if length < 1:
            continue
        
        # Outward normal (away from center)
        nx = dy / length
        ny = -dx / length
        
        # Verify outward direction (should point away from center)
        mid_x = (x1 + x2) / 2
        mid_y = (y1 + y2) / 2
        to_center_x = cx - mid_x
        to_center_y = cy - mid_y
        if nx * to_center_x + ny * to_center_y > 0:
            # Normal points toward center, flip it
            nx = -nx
            ny = -ny
        
        # Wall thickness offset
        tx = nx * wall_thickness
        ty = ny * wall_thickness
        
        points = [
            round(x1), round(y1),
            round(x2), round(y2),
            round(x2 + tx), round(y2 + ty),
            round(x1 + tx), round(y1 + ty)
        ]
        walls.append(points)
    
    return walls


def format_tscn_walls(walls):
    """Format wall segments as tscn nodes."""
    lines = ['\n[node name="Walls" type="StaticBody2D" parent="."]\n']
    for idx, points in enumerate(walls, 1):
        pts_str = ", ".join(str(p) for p in points)
        lines.append(f'[node name="Wall_{idx:03d}" type="CollisionPolygon2D" parent="Walls"]')
        lines.append(f'polygon = PackedVector2Array({pts_str})')
        lines.append('')
    return "\n".join(lines)


def inject_walls(filepath, walls_tscn):
    """Replace the Walls section in a tscn file."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Find the Walls node and truncate from there
    wall_idx = content.find('\n[node name="Walls"')
    if wall_idx == -1:
        wall_idx = content.find('\n[node name="RoomWalls"')
    
    if wall_idx != -1:
        content = content[:wall_idx]
    
    # Append new walls
    content += walls_tscn
    
    with open(filepath, 'w') as f:
        f.write(content)


ROOMS = {
    "Floor2_Entry": {
        "path": "/root/.openclaw/workspace/acanous_floor3_demo/scenes/rooms/Floor2_Entry.tscn",
        "cx": 960, "cy": 900,
        "rx": 720, "ry": 520,
        "portals": [(270, 1), (0, 1), (90, 1)]  # North, East, South
    },
    "Floor2_Upper": {
        "path": "/root/.openclaw/workspace/acanous_floor3_demo/scenes/rooms/Floor2_Upper.tscn",
        "cx": 960, "cy": 800,
        "rx": 680, "ry": 500,
        "portals": [(270, 1), (90, 1)]  # North (to boss), South (to entry)
    },
    "Floor2_Middle": {
        "path": "/root/.openclaw/workspace/acanous_floor3_demo/scenes/rooms/Floor2_Middle.tscn",
        "cx": 960, "cy": 800,
        "rx": 680, "ry": 500,
        "portals": [(270, 1), (90, 1)]  # North (to boss), South (to entry)
    },
    "Floor2_Lower": {
        "path": "/root/.openclaw/workspace/acanous_floor3_demo/scenes/rooms/Floor2_Lower.tscn",
        "cx": 960, "cy": 800,
        "rx": 680, "ry": 500,
        "portals": [(270, 1), (90, 1)]  # North (to boss), South (to entry)
    },
    "Floor2_Secret": {
        "path": "/root/.openclaw/workspace/acanous_floor3_demo/scenes/rooms/Floor2_Secret.tscn",
        "cx": 960, "cy": 800,
        "rx": 620, "ry": 460,
        "portals": [(90, 1)]  # South (to lower)
    },
    "Floor2_SporeHeart": {
        "path": "/root/.openclaw/workspace/acanous_floor3_demo/scenes/rooms/Floor2_SporeHeart.tscn",
        "cx": 960, "cy": 800,
        "rx": 720, "ry": 520,
        "portals": [(90, 1)]  # South (to entry)
    },
}


def main():
    for room_name, params in ROOMS.items():
        walls = generate_walls(
            params["cx"], params["cy"],
            params["rx"], params["ry"],
            params["portals"]
        )
        tscn = format_tscn_walls(walls)
        inject_walls(params["path"], tscn)
        print(f"[OK] {room_name}: {len(walls)} wall segments")
    
    print("\nAll Floor 2 rooms updated with organic bubble walls.")


if __name__ == "__main__":
    main()
