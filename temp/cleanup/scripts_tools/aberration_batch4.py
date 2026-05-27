#!/usr/bin/env python3
"""
Pixel Lab API - Finish Batch 3 + Batch 4
Remaining Aberration enemies
"""

import requests
import base64
import time
from pathlib import Path

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"
OUTPUT_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/enemies")

SPRITES = [
    # Finish The Forgotten
    ("enemy_the_forgotten", "damage", "pixel art fading silhouette hit, forgotten figure struck, memory disruption, transparency glitch, hurt animation, 64x64 transparent", 64),
    ("enemy_the_forgotten", "death", "pixel art forgotten one vanishing completely, memory erased, final fade to nothing, defeat animation, 64x64 transparent", 64),
    
    # The Default
    ("enemy_the_default", "idle", "pixel art generic humanoid, default shape, template figure, blank slate creature, uncanny valley, horror, 64x64 transparent", 64),
    ("enemy_the_default", "reset", "pixel art default figure resetting, form returning to template, shape reformatting, default state, 64x64 transparent", 64),
    ("enemy_the_default", "damage", "pixel art default form hit, generic figure struck, template distorting, hurt animation, 64x64 transparent", 64),
    ("enemy_the_default", "death", "pixel art default figure dissolving, template erasing, generic form fading, defeat, 64x64 transparent", 64),
    
    # The Refrain
    ("enemy_the_refrain", "idle", "pixel art musical note creature, repeating melody form, song entity, chorus spirit, audio horror, 64x64 transparent", 64),
    ("enemy_the_refrain", "repeat", "pixel art refrain looping, musical phrase repeating, chorus building, song cycle, 64x64 transparent", 64),
    ("enemy_the_refrain", "damage", "pixel art refrain disrupted, musical note struck, melody breaking, song interrupted, hurt, 64x64 transparent", 64),
    ("enemy_the_refrain", "death", "pixel art refrain ending, final note held, song complete, melody fading, defeat, 64x64 transparent", 64),
]

def generate(name, state, prompt, size):
    output_file = OUTPUT_DIR / f"{name}_{state}.png"
    
    if output_file.exists() and output_file.stat().st_size > 100:
        print(f"[SKIP] {name}_{state}")
        return True
    
    try:
        resp = requests.post(
            f"{BASE_URL}/generate-image-pixflux",
            headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
            json={"description": prompt, "image_size": {"width": size, "height": size}, "no_background": True, "seed": 42},
            timeout=120
        )
        
        if resp.status_code == 200:
            data = resp.json()
            if "image" in data and isinstance(data["image"], dict) and "base64" in data["image"]:
                img_bytes = base64.b64decode(data["image"]["base64"])
                if len(img_bytes) > 100:
                    output_file.write_bytes(img_bytes)
                    print(f"[OK] {name}_{state}.png ({len(img_bytes)}b)")
                    return True
        print(f"[FAIL] {name}_{state}")
        return False
    except Exception as e:
        print(f"[ERR] {name}_{state}: {e}")
        return False

def main():
    print("="*60)
    print("ABERRATION SPRITES - BATCH 4 (Finish + New)")
    print("="*60)
    
    success = 0
    for i, (name, state, prompt, size) in enumerate(SPRITES, 1):
        print(f"[{i:2}/{len(SPRITES)}] ", end="", flush=True)
        if generate(name, state, prompt, size):
            success += 1
        time.sleep(0.5)
    
    print(f"\nDONE: {success}/{len(SPRITES)}")
    
    total = len(list(OUTPUT_DIR.glob("enemy_the_*.png")))
    print(f"Total 'The' sprites: {total}")

if __name__ == "__main__":
    main()
