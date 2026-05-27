#!/usr/bin/env python3
"""Clean up broken wall sprites and duplicate ext_resources from Floor 2 room scenes."""

import re
from pathlib import Path

ROOMS = [
    "Floor2_Entry",
    "Floor2_Upper", 
    "Floor2_Middle",
    "Floor2_Lower",
    "Floor2_Secret",
    "Floor2_SporeHeart",
]

SCENES_DIR = Path("/root/.openclaw/workspace/acanous_floor3_demo/scenes/rooms")

for room in ROOMS:
    filepath = SCENES_DIR / f"{room}.tscn"
    if not filepath.exists():
        continue
    
    content = filepath.read_text()
    original_len = len(content)
    
    # Remove all WallSprite nodes
    content = re.sub(r'\n\[node name="WallSprite_\d+".*?\n(?:.*?\n)*?\n', '\n', content)
    
    # Remove all duplicate/broken wall ext_resources
    content = re.sub(r'\[ext_resource type="Texture2D" path="res://assets/sprites/floor2/walls/.*?\n', '', content)
    
    # Fix load_steps count (remove approximate, Godot will recalculate)
    # Actually Godot recalculates this on import, so we can leave it or fix roughly
    # Count remaining ext_resources
    ext_count = content.count('[ext_resource')
    content = re.sub(r'load_steps=\d+', f'load_steps={ext_count + 1}', content)
    
    filepath.write_text(content)
    print(f"  Cleaned {room}: removed {original_len - len(content)} chars")

print("Done")
