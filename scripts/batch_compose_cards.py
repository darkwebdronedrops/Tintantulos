#!/usr/bin/env python3
"""
Batch card compositor - generates finished cards for all 240 cards.
Run: cd /root/.openclaw/workspace/acanous_floor3_demo && python3 scripts/batch_compose_cards.py
"""

import os
import re
import sys
from pathlib import Path

# Add scripts dir to path for compositor import
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
from card_compositor import composite_card

BASE_DIR = "/root/.openclaw/workspace/acanous_floor3_demo"
FINISHED_DIR = os.path.join(BASE_DIR, "assets", "sprites", "cards", "finished")

def parse_tres_file(path):
    """Parse a Godot .tres file and extract key fields."""
    data = {}
    with open(path, 'r') as f:
        content = f.read()
    
    # Extract string fields
    for key in ['card_name', 'faction', 'card_type', 'description', 'damage_dice', 'keywords']:
        if key == 'keywords':
            # PackedStringArray format: PackedStringArray("keyword1", "keyword2")
            match = re.search(r'keywords\s*=\s*PackedStringArray\(([^)]*)\)', content)
            if match:
                items = match.group(1)
                # Extract quoted strings
                data[key] = re.findall(r'"([^"]*)"', items)
            else:
                data[key] = []
        else:
            match = re.search(rf'{key}\s*=\s*"([^"]*)"', content)
            if match:
                data[key] = match.group(1)
    
    # Extract integer fields
    for key in ['attention_cost', 'damage_flat', 'shield_amount', 'heal_amount', 'summon_count']:
        match = re.search(rf'{key}\s*=\s*(\d+)', content)
        if match:
            data[key] = int(match.group(1))
        else:
            data[key] = 0
    
    # Extract bool fields
    match = re.search(r'uses_dice\s*=\s*(true|false)', content)
    data['uses_dice'] = match.group(1) == 'true' if match else False
    
    # Extract texture paths
    for key in ['frame_texture_path', 'sprite_texture_path']:
        match = re.search(rf'{key}\s*=\s*"([^"]*)"', content)
        if match:
            data[key] = match.group(1)
    
    return data

def build_effect_text(card):
    """Build effect text from card stats."""
    parts = []
    if card.get('uses_dice') and card.get('damage_dice'):
        parts.append("DMG: %s" % card['damage_dice'])
    elif card.get('damage_flat', 0) > 0:
        parts.append("DMG: %d" % card['damage_flat'])
    if card.get('shield_amount', 0) > 0:
        parts.append("SHIELD: %d" % card['shield_amount'])
    if card.get('heal_amount', 0) > 0:
        parts.append("HEAL: %d" % card['heal_amount'])
    if card.get('summon_count', 0) > 0:
        parts.append("SUMMON %d" % card['summon_count'])
    
    effect = " / ".join(parts)
    
    # Add description if it adds something beyond stats
    desc = card.get('description', '')
    if desc and desc not in effect:
        if effect:
            effect = desc
        else:
            effect = desc
    
    return effect

def get_frame_path(faction, overlay=None):
    """Get frame path for a faction, optionally with overlay."""
    if overlay:
        path = f"{BASE_DIR}/assets/sprites/cards/{faction.lower()}_{overlay.lower()}_frame.png"
        if os.path.exists(path):
            return path
        print(f"  Warning: overlay frame not found: {path}")
    
    if faction == "Universal":
        return f"{BASE_DIR}/assets/sprites/cards/untyped_frame.png"
    return f"{BASE_DIR}/assets/sprites/cards/{faction.lower()}_frame.png"

def main():
    os.makedirs(FINISHED_DIR, exist_ok=True)
    
    finished_cards_dir = os.path.join(BASE_DIR, "finished_cards")
    
    total = 0
    success = 0
    failed = 0
    
    for faction_dir in sorted(os.listdir(finished_cards_dir)):
        faction_path = os.path.join(finished_cards_dir, faction_dir)
        if not os.path.isdir(faction_path):
            continue
        
        faction_output_dir = os.path.join(FINISHED_DIR, faction_dir)
        os.makedirs(faction_output_dir, exist_ok=True)
        
        for tres_file in sorted(os.listdir(faction_path)):
            if not tres_file.endswith('.tres'):
                continue
            
            tres_path = os.path.join(faction_path, tres_file)
            card = parse_tres_file(tres_path)
            
            if not card.get('card_name') or not card.get('faction'):
                print(f"  Skip {tres_file}: missing name/faction")
                failed += 1
                continue
            
            # Convert res:// paths to absolute
            sprite_path = card.get('sprite_texture_path', '')
            if sprite_path.startswith('res://'):
                sprite_path = os.path.join(BASE_DIR, sprite_path.replace('res://', ''))
            
            if not os.path.exists(sprite_path):
                print(f"  Skip {card['card_name']}: art not found at {sprite_path}")
                failed += 1
                continue
            
            # Determine overlay
            overlay = None
            if card.get('is_overlay') or 'overlay' in card.get('card_type', '').lower():
                overlay = card.get('overlay_type', '')
            
            frame_path = get_frame_path(card['faction'], overlay)
            
            effect_text = build_effect_text(card)
            keywords = card.get('keywords', [])
            
            safe_name = card['card_name'].lower().replace(' ', '_').replace("'", "")
            output_path = os.path.join(faction_output_dir, f"{safe_name}.png")
            
            try:
                finished = composite_card(
                    art_path=sprite_path,
                    frame_path=frame_path,
                    faction=card['faction'],
                    card_name=card['card_name'],
                    card_type=card.get('card_type', ''),
                    attention_cost=card.get('attention_cost', 0),
                    effect_text=effect_text,
                    keywords=keywords,
                    overlay=overlay
                )
                finished.save(output_path)
                success += 1
                print(f"  ✓ {card['faction']} - {card['card_name']}")
            except Exception as e:
                failed += 1
                print(f"  ✗ {card['faction']} - {card['card_name']}: {e}")
            
            total += 1
    
    print(f"\n=== Done ===")
    print(f"Total: {total}, Success: {success}, Failed: {failed}")
    print(f"Output: {FINISHED_DIR}")

if __name__ == '__main__':
    main()
