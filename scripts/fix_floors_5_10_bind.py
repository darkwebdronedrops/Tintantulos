#!/usr/bin/env python3
"""Bulk fix _on_encounter_started signatures for Floors 5-10."""
import re

for floor_num in range(5, 11):
    filepath = f"/root/.openclaw/workspace/acanous_floor3_demo/scripts/Floor{floor_num}Controller.gd"
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Pattern: func _on_encounter_started(room_id: String, enemy_names: Array):
    # Should be: func _on_encounter_started(enemy_names: Array, room_id: String = ""):
    old_sig = r"func _on_encounter_started\(room_id: String, enemy_names: Array\):"
    new_sig = "func _on_encounter_started(enemy_names: Array, room_id: String = \"\"):"
    content = re.sub(old_sig, new_sig, content)
    
    # Fix super call: super._on_encounter_started(room_id, enemy_names)
    # Should be: super._on_encounter_started(enemy_names, room_id)
    old_call = r"super\._on_encounter_started\(room_id, enemy_names\)"
    new_call = "super._on_encounter_started(enemy_names, room_id)"
    content = re.sub(old_call, new_call, content)
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    print(f"Fixed Floor {floor_num}")

print("All floors 5-10 fixed.")
