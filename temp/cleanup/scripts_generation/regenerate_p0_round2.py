#!/usr/bin/env python3
"""
Round 2 P0 Regeneration — Category-Hacked Prompts
Goal: Trick the model into using its natural good angles for problematic categories.
"""

import requests
import base64
import os
import time
from pathlib import Path

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"
OUTPUT_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/temp_regeneration")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Base camera lock phrase used successfully for enemies/room objects
BASE_LOCK = (
    "pixel art sprite, dark industrial steampunk style, muted metallic colors, "
    "transparent background, centered, game asset"
)

# ============================================================================
# CATEGORY-HACKED ASSETS
# Using prompt structures that previously produced good angles
# ============================================================================

ASSETS = []

# --- FLOORS (hack: describe as 'large flat platform' not 'floor tile') ---
# The model produced ~50-60° for room objects. Trick it into treating floors as objects.
ASSETS.extend([
    {
        "name": "floor_gear_tile",
        "category": "floors",
        "size": 256,
        "prompt": (
            "pixel art sprite, large flat metal platform viewed from 60 degrees above, "
            "tilted toward camera showing top surface and thick front edge, "
            "metal floor plate with subtle embedded gear pattern etched into surface, "
            "industrial tread plate texture, rivets along edges, dark iron and brass tones, "
            "walkable dungeon floor, 256x256, transparent background, centered, "
            "dark industrial steampunk style, muted metallic colors"
        ),
        "replaces": "assets/sprites/room_objects/floor_gear_tile.png",
    },
    {
        "name": "env_floor_hex",
        "category": "floors",
        "size": 256,
        "prompt": (
            "pixel art sprite, large flat stone platform viewed from 60 degrees above, "
            "tilted toward camera showing top surface and thick front edge, "
            "hexagonal stone floor tile, geometric hex pattern, dark granite with brass inlay, "
            "walkable steampunk dungeon floor, gear motifs at hex vertices, "
            "256x256, transparent background, centered, "
            "dark industrial steampunk style, muted metallic colors"
        ),
        "replaces": "assets/sprites/ui_env/env_floor_hex.png",
    },
])

# --- BOSSES (hack: use 'enemy creature' framing instead of 'boss') ---
# The aberration batch produced ~55-60° for 'enemy creature'. Use that structure.
BOSS_FRAMES = [
    ("idle", "standing still, massive gear-construct matriarch, bronze and copper mechanical body, "
             "multiple gear segments forming torso, calm but imposing"),
    ("damage", "recoiling from hit, gear segments sparking, bronze plating dented, "
               "oil leaking from cracks, wounded mechanical matriarch"),
    ("special", "summoning smaller gear-constructs from torso, mechanical birth animation, "
                "gears spinning rapidly, constructs emerging from central cavity"),
]

for frame_type, desc in BOSS_FRAMES:
    ASSETS.append({
        "name": f"boss_gear_mother_{frame_type}",
        "category": "bosses",
        "size": 200,
        "prompt": (
            "pixel art enemy creature, 200x200 game sprite, construct faction, mechanical horror, "
            f"{desc}, dark industrial steampunk style, muted metallic colors, "
            "transparent background, centered"
        ),
        "replaces": f"assets/sprites/enemies/boss_gear_mother_{frame_type}.png",
    })

# ============================================================================
# GENERATION ENGINE (same as round 1, fixed base64 handling)
# ============================================================================

def generate_asset(asset):
    output_path = OUTPUT_DIR / asset["category"] / f"{asset['name']}.png"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    if output_path.exists():
        print(f"[SKIP] {asset['name']}.png already in temp")
        return True, "skipped"
    
    payload = {
        "description": asset["prompt"],
        "image_size": {"width": asset["size"], "height": asset["size"]},
        "no_background": True,
        "seed": 43,  # Different seed from round 1
    }
    
    try:
        resp = requests.post(
            f"{BASE_URL}/generate-image-pixflux",
            headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
            json=payload,
            timeout=120,
        )
        
        if resp.status_code == 200:
            data = resp.json()
            image_data = data.get("image")
            if isinstance(image_data, dict):
                img_b64 = image_data.get("base64")
            elif isinstance(image_data, str):
                img_b64 = image_data
            else:
                img_b64 = None
            if img_b64:
                img_bytes = base64.b64decode(img_b64)
                output_path.write_bytes(img_bytes)
                print(f"[OK] {asset['name']}.png ({len(img_bytes)} bytes, {asset['size']}x{asset['size']})")
                return True, "generated"
            else:
                print(f"[FAIL] {asset['name']}: No image data")
                return False, "no_image"
        else:
            print(f"[FAIL] {asset['name']}: HTTP {resp.status_code}")
            return False, f"http_{resp.status_code}"
    except Exception as e:
        print(f"[ERROR] {asset['name']}: {e}")
        return False, f"exception_{e}"


def main():
    print("=" * 60)
    print("ROUND 2 — Category-Hacked P0 Regeneration")
    print(f"Output: {OUTPUT_DIR}")
    print(f"Total: {len(ASSETS)} assets")
    print("=" * 60)
    
    success = 0
    failed = 0
    skipped = 0
    
    for i, asset in enumerate(ASSETS, 1):
        print(f"\n[{i}/{len(ASSETS)}] ", end="", flush=True)
        ok, status = generate_asset(asset)
        if ok:
            if status == "skipped":
                skipped += 1
            else:
                success += 1
        else:
            failed += 1
        time.sleep(1.5)
    
    print("\n" + "=" * 60)
    print(f"DONE: {success} generated, {skipped} skipped, {failed} failed")
    print("=" * 60)


if __name__ == "__main__":
    main()
