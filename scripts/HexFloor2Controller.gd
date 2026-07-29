extends Node2D

# ===================================================================
# FLOOR 2 CONTROLLER — Hex-Based — The Fungal Cavern
# ===================================================================
# Replaces room scenes with hex grid zones.
# Rooms are defined by center hex + radius.
# Portals are hex teleports.
# Encounters trigger on room zone entry.
# ===================================================================

# -------------------------------------------------------------------
# Hex Grid
# -------------------------------------------------------------------
@onready var hex_map: HexTileMap = $HexTileMap

# -------------------------------------------------------------------
# State
# -------------------------------------------------------------------
var player_node: Node2D
var current_room_id: String = "f2_entry"
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

# Room definitions: center hex, radius, encounter type
var room_data: Dictionary = {
	"f2_entry":       {"center": Vector2i(0, 0),   "radius": 7, "encounter": "none",    "display": "The Overlook"},
	"f2_upper":       {"center": Vector2i(0, -20),  "radius": 7, "encounter": "standard", "display": "The Upper Spore"},
	"f2_middle":      {"center": Vector2i(18, 0),   "radius": 7, "encounter": "warren",   "display": "The Growth Chamber"},
	"f2_lower":       {"center": Vector2i(0, 20),   "radius": 7, "encounter": "shrine",   "display": "The Lower Pool"},
	"f2_secret":      {"center": Vector2i(12, 34),  "radius": 4, "encounter": "secret",   "display": "The Hidden Spore"},
	"f2_spore_heart": {"center": Vector2i(-16, 36), "radius": 8, "encounter": "spore",    "display": "Spore Heart"},
}

# Portal connections: room_id -> direction -> target room
var portal_connections: Dictionary = {
	"f2_entry":  {"north": "f2_upper",       "east": "f2_middle",      "south": "f2_lower"},
	"f2_upper":  {"south": "f2_entry",       "down": "f2_spore_heart"},
	"f2_middle": {"west":  "f2_entry",       "down": "f2_spore_heart"},
	"f2_lower":  {"north": "f2_entry",       "secret": "f2_secret", "down": "f2_spore_heart"},
	"f2_secret": {"exit": "f2_lower"},
	"f2_spore_heart": {"exit": "f2_entry"},
}

# Portal hex offsets from room center (which direction portal faces)
var portal_offsets: Dictionary = {
	"north": Vector2i(0, -8),
	"east":  Vector2i(8, 0),
	"south": Vector2i(0, 8),
	"west":  Vector2i(-8, 0),
	"down":  Vector2i(0, 8),
	"secret": Vector2i(8, 4),
	"exit":  Vector2i(0, -8),
}

# Room encounter state
var room_cleared: Dictionary = {}
var room_encounter_spawned: Dictionary = {}

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

# -------------------------------------------------------------------
# Tutorial
# -------------------------------------------------------------------
var tutorial_active: bool = false
var tutorial_step: int = 0
var tutorial_prompt_label: Label

# -------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------
signal room_changed(room_id: String, room_name: String)

# ===================================================================
# LIFECYCLE
# ===================================================================

func _ready():
	# Reset for replayability — selecting floor from menu should always be fresh
	room_cleared.clear()
	room_encounter_spawned.clear()
	call_deferred("_build_floor")

func _build_floor():
	# Load tile texture variations for Floor 2
	if hex_map:
		var floor_variants = [
			preload("res://assets/sprites/hex/floor2/floor_v4.png"),
			preload("res://assets/sprites/hex/floor2/floor_v5.png"),
			preload("res://assets/sprites/hex/floor2/floor_v6.png"),
		]
		var wall_variant = preload("res://assets/sprites/hex/floor2/wall.png")
		var water_variants = [
			preload("res://assets/sprites/hex/floor2/water_v1.png"),
			preload("res://assets/sprites/hex/floor2/water_v2.png"),
		]
		for tex in water_variants:
			if tex:
				hex_map.tile_textures_water.append(tex)
		for tex in floor_variants:
			if tex:
				hex_map.tile_textures_floor.append(tex)
		if wall_variant:
			hex_map.tile_textures_wall.append(wall_variant)
		if hex_map.tile_textures_floor.size() > 0:
			hex_map.tile_texture_floor = hex_map.tile_textures_floor[0]
		if hex_map.tile_textures_wall.size() > 0:
			hex_map.tile_texture_wall = hex_map.tile_textures_wall[0]
		if hex_map.tile_textures_water.size() > 0:
			hex_map.tile_texture_water = hex_map.tile_textures_water[0]
		print("[Floor2-Hex] Loaded %d floor textures, %d wall textures, %d water textures" % [hex_map.tile_textures_floor.size(), hex_map.tile_textures_wall.size(), hex_map.tile_textures_water.size()])
	
	# Generate hex layout
	if hex_map:
		hex_map.generate_floor2_layout()
		print("[Floor2-Hex] Hex grid generated: %d tiles" % hex_map.grid.size())
	
	# Setup systems
	_setup_combat()
	_setup_ui()
	_setup_player()
	_setup_floor_specific()
	_setup_enemies()  # Spawn hex enemies
	
	# Start music
	AudioManager.play_floor_ambient(2)
	
	# Enter starting room
	_enter_room("f2_entry")

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
		print("[Floor2-Hex] Player created")
	
	# Place at entry room center
	var entry_center = room_data["f2_entry"]["center"]
	player_node.global_position = hex_map.hex_to_world(entry_center)
	print("[Floor2-Hex] Player placed at entry: %s" % str(entry_center))

func _setup_enemies():
	"""Spawn enemies on the hex grid for each room."""
	enemy_container = Node2D.new()
	enemy_container.name = "EnemyContainer"
	add_child(enemy_container)
	
	# Spawn enemies per room
	var enemy_spawns = {
		"f2_upper": [
			{"name": "Spore Walker", "hex": Vector2i(-2, -18), "faction": "Aberration"},
			{"name": "Spore Walker", "hex": Vector2i(2, -22), "faction": "Aberration"},
		],
		"f2_middle": [
			{"name": "Torch Boy", "hex": Vector2i(16, -2), "faction": "Goblin"},
			{"name": "Torch Boy", "hex": Vector2i(20, 2), "faction": "Goblin"},
		],
		"f2_lower": [
			{"name": "Droplet", "hex": Vector2i(0, 22), "faction": "Elemental"},
		],
		"f2_secret": [
			{"name": "Mimic Chest", "hex": Vector2i(12, 36), "faction": "Aberration"},
		],
		"f2_spore_heart": [
			{"name": "Spore Queen", "hex": Vector2i(-16, 36), "faction": "Aberration", "boss": true},
		],
	}
	
	for room_id in enemy_spawns.keys():
		for spawn_data in enemy_spawns[room_id]:
			var enemy = HexEnemy.new(
				spawn_data["name"] + "_%d" % hex_enemies.size(),
				spawn_data["name"],
				spawn_data["hex"],
				spawn_data.get("faction", "Unknown"),
				spawn_data.get("boss", false)
			)
			enemy.name = "HexEnemy_%d" % hex_enemies.size()
			
			# Configure enemy stats based on type
			if spawn_data.get("boss", false):
				enemy.max_hp = 55
				enemy.hp = 55
				enemy.attack = 7
				enemy.defense = 3
			elif spawn_data["name"] == "Mimic Chest":
				enemy.max_hp = 15
				enemy.hp = 15
				enemy.attack = 5
				enemy.defense = 2
			elif spawn_data["name"] == "Droplet":
				enemy.max_hp = 12
				enemy.hp = 12
				enemy.attack = 3
				enemy.defense = 1
			else:
				enemy.max_hp = 10 + randi() % 6
				enemy.hp = enemy.max_hp
				enemy.attack = 2 + randi() % 3
				enemy.defense = randi() % 2
			
			enemy_container.add_child(enemy)
			enemy.set_hex_map_position(spawn_data["hex"], hex_map)
			
			# Connect signals
			enemy.combat_initiated.connect(_on_enemy_combat_initiated)
			
			hex_enemies.append(enemy)
			print("[Floor2-Hex] Spawned %s at %s" % [spawn_data["name"], str(spawn_data["hex"])])
	
	print("[Floor2-Hex] %d hex enemies spawned" % hex_enemies.size())

# ===================================================================
# COMBAT
# ===================================================================

func _setup_combat():
	var combat_manager = get_node_or_null("CombatManager")
	if combat_manager:
		combat_manager.combat_ended.connect(_on_combat_ended)
		print("[Floor2-Hex] CombatManager wired")

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
		AudioManager.play_combat(2)
		print("[Floor2-Hex] Combat started: %s" % encounter_type)

func _get_encounter_enemies(encounter_type: String) -> Array[CombatManager.EnemyData]:
	var result: Array[CombatManager.EnemyData] = []
	
	match encounter_type:
		"standard":
			result = _spawn_enemies(["Spore Walker", "Spore Walker"])
		"warren":
			result = _spawn_enemies(["Torch Boy", "Torch Boy", "Torch Boy"])
		"shrine":
			result = _spawn_enemies(["Droplet"])
		"secret":
			result = _spawn_enemies(["Mimic Chest"])
		"spore":
			result = _spawn_enemies(["Spore Queen"])
		_:
			result = _spawn_enemies(["Spore Walker"])
	
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
	AudioManager.play_floor_ambient(2)
	
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
		room_cleared[current_room_id] = true
		print("[Floor2-Hex] Room cleared: %s" % current_room_id)
		
		if current_room_id == "f2_spore_heart":
			_floor_complete()
	else:
		print("[Floor2-Hex] Combat lost — player respawned")
		GameState.player_hp = max(1, GameState.player_hp)
		player_node.global_position = hex_map.hex_to_world(room_data["f2_entry"]["center"])
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
		AudioManager.play_combat(2)
		print("[Floor2-Hex] Hex combat started! Enemies: %d, Ambush: %s" % [combat_enemies.size(), str(ambush)])
		
		# If ambush, grant player bonus turn
		if ambush:
			combat_manager.is_player_turn = true
			combat_manager.player_shield += 2
			print("[Floor2-Hex] Ambush bonus: +2 shield, player goes first")

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

func _floor_complete():
	_show_dialogue("The Tower", "The Spore Heart falls. Press [S] to ascend to Floor 3.")
	GameState.add_card_to_deck("spore_heart_card")
	GameState.gems += 20
	GameState.save_game()

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
	
	var transit_ui = Control.new()
	transit_ui.name = "TransitTokenUI"
	transit_ui.position = Vector2(20, 20)
	add_child(transit_ui)
	_update_transit_token_display()
	
	tutorial_prompt_label = Label.new()
	tutorial_prompt_label.name = "TutorialPrompt"
	tutorial_prompt_label.position = Vector2(660, 200)
	tutorial_prompt_label.size = Vector2(600, 80)
	tutorial_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_prompt_label.add_theme_font_size_override("font_size", 18)
	tutorial_prompt_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	tutorial_prompt_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	tutorial_prompt_label.add_theme_constant_override("shadow_outline_size", 4)
	tutorial_prompt_label.visible = false
	add_child(tutorial_prompt_label)

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

func _toggle_pause_menu():
	is_paused = !is_paused
	pause_menu.visible = is_paused
	get_tree().paused = is_paused

# ===================================================================
# MOVEMENT (WEADZX + Click-to-Move)
# ===================================================================

func _input(event: InputEvent):
	if in_combat or in_transition or in_ui:
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
	
	player_node.global_position = hex_map.hex_to_world(target_hex)
	
	var animator = player_node.get_node_or_null("PlayerAnimator")
	if animator:
		var dir_str = _velocity_to_direction(move_vec)
		animator.play_walk(dir_str)
		animator.set_meta("move_timer", 0.2)
	
	_check_room_transition(target_hex)
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
# ROOM / PORTAL LOGIC
# ===================================================================

func _check_room_transition(player_hex: Vector2i):
	if hex_map.get_tile(player_hex) == hex_map.TILE_PORTAL:
		var portal_dir = _get_portal_direction_from_hex(player_hex)
		if portal_dir:
			_try_portal_transition(portal_dir)
			return
	
	for room_id in room_data.keys():
		if room_id == current_room_id:
			continue
		var data = room_data[room_id]
		var dist = HexTileMap._hex_distance(player_hex, data["center"])
		if dist <= data["radius"]:
			_enter_room(room_id)
			return

func _get_portal_direction_from_hex(hex: Vector2i) -> String:
	var current_data = room_data.get(current_room_id)
	if not current_data:
		return ""
	
	var center = current_data["center"]
	for dir_name in portal_offsets.keys():
		var offset = portal_offsets[dir_name]
		var portal_hex = center + offset
		if hex == portal_hex:
			return dir_name
	return ""

func _try_portal_transition(direction: String):
	var connections = portal_connections.get(current_room_id, {})
	var target_room = connections.get(direction, "")
	if target_room.is_empty():
		return
	
	if _is_portal_locked(direction):
		_show_notification("Portal is locked.")
		return
	
	in_transition = true
	AudioManager.play_sfx("room_enter")
	
	var target_data = room_data[target_room]
	var target_hex = target_data["center"]
	
	var opposite_dir = _opposite_direction(direction)
	var entry_offset = portal_offsets.get(opposite_dir, Vector2i.ZERO)
	player_node.global_position = hex_map.hex_to_world(target_hex + entry_offset)
	
	_enter_room(target_room)
	
	in_transition = false

func _enter_room(room_id: String):
	if room_id == current_room_id:
		return
	
	current_room_id = room_id
	var data = room_data[room_id]
	print("[Floor2-Hex] Entered room: %s" % data["display"])
	room_changed.emit(room_id, data["display"])
	
	if not room_cleared.get(room_id, false) and not room_encounter_spawned.get(room_id, false):
		if data["encounter"] != "none":
			room_encounter_spawned[room_id] = true
			_start_combat(data["encounter"])

func _opposite_direction(dir: String) -> String:
	match dir:
		"north": return "south"
		"south": return "north"
		"east":  return "west"
		"west":  return "east"
		"down":  return "up"
		"up":    return "down"
		"secret": return "exit"
		"exit": return "secret"
	return ""

func _is_portal_locked(direction: String) -> bool:
	return false

# ===================================================================
# INTERACTION
# ===================================================================

func _check_interactables():
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	
	var neighbors = hex_map.get_neighbors(player_hex)
	neighbors.append(player_hex)
	
	var found = false
	for hex in neighbors:
		if hex_map.get_tile(hex) == hex_map.TILE_OBJECT:
			found = true
			_show_interact_prompt("Interact")
			break
	
	if not found:
		_hide_interact_prompt()

func _try_interact():
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	
	match current_room_id:
		"f2_entry":
			_show_dialogue("Fungal Guide", "The spores grow thick here. Choose your path carefully.")
		"f2_middle":
			_show_dialogue("Growth Pool", "The fungal growth pulses with strange energy.")
		"f2_lower":
			_show_dialogue("Pool Shrine", "The waters here carry ancient spores.")
		"f2_secret":
			_open_chest()
		"f2_spore_heart":
			_show_dialogue("Spore Heart", "The heart of the cavern beats with living fungus.")

func _show_interact_prompt(text: String):
	if interact_prompt:
		interact_prompt.text = text
		interact_prompt.visible = true

func _hide_interact_prompt():
	if interact_prompt:
		interact_prompt.visible = false

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
	var canvas = CanvasLayer.new()
	canvas.layer = 95
	add_child(canvas)
	
	var notif = Label.new()
	notif.text = text
	notif.position = Vector2(390, 300)
	notif.size = Vector2(500, 30)
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.add_theme_font_size_override("font_size", 14)
	notif.add_theme_color_override("font_color", color)
	canvas.add_child(notif)
	
	var tween = create_tween()
	tween.tween_property(notif, "position:y", 250, 1.5)
	tween.parallel().tween_property(notif, "modulate:a", 0.0, 1.5)
	tween.tween_callback(func():
		if is_instance_valid(canvas):
			canvas.queue_free()
		elif is_instance_valid(notif):
			notif.queue_free()
	)

func _open_chest():
	GameState.add_quiddity(5)
	_show_dialogue("Chest", "You found 5 Quiddity among the fungal growth!")

# ===================================================================
# TUTORIAL
# ===================================================================

func _setup_floor_specific():
	print("[Floor2-Hex] Floor 2 initialized")

func _start_tutorial():
	tutorial_active = true
	tutorial_step = 0
	_show_tutorial_prompt("The fungal cavern spreads before you.\nClick to move or use WEADZX.")

func _advance_tutorial_step():
	tutorial_step += 1
	match tutorial_step:
		1: _show_tutorial_prompt("Spores fill the air. Watch for fungal growths.")
		2: _show_tutorial_prompt("The Spore Heart awaits below. Find the path down.")
		3:
			_hide_tutorial_prompt()
			tutorial_active = false

func _show_tutorial_prompt(text: String):
	if tutorial_prompt_label:
		tutorial_prompt_label.text = text
		tutorial_prompt_label.visible = true

func _hide_tutorial_prompt():
	if tutorial_prompt_label:
		tutorial_prompt_label.visible = false

# ===================================================================
# UTILITIES
# ===================================================================

func _update_transit_token_display():
	var transit_ui = get_node_or_null("TransitTokenUI")
	if not transit_ui:
		return
	
	for child in transit_ui.get_children():
		child.queue_free()
	
	var tokens = GameState.transit_tokens if GameState.get("transit_tokens") else []
	if tokens.is_empty():
		return
	
	var y_offset = 0
	for token in tokens:
		var label = Label.new()
		label.text = "🗝 %s" % token
		label.position = Vector2(0, y_offset)
		label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
		transit_ui.add_child(label)
		y_offset += 25

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
				
				_check_room_transition(step_hex)
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

func _ascend_to_next_floor():
	AudioManager.play_sfx("floor_transition")
	get_tree().change_scene_to_file("res://scenes/Floor3.tscn")
