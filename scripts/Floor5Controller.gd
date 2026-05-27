extends FloorController

# ===================================================================
# FLOOR 5 CONTROLLER — The Airship Docks
# Refactored to use FloorController base class + Floor5Template
# ===================================================================
# Adds: CHARGE system, environmental hazards, gangplank mechanics,
#       boss phase transitions (The Elemental Core)
# ===================================================================

@onready var floor5_template: Floor5Template = Floor5Template.new()

# CHARGE System
var charge: Dictionary = {"wind": 0, "steam": 0, "lightning": 0, "aether": 0}
var max_charge: int = 10
var vent_ready: bool = false

# Environmental Hazards
var combat_turn_count: int = 0
var wind_gust_interval: int = 3
var steam_vent_interval: int = 4
var storm_phase_interval: int = 8
var steam_warning_turns: int = 0  # Countdown before vent burst
var in_storm_phase: bool = false

# Gangplank Weight Tracking
var gangplank_entities: Dictionary = {}  # room_id -> entity_count
const GANGPLANK_LIMIT: int = 3

# Boss State (The Elemental Core)
var boss_current_phase: String = ""  # "wind" | "steam" | "lightning"
var boss_phase_transitioned: bool = false

# Mooring Puzzle State
var valves_turned: Dictionary = {"breeze": false, "boiler": false, "gale": false}
var all_moorings_unlocked: bool = false

# Secret Room
var cargo_hold_discovered: bool = false

# UI References
var charge_ui: Label
var hazard_ui: Label
var gangplank_ui: Label
var boss_phase_ui: Label

func _ready():
	floor_template = floor5_template
	super._ready()

# -------------------------------------------------------------------
# Floor-Specific Setup (override)
# -------------------------------------------------------------------

func _setup_floor_specific():
	# Restore saved state if returning
	if GameState.floor5_valves_turned:
		valves_turned = GameState.floor5_valves_turned
		_check_all_moorings_unlocked()
	
	# Initialize CHARGE
	var config = floor5_template.get_charge_config()
	max_charge = config.get("max_charge", 10)
	
	# Initialize hazard timers
	var timers = floor5_template.get_hazard_timers()
	wind_gust_interval = timers.get("wind_gust_interval", 3)
	steam_vent_interval = timers.get("steam_vent_interval", 4)
	storm_phase_interval = timers.get("storm_phase_interval", 8)
	
	print("[Floor5] CHARGE max: %d | Wind interval: %d | Steam interval: %d | Storm: %d" % [
		max_charge, wind_gust_interval, steam_vent_interval, storm_phase_interval
	])

func _setup_floor_ui():
	# CHARGE meter
	charge_ui = Label.new()
	charge_ui.name = "ChargeUI"
	charge_ui.position = Vector2(20, 20)
	charge_ui.size = Vector2(300, 60)
	charge_ui.add_theme_font_size_override("font_size", 14)
	add_child(charge_ui)
	_update_charge_display()
	
	# Hazard status
	hazard_ui = Label.new()
	hazard_ui.name = "HazardUI"
	hazard_ui.position = Vector2(20, 90)
	hazard_ui.size = Vector2(300, 30)
	hazard_ui.add_theme_font_size_override("font_size", 12)
	add_child(hazard_ui)
	_update_hazard_display()
	
	# Gangplank weight
	gangplank_ui = Label.new()
	gangplank_ui.name = "GangplankUI"
	gangplank_ui.position = Vector2(20, 130)
	gangplank_ui.size = Vector2(300, 30)
	gangplank_ui.add_theme_font_size_override("font_size", 12)
	add_child(gangplank_ui)
	_update_gangplank_display()
	
	# Boss phase (hidden until boss)
	boss_phase_ui = Label.new()
	boss_phase_ui.name = "BossPhaseUI"
	boss_phase_ui.position = Vector2(20, 170)
	boss_phase_ui.size = Vector2(300, 30)
	boss_phase_ui.add_theme_font_size_override("font_size", 14)
	boss_phase_ui.visible = false
	add_child(boss_phase_ui)

func _update_floor_ui():
	_update_charge_display()
	_update_hazard_display()
	_update_gangplank_display()
	if not boss_phase_ui.text.is_empty():
		boss_phase_ui.visible = true

# -------------------------------------------------------------------
# CHARGE System
# -------------------------------------------------------------------

func add_charge(type: String, amount: int):
	"""Add CHARGE of a specific type."""
	if type == "aether" or (charge["wind"] > 0 and charge["steam"] > 0 and charge["lightning"] > 0):
		# Mixed CHARGE creates unstable Aether
		charge["aether"] += amount
		print("[Floor5] Aether CHARGE unstable! +%d" % amount)
	else:
		charge[type] = min(charge[type] + amount, max_charge)
		print("[Floor5] %s CHARGE: %d/%d" % [type.capitalize(), charge[type], max_charge])
	
	_check_vent_ready()
	_update_charge_display()

func _check_vent_ready():
	var total = charge["wind"] + charge["steam"] + charge["lightning"] + charge["aether"]
	vent_ready = total >= max_charge
	if vent_ready:
		_show_notification("⚡ MAX CHARGE — Press [V] to VENT!", Color(0.9, 0.9, 0.3))

func vent_charge() -> Dictionary:
	"""Release all CHARGE. Returns the effect based on dominant type."""
	if not vent_ready:
		return {}
	
	var dominant = _get_dominant_charge_type()
	var total = charge["wind"] + charge["steam"] + charge["lightning"] + charge["aether"]
	
	var effect = {
		"type": dominant,
		"total": total,
		"effect": ""
	}
	
	match dominant:
		"wind":
			effect["effect"] = "push_all"
			effect["push_distance"] = total
			_show_notification("🌪 VENT WIND — Push all enemies %d hexes!" % total, Color(0.5, 0.8, 0.9))
		"steam":
			effect["effect"] = "heal_burn"
			effect["heal"] = total * 2
			effect["burn"] = total
			_show_notification("💨 VENT STEAM — Heal %d, Burn all for %d!" % [total * 2, total], Color(0.7, 0.7, 0.7))
		"lightning":
			effect["effect"] = "stun_damage"
			effect["damage"] = total * 3
			effect["stun_turns"] = 2
			_show_notification("⚡ VENT LIGHTNING — Stun all, deal %d damage!" % (total * 3), Color(0.9, 0.9, 0.3))
		"aether":
			effect["effect"] = "random"
			effect["random_table"] = ["explode", "heal_all", "swap_positions", "reset_all_charge"]
			_show_notification("☄ VENT AETHER — UNSTABLE! Random effect!", Color(0.9, 0.3, 0.9))
	
	# Reset all CHARGE
	charge = {"wind": 0, "steam": 0, "lightning": 0, "aether": 0}
	vent_ready = false
	_update_charge_display()
	
	return effect

func _get_dominant_charge_type() -> String:
	var max_val = charge.values().max()
	if max_val == 0:
		return "wind"
	
	for t in ["wind", "steam", "lightning", "aether"]:
		if charge[t] == max_val:
			return t
	return "wind"

func _update_charge_display():
	if not charge_ui:
		return
	
	var total = charge["wind"] + charge["steam"] + charge["lightning"] + charge["aether"]
	var color = Color(0.8, 0.8, 0.8)
	if vent_ready:
		color = Color(0.9, 0.9, 0.3)
	
	charge_ui.text = "CHARGE: %d/%d\n🌪 %d | 💨 %d | ⚡ %d | ☄ %d" % [
		total, max_charge,
		charge["wind"], charge["steam"], charge["lightning"], charge["aether"]
	]
	charge_ui.add_theme_color_override("font_color", color)

# -------------------------------------------------------------------
# Environmental Hazards (Combat Integration)
# -------------------------------------------------------------------

func _on_combat_started():
	"""Called when combat begins. Reset turn counter."""
	combat_turn_count = 0
	steam_warning_turns = 0
	in_storm_phase = false
	_update_hazard_display()

func _on_combat_turn_advanced():
	"""Called each combat turn. Process environmental effects."""
	combat_turn_count += 1
	
	# Wind Gust
	if combat_turn_count % wind_gust_interval == 0:
		_apply_wind_gust()
	
	# Steam Vent
	var steam_turn = combat_turn_count % steam_vent_interval
	if steam_turn == steam_vent_interval - 2:
		# Warning: 2 turns before burst
		steam_warning_turns = 2
		_show_notification("🔴 STEAM BUILDING — Vent imminent!", Color(0.9, 0.5, 0.2))
	elif steam_turn == 0 and combat_turn_count > 0:
		# Vent burst
		_apply_steam_vent()
		steam_warning_turns = 0
	
	# Storm Phase
	if combat_turn_count % storm_phase_interval == 0 and combat_turn_count > 0:
		in_storm_phase = true
		_apply_storm_phase()
	elif in_storm_phase and combat_turn_count % storm_phase_interval == 4:
		# Storm ends after 4 turns
		in_storm_phase = false
		_show_notification("⛈ Storm subsides...", Color(0.5, 0.5, 0.7))
	
	_update_hazard_display()

func _apply_wind_gust():
	"""Wind pushes player 1 hex toward nearest edge unless anchored."""
	var current = rooms.get(current_room_id)
	if not current:
		return
	
	# Check if player is anchored
	if current.has_method("is_player_anchored") and current.is_player_anchored():
		_show_notification("🌪 Wind gusts — Anchor holds!", Color(0.5, 0.8, 0.9))
		return
	
	# Check if player has wind CHARGE to push back
	if charge["wind"] >= 2:
		charge["wind"] -= 2
		_show_notification("🌪 Wind gusts — You push back with Wind CHARGE!", Color(0.5, 0.8, 0.9))
		_update_charge_display()
		return
	
	# Apply slide damage
	if GameState.has_method("damage_player"):
		GameState.damage_player(randi() % 4 + 1)
	_show_notification("🌪 Wind gusts — Slide toward edge!", Color(0.9, 0.7, 0.3))

func _apply_steam_vent():
	"""Steam vent burst — 2d6 damage + knockback."""
	var damage = randi() % 6 + randi() % 6 + 2  # 2d6
	_show_notification("💥 STEAM VENT! %d damage + knockback!" % damage, Color(0.9, 0.3, 0.1))
	# Apply steam vent damage
	if GameState.has_method("damage_player"):
		GameState.damage_player(damage)
	
	# Bonus: If player was near vent, they gain steam CHARGE
	add_charge("steam", 2)

func _apply_storm_phase():
	"""Storm phase begins — lightning rods active."""
	_show_notification("⛈ STORM PHASE — Lightning rods live!", Color(0.3, 0.3, 0.9))
	
	# Check if player is near lightning rod
	var current = rooms.get(current_room_id)
	if current and current.has_method("is_near_lightning_rod") and current.is_near_lightning_rod():
		# Risk vs reward
		var damage = randi() % 6 + randi() % 6 + randi() % 6 + 3  # 3d6
		_show_notification("⚡ Lightning strikes! %d damage but +3 CHARGE!" % damage, Color(0.9, 0.3, 0.9))
		if GameState.has_method("damage_player"):
			GameState.damage_player(damage)
		add_charge("lightning", 3)

func _update_hazard_display():
	if not hazard_ui:
		return
	
	var wind_next = wind_gust_interval - (combat_turn_count % wind_gust_interval)
	var steam_next = steam_vent_interval - (combat_turn_count % steam_vent_interval)
	var storm_next = storm_phase_interval - (combat_turn_count % storm_phase_interval)
	
	var status = "🌪 Wind: %d | 💨 Steam: %d" % [wind_next, steam_next]
	if steam_warning_turns > 0:
		status += " ⚠ VENT SOON!"
	if in_storm_phase:
		status += " ⛈ STORM!"
	else:
		status += " | ⚡ Storm: %d" % storm_next
	
	hazard_ui.text = status

# -------------------------------------------------------------------
# Gangplank Weight System
# -------------------------------------------------------------------

func _is_gangplank_room(room_id: String) -> bool:
	"""Check if room is a gangplank (between airships)."""
	return room_id in ["breeze", "boiler", "gale"]

func _gangplank_collapse(room_id: String):
	"""Gangplank collapses — fall to lower level."""
	var damage = randi() % 6 + randi() % 6 + 2  # 2d6
	_show_notification("💥 GANGPLANK COLLAPSES! Fall to Mooring — %d damage!" % damage, Color(0.9, 0.1, 0.1))
	
	# Teleport player to mooring
	move_player_to_room("mooring")
	
	# Apply fall damage
	if GameState.has_method("damage_player"):
		GameState.damage_player(damage)
	
	# Cancel the encounter
	in_combat = false

func _update_gangplank_display():
	if not gangplank_ui:
		return
	
	var current_weight = gangplank_entities.get(current_room_id, 0)
	if current_weight > 0:
		var color = Color(0.9, 0.7, 0.3)
		if current_weight >= GANGPLANK_LIMIT:
			color = Color(0.9, 0.2, 0.2)
		gangplank_ui.text = "⚖ Gangplank: %d/%d entities" % [current_weight, GANGPLANK_LIMIT]
		gangplank_ui.add_theme_color_override("font_color", color)
		gangplank_ui.visible = true
	else:
		gangplank_ui.visible = false

# -------------------------------------------------------------------
# Boss Phase System (The Elemental Core)
# -------------------------------------------------------------------

func _check_boss_phase(boss_hp: int, max_hp: int = 60) -> String:
	"""Determine current boss phase based on HP percentage."""
	var hp_percent = float(boss_hp) / max_hp
	
	var new_phase = ""
	if hp_percent > 0.66:
		new_phase = "wind"
	elif hp_percent > 0.33:
		new_phase = "steam"
	else:
		new_phase = "lightning"
	
	if new_phase != boss_current_phase:
		boss_current_phase = new_phase
		boss_phase_transitioned = true
		_on_boss_phase_transition(new_phase)
	
	return new_phase

func _on_boss_phase_transition(new_phase: String):
	"""Handle boss phase change effects."""
	match new_phase:
		"wind":
			_show_notification("🌪 PHASE 1: WIND — The Core howls!", Color(0.5, 0.8, 0.9))
			# Summon 2 Jetstream Shepherds
			# Double arena wind speed
		"steam":
			_show_notification("💨 PHASE 2: STEAM — The Core boils!", Color(0.7, 0.7, 0.7))
			# Heal boss 10 HP
			# Fill arena with steam clouds
			# Reset all CHARGE to 0
			charge = {"wind": 0, "steam": 0, "lightning": 0, "aether": 0}
			_update_charge_display()
		"lightning":
			_show_notification("⚡ PHASE 3: LIGHTNING — The Core strikes!", Color(0.9, 0.9, 0.3))
			# Become immune to lightning CHARGE
			# Reflect 50% of lightning damage
	
	_update_boss_phase_display()

func _update_boss_phase_display():
	if not boss_phase_ui:
		return
	
	var color = Color(0.8, 0.8, 0.8)
	match boss_current_phase:
		"wind": color = Color(0.5, 0.8, 0.9)
		"steam": color = Color(0.7, 0.7, 0.7)
		"lightning": color = Color(0.9, 0.9, 0.3)
	
	boss_phase_ui.text = "BOSS: The Elemental Core [%s PHASE]" % boss_current_phase.to_upper()
	boss_phase_ui.add_theme_color_override("font_color", color)
	boss_phase_ui.visible = true

# -------------------------------------------------------------------
# Mooring Puzzle (Unlock Crow's Nest)
# -------------------------------------------------------------------

func _on_object_interact(object_type: String):
	"""Override to handle floor-specific interactions."""
	match object_type:
		"Turn Valve":
			_turn_steam_valve()
		"Anchor Rope":
			_toggle_anchor()
		"Approach Rod":
			_approach_lightning_rod()
		"Ride Lift":
			_ride_cargo_lift()
		"Challenge Boss":
			if all_moorings_unlocked:
				_start_boss_combat()
			else:
				_show_dialogue("Boss Altar", "The Aetherworks is sealed. Unlock all three moorings first.")
		"Inspect Wall":
			_discover_cargo_hold()
		"Vent Steam":
			_trigger_steam_vent_early()
		"Attach Cable":
			_ground_lightning_rod()
		_:
			super._on_object_interact(object_type)

func _turn_steam_valve():
	"""Turn a steam valve in the current room."""
	var room_id = current_room_id
	if room_id in ["breeze", "boiler", "gale"] and not valves_turned.get(room_id, false):
		valves_turned[room_id] = true
		_show_notification("🔧 %s valve turned! (%d/3)" % [
			room_id.capitalize(),
			valves_turned.values().count(true)
		], Color(0.3, 0.9, 0.3))
		
		# Visual effect: steam release
		var room = rooms.get(room_id)
		if room and room.has_method("play_steam_effect"):
			room.play_steam_effect()
		
		_check_all_moorings_unlocked()
	else:
		_show_notification("Valve already turned or not found here.", Color(0.7, 0.7, 0.7))

func _check_all_moorings_unlocked():
	if valves_turned["breeze"] and valves_turned["boiler"] and valves_turned["gale"]:
		if not all_moorings_unlocked:
			all_moorings_unlocked = true
			GameState.floor5_all_moorings_unlocked = true
			
			# Unlock gangplanks to Crow's Nest
			var crow = rooms.get("crow")
			if crow and crow.has_method("unlock_gangplanks"):
				crow.unlock_gangplanks()
			
			_show_dialogue("The Tower", "All three moorings unlock. The gangplanks to the Crow's Nest extend.")
			print("[Floor5] All moorings unlocked! Crow's Nest accessible.")

func _start_boss_combat():
	"""Start boss combat with The Elemental Core."""
	boss_current_phase = "wind"
	boss_phase_transitioned = false
	
	var boss_data = RoomEnemyDatabase.ENEMIES.get("elemental_core", null)
	if boss_data:
		var combat_manager = $CombatManager if has_node("CombatManager") else null
		if combat_manager:
			in_combat = true
			combat_manager.start_combat([boss_data.to_combat_data()], GameState.player_deck)
			_update_boss_phase_display()
	else:
		push_error("[Floor5] Boss 'elemental_core' not found in enemy database!")

func _toggle_anchor():
	"""Toggle anchor state in current room."""
	var current = rooms.get(current_room_id)
	if current and current.has_method("toggle_anchor"):
		current.toggle_anchor()
		var anchored = current.is_player_anchored() if current.has_method("is_player_anchored") else false
		if anchored:
			_show_notification("⚓ Anchored — Wind resistance active!", Color(0.3, 0.9, 0.3))
		else:
			_show_notification("⚓ Anchor released.", Color(0.7, 0.7, 0.7))

func _approach_lightning_rod():
	"""Approach lightning rod — gain CHARGE but risk damage during storm."""
	if in_storm_phase:
		var damage = randi() % 6 + randi() % 6 + randi() % 6 + 3
		_show_notification("⚡ Lightning strikes! %d damage but +3 CHARGE!" % damage, Color(0.9, 0.3, 0.9))
		if GameState.has_method("damage_player"):
			GameState.damage_player(damage)
		add_charge("lightning", 3)
	else:
		_show_notification("The lightning rod hums with potential...", Color(0.5, 0.5, 0.7))
		add_charge("lightning", 1)

func _ride_cargo_lift():
	"""Ride cargo lift between levels."""
	var connections = floor_template.get_room_connections(current_room_id)
	var target = connections.get("up", "")
	if target.is_empty():
		target = connections.get("down", "")
	
	if not target.is_empty():
		_show_notification("🛗 Riding cargo lift...", Color(0.7, 0.7, 0.5))
		_transition_to_room(target)
	else:
		_show_notification("No lift destination from here.", Color(0.7, 0.7, 0.7))

func _discover_cargo_hold():
	"""Discover the secret cargo hold (behind fake wall in boiler room)."""
	if current_room_id == "boiler" and not cargo_hold_discovered:
		cargo_hold_discovered = true
		_show_dialogue("Cargo Hold", "The wall slides aside. A hidden cargo hold lies beyond, humming with wrong frequency.")
		
		# Unlock secret connection
		var boiler = rooms.get("boiler")
		if boiler and boiler.has_method("unlock_secret_door"):
			boiler.unlock_secret_door()
	else:
		_show_notification("Just a wall. Nothing unusual.", Color(0.7, 0.7, 0.7))

func _trigger_steam_vent_early():
	"""Deliberately trigger steam vent (risk/reward — launch across gap)."""
	var damage = randi() % 6 + randi() % 6 + 2
	_show_notification("💨 You trigger the vent! %d damage but launch across the gap!" % damage, Color(0.9, 0.7, 0.3))
	if GameState.has_method("damage_player"):
		GameState.damage_player(damage)
	add_charge("steam", 2)

func _ground_lightning_rod():
	"""Attach grounding cable to lightning rod (solves Crow's Nest puzzle)."""
	_show_notification("⚓ Cable attached — Lightning rod grounded!", Color(0.3, 0.9, 0.3))
	# Mark puzzle as solved for storm crossing

# -------------------------------------------------------------------
# Input Override — VENT Key
# -------------------------------------------------------------------

func _input(event: InputEvent):
	# Check for VENT key (V) during combat
	if in_combat and event is InputEventKey and event.pressed:
		if event.keycode == KEY_V and vent_ready:
			vent_charge()
			get_viewport().set_input_as_handled()
			return
	
	# Otherwise use base class input
	super._input(event)

# -------------------------------------------------------------------
# Floor Complete — Transition to Floor 6
# -------------------------------------------------------------------

func _ascend_to_next_floor():
	"""Ascend to Floor 6."""
	print("[Floor5] Ascending to Floor 6...")
	get_tree().change_scene_to_file("res://scenes/Floor6.tscn")

func _on_floor_complete():
	"""Called when Elemental Core is defeated."""
	_show_dialogue("The Tower", "The Elemental Core shatters.\nThe Aether Key materializes.\nThe path to Floor 6 opens.")
	
	# Give rewards
	GameState.add_card_to_deck("elemental_core")  # Boss card
	GameState.gems += 75
	if GameState.has_signal("gems_changed"):
		GameState.gems_changed.emit(GameState.gems)
	
	# Save progress
	GameState.save_game()
	
	# Show floor transition option
	_show_floor_transition_prompt()

func _show_floor_transition_prompt():
	"""Show prompt to ascend to Floor 6."""
	var prompt = Label.new()
	prompt.name = "FloorTransitionPrompt"
	prompt.text = "Press [S] to Ascend to Floor 6 — The Lunar University"
	prompt.position = Vector2(660, 600)
	prompt.size = Vector2(600, 40)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	add_child(prompt)

# -------------------------------------------------------------------
# Combat Override — Hook environmental turns
# -------------------------------------------------------------------

func _on_encounter_started(enemy_names: Array, room_id: String = ""):
	"""Override to init combat state and check gangplank weight."""
	_on_combat_started()
	
	# Gangplank check
	var total_entities = 1 + enemy_names.size()
	if _is_gangplank_room(room_id) and total_entities > GANGPLANK_LIMIT:
		_gangplank_collapse(room_id)
		return
	
	# Gangplank weight tracking
	if _is_gangplank_room(room_id):
		var total = 1 + enemy_names.size()
		gangplank_entities[room_id] = total
		_update_gangplank_display()
	
	# Proceed with normal combat
	super._on_encounter_started(enemy_names, room_id)

func _on_combat_ended(victory: bool):
	"""Override to check boss defeat and faction kills."""
	super._on_combat_ended(victory)
	
	if not victory:
		return
	
	# Check if this was boss fight
	if current_room_id == "aether":
		_on_floor_complete()
		return
	
	# Check faction kills for elemental death bonus
	var room = rooms.get(current_room_id)
	if room and room.has_method("get_defeated_faction"):
		var faction = room.get_defeated_faction()
		if faction == "Elemental":
			add_charge("wind", 1)  # Elemental death bonus
			print("[Floor5] Elemental defeated — +1 Wind CHARGE")

# -------------------------------------------------------------------
# Public API
# -------------------------------------------------------------------

func get_charge() -> Dictionary:
	return charge.duplicate()

func get_boss_phase() -> String:
	return boss_current_phase

func are_all_moorings_unlocked() -> bool:
	return all_moorings_unlocked

func is_cargo_hold_discovered() -> bool:
	return cargo_hold_discovered
