extends FloorController

# ===================================================================
# FLOOR 4 CONTROLLER — The Curio Bazaar (Three Levels)
# ===================================================================
# Levels:
#   main       — Circular hall, 12 booths, Great Lifter center
#   undercroft — Pipe tunnels below, Aether Slick, Construct patrols
#   refectory  — Brass balconies above, memory-food, Nostalgia debuff
# ===================================================================

@onready var floor4_template: Floor4Template = Floor4Template.new()

# Level nodes (set by scene tree)
var main_level: Node2D
var undercroft_level: Node2D
var refectory_level: Node2D

# Active booth interior (overlay within a level)
var active_booth_interior: Node2D = null
var active_booth_id: String = ""
var in_booth: bool = false

# Aether Slick state (undercroft)
var on_aether_slick: bool = false
var last_move_direction: Vector2 = Vector2.ZERO

# Nostalgia debuff (refectory)
var has_nostalgia: bool = false

func _ready():
	floor_template = floor4_template
	super._ready()

func _build_floor():
	# Skip room instantiation — Floor4 uses legacy level nodes (MainLevel, Undercroft, Refectory)
	# instead of the room-based architecture. The base FloorController._build_floor() would
	# create duplicate room instances from Floor4Template that lack proper scripts.
	_setup_player()
	_setup_combat()
	_setup_ui()
	_setup_shop()
	_setup_floor_specific()
	
	# Position player AFTER floor-specific setup has found MainLevel
	if main_level:
		var spawn = main_level.get_node_or_null("PlayerSpawn")
		if spawn and player_node:
			player_node.global_position = spawn.global_position
			current_room_id = floor_template.starting_room_id
			print("[Floor4] Player positioned at MainLevel spawn: %s" % spawn.global_position)
	else:
		push_warning("[Floor4] MainLevel not found — player positioning may be incorrect")
	
	# Start floor ambient music
	if floor_template and floor_template.floor_id > 0:
		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr and audio_mgr.has_method("play_floor_ambient"):
			audio_mgr.play_floor_ambient(floor_template.floor_id)

func _setup_player():
	# Call base to create player node if needed
	super._setup_player()

# -------------------------------------------------------------------
# Floor-Specific Setup (override)
# -------------------------------------------------------------------

func _setup_floor_specific():
	# Find level nodes in scene tree
	main_level = get_node_or_null("MainLevel")
	undercroft_level = get_node_or_null("Undercroft")
	refectory_level = get_node_or_null("Refectory")
	
	# Hide non-starting levels (legacy — will be removed when scenes are separated)
	if undercroft_level:
		undercroft_level.visible = false
	if refectory_level:
		refectory_level.visible = false
	
	# Ensure main is visible
	if main_level:
		main_level.visible = true
	
	# Add shop kiosk to main level
	if main_level:
		var kiosk = Node2D.new()
		kiosk.name = "ShopKiosk"
		kiosk.position = Vector2(400, 300)  # Center of bazaar
		main_level.add_child(kiosk)
		print("[Floor4] Shop kiosk added at %s" % kiosk.position)
	
	print("[Floor4] Bazaar initialized — level: %s" % floor4_template.get_current_level())

func _setup_floor_ui():
	# Great Lifter repair status
	var lifter_ui = Control.new()
	lifter_ui.name = "GreatLifterUI"
	lifter_ui.position = Vector2(20, 20)
	add_child(lifter_ui)
	_update_great_lifter_ui()
	
	# Level indicator
	var level_ui = Label.new()
	level_ui.name = "LevelIndicator"
	level_ui.position = Vector2(20, 60)
	level_ui.add_theme_font_size_override("font_size", 12)
	add_child(level_ui)
	_update_level_indicator()

func _update_floor_ui():
	_update_great_lifter_ui()
	_update_level_indicator()

func _update_great_lifter_ui():
	var lifter_ui = get_node_or_null("GreatLifterUI")
	if not lifter_ui:
		return
	
	for child in lifter_ui.get_children():
		child.queue_free()
	
	var parts = floor4_template.custom_data.get("collected_parts", [])
	var required = floor4_template.custom_data.get("required_parts", [])
	
	var label = Label.new()
	if floor4_template.is_lifter_repaired():
		label.text = "🔧 Great Lifter: REPAIRED"
		label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	else:
		label.text = "🔧 Great Lifter: %d/%d parts" % [parts.size(), required.size()]
		label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))
	
	lifter_ui.add_child(label)

func _update_level_indicator():
	var level_ui = get_node_or_null("LevelIndicator")
	if not level_ui:
		return
	
	var level = floor4_template.get_current_level()
	match level:
		"main":       level_ui.text = "📍 The Bazaar"
		"undercroft": level_ui.text = "📍 The Undercroft"
		"refectory":  level_ui.text = "📍 The Refectory"
		_:           level_ui.text = "📍 Unknown"
	
	# Color by level danger
	match level:
		"main":       level_ui.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
		"undercroft": level_ui.add_theme_color_override("font_color", Color(0.5, 0.4, 0.6))
		"refectory":  level_ui.add_theme_color_override("font_color", Color(0.6, 0.5, 0.7))

func _transition_to_room(target_room_id: String):
	# Floor4 uses legacy level nodes (MainLevel, Undercroft, Refectory)
	# instead of room instances. Handle visibility and player positioning here.
	if in_transition:
		return
	
	var level_map = {
		"bazaar": "main",
		"undercroft": "undercroft",
		"refectory": "refectory"
	}
	var target_level_name = level_map.get(target_room_id, "")
	if target_level_name.is_empty():
		return
	
	var target_level = get_node_or_null(target_level_name)
	if not target_level:
		return
	
	in_transition = true
	print("[Floor4] Transitioning to level: %s (room_id: %s)" % [target_level_name, target_room_id])
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_sfx"):
		audio_mgr.play_sfx("room_enter")
	
	# Hide current level
	var current_level_name = floor4_template.get_current_level()
	if not current_level_name.is_empty():
		var current_level = get_node_or_null(current_level_name)
		if current_level:
			current_level.visible = false
	
	# Show target level
	target_level.visible = true
	
	# Position player at target's PlayerSpawn marker
	if player_node:
		var spawn = target_level.get_node_or_null("PlayerSpawn")
		if spawn:
			player_node.global_position = spawn.global_position
			print("[Floor4] Player moved to %s spawn: %s" % [target_level_name, spawn.global_position])
	
	# Update current room tracking
	current_room_id = target_room_id
	GameState.save_game()
	
	in_transition = false
	room_changed.emit(target_room_id, target_level_name)

# -------------------------------------------------------------------
# Level Switching
# -------------------------------------------------------------------

func _switch_level(target_level: String, animate: bool = true) -> bool:
	"""Switch to a different level using room transitions."""
	if not floor4_template.is_level_unlocked(target_level):
		print("[Floor4] Level '%s' is locked" % target_level)
		return false
	
	var current = floor4_template.get_current_level()
	if current == target_level:
		return true
	
	print("[Floor4] Switching level: %s → %s" % [current, target_level])
	
	# Map level names to room IDs
	var room_id = ""
	match target_level:
		"main":       room_id = "bazaar"
		"undercroft": room_id = "undercroft"
		"refectory":  room_id = "refectory"
	
	if room_id.is_empty():
		return false
	
	# Use base class room transition
	_transition_to_room(room_id)
	
	# Update state
	floor4_template.set_current_level(target_level)
	
	# Clear booth state when changing levels
	_exit_booth()
	
	# Reset hazard states
	on_aether_slick = false
	
	# Visual feedback
	if animate:
		var msg = ""
		match target_level:
			"undercroft": msg = "You fall through a grate into the pipe tunnels below..."
			"refectory":  msg = "Steam lifts you to the brass balconies above..."
			"main":       msg = "You return to the main floor."
		_show_dialogue("Transition", msg, 2.5)
	
	_update_level_indicator()
	return true

# -------------------------------------------------------------------
# Interaction Override (level-aware)
# -------------------------------------------------------------------

func _check_interactables():
	if not player_node:
		return
	
	var player_pos = player_node.global_position
	var level = floor4_template.get_current_level()
	
	match level:
		"main":
			_check_interactables_main(player_pos)
		"undercroft":
			_check_interactables_undercroft(player_pos)
		"refectory":
			_check_interactables_refectory(player_pos)

func _check_interactables_main(player_pos: Vector2):
	# Check Great Lifter (center)
	var lifter_dist = player_pos.distance_to(Vector2.ZERO)
	if lifter_dist < 120.0:
		if floor4_template.is_lifter_repaired():
			_show_interact_prompt("[S] Enter Great Lifter (Exit)")
		else:
			_show_interact_prompt("[S] Inspect Great Lifter")
		return
	
	# Check level transitions (grates to undercroft, stairs to refectory)
	var exit_name = floor4_template.get_exit_name_at_position("main", player_pos, 80.0)
	if not exit_name.is_empty():
		var target = floor4_template.get_exit_target_level(exit_name)
		var target_name = ""
		match target:
			"undercroft": target_name = "Undercroft"
			"refectory":  target_name = "Refectory"
		_show_interact_prompt("[S] Go to %s" % target_name)
		return
	
	# Check booths
	var booth_id = floor4_template.get_booth_id_at_position(player_pos, 120.0)
	if not booth_id.is_empty():
		var is_vendor = floor4_template.is_real_vendor(booth_id)
		var booth_name = _get_booth_display_name(booth_id)
		if is_vendor:
			_show_interact_prompt("[S] Enter %s" % booth_name)
		else:
			_show_interact_prompt("[S] Enter %s (⚠ Trap)" % booth_name)
		return
	
	_hide_interact_prompt()

func _check_interactables_undercroft(player_pos: Vector2):
	# Check exits back to main
	var exit_name = floor4_template.get_exit_name_at_position("undercroft", player_pos, 80.0)
	if not exit_name.is_empty():
		_show_interact_prompt("[S] Climb to Main Floor")
		return
	
	# Check lootable objects (gear parts hidden in undercroft)
	# Simplified: random chance to find parts when near hazard zones
	
	_hide_interact_prompt()

func _check_interactables_refectory(player_pos: Vector2):
	# Check exits back to main
	var exit_name = floor4_template.get_exit_name_at_position("refectory", player_pos, 80.0)
	if not exit_name.is_empty():
		_show_interact_prompt("[S] Go down to Main Floor")
		return
	
	# Check food stations
	var food = floor4_template.get_food_station_at(player_pos, 60.0)
	if not food.is_empty():
		_show_interact_prompt("[S] Eat %s (+HP, ⚠ Nostalgia)" % food.get("type", "food"))
		return
	
	_hide_interact_prompt()



func _try_interact_main(player_pos: Vector2):
	# Check Great Lifter first
	var lifter_dist = player_pos.distance_to(Vector2.ZERO)
	if lifter_dist < 120.0:
		_interact_great_lifter()
		return
	
	# Check level transitions
	var exit_name = floor4_template.get_exit_name_at_position("main", player_pos, 80.0)
	if not exit_name.is_empty():
		var target = floor4_template.get_exit_target_level(exit_name)
		floor4_template.unlock_level(target)
		_switch_level(target)
		return
	
	# Check booths
	var booth_id = floor4_template.get_booth_id_at_position(player_pos, 120.0)
	if not booth_id.is_empty():
		_enter_booth(booth_id)
		return

func _interact_great_lifter():
	if floor4_template.is_lifter_repaired():
		_show_dialogue("Great Lifter", "The steam elevator rumbles. Step into the cage...", 3.0)
		# Transition to Floor 5
		await get_tree().create_timer(2.0).timeout
		GameState.set_current_floor(5)
		get_tree().change_scene_to_file("res://scenes/Floor5.tscn")
	elif floor4_template.has_all_parts():
		_repair_great_lifter()
	else:
		var needed = floor4_template.custom_data.get("required_parts", [])
		var have = floor4_template.custom_data.get("collected_parts", [])
		var missing = []
		for part in needed:
			if part not in have:
				missing.append(part)
		_show_dialogue("Great Lifter", "Broken. Missing: %s" % ", ".join(missing), 3.0)

func _try_interact_undercroft(player_pos: Vector2):
	var exit_name = floor4_template.get_exit_name_at_position("undercroft", player_pos, 80.0)
	if not exit_name.is_empty():
		_switch_level("main")
		return
	
	# Check for hidden parts (simplified)
	_show_dialogue("Undercroft", "Pipe steam hisses. Something glints in the dark...", 2.0)

func _try_interact_refectory(player_pos: Vector2):
	var exit_name = floor4_template.get_exit_name_at_position("refectory", player_pos, 80.0)
	if not exit_name.is_empty():
		_switch_level("main")
		return
	
	# Eat food
	var food = floor4_template.get_food_station_at(player_pos, 60.0)
	if not food.is_empty():
		_eat_food(food)
		return

func _eat_food(food_data: Dictionary):
	var food_type = food_data.get("type", "food")
	
	# Heal player
	if GameState.has_method("heal_player"):
		GameState.heal_player(10)
	
	# Apply Nostalgia debuff
	has_nostalgia = true
	GameState.add_temp_effect("nostalgia", 5)
	
	_show_dialogue("Food", "The %s tastes like your childhood. +10 HP. You feel... vulnerable." % food_type, 3.0)

# -------------------------------------------------------------------
# Movement Override (level-specific hazards)
# -------------------------------------------------------------------

func _hex_step(move_vec: Vector2):
	var level = floor4_template.get_current_level()
	
	match level:
		"undercroft":
			_hex_step_undercroft(move_vec)
		"refectory":
			_hex_step_refectory(move_vec)
		_:
			# Default main level behavior
			if player_node:
				player_node.position += move_vec * floor4_template.hex_step_size
				last_move_direction = move_vec
				_update_animator(move_vec)

func _hex_step_undercroft(move_vec: Vector2):
	"""Aether Slick: movement randomized on steam vents"""
	var step = floor4_template.hex_step_size
	
	# Check if entering Aether Slick
	var new_pos = player_node.position + move_vec * step
	if floor4_template.is_in_aether_slick(new_pos):
		if not on_aether_slick:
			on_aether_slick = true
			_show_dialogue("Aether Slick", "The aether-fluid shifts beneath you! Movement becomes erratic!", 2.0)
		
		# Randomize movement direction slightly
		var jitter = Vector2(randf() - 0.5, randf() - 0.5) * 0.5
		move_vec = (move_vec + jitter).normalized()
	else:
		on_aether_slick = false
	
	if player_node:
		player_node.position += move_vec * step
		last_move_direction = move_vec
		_update_animator(move_vec)

func _hex_step_refectory(move_vec: Vector2):
	"""Refectory: normal movement but Nostalgia debuff affects display"""
	if player_node:
		player_node.position += move_vec * floor4_template.hex_step_size
		_update_animator(move_vec)
	
	# If player has Nostalgia, show occasional flashbacks (simplified)
	if has_nostalgia and randf() < 0.05:
		_show_dialogue("Memory", "A scent reminds you of something lost...", 1.5)

func _update_animator(move_vec: Vector2):
	var animator = player_node.get_node_or_null("PlayerAnimator")
	if animator:
		var dir_str = _velocity_to_direction(move_vec)
		animator.play_walk(dir_str)
		await get_tree().create_timer(0.15).timeout
		if is_instance_valid(animator):
			animator.play_idle()

# -------------------------------------------------------------------
# Booth System (unchanged from before, but level-aware)
# -------------------------------------------------------------------

func _enter_booth(booth_id: String):
	if in_booth:
		return
	in_booth = true
	active_booth_id = booth_id
	
	# Dynamically load booth scene
	var scene_path = _get_booth_scene_path(booth_id)
	var booth_scene = load(scene_path)
	if not booth_scene:
		print("[Floor4] Failed to load booth scene: %s" % scene_path)
		in_booth = false
		return
	
	active_booth_interior = booth_scene.instantiate()
	active_booth_interior.name = "BoothInterior_%s" % booth_id
	add_child(active_booth_interior)
	
	# Position booth interior over player / center of screen
	if player_node:
		active_booth_interior.global_position = player_node.global_position
	
	# Show booth
	if active_booth_interior.has_method("show_interior"):
		active_booth_interior.show_interior()
	
	# Trap booths trigger combat
	if not floor4_template.is_real_vendor(booth_id):
		if active_booth_interior.has_method("_trigger_trap"):
			active_booth_interior._trigger_trap()
		else:
			_trigger_trap_combat(booth_id)
	
	print("[Floor4] Entered booth: %s" % booth_id)

func _get_booth_scene_path(booth_id: String) -> String:
	return floor4_template.get_booth_scene_path(booth_id)

func _exit_booth():
	if active_booth_interior:
		if active_booth_interior.has_method("hide_interior"):
			active_booth_interior.hide_interior()
		active_booth_interior.queue_free()
		active_booth_interior = null
	
	active_booth_id = ""
	in_booth = false
	print("[Floor4] Exited booth")

func _trigger_trap_combat(booth_id: String):
	var comp = RoomEnemyDatabase.get_floor4_composition(booth_id)
	if comp.get("is_peaceful", false):
		return
	
	var enemy_data = comp.get("enemies", [])
	if enemy_data.is_empty():
		return
	
	in_combat = true
	var player_deck = GameState.player_deck if GameState.get("player_deck") else []
	var combat_manager = $CombatManager if has_node("CombatManager") else null
	
	if combat_manager:
		var combat_enemies: Array = []
		for template in enemy_data:
			if template.has_method("to_combat_data"):
				combat_enemies.append(template.to_combat_data())
		
		combat_manager.start_combat(combat_enemies, player_deck)
		print("[Floor4] Trap booth '%s' combat started" % booth_id)

func _get_booth_display_name(booth_id: String) -> String:
	match booth_id:
		"booth_12": return "The Gearwright"
		"booth_4":  return "The Steam-Press"
		"booth_8":  return "The Curio Collector"
		"booth_1":  return "The Infinity Mirror"
		"booth_2":  return "The Bargain Bin"
		"booth_3":  return "The Timepiece Exchange"
		"booth_5":  return "The Memory Monger"
		"booth_6":  return "The Duplicate Drapers"
		"booth_7":  return "The Glitch Glassworks"
		"booth_9":  return "The Rollback Refinery"
		"booth_10": return "The Sample Crier"
		"booth_11": return "The Reflection Salon"
		_: return "Unknown Booth"

# -------------------------------------------------------------------
# Great Lifter
# -------------------------------------------------------------------

func _on_check_boss_unlock():
	if floor4_template.has_all_parts():
		_repair_great_lifter()

func _repair_great_lifter():
	if floor4_template.is_lifter_repaired():
		return
	
	floor4_template.repair_lifter()
	GameState.repair_great_lifter()
	
	print("[Floor4] GREAT LIFTER REPAIRED!")
	boss_portal_unlocked.emit()
	
	# Update center visual
	var lifter = get_node_or_null("GreatLifter")
	if lifter:
		var status_label = lifter.get_node_or_null("StatusLabel")
		if status_label and status_label is Label:
			status_label.text = "OPERATIONAL"
			status_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	
	_show_dialogue("Great Lifter", "The steam elevator rumbles to life. Floor 5 awaits.", 4.0)

# -------------------------------------------------------------------
# Vendor Dialogue
# -------------------------------------------------------------------

func _on_object_interact(object_type: String):
	match object_type:
		"Talk to Gearwright":
			_show_dialogue("Gearwright", "Construct cards and gear parts. One part: 10 Quiddity.", 3.0)
		"Talk to Steam-Press":
			_show_dialogue("Steam-Press", "Tonics! Heal 10 HP for 5 Quiddity. Bargain!", 3.0)
		"Talk to Curio Collector":
			_show_dialogue("Curio Collector", "Memory cards... rare. Expensive. Worth it.", 3.0)
		"Open Shop":
			_open_shop()
		"Save Game":
			if GameState.has_method("save_game"):
				GameState.save_game()
			_show_dialogue("Save", "Progress saved.", 2.0)
		_:
			print("[Floor4] Unknown interaction: %s" % object_type)

# -------------------------------------------------------------------
# Input Override (booth exit + level transitions)
# -------------------------------------------------------------------

func _input(event: InputEvent):
	# If in booth, ESC or S exits
	if in_booth and not in_combat:
		if event is InputEventKey and event.pressed:
			match event.keycode:
				KEY_ESCAPE, KEY_S:
					_exit_booth()
					get_viewport().set_input_as_handled()
					return
	
	# Otherwise use base class input
	super._input(event)

# -------------------------------------------------------------------
# Part Collection
# -------------------------------------------------------------------

func collect_part(part_name: String):
	floor4_template.collect_part(part_name)
	GameState.collect_lifter_part(part_name)
	_update_great_lifter_ui()
	_on_check_boss_unlock()

# -------------------------------------------------------------------
# Public API
# -------------------------------------------------------------------

func is_lifter_repaired() -> bool:
	return floor4_template.is_lifter_repaired()

func get_active_booth_id() -> String:
	return active_booth_id

func is_in_booth() -> bool:
	return in_booth

func get_current_level_name() -> String:
	return floor4_template.get_current_level()

func force_level_switch(target: String):
	"""For trap dumps and Lifter misfires."""
	floor4_template.unlock_level(target)
	_switch_level(target)
