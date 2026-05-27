#!/usr/bin/env python3
"""
Pixel Lab API Sprite Generator - Aberration Faction Batch 2
More key Aberration enemies
"""

import requests
import base64
import time
from pathlib import Path

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"
OUTPUT_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/enemies")

SPRITES = [
    # The Collar
    ("enemy_the_collar", "idle", "pixel art metallic collar floating, shadow figure attached, restraint device, controlling ring around neck, submission symbol, horror artifact, 64x64 transparent", 64),
    ("enemy_the_collar", "tighten", "pixel art collar constricting, metal closing, shadow choking, restraint tightening, control exerting, horror animation, 64x64 transparent", 64),
    ("enemy_the_collar", "damage", "pixel art collar struck, metal denting, shadow recoiling, restraint damaged, hurt animation, 64x64 transparent", 64),
    ("enemy_the_collar", "death", "pixel art collar breaking, metal shattering, shadow released, restraint destroyed, defeat, 64x64 transparent", 64),
    
    # The Cursor
    ("enemy_the_cursor", "idle", "pixel art floating mouse pointer arrow, cursor creature, digital arrowhead with eyes, UI element alive, computer cursor monster, 64x64 transparent", 64),
    ("enemy_the_cursor", "point", "pixel art cursor pointing aggressively, selecting targeting, arrow indicating direction, UI horror action, 64x64 transparent", 64),
    ("enemy_the_cursor", "damage", "pixel art cursor hit, arrow bending, pointer distorting, digital glitch, hurt animation, 64x64 transparent", 64),
    ("enemy_the_cursor", "death", "pixel art cursor breaking, arrow fragmenting, digital decay, pointer dissolving, defeat, 64x64 transparent", 64),
    
    # The Mirror
    ("enemy_the_mirror", "idle", "pixel art floating antique mirror, reflection showing wrong thing, silvered glass, ornate frame, reflection horror, 64x64 transparent", 64),
    ("enemy_the_mirror", "reflect", "pixel art mirror showing alternate reality, reflection moving independently, glass rippling, horror reflection, 64x64 transparent", 64),
    ("enemy_the_mirror", "damage", "pixel art mirror cracked, glass fracturing, reflection distorted, silver tarnishing, hurt animation, 64x64 transparent", 64),
    ("enemy_the_mirror", "death", "pixel art mirror shattering, glass breaking apart, reflection escaping, shards falling, defeat, 64x64 transparent", 64),
    
    # The Echo
    ("enemy_the_echo", "idle", "pixel art translucent figure, sound waves emanating, ghost of a person, audio waveform body, ethereal horror, 64x64 transparent", 64),
    ("enemy_the_echo", "repeat", "pixel art echo duplicating, waveform multiplying, sound becoming solid, ghost cloning, horror animation, 64x64 transparent", 64),
    ("enemy_the_echo", "damage", "pixel art echo distorting, waveform interference, ghost flickering, sound disrupted, hurt animation, 64x64 transparent", 64),
    ("enemy_the_echo", "death", "pixel art echo fading, waveform dissipating, ghost vanishing, sound dying out, silence, defeat, 64x64 transparent", 64),
]

def generate(name, state, prompt, size):
    output_file = OUTPUT_DIR / f"{name}_{state}.png"
    
    if output_file.exists() and output_file.stat().st_size > 100:
        print(f"[SKIP] {name}_{state}.png")
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
                    print(f"[OK] {name}_{state}.png ({len(img_bytes)} bytes)")
                    return True
        print(f"[FAIL] {name}_{state}")
        return False
    except Exception as e:
        print(f"[ERR] {name}_{state}: {e}")
        return False

def main():
    print("="*60)
    print("ABERRATION SPRITES - BATCH 2")
    print("="*60)
    
    success = 0
    for i, (name, state, prompt, size) in enumerate(SPRITES, 1):
        print(f"[{i:2}/{len(SPRITES)}] ", end="", flush=True)
        if generate(name, state, prompt, size):
            success += 1
        time.sleep(0.5)
    
    print(f"\nCOMPLETE: {success}/{len(SPRITES)}")
    
    total = len(list(OUTPUT_DIR.glob("enemy_the_*.png")))
    print(f"\nTotal Aberration sprites: {total}")

if __name__ == "__main__":
    main()
