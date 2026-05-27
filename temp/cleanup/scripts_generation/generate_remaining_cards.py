#!/usr/bin/env python3
"""
Acanous Card Battler - Card Generator
Generates all 50 cards (20 Universal + 30 Faction) and FactionDeckRandomizer
"""

import os
import json

# Base path for card output
BASE_PATH = "/root/.openclaw/workspace/game/finished_cards"

# Card template
CARD_TEMPLATE = """[gd_resource type="Resource" script_class="CardData" load_steps=2 format=3]

[ext_resource type="Script" uid="uid://d17eib7xsesug" path="res://CardData.gd" id="1_{id_suffix}"]

[resource]
script = ExtResource("1_{id_suffix}")
card_name = "{card_name}"
faction = "{faction}"
card_type = "{card_type}"
attention_cost = {attention_cost}
quiddity_gain = {quiddity_gain}
damage_dice = "{damage_dice}"
damage_flat = {damage_flat}
uses_dice = {uses_dice}
shield_amount = {shield_amount}
heal_amount = {heal_amount}
summon_attack = {summon_attack}
summon_hp = {summon_hp}
summon_count = {summon_count}
summon_growth_atk = {summon_growth_atk}
summon_growth_hp = {summon_growth_hp}
attack_type = "{attack_type}"
attack_roll = "{attack_roll}"
keywords = PackedStringArray({keywords})
trap_cast_cost = {trap_cast_cost}
trap_trigger_cost = {trap_trigger_cost}
trap_disarm_cost = {trap_disarm_cost}
trap_trigger_action = "{trap_trigger_action}"
trap_disarm_action = "{trap_disarm_action}"
field_persist = {field_persist}
range_type = "{range_type}"
aoe_radius = {aoe_radius}
targets_all = {targets_all}
special_effect = "{special_effect}"
requires_condition = "{requires_condition}"
corruption_gain = {corruption_gain}
is_overlay = {is_overlay}
overlay_type = "{overlay_type}"
gem_cost = {gem_cost}
description = "{description}"
frame_texture_path = "{frame_texture_path}"
"""

def create_card(faction, card_name, **kwargs):
    """Create a card .tres file"""
    folder = os.path.join(BASE_PATH, faction)
    os.makedirs(folder, exist_ok=True)
    
    # Build ID suffix from card name
    id_suffix = card_name.lower().replace(" ", "_")
    filename = f"{faction}_{id_suffix}.tres"
    filepath = os.path.join(folder, filename)
    
    # Default values
    defaults = {
        "card_name": card_name,
        "faction": faction,
        "card_type": "Attack",
        "attention_cost": 2,
        "quiddity_gain": 0,
        "damage_dice": "",
        "damage_flat": 0,
        "uses_dice": "true",
        "shield_amount": 0,
        "heal_amount": 0,
        "summon_attack": 0,
        "summon_hp": 0,
        "summon_count": 0,
        "summon_growth_atk": 0,
        "summon_growth_hp": 0,
        "attack_type": "",
        "attack_roll": "",
        "keywords": "[]",
        "trap_cast_cost": 0,
        "trap_trigger_cost": 0,
        "trap_disarm_cost": 0,
        "trap_trigger_action": "",
        "trap_disarm_action": "",
        "field_persist": "false",
        "range_type": "",
        "aoe_radius": 0,
        "targets_all": "false",
        "special_effect": "",
        "requires_condition": "",
        "corruption_gain": 0,
        "is_overlay": "false",
        "overlay_type": "",
        "gem_cost": 0,
        "description": "",
        "frame_texture_path": "",
        "id_suffix": id_suffix
    }
    
    # Update with provided values
    defaults.update(kwargs)
    
    content = CARD_TEMPLATE.format(**defaults)
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    return filepath

# ============================================================================
# UNIVERSAL CARDS (20 total)
# ============================================================================

def create_universal_cards():
    cards = []
    
    # 1. Strike - Basic attack
    cards.append(create_card("Universal", "Strike", 
        card_type="Attack",
        attention_cost=2,
        damage_dice="1d6",
        description="1d6 damage. Basic attack."))
    
    # 2. Defend - Shield gain
    cards.append(create_card("Universal", "Defend",
        card_type="Special",
        attention_cost=1,
        shield_amount=3,
        description="Gain 3 Shield (absorbs damage)."))
    
    # 3. Focus - Cost reduction
    cards.append(create_card("Universal", "Focus",
        card_type="Special", 
        attention_cost=0,
        special_effect="Next card costs -2 Attention (min 1)",
        description="Next card costs -2 Attention (min 1)."))
    
    # 4. Gambit - Card draw
    cards.append(create_card("Universal", "Gambit",
        card_type="Special",
        attention_cost=3,
        special_effect="Draw 3 cards, discard 2 at end of turn",
        description="Draw 3 cards. Discard 2 at end of turn."))
    
    # 5. Recover - Heal
    cards.append(create_card("Universal", "Recover",
        card_type="Direct",
        attention_cost=2,
        heal_amount=2,
        description="Heal 2 HP."))
    
    # 6. Quick Step - Movement
    cards.append(create_card("Universal", "Quick Step",
        card_type="Special",
        attention_cost=1,
        special_effect="Move 2 hexes. Evade next attack (50%)",
        description="Move 2 hexes. Evade next attack (50%)."))
    
    # 7. Second Wind - Emergency heal
    cards.append(create_card("Universal", "Second Wind",
        card_type="Direct",
        attention_cost=4,
        heal_amount=4,
        requires_condition="below 50% HP",
        description="Heal 4 HP. Usable only below 50% HP."))
    
    # 8. Hoard Instinct - Quiddity gain with cost
    cards.append(create_card("Universal", "Hoard Instinct",
        card_type="Special",
        attention_cost=2,
        quiddity_gain=2,
        special_effect="Lose 1 HP",
        description="Gain 2 Quiddity now. Lose 1 HP."))
    
    # 9. Feint - Weak attack with miss effect
    cards.append(create_card("Universal", "Feint",
        card_type="Attack",
        attention_cost=1,
        damage_dice="1d4",
        special_effect="Enemy's next attack misses",
        description="1d4 damage. Enemy's next attack misses."))
    
    # 10. Brace - Heavy shield with restriction
    cards.append(create_card("Universal", "Brace",
        card_type="Special",
        attention_cost=2,
        shield_amount=5,
        special_effect="Cannot attack next turn",
        description="Gain 5 Shield. Cannot attack next turn."))
    
    # 11. Exploit - Conditional damage
    cards.append(create_card("Universal", "Exploit",
        card_type="Attack",
        attention_cost=3,
        damage_dice="2d6",
        special_effect="+1d6 if enemy HP below 50%",
        description="2d6 damage. +1d6 if enemy HP below 50%."))
    
    # 12. Tread Lightly - Attention reduction
    cards.append(create_card("Universal", "Tread Lightly",
        card_type="Special",
        attention_cost=1,
        special_effect="Attention -3 for 2 turns",
        description="Attention -3 for 2 turns."))
    
    # 13. Desperate Lunge - High damage with self-damage
    cards.append(create_card("Universal", "Desperate Lunge",
        card_type="Attack",
        attention_cost=5,
        damage_dice="3d6",
        special_effect="Take 1d4 damage",
        description="3d6 damage. Take 1d4 damage."))
    
    # 14. Catch Breath - Small heal + draw
    cards.append(create_card("Universal", "Catch Breath",
        card_type="Direct",
        attention_cost=0,
        heal_amount=1,
        special_effect="Draw 1 card",
        description="Heal 1 HP. Draw 1 card."))
    
    # 15. Study - Deck manipulation
    cards.append(create_card("Universal", "Study",
        card_type="Special",
        attention_cost=1,
        special_effect="Look at top 3 cards, arrange order",
        description="Look at top 3 cards of deck. Put back in any order."))
    
    # 16. Throw Voice - Position manipulation
    cards.append(create_card("Universal", "Throw Voice",
        card_type="Special",
        attention_cost=2,
        special_effect="Enemy moves 1 hex toward target point",
        description="Enemy moves 1 hex toward target point."))
    
    # 17. Blinding Dust - Attack with debuff
    cards.append(create_card("Universal", "Blinding Dust",
        card_type="Attack",
        attention_cost=3,
        damage_dice="1d4",
        special_effect="Enemy attacks at -2 for 2 turns",
        description="1d4 damage. Enemy attacks at -2 for 2 turns."))
    
    # 18. Leverage - Discard for Quiddity
    cards.append(create_card("Universal", "Leverage",
        card_type="Special",
        attention_cost=2,
        quiddity_gain=3,
        special_effect="Discard 1 card",
        description="Discard 1 card. Gain 3 Quiddity."))
    
    # 19. Deep Breath - Attention reduction
    cards.append(create_card("Universal", "Deep Breath",
        card_type="Direct",
        attention_cost=0,
        special_effect="Reduce Attention by 3",
        description="Reduce Attention by 3."))
    
    # 20. Overextend - Powerful attack with debt
    cards.append(create_card("Universal", "Overextend",
        card_type="Attack",
        attention_cost=6,
        damage_dice="4d6",
        special_effect="Next turn: start with 3 Attention (Debt)",
        description="4d6 damage. Next turn: start with 3 Attention (Debt)."))
    
    return cards

# ============================================================================
# CONSTRUCT CARDS (5 cards)
# ============================================================================

def create_construct_cards():
    cards = []
    
    # 1. Gear Shield - Trap
    cards.append(create_card("Construct", "Gear Shield",
        card_type="Trap",
        attention_cost=1,
        trap_cast_cost=1,
        trap_trigger_cost=1,
        trap_disarm_cost=2,
        trap_trigger_action="Attack",
        trap_disarm_action="Special",
        keywords='["Machine", "Precision"]',
        description="Trap: Cast 1, Trigger 1, Disarm 2. Blocks next attack."))
    
    # 2. Assembly Line - Summon
    cards.append(create_card("Construct", "Assembly Line",
        card_type="Summon",
        attention_cost=3,
        summon_attack=2,
        summon_hp=3,
        summon_count=1,
        summon_growth_atk=1,
        summon_growth_hp=1,
        attack_type="flat",
        attack_roll="2d6",
        keywords='["Machine"]',
        description="Summon: 2/3 with Growth +1/+1 each turn."))
    
    # 3. Optimize - Special (averages damage)
    cards.append(create_card("Construct", "Optimize",
        card_type="Special",
        attention_cost=2,
        keywords='["Precision"]',
        special_effect="Next damage roll becomes average (rounded up)",
        description="Special: Averages next damage roll (round up)."))
    
    # 4. Calibrate - Field
    cards.append(create_card("Construct", "Calibrate",
        card_type="Field",
        attention_cost=3,
        field_persist="true",
        keywords='["Machine", "Precision"]',
        special_effect="+1 damage for all Machine cards",
        description="Field: +1 damage for Machine cards. Persist."))
    
    # 5. Overclock - Attack with self-damage
    cards.append(create_card("Construct", "Overclock",
        card_type="Attack",
        attention_cost=4,
        damage_dice="3d6",
        special_effect="Take 2 damage",
        keywords='["Machine"]',
        description="Attack: 3d6 damage, take 2 damage."))
    
    return cards

# ============================================================================
# GOBLIN CARDS (5 cards)
# ============================================================================

def create_goblin_cards():
    cards = []
    
    # 1. Shank - Sneaky attack
    cards.append(create_card("Goblin", "Shank",
        card_type="Attack",
        attention_cost=2,
        damage_dice="1d6",
        special_effect="Sneaky: +2d6 if target lacks keywords",
        keywords='["Sneaky"]',
        description="Attack: 1d6, Sneaky +2d6 if target lacks keywords."))
    
    # 2. Sharp Stick - Sharp attack
    cards.append(create_card("Goblin", "Sharp Stick",
        card_type="Attack",
        attention_cost=2,
        damage_dice="2d6",
        special_effect="Sharp: treat as 3d6",
        keywords='["Sharp"]',
        description="Attack: 2d6, Sharp makes it 3d6."))
    
    # 3. Quick Strike - Fast attack
    cards.append(create_card("Goblin", "Quick Strike",
        card_type="Attack",
        attention_cost=1,
        damage_dice="1d4",
        keywords='["Fast"]',
        special_effect="Fast: resolves before enemy actions",
        description="Attack: 1d4, Fast - resolves before enemy."))
    
    # 4. Swarm Tactics - Ally-based damage
    cards.append(create_card("Goblin", "Swarm Tactics",
        card_type="Special",
        attention_cost=2,
        damage_dice="1d6",
        special_effect="+1 damage per ally",
        keywords='["Sneaky"]',
        description="Special: +1 damage per ally on next attack."))
    
    # 5. Backstab - Position-based attack
    cards.append(create_card("Goblin", "Backstab",
        card_type="Attack",
        attention_cost=3,
        damage_dice="2d6",
        special_effect="+1d6 from behind",
        keywords='["Sneaky"]',
        description="Attack: 2d6, +1d6 from behind."))
    
    return cards

# ============================================================================
# UNDEAD CARDS (5 cards)
# ============================================================================

def create_undead_cards():
    cards = []
    
    # 1. Bone Shield - Convert attention to shield
    cards.append(create_card("Undead", "Bone Shield",
        card_type="Special",
        attention_cost=2,
        shield_amount=5,  # Based on 1/2 attention (assuming 10 attention = 5 shield)
        keywords='["Death", "Bone"]',
        special_effect="1/2 current Attention becomes Shield",
        description="Special: 1/2 attention becomes Shield."))
    
    # 2. Death Grip - Kill gives quiddity
    cards.append(create_card("Undead", "Death Grip",
        card_type="Attack",
        attention_cost=3,
        damage_dice="2d6",
        keywords='["Death"]',
        special_effect="Death: doubles quiddity on kill",
        description="Attack: 2d6, Death doubles quiddity on kill."))
    
    # 3. Grasping Hands - Trap
    cards.append(create_card("Undead", "Grasping Hands",
        card_type="Trap",
        attention_cost=0,
        trap_cast_cost=0,
        trap_trigger_cost=2,
        trap_disarm_cost=3,
        trap_trigger_action="Move",
        trap_disarm_action="Special",
        keywords='["Death", "Grasp"]',
        description="Trap: Cast 0, Trigger 2, Disarm 3. Immobilizes on trigger."))
    
    # 4. Unnatural Persistence - Return destroyed summon
    cards.append(create_card("Undead", "Unnatural Persistence",
        card_type="Direct",
        attention_cost=2,
        keywords='["Death"]',
        special_effect="Return destroyed Undead summon to play at 1 HP",
        description="Direct: Return destroyed Undead summon to play at 1 HP."))
    
    # 5. Grave Chill - AoE with debuff
    cards.append(create_card("Undead", "Grave Chill",
        card_type="Attack",
        attention_cost=3,
        damage_dice="2d6",
        aoe_radius=1,
        keywords='["Death"]',
        special_effect="Removes Fast from enemies in radius",
        description="Attack: Radius 1, 2d6, removes Fast."))
    
    return cards

# ============================================================================
# ELEMENTAL CARDS (5 cards)
# ============================================================================

def create_elemental_cards():
    cards = []
    
    # 1. Flash Flood - Line attack with push
    cards.append(create_card("Elemental", "Flash Flood",
        card_type="Attack",
        attention_cost=4,
        damage_dice="2d6",
        range_type="Line",
        keywords='["Flow", "Nature"]',
        special_effect="Line 4, push enemies back 1 hex",
        description="Attack: Line 4, 2d6, push back."))
    
    # 2. Ember Core - Reduce fire cost
    cards.append(create_card("Elemental", "Ember Core",
        card_type="Special",
        attention_cost=2,
        keywords='["Nature"]',
        special_effect="Next Fire card costs -2 Attention",
        description="Special: Next Fire card -2 attention."))
    
    # 3. Tidal Surge - AoE with heal
    cards.append(create_card("Elemental", "Tidal Surge",
        card_type="Attack",
        attention_cost=5,
        damage_dice="3d6",
        aoe_radius=2,
        keywords='["Flow", "Nature"]',
        special_effect="Heal 1 HP per enemy hit",
        description="Attack: Radius 2, 3d6, heal 1 per hit."))
    
    # 4. Flow State - Delayed attack
    cards.append(create_card("Elemental", "Flow State",
        card_type="Attack",
        attention_cost=3,
        damage_dice="2d6",
        keywords='["Flow"]',
        special_effect="Flow: Resolves at end of player phase",
        description="Attack: Flow - resolves end of player phase."))
    
    # 5. Nature's Blessing - Buff summons
    cards.append(create_card("Elemental", "Nature's Blessing",
        card_type="Special",
        attention_cost=2,
        keywords='["Nature"]',
        special_effect="All summons +1 HP",
        description="Special: All summons +1 HP."))
    
    return cards

# ============================================================================
# DEMON CARDS (5 cards)
# ============================================================================

def create_demon_cards():
    cards = []
    
    # 1. Painforged - Take damage for buff
    cards.append(create_card("Demon", "Painforged",
        card_type="Special",
        attention_cost=2,
        keywords='["Corruption"]',
        special_effect="Take 2 damage, next attack +3d6",
        description="Special: Take 2 damage, next attack +3d6."))
    
    # 2. Hellchain - Chain kill damage
    cards.append(create_card("Demon", "Hellchain",
        card_type="Attack",
        attention_cost=4,
        damage_dice="2d6",
        keywords='["Corruption"]',
        special_effect="If kill: chain to nearest enemy for 1d6",
        description="Attack: 2d6, chain to nearest on kill."))
    
    # 3. Torment - Field damage
    cards.append(create_card("Demon", "Torment",
        card_type="Field",
        attention_cost=4,
        field_persist="true",
        keywords='["Corruption"]',
        special_effect="Enemies take 1 when they attack",
        description="Field: Enemies take 1 when they attack. Persist."))
    
    # 4. Dark Pact - Discard damage
    cards.append(create_card("Demon", "Dark Pact",
        card_type="Special",
        attention_cost=1,
        keywords='["Bargain"]',
        special_effect="When discarded: deals attention value damage",
        description="Special: Bargain - when discarded, deals attention value damage."))
    
    # 5. Corrupting Touch - Apply corruption
    cards.append(create_card("Demon", "Corrupting Touch",
        card_type="Attack",
        attention_cost=2,
        damage_dice="1d6",
        corruption_gain=1,
        keywords='["Corruption"]',
        special_effect="Apply 1 Corruption",
        description="Attack: Apply 1 Corruption."))
    
    return cards

# ============================================================================
# ABERRATION CARDS (5 cards)
# ============================================================================

def create_aberration_cards():
    cards = []
    
    # 1. Fold Space - Position swap
    cards.append(create_card("Aberration", "Fold Space",
        card_type="Special",
        attention_cost=3,
        keywords='["Void"]',
        special_effect="Swap positions with any summon",
        description="Special: Swap positions with summon."))
    
    # 2. Glitch Step - Movement
    cards.append(create_card("Aberration", "Glitch Step",
        card_type="Special",
        attention_cost=1,
        keywords='["Glitch"]',
        special_effect="Move 3 hexes, ignore terrain",
        description="Special: Move 3 hexes, ignore terrain."))
    
    # 3. Recursive Strike - Conditional double attack
    cards.append(create_card("Aberration", "Recursive Strike",
        card_type="Attack",
        attention_cost=4,
        damage_dice="2d6",
        keywords='["Glitch"]',
        special_effect="If Attention >10: attack again for 1d6",
        requires_condition="Attention > 10",
        description="Attack: 2d6, if Attention >10 attack again."))
    
    # 4. Void Touch - Uncounterable attack
    cards.append(create_card("Aberration", "Void Touch",
        card_type="Attack",
        attention_cost=3,
        damage_dice="2d6",
        keywords='["Void"]',
        special_effect="Cannot be countered",
        description="Attack: Void - cannot be countered."))
    
    # 5. System Error - Random double-cast
    cards.append(create_card("Aberration", "System Error",
        card_type="Special",
        attention_cost=2,
        keywords='["Glitch"]',
        special_effect="Glitch: Chance to double-cast next card",
        description="Special: Glitch chance to double-cast."))
    
    return cards

# ============================================================================
# FACTION DECK RANDOMIZER
# ============================================================================

RANDOMIZER_SCRIPT = '''extends Node
class_name FactionDeckRandomizer

## Faction Deck Randomizer for Acanous Card Battler
## Selects 10 random faction cards from all 6 factions
## Player deck = 20 Universal cards + 10 random Faction cards

# Faction card pools - 5 cards per faction
const FACTION_CARDS = {
    "Construct": [
        "res://finished_cards/Construct/Construct_gear_shield.tres",
        "res://finished_cards/Construct/Construct_assembly_line.tres",
        "res://finished_cards/Construct/Construct_optimize.tres",
        "res://finished_cards/Construct/Construct_calibrate.tres",
        "res://finished_cards/Construct/Construct_overclock.tres"
    ],
    "Goblin": [
        "res://finished_cards/Goblin/Goblin_shank.tres",
        "res://finished_cards/Goblin/Goblin_sharp_stick.tres",
        "res://finished_cards/Goblin/Goblin_quick_strike.tres",
        "res://finished_cards/Goblin/Goblin_swarm_tactics.tres",
        "res://finished_cards/Goblin/Goblin_backstab.tres"
    ],
    "Undead": [
        "res://finished_cards/Undead/Undead_bone_shield.tres",
        "res://finished_cards/Undead/Undead_death_grip.tres",
        "res://finished_cards/Undead/Undead_grasping_hands.tres",
        "res://finished_cards/Undead/Undead_unnatural_persistence.tres",
        "res://finished_cards/Undead/Undead_grave_chill.tres"
    ],
    "Elemental": [
        "res://finished_cards/Elemental/Elemental_flash_flood.tres",
        "res://finished_cards/Elemental/Elemental_ember_core.tres",
        "res://finished_cards/Elemental/Elemental_tidal_surge.tres",
        "res://finished_cards/Elemental/Elemental_flow_state.tres",
        "res://finished_cards/Elemental/Elemental_nature's_blessing.tres"
    ],
    "Demon": [
        "res://finished_cards/Demon/Demon_painforged.tres",
        "res://finished_cards/Demon/Demon_hellchain.tres",
        "res://finished_cards/Demon/Demon_torment.tres",
        "res://finished_cards/Demon/Demon_dark_pact.tres",
        "res://finished_cards/Demon/Demon_corrupting_touch.tres"
    ],
    "Aberration": [
        "res://finished_cards/Aberration/Aberration_fold_space.tres",
        "res://finished_cards/Aberration/Aberration_glitch_step.tres",
        "res://finished_cards/Aberration/Aberration_recursive_strike.tres",
        "res://finished_cards/Aberration/Aberration_void_touch.tres",
        "res://finished_cards/Aberration/Aberration_system_error.tres"
    ]
}

# Universal base cards (always included)
const UNIVERSAL_CARDS = [
    "res://finished_cards/Universal/Universal_strike.tres",
    "res://finished_cards/Universal/Universal_defend.tres",
    "res://finished_cards/Universal/Universal_focus.tres",
    "res://finished_cards/Universal/Universal_gambit.tres",
    "res://finished_cards/Universal/Universal_recover.tres",
    "res://finished_cards/Universal/Universal_quick_step.tres",
    "res://finished_cards/Universal/Universal_second_wind.tres",
    "res://finished_cards/Universal/Universal_hoard_instinct.tres",
    "res://finished_cards/Universal/Universal_feint.tres",
    "res://finished_cards/Universal/Universal_brace.tres",
    "res://finished_cards/Universal/Universal_exploit.tres",
    "res://finished_cards/Universal/Universal_tread_lightly.tres",
    "res://finished_cards/Universal/Universal_desperate_lunge.tres",
    "res://finished_cards/Universal/Universal_catch_breath.tres",
    "res://finished_cards/Universal/Universal_study.tres",
    "res://finished_cards/Universal/Universal_throw_voice.tres",
    "res://finished_cards/Universal/Universal_blinding_dust.tres",
    "res://finished_cards/Universal/Universal_leverage.tres",
    "res://finished_cards/Universal/Universal_deep_breath.tres",
    "res://finished_cards/Universal/Universal_overextend.tres"
]

const FACTION_CARD_COUNT := 10
const UNIVERSAL_CARD_COUNT := 20

## Generates a complete player deck
## Returns array of CardData resource paths
func generate_player_deck() -> Array[String]:
    var deck: Array[String] = []
    
    # Add all 20 Universal cards
    deck.append_array(UNIVERSAL_CARDS)
    
    # Add 10 random faction cards
    var faction_cards = select_random_faction_cards(FACTION_CARD_COUNT)
    deck.append_array(faction_cards)
    
    return deck

## Selects N random cards from all faction pools
func select_random_faction_cards(count: int) -> Array[String]:
    var all_faction_cards: Array[String] = []
    
    # Collect all faction cards into one pool
    for faction in FACTION_CARDS.keys():
        all_faction_cards.append_array(FACTION_CARDS[faction])
    
    # Shuffle and select
    all_faction_cards.shuffle()
    
    var selected: Array[String] = []
    for i in range(min(count, all_faction_cards.size())):
        selected.append(all_faction_cards[i])
    
    return selected

## Selects cards from specific factions only
func select_from_factions(factions: Array[String], count: int) -> Array[String]:
    var pool: Array[String] = []
    
    for faction in factions:
        if FACTION_CARDS.has(faction):
            pool.append_array(FACTION_CARDS[faction])
    
    pool.shuffle()
    
    var selected: Array[String] = []
    for i in range(min(count, pool.size())):
        selected.append(pool[i])
    
    return selected

## Gets weighted random selection (favoring certain factions)
func select_weighted_faction_cards(faction_weights: Dictionary, count: int) -> Array[String]:
    var weighted_pool: Array[String] = []
    
    for faction in faction_weights.keys():
        if FACTION_CARDS.has(faction):
            var weight = faction_weights[faction]
            for card_path in FACTION_CARDS[faction]:
                # Add card multiple times based on weight
                for w in range(weight):
                    weighted_pool.append(card_path)
    
    weighted_pool.shuffle()
    
    var selected: Array[String] = []
    var used_cards = {}
    
    for card_path in weighted_pool:
        if selected.size() >= count:
            break
        if not used_cards.has(card_path):
            selected.append(card_path)
            used_cards[card_path] = true
    
    return selected

## Loads CardData resources from paths
func load_card_data(card_paths: Array[String]) -> Array[CardData]:
    var cards: Array[CardData] = []
    
    for path in card_paths:
        var card = load(path) as CardData
        if card:
            cards.append(card)
        else:
            push_warning("Failed to load card: " + path)
    
    return cards

## Debug: Print deck composition
func print_deck_composition(deck: Array[String]):
    print("=== DECK COMPOSITION ===")
    print("Total cards: " + str(deck.size()))
    
    var universal_count = 0
    var faction_counts = {}
    
    for path in deck:
        if "Universal" in path:
            universal_count += 1
        else:
            for faction in FACTION_CARDS.keys():
                if faction in path:
                    faction_counts[faction] = faction_counts.get(faction, 0) + 1
                    break
    
    print("Universal cards: " + str(universal_count))
    for faction in faction_counts.keys():
        print(faction + " cards: " + str(faction_counts[faction]))
'''

def create_randomizer():
    """Create the FactionDeckRandomizer.gd script"""
    filepath = os.path.join(BASE_PATH, "FactionDeckRandomizer.gd")
    with open(filepath, 'w') as f:
        f.write(RANDOMIZER_SCRIPT)
    return filepath

# ============================================================================
# MAIN EXECUTION
# ============================================================================

def main():
    print("=" * 60)
    print("ACANOUS CARD BATTLER - CARD GENERATOR")
    print("=" * 60)
    
    all_cards = []
    
    # Generate Universal cards
    print("\n[1/7] Generating Universal cards...")
    universal = create_universal_cards()
    all_cards.extend(universal)
    print(f"    Created {len(universal)} Universal cards")
    
    # Generate Construct cards
    print("\n[2/7] Generating Construct cards...")
    construct = create_construct_cards()
    all_cards.extend(construct)
    print(f"    Created {len(construct)} Construct cards")
    
    # Generate Goblin cards
    print("\n[3/7] Generating Goblin cards...")
    goblin = create_goblin_cards()
    all_cards.extend(goblin)
    print(f"    Created {len(goblin)} Goblin cards")
    
    # Generate Undead cards
    print("\n[4/7] Generating Undead cards...")
    undead = create_undead_cards()
    all_cards.extend(undead)
    print(f"    Created {len(undead)} Undead cards")
    
    # Generate Elemental cards
    print("\n[5/7] Generating Elemental cards...")
    elemental = create_elemental_cards()
    all_cards.extend(elemental)
    print(f"    Created {len(elemental)} Elemental cards")
    
    # Generate Demon cards
    print("\n[6/7] Generating Demon cards...")
    demon = create_demon_cards()
    all_cards.extend(demon)
    print(f"    Created {len(demon)} Demon cards")
    
    # Generate Aberration cards
    print("\n[7/7] Generating Aberration cards...")
    aberration = create_aberration_cards()
    all_cards.extend(aberration)
    print(f"    Created {len(aberration)} Aberration cards")
    
    # Create randomizer
    print("\n[8/8] Creating FactionDeckRandomizer.gd...")
    randomizer_path = create_randomizer()
    print(f"    Created: {randomizer_path}")
    
    # Summary
    print("\n" + "=" * 60)
    print("GENERATION COMPLETE")
    print("=" * 60)
    print(f"\nTotal cards created: {len(all_cards)}")
    print("  - Universal: 20")
    print("  - Construct: 5")
    print("  - Goblin: 5")
    print("  - Undead: 5")
    print("  - Elemental: 5")
    print("  - Demon: 5")
    print("  - Aberration: 5")
    print("\nFactionDeckRandomizer.gd created with:")
    print("  - 20 Universal base cards")
    print("  - 30 Faction cards (5 per faction)")
    print("  - Random selection of 10 faction cards for player deck")
    
    return all_cards

if __name__ == "__main__":
    main()
