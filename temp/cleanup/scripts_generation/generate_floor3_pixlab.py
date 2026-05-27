#!/usr/bin/env python3
"""Floor 3 PixelLab Background Pass — The Gearworks (proper)"""
import requests, base64, io, time
from pathlib import Path
from PIL import Image

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"
OUT = Path("/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/floor3")

TARGET_SIZES = {
    "bg_beacon": (800, 600),
    "bg_bearing": (800, 600),
    "bg_counterweight": (800, 600),
    "bg_draft": (800, 600),
    "bg_escapement": (800, 600),
    "bg_flywheel": (800, 600),
    "bg_governor": (800, 600),
    "bg_oiler": (800, 600),
    "bg_quench": (800, 600),
    "bg_reservoir": (800, 600),
    "bg_spark": (800, 600),
    "bg_temper": (800, 600),
}

def generate(name, prompt, seed=800):
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
    ("bg_beacon", 800,
     "pixel art background, ancient clockwork gearworks interior, brass beacon tower in center, warm golden light, mechanical industrial interior, gears and pistons, steampunk factory, parallel projection, top down view, detailed pixel art"),
    ("bg_bearing", 801,
     "pixel art background, gearworks bearing chamber, smooth frictionless surfaces, polished brass and steel, mechanical precision, rotating bearing assembly, industrial steampunk interior, detailed pixel art"),
    ("bg_counterweight", 802,
     "pixel art background, gearworks counterweight room, massive hanging weights, chains and pulleys, balance mechanism, industrial steampunk interior, brass and iron, detailed pixel art"),
    ("bg_draft", 803,
     "pixel art background, gearworks ventilation shaft, steam pipes, air pressure valves, hissing steam, industrial fans, steampunk interior, brass and copper, detailed pixel art"),
    ("bg_escapement", 804,
     "pixel art background, gearworks escapement mechanism, ticking clockwork, pendulum, time regulation gears, precision clockwork interior, brass and steel, steampunk, detailed pixel art"),
    ("bg_flywheel", 805,
     "pixel art background, gearworks flywheel chamber, massive spinning wheel, momentum storage, kinetic energy, industrial steampunk interior, brass and iron, detailed pixel art"),
    ("bg_governor", 806,
     "pixel art background, gearworks governor room, speed regulation mechanism, spinning balls, control levers, industrial steampunk interior, brass and steel, detailed pixel art"),
    ("bg_oiler", 807,
     "pixel art background, gearworks maintenance chamber, oil reservoirs, lubrication pipes, dripping oil, mechanical maintenance, steampunk interior, brass and copper, detailed pixel art"),
    ("bg_quench", 808,
     "pixel art background, gearworks quench chamber, water cooling station, steam rising from hot metal, hissing water jets, industrial steampunk interior, detailed pixel art"),
    ("bg_reservoir", 809,
     "pixel art background, gearworks power reservoir, massive energy storage tank, glowing liquid, pipes and valves, industrial steampunk interior, brass and copper, detailed pixel art"),
    ("bg_spark", 810,
     "pixel art background, gearworks ignition chamber, electrical sparks, arcing lightning between coils, power generation, industrial steampunk interior, blue and orange sparks, detailed pixel art"),
    ("bg_temper", 811,
     "pixel art background, gearworks heat treatment furnace, glowing orange metal, heat haze, fire and coals, industrial forge interior, steampunk, detailed pixel art"),
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
