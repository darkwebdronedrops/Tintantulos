#!/usr/bin/env python3
"""
PixelLab Batch Sprite Generator for Acanous Card Battler
Uses PixelLab API to generate enemy sprites from JSON definitions

Usage:
    python3 generate_sprites.py --faction Aberration --count 10
    python3 generate_sprites.py --boss-only
    python3 generate_sprites.py --all

Requirements:
    pip install requests
"""

import json
import os
import sys
import argparse
import requests
from pathlib import Path
from typing import List, Dict, Optional

# PixelLab API Configuration
API_BASE = "https://api.pixellab.ai/v1"
API_TOKEN = "7121a3bf-3da7-44e9-a18e-39582de2362f"  # Acanous token

# Sprite configuration
SPRITE_SIZE = {"width": 128, "height": 128}
OUTPUT_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/enemies")
ENEMIES_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/enemies")

HEADERS = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}


def get_balance() -> int:
    """Check remaining PixelLab generations"""
    try:
        response = requests.get(
            f"{API_BASE}/balance",
            headers=HEADERS,
            timeout=30
        )
        response.raise_for_status()
        data = response.json()
        return data.get("balance", 0)
    except Exception as e:
        print(f"Error checking balance: {e}")
        return 0


def generate_sprite(prompt: str, filename: str, size: Dict[str, int] = None) -> bool:
    """Generate a single sprite using PixFlux endpoint"""
    if size is None:
        size = SPRITE_SIZE
    
    payload = {
        "description": prompt,
        "image_size": size,
        "no_background": True
    }
    
    try:
        response = requests.post(
            f"{API_BASE}/generate-image-pixflux",
            headers=HEADERS,
            json=payload,
            timeout=60
        )
        response.raise_for_status()
        data = response.json()
        
        # Save the generated image
        if "image" in data:
            import base64
            img_data = base64.b64decode(data["image"])
            OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
            filepath = OUTPUT_DIR / filename
            with open(filepath, "wb") as f:
                f.write(img_data)
            print(f"✅ Generated: {filename}")
            return True
        else:
            print(f"❌ No image in response for {filename}")
            return False
            
    except Exception as e:
        print(f"❌ Error generating {filename}: {e}")
        return False


def load_enemy_json(faction: str, enemy_name: str) -> Optional[Dict]:
    """Load enemy definition from JSON file"""
    filepath = ENEMIES_DIR / faction / f"{enemy_name}.json"
    if not filepath.exists():
        return None
    
    try:
        with open(filepath, "r") as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading {filepath}: {e}")
        return None


def list_enemies(faction: str) -> List[str]:
    """List all enemy names in a faction"""
    faction_dir = ENEMIES_DIR / faction
    if not faction_dir.exists():
        return []
    
    enemies = []
    for f in faction_dir.glob("*.json"):
        enemies.append(f.stem)
    return sorted(enemies)


def generate_prompt_for_state(enemy_data: Dict, state: str) -> str:
    """Generate PixelLab prompt from enemy definition and animation state"""
    name = enemy_data.get("name", "Unknown")
    faction = enemy_data.get("faction", "Unknown")
    tier = enemy_data.get("tier", "Common")
    
    # Get animation details
    animations = enemy_data.get("animations", {})
    anim_data = animations.get(state, {})
    
    # Base prompt construction
    prompt_parts = [f"pixel art {faction.lower()} enemy"]
    
    # Add enemy name
    prompt_parts.append(f'"{name}"')
    
    # Add state context
    if state == "idle":
        prompt_parts.append("idle pose, standing still")
        if anim_data.get("loop"):
            prompt_parts.append("subtle animation loop")
    elif state == "attack":
        prompt_parts.append("attacking pose, aggressive stance, mid-strike")
    elif state == "damage":
        prompt_parts.append("taking damage, hit reaction, impact pose")
    elif state == "death":
        prompt_parts.append("defeated, death pose, fallen")
    elif state == "defend":
        prompt_parts.append("defensive stance, shielding, guarding")
    elif state == "special":
        special_name = enemy_data.get("mechanic", {}).get("name", "special ability")
        prompt_parts.append(f"using {special_name}, special ability activation")
    else:
        # Custom states
        prompt_parts.append(f"{state} animation")
    
    # Add visual features from animation data
    for key, value in anim_data.items():
        if key in ["sprite", "frames", "fps", "loop", "sound", "flash"]:
            continue
        if isinstance(value, bool) and value:
            prompt_parts.append(key.replace("_", " "))
        elif isinstance(value, str) and not value.startswith("res://"):
            prompt_parts.append(value)
    
    # Add faction-specific styling
    faction_styles = {
        "Aberration": "glitch aesthetic, distorted, unnatural, horror",
        "Construct": "mechanical, gears, metal, industrial",
        "Demon": "demonic, infernal, tempting, corrupting",
        "Elemental": "elemental forces, natural phenomenon, energy",
        "Goblin": "goblin, green skin, mischievous, tribal",
        "Undead": "undead, skeletal, financial horror, creditor"
    }
    if faction in faction_styles:
        prompt_parts.append(faction_styles[faction])
    
    # Style specifications
    prompt_parts.extend([
        "game sprite",
        "transparent background",
        "single character",
        "fantasy game art style"
    ])
    
    return ", ".join(prompt_parts)


def check_existing_sprite(enemy_name: str, state: str) -> bool:
    """Check if sprite already exists"""
    filename = f"enemy_{enemy_name.lower()}_{state}.png"
    return (OUTPUT_DIR / filename).exists()


def generate_enemy_sprites(enemy_name: str, faction: str, skip_existing: bool = True) -> int:
    """Generate all sprites for a single enemy"""
    enemy_data = load_enemy_json(faction, enemy_name)
    if not enemy_data:
        print(f"❌ Could not load {enemy_name}")
        return 0
    
    animations = enemy_data.get("animations", {})
    generated = 0
    
    for state in animations.keys():
        filename = f"enemy_{enemy_name.lower()}_{state}.png"
        
        if skip_existing and check_existing_sprite(enemy_name, state):
            print(f"⏭️  Skipping {filename} (exists)")
            continue
        
        prompt = generate_prompt_for_state(enemy_data, state)
        print(f"\n🎨 {filename}")
        print(f"   Prompt: {prompt[:80]}...")
        
        if generate_sprite(prompt, filename):
            generated += 1
    
    return generated


def generate_boss_specials() -> int:
    """Generate the 6 missing boss special state sprites"""
    bosses = [
        ("The_Caldera", "Construct"),
        ("Gear_Mother", "Construct"), 
        ("Goblin_King_Grimgut", "Goblin"),
        ("The_Interview", "Aberration"),
        ("The_Consumption", "Aberration"),
        ("The_Unsent_Letter", "Aberration")
    ]
    
    total = 0
    for boss_name, faction in bosses:
        print(f"\n{'='*50}")
        print(f"BOSS: {boss_name}")
        print(f"{'='*50}")
        
        enemy_data = load_enemy_json(faction, boss_name)
        if not enemy_data:
            print(f"❌ Could not load {boss_name}")
            continue
        
        # Generate only the 'special' state
        if "special" in enemy_data.get("animations", {}):
            filename = f"boss_{boss_name.lower()}_special.png"
            
            if check_existing_sprite(boss_name, "special"):
                print(f"⏭️  Skipping {filename} (exists)")
                continue
            
            prompt = generate_prompt_for_state(enemy_data, "special")
            # Boost size for bosses
            boss_size = {"width": 200, "height": 200}
            
            print(f"🎨 {filename}")
            print(f"   Prompt: {prompt[:100]}...")
            
            if generate_sprite(prompt, filename, boss_size):
                total += 1
        else:
            print(f"⚠️  {boss_name} has no 'special' animation defined")
    
    return total


def main():
    parser = argparse.ArgumentParser(description="Generate PixelLab sprites for Acanous Card Battler")
    parser.add_argument("--faction", choices=["Aberration", "Construct", "Demon", "Elemental", "Goblin", "Undead"],
                      help="Generate sprites for a specific faction")
    parser.add_argument("--count", type=int, default=5, help="Number of enemies to generate (default: 5)")
    parser.add_argument("--boss-only", action="store_true", help="Generate only boss special states")
    parser.add_argument("--all", action="store_true", help="Generate ALL missing sprites (use with caution)")
    parser.add_argument("--check-balance", action="store_true", help="Check remaining PixelLab generations")
    
    args = parser.parse_args()
    
    # Check balance first
    balance = get_balance()
    print(f"💰 PixelLab Balance: {balance} generations remaining")
    
    if args.check_balance:
        return
    
    if balance < 10:
        print("❌ Insufficient generations remaining. Exiting.")
        return
    
    total_generated = 0
    
    if args.boss_only:
        print("\n🎯 Generating boss special states...")
        total_generated = generate_boss_specials()
    
    elif args.faction:
        print(f"\n🎯 Generating {args.count} enemies from {args.faction}...")
        enemies = list_enemies(args.faction)[:args.count]
        
        for enemy in enemies:
            total_generated += generate_enemy_sprites(enemy, args.faction)
    
    elif args.all:
        print("\n🎯 Generating ALL missing sprites (this may take a while)...")
        for faction in ["Aberration", "Construct", "Demon", "Elemental", "Goblin", "Undead"]:
            print(f"\n{'='*50}")
            print(f"FACTION: {faction}")
            print(f"{'='*50}")
            
            enemies = list_enemies(faction)
            for enemy in enemies:
                total_generated += generate_enemy_sprites(enemy, faction)
    
    else:
        print("\nUsage examples:")
        print("  python3 generate_sprites.py --boss-only")
        print("  python3 generate_sprites.py --faction Construct --count 5")
        print("  python3 generate_sprites.py --faction Aberration --count 10")
        print("  python3 generate_sprites.py --check-balance")
        return
    
    print(f"\n{'='*50}")
    print(f"✅ Total sprites generated: {total_generated}")
    print(f"💰 Remaining balance: ~{balance - total_generated} generations")


if __name__ == "__main__":
    main()
