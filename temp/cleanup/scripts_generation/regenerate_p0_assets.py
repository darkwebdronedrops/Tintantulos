#!/usr/bin/env python3
"""
P0 Asset Regeneration Script — Floor 3: The Gearworks
Generates replacement assets following the Camera Lock Protocol (60° oblique).
Outputs to temp_regeneration/ for side-by-side comparison with existing assets.
"""

import requests
import base64
import os
import time
from pathlib import Path

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"

# Output directory — temp only, never overwrites existing assets
OUTPUT_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/temp_regeneration")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# ============================================================================
# CAMERA LOCK PROMPT PREFIX — prepended to every generation request
# ============================================================================
CAMERA_LOCK = (
    "Pixel art sprite, 60-degree oblique top-down view, camera looking down "
    "from 60 degrees above horizontal, north is top of image, object standing "
    "upright on flat ground, parallel projection, no perspective distortion, "
    "no vanishing points, consistent 3/4 view from above showing top and front "
    "surfaces, centered, dark industrial steampunk style, muted metallic colors, "
    "transparent background"
)

FLOOR_LOCK = (
    "Pixel art floor tile, 60-degree oblique top-down view, camera looking down "
    "from 60 degrees above horizontal, north is top of image, walkable ground "
    "surface visible, parallel projection, no perspective distortion, no vanishing "
    "points, showing top surface with visible front edge band, dark industrial "
    "steampunk style, muted metallic colors, seamless tile texture"
)

# ============================================================================
# P0 ASSET DEFINITIONS
# ============================================================================

ASSETS = []

# --- P0.1: BASE FLOORS (2 assets) ---
ASSETS.extend([
    {
        "name": "floor_gear_tile",
        "category": "floors",
        "size": 256,
        "prompt": (
            FLOOR_LOCK + ", metal floor plate with subtle embedded gear pattern "
            "etched into surface, industrial tread plate texture, rivets along edges, "
            "dark iron and brass tones, visible front edge thickness, walkable "
            "walkable dungeon floor"
        ),
        "replaces": "assets/sprites/room_objects/floor_gear_tile.png",
    },
    {
        "name": "env_floor_hex",
        "category": "floors",
        "size": 256,
        "prompt": (
            FLOOR_LOCK + ", hexagonal stone floor tile, geometric hex pattern, "
            "dark granite with brass inlay lines, visible front edge bevel, "
            "walkable steampunk dungeon floor, gear motifs at hex vertices"
        ),
        "replaces": "assets/sprites/ui_env/env_floor_hex.png",
    },
])

# --- P0.2: GEAR MOTHER BOSS (5 animation frames) ---
GEAR_MOTHER_FRAMES = [
    ("idle", "standing still, massive gear-construct matriarch, bronze and copper mechanical body, multiple gear segments forming torso, calm but imposing, mother of all gears"),
    ("attack", "lunging forward, gear teeth extending as blades, mechanical limbs thrusting, aggressive motion blur on gear arms, industrial assault"),
    ("damage", "recoiling from hit, gear segments sparking, bronze plating dented, oil leaking from cracks, wounded mechanical matriarch"),
    ("death", "collapsing, gears grinding to halt, body breaking apart into scattered cogs and springs, final spark of consciousness fading"),
    ("special", "summoning smaller gear-constructs from her torso, mechanical birth animation, gears spinning rapidly, constructs emerging from central cavity"),
]

for frame_type, desc in GEAR_MOTHER_FRAMES:
    ASSETS.append({
        "name": f"boss_gear_mother_{frame_type}",
        "category": "bosses",
        "size": 200,
        "prompt": f"{CAMERA_LOCK}, {desc}, 200x200 game boss sprite, construct faction, mechanical horror",
        "replaces": f"assets/sprites/enemies/boss_gear_mother_{frame_type}.png",
    })

# --- P0.3: ROOM OBJECTS — worst offenders (8 assets) ---
# Selected for visual importance and confirmed/predicted severe mismatch
ROOM_OBJECTS = [
    ("flywheel_massive_gear", 128, "massive industrial flywheel gear lying on factory floor, huge cog wheel with momentum, cast iron with momentum scars, gear teeth visible from above and front, heavy machinery object"),
    ("oiler_barrel", 128, "industrial oil barrel, metal drum with grease stains, oil spigot on side, maintenance equipment, dark iron with oil residue"),
    ("tool_rack", 128, "wall-mounted tool rack with wrenches and oil cans, maintenance tools hanging, steampunk workshop equipment, brass and iron"),
    ("warning_sign", 64, "industrial warning sign on metal stand, 'INEFFICIENT' or caution symbol, brass plaque with engraved letters, factory safety signage"),
    ("bearing_housing", 128, "bearing housing mechanism, cylindrical metal bearing casing with grease fitting, lubrication point visible, precision machine part"),
    ("spark_furnace", 128, "small industrial furnace, brick-lined firebox with glowing coals visible, chimney pipe extending upward, forge heat source, dark iron and firebrick"),
    ("temper_forge", 128, "heat treatment forge, anvil and quench tank together, blacksmith equipment, glowing metal being tempered, industrial forge setup"),
    ("quench_cooling_tank", 128, "cooling tank basin filled with water, steam rising from surface, quench tank for heat treatment, metal rim with condensation"),
    ("governor_control_panel", 128, "control panel with levers and gauges, speed regulation mechanism, brass dials and iron levers, industrial control station"),
    ("counterweight_scale", 128, "balance scale with iron counterweights, precision weighing mechanism, brass beam scale with hanging pans, industrial measurement device"),
]

for name, size, desc in ROOM_OBJECTS:
    ASSETS.append({
        "name": name,
        "category": "room_objects",
        "size": size,
        "prompt": f"{CAMERA_LOCK}, {desc}, game environment object sprite",
        "replaces": f"assets/sprites/room_objects/{name}.png",
    })

# --- P0.4: ABERRATION ENEMIES — too overhead (12 idle frames) ---
# All aberration enemies in root enemies/ folder need audit. Generating all 16.
ABERRATION_ENEMIES = [
    ("enemy_the_bug", "glitch insectoid creature, corrupted data bug, crawling code fragments, static interference, distorted limbs, corrupted antennae, digital corruption horror"),
    ("enemy_the_lag", "stuttering figure, motion blur trails, frame skip entity, teleporting between positions, temporal lag creature, glitching movement"),
    ("enemy_the_echo", "repeating phantom figure, copy of a person, recursive duplicate, mirror image creature, sound-wave distortion body, resonant horror"),
    ("enemy_the_loop", "circular ouroboros serpent, infinite circle creature, snake eating its tail, endless cycle entity, temporal recursion horror"),
    ("enemy_the_cursor", "arrow-pointer creature, selection tool given form, clicking hand entity, UI element animated, digital interface horror"),
    ("enemy_the_default", "blank humanoid template, factory setting person, unremarkable default form, plain and balanced, the baseline before customization"),
    ("enemy_the_collar", "tightening collar entity, constraint given form, choking ring creature, restriction and bondage, suffocating loop"),
    ("enemy_the_contagion", "amorphous blob of corruption, viral infection form, spreading glitch tendrils, static membrane, infectious horror, organic digital hybrid"),
    ("enemy_the_hollow", "humanoid silhouette filled with void, empty darkness inside form, outline of person with abyss interior, void entity, vacuum horror"),
    ("enemy_the_forgotten", "fading memory creature, translucent figure becoming transparent, disappearing person, neglected and angry, ghost of abandonment"),
    ("enemy_the_whisper", "broadcasting mouth creature, speaking lips without face, sound wave entity, radio static form, communication horror"),
    ("enemy_the_mirror", "reflective glass figure, mirror surface creature, symmetrical enemy, reflective damage entity, crystalline duplicate"),
    ("enemy_the_duplicate", "exact copy creature, clone entity, perfect replica, identity thief form, mimic horror"),
    ("enemy_the_refrain", "repeating pattern creature, musical loop entity, chorus given form, cyclical attack pattern, repetitive motion"),
    ("enemy_the_eidolon", "spectral reflection given teeth, mirror self turned hostile, ghost that looks like you, identity horror boss, phantom doppelganger"),
    ("enemy_the_interview", "abstract aberration boss, question-asking entity, mental probe creature, examination horror, interrogation given form"),
]

for name, desc in ABERRATION_ENEMIES:
    ASSETS.append({
        "name": f"{name}_idle",
        "category": "enemies",
        "size": 64,
        "prompt": f"{CAMERA_LOCK}, {desc}, 64x64 game enemy sprite, aberration faction, horror creature, idle standing pose",
        "replaces": f"assets/sprites/enemies/{name}_idle.png",
    })

# ============================================================================
# GENERATION ENGINE
# ============================================================================

def generate_asset(asset):
    """Generate a single asset via Pixel Lab API."""
    output_path = OUTPUT_DIR / asset["category"] / f"{asset['name']}.png"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    if output_path.exists():
        print(f"[SKIP] {asset['name']}.png already in temp")
        return True, "skipped"
    
    payload = {
        "description": asset["prompt"],
        "image_size": {"width": asset["size"], "height": asset["size"]},
        "no_background": True,
        "seed": 42,
    }
    
    try:
        resp = requests.post(
            f"{BASE_URL}/generate-image-pixflux",
            headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
            json=payload,
            timeout=120,
        )
        
        if resp.status_code == 200:
            data = resp.json()
            # API may return image as base64 string or nested object
            image_data = data.get("image")
            if isinstance(image_data, dict):
                img_b64 = image_data.get("base64")
            elif isinstance(image_data, str):
                img_b64 = image_data
            else:
                img_b64 = None
            if img_b64:
                img_bytes = base64.b64decode(img_b64)
                output_path.write_bytes(img_bytes)
                print(f"[OK] {asset['name']}.png ({len(img_bytes)} bytes, {asset['size']}x{asset['size']})")
                return True, "generated"
            else:
                print(f"[FAIL] {asset['name']}: No image data in response")
                return False, "no_image"
        else:
            print(f"[FAIL] {asset['name']}: HTTP {resp.status_code} — {resp.text[:200]}")
            return False, f"http_{resp.status_code}"
            
    except requests.exceptions.Timeout:
        print(f"[TIMEOUT] {asset['name']}: API timeout")
        return False, "timeout"
    except Exception as e:
        print(f"[ERROR] {asset['name']}: {e}")
        return False, f"exception_{e}"


def main():
    print("=" * 60)
    print("P0 ASSET REGENERATION — Camera Lock Protocol v1.0")
    print(f"Output: {OUTPUT_DIR}")
    print(f"Total assets to generate: {len(ASSETS)}")
    print("=" * 60)
    
    success = 0
    failed = 0
    skipped = 0
    
    for i, asset in enumerate(ASSETS, 1):
        print(f"\n[{i}/{len(ASSETS)}] ", end="", flush=True)
        ok, status = generate_asset(asset)
        if ok:
            if status == "skipped":
                skipped += 1
            else:
                success += 1
        else:
            failed += 1
        time.sleep(1.5)  # Rate limiting courtesy
    
    print("\n" + "=" * 60)
    print(f"DONE: {success} generated, {skipped} skipped, {failed} failed")
    print(f"Output directory: {OUTPUT_DIR}")
    print("=" * 60)
    
    # Write manifest
    manifest_path = OUTPUT_DIR / "REGENERATION_MANIFEST.md"
    with open(manifest_path, "w") as f:
        f.write("# P0 Regeneration Manifest\n\n")
        f.write(f"Generated: {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Camera Lock: 60° oblique, parallel projection\n\n")
        f.write("| # | Name | Category | Size | Replaces | Status |\n")
        f.write("|---|------|----------|------|----------|--------|\n")
        for i, asset in enumerate(ASSETS, 1):
            out_path = OUTPUT_DIR / asset["category"] / f"{asset['name']}.png"
            status = "PRESENT" if out_path.exists() else "MISSING"
            f.write(f"| {i} | {asset['name']} | {asset['category']} | {asset['size']}x{asset['size']} | {asset['replaces']} | {status} |\n")
    
    print(f"Manifest written: {manifest_path}")


if __name__ == "__main__":
    main()
