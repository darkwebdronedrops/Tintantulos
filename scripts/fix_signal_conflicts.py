#!/usr/bin/env python3
"""Fix all signal/variable name conflicts in RoomBase files."""
import re

fixes = {
    "Floor7RoomBase.gd": {
        "final_pact_shown": "final_pact_was_shown",
    },
    "Floor8RoomBase.gd": {
        "alarm_pulled": "alarm_was_pulled",
        "pipe_destroyed": "pipe_was_destroyed",
        "morale_broken": "morale_was_broken",
        "leader_killed": "leader_was_killed",
    },
    "Floor9RoomBase.gd": {
        "furnace_destroyed": "furnace_was_destroyed",
        "furnace_used": "furnace_was_used",
        "conveyor_ridden": "conveyor_was_ridden",
        "bone_salvaged": "bone_was_salvaged",
        "gear_salvaged": "gear_was_salvaged",
    },
}

for filename, renames in fixes.items():
    filepath = f"/root/.openclaw/workspace/acanous_floor3_demo/scripts/{filename}"
    with open(filepath, 'r') as f:
        content = f.read()
    
    for old_name, new_name in renames.items():
        # Replace var declaration
        content = content.replace(f"var {old_name}:", f"var {new_name}:")
        # Replace all other references (but NOT the signal declaration or emit_signal)
        # We need to be careful not to change "signal old_name" or "emit_signal(\"old_name\")"
        
        # Pattern: word boundary + old_name + word boundary, but not preceded by 'signal ' or '"'
        # This is tricky. Let's do it line by line for safety.
        lines = content.split('\n')
        new_lines = []
        for line in lines:
            stripped = line.strip()
            if stripped.startswith(f"signal {old_name}"):
                new_lines.append(line)
            elif f'emit_signal("{old_name}")' in line:
                new_lines.append(line)
            else:
                new_lines.append(line.replace(old_name, new_name))
        content = '\n'.join(new_lines)
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    print(f"Fixed {filename}")

print("All conflicts resolved.")
