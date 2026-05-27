#!/usr/bin/env python3
"""
Floor 1 Art Pass — Sprite Generation
Generates all art assets needed for Floor 1 to match Floor 3 visual quality
Uses proven prompt hacks from Floor 3 sweep
Output: temp_regeneration/floor1/
"""

import requests
import base64
import time
from pathlib import Path

API_KEY = "7121a3bf-3da7-44e9-a18e-39582de2362f"
BASE_URL = "https://api.pixellab.ai/v1"
OUTPUT_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/temp_regeneration/floor1")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Proven base prompts by category
PLATFORM_BASE = (
    "pixel art sprite, large flat platform viewed from 60 degrees above, "
    "tilted toward camera showing top surface and thick front edge, "
    "parallel projection, no vanishing points, transparent background, centered, "
    "dark industrial steampunk style, muted metallic colors"
)

OBJECT_BASE = (
    "pixel art sprite, object sitting on factory floor, viewed from 60 degrees above, "
    "showing top and front surfaces, parallel projection, no vanishing points, "
    "transparent background, centered, dark industrial steampunk style, muted metallic colors"
)

CHARACTER_BASE = (
    "pixel art sprite, character standing on factory floor, "
    "bird's eye view, top of head dominates, tiny feet, "
    "viewed from above at 60 degrees, "
    "showing top of head and shoulders, body angled toward camera, "
    "parallel projection, no vanishing points, "
    "transparent background, centered, dark industrial steampunk style, muted metallic colors"
)

BACKGROUND_BASE = (
    "pixel art background, dark industrial steampunk, "
    "viewed from above, looking down onto mechanical environment, "
    "parallel projection, muted metallic colors, grimy industrial"
)

# ===== FLOOR TEXTURES (5 rooms) =====
FLOORS = [
    ("floor1_central", 512, PLATFORM_BASE,
     "central hub floor, ornate metallic platform, portal nexus, circular pattern, "
     "brass inlay, six faction banner positions, sacred geometry etched into steel, "
     "threshold room, meeting ground, neutral ground"),
    
    ("floor1_north_door", 512, PLATFORM_BASE,
     "iron guardian floor, dark steel plate, fortress threshold, heavy door platform, "
     "guardian-themed, iron gray with rust streaks, ominous, the door room"),
    
    ("floor1_east_warren", 512, PLATFORM_BASE,
     "construct warren floor, cluttered workshop, debris and scrap metal, "
     "greenish copper patina, goblin graffiti etched into metal, "
     "messy, chaotic, tinker's floor"),
    
    ("floor1_south_shrine", 512, PLATFORM_BASE,
     "divine shrine floor, golden brass platform, sacred offering space, "
     "holy geometry, warm gold and white tones, serene, temple floor, "
     "offering niche, water droplet motif"),
    
    ("floor1_west_gauntlet", 512, PLATFORM_BASE,
     "combat arena floor, scarred metal, battle-tested steel, "
     "weapon marks, dark red rust, brutal, fighting pit floor, "
     "rubble, broken tiles, arena scars"),
]

# ===== THE DOOR =====
DOOR = [
    ("the_door", 256, OBJECT_BASE,
     "massive iron door with carved face, ancient guardian portal, "
     "heavy riveted iron plates, a face carved into the metal, "
     "door knocker ring, imposing, vertical rectangular shape, "
     "dark iron, rust streaks, ominous portal"),
]

# ===== NPCs =====
NPCS = [
    ("npc_transit_construct", 128, CHARACTER_BASE,
     "clockwork construct NPC, brass automaton, mechanical humanoid, "
     "gear-driven joints, glowing eye slits, helpful guide, "
     "standing upright, brass and copper, friendly posture"),
    
    ("shop_kiosk", 128, OBJECT_BASE,
     "vendor kiosk, small shop booth, card trading station, "
     "wooden counter with brass fittings, item display, "
     "merchant stall, compact, upright structure"),
]

# ===== PORTALS =====
PORTALS = [
    ("portal_main", 128, OBJECT_BASE,
     "main portal gateway, hexagonal energy gate, blue-white energy, "
     "boss portal, larger and more ornate, swirling vortex, "
     "central hub gateway, primary portal, dominant"),
    
    ("portal_north", 64, OBJECT_BASE,
     "side portal, red energy, directional gate, "
     "smaller than main portal, compass portal, north indicator"),
    
    ("portal_east", 64, OBJECT_BASE,
     "side portal, green energy, directional gate, "
     "smaller than main portal, compass portal, east indicator"),
    
    ("portal_south", 64, OBJECT_BASE,
     "side portal, blue energy, directional gate, "
     "smaller than main portal, compass portal, south indicator"),
    
    ("portal_west", 64, OBJECT_BASE,
     "side portal, orange energy, directional gate, "
     "smaller than main portal, compass portal, west indicator"),
]

# ===== FACTION BANNERS =====
BANNERS = [
    ("banner_goblin", 64, OBJECT_BASE,
     "faction banner, green goblin flag, tribal symbol, "
     "vertical hanging banner, green fabric, goblin emblem"),
    
    ("banner_construct", 64, OBJECT_BASE,
     "faction banner, gray construct flag, gear symbol, "
     "vertical hanging banner, steel gray fabric, gear emblem"),
    
    ("banner_demon", 64, OBJECT_BASE,
     "faction banner, red demon flag, flame symbol, "
     "vertical hanging banner, crimson fabric, flame emblem"),
    
    ("banner_elemental", 64, OBJECT_BASE,
     "faction banner, cyan elemental flag, crystal symbol, "
     "vertical hanging banner, light blue fabric, crystal emblem"),
    
    ("banner_undead", 64, OBJECT_BASE,
     "faction banner, purple undead flag, bone symbol, "
     "vertical hanging banner, dark purple fabric, bone emblem"),
    
    ("banner_aberration", 64, OBJECT_BASE,
     "faction banner, pink aberration flag, eye symbol, "
     "vertical hanging banner, magenta fabric, eye emblem"),
]

# ===== BACKGROUND =====
BACKGROUNDS = [
    ("floor1_background", 512, BACKGROUND_BASE,
     "1920x1080 background, the threshold of a clocktower, entry chamber, "
     "portal room interior, dark mechanical environment, "
     "portal energy glows, distant machinery, "
     "the beginning of the descent, first floor atmosphere"),
]

ALL_SPRITES = FLOORS + DOOR + NPCS + PORTALS + BANNERS + BACKGROUNDS

def generate(name, size, base_prompt, description, seed=600):
    out = OUTPUT_DIR / f"{name}.png"
    if out.exists():
        print(f"[SKIP] {name}.png")
        return True
    try:
        resp = requests.post(
            f"{BASE_URL}/generate-image-pixflux",
            headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
            json={
                "description": f"{base_prompt}, {description}",
                "image_size": {"width": size, "height": size},
                "no_background": True,
                "seed": seed,
            },
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
    print(f"Generating {len(ALL_SPRITES)} Floor 1 art assets...")
    ok = 0
    for i, (name, size, base, desc) in enumerate(ALL_SPRITES, 1):
        print(f"[{i}/{len(ALL_SPRITES)}] ", end="", flush=True)
        if generate(name, size, base, desc, seed=600 + i):
            ok += 1
        time.sleep(1.5)
    print(f"\nDONE: {ok}/{len(ALL_SPRITES)}")

if __name__ == "__main__":
    main()
