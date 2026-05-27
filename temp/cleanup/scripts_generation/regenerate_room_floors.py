#!/usr/bin/env python3
"""
Room Floor Tile Regeneration — ui_env/env_floor_*.png
These are the actual floor tiles used in each room scene.
Uses proven 'platform' hack.
Output: temp_regeneration/ui_env/
"""

import requests
import base64
import time
from pathlib import Path

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"
OUTPUT_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/temp_regeneration/ui_env")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

BASE = (
    "pixel art sprite, large flat platform viewed from 60 degrees above, "
    "tilted toward camera showing top surface and thick front edge, "
    "walkable dungeon floor, parallel projection, no vanishing points, "
    "256x256, transparent background, dark industrial steampunk style, muted metallic colors"
)

FLOORS = [
    ("env_floor_quench", "quench room floor, water-cooled metal plate, steam condensation, blue-copper tones, cooling system, riveted iron tread"),
    ("env_floor_spark", "spark room floor, fire-ignition themed metal, warm orange-red steel, furnace floor, ember glow, heat scorched"),
    ("env_floor_governor", "governor room floor, control mechanism themed, precision dials etched into metal plate, slate-gray steel, regulatory"),
    ("env_floor_draft", "draft room floor, airflow steam pipe themed, vented grating pattern, light steel blue, ventilation"),
    ("env_floor_temper", "temper room floor, heat treatment forge floor, firebrick red metal, anvil marks, scorched steel"),
    ("env_floor_beacon", "beacon room floor, tower peak floor, illuminated gold metal plate, highest point, radiant light etched"),
    ("env_floor_escapement", "escapement room floor, clockwork timekeeping themed, gear teeth pattern etched, steel blue metal, precision"),
    ("env_floor_bearing", "bearing room floor, friction reduction themed, smooth polished steel plate, silver, lubricated metal"),
    ("env_floor_flywheel", "flywheel room floor, spinning momentum themed, radial gear pattern etched, goldenrod metal, motion scars"),
    ("env_floor_counterweight", "counterweight room floor, balance scale motif, brass and copper tones, equilibrium etched"),
    ("env_floor_oiler", "oiler room floor, maintenance grease themed, oil-stained metal plate, olive drab, lubrication tread"),
]

def generate(name, prompt, seed=300):
    out = OUTPUT_DIR / f"{name}.png"
    if out.exists():
        print(f"[SKIP] {name}.png")
        return True
    try:
        resp = requests.post(
            f"{BASE_URL}/generate-image-pixflux",
            headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
            json={"description": f"{BASE}, {prompt}", "image_size": {"width": 256, "height": 256}, "no_background": True, "seed": seed},
            timeout=120,
        )
        if resp.status_code == 200:
            data = resp.json()
            img_data = data.get("image")
            img_b64 = img_data.get("base64") if isinstance(img_data, dict) else (img_data if isinstance(img_data, str) else None)
            if img_b64:
                out.write_bytes(base64.b64decode(img_b64))
                print(f"[OK] {name}.png")
                return True
        print(f"[FAIL] {name}: HTTP {resp.status_code}")
        return False
    except Exception as e:
        print(f"[ERROR] {name}: {e}")
        return False

def main():
    print(f"Generating {len(FLOORS)} room floor tiles...")
    ok = 0
    for i, (name, desc) in enumerate(FLOORS, 1):
        print(f"[{i}/{len(FLOORS)}] ", end="", flush=True)
        if generate(name, desc, seed=300 + i):
            ok += 1
        time.sleep(1.5)
    print(f"\nDONE: {ok}/{len(FLOORS)}")

if __name__ == "__main__":
    main()
