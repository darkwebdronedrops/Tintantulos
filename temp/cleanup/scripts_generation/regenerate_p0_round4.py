#!/usr/bin/env python3
"""
Round 4 — Extreme top-down language for the last boss frame
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

def generate(name, size, prompt):
    output_path = OUTPUT_DIR / "bosses" / f"{name}.png"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    if output_path.exists():
        print(f"[SKIP] {name}.png exists")
        return True
    
    try:
        resp = requests.post(
            f"{BASE_URL}/generate-image-pixflux",
            headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
            json={"description": prompt, "image_size": {"width": size, "height": size}, "no_background": True, "seed": 45},
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
                output_path.write_bytes(base64.b64decode(img_b64))
                print(f"[OK] {name}.png")
                return True
        print(f"[FAIL] {name}: HTTP {resp.status_code}")
        return False
    except Exception as e:
        print(f"[ERROR] {name}: {e}")
        return False

prompt = (
    "pixel art 200x200 game sprite, construct faction, "
    "mechanical gear-matriarch viewed from directly above, bird's eye view, "
    "top of head and shoulders dominate the image, body seen from above, "
    "arms and legs foreshortened, tiny feet at bottom, "
    "bronze and copper mechanical body made of interlocking gears, "
    "dark industrial steampunk style, muted metallic colors, "
    "transparent background, centered"
)

print("Round 4 — Final attempt for boss_gear_mother_idle")
if generate("boss_gear_mother_idle", 200, prompt):
    print("Generated. Analyze before moving.")
else:
    print("Generation failed.")
