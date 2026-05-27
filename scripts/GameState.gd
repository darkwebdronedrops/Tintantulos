extends Node

# GameState - Persistent game state (Autoload Singleton)

# Signals (for cross-system communication)
signal hp_changed(new_hp: int, max_hp: int, delta: int)
signal gems_changed(new_amount: int)
signal offerings_changed()
signal quiddity_changed(new_amount: int)
signal deck_changed()
signal player_died()  # Emitted when HP reaches 0

# Transit Tokens (Floor 1)
static var transit_tokens: Array[String] = []  # Collected tokens: "North Pass", "East Pass", "South Pass", "West Pass"
static var is_first_run: bool = true  # First time playing Floor 1
static var door_tutorial_completed: bool = false  # The Door tutorial done

# Floor 1 progress
static var floor1_rooms_cleared: Array[String] = []  # Room IDs cleared
static var shortcut_maker_status: String = "none"  # "none", "befriended", "killed", "declined"
static var shortcut_maker_pact_taken: bool = false

# Floor 5 progress
static var floor5_valves_turned: Dictionary = {"breeze": false, "boiler": false, "gale": false}
static var floor5_all_moorings_unlocked: bool = false
static var floor5_cargo_discovered: bool = false
static var floor5_charge_state: Dictionary = {"wind": 0, "steam": 0, "lightning": 0, "aether": 0}

# Floor 6 progress — The Lunar University
static var floor6_courses: Array = []  # Assigned course types
static var floor6_grades: Dictionary = {}  # course_id -> grade
static var floor6_clocktower_sabotaged: bool = false
static var floor6_master_key: bool = false
static var floor6_deans_key: bool = false
static var floor6_graduate_status: String = ""  # "" | "audit" | "graduate"
static var floor6_books_read: int = 0
static var floor6_goblin_janitor_befriended: bool = false
static var floor6_failed_courses: bool = false
static var floor6_audit_status: String = ""  # "" | "audit" | "graduate"

# Floor progression (which floor the player has reached)
# Floor 7 progress — The Broken Pact
static var floor7_signed_pacts: Array[Dictionary] = []  # Each pact: {type, cost, effect}
static var floor7_void_cracks_stabilized: int = 0
static var floor7_docket_weight: int = 0
static var floor7_final_pact_signed: bool = false
static var floor7_goblin_forger_used: bool = false

# Floor 8 progress — The Overclock Forge
static var floor8_overclock_meter: int = 0
static var floor8_elemental_charge: Dictionary = {"fire": 0, "water": 0, "earth": 0, "air": 0}
static var floor8_vessels_vented: int = 0
static var floor8_vessels_overclocked: int = 0
static var floor8_padlocks_opened: int = 0
static var floor8_blix_surrendered: bool = false
static var floor8_scram_pulled: bool = false

# Floor 9 progress — The Bone Forges
static var floor9_bone_count: int = 0
static var floor9_gear_count: int = 0
static var floor9_souls_freed: int = 0
static var floor9_soul_debt: int = 0
static var floor9_liberator_status: bool = false
static var floor9_companions_built: int = 0

# Floor 10 progress — The Dragon's Lair
static var floor10_choices_made: Dictionary = {}  # All cross-floor choices tracked
static var floor10_ghosts_spoken: Array = []  # Which ghost bosses were spoken to
static var floor10_hoard_touched: Array = []  # Which hoard objects were touched
static var floor10_aspects_defeated: int = 0  # Count of aspects defeated
static var floor10_final_choice: String = ""  # "destroy"/"become"/"walk"/"true"
static var floor10_true_ending_unlocked: bool = false

# Meta-progression
static var dragon_deck_archive: Array[String] = []  # Cards that survive across NG+ runs

static var ng_plus_unlocked: bool = false
static var exile_mode_unlocked: bool = false
static var cano_defeated: bool = false
static var true_ending_achieved: bool = false
static var true_ending_locked: bool = false
static var text_speed: float = 1.0  # 0.1 - 2.0 multiplier for text display speed
static var become_ending_chosen: bool = false
static var false_ending_seen: bool = false
static var run_count: int = 1
static var dragon_deck_archive_size: int = 0
static var dragon_variant: String = ""  # Red/Black/Gold — set randomly per run, persists across saves

static var current_floor: int = 1  # 1-10
static var highest_floor_reached: int = 1

# Floor 2 progress — The Fungal Cavern
static var floor2_elevator_repaired: bool = false
static var floor2_spore_state: String = "balance"
static var floor2_pool_effect: int = 0  # Positive = heal per turn, negative = toxic damage per turn
static var floor2_spore_damage: int = 0  # Damage per turn from spore clouds
static var floor2_gears_collected: int = 0
static var floor2_boss_defeated: bool = false
static var cleared_rooms: Array[int] = []
static var defeated_bosses: Array[String] = []
static var dial_position: int = 0
static var crown_cog_unlocked: bool = false

# Floor 4 progress
static var floor4_booths_cleared: Array[String] = []  # Booth IDs cleared (legacy — main only)
static var floor4_booths_cleared_main: Array[String] = []
static var floor4_booths_cleared_undercroft: Array[String] = []
static var floor4_booths_cleared_refectory: Array[String] = []
static var floor4_levels_unlocked: Array[String] = ["main"]
static var floor4_current_level: String = "main"
static var floor4_lifter_repaired: bool = false
static var floor4_collected_parts: Array[String] = []  # Gear parts for Great Lifter
static var player_hp: int = 50
static var player_max_hp: int = 50

# Deck & Quiddity (Combat Economy)
static var player_deck: Array[String] = []  # Persistent deck (card IDs)
static var player_quiddity: int = 0  # Combat currency — spend after combat

# Save/Load suffix (for multiple save slots)
static var save_suffix: String = ""

# --- No Aggro State (post-flee grace period) ---
static var no_aggro_timer: float = 0.0

static func activate_no_aggro(duration: float):
	"""Activate No Aggro state for duration seconds. Enemies won't trigger combat."""
	no_aggro_timer = duration
	print("GameState: No Aggro activated for %.1f seconds" % duration)

static func is_no_aggro() -> bool:
	"""Check if No Aggro is currently active."""
	return no_aggro_timer > 0.0

static func tick_no_aggro(delta: float):
	"""Decrement No Aggro timer. Call from _process or _physics_process."""
	if no_aggro_timer > 0:
		no_aggro_timer -= delta
		if no_aggro_timer <= 0:
			no_aggro_timer = 0
			print("GameState: No Aggro expired — enemies can trigger combat again")

func _process(delta):
	tick_no_aggro(delta)

static var deck_max_size: int = 50

# Offerings & Economy
static var gear_devil_tokens: Array[int] = []  # Room IDs where tokens collected
static var inventory_offerings: Array[String] = []  # Carried offering items (max 10)
static var gems: int = 0
static var temp_effects: Dictionary = {}  # effect_name -> duration (in encounters/rooms)

# Equipment System
static var equipped_weapon: String = ""  # Weapon ID
static var equipped_armor: String = ""   # Armor ID
static var equipped_shield: String = ""  # Shield ID
static var equipped_trinket: String = "" # Trinket ID

# Equipment Inventory (found but not equipped)
static var inventory_weapons: Array[String] = []
static var inventory_armor: Array[String] = []
static var inventory_shields: Array[String] = []
static var inventory_trinkets: Array[String] = []

# Offering Item Database
static var OFFERING_DATABASE: Dictionary = {
	"machine_oil": {
		"name": "Machine Oil",
		"description": "Thick lubricant distilled from gear runoff. Smells of copper and regret.",
		"quality": 1,
		"gem_value": 2,
		"sprite": "res://assets/sprites/puzzles/puzzle_bearing_oilcan.png",
		"tags": ["lubricant", "mechanical"]
	},
	"polished_brass": {
		"name": "Polished Brass",
		"description": "A gleaming fitting from some forgotten engine. Still warm to the touch.",
		"quality": 2,
		"gem_value": 5,
		"sprite": "res://assets/sprites/puzzles/puzzle_governor_gears.png",
		"tags": ["metal", "shiny"]
	},
	"interesting_trash": {
		"name": "Interesting Trash",
		"description": "You don't know what it is, but it looks important. Might be a gasket. Might be a tooth.",
		"quality": 0,
		"gem_value": 1,
		"sprite": "res://assets/sprites/puzzles/puzzle_weights.png",
		"tags": ["trash", "unknown"]
	},
	"sacred_gasket": {
		"name": "Sacred Gasket",
		"description": "A ring of woven metal fibers, blessed by the Gear Mother's priests. Seals what should not leak.",
		"quality": 3,
		"gem_value": 12,
		"sprite": "res://assets/sprites/puzzles/puzzle_oiler_nozzle.png",
		"tags": ["sacred", "seal"]
	},
	"phosphor_crystal": {
		"name": "Phosphor Crystal",
		"description": "Glows faintly in the dark. The Gearworkers use them to see in the deep shafts.",
		"quality": 3,
		"gem_value": 8,
		"sprite": "res://assets/sprites/puzzles/puzzle_beacon_peak.png",
		"tags": ["light", "crystal"]
	},
	"gear_devil_token": {
		"name": "Gear Devil Token",
		"description": "A cog-shaped coin stamped with an infernal seal. The Gear Devil's currency.",
		"quality": 5,
		"gem_value": 50,
		"sprite": "res://assets/sprites/puzzles/puzzle_governor_gears.png",
		"tags": ["token", "devil", "epic"]
	},
	"flame_essence": {
		"name": "Flame Essence",
		"description": "A vial of liquid fire. Warm even through the glass. Never goes out.",
		"quality": 2,
		"gem_value": 6,
		"sprite": "res://assets/sprites/puzzles/kami_heat.png",
		"tags": ["fire", "heat"]
	},
	"charcoal": {
		"name": "Compressed Charcoal",
		"description": "Dense fuel blocks from the deep forges. Burns slow and hot.",
		"quality": 1,
		"gem_value": 3,
		"sprite": "res://assets/sprites/puzzles/puzzle_spark_furnace.png",
		"tags": ["fuel", "heat"]
	},
	"precision_tools": {
		"name": "Precision Tools",
		"description": "Calipers, gauges, and a tiny hammer. For the mechanic who measures twice.",
		"quality": 2,
		"gem_value": 7,
		"sprite": "res://assets/sprites/puzzles/puzzle_escapement_switch.png",
		"tags": ["tools", "precision"]
	},
	"coolant_water": {
		"name": "Coolant Water",
		"description": "Icy runoff from the Quench channels. Smells of minerals and cold metal.",
		"quality": 1,
		"gem_value": 3,
		"sprite": "res://assets/sprites/puzzles/puzzle_quench_tank.png",
		"tags": ["water", "cooling"]
	}
}

# Helper for safe property access with defaults
func get_value(key: String, default_value = null):
	var val = get(key)
	if val == null:
		return default_value
	return val


static var KAMI_DATABASE: Dictionary = {
	"water_kami": {
		"name": "Desperate Water Kami",
		"preferred": ["coolant_water", "machine_oil"],
		"accepts_any": true,
		"sprite": "res://assets/sprites/puzzles/kami_water.png",
		"minor_boon": "cooling_blessing",
		"major_boon": "flood_ward",
		"epic_boon": "tidal_surge",
		"dialogue_greet": "*drip* ... *drip* ... so thirsty...",
		"dialogue_accept": "*gurgle* Yes... yes! Water... thank you...",
		"dialogue_reject": "*sputter* That... that is not water..."
	},
	"heat_kami": {
		"name": "Heat Kami",
		"preferred": ["flame_essence", "charcoal"],
		"accepts_any": false,
		"sprite": "res://assets/sprites/puzzles/kami_heat.png",
		"minor_boon": "warmth_blessing",
		"major_boon": "forge_ward",
		"epic_boon": "infernal_flame",
		"dialogue_greet": "*crackle* The furnace hungers. Feed it.",
		"dialogue_accept": "*roar* YES! More heat! More FIRE!",
		"dialogue_reject": "*hiss* Cold... useless... cold..."
	},
	"maintenance_kami": {
		"name": "Maintenance Kami",
		"preferred": ["machine_oil", "polished_brass"],
		"accepts_any": false,
		"sprite": "res://assets/sprites/puzzles/kami_maintenance.png",
		"minor_boon": "grease_blessing",
		"major_boon": "repair_ward",
		"epic_boon": "perfect_maintenance",
		"dialogue_greet": "*whir* Lubrication levels... critical.",
		"dialogue_accept": "*click* Smooth. Precise. Acceptable.",
		"dialogue_reject": "*grind* Wrong viscosity. Unacceptable."
	},
	"regulation_kami": {
		"name": "Regulation Kami",
		"preferred": ["precision_tools", "machine_oil"],
		"accepts_any": false,
		"sprite": "res://assets/sprites/puzzles/kami_regulation.png",
		"minor_boon": "calibration_blessing",
		"major_boon": "balance_ward",
		"epic_boon": "perfect_harmony",
		"dialogue_greet": "*tick* Parameters... drifting. Adjust.",
		"dialogue_accept": "*tick-tick* Within tolerance. Good.",
		"dialogue_reject": "*buzz* OUT OF SPEC. Rejected."
	},
	"steam_kami": {
		"name": "Steam Kami",
		"preferred": ["coolant_water", "charcoal", "machine_oil"],
		"accepts_any": false,
		"sprite": "res://assets/sprites/puzzles/kami_steam.png",
		"minor_boon": "pressure_blessing",
		"major_boon": "steam_ward",
		"epic_boon": "torrent_force",
		"dialogue_greet": "*hiss* The pipes sing... pressure builds...",
		"dialogue_accept": "*whistle* YES! Steam rises! Power flows!",
		"dialogue_reject": "*sputter* Damp... useless... damp..."
	},
	"heat_treatment_kami": {
		"name": "Heat Treatment Kami",
		"preferred": ["sacred_gasket", "phosphor_crystal", "charcoal"],
		"accepts_any": false,
		"sprite": "res://assets/sprites/puzzles/kami_heat_treatment.png",
		"minor_boon": "heat_resist_blessing",
		"major_boon": "forge_ward",
		"epic_boon": "infernal_flame",
		"dialogue_greet": "*crackle* The metal remembers the fire...",
		"dialogue_accept": "*hiss* Tempered. Perfect. Unbreakable.",
		"dialogue_reject": "*sputter* Wrong alloy. Would shatter."
	},
	"light_kami": {
		"name": "Light Kami",
		"preferred": ["phosphor_crystal", "polished_brass"],
		"accepts_any": false,
		"sprite": "res://assets/sprites/puzzles/kami_light.png",
		"minor_boon": "light_blessing",
		"major_boon": "radiance_ward",
		"epic_boon": "solar_flare",
		"dialogue_greet": "*hum* The beam calls. Climb to it.",
		"dialogue_accept": "*shine* YES! Brilliant! Blinding!",
		"dialogue_reject": "*dim* Dark... weak... dark..."
	},
	"time_kami": {
		"name": "Time Kami",
		"preferred": ["precision_tools", "polished_brass", "sacred_gasket"],
		"accepts_any": false,
		"sprite": "res://assets/sprites/puzzles/kami_time.png",
		"minor_boon": "timing_blessing",
		"major_boon": "temporal_ward",
		"epic_boon": "perfect_timing",
		"dialogue_greet": "*tick* The beat is off. Fix it.",
		"dialogue_accept": "*tick-tock* Precision. Excellent.",
		"dialogue_reject": "*grind* Off-beat. Unacceptable."
	},
	"friction_kami": {
		"name": "Friction Kami",
		"preferred": ["machine_oil", "polished_brass"],
		"accepts_any": false,
		"sprite": "res://assets/sprites/puzzles/kami_friction.png",
		"minor_boon": "lubrication_blessing",
		"major_boon": "smooth_ward",
		"epic_boon": "perfect_flow",
		"dialogue_greet": "*screech* The metal... it screams...",
		"dialogue_accept": "*swoosh* Silence. Smooth. Perfect.",
		"dialogue_reject": "*grind* Rough. Wrong. Rough."
	},
	"momentum_kami": {
		"name": "Momentum Kami",
		"preferred": ["polished_brass", "machine_oil", "interesting_trash"],
		"accepts_any": false,
		"sprite": "res://assets/sprites/puzzles/kami_momentum.png",
		"minor_boon": "speed_blessing",
		"major_boon": "momentum_ward",
		"epic_boon": "unstoppable_force",
		"dialogue_greet": "*whir* The wheel hungers. Push it.",
		"dialogue_accept": "*roar* SPIN! FASTER! MORE!",
		"dialogue_reject": "*clunk* Stuck. Useless. Stuck."
	},
	"balance_kami": {
		"name": "Balance Kami",
		"preferred": ["precision_tools", "sacred_gasket", "polished_brass"],
		"accepts_any": false,
		"sprite": "res://assets/sprites/puzzles/kami_balance.png",
		"minor_boon": "equilibrium_blessing",
		"major_boon": "stability_ward",
		"epic_boon": "perfect_balance",
		"dialogue_greet": "*creak* The scale tips... restore it.",
		"dialogue_accept": "*click* Perfect. Equal. Still.",
		"dialogue_reject": "*clunk* Unbalanced. Unacceptable."
	}
}

# Boon Effects Database
static var BOON_DATABASE: Dictionary = {
	"cooling_blessing": {
		"name": "Cooling Blessing",
		"description": "Take 2 less damage from heat sources",
		"duration": 3,
		"effect": "heat_resist_2"
	},
	"flood_ward": {
		"name": "Flood Ward",
		"description": "Immune to steam/pressure traps",
		"duration": 5,
		"effect": "pressure_immunity"
	},
	"warmth_blessing": {
		"name": "Warmth Blessing",
		"description": "Deal +2 damage with fire cards",
		"duration": 3,
		"effect": "fire_damage_2"
	},
	"forge_ward": {
		"name": "Forge Ward",
		"description": "Immune to backfire damage",
		"duration": 5,
		"effect": "backfire_immunity"
	},
	"grease_blessing": {
		"name": "Grease Blessing",
		"description": "Movement speed +20% in puzzles",
		"duration": 3,
		"effect": "speed_boost"
	},
	"calibration_blessing": {
		"name": "Calibration Blessing",
		"description": "Gauges show exact values (no guesswork)",
		"duration": 3,
		"effect": "precise_gauges"
	}
}

# Kami boon tracking
static var boons_active: Dictionary = {}  # boon_name -> turns_remaining

func _ready():
	print("GameState: Initialized")
	load_game()
	
	# Fallback: if no deck loaded (first run or failed load), build starter deck
	# We defer this because CardDB may not be initialized yet when _ready() runs
	if player_deck.is_empty():
		call_deferred("_build_starter_deck_if_needed")

static func _build_starter_deck_if_needed():
	if player_deck.size() > 0:
		return
	if CardDB.starter_deck.size() > 0:
		print("GameState: No deck found — building starter deck")
		for starter_id in CardDB.starter_deck:
			if starter_id not in player_deck:
				player_deck.append(starter_id)
		print("GameState: Starter deck built with %d cards" % player_deck.size())
	else:
		print("GameState: No deck and CardDB.starter_deck is empty — deck remains empty!")

static func set_current_floor(floor_num: int):
	current_floor = floor_num
	if floor_num > highest_floor_reached:
		highest_floor_reached = floor_num
		print("GameState: New highest floor reached: %d" % floor_num)
	save_game()

static func add_transit_token(token_name: String):
	if token_name not in transit_tokens:
		transit_tokens.append(token_name)
		print("GameState: Transit token collected: %s" % token_name)
		save_game()

static func has_all_transit_tokens() -> bool:
	# Need East, South, West passes (North is tutorial, doesn't give token for unlock)
	var required = ["East Pass", "South Pass", "West Pass"]
	for token in required:
		if token not in transit_tokens:
			return false
	return true

static func is_room_cleared(room_id: int) -> bool:
	return room_id in cleared_rooms

static func clear_room(room_id: int):
	if not room_id in cleared_rooms:
		cleared_rooms.append(room_id)
		save_game()

static func reset_floor():
	cleared_rooms.clear()
	defeated_bosses.clear()
	dial_position = 0
	crown_cog_unlocked = false
	save_game()

static func add_gear_devil_token(room_id: int):
	if not room_id in gear_devil_tokens:
		gear_devil_tokens.append(room_id)
		save_game()

static func add_offering(item_id: String) -> bool:
	if inventory_offerings.size() >= 10:
		return false
	inventory_offerings.append(item_id)
	GameState.offerings_changed.emit()
	return true

static func remove_offering(item_id: String) -> bool:
	if item_id in inventory_offerings:
		inventory_offerings.erase(item_id)
		GameState.offerings_changed.emit()
		return true
	return false

func is_floor4_booth_cleared(booth_id: String, level: String = "main") -> bool:
	match level:
		"main": return booth_id in floor4_booths_cleared_main
		"undercroft": return booth_id in floor4_booths_cleared_undercroft
		"refectory": return booth_id in floor4_booths_cleared_refectory
		_: return booth_id in floor4_booths_cleared

func clear_floor4_booth(booth_id: String, level: String = "main"):
	match level:
		"main":
			if not booth_id in floor4_booths_cleared_main:
				floor4_booths_cleared_main.append(booth_id)
		"undercroft":
			if not booth_id in floor4_booths_cleared_undercroft:
				floor4_booths_cleared_undercroft.append(booth_id)
		"refectory":
			if not booth_id in floor4_booths_cleared_refectory:
				floor4_booths_cleared_refectory.append(booth_id)
		_:
			if not booth_id in floor4_booths_cleared:
				floor4_booths_cleared.append(booth_id)

func get_floor4_cleared_booths(level: String = "main") -> Array[String]:
	match level:
		"main": return floor4_booths_cleared_main
		"undercroft": return floor4_booths_cleared_undercroft
		"refectory": return floor4_booths_cleared_refectory
		_: return floor4_booths_cleared

func is_floor4_level_unlocked(level: String) -> bool:
	return level in floor4_levels_unlocked

func unlock_floor4_level(level: String):
	if level not in floor4_levels_unlocked:
		floor4_levels_unlocked.append(level)

static func set_floor4_current_level(level: String):
	floor4_current_level = level
	save_game()

static func collect_lifter_part(part_name: String):
	if not part_name in floor4_collected_parts:
		floor4_collected_parts.append(part_name)
		save_game()

static func has_lifter_part(part_name: String) -> bool:
	return part_name in floor4_collected_parts

static func repair_great_lifter():
	floor4_lifter_repaired = true
	save_game()

static func is_great_lifter_repaired() -> bool:
	return floor4_lifter_repaired

static func get_lifter_part_count() -> int:
	return floor4_collected_parts.size()

static func reset_floor4():
	floor4_booths_cleared.clear()
	floor4_booths_cleared_main.clear()
	floor4_booths_cleared_undercroft.clear()
	floor4_booths_cleared_refectory.clear()
	floor4_levels_unlocked = ["main"]
	floor4_current_level = "main"
	floor4_lifter_repaired = false
	floor4_collected_parts.clear()
	save_game()

func heal_player(amount: int):
	var old_hp = player_hp
	player_hp = min(player_hp + amount, player_max_hp)
	var delta = player_hp - old_hp
	if delta > 0:
		hp_changed.emit(player_hp, player_max_hp, delta)

func damage_player(amount: int):
	var old_hp = player_hp
	player_hp = max(player_hp - amount, 0)
	var delta = old_hp - player_hp
	if delta > 0:
		hp_changed.emit(player_hp, player_max_hp, -delta)
	if player_hp <= 0:
		player_died.emit()

static func add_temp_effect(effect_name: String, duration: int):
	temp_effects[effect_name] = duration

static func tick_temp_effects():
	"""Call after each room/encounter to decrement durations"""
	var expired = []
	for effect in temp_effects:
		temp_effects[effect] -= 1
		if temp_effects[effect] <= 0:
			expired.append(effect)
	for effect in expired:
		temp_effects.erase(effect)

static func has_temp_effect(effect_name: String) -> bool:
	return temp_effects.has(effect_name) and temp_effects[effect_name] > 0


# Equipment Database
static var WEAPON_DATABASE: Dictionary = {
	"goblin_shiv": {
		"name": "Goblin Shiv",
		"floor": 1,
		"charge": 2,
		"start_ready": true,
		"damage_min": 3,
		"damage_max": 6,
		"cost": 15,
		"desc": "A jagged blade that strikes fast. Ready to use immediately."
	},
	"gearwork_hammer": {
		"name": "Gearwork Hammer",
		"floor": 3,
		"charge": 3,
		"start_ready": false,
		"damage_min": 5,
		"damage_max": 10,
		"cost": 25,
		"desc": "Heavy and slow. Breaks shields. Needs time to wind up."
	},
	"aether_channel": {
		"name": "Aether Channel",
		"floor": 5,
		"charge": 4,
		"start_ready": true,
		"damage_min": 4,
		"damage_max": 8,
		"cost": 40,
		"desc": "Channels elemental force. Ignores block. Ready at start."
	},
	"pact_blade": {
		"name": "Pact Blade",
		"floor": 7,
		"charge": 5,
		"start_ready": false,
		"damage_min": 8,
		"damage_max": 15,
		"cost": 60,
		"desc": "Costs HP to swing. Heals if it kills. Dark power demands sacrifice."
	},
	"dragon_maw": {
		"name": "Dragon Maw",
		"floor": 9,
		"charge": 3,
		"start_ready": true,
		"damage_min": 6,
		"damage_max": 12,
		"cost": 80,
		"desc": "Strikes all enemies. Attention distributes the blow."
	}
}

static var ARMOR_DATABASE: Dictionary = {
	"goblin_scrap": {
		"name": "Goblin Scrap",
		"floor": 1,
		"hp_bonus": 5,
		"special": "+1 Quiddity per enemy kill",
		"cost": 10,
		"desc": "Stitched together from battlefield salvage."
	},
	"gearworks_plate": {
		"name": "Gearworks Plate",
		"floor": 3,
		"hp_bonus": 10,
		"special": "Ignore first trap damage per floor",
		"cost": 20,
		"desc": "Reinforced with clockwork joints."
	},
	"aether_weave": {
		"name": "Aether Weave",
		"floor": 5,
		"hp_bonus": 15,
		"special": "+1 card draw per turn",
		"cost": 35,
		"desc": "Woven from crystallized mana threads."
	},
	"pactbound_mail": {
		"name": "Pactbound Mail",
		"floor": 7,
		"hp_bonus": 20,
		"special": "50% resist first debuff per combat",
		"cost": 50,
		"desc": "Bound with infernal thread. Offers dark protection."
	},
	"dragonbone": {
		"name": "Dragonbone",
		"floor": 9,
		"hp_bonus": 30,
		"special": "Survive first lethal hit per combat",
		"cost": 75,
		"desc": "Scales harder than steel. Regrows when broken."
	}
}

static var SHIELD_DATABASE: Dictionary = {
	"rusty_targe": {
		"name": "Rusty Targe",
		"floor": 1,
		"type": "block",
		"block": 1,
		"cost": 8,
		"desc": "Old but serviceable. Blocks 1 damage."
	},
	"gearshield": {
		"name": "Gearshield",
		"floor": 3,
		"type": "retributive",
		"retributive": 2,
		"cost": 18,
		"desc": "Counter-rotating gears. Attacker takes 2 damage."
	},
	"aegis_bulwark": {
		"name": "Aegis Bulwark",
		"floor": 5,
		"type": "block",
		"block": 2,
		"cost": 30,
		"desc": "Blocks 2 damage. Ignores first elemental hit."
	},
	"pactward": {
		"name": "Pactward",
		"floor": 7,
		"type": "retributive",
		"retributive": 3,
		"cost": 45,
		"desc": "Dark mirror surface. Retributive + chance to debuff attacker."
	},
	"dragon_scale": {
		"name": "Dragon Scale",
		"floor": 9,
		"type": "hybrid",
		"block": 2,
		"retributive": 2,
		"cost": 60,
		"desc": "Once per combat: negate any single hit entirely."
	}
}

static var TRINKET_DATABASE: Dictionary = {
	"crystal_focus": {
		"name": "Crystal Focus",
		"faction": "Arcane",
		"cost": 20,
		"desc": "Spell cards cost 1 less Quiddity. Once per combat: free spell."
	},
	"blessed_relic": {
		"name": "Blessed Relic",
		"faction": "Divine",
		"cost": 20,
		"desc": "Healing +2. Once per floor: full heal outside combat."
	},
	"blood_chalice": {
		"name": "Blood Chalice",
		"faction": "Infernal",
		"cost": 20,
		"desc": "Lose 3 HP at combat start, gain 6 Quiddity."
	},
	"grasping_shroud": {
		"name": "Grasping Shroud",
		"faction": "Undead",
		"cost": 25,
		"desc": "Your deck IS your HP. Drawing costs HP. Reshuffle heals to full."
	},
	"assembly_core": {
		"name": "Assembly Core",
		"faction": "Construct",
		"cost": 20,
		"desc": "Start combat with free Assembly Drone summon."
	},
	"swarm_totem": {
		"name": "Swarm Totem",
		"faction": "Goblin",
		"cost": 15,
		"desc": "+1 max summons. Goblin summons +1 HP."
	},
	"catalyst_ring": {
		"name": "Catalyst Ring",
		"faction": "Elemental",
		"cost": 20,
		"desc": "Elemental cards charge 1 turn faster."
	},
	"veil_piercer": {
		"name": "Veil Piercer",
		"faction": "Aberration",
		"cost": 20,
		"desc": "See enemy intents 2 turns ahead. +2 Attention start."
	},
	"merchants_signet": {
		"name": "Merchant's Signet",
		"faction": "Universal",
		"cost": 15,
		"desc": "Shops on every floor. Items 25% cheaper."
	},
	"survivors_badge": {
		"name": "Survivor's Badge",
		"faction": "Universal",
		"cost": 15,
		"desc": "+5 max HP. Below 25% HP: gain 3 Block."
	}
}

static func get_equipment_data(item_id: String, category: String) -> Dictionary:
	match category:
		"weapon": return WEAPON_DATABASE.get(item_id, {})
		"armor": return ARMOR_DATABASE.get(item_id, {})
		"shield": return SHIELD_DATABASE.get(item_id, {})
		"trinket": return TRINKET_DATABASE.get(item_id, {})
		_: return {}

static func equip_item(item_id: String, category: String) -> bool:
	"""Equip an item from inventory. Returns true if equipped. Updates HP bonuses."""
	var data = get_equipment_data(item_id, category)
	if data.is_empty():
		return false
	
	# Recalculate max HP when armor changes
	var old_hp_bonus = get_equipped_hp_bonus()
	
	match category:
		"weapon":
			if item_id in inventory_weapons:
				inventory_weapons.erase(item_id)
				if not equipped_weapon.is_empty():
					inventory_weapons.append(equipped_weapon)
				equipped_weapon = item_id
				return true
		"armor":
			if item_id in inventory_armor:
				inventory_armor.erase(item_id)
				if not equipped_armor.is_empty():
					inventory_armor.append(equipped_armor)
				equipped_armor = item_id
				# Update max HP
				var new_hp_bonus = get_equipped_hp_bonus()
				var hp_delta = new_hp_bonus - old_hp_bonus
				player_max_hp += hp_delta
				player_hp = min(player_hp + hp_delta, player_max_hp)
				return true
		"shield":
			if item_id in inventory_shields:
				inventory_shields.erase(item_id)
				if not equipped_shield.is_empty():
					inventory_shields.append(equipped_shield)
				equipped_shield = item_id
				return true
		"trinket":
			if item_id in inventory_trinkets:
				inventory_trinkets.erase(item_id)
				if not equipped_trinket.is_empty():
					inventory_trinkets.append(equipped_trinket)
				equipped_trinket = item_id
				return true
	return false

static func unequip_item(category: String) -> String:
	"""Unequip current item and return to inventory. Returns old item ID."""
	var old_id = ""
	var old_hp_bonus = get_equipped_hp_bonus() if category == "armor" else 0
	
	match category:
		"weapon":
			old_id = equipped_weapon
			if not old_id.is_empty():
				inventory_weapons.append(old_id)
				equipped_weapon = ""
		"armor":
			old_id = equipped_armor
			if not old_id.is_empty():
				inventory_armor.append(old_id)
				equipped_armor = ""
				# Reduce max HP
				var new_hp_bonus = get_equipped_hp_bonus()
				var hp_delta = new_hp_bonus - old_hp_bonus
				player_max_hp += hp_delta
				player_hp = min(player_hp, player_max_hp)
		"shield":
			old_id = equipped_shield
			if not old_id.is_empty():
				inventory_shields.append(old_id)
				equipped_shield = ""
		"trinket":
			old_id = equipped_trinket
			if not old_id.is_empty():
				inventory_trinkets.append(old_id)
				equipped_trinket = ""
	return old_id

static func get_equipped_hp_bonus() -> int:
	"""Get total HP bonus from equipped armor."""
	if equipped_armor.is_empty():
		return 0
	var data = ARMOR_DATABASE.get(equipped_armor, {})
	return data.get("hp_bonus", 0)

static func get_shop_stock_for_floor(floor_num: int) -> Dictionary:
	"""Generate equipment stock for a given floor."""
	var stock = {"weapons": [], "armor": [], "shields": [], "trinkets": []}
	for id in WEAPON_DATABASE.keys():
		if WEAPON_DATABASE[id]["floor"] <= floor_num:
			stock["weapons"].append(id)
	for id in ARMOR_DATABASE.keys():
		if ARMOR_DATABASE[id]["floor"] <= floor_num:
			stock["armor"].append(id)
	for id in SHIELD_DATABASE.keys():
		if SHIELD_DATABASE[id]["floor"] <= floor_num:
			stock["shields"].append(id)
	var all_trinkets = TRINKET_DATABASE.keys()
	all_trinkets.shuffle()
	stock["trinkets"] = all_trinkets.slice(0, 2)
	return stock

static func get_offering_data(item_id: String) -> Dictionary:
	return OFFERING_DATABASE.get(item_id, {})

static func get_offering_name(item_id: String) -> String:
	var data = OFFERING_DATABASE.get(item_id, {})
	return data.get("name", item_id)

static func get_offering_quality(item_id: String) -> int:
	var data = OFFERING_DATABASE.get(item_id, {})
	return data.get("quality", 0)

static func get_offering_gem_value(item_id: String) -> int:
	var data = OFFERING_DATABASE.get(item_id, {})
	return data.get("gem_value", 0)

static func get_kami_data(kami_id: String) -> Dictionary:
	return KAMI_DATABASE.get(kami_id, {})

static func get_boon_data(boon_id: String) -> Dictionary:
	return BOON_DATABASE.get(boon_id, {})

static func clear_all_room_states():
	"""Reset all room progress (new run)"""
	cleared_rooms.clear()
	gear_devil_tokens.clear()
	inventory_offerings.clear()
	inventory_weapons.clear()
	inventory_armor.clear()
	inventory_shields.clear()
	inventory_trinkets.clear()
	equipped_weapon = ""
	equipped_armor = ""
	equipped_shield = ""
	equipped_trinket = ""
	temp_effects.clear()
	boons_active.clear()
	reset_floor()

static func get_compiler_count() -> int:
	"""Calculate weighted deck size for Compiler awakening threshold.
	Fused cards count as 2. Unfused cards count as 1."""
	var count = 0
	for card_id in player_deck:
		var card = CardDB.get_card(card_id)
		if card:
			count += card.get_compiler_weight()
		else:
			count += 1
	return count

static func is_compiler_triggered() -> bool:
	"""Check if the 50-card Compiler threshold has been reached."""
	return get_compiler_count() >= deck_max_size

static func get_compiler_warning_level() -> String:
	"""Return warning string based on proximity to Compiler threshold.
	"""
	var count = get_compiler_count()
	var remaining = deck_max_size - count
	if remaining <= 0:
		return "COMPILER AWAKENING"
	elif remaining <= 5:
		return "Compiler imminent (%d left)" % remaining
	elif remaining <= 10:
		return "Deck heavy (%d left)" % remaining
	elif remaining <= 20:
		return "Deck growing (%d left)" % remaining
	return ""

static func get_overlay_stock_for_floor(floor_num: int) -> Array[String]:
	"""Generate overlay shop stock for a given floor.
	Returns array of overlay card IDs available for purchase."""
	# Floor 1: no overlays
	if floor_num <= 1:
		return []
	
	# Floor 2-3: basic Arcane only
	if floor_num <= 3:
		return ["Overlay_arcane_infusion", "Overlay_arcane_bolt", "Overlay_arcane_shield"]
	
	# Floor 4-5: Arcane + Divine
	if floor_num <= 5:
		return ["Overlay_arcane_infusion", "Overlay_arcane_bolt", "Overlay_divine_blessing", "Overlay_divine_shield"]
	
	# Floor 6-8: all three types
	if floor_num <= 8:
		return ["Overlay_arcane_infusion", "Overlay_arcane_overload", "Overlay_divine_blessing", "Overlay_divine_smite", "Overlay_infernal_pact", "Overlay_infernal_surge"]
	
	# Floor 9-10: all types + advanced
	return ["Overlay_arcane_infusion", "Overlay_arcane_overload", "Overlay_arcane_mastery", "Overlay_divine_blessing", "Overlay_divine_smite", "Overlay_divine_mastery", "Overlay_infernal_pact", "Overlay_infernal_surge", "Overlay_infernal_wrath"]


static func get_gear_devil_token_count() -> int:
	return gear_devil_tokens.size()

static func get_cleared_room_count() -> int:
	return cleared_rooms.size()

static func add_card_to_deck(card_id: String) -> bool:
	"""Add a card to persistent deck. Returns false if compiler threshold reached."""
	if get_compiler_count() > deck_max_size:
		push_warning("GameState: Compiler threshold reached (%d/%d)" % [get_compiler_count(), deck_max_size])
		return false
	player_deck.append(card_id)
	GameState.deck_changed.emit()
	return true

static func remove_card_from_deck(card_id: String) -> bool:
	"""Remove first instance of card from deck. Returns true if removed."""
	for i in range(player_deck.size()):
		if player_deck[i] == card_id:
			player_deck.remove_at(i)
			GameState.deck_changed.emit()
			return true
	return false

static func imbue(overlay_id: String, target_id: String) -> String:
	"""Fuse an Overlay card onto a base faction card.
	Consumes both cards, creates fused card, adds to deck.
	Returns fused card ID, or empty string on failure."""
	var overlay = CardDB.get_card(overlay_id)
	var base = CardDB.get_card(target_id)
	
	if not overlay or not base:
		push_warning("GameState: Imbue failed — invalid card IDs")
		return ""
	
	if not overlay.is_overlay:
		push_warning("GameState: Imbue failed — %s is not an Overlay" % overlay_id)
		return ""
	
	if base.is_fused:
		push_warning("GameState: Imbue failed — %s is already fused" % target_id)
		return ""
	
	# Check if target can receive this overlay type
	if base.faction in ["Dragon", "Universal"]:
		push_warning("GameState: Imbue failed — %s cannot be fused" % base.faction)
		return ""
	
	# Create fused card
	var fused = base.duplicate()
	fused.id = target_id + "_fused_" + overlay.overlay_type.to_lower()
	fused.is_fused = true
	fused.fused_overlay_id = overlay_id
	fused.fused_overlay_type = overlay.overlay_type
	fused.fused_keywords = overlay.keywords.duplicate()
	
	# Merge keywords (base + overlay)
	var merged_keywords: PackedStringArray = base.keywords.duplicate()
	for kw in overlay.keywords:
		if not (kw in merged_keywords):
			merged_keywords.append(kw)
	fused.keywords = merged_keywords
	
	# Set fused frame texture
	var f = base.faction.to_lower()
	var o = overlay.overlay_type.to_lower()
	fused.frame_texture_path = "res://assets/sprites/cards/%s_%s_frame.png" % [f, o]
	
	# Register fused card in CardDB
	if not CardDB.register_card(fused):
		push_warning("GameState: Imbue failed — could not register fused card")
		return ""
	
	# Remove base and overlay from deck
	remove_card_from_deck(target_id)
	remove_card_from_deck(overlay_id)
	
	# Add fused card to deck
	add_card_to_deck(fused.id)
	
	print("GameState: Imbued %s + %s → %s" % [target_id, overlay_id, fused.id])
	GameState.deck_changed.emit()
	return fused.id

static func can_imbue(overlay_id: String, target_id: String) -> bool:
	"""Check if overlay can be fused onto target without modifying state."""
	var overlay = CardDB.get_card(overlay_id)
	var base = CardDB.get_card(target_id)
	
	if not overlay or not base:
		return false
	if not overlay.is_overlay:
		return false
	if base.is_fused:
		return false
	if base.faction in ["Dragon", "Universal"]:
		return false
	return true

static func burn_card_for_gems(card_id: String) -> int:
	"""Remove card from deck, return gem value earned."""
	var card = CardDB.get_card(card_id)
	if not card:
		return 0
	
	var gem_value = _calculate_card_gem_value(card)
	if remove_card_from_deck(card_id):
		gems += gem_value
		GameState.gems_changed.emit(gems)
		GameState.deck_changed.emit()
		return gem_value
	return 0

static func _calculate_card_gem_value(card: CardData) -> int:
	"""Calculate gem value when burning a card."""
	var base = 1
	# Higher attention cost = more valuable
	base += card.attention_cost
	# Dice cards worth more
	if card.uses_dice:
		base += 2
	# Summons worth more
	if card.summon_count > 0:
		base += card.summon_count * 2
	# Special effects
	if not card.special_effect.is_empty():
		base += 2
	# Overlay cards worth most
	if card.is_overlay:
		base += 5
	return base

static func spend_quiddity(amount: int) -> bool:
	"""Spend quiddity. Returns true if successful."""
	if player_quiddity >= amount:
		player_quiddity -= amount
		GameState.quiddity_changed.emit(player_quiddity)
		return true
	return false

static func add_quiddity(amount: int):
	"""Add quiddity (post-combat rewards)."""
	player_quiddity += amount
	GameState.quiddity_changed.emit(player_quiddity)

static func get_deck_card_data() -> Array[CardData]:
	"""Get CardData objects for all cards in deck."""
	var result: Array[CardData] = []
	for id in player_deck:
		var card = CardDB.get_card(id)
		if card:
			result.append(card)
	return result

static func _save_game_static():
	var save_data = {
		"cleared_rooms": cleared_rooms,
		"defeated_bosses": defeated_bosses,
		"dial_position": dial_position,
		"crown_cog_unlocked": crown_cog_unlocked,
		"gear_devil_tokens": gear_devil_tokens,
		"inventory_offerings": inventory_offerings,
		"inventory_weapons": inventory_weapons,
		"inventory_armor": inventory_armor,
		"inventory_shields": inventory_shields,
		"inventory_trinkets": inventory_trinkets,
		"equipped_weapon": equipped_weapon,
		"equipped_armor": equipped_armor,
		"equipped_shield": equipped_shield,
		"equipped_trinket": equipped_trinket,
		"gems": gems,
		"temp_effects": temp_effects,
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"player_deck": player_deck,
		"player_quiddity": player_quiddity,
		"dragon_deck_archive": dragon_deck_archive,
		"run_count": run_count
	}
	
	var file = FileAccess.open("user://floor3_save.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

static func has_save() -> bool:
	return FileAccess.file_exists("user://floor3_save.json")

static func new_game():
	"""Reset for a fresh run. Keep persistent progression (deck with survivors, gems)."""
	
	# --- NG+ ARCHIVE: Collect survivor cards from current deck ---
	for card_id in player_deck:
		var card = CardDB.get_card(card_id)
		if card and card.survives_reset:
			if card_id not in dragon_deck_archive:
				dragon_deck_archive.append(card_id)
				print("GameState: Archived survivor card: %s" % card_id)
	
	# Increment run count
	run_count += 1
	if run_count > 1:
		ng_plus_unlocked = true
		print("GameState: NG+ activated — Run #%d" % run_count)
	
	# Reset all floor progress
	cleared_rooms.clear()
	defeated_bosses.clear()
	dial_position = 0
	crown_cog_unlocked = false
	gear_devil_tokens.clear()
	temp_effects.clear()
	boons_active.clear()
	player_quiddity = 0
	# Floor 1 reset
	transit_tokens.clear()
	is_first_run = true
	door_tutorial_completed = false
	floor1_rooms_cleared.clear()
	shortcut_maker_status = "none"
	shortcut_maker_pact_taken = false
	# Floor 2 reset
	floor2_elevator_repaired = false
	floor2_gears_collected = 0
	# Floor 4 reset
	floor4_booths_cleared.clear()
	floor4_booths_cleared_main.clear()
	floor4_booths_cleared_undercroft.clear()
	floor4_booths_cleared_refectory.clear()
	floor4_levels_unlocked = ["main"]
	floor4_current_level = "main"
	floor4_lifter_repaired = false
	floor4_collected_parts.clear()
	# Floor 5 reset
	floor5_valves_turned = {"breeze": false, "boiler": false, "gale": false}
	floor5_all_moorings_unlocked = false
	floor5_cargo_discovered = false
	floor5_charge_state = {"wind": 0, "steam": 0, "lightning": 0, "aether": 0}
	# Floor 6 reset
	floor6_courses.clear()
	floor6_grades.clear()
	floor6_clocktower_sabotaged = false
	floor6_master_key = false
	floor6_deans_key = false
	floor6_graduate_status = ""
	floor6_books_read = 0
	floor6_goblin_janitor_befriended = false
	# Floor 7 reset
	floor7_signed_pacts.clear()
	floor7_void_cracks_stabilized = 0
	floor7_docket_weight = 0
	floor7_final_pact_signed = false
	floor7_goblin_forger_used = false
	# Floor 8 reset
	floor8_overclock_meter = 0
	floor8_elemental_charge = {"fire": 0, "water": 0, "earth": 0, "air": 0}
	floor8_vessels_vented = 0
	floor8_vessels_overclocked = 0
	floor8_padlocks_opened = 0
	floor8_blix_surrendered = false
	floor8_scram_pulled = false
	# Floor 9 reset
	floor9_bone_count = 0
	floor9_gear_count = 0
	floor9_souls_freed = 0
	floor9_soul_debt = 0
	floor9_liberator_status = false
	floor9_companions_built = 0
	# Floor 10 reset
	floor10_choices_made.clear()
	floor10_ghosts_spoken.clear()
	floor10_hoard_touched.clear()
	floor10_aspects_defeated = 0
	floor10_final_choice = ""
	floor10_true_ending_unlocked = false
	
	# Reset HP
	player_hp = player_max_hp
	
	# --- REBUILD DECK: Starter deck + survivor archive ---
	player_deck.clear()
	
	var survivor_count = dragon_deck_archive.size()
	
	if survivor_count <= 20:
		# Standard: starter deck + all survivor cards
		for starter_id in CardDB.starter_deck:
			if starter_id not in player_deck:
				player_deck.append(starter_id)
		
		for survivor_id in dragon_deck_archive:
			if survivor_id not in player_deck:
				player_deck.append(survivor_id)
	else:
		# Threshold met: survivors ONLY, no starter deck
		for survivor_id in dragon_deck_archive:
			if survivor_id not in player_deck:
				player_deck.append(survivor_id)
		
		print("GameState: Survivor threshold reached (%d > 20) — starter deck replaced by archive" % survivor_count)
	
	# Enforce compiler threshold (weighted deck cap)
	while get_compiler_count() > deck_max_size:
		# Remove last card (could be smarter but this is safe)
		var removed = player_deck.pop_back()
		print("GameState: Compiler cap enforced — removed %s (%d/%d weighted)" % [removed, get_compiler_count(), deck_max_size])
	
	GameState.deck_changed.emit()
	
	save_game()
	print("GameState: New game started (Run #%d, deck size: %d, survivors: %d)" % [
		run_count, player_deck.size(), dragon_deck_archive.size()
	])

static func reset_everything():
	"""Hard reset — wipes ALL progress including deck and gems."""
	cleared_rooms.clear()
	defeated_bosses.clear()
	dial_position = 0
	crown_cog_unlocked = false
	gear_devil_tokens.clear()
	inventory_offerings.clear()
	inventory_weapons.clear()
	inventory_armor.clear()
	inventory_shields.clear()
	inventory_trinkets.clear()
	equipped_weapon = ""
	equipped_armor = ""
	equipped_shield = ""
	equipped_trinket = ""
	gems = 0
	temp_effects.clear()
	boons_active.clear()
	player_hp = 50
	player_max_hp = 50
	player_deck.clear()
	player_quiddity = 0
	# Floor 1 hard reset
	transit_tokens.clear()
	is_first_run = true
	door_tutorial_completed = false
	floor1_rooms_cleared.clear()
	shortcut_maker_status = "none"
	shortcut_maker_pact_taken = false
	current_floor = 1
	highest_floor_reached = 1
	# Floor 2 hard reset
	floor2_elevator_repaired = false
	floor2_gears_collected = 0
	# Floor 4 hard reset
	floor4_booths_cleared.clear()
	floor4_lifter_repaired = false
	floor4_collected_parts.clear()
	# Floor 5 hard reset
	floor5_valves_turned = {"breeze": false, "boiler": false, "gale": false}
	floor5_all_moorings_unlocked = false
	floor5_cargo_discovered = false
	floor5_charge_state = {"wind": 0, "steam": 0, "lightning": 0, "aether": 0}
	# Floor 6 hard reset
	floor6_courses.clear()
	floor6_grades.clear()
	floor6_clocktower_sabotaged = false
	floor6_master_key = false
	floor6_deans_key = false
	floor6_graduate_status = ""
	floor6_books_read = 0
	floor6_goblin_janitor_befriended = false
	# Floor 7 hard reset
	floor7_signed_pacts.clear()
	floor7_void_cracks_stabilized = 0
	floor7_docket_weight = 0
	floor7_final_pact_signed = false
	floor7_goblin_forger_used = false
	# Floor 8 hard reset
	floor8_overclock_meter = 0
	floor8_elemental_charge = {"fire": 0, "water": 0, "earth": 0, "air": 0}
	floor8_vessels_vented = 0
	floor8_vessels_overclocked = 0
	floor8_padlocks_opened = 0
	floor8_blix_surrendered = false
	floor8_scram_pulled = false
	# Floor 9 hard reset
	floor9_bone_count = 0
	floor9_gear_count = 0
	floor9_souls_freed = 0
	floor9_soul_debt = 0
	floor9_liberator_status = false
	floor9_companions_built = 0
	# Floor 10 hard reset
	floor10_choices_made.clear()
	floor10_ghosts_spoken.clear()
	floor10_hoard_touched.clear()
	floor10_aspects_defeated = 0
	floor10_final_choice = ""
	floor10_true_ending_unlocked = false
	# Meta hard reset
	ng_plus_unlocked = false
	exile_mode_unlocked = false
	cano_defeated = false
	true_ending_achieved = false
	true_ending_locked = false
	become_ending_chosen = false
	false_ending_seen = false
	run_count = 1
	dragon_deck_archive_size = 0
	dragon_deck_archive.clear()
	dragon_variant = ""  # Fresh dragon variant roll for new run
	save_suffix = ""
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("floor3_save.json")
	print("GameState: Everything reset")

static func delete_save():
	if FileAccess.file_exists("user://floor3_save.json"):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("floor3_save.json")
			print("GameState: Save deleted")

static func save_game():
	# Keep archive size in sync
	dragon_deck_archive_size = dragon_deck_archive.size()
	
	var save_data = {
		"cleared_rooms": cleared_rooms,
		"defeated_bosses": defeated_bosses,
		"dial_position": dial_position,
		"crown_cog_unlocked": crown_cog_unlocked,
		"gear_devil_tokens": gear_devil_tokens,
		"inventory_offerings": inventory_offerings,
		"inventory_weapons": inventory_weapons,
		"inventory_armor": inventory_armor,
		"inventory_shields": inventory_shields,
		"inventory_trinkets": inventory_trinkets,
		"equipped_weapon": equipped_weapon,
		"equipped_armor": equipped_armor,
		"equipped_shield": equipped_shield,
		"equipped_trinket": equipped_trinket,
		"gems": gems,
		"temp_effects": temp_effects,
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"player_deck": player_deck,
		"player_quiddity": player_quiddity,
		# Floor 1 data
		"transit_tokens": transit_tokens,
		"is_first_run": is_first_run,
		"door_tutorial_completed": door_tutorial_completed,
		"floor1_rooms_cleared": floor1_rooms_cleared,
		"shortcut_maker_status": shortcut_maker_status,
		"shortcut_maker_pact_taken": shortcut_maker_pact_taken,
		"current_floor": current_floor,
		# Floor 2 data
		"floor2_elevator_repaired": floor2_elevator_repaired,
		"floor2_gears_collected": floor2_gears_collected,
		# Floor 4 data
		"floor4_booths_cleared": floor4_booths_cleared,
		"floor4_booths_cleared_main": floor4_booths_cleared_main,
		"floor4_booths_cleared_undercroft": floor4_booths_cleared_undercroft,
		"floor4_booths_cleared_refectory": floor4_booths_cleared_refectory,
		"floor4_levels_unlocked": floor4_levels_unlocked,
		"floor4_current_level": floor4_current_level,
		"floor4_lifter_repaired": floor4_lifter_repaired,
		"floor4_collected_parts": floor4_collected_parts,
		# Floor 5 data
		"floor5_valves_turned": floor5_valves_turned,
		"floor5_all_moorings_unlocked": floor5_all_moorings_unlocked,
		"floor5_cargo_discovered": floor5_cargo_discovered,
		"floor5_charge_state": floor5_charge_state,
		# Floor 6 data
		"floor6_courses": floor6_courses,
		"floor6_grades": floor6_grades,
		"floor6_clocktower_sabotaged": floor6_clocktower_sabotaged,
		"floor6_master_key": floor6_master_key,
		"floor6_deans_key": floor6_deans_key,
		"floor6_graduate_status": floor6_graduate_status,
		"floor6_books_read": floor6_books_read,
		"floor6_goblin_janitor_befriended": floor6_goblin_janitor_befriended,
		# Floor 7 data
		"floor7_signed_pacts": floor7_signed_pacts,
		"floor7_void_cracks_stabilized": floor7_void_cracks_stabilized,
		"floor7_docket_weight": floor7_docket_weight,
		"floor7_final_pact_signed": floor7_final_pact_signed,
		"floor7_goblin_forger_used": floor7_goblin_forger_used,
		# Floor 8 data
		"floor8_overclock_meter": floor8_overclock_meter,
		"floor8_elemental_charge": floor8_elemental_charge,
		"floor8_vessels_vented": floor8_vessels_vented,
		"floor8_vessels_overclocked": floor8_vessels_overclocked,
		"floor8_padlocks_opened": floor8_padlocks_opened,
		"floor8_blix_surrendered": floor8_blix_surrendered,
		"floor8_scram_pulled": floor8_scram_pulled,
		# Floor 9 data
		"floor9_bone_count": floor9_bone_count,
		"floor9_gear_count": floor9_gear_count,
		"floor9_souls_freed": floor9_souls_freed,
		"floor9_soul_debt": floor9_soul_debt,
		"floor9_liberator_status": floor9_liberator_status,
		"floor9_companions_built": floor9_companions_built,
		# Floor 10 data
		"floor10_choices_made": floor10_choices_made,
		"floor10_ghosts_spoken": floor10_ghosts_spoken,
		"floor10_hoard_touched": floor10_hoard_touched,
		"floor10_aspects_defeated": floor10_aspects_defeated,
		"floor10_final_choice": floor10_final_choice,
		"floor10_true_ending_unlocked": floor10_true_ending_unlocked,
		# Meta-progression
		"ng_plus_unlocked": ng_plus_unlocked,
		"exile_mode_unlocked": exile_mode_unlocked,
		"cano_defeated": cano_defeated,
		"true_ending_achieved": true_ending_achieved,
		"true_ending_locked": true_ending_locked,
		"become_ending_chosen": become_ending_chosen,
		"false_ending_seen": false_ending_seen,
		"run_count": run_count,
		"dragon_deck_archive_size": dragon_deck_archive_size,
		"dragon_deck_archive": dragon_deck_archive,
		"dragon_variant": dragon_variant,
		"save_suffix": save_suffix,
	}
	
	var file = FileAccess.open("user://floor3_save.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("GameState: Saved successfully")

static func load_game() -> bool:
	if not FileAccess.file_exists("user://floor3_save.json"):
		return false
	
	var file = FileAccess.open("user://floor3_save.json", FileAccess.READ)
	if not file:
		return false
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		return false
	
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	
	# Load all data with explicit type conversion (JSON returns plain Arrays)
	var temp_cleared: Array = data.get("cleared_rooms", [])
	cleared_rooms.clear()
	for item in temp_cleared:
		cleared_rooms.append(int(item))
	
	var temp_defeated: Array = data.get("defeated_bosses", [])
	defeated_bosses.clear()
	for item in temp_defeated:
		defeated_bosses.append(str(item))
	dial_position = data.get("dial_position", 0)
	crown_cog_unlocked = data.get("crown_cog_unlocked", false)
	var temp_gear_tokens: Array = data.get("gear_devil_tokens", [])
	gear_devil_tokens.clear()
	for item in temp_gear_tokens:
		gear_devil_tokens.append(int(item))
	
	var temp_offerings: Array = data.get("inventory_offerings", [])
	inventory_offerings.clear()
	for item in temp_offerings:
		inventory_offerings.append(str(item))
	
	var temp_weapons: Array = data.get("inventory_weapons", [])
	inventory_weapons.clear()
	for item in temp_weapons:
		inventory_weapons.append(str(item))
	
	var temp_armor: Array = data.get("inventory_armor", [])
	inventory_armor.clear()
	for item in temp_armor:
		inventory_armor.append(str(item))
	
	var temp_shields: Array = data.get("inventory_shields", [])
	inventory_shields.clear()
	for item in temp_shields:
		inventory_shields.append(str(item))
	
	var temp_trinkets: Array = data.get("inventory_trinkets", [])
	inventory_trinkets.clear()
	for item in temp_trinkets:
		inventory_trinkets.append(str(item))
	equipped_weapon = data.get("equipped_weapon", "")
	equipped_armor = data.get("equipped_armor", "")
	equipped_shield = data.get("equipped_shield", "")
	equipped_trinket = data.get("equipped_trinket", "")
	gems = data.get("gems", 0)
	temp_effects = data.get("temp_effects", {})
	player_hp = data.get("player_hp", 50)
	player_max_hp = data.get("player_max_hp", 50)
	var temp_deck: Array = data.get("player_deck", [])
	player_deck.clear()
	for item in temp_deck:
		player_deck.append(str(item))
	
	player_quiddity = data.get("player_quiddity", 0)
	# Floor 1 data
	var temp_transit: Array = data.get("transit_tokens", [])
	transit_tokens.clear()
	for item in temp_transit:
		transit_tokens.append(str(item))
	is_first_run = data.get("is_first_run", true)
	door_tutorial_completed = data.get("door_tutorial_completed", false)
	var temp_f1_cleared: Array = data.get("floor1_rooms_cleared", [])
	floor1_rooms_cleared.clear()
	for item in temp_f1_cleared:
		floor1_rooms_cleared.append(str(item))
	shortcut_maker_status = data.get("shortcut_maker_status", "none")
	shortcut_maker_pact_taken = data.get("shortcut_maker_pact_taken", false)
	current_floor = data.get("current_floor", 1)
	highest_floor_reached = data.get("highest_floor_reached", 1)
	# Floor 2 data
	floor2_elevator_repaired = data.get("floor2_elevator_repaired", false)
	floor2_gears_collected = data.get("floor2_gears_collected", 0)
	# Floor 4 data
	var temp_f4_legacy: Array = data.get("floor4_booths_cleared", [])
	floor4_booths_cleared.clear()
	for item in temp_f4_legacy:
		floor4_booths_cleared.append(str(item))
	
	var temp_f4_main: Array = data.get("floor4_booths_cleared_main", [])
	floor4_booths_cleared_main.clear()
	for item in temp_f4_main:
		floor4_booths_cleared_main.append(str(item))
	
	var temp_f4_under: Array = data.get("floor4_booths_cleared_undercroft", [])
	floor4_booths_cleared_undercroft.clear()
	for item in temp_f4_under:
		floor4_booths_cleared_undercroft.append(str(item))
	
	var temp_f4_ref: Array = data.get("floor4_booths_cleared_refectory", [])
	floor4_booths_cleared_refectory.clear()
	for item in temp_f4_ref:
		floor4_booths_cleared_refectory.append(str(item))
	var temp_f4_levels: Array = data.get("floor4_levels_unlocked", ["main"])
	floor4_levels_unlocked.clear()
	for item in temp_f4_levels:
		floor4_levels_unlocked.append(str(item))
	floor4_current_level = data.get("floor4_current_level", "main")
	floor4_lifter_repaired = data.get("floor4_lifter_repaired", false)
	var temp_f4_parts: Array = data.get("floor4_collected_parts", [])
	floor4_collected_parts.clear()
	for item in temp_f4_parts:
		floor4_collected_parts.append(str(item))
	# Floor 5 data
	floor5_valves_turned = data.get("floor5_valves_turned", {"breeze": false, "boiler": false, "gale": false})
	floor5_all_moorings_unlocked = data.get("floor5_all_moorings_unlocked", false)
	floor5_cargo_discovered = data.get("floor5_cargo_discovered", false)
	floor5_charge_state = data.get("floor5_charge_state", {"wind": 0, "steam": 0, "lightning": 0, "aether": 0})
	# Floor 6 data
	var temp_f6_courses: Array = data.get("floor6_courses", [])
	floor6_courses.clear()
	for item in temp_f6_courses:
		floor6_courses.append(str(item))
	floor6_grades = data.get("floor6_grades", {})
	floor6_clocktower_sabotaged = data.get("floor6_clocktower_sabotaged", false)
	floor6_master_key = data.get("floor6_master_key", false)
	floor6_deans_key = data.get("floor6_deans_key", false)
	floor6_graduate_status = data.get("floor6_graduate_status", "")
	floor6_books_read = data.get("floor6_books_read", 0)
	floor6_goblin_janitor_befriended = data.get("floor6_goblin_janitor_befriended", false)
	# Floor 7 data
	var temp_f7_pacts: Array = data.get("floor7_signed_pacts", [])
	floor7_signed_pacts.clear()
	for item in temp_f7_pacts:
		if item is Dictionary:
			floor7_signed_pacts.append(item)
	floor7_void_cracks_stabilized = data.get("floor7_void_cracks_stabilized", 0)
	floor7_docket_weight = data.get("floor7_docket_weight", 0)
	floor7_final_pact_signed = data.get("floor7_final_pact_signed", false)
	floor7_goblin_forger_used = data.get("floor7_goblin_forger_used", false)
	# Floor 8 data
	floor8_overclock_meter = data.get("floor8_overclock_meter", 0)
	floor8_elemental_charge = data.get("floor8_elemental_charge", {"fire": 0, "water": 0, "earth": 0, "air": 0})
	floor8_vessels_vented = data.get("floor8_vessels_vented", 0)
	floor8_vessels_overclocked = data.get("floor8_vessels_overclocked", 0)
	floor8_padlocks_opened = data.get("floor8_padlocks_opened", 0)
	floor8_blix_surrendered = data.get("floor8_blix_surrendered", false)
	floor8_scram_pulled = data.get("floor8_scram_pulled", false)
	# Floor 9 data
	floor9_bone_count = data.get("floor9_bone_count", 0)
	floor9_gear_count = data.get("floor9_gear_count", 0)
	floor9_souls_freed = data.get("floor9_souls_freed", 0)
	floor9_soul_debt = data.get("floor9_soul_debt", 0)
	floor9_liberator_status = data.get("floor9_liberator_status", false)
	floor9_companions_built = data.get("floor9_companions_built", 0)
	# Floor 10 data
	floor10_choices_made = data.get("floor10_choices_made", {})
	floor10_ghosts_spoken = data.get("floor10_ghosts_spoken", [])
	floor10_hoard_touched = data.get("floor10_hoard_touched", [])
	floor10_aspects_defeated = data.get("floor10_aspects_defeated", 0)
	floor10_final_choice = data.get("floor10_final_choice", "")
	floor10_true_ending_unlocked = data.get("floor10_true_ending_unlocked", false)
	# Meta-progression
	ng_plus_unlocked = data.get("ng_plus_unlocked", false)
	exile_mode_unlocked = data.get("exile_mode_unlocked", false)
	cano_defeated = data.get("cano_defeated", false)
	true_ending_achieved = data.get("true_ending_achieved", false)
	true_ending_locked = data.get("true_ending_locked", false)
	become_ending_chosen = data.get("become_ending_chosen", false)
	false_ending_seen = data.get("false_ending_seen", false)
	run_count = data.get("run_count", 1)
	dragon_deck_archive_size = data.get("dragon_deck_archive_size", 0)
	dragon_variant = data.get("dragon_variant", "")
	var temp_dragon_deck: Array = data.get("dragon_deck_archive", [])
	dragon_deck_archive.clear()
	for _id in temp_dragon_deck:
		if _id is String:
			dragon_deck_archive.append(_id)
	save_suffix = data.get("save_suffix", "")
	dragon_deck_archive_size = dragon_deck_archive.size()
	print("GameState: Loaded successfully")
	return true
