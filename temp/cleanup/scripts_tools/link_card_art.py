#!/usr/bin/env python3
"""
Card Art Linker - Updated to handle naming mismatches between art and .tres files
"""

import os
import re
from pathlib import Path

FACTION_MAP = {
    "Aberration": ("Aberration", "res://assets/sprites/cards/aberration_frame.png"),
    "Construct": ("Construct", "res://assets/sprites/cards/construct_frame.png"),
    "Demon": ("Demon", "res://assets/sprites/cards/demon_frame.png"),
    "Dragon": ("Dragon", "res://assets/sprites/cards/dragon_frame.png"),
    "Elemental": ("Elemental", "res://assets/sprites/cards/elemental_frame.png"),
    "Goblin": ("Goblin", "res://assets/sprites/cards/goblin_frame.png"),
    "Undead": ("Undead", "res://assets/sprites/cards/undead_frame.png"),
    "Universal": ("Universal", "res://assets/sprites/cards/untyped_frame.png"),
}

def normalize_name(name):
    """Normalize for comparison"""
    return name.lower().replace(" ", "_").replace("-", "_").strip()

def extract_card_name_from_tres(tres_path):
    """Read the card_name from a .tres file"""
    content = tres_path.read_text()
    match = re.search(r'card_name\s*=\s*"([^"]+)"', content)
    if match:
        return match.group(1)
    return None

def update_tres_file(tres_path, art_path, frame_path):
    """Add or update sprite_texture_path in .tres file"""
    content = tres_path.read_text()
    
    # Remove existing sprite_texture_path and frame_texture_path lines if they exist
    lines = content.split("\n")
    new_lines = []
    for line in lines:
        if "sprite_texture_path" in line and "@export" in line:
            continue
        if "frame_texture_path" in line and "@export" in line:
            continue
        new_lines.append(line)
    
    # Find the right place to insert (after other @export vars)
    insert_idx = len(new_lines)
    for i, line in enumerate(new_lines):
        if line.startswith("@export var") and "sprite_texture_path" not in line and "frame_texture_path" not in line:
            insert_idx = i + 1
    
    # Insert the new export lines
    new_lines.insert(insert_idx, f'@export var sprite_texture_path: String = "{art_path}"')
    new_lines.insert(insert_idx + 1, f'@export var frame_texture_path: String = "{frame_path}"')
    
    tres_path.write_text("\n".join(new_lines))
    return True

def main():
    base_path = Path("/root/.openclaw/workspace/acanous_floor3_demo")
    cards_path = base_path / "assets" / "sprites" / "cards"
    
    total_linked = 0
    total_missing = 0
    
    print("=== Card Art Linker (Updated) ===\n")
    
    for faction, (folder_name, frame_path) in FACTION_MAP.items():
        folder = cards_path / folder_name
        if not folder.exists():
            print(f"⚠️  {faction}: Folder not found")
            continue
        
        # Load all .tres files for this faction
        tres_folder = base_path / "finished_cards" / faction
        if not tres_folder.exists():
            print(f"⚠️  {faction}: No .tres folder found")
            continue
        
        # Build a map of normalized card names to tres files
        tres_map = {}
        for tres_file in tres_folder.glob("*.tres"):
            card_name = extract_card_name_from_tres(tres_file)
            if card_name:
                normalized = normalize_name(card_name)
                tres_map[normalized] = tres_file
                # Also add the filename stem as a key
                stem_normalized = normalize_name(tres_file.stem.replace(f"{faction}_", ""))
                tres_map[stem_normalized] = tres_file
        
        linked = 0
        missing = []
        
        # Get all PNG files
        png_files = sorted([f for f in folder.glob("*.png") if not f.name.endswith(".import")])
        
        for png_file in png_files:
            # Get card name from PNG filename (e.g., "01_aberrant_form.png" -> "aberrant_form")
            card_name = png_file.stem
            clean_name = re.sub(r'^\d+_', '', card_name)  # Remove leading number
            normalized = normalize_name(clean_name)
            
            art_path = f"res://assets/sprites/cards/{folder_name}/{png_file.name}"
            
            # Try to find matching .tres file
            tres_file = None
            
            # Try exact match first
            if normalized in tres_map:
                tres_file = tres_map[normalized]
            else:
                # Try partial matches
                for key, path in tres_map.items():
                    if normalized in key or key in normalized:
                        tres_file = path
                        break
            
            if tres_file:
                if update_tres_file(tres_file, art_path, frame_path):
                    linked += 1
            else:
                missing.append(clean_name)
        
        print(f"✅ {faction}: {linked}/{len(png_files)} cards linked")
        if missing:
            print(f"   Missing {len(missing)}: {', '.join(missing[:3])}{'...' if len(missing) > 3 else ''}")
            total_missing += len(missing)
        
        total_linked += linked
    
    print(f"\n=== Complete ===")
    print(f"Total linked: {total_linked}")
    print(f"Total missing: {total_missing}")
    
    return total_missing == 0

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
