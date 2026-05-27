#!/usr/bin/env python3
"""Floor 2 PixelLab Background Pass — Fungal Cavern"""
import requests, base64, io, time
from pathlib import Path
from PIL import Image

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"
OUT = Path("/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/floor2")

TARGET_SIZES = {
    "bg_entry": (3120, 1400),
    "bg_upper": (2720, 1600),
    "bg_middle": (2200, 1600),
    "bg_lower": (2320, 1600),
    "bg_spore_heart": (2400, 1600),
    "bg_secret": (1920, 1080),
}

def generate(name, prompt, seed=700):
    target_path = OUT / f"{name}.png"
    try:
        resp = requests.post(
            f"{BASE_URL}/generate-image-pixflux",
            headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
            json={"description": prompt, "image_size": {"width": 400, "height": 400}, "no_background": False, "seed": seed},
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
    ("bg_entry", 700,
     "pixel art background, fungal cavern entry, bioluminescent mushroom forest, purple and green glowing spores, soft cavern light, giant mushroom stalks, mycelium floor, underground fungal network, beautiful and deadly, parallel projection, top down view"),
    ("bg_upper", 701,
     "pixel art background, upper fungal cavern, glowing mushroom caps as platforms, drifting spore clouds, bioluminescent green and purple, fungal bridges, cavern ceiling with hanging mycelium, ethereal underground forest"),
    ("bg_middle", 702,
     "pixel art background, waterlogged fungal grotto, bioluminescent pool in center, glowing blue and green water, floating mushroom platforms, damp cavern walls, underground lake, magical steampunk, fungal overgrowth"),
    ("bg_lower", 703,
     "pixel art background, ancient construct excavation site overgrown with fungus, brass gears embedded in mushroom growth, industrial cavern reclaimed by nature, brown and green, ancient machinery covered in fungal tendrils, underground ruins"),
    ("bg_spore_heart", 704,
     "pixel art background, massive fungal boss arena, giant mushroom throne in center, pulsing spore heart, bioluminescent purple and green, fungal tendrils everywhere, sacred fungal chamber, epic underground, the flesh garden"),
    ("bg_secret", 705,
     "pixel art background, hidden fungal passage, narrow secret cavern, glowing mushrooms in cracks, mysterious underground tunnel, purple spore light, hidden treasure vibe, intimate fungal space"),
]

if __name__ == "__main__":
    ok = 0; fail = 0
    for i, (name, seed, prompt) in enumerate(JOBS, 1):
        print(f"[{i}/{len(JOBS)}] ", end="", flush=True)
        if generate(name, prompt, seed):
            ok += 1
        else:
            fail += 1
        time.sleep(1.5)
    print(f"\nDONE: {ok}/{len(JOBS)} OK, {fail} failed")
