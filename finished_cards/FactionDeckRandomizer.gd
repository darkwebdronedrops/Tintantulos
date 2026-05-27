extends Node
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
