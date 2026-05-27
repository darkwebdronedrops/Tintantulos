#!/usr/bin/env python3
"""
PixelLab Tileset Generator — Floor 2: Fungal Cavern Wall Edges
Generates modular wall tileset pieces for organic cave boundaries.
Uses v2 API (create-image-pixflux) with seed-only mode (init_image is broken).

Usage:
    export PIXELLAB_API_KEY="7121a3bf-3da7-44e9-a18e-39582de2362f"
    python3 generate_f2_wall_tileset.py

Output: assets/sprites/floor2/walls/
"""

import os
import sys
import time
import base64
import requests
from pathlib import Path
from dataclasses import dataclass
from typing import List, Optional

# --- Config ---
API_KEY = os.environ.get("PIXELLAB_API_KEY", "7121a3bf-3da7-44e9-a18e-39582de2362f")
API_URL = "https://api.pixellab.ai/v2/create-image-pixflux"
OUTPUT_DIR = Path("assets/sprites/floor2/walls")
REQUEST_DELAY = 4  # Seconds between calls (slightly longer for tile consistency)
MAX_RETRIES = 3

# Ensure output dir exists
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# --- Tile Definitions ---
# Each tile is a modular wall piece. Size 64x64 for small segments, 128x128 for major features.
# All tiles share a consistent fungal cavern aesthetic.

@dataclass
class TileDef:
    filename: str
    width: int
    height: int
    prompt: str
    seed: int  # Fixed seed for visual consistency across tiles

# Base style shared across all tiles
BASE_STYLE = (
    "Pixel art tileset piece, {size}, transparent background. "
    "Dark fungal cavern wall edge, rocky surface with bioluminescent moss drips, "
    "irregular organic shape, chunky low-res pixel art style, "
    "consistent dark brown-grey rock palette with teal-green moss glow accents. "
    "Steampunk industrial cavern aesthetic."
)

WALL_TILES: List[TileDef] = [
    # --- Straight segments (most common) ---
    TileDef("wall_straight_n.png", 64, 64,
        BASE_STYLE.format(size="64x64") + " Horizontal wall top edge, flat top surface with moss overhang, bottom fades to transparency. North-facing wall segment.",
        seed=21001),
    
    TileDef("wall_straight_s.png", 64, 64,
        BASE_STYLE.format(size="64x64") + " Horizontal wall bottom edge, flat bottom surface with root tendrils, top fades to transparency. South-facing wall segment.",
        seed=21002),
    
    TileDef("wall_straight_w.png", 64, 64,
        BASE_STYLE.format(size="64x64") + " Vertical wall left edge, flat left surface with moss drips, right fades to transparency. West-facing wall segment.",
        seed=21003),
    
    TileDef("wall_straight_e.png", 64, 64,
        BASE_STYLE.format(size="64x64") + " Vertical wall right edge, flat right surface with moss drips, left fades to transparency. East-facing wall segment.",
        seed=21004),
    
    # --- Curved / organic segments (for bubble shapes) ---
    TileDef("wall_curve_nw.png", 64, 64,
        BASE_STYLE.format(size="64x64") + " Curved wall corner, concave arc from top-left to center, moss cluster at inner curve. Northwest inner curve segment.",
        seed=21005),
    
    TileDef("wall_curve_ne.png", 64, 64,
        BASE_STYLE.format(size="64x64") + " Curved wall corner, concave arc from top-right to center, moss cluster at inner curve. Northeast inner curve segment.",
        seed=21006),
    
    TileDef("wall_curve_sw.png", 64, 64,
        BASE_STYLE.format(size="64x64") + " Curved wall corner, concave arc from bottom-left to center, root cluster at inner curve. Southwest inner curve segment.",
        seed=21007),
    
    TileDef("wall_curve_se.png", 64, 64,
        BASE_STYLE.format(size="64x64") + " Curved wall corner, concave arc from bottom-right to center, root cluster at inner curve. Southeast inner curve segment.",
        seed=21008),
    
    # --- Outer curves (convex) ---
    TileDef("wall_outer_nw.png", 64, 64,
        BASE_STYLE.format(size="64x64") + " Curved wall corner, convex arc bulging to top-left, thick moss cap on outer edge. Northwest outer curve segment.",
        seed=21009),
    
    TileDef("wall_outer_ne.png", 64, 64,
        BASE_STYLE.format(size="64x64") + " Curved wall corner, convex arc bulging to top-right, thick moss cap on outer edge. Northeast outer curve segment.",
        seed=21010),
    
    TileDef("wall_outer_sw.png", 64, 64,
        BASE_STYLE.format(size="64x64") + " Curved wall corner, convex arc bulging to bottom-left, root tangle on outer edge. Southwest outer curve segment.",
        seed=21011),
    
    TileDef("wall_outer_se.png", 64, 64,
        BASE_STYLE.format(size="64x64") + " Curved wall corner, convex arc bulging to bottom-right, root tangle on outer edge. Southeast outer curve segment.",
        seed=21012),
    
    # --- End caps / terminals ---
    TileDef("wall_cap_n.png", 64, 64,
        BASE_STYLE.format(size="64x64") + " Wall end cap, rounded top terminal with heavy moss cluster, wall body below. North-facing end piece.",
        seed=21013),
    
    TileDef("wall_cap_s.png", 64, 64,
        BASE_STYLE.format(size="64x64") + " Wall end cap, rounded bottom terminal with root bundle, wall body above. South-facing end piece.",
        seed=21014),
    
    TileDef("wall_cap_w.png", 64, 64,
        BASE_STYLE.format(size="64x64") + " Wall end cap, rounded left terminal with moss and small glowing mushroom, wall body to right. West-facing end piece.",
        seed=21015),
    
    TileDef("wall_cap_e.png", 64, 64,
        BASE_STYLE.format(size="64x64") + " Wall end cap, rounded right terminal with moss and small glowing mushroom, wall body to left. East-facing end piece.",
        seed=21016),
    
    # --- Feature tiles (128x128 for visual interest) ---
    TileDef("wall_feature_moss_cluster.png", 128, 128,
        BASE_STYLE.format(size="128x128") + " Large moss cluster feature, dense hanging bioluminescent moss curtains, dripping spores, teal-green glow. Feature tile for wall decoration.",
        seed=21017),
    
    TileDef("wall_feature_crystal_growth.png", 128, 128,
        BASE_STYLE.format(size="128x128") + " Crystal growth on cave wall, small teal-blue mineral crystals emerging from rock, faint glow. Feature tile for wall decoration.",
        seed=21018),
    
    TileDef("wall_feature_fungal_shelf.png", 128, 128,
        BASE_STYLE.format(size="128x128") + " Fungal shelf protruding from wall, layered mushroom caps, brown and teal, spore dust particles. Feature tile for wall decoration.",
        seed=21019),
    
    TileDef("wall_feature_root_tangle.png", 128, 128,
        BASE_STYLE.format(size="128x128") + " Thick root tangle on cave wall, dark woody tendrils weaving across rock face, bioluminescent nodes at root joints. Feature tile for wall decoration.",
        seed=21020),
    
    # --- Diagonal segments (for hex-adjacent walls) ---
    TileDef("wall_diag_nw_se.png", 64, 64,
        BASE_STYLE.format(size="64x64") + " Diagonal wall segment, running from top-left to bottom-right, moss along upper edge. NW-SE diagonal wall piece.",
        seed=21021),
    
    TileDef("wall_diag_ne_sw.png", 64, 64,
        BASE_STYLE.format(size="64x64") + " Diagonal wall segment, running from top-right to bottom-left, moss along upper edge. NE-SW diagonal wall piece.",
        seed=21022),
]

# --- API ---

def generate_tile(tile: TileDef, api_key: str) -> bool:
    """Generate a single tile via PixelLab API. Returns True on success."""
    output_path = OUTPUT_DIR / tile.filename
    
    # Skip if already exists
    if output_path.exists():
        print(f"  [SKIP] {tile.filename} already exists")
        return True
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    payload = {
        "description": tile.prompt,
        "image_size": {"width": tile.width, "height": tile.height},
        "no_background": True,
        "text_guidance_scale": 8.0,
        "view": "high top-down",
        "detail": "highly detailed",
        "outline": "single color outline",
        "shading": "medium shading",
        "seed": tile.seed,
    }
    
    for attempt in range(MAX_RETRIES):
        try:
            print(f"  [GEN] {tile.filename} ({tile.width}x{tile.height}) — attempt {attempt + 1}/{MAX_RETRIES}")
            resp = requests.post(API_URL, headers=headers, json=payload, timeout=120)
            
            if resp.status_code == 200:
                data = resp.json()
                if "image" in data and "base64" in data["image"]:
                    b64_str = data["image"]["base64"]
                    if b64_str.startswith("data:image"):
                        b64_str = b64_str.split(",", 1)[1]
                    img_data = base64.b64decode(b64_str)
                    with open(output_path, "wb") as f:
                        f.write(img_data)
                    usage = data.get("usage", {})
                    print(f"  [OK]  {tile.filename} saved ({len(img_data)} bytes) — {usage}")
                    return True
                else:
                    print(f"  [ERR] No image in response: {list(data.keys())}")
                    
            elif resp.status_code == 429:
                print(f"  [RATE] Rate limited, waiting 30s...")
                time.sleep(30)
                continue
                
            elif resp.status_code == 401:
                print(f"  [ERR] API key invalid or expired")
                return False
                
            else:
                print(f"  [ERR] HTTP {resp.status_code}: {resp.text[:200]}")
                
        except requests.exceptions.Timeout:
            print(f"  [ERR] Timeout on attempt {attempt + 1}")
        except Exception as e:
            print(f"  [ERR] {type(e).__name__}: {e}")
        
        if attempt < MAX_RETRIES - 1:
            time.sleep(5 * (attempt + 1))
    
    print(f"  [FAIL] {tile.filename} — all retries exhausted")
    return False


def main():
    print("=" * 60)
    print("PixelLab Tileset Generator — Floor 2: Fungal Cavern Walls")
    print("=" * 60)
    print(f"API Key: {API_KEY[:8]}...{API_KEY[-4:]}")
    print(f"Output:  {OUTPUT_DIR}")
    print(f"Tiles:   {len(WALL_TILES)} total")
    print("=" * 60)
    
    if not API_KEY or API_KEY == "your-api-key-here":
        print("\n[ERROR] No API key found!")
        sys.exit(1)
    
    success_count = 0
    fail_count = 0
    skip_count = 0
    
    for tile in WALL_TILES:
        output_path = OUTPUT_DIR / tile.filename
        if output_path.exists():
            skip_count += 1
            print(f"  [SKIP] {tile.filename}")
            continue
        
        if generate_tile(tile, API_KEY):
            success_count += 1
        else:
            fail_count += 1
        
        time.sleep(REQUEST_DELAY)
    
    # Summary
    print("\n" + "=" * 60)
    print("GENERATION COMPLETE")
    print("=" * 60)
    print(f"Success:  {success_count}")
    print(f"Failed:   {fail_count}")
    print(f"Skipped:  {skip_count} (already exist)")
    print(f"Total:    {success_count + fail_count + skip_count}/{len(WALL_TILES)}")
    
    if fail_count > 0:
        print(f"\n[NOTE] {fail_count} tiles failed. Re-run to retry.")
    
    print(f"\nOutput directory: {OUTPUT_DIR.absolute()}")
    print("=" * 60)


if __name__ == "__main__":
    main()
