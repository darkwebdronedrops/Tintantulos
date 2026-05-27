#!/usr/bin/env python3
"""Fix all Floor10 scenes that use full paths instead of ExtResource IDs."""
import re, os

scenes_dir = "/root/.openclaw/workspace/acanous_floor3_demo/scenes/rooms"

for filename in sorted(os.listdir(scenes_dir)):
    if not filename.startswith("Floor10_") or not filename.endswith(".tscn"):
        continue
    
    filepath = os.path.join(scenes_dir, filename)
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Find all ExtResource("res://...") references
    pattern = r'ExtResource\("(res://assets/sprites/floor10/[^"]+)"\)'
    matches = re.findall(pattern, content)
    
    if not matches:
        continue
    
    print(f"Fixing {filename}...")
    
    # Get existing ext_resources
    existing = re.findall(r'\[ext_resource type="Texture2D" path="([^"]+)" id="([^"]+)"\]', content)
    existing_paths = [p for p, _ in existing]
    max_id = 1
    for _, eid in existing:
        num = int(eid.split('_')[0]) if '_' in eid else int(eid)
        max_id = max(max_id, num)
    
    # Add missing ext_resources and build replacement map
    replacements = {}
    for path in set(matches):
        if path in existing_paths:
            # Find existing ID
            for p, eid in existing:
                if p == path:
                    replacements[path] = eid
                    break
        else:
            max_id += 1
            new_id = f"{max_id}_{os.path.basename(path).replace('.png', '')}"
            # Add ext_resource after last ext_resource
            ext_line = f'[ext_resource type="Texture2D" path="{path}" id="{new_id}"]\n'
            # Insert before first [node
            content = content.replace('[node name=', ext_line + '[node name=', 1)
            replacements[path] = new_id
            existing_paths.append(path)
    
    # Replace all full path references with ExtResource IDs
    for path, eid in replacements.items():
        content = content.replace(f'ExtResource("{path}")', f'ExtResource("{eid}")')
    
    # Update load_steps count
    old_steps_match = re.search(r'\[gd_scene load_steps=(\d+)', content)
    if old_steps_match:
        old_steps = int(old_steps_match.group(1))
        new_steps = old_steps + len([p for p in set(matches) if p not in existing_paths])
        content = content.replace(f'[gd_scene load_steps={old_steps}', f'[gd_scene load_steps={new_steps}', 1)
    
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"  Fixed {len(set(matches))} texture references, load_steps now {new_steps}")

print("All Floor10 scenes fixed.")
