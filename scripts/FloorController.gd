extends Node2D
class_name FloorController

# ===================================================================
# FLOOR CONTROLLER — Base class for all floor controllers
# ===================================================================
# Handles shared functionality:
#   - Hex-based movement (WEADZX)
#   - Player setup (CharacterBody2D + sprite + animator)
#   - Room instantiation and management
#   - Room transitions
#   - Combat integration with CombatManager
#   - Interaction system (proximity detection, prompts)
#   - UI setup (interact prompt, transit tokens, etc.)
#
# Each floor provides a FloorTemplate subclass that defines:
#   - Room scene paths, positions, connections
#   - Floor metadata (ID, name, starting room)
#   - Floor-specific interactable mappings
#
# Floor-specific logic (dial rotation, trap booths, tutorial sequences)
# goes in the child controller class.
#
# THIS GAME IS HEX-BASED. EVERY FLOOR IS HEX-BASED.
# DO NOT CHANGE MOVEMENT TO WASD/ARROWS.
# ===================================================================

# -------------------------------------------------------------------
# Template reference — set by child controller in _ready() or exported
# -------------------------------------------------------------------
var floor_template: FloorTemplate

# -------------------------------------------------------------------
# State
# -------------------------------------------------------------------
var rooms: Dictionary = {}          # room_id -> room_node
var current_room_id: String = ""
var player_node: Node2D
var in_combat: bool = false
var in_transition: bool = false
var in_ui: bool = false             # Set by child when shop/dialogue/puzzle is active

# -------------------------------------------------------------------
# Interaction
# -------------------------------------------------------------------
var nearby_interactable: Node = null
var interactable_type: String = ""
var interact_prompt: Label
var pause_menu: CanvasLayer
var is_paused: bool = false

# -------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------
signal room_changed(room_id: String, room_name: String)
signal boss_portal_unlocked

# -------------------------------------------------------------------
# Lifecycle
# -------------------------------------------------------------------

func _ready():
	call_deferred("_build_floor")

func _build_floor():
	if not floor_template:
		push_error("FloorController: No floor_template assigned!")
		return
	
	# Instantiate all rooms from template
	for room_id in floor_template.get_all_room_ids():
		var scene_path = floor_template.get_room_scene_path(room_id)
		if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
			push_warning("[FloorController] Room scene not found: %s" % scene_path)
			continue
		
		var scene = load(scene_path)
		var room = scene.instantiate()
		room.room_id = room_id
		room.position = floor_template.get_room_position(room_id)
		
		# Wire signals
		if room.has_signal("room_entered"):
			room.room_entered.connect(_on_room_entered.bind(room_id))
		if room.has_signal("room_exited"):
			room.room_exited.connect(_on_room_exited.bind(room_id))
		if room.has_signal("room_cleared"):
			room.room_cleared.connect(_on_room_cleared.bind(room_id))
		if room.has_signal("transit_token_given"):
			room.transit_token_given.connect(_on_transit_token_given)
		if room.has_signal("encounter_started"):
			room.encounter_started.connect(_on_encounter_started.bind(room_id))
		if room.has_signal("encounter_ended"):
			room.encounter_ended.connect(_on_encounter_ended.bind(room_id))
		
		add_child(room)
		rooms[room_id] = room
		print("[FloorController] Room '%s' at %s" % [room_id, room.position])
	
	# Setup shared systems
	_setup_combat()
	_setup_ui()
	_setup_shop()
	
	# Start floor ambient music (before player placement, will be overwritten by combat if needed)
	if floor_template and floor_template.floor_id > 0:
		AudioManager.play_floor_ambient(floor_template.floor_id)
	
	_setup_player()
	
	# Floor-specific initialization (child override)
	_setup_floor_specific()
	
	# Trigger room entry AFTER floor-specific setup is complete
	# This ensures the player is in the correct position before combat starts
	var start_room = rooms.get(current_room_id)
	if start_room and start_room.has_method("on_player_entered"):
		start_room.on_player_entered()
		print("[FloorController] Player entered room: %s" % current_room_id)


# -------------------------------------------------------------------
# Player Setup
# -------------------------------------------------------------------

func _setup_player():
	player_node = get_tree().get_first_node_in_group("player")
	
	if not player_node:
		player_node = CharacterBody2D.new()
		player_node.name = "Player"
		player_node.z_index = 100
		player_node.add_to_group("player")
		
		var collision = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 12.0
		collision.shape = circle
		player_node.add_child(collision)
		
		# Set collision layers for proper wall collision
		player_node.collision_layer = 2  # Player layer
		player_node.collision_mask = 1   # Collide with World layer
		
		var player_sprite = Sprite2D.new()
		player_sprite.name = "PlayerSprite"
		player_sprite.centered = true
		player_sprite.scale = Vector2(3.0, 3.0)
		player_node.add_child(player_sprite)
		
		var animator = Node2D.new()
		animator.name = "PlayerAnimator"
		animator.set_script(preload("res://scripts/PlayerAnimator.gd"))
		player_node.add_child(animator)
		
		var shadow = Polygon2D.new()
		shadow.name = "Shadow"
		shadow.polygon = PackedVector2Array([
			Vector2(-15, 25), Vector2(15, 25),
			Vector2(10, 35), Vector2(-10, 35)
		])
		shadow.color = Color(0.0, 0.0, 0.0, 0.3)
		shadow.z_index = -1
		player_node.add_child(shadow)
		
		add_child(player_node)
		print("[FloorController] Player created")
	
	# Place player at starting room
	var start_room = rooms.get(floor_template.starting_room_id)
	if start_room and start_room.has_method("get_player_spawn_position"):
		player_node.global_position = start_room.get_player_spawn_position()
		current_room_id = floor_template.starting_room_id
		print("[FloorController] Player placed at starting room: %s" % current_room_id)
		# NOTE: on_player_entered() is called in _build_floor() AFTER _setup_floor_specific()
		# to ensure floor-specific setup (like Floor 3's Room 12 placement) is done first

# -------------------------------------------------------------------
# Combat Setup
# -------------------------------------------------------------------

func _setup_combat():
	var combat_manager = $CombatManager if has_node("CombatManager") else null
	var combat_ui = $CombatUI if has_node("CombatUI") else null
	
	if combat_ui and combat_ui.has_method("setup") and combat_manager:
		combat_ui.setup(combat_manager)
	
	if combat_manager and combat_manager.has_signal("combat_started"):
		combat_manager.combat_started.connect(_on_combat_started)
	
	if combat_manager and combat_manager.has_signal("combat_ended"):
		combat_manager.combat_ended.connect(_on_combat_ended)

# -------------------------------------------------------------------
# UI Setup
# -------------------------------------------------------------------

func _setup_ui():
	interact_prompt = Label.new()
	interact_prompt.name = "InteractPrompt"
	interact_prompt.position = Vector2(540, 620)
	interact_prompt.size = Vector2(200, 30)
	interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_prompt.add_theme_font_size_override("font_size", 14)
	interact_prompt.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	interact_prompt.visible = false
	add_child(interact_prompt)
	
	# Pause menu setup
	_setup_pause_menu()
	
	# Floor-specific UI (child override)
	_setup_floor_ui()

# -------------------------------------------------------------------
# Hex Movement (WEADZX)
# -------------------------------------------------------------------

func _input(event: InputEvent):
	if in_combat or in_transition:
		return
	
	if event is InputEventKey and event.pressed:
		var move_vec = Vector2.ZERO
		match event.keycode:
			KEY_ESCAPE:
				_toggle_pause_menu()
				return
			KEY_E: move_vec = Vector2(0.866, -0.5)    # Northeast
			KEY_W: move_vec = Vector2(-0.866, -0.5)   # Northwest
			KEY_A: move_vec = Vector2(-1, 0)          # West
			KEY_D: move_vec = Vector2(1, 0)           # East
			KEY_Z: move_vec = Vector2(-0.866, 0.5)    # Southwest
			KEY_X: move_vec = Vector2(0.866, 0.5)     # Southeast
			KEY_S, KEY_SPACE:
				_try_interact()
				return
		
		if move_vec != Vector2.ZERO:
			_hex_step(move_vec)
			_check_interactables()

func _hex_step(move_vec: Vector2):
	if not player_node:
		return
	
	# Convert current position to hex, then move one hex in the direction
	var current_hex = HexTileMap.world_to_hex(player_node.global_position)
	var direction = _vector_to_hex_dir(move_vec)
	var dirs = HexGrid.DIRECTIONS
	var target_hex = current_hex + dirs[direction]
	
	# Check if target hex is walkable
	var hex_map = get_node_or_null("HexTileMap")
	if hex_map and hex_map.is_wall(target_hex):
		# Can't move into wall - play bump animation?
		return
	
	# Snap to hex center
	var target_world = HexTileMap.hex_to_world(target_hex)
	player_node.global_position = target_world
	
	var animator = player_node.get_node_or_null("PlayerAnimator")
	if animator:
		var dir_str = _velocity_to_direction(move_vec)
		animator.play_walk(dir_str)
		# Movement timer: reset on each step, only play idle after 0.2s of no movement
		if not animator.has_meta("move_timer"):
			animator.set_meta("move_timer", 0.0)
		animator.set_meta("move_timer", 0.2)

func _velocity_to_direction(velocity: Vector2) -> String:
	var angle = velocity.angle()
	var degrees = rad_to_deg(angle)
	if degrees >= -22.5 and degrees < 22.5:       return "e"
	elif degrees >= 22.5 and degrees < 67.5:     return "se"
	elif degrees >= 67.5 and degrees < 112.5:    return "s"
	elif degrees >= 112.5 and degrees < 157.5:   return "sw"
	elif degrees >= 157.5 or degrees < -157.5:    return "w"
	elif degrees >= -157.5 and degrees < -112.5: return "nw"
	elif degrees >= -112.5 and degrees < -67.5:  return "n"
	else:                                         return "ne"

func _vector_to_hex_dir(velocity: Vector2) -> int:
	"""Convert a movement vector to hex direction index (0-5)"""
	var angle = velocity.angle()
	var degrees = rad_to_deg(angle)
	
	# Match with WEADZX directions
	# E (NE): 30°, W (NW): 150°, A (W): 180°, D (E): 0°, Z (SW): -150°, X (SE): -30°
	if degrees >= -15 and degrees < 15:         return 3    # E (East) -> D
	elif degrees >= 15 and degrees < 75:        return 1    # NE -> E
	elif degrees >= 75 and degrees < 135:       return 0    # N -> W (closest)
	elif degrees >= 135 and degrees < 180:      return 2    # NW -> A
	elif degrees >= -180 and degrees < -135:    return 4    # W -> Z (closest)
	elif degrees >= -135 and degrees < -75:     return 4    # SW -> Z
	elif degrees >= -75 and degrees < -15:      return 5    # SE -> X
	else:                                        return 3    # default E

func _physics_process(_delta: float):
	if in_combat or in_transition or in_ui or not player_node:
		return
	_check_interactables()

func _process(_delta: float):
	# Camera follows player
	if player_node:
		var camera = get_node_or_null("Camera2D")
		if camera:
			camera.global_position = player_node.global_position
	
	# Movement idle timer - only play idle when no movement for 0.2s
	var animator = player_node.get_node_or_null("PlayerAnimator") if player_node else null
	if animator and animator.has_meta("move_timer"):
		var timer = animator.get_meta("move_timer") - _delta
		if timer <= 0:
			animator.play_idle()
			animator.set_meta("move_timer", 0.0)
		else:
			animator.set_meta("move_timer", timer)

# -------------------------------------------------------------------
# Interaction System
# -------------------------------------------------------------------

func _check_interactables():
	var current_room = rooms.get(current_room_id)
	if not current_room or not player_node:
		return
	
	var player_pos = player_node.global_position
	var closest_type = ""
	var closest_dist = floor_template.interact_range if floor_template else 80.0
	var found_object = false
	
	# Check interior for known interactable nodes by name
	var interior = current_room.get_node_or_null("Interior")
	if interior:
		for child in interior.get_children():
			var type = _get_interactable_type(child.name)
			if not type.is_empty() and not _is_portal_node(child.name):
				var dist = player_pos.distance_to(child.global_position)
				if dist < closest_dist:
					closest_dist = dist
					closest_type = type
					found_object = true
	
	# Check portal exit
	if current_room.has_method("get_exit_position"):
		var portal_pos = current_room.get_exit_position()
		var portal_dist = player_pos.distance_to(portal_pos)
		if portal_dist < closest_dist:
			_show_interact_prompt("[S] Enter Portal")
			return
	
	if found_object:
		interactable_type = closest_type
		_show_interact_prompt("[S] %s" % closest_type)
	else:
		interactable_type = ""
		_hide_interact_prompt()

func _get_interactable_type(node_name: String) -> String:
	# First check floor template for custom mappings
	if floor_template:
		var label = floor_template.get_interactable_label(node_name)
		if not label.is_empty():
			return label
	
	# Default fallback mappings
	match node_name:
		"NPC_Construct": return "Talk to Construct"
		"ShopKiosk": return "Open Shop"
		"Chest": return "Open Chest"
		"BreakableWall": return "Break Wall"
		"TheDoor": return "Approach Door"
		"Droplet": return "Receive Blessing"
		"SavePoint": return "Save Game"
		"Altar": return "Make Offering"
		_: return ""

func _is_portal_node(node_name: String) -> bool:
	if floor_template:
		return floor_template.is_portal_node(node_name)
	return node_name in ["MainPortal", "PortalNorth", "PortalEast", "PortalSouth", "PortalWest", "ReturnPortal"]

func _show_interact_prompt(text: String):
	if interact_prompt:
		interact_prompt.text = text
		interact_prompt.visible = true

func _hide_interact_prompt():
	if interact_prompt:
		interact_prompt.visible = false

func _try_interact():
	if not player_node:
		return
	
	var current = rooms.get(current_room_id)
	if not current:
		return
	
	# Check portal proximity first
	if current.has_method("get_exit_position"):
		var portal_pos = current.get_exit_position()
		var dist = player_node.global_position.distance_to(portal_pos)
		
		var threshold = floor_template.hex_step_size * 3.0 if floor_template else 180.0
		if dist < threshold:
			var connections = floor_template.get_room_connections(current_room_id)
			for dir_name in connections.keys():
				_on_portal_interact(dir_name)
				return
	
	# If not near portal, interact with nearby object
	if not interactable_type.is_empty():
		_on_object_interact(interactable_type)

# -------------------------------------------------------------------
# Room Transitions
# -------------------------------------------------------------------

func _on_portal_interact(portal_direction: String):
	if in_transition or in_combat:
		return
	
	var connections = floor_template.get_room_connections(current_room_id)
	var target_room_id = connections.get(portal_direction, "")
	
	if target_room_id.is_empty():
		return
	
	var current = rooms.get(current_room_id)
	if current and current.has_method("is_portal_locked"):
		if current.is_portal_locked(portal_direction):
			print("[FloorController] Portal locked: %s" % portal_direction)
			return
	
	_transition_to_room(target_room_id)

func _transition_to_room(target_room_id: String):
	if in_transition:
		return
	
	var target_room = rooms.get(target_room_id)
	if not target_room:
		return
	
	in_transition = true
	print("[FloorController] Transitioning to: %s" % target_room_id)
	AudioManager.play_sfx("room_enter")
	
	var current_room = rooms.get(current_room_id)
	if current_room:
		if current_room.has_method("on_player_exited"):
			current_room.on_player_exited()
		if in_combat and current_room.has_method("despawn_enemies"):
			current_room.despawn_enemies()
			in_combat = false
	
	if player_node and target_room.has_method("get_player_spawn_position"):
		player_node.global_position = target_room.get_player_spawn_position()
	
	if target_room.has_method("on_player_entered"):
		target_room.on_player_entered()
	
	current_room_id = target_room_id
	GameState.save_game()
	
	in_transition = false
	room_changed.emit(target_room_id, target_room.room_display_name if target_room.has_method("get") else target_room_id)

# -------------------------------------------------------------------
# Room Events
# -------------------------------------------------------------------

func _on_room_entered(room_id: String):
	print("[FloorController] Entered room: %s" % room_id)
	current_room_id = room_id

func _on_room_exited(room_id: String):
	print("[FloorController] Exited room: %s" % room_id)

func _on_room_cleared(room_id: String):
	print("[FloorController] Room cleared: %s" % room_id)
	if GameState.has_method("mark_room_cleared"):
		GameState.mark_room_cleared(room_id)
	_on_check_boss_unlock()

func _on_transit_token_given(token_name: String):
	print("[FloorController] Got token: %s" % token_name)
	_update_floor_ui()
	_on_check_boss_unlock()

# -------------------------------------------------------------------
# Combat
# -------------------------------------------------------------------

func _start_combat_with_enemies(enemy_names: Array[String], is_boss_fight: bool = false):
	"""Start combat with a specific list of enemy names (for special floor mechanics)."""
	# Check No Aggro state
	if GameState.is_no_aggro():
		print("[FloorController] No Aggro active — skipping combat trigger")
		return
	
	if in_combat:
		print("[FloorController] Already in combat, skipping")
		return
	
	in_combat = true
	
	# Determine music
	var boss_key := ""
	if is_boss_fight:
		for ename in enemy_names:
			var key = AudioManager.get_boss_key_for_enemy(ename)
			if not key.is_empty():
				boss_key = key
				break
		if boss_key.is_empty():
			boss_key = "_fallback"
		AudioManager.play_boss(boss_key)
	elif floor_template and floor_template.floor_id > 0:
		AudioManager.play_combat(floor_template.floor_id)
	
	var player_deck = GameState.player_deck if GameState.get("player_deck") else []
	
	var combat_manager = $CombatManager if has_node("CombatManager") else null
	if not combat_manager:
		push_warning("[FloorController] No CombatManager node found!")
		in_combat = false
		return
	
	var combat_enemies: Array = []
	for enemy_name in enemy_names:
		if RoomEnemyDatabase.ENEMIES.has(enemy_name):
			var template = RoomEnemyDatabase.ENEMIES[enemy_name]
			combat_enemies.append(template.to_combat_data())
		else:
			push_warning("[FloorController] Unknown enemy '%s', skipping" % enemy_name)
	
	if combat_enemies.is_empty():
		print("[FloorController] No valid enemies — skipping combat")
		in_combat = false
		return
	
	combat_manager.start_combat(combat_enemies, player_deck)

func _on_encounter_started(enemy_names: Array, room_id: String = ""):
	# Godot 4 bind() appends args after signal args, so enemy_names comes first
	var rid = room_id if not room_id.is_empty() else current_room_id
	
	# Check No Aggro state
	if GameState.is_no_aggro():
		print("[FloorController] No Aggro active — encounter ignored")
		return
	
	print("[FloorController] Combat started in '%s' against: %s" % [rid, ", ".join(enemy_names)])
	in_combat = true
	
	# Determine music: boss or combat
	var is_boss_fight := false
	var boss_key := ""
	if floor_template and floor_template.floor_id > 0:
		var comp = RoomEnemyDatabase.get_floor_composition(floor_template.floor_id, rid)
		if comp.get("is_boss", false):
			is_boss_fight = true
			# Determine which boss from enemy names
			for ename in enemy_names:
				var key = AudioManager.get_boss_key_for_enemy(ename)
				if not key.is_empty():
					boss_key = key
					break
			if boss_key.is_empty():
				boss_key = "_fallback"
	
	# Play appropriate music
	if is_boss_fight and not boss_key.is_empty():
		AudioManager.play_boss(boss_key)
		print("[FloorController] Boss music: %s" % boss_key)
	elif floor_template and floor_template.floor_id > 0:
		AudioManager.play_combat(floor_template.floor_id)


	
	var comp = RoomEnemyDatabase.get_floor_composition(floor_template.floor_id, rid)
	var enemy_data = comp.get("enemies", []) if comp is Dictionary else []
	
	if enemy_data.is_empty():
		print("[FloorController] No enemies — skipping combat")
		in_combat = false
		return
	
	var player_deck = GameState.player_deck if GameState.get("player_deck") else []
	
	var combat_manager = $CombatManager if has_node("CombatManager") else null
	if not combat_manager:
		push_warning("[FloorController] No CombatManager node found!")
		in_combat = false
		return
	
	var combat_enemies: Array = []
	for template in enemy_data:
		if template.has_method("to_combat_data"):
			combat_enemies.append(template.to_combat_data())
	
	combat_manager.start_combat(combat_enemies, player_deck)

func _on_combat_started():
	"""Virtual: Called when combat begins. Override in child classes."""
	pass

func _on_combat_ended(victory: bool):
	print("[FloorController] Combat ended — victory: %s" % victory)
	in_combat = false
	# Return to floor ambient
	if floor_template and floor_template.floor_id > 0:
		AudioManager.return_to_ambient()
	if victory:
		var room = rooms.get(current_room_id)
		if room and room.has_method("mark_cleared"):
			room.mark_cleared()

func _on_encounter_ended(victory: bool, room_id: String = ""):
	# Godot 4 bind() appends args after signal args
	var rid = room_id if not room_id.is_empty() else current_room_id
	
	print("[FloorController] Encounter ended in '%s' — victory: %s" % [rid, victory])
	in_combat = false
	# Return to floor ambient
	if floor_template and floor_template.floor_id > 0:
		AudioManager.return_to_ambient()
	if victory:
		var room = rooms.get(rid)
		if room and room.has_method("mark_cleared"):
			room.mark_cleared()

# -------------------------------------------------------------------
# Pause Menu
# -------------------------------------------------------------------

func _setup_pause_menu():
	pause_menu = CanvasLayer.new()
	pause_menu.name = "PauseMenu"
	pause_menu.visible = false
	pause_menu.layer = 100
	pause_menu.process_mode = PROCESS_MODE_ALWAYS  # CRITICAL: UI must work when paused
	
	var bg = ColorRect.new()
	bg.name = "PauseBG"
	bg.color = Color(0, 0, 0, 0.7)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.process_mode = PROCESS_MODE_ALWAYS
	pause_menu.add_child(bg)
	
	var container = VBoxContainer.new()
	container.name = "PauseContainer"
	container.anchors_preset = Control.PRESET_CENTER
	container.position = Vector2(860, 440)
	container.size = Vector2(200, 200)
	container.process_mode = PROCESS_MODE_ALWAYS
	pause_menu.add_child(container)
	
	var title = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	title.process_mode = PROCESS_MODE_ALWAYS
	container.add_child(title)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	spacer.process_mode = PROCESS_MODE_ALWAYS
	container.add_child(spacer)
	
	var resume_btn = Button.new()
	resume_btn.text = "Resume"
	resume_btn.pressed.connect(_toggle_pause_menu)
	resume_btn.process_mode = PROCESS_MODE_ALWAYS
	container.add_child(resume_btn)
	
	var save_btn = Button.new()
	save_btn.text = "Save Game"
	save_btn.pressed.connect(_pause_save)
	save_btn.process_mode = PROCESS_MODE_ALWAYS
	container.add_child(save_btn)
	
	var quit_btn = Button.new()
	quit_btn.text = "Quit to Title"
	quit_btn.pressed.connect(_pause_quit)
	quit_btn.process_mode = PROCESS_MODE_ALWAYS
	container.add_child(quit_btn)
	
	add_child(pause_menu)

func _toggle_pause_menu():
	is_paused = not is_paused
	if pause_menu:
		pause_menu.visible = is_paused
	get_tree().paused = is_paused

func _pause_save():
	GameState.save_game()
	_show_notification("Game saved!")

func _pause_quit():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")

# -------------------------------------------------------------------
# Virtual Methods — Override in child controllers
# -------------------------------------------------------------------

func _setup_floor_specific():
	"""Override for floor-specific initialization."""
	pass

func _setup_floor_ui():
	"""Override for floor-specific UI (transit tokens, tutorial overlays, etc.)"""
	pass

func _setup_shop():
	"""Add MachinistShopUI to the floor. Override in child if floor has custom shop."""
	var shop_script = load("res://scripts/MachinistShopUI.gd")
	if shop_script:
		var shop_ui = shop_script.new()
		shop_ui.name = "MachinistShop"
		shop_ui.visible = false
		shop_ui.shop_closed.connect(_on_shop_closed)
		add_child(shop_ui)
		print("[FloorController] Shop UI added for floor %d" % floor_template.floor_id if floor_template else 0)

func _on_shop_closed():
	in_ui = false

func _update_floor_ui():
	"""Override for updating floor-specific UI state."""
	pass

func _on_check_boss_unlock():
	"""Override for checking boss unlock conditions."""
	pass

func _on_object_interact(object_type: String):
	"""Override for handling object interactions.
	Default implementation handles common types, child controllers extend for floor-specific."""
	match object_type:
		"Open Shop":
			_open_shop()
		"Save Game":
			GameState.save_game()
			_show_dialogue("Save Point", "Progress saved.")
		_:
			_show_dialogue("Object", "You interact with the %s." % object_type)

func _open_shop():
	"""Open the MachinistShopUI if available."""
	var shop = get_node_or_null("MachinistShop")
	if shop and shop.has_method("show_shop"):
		in_ui = true
		shop.show_shop()
	else:
		push_warning("[FloorController] No shop UI found!")

# -------------------------------------------------------------------
# Notifications
# -------------------------------------------------------------------

func _show_notification(text: String, color: Color = Color(1, 1, 1), duration: float = 3.0):
	var label = Label.new()
	label.name = "NotificationLabel"
	label.text = text
	label.position = Vector2(560, 100)
	label.size = Vector2(800, 60)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	label.add_theme_constant_override("shadow_outline_size", 4)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.size = Vector2(800, 60)
	bg.position = Vector2(560, 100)
	bg.z_index = -1
	
	add_child(bg)
	add_child(label)
	
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(label): label.queue_free()
	if is_instance_valid(bg): bg.queue_free()

# -------------------------------------------------------------------
# Utility
# -------------------------------------------------------------------

func _show_dialogue(speaker: String, text: String, duration: float = 3.0):
	var dialogue = Label.new()
	dialogue.name = "DialoguePopup"
	dialogue.text = "%s: %s" % [speaker, text]
	dialogue.position = Vector2(660, 500)
	dialogue.size = Vector2(600, 80)
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue.add_theme_font_size_override("font_size", 16)
	dialogue.add_theme_color_override("font_color", Color(1, 1, 1))
	dialogue.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	dialogue.add_theme_constant_override("shadow_outline_size", 4)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.size = Vector2(600, 80)
	bg.position = Vector2(660, 500)
	bg.z_index = -1
	
	add_child(bg)
	add_child(dialogue)
	
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(dialogue): dialogue.queue_free()
	if is_instance_valid(bg): bg.queue_free()

func _enter_room(room_id):
	"""Override point for floor-specific room entry logic."""
	pass

func _ending_true():
	"""Override point for true ending logic."""
	pass



func get_current_room():
	return rooms.get(current_room_id)

func move_player_to_room(room_id: String):
	if floor_template.has_room(room_id):
		_transition_to_room(room_id)

func is_player_in_combat() -> bool:
	return in_combat

func set_ui_active(active: bool):
	"""Child controllers call this when opening shops/dialogues/puzzles
	to disable movement and interaction."""
	in_ui = active
	if active:
		_hide_interact_prompt()
