#!/usr/bin/env python3
"""
Puzzle Sprite Regeneration — Floor 3: The Gearworks
Uses 'object on floor' hack that worked for room objects.
Output: temp_regeneration/puzzles/
"""

import requests
import base64
import time
from pathlib import Path

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"
OUTPUT_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/temp_regeneration/puzzles")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

BASE_64 = (
    "pixel art sprite, dark industrial steampunk style, muted metallic colors, "
    "object sitting on factory floor, viewed from 60 degrees above, "
    "showing top and front surfaces, transparent background, centered"
)

BASE_128 = (
    "pixel art sprite, dark industrial steampunk style, muted metallic colors, "
    "large object sitting on factory floor, viewed from 60 degrees above, "
    "showing top and front surfaces, transparent background, centered"
)

PUZZLES = [
    # --- Kami icons (12 files, 64x64) ---
    ("kami_friction", 64, "friction kami spirit, small mechanical spirit, gear teeth motif, orange sparks, tiny spirit"),
    ("kami_heat", 64, "heat kami spirit, small flame spirit, steam and fire, red-orange glow, tiny spirit"),
    ("kami_heat_treatment", 64, "heat treatment kami, forge spirit, anvil and flame, red-gold, tiny spirit"),
    ("kami_light", 64, "light kami spirit, small luminous spirit, crystal glow, white-gold, tiny spirit"),
    ("kami_maintenance", 64, "maintenance kami, oil and wrench spirit, grease and tools, olive-brown, tiny spirit"),
    ("kami_momentum", 64, "momentum kami, spinning spirit, wheel and motion, golden, tiny spirit"),
    ("kami_regulation", 64, "regulation kami, control spirit, dial and gauge, slate blue, tiny spirit"),
    ("kami_steam", 64, "steam kami spirit, vapor spirit, pipe and condensation, light blue, tiny spirit"),
    ("kami_time", 64, "time kami spirit, clockwork spirit, pendulum and gears, steel blue, tiny spirit"),
    ("kami_water", 64, "water kami spirit, cooling spirit, droplet and condensation, cornflower blue, tiny spirit"),
    ("kami_balance", 64, "balance kami spirit, scale spirit, equilibrium, brass, tiny spirit"),
    ("kami_friction2", 64, "friction spirit, industrial demon, heat and spark, gear-based, tiny spirit"),
    # --- Puzzle objects (128x128) ---
    ("puzzle_bearing_housing", 128, "bearing housing puzzle object, cylindrical metal casing, grease fitting visible"),
    ("puzzle_bearing_oilcan", 128, "oil can for bearing lubrication, metal oiler with spout, maintenance tool"),
    ("puzzle_beacon_crystal", 128, "beacon light crystal, tall glowing prism, light emitter, golden-white"),
    ("puzzle_beacon_lift", 128, "beacon lift mechanism, vertical elevator platform, rising platform"),
    ("puzzle_beacon_peak", 128, "beacon peak tower, highest point structure, tall spire, illuminated top"),
    ("puzzle_beacon_platform", 128, "beacon platform, circular stage at peak, observation deck"),
    ("puzzle_counterweight_pan", 128, "counterweight balance pan, scale weighing dish, brass pan hanging"),
    ("puzzle_counterweight_scale", 128, "counterweight scale mechanism, beam balance, precision scale"),
    ("puzzle_draft_pipe", 128, "draft steam pipe, horizontal ventilation tube, brass piping"),
    ("puzzle_draft_prism", 128, "draft light prism, crystal redirecting beam, angular glass"),
    ("puzzle_draft_vent", 128, "draft air vent, louvered opening, airflow control, metal grate"),
    ("puzzle_escapement_clock", 128, "escapement clock mechanism, tick-tock gear, timekeeping device"),
    ("puzzle_escapement_switch", 128, "escapement trigger switch, timing mechanism latch, precision switch"),
    ("puzzle_escapement_wheel", 128, "escapement gear wheel, toothed timing wheel, clockwork component"),
    ("puzzle_flyweight", 128, "flyweight governor, spinning mass on arm, speed regulator"),
    ("puzzle_flywheel_wheel", 128, "massive flywheel gear, momentum wheel, heavy iron cog"),
    ("puzzle_governor_gears", 128, "governor gear cluster, control mechanism gears, precision transmission"),
    ("puzzle_governor_lever", 128, "governor control lever, speed adjustment arm, iron lever"),
    ("puzzle_oiler_nozzle", 128, "oiler grease nozzle, lubrication point, metal spout dripping oil"),
    ("puzzle_oiler_reservoir", 128, "oiler oil reservoir, metal tank, dark liquid visible, maintenance"),
    ("puzzle_quench_tank", 128, "quench cooling tank, water basin, steam rising, heat treatment"),
    ("puzzle_quench_valve", 128, "quench water valve, flow control handle, pipe fitting"),
    ("puzzle_spark_furnace", 128, "spark furnace, small boiler, firebox, glowing coals, ignition"),
    ("puzzle_spark_igniter", 128, "spark igniter mechanism, flint striker, ignition device, flame starter"),
    ("puzzle_temper_anvil", 128, "temper anvil, blacksmith anvil, heat treatment surface, dark iron"),
    ("puzzle_temper_bucket", 128, "temper quench bucket, metal pail, cooling water, steam"),
    ("puzzle_temper_forge", 128, "temper forge, heat treatment furnace, glowing interior, firebrick"),
    ("puzzle_temper_lens", 128, "temper focusing lens, heat treatment glass, thermal lens, glowing"),
    ("puzzle_weights", 128, "counterweight iron weights, heavy blocks, calibration masses, dark metal"),
    # --- Traps + token + light (128x128 except light_emitter 64) ---
    ("trap_compression", 128, "compression trap, ceiling gear mechanism, descending hazard, crushing gears"),
    ("trap_grasping_cog", 128, "grasping cog trap, sweeping gear tooth, rotating blade hazard"),
    ("trap_recalibration", 128, "recalibration trap, spinning floor mechanism, centrifugal hazard"),
    ("trap_warning_sermon", 128, "warning sermon trap, inscribed plaque, runic warning, inscribed stone"),
    ("token_gear_devil", 64, "gear devil token, small collectible coin, embossed gear symbol, brass token"),
    ("light_emitter", 64, "light emitter crystal, small glowing prism, beam source, golden crystal"),
]

def generate(name, size, prompt, seed=100):
    out = OUTPUT_DIR / f"{name}.png"
    if out.exists():
        print(f"[SKIP] {name}.png")
        return True
    base = BASE_64 if size == 64 else BASE_128
    try:
        resp = requests.post(
            f"{BASE_URL}/generate-image-pixflux",
            headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
            json={"description": f"{base}, {prompt}", "image_size": {"width": size, "height": size}, "no_background": True, "seed": seed},
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
    print(f"Generating {len(PUZZLES)} puzzle sprites...")
    ok = 0
    for i, (name, size, desc) in enumerate(PUZZLES, 1):
        print(f"[{i}/{len(PUZZLES)}] ", end="", flush=True)
        if generate(name, size, desc, seed=100 + i):
            ok += 1
        time.sleep(1.5)
    print(f"\nDONE: {ok}/{len(PUZZLES)}")

if __name__ == "__main__":
    main()
