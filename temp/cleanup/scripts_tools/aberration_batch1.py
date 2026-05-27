#!/usr/bin/env python3
"""
Pixel Lab API Sprite Generator - Aberration Faction Batch 1
"""

import requests
import base64
import os
import time
from pathlib import Path

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"
OUTPUT_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/enemies")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# First batch: 5 key Aberration enemies
SPRITES = [
    ("enemy_the_bug", "idle", "pixel art glitch insectoid creature, corrupted data bug, crawling code fragments, static interference, distorted limbs, corrupted antennae, digital corruption, horror, 64x64 transparent background", 64),
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
        print(f"[SKIP] {name}_{state}.png exists")
        return True
    
    try:
        resp = requests.post(
            f"{BASE_URL}/generate-image-pixflux",
            headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
            json={"description": prompt, "image_size": {"width": size, "height": size}, "no_background": True, "seed": 42},
            timeout=90
        )
        
        if resp.status_code == 200:
            data = resp.json()
            if "image" in data and data["image"]:
                img_bytes = base64.b64decode(data["image"])
                output_file.write_bytes(img_bytes)
                print(f"[OK] {name}_{state}.png ({len(img_bytes)} bytes)")
                return True
            else:
                print(f"[FAIL] {name}_{state}: No image in response")
                return False
        else:
            print(f"[FAIL] {name}_{state}: HTTP {resp.status_code}")
            return False
    except Exception as e:
        print(f"[ERROR] {name}_{state}: {e}")
        return False

def main():
    print("="*50)
    print("ABERRATION SPRITES - BATCH 1")
    print("="*50)
    
    success = 0
    for i, (name, state, prompt, size) in enumerate(SPRITES, 1):
        print(f"[{i}/{len(SPRITES)}] ", end="", flush=True)
        if generate(name, state, prompt, size):
            success += 1
        time.sleep(1)
    
    print(f"\nDone: {success}/{len(SPRITES)}")

if __name__ == "__main__":
    main()
