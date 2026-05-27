#!/usr/bin/env python3
"""
PixelLab Batch Sprite Generator — Floor 3: The Gearworks
Uses PixelLab API v2 (create-image-pixflux) to generate missing sprites.

Usage:
    export PIXELLAB_API_KEY="7121a3bf-3da7-44e9-a18e-39582de2362f"
    python3 pixellab_batch_generator.py

Output: acanous_floor3_demo/assets/sprites/puzzles/
"""

import os
import sys
import json
import time
import base64
import requests
from pathlib import Path
from dataclasses import dataclass
from typing import Optional

# --- Config ---
API_KEY = os.environ.get("PIXELLAB_API_KEY", "7121a3bf-3da7-44e9-a18e-39582de2362f")
API_URL = "https://api.pixellab.ai/v2/create-image-pixflux"
OUTPUT_DIR = Path("acanous_floor3_demo/assets/sprites/puzzles")
REQUEST_DELAY = 3  # Seconds between API calls
MAX_RETRIES = 3

# Ensure output dir exists
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# --- Sprite Definitions ---

@dataclass
class SpriteDef:
    filename: str
    width: int
    height: int
    prompt: str
    view: str = "high top-down"
    detail: str = "highly detailed"
    outline: str = "single color outline"
    shading: str = "medium shading"

# Batch 1: Kami Sprites (64×64)
KAMI_SPRITES = [
    SpriteDef("kami_water.png", 64, 64,
        "Pixel art sprite, 64x64, transparent background. A small water spirit deity, ethereal translucent blue body, cooling coil motifs wrapping around limbs, dripping water droplets from fingertips, sad hunched posture. Dark blue-grey palette with cyan glow accents. Single character, centered, top-down view. Steampunk industrial spirit."),
    
    SpriteDef("kami_heat.png", 64, 64,
        "Pixel art sprite, 64x64, transparent background. A small fire spirit deity, wreathed in orange and red flame, furnace-door chest, aggressive stance with arms raised. Dark red-brown palette with bright orange glow accents. Single character, centered, top-down view. Steampunk industrial spirit."),
    
    SpriteDef("kami_maintenance.png", 64, 64,
        "Pixel art sprite, 64x64, transparent background. A small grease spirit deity, oily brown-green body, tool belt with wrenches, calm mechanical pose holding a spanner. Dark olive palette with brass accents. Single character, centered, top-down view. Steampunk industrial spirit."),
    
    SpriteDef("kami_regulation.png", 64, 64,
        "Pixel art sprite, 64x64, transparent background. A small gauge spirit deity, grey body with dial-face for a head, needle hands pointing precisely, balanced stance. Dark steel palette with green indicator glow. Single character, centered, top-down view. Steampunk industrial spirit."),
    
    SpriteDef("kami_steam.png", 64, 64,
        "Pixel art sprite, 64x64, transparent background. A small steam spirit deity, pale white-blue body like curling vapor, pressure valve head, pipe-like limbs, hissing posture. Pale grey palette with white steam wisps. Single character, centered, top-down view. Steampunk industrial spirit."),
    
    SpriteDef("kami_heat_treatment.png", 64, 64,
        "Pixel art sprite, 64x64, transparent background. A small forge spirit deity, deep orange body with tempered metal skin texture, anvil-shaped base, hammer arm raised. Dark forge palette with heat-glow orange. Single character, centered, top-down view. Steampunk industrial spirit."),
    
    SpriteDef("kami_light.png", 64, 64,
        "Pixel art sprite, 64x64, transparent background. A small light spirit deity, bright yellow-white body like a prism, radiating beam lines, upward reaching pose. Dark background palette with bright white-yellow glow center. Single character, centered, top-down view. Steampunk industrial spirit."),
    
    SpriteDef("kami_time.png", 64, 64,
        "Pixel art sprite, 64x64, transparent background. A small clock spirit deity, brass body with clock-face chest, pendulum legs, precise geometric form, ticking motion blur on hands. Dark brass palette with gold highlights. Single character, centered, top-down view. Steampunk industrial spirit."),
    
    SpriteDef("kami_friction.png", 64, 64,
        "Pixel art sprite, 64x64, transparent background. A small oil spirit deity, sleek silver body with oil-slick rainbow sheen, smooth flowing hair, lubricated joints, calm confident pose. Dark silver palette with iridescent highlights. Single character, centered, top-down view. Steampunk industrial spirit."),
    
    SpriteDef("kami_momentum.png", 64, 64,
        "Pixel art sprite, 64x64, transparent background. A small wheel spirit deity, circular body like a spinning gear, spoke-like limbs, dynamic spinning pose with motion blur. Dark iron palette with speed lines. Single character, centered, top-down view. Steampunk industrial spirit."),
    
    SpriteDef("kami_balance.png", 64, 64,
        "Pixel art sprite, 64x64, transparent background. A small scale spirit deity, perfectly symmetrical body, balance beam arms with equal weights hanging, centered meditative stance. Dark bronze palette with balanced gold accents. Single character, centered, top-down view. Steampunk industrial spirit."),
]

# Batch 2: Puzzle Object Sprites (128×128)
PUZZLE_SPRITES = [
    SpriteDef("puzzle_draft_prism.png", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Industrial crystal prism, hexagonal shape, pale blue glow emanating from core, steam wisps curling around base, brass mounting clamp. Dark metal with cyan glow accents. Isometric view, centered, clear readable silhouette. Steampunk factory machinery."),
    
    SpriteDef("puzzle_temper_bucket.png", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Industrial quench bucket, dark riveted metal, water inside with surface reflection, steam rising from top, riveted seams, handle on side. Dark metal with blue water and white steam. Isometric view, centered, clear readable silhouette. Steampunk forge equipment."),
    
    SpriteDef("puzzle_temper_lens.png", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Thermal lens, glass disc with heat distortion shimmer effect, brass mounting ring with screws, slightly convex surface. Dark metal with warm orange heat glow. Isometric view, centered, clear readable silhouette. Steampunk optical equipment."),
    
    SpriteDef("puzzle_beacon_platform.png", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Elevator platform, grated metal floor with gaps showing gears below, gear-tooth edges, low safety rail on sides, hydraulic piston center. Dark steel with yellow warning stripes. Isometric view, centered, clear readable silhouette. Steampunk industrial lift."),
    
    SpriteDef("puzzle_beacon_crystal.png", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Light crystal, tall hexagonal prism, bright white glow emanating from core, metallic base mount with clamps, light beams radiating upward. Dark metal with intense white-yellow glow center. Isometric view, centered, clear readable silhouette. Steampunk power crystal."),
    
    SpriteDef("puzzle_escapement_wheel.png", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Brass escapement wheel, 6 visible teeth, central axle hole, gear spokes radiating inward, precision clockwork mechanism. Dark brass with gold highlights. Isometric view, centered, clear readable silhouette. Steampunk clockwork gear."),
    
    SpriteDef("puzzle_bearing_ball.png", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Single steel ball bearing, perfect sphere, slight reflection highlight on top-left, metallic grey with polished shine, 16px usable center. Dark steel with silver highlight. Isometric view, centered, clear readable silhouette. Steampunk mechanical component."),
    
    SpriteDef("puzzle_flyweight.png", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Iron counterweight mass, rectangular iron block with bolt holes, heavy hanging mount point at top, rough cast metal texture. Dark iron with rust accents. Isometric view, centered, clear readable silhouette. Steampunk heavy machinery component."),
    
    SpriteDef("puzzle_counterweight_pan.png", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Brass balance pan, shallow bowl shape, chain attachment points on rim, ornate decorative rim pattern, slightly worn patina. Dark bronze with brass highlights. Isometric view, centered, clear readable silhouette. Steampunk weighing scale component."),
]

# Batch 3: Core Game Sprites
CORE_SPRITES = [
    SpriteDef("token_gear_devil.png", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Gear Devil Token, cog-shaped coin with teeth around edge, infernal red glow emanating from stamped seal in center, brass base metal with dark oxidation. Dark brass with intense red center glow. Single object, centered, top-down view. Steampunk infernal currency."),
    
    SpriteDef("light_emitter.png", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Light emitter socket, small crystal housing with dormant dim grey crystal, brass socket mount, when active bright beam shoots upward. Dark metal with dim grey crystal center. Single object, centered, top-down view. Steampunk power socket."),
    
    SpriteDef("trap_grasping_cog.png", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Giant grasping cog trap, massive gear with sharp teeth as claws, spring-loaded mechanism visible, rusted metal with red warning paint. Dark rusted metal with red danger accents. Isometric view, centered, clear readable silhouette. Steampunk industrial trap."),
    
    SpriteDef("trap_compression.png", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Compression trap, heavy piston plate descending from top, hydraulic lines and pressure cylinders, pressure gauge showing red zone, industrial ceiling mount. Dark steel with hydraulic fluid lines. Isometric view, centered, clear readable silhouette. Steampunk crushing trap."),
    
    SpriteDef("trap_recalibration.png", 128, 128,
        "Pixel art sprite, 128x128, transparent background. Recalibration trap, rotating lever arms with calibration dials, sparks flying from contacts, gyroscopic rings spinning, warning lights flashing. Dark metal with orange sparks and red warning lights. Isometric view, centered, clear readable silhouette. Steampunk spinning trap."),
    
    SpriteDef("trap_warning_sermon.png", 64, 64,
        "Pixel art sprite, 64x64, transparent background. Warning Sermon trap, Gear Devil face hologram projection, red glowing eyes, small broadcast antenna emitting signal rings, dark metallic base. Dark metal with red hologram glow. Single object, centered, top-down view. Steampunk holographic projector."),
]

ALL_SPRITES = KAMI_SPRITES + PUZZLE_SPRITES + CORE_SPRITES

# --- API ---

def generate_sprite(sprite: SpriteDef, api_key: str) -> bool:
    """Generate a single sprite via PixelLab API. Returns True on success."""
    output_path = OUTPUT_DIR / sprite.filename
    
    # Skip if already exists
    if output_path.exists():
        print(f"  [SKIP] {sprite.filename} already exists")
        return True
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    payload = {
        "description": sprite.prompt,
        "image_size": {"width": sprite.width, "height": sprite.height},
        "no_background": True,
        "text_guidance_scale": 8.0,
        "view": sprite.view,
        "detail": sprite.detail,
        "outline": sprite.outline,
        "shading": sprite.shading,
    }
    
    for attempt in range(MAX_RETRIES):
        try:
            print(f"  [GEN] {sprite.filename} ({sprite.width}x{sprite.height}) — attempt {attempt + 1}/{MAX_RETRIES}")
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
                    usage = data.get("usage", {})
                    print(f"  [OK]  {sprite.filename} saved ({len(img_data)} bytes) — {usage}")
                    return True
                else:
                    print(f"  [ERR] No image in response: {list(data.keys())}")
                    
            elif resp.status_code == 429:
                print(f"  [RATE] Rate limited, waiting 30s...")
                time.sleep(30)
                continue
                
            elif resp.status_code == 401:
                print(f"  [ERR] API key invalid or expired")
                return False
                
            else:
                print(f"  [ERR] HTTP {resp.status_code}: {resp.text[:200]}")
                
        except requests.exceptions.Timeout:
            print(f"  [ERR] Timeout on attempt {attempt + 1}")
        except Exception as e:
            print(f"  [ERR] {type(e).__name__}: {e}")
        
        if attempt < MAX_RETRIES - 1:
            time.sleep(5 * (attempt + 1))
    
    print(f"  [FAIL] {sprite.filename} — all retries exhausted")
    return False


def main():
    print("=" * 60)
    print("PixelLab Batch Sprite Generator — Floor 3: The Gearworks")
    print("=" * 60)
    print(f"API Key: {API_KEY[:8]}...{API_KEY[-4:]}")
    print(f"Output:  {OUTPUT_DIR}")
    print(f"Sprites: {len(ALL_SPRITES)} total")
    print(f"  - Kami:         {len(KAMI_SPRITES)}")
    print(f"  - Puzzle:       {len(PUZZLE_SPRITES)}")
    print(f"  - Core Game:    {len(CORE_SPRITES)}")
    print("=" * 60)
    
    if not API_KEY or API_KEY == "your-api-key-here":
        print("\n[ERROR] No API key found!")
        sys.exit(1)
    
    # Generate all sprites
    success_count = 0
    fail_count = 0
    skip_count = 0
    
    print("\n--- Batch 1: Kami Sprites ---")
    for sprite in KAMI_SPRITES:
        output_path = OUTPUT_DIR / sprite.filename
        if output_path.exists():
            skip_count += 1
            print(f"  [SKIP] {sprite.filename}")
            continue
        if generate_sprite(sprite, API_KEY):
            success_count += 1
        else:
            fail_count += 1
        time.sleep(REQUEST_DELAY)
    
    print("\n--- Batch 2: Puzzle Object Sprites ---")
    for sprite in PUZZLE_SPRITES:
        output_path = OUTPUT_DIR / sprite.filename
        if output_path.exists():
            skip_count += 1
            print(f"  [SKIP] {sprite.filename}")
            continue
        if generate_sprite(sprite, API_KEY):
            success_count += 1
        else:
            fail_count += 1
        time.sleep(REQUEST_DELAY)
    
    print("\n--- Batch 3: Core Game Sprites ---")
    for sprite in CORE_SPRITES:
        output_path = OUTPUT_DIR / sprite.filename
        if output_path.exists():
            skip_count += 1
            print(f"  [SKIP] {sprite.filename}")
            continue
        if generate_sprite(sprite, API_KEY):
            success_count += 1
        else:
            fail_count += 1
        time.sleep(REQUEST_DELAY)
    
    # Summary
    print("\n" + "=" * 60)
    print("GENERATION COMPLETE")
    print("=" * 60)
    print(f"Success:  {success_count}")
    print(f"Failed:   {fail_count}")
    print(f"Skipped:  {skip_count} (already exist)")
    print(f"Total:    {success_count + fail_count + skip_count}/{len(ALL_SPRITES)}")
    
    if fail_count > 0:
        print(f"\n[NOTE] {fail_count} sprites failed. Re-run to retry.")
    
    print(f"\nOutput directory: {OUTPUT_DIR.absolute()}")
    print("=" * 60)


if __name__ == "__main__":
    main()
