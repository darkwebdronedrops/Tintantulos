#!/usr/bin/env python3
"""
Card Generator for Acanous Card Battler
Parses markdown design docs and generates Godot .tres resource files
"""

import os
import re
import json
from pathlib import Path

# Configuration
OUTPUT_DIR = "res://CardsData"  # Where to save .tres files
CARD_DATA_SCRIPT = "res://CardData.gd"  # Path to CardData.gd in your project

# Card data structure matching CardData.gd
DEFAULT_CARD = {
    "card_name": "Unknown",
    "cost": 1,
    "faction": "Construct",
    "card_type": "Attack",
    "damage": 0,
    "block": 0,
    "description": "",
    "effects": []
}

# Faction list
FACTIONS = ["Construct", "Goblin", "Demon", "Elemental", "Undead", "Aberration", "Dragon"]

# Card type mapping (normalize various terms)
TYPE_MAP = {
    "attack": "Attack",
    "summon": "Skill",
    "trap": "Skill",
    "field": "Skill",
    "spell": "Attack",
    "direct": "Skill",
    "special": "Skill",
    "block": "Block",
    "power": "Power"
}

def parse_card_table(content):
    """Parse markdown tables to extract card data"""
    cards = []
    
    # Look for card tables with | # | Name | Type | Attention | Effect |
    # or variations
    lines = content.split('\n')
    in_table = False
    headers = []
    
    for line in lines:
        # Detect table header
        if '|' in line and ('Name' in line or 'Card' in line) and 'Type' in line:
            headers = [h.strip().lower() for h in line.split('|')]
            in_table = True
            continue
        
        # Skip separator lines
        if in_table and '---' in line and '|' in line:
            continue
        
        # Parse data rows
        if in_table and '|' in line and not line.strip().startswith('#'):
            cells = [c.strip() for c in line.split('|')]
            if len(cells) >= 4 and cells[1] and not cells[1].lower() in ['name', 'card', '']:
                card = parse_card_row(headers, cells)
                if card:
                    cards.append(card)
        
        # End of table
        if in_table and not '|' in line and line.strip():
            in_table = False
    
    return cards

def parse_card_row(headers, cells):
    """Parse a single card row from table"""
    card = DEFAULT_CARD.copy()
    
    # Create dict from headers and cells
    data = {}
    for i, header in enumerate(headers):
        if i < len(cells):
            data[header] = cells[i]
    
    # Extract card name
    if 'name' in data:
        card['card_name'] = data['name'].strip('*_')
    
    # Extract attention cost
    if 'attention' in data:
        try:
            card['cost'] = int(data['attention'])
        except:
            card['cost'] = 1
    
    # Extract type
    if 'type' in data:
        raw_type = data['type'].lower()
        card['card_type'] = TYPE_MAP.get(raw_type, 'Skill')
    
    # Extract effect/description
    if 'effect' in data:
        card['description'] = data['effect']
    
    # Try to extract damage from description
    desc = card.get('description', '')
    damage_match = re.search(r'(\d+)\s*damage', desc.lower())
    if damage_match:
        card['damage'] = int(damage_match.group(1))
    
    # Try to extract block/shield from description
    block_match = re.search(r'(\d+)\s*(?:shield|block)', desc.lower())
    if block_match:
        card['block'] = int(block_match.group(1))
    
    return card

def detect_faction_from_filename(filename):
    """Detect faction from filename"""
    fname = filename.lower()
    for faction in FACTIONS:
        if faction.lower() in fname:
            return faction
    return "Construct"  # Default

def generate_tres(card, resource_id):
    """Generate a .tres file content"""
    effects = card.get('effects', [])
    effects_str = ', '.join([f'"{e}"' for e in effects])
    if not effects_str:
        effects_str = '""'
    
    # Escape quotes in description
    description = card['description'].replace('"', '\\"')
    card_name = card['card_name'].replace('"', '\\"')
    
    tres = f"""[gd_resource type="Resource" script_class="CardData" load_steps=2 format=3]

[ext_resource type="Script" path="{CARD_DATA_SCRIPT}" id="1_{resource_id}"]

[resource]
script = ExtResource("1_{resource_id}")
card_name = "{card_name}"
cost = {card.get('cost', 1)}
faction = "{card.get('faction', 'Construct')}"
card_type = "{card.get('card_type', 'Attack')}"
damage = {card.get('damage', 0)}
block = {card.get('block', 0)}
description = "{description}"
effects = PackedStringArray([{effects_str}])
"""
    return tres

def generate_universal_cards():
    """Generate the 25 Universal/Buffer cards we know exist"""
    universal_cards = [
        {"card_name": "Strike", "cost": 2, "faction": "Construct", "card_type": "Attack", "damage": 3, "description": "Deal 1d6 damage. Basic attack."},
        {"card_name": "Defend", "cost": 1, "faction": "Construct", "card_type": "Block", "block": 3, "description": "Gain 3 Shield (absorbs damage)."},
        {"card_name": "Focus", "cost": 0, "faction": "Construct", "card_type": "Skill", "description": "Next card costs -2 Attention (min 1)."},
        {"card_name": "Gambit", "cost": 3, "faction": "Construct", "card_type": "Skill", "description": "Draw 3 cards. Discard 2 at end of turn."},
        {"card_name": "Recover", "cost": 2, "faction": "Construct", "card_type": "Skill", "description": "Heal 2 HP."},
        {"card_name": "Prepare", "cost": 1, "faction": "Construct", "card_type": "Skill", "description": "Cast 0, Trigger 0, Disarm 2. When enemy attacks: gain 2 Shield."},
        {"card_name": "Quick Step", "cost": 1, "faction": "Construct", "card_type": "Skill", "description": "Move 2 hexes. Evade next attack (50%)."},
        {"card_name": "Second Wind", "cost": 4, "faction": "Construct", "card_type": "Skill", "description": "Heal 4 HP. Usable only below 50% HP."},
        {"card_name": "Hoard Instinct", "cost": 2, "faction": "Construct", "card_type": "Skill", "description": "Gain 2 Quiddity now. Lose 1 HP."},
    ]
    return universal_cards

def main():
    """Main generation function"""
    print("Acanous Card Battler - Card Generator")
    print("=" * 50)
    
    # Create output directory if needed
    os.makedirs("generated_cards", exist_ok=True)
    
    all_cards = []
    
    # Generate Universal cards
    print("\n[Universal Cards]")
    universal = generate_universal_cards()
    for card in universal:
        all_cards.append(card)
        print(f"  + {card['card_name']}")
    
    # Note about faction cards
    print("\n[Faction Cards - Placeholder]")
    print("  To generate all 240 cards, we need to parse:")
    print("  - ACANOUS_CARD_BATTLER_MASTER.md")
    print("  - CONSTRUCT_ENEMIES.md")
    print("  - GOBLIN_ENEMIES_WORKING.md")
    print("  - etc.")
    
    # For now, generate sample faction cards
    sample_faction_cards = [
        {"card_name": "Gear Shield", "cost": 1, "faction": "Construct", "card_type": "Skill", "description": "Cast 1, Trigger 1, Disarm 2. When enemy Primary Attack (Melee): 4d6 damage."},
        {"card_name": "Brass Enforcer", "cost": 3, "faction": "Construct", "card_type": "Attack", "damage": 5, "description": "Deal 5 damage. Machine: Average damage dealt."},
        {"card_name": "Spark", "cost": 1, "faction": "Goblin", "card_type": "Attack", "damage": 3, "description": "Deal 3 damage. Sneaky: +2d6 if enemy lacks Sneaky."},
        {"card_name": "Fireball", "cost": 3, "faction": "Elemental", "card_type": "Attack", "damage": 10, "description": "Radius 2, 3d6 damage. Hits 19 hexes."},
        {"card_name": "Bone Wall", "cost": 4, "faction": "Undead", "card_type": "Skill", "description": "Summon 0/8 Bone Wall. Blocks line of sight. Persist."},
        {"card_name": "Demonic Bargain", "cost": 2, "faction": "Demon", "card_type": "Skill", "description": "Gain 5 Quiddity. Add 1 Corruption."},
        {"card_name": "Glitch Step", "cost": 1, "faction": "Aberration", "card_type": "Skill", "description": "Move unpredictably. 50% chance to dodge."},
        {"card_name": "Young Drake", "cost": 6, "faction": "Dragon", "card_type": "Skill", "damage": 4, "description": "4/6 stats, First Strike, Growth. Attacks for 2d6. Gain 1 Quiddity when attacking."},
    ]
    
    for card in sample_faction_cards:
        all_cards.append(card)
        print(f"  + {card['card_name']} ({card['faction']})")
    
    # Generate .tres files
    print(f"\n[Generating {len(all_cards)} .tres files...]")
    
    for i, card in enumerate(all_cards):
        resource_id = f"{i:04d}"
        safe_name = card['card_name'].replace(' ', '_').replace('/', '_')
        filename = f"{safe_name}_{resource_id}.tres"
        filepath = os.path.join("generated_cards", filename)
        
        tres_content = generate_tres(card, resource_id)
        
        with open(filepath, 'w') as f:
            f.write(tres_content)
        
        print(f"  -> {filename}")
    
    print(f"\n[Complete!]")
    print(f"Generated {len(all_cards)} cards in ./generated_cards/")
    print(f"\nTo use in Godot:")
    print(f"1. Copy the .tres files to your project's {OUTPUT_DIR} folder")
    print(f"2. In Godot, assign them to Card nodes via the 'Card Data' export variable")
    print(f"3. The faction frames should switch automatically!")

if __name__ == "__main__":
    main()
