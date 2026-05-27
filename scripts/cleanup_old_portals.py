#!/usr/bin/env python3
"""Remove old side-scroller portal sprites from Floor2 room scenes."""
from pathlib import Path
import re

scenes_dir = Path('/root/.openclaw/workspace/acanous_floor3_demo/scenes/rooms')
rooms = ['Floor2_Entry', 'Floor2_Upper', 'Floor2_Middle', 'Floor2_Lower', 'Floor2_Secret', 'Floor2_SporeHeart']

for room in rooms:
    filepath = scenes_dir / f'{room}.tscn'
    if not filepath.exists():
        continue
    content = filepath.read_text()
    
    lines = content.split('\n')
    new_lines = []
    skip_until_blank = False
    removed = []
    
    for line in lines:
        if skip_until_blank:
            if line.strip() == '':
                skip_until_blank = False
            continue
        
        # Detect old portal sprite nodes (side-scroller style)
        if re.match(r'\[node name="Portal(Entry|Upper|Middle|Lower|Secret|Boss)" type="Sprite2D"', line):
            skip_until_blank = True
            removed.append(line.strip()[:60])
            continue
        
        new_lines.append(line)
    
    new_content = '\n'.join(new_lines)
    filepath.write_text(new_content)
    print(f'[OK] {room}: removed {len(removed)} old portal sprites')

print('Done')
