import sys, os, re
sys.path.insert(0, '/root/.openclaw/workspace/acanous_floor3_demo/scripts')
from card_compositor import composite_card

BASE = '/root/.openclaw/workspace/acanous_floor3_demo'

def read_tres(tres_path):
    with open(tres_path, 'r') as f:
        content = f.read()
    name = re.search(r'card_name = "([^"]+)"', content)
    ctype = re.search(r'card_type = "([^"]+)"', content)
    cost = re.search(r'attention_cost = (\d+)', content)
    effect = re.search(r'effect_text = "([^"]+)"', content)
    kw = re.findall(r'"([^"]+)"', content)
    # Filter out common non-keyword strings
    keywords = [k for k in kw if k not in ['Special', 'Attack', 'Defend', 'Field', 'Overlay', 'Arcane', 'Divine', 'Infernal'] and len(k) > 2]
    # But include faction keyword
    faction_match = re.search(r'faction = "([^"]+)"', content)
    faction = faction_match.group(1) if faction_match else ''
    if faction and faction not in keywords:
        keywords.insert(0, faction)
    
    return {
        'name': name.group(1) if name else 'Unknown',
        'type': ctype.group(1) if ctype else 'Special',
        'cost': int(cost.group(1)) if cost else 1,
        'effect': effect.group(1) if effect else '',
        'keywords': keywords
    }

for overlay_faction in ['Arcane', 'Divine', 'Infernal']:
    print(f"\n=== {overlay_faction} ===")
    tres_dir = f'{BASE}/finished_cards/Overlays/{overlay_faction}'
    art_dir = f'{BASE}/assets/sprites/cards/Overlays/{overlay_faction}'
    frame_path = f'{BASE}/assets/sprites/cards/{overlay_faction.lower()}_frame.png'
    
    if not os.path.exists(tres_dir):
        print(f"  Missing tres dir: {tres_dir}")
        continue
    
    for fname in sorted(os.listdir(tres_dir)):
        if not fname.endswith('.tres'):
            continue
        
        tres_path = f'{tres_dir}/{fname}'
        data = read_tres(tres_path)
        
        # Find matching art file
        card_base = data['name'].lower().replace(' ', '_')
        art_match = None
        for art in os.listdir(art_dir):
            if not art.endswith('.png') or art.endswith('.import'):
                continue
            if card_base in art.lower():
                art_match = art
                break
        
        if not art_match:
            print(f"  ❌ {data['name']}: NO ART FOUND")
            continue
        
        art_path = f'{art_dir}/{art_match}'
        
        # Generate printable
        out_name = f"{overlay_faction}_{card_base}.png"
        out_path = f'{BASE}/assets/sprites/cards/printable/{out_name}'
        
        try:
            card = composite_card(art_path, frame_path, overlay_faction, 
                                  data['name'], data['type'], data['cost'],
                                  data['effect'], data['keywords'])
            card.save(out_path)
            print(f"  ✅ {data['name']} → {out_name}")
        except Exception as e:
            print(f"  ❌ {data['name']}: ERROR - {e}")

print("\n=== Done ===")
