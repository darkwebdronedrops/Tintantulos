#!/usr/bin/env python3
"""Floor 1 PixelLab Background Pass - Only backgrounds"""
import requests
import base64
import io
import time
from pathlib import Path
from PIL import Image

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"
OUT = Path("/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/floor1")

TARGET_SIZES = {
    "floor1_central": (1600, 1200),
    "floor1_north_door": (1400, 1000),
    "floor1_east_warren": (1400, 1000),
    "floor1_west_gauntlet": (1400, 1000),
    "floor1_south_shrine": (1400, 1000),
    "floor1_background": (1600, 1200),
}

def generate(name, prompt, seed=600):
    target_path = OUT / f"{name}.png"
    try:
        resp = requests.post(
            f"{BASE_URL}/generate-image-pixflux",
            headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
            json={
                "description": prompt,
                "image_size": {"width": 400, "height": 400},
                "no_background": False,
                "seed": seed,
            },
            timeout=120,
        )
        if resp.status_code == 200:
            data = resp.json()
            img_data = data.get("image")
            b64 = img_data.get("base64") if isinstance(img_data, dict) else (img_data if isinstance(img_data, str) else None)
            if b64:
                img_400 = Image.open(io.BytesIO(base64.b64decode(b64)))
                target = TARGET_SIZES.get(name, (800, 600))
                img_scaled = img_400.resize(target, Image.NEAREST)
                img_scaled.save(target_path)
                print(f"[OK] {name}.png {img_400.size} -> {target}")
                return True
        print(f"[FAIL] {name}: HTTP {resp.status_code}")
        return False
    except Exception as e:
        print(f"[ERROR] {name}: {e}")
        return False

JOBS = [
    ("floor1_central", 
     "pixel art background, brass and construct tutorial room, dark industrial steampunk floor, metallic tiles, brass gears embedded in floor, teal energy portal in center, hanging warm bulbs, steam pipes along walls, dark metal and brass colors, parallel projection, top down view, muted metallic palette"),
    ("floor1_north_door",
     "pixel art background, iron guardian door room, heavy fortress threshold, dark steel floor plates, rust streaks, ominous iron door in center, brass trim around door, warning signs, industrial steampunk, grey and rust"),
    ("floor1_east_warren",
     "pixel art background, construct goblin workshop floor, cluttered tinker's space, scrap metal piles, green copper patina, brass gears scattered, messy workbenches, goblin-sized tools, chaotic workshop, brown and green industrial"),
    ("floor1_west_gauntlet",
     "pixel art background, combat arena training floor, scarred metal plates, weapon marks and scratches, dark red rust stains, battle-tested steel, training dummies, fighting pit atmosphere, dark metal and blood rust"),
    ("floor1_south_shrine",
     "pixel art background, sacred brass shrine room, golden temple floor, holy geometry etched in metal, warm gold and white tones, offering altar, serene divine space, water droplet motifs, peaceful brass sanctuary"),
    ("floor1_background",
     "pixel art background, dark industrial steampunk portal room, mechanical environment, brass and dark metal, gears turning in walls, teal energy glows, distant machinery, beginning of the descent, first floor atmosphere, grimy industrial, muted metallic colors"),
]

if __name__ == "__main__":
    ok = 0; fail = 0
    for i, (name, prompt) in enumerate(JOBS, 1):
        print(f"[{i}/{len(JOBS)}] ", end="", flush=True)
        if generate(name, prompt, seed=600 + i):
            ok += 1
        else:
            fail += 1
        time.sleep(1.5)
    print(f"\nDONE: {ok}/{len(JOBS)} OK, {fail} failed")
