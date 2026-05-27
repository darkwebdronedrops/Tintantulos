#!/usr/bin/env python3
"""
Round 3 — Sculpture/Statue Hack for Boss Frames
Hypothesis: The model treats 'sculpture'/'miniature'/'diorama' as objects,
giving steeper angles than 'character'/'boss'/'enemy creature'.
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

ASSETS = []

BOSS_FRAMES = [
    ("idle", "bronze mechanical sculpture of a gear matriarch, viewed from above at 60 degrees, "
             "miniature model on a dark table, top of head and shoulders clearly visible from above, "
             "body foreshortened, arms and legs seen from above, tiny feet, calm imposing pose, "
             "multiple gear segments forming torso, dark industrial steampunk style"),
    ("damage", "bronze mechanical sculpture recoiling from impact, viewed from above at 60 degrees, "
                "miniature model on dark table, gear segments sparking, bronze plating dented, "
                "oil leaking, wounded mechanical matriarch, top-down perspective"),
    ("special", "bronze mechanical sculpture spawning smaller gears, viewed from above at 60 degrees, "
                 "miniature model on dark table, gears spinning rapidly, constructs emerging, "
                 "mechanical birth, top-down perspective, dark industrial steampunk"),
]

for frame_type, desc in BOSS_FRAMES:
    ASSETS.append({
        "name": f"boss_gear_mother_{frame_type}",
        "category": "bosses",
        "size": 200,
        "prompt": (
            "pixel art miniature sculpture, 200x200 game sprite, construct faction, "
            f"{desc}, muted metallic colors, transparent background, centered"
        ),
    })

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
        "seed": 44,
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
                print(f"[OK] {asset['name']}.png ({len(img_bytes)} bytes)")
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
    print("ROUND 3 — Sculpture Hack for Boss Frames")
    print("=" * 60)
    
    success = 0
    for i, asset in enumerate(ASSETS, 1):
        print(f"\n[{i}/{len(ASSETS)}] ", end="", flush=True)
        if generate_asset(asset)[0]:
            success += 1
        time.sleep(1.5)
    
    print(f"\n\nDONE: {success}/{len(ASSETS)}")


if __name__ == "__main__":
    main()
