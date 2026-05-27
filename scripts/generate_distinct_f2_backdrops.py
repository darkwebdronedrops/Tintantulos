#!/usr/bin/env python3
"""
Generate 6 visually distinct top-down backdrops for Floor 2.
Batched 2 at a time to avoid timeouts.
"""

import os
import time
import base64
import requests
from pathlib import Path

API_KEY = os.environ.get("PIXELLAB_API_KEY", "7121a3bf-3da7-44e9-a18e-39582de2362f")
API_URL = "https://api.pixellab.ai/v2/create-image-pixflux"
OUTPUT_DIR = Path("assets/sprites/floor2")

# VERY distinct prompts with different color palettes
BACKDROPS = [
    ("bg_entry.png",
     "Top-down pixel art, 400x400. Warm amber and brown fungal cavern floor. Wide open central clearing with a stone gateway arch in the center. Scattered orange-glowing mushrooms, dry moss patches in gold-yellow. Light brown rocky ground with warm cracks. Welcoming, bright for a cavern. Seamless edges."),
    
    ("bg_upper.png",
     "Top-down pixel art, 400x400. Deep purple and midnight blue fungal forest floor. Dense clusters of tall violet mushroom caps creating canopy shadows. Dark indigo ground with bioluminescent blue-white spore trails. Mysterious, dense, shadowy. Seamless edges."),
    
    ("bg_middle.png",
     "Top-down pixel art, 400x400. Teal-green and grey-brown fungal crossroads. Four-way intersection paths of pale green moss. Medium mushroom density in emerald and jade tones. Neutral balanced lighting. Seamless edges."),
    
    ("bg_lower.png",
     "Top-down pixel art, 400x400. Dark crimson and rusty brown deep cavern floor. Wet reflective blood-red pools. Sparse dying mushrooms in dark maroon. Heavy stalactite shadow patterns. Ominous, deep, dangerous. Seamless edges."),
    
    ("bg_secret.png",
     "Top-down pixel art, 400x400. Golden amber and copper hidden grotto floor. Rare glowing gold-capped mushrooms, treasure-like crystal formations in warm yellow. Intimate small space feel. Magical, precious. Seamless edges."),
    
    ("bg_spore_heart.png",
     "Top-down pixel art, 400x400. Intense white-cyan and dark purple boss arena floor. Massive radial fungal growth pattern emanating from center like a flower. Bright pulsing cyan veins in dark violet ground. Dramatic, intense, epic boss room. Seamless edges."),
]

def generate(filename, prompt):
    output_path = OUTPUT_DIR / filename
    backup = OUTPUT_DIR / (filename.replace(".png", "_v1.png"))
    if output_path.exists():
        os.rename(output_path, backup)
        print(f"  [BACKUP] {filename}")

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    payload = {
        "description": prompt,
        "image_size": {"width": 400, "height": 400},
        "no_background": False,
        "text_guidance_scale": 8.0,
        "view": "high top-down",
        "detail": "highly detailed",
        "outline": "single color outline",
        "shading": "medium shading",
    }

    print(f"  [GEN] {filename}...")
    try:
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
                print(f"  [OK]  {filename} ({len(img_data)} bytes)")
                return True
            else:
                print(f"  [ERR] No image in response")
        else:
            print(f"  [ERR] HTTP {resp.status_code}: {resp.text[:200]}")
    except Exception as e:
        print(f"  [ERR] {type(e).__name__}: {e}")
    return False

def main():
    print("=" * 60)
    print("Distinct Floor 2 Backdrops")
    print("=" * 60)
    
    success = 0
    for filename, prompt in BACKDROPS:
        if generate(filename, prompt):
            success += 1
        time.sleep(5)  # Longer delay between calls
    
    print(f"\nDone: {success}/{len(BACKDROPS)} generated")
    
    # Verify distinctness
    print("\nColor analysis:")
    from PIL import Image
    import numpy as np
    for filename, _ in BACKDROPS:
        path = OUTPUT_DIR / filename
        if path.exists():
            img = Image.open(path)
            arr = np.array(img.convert('RGB'))
            avg = arr.mean(axis=(0,1))
            print(f"  {filename}: RGB=({avg[0]:.1f}, {avg[1]:.1f}, {avg[2]:.1f})")

if __name__ == "__main__":
    main()
