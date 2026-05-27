#!/usr/bin/env python3
"""
Pixel Lab API Sprite Generator for Acanous Card Battler
Generates enemy sprites with transparency for Aberration faction
"""

import requests
import base64
import os
import json
import time
from pathlib import Path

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"
OUTPUT_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/enemies")

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

ABERRATION_SPRITES = [
    # name, state, prompt, size
    ("enemy_the_bug", "idle", "pixel art retro game sprite, glitch insectoid creature, corrupted data bug, crawling code fragments, static interference, distorted limbs, corrupted antennae, digital corruption, horror creature, 64x64", 64),
    ("enemy_the_bug", "glitch", "pixel art retro game sprite, glitch insect mid-corruption, body fragmenting into static, data scattering, screen tearing effect, digital distortion, horror creature, 64x64", 64),
    ("enemy_the_bug", "damage", "pixel art retro game sprite, glitch bug being hit, corruption spreading across body, static burst emanating, hurt pose, horror creature, 64x64", 64),
    ("enemy_the_bug", "death", "pixel art retro game sprite, glitch bug dissolving into pixels, data corruption consuming body, breaking apart, static fade, defeat animation, 64x64", 64),
    
    ("enemy_the_contagion", "idle", "pixel art retro game sprite, amorphous blob of corruption, viral infection form, spreading glitch tentacles, static membrane, infectious horror, organic digital hybrid, 64x64", 64),
    ("enemy_the_contagion", "spread", "pixel art retro game sprite, corruption expanding outward, viral tendrils reaching, glitch infection spreading, static waves emanating, horror creature, 64x64", 64),
    ("enemy_the_contagion", "damage", "pixel art retro game sprite, contagion blob hit, corruption recoiling, membrane tearing, static discharge, hurt animation, 64x64", 64),
    ("enemy_the_contagion", "death", "pixel art retro game sprite, contagion dissolving, corruption neutralized, static fading, blob collapsing, defeat animation, 64x64", 64),
    
    ("enemy_the_hollow", "idle", "pixel art retro game sprite, humanoid silhouette filled with void, empty darkness inside form, outline of person with abyss interior, void entity, horror, 64x64", 64),
    ("enemy_the_hollow", "consume", "pixel art retro game sprite, hollow figure opening void mouth, consuming darkness expanding, void portal opening, light being absorbed, horror entity, 64x64", 64),
    ("enemy_the_hollow", "damage", "pixel art retro game sprite, hollow figure struck, void flickering, outline destabilizing, darkness disturbed, hurt pose, 64x64", 64),
    ("enemy_the_hollow", "death", "pixel art retro game sprite, hollow figure collapsing, void dissipating, silhouette breaking apart, darkness fading to nothing, defeat, 64x64", 64),
    
    ("enemy_the_collar", "idle", "pixel art retro game sprite, metallic collar floating with shadow figure, restraint device, controlling ring, submission symbol, horror artifact, 64x64", 64),
    ("enemy_the_collar", "tighten", "pixel art retro game sprite, collar constricting, shadow figure choking, restraint tightening, control exerting, horror animation, 64x64", 64),
    ("enemy_the_collar", "damage", "pixel art retro game sprite, collar struck, metal denting, shadow recoiling, restraint damaged, hurt animation, 64x64", 64),
    ("enemy_the_collar", "death", "pixel art retro game sprite, collar breaking, metal shattering, shadow released, restraint destroyed, defeat animation, 64x64", 64),
    
    ("enemy_the_cursor", "idle", "pixel art retro game sprite, floating pointer arrow, mouse cursor creature, digital arrowhead with eyes, UI element come alive, horror cursor, 64x64", 64),
    ("enemy_the_cursor", "point", "pixel art retro game sprite, cursor pointing aggressively, selecting targeting, arrow indicating, UI horror action, 64x64", 64),
    ("enemy_the_cursor", "damage", "pixel art retro game sprite, cursor hit, arrow bending, pointer distorting, digital glitch, hurt animation, 64x64", 64),
    ("enemy_the_cursor", "death", "pixel art retro game sprite, cursor breaking, arrow fragmenting, digital decay, pointer dissolving, defeat, 64x64", 64),
]

def generate_sprite(name, state, prompt, size):
    """Generate a single sprite using Pixel Lab API"""
    output_file = OUTPUT_DIR / f"{name}_{state}.png"
    
    if output_file.exists():
        print(f"  [SKIP] {name}_{state}.png already exists")
        return True
    
    try:
        response = requests.post(
            f"{BASE_URL}/generate-image-pixflux",
            headers={
                "Authorization": f"Bearer {API_KEY}",
                "Content-Type": "application/json"
            },
            json={
                "description": prompt,
                "image_size": {"width": size, "height": size},
                "no_background": True,
                "seed": 42
            },
            timeout=60
        )
        
        if response.status_code == 200:
            data = response.json()
            if "image" in data:
                image_data = base64.b64decode(data["image"])
                output_file.write_bytes(image_data)
                print(f"  [OK] {name}_{state}.png ({len(image_data)} bytes)")
                return True
            else:
                print(f"  [FAIL] {name}_{state}: No image in response - {data}")
                return False
        else:
            print(f"  [FAIL] {name}_{state}: HTTP {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"  [ERROR] {name}_{state}: {e}")
        return False

def main():
    print("=" * 60)
    print("ABERRATION SPRITE GENERATION - BATCH 1")
    print("=" * 60)
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"Sprites to generate: {len(ABERRATION_SPRITES)}")
    print()
    
    success = 0
    failed = 0
    
    for i, (name, state, prompt, size) in enumerate(ABERRATION_SPRITES, 1):
        print(f"[{i}/{len(ABERRATION_SPRITES)}] ", end="")
        if generate_sprite(name, state, prompt, size):
            success += 1
        else:
            failed += 1
        time.sleep(0.5)  # Rate limiting
    
    print()
    print("=" * 60)
    print(f"BATCH 1 COMPLETE: {success} success, {failed} failed")
    print("=" * 60)
    
    # List generated files
    print("\nGenerated files:")
    for f in sorted(OUTPUT_DIR.glob("enemy_the_*.png")):
        size = f.stat().st_size
        print(f"  {f.name} ({size} bytes)")

if __name__ == "__main__":
    main()
