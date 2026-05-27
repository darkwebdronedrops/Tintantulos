#!/usr/bin/env python3
"""
Generate top-down fungal cavern backdrops for Floor 2.
Uses PixelLab API v2 (max 400x400) — scaled up in Godot scenes.

Usage:
    export PIXELLAB_API_KEY="7121a3bf-3da7-44e9-a18e-39582de2362f"
    python3 generate_f2_backdrops.py
"""

import os
import time
import base64
import requests
from pathlib import Path

API_KEY = os.environ.get("PIXELLAB_API_KEY", "7121a3bf-3da7-44e9-a18e-39582de2362f")
API_URL = "https://api.pixellab.ai/v2/create-image-pixflux"
OUTPUT_DIR = Path("assets/sprites/floor2")
REQUEST_DELAY = 4
MAX_RETRIES = 3

BASE_STYLE = (
    "Top-down pixel art background, 400x400, aerial view looking straight down from above. "
    "Dark fungal cavern floor, rocky surface with patches of bioluminescent teal-green moss, "
    "mushroom caps seen from above (circular spotted caps in purple and pink), "
    "stalactite shadows on ground, spore dust particles, cave floor cracks with faint cyan glow. "
    "Chunky low-res pixel art style, dark brown-grey rock palette with bright teal-green and purple-pink accents. "
    "Seamless tiling edges, no characters, no horizon, pure top-down perspective."
)

BACKDROPS = [
    ("bg_entry.png", BASE_STYLE + " Wide open entry cavern, central pathway leading north, scattered small mushrooms, welcoming central area."),
    ("bg_upper.png", BASE_STYLE + " Upper cavern with dense mushroom forest, towering mushroom caps from above, narrow winding paths, more purple tones."),
    ("bg_middle.png", BASE_STYLE + " Middle cavern, balanced mix of open floor and mushroom clusters, crossroads area with mossy intersections."),
    ("bg_lower.png", BASE_STYLE + " Lower cavern near depths, darker floor with more cracks and glowing cyan fissures, root tendrils across ground, wet reflective patches."),
    ("bg_secret.png", BASE_STYLE + " Hidden secret grotto, rare golden mushroom caps, denser teal moss concentration, mysterious glowing symbols on floor, intimate smaller space."),
    ("bg_spore_heart.png", BASE_STYLE + " Spore Heart chamber, massive central fungal growth seen from above like a giant flower, radial pattern of moss veins, intense bioluminescence, boss arena feel."),
    ("bg_fungal_cavern.png", BASE_STYLE + " Generic fungal cavern floor, moderate mushroom density, balanced mix of all elements, standard cave room."),
]

def generate(filename, prompt):
    output_path = OUTPUT_DIR / filename
    if output_path.exists():
        backup = OUTPUT_DIR / (filename.replace(".png", "_old.png"))
        os.rename(output_path, backup)
        print(f"  [BACKUP] {filename} -> {backup.name}")

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

    for attempt in range(MAX_RETRIES):
        try:
            print(f"  [GEN] {filename} — attempt {attempt + 1}/{MAX_RETRIES}")
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
                    print(f"  [OK]  {filename} saved ({len(img_data)} bytes)")
                    return True
                else:
                    print(f"  [ERR] No image in response: {list(data.keys())}")
            elif resp.status_code == 429:
                print(f"  [RATE] Rate limited, waiting 30s...")
                time.sleep(30)
                continue
            elif resp.status_code == 401:
                print(f"  [ERR] API key invalid")
                return False
            else:
                print(f"  [ERR] HTTP {resp.status_code}: {resp.text[:200]}")
        except requests.exceptions.Timeout:
            print(f"  [ERR] Timeout on attempt {attempt + 1}")
        except Exception as e:
            print(f"  [ERR] {type(e).__name__}: {e}")

        if attempt < MAX_RETRIES - 1:
            time.sleep(5 * (attempt + 1))

    print(f"  [FAIL] {filename} — all retries exhausted")
    return False

def update_scene_scales():
    """Update Floor2 scene files to scale backgrounds to fill viewport."""
    scenes_dir = Path("scenes/rooms")
    rooms = ["Floor2_Entry", "Floor2_Upper", "Floor2_Middle", 
             "Floor2_Lower", "Floor2_Secret", "Floor2_SporeHeart"]

    for room in rooms:
        filepath = scenes_dir / f"{room}.tscn"
        if not filepath.exists():
            continue

        content = filepath.read_text()

        # Update Background sprite scale to 5x for 400x400 -> 2000x2000 coverage
        # Only if it's currently scale = Vector2(1, 1)
        content = content.replace(
            'scale = Vector2(1, 1)\ntexture = ExtResource("2_bg")',
            'scale = Vector2(5, 5)\ntexture = ExtResource("2_bg")'
        )
        # Also try without texture line
        content = content.replace(
            '[node name="Background" type="Sprite2D" parent="Interior"]\nposition = Vector2(960, 900)\ntexture = ExtResource("2_bg")\nscale = Vector2(1, 1)',
            '[node name="Background" type="Sprite2D" parent="Interior"]\nposition = Vector2(960, 900)\ntexture = ExtResource("2_bg")\nscale = Vector2(5, 5)'
        )

        filepath.write_text(content)
        print(f"  [UPDATED] {room}.tscn scale -> 5x")

def main():
    print("=" * 60)
    print("Floor 2 Top-Down Backdrop Generator")
    print("=" * 60)
    print(f"Output: {OUTPUT_DIR}")
    print(f"Rooms:  {len(BACKDROPS)}")
    print("=" * 60)

    success = 0
    fail = 0

    for filename, prompt in BACKDROPS:
        if generate(filename, prompt):
            success += 1
        else:
            fail += 1
        time.sleep(REQUEST_DELAY)

    print("\n" + "=" * 60)
    print(f"Done: {success} success, {fail} failed")
    print("=" * 60)

    if success > 0:
        print("\nUpdating scene scales...")
        update_scene_scales()
        print("\n[NOTE] Run 'godot --headless --import' to re-import new textures.")

if __name__ == "__main__":
    main()
