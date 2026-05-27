#!/usr/bin/env python3
"""Batch test all 18 merged frames for transparency and text positioning."""

import sys
sys.path.insert(0, '/root/.openclaw/workspace/acanous_floor3_demo/scripts')
from card_compositor import composite_card

# Test matrix: (faction, overlay, art_file_prefix, card_name, card_type, cost, effect, keywords)
# art_file_prefix is the part AFTER "Faction_" in the filename
TEST_CASES = [
    # Aberration
    ("Aberration", "Arcane", "consume_sanity", "Consume Sanity", "Attack", 3, "Deal 12 damage. Lose 1 Sanity.", "Aberration | Attack"),
    ("Aberration", "Divine", "consume_sanity", "Consume Sanity", "Attack", 3, "Deal 12 damage. Lose 1 Sanity.", "Aberration | Attack"),
    ("Aberration", "Infernal", "consume_sanity", "Consume Sanity", "Attack", 3, "Deal 12 damage. Lose 1 Sanity.", "Aberration | Attack"),
    # Construct
    ("Construct", "Arcane", "assembly_line", "Assembly Line", "Attack", 2, "Deal 8 damage. Draw 1 card.", "Construct | Attack"),
    ("Construct", "Divine", "assembly_line", "Assembly Line", "Attack", 2, "Deal 8 damage. Draw 1 card.", "Construct | Attack"),
    ("Construct", "Infernal", "assembly_line", "Assembly Line", "Attack", 2, "Deal 8 damage. Draw 1 card.", "Construct | Attack"),
    # Demon
    ("Demon", "Arcane", "blood_pact", "Blood Pact", "Special", 2, "Lose 3 HP. Gain 6 attention. Draw 2.", "Demon | Blood"),
    ("Demon", "Divine", "blood_pact", "Blood Pact", "Special", 2, "Lose 3 HP. Gain 6 attention. Draw 2.", "Demon | Blood"),
    ("Demon", "Infernal", "blood_pact", "Blood Pact", "Special", 2, "Lose 3 HP. Gain 6 attention. Draw 2.", "Demon | Blood"),
    # Elemental
    ("Elemental", "Arcane", "cyclone", "Cyclone", "Attack", 3, "Deal 10 damage. Push enemy back 1 hex.", "Elemental | Wind"),
    ("Elemental", "Divine", "cyclone", "Cyclone", "Attack", 3, "Deal 10 damage. Push enemy back 1 hex.", "Elemental | Wind"),
    ("Elemental", "Infernal", "cyclone", "Cyclone", "Attack", 3, "Deal 10 damage. Push enemy back 1 hex.", "Elemental | Wind"),
    # Goblin
    ("Goblin", "Arcane", "ambush", "Ambush", "Attack", 2, "Deal 6 damage. Steal 1 attention.", "Goblin | Steal"),
    ("Goblin", "Divine", "ambush", "Ambush", "Attack", 2, "Deal 6 damage. Steal 1 attention.", "Goblin | Steal"),
    ("Goblin", "Infernal", "ambush", "Ambush", "Attack", 2, "Deal 6 damage. Steal 1 attention.", "Goblin | Steal"),
    # Undead
    ("Undead", "Arcane", "bone_armor", "Bone Armor", "Defend", 2, "Gain 8 Block. Heal 4 HP.", "Undead | Bone"),
    ("Undead", "Divine", "bone_armor", "Bone Armor", "Defend", 2, "Gain 8 Block. Heal 4 HP.", "Undead | Bone"),
    ("Undead", "Infernal", "bone_armor", "Bone Armor", "Defend", 2, "Gain 8 Block. Heal 4 HP.", "Undead | Bone"),
]

BASE_DIR = "/root/.openclaw/workspace/acanous_floor3_demo"

for faction, overlay, art_prefix, card_name, card_type, cost, effect, keywords in TEST_CASES:
    art_path = f"{BASE_DIR}/assets/sprites/cards/{faction}/{faction}_{art_prefix}.png"
    frame_path = f"{BASE_DIR}/assets/sprites/cards/{faction.lower()}_frame.png"
    output = f"{BASE_DIR}/batch_test/{faction.lower()}_{overlay.lower()}_{art_prefix}.png"
    
    try:
        card = composite_card(
            art_path=art_path,
            frame_path=frame_path,
            faction=faction,
            card_name=card_name,
            card_type=card_type,
            attention_cost=cost,
            effect_text=effect,
            keywords=keywords,
            overlay=overlay
        )
        card.save(output)
        print(f"✓ {faction}+{overlay}: {card_name}")
    except Exception as e:
        print(f"✗ {faction}+{overlay}: {e}")

print("\nBatch complete! Check batch_test/ directory.")
