#!/usr/bin/env python3
"""
Terrain Hex Regeneration — Floor 3: The Gearworks
Uses 'platform' hack: "large flat platform viewed from 60 degrees above"
Output: temp_regeneration/terrain/
"""

import requests
import base64
import time
from pathlib import Path

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"
OUTPUT_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/temp_regeneration/terrain")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

BASE_PROMPT = (
    "pixel art sprite, large flat platform viewed from 60 degrees above, "
    "tilted toward camera showing top surface and thick front edge, "
    "parallel projection, no vanishing points, 64x64, transparent background, "
    "dark industrial steampunk style, muted metallic colors, centered"
)

TERRAIN = [
    # --- Base tiles (5) ---
    ("hex_base_brass", "brass-colored metal floor plate, golden-bronze industrial tread, rivets, warm metallic"),
    ("hex_base_dark", "dark iron floor plate, blackened steel, industrial grating, dark metal"),
    ("hex_base_luminous", "glowing luminous floor plate, faint blue-white light emanating, bioluminescent metal, ethereal"),
    ("hex_base_metal", "standard iron floor plate, gray steel, industrial tread, neutral metal"),
    # --- Room tiles (11) ---
    ("hex_room_quench", "quench room floor, water-cooled metal, steam condensation, blue-copper tones, cooling tower floor"),
    ("hex_room_spark", "spark room floor, fire-ignition themed, warm orange-red metal, furnace floor, ember glow"),
    ("hex_room_governor", "governor room floor, control mechanism themed, precision dials etched into metal, slate-gray"),
    ("hex_room_draft", "draft room floor, airflow steam pipes, vented grating, light steel blue"),
    ("hex_room_temper", "temper room floor, heat treatment forge floor, firebrick red, anvil marks"),
    ("hex_room_beacon", "beacon room floor, tower peak floor, illuminated gold metal, highest point"),
    ("hex_room_escapement", "escapement room floor, clockwork timekeeping, gear teeth pattern, steel blue"),
    ("hex_room_bearing", "bearing room floor, friction reduction themed, smooth polished steel, silver"),
    ("hex_room_flywheel", "flywheel room floor, spinning momentum, radial gear pattern, goldenrod metal"),
    ("hex_room_counterweight", "counterweight room floor, balance scale motif, brass and copper"),
    ("hex_room_oiler", "oiler room floor, maintenance grease, oil-stained metal, olive drab"),
    # --- Special tiles (24) ---
    ("hex_emitter_off", "inactive light emitter platform, dark crystal socket, no glow, dormant"),
    ("hex_emitter_on", "active light emitter platform, glowing crystal prism, golden beam source, illuminated"),
    ("hex_gear_large", "large gear embedded in floor, massive cog wheel, teeth visible, iron"),
    ("hex_gear_small", "small gear embedded in floor, tiny cog, precision mechanism, brass"),
    ("hex_grate", "floor grate, metal grid, drain cover, see-through grid pattern"),
    ("hex_inefficient", "broken inefficient tile, cracked and glitching, error pattern, damaged machinery"),
    ("hex_mirror", "mirror reflection tile, polished silver surface, reflective metal"),
    ("hex_oil_pool", "oil pool hazard, dark viscous liquid, grease spill, reflective black"),
    ("hex_pipe_corner", "corner pipe segment, brass elbow joint, 90-degree turn, plumbing"),
    ("hex_pipe_horizontal", "horizontal pipe segment, straight brass tube, industrial plumbing"),
    ("hex_pipe_vertical", "vertical pipe segment, straight brass tube, rising plumbing"),
    ("hex_piston", "piston mechanism, vertical iron cylinder, steam-powered, mechanical"),
    ("hex_pressure_active", "pressure plate active, depressed metal switch, glowing indicator, triggered"),
    ("hex_pressure_plate", "pressure plate inactive, flat metal switch, waiting to be stepped on"),
    ("hex_receiver", "light receiver sensor, crystal detector, beam target, sensor plate"),
    ("hex_spawn_construct", "construct spawn point, gear emergence portal, mechanical birth location"),
    ("hex_spawn_demon", "demon spawn point, friction spirit portal, heat kami emergence"),
    ("hex_spawn_glitch", "glitch spawn point, aberration portal, static distortion location"),
    ("hex_spawn_goblin", "goblin spawn point, scavenger hole, small creature entrance"),
    ("hex_switch", "lever switch tile, iron toggle mechanism, on-off control"),
    ("hex_trap_cog", "grasping cog trap, gear tooth hazard, sweeping blade mechanism"),
    ("hex_trap_compress", "compression trap, ceiling lowering hazard, falling gears"),
    ("hex_trap_pit", "pitfall trap, open hole in floor, gear works below, danger"),
]

def generate(name, prompt, size=64, seed=50):
    out = OUTPUT_DIR / f"{name}.png"
    if out.exists():
        print(f"[SKIP] {name}.png")
        return True
    try:
        resp = requests.post(
            f"{BASE_URL}/generate-image-pixflux",
            headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
            json={"description": f"{BASE_PROMPT}, {prompt}", "image_size": {"width": size, "height": size}, "no_background": True, "seed": seed},
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
    print(f"Generating {len(TERRAIN)} terrain hex tiles...")
    ok = 0
    for i, (name, desc) in enumerate(TERRAIN, 1):
        print(f"[{i}/{len(TERRAIN)}] ", end="", flush=True)
        if generate(name, desc, seed=50 + i):
            ok += 1
        time.sleep(1.5)
    print(f"\nDONE: {ok}/{len(TERRAIN)}")

if __name__ == "__main__":
    main()
