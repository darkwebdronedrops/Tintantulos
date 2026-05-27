#!/usr/bin/env python3
"""Generate boss special state sprites for Acanous Card Battler"""

import requests
import base64
from pathlib import Path

API_TOKEN = '7121a3bf-3da7-44e9-a18e-39582de2362f'
HEADERS = {
    'Authorization': f'Bearer {API_TOKEN}',
    'Content-Type': 'application/json'
}

OUTPUT_DIR = Path('/root/.openclaw/workspace/acanous_floor3_demo/assets/sprites/enemies')
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

bosses = [
    ('The_Caldera', 'Construct', 'volcanic forge boss, heat surge special attack, magma eruption, intense heat wave, lava explosion'),
    ('Gear_Mother', 'Construct', 'mechanical mother boss, gear spawner special, constructs emerging from gears, industrial summoning'),
    ('Goblin_King_Grimgut', 'Goblin', 'goblin king warlord, war cry special, rallying goblin swarm, tribal leader roaring'),
    ('The_Interview', 'Aberration', 'abstract aberration boss, mental probe special, question beams, psychological examination'),
    ('The_Consumption', 'Aberration', 'ravenous aberration boss, life drain tendrils special, hunger manifestation, devouring void'),
    ('The_Unsent_Letter', 'Aberration', 'ghostly correspondence boss, unread words manifest special, message release, ethereal writing')
]

generated = 0
for boss_name, faction, desc in bosses:
    filename = f'boss_{boss_name.lower()}_special.png'
    filepath = OUTPUT_DIR / filename
    
    if filepath.exists():
        print(f'SKIP: {filename} already exists')
        continue
    
    prompt = f'pixel art {faction.lower()} boss, {desc}, special ability activation, game sprite, transparent background, fantasy style'
    
    payload = {
        'description': prompt,
        'image_size': {'width': 200, 'height': 200},
        'no_background': True
    }
    
    print(f'\nGenerating: {filename}')
    print(f'Prompt: {prompt[:100]}...')
    
    try:
        response = requests.post(
            'https://api.pixellab.ai/v1/generate-image-pixflux',
            headers=HEADERS,
            json=payload,
            timeout=120
        )
        response.raise_for_status()
        data = response.json()
        
        if 'image' in data and 'base64' in data['image']:
            img_data = base64.b64decode(data['image']['base64'])
            with open(filepath, 'wb') as f:
                f.write(img_data)
            print(f'SAVED: {filename}')
            generated += 1
        else:
            print(f'FAIL: No image data for {filename}')
    except Exception as e:
        print(f'ERROR: {e}')

print(f'\nDONE: Generated {generated}/6 boss specials')
