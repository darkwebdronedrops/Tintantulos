extends FloorController

# ===================================================================
# FLOOR 2 CONTROLLER — The Fungal Cavern
# ===================================================================
# Handles:
#   - Spore Cycle mechanic (environment shifts based on kills)
#   - Elevator shortcut (repairable with 3 gear parts)
#   - Faction dominance tracking
#   - Boss unlock (Spore Heart convergence)
# ===================================================================

@onready var floor2_template: Floor2Template = Floor2Template.new()

# Spore Cycle State
var spore_state: String = "balance"  # "rot" | "bloom" | "overgrowth" | "balance"
var kill_counts: Dictionary = {"Undead": 0, "Elemental": 0, "Construct": 0}
var faction_dominant: String = ""

# Elevator shortcut
var elevator_repaired: bool = false
var gears_collected: int = 0
const GEARS_NEEDED: int = 3

# Boss
var boss_unlocked: bool = false

# UI
var spore_state_label: Label
var elevator_ui: Label

func _ready():
	floor_template = floor2_template
	super._ready()

func _setup_floor_specific():
	# Check if returning from previous run
	if GameState.floor2_elevator_repaired:
		elevator_repaired = true
		gears_collected = GEARS_NEEDED
	
	# First run: start in balance
	spore_state = "balance"
	kill_counts = {"Undead": 0, "Elemental": 0, "Construct": 0}
	_update_dominant_faction()
	
	print("[Floor2] Spore state: %s | Dominant: %s" % [spore_state, faction_dominant])

func _setup_floor_ui():
	# Spore state display
	spore_state_label = Label.new()
	spore_state_label.name = "SporeStateLabel"
	spore_state_label.position = Vector2(20, 20)
	spore_state_label.add_theme_font_size_override("font_size", 14)
	add_child(spore_state_label)
	_update_spore_state_display()
	
	# Elevator status
	elevator_ui = Label.new()
	elevator_ui.name = "ElevatorUI"
	elevator_ui.position = Vector2(20, 50)
	elevator_ui.add_theme_font_size_override("font_size", 12)
	elevator_ui.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
	add_child(elevator_ui)
	_update_elevator_display()

func _update_floor_ui():
	_update_spore_state_display()
	_update_elevator_display()

func _update_spore_state_display():
	if not spore_state_label:
		return
	
	var color = Color(0.8, 0.8, 0.8)
	var icon = "⚖"
	match spore_state:
		"rot":
			color = Color(0.6, 0.3, 0.3)
			icon = "🍄"
		"bloom":
			color = Color(0.3, 0.6, 0.3)
			icon = "🌿"
		"overgrowth":
			color = Color(0.5, 0.4, 0.2)
			icon = "🔩"
		"balance":
			color = Color(0.7, 0.7, 0.8)
			icon = "⚖"
	
	spore_state_label.text = "%s Spore State: %s" % [icon, spore_state.capitalize()]
	spore_state_label.add_theme_color_override("font_color", color)

func _update_elevator_display():
	if not elevator_ui:
		return
	
	if elevator_repaired:
		elevator_ui.text = "🔧 Elevator: OPERATIONAL"
		elevator_ui.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	else:
		elevator_ui.text = "🔧 Elevator: %d/%d gears" % [gears_collected, GEARS_NEEDED]
		elevator_ui.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))

# -------------------------------------------------------------------
# Spore Cycle — Kill Tracking
# -------------------------------------------------------------------

func _on_combat_started():
	"""Apply spore effects when combat begins."""
	var effects = get_spore_effects()
	var room = rooms.get(current_room_id)
	if room and room.has_method("apply_spore_effects"):
		room.apply_spore_effects(effects)
		print("[Floor2] Applied spore effects to '%s': %s" % [room.room_display_name, effects])
	
	# Apply environmental DoTs to CombatManager
	_apply_environmental_dots(effects)

func _apply_environmental_dots(effects: Dictionary):
	"""Apply environmental DoTs to CombatManager based on spore state."""
	var combat_manager = $CombatManager if has_node("CombatManager") else null
	if not combat_manager:
		return
	
	# Pool effect: heal or toxic damage per turn
	if effects.has("pool_heal"):
		var pool_value = effects["pool_heal"]
		# We'll apply this via a lightweight mechanism
		# Store in GameState for CombatManager to check
		GameState.floor2_pool_effect = pool_value
		print("[Floor2] Pool effect set: %d per turn" % pool_value)
	
	# Spore damage per turn
	if effects.has("spore_damage"):
		GameState.floor2_spore_damage = effects["spore_damage"]
		print("[Floor2] Spore damage set: %d per turn" % effects["spore_damage"])

func _on_combat_ended(victory: bool):
	super._on_combat_ended(victory)
	
	# Clear environmental effects
	GameState.floor2_pool_effect = 0
	GameState.floor2_spore_damage = 0
	
	if victory:
		var room = rooms.get(current_room_id)
		if room and room.has_method("get_defeated_faction"):
			var faction = room.get_defeated_faction()
			if not faction.is_empty():
				_record_kill(faction)

func _record_kill(faction: String):
	if faction in kill_counts:
		kill_counts[faction] += 1
		print("[Floor2] %s killed (%d total)" % [faction, kill_counts[faction]])
	
	_update_spore_state()
	_update_dominant_faction()
	_update_spore_state_display()
	
	# Re-apply effects to current room if player is still there
	var room = rooms.get(current_room_id)
	if room and room.has_method("apply_spore_effects"):
		var effects = get_spore_effects()
		room.apply_spore_effects(effects)
		print("[Floor2] Re-applied spore effects to '%s' after kill: %s" % [room.room_display_name, effects])

func _update_spore_state():
	var total = kill_counts["Undead"] + kill_counts["Elemental"] + kill_counts["Construct"]
	if total < 3:
		spore_state = "balance"
		return
	
	var max_kills = kill_counts.values().max()
	var dominant = ""
	for f in kill_counts:
		if kill_counts[f] == max_kills:
			dominant = f
			break
	
	match dominant:
		"Undead": spore_state = "rot"
		"Elemental": spore_state = "bloom"
		"Construct": spore_state = "overgrowth"
		_: spore_state = "balance"

func _update_dominant_faction():
	var max_kills = kill_counts.values().max()
	if max_kills == 0:
		faction_dominant = ""
		return
	
	for f in kill_counts:
		if kill_counts[f] == max_kills:
			faction_dominant = f
			break

func get_spore_state() -> String:
	return spore_state

func get_dominant_faction() -> String:
	return faction_dominant

func get_kill_count(faction: String) -> int:
	return kill_counts.get(faction, 0)

# -------------------------------------------------------------------
# Elevator / Shortcut System
# -------------------------------------------------------------------

func collect_gear() -> bool:
	if elevator_repaired:
		return false
	
	gears_collected += 1
	print("[Floor2] Gear collected: %d/%d" % [gears_collected, GEARS_NEEDED])
	
	if gears_collected >= GEARS_NEEDED:
		_repair_elevator()
	
	_update_elevator_display()
	return true

func _repair_elevator():
	elevator_repaired = true
	GameState.floor2_elevator_repaired = true
	
	# Unlock elevator shortcut in Lower Cavern
	var lower = rooms.get("lower")
	if lower and lower.has_method("unlock_elevator"):
		lower.unlock_elevator()
	
	_show_dialogue("Elevator", "The ancient Construct lift rumbles to life. A shortcut to the Spore Heart is now available.")
	print("[Floor2] Elevator repaired! Shortcut unlocked.")
	_update_elevator_display()

func is_elevator_repaired() -> bool:
	return elevator_repaired

# -------------------------------------------------------------------
# Boss Unlock
# -------------------------------------------------------------------

func _on_check_boss_unlock():
	if boss_unlocked:
		return
	
	# Boss unlocks when any cavern is cleared OR elevator is repaired
	var upper = rooms.get("upper")
	var middle = rooms.get("middle")
	var lower = rooms.get("lower")
	
	var any_cleared = false
	if upper and upper.has_method("is_cleared") and upper.is_cleared:
		any_cleared = true
	if middle and middle.has_method("is_cleared") and middle.is_cleared:
		any_cleared = true
	if lower and lower.has_method("is_cleared") and lower.is_cleared:
		any_cleared = true
	
	if any_cleared or elevator_repaired:
		_unlock_boss()

func _unlock_boss():
	boss_unlocked = true
	print("[Floor2] BOSS UNLOCKED — The Flesh Garden awaits")
	
	# Update Spore Heart room to show boss portal
	var spore_heart = rooms.get("spore_heart")
	if spore_heart and spore_heart.has_method("activate_boss"):
		spore_heart.activate_boss()
	
	_show_dialogue("The Cavern", "The spores converge. Something vast stirs in the heart of the fungal garden...")

# -------------------------------------------------------------------
# Object Interactions
# -------------------------------------------------------------------

func _on_object_interact(object_type: String):
	match object_type:
		"Cross Bridge":
			_show_dialogue("Fungal Bridge", "The mushroom caps glow softly. Some feel stable, others wobble beneath your feet.")
		"Burn Spores":
			_show_dialogue("Spore Gate", "Dense fungal matter blocks the path. A fire card would burn through it.")
		"Break Wall":
			var lower = rooms.get("lower")
			if lower and lower.has_method("reveal_secret"):
				lower.reveal_secret()
				_show_dialogue("Wall", "The fungal wall crumbles, revealing a hidden passage.")
			else:
				_show_dialogue("Wall", "The wall is thick with fungal growth. It might yield to force.")
		"Approach Pool":
			_show_dialogue("Bioluminescent Pool", "The water glows %s. Standing in the light heals you, but attracts attention." % _get_pool_color())
		"Repair Elevator":
			if elevator_repaired:
				_show_dialogue("Elevator", "The lift is operational. You can now travel directly to the Spore Heart.")
			else:
				_show_dialogue("Elevator", "The ancient lift is broken. Find %d gear parts to repair it." % GEARS_NEEDED)
		"Collect Gear":
			if collect_gear():
				_show_dialogue("Gear Part", "A brass gear piece from the old excavation. Heavy with age.")
			else:
				_show_dialogue("Gear Part", "You already have enough gears. Repair the elevator to use them.")
		"Challenge Boss":
			if boss_unlocked:
				_show_dialogue("The Flesh Garden", "The fungal throne pulses with decay. Are you ready?")
			else:
				_show_dialogue("The Flesh Garden", "The throne is dormant. Explore the cavern first.")
		"Save Game":
			if GameState.has_method("save_game"):
				GameState.save_game()
				_show_dialogue("Save", "Progress saved.")
		"Jump Platform":
			_show_dialogue("Platform", "Floating mushroom platforms drift above the pool. Timing is everything.")
		"Disperse Spores":
			_show_dialogue("Spore Cloud", "Thick spores reduce visibility. A fire or heat card would clear them.")
		_:
			super._on_object_interact(object_type)

func _get_pool_color() -> String:
	match faction_dominant:
		"Undead": return "pale white"
		"Elemental": return "deep blue"
		"Construct": return "warm orange"
		_: return "soft green"

# -------------------------------------------------------------------
# Public API
# -------------------------------------------------------------------

func get_spore_effects() -> Dictionary:
	"""Get current environmental effects based on spore state."""
	match spore_state:
		"rot":
			return {
				"pool_heal": -1,  # Toxic instead of healing
				"spore_damage": 1,
				"undead_spawn_bonus": true,
			}
		"bloom":
			return {
				"pool_heal": 3,
				"spore_visibility": 0.3,
				"elemental_spawn_bonus": true,
			}
		"overgrowth":
			return {
				"pool_heal": 1,
				"trap_damage": 3,
				"construct_spawn_bonus": true,
			}
		_:
			return {
				"pool_heal": 2,
				"spore_visibility": 0.6,
			}

# -------------------------------------------------------------------
# Floor Transition (Up to Floor 3)
# -------------------------------------------------------------------

func _ascend_to_next_floor():
	"""Ascend to Floor 3 (The Gearworks)."""
	print("[Floor2] Ascending to Floor 3...")
	GameState.set_current_floor(3)
	get_tree().change_scene_to_file("res://scenes/Floor3.tscn")
