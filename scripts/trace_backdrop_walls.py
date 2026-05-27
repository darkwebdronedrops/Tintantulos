#!/usr/bin/env python3
"""
Trace backdrop wall edges — detects the boundary between floor and wall
in generated backdrops, then generates collision polygons aligned to that edge.

Pure numpy/PIL implementation (no skimage/scipy needed).

Usage:
    python3 trace_backdrop_walls.py
"""

import os
import re
import math
from pathlib import Path
from PIL import Image
import numpy as np

# Config
SCENES_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/scenes/rooms")
BACKDROP_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/floor2")
SCALE = 8  # Backdrop 400x400 scaled 8x = 3200x3200

ROOMS = [
    ("Floor2_Entry", "bg_entry.png"),
    ("Floor2_Upper", "bg_upper.png"),
    ("Floor2_Middle", "bg_middle.png"),
    ("Floor2_Lower", "bg_lower.png"),
    ("Floor2_Secret", "bg_secret.png"),
    ("Floor2_SporeHeart", "bg_spore_heart.png"),
]


def find_largest_bright_region(arr: np.ndarray, threshold: int = 40) -> np.ndarray:
    """Find largest connected region brighter than threshold."""
    # Binary mask
    mask = arr > threshold
    
    # Manual flood-fill to find connected components
    visited = np.zeros_like(mask, dtype=bool)
    largest = np.zeros_like(mask, dtype=bool)
    largest_size = 0
    
    h, w = mask.shape
    
    for y in range(h):
        for x in range(w):
            if mask[y, x] and not visited[y, x]:
                # BFS flood fill
                stack = [(y, x)]
                component = []
                visited[y, x] = True
                
                while stack:
                    cy, cx = stack.pop()
                    component.append((cy, cx))
                    
                    # Check 4 neighbors
                    for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < h and 0 <= nx < w:
                            if mask[ny, nx] and not visited[ny, nx]:
                                visited[ny, nx] = True
                                stack.append((ny, nx))
                
                if len(component) > largest_size:
                    largest_size = len(component)
                    largest = np.zeros_like(mask, dtype=bool)
                    for cy, cx in component:
                        largest[cy, cx] = True
    
    return largest


def trace_edge(mask: np.ndarray, step: int = 4) -> list:
    """
    Trace the edge of a binary mask by finding boundary pixels.
    Returns points sampled every 'step' pixels along the edge.
    """
    h, w = mask.shape
    
    # Find edge pixels: bright pixel with at least one dark neighbor
    edge = np.zeros_like(mask, dtype=bool)
    
    # Interior pixels (not on border)
    interior = mask[1:-1, 1:-1]
    
    # Check 4 neighbors
    has_dark_neighbor = (
        ~mask[0:-2, 1:-1] |   # top
        ~mask[2:, 1:-1] |     # bottom
        ~mask[1:-1, 0:-2] |   # left
        ~mask[1:-1, 2:]       # right
    )
    
    edge[1:-1, 1:-1] = interior & has_dark_neighbor
    
    # Get coordinates
    y_coords, x_coords = np.where(edge)
    
    if len(y_coords) < 10:
        return []
    
    # Sort by angle around centroid for a clean loop
    cx = float(np.mean(x_coords))
    cy = float(np.mean(y_coords))
    
    points = [(float(x_coords[i]), float(y_coords[i])) for i in range(len(x_coords))]
    points.sort(key=lambda p: math.atan2(p[1] - cy, p[0] - cx))
    
    # Sample every Nth point to reduce density
    sampled = points[::step]
    
    # Ensure we close the loop if first and last are close
    if len(sampled) > 2:
        dx = sampled[0][0] - sampled[-1][0]
        dy = sampled[0][1] - sampled[-1][1]
        if math.sqrt(dx*dx + dy*dy) > 20:
            sampled.append(sampled[0])
    
    return sampled


def simplify_polygon(points: list, tolerance: float = 3.0) -> list:
    """Simple polygon simplification by removing collinear points."""
    if len(points) < 3:
        return points
    
    simplified = [points[0]]
    
    for i in range(1, len(points) - 1):
        p_prev = simplified[-1]
        p_curr = points[i]
        p_next = points[i + 1]
        
        # Check if p_curr is roughly collinear
        dx1 = p_curr[0] - p_prev[0]
        dy1 = p_curr[1] - p_prev[1]
        dx2 = p_next[0] - p_curr[0]
        dy2 = p_next[1] - p_curr[1]
        
        mag1 = math.sqrt(dx1*dx1 + dy1*dy1)
        mag2 = math.sqrt(dx2*dx2 + dy2*dy2)
        
        if mag1 < 0.001 or mag2 < 0.001:
            continue
        
        # Cross product (area of parallelogram)
        cross = abs(dx1 * dy2 - dy1 * dx2)
        
        # If cross product is small relative to edge lengths, point is collinear
        if cross > tolerance * max(mag1, mag2):
            simplified.append(p_curr)
    
    simplified.append(points[-1])
    
    # Remove duplicate of first point if it was added as last
    if len(simplified) > 2:
        dx = simplified[0][0] - simplified[-1][0]
        dy = simplified[0][1] - simplified[-1][1]
        if math.sqrt(dx*dx + dy*dy) < tolerance:
            simplified.pop()
    
    return simplified


def generate_collision_walls(contour: list, scale: float = 8.0, wall_thickness: float = 60.0) -> list:
    """Convert traced contour into thick collision polygon segments."""
    if len(contour) < 3:
        return []
    
    walls = []
    n = len(contour)
    
    for i in range(n):
        p1 = contour[i]
        p2 = contour[(i + 1) % n]
        
        # Scale to game coordinates (backdrop center at ~200,200 maps to room center)
        x1, y1 = p1[0] * scale, p1[1] * scale
        x2, y2 = p2[0] * scale, p2[1] * scale
        
        dx = x2 - x1
        dy = y2 - y1
        mag = math.sqrt(dx * dx + dy * dy)
        if mag < 0.001:
            continue
        
        # Normal pointing outward
        nx = -dy / mag * (wall_thickness / 2)
        ny = dx / mag * (wall_thickness / 2)
        
        walls.append([
            (x1 - nx, y1 - ny),  # inner (floor side)
            (x2 - nx, y2 - ny),
            (x2 + nx, y2 + ny),  # outer (wall side)
            (x1 + nx, y1 + ny),
        ])
    
    return walls


def analyze_backdrop(image_path: Path) -> tuple:
    """Analyze backdrop and find optimal threshold."""
    img = Image.open(image_path).convert('L')
    arr = np.array(img)
    
    # Histogram analysis
    hist = np.histogram(arr, bins=50, range=(0, 255))[0]
    
    # Find valleys in histogram (good threshold candidates)
    # Simple approach: threshold at first significant drop
    total_pixels = arr.size
    
    # Cumulative distribution
    cumsum = np.cumsum(np.histogram(arr, bins=256, range=(0, 256))[0])
    
    # Find threshold where ~10-20% of pixels are "dark" (walls)
    for t in range(20, 100):
        dark_ratio = cumsum[t] / total_pixels
        if 0.05 <= dark_ratio <= 0.35:
            return arr, t
    
    # Fallback
    return arr, 40


def process_room(room_name: str, backdrop_file: str):
    backdrop_path = BACKDROP_DIR / backdrop_file
    scene_path = SCENES_DIR / f"{room_name}.tscn"
    
    if not backdrop_path.exists():
        print(f"  [SKIP] Backdrop not found: {backdrop_file}")
        return
    
    if not scene_path.exists():
        print(f"  [SKIP] Scene not found: {room_name}")
        return
    
    print(f"\n[PROCESS] {room_name}")
    
    # Analyze and trace
    arr, threshold = analyze_backdrop(backdrop_path)
    print(f"  [ANALYZE] Auto threshold: {threshold}")
    
    # Also try a lower threshold for dark images (PixelLab produces dark caverns)
    # The "floor" might only be ~15-25 brightness
    dark_threshold = max(8, int(np.percentile(arr, 35)))
    print(f"  [ANALYZE] Dark image adjusted threshold: {dark_threshold}")
    
    # Use the lower threshold for dark cavern images
    effective_threshold = min(threshold, dark_threshold)
    print(f"  [ANALYZE] Using effective threshold: {effective_threshold}")
    
    # Find largest bright region (floor)
    floor_mask = find_largest_bright_region(arr, effective_threshold)
    floor_pixels = np.sum(floor_mask)
    print(f"  [FLOOR] {floor_pixels} pixels ({floor_pixels/arr.size*100:.1f}%)")
    
    if floor_pixels < 100:
        print(f"  [WARN] Floor region too small, skipping")
        return
    
    # Trace edge
    contour = trace_edge(floor_mask, step=6)
    print(f"  [TRACE] {len(contour)} edge points")
    
    if len(contour) < 10:
        print(f"  [WARN] Not enough edge points, skipping")
        return
    
    # Simplify
    simplified = simplify_polygon(contour, tolerance=4.0)
    print(f"  [SIMPLIFY] Reduced to {len(simplified)} points")
    
    # Generate collision walls
    walls = generate_collision_walls(simplified, scale=SCALE, wall_thickness=60.0)
    print(f"  [WALLS] {len(walls)} collision segments")
    
    # Read and update scene
    content = scene_path.read_text()
    
    # Remove old walls
    content = re.sub(
        r'\n\[node name="Wall_\d+" type="CollisionPolygon2D" parent="Walls"\]\npolygon = PackedVector2Array\([^\)]*\)\n',
        '\n', content
    )
    content = re.sub(
        r'\n\[node name="WallSprite_\d+" type="Sprite2D" parent="Walls"\]\n(?:.*\n)*?\n(?=\[node name=|\Z)',
        '\n', content
    )
    
    # Find Walls node
    walls_match = re.search(r'\[node name="Walls" type="StaticBody2D" parent="\."\]\n', content)
    if not walls_match:
        print(f"  [WARN] Walls node not found")
        return
    
    insert_pos = walls_match.end()
    
    wall_lines = []
    for i, wall in enumerate(walls):
        pts = ", ".join(f"{x:.1f}, {y:.1f}" for x, y in wall)
        wall_lines.append(f'[node name="Wall_{i+1:03d}" type="CollisionPolygon2D" parent="Walls"]')
        wall_lines.append(f'polygon = PackedVector2Array({pts})')
        wall_lines.append('')
    
    content = content[:insert_pos] + '\n' + '\n'.join(wall_lines) + '\n' + content[insert_pos:]
    
    scene_path.write_text(content)
    print(f"  [OK] Saved {len(walls)} traced walls")


def main():
    print("=" * 60)
    print("Backdrop Wall Tracer (pure numpy)")
    print("=" * 60)
    
    for room_name, backdrop_file in ROOMS:
        process_room(room_name, backdrop_file)
    
    print("\n" + "=" * 60)
    print("WALL TRACING COMPLETE")
    print("=" * 60)
    print("\nRun 'python3 scripts/place_f2_wall_tiles_v2.py' to add visual sprites")


if __name__ == "__main__":
    main()
