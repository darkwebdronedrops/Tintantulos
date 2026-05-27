#!/usr/bin/env python3
"""
Pixel Lab API Sprite Generator - Aberration Faction Batch 1 (FIXED)
"""

import requests
import base64
import time
from pathlib import Path

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"
OUTPUT_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/enemies")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

SPRITES = [
    ("enemy_the_bug", "attack", "pixel art glitch insect attacking, corrupted bug striking, static burst, aggressive pose, digital distortion, horror creature, 64x64 transparent background", 64),
    ("enemy_the_bug", "damage", "pixel art glitch bug being hit, corruption recoiling, static discharge, hurt pose, damaged insectoid, horror, 64x64 transparent background", 64),
    ("enemy_the_bug", "death", "pixel art glitch bug dissolving into pixels, corruption consuming body, breaking apart, static fade, defeat, 64x64 transparent background", 64),
    
    ("enemy_the_contagion", "idle", "pixel art amorphous blob of corruption, viral infection form, spreading glitch tendrils, static membrane, infectious horror, organic digital hybrid, 64x64 transparent background", 64),
    ("enemy_the_contagion", "spread", "pixel art corruption expanding outward, viral tendrils reaching, glitch infection spreading, static waves emanating, horror creature, 64x64 transparent background", 64),
    ("enemy_the_contagion", "damage", "pixel art contagion blob hit, corruption recoiling, membrane tearing, static discharge, hurt animation, 64x64 transparent background", 64),
    ("enemy_the_contagion", "death", "pixel art contagion dissolving, corruption neutralized, static fading, blob collapsing, defeat, 64x64 transparent background", 64),
    
    ("enemy_the_hollow", "idle", "pixel art humanoid silhouette filled with void, empty darkness inside form, outline of person with abyss interior, void entity, horror, 64x64 transparent background", 64),
    ("enemy_the_hollow", "consume", "pixel art hollow figure opening void mouth, consuming darkness expanding, void portal opening, light being absorbed, horror entity, 64x64 transparent background", 64),
    ("enemy_the_hollow", "damage", "pixel art hollow figure struck, void flickering, outline destabilizing, darkness disturbed, hurt pose, 64x64 transparent background", 64),
    ("enemy_the_hollow", "death", "pixel art hollow figure collapsing, void dissipating, silhouette breaking apart, darkness fading to nothing, defeat, 64x64 transparent background", 64),
]

def generate(name, state, prompt, size):
    output_file = OUTPUT_DIR / f"{name}_{state}.png"
    
    if output_file.exists():
        print(f"[SKIP] {name}_{state}.png exists ({output_file.stat().st_size} bytes)")
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
            # image is a dict with "type" and "base64" fields
            if "image" in data and isinstance(data["image"], dict) and "base64" in data["image"]:
                img_bytes = base64.b64decode(data["image"]["base64"])
                output_file.write_bytes(img_bytes)
                print(f"[OK] {name}_{state}.png ({len(img_bytes)} bytes)")
                return True
            else:
                print(f"[FAIL] {name}_{state}: Unexpected response structure")
                return False
        else:
            print(f"[FAIL] {name}_{state}: HTTP {resp.status_code}")
            return False
    except Exception as e:
        print(f"[ERROR] {name}_{state}: {e}")
        return False

def main():
    print("="*60)
    print("ABERRATION SPRITES - BATCH 1 (FIXED)")
    print("="*60)
    
    success = 0
    for i, (name, state, prompt, size) in enumerate(SPRITES, 1):
        print(f"[{i:2}/{len(SPRITES)}] ", end="", flush=True)
        if generate(name, state, prompt, size):
            success += 1
        time.sleep(0.5)
    
    print(f"\n{'='*60}")
    print(f"COMPLETE: {success}/{len(SPRITES)} sprites generated")
    print(f"{'='*60}")
    
    # Show what we have
    print("\nCurrent Aberration sprites:")
    for f in sorted(OUTPUT_DIR.glob("enemy_the_*.png")):
        print(f"  {f.name} ({f.stat().st_size} bytes)")

if __name__ == "__main__":
    main()
