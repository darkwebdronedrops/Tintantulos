#!/usr/bin/env python3
"""
Final room objects batch — 19 remaining sprites
Uses proven 'object on floor' prompt hack
Output: temp_regeneration/room_objects/
"""

import requests
import base64
import time
from pathlib import Path

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"
OUTPUT_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/temp_regeneration/room_objects")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

BASE = (
    "pixel art sprite, dark industrial steampunk style, muted metallic colors, "
    "object sitting on factory floor, viewed from 60 degrees above, "
    "showing top and front surfaces, transparent background, centered"
)

OBJECTS = [
    ("beacon_lift_gear", 128, "beacon lift gear mechanism, vertical elevator gears, rising platform machinery, tower ascent equipment"),
    ("beacon_light_socket", 128, "beacon light crystal socket, empty prism holder, light emitter mount, golden crystal cradle"),
    ("bearing_grease_point", 64, "bearing grease fitting, small lubrication nipple, metal oil point, maintenance access"),
    ("counterweight_iron_block", 128, "counterweight iron block, heavy mass weight, solid cast iron, balance weight"),
    ("draft_steam_pipe", 128, "draft steam pipe, horizontal brass tube, ventilation piping, industrial plumbing"),
    ("draft_vent", 128, "draft air vent, louvered opening, airflow control vent, metal grate"),
    ("escapement_pendulum", 128, "escapement pendulum, swinging clock weight, timekeeping bob, brass pendulum arm"),
    ("escapement_tick_wheel", 128, "escapement tick wheel, toothed timing gear, clockwork escapement mechanism, precision gear"),
    ("flywheel_push_bar", 128, "flywheel push bar, horizontal lever for spinning wheel, momentum handle, iron bar"),
    ("governor_speed_dial", 64, "governor speed dial, small control gauge, RPM indicator, brass dial face"),
    ("oiler_sight_glass", 64, "oiler sight glass, small oil level window, transparent gauge, liquid indicator"),
    ("oiler_toolbox", 128, "oiler toolbox, maintenance tool chest, wrench and oil can storage, metal box"),
    ("quench_drain_grate", 64, "quench drain grate, floor drain cover, water runoff grid, metal grate"),
    ("quench_pipe_valve", 64, "quench water valve, flow control handle, pipe fitting, brass valve"),
    ("spark_boiler", 128, "spark boiler, steam boiler tank, pressure vessel, riveted iron cylinder"),
    ("spark_pressure_gauge", 64, "spark pressure gauge, steam pressure dial, boiler gauge, brass instrument"),
    ("temper_anvil", 128, "temper anvil, blacksmith anvil, heat treatment surface, dark iron block"),
    ("wall_pipe_section", 128, "wall pipe section, vertical pipe segment, plumbing mounted on wall, brass tube"),
]

def generate(name, size, prompt, seed=200):
    out = OUTPUT_DIR / f"{name}.png"
    if out.exists():
        print(f"[SKIP] {name}.png")
        return True
    try:
        resp = requests.post(
            f"{BASE_URL}/generate-image-pixflux",
            headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
            json={"description": f"{BASE}, {prompt}", "image_size": {"width": size, "height": size}, "no_background": True, "seed": seed},
            timeout=120,
        )
        if resp.status_code == 200:
            data = resp.json()
            img_data = data.get("image")
            img_b64 = img_data.get("base64") if isinstance(img_data, dict) else (img_data if isinstance(img_data, str) else None)
            if img_b64:
                out.write_bytes(base64.b64decode(img_b64))
                print(f"[OK] {name}.png ({size}x{size})")
                return True
        print(f"[FAIL] {name}: HTTP {resp.status_code}")
        return False
    except Exception as e:
        print(f"[ERROR] {name}: {e}")
        return False

def main():
    print(f"Generating {len(OBJECTS)} room objects...")
    ok = 0
    for i, (name, size, desc) in enumerate(OBJECTS, 1):
        print(f"[{i}/{len(OBJECTS)}] ", end="", flush=True)
        if generate(name, size, desc, seed=200 + i):
            ok += 1
        time.sleep(1.5)
    print(f"\nDONE: {ok}/{len(OBJECTS)}")

if __name__ == "__main__":
    main()
