extends Node

# CardDB - Loads all cards from finished_cards/ directory (Autoload Singleton)

var cards: Dictionary = {}  # id -> CardData
var starter_deck: Array[String] = []

const FACTIONS = ["Aberration", "Construct", "Demon", "Dragon", "Elemental", "Goblin", "Undead", "Universal"]

func _ready():
	_load_all_cards()
	_setup_starter_deck()
	print("CardDB: Loaded %d cards" % cards.size())

func get_card(id: String) -> CardData:
	var card = cards.get(id)
	if card:
		_ensure_card_flags(card)
	return card

func _ensure_card_flags(card: CardData):
	"""Auto-mark Dragon cards as survivors. All other cards must be manually chosen by player."""
	if card.survives_reset:
		return
	
	# Dragon faction cards always survive
	if card.faction == "Dragon":
		card.survives_reset = true

func mark_card_survivor(card_id: String):
	"""Mark a card as surviving resets (for player choice at end of run)."""
	var card = get_card(card_id)
	if card:
		card.survives_reset = true

func register_card(new_card: CardData) -> bool:
	"""Register a dynamically created card (e.g., fused overlay cards).
	Returns true if registered, false if ID already exists."""
	if not new_card or new_card.id.is_empty():
		push_warning("CardDB: Cannot register card with empty ID")
		return false
	if cards.has(new_card.id):
		push_warning("CardDB: Card '%s' already exists, skipping registration" % new_card.id)
		return false
	
	_ensure_card_flags(new_card)
	cards[new_card.id] = new_card
	print("CardDB: Registered fused card '%s' (%s %s)" % [new_card.id, new_card.faction, new_card.card_type])
	return true

func is_card_survivor(card_id: String) -> bool:
	"""Check if a card survives resets."""
	var card = get_card(card_id)
	if card:
		return card.survives_reset
	return false

func get_cards_by_faction(faction: String) -> Array[CardData]:
	var result: Array[CardData] = []
	for card in cards.values():
		if card.faction == faction:
			result.append(card)
	return result

func get_cards_by_type(card_type: String) -> Array[CardData]:
	var result: Array[CardData] = []
	for card in cards.values():
		if card.card_type == card_type:
			result.append(card)
	return result

# Starter deck composition
const STARTER_DECK_CONFIG: Dictionary = {
	"damage": [
		"Goblin_desperate_strike",    # 0-cost, 2d4 dmg
		"Goblin_shiv",                # 1-cost, flat 3 dmg
		"Goblin_quick_strike",        # 1-cost, 1d4 dmg
		"Undead_bone_spike"           # 2-cost, 1d6 dmg
	],
	"defense": [
		"Construct_efficient_block",  # 1-cost, 3 shield
		"Goblin_nimble_dodge",        # 2-cost, 4 shield
		"Undead_bone_shield",         # 2-cost, 5 shield
		"Universal_fortify"           # 2-cost, 5 shield
	],
	"healing": [
		"Universal_stabilize",        # 2-cost, heal 5
		"Universal_cleanse"           # 2-cost, heal 3 + remove debuffs
	],
	"traps": [
		"Construct_gear_shield",        # 1-cost trap
		"Goblin_tripwire"             # 2-cost trap
	],
	"summons": [
		"Construct_clockwork_tick",   # 2-cost, 2x 1/1 ticks
		"Demon_imp"                   # 2-cost, 1x 2/2 imp
	]
}

func get_starter_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	for id in starter_deck:
		var card = get_card(id)
		if card:
			deck.append(card)
	return deck

func _get_or_create_basic_card(faction: String, card_type: String) -> CardData:
	# Find a matching card or create a basic one
	for card in cards.values():
		if card.faction == faction and card.card_type == card_type:
			return card
	
	# Create basic fallback
	var card = CardData.new()
	card.id = "basic_%s_%s" % [faction.to_lower(), card_type.to_lower()]
	card.card_name = "%s %s" % [faction, card_type]
	card.faction = faction
	card.card_type = card_type
	card.attention_cost = 1
	
	if card_type == "Attack":
		card.damage_flat = 10
		card.description = "Deal 10 damage. (TEST CARD - not for final gameplay)"
	elif card_type == "Defense":
		card.shield_amount = 5
		card.description = "Gain 5 shield."
	else:
		card.damage_flat = 10
		card.description = "Deal 10 damage. (TEST CARD - not for final gameplay)"
	
	return card

func _load_all_cards():
	"""Load all .tres card files from finished_cards/"""
	var dir = DirAccess.open("res://finished_cards")
	if not dir:
		print("CardDB: Warning - could not open finished_cards/ directory")
		return
	
	dir.list_dir_begin()
	var folder = dir.get_next()
	
	while folder != "":
		if dir.current_is_dir() and not folder.begins_with("."):
			_load_cards_from_folder("res://finished_cards/" + folder)
		folder = dir.get_next()
	
	dir.list_dir_end()

func _load_cards_from_folder(path: String):
	var dir = DirAccess.open(path)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file = dir.get_next()
	
	while file != "":
		if dir.current_is_dir() and not file.begins_with("."):
			# Recurse into subdirectories (e.g., Overlays/Arcane, Overlays/Divine, etc.)
			_load_cards_from_folder(path + "/" + file)
		elif file.ends_with(".tres") and not file.begins_with("."):
			var full_path = path + "/" + file
			_load_card_resource(full_path)
		file = dir.get_next()
	
	dir.list_dir_end()

func _load_card_resource(path: String):
	var card = load(path)
	if card and card is CardData:
		var id = path.get_file().get_basename()
		card.id = id
		_ensure_card_flags(card)
		cards[id] = card
	else:
		print("CardDB: Failed to load %s" % path)

func _setup_starter_deck():
	"""Build starter deck from explicit config + 6 random universal cards."""
	starter_deck.clear()
	
	# Add fixed cards by category
	for category in ["damage", "defense", "healing", "traps", "summons"]:
		for card_id in STARTER_DECK_CONFIG[category]:
			if card_id in cards and not starter_deck.has(card_id):
				starter_deck.append(card_id)
			else:
				print("CardDB: Starter card '%s' not found, skipping" % card_id)
	
	# Add 6 random universal cards (from available universal cards)
	var universal_cards: Array[String] = []
	for card in cards.values():
		if card.faction == "Universal" and not starter_deck.has(card.id):
			universal_cards.append(card.id)
	
	universal_cards.shuffle()
	var random_count = min(6, universal_cards.size())
	for i in range(random_count):
		starter_deck.append(universal_cards[i])
	
	print("CardDB: Starter deck built with %d cards" % starter_deck.size())
	for id in starter_deck:
		var card = cards[id]
		print("  - %s (%s %s, cost: %d)" % [id, card.faction, card.card_type, card.attention_cost])
