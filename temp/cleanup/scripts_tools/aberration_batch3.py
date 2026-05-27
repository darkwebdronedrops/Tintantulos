#!/usr/bin/env python3
"""
Pixel Lab API Sprite Generator - Aberration Faction Batch 3
More Aberration enemies: The Loop, The Lag, The Whisper, The Duplicate, The Forgotten
"""

import requests
import base64
import time
from pathlib import Path

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"
OUTPUT_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/enemies")

SPRITES = [
    # The Loop
    ("enemy_the_loop", "idle", "pixel art circular form, ouroboros serpent, infinite circle creature, snake eating its tail, endless cycle, loop entity, horror, 64x64 transparent", 64),
    ("enemy_the_loop", "cycle", "pixel art loop accelerating, circular motion blur, infinite recursion, cycle repeating faster, temporal horror, 64x64 transparent", 64),
    ("enemy_the_loop", "damage", "pixel art loop breaking, circle fracturing, ouroboros releasing tail, cycle interrupted, hurt animation, 64x64 transparent", 64),
    ("enemy_the_loop", "death", "pixel art loop collapsing, infinite circle closing, recursion ending, spiral finality, defeat, 64x64 transparent", 64),
    
    # The Lag
    ("enemy_the_lag", "idle", "pixel art stuttering figure, motion blur trails, frame skip entity, teleporting person, glitching between positions, temporal lag, 64x64 transparent", 64),
    ("enemy_the_lag", "skip", "pixel art lag entity jumping, frame skipping, position teleporting, stutter movement, temporal glitch, 64x64 transparent", 64),
    ("enemy_the_lag", "damage", "pixel art lag figure hit, motion trails distorting, frame drop, temporal disruption, hurt animation, 64x64 transparent", 64),
    ("enemy_the_lag", "death", "pixel art lag entity freezing, final frame held, motion stopping, temporal end, defeat, 64x64 transparent", 64),
    
    # The Whisper
    ("enemy_the_whisper", "idle", "pixel art dark cloud of murmurs, shadow mist with faces, whispering darkness, many mouths in fog, auditory horror, 64x64 transparent", 64),
    ("enemy_the_whisper", "speak", "pixel art whispers coalescing, dark cloud forming words, shadow mouths opening, secrets spoken, horror, 64x64 transparent", 64),
    ("enemy_the_whisper", "damage", "pixel art whisper cloud dispersing, murmurs scattered, dark fog thinning, voices silenced, hurt, 64x64 transparent", 64),
    ("enemy_the_whisper", "death", "pixel art whisper cloud vanishing, final silence, darkness dissipating, voices gone, defeat, 64x64 transparent", 64),
    
    # The Duplicate
    ("enemy_the_duplicate", "idle", "pixel art perfect copy of player, mirror image, doppelganger, exact double, twin entity, horror reflection, 64x64 transparent", 64),
    ("enemy_the_duplicate", "mimic", "pixel art duplicate copying action, mirror movement, doppelganger synchronizing, perfect imitation, horror, 64x64 transparent", 64),
    ("enemy_the_duplicate", "damage", "pixel art duplicate flickering, copy distorting, doppelganger destabilizing, mirror cracking, hurt, 64x64 transparent", 64),
    ("enemy_the_duplicate", "death", "pixel art duplicate fading, copy dissolving, doppelganger vanishing, mirror breaking, defeat, 64x64 transparent", 64),
    
    # The Forgotten
    ("enemy_the_forgotten", "idle", "pixel art fading silhouette, person becoming transparent, forgotten memory walking, existence eroding, memory horror, 64x64 transparent", 64),
    ("enemy_the_forgotten", "fade", "pixel art forgotten one fading further, transparency increasing, memory being lost, existence diminishing, horror, 64x64 transparent", 64),
    ("enemy_the_forgotten", "damage", "pixel art forgotten figure flickering, fading silhouette hit, memory disrupted, existence questioned, hurt, 64x64 transparent", 64),
    ("enemy_the_forgotten", "death", "pixel art forgotten one vanishing completely, memory erased, no longer exists, final fade, defeat, 64x64 transparent", 64),
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
    print("ABERRATION SPRITES - BATCH 3")
    print("="*60)
    
    success = 0
    for i, (name, state, prompt, size) in enumerate(SPRITES, 1):
        print(f"[{i:2}/{len(SPRITES)}] ", end="", flush=True)
        if generate(name, state, prompt, size):
            success += 1
        time.sleep(0.5)
    
    print(f"\nDONE: {success}/{len(SPRITES)}")

if __name__ == "__main__":
    main()
