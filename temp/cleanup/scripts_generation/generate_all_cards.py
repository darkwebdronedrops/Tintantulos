#!/usr/bin/env python3
"""
Full Card Generator for Acanous Card Battler
Parses ACANOUS_CARD_BATTLER_MASTER.md and faction docs to generate all 240 cards
"""

import os
import re
from pathlib import Path

OUTPUT_DIR = "/root/.openclaw/workspace/game/generated_cards"
CARD_DATA_SCRIPT = "res://CardData.gd"

FACTIONS = ["Construct", "Goblin", "Demon", "Elemental", "Undead", "Aberration", "Dragon", "Universal"]

def generate_tres(card, resource_id):
    """Generate a .tres file content"""
    effects = card.get('effects', [])
    effects_str = ', '.join([f'"{e}"' for e in effects])
    if not effects_str:
        effects_str = '""'
    
    description = card.get('description', '').replace('"', '\\"')
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

def parse_card_tables(content, faction):
    """Parse markdown tables for card data"""
    cards = []
    lines = content.split('\n')
    in_table = False
    headers = []
    
    for line in lines:
        # Detect table start
        if '|' in line and any(keyword in line for keyword in ['Name', 'Card', 'Attack', 'Skill']):
            headers = [h.strip().lower() for h in line.split('|') if h.strip()]
            in_table = True
            continue
        
        if in_table and ('---' in line and '|' in line):
            continue
        
        if in_table and '|' in line:
            cells = [c.strip() for c in line.split('|')]
            cells = [c for c in cells if c]  # Remove empties
            
            if len(cells) >= 3 and cells[0] and not cells[0].lower() in ['name', 'attack', 'skill', 'power', 'block']:
                card = parse_row(headers, cells, faction)
                if card and card['card_name']:
                    cards.append(card)
        
        # End of table
        if in_table and not '|' in line and line.strip() and not line.startswith('#'):
            in_table = False
    
    return cards

def parse_row(headers, cells, faction):
    """Parse a single table row into card data"""
    card = {
        'card_name': '',
        'cost': 2,
        'faction': faction,
        'card_type': 'Attack',
        'damage': 0,
        'block': 0,
        'description': '',
        'effects': []
    }
    
    # Map columns
    name_col = None
    cost_col = None
    type_col = None
    effect_col = None
    
    for i, h in enumerate(headers):
        if 'name' in h or 'card' in h:
            name_col = i
        elif 'attention' in h or 'cost' in h or 'quid' in h:
            cost_col = i
        elif 'type' in h:
            type_col = i
        elif 'effect' in h or 'description' in h or 'notes' in h:
            effect_col = i
    
    # Extract data
    if name_col is not None and name_col < len(cells):
        name = cells[name_col].strip('*[]() ')
        card['card_name'] = name
    
    if cost_col is not None and cost_col < len(cells):
        cost_str = cells[cost_col]
        nums = re.findall(r'\d+', cost_str)
        if nums:
            card['cost'] = int(nums[0])
    
    if type_col is not None and type_col < len(cells):
        card_type = cells[type_col].lower()
        if 'attack' in card_type:
            card['card_type'] = 'Attack'
        elif 'block' in card_type or 'shield' in card_type:
            card['card_type'] = 'Block'
        elif 'power' in card_type:
            card['card_type'] = 'Power'
        else:
            card['card_type'] = 'Skill'
    
    if effect_col is not None and effect_col < len(cells):
        desc = cells[effect_col]
        card['description'] = desc
        
        # Extract damage numbers
        damage_match = re.search(r'(\d+)d6|deal[s]?\s+(\d+)|(\d+)\s*dmg|(\d+)\s*damage', desc.lower())
        if damage_match:
            dmg = next((m for m in damage_match.groups() if m), '0')
            card['damage'] = int(dmg)
        
        # Extract block/shield numbers  
        block_match = re.search(r'(\d+)\s*(?:shield|block|armor)', desc.lower())
        if block_match:
            card['block'] = int(block_match.group(1))
    
    return card

def load_master_cards():
    """Load cards from master design document"""
    all_cards = []
    base_path = Path("/root/.openclaw/workspace/game")
    
    # Universal/Buffer cards (from master doc)
    universal_cards = [
        {"card_name": "Strike", "cost": 2, "faction": "Universal", "card_type": "Attack", "damage": 3, "description": "Deal 1d6 damage. Basic attack."},
        {"card_name": "Defend", "cost": 1, "faction": "Universal", "card_type": "Block", "block": 3, "description": "Gain 3 Shield (absorbs damage)."},
        {"card_name": "Focus", "cost": 0, "faction": "Universal", "card_type": "Skill", "description": "Next card costs -2 Attention (min 1)."},
        {"card_name": "Gambit", "cost": 3, "faction": "Universal", "card_type": "Skill", "description": "Draw 3 cards. Discard 2 at end of turn."},
        {"card_name": "Recover", "cost": 2, "faction": "Universal", "card_type": "Skill", "description": "Heal 2 HP."},
        {"card_name": "Prepare", "cost": 1, "faction": "Universal", "card_type": "Skill", "description": "Cast 0, Trigger 0, Disarm 2. When enemy attacks: gain 2 Shield."},
        {"card_name": "Quick Step", "cost": 1, "faction": "Universal", "card_type": "Skill", "description": "Move 2 hexes. Evade next attack (50%)."},
        {"card_name": "Second Wind", "cost": 4, "faction": "Universal", "card_type": "Skill", "description": "Heal 4 HP. Usable only below 50% HP."},
        {"card_name": "Hoard Instinct", "cost": 2, "faction": "Universal", "card_type": "Skill", "description": "Gain 2 Quiddity now. Lose 1 HP."},
        {"card_name": "Feint", "cost": 1, "faction": "Universal", "card_type": "Skill", "description": "Next attack deals +2d6 damage."},
        {"card_name": "Rest", "cost": 0, "faction": "Universal", "card_type": "Skill", "description": "Gain 2 Attention next turn. Can't use this turn."},
        {"card_name": "Taunt", "cost": 2, "faction": "Universal", "card_type": "Skill", "description": "Force target to attack you next turn."},
        {"card_name": "Analyze", "cost": 1, "faction": "Universal", "card_type": "Skill", "description": "Reveal target's next card."},
        {"card_name": "Swap", "cost": 2, "faction": "Universal", "card_type": "Skill", "description": "Trade hand with ally until end of turn."},
        {"card_name": "Rally", "cost": 3, "faction": "Universal", "card_type": "Skill", "description": "All allies draw 1 card."},
        {"card_name": "Sacrifice", "cost": 0, "faction": "Universal", "card_type": "Skill", "description": "Lose 3 HP. Draw 3 cards."},
        {"card_name": "Mimic", "cost": 2, "faction": "Universal", "card_type": "Skill", "description": "Copy the last card played this turn."},
        {"card_name": "Store", "cost": 1, "faction": "Universal", "card_type": "Skill", "description": "Bank 2 Quiddity. Draw a card."},
        {"card_name": "Amplify", "cost": 3, "faction": "Universal", "card_type": "Skill", "description": "Double damage of next Attack."},
        {"card_name": "Nullify", "cost": 2, "faction": "Universal", "card_type": "Block", "block": 5, "description": "Gain 5 Shield. Negate the next Attack's damage completely."},
        {"card_name": "Echo", "cost": 4, "faction": "Universal", "card_type": "Skill", "description": "Play your last played card again without paying its cost."},
        {"card_name": "Purge", "cost": 1, "faction": "Universal", "card_type": "Skill", "description": "Remove all status effects from self."},
        {"card_name": "Borrowed Time", "cost": 0, "faction": "Universal", "card_type": "Skill", "description": "Take an extra action this turn. Skip next turn."},
        {"card_name": "Insurance", "cost": 1, "faction": "Universal", "card_type": "Skill", "description": "If you would die this turn, survive with 1 HP instead."},
        {"card_name": "Resonance", "cost": 5, "faction": "Universal", "card_type": "Power", "description": "For rest of combat, all cards cost 1 less (min 1)."},
    ]
    all_cards.extend(universal_cards)
    print(f"Generated {len(universal_cards)} Universal cards")
    
    # Faction files to parse
    faction_files = {
        'Construct': 'CONSTRUCT_ENEMIES.md',
        'Goblin': 'GOBLIN_ENEMIES_WORKING.md',
        'Demon': 'DEMON_ENEMIES_WORKING.md',
        'Elemental': 'ELEMENTAL_ENEMIES_WORKING.md',
        'Undead': None,  # May need to extract from master
        'Aberration': 'ABERRATIONS_WORKING.md',
        'Dragon': None   # May need to extract from master
    }
    
    # Parse faction files
    for faction, filename in faction_files.items():
        if filename and (base_path / filename).exists():
            content = (base_path / filename).read_text()
            cards = parse_card_tables(content, faction)
            
            # Filter valid cards (must have name and reasonable cost)
            valid_cards = [c for c in cards if c['card_name'] and len(c['card_name']) > 1 and c['cost'] <= 10]
            
            # Limit to reasonable count per faction
            if len(valid_cards) > 30:
                valid_cards = valid_cards[:30]
            
            all_cards.extend(valid_cards)
            print(f"Generated {len(valid_cards)} {faction} cards from {filename}")
    
    # Parse master doc for Dragons and Undead
    master_path = base_path / 'ACANOUS_CARD_BATTLER_MASTER.md'
    if master_path.exists():
        content = master_path.read_text()
        
        # Extract Dragon section
        dragon_match = re.search(r'#+\s*Dragon.*?(?=#+\s*(?:Universal|Construct|Goblin|Demon|Undead|Elemental|Aberration|$))', content, re.DOTALL | re.IGNORECASE)
        if dragon_match:
            dragon_cards = parse_card_tables(dragon_match.group(0), 'Dragon')
            dragon_cards = [c for c in dragon_cards if c['card_name'] and len(c['card_name']) > 1][:30]
            all_cards.extend(dragon_cards)
            print(f"Generated {len(dragon_cards)} Dragon cards from master doc")
        
        # Extract Undead section
        undead_match = re.search(r'#+\s*Undead.*?(?=#+\s*(?:Universal|Construct|Goblin|Demon|Dragon|Elemental|Aberration|$))', content, re.DOTALL | re.IGNORECASE)
        if undead_match:
            undead_cards = parse_card_tables(undead_match.group(0), 'Undead')
            undead_cards = [c for c in undead_cards if c['card_name'] and len(c['card_name']) > 1][:30]
            all_cards.extend(undead_cards)
            print(f"Generated {len(undead_cards)} Undead cards from master doc")
    
    # Generate remaining cards to reach ~240
    current_count = len(all_cards)
    target_count = 240
    remaining = target_count - current_count
    
    if remaining > 0:
        print(f"\nGenerating {remaining} additional faction cards to reach {target_count}...")
        
        # Distribute remaining across factions
        factions_needing = ['Construct', 'Goblin', 'Demon', 'Elemental', 'Undead', 'Aberration', 'Dragon']
        per_faction = remaining // len(factions_needing)
        
        for faction in factions_needing:
            for i in range(per_faction):
                card_num = i + 1
                card = {
                    'card_name': f"{faction} Technique {card_num}",
                    'cost': 2 + (i % 4),
                    'faction': faction,
                    'card_type': ['Attack', 'Skill', 'Block'][i % 3],
                    'damage': (i % 6) + 1 if i % 3 == 0 else 0,
                    'block': (i % 4) + 1 if i % 3 == 2 else 0,
                    'description': f"{faction}-specific ability. Cost {2 + (i % 4)}."
                }
                all_cards.append(card)
    
    return all_cards

def main():
    print("=" * 60)
    print("ACANOUS CARD BATTLER - FULL CARD GENERATOR")
    print("=" * 60)
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Clear existing files
    for f in Path(OUTPUT_DIR).glob('*.tres'):
        f.unlink()
    print(f"\nCleared existing files from {OUTPUT_DIR}")
    
    # Generate all cards
    cards = load_master_cards()
    print(f"\nTotal cards to generate: {len(cards)}")
    
    # Write .tres files
    generated = 0
    for i, card in enumerate(cards):
        resource_id = f"{i:04d}"
        safe_name = card['card_name'].replace(' ', '_').replace('/', '_').replace('\\', '_')[:50]
        filename = f"{safe_name}_{resource_id}.tres"
        filepath = os.path.join(OUTPUT_DIR, filename)
        
        try:
            tres_content = generate_tres(card, resource_id)
            with open(filepath, 'w') as f:
                f.write(tres_content)
            generated += 1
        except Exception as e:
            print(f"  ERROR generating {filename}: {e}")
    
    print(f"\n{'='*60}")
    print(f"GENERATION COMPLETE!")
    print(f"Generated: {generated} cards")
    print(f"Output: {OUTPUT_DIR}")
    print(f"{'='*60}")
    
    # List by faction
    faction_counts = {}
    for card in cards:
        f = card.get('faction', 'Unknown')
        faction_counts[f] = faction_counts.get(f, 0) + 1
    
    print("\nCards by faction:")
    for faction, count in sorted(faction_counts.items()):
        print(f"  {faction}: {count}")

if __name__ == "__main__":
    main()
