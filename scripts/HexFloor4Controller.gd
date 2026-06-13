extends Node2D

# ===================================================================
# FLOOR 4 CONTROLLER — Hex-Based — The Curio Bazaar (Three Levels)
# ===================================================================
# Three sub-levels connected by stairs and the Great Lifter:
#   main       — Circular bazaar, 12 booths, Great Lifter center
#   undercroft — Pipe tunnels below, Aether Slick hazards, gear parts
#   refectory  — Brass balconies above, memory-food, Nostalgia debuff
# ===================================================================

# -------------------------------------------------------------------
# Hex Grid
# -------------------------------------------------------------------
@onready var hex_map: HexTileMap = $HexTileMap

# -------------------------------------------------------------------
# State
# -------------------------------------------------------------------
var player_node: Node2D
var current_level: String = "main"  # "main" | "undercroft" | "refectory"
var current_room_id: String = "f4_main"
var in_combat: bool = false
var in_transition: bool = false
var in_ui: bool = false
var is_paused: bool = false

# Click-to-Move path following state
var path_movement_active: bool = false
var path_movement_target: Array[Vector2i] = []
var path_movement_index: int = 0
var path_movement_timer: float = 0.0
const PATH_MOVE_STEP_INTERVAL: float = 0.12

# Great Lifter (elevator) repair state
var lifter_repaired: bool = false
var required_parts: Array[String] = ["gear_part_1", "gear_part_2", "steam_valve"]
var collected_parts: Array[String] = []

# Aether Slick state (undercroft)
var on_aether_slick: bool = false

# Nostalgia debuff (refectory)
var has_nostalgia: bool = false

# Booth state
var in_booth: bool = false
var active_booth_id: String = ""

# Level data: center hex, radius, encounter type
var level_data: Dictionary = {
	"f4_main":       {"center": Vector2i(0, 0),    "radius": 12, "encounter": "none",    "display": "The Bazaar", "level": "main"},
	"f4_undercroft": {"center": Vector2i(0, 30),    "radius": 10, "encounter": "construct", "display": "The Undercroft", "level": "undercroft"},
	"f4_refectory":  {"center": Vector2i(0, -30),   "radius": 10, "encounter": "none",    "display": "The Refectory", "level": "refectory"},
}

# Stair connections: level -> direction -> target level
var stair_connections: Dictionary = {
	"main":       {"down": "f4_undercroft", "up": "f4_refectory"},
	"undercroft": {"up": "f4_main"},
	"refectory":  {"down": "f4_main"},
}

# Stair hex offsets from level center
var stair_offsets: Dictionary = {
	"down": Vector2i(0, 10),
	"up":   Vector2i(0, -10),
}

# Booth positions (12 booths around main level perimeter)
var booth_hex_positions: Dictionary = {
	"booth_12": Vector2i(0, -14),    # 12 o'clock
	"booth_1":  Vector2i(7, -12),     # 1 o'clock
	"booth_2":  Vector2i(12, -7),     # 2 o'clock
	"booth_3":  Vector2i(14, 0),      # 3 o'clock
	"booth_4":  Vector2i(12, 7),      # 4 o'clock
	"booth_5":  Vector2i(7, 12),      # 5 o'clock
	"booth_6":  Vector2i(0, 14),      # 6 o'clock
	"booth_7":  Vector2i(-7, 12),     # 7 o'clock
	"booth_8":  Vector2i(-12, 7),    # 8 o'clock
	"booth_9":  Vector2i(-14, 0),     # 9 o'clock
	"booth_10": Vector2i(-12, -7),    # 10 o'clock
	"booth_11": Vector2i(-7, -12),    # 11 o'clock
}

var real_vendors: Array[String] = ["booth_12", "booth_4", "booth_8"]
var trap_booths: Array[String] = ["booth_1", "booth_2", "booth_3", "booth_5", "booth_6", "booth_7", "booth_9", "booth_10", "booth_11"]

# Level encounter state
var level_cleared: Dictionary = {}
var level_encounter_spawned: Dictionary = {}

# Hex enemies on the grid
var hex_enemies: Array[HexEnemy] = []
var enemy_container: Node2D

# Ambush state
var ambush_bonus: bool = false

# -------------------------------------------------------------------
# UI
# -------------------------------------------------------------------
var interact_prompt: Label
var pause_menu: CanvasLayer
var lifter_ui: Control

# -------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------
signal room_changed(room_id: String, room_name: String)
signal level_changed(level_name: String)

# ===================================================================
# LIFECYCLE
# ===================================================================

func _ready():
	call_deferred("_build_floor")

func _build_floor():
	# Generate hex layout
	if hex_map:
		hex_map.generate_floor4_layout()
		print("[Floor4-Hex] Hex grid generated: %d tiles" % hex_map.grid.size())
	
	# Setup systems
	_setup_combat()
	_setup_ui()
	_setup_player()
	_setup_floor_specific()
	_setup_enemies()  # Spawn hex enemies
	
	# Start music
	AudioManager.play_floor_ambient(4)
	
	# Enter starting level
	_enter_level("main", "f4_main")

# ===================================================================
# PLAYER
# ===================================================================

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
		
		player_node.collision_layer = 2
		player_node.collision_mask = 1
		
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
		print("[Floor4-Hex] Player created")
	
	# Place at main level center
	var main_center = level_data["f4_main"]["center"]
	player_node.global_position = hex_map.hex_to_world(main_center)
	print("[Floor4-Hex] Player placed at main level: %s" % str(main_center))

func _setup_enemies():
	"""Spawn enemies on the hex grid for each level."""
	enemy_container = Node2D.new()
	enemy_container.name = "EnemyContainer"
	add_child(enemy_container)
	
	# Spawn enemies per level
	var enemy_spawns = {
		"f4_undercroft": [
			{"name": "Construct", "hex": Vector2i(-2, 32), "faction": "Construct"},
			{"name": "Construct", "hex": Vector2i(2, 28), "faction": "Construct"},
		],
		"f4_main": [
			{"name": "Construct", "hex": Vector2i(5, 0), "faction": "Construct"},
		],
	}
	
	for level_id in enemy_spawns.keys():
		for spawn_data in enemy_spawns[level_id]:
			var enemy = HexEnemy.new(
				spawn_data["name"] + "_%d" % hex_enemies.size(),
				spawn_data["name"],
				spawn_data["hex"],
				spawn_data.get("faction", "Unknown"),
				spawn_data.get("boss", false)
			)
			enemy.name = "HexEnemy_%d" % hex_enemies.size()
			
			# Configure enemy stats
			if spawn_data["name"] == "Construct":
				enemy.max_hp = 14 + randi() % 6
				enemy.hp = enemy.max_hp
				enemy.attack = 3 + randi() % 3
				enemy.defense = 1 + randi() % 2
			
			enemy_container.add_child(enemy)
			enemy.set_hex_map_position(spawn_data["hex"], hex_map)
			
			# Connect signals
			enemy.combat_initiated.connect(_on_enemy_combat_initiated)
			
			hex_enemies.append(enemy)
			print("[Floor4-Hex] Spawned %s at %s" % [spawn_data["name"], str(spawn_data["hex"])])
	
	print("[Floor4-Hex] %d hex enemies spawned" % hex_enemies.size())

# ===================================================================
# COMBAT
# ===================================================================

func _setup_combat():
	var combat_manager = get_node_or_null("CombatManager")
	if combat_manager:
		combat_manager.combat_ended.connect(_on_combat_ended)
		print("[Floor4-Hex] CombatManager wired")

func _start_combat(encounter_type: String):
	if in_combat:
		return
	
	var enemies = _get_encounter_enemies(encounter_type)
	if enemies.is_empty():
		return
	
	in_combat = true
	var combat_manager = get_node_or_null("CombatManager")
	if combat_manager:
		combat_manager.start_combat(enemies, GameState.player_deck)
		var ui = get_node_or_null("CombatUI")
		if ui:
			ui.setup(combat_manager)
			ui.visible = true
		AudioManager.play_combat(4)
		print("[Floor4-Hex] Combat started: %s" % encounter_type)

func _get_encounter_enemies(encounter_type: String) -> Array[CombatManager.EnemyData]:
	var result: Array[CombatManager.EnemyData] = []
	
	match encounter_type:
		"construct":
			result = _spawn_enemies(["Construct"])
		"trap":
			result = _spawn_enemies(["Mimic Chest"])
		_:
			result = _spawn_enemies(["Construct"])
	
	return result

func _spawn_enemies(enemy_names: Array[String]) -> Array[CombatManager.EnemyData]:
	var result: Array[CombatManager.EnemyData] = []
	for name in enemy_names:
		var template = RoomEnemyDatabase.ENEMIES.get(name)
		if template:
			result.append(template.to_combat_data())
	return result

func _on_combat_ended(victory: bool):
	in_combat = false
	AudioManager.play_floor_ambient(4)
	
	# Reset surviving enemies to unaware, clean up dead ones
	for enemy in hex_enemies:
		if enemy.hp > 0:
			enemy.reset_after_combat()
		else:
			enemy.queue_free()
	
	# Remove dead enemies from array
	var alive_enemies: Array[HexEnemy] = []
	for enemy in hex_enemies:
		if enemy.hp > 0:
			alive_enemies.append(enemy)
	hex_enemies = alive_enemies
	
	if victory:
		level_cleared[current_room_id] = true
		print("[Floor4-Hex] Level cleared: %s" % current_room_id)
		
		if current_room_id == "f4_undercroft" and not lifter_repaired:
			# Chance to find a gear part in undercroft
			_find_gear_part()
	else:
		print("[Floor4-Hex] Combat lost — player respawned")
		GameState.player_hp = max(1, GameState.player_hp)
		player_node.global_position = hex_map.hex_to_world(level_data["f4_main"]["center"])
		# Reset all enemies
		for enemy in hex_enemies:
			enemy.reset_after_combat()

func _on_enemy_combat_initiated(ambush: bool):
	"""Called when an enemy initiates or is ambushed into combat."""
	if in_combat:
		return
	
	ambush_bonus = ambush
	
	var ambush_msg = "AMBUSH! Player bonus turn!" if ambush else "Enemy spotted you!"
	_show_notification(ambush_msg, Color(0.9, 0.9, 0.9), 3.0)
	
	# Find all enemies in combat range
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	var combat_enemies: Array[CombatManager.EnemyData] = []
	
	for enemy in hex_enemies:
		if enemy.state == HexEnemy.State.IN_COMBAT or enemy.hp <= 0:
			continue
		var dist = HexTileMap._hex_distance(player_hex, enemy.hex_pos)
		if dist <= 3:  # Combat range for all nearby enemies
			combat_enemies.append(enemy.to_combat_data())
			enemy._set_state(HexEnemy.State.IN_COMBAT)
	
	if combat_enemies.is_empty():
		return
	
	# Start card combat
	in_combat = true
	var combat_manager = get_node_or_null("CombatManager")
	if combat_manager:
		combat_manager.start_combat(combat_enemies, GameState.player_deck)
		var ui = get_node_or_null("CombatUI")
		if ui:
			ui.setup(combat_manager)
			ui.visible = true
		AudioManager.play_combat(4)
		print("[Floor4-Hex] Hex combat started! Enemies: %d, Ambush: %s" % [combat_enemies.size(), str(ambush)])
		
		# If ambush, grant player bonus turn
		if ambush:
			combat_manager.is_player_turn = true
			combat_manager.player_shield += 2
			print("[Floor4-Hex] Ambush bonus: +2 shield, player goes first")

func _check_enemy_sight():
	"""Check if any enemy can see the player."""
	if in_combat or not player_node or not hex_map:
		return
	
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	
	for enemy in hex_enemies:
		if enemy.state == HexEnemy.State.IN_COMBAT or enemy.hp <= 0:
			continue
		enemy.check_player_sight(player_hex)

func _try_ambush_at_hex(target_hex: Vector2i) -> bool:
	"""Check if player walked onto or adjacent to an enemy for ambush."""
	for enemy in hex_enemies:
		if enemy.hp <= 0 or enemy.state == HexEnemy.State.IN_COMBAT:
			continue
		var dist = HexTileMap._hex_distance(target_hex, enemy.hex_pos)
		if dist <= 1:
			# Player is adjacent to enemy — try ambush!
			if enemy.try_ambush(target_hex):
				return true
	return false

func _find_gear_part():
	for part in required_parts:
		if part not in collected_parts:
			collected_parts.append(part)
			GameState.collect_lifter_part(part)
			_show_notification("Found %s! (%d/3)" % [part, collected_parts.size()], Color(0.9, 0.9, 0.9), 3.0)
			_update_lifter_ui()
			break

# ===================================================================
# UI
# ===================================================================

func _setup_ui():
	interact_prompt = Label.new()
	interact_prompt.name = "InteractPrompt"
	interact_prompt.position = Vector2(540, 650)
	interact_prompt.size = Vector2(200, 30)
	interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_prompt.add_theme_font_size_override("font_size", 14)
	interact_prompt.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	interact_prompt.visible = false
	add_child(interact_prompt)
	
	_pause_menu_setup()
	_lifter_ui_setup()
	_level_indicator_setup()

func _pause_menu_setup():
	pause_menu = CanvasLayer.new()
	pause_menu.name = "PauseMenu"
	pause_menu.visible = false
	pause_menu.process_mode = PROCESS_MODE_ALWAYS
	add_child(pause_menu)
	
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.85)
	bg.size = Vector2(1280, 720)
	pause_menu.add_child(bg)
	
	var container = VBoxContainer.new()
	container.position = Vector2(560, 320)
	container.size = Vector2(160, 150)
	pause_menu.add_child(container)
	
	var title = Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)
	
	var resume_btn = Button.new()
	resume_btn.text = "Resume"
	resume_btn.pressed.connect(_toggle_pause_menu)
	container.add_child(resume_btn)
	
	var save_btn = Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(func(): GameState.save_game(); _show_notification("Saved!"))
	container.add_child(save_btn)
	
	var quit_btn = Button.new()
	quit_btn.text = "Quit to Title"
	quit_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn"))
	container.add_child(quit_btn)

func _lifter_ui_setup():
	lifter_ui = Control.new()
	lifter_ui.name = "GreatLifterUI"
	lifter_ui.position = Vector2(20, 20)
	add_child(lifter_ui)
	_update_lifter_ui()

func _update_lifter_ui():
	if not lifter_ui:
		return
	
	for child in lifter_ui.get_children():
		child.queue_free()
	
	var label = Label.new()
	if lifter_repaired:
		label.text = "🔧 Great Lifter: REPAIRED"
		label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	else:
		label.text = "🔧 Great Lifter: %d/%d parts" % [collected_parts.size(), required_parts.size()]
		label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))
	
	lifter_ui.add_child(label)

func _level_indicator_setup():
	var level_ui = Label.new()
	level_ui.name = "LevelIndicator"
	level_ui.position = Vector2(20, 60)
	level_ui.add_theme_font_size_override("font_size", 12)
	add_child(level_ui)
	_update_level_indicator()

func _update_level_indicator():
	var level_ui = get_node_or_null("LevelIndicator")
	if not level_ui:
		return
	
	match current_level:
		"main":       level_ui.text = "📍 The Bazaar"
		"undercroft": level_ui.text = "📍 The Undercroft"
		"refectory":  level_ui.text = "📍 The Refectory"
	
	match current_level:
		"main":       level_ui.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
		"undercroft": level_ui.add_theme_color_override("font_color", Color(0.5, 0.4, 0.6))
		"refectory":  level_ui.add_theme_color_override("font_color", Color(0.6, 0.5, 0.7))

func _toggle_pause_menu():
	is_paused = !is_paused
	pause_menu.visible = is_paused
	get_tree().paused = is_paused

# ===================================================================
# MOVEMENT (WEADZX + Click-to-Move)
# ===================================================================

func _input(event: InputEvent):
	if in_combat or in_transition or in_ui or in_booth:
		return
	
	# Mouse click handling
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_click_move(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_on_click_interact(event.position)
		return
	
	# Keyboard movement — cancels any active path movement
	if event is InputEventKey and event.pressed:
		path_movement_active = false
		match event.keycode:
			KEY_ESCAPE:
				_toggle_pause_menu()
				return
			KEY_E:
				_hex_move(Vector2(0.5, -0.866))
			KEY_W:
				_hex_move(Vector2(-0.5, -0.866))
			KEY_A:
				_hex_move(Vector2(-1, 0))
			KEY_D:
				_hex_move(Vector2(1, 0))
			KEY_Z:
				_hex_move(Vector2(-0.5, 0.866))
			KEY_X:
				_hex_move(Vector2(0.5, 0.866))
			KEY_S, KEY_SPACE:
				_try_interact()
				return

func _on_click_move(screen_pos: Vector2):
	if not player_node or not hex_map:
		return
	
	var world_pos = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var target_hex = hex_map.world_to_hex(world_pos)
	
	# Check if clicked on enemy for ambush
	for enemy in hex_enemies:
		if enemy.hp <= 0 or enemy.state == HexEnemy.State.IN_COMBAT:
			continue
		if enemy.hex_pos == target_hex:
			if enemy.try_ambush(hex_map.world_to_hex(player_node.global_position)):
				return
	
	if not hex_map.is_walkable(target_hex):
		_show_notification("Can't move there!")
		return
	
	var current_hex = hex_map.world_to_hex(player_node.global_position)
	if target_hex == current_hex:
		return
	
	var path = hex_map.find_path(current_hex, target_hex)
	if path.is_empty() or path.size() <= 1:
		_show_notification("No path!")
		return
	
	# Check if path goes near enemy for ambush
	for step_hex in path.slice(1):
		for enemy in hex_enemies:
			if enemy.hp <= 0 or enemy.state == HexEnemy.State.IN_COMBAT:
				continue
			if HexTileMap._hex_distance(step_hex, enemy.hex_pos) <= 1:
				# Walk up to this hex and ambush
				var ambush_path = path.slice(1, path.find(step_hex) + 1)
				path_movement_target = ambush_path
				path_movement_index = 0
				path_movement_timer = 0.0
				path_movement_active = true
				return
	
	path_movement_target = path.slice(1)
	path_movement_index = 0
	path_movement_timer = 0.0
	path_movement_active = true

func _on_click_interact(screen_pos: Vector2):
	if not player_node or not hex_map:
		return
	
	var world_pos = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var click_hex = hex_map.world_to_hex(world_pos)
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	
	# Check if clicked on/near enemy for ambush
	for enemy in hex_enemies:
		if enemy.hp <= 0 or enemy.state == HexEnemy.State.IN_COMBAT:
			continue
		if HexTileMap._hex_distance(click_hex, enemy.hex_pos) <= 1:
			if enemy.try_ambush(player_hex):
				return
	
	var dist = HexTileMap._hex_distance(player_hex, click_hex)
	if dist <= 1:
		_try_interact()
	else:
		_show_notification("Too far to interact.")

func _hex_move(move_vec: Vector2):
	if not player_node:
		return
	
	var current_hex = hex_map.world_to_hex(player_node.global_position)
	var direction = _vector_to_hex_dir(move_vec)
	var dirs = HexTileMap.DIRECTIONS
	var target_hex = current_hex + dirs[direction]
	
	if hex_map.is_wall(target_hex):
		return
	
	# Check if player walked onto/near an enemy for ambush
	if _try_ambush_at_hex(target_hex):
		return
	
	# Undercroft: Aether Slick hazard
	if current_level == "undercroft":
		if _is_in_aether_slick(target_hex):
			if not on_aether_slick:
				on_aether_slick = true
				_show_notification("Aether Slick! Movement erratic!")
			# Jitter movement
			move_vec += Vector2(randf() - 0.5, randf() - 0.5) * 0.5
		else:
			on_aether_slick = false
	
	player_node.global_position = hex_map.hex_to_world(target_hex)
	
	var animator = player_node.get_node_or_null("PlayerAnimator")
	if animator:
		var dir_str = _velocity_to_direction(move_vec)
		animator.play_walk(dir_str)
		animator.set_meta("move_timer", 0.2)
	
	_check_level_transition(target_hex)
	_check_interactables()
	_check_enemy_sight()  # Check sight after movement

func _vector_to_hex_dir(velocity: Vector2) -> int:
	var angle = velocity.angle()
	var degrees = rad_to_deg(angle)
	if degrees >= -30 and degrees < 30:         return 3
	elif degrees >= 30 and degrees < 90:          return 5
	elif degrees >= 90 and degrees < 150:         return 4
	elif degrees >= 150 or degrees < -150:        return 2
	elif degrees >= -150 and degrees < -90:       return 0
	elif degrees >= -90 and degrees < -30:       return 1
	else:                                         return 3

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

# ===================================================================
# LEVEL / STAIR TRANSITIONS
# ===================================================================

func _check_level_transition(player_hex: Vector2i):
	if hex_map.get_tile(player_hex) == hex_map.TILE_PORTAL:
		var stair_dir = _get_stair_direction_from_hex(player_hex)
		if stair_dir:
			_try_stair_transition(stair_dir)
			return

func _get_stair_direction_from_hex(hex: Vector2i) -> String:
	var current_data = level_data.get(current_room_id)
	if not current_data:
		return ""
	
	var center = current_data["center"]
	for dir_name in stair_offsets.keys():
		var offset = stair_offsets[dir_name]
		var stair_hex = center + offset
		if hex == stair_hex:
			return dir_name
	return ""

func _try_stair_transition(direction: String):
	var connections = stair_connections.get(current_level, {})
	var target_room = connections.get(direction, "")
	if target_room.is_empty():
		return
	
	var target_data = level_data[target_room]
	var target_level_name = target_data["level"]
	
	in_transition = true
	AudioManager.play_sfx("room_enter")
	
	var msg = ""
	match target_level_name:
		"undercroft": msg = "You descend into the pipe tunnels..."
		"refectory":  msg = "Steam lifts you to the brass balconies..."
		"main":       msg = "You return to the main floor."
	_show_notification(msg, Color(0.9, 0.9, 0.9), 2.5)
	
	# Place player at target level center
	var target_hex = target_data["center"]
	player_node.global_position = hex_map.hex_to_world(target_hex)
	
	_enter_level(target_level_name, target_room)
	
	in_transition = false

func _enter_level(level_name: String, room_id: String):
	if room_id == current_room_id:
		return
	
	current_level = level_name
	current_room_id = room_id
	var data = level_data[room_id]
	print("[Floor4-Hex] Entered level: %s (%s)" % [data["display"], level_name])
	room_changed.emit(room_id, data["display"])
	level_changed.emit(level_name)
	
	_update_level_indicator()
	
	# Show level-specific message
	match level_name:
		"undercroft":
			if not _has_all_parts():
				_show_notification("Undercroft: Search for gear parts! (%d/3 found)" % collected_parts.size(), Color(0.9, 0.9, 0.9), 4.0)
		"refectory":
			_show_notification("Refectory: Memory-food heals but brings Nostalgia...", Color(0.9, 0.9, 0.9), 3.0)
	
	# Spawn encounter if not cleared
	if not level_cleared.get(room_id, false) and not level_encounter_spawned.get(room_id, false):
		if data["encounter"] != "none":
			level_encounter_spawned[room_id] = true
			_start_combat(data["encounter"])

# ===================================================================
# INTERACTION
# ===================================================================

func _check_interactables():
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	var player_pos = player_node.global_position
	
	match current_level:
		"main":
			_check_interactables_main(player_hex, player_pos)
		"undercroft":
			_check_interactables_undercroft(player_hex)
		"refectory":
			_check_interactables_refectory(player_hex)

func _check_interactables_main(player_hex: Vector2i, player_pos: Vector2):
	# Check Great Lifter (center of main level)
	var main_center = level_data["f4_main"]["center"]
	var lifter_dist = HexTileMap._hex_distance(player_hex, main_center)
	if lifter_dist <= 2:
		if lifter_repaired:
			_show_interact_prompt("[S] Enter Great Lifter (Exit)")
		else:
			_show_interact_prompt("[S] Inspect Great Lifter")
		return
	
	# Check booths
	for booth_id in booth_hex_positions.keys():
		var booth_hex = main_center + booth_hex_positions[booth_id]
		var dist = HexTileMap._hex_distance(player_hex, booth_hex)
		if dist <= 1:
			var booth_name = _get_booth_display_name(booth_id)
			if booth_id in real_vendors:
				_show_interact_prompt("[S] Enter %s" % booth_name)
			else:
				_show_interact_prompt("[S] Enter %s (⚠ Trap)" % booth_name)
			return
	
	_hide_interact_prompt()

func _check_interactables_undercroft(player_hex: Vector2i):
	# Check for gear parts anywhere in the undercroft (radius 10 room)
	var undercroft_center = level_data["f4_undercroft"]["center"]
	var dist = HexTileMap._hex_distance(player_hex, undercroft_center)
	if dist <= 8 and not _has_all_parts():
		_show_interact_prompt("[S] Search for parts (%d/3 found)" % collected_parts.size())
		return
	
	_hide_interact_prompt()

func _check_interactables_refectory(player_hex: Vector2i):
	# Check food stations (simplified: near edges)
	var refectory_center = level_data["f4_refectory"]["center"]
	var dist = HexTileMap._hex_distance(player_hex, refectory_center)
	if dist >= 6 and dist <= 8:
		_show_interact_prompt("[S] Eat memory-food (+HP, ⚠ Nostalgia)")
		return
	
	_hide_interact_prompt()

func _try_interact():
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	var player_pos = player_node.global_position
	
	match current_level:
		"main":
			_try_interact_main(player_hex, player_pos)
		"undercroft":
			_try_interact_undercroft(player_hex)
		"refectory":
			_try_interact_refectory(player_hex)

func _try_interact_main(player_hex: Vector2i, player_pos: Vector2):
	var main_center = level_data["f4_main"]["center"]
	
	# Check Great Lifter
	var lifter_dist = HexTileMap._hex_distance(player_hex, main_center)
	if lifter_dist <= 2:
		_interact_great_lifter()
		return
	
	# Check booths
	for booth_id in booth_hex_positions.keys():
		var booth_hex = main_center + booth_hex_positions[booth_id]
		var dist = HexTileMap._hex_distance(player_hex, booth_hex)
		if dist <= 1:
			_enter_booth(booth_id)
			return

func _interact_great_lifter():
	if lifter_repaired:
		_show_dialogue("Great Lifter", "The steam elevator rumbles. Floor 5 awaits.")
		await get_tree().create_timer(2.0).timeout
		GameState.set_current_floor(5)
		get_tree().change_scene_to_file("res://scenes/Floor5.tscn")
	elif _has_all_parts():
		_repair_great_lifter()
	else:
		var missing = []
		for part in required_parts:
			if part not in collected_parts:
				missing.append(part)
		_show_dialogue("Great Lifter", "Broken. Need %d more parts: %s. Search the Undercroft!" % [missing.size(), ", ".join(missing)])

func _repair_great_lifter():
	if lifter_repaired:
		return
	
	lifter_repaired = true
	GameState.repair_great_lifter()
	
	_show_dialogue("Great Lifter", "The steam elevator rumbles to life! Floor 5 awaits.")
	_update_lifter_ui()

func _has_all_parts() -> bool:
	for part in required_parts:
		if part not in collected_parts:
			return false
	return true

func _try_interact_undercroft(player_hex: Vector2i):
	var undercroft_center = level_data["f4_undercroft"]["center"]
	var dist = HexTileMap._hex_distance(player_hex, undercroft_center)
	if dist <= 8 and not _has_all_parts():
		_find_gear_part()
		return
	
	_show_dialogue("Undercroft", "Pipe steam hisses. Something glints in the dark...")

func _try_interact_refectory(player_hex: Vector2i):
	var refectory_center = level_data["f4_refectory"]["center"]
	var dist = HexTileMap._hex_distance(player_hex, refectory_center)
	if dist >= 6 and dist <= 8:
		_eat_food()
		return

func _eat_food():
	GameState.heal_player(10)
	has_nostalgia = true
	_show_dialogue("Food", "The memory-food tastes like your childhood. +10 HP. You feel... vulnerable.")

func _show_interact_prompt(text: String):
	if interact_prompt:
		interact_prompt.text = text
		interact_prompt.visible = true

func _hide_interact_prompt():
	if interact_prompt:
		interact_prompt.visible = false

# ===================================================================
# BOOTH SYSTEM
# ===================================================================

func _enter_booth(booth_id: String):
	if in_booth:
		return
	in_booth = true
	active_booth_id = booth_id
	
	var booth_name = _get_booth_display_name(booth_id)
	
	if booth_id in real_vendors:
		_show_dialogue("Vendor", "Welcome to %s!" % booth_name)
		_open_shop()
	else:
		_show_dialogue("Trap", "It's a trap! %s attacks!" % booth_name)
		_trigger_trap_combat(booth_id)
	
	print("[Floor4-Hex] Entered booth: %s" % booth_id)

func _exit_booth():
	in_booth = false
	active_booth_id = ""
	print("[Floor4-Hex] Exited booth")

func _trigger_trap_combat(booth_id: String):
	var comp = RoomEnemyDatabase.get_floor4_composition(booth_id)
	if comp.get("is_peaceful", false):
		return
	
	var enemy_data = comp.get("enemies", [])
	if enemy_data.is_empty():
		return
	
	in_combat = true
	var combat_manager = get_node_or_null("CombatManager")
	if combat_manager:
		var combat_enemies: Array = []
		for template in enemy_data:
			if template.has_method("to_combat_data"):
				combat_enemies.append(template.to_combat_data())
		combat_manager.start_combat(combat_enemies, GameState.player_deck)
		var ui = get_node_or_null("CombatUI")
		if ui:
			ui.setup(combat_manager)
			ui.visible = true
		print("[Floor4-Hex] Trap booth '%s' combat started" % booth_id)

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

func _open_shop():
	_show_dialogue("Shop", "Shop interface not yet implemented. Use keyboard for now.")

# ===================================================================
# AETHER SLICK
# ===================================================================

func _is_in_aether_slick(hex: Vector2i) -> bool:
	# Undercroft has aether slick zones near the center
	if current_level != "undercroft":
		return false
	
	var undercroft_center = level_data["f4_undercroft"]["center"]
	var dist = HexTileMap._hex_distance(hex, undercroft_center)
	return dist >= 3 and dist <= 6

# ===================================================================
# DIALOGUE / NOTIFICATIONS
# ===================================================================

func _show_dialogue(speaker: String, text: String):
	var dialogue = Label.new()
	dialogue.name = "DialogueBox"
	dialogue.text = "%s: %s" % [speaker, text]
	dialogue.position = Vector2(140, 550)
	dialogue.size = Vector2(1000, 100)
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.add_theme_font_size_override("font_size", 16)
	add_child(dialogue)
	
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(dialogue):
		dialogue.queue_free()

func _show_notification(text: String, color: Color = Color(0.9, 0.9, 0.9), duration: float = 3.0):
	var notif = Label.new()
	notif.text = text
	notif.position = Vector2(390, 300)
	notif.size = Vector2(500, 30)
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.add_theme_font_size_override("font_size", 14)
	notif.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	add_child(notif)
	
	var tween = create_tween()
	tween.tween_property(notif, "position:y", 250, 1.5)
	tween.parallel().tween_property(notif, "modulate:a", 0.0, 1.5)
	tween.tween_callback(notif.queue_free)

# ===================================================================
# FLOOR SPECIFIC
# ===================================================================

func _setup_floor_specific():
	print("[Floor4-Hex] Floor 4 initialized — three levels with Great Lifter")

func _process(_delta: float):
	# Camera follows player
	if player_node:
		var camera = get_node_or_null("Camera2D")
		if camera:
			camera.global_position = player_node.global_position
	
	# Path movement (click-to-move)
	if path_movement_active and player_node and not in_combat and not in_transition:
		path_movement_timer += _delta
		if path_movement_timer >= PATH_MOVE_STEP_INTERVAL:
			path_movement_timer = 0.0
			if path_movement_index < path_movement_target.size():
				var step_hex = path_movement_target[path_movement_index]
				
				if hex_map.is_wall(step_hex):
					path_movement_active = false
					return
				
				# Check for ambush opportunity at each step
				for enemy in hex_enemies:
					if enemy.hp <= 0 or enemy.state == HexEnemy.State.IN_COMBAT:
						continue
					if HexTileMap._hex_distance(step_hex, enemy.hex_pos) <= 1:
						# Stop at this hex and ambush
						player_node.global_position = hex_map.hex_to_world(step_hex)
						path_movement_active = false
						var animator = player_node.get_node_or_null("PlayerAnimator")
						if animator:
							animator.play_idle()
						_check_enemy_sight()
						return
				
				var prev_pos = player_node.global_position
				player_node.global_position = hex_map.hex_to_world(step_hex)
				
				var animator = player_node.get_node_or_null("PlayerAnimator")
				if animator:
					var dir_vec = player_node.global_position - prev_pos
					var dir_str = _velocity_to_direction(dir_vec)
					animator.play_walk(dir_str)
					animator.set_meta("move_timer", 0.2)
				
				_check_level_transition(step_hex)
				_check_interactables()
				
				path_movement_index += 1
				_check_enemy_sight()  # Check after each step
			else:
				path_movement_active = false
				var animator = player_node.get_node_or_null("PlayerAnimator")
				if animator:
					animator.play_idle()
				return
	
	# Enemy sight check every frame (for enemies that patrol)
	if not in_combat and not in_transition:
		_check_enemy_sight()
	
	# Movement idle timer
	if not path_movement_active:
		var animator = player_node.get_node_or_null("PlayerAnimator") if player_node else null
		if animator and animator.has_meta("move_timer"):
			var timer = animator.get_meta("move_timer") - _delta
			if timer <= 0:
				animator.play_idle()
				animator.set_meta("move_timer", 0.0)
			else:
				animator.set_meta("move_timer", timer)
	
	# Refectory: Nostalgia flashbacks
	if has_nostalgia and current_level == "refectory" and randf() < 0.01:
		_show_notification("A scent reminds you of something lost...", Color(0.9, 0.9, 0.9), 1.5)
