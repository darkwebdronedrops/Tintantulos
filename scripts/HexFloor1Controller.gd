extends Node2D

# ===================================================================
# FLOOR 1 CONTROLLER — Hex-Based (Full Transition)
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
var current_room_id: String = "entry"
var in_combat: bool = false
var in_transition: bool = false
var in_ui: bool = false
var is_paused: bool = false
var floor_cleared: bool = false
var floor_complete_notified: bool = false

# Click-to-Move path following state
var path_movement_active: bool = false
var path_movement_target: Array[Vector2i] = []
var path_movement_index: int = 0
var path_movement_timer: float = 0.0
const PATH_MOVE_STEP_INTERVAL: float = 0.12

# Room definitions: center hex, radius, encounter type
var room_data: Dictionary = {
	"entry":       {"center": Vector2i(0, 0),   "radius": 6, "encounter": "none",    "display": "The Threshold"},
	"upper":       {"center": Vector2i(0, -24),  "radius": 6, "encounter": "standard", "display": "The Door"},
	"middle":      {"center": Vector2i(24, 0),   "radius": 6, "encounter": "warren",   "display": "The Warren"},
	"lower":       {"center": Vector2i(0, 24),   "radius": 6, "encounter": "shrine",   "display": "The Shrine"},
	"secret":      {"center": Vector2i(0, 44),   "radius": 5, "encounter": "secret",   "display": "The Secret"},
	"spore_heart": {"center": Vector2i(44, 0),   "radius": 5, "encounter": "spore",    "display": "Spore Heart"},
}

# Portal connections: room_id -> direction -> target room
var portal_connections: Dictionary = {
	"entry":  {"north": "upper",       "east": "middle",      "south": "lower"},
	"upper":  {"south": "entry"},
	"middle": {"west":  "entry",       "east": "spore_heart"},
	"lower":  {"north": "entry",       "south": "secret"},
	"secret": {"north": "lower"},
	"spore_heart": {"west": "middle"},
}

# Portal hex offsets from room center (which direction portal faces)
var portal_offsets: Dictionary = {
	"north": Vector2i(0, -7),
	"east":  Vector2i(7, 0),
	"south": Vector2i(0, 7),
	"west":  Vector2i(-7, 0),
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
var door_tutorial_active: bool = false
var tutorial_step: int = 0
var tutorial_prompt_label: Label

# -------------------------------------------------------------------
# Shop
# -------------------------------------------------------------------
var shop_stock: Array[Dictionary] = [
	{"card_id": "Universal_counterspell", "cost": 15, "name": "Counterspell", "desc": "Negate enemy Special, they lose next action"},
	{"card_id": "Universal_focus",        "cost": 10, "name": "Focus",        "desc": "Gain +2 Attention this turn"},
	{"card_id": "Universal_fortify",      "cost": 12, "name": "Fortify",      "desc": "Gain 8 Shield"},
	{"card_id": "Universal_cleanse",      "cost": 10, "name": "Cleanse",      "desc": "Remove all debuffs"},
	{"card_id": "Universal_overcharge",   "cost": 15, "name": "Overcharge",   "desc": "Next attack deals +50% damage"}
]
var shop_ui_active: bool = false
var shop_ui_container: Control
var shop_sprite: Sprite2D  # Visual shop widget in the middle room

# -------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------
signal room_changed(room_id: String, room_name: String)
signal boss_portal_unlocked

# ===================================================================
# LIFECYCLE
# ===================================================================

func _ready():
	call_deferred("_build_floor")

func _build_floor():
	if GameState.is_first_run:
		_start_tutorial()
		return
	
	_finish_floor_setup()

func _finish_floor_setup():
	# Generate hex layout
	if hex_map:
		hex_map.generate_floor1_layout()
		print("[Floor1-Hex] Hex grid generated: %d tiles" % hex_map.grid.size())
	
	# Setup systems
	_setup_combat()
	_setup_ui()
	_setup_player()
	_setup_floor_specific()
	_setup_enemies()  # Spawn hex enemies
	
	# Start music
	AudioManager.play_floor_ambient(1)
	
	# Enter starting room
	_enter_room("entry")

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
		print("[Floor1-Hex] Player created")
	
	# Place at entry room center
	var entry_center = room_data["entry"]["center"]
	player_node.global_position = hex_map.hex_to_world(entry_center)
	print("[Floor1-Hex] Player placed at entry: %s" % str(entry_center))

func _setup_enemies():
	"""Spawn enemies on the hex grid for each room."""
	enemy_container = Node2D.new()
	enemy_container.name = "EnemyContainer"
	add_child(enemy_container)
	
	# Spawn enemies per room
	var enemy_spawns = {
		"upper": [
			{"name": "Piston Assembly", "hex": Vector2i(-2, -22), "faction": "Construct", "sprite": "res://assets/sprites/enemies/Construct/enemy_piston_assembly_idle.png"},
			{"name": "Piston Assembly", "hex": Vector2i(2, -26), "faction": "Construct", "sprite": "res://assets/sprites/enemies/Construct/enemy_piston_assembly_idle.png"},
		],
		"middle": [
			{"name": "Piston Assembly", "hex": Vector2i(22, -2), "faction": "Construct", "sprite": "res://assets/sprites/enemies/Construct/enemy_piston_assembly_idle.png"},
			{"name": "Piston Assembly", "hex": Vector2i(26, 2), "faction": "Construct", "sprite": "res://assets/sprites/enemies/Construct/enemy_piston_assembly_idle.png"},
		],
		"secret": [
			{"name": "The Duplicate", "hex": Vector2i(0, 46), "faction": "Aberration", "sprite": "res://assets/sprites/enemies/Aberration/enemy_the_duplicate_idle.png"},
		],
		"spore_heart": [
			{"name": "Geode Heart", "hex": Vector2i(44, 0), "faction": "Elemental", "boss": true, "sprite": "res://assets/sprites/enemies/Elemental/enemy_geode_heart_idle.png"},
		],
	}
	
	for room_id in enemy_spawns.keys():
		for spawn_data in enemy_spawns[room_id]:
			var enemy = HexEnemy.new(
				spawn_data["name"] + "_%d" % hex_enemies.size(),
				spawn_data["name"],
				spawn_data["hex"],
				spawn_data.get("faction", "Unknown"),
				spawn_data.get("boss", false),
				spawn_data.get("sprite", "")
			)
			enemy.name = "HexEnemy_%d" % hex_enemies.size()
			
			# Configure enemy stats based on type
			if spawn_data.get("boss", false):
				enemy.max_hp = 50
				enemy.hp = 50
				enemy.attack = 7
				enemy.defense = 3
			elif spawn_data["name"] == "Mimic Chest":
				enemy.max_hp = 15
				enemy.hp = 15
				enemy.attack = 5
				enemy.defense = 2
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
			print("[Floor1-Hex] Spawned %s at %s" % [spawn_data["name"], str(spawn_data["hex"])])
	
	print("[Floor1-Hex] %d hex enemies spawned" % hex_enemies.size())

# ===================================================================
# COMBAT
# ===================================================================

func _setup_combat():
	var combat_manager = get_node_or_null("CombatManager")
	if combat_manager:
		combat_manager.combat_ended.connect(_on_combat_ended)
		print("[Floor1-Hex] CombatManager wired")

func _start_combat(encounter_type: String):
	if in_combat:
		return
	
	# Get enemies for this encounter
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
		AudioManager.play_combat(1)
		print("[Floor1-Hex] Combat started: %s" % encounter_type)

func _get_encounter_enemies(encounter_type: String) -> Array[CombatManager.EnemyData]:
	var result: Array[CombatManager.EnemyData] = []
	
	match encounter_type:
		"standard":
			result = _spawn_enemies(["Piston Assembly", "Piston Assembly"])
		"warren":
			result = _spawn_enemies(["Torch Boy", "Torch Boy", "Torch Boy"])
		"shrine":
			result = _spawn_enemies(["Droplet"])
		"secret":
			result = _spawn_enemies(["Mimic Chest"])
		"spore":
			result = _spawn_enemies(["Spore Walker"])
		"boss":
			result = _spawn_enemies(["Snotling King"])
		_:
			result = _spawn_enemies(["Piston Assembly"])
	
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
	AudioManager.play_floor_ambient(1)
	
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
		print("[Floor1-Hex] Room cleared: %s" % current_room_id)
		
		# Check boss unlock
		if current_room_id == "upper" and not GameState.door_tutorial_completed:
			GameState.door_tutorial_completed = true
			_unlock_all_portals()
			_show_dialogue("The Door", "The Door creaks open. All paths are now clear.")
		
		# Boss defeated
		if current_room_id == "spore_heart":
			_floor_complete()
	else:
		print("[Floor1-Hex] Combat lost — player respawned")
		GameState.player_hp = max(1, GameState.player_hp)
		player_node.global_position = hex_map.hex_to_world(room_data["entry"]["center"])
		# Reset all enemies
		for enemy in hex_enemies:
			enemy.reset_after_combat()

func _floor_complete():
	if floor_complete_notified:
		return
	floor_complete_notified = true
	floor_cleared = true
	_show_notification("🎉 Floor 1 Complete! The portal opens...", Color(0.3, 0.9, 0.3), 5.0)
	_show_dialogue("The Tower", "The Geode Heart falls. Press [S] to ascend to Floor 2.")
	GameState.add_card_to_deck("geode_heart_boss")
	GameState.gems += 20
	GameState.save_game()
	print("[Floor1-Hex] Floor complete! Press S to ascend.")

func _on_enemy_combat_initiated(ambush: bool):
	"""Called when an enemy initiates or is ambushed into combat."""
	if in_combat:
		return
	
	ambush_bonus = ambush
	
	var ambush_msg = "AMBUSH! Player bonus turn!" if ambush else "Enemy spotted you!"
	_show_notification(ambush_msg, Color(0.9, 0.9, 0.3), 3.0)
	
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
		AudioManager.play_combat(1)
		print("[Floor1-Hex] Hex combat started! Enemies: %d, Ambush: %s" % [combat_enemies.size(), str(ambush)])
		
		# If ambush, grant player bonus turn
		if ambush:
			combat_manager.is_player_turn = true
			combat_manager.player_shield += 2
			print("[Floor1-Hex] Ambush bonus: +2 shield, player goes first")

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

# ===================================================================
# UI
# ===================================================================

func _setup_ui():
	# Interact prompt
	interact_prompt = Label.new()
	interact_prompt.name = "InteractPrompt"
	interact_prompt.position = Vector2(540, 650)
	interact_prompt.size = Vector2(200, 30)
	interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_prompt.add_theme_font_size_override("font_size", 14)
	interact_prompt.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	interact_prompt.visible = false
	add_child(interact_prompt)
	
	# Pause menu
	_pause_menu_setup()
	
	# Transit tokens
	var transit_ui = Control.new()
	transit_ui.name = "TransitTokenUI"
	transit_ui.position = Vector2(20, 20)
	add_child(transit_ui)
	_update_transit_token_display()
	
	# Tutorial prompt
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
	container.position = Vector2(760, 400)
	container.size = Vector2(400, 300)
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
				_hex_move(Vector2(0.5, -0.866))     # NE (angle -60°)
			KEY_W:
				_hex_move(Vector2(-0.5, -0.866))    # NW (angle -120°)
			KEY_A:
				_hex_move(Vector2(-1, 0))           # W (angle 180°)
			KEY_D:
				_hex_move(Vector2(1, 0))            # E (angle 0°)
			KEY_Z:
				_hex_move(Vector2(-0.5, 0.866))     # SW (angle 120°)
			KEY_X:
				_hex_move(Vector2(0.5, 0.866))      # SE (angle 60°)
			KEY_S, KEY_SPACE:
				if floor_cleared:
					_ascend_to_next_floor()
				else:
					_try_interact()
				return

func _on_click_move(screen_pos: Vector2):
	"""Left-click to move to a hex tile. Uses A* pathfinding."""
	if not player_node or not hex_map:
		return
	
	# Convert screen position to world position
	var world_pos = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var target_hex = hex_map.world_to_hex(world_pos)
	
	# Check if clicked on enemy for ambush
	for enemy in hex_enemies:
		if enemy.hp <= 0 or enemy.state == HexEnemy.State.IN_COMBAT:
			continue
		if enemy.hex_pos == target_hex:
			if enemy.try_ambush(hex_map.world_to_hex(player_node.global_position)):
				return
	
	# Check if target is walkable
	if not hex_map.is_walkable(target_hex):
		_show_notification("Can't move there!")
		return
	
	# Get current hex and find path
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
	
	# Start path following (skip first hex — current position)
	path_movement_target = path.slice(1)
	path_movement_index = 0
	path_movement_timer = 0.0
	path_movement_active = true

func _on_click_interact(screen_pos: Vector2):
	"""Right-click to interact with an object or NPC near the clicked hex."""
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
	
	# Check distance — interactables within 1 hex
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
	
	# Check wall collision
	if hex_map.is_wall(target_hex):
		return
	
	# Check if player walked onto/near an enemy for ambush
	if _try_ambush_at_hex(target_hex):
		return
	
	# Move to new hex
	player_node.global_position = hex_map.hex_to_world(target_hex)
	
	# Play walk animation
	var animator = player_node.get_node_or_null("PlayerAnimator")
	if animator:
		var dir_str = _velocity_to_direction(move_vec)
		animator.play_walk(dir_str)
		animator.set_meta("move_timer", 0.2)
	
	# Check if we entered a new room or portal
	_check_room_transition(target_hex)
	_check_interactables()
	_check_enemy_sight()  # Check sight after movement

func _vector_to_hex_dir(velocity: Vector2) -> int:
	"""Convert a movement vector to hex direction index (0-5) for pointy-top hexes.
	Hex direction angles: E=0°, SE=60°, SW=120°, W=180°/-180°, NW=-120°, NE=-60°"""
	var angle = velocity.angle()
	var degrees = rad_to_deg(angle)
	
	# Pointy-top hex boundary angles: 30°, 90°, 150°, -150°, -90°, -30°
	if degrees >= -30 and degrees < 30:         return 3    # E  -> D key
	elif degrees >= 30 and degrees < 90:          return 5    # SE -> X key
	elif degrees >= 90 and degrees < 150:         return 4    # SW -> Z key
	elif degrees >= 150 or degrees < -150:        return 2    # W  -> A key
	elif degrees >= -150 and degrees < -90:       return 0    # NW -> W key
	elif degrees >= -90 and degrees < -30:       return 1    # NE -> E key
	else:                                         return 3    # default E

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
	# Check if player stepped on a portal hex
	if hex_map.get_tile(player_hex) == hex_map.TILE_PORTAL:
		var portal_dir = _get_portal_direction_from_hex(player_hex)
		if portal_dir:
			_try_portal_transition(portal_dir)
			return
	
	# Check if player entered a new room zone
	for room_id in room_data.keys():
		if room_id == current_room_id:
			continue
		var data = room_data[room_id]
		var dist = HexTileMap._hex_distance(player_hex, data["center"])
		if dist <= data["radius"]:
			_enter_room(room_id)
			return

func _get_portal_direction_from_hex(hex: Vector2i) -> String:
	# Check which portal this hex belongs to
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
	
	# Check if locked
	if _is_portal_locked(direction):
		_show_notification("Portal is locked.")
		return
	
	# Transition
	in_transition = true
	AudioManager.play_sfx("room_enter")
	
	var target_data = room_data[target_room]
	var target_hex = target_data["center"]
	
	# Place player just inside the target room (opposite side of portal)
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
	print("[Floor1-Hex] Entered room: %s" % data["display"])
	room_changed.emit(room_id, data["display"])
	
	# Check for encounter
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
	return ""

func _is_portal_locked(direction: String) -> bool:
	# Tutorial: only north unlocked initially
	if GameState.is_first_run and current_room_id == "entry":
		return direction != "north"
	return false

func _unlock_all_portals():
	GameState.is_first_run = false
	_show_notification("All portals unlocked!")

# ===================================================================
# INTERACTION
# ===================================================================

func _check_interactables():
	var player_hex = hex_map.world_to_hex(player_node.global_position)
	
	# Check for shop proximity first
	if shop_sprite and shop_sprite.visible:
		var shop_hex = hex_map.world_to_hex(shop_sprite.global_position)
		if HexTileMap._hex_distance(player_hex, shop_hex) <= 2:
			_show_interact_prompt("Shop [S]")
			return
	
	# Check for nearby interactables (objects on OBJECT tiles)
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
	
	# Check for shop proximity first
	if shop_sprite and shop_sprite.visible:
		var shop_hex = hex_map.world_to_hex(shop_sprite.global_position)
		if HexTileMap._hex_distance(player_hex, shop_hex) <= 2:
			_open_shop()
			return
	
	# Check current room for other interactions
	match current_room_id:
		"entry":
			_show_dialogue("Transit Construct", "Welcome to the Tower, Seeker. The portals lead to the four trials.")
		"lower":
			_receive_blessing()
		"secret":
			_open_chest()
		"spore_heart":
			_make_offering()

func _show_interact_prompt(text: String):
	if interact_prompt:
		interact_prompt.text = text
		interact_prompt.visible = true

func _hide_interact_prompt():
	if interact_prompt:
		interact_prompt.visible = false

# ===================================================================
# SHOP
# ===================================================================

func _open_shop():
	if shop_ui_active:
		return
	shop_ui_active = true
	in_ui = true
	
	shop_ui_container = Control.new()
	shop_ui_container.name = "ShopUI"
	add_child(shop_ui_container)
	
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.92)
	bg.size = Vector2(1280, 720)
	shop_ui_container.add_child(bg)
	
	var panel = PanelContainer.new()
	panel.size = Vector2(700, 550)
	panel.position = Vector2(290, 85)
	shop_ui_container.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)
	
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var title = Label.new()
	title.text = "⚙ Machinist's Card Shop ⚙"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))
	header.add_child(title)
	
	var gems_label = Label.new()
	gems_label.text = "Gems: %d💎" % GameState.gems
	gems_label.add_theme_font_size_override("font_size", 18)
	gems_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	header.add_child(gems_label)
	
	var grid = GridContainer.new()
	grid.columns = 2
	vbox.add_child(grid)
	
	for i in range(shop_stock.size()):
		var slot = _create_shop_slot(i, shop_stock[i], gems_label)
		grid.add_child(slot)
	
	var close_btn = Button.new()
	close_btn.text = "Leave Shop"
	close_btn.pressed.connect(_close_shop)
	vbox.add_child(close_btn)

func _create_shop_slot(index: int, item: Dictionary, gems_label: Label) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 140)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var name_label = Label.new()
	name_label.text = item["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	var desc = Label.new()
	desc.text = item.get("desc", "")
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	
	var cost = Label.new()
	cost.text = "%d💎" % item["cost"]
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(cost)
	
	var btn = Button.new()
	btn.text = "Buy"
	btn.disabled = GameState.gems < item["cost"]
	btn.pressed.connect(func(): _on_buy_card(index, item, gems_label))
	vbox.add_child(btn)
	
	return panel

func _on_buy_card(index: int, item: Dictionary, gems_label: Label):
	if GameState.gems < item["cost"]:
		return
	
	var card = CardDB.get_card(item["card_id"])
	if not card:
		return
	
	if GameState.player_deck.size() >= 50:
		_show_notification("Deck full!")
		return
	
	GameState.gems -= item["cost"]
	GameState.add_card_to_deck(item["card_id"])
	gems_label.text = "Gems: %d💎" % GameState.gems
	_show_notification("Bought %s!" % item["name"])

func _close_shop():
	shop_ui_active = false
	in_ui = false
	if shop_ui_container:
		shop_ui_container.queue_free()
	shop_ui_container = null

# ===================================================================
# OTHER INTERACTIONS
# ===================================================================

func _receive_blessing():
	GameState.heal_player(5)
	_show_dialogue("Droplet", "*wobble* The water elemental heals you for 5 HP.")

func _open_chest():
	GameState.add_quiddity(5)
	_show_dialogue("Chest", "You found 5 Quiddity!")

func _make_offering():
	if GameState.inventory_offerings.is_empty():
		_show_dialogue("Altar", "The altar awaits an offering.")
		return
	
	var offering = GameState.inventory_offerings[0]
	GameState.remove_offering(offering)
	GameState.heal_player(5)
	_show_dialogue("Altar", "You offer %s. The shrine grants +5 HP." % GameState.get_offering_name(offering))

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
	notif.add_theme_color_override("font_color", color)
	add_child(notif)
	
	var tween = create_tween()
	tween.tween_property(notif, "position:y", 250, 1.5)
	tween.parallel().tween_property(notif, "modulate:a", 0.0, 1.5)
	tween.tween_callback(notif.queue_free)

# ===================================================================
# TUTORIAL
# ===================================================================

func _setup_floor_specific():
	# Place shop sprite in middle room
	if hex_map and room_data.has("middle"):
		var shop_pos = hex_map.hex_to_world(room_data["middle"]["center"])
		shop_sprite = Sprite2D.new()
		shop_sprite.name = "ShopSprite"
		shop_sprite.texture = preload("res://assets/sprites/shop_machinist.png")
		shop_sprite.position = shop_pos
		shop_sprite.z_index = 50
		shop_sprite.scale = Vector2(1.0, 1.0)
		add_child(shop_sprite)
		print("[Floor1-Hex] Shop sprite placed at middle room")
	
	if GameState.is_first_run:
		print("[Floor1-Hex] First run — tutorial mode")
		_lock_portals_except(["north"])
	else:
		print("[Floor1-Hex] Re-run — all portals active")
		_unlock_all_portals()

func _start_tutorial():
	in_ui = true
	print("[Floor1-Hex] Starting tutorial via TutorialManager")
	TutorialManager.start_tutorial()
	TutorialManager.tutorial_completed.connect(_on_tutorial_completed, CONNECT_ONE_SHOT)

func _on_tutorial_completed():
	GameState.is_first_run = false
	GameState.save_game()
	in_ui = false
	print("[Floor1-Hex] Tutorial complete — resuming floor setup")
	_finish_floor_setup()

func _lock_portals_except(allowed: Array[String]):
	# Handled by _is_portal_locked
	pass

func _start_door_tutorial():
	door_tutorial_active = true
	tutorial_step = 0
	_show_tutorial_prompt("The Door closes its panels.\nPlay a BLOCK card!")

func _advance_tutorial_step():
	tutorial_step += 1
	match tutorial_step:
		1: _show_tutorial_prompt("Good! Now the Door slams forward.\nPlay an ATTACK card!")
		2: _show_tutorial_prompt("The Door closes again.\nPlay another BLOCK card!")
		3: _show_tutorial_prompt("Final strike! Play an ATTACK card!")
		4:
			_hide_tutorial_prompt()
			door_tutorial_active = false

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
				
				# Check if still walkable (doors might have closed, etc.)
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
				
				# Move to next hex
				var prev_pos = player_node.global_position
				player_node.global_position = hex_map.hex_to_world(step_hex)
				
				# Play walk animation
				var animator = player_node.get_node_or_null("PlayerAnimator")
				if animator:
					var dir_vec = player_node.global_position - prev_pos
					var dir_str = _velocity_to_direction(dir_vec)
					animator.play_walk(dir_str)
					animator.set_meta("move_timer", 0.2)
				
				# Check room transition / interactables
				_check_room_transition(step_hex)
				_check_interactables()
				
				path_movement_index += 1
				_check_enemy_sight()  # Check after each step
			else:
				# Path complete
				path_movement_active = false
				var animator = player_node.get_node_or_null("PlayerAnimator")
				if animator:
					animator.play_idle()
				return
	
	# Enemy sight check every frame (for enemies that patrol)
	if not in_combat and not in_transition:
		_check_enemy_sight()
	
	# Movement idle timer (only when not pathing)
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
	GameState.set_current_floor(2)
	GameState.save_game()
	print("[Floor1-Hex] Ascending to Floor 2...")
	get_tree().change_scene_to_file("res://scenes/Floor2.tscn")
